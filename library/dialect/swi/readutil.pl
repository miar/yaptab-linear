/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        jan@swi.psy.uva.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 1985-2002, University of Amsterdam

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

:- module(read_util,
	  [ read_line_to_codes/2,	% +Fd, -Codes (without trailing \n)
	    read_line_to_codes/3,	% +Fd, -Codes, ?Tail
	    read_stream_to_codes/2,	% +Fd, -Codes
	    read_stream_to_codes/3,	% +Fd, -Codes, ?Tail
	    read_file_to_codes/3,	% +File, -Codes, +Options
	    read_file_to_terms/3	% +File, -Terms, +Options
	  ]).
:- use_module(library(shlib)).
:- use_module(library(lists), [select/3]).
:- use_module(library(error)).

/** <module> Read utilities

This library provides some commonly used   reading  predicates. As these
predicates have proven to be time-critical in some applications we moved
them to C. For compatibility as well  as to reduce system dependency, we
link  the  foreign  code  at  runtime    and   fallback  to  the  Prolog
implementation if the shared object cannot be found.
*/

:- volatile
	read_line_to_codes/2,
	read_line_to_codes/3,
	read_stream_to_codes/2,
	read_stream_to_codes/3.

link_foreign :-
	catch(load_foreign_library(foreign(readutil)), _, fail), !.
link_foreign :-
	assertz((read_line_to_codes(Stream, Line) :-
		pl_read_line_to_codes(Stream, Line))),
	assertz((read_line_to_codes(Stream, Line, Tail) :-
		pl_read_line_to_codes(Stream, Line, Tail))),
	assertz((read_stream_to_codes(Stream, Content) :-
	        pl_read_stream_to_codes(Stream, Content))),
	assertz((read_stream_to_codes(Stream, Content, Tail) :-
	        pl_read_stream_to_codes(Stream, Content, Tail))),
	compile_predicates([ read_line_to_codes/2,
			     read_line_to_codes/3,
			     read_stream_to_codes/2,
			     read_stream_to_codes/3
			   ]).

:- initialization(link_foreign, now).


		 /*******************************
		 *	       LINES		*
		 *******************************/

%%	read_line_to_codes(+In:stream, -Line:codes) is det.
%
%	Read a line of input from  In   into  a list of character codes.
%	Trailing newline and  or  return   are  deleted.  Upon  reaching
%	end-of-file Line is unified to the atom =end_of_file=.

pl_read_line_to_codes(Fd, Codes) :-
	get_code(Fd, C0),
	(   C0 == -1
	->  Codes = end_of_file
	;   read_1line_to_codes(C0, Fd, Codes0)
	),
	Codes = Codes0.

read_1line_to_codes(-1, _, []) :- !.
read_1line_to_codes(10, _, []) :- !.
read_1line_to_codes(13, Fd, L) :- !,
	get_code(Fd, C2),
	read_1line_to_codes(C2, Fd, L).
read_1line_to_codes(C, Fd, [C|T]) :-
	get_code(Fd, C2),
	read_1line_to_codes(C2, Fd, T).

%%	read_line_to_codes(+Fd, -Line, ?Tail) is det.
%
%	Read a line of input as a   difference list. This should be used
%	to read multiple lines  efficiently.   On  reaching end-of-file,
%	Tail is bound to the empty list.

pl_read_line_to_codes(Fd, Codes, Tail) :-
	get_code(Fd, C0),
	read_line_to_codes(C0, Fd, Codes0, Tail),
	Codes = Codes0.

read_line_to_codes(-1, _, Tail, Tail) :- !,
	Tail = [].
read_line_to_codes(10, _, [10|Tail], Tail) :- !.
read_line_to_codes(C, Fd, [C|T], Tail) :-
	get_code(Fd, C2),
	read_line_to_codes(C2, Fd, T, Tail).


		 /*******************************
		 *     STREAM (ENTIRE INPUT)	*
		 *******************************/

%%	read_stream_to_codes(+Stream, -Codes) is det.
%%	read_stream_to_codes(+Stream, -Codes, ?Tail) is det.
%
%	Read input from Stream to a list of character codes. The version
%	read_stream_to_codes/3 creates a difference-list.

pl_read_stream_to_codes(Fd, Codes) :-
	pl_read_stream_to_codes(Fd, Codes, []).
pl_read_stream_to_codes(Fd, Codes, Tail) :-
	get_code(Fd, C0),
	read_stream_to_codes(C0, Fd, Codes0, Tail),
	Codes = Codes0.

read_stream_to_codes(-1, _, Tail, Tail) :- !.
read_stream_to_codes(C, Fd, [C|T], Tail) :-
	get_code(Fd, C2),
	read_stream_to_codes(C2, Fd, T, Tail).


%%	read_stream_to_terms(+Stream, -Terms, ?Tail, +Options) is det.

read_stream_to_terms(Fd, Terms, Tail, Options) :-
	read_term(Fd, C0, Options),
	read_stream_to_terms(C0, Fd, Terms0, Tail, Options),
	Terms = Terms0.

read_stream_to_terms(end_of_file, _, Tail, Tail, _) :- !.
read_stream_to_terms(C, Fd, [C|T], Tail, Options) :-
	read_term(Fd, C2, Options),
	read_stream_to_terms(C2, Fd, T, Tail, Options).


		 /*******************************
		 *      FILE (ENTIRE INPUT)	*
		 *******************************/

%%	read_file_to_codes(+Spec, -Codes, +Options) is det.
%
%	Read the file Spec into a list of Codes.  Options is split into
%	options for absolute_file_name/3 and open/4.

read_file_to_codes(Spec, Codes, Options) :-
	must_be(proper_list, Options),
	(   select(tail(Tail), Options, Options1)
	->  true
	;   Tail = [],
	    Options1 = Options
	),
	split_options(Options1, file_option, FileOptions, OpenOptions),
	absolute_file_name(Spec,
			   [ access(read)
			   | FileOptions
			   ],
			   Path),
	open(Path, read, Fd, OpenOptions),
	call_cleanup(read_stream_to_codes(Fd, Codes0, Tail),
		     close(Fd)),
	Codes = Codes0.


%%	read_file_to_terms(+Spec, -Terms, +Options) is det.
%
%	Read the file Spec into a list   of terms. Options is split over
%	absolute_file_name/3, open/4 and read_term/3.

read_file_to_terms(Spec, Terms, Options) :-
	must_be(proper_list, Options),
	(   select(tail(Tail), Options, Options1)
	->  true
	;   Tail = [],
	    Options1 = Options
	),
	split_options(Options1, file_option, FileOptions, Options2),
	split_options(Options2, read_option, ReadOptions, OpenOptions),
	absolute_file_name(Spec,
			   [ access(read)
			   | FileOptions
			   ],
			   Path),
	open(Path, read, Fd, OpenOptions),
	call_cleanup(read_stream_to_terms(Fd, Terms0, Tail, ReadOptions),
		     close(Fd)),
	Terms = Terms0.

split_options([], _, [], []).
split_options([H|T], G, File, Open) :-
	(   call(G, H)
	->  File = [H|FT],
	    OT = Open
	;   Open = [H|OT],
	    FT = File
	),
	split_options(T, G, FT, OT).


read_option(module(_)).
read_option(syntax_errors(_)).
read_option(character_escapes(_)).
read_option(double_quotes(_)).
read_option(backquoted_string(_)).

file_option(extensions(_)).
file_option(file_type(_)).
file_option(file_errors(_)).
file_option(relative_to(_)).
file_option(expand(_)).

		 /*******************************
		 *	       XREF		*
		 *******************************/

:- multifile prolog:meta_goal/2.
:- dynamic prolog:meta_goal/2.
prolog:meta_goal(split_options(_,G,_,_), [G+1]).
