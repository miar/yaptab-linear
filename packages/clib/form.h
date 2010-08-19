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

#define MAXNAME 256

#define ERROR_NAME_TOO_LONG  -1
#define ERROR_SYNTAX_ERROR   -2
#define ERROR_NOMEM	     -3

#ifndef TRUE
#define TRUE 1
#define FALSE 0
#endif

typedef struct
{ char *ptr;
  char *name;
} form_arg;

/* form.c */
int		break_form_argument(const char *formdata,
				    int (*func)(const char *name,
						size_t namelen,
						const char *value,
						size_t valuelen,
						void *closure), void *closure);
int		break_multipart(char *formdata, size_t len,
				const char *boundary,
				int (*func)(const char *name,
					    size_t namelen,
					    const char *value,
					    size_t valuelen,
					    const char *filename,
					    void *closure),
				void *closure);
int		get_raw_form_data(char **data, size_t *lenp, int *must_free);
