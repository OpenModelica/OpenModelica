/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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

#include "modelica_string.h"
#include "memory_pool.h"
#include <stdio.h>
#include <assert.h>
#include <string.h>

int modelica_string_ok(modelica_string_t* a)
{
	/* Since a modelica string is a char* check that it is not null.*/
    return (int)a;
}

int modelica_string_length(modelica_string_t* a)
{
    return strlen(*a);
}

/* Convert a modelica_integer to a modelica_string, used in String(i) */

void modelica_integer_to_modelica_string(modelica_string_t* dest,modelica_integer i, modelica_integer minLen,modelica_boolean leftJustified,modelica_integer signDigits)
{
	char formatStr[40];
	char buf[400];
	formatStr[0]='%';
	if (leftJustified) {
		sprintf(&formatStr[1],"-%dd",minLen);
	} else {
		sprintf(&formatStr[1],"%dd",minLen);
	}
	sprintf(buf,formatStr,i);
	init_modelica_string(dest,buf);
}

/* Convert a modelica_real to a modelica_string, used in String(r) */

void modelica_real_to_modelica_string(modelica_string_t* dest,modelica_real r,modelica_integer minLen,modelica_boolean leftJustified,modelica_integer signDigits)
{
	char formatStr[40];
	char buf[400];
	formatStr[0]='%';
	if (leftJustified) {
		sprintf(&formatStr[1],"-%d.%dg",minLen,signDigits);
	} else {
		sprintf(&formatStr[1],"%d.%dg",minLen,signDigits);
	}
	sprintf(buf,formatStr,r);
	init_modelica_string(dest,buf);
}

/* Convert a modelica_boolean to a modelica_string, used in String(b) */

void modelica_boolean_to_modelica_string(modelica_string_t* dest,modelica_boolean b, modelica_integer minLen, modelica_boolean leftJustified, modelica_integer signDigits)
{
	if (b) {
		init_modelica_string(dest,"true");
	} else {
		init_modelica_string(dest,"false");
	}
}

void init_modelica_string(modelica_string_t* dest, const char* str)
{
    int i;
    int length = strlen(str);
    alloc_modelica_string(dest, length);
    for (i = 0; i<length; ++i) {
        (*dest)[i] = str[i];
    }
    (*dest)[i]=0;
}

void alloc_modelica_string(modelica_string_t* dest, int n)
{
	/* Reserve place for null terminator too.*/
    *dest = char_alloc(n+1);
}


void free_modelica_string(modelica_string_t* a)
{
    int length;

    assert(modelica_string_ok(a));

    length = modelica_string_length(a);
    /* Free also null terminator.*/
    char_free(length+1);
}

void copy_modelica_string(modelica_string_t* source, modelica_string_t* dest)
{
	alloc_modelica_string(dest,modelica_string_length(source));
    memcpy(*dest, *source, modelica_string_length(source)+1);
}

void cat_modelica_string(modelica_string_t* dest, modelica_string_t *s1, modelica_string_t *s2)
{
    int len1 = modelica_string_length(s1);
    int len2 = modelica_string_length(s2);
	alloc_modelica_string(dest,len1+len2);
    memcpy(*dest, *s1, len1);
    memcpy((*dest) + len1, *s2, len2 + 1);
}

