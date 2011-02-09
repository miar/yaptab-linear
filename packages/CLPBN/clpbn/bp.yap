
/***********************************

  Belief Propagation in CLP(BN)

  This should connect to C-code.
 
*********************************/

:- module(clpbn_bp, [bp/3,
        check_if_bp_done/1,
        init_bp_solver/4,
        run_bp_solver/3]).

:- attribute all_diffs/1.

:- use_module(library(ordsets),
    [ord_union/3,
     ord_member/2]).

:- use_module(library('clpbn/matrix_cpt_utils'),
	      [reorder_CPT/5]).

:- use_module(library('clpbn/dists'),
          [
           dist/4,
           get_dist_domain/2,
           get_dist_params/2]).

:- use_module(library('clpbn/utils'), [
    clpbn_not_var_member/2]).

:- use_module(library('clpbn/display'), [
    clpbn_bind_vals/3]).

:- use_module(library('clpbn/connected'),
          [
           init_influences/3,
           influences/5
          ]).

:- use_module(library(lists),
          [
           append/3
          ]).

:- use_module(library('clpbn/aggregates'),
          [check_for_agg_vars/2]).


check_if_bp_done(_Var).

%
% implementation of belief propagation
%
% Process
%
bp([[]],_,_) :- !.
bp([LVs],Vs0,AllDiffs) :-
    init_bp_solver([LVs], Vs0, AllDiffs, State),
    % variable elimination proper
    run_bp_solver([LVs], [LPs], State),
    % bind Probs back to variables so that they can be output.
    clpbn_bind_vals([LVs],[LPs],AllDiffs).

% initialise necessary data for query solver
init_bp_solver(Qs, Vs0, _, LVis) :-
    % replace average, max, min and friends
    % by binary nodes.
    check_for_agg_vars(Vs0, Vs1),
    % replace the variables reachable from G
    % Tables0 will have the full data on each variable
    init_influences(Vs1, G, RG),
    init_bp_solver_for_questions(Qs, G, RG, _, LVis).

init_bp_solver_for_questions([], _, _, [], []).
init_bp_solver_for_questions([Vs|MVs], G, RG, [NVs|MNVs0], [NVs|LVis]) :-
    % find variables connectd to Vs
    influences(Vs, _, NVs0, G, RG),
    sort(NVs0, NVs),
%clpbn_gviz:clpbn2gviz(user_error, test, NVs, Vs),
    init_bp_solver_for_questions(MVs, G, RG, MNVs0, LVis).

% use a findall to recover space without needing for GC
run_bp_solver(LVs, LPs, LNVs) :-
    findall(Ps, solve_bp(LVs, LNVs, Ps), LPs).

solve_bp([LVs|_], [NVs0|_], Ps) :-
%    length(NVs0, L), (L > 64 -> clpbn_gviz:clpbn2gviz(user_error,sort,NVs0,LVs) ; true ),
    find_all_clpbn_vars(NVs0, LVi),
    % construct the graph
    process(LVi, LVs, P).
solve_bp([_|MoreLVs], [_|MoreLVis], Ps) :-
    solve_bp(MoreLVs, MoreLVis, Ps).


% get a list of variables plus associated tables
%
find_all_clpbn_vars([], []).
find_all_clpbn_vars([V|Vs], [var(V,Id,Parents,Domain,Matrix,Ev)|LV]) :-
    clpbn:get_atts(V, [dist(Id,Parents)]), !,
    get_dist_domain(Id, Domain),
    get_dist_params(Id, Matrix),
    get_evidence(V, Ev),
    find_all_clpbn_vars(Vs, LV).
find_all_clpbn_vars([_|Vs], LV) :-
    find_all_clpbn_vars(Vs, LV).

get_evidence(V, Ev) :-
    clpbn:get_atts(V, [evidence(Ev)]), !.
get_evidence(V, -1).  % no evidence!!!

% to be defined in C
% +LVO is the list of all variables
% +InputVs are the variables to be marginalised
% -Out is some output term stating the probabilities
%
process(LV0, InputVs, Out) :-
	length(LV0, N),
	length(InputVs, NI),
	writeln(process(LV0, InputVs, Out)),
	bp_process(N, LV0, NI, InputVs, Out),
	fail.
