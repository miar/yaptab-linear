#ifndef LINEAR_TAB_MACROS_H
#define LINEAR_TAB_MACROS_H

/* ------------------------------------------ **
**      yaptab suspend compatibility          **
** ------------------------------------------ */

//#define find_leader_node(LEADER_CP, DEP_ON_STACK)


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

#define GET_SGFR_DFN(SG_FR)                       (SgFr_dfn(SG_FR)>>3)
#define SET_SGFR_DFN(SG_FR,NR)                    (SgFr_dfn(SG_FR)=(NR<<3))


/*--------------------------------------**
**  definition of strategy:             **    
**        0- batched sheduling          **
**        1- local scheduling           **
**--------------------------------------*/

#define IS_LOCAL_SF(SG_FR)                       (SgFr_dfn(SG_FR) & 0x4)
#define IS_BATCHED_SF(SG_FR)                     (!(IS_LOCAL_SF(SG_FR)))

#define TAG_AS_LOCAL_SF(SG_FR)                   (SgFr_dfn(SG_FR)=(SgFr_dfn(SG_FR)| 0x4))

/* -------------------- **
**      Prototypes      **
** -------------------- */

/*------------------------------------------------LINEAR TABLING DRA------------------------------*/
#ifdef LINEAR_TABLING_DRA
#define SgFr_init_dra_fields(SG_FR)                         \
        SgFr_current_alt(SG_FR) = NULL;                     

#else
#define SgFr_init_dra_fields(SG_FR)


#endif /*LINEAR_TABLING_DRA */



/*------------------------------------------------LINEAR TABLING DRE------------------------------*/
#ifdef LINEAR_TABLING_DRE

#define add_next_follower(SG_FR)                                   \
{                                                                  \
        sg_fr_ptr sgfr_aux=NULL;                                   \
        new_subgoal_frame(sgfr_aux, PREG);                         \
        DRS_add_next_follower_fields(sgfr_aux);                    \
        SgFr_stop_loop_alt(sgfr_aux) = NULL;                       \
	SgFr_current_loop_alt(sgfr_aux) = NULL;                    \
	SgFr_current_batched_answer(sgfr_aux)=NULL;		   \
        SgFr_next_alt(sgfr_aux) = NULL; 			   \
	SgFr_pioneer(sgfr_aux)=NULL;                               \
	SgFr_pioneer_frame(sgfr_aux)=SG_FR; /*support for cuts*/   \
        SgFr_gen_cp(sgfr_aux)=SgFr_gen_cp(SG_FR);                  \
        SgFr_next(sgfr_aux) = LOCAL_top_sg_fr;   		   \
        LOCAL_top_sg_fr = sgfr_aux;				   \
   }

#define SgFr_init_follower_fields(SG_FR)                         \
{                                        			 \
        SgFr_next_alt(SG_FR) = NULL; 			         \
        SgFr_pioneer(SG_FR) = NULL;                              \
        SgFr_pioneer_frame(SG_FR) = NULL;                        \
}

#else
#define SgFr_init_follower_fields(SG_FR)



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

#define add_answer(SG_FR,ans)						                                \
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


#define SgFr_allocate_drs_looping_structure(SG_FR)    \
       ALLOC_ANSWERS_BUCKET(SgFr_loop_ans(SG_FR)); 

#define free_drs_answers(SG_FR)                  \
{		                                 \
    if (SgFr_current_loop_ans(SG_FR)!=NULL){     \
       struct answer_trie_node **next=NULL;      \
       struct answer_trie_node **curr=NULL;      \
       curr=SgFr_loop_ans(SG_FR);                \
       next= curr+MAX_LOOP_ANS_BUCKET;           \
       if (*next!=1){                            \
         ANS_JUMP_NEXT_CELL(next);               \
         while(next!=SgFr_loop_ans(SG_FR)){      \
	   FREE_ANSWERS_BUCKET(curr);            \
	   curr=next;                            \
	   next= curr+MAX_LOOP_ANS_BUCKET;       \
	   if((*next)==1)                        \
	     break;                              \
  	   ANS_JUMP_NEXT_CELL(next);             \
         }                                       \
       }                                         \
       FREE_ANSWERS_BUCKET(curr);                \
     }                                           \
    SgFr_stop_loop_ans(SG_FR) = NULL;	         \
    SgFr_current_loop_ans(SG_FR) = NULL;	 \
    SgFr_consuming_answers(SG_FR)=0;	         \
    SgFr_new_answer_trie(SG_FR) = NULL;  	 \
    SgFr_loop_ans(SG_FR)=NULL;   		 \
 }

#define SgFr_init_drs_fields(SG_FR)                                         \
{   									    \
        SgFr_consuming_answers(SG_FR)=0;	                            \
	SgFr_new_answer_trie(SG_FR) = NULL;                                 \
        SgFr_stop_loop_ans(SG_FR) = NULL;                                   \
        SgFr_current_loop_ans(SG_FR) = NULL;                                \
        SgFr_cp(SG_FR)=NULL;                                                \
}



#else
#define DRS_add_next_follower_fields(sgfr_aux)
#define free_drs_answers(sg_fr)
#define SgFr_allocate_drs_looping_structure(SG_FR)
#define SgFr_init_drs_fields(SG_FR)
#endif /*LINEAR_TABLING_DRS */

/*------------------------------------------------LINEAR TABLING------------------------------*/


#define fail_or_yes_answer(tab_ent,sg_fr)		      \
      ans_node_ptr ans_node;                                  \
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
      }							      \


#define add_next(SG_FR){                                           \
       if(SG_FR!=LOCAL_top_sg_fr){                                 \
	 SgFr_next(SG_FR) = LOCAL_top_sg_fr;   		           \
         LOCAL_top_sg_fr = SG_FR;				   \
       }                                                           \
}



#define remove_next(SG_FR){                                        \
     if(B ==SgFr_gen_cp(LOCAL_top_sg_fr)){	                   \
       LOCAL_top_sg_fr= SgFr_next(LOCAL_top_sg_fr);		   \
     }else{							   \
        printf("nao pode acontecer\n"); 			   \
     }								   \
}



#define add_max_scc(SG_FR){                                        \
     if(SG_FR!=LOCAL_max_scc){				           \
         SgFr_next_on_scc(SG_FR)=LOCAL_max_scc;                    \
         LOCAL_max_scc = SG_FR;                                    \
     }                                                             \
}


#define add_branch(SG_FR){                                               \
       if(SG_FR!=LOCAL_top_sg_fr_on_branch){                             \
          SgFr_next_on_branch(SG_FR) = LOCAL_top_sg_fr_on_branch;        \
          LOCAL_top_sg_fr_on_branch =SG_FR;                              \
       }                                                                 \
}

#define remove_branch(SG_FR){	   				         \
  if (SG_FR==LOCAL_top_sg_fr_on_branch){                                 \
      LOCAL_top_sg_fr_on_branch = SgFr_next_on_branch(SG_FR);		 \
  }                                                                      \
}




#define free_alternatives(sg_fr){                 \
  if (SgFr_current_loop_alt(sg_fr)!=NULL){        \
    yamop **next=NULL;                            \
    yamop **curr=NULL;                            \
    curr=SgFr_loop_alts(sg_fr);                   \
    next= curr+MAX_LOOP_ALT_BUCKET;               \
    if (*next!=1){                                \
      ALT_JUMP_NEXT_CELL(next);                   \
      while(next!=SgFr_loop_alts(sg_fr)){         \
	FREE_ALTERNATIVES_BUCKET(curr);           \
	curr=next;                                \
	next= curr+MAX_LOOP_ALT_BUCKET;           \
	if((*next)==1)                            \
	  break;                                  \
	ALT_JUMP_NEXT_CELL(next);                 \
      }                                           \
    }                                             \
    FREE_ALTERNATIVES_BUCKET(curr);               \
   }                                              \
   SgFr_stop_loop_alt(sg_fr) = NULL;              \
   SgFr_current_loop_alt(sg_fr) = NULL;           \
   SgFr_init_dra_fields(sg_fr);			  \
   SgFr_loop_alts(sg_fr)=NULL;                    \
}


#define SgFr_init_linear_tabling_fields(SG_FR,TAB_ENT){     		    \
        SET_SGFR_DFN(SG_FR,LOCAL_dfn++);			            \
	TAG_AS_LEADER(SG_FR);                                               \
	if (IsMode_Local(TabEnt_mode(TAB_ENT))){			    \
	  TAG_AS_LOCAL_SF(SG_FR);                                           \
        }                                                                   \
        SgFr_stop_loop_alt(SG_FR) = NULL;                                   \
        SgFr_first_loop_alt(SG_FR) = NULL;                                  \
	SgFr_current_loop_alt(SG_FR) = NULL;                                \
        SgFr_current_batched_answer(SG_FR)=NULL;			    \
	SgFr_init_follower_fields(SG_FR);                                   \
    	SgFr_init_drs_fields(SG_FR);                                        \
	SgFr_init_dra_fields(SG_FR);                                        \
}


#endif /*LINEAR_TAB_MACROS_H */

