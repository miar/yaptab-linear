/*  $Id$

    Part of SWI-Prolog

    Author:	Austin Appleby
    License:	Public domain
    See:	http://murmurhash.googlepages.com/
*/

#ifndef PL_HASH_H_INCLUDED
#define PL_HASH_H_INCLUDED

#define MURMUR_SEED	(0x1a3be34a)

unsigned int
	rdf_murmer_hash(const void *key, int len, unsigned int seed);

#endif /*PL_HASH_H_INCLUDED*/
