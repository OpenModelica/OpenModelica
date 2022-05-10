#include <errno.h>
#include <string.h>
#include <sys/stat.h>
#include "../../3rdParty/FMIL/ThirdParty/Minizip/minizip/unzip.h"
#include "util/modelica_string.h"
#include "util/omc_file.h"
#include "errorext.h"
#include "systemimpl.h"

#define dir_delimter '/'
#define MAX_FILENAME 2048
#define READ_SIZE 8192

int om_unzip(const char *zipFileName, const char *pathToExtract, const char *destPath)
{
  unz_file_info file_info;
  char filename[MAX_FILENAME], commonPrefix[MAX_FILENAME];
  unzFile *zipfile = unzOpen(zipFileName);
  if (zipfile == NULL) {
    c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "Failed to open file: %s", &zipFileName, 1);
    return 0;
  }
  unz_global_info global_info;
  if (unzGetGlobalInfo(zipfile, &global_info) != UNZ_OK) {
    c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "minizip failed to read file global info: %s", &zipFileName, 1);
    unzClose(zipfile);
    return 0;
  }
  char read_buffer[READ_SIZE];

  uLong i, j;
  size_t commonLength, pathToExtractLen = strlen(pathToExtract);
  for (i = 0; i < global_info.number_entry; ++i ) {
    if (unzGetCurrentFileInfo(zipfile, &file_info, filename, MAX_FILENAME, NULL, 0, NULL, 0 ) != UNZ_OK) {
      c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "minizip failed to read file info: %s", &zipFileName, 1);
      unzClose(zipfile);
      return 0;
    }
    if (i == 0) {
      commonLength = strlen(filename);
      strcpy(commonPrefix, filename);
    } else {
      for (j = 0; j < commonLength; j++) {
        if (commonPrefix[j] != filename[j]) {
          commonLength = j;
          break;
        }
      }
    }
    if ((i+1) < global_info.number_entry && unzGoToNextFile( zipfile ) != UNZ_OK) {
      const char *msgs[2] = {zipFileName, filename};
      c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "minizip failed to read next file after %s in %s", msgs, 2);
      unzClose(zipfile);
      return 0;
    }
  }
  while (commonLength >= 1 && commonPrefix[commonLength-1] != '/') {
    commonLength--;
  }
  commonPrefix[commonLength] = '\0';
  if (commonLength > 0 && commonLength > pathToExtractLen && (0==strncmp(commonPrefix+commonLength-pathToExtractLen-1, pathToExtract, pathToExtractLen))) {
    commonLength = commonLength-pathToExtractLen-1;
    commonPrefix[commonLength] = '\0';
  }
  if (unzGoToFirstFile(zipfile) != UNZ_OK) {
    c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "minizip failed to reset to first file in %s", &zipFileName, 1);
    unzClose(zipfile);
    return 0;
  }

  // Loop to extract all files
  for (i = 0; i < global_info.number_entry; ++i ) {
    const char *filenameStart = NULL, *renamedPrefix = NULL;
    // Get info about current file.
    if (unzGetCurrentFileInfo(zipfile, &file_info, filename, MAX_FILENAME, NULL, 0, NULL, 0 ) != UNZ_OK ) {
      c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "minizip failed to reset to first file in %s", &zipFileName, 1);
      unzClose(zipfile);
      return 0;
    }
    filenameStart = filename + commonLength;
    const size_t filename_length = strlen(filenameStart);
    if (pathToExtractLen && (strlen(filenameStart) < pathToExtractLen || (filenameStart[pathToExtractLen] != '\0' && filenameStart[pathToExtractLen] != '/') || 0 != strncmp(filenameStart, pathToExtract, pathToExtractLen))) {
      /* Do nothing; not a path we want to copy */
    } else if (filenameStart[ filename_length-1 ] == dir_delimter) {
      /* Directory */
      GC_asprintf(&renamedPrefix, "%s%s%s", destPath, filenameStart[pathToExtractLen] == '/' || filenameStart[pathToExtractLen] == '\0' ? "" : "/", filenameStart+pathToExtractLen);
      SystemImpl__createDirectory(renamedPrefix);
#if defined(_POSIX_C_SOURCE)
      chmod(renamedPrefix, S_IRUSR | S_IWUSR | S_IXUSR | S_IRGRP | S_IROTH | S_IXGRP | S_IXOTH);
#endif
    } else {
      /* File */
      GC_asprintf(&renamedPrefix, "%s%s%s", destPath, filenameStart[pathToExtractLen] == '/' || filenameStart[pathToExtractLen] == '\0' ? "" : "/", filenameStart+pathToExtractLen);
      // Entry is a file, so extract it.
      if (unzOpenCurrentFile(zipfile) != UNZ_OK) {
        const char *msgs[2] = {zipFileName, filename};
        c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "minizip failed to open file %s in %s", &zipFileName, 2);
        unzClose(zipfile);
        return 0;
      }

      FILE *fout = omc_fopen(renamedPrefix, "wb");
      if (fout == NULL) {
        c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "Failed to open file for writing %s", &renamedPrefix, 1);
        unzCloseCurrentFile(zipfile);
        unzClose(zipfile);
        return 0;
      }

      int error = UNZ_OK;
      do {
        error = unzReadCurrentFile(zipfile, read_buffer, READ_SIZE);
        if (error < 0) {
          c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "minizip failed to open read data in %s", &zipFileName, 1);
          unzCloseCurrentFile(zipfile);
          unzClose(zipfile);
          return 0;
        }

        // Write data to file.
        if (error > 0) {
          if (1 != fwrite(read_buffer, error, 1, fout)) {
            const char *msgs[2] = {strerror(errno), renamedPrefix};
            c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "Failed to write data to %s: %s", msgs, 2);
            unzCloseCurrentFile(zipfile);
            unzClose(zipfile);
            return 0;
          }
        }
      } while (error > 0);

#if defined(_POSIX_C_SOURCE)
      /* Set executable flag, etc if we are on a POSIX system
       * external_fa is 4 bytes - the upper 2 are POSIX permissions
       * and the lower of those 2 bytes are the chmod permissions we
       * are interested in (read/write/executable). We filter out the
       * highest octet since we do not need stick/setgid/setuid
       */
      mode_t mode = ((file_info.external_fa >> 16L) & 0x7F) | S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;
      if (fchmod(fileno(fout), mode)) {
        const char *msgs[2] = {strerror(errno), renamedPrefix};
        c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "fchmod failed for %s: %s", msgs, 2);
        unzCloseCurrentFile(zipfile);
        unzClose(zipfile);
        return 0;
      }
#endif
      fclose(fout);
    }

    unzCloseCurrentFile(zipfile);

    /* Next entry */
    if ((i+1) < global_info.number_entry) {
      if (unzGoToNextFile(zipfile) != UNZ_OK) {
        const char *msgs[2] = {zipFileName, filename};
        c_add_message(NULL, -1, ErrorType_runtime,ErrorLevel_error, "minizip failed to read next file after %s in %s", msgs, 2);
        unzClose(zipfile);
        return 0;
      }
    }
  }

  unzClose(zipfile);
  return 1;
}
