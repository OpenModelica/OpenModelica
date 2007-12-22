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

#ifndef READ_WRITE_H_
#define READ_WRITE_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "modelica.h"

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

int read_modelica_boolean(FILE*,modelica_boolean*);
int read_boolean_array(FILE*,boolean_array_t*);
int write_modelica_boolean(FILE*,modelica_boolean*);
int write_boolean_array(FILE*,boolean_array_t*);

int read_modelica_string(FILE*,modelica_string_t*);
int write_modelica_string(FILE*,modelica_string_t*);
int read_type_description(FILE*, type_description*);

int read_modelica_complex(FILE*, modelica_complex);

#endif
