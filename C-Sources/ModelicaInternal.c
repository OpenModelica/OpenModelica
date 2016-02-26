/* ModelicaInternal.c - External functions for Modelica.Utilities

   Copyright (C) 2002-2016, Modelica Association and DLR
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

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

/* The functions are mostly non-portable. The following #define's are used
   to define the system calls of the operating system

   _WIN32         : System calls of Windows'95, Windows'NT
                    (Note, that these system calls allow both '/' and '\'
                    as directory separator for input arguments. As return
                    argument '\' is used).
                    All system calls are from the library libc.a.
   _POSIX_        : System calls of POSIX
   _MSC_VER       : Microsoft Visual C++
   __GNUC__       : GNU C compiler
   NO_FILE_SYSTEM : A file system is not present (e.g. on dSPACE or xPC).
   NO_PID         : Function getpid is not present (e.g. on dSPACE)
   NO_TIME        : Function gettimeofday is not present (e.g. on dSPACE)
   MODELICA_EXPORT: Prefix used for function calls. If not defined, blank is used
                    Useful definitions:
                    - "static" that is all functions become static
                      (useful if file is included with other C-sources for an
                       embedded system)
                    - "__declspec(dllexport)" if included in a DLL and the
                      functions shall be visible outside of the DLL

   Release Notes:
      Dec. 10, 2015: by Martin Otter, DLR
                     Added flags NO_PID and NO_TIME (ticket #1805)

      Oct. 27, 2015: by Thomas Beutlich, ITI GmbH
                     Added nonnull attributes/annotations (ticket #1436)

      Oct. 05, 2015: by Thomas Beutlich, ITI GmbH
                     Added functions ModelicaInternal_getpid/_getTime from
                     ModelicaRandom.c of https://github.com/DLR-SR/Noise
                     (ticket #1662)

      Nov. 20, 2014: by Thomas Beutlich, ITI GmbH
                     Fixed platform dependency of ModelicaInternal_readLine/_readFile
                     (ticket #1580)

      Aug. 22, 2014: by Thomas Beutlich, ITI GmbH
                     Fixed multi-threaded access of common/shared file cache
                     (ticket #1556)

      Aug. 11, 2014: by Thomas Beutlich, ITI GmbH
                     Increased cache size of opened files and made it
                     thread-safe (ticket #1433)
                     Made getenv/putenv thread-safe for Visual Studio 2005 and
                     later (ticket #1433)

      May 21, 2013:  by Martin Otter, DLR
                     Included the improvements from DS Lund:
                     - Changed implementation of print to do nothing in case of
                       missing file-system. Otherwise we just end up with an
                       error message that is not written, and the failure in
                       itself is not sufficiently fatal to just stop.
                     - Caching when reading from file

      Mar, 26, 2013: by Martin Otter, DLR
                     Changed type of variable valueStart from int to size_t
                     (ticket #1032)

      Jan. 05, 2013: by Martin Otter, DLR
                     Removed "static" declarations from the Modelica interface
                     functions

      Sep. 26, 2004: by Martin Otter, DLR
                     Added missing implementations, merged code from previous
                     ModelicaFiles and clean-up of code

      Sep. 09, 2004: by Dag Bruck, Dynasim AB
                     Further implementation and clean-up of code

      Aug. 24, 2004: by Martin Otter, DLR
                     Adapted to Dymola 5.3 with minor improvements

      Jan. 07, 2002: by Martin Otter, DLR
                     First version implemented:
                     Only tested for _WIN32, but implemented all
                     functions also for _POSIX_, with the exception of
                     ModelicaInternal_getFullPath
*/

#if !defined(MODELICA_EXPORT)
  #define MODELICA_EXPORT
#endif

#include <string.h>
#include "ModelicaUtilities.h"

/* The standard way to detect posix is to check _POSIX_VERSION,
 * which is defined in <unistd.h>
 */
#if defined(__unix__) || defined(__linux__) || defined(__APPLE_CC__)
  #include <unistd.h>
#endif

#if !defined(_POSIX_) && defined(_POSIX_VERSION)
  #define _POSIX_ 1
#endif

static void ModelicaNotExistError(const char* name) {
  /* Print error message if a function is not implemented */
    ModelicaFormatError("C-Function \"%s\" is called\n"
        "but is not implemented for the actual environment\n"
        "(e.g., because there is no file system available on the machine\n"
        "as for dSPACE or xPC systems)", name);
}

#ifdef NO_FILE_SYSTEM
MODELICA_EXPORT void ModelicaInternal_mkdir(const char* directoryName) {
    ModelicaNotExistError("ModelicaInternal_mkdir"); }
MODELICA_EXPORT void ModelicaInternal_rmdir(const char* directoryName) {
    ModelicaNotExistError("ModelicaInternal_rmdir"); }
MODELICA_EXPORT int  ModelicaInternal_stat(const char* name) {
    ModelicaNotExistError("ModelicaInternal_stat"); return 0; }
MODELICA_EXPORT void ModelicaInternal_rename(const char* oldName, const char* newName)  {
    ModelicaNotExistError("ModelicaInternal_rename"); }
MODELICA_EXPORT void ModelicaInternal_removeFile(const char* file) {
    ModelicaNotExistError("ModelicaInternal_removeFile"); }
MODELICA_EXPORT void ModelicaInternal_copyFile(const char* oldFile, const char* newFile) {
    ModelicaNotExistError("ModelicaInternal_copyFile"); }
MODELICA_EXPORT void ModelicaInternal_readDirectory(const char* directory, int nFiles, const char* files[]) {
    ModelicaNotExistError("ModelicaInternal_readDirectory"); }
MODELICA_EXPORT int  ModelicaInternal_getNumberOfFiles(const char* directory) {
    ModelicaNotExistError("ModelicaInternal_getNumberOfFiles"); return 0; }
MODELICA_EXPORT const char* ModelicaInternal_fullPathName(const char* name) {
    ModelicaNotExistError("ModelicaInternal_fullPathName"); return 0; }
MODELICA_EXPORT const char* ModelicaInternal_temporaryFileName(void) {
    ModelicaNotExistError("ModelicaInternal_temporaryFileName"); return 0; }
MODELICA_EXPORT void ModelicaInternal_print(const char* string, const char* fileName) {
    if ( fileName[0] == '\0' ) {
      /* Write string to terminal */
        ModelicaFormatMessage("%s\n", string);
    }
    return; }
MODELICA_EXPORT int  ModelicaInternal_countLines(const char* fileName) {
    ModelicaNotExistError("ModelicaInternal_countLines"); return 0; }
MODELICA_EXPORT void ModelicaInternal_readFile(const char* fileName, const char* string[], size_t nLines) {
    ModelicaNotExistError("ModelicaInternal_readFile"); }
MODELICA_EXPORT const char* ModelicaInternal_readLine(const char* fileName, int lineNumber, int* endOfFile) {
    ModelicaNotExistError("ModelicaInternal_readLine"); return 0; }
MODELICA_EXPORT void ModelicaInternal_chdir(const char* directoryName) {
    ModelicaNotExistError("ModelicaInternal_chdir"); }
MODELICA_EXPORT const char* ModelicaInternal_getcwd(int dummy) {
    ModelicaNotExistError("ModelicaInternal_getcwd"); return 0; }
MODELICA_EXPORT void ModelicaInternal_getenv(const char* name, int convertToSlash, const char** content, int* exist) {
    ModelicaNotExistError("ModelicaInternal_getenv"); }
MODELICA_EXPORT void ModelicaInternal_setenv(const char* name, const char* value, int convertFromSlash) {
    ModelicaNotExistError("ModelicaInternal_setenv"); }
#else

#define uthash_fatal(msg) ModelicaFormatMessage("Error: %s\n", msg); break
#include "uthash.h"
#include "gconstructor.h"

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#if defined(__WATCOMC__)
  #include <direct.h>
  #include <sys/types.h>
  #include <sys/stat.h>
#elif defined(__BORLANDC__)
  #include <direct.h>
  #include <sys/types.h>
  #include <sys/stat.h>
  #include <dirent.h>
#elif defined(_WIN32)
  #include <direct.h>
  #include <sys/types.h>
  #include <sys/stat.h>

  #if defined(__MINGW32__) || defined(__CYGWIN__) /* MinGW and Cygwin have dirent.h */
    #include <dirent.h>
  #else /* include the opendir/readdir/closedir implementation for _WIN32 */
    #include "win32_dirent.c"
  #endif

#elif defined(_POSIX_) || defined(__GNUC__)
  #include <dirent.h>
  #include <unistd.h>
  #include <sys/types.h>
  #include <sys/stat.h>
#endif

/*
 * Non-null pointers and esp. null-terminated strings need to be passed to
 * external functions.
 *
 * The following macros handle nonnull attributes for GNU C and Microsoft SAL.
 */
#if defined(__GNUC__)
#define MODELICA_NONNULLATTR __attribute__((nonnull))
#if defined(__GNUC_MINOR__) && (__GNUC__ > 3 && __GNUC_MINOR__ > 8)
#define MODELICA_RETURNNONNULLATTR __attribute__((returns_nonnull))
#else
#define MODELICA_RETURNNONNULLATTR
#endif
#elif defined(__ATTR_SAL)
#define MODELICA_NONNULLATTR
#define MODELICA_RETURNNONNULLATTR _Ret_z_ /* _Ret_notnull_ and null-terminated */
#else
#define MODELICA_NONNULLATTR
#define MODELICA_RETURNNONNULLATTR
#endif
#if !defined(__ATTR_SAL)
#define _In_z_
#define _Out_
#endif

MODELICA_EXPORT void ModelicaInternal_mkdir(_In_z_ const char* directoryName) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaInternal_rmdir(_In_z_ const char* directoryName) MODELICA_NONNULLATTR;
MODELICA_EXPORT int ModelicaInternal_stat(_In_z_ const char* name) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaInternal_rename(_In_z_ const char* oldName,
    _In_z_ const char* newName) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaInternal_removeFile(_In_z_ const char* file) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaInternal_copyFile(_In_z_ const char* oldFile,
    _In_z_ const char* newFile) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaInternal_readDirectory(_In_z_ const char* directory, int nFiles,
    _Out_ const char** files) MODELICA_NONNULLATTR;
MODELICA_EXPORT int ModelicaInternal_getNumberOfFiles(_In_z_ const char* directory) MODELICA_NONNULLATTR;
MODELICA_EXPORT MODELICA_RETURNNONNULLATTR const char* ModelicaInternal_fullPathName(
    _In_z_ const char* name) MODELICA_NONNULLATTR;
MODELICA_EXPORT MODELICA_RETURNNONNULLATTR const char* ModelicaInternal_temporaryFileName(void);
MODELICA_EXPORT void ModelicaStreams_closeFile(_In_z_ const char* fileName) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaInternal_print(_In_z_ const char* string,
    _In_z_ const char* fileName) MODELICA_NONNULLATTR;
MODELICA_EXPORT int ModelicaInternal_countLines(_In_z_ const char* fileName) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaInternal_readFile(_In_z_ const char* fileName,
    _Out_ const char* string[], size_t nLines) MODELICA_NONNULLATTR;
MODELICA_EXPORT MODELICA_RETURNNONNULLATTR const char* ModelicaInternal_readLine(_In_z_ const char* fileName,
    int lineNumber, _Out_ int* endOfFile) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaInternal_chdir(_In_z_ const char* directoryName) MODELICA_NONNULLATTR;
MODELICA_EXPORT MODELICA_RETURNNONNULLATTR const char* ModelicaInternal_getcwd(int dummy);
MODELICA_EXPORT void ModelicaInternal_getenv(_In_z_ const char* name, int convertToSlash,
    _Out_ const char** content, _Out_ int* exist) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaInternal_setenv(_In_z_ const char* name,
    _In_z_ const char* value, int convertFromSlash) MODELICA_NONNULLATTR;
MODELICA_EXPORT void ModelicaInternal_getTime(_Out_ int* ms, _Out_ int* sec, _Out_ int* min, _Out_ int* hour,
    _Out_ int* mday, _Out_ int* mon, _Out_ int* year) MODELICA_NONNULLATTR;

#if PATH_MAX > 1024
#define BUFFER_LENGTH PATH_MAX
#else
#define BUFFER_LENGTH 1024
#endif

typedef enum {
    FileType_NoFile = 1,
    FileType_RegularFile,
    FileType_Directory,
    FileType_SpecialFile   /* pipe, FIFO, device, etc. */
} ModelicaFileType;

/* Convert to Unix directory separators: */
#if defined(_WIN32)
static void ModelicaConvertToUnixDirectorySeparator(char* string) {
    /* Convert to Unix directory separators */
    char* c = string;
    while ( *c ) {
        if ( *c == '\\' )  {
            *c = '/';
        }
        c++;
    }
}

static void ModelicaConvertFromUnixDirectorySeparator(char* string) {
    /* Convert from Unix directory separators */
    char* c = string;
    while ( *c ) {
        if ( *c == '/' )  {
            *c = '\\';
        }
        c++;
    }
}
#else
  #define ModelicaConvertToUnixDirectorySeparator(string) ;
  #define ModelicaConvertFromUnixDirectorySeparator(string) ;
#endif

/* --------------------- Modelica_Utilities.Internal --------------------------------- */

MODELICA_EXPORT void ModelicaInternal_mkdir(const char* directoryName) {
    /* Create directory */
#if defined(__WATCOMC__) || defined(__LCC__)
    int result = mkdir(directoryName);
#elif defined(__BORLANDC__) || defined(_WIN32)
    int result = _mkdir(directoryName);
#elif defined(_POSIX_) || defined(__GNUC__)
    int result = mkdir(directoryName, S_IRUSR | S_IWUSR | S_IXUSR);
#else
    int result = -1;
    ModelicaNotExistError("ModelicaInternal_mkdir");
#endif

    if (result != 0) {
        ModelicaFormatError("Not possible to create new directory\n"
            "\"%s\":\n%s", directoryName, strerror(errno));
    }
}

MODELICA_EXPORT void ModelicaInternal_rmdir(const char* directoryName) {
    /* Remove directory */
#if defined(__WATCOMC__) || defined(__LCC__) || defined(_POSIX_) || defined(__GNUC__)
    int result = rmdir(directoryName);
#elif defined(__BORLANDC__) || defined(_WIN32)
    int result = _rmdir(directoryName);
#else
    int result = -1;
    ModelicaNotExistError("ModelicaInternal_rmdir");
#endif

    if (result != 0) {
        ModelicaFormatError("Not possible to remove directory\n"
            "\"%s\":\n%s", directoryName, strerror(errno));
    }
}

MODELICA_EXPORT int ModelicaInternal_stat(const char* name) {
    /* Inquire type of file */
    ModelicaFileType type = FileType_NoFile;

#if defined(__WATCOMC__) || defined(__BORLANDC__)
    struct _stat fileInfo;
    if ( _stat(name, &fileInfo) != 0 ) {
        type = FileType_NoFile;
    }
    else if ( fileInfo.st_mode & S_IFREG ) {
        type = FileType_RegularFile;
    }
    else if ( fileInfo.st_mode & S_IFDIR ) {
        type = FileType_Directory;
    }
    else {
        type = FileType_SpecialFile;
    }
#elif defined(_WIN32)
    struct _stat fileInfo;
    int statReturn;
    statReturn=_stat(name, &fileInfo);
    if (statReturn!=0) {
        /* For some reason _stat requires a:\ and a:\test1 and fails on a: and a:\test1\ */
        /* It could be handled in the Modelica code, but seems better to have here */
        if (strpbrk(name,"/\\")==0 && strchr(name,':')!=0 && strchr(name,':')[1]==0 && (strchr(name,':')-name)<40) {
            char name2[100];
            strcpy(name2,name);
            strcat(name2,"\\");
            statReturn=_stat(name2, &fileInfo);
        }
    }
    if ( statReturn != 0 ) {
        type = FileType_NoFile;
    }
    else if ( fileInfo.st_mode & S_IFREG ) {
        type = FileType_RegularFile;
    }
    else if ( fileInfo.st_mode & S_IFDIR ) {
        type = FileType_Directory;
    }
    else {
        type = FileType_SpecialFile;
    }
#elif defined(_POSIX_) || defined(__GNUC__)
    struct stat fileInfo;
    int statReturn;
    statReturn=stat(name, &fileInfo);
    if ( statReturn != 0 ) {
        type = FileType_NoFile;
    }
    else if ( S_ISREG(fileInfo.st_mode) ) {
        type = FileType_RegularFile;
    }
    else if ( S_ISDIR(fileInfo.st_mode) ) {
        type = FileType_Directory;
    }
    else {
        type = FileType_SpecialFile;
    }
#else
    ModelicaNotExistError("ModelicaInternal_stat");
#endif
    return type;
}

MODELICA_EXPORT void ModelicaInternal_rename(const char* oldName, const char* newName) {
    /* Change the name of a file or of a directory */
    if ( rename(oldName, newName) != 0 ) {
        ModelicaFormatError("renaming \"%s\" to \"%s\" failed:\n%s",
            oldName, newName, strerror(errno));
    }
}

MODELICA_EXPORT void ModelicaInternal_removeFile(const char* file) {
    /* Remove file */
    if ( remove(file) != 0 ) {
        ModelicaFormatError("Not possible to remove file \"%s\":\n%s",
            file, strerror(errno));
    }
}

MODELICA_EXPORT void ModelicaInternal_copyFile(const char* oldFile, const char* newFile) {
    /* Copy file */
#ifdef _WIN32
    const char* modeOld = "rb";
    const char* modeNew = "wb";
#else
    const char* modeOld = "r";
    const char* modeNew = "w";
#endif
    FILE* fpOld;
    FILE* fpNew;
    ModelicaFileType type;
    int c;

    /* Check file existence */
    type = (ModelicaFileType) ModelicaInternal_stat(oldFile);
    if ( type == FileType_NoFile ) {
        ModelicaFormatError("\"%s\" cannot be copied\nbecause it does not exist", oldFile);
        return;
    }
    else if ( type == FileType_Directory ) {
        ModelicaFormatError("\"%s\" cannot be copied\nbecause it is a directory", oldFile);
        return;
    }
    else if ( type == FileType_SpecialFile ) {
        ModelicaFormatError("\"%s\" cannot be copied\n"
            "because it is not a regular file", oldFile);
        return;
    }
    type = (ModelicaFileType) ModelicaInternal_stat(newFile);
    if ( type != FileType_NoFile ) {
        ModelicaFormatError("\"%s\" cannot be copied\nbecause the target "
            "\"%s\" exists", oldFile, newFile);
        return;
    }

    /* Copy file */
    fpOld = fopen(oldFile, modeOld);
    if ( fpOld == NULL ) {
        ModelicaFormatError("\"%s\" cannot be copied:\n%s", oldFile, strerror(errno));
        return;
    }
    fpNew = fopen(newFile, modeNew);
    if ( fpNew == NULL ) {
        fclose(fpOld);
        ModelicaFormatError("\"%s\" cannot be copied to \"%s\":\n%s",
            oldFile, newFile, strerror(errno));
        return;
    }
    while ( (c = getc(fpOld)) != EOF ) {
        putc(c, fpNew);
    }
    fclose(fpOld);
    fclose(fpNew);
}

MODELICA_EXPORT void ModelicaInternal_readDirectory(const char* directory, int nFiles,
                                           const char** files) {
    /* Get all file and directory names in a directory in any order
       (must be very careful, to call closedir if an error occurs)
    */
#if defined(__WATCOMC__) || defined(__BORLANDC__) || defined(_WIN32) || defined(_POSIX_) || defined(__GNUC__)
    int errnoTemp;
    int iFiles  = 0;
    char *pName;
    struct dirent *pinfo;
    DIR* pdir;

    /* Open directory information inquiry */
    pdir = opendir(directory);
    if ( pdir == NULL ) {
        ModelicaFormatError("1: Not possible to get file names of \"%s\":\n%s",
            directory, strerror(errno));
    }

    /* Read file and directory names and store them in vector "files" */
    errno = 0;
    while ( (pinfo = readdir(pdir)) != NULL ) {
        if ( (strcmp(pinfo->d_name, "." ) != 0) &&
            (strcmp(pinfo->d_name, "..") != 0) ) {
            /* Check if enough space in "files" vector */
            if ( iFiles >= nFiles ) {
                closedir(pdir);
                ModelicaFormatError("Not possible to get file names of \"%s\":\n"
                    "More files in this directory as reported by nFiles (= %i)",
                    directory, nFiles);
            }

            /* Allocate Modelica memory for file/directory name and copy name */
            pName = ModelicaAllocateStringWithErrorReturn(strlen(pinfo->d_name));
            if ( pName == NULL ) {
                errnoTemp = errno;
                closedir(pdir);
                if ( errnoTemp == 0 ) {
                    ModelicaFormatError("Not possible to get file names of \"%s\":\n"
                        "Not enough storage", directory);
                }
                else {
                    ModelicaFormatError("Not possible to get file names of \"%s\":\n%s",
                        directory, strerror(errnoTemp));
                }
            }
            strcpy(pName, pinfo->d_name);

            /* Save pointer to file */
            files[iFiles] = pName;
            iFiles++;
        }
    }

    if ( errno != 0 ) {
        errnoTemp = errno;
        closedir(pdir);
        ModelicaFormatError("Not possible to get file names of \"%s\":\n%s",
            directory, strerror(errnoTemp));
    }

    /* Check, whether the whole "files" vector is filled and close inquiry */
    if ( iFiles != nFiles) {
        closedir(pdir);
        ModelicaFormatError("Not possible to get file names of \"%s\":\n"
            "Less files (= %d) found as defined by argument nNames (= %d)",
             directory, iFiles, nFiles);
    }

    if ( closedir(pdir) != 0 ) {
        ModelicaFormatError("Not possible to get file names of \"%s\":\n",
            directory, strerror(errno));
    }

#else
    ModelicaNotExistError("ModelicaInternal_readDirectory");
#endif
}

MODELICA_EXPORT int ModelicaInternal_getNumberOfFiles(const char* directory) {
    /* Get number of files and directories in a directory */
#if defined(__WATCOMC__) || defined(__BORLANDC__) || defined(_WIN32) || defined(_POSIX_) || defined(__GNUC__)
    int nFiles = 0;
    int errnoTemp;
    struct dirent *pinfo;
    DIR* pdir;

    pdir = opendir(directory);
    if ( pdir == NULL ) {
        goto Modelica_ERROR;
    }
    errno = 0;
    while ( (pinfo = readdir(pdir)) != NULL ) {
        if ( (strcmp(pinfo->d_name, "." ) != 0) &&
                (strcmp(pinfo->d_name, "..") != 0) ) {
            nFiles++;
        }
    }
    errnoTemp = errno;
    closedir(pdir);
    if ( errnoTemp != 0 ) {
        errno = errnoTemp;
        goto Modelica_ERROR;
    }

    return nFiles;

Modelica_ERROR:
    ModelicaFormatError("Not possible to get number of files in \"%s\":\n%s",
        directory, strerror(errno));
    return 0;
#else
    ModelicaNotExistError("ModelicaInternal_getNumberOfFiles");
    return 0;
#endif
}

/* --------------------- Modelica_Utilities.Files ------------------------------------- */

MODELICA_EXPORT const char* ModelicaInternal_fullPathName(const char* name) {
    /* Get full path name of file or directory */

#if defined(_WIN32) || (_BSD_SOURCE || _XOPEN_SOURCE >= 500 || _XOPEN_SOURCE && _XOPEN_SOURCE_EXTENDED || (_POSIX_VERSION >= 200112L))
    char* fullName;
    char localbuf[BUFFER_LENGTH];
#if (_BSD_SOURCE || _XOPEN_SOURCE >= 500 || _XOPEN_SOURCE && _XOPEN_SOURCE_EXTENDED || _POSIX_VERSION >= 200112L)
    /* realpath availability: 4.4BSD, POSIX.1-2001. Using the behaviour of NULL: POSIX.1-2008 */
    char* tempName = realpath(name, localbuf);
#else
    char* tempName = _fullpath(localbuf, name, sizeof(localbuf));
#endif
    if (tempName == NULL) {
        ModelicaFormatError("Not possible to construct full path name of \"%s\"\n%s",
            name, strerror(errno));
        return "";
    }
    fullName = ModelicaAllocateString(strlen(tempName));
    strcpy(fullName, tempName);
    ModelicaConvertToUnixDirectorySeparator(fullName);
#elif defined(_POSIX_)
    char* fullName;
    char localbuf[BUFFER_LENGTH];
    /* No such system call in _POSIX_ available (except realpath above) */
    char* cwd = getcwd(localbuf, sizeof(localbuf));
    if (cwd == NULL) {
        ModelicaFormatError("Not possible to get current working directory:\n%s",
            strerror(errno));
    }
    fullName = ModelicaAllocateString(strlen(cwd) + strlen(name) + 1);
    if (name[0] != '/') {
        /* Any name beginning with "/" is regarded as already being a full path. */
        strcpy(fullName, cwd);
        strcat(fullName, "/");
    }
    strcat(fullName, name);
#else
    char* fullName = "";
    ModelicaNotExistError("ModelicaInternal_fullPathName");
#endif

    return fullName;
}

MODELICA_EXPORT const char* ModelicaInternal_temporaryFileName(void) {
    /* Get full path name of a temporary */
    char* fullName;

    char* tempName = tmpnam(NULL);
    if (tempName == NULL) {
        ModelicaFormatError("Not possible to get temporary filename\n%s", strerror(errno));
        return "";
    }
    fullName = ModelicaAllocateString(strlen(tempName));
    strcpy(fullName, tempName);
    ModelicaConvertToUnixDirectorySeparator(fullName);

    return fullName;
}

/* --------------------- Abstract data type for stream handles --------------------- */

/* Improved for caching of the open files */
typedef struct FileCache {
    char* fileName; /* Key = File name */
    FILE* fp /* File pointer */;
    int line;
    UT_hash_handle hh; /* Hashable structure */
} FileCache;

static FileCache* fileCache = NULL;
#if defined(_POSIX_)
#include <pthread.h>
#if defined(G_HAS_CONSTRUCTORS)
static pthread_mutex_t m;
G_DEFINE_CONSTRUCTOR(initializeMutex)
static void initializeMutex(void) {
    if (pthread_mutex_init(&m, NULL) != 0) {
        ModelicaError("Initialization of mutex failed\n");
    }
}
G_DEFINE_DESTRUCTOR(destroyMutex)
static void destroyMutex(void) {
    if (pthread_mutex_destroy(&m) != 0) {
        ModelicaError("Destruction of mutex failed\n");
    }
}
#else
static pthread_mutex_t m = PTHREAD_MUTEX_INITIALIZER;
#endif
#define MUTEX_LOCK() pthread_mutex_lock(&m)
#define MUTEX_UNLOCK() pthread_mutex_unlock(&m)
#elif defined(_WIN32) && defined(G_HAS_CONSTRUCTORS)
#if !defined(WIN32_LEAN_AND_MEAN)
#define WIN32_LEAN_AND_MEAN
#endif
#include <Windows.h>
static CRITICAL_SECTION cs;
#ifdef G_DEFINE_CONSTRUCTOR_NEEDS_PRAGMA
#pragma G_DEFINE_CONSTRUCTOR_PRAGMA_ARGS(initializeCS)
#endif
G_DEFINE_CONSTRUCTOR(initializeCS)
static void initializeCS(void) {
    InitializeCriticalSection(&cs);
}
#ifdef G_DEFINE_DESTRUCTOR_NEEDS_PRAGMA
#pragma G_DEFINE_DESTRUCTOR_PRAGMA_ARGS(deleteCS)
#endif
G_DEFINE_DESTRUCTOR(deleteCS)
static void deleteCS(void) {
    DeleteCriticalSection(&cs);
}
#define MUTEX_LOCK() EnterCriticalSection(&cs)
#define MUTEX_UNLOCK() LeaveCriticalSection(&cs)
#else
#define MUTEX_LOCK()
#define MUTEX_UNLOCK()
#endif

static void CacheFileForReading(FILE* fp, const char* fileName, int line) {
    FileCache* fv;
    if (fileName == 0) {
        /* Do not add, close file */
        if (fp) {
            fclose(fp);
        }
        return;
    }
    MUTEX_LOCK();
    HASH_FIND(hh, fileCache, fileName, (unsigned)strlen(fileName), fv);
    if (fv) {
        fv->fp = fp;
        fv->line = line;
    }
    else {
        fv = (FileCache*)malloc(sizeof(FileCache));
        if (fv) {
            char* key = (char*)malloc((strlen(fileName) + 1)*sizeof(char));
            if (key) {
                strcpy(key, fileName);
                fv->fileName = key;
                fv->fp = fp;
                fv->line = line;
                HASH_ADD_KEYPTR(hh, fileCache, key, (unsigned)strlen(key), fv);
            }
        }
    }
    MUTEX_UNLOCK();
}

static void CloseCachedFile(const char* fileName) {
    FileCache* fv;
    MUTEX_LOCK();
    HASH_FIND(hh, fileCache, fileName, (unsigned)strlen(fileName), fv);
    if (fv) {
        if (fv->fp) {
            fclose(fv->fp);
        }
        free(fv->fileName);
        HASH_DEL(fileCache, fv);
        free(fv);
    }
    MUTEX_UNLOCK();
}

static FILE* ModelicaStreams_openFileForReading(const char* fileName, int line) {
    /* Open text file for reading */
    FILE* fp;
    int c = 1;
    FileCache* fv;
    MUTEX_LOCK();
    HASH_FIND(hh, fileCache, fileName, (unsigned)strlen(fileName), fv);
    /* Open file */
    if (fv && fv->fp && line != 0 && line >= fv->line) {
        /* Cached value */
        line -= fv->line;
        fp = fv->fp;
        fv->fp = 0;
        MUTEX_UNLOCK();
    }
    else {
        MUTEX_UNLOCK();
        fp = fopen(fileName, "r");
        if ( fp == NULL ) {
            ModelicaFormatError("Not possible to open file \"%s\" for reading:\n"
                "%s\n", fileName, strerror(errno));
        }
    }
    while ( line != 0 && c != EOF ) {
        c = fgetc(fp);
        while ( c != '\n' && c != EOF ) {
            c = fgetc(fp);
        }
        line--;
    }
    return fp;
}

MODELICA_EXPORT void ModelicaStreams_closeFile(const char* fileName) {
    /* Close file */
    CloseCachedFile(fileName); /* Closes it */
}

static FILE* ModelicaStreams_openFileForWriting(const char* fileName) {
    /* Open text file for writing (with append) */
    FILE* fp;

    /* Check fileName */
    if ( strlen(fileName) == 0 ) {
        ModelicaError("fileName is an empty string.\n"
            "Opening of file is aborted\n");
    }

    /* Open file */
    ModelicaStreams_closeFile(fileName);
    fp = fopen(fileName, "a");
    if ( fp == NULL ) {
        ModelicaFormatError("Not possible to open file \"%s\" for writing:\n"
            "%s\n", fileName, strerror(errno));
    }
    return fp;
}

/* --------------------- Modelica_Utilities.Streams ----------------------------------- */

MODELICA_EXPORT void ModelicaInternal_print(const char* string, const char* fileName) {
    /* Write string to terminal or to file */
    if ( fileName[0] == '\0' ) {
        /* Write string to terminal */
        ModelicaFormatMessage("%s\n", string);
    }
    else {
        /* Write string to file */
        FILE* fp = ModelicaStreams_openFileForWriting(fileName);
        if ( fputs(string,fp) < 0 ) {
            goto Modelica_ERROR2;
        }
        if ( fputs("\n",fp)   < 0 ) {
            goto Modelica_ERROR2;
        }
        fclose(fp);
        return;

Modelica_ERROR2:
        fclose(fp);
        ModelicaFormatError("Error when writing string to file \"%s\":\n"
            "%s\n", fileName, strerror(errno));
    }
}

MODELICA_EXPORT int ModelicaInternal_countLines(const char* fileName) {
    /* Get number of lines of a file */
    int c;
    int nLines = 0;
    int start_of_line = 1;
    /* If true, next character starts a new line. */

    FILE* fp = ModelicaStreams_openFileForReading(fileName, 0);

    /* Count number of lines */
    while ((c = fgetc(fp)) != EOF) {
        if (start_of_line) {
            nLines++;
            start_of_line = 0;
        }
        if (c == '\n') {
            start_of_line = 1;
        }
    }
    fclose(fp);
    return nLines;
}

MODELICA_EXPORT void ModelicaInternal_readFile(const char* fileName, const char* string[], size_t nLines) {
    /* Read file into string vector string[nLines] */
    FILE* fp = ModelicaStreams_openFileForReading(fileName, 0);
    char* line;
    size_t iLines;
    size_t nc;
    char localbuf[200]; /* To avoid fseek */

    /* Read data from file */
    iLines = 1;
    while ( iLines <= nLines ) {
        /* Determine length of next line */
        long offset = ftell(fp);
        size_t lineLen = 0;
        int c = fgetc(fp);
        int c2 = c;
        while ( c != '\n' && c != EOF ) {
            if (lineLen < sizeof(localbuf)) {
                localbuf[lineLen] = (char)c;
            }
            lineLen++;
            c2 = c;
            c = fgetc(fp);
        }

        if ( lineLen > 0 && c2 == '\r' ) {
            lineLen--;
        }
        /* Allocate storage for next line */
        line = ModelicaAllocateStringWithErrorReturn(lineLen);
        if ( line == NULL ) {
            fclose(fp);
            ModelicaFormatError("Not enough memory to allocate string for reading line %i from file\n"
                "\"%s\".\n"
                "(this file contains %i lines)\n", iLines, fileName, nLines);
        }

        /* Read next line */
        if (lineLen<=sizeof(localbuf)) {
            memcpy(line, localbuf, lineLen);
        }
        else {
            if ( fseek(fp, offset, SEEK_SET != 0) ) {
                fclose(fp);
                ModelicaFormatError("Error when reading line %i from file\n\"%s\":\n"
                    "%s\n", iLines, fileName, strerror(errno));
            }
            nc = ( iLines < nLines ? lineLen+1 : lineLen);
            if ( fread(line, sizeof(char), nc, fp) != nc ) {
                fclose(fp);
                ModelicaFormatError("Error when reading line %i from file\n\"%s\"\n",
                    iLines, fileName);
            }
        }
        line[lineLen] = '\0';
        string[iLines-1] = line;
        iLines++;
    }
    fclose(fp);
}

MODELICA_EXPORT const char* ModelicaInternal_readLine(const char* fileName, int lineNumber, int* endOfFile) {
    /* Read line lineNumber from file fileName */
    FILE* fp = ModelicaStreams_openFileForReading(fileName, lineNumber - 1);
    char* line;
    int c, c2;
    size_t lineLen;
    long offset;
    char localbuf[200]; /* To avoid fseek */

    if (feof(fp)) {
        goto END_OF_FILE;
    }

    /* Determine length of line lineNumber */
    offset  = ftell(fp);
    lineLen = 0;
    c = fgetc(fp);
    c2 = c;
    while ( c != '\n' && c != EOF ) {
        if (lineLen < sizeof(localbuf)) {
            localbuf[lineLen] = (char)c;
        }
        lineLen++;
        c2 = c;
        c = fgetc(fp);
    }
    if ( lineLen == 0 && c == EOF ) {
        goto END_OF_FILE;
    }

    /* Read line lineNumber */
    if ( lineLen > 0 && c2 == '\r') {
        lineLen--;
    }
    line = ModelicaAllocateStringWithErrorReturn(lineLen);
    if ( line == NULL ) {
        goto Modelica_ERROR3;
    }

    if (lineLen <= sizeof(localbuf)) {
        memcpy(line, localbuf, lineLen);
    }
    else {
        if ( fseek(fp, offset, SEEK_SET) != 0 ) {
            goto Modelica_ERROR3;
        }
        if ( fread(line, sizeof(char), lineLen, fp) != lineLen ) {
            goto Modelica_ERROR3;
        }
        fgetc(fp); /* Read the EOF/new-line. */
    }
    CacheFileForReading(fp, fileName, lineNumber);
    line[lineLen] = '\0';
    *endOfFile = 0;
    return line;

    /* End-of-File or error */
END_OF_FILE:
    fclose(fp);
    CloseCachedFile(fileName);
    *endOfFile = 1;
    line = ModelicaAllocateString(0);
    return line;

Modelica_ERROR3:
    fclose(fp);
    CloseCachedFile(fileName);
    ModelicaFormatError("Error when reading line %i from file\n\"%s\":\n%s",
        lineNumber, fileName, strerror(errno));
    return "";
}

/* --------------------- Modelica_Utilities.System ------------------------------------ */

MODELICA_EXPORT void ModelicaInternal_chdir(const char* directoryName) {
    /* Change current working directory */
#if defined(__WATCOMC__) || defined(__LCC__)
    int result = chdir(directoryName);
#elif defined(__BORLANDC__)
    int result = chdir(directoryName);
#elif defined(_WIN32)
    int result = _chdir(directoryName);
#elif defined(_POSIX_) || defined(__GNUC__)
    int result = chdir(directoryName);
#else
    int result = -1;
    ModelicaNotExistError("ModelicaInternal_chdir");
#endif

    if (result != 0) {
        ModelicaFormatError("Not possible to change current working directory to\n"
            "\"%s\":\n%s", directoryName, strerror(errno));
    }
}

MODELICA_EXPORT const char* ModelicaInternal_getcwd(int dummy) {
    const char* cwd;
    char* directory;

#if defined(__WATCOMC__) || defined(__BORLANDC__) || defined(_POSIX_) || defined(__GNUC__)
    char localbuf[BUFFER_LENGTH];
    cwd = getcwd(localbuf, sizeof(localbuf));
#elif defined(_WIN32)
    char localbuf[BUFFER_LENGTH];
    cwd = _getcwd(localbuf, sizeof(localbuf));
#else
    ModelicaNotExistError("ModelicaInternal_getcwd");
    cwd = "";
#endif

    if (cwd == NULL) {
        ModelicaFormatError("Not possible to get current working directory:\n%s",
            strerror(errno));
        cwd = "";
    }

    directory = ModelicaAllocateString(strlen(cwd));
    strcpy(directory, cwd);
    ModelicaConvertToUnixDirectorySeparator(directory);
    return directory;
}

MODELICA_EXPORT void ModelicaInternal_getenv(const char* name, int convertToSlash, const char** content, int* exist) {
    /* Get content of environment variable */
    char* result;
#if defined(_MSC_VER) && _MSC_VER >= 1400
    char* value;
    size_t len = 0;
    errno_t err = _dupenv_s(&value, &len, name);
    if (err) {
        value = NULL;
        ModelicaFormatError("Not possible to get environment variable:\n%s", strerror(err));
    }
#else
    char* value = getenv(name);
#endif

#if defined(_MSC_VER) && _MSC_VER >= 1400
    if (value == NULL && len == 0 && err == 0) {
#else
    if (value == NULL) {
#endif
        result = ModelicaAllocateString(0);
        result[0] = '\0';
        *exist = 0;
    }
    else {
#if defined(_MSC_VER) && _MSC_VER >= 1400
        result = ModelicaAllocateStringWithErrorReturn(len); /* (len - 1) actually is sufficient */
        if (result) {
#else
        result = ModelicaAllocateString(strlen(value));
#endif
            strcpy(result, value);
            if ( convertToSlash == 1 ) {
                ModelicaConvertToUnixDirectorySeparator(result);
            }
            *exist = 1;
#if defined(_MSC_VER) && _MSC_VER >= 1400
            free(value);
        }
        else {
            free(value);
            ModelicaFormatError("Not enough memory to allocate string for copying "
                "environment variable \"%s\".\n", name);
        }
#endif
    }
    *content = result;
}

MODELICA_EXPORT void ModelicaInternal_setenv(const char* name, const char* value, int convertFromSlash) {
#if defined(__WATCOMC__) || defined(__BORLANDC__) || defined(_WIN32) || defined(_POSIX_) || defined(__GNUC__)
    char localbuf[BUFFER_LENGTH];
    if (strlen(name) + strlen(value) + 1 > sizeof(localbuf)) {
        ModelicaFormatError("Environment variable\n"
            "\"%s\"=\"%s\"\n"
            "cannot be set, because the internal buffer\n"
            "in file \"ModelicaInternal.c\" is too small (= %d)",
            name, value, sizeof(localbuf));
    }

    strcpy(localbuf, name);
    strcat(localbuf, "=");
    strcat(localbuf, value);

    if ( convertFromSlash == 1 ) {
        ModelicaConvertFromUnixDirectorySeparator(&localbuf[strlen(name) + 1]);
    }
#endif

    /* Set environment variable */
#if defined(__WATCOMC__) || defined(__BORLANDC__) || defined(_POSIX_) || defined(__GNUC__)
    if (putenv(localbuf) != 0) {
        ModelicaFormatError("Environment variable\n"
            "\"%s\"=\"%s\"\n"
            "cannot be set: %s", name, value, strerror(errno));
    }

#elif defined(_WIN32)
    if (_putenv(localbuf) != 0) {
        ModelicaFormatError("Environment variable\n"
            "\"%s\"=\"%s\"\n"
            "cannot be set: %s", name, value, strerror(errno));
    }
#else
    ModelicaNotExistError("ModelicaInternal_setenv");
#endif
}

#endif

/* Low-level time and pid functions */
/* Some parts from: http://nadeausoftware.com/articles/2012/04/c_c_tip_how_measure_elapsed_real_time_benchmarking */

#if !defined(NO_PID)
  #if defined(__WATCOMC__) || defined(__BORLANDC__) || defined(_WIN32)
    #include <process.h>
  #elif defined(NO_FILE_SYSTEM) && (defined(_POSIX_) || defined(__GNUC__))
    #include <unistd.h>
    #include <sys/types.h>
  #endif
#endif

#if !defined(NO_TIME)
  #include <time.h>
  #if defined(__WATCOMC__) || defined(__BORLANDC__) || defined(_WIN32)
    #include <sys/timeb.h>
  #elif defined(_POSIX_) || defined(__GNUC__)
    #include <sys/time.h>
  #endif
#endif

MODELICA_EXPORT int ModelicaInternal_getpid(void) {
#if defined(NO_PID)
    return 0;
#else
#if defined(_POSIX_) || defined(__GNUC__) || defined(__WATCOMC__) || defined(__BORLANDC__) || defined(__LCC__)
    return getpid();
#else
    return _getpid();
#endif
#endif
}

MODELICA_EXPORT void ModelicaInternal_getTime(int* ms, int* sec, int* min, int* hour, int* mday, int* mon, int* year) {
#if defined(NO_TIME)
    *ms   = 0;
    *sec  = 0;
    *min  = 0;
    *hour = 0;
    *mday = 0;
    *mon  = 0;
    *year = 0;
#else
    struct tm* tlocal;
    time_t calendarTime;
    int ms0;

    time( &calendarTime );               /* Retrieve sec time */
    tlocal = localtime( &calendarTime ); /* Time fields in local time zone */

    /* Get millisecond resolution depending on platform */
#if defined(_WIN32)
    {
#if defined(__BORLANDC__)
        struct timeb timebuffer;
#else
        struct _timeb timebuffer;
#endif
#if defined(__BORLANDC__) || defined(__LCC__)
        ftime( &timebuffer );                     /* Retrieve ms time */
#else
        _ftime( &timebuffer );                    /* Retrieve ms time */
#endif
        ms0 = (int)(timebuffer.millitm);          /* Convert unsigned int to int */
        tlocal->tm_mon  = tlocal->tm_mon + 1;     /* Correct for month starting at 1 */
        tlocal->tm_year = tlocal->tm_year + 1900; /* Correct for 4-digit year */
    }
#else
    {
        struct timeval tv;
        gettimeofday(&tv, NULL);
        ms0 = tv.tv_usec/1000; /* Convert microseconds to milliseconds */
    }
#endif

    /* Do not memcpy as you do not know which sizes are in the struct */
    *ms = ms0;
    *sec = tlocal->tm_sec;
    *min = tlocal->tm_min;
    *hour = tlocal->tm_hour;
    *mday = tlocal->tm_mday;
    *mon = tlocal->tm_mon;
    *year = tlocal->tm_year;
#endif
}
