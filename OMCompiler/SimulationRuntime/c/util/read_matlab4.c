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

/**
 * @brief Compare two null-terminated strings while ignoring whitespace.
 *
 * This comparison advances over any whitespace characters in either
 * string before comparing the next non-whitespace character. It is
 * useful for comparing variable names where spacing may differ.
 *
 * @param a First null-terminated string.
 * @param b Second null-terminated string.
 * @return 0 if equal when ignoring whitespace, >0 if a>b, <0 if a<b.
 */
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

/**
 * @brief Comparator wrapper used for sorting/searching Modelica variables.
 *
 * Compares two ModelicaMatVariable_t objects by their name fields using
 * whitespace-ignoring comparison (`strcmp_iws`). This function is suitable
 * for use with `qsort` and `bsearch`.
 *
 * @param a Pointer to the first ModelicaMatVariable_t.
 * @param b Pointer to the second ModelicaMatVariable_t.
 * @return See `strcmp_iws`: 0 if equal, >0 if a>b, <0 if a<b.
 */
int omc_matlab4_comp_var(const void *a, const void *b)
{
  char *as = ((ModelicaMatVariable_t*)a)->name;
  char *bs = ((ModelicaMatVariable_t*)b)->name;

  return strcmp_iws(as,bs);
}

/**
 * @brief Determine the byte-length of an element from MATLAB v4 type code.
 *
 * The MATLAB v4 matrix type encodes element size and format. This helper
 * extracts the relevant fields and returns the element length in bytes.
 *
 * @param type MATLAB v4 matrix type code.
 * @return Element length in bytes on success, or -1 if unsupported/invalid.
 */
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

/**
 * @brief Free resources held by a ModelicaMatReader.
 *
 * Frees any allocated memory and closes the file associated with `reader`.
 * After this call the contents of `reader` should not be accessed.
 *
 * @param reader Pointer to an initialized ModelicaMatReader.
 */
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

/**
 * @brief Trim leading and trailing whitespace in-place.
 *
 * Modifies the provided C string by removing leading and trailing
 * whitespace characters. The operation moves characters forward when
 * needed and ensures the result is null-terminated.
 *
 * @param str Null-terminated string to trim (modified in-place).
 */
void trimWhitespace(char *str)
{
  char *start = str;
  char *end;
  size_t len = strlen(str);
  if (len > 0 && (isspace(*start) || isspace(str[len-1]))) {
    /* find first non-whitespace */
    while (isspace(*start)) {
      ++start;
    }
    /* find last non-whitespace */
    end = start + strlen(start) - 1;
    while (end > str && isspace(*end)) {
      --end;
    }
    len = end - start + 1;
    /* shift the string to remove leading whitespace */
    if (start != str) memmove(str, start, len);
    /* terminate the string to remove trailing whitespace */
    *(str+len) = '\0';
  }
}

/**
 * @brief Read character data from a MATLAB v4 matrix into a buffer.
 *
 * Depending on the encoded precision in `type`, elements may be stored as
 * doubles or as bytes. If stored as doubles they will be converted to
 * characters by casting. The function attempts to read exactly `n`
 * elements into `str`.
 *
 * @param type MATLAB v4 matrix type code.
 * @param n Number of elements to read.
 * @param file Open FILE pointer positioned at the matrix payload.
 * @param str Destination buffer with space for at least `n` bytes.
 * @return 0 on success, non-zero on read/format error.
 */
static int read_chars(int type, size_t n, FILE *file, char *str)
{
  int p = (type%100)/10;
  if (p == 0) { /* Double */
    double d=0.0;
    int k;
    for (k=0; k<n; k++) {
      if (omc_fread(&d, sizeof(double), 1, file, 0) != 1) {
        return 1;
      }
      str[k] = (char) d;
    }
    return 0;
  } else if (p == 5) { /* Byte */
    return omc_fread(str,n,1,file, 0) != 1;
  }
  return 1;
}

/**
 * @brief Read 32-bit integer data from a MATLAB v4 matrix into an array.
 *
 * If the stored element type is double, values are read as doubles and
 * converted to int32_t. If stored as int32 they are read directly.
 *
 * @param type MATLAB v4 matrix type code.
 * @param n Number of integers to read.
 * @param file Open FILE pointer positioned at the matrix payload.
 * @param val Destination array of at least `n` int32_t elements.
 * @return 0 on success, non-zero on read/format error.
 */
static int read_int32(int type, size_t n, FILE *file, int32_t *val)
{
  int p = (type%100)/10;
  if (p == 0) { /* Double */
    double d=0.0;
    int k;
    for (k=0; k<n; k++) {
      if (omc_fread(&d, sizeof(double), 1, file, 0) != 1) {
        return 1;
      }
      val[k] = (int32_t) d;
    }
    return 0;
  } else if (p == 2) { /* int32 */
    return omc_fread(val,n*sizeof(int32_t),1,file, 0) != 1;
  }
  return 1;
}

/**
 * @brief Read floating point (double/float) data from a MATLAB v4 matrix.
 *
 * If the stored precision is double the function reads doubles directly.
 * If the stored precision is float the values are read as floats and cast
 * to double in the destination array.
 *
 * @param type MATLAB v4 matrix type code.
 * @param n Number of floating point elements to read.
 * @param file Open FILE pointer positioned at the matrix payload.
 * @param val Destination array of at least `n` doubles.
 * @return 0 on success, non-zero on read/format error.
 */
static int read_double(int type, size_t n, FILE *file, double *val)
{
  int p = (type%100)/10;
  if (n==0) {
    return 0;
  }
  if (p == 0) { /* Double */
    return omc_fread(val,n*sizeof(double),1,file, 0) != 1;
  } else if (p == 1) { /* float */
    float f=0.0;
    int k;
    for (k=0; k<n; k++) {
      if (omc_fread(&f, sizeof(float), 1, file, 0) != 1) {
        return 1;
      }
      val[k] = (double) f;
    }
    return 0;
  }
  return 1;
}

/**
 * @brief Open and parse a MATLAB v4 file into a ModelicaMatReader.
 *
 * This function opens `filename`, validates that it contains the expected
 * set of MATLAB v4 matrices for OpenModelica (`Aclass`, `name`,
 * `description`, `dataInfo`, `data_1`, `data_2`) and populates the
 * provided `reader` structure with metadata and file offsets for later
 * value reads. The reader is initialized (zeroed) by this call.
 *
 * The function uses a subset of MATLAB v4 files accepted by OpenModelica
 * and will return a textual error describing the first problem found.
 *
 * #### Notes:
 *
 * The internal data is free'd by `omc_free_matlab4_reader`.
 * The data persists until free'd, and is safe to use in your own data
 * structures.
 *
 * @param filename Path to the MATLAB v4 file to open (must be readable).
 * @param reader Pointer to an allocated ModelicaMatReader that will be
 *               initialized by this function.
 * @return 0 on success, or a pointer to a static error string on failure.
 *         The returned string should not be freed by the caller.
 */
const char* omc_new_matlab4_reader(const char *filename, ModelicaMatReader *reader)
{
  const int nMatrix=6;
  static const char *matrixNames[6]={"Aclass","name","description","dataInfo","data_1","data_2"};
  static const char *matrixNamesMismatch[6]={"Matrix name mismatch: Aclass","Matrix name mismatch: name","Matrix name mismatch: description","Matrix name mismatch: dataInfo","Matrix name mismatch: data_1","Matrix name mismatch: data_2"};
  const int matrixTypes[6]={51,51,51,20,0,0};
  int i;
  char binTrans = 1;
  memset(reader, 0, sizeof(ModelicaMatReader));
  reader->startTime = NaN;
  reader->stopTime = NaN;
  reader->file = omc_fopen(filename, "rb");
  if(!reader->file) return strerror(errno);
  reader->fileName = strdup(filename);
  reader->readAll = 0;
  reader->stopTime = NAN;
  for(i=0; i<nMatrix;i++) {
    MHeader_t hdr;
    int nr = omc_fread(&hdr,sizeof(MHeader_t),1,reader->file, 0);
    size_t matrix_length,element_length;
    char *name;
    if(nr != 1) return "Corrupt header (1)";
    /* fprintf(stderr, "Found matrix %d=%s type=%04d mrows=%d ncols=%d imagf=%d namelen=%d\n", i, name, hdr.type, hdr.mrows, hdr.ncols, hdr.imagf, hdr.namelen); */
    if(hdr.imagf > 1) return "Matrix uses imaginary numbers";
    if((element_length = mat_element_length(hdr.type)) == -1) return "Could not determine size of matrix elements";
    name = (char*) malloc(hdr.namelen);
    nr = omc_fread(name,hdr.namelen,1,reader->file, 0);
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
          trimWhitespace(reader->allInfo[k].name);
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
          trimWhitespace(reader->allInfo[k].name);
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
        if(-1==omc_fseek(reader->file,matrix_length,SEEK_CUR)) return "Corrupt header: data_2 matrix";
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

        if(-1==omc_fseek(reader->file,matrix_length,SEEK_CUR)) return "Corrupt header: data_2 matrix";
      }
      break;
    }
    default:
      return "Implementation error: Unknown case";
    }
  }
  return 0;
}

/**
 * @brief Convert an OpenModelica variable name into Dymola "der" style.
 *
 * If `varName` contains a dot and is of the form "der(X.Y)" in Dymola
 * style, this function returns a malloc'd string with the converted
 * representation. If no conversion is needed the function returns NULL.
 *
 * Caller must free the returned string when non-NULL.
 *
 * @param varName Input variable name.
 * @return Newly allocated converted name, or NULL if no conversion was
 *         necessary or on allocation failure.
 */
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

/**
 * @brief Convert a Dymola-style variable name into OpenModelica style.
 *
 * Transforms occurrences where the derivative is expressed at the end of
 * the name (e.g. "x.der(y)") into OpenModelica's "der(x.y)" style.
 * Returns a malloc'd string on success or NULL if no transformation is
 * necessary. Caller must free the returned string.
 *
 * @param varName Input variable name.
 * @return Newly allocated converted name or NULL.
 */
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

/**
 * @brief Find a variable by name in the reader's variable metadata.
 *
 * Performs a binary search (via `bsearch`) over the sorted variable list
 * and tries a few name conversion fallbacks if the direct lookup fails:
 * - checks for "time"/"Time" aliases
 * - attempts Dymola/OpenModelica style conversions
 *
 * @param reader Pointer to an initialized ModelicaMatReader.
 * @param varName Null-terminated variable name to search for.
 * @return Pointer to the matching ModelicaMatVariable_t in `reader->allInfo`,
 *         or NULL if not found.
 */
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

/**
 * @brief Read (or lazily load) the full time series for a variable.
 *
 * If the requested variable's data has not been loaded yet this function
 * reads the column from the file, converts if necessary and stores it in
 * the reader cache (`reader->vars`). The `varIndex` follows the file
 * convention where negative indices refer to the negative alias of a
 * variable (i.e. sign-inverted values).
 *
 * @param reader Pointer to an initialized ModelicaMatReader.
 * @param varIndex 1-based variable index; negative values select the
 *                 negative alias of the variable.
 * @return Pointer to an array of `reader->nrows` doubles containing the
 *         time series for the variable, or NULL on failure or if there are
 *         no rows.
 */
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
        omc_fseek(reader->file,reader->var_offset + sizeof(double)*(i*reader->nvar + absVarIndex-1), SEEK_SET);
        if(1 != omc_fread(&tmp[i], sizeof(double), 1, reader->file, 0)) {
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
        omc_fseek(reader->file,reader->var_offset + sizeof(float)*(i*reader->nvar + absVarIndex-1), SEEK_SET);
        if(1 != omc_fread(&buffer[i], sizeof(float), 1, reader->file, 0)) {
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

/**
 * @brief In-place transpose of a w-by-h matrix stored in row-major order.
 *
 * The algorithm performs the transpose without allocating a separate
 * buffer. The matrix is assumed to be stored contiguous in `m` with
 * dimensions w (width) and h (height).
 *
 * @param m Pointer to the matrix data (length w*h).
 * @param w Width (number of columns) of the original matrix.
 * @param h Height (number of rows) of the original matrix.
 */
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

/**
 * @brief In-place transpose for a uint32_t matrix (same semantics as
 *        matrix_transpose).
 *
 * @param m Pointer to the uint32_t matrix data (length w*h).
 * @param w Width (number of columns) of the original matrix.
 * @param h Height (number of rows) of the original matrix.
 */
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

/**
 * @brief Read all variable values from the file into memory.
 *
 * Allocates buffers for all variables and reads the entire data block
 * from disk. After a successful call all `reader->vars[i]` pointers will
 * be non-NULL and `reader->readAll` will be set.
 *
 * @param reader Pointer to an initialized ModelicaMatReader.
 * @return 0 on success, 1 on failure (allocation or read error).
 */
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
  omc_fseek(reader->file, reader->var_offset, SEEK_SET);
  if (nvar*reader->nrows != omc_fread(tmp, reader->doublePrecision==1 ? sizeof(double) : sizeof(float), nvar*nrows, reader->file, 0)) {
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

/**
 * @brief Read a single value for a variable at a specific time index.
 *
 * If the variable has been cached in memory the value is read from the
 * cache. Otherwise the function seeks to the appropriate file position
 * and reads either a double or float depending on `reader->doublePrecision`.
 *
 * @param res Output pointer where the value will be stored.
 * @param reader Pointer to an initialized ModelicaMatReader.
 * @param varIndex 1-based variable index; negative values select the
 *                 negative alias of the variable.
 * @param timeIndex Zero-based index into the time series (0..nrows-1).
 * @return 0 on success, non-zero on failure (read error or invalid index).
 */
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
    omc_fseek(reader->file,reader->var_offset + sizeof(double)*(timeIndex*reader->nvar + absVarIndex-1), SEEK_SET);
    if(1 != omc_fread(res, sizeof(double), 1, reader->file, 0)) {
      *res = 0;
      return 1;
    }
  } else {
    float tmpres;
    omc_fseek(reader->file,reader->var_offset + sizeof(float)*(timeIndex*reader->nvar + absVarIndex-1), SEEK_SET);
    if(1 != omc_fread(&tmpres, sizeof(float), 1, reader->file, 0)) {
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

/**
 * @brief Find the two closest points surrounding `key` in a sorted vector.
 *
 * Performs a binary search over `vec` (length `nelem`) which is expected
 * to be sorted in ascending order. If an exact match is found the function
 * returns that index in `index1`, sets `index2` to -1 and `weight1`=1.
 * Otherwise it returns the two neighboring indices and linear
 * interpolation weights so that value(key) = weight1 * vec[index1] + weight2 * vec[index2].
 *
 * @param key Value to locate.
 * @param vec Sorted array of doubles (length `nelem`).
 * @param nelem Number of elements in `vec`.
 * @param index1 Output index for the right-side neighbour (or exact match).
 * @param weight1 Output interpolation weight for index1.
 * @param index2 Output index for the left-side neighbour, or -1 on exact match.
 * @param weight2 Output interpolation weight for index2.
 */
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

/**
 * @brief Populate `reader->startTime` and `reader->stopTime` from the time column.
 *
 * Attempts to read the time series (variable index 1) and sets start/stop
 * time to the first and last entry respectively. If the time vector cannot
 * be read the function leaves the values unchanged.
 *
 * @param reader Pointer to an initialized ModelicaMatReader.
 */
static void read_start_stop_time(ModelicaMatReader *reader)
{
  double *d = omc_matlab4_read_vals(reader, 1);
  if (d==NULL) {
    return;
  }
  reader->startTime = d[0];
  reader->stopTime = d[reader->nrows-1];
}

/**
 * @brief Get the start time of the dataset managed by `reader`.
 *
 * If the start time has not yet been determined this function will read
 * the time column lazily to extract the first timestamp.
 *
 * @param reader Pointer to an initialized ModelicaMatReader.
 * @return Start time as a double (NaN if unknown/unreadable).
 */
double omc_matlab4_startTime(ModelicaMatReader *reader)
{
  if (reader->startTime != reader->startTime /* NaN */) {
    read_start_stop_time(reader);
  }
  return reader->startTime;
}

/**
 * @brief Get the stop time of the dataset managed by `reader`.
 *
 * If the stop time has not yet been determined this function will read
 * the time column lazily to extract the last timestamp.
 *
 * @param reader Pointer to an initialized ModelicaMatReader.
 * @return Stop time as a double (NaN if unknown/unreadable).
 */
double omc_matlab4_stopTime(ModelicaMatReader *reader)
{
  if (reader->stopTime != reader->stopTime /* NaN */) {
    read_start_stop_time(reader);
  }
  return reader->stopTime;
}

/**
 * @brief Evaluate a variable (parameter or time-dependent) at a given time.
 *
 * If `var` represents a parameter the value is returned directly from
 * `reader->params`. For time-dependent variables a nearest-neighbour or
 * linear interpolation between the two surrounding time points is used.
 *
 * @param res Output pointer where the evaluated value will be stored.
 * @param reader Pointer to an initialized ModelicaMatReader.
 * @param var Pointer to the variable metadata (from `omc_matlab4_find_var`).
 * @param time Time at which to evaluate the variable.
 * @return 0 on success, non-zero on error (out of range, read failure).
 */
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

/**
 * @brief Read multiple variables at a given time into a result array.
 *
 * For each variable in `vars` this function either returns the parameter
 * value or performs interpolation from the time-series data. Results are
 * written into the `res` array (length N).
 *
 * #### Note
 *
 * This function is not defined for parameters.
 * Check `var->isParam` and then send the index.
 *
 * No bounds checking is performed.
 * The returned data persists until the reader is closed.
 *
 * @param res Output array of length N where values will be stored.
 * @param reader Pointer to an initialized ModelicaMatReader.
 * @param vars Array of N pointers to ModelicaMatVariable_t descriptors.
 * @param N Number of variables to read.
 * @param time Time at which to evaluate the variables.
 * @return 0 on success, non-zero on failure (out-of-range or read error).
 */
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

/**
 * @brief Print all variables to file.
 *
 * #### Notes:
 *
 * For debugging purpose
 *
 * @param stream    Text file to write to.
 * @param reader    Pointer to an initialized ModelicaMatReader.
 */
void omc_matlab4_print_all_vars(FILE *stream, ModelicaMatReader *reader)
{
  unsigned int i;
  fprintf(stream, "allSortedVars(\"%s\") => {", reader->fileName);
  for(i=0; i<reader->nall; i++)
    fprintf(stream, "\"%s\",", reader->allInfo[i].name);
  fprintf(stream, "}\n");
}
