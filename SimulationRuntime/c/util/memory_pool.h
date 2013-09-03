/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef MEMORY_POOL_H_
#define MEMORY_POOL_H_

#include <stdlib.h>
#include "openmodelica.h"

extern int (*get_thread_index)(void); /* Implemented by generated code; different for each thread implementation */
extern state get_memory_state(void);
extern void restore_memory_state(state restore_state);
extern void clear_memory_state(void);
extern void clear_current_state(void);

/*Help functions*/
extern void print_current_state(void);
extern void print_state(state s);

/* Allocation functions */
extern void* alloc_elements(int n, int sz);
extern m_real* real_alloc(int n);
extern m_integer* integer_alloc(int n);
extern m_string* string_alloc(int n);
extern m_boolean* boolean_alloc(int n);
extern _index_t* size_alloc(int n);
extern _index_t** index_alloc(int n);

extern void* push_memory_states(int maxThreads);
extern void pop_memory_states(void* new_states);

void* generic_alloc(int n, size_t sze);

#endif
