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

#include "omc_init_bin.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum {
  SECTION_STRINGS = 1, SECTION_MODEL, SECTION_EXPERIMENT, SECTION_ENUMERATIONS,
  SECTION_VARIABLES, SECTION_REALS, SECTION_INTEGERS, NUM_SECTIONS = SECTION_INTEGERS
};

static const size_t recordSize[NUM_SECTIONS + 1] = {0, 1, 104, 48, 12, 104, 8, 8};

typedef struct section {
  const unsigned char *data;
  size_t count, stride;
} section;

static uint16_t le16(const unsigned char *p) { return (uint16_t) (p[0] | (p[1] << 8)); }

static uint32_t le32(const unsigned char *p)
{
  return (uint32_t) p[0] | ((uint32_t) p[1] << 8) | ((uint32_t) p[2] << 16) | ((uint32_t) p[3] << 24);
}

static uint64_t le64(const unsigned char *p) { return (uint64_t) le32(p) | ((uint64_t) le32(p + 4) << 32); }

static int fail(omc_init_bin *bin, const char *format, ...)
{
  va_list ap;
  va_start(ap, format);
  vsnprintf(bin->error, sizeof(bin->error), format, ap);
  va_end(ap);
  return 1;
}

static int string(omc_init_bin *bin, const unsigned char *p, const char **str)
{
  uint32_t offset = le32(p);
  if (offset >= bin->stringsSize) {
    return fail(bin, "string offset %lu out of range", (unsigned long) offset);
  }
  *str = bin->strings + offset;
  return 0;
}

static int values(omc_init_bin *bin, const unsigned char *p, size_t poolSize, omc_init_bin_values *v)
{
  v->count = le32(p);
  v->index = le32(p + 4);
  if ((uint64_t) v->index + v->count > poolSize) {
    return fail(bin, "values %lu..%lu out of range", (unsigned long) v->index, (unsigned long) v->index + v->count);
  }
  return 0;
}

static int read_model(omc_init_bin *bin, const unsigned char *p)
{
  omc_init_bin_model *m = &bin->model;
  const char **strs[] = {&m->modelName, &m->modelIdentifier, &m->description, &m->guid,
                         &m->generationTool, &m->generationDateAndTime, &m->omhome};
  int32_t *counts[] = {
    &m->numberOfContinuousStates, &m->numberOfRealAlgebraicVariables, &m->numberOfRealAlgebraicAliasVariables,
    &m->numberOfRealParameters, &m->numberOfIntegerAlgebraicVariables, &m->numberOfIntegerAliasVariables,
    &m->numberOfIntegerParameters, &m->numberOfBooleanAlgebraicVariables, &m->numberOfBooleanAliasVariables,
    &m->numberOfBooleanParameters, &m->numberOfStringAlgebraicVariables, &m->numberOfStringAliasVariables,
    &m->numberOfStringParameters, &m->numberOfEventIndicators, &m->numberOfTimeEvents, &m->numberOfInputVariables,
    &m->numberOfOutputVariables, &m->numberOfExternalObjects, &m->numberOfFunctions};
  size_t i;
  for (i = 0; i < sizeof(strs)/sizeof(strs[0]); i++, p += 4) {
    if (string(bin, p, strs[i])) return 1;
  }
  for (i = 0; i < sizeof(counts)/sizeof(counts[0]); i++, p += 4) {
    *counts[i] = (int32_t) le32(p);
  }
  return 0;
}

static double f64(const unsigned char *p)
{
  uint64_t u = le64(p);
  double d;
  memcpy(&d, &u, sizeof(d));
  return d;
}

static int read_experiment(omc_init_bin *bin, const unsigned char *p)
{
  omc_init_bin_experiment *e = &bin->experiment;
  e->startTime = f64(p);
  e->stopTime = f64(p + 8);
  e->stepSize = f64(p + 16);
  e->tolerance = f64(p + 24);
  return string(bin, p + 32, &e->solver) || string(bin, p + 36, &e->outputFormat) || string(bin, p + 40, &e->variableFilter);
}

static int read_variable(omc_init_bin *bin, const unsigned char *p, omc_init_bin_variable *v)
{
  const char **strs[] = {&v->name, &v->description, &v->fileName, &v->unit, &v->displayUnit, &v->declaredType, &v->aliasVariable};
  int32_t *ints[] = {&v->valueReference, &v->inputIndex, &v->classIndex,
                     &v->startLine, &v->startColumn, &v->endLine, &v->endColumn};
  uint8_t *bytes[] = {&v->classType, &v->baseType, &v->variability, &v->causality, &v->alias, &v->hideResult};
  size_t i, pool;
  for (i = 0; i < 7; i++, p += 4) {
    if (string(bin, p, strs[i])) return 1;
  }
  for (i = 0; i < 7; i++, p += 4) {
    *ints[i] = (int32_t) le32(p);
  }
  for (i = 0; i < 6; i++, p++) {
    *bytes[i] = *p;
  }
  v->flags = le16(p);
  v->numDimensions = le32(p + 2);
  v->firstDimension = le32(p + 6);
  p += 10;
  if (v->classType >= OMC_INIT_BIN_NUM_CLASS_TYPES || v->baseType > OMC_INIT_BIN_EXTERNAL_OBJECT) {
    return fail(bin, "variable %s: invalid class or base type", v->name);
  }
  if ((uint64_t) v->firstDimension + 2 * (uint64_t) v->numDimensions > bin->numIntegers) {
    return fail(bin, "variable %s: dimensions out of range", v->name);
  }
  pool = v->baseType == OMC_INIT_BIN_REAL ? bin->numReals : bin->numIntegers;
  return values(bin, p, pool, &v->start) || values(bin, p + 8, pool, &v->min) ||
         values(bin, p + 16, pool, &v->max) || values(bin, p + 24, pool, &v->nominal);
}

static int parse(omc_init_bin *bin)
{
  section sections[NUM_SECTIONS + 1];
  const unsigned char *d = bin->data;
  uint32_t version, numSections, i;
  size_t j;

  memset(sections, 0, sizeof(sections));
  if (bin->size < 16 || memcmp(d, "OMCINIT", 8)) {
    return fail(bin, "not an init.bin file");
  }
  version = le32(d + 8);
  numSections = le32(d + 12);
  if (version != OMC_INIT_BIN_VERSION) {
    return fail(bin, "unsupported version %lu, expected %d", (unsigned long) version, OMC_INIT_BIN_VERSION);
  }
  if (16 + 24 * (uint64_t) numSections > bin->size) {
    return fail(bin, "truncated section table");
  }
  for (i = 0; i < numSections; i++) {
    const unsigned char *e = d + 16 + 24 * i;
    uint32_t id = le32(e), count = le32(e + 4);
    uint64_t offset = le64(e + 8), size = le64(e + 16);
    if (offset > bin->size || size > bin->size - offset) {
      return fail(bin, "section %lu out of range", (unsigned long) id);
    }
    if (id < 1 || id > NUM_SECTIONS) {
      continue;
    }
    sections[id].data = d + offset;
    sections[id].count = count;
    sections[id].stride = id == SECTION_STRINGS ? 1 : (count ? size / count : 0);
    if (count && (sections[id].stride < recordSize[id] || sections[id].stride * count > size)) {
      return fail(bin, "section %lu has records of %lu bytes, expected %lu", (unsigned long) id,
                  (unsigned long) sections[id].stride, (unsigned long) recordSize[id]);
    }
  }
  for (i = 1; i <= NUM_SECTIONS; i++) {
    if (!sections[i].data) {
      return fail(bin, "section %lu is missing", (unsigned long) i);
    }
  }
  if (sections[SECTION_MODEL].count != 1 || sections[SECTION_EXPERIMENT].count != 1) {
    return fail(bin, "expected one model and one experiment record");
  }

  bin->strings = (const char *) sections[SECTION_STRINGS].data;
  bin->stringsSize = sections[SECTION_STRINGS].count;
  if (bin->stringsSize == 0 || bin->strings[bin->stringsSize - 1] != '\0') {
    return fail(bin, "the strings are not NUL-terminated");
  }
  bin->reals = sections[SECTION_REALS].data;
  bin->numReals = sections[SECTION_REALS].count;
  bin->integers = sections[SECTION_INTEGERS].data;
  bin->numIntegers = sections[SECTION_INTEGERS].count;

  if (read_model(bin, sections[SECTION_MODEL].data) || read_experiment(bin, sections[SECTION_EXPERIMENT].data)) {
    return 1;
  }

  bin->numEnumerations = sections[SECTION_ENUMERATIONS].count;
  bin->enumerations = (omc_init_bin_enumeration *) calloc(bin->numEnumerations + 1, sizeof(omc_init_bin_enumeration));
  for (j = 0; j < bin->numEnumerations; j++) {
    const unsigned char *p = sections[SECTION_ENUMERATIONS].data + j * sections[SECTION_ENUMERATIONS].stride;
    omc_init_bin_enumeration *e = &bin->enumerations[j];
    if (string(bin, p, &e->name)) return 1;
    e->numLiterals = le32(p + 4);
    e->firstLiteral = le32(p + 8);
    if ((uint64_t) e->firstLiteral + e->numLiterals > bin->numIntegers) {
      return fail(bin, "enumeration %s: literals out of range", e->name);
    }
    for (i = 0; i < e->numLiterals; i++) {
      if (!omc_init_bin_string(bin, e->firstLiteral + i)) {
        return fail(bin, "enumeration %s: literal out of range", e->name);
      }
    }
  }

  bin->numVariables = sections[SECTION_VARIABLES].count;
  bin->variables = (omc_init_bin_variable *) calloc(bin->numVariables + 1, sizeof(omc_init_bin_variable));
  for (j = 0; j < bin->numVariables; j++) {
    omc_init_bin_variable *v = &bin->variables[j];
    if (read_variable(bin, sections[SECTION_VARIABLES].data + j * sections[SECTION_VARIABLES].stride, v)) {
      return 1;
    }
    if (j > 0 && v->classType < bin->variables[j-1].classType) {
      return fail(bin, "variable %s is not ordered by class type", v->name);
    }
    if (bin->classCount[v->classType]++ == 0) {
      bin->classStart[v->classType] = j;
    }
    if (v->baseType == OMC_INIT_BIN_STRING) {
      for (i = 0; i < v->start.count; i++) {
        if (!omc_init_bin_string(bin, v->start.index + i)) {
          return fail(bin, "variable %s: start value out of range", v->name);
        }
      }
    }
  }
  return 0;
}

int omc_init_bin_load_buffer(omc_init_bin *bin, const void *data, size_t size)
{
  memset(bin, 0, sizeof(*bin));
  bin->data = (unsigned char *) malloc(size ? size : 1);
  if (!bin->data) {
    return fail(bin, "out of memory");
  }
  memcpy(bin->data, data, size);
  bin->size = size;
  return parse(bin);
}

int omc_init_bin_load_file(omc_init_bin *bin, const char *fileName)
{
  FILE *f;
  long size;
  memset(bin, 0, sizeof(*bin));
  f = fopen(fileName, "rb");
  if (!f) {
    return fail(bin, "could not open %s", fileName);
  }
  if (fseek(f, 0, SEEK_END) || (size = ftell(f)) < 0 || fseek(f, 0, SEEK_SET)) {
    fclose(f);
    return fail(bin, "could not read %s", fileName);
  }
  bin->data = (unsigned char *) malloc(size ? size : 1);
  if (!bin->data || fread(bin->data, 1, size, f) != (size_t) size) {
    fclose(f);
    return fail(bin, "could not read %s", fileName);
  }
  fclose(f);
  bin->size = (size_t) size;
  if (parse(bin)) {
    char reason[sizeof(bin->error)];
    memcpy(reason, bin->error, sizeof(reason));
    return fail(bin, "%s: %s", fileName, reason);
  }
  return 0;
}

void omc_init_bin_free(omc_init_bin *bin)
{
  free(bin->data);
  free(bin->enumerations);
  free(bin->variables);
  memset(bin, 0, sizeof(*bin));
}

double omc_init_bin_real(const omc_init_bin *bin, size_t index)
{
  return f64(bin->reals + 8 * index);
}

int64_t omc_init_bin_integer(const omc_init_bin *bin, size_t index)
{
  return (int64_t) le64(bin->integers + 8 * index);
}

const char *omc_init_bin_string(const omc_init_bin *bin, size_t integerIndex)
{
  int64_t offset;
  if (integerIndex >= bin->numIntegers) {
    return NULL;
  }
  offset = omc_init_bin_integer(bin, integerIndex);
  return offset >= 0 && (uint64_t) offset < bin->stringsSize ? bin->strings + offset : NULL;
}
