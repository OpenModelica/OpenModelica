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
 * The Rust part of omcruntime (OMCompiler/Compiler/runtime/rust).
 *
 * Functions returning char* return NULL on success and an error message
 * otherwise, which the caller releases with omcrs_free_string.
 */
#ifndef OMCRUNTIME_RUST_H
#define OMCRUNTIME_RUST_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

char *omcrs_unzip_path(const char *zipFileName, const char *pathToExtract, const char *destPath);
char *omcrs_unzip_all(const char *zipFileName, const char *destPath);

/* paths[i] (a file, or a directory recursively) is stored as entryNames[i]; an
 * empty name puts a directory's contents at the root. Entries named in excludes,
 * and everything below them, are left out, and so is zipFileName itself. */
char *omcrs_zip_paths(const char *zipFileName, const char *const *paths, const char *const *entryNames, size_t n,
                      const char *const *excludes, size_t nExcludes);
void omcrs_free_string(char *s);

#ifdef __cplusplus
}
#endif

#endif
