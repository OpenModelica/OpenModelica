/* ModelicaStrings.c - External functions for Modelica.Utilities.Strings

   Copyright (C) 2002-2020, Modelica Association and contributors
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

   3. Neither the name of the copyright holder nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
   DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
   FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
   CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
   OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/* Changelog:
      Jun. 16, 2017: by Thomas Beutlich, ESI ITI GmbH
                     Utilized hash macros of uthash.h for ModelicaStrings_hashString
                     (ticket #2250)

      Nov. 23, 2016: by Martin Sjoelund, SICS East Swedish ICT AB
                     Added NO_LOCALE define flag, in case the OS does
                     not have this (for example when using GCC compiler,
                     but not libc). Also added autoconf detection for
                     this flag, NO_PID, NO_TIME, and NO_FILE_SYSTEM

      Feb. 26, 2016: by Hans Olsson, DS AB
                     Build hash code on the unsigned characters in
                     ModelicaStrings_hashString (ticket #1926)

      Oct. 27, 2015: by Thomas Beutlich, ITI GmbH
                     Added nonnull attributes/annotations (ticket #1436)

      Oct. 05, 2015: by Thomas Beutlich, ITI GmbH
                     Added function ModelicaStrings_hashString from ModelicaRandom.c
                     of https://github.com/DLR-SR/Noise (ticket #1662)

      Mar. 26, 2013: by Martin Otter, DLR
                     Introduced three (int) casts to avoid warning messages (ticket #1032)

      Jan. 11, 2013: by Jesper Mattsson, Modelon AB
                     Made code C89 compatible

      Jan.  5, 2013: by Martin Otter, DLR
                     Removed "static" declarations from the Modelica interface functions

      Sep. 24, 2004: by Martin Otter, DLR
                     Final cleaning up of the code

      Sep.  9, 2004: by Dag Brueck, Dynasim AB
                     Implementation of scan functions

      Aug. 19, 2004: by Martin Otter, DLR
                     Changed according to the decisions of the 37th
                     design meeting in Lund (see minutes)

      Jan.  7, 2002: by Martin Otter, DLR
                     Implemented a first version
*/

#if defined(__gnu_linux__)
#define _GNU_SOURCE 1
#endif

#include "ModelicaStrings.h"

#include <ctype.h>
#include <string.h>
#if !defined(NO_LOCALE)
#include <locale.h>
#endif

#include "ModelicaUtilities.h"
#if !defined(HASH_FUNCTION)
#define HASH_FUNCTION HASH_AP
#endif
#include "uthash.h"
#undef uthash_fatal /* Ensure that nowhere in this file uses uthash_fatal by accident */

#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-compare"
#endif

_Ret_z_ const char* ModelicaStrings_substring(_In_z_ const char* string,
                                      int startIndex, int endIndex) {
    /* Return string1(startIndex:endIndex) if endIndex >= startIndex,
       or return string1(startIndex:startIndex), if endIndex = 0.
       An assert is triggered, if startIndex/endIndex are not valid.
     */
    char* substring;
    int len1 = (int) strlen(string);
    int len2;

    /* Check arguments */
    if ( startIndex < 1 ) {
        ModelicaFormatError("Wrong call of Utilities.Strings.substring:\n"
                            "  startIndex = %d (has to be > 0).\n"
                            "  string     = \"%s\"\n", startIndex, string);
    }
    else if ( endIndex == -999 ) {
        endIndex = startIndex;
    }
    else if ( endIndex < startIndex ) {
        ModelicaFormatError("Wrong call of  Utilities.Strings.substring:\n"
                            "  startIndex = %d\n"
                            "  endIndex   = %d (>= startIndex required)\n"
                            "  string     = \"%s\"\n", startIndex, endIndex, string);
    }
    else if ( endIndex > len1 ) {
        ModelicaFormatError("Wrong call of Utilities.Strings.substring:\n"
                            "  endIndex = %d (<= %d required (=length(string)).\n"
                            "  string   = \"%s\"\n", endIndex, len1, string);
    }

    /* Allocate memory and copy string */
    len2 = endIndex - startIndex + 1;
    substring = ModelicaAllocateString((size_t)len2);
    strncpy(substring, &string[startIndex-1], (size_t)len2);
    substring[len2] = '\0';
    return substring;
}

int ModelicaStrings_length(_In_z_ const char* string) {
    /* Return the number of characters "string" */
    return (int) strlen(string);
}

int ModelicaStrings_compare(_In_z_ const char* string1, _In_z_ const char* string2, int caseSensitive) {
    /* Compare two strings, optionally ignoring case */
    int result;
    if (string1 == 0 || string2 == 0) {
        return 2;
    }

    if (caseSensitive) {
        result = strcmp(string1, string2);
    }
    else {
        while (tolower((unsigned char)*string1) == tolower((unsigned char)*string2) && *string1 != '\0') {
            string1++;
            string2++;
        }
        result = (int)(tolower((unsigned char)*string1)) - (int)(tolower((unsigned char)*string2));
    }

    if ( result < 0 ) {
        result = 1;
    }
    else if ( result == 0 ) {
        result = 2;
    }
    else {
        result = 3;
    }
    return result;
}

#define MAX_TOKEN_SIZE 100

int ModelicaStrings_skipWhiteSpace(_In_z_ const char* string, int i) {
    /* Return index in string after skipping ws, or position of terminating nul. */
    while (string[i-1] != '\0' && isspace((unsigned char)string[i-1])) {
        ++i;
    }
    return i;
}

/* ----------------- utility functions used in scanXXX functions ----------- */

static int InSet(const char* string, int i, const char* separators) {
    /* Return true if string[i] is one of the characters in separators. */
    return strchr(separators, string[i-1]) != NULL;
}

static int SkipNonWhiteSpaceSeparator(const char* string, int i, const char* separators) {
    /* Return index in string of first character which is ws or character in separators,
       or position of terminating nul.
     */
    while (string[i-1] != '\0' && (isspace((unsigned char)string[i-1]) || InSet(string, i, separators))) {
        ++i;
    }
    return i;
}

static int get_token(const char* string, int startIndex, const char* separators,
                     int* output_index, int* token_start, int* token_length) {
    int past_token;
    int sep_pos;

    *token_start = ModelicaStrings_skipWhiteSpace(string, startIndex);
    /* Index of first char of token, after ws. */

    past_token = SkipNonWhiteSpaceSeparator(string, *token_start, separators);
    /* Index of first char after token, ws or separator. */

    sep_pos = ModelicaStrings_skipWhiteSpace(string, past_token);
    /* Index of first char after ws after token, maybe a separator. */

    *output_index = InSet(string, sep_pos, separators) ? sep_pos + 1 : sep_pos;
    /* Skip any separator. */

    *token_length = past_token-*token_start;

    if (*token_length == 0 || *token_length > MAX_TOKEN_SIZE) {
        /* Token missing or too long. */
        *output_index = startIndex;
        return 0; /* error */
    }

    return 1; /* ok */
}

static int MatchUnsignedInteger(const char* string, int start) {
    /* Starts matching character which make an unsigned integer. The matching
       begins at the start index (first char has index 1). Returns the number
       of characters that could be matched, or zero if the first character
       was not a digit.
     */
    const char* begin = &string[start-1];
    const char* p = begin;
    while (*p != '\0' && isdigit((unsigned char)*p)) {
        ++p;
    }
    return (int) (p - begin);
}

/* --------------- end of utility functions used in scanXXX functions ----------- */

void ModelicaStrings_scanIdentifier(_In_z_ const char* string,
                                    int startIndex, _Out_ int* nextIndex,
                                    _Out_ const char** identifier) {
    int token_start = ModelicaStrings_skipWhiteSpace(string, startIndex);
    /* Index of first char of token, after ws. */

    if (isalpha((unsigned char)string[token_start-1])) {
        /* Identifier has begun. */
        int token_length = 1;
        while (string[token_start+token_length-1] != '\0' &&
            (isalpha((unsigned char)string[token_start+token_length-1]) ||
            isdigit((unsigned char)string[token_start+token_length-1]) ||
            string[token_start+token_length-1] == '_')) {
            ++token_length;
        }

        {
            char* s = ModelicaAllocateString((size_t)token_length);
            strncpy(s, string+token_start-1, (size_t)token_length);
            s[token_length] = '\0';
            *nextIndex = token_start + token_length;
            *identifier = s;
            return;
        }
    }

    /* Token missing or not identifier. */
    *nextIndex  = startIndex;
    {
        char* s = ModelicaAllocateString(0);
        s[0] = '\0';
        *identifier = s;
    }
    return;
}

void ModelicaStrings_scanInteger(_In_z_ const char* string,
                                 int startIndex, int unsignedNumber,
                                 _Out_ int* nextIndex, _Out_ int* integerNumber) {
    int sign = 0;
    /* Number of characters used for sign. */

    int token_start = ModelicaStrings_skipWhiteSpace(string, startIndex);
    /* Index of first char of token, after ws. */

    if (string[token_start-1] == '+' || string[token_start-1] == '-') {
        sign = 1;
    }

    if (unsignedNumber==0 || (unsignedNumber==1 && sign==0)) {
        int number_length = MatchUnsignedInteger(string, token_start + sign);
        /* Number of characters in unsigned number. */

        if (number_length > 0 && sign + number_length < MAX_TOKEN_SIZE) {
            /* check if the scanned string is no Real number */
            int next = token_start + sign + number_length - 1;
            if ( string[next] == '\0' ||
                (string[next] != '.'  && string[next] != 'e'
                                      && string[next] != 'E') ) {
#if defined(NO_LOCALE)
#elif defined(_MSC_VER) && _MSC_VER >= 1400
                _locale_t loc = _create_locale(LC_NUMERIC, "C");
#elif defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3)
                locale_t loc = newlocale(LC_NUMERIC, "C", NULL);
#endif
                char buf[MAX_TOKEN_SIZE+1];
                /* Buffer for copying the part recognized as the number for passing to strtol(). */
                char* endptr;
                /* For error checking of strtol(). */
                int x;
                /* For receiving the result. */

                strncpy(buf, string+token_start-1, (size_t)(sign + number_length));
                buf[sign + number_length] = '\0';
#if !defined(NO_LOCALE) && (defined(_MSC_VER) && _MSC_VER >= 1400)
                x = (int)_strtol_l(buf, &endptr, 10, loc);
                _free_locale(loc);
#elif !defined(NO_LOCALE) && (defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3))
                x = (int)strtol_l(buf, &endptr, 10, loc);
                freelocale(loc);
#else
                x = (int)strtol(buf, &endptr, 10);
#endif
                if (*endptr == 0) {
                    *integerNumber = x;
                    *nextIndex = token_start + sign + number_length;
                    return;
                }
            }
        }
    }

    /* Token missing or cannot be converted to result type. */
    *nextIndex     = startIndex;
    *integerNumber = 0;
    return;
}

void ModelicaStrings_scanReal(_In_z_ const char* string, int startIndex,
                              int unsignedNumber, _Out_ int* nextIndex,
                              _Out_ double* number) {
    /*
    Grammar of real number:

    real ::= [sign] unsigned [fraction] [exponent]
    sign ::= '+' | '-'
    unsigned ::= digit [unsigned]
    fraction ::= '.' [unsigned]
    exponent ::= ('e' | 'E') [sign] unsigned
    digit ::= '0'|'1'|'2'|'3'|'4'|'5'|'6'|'7'|'8'|'9'
    */

    int len;
    /* Temporary variable for the length of a matched unsigned number. */

    int total_length = 0;
    /* Total number of characters recognized as part of a decimal number. */

    int token_start = ModelicaStrings_skipWhiteSpace(string, startIndex);
    /* Index of first char of token, after ws. */

    /* Scan sign of decimal number */

    if (string[token_start-1] == '+' || string[token_start-1] == '-') {
        total_length = 1;
        if (unsignedNumber == 1) {
            goto Modelica_ERROR;
        }
    }

    /* Scan integer part of mantissa. */

    len = MatchUnsignedInteger(string, token_start + total_length);
    total_length += len;

    /* Scan decimal part of mantissa. */

    if (string[token_start + total_length-1] == '.') {
        total_length += 1;
        len = MatchUnsignedInteger(string, token_start + total_length);
        if (len > 0) {
            total_length += len;
        }
    }

    /* Scan exponent part of mantissa. */

    if (string[token_start + total_length-1] == 'e' || string[token_start + total_length-1] == 'E') {
        int exp_len = 1;
        /* Total number of characters recognized as part of the non-numeric parts
         * of exponent (the 'e' and the sign). */

        if (string[token_start + total_length] == '+' || string[token_start + total_length] == '-') {
            exp_len += 1;
        }
        len = MatchUnsignedInteger(string, token_start + total_length + exp_len);
        if (len == 0) {
            goto Modelica_ERROR;
        }
        total_length += exp_len + len;
    }

    /* Convert accumulated characters into a number. */

    if (total_length > 0 && total_length < MAX_TOKEN_SIZE) {
#if defined(NO_LOCALE)
        const char* const dec = ".";
#elif defined(_MSC_VER) && _MSC_VER >= 1400
        _locale_t loc = _create_locale(LC_NUMERIC, "C");
#elif defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3)
        locale_t loc = newlocale(LC_NUMERIC, "C", NULL);
#else
        char* dec = localeconv()->decimal_point;
#endif
        char buf[MAX_TOKEN_SIZE+1];
        /* Buffer for copying the part recognized as the number for passing to strtod(). */
        char* endptr;
        /* For error checking of strtod(). */
        double x;
        /* For receiving the result. */

        strncpy(buf, string+token_start-1, (size_t)total_length);
        buf[total_length] = '\0';
#if !defined(NO_LOCALE) && (defined(_MSC_VER) && _MSC_VER >= 1400)
        x = _strtod_l(buf, &endptr, loc);
        _free_locale(loc);
#elif !defined(NO_LOCALE) && (defined(__GLIBC__) && defined(__GLIBC_MINOR__) && ((__GLIBC__ << 16) + __GLIBC_MINOR__ >= (2 << 16) + 3))
        x = strtod_l(buf, &endptr, loc);
        freelocale(loc);
#else
        if (*dec == '.') {
            x = strtod(buf, &endptr);
        }
        else if (NULL == strchr(buf, '.')) {
            x = strtod(buf, &endptr);
        }
        else {
            char* p = strchr(buf, '.');
            *p = *dec;
            x = strtod(buf, &endptr);
        }
#endif
        if (*endptr == 0) {
            *number = x;
            *nextIndex = token_start + total_length;
            return;
        }
    }

    /* Token missing or cannot be converted to result type. */

Modelica_ERROR:
    *nextIndex = startIndex;
    *number = 0;
    return;
}

void ModelicaStrings_scanString(_In_z_ const char* string, int startIndex,
                                _Out_ int* nextIndex, _Out_ const char** result) {
    int i, token_start, past_token, token_length;

    token_start = ModelicaStrings_skipWhiteSpace(string, startIndex);
    i = token_start;
    if (string[token_start-1] != '"') {
        goto Modelica_ERROR;
    }
    /* Index of first char of token, after ws. */

    ++i;
    while (1) {
        if (string[i-1] == '\0') {
            goto Modelica_ERROR;
        }
        if (string[i-2] == '\\' && string[i-1] == '"')
            ; /* escaped quote, consume */
        else if (string[i-1] == '"') {
            break; /* end quote */
        }
        ++i;
    }
    past_token = i + 1;
    /* Index of first char after token, ws or separator. */

    token_length = past_token-token_start-2;

    if (token_length > 0) {
        char* s = ModelicaAllocateString((size_t)token_length);
        strncpy(s, string+token_start, (size_t)token_length);
        s[token_length] = '\0';
        *result = s;
        *nextIndex = past_token;
        return;
    }

Modelica_ERROR:
    {
        char* s = ModelicaAllocateString(0);
        s[0] = '\0';
        *result = s;
    }
    *nextIndex = startIndex;
    return;
}

/* AP hash function macro variant of the one listed at
   http://www.partow.net/programming/hashfunctions/index.html#APHashFunction

   Copyright (C) 2002, Arash Partow

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
*/
#define HASH_AP(key, keylen, hash) \
do { \
    unsigned _hb_keylen = (unsigned)keylen; \
    const unsigned char *_hb_key = (const unsigned char*)(key); \
    unsigned int i; \
    hash = 0xAAAAAAAA; \
    for (i = 0; i < _hb_keylen; _hb_key++, i++) { \
        hash ^= ((i & 1) == 0) ? (  (hash <<  7) ^ (*_hb_key) * (hash >> 3)) : \
                                 (~((hash << 11) + ((*_hb_key) ^ (hash >> 5)))); \
    } \
} while (0)

int ModelicaStrings_hashString(_In_z_ const char* str) {
    /* Compute an unsigned int hash code from a character string */
    size_t len = strlen(str);
    union hash_tag {
        unsigned int iu;
        int          is;
    } h;

    HASH_VALUE(str, len, h.iu);

    return h.is;
}

#if defined(__clang__)
#pragma clang diagnostic pop
#endif
