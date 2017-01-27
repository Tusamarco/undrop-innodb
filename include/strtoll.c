/* Copyright (C) 2000 MySQL AB

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; version 2 of the License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

/* This implements strtoll() if needed */


/*
   These includes are mandatory because they check for type sizes and
   functions, especially they handle tricks for Tru64 where 'long' is
   64 bit already and our 'longlong' is just a 'long'.
   This solves a problem on Tru64 where the C99 compiler has a prototype
   for 'strtoll()' but no implementation, see "6.1 New C99 library functions" 
   in file '/usr/share/doclib/cc.dtk/release_notes.txt'.
 */
#include <my_global.h>
#include <m_string.h>

#if !defined(HAVE_STRTOLL) && defined(HAVE_LONG_LONG)
#define USE_LONGLONG
#include "strto.c"
#endif
