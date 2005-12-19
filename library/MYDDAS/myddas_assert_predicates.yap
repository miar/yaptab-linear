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
* File:		myddas_assert_predicates.yap	                         *
* Last rev:							         *
* mods:									 *
* comments:	Predicates that assert other for the MyDDAS Interface	 *
*									 *
*************************************************************************/

:- module(myddas_assert_predicates,[
				    db_import/3,
				    db_view/3,
				    db_insert/3
				   ]).


:- use_module(myddas,[
		      db_module/1
		     ]).

:- use_module(myddas_errors,[
			     '$error_checks'/1
			     ]).

:- use_module(myddas_util_predicates,[
				      '$get_values_for_insert'/3,
				      '$make_atom'/2,
				      '$write_or_not'/1,
				      '$copy_term_nv'/4,
				      '$assert_attribute_information'/4,
				      '$make_a_list'/2,
				      '$make_list_of_args'/4,
				      '$where_exists'/2,
				      '$build_query'/5
				      ]).

:- use_module(myddas_prolog2sql,[
				 translate/3,
				 queries_atom/2
				]).
:- use_module(myddas_mysql,[
			    db_my_result_set/1
			    ]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% db_import/3
%
%
db_import(Connection,RelationName,PredName) :-
	'$error_checks'(db_import(Connection,RelationName,PredName)),
	get_value(Connection,Con),
	c_db_connection_type(Con,ConType),
		
	% get relation arity
        ( ConType == mysql ->
	    c_db_my_number_of_fields(RelationName,Con,Arity)
	;
	    c_db_odbc_number_of_fields(RelationName,Con,Arity)
	),
	db_module(Module),
	not c_db_check_if_exists_pred(PredName,Arity,Module),

	R=..[relation,PredName,Arity,RelationName],
	% assert relation fact
	assert(myddas_prolog2sql:R),
	
	Size is 2*Arity,
        '$make_a_list'(Size,TypesList),
	% get attributes types in TypesList [field0,type0,field1,type1...]
	( ConType == mysql ->
	    c_db_my_get_attributes_types(RelationName,Con,TypesList)
	;
	    c_db_odbc_get_attributes_types(RelationName,Con,TypesList)
	),
	
	% assert attributes facts 
        '$assert_attribute_information'(0,Arity,RelationName,TypesList),

	% build PredName functor
	functor(P,PredName,Arity),
	'$make_list_of_args'(1,Arity,P,LA),

	%Optimization
	'$copy_term_nv'(P,[],G,_),

	%generate the SQL query
	translate(G,G,Code),
	queries_atom(Code,SQL),

	%build PredName clause
	( ConType == mysql ->
	    Assert =..[':-',P,','(myddas_assert_predicates:'$build_query'(0,SQL,Code,LA,FinalSQL),
				  ','(myddas_assert_predicates:db_my_result_set(Mode),
				      ','(myddas_assert_predicates:'$write_or_not'(FinalSQL),
					  ','(myddas_assert_predicates:c_db_my_query(FinalSQL,ResultSet,Con,Mode),
					      ','(!,myddas_assert_predicates:c_db_my_row(ResultSet,Arity,LA))))))]
	    
% 	    Assert =..[':-',P,','(get_value(db_myddas_stats_count,Number),
% 				  ','(statistics(cputime,TimeI),
% 				      ','(myddas_assert_predicates:'$build_query'(0,SQL,Code,LA,FinalSQL),
% 					  ','(myddas_assert_predicates:db_my_result_set(Mode),
% 					      ','(myddas_assert_predicates:'$write_or_not'(FinalSQL),
% 						  ','(myddas_assert_predicates:c_db_my_query(FinalSQL,ResultSet,Con,Mode),
% 						      ','(statistics(cputime,TimeF),
% 							  ','(Temp is TimeF - TimeI,
% 							      ','(Temp2 is Temp + Number,
% 								  ','(set_value(db_myddas_stats_count,Temp2),
% 								      ','(!,myddas_assert_predicates:c_db_my_row(ResultSet,Arity,LA))))))))))))]
	    ;
	    
	    Assert =..[':-',P,','(myddas_assert_predicates:'$build_query'(0,SQL,Code,LA,FinalSQL),
				  ','(myddas_assert_predicates:'$make_a_list'(Arity,BindList),
				      ','(myddas_assert_predicates:c_db_odbc_query(FinalSQL,ResultSet,Arity,BindList,Connection),
					  ','(myddas_assert_predicates:'$write_or_not'(FinalSQL),
					      ','(!,myddas_assert_predicates:c_db_odbc_row(ResultSet,BindList,LA))))))]
	    ),
	
	assert(Module:Assert),
	c_db_add_preds(PredName,Arity,Module,Con).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% db_view/3
%
%
db_view(Connection,PredName,DbGoal) :-
	'$error_checks'(db_view(Connection,PredName,DbGoal)),
	get_value(Connection,Con),
		
       	% get arity of projection term
	functor(PredName,ViewName,Arity),
	functor(NewName,ViewName,Arity),
	db_module(Module),
	not c_db_check_if_exists_pred(ViewName,Arity,Module),

	% This copy_term is done to prevent the unification
	% with top-level variables   A='var('A')' error
	copy_term((PredName,DbGoal),(CopyView,CopyGoal)),
	translate(CopyView,CopyGoal,Code),
	queries_atom(Code,SQL),

	% checks if the WHERE commend of SQL exists in the string
	'$where_exists'(SQL,Flag),

	'$make_list_of_args'(1,Arity,NewName,LA),

	c_db_connection_type(Con,ConType),
	% build view clause
	( ConType == mysql ->
	    Assert =..[':-',NewName,
		       ','(myddas_assert_predicates:'$build_query'(Flag,SQL,Code,LA,FinalSQL),
			   ','(myddas_assert_predicates:db_my_result_set(Mode),
			       ','(myddas_assert_predicates:'$write_or_not'(FinalSQL),
				   ','(myddas_assert_predicates:c_db_my_query(FinalSQL,ResultSet,Con,Mode),
				       ','(!,myddas_assert_predicates:c_db_my_row(ResultSet,Arity,LA))))))]
	    ;
	    Assert =..[':-',NewName,
		       ','(myddas_assert_predicates:'$build_query'(Flag,SQL,Code,LA,FinalSQL),
			   ','(myddas_assert_predicates:'$make_a_list'(Arity,BindList),
			       ','(myddas_assert_predicates:'$write_or_not'(FinalSQL),
				   ','(myddas_assert_predicates:c_db_odbc_query(FinalSQL,ResultSet,Arity,BindList,Con),
				       ','(!,myddas_assert_predicates:c_db_odbc_row(ResultSet,BindList,LA))))))]
	    
	    ),
	assert(Module:Assert),
	c_db_add_preds(ViewName,Arity,Module,Con).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% db_insert/3
%
%
db_insert(Connection,RelationName,PredName) :-
	'$error_checks'(db_insert3(Connection,RelationName,PredName)),
	get_value(Connection,Con),
	c_db_connection_type(Con,ConType),

	% get relation arity
	( ConType == mysql ->
	    c_db_my_number_of_fields(RelationName,Con,Arity)
	;
	    c_db_odbc_number_of_fields(RelationName,Con,Arity)
	),
	db_module(Module),
	not c_db_check_if_exists_pred(PredName,Arity,Module),

	R=..[relation,PredName,Arity,RelationName],
	% assert relation fact
	assert(myddas_prolog2sql:R),

	% build PredName functor
	functor(Predicate,PredName,Arity),
	'$make_list_of_args'(1,Arity,Predicate,LA),

	Size is 2*Arity,
        '$make_a_list'(Size,TypesList),

	% get attributes types in TypesList [field0,type0,field1,type1...]
	% and build PredName clause
	( ConType == mysql ->
	    c_db_my_get_attributes_types(RelationName,Con,TypesList),
	    Assert =..[':-',Predicate,','(myddas_assert_predicates:'$get_values_for_insert'(TypesList,LA,ValuesList),
					  ','(myddas_assert_predicates:'$make_atom'(['INSERT INTO ',RelationName,' VALUES ('|ValuesList],SQL),
					      ','(myddas_assert_predicates:db_my_result_set(Mode),
						  ','(myddas_assert_predicates:'$write_or_not'(SQL),
						      myddas_assert_predicates:c_db_my_query(SQL,_,Con,Mode)))))]
	;
	    c_db_odbc_get_attributes_types(RelationName,Con,TypesList),
	    Assert =..[':-',Predicate,','(myddas_assert_predicates:'$get_values_for_insert'(TypesList,LA,ValuesList),
					  ','(myddas_assert_predicates:'$make_atom'(['INSERT INTO ',RelationName,' VALUES ('|ValuesList],SQL),
					      ','(myddas_assert_predicates:'$write_or_not'(SQL),
						  myddas_assert_predicates:c_db_odbc_query(SQL,_,_,_,Con))))]
	),
	assert(Module:Assert),
	c_db_add_preds(PredName,Arity,Module,Con).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%