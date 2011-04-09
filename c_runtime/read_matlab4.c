#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <string.h>
#include "read_matlab4.h"

#define size_omc_mat_Aclass 45
const char *omc_mat_Aclass = "A1 bt. ir1 na  Tj  re  ac  nt  so   r   y   ";

int omc_matlab4_comp_var(const void *a, const void *b)
{
  char *as = ((ModelicaMatVariable_t*)a)->name;
  char *bs = ((ModelicaMatVariable_t*)b)->name;
  return strcmp(as,bs);
}

int mat_element_length(int type)
{
  int m = (type/1000);
  int o = (type%1000)/100;
  int p = (type%100)/10;
  int t = (type%10);
  if (m) return -1; /* We require IEEE Little Endian for now */
  if (o) return -1; /* Reserved number; forced 0 */
  if (t == 1 && p != 5) return -1; /* Text matrix? Force element length=1 */
  if (t == 2) return -1; /* Sparse matrix fails */
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
  fclose(reader->file);
  free(reader->fileName); reader->fileName=NULL;
  for (i=0; i<reader->nall; i++)
    free(reader->allInfo[i].name);
  free(reader->allInfo); reader->allInfo=NULL;
  free(reader->params); reader->params=NULL;
  for (i=0; i<reader->nvar*2; i++)
    if (reader->vars[i]) free(reader->vars[i]);
  free(reader->vars); reader->vars=NULL;
}

/* Returns 0 on success; the error message on error */
const char* omc_new_matlab4_reader(const char *filename, ModelicaMatReader *reader)
{
  typedef const char *_string;
  const int nMatrix=6;
  _string matrixNames[6]={"Aclass","name","description","dataInfo","data_1","data_2"};
  const int matrixTypes[6]={51,51,51,0,0,0};
  int i;
  reader->file = fopen(filename, "rb");
  if (!reader->file) return strerror(errno);
  reader->fileName = strdup(filename);
  for (i=0; i<nMatrix;i++) {
    MHeader_t hdr;
    int nr = fread(&hdr,sizeof(MHeader_t),1,reader->file);
    int matrix_length,element_length;
    char *name;
    if (nr != 1) return "Corrupt header (1)";
    /* fprintf(stderr, "Found matrix type=%04d mrows=%d ncols=%d imagf=%d namelen=%d\n", hdr.type, hdr.mrows, hdr.ncols, hdr.imagf, hdr.namelen); */
    if (hdr.type != matrixTypes[i]) return "Matrix type mismatch";
    if (hdr.imagf > 1) return "Matrix uses imaginary numbers";
    if ((element_length = mat_element_length(hdr.type)) == -1) return "Could not determine size of matrix elements";
    name = (char*) malloc(hdr.namelen);
    nr = fread(name,hdr.namelen,1,reader->file);
    if (nr != 1) return "Corrupt header (2)";
    if (name[hdr.namelen-1]) return "Corrupt header (3)";
    /* fprintf(stderr, "  Name of matrix: %s\n", name); */
    matrix_length = hdr.mrows*hdr.ncols*(1+hdr.imagf)*element_length;
    if (0 != strcmp(name,matrixNames[i])) return "Matrix name mismatch";
    free(name); name=NULL;
    switch (i) {
    case 0: {
      char tmp[size_omc_mat_Aclass];
      if (fread(tmp,size_omc_mat_Aclass-1,1,reader->file) != 1) return "Corrupt header: Aclass matrix";
      tmp[size_omc_mat_Aclass-1] = '\0';
      if (0 != strncmp(tmp,omc_mat_Aclass,size_omc_mat_Aclass)) return "Aclass matrix does not match the magic number";
      break;
    }
    case 1: { /* "names" */
      unsigned int i;
      reader->nall = hdr.ncols;
      reader->allInfo = (ModelicaMatVariable_t*) malloc(sizeof(ModelicaMatVariable_t)*reader->nall);
      for (i=0; i<hdr.ncols; i++) {
        reader->allInfo[i].name = (char*) malloc(hdr.mrows+1);
        if (fread(reader->allInfo[i].name,hdr.mrows,1,reader->file) != 1) return "Corrupt header: names matrix";
        reader->allInfo[i].name[hdr.mrows] = '\0';
        reader->allInfo[i].isParam = -1;
        reader->allInfo[i].index = -1;
        /* fprintf(stderr, "    Adding variable %s\n", reader->allInfo[i].name); */
      }
      break;
    }
    case 2: {
      if (-1==fseek(reader->file,matrix_length,SEEK_CUR)) return "Corrupt header: description matrix";
      break;
    }
    case 3: { /* "dataInfo" */
      unsigned int i;
      double *tmp = (double*) malloc(sizeof(double)*hdr.ncols*hdr.mrows);
      if (1 != fread(tmp,sizeof(double)*hdr.ncols*hdr.mrows,1,reader->file)) {
        free(tmp); tmp=NULL;
        return "Corrupt header: dataInfo matrix";
      }
      for (i=0; i<hdr.ncols; i++) {
        reader->allInfo[i].isParam = tmp[i*hdr.mrows] == 1.0;
        reader->allInfo[i].index = (int) tmp[i*hdr.mrows+1];
        /* fprintf(stderr, "    Variable %s isParam=%d index=%d\n", reader->allInfo[i].name, reader->allInfo[i].isParam, reader->allInfo[i].index); */
      }
      free(tmp); tmp=NULL;
      /* Sort the variables so we can do faster lookup */
      qsort(reader->allInfo,reader->nall,sizeof(ModelicaMatVariable_t),omc_matlab4_comp_var);
      break;
    }
    case 4: { /* "data_1" */
      unsigned int i;
      if (hdr.mrows == 0) return "data_1 matrix does not contain at least 1 variable";
      if (hdr.ncols != 2) return "data_1 matrix does not have 2 rows";
      reader->nparam = hdr.mrows;
      reader->params = (double*) malloc(hdr.mrows*hdr.ncols*sizeof(double));
      if (1 != fread(reader->params,matrix_length,1,reader->file)) return "Corrupt header: data_1 matrix";
      /* fprintf(stderr, "    startTime = %.6g\n", reader->params[0]);
       * fprintf(stderr, "    stopTime = %.6g\n", reader->params[1]); */
      for (i=1; i<reader->nparam; i++) {
        if (reader->params[i] != reader->params[i+reader->nparam]) return "data_1 matrix contained parameter that changed between start and stop-time";
        /* fprintf(stderr, "    Parameter[%d] = %.6g\n", i, reader->params[i]); */
      }
      break;
    }
    case 5: { /* "data_2" */
      reader->nrows = hdr.ncols;
      reader->nvar = hdr.mrows;
      if (reader->nrows < 2) return "Too few rows in data_2 matrix";
      reader->var_offset = ftell(reader->file);
      reader->vars = (double**) calloc(reader->nvar*2,sizeof(double*));
      if (-1==fseek(reader->file,matrix_length,SEEK_CUR)) return "Corrupt header: data_2 matrix";
      break;
    }
    default:
      return "Implementation error: Unknown case";
    }
  };
  return 0;
}

ModelicaMatVariable_t *omc_matlab4_find_var(ModelicaMatReader *reader, const char *varName)
{
  ModelicaMatVariable_t key;
  key.name = (char*) varName;
  return bsearch(&key,reader->allInfo,reader->nall,sizeof(ModelicaMatVariable_t),omc_matlab4_comp_var);
}

/* Writes the number of values in the returned array if nvals is non-NULL */
double* omc_matlab4_read_vals(ModelicaMatReader *reader, int varIndex)
{
  size_t absVarIndex = abs(varIndex);
  size_t ix = varIndex < 0 ? absVarIndex + reader->nvar : absVarIndex;
  if (!reader->vars[ix]) {
    unsigned int i;
    double *tmp = (double*) malloc(reader->nrows*sizeof(double));
    for (i=0; i<reader->nrows; i++) {
      fseek(reader->file,reader->var_offset + sizeof(double)*(i*reader->nvar + absVarIndex-1), SEEK_SET);
      if (1 != fread(&tmp[i], sizeof(double), 1, reader->file)) {
        /* fprintf(stderr, "Corrupt file at %d of %d? nvar %d\n", i, reader->nrows, reader->nvar); */
        free(tmp);
        tmp=NULL;
        return NULL;
      }
      tmp[i] = tmp[i] * (varIndex < 0 ? -1 : 1);
      /* fprintf(stderr, "tmp[%d]=%g\n", i, tmp[i]); */
    }
    reader->vars[ix] = tmp;
  }
  return reader->vars[ix];
}

double omc_matlab4_read_single_val(double *res, ModelicaMatReader *reader, int varIndex, int timeIndex)
{
  size_t absVarIndex = abs(varIndex);
  size_t ix = varIndex < 0 ? absVarIndex + reader->nvar : absVarIndex;
  if (reader->vars[ix]) {
    *res = reader->vars[ix][timeIndex];
    return 0;
  }
  fseek(reader->file,reader->var_offset + sizeof(double)*(timeIndex*reader->nvar + absVarIndex-1), SEEK_SET);
  if (1 != fread(res, sizeof(double), 1, reader->file))
    return 1;
  if (varIndex < 0)
    *res = -(*res);
  return 0;
}

void find_closest_points(double key, double *vec, int nelem, int *index1, double *weight1, int *index2, double *weight2)
{
  int min = 0;
  int max = nelem-1;
  int mid;
  /* fprintf(stderr, "search closest: %g in %d elem\n", key, nelem); */
  do {
    mid = min + (max-min)/2;
    if (key == vec[mid]) {
      /* If we have events (multiple identical time stamps), use the right limit */
      while (mid < max && vec[mid] == vec[mid+1]) mid++;
      *index1 = mid;
      *weight1 = 1.0;
      *index2 = -1;
      *weight2 = 0.0;
      return;
    } else if (key > vec[mid]) {
      min = mid + 1;
    } else {
      max = mid - 1;
    }
  } while (max > min);
  if (max == min) {
    if (key > vec[max])
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

double omc_matlab4_startTime(ModelicaMatReader *reader)
{
  return reader->params[0];
}

double omc_matlab4_stopTime(ModelicaMatReader *reader)
{
  return reader->params[reader->nparam];
}

/* Returns 0 on success */
int omc_matlab4_val(double *res, ModelicaMatReader *reader, ModelicaMatVariable_t *var, double time)
{
  if (var->isParam) {
    if (var->index < 0)
      *res = -reader->params[abs(var->index)-1];
    else
      *res = reader->params[var->index-1];
  } else {
    double w1,w2,y1,y2;
    int i1,i2;
    if (time > omc_matlab4_stopTime(reader)) return 1;
    if (time < omc_matlab4_startTime(reader)) return 1;
    if (!omc_matlab4_read_vals(reader,1)) return 1;
    find_closest_points(time, reader->vars[0], reader->nrows, &i1, &w1, &i2, &w2);
    if (i2 == -1) {
      return omc_matlab4_read_single_val(res,reader,var->index,i1);
    } else if (i1 == -1) {
      return omc_matlab4_read_single_val(res,reader,var->index,i2);
    } else {
      if (omc_matlab4_read_single_val(&y1,reader,var->index,i1)) return 1;
      if (omc_matlab4_read_single_val(&y2,reader,var->index,i2)) return 1;
      *res = w1*y1 + w2*y2;
      return 0;
    }
  }
  return 0;
}

void omc_matlab4_print_all_vars(FILE *stream, ModelicaMatReader *reader)
{
  unsigned int i;
  fprintf(stream, "allSortedVars(\"%s\") => {", reader->fileName);
  for (i=0; i<reader->nall; i++)
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
  if (argc < 2) {
    fprintf(stderr, "Usage: %s filename.mat var0 ... varn\n", *argv);
    exit(1);
  }
  if (0 != (msg=omc_new_matlab4_reader(argv[1],&reader))) {
    fprintf(stderr, "%s is not in the MATLAB4 subset accepted by OpenModelica: %s\n", argv[1], msg);
    exit(1);
  }
  omc_matlab4_print_all_vars(stderr, &reader);
  for (i=2; i<argc; i++) {
    int printAll = *argv[i] == '.';
    char *name = argv[i] + printAll;
    var = omc_matlab4_find_var(&reader, name);
    if (!var) {
      fprintf(stderr, "%s not found\n", name);
    } else if (printAll) {
      int n,j;
      if (var->isParam) {
        fprintf(stderr, "%s is param, but tried to read all values", name);
        continue;
      }
      double *vals = omc_matlab4_read_vals(&n,&reader,var->index);
      if (!vals) {
        fprintf(stderr, "%s = #FAILED TO READ VALS", name);
      } else {
        fprintf(stderr, "  allValues(%s) => {", name);
        for (j=0; j<n; j++)
          fprintf(stderr, "%g,", vals[j]);
        fprintf(stderr, "}\n");
      }
    } else {
      int j;
      double ts[4] = {-1.0,0.0,0.1,1.0};
      for (j=0; j<4; j++)
        if (0==omc_matlab4_val(&r,&reader,var,ts[j]))
          fprintf(stderr, "  val(\"%s\",%4g) => %g\n", name, ts[j], r);
        else
          fprintf(stderr, "  val(\"%s\",%4g) => fail()\n", name, ts[j]);
    }
  }
  omc_free_matlab4_reader(&reader);
  return 0;
}
#endif
