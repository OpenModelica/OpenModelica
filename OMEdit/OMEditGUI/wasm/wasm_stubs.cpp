// Startup symbols OMEdit links from libOpenModelicaCompiler.so natively but that
// the wasm build (omc in a Web Worker) has no cdylib for. See wasm/HANDOFF.md.

#include <cstdlib>
#include <ctime>
#include <util/rtclock.h>

extern "C" {

// OMEditApplication aborts startup if this returns null; no install tree on wasm,
// so a non-null placeholder (the page's OPENMODELICAHOME, else "/usr") suffices.
const char *SettingsImpl__getInstallationDirectoryPath()
{
  const char *home = getenv("OPENMODELICAHOME");
  return (home && *home) ? home : "/usr";
}

// Animation/TimeManager.cpp is compiled for wasm (drives the result-replay time
// slider) but rtclock.c is not (it pulls in the Boehm GC headers). These two are
// the only rtclock entry points TimeManager uses; the rest of rtclock is unneeded.
void rt_ext_tp_tick_realtime(rtclock_t *tick_tp)
{
  clock_gettime(CLOCK_MONOTONIC, &tick_tp->time);
}

double rt_ext_tp_tock(rtclock_t *tick_tp)
{
  struct timespec now;
  clock_gettime(CLOCK_MONOTONIC, &now);
  return (now.tv_sec - tick_tp->time.tv_sec) + (now.tv_nsec - tick_tp->time.tv_nsec) * 1e-9;
}

} // extern "C"
