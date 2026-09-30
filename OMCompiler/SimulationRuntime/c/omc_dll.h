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

/*! \file omc_dll.h
 * The dllexport/dllimport decorations. Their own header because omc_gc.h needs
 * them and is itself included from the middle of openmodelica.h.
 */

#ifndef OMC_DLL_H
#define OMC_DLL_H

/* adrpo: extreme windows crap! */
#if defined(__MINGW32__) || defined(_MSC_VER)
#define DLLImport   __declspec( dllimport )
#define DLLExport   __declspec( dllexport )
#elif defined(OMC_EXPORT_BY_VISIBILITY)
/* Set when building libOpenModelicaCompiler with hidden visibility: it then
 * exports the same symbols as the DLL, so its users fail to link on Linux too
 * when they use a symbol the DLL does not export. */
#define DLLImport /* extern */
#define DLLExport __attribute__((visibility("default")))
#else
#define DLLImport /* extern */
#define DLLExport /* nothing */
#endif

#if defined(IMPORT_INTO)
#define DLLDirection DLLImport
#else /* we export from the dll */
#define DLLDirection DLLExport
#endif

/* Symbols the generated model defines itself. IMPORT_INTO says the runtime DLL
 * is external, which must not turn these into dllimport. */
#define DLLModelDirection DLLExport

/* Global data crossing the runtime DLL boundary. MSVC needs an explicit export
 * (WINDOWS_EXPORT_ALL_SYMBOLS skips .bss) and dllimport at the use site; MinGW
 * auto-imports and needs neither. */
#if defined(_MSC_VER)
#define DLLDataDirection DLLDirection
#else
#define DLLDataDirection
#endif

#endif
