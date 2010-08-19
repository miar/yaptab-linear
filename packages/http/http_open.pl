/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        J.Wielemaker@uva.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 2008, University of Amsterdam

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


:- module(http_open,
	  [ http_open/3,		% +URL, -Stream, +Options
	    http_set_authorization/2	% +URL, +Authorization
	  ]).

:- use_module(library(url)).
:- use_module(library(readutil)).
:- use_module(library(socket)).
:- use_module(library(lists)).
:- use_module(library(option)).
:- use_module(library(error)).
:- use_module(library(base64)).
:- use_module(library(debug)).

:- expects_dialect(swi).
:- assert(system:swi_io).

user_agent('SWI-Prolog <http://www.swi-prolog.org>').

/** <module> Simple HTTP client

This library provides a light-weight HTTP client library to get the data
from a URL. The functionality of the  library can be extended by loading
two additional modules that acts as plugins:

    * library(http/http_chunked)
    Loading this library causes http_open/3 to support chunked
    transfer encoding.

    * library(http/http_header)
    Loading this library causes http_open/3 to support the =POST= method
    in addition to =GET= and =HEAD=.

Here is a simple example to fetch a web-page:

  ==
  ?- http_open('http://www.google.com/search?q=prolog', In, []),
     copy_stream_data(In, user_output),
     close(In).
  <!doctype html><head><title>prolog - Google Search</title><script>
  ...
  ==

The example below fetches the modification time of a web-page. Note that
Modified is '' if the web-server does not provide a time-stamp for the
resource. See also parse_time/2.

  ==
  modified(URL, Stamp) :-
	  http_open(URL, In,
		    [ method(head),
		      header(last_modified, Modified)
		    ]),
	  close(In),
	  Modified \== '',
	  parse_time(Modified, Stamp).
  close(In).
  ==

@see xpath/3
@see http_get/3
@see http_post/4
*/

:- multifile
	http:encoding_filter/3,		  % +Encoding, +In0,  -In
	http:current_transfer_encoding/1, % ?Encoding
	http:http_protocol_hook/7.	  % +Protocol, +Parts, +In, +Out,
					  % -NewIn, -NewOut, +Options


%%	http_open(+URL, -Stream, +Options) is det.
%
%	Open the data at the HTTP  server   as  a  Prolog stream. URL is
%	either an atom  specifying  a  URL   or  a  list  representing a
%	broken-down URL compatible to parse_url/2.  After this predicate
%	succeeds the data can be read from Stream. After completion this
%	stream must be  closed  using   the  built-in  Prolog  predicate
%	close/1. Options provides additional options:
%
%	  * authorization(+Term)
%	  Send authorization.  Currently only supports basic(User,Password).
%	  See also http_set_authorization/2.
%
%	  * final_url(-FinalURL)
%	  Unify FinalURL} with the final  destination. This differs from
%	  the  original  URL  if  the  returned  head  of  the  original
%	  indicates an HTTP redirect (codes 301,  302 or 303). Without a
%	  redirect, FinalURL is unified with   the  canonical version of
%	  URL using:
%
%	      ==
%	      parse_url(URL, Parts),
%	      parse_url(FinalURL, Parts)
%	      ==
%
%	  * header(Name, -AtomValue)
%	  If provided, AtomValue is  unified  with   the  value  of  the
%	  indicated  field  in  the  reply    header.  Name  is  matched
%	  case-insensitive and the underscore  (_)   matches  the hyphen
%	  (-). Multiple of these options  may   be  provided  to extract
%	  multiple  header  fields.  If  the  header  is  not  available
%	  AtomValue is unified to the empty atom ('').
%
%	  * method(+Method)
%	  One of =get= (default) or =head=.   The  =head= message can be
%	  used in combination with  the   header(Name,  Value) option to
%	  access information on the resource   without actually fetching
%	  the resource itself.  The  returned   stream  must  be  closed
%	  immediately.   If   library(http/http_header)     is   loaded,
%	  http_open/3 also supports =post=. See the post(Data) option.
%
%	  * size(-Size)
%	  Size is unified with the   integer value of =|Content-Length|=
%	  in the reply header.
%
%	  * timeout(+Timeout)
%	  If provided, set a timeout on   the stream using set_stream/2.
%	  With this option if no new data arrives within Timeout seconds
%	  the stream raises an exception.  Default   is  to wait forever
%	  (=infinite=).
%
%	  * post(+Data)
%	  Provided if library(http/http_header) is also loaded.  Data is
%	  handed to http_post_data/3.
%
%	  * proxy(+Host, +Port)
%	  Use an HTTP proxy to connect to the outside world.
%
%	  * proxy_authorization(+Authorization)
%	  Send authorization to the proxy.  Otherwise   the  same as the
%	  =authorization= option.
%
%	  * request_header(Name = Value)
%	  Additional  name-value  parts  are  added   in  the  order  of
%	  appearance to the HTTP request   header.  No interpretation is
%	  done.
%
%	  * user_agent(+Agent)
%	  Defines the value of the  =|User-Agent|=   field  of  the HTTP
%	  header. Default is =|SWI-Prolog (http://www.swi-prolog.org)|=.
%
%	@error	existence_error(url, Id)

http_open(URL, Stream, Options) :-
	atom(URL), !,
	parse_url_ex(URL, Parts),
	add_authorization(URL, Options, Options1),
	http_open(Parts, Stream, Options1).
http_open(Parts, Stream, Options0) :-
	memberchk(proxy(Host, ProxyPort), Options0), !,
	parse_url_ex(Location, Parts),
	Options = [visited(Parts)|Options0],
	open_socket(Host:ProxyPort, In, Out, Options),
        option(protocol(Protocol), Parts, http),
	default_port(Protocol, DefPort),
	option(port(Port), Parts, DefPort),
	host_and_port(Host, DefPort, Port, HostPort),
	add_authorization(Parts, Options, Options1),
	send_rec_header(Out, In, Stream, HostPort, Location, Parts, Options1),
	return_final_url(Options).
http_open(Parts, Stream, Options0) :-
	memberchk(host(Host), Parts),
        option(protocol(Protocol), Parts, http),
	default_port(Protocol, DefPort),
	option(port(Port), Parts, DefPort),
	http_location(Parts, Location),
	Options = [visited(Parts)|Options0],
	open_socket(Host:Port, SocketIn, SocketOut, Options),
        (   http:http_protocol_hook(Protocol, Parts,
				    SocketIn, SocketOut,
				    In, Out, Options)
        ->  true
        ;   In = SocketIn,
            Out = SocketOut
        ),
	host_and_port(Host, DefPort, Port, HostPort),
	add_authorization(Parts, Options, Options1),
	send_rec_header(Out, In, Stream, HostPort, Location, Parts, Options1),
	return_final_url(Options).

http:http_protocol_hook(http, _, In, Out, In, Out, _).

default_port(https, 443) :- !.
default_port(_,	    80).

host_and_port(Host, DefPort, DefPort, Host) :- !.
host_and_port(Host, _,       Port,    Host:Port).

%%	send_rec_header(+Out, +In, -InStream,
%%			+Host, +Location, +Parts, +Options) is det.
%
%	Send header to Out and process reply.  If there is an error or
%	failure, close In and Out and return the error or failure.

send_rec_header(Out, In, Stream, Host, Location, Parts, Options) :-
	(   catch(guarded_send_rec_header(Out, In, Stream,
					  Host, Location, Parts, Options),
		  E, true)
	->  (   var(E)
	    ->	close(Out)
	    ;	force_close(In, Out),
		throw(E)
	    )
	;   force_close(In, Out),
	    fail
	).

guarded_send_rec_header(Out, In, Stream, Host, Location, Parts, Options) :-
	user_agent(Agent, Options),
	method(Options, MNAME),
	http_version(Version),
	format(Out,
	       '~w ~w HTTP/~w\r\n\
	       Host: ~w\r\n\
	       User-Agent: ~w\r\n\
	       Connection: close\r\n',
	       [MNAME, Location, Version, Host, Agent]),
	x_headers(Options, Out),
        (   option(post(PostData), Options)
        ->  http_header:http_post_data(PostData, Out, [])
        ;   format(Out, '\r\n', [])
        ),
	flush_output(Out),
					% read the reply header
	read_header(In, Code, Comment, Lines),
	do_open(Code, Comment, Lines, Options, Parts, In, Stream).


%%	http_version(-Version:atom) is det.
%
%	HTTP version we publish. We  can  only   use  1.1  if we support
%	chunked encoding, which means http_chunked.pl must be loaded.

http_version('1.1') :-
	http:current_transfer_encoding(chunked), !.
http_version('1.0').

force_close(S1, S2) :-
	close(S1, [force(true)]),
	close(S2, [force(true)]).

method(Options, MNAME) :-
	option(post(_), Options), !,
	option(method(M), Options, post),
	(   map_method(M, MNAME0)
	->  MNAME = MNAME0
	;   domain_error(method, M)
	).
method(Options, MNAME) :-
	option(method(M), Options, get),
	(   map_method(M, MNAME0)
	->  MNAME = MNAME0
	;   domain_error(method, M)
	).

map_method(get,  'GET').
map_method(head, 'HEAD').
map_method(post, 'POST') :-
	current_predicate(http_header:http_post_data/3).


%%	x_headers(+Options, +Out) is det.
%
%	Emit extra headers from   request_header(Name=Value)  options in
%	Options.

x_headers([], _).
x_headers([H|T], Out) :- !,
	x_header(H, Out),
	x_headers(T, Out).

x_header(request_header(Name=Value), Out) :- !,
	format(Out, '~w: ~w\r\n', [Name, Value]).
x_header(proxy_authorization(ProxyAuthorization), Out) :- !,
	auth_header(ProxyAuthorization, 'Proxy-Authorization', Out).
x_header(authorization(Authorization), Out) :- !,
	auth_header(Authorization, 'Authorization', Out).
x_header(_, _).

auth_header(basic(User, Password), Header, Out) :- !,
	format(codes(Codes), '~w:~w', [User, Password]),
	phrase(base64(Codes), Base64Codes),
	format(Out, '~w: basic ~s\r\n', [Header, Base64Codes]).
auth_header(Auth, _, _) :-
	domain_error(authorization, Auth).

user_agent(Agent, Options) :-
	(   option(user_agent(Agent), Options)
	->  true
	;   user_agent(Agent)
	).

%%	do_open(+HTTPStatusCode, +HTTPStatusComment, +Header,
%%		+Options, +Parts, +In, -FinalIn) is det.
%
%	Handle the HTTP status. If 200, we   are ok. If a redirect, redo
%	the open, returning a new stream. Else issue an error.
%
%	@error	existence_error(url, URL)

do_open(200, _, Lines, Options, Parts, In0, In) :- !,
	return_size(Options, Lines),
	return_fields(Options, Lines),
	transfer_encoding_filter(Lines, In0, In),
					% properly re-initialise the stream
	parse_url_ex(Id, Parts),
	set_stream(In, file_name(Id)),
	set_stream(In, record_position(true)).
					% Handle redirections
do_open(Code, _, Lines, Options, Parts, In, Stream) :-
	redirect_code(Code),
	location(Lines, Location), !,
	debug(http(redirect), 'http_open: redirecting to ~w', [Location]),
	parse_url_ex(Location, Parts, Redirected),
	close(In),
	http_open(Redirected, Stream, [visited(Redirected)|Options]).
					% report anything else as error
do_open(Code, Comment, _,  _, Parts, _, _) :-
	parse_url_ex(Id, Parts),
	(   map_error_code(Code, Error)
	->  Formal =.. [Error, url, Id]
	;   Formal = existence_error(url, Id)
	),
	throw(error(Formal, context(_, status(Code, Comment)))).

%%	map_error_code(+HTTPCode, -PrologError) is semidet.
%
%	Map HTTP error codes to Prolog errors.
%
%	@tbd	Many more maps. Unfortunately many have no sensible Prolog
%		counterpart.

map_error_code(401, permission_error).
map_error_code(403, permission_error).
map_error_code(404, existence_error).
map_error_code(405, permission_error).
map_error_code(407, permission_error).
map_error_code(410, existence_error).

redirect_code(301).			% moved permanently
redirect_code(302).			% moved temporary
redirect_code(303).			% see also

%%	open_socket(+Address, -In, -Out, +Options) is det.
%
%	Create and connect a client socket to Address.  Options
%
%	    * timeout(+Timeout)
%	    Sets timeout on the stream, *after* connecting the
%	    socket.
%
%	@tbd	Make timeout also work on tcp_connect/4.
%	@tbd	This is the same as do_connect/4 in http_client.pl

open_socket(Address, In, Out, Options) :-
	debug(http(open), 'http_open: Connecting to ~p ...', [Address]),
	tcp_socket(Socket),
	catch(tcp_connect(Socket, Address, In, Out),
	      E,
	      (	  tcp_close_socket(Socket),
		  throw(E)
	      )),
	debug(http(open), '\tok ~p --> ~p', [In, Out]),
	set_stream(In, record_position(false)),
	(   memberchk(Options, timeout(Timeout))
	->  set_stream(In, timeout(Timeout))
	;   true
	).


return_size(Options, Lines) :-
	memberchk(size(Size), Options), !,
	content_length(Lines, Size).
return_size(_, _).

return_fields([], _).
return_fields([header(Name, Value)|T], Lines) :- !,
	atom_codes(Name, Codes),
	(   member(Line, Lines),
	    phrase(atom_field(Codes, Value), Line)
	->  true
	;   Value = ''
	),
	return_fields(T, Lines).
return_fields([_|T], Lines) :-
	return_fields(T, Lines).


%%	return_final_url(+Options) is semidet.
%
%	If Options contains final_url(URL), unify URL with the final
%	URL after redirections.

return_final_url(Options) :-
	memberchk(final_url(URL), Options),
	var(URL), !,
	memberchk(visited(Parts), Options),
	parse_url_ex(URL, Parts).
return_final_url(_).


%%	transfer_encoding_filter(+Lines, +In0, -In) is det.
%
%	Install filters depending on the encoding.

transfer_encoding_filter(Lines, In0, In) :-
	transfer_encoding(Lines, Encoding), !,
	(   http:encoding_filter(Encoding, In0, In)
	->  true
	;   	domain_error(http_encoding, Encoding)
	).
transfer_encoding_filter(_, In, In).


%%	transfer_encoding(+Lines, -Encoding) is semidet.
%
%	True if Encoding is the value of the =|Transfer-encoding|=
%	header.

transfer_encoding(Lines, Encoding) :-
	member(Line, Lines),
	phrase(transfer_encoding(Encoding0), Line), !,
	debug(http(transfer_encoding), 'Transfer-encoding: ~w', [Encoding0]),
	Encoding = Encoding0.

transfer_encoding(Encoding) -->
	field("transfer-encoding"),
	rest(Encoding).

%%	read_header(+In:stream, -Code:int, -Comment:atom, -Lines:list)
%
%	Read the HTTP reply-header.
%
%	@param Code	Numeric HTTP reply-code
%	@param Comment	Comment of reply-code as atom
%	@param Lines	Remaining header lines as code-lists.

read_header(In, Code, Comment, Lines) :-
	read_line_to_codes(In, Line),
	phrase(first_line(Code, Comment), Line),
	read_line_to_codes(In, Line2),
	rest_header(Line2, In, Lines).

rest_header("", _, []) :- !.		% blank line: end of header
rest_header(L0, In, [L0|L]) :-
	read_line_to_codes(In, L1),
	rest_header(L1, In, L).

%%	content_length(+Header, -Length:int) is semidet.
%
%	Find the Content-Length in an HTTP reply-header.

content_length(Lines, Length) :-
	member(Line, Lines),
	phrase(content_length(Length0), Line), !,
	Length = Length0.

location(Lines, Location) :-
	member(Line, Lines),
	phrase(atom_field("location", Location), Line), !.

first_line(Code, Comment) -->
	"HTTP/", [_], ".", [_],
	skip_blanks,
	integer(Code),
	skip_blanks,
	rest(Comment).

atom_field(Name, Value) -->
	field(Name),
	rest(Value).

content_length(Len) -->
	field("content-length"),
	integer(Len).

field([]) -->
	":",
	skip_blanks.
field([H|T]) -->
	[C],
	{ match_header_char(H, C)
	},
	field(T).

match_header_char(C, C) :- !.
match_header_char(C, U) :-
	code_type(C, to_lower(U)), !.
match_header_char(0'_, 0'-).


skip_blanks -->
	[C],
	{ code_type(C, white)
	}, !,
	skip_blanks.
skip_blanks -->
	[].

%%	integer(-Int)//
%
%	Read 1 or more digits and return as integer.

integer(Code) -->
	digit(D0),
	digits(D),
	{ number_codes(Code, [D0|D])
	}.

digit(C) -->
	[C],
	{ code_type(C, digit)
	}.

digits([D0|D]) -->
	digit(D0), !,
	digits(D).
digits([]) -->
	[].

%%	rest(-Atom:atom)//
%
%	Get rest of input as an atom.

rest(A,L,[]) :-
	atom_codes(A, L).


		 /*******************************
		 *   AUTHORIZATION MANAGEMENT	*
		 *******************************/

%%	http_set_authorization(+URL, +Authorization) is det.
%
%	Set user/password to supply with URLs   that have URL as prefix.
%	If  Authorization  is  the   atom    =|-|=,   possibly   defined
%	authorization is cleared.  For example:
%
%	==
%	?- http_set_authorization('http://www.example.com/private/',
%				  basic('John', 'Secret'))
%	==
%
%	@tbd	Move to a separate module, so http_get/3, etc. can use this
%		too.

:- dynamic
	stored_authorization/2,
	cached_authorization/2.

http_set_authorization(URL, Authorization) :-
	must_be(atom, URL),
	retractall(stored_authorization(URL, _)),
	(   Authorization = (-)
	->  true
	;   check_authorization(Authorization),
	    assert(stored_authorization(URL, Authorization))
	),
	retractall(cached_authorization(_,_)).

check_authorization(Var) :-
	var(Var), !,
	instantiation_error(Var).
check_authorization(basic(User, Password)) :-
	must_be(atom, User),
	must_be(atom, Password).

%%	authorization(+URL, -Authorization) is semdet.
%
%	True if Authorization must be supplied for URL.
%
%	@tbd	Cleanup cache if it gets too big.

authorization(_, _) :-
	\+ stored_authorization(_, _), !,
	fail.
authorization(URL, Authorization) :-
	cached_authorization(URL, Authorization), !,
	Authorization \== (-).
authorization(URL, Authorization) :-
	(   stored_authorization(Prefix, Authorization),
	    sub_atom(URL, 0, _, _, Prefix)
	->  assert(cached_authorization(URL, Authorization))
	;   assert(cached_authorization(URL, -)),
	    fail
	).

add_authorization(_, Options, Options) :-
	option(authorization(_), Options), !.
add_authorization(For, Options0, Options) :-
	stored_authorization(_, _) ->	% quick test to avoid work
	(   atom(For)
	->  URL = For
	;   parse_url_ex(URL, For)
	),
	authorization(URL, Auth), !,
	Options = [authorization(Auth)|Options0].
add_authorization(_, Options, Options).


parse_url_ex(URL, Parts) :-
	parse_url(URL, Parts), !.
parse_url_ex(URL, _) :-
	domain_error(url, URL).		% Syntax error?

parse_url_ex(URL, RelativeTo, Parts) :-
	parse_url(URL, RelativeTo, Parts), !.
parse_url_ex(URL, _, _) :-
	domain_error(url, URL).		% Syntax error?

:- retract(system:swi_io).
