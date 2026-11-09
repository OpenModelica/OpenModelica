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

#include "omc_fmu_paramdeps.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "omc_file.h"

#define VERSION 1
#define MAX_SLOT (1 << 28)

typedef struct READER {
  const unsigned char *p, *end;
  int failed;
} READER;

static uint64_t read_varint(READER *r)
{
  uint64_t v = 0;
  int shift = 0;
  unsigned char b;
  do {
    if (r->p == r->end) {
      r->failed = 1;
      return 0;
    }
    b = *r->p++;
    if (shift < 64) {
      v |= (uint64_t) (b & 127) << shift;
    }
    shift += 7;
  } while (b & 128);
  return v;
}

static unsigned char read_u8(READER *r)
{
  if (r->p == r->end) {
    r->failed = 1;
    return 0;
  }
  return *r->p++;
}

static size_t* read_slots(READER *r, size_t *start, size_t k, size_t *n, size_t *cap, size_t *slots, size_t *nSlots)
{
  uint64_t m = read_varint(r), i;
  start[k] = *n;
  if (m > (uint64_t) (r->end - r->p)) {
    r->failed = 1;
    return slots;
  }
  if (*n + m > *cap) {
    *cap = 2 * (*n + m);
    slots = (size_t*) realloc(slots, *cap * sizeof(size_t));
  }
  for (i = 0; i < m && !r->failed; i++) {
    uint64_t s = read_varint(r);
    if (s >= MAX_SLOT) {
      r->failed = 1;
    } else if (s >= *nSlots) {
      *nSlots = (size_t) s + 1;
    }
    slots[(*n)++] = (size_t) s;
  }
  start[k + 1] = *n;
  return slots;
}

static OMC_FMU_PARAMDEPS* newParamDeps(void)
{
  OMC_FMU_PARAMDEPS *deps = (OMC_FMU_PARAMDEPS*) calloc(1, sizeof(OMC_FMU_PARAMDEPS));
  deps->usesStart = (size_t*) calloc(1, sizeof(size_t));
  deps->definesStart = (size_t*) calloc(1, sizeof(size_t));
  deps->flags = (unsigned char*) calloc(1, 1);
  return deps;
}

OMC_FMU_PARAMDEPS* omc_fmu_paramdeps_load(const MODEL_DATA *md)
{
  OMC_FMU_PARAMDEPS *deps;
  char *path;
  if (!md->resourcesDir) {
    deps = newParamDeps();
    snprintf(deps->error, sizeof(deps->error), "The FMU has no resources directory with %s_paramdeps.bin.", md->modelFilePrefix);
    return deps;
  }
  path = (char*) malloc(strlen(md->resourcesDir) + strlen(md->modelFilePrefix) + 16);
  sprintf(path, "%s/%s_paramdeps.bin", md->resourcesDir, md->modelFilePrefix);
  deps = omc_fmu_paramdeps_load_file(path);
  free(path);
  return deps;
}

OMC_FMU_PARAMDEPS* omc_fmu_paramdeps_load_file(const char *path)
{
  OMC_FMU_PARAMDEPS *deps = newParamDeps();
  unsigned char *bytes = NULL;
  size_t len = 0, nUses = 0, capUses = 0, nDefines = 0, capDefines = 0, nFlags = 0, capFlags = 0, k;
  size_t *flagSlots = NULL;
  unsigned char *flagValues = NULL;
  uint64_t nEqs, nSettable;
  READER r;
  FILE *file = omc_fopen(path, "rb");

  if (!file) {
    snprintf(deps->error, sizeof(deps->error), "Cannot read %s.", path);
    return deps;
  }
  fseek(file, 0, SEEK_END);
  len = (size_t) ftell(file);
  fseek(file, 0, SEEK_SET);
  bytes = (unsigned char*) malloc(len ? len : 1);
  if (fread(bytes, 1, len, file) != len) {
    len = 0;
  }
  fclose(file);

  r.p = bytes;
  r.end = bytes + len;
  r.failed = 0;
  if (len < 13 || memcmp(bytes, "OMCFMUP", 8)) {
    snprintf(deps->error, sizeof(deps->error), "%s is not a parameter dependency file.", path);
  } else if ((bytes[8] | bytes[9] << 8 | bytes[10] << 16 | (uint32_t) bytes[11] << 24) != VERSION) {
    snprintf(deps->error, sizeof(deps->error), "%s has another version than %d.", path, VERSION);
  } else {
    r.p += 12;
    deps->checked = read_u8(&r);
    nEqs = read_varint(&r);
    if (nEqs > (uint64_t) (r.end - r.p)) {
      r.failed = 1;
    } else {
      deps->nEqs = (size_t) nEqs;
      deps->runnable = (unsigned char*) calloc(deps->nEqs ? deps->nEqs : 1, 1);
      deps->usesStart = (size_t*) realloc(deps->usesStart, (deps->nEqs + 1) * sizeof(size_t));
      deps->definesStart = (size_t*) realloc(deps->definesStart, (deps->nEqs + 1) * sizeof(size_t));
      deps->usesStart[0] = deps->definesStart[0] = 0;
    }
    for (k = 0; k < deps->nEqs && !r.failed; k++) {
      deps->runnable[k] = read_u8(&r);
      deps->uses = read_slots(&r, deps->usesStart, k, &nUses, &capUses, deps->uses, &deps->nSlots);
      deps->defines = read_slots(&r, deps->definesStart, k, &nDefines, &capDefines, deps->defines, &deps->nSlots);
    }
    nSettable = r.failed ? 0 : read_varint(&r);
    if (nSettable > (uint64_t) (r.end - r.p)) {
      r.failed = 1;
    } else {
      capFlags = (size_t) nSettable;
      flagSlots = (size_t*) malloc((capFlags ? capFlags : 1) * sizeof(size_t));
      flagValues = (unsigned char*) malloc(capFlags ? capFlags : 1);
    }
    for (k = 0; k < capFlags && !r.failed; k++) {
      uint64_t s = read_varint(&r);
      flagValues[nFlags] = read_u8(&r);
      if (s >= MAX_SLOT) {
        r.failed = 1;
      } else {
        flagSlots[nFlags++] = (size_t) s;
        if (s >= deps->nSlots) {
          deps->nSlots = (size_t) s + 1;
        }
      }
    }
    if (r.failed || r.p != r.end) {
      snprintf(deps->error, sizeof(deps->error), "%s is truncated or corrupt.", path);
    } else {
      deps->flags = (unsigned char*) realloc(deps->flags, deps->nSlots ? deps->nSlots : 1);
      memset(deps->flags, 0, deps->nSlots);
      for (k = 0; k < nFlags; k++) {
        deps->flags[flagSlots[k]] = flagValues[k];
      }
    }
  }
  free(flagSlots);
  free(flagValues);
  free(bytes);
  return deps;
}

void omc_fmu_paramdeps_resize(OMC_FMU_PARAMDEPS *deps, const MODEL_DATA *md)
{
  const long counts[5] = {md->nVariablesReal + md->nParametersReal, md->nVariablesInteger + md->nParametersInteger,
                          md->nVariablesBoolean + md->nParametersBoolean, md->nVariablesString + md->nParametersString,
                          md->nExtObjs};
  size_t n = 0;
  int t;
  for (t = 0; t < 5; t++) {
    if (OMC_SLOT(counts[t], 0) > n) {
      n = OMC_SLOT(counts[t], 0);
    }
  }
  if (n > deps->nSlots) {
    deps->flags = (unsigned char*) realloc(deps->flags, n);
    memset(deps->flags + deps->nSlots, 0, n - deps->nSlots);
    deps->nSlots = n;
  }
}

void omc_fmu_paramdeps_free(OMC_FMU_PARAMDEPS *deps)
{
  if (deps) {
    free(deps->runnable);
    free(deps->usesStart);
    free(deps->uses);
    free(deps->definesStart);
    free(deps->defines);
    free(deps->flags);
    free(deps);
  }
}

size_t omc_fmu_paramdeps_select(const OMC_FMU_PARAMDEPS *deps, unsigned char *dirty, unsigned char *eqMask)
{
  size_t k, i, n = 0;
  for (k = 0; k < deps->nEqs; k++) {
    int hit = 0;
    for (i = deps->usesStart[k]; i < deps->usesStart[k + 1] && !hit; i++) {
      hit = dirty[deps->uses[i]];
    }
    eqMask[k] = hit && deps->runnable[k];
    if (hit) {
      for (i = deps->definesStart[k]; i < deps->definesStart[k + 1]; i++) {
        dirty[deps->defines[i]] = 1;
      }
      n += eqMask[k];
    }
  }
  return n;
}
