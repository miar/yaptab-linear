#ifndef LINEAR_TAB_INSTS_H
#define LINEAR_TAB_INSTS_H

#ifdef DUMMY_PRINT
#define store_loader_node(TAB_ENT, ANSWER, TYPE)	      \
        { register choiceptr lcp;                             \
	  /* initialize lcp */                                \
          lcp = NORM_CP(LOAD_CP(YENV) - 1);                   \
          /* store loader choice point */                     \
          HBREG = H;                                          \
          store_yaam_reg_cpdepth(lcp);                        \
          lcp->cp_tr = TR;         	                      \
          lcp->cp_ap = LOAD_ANSWER;                           \
          lcp->cp_h  = H;                                     \
          lcp->cp_b  = B;                                     \
          lcp->cp_env= ENV;                                   \
          lcp->cp_cp = CPREG;                                 \
          LOAD_CP(lcp)->cp_last_answer = ANSWER;              \
          LOAD_CP(lcp)->type_of_node = TYPE;	              \
          store_low_level_trace_info(LOAD_CP(lcp), TAB_ENT);  \
          /* set_cut((CELL *)lcp, B); --> no effect */        \
          B = lcp;                                            \
          YAPOR_SET_LOAD(B);                                  \
          SET_BB(B);                                          \
          TABLING_ERRORS_check_stack;                         \
        }



#define DUMMY_LOCAL_nr_followers_inc()                  (LOCAL_nr_followers++)
#define DUMMY_LOCAL_nr_generators_inc()                 (LOCAL_nr_generators++)
#define DUMMY_LOCAL_nr_consumers_inc()                  (LOCAL_nr_consumers++)
#define DUMMY_LOCAL_nr_propagate_depen_cicles_inc()     (LOCAL_nr_propagate_depen_cicles++)

#define	DUMMY_LOCAL_nr_is_leader_and_has_new_answers_inc() (LOCAL_nr_is_leader_and_has_new_answers++)



#ifdef LINEAR_TABLING_DRE

#define DUMMY_DRE_table_try_with_looping_evaluating()                                             \
    DUMMY_LOCAL_nr_followers_inc();                                                               \
    LOCAL_nr_consumed_alternatives++;                                                             \
    INFO_LINEAR_TABLING("i7: LOCAL_nr_consumed_alternatives=%d",LOCAL_nr_consumed_alternatives);

#endif /*LINEAR_TABLING_DRE */



#else  /*!DUMMY_PRINT */

#define store_loader_node(TAB_ENT, ANSWER)	              \
        { register choiceptr lcp;                             \
	  /* initialize lcp */                                \
          lcp = NORM_CP(LOAD_CP(YENV) - 1);                   \
          /* store loader choice point */                     \
          HBREG = H;                                          \
          store_yaam_reg_cpdepth(lcp);                        \
          lcp->cp_tr = TR;         	                      \
          lcp->cp_ap = LOAD_ANSWER;                           \
          lcp->cp_h  = H;                                     \
          lcp->cp_b  = B;                                     \
          lcp->cp_env= ENV;                                   \
          lcp->cp_cp = CPREG;                                 \
          LOAD_CP(lcp)->cp_last_answer = ANSWER;              \
          store_low_level_trace_info(LOAD_CP(lcp), TAB_ENT);  \
          /* set_cut((CELL *)lcp, B); --> no effect */        \
          B = lcp;                                            \
          YAPOR_SET_LOAD(B);                                  \
          SET_BB(B);                                          \
          TABLING_ERRORS_check_stack;                         \
        }

#define DUMMY_LOCAL_nr_followers_inc()
#define DUMMY_LOCAL_nr_generators_inc()
#define DUMMY_LOCAL_nr_consumers_inc()
#define	DUMMY_LOCAL_nr_is_leader_and_has_new_answers_inc()
#define DUMMY_LOCAL_nr_propagate_depen_cicles_inc()

#ifdef LINEAR_TABLING_DRE
#define DUMMY_DRE_table_try_with_looping_evaluating()
#endif /*LINEAR_TABLING_DRE */


#endif /*DUMMY_PRINT*/


#ifdef LOW_LEVEL_TRACER
#define store_low_level_trace_info(CP, TAB_ENT)  CP->cp_pred_entry = TabEnt_pe(TAB_ENT)
#else
#define store_low_level_trace_info(CP, TAB_ENT)
#endif /* LOW_LEVEL_TRACER */

#ifdef TABLING_ERRORS
#define TABLING_ERRORS_check_stack                                                     \
        if (Unsigned(H) + 1024 > Unsigned(B))                                          \
	  TABLING_ERROR_MESSAGE("H + 1024 > B (check_stack)");                         \
        if (Unsigned(H_FZ) + 1024 > Unsigned(B))                                       \
	  TABLING_ERROR_MESSAGE("H_FZ + 1024 > B (check_stack)")
#define TABLING_ERRORS_consume_answer_and_procceed                                     \
        if (IS_BATCHED_GEN_CP(B))                                                      \
	  TABLING_ERROR_MESSAGE("IS_BATCHED_GEN_CP(B) (consume_answer_and_procceed)")
#else
#define TABLING_ERRORS_check_stack
#define TABLING_ERRORS_consume_answer_and_procceed
#endif /* TABLING_ERRORS */


#define store_generator_node(TAB_ENT, SG_FR, ARITY, AP)               \
        { register CELL *pt_args;                                     \
          DUMMY_LOCAL_nr_generators_inc();                            \
          register choiceptr gcp;                                     \
          /* store args */                                            \
          pt_args = XREGS + (ARITY);                                  \
	  while (pt_args > XREGS) {                                   \
            register CELL aux_arg = pt_args[0];                       \
            --YENV;                                                   \
            --pt_args;                                                \
            *YENV = aux_arg;                                          \
	  }                                                           \
          /* initialize gcp and adjust subgoal frame field */         \
          YENV = (CELL *) (GEN_CP(YENV) - 1);                         \
          gcp = NORM_CP(YENV);                                        \
          SgFr_gen_cp(SG_FR) = gcp;                                   \
          /* store generator choice point */                          \
          HBREG = H;						      \
          store_yaam_reg_cpdepth(gcp);                                \
          gcp->cp_tr = TR;                                            \
          gcp->cp_ap = (yamop *)(AP);                                 \
          gcp->cp_h  = H;                                             \
          gcp->cp_b  = B;                                             \
          gcp->cp_env = ENV;                                          \
          gcp->cp_cp = CPREG;		                              \
          GEN_CP(gcp)->cp_sg_fr = SG_FR;                              \
          store_low_level_trace_info(GEN_CP(gcp), TAB_ENT);           \
          set_cut((CELL *)gcp, B);                                    \
          B = gcp;                                                    \
          YAPOR_SET_LOAD(B);                                          \
          SET_BB(B);                                                  \
          TABLING_ERRORS_check_stack;                                 \
        }



#define restore_generator_node(ARITY, AP)               \
        { register CELL *pt_args, *x_args;              \
          register choiceptr gcp = B;                   \
          /* restore generator choice point */          \
          H = HBREG = PROTECT_FROZEN_H(gcp);     	\
          restore_yaam_reg_cpdepth(gcp);                \
          CPREG = gcp->cp_cp;                           \
          ENV = gcp->cp_env;                            \
          YAPOR_update_alternative(PREG, (yamop *) AP)  \
          gcp->cp_ap = (yamop *) AP;                    \
          /* restore args */                            \
          pt_args = (CELL *)(GEN_CP(gcp) + 1) + ARITY;  \
          x_args = XREGS + 1 + ARITY;                   \
          while (x_args > XREGS + 1) {                  \
            register CELL x = pt_args[-1];              \
            --x_args;                                   \
            --pt_args;                                  \
            *x_args = x;                                \
	  }                                             \
        }


#define pop_generator_node(ARITY)               \
        { register CELL *pt_args, *x_args;      \
          register choiceptr gcp = B;           \
          /* pop generator choice point */      \
          H = PROTECT_FROZEN_H(gcp);            \
          pop_yaam_reg_cpdepth(gcp);            \
          CPREG = gcp->cp_cp;                   \
          ENV = gcp->cp_env;                    \
          TR = gcp->cp_tr;                      \
          B = gcp->cp_b;                        \
          HBREG = PROTECT_FROZEN_H(B);		\
          /* pop args */                        \
          x_args = XREGS + 1 ;                  \
          pt_args = (CELL *)(GEN_CP(gcp) + 1);  \
	  while (x_args < XREGS + 1 + ARITY) {  \
            register CELL x = pt_args[0];       \
            pt_args++;                          \
            x_args++;                           \
            x_args[-1] = x;                     \
          }                                     \
          YENV = pt_args;		    	\
          SET_BB(PROTECT_FROZEN_B(B));          \
        }


#define restore_loader_node(ANSWER)           \
        H = HBREG = PROTECT_FROZEN_H(B);      \
        restore_yaam_reg_cpdepth(B);          \
        CPREG = B->cp_cp;                     \
        ENV = B->cp_env;                      \
        LOAD_CP(B)->cp_last_answer = ANSWER;  \
        SET_BB(PROTECT_FROZEN_B(B))

#define pop_loader_node()             \
        H = PROTECT_FROZEN_H(B);      \
        pop_yaam_reg_cpdepth(B);      \
	CPREG = B->cp_cp;             \
        TABLING_close_alt(B);	      \
        ENV = B->cp_env;              \
	B = B->cp_b;	              \
        HBREG = PROTECT_FROZEN_H(B);  \
        SET_BB(PROTECT_FROZEN_B(B))


#ifdef DEPTH_LIMIT
#define allocate_environment()        \
        YENV[E_CP] = (CELL) CPREG;    \
        YENV[E_E] = (CELL) ENV;       \
        YENV[E_B] = (CELL) B;         \
        YENV[E_DEPTH] = (CELL)DEPTH;  \
        ENV = YENV
#else
#define allocate_environment()        \
        YENV[E_CP] = (CELL) CPREG;    \
        YENV[E_E] = (CELL) ENV;       \
        YENV[E_B] = (CELL) B;         \
        ENV = YENV
#endif /* DEPTH_LIMIT */


/*-------------------------------------AUX TO COMMOM TABLING INSTRUCTIONS ----------------------*/



#define table_try_begin(void)	 		 		 	      \
    tab_ent_ptr tab_ent;                                                      \
    sg_fr_ptr sg_fr;                                                          \
    check_trail(TR);                                                          \
    tab_ent = PREG->u.Otapl.te;                                               \
    YENV2MEM;                                                                 \
    sg_fr = subgoal_search(PREG, YENV_ADDRESS); /*incomplete subgoals*/       \
    INFO_LINEAR_TABLING("sg_fr= %p   state=%d",sg_fr,SgFr_state(sg_fr));      \
    MEM2YENV;                                                                 \
    LOCK(SgFr_lock(sg_fr))


#define add_alternative(SG_FR,pc)						              \
  {                                                                                           \
      if (SgFr_state(SG_FR) == evaluating) {				                      \
          if (SgFr_current_loop_alt(SG_FR)==NULL) {	  		       	              \
	    SgFr_current_loop_alt(SG_FR)= SgFr_loop_alts(SG_FR);	                      \
	    SET_CELL_VALUE(SgFr_current_loop_alt(SG_FR),pc);                                  \
   	    INFO_LINEAR_TABLING("add_alternative=%p",pc);                                     \
          } else if (GET_CELL_VALUE(SgFr_current_loop_alt(SG_FR))!= pc) {                     \
            SgFr_current_loop_alt(SG_FR)++;                                                   \
   	    if (IS_JUMP_CELL(SgFr_current_loop_alt(SG_FR))){                                  \
	      yamop *nb;                                                                      \
              ALLOC_ALTERNATIVES_BUCKET(nb);				                      \
   	      ALT_TAG_AS_JUMP_CELL(SgFr_current_loop_alt(SG_FR),nb);                          \
              SgFr_current_loop_alt(SG_FR)=nb;					              \
	    }                                                                                 \
	    SET_CELL_VALUE(SgFr_current_loop_alt(SG_FR),pc);	                              \
	    INFO_LINEAR_TABLING("add_alternative=%p",pc);		                      \
          }                                                                                   \
	}                                                                                     \
   }




inline void propagate_dependencies(sg_fr_ptr sg_fr){
  sg_fr_ptr sf_aux=LOCAL_top_sg_fr_on_branch;                                        
  int dfn=GET_SGFR_DFN(sg_fr);                                                       
  INFO_LINEAR_TABLING("propagate dependencies upto to sg_fr=%p",sg_fr);
  while(sf_aux && (GET_SGFR_DFN(sf_aux) >dfn 
#ifdef LINEAR_TABLING_DRS
	||SgFr_consuming_answers(sf_aux)==1)){
#else  
       )){
#endif /*LINEAR_TABLING_DRS */
       DUMMY_LOCAL_nr_propagate_depen_cicles_inc();
       INFO_LINEAR_TABLING("sgfr_aux=%p",sf_aux);                                       
       TAG_AS_NO_LEADER(sf_aux);
#ifdef LINEAR_TABLING_DRS
   if(SgFr_consuming_answers(sf_aux)==1){
       add_answer(sf_aux,SgFr_new_answer_trie(sf_aux))
    }
#endif /*LINEAR_TABLING_DRS */
#if defined(LINEAR_TABLING_DRA) && defined(LINEAR_TABLING_DRS)
    else 
#endif /*LINEAR_TABLING_DRA && LINEAR_TABLING_DRS */
#ifdef LINEAR_TABLING_DRA
   add_alternative(sf_aux, SgFr_current_alt(sf_aux));			     
#endif /*LINEAR_TABLING_DRA*/
       sf_aux = SgFr_next_on_branch(sf_aux);		        	             
  }	                                                                             
  if (sf_aux) {	
#ifdef LINEAR_TABLING_DRS
   if(SgFr_consuming_answers(sf_aux)==1){
       add_answer(sf_aux,SgFr_new_answer_trie(sf_aux))
    }
#endif /*LINEAR_TABLING_DRS */
#if defined(LINEAR_TABLING_DRA) && defined(LINEAR_TABLING_DRS)
    else 
#endif /*LINEAR_TABLING_DRA && LINEAR_TABLING_DRS */
#ifdef LINEAR_TABLING_DRA
   add_alternative(sf_aux, SgFr_current_alt(sf_aux));			     
#endif /*LINEAR_TABLING_DRA*/
  }
  return;
}							                             



inline void consume_all_answers_on_trie(tab_ent_ptr tab_ent,ans_node_ptr ans_node,sg_fr_ptr sg_fr) {
  /* answers -> get first answer */                     
  UNLOCK(SgFr_lock(sg_fr));
#ifdef DUMMY_PRINT
  DUMMY_LOCAL_nr_consumers_inc();
  store_loader_node(tab_ent, ans_node,0);	       
#else
  store_loader_node(tab_ent, ans_node);		
#endif
  PREG = (yamop *) CPREG;                             
  PREFETCH_OP(PREG);                                    
  load_answer(ans_node, YENV);                     
  YENV = ENV;                                
  return;
}



inline void table_try_single_with_ready(sg_fr_ptr sg_fr, yamop* PREG_CI, tab_ent_ptr tab_ent){
#ifdef DUMMY_PRINT
  LOCAL_nr_consumed_alternatives++;
  INFO_LINEAR_TABLING("i3: LOCAL_nr_consumed_alternatives=%d",LOCAL_nr_consumed_alternatives);
#endif /* DUMMY_PRINT */
  init_subgoal_frame(sg_fr,tab_ent);
  add_branch(sg_fr);
  add_max_scc(sg_fr);
  add_next(sg_fr);
  UNLOCK(SgFr_lock(sg_fr));
  store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, COMPLETION);
#ifdef LINEAR_TABLING_DRE
  SgFr_pioneer(sg_fr)=B;
  SgFr_next_alt(sg_fr)= NULL;
#endif /*LINEAR_TABLING_DRE */
#ifdef LINEAR_TABLING_DRA
  SgFr_current_alt(sg_fr) =  PREG_CI;
#else 
  add_alternative(sg_fr,PREG_CI);
#endif  /*LINEAR_TABLING_DRA */
  PREG = PREG_CI;                          
  PREFETCH_OP(PREG);
  allocate_environment();
  return;
}



inline void table_try_with_ready(sg_fr_ptr sg_fr, yamop* PREG_CI, yamop* PREG_NI,tab_ent_ptr tab_ent){
#ifdef DUMMY_PRINT
  LOCAL_nr_consumed_alternatives++;
  INFO_LINEAR_TABLING("i3: LOCAL_nr_consumed_alternatives=%d",LOCAL_nr_consumed_alternatives);
#endif /* DUMMY_PRINT */
  init_subgoal_frame(sg_fr,tab_ent);
  add_branch(sg_fr);
  add_max_scc(sg_fr);
  add_next(sg_fr);
  UNLOCK(SgFr_lock(sg_fr));
#ifdef LINEAR_TABLING_DRE
  store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, COMPLETION);
  SgFr_pioneer(sg_fr)=B;
  SgFr_next_alt(sg_fr)= PREG_NI;
#else
  store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, PREG_NI);
#endif /*LINEAR_TABLING_DRE */
#ifdef LINEAR_TABLING_DRA
  SgFr_current_alt(sg_fr) =  PREG_CI;
#else 
  add_alternative(sg_fr,PREG_CI);
#endif  /*LINEAR_TABLING_DRA */
  PREG = PREG_CI;                          
  PREFETCH_OP(PREG);
  allocate_environment();
  return;
}



inline void table_try_with_looping_ready(sg_fr_ptr sg_fr){
#ifdef DUMMY_PRINT
  LOCAL_nr_consumed_alternatives++;
  INFO_LINEAR_TABLING("i3: LOCAL_nr_consumed_alternatives=%d",LOCAL_nr_consumed_alternatives);
#endif /* DUMMY_PRINT */
  INFO_LINEAR_TABLING("table_try_with_looping_ready");
  add_max_scc(sg_fr);
  add_next(sg_fr);
  SgFr_state(sg_fr) = looping_evaluating; 
  SgFr_stop_loop_alt(sg_fr)=SgFr_current_loop_alt(sg_fr) = SgFr_first_loop_alt(sg_fr);
  store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, COMPLETION);
#ifdef LINEAR_TABLING_DRE
  SgFr_pioneer(sg_fr)=B;
#endif  /*LINEAR_TABLING_DRE*/
  if(IS_BATCHED_SF(sg_fr) && SgFr_first_answer(sg_fr)){
    //B->cp_ap= (yamop *)TRY_ANSWER;
    INFO_LINEAR_TABLING("table_try_with_looping_ready answer");
    SgFr_current_batched_answer(LOCAL_top_sg_fr) = SgFr_first_answer(sg_fr);
    PREG= (yamop *) TRY_ANSWER;   
  } else{     
    PREG = GET_CELL_VALUE(SgFr_current_loop_alt(sg_fr));
    PREFETCH_OP(PREG);
    allocate_environment();
  }
  return;
}


inline void table_try_with_completed(sg_fr_ptr sg_fr,ans_node_ptr ans_node,tab_ent_ptr tab_ent){
    /* answers -> get first answer */
    if (IsMode_LoadAnswers(TabEnt_mode(tab_ent))) {
      /* load answers from the trie */
      UNLOCK(SgFr_lock(sg_fr));
      // if(TrNode_child(ans_node) != NULL) {
#ifdef DUMMY_PRINT
	store_loader_node(tab_ent, ans_node,0);
#else /*!DUMMY_PRINT */
	store_loader_node(tab_ent, ans_node);
#endif /*DUMMY_PRINT */
	//}
      PREG = (yamop *) CPREG;
      PREFETCH_OP(PREG);
      load_answer(ans_node, YENV);
      YENV = ENV;
    } else {
      /* execute compiled code from the trie */
      if (SgFr_state(sg_fr) < compiled)
	update_answer_trie(sg_fr);
      UNLOCK(SgFr_lock(sg_fr));
      PREG = (yamop *) TrNode_child(SgFr_answer_trie(sg_fr));
      PREFETCH_OP(PREG);
      *--YENV = 0;  /* vars_arity */
      *--YENV = 0;  /* heap_arity */
    }
    return;
}



inline void table_retry(yamop* PREG_CI, yamop* PREG_NI){
#ifdef DUMMY_PRINT
    LOCAL_nr_consumed_alternatives++;
    INFO_LINEAR_TABLING("i8: LOCAL_nr_consumed_alternatives=%d",LOCAL_nr_consumed_alternatives);
#endif /* DUMMY_PRINT */
    sg_fr_ptr sg_fr = GEN_CP(B)->cp_sg_fr;
#ifdef LINEAR_TABLING_DRE
    restore_generator_node(PREG->u.Otapl.s, COMPLETION);
    SgFr_next_alt(sg_fr)=PREG_NI;
#else
    restore_generator_node(PREG->u.Otapl.s, PREG_NI);
#endif  /*LINEAR_TABLING_DRE */

#ifdef LINEAR_TABLING_DRA
    SgFr_current_alt(sg_fr) = PREG_CI;
#else
    add_alternative(sg_fr,PREG_CI); 
#endif /*LINEAR_TABLING_DRA*/
    YENV = (CELL *) PROTECT_FROZEN_B(B);
    set_cut(YENV, B->cp_b);
    SET_BB(NORM_CP(YENV));
    PREG = PREG_CI;
    allocate_environment();
    return;
}


inline void table_trust(yamop* PREG_CI){
/*------------------------------------------------LINEAR TABLING------------------------------*/
#ifdef DUMMY_PRINT
  LOCAL_nr_consumed_alternatives++;
  INFO_LINEAR_TABLING("i10: LOCAL_nr_consumed_alternatives=%d",LOCAL_nr_consumed_alternatives);
#endif /* DUMMY_PRINT */
    sg_fr_ptr sg_fr = GEN_CP(B)->cp_sg_fr; 
#ifdef LINEAR_TABLING_DRE
    SgFr_next_alt(sg_fr)= NULL;
#endif /* LINEAR_TABLING_DRE */
#ifdef LINEAR_TABLING_DRA
    SgFr_current_alt(sg_fr) = PREG_CI;
#else 
    add_alternative(sg_fr,PREG_CI);
#endif /*LINEAR_TABLING_DRA */ 
    restore_generator_node(PREG->u.Otapl.s, COMPLETION);
    YENV = (CELL *) PROTECT_FROZEN_B(B);
    set_cut(YENV, B->cp_b);
    SET_BB(NORM_CP(YENV));
    PREG = PREG_CI;
    allocate_environment();
    return;
}


inline void table_completion_launch_next_loop_alt(sg_fr_ptr sg_fr,yamop **next_loop_alt){
  restore_generator_node(SgFr_arity(sg_fr), COMPLETION);
  YENV = (CELL *) PROTECT_FROZEN_B(B);
  set_cut(YENV, B->cp_b);
  SET_BB(NORM_CP(YENV));
  PREG = GET_CELL_VALUE(SgFr_current_loop_alt(sg_fr));
  INFO_LINEAR_TABLING("current_alt=%p",PREG);
  PREFETCH_OP(PREG);
#ifdef DUMMY_PRINT
  LOCAL_nr_consumed_alternatives++;
  INFO_LINEAR_TABLING("i2: LOCAL_nr_consumed_alternatives=%d",LOCAL_nr_consumed_alternatives);
#endif /* DUMMY_PRINT */
  allocate_environment();
  return;
}


#endif /*LINEAR_TAB_INSTS_H */
