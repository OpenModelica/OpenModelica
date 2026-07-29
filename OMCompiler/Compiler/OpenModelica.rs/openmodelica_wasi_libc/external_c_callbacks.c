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

/* The Modelica utility callbacks (`env.Modelica*`) that ModelicaExternalC needs
 * but does not define. In a hosted build (OMC, the wasmer web host) these come
 * from the runtime; in a host-free wasm FMU there is no host, so the PIC
 * dylink side module carries them itself. Because the FMU is one shared linear
 * memory, an allocated string is a plain pointer the model reads directly — no
 * marshalling. Errors abort (fatal); the FMI master sees the resulting trap. */

#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>

char* ModelicaAllocateString(size_t len) {
    char* p = (char*) malloc(len + 1);
    if (p) p[len] = '\0';
    return p;
}

char* ModelicaAllocateStringWithErrorReturn(size_t len) {
    return ModelicaAllocateString(len);
}

void ModelicaError(const char* string) {
    fputs(string, stderr);
    fputc('\n', stderr);
    abort();
}

void ModelicaVFormatError(const char* fmt, va_list ap) {
    vfprintf(stderr, fmt, ap);
    abort();
}

void ModelicaFormatError(const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    ModelicaVFormatError(fmt, ap);
    va_end(ap);
}

void ModelicaMessage(const char* string) {
    fputs(string, stderr);
}

void ModelicaVFormatMessage(const char* fmt, va_list ap) {
    vfprintf(stderr, fmt, ap);
}

void ModelicaFormatMessage(const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    ModelicaVFormatMessage(fmt, ap);
    va_end(ap);
}

void ModelicaWarning(const char* string) {
    fputs(string, stderr);
}

void ModelicaVFormatWarning(const char* fmt, va_list ap) {
    vfprintf(stderr, fmt, ap);
}

void ModelicaFormatWarning(const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    ModelicaVFormatWarning(fmt, ap);
    va_end(ap);
}
