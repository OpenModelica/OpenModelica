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

#ifndef OMC_WASM_COMPAT_H
#define OMC_WASM_COMPAT_H

// Web build: omc runs in a Web Worker, not in-process, so there is no
// MetaModelica runtime. threadData is an empty carrier and MMC try/init become
// plain blocks (the no-op slice of omc_rust_embedding.h). Shared header so the
// definitions stay single across the headers cellapplication.cpp pulls in.
#if defined(__EMSCRIPTEN__)
struct threadData_s {};
typedef struct threadData_s threadData_t;
#define MMC_INIT(...)       ((void) 0)
#define MMC_TRY_TOP()       { threadData_t threadDataOnStack = {}; threadData_t *threadData = &threadDataOnStack; (void) threadData; {
#define MMC_CATCH_TOP(...)  } if (0) { __VA_ARGS__; } }
#endif

#endif
