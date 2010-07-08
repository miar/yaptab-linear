




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
    } else if (SgFr_state(sg_fr) == looping_ready) {
      table_try_with_looping_ready(sg_fr);
    } else if (SgFr_state(sg_fr) == evaluating || 
               SgFr_state(sg_fr) == looping_evaluating){ 
      propagate_dependencies(sg_fr);
      consume_answers(tab_ent,sg_fr);
    } else {
      /* subgoal completed */
      ans_node_ptr ans_node = SgFr_first_answer(sg_fr);
      if (ans_node == NULL) {
	/* no answers --> fail */
	UNLOCK(SgFr_lock(sg_fr));
	goto fail;
      }
      table_try_with_completed(sg_fr,ans_node,tab_ent);
    }
  ENDPBOp();


  PBOp(table_try_me, Otapl)
    INFO_LINEAR_TABLING("-------------------------table_try_me ---------------");
    table_try_begin();
    if (SgFr_state(sg_fr) == ready) {
      /* subgoal new */
      table_try_with_ready(sg_fr,NEXTOP(PREG,Otapl),PREG->u.Otapl.d);
    } else if (SgFr_state(sg_fr) == looping_ready) {
      table_try_with_looping_ready(sg_fr);
    } else if (SgFr_state(sg_fr) == evaluating) {
      table_try_with_evaluating(sg_fr);
      consume_answers(tab_ent,sg_fr);
    } else if (SgFr_state(sg_fr) == looping_evaluating) {
      table_try_with_looping_evaluating(sg_fr);
      consume_answers(tab_ent,sg_fr);
    } else {
      /* subgoal completed */
      ans_node_ptr ans_node = SgFr_first_answer(sg_fr);
      if (ans_node == NULL) {
	/* no answers --> fail */
	UNLOCK(SgFr_lock(sg_fr));
	goto fail;
      }
      table_try_with_completed(sg_fr,ans_node,tab_ent);
    }
  ENDPBOp();


  PBOp(table_try, Otapl)
    INFO_LINEAR_TABLING("-------------------------table_try ---------------");
    table_try_begin();
    if (SgFr_state(sg_fr) == ready) {
      /* subgoal new */
      table_try_with_ready(sg_fr,PREG->u.Otapl.d, NEXTOP(PREG,Otapl));
    } else if (SgFr_state(sg_fr) == looping_ready) {
      table_try_with_looping_ready(sg_fr);
    } else if (SgFr_state(sg_fr) == evaluating) {
      table_try_with_evaluating(sg_fr);
      consume_answers(tab_ent,sg_fr);
    } else if (SgFr_state(sg_fr) == looping_evaluating) {
      table_try_with_looping_evaluating(sg_fr);
      consume_answers(tab_ent,sg_fr);
    } else {
      /* subgoal completed */
      ans_node_ptr ans_node = SgFr_first_answer(sg_fr);
      if (ans_node == NULL) {
	/* no answers --> fail */
	UNLOCK(SgFr_lock(sg_fr));
	goto fail;
      }
      table_try_with_completed(sg_fr,ans_node,tab_ent);
    }
  ENDPBOp();







