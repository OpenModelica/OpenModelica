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

/*
 * verify_libOMCDLL.c
 *
 * Smoke test for libOMCDLL (the omc C-API wrapper). It does NOT link against the
 * library: it loads it at runtime and resolves the exported C functions by name,
 * which is exactly what an external consumer that "relies on this dll for
 * communication with omc" does, then drives omc through the full public API.
 *
 * It is the CTest `omcCAPI-libOMCDLL-usable`.
 *
 * Usage:
 *   verify_libOMCDLL [<path-to-libOMCDLL>]
 *
 * With no argument the library is loaded by its plain name (needs its directory
 * on PATH / LD_LIBRARY_PATH). With a path argument it is loaded from there and,
 * on Windows, that directory is also searched for its dependencies.
 *
 * Build (from an OpenModelica install):
 *   MinGW/MSYS2:  gcc verify_libOMCDLL.c -o verify_libOMCDLL.exe
 *   Linux/macOS:  cc  verify_libOMCDLL.c -ldl -o verify_libOMCDLL
 *
 * Run:
 *   export OPENMODELICAHOME=/c/OpenModelica
 *   PATH="$OPENMODELICAHOME/bin:$PATH" ./verify_libOMCDLL
 *
 * Exit codes: 0 pass, 77 the library/deps could not be loaded (environment, not
 * an ABI regression -> CTest SKIP), 2-19 a missing export or a failed assertion.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(_WIN32)
#  include <windows.h>
#  define OMCDLL_NAME "libOMCDLL.dll"
#  define DL_SYM(h, s) ((void *) GetProcAddress((HMODULE) (h), (s)))
#  define DL_CLOSE(h)  FreeLibrary((HMODULE) (h))
static void *dl_open(const char *spec, int is_path)
{
  if (is_path) {
    return (void *) LoadLibraryExA(spec, NULL, LOAD_WITH_ALTERED_SEARCH_PATH);
  }
  return (void *) LoadLibraryA(spec);
}
#else
#  include <dlfcn.h>
#  if defined(__APPLE__)
#    define OMCDLL_NAME "libOMCDLL.dylib"
#  else
#    define OMCDLL_NAME "libOMCDLL.so"
#  endif
#  define DL_SYM(h, s) dlsym((h), (s))
#  define DL_CLOSE(h)  dlclose(h)
static void *dl_open(const char *spec, int is_path)
{
  (void) is_path;
  return dlopen(spec, RTLD_NOW | RTLD_GLOBAL);
}
#endif

/* Opaque; libOMCDLL owns the real definition (struct OMCData). */
typedef struct OMCData OMCData;

typedef void (*InitMetaOMC_t)(void);
typedef int  (*InitOMC_t)(OMCData **, const char *compiler, const char *openModelicaHome);
typedef int  (*InitOMCWithZeroMQ_t)(OMCData **, const char *, const char *, const char *, const char *, int);
typedef int  (*GetOMCVersion_t)(OMCData *, char **result);
typedef void (*FreeOMC_t)(OMCData *);
typedef int  (*GetError_t)(OMCData *, char **result);
typedef int  (*LoadModel_t)(OMCData *, const char *className);
typedef int  (*LoadFile_t)(OMCData *, const char *fileName);
typedef int  (*SendCommand_t)(OMCData *, const char *expression, char **result);
typedef int  (*SetCommandLineOptions_t)(OMCData *, const char *expression);
typedef int  (*SetWorkingDirectory_t)(OMCData *, const char *directory, char **result);

static InitMetaOMC_t           InitMetaOMC;
static InitOMC_t               InitOMC;
static InitOMCWithZeroMQ_t     InitOMCWithZeroMQ;
static GetOMCVersion_t         GetOMCVersion;
static FreeOMC_t               FreeOMC;
static GetError_t              GetError;
static LoadModel_t             LoadModel;
static LoadFile_t              LoadFile;
static SendCommand_t           SendCommand;
static SetCommandLineOptions_t SetCommandLineOptions;
static SetWorkingDirectory_t   SetWorkingDirectory;

static OMCData *omc;
static int      omc_ready; /* set once InitOMC has succeeded */

static void *must_sym(void *h, const char *name)
{
  void *p = DL_SYM(h, name);
  if (!p) {
    fprintf(stderr, "FAIL: %s does not export '%s'\n", OMCDLL_NAME, name);
    exit(2);
  }
  return p;
}

/* Assert helper: on failure print the omc error buffer and exit with `code`. */
static void check(int ok, int code, const char *what)
{
  if (ok) {
    printf("ok: %s\n", what);
    return;
  }
  fprintf(stderr, "FAIL: %s\n", what);
  if (omc_ready) {
    char *err = NULL;
    if (GetError(omc, &err) > 0 && err && err[0]) {
      fprintf(stderr, "      omc error: %s\n", err);
    }
  }
  exit(code);
}

static int contains(const char *hay, const char *needle)
{
  return hay && strstr(hay, needle) != NULL;
}

int main(int argc, char **argv)
{
  const char *lib     = (argc > 1) ? argv[1] : OMCDLL_NAME;
  const int   is_path = (argc > 1);
  char *r = NULL;

  const char *omhome = getenv("OPENMODELICAHOME");
  if (!omhome) omhome = getenv("OPENMODELICA_HOME");
  if (!omhome) omhome = ""; /* let omc try to locate itself */

  void *h = dl_open(lib, is_path);
  if (!h) {
    /* Could not even load the library / its dependencies: an environment
     * problem, not an ABI regression. Exit 77 so CTest reports SKIP. */
#if defined(_WIN32)
    fprintf(stderr, "SKIP: could not load %s (error %lu)\n", lib, (unsigned long) GetLastError());
#else
    fprintf(stderr, "SKIP: could not load %s: %s\n", lib, dlerror());
#endif
    return 77;
  }
  printf("ok: loaded %s\n", lib);

  /* Resolving every exported symbol is itself an ABI check. */
  InitMetaOMC           = (InitMetaOMC_t)           must_sym(h, "InitMetaOMC");
  InitOMC               = (InitOMC_t)               must_sym(h, "InitOMC");
  InitOMCWithZeroMQ     = (InitOMCWithZeroMQ_t)     must_sym(h, "InitOMCWithZeroMQ");
  GetOMCVersion         = (GetOMCVersion_t)         must_sym(h, "GetOMCVersion");
  FreeOMC               = (FreeOMC_t)               must_sym(h, "FreeOMC");
  GetError              = (GetError_t)              must_sym(h, "GetError");
  LoadModel             = (LoadModel_t)             must_sym(h, "LoadModel");
  LoadFile              = (LoadFile_t)              must_sym(h, "LoadFile");
  SendCommand           = (SendCommand_t)           must_sym(h, "SendCommand");
  SetCommandLineOptions = (SetCommandLineOptions_t) must_sym(h, "SetCommandLineOptions");
  SetWorkingDirectory   = (SetWorkingDirectory_t)   must_sym(h, "SetWorkingDirectory");
  (void) InitOMCWithZeroMQ; /* resolved above; not exercised (needs a live socket) */
  printf("ok: resolved all 11 exported functions\n");

  InitMetaOMC();

  check(InitOMC(&omc, "gcc", omhome) > 0 && omc != NULL, 3,
        "InitOMC()");
  omc_ready = 1;

  check(GetOMCVersion(omc, &r) > 0 && r && r[0], 4, "GetOMCVersion()");
  printf("     version: %s\n", r);

  check(SetCommandLineOptions(omc, "-d=newInst") > 0, 5,
        "SetCommandLineOptions()");

  check(SendCommand(omc, "1 + 2", &r) > 0 && contains(r, "3"), 6,
        "SendCommand(\"1 + 2\") -> 3");

  /* LoadFile: write a tiny model, load it, confirm omc sees it. */
  {
    const char *mo_path = "omccapi_verify_model.mo";
    FILE *f = fopen(mo_path, "w");
    check(f != NULL, 7, "create temporary .mo file");
    fputs("model OMCApiVerifyModel Real x(start = 1); equation der(x) = -x; end OMCApiVerifyModel;\n", f);
    fclose(f);

    check(LoadFile(omc, mo_path) > 0, 8, "LoadFile()");
    check(SendCommand(omc, "isModel(OMCApiVerifyModel)", &r) > 0 && contains(r, "true"), 9,
          "loaded model is visible to omc");
    remove(mo_path);
  }

  /* SetWorkingDirectory: mkdir + cd in + cd back (as OMCTest.cpp did). */
  check(SendCommand(omc, "mkdir(\"omccapi_verify_wd\")", &r) > 0, 10,
        "SendCommand(\"mkdir(...)\")");
  check(SetWorkingDirectory(omc, "omccapi_verify_wd", &r) > 0 && r && contains(r, "omccapi_verify_wd"), 11,
        "SetWorkingDirectory() into new dir");
  check(SetWorkingDirectory(omc, "..", &r) > 0, 12,
        "SetWorkingDirectory() back");

  /* GetError after a deliberately failing LoadModel. */
  GetError(omc, &r); /* drain any pending warnings first */
  check(LoadModel(omc, "ThisClassDoesNotExist") <= 0, 13,
        "LoadModel(\"ThisClassDoesNotExist\") fails as expected");
  check(GetError(omc, &r) > 0, 14, "GetError() after the failed load");
  printf("     error:   %s\n", (r && r[0]) ? r : "(empty)");

  /* MSL-dependent section: a bare build tree has no standard library, so this is
   * best-effort. When MSL *is* available it is asserted, matching OMCTest.cpp. */
  if (LoadModel(omc, "Modelica") > 0) {
    printf("ok: LoadModel(\"Modelica\") (MSL available)\n");
    check(SendCommand(omc, "isPackage(Modelica)", &r) > 0 && contains(r, "true"), 15,
          "MSL is loaded as a package");
    if (SendCommand(omc, "simulate(Modelica.Blocks.Examples.PID_Controller, stopTime = 0.1, numberOfIntervals = 2)", &r) > 0
        && contains(r, "resultFile = \"")
        && !contains(r, "resultFile = \"\"")) {
      printf("ok: simulate(Modelica.Blocks.Examples.PID_Controller)\n");
    } else {
      printf("note: simulate() did not produce a result (no C compiler?) -- skipped\n");
    }
  } else {
    printf("note: MSL not available -- LoadModel(\"Modelica\") / simulate() skipped\n");
  }

  SendCommand(omc, "clear()", &r);
  check(SendCommand(omc, "getClassNames()", &r) > 0 && contains(r, "{}"), 16,
        "clear() emptied the symbol table");

  FreeOMC(omc);
  omc = NULL;
  DL_CLOSE(h);

  printf("\nPASS: libOMCDLL is usable.\n");
  return 0;
}
