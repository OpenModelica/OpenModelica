/**********************************************************************

  Taken from http://svn.ruby-lang.org/repos/ruby/trunk r45406

  The om_ prefix has been replaced with om_

  created at: Thu Mar  9 11:55:53 JST 1995

  Copyright (C) 1993-2007 Yukihiro Matsumoto

**********************************************************************/

#ifndef om_UTIL_H
#define om_UTIL_H 1

#if defined(__cplusplus)
extern "C" {
#if 0
} /* satisfy cc-mode */
#endif
#endif

#define DECIMAL_SIZE_OF_BITS(n) (((n) * 3010 + 9998) / 9999)
/* an approximation of ceil(n * log10(2)), upto 65536 at least */

unsigned long om_scan_oct(const char *, size_t, size_t *);
unsigned long om_scan_hex(const char *, size_t, size_t *);

void om_setenv(const char *, const char *);
void om_unsetenv(const char *);

char *om_strdup(const char *);

double om_strtod(const char *, char **);

#if defined _MSC_VER && _MSC_VER >= 1300
#pragma warning(push)
#pragma warning(disable:4723)
#endif
#if defined _MSC_VER && _MSC_VER >= 1300
#pragma warning(pop)
#endif

void om_each_words(const char *, void (*)(const char*, int, void*), void *);

#if defined(__cplusplus)
#if 0
{ /* satisfy cc-mode */
#endif
}  /* extern "C" { */
#endif

#endif /* om_UTIL_H */
