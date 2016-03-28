/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

#ifdef __cplusplus
extern "C" {
#endif

#include "omc_msvc.h"
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>


#if defined(__MINGW32__) || defined(_MSC_VER)

int asprintf(char **strp, const char *fmt, ...) {
  int len;
  va_list ap;
  va_start(ap, fmt);

  len = vsnprintf(NULL, 0, fmt, ap);
  *strp = malloc(len+1);
  len = vsnprintf(*strp, len+1, fmt, ap);

  va_end(ap);
  return len;
}

int vasprintf(char **strp, const char *fmt, va_list ap) {
  int len;
  len = vsnprintf(NULL, 0, fmt, ap);
  *strp = malloc(len+1);
  len = vsnprintf(*strp, len+1, fmt, ap);
  return len;
}

#if !defined(OMC_MINIMAL_RUNTIME)

#include <windows.h>
#include <tlhelp32.h>
#include <time.h>

#ifndef SIGALRM
#define SIGALRM         SIGTERM
#endif

static HANDLE thread    = 0; // thread handle

/* adrpo: found this on http://stackoverflow.com/questions/1173342/terminate-a-process-tree-c-for-windows
 * thanks go to: mjmarsh & Firas Assaad
 * adapted to recurse on children ids
 */
void killProcessTreeWindows(DWORD myprocID)
{
  PROCESSENTRY32 pe;
  HANDLE hSnap = NULL, hProc = NULL;

  memset(&pe, 0, sizeof(PROCESSENTRY32));
  pe.dwSize = sizeof(PROCESSENTRY32);

  hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

  if (Process32First(hSnap, &pe))
  {
      BOOL bContinue = TRUE;

      // kill child processes
      while (bContinue)
      {
          // only kill child processes
          if (pe.th32ParentProcessID == myprocID)
          {
              HANDLE hChildProc = NULL;

              // recurse
              killProcessTreeWindows(pe.th32ProcessID);

              hChildProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, pe.th32ProcessID);

              if (hChildProc)
              {
                  TerminateProcess(hChildProc, 1);
                  CloseHandle(hChildProc);
              }
          }

          bContinue = Process32Next(hSnap, &pe);
      }

      // kill the main process
      hProc = OpenProcess(PROCESS_ALL_ACCESS, FALSE, myprocID);

      if (hProc)
      {
          TerminateProcess(hProc, 1);
          CloseHandle(hProc);
      }
  }
}


static DWORD WINAPI killProcess (LPVOID arg)
{
  Sleep (1000 * ((unsigned int)arg));
  fprintf(stdout, "Alarm clock"); fflush(NULL);
  killProcessTreeWindows(GetCurrentProcessId());

  return 0;
}

unsigned int alarm (unsigned int seconds)
{
  static unsigned pending = 0;   // previous alarm() argument
  static time_t t0        = 0;   // start of previous alarm()
  time_t unslept          = 0;   // seconds until previous alarm expires

  if (thread) {
      // previous alarm is still pending, cancel it
      unslept = pending - (time (0) - t0);
      TerminateThread (thread, 0);
      CloseHandle (thread);
      thread = 0;
  }

  pending = seconds;

  if (seconds) {
      DWORD threadId;
      time (&t0);   // keep track of when count down started
      thread = CreateThread (0, 0, killProcess, (void*)seconds, 0, &threadId);
  }

  return (unsigned int)(unslept);
}

#endif /* !defined(OMC_MINIMAL_RUNTIME) */

#endif

#if defined(__MINGW32__) || defined(_MSC_VER)

#if defined(__MINGW32__)
#include <dirent.h>
#include <unistd.h>
#endif

#if defined(_MSC_VER)
#include <direct.h> /* for mkdir */
#endif

/* from "man mkdtemp":
  The mkdtemp() function generates a uniquely named temporary directory from
  template. The last six characters of template must be XXXXXX and these are
  replaced with a string that makes the directory name unique. The directory
  is then created with permissions 0700. Since it will be modified, template
  must not be a string constant, but should be declared as a character array.

  The mkdtemp() function returns a pointer to the modified template string on
  success, and NULL on failure, in which case errno is set appropriately.
*/
char *mkdtemp(char *tpl)
{
  int i, len, n;

  len = strlen(tpl);
  /* check for len>=6 and last 6 characters being all 'X' */
  if (len>=6)
  {
    for (i = len-6; i < len; i++)
    {
      if (tpl[i]!='X')
      {
          return NULL;
      }
    }
    for (n=0; n < 256; n++) {
      /* generate random numbers between 0..9 for the last 6 chars of the template name */
      for (i = len-6; i < len; i++)
      {
        tpl[i] = '0' + rand()%10;
      }
      /* try to create dir */
      if (mkdir(tpl) == 0)
      {
        return tpl;
      }
    }
  }

  return NULL;
}

#if !defined(OMC_MINIMAL_RUNTIME)
void* omc_dlopen(const char *filename, int flag)
{
  return (void*) LoadLibrary(filename);
}
#endif

#include <windows.h>

static const char* GetLastErrorAsString()
{
  static char *str = NULL;
  LPSTR messageBuffer = NULL;
  size_t size = 0;
  //Get the error message, if any.
  DWORD errorMessageID = GetLastError();
  if (errorMessageID == 0) {
    return ""; //No error message has been recorded
  }

  size = FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                               NULL, errorMessageID, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), (LPSTR)&messageBuffer, 0, NULL);

  if (str != NULL) {
    free(str);
    str = NULL;
  }
  str = malloc(size+1);
  memcpy(str, messageBuffer, size);
  str[size] = '\0';

  //Free the buffer.
  LocalFree(messageBuffer);

  return str;
}

char* omc_dlerror()
{
  return GetLastErrorAsString();
}

void *omc_dlsym(void *handle, const char *symbol)
{
  return (void*) GetProcAddress(handle, symbol);
}

int omc_dlclose(void *handle)
{
  return FreeLibrary(handle);
}
#endif

#ifdef __cplusplus
}
#endif
