/**********************************************************************
                                                               
                       The OPTYap Prolog system                
  OPTYap extends the Yap Prolog system to support or-parallel tabling
                                                               
  Copyright:   R. Rocha and NCC - University of Porto, Portugal
  File:        tab.insts.i
  version:     $Id: tab.insts.i,v 1.26 2008-05-23 18:28:58 ricroc Exp $   
                                                                     
**********************************************************************/

/* ------------------------------------------------ **
**      Tabling instructions: auxiliary macros      **
** ------------------------------------------------ */

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
          HBREG = H;                                                  \
          store_yaam_reg_cpdepth(gcp);                                \
          gcp->cp_tr = TR;                                            \
          gcp->cp_ap = (yamop *)(AP);                                 \
          gcp->cp_h  = H;                                             \
          gcp->cp_b  = B;                                             \
          gcp->cp_env = ENV;                                          \
          gcp->cp_cp = CPREG;                                         \
	  if (IsMode_Local(TabEnt_mode(TAB_ENT))) {                   \
            /* go local */                                            \
            /*register dep_fr_ptr new_dep_fr;*/			      \
            /* adjust freeze registers */                             \
            H_FZ = H;                                                 \
            B_FZ = gcp;                                               \
            TR_FZ = TR;                                               \
            /* store dependency frame */                              \
            /* new_dependency_frame(new_dep_fr, TRUE, LOCAL_top_or_fr, */ \
               /*                  gcp, gcp, SG_FR, LOCAL_top_dep_fr); */ \
            /*LOCAL_top_dep_fr = new_dep_fr;	*/		      \
            GEN_CP(gcp)->cp_dep_fr = LOCAL_top_dep_fr;                \
          } else {                                                    \
            /* go batched */                                          \
            GEN_CP(gcp)->cp_dep_fr = NULL;                            \
          }                                                           \
          GEN_CP(gcp)->cp_sg_fr = SG_FR;                              \
          store_low_level_trace_info(GEN_CP(gcp), TAB_ENT);           \
          set_cut((CELL *)gcp, B);                                    \
          B = gcp;                                                    \
          YAPOR_SET_LOAD(B);                                          \
          SET_BB(B);                                                  \
          TABLING_ERRORS_check_stack;                                 \
        }


#ifdef DETERMINISTIC_TABLING
#define store_deterministic_generator_node(TAB_ENT, SG_FR)            \
        { register choiceptr gcp;                                     \
          /* initialize gcp and adjust subgoal frame field */         \
          YENV = (CELL *) (DET_GEN_CP(YENV) - 1);                     \
	  gcp = NORM_CP(YENV);                                        \
          SgFr_gen_cp(SG_FR) = gcp;                                   \
          /* store deterministic generator choice point */            \
          HBREG = H;                                                  \
          store_yaam_reg_cpdepth(gcp);                                \
          gcp->cp_ap = COMPLETION;                                    \
          gcp->cp_b  = B;                                             \
          gcp->cp_tr = TR;           	  	                      \
          gcp->cp_h = H;                                              \
	  DET_GEN_CP(gcp)->cp_sg_fr = SG_FR;                          \
          store_low_level_trace_info(DET_GEN_CP(gcp), TAB_ENT);       \
          set_cut((CELL *)gcp, B);                                    \
          B = gcp;                                                    \
          YAPOR_SET_LOAD(B);                                          \
          SET_BB(B);                                                  \
          TABLING_ERRORS_check_stack;                                 \
	}
#endif /* DETERMINISTIC_TABLING */


#define restore_generator_node(ARITY, AP)               \
        { register CELL *pt_args, *x_args;              \
          register choiceptr gcp = B;                   \
          /* restore generator choice point */          \
          H = HBREG = PROTECT_FROZEN_H(gcp);            \
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


#define store_consumer_node(TAB_ENT, SG_FR, LEADER_CP, DEP_ON_STACK)       \
        { register choiceptr ccp;                                          \
          register dep_fr_ptr new_dep_fr;                                  \
	  /* initialize ccp */                                             \
          YENV = (CELL *) (CONS_CP(YENV) - 1);                             \
          ccp = NORM_CP(YENV);                                             \
          /* adjust freeze registers */                                    \
          H_FZ = H;                                                        \
          B_FZ = ccp;                    	                           \
          TR_FZ = TR;                                                      \
          /* store dependency frame */                                     \
          new_dependency_frame(new_dep_fr, DEP_ON_STACK, LOCAL_top_or_fr,  \
                               LEADER_CP, ccp, SG_FR, LOCAL_top_dep_fr);   \
          LOCAL_top_dep_fr = new_dep_fr;                                   \
          /* store consumer choice point */                                \
          HBREG = H;                                                       \
          store_yaam_reg_cpdepth(ccp);                                     \
          ccp->cp_tr = TR;         	                                   \
          ccp->cp_ap = ANSWER_RESOLUTION;                                  \
          ccp->cp_h  = H;                                                  \
          ccp->cp_b  = B;                                                  \
          ccp->cp_env= ENV;                                                \
          ccp->cp_cp = CPREG;                                              \
          CONS_CP(ccp)->cp_dep_fr = LOCAL_top_dep_fr;                      \
          store_low_level_trace_info(CONS_CP(ccp), TAB_ENT);               \
          /* set_cut((CELL *)ccp, B); --> no effect */                     \
          B = ccp;                                                         \
          YAPOR_SET_LOAD(B);                                               \
          SET_BB(B);                                                       \
          TABLING_ERRORS_check_stack;                                      \
        }


#define consume_answer_and_procceed(DEP_FR, ANSWER)       \
        { CELL *subs_ptr;                                 \
          /* restore consumer choice point */             \
          H = HBREG = PROTECT_FROZEN_H(B);                \
          restore_yaam_reg_cpdepth(B);                    \
          CPREG = B->cp_cp;                               \
          ENV = B->cp_env;                                \
          /* set_cut(YENV, B->cp_b); --> no effect */     \
          PREG = (yamop *) CPREG;                         \
          PREFETCH_OP(PREG);                              \
          /* load answer from table to global stack */    \
          if (B == DepFr_leader_cp(DEP_FR)) {             \
            /*  B is a generator-consumer node  */        \
            /* never here if batched scheduling */        \
            TABLING_ERRORS_consume_answer_and_procceed;   \
            subs_ptr = (CELL *) (GEN_CP(B) + 1);          \
            subs_ptr += SgFr_arity(GEN_CP(B)->cp_sg_fr);  \
	  } else {                                        \
            subs_ptr = (CELL *) (CONS_CP(B) + 1);         \
	  }                                               \
          load_answer_trie(ANSWER, subs_ptr);             \
          /* procceed */                                  \
          YENV = ENV;                                     \
          GONext();                                       \
        }


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

#else /* !DUMMY_PRINT */

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

#endif /*DUMMY_PRINT */



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


#ifdef LINEAR_TABLING

#ifdef LINEAR_TABLING_BATCHED
#define batched_consume_first_answer(sg_fr)                           \
  {   SgFr_batched_ans(sg_fr)=SgFr_first_answer(sg_fr);               \
      INFO_LINEAR_TABLING("batched consume first_answer");	      \
      if (SgFr_batched_ans(sg_fr)!=NULL){                             \
	if (SgFr_batched_ans(sg_fr) == SgFr_answer_trie(sg_fr)) {     \
         /* yes answer --> procceed*/	                              \
          INFO_LINEAR_TABLING("yes answer -->proceed");               \
	  PREG = (yamop *) CPREG;                                     \
	  PREFETCH_OP(PREG);                                          \
	  YENV = ENV;                                                 \
	  GONext() ;                                                  \
	}else{	                                                      \
          INFO_LINEAR_TABLING("consume answer");                      \
	  PREG = (yamop *) CPREG;                                     \
	  PREFETCH_OP(PREG);                                          \
	  CELL *subs_ptr;                                             \
	  subs_ptr = (CELL *) (GEN_CP(B) + 1);                        \
	  subs_ptr += SgFr_arity(GEN_CP(B)->cp_sg_fr);                \
	  load_answer_trie(SgFr_batched_ans(sg_fr), subs_ptr);        \
	  YENV = ENV;                                                 \
	  GONext();                                                   \
	}                                                             \
      }                                                               \
    }
   
#else  /*! LINEAR_TABLING_BATCHED */
#define batched_consume_first_answer(sg_fr)

#endif /*LINEAR_TABLING_BATCHED */


#ifdef DUMMY_PRINT

#define DUMMY_LOCAL_nr_followers_inc()                  (LOCAL_nr_followers++)
#define DUMMY_LOCAL_nr_generators_inc()                 (LOCAL_nr_generators++)
#define DUMMY_LOCAL_nr_consumers_inc()                  (LOCAL_nr_consumers++)

#define consume_answers(tab_ent,sg_fr)                        \
      ans_node_ptr ans_node;                                  \
      DUMMY_LOCAL_nr_consumers_inc();                         \
      ans_node = SgFr_first_answer(sg_fr);                    \
      if (ans_node == NULL) {                                 \
	/* no answers --> fail */                             \
	UNLOCK(SgFr_lock(sg_fr));                             \
	goto fail;                                            \
      } else if (ans_node == SgFr_answer_trie(sg_fr)) {       \
	/* yes answer --> procceed */                         \
	UNLOCK(SgFr_lock(sg_fr));                             \
	PREG = (yamop *) CPREG;                               \
	PREFETCH_OP(PREG);                                    \
	YENV = ENV;                                           \
	GONext();                                             \
      } else {                                                \
	/* answers -> get first answer */                     \
	UNLOCK(SgFr_lock(sg_fr));                             \
	store_loader_node(tab_ent, ans_node,0);		      \
	PREG = (yamop *) CPREG;                               \
	PREFETCH_OP(PREG);                                    \
	load_answer_trie(ans_node, YENV);                     \
	YENV = ENV;                                           \
	GONext();                                             \
      }

#define DUMMY_LOCAL_nr_propagate_depen_cicles_inc()        (LOCAL_nr_propagate_depen_cicles++)
#define	DUMMY_LOCAL_nr_is_leader_and_has_new_answers_inc() (LOCAL_nr_is_leader_and_has_new_answers++)


#else /*! DUMMY_PRINT */
#define DUMMY_LOCAL_nr_followers_inc()
#define DUMMY_LOCAL_nr_generators_inc()
#define DUMMY_LOCAL_nr_consumers_inc()


#define consume_answers(tab_ent,sg_fr)                        \
      ans_node_ptr ans_node;                                  \
      DUMMY_LOCAL_nr_consumers_inc();                         \
      ans_node = SgFr_first_answer(sg_fr);                    \
      if (ans_node == NULL) {                                 \
	/* no answers --> fail */                             \
	UNLOCK(SgFr_lock(sg_fr));                             \
	goto fail;                                            \
      } else if (ans_node == SgFr_answer_trie(sg_fr)) {       \
	/* yes answer --> procceed */                         \
	UNLOCK(SgFr_lock(sg_fr));                             \
	PREG = (yamop *) CPREG;                               \
	PREFETCH_OP(PREG);                                    \
	YENV = ENV;                                           \
	GONext();                                             \
      } else {                                                \
	/* answers -> get first answer */                     \
	UNLOCK(SgFr_lock(sg_fr));                             \
	store_loader_node(tab_ent, ans_node);                 \
	PREG = (yamop *) CPREG;                               \
	PREFETCH_OP(PREG);                                    \
	load_answer_trie(ans_node, YENV);                     \
	YENV = ENV;                                           \
	GONext();                                             \
      }


#define	DUMMY_LOCAL_nr_is_leader_and_has_new_answers_inc()
#define DUMMY_LOCAL_nr_propagate_depen_cicles_inc()

#endif /*DUMMY_PRINT*/


#define add_max_scc(SG_FR){				      \
        SgFr_next_on_scc(SG_FR)=LOCAL_max_scc;                \
        LOCAL_max_scc = SG_FR;                                \
}


#ifdef LINEAR_TABLING_BATCHED
#define add_next(SG_FR)
#define add_next_follower(SG_FR)
#define remove_next(SG_FR)
#else

#define add_next(SG_FR){                                           \
       if(SG_FR!=LOCAL_top_sg_fr){                                 \
	 SgFr_next(SG_FR) = LOCAL_top_sg_fr;   		           \
         LOCAL_top_sg_fr = SG_FR;				   \
       }                                                           \
   }


#define add_next_follower(SG_FR){                                  \
        sg_fr_ptr sgfr_aux=NULL;                                   \
        new_subgoal_frame(sgfr_aux, PREG);                         \
	SgFr_stop_loop_ans(sgfr_aux) = NULL;                       \
        SgFr_current_loop_ans(sgfr_aux) = NULL;			   \
        SgFr_stop_loop_alt(sgfr_aux) = NULL;                       \
	SgFr_current_loop_alt(sgfr_aux) = NULL;                    \
        SgFr_consuming_answers(sgfr_aux)=0;	                   \
        SgFr_new_answer_trie(sgfr_aux) = NULL;                     \
        SgFr_next_alt(sgfr_aux) = NULL; 			   \
	SgFr_pioneer(sgfr_aux)=NULL;                               \
        SgFr_gen_cp(sgfr_aux)=SgFr_gen_cp(SG_FR);                  \
        SgFr_next(sgfr_aux) = LOCAL_top_sg_fr;   		   \
        LOCAL_top_sg_fr = sgfr_aux;				   \
   }





#define remove_next(SG_FR){                                        \
     if(B !=SgFr_gen_cp(LOCAL_top_sg_fr)){	                   \
        printf("nao devia acontecer\n"); 			   \
     }else{							   \
       LOCAL_top_sg_fr= SgFr_next(LOCAL_top_sg_fr);		   \
     }								   \
   }

#endif /*LINEAR_TABLING_BATCHED */




#define add_branch(SG_FR){			                 			\
    SgFr_next_on_branch(SG_FR) = LOCAL_top_sg_fr_on_branch;                             \
    LOCAL_top_sg_fr_on_branch =SG_FR;                                                   \
    }

#define remove_branch(SG_FR){					                            \
        LOCAL_top_sg_fr_on_branch = SgFr_next_on_branch(SG_FR);		                    \
  }



#define add_alternative(SG_FR,pc)						              \
        if (SgFr_state(SG_FR) == evaluating) {                                                \
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
	}



#define add_answer(SG_FR,ans)              					                        \
          if (SgFr_stop_loop_ans(SG_FR)==NULL) {	  		       	                        \
  	     SgFr_stop_loop_ans(SG_FR)= SgFr_loop_ans(SG_FR);                                           \
             SET_CELL_VALUE(SgFr_stop_loop_ans(SG_FR),ans);                                             \
          } else if (GET_CELL_VALUE(SgFr_stop_loop_ans(SG_FR))!= ans) {                                 \
             SgFr_stop_loop_ans(SG_FR)++;                                                               \
	     if (IS_JUMP_CELL(SgFr_stop_loop_ans(SG_FR))){		                                \
	       struct answer_trie_node * nb;                                                            \
	       ALLOC_ANSWERS_BUCKET(nb);	                                                        \
	       ANS_TAG_AS_JUMP_CELL(SgFr_stop_loop_ans(SG_FR),nb);                                      \
	       SgFr_stop_loop_ans(SG_FR)=nb;                                                            \
	    }                                                                                           \
            SET_CELL_VALUE(SgFr_stop_loop_ans(SG_FR),ans);                                              \
         }


#ifdef LINEAR_TABLING_DRA

#ifdef LINEAR_TABLING_DRS

#define propagate_dependencies(SG_FR)					                     \
	{ sg_fr_ptr sf_aux=LOCAL_top_sg_fr_on_branch;                                        \
    	  int dfn=GET_SGFR_DFN(SG_FR);                                                       \
	  INFO_LINEAR_TABLING("propagate dependencies upto to sg_fr=%p",SG_FR);              \
          while(sf_aux && (GET_SGFR_DFN(sf_aux) >dfn ||SgFr_consuming_answers(sf_aux)==2)) { \
   	    DUMMY_LOCAL_nr_propagate_depen_cicles_inc();                                     \
   	    INFO_LINEAR_TABLING("sgfr_aux=%p",sf_aux);                                       \
            TAG_AS_NO_LEADER(sf_aux);					                     \
	    if(SgFr_consuming_answers(sf_aux)==2){                                           \
                add_answer(sf_aux,SgFr_new_answer_trie(sf_aux));                             \
             }else{                                                                          \
		add_alternative(sf_aux, SgFr_current_alt(sf_aux));			     \
	     }                                                                               \
            sf_aux = SgFr_next_on_branch(sf_aux);		        	             \
          }	                                                                             \
	  if (sf_aux) {				                                             \
	    if(SgFr_consuming_answers(sf_aux)==2){                                           \
                add_answer(sf_aux,SgFr_new_answer_trie(sf_aux));                             \
             }else{                                                                          \
		add_alternative(sf_aux, SgFr_current_alt(sf_aux));			     \
	     }                                                                               \
          }							                             \
      }



#else /*! LINEAR_TABLING_DRS */



#define propagate_dependencies(SG_FR)					                     \
	{ sg_fr_ptr sf_aux=LOCAL_top_sg_fr_on_branch;                                        \
    	  int dfn=GET_SGFR_DFN(SG_FR);                                                       \
          while(sf_aux && (GET_SGFR_DFN(sf_aux) >dfn)) {                                     \
   	    DUMMY_LOCAL_nr_propagate_depen_cicles_inc();                                     \
	    TAG_AS_NO_LEADER(sf_aux);                                                        \
    	    add_alternative(sf_aux, SgFr_current_alt(sf_aux));			             \
            sf_aux = SgFr_next_on_branch(sf_aux);		        	             \
          }	                                                                             \
	  if (sf_aux) {				                                             \
		add_alternative(sf_aux, SgFr_current_alt(sf_aux));			     \
	     }                                                                               \
	}


#endif /*LINEAR_TABLING_DRS */


#else /*LINEAR_TABLING_BASIC */

#ifdef LINEAR_TABLING_DRS

#define propagate_dependencies(SG_FR)                                                          \
	{ sg_fr_ptr sf_aux=LOCAL_top_sg_fr_on_branch;                                          \
    	  int dfn=GET_SGFR_DFN(SG_FR);                                                         \
          while(sf_aux && (GET_SGFR_DFN(sf_aux) > dfn ||SgFr_consuming_answers(sf_aux)==2)) {  \
   	    DUMMY_LOCAL_nr_propagate_depen_cicles_inc();                                       \
	    TAG_AS_NO_LEADER(sf_aux);                                                          \
            if(SgFr_consuming_answers(sf_aux)==2){					       \
                add_answer(sf_aux,SgFr_new_answer_trie(sf_aux));                               \
            }                                                                                  \
            sf_aux = SgFr_next_on_branch(sf_aux);                                              \
          }	                                                                               \
	  if (sf_aux && SgFr_consuming_answers(sf_aux)==2){                                    \
                add_answer(sf_aux,SgFr_new_answer_trie(sf_aux));                               \
	  }                                                                                    \
      }


#else /*! LINEAR_TABLING_DRS */

#define propagate_dependencies(SG_FR)                                                       \
	{ sg_fr_ptr sf_aux=LOCAL_top_sg_fr_on_branch;                                       \
    	  int dfn=GET_SGFR_DFN(SG_FR);                                                      \
          while(sf_aux && GET_SGFR_DFN(sf_aux) > dfn) {	 		                    \
   	    DUMMY_LOCAL_nr_propagate_depen_cicles_inc();                                    \
	    TAG_AS_NO_LEADER(sf_aux);                                                       \
            sf_aux = SgFr_next_on_branch(sf_aux);                                           \
          }	                                                                            \
      }

#endif /* LINEAR_TABLING_DRS */

#endif  /*LINEAR_TABLING_DRA*/


#endif  /* LINEAR_TABLING */



/* ------------------------------ **
**      Tabling instructions      **
** ------------------------------ */  

#ifdef TABLING_INNER_CUTS
  Op(clause_with_cut, e)
    if (LOCAL_pruning_scope) {
      if (YOUNGER_CP(LOCAL_pruning_scope, B))
        LOCAL_pruning_scope = B;
    } else {
      LOCAL_pruning_scope = B;
      PUT_IN_PRUNING(worker_id);
    }
    PREG = NEXTOP(PREG, e);
    GONext();
  ENDOp();
#endif /* TABLING_INNER_CUTS */



  PBOp(table_load_answer, Otapl)
  // INFO_LINEAR_TABLING("-------------------------table_load_answer ---------------");
    CELL *subs_ptr;
    ans_node_ptr ans_node;
#ifdef YAPOR
    if (SCH_top_shared_cp(B)) {
      PROBLEM: cp_last_answer field is local to the cp!
               -> we need a shared data structure to avoid redundant computations!
      UNLOCK_OR_FRAME(LOCAL_top_or_fr);
    }
#endif /* YAPOR */
    subs_ptr = (CELL *) (LOAD_CP(B) + 1);
    ans_node = TrNode_child(LOAD_CP(B)->cp_last_answer);
#ifdef LINEAR_TABLING
    if (ans_node != NULL) {
      restore_loader_node(ans_node);
    } else {
      B = B->cp_b;
      //  INFO_LINEAR_TABLING("-------------------------no answers ----fail");
      goto fail; 
    } 
#else  
    if(TrNode_child(ans_node) != NULL) {
      restore_loader_node(ans_node);
    } else {
      pop_loader_node();
    }
#endif /* LINEAR_TABLING */
    PREG = (yamop *) CPREG;
    PREFETCH_OP(PREG);
    load_answer_trie(ans_node, subs_ptr);
    YENV = ENV;
    GONext();
  ENDPBOp();



  PBOp(table_try_answer, Otapl)
  // INFO_LINEAR_TABLING("-------------------------table_try_answer ---------------");
#ifdef INCOMPLETE_TABLING
    sg_fr_ptr sg_fr;
    ans_node_ptr ans_node;

    sg_fr = GEN_CP(B)->cp_sg_fr;
    ans_node = TrNode_child(SgFr_try_answer(sg_fr));
    if(ans_node) {
      CELL *subs_ptr = (CELL *) (GEN_CP(B) + 1) + SgFr_arity(sg_fr);

      H = HBREG = PROTECT_FROZEN_H(B);
      restore_yaam_reg_cpdepth(B);
      CPREG = B->cp_cp;
      ENV = B->cp_env;
      SgFr_try_answer(sg_fr) = ans_node;
#ifdef YAPOR
      if (SCH_top_shared_cp(B))
	UNLOCK_OR_FRAME(LOCAL_top_or_fr);
#endif /* YAPOR */
      SET_BB(PROTECT_FROZEN_B(B));

      PREG = (yamop *) CPREG;
      PREFETCH_OP(PREG);
      load_answer_trie(ans_node, subs_ptr);
      YENV = ENV;
      GONext();
    } else {
      yamop *code_ap;
      PREG = SgFr_code(sg_fr);
      if (PREG->opc == Yap_opcode(_table_try)) {
	/* table_try */
	code_ap = NEXTOP(PREG,Otapl);
	PREG = PREG->u.Otapl.d;
      } else if (PREG->opc == Yap_opcode(_table_try_single)) {
	/* table_try_single */
	code_ap = COMPLETION;
	PREG = PREG->u.Otapl.d;
      } else {
	/* table_try_me */
	code_ap = PREG->u.Otapl.d;
	PREG = NEXTOP(PREG,Otapl);
      }
      PREFETCH_OP(PREG);
      restore_generator_node(SgFr_arity(sg_fr), code_ap);
      YENV = (CELL *) PROTECT_FROZEN_B(B);
      set_cut(YENV, B->cp_b);
      SET_BB(NORM_CP(YENV));
      allocate_environment();
      GONext();
    }
#else
    PREG = PREG->u.Otapl.d;
    PREFETCH_OP(PREG);
    GONext();    
#endif /* INCOMPLETE_TABLING */
  ENDPBOp();



  PBOp(table_try_single, Otapl)

#ifdef DUMMY_PRINT
  LOCAL_nr_consumed_alternatives++;
#endif /* DUMMY_PRINT */

    INFO_LINEAR_TABLING("-------------------------table_try_single ---------------");
    tab_ent_ptr tab_ent;
    sg_fr_ptr sg_fr;
  
    check_trail(TR);
    tab_ent = PREG->u.Otapl.te;
    YENV2MEM;
    sg_fr = subgoal_search(PREG, YENV_ADDRESS);
    INFO_LINEAR_TABLING("sg_fr= %p   state=%d",sg_fr,SgFr_state(sg_fr));
  
    MEM2YENV;
    LOCK(SgFr_lock(sg_fr));
    if (SgFr_state(sg_fr) == ready) {
      /* subgoal new */
      init_subgoal_frame(sg_fr);
      UNLOCK(SgFr_lock(sg_fr));
#ifdef LINEAR_TABLING
      add_branch(sg_fr);
      add_max_scc(sg_fr);
      add_next(sg_fr);
      store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, COMPLETION);
#ifdef LINEAR_TABLING_FOLLOWER
      SgFr_pioneer(sg_fr)=B;
      SgFr_next_alt(sg_fr)= NULL;
#endif /*LINEAR_TABLING_FOLLOWER */
#ifdef LINEAR_TABLING_DRA
      SgFr_current_alt(sg_fr) = PREG->u.Otapl.d;
#else 
      add_alternative(sg_fr,PREG->u.Otapl.d);
#endif  /*LINEAR_TABLING_DRA */
#else  /*!LINEAR_TABLING */

#ifdef DETERMINISTIC_TABLING
      if (IsMode_Batched(TabEnt_mode(tab_ent))) {
	store_deterministic_generator_node(tab_ent, sg_fr);
      } else
#endif /* DETERMINISTIC_TABLING */
      {
	store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, COMPLETION);
      }
#endif /* LINEAR_TABLING */
      PREG = PREG->u.Otapl.d;  /* should work also with PREG = NEXTOP(PREG,Otapl); */
      PREFETCH_OP(PREG);
      allocate_environment();
      GONext();
#ifdef INCOMPLETE_TABLING
    } else if (SgFr_state(sg_fr) == incomplete) {
      /* subgoal incomplete --> start by loading the answers already found */
      ans_node_ptr ans_node = SgFr_first_answer(sg_fr);
      CELL *subs_ptr = YENV;
      init_subgoal_frame(sg_fr);
      UNLOCK(SgFr_lock(sg_fr));
      SgFr_try_answer(sg_fr) = ans_node;
      store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, TRY_ANSWER);
      PREG = (yamop *) CPREG;
      PREFETCH_OP(PREG);
      load_answer_trie(ans_node, subs_ptr);
      YENV = ENV;
      GONext();
#endif /* INCOMPLETE_TABLING */
#ifdef LINEAR_TABLING
    } else if (SgFr_state(sg_fr) == looping_ready) {
      add_max_scc(sg_fr)
      add_next(sg_fr);
      store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, COMPLETION);
#ifdef LINEAR_TABLING_FOLLOWER
      SgFr_pioneer(sg_fr)=B;
#endif  /*LINEAR_TABLING_FOLLOWER*/
      SgFr_state(sg_fr) = looping_evaluating; 
      batched_consume_first_answer(sg_fr);
      /*else */
      SgFr_stop_loop_alt(LOCAL_max_scc)=SgFr_current_loop_alt(LOCAL_max_scc);
      PREG = GET_CELL_VALUE(SgFr_current_loop_alt(sg_fr));
      PREFETCH_OP(PREG);
      allocate_environment();
      GONext();
    } else if (SgFr_state(sg_fr) == evaluating || 
               SgFr_state(sg_fr) == looping_evaluating
#ifdef LINEAR_TABLING_FOLLOWER	       
	       || SgFr_state(sg_fr) == looping_follower_cons
#endif  /*LINEAR_TABLING_FOLLOWER*/
               ){ 

      propagate_dependencies(sg_fr);
      consume_answers(tab_ent,sg_fr);
#else /*!LINEAR_TABLING */
    } else if (SgFr_state(sg_fr) == evaluating) {
      /* subgoal in evaluation */
      choiceptr leader_cp;
      int leader_dep_on_stack;
      find_dependency_node(sg_fr, leader_cp, leader_dep_on_stack);
      UNLOCK(SgFr_lock(sg_fr));
      find_leader_node(leader_cp, leader_dep_on_stack);
      store_consumer_node(tab_ent, sg_fr, leader_cp, leader_dep_on_stack);
#ifdef OPTYAP_ERRORS
      if (PARALLEL_EXECUTION_MODE) {
	choiceptr aux_cp;
	aux_cp = B;
	while (YOUNGER_CP(aux_cp, LOCAL_top_cp_on_stack))
	  aux_cp = aux_cp->cp_b;
	if (aux_cp->cp_or_fr != DepFr_top_or_fr(LOCAL_top_dep_fr))
	  OPTYAP_ERROR_MESSAGE("Error on DepFr_top_or_fr (table_try_single)");
	aux_cp = B;
	while (YOUNGER_CP(aux_cp, DepFr_leader_cp(LOCAL_top_dep_fr)))
	  aux_cp = aux_cp->cp_b;
	if (aux_cp != DepFr_leader_cp(LOCAL_top_dep_fr))
	  OPTYAP_ERROR_MESSAGE("Error on DepFr_leader_cp (table_try_single)");
      }
#endif /* OPTYAP_ERRORS */
      goto answer_resolution;
#endif /* LINEAR_TABLING */
    } else {
      /* subgoal completed */
      ans_node_ptr ans_node = SgFr_first_answer(sg_fr);
      if (ans_node == NULL) {
	/* no answers --> fail */
	UNLOCK(SgFr_lock(sg_fr));
	goto fail;
      } else if (ans_node == SgFr_answer_trie(sg_fr)) {
	/* yes answer --> procceed */
	UNLOCK(SgFr_lock(sg_fr));
	PREG = (yamop *) CPREG;
	PREFETCH_OP(PREG);
	YENV = ENV;
	GONext();
      } else {
	/* answers -> get first answer */
#ifdef LIMIT_TABLING
	if (SgFr_state(sg_fr) == complete || SgFr_state(sg_fr) == compiled) {
	  SgFr_state(sg_fr)++;  /* complete --> complete_in_use : compiled --> compiled_in_use */
	  remove_from_global_sg_fr_list(sg_fr);
	  TRAIL_FRAME(sg_fr);
	}
#endif /* LIMIT_TABLING */
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
  ENDPBOp();



  PBOp(table_try_me, Otapl)
  //    INFO_LINEAR_TABLING("-------------------------table_try_me ---------------");
#ifdef DUMMY_PRINT
  LOCAL_nr_consumed_alternatives++;
#endif /* DUMMY_PRINT */

    tab_ent_ptr tab_ent;
    sg_fr_ptr sg_fr;

    check_trail(TR);
    tab_ent = PREG->u.Otapl.te;
    YENV2MEM;
    sg_fr = subgoal_search(PREG, YENV_ADDRESS);
    MEM2YENV;
    LOCK(SgFr_lock(sg_fr));
    if (SgFr_state(sg_fr) == ready) {
      /* subgoal new */
      init_subgoal_frame(sg_fr);
      UNLOCK(SgFr_lock(sg_fr));
#ifdef LINEAR_TABLING
      add_branch(sg_fr);
      add_max_scc(sg_fr);
      add_next(sg_fr);
#ifdef LINEAR_TABLING_FOLLOWER
      store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, COMPLETION);
      SgFr_pioneer(sg_fr)=B;
      SgFr_next_alt(sg_fr)= PREG->u.Otapl.d;
#else
      store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, PREG->u.Otapl.d);
#endif /* LINEAR_TABLING_FOLLOWER */

#ifdef LINEAR_TABLING_DRA
      SgFr_current_alt(sg_fr) = NEXTOP(PREG,Otapl);
#else
      add_alternative(sg_fr,NEXTOP(PREG, Otapl));
#endif /*LINEAR_TABLING_DRA*/

#else  /*!LINEAR_TABLING */
      store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, PREG->u.Otapl.d);
#endif /* LINEAR_TABLING */
      PREG = NEXTOP(PREG, Otapl);
      PREFETCH_OP(PREG);
      allocate_environment();
      GONext();
#ifdef INCOMPLETE_TABLING
    } else if (SgFr_state(sg_fr) == incomplete) {
      /* subgoal incomplete --> start by loading the answers already found */
      ans_node_ptr ans_node = SgFr_first_answer(sg_fr);
      CELL *subs_ptr = YENV;
      init_subgoal_frame(sg_fr);
      UNLOCK(SgFr_lock(sg_fr));
      SgFr_try_answer(sg_fr) = ans_node;
      store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, TRY_ANSWER);
      PREG = (yamop *) CPREG;
      PREFETCH_OP(PREG);
      load_answer_trie(ans_node, subs_ptr);
      YENV = ENV;
      GONext();
#endif /* INCOMPLETE_TABLING */

#ifdef LINEAR_TABLING
    } else if (SgFr_state(sg_fr) == looping_ready) {
      add_max_scc(sg_fr)
      add_next(sg_fr);
      store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, COMPLETION);
#ifdef LINEAR_TABLING_FOLLOWER
      SgFr_pioneer(sg_fr)=B;
#endif /*LINEAR_TABLING_FOLLOWER */
      SgFr_state(sg_fr) = looping_evaluating; 
      batched_consume_first_answer(sg_fr);
      /*else */
      SgFr_stop_loop_alt(LOCAL_max_scc)=SgFr_current_loop_alt(LOCAL_max_scc);
      PREG = GET_CELL_VALUE(SgFr_current_loop_alt(sg_fr));
      PREFETCH_OP(PREG);
      allocate_environment();
      GONext();
    } else if (SgFr_state(sg_fr) == looping_evaluating) {
      propagate_dependencies(sg_fr);
#ifdef LINEAR_TABLING_FOLLOWER
      yamop **follower_alt=SgFr_current_loop_alt(sg_fr)+1;
      if (IS_JUMP_CELL(follower_alt))
	ALT_JUMP_NEXT_CELL(follower_alt);
      if (follower_alt != SgFr_stop_loop_alt(sg_fr)){
	INFO_LINEAR_TABLING("follower");
#ifdef DUMMY_PRINT
	DUMMY_LOCAL_nr_followers_inc();
	LOCAL_nr_consumed_alternatives++;
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
#endif  /*LINEAR_TABLING_FOLLOWER*/
     consume_answers(tab_ent,sg_fr);  

#endif /* LINEAR TABLING */

#ifdef LINEAR_TABLING_FOLLOWER	       
    }else if (SgFr_state(sg_fr) == looping_follower_cons){ 
      propagate_dependencies(sg_fr);
      consume_answers(tab_ent,sg_fr);
#endif  /*LINEAR_TABLING_FOLLOWER*/

    } else if (SgFr_state(sg_fr) == evaluating) {
#ifdef LINEAR_TABLING
      propagate_dependencies(sg_fr);
#ifdef LINEAR_TABLING_FOLLOWER
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
#endif /*LINEAR_TABLING_FOLLOWER */
     consume_answers(tab_ent,sg_fr);  
#else  /* !LINEAR_TABLING */
      /* subgoal in evaluation */
      choiceptr leader_cp;
      int leader_dep_on_stack;
      find_dependency_node(sg_fr, leader_cp, leader_dep_on_stack);
      UNLOCK(SgFr_lock(sg_fr));
      find_leader_node(leader_cp, leader_dep_on_stack);
      store_consumer_node(tab_ent, sg_fr, leader_cp, leader_dep_on_stack);
#ifdef OPTYAP_ERRORS
      if (PARALLEL_EXECUTION_MODE) {
	choiceptr aux_cp;
	aux_cp = B;
	while (YOUNGER_CP(aux_cp, LOCAL_top_cp_on_stack))
	  aux_cp = aux_cp->cp_b;
	if (aux_cp->cp_or_fr != DepFr_top_or_fr(LOCAL_top_dep_fr))
	  OPTYAP_ERROR_MESSAGE("Error on DepFr_top_or_fr (table_try_me)");
	aux_cp = B;
	while (YOUNGER_CP(aux_cp, DepFr_leader_cp(LOCAL_top_dep_fr)))
	  aux_cp = aux_cp->cp_b;
	if (aux_cp != DepFr_leader_cp(LOCAL_top_dep_fr))
	  OPTYAP_ERROR_MESSAGE("Error on DepFr_leader_cp (table_try_me)");
      }
#endif /* OPTYAP_ERRORS */
      goto answer_resolution;
#endif /* LINEAR_TABLING */
    } else {
      /* subgoal's state = completed- all answers will be consumed */
      ans_node_ptr ans_node = SgFr_first_answer(sg_fr);
      if (ans_node == NULL) {
	/* no answers --> fail */
	UNLOCK(SgFr_lock(sg_fr));
	goto fail;
      } else if (ans_node == SgFr_answer_trie(sg_fr)) {
	/* yes answer --> procceed */
	UNLOCK(SgFr_lock(sg_fr));
	PREG = (yamop *) CPREG;
	PREFETCH_OP(PREG);
	YENV = ENV;
	GONext();
      } else {
	/* answers -> get first answer */
#ifdef LIMIT_TABLING
	if (SgFr_state(sg_fr) == complete || SgFr_state(sg_fr) == compiled) {
	  SgFr_state(sg_fr)++;  /* complete --> complete_in_use : compiled --> compiled_in_use */
	  remove_from_global_sg_fr_list(sg_fr);
	  TRAIL_FRAME(sg_fr);
	}
#endif /* LIMIT_TABLING */
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
  ENDPBOp();



  PBOp(table_try, Otapl)

#ifdef DUMMY_PRINT
  LOCAL_nr_consumed_alternatives++;
#endif /* DUMMY_PRINT */

    tab_ent_ptr tab_ent;
    sg_fr_ptr sg_fr;
    check_trail(TR);
    tab_ent = PREG->u.Otapl.te;
    YENV2MEM;
    sg_fr = subgoal_search(PREG, YENV_ADDRESS);
    INFO_LINEAR_TABLING("-------------------------table_try ---------------\n");
    INFO_LINEAR_TABLING("sg_fr= %p  state=%d \n",sg_fr,SgFr_state(sg_fr));
    MEM2YENV;
    LOCK(SgFr_lock(sg_fr));
    if (SgFr_state(sg_fr) == ready) {
      /* subgoal new */
      init_subgoal_frame(sg_fr);
      UNLOCK(SgFr_lock(sg_fr));
#ifdef LINEAR_TABLING
      add_branch(sg_fr);
      add_max_scc(sg_fr);
      add_next(sg_fr);
#ifdef LINEAR_TABLING_FOLLOWER
      store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, COMPLETION);
      SgFr_pioneer(sg_fr)=B;
      SgFr_next_alt(sg_fr)= NEXTOP(PREG,Otapl);
#else
      store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, NEXTOP(PREG,Otapl));
#endif /* LINEAR_TABLING_FOLLOWER */

#ifdef LINEAR_TABLING_DRA
      SgFr_current_alt(sg_fr) = PREG->u.Otapl.d;
#else
      add_alternative(sg_fr,PREG->u.Otapl.d);
#endif /* LINEAR_TABLING_DRA */

#else  /*!LINEAR_TABLING */
      store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, NEXTOP(PREG,Otapl));
#endif /* LINEAR_TABLING */
      PREG = PREG->u.Otapl.d;
      PREFETCH_OP(PREG);
      allocate_environment();
      GONext();
#ifdef INCOMPLETE_TABLING
    } else if (SgFr_state(sg_fr) == incomplete) {
      /* subgoal incomplete --> start by loading the answers already found */
      ans_node_ptr ans_node = SgFr_first_answer(sg_fr);
      CELL *subs_ptr = YENV;
      init_subgoal_frame(sg_fr);
      UNLOCK(SgFr_lock(sg_fr));
      SgFr_try_answer(sg_fr) = ans_node;
      store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, TRY_ANSWER);
      PREG = (yamop *) CPREG;
      PREFETCH_OP(PREG);
      load_answer_trie(ans_node, subs_ptr);
      YENV = ENV;
      GONext();
#endif /* INCOMPLETE_TABLING */
#ifdef LINEAR_TABLING
    } else if (SgFr_state(sg_fr) == looping_ready) {
      add_max_scc(sg_fr)
      add_next(sg_fr);
      store_generator_node(tab_ent, sg_fr, PREG->u.Otapl.s, COMPLETION);
#ifdef LINEAR_TABLING_FOLLOWER
      SgFr_pioneer(sg_fr)=B;
#endif /*LINEAR_TABLING_FOLLOWER */
      SgFr_state(sg_fr) = looping_evaluating; 
      batched_consume_first_answer(sg_fr);
      /*else */
      SgFr_stop_loop_alt(LOCAL_max_scc)=SgFr_current_loop_alt(LOCAL_max_scc);
      PREG = GET_CELL_VALUE(SgFr_current_loop_alt(sg_fr));
      PREFETCH_OP(PREG);
      allocate_environment();
      GONext();
    } else if (SgFr_state(sg_fr) == looping_evaluating) {
      propagate_dependencies(sg_fr);
#ifdef LINEAR_TABLING_FOLLOWER
      yamop **follower_alt=SgFr_current_loop_alt(sg_fr)+1;
      if (IS_JUMP_CELL(follower_alt))
	ALT_JUMP_NEXT_CELL(follower_alt);	  
      if (follower_alt != SgFr_stop_loop_alt(sg_fr)){
	INFO_LINEAR_TABLING("follower");
#ifdef DUMMY_PRINT
	DUMMY_LOCAL_nr_followers_inc();
	LOCAL_nr_consumed_alternatives++;
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
#endif  /*LINEAR_TABLING_FOLLOWER*/
      consume_answers(tab_ent,sg_fr);
#endif /* LINEAR TABLING */

#ifdef LINEAR_TABLING_FOLLOWER	       
    }else if (SgFr_state(sg_fr) == looping_follower_cons){ 
      propagate_dependencies(sg_fr);
      consume_answers(tab_ent,sg_fr);
#endif  /*LINEAR_TABLING_FOLLOWER*/

    } else if (SgFr_state(sg_fr) == evaluating) {
#ifdef LINEAR_TABLING
      propagate_dependencies(sg_fr);
#ifdef LINEAR_TABLING_FOLLOWER
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
#endif /*LINEAR_TABLING_FOLLOWER */
      consume_answers(tab_ent,sg_fr);
#else  /* !LINEAR_TABLING */
      /* subgoal in evaluation */
      choiceptr leader_cp;
      int leader_dep_on_stack;
      find_dependency_node(sg_fr, leader_cp, leader_dep_on_stack);
      UNLOCK(SgFr_lock(sg_fr));
      find_leader_node(leader_cp, leader_dep_on_stack);
      store_consumer_node(tab_ent, sg_fr, leader_cp, leader_dep_on_stack);
#ifdef OPTYAP_ERRORS
      if (PARALLEL_EXECUTION_MODE) {
	choiceptr aux_cp;
	aux_cp = B;
	while (YOUNGER_CP(aux_cp, LOCAL_top_cp_on_stack))
	  aux_cp = aux_cp->cp_b;
	if (aux_cp->cp_or_fr != DepFr_top_or_fr(LOCAL_top_dep_fr))
	  OPTYAP_ERROR_MESSAGE("Error on DepFr_top_or_fr (table_try)");
	aux_cp = B;
	while (YOUNGER_CP(aux_cp, DepFr_leader_cp(LOCAL_top_dep_fr)))
	  aux_cp = aux_cp->cp_b;
	if (aux_cp != DepFr_leader_cp(LOCAL_top_dep_fr))
	  OPTYAP_ERROR_MESSAGE("Error on DepFr_leader_cp (table_try)");
      }
#endif /* OPTYAP_ERRORS */
      goto answer_resolution;
#endif /* LINEAR_TABLING */
    } else {
      /* subgoal completed */
      ans_node_ptr ans_node = SgFr_first_answer(sg_fr);
      if (ans_node == NULL) {
	/* no answers --> fail */
	UNLOCK(SgFr_lock(sg_fr));
	goto fail;
      } else if (ans_node == SgFr_answer_trie(sg_fr)) {
	/* yes answer --> procceed */
	UNLOCK(SgFr_lock(sg_fr));
	PREG = (yamop *) CPREG;
	PREFETCH_OP(PREG);
	YENV = ENV;
	GONext();
      } else {
        /* answers -> get first answer */
#ifdef LIMIT_TABLING
	if (SgFr_state(sg_fr) == complete || SgFr_state(sg_fr) == compiled) {
	  SgFr_state(sg_fr)++;  /* complete --> complete_in_use : compiled --> compiled_in_use */
	  remove_from_global_sg_fr_list(sg_fr);
	  TRAIL_FRAME(sg_fr);
	}
#endif /* LIMIT_TABLING */
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
  ENDPBOp();



  Op(table_retry_me, Otapl)

#ifdef DUMMY_PRINT
  LOCAL_nr_consumed_alternatives++;
#endif /* DUMMY_PRINT */

    INFO_LINEAR_TABLING("-------------------------table_retry_me ---------------\n");
#ifdef LINEAR_TABLING
    sg_fr_ptr sg_fr = GEN_CP(B)->cp_sg_fr;
#ifdef LINEAR_TABLING_FOLLOWER
    restore_generator_node(PREG->u.Otapl.s, COMPLETION);
    SgFr_next_alt(sg_fr)=PREG->u.Otapl.d;
#else
    restore_generator_node(PREG->u.Otapl.s, PREG->u.Otapl.d);
#endif  /*LINEAR_TABLING_FOLLOWER */

#ifdef LINEAR_TABLING_DRA
     SgFr_current_alt(sg_fr) = NEXTOP(PREG,Otapl); 
#else
     add_alternative(sg_fr,NEXTOP(PREG,Otapl)); 
#endif /*LINEAR_TABLING_DRA*/
#else  /* ! LINEAR_TABLING  */
    restore_generator_node(PREG->u.Otapl.s, PREG->u.Otapl.d);
#endif   /*LINEAR_TABLING */
    YENV = (CELL *) PROTECT_FROZEN_B(B);
    set_cut(YENV, B->cp_b);
    SET_BB(NORM_CP(YENV));
    allocate_environment();
    PREG = NEXTOP(PREG,Otapl);
    GONext();
  ENDOp();



 Op(table_retry, Otapl)

#ifdef DUMMY_PRINT
 LOCAL_nr_consumed_alternatives++;
#endif /* DUMMY_PRINT */

     INFO_LINEAR_TABLING("-------------------------table_retry ---------------\n");
#ifdef LINEAR_TABLING
    sg_fr_ptr sg_fr = GEN_CP(B)->cp_sg_fr;
#ifdef LINEAR_TABLING_FOLLOWER
   restore_generator_node(PREG->u.Otapl.s, COMPLETION);
   SgFr_next_alt(sg_fr)= NEXTOP(PREG,Otapl);
#else
    restore_generator_node(PREG->u.Otapl.s, NEXTOP(PREG,Otapl));
#endif /*LINEAR_TABLING_FOLLOWER */

#ifdef LINEAR_TABLING_DRA
      SgFr_current_alt(sg_fr) = PREG->u.Otapl.d;
#else
      add_alternative(sg_fr,PREG->u.Otapl.d);
#endif /* LINEAR_TABLING_DRA */

#else /*!LINEAR_TABLING */
    restore_generator_node(PREG->u.Otapl.s, NEXTOP(PREG,Otapl));
#endif /*LINEAR_TABLING */
    YENV = (CELL *) PROTECT_FROZEN_B(B);
    set_cut(YENV, B->cp_b);
    SET_BB(NORM_CP(YENV));
    allocate_environment();
    PREG = PREG->u.Otapl.d;
    GONext();
  ENDOp();



  Op(table_trust_me, Otapl)

#ifdef DUMMY_PRINT
  LOCAL_nr_consumed_alternatives++;
#endif /* DUMMY_PRINT */

    INFO_LINEAR_TABLING("-------------------------table_trust_me ---------------\n");
#ifdef LINEAR_TABLING
    sg_fr_ptr sg_fr = GEN_CP(B)->cp_sg_fr; 
#ifdef LINEAR_TABLING_FOLLOWER
    SgFr_next_alt(sg_fr)= NULL;
#endif /* LINEAR_TABLING_FOLLOWER */
#ifdef LINEAR_TABLING_DRA
    SgFr_current_alt(sg_fr) = NEXTOP(PREG,Otapl);
#else 
    add_alternative(sg_fr,NEXTOP(PREG,Otapl));
#endif /*LINEAR_TABLING_DRA */ 

#endif /*LINEAR_TABLING */
    restore_generator_node(PREG->u.Otapl.s, COMPLETION);
#ifdef DETERMINISTIC_TABLING
    if (B_FZ > B && IS_BATCHED_NORM_GEN_CP(B)) {   
      CELL *subs_ptr = (CELL *)(GEN_CP(B) + 1) + PREG->u.Otapl.s;
      choiceptr gcp = NORM_CP(DET_GEN_CP(subs_ptr) - 1);
      sg_fr_ptr sg_fr = GEN_CP(B)->cp_sg_fr; 
      DET_GEN_CP(gcp)->cp_sg_fr = sg_fr;         
      gcp->cp_h     = B->cp_h;
#ifdef DEPTH_LIMIT
      gcp->cp_depth = B->cp_depth;
#endif /* DEPTH_LIMIT */
      gcp->cp_tr    = B->cp_tr;
      gcp->cp_b     = B->cp_b;
      gcp->cp_ap    = B->cp_ap;
      SgFr_gen_cp(sg_fr) = B = gcp;       
    }
#endif /* DETERMINISTIC_TABLING */
    YENV = (CELL *) PROTECT_FROZEN_B(B);
    set_cut(YENV, B->cp_b);
    SET_BB(NORM_CP(YENV));
    allocate_environment();
    PREG = NEXTOP(PREG,Otapl);
    GONext();
  ENDOp();



  Op(table_trust, Otapl)

#ifdef DUMMY_PRINT
  LOCAL_nr_consumed_alternatives++;
#endif /* DUMMY_PRINT */

   INFO_LINEAR_TABLING("-------------------------table_trust ---------------\n");
#ifdef LINEAR_TABLING
   sg_fr_ptr sgfr = GEN_CP(B)->cp_sg_fr; 
#ifdef LINEAR_TABLING_FOLLOWER
   SgFr_next_alt(sgfr)= NULL;
#endif /* LINEAR_TABLING_FOLLOWER */
#ifdef LINEAR_TABLING_DRA
   SgFr_current_alt(sgfr) =PREG->u.Otapl.d;
#else 
    add_alternative(sgfr,PREG->u.Otapl.d);
#endif /* LINEAR_TABLING_DRA*/
#endif /* LINEAR_TABLING */
   restore_generator_node(PREG->u.Otapl.s, COMPLETION);
#ifdef DETERMINISTIC_TABLING
  if (B_FZ > B && IS_BATCHED_NORM_GEN_CP(B)) {    
      CELL *subs_ptr = (CELL *)(GEN_CP(B) + 1) + PREG->u.Otapl.s;
      choiceptr gcp = NORM_CP(DET_GEN_CP(subs_ptr) - 1);
      sg_fr_ptr sg_fr = GEN_CP(B)->cp_sg_fr; 
      DET_GEN_CP(gcp)->cp_sg_fr = sg_fr;         
      gcp->cp_h     = B->cp_h;
#ifdef DEPTH_LIMIT
      gcp->cp_depth = B->cp_depth;
#endif /* DEPTH_LIMIT */
      gcp->cp_tr    = B->cp_tr;
      gcp->cp_b     = B->cp_b;
      gcp->cp_ap    = B->cp_ap;
      SgFr_gen_cp(sg_fr) = B = gcp;
    }
#endif /* DETERMINISTIC_TABLING */
    YENV = (CELL *) PROTECT_FROZEN_B(B);
    set_cut(YENV, B->cp_b);
    SET_BB(NORM_CP(YENV));
    allocate_environment();
    PREG = PREG->u.Otapl.d;
    GONext();
  ENDOp();



  PBOp(table_new_answer, s)
    CELL *subs_ptr;
    choiceptr gcp;
    sg_fr_ptr sg_fr;
    ans_node_ptr ans_node;

    gcp = NORM_CP(YENV[E_B]);
#ifdef DETERMINISTIC_TABLING
    if (IS_DET_GEN_CP(gcp)){  
      sg_fr = DET_GEN_CP(gcp)->cp_sg_fr;
      subs_ptr = (CELL *)(DET_GEN_CP(gcp) + 1) ; 
    } else
#endif /* DETERMINISTIC_TABLING */
    {
      sg_fr = GEN_CP(gcp)->cp_sg_fr;
      subs_ptr = (CELL *)(GEN_CP(gcp) + 1) + PREG->u.s.s;
    }
#if defined(TABLING_ERRORS) && !defined(DETERMINISTIC_TABLING)
    {
      int i, j, arity_args, arity_subs;
      CELL *aux_args;
      CELL *aux_subs;

      arity_args = PREG->u.s.s;
      arity_subs = *subs_ptr;
      aux_args = (CELL *)(GEN_CP(gcp) + 1);
      aux_subs = subs_ptr;
      for (i = 1; i <= arity_subs; i++) {
        Term term_subs = Deref(*(aux_subs + i));
        for (j = 0; j < arity_args; j++) {
          Term term_arg = Deref(*(aux_args + j));
          if (term_subs == term_arg) break;
	}
        if (j == arity_args)
          TABLING_ERROR_MESSAGE("j == arity_args (table_new_answer)");
      }
    }
#endif /* TABLING_ERRORS && !DETERMINISTIC_TABLING */
#ifdef TABLE_LOCK_AT_ENTRY_LEVEL
    LOCK(SgFr_lock(sg_fr));
#endif /* TABLE_LOCK_LEVEL */
    ans_node = answer_search(sg_fr, subs_ptr);
#if defined(TABLE_LOCK_AT_NODE_LEVEL)
    LOCK(TrNode_lock(ans_node));
#elif defined(TABLE_LOCK_AT_WRITE_LEVEL)
    LOCK_TABLE(ans_node);
#endif /* TABLE_LOCK_LEVEL */
    if (! IS_ANSWER_LEAF_NODE(ans_node)) {
      /* new answer */
#ifdef TABLING_INNER_CUTS
      /* check for potencial prunings */
      if (! BITMAP_empty(GLOBAL_bm_pruning_workers)) {
        int until_depth, depth;

        until_depth = OrFr_depth(SgFr_gen_top_or_fr(sg_fr));
        depth = OrFr_depth(LOCAL_top_or_fr);
        if (depth > until_depth) {
          int i, ltt;
          bitmap prune_members, members;
          or_fr_ptr leftmost_or_fr, or_fr, nearest_or_fr;

          BITMAP_copy(prune_members, GLOBAL_bm_pruning_workers);
          BITMAP_delete(prune_members, worker_id);
          ltt = BRANCH_LTT(worker_id, depth);
          BITMAP_intersection(members, prune_members, OrFr_members(LOCAL_top_or_fr));
          if (members) {
            for (i = 0; i < number_workers; i++) {
              if (BITMAP_member(members, i) && 
                  BRANCH_LTT(i, depth) > ltt && 
                  EQUAL_OR_YOUNGER_CP(LOCAL_top_cp, REMOTE_pruning_scope(i))) {
                leftmost_or_fr = LOCAL_top_or_fr;
  pending_table_new_answer:
#if defined(TABLE_LOCK_AT_ENTRY_LEVEL)
                UNLOCK(SgFr_lock(sg_fr));
#elif defined(TABLE_LOCK_AT_NODE_LEVEL)
                UNLOCK(TrNode_lock(ans_node));
#elif defined(TABLE_LOCK_AT_WRITE_LEVEL)
                UNLOCK_TABLE(ans_node);
#endif /* TABLE_LOCK_LEVEL */
                LOCK_OR_FRAME(leftmost_or_fr);
                if (LOCAL_prune_request) {
                  UNLOCK_OR_FRAME(leftmost_or_fr);
                  SCHEDULER_GET_WORK();
                } else {
                  CUT_store_tg_answer(leftmost_or_fr, ans_node, gcp, ltt);
                  UNLOCK_OR_FRAME(leftmost_or_fr);
                }
		if (IS_BATCHED_GEN_CP(gcp)) {
                  /* deallocate and procceed */
                  PREG = (yamop *) YENV[E_CP];
                  PREFETCH_OP(PREG);
                  CPREG = PREG;
                  SREG = YENV;
                  ENV = YENV = (CELL *) YENV[E_E];
#ifdef DEPTH_LIMIT
		  DEPTH = YENV[E_DEPTH];
#endif /* DEPTH_LIMIT */
                  GONext();
		} else {
                  /* fail */
                  goto fail;
		}
              }
	    }
            BITMAP_minus(prune_members, members);
	  }
          leftmost_or_fr = OrFr_nearest_leftnode(LOCAL_top_or_fr);
          depth = OrFr_depth(leftmost_or_fr);
          if (depth > until_depth) {
            ltt = BRANCH_LTT(worker_id, depth);
            BITMAP_intersection(members, prune_members, OrFr_members(leftmost_or_fr));
            if (members) {
              for (i = 0; i < number_workers; i++) {
                if (BITMAP_member(members, i) &&
                    BRANCH_LTT(i, depth) > ltt &&
                    EQUAL_OR_YOUNGER_CP(OrFr_node(leftmost_or_fr), REMOTE_pruning_scope(i)))
                  goto pending_table_new_answer;
	      }
              BITMAP_minus(prune_members, members);
            }
            /* reaching that point we should update the nearest leftnode data */
            leftmost_or_fr = OrFr_nearest_leftnode(leftmost_or_fr);
            depth = OrFr_depth(leftmost_or_fr);
            while (depth > until_depth) {
              ltt = BRANCH_LTT(worker_id, depth);
              BITMAP_intersection(members, prune_members, OrFr_members(leftmost_or_fr));
              if (members) {
                for (i = 0; i < number_workers; i++) {
                  if (BITMAP_member(members, i) &&
                      BRANCH_LTT(i, depth) > ltt &&
                      EQUAL_OR_YOUNGER_CP(OrFr_node(leftmost_or_fr), REMOTE_pruning_scope(i))) {
                    /* update nearest leftnode data */
                    or_fr = LOCAL_top_or_fr;
                    nearest_or_fr = OrFr_nearest_leftnode(or_fr);
                    while (OrFr_depth(nearest_or_fr) > depth) {
                      LOCK_OR_FRAME(or_fr);
                      OrFr_nearest_leftnode(or_fr) = leftmost_or_fr;
                      UNLOCK_OR_FRAME(or_fr);
                      or_fr = nearest_or_fr;
                      nearest_or_fr = OrFr_nearest_leftnode(or_fr);
                    }
                    goto pending_table_new_answer;
  	       	  }
		}
		BITMAP_minus(prune_members, members);
              }
              leftmost_or_fr = OrFr_nearest_leftnode(leftmost_or_fr);
              depth = OrFr_depth(leftmost_or_fr);
            }
            /* update nearest leftnode data */
            or_fr = LOCAL_top_or_fr;
            nearest_or_fr = OrFr_nearest_leftnode(or_fr);
            while (OrFr_depth(nearest_or_fr) > depth) {
              LOCK_OR_FRAME(or_fr);
              OrFr_nearest_leftnode(or_fr) = leftmost_or_fr;
              UNLOCK_OR_FRAME(or_fr);
              or_fr = nearest_or_fr;
              nearest_or_fr = OrFr_nearest_leftnode(or_fr);
            }
          }
        }
      }

      /* check for prune requests */
      if (LOCAL_prune_request) {
#if defined(TABLE_LOCK_AT_ENTRY_LEVEL)
        UNLOCK(SgFr_lock(sg_fr));
#elif defined(TABLE_LOCK_AT_NODE_LEVEL)
        UNLOCK(TrNode_lock(ans_node));
#elif defined(TABLE_LOCK_AT_WRITE_LEVEL)
        UNLOCK_TABLE(ans_node);
#endif /* TABLE_LOCK_LEVEL */
        SCHEDULER_GET_WORK();
      }
#endif /* TABLING_INNER_CUTS */
      TAG_AS_ANSWER_LEAF_NODE(ans_node);
#if defined(TABLE_LOCK_AT_NODE_LEVEL)
      UNLOCK(TrNode_lock(ans_node));
      LOCK(SgFr_lock(sg_fr));
#elif defined(TABLE_LOCK_AT_WRITE_LEVEL)
      UNLOCK_TABLE(ans_node);
      LOCK(SgFr_lock(sg_fr));
#endif /* TABLE_LOCK_LEVEL */
      if (SgFr_first_answer(sg_fr) == NULL)
	SgFr_first_answer(sg_fr) = ans_node;
      else
        TrNode_child(SgFr_last_answer(sg_fr)) = ans_node;
      SgFr_last_answer(sg_fr) = ans_node;
#ifdef LINEAR_TABLING
      //add_answer(sg_fr,ans_node);
#ifdef LINEAR_TABLING_DRS
      if (SgFr_new_answer_trie(sg_fr)==NULL){
	SgFr_new_answer_trie(sg_fr)=ans_node;
      }
#endif /*LINEAR_TABLING_DRS*/
      INFO_LINEAR_TABLING("nova resposta");
      TAG_NEW_ANSWERS(sg_fr);      
#endif /* LINEAR_TABLING */

#ifdef TABLING_ERRORS
      { 
        ans_node_ptr aux_ans_node = SgFr_first_answer(sg_fr);
        while (aux_ans_node != SgFr_last_answer(sg_fr)) {
          if (! IS_ANSWER_LEAF_NODE(aux_ans_node))
            TABLING_ERROR_MESSAGE("! IS_ANSWER_LEAF_NODE(aux_ans_node) (table_new_answer)");
          aux_ans_node = TrNode_child(aux_ans_node);
        }
      }
#endif /* TABLING_ERRORS */
      UNLOCK(SgFr_lock(sg_fr));
      if (IS_BATCHED_GEN_CP(gcp)) {


#if defined(TABLING_EARLY_COMPLETION) && !defined(LINEAR_TABLING) 
	if (gcp == PROTECT_FROZEN_B(B) && (*subs_ptr == 0 || gcp->cp_ap == COMPLETION)) {
	  /* if the current generator choice point is the topmost choice point and the current */
	  /* call is deterministic (i.e., the number of substitution variables is zero or      */
	  /* there are no more alternatives) then the current answer is deterministic and we   */
	  /* can perform an early completion and remove the current generator choice point     */
	  private_completion(sg_fr);
	  B = B->cp_b;
	  SET_BB(PROTECT_FROZEN_B(B));
	} else if (*subs_ptr == 0) {
	  /* if the number of substitution variables is zero, an answer is sufficient to perform */
          /* an early completion, but the current generator choice point cannot be removed       */
	  mark_as_completed(sg_fr);
	  if (gcp->cp_ap != NULL)
	    gcp->cp_ap = COMPLETION;
	}
#endif /* TABLING_EARLY_COMPLETION */

        /* deallocate and procceed */
        PREG = (yamop *) YENV[E_CP];
        PREFETCH_OP(PREG);
        CPREG = PREG;
        SREG = YENV;
        ENV = YENV = (CELL *) YENV[E_E];
#ifdef DEPTH_LIMIT
	DEPTH = YENV[E_DEPTH];
#endif /* DEPTH_LIMIT */
        GONext();
      } else {
#if defined(TABLING_EARLY_COMPLETION)  && !defined(LINEAR_TABLING) 
	if (*subs_ptr == 0) {
	  /* if the number of substitution variables is zero, an answer is sufficient to perform */
          /* an early completion, but the current generator choice point cannot be removed       */
	  mark_as_completed(sg_fr);
	  if (gcp->cp_ap != ANSWER_RESOLUTION)
	    gcp->cp_ap = COMPLETION;
	}
#endif /* TABLING_EARLY_COMPLETION */
        /* fail */
        goto fail;
      }
    } else {
      /* repeated answer */
#if defined(TABLE_LOCK_AT_ENTRY_LEVEL)
      UNLOCK(SgFr_lock(sg_fr));
#elif defined(TABLE_LOCK_AT_NODE_LEVEL)
      UNLOCK(TrNode_lock(ans_node));
#elif defined(TABLE_LOCK_AT_WRITE_LEVEL)
      UNLOCK_TABLE(ans_node);
#endif /* TABLE_LOCK_LEVEL */
      goto fail;
    }
  ENDPBOp();



  BOp(table_answer_resolution, Otapl)
#ifdef YAPOR
    if (SCH_top_shared_cp(B)) {
      UNLOCK_OR_FRAME(LOCAL_top_or_fr);
    }
#endif /* YAPOR */


  answer_resolution:
    INIT_PREFETCH()
    dep_fr_ptr dep_fr;
    ans_node_ptr ans_node;

#ifdef OPTYAP_ERRORS
    if (SCH_top_shared_cp(B)) {
      if (B->cp_or_fr->alternative != ANSWER_RESOLUTION)
        OPTYAP_ERROR_MESSAGE("B->cp_or_fr->alternative != ANSWER_RESOLUTION (answer_resolution)");
    } else {
      if (B->cp_ap != ANSWER_RESOLUTION)
        OPTYAP_ERROR_MESSAGE("B->cp_ap != ANSWER_RESOLUTION (answer_resolution)");
    }
#endif /* OPTYAP_ERRORS */
    dep_fr = CONS_CP(B)->cp_dep_fr;
    LOCK(DepFr_lock(dep_fr));
    ans_node = DepFr_last_answer(dep_fr);
    if (TrNode_child(ans_node)) {
      /* unconsumed answer */
      ans_node = DepFr_last_answer(dep_fr) = TrNode_child(ans_node);
      UNLOCK(DepFr_lock(dep_fr));
      consume_answer_and_procceed(dep_fr, ans_node);
    }
    UNLOCK(DepFr_lock(dep_fr));

#ifdef YAPOR
    if (B == DepFr_leader_cp(LOCAL_top_dep_fr)) {
      /*  B is a generator-consumer node  **
      ** never here if batched scheduling */
#ifdef TABLING_ERRORS
      if (IS_BATCHED_GEN_CP(B))
        TABLING_ERROR_MESSAGE("IS_BATCHED_GEN_CP(B) (answer_resolution)");
#endif /* TABLING_ERRORS */
      goto completion;
    }
#endif /* YAPOR */

    /* no unconsumed answers */
    if (DepFr_backchain_cp(dep_fr) == NULL) {
      /* normal backtrack */
#ifdef YAPOR
      if (SCH_top_shared_cp(B)) {
        SCHEDULER_GET_WORK();
      }
#endif /* YAPOR */
      B = B->cp_b;
      goto fail;
    } else {
      /* chain backtrack */
      choiceptr top_chain_cp, chain_cp;
#ifdef YAPOR
      or_fr_ptr start_or_fr, end_or_fr;
#endif /* YAPOR */

      /* find chain choice point to backtrack */
      top_chain_cp = DepFr_backchain_cp(dep_fr);
      chain_cp = DepFr_leader_cp(LOCAL_top_dep_fr);
      if (YOUNGER_CP(top_chain_cp, chain_cp))
        chain_cp = top_chain_cp;
#ifdef TABLING_ERRORS
      if (EQUAL_OR_YOUNGER_CP(top_chain_cp, B))
        TABLING_ERROR_MESSAGE("EQUAL_OR_YOUNGER_CP(top_chain_cp, B) (answer_resolution)");
      else if (EQUAL_OR_YOUNGER_CP(chain_cp, B))
        TABLING_ERROR_MESSAGE("EQUAL_OR_YOUNGER_CP(chain_cp, B) (answer_resolution)");
#endif /* TABLING_ERRORS */

      /* check for dependency frames with unconsumed answers */
      dep_fr = DepFr_next(dep_fr);
      while (YOUNGER_CP(DepFr_cons_cp(dep_fr), chain_cp)) {
        LOCK(DepFr_lock(dep_fr));
        ans_node = DepFr_last_answer(dep_fr);
        if (TrNode_child(ans_node)) {
          /* dependency frame with unconsumed answers */
          ans_node = DepFr_last_answer(dep_fr) = TrNode_child(ans_node);
#ifdef YAPOR
          if (YOUNGER_CP(DepFr_backchain_cp(dep_fr), top_chain_cp))
#endif /* YAPOR */
            DepFr_backchain_cp(dep_fr) = top_chain_cp;
          UNLOCK(DepFr_lock(dep_fr));

          chain_cp = DepFr_cons_cp(dep_fr);
#ifdef YAPOR
          /* update shared nodes */
          start_or_fr = LOCAL_top_or_fr;
          end_or_fr = DepFr_top_or_fr(dep_fr);
          if (start_or_fr != end_or_fr) {
            LOCAL_top_or_fr = end_or_fr;
            LOCAL_top_cp = OrFr_node(end_or_fr);
            do {
              while (YOUNGER_CP(OrFr_node(start_or_fr), OrFr_node(end_or_fr))) {
                LOCK_OR_FRAME(start_or_fr);
                BITMAP_delete(OrFr_members(start_or_fr), worker_id);
                if (BITMAP_empty(OrFr_members(start_or_fr))) {
                  if (frame_with_suspensions_not_collected(start_or_fr)) {
                    collect_suspension_frames(start_or_fr);
                  }
#ifdef TABLING_INNER_CUTS
                  if (OrFr_tg_solutions(start_or_fr)) {
                    tg_sol_fr_ptr tg_solutions;
                    or_fr_ptr leftmost_until;
                    tg_solutions = OrFr_tg_solutions(start_or_fr);
                    leftmost_until = CUT_leftmost_until(start_or_fr, OrFr_depth(TgSolFr_gen_cp(tg_solutions)->cp_or_fr));
                    OrFr_tg_solutions(start_or_fr) = NULL;
                    UNLOCK_OR_FRAME(start_or_fr);
                    if (leftmost_until) {
                      LOCK_OR_FRAME(leftmost_until);
                      tg_solutions = CUT_store_tg_answers(leftmost_until, tg_solutions,
                                                          BRANCH_LTT(worker_id, OrFr_depth(leftmost_until)));
                      UNLOCK_OR_FRAME(leftmost_until);
                    }
                    CUT_validate_tg_answers(tg_solutions);
                    goto continue_update_loop1;
                  }
#endif /* TABLING_INNER_CUTS */
                }
                UNLOCK_OR_FRAME(start_or_fr);
#ifdef TABLING_INNER_CUTS
  continue_update_loop1:
#endif /* TABLING_INNER_CUTS */
                start_or_fr = OrFr_next(start_or_fr);
  	      }
              while (YOUNGER_CP(OrFr_node(end_or_fr), OrFr_node(start_or_fr))) {
                LOCK_OR_FRAME(end_or_fr);
                BITMAP_insert(OrFr_members(end_or_fr), worker_id);
                BRANCH(worker_id, OrFr_depth(end_or_fr)) = 1;
                UNLOCK_OR_FRAME(end_or_fr);
                end_or_fr = OrFr_next(end_or_fr);
	      }
    	    } while (start_or_fr != end_or_fr);
            if (LOCAL_prune_request)
              pruning_over_tabling_data_structures(); 	
          }
#endif /* YAPOR */
#ifdef OPTYAP_ERRORS
          if (PARALLEL_EXECUTION_MODE) {
            if (YOUNGER_CP(LOCAL_top_cp, LOCAL_top_cp_on_stack)) {
              OPTYAP_ERROR_MESSAGE("YOUNGER_CP(LOCAL_top_cp, LOCAL_top_cp_on_stack) (answer_resolution)");
    	    } else {
              choiceptr aux_cp;
              aux_cp = chain_cp;
              while (aux_cp != LOCAL_top_cp) {
                if (YOUNGER_CP(LOCAL_top_cp, aux_cp)) {
                  OPTYAP_ERROR_MESSAGE("LOCAL_top_cp not in branch (answer_resolution)");
                  break;
                }
                if (EQUAL_OR_YOUNGER_CP(LOCAL_top_cp_on_stack, aux_cp)) {
                  OPTYAP_ERROR_MESSAGE("shared frozen segments in branch (answer_resolution)");
                  break;
                }
                aux_cp = aux_cp->cp_b;
              }
    	    }
	  }
#endif /* OPTYAP_ERRORS */
          /* restore bindings, update registers, consume answer and procceed */
          restore_bindings(B->cp_tr, chain_cp->cp_tr);
#ifdef TABLING_ERRORS
          if (TR != B->cp_tr) {
            if(! IsPairTerm((CELL)TrailTerm(TR - 1)))
              TABLING_ERROR_MESSAGE("! IsPairTerm((CELL)TrailTerm(TR - 1)) (answer_resolution)");
            if ((tr_fr_ptr) RepPair((CELL)TrailTerm(TR - 1)) != B->cp_tr)
              TABLING_ERROR_MESSAGE("RepPair((CELL)TrailTerm(TR - 1)) != B->cp_tr (answer_resolution)");
	  }
#endif /* TABLING_ERRORS */
          B = chain_cp;
          TR = TR_FZ;
          TRAIL_LINK(B->cp_tr);
          consume_answer_and_procceed(dep_fr, ans_node);
	}
        UNLOCK(DepFr_lock(dep_fr));
        dep_fr = DepFr_next(dep_fr);
      }

      /* no dependency frames with unconsumed answers found */
#ifdef YAPOR
      /* update shared nodes */
      if (EQUAL_OR_YOUNGER_CP(LOCAL_top_cp_on_stack, chain_cp)) {
        end_or_fr = chain_cp->cp_or_fr;
        start_or_fr = LOCAL_top_or_fr;
        if (start_or_fr != end_or_fr) {
          LOCAL_top_or_fr = end_or_fr;
          LOCAL_top_cp = OrFr_node(end_or_fr);
          while (start_or_fr != end_or_fr) {
            LOCK_OR_FRAME(start_or_fr);
            BITMAP_delete(OrFr_members(start_or_fr), worker_id);
            if (BITMAP_empty(OrFr_members(start_or_fr))) {
              if (frame_with_suspensions_not_collected(start_or_fr)) {
                collect_suspension_frames(start_or_fr);
              }
#ifdef TABLING_INNER_CUTS
              if (OrFr_tg_solutions(start_or_fr)) {
                tg_sol_fr_ptr tg_solutions;
                or_fr_ptr leftmost_until;
                tg_solutions = OrFr_tg_solutions(start_or_fr);
                leftmost_until = CUT_leftmost_until(start_or_fr, OrFr_depth(TgSolFr_gen_cp(tg_solutions)->cp_or_fr));
                OrFr_tg_solutions(start_or_fr) = NULL;
                UNLOCK_OR_FRAME(start_or_fr);
                if (leftmost_until) {
                  LOCK_OR_FRAME(leftmost_until);
                  tg_solutions = CUT_store_tg_answers(leftmost_until, tg_solutions,
                                                      BRANCH_LTT(worker_id, OrFr_depth(leftmost_until)));
                  UNLOCK_OR_FRAME(leftmost_until);
                }
                CUT_validate_tg_answers(tg_solutions);
                goto continue_update_loop2;
              }
#endif /* TABLING_INNER_CUTS */
            }
            UNLOCK_OR_FRAME(start_or_fr);
#ifdef TABLING_INNER_CUTS
  continue_update_loop2:
#endif /* TABLING_INNER_CUTS */
            start_or_fr = OrFr_next(start_or_fr);
  	  }
          if (LOCAL_prune_request)
            pruning_over_tabling_data_structures(); 
        }
      }
#endif /* YAPOR */
#ifdef OPTYAP_ERRORS
      if (PARALLEL_EXECUTION_MODE) {
        if (YOUNGER_CP(LOCAL_top_cp, LOCAL_top_cp_on_stack)) {
          OPTYAP_ERROR_MESSAGE("YOUNGER_CP(LOCAL_top_cp, LOCAL_top_cp_on_stack) (answer_resolution)");
	} else {
          choiceptr aux_cp;
          aux_cp = chain_cp;
          while (aux_cp != LOCAL_top_cp) {
            if (YOUNGER_CP(LOCAL_top_cp, aux_cp)) {
              OPTYAP_ERROR_MESSAGE("LOCAL_top_cp not in branch (answer_resolution)");
              break;
            }
            if (EQUAL_OR_YOUNGER_CP(LOCAL_top_cp_on_stack, aux_cp)) {
              OPTYAP_ERROR_MESSAGE("shared frozen segments in branch (answer_resolution)");
              break;
            }
            aux_cp = aux_cp->cp_b;
          }
	}
      }
#endif /* OPTYAP_ERRORS */
      /* unbind variables */
      unbind_variables(B->cp_tr, chain_cp->cp_tr);
#ifdef TABLING_ERRORS
      if (TR != B->cp_tr) {
        if(! IsPairTerm((CELL)TrailTerm(TR - 1)))
          TABLING_ERROR_MESSAGE("! IsPairTerm((CELL)TrailTerm(TR - 1)) (answer_resolution)");
        if ((tr_fr_ptr) RepPair((CELL)TrailTerm(TR - 1)) != B->cp_tr)
          TABLING_ERROR_MESSAGE("RepPair((CELL)TrailTerm(TR - 1)) != B->cp_tr (answer_resolution)");
      }
#endif /* TABLING_ERRORS */
      if (DepFr_leader_cp(LOCAL_top_dep_fr) == chain_cp && (
        /* chain_cp is a leader node AND ... */
#ifdef YAPOR
        /* the leader dependency is not on stack OR ... */
        DepFr_leader_dep_is_on_stack(LOCAL_top_dep_fr) == FALSE ||
        /* the leader dependency is on stack (this means that chain_cp is a generator node) and */
#endif /* YAPOR */
        /*                 there are no unexploited alternatives                 **
        ** (NULL if batched scheduling OR ANSWER_RESOLUTION if local scheduling) */
        chain_cp->cp_ap == NULL || chain_cp->cp_ap == ANSWER_RESOLUTION)) {
        B = chain_cp;
        TR = TR_FZ;
        TRAIL_LINK(B->cp_tr);
        goto completion;
      }
      /* backtrack to chain choice point */
      PREG = chain_cp->cp_ap;
      PREFETCH_OP(PREG);
      B = chain_cp;
      TR = TR_FZ;
      TRAIL_LINK(B->cp_tr);
      GONext();
    }
    END_PREFETCH()
  ENDBOp();




  BOp(table_completion, Otapl)

 INFO_LINEAR_TABLING("-------------------------table_completion ---------------");
#ifdef LINEAR_TABLING
{ 
  sg_fr_ptr sg_fr = GEN_CP(B)->cp_sg_fr;       
  INFO_LINEAR_TABLING("sg_fr=%p",sg_fr);

#ifdef LINEAR_TABLING_BATCHED    
  if(SgFr_batched_ans(sg_fr)!=NULL){
    INFO_LINEAR_TABLING("batched answer");        
    if(SgFr_batched_ans(sg_fr)!=SgFr_last_answer(sg_fr)){
      INFO_LINEAR_TABLING("batched_ans !=last_answ");
      SgFr_batched_ans(sg_fr)=TrNode_child(SgFr_batched_ans(sg_fr));
      restore_generator_node(SgFr_arity(sg_fr), COMPLETION);
      PREG = (yamop *) CPREG;
      PREFETCH_OP(PREG);
      CELL *subs_ptr;
      subs_ptr = (CELL *) (GEN_CP(B) + 1);          
      subs_ptr += SgFr_arity(GEN_CP(B)->cp_sg_fr);
      load_answer_trie(SgFr_batched_ans(sg_fr), subs_ptr);    
      YENV = ENV;
      GONext();
    }else{
      INFO_LINEAR_TABLING("no more answers to consume");
      SgFr_batched_ans(sg_fr)=NULL;
      if(!IS_LEADER(sg_fr)){
	restore_generator_node(SgFr_arity(sg_fr), COMPLETION);
	SgFr_stop_loop_alt(sg_fr)=SgFr_current_loop_alt(sg_fr);
	YENV = (CELL *) PROTECT_FROZEN_B(B);
	set_cut(YENV, B->cp_b);
	SET_BB(NORM_CP(YENV));
	PREG = GET_CELL_VALUE(SgFr_current_loop_alt(sg_fr));
	PREFETCH_OP(PREG);
	allocate_environment();
	GONext();
      }
      /*computation on leader nodes follows to standard dra execution */
      
    }
  }
#endif /*LINEAR_TABLING_BATCHED */


#if defined(LINEAR_TABLING_FOLLOWER)
  if (SgFr_next_alt(sg_fr)!=NULL){
    PREG = SgFr_next_alt(sg_fr);
    INFO_LINEAR_TABLING("next alt != null");
    PREFETCH_OP(PREG);
    GONext();    
  }
  if (SgFr_pioneer(sg_fr) != B){
    INFO_LINEAR_TABLING("follower");
    if (SgFr_state(sg_fr) == looping_evaluating){
      yamop **follower_alt=SgFr_current_loop_alt(sg_fr)+1;
      if (IS_JUMP_CELL(follower_alt))
	ALT_JUMP_NEXT_CELL(follower_alt);
      if (follower_alt != SgFr_stop_loop_alt(sg_fr)){
#ifdef DUMMY_PRINT
	LOCAL_nr_consumed_alternatives++;
#endif /* DUMMY_PRINT */
	restore_generator_node(SgFr_arity(sg_fr), COMPLETION);
	YENV = (CELL *) PROTECT_FROZEN_B(B);
	set_cut(YENV, B->cp_b);
	SET_BB(NORM_CP(YENV));
	allocate_environment();
	SgFr_current_loop_alt(sg_fr)=follower_alt;
	if (IS_LEADER(sg_fr) && HAS_NEW_ANSWERS(sg_fr) ) {  
	  INFO_LINEAR_TABLING("is_leader and has new answers");
	  DUMMY_LOCAL_nr_is_leader_and_has_new_answers_inc();
	  UNTAG_NEW_ANSWERS(sg_fr);
	  SgFr_stop_loop_alt(sg_fr)=SgFr_current_loop_alt(sg_fr);
	}
	PREG = GET_CELL_VALUE(SgFr_current_loop_alt(sg_fr));
	GONext();
      }       
    }
    /* pop generator node and store loader to consume all answers*/
    ans_node_ptr ans_node = SgFr_first_answer(sg_fr);
    if (ans_node == NULL) {
      /* no answers --> fail */
      remove_next(sg_fr);
      B = B->cp_b;
      SET_BB(PROTECT_FROZEN_B(B));
      goto fail;
    }
    remove_next(sg_fr);
    pop_generator_node(SgFr_arity(sg_fr));
    if (ans_node == SgFr_answer_trie(sg_fr)) {
      /* yes answer --> procceed */
      PREG = (yamop *) CPREG;
      PREFETCH_OP(PREG);
      YENV = ENV;
      GONext();
    } else  {
      /* answers -> get first answer */
#ifdef LIMIT_TABLING
      SgFr_state(sg_fr)++;  /* complete --> complete_in_use */
      remove_from_global_sg_fr_list(sg_fr);
      TRAIL_FRAME(sg_fr);
#endif /* LIMIT_TABLING */
      /* load answers from the trie */
#ifdef DUMMY_PRINT
      store_loader_node(tab_ent, ans_node,0);
#else /*!DUMMY_PRINT */
      store_loader_node(tab_ent, ans_node);
#endif /*DUMMY_PRINT */
      PREG = (yamop *) CPREG;
      PREFETCH_OP(PREG);
      load_answer_trie(ans_node, YENV);
      YENV = ENV;
      GONext();
    }   
  }
#endif  /*LINEAR_TABLING_FOLLOWER */


#ifdef LINEAR_TABLING_DRS 
  if (SgFr_consuming_answers(sg_fr)==1){
    /*continue loading looping answers */    
    if (SgFr_current_loop_ans(sg_fr)!=SgFr_stop_loop_ans(sg_fr)){
      SgFr_current_loop_ans(sg_fr)++;
      if (IS_JUMP_CELL(SgFr_current_loop_ans(sg_fr)))
	ANS_JUMP_NEXT_CELL(SgFr_current_loop_ans(sg_fr));
      restore_generator_node(SgFr_arity(sg_fr), COMPLETION);
      PREG = (yamop *) CPREG;
      PREFETCH_OP(PREG);
      CELL *subs_ptr;
      subs_ptr = (CELL *) (GEN_CP(B) + 1);          
      subs_ptr += SgFr_arity(GEN_CP(B)->cp_sg_fr);
#ifdef DUMMY_PRINT
      LOCAL_nr_consumed_answers++;      
#endif /*DUMMY_PRINT */
      load_answer_trie(GET_CELL_VALUE(SgFr_current_loop_ans(sg_fr)), subs_ptr);
      YENV = ENV;
      GONext();
      /*first time that direct trie answers are loaded */    
    }else if (SgFr_new_answer_trie(sg_fr)!=NULL){
      if(sg_fr!=LOCAL_top_sg_fr_on_branch)
	add_branch(sg_fr);
      SgFr_consuming_answers(sg_fr)=2;
      restore_generator_node(SgFr_arity(sg_fr), COMPLETION);
      PREG = (yamop *) CPREG;
      PREFETCH_OP(PREG);
      CELL *subs_ptr;
      subs_ptr = (CELL *) (GEN_CP(B) + 1);          
      subs_ptr += SgFr_arity(GEN_CP(B)->cp_sg_fr);
#ifdef DUMMY_PRINT
      LOCAL_nr_consumed_answers++;      
#endif /*DUMMY_PRINT */
      load_answer_trie(SgFr_new_answer_trie(sg_fr), subs_ptr);
      YENV = ENV;
      GONext();
    }    
  }
  
  /*continue loading answers from trie */

  if (SgFr_consuming_answers(sg_fr)==2){
    if (SgFr_new_answer_trie(sg_fr)!=SgFr_last_answer(sg_fr)){
      SgFr_new_answer_trie(sg_fr)=TrNode_child(SgFr_new_answer_trie(sg_fr));
      restore_generator_node(SgFr_arity(sg_fr), COMPLETION);
      PREG = (yamop *) CPREG;
      PREFETCH_OP(PREG);
      CELL *subs_ptr;
      subs_ptr = (CELL *) (GEN_CP(B) + 1);          
      subs_ptr += SgFr_arity(GEN_CP(B)->cp_sg_fr);

#ifdef DUMMY_PRINT
      LOCAL_nr_consumed_answers++;      
#endif /*DUMMY_PRINT */

      load_answer_trie(SgFr_new_answer_trie(sg_fr), subs_ptr);    
      YENV = ENV;
      GONext();
    }
  }
  /*no more answers to explore. */
  if(SgFr_consuming_answers(sg_fr)==1 || SgFr_consuming_answers(sg_fr)==2){
    if(sg_fr==LOCAL_top_sg_fr_on_branch){
      remove_branch(sg_fr);
    }
    if(HAS_NEW_ANSWERS(sg_fr)){
      TAG_NEW_ANSWERS(LOCAL_top_sg_fr_on_branch);
      UNTAG_NEW_ANSWERS(sg_fr);
    }
    remove_next(sg_fr);
    SgFr_consuming_answers(sg_fr)=0;      
    B = B->cp_b;
    SET_BB(PROTECT_FROZEN_B(B));
    goto fail;  
}
   
#endif /*LINEAR_TABLING_DRS */


#ifdef LINEAR_TABLING_DRA
    if (SgFr_current_loop_alt(sg_fr) != NULL) 
#endif /*LINEAR_TABLING_DRA*/
      {
      if (SgFr_state(sg_fr) == evaluating){

	/*first time on table completion */	   
	SgFr_state(sg_fr) = looping_evaluating;  
	if (!IS_LEADER(sg_fr))	  
	  remove_branch(sg_fr);
	SgFr_stop_loop_alt(sg_fr)=sg_fr->loop_alts;
	SgFr_current_loop_alt(sg_fr)++;
	ALT_TAG_AS_JUMP_CELL(SgFr_current_loop_alt(sg_fr),SgFr_stop_loop_alt(sg_fr));
	SgFr_current_loop_alt(sg_fr)=SgFr_stop_loop_alt(sg_fr);
      } else { 
  	/*get next alternative  */
#ifdef LINEAR_TABLING_BATCHED
	if (SgFr_batched_consuming_answers(sg_fr)==0)
#endif /*LINEAR_TABLING_BATCHED */
	   {
	     SgFr_current_loop_alt(sg_fr)++;
	     if (IS_JUMP_CELL(SgFr_current_loop_alt(sg_fr))){
	      ALT_JUMP_NEXT_CELL(SgFr_current_loop_alt(sg_fr));	  
	    }
	  }
      }

      if (IS_LEADER(sg_fr) && HAS_NEW_ANSWERS(sg_fr) ) {  
	INFO_LINEAR_TABLING("is_leader and has new answers");
	DUMMY_LOCAL_nr_is_leader_and_has_new_answers_inc();	
#ifdef LINEAR_TABLING_BATCHED
	if(SgFr_current_loop_alt(sg_fr)==SgFr_stop_loop_alt(sg_fr) && SgFr_batched_consuming_answers(sg_fr)==0){  
#endif
	  /*reset dependant subgoals */
	  while(LOCAL_max_scc !=sg_fr){                        
	    SgFr_state(LOCAL_max_scc) = looping_ready;
	    INFO_LINEAR_TABLING("LOCAL_MAX_SCC=%p",LOCAL_max_scc);	
	    LOCAL_max_scc  = SgFr_next_on_scc(LOCAL_max_scc);
	  }
#ifdef LINEAR_TABLING_BATCHED
	  /*consume trie answers- if any */	  
	  if(SgFr_first_answer(sg_fr)!=NULL){
	    SgFr_batched_consuming_answers(sg_fr)=2;
	    restore_generator_node(SgFr_arity(sg_fr), COMPLETION);
	    batched_consume_first_answer(sg_fr);
	  }
	}
#endif	/* LINEAR_TABLING_BATCHED */ 		
	UNTAG_NEW_ANSWERS(sg_fr);
	SgFr_stop_loop_alt(sg_fr)=SgFr_current_loop_alt(sg_fr);
#ifdef LINEAR_TABLING_BATCHED
	SgFr_batched_consuming_answers(sg_fr)=0;
#endif /*LINEAR_TABLING_BATCHED */
	restore_generator_node(SgFr_arity(sg_fr), COMPLETION);
	YENV = (CELL *) PROTECT_FROZEN_B(B);
	set_cut(YENV, B->cp_b);
	SET_BB(NORM_CP(YENV));
	allocate_environment();
	PREG = GET_CELL_VALUE(SgFr_current_loop_alt(sg_fr));
	INFO_LINEAR_TABLING("current_alt=%p",PREG);
	PREFETCH_OP(PREG);
#ifdef DUMMY_PRINT
	LOCAL_nr_consumed_alternatives++;
#endif /* DUMMY_PRINT */
	GONext();          
      }
      
      if (SgFr_current_loop_alt(sg_fr) != SgFr_stop_loop_alt(sg_fr) ) {  
	INFO_LINEAR_TABLING("next loop alt");
	restore_generator_node(SgFr_arity(sg_fr), COMPLETION);
	YENV = (CELL *) PROTECT_FROZEN_B(B);
	set_cut(YENV, B->cp_b);
	SET_BB(NORM_CP(YENV));
	allocate_environment();
	PREG = GET_CELL_VALUE(SgFr_current_loop_alt(sg_fr));
	INFO_LINEAR_TABLING("current_alt=%p",PREG);
	PREFETCH_OP(PREG);
#ifdef DUMMY_PRINT
	LOCAL_nr_consumed_alternatives++;
#endif /* DUMMY_PRINT */
	GONext();    
      }
    }
    

#ifdef LINEAR_TABLING_DRS
    if (IS_LEADER(sg_fr)){
      INFO_LINEAR_TABLING("is leader");
      if(sg_fr==LOCAL_top_sg_fr_on_branch)
	remove_branch(sg_fr);
      goto complete_all;      
    }
    goto consume_all;
}
#else /*!LINEAR_TABLING_DRS */

     if(sg_fr==LOCAL_top_sg_fr_on_branch)
       remove_branch(sg_fr);
     if (IS_LEADER(sg_fr)){
       INFO_LINEAR_TABLING("is leader");
       goto complete_all;
    } else {
       if (HAS_NEW_ANSWERS(sg_fr)) {
	 UNTAG_NEW_ANSWERS(sg_fr);
	 TAG_NEW_ANSWERS(LOCAL_top_sg_fr_on_branch);
       }
     goto consume_all;   
  }
}

#endif /*LINEAR_TABLING_DRS */

#endif /*LINEAR_TABLING */

#ifdef YAPOR
    if (SCH_top_shared_cp(B)) {
      if (IS_BATCHED_GEN_CP(B)) {
        SCH_new_alternative(PREG, NULL);
        if (B != DepFr_leader_cp(LOCAL_top_dep_fr) && EQUAL_OR_YOUNGER_CP(B_FZ, B)) {
          /* not leader on that node */
          SCHEDULER_GET_WORK();
        }
      } else {
        SCH_new_alternative(PREG, ANSWER_RESOLUTION);
        if (B != DepFr_leader_cp(LOCAL_top_dep_fr)) {
          /* not leader on that node */
          SCHEDULER_GET_WORK();
        }
      }
    } else
#endif /* YAPOR */
    {
      if (IS_BATCHED_GEN_CP(B)) {
        B->cp_ap = NULL;
        if (EQUAL_OR_YOUNGER_CP(B_FZ, B) && B != DepFr_leader_cp(LOCAL_top_dep_fr)) {
          /* not leader on that node */
          B = B->cp_b;
          goto fail;
        }
      } else {
        B->cp_ap = ANSWER_RESOLUTION;
        if (B != DepFr_leader_cp(LOCAL_top_dep_fr)) {
          /* not leader on that node */
	  goto answer_resolution; 
	  /* B = B->cp_b;
	     goto fail; */
        }
      }
    }
    /* leader on that node */


  completion:
    INIT_PREFETCH()
    dep_fr_ptr dep_fr;
    ans_node_ptr ans_node;
#ifdef YAPOR
#ifdef TIMESTAMP_CHECK
    long timestamp = 0;
#endif /* TIMESTAMP_CHECK */
    int entry_owners = 0;

    if (SCH_top_shared_cp(B)) {
#ifdef TIMESTAMP_CHECK
      timestamp = ++GLOBAL_timestamp;
#endif /* TIMESTAMP_CHECK */
      entry_owners = OrFr_owners(LOCAL_top_or_fr);
    }
#endif /* YAPOR */

    /* check for dependency frames with unconsumed answers */
    dep_fr = LOCAL_top_dep_fr;
    while (YOUNGER_CP(DepFr_cons_cp(dep_fr), B)) {
      LOCK(DepFr_lock(dep_fr));
      ans_node = DepFr_last_answer(dep_fr);
      if (TrNode_child(ans_node)) {    
        /* dependency frame with unconsumed answers */
        ans_node = DepFr_last_answer(dep_fr) = TrNode_child(ans_node);
        if (B->cp_ap) {
#ifdef YAPOR
          if (YOUNGER_CP(DepFr_backchain_cp(dep_fr), B))
#endif /* YAPOR */
            DepFr_backchain_cp(dep_fr) = B;
	} else {
#ifdef YAPOR
          if (YOUNGER_CP(DepFr_backchain_cp(dep_fr), B->cp_b))
#endif /* YAPOR */
            DepFr_backchain_cp(dep_fr) = B->cp_b;
	}
        UNLOCK(DepFr_lock(dep_fr));

#ifdef OPTYAP_ERRORS
        if (PARALLEL_EXECUTION_MODE) {
          if (YOUNGER_CP(LOCAL_top_cp, LOCAL_top_cp_on_stack)) {
            OPTYAP_ERROR_MESSAGE("YOUNGER_CP(LOCAL_top_cp, LOCAL_top_cp_on_stack) (completion)");
          } else {
            choiceptr aux_cp;
            aux_cp = DepFr_cons_cp(dep_fr);
            while (YOUNGER_CP(aux_cp, LOCAL_top_cp_on_stack))
              aux_cp = aux_cp->cp_b;
            if (aux_cp->cp_or_fr != DepFr_top_or_fr(dep_fr))
              OPTYAP_ERROR_MESSAGE("Error on DepFr_top_or_fr (completion)");
	  }
	}
#endif /* OPTYAP_ERRORS */
#ifdef YAPOR
        /* update shared nodes */
        if (YOUNGER_CP(LOCAL_top_cp_on_stack, LOCAL_top_cp)) {
          or_fr_ptr or_frame = DepFr_top_or_fr(dep_fr);
          while (or_frame != LOCAL_top_or_fr) {
            LOCK_OR_FRAME(or_frame);
            BITMAP_insert(OrFr_members(or_frame), worker_id);
            BRANCH(worker_id, OrFr_depth(or_frame)) = 1;
            UNLOCK_OR_FRAME(or_frame);
            or_frame = OrFr_next(or_frame);
          }
          LOCAL_top_or_fr = DepFr_top_or_fr(dep_fr);
          LOCAL_top_cp = OrFr_node(LOCAL_top_or_fr);
        }
#endif /* YAPOR */
#ifdef OPTYAP_ERRORS
        if (PARALLEL_EXECUTION_MODE) {
          if (YOUNGER_CP(LOCAL_top_cp, LOCAL_top_cp_on_stack)) {
            OPTYAP_ERROR_MESSAGE("YOUNGER_CP(LOCAL_top_cp, LOCAL_top_cp_on_stack) (completion)");
          } else {
            choiceptr aux_cp;
            aux_cp = DepFr_cons_cp(dep_fr);
            while (aux_cp != LOCAL_top_cp) {
              if (YOUNGER_CP(LOCAL_top_cp, aux_cp)) {
                OPTYAP_ERROR_MESSAGE("LOCAL_top_cp not in branch (completion)");
                break;
              }
              if (EQUAL_OR_YOUNGER_CP(LOCAL_top_cp_on_stack, aux_cp)) {
                OPTYAP_ERROR_MESSAGE("shared frozen segments in branch (completion)");
                break;
              }
              aux_cp = aux_cp->cp_b;
            }
          }
	}
#endif /* OPTYAP_ERRORS */
        /* rebind variables, update registers, consume answer and procceed */
#ifdef TABLING_ERRORS
        if (EQUAL_OR_YOUNGER_CP(B, DepFr_cons_cp(dep_fr)))
          TABLING_ERROR_MESSAGE("EQUAL_OR_YOUNGER_CP(B, DepFr_cons_cp(dep_fr)) (completion)");
        if (B->cp_tr > DepFr_cons_cp(dep_fr)->cp_tr)
          TABLING_ERROR_MESSAGE("B->cp_tr > DepFr_cons_cp(dep_fr)->cp_tr (completion)");
#endif /* TABLING_ERRORS */
        rebind_variables(DepFr_cons_cp(dep_fr)->cp_tr, B->cp_tr);
#ifdef TABLING_ERRORS
        if (TR != B->cp_tr) {
          if(! IsPairTerm((CELL)TrailTerm(TR - 1)))
            TABLING_ERROR_MESSAGE("! IsPairTerm((CELL)TrailTerm(TR - 1)) (completion)");
          if ((tr_fr_ptr) RepPair((CELL)TrailTerm(TR - 1)) != B->cp_tr)
            TABLING_ERROR_MESSAGE("RepPair((CELL)TrailTerm(TR - 1)) != B->cp_tr (completion)");
	}
#endif /* TABLING_ERRORS */
        B = DepFr_cons_cp(dep_fr);
        TR = TR_FZ;
        if (TR != B->cp_tr)
          TRAIL_LINK(B->cp_tr);
        consume_answer_and_procceed(dep_fr, ans_node);
      }
      UNLOCK(DepFr_lock(dep_fr));
#ifdef TIMESTAMP_CHECK
      DepFr_timestamp(dep_fr) = timestamp;
#endif /* TIMESTAMP_CHECK */
      dep_fr = DepFr_next(dep_fr);
    }
#ifdef LINEAR_TABLING
  consume_all:
    {
      INFO_LINEAR_TABLING("--------------------- goto consume_all ---------------\n");
      /* consume all */
      sg_fr_ptr sg_fr;
      sg_fr = GEN_CP(B)->cp_sg_fr; 
      INFO_LINEAR_TABLING("sgfr(%p)->state=%d\n",sg_fr,SgFr_state(sg_fr));
#ifdef LINEAR_TABLING_FOLLOWER
      if (SgFr_pioneer(sg_fr)==B)
	SgFr_state(sg_fr) = looping_follower_cons;
#else  /*!LINEAR_TABLING_FOLLOWER */
      SgFr_state(sg_fr) = looping_evaluating;
#endif /*LINEAR_TABLING_FOLLOWER */

      if (IS_BATCHED_GEN_CP(B)) {
        /* backtrack */
	remove_next(sg_fr);
        B = B->cp_b;
        SET_BB(PROTECT_FROZEN_B(B));
        goto fail;
      } else {	
        /* consume_answers*/	
#ifdef LINEAR_TABLING_DRS 
	if (SgFr_stop_loop_ans(sg_fr)!=NULL){
	  /* first time to load answers from looping answers */	
	  if(sg_fr==LOCAL_top_sg_fr_on_branch){
	    remove_branch(sg_fr);	     	   
	  }
	  restore_generator_node(SgFr_arity(sg_fr), COMPLETION);
	  SgFr_consuming_answers(sg_fr)=1; /*schedule for looping answers */
	  PREG = (yamop *) CPREG;
	  PREFETCH_OP(PREG);
	  CELL *subs_ptr;
	  subs_ptr = (CELL *) (GEN_CP(B) + 1);          
	  subs_ptr += SgFr_arity(GEN_CP(B)->cp_sg_fr);
	  SgFr_current_loop_ans(sg_fr)= SgFr_loop_ans(sg_fr);
#ifdef DUMMY_PRINT
      LOCAL_nr_consumed_answers++;      
#endif /*DUMMY_PRINT */
	  load_answer_trie(GET_CELL_VALUE(SgFr_current_loop_ans(sg_fr)), subs_ptr);
	  YENV = ENV;
	  GONext();
	}	
	
	if (SgFr_new_answer_trie(sg_fr)!=NULL){	  
	  /*first time to load answers from trie */
	  if (SgFr_new_answer_trie(sg_fr) == SgFr_answer_trie(sg_fr)) {
	    // yes answer --> procceed 
	    if(sg_fr==LOCAL_top_sg_fr_on_branch){
	      remove_next(sg_fr);
	      remove_branch(sg_fr);	     	   
	    }
	    if(HAS_NEW_ANSWERS(sg_fr)){
	      TAG_NEW_ANSWERS(LOCAL_top_sg_fr_on_branch);
	      UNTAG_NEW_ANSWERS(sg_fr);
	    }
	    remove_next(sg_fr);
	    pop_generator_node(SgFr_arity(sg_fr));
	    PREG = (yamop *) CPREG;
	    PREFETCH_OP(PREG);
	    YENV = ENV;
	    GONext();
	  }
  	  if(sg_fr!=LOCAL_top_sg_fr_on_branch)
	    add_branch(sg_fr);   
	  SgFr_consuming_answers(sg_fr)=2; /*schedule for trie answers */
	  restore_generator_node(SgFr_arity(sg_fr), COMPLETION);
	  PREG = (yamop *) CPREG;
	  PREFETCH_OP(PREG);
	  CELL *subs_ptr;
	  subs_ptr = (CELL *) (GEN_CP(B) + 1);          
	  subs_ptr += SgFr_arity(GEN_CP(B)->cp_sg_fr);
#ifdef DUMMY_PRINT
      LOCAL_nr_consumed_answers++;      
#endif /*DUMMY_PRINT */
	  load_answer_trie(SgFr_new_answer_trie(sg_fr), subs_ptr);
	  YENV = ENV;
	  GONext();
	}
	
	/* no answers to explore  */
	if(sg_fr==LOCAL_top_sg_fr_on_branch){
	  remove_branch(sg_fr);
	}
	if(HAS_NEW_ANSWERS(sg_fr)){
	  TAG_NEW_ANSWERS(LOCAL_top_sg_fr_on_branch);
	  UNTAG_NEW_ANSWERS(sg_fr);
	}
	remove_next(sg_fr);
	B = B->cp_b;
	SET_BB(PROTECT_FROZEN_B(B));
	goto fail;                  
      }

    }

#else  /*!LINEAR_TABLING_DRS */
       	ans_node = SgFr_first_answer(sg_fr);
        if (ans_node == NULL) {
          /* no answers --> fail */
	  remove_next(sg_fr);
          B = B->cp_b;
          SET_BB(PROTECT_FROZEN_B(B));
          goto fail;
        }
        remove_next(sg_fr);
        pop_generator_node(SgFr_arity(sg_fr));
        if (ans_node == SgFr_answer_trie(sg_fr)) {
          /* yes answer --> procceed */
          PREG = (yamop *) CPREG;
          PREFETCH_OP(PREG);
          YENV = ENV;
          GONext();
        } else  {
          /* answers -> get first answer */
#ifdef LIMIT_TABLING
	  SgFr_state(sg_fr)++;  /* complete --> complete_in_use */
	  remove_from_global_sg_fr_list(sg_fr);
	  TRAIL_FRAME(sg_fr);
#endif /* LIMIT_TABLING */
	  /* load answers from the trie */
#ifdef DUMMY_PRINT
	    store_loader_node(tab_ent, ans_node,1);
#else /*!DUMMY_PRINT */
	    store_loader_node(tab_ent, ans_node);
#endif /*DUMMY_PRINT */
	  PREG = (yamop *) CPREG;
	  PREFETCH_OP(PREG);
	  load_answer_trie(ans_node, YENV);
	  YENV = ENV;
	  GONext();
	}
      }
    }


#endif  /* LINEAR_TABLING_DRS */


#endif /* LINEAR_TABLING */



    /* no dependency frames with unconsumed answers found */
#ifdef YAPOR
    if (SCH_top_shared_cp(B)) {
      if (entry_owners > 1) {
        /* more owners when we start looking for dependency frames with unconsumed answers */
        if (YOUNGER_CP(B_FZ, B)) {
          suspend_branch();
          /* check for suspension frames to be resumed */
          while (YOUNGER_CP(OrFr_node(LOCAL_top_susp_or_fr), LOCAL_top_cp)) {
            or_fr_ptr susp_or_fr;
            susp_fr_ptr resume_fr;
            susp_or_fr = LOCAL_top_susp_or_fr;
            LOCK_OR_FRAME(susp_or_fr);
#ifdef TIMESTAMP_CHECK
            resume_fr = suspension_frame_to_resume(susp_or_fr, timestamp);
#else
            resume_fr = suspension_frame_to_resume(susp_or_fr);
#endif /* TIMESTAMP_CHECK */
	    if (resume_fr) {
              if (OrFr_suspensions(susp_or_fr) == NULL) {
                LOCAL_top_susp_or_fr = OrFr_nearest_suspnode(susp_or_fr);
                OrFr_nearest_suspnode(susp_or_fr) = susp_or_fr;
              }
              UNLOCK_OR_FRAME(susp_or_fr);
              rebind_variables(OrFr_node(susp_or_fr)->cp_tr, B->cp_tr);
              resume_suspension_frame(resume_fr, susp_or_fr);
              B = LOCAL_top_cp;
              SET_BB(B_FZ);
              TR = TR_FZ;
              TRAIL_LINK(B->cp_tr);
              goto completion;
            }
            LOCAL_top_susp_or_fr = OrFr_nearest_suspnode(susp_or_fr);
            OrFr_nearest_suspnode(susp_or_fr) = NULL;
            UNLOCK_OR_FRAME(susp_or_fr);
          }
        }
      } else {
        /* unique owner */
        if (frame_with_suspensions_not_collected(LOCAL_top_or_fr))
          collect_suspension_frames(LOCAL_top_or_fr);
        /* check for suspension frames to be resumed */
        while (EQUAL_OR_YOUNGER_CP(OrFr_node(LOCAL_top_susp_or_fr), LOCAL_top_cp)) {
          or_fr_ptr susp_or_fr;
          susp_fr_ptr resume_fr;
          susp_or_fr = LOCAL_top_susp_or_fr;
#ifdef TIMESTAMP_CHECK
          resume_fr = suspension_frame_to_resume(susp_or_fr, timestamp);
#else
          resume_fr = suspension_frame_to_resume(susp_or_fr);
#endif /* TIMESTAMP_CHECK */
          if (resume_fr) {
            if (OrFr_suspensions(susp_or_fr) == NULL) {
              LOCAL_top_susp_or_fr = OrFr_nearest_suspnode(susp_or_fr);
              OrFr_nearest_suspnode(susp_or_fr) = susp_or_fr;
            }
            if (YOUNGER_CP(B_FZ, B)) {
              suspend_branch();
            }
            rebind_variables(OrFr_node(susp_or_fr)->cp_tr, B->cp_tr);
            resume_suspension_frame(resume_fr, susp_or_fr);
            B = LOCAL_top_cp;
            SET_BB(B_FZ);
            TR = TR_FZ;
            TRAIL_LINK(B->cp_tr);
            goto completion;
          }
          LOCAL_top_susp_or_fr = OrFr_nearest_suspnode(susp_or_fr);
          OrFr_nearest_suspnode(susp_or_fr) = NULL;
        }
        /* complete all */
        public_completion();
      }
#ifdef TABLING_ERRORS
      if (TR != B->cp_tr) {
        if(! IsPairTerm((CELL)TrailTerm(TR - 1)))
          TABLING_ERROR_MESSAGE("! IsPairTerm((CELL)TrailTerm(TR - 1)) (completion)");
        if ((tr_fr_ptr) RepPair((CELL)TrailTerm(TR - 1)) != B->cp_tr)
          TABLING_ERROR_MESSAGE("RepPair((CELL)TrailTerm(TR - 1)) != B->cp_tr (completion)");
      }
#endif /* TABLING_ERRORS */
      if (B == DepFr_leader_cp(LOCAL_top_dep_fr)) {
        /*  B is a generator-consumer node  */
        /* never here if batched scheduling */
        ans_node_ptr ans_node;
#ifdef TABLING_ERRORS
	if (IS_BATCHED_GEN_CP(B))
	  TABLING_ERROR_MESSAGE("IS_BATCHED_GEN_CP(B) (completion)");
#endif /* TABLING_ERRORS */
        TR = B->cp_tr;
        SET_BB(B);
        LOCK_OR_FRAME(LOCAL_top_or_fr);
        LOCK(DepFr_lock(LOCAL_top_dep_fr));
        ans_node = DepFr_last_answer(LOCAL_top_dep_fr);
        if (TrNode_child(ans_node)) {
          /* unconsumed answer */
          UNLOCK_OR_FRAME(LOCAL_top_or_fr);
          ans_node = DepFr_last_answer(LOCAL_top_dep_fr) = TrNode_child(ans_node);
          UNLOCK(DepFr_lock(LOCAL_top_dep_fr));
          consume_answer_and_procceed(LOCAL_top_dep_fr, ans_node);
        }
        /* no unconsumed answers */
        UNLOCK(DepFr_lock(LOCAL_top_dep_fr));
        if (OrFr_owners(LOCAL_top_or_fr) > 1) {
          /* more owners -> move up one node */
          LOCAL_top_cp_on_stack = OrFr_node(OrFr_next_on_stack(LOCAL_top_or_fr));
          BITMAP_delete(OrFr_members(LOCAL_top_or_fr), worker_id);
          OrFr_owners(LOCAL_top_or_fr)--;
          LOCAL_top_dep_fr = DepFr_next(LOCAL_top_dep_fr);
          UNLOCK_OR_FRAME(LOCAL_top_or_fr);
          if (LOCAL_top_sg_fr && LOCAL_top_cp == SgFr_gen_cp(LOCAL_top_sg_fr)) {
            LOCAL_top_sg_fr = SgFr_next(LOCAL_top_sg_fr);
          }
          SCH_update_local_or_tops();
          CUT_reset_prune_request();
          adjust_freeze_registers();
          goto shared_fail;
        } else {
          /* free top dependency frame --> get work */
          OrFr_alternative(LOCAL_top_or_fr) = NULL;
          UNLOCK_OR_FRAME(LOCAL_top_or_fr);
          dep_fr = DepFr_next(LOCAL_top_dep_fr);
          FREE_DEPENDENCY_FRAME(LOCAL_top_dep_fr);
          LOCAL_top_dep_fr = dep_fr;
          adjust_freeze_registers();
          SCHEDULER_GET_WORK();
        }
      }
      /* goto getwork */
      PREG = B->cp_ap;
      PREFETCH_OP(PREG);
      TR = B->cp_tr;
      SET_BB(B);
      GONext();
    } else
#endif /* YAPOR */
complete_all:
    {
       INFO_LINEAR_TABLING("--------------------- goto complete_all ---------------\n");
      /* complete all */
      sg_fr_ptr sg_fr;

#ifdef DETERMINISTIC_TABLING
      if (IS_DET_GEN_CP(B))
	sg_fr = DET_GEN_CP(B)->cp_sg_fr;
      else	 
#endif /* DETERMINISTIC_TABLING */
      sg_fr = GEN_CP(B)->cp_sg_fr;
      private_completion(sg_fr);
 
      if (IS_BATCHED_GEN_CP(B)) {
        /* backtrack */
        B = B->cp_b;
	remove_next(sg_fr);
        SET_BB(PROTECT_FROZEN_B(B));
        goto fail;
      } else {
        /* subgoal completed */
	ans_node = SgFr_first_answer(sg_fr);
        if (ans_node == NULL) {
          /* no answers --> fail */
	  remove_next(sg_fr);
          B = B->cp_b;
          SET_BB(PROTECT_FROZEN_B(B));
          goto fail;
        }
#ifdef TABLING_ERRORS
        if (TR != B->cp_tr) {
          if(! IsPairTerm((CELL)TrailTerm(TR - 1)))
            TABLING_ERROR_MESSAGE("! IsPairTerm((CELL)TrailTerm(TR - 1)) (completion)");
          if ((tr_fr_ptr) RepPair((CELL)TrailTerm(TR - 1)) != B->cp_tr)
            TABLING_ERROR_MESSAGE("RepPair((CELL)TrailTerm(TR - 1)) != B->cp_tr (completion)");
        }
#endif /* TABLING_ERRORS */
        remove_next(sg_fr);
        pop_generator_node(SgFr_arity(sg_fr));
        if (ans_node == SgFr_answer_trie(sg_fr)) {
          /* yes answer --> procceed */
          PREG = (yamop *) CPREG;
          PREFETCH_OP(PREG);
          YENV = ENV;
          GONext();
        } else  {
          /* answers -> get first answer */
	  tab_ent_ptr tab_ent = SgFr_tab_ent(sg_fr);
#ifdef LIMIT_TABLING
	  SgFr_state(sg_fr)++;  /* complete --> complete_in_use */
	  remove_from_global_sg_fr_list(sg_fr);
	  TRAIL_FRAME(sg_fr);
#endif /* LIMIT_TABLING */
	  if (IsMode_LoadAnswers(TabEnt_mode(tab_ent))) {
            /* load answers from the trie */
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
	    LOCK(SgFr_lock(sg_fr));
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
    }
    END_PREFETCH()
  ENDBOp();
