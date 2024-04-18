/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

#ifndef MEMORY_POOL_H_
#define MEMORY_POOL_H_

#include <stdlib.h>
#include "../openmodelica.h"

#if defined(__cplusplus)
extern "C" {
#endif

/// @brief
/// The memory pool is a linked list of blocks of memory. Each block has its own
/// chink of memory space to be used for requests by the program. It knows the size
/// of the chunk and keeps track of how much of it used currently. Each block also has
/// a pointer to the previous block.
typedef struct OMCMemPoolBlock_s {
  void *memory;
  size_t used;
  size_t size;
  struct OMCMemPoolBlock_s *previous;
} OMCMemPoolBlock;

/// @brief
/// The current state of the pool can be represented by a pointer to the current block
/// and the currently used amount of that block. Restoring will reset the pool pointer
/// the block saved in the state and then restors the used value when the satate was created.
typedef struct {
  OMCMemPoolBlock *block;
  size_t used;
} MemPoolState;

/// @brief Get the current state of the pool (the current block and used amount in that block)
MemPoolState omc_util_get_pool_state();
/// @brief Restors the memory pool to a given state (specifc block and used amount in that block).
void omc_util_restore_pool_state(MemPoolState in_state_v);
/// @brief Completely cleans up the memory pool by deleting all blocks.
void free_memory_pool();


/* Allocation functions */
extern modelica_real* real_alloc(int n);
extern modelica_integer* integer_alloc(int n);
extern modelica_string* string_alloc(int n);
extern modelica_boolean* boolean_alloc(int n);
extern _index_t* size_alloc(int n);
extern _index_t** index_alloc(int n);

void* generic_alloc(int n, size_t sze);

#if defined(__cplusplus)
} /* end extern "C" */
#endif

#endif
