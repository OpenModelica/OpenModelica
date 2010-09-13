/* External utility functions for Modelica package
   Modelica.Functions.Strings.

   Release Notes:
      Sep. 24, 2004: by Martin Otter.
                     Final cleaning up of the code

      Sep.  9, 2004: by Dag Bruck, Dynasim AB.
                     Implementation of scan functions

      Aug. 19, 2004: by Martin Otter, DLR.
                     Changed according to the decisions of the 37th
                     design meeting in Lund (see minutes)

      Jan.  7, 2002: by Martin Otter, DLR.
                     Implemented a first version

   Copyright (C) 2002-2006, Modelica Association and DLR.

   The content of this file is free software; it can be redistributed
   and/or modified under the terms of the Modelica License 2, see the
   license conditions and the accompanying disclaimer in file
   Modelica/ModelicaLicense2.html or in Modelica.UsersGuide.ModelicaLicense2.
*/

#include <ctype.h>
#if !defined(NO_FILE_SYSTEM)
#include <stdio.h>
#endif
#include <string.h>
#include "ModelicaUtilities.h"


static const char* ModelicaStrings_substring(const char* string, int startIndex, int endIndex) {

  /* Return string1(startIndex:endIndex) if endIndex >= startIndex,
     or return string1(startIndex:startIndex), if endIndex = 0.
     An assert is triggered, if startIndex/endIndex are not valid.
  */
     char* substring;
     int len1 = strlen(string);
     int len2;

  /* Check arguments */
     if ( startIndex < 1 ) {
        ModelicaFormatError("Wrong call of Utilities.Strings.substring:\n"
                            "  startIndex = %d (has to be > 0).\n"
                            "  string     = \"%s\"\n", startIndex, string);
     } else if ( endIndex == -999 ) {
        endIndex = startIndex;
     } else if ( endIndex < startIndex ) {
        ModelicaFormatError("Wrong call of  Utilities.Strings.substring:\n"
                            "  startIndex = %d\n"
                            "  endIndex   = %d (>= startIndex required)\n"
                            "  string     = \"%s\"\n", startIndex, endIndex, string);
     } else if ( endIndex > len1 ) {
        ModelicaFormatError("Wrong call of Utilities.Strings.substring:\n"
                            "  endIndex = %d (<= %d required (=length(string)).\n"
                            "  string   = \"%s\"\n", endIndex, len1, string);
     };

  /* Allocate memory and copy string */
     len2 = endIndex - startIndex + 1;
     substring = ModelicaAllocateString(len2);
     strncpy(substring, &string[startIndex-1], len2);
     substring[len2] = '\0';
     return substring;
};


static int ModelicaStrings_length(const char* string)
/* Returns the number of characters "string" */
{
     return strlen(string);
}


static int ModelicaStrings_compare(const char* string1, const char* string2, int caseSensitive)
/* compares two strings, optionally ignoring case */
{
    int result;
    if (string1 == 0 || string2 == 0) return 2;

    if (caseSensitive) {
        result = strcmp(string1, string2);
    } else {
        while (tolower(*string1) == tolower(*string2) && *string1 != '\0') {
            string1++;
            string2++;
        }
        result = (int)(tolower(*string1)) - (int)(tolower(*string2));
    }

    if ( result < 0 ) {
        result = 1;
    } else if ( result == 0 ) {
        result = 2;
    } else {
        result = 3;
    };
    return result;
}


#define MAX_TOKEN_SIZE 100

static int ModelicaStrings_skipWhiteSpace(const char* string, int i)
/* Return index in string after skipping ws, or position of terminating nul. */
{
    while (string[i-1] != '\0' && isspace(string[i-1]))
        ++i;
    return i;
}


/* ----------------- utility functions used in scanXXX functions ----------- */

static int InSet(const char* string, int i, const char* separators)
/* Returns true if string[i] is one of the characters in separators. */
{
    return strchr(separators, string[i-1]) != NULL;
}

static int SkipNonWhiteSpaceSeparator(const char* string, int i, const char* separators)
/* Return index in string of first character which is ws or character in separators,
   or position of terminating nul. */
{
    while (string[i-1] != '\0' && (isspace(string[i-1]) || InSet(string, i, separators)))
        ++i;
    return i;
}

static int get_token(const char* string, int startIndex, const char* separators,
                     int* output_index, int* token_start, int* token_length)
{
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

static int MatchUnsignedInteger(const char* string, int start)
/* Starts matching character which make an unsigned integer. The matching
   begins at the start index (first char has index 1). Returns the number
   of characters that could be matched, or zero if the first character
   was not a digit. */
{
    const char* begin = &string[start-1];
    const char* p = begin;
    while (*p != '\0' && isdigit(*p))
        ++p;
    return p - begin;
}

/* --------------- end of utility functions used in scanXXX functions ----------- */


static void ModelicaStrings_scanIdentifier(const char* string, int startIndex, int* nextIndex, const char** identifier)
{
    int token_length=0;

    int token_start = ModelicaStrings_skipWhiteSpace(string, startIndex);
    /* Index of first char of token, after ws. */

    if (isalpha(string[token_start-1])) {
        /* Identifier has begun. */
        token_length = 1;
        while (string[token_start+token_length-1] != '\0' &&
            (isalpha(string[token_start+token_length-1]) ||
            isdigit(string[token_start+token_length-1]) ||
            string[token_start+token_length-1] == '_'))
        {
            ++token_length;
        }

       {
        char* s = ModelicaAllocateString(token_length);
        strncpy(s, string+token_start-1, token_length);
        s[token_length] = '\0';
        *nextIndex = token_start + token_length;
        *identifier = s;
        return;
       }
    }

    /* Token missing or not identifier. */
    *nextIndex  = startIndex;
    *identifier = ModelicaAllocateString(0);
    return;
}

static void ModelicaStrings_scanInteger(const char* string, int startIndex, int unsignedNumber,
                                        int* nextIndex, int* integerNumber)
{
    int number_length=0;
    int sign = 0;
    /* Number of characters used for sign. */

    int token_start = ModelicaStrings_skipWhiteSpace(string, startIndex);
    /* Index of first char of token, after ws. */

    if (string[token_start-1] == '+' || string[token_start-1] == '-')
        sign = 1;

    if (unsignedNumber==0 || unsignedNumber==1 && sign==0) {
        number_length = MatchUnsignedInteger(string, token_start + sign);
        /* Number of characters in unsigned number. */

        if (number_length > 0 && sign + number_length < MAX_TOKEN_SIZE) {
          /* check if the scanned string is no Real number */
          int next = token_start + sign + number_length - 1;
          if (  string[next] == '\0' ||
               (string[next] != '\0' && string[next] != '.'
                                     && string[next] != 'e'
                                     && string[next] != 'E') ) {
             /* get Integer value */
             char buf[MAX_TOKEN_SIZE+1];
             int x;

             strncpy(buf, string+token_start-1, sign + number_length);
             buf[sign + number_length] = '\0';
#if !defined(NO_FILE_SYSTEM)
             if (sscanf(buf, "%d", &x) == 1) {
                *integerNumber = x;
                *nextIndex = token_start + sign + number_length;
                return;
             }
#endif
          } else {
            ++number_length;
          }
        }
    }

    /* Token missing or cannot be converted to result type. */
    *nextIndex     = startIndex;
    *integerNumber = 0;
     return;
}

static void ModelicaStrings_scanReal(const char* string, int startIndex, int unsignedNumber,
                                     int* nextIndex, double* number)
{
    /*
    Grammar of real number:

    real ::= [sign] unsigned [fraction] [exponent]
    sign ::= '+' | '-'
    unsigned ::= digit [unsigned]
    fraction ::= '.' [unsigned]
    exponent ::= ('e' | 'E') [sign] unsigned
    digit ::= '0'|'1'|'2'|'3'|'4'|'5'|'6'|'7'|'8'|'9'
    */

    int len = 0;
    /* Temporary variable for the length of a matched unsigned number. */

    int total_length = 0;
    /* Total number of characters recognized as part of a decimal number. */

    int token_start = ModelicaStrings_skipWhiteSpace(string, startIndex);
    /* Index of first char of token, after ws. */

    /* Scan sign of decimal number */

    if (string[token_start-1] == '+' || string[token_start-1] == '-') {
        total_length = 1;
        if (unsignedNumber==1) goto error;
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
        // total_length += 1;
        int exp_len = 1;

        if (string[token_start + total_length] == '+' || string[token_start + total_length] == '-') {
            exp_len += 1;
        }
        len = MatchUnsignedInteger(string, token_start + total_length + exp_len);
        if (len == 0) goto error;
        total_length += exp_len + len;
    }

    /* Convert accumulated characters into a number. */

    if (total_length > 0 && total_length < MAX_TOKEN_SIZE) {
        char buf[MAX_TOKEN_SIZE+1];
        double x;

        strncpy(buf, string+token_start-1, total_length);
        buf[total_length] = '\0';
#if !defined(NO_FILE_SYSTEM)
        if (sscanf(buf, "%lg", &x) == 1) {
            *number = x;
            *nextIndex = token_start + total_length;
            return;
        }
#endif
    }

    /* Token missing or cannot be converted to result type. */

error:
    *nextIndex = startIndex;
    *number = 0;
    return;
}


static void ModelicaStrings_scanString(const char* string, int startIndex,
                                       int* nextIndex, const char** result)
{
    int i, token_start, past_token, token_length;

    token_length = 0;
    token_start = ModelicaStrings_skipWhiteSpace(string, startIndex);
    i = token_start;
    if (string[token_start-1] != '"') goto error;
    /* Index of first char of token, after ws. */

    ++i;
    while (1) {
        if (string[i-1] == '\0') goto error;
        if (string[i-2] == '\\' && string[i-1] == '"')
            ; /* escaped quote, consume */
        else if (string[i-1] == '"')
            break;      /* end quote */
        ++i;
    }
    past_token = i + 1;
    /* Index of first char after token, ws or separator. */

    token_length = past_token-token_start-2;

    if (token_length > 0) {
        char* s = ModelicaAllocateString(token_length);
        strncpy(s, string+token_start, token_length);
        s[token_length] = '\0';
        *result = s;
        *nextIndex = past_token;
        return;
    }

error:
    *result = ModelicaAllocateString(0);
    *nextIndex = startIndex;
    return;
}
