/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * In-memory model-instance references (issue #15219).
 *
 * getModelInstanceReference()/getModelInstanceAnnotationReference() build the
 * exact same MetaModelica JSON structure as getModelInstance()/
 * getModelInstanceAnnotation(), but instead of serializing it to a string they
 * store the boxed MetaModelica JSON value here and return an integer handle.
 *
 * OMEdit links libOpenModelicaCompiler in-process, so it can fetch the boxed
 * value directly with ModelInstanceReference_get() and walk it, avoiding both
 * the JSON string generation (in omc) and the JSON string parsing (in OMEdit)
 * which, for large models, takes seconds.
 *
 * The values are kept in a static array which lives in the process data segment
 * and is therefore scanned conservatively by the (Boehm) garbage collector, so
 * the stored values are kept alive until they are released. Handles are 1-based;
 * a handle of 0 means "no/invalid reference" and lets callers fall back to the
 * string-based API.
 */

#include <stdio.h>
#include <stdlib.h>

#include "meta/meta_modelica.h"
#include "omc_config.h"

#define MODEL_INSTANCE_REFERENCE_MAX 256

static void *modelInstanceReferences[MODEL_INSTANCE_REFERENCE_MAX];
static int modelInstanceReferenceUsed[MODEL_INSTANCE_REFERENCE_MAX];

/* Stores a boxed JSON value and returns a 1-based handle, or 0 if no slot is
 * free. Called from MetaModelica (NFApi.storeModelInstanceReference). */
extern int ModelInstanceReference_store(void *json)
{
  int i;
  for (i = 0; i < MODEL_INSTANCE_REFERENCE_MAX; i++) {
    if (!modelInstanceReferenceUsed[i]) {
      modelInstanceReferenceUsed[i] = 1;
      modelInstanceReferences[i] = json;
      return i + 1; /* 1-based handle */
    }
  }
  return 0; /* no free slot */
}

/* Returns the boxed JSON value for a handle, or NULL for an invalid handle.
 * Called directly (as a C symbol) from OMEdit. */
extern void* ModelInstanceReference_get(int handle)
{
  int i = handle - 1;
  if (i < 0 || i >= MODEL_INSTANCE_REFERENCE_MAX || !modelInstanceReferenceUsed[i]) {
    return NULL;
  }
  return modelInstanceReferences[i];
}

/* Releases a handle. Returns 1 on success, 0 for an invalid handle.
 * Called from MetaModelica (NFApi.releaseModelInstanceReference) and may also be
 * called directly from OMEdit. */
extern int ModelInstanceReference_release(int handle)
{
  int i = handle - 1;
  if (i < 0 || i >= MODEL_INSTANCE_REFERENCE_MAX || !modelInstanceReferenceUsed[i]) {
    return 0;
  }
  modelInstanceReferenceUsed[i] = 0;
  modelInstanceReferences[i] = NULL;
  return 1;
}
