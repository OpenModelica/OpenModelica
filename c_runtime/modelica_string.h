/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/


#ifndef MODELICA_STRING_H_
#define MODELICA_STRING_H_

struct modelica_string_s
{
  int length;
  char* data;
};

typedef struct modelica_string_s modelica_string_t;

int modelica_string_ok(modelica_string_t* a);

int modelica_string_length(modelica_string_t* a);

void init_modelica_string(modelica_string_t* dest, const char* str);

void alloc_modelica_string(modelica_string_t* dest,int length);

/* Allocation of real data */
void alloc_modelica_string_data(modelica_string_t*);

/* Frees memory*/
void free_modelica_string_data(modelica_string_t*);

/* Clones data*/
void clone_modelica_string_spec(modelica_string_t* source, modelica_string_t* dest);

/* Copy real data*/
void copy_modelica_string_data(modelica_string_t* source, modelica_string_t* dest);

/* Copy real array*/
void copy_modelica_string(modelica_string_t* source, modelica_string_t* dest);

#endif
