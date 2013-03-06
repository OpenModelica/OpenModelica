/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <float.h>
#include <strings.h> /* strcasecmp */
#include <unistd.h>
#include "moGenerator.h"

/* macro for screen printing */
#define QUOTEME_(x) #x
#define QUOTEME(x) QUOTEME_(x)

/*#define _DEBUG_ 1
 #define PRINT_INFORMATION
 */
/* #define _DEBUG_MODELICA 1*/

/* macro for error message print */
#define _IMPORT_ERROR_LOG_
#define WHERESTR  "[date %s, time %s, file %s, line %d]: "
#define WHEREARG  __DATE__, __TIME__, __FILE__, __LINE__
#define ERRORPRINT       fprintf(errLogFile, WHERESTR, WHEREARG)

/* macro for log message print */
#define _IMPORT_LOG_
#define WHERESTR  "[date %s, time %s, file %s, line %d]: "
#define WHEREARG  __DATE__, __TIME__, __FILE__, __LINE__
#define LOGPRINT2(...)       fprintf(logFile, __VA_ARGS__)
#define LOGPRINT(_fmt, ...)  LOGPRINT2(WHERESTR _fmt, WHEREARG, __VA_ARGS__)

/* handling platform dependency */
#if defined(__MINGW32__) || defined(_MSC_VER)
#include <windows.h>
#define ERROR_ENVVAR_NOT_FOUND           203L
#define getLastErrorSystem GetLastError
#define getEnvVariable GetEnvironmentVariable
#else
#include <errno.h>
#define ERROR_ENVVAR_NOT_FOUND           NULL
#define getLastErrorSystem errno
#define getEnvVariable getenv
#endif

/* macro for some global variables */
#if defined(__MINGW32__) || defined(_MSC_VER)
#define FMU_BINARIES_PATH "binaries/win32/"
#define FMU_BINARIES_END ".dll"
#else
#define FMU_BINARIES_PATH "binaries/linux64/"
#define FMU_BINARIES_END ".so"
#endif
#define BUFFERSIZE 4096
#define PATHSIZE 1024

#define MODEL_DESCRIPTION "modelDescription.xml"
#define FMU_PATH "../fmu"
#define BIN_PATH "../bin"

/* macros for unzip command */
#define USE_UNZIP
/* return codes of the unzip tool */
#define UNZIP_NO_ERROR 0    /* sucess */
#define UNZIP_WARNINGS 1    /* one or more warning errors, but successfully completed anyway */
#define UNZIP_NOZIP 9       /* no zip files found */
#define UNZIP_METHOD_DECRYPTION_ERROR 81 /* unsupported compression methods or unsupported decryption */
#define UNZIP_WRONG_PASS 82 /* no files were found due to bad decryption password */

/* macro for the 7z tool */
#define DECOMPRESS_CMD "7z x -aoa -o"
/* return codes of the 7z tool */
#define SEVEN_ZIP_NO_ERROR 0 /* success */
#define SEVEN_ZIP_WARNING 1  /* e.g., one or more files were locked during zip */
#define SEVEN_ZIP_ERROR 2
#define SEVEN_ZIP_COMMAND_LINE_ERROR 7
#define SEVEN_ZIP_OUT_OF_MEMORY 8
#define SEVEN_ZIP_STOPPED_BY_USER 255

const char* variabilityNames[4] = { "constant", "parameter", "discrete", "" };
const char* causalityNames[4] = { "input", "output", "", "" };
const char* startValueFixed[2] = { "false", "true" };
const char* fmiBooleanValue[2] = { "false", "true" };
FILE* errLogFile;

/*
 * function that returns the name of the FMU from given
 * FMU path, more details see FMI for model exchange 1.0
 */
char* getFMUname(const char* fmupath) {
  char* fmuname;
  int i, counter, tmp;

  counter = strlen(fmupath);

#ifdef _DEBUG_
  printf("#### length of fmupath[1] (%s): %d\n",fmupath,counter);
#endif

  i = counter - 5;
  tmp = i;
  while (fmupath[i] != '/')
    i--;

#ifdef _DEBUG_
  printf("#### Result: fmupath[%d]: %c\n",i,fmupath[i]);
#endif

  fmuname = (char*) calloc(tmp - i + 1, sizeof(char));
  strncpy(fmuname, &fmupath[i + 1], tmp - i);

#ifdef _DEBUG_
  printf("#### fmuname is: %s\n",fmuname);
#endif

  return fmuname;
}

/*
 * functions that returns the dll path from decompression path
 * and model identifier
 */
char* getDllPath(const char* decompPath, const char* mid) {
  char *fmudllpath;

  const int lenStr1 = (strlen(FMU_BINARIES_PATH) + 1) + (strlen(decompPath) + 1)
      + (strlen(mid) + 1) + 4;
  fmudllpath = (char*) calloc(lenStr1, sizeof(char));
  sprintf(fmudllpath, "%s%s%s%s", decompPath, FMU_BINARIES_PATH, mid,
      FMU_BINARIES_END);
  /*
   * What's done here?
   #if 0
   fprintf(stderr, "fmudllpath=%s\n", fmudllpath);

   pch = strtok(fmudllpath,"/");
   while(pch!=NULL){
   lenStr2 += strlen(pch);
   strcount++;
   pch = strtok(NULL,"/");
   }
   ret_fmudllpath = (char*)calloc(lenStr2+(strcount-1)*2, sizeof(char));
   pch = strtok(tmpStr,"/");

   for(i=1;i<strcount;i++){
   strcat(ret_fmudllpath,pch);
   strcat(ret_fmudllpath,"/");
   pch = strtok(NULL,"/");
   #ifdef _DEBUG_
   printf("#### ret_fmudllpath = %s\n",ret_fmudllpath);
   #endif
   }
   strcat(ret_fmudllpath,pch);

   #ifdef _DEBUG_
   printf("#### ret_fmudllpath = %s\n",ret_fmudllpath);
   printf("#### strlen(ret_fmudllpath) = %d\n",strlen(ret_fmudllpath));
   #endif
   #endif
   */

  return fmudllpath;
}

/* function that returns the name of the model description xml file */
static char* getNameXMLfile(const char * decompPath, const char * modeldes) {
  char * xmlfile;
#ifdef _DEBUG_
  printf("####  start xmlfile size of path length= %d.\n",strlen(decompPath)+strlen(modeldes)+1);
#endif
  xmlfile = (char*) calloc(strlen(decompPath) + strlen(modeldes) + 10,
      sizeof(char));
#ifdef _DEBUG_
  printf("####  xmlfile: %s\n",xmlfile);
#endif
  strncpy(xmlfile, decompPath, strlen(decompPath) + 1);
#ifdef _DEBUG_
  printf("####  xmlfile: %s\n",xmlfile);
#endif
  strcat(xmlfile, modeldes);
#ifdef _DEBUG_
  printf("####  xmlfile: %s\n",xmlfile);
#endif
  return xmlfile;
}

/* function that decompresses the given FMU archive either via OMDev
 * inherent unzip command or attached 7z tool
 */
static int decompress(const char* fmuPath, const char* decompPath) {
  int err;
  int n;
  char * cmd; /* needed to be free*/

#ifdef USE_UNZIP
  n = (strlen(fmuPath) + 1) + (strlen(decompPath) + 1) + 20;
  cmd = (char*) calloc(n, sizeof(char));
  sprintf(cmd, "unzip -q -o %s -d %s", fmuPath, decompPath);
  err = system(cmd);
  if (err != UNZIP_NO_ERROR) {
    switch (err) {
    case UNZIP_WARNINGS:
      printf(
          "some warnings occurred during decompression, success anyway...\n");
      break;
    case UNZIP_NOZIP:
      printf("no zip files found...\n");
      break;
    case UNZIP_METHOD_DECRYPTION_ERROR:
      printf("unsupported compression methods or unsupported decryption...\n");
      break;
    case UNZIP_WRONG_PASS:
      printf(" no files were found due to bad decryption password...\n");
      break;
    default:
      printf(" unknown errors..\n");
      break;
    }
  }

#else
  n = (strlen(DECOMPRESS_CMD)+1) + (strlen(fmuPath)+1) + (strlen(decompPath)+1) + 10;
  cmd = (char*)calloc(n, sizeof(char));
  sprintf(cmd, "%s%s \"%s\" > NUL", DECOMPRESS_CMD, decompPath, fmuPath);
  err = system(cmd);

  if (err!=SEVEN_ZIP_NO_ERROR) {
    switch (err) {
      ERRORPRINT; fprintf(errLogFile,"#### 7z: %s","");
      case SEVEN_ZIP_WARNING: printf("warning\n"); break;
      case SEVEN_ZIP_ERROR: printf("error\n"); break;
      case SEVEN_ZIP_COMMAND_LINE_ERROR: printf("command line error\n"); break;
      case SEVEN_ZIP_OUT_OF_MEMORY: printf("out of memory\n"); break;
      case SEVEN_ZIP_STOPPED_BY_USER: printf("stopped by user\n"); break;
      default: ERRORPRINT; fprintf(errLogFile,"#### Unknown problem %s\n","");
    }
  }
#endif
  free(cmd);
  return EXIT_SUCCESS;
}

/*
 * function that returns the number of scalar variables contained in
 * the ModelVariables entity, return -1 for error
 */
static int getNumberOfSV(ModelDescription* md) {
  int i;
  if (md->modelVariables) {
    for (i = 0; md->modelVariables[i]; i++)
      ;
    return i;
  } else
    return -1;
}

/*
 * function that gets the element type from a ScalarVariable defined
 * in xmlparser.h
 */
fmiScalarVariableType getElementType(ScalarVariable* sv) {
  Elm elm;
  fmiScalarVariableType sv_type;
  elm = sv->typeSpec->type;
  switch (elm) {
  case elm_Real:
    sv_type = sv_real;
    return sv_type;
  case elm_Integer:
    sv_type = sv_integer;
    return sv_type;
  case elm_Boolean:
    sv_type = sv_boolean;
    return sv_type;
  case elm_String:
    sv_type = sv_string;
    return sv_type;
  case elm_Enumeration:
    sv_type = sv_enum;
    return sv_type;
  default:
    ERRORPRINT;
    fprintf(errLogFile, "#### Unknown element type in ScalarVaraible %s...\n",
        "");
    exit(EXIT_FAILURE);
  }
}

/*
 * function that allocates memory for element contained in scalar variables
 */
void* allocateElmSV(fmiScalarVariable fmisv) {
  switch (fmisv.type) {
  case sv_real:
    return calloc(1, sizeof(fmiREAL));
  case sv_integer:
    return calloc(1, sizeof(fmiINTEGER));
  case sv_boolean:
    return calloc(1, sizeof(fmiBOOLEAN));
  case sv_string:
    return calloc(1, sizeof(fmiSTRING));
  case sv_enum:
    return calloc(1, sizeof(fmiENUM));
  default:
    ERRORPRINT;
    fprintf(
        errLogFile,
        "#### Unknown element type in allocateElmSV() for fmiScalarVariable: %s ...\n",
        fmisv.name);
    exit(EXIT_FAILURE);
  }
}

/*
 * function that  instantiates the element in scalar variable,
 * e.g. Real, Integer, ect..
 */
void instElmSV(ScalarVariable* sv, fmiScalarVariable fmisv) {
  ValueStatus vs;
  double tmp_db;
  int tmp_i;
  const char *tmp_str;
  fmiBooleanXML tmp_bl;

  switch (fmisv.type) {
  case sv_real: {
    tmp_str = getString(sv->typeSpec, att_declaredType);
    ((fmiREAL *) fmisv.variable)->declType = (tmp_str != NULL ? tmp_str : "");

    tmp_str = getString(sv->typeSpec, att_quantity);
    ((fmiREAL *) fmisv.variable)->quantity = (tmp_str != NULL ? tmp_str : "");

    tmp_str = getString(sv->typeSpec, att_unit);
    ((fmiREAL *) fmisv.variable)->unit = (tmp_str != NULL ? tmp_str : "");

    tmp_str = getString(sv->typeSpec, att_displayUnit);
    ((fmiREAL *) fmisv.variable)->displayUnit = (
        tmp_str != NULL ? tmp_str : "");

    tmp_bl = getBoolean(sv->typeSpec, att_relativeQuantity, &vs);
    ((fmiREAL *) fmisv.variable)->relQuantity = (
        vs == valueDefined ? tmp_bl : 0);

    tmp_db = getDouble(sv->typeSpec, att_min, &vs);
    if (vs == valueDefined) {
      ((fmiREAL *) fmisv.variable)->min = tmp_db;
      ((fmiREAL *) fmisv.variable)->defMin = 1;
    } else
      ((fmiREAL *) fmisv.variable)->defMin = 0;

    tmp_db = getDouble(sv->typeSpec, att_max, &vs);
    if (vs == valueDefined) {
      ((fmiREAL *) fmisv.variable)->max = tmp_db;
      ((fmiREAL *) fmisv.variable)->defMax = 1;
    } else
      ((fmiREAL *) fmisv.variable)->defMax = 0;

    tmp_db = getDouble(sv->typeSpec, att_nominal, &vs);
    if (vs == valueDefined) {
      ((fmiREAL *) fmisv.variable)->nominal = tmp_db;
      ((fmiREAL *) fmisv.variable)->defNorminal = 1;
    } else
      ((fmiREAL *) fmisv.variable)->defNorminal = 0;

    tmp_db = getDouble(sv->typeSpec, att_start, &vs);
    if (vs == valueDefined) {
      ((fmiREAL *) fmisv.variable)->start = tmp_db;
      ((fmiREAL *) fmisv.variable)->defStart = 1;
    } else
      ((fmiREAL *) fmisv.variable)->defStart = 0;

    tmp_bl = getBoolean(sv->typeSpec, att_fixed, &vs);
    ((fmiREAL*) fmisv.variable)->fixed = (vs == valueDefined ? tmp_bl : 0);

    break;
  }
  case sv_integer: {
    tmp_str = getString(sv->typeSpec, att_declaredType);
    ((fmiINTEGER *) fmisv.variable)->declType = (
        tmp_str != NULL ? tmp_str : "");

    tmp_str = getString(sv->typeSpec, att_quantity);
    ((fmiINTEGER *) fmisv.variable)->quantity = (
        tmp_str != NULL ? tmp_str : "");

    tmp_i = getInt(sv->typeSpec, att_min, &vs);
    if (vs == valueDefined) {
      ((fmiINTEGER *) fmisv.variable)->min = tmp_i;
      ((fmiINTEGER *) fmisv.variable)->defMin = 1;
    } else
      ((fmiINTEGER *) fmisv.variable)->defMin = 0;

    tmp_i = getInt(sv->typeSpec, att_max, &vs);
    if (vs == valueDefined) {
      ((fmiINTEGER *) fmisv.variable)->max = tmp_i;
      ((fmiINTEGER *) fmisv.variable)->defMax = 1;
    } else
      ((fmiINTEGER *) fmisv.variable)->defMax = 0;

    tmp_i = getInt(sv->typeSpec, att_start, &vs);

    if (vs == valueDefined) {
      ((fmiINTEGER *) fmisv.variable)->start = tmp_i;
      ((fmiINTEGER *) fmisv.variable)->defStart = 1;
    } else if (vs == valueMissing)
      ((fmiINTEGER *) fmisv.variable)->defStart = 0;
    else {
      printf("[%d]: #### Integer variable %s: start value illegal ...\n",
          __LINE__, fmisv.name);
      exit(EXIT_FAILURE);
    }
    tmp_bl = getBoolean(sv->typeSpec, att_fixed, &vs);
    ((fmiINTEGER*) fmisv.variable)->fixed = (vs == valueDefined ? tmp_bl : 0);

    break;
  }
  case sv_boolean: {
    tmp_str = getString(sv->typeSpec, att_declaredType);
    ((fmiBOOLEAN *) fmisv.variable)->declType = (
        tmp_str != NULL ? tmp_str : "");

    tmp_bl = getBoolean(sv->typeSpec, att_start, &vs);
    if (vs == valueDefined) {
      ((fmiBOOLEAN *) fmisv.variable)->start = tmp_bl;
      ((fmiBOOLEAN *) fmisv.variable)->defStart = 1;
    } else if (vs == valueMissing)
      ((fmiBOOLEAN *) fmisv.variable)->defStart = 0;
    else {
      printf("[%d]: #### Boolean variable %s: start value illegal ...\n",
          __LINE__, fmisv.name);
      exit(EXIT_FAILURE);
    }
    tmp_bl = getBoolean(sv->typeSpec, att_fixed, &vs);
    ((fmiBOOLEAN *) fmisv.variable)->fixed = (vs == valueDefined ? tmp_bl : 0);

    tmp_bl = getBoolean(sv->typeSpec, att_fixed, &vs);
    ((fmiBOOLEAN*) fmisv.variable)->fixed = (vs == valueDefined ? tmp_bl : 0);
    break;
  }
  case sv_string: {
    ((fmiSTRING*) fmisv.variable)->start = getString(sv->typeSpec, att_start);
    tmp_str = getString(sv->typeSpec, att_declaredType);
    ((fmiSTRING *) fmisv.variable)->declType = (tmp_str != NULL ? tmp_str : "");

    tmp_str = getString(sv->typeSpec, att_start);
    if (tmp_str) {
      ((fmiSTRING *) fmisv.variable)->start = tmp_str;
      ((fmiSTRING *) fmisv.variable)->defStart = 1;
    } else {
      ((fmiSTRING *) fmisv.variable)->start = "";
      ((fmiSTRING *) fmisv.variable)->defStart = 0;
    }

    tmp_bl = getBoolean(sv->typeSpec, att_fixed, &vs);
    ((fmiSTRING*) fmisv.variable)->fixed = (vs == valueDefined ? tmp_bl : 0);
    break;
  }
  case sv_enum: {
    tmp_str = getString(sv->typeSpec, att_declaredType);
    ((fmiENUM *) fmisv.variable)->declType = (tmp_str != NULL ? tmp_str : "");

    tmp_str = getString(sv->typeSpec, att_quantity);
    ((fmiENUM *) fmisv.variable)->quantity = (tmp_str != NULL ? tmp_str : "");

    tmp_i = getInt(sv->typeSpec, att_min, &vs);
    if (vs == valueDefined) {
      ((fmiENUM *) fmisv.variable)->min = tmp_i;
      ((fmiENUM *) fmisv.variable)->defMin = 1;
    } else
      ((fmiENUM *) fmisv.variable)->defMin = 0;

    tmp_i = getInt(sv->typeSpec, att_max, &vs);
    if (vs == valueDefined) {
      ((fmiENUM *) fmisv.variable)->max = tmp_i;
      ((fmiENUM *) fmisv.variable)->defMax = 1;
    } else
      ((fmiENUM *) fmisv.variable)->defMax = 0;

    tmp_i = getInt(sv->typeSpec, att_start, &vs);
    if (vs == valueDefined) {
      ((fmiENUM *) fmisv.variable)->start = tmp_i;
      ((fmiENUM *) fmisv.variable)->defStart = 1;
    } else
      ((fmiENUM *) fmisv.variable)->defStart = 0;

    break;
  }

  default:
    ERRORPRINT;
    fprintf(errLogFile,
        "#### Unknown error in instElmSV() for fmiScalarVariable: %s...\n",
        fmisv.name);
    exit(EXIT_FAILURE);
  }
}

/*
 * functions that replaces the given character old with the character new in a string
 */
void charReplace(char* flatName, unsigned int len, char old, char new) {
  char* pntCh = NULL;

  pntCh = strchr(flatName, old);
  while (pntCh != NULL) {
    *pntCh = new;
    pntCh = strchr(flatName, old);
  }
  flatName[len] = '\0';
}

// function that returns the fmiVariability defined in moGenerator.h
fmiVariability getFMIVariability(ScalarVariable* sv) {
  fmiVariability ret;
  Enu fmi_var;

  fmi_var = getVariability(sv);
  // var cases: enu_constant,enu_parameter,enu_discrete,enu_continuous
  switch (fmi_var) {
  case enu_constant:
    ret = constant;
    break;
  case enu_parameter:
    ret = parameter;
    break;
  case enu_discrete:
    ret = discrete;
    break;
  case enu_continuous:
    ret = continuous;
    break;

  default:
    ERRORPRINT;
    fprintf(
        stderr,
        "#### Unknown error in getFMIVariability() for fmiScalarVariable: %s...\n",
        getString(sv, att_name));
    exit(EXIT_FAILURE);
  }
  return ret;
}

// function that returns the fmiCausality defined in moGenerator.h
fmiCausality getFMICausality(ScalarVariable* sv) {
  fmiCausality ret;
  Enu fmi_cau;

  fmi_cau = getCausality(sv);
  // fmi_cau cases: enu_input,enu_output,enu_internal,enu_none
  switch (fmi_cau) {
  case enu_input:
    ret = input;
    break;
  case enu_output:
    ret = output;
    break;
  case enu_internal:
    ret = internal;
    break;
  case enu_none:
    ret = none;
    break;

  default:
    ERRORPRINT;
    fprintf(
        stderr,
        "#### Unknown error in getFMICausality() for fmiScalarVariable: %s...\n",
        getString(sv, att_name));
    exit(EXIT_FAILURE);
  }
  return ret;
}

// function that returns the fmiAlias defined in moGenerator.h
fmiAlias getFMIAlias(ScalarVariable* sv) {
  fmiAlias ret;
  Enu fmi_als;

  fmi_als = getAlias(sv);
  // fmi_als cases: enu_noAlias,enu_alias,enu_negatedAlias
  switch (fmi_als) {
  case enu_noAlias:
    ret = noalias;
    break;
  case enu_alias:
    ret = alias;
    break;
  case enu_negatedAlias:
    ret = negatedAlias;
    break;

  default:
    ERRORPRINT;
    fprintf(stderr,
        "#### Unknown error in getFMIAlias() for fmiScalarVariable: %s...\n",
        getString(sv, att_name));
    exit(EXIT_FAILURE);
  }
  return ret;
}

/*
 * function that instantiates the fmiScalarVariable list
 */
void instScalarVariable(ModelDescription* md, fmiScalarVariable* list) {
  int i;
  unsigned int len;
  char* tempDesc;
  if (md->modelVariables) {
    for (i = 0; md->modelVariables[i]; i++) {
      list[i].name = getName(md->modelVariables[i]);
      len = strlen(list[i].name);
      list[i].flatName = (char*) calloc(len + 1, sizeof(char));
      strcpy(list[i].flatName, list[i].name);
      charReplace(list[i].flatName, len, '.', '_');
      charReplace(list[i].flatName, len, '[', '_');
      charReplace(list[i].flatName, len, ']', '_');
      charReplace(list[i].flatName, len, ',', '_');
      charReplace(list[i].flatName, len, '(', '_');
      charReplace(list[i].flatName, len, ')', '_');
      list[i].vr = getValueReference(md->modelVariables[i]);
      list[i].description = getDescription(md, md->modelVariables[i]);
      /* replace '"' with "'" */
      if (list[i].description != NULL){
        len = strlen(list[i].description);
        tempDesc = (char*) calloc(len + 1, sizeof(char));
        memcpy(tempDesc, list[i].description, len);
        charReplace(tempDesc, len, 0x22, 0x27);
        list[i].description = (const char *) tempDesc;
      }
      //tempDesc = (char*) calloc(len + 1, sizeof(char));

#ifdef _DEBUG_
      printf("#### Description of sv %s, %s, value reference: %d\n",list[i].name, list[i].description,list[i].vr );
#endif

      list[i].var = getVariability(md->modelVariables[i]) - 2;
      list[i].causality = getCausality(md->modelVariables[i]) - 6;
      list[i].alias = getAlias(md->modelVariables[i]) - 10;
      list[i].type = getElementType(md->modelVariables[i]);

#ifdef _DEBUG_
      printf("#### sv.typeSpec.type: %d\n",list[i].type);
#endif

      list[i].variable = allocateElmSV(list[i]);
      instElmSV(md->modelVariables[i], list[i]);
#ifdef _DEBUG_
      if(list[i].type==0)
      printf("#### %s startvalue: %lf\n", list[i].name,((fmiREAL*)list[i].variable)->start);
      if(list[i].type==1)
      printf("#### %s startvalue: %d\n", list[i].name,((fmiINTEGER*)list[i].variable)->start);
      if(list[i].type==2)
      printf("#### %s startvalue: %d\n", list[i].name,((fmiBOOLEAN*)list[i].variable)->start);
#endif
    };
    return;
  } else {
    ERRORPRINT;
    fprintf(
        errLogFile,
        "#### instScalarVariable() failed: no modelVariable defined or memory error...%s\n",
        "");
    exit(EXIT_FAILURE);
  }
}

/*
 * functions that returns the variable naming convention
 */
fmiNamingConvention getNamingConvention(ModelDescription* md, Att att) {
  ValueStatus vs;
  Enu enu;
  fmiNamingConvention nconv;
  enu = getEnumValue(md, att_variableNamingConvention, &vs);
  if (vs == valueIllegal) {
    ERRORPRINT;
    fprintf(errLogFile,
        "#### Return value of getNamingConvention is illegal...%s\n", "");
    exit(EXIT_FAILURE);
  }
  if (enu == enu_flat)
    nconv = flat;
  else
    nconv = structured;
  return nconv;
}

/*
 *  function gets Experiment annotation or sets default values
 */
fmiDefaultExperiment *getDefaultExperiment(ModelDescription *md) {
  ValueStatus vs;
  double tmp_db;
  fmiDefaultExperiment *defExp = (fmiDefaultExperiment *) calloc(1,
      sizeof(fmiDefaultExperiment));
  ;

  if (md->defaultExperiment) {

    tmp_db = getDouble(md->defaultExperiment, att_startTime, &vs);
    defExp->startTime = (vs == valueDefined ? tmp_db : 0.0);

    tmp_db = getDouble(md->defaultExperiment, att_stopTime, &vs);
    defExp->stopTime = (vs == valueDefined ? tmp_db : 0.0);

    tmp_db = getDouble(md->defaultExperiment, att_tolerance, &vs);
    defExp->tolerance = (vs == valueDefined ? tmp_db : 0.00001);
  } else {
    defExp->startTime = 0.0;
    defExp->stopTime = 3.0;
    defExp->tolerance = 0.00001;
  }
  return defExp;
}

/*
 * function that instantiates the tree-like structure of fmu model description
 */
void instFmuModelDescription(ModelDescription* md, fmuModelDescription* fmuMD,
    fmiModelVariable* fmuMV) {
  fmuMD->fmiver = getFmiVersion(md);
  fmuMD->mn = getModelName(md);
  fmuMD->mid = getModelIdentifier(md);
  fmuMD->guid = getString(md, att_guid);
  fmuMD->description = getString(md, att_description);
  fmuMD->author = getString(md, att_author);
  fmuMD->mver = getString(md, att_version);
  fmuMD->genTool = getString(md, att_generationTool);
  fmuMD->genTime = getString(md, att_generationDateAndTime);
  fmuMD->nconv = getNamingConvention(md, att_variableNamingConvention);
  fmuMD->ncs = getNumberOfContStates(md);
  fmuMD->nei = getNumberOfEventIndicators(md);
  fmuMD->modelVariable = fmuMV;
  fmuMD->defaultExperiment = getDefaultExperiment(md);
}

/*
 * function that frees the allocated memory for scalar variable list
 */
void freeScalarVariableLst(fmiScalarVariable* list, int nsv) {
  int i;
  for (i = 0; i < nsv; i++) {
    /* free(list[i].variable); */
  }
  /* free(list); */
}

void printFileTest() {
  FILE *pfile = NULL;
  pfile = fopen("test.txt", "w");
  fprintf(pfile, "\npackage FMUImport_%s\n", "This is it");
  fclose(pfile);
  return;
}

/*
 * Modelica code generation for the external interface functions
 */
void tmpcodegen(fmuModelDescription* fmuMD, const char* decompPath) {
  //char tmpstr[BUFFERSIZE];

  /* Allocated memory needed to be freed and file needed to be closed */
  FILE * pfile;
  char * id;

  size_t len = strlen(fmuMD->mid) + strlen(decompPath);
  id = (char*) malloc(len + 14);
  strcpy(id, decompPath);
  strcat(id, fmuMD->mid);
  strcat(id, "FMUImport");
  strcat(id, ".mo");

#ifdef _DEBUG_
  printf("#### %s id = %s\n",QUOTEME(__LINE__),id);
#endif

  pfile = fopen(id, "w");
  if (!pfile) {
    ERRORPRINT;
    fprintf(errLogFile, "#### Creating %s failed...\n", id);
    exit(EXIT_FAILURE);
  } else {
    /*
     * No need of fmuModelica.tmp
     * since the makefile create the header file from it and then we assign that header FMU_TEMPLATE_STR
     */
    const char *FMU_TEMPLATE_STR =
#if defined(__MINGW32__) || defined(_MSC_VER)
#include "fmuModelica.h"
#else
#include "fmuModelica.unix.h"
#endif
    ;
    fprintf(pfile, "\npackage FMUImport_%s\n", fmuMD->mid);
    fputs(FMU_TEMPLATE_STR, pfile);
    /* // pf = fopen(FMU_TEMPLATE,"r");
     // if(!pf){
     // ERRORPRINT; fprintf(errLogFile,"#### Opening %s failed...\n",FMU_TEMPLATE);
     // exit(EXIT_FAILURE);
     // }
     // while(!feof(pf)){
     // fgets(tmpstr,BUFFERSIZE,pf);
     // if(ferror(pf)){
     // ERRORPRINT; fprintf(errLogFile,"#### Reading lines from %s failed...\n",FMU_TEMPLATE);
     // exit(EXIT_FAILURE);
     // }
     // fputs(tmpstr,pfile);
     // }
     * */
  }
  /* Free memory*/
  /* fclose(pf); */
  fclose(pfile);
  free(id);
}

/*
 *  function that adds an element to an fmuOutputVar list;
 */
void addOutputVariable(fmiScalarVariable* sv, fmuOutputVar** root,
    fmuOutputVar** nextVar, unsigned int* counter) {
  int tmpAlias;
  if (sv->alias == noalias)
    tmpAlias = 1;
  if (sv->alias == alias)
    tmpAlias = 1;
  if (sv->alias == negatedAlias)
    tmpAlias = -1;

  if (*root == NULL) {
    *root = (fmuOutputVar*) calloc(1, sizeof(fmuOutputVar));
    (*root)->name = sv->flatName;
    (*root)->vr = sv->vr;
    (*root)->aliasInd = tmpAlias;
    (*root)->variable = sv;
    (*root)->next = NULL;
    *nextVar = *root;
  } else {
    (*nextVar)->next = (fmuOutputVar*) calloc(1, sizeof(fmuOutputVar));
    (*nextVar) = (*nextVar)->next;
    (*nextVar)->name = sv->flatName;
    (*nextVar)->vr = sv->vr;
    (*nextVar)->aliasInd = tmpAlias;
    (*nextVar)->variable = sv;
    (*nextVar)->next = NULL;
  }
  (*counter)++;
}

/*
 * function that appends tow strings and returns the resulted string
 */
char* appendString(char const* head, char const* tail) {
  int len;
  char* res = NULL;
  len = strlen(head) + strlen(tail) + 1;
  res = (char*) calloc(len, sizeof(char));
  strcat(res, head);
  strcat(res, tail);
  res[len - 1] = '\0';
  return res;
}

/*
 * Modelica code generation for the FMU block
 */
void blockcodegen(fmuModelDescription* fmuMD, const char* decompPath,
    const char* fmudllpath) {
  /* Allocated memory needed to be freed */
  char * id = NULL;
  FILE * pfile = NULL;
  fmiScalarVariable *tmpSV = NULL;
  /* printing strings in modelica code */
  const char *varDesc;
  const char *y = appendString("y_", fmuMD->mid);
  const char *nx = appendString("nx_", fmuMD->mid);
  const char *der_x = appendString("der_x_", fmuMD->mid);
  const char *out_x = appendString("out_x_", fmuMD->mid);
  const char *out_der_x = appendString("out_der_x_", fmuMD->mid);
  const char *x = appendString("x_", fmuMD->mid);
  const char *nz = appendString("nz_", fmuMD->mid);
  const char *z = appendString("z_", fmuMD->mid);
  const char *prez = appendString("prez_", fmuMD->mid);
  const char *zXprez = appendString("zXprez", fmuMD->mid);
  const char *flagSE = appendString("flagSE_", fmuMD->mid);
  const char *indSE = appendString("indSE_", fmuMD->mid);
  const char *defaultVar = appendString("default_", fmuMD->mid);

  /* pointers for output variable linked lists */
  fmuOutputVar* pntReal = NULL;
  fmuOutputVar* tmpReal = NULL;
  fmuOutputVar* pntRealInput = NULL;
  fmuOutputVar* tmpRealInput = NULL;
  fmuOutputVar* pntRealOutput = NULL;
  fmuOutputVar* tmpRealOutput = NULL;
  /*
   * TODO: add start correct start value support
   */
  /*
  fmuOutputVar* pntRealStart = NULL;
  fmuOutputVar* tmpRealStart = NULL;
  */

  fmuOutputVar* pntInteger = NULL;
  fmuOutputVar* tmpInteger = NULL;
  fmuOutputVar* pntIntegerInput = NULL;
  fmuOutputVar* tmpIntegerInput = NULL;
  fmuOutputVar* pntIntegerOutput = NULL;
  fmuOutputVar* tmpIntegerOutput = NULL;

  fmuOutputVar* pntString = NULL;
  fmuOutputVar* tmpString = NULL;
  fmuOutputVar* pntStringInput = NULL;
  fmuOutputVar* tmpStringInput = NULL;
  fmuOutputVar* pntStringOutput = NULL;
  fmuOutputVar* tmpStringOutput = NULL;

  fmuOutputVar* pntBoolean = NULL;
  fmuOutputVar* tmpBoolean = NULL;
  fmuOutputVar* pntBooleanInput = NULL;
  fmuOutputVar* tmpBooleanInput = NULL;
  fmuOutputVar* pntBooleanOutput = NULL;
  fmuOutputVar* tmpBooleanOutput = NULL;

  unsigned int noReal; /* number of real variable */
  unsigned int noRealInput; /* number of real inputs */
  unsigned int noRealOutput; /* number of real outputs */
  /*unsigned int noRealStart;*/ /* number of real start value */

  unsigned int noInteger; /* number of integer variables */
  unsigned int noIntegerInput; /* number of integer inputs */
  unsigned int noIntegerOutput; /* number of integer outputs */

  unsigned int noString; /* number of string variables */
  unsigned int noStringInput; /* number of string inputs */
  unsigned int noStringOutput; /* number of string outputs */

  unsigned int noBoolean; /* number of boolean variables */
  unsigned int noBooleanInput; /* number of string inputs */
  unsigned int noBooleanOutput; /* number of string outputs */

  unsigned int noEnumeration; /* number of enumeration variables */

  int existPre; /* Whether there exists previous attribute */

  int j;
  double StartTime = fmuMD->defaultExperiment->startTime;
  double StopTime = fmuMD->defaultExperiment->stopTime;
  double Tolerance = fmuMD->defaultExperiment->tolerance;
  ;

  size_t len = strlen(fmuMD->mid) + strlen(decompPath);
  id = (char*) malloc(len + 14);
  strcpy(id, decompPath);
  strcat(id, fmuMD->mid);
  strcat(id, "FMUImport");
  strcat(id, ".mo");

  pfile = fopen(id, "a+");

  if (!pfile) {
    ERRORPRINT;
    fprintf(errLogFile, "#### Creating %s failed...\n", id);
    exit(EXIT_FAILURE);
  } else {
    fprintf(pfile, "\nblock FMUBlock \"%s model\"\n", fmuMD->mid);
    fprintf(
        pfile,
        "\tannotation(experiment(StartTime = %f, StopTime = %f, Tolerance = %f));\n",
        StartTime, StopTime, Tolerance);
    /*fprintf(pfile,"\tannotation(experiment(StartTime = %f, StopTime = %f));\n",StartTime,StopTime);*/
    fprintf(pfile, "\tconstant String dllPath = \"%s\";\n", fmudllpath);
    fprintf(pfile, "\tconstant String instName = \"%s\";\n", fmuMD->mid);
    fprintf(pfile, "\tconstant String guid = \"%s\";\n", fmuMD->guid);
    fprintf(pfile, "\tparameter Boolean logFlag = false;\n");
    fprintf(pfile, "\tparameter Boolean tolControl = true;\n");
    tmpSV = fmuMD->modelVariable->list_sv;
#ifdef _DEBUG_
    printf("++++ fmuMD->modelVariable->nsv %d \n",fmuMD->modelVariable->nsv);
#endif

    noReal = 0;
    noRealInput = 0;
    noRealOutput = 0;
    /* noRealStart = 0; */

    noInteger = 0;
    noIntegerInput = 0;
    noIntegerOutput = 0;

    noString = 0;
    noStringInput = 0;
    noStringOutput = 0;

    noBoolean = 0;
    noBooleanInput = 0;
    noBooleanOutput = 0;

    noEnumeration = 0;


    if (1 /* tmpSV>0 - handled by nsv... */) {
      for (j = 0; j < fmuMD->modelVariable->nsv; j++) {

        if (tmpSV[j].description != NULL)
          varDesc = tmpSV[j].description;
        else
          varDesc = "";

#ifdef _DEBUG_
        printf("++++ Variable type is %d\n",tmpSV[j].type);
        printf("++++ Variable name is %s\n",tmpSV[j].name);
#endif
        switch (tmpSV[j].type) { /* sorting by variable types */
        case sv_real: {
          /* local variables for Real type varialbe definition */
          int bool_quantity, bool_unit, bool_displayUnit, bool_defMin,
              bool_defMax, bool_norminal, bool_defStart, bool_fixed;

          bool_quantity =
              (strcmp(((fmiREAL *) tmpSV[j].variable)->quantity, "") != 0) ?
                  1 : 0;
          bool_unit =
              (strcmp(((fmiREAL *) tmpSV[j].variable)->unit, "") != 0) ?
                  1 : 0;
          bool_displayUnit =
              (strcmp(((fmiREAL *) tmpSV[j].variable)->displayUnit, "")
                  != 0) ? 1 : 0;
          bool_defMin = ((fmiREAL *) tmpSV[j].variable)->defMin;
          bool_defMax = ((fmiREAL *) tmpSV[j].variable)->defMax;
          bool_norminal = ((fmiREAL *) tmpSV[j].variable)->defNorminal;
          bool_defStart = ((fmiREAL *) tmpSV[j].variable)->defStart;
          bool_fixed =
              (((fmiREAL *) tmpSV[j].variable)->fixed == fmi_true) ? 1 : 0;

          if (((tmpSV[j].causality) != none) && ((tmpSV[j].causality) != internal))
            fprintf(pfile, "\t%s", causalityNames[tmpSV[j].causality]);
          if ((tmpSV[j].var) != continuous)
            fprintf(pfile, " %s", variabilityNames[tmpSV[j].var]);
          if ((tmpSV[j].var) == continuous)
                        fprintf(pfile, " %s", variabilityNames[tmpSV[j].var]);



          fprintf(pfile, " Real %s", tmpSV[j].flatName);
          existPre = 0;
          if (bool_quantity || bool_unit || bool_displayUnit || bool_defMin
              || bool_defMax || bool_norminal || bool_defStart || bool_fixed)
            fprintf(pfile, "%s", "(");
          if (bool_quantity) {
            fprintf(pfile, "quantity = \"%s\"",
                ((fmiREAL *) tmpSV[j].variable)->quantity);
            existPre = 1;
          }
          if (bool_unit) {
            if (existPre)
              fprintf(pfile, ", unit = \"%s\"",
                  ((fmiREAL *) tmpSV[j].variable)->unit);
            else {
              fprintf(pfile, "unit = \"%s\"",
                  ((fmiREAL *) tmpSV[j].variable)->unit);
              existPre = 1;
            }
          }
          if (bool_displayUnit) {
            if (existPre)
              fprintf(pfile, ", displayUnit = \"%s\"",
                  ((fmiREAL *) tmpSV[j].variable)->displayUnit);
            else {
              fprintf(pfile, "displayUnit = \"%s\"",
                  ((fmiREAL *) tmpSV[j].variable)->displayUnit);
              existPre = 1;
            }
          }
          if (bool_defStart) {
            /*
             * TODO: add start correct start value support
             */
            /* addOutputVariable(&tmpSV[j], &pntRealStart, &tmpRealStart, &noRealStart);*/
            if (existPre)
              fprintf(pfile, ", start = %lf",
                  ((fmiREAL*) tmpSV[j].variable)->start);
            else {
              fprintf(pfile, "start = %lf",
                  ((fmiREAL*) tmpSV[j].variable)->start);
              existPre = 1;
            }
          }
          if (bool_defMin) {
            if (existPre)
              fprintf(pfile, ", min = %lf",
                  ((fmiREAL*) tmpSV[j].variable)->min);
            else {
              fprintf(pfile, "min = %lf",
                  ((fmiREAL*) tmpSV[j].variable)->min);
              existPre = 1;
            }
          }
          if (bool_defMax) {
            if (existPre)
              fprintf(pfile, ", max = %lf",
                  ((fmiREAL*) tmpSV[j].variable)->max);
            else {
              fprintf(pfile, "max = %lf",
                  ((fmiREAL*) tmpSV[j].variable)->max);
              existPre = 1;
            }
          }
          if (bool_fixed) {
            if (existPre)
              fprintf(pfile, ", fixed = %s",
                  startValueFixed[((fmiREAL*) tmpSV[j].variable)->fixed]);
            else {
              fprintf(pfile, "fixed = %s",
                  startValueFixed[((fmiREAL*) tmpSV[j].variable)->fixed]);
              /* existPre = 1; */
            }
          }
          if (bool_quantity || bool_unit || bool_displayUnit || bool_defMin
              || bool_defMax || bool_norminal || bool_defStart || bool_fixed)
            fprintf(pfile, "%s", " )");
          if ((tmpSV[j].var == 0) || (tmpSV[j].var == 1)) {
            fprintf(pfile, " =  %lf", ((fmiREAL*) tmpSV[j].variable)->start);
          }
          if (strcmp(varDesc, "") != 0)
            fprintf(pfile, " \"%s\"", varDesc);
          fprintf(pfile, "%s", ";\n");
          /*
           fprintf(pfile,"\t%s %s Real %s (start=%lf, fixed = %s) \"%s\";\n",causalityNames[tmpSV[j].causality],
           variabilityNames[tmpSV[j].var],tmpSV[j].flatName,((fmiREAL*)tmpSV[j].variable)->start,
           startValueFixed[((fmiREAL*)tmpSV[j].variable)->fixed],varDesc);
           */
          if ((tmpSV[j].var != 0) && (tmpSV[j].var != 1)) {
            if ((tmpSV[j].causality == 0)){
              addOutputVariable(&tmpSV[j], &pntRealInput, &tmpRealInput, &noRealInput);
            }else if ((tmpSV[j].causality == 1)){
              addOutputVariable(&tmpSV[j], &pntRealOutput, &tmpRealOutput, &noRealOutput);
            }else{
              addOutputVariable(&tmpSV[j], &pntReal, &tmpReal, &noReal);
            }
          }
          break;
        }

        case sv_integer: {
          /* local variables for Integer type varialbe definition */
          int bool_quantity, bool_defMin, bool_defMax, bool_defStart,
              bool_fixed;

          bool_quantity =
              (strcmp(((fmiINTEGER *) tmpSV[j].variable)->quantity, "")
                  != 0) ? 1 : 0;
          bool_defMin = ((fmiINTEGER *) tmpSV[j].variable)->defMin;
          bool_defMax = ((fmiINTEGER *) tmpSV[j].variable)->defMax;
          bool_defStart = ((fmiINTEGER *) tmpSV[j].variable)->defStart;
          bool_fixed =
              (((fmiINTEGER *) tmpSV[j].variable)->fixed == fmi_true) ? 1 : 0;

          if (((tmpSV[j].causality) != none)
              && ((tmpSV[j].causality) != internal))
            fprintf(pfile, "\t%s", causalityNames[tmpSV[j].causality]);
          fprintf(pfile, " Integer %s", tmpSV[j].flatName);
          existPre = 0;
          if (bool_quantity || bool_defMin || bool_defMax || bool_defStart
              || bool_fixed)
            fprintf(pfile, " %s", "(");
          if (bool_quantity) {
            fprintf(pfile, "quantity = \"%s\"",
                ((fmiINTEGER *) tmpSV[j].variable)->quantity);
            existPre = 1;
          }
          if (bool_defStart) {
            if (existPre)
              fprintf(pfile, ", start = %d",
                  ((fmiINTEGER*) tmpSV[j].variable)->start);
            else {
              fprintf(pfile, "start = %d",
                  ((fmiINTEGER*) tmpSV[j].variable)->start);
              existPre = 1;
            }
          }
          if (bool_defMin) {
            if (existPre)
              fprintf(pfile, ", min = %d",
                  ((fmiINTEGER*) tmpSV[j].variable)->min);
            else {
              fprintf(pfile, "min = %d",
                  ((fmiINTEGER*) tmpSV[j].variable)->min);
              existPre = 1;
            }
          }
          if (bool_defMax) {
            if (existPre)
              fprintf(pfile, ", max = %d",
                  ((fmiINTEGER*) tmpSV[j].variable)->max);
            else {
              fprintf(pfile, "max = %d",
                  ((fmiINTEGER*) tmpSV[j].variable)->max);
              existPre = 1;
            }
          }
          if (bool_fixed) {
            if (existPre)
              fprintf(pfile, ", fixed = %s",
                  startValueFixed[((fmiINTEGER*) tmpSV[j].variable)->fixed]);
            else {
              fprintf(pfile, "fixed = %s",
                  startValueFixed[((fmiINTEGER*) tmpSV[j].variable)->fixed]);
              /* existPre = 1; */
            }
          }
          if (bool_quantity || bool_defMin || bool_defMax || bool_defStart
              || bool_fixed)
            fprintf(pfile, " %s", ")");
          if ((tmpSV[j].var == 0) || (tmpSV[j].var == 1)) {
            fprintf(pfile, " = %d", ((fmiINTEGER*) tmpSV[j].variable)->start);
          }
          if (strcmp(varDesc, "") != 0)
            fprintf(pfile, " \"%s\"", varDesc);
          fprintf(pfile, "%s", ";\n");

          // fprintf(pfile,"\t%s %s Integer %s (start=%d, fixed = %s) \"%s\";\n",causalityNames[tmpSV[j].causality],
          // variabilityNames[tmpSV[j].var],tmpSV[j].flatName,((fmiINTEGER*)tmpSV[j].variable)->start,
          // startValueFixed[((fmiINTEGER*)tmpSV[j].variable)->fixed],varDesc);

          if ((tmpSV[j].var != 0) && (tmpSV[j].var != 1)) {
            if ((tmpSV[j].causality == 0)){
              addOutputVariable(&tmpSV[j], &pntIntegerInput, &tmpIntegerInput, &noIntegerInput);
            }else if ((tmpSV[j].causality == 1)){
              addOutputVariable(&tmpSV[j], &pntIntegerOutput, &tmpIntegerOutput, &noIntegerOutput);
            }else{
              addOutputVariable(&tmpSV[j], &pntInteger, &tmpInteger, &noInteger);
            }
          }
          break;
        }
        case sv_boolean: {
          int bool_defStart, bool_fixed;

          bool_defStart = ((fmiBOOLEAN *) tmpSV[j].variable)->defStart;
          bool_fixed =
              (((fmiBOOLEAN *) tmpSV[j].variable)->fixed == fmi_true) ? 1 : 0;

          if (((tmpSV[j].causality) != none)
              && ((tmpSV[j].causality) != internal))
            fprintf(pfile, "\t%s", causalityNames[tmpSV[j].causality]);
          fprintf(pfile, " Boolean %s", tmpSV[j].flatName);
          existPre = 0;
          if (bool_defStart || bool_fixed)
            fprintf(pfile, " %s", "(");
          if (bool_defStart) {
            if (((fmiINTEGER*) tmpSV[j].variable)->start == 1)
              fprintf(pfile, " start = %s", "true");
            else
              fprintf(pfile, " start = %s", "false");
            existPre = 1;
          }
          if (bool_fixed) {
            if (existPre)
              fprintf(pfile, ", fixed = %s",
                  startValueFixed[((fmiBOOLEAN*) tmpSV[j].variable)->fixed]);
            else {
              fprintf(pfile, "fixed = %s",
                  startValueFixed[((fmiBOOLEAN*) tmpSV[j].variable)->fixed]);
              existPre = 1;
            }
          }
          if (bool_defStart || bool_fixed)
            fprintf(pfile, " %s", ")");
          if ((tmpSV[j].var == 0) && (tmpSV[j].var == 1)) {
            if (((fmiINTEGER*) tmpSV[j].variable)->start == 1)
              fprintf(pfile, " = %s", "true");
            else
              fprintf(pfile, " = %s", "false");
          }
          if (strcmp(varDesc, "") != 0)
            fprintf(pfile, " \"%s\"", varDesc);
          fprintf(pfile, "%s", ";\n");

          // fprintf(pfile,"\t%s %s Boolean %s (start=%s, fixed = %s) \"%s\";\n",causalityNames[tmpSV[j].causality],
          // variabilityNames[tmpSV[j].var],tmpSV[j].flatName,fmiBooleanValue[((fmiBOOLEAN*)tmpSV[j].variable)->start],
          // startValueFixed[((fmiBOOLEAN*)tmpSV[j].variable)->fixed],varDesc);

          if ((tmpSV[j].var != 0) || (tmpSV[j].var != 1)) {
            if ((tmpSV[j].causality == 0)){
              addOutputVariable(&tmpSV[j], &pntBooleanInput, &tmpBooleanInput, &noBooleanInput);
            }else if ((tmpSV[j].causality == 1)){
              addOutputVariable(&tmpSV[j], &pntBooleanOutput, &tmpBooleanOutput, &noBooleanOutput);
            }else{
              addOutputVariable(&tmpSV[j], &pntBoolean, &tmpBoolean, &noBoolean);
            }
          }
          break;
        }
        case sv_string: {
          int bool_defStart, bool_fixed;

          bool_defStart = ((fmiSTRING *) tmpSV[j].variable)->defStart;
          bool_fixed =
              (((fmiSTRING *) tmpSV[j].variable)->fixed == fmi_true) ? 1 : 0;
          if (((tmpSV[j].causality) != none)
              && ((tmpSV[j].causality) != internal))
            fprintf(pfile, "\t%s", causalityNames[tmpSV[j].causality]);
          fprintf(pfile, " String %s", tmpSV[j].flatName);
          existPre = 0;
          if (bool_defStart || bool_fixed)
            fprintf(pfile, " %s", "(");
          if (bool_defStart) {
            fprintf(pfile, " start = \"%s\"",
                ((fmiSTRING*) tmpSV[j].variable)->start);
            existPre = 1;
          }
          if (bool_fixed) {
            if (existPre)
              fprintf(pfile, ", fixed = %s",
                  startValueFixed[((fmiSTRING*) tmpSV[j].variable)->fixed]);
            else {
              fprintf(pfile, "fixed = %s",
                  startValueFixed[((fmiSTRING*) tmpSV[j].variable)->fixed]);
              existPre = 1;
            }
          }
          if (bool_defStart || bool_fixed)
            fprintf(pfile, " %s", ")");
          if ((tmpSV[j].var == 0) || (tmpSV[j].var == 1)) {
            fprintf(pfile, " = \"%s\"",
                ((fmiSTRING*) tmpSV[j].variable)->start);
          }
          if (strcmp(varDesc, "") != 0)
            fprintf(pfile, " \"%s\"", varDesc);
          fprintf(pfile, "%s", ";\n");

          // fprintf(pfile,"\t%s %s String %s (start=\"%s\", fixed = %s) \"%s\";\n",causalityNames[tmpSV[j].causality],
          // variabilityNames[tmpSV[j].var],tmpSV[j].flatName,((fmiSTRING*)tmpSV[j].variable)->start,
          // startValueFixed[((fmiSTRING*)tmpSV[j].variable)->fixed],varDesc);

          if ((tmpSV[j].var != 0) && (tmpSV[j].var != 1)) {
            if ((tmpSV[j].causality == 0)){
              addOutputVariable(&tmpSV[j], &pntStringInput, &tmpStringInput, &noStringInput);
            }else if ((tmpSV[j].causality == 1)){
              addOutputVariable(&tmpSV[j], &pntStringOutput, &tmpStringOutput, &noStringOutput);
            }else{
              addOutputVariable(&tmpSV[j], &pntString, &tmpString, &noString);
            }
          }
          break;
        }
        case sv_enum: {
          printf("[%d]: #### Here Ok...\n", __LINE__);
        }
        default: {
        }
        }
      }

    } else {
      ERRORPRINT;
      fprintf(errLogFile, "#### Memory error: %s is empty...\n", "tmpSV");
      exit(EXIT_FAILURE);
    }
#ifdef _DEBUG_
    printf("#### noReal: %d\n",noReal);
    printf("#### noInteger: %d\n",noInteger);
    printf("#### noString: %d\n",noString);
    printf("#### noBoolean: %d\n",noBoolean);
    printf("#### noRealParam: %d\n",noRealParam);
    printf("#### noIntegerParam: %d\n",noIntegerParam);
    printf("#### noStringParam: %d\n",noStringParam);
    printf("#### noBooleanParam: %d\n",noBooleanParam);
#endif
    if (fmuMD->ncs > 0) {
      fprintf(pfile, "\tparameter Integer %s = %d;\n", nx, fmuMD->ncs);
      if (fmuMD->nei > 0) {
        fprintf(pfile, "\tReal %s[%s];\n", out_x, nx);
      }
      fprintf(pfile, "\treplaceable Real %s[%s];\n", x, nx);
    }else {
      fprintf(pfile, "\tReal dummy;\n");
    }
    fprintf(pfile, "protected\n");

    if (noReal > 0) {
      tmpReal = pntReal;
      fprintf(pfile, "\tReal realV[%d];\n", noReal);
      fprintf(pfile, "\tparameter Integer realVR[%d] = {", noReal);
      if (noReal == 1)
        fprintf(pfile, "%d};\n", tmpReal->vr);
      else if (noReal > 1) {
        for (j = 0; j < noReal - 1; j++) {
          fprintf(pfile, "%d, ", tmpReal->vr);
          tmpReal = tmpReal->next;
        }
        fprintf(pfile, "%d};\n", tmpReal->vr);
      }
    }

    if (noRealInput > 0) {
      tmpRealInput = pntRealInput;
      fprintf(pfile, "\tReal flowControlRealInput;\n");
      fprintf(pfile, "\tparameter Integer realVRInput[%d] = {", noRealInput);
      if (noRealInput == 1)
        fprintf(pfile, "%d};\n", tmpRealInput->vr);
      else if (noRealInput > 1) {
        for (j = 0; j < noRealInput - 1; j++) {
          fprintf(pfile, "%d, ", tmpRealInput->vr);
          tmpRealInput = tmpRealInput->next;
        }
        fprintf(pfile, "%d};\n", tmpRealInput->vr);
      }
    }

    if (noRealOutput > 0) {
      tmpRealOutput = pntRealOutput;
      fprintf(pfile, "\tReal realVOutput[%d];\n", noRealOutput);
      fprintf(pfile, "\tparameter Integer realVROutput[%d] = {", noRealOutput);
      if (noRealOutput == 1)
        fprintf(pfile, "%d};\n", tmpRealOutput->vr);
      else if (noRealOutput > 1) {
        for (j = 0; j < noRealOutput - 1; j++) {
          fprintf(pfile, "%d, ", tmpRealOutput->vr);
          tmpRealOutput = tmpRealOutput->next;
        }
        fprintf(pfile, "%d};\n", tmpRealOutput->vr);
      }
    }
    /*
     * TODO: add start correct start value support
     */
    /*
    if (noRealStart > 0) {
      tmpRealStart = pntRealStart;
      fprintf(pfile, "\tReal realVStart[%d] = {", noRealStart);
      if (noRealStart == 1)
        fprintf(pfile, "%s};\n",((fmiREAL*) tmpRealStart->variable)->start);
      else if (noRealStart > 1) {
        for (j = 0; j < noRealStart - 1; j++) {
          fprintf(pfile, "%s, ", ((fmiREAL*) tmpRealStart->variable)->start);
          tmpRealStart = tmpRealStart->next;
        }
        fprintf(pfile, "%s};\n", ((fmiREAL*) tmpRealStart->variable)->start);
      }

      fprintf(pfile, "\tparameter Integer realVRStart[%d] = {", noRealStart);
      if (noRealStart == 1)
        fprintf(pfile, "%d};\n", tmpRealStart->vr);
      else if (noRealStart > 1) {
        for (j = 0; j < noRealStart - 1; j++) {
          fprintf(pfile, "%d, ", tmpRealStart->vr);
          tmpRealStart = tmpRealStart->next;
        }
        fprintf(pfile, "%d};\n", tmpRealStart->vr);
      }
    }
    */

    if (noInteger > 0) {
      tmpInteger = pntInteger;
      fprintf(pfile, "\tInteger integerV[%d];\n", noInteger);
      fprintf(pfile, "\tparameter Integer integerVR[%d] = {", noInteger);
      if (noInteger == 1)
        fprintf(pfile, "%d};\n", tmpInteger->vr);
      else if (noInteger > 1) {
        for (j = 0; j < noInteger - 1; j++) {
          fprintf(pfile, "%d, ", tmpInteger->vr);
          tmpInteger = tmpInteger->next;
        }
        fprintf(pfile, "%d};\n", tmpInteger->vr);
      }
    }
    if (noIntegerInput > 0) {
      tmpIntegerInput = pntIntegerInput;
      fprintf(pfile, "\tReal flowControlIntegerInput;\n");
      fprintf(pfile, "\tparameter Integer integerVRInput[%d] = {", noIntegerInput);
      if (noIntegerInput == 1)
        fprintf(pfile, "%d};\n", tmpIntegerInput->vr);
      else if (noIntegerInput > 1) {
        for (j = 0; j < noIntegerInput - 1; j++) {
          fprintf(pfile, "%d, ", tmpIntegerInput->vr);
          tmpIntegerInput = tmpIntegerInput->next;
        }
        fprintf(pfile, "%d};\n", tmpIntegerInput->vr);
      }
    }

    if (noIntegerOutput > 0) {
      tmpIntegerOutput = pntIntegerOutput;
      fprintf(pfile, "\tInteger integerVOutput[%d];\n", noIntegerOutput);
      fprintf(pfile, "\tparameter Integer integerVROutput[%d] = {", noIntegerOutput);
      if (noIntegerOutput == 1)
        fprintf(pfile, "%d};\n", tmpIntegerOutput->vr);
      else if (noIntegerOutput > 1) {
        for (j = 0; j < noIntegerOutput - 1; j++) {
          fprintf(pfile, "%d, ", tmpIntegerOutput->vr);
          tmpIntegerOutput = tmpIntegerOutput->next;
        }
        fprintf(pfile, "%d};\n", tmpIntegerOutput->vr);
      }
    }

    if (noBoolean > 0) {
      tmpBoolean = pntBoolean;
      fprintf(pfile, "\tBoolean booleanV[%d];\n", noBoolean);
      fprintf(pfile, "\tparameter Integer booleanVR[%d] = {", noBoolean);
      if (noBoolean == 1)
        fprintf(pfile, "%d};\n", tmpBoolean->vr);
      else if (noBoolean > 1) {
        for (j = 0; j < noBoolean - 1; j++) {
          fprintf(pfile, "%d, ", tmpBoolean->vr);
          tmpBoolean = tmpBoolean->next;
        }
        fprintf(pfile, "%d};\n", tmpBoolean->vr);
      }
    }
    if (noBooleanInput > 0) {
      tmpBooleanInput = pntBooleanInput;
      fprintf(pfile, "\tReal flowControlBooleanInput;\n");
      fprintf(pfile, "\tparameter Integer booleanVRInput[%d] = {", noBooleanInput);
      if (noBooleanInput == 1)
        fprintf(pfile, "%d};\n", tmpBooleanInput->vr);
      else if (noBooleanInput > 1) {
        for (j = 0; j < noBooleanInput - 1; j++) {
          fprintf(pfile, "%d, ", tmpBooleanInput->vr);
          tmpBooleanInput = tmpBooleanInput->next;
        }
        fprintf(pfile, "%d};\n", tmpBooleanInput->vr);
      }
    }

    if (noBooleanOutput > 0) {
      tmpBooleanOutput = pntBooleanOutput;
      fprintf(pfile, "\tBoolean booleanVOutput[%d];\n", noBooleanOutput);
      fprintf(pfile, "\tparameter Integer booleanVROutput[%d] = {", noBooleanOutput);
      if (noBooleanOutput == 1)
        fprintf(pfile, "%d};\n", tmpBooleanOutput->vr);
      else if (noBooleanOutput > 1) {
        for (j = 0; j < noBooleanOutput - 1; j++) {
          fprintf(pfile, "%d, ", tmpBooleanOutput->vr);
          tmpBooleanOutput = tmpBooleanOutput->next;
        }
        fprintf(pfile, "%d};\n", tmpBooleanOutput->vr);
      }
    }

    if (noString > 0) {
      tmpString = pntString;
      fprintf(pfile, "\tString stringV[%d];\n", noString);
      fprintf(pfile, "\tparameter Integer stringVR[%d] = {", noString);
      if (noString == 1)
        fprintf(pfile, "%d};\n", tmpString->vr);
      else if (noString > 1) {
        for (j = 0; j < noString - 1; j++) {
          fprintf(pfile, "%d, ", tmpString->vr);
          tmpString = tmpString->next;
        }
        fprintf(pfile, "%d};\n", tmpString->vr);
      }
    }
    if (noStringInput > 0) {
      tmpStringInput = pntStringInput;
      fprintf(pfile, "\tReal flowControlStringInput;\n");
      fprintf(pfile, "\tparameter Integer stringVRInput[%d] = {", noStringInput);
      if (noStringInput == 1)
        fprintf(pfile, "%d};\n", tmpStringInput->vr);
      else if (noStringInput > 1) {
        for (j = 0; j < noStringInput - 1; j++) {
          fprintf(pfile, "%d, ", tmpStringInput->vr);
          tmpStringInput = tmpStringInput->next;
        }
        fprintf(pfile, "%d};\n", tmpStringInput->vr);
      }
    }

    if (noStringOutput > 0) {
      tmpStringOutput = pntStringOutput;
      fprintf(pfile, "\tString stringVOutput[%d];\n", noStringOutput);
      fprintf(pfile, "\tparameter Integer stringVROutput[%d] = {", noStringOutput);
      if (noStringOutput == 1)
        fprintf(pfile, "%d};\n", tmpStringOutput->vr);
      else if (noStringOutput > 1) {
        for (j = 0; j < noStringOutput - 1; j++) {
          fprintf(pfile, "%d, ", tmpStringOutput->vr);
          tmpStringOutput = tmpStringOutput->next;
        }
        fprintf(pfile, "%d};\n", tmpStringOutput->vr);
      }
    }
    if (fmuMD->nei > 0) {
      fprintf(pfile, "\tparameter Integer %s = %d;\n", nz, fmuMD->nei);
      fprintf(pfile, "\tReal %s[%s];\n", z, nz);
      fprintf(pfile, "\tBoolean %s[%s] \"flag for state events\";\n", flagSE,
          nz);
    }
    fprintf(pfile, "\treplaceable parameter Real relTol = 0.0001;\n");
    fprintf(pfile, "\tparameter Integer %s = 0;\n", defaultVar);
    fprintf(pfile, "\tfmuModelInst inst = fmuModelInst(fmufun, instName, guid, functions, logFlag);\n");
    fprintf(pfile, "\tfmuEventInfo evtInfo = fmuEventInfo();\n");
    fprintf(pfile, "\tfmuBoolean timeEvt = fmuBoolean(%s);\n", defaultVar);
    fprintf(pfile, "\tfmuBoolean stepEvt = fmuBoolean(%s);\n", defaultVar);
    fprintf(pfile, "\tfmuBoolean stateEvt = fmuBoolean(%s);\n", defaultVar);
    fprintf(pfile, "\tfmuBoolean interMediateRes = fmuBoolean(%s);\n",
        defaultVar);
    //fprintf(pfile,"\tfmuBoolean freeAll = fmuBoolean(default);\n");
    fprintf(pfile, "\tfmuFunctions fmufun = fmuFunctions(\"%s\",dllPath);\n",
        fmuMD->mid);
    fprintf(pfile, "\tfmuCallbackFuns functions = fmuCallbackFuns();\n");
    fprintf(pfile, "\tReal flowControlTime;\n");
    fprintf(pfile, "\tReal flowControlStates;\n");
    fprintf(pfile, "\tReal flowControlEvent;\n");

    fprintf(pfile, "\tReal flowControlStatesInputs = flowControlStates ");
    if (noRealInput > 0) {
      fputs(" + flowControlRealInput", pfile);
    }
    if (noIntegerInput > 0) {
      fputs(" + flowControlIntegerInput", pfile);
    }
    if (noBooleanInput > 0) {
      fputs(" + flowControlBooleanInput", pfile);
    }
    if (noStringInput > 0) {
      fputs(" + flowControlStringInput", pfile);
    }
    fprintf(pfile, ";\n");

    fprintf(pfile, "\tReal flowhack;\n");
    fprintf(pfile, "\tBoolean initializationDone(start=false);\n");
    fprintf(pfile, "initial algorithm\n");
    fprintf(pfile, "\tflowControlTime := fmuSetTime(fmufun, inst, time, 1);\n");
    fprintf(pfile, "\tif not initializationDone then\n");

    /*
     * TODO: add start correct start value support
     */
    /*
    // Set start values for real variables
    if (noRealStart > 0) {
      tmpReal = pntReal;
      fprintf(pfile, "\t\t realVRStart = {fmuSetRealVR(fmufun, inst, %d, realVR,", noReal);
      fprintf(pfile, "\t\t{");
      if (noReal == 1)
        fprintf(pfile, "%s});\n", tmpReal->name);
      else if (noReal > 1) {
        for (j = 0; j < noReal - 1; j++) {
          fprintf(pfile, "%s, ", tmpReal->name);
          tmpReal = tmpReal->next;
        }
        fprintf(pfile, " %s});\n", tmpReal->name);
      }
      fprintf(pfile, "\t\tflowControlStart := fmuSetRealVR(fmufun, inst, %d, realVR,", noReal);
    }

    // Set start values for real parameters
    if (noRealParam > 0) {
      tmpRealParam = pntRealParam;
      fprintf(pfile, "\t\tfmuSetRealVR(fmufun, inst, %d, realVRParam,",
          noRealParam);
      fprintf(pfile, "\t\t{");
      if (noRealParam == 1)
        fprintf(pfile, "%s});\n", tmpRealParam->name);
      else if (noRealParam > 1) {
        for (j = 0; j < noRealParam - 1; j++) {
          fprintf(pfile, "%s, ", tmpRealParam->name);
          tmpRealParam = tmpRealParam->next;
        }
        fprintf(pfile, " %s});", tmpRealParam->name);
      }
    }

    // Set start values for integer variables
    if (noInteger > 0) {
      tmpInteger = pntInteger;
      fprintf(pfile, "\t\tfmuSetIntegerVR(fmufun, inst, %d, integerVR,",
          noInteger);
      fprintf(pfile, "\t\t{");
      if (noInteger == 1)
        fprintf(pfile, "%s});\n", tmpInteger->name);
      else if (noInteger > 1) {
        for (j = 0; j < noInteger - 1; j++) {
          fprintf(pfile, "%s, ", tmpInteger->name);
          tmpInteger = tmpInteger->next;
        }
        fprintf(pfile, "%s});\n", tmpInteger->name);
      }
    }

    // Set start values for integer parameters
    if (noIntegerParam > 0) {
      tmpIntegerParam = pntIntegerParam;
      fprintf(pfile, "\t\tfmuSetIntegerVR(fmufun, inst, %d, integerVR,",
          noIntegerParam);
      fprintf(pfile, "\t\t{");
      if (noIntegerParam == 1)
        fprintf(pfile, "%s});\n", tmpIntegerParam->name);
      else if (noIntegerParam > 1) {
        for (j = 0; j < noIntegerParam - 1; j++) {
          fprintf(pfile, "%s, ", tmpIntegerParam->name);
          tmpIntegerParam = tmpIntegerParam->next;
        }
        fprintf(pfile, "%s});\n", tmpIntegerParam->name);
      }
    }

    // Set start values for boolean variables
    if (noBoolean > 0) {
      tmpBoolean = pntBoolean;
      fprintf(pfile, "\t\tfmuSetBooleanVR(fmufun, inst, %d, booleanVR,",
          noBoolean);
      fprintf(pfile, "\t\t{");
      if (noBoolean == 1)
        fprintf(pfile, "%s});\n", tmpBoolean->name);
      else if (noBoolean > 1) {
        for (j = 0; j < noBoolean - 1; j++) {
          fprintf(pfile, "%s, ", tmpBoolean->name);
          tmpBoolean = tmpBoolean->next;
        }
        fprintf(pfile, "%s});\n", tmpBoolean->name);
      }
    }

    // Set start values for boolean parameters
    if (noBooleanParam > 0) {
      tmpBooleanParam = pntBooleanParam;
      fprintf(pfile, "\t\tfmuSetBooleanVR(fmufun, inst, %d, booleanParamVR,",
          noBoolean);
      fprintf(pfile, "\t{");
      if (noBooleanParam == 1)
        fprintf(pfile, "%s});\n", tmpBooleanParam->name);
      else if (noBooleanParam > 1) {
        for (j = 0; j < noBooleanParam - 1; j++) {
          fprintf(pfile, "%s, ", tmpBooleanParam->name);
          tmpBooleanParam = tmpBooleanParam->next;
        }
        fprintf(pfile, "%s});\n", tmpBooleanParam->name);
      }
    }
    // Set start values for string variables
    if (noString > 0) {
      tmpString = pntString;
      fprintf(pfile, "\t\tfmuSetStringVR(fmufun, inst, %d, stringVR,",
          noBoolean);
      fprintf(pfile, "\t\t{");
      if (noString == 1)
        fprintf(pfile, "%s})\n", tmpString->name);
      else if (noString > 1) {
        for (j = 0; j < noString - 1; j++) {
          fprintf(pfile, "%s, ", tmpString->name);
          tmpString = tmpString->next;
        }
        fprintf(pfile, "%s});\n", tmpString->name);
      }
    }

    // Set start values for string parameters
    if (noStringParam > 0) {
      tmpStringParam = pntStringParam;
      fprintf(pfile, "\t\tfmuSetstringVR(fmufun, inst, %d, stringParamVR,",
          noBoolean);
      fprintf(pfile, "\t\t{");
      if (noStringParam == 1)
        fprintf(pfile, "%s});\n", tmpStringParam->name);
      else if (noStringParam > 1) {
        for (j = 0; j < noStringParam - 1; j++) {
          fprintf(pfile, "%s, ", tmpStringParam->name);
          tmpStringParam = tmpStringParam->next;
        }
        fprintf(pfile, "%s});\n", tmpStringParam->name);
      }
    }
*/
    fprintf(pfile, "\t\tfmuInit(fmufun, inst, tolControl, relTol, evtInfo);\n");
    fprintf(pfile, "\t\tinitializationDone:= true;\n");
    fprintf(pfile, "\tend if;\n");

    if (fmuMD->ncs > 0) {
      fprintf(pfile, "\t%s:=fmuGetContStates(fmufun, inst, %s);\n", x, nx);
    }
#ifdef _DEBUG_MODELICA
    fprintf(pfile,"\tprintVariable(%s, %s, \"%s, initial algorithm\");\n",x,nx,x);
#endif
    fputs("algorithm\n", pfile);
    fputs("\tinitializationDone := true;\n", pfile);
    fprintf(pfile, "equation \n");

    fputs("\tflowControlTime = fmuSetTime(fmufun, inst, time, 1);\n", pfile);

    if (noRealInput > 0) {
      fprintf(pfile, "\tflowControlRealInput = fmuSetRealVR(fmufun, inst, %d, realVRInput",
          noRealInput);
      tmpRealInput = pntRealInput;
      fprintf(pfile, "\t, {");
      if (noRealInput == 1)
        fprintf(pfile, "%s}, flowControlStates);\n", tmpRealInput->name);
      else if (noRealInput > 1) {
        for (j = 0; j < noRealInput - 1; j++) {
          fprintf(pfile, "%s, ", tmpRealInput->name);
          tmpRealInput = tmpRealInput->next;
        }
        fprintf(pfile, "%s}, flowControlStates);\n",tmpRealInput->name);
      }
    }
    if (noIntegerInput > 0) {
      fprintf(pfile, "\tflowControlIntegerInput = fmuSetIntegerVR(fmufun, inst, %d, integerVRInput",
          noIntegerInput);
      tmpIntegerInput = pntIntegerInput;
      fprintf(pfile, "\t, {");
      if (noIntegerInput == 1)
        fprintf(pfile, "%s}, flowControlStates);\n", tmpIntegerInput->name);
      else if (noIntegerInput > 1) {
        for (j = 0; j < noIntegerInput - 1; j++) {
          fprintf(pfile, "%s, ", tmpIntegerInput->name);
          tmpIntegerInput = tmpIntegerInput->next;
        }
        fprintf(pfile, "%s}, flowControlStates);\n",tmpIntegerInput->name);
      }
    }
    if (noBooleanInput > 0) {
      fprintf(pfile, "\tflowControlBooleanInput = fmuSetBooleanVR(fmufun, inst, %d, booleanVRInput",
          noBooleanInput);
      tmpBooleanInput = pntBooleanInput;
      fprintf(pfile, "\t, {");
      if (noBooleanInput == 1)
        fprintf(pfile, "%s}, flowControlStates);\n", tmpBooleanInput->name);
      else if (noBooleanInput > 1) {
        for (j = 0; j < noBooleanInput - 1; j++) {
          fprintf(pfile, "%s, ", tmpBooleanInput->name);
          tmpBooleanInput = tmpBooleanInput->next;
        }
        fprintf(pfile, "%s}, flowControlStates);\n",tmpBooleanInput->name);
      }
    }
    if (noStringInput > 0) {
      fprintf(pfile, "\tflowControlStringInput = fmuSetStringVR(fmufun, inst, %d, stringVRInput",
          noStringInput);
      tmpStringInput = pntStringInput;
      fprintf(pfile, "\t, {");
      if (noStringInput == 1)
        fprintf(pfile, "%s}, flowControlStates);\n", tmpStringInput->name);
      else if (noStringInput > 1) {
        for (j = 0; j < noStringInput - 1; j++) {
          fprintf(pfile, "%s, ", tmpStringInput->name);
          tmpStringInput = tmpStringInput->next;
        }
        fprintf(pfile, "%s}, flowControlStates);\n",tmpStringInput->name);
      }
    }

    if (fmuMD->ncs > 0) {
      fprintf(pfile, "\tflowControlStates = fmuSetContStates(fmufun, inst, %s, %s, flowControlTime);\n", nx, x);
      fprintf(pfile, "\tder(%s) = fmuGetDer(fmufun, inst, %s, %s, flowControlStatesInputs);\n", x, nx, x);
      fprintf(pfile, "\tflowControlEvent = fmuCompIntStep(fmufun, inst, stepEvt, flowControlStatesInputs);\n");
    }else{
      /* workaround for array with zero-elements
       * we need to call that function for our export
       */
      fprintf(pfile, "\tflowControlStates = fmuSetContStates(fmufun, inst, 0, {dummy}, flowControlTime + flowControlStart);\n");
      fprintf(pfile, "\tder(dummy) = 0;\n");
    }

    if (noReal > 0) {
      fprintf(pfile, "\trealV = fmuGetRealVR(fmufun, inst, %d, realVR, flowControlStatesInputs);\n",
          noReal);
      tmpReal = pntReal;
      fprintf(pfile, "\t{");
      if (noReal == 1)
        fprintf(pfile, "%s} = realV;\n", tmpReal->name);
      else if (noReal > 1) {
        for (j = 0; j < noReal - 1; j++) {
          fprintf(pfile, "%s, ", tmpReal->name);
          tmpReal = tmpReal->next;
        }
        fprintf(pfile, "%s} = realV;\n", tmpReal->name);
      }
    }

    if (noRealOutput > 0) {
      fprintf(pfile, "\trealVOutput = fmuGetRealVR(fmufun, inst, %d, realVROutput, flowControlStatesInputs);\n",
          noRealOutput);
      tmpRealOutput = pntRealOutput;
      fprintf(pfile, "\t{");
      if (noRealOutput == 1)
        fprintf(pfile, "%s} = realVOutput;\n", tmpRealOutput->name);
      else if (noRealOutput > 1) {
        for (j = 0; j < noRealOutput - 1; j++) {
          fprintf(pfile, "%s, ", tmpRealOutput->name);
          tmpRealOutput = tmpRealOutput->next;
        }
        fprintf(pfile, "%s} = realV;\n", tmpRealOutput->name);
      }
    }

    if (noInteger > 0) {
      fprintf(pfile,
          "\tintegerV = fmuGetIntegerVR(fmufun, inst, %d, integerVR, flowControlStatesInputs);\n",
          noInteger);
      tmpInteger = pntInteger;
      fprintf(pfile, "\t{");
      if (noInteger == 1)
        fprintf(pfile, "%s} = integerV;\n", tmpInteger->name);
      else if (noInteger > 1) {
        for (j = 0; j < noInteger - 1; j++) {
          fprintf(pfile, "%s, ", tmpInteger->name);
          tmpInteger = tmpInteger->next;
        }
        fprintf(pfile, "%s} = integerV;\n", tmpInteger->name);
      }
    }

    if (noIntegerOutput > 0) {
      fprintf(pfile, "\tintegerVOutput = fmuGetIntegerVR(fmufun, inst, %d, integerVROutput, flowControlStatesInputs);\n",
          noIntegerOutput);
      tmpIntegerOutput = pntIntegerOutput;
      fprintf(pfile, "\t{");
      if (noIntegerOutput == 1)
        fprintf(pfile, "%s} = integerVOutput;\n", tmpIntegerOutput->name);
      else if (noIntegerOutput > 1) {
        for (j = 0; j < noIntegerOutput - 1; j++) {
          fprintf(pfile, "%s, ", tmpIntegerOutput->name);
          tmpIntegerOutput = tmpIntegerOutput->next;
        }
        fprintf(pfile, "%s} = integerV;\n", tmpIntegerOutput->name);
      }
    }

    if (noBoolean > 0) {
      fprintf(pfile,
          "\tbooleanV = fmuGetBooleanVR(fmufun, inst, %d, booleanVR, flowControlStatesInputs);\n",
          noBoolean);
      tmpBoolean = pntBoolean;
      fprintf(pfile, "\t{");
      if (noBoolean == 1)
        fprintf(pfile, "%s} = booleanV;\n", tmpBoolean->name);
      else if (noBoolean > 1) {
        for (j = 0; j < noBoolean - 1; j++) {
          fprintf(pfile, "%s, ", tmpBoolean->name);
          tmpBoolean = tmpBoolean->next;
        }
        fprintf(pfile, "%s} = booleanV;\n", tmpBoolean->name);
      }
    }

    if (noBooleanOutput > 0) {
      fprintf(pfile, "\tbooleanVOutput = fmuGetBooleanVR(fmufun, inst, %d, booleanVROutput, flowControlStatesInputs);\n",
          noBooleanOutput);
      tmpBooleanOutput = pntBooleanOutput;
      fprintf(pfile, "\t{");
      if (noBooleanOutput == 1)
        fprintf(pfile, "%s} = booleanVOutput;\n", tmpBooleanOutput->name);
      else if (noBooleanOutput > 1) {
        for (j = 0; j < noBooleanOutput - 1; j++) {
          fprintf(pfile, "%s, ", tmpBooleanOutput->name);
          tmpBooleanOutput = tmpBooleanOutput->next;
        }
        fprintf(pfile, "%s} = booleanV;\n", tmpBooleanOutput->name);
      }
    }

    if (noString > 0) {
      fprintf(pfile,
          "\tstringV = fmuGetStringVR(fmufun, inst, %d, stringVR, flowControlStatesInputs);\n",
          noString);
      tmpString = pntString;
      fprintf(pfile, "\t{");
      if (noString == 1)
        fprintf(pfile, "%s} = stringV;\n", tmpString->name);
      else if (noString > 1) {
        for (j = 0; j < noString - 1; j++) {
          fprintf(pfile, "%s, ", tmpString->name);
          tmpString = tmpString->next;
        }
        fprintf(pfile, "%s} = stringV;\n", tmpString->name);
      }
    }

    if (noStringOutput > 0) {
      fprintf(pfile, "\tstringVOutput = fmuGetStringVR(fmufun, inst, %d, stringVROutput, flowControlStatesInputs);\n",
          noStringOutput);
      tmpStringOutput = pntStringOutput;
      fprintf(pfile, "\t{");
      if (noStringOutput == 1)
        fprintf(pfile, "%s} = stringVOutput;\n", tmpStringOutput->name);
      else if (noStringOutput > 1) {
        for (j = 0; j < noStringOutput - 1; j++) {
          fprintf(pfile, "%s, ", tmpStringOutput->name);
          tmpStringOutput = tmpStringOutput->next;
        }
        fprintf(pfile, "%s} = stringV;\n", tmpStringOutput->name);
      }
    }

    if (fmuMD->nei > 0) {
      fprintf(pfile, "\t%s = fmuGetEventInd(fmufun, inst, %s);\n", z, nz);
    }

    fprintf(pfile, "algorithm\n");
    fprintf(pfile, "\tflowhack := flowControlEvent;\n");

#ifdef _DEBUG_MODELICA
    fprintf(pfile,"\tprintVariable(time, 1, \"time\");\n");
    fprintf(pfile,"\tprintVariable(%s, %s, \"nx\");\n",x,nx);
#endif

    if (fmuMD->nei > 0) {
      //fprintf(pfile, "\t%s:=%s;\n", prez, z);
      for (j = 1; j <= fmuMD->nei; j++) {
        fprintf(pfile, "\t%s[%d] := %s[%d]>0;\n", flagSE, j, z, j);
        /*
         fprintf(pfile, "\t%s[%d] := change(%s[%d]);\n", indSE, j,
         flagSE, j);
         fprintf(pfile, "\t%s[%d] := %s[%d] * %s[%d];\n", zXprez, j, z,
         j, prez, j);
         */
      }
      fprintf(pfile, "\twhen (");
      for (j = 1; j <= fmuMD->nei - 1; j++) {
        fprintf(pfile, "change(%s[%d]) or ", flagSE, j);
      }
      fprintf(pfile, "change(%s[%d])) and not initial() then\n", flagSE, j);
      fprintf(
          pfile,
          "\t\tfmuEvtUpdate(fmufun, inst, evtInfo, timeEvt, stepEvt, stateEvt, interMediateRes);\n");
      //fprintf(pfile,"\tend when;\n");
      /*fprintf(pfile,"algorithm \n");
       fprintf(pfile, "\tflowhack4 := flowhack3*time;\n");
       fprintf(pfile, "\tfmuStateEvtCheck(stateEvt, %s, %s, save_%s);\n", nz, z,
       prez);
       */
      if (fmuMD->ncs > 0) {
        fprintf(pfile, "\t\t%s:=fmuGetContStates(fmufun, inst, %s);\n", out_x, nx);
        /*fprintf(pfile, "\t%s:=fmuGetDer(fmufun, inst, %s, %s);\n",
         out_der_x, nx, out_x);
         */
      }
      for (j = 1; j <= fmuMD->ncs; j++) {
        fprintf(pfile, "\t\treinit(%s[%d], %s[%d]);\n", x, j, out_x, j);
        /*fprintf(pfile, "\t\treinit(%s[%d], %s[%d]);\n", der_x, j,
         out_der_x, j);
         */
      }
      fprintf(pfile, "\tend when;\n");
    }


    /*
    fprintf(pfile,"equation\n");
    fprintf(pfile, "\twhen terminal() then\n");
    fprintf(pfile,"\t\t freeAll = fmuFreeAll(inst, fmufun, functions);\n");
    fprintf(pfile, "\tend when;\n");
    */

    fputs("end FMUBlock;\n", pfile);
    fprintf(pfile, "end FMUImport_%s;\n", fmuMD->mid);
  }

  /* Free memory */
  free(id);
  free((void*) x);
  free((void*) nx);
  free((void*) out_x);
  free((void*) der_x);
  free((void*) out_der_x);
  free((void*) nz);
  free((void*) z);
  free((void*) prez);
  free((void*) zXprez);
  free((void*) y);
  free((void*) flagSE);
  free((void*) indSE);
  free((void*) defaultVar);
  /*
   free(pntReal);
   free(tmpReal);
   free(pntInteger);
   free(tmpInteger);
   free(pntBoolean);
   free(tmpBoolean);
   free(pntString);
   free(tmpString);
   */
  fclose(pfile);
}

void printUsage() {
  printf("Usage: fmigenerator [--fmufile=NAME] [--outputdir=PATH]\n");
  printf(
      "--fmufile  The FMU file that contains the model description to be imported.\n");
  printf("--outputdir The output directory.");
}

int main(int argc, char *argv[]) {
  /* Declaration of variables */
  size_t nsv; /* number of scalar variables */
  fmiScalarVariable* list = NULL; /* list of fmiScalarVariable; */
  fmiModelVariable* fmuMV = NULL; /* pointer to model variables */
  fmuModelDescription* fmuMD = (fmuModelDescription*) calloc(1,
      sizeof(fmuModelDescription)); // pointer to the tree-like structure of paresed xml
  char omPath[PATHSIZE]; /* OpenModelica installation directory */
  /* Allocated memory needed to be freed or file needed to be closed */
  FILE* logFile;
  const char * fmuname; /* name of the fmu file <fmuname>.fmu */
  ModelDescription* md = NULL; /* handle to the parsed XML file */
  const char * decompPath = NULL; /* name of the decompression path */
  const char * xmlFile = NULL; /* model description xml file name */
  const char * fmuDllPath = NULL; /* dll path */

  /* Creating log file */
  errLogFile = fopen("fmuImportError.log", "w");
  if (!errLogFile) {
    printf(
        "#### %s, %s, %d, : Error: Creating file fmuImportError.log failed...\n",
        __DATE__, __TIME__, __LINE__);
    exit(EXIT_FAILURE);
  }
  printf("\n\n");

  if (argc < 3) {
    printUsage();
    ERRORPRINT;
    fprintf(errLogFile, "#### Wrong arguments passed to main entry...%s\n", "");
    exit(EXIT_FAILURE);
  } else if (strcasecmp(argv[1], "-h") == 0) {
    printUsage();
    exit(EXIT_FAILURE);
  } else if (strcasecmp(argv[1], "--help") == 0) {
    printUsage();
    exit(EXIT_FAILURE);
  }

  // Attaining the name of the FMU from the argument
  // Decompressing the archive into an appropriate directory
  // Get the model description xml file name
  if (strncmp(argv[1], "--fmufile=", 10) == 0) {
    fmuname = getFMUname(argv[1] + 10);
  } else {
    printUsage();
    ERRORPRINT;
    fprintf(errLogFile, "#### Specify the FMU file...%s\n", "");
    exit(EXIT_FAILURE);
  }
#ifdef _DEBUG_
  printf("#### fmuname: %s\n",fmuname);
#endif
  if (strncmp(argv[2], "--outputdir=", 12) == 0) {
    decompPath = (char*) calloc((strlen(argv[2]) - 10), sizeof(char));strncpy((char*)decompPath, argv[2] + 12, strlen(argv[2]) - 11);
    strcat((char*) decompPath, "/");
  } else {
      printUsage();
      ERRORPRINT;
      fprintf(
          errLogFile,
          "#### Invalid output directory. Wrong argument for decompression path...%s\n",
          "");
      exit(EXIT_FAILURE);
    }
  if (decompPath == NULL) {
    printf("#### path for decompression is not available: decompPath = %s\n",
        "NULL");
    ERRORPRINT;
    fprintf(errLogFile,
        "#### path for decompression is not available: decompPath = %s\n",
        "NULL");
    exit(EXIT_FAILURE);
  }
#ifdef _DEBUG_
  printf("#### %s decompPath: %s\n",QUOTEME(__LINE__),decompPath);
#endif
  decompress(argv[1] + 10, decompPath);
  xmlFile = getNameXMLfile(decompPath, MODEL_DESCRIPTION);
  if (xmlFile == NULL) {
    printf("#### model description xml file is not available: xmlFile = %s\n",
        "NULL");
    ERRORPRINT;
    fprintf(errLogFile,
        "#### model description xml file is not available: xmlFile = %s\n",
        "NULL");
    exit(EXIT_FAILURE);
  }

  /* Parsing the model description file as a tree-like structure */
  md = parse(xmlFile);
  if (md == NULL) {
    printf("#### parsing model description xml file occurred error: md = %s\n",
        "NULL");
    ERRORPRINT;
    fprintf(errLogFile,
        "#### parsing model description xml file occurred error: md = %s\n",
        "NULL");
    exit(EXIT_FAILURE);
  }

  /* Creating the tree-like data structure for code generation */
  nsv = getNumberOfSV(md);
  if (nsv > 0) {
    list = (fmiScalarVariable*) calloc(nsv, sizeof(fmiScalarVariable));
    instScalarVariable(md, list);
  } else {
    printf("#### There is no scalar variable in the model %s\n", fmuname);
    ERRORPRINT;
    fprintf(errLogFile, "#### There is no scalar variable in the model %s\n",
        fmuname);
    exit(EXIT_FAILURE);
  }
  fmuMV = (fmiModelVariable*) calloc(1, sizeof(fmiModelVariable));
  fmuMV->list_sv = list;
  fmuMV->nsv = nsv;
  instFmuModelDescription(md, fmuMD, fmuMV);
  // end

# ifdef _DEBUG_
  printf("#### sizeof(fmiScalarVariable): %d, sizeof(list): %d\n",sizeof(fmiScalarVariable),sizeof(list));
#endif
  fmuDllPath = getDllPath(decompPath, fmuMD->mid);
# ifdef _DEBUG_
  printf("#### fmuDllPath is: %s\n",fmuDllPath);
#endif
  // Code generation
  tmpcodegen(fmuMD, decompPath);
  blockcodegen(fmuMD, decompPath, fmuDllPath);
#ifdef PRINT_INFORMATION
  printf("#### ModelIdentifier fmuMD->mid = %s\n",fmuMD->mid);
  printf("#### fmuMD->guid = %s\n",fmuMD->guid);
  printf("#### NumberOfStates fmuMD->ncs = %d\n",fmuMD->ncs);
  printf("#### NumberOfEventIndicators fmuMD->nei = %d\n",fmuMD->nei);
  printf("#### NumberOfScalarVariables fmuMD->modelVariable->nsv = %d\n",fmuMD->modelVariable->nsv);
#endif
  // end
#ifdef _IMPORT_LOG_
  logFile = fopen("fmuImport.log", "w");
  LOGPRINT("FMU decompression path: %s\n", decompPath);
  LOGPRINT("FMU name: %s\n", fmuname);
  LOGPRINT("FMU model identifier: %s\n", fmuMD->mid);
  LOGPRINT("Modelica model name: %sFMUImport.mo\n", fmuMD->mid);
#endif
  // Free allocated and close file memory
  free((void*) xmlFile);
  free((void*) fmuDllPath);
  free((void*) fmuname);
  free((void*) decompPath);
  free(list);
  freeScalarVariableLst(list, nsv);
  freeElement((void*) md);
  fclose(errLogFile);
  fclose(logFile);
  // end
  //system("PAUSE");
  return EXIT_SUCCESS;
}
