#ifndef __MYDDAS_STRUCTS_H__
#define __MYDDAS_STRUCTS_H__

#include "myddas.h"
#ifdef MYDDAS_STATS
#include "myddas_statistics_structs.h"
#endif 

struct myddas_global {
  MYDDAS_UTIL_CONNECTION myddas_top_connections;
#ifdef MYDDAS_TOP_LEVEL
  MYDDAS_UTIL_CONNECTION myddas_top_level_connection;
#endif
#ifdef MYDDAS_STATS
  MYDDAS_GLOBAL_STATS myddas_statistics;
#endif
#ifdef DEBUG
  /* Number times malloc was called */
  MyddasULInt malloc_called;
  /* Memory allocated by MYDDAS */
  MyddasULInt memory_allocated;
  
  /* Number times free was called */
  MyddasULInt free_called;
  /* Memory freed by MYDDAS */
  MyddasULInt memory_freed;
#endif
};

struct myddas_list_preds {
  char *pred_module;
  char *pred_name;
  short pred_arity;
  //void *pe;
  MYDDAS_UTIL_PREDICATE next;
  MYDDAS_UTIL_PREDICATE previous;
};

struct myddas_list_connection {
  void *connection;

  /*If variable env is NULL, then it's a 
    MySQL connection, if not then it as the pointer 
    to the ODBC enviromment variable */
  void *odbc_enviromment;

#ifdef MYDDAS_STATS
  MYDDAS_STATS_STRUCT stats;
#endif
  MYDDAS_UTIL_PREDICATE predicates;

  /* Multi Queries Section */
  unsigned long total_number_queries;
  unsigned long actual_number_queries;
  MYDDAS_UTIL_QUERY *queries;

  /* List Integrety */
  MYDDAS_UTIL_CONNECTION next;
  MYDDAS_UTIL_CONNECTION previous;
};

struct myddas_util_query{
  char *query;
  MYDDAS_UTIL_QUERY next;
};

#endif 
