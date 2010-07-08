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
#else
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
          gcp->cp_cp = CPREG;                                         \
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



/*-------------------------------------COMMOM ON SLDT INSTRUCTIONS ------------------------*/
#define table_try_begin(void)	 		 		 	      \
    tab_ent_ptr tab_ent;                                                      \
    sg_fr_ptr sg_fr;                                                          \
    check_trail(TR);                                                          \
    tab_ent = PREG->u.Otapl.te;                                               \
    YENV2MEM;                                                                 \
    sg_fr = subgoal_search(PREG, YENV_ADDRESS);                               \
    INFO_LINEAR_TABLING("sg_fr= %p   state=%d",sg_fr,SgFr_state(sg_fr));      \
    MEM2YENV;                                                                 \
    LOCK(SgFr_lock(sg_fr))



STD_PROTO(static inline void table_try_single_with_ready, (sg_fr_ptr,yamop *));
STD_PROTO(static inline void table_try_with_ready, (sg_fr_ptr,yamop *,yamop*));
STD_PROTO(static inline void table_try_with_evaluating, (sg_fr_ptr));
STD_PROTO(static inline void table_try_with_looping_ready, (sg_fr_ptr));
STD_PROTO(static inline void table_try_with_looping_evaluating, (sg_fr_ptr));
STD_PROTO(static inline void table_try_with_complete,(sg_fr_ptr,ans_node_ptr,tab_ent_ptr));



static inline void table_try_single_with_ready(sg_fr_ptr sg_fr, yamop* PREG_CI){
#ifdef DUMMY_PRINT
  LOCAL_nr_consumed_alternatives++;
  INFO_LINEAR_TABLING("i3: LOCAL_nr_consumed_alternatives=%d",LOCAL_nr_consumed_alternatives);
#endif /* DUMMY_PRINT */
  init_subgoal_frame(sg_fr);
  UNLOCK(SgFr_lock(sg_fr));
  store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, COMPLETION);
#ifdef LINEAR_TABLING_DRE
  SgFr_pioneer(sg_fr)=B;
  SgFr_next_alt(sg_fr)= NULL;
#endif /*LINEAR_TABLING_DRE */
  add_branch(sg_fr);
  add_max_scc(sg_fr);
  add_next(sg_fr);
#ifdef LINEAR_TABLING_DRA
  SgFr_current_alt(sg_fr) =  PREG_CI;
#else 
  add_alternative(sg_fr,PREG_CI);
#endif  /*LINEAR_TABLING_DRA */
  PREG = PREG_CI;                          
  PREFETCH_OP(PREG);
  allocate_environment();
  GONext();
}


static inline void table_try_with_ready(sg_fr_ptr sg_fr, yamop* PREG_CI, yamop* PREG_NI){
#ifdef DUMMY_PRINT
  LOCAL_nr_consumed_alternatives++;
  INFO_LINEAR_TABLING("i3: LOCAL_nr_consumed_alternatives=%d",LOCAL_nr_consumed_alternatives);
#endif /* DUMMY_PRINT */
  init_subgoal_frame(sg_fr);
  UNLOCK(SgFr_lock(sg_fr));
#ifdef LINEAR_TABLING_DRE
  store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, COMPLETION);
  SgFr_pioneer(sg_fr)=B;
  SgFr_next_alt(sg_fr)= PREG_NI;
#else
  store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, PREG_NI);
#endif /*LINEAR_TABLING_DRE */
  add_branch(sg_fr);
  add_max_scc(sg_fr);
  add_next(sg_fr);
#ifdef LINEAR_TABLING_DRA
  SgFr_current_alt(sg_fr) =  PREG_CI;
#else 
  add_alternative(sg_fr,PREG_CI);
#endif  /*LINEAR_TABLING_DRA */
  PREG = PREG_CI;                          
  PREFETCH_OP(PREG);
  allocate_environment();
  GONext();
}



static inline void table_try_with_looping_ready(sg_fr_ptr sg_fr){
#ifdef DUMMY_PRINT
  LOCAL_nr_consumed_alternatives++;
  INFO_LINEAR_TABLING("i3: LOCAL_nr_consumed_alternatives=%d",LOCAL_nr_consumed_alternatives);
#endif /* DUMMY_PRINT */
  add_max_scc(sg_fr);
  add_next(sg_fr);
  store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, COMPLETION);
#ifdef LINEAR_TABLING_DRE
  SgFr_pioneer(sg_fr)=B;
#endif  /*LINEAR_TABLING_DRE*/
  SgFr_state(sg_fr) = looping_evaluating; 
  //  batched_consume_first_answer(sg_fr);
  /*else */
  SgFr_stop_loop_alt(sg_fr)=SgFr_current_loop_alt(sg_fr)= SgFr_first_loop_alt(sg_fr);
  PREG = GET_CELL_VALUE(SgFr_current_loop_alt(sg_fr));
  PREFETCH_OP(PREG);
  allocate_environment();
  GONext();
}


static inline void table_try_with_evaluating(sg_fr_ptr sg_fr){
  propagate_dependencies(sg_fr);
#ifdef LINEAR_TABLING_DRE
  if (SgFr_next_alt(sg_fr)!=NULL){
    INFO_LINEAR_TABLING("follower");
    DUMMY_LOCAL_nr_followers_inc();
    register choiceptr gcp_temp=SgFr_gen_cp(sg_fr);
    store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, COMPLETION);
    add_next_follower(sg_fr);
    SgFr_gen_cp(sg_fr)=gcp_temp;
    PREG = SgFr_next_alt(sg_fr);
    PREFETCH_OP(PREG);
    allocate_environment();
    GONext();
  }            
#endif /*LINEAR_TABLING_DRE */
  //  consume_answers(tab_ent,sg_fr);
}


static inline void table_try_with_looping_evaluating(sg_fr_ptr sg_fr){
  propagate_dependencies(sg_fr);
#ifdef LINEAR_TABLING_DRE
  yamop **follower_alt=SgFr_current_loop_alt(sg_fr)+1;
  if (IS_JUMP_CELL(follower_alt))
    ALT_JUMP_NEXT_CELL(follower_alt);	  
  if (follower_alt != SgFr_stop_loop_alt(sg_fr)){
    INFO_LINEAR_TABLING("follower");
#ifdef DUMMY_PRINT
    DUMMY_LOCAL_nr_followers_inc();
    LOCAL_nr_consumed_alternatives++;
    INFO_LINEAR_TABLING("i7: LOCAL_nr_consumed_alternatives=%d",LOCAL_nr_consumed_alternatives);
#endif /* DUMMY_PRINT */
    register choiceptr gcp_temp=SgFr_gen_cp(sg_fr);
    store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, COMPLETION);
    add_next_follower(sg_fr);
    SgFr_gen_cp(sg_fr)=gcp_temp;
    SgFr_current_loop_alt(sg_fr)=follower_alt;
    PREG = GET_CELL_VALUE(SgFr_current_loop_alt(sg_fr));
    PREFETCH_OP(PREG);
    allocate_environment();
    GONext();
  }
#endif /*LINEAR_TABLING_DRE */
  //  consume_answers(tab_ent,sg_fr);
}


static inline void table_try_with_completed(sg_fr_ptr sg_fr,ans_node_ptr ans_node,tab_ent_ptr tab_ent){
  /*  ans_node_ptr ans_node = SgFr_first_answer(sg_fr);
    if (ans_node == NULL) {
     no answers --> fail 
    UNLOCK(SgFr_lock(sg_fr));
    goto fail;
    } else */
  if (ans_node == SgFr_answer_trie(sg_fr)) {
    /* yes answer --> procceed */
    UNLOCK(SgFr_lock(sg_fr));
    PREG = (yamop *) CPREG;
    PREFETCH_OP(PREG);
    YENV = ENV;
    GONext();
  } else {
    /* answers -> get first answer */
    if (IsMode_LoadAnswers(TabEnt_mode(tab_ent))) {
      /* load answers from the trie */
      UNLOCK(SgFr_lock(sg_fr));
      if(TrNode_child(ans_node) != NULL) {
#ifdef DUMMY_PRINT
	store_loader_node(tab_ent, ans_node,0);
#else /*!DUMMY_PRINT */
	store_loader_node(tab_ent, ans_node);
#endif /*DUMMY_PRINT */
      }
      PREG = (yamop *) CPREG;
      PREFETCH_OP(PREG);
      load_answer_trie(ans_node, YENV);
      YENV = ENV;
      GONext();
    } else {
      /* execute compiled code from the trie */
      if (SgFr_state(sg_fr) < compiled)
	update_answer_trie(sg_fr);
      UNLOCK(SgFr_lock(sg_fr));
      PREG = (yamop *) TrNode_child(SgFr_answer_trie(sg_fr));
      PREFETCH_OP(PREG);
      *--YENV = 0;  /* vars_arity */
      *--YENV = 0;  /* heap_arity */
      GONext();
    }
  }
}
