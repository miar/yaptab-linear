/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        wielemak@science.uva.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 1985-2007, University of Amsterdam

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#ifndef RDFDB_H_INCLUDED
#define RDFDB_H_INCLUDED
#include "avl.h"
#ifdef WITH_MD5
#include "md5.h"
#endif
#include "lock.h"

#define RDF_VERSION 20800		/* 2.8.0 */

#define URL_subPropertyOf \
	"http://www.w3.org/2000/01/rdf-schema#subPropertyOf"


		 /*******************************
		 *               C		*
		 *******************************/

/* Keep consistent with md5_type[] in rdf_db.c! */
#define OBJ_UNTYPED	0x0		/* partial: don't know */
#define OBJ_INTEGER	0x1
#define OBJ_DOUBLE	0x2
#define OBJ_STRING	0x3
#define OBJ_TERM	0x4

#define Q_NONE		0x0
#define Q_TYPE		0x1
#define Q_LANG		0x2

#define BY_NONE	0x00			/* 0 */
#define BY_S	0x01			/* 1 */
#define BY_P	0x02			/* 2 */
#define BY_O	0x04			/* 4 */
#define BY_SP	(BY_S|BY_P)		/* 3 */
#define BY_SO	(BY_S|BY_O)		/* 5 */
#define BY_OP	(BY_P|BY_O)		/* 6 */
#define BY_SPO	(BY_S|BY_P|BY_O)	/* 7 */

#define INDEX_TABLES 		        7
#define INITIAL_TABLE_SIZE   		8*1024
#define INITIAL_PREDICATE_TABLE_SIZE	1024
#define INITIAL_GRAPH_TABLE_SIZE	64

#define MAX_HASH_FACTOR 8		/* factor to trigger re-hash */
#define MIN_HASH_FACTOR 4		/* factor after re-hash */

#define NO_LINE	(0)

typedef struct cell
{ void *	value;			/* represented resource */
  struct cell  *next;			/* next in chain */
} cell;


typedef struct list
{ cell *head;				/* first in list */
  cell *tail;				/* tail of list */
} list;


typedef struct bitmatrix
{ size_t width;
  size_t heigth;
  int bits[1];
} bitmatrix;


#define DISTINCT_DIRECT 0		/* for ->distinct_subjects, etc */
#define DISTINCT_SUB    1

typedef struct predicate
{ atom_t	    name;		/* name of the predicate */
  struct predicate *next;		/* next in hash-table */
					/* hierarchy */
  list	            subPropertyOf;	/* the one I'm subPropertyOf */
  list	            siblings;		/* reverse of subPropertyOf */
  int		    label;		/* Numeric label in cloud */
  struct predicate_cloud *cloud;	/* cloud I belong to */
  unsigned int	    hash;		/* key used for hashing
  					   (=hash if ->cloud is up-to-date) */
					/* properties */
  struct predicate *inverse_of;		/* my inverse predicate */
  unsigned 	    transitive : 1;	/* P(a,b)&P(b,c) --> P(a,c) */
					/* statistics */
  long		    triple_count;	/* # triples on this predicate */
  long		    distinct_updated[2];/* Is count still valid? */
  long		    distinct_count[2];  /* Triple count at last update */
  long		    distinct_subjects[2];/* # distinct subject values */
  long		    distinct_objects[2];/* # distinct object values */
} predicate;


typedef struct predicate_cloud
{ predicate   **members;		/* member predicates */
  unsigned int  hash;			/* hash-code */
  size_t	size;			/* size of the cloud */
  size_t	deleted;		/* See erase_predicates() */
  bitmatrix    *reachable;		/* cloud reachability matrix */
  unsigned	dirty : 1;		/* predicate hash not synchronised */
} predicate_cloud;


typedef struct graph
{ struct graph    *next;		/* next in table */
  atom_t	    name;		/* name of the graph */
  atom_t	    source;		/* URL graph was loaded from */
  double	    modified;		/* Modified time of source URL */
  int		    triple_count;	/* # triples associated to it */
#ifdef WITH_MD5
  unsigned	    md5 : 1;		/* do/don't record MD5 */
  md5_byte_t 	    digest[16];		/* MD5 digest */
#endif
} graph;


typedef struct literal
{ union
  { atom_t	string;
    int64_t	integer;
    double	real;
    struct
    { record_t  record;
      size_t	len;
    } term;				/* external record */
  } value;
  atom_t	type_or_lang;		/* Type or language for literals */
  unsigned int  hash;			/* saved hash */
  unsigned	objtype : 3;
  unsigned	qualifier : 2;		/* Lang/Type qualifier */
  unsigned	shared : 1;		/* member of shared table */
  unsigned	term_loaded : 1;	/* OBJ_TERM from quick save file */
  unsigned	atoms_locked : 1;	/* Atoms have been locked */
  unsigned	references : 24;	/* # references to me */
} literal;


#define t_match next[0]

typedef struct triple
{ atom_t	subject;
  union
  { predicate*	r;			/* resolved: normal DB */
    atom_t	u;			/* used by rdf_load_db_/3 */
  } predicate;
  union
  { literal *	literal;
    atom_t	resource;
  } object;
  atom_t	graph;			/* where it comes from */
  unsigned long line;			/* graph-line number */
					/* indexing */
  struct triple*next[INDEX_TABLES];	/* hash-table next links */
					/* flags */
  unsigned	object_is_literal : 1;	/* Object is a literal */
  unsigned	resolve_pred : 1;	/* predicates needs to be resolved */
  unsigned	indexed : 3;		/* Partials: BY_* */
  unsigned	erased  : 1;		/* If TRUE, triple is erased */
  unsigned	first   : 1;		/* I'm the first on subject */
  unsigned	match   : 3;		/* How to match literals */
  unsigned	inversed : 1;		/* Partials: using inverse match */
  unsigned	is_duplicate : 1;	/* I'm a duplicate */
  unsigned	allocated : 1;		/* Triple is allocated */
  unsigned	atoms_locked : 1;	/* Atoms have been locked */
  unsigned	duplicates : 16;	/* Duplicate count */
					/* Total: 32 */
} triple;


typedef enum
{ TR_MARK,				/* mark start for nesting */
  TR_SUB_START,				/* start nested transaction */
  TR_SUB_END,				/* end nested transaction */
  TR_ASSERT,				/* rdf_assert */
  TR_RETRACT,				/* rdf_retractall */
  TR_UPDATE,				/* rdf_update */
  TR_UPDATE_SRC,			/* rdf_update */
  TR_UPDATE_MD5,			/* update md5 src */
  TR_RESET,				/* rdf_reset_db */
  TR_VOID				/* no-op */
} tr_type;


typedef struct transaction_record
{ struct transaction_record    *previous;
  struct transaction_record    *next;
  tr_type			type;
  triple		       *triple;		/* new/deleted triple */
  union
  { triple		       *triple; 	/* used for update */
    struct
    { atom_t			atom;
      unsigned long		line;
    } src;
    struct
    { graph		       *graph;
      md5_byte_t	       *digest;
    } md5;
    record_t		       transaction_id;
  } update;
} transaction_record;


typedef struct active_transaction
{ struct active_transaction *parent;
  term_t id;
} active_transaction;


typedef struct rdf_db
{ triple       *by_none, *by_none_tail;
  triple      **table[INDEX_TABLES];
  triple      **tail[INDEX_TABLES];
  int	       *counts[INDEX_TABLES];
  int		table_size[INDEX_TABLES];
  long		created;		/* #triples created */
  long		erased;			/* #triples erased */
  long		freed;			/* #triples actually erased */
  long		subjects;		/* subjects (unique first) */
  long		indexed[8];		/* Count calls */
  int		rehash_count;		/* # rehashes */
  int		gc_count;		/* # garbage collections */
  int		gc_blocked;		/* GC is blocked; */
  double	rehash_time;		/* time spent in rehash */
  double	gc_time;		/* time spent in GC */
  size_t	core;			/* core in use */
  predicate   **pred_table;		/* Hash-table of predicates */
  int		pred_table_size;	/* #entries in the table */
  int		pred_count;		/* #predicates */
  unsigned long next_hash;		/* cloud hash keys */
  int		active_queries;		/* Calls with choicepoints */
  int		need_update;		/* We need to update */
  long		agenda_created;		/* #visited nodes in agenda */
  long		duplicates;		/* #duplicate triples */
  long		generation;		/* generation-id of the database */
  graph       **graph_table;		/* Hash table of sources */
  int      	graph_table_size;	/* Entries in table */

  graph	*last_graph;		/* last accessed graph */
  active_transaction *tr_active;	/* open transactions */
  transaction_record *tr_first;		/* first transaction record */
  transaction_record *tr_last;		/* last transaction record */
  int		tr_nesting;		/* nesting depth of transactions */
  int		tr_reset;		/* transaction contains reset */
  int 		resetting;		/* We are in rdf_reset_db() */

  rwlock	lock;			/* threaded access */

  avl_tree      literals;
} rdf_db;

#endif /*RDFDB_H_INCLUDED*/
