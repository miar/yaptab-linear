/*  $Id: maplist.pl,v 1.2 2008-06-05 19:33:51 rzf Exp $

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

:- module(maplist,
	  [ maplist/2,			% :Goal, +List
	    maplist/3,			% :Goal, ?List1, ?List2
	    maplist/4,			% :Goal, ?List1, ?List2, ?List3
	    maplist/5,			% :Goal, ?List1, ?List2, ?List3, List4
	    forall/2			% :Goal, :Goal
	  ]).

:- module_transparent
	maplist/2, 
	maplist2/2, 
	maplist/3, 
	maplist2/3, 
	maplist/4, 
	maplist2/4, 
	maplist/5, 
	maplist2/5, 
	forall/2.

%	maplist(:Goal, +List)
%
%	True if Goal can succesfully be applied on all elements of List.
%	Arguments are reordered to gain performance as well as to make
%	the predicate deterministic under normal circumstances.

maplist(Goal, List) :-
	maplist2(List, Goal).

maplist2([], _).
maplist2([Elem|Tail], Goal) :-
	call(Goal, Elem), 
	maplist2(Tail, Goal).

%	maplist(:Goal, ?List1, ?List2)
%
%	True if Goal can succesfully be applied to all succesive pairs
%	of elements of List1 and List2.

maplist(Goal, List1, List2) :-
	maplist2(List1, List2, Goal).

maplist2([], [], _).
maplist2([Elem1|Tail1], [Elem2|Tail2], Goal) :-
	call(Goal, Elem1, Elem2), 
	maplist2(Tail1, Tail2, Goal).

%	maplist(:Goal, ?List1, ?List2, ?List3)
%
%	True if Goal can succesfully be applied to all succesive triples
%	of elements of List1..List3.

maplist(Goal, List1, List2, List3) :-
	maplist2(List1, List2, List3, Goal).

maplist2([], [], [], _).
maplist2([Elem1|Tail1], [Elem2|Tail2], [Elem3|Tail3], Goal) :-
	call(Goal, Elem1, Elem2, Elem3), 
	maplist2(Tail1, Tail2, Tail3, Goal).

%	maplist(:Goal, ?List1, ?List2, ?List3, List4)
%
%	True if Goal  can  succesfully  be   applied  to  all  succesive
%	quadruples of elements of List1..List4

maplist(Goal, List1, List2, List3, List4) :-
	maplist2(List1, List2, List3, List4, Goal).

maplist2([], [], [], [], _).
maplist2([Elem1|Tail1], [Elem2|Tail2], [Elem3|Tail3], [Elem4|Tail4], Goal) :-
	call(Goal, Elem1, Elem2, Elem3, Elem4), 
	maplist2(Tail1, Tail2, Tail3, Tail4, Goal).

