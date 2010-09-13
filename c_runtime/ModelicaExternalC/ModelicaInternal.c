/* External utility functions for Modelica packages
   Modelica_Utilities.Internal

   The functions are mostly non-portable. The following #define's are used
   to define the system calls of the operating system

    _WIN32        : System calls of Windows'95, Windows'NT
                    (Note, that these system calls allow both '/' and '\'
                    as directory separator for input arguments. As return
                    argument '\' is used).
                    All system calls are from the library libc.a.
    _POSIX_       : System calls of POSIX
    _MSC_VER      : Microsoft Visual C++
    __GNUC__      : GNU C compiler
    NO_FILE_SYSTEM: A file system is not present (e.g. on dSpace or xPC).


    Release Notes:
      Sept. 26, 2004: by Martin Otter, DLR.
        Added missing implementations, merged code from previous ModelicaFiles
        and clean-up of code.

      Sep.  9, 2004: by Dag Bruck, Dynasim AB.
        Further implementation and clean-up of code.

      Aug. 24, 2004: by Martin Otter, DLR.
        Adapted to Dymola 5.3 with minor improvements.

      Jan.  7, 2002: by Martin Otter, DLR.
        First version implemented.
        Only tested for _WIN32, but implemented all
        functions also for _POSIX_, with the exception of
        ModelicaInternal_getFullPath


    Copyright (C) 2002-2006, Modelica Association and DLR.


   The content of this file is free software; it can be redistributed
   and/or modified under the terms of the Modelica License 2, see the
   license conditions and the accompanying disclaimer in file
   Modelica/ModelicaLicense2.html or in Modelica.UsersGuide.ModelicaLicense2.

*/

#if defined(linux)
#define _POSIX_ 1
#endif

#include <string.h>
#include "ModelicaUtilities.h"

static void ModelicaNotExistError(const char* name) {
   /* Print error message if a function is not implemented */
   ModelicaFormatError("C-Function \"%s\" is called\n"
                       "but is not implemented for the actual environment\n"
                       "(e.g., because there is no file system available on the machine\n"
                       "as for dSpace or xPC systems)", name);
}

#if NO_FILE_SYSTEM
  static void ModelicaInternal_mkdir(const char* directoryName) {
              ModelicaNotExistError("ModelicaInternal_mkdir"); }
  static void ModelicaInternal_rmdir(const char* directoryName) {
              ModelicaNotExistError("ModelicaInternal_rmdir"); }
  static int  ModelicaInternal_stat(const char* name) {
              ModelicaNotExistError("ModelicaInternal_stat"); return 0; }
  static void ModelicaInternal_rename(const char* oldName, const char* newName)  {
              ModelicaNotExistError("ModelicaInternal_rename"); }
  static void ModelicaInternal_removeFile(const char* file) {
              ModelicaNotExistError("ModelicaInternal_removeFile"); }
  static void ModelicaInternal_copyFile(const char* oldFile, const char* newFile) {
              ModelicaNotExistError("ModelicaInternal_copyFile"); }
  static void ModelicaInternal_readDirectory(const char* directory, int nFiles, const char* files[]) {
              ModelicaNotExistError("ModelicaInternal_readDirectory"); }
  static int  ModelicaInternal_getNumberOfFiles(const char* directory) {
              ModelicaNotExistError("ModelicaInternal_getNumberOfFiles"); return 0; }
  static const char* ModelicaInternal_fullPathName(const char* name) {
              ModelicaNotExistError("ModelicaInternal_fullPathName"); return 0; }
  static const char* ModelicaInternal_temporaryFileName() {
              ModelicaNotExistError("ModelicaInternal_temporaryFileName"); return 0; }
  static void ModelicaInternal_print(const char* string, const char* fileName) {
              ModelicaNotExistError("ModelicaInternal_print"); }
  static int  ModelicaInternal_countLines(const char* fileName) {
              ModelicaNotExistError("ModelicaInternal_countLines"); return 0; }
  static void ModelicaInternal_readFile(const char* fileName, const char* string[], size_t nLines) {
              ModelicaNotExistError("ModelicaInternal_readFile"); }
  static const char* ModelicaInternal_readLine(const char* fileName, int lineNumber, int* endOfFile) {
              ModelicaNotExistError("ModelicaInternal_readLine"); return 0; }
  static void ModelicaInternal_chdir(const char* directoryName) {
              ModelicaNotExistError("ModelicaInternal_chdir"); }
  static const char* ModelicaInternal_getcwd(int dummy) {
              ModelicaNotExistError("ModelicaInternal_getcwd"); return 0; }
  static const char* ModelicaInternal_getenv(const char* name, int convertToSlash, int* exist) {
              ModelicaNotExistError("ModelicaInternal_getenv"); return 0; }
  static void ModelicaInternal_setenv(const char* name, const char* value, int convertFromSlash) {
              ModelicaNotExistError("ModelicaInternal_setenv"); }
#else

#  include <stdio.h>
#  include <stdlib.h>
#  include <errno.h>

#  if defined(__WATCOMC__)
#     include <direct.h>
#     include <sys/types.h>
#     include <sys/stat.h>
#  elif defined(_WIN32)
#     include <direct.h>
#     include <sys/types.h>
#     include <sys/stat.h>

      /* include the opendir/readdir/closedir implementation for _WIN32 */
#     include "win32_dirent.c"
#  elif defined(_POSIX_)
#     include <dirent.h>
#     include <unistd.h>
#     include <sys/types.h>
#     include <sys/stat.h>
#     include <dirent.h>
#  endif

#define BUFFER_LENGTH 1000
static char buffer[BUFFER_LENGTH];  /* Buffer for temporary storage */

typedef enum {
   FileType_NoFile = 1,
   FileType_RegularFile,
   FileType_Directory,
   FileType_SpecialFile   /* pipe, FIFO, device, etc. */
} ModelicaFileType;



/* Convert to Unix directory separators: */
#if defined(_WIN32)
   static void ModelicaConvertToUnixDirectorySeparator(char* string) {
      /* convert to Unix directory separators */
      char* c = string;
      while ( *c ) {
         if ( *c == '\\' )  {*c = '/';}
         c++;
      }
   };

   static void ModelicaConvertFromUnixDirectorySeparator(char* string) {
      /* convert from Unix directory separators */
      char* c = string;
      while ( *c ) {
         if ( *c == '/' )  {*c = '\\';}
         c++;
      }
   };
#else
#  define ModelicaConvertToUnixDirectorySeparator(string) ;
#  define ModelicaConvertFromUnixDirectorySeparator(string) ;
#endif


/* --------------------- Modelica_Utilities.Internal --------------------------------- */

static void ModelicaInternal_mkdir(const char* directoryName)
{
    /* Create directory */

#if defined(_WIN32)
    int result = _mkdir(directoryName);
#elif defined(_POSIX_)
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


static void ModelicaInternal_rmdir(const char* directoryName)
{
#if defined(__WATCOMC__)
    int result = rmdir(directoryName);
#elif defined(_WIN32) && !defined(SimStruct)
    int result = _rmdir(directoryName);
#elif defined(_POSIX_)
    int result = rmdir(directoryName);
#else
    int result = -1;
    ModelicaNotExistError("ModelicaInternal_rmdir");
#endif

    if (result != 0) {
        ModelicaFormatError("Not possible to remove directory\n"
            "\"%s\":\n%s", directoryName, strerror(errno));
    }
}


static int ModelicaInternal_stat(const char* name)
{
    /* Inquire type of file */
    ModelicaFileType type = FileType_NoFile;

#if defined(_WIN32) && defined(_MSC_VER)
    struct _stat fileInfo;
    if ( _stat(name, &fileInfo) != 0 ) {
        type = FileType_NoFile;
    } else if ( fileInfo.st_mode & S_IFREG ) {
        type = FileType_RegularFile;
    } else if ( fileInfo.st_mode & S_IFDIR ) {
        type = FileType_Directory;
    } else {
        type = FileType_SpecialFile;
    }
#elif defined(_POSIX_) || defined(__GNUC__)
    struct stat fileInfo;
    if ( stat(name, &fileInfo) != 0 ) {
        type = FileType_NoFile;
    } else if ( S_ISREG(fileInfo.st_mode) ) {
        type = FileType_RegularFile;
    } else if ( S_ISDIR(fileInfo.st_mode) ) {
        type = FileType_Directory;
    } else {
        type = FileType_SpecialFile;
    }
#else
    ModelicaNotExistError("ModelicaInternal_stat");
#endif
    return type;
}



static void ModelicaInternal_rename(const char* oldName, const char* newName) {
   /* Changes the name of a file or of a directory */

   if ( rename(oldName, newName) != 0 ) {
      ModelicaFormatError("renaming \"%s\" to \"%s\" failed:\n%s",
                    oldName, newName, strerror(errno));
   }
}


static void ModelicaInternal_removeFile(const char* file) {
  /* Remove file. */
  if ( remove(file) != 0 ) {
     ModelicaFormatError("Not possible to remove file \"%s\":\n%s",
                   file, strerror(errno));
  }
}



static void ModelicaInternal_copyFile(const char* oldFile, const char* newFile) {
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
     } else if ( type == FileType_Directory ) {
        ModelicaFormatError("\"%s\" cannot be copied\nbecause it is a directory", oldFile);
        return;
     } else if ( type == FileType_SpecialFile ) {
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
     while ( (c = getc(fpOld)) != EOF ) putc(c, fpNew);
     fclose(fpOld);
     fclose(fpNew);
}


static void ModelicaInternal_readDirectory(const char* directory, int nFiles,
                                           const char** files) {
  /* Get all file and directory names in a directory in any order
     (must be very careful, to call closedir if an error occurs)
  */
  #if defined(_WIN32) || defined(_POSIX_)
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
                } else {
                   ModelicaFormatError("Not possible to get file names of \"%s\":\n%s",
                                 directory, strerror(errnoTemp));
                }
              }
              strcpy(pName, pinfo->d_name);

           /* Save pointer to file */
              files[iFiles] = pName;
              iFiles++;
        };
     };

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
};



static int ModelicaInternal_getNumberOfFiles(const char* directory) {
    /* Get number of files and directories in a directory */

#if defined(_WIN32) || defined(_POSIX_)
    int nFiles = 0;
    int errnoTemp;
    struct dirent *pinfo;
    DIR* pdir;

    pdir = opendir(directory);
    if ( pdir == NULL ) goto ERROR;
    errno = 0;
    while ( (pinfo = readdir(pdir)) != NULL ) {
        if ( (strcmp(pinfo->d_name, "." ) != 0) &&
            (strcmp(pinfo->d_name, "..") != 0) ) {
            nFiles++;
        };
    };
    errnoTemp = errno;
    closedir(pdir);
    if ( errnoTemp != 0 ) {errno = errnoTemp; goto ERROR;}

    return nFiles;

ERROR: ModelicaFormatError("Not possible to get number of files in \"%s\":\n%s",
                           directory, strerror(errno));
       return 0;
#else
       ModelicaNotExistError("ModelicaInternal_getNumberOfFiles");
       return 0;
#endif
};


/* --------------------- Modelica_Utilities.Files ------------------------------------- */

static const char* ModelicaInternal_fullPathName(const char* name)
{
    /* Get full path name of file or directory */

    char* fullName;

#if defined(_WIN32)
    char* tempName = _fullpath(buffer, name, sizeof(buffer));
    if (tempName == NULL) {
        ModelicaFormatError("Not possible to construct full path name of \"%s\"\n%s",
            name, strerror(errno));
        return "";
    }
    fullName = ModelicaAllocateString(strlen(tempName));
    strcpy(fullName, tempName);
    ModelicaConvertToUnixDirectorySeparator(fullName);
#else
    /* No such system call in _POSIX_ available */
    char* cwd = getcwd(buffer, sizeof(buffer));
    if (cwd == NULL) {
        ModelicaFormatError("Not possible to get current working directory:\n%s",
            strerror(errno));
    }
    fullName = ModelicaAllocateString(strlen(cwd) + strlen(name) + 1);
    strcpy(fullName, cwd);
    strcat(fullName, "/");
    strcat(fullName, name);
#endif

    return fullName;
}

static const char* ModelicaInternal_temporaryFileName()
{
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

/* Needs to be improved for cashing of the open files */

static FILE* ModelicaStreams_openFileForReading(const char* fileName) {
   /* Open text file for reading */
      FILE* fp;

   /* Open file */
      fp = fopen(fileName, "r");
      if ( fp == NULL ) {
         ModelicaFormatError("Not possible to open file \"%s\" for reading:\n"
                             "%s\n", fileName, strerror(errno));
      }
      return fp;
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
      fp = fopen(fileName, "a");
      if ( fp == NULL ) {
         ModelicaFormatError("Not possible to open file \"%s\" for writing:\n"
                             "%s\n", fileName, strerror(errno));
      }
      return fp;
}

static void ModelicaStreams_closeFile(const char* fileName) {
   /* close file */
}


/* --------------------- Modelica_Utilities.Streams ----------------------------------- */

static void ModelicaInternal_print(const char* string, const char* fileName) {
  /* Write string to terminal or to file */

     if ( fileName[0] == '\0' ) {
        /* Write string to terminal */
           ModelicaMessage(string);
     } else {
        /* Write string to file */
           FILE* fp = ModelicaStreams_openFileForWriting(fileName);
           if ( fputs(string,fp) < 0 ) goto ERROR;
           if ( fputs("\n",fp)   < 0 ) goto ERROR;
           fclose(fp);
           return;

           ERROR: fclose(fp);
                  ModelicaFormatError("Error when writing string to file \"%s\":\n"
                                      "%s\n", fileName, strerror(errno));
     }
}


static int ModelicaInternal_countLines(const char* fileName)
/* Get number of lines of a file */
{
    int c;
    int nLines = 0;
    int start_of_line = 1;
    /* If true, next character starts a new line. */

    FILE* fp = ModelicaStreams_openFileForReading(fileName);

    /* Count number of lines */
    while ((c = fgetc(fp)) != EOF) {
        if (start_of_line) {
            nLines++;
            start_of_line = 0;
        }
        if (c == '\n') start_of_line = 1;
    }
    fclose(fp);
    return nLines;
}

static void ModelicaInternal_readFile(const char* fileName, const char* string[], size_t nLines) {
  /* Read file into string vector string[nLines] */
     FILE* fp = ModelicaStreams_openFileForReading(fileName);
     char*  line;
     int    c;
     size_t lineLen;
     size_t iLines;
     long   offset;
     size_t nc;

  /* Read data from file */
     iLines = 1;
     while ( iLines <= nLines ) {
        /* Determine length of next line */
           offset  = ftell(fp);
           lineLen = 0;
           c = fgetc(fp);
           while ( c != '\n' && c != EOF ) {
              lineLen++;
              c = fgetc(fp);
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
           if ( fseek(fp, offset, SEEK_SET != 0) ) {
              fclose(fp);
              ModelicaFormatError("Error when reading line %i from file\n\"%s\":\n"
                                  "%s\n", iLines, fileName, strerror(errno));
           };
           nc = ( iLines < nLines ? lineLen+1 : lineLen);
           if ( fread(line, sizeof(char), nc, fp) != nc ) {
              fclose(fp);
              ModelicaFormatError("Error when reading line %i from file\n\"%s\"\n",
                                  iLines, fileName);
           };
           line[lineLen] = '\0';
           string[iLines-1] = line;
           iLines++;
     }
     fclose(fp);
}


static const char* ModelicaInternal_readLine(const char* fileName, int lineNumber, int* endOfFile) {
  /* Read line lineNumber from file fileName */
     FILE* fp = ModelicaStreams_openFileForReading(fileName);
     char*  line;
     int    c;
     size_t lineLen;
     size_t iLines;
     long   offset;

  /* Read upto line lineNumber-1 */
     iLines = 0;
     c = 1;
     while ( iLines != (size_t) lineNumber-1 && c != EOF ) {
        c = fgetc(fp);
        while ( c != '\n' && c != EOF ) {
           c = fgetc(fp);
        }
        iLines++;
     }
     if ( iLines != (size_t) lineNumber-1 ) goto END_OF_FILE;

  /* Determine length of line lineNumber */
     offset  = ftell(fp);
     lineLen = 0;
     c = fgetc(fp);
     while ( c != '\n' && c != EOF ) {
        lineLen++;
        c = fgetc(fp);
     }
     if ( lineLen == 0 && c == EOF ) goto END_OF_FILE;

  /* Read line lineNumber */
     line = ModelicaAllocateStringWithErrorReturn(lineLen);
     if ( line == NULL ) goto ERROR;
     if ( fseek(fp, offset, SEEK_SET != 0) ) goto ERROR;
     if ( fread(line, sizeof(char), lineLen, fp) != lineLen ) goto ERROR;
     fclose(fp);
     line[lineLen] = '\0';
     *endOfFile = 0;
     return line;

  /* End-of-File or error */
     END_OF_FILE: fclose(fp);
                  *endOfFile = 1;
                  line = ModelicaAllocateString(0);
                  return line;

     ERROR      : fclose(fp);
                  ModelicaFormatError("Error when reading line %i from file\n\"%s\":\n%s",
                                      lineNumber, fileName, strerror(errno));
                  return "";
}


/* --------------------- Modelica_Utilities.System ------------------------------------ */

static void ModelicaInternal_chdir(const char* directoryName)
{
/* Change current working directory. */
#if defined(__WATCOMC__)
    int result = chdir(directoryName);
#elif defined(_WIN32) && !defined(SimStruct)
    int result = _chdir(directoryName);
#elif defined(_POSIX_)
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


static const char* ModelicaInternal_getcwd(int dummy)
{
    const char* cwd;
    char* directory;

#if defined(_WIN32)
    cwd = _getcwd(buffer, sizeof(buffer));
#elif defined(_POSIX_)
    cwd = getcwd(buffer, sizeof(buffer));
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


static const char* ModelicaInternal_getenv(const char* name, int convertToSlash, int* exist)
{
    /* Get content of environment variable */
    char* value = getenv(name);
    char* result;

    if (value == NULL) {
        result = ModelicaAllocateString(0);
        result[0] = '\0';
        *exist = 0;
    } else {
        result = ModelicaAllocateString(strlen(value));
        strcpy(result, value);
        if ( convertToSlash == 1 ) ModelicaConvertToUnixDirectorySeparator(result);
        *exist = 1;
    }
    return result;
}


static void ModelicaInternal_setenv(const char* name, const char* value, int convertFromSlash)
{
#if defined(_WIN32) || defined(_POSIX_)
    int valueStart;
    if (strlen(name) + strlen(value) + 1 > sizeof(buffer)) {
        ModelicaFormatError("Environment variable\n"
            "\"%s\"=\"%s\"\n"
            "cannot be set, because the internal buffer\n"
            "in file \"ModelicaInternal.c\" is too small (= %d)",
            name, value, sizeof(buffer));
    }

    strcpy(buffer,name);
    strcat(buffer, "=");
    valueStart = strlen(buffer);
    strcat(buffer, value);

    if ( convertFromSlash == 1 ) ModelicaConvertFromUnixDirectorySeparator(&buffer[valueStart]);
#endif

    /* Set environment variable */
#if defined(_WIN32)
    if (_putenv(buffer) != 0) {
        ModelicaFormatError("Environment variable\n"
            "\"%s\"=\"%s\"\n"
            "cannot be set: %s", name, value, strerror(errno));
    }
#elif defined(_POSIX_)
    if (putenv(buffer) != 0) {
        ModelicaFormatError("Environment variable\n"
            "\"%s\"=\"%s\"\n"
            "cannot be set: %s", name, value, strerror(errno));
    }
#else
    ModelicaNotExistError("ModelicaInternal_setenv");
#endif
}


#endif
