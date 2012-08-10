/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>

#include "systemimpl.h"
#include "errorext.h"

/* return codes of the unzip tool */
#define UNZIP_NO_ERROR 0    /* success */
#define UNZIP_WARNINGS 1    /* one or more warning errors, but successfully completed anyway */
#define UNZIP_NOZIP 9       /* no zip files found */
#define UNZIP_METHOD_DECRYPTION_ERROR 81 /* unsupported compression methods or unsupported decryption */
#define UNZIP_WRONG_PASS 82 /* no files were found due to bad decryption password */
/* model description xml file name */
#define FMI_MODEL_DESCRIPTION_XML "modelDescription.xml"
#define FMI_SYSTEM_PATH_DELIMITER "/"

int extractFMU(char *fileName, char *workingDirectory)
{
  int error;
  int n;
  char *cmd;
  n = strlen(fileName) + strlen(workingDirectory) + 16;
  cmd = (char*) malloc(n * sizeof(char));
  sprintf(cmd, "unzip -q -o %s -d %s", fileName, workingDirectory);
  /* -q  quiet mode
   * -o  overwrite files WITHOUT prompting
   * -d  extract files into exdir
   */
  error = system(cmd);
  const char *c_tokens[1]={fileName};
  if (error != UNZIP_NO_ERROR) {
    switch (error) {
      case UNZIP_WARNINGS:
        c_add_message(-1, ErrorType_scripting, ErrorLevel_warning, gettext("some warnings occurred during decompression, success anyway."), NULL, 0);
        break;
      case UNZIP_NOZIP:
        c_add_message(-1, ErrorType_scripting, ErrorLevel_error, gettext("File not Found: %s."), c_tokens, 1);
        return 0;
      case UNZIP_METHOD_DECRYPTION_ERROR:
        c_add_message(-1, ErrorType_scripting, ErrorLevel_error, gettext("unsupported compression methods or unsupported decryption"), NULL, 0);
        return 0;
      case UNZIP_WRONG_PASS:
        c_add_message(-1, ErrorType_scripting, ErrorLevel_error, gettext("No files were found due to bad decryption password."), NULL, 0);
        return 0;
      default:
        c_add_message(-1, ErrorType_scripting, ErrorLevel_error, gettext("Unknown errors occurred during the decompression of file %s"), c_tokens, 1);
        return 0;
    }
  }
  free(cmd);
  return 1;
}

char* getFMIModelDescriptionPath(char* workingDirectory)
{
  char* modelDescriptionPath;
  int len = strlen(workingDirectory) + strlen(FMI_SYSTEM_PATH_DELIMITER) + strlen(FMI_MODEL_DESCRIPTION_XML) + 1;
  modelDescriptionPath = (char*) malloc(len * sizeof(char));
  sprintf(modelDescriptionPath, "%s%s%s", workingDirectory, FMI_SYSTEM_PATH_DELIMITER, FMI_MODEL_DESCRIPTION_XML);
  return modelDescriptionPath;
}

int parseXML(char* modelDescriptionPath)
{
  /* Use FMIL to parse XML.*/
  return 1;
}


int FMIImpl__importFMU(char *fileName, char* workingDirectory)
{
  // check the if the fmu file exists
  if (!SystemImpl__regularFileExists(fileName)) {
    const char *c_tokens[1]={fileName};
    c_add_message(-1, ErrorType_scripting, ErrorLevel_error, gettext("File not Found: %s."), c_tokens, 1);
    return 0;
  }
  // extract the fmu file
  if (!extractFMU(fileName, workingDirectory))
    return 0;
  // get the model description xml file path
  char* modelDescriptionPath = getFMIModelDescriptionPath(workingDirectory);
  // parse XML
  if (!parseXML(modelDescriptionPath))
    return 0;
  return 1;
}

#ifdef __cplusplus
}
#endif

