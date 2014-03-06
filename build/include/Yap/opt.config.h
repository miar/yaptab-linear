/**********************************************************************
                                                               
                       The OPTYap Prolog system                
  OPTYap extends the Yap Prolog system to support or-parallel tabling
                                                               
  Copyright:   R. Rocha and NCC - University of Porto, Portugal
  File:        opt.config.h
  version:     $Id: opt.config.h,v 1.10 2005-10-31 12:27:54 vsc Exp $   
                                                                     
**********************************************************************/

/* ----------------------------------------------------------------- **
**                  General Configuration Parameters                 **
** ----------------------------------------------------------------- */

/* ------------------------------------------ **
**      memory alloc scheme (define one)      **
** ------------------------------------------ */
#define YAP_MEMORY_ALLOC_SCHEME 1
/* #define SHM_MEMORY_ALLOC_SCHEME 1 */
/* #define MALLOC_MEMORY_ALLOC_SCHEME 1 */





/* ---------------------------------------------------------------- **
**                 TABLING Configuration Parameters                 **
** ---------------------------------------------------------------- */



/* ----------------------------------- **
**      linear tabling? (optional)     **
** ----------------------------------- */

//#define DEBUG_LINEAR_TABLING 1  

#define LINEAR_TABLING 1 

/* ------------------------------------------------------ **
**      linear tabling strategy                           **
**            (suported modes:                            **
**                  --BASIC                               **
**		    --DRA                                 **
**		    --FOLLOWER (basic mode)               **
**		    --DRA+FOLLOWER)                       **
**      DRS- Dynamic Reordering of Solutions (optional)   **
** ------------------------------------------------------ */

#define LINEAR_TABLING_BASIC 1  
//#define LINEAR_TABLING_DRA 1  
//#define LINEAR_TABLING_FOLLOWER 1 

//#define LINEAR_TABLING_DRS     1

//#define DUMMY_PRINT        1

#define MAX_LOOP_ALT_BUCKET   10

#define MAX_LOOP_ANS_BUCKET   1


/* ----------------------- **
**      default sizes      **
** ----------------------- */
#define MAX_TABLE_VARS 1000



/* ------------------------------------------ **
**      trail freeze scheme (define one)      **
** ------------------------------------------ */
#define BFZ_TRAIL_SCHEME 1
/* #define BBREG_TRAIL_SCHEME 1 */

/* ----------------------------------------------- **
**      support early completion ? (optional)      **
** ----------------------------------------------- */
 /*#define TABLING_EARLY_COMPLETION 1 */

/* ------------------------------------------------ **
**      support trie compact pairs? (optional)      **
** ------------------------------------------------ */
#define TRIE_COMPACT_PAIRS 1

/* --------------------------------------------------- **
**      support deterministic tabling? (optional)      **
** --------------------------------------------------- */
/* #define DETERMINISTIC_TABLING 1 */

/* ------------------------------------------------ **
**      limit the table space size? (optional)      **
** ------------------------------------------------ */
/* #define LIMIT_TABLING 1 */

/* ------------------------------------------------ **
**      support incomplete tabling? (optional)      **
** ------------------------------------------------ */
/* #define INCOMPLETE_TABLING 1 */

/* ---------------------------------------- -- **
**      enable error checking? (optional)      **
** ------------------------------------------- */
/* #define TABLING_ERRORS 1 */




/* ---------------------------------------------------------------- **
**                  YAPOR Configuration Parameters                  **
** ---------------------------------------------------------------- */

/* ----------------------- **
**      default sizes      **
** ----------------------- */
#define MAX_LENGTH_ANSWER  1000
#define MAX_BRANCH_DEPTH   1000
#define MAX_BEST_TIMES     21

/* -------------------------------------------- **
**      memory mapping scheme (define one)      **
** -------------------------------------------- */
#define MMAP_MEMORY_MAPPING_SCHEME 1
/* #define SHM_MEMORY_MAPPING_SCHEME  1 */

/* ---------------------------------------- -- **
**      enable error checking? (optional)      **
** ------------------------------------------- */
/* #define YAPOR_ERRORS   1 */





/* ---------------------------------------------------------------- **
**                   OPTYAP Configuration Parameters                **
** ---------------------------------------------------------------- */

/* ----------------------- **
**      default sizes      **
** ----------------------- */
#define TABLE_LOCK_BUCKETS 512
#define TG_ANSWER_SLOTS    20

/* ------------------------------------------- **
**      tries locking scheme (define one)      **
** ------------------------------------------- **
** The TABLE_LOCK_AT_ENTRY_LEVEL scheme locks  **
** the access to the table space in the entry  **
** data structure. It restricts the number of  **
** lock operations needed to go through the    **
** table data structures.                      **
**                                             **
** The TABLE_LOCK_AT_NODE_LEVEL scheme locks   **
** each data structure before accessing it. It **
** decreases concurrrency for workers          **
** accessing commom parts of the table space.  **
**                                             **
** The TABLE_LOCK_AT_WRITE_LEVEL scheme is an  **
** hibrid scheme, it only locks a table data   **
** structure when it is going to update it.    **
** You can use ALLOC_BEFORE_CHECK with this    **
** scheme to allocate a node before checking   **
** if it will be necessary.                    **
** ------------------------------------------- */
/* #define TABLE_LOCK_AT_ENTRY_LEVEL 1 */
/* #define TABLE_LOCK_AT_NODE_LEVEL  1 */
#define TABLE_LOCK_AT_WRITE_LEVEL 1
/* #define ALLOC_BEFORE_CHECK        1 */

/* ---------------------------------------- **
**      support inner cuts? (optional)      **
** ---------------------------------------- */
#define TABLING_INNER_CUTS 1

/* --------------------------------------------------- **
**      use timestamps for suspension? (optional)      **
** --------------------------------------------------- */
#define TIMESTAMP_CHECK 1





/* ---------------------------------------------------------------- **
**                          Parameter Checks                        **
** ---------------------------------------------------------------- */

#if !defined(SHM_MEMORY_ALLOC_SCHEME) && !defined(MALLOC_MEMORY_ALLOC_SCHEME) && !defined(YAP_MEMORY_ALLOC_SCHEME)
#error Define a memory alloc scheme
#endif /* !SHM_MEMORY_ALLOC_SCHEME && !MALLOC_MEMORY_ALLOC_SCHEME && !YAP_MEMORY_ALLOC_SCHEME */
#if defined(SHM_MEMORY_ALLOC_SCHEME)
#if defined(MALLOC_MEMORY_ALLOC_SCHEME) || defined(YAP_MEMORY_ALLOC_SCHEME)
#error Do not define multiple memory alloc schemes
#endif /* MALLOC_MEMORY_ALLOC_SCHEME || YAP_MEMORY_ALLOC_SCHEME */
#endif /* SHM_MEMORY_ALLOC_SCHEME */
#if defined(MALLOC_MEMORY_ALLOC_SCHEME) && defined(YAP_MEMORY_ALLOC_SCHEME)
#error Do not define multiple memory alloc schemes
#endif /* MALLOC_MEMORY_ALLOC_SCHEME && YAP_MEMORY_ALLOC_SCHEME */
#if defined(YAPOR) && defined(MALLOC_MEMORY_ALLOC_SCHEME)
#error YAPOR is incompatible with MALLOC_MEMORY_ALLOC_SCHEME 
#endif /* YAPOR && TABLING && (MALLOC_MEMORY_ALLOC_SCHEME || YAP_MEMORY_ALLOC_SCHEME) */

#ifdef YAPOR
#ifdef i386 /* For i386 machines we use shared memory segments */
#undef MMAP_MEMORY_MAPPING_SCHEME
#define SHM_MEMORY_MAPPING_SCHEME
#endif /* i386 */
#if !defined(MMAP_MEMORY_MAPPING_SCHEME) && !defined(SHM_MEMORY_MAPPING_SCHEME)
#error Define a memory mapping scheme
#endif /* !MMAP_MEMORY_MAPPING_SCHEME && !SHM_MEMORY_MAPPING_SCHEME */
#if defined(MMAP_MEMORY_MAPPING_SCHEME) && defined(SHM_MEMORY_MAPPING_SCHEME)
#error Do not define multiple memory mapping schemes
#endif /* MMAP_MEMORY_MAPPING_SCHEME && SHM_MEMORY_MAPPING_SCHEME */
#undef LIMIT_TABLING
#endif /* YAPOR */

#ifdef TABLING
#if !defined(BFZ_TRAIL_SCHEME) && !defined(BBREG_TRAIL_SCHEME)
#error Define a trail scheme
#endif /* !BFZ_TRAIL_SCHEME && !BBREG_TRAIL_SCHEME */
#if defined(BFZ_TRAIL_SCHEME) && defined(BBREG_TRAIL_SCHEME)
#error Do not define multiple trail schemes
#endif /* BFZ_TRAIL_SCHEME && BBREG_TRAIL_SCHEME */
#endif /* TABLING */

#if defined(YAPOR) && defined(TABLING)
#if !defined(TABLE_LOCK_AT_ENTRY_LEVEL) && !defined(TABLE_LOCK_AT_NODE_LEVEL) && !defined(TABLE_LOCK_AT_WRITE_LEVEL)
#error Define a table lock scheme
#endif /* !TABLE_LOCK_AT_ENTRY_LEVEL && !TABLE_LOCK_AT_NODE_LEVEL && !TABLE_LOCK_AT_WRITE_LEVEL */
#if defined(TABLE_LOCK_AT_ENTRY_LEVEL)
#if defined(TABLE_LOCK_AT_NODE_LEVEL) || defined(TABLE_LOCK_AT_WRITE_LEVEL)
#error Do not define multiple table lock schemes
#endif /* TABLE_LOCK_AT_NODE_LEVEL || TABLE_LOCK_AT_WRITE_LEVEL */
#endif /* TABLE_LOCK_AT_ENTRY_LEVEL */
#if defined(TABLE_LOCK_AT_NODE_LEVEL) && defined(TABLE_LOCK_AT_WRITE_LEVEL)
#error Do not define multiple table lock schemes
#endif /* TABLE_LOCK_AT_NODE_LEVEL || TABLE_LOCK_AT_WRITE_LEVEL */
#ifndef TABLE_LOCK_AT_WRITE_LEVEL
#undef ALLOC_BEFORE_CHECK
#endif /* !TABLE_LOCK_AT_WRITE_LEVEL */
#else
#undef TABLE_LOCK_AT_ENTRY_LEVEL
#undef TABLE_LOCK_AT_NODE_LEVEL
#undef TABLE_LOCK_AT_WRITE_LEVEL
#undef ALLOC_BEFORE_CHECK
#endif /* YAPOR && TABLING */

#if !defined(TABLING) || !defined(YAPOR)
#undef TABLING_INNER_CUTS
#undef TIMESTAMP_CHECK
#endif /* !TABLING || !YAPOR */

#ifndef YAPOR
#undef YAPOR_ERRORS
#endif /* !YAPOR */

#ifndef TABLING
#undef BFZ_TRAIL_SCHEME
#undef BBREG_TRAIL_SCHEME
#undef TRIE_COMPACT_PAIRS
#undef TABLING_EARLY_COMPLETION
#undef DETERMINISTIC_TABLING
#undef LIMIT_TABLING
#undef INCOMPLETE_TABLING
#undef TABLING_ERRORS
#endif /* !TABLING */

#ifndef SHM_MEMORY_ALLOC_SCHEME
#undef LIMIT_TABLING
#endif /* !SHM_MEMORY_ALLOC_SCHEME */

#if defined(YAPOR_ERRORS) && defined(TABLING_ERRORS)
#define OPTYAP_ERRORS
#endif /* YAPOR_ERRORS && TABLING_ERRORS */


#ifdef LINEAR_TABLING
#if defined(LINEAR_TABLING_FOLLOWER) && !defined(LINEAR_TABLING_BASIC) && !defined(LINEAR_TABLING_DRA)
#define LINEAR_TABLING_BASIC
#endif /*defined(LINEAR_TABLING_FOLLOWER) && !defined(LINEAR_TABLING_BASIC) && !defined(LINEAR_TABLING_DRA) */

#if (defined(LINEAR_TABLING_DRA) && defined(LINEAR_TABLING_BASIC))
#error Please define a linear tabling strategy (supported modes:dra,basic,dra+follower,follower (basic mode))
#endif /*(defined(LINEAR_TABLING_DRA) && defined(LINEAR_TABLING_BASIC)) */

#if (!defined(LINEAR_TABLING_DRA) && !defined(LINEAR_TABLING_BASIC) && !defined(LINEAR_TABLING_FOLLOWER))
#error Please define a linear tabling strategy (supported modes:dra,basic,dra+follower,follower (basic mode))
#endif /*(!defined(LINEAR_TABLING_DRA) && !defined(LINEAR_TABLING_BASIC) && !defined(LINEAR_TABLING_FOLLOWER))*/

#else
#undef LINEAR_TABLING_DRA
#undef LINEAR_TABLING_FOLLOWER
#undef LINEAR_TABLING_BASIC
#endif /* LINEAR_TABLING */



