/* strtod_l is considered a GNU extension.
 * It will fail if the correct prototype does not exist. */
#define _GNU_SOURCE 1

#include <stdlib.h>

#if (defined(_MSC_VER) && _MSC_VER >= 1400)

#include <locale.h>


_locale_t getCLocale()
{
  static int init = 0;
  static _locale_t loc;
  if (!init) {
    loc = _create_locale(LC_NUMERIC, "C");
    init = 1;
  }
  return loc;
}

double om_strtod(const char *nptr, char **endptr)
{
  return _strtod_l(nptr, endptr, getCLocale());
}

#elif (defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3)) || defined(__APPLE_CC__)

#if defined(__GLIBC__)
#include <locale.h>
#elif defined(__APPLE_CC__)
#include <xlocale.h>
#include <locale.h>
#endif

locale_t getCLocale()
{
  static int init = 0;
  static locale_t loc;
  if (!init) {
    loc = newlocale(LC_NUMERIC, "C", NULL);
    init = 1;
  }
  return loc;
}

double om_strtod(const char *nptr, char **endptr)
{
  return strtod_l(nptr, endptr, getCLocale());
}

#else

double om_strtod(const char *nptr, char **endptr)
{
  /* Default to just assuming we have the correct locale */
  return strtod(nptr, endptr);
}

#endif
