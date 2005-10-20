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


#ifndef READ_WRITE_H_
#define READ_WRITE_H_

#include "modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#define PRE_VARIABLES FILE *in_file,*out_file;int close_file;
#define PRE_OPEN_FILE(fv,fn,m,df) if(strcmp("-",fn)==0){fv=df;close_file=0;}else{fv=fopen(fn,m);close_file=1;if(!fv){return errno;}}

#define PRE_OPEN_INFILE PRE_OPEN_FILE(in_file,in_filename,"r",stdin)
#define PRE_OPEN_OUTFILE PRE_OPEN_FILE(out_file,out_filename,"w",stdout)
#define PRE_READ_DONE if (close_file) fclose(in_file);
#define PRE_WRITE_DONE if (close_file) fclose(out_file);

struct type_desc_s {
  char type;
  int ndims;
  int *dim_size;
};

typedef struct type_desc_s type_description;

int read_modelica_real(FILE*,modelica_real*);
int read_real_array(FILE*,real_array_t*);
int write_modelica_real(FILE*,modelica_real*);
int write_real_array(FILE*,real_array_t*);

int read_modelica_integer(FILE*,modelica_integer*);
int read_integer_array(FILE*,integer_array_t*);
int write_modelica_integer(FILE*,modelica_integer*);
int write_integer_array(FILE*,integer_array_t*);

int read_modelica_string(FILE*,modelica_string_t*);
int write_modelica_string(FILE*,modelica_string_t*);
int read_type_description(FILE*, type_description*);

#endif
