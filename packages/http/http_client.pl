/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        J.Wielemaker@cs.vu.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 1985-2010, University of Amsterdam, VU University Amsterdam

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    As a special exception, if you link this library with other files,
    compiled with a Free Software compiler, to produce an executable, this
    library does not by itself cause the resulting executable to be covered
    by the GNU General Public License. This exception does not however
    invalidate any other reasons why the executable file might be covered by
    the GNU General Public License.
*/


:- module(http_client,
	  [ http_get/3,			% +URL, -Reply, +Options
	    http_delete/3,		% +URL, -Reply, +Options
	    http_post/4,		% +URL, +In, -Reply, +Options
	    http_put/4,			% +URL, +In, -Reply, +Options
	    http_read_data/3,		% +Header, -Data, +Options
	    http_disconnect/1		% +What
	  ]).
:- use_module(library(socket)).
:- use_module(library(url)).
:- use_module(http_header).
:- use_module(http_stream).
:- use_module(library(debug)).
:- use_module(library(memfile)).
:- use_module(library(lists)).
:- use_module(library(error)).
:- use_module(library(option)).
:- use_module(http_stream).
:- use_module(dcg_basics).

:- multifile
	http_convert_data/4,		% http_read_data plugin-hook
	post_data_hook/3,		% http_post_data/3 hook
	open_connection/4,		% do_connect/5 hook
	close_connection/4.

%%	open_connection(+Scheme, +Address, -In, -Out) is semidet.
%
%	Hook to open a connection for the  given URL-scheme to the given
%	address. If successful, In and  Out   must  be  two valid Prolog
%	streams that connect to the server.
%
%	@param Scheme is the URL schema (=http= or =https=)
%	@param Address is a term Host:Port as used by tcp_connect/4.

%%	close_connection(+Scheme, +Address, +In, +Out) is semidet.
%
%	Hook to close a specific connection.   If the hook succeeds, the
%	HTTP client assumes that In and Out are no longer to be used. If
%	the hook fails, the client calls close/2 on both streams.

:- dynamic
	connection/5.			% Host:Port, Protocol, Thread, In, Out

:- expects_dialect(swi).
:- assert(system:swi_io).

user_agent('SWI-Prolog (http://www.swi-prolog.org)').

%%	connect(+UrlParts, -Read, -Write, +Options) is det.
%%	disconnect(+UrlParts) is det.
%
%	Connect/disconnect on the basis of a parsed URL.

connect(Parts, Read, Write, _) :-
	memberchk(socket(Read, Write), Parts), !.
connect(Parts, Read, Write, Options) :-
	address(Parts, Address, Protocol, Options),
	with_mutex(http_client_connect,
		   connect2(Address, Protocol, Read, Write, Options)).

connect2(Address, Protocol, In, Out, _) :-
	thread_self(Self),
	connection(Address, Protocol, Self, In, Out), !.
connect2(Address, Protocol, In, Out, Options) :-
	thread_self(Self),
	do_connect(Address, Protocol, In, Out, Options),
	assert(connection(Address, Protocol, Self, In, Out)).

do_connect(Address, Protocol, In, Out, Options) :-
	debug(http(client), 'http_client: Connecting to ~p ...', [Address]),
	(   open_connection(Protocol, Address, In, Out)
	->  true
	;   tcp_socket(Socket),
	    catch(tcp_connect(Socket, Address, In, Out),
		  E,
		  (   tcp_close_socket(Socket),
		      throw(E)
		  ))
	),
	debug(http(client), '\tok ~p --> ~p', [In, Out]),
	(   memberchk(timeout(Timeout), Options)
        ->  set_stream(In, timeout(Timeout))
        ;   true
	), !.
do_connect(Address, _, _, _, _) :-		% can this happen!?
	throw(error(failed(connect, Address), _)).


disconnect(Parts) :-
	protocol(Parts, Protocol),
	address(Parts, Protocol, Address, []), !,
	disconnect(Address, Protocol).

disconnect(Address, Protocol) :-
	with_mutex(http_client_connect,
		   disconnect_locked(Address, Protocol)).

disconnect_locked(Address, Protocol) :-
	thread_self(Me),
	debug(connection, '~w: Closing connection to ~w~n', [Me, Address]),
	thread_self(Self),
	retract(connection(Address, Protocol, Self, In, Out)), !,
	disconnect(Protocol, Address, In, Out).

disconnect(Protocol, Address, In, Out) :-
	close_connection(Protocol, Address, In, Out), !.
disconnect(_, _, In, Out) :-
	close(Out, [force(true)]),
	close(In,  [force(true)]).

%%	http_disconnect(+Connections) is det.
%
%	Close down some connections. Currently Connections must have the
%	value =all=, closing all connections.

http_disconnect(all) :-
	(   thread_self(Self),
	    connection(Address, Protocol, Self, _, _),
	    disconnect(Address, Protocol),
	    fail
	;   true
	).

address(_Parts, Host:Port, Protocol, Options) :-
	(   memberchk(proxy(Host, Port, Protocol), Options)
	->  true
	;   memberchk(proxy(Host, Port), Options),
	    Protocol = http
	).
address(Parts, Host:Port, Protocol, _Options) :-
	memberchk(host(Host), Parts),
	port(Parts, Port),
	protocol(Parts, Protocol).

port(Parts, Port) :-
	memberchk(port(Port), Parts), !.
port(Parts, 80) :-
	memberchk(protocol(http), Parts).

protocol(Parts, Protocol) :-
	memberchk(protocol(Protocol), Parts), !.
protocol(_, http).

		 /*******************************
		 *	        GET		*
		 *******************************/

%%	http_delete(+URL, -Data, +Options) is det.
%
%	Execute a DELETE method on the server.
%
%	@tbd Properly map the 201, 202 and 204 replies.

http_delete(URL, Data, Options) :-
	http_get(URL, Data, [method('DELETE')|Options]).


%%	http_get(+URL, -Data, +Options) is det.
%
%	Get data from an HTTP server.

http_get(URL, Data, Options) :-
	atomic(URL), !,
	parse_url(URL, Parts),
        http_get(Parts, Data, Options).
http_get(Parts, Data, Options) :-
	must_be(list, Options),
	memberchk(connection(Connection), Options),
	downcase_atom(Connection, 'keep-alive'), !,
	between(0, 1, _),
	catch(http_do_get(Parts, Data, Options), E,
	      (	  message_to_string(E, Msg),
	          debug(keep_alive, 'Error: ~w; retrying~n', [Msg]),
	          disconnect(Parts),
		  fail
	      )), !.
http_get(Parts, Data, Options) :-
	address(Parts, Address, Protocol, Options),
	do_connect(Address, Protocol, Read, Write, Options),
	call_cleanup(http_do_get([socket(Read, Write)|Parts], Data, Options),
		     disconnect(Protocol, Address, Read, Write)).

http_do_get(Parts, Data, Options) :-
	connect(Parts, Read, Write, Options),
	(   select(proxy(_,_), Options, Options1)
	->  parse_url(Location, Parts)
	;   http_location(Parts, Location),
	    Options1 = Options
	),
	memberchk(host(Host), Parts),
	option(method(Method), Options, 'GET'),
	http_write_header(Write, Method, Location, Host,
			  Options1, ReplyOptions),
	write(Write, '\r\n'),
	flush_output(Write),
	http_read_reply(Read, Data0, ReplyOptions), !,
	(   Data0 = redirect(Redirect),
	    nonvar(Redirect)
	->  debug(http(redirect), 'Redirect to ~w', [Redirect]),
	    parse_url(Redirect, Parts, NewParts),
	    http_get(NewParts, Data, Options)
	;   Data = Data0
	).
http_do_get(Parts, _Data, _Options) :-
	throw(error(failed(http_get, Parts), _)).

http_read_reply(In, Data, Options) :-
	between(0, 1, _),
	    http_read_reply_header(In, Fields),
	\+ memberchk(status(continue, _), Fields), !,
	(   memberchk(location(Location), Fields),
	    (   memberchk(status(moved, _), Fields)
	    ;	memberchk(status(moved_temporary, _), Fields)
	    ;	memberchk(status(see_other, _), Fields)
	    )
	->  Data = redirect(Location)
	;   (   select(reply_header(Fields), Options, ReadOptions)
	    ->  true
	    ;   ReadOptions = Options
	    ),
	    http_read_data(In, Fields, Data, ReadOptions)
	),
	(   memberchk(connection(Connection), Fields),
	    downcase_atom(Connection, 'keep-alive')
	->  true
	;   thread_self(Self),
	    connection(Address, Protocol, Self, In, _Out)
	->  disconnect(Address, Protocol)
	;   true
	).
http_read_reply(In, _Data, _Options) :-
	format(user_error, 'Get FAILED~n', []),
	throw(error(failed(read_reply, In), _)).


%%	http_write_header(+Out, +Method, +Location,
%%			  +Host, +Options, -RestOptions) is det.
%
%	Write the request header.  It accepts the following options:
%
%		* http_version(Major-Minor)
%		* connection(Connection)
%		* user_agent(Agent)
%		* request_header(Name=Value)
%
%	Remaining options are returned in RestOptions.

http_write_header(Out, Method, Location, Host, Options, RestOptions) :-
	(   select(http_version(Major-Minor), Options, Options1)
	->  true
	;   Major = 1, Minor = 1,
	    Options1 = Options
	),
	format(Out, '~w ~w HTTP/~w.~w\r\n', [Method, Location, Major, Minor]),
	format(Out, 'Host: ~w\r\n', [Host]),
	(   select(connection(Connection), Options1, Options2)
	->  true
	;   Connection = 'Keep-Alive',
	    Options2 = Options1
	),
	(   select(user_agent(Agent), Options2, Options3)
	->  true
	;   user_agent(Agent),
	    Options3 = Options2
	),
	format(Out, 'User-Agent: ~w\r\n\
		     Connection: ~w\r\n', [Agent, Connection]),
	x_headers(Options3, Out, RestOptions).

%%	x_headers(+Options, +Out, -RestOptions) is det.
%
%	Pass additional request options.  For example:
%
%		request_header('Accept-Language' = 'nl, en')
%
%	No checking is performed on the fieldname or value. Both are
%	copied literally and in the order of appearance to the request.

x_headers([], _, []).
x_headers([H|T0], Out, Options) :-
	x_header(H, Out), !,
	x_headers(T0, Out, Options).
x_headers([H|T0], Out, [H|T]) :-
	x_headers(T0, Out, T).

x_header(request_header(Name=Value), Out) :-
	format(Out, '~w: ~w\r\n', [Name, Value]).
x_header(proxy_authorization(ProxyAuthorization), Out) :-
	proxy_auth_header(ProxyAuthorization, Out).
x_header(range(Spec), Out) :-
	Spec =.. [Unit, From, To],
	(   To == end
	->  ToT = ''
	;   must_be(integer, To),
	    ToT = To
	),
	format(Out, 'Range: ~w=~d-~w\r\n', [Unit, From, ToT]).

proxy_auth_header(basic(User, Password), Out) :- !,
	format(codes(Codes), '~w:~w', [User, Password]),
	phrase(base64(Codes), Base64Codes),
	format(Out, 'Proxy-Authorization: basic ~s\r\n', [Base64Codes]).
proxy_auth_header(Auth, _) :-
	domain_error(authorization, Auth).

%%	http_read_data(+Fields, -Data, +Options) is det.
%
%	Read data from an HTTP connection.   Options must contain a term
%	input(In) that provides the input stream   from the HTTP server.
%	Fields is the parsed http  reply-header. Options is one of:
%
%		* to(stream(+WriteStream))
%		Append the content of the message to Stream
%		* to(atom)
%		Return the reply as an atom
%		* to(codes)
%		Return the reply as a list of codes

http_read_data(Fields, Data, Options) :-
	memberchk(input(In), Fields),
	(   http_read_data(In, Fields, Data, Options)
	->  true
	;   throw(error(failed(http_read_data), _))
	).


http_read_data(In, Fields, Data, Options) :-	% Transfer-encoding: chunked
	select(transfer_encoding(chunked), Fields, RestFields), !,
	http_chunked_open(In, DataStream, []),
	call_cleanup(http_read_data(DataStream, RestFields, Data, Options),
		     close(DataStream)).
http_read_data(In, Fields, Data, Options) :-
	memberchk(to(X), Options), !,
	(   X = stream(Stream)
	->  (   memberchk(content_length(Bytes), Fields)
	    ->  copy_stream_data(In, Stream, Bytes)
	    ;   copy_stream_data(In, Stream)
	    )
	;   new_memory_file(MemFile),
	    open_memory_file(MemFile, write, Stream, [encoding(octet)]),
	    (   memberchk(content_length(Bytes), Fields)
	    ->  copy_stream_data(In, Stream, Bytes)
	    ;   copy_stream_data(In, Stream)
	    ),
	    close(Stream),
	    encoding(Fields, Encoding),
	    (   X == atom
	    ->  memory_file_to_atom(MemFile, Data0, Encoding)
	    ;	X == codes
	    ->	memory_file_to_codes(MemFile, Data0, Encoding)
	    ;	domain_error(return_type, X)
	    ),
	    free_memory_file(MemFile),
	    Data = Data0
	).
http_read_data(In, Fields, Data, _) :-
	memberchk(content_type('application/x-www-form-urlencoded'), Fields), !,
	http_read_data(In, Fields, Codes, [to(codes)]),
	parse_url_search(Codes, Data).
http_read_data(In, Fields, Data, Options) :- 			% call hook
	(   select(content_type(Type), Options, Options1)
	->  delete(Fields, content_type(_), Fields1),
	    http_convert_data(In, [content_type(Type)|Fields1], Data, Options1)
	;   http_convert_data(In, Fields, Data, Options)
	), !.
http_read_data(In, Fields, Data, Options) :-
	http_read_data(In, Fields, Data, [to(atom)|Options]).


encoding(Fields, utf8) :-
	memberchk(content_type(Type), Fields),
	(   sub_atom(Type, _, _, _, 'UTF-8')
	->  true
	;   sub_atom(Type, _, _, _, 'utf-8')
	), !.
encoding(_, octet).


		 /*******************************
		 *	       POST		*
		 *******************************/

%%	http_put(+URL, +In, -Out, +Options)
%
%	Issue an HTTP PUT request.

http_put(URL, In, Out, Options) :-
	http_post(URL, In, Out, [method('PUT')|Options]).


%%	http_post(+URL, +In, -Out, +Options)
%
%	Issue an HTTP POST request, In is modelled after the reply
%	from the HTTP server module.  In is one of:
%
%		* string(String)
%		* string(MimeType, String)
%		* html(Tokens)
%		* file(MimeType, File)

http_post(URL, In, Out, Options) :-
	atomic(URL), !,
	parse_url(URL, Parts),
	http_post(Parts, In, Out, Options).
http_post(Parts, In, Out, Options) :-
	memberchk(connection(Connection), Options),
	downcase_atom(Connection, 'keep-alive'), !,
	between(0, 1, _),
	catch(http_do_post(Parts, In, Out, Options), error(io_error, _),
	      (	  disconnect(Parts),
		  fail
	      )), !.
http_post(Parts, In, Out, Options) :-
	address(Parts, Address, Protocol, Options),
	do_connect(Address, Protocol, Read, Write, Options),
	call_cleanup(http_do_post([socket(Read, Write)|Parts],
				  In, Out, Options),
		     disconnect(Protocol, Address, Read, Write)).

http_do_post(Parts, In, Out, Options) :-
	connect(Parts, Read, Write, Options),
	(   memberchk(proxy(_,_), Options)
	->  parse_url(Location, Parts)
	;   http_location(Parts, Location)
	),
	memberchk(host(Host), Parts),
	split_options(Options, PostOptions, ReplyOptions),
	write_post_header(Write, Location, Host, In, PostOptions),
	http_read_reply(Read, Out, ReplyOptions).

write_post_header(Out, Location, Host, In, Options) :-
	option(method(Method), Options, 'POST'),
	http_write_header(Out, Method, Location, Host, Options, DataOptions),
	http_post_data(In, Out, DataOptions),
	flush_output(Out).

post_option(connection(_)).
post_option(http_version(_)).
post_option(cache_control(_)).
post_option(request_header(_)).

split_options([], [], []).
split_options([H|T], [H|P], R) :-
	post_option(H), !,
	split_options(T, P, R).
split_options([H|T], P, [H|R]) :-
	split_options(T, P, R).

:- retract(system:swi_io).

