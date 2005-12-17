% -*- Mode: Prolog -*-
% --------------------------------------------------------------------------------------
%
% This Prolog to SQL compiler may be distributed free of charge provided that it is
% not used in commercial applications without written consent of the author, and
% that the copyright notice remains unchanged.
%
%                    (C) Copyright by Christoph Draxler, Munich
%                        Version 1.1 of Dec. 21st 1992
%
% I would like to keep in my hands the further development and distribution of the
% compiler. This does not mean that I don't want other people to suggest or even
% implement improvements - quite on the contrary: I greatly appreciate contributions 
% and if they make sense to me I will incorporate them into the compiler (with due
% credits given!). 
% 
% For further development of the compiler, address your requests, comments and
% criticism to the author:
%
%                    Christoph Draxler
%                    CIS Centre for Information and Speech Processing
%                    Ludwig-Maximilians-University Munich
%                    Wagmuellerstr. 23 
%                    D 80538 Munich
%                    Tel : ++49 / +89 / 211 06 64 (-60)
%                    Fax : ++49 / +89 / 211 06 74
%                    Mail: draxler@cis.uni-muenchen.de
%
%
% A report describing the implementation is available upon request from the
% author. 
%
%
% RELEASE INFORMATION
% ===================
% Current version is v. 1.1 of Dec. 21st 1992.
% Version 1.0 Sept. 3 1992
% --------------------------------------------------------------------------------------


:- module(myddas_prolog2sql,[
			     translate/3,
			     queries_atom/2
			    ]).
			    





% --------------------------------------------------------------------------------------
%
% Top level predicate translate/3 organizes the compilation and constructs a
% Prolog term representation of the SQL query. 
%
% --------------------------------------------------------------------------------------


translate(ProjectionTerm,DatabaseGoal,SQLQueryTerm):-
   % --- initialize variable identifiers and range variables for relations -----
   init_gensym(var),
   init_gensym(rel),

   % --- tokenize projection term and database goal ----------------------------
   tokenize_term(DatabaseGoal,TokenDatabaseGoal),
   tokenize_term(ProjectionTerm,TokenProjectionTerm),

   % --- lexical analysis: reordering of goals for disjunctive normalized form -
   disjunction(TokenDatabaseGoal,Disjunction),

   % --- code generation ---------------------------------------------------------------
   query_generation(Disjunction,TokenProjectionTerm,SQLQueryTerm).





% --- disjunction(Goal,Disjunction) ----------------------------------------------------
%
% turns original goal into disjunctive normalized form by computing all conjunctions
% and collecting them in a list
%
% --------------------------------------------------------------------------------------

disjunction(Goal,Disjunction):-
   findall(Conjunction,linearize(Goal,Conjunction),Disjunction).




% --- linearize(Goal,ConjunctionList) --------------------------------------------------
%
% Returns a conjunction of base goals for a complex disjunctive or conjunctive goal
% Yields several solutions upon backtracking for disjunctive goals
%
% --------------------------------------------------------------------------------------

linearize(((A,B),C),(LinA,(LinB,LinC))):-
   % --- transform left-linear to right-linear conjunction (',' is associative) ----
   linearize(A,LinA),
   linearize(B,LinB),
   linearize(C,LinC).

linearize((A,B),(LinA,LinB)):-
   A \= (_,_),
   % --- make sure A is not a conjunction ------------------------------------------
   linearize(A,LinA),
   linearize(B,LinB).

% ILP
%linearize((A;B),LinA):-
linearize((A;_),LinA):-
   linearize(A,LinA).

% ILP
%linearize((A;B),LinB):-
linearize((_;B),LinB):-
   linearize(B,LinB).

linearize(not A, not LinA):-
   linearize(A,LinA).

linearize(Var^A, Var^LinA):-
   linearize(A,LinA).

linearize(A,A):-
   A \= (_,_),
   A \= (_;_),
   A \= _^_,
   A \= not(_).




% --- tokenize_term(Term,TokenizedTerm) -------------------------------------------------
%
% If Term is a 
%
%  - variable, then this variable is instantiated with a unique identifier 
%    of the form '$var$'(VarId), and TokenizedTerm is bound to the same 
%    term '$var$'(VarId). 
%
%  - constant, then TokenizedTerm is bound to '$const$'(Term).
%
%  - complex term, then the term is decomposed, its arguments are tokenized,
%    and TokenizedTerm is bound to the result of the composition of the original
%    functor and the tokenized arguments.
%
% --------------------------------------------------------------------------------------

tokenize_term('$var$'(VarId),'$var$'(VarId)):-
   var(VarId),
   % --- uninstantiated variable: instantiate it with unique identifier.
   gensym(var,VarId).

tokenize_term('$var$'(VarId),'$var$'(VarId)):-
   nonvar(VarId).

tokenize_term(Constant,'$const$'(Constant)):-
   nonvar(Constant),
   functor(Constant,_,0).

tokenize_term(Term,TokenizedTerm):-
   nonvar(Term),
   Term \= '$var$'(_),
   Term \= '$const$'(_),
   Term =.. [Functor|Arguments],
   Arguments \= [],
   tokenize_arguments(Arguments,TokenArguments),
   TokenizedTerm =.. [Functor|TokenArguments].



% --- tokenize_arguments(Arguments,TokenizedArguments) ---------------------------------
%
% organizes tokenization of arguments by traversing list and calling tokenize_term
% for each element of the list.
%
% --------------------------------------------------------------------------------------

tokenize_arguments([],[]).

tokenize_arguments([FirstArg|RestArgs],[TokFirstArg|TokRestArgs]):-
   tokenize_term(FirstArg,TokFirstArg),
   tokenize_arguments(RestArgs,TokRestArgs).







% --- query_generation(ListOfConjunctions, ProjectionTerm, ListOfQueries) -------------- 
%
% For each Conjunction translate the pair (ProjectionTerm,Conjunction) to an SQL query
% and connect each such query through a UNION-operator to result in the ListOfQueries.
%
% A Conjunction consists of positive or negative subgoals. Each subgoal is translated 
% as follows:
%  - the functor of a goal that is not a comparison operation is translated to
%    a relation name with a range variable
%  - negated goals are translated to NOT EXISTS-subqueries with * projection
%  - comparison operations are translated to comparison operations in the WHERE-clause
%  - aggregate function terms are translated to aggregate function (sub)queries
% 
% The arguments of a goal are translated as follows:
%  - variables of a goal are translated to qualified attributes
%  - variables occurring in several goals are translated to equality comparisons
%    (equi join) in the WHERE-clause
%  - constant arguments are translated to equality comparisons in the WHERE-clause
% 
% Special treatment of arithmetic functions:
%  - arithmetic functions are identified through the Prolog is/2 operator
%  - an arithmetic function may contain an unbound variable only on its left side
%  - the right side of the is/2 operator may consist of 
%    * bound variables (bound through occurrence within a positive database goal, or 
%      bound through preceeding arithmetic function), or of 
%    * constants (numbers, i.e. integers, reals)
% 
% The following RESTRICTION holds:
%
%  - the binding of variables follows Prolog: variables are bound by positive base goals
%    and on the left side of the is/2 predicate - comparison operations, negated goals
%    and right sides of the is/2 predicate do not return variable bindings and may even 
%    require all arguments to be bound for a safe evaluation.
%
% --------------------------------------------------------------------------------------

query_generation([],_,[]).

query_generation([Conjunction|Conjunctions],ProjectionTerm,[Query|Queries]):-
   projection_term_variables(ProjectionTerm,InitDict),
   translate_conjunction(Conjunction,SQLFrom,SQLWhere,InitDict,Dict),
   translate_projection(ProjectionTerm,Dict,SQLSelect),
   Query = query(SQLSelect,SQLFrom,SQLWhere),
   query_generation(Conjunctions,ProjectionTerm,Queries).



% --- translate_goal(Goal,SQLFrom,SQLWhere,Dict,NewDict) -------------------------------
%
% translates a
%
%   - positive database goal to the associated FROM- and WHERE clause of an SQL query
%   - a negated goal to a negated existential subquery
%   - an arithmetic goal to an arithmetic expression or an aggregate function query
%   - a comparison goal to a comparison expression
%   - a negated comparison goal to a comparison expression with the opposite comparison
%     operator
%
% --------------------------------------------------------------------------------------

translate_goal(SimpleGoal,[SQLFrom],SQLWhere,Dict,NewDict):-
   % --- positive goal binds variables - these bindings are held in the dictionary -----
   functor(SimpleGoal,Functor,Arity),
   translate_functor(Functor,Arity,SQLFrom),
   SimpleGoal =.. [Functor|Arguments],
   translate_arguments(Arguments,SQLFrom,1,SQLWhere,Dict,NewDict).

translate_goal(Result is Expression,[],SQLWhere,Dict,NewDict):-
   translate_arithmetic_function(Result,Expression,SQLWhere,Dict,NewDict).

translate_goal(not NegatedGoals,[],SQLNegatedSubquery,Dict,Dict):-
   % --- negated goals do not bind variables - hence Dict is returned unchanged --------
   functor(NegatedGoals,Functor,_),
   not comparison(Functor,_),
   translate_conjunction(NegatedGoals,SQLFrom,SQLWhere,Dict,_),
   SQLNegatedSubquery = [negated_existential_subquery([*],SQLFrom,SQLWhere)].

translate_goal(not ComparisonGoal,[],SQLCompOp,Dict,Dict):-
   % --- comparison operations do not bind variables - Dict is returned unchanged ------
   ComparisonGoal =.. [ComparisonOperator,LeftArg,RightArg],
   comparison(ComparisonOperator,SQLOperator),
   negated_comparison(SQLOperator,SQLNegOperator),
   translate_comparison(LeftArg,RightArg,SQLNegOperator,Dict,SQLCompOp).

translate_goal(ComparisonGoal,[],SQLCompOp,Dict,Dict):-
   % --- comparison operations do not bind variables - Dict is returned unchanged ------
   ComparisonGoal =.. [ComparisonOperator,LeftArg,RightArg],
   comparison(ComparisonOperator,SQLOperator),
   translate_comparison(LeftArg,RightArg,SQLOperator,Dict,SQLCompOp).

%DISTINCT
translate_goal(distinct(Goal),List,SQL,Dict,DistinctDict):-!,
	translate_goal(Goal,List,SQL,Dict,NewDict),
	add_distinct_statement(NewDict,DistinctDict).

%DEBUG
add_distinct_statement(Dict,Dict):-
	append([A],[1,2],_).
	


% --- translate_conjunction(Conjunction,SQLFrom,SQLWhere,Dict,NewDict) -----------------
% 
% translates a conjunction of goals (represented as a list of goals preceeded by 
% existentially quantified variables) to FROM- and WHERE-clause of an SQL query.  
% A dictionary containing the associated SQL table and attribute names is built up
% as an accumulator pair (arguments Dict and NewDict)
%
% --------------------------------------------------------------------------------------

translate_conjunction('$var$'(VarId)^Goal,SQLFrom,SQLWhere,Dict,NewDict):-
   % --- add info on existentially quantified variables to dictionary here -------------
   add_to_dictionary(VarId,_,_,_,existential,Dict,TmpDict),
   translate_conjunction(Goal,SQLFrom,SQLWhere,TmpDict,NewDict).

translate_conjunction(Goal,SQLFrom,SQLWhere,Dict,NewDict):-
   Goal \= (_,_),
   translate_goal(Goal,SQLFrom,SQLWhere,Dict,NewDict).

translate_conjunction((Goal,Conjunction),SQLFrom,SQLWhere,Dict,NewDict):-
   translate_goal(Goal,FromBegin,WhereBegin,Dict,TmpDict),
   translate_conjunction(Conjunction,FromRest,WhereRest,TmpDict,NewDict),
   append(FromBegin,FromRest,SQLFrom),
   append(WhereBegin,WhereRest,SQLWhere).





% --- translate_arithmetic_function(Result,Expression,SQLWhere,Dict,NewDict) -----------
%
% Arithmetic functions (left side of is/2 operator is bound to value of expression on
% right side) may be called with either
%
% - Result unbound: then Result is bound to the value of the evaluation of Expression
% - Result bound: then an equality condition is returned between the value of Result
%   and the value of the evaluation of Expression.
%
% Only the equality test shows up in the WHERE clause of an SQLquery.
%
% --------------------------------------------------------------------------------------

translate_arithmetic_function('$var$'(VarId),Expression,[],Dict,NewDict):-
   % assigment of value of arithmetic expression to variable - does not
   % show up in WHERE-part, but expression corresponding to
   % variable must be stored in Dict for projection translation

   evaluable_expression(Expression,Dict,ArithExpression,Type),
   add_to_dictionary(VarId,is,ArithExpression,Type,all,Dict,NewDict).


translate_arithmetic_function('$var$'(VarId),Expression,ArithComparison,Dict,Dict):-
   % --- test whether left side evaluates to right side: return equality comparison ----
   % Left side consists of qualified attribute, i.e. range variable must not be
   % arithmetic operator is/2 

   lookup(VarId,Dict,PrevRangeVar,PrevAtt,PrevType),
   not (PrevRangeVar = is),

   % test whether type of attribute is numeric - if not, there's no sense in 
   % continuing the translation

   type_compatible(PrevType,number),
   evaluable_expression(Expression,Dict,ArithExpression,ExprType),
   type_compatible(ExprType,number),
   ArithComparison = [comp(att(PrevRangeVar,PrevAtt),'=',ArithExpression)].


translate_arithmetic_function('$var$'(VarId),Expression,ArithComparison,Dict,Dict):-
   % --- test whether left side evaluates to right side: return equality comparison ----
   % Left side consists of arithmetic expression, i.e. VarId is stored in Dict as 
   % belonging to arithmetic expression which is expressed as RangeVar-argument 
   % of lookup returning is/2. Type information is implicit through the is/2 functor

   lookup(VarId,Dict,is,LeftExpr,Type),
   type_compatible(Type,number),
   evaluable_expression(Expression,Dict,RightExpr,ExprType),
   type_compatible(ExprType,number),
   ArithComparison = [comp(LeftExpr,'=',RightExpr)].


translate_arithmetic_function('$const$'(Constant),Expression,ArithComparison,Dict,Dict):-
   % --- is/2 used to test whether left side evaluates to right side -------------------
   get_type('$const$'(Constant),ConstantType),
   type_compatible(ConstantType,number),
   evaluable_expression(Expression,Dict,ArithExpression,ExprType),
   type_compatible(ExprType,number),
   ArithComparison = [comp('$const$'(Constant),'=',ArithExpression)].



% --- translate_comparison(LeftArg,RightArg,CompOp,Dict,SQLComparison) ---------
%
% translates the left and right arguments of a comparison term into the
% appropriate comparison operation in SQL. The result type of each 
% argument expression is checked for type compatibility
%
% ------------------------------------------------------------------------------

translate_comparison(LeftArg,RightArg,CompOp,Dict,Comparison):-
   evaluable_expression(LeftArg,Dict,LeftTerm,LeftArgType),
   evaluable_expression(RightArg,Dict,RightTerm,RightArgType),
   type_compatible(LeftArgType,RightArgType),
   Comparison = [comp(LeftTerm,CompOp,RightTerm)].







% --- translate_functor(Functor,QualifiedTableName) ------------------------------------
%
% translate_functor searches for the matching relation table name for
% a given functor and creates a unique range variable to result in
% a unique qualified relation table name.
%
% --------------------------------------------------------------------------------------

translate_functor(Functor,Arity,rel(TableName,RangeVariable)):-
   relation(Functor,Arity,TableName),
   gensym(rel,RangeVariable).




% --- translate_arguments(Arguments,RelTable,ArgPos,Conditions,Dict) -------------------
%
% translate_arguments organizes the translation of term arguments. One
% term argument after the other is taken from the list of term arguments
% until the list is exhausted. 
%
% --------------------------------------------------------------------------------------

translate_arguments([],_,_,[],Dict,Dict).

translate_arguments([Arg|Args],SQLTable,Position,SQLWhere,Dict,NewDict):-
   translate_argument(Arg,SQLTable,Position,Where,Dict,TmpDict),
   NewPosition is Position + 1,
   translate_arguments(Args,SQLTable,NewPosition,RestWhere,TmpDict,NewDict),
   append(Where,RestWhere,SQLWhere).




% --- translate_argument(Argument,RelTable,Position,Condition,Dict) --------------------
%
% The first occurrence of a variable leads to its associated SQL attribute information
% to be recorded in the Dict. Any further occurrence creates an equi-join condition 
% between the current attribute and the previously recorded attribute.
% Constant arguments always translate to equality comparisons between an attribute and 
% the constant value.
%
% --------------------------------------------------------------------------------------

translate_argument('$var$'(VarId),rel(SQLTable,RangeVar),Position,[],Dict,NewDict):-
   attribute(Position,SQLTable,Attribute,Type),
   add_to_dictionary(VarId,RangeVar,Attribute,Type,all,Dict,NewDict).

translate_argument('$var$'(VarId),rel(SQLTable,RangeVar),Position,AttComparison,Dict,Dict):-
   % --- Variable occurred previously - retrieve first occurrence data from dictionary -
   lookup(VarId,Dict,PrevRangeVar,PrevAtt,PrevType),
   attribute(Position,SQLTable,Attribute,Type),
   type_compatible(PrevType,Type),
   AttComparison = [comp(att(RangeVar,Attribute),=,att(PrevRangeVar,PrevAtt))].

translate_argument('$const$'(Constant),rel(SQLTable,RangeVar),Position,ConstComparison,Dict,Dict):-
   % --- Equality comparison of constant value and attribute in table ------------------
   attribute(Position,SQLTable,Attribute,Type),
   get_type('$const$'(Constant),ConstType),
   type_compatible(ConstType,Type),
   ConstComparison = [comp(att(RangeVar,Attribute),=,'$const$'(Constant))].





% --- projection_term_variables(ProjectionTerm,Dict) -----------------------------------
%
% extracts all variables from the ProjectionTerm and places them into the
% Dict as a dict/4 term with their Identifier, a non instantiated RangeVar and 
% Attribute argument, and the keyword existential for the type of quantification
%
% --------------------------------------------------------------------------------------

%% ERRO??
%projection_term_variables('$const(_)$',[]).
projection_term_variables('$const$'(_),[]).

projection_term_variables('$var$'(VarId),[dict(VarId,_,_,_,existential)]).

projection_term_variables(ProjectionTerm,ProjectionTermVariables):-
   ProjectionTerm =.. [Functor|ProjectionTermList],
   not (Functor = '$var$'),
   not (ProjectionTermList = []),
   projection_list_vars(ProjectionTermList,ProjectionTermVariables).


projection_list_vars([],[]).
projection_list_vars(['$var$'(VarId)|RestArgs],[dict(VarId,_,_,_,existential)|RestVars]):-
   projection_list_vars(RestArgs,RestVars).
projection_list_vars(['$const$'(_)|RestArgs],Vars):-
   projection_list_vars(RestArgs,Vars).






% --------------------------------------------------------------------------------------
% RESTRICTION! ProjectionTerm underlies the following restrictions:
%
%  - ProjectionTerm must have a functor other than the built-in
%    operators, i.e. ',',';', etc. are not allowed
%
%  - only variables and constants are allowed as arguments,
%    i.e. no structured terms
%
% --------------------------------------------------------------------------------------

translate_projection('$var$'(VarId),Dict,SelectList):-
   projection_arguments(['$var$'(VarId)],SelectList,Dict).

translate_projection('$const$'(Const),_,['$const$'(Const)]).

translate_projection(ProjectionTerm,Dict,SelectList):-
   ProjectionTerm =.. [Functor|Arguments],
   not (Functor = '$var$'),
   not (Functor = '$const$'),
   not (Arguments = []),
   projection_arguments(Arguments,SelectList,Dict).



projection_arguments([],[],_).

projection_arguments([Arg|RestArgs],[Att|RestAtts],Dict):-
   retrieve_argument(Arg,Att,Dict),
   projection_arguments(RestArgs,RestAtts,Dict).




% - retrieve_argument(Argument,SQLAttribute,Dictionary) --------------------------------
%
% retrieves the mapping of an argument to the appropriate SQL construct, i.e.
%
%  - qualified attribute names for variables in base goals
%  - arithmetic expressions for variables in arithmetic goals
%  - constant values for constants
% 
% --------------------------------------------------------------------------------------

retrieve_argument('$var$'(VarId),Attribute,Dict):-
   lookup(VarId,Dict,TableName,AttName,_),
   (
    TableName = is ->
      Attribute = AttName
   ;
      Attribute = att(TableName,AttName)
   ).

retrieve_argument('$const$'(Constant),'$const$'(Constant),_).





% --- lookup(Key,Dict,Value) -----------------------------------------------------------

lookup(VarId,Dict,RangeVar,Attribute,Type):-
   member(dict(VarId,RangeVar,Attribute,Type,Quant),Dict),
   (
    Quant = all ->
      true
   ;
      nonvar(RangeVar),
      nonvar(Attribute)
   ).



% --- add_to_dictionary(Key,RangeVar,Attribute,Quantifier,Dict,NewDict) ----------------

add_to_dictionary(Key,RangeVar,Attribute,Type,_,Dict,Dict):-
   member(dict(Key,RangeVar,Attribute,Type,existential),Dict).

add_to_dictionary(Key,RangeVar,Attribute,Type,Quantifier,Dict,NewDict):-
   not member(dict(Key,_,_,_,_),Dict),
   NewDict = [dict(Key,RangeVar,Attribute,Type,Quantifier)|Dict].




% --- aggregate_function(AggregateFunctionTerm,Dict,AggregateFunctionQuery) ------------
%
% aggregate_function discerns five Prolog aggregate function terms: count, avg, min,
% max, and sum. Each such term is has two arguments: a variable indicating the attribute
% over which the function is to be computed, and a goal argument which must contain in 
% at least one argument position the variable:
%
%    e.g.  avg(Seats,plane(Type,Seats))
%
% These aggregate function terms correspond to the SQL built-in aggregate functions.
% 
% RESTRICTION: AggregateGoal may only be conjunction of (positive or negative) base 
% goals
% 
% --------------------------------------------------------------------------------------

aggregate_function(AggregateFunctionTerm,Dict,AggregateFunctionExpression):-
   AggregateFunctionTerm =..[AggFunctor,AggVar,AggGoal],
   aggregate_functor(AggFunctor,SQLFunction),
   conjunction(AggGoal,AggConjunction),
   aggregate_query_generation(SQLFunction,AggVar,AggConjunction,Dict,AggregateFunctionExpression).


conjunction(Goal,Conjunction):-
   disjunction(Goal,[Conjunction]).




% --- aggregate_query_generation(Function,FunctionVariable,AggGoal,Dict,AggregateQuery) 
%
% compiles the function variable (representing the attribute over which the aggregate 
% function is to be computed) and the aggregate goal (representing the selection and 
% join conditions for the computation of the aggregate function) to an SQL aggregate 
% function subquery.
% 
% --------------------------------------------------------------------------------------

% ILP
% aggregate_query_generation(count,'$const$'('*'),AggGoal,Dict,AggregateQuery):-
%    translate_conjunction(AggGoal,SQLFrom,SQLWhere,Dict,TmpDict),
%   AggregateQuery = agg_query(Function,(count,['$const$'(*)]),SQLFrom,SQLWhere,[]).

aggregate_query_generation(count,'$const$'('*'),AggGoal,Dict,AggregateQuery):-
   translate_conjunction(AggGoal,SQLFrom,SQLWhere,Dict,_),

   % ATTENTION! It is assumed that in count(*) aggregate query terms there cannot be
   % free variables because '*' stands for "all arguments"

   AggregateQuery = agg_query(_,(count,['$const$'(*)]),SQLFrom,SQLWhere,[]).

%DISTINCT
aggregate_query_generation(countdistinct,'$const$'('*'),AggGoal,Dict,AggregateQuery):-
   translate_conjunction(AggGoal,SQLFrom,SQLWhere,Dict,_),

   % ATTENTION! It is assumed that in count(*) aggregate query terms there cannot be
   % free variables because '*' stands for "all arguments"

   AggregateQuery = agg_query(_,(countdistinct,['$const$'(*)]),SQLFrom,SQLWhere,[]).


aggregate_query_generation(Function,FunctionVariable,AggGoal,Dict,AggregateQuery):-
   translate_conjunction(AggGoal,SQLFrom,SQLWhere,Dict,TmpDict),

   % --- only variables occurring in the aggregate goal are relevant to the translation
   % of the function variable and the free variables in the goal.
   % Thus subtract from TmpDict all entries of Dict
   set_difference(TmpDict,Dict,AggDict),
 
   translate_projection(FunctionVariable,AggDict,SQLSelect),
   translate_grouping(FunctionVariable,AggDict,SQLGroup),
   AggregateQuery = agg_query(Function,SQLSelect,SQLFrom,SQLWhere,SQLGroup).




% --- translate_grouping(FunctionVariable,Dict,SQLGroup) -------------------------------
%
% finds the free variables in the aggregate function term and collects their
% corresponding SQL qualified attributes in the SQLGroup list.
% 
% --------------------------------------------------------------------------------------

translate_grouping(FunctionVariable,Dict,SQLGroup):-
   free_vars(FunctionVariable,Dict,FreeVariables),
   translate_free_vars(FreeVariables,SQLGroup).




% --- free_vars(FunctionVariable,Dict,FreeVarList) -------------------------------------
%
% A Variable is free if it neither occurs as the FunctionVariable, nor is stored as
% existentially quantified (through ^/2 in the original goal) in the dictionary
% 
% FreeVars contains for each variable the relevant attribute and relation information 
% contained in the dictionary
% 
% --------------------------------------------------------------------------------------

% ILP
% free_vars(FunctionVariable,Dict,FreeVarList):-
%   projection_term_variables(FunctionVariable,FunctionVariableList),
%   findall((Var,Table,Attribute),
%       (member(dict(Var,Table,Attribute,Type,all),Dict),
%        not member(dict(Var,_,_,_,_),FunctionVariableList)
%       ),
%       FreeVarList).
free_vars(FunctionVariable,Dict,FreeVarList):-
  projection_term_variables(FunctionVariable,FunctionVariableList),
  findall((Var,Table,Attribute),
      (member(dict(Var,Table,Attribute,_,all),Dict),
       not member(dict(Var,_,_,_,_),FunctionVariableList)
      ),
      FreeVarList).


% --- function_variable_list(FunctionVariable,FunctionVariableList) --------------------
%
% extracts the list of variables which occur in the function variable term
%
% RESTRICTION: FunctionVariable may only contain one single variable.
% 
% --------------------------------------------------------------------------------------

function_variable_list('$var$'(VarId),[VarId]).




% --- translate_free_vars(FreeVars,SQLGroup) -------------------------------------------
%
% translates dictionary information on free variables to SQLGroup of aggregate
% function query
% 
% --------------------------------------------------------------------------------------

translate_free_vars([],[]).
% ILP
%translate_free_vars([(VarId,Table,Attribute)|FreeVars],[att(Table,Attribute)|SQLGroups]):-
translate_free_vars([(_,Table,Attribute)|FreeVars],[att(Table,Attribute)|SQLGroups]):-
   translate_free_vars(FreeVars,SQLGroups).




% --- evaluable_expression(ExpressionTerm,Dictionary,Expression,Type) --------------------
%
% evaluable_expression constructs SQL arithmetic expressions with qualified attribute names
% from the Prolog arithmetic expression term and the information stored in the dictionary.
%
% The type of an evaluable function is returned in the argument Type.
%
% The dictionary is not changed because it is used for lookup only. 
% 

evaluable_expression(AggregateFunctionTerm,Dictionary,AggregateFunctionExpression,number):-
   aggregate_function(AggregateFunctionTerm,Dictionary,AggregateFunctionExpression).

evaluable_expression(LeftExp + RightExp,Dictionary,LeftAr + RightAr,number):-
   evaluable_expression(LeftExp,Dictionary,LeftAr,number),
   evaluable_expression(RightExp,Dictionary,RightAr,number).

evaluable_expression(LeftExp - RightExp,Dictionary,LeftAr - RightAr,number):-
   evaluable_expression(LeftExp,Dictionary,LeftAr,number),
   evaluable_expression(RightExp,Dictionary,RightAr,number).

evaluable_expression(LeftExp * RightExp,Dictionary,LeftAr * RightAr,number):-
   evaluable_expression(LeftExp,Dictionary,LeftAr,number),
   evaluable_expression(RightExp,Dictionary,RightAr,number).

evaluable_expression(LeftExp / RightExp,Dictionary, LeftAr / RightAr,number):-
   evaluable_expression(LeftExp,Dictionary,LeftAr,number),
   evaluable_expression(RightExp,Dictionary,RightAr,number).

evaluable_expression('$var$'(VarId),Dictionary,att(RangeVar,Attribute),Type):-
   lookup(VarId,Dictionary,RangeVar,Attribute,Type),
   RangeVar \= is.

evaluable_expression('$var$'(VarId),Dictionary,ArithmeticExpression,Type):-
   lookup(VarId,Dictionary,is,ArithmeticExpression,Type).

evaluable_expression('$const$'(Const),_,'$const$'(Const),ConstType):-
   get_type('$const$'(Const),ConstType).





% --------------------------------------------------------------------------------------
%
% Output to screen predicates - rather crude at the moment
%
% --------------------------------------------------------------------------------------


% --- printqueries(Code) ---------------------------------------------------------------

printqueries([Query]):-
   nl,
   print_query(Query),
   write(';'),
   nl,
   nl.

printqueries([Query|Queries]):-
   not (Queries = []),
   nl,
   print_query(Query),
   nl,
   write('UNION'),
   nl,
   printqueries(Queries).



% --- print_query(QueryCode) -----------------------------------------------------------

print_query(query([agg_query(Function,Select,From,Where,Group)],_,_)):-
   % --- ugly rule here: aggregate function only in SELECT Part of query ----
   !,
   print_query(agg_query(Function,Select,From,Where,Group)).

print_query(query(Select,From,Where)):-
   print_clause('SELECT',Select,','),
   nl,
   print_clause('FROM',From,','),
   nl,
   print_clause('WHERE',Where,'AND'),
   nl.

print_query(agg_query(Function,Select,From,Where,Group)):-
   print_clause('SELECT',Function,Select,','),
   nl,
   print_clause('FROM',From,','),
   nl,
   print_clause('WHERE',Where,'AND'),
   nl,
   print_clause('GROUP BY',Group,',').

print_query(negated_existential_subquery(Select,From,Where)):-
   write('NOT EXISTS'),
   nl,
   write('('),
   print_clause('SELECT',Select,','),
   nl,
   print_clause('FROM',From,','),
   nl,
   print_clause('WHERE',Where,'AND'),
   nl,
   write(')').




% --- print_clause(Keyword,ClauseCode,Separator) ---------------------------------------
%
% with 
% Keyword    one of SELECT, FROM, WHERE, or GROUP BY, 
% ClauseCode the code corresponding to the appropriate clause of an SQL query, and 
% Separator  indicating the character(s) through which the items of a clause
%            are separated from each other (',' or 'AND').
% 
% --------------------------------------------------------------------------------------

% ILP
% print_clause(Keyword,[],_).
print_clause(_,[],_).

print_clause(Keyword,[Column|RestColumns],Separator):-
   write(Keyword),
   write(' '),
   print_clause([Column|RestColumns],Separator).

print_clause(Keyword,Function,[Column],Separator):-
   write(Keyword),
   write(' '),
   write(Function),
   write('('),
   print_clause([Column],Separator),
   write(')').





% --- print_clause(ClauseCode,Separator) -----------------------------------------------

print_clause([Item],_):-
   print_column(Item).

print_clause([Item,NextItem|RestItems],Separator):-
   print_column(Item),
   write(' '),
   write(Separator),
   write(' '),
   print_clause([NextItem|RestItems],Separator).




% --- print_column(ColumnCode) --------------------------------

print_column('*'):-
   write('*').

print_column(att(RangeVar,Attribute)):-
   write(RangeVar),
   write('.'),
   write(Attribute).

print_column(rel(Relation,RangeVar)):-
   write(Relation),
   write(' '),
   write(RangeVar).

print_column('$const$'(String)):-
   get_type('$const$'(String),string),
   write('"'),
   write(String),
   write('"').

print_column('$const$'(Number)):-
   get_type('$const$'(Number),NumType),
   type_compatible(NumType,number),
   write(Number).

print_column(comp(LeftArg,Operator,RightArg)):-
   print_column(LeftArg),
   write(' '),
   write(Operator),
   write(' '),
   print_column(RightArg).

print_column(LeftExpr * RightExpr):-
   print_column(LeftExpr),
   write('*'),
   print_column(RightExpr).

print_column(LeftExpr / RightExpr):-
   print_column(LeftExpr),
   write('/'),
   print_column(RightExpr).

print_column(LeftExpr + RightExpr):-
   print_column(LeftExpr),
   write('+'),
   print_column(RightExpr).

print_column(LeftExpr - RightExpr):-
   print_column(LeftExpr),
   write('-'),
   print_column(RightExpr).

print_column(agg_query(Function,Select,From,Where,Group)):-
   nl,
   write('('),
   print_query(agg_query(Function,Select,From,Where,Group)),
   write(')').

print_column(negated_existential_subquery(Select,From,Where)):-
   print_query(negated_existential_subquery(Select,From,Where)).





% --- queries_atom(Queries,QueryAtom) ---------------------------- 
%
% queries_atom(Queries,QueryAtom) returns in its second argument
% the SQL query as a Prolog atom. For efficiency reasons, a list
% of ASCII codes is ceated as a difference list, and it is then 
% transformed to an atom by name/2
% ---------------------------------------------------------------- 


queries_atom(Queries,QueryAtom):-
   queries_atom(Queries,QueryList,[]),
   name(QueryAtom,QueryList).



queries_atom([Query],QueryList,Diff):-
   query_atom(Query,QueryList,Diff).

queries_atom([Query|Queries],QueryList,Diff):-
   Queries \= [],
   query_atom(Query,QueryList,X1),
   column_atom('UNION',X1,X2),
   queries_atom(Queries,X2,Diff).



% --- query_atom(QueryCode) --------------------------------

query_atom(query([agg_query(Function,Select,From,Where,Group)],_,_),QueryList,Diff):-
   % --- ugly rule here: aggregate function only in SELECT Part of query ----
   !,
   query_atom(agg_query(Function,Select,From,Where,Group),QueryList,Diff).

query_atom(query(Select,From,Where),QueryList,Diff):-
   clause_atom('SELECT',Select,',',QueryList,X1),
   clause_atom('FROM',From,',',X1,X2),
   clause_atom('WHERE',Where,'AND',X2,Diff).

query_atom(agg_query(Function,Select,From,Where,Group),QueryList,Diff):-
   clause_atom('SELECT',Function,Select,',',QueryList,X1),
   clause_atom('FROM',From,',',X1,X2),
   clause_atom('WHERE',Where,'AND',X2,X3),
   clause_atom('GROUP BY',Group,',',X3,Diff).

query_atom(negated_existential_subquery(Select,From,Where),QueryList,Diff):-
   column_atom('NOT EXISTS(',QueryList,X1),   
   clause_atom('SELECT',Select,',',X1,X2),
   clause_atom('FROM',From,',',X2,X3),
   clause_atom('WHERE',Where,'AND',X3,X4),
   column_atom(')',X4,Diff).




% --- clause_atom(Keyword,ClauseCode,Junctor,CurrAtom,QueryAtom) -------------
%
% with 
% Keyword    one of SELECT, FROM, WHERE, or GROUP BY, 
% ClauseCode the code corresponding to the appropriate clause of an SQL query, and 
% Junctor    indicating the character(s) through which the items of a clause
%            are separated from each other (',' or 'AND').

% ILP
% clause_atom(Keyword,[],_,QueryList,QueryList).
clause_atom(_,[],_,QueryList,QueryList).

clause_atom(Keyword,[Column|RestColumns],Junctor,QueryList,Diff):-
   column_atom(Keyword,QueryList,X1),
   column_atom(' ',X1,X2),
   clause_atom([Column|RestColumns],Junctor,X2,X3),
   column_atom(' ',X3,Diff).

%DISTINCT
clause_atom(Keyword,'COUNTDISTINCT',[Column],Junctor,QueryList,Diff):-!,
   column_atom(Keyword,QueryList,X1),
   column_atom(' ',X1,X2),
   column_atom('COUNT',X2,X3),
   column_atom('(DISTINCT ',X3,X4),
   clause_atom([Column],Junctor,X4,X5),
   column_atom(') ',X5,Diff).

clause_atom(Keyword,Function,[Column],Junctor,QueryList,Diff):-
   column_atom(Keyword,QueryList,X1),
   column_atom(' ',X1,X2),
   column_atom(Function,X2,X3),
   column_atom('(',X3,X4),
   clause_atom([Column],Junctor,X4,X5),
   column_atom(') ',X5,Diff).






% --- clause_atom(ClauseCode,Junctor) --------------------------------

clause_atom([Item],_,QueryList,Diff):-
   column_atom(Item,QueryList,Diff).

clause_atom([Item,NextItem|RestItems],Junctor,QueryList,Diff):-
   column_atom(Item,QueryList,X1),
   column_atom(' ',X1,X2),
   column_atom(Junctor,X2,X3),
   column_atom(' ',X3,X4),
   clause_atom([NextItem|RestItems],Junctor,X4,Diff).





column_atom(att(RangeVar,Attribute),QueryList,Diff):-
   column_atom(RangeVar,QueryList,X1),
   column_atom('.',X1,X2),
   column_atom(Attribute,X2,Diff).

column_atom(rel(Relation,RangeVar),QueryList,Diff):-
   column_atom(Relation,QueryList,X1),
   column_atom(' ',X1,X2),
   column_atom(RangeVar,X2,Diff).

column_atom('$const$'(String),QueryList,Diff):-
   get_type('$const$'(String),string),
   column_atom('"',QueryList,X1),
   column_atom(String,X1,X2),
   column_atom('"',X2,Diff).

column_atom('$const$'(Number),QueryList,Diff):-
   get_type('$const$'(Number),NumType),
   type_compatible(NumType,number),
   column_atom(Number,QueryList,Diff).

column_atom(comp(LeftArg,Operator,RightArg),QueryList,Diff):-
   column_atom(LeftArg,QueryList,X1),
   column_atom(' ',X1,X2),
   column_atom(Operator,X2,X3),
   column_atom(' ',X3,X4),
   column_atom(RightArg,X4,Diff).

column_atom(LeftExpr * RightExpr,QueryList,Diff):-
   column_atom(LeftExpr,QueryList,X1),
   column_atom('*',X1,X2),
   column_atom(RightExpr,X2,Diff).

column_atom(LeftExpr + RightExpr,QueryList,Diff):-
   column_atom(LeftExpr,QueryList,X1),
   column_atom('+',X1,X2),
   column_atom(RightExpr,X2,Diff).

column_atom(LeftExpr - RightExpr,QueryList,Diff):-
   column_atom(LeftExpr,QueryList,X1),
   column_atom('-',X1,X2),
   column_atom(RightExpr,X2,Diff).

column_atom(LeftExpr / RightExpr,QueryList,Diff):-
   column_atom(LeftExpr,QueryList,X1),
   column_atom('/',X1,X2),
   column_atom(RightExpr,X2,Diff).

column_atom(agg_query(Function,Select,From,Where,Group),QueryList,Diff):-
   column_atom('(',QueryList,X1),
   query_atom(agg_query(Function,Select,From,Where,Group),X1,X2),
   column_atom(')',X2,Diff).

column_atom(negated_existential_subquery(Select,From,Where),QueryList,Diff):-
   query_atom(negated_existential_subquery(Select,From,Where),QueryList,Diff).


column_atom(Atom,List,Diff):-
   atom(Atom),
   name(Atom,X1),
   append(X1,Diff,List).

column_atom(Number,List,Diff) :-
	number(Number),
	name(Number,X1),
	append(X1,Diff,List).	



% --- gensym(Root,Symbol) ----------------------------------------------------
%
% SEPIA 3.2. version - other Prolog implementations provide gensym/2
% and init_gensym/1 as built-ins. */
%
% (C) Christoph Draxler, Aug. 1992
%
% 

init_gensym(Atom) :- 
	set_value(Atom,'@').

gensym(Atom,Var) :-
        var(Var),
	get_value(Atom,Value),
	char_code(Value,Code),
        NewCode is Code + 1,
	char_code(Var,NewCode),
        set_value(Atom,Var).



% --- auxiliary predicates (some of them may be built-in... --------------------

append([],L,L).
append([H1|L1],L2,[H1|L3]):-
   append(L1,L2,L3).



member(X,[X|_]).
member(X,[_|T]):-
   member(X,T).



repeat_n(N):-
   integer(N),
   N > 0,
   repeat_1(N).

repeat_1(1):-!.
repeat_1(_).
repeat_1(N):-
   N1 is N-1,
   repeat_1(N1).



% --- set_difference(SetA,SetB,Difference) --------------------------------------------
%
% SetA - SetB = Difference

set_difference([],_,[]).

set_difference([Element|RestSet],Set,[Element|RestDifference]):-
   not member(Element,Set),
   set_difference(RestSet,Set,RestDifference).

set_difference([Element|RestSet],Set,RestDifference):-
   member(Element,Set),
   set_difference(RestSet,Set,RestDifference).



% % --- benchmarking programs --------------------------------------------
% %
% % taken from R. O'Keefe: The Craft of Prolog, MIT Press 1990
% %
% % Sepia Prolog version

% cpu_time(Time):-
%    cputime(Time).


% cpu_time(Goal,Duration):-
%    !,
%    cputime(T1),
%    (call(Goal) -> true; true),
%    cputime(T2),
%    Duration is T2 - T1.

% cpu_time(N,Goal,Duration):-
%    !,
%    cpu_time((repeat_n(N),(Goal -> fail);true),D1),
%    cpu_time((repeat_n(N),(true -> fail);true),D2),
%    Duration is D1 - D2.




% % --- benchmarks of sample queries ---------

% benchmark(N,1,D):-
%    cpu_time(N,
%      (translate(flight(No,Dep,Dest,Type),flight(No,Dep,Dest,Type),Code),
% 	  printqueries(Code)),
%    D).

% benchmark(N,2,D):-
%    cpu_time(N,
%      (translate(capacity(No,Dep,Dest,Type,Seats),
% 	    (flight(No,Dep,Dest,Type),
% 		 plane(Type,Seats),
% 		 Type='b-737'),Code),
% 	   printqueries(Code)),
%    D).

% benchmark(N,3,D):-
%    cpu_time(N,
%       (translate(no_planes(No,Dep,Dest,Type),
% 	      (flight(No,Dep,Dest,Type),
% 		   not plane(Type,Seats)),Code),
% 	   printqueries(Code)),
% 	D).

% benchmark(N,4,D):-
%    cpu_time(N,(translate(X,X is count(S,plane(P,S)),Code),printqueries(Code)),D).

% benchmark(N,5,D):-
%    cpu_time(N,
%       (translate(big_planes(munich,Dest,Type,Seats),
% 	      FNo^(flight(FNo,munich,Dest,Type),
% 		       plane(Type,Seats),
% 			   Seats > avg(S, T^plane(T,S))),Code),
% 	  printqueries(Code)),
%    D).

% benchmark(N,6,D):-
%    cpu_time(N,(
%      translate(big_planes(munich,Dest,Type,Seats),
% 	     FNo^(flight(FNo,munich,Dest,Type),
% 		      plane(Type,Seats),
% 			  Seats > avg(S, T^plane(T,S))),Code),
% 		 printqueries(Code)),
%    D).

% benchmark(N,7,D):-
%    cpu_time(N,(
%      translate(big_planes(munich,Dest,Type,Seats),
% 	     FNo^(flight(FNo,munich,Dest,Type),
% 		      plane(Type,Seats),
% 			  Seats > avg(S, T^plane(T,S))),Code),
% 		 queries_atom(Code,SQLQueryAtom),
% 		 writeq(query_atom(SQLQueryAtom)),
% 		 nl),
%    D).
   
   
   


% % --- Meta Database for schema definition of SQL DB in Prolog --------------------------
% %
% % maps Prolog predicates to SQL table names, Prolog predicate argument positions to SQL
% % attributes, and Prolog operators to SQL operators. 
% %
% % ATTENTION! It is assumed that the arithmetic operators in Prolog and SQL are the same,
% % i.e. + is addition in Prolog and in SQL, etc. If this is not the case, then a mapping
% % function for arithmetic operators is necessary too.
% % --------------------------------------------------------------------------------------


% % --- relation(PrologFunctor,Arity,SQLTableName) ---------------------------------------

% relation(flight,4,'FLIGHT').
% relation(plane,2,'PLANE').


% % --- attribute(PrologArgumentPosition,SQLTableName,SQLAttributeName) ------------------

% attribute(1,'FLIGHT','FLIGHT_NO',string).
% attribute(2,'FLIGHT','DEPARTURE',string).
% attribute(3,'FLIGHT','DESTINATION',string).
% attribute(4,'FLIGHT','PLANE_TYPE',string).


% attribute(1,'PLANE','TYPE',string).
% attribute(2,'PLANE','SEATS',integer).


% --- Mapping of Prolog operators to SQL operators -------------------------------------

comparison(=,=).
comparison(<,<).
comparison(>,>).
comparison(@<,<).
comparison(@>,>).


negated_comparison(=,'<>').
negated_comparison(\=,=).
negated_comparison(>,=<).
negated_comparison(=<,>).
negated_comparison(<,>=).
negated_comparison(>=,<).


% --- aggregate_function(PrologFunctor,SQLFunction) -----------------

aggregate_functor(avg,'AVG').
aggregate_functor(min,'MIN').
aggregate_functor(max,'MAX').
aggregate_functor(sum,'SUM').
aggregate_functor(count,'COUNT').
aggregate_functor(countdistinct,'COUNTDISTINCT').



% --- type system --------------------------------------------------------------
%
% A rudimentary type system is provided for consistency checking during the
% translation and for output formatting
%
% The basic types are string and number. number has the subtypes integer and
% real.
%
% ------------------------------------------------------------------------------


type_compatible(Type,Type):-
   is_type(Type).
type_compatible(SubType,Type):-
   subtype(SubType,Type).
type_compatible(Type,SubType):-
   subtype(SubType,Type).


% --- subtype(SubType,SuperType) -----------------------------------------------
%
% Simple type hierarchy checking
%
% ------------------------------------------------------------------------------

subtype(SubType,SuperType):-
   is_subtype(SubType,SuperType).

subtype(SubType,SuperType):-
   is_subtype(SubType,InterType),
   subtype(InterType,SuperType).



% --- is_type(Type) ------------------------------------------------------------
%
% Type names
%
% ------------------------------------------------------------------------------

is_type(number).
is_type(integer).
is_type(real).
is_type(string).
is_type(natural).


% --- is_subtype(SubType,SuperType) --------------------------------------------
%
% Simple type hierarchy for numeric types
%
% ------------------------------------------------------------------------------

is_subtype(integer,number).
is_subtype(real,number).
is_subtype(natural,integer).


% --- get_type(Constant,Type) --------------------------------------------------
%
% Prolog implementation specific definition of type retrieval
% sepia Prolog version given here
%
% ------------------------------------------------------------------------------

get_type('$const$'(Constant),integer):-
   integer(Constant),!.

get_type('$const$'(Constant),real):-
   number(Constant),!.

get_type('$const$'(Constant),string):-
   atom(Constant).