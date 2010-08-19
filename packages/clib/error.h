/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        jan@swi.psy.uva.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 1985-2002, University of Amsterdam

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

#ifndef H_ERROR_INCLUDED
#define H_ERROR_INCLUDED
#include <stdarg.h>

#define ERR_ERRNO		-1
#define ERR_TYPE		-2
#define ERR_ARGTYPE		-3
#define ERR_DOMAIN		-4
#define ERR_EXISTENCE		-5
#define ERR_PERMISSION		-6
#define ERR_NOTIMPLEMENTED	-7
#define ERR_RESOURCE		-8
#define ERR_SYNTAX		-9

int		pl_error(const char *name, int arity,
			 const char *msg, int id, ...);

#endif /*H_ERROR_INCLUDED*/
