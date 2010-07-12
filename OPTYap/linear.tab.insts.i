
/* ------------------------------ **
**      Tabling instructions      **
** ------------------------------ */  

PBOp(table_try_answer, Otapl)
return(0);
ENDPBOp();


  PBOp(table_load_answer, Otapl)
    INFO_LINEAR_TABLING("-------------------------table_load_answer ---------------");
    CELL *subs_ptr;
    ans_node_ptr ans_node;
    subs_ptr = (CELL *) (LOAD_CP(B) + 1);
    ans_node = TrNode_child(LOAD_CP(B)->cp_last_answer);
    if (ans_node != NULL) {
      restore_loader_node(ans_node);
    } else {
      /*no more answers to consume */
      B = B->cp_b;
      goto fail; 
    } 
    PREG = (yamop *) CPREG;
    PREFETCH_OP(PREG);
    load_answer_trie(ans_node, subs_ptr);
    YENV = ENV;
    GONext();
  ENDPBOp();


  PBOp(table_try_single, Otapl)
    INFO_LINEAR_TABLING("-------------------------table_try_single ---------------");
    table_try_begin();
    if (SgFr_state(sg_fr) == ready) {
      /* subgoal new */
      table_try_single_with_ready(sg_fr,PREG->u.Otapl.d);
      GONext();
    } else if (SgFr_state(sg_fr) == looping_ready) {
      table_try_with_looping_ready(sg_fr);
      GONext();
    } else if (SgFr_state(sg_fr) == evaluating || 
               SgFr_state(sg_fr) == looping_evaluating){ 
      propagate_dependencies(sg_fr);
      fail_or_yes_answer(tab_ent,sg_fr);
      consume_all_answers_on_trie(tab_ent,ans_node,sg_fr);
      GONext();
    } else {
      /* subgoal completed */
      fail_or_yes_answer(tab_ent,sg_fr);
      table_try_with_completed(sg_fr,ans_node,tab_ent);
      GONext();
    }
  ENDPBOp();


  PBOp(table_try_me, Otapl)
    INFO_LINEAR_TABLING("-------------------------table_try_me ---------------");
    table_try_begin();
    if (SgFr_state(sg_fr) == ready) {
      /* subgoal new */
      table_try_with_ready(sg_fr,NEXTOP(PREG,Otapl),PREG->u.Otapl.d);
      GONext();
    } else if (SgFr_state(sg_fr) == looping_ready) {
      table_try_with_looping_ready(sg_fr);
      GONext();
    } else if (SgFr_state(sg_fr) == evaluating) {
      propagate_dependencies(sg_fr);
      DRE_table_try_with_evaluating(sg_fr);
      fail_or_yes_answer(tab_ent,sg_fr);
      consume_all_answers_on_trie(tab_ent,ans_node,sg_fr);
      GONext();
    } else if (SgFr_state(sg_fr) == looping_evaluating) {
      propagate_dependencies(sg_fr);
      DRE_table_try_with_looping_evaluating(sg_fr);
      fail_or_yes_answer(tab_ent,sg_fr);
      consume_all_answers_on_trie(tab_ent,ans_node,sg_fr);
      GONext();
    } else {
      /* subgoal completed */
      fail_or_yes_answer(tab_ent,sg_fr);
      table_try_with_completed(sg_fr,ans_node,tab_ent);
      GONext();
    }
  ENDPBOp();


  PBOp(table_try, Otapl)
    INFO_LINEAR_TABLING("-------------------------table_try ---------------");
    table_try_begin();
    if (SgFr_state(sg_fr) == ready) {
      /* subgoal new */
      INFO_LINEAR_TABLING(" outside  B=%p",B);
      table_try_with_ready(sg_fr,PREG->u.Otapl.d, NEXTOP(PREG,Otapl));
      GONext();
    } else if (SgFr_state(sg_fr) == looping_ready) {
      table_try_with_looping_ready(sg_fr);
      GONext();
    } else if (SgFr_state(sg_fr) == evaluating) {
      propagate_dependencies(sg_fr);
      DRE_table_try_with_evaluating(sg_fr);
      fail_or_yes_answer(tab_ent,sg_fr);
      consume_all_answers_on_trie(tab_ent,ans_node,sg_fr);
      GONext();
    } else if (SgFr_state(sg_fr) == looping_evaluating) {
      propagate_dependencies(sg_fr);
      DRE_table_try_with_looping_evaluating(sg_fr);
      fail_or_yes_answer(tab_ent,sg_fr);
      consume_all_answers_on_trie(tab_ent,ans_node,sg_fr);
      GONext();
    } else {
      /* subgoal completed */
      fail_or_yes_answer(tab_ent,sg_fr);
      table_try_with_completed(sg_fr,ans_node,tab_ent);
      GONext();
    }
  ENDPBOp();




  Op(table_retry_me, Otapl)
    INFO_LINEAR_TABLING("-------------------------table_retry_me ---------------\n");
    table_retry(NEXTOP(PREG,Otapl),PREG->u.Otapl.d);
    GONext();
  ENDOp();


  Op(table_retry, Otapl)
    INFO_LINEAR_TABLING("-------------------------table_retry ---------------\n");
    table_retry(PREG->u.Otapl.d,NEXTOP(PREG,Otapl));
    GONext();
  ENDOp();

  Op(table_trust_me, Otapl)
    INFO_LINEAR_TABLING("-------------------------table_trust_me ---------------\n");
    table_trust(NEXTOP(PREG,Otapl));
    GONext();
  ENDOp();

  Op(table_trust, Otapl)
    INFO_LINEAR_TABLING("-------------------------table_trust ---------------\n");
    table_trust(PREG->u.Otapl.d);
    GONext();
  ENDOp();

  BOp(table_answer_resolution, Otapl)

#ifdef LINEAR_TABLING_DRS
  answer_resolution:
  {
     sg_fr_ptr sg_fr = GEN_CP(B)->cp_sg_fr; 
     INFO_LINEAR_TABLING("answer resolution sg_fr=%p",sg_fr);
     if (SgFr_stop_loop_ans(sg_fr) && SgFr_current_loop_ans(sg_fr)!=SgFr_stop_loop_ans(sg_fr)){
       if (SgFr_current_loop_ans(sg_fr)==NULL){
	 SgFr_current_loop_ans(sg_fr)= SgFr_loop_ans(sg_fr);
	 /* first time to load answers from looping answers */	
	 if(sg_fr==LOCAL_top_sg_fr_on_branch){
	   remove_branch(sg_fr);	     	   
	 }
       }else{
	 SgFr_current_loop_ans(sg_fr)++;
	 if (IS_JUMP_CELL(SgFr_current_loop_ans(sg_fr)))
	   ANS_JUMP_NEXT_CELL(SgFr_current_loop_ans(sg_fr));
       }	  
       restore_generator_node(SgFr_arity(sg_fr), ANSWER_RESOLUTION);
       SgFr_consuming_answers(sg_fr)=1; /*schedule for looping answers*/
       PREG = (yamop *) CPREG;
       PREFETCH_OP(PREG);
       CELL *subs_ptr;
       subs_ptr = (CELL *) (GEN_CP(B) + 1);          
       subs_ptr += SgFr_arity(GEN_CP(B)->cp_sg_fr);
#ifdef DUMMY_PRINT
       LOCAL_nr_consumed_answers++;      
#endif /*DUMMY_PRINT */
       INFO_LINEAR_TABLING("drs- consume loop answer %p",GET_CELL_VALUE(SgFr_current_loop_ans(sg_fr)));
       load_answer_trie(GET_CELL_VALUE(SgFr_current_loop_ans(sg_fr)), subs_ptr);
       YENV = ENV;
       GONext();
     }

     if (SgFr_consuming_answers(sg_fr)==2)
       SgFr_new_answer_trie(sg_fr)=TrNode_child(SgFr_new_answer_trie(sg_fr));
     else{
       SgFr_consuming_answers(sg_fr)=2; /*schedule for trie answers*/
       if(sg_fr!=LOCAL_top_sg_fr_on_branch)
	 add_branch(sg_fr);   
     }
       
     if (SgFr_new_answer_trie(sg_fr)!=NULL){ 
       /*first time to load answers from trie */
       if (SgFr_new_answer_trie(sg_fr) == SgFr_answer_trie(sg_fr)) {	 
	 // yes answer --> procceed 
	 if(sg_fr==LOCAL_top_sg_fr_on_branch) {
	   remove_next(sg_fr);
	   remove_branch(sg_fr);	     	   
	 }
	 if(HAS_NEW_ANSWERS(sg_fr)) {
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
       restore_generator_node(SgFr_arity(sg_fr), ANSWER_RESOLUTION);
       PREG = (yamop *) CPREG;
       PREFETCH_OP(PREG);
       CELL *subs_ptr;
       subs_ptr = (CELL *) (GEN_CP(B) + 1);          
       subs_ptr += SgFr_arity(GEN_CP(B)->cp_sg_fr);
#ifdef DUMMY_PRINT
       LOCAL_nr_consumed_answers++;      
#endif /*DUMMY_PRINT */
       INFO_LINEAR_TABLING("drs- consume trie answer %p",SgFr_new_answer_trie(sg_fr));
       load_answer_trie(SgFr_new_answer_trie(sg_fr), subs_ptr);
       YENV = ENV;
       GONext();
     }

     /* no answers to explore  */

     INFO_LINEAR_TABLING("drs- no answers to explore");
     SgFr_consuming_answers(sg_fr)=0; 
     SgFr_current_loop_ans(sg_fr)= NULL;
     
     if(sg_fr==LOCAL_top_sg_fr_on_branch){
       remove_branch(sg_fr);
       remove_next(sg_fr);
     }
     if(HAS_NEW_ANSWERS(sg_fr)){
       TAG_NEW_ANSWERS(LOCAL_top_sg_fr_on_branch);
       UNTAG_NEW_ANSWERS(sg_fr);
     }

     B = B->cp_b;
     SET_BB(PROTECT_FROZEN_B(B));
     goto fail;               
}
#endif /* LINEAR_TABLING_DRS */


ENDBOp();
