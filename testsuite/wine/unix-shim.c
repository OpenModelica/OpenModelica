/* Runs the Linux program UNIX_PROGRAM from under wine and exits with its exit
 * code.
 *
 * The Linux process inherits the Unix stdin and stdout wine gave this process
 * when it started, from handles wine could turn into file descriptors (a file
 * opened for writing, but not a pipe or one opened for appending only), and
 * wine's own stderr. So the shim runs a copy of itself with a temporary file
 * for stdout, and copies that to the real stdout. */
#include <windows.h>
#include <shellapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef NTSTATUS (CDECL *unix_spawnvp_t)(char *const argv[], int wait);

#define INNER L"UNIX_SHIM_INNER"

static char *utf8(const WCHAR *w)
{
  int n = WideCharToMultiByte(CP_UTF8, 0, w, -1, NULL, 0, NULL, NULL);
  char *s = malloc(n);
  WideCharToMultiByte(CP_UTF8, 0, w, -1, s, n, NULL, NULL);
  return s;
}

static BOOL same_file(HANDLE a, HANDLE b)
{
  BY_HANDLE_FILE_INFORMATION ia, ib;
  if (a == b)
    return TRUE;
  return GetFileType(a) == FILE_TYPE_DISK && GetFileType(b) == FILE_TYPE_DISK &&
         GetFileInformationByHandle(a, &ia) && GetFileInformationByHandle(b, &ib) &&
         ia.dwVolumeSerialNumber == ib.dwVolumeSerialNumber &&
         ia.nFileIndexHigh == ib.nFileIndexHigh && ia.nFileIndexLow == ib.nFileIndexLow;
}

static int run_unix(BOOL merge_stderr)
{
  unix_spawnvp_t unix_spawnvp = (unix_spawnvp_t)
    GetProcAddress(GetModuleHandleW(L"ntdll.dll"), "__wine_unix_spawnvp");
  if (!unix_spawnvp) {
    fprintf(stderr, "unix-shim: not running under wine\n");
    return 127;
  }

  int argc;
  WCHAR **wargv = CommandLineToArgvW(GetCommandLineW(), &argc);
  char **argv = calloc(argc + 4, sizeof(char *));
  char **args = argv;
  if (merge_stderr) {
    argv[0] = "/bin/sh";
    argv[1] = "-c";
    argv[2] = "exec \"$0\" \"$@\" 2>&1";
    args += 3;
  }
  args[0] = UNIX_PROGRAM;
  for (int i = 1; i < argc; i++)
    args[i] = utf8(wargv[i]);

  NTSTATUS status = unix_spawnvp(argv, TRUE);
  if (status < 0) {
    fprintf(stderr, "unix-shim: cannot run %s (0x%lx)\n", UNIX_PROGRAM, (unsigned long)status);
    return 127;
  }
  return status;
}

int wmain(void)
{
  WCHAR mode[8];
  if (GetEnvironmentVariableW(INNER, mode, 8))
    return run_unix(mode[0] == L'2');

  HANDLE out = GetStdHandle(STD_OUTPUT_HANDLE);
  HANDLE err = GetStdHandle(STD_ERROR_HANDLE);
  /* "2": stderr goes where stdout does, as after a 2>&1. */
  SetEnvironmentVariableW(INNER, same_file(out, err) ? L"2" : L"1");

  SECURITY_ATTRIBUTES sa = { sizeof(sa), NULL, TRUE };
  WCHAR dir[MAX_PATH], tmp[MAX_PATH], self[MAX_PATH];
  HANDLE log = INVALID_HANDLE_VALUE;
  if (GetTempPathW(MAX_PATH, dir) && GetTempFileNameW(dir, L"shm", 0, tmp))
    log = CreateFileW(tmp, GENERIC_READ | GENERIC_WRITE,
                      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, &sa,
                      CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY | FILE_FLAG_DELETE_ON_CLOSE, NULL);
  if (log == INVALID_HANDLE_VALUE || !GetModuleFileNameW(NULL, self, MAX_PATH)) {
    fprintf(stderr, "unix-shim: cannot create a temporary file\n");
    return 127;
  }

  STARTUPINFOW si = { sizeof(si) };
  PROCESS_INFORMATION pi;
  si.dwFlags = STARTF_USESTDHANDLES;
  si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
  si.hStdOutput = log;
  si.hStdError = err;
  if (!CreateProcessW(self, GetCommandLineW(), NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi)) {
    fprintf(stderr, "unix-shim: cannot start %ls\n", self);
    return 127;
  }
  WaitForSingleObject(pi.hProcess, INFINITE);

  char buf[4096];
  DWORD n, written;
  SetFilePointer(log, 0, NULL, FILE_BEGIN);
  while (ReadFile(log, buf, sizeof(buf), &n, NULL) && n)
    WriteFile(out, buf, n, &written, NULL);

  DWORD code = 127;
  GetExitCodeProcess(pi.hProcess, &code);
  return code;
}
