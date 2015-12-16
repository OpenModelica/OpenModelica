/*
 * DIRENT.H (formerly DIRLIB.H)
 *
 * by M. J. Weinstein   Released to public domain 1-Jan-89
 *
 * Because I have heard that this feature (opendir, readdir, closedir)
 * it so useful for programmers coming from UNIX or attempting to port
 * UNIX code, and because it is reasonably light weight, I have included
 * it in the Mingw32 package. I have also added an implementation of
 * rewinddir, seekdir and telldir.
 *   - Colin Peters <colin@bird.fu.is.saga-u.ac.jp>
 *
 *  This code is distributed in the hope that is will be useful but
 *  WITHOUT ANY WARRANTY. ALL WARRANTIES, EXPRESS OR IMPLIED ARE HEREBY
 *  DISCLAIMED. This includeds but is not limited to warranties of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * Martin Otter, 2001/01/06:
 *    Removed:   #ifndef __STRICT_ANSI__
 *               #include <_mingw.h>
 *    since not needed in Modelica
 */

#ifndef _DIRENT_H_
#define _DIRENT_H_

#include <io.h>

#ifdef __cplusplus
extern "C" {
#endif

struct dirent
{
 long  d_ino;          /* Always zero. */
 unsigned short d_reclen;   /* Always zero. */
 unsigned short d_namlen;   /* Length of name in d_name. */
 char*  d_name;          /* File name. */
 /* NOTE: The name in the dirent structure points to the name in the
  *       finddata_t structure in the DIR. */
};

/*
 * This is an internal data structure. Good programmers will not use it
 * except as an argument to one of the functions below.
 */
typedef struct
{
 /* disk transfer area for this dir */
 struct _finddata_t dd_dta;

 /* dirent struct to return from dir (NOTE: this makes this thread
  * safe as long as only one thread uses a particular DIR struct at
  * a time) */
 struct dirent  dd_dir;

 /* _findnext handle */
 long   dd_handle;

 /*
         * Status of search:
  *   0 = not started yet (next entry to read is first entry)
  *  -1 = off the end
  *   positive = 0 based index of next entry
  */
 short   dd_stat;

 /* given path for dir with search pattern (struct is extended) */
 char   dd_name[1];
} DIR;


DIR*  opendir (const char*);
struct dirent* readdir (DIR*);
int  closedir (DIR*);
void  rewinddir (DIR*);
long  telldir (DIR*);
void  seekdir (DIR*, long);

#ifdef __cplusplus
}
#endif

#endif /* Not _DIRENT_H_ */
