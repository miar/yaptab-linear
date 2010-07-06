
:- module(dbusage, [
	db_usage/0,
	db_static/0,
	db_dynamic/0
    ]).

db_usage :-
	statistics(heap,[HeapUsed,HeapFree]),
	HeapUsedK is HeapUsed//1024,
	HeapFreeK is HeapFree//1024,
	format(user_error, 'Heap Space = ~d KB (+ ~d free)~n',[HeapUsedK,HeapFreeK]),	
	findall(p(Cls,CSz,ISz),
		(current_module(M),
		 current_predicate(_,M:P),
		 predicate_statistics(M:P,Cls,CSz,ISz)),LAll),
	sumall(LAll, TCls, TCSz, TISz),
	statistics(atoms,[AtomN,AtomS]),
	AtomSK is AtomS//1024,
	format(user_error, '~d Atoms taking ~d KB~n',[AtomN,AtomSK]),
	TSz is TCSz+TISz,
	TSzK is TSz//1024,
	TCSzK is TCSz//1024,
	TISzK is TISz//1024,
	format(user_error, 'Total User Code~n    ~d clauses taking ~d KB~n    ~d KB in clauses + ~d KB in indices~n',
	       [TCls,TSzK,TCSzK,TISzK]),
	statistics(static_code,[SCl,SI,SI1,SI2,SI3]),
	SClK is SCl//1024,
	SIK is SI//1024,
	SI1K is SI1//1024,
	SI2K is SI2//1024,
	SI3K is SI3//1024,
	ST is SCl+SI,
	STK is ST//1024,
	format(user_error, 'Total Static code=~d KB~n    ~dKB in clauses + ~dKB in indices (~d+~d+~d)~n',
	       [STK,SClK,SIK,SI1K,SI2K,SI3K]),
	statistics(dynamic_code,[DCl,DI,DI1,DI2,DI3,DI4]),
	DClK is DCl//1024,
	DIK is DI//1024,
	DI1K is DI1//1024,
	DI2K is DI2//1024,
	DI3K is DI3//1024,
	DI4K is DI4//1024,
	DT is DCl+DI,
	DTK is DT//1024,
	format(user_error, 'Total Dynamic code=~d KB~n    ~dKB in clauses + ~dKB in indices (~d+~d+~d+~d)~n',
	       [DTK,DClK,DIK,DI1K,DI2K,DI3K,DI4K]),
	total_erased(DCls,DSZ,ICls,ISZ),
	(DCls =:= 0 ->
	 true
	;
	 DSZK is DSZ//1024,
	 format(user_error, '    ~d erased clauses not reclaimed (~dKB)~n',[DCls,DSZK])
	),
	(ICls =:= 0 ->
	 true
	;
	 ISZK is ISZ//1024,
	 format(user_error, '    ~d erased indices not reclaimed (~dKB)~n',[ICls,ISZK])
	),
	!.

db_usage:-
	write(mem_dump_error),nl.


db_static :-
	setof(p(Sz,M:P,Cls,CSz,ISz),
	      PN^(current_module(M),
	       current_predicate(PN,M:P),
	       \+ predicate_property(M:P,dynamic),
	       predicate_statistics(M:P,Cls,CSz,ISz),
	       Sz is (CSz+ISz)),All),
	format(user_error,' Static user code~n===========================~n',[]),
	display_preds(All).

db_dynamic :-
	setof(p(Sz,M:P,Cls,CSz,ISz,ECls,ECSz,EISz),
	      PN^(current_module(M),
		  current_predicate(PN,M:P),
		  predicate_property(M:P,dynamic),
		  predicate_statistics(M:P,Cls,CSz,ISz),
		  predicate_erased_statistics(M:P,ECls,ECSz,EISz),
		  Sz is (CSz+ISz+ECSz+EISz)),
	      All),
	format(user_error,' Dynamic user code~n===========================~n',[]),
	display_dpreds(All).

display_preds([]).
display_preds([p(Sz,M:P,Cls,CSz,ISz)|_]) :-
	functor(P,A,N),
	KSz is Sz//1024,
	KCSz is CSz//1024,
	KISz is ISz//1024,
	(M = user -> Name = A/N ; Name = M:A/N),
	format(user_error,'~w~t~36+:~t~d~7+ clauses using~|~t~d~8+ KB (~d + ~d)~n',[Name,Cls,KSz,KCSz,KISz]),
	fail.
display_preds([_|All]) :-
	display_preds(All).


display_dpreds([]).
display_dpreds([p(Sz,M:P,Cls,CSz,ISz,ECls,ECSz,EISz)|_]) :-
	functor(P,A,N),
	KSz is Sz//1024,
	KCSz is CSz//1024,
	KISz is ISz//1024,
	(M = user -> Name = A/N ; Name = M:A/N),
	format(user_error,'~w~t~36+:~t~d~7+ clauses using~|~t~d~8+ KB (~d + ~d)~n',[Name,Cls,KSz,KCSz,KISz]),
	(ECls =:= 0
	->
	 true
	;
	 ECSzK is ECSz//1024,
	 format(user_error,'                        ~d erased clauses: ~d KB~n',[ECls,ECSzK])
	),
	(EISz =:= 0
	->
	 true
	;
	 EISzK is EISz//1024,
	 format(user_error,'                        ~d KB erased indices~n',[EISzK])
	),
	fail.
display_dpreds([_|All]) :-
	display_dpreds(All).


sumall(LEDAll, TEDCls, TEDCSz, TEDISz) :-
	sumall(LEDAll, 0, TEDCls, 0, TEDCSz, 0, TEDISz).

sumall([], TEDCls, TEDCls, TEDCSz, TEDCSz, TEDISz, TEDISz).
sumall([p(Cls,CSz,ISz)|LEDAll], TEDCls0, TEDCls, TEDCSz0, TEDCSz, TEDISz0, TEDISz) :-
	TEDClsI is Cls+TEDCls0,
	TEDCSzI is CSz+TEDCSz0,
	TEDISzI is ISz+TEDISz0,
	sumall(LEDAll, TEDClsI, TEDCls, TEDCSzI, TEDCSz, TEDISzI, TEDISz).

