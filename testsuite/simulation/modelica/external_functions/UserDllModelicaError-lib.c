/* A shared library that calls ModelicaError without linking any OpenModelica
 * library. On Windows it looks the function up in the loaded modules at run
 * time, as the MWE of #14581 does; elsewhere the dynamic linker binds it. */
#include <stdio.h>

typedef void (*ModelicaError_t)(const char *);

#if defined(_WIN32)
/* EnumProcessModules from kernel32 (K32EnumProcessModules): no psapi.lib to link. */
#define PSAPI_VERSION 2
#include <windows.h>
#include <psapi.h>

static ModelicaError_t findModelicaError(void)
{
  HMODULE modules[1024];
  DWORD needed, i;
  FARPROC f = GetProcAddress(GetModuleHandleA(NULL), "ModelicaError");
  if (!f && EnumProcessModules(GetCurrentProcess(), modules, sizeof(modules), &needed)) {
    for (i = 0; !f && i < needed / sizeof(HMODULE); i++) {
      f = GetProcAddress(modules[i], "ModelicaError");
    }
  }
  return (ModelicaError_t)f;
}
#define EXPORT __declspec(dllexport)
#else
void ModelicaError(const char *string);
static ModelicaError_t findModelicaError(void) { return ModelicaError; }
#define EXPORT
#endif

EXPORT double userdll_bar(double t)
{
  if (t > 0.5) {
    char msg[64];
    ModelicaError_t err = findModelicaError();
    snprintf(msg, sizeof(msg), "ModelicaError from a shared library at t=%g", t);
    if (!err) {
      fputs("ModelicaError not found in any loaded module\n", stderr);
      return t;
    }
    err(msg);
  }
  return t;
}
