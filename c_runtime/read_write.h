/*
Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
