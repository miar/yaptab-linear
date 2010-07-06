/* config.h.  Generated from config.h.in by configure.  */

#include "parms.h"

/* are we using gcc */
#define HAVE_GCC 1

/* should we use gcc threaded code (i.e. goto *adrs) */
#define USE_THREADED_CODE 1

/* Should we use lib readline ? 	*/
#define HAVE_LIBREADLINE 1

/* Should we use gmp ? 	*/
/* #undef HAVE_LIBGMP */

/* What MPI libraries are there? */
#define HAVE_LIBMPI 0
#define HAVE_LIBMPICH 0

/* Should we use MPI ? */
#if HAVE_LIBMPI || HAVE_LIBMPICH
#define HAVE_MPI 1
#else
#define HAVE_MPI 0
#endif

/* Is there an MPE library? */
#define HAVE_LIBMPE 0

/* Should we use MPE ? */
#if HAVE_LIBMPE &&  HAVE_MPI
#define HAVE_MPE 1
#else
#define HAVE_MPE 0
#endif

/* does the compiler support inline ? */
/* #undef inline */

/* Do we have Ansi headers ?		*/
/* #undef STDC_HEADERS */

/* Host Name ?				*/
#define HOST_ALIAS "i686-pc-linux-gnu"

/* #undef SUPPORT_CONDOR */
/* #undef SUPPORT_THREADS */
/* #undef USE_PTHREAD_LOCKING */

#define HAVE_SYS_WAIT_H 1
/* #undef NO_UNION_WAIT */

#define HAVE_ARPA_INET_H 1
#define HAVE_CTYPE_H 1
/* #undef HAVE_CUDD_H */
/* #undef HAVE_DIRECT_H */
#define HAVE_DIRENT_H 1
#define HAVE_DLFCN_H 1
#define HAVE_ERRNO_H 1
#define HAVE_FCNTL_H 1
#define HAVE_FENV_H 1
#define HAVE_FLOAT_H 1
#define HAVE_FPU_CONTROL_H 1
/* #undef HAVE_GMP_H */
/* #undef HAVE_IEEEFP_H */
/* #undef HAVE_IO_H */
#define HAVE_LIMITS_H 1
#define HAVE_LOCALE_H 1
/* #undef HAVE_MACH_O_DYLD_H */
#define HAVE_MALLOC_H 1
#define HAVE_MATH_H 1
#define HAVE_MEMORY_H 1
/* #undef HAVE_MPE_H */
/* #undef HAVE_MPI_H */
#define HAVE_NETDB_H 1
#define HAVE_NETINET_IN_H 1
/* #undef HAVE_PTHREAD_H */
#define HAVE_PWD_H 1
#define HAVE_READLINE_READLINE_H 1
#define HAVE_REGEX_H 1
/* #undef HAVE_SIGINFO_H */
#define HAVE_SIGNAL_H 1
#define HAVE_STDARG_H 1
#define HAVE_STRING_H 1
#define HAVE_STROPTS_H 1
/* #undef HAVE_SYS_CONF_H */
#define HAVE_SYS_FILE_H 1
#define HAVE_SYS_MMAN_H 1
#define HAVE_SYS_PARAM_H 1
#define HAVE_SYS_RESOURCE_H 1
#define HAVE_SYS_SELECT_H 1
#define HAVE_SYS_SHM_H 1
#define HAVE_SYS_SOCKET_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TIMES_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_UCONTEXT_H 1
#define HAVE_SYS_UN_H 1
#define HAVE_SYS_WAIT_H 1
#define HAVE_TIME_H 1
#define HAVE_UNISTD_H 1
#define HAVE_WCTYPE_H 1
/* #undef HAVE_WINSOCK_H */
/* #undef HAVE_WINSOCK2_H */

/* Do we have restartable syscalls */
#define HAVE_RESTARTABLE_SYSCALLS 1

/* is 'tms' defined in <sys/time.h> ? */
/* #undef TM_IN_SYS_TIME */

/* define type of prt returned by malloc: char or void */
#define MALLOC_T void *

/* Define byte order			*/
/* #undef WORDS_BIGENDIAN */

/* Define sizes of some basic types	*/
#define SIZEOF_INT_P 4
#define SIZEOF_INT 4
#define SIZEOF_SHORT_INT 2
#define SIZEOF_LONG_INT 4
#define SIZEOF_LONG_LONG_INT 8
#define SIZEOF_FLOAT 4
#define SIZEOF_DOUBLE 8

/* Define representation of floats      */
/* only one of the following shoud be set */
/* to add a new representation you must edit FloatOfTerm and MkFloatTerm
  in adtdefs.c
*/
#define FFIEEE 1
/*manual */
/* #undef FFVAX */

/* Define the standard type of a float argument to a function */
/*manual */
#define  FAFloat double	

/* Set the minimum and default heap, trail and stack size */
#define MinTrailSpace ( 48*SIZEOF_INT_P)
#define MinStackSpace (300*SIZEOF_INT_P)
#define MinHeapSpace (1000*SIZEOF_INT_P)

#define DefTrailSpace 0
#define DefStackSpace 0
#define DefHeapSpace 0


/* Define return type for signal	*/
#define RETSIGTYPE void

#define HAVE_ACCESS 1
#define HAVE_ACOSH 1
#define HAVE_ALARM 1
#define HAVE_ASINH 1
#define HAVE_ATANH 1
#define HAVE_CHDIR 1
#define HAVE_CTIME 1
#define HAVE_DLOPEN 1
#define HAVE_DUP2 1
#define HAVE_ERF 1
#define HAVE_FECLEAREXCEPT 1
/* #undef HAVE_FESETTRAPENABLE */
#define HAVE_FETESTEXCEPT 1
#define HAVE_FGETPOS 1
#define HAVE_FINITE 1
/* #undef HAVE_FPCLASS */
#define HAVE_FTIME 1
#define HAVE_GETCWD 1
#define HAVE_GETENV 1
#define HAVE_GETHOSTBYNAME 1
#define HAVE_GETHOSTID 1
#define HAVE_GETHOSTNAME 1
/* #undef HAVE_GETHRTIME */
#define HAVE_GETPAGESIZE 1
#define HAVE_GETPWNAM 1
#define HAVE_GETRUSAGE 1
#define HAVE_GETTIMEOFDAY 1
#define HAVE_GETWD 1
#define HAVE_ISATTY 1
#define HAVE_ISINF 1
#define HAVE_ISNAN 1
#define HAVE_KILL 1
#define HAVE_LABS 1
#define HAVE_LGAMMA 1
#define HAVE_LINK 1
#define HAVE_LOCALTIME 1
#define HAVE_LSTAT 1
#define HAVE_MALLINFO 1
#define HAVE_MBSNRTOWCS 1
#define HAVE_MEMCPY 1
#define HAVE_MEMMOVE 1
#define HAVE_MKSTEMP 1
#define HAVE_MKTEMP 1
#define HAVE_MKTIME 1
#define HAVE_MMAP 1
#define HAVE_NANOSLEEP 1
/* #undef HAVE_NSLINKMODULE */
#define HAVE_OPENDIR 1
#define HAVE_POPEN 1
/* #undef HAVE_PTHREAD_MUTEXATTR_SETKIND_NP */
/* #undef HAVE_PTHREAD_MUTEXATTR_SETTYPE */
#define HAVE_PUTENV 1
#define HAVE_RAND 1
#define HAVE_RANDOM 1
#define HAVE_READLINK 1
#define HAVE_REGEXEC 1
#define HAVE_RENAME 1
#define HAVE_RINT 1
#define HAVE_RL_SET_PROMPT 1
#define HAVE_SBRK 1
#define HAVE_SELECT 1
#define HAVE_SETBUF 1
#define HAVE_SETITIMER 1
#define HAVE_SETLINEBUF 1
/* #undef HAVE_SETLOCALE */
#define HAVE_SHMAT 1
#define HAVE_SIGACTION 1
#define HAVE_SIGGETMASK 1
#define HAVE_SIGINTERRUPT 1
#define HAVE_SIGNAL 1
#define HAVE_SIGPROCMASK 1
#define HAVE_SIGSETJMP 1
#define HAVE_SLEEP 1
#define HAVE_SNPRINTF 1
#define HAVE_SOCKET 1
#define HAVE_STAT 1
#define HAVE_STRCHR 1
#define HAVE_STRERROR 1
/* #undef HAVE_STRICMP */
#define HAVE_STRNCAT 1
#define HAVE_STRNCPY 1
#define HAVE_STRTOD 1
#define HAVE_SYSTEM 1
#define HAVE_TIME 1
#define HAVE_TIMES 1
#define HAVE_TMPNAM 1
#define HAVE_TTYNAME 1
#define HAVE_USLEEP 1
#define HAVE_VSNPRINTF 1
#define HAVE_WAITPID 1
#define HAVE_MPZ_XOR 0

#define HAVE_SIGINFO 1
#define HAVE_SIGSEGV 1
#define HAVE_SIGPROF 1

#define HAVE_ENVIRON 1

#define  SELECT_TYPE_ARG1    
#define  SELECT_TYPE_ARG234  
#define  SELECT_TYPE_ARG5    

#define  TYPE_SELECT_
#define  MYTYPE(X) MYTYPE1#X

/* define how to pass the address of a function */
#define FunAdr(Fn)  Fn

#define  ALIGN_LONGS 1
#define  LOW_ABSMI 0

#define  MSHIFTOFFS 1

#define USE_DL_MALLOC 1
/* #undef USE_MALLOC */
/* #undef USE_SYSTEM_MALLOC */
#define USE_MMAP    (HAVE_MMAP  & !USE_MALLOC & !USE_SYSTEM_MALLOC)
#define USE_SHM	    (HAVE_SHMAT & !HAVE_MMAP & !USE_MALLOC & !USE_SYSTEM_MALLOC)
#define USE_SBRK    (HAVE_SBRK  & !HAVE_MMAP & !HAVE_SHMAT & !USE_MALLOC & !USE_SYSTEM_MALLOC)

/* for OSes that do not allow user access to the first
   quadrant of the memory space */
/* #undef FORCE_SECOND_QUADRANT */

#if (HAVE_SOCKET || defined(__MINGW32__)) && !defined(SIMICS)
#define USE_SOCKET 1
#endif

#if defined(__hpux)
/* HP-UX requires extra definitions for X/Open networking */
/* #undef _XOPEN_SOURCE */
#define _XOPEN_SOURCE_EXTENDED 0
#endif

#if HAVE_GMP_H && HAVE_LIBGMP
#define USE_GMP 1
#endif

/* Should we use MPI ? */
#if defined(HAVE_MPI_H) && (HAVE_LIBMPI || HAVE_LIBMPICH)
 #define HAVE_MPI 1
#else
 #define HAVE_MPI 0
#endif

/* Should we use MPE ? */
#if defined(HAVE_MPI_H) && HAVE_LIBMPE &&  HAVE_MPI
 #define HAVE_MPE 1
#else
 #define HAVE_MPE 0
#endif

/* should we avoid realloc() in mpi.c? */
#define MPI_AVOID_REALLOC 0

/* Is fflush(NULL) clobbering input streams? */
#define BROKEN_FFLUSH_NULL 0

/* sunpro cc */
#ifdef __SUNPRO_CC
#ifdef HAVE_GCC
#define HAVE_GCC 1
#endif
#endif

#define GC_NO_TAGS 1

#define MAX_WORKERS (8*SIZEOF_INT_P)

#define MAX_THREADS 1



