/*************************************************************************
*									 *
*	 YAP Prolog 							 *
*									 *
*	Yap Prolog was developed at NCCUP - Universidade do Porto	 *
*									 *
* Copyright L.Damas, V.S.Costa and Universidade do Porto 1985-1997	 *
*									 *
**************************************************************************
*									 *
* File:		regexp.yap						 *
* Last rev:	5/15/2000						 *
* mods:									 *
* comments:	AVL trees in YAP (from code by M. van Emden, P. Vasey)	 *
*									 *
*************************************************************************/

:- module(avl, [
	avl_new/1,
	avl_insert/4,
	avl_lookup/3
          ]).

avl_new([]).

avl_insert(Key, Value, T0, TF) :-
	insert(T0, Key, Value, TF, _).

insert([], Key, Value, avl([],Key,Value,-,[]), yes).
insert(avl(L,Root,RVal,Bl,R), E, Value, NewTree, WhatHasChanged) :-
	E @< Root, !,
	insert(L, E, Value, NewL, LeftHasChanged),
	adjust(avl(NewL,Root,RVal,Bl,R), LeftHasChanged, left, NewTree, WhatHasChanged).
insert(avl(L,Root,RVal,Bl,R), E, Val, NewTree, WhatHasChanged) :-
%	 E @>= Root, currently we allow duplicated values, although
%        lookup will only fetch the first.
	insert(R, E, Val,NewR, RightHasChanged),
	adjust(avl(L,Root,RVal,Bl,NewR), RightHasChanged, right, NewTree, WhatHasChanged).

adjust(Oldtree, no, _, Oldtree, no).
adjust(avl(L,Root,RVal,Bl,R), yes, Lor, NewTree, WhatHasChanged) :-
	table(Bl, Lor, Bl1, WhatHasChanged, ToBeRebalanced),
	rebalance(avl(L, Root, RVal, Bl, R), Bl1, ToBeRebalanced, NewTree).

%     balance  where     balance  whole tree  to be
%     before   inserted  after    increased   rebalanced
table(-      , left    , <      , yes       , no    ).
table(-      , right   , >      , yes       , no    ).
table(<      , left    , -      , no        , yes   ).
table(<      , right   , -      , no        , no    ).
table(>      , left    , -      , no        , no    ).
table(>      , right   , -      , no        , yes   ).

rebalance(avl(Lst, Root, RVal, _Bl, Rst), Bl1, no, avl(Lst, Root, RVal, Bl1,Rst)).
rebalance(OldTree, _, yes, NewTree) :-
	avl_geq(OldTree,NewTree).

avl_geq(avl(Alpha,A,VA,>,avl(Beta,B,VB,>,Gamma)),
	avl(avl(Alpha,A,VA,-,Beta),B,VB,-,Gamma)).
avl_geq(avl(avl(Alpha,A,VA,<,Beta),B,VB,<,Gamma),
	avl(Alpha,A,VA,-,avl(Beta,B,VB,-,Gamma))).
avl_geq(avl(Alpha,A,VA,>,avl(avl(Beta,X,VX,Bl1,Gamma),B,VB,<,Delta)),
	avl(avl(Alpha,A,VA,Bl2,Beta),X,VX,-,avl(Gamma,B,VB,Bl3,Delta))) :-
        table2(Bl1,Bl2,Bl3).
avl_geq(avl(avl(Alpha,A,VA,>,avl(Beta,X,VX,Bl1,Gamma)),B,VB,<,Delta),
	avl(avl(Alpha,A,VA,Bl2,Beta),X,VX,-,avl(Gamma,B,VB,Bl3,Delta))) :-
        table2(Bl1,Bl2,Bl3).

table2(< ,- ,> ).
table2(> ,< ,- ).
table2(- ,- ,- ).


avl_lookup(Key, Value, avl(L,Key0,KVal,_,R)) :-
	compare(Cmp, Key, Key0),
	avl_lookup(Cmp, Value, L, R, Key, KVal).

avl_lookup(=, Value, _, _, _, Value).
avl_lookup(<, Value, L, _, Key, _) :-
	avl_lookup(Key, Value, L).
avl_lookup(>, Value, _, R, Key, _) :-
	avl_lookup(Key, Value, R).

