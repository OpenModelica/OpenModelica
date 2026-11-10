/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#include "omc_fmu_init.h"

#include <float.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(OMC_METAMODELICA_RUNTIME)
#include "../meta/meta_modelica_string.h"
#endif
#include "../gc/omc_gc.h"
#include "boolean_array.h"
#include "integer_array.h"
#include "omc_file.h"
#include "omc_strdup.h"
#include "omc_string.h"
#include "real_array.h"
#include "string_array.h"

#define VERSION 1
#define NUM_ARRAYS 8
#define BUFFER_SIZE 65536
#define FIRST_VALUE_REFERENCE 1000
#define MAX_LENGTH (1 << 28)

enum { FLAG_READONLY = 1, FLAG_FIXED = 2, FLAG_USE_NOMINAL = 4, FLAG_DIMENSIONS = 8, FLAG_START = 16 };
enum { ATTR_START, ATTR_MIN, ATTR_MAX, ATTR_NOMINAL };
enum { KIND_REAL, KIND_INTEGER, KIND_BOOLEAN, KIND_STRING };

static const int KIND_OF[NUM_ARRAYS] = {KIND_REAL, KIND_REAL, KIND_INTEGER, KIND_INTEGER, KIND_BOOLEAN, KIND_BOOLEAN, KIND_STRING, KIND_STRING};

struct OMC_FMU_INIT {
  FILE *file;
  long entries;
  unsigned char buffer[BUFFER_SIZE];
  size_t pos, len;
  int failed;
  uint32_t counts[NUM_ARRAYS];
  double experiment[4];
  char *solver;
  uint64_t numFiles;
  char **files;
  char error[512];
};

/* What one variable is read into; NULL members are skipped. */
typedef struct TARGET {
  VAR_INFO *info;
  DIMENSION_INFO *dimension;
  base_array_t *attribute[4];
  modelica_boolean *fixed, *useNominal;
} TARGET;

static int next_byte(OMC_FMU_INIT *init)
{
  if (init->pos == init->len) {
    init->pos = 0;
    init->len = init->failed ? 0 : fread(init->buffer, 1, BUFFER_SIZE, init->file);
    if (!init->len) {
      init->failed = 1;
      return 0;
    }
  }
  return init->buffer[init->pos++];
}

/* Skips the bytes if dest is NULL. */
static void read_bytes(OMC_FMU_INIT *init, void *dest, size_t n)
{
  unsigned char *d = (unsigned char*) dest;
  while (n && !init->failed) {
    size_t k;
    if (init->pos == init->len) {
      init->pos = 0;
      init->len = fread(init->buffer, 1, BUFFER_SIZE, init->file);
      if (!init->len) {
        init->failed = 1;
        return;
      }
    }
    k = init->len - init->pos < n ? init->len - init->pos : n;
    if (d) {
      memcpy(d, init->buffer + init->pos, k);
      d += k;
    }
    init->pos += k;
    n -= k;
  }
}

static uint64_t read_varint(OMC_FMU_INIT *init)
{
  uint64_t v = 0;
  int shift = 0, b;
  do {
    b = next_byte(init);
    if (shift < 64) {
      v |= (uint64_t) (b & 127) << shift;
    }
    shift += 7;
  } while ((b & 128) && !init->failed);
  return v;
}

static int64_t read_int(OMC_FMU_INIT *init)
{
  int b = next_byte(init);
  uint64_t m = (b >> 1) & 63;
  if (b & 128) {
    m |= read_varint(init) << 6;
  }
  return (b & 1) ? -(int64_t) m - 1 : (int64_t) m;
}

static double read_f64(OMC_FMU_INIT *init)
{
  unsigned char p[8];
  uint64_t u = 0;
  double d;
  int i;
  read_bytes(init, p, 8);
  for (i = 7; i >= 0; i--) {
    u = u << 8 | p[i];
  }
  memcpy(&d, &u, sizeof(d));
  return d;
}

static uint32_t read_u32(OMC_FMU_INIT *init)
{
  unsigned char p[4];
  read_bytes(init, p, 4);
  return (uint32_t) p[0] | (uint32_t) p[1] << 8 | (uint32_t) p[2] << 16 | (uint32_t) p[3] << 24;
}

/* A malloc'd string, or NULL when it is skipped or the file ends. */
static char* read_string(OMC_FMU_INIT *init, int keep)
{
  uint64_t n = read_varint(init);
  char *s;
  if (n > MAX_LENGTH) {
    init->failed = 1;
  }
  if (init->failed || !keep) {
    read_bytes(init, NULL, init->failed ? 0 : (size_t) n);
    return NULL;
  }
  s = (char*) malloc(n + 1);
  read_bytes(init, s, n);
  s[n] = '\0';
  if (init->failed) {
    free(s);
    return NULL;
  }
  return s;
}

/* The array of an attribute with n elements, zeroed if it was reallocated. */
static void resize(base_array_t *a, int kind, uint64_t n)
{
  static const size_t SIZE[] = {sizeof(modelica_real), sizeof(modelica_integer), sizeof(modelica_boolean), sizeof(modelica_string)};
  if (a->data && base_array_nr_of_elements(*a) == (_index_t) n) {
    return;
  }
  if (kind == KIND_STRING) {
    omc_string_array_release(a);
  } else {
    omc_array_release(a);
  }
  switch (kind) {
    case KIND_REAL: simple_alloc_1d_real_array(a, (int) n); break;
    case KIND_INTEGER: simple_alloc_1d_integer_array(a, (int) n); break;
    case KIND_BOOLEAN: simple_alloc_1d_boolean_array(a, (int) n); break;
    default: simple_alloc_1d_string_array(a, (int) n); break;
  }
  memset(a->data, 0, n * SIZE[kind]);
}

static void put_string(base_array_t *a, uint64_t k, const char *s)
{
  omc_string_move(&((modelica_string*) a->data)[k], omc_string_new(s));
}

static void read_value(OMC_FMU_INIT *init, int kind, base_array_t *a, uint64_t k)
{
  char *s;
  switch (kind) {
    case KIND_REAL: {
      modelica_real r = read_f64(init);
      if (a) put_real_element(r, (int) k, a);
      break;
    }
    case KIND_INTEGER: {
      modelica_integer i = (modelica_integer) read_int(init);
      if (a) put_integer_element(i, (int) k, a);
      break;
    }
    case KIND_BOOLEAN: {
      modelica_boolean b = next_byte(init) != 0;
      if (a) put_boolean_element(b, (int) k, a);
      break;
    }
    default:
      s = read_string(init, a != NULL);
      if (a && s) put_string(a, k, s);
      free(s);
      break;
  }
}

static void put_default(int kind, int attribute, base_array_t *a)
{
  static const modelica_real REALS[] = {0.0, -DBL_MAX, DBL_MAX, 1.0};
  static const modelica_integer INTEGERS[] = {0, -LONG_MAX, LONG_MAX, 0};
  resize(a, kind, 1);
  switch (kind) {
    case KIND_REAL: put_real_element(REALS[attribute], 0, a); break;
    case KIND_INTEGER: put_integer_element(INTEGERS[attribute], 0, a); break;
    case KIND_BOOLEAN: put_boolean_element(0, 0, a); break;
    default: put_string(a, 0, ""); break;
  }
}

static void read_variable(OMC_FMU_INIT *init, int kind, int id, TARGET *t)
{
  int flags = next_byte(init), a;
  uint64_t file, n, k;
  int64_t position[4];
  VAR_INFO *info = t->info;
  int keepName = info && !info->name;
  char *name = read_string(init, keepName);

  if (keepName) {
    info->name = name;
  }
  file = read_varint(init);
  for (a = 0; a < 4; a++) {
    position[a] = read_int(init);
  }
  if (file >= init->numFiles) {
    init->failed = 1;
  }
  if (init->failed) {
    return;
  }
  if (info) {
    info->id = id;
    if (keepName) {
      info->info.filename = omc_strdup(init->files[file]);
    }
    info->info.lineStart = (int) position[0];
    info->info.colStart = (int) position[1];
    info->info.lineEnd = (int) position[2];
    info->info.colEnd = (int) position[3];
    info->info.readonly = (flags & FLAG_READONLY) != 0;
  }
  if (flags & FLAG_DIMENSIONS) {
    DIMENSION_INFO *d = t->dimension && !t->dimension->numberOfDimensions ? t->dimension : NULL;
    n = read_varint(init);
    if (n > 64) {
      init->failed = 1;
      return;
    }
    if (d) {
      d->numberOfDimensions = n;
      d->dimensions = (DIMENSION_ATTRIBUTE*) calloc(n, sizeof(DIMENSION_ATTRIBUTE));
    }
    for (k = 0; k < n; k++) {
      int64_t size = read_int(init);
      if (d) {
        d->dimensions[k].type = DIMENSION_BY_START;
        d->dimensions[k].start = (modelica_integer) size;
        d->dimensions[k].valueReference = -1;
      }
    }
  }
  for (a = ATTR_START; a <= ATTR_NOMINAL; a++) {
    base_array_t *arr = t->attribute[a];
    if (flags & (FLAG_START << a)) {
      n = read_varint(init);
      if (n == 0 || n > MAX_LENGTH) {
        init->failed = 1;
      }
      if (init->failed) {
        return;
      }
      if (arr) {
        resize(arr, kind, n);
      }
      for (k = 0; k < n && !init->failed; k++) {
        read_value(init, kind, arr, k);
      }
    } else if (arr) {
      put_default(kind, a, arr);
    }
  }
  if (t->fixed) {
    *t->fixed = (flags & FLAG_FIXED) != 0;
  }
  if (t->useNominal) {
    *t->useNominal = (flags & FLAG_USE_NOMINAL) != 0;
  }
}

/* Without md only reads (checks) the variables. */
static void read_variables(OMC_FMU_INIT *init, MODEL_DATA *md, int startOnly)
{
  int id = FIRST_VALUE_REFERENCE, a;
  uint32_t i;

  for (a = 0; a < NUM_ARRAYS; a++) {
    for (i = 0; i < init->counts[a] && !init->failed; i++, id++) {
      TARGET t;
      memset(&t, 0, sizeof(t));
      if (md) {
        switch (a) {
          case 0:
          case 1: {
            STATIC_REAL_DATA *d = a == 0 ? &md->realVarsData[i] : &md->realParameterData[i];
            t.attribute[ATTR_START] = &d->attribute.start;
            if (!startOnly) {
              t.info = &d->info;
              t.dimension = &d->dimension;
              t.attribute[ATTR_MIN] = &d->attribute.min;
              t.attribute[ATTR_MAX] = &d->attribute.max;
              t.attribute[ATTR_NOMINAL] = &d->attribute.nominal;
              t.fixed = &d->attribute.fixed;
              t.useNominal = &d->attribute.useNominal;
            }
            break;
          }
          case 2:
          case 3: {
            STATIC_INTEGER_DATA *d = a == 2 ? &md->integerVarsData[i] : &md->integerParameterData[i];
            t.attribute[ATTR_START] = &d->attribute.start;
            if (!startOnly) {
              t.info = &d->info;
              t.dimension = &d->dimension;
              t.attribute[ATTR_MIN] = &d->attribute.min;
              t.attribute[ATTR_MAX] = &d->attribute.max;
              t.fixed = &d->attribute.fixed;
            }
            break;
          }
          case 4:
          case 5: {
            STATIC_BOOLEAN_DATA *d = a == 4 ? &md->booleanVarsData[i] : &md->booleanParameterData[i];
            t.attribute[ATTR_START] = &d->attribute.start;
            if (!startOnly) {
              t.info = &d->info;
              t.dimension = &d->dimension;
              t.fixed = &d->attribute.fixed;
            }
            break;
          }
          default: {
            STATIC_STRING_DATA *d = a == 6 ? &md->stringVarsData[i] : &md->stringParameterData[i];
            t.attribute[ATTR_START] = &d->attribute.start;
            if (!startOnly) {
              t.info = &d->info;
              t.dimension = &d->dimension;
            }
            break;
          }
        }
      }
      read_variable(init, KIND_OF[a], id, &t);
    }
  }
}

OMC_FMU_INIT* omc_fmu_init_load(const MODEL_DATA *md)
{
  const long expected[NUM_ARRAYS] = {md->nVariablesRealArray, md->nParametersRealArray, md->nVariablesIntegerArray,
                                     md->nParametersIntegerArray, md->nVariablesBooleanArray, md->nParametersBooleanArray,
                                     md->nVariablesStringArray, md->nParametersStringArray};
  OMC_FMU_INIT *init = (OMC_FMU_INIT*) calloc(1, sizeof(OMC_FMU_INIT));
  const char *prefix = md->modelFilePrefix;
  char magic[8], *path;
  uint64_t f;
  int a;

  if (!md->resourcesDir) {
    snprintf(init->error, sizeof(init->error), "The FMU has no resources directory with %s_init.bin.", prefix);
    return init;
  }
  path = (char*) malloc(strlen(md->resourcesDir) + strlen(prefix) + 11);
  sprintf(path, "%s/%s_init.bin", md->resourcesDir, prefix);
  init->file = omc_fopen(path, "rb");
  if (!init->file) {
    snprintf(init->error, sizeof(init->error), "Cannot read %s.", path);
    free(path);
    return init;
  }
  read_bytes(init, magic, 8);
  if (init->failed || memcmp(magic, "OMCFMUI", 8)) {
    snprintf(init->error, sizeof(init->error), "%s is not an init file of an FMU.", path);
  } else if (read_u32(init) != VERSION) {
    snprintf(init->error, sizeof(init->error), "%s has another version than %d.", path, VERSION);
  } else {
    for (a = 0; a < NUM_ARRAYS; a++) {
      init->counts[a] = read_u32(init);
      if (!init->failed && (long) init->counts[a] != expected[a]) {
        snprintf(init->error, sizeof(init->error), "%s has %u variables of kind %d, the model %ld.", path, init->counts[a], a, expected[a]);
        break;
      }
    }
  }
  if (!init->error[0]) {
    for (a = 0; a < 4; a++) {
      init->experiment[a] = read_f64(init);
    }
    init->solver = read_string(init, 1);
    init->numFiles = read_varint(init);
    if (init->numFiles > MAX_LENGTH) {
      init->failed = 1;
    }
    if (!init->failed) {
      init->files = (char**) calloc(init->numFiles ? init->numFiles : 1, sizeof(char*));
    }
    for (f = 0; f < init->numFiles && !init->failed; f++) {
      init->files[f] = read_string(init, 1);
    }
    init->entries = ftell(init->file) - (long) (init->len - init->pos);
    read_variables(init, NULL, 0);
    if (!init->failed) {
      next_byte(init);
      init->failed = !init->failed;
    }
    if (init->failed) {
      snprintf(init->error, sizeof(init->error), "%s is truncated or corrupt.", path);
    }
  }
  free(path);
  return init;
}

const char* omc_fmu_init_error(const OMC_FMU_INIT *init)
{
  return init->error[0] ? init->error : NULL;
}

void omc_fmu_init_free(OMC_FMU_INIT *init)
{
  uint64_t f;
  if (init->file) {
    fclose(init->file);
  }
  for (f = 0; init->files && f < init->numFiles; f++) {
    free(init->files[f]);
  }
  free(init->files);
  free(init->solver);
  free(init);
}

void omc_fmu_init_experiment(const OMC_FMU_INIT *init, SIMULATION_INFO *simulationInfo)
{
  simulationInfo->startTime = init->experiment[0];
  simulationInfo->stopTime = init->experiment[1];
  simulationInfo->stepSize = init->experiment[2];
  simulationInfo->tolerance = init->experiment[3];
  simulationInfo->solverMethod = GC_strdup(init->solver ? init->solver : "");
}

void omc_fmu_init_variables(OMC_FMU_INIT *init, MODEL_DATA *modelData, int startOnly)
{
  fseek(init->file, init->entries, SEEK_SET);
  init->pos = init->len = 0;
  init->failed = 0;
  read_variables(init, modelData, startOnly);
}
