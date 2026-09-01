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

/* wasi-libc compat shims for the ModelicaExternalC side module (build.rs clang
 * wasm32-wasi build). WASI has no processes and no temp-name helpers, so these
 * libc functions are absent; the paths that use them (MatIO file-write, temp
 * file names) are not exercised by the web target's read-only table/matrix use.
 * Everything else resolves against wasi-libc. */
/* wasi-libc compat shims for the ModelicaExternalC side module (build.rs clang
 * wasm32-wasi build). WASI has no processes, and wasi-libc ships no temp-name
 * helpers; these are musl's, over the `mkdir`/`stat` wasi-libc does have. */
#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>

/* musl's `__randname`: six characters from the clock and a per-call counter. */
static char* randname(char* suffix) {
    static unsigned long counter;
    struct timeval tv;
    unsigned long r;
    int i;
    gettimeofday(&tv, NULL);
    r = (unsigned long) tv.tv_usec * 65537UL
        ^ ((unsigned long) (uintptr_t) &tv / 16 + counter++);
    for (i = 0; i < 6; i++, r >>= 5) {
        suffix[i] = 'A' + (r & 15) + (r & 16) * 2;
    }
    return suffix;
}

char* mkdtemp(char* template) {
    size_t l = strlen(template);
    int retries;
    if (l < 6 || memcmp(template + l - 6, "XXXXXX", 6) != 0) {
        errno = EINVAL;
        return NULL;
    }
    for (retries = 100; retries > 0; retries--) {
        randname(template + l - 6);
        if (mkdir(template, 0700) == 0) {
            return template;
        }
        if (errno != EEXIST) {
            return NULL;
        }
    }
    memcpy(template + l - 6, "XXXXXX", 6);
    errno = EEXIST;
    return NULL;
}

char* tmpnam(char* s) {
    /* wasi-libc has no `L_tmpnam`; the buffer is the one name this builds. */
    static char internal[sizeof "/tmp/tmpnam_XXXXXX"];
    char path[] = "/tmp/tmpnam_XXXXXX";
    struct stat st;
    int retries;
    for (retries = 100; retries > 0; retries--) {
        randname(path + sizeof(path) - 7);
        if (stat(path, &st) != 0 && errno == ENOENT) {
            return strcpy(s ? s : internal, path);
        }
    }
    return NULL;
}

int getpid(void) {
    return 1;
}
