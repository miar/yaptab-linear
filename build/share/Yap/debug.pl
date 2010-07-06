/*  $Id: debug.pl,v 1.1 2008-02-12 17:03:53 vsc Exp $

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

:- module(prolog_debug,
	  [ debug/3,			% +Topic, +Format, +Args
	    debug/1,			% +Topic
	    nodebug/1,			% +Topic
	    debugging/1,		% ?Topic
	    debugging/2,		% ?Topic, ?Bool
	    list_debug_topics/0,

	    assertion/1			% :Goal
	  ]).

:- meta_predicate(assertion(:)).
:- set_prolog_flag(generate_debug_info, false).

:- if(current_prolog_flag(dialect, yap)).

:- use_module(library(hacks), [stack_dump/1]).

% this is as good as I can do. 
backtrace(N) :-
	stack_dump(N).

:- endif.

:- dynamic
	debugging/2.

/** <module> Print debug messages

This library is a replacement for  format/3 for printing debug messages.
Messages are assigned a _topic_. By   dynamically  enabling or disabling
topics the user can  select  desired   messages.  Debug  statements  are
removed when the code is compiled for optimization.

See manual for details. With XPCE, you can use the call below to start a
graphical monitorring tool.

==
?- prolog_ide(debug_monitor).
==

Using the predicate assertion/1 you  can   make  assumptions  about your
program explicit, trapping the debugger if the condition does not hold.

@author	Jan Wielemaker
*/

%%	debugging(+Topic) is semidet.
%%	debugging(-Topic) is nondet.
%%	debugging(?Topic, ?Bool) is nondet.
%
%	Check whether we are debugging Topic or enumerate the topics we
%	are debugging.

debugging(Topic) :-
	debugging(Topic, true).

%%	debug(+Topic) is det.
%%	nodebug(+Topic) is det.
%
%	Add/remove a topic from being   printed.  nodebug(_) removes all
%	topics. Gives a warning if the topic is not defined unless it is
%	used from a directive. The latter allows placing debug topics at
%	the start a a (load-)file without warnings.

debug(Topic) :-
	debug(Topic, true).
nodebug(Topic) :-
	debug(Topic, false).

debug(Topic, Val) :-
	(   (   retract(debugging(Topic, _))
	    *-> assert(debugging(Topic, Val)),
		fail
	    ;   (   prolog_load_context(file, _)
		->  true
		;   print_message(warning, debug_no_topic(Topic))
		),
	        assert(debugging(Topic, Val))
	    )
	->  true
	;   true
	).


%%	debug_topic(+Topic) is det.
%
%	Declare a topic for debugging.  This can be used to find all
%	topics available for debugging.

debug_topic(Topic) :-
	(   debugging(Registered, _),
	    Registered =@= Topic
	->  true
	;   assert(debugging(Topic, false))
	).

%%	list_debug_topics is det.
%	
%	List currently known debug topics and their setting.

list_debug_topics :-
	format(user_error, '~*t~40|~n', "-"),
	format(user_error, '~w~t~30| ~w~n', ['Debug Topic', 'Activated']),
	format(user_error, '~*t~40|~n', "-"),
	(   debugging(Topic, Value),
	    format(user_error, '~w~t~30| ~w~n', [Topic, Value]),
	    fail
	;   true
	).

%%	debug(+Topic, +Format, +Args) is det.
%
%	As format/3 to user_error, but only does something if Topic
%	is activated through debug/1.

debug(Topic, Format, Args) :-
	debugging(Topic, true), !,
	print_debug(Topic, Format, Args).
debug(_, _, _).


:- multifile
	prolog:debug_print_hook/3.

print_debug(Topic, Format, Args) :-
	prolog:debug_print_hook(Topic, Format, Args), !.
print_debug(_, Format, Args) :-
	print_message(informational, debug(Format, Args)).


		 /*******************************
		 *	     ASSERTION		*
		 *******************************/

%%	assertion(:Goal) is det.
%	
%	Acts similar to C assert() macro.  It has no effect of Goal
%	succeeds.  If Goal fails it prints a message, a stack-trace
%	and finally traps the debugger.

assertion(G) :-
	\+ \+ G, !.			% avoid binding variables
assertion(G) :-
	print_message(error, assumption_failed(G)),
	backtrace(10),
	trace,
	assertion_failed.

assertion_failed.

%%	assume(:Goal) is det.
%	
%	Acts similar to C assert() macro.  It has no effect of Goal
%	succeeds.  If Goal fails it prints a message, a stack-trace
%	and finally traps the debugger.
%	
%	@deprecated	Use assertion/1 in new code.

		 /*******************************
		 *	     EXPANSION		*
		 *******************************/

:- multifile
	user:goal_expansion/2.

user:goal_expansion(debug(Topic,_,_), true) :-
	(   current_prolog_flag(optimise, true)
	->  true
	;   debug_topic(Topic),
	    fail
	).
user:goal_expansion(debugging(Topic), fail) :-
	(   current_prolog_flag(optimise, true)
	->  true
	;   debug_topic(Topic),
	    fail
	).
user:goal_expansion(assertion(G), Goal) :-
	(   current_prolog_flag(optimise, true)
	->  Goal = true
	;   expand_goal(G, G2),
	    Goal = assertion(G2)
	).
user:goal_expansion(assume(G), Goal) :-
	print_message(informational,
		      compatibility(renamed(assume/1, assertion/1))),
	(   current_prolog_flag(optimise, true)
	->  Goal = true
	;   expand_goal(G, G2),
	    Goal = assertion(G2)
	).


		 /*******************************
		 *	      MESSAGES		*
		 *******************************/

:- multifile
	prolog:message/3.

prolog:message(assumption_failed(G)) -->
	[ 'Assertion failed: ~p'-[G] ].
prolog:message(debug(Fmt, Args)) -->
	{ thread_self(Me) },
	(   { Me == main }
	->  [ Fmt-Args ]
	;   [ '[Thread ~w] '-[Me], Fmt-Args ]
	).
prolog:message(debug_no_topic(Topic)) -->
	[ '~q: no matching debug topic (yet)'-[Topic] ].
