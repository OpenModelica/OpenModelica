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
#include "omc_error.h"
#include "omc_file.h"
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

#include <winsock2.h>
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
#endif /* defined(__MINGW32__) */

#if defined(_MSC_VER)
#include <direct.h> /* for mkdir */
#endif /* defined(_MSC_VER) */

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

#if (defined(__MINGW32__) || defined(_MSC_VER)) && !defined(OMC_MINIMAL_RUNTIME)
void* omc_dlopen(const char *filename, int flag)
{
  return (void*) LoadLibrary(filename);
}

#include <winsock2.h>
#include <imagehlp.h>

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

void* dlopen(const char *filename, int flag) {
  return omc_dlopen(filename, flag);
}

char* dlerror() {
  return omc_dlerror();
}

void* dlsym(void *handle, const char *symbol) {
  return omc_dlsym(handle, symbol);
}

int dlclose(void *handle) {
  return omc_dlclose(handle);
}

int dladdr(void *addr, Dl_info *info) {
  return omc_dladdr(addr, info);
}



#if defined(_MSC_VER)
/* no dladdr on MSVC */
int omc_dladdr(void *addr, Dl_info *info)
{
  return 0;
}
#else /* MINGW */

/*
 * used the implementation from:
 * http://emfisis.physics.uiowa.edu/Software/C/librpwgse/rpwgse/GseWinSvc.c
 * this is work in progress, we need to load the symbols and search in them
 * using the function address (using something similar to what we have in backtrace.c)
 */
int omc_dladdr(void *addr, Dl_info *info)
{
  HANDLE hProcess;
  DWORD dwModuleBase;
  DWORD displacement;
  char sModuleName[MAX_PATH + 1];
  sModuleName[MAX_PATH] = '\0';

  hProcess = GetCurrentProcess();

  /* Init the structure to nothing */
  info->dli_fname = NULL;
  info->dli_fbase = NULL;
  info->dli_sname = NULL;
  info->dli_saddr = NULL;
  info->dli_salloc = 0;

  dwModuleBase = SymGetModuleBase(hProcess, (DWORD)addr);
  info->dli_fbase = (void*)dwModuleBase;
  if(! GetModuleFileNameA((HMODULE)dwModuleBase, sModuleName, MAX_PATH)) return 0;

  info->dli_fname = (const char*) calloc(MAX_PATH + 1, sizeof(char));
  memcpy((char*)info->dli_fname, sModuleName, MAX_PATH);

  /* First assume that name is in the current mingw compiled executable */
  // here we should do something similar to backtrace.c find function

  /* Name might be in a DLL, try to get it */
  if(!(info->dli_sname)){

    displacement = 0;
    char symbol_buffer[sizeof(IMAGEHLP_SYMBOL) + 255];
    symbol_buffer[sizeof(IMAGEHLP_SYMBOL) + 254] = '\0';

    IMAGEHLP_SYMBOL* pSymbol = (IMAGEHLP_SYMBOL*)symbol_buffer;

    pSymbol->SizeOfStruct = sizeof(IMAGEHLP_SYMBOL) + 255;
    pSymbol->MaxNameLength = 254;

    if(SymGetSymFromAddr(hProcess, (DWORD)addr, &displacement, pSymbol)) {
      info->dli_sname = (const char*) calloc(pSymbol->MaxNameLength + 1, 1);
      memcpy((char*)info->dli_sname, pSymbol->Name, pSymbol->MaxNameLength);
      info->dli_salloc = 1;
    }
  }
  if(!(info->dli_sname)){
    info->dli_sname = "[unknown function name]";
  }

  return 1;
}

#endif /* #if (defined(__MINGW32__) || defined(_MSC_VER)) && !defined(OMC_MINIMAL_RUNTIME) */

#endif /* #if defined(__MINGW32__) || defined(_MSC_VER)  */

#endif

#if defined(__MINGW32__) || defined(_MSC_VER)

#ifdef __MINGW32__

char *realpath(const char *path, char resolved_path[PATH_MAX])
{
  if (!_fullpath(resolved_path, path, PATH_MAX))
  {
    FILE_INFO info = omc_dummyFileInfo;
    omc_assert_warning(info, "System.realpath failed on %s with errno: %d", path, errno);
    resolved_path = (char*)path;
  }
  return resolved_path;
}

#else

/*
realpath() Win32 implementation, supports non standard glibc extension
This file has no copyright assigned and is placed in the Public Domain.
Written by Nach M. S. September 8, 2005
*/

#include <winsock2.h>
#include <stdlib.h>
#include <limits.h>
#include <errno.h>
#include <sys/stat.h>

char *realpath(const char *path, char resolved_path[PATH_MAX])
{
  char *return_path = 0;

  if (path) //Else EINVAL
  {
    if (resolved_path)
    {
      return_path = resolved_path;
    }
    else
    {
      //Non standard extension that glibc uses
      return_path = (char*)malloc(PATH_MAX);
    }

    if (return_path) //Else EINVAL
    {
      //This is a Win32 API function similar to what realpath() is supposed to do
      size_t size = GetFullPathNameA(path, PATH_MAX, return_path, 0);

      //GetFullPathNameA() returns a size larger than buffer if buffer is too small
      if (size > PATH_MAX)
      {
        if (return_path != resolved_path) //Malloc'd buffer - Unstandard extension retry
        {
          size_t new_size;

          free(return_path);
          return_path = (char*)malloc(size);

          if (return_path)
          {
            new_size = GetFullPathNameA(path, size, return_path, 0); //Try again

            if (new_size > size) //If it's still too large, we have a problem, don't try again
            {
              free(return_path);
              return_path = 0;
              errno = ENAMETOOLONG;
            }
            else
            {
              size = new_size;
            }
          }
          else
          {
            //I wasn't sure what to return here, but the standard does say to return EINVAL
            //if resolved_path is null, and in this case we couldn't malloc large enough buffer
            errno = EINVAL;
          }
        }
        else //resolved_path buffer isn't big enough
        {
          return_path = 0;
          errno = ENAMETOOLONG;
        }
      }

      //GetFullPathNameA() returns 0 if some path resolve problem occured
      if (!size)
      {
        if (return_path != resolved_path) //Malloc'd buffer
        {
          free(return_path);
        }

        return_path = 0;

        //Convert MS errors into standard errors
        switch (GetLastError())
        {
          case ERROR_FILE_NOT_FOUND:
            errno = ENOENT;
            break;

          case ERROR_PATH_NOT_FOUND: case ERROR_INVALID_DRIVE:
            errno = ENOTDIR;
            break;

          case ERROR_ACCESS_DENIED:
            errno = EACCES;
            break;

          default: //Unknown Error
            errno = EIO;
            break;
        }
      }

      //If we get to here with a valid return_path, we're still doing good
      if (return_path)
      {
        omc_stat_t stat_buffer;

        //Make sure path exists, omc_stat() returns 0 on success
        if (omc_stat(return_path, &stat_buffer))
        {
          if (return_path != resolved_path)
          {
            free(return_path);
          }

          return_path = 0;
          //omc_stat() will set the correct errno for us
        }
        //else we succeeded!
      }
    }
    else
    {
      errno = EINVAL;
    }
  }
  else
  {
    errno = EINVAL;
  }

  if (return_path == NULL)
  {
    FILE_INFO info = omc_dummyFileInfo;
    omc_assert_warning(info, "System.realpath failed on %s with errno: %d", path, errno);
    resolved_path = (char*)path;
    return_path = (char*)path;
  }

  return return_path;
}
#endif /* mingw */

#endif /* mingw and msvc */

#ifdef __cplusplus
}
#endif
