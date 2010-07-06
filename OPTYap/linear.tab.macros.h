/* -------------------- **
**      macros          **
** -------------------- */
#define ALT_TAG_AS_JUMP_CELL(PTR,NEXT_NODE)       ((*PTR)= (yamop *)((unsigned long int)NEXT_NODE | 0x1))
#define ALT_JUMP_NEXT_CELL(PTR)                   (PTR=(yamop*)(((unsigned long int)(*PTR)) & 0xFFFFFFFE))
#define IS_JUMP_CELL(PTR)                         (((unsigned long int)(*PTR)) & 0x1)

#define ANS_TAG_AS_JUMP_CELL(PTR,NEXT_NODE)       ((*PTR)= (struct answer_trie_node *)((unsigned long int)NEXT_NODE | 0x1))
#define ANS_JUMP_NEXT_CELL(PTR)                   (PTR=(struct answer_trie_node *)(((unsigned long int)(*PTR)) & 0xFFFFFFFE))
#define GET_CELL_VALUE(PTR)                       (*(PTR))

#define SET_CELL_VALUE(PTR,VALUE)                 (*(PTR)=VALUE)
#define TAG_NEW_ANSWERS(SG_FR)                    (SgFr_dfn(SG_FR)=(SgFr_dfn(SG_FR)| 0x1))
#define TAG_AS_LEADER(SG_FR)                      (SgFr_dfn(SG_FR)=(SgFr_dfn(SG_FR)| 0x2))

#define UNTAG_NEW_ANSWERS(SG_FR)                  (SgFr_dfn(SG_FR)=(SgFr_dfn(SG_FR) & ~(0x1)))
#define TAG_AS_NO_LEADER(SG_FR)                   (SgFr_dfn(SG_FR)=(SgFr_dfn(SG_FR) & ~(0x2)))
#define HAS_NEW_ANSWERS(SG_FR)                    (SgFr_dfn(SG_FR) & 0x1)

#define IS_LEADER(SG_FR)                          (SgFr_dfn(SG_FR) & 0x2)
#define GET_SGFR_DFN(SG_FR)                       (SgFr_dfn(SG_FR)>>2)
#define SET_SGFR_DFN(SG_FR,NR)                    (SgFr_dfn(SG_FR)=(NR<<2))

/* -------------------- **
**      Prototypes      **
** -------------------- */
STD_PROTO(static inline void propagate_dependencies, (sg_fr_ptr));

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

#define DUMMY_LOCAL_nr_followers_inc()                  (LOCAL_nr_followers++)
#define DUMMY_LOCAL_nr_generators_inc()                 (LOCAL_nr_generators++)
#define DUMMY_LOCAL_nr_consumers_inc()                  (LOCAL_nr_consumers++)
#define DUMMY_LOCAL_nr_propagate_depen_cicles_inc()        (LOCAL_nr_propagate_depen_cicles++)
#define	DUMMY_LOCAL_nr_is_leader_and_has_new_answers_inc() (LOCAL_nr_is_leader_and_has_new_answers++)

#else  /*! DUMMY_PRINT */

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

#define DUMMY_LOCAL_nr_followers_inc()
#define DUMMY_LOCAL_nr_generators_inc()
#define DUMMY_LOCAL_nr_consumers_inc()
#define	DUMMY_LOCAL_nr_is_leader_and_has_new_answers_inc()
#define DUMMY_LOCAL_nr_propagate_depen_cicles_inc()
#endif /*DUMMY_PRINT */

/*------------------------------------------------LINEAR TABLING DRA------------------------------*/
#ifdef LINEAR_TABLING_DRA




#endif /*LINEAR_TABLING_DRA */





/*------------------------------------------------LINEAR TABLING DRE------------------------------*/
#ifdef LINEAR_TABLING_DRE


#define add_next_follower(SG_FR){                                  \
        sg_fr_ptr sgfr_aux=NULL;                                   \
        new_subgoal_frame(sgfr_aux, PREG);                         \
        DRS_add_next_follower_fields(sgfr_aux);                    \
        SgFr_stop_loop_alt(sgfr_aux) = NULL;                       \
	SgFr_current_loop_alt(sgfr_aux) = NULL;                    \
        SgFr_next_alt(sgfr_aux) = NULL; 			   \
	SgFr_pioneer(sgfr_aux)=NULL;                               \
        SgFr_gen_cp(sgfr_aux)=SgFr_gen_cp(SG_FR);                  \
        SgFr_next(sgfr_aux) = LOCAL_top_sg_fr;   		   \
        LOCAL_top_sg_fr = sgfr_aux;				   \
   }


#endif  /*LINEAR_TABLING_DRE */


/*------------------------------------------------LINEAR TABLING DRS------------------------------*/
#ifdef LINEAR_TABLING_DRS
#define DRS_add_next_follower_fields(sgfr_aux)                      \
{								    \
        SgFr_cp(sgfr_aux) =NULL;                                    \
        SgFr_consuming_answers(sgfr_aux)=0;                         \
        SgFr_new_answer_trie(sgfr_aux) = NULL;                      \				 
	SgFr_stop_loop_ans(sgfr_aux) = NULL;                        \
        SgFr_current_loop_ans(sgfr_aux) = NULL;                     \
}

#define add_answer(SG_FR,ans)						                        \
{                                                                                                       \
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
         }                                                                                              \
}
#else
#define DRS_add_next_follower_fields(sgfr_aux)

#endif /*LINEAR_TABLING_DRS */




/*------------------------------------------------LINEAR TABLING------------------------------*/

#define add_next(SG_FR)                                            \
{                                                                  \
       if(SG_FR!=LOCAL_top_sg_fr){                                 \
	 SgFr_next(SG_FR) = LOCAL_top_sg_fr;   		           \
         LOCAL_top_sg_fr = SG_FR;				   \
       }                                                           \
}



#define remove_next(SG_FR)                                         \
{                                                                  \
     if(B !=SgFr_gen_cp(LOCAL_top_sg_fr)){	                   \
        printf("nao devia acontecer\n"); 			   \
     }else{							   \
       LOCAL_top_sg_fr= SgFr_next(LOCAL_top_sg_fr);		   \
     }								   \
}



#define add_max_scc(SG_FR)                                 \
{                                                          \
     SgFr_next_on_scc(SG_FR)=LOCAL_max_scc;                \
     LOCAL_max_scc = SG_FR;                                \
}


#define add_branch(SG_FR)                                                             \
{                                                                                     \
    SgFr_next_on_branch(SG_FR) = LOCAL_top_sg_fr_on_branch;                           \
    LOCAL_top_sg_fr_on_branch =SG_FR;                                                 \
}

#define remove_branch(SG_FR)                                                         \
{                                                                                    \
      LOCAL_top_sg_fr_on_branch = SgFr_next_on_branch(SG_FR);		             \
}



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


					
static inline void propagate_dependencies(sg_fr_ptr SG_FR){
  sg_fr_ptr sf_aux=LOCAL_top_sg_fr_on_branch;                                        
  int dfn=GET_SGFR_DFN(SG_FR);                                                       
  INFO_LINEAR_TABLING("propagate dependencies upto to sg_fr=%p",SG_FR);
  while(sf_aux && (GET_SGFR_DFN(sf_aux) >dfn 
#ifdef LINEAR_TABLING_DRS
       ||SgFr_consuming_answers(sf_aux)==2)
#endif /*LINEAR_TABLING_DRS */
     ){ 
       DUMMY_LOCAL_nr_propagate_depen_cicles_inc();                                     
       INFO_LINEAR_TABLING("sgfr_aux=%p",sf_aux);                                       
       TAG_AS_NO_LEADER(sf_aux);
#ifdef LINEAR_TABLING_DRS
   if(SgFr_consuming_answers(sf_aux)==2){
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
   if(SgFr_consuming_answers(sf_aux)==2){
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
}							                             

