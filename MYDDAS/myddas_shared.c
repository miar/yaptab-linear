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
* File:		myddas_shared.c						 *
* Last rev:	22/03/05						 *
* mods:									 *
* comments:	Predicates for maintaining MYDDAS                        *
*									 *
*************************************************************************/

#if defined MYDDAS_MYSQL || defined MYDDAS_ODBC

#include "Yap.h"
#include "Yatom.h"
#include "cut_c.h"
#include "myddas.h"
#include <stdlib.h>
#include "myddas_structs.h"
#ifdef MYDDAS_STATS
#include "myddas_statistics.h"
#endif

STATIC_PROTO(Int c_db_initialize_myddas,(void));
STATIC_PROTO(Int c_db_connection_type,(void));
STATIC_PROTO(Int c_db_add_preds,(void));
STATIC_PROTO(Int c_db_preds_conn_start ,(void));
STATIC_PROTO(Int c_db_preds_conn_continue ,(void));
STATIC_PROTO(Int c_db_connection_start ,(void));
STATIC_PROTO(Int c_db_connection_continue ,(void));
STATIC_PROTO(Int c_db_check_if_exists_pred,(void));
STATIC_PROTO(Int c_db_delete_predicate,(void));
STATIC_PROTO(Int c_db_multi_queries_number,(void));
#ifdef MYDDAS_STATS
STATIC_PROTO(Int c_db_stats,(void));
STATIC_PROTO(Int c_db_stats_walltime,(void));
STATIC_PROTO(Int c_db_stats_translate,(void));
STATIC_PROTO(Int c_db_stats_time,(void));
#endif 
#ifdef DEBUG
STATIC_PROTO(Int c_db_check,(void));
#endif

void Yap_InitMYDDAS_SharedPreds(void)
{
  /* c_db_initialize_myddas */
  Yap_InitCPred("c_db_initialize_myddas",0,c_db_initialize_myddas, 0);
  
  /* c_db_connection_type: Connection x Type */
  Yap_InitCPred("c_db_connection_type",2,c_db_connection_type, 0);

  /* CORRECT THIS: db_add_preds : PredName * Arity * Connection */
  Yap_InitCPred("c_db_add_preds",4,c_db_add_preds, 0);

  /* c_db_check_if_exists_pred : PredName * Arity * Connection */
  Yap_InitCPred("c_db_check_if_exists_pred",3,c_db_check_if_exists_pred, 0);
  
  /* c_db_delete_pred : Module * PredName * Arity */
  Yap_InitCPred("c_db_delete_predicate",3,c_db_delete_predicate, 0);

  /* c_db_delete_pred : Module * PredName * Arity */
  Yap_InitCPred("c_db_multi_queries_number",2,c_db_multi_queries_number, 0);

#ifdef MYDDAS_STATS
  /* c_db_stats: Connection * Stats */
  Yap_InitCPred("c_db_stats",2, c_db_stats, 0);

  /* c_db_stats_walltime */
  Yap_InitCPred("c_db_stats_walltime",1, c_db_stats_walltime, 0);

  /* c_db_stats_translate */
  Yap_InitCPred("c_db_stats_translate",2,c_db_stats_translate, 0);

  /* c_db_stats_time */
  Yap_InitCPred("c_db_stats_time",2,c_db_stats_time, 0);
#endif

#ifdef DEBUG
  Yap_InitCPred("c_db_check",0, c_db_check, 0);
#endif
}

void Yap_InitBackMYDDAS_SharedPreds(void)
{
  /* Gives all the predicates associated to a given connection */
  Yap_InitCPredBack("c_db_preds_conn", 4, sizeof(Int),
		    c_db_preds_conn_start, 
		    c_db_preds_conn_continue,  0);
  /* Gives all the connections stored on the MYDDAS Structure*/
  Yap_InitCPredBack("c_db_connection", 1, sizeof(Int),
		    c_db_connection_start, 
		    c_db_connection_continue,  0); 
  

}

/* Initialize all of the MYDDAS global structures */
static Int 
c_db_initialize_myddas(void){
  Yap_REGS.MYDDAS_GLOBAL_POINTER = myddas_init_initialize_myddas(); 
#ifdef MYDDAS_STATS
  Yap_REGS.MYDDAS_GLOBAL_POINTER = myddas_stats_initialize_global_stats(Yap_REGS.MYDDAS_GLOBAL_POINTER);
#endif /* MYDDAS_STATS */
  return TRUE;
}


/* Gives the type of a given connection, 
   in other words, type will be mysql or odbc 
   
   NOTE: In order to use this predicate, the connection*/
/* c_db_connection_type: +Connection * ?Type */
static Int 
c_db_connection_type (void){
  Term arg_con = Deref(ARG1);
  Term arg_type = Deref(ARG2);
  
  Int *con = (Int *) IntegerOfTerm(arg_con);
  Int type = myddas_util_connection_type(con);
  
  if (type == 1) /* MYSQL Connection */
    Yap_unify(arg_type, MkAtomTerm(Yap_LookupAtom("mysql")));
  else if (type ==2) /* ODBC Connection */
    Yap_unify(arg_type, MkAtomTerm(Yap_LookupAtom("odbc")));
  else /* Not a valid connection*/
    return FALSE;
  
  return TRUE;
}

/* db_add_preds: PredName * Arity * Module * Connection*/
static Int 
c_db_add_preds (void){
  Term arg_nome = Deref(ARG1);
  Term arg_aridade = Deref(ARG2);
  Term arg_module = Deref(ARG3);
  Term arg_conn = Deref(ARG4);
  
/*   PredEntry *pe; */
/*   pe = RepPredProp(PredPropByFunc(FunctorOfTerm(arg_pred),arg_module)); */
  

  char *nome = AtomName(AtomOfTerm(arg_nome));
  char *module = AtomName(AtomOfTerm(arg_module));
  Int aridade = IntegerOfTerm(arg_aridade);
  Int *conn = (Int *) IntegerOfTerm(arg_conn);

  if (myddas_util_add_predicate(nome,aridade,module,conn) == NULL)
    {
#ifdef DEBUG
      printf ("ERROR : Could not add Predicate: Line: %d File: %s\n",__LINE__,__FILE__);
#endif
      return FALSE;
    }
  
  return TRUE;
}


static Int 
c_db_check_if_exists_pred (void){
  Term arg_nome = Deref(ARG1);
  Term arg_aridade = Deref(ARG2);
  Term arg_module = Deref(ARG3);
    
 
  char *nome = AtomName(AtomOfTerm(arg_nome));
  char *module = AtomName(AtomOfTerm(arg_module));
  Int aridade = IntegerOfTerm(arg_aridade);
  
  if (myddas_util_search_predicate(nome,aridade,module) == NULL)
    return FALSE;
  else
    return TRUE;
}


static Int 
c_db_delete_predicate(void){
  Term arg_module = Deref(ARG1);
  Term arg_name = Deref(ARG2);
  Term arg_arity = Deref(ARG3);
  
  char *module = AtomName(AtomOfTerm(arg_module));
  char *name = AtomName(AtomOfTerm(arg_name));
  Int arity = IntegerOfTerm(arg_arity);

  MYDDAS_UTIL_PREDICATE predicate = 
    myddas_util_search_predicate(name,arity,module);
  if (predicate == NULL)
    return FALSE;

  myddas_util_delete_predicate(predicate);

  return TRUE;
}


static Int 
c_db_multi_queries_number(void){
  Term arg_conn = Deref(ARG1);
  Term arg_number = Deref(ARG2);

  Int *conn = (Int *) IntegerOfTerm(arg_conn);
  MYDDAS_UTIL_CONNECTION node = 
    myddas_util_search_connection(conn);
  
  if (node == NULL)
    return FALSE;

  if (IsVarTerm(arg_number)){
    Yap_unify(arg_number,MkIntegerTerm(((Int)myddas_util_get_total_multi_queries_number(node))+1));
  } 
  else {
    Int number = IntegerOfTerm(arg_number);
    number--;
    myddas_util_set_total_multi_queries_number(node,number);
  }
  
  return TRUE;
  
}

static Int
c_db_connection_start(void){

  MYDDAS_UTIL_CONNECTION node =
    Yap_REGS.MYDDAS_GLOBAL_POINTER->myddas_top_connections;

  EXTRA_CBACK_ARG(1,1)=(CELL) MkIntegerTerm((Int)node);
  
  return (c_db_connection_continue());
}

static Int
c_db_connection_continue(void){
  Term arg_conn = Deref(ARG1);
  
  MYDDAS_UTIL_CONNECTION node;
  node = (MYDDAS_UTIL_CONNECTION) IntegerOfTerm(EXTRA_CBACK_ARG(1,1));
  
  /* There is no connections */
  if (node == NULL)
    {
      cut_fail();
      return FALSE;
    }

  Yap_unify(arg_conn, MkIntegerTerm((Int)(node->connection)));
  EXTRA_CBACK_ARG(1,1)=(CELL) MkIntegerTerm((Int)(node->next));
  
  return TRUE;
  
}

/* db_preds_conn : Connection(+) * Pred_name(-) * Pred_arity */
static Int
c_db_preds_conn_start (void){
  Term arg_conn = Deref(ARG1);
   
  Int *conn = (Int *) IntegerOfTerm(arg_conn);
  MYDDAS_UTIL_CONNECTION node = 
    myddas_util_search_connection(conn);
  
  /* Caso a ligacao j� tenha sido apagada*/
  if (node == NULL)
    {
      cut_fail();
      return FALSE;
    }
  
  void *pointer = myddas_util_get_list_pred(node);
  EXTRA_CBACK_ARG(4,1)=(CELL) MkIntegerTerm((Int)pointer);
  
  return (c_db_preds_conn_continue());
}

/* db_preds_conn : Connection(+) * Pred_name(-) * Pred_arity*/
static Int 
c_db_preds_conn_continue (void){
  Term module = Deref(ARG2);
  Term name = Deref(ARG3);
  Term arity = Deref(ARG4);

  void *pointer;
  pointer = (void *) IntegerOfTerm(EXTRA_CBACK_ARG(4,1));
    
  if (pointer != NULL)
    {
      EXTRA_CBACK_ARG(4,1)=(CELL) MkIntegerTerm((Int)myddas_util_get_pred_next(pointer));
      
      if (!Yap_unify(module, MkAtomTerm(Yap_LookupAtom(myddas_util_get_pred_module(pointer))))){
	return FALSE;
      }
      if (!Yap_unify(name,MkAtomTerm(Yap_LookupAtom(myddas_util_get_pred_name(pointer))))){
	return FALSE;
      }
      if (!Yap_unify(arity, MkIntegerTerm((Int)myddas_util_get_pred_arity(pointer)))){
	return FALSE;
      }
      return TRUE;
    }
  else
    {
      cut_fail();
      return FALSE;
    }
}



#ifdef DEBUG
static Int 
c_db_check(void){
  check_int();
  return TRUE;
}
#endif /*DEBUG*/

#ifdef MYDDAS_STATS

static Int
c_db_stats_walltime(void){
  Term arg_time = Deref(ARG1);

#ifdef DEBUG
  if (IsVarTerm(arg_time)){
#endif
    Yap_unify(arg_time,MkIntegerTerm((Int)myddas_stats_walltime()));
    return TRUE;
#ifdef DEBUG
  }
  else{
    printf ("ERROR: c_db_stats_walltime got a variable\n");
    return FALSE;
  }
#endif
}

static Int
c_db_stats_translate(void){
  Term arg_start = Deref(ARG1);
  Term arg_end = Deref(ARG2);

  MYDDAS_STATS_TIME start;
  MYDDAS_STATS_TIME end;
  
  MYDDAS_STATS_TIME total_time,diff;

#ifdef DEBUG
  //Both args must be instanciated
  if (IsNonVarTerm(arg_start) && IsNonVarTerm(arg_end)){
#endif
    start = (MYDDAS_STATS_TIME) IntegerOfTerm(arg_start);
    end = (MYDDAS_STATS_TIME) IntegerOfTerm(arg_end);

    MYDDAS_STATS_GET_TRANSLATE(total_time);
    
    MYDDAS_STATS_INITIALIZE_TIME_STRUCT(diff,time_copy);
    myddas_stats_subtract_time(diff,end,start);
    
    diff = myddas_stats_time_copy_to_final(diff);
    myddas_stats_add_time(total_time,diff,total_time);
    MyddasULInt count;
    MYDDAS_STATS_GET_TRANSLATE_COUNT(count);
    MYDDAS_STATS_SET_TRANSLATE_COUNT(++count);
    
    MYDDAS_FREE(diff,struct myddas_stats_time_struct);
    MYDDAS_FREE(start, struct myddas_stats_time_struct);
    MYDDAS_FREE(end, struct myddas_stats_time_struct);
    
    return TRUE;
#ifdef DEBUG
  }
  else{
    printf ("ERROR: c_db_stats_translate got a variable\n");
    return FALSE;
  }
#endif
}

static Int
c_db_stats_time(void){
  Term arg_reference = Deref(ARG1);
  Term arg_time = Deref(ARG2);
  
  Term final_term;
  
  MYDDAS_STATS_STRUCT struc = (MYDDAS_STATS_STRUCT)IntegerOfTerm(arg_reference);
  Functor functor_count = Yap_MkFunctor(Yap_LookupAtom("count"),1);
  Term count_number[1];
  Functor unit;
  Term number[1];

  switch(struc->type){
  
  case integer:
    {
      Functor functor = Yap_MkFunctor(Yap_LookupAtom("myddas_integer"),2);
      Term integer_number[1];
      MyddasULInt integer;

      unit = Yap_MkFunctor(Yap_LookupAtom("number"),1);
      integer = struc->u.integer.integer;
      number[0] = MkIntegerTerm(integer);
      integer_number[0] = Yap_MkApplTerm(unit,1,number);;
      
      count_number[0] = MkIntegerTerm(struc->count);
      integer_number[1] = Yap_MkApplTerm(functor_count,1,count_number);
      final_term = Yap_MkApplTerm(functor,2,integer_number);
      break;
    }
    
  case time_str:
    {
      MYDDAS_STATS_TIME time = struc->u.time_str.time_str;
    
      Functor functor = Yap_MkFunctor(Yap_LookupAtom("myddas_time"),6);
      Term time_numbers[6];
      MyddasUInt time_number;
            
      unit = Yap_MkFunctor(Yap_LookupAtom("hours"),1);
      time_number = MYDDAS_STATS_TIME_HOURS(time);
      number[0] = MkIntegerTerm(time_number);
      time_numbers[0] = Yap_MkApplTerm(unit,1,number);;
      
      unit = Yap_MkFunctor(Yap_LookupAtom("minutes"),1);
      time_number = MYDDAS_STATS_TIME_MINUTES(time);
      number[0] = MkIntegerTerm(time_number);
      time_numbers[1] = Yap_MkApplTerm(unit,1,number);;

      unit = Yap_MkFunctor(Yap_LookupAtom("seconds"),1);
      time_number = MYDDAS_STATS_TIME_SECONDS(time);
      number[0] = MkIntegerTerm(time_number);
      time_numbers[2] = Yap_MkApplTerm(unit,1,number);;
            
      unit = Yap_MkFunctor(Yap_LookupAtom("miliseconds"),1);
      time_number = MYDDAS_STATS_TIME_MILISECONDS(time);
      number[0] = MkIntegerTerm(time_number);
      time_numbers[3] = Yap_MkApplTerm(unit,1,number);;
      
      unit = Yap_MkFunctor(Yap_LookupAtom("microseconds"),1);
      time_number = MYDDAS_STATS_TIME_MICROSECONDS(time); 
      number[0] = MkIntegerTerm(time_number);
      time_numbers[4] = Yap_MkApplTerm(unit,1,number);;
      
      count_number[0] = MkIntegerTerm(struc->count);
      time_numbers[5] = Yap_MkApplTerm(functor_count,1,count_number);
      final_term = Yap_MkApplTerm(functor,6,time_numbers);
      break;
    }
  
    default:
#ifdef DEBUG
    printf ("ERROR: c_db_stats_time unknow option\n");
#endif
    return FALSE;
    break;
  }
  
  if (!Yap_unify(arg_time,final_term )){
    return FALSE;
  }

  return TRUE;
}

//Returns the stats of this module in a list
static Int 
c_db_stats(void) {
  Term arg_conn = Deref(ARG1);
  Term arg_list = Deref(ARG2);
  
  MyddasPointer *conn = (MyddasPointer *) (IntegerOfTerm(arg_conn));
    
  // TODO
  if (get_myddas_top() == 0 ){ /* We want all the statistics */
    return FALSE;
  }

  MYDDAS_STATS_STRUCT str;
  MYDDAS_UTIL_CONNECTION 
   node = myddas_util_search_connection(conn);
  Term head, list;
  list = arg_list;

#ifdef DEBUG
  MYDDAS_STATS_TIME time = NULL;
#endif
  //[Index 1] -> Total Number of Rows by connection
  //Total number of Rows returned by the server
  //WARNING: only works with store_result
  head = HeadOfTerm(list);
  list = TailOfTerm(list);
  str = myddas_stats_get_stat(node->stats,5);
  Yap_unify(head, MkIntegerTerm((MyddasInt)str));
#ifdef DEBUG
  MyddasUInt number = 0;

  MYDDAS_STATS_CON_GET_TOTAL_ROWS(node,number);
  printf ("Total Number of Rows returned from the Server\n");
  printf ("%lu\n\n",(unsigned long)number);
#endif

  //[Index 2] -> Total of Time Spent by the DB Server
  // processing all the  SQL Querys
  head = HeadOfTerm(list);
  list = TailOfTerm(list);
    
  str = myddas_stats_get_stat(node->stats,1);
  Yap_unify(head, MkIntegerTerm((MyddasInt)str));
#ifdef DEBUG
  MYDDAS_STATS_CON_GET_TOTAL_TIME_DBSERVER(node,time);
  printf ("Reference to time Spent by the Server, on all the SQL Querys\n");
  MYDDAS_STATS_PRINT_TIME_STRUCT(time);
  printf ("\n\n");
#endif  

  //[Index 3] -> Total of Time Spent by the DB Server
  // processing a the last SQL Query
  head = HeadOfTerm(list);
  list = TailOfTerm(list);
  
  str = myddas_stats_get_stat(node->stats,2);
  Yap_unify(head, MkIntegerTerm((MyddasInt)str));
#ifdef DEBUG
  MYDDAS_STATS_CON_GET_LAST_TIME_DBSERVER(node,time);
  printf ("Reference to time Spent by the Server, on the last SQL Query\n");
  MYDDAS_STATS_PRINT_TIME_STRUCT(time);
  printf ("\n\n");
#endif
  
  //[Index 4] -> Total of Time Spent by the DB Server
  // transfering all the results of the  SQL Querys
  head = HeadOfTerm(list);
  list = TailOfTerm(list);
  
  str = myddas_stats_get_stat(node->stats,3);
  Yap_unify(head, MkIntegerTerm((MyddasInt)str));
#ifdef DEBUG
  MYDDAS_STATS_CON_GET_TOTAL_TIME_TRANSFERING(node,time);
  printf ("Refence to time Spent by the Server, transfering all the results SQL Query\n");
  MYDDAS_STATS_PRINT_TIME_STRUCT(time);
  printf ("\n\n");
#endif
  
  //[Index 5] -> Total of Time Spent by the DB Server
  // transfering the result of the last SQL Query
  head = HeadOfTerm(list);
  list = TailOfTerm(list);
  
  str = myddas_stats_get_stat(node->stats,4);
  Yap_unify(head, MkIntegerTerm((MyddasInt)str));
#ifdef DEBUG
  MYDDAS_STATS_CON_GET_LAST_TIME_TRANSFERING(node,time);
  printf ("Reference to time Spent by the Server, transfering the result of the last SQL Query\n");
  MYDDAS_STATS_PRINT_TIME_STRUCT(time);
  printf ("\n\n");
#endif
  
  //[Index 6] -> Total of Time Spent by the 
  // db_row_function
  head = HeadOfTerm(list);
  list = TailOfTerm(list);
  
  str = myddas_stats_get_stat(Yap_REGS.MYDDAS_GLOBAL_POINTER->myddas_statistics->stats,1);
  
  Yap_unify(head, MkIntegerTerm((MyddasInt)str));
#ifdef DEBUG
  MYDDAS_STATS_GET_DB_ROW_FUNCTION(time);
  printf ("Reference to time Spent by the db_row_function\n");
  MYDDAS_STATS_PRINT_TIME_STRUCT(time);
  printf ("\n\n");
#endif
  
  //[Index 7] -> Total of Bytes Transfered by the 
  // DB Server on all SQL Querys
  head = HeadOfTerm(list);
  list = TailOfTerm(list);

  str = myddas_stats_get_stat(node->stats,6);
  Yap_unify(head, MkIntegerTerm((MyddasPointer)str));
#ifdef DEBUG
  MYDDAS_STATS_CON_GET_TOTAL_BYTES_TRANSFERING_FROM_DBSERVER(node,number);
  printf ("Bytes Transfered by the DB Server from all querys\n");
  printf ("%llu\n\n",(MyddasULInt)number);
#endif
  
  //[Index 8] -> Total of Bytes Transfered by the 
  // DB Server on the last SQL Query
  head = HeadOfTerm(list);
  list = TailOfTerm(list);
  
  str = myddas_stats_get_stat(node->stats,7);
  Yap_unify(head, MkIntegerTerm((MyddasPointer)str));
#ifdef DEBUG
  MYDDAS_STATS_CON_GET_LAST_BYTES_TRANSFERING_FROM_DBSERVER(node,number);
  printf ("Bytes Transfered by the DB Server on the last query\n");
  printf ("%llu\n\n",(MyddasULInt)number);
#endif
  //[Index 9] -> Number of querys made to the DBserver
  head = HeadOfTerm(list);
  list = TailOfTerm(list);

  str = myddas_stats_get_stat(node->stats,8);
  Yap_unify(head, MkIntegerTerm((MyddasPointer)str));
#ifdef DEBUG
  MYDDAS_STATS_CON_GET_NUMBER_QUERIES_MADE(node,number);
  printf ("Number of Querys made to the server\n");
  printf ("%llu\n\n",(MyddasULInt)number);
#endif

  //[Index 10] -> Total of Time Spent by the 
  // translate predicate
  head = HeadOfTerm(list);
  list = TailOfTerm(list);

  str = myddas_stats_get_stat(Yap_REGS.MYDDAS_GLOBAL_POINTER->myddas_statistics->stats,2);
  Yap_unify(head, MkIntegerTerm((Int)str));

#ifdef DEBUG
  MYDDAS_STATS_GET_TRANSLATE(time);
  printf ("Reference to time Spent by the translate predicate\n");
  MYDDAS_STATS_PRINT_TIME_STRUCT(time);
  printf ("\n\n");
#endif

  /* Memory management */
#ifdef DEBUG
  MyddasULInt nr;
  MYDDAS_MEMORY_MALLOC_NR(nr);
  printf ("Number of times malloc was called in MYDDAS: %lu \n",nr);
  MYDDAS_MEMORY_FREE_NR(nr);
  printf ("Number of times free was called in MYDDAS  : %lu \n",nr);
  
  MYDDAS_MEMORY_MALLOC_SIZE(nr);
  printf ("Total memory allocated in MYDDAS: %lu \n",nr);
  MYDDAS_MEMORY_FREE_SIZE(nr);
  printf ("Total memory freed in MYDDAS    : %lu \n",nr);
#endif
  
  return TRUE;
}

#endif /* MYDDAS_STATS */


/* Function to delete all the temporary tables */
/* from the mysql server */
void Yap_MYDDAS_delete_all_myddas_structs(void)
{

  /* NAO ESQUECER DE FAZER ISTO TB PARA O DB_CLOSE*/
  MYDDAS_GLOBAL global = 
    Yap_REGS.MYDDAS_GLOBAL_POINTER;

  /* In case that the MYDDAS module isn't loaded */
  if (global == NULL)
    return;

  MYDDAS_UTIL_CONNECTION connections =
    global->myddas_top_connections;
  
  /* Delete all connections */
  for(;connections!=NULL;connections=connections->next)
    myddas_util_delete_connection(connections->connection);
  
#ifdef MYDDAS_STATS
  myddas_stats_delete_stats_list(global->myddas_statistics->stats);
  MYDDAS_FREE(global->myddas_statistics,struct myddas_global_stats);
#endif

  MYDDAS_FREE(global,struct myddas_global);

#ifdef DEBUG
  MyddasULInt nr;
  MYDDAS_MEMORY_MALLOC_NR(nr);
  printf ("Number of times malloc was called in MYDDAS: " UInt_FORMAT " \n",(UInt)nr);
  MYDDAS_MEMORY_FREE_NR(nr);
  printf ("Number of times free was called in MYDDAS  : " UInt_FORMAT " \n",(UInt)nr);
  
  MYDDAS_MEMORY_MALLOC_SIZE(nr);
  printf ("Total memory allocated in MYDDAS: " UInt_FORMAT " \n",(UInt)nr);
  MYDDAS_MEMORY_FREE_SIZE(nr);
  printf ("Total memory freed in MYDDAS    : " UInt_FORMAT " \n",(UInt)nr);
#endif
  
}





#endif /*CUT_C && (MYDDAS_MYSQL || MYDDAS_ODBC)*/
