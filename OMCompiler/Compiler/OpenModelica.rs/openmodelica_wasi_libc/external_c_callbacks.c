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

/* The Modelica utility callbacks (`env.Modelica*`) that ModelicaExternalC needs
 * but does not define. In a hosted build (OMC, the wasmer web host) these come
 * from the runtime; in a host-free wasm FMU there is no host, so the PIC
 * dylink side module carries them itself. Because the FMU is one shared linear
 * memory, an allocated string is a plain pointer the model reads directly — no
 * marshalling. They report through the runtime, as
 * `SimulationRuntime/c/util/ModelicaUtilities.c` does: an FMU has no stdout, and
 * its simulation log is the FMI logger. An error ends the run (C's MMC_THROW). */

#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>

/* openmodelica_codegen_wasm_jit_runtime. */
void rt_ext_error(const char* msg) __attribute__((noreturn));
void rt_ext_message(const char* msg);
void rt_ext_warning(const char* msg);

/* C's SIZE_LOG_BUFFER, and the same truncation. */
#define LOG_BUFFER 2048

char* ModelicaAllocateString(size_t len) {
    char* p = (char*) malloc(len + 1);
    if (p) p[len] = '\0';
    return p;
}

char* ModelicaAllocateStringWithErrorReturn(size_t len) {
    return ModelicaAllocateString(len);
}

static void report(void (*to)(const char*), const char* fmt, va_list ap) {
    char buf[LOG_BUFFER];
    vsnprintf(buf, sizeof(buf), fmt, ap);
    to(buf);
}

void ModelicaError(const char* string) {
    rt_ext_error(string);
}

void ModelicaVFormatError(const char* fmt, va_list ap) {
    char buf[LOG_BUFFER];
    vsnprintf(buf, sizeof(buf), fmt, ap);
    rt_ext_error(buf);
}

void ModelicaFormatError(const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    ModelicaVFormatError(fmt, ap);
    va_end(ap);
}

void ModelicaMessage(const char* string) {
    rt_ext_message(string);
}

void ModelicaVFormatMessage(const char* fmt, va_list ap) {
    report(rt_ext_message, fmt, ap);
}

void ModelicaFormatMessage(const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    ModelicaVFormatMessage(fmt, ap);
    va_end(ap);
}

void ModelicaWarning(const char* string) {
    rt_ext_warning(string);
}

void ModelicaVFormatWarning(const char* fmt, va_list ap) {
    report(rt_ext_warning, fmt, ap);
}

void ModelicaFormatWarning(const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    ModelicaVFormatWarning(fmt, ap);
    va_end(ap);
}
