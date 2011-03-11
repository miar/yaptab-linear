/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        J.Wielemak@uva.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 2008-2009, University of Amsterdam

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    As a special exception, if you link this library with other files,
    compiled with a Free Software compiler, to produce an executable, this
    library does not by itself cause the resulting executable to be covered
    by the GNU General Public License. This exception does not however
    invalidate any other reasons why the executable file might be covered by
    the GNU General Public License.
*/

:- module(process,
	  [ process_create/3,		% +Exe, +Args, +Options
	    process_wait/2,		% +PID, -Status
	    process_wait/3,		% +PID, -Status, +Options
	    process_id/1,		% -PID
	    process_id/2,		% +Process, -PID
	    is_process/1,		% +PID
	    process_release/1,		% +PID
	    process_kill/1,		% +PID
	    process_kill/2		% +PID, -Signal
	  ]).
:- use_module(library(shlib)).
:- use_module(library(lists)).
:- use_module(library(option)).
:- use_module(library(error)).

:- use_module(library(maplist)).

:- use_foreign_library(foreign(process)).

/** <module> Create processes and redirect I/O

The module library(process) implements interaction  with child processes
and unifies older interfaces such   as  shell/[1,2], open(pipe(command),
...) etc. This library is modelled after SICStus 4.

The main interface is formed by process_create/3.   If the process id is
requested the process must be waited for using process_wait/2. Otherwise
the process resources are reclaimed automatically.

In addition to the predicates, this module   defines  a file search path
(see user:file_search_path/2 and absolute_file_name/3) named =path= that
locates files on the system's  search   path  for  executables. E.g. the
following finds the executable for =ls=:

    ==
    ?- absolute_file_name(path(ls), Path, [access(execute)]).
    ==

*|Incompatibilities and current limitations|*

    * Where SICStus distinguishes between an internal process id and
    the OS process id, this implements does not make this distinction.
    This implies that is_process/1 is incomplete and unreliable.

    * SICStus only supports ISO 8859-1 (latin-1). This implementation
    supports arbitrary OS multibyte interaction using the default
    locale.

    * It is unclear what the detached(true) option is supposed to do. Disable
    signals in the child? Use setsid() to detach from the session?  The
    current implementation uses setsid()

    * An extra option env([Name=Value, ...]) is added to
    process_create/3.

@tbd	Implement detached option in process_create/3
@compat	SICStus 4
*/


		 /*******************************
		 *	  PATH HANDLING		*
		 *******************************/

:- multifile
	user:file_search_path/2.
:- dynamic
	user:file_search_path/2.

user:file_search_path(path, Dir) :-
	getenv('PATH', Path),
	(   current_prolog_flag(windows, true)
	->  atomic_list_concat(Dirs, (;), Path)
	;   atomic_list_concat(Dirs, :, Path)
	),
	member(Dir, Dirs).


%%	process_create(+Exe, +Args:list, +Options) is det.
%
%	Create a new process running the   file  Exe and using arguments
%	from the given list. Exe is a   file  specification as handed to
%	absolute_file_name/3. Typically one use the =path= file alias to
%	specify an executable file on the current   PATH. Args is a list
%	of arguments that  are  handed  to   the  new  process.  On Unix
%	systems, each element in the list becomes a seperate argument in
%	the  new  process.  In  Windows,    the   arguments  are  simply
%	concatenated to form the commandline.   Each  argument itself is
%	either a primitive or  a  list   of  primitives.  A primitive is
%	either atomic or a term file(Spec). Using file(Spec), the system
%	inserts a filename using the OS   filename  conventions which is
%	properly quoted if needed.
%
%	Options:
%
%	    * stdin(Spec)
%	    * stdout(Spec)
%	    * stderr(Spec)
%	    Bind the standard streams of the new process. Spec is one of
%	    the terms below. If pipe(Pipe) is used, the Prolog stream is
%	    a stream in text-mode using the encoding of the default
%	    locale.  The encoding can be changed using set_stream/2.
%
%		* std
%		Just share with the Prolog I/O streams
%		* null
%		Bind to a _null_ stream. Reading from such a stream
%		returns end-of-file, writing produces no output
%		* pipe(-Stream)
%		Attach input and/or output to a Prolog stream.
%
%	    * cwd(+Directory)
%	    Run the new process in Directory.  Directory can be a
%	    compound specification, which is converted using
%	    absolute_file_name/3.
%	    * env(+List)
%	    Specify the environment for the new process.  List is
%	    a list of Name=Value terms.  Note that the current
%	    implementation does not pass any environment variables.
%	    If unspecified, the environment is inherited from the
%	    Prolog process.
%	    * process(-PID)
%	    Unify PID with the process id of the created process.
%	    * detached(+Bool)
%	    If =true=, detach the process from the terminal (Unix only)
%	    Currently mapped to setsid();
%	    * window(+Bool)
%	    If =true=, create a window for the process (Windows only)
%
%	If the user specifies the process(-PID)   option, he *must* call
%	process_wait/2 to reclaim the process.  Without this option, the
%	system will wait for completion of   the  process after the last
%	pipe stream is closed.
%
%	If the process is not waited for, it must succeed with status 0.
%	If not, an process_error is raised.
%
%	*|Windows notes|*
%
%	On Windows this call is an interface to the CreateProcess() API.
%	The  commandline  consists  of  the  basename  of  Exe  and  the
%	arguments formed from Args. Arguments are  separated by a single
%	space. If all characters satisfy iswalnum()   it is unquoted. If
%	the argument contains a double-quote it   is quoted using single
%	quotes. If both single and double   quotes appear a domain_error
%	is raised, otherwise double-quote are used.
%
%	The CreateProcess() API has  many   options.  Currently only the
%	=CREATE_NO_WINDOW=   options   is   supported     through    the
%	window(+Bool) option. If omitted, the  default   is  to use this
%	option if the application has no   console.  Future versions are
%	likely to support  more  window   specific  options  and replace
%	win_exec/2.
%
%	*Examples*
%
%	First,  a  very  simple  example  that    behaves  the  same  as
%	=|shell('ls -l')|=, except for error handling:
%
%	==
%	?- process_create(path(ls), ['-l'], []).
%	==
%
%	@tbd	The detach options is a no-op.
%	@error	process_error(Exe, Status) where Status is one of
%		exit(Code) or killed(Signal).  Raised if the process
%		does not exit with status 0.

process_create(Exe, Args, Options) :-
	exe_options(ExeOptions),
	absolute_file_name(Exe, PlProg, ExeOptions),
	must_be(list, Args),
	maplist(map_arg, Args, Av),
	prolog_to_os_filename(PlProg, Prog),
	Term =.. [Prog|Av],
	expand_cwd_option(Options, Options1),
	process_create(Term, Options1).

exe_options(Options) :-
	current_prolog_flag(windows, true), !,
	Options = [ extensions(['',exe,com]), access(read) ].
exe_options(Options) :-
	Options = [ access(execute) ].

expand_cwd_option(Options0, Options) :-
	select_option(cwd(Spec), Options0, Options1), !,
	(   compound(Spec)
	->  absolute_file_name(Spec, PlDir, [file_type(directory), access(read)]),
	    prolog_to_os_filename(PlDir, Dir),
	    Options = [cwd(Dir)|Options1]
	;   exists_directory(Spec)
	->  Options = Options0
	;   existence_error(directory, Spec)
	).
expand_cwd_option(Options, Options).


%%	map_arg(+ArgIn, -Arg) is det.
%
%	Map an individual argument. Primitives  are either file(Spec) or
%	an atomic value (atom, string, number).  If ArgIn is a non-empty
%	list,  all  elements  are   converted    and   the  results  are
%	concatenated.

map_arg([], []) :- !.
map_arg(List, Arg) :-
	is_list(List), !,
	maplist(map_arg_prim, List, Prims),
	atomic_list_concat(Prims, Arg).
map_arg(Prim, Arg) :-
	map_arg_prim(Prim, Arg).

map_arg_prim(file(Spec), File) :- !,
	(   compound(Spec)
	->  absolute_file_name(Spec, PlFile)
	;   PlFile = Spec
	),
	prolog_to_os_filename(PlFile, File).
map_arg_prim(Arg, Arg).


%%	process_id(-PID) is det.
%
%	True if PID is the process id of the running Prolog process.
%
%	@deprecated	Use current_prolog_flag(pid, PID)

process_id(PID) :-
	current_prolog_flag(pid, PID).

%%	process_id(+Process, -PID) is det.
%
%	PID is the process id of Process.  Given that they are united in
%	SWI-Prolog, this is a simple unify.

process_id(PID, PID).

%%	is_process(+PID) is semidet.
%
%	True if PID might  be  a   process.  Succeeds  for  any positive
%	integer.

is_process(PID) :-
	integer(PID),
	PID > 0.

%%	process_release(+PID)
%
%	Release process handle.  In this implementation this is the same
%	as process_wait(PID, _).

process_release(PID) :-
	process_wait(PID, _).

%%	process_wait(+PID, -Status) is det.
%%	process_wait(+PID, -Status, +Options) is det.
%
%	True if PID completed with  Status.   This  call normally blocks
%	until the process is finished.  Options:
%
%	    * timeout(+Timeout)
%	    Default: =infinite=.  If this option is a number, the
%	    waits for a maximum of Timeout seconds and unifies Status
%	    with =timeout= if the process does not terminate within
%	    Timeout.  In this case PID is _not_ invalidated.  On Unix
%	    systems only timeout 0 and =infinite= are supported.  A
%	    0-value can be used to poll the status of the process.
%
%	    * release(+Bool)
%	    Do/do not release the process.  We do not support this flag
%	    and a domain_error is raised if release(false) is provided.

process_wait(PID, Status) :-
	process_wait(PID, Status, []).

%%	process_kill(+PID) is det.
%%	process_kill(+PID, +Signal) is det.
%
%	Send signal to process PID.  Default   is  =term=.  Signal is an
%	integer, Unix signal name (e.g. =SIGSTOP=)   or  the more Prolog
%	friendly variation one gets after   removing  =SIG= and downcase
%	the result: =stop=. On Windows systems,   Signal  is ignored and
%	the process is terminated using   the TerminateProcess() API. On
%	Windows systems PID must  be   obtained  from  process_create/3,
%	while any PID is allowed on Unix systems.
%
%	@compat	SICStus does not accept the prolog friendly version.  We
%		choose to do so for compatibility with on_signal/3.

process_kill(PID) :-
	process_kill(PID, term).


		 /*******************************
		 *	      MESSAGES		*
		 *******************************/

:- multifile
	prolog:error_message/3.

prolog:error_message(process_error(File, exit(Status))) -->
	[ 'Process "~w": exit status: ~w'-[File, Status] ].
prolog:error_message(process_error(File, killed(Signal))) -->
	[ 'Process "~w": killed by signal ~w'-[File, Signal] ].
