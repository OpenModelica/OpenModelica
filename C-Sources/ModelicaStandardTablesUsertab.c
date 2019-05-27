/* ModelicaStandardTablesUsertab.c - A dummy usertab function

   Copyright (C) 2013-2019, Modelica Association and contributors
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

   3. Neither the name of the copyright holder nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
   DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
   FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
   CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
   OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/* The usertab function needs to be in a separate object or clang/gcc
   optimize the code in such a way that the user-defined usertab gets
   sent the wrong input.

   NOTE: If a dummy usertab is included in your code, you may be unable
   to also provide a user-defined usertab. If you use dynamic linking
   this is sometimes possible: when the simulation executable provides
   a usertab object, it will be part of the table of loaded objects and
   when later loading the shared object version of ModelicaStandardTables,
   the dummy usertab will not be loaded by the dynamic linker; this is
   what can confuse C-compilers and why this function is in a separate
   file).

   The interface of usertab is defined in ModelicaStandardTables.c
 */

#include "ModelicaUtilities.h"

#if defined(DUMMY_FUNCTION_USERTAB)
#if (defined(__clang__) || defined(__GNUC__)) && !(defined(__apple_build_version__) || defined(__MINGW32__) || defined(__MINGW64__) || defined(__CYGWIN__))
int usertab(char* tableName, int nipo, int dim[], int* colWise,
            double** table) __attribute__ ((weak, alias ("dummy_usertab")));
#define USERTAB_NAME dummy_usertab
#else
#define USERTAB_NAME usertab
#endif /* clang/gcc weak linking */
int USERTAB_NAME(char* tableName, int nipo, int dim[], int* colWise,
                 double** table) {
    ModelicaError("Function \"usertab\" is not implemented\n");
    return 1; /* Error */
}
#endif /* #if defined(DUMMY_FUNCTION_USERTAB) */
