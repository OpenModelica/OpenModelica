/* Exact-width integer types
 * Portable Snippets - https://gitub.com/nemequ/portable-snippets
 * Created by Evan Nemerson <evan@nemerson.com>
 *
 *   To the extent possible under law, the authors have waived all
 *   copyright and related or neighboring rights to this code.  For
 *   details, see the Creative Commons Zero 1.0 Universal license at
 *   https://creativecommons.org/publicdomain/zero/1.0/
 *
 * This header tries to define psnip_(u)int(8|16|32|64)_t to
 * appropriate types given your system.  For most systems this means
 * including <stdint.h> and adding a few preprocessor definitions.
 *
 * If you prefer, you can define any necessary types yourself.
 * Snippets in this repository which rely on these types will not
 * attempt to include this header if you have already defined the
 * types it uses.
 */

#if !defined(PSNIP_EXACT_INT_H)
#  define PSNIP_EXACT_INT_H
#  if !defined(PSNIP_EXACT_INT_HAVE_STDINT)
#    if defined(_STDC_VERSION__) && (__STDC_VERSION__ >= 199901L)
#      define PSNIP_EXACT_INT_HAVE_STDINT
#    elif defined(__has_include)
#      if __has_include(<stdint.h>)
#        define PSNIP_EXACT_INT_HAVE_STDINT
#      endif
#    elif \
      defined(HAVE_STDINT_H) || \
      defined(_STDINT_H_INCLUDED) || \
      defined(_STDINT_H) || \
      defined(_STDINT_H_)
#      define PSNIP_EXACT_INT_HAVE_STDINT
#    elif \
      (defined(__GNUC__) && ((__GNUC__ > 4) || (__GNUC__ == 4 && __GNUC_MINOR__ >= 5))) || \
      (defined(_MSC_VER) && (_MSC_VER >= 1600)) || \
      (defined(__SUNPRO_C) && (__SUNPRO_C >= 0x570)) || \
      (defined(__WATCOMC__) && (__WATCOMC__ >= 1250))
#      define PSNIP_EXACT_INT_HAVE_STDINT
#    endif
#  endif

#  if \
  defined(__INT8_TYPE__) && defined(__INT16_TYPE__) && defined(__INT32_TYPE__) && defined(__INT64_TYPE__) && \
  defined(__UINT8_TYPE__) && defined(__UINT16_TYPE__) && defined(__UINT32_TYPE__) && defined(__UINT64_TYPE__)
#    define psnip_int8_t   __INT8_TYPE__
#    define psnip_int16_t  __INT16_TYPE__
#    define psnip_int32_t  __INT32_TYPE__
#    define psnip_int64_t  __INT64_TYPE__
#    define psnip_uint8_t  __UINT8_TYPE__
#    define psnip_uint16_t __UINT16_TYPE__
#    define psnip_uint32_t __UINT32_TYPE__
#    define psnip_uint64_t __UINT64_TYPE__
#  elif defined(PSNIP_EXACT_INT_HAVE_STDINT)
#    include <stdint.h>
#    if !defined(psnip_int8_t)
#      define psnip_int8_t int8_t
#    endif
#    if !defined(psnip_uint8_t)
#      define psnip_uint8_t uint8_t
#    endif
#    if !defined(psnip_int16_t)
#      define psnip_int16_t int16_t
#    endif
#    if !defined(psnip_uint16_t)
#      define psnip_uint16_t uint16_t
#    endif
#    if !defined(psnip_int32_t)
#      define psnip_int32_t int32_t
#    endif
#    if !defined(psnip_uint32_t)
#      define psnip_uint32_t uint32_t
#    endif
#    if !defined(psnip_int64_t)
#      define psnip_int64_t int64_t
#    endif
#    if !defined(psnip_uint64_t)
#      define psnip_uint64_t uint64_t
#    endif
#  elif defined(_MSC_VER)
#    if !defined(psnip_int8_t)
#      define psnip_int8_t __int8
#    endif
#    if !defined(psnip_uint8_t)
#      define psnip_uint8_t unsigned __int8
#    endif
#    if !defined(psnip_int16_t)
#      define psnip_int16_t __int16
#    endif
#    if !defined(psnip_uint16_t)
#      define psnip_uint16_t unsigned __int16
#    endif
#    if !defined(psnip_int32_t)
#      define psnip_int32_t __int32
#    endif
#    if !defined(psnip_uint32_t)
#      define psnip_uint32_t unsigned __int32
#    endif
#    if !defined(psnip_int64_t)
#      define psnip_int64_t __int64
#    endif
#    if !defined(psnip_uint64_t)
#      define psnip_uint64_t unsigned __int64
#    endif
#  else
#    include <limits.h>
#    if !defined(psnip_int8_t)
#      if defined(CHAR_MIN) && defined(CHAR_MAX) && (CHAR_MIN == (-127-1)) && (CHAR_MAX == 127)
#        define psnip_int8_t char
#      elif defined(SHRT_MIN) && defined(SHRT_MAX) && (SHRT_MIN == (-127-1)) && (SHRT_MAX == 127)
#        define psnip_int8_t short
#      elif defined(INT_MIN) && defined(INT_MAX) && (INT_MIN == (-127-1)) && (INT_MAX == 127)
#        define psnip_int8_t int
#      elif defined(LONG_MIN) && defined(LONG_MAX) && (LONG_MIN == (-127-1)) && (LONG_MAX == 127)
#        define psnip_int8_t long
#      elif defined(LLONG_MIN) && defined(LLONG_MAX) && (LLONG_MIN == (-127-1)) && (LLONG_MAX == 127)
#        define psnip_int8_t long long
#      else
#        error Unable to locate 8-bit signed integer type.
#      endif
#    endif
#    if !defined(psnip_uint8_t)
#      if defined(UCHAR_MAX) && (UCHAR_MAX == 255)
#        define psnip_uint8_t unsigned char
#      elif defined(USHRT_MAX) && (USHRT_MAX == 255)
#        define psnip_uint8_t unsigned short
#      elif defined(UINT_MAX) && (UINT_MAX == 255)
#        define psnip_uint8_t unsigned int
#      elif defined(ULONG_MAX) && (ULONG_MAX == 255)
#        define psnip_uint8_t unsigned long
#      elif defined(ULLONG_MAX) && (ULLONG_MAX == 255)
#        define psnip_uint8_t unsigned long long
#      else
#        error Unable to locate 8-bit unsigned integer type.
#      endif
#    endif
#    if !defined(psnip_int16_t)
#      if defined(CHAR_MIN) && defined(CHAR_MAX) && (CHAR_MIN == (-32767-1)) && (CHAR_MAX == 32767)
#        define psnip_int16_t char
#      elif defined(SHRT_MIN) && defined(SHRT_MAX) && (SHRT_MIN == (-32767-1)) && (SHRT_MAX == 32767)
#        define psnip_int16_t short
#      elif defined(INT_MIN) && defined(INT_MAX) && (INT_MIN == (-32767-1)) && (INT_MAX == 32767)
#        define psnip_int16_t int
#      elif defined(LONG_MIN) && defined(LONG_MAX) && (LONG_MIN == (-32767-1)) && (LONG_MAX == 32767)
#        define psnip_int16_t long
#      elif defined(LLONG_MIN) && defined(LLONG_MAX) && (LLONG_MIN == (-32767-1)) && (LLONG_MAX == 32767)
#        define psnip_int16_t long long
#      else
#        error Unable to locate 16-bit signed integer type.
#      endif
#    endif
#    if !defined(psnip_uint16_t)
#      if defined(UCHAR_MAX) && (UCHAR_MAX == 65535)
#        define psnip_uint16_t unsigned char
#      elif defined(USHRT_MAX) && (USHRT_MAX == 65535)
#        define psnip_uint16_t unsigned short
#      elif defined(UINT_MAX) && (UINT_MAX == 65535)
#        define psnip_uint16_t unsigned int
#      elif defined(ULONG_MAX) && (ULONG_MAX == 65535)
#        define psnip_uint16_t unsigned long
#      elif defined(ULLONG_MAX) && (ULLONG_MAX == 65535)
#        define psnip_uint16_t unsigned long long
#      else
#        error Unable to locate 16-bit unsigned integer type.
#      endif
#    endif
#    if !defined(psnip_int32_t)
#      if defined(CHAR_MIN) && defined(CHAR_MAX) && (CHAR_MIN == (-2147483647-1)) && (CHAR_MAX == 2147483647)
#        define psnip_int32_t char
#      elif defined(SHRT_MIN) && defined(SHRT_MAX) && (SHRT_MIN == (-2147483647-1)) && (SHRT_MAX == 2147483647)
#        define psnip_int32_t short
#      elif defined(INT_MIN) && defined(INT_MAX) && (INT_MIN == (-2147483647-1)) && (INT_MAX == 2147483647)
#        define psnip_int32_t int
#      elif defined(LONG_MIN) && defined(LONG_MAX) && (LONG_MIN == (-2147483647-1)) && (LONG_MAX == 2147483647)
#        define psnip_int32_t long
#      elif defined(LLONG_MIN) && defined(LLONG_MAX) && (LLONG_MIN == (-2147483647-1)) && (LLONG_MAX == 2147483647)
#        define psnip_int32_t long long
#      else
#        error Unable to locate 32-bit signed integer type.
#      endif
#    endif
#    if !defined(psnip_uint32_t)
#      if defined(UCHAR_MAX) && (UCHAR_MAX == 4294967295)
#        define psnip_uint32_t unsigned char
#      elif defined(USHRT_MAX) && (USHRT_MAX == 4294967295)
#        define psnip_uint32_t unsigned short
#      elif defined(UINT_MAX) && (UINT_MAX == 4294967295)
#        define psnip_uint32_t unsigned int
#      elif defined(ULONG_MAX) && (ULONG_MAX == 4294967295)
#        define psnip_uint32_t unsigned long
#      elif defined(ULLONG_MAX) && (ULLONG_MAX == 4294967295)
#        define psnip_uint32_t unsigned long long
#      else
#        error Unable to locate 32-bit unsigned integer type.
#      endif
#    endif
#    if !defined(psnip_int64_t)
#      if defined(CHAR_MIN) && defined(CHAR_MAX) && (CHAR_MIN == (-9223372036854775807LL-1)) && (CHAR_MAX == 9223372036854775807LL)
#        define psnip_int64_t char
#      elif defined(SHRT_MIN) && defined(SHRT_MAX) && (SHRT_MIN == (-9223372036854775807LL-1)) && (SHRT_MAX == 9223372036854775807LL)
#        define psnip_int64_t short
#      elif defined(INT_MIN) && defined(INT_MAX) && (INT_MIN == (-9223372036854775807LL-1)) && (INT_MAX == 9223372036854775807LL)
#        define psnip_int64_t int
#      elif defined(LONG_MIN) && defined(LONG_MAX) && (LONG_MIN == (-9223372036854775807LL-1)) && (LONG_MAX == 9223372036854775807LL)
#        define psnip_int64_t long
#      elif defined(LLONG_MIN) && defined(LLONG_MAX) && (LLONG_MIN == (-9223372036854775807LL-1)) && (LLONG_MAX == 9223372036854775807LL)
#        define psnip_int64_t long long
#      else
#        error Unable to locate 64-bit signed integer type.
#      endif
#    endif
#    if !defined(psnip_uint64_t)
#      if defined(UCHAR_MAX) && (UCHAR_MAX == 18446744073709551615ULL)
#        define psnip_uint64_t unsigned char
#      elif defined(USHRT_MAX) && (USHRT_MAX == 18446744073709551615ULL)
#        define psnip_uint64_t unsigned short
#      elif defined(UINT_MAX) && (UINT_MAX == 18446744073709551615ULL)
#        define psnip_uint64_t unsigned int
#      elif defined(ULONG_MAX) && (ULONG_MAX == 18446744073709551615ULL)
#        define psnip_uint64_t unsigned long
#      elif defined(ULLONG_MAX) && (ULLONG_MAX == 18446744073709551615ULL)
#        define psnip_uint64_t unsigned long long
#      else
#        error Unable to locate 64-bit unsigned integer type.
#      endif
#    endif
#  endif
#endif
