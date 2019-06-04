/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>
#include <assert.h>
#include <ctype.h>
#include "read_matlab4.h"
#include "omc_file.h"

extern const char *omc_mat_Aclass;

typedef struct {
  uint32_t type;
  uint32_t mrows;
  uint32_t ncols;
  uint32_t imagf;
  uint32_t namelen;
} MHeader_t;

/* Make Visual Studio not complain about deprecated items */
#ifdef _MSC_VER
#define strdup _strdup
#endif

static const char *binTrans_char = "binTrans";
static const char *binNormal_char = "binNormal";

/* strcmp ignore whitespace */
static OMC_INLINE int strcmp_iws(const char *a, const char *b)
{
  while (*a && *b) {
    if (isspace(*a)) {
      a++;
      continue;
    }
    if (isspace(*b)) {
      b++;
      continue;
    }
    if (*a != *b) {
      return *a > *b ? 1 : -1;
    }
    a++;
    b++;
  }
  return *a == *b ? 0 : (*a ? 1 : -1);
}

int omc_matlab4_comp_var(const void *a, const void *b)
{
  char *as = ((ModelicaMatVariable_t*)a)->name;
  char *bs = ((ModelicaMatVariable_t*)b)->name;

  return strcmp_iws(as,bs);
}

int mat_element_length(int type)
{
  int m = (type/1000);
  int o = (type%1000)/100;
  int p = (type%100)/10;
  int t = (type%10);
  if(m) return -1; /* We require IEEE Little Endian for now */
  if(o) return -1; /* Reserved number; forced 0 */
  if(t == 1 && p == 0) return 8; /* Double text matrix? */
  if(t == 1 && p != 5) return -1; /* Text matrix? Force element length=1 */
  if(t == 2) return -1; /* Sparse matrix fails */
  switch (p) {
    case 0: return 8;
    case 1: return 4;
    case 2: return 4;
    case 3: return 2;
    case 4: return 2;
    case 5: return 1;
    default: return -1;
  }
}

/* Do not double-free this :) */
void omc_free_matlab4_reader(ModelicaMatReader *reader)
{
  unsigned int i;
  if (reader->file) {
    fclose(reader->file);
    reader->file = 0;
  }
  if (reader->fileName) {
    free(reader->fileName);
    reader->fileName=NULL;
  }
  for(i=0; i<reader->nall; i++) {
    free(reader->allInfo[i].name);
    free(reader->allInfo[i].descr);
  }
  reader->nall = 0;
  if (reader->file) {
    free(reader->allInfo);
    reader->allInfo=NULL;
  }
  if (reader->params) {
    free(reader->params);
    reader->params=NULL;
  }
  for(i=0; i<reader->nvar*2; i++) {
    if (reader->vars[i]) free(reader->vars[i]);
  }
  reader->nvar = 0;
  if (reader->vars) {
    free(reader->vars);
    reader->vars=NULL;
  }
}

void remSpaces(char *ch){
    char *ch2 = ch;
    unsigned int ui = 0;
    unsigned int uj = 0;

    for(ui=0;ui<=strlen(ch);ui++){
        if(ch[ui]!=' '){
            ch2[uj] = ch[ui];
            uj++;
        }
    }
}

/* Read n elements into str; convert from double if necessary, etc */
static int read_chars(int type, size_t n, FILE *file, char *str)
{
  int p = (type%100)/10;
  if (p == 0) { /* Double */
    double d=0.0;
    int k;
    for (k=0; k<n; k++) {
      if (fread(&d, sizeof(double), 1, file) != 1) {
        return 1;
      }
      str[k] = (char) d;
    }
    return 0;
  } else if (p == 5) { /* Byte */
    return fread(str,n,1,file) != 1;
  }
  return 1;
}

static int read_int32(int type, size_t n, FILE *file, int32_t *val)
{
  int p = (type%100)/10;
  if (p == 0) { /* Double */
    double d=0.0;
    int k;
    for (k=0; k<n; k++) {
      if (fread(&d, sizeof(double), 1, file) != 1) {
        return 1;
      }
      val[k] = (int32_t) d;
    }
    return 0;
  } else if (p == 2) { /* int32 */
    return fread(val,n*sizeof(int32_t),1,file) != 1;
  }
  return 1;
}

static int read_double(int type, size_t n, FILE *file, double *val)
{
  int p = (type%100)/10;
  if (n==0) {
    return 0;
  }
  if (p == 0) { /* Double */
    return fread(val,n*sizeof(double),1,file) != 1;
  } else if (p == 1) { /* float */
    float f=0.0;
    int k;
    for (k=0; k<n; k++) {
      if (fread(&f, sizeof(float), 1, file) != 1) {
        return 1;
      }
      val[k] = (double) f;
    }
    return 0;
  }
  return 1;
}


/* Returns 0 on success; the error message on error */
const char* omc_new_matlab4_reader(const char *filename, ModelicaMatReader *reader)
{
  const int nMatrix=6;
  static const char *matrixNames[6]={"Aclass","name","description","dataInfo","data_1","data_2"};
  static const char *matrixNamesMismatch[6]={"Matrix name mismatch: Aclass","Matrix name mismatch: name","Matrix name mismatch: description","Matrix name mismatch: dataInfo","Matrix name mismatch: data_1","Matrix name mismatch: data_2"};
  const int matrixTypes[6]={51,51,51,20,0,0};
  int i;
  char binTrans = 1;
  memset(reader, 0, sizeof(ModelicaMatReader));
  reader->file = omc_fopen(filename, "rb");
  if(!reader->file) return strerror(errno);
  reader->fileName = strdup(filename);
  reader->readAll = 0;
  reader->stopTime = NAN;
  for(i=0; i<nMatrix;i++) {
    MHeader_t hdr;
    int nr = fread(&hdr,sizeof(MHeader_t),1,reader->file);
    size_t matrix_length,element_length;
    char *name;
    if(nr != 1) return "Corrupt header (1)";
    /* fprintf(stderr, "Found matrix %d=%s type=%04d mrows=%d ncols=%d imagf=%d namelen=%d\n", i, name, hdr.type, hdr.mrows, hdr.ncols, hdr.imagf, hdr.namelen); */
    if(hdr.imagf > 1) return "Matrix uses imaginary numbers";
    if((element_length = mat_element_length(hdr.type)) == -1) return "Could not determine size of matrix elements";
    name = (char*) malloc(hdr.namelen);
    nr = fread(name,hdr.namelen,1,reader->file);
    if(nr != 1) {
      free(name);
      return "Corrupt header (2)";
    }
    if(name[hdr.namelen-1]) {
      free(name);
      return "Corrupt header (3)";
    }
    /* fprintf(stderr, "  Name of matrix: %s\n", name); */
    matrix_length = hdr.mrows*hdr.ncols*(1+hdr.imagf)*element_length;
    if(0 != strcmp(name,matrixNames[i])) {
      free(name);
      return matrixNamesMismatch[i];
    }
    free(name);
    name=NULL;
    switch (i) {
    case 0: {
      unsigned int k;
      uint32_t j;
      char tmp[45];
      if(hdr.mrows != 4) return "Aclass matrix does not have 4 rows";
      if(hdr.ncols != 11) return "Aclass matrix does not have 11 cols";
      if (read_chars(hdr.type, hdr.ncols*hdr.mrows, reader->file, tmp)) {
        return "Could not read: Aclass matrix as text";
      }
      for(k=0; k<hdr.mrows; k++) {
        char row[12];
        for(j=0; j<hdr.ncols; j++) {
            row[j] = tmp[j*hdr.mrows+k];
        }
        row[hdr.ncols] = '\0';
        /* fprintf(stderr, "Row %s\n", row); */
        if(k==3)
        {
          /* binTrans */
          if(0 == strncmp(row,binTrans_char,8))  {
            /* fprintf(stderr, "use binTrans format\n"); */
            binTrans = 1;
          } else if(0 == strncmp(row,binNormal_char,9))  {
            /* binNormal */
            /* fprintf(stderr, "use binNormal format\n"); */
            binTrans = 0;
          } else {
            /* fprintf(stderr, "row 3: %s\n", row); */
            return "Aclass matrix does not match binTrans or binNormal format";
          }
        }
      }
      break;
    }
    case 1: { /* "names" */
      unsigned int k;
      if(binTrans==0)
         reader->nall = hdr.mrows;
      else
        reader->nall = hdr.ncols;
      reader->allInfo = (ModelicaMatVariable_t*) malloc(sizeof(ModelicaMatVariable_t)*reader->nall);
      if(binTrans==1) {
        for(k=0; k<hdr.ncols; k++) {
          reader->allInfo[k].name = (char*) malloc(hdr.mrows+1);
          if (read_chars(hdr.type, hdr.mrows, reader->file, reader->allInfo[k].name)) {
            return "Could not read: names matrix as text";
          }
          reader->allInfo[k].name[hdr.mrows] = '\0';
          reader->allInfo[k].isParam = -1;
          reader->allInfo[k].index = -1;
          remSpaces(reader->allInfo[k].name);
          /* fprintf(stderr, "    Adding variable '%s'\n", reader->allInfo[k].name); */
         }
      }
      if(binTrans==0) {
        uint32_t j;
        char* tmp = (char*) malloc(hdr.ncols*hdr.mrows+1);
        if (read_chars(hdr.type, hdr.ncols*hdr.mrows, reader->file, tmp)) {
          return "Could not read: names matrix as text";
        }
        for(k=0; k<hdr.mrows; k++) {
          reader->allInfo[k].name = (char*) malloc(hdr.ncols+1);
          for(j=0; j<hdr.ncols; j++) {
            reader->allInfo[k].name[j] = tmp[j*hdr.mrows+k];
          }
          reader->allInfo[k].name[hdr.ncols] = '\0';
          reader->allInfo[k].isParam = -1;
          reader->allInfo[k].index = -1;
          remSpaces(reader->allInfo[k].name);
          /* fprintf(stderr, "    Adding variable '%s'\n", reader->allInfo[k].name); */
        }
        free(tmp);
      }
      break;
    }
    case 2: { /* description */
      unsigned int k;
      if(binTrans==1) {
        for(k=0; k<hdr.ncols; k++) {
          reader->allInfo[k].descr = (char*) malloc(hdr.mrows+1);
          if (read_chars(hdr.type, hdr.mrows, reader->file, reader->allInfo[k].descr)) {
            return "Could not read: description matrix as text";
          }
          reader->allInfo[k].descr[hdr.mrows] = '\0';
          /* fprintf(stderr, "    Adding description %s\n", reader->allInfo[k].descr); */
        }
      } else if(binTrans==0) {
        uint32_t j;
        char* tmp = (char*) malloc(hdr.ncols*hdr.mrows+1);
        if (read_chars(hdr.type, hdr.ncols*hdr.mrows, reader->file, tmp)) {
          return "Could not read: description matrix as text";
        }
        for(k=0; k<hdr.mrows; k++) {
          reader->allInfo[k].descr = (char*) malloc(hdr.ncols+1);
          for(j=0; j<hdr.ncols; j++) {
            reader->allInfo[k].descr[j] = tmp[j*hdr.mrows+k];
          }
          reader->allInfo[k].descr[hdr.ncols] = '\0';
          /* fprintf(stderr, "    Adding description %s\n", reader->allInfo[k].descr); */
        }
        free(tmp);
      }
      break;
    }
    case 3: { /* "dataInfo" */
      unsigned int k;
      int32_t *tmp = (int32_t*) malloc(sizeof(int32_t)*hdr.ncols*hdr.mrows);
      if (read_int32(hdr.type, hdr.ncols*hdr.mrows, reader->file, tmp)) {
        free(tmp); tmp=NULL;
        return "Corrupt header: dataInfo matrix";
      }
      if(binTrans==1) {
        for(k=0; k<hdr.ncols; k++) {
          reader->allInfo[k].isParam = tmp[k*hdr.mrows] == 1;
          reader->allInfo[k].index = tmp[k*hdr.mrows+1];
          /* fprintf(stderr, "    Variable %s isParam=%d index=%d\n", reader->allInfo[k].name, reader->allInfo[k].isParam, reader->allInfo[k].index); */
        }
      }
      if(binTrans==0) {
        for(k=0; k<hdr.mrows; k++) {
          reader->allInfo[k].isParam = tmp[k] == 1;
          reader->allInfo[k].index =  tmp[k + hdr.mrows];
          /* fprintf(stderr, "    Variable %s isParam=%d index=%d\n", reader->allInfo[k].name, reader->allInfo[k].isParam, reader->allInfo[k].index); */
        }
      }
      free(tmp); tmp=NULL;
      /* Sort the variables so we can do faster lookup */
      qsort(reader->allInfo,reader->nall,sizeof(ModelicaMatVariable_t),omc_matlab4_comp_var);
      break;
    }
    case 4: { /* "data_1" */
      unsigned int k;
      if(binTrans==1) {
        if(hdr.mrows != 0 || hdr.ncols != 0) {
          if(hdr.ncols != 2 && hdr.ncols != 1) return "data_1 matrix does not have 1 or 2 cols (or 0 rows/columns)";
        }
        reader->nparam = hdr.mrows;
        reader->params = reader->nparam > 0 ? (double*) malloc(hdr.mrows*hdr.ncols*sizeof(double)) : NULL;
        if (read_double(hdr.type, hdr.mrows*hdr.ncols, reader->file, reader->params)) {
          return "Corrupt header: data_1 matrix";
        }
      }
      if(binTrans==0) {
        unsigned int j;
        if(hdr.mrows != 0 || hdr.ncols != 0) {
          if(hdr.mrows != 2 && hdr.mrows != 1) return "data_1 matrix does not have 1 or 2 rows (or 0 rows/columns)";
        }
        reader->nparam = hdr.ncols;
        double *tmp=NULL;
        tmp = reader->nparam > 0 ? (double*) malloc(hdr.mrows*hdr.ncols*sizeof(double)) : NULL;
        reader->params = reader->nparam > 0 ? (double*) malloc(hdr.mrows*hdr.ncols*sizeof(double)) : NULL;
        if (read_double(hdr.type, hdr.mrows*hdr.ncols, reader->file, tmp)) {
          return "Corrupt header: data_1 matrix";
        }
        for(k=0; k<hdr.mrows; k++) {
          for(j=0; j<hdr.ncols; j++) {
            reader->params[k*hdr.ncols+j] = tmp[k +j*hdr.mrows];
          }
        }
        if (tmp) {
          free(tmp);
        }
      }
      break;
    }
    case 5: { /* "data_2" */
      int p = (hdr.type / 10)%10;
      if (p==0) {
        reader->doublePrecision=1;
      } else if (p==1) {
        reader->doublePrecision=0;
      } else {
        return "data_2 matrix not in double/float representation";
      }
      if(binTrans==1) {
        reader->nrows = hdr.ncols;
        /* Allow empty matrix; it's not a complete file, but ok... */
        /* if(reader->nrows < 2) return "Too few rows in data_2 matrix"; */
        reader->nvar = hdr.mrows;
        reader->var_offset = ftell(reader->file);
        reader->vars = (double**) calloc(reader->nvar*2,sizeof(double*));
        if(-1==fseek(reader->file,matrix_length,SEEK_CUR)) return "Corrupt header: data_2 matrix";
      }
      if(binTrans==0) {
        unsigned int k,j;
        reader->nrows = hdr.mrows;
        /* Allow empty matrix; it's not a complete file, but ok... */
        /* if(reader->nrows < 2) return "Too few rows in data_2 matrix"; */
        reader->nvar = hdr.ncols;
        reader->var_offset = ftell(reader->file);
        reader->vars = (double**) calloc(reader->nvar*2,sizeof(double*));


        double *tmp=NULL;
        tmp = (double*) malloc(hdr.mrows*hdr.ncols*sizeof(double));
        if (read_double(hdr.type, hdr.mrows*hdr.ncols, reader->file, tmp)) {
          return "Corrupt header: data_2 matrix";
        }
        for(k=0; k<hdr.ncols; k++) {
          reader->vars[k] = (double*) malloc(hdr.mrows*sizeof(double));
          for(j=0; j<hdr.mrows; j++) {
            reader->vars[k][j] = tmp[j+k*hdr.mrows];
          }
        }
        for(k=reader->nvar; k<reader->nvar*2; k++) {
          reader->vars[k] = (double*) malloc(hdr.mrows*sizeof(double));
          for(j=0; j<hdr.mrows; j++) {
            reader->vars[k][j] = -reader->vars[k-reader->nvar][j];
          }
        }
        free(tmp);

        if(-1==fseek(reader->file,matrix_length,SEEK_CUR)) return "Corrupt header: data_2 matrix";
      }
      break;
    }
    default:
      return "Implementation error: Unknown case";
    }
  }
  return 0;
}

static char* dymolaStyleVariableName(const char *varName)
{
  int len,is_der=0==strncmp("der(", varName, 4);
  const char *has_dot=NULL;
  const char *c = varName;
  char *res = NULL;
  while (*c) {
    if (*c=='.') {
      has_dot = c;
    }
    c++;
  }
  if (!(is_der&&has_dot)) {
    return NULL; /* The Dymola name is the same as OMC */
  }
  len = strlen(varName);
  res = (char*) malloc(len+1);
  res[len]='\0';

  memcpy(res, varName+4, has_dot-varName-3);
  sprintf(res+(has_dot-varName)-3, "der(%s", has_dot+1);

  /* fprintf(stderr, "Dymola style %s -> %s\n", varName, res); */
  return res;
}

char* openmodelicaStyleVariableName(const char *varName)
{
  int len;
  const char *der=strstr(varName, "der(");
  const char *c = varName;
  char *res = NULL;
  if (!der || der == varName) {
    return NULL;
  }
  len = strlen(varName);
  res = (char*) malloc(len+1);
  res[len]='\0';

  memcpy(res, "der(", 4);
  memcpy(res+4, varName, der-varName);
  memcpy(res+(der-varName)+4, der+4, len-(der-varName+4));

  return res;
}

ModelicaMatVariable_t *omc_matlab4_find_var(ModelicaMatReader *reader, const char *varName)
{
  ModelicaMatVariable_t key;
  ModelicaMatVariable_t *res;
  char *dymolaName = NULL;

  key.name = (char*) varName;

  res = (ModelicaMatVariable_t*)bsearch(&key,reader->allInfo,reader->nall,sizeof(ModelicaMatVariable_t),omc_matlab4_comp_var);
  if (res == NULL) { /* Try to convert the name to a Dymola name */
    /* fprintf(stderr, "Did not find: %s\n", varName); */
    if (0==strcmp(varName, "time")) {
      key.name = "Time";
      return (ModelicaMatVariable_t*)bsearch(&key,reader->allInfo,reader->nall,sizeof(ModelicaMatVariable_t),omc_matlab4_comp_var);
    } else if (0==strcmp(varName, "Time")) {
      key.name = "time";
      return (ModelicaMatVariable_t*)bsearch(&key,reader->allInfo,reader->nall,sizeof(ModelicaMatVariable_t),omc_matlab4_comp_var);
    }
    dymolaName = dymolaStyleVariableName(varName);
    if (dymolaName == NULL) {
      dymolaName = openmodelicaStyleVariableName(varName);
    }
    if (dymolaName == NULL) {
      return NULL;
    }
    key.name = dymolaName;
    /* fprintf(stderr, "Look for dymola style name: %s\n", dymolaName); */
    res = (ModelicaMatVariable_t*)bsearch(&key,reader->allInfo,reader->nall,sizeof(ModelicaMatVariable_t),omc_matlab4_comp_var);
    free(dymolaName);
  }
  return res;
}

/* Writes the number of values in the returned array if nvals is non-NULL */
double* omc_matlab4_read_vals(ModelicaMatReader *reader, int varIndex)
{
  size_t absVarIndex = abs(varIndex);
  size_t ix = (varIndex < 0 ? absVarIndex + reader->nvar : absVarIndex) -1;
  assert(absVarIndex > 0 && absVarIndex <= reader->nvar);
  if (0 == reader->nrows) {
    return NULL;
  } else if(!reader->vars[ix]) {
    unsigned int i;
    double *tmp = (double*) malloc(reader->nrows*sizeof(double));
    if(reader->doublePrecision==1)
    {
      for(i=0; i<reader->nrows; i++) {
        fseek(reader->file,reader->var_offset + sizeof(double)*(i*reader->nvar + absVarIndex-1), SEEK_SET);
        if(1 != fread(&tmp[i], sizeof(double), 1, reader->file)) {
          /* fprintf(stderr, "Corrupt file at %d of %d? nvar %d\n", i, reader->nrows, reader->nvar); */
          free(tmp);
          tmp=NULL;
          return NULL;
        }
        if(varIndex < 0) tmp[i] = -tmp[i];
        /* fprintf(stderr, "tmp[%d]=%g\n", i, tmp[i]); */
      }
    }
    else
    {
      float *buffer = (float*) malloc(reader->nrows*sizeof(float));
      for(i=0; i<reader->nrows; i++) {
        fseek(reader->file,reader->var_offset + sizeof(float)*(i*reader->nvar + absVarIndex-1), SEEK_SET);
        if(1 != fread(&buffer[i], sizeof(float), 1, reader->file)) {
          /* fprintf(stderr, "Corrupt file at %d of %d? nvar %d\n", i, reader->nrows, reader->nvar); */
          free(buffer);
          free(tmp);
          tmp=NULL;
          return NULL;
        }
      }
      if(varIndex < 0)
      {
        for(i=0; i<reader->nrows; i++) {
          tmp[i] = -buffer[i];
        }
      }
      else
      {
          for(i=0; i<reader->nrows; i++) {
            tmp[i] = buffer[i];
          }
      }
      free(buffer);
      /* fprintf(stderr, "tmp[%d]=%g\n", i, tmp[i]); */
    }
    reader->vars[ix] = tmp;
  }
  return reader->vars[ix];
}

void matrix_transpose(double *m, int w, int h)
{
  int start;
  double tmp;

  for (start = 0; start <= w * h - 1; start++) {
    int next = start;
    int i = 0;
    do {  i++;
      next = (next % h) * w + next / h;
    } while (next > start);
    if (next < start || i == 1) continue;

    tmp = m[next = start];
    do {
      i = (next % h) * w + next / h;
      m[next] = (i == start) ? tmp : m[i];
      next = i;
    } while (next > start);
  }
}

void matrix_transpose_uint32(uint32_t *m, int w, int h)
{
  int start;
  uint32_t tmp;

  for (start = 0; start <= w * h - 1; start++) {
    int next = start;
    int i = 0;
    do {  i++;
      next = (next % h) * w + next / h;
    } while (next > start);
    if (next < start || i == 1) continue;

    tmp = m[next = start];
    do {
      i = (next % h) * w + next / h;
      m[next] = (i == start) ? tmp : m[i];
      next = i;
    } while (next > start);
  }
}

int omc_matlab4_read_all_vals(ModelicaMatReader *reader)
{
  int done = reader->readAll;
  int i,j;
  double *tmp;
  int nrows = reader->nrows, nvar = reader->nvar;
  if (nvar == 0 || nrows == 0) {
    return 1;
  }
  for (i=0; i<2*nvar; i++) {
    if (reader->vars[i] == 0) done = 0;
  }
  if (done) {
    reader->readAll = 1;
    return 0;
  }
  tmp = (double*) malloc(2*nvar*nrows*sizeof(double));
  if (!tmp) {
    return 1;
  }
  fseek(reader->file, reader->var_offset, SEEK_SET);
  if (nvar*reader->nrows != fread(tmp, reader->doublePrecision==1 ? sizeof(double) : sizeof(float), nvar*nrows, reader->file)) {
    free(tmp);
    return 1;
  }
  if(reader->doublePrecision != 1) {
    for (i=nvar*nrows-1; i>=0; i--) {
      tmp[i] = ((float*)tmp)[i];
    }
  }
  matrix_transpose(tmp,nvar,nrows);
  /* Negative aliases */
  for (i=0; i<nrows*nvar; i++) {
    tmp[nrows*nvar + i] = -tmp[i];
  }
  /* Setup all the pointers */
  for (i=0; i<2*nvar; i++) {
    if (!reader->vars[i]) {
      reader->vars[i] = (double*) malloc(nrows*sizeof(double));
      memcpy(reader->vars[i], tmp + i*nrows, nrows*sizeof(double));
    }
  }
  free(tmp);
  reader->readAll = 1;
  return 0;
}

double omc_matlab4_read_single_val(double *res, ModelicaMatReader *reader, int varIndex, int timeIndex)
{
  size_t absVarIndex = abs(varIndex);
  size_t ix = (varIndex < 0 ? absVarIndex + reader->nvar : absVarIndex) -1;
  assert(absVarIndex > 0 && absVarIndex <= reader->nvar);
  if(reader->vars[ix]) {
    *res = reader->vars[ix][timeIndex];
    return 0;
  }
  if(reader->doublePrecision==1) {
    fseek(reader->file,reader->var_offset + sizeof(double)*(timeIndex*reader->nvar + absVarIndex-1), SEEK_SET);
    if(1 != fread(res, sizeof(double), 1, reader->file)) {
      *res = 0;
      return 1;
    }
  } else {
    float tmpres;
    fseek(reader->file,reader->var_offset + sizeof(float)*(timeIndex*reader->nvar + absVarIndex-1), SEEK_SET);
    if(1 != fread(&tmpres, sizeof(float), 1, reader->file)) {
      *res = 0;
      return 1;
    }
    *res = tmpres;
  }
  if(varIndex < 0) {
    *res = -(*res);
  }
  return 0;
}

void find_closest_points(double key, double *vec, int nelem, int *index1, double *weight1, int *index2, double *weight2)
{
  int min = 0;
  int max = nelem-1;
  /* fprintf(stderr, "search closest: %g in %d elem\n", key, nelem); */
  do {
    int mid = min + (max-min)/2;
    if(key == vec[mid]) {
      /* If we have events (multiple identical time stamps), use the right limit */
      while(mid < max && vec[mid] == vec[mid+1]) mid++;
      *index1 = mid;
      *weight1 = 1.0;
      *index2 = -1;
      *weight2 = 0.0;
      return;
    } else if(key > vec[mid]) {
      min = mid + 1;
    } else {
      max = mid - 1;
    }
  } while(max > min);
  if(max == min) {
    if(key > vec[max])
      max++;
    else
      min--;
  }
  *index1 = max;
  *index2 = min;
  /* fprintf(stderr, "closest: %g = (%d,%g),(%d,%g)\n", key, min, vec[min], max, vec[max]); */
  *weight1 = (key - vec[min]) / (vec[max]-vec[min]);
  *weight2 = 1.0 - *weight1;
}

static void read_start_stop_time(ModelicaMatReader *reader)
{
  double *d = omc_matlab4_read_vals(reader, 1);
  if (d==NULL) {
    return;
  }
  reader->startTime = d[0];
  reader->stopTime = d[reader->nrows-1];
}

double omc_matlab4_startTime(ModelicaMatReader *reader)
{
  if (reader->startTime != reader->startTime /* NaN */) {
    read_start_stop_time(reader);
  }
  return reader->startTime;
}

double omc_matlab4_stopTime(ModelicaMatReader *reader)
{
  if (reader->stopTime != reader->stopTime /* NaN */) {
    read_start_stop_time(reader);
  }
  return reader->stopTime;
}

/* Returns 0 on success */
int omc_matlab4_val(double *res, ModelicaMatReader *reader, ModelicaMatVariable_t *var, double time)
{
  if(var->isParam) {
    if(var->index < 0)
      *res = -reader->params[abs(var->index)-1];
    else
      *res = reader->params[var->index-1];
  } else {
    double w1,w2,y1,y2;
    int i1,i2;
    if(time > omc_matlab4_stopTime(reader)) {
      *res = NAN;
      return 1;
    }
    if(time < omc_matlab4_startTime(reader)) {
      *res = NAN;
      return 1;
    }
    if(!omc_matlab4_read_vals(reader,1)) {
      *res = NAN;
      return 1;
    }
    find_closest_points(time, reader->vars[0], reader->nrows, &i1, &w1, &i2, &w2);
    if(i2 == -1) {
      return (int)omc_matlab4_read_single_val(res,reader,var->index,i1);
    } else if(i1 == -1) {
      return (int)omc_matlab4_read_single_val(res,reader,var->index,i2);
    } else {
      if(omc_matlab4_read_single_val(&y1,reader,var->index,i1)) return 1;
      if(omc_matlab4_read_single_val(&y2,reader,var->index,i2)) return 1;
      *res = w1*y1 + w2*y2;
      return 0;
    }
  }
  return 0;
}

int omc_matlab4_read_vars_val(double *res, ModelicaMatReader *reader, ModelicaMatVariable_t **vars, int N, double time){
    double w1,w2,y1,y2;
    int i,i1,i2;
    if(time > omc_matlab4_stopTime(reader)) return 1;
    if(time < omc_matlab4_startTime(reader)) return 1;
    if(!omc_matlab4_read_vals(reader,1)) return 1;
    find_closest_points(time, reader->vars[0], reader->nrows, &i1, &w1, &i2, &w2);
    for (i = 0; i< N; i++){
      if(vars[i]->isParam) {
        if(vars[i]->index < 0)
          res[i] = -reader->params[abs(vars[i]->index)-1];
        else
          res[i] = reader->params[vars[i]->index-1];
      } else {
        if(i2 == -1) {

          if (omc_matlab4_read_single_val(&res[i],reader,vars[i]->index,i1)) return 1;

        } else if(i1 == -1) {

          if (omc_matlab4_read_single_val(&res[i],reader,vars[i]->index,i2)) return 1;

        } else {

          if(omc_matlab4_read_single_val(&y1,reader,vars[i]->index,i1)) return 1;
          if(omc_matlab4_read_single_val(&y2,reader,vars[i]->index,i2)) return 1;
          res[i] = w1*y1 + w2*y2;

        }
      }
    }
    return 0;
}

void omc_matlab4_print_all_vars(FILE *stream, ModelicaMatReader *reader)
{
  unsigned int i;
  fprintf(stream, "allSortedVars(\"%s\") => {", reader->fileName);
  for(i=0; i<reader->nall; i++)
    fprintf(stream, "\"%s\",", reader->allInfo[i].name);
  fprintf(stream, "}\n");
}

#if 0
int main(int argc, char** argv)
{
  ModelicaMatReader reader;
  const char *msg;
  int i;
  double r;
  ModelicaMatVariable_t *var;
  if(argc < 2) {
    fprintf(stderr, "Usage: %s filename.mat var0 ... varn\n", *argv);
    exit(1);
  }
  if(0 != (msg=omc_new_matlab4_reader(argv[1],&reader))) {
    fprintf(stderr, "%s is not in the MATLAB4 subset accepted by OpenModelica: %s\n", argv[1], msg);
    exit(1);
  }
  omc_matlab4_print_all_vars(stderr, &reader);
  for(i=2; i<argc; i++) {
    int printAll = *argv[i] == '.';
    char *name = argv[i] + printAll;
    var = omc_matlab4_find_var(&reader, name);
    if(!var) {
      fprintf(stderr, "%s not found\n", name);
    } else if(printAll) {
      int n,j;
      if(var->isParam) {
        fprintf(stderr, "%s is param, but tried to read all values", name);
        continue;
      }
      double *vals = omc_matlab4_read_vals(&n,&reader,var->index);
      if(!vals) {
        fprintf(stderr, "%s = #FAILED TO READ VALS", name);
      } else {
        fprintf(stderr, "  allValues(%s) => {", name);
        for(j=0; j<n; j++)
          fprintf(stderr, "%g,", vals[j]);
        fprintf(stderr, "}\n");
      }
    } else {
      int j;
      double ts[4] = {-1.0,0.0,0.1,1.0};
      for(j=0; j<4; j++)
        if(0==omc_matlab4_val(&r,&reader,var,ts[j]))
          fprintf(stderr, "  val(\"%s\",%4g) => %g\n", name, ts[j], r);
        else
          fprintf(stderr, "  val(\"%s\",%4g) => fail()\n", name, ts[j]);
    }
  }
  omc_free_matlab4_reader(&reader);
  return 0;
}
#endif
