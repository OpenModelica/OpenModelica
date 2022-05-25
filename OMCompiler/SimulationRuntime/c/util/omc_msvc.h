/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
#ifndef __OPENMODELICA_MSVC_H
#define __OPENMODELICA_MSVC_H

#ifdef __cplusplus
extern "C" {
#endif

#include <math.h> /* Make sure we try to get INFINITY and NAN from the system. They are way cooler */
/*For _MAX_PATH on MSVC */
#include <stdlib.h>

#ifndef NaN
#define NaN NAN
#endif

union MSVC_FLOAT_HACK
{
   unsigned char Bytes[4];
   float Value;
};
#ifndef INFINITY
static union MSVC_FLOAT_HACK __INFINITY = {{0x00, 0x00, 0x80, 0x7F}};
#define INFINITY (__INFINITY.Value)
#endif

#ifndef NAN
static union MSVC_FLOAT_HACK __NAN = {{0x00, 0x00, 0xC0, 0x7F}};
#define NAN (__NAN.Value)
#endif

/* for non GNU compilers */
#ifndef __GNUC__
#define __attribute__(x)
#endif

/* Compatibility header for MSVC compiler.
 * (Things that MinGW has but MSVC does not)
 */
#if defined(_MSC_VER)

#ifndef S_ISDIR
#define S_ISDIR(mode)  (((mode) & S_IFMT) == S_IFDIR)
#endif

#ifndef S_ISREG
#define S_ISREG(mode)  (((mode) & S_IFMT) == S_IFREG)
#endif

/* get rid of inline for MSVC */
#define OMC_INLINE

#ifndef WIN32
#define WIN32
#endif

#define geteuid(void) (-1)

#if _MSC_VER < 1800 /* VS 2013 */
#define round(dbl) ((dbl) < 0.0 ? ceil((dbl) - 0.5) : floor((dbl) + 0.5))
#define fmax(x, y) ((x>y)?x:y)
#define fmin(x, y) ((x<y)?x:y)
#define trunc(a) ((double)((int)(a)))
#endif

#define PATH_MAX _MAX_PATH
#include <stdarg.h>
char *realpath(const char *path, char *resolved_path);
int asprintf(char **strp, const char *fmt, ...);
int vasprintf(char **strp, const char *fmt, va_list ap);

unsigned int alarm (unsigned int seconds);

#include <float.h>
#if !defined(isinf)
#define isinf(d) (!_finite(d) && !_isnan(d))
#endif
#if !defined(isnan)
#define isnan _isnan
#endif
#define fpu_error(x) (isinf(x) || isnan(x))


#if _MSC_VER < 1900 /* VS 2015 */
#define snprintf sprintf_s
#if !defined(snprintf)
#define snprintf snprintf_s
#endif
#endif

#else /* not msvc */

/* define inline for non-MSVC */
#define OMC_INLINE inline

#endif /* end msvc */

#if defined(__MINGW32__)
#include <stdarg.h>
char *realpath(const char *path, char *resolved_path);
int asprintf(char **strp, const char *fmt, ...);
int vasprintf(char **strp, const char *fmt, va_list ap);
unsigned int alarm (unsigned int seconds);
#endif

#if (defined(__MINGW32__) || defined(_MSC_VER)) && !defined(OMC_MINIMAL_RUNTIME)

static int RTLD_LAZY __attribute__((unused)) = 0;

/** definition of the return data for dladdr().
 */
typedef struct {
  /** Filename of defining DLL or EXE */
  const char *dli_fname;

  /** Load address of the DLL or EXE that defines the object */
  void *dli_fbase;

  /** Name of nearest Symbol, string memory allocated possibly allocated
   *  on the heap. See #dli_salloc;
   */
  const char *dli_sname;

  /** Exact value of nearest symbol (Not implemented on Windows) */
  void *dli_saddr;

  /** Non-zero if the memory for dli_sname was allocated on the heap */
  int dli_salloc;

} Dl_info;

char* mkdtemp(char *tpl);
void* omc_dlopen(const char *filename, int flag);
char* omc_dlerror();
void* omc_dlsym(void *handle, const char *symbol);
int omc_dlclose(void *handle);
int omc_dladdr(void *addr, Dl_info *info);

void* dlopen(const char *filename, int flag);
char* dlerror();
void* dlsym(void *handle, const char *symbol);
int dlclose(void *handle);
int dladdr(void *addr, Dl_info *info);

#endif

#if defined(__MINGW32__) || defined(_MSC_VER)

#if defined(_MSC_VER)

#include <winsock2.h>
#if !defined(PATH_MAX)
#define PATH_MAX MAX_PATH
#endif
char *realpath(const char *path, char resolved_path[PATH_MAX]);

#include <direct.h> /* for getcwd */
#define getcwd _getcwd

#else

#include <limits.h>
#include <stdlib.h>

#endif



#endif

#ifdef __cplusplus
}
#endif

#endif
