/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        wielemak@science.uva.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 1985-2007, University of Amsterdam

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

:- module(dcg_basics,
	  [ white//0,			% <white inside line>
	    whites//0,			% <white inside line>*
	    blank//0,			% <blank>
	    blanks//0,			% <blank>*
	    nonblank//1,		% <nonblank>
	    nonblanks//1,		% <nonblank>* --> chars		(long)
	    blanks_to_nl//0,		% [space,tab,ret]*nl
	    string//1,			% <any>* -->chars 		(short)
	    string_without//2,		% Exclude, -->chars 		(long)
					% Characters
	    alpha_to_lower//1,		% Get lower|upper, return lower
					% Decimal numbers
	    digits//1,			% [0-9]* -->chars
	    digit//1,			% [0-9] --> char
	    integer//1,			% [+-][0-9]+ --> integer
	    float//1,			% [+-]?[0-9]+(.[0-9]*)?(e[+-]?[0-9]+)? --> float
	    number//1,			% integer | float
					% Hexadecimal numbers
	    xdigits//1,			% [0-9a-f]* --> 0-15*
	    xdigit//1,			% [0-9a-f] --> 0-15
	    xinteger//1,		% [0-9a-f]+ --> integer
					% Misc
	    eos//0,			% demand end-of-string
					% generation (TBD)
	    atom//1			% generate atom
	  ]).
:- use_module(library(lists)).


/** <module> Various general DCG utilities

This library provides various commonly  used   DCG  primitives acting on
list  of  character  codes.  Character    classification   is  based  on
code_type/2.

@tbd	Try to achieve an accepted standard and move this into the
	general SWI-Prolog library.  None of this is HTTP specific.
*/

%%	string_without(+End, -Codes)// is det.
%
%	Take as many tokens from the input  until the next token appears
%	in End. End itself is left on the  input. Typical use is to read
%	upto a defined delimiter such  as   a  newline or other reserved
%	character.
%
%	@see string//1.

string_without(Not, [C|T]) -->
	[C],
	{ \+ memberchk(C, Not)
	}, !,
	string_without(Not, T).
string_without(_, []) -->
	[].

%%	string(-Codes)// is nondet.
%
%	Take as few as possible tokens from the input, taking one more
%	each time on backtracking. This code is normally followed by a
%	test for a delimiter.  E.g.
%
%	==
%	upto_colon(Atom) -->
%		string(Codes), ":", !,
%		{ atom_codes(Atom, Codes) }.
%	==

string([]) -->
	[].
string([H|T]) -->
	[H],
	string(T).

%%	blanks// is det.
%
%	Skip zero or more white-space characters.

blanks -->
	blank, !,
	blanks.
blanks -->
	[].

%%	blank// is semidet.
%
%	Take next =space= character from input. Space characters include
%	newline.
%
%	@see white//0

blank -->
	[C],
	{ nonvar(C),
	  code_type(C, space)
	}.

%%	nonblanks(-Codes)// is det.
%
%	Take all =graph= characters

nonblanks([H|T]) -->
	[H],
	{ code_type(H, graph)
	}, !,
	nonblanks(T).
nonblanks([]) -->
	[].

%%	nonblank(-Code)// is semidet.
%
%	Code is the next non-blank (=graph=) character.

nonblank(H) -->
	[H],
	{ code_type(H, graph)
	}.

%%	blanks_to_nl// is semidet.
%
%	Take a sequence of blank//0 codes if banks are followed by a
%	newline or end of the input.

blanks_to_nl -->
	"\n", !.
blanks_to_nl -->
	blank, !,
	blanks_to_nl.
blanks_to_nl -->
	eos.

%%	whites// is det.
%
%	Skip white space _inside_ a line.
%
%	@see blanks//0 also skips newlines.

whites -->
	white, !,
	whites.
whites -->
	[].

%%	white// is semidet.
%
%	Take next =white= character from input. White characters do
%	_not_ include newline.

white -->
	[C],
	{ nonvar(C),
	  code_type(C, white)
	}.


		 /*******************************
		 *	 CHARACTER STUFF	*
		 *******************************/

%%	alpha_to_lower(+C)// is det.
%%	alpha_to_lower(-C)// is semidet.
%
%	Read a letter (class  =alpha=)  and   return  it  as a lowercase
%	letter. In output mode this simply emits the character.

alpha_to_lower(L) -->
	{ integer(L) }, !,
	[L].
alpha_to_lower(L) -->
	[C],
	{ code_type(C, alpha),
	  code_type(C, to_upper(L))
	}.


		 /*******************************
		 *	      NUMBERS		*
		 *******************************/

%%	digits(?Chars)// is det.
%%	digit(?Char)// is det.
%%	integer(?Integer)// is det.
%
%	Number processing. The predicate  digits//1   matches  a posibly
%	empty set of digits,  digit//1  processes   a  single  digit and
%	integer processes an  optional  sign   followed  by  a non-empty
%	sequence of digits into an integer.

digits([H|T]) -->
	digit(H), !,
	digits(T).
digits([]) -->
	[].

digit(C) -->
	[C],
	{ code_type(C, digit)
	}.

integer(I, Head, Tail) :-
	integer(I), !,
	format(codes(Head, Tail), '~w', [I]).
integer(I) -->
	int_codes(Codes),
	{ number_codes(I, Codes)
	}.

int_codes([C,D0|D]) -->
	sign(C), !,
	digit(D0),
	digits(D).
int_codes([D0|D]) -->
	digit(D0),
	digits(D).


%%	float(?Float)// is det.
%
%	Process a floating  point  number.   The  actual  conversion  is
%	controlled by number_codes/2.

float(F, Head, Tail) :-
	float(F), !,
	with_output_to(codes(Head, Tail), write(F)).
float(F) -->
	number(F),
	{ float(F) }.

%%	number(+Number)// is det.
%%	number(-Number)// is semidet.
%
%	Generate extract a number. Handles   both  integers and floating
%	point numbers.

number(N, Head, Tail) :-
	number(N), !,
	format(codes(Head, Tail), '~w', N).
number(N) -->
	int_codes(I),
	(   dot,
	    digit(DF0),
	    digits(DF)
	->  {F = [0'., DF0|DF]}
	;   {F = ""}
	),
	(   exp
	->  int_codes(DI),
	    {E=[0'e|DI]}
	;   {E = ""}
	),
	{ append([I, F, E], Codes),
	  number_codes(N, Codes)
	}.

sign(0'-) --> "-".
sign(0'+) --> "+".

dot --> ".".

exp --> "e".
exp --> "E".

		 /*******************************
		 *	    HEX NUMBERS		*
		 *******************************/

%%	xinteger(+Integer)// is det.
%%	xinteger(-Integer)// is semidet.
%
%	Generate or extract an integer from   a  sequence of hexadecimal
%	digits.

xinteger(Val, Head, Tail) :-
	integer(Val),
	format(codes(Head, Tail), '~16r', [Val]).
xinteger(Val) -->
	xdigit(D0),
	xdigits(D),
	{ mkval([D0|D], 16, Val)
	}.

%%	xdigit(-Weight)// is semidet.
%
%	True if the next code is a  hexdecimal digit with Weight. Weight
%	is between 0 and 15.

xdigit(D) -->
	[C],
	{ code_type(C, xdigit(D))
	}.

%%	xdigits(-WeightList)// is det.
%
%	List of weights of a sequence of hexadecimal codes.  WeightList
%	may be empty.

xdigits([D0|D]) -->
	xdigit(D0), !,
	xdigits(D).
xdigits([]) -->
	[].

mkval([W0|Weights], Base, Val) :-
	mkval(Weights, Base, W0, Val).

mkval([], _, W, W).
mkval([H|T], Base, W0, W) :-
	W1 is W0*Base+H,
	mkval(T, Base, W1, W).


		 /*******************************
		 *	   END-OF-STRING	*
		 *******************************/

%%	eos//
%
%	True if at end of input list.

eos([], []).

		 /*******************************
		 *	     GENERATION		*
		 *******************************/

%%	atom(+Atom)// is det.
%
%	Generate codes of Atom.  Current implementation uses write/1,
%	dealing with any Prolog term.

atom(Atom, Head, Tail) :-
	format(codes(Head, Tail), '~w', [Atom]).
