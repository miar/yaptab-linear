
/* ------------------------------ **
**      Tabling instructions      **
** ------------------------------ */  


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
  DRS_answer_resolution:
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
  answer_resolution:
    {
      INFO_LINEAR_TABLING("--------------------- goto consume_all ---------------\n");
      /* consume all */
      sg_fr_ptr sg_fr;
      sg_fr = GEN_CP(B)->cp_sg_fr; 
#if defined(DUMMY_PRINT) && defined(LINEAR_TABLING_DRE)
      int type_of_node=0; /*0-follower   1- drs generator */
      if (SgFr_pioneer(sg_fr)==B)
	type_of_node=1;
#endif /*DUMMY_PRINT && LINEAR_TABLING_DRE*/
      INFO_LINEAR_TABLING("sgfr(%p)->state=%d\n",sg_fr,SgFr_state(sg_fr));
#ifdef LINEAR_TABLING_BATCHED
      if (IS_BATCHED_GEN_CP(B)) {
        /* backtrack */
	remove_next(sg_fr);
        B = B->cp_b;
        SET_BB(PROTECT_FROZEN_B(B));
        goto fail;
      } else
#endif /*LINEAR_TABLING_BATCHED */
	{	
	  /* consume_answers*/	
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
#ifdef DUMMY_PRINT
#ifdef LINEAR_TABLING_DRE
	    store_loader_node(tab_ent, ans_node,type_of_node);
#else
	    store_loader_node(tab_ent, ans_node,1);
#endif /*LINEAR_TABLING_DRE*/
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

ENDBOp();



BOp(table_completion, Otapl)
   INFO_LINEAR_TABLING("-------------------------table_completion ---------------");
   sg_fr_ptr sg_fr = GEN_CP(B)->cp_sg_fr;       
   INFO_LINEAR_TABLING("sg_fr=%p",sg_fr);
#ifdef LINEAR_TABLING_DRE
   if (SgFr_next_alt(sg_fr)!=NULL){
      PREG = SgFr_next_alt(sg_fr);
      INFO_LINEAR_TABLING("next alt != null");
      PREFETCH_OP(PREG);
      GONext();    
   }
  /* check for follower node and state still evaluating */
  if (SgFr_state(sg_fr)==evaluating && SgFr_pioneer(sg_fr)!=B)
    goto answer_resolution;
#endif /*LINEAR_TABLING_DRE*/

#ifdef LINEAR_TABLING_DRA
    if (SgFr_current_loop_alt(sg_fr) != NULL) 
#endif /*LINEAR_TABLING_DRA*/
      {
	/*----------determine which alternative to consume ----------------------------*/
	yamop **next_loop_alt = SgFr_current_loop_alt(sg_fr) + 1;
	if (SgFr_state(sg_fr) == evaluating){
	  /*first time on table completion */	   
	  SgFr_state(sg_fr) = looping_evaluating;  
	  if (!IS_LEADER(sg_fr)) 
	    remove_branch(sg_fr);
	  ALT_TAG_AS_JUMP_CELL(next_loop_alt,sg_fr->loop_alts);
	  next_loop_alt = SgFr_stop_loop_alt(sg_fr) = sg_fr->loop_alts;
	  SgFr_first_loop_alt(sg_fr)=SgFr_stop_loop_alt(sg_fr);
	} else { 
	  /*get next alternative  */
	  if (IS_JUMP_CELL(next_loop_alt)) 
	    ALT_JUMP_NEXT_CELL(next_loop_alt);	  
	}
	/*----------launch alternative (if any) ----------------------------*/
	if (IS_LEADER(sg_fr) && HAS_NEW_ANSWERS(sg_fr) ) {  
	  INFO_LINEAR_TABLING("is_leader and has new answers");
	  DUMMY_LOCAL_nr_is_leader_and_has_new_answers_inc();	
#ifdef LINEAR_TABLING_DRE
	  if( SgFr_pioneer(sg_fr)==B)
#endif /*LINEAR_TABLING_DRE */
	  {
#ifdef LINEAR_TABLING_DSLA
	      while(LOCAL_max_scc !=sg_fr){                        
		SgFr_state(LOCAL_max_scc) = looping_ready;
		INFO_LINEAR_TABLING("LOCAL_MAX_SCC=%p",LOCAL_max_scc);	
		LOCAL_max_scc  = SgFr_next_on_scc(LOCAL_max_scc);
	      }
	  } 
	  SgFr_stop_loop_alt(sg_fr) = SgFr_current_loop_alt(sg_fr) = next_loop_alt;
	  UNTAG_NEW_ANSWERS(sg_fr);
#else  /*!LINEAR_TABLING_DSLA --- TO REMOVE*/
	      if(next_loop_alt == SgFr_first_loop_alt(sg_fr)){
	         while(LOCAL_max_scc !=sg_fr){                        
		   SgFr_state(LOCAL_max_scc) = looping_ready;
		   INFO_LINEAR_TABLING("LOCAL_MAX_SCC=%p",LOCAL_max_scc);	
		   LOCAL_max_scc  = SgFr_next_on_scc(LOCAL_max_scc);
		 }
		 UNTAG_NEW_ANSWERS(sg_fr);
	      }   	      
	    } 
	    SgFr_current_loop_alt(sg_fr) = next_loop_alt;
#endif /*LINEAR_TABLING_DSLA*/
	  table_completion_launch_next_loop_alt(sg_fr,next_loop_alt);	  
	  GONext();          
      }

      if (next_loop_alt != SgFr_stop_loop_alt(sg_fr) ) {  
	  INFO_LINEAR_TABLING("next loop alt!= stop loop alt");	  
	  table_completion_launch_next_loop_alt(sg_fr,next_loop_alt);	  
	  GONext();     
      }
   }
   /*---------- no more alternatives to consume  ----------------------------*/
	

#ifdef LINEAR_TABLING_DRE
    if (SgFr_pioneer(sg_fr)!=B){
      if (!IS_LEADER(sg_fr)){
	if (HAS_NEW_ANSWERS(sg_fr)) {
	  UNTAG_NEW_ANSWERS(sg_fr);
	  TAG_NEW_ANSWERS(LOCAL_top_sg_fr_on_branch);
	}	
      }
      /* consume all answers */
      goto answer_resolution;
    } 
    
#endif /*LINEAR_TABLING_DRE */    

    if(sg_fr==LOCAL_top_sg_fr_on_branch)
      remove_branch(sg_fr);

    if (IS_LEADER(sg_fr)){
      INFO_LINEAR_TABLING("is leader");
      private_completion(sg_fr);
      goto answer_resolution;      
    }

    /*if DRE is present then not leader */
#ifdef LINEAR_TABLING_DRS
      if(SgFr_cp(sg_fr)!=B->cp_cp){
        INFO_LINEAR_TABLING("drs- SgFr_cp=%p  B->cp=%p",SgFr_cp(sg_fr),B->cp_cp);
	SgFr_cp(sg_fr)=B->cp_cp;
	free_drs_answers(sg_fr);                
        SgFr_allocate_drs_looping_structure(sg_fr);
	SgFr_new_answer_trie(sg_fr)=SgFr_first_answer(sg_fr);
      }     
      goto DRS_answer_resolution;
#endif /*LINEAR_TABLING_DRS */
      if (HAS_NEW_ANSWERS(sg_fr)) {
	UNTAG_NEW_ANSWERS(sg_fr);
	TAG_NEW_ANSWERS(LOCAL_top_sg_fr_on_branch);
      }
      goto answer_resolution;    

ENDBOp();
