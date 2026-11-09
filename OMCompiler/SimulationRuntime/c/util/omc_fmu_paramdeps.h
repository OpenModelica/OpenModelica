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

/*
 * resources/<prefix>_paramdeps.bin of a C FMU 2.0 or 3.0: how the parameters
 * depend on each other and which variables an importer may set, written by omc
 * (Compiler/SimCode/ParamDeps.mo, SerializeFmuInit.writeParamDeps).
 * Format version 1, read front to back:
 *   Header: "OMCFMUP\0", u32 version (little-endian), u8 1 if the runtime
 *   checks writes and updates parameters, 0 if it does neither (a model
 *   that is not scalarized).
 *   varint number of equations, then per equation in evaluation order: u8 1 if
 *   updateTunableParameters evaluates it, else 0; varint n, n slots it uses;
 *   varint n, n slots it defines.
 *   varint number of settable slots, then per slot: varint slot, u8 flags
 *   (OMC_PARAMDEPS_*).
 *   A slot is 8 * index + type (OMC_SLOT_*), the index counting the variables
 *   of that type, then its parameters. varint: LEB128.
 */

#ifndef OMC_FMU_PARAMDEPS_H
#define OMC_FMU_PARAMDEPS_H

#include <stddef.h>
#include "../simulation_data.h"

#ifdef __cplusplus
extern "C" {
#endif

enum { OMC_SLOT_REAL, OMC_SLOT_INTEGER, OMC_SLOT_BOOLEAN, OMC_SLOT_STRING, OMC_SLOT_EXTOBJ };
#define OMC_SLOT(index, type) (8 * (size_t) (index) + (type))

enum {
  OMC_PARAMDEPS_INITIAL_EXACT = 1,
  OMC_PARAMDEPS_INITIAL_APPROX = 2,
  OMC_PARAMDEPS_INPUT = 4,
  OMC_PARAMDEPS_CONTINUOUS = 8,
  OMC_PARAMDEPS_TUNABLE = 16
};

typedef struct OMC_FMU_PARAMDEPS {
  int checked;
  size_t nEqs;
  unsigned char *runnable;
  size_t *usesStart, *uses;       /* the uses of equation k are uses[usesStart[k]] .. uses[usesStart[k+1]-1] */
  size_t *definesStart, *defines;
  size_t nSlots;
  unsigned char *flags;           /* per slot */
  char error[512];
} OMC_FMU_PARAMDEPS;

/* Reads <resourcesDir>/<modelFilePrefix>_paramdeps.bin. Never NULL; error[0]
 * is set if it failed. */
OMC_FMU_PARAMDEPS* omc_fmu_paramdeps_load(const MODEL_DATA *modelData);
OMC_FMU_PARAMDEPS* omc_fmu_paramdeps_load_file(const char *path);
/* Makes room for every slot of the model, once its scalar sizes are known. */
void omc_fmu_paramdeps_resize(OMC_FMU_PARAMDEPS *deps, const MODEL_DATA *modelData);
void omc_fmu_paramdeps_free(OMC_FMU_PARAMDEPS *deps);

/* Extends dirty (one byte per slot) by everything calculated from the dirty
 * slots and sets eqMask[k] for each equation k that updateTunableParameters
 * has to evaluate for it. Returns the number of such equations. */
size_t omc_fmu_paramdeps_select(const OMC_FMU_PARAMDEPS *deps, unsigned char *dirty, unsigned char *eqMask);

#ifdef __cplusplus
}
#endif

#endif
