#ifndef OMC_READ_MATLAB4_H
#define OMC_READ_MATLAB4_H

#include <stdio.h>
#include <stdint.h>

extern const char *omc_mat_Aclass;

typedef struct {
  uint32_t type;
  uint32_t mrows;
  uint32_t ncols;
  uint32_t imagf;
  uint32_t namelen;
} MHeader_t;

typedef struct {
  char *name,*descr;
  int isParam;
  /* Parameters are stored in data_1, variables in data_2; parameters are defined at any time, variables only within the simulation start/stop interval */
  int index;
} ModelicaMatVariable_t;

typedef struct {
  FILE *file;
  char *fileName;
  uint32_t nall;
  ModelicaMatVariable_t *allInfo; /* Sorted array of variables and their associated information */
  uint32_t nparam;
  double *params; /* This has size 2*nparam; the first parameter has row0=startTime,row1=stopTime. Other variables are stored as row0=row1 */
  uint32_t nvar,nrows;
  size_t var_offset; /* This is the offset in the file */
  double **vars;
  char doublePrecision; /* data_1 and data_2 in double ore single precision */
} ModelicaMatReader;

/* Returns 0 on success; the error message on error.
 * The internal data is free'd by omc_free_matlab4_reader.
 * The data persists until free'd, and is safe to use in your own data-structures
 */
#ifdef __cplusplus
extern "C" {
#endif
const char* omc_new_matlab4_reader(const char *filename, ModelicaMatReader *reader);

void omc_free_matlab4_reader(ModelicaMatReader *reader);

/* Returns a variable or NULL */
ModelicaMatVariable_t *omc_matlab4_find_var(ModelicaMatReader *reader, const char *varName);

/* Writes the number of values in the returned array if nvals is non-NULL
 * Returns all values that the given variable may have.
 * Note: This function is _not_ defined for parameters; check var->isParam and then send the index
 * No bounds checking is performed. The returned data persists until the reader is closed.
 */
double* omc_matlab4_read_vals(ModelicaMatReader *reader, int varIndex);

/* Returns 0 on success */
int omc_matlab4_val(double *res, ModelicaMatReader *reader, ModelicaMatVariable_t *var, double time);

/* For debugging */
void omc_matlab4_print_all_vars(FILE *stream, ModelicaMatReader *reader);

double omc_matlab4_startTime(ModelicaMatReader *reader);

double omc_matlab4_stopTime(ModelicaMatReader *reader);
#ifdef __cplusplus
} /* extern "C" */
#endif

#endif
