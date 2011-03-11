/*************************************************************************
*									 *
*	 YAP Prolog 							 *
*									 *
*	Yap Prolog was developed at NCCUP - Universidade do Porto	 *
*									 *
* Copyright R. Lopes,L.Damas, V. Santos Costa and Universidade do Porto 1985--	 *
*									 *
**************************************************************************
*									 *
* File:		gprof.c							 *
* comments:	Interrupt Driven Profiler				 *
*									 *
* Last rev:     $Date: 2008-03-26 14:37:07 $,$Author: vsc $						 *
* $Log: not supported by cvs2svn $
* Revision 1.9  2007/10/08 23:02:15  vsc
* minor fixes
*
* Revision 1.8  2007/04/10 22:13:20  vsc
* fix max modules limitation
*
* Revision 1.7  2006/08/22 16:12:45  vsc
* global variables
*
* Revision 1.6  2006/08/07 18:51:44  vsc
* fix garbage collector not to try to garbage collect when we ask for large
* chunks of stack in a single go.
*
* Revision 1.5  2006/04/27 20:58:59  rslopes
* fix do profiler offline.
*
* Revision 1.4  2006/02/01 13:28:56  vsc
* bignum support fixes
*
* Revision 1.3  2006/01/17 14:10:40  vsc
* YENV may be an HW register (breaks some tabling code)
* All YAAM instructions are now brackedted, so Op introduced an { and EndOp introduces an }. This is because Ricardo assumes that.
* Fix attvars when COROUTING is undefined.
*
* Revision 1.2  2005/12/23 00:20:13  vsc
* updates to gprof
* support for __POWER__
* Try to saveregs before longjmp.
*
* Revision 1.1  2005/12/17 03:26:38  vsc
* move event profiler outside from stdpreds.c
*									 *
*************************************************************************/

#ifdef SCCS
static char     SccsId[] = "%W% %G%";
#endif

#if defined(__x86_64__) && defined (__linux__)

#define __USE_GNU

#include <ucontext.h>

typedef greg_t context_reg;
#define CONTEXT_PC(scv) (((ucontext_t *)(scv))->uc_mcontext.gregs[14])
#define CONTEXT_BP(scv) (((ucontext_t *)(scv))->uc_mcontext.gregs[6])

#elif defined(__i386__) && defined (__linux__)

#include <ucontext.h>

typedef greg_t context_reg;
#define CONTEXT_PC(scv) (((ucontext_t *)(scv))->uc_mcontext.gregs[14])
#define CONTEXT_BP(scv) (((ucontext_t *)(scv))->uc_mcontext.gregs[6])

#elif defined(__APPLE__) && defined(__x86_64__)

#include <AvailabilityMacros.h>
#include <sys/ucontext.h>

#if !defined(MAC_OS_X_VERSION_10_5) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
#define CONTEXT_REG(r) r
#else
#define CONTEXT_REG(r) __##r
#endif

#define CONTEXT_STATE(scv) (((ucontext_t *)(scv))->uc_mcontext->CONTEXT_REG(ss))
#define CONTEXT_PC(scv) (CONTEXT_STATE(scv).CONTEXT_REG(rip))
#define CONTEXT_BP(scv) (CONTEXT_STATE(scv).CONTEXT_REG(rbp))

#elif defined(__APPLE__) && defined(__i386__)

#include <AvailabilityMacros.h>
#include <sys/ucontext.h>

#if !defined(MAC_OS_X_VERSION_10_5) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
#define CONTEXT_REG(r) r
#else
#define CONTEXT_REG(r) __##r
#endif

#define CONTEXT_STATE(scv) (((ucontext_t *)(scv))->uc_mcontext->CONTEXT_REG(ss))
#define CONTEXT_PC(scv) (CONTEXT_STATE(scv).CONTEXT_REG(eip))
#define CONTEXT_BP(scv) (CONTEXT_STATE(scv).CONTEXT_REG(ebp))
#define CONTEXT_FAULTING_ADDRESS ((char *) info->si_addr)

#else

#define CONTEXT_PC NULL
#define CONTEXT_BP NULL

#endif

#include "absmi.h"
#include <stdio.h>

#if HAVE_STRING_H
#include <string.h>
#endif

#ifdef LOW_PROF
#include <signal.h>
#include <unistd.h>
#include <sys/time.h>
#ifdef __APPLE__
#else
#include <ucontext.h>
#endif

static Int ProfCalls, ProfGCs, ProfHGrows, ProfSGrows, ProfMallocs, ProfOn, ProfOns;

#define TIMER_DEFAULT 100
#define PROFILING_FILE 1
#define PROFPREDS_FILE 2

static char *DIRNAME=NULL;

typedef struct RB_red_blk_node {
  yamop *key; /* first address */
  yamop *lim; /* end address */
  PredEntry *pe; /* parent predicate */
  UInt pcs;  /* counter with total for each clause */
  int red; /* if red=0 then the node is black */
  struct RB_red_blk_node* left;
  struct RB_red_blk_node* right;
  struct RB_red_blk_node* parent;
} rb_red_blk_node;

static rb_red_blk_node *ProfilerRoot, *ProfilerNil;

static rb_red_blk_node *
RBMalloc(UInt size)
{
  return (rb_red_blk_node *)malloc(size);
}

static void
RBfree(rb_red_blk_node *ptr)
{
  free((char *)ptr);
}

static rb_red_blk_node *
RBTreeCreate(void) {
  rb_red_blk_node* temp;

  /*  see the comment in the rb_red_blk_tree structure in red_black_tree.h */
  /*  for information on nil and root */
  temp=ProfilerNil= RBMalloc(sizeof(rb_red_blk_node));
  temp->parent=temp->left=temp->right=temp;
  temp->pcs=0;
  temp->red=0;
  temp->key=temp->lim=NULL;
  temp->pe=NULL;
  temp = RBMalloc(sizeof(rb_red_blk_node));
  temp->parent=temp->left=temp->right=ProfilerNil;
  temp->key=temp->lim=NULL;
  temp->pe=NULL;
  temp->pcs=0;
  temp->red=0;
  return temp;
}

/* This is code originally written by Emin Martinian */

/***********************************************************************/
/*  FUNCTION:  LeftRotate */
/**/
/*  INPUTS:  This takes a tree so that it can access the appropriate */
/*           root and nil pointers, and the node to rotate on. */
/**/
/*  OUTPUT:  None */
/**/
/*  Modifies Input: tree, x */
/**/
/*  EFFECTS:  Rotates as described in _Introduction_To_Algorithms by */
/*            Cormen, Leiserson, Rivest (Chapter 14).  Basically this */
/*            makes the parent of x be to the left of x, x the parent of */
/*            its parent before the rotation and fixes other pointers */
/*            accordingly. */
/***********************************************************************/

static void
LeftRotate(rb_red_blk_node* x) {
  rb_red_blk_node* y;
  rb_red_blk_node* nil=ProfilerNil;

  /*  I originally wrote this function to use the sentinel for */
  /*  nil to avoid checking for nil.  However this introduces a */
  /*  very subtle bug because sometimes this function modifies */
  /*  the parent pointer of nil.  This can be a problem if a */
  /*  function which calls LeftRotate also uses the nil sentinel */
  /*  and expects the nil sentinel's parent pointer to be unchanged */
  /*  after calling this function.  For example, when RBDeleteFixUP */
  /*  calls LeftRotate it expects the parent pointer of nil to be */
  /*  unchanged. */

  y=x->right;
  x->right=y->left;

  if (y->left != nil) y->left->parent=x; /* used to use sentinel here */
  /* and do an unconditional assignment instead of testing for nil */
  
  y->parent=x->parent;   

  /* instead of checking if x->parent is the root as in the book, we */
  /* count on the root sentinel to implicitly take care of this case */
  if( x == x->parent->left) {
    x->parent->left=y;
  } else {
    x->parent->right=y;
  }
  y->left=x;
  x->parent=y;

#ifdef DEBUG_ASSERT
  Assert(!ProfilerNil->red,"nil not red in LeftRotate");
#endif
}


/***********************************************************************/
/*  FUNCTION:  RighttRotate */
/**/
/*  INPUTS:  This takes a tree so that it can access the appropriate */
/*           root and nil pointers, and the node to rotate on. */
/**/
/*  OUTPUT:  None */
/**/
/*  Modifies Input?: tree, y */
/**/
/*  EFFECTS:  Rotates as described in _Introduction_To_Algorithms by */
/*            Cormen, Leiserson, Rivest (Chapter 14).  Basically this */
/*            makes the parent of x be to the left of x, x the parent of */
/*            its parent before the rotation and fixes other pointers */
/*            accordingly. */
/***********************************************************************/

static void
RightRotate(rb_red_blk_node* y) {
  rb_red_blk_node* x;
  rb_red_blk_node* nil=ProfilerNil;

  /*  I originally wrote this function to use the sentinel for */
  /*  nil to avoid checking for nil.  However this introduces a */
  /*  very subtle bug because sometimes this function modifies */
  /*  the parent pointer of nil.  This can be a problem if a */
  /*  function which calls LeftRotate also uses the nil sentinel */
  /*  and expects the nil sentinel's parent pointer to be unchanged */
  /*  after calling this function.  For example, when RBDeleteFixUP */
  /*  calls LeftRotate it expects the parent pointer of nil to be */
  /*  unchanged. */

  x=y->left;
  y->left=x->right;

  if (nil != x->right)  x->right->parent=y; /*used to use sentinel here */
  /* and do an unconditional assignment instead of testing for nil */

  /* instead of checking if x->parent is the root as in the book, we */
  /* count on the root sentinel to implicitly take care of this case */
  x->parent=y->parent;
  if( y == y->parent->left) {
    y->parent->left=x;
  } else {
    y->parent->right=x;
  }
  x->right=y;
  y->parent=x;

#ifdef DEBUG_ASSERT
  Assert(!ProfilerNil->red,"nil not red in RightRotate");
#endif
}

/***********************************************************************/
/*  FUNCTION:  TreeInsertHelp  */
/**/
/*  INPUTS:  tree is the tree to insert into and z is the node to insert */
/**/
/*  OUTPUT:  none */
/**/
/*  Modifies Input:  tree, z */
/**/
/*  EFFECTS:  Inserts z into the tree as if it were a regular binary tree */
/*            using the algorithm described in _Introduction_To_Algorithms_ */
/*            by Cormen et al.  This funciton is only intended to be called */
/*            by the RBTreeInsert function and not by the user */
/***********************************************************************/

static void
TreeInsertHelp(rb_red_blk_node* z) {
  /*  This function should only be called by InsertRBTree (see above) */
  rb_red_blk_node* x;
  rb_red_blk_node* y;
  rb_red_blk_node* nil=ProfilerNil;
  
  z->left=z->right=nil;
  y=ProfilerRoot;
  x=ProfilerRoot->left;
  while( x != nil) {
    y=x;
    if (x->key > z->key) { /* x.key > z.key */
      x=x->left;
    } else { /* x,key <= z.key */
      x=x->right;
    }
  }
  z->parent=y;
  if ( (y == ProfilerRoot) ||
       (y->key > z->key)) { /* y.key > z.key */
    y->left=z;
  } else {
    y->right=z;
  }

#ifdef DEBUG_ASSERT
  Assert(!ProfilerNil->red,"nil not red in TreeInsertHelp");
#endif
}

/*  Before calling Insert RBTree the node x should have its key set */

/***********************************************************************/
/*  FUNCTION:  RBTreeInsert */
/**/
/*  INPUTS:  tree is the red-black tree to insert a node which has a key */
/*           pointed to by key and info pointed to by info.  */
/**/
/*  OUTPUT:  This function returns a pointer to the newly inserted node */
/*           which is guarunteed to be valid until this node is deleted. */
/*           What this means is if another data structure stores this */
/*           pointer then the tree does not need to be searched when this */
/*           is to be deleted. */
/**/
/*  Modifies Input: tree */
/**/
/*  EFFECTS:  Creates a node node which contains the appropriate key and */
/*            info pointers and inserts it into the tree. */
/***********************************************************************/

static rb_red_blk_node *
RBTreeInsert(yamop *key, yamop *lim) {
  rb_red_blk_node * y;
  rb_red_blk_node * x;
  rb_red_blk_node * newNode;

  x=(rb_red_blk_node*) RBMalloc(sizeof(rb_red_blk_node));
  x->key=key;
  x->lim=lim;

  TreeInsertHelp(x);
  newNode=x;
  x->red=1;
  while(x->parent->red) { /* use sentinel instead of checking for root */
    if (x->parent == x->parent->parent->left) {
      y=x->parent->parent->right;
      if (y->red) {
	x->parent->red=0;
	y->red=0;
	x->parent->parent->red=1;
	x=x->parent->parent;
      } else {
	if (x == x->parent->right) {
	  x=x->parent;
	  LeftRotate(x);
	}
	x->parent->red=0;
	x->parent->parent->red=1;
	RightRotate(x->parent->parent);
      } 
    } else { /* case for x->parent == x->parent->parent->right */
      y=x->parent->parent->left;
      if (y->red) {
	x->parent->red=0;
	y->red=0;
	x->parent->parent->red=1;
	x=x->parent->parent;
      } else {
	if (x == x->parent->left) {
	  x=x->parent;
	  RightRotate(x);
	}
	x->parent->red=0;
	x->parent->parent->red=1;
	LeftRotate(x->parent->parent);
      } 
    }
  }
  ProfilerRoot->left->red=0;
  return newNode;

#ifdef DEBUG_ASSERT
  Assert(!ProfilerNil->red,"nil not red in RBTreeInsert");
  Assert(!ProfilerRoot->red,"root not red in RBTreeInsert");
#endif
}

/***********************************************************************/
/*  FUNCTION:  RBExactQuery */
/**/
/*    INPUTS:  tree is the tree to print and q is a pointer to the key */
/*             we are searching for */
/**/
/*    OUTPUT:  returns the a node with key equal to q.  If there are */
/*             multiple nodes with key equal to q this function returns */
/*             the one highest in the tree */
/**/
/*    Modifies Input: none */
/**/
/***********************************************************************/
  
static rb_red_blk_node*
RBExactQuery(yamop* q) {
  rb_red_blk_node* x;
  rb_red_blk_node* nil=ProfilerNil;

  if (!ProfilerRoot) return NULL;
  x=ProfilerRoot->left;
  if (x == nil) return NULL;
  while(x->key != q) {/*assignemnt*/
    if (x->key > q) { /* x->key > q */
      x=x->left;
    } else {
      x=x->right;
    }
    if ( x == nil) return NULL;
  }
  return(x);
}


static rb_red_blk_node*
RBLookup(yamop *entry) {
  rb_red_blk_node *current;

  if (!ProfilerRoot)
    return NULL;
  current = ProfilerRoot->left;
  while (current != ProfilerNil) {
    if (current->key <= entry && current->lim >= entry) {
      return current;
    }
    if (entry > current->key)
      current = current->right;
    else
      current = current->left;
  }
  return NULL;
}


/***********************************************************************/
/*  FUNCTION:  RBDeleteFixUp */
/**/
/*    INPUTS:  tree is the tree to fix and x is the child of the spliced */
/*             out node in RBTreeDelete. */
/**/
/*    OUTPUT:  none */
/**/
/*    EFFECT:  Performs rotations and changes colors to restore red-black */
/*             properties after a node is deleted */
/**/
/*    Modifies Input: tree, x */
/**/
/*    The algorithm from this function is from _Introduction_To_Algorithms_ */
/***********************************************************************/

static void RBDeleteFixUp(rb_red_blk_node* x) {
  rb_red_blk_node* root=ProfilerRoot->left;
  rb_red_blk_node *w;

  while( (!x->red) && (root != x)) {
    if (x == x->parent->left) {
      w=x->parent->right;
      if (w->red) {
	w->red=0;
	x->parent->red=1;
	LeftRotate(x->parent);
	w=x->parent->right;
      }
      if ( (!w->right->red) && (!w->left->red) ) { 
	w->red=1;
	x=x->parent;
      } else {
	if (!w->right->red) {
	  w->left->red=0;
	  w->red=1;
	  RightRotate(w);
	  w=x->parent->right;
	}
	w->red=x->parent->red;
	x->parent->red=0;
	w->right->red=0;
	LeftRotate(x->parent);
	x=root; /* this is to exit while loop */
      }
    } else { /* the code below is has left and right switched from above */
      w=x->parent->left;
      if (w->red) {
	w->red=0;
	x->parent->red=1;
	RightRotate(x->parent);
	w=x->parent->left;
      }
      if ( (!w->right->red) && (!w->left->red) ) { 
	w->red=1;
	x=x->parent;
      } else {
	if (!w->left->red) {
	  w->right->red=0;
	  w->red=1;
	  LeftRotate(w);
	  w=x->parent->left;
	}
	w->red=x->parent->red;
	x->parent->red=0;
	w->left->red=0;
	RightRotate(x->parent);
	x=root; /* this is to exit while loop */
      }
    }
  }
  x->red=0;

#ifdef DEBUG_ASSERT
  Assert(!tree->nil->red,"nil not black in RBDeleteFixUp");
#endif
}



/***********************************************************************/
/*  FUNCTION:  TreeSuccessor  */
/**/
/*    INPUTS:  tree is the tree in question, and x is the node we want the */
/*             the successor of. */
/**/
/*    OUTPUT:  This function returns the successor of x or NULL if no */
/*             successor exists. */
/**/
/*    Modifies Input: none */
/**/
/*    Note:  uses the algorithm in _Introduction_To_Algorithms_ */
/***********************************************************************/
  
static rb_red_blk_node*
TreeSuccessor(rb_red_blk_node* x) { 
  rb_red_blk_node* y;
  rb_red_blk_node* nil=ProfilerNil;
  rb_red_blk_node* root=ProfilerRoot;

  if (nil != (y = x->right)) { /* assignment to y is intentional */
    while(y->left != nil) { /* returns the minium of the right subtree of x */
      y=y->left;
    }
    return(y);
  } else {
    y=x->parent;
    while(x == y->right) { /* sentinel used instead of checking for nil */
      x=y;
      y=y->parent;
    }
    if (y == root) return(nil);
    return(y);
  }
}

/***********************************************************************/
/*  FUNCTION:  RBDelete */
/**/
/*    INPUTS:  tree is the tree to delete node z from */
/**/
/*    OUTPUT:  none */
/**/
/*    EFFECT:  Deletes z from tree and frees the key and info of z */
/*             using DestoryKey and DestoryInfo.  Then calls */
/*             RBDeleteFixUp to restore red-black properties */
/**/
/*    Modifies Input: tree, z */
/**/
/*    The algorithm from this function is from _Introduction_To_Algorithms_ */
/***********************************************************************/

static void
RBDelete(rb_red_blk_node* z){
  rb_red_blk_node* y;
  rb_red_blk_node* x;
  rb_red_blk_node* nil=ProfilerNil;
  rb_red_blk_node* root=ProfilerRoot;

  y= ((z->left == nil) || (z->right == nil)) ? z : TreeSuccessor(z);
  x= (y->left == nil) ? y->right : y->left;
  if (root == (x->parent = y->parent)) { /* assignment of y->p to x->p is intentional */
    root->left=x;
  } else {
    if (y == y->parent->left) {
      y->parent->left=x;
    } else {
      y->parent->right=x;
    }
  }
  if (y != z) { /* y should not be nil in this case */

#ifdef DEBUG_ASSERT
    Assert( (y!=tree->nil),"y is nil in RBDelete\n");
#endif
    /* y is the node to splice out and x is its child */

    if (!(y->red)) RBDeleteFixUp(x);
  
    /* tree->DestroyKey(z->key);*/
    /*tree->DestroyInfo(z->info); */
    y->left=z->left;
    y->right=z->right;
    y->parent=z->parent;
    y->red=z->red;
    z->left->parent=z->right->parent=y;
    if (z == z->parent->left) {
      z->parent->left=y; 
    } else {
      z->parent->right=y;
    }
    RBfree(z); 
  } else {
    /*tree->DestroyKey(y->key);*/
    /*tree->DestroyInfo(y->info);*/
    if (!(y->red)) RBDeleteFixUp(x);
    RBfree(y);
  }
  
#ifdef DEBUG_ASSERT
  Assert(!tree->nil->red,"nil not black in RBDelete");
#endif
}

char *set_profile_dir(char *);
char *set_profile_dir(char *name){
int size=0;

    if (name!=NULL) {
      size=strlen(name)+1;
      if (DIRNAME!=NULL) free(DIRNAME);
      DIRNAME=malloc(size);
      if (DIRNAME==NULL) { printf("Profiler Out of Mem\n"); exit(1); }
      strcpy(DIRNAME,name);
    } 
    if (DIRNAME==NULL) {
      do {
        if (DIRNAME!=NULL) free(DIRNAME);
        size+=20;
        DIRNAME=malloc(size);
        if (DIRNAME==NULL) { printf("Profiler Out of Mem\n"); exit(1); }
      } while (getcwd(DIRNAME, size-15)==NULL); 
    }

return DIRNAME;
}

char *profile_names(int);
char *profile_names(int k) {
static char *FNAME=NULL;
int size=200;
   
  if (DIRNAME==NULL) set_profile_dir(NULL);
  size=strlen(DIRNAME)+40;
  if (FNAME!=NULL) free(FNAME);
  FNAME=malloc(size);
  if (FNAME==NULL) { printf("Profiler Out of Mem\n"); exit(1); }
  strcpy(FNAME,DIRNAME);

  if (k==PROFILING_FILE) {
    sprintf(FNAME,"%s/PROFILING_%d",FNAME,getpid());
  } else { 
    sprintf(FNAME,"%s/PROFPREDS_%d",FNAME,getpid());
  }

  //  printf("%s\n",FNAME);
  return FNAME;
}

void del_profile_files(void);
void del_profile_files() {
  if (DIRNAME!=NULL) {
    remove(profile_names(PROFPREDS_FILE));
    remove(profile_names(PROFILING_FILE));
  }
}

void
Yap_inform_profiler_of_clause(yamop *code_start, yamop *code_end, PredEntry *pe,int index_code) {
static Int order=0;
 
  ProfPreds++;
  ProfOn = TRUE;
  if (FPreds != NULL) {
    Int temp;

    order++;
    if (index_code) temp=-order; else temp=order;
    fprintf(FPreds,"+%p %p %p %ld\n",code_start,code_end, pe, (long int)temp);
  }
  ProfOn = FALSE;
}

typedef struct clause_entry {
  yamop *beg, *end;
  PredEntry *pp;
  UInt pcs;  /* counter with total for each clause */
  UInt pca;  /* counter with total for each predicate (repeated for each clause)*/  
  int ts;    /* start end timestamp towards retracts, eventually */
} clauseentry;

static Int profend(void); 

static void
clean_tree(rb_red_blk_node* node) {
  if (node == ProfilerNil)
    return;
  clean_tree(node->left);
  clean_tree(node->right);
  Yap_FreeCodeSpace((char *)node);
}

static void
reset_tree(void) {
  clean_tree(ProfilerRoot);
  Yap_FreeCodeSpace((char *)ProfilerNil);
  ProfilerNil = ProfilerRoot = NULL;
  ProfCalls = ProfGCs = ProfHGrows = ProfSGrows = ProfMallocs = ProfOns = 0L;
}

static int
InitProfTree(void)
{
  if (ProfilerRoot) 
    reset_tree();
  while (!(ProfilerRoot = RBTreeCreate())) {
    if (!Yap_growheap(FALSE, 0, NULL)) {
      Yap_Error(OUT_OF_HEAP_ERROR, TermNil, "while initialisating profiler");
      return FALSE;
    }    
  }
  return TRUE;
}

static void LookupNode(yamop *current_p) {
  rb_red_blk_node *node;

  if ((node = RBLookup(current_p))) {
    node->pcs++;
    return;
  } else {
    PredEntry *pp = NULL;
    CODEADDR start, end;

    pp = Yap_PredEntryForCode(current_p, FIND_PRED_FROM_ANYWHERE, &start, &end);
    if (!pp) {
#if DEBUG
      fprintf(stderr,"lost %p, %d\n", P, Yap_op_from_opcode(P->opc));
#endif
      /* lost profiler event !! */
      return;
    }
#if !USE_SYSTEM_MALLOC
    /* add this clause as new node to the tree */
    if (start < (CODEADDR)Yap_HeapBase || start > (CODEADDR)HeapTop ||
	end < (CODEADDR)Yap_HeapBase || end > (CODEADDR)HeapTop) {
#if DEBUG
      fprintf(stderr,"Oops2: %p->%lu %p, %p\n", current_p, (unsigned long int)(current_p->opc), start, end);
#endif
      return;
    }
#endif
    if (pp->ArityOfPE > 100) {
#if DEBUG
      fprintf(stderr,"%p(%lu)-->%p\n",current_p,(unsigned long int)Yap_op_from_opcode(current_p->opc),pp);
#endif
     return;
    }
    node = RBTreeInsert((yamop *)start, (yamop *)end);
    node->pe = pp;
    node->pcs = 1;
  }
}

static void RemoveCode(CODEADDR clau)
{
  rb_red_blk_node* x, *node;
  PredEntry *pp;
  UInt count;

  if (!ProfilerRoot) return;
  if (!(x = RBExactQuery((yamop *)clau))) {
    /* send message */
    ProfOn = FALSE;
    return;
  }
  pp = x->pe;
  count = x->pcs;
  RBDelete(x);
  /* use a single node to represent all deleted clauses */
  if (!(node = RBExactQuery((yamop *)(pp->OpcodeOfPred)))) {
    node = RBTreeInsert((yamop *)(pp->OpcodeOfPred), NEXTOP((yamop *)(pp->OpcodeOfPred),e));
    node->lim = (yamop *)pp;
    node->pe = pp;
    node->pcs = count;
    /* send message */
    ProfOn = FALSE;
    return;
  } else {
    node->pcs += count;
  }  
}

#define MAX_LINE_SIZE 1024

static int
showprofres(void) { 
  char line[MAX_LINE_SIZE];
  yamop *pr_beg, *pr_end;
  PredEntry *pr_pp;
  long int pr_count;
  

  profend(); /* Make sure profiler has ended */

  /* First part: Read information about predicates and store it on yap trail */

  InitProfTree();
  FProf=fopen(profile_names(PROFILING_FILE),"r"); 
  if (FProf==NULL) { fclose(FProf); return FALSE; }
  while (fgets(line, MAX_LINE_SIZE, FProf) != NULL) {
    if (line[0] == '+') {
      rb_red_blk_node *node;
      sscanf(line+1,"%p %p %p %ld",&pr_beg,&pr_end,&pr_pp,&pr_count);
      node = RBTreeInsert(pr_beg, pr_end);
      node->pe = pr_pp;
      node->pcs = 0;
    } else if  (line[0] == '-') {
      sscanf(line+1,"%p",&pr_beg);
      RemoveCode((CODEADDR)pr_beg);
    } else {
      rb_red_blk_node *node;

      sscanf(line,"%p",&pr_beg);
      node = RBLookup(pr_beg);
      if (!node) {
#if DEBUG
	fprintf(stderr,"Oops: %p\n", pr_beg);
#endif
      } else {
	node->pcs++; 
      }
    }
  }
  fclose(FProf);
  if (ProfCalls==0) 
    return TRUE;
  return TRUE;
}

static Int
p_test(void) { 
  char line[MAX_LINE_SIZE];
  yamop *pr_beg, *pr_end;
  PredEntry *pr_pp;
  long int pr_count;


  profend(); /* Make sure profiler has ended */

  /* First part: Read information about predicates and store it on yap trail */

  InitProfTree();
  FProf=fopen("PROFILING_93920","r"); 
  if (FProf==NULL) { fclose(FProf); return FALSE; }
  while (fgets(line, MAX_LINE_SIZE, FProf) != NULL) {
    if (line[0] == '+') {
      rb_red_blk_node *node;
      sscanf(line+1,"%p %p %p %ld",&pr_beg,&pr_end,&pr_pp,&pr_count);
      node = RBTreeInsert(pr_beg, pr_end);
      node->pe = pr_pp;
      node->pcs = 0;
    } else if  (line[0] == '-') {
      sscanf(line+1,"%p",&pr_beg);
      RemoveCode((CODEADDR)pr_beg);
    } else {
      rb_red_blk_node *node = RBTreeInsert(pr_beg, pr_end);
      node->pe = pr_pp;
      node->pcs = 1;
    }
  }
  fclose(FProf);
  if (ProfCalls==0) 
    return TRUE;
  return TRUE;
}


#define TestMode (GCMode | GrowHeapMode | GrowStackMode | ErrorHandlingMode | InErrorMode | AbortMode | MallocMode)


static void
prof_alrm(int signo, siginfo_t *si, void *scv)
{
  void * oldpc=(void *) CONTEXT_PC(scv);
  yamop *current_p;

  ProfCalls++;
  /* skip an interrupt */
  if (ProfOn) {
    ProfOns++;
    return;
  }
  ProfOn = TRUE;
  if (Yap_PrologMode & TestMode) {
    if (Yap_PrologMode & GCMode) {
      ProfGCs++;
      ProfOn = FALSE;
      return;
    }

    if (Yap_PrologMode & MallocMode) {
      ProfMallocs++;
      ProfOn = FALSE;
      return;
    }

    if (Yap_PrologMode & GrowHeapMode) {
      ProfHGrows++;
      ProfOn = FALSE;
      return;
    }
  
    if (Yap_PrologMode & GrowStackMode) {
      ProfSGrows++;
      ProfOn = FALSE;
      return;
    }
   
  }
  
  
  if (oldpc>(void *) &Yap_absmi && oldpc <= (void *) &Yap_absmiEND) { 
    /* we are running emulator code */
#if BP_FREE
    current_p =(yamop *) CONTEXT_BP(scv);
#else
    current_p = P;
#endif
  } else {
    op_numbers oop = Yap_op_from_opcode(PREVOP(P,Osbpp)->opc);
    
    if (oop == _call_cpred || oop == _call_usercpred) {
      /* doing C-code */
      current_p = PREVOP(P,Osbpp)->u.Osbpp.p->CodeOfPred;
    } else if ((oop = Yap_op_from_opcode(PREVOP(P,pp)->opc)) == _execute_cpred) {
      /* doing C-code */
      current_p = PREVOP(P,pp)->u.pp.p->CodeOfPred;
    } else {
      current_p = P;
    }
  }

#if !USE_SYSTEM_MALLOC
  if (P < (yamop *)Yap_HeapBase || P > (yamop *)HeapTop) {
#if DEBUG
    fprintf(stderr,"Oops: %p, %p\n", oldpc, current_p);
#endif
    ProfOn = FALSE;
    return;
  }
#endif

  if (Yap_OffLineProfiler) {
    fprintf(FProf,"%p\n", current_p);
    ProfOn = FALSE;
    return;
  }

  LookupNode(current_p);
  ProfOn = FALSE;
}


void
Yap_InformOfRemoval(CODEADDR clau)
{
  ProfOn = TRUE;
  if (FPreds != NULL) {
    /* just store info about what is going on  */
    fprintf(FPreds,"-%p\n",clau);
    ProfOn = FALSE;
    return;
  }
  RemoveCode(clau);
  ProfOn = FALSE;
}

static Int profend(void); 

static Int
profnode(void) {
  Term t1 = Deref(ARG1), tleft, tright;
  rb_red_blk_node *node;

  if (!ProfilerRoot)
    return FALSE;
  if (!(node = (rb_red_blk_node *)IntegerOfTerm(t1)))
    node = ProfilerRoot;
  /*
    if (node->key)
    fprintf(stderr,"%p: %p,%p,%d,%p(%d),%p,%p\n",node,node->key,node->lim,node->pcs,node->pe,node->pe->ArityOfPE,node->right,node->left);
  */
  if (node->left == ProfilerNil) {
    tleft = TermNil;
  } else {
    tleft = MkIntegerTerm((Int)node->left);
  }
  if (node->left == ProfilerNil) {
    tleft = TermNil;
  } else {
    tleft = MkIntegerTerm((Int)node->left);
  }
  if (node->right == ProfilerNil) {
    tright = TermNil;
  } else {
    tright = MkIntegerTerm((Int)node->right);
  }
  return 
    Yap_unify(ARG2,MkIntegerTerm((Int)node->key)) &&
    Yap_unify(ARG3,MkIntegerTerm((Int)node->pe)) &&
    Yap_unify(ARG4,MkIntegerTerm((Int)node->pcs)) &&
    Yap_unify(ARG5,tleft) &&
    Yap_unify(ARG6,tright);
}

static Int
profglobs(void) {
  return 
    Yap_unify(ARG1,MkIntegerTerm(ProfCalls)) &&
    Yap_unify(ARG2,MkIntegerTerm(ProfGCs)) &&
    Yap_unify(ARG3,MkIntegerTerm(ProfHGrows)) &&
    Yap_unify(ARG4,MkIntegerTerm(ProfSGrows)) &&
    Yap_unify(ARG5,MkIntegerTerm(ProfMallocs)) &&
    Yap_unify(ARG6,MkIntegerTerm(ProfOns)) ;
}

static Int
do_profinit(void)
{
  if (Yap_OffLineProfiler) {
    //    FPreds=fopen(profile_names(PROFPREDS_FILE),"w+"); 
    // if (FPreds == NULL) return FALSE;
    FProf=fopen(profile_names(PROFILING_FILE),"w+"); 
    if (FProf==NULL) { fclose(FProf); return FALSE; }
    FPreds = FProf;

    Yap_dump_code_area_for_profiler();
  } else {
    InitProfTree();
  }
  return TRUE;
}

static Int profinit(void)
{
  if (ProfilerOn!=0) return (FALSE);
  
  if (!do_profinit())
    return FALSE;

  ProfilerOn = -1; /* Inited but not yet started */
  return(TRUE);
}

static Int profinit1(void)
{
  Term t = Deref(ARG1);

  if (IsVarTerm(t)) {
    if (Yap_OffLineProfiler) 
      Yap_unify(ARG1,MkAtomTerm(AtomOffline));
    else
      Yap_unify(ARG1,MkAtomTerm(AtomOnline));
  } else if (IsAtomTerm(t)) {
    char *name = RepAtom(AtomOfTerm(t))->StrOfAE;
    if (!strcmp(name,"offline"))
      Yap_OffLineProfiler = TRUE;
    else if (!strcmp(name,"online"))
      Yap_OffLineProfiler = FALSE;
    else {
      Yap_Error(DOMAIN_ERROR_OUT_OF_RANGE,t,"profinit only allows offline,online");
      return FALSE;
    }
  } else {
      Yap_Error(TYPE_ERROR_ATOM,t,"profinit only allows offline,online");
      return FALSE;
  }
  return profinit();
}


static Int proftype(void)
{
  if (Yap_OffLineProfiler) 
    return Yap_unify(ARG1,MkAtomTerm(AtomOffline));
  else
    return Yap_unify(ARG1,MkAtomTerm(AtomOnline));
}

static Int start_profilers(int msec)
{
  struct itimerval t;
  struct sigaction sa;
  
  if (ProfilerOn!=-1) {
    if (Yap_OffLineProfiler) {
      return FALSE; /* have to go through profinit */
    } else {
      if (!do_profinit())
	return FALSE;
    }
  }
  sa.sa_sigaction=prof_alrm;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags=SA_SIGINFO;
  if (sigaction(SIGPROF,&sa,NULL)== -1) return FALSE;
//  if (signal(SIGPROF,prof_alrm) == SIG_ERR) return FALSE;

  t.it_interval.tv_sec=0;
  t.it_interval.tv_usec=msec;
  t.it_value.tv_sec=0;
  t.it_value.tv_usec=msec;
  setitimer(ITIMER_PROF,&t,NULL);

  ProfilerOn = msec;
  return TRUE;
}


static Int profoff(void) {
  if (ProfilerOn>0) {
    setitimer(ITIMER_PROF,NULL,NULL);
    ProfilerOn = -1;
    return TRUE;
  }
  return FALSE;
}

static Int profon(void) { 
  Term p;
  profoff();
  p=Deref(ARG1);
  return(start_profilers(IntOfTerm(p)));
}

static Int profon0(void) { 
  profoff();
  return(start_profilers(TIMER_DEFAULT));
}

static Int profison(void) {
  return (ProfilerOn > 0);
}

static Int profalt(void) { 
  if (ProfilerOn==0) return(FALSE);
  if (ProfilerOn==-1) return profon();
  return profoff();
}

static Int profend(void) 
{
  if (ProfilerOn==0) return(FALSE);
  profoff();         /* Make sure profiler is off */
  ProfilerOn=0;
  if (Yap_OffLineProfiler) {
    fclose(FProf);
  }
  return TRUE;
}

static Int getpredinfo(void) 
{
  PredEntry *pp = (PredEntry *)IntegerOfTerm(Deref(ARG1));
  Term mod, name;
  UInt arity;

  if (!pp)
    return FALSE;
  if (pp->ModuleOfPred == PROLOG_MODULE)
    mod = TermProlog;
  else
    mod = pp->ModuleOfPred;
  if (pp->ModuleOfPred == IDB_MODULE) {
    if (pp->PredFlags & NumberDBPredFlag) {
      arity = 0;
      name = MkIntegerTerm(pp->src.IndxId);
    } else  if (pp->PredFlags & AtomDBPredFlag) {
      arity = 0;
      name = MkAtomTerm((Atom)pp->FunctorOfPred);
    } else {
      name = MkAtomTerm(NameOfFunctor(pp->FunctorOfPred));
      arity = ArityOfFunctor(pp->FunctorOfPred);
    }
  } else {
    arity = pp->ArityOfPE;
    if (pp->ArityOfPE) {
      name = MkAtomTerm(NameOfFunctor(pp->FunctorOfPred));
    } else {
      name = MkAtomTerm((Atom)(pp->FunctorOfPred));
    }  
  }
  return Yap_unify(ARG2, mod) &&
    Yap_unify(ARG3, name) &&
    Yap_unify(ARG4, MkIntegerTerm(arity));
}

static Int profres0(void) { 
  return(showprofres());
}

#endif /* LOW_PROF */

void
Yap_InitLowProf(void)
{
#if LOW_PROF
  ProfCalls = 0;
  ProfilerOn = FALSE;
  Yap_OffLineProfiler = FALSE;
  Yap_InitCPred("profinit",0, profinit, SafePredFlag);
  Yap_InitCPred("profinit",1, profinit1, SafePredFlag);
  Yap_InitCPred("$proftype",1, proftype, SafePredFlag);
  Yap_InitCPred("profend" ,0, profend, SafePredFlag);
  Yap_InitCPred("profon" , 0, profon0, SafePredFlag);
  Yap_InitCPred("profon" , 1, profon, SafePredFlag);
  Yap_InitCPred("profoff", 0, profoff, SafePredFlag);
  Yap_InitCPred("profalt", 0, profalt, SafePredFlag);
  Yap_InitCPred("$offline_showprofres", 0, profres0, SafePredFlag);
  Yap_InitCPred("$profnode", 6, profnode, SafePredFlag);
  Yap_InitCPred("$profglobs", 6, profglobs, SafePredFlag);
  Yap_InitCPred("$profison",0 , profison, SafePredFlag);
  Yap_InitCPred("$get_pred_pinfo", 4, getpredinfo, SafePredFlag);
  Yap_InitCPred("showprofres", 4, getpredinfo, SafePredFlag);
  Yap_InitCPred("prof_test", 0, p_test, 0);
#endif
}
