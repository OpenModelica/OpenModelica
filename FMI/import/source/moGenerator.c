#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "moGenerator.h"

#define QUOTEME_(x) #x
#define QUOTEME(x) QUOTEME_(x)
//#define _DEBUG_ 1
//#define _DEBUG_MODELICA 1

#define FMU_BINARIES_Win32 "binaries\\win32\\"
#define BUFFERSIZE 4096
#define PATHSIZE 1024

#define MODEL_DESCRIPTION "modelDescription.xml"

#define USE_UNZIP
#define DECOMPRESS_CMD "7z x -aoa -o"
// return codes of the 7z command line tool
#define SEVEN_ZIP_NO_ERROR 0 // success
#define SEVEN_ZIP_WARNING 1  // e.g., one or more files were locked during zip
#define SEVEN_ZIP_ERROR 2
#define SEVEN_ZIP_COMMAND_LINE_ERROR 7
#define SEVEN_ZIP_OUT_OF_MEMORY 8
#define SEVEN_ZIP_STOPPED_BY_USER 255
// Search a variable in an fmu structure for the given value reference
// return NULL, if (not found) || (vr = fmiUndefinedValueReference)
// static ScalarVariable* getSV(FMU *fmu, char type, fmiValueReference vr) {
// int i;
// Elm tp;
// ScalarVariable** vars = fmu->modelDescription->modelVariables;
// if (vr==fmiUndefinedValueReference) return NULL;
// switch (type) {
// case 'r': tp = elm_Real;    break;
// case 'i': tp = elm_Integer; break;
// case 'b': tp = elm_Boolean; break;
// case 's': tp = elm_String;  break;
// }
// for (i=0; vars[i]; i++) {
// ScalarVariable* sv = vars[i];
// if (vr==getValueReference(sv) && tp==sv->typeSpec->type)
// return sv;
// }
// return NULL;
// }
static char* getFMUname(const char* fmupath) {
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

  fmuname = (char*) calloc(sizeof(char), tmp - i + 1);
  strncpy(fmuname, &fmupath[i + 1], tmp - i);

#ifdef _DEBUG_
  printf("#### fmuname is: %s\n",fmuname);
#endif

  return fmuname;
}

static char* getDllPath(const char* decompPath, const char* mid) {
  char * fmudllpath;
  char * pch;
  char * ret_fmudllpath;
  int i;

  int lenStr1 = strlen(FMU_BINARIES_Win32) + strlen(decompPath) + strlen(mid)
      + 4 + 1;
  char tmpStr[lenStr1];
  int lenStr2 = 0;
  int strcount = 0;
  fmudllpath = (char*) calloc(sizeof(char), lenStr1);
  strcpy(fmudllpath, decompPath);
  strcat(fmudllpath, FMU_BINARIES_Win32);
  strcat(fmudllpath, mid);
  strcat(fmudllpath, ".dll");
  strcpy(tmpStr, fmudllpath);

  pch = strtok(fmudllpath, "\\");
  while (pch != NULL) {
#ifdef _DEBUG_
    printf("#### string token: %s\n",pch);
#endif
    lenStr2 += strlen(pch);
    strcount++;
#ifdef _DEBUG_
    printf("#### lenStr2 = %d\n",lenStr2);
    printf("#### strcount = %d\n",strcount);
#endif
    pch = strtok(NULL, "\\");
  }
  ret_fmudllpath = (char*) calloc(sizeof(char), lenStr2 + (strcount - 1) * 2);
  pch = strtok(tmpStr, "\\");

  for (i = 1; i < strcount; i++) {
    strcat(ret_fmudllpath, pch);
    strcat(ret_fmudllpath, "\\\\");
    pch = strtok(NULL, "\\");

#ifdef _DEBUG_
    printf("#### ret_fmudllpath = %s\n",ret_fmudllpath);
#endif
  }
  strcat(ret_fmudllpath, pch);

#ifdef _DEBUG_
  printf("#### ret_fmudllpath = %s\n",ret_fmudllpath);
  printf("#### strlen(ret_fmudllpath) = %d\n",strlen(ret_fmudllpath));
#endif

  free(pch);
  free(fmudllpath);

  return ret_fmudllpath;
}

static char* getXMLfile(const char * decompPath, const char * modeldes) {
  char * xmlfile;
  xmlfile = (char*) calloc(sizeof(char),
      strlen(decompPath) + strlen(modeldes) + 1);
  strcpy(xmlfile, decompPath);
  strcat(xmlfile, modeldes);
  return xmlfile;
}
static char* getDecompPath(const char * omPath, const char* mid) {
  int n;
  char * decompPath;

  if (!GetEnvironmentVariable("OPENMODELICAHOME", omPath, PATHSIZE)) {
    if (GetLastError() == ERROR_ENVVAR_NOT_FOUND) {
      printf(
          "#### %s Error: Environment variable \"OPENMODELICAHOME\" not defined\n",
          QUOTEME(__LINE__));
    }
    else {
      printf("#### %s Error: Could not get value of \"OPENMODELICAHOME\"\n",
          QUOTEME(__LINE__));
    }
    exit(EXIT_FAILURE); // error
  }
#ifdef _DEBUG_
  printf("#### %s Enviroment: %s\n",QUOTEME(__LINE__),omPath);
#endif
  n = strlen(omPath) + strlen(mid) + 6;
  decompPath = (char*) calloc(sizeof(char), n);
  sprintf(decompPath, "%sfmu\\%s\\", omPath, mid);
#ifdef _DEBUG_
  printf("#### %s decompPath: %s\n",QUOTEME(__LINE__),decompPath);
#endif
  return decompPath;
}

// Decompresion of the given fmu
static int decompress(const char* fmuPath, const char* decompPath) {
  int err;
  int n;
  char * cmd; // needed to be freed

#ifdef USE_UNZIP
  n = strlen(fmuPath) + strlen(decompPath) + 17;
  cmd = (char*) calloc(sizeof(char), n);
  sprintf(cmd, "unzip -o \"%s\" -d \"%s\"", fmuPath, decompPath);
  err = system(cmd);
  free(cmd); // free
#else
  n = strlen(DECOMPRESS_CMD) + strlen(fmuPath) +strlen(decompPath)+10;
  cmd = (char*)calloc(sizeof(char),n);
  sprintf(cmd, "%s%s \"%s\" > NUL", DECOMPRESS_CMD, decompPath, fmuPath);
  err = system(cmd);
  free(cmd); // free
  if (err!=SEVEN_ZIP_NO_ERROR) {
    switch (err) {
      printf("#### 7z: ");
      case SEVEN_ZIP_WARNING: printf("warning\n"); break;
      case SEVEN_ZIP_ERROR: printf("error\n"); break;
      case SEVEN_ZIP_COMMAND_LINE_ERROR: printf("command line error\n"); break;
      case SEVEN_ZIP_OUT_OF_MEMORY: printf("out of memory\n"); break;
      case SEVEN_ZIP_STOPPED_BY_USER: printf("stopped by user\n"); break;
      default: printf("unknown problem\n");
    }
  }
#endif
  return EXIT_SUCCESS;
}

// return the number of scalar variables contained in
// the ModelVariables entity, return -1 for error
static int getNumberOfSV(ModelDescription* md) {
  int i;
  if (md->modelVariables) {
    for (i = 0; md->modelVariables[i]; i++)
      ;
    return i;
  }
  else
    return -1;
}

// get element type
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
      printf("#### unknown element type in ScalarVaraible...\n");
      exit(EXIT_FAILURE);
  }
}

// allocate memory for element contained in scalar variables
void* allocateElmSV(fmiScalarVariable fmisv) {
  switch (fmisv.type) {
    case sv_real:
      return calloc(sizeof(fmiREAL), 1);
    case sv_integer:
      return calloc(sizeof(fmiINTEGER), 1);
    case sv_boolean:
      return calloc(sizeof(fmiBOOLEAN), 1);
    case sv_string:
      return calloc(sizeof(fmiSTRING), 1);
    case sv_enum:
      return NULL;
    default:
      printf("#### Line %s: unknown element type in allocateElmSV()...\n",
          QUOTEME(__LINE__));
      exit(EXIT_FAILURE);
  }
}

// instantiation of element in scalar variable, e.g. Real, Integer, ect..
void instElmSV(ScalarVariable* sv, fmiScalarVariable fmisv) {
  ValueStatus vs;
  double tmp_db;
  int tmp_i;
  fmiBooleanXML tmp_bl;

  switch (fmisv.type) {
    case sv_real: {
      tmp_db = getDouble(sv->typeSpec, att_start, &vs);
      ((fmiREAL*) fmisv.variable)->start = (vs == valueDefined ? tmp_db : 0.0);

      tmp_bl = getBoolean(sv->typeSpec, att_fixed, &vs);
      ((fmiREAL*) fmisv.variable)->fixed = (vs == valueDefined ? tmp_bl : 0);

      tmp_db = getDouble(sv->typeSpec, att_nominal, &vs);
      ((fmiREAL*) fmisv.variable)->nominal
          = (vs == valueDefined ? tmp_db : 1.0);
      break;
    }
    case sv_integer: {
      tmp_i = getInt(sv->typeSpec, att_start, &vs);
      ((fmiINTEGER*) fmisv.variable)->start = (vs == valueDefined ? tmp_i : 0);

      tmp_bl = getBoolean(sv->typeSpec, att_fixed, &vs);
      ((fmiINTEGER*) fmisv.variable)->fixed = (vs == valueDefined ? tmp_bl : 0);

      break;
    }
    case sv_boolean: {
      tmp_bl = getBoolean(sv->typeSpec, att_start, &vs);
      ((fmiBOOLEAN*) fmisv.variable)->start = (vs == valueDefined ? tmp_bl : 0);

      tmp_bl = getBoolean(sv->typeSpec, att_fixed, &vs);
      ((fmiBOOLEAN*) fmisv.variable)->fixed = (vs == valueDefined ? tmp_bl : 0);
      break;
    }
    case sv_string: {
      ((fmiSTRING*) fmisv.variable)->start = getString(sv->typeSpec, att_start);

      tmp_bl = getBoolean(sv->typeSpec, att_fixed, &vs);
      ((fmiSTRING*) fmisv.variable)->fixed = (vs == valueDefined ? tmp_bl : 0);
      break;
    }
    default:
      printf("#### Line %s: unknown error in instElmSV()...\n",
          QUOTEME(__LINE__));
      exit(EXIT_FAILURE);
  }
}

// instantiation of fmiScalarVariable list
static void instScalarVariable(ModelDescription* md, fmiScalarVariable* list) {
  int i;
  if (md->modelVariables) {
    for (i = 0; md->modelVariables[i]; i++) {
      list[i].name = getName(md->modelVariables[i]);
      list[i].vr = getValueReference(md->modelVariables[i]);
      list[i].description = getDescription(md, md->modelVariables[i]);

#ifdef _DEBUG_
      printf("#### descritpion of sv %s, %s, value reference: %d\n",list[i].name, list[i].description,list[i].vr );
#endif

      list[i].var = getVariability(md->modelVariables[i]);
      list[i].causality = getCausality(md->modelVariables[i]);
      list[i].alias = getAlias(md->modelVariables[i]);
      list[i].type = getElementType(md->modelVariables[i]);

#ifdef _DEBUG_
      printf("#### sv.typeSpec.type: %d\n",list[i].type);
#endif

      list[i].variable = allocateElmSV(list[i]);
      instElmSV(md->modelVariables[i], list[i]);
#ifdef _DEBUG_
      if(list[i].type==0)
      printf("#### %s startvalue: %f\n", list[i].name,((fmiREAL*)list[i].variable)->start);
      if(list[i].type==1)
      printf("#### %s startvalue: %f\n", list[i].name,((fmiINTEGER*)list[i].variable)->start);
      if(list[i].type==2)
      printf("#### %s startvalue: %f\n", list[i].name,((fmiBOOLEAN*)list[i].variable)->start);
#endif
    };
    return;
  }
  else {
    printf(
        "#### instScalarVariable failed: no modelVariable defined or memory error...\n");
    exit(EXIT_FAILURE);
  }
}

// free memory for scalar variable list
void freeScalarVariableLst(fmiScalarVariable* list, int nsv) {
  int i;
  for (i = 0; i < nsv; i++) {
    free(list[i].variable);
  }
  free(list);
}
// Modelica code generation for the external functions
void tmpcodegen(size_t nx, size_t nz, const char* mid, const char* guid,
    const char* decompPath) {

  // Allocated memory needed to be freed
  FILE * pfile;
  char * id;

  size_t len = strlen(mid) + strlen(decompPath);
  id = (char*) malloc(len + 4);
  strcpy(id, decompPath);
  strcat(id, mid);
  strcat(id, ".mo");

#ifdef _DEBUG_
  printf("#### %s id = %s\n",QUOTEME(__LINE__),id);
#endif

  pfile = fopen(id, "w");
  if (!pfile) {
#ifdef _DEBUG_
    printf("#### Creating %s failed...\n",id);
#endif

    exit(EXIT_FAILURE);
  }
  else {
    fprintf(pfile, "\npackage FMUImport_%s\n", mid);
    /*
     * No need of fmuModelica.tmp
     * since the makefile create the header file from it and then we assign that header FMU_TEMPLATE_STR
     */
    const char *FMU_TEMPLATE_STR =
    #include "fmuModelica.h"
    ;
    fputs(FMU_TEMPLATE_STR, pfile);
  }
  // Free memory
  fclose(pfile);
  free(id);
}

// Modelica code generation for the FMU block
void blockcodegen(ModelDescription* md, size_t nx, size_t nz, const char* mid,
    const char* guid, const char* decompPath, const char* fmudllpath) {
  // Allocated memory needed to be freed
  char * id;
  FILE * pfile;
  int j;
  double StartTime = 0.0;
  double StopTime = 3.0;
  double Tolerance = 0.0001;
  size_t len = strlen(mid) + strlen(decompPath);
  id = (char*) malloc(len + 4);
  strcpy(id, decompPath);
  strcat(id, mid);
  strcat(id, ".mo");

  pfile = fopen(id, "a+");

  if (!pfile) {
    printf("#### Creating %s failed...\n", id);
    exit(EXIT_FAILURE);
  }
  else {
    fprintf(pfile, "\nblock FMUBlock \"%s model\"\n", mid);
    fprintf(
        pfile,
        "\tannotation(experiment(StartTime = %f, StopTime = %f, Tolerance = %f));\n",
        StartTime, StopTime, Tolerance);
    fprintf(pfile, "\toutput Real y[%d];\n", nx);
    fprintf(pfile, "\tconstant String dllPath = \"%s\";\n", fmudllpath);
    fprintf(pfile, "\tconstant String instName = \"%s\";\n", mid);
    fprintf(pfile, "\tconstant String guid = \"%s\";\n", guid);
    fprintf(pfile, "\tparameter Boolean logFlag = false;\n");
    fprintf(pfile, "\tparameter Boolean tolControl = true;\n");
    if (nx > 0) {
      fprintf(pfile, "\tparameter Integer nx = %d;\n", nx);
      fprintf(pfile, "\tReal der_x[nx];\n");
      fprintf(pfile, "\tReal out_x[nx];\n");
      fprintf(pfile, "\tReal out_der_x[nx];\n");
      fprintf(pfile, "\treplaceable Real x[nx];\n");
    }
    if (nz > 0) {
      fprintf(pfile, "\tparameter Integer nz = %d;\n", nz);
      fprintf(pfile, "\tReal z[nz];\n");
      fprintf(pfile, "\tReal prez[nz];\n");
      fprintf(pfile, "\tReal zXprez[nz];\n");
      fprintf(pfile, "\tBoolean flagSE[nz] \"flag for state events\";\n");
      fprintf(pfile, "\tBoolean indSE[nz] \"indicator for state events\";\n");
    }
    fprintf(pfile, "\treplaceable parameter Real relTol = 0.0001;\n");
    fprintf(pfile, "\tparameter Integer default = 0;\n");
    fprintf(pfile, "\tparameter Integer valueRef[2] = {1,3};\n");
    fprintf(pfile, "protected\n");
    fprintf(
        pfile,
        "\tfmuModelInst inst = fmuModelInst(fmufun, instName, guid, functions, logFlag);\n");
    fprintf(pfile, "\tfmuEventInfo evtInfo = fmuEventInfo();\n");
    fprintf(pfile, "\tfmuBoolean timeEvt = fmuBoolean(default);\n");
    fprintf(pfile, "\tfmuBoolean stepEvt = fmuBoolean(default);\n");
    fprintf(pfile, "\tfmuBoolean stateEvt = fmuBoolean(default);\n");
    fprintf(pfile, "\tfmuBoolean interMediateRes = fmuBoolean(default);\n");
    //fprintf(pfile,"\tfmuBoolean freeAll = fmuBoolean(default);\n");
    fprintf(pfile, "\tfmuFunctions fmufun = fmuFunctions(\"%s\",dllPath);\n",
        mid);
    fprintf(pfile, "\tfmuCallbackFuns functions = fmuCallbackFuns();\n");
    fprintf(pfile, "initial algorithm\n");
    fprintf(pfile, "\tfmuSetTime(fmufun, inst, time);\n");
    fprintf(pfile, "\tfmuInit(fmufun, inst, tolControl, relTol, evtInfo);\n");
    if (nx > 0) {
      fprintf(pfile, "\tx:=fmuGetContStates(fmufun, inst, nx);\n");

#ifdef _DEBUG_MODELICA
      fprintf(pfile,"\tprintVariable(x, nx, \"x, initial algorithm\");\n");
#endif

      fprintf(pfile, "algorithm \n");
      fprintf(pfile, "\tder_x:=fmuGetDer(fmufun, inst, nx, x);\n");
      fprintf(pfile, "\ty:=der_x;\n");
      fprintf(pfile, "equation\n");
      fprintf(pfile, "\tder(x) = der_x;\n");
      fprintf(pfile, "algorithm\n");
      fprintf(pfile, "\tfmuSetContStates(fmufun, inst, nx, x);\n");

#ifdef _DEBUG_MODELICA
      fprintf(pfile,"\tprintVariable(time, 1, \"time\");\n");
      fprintf(pfile,"\tprintVariable(x, nx, \"nx\");\n");
#endif
    }
    fprintf(pfile, "\tfmuCompIntStep(fmufun, inst, stepEvt);\n");
    if (nz > 0) {
      fprintf(pfile, "\tprez:=z;\n");
      fprintf(pfile, "\tz:=fmuGetEventInd(fmufun, inst, nz);\n");

      for (j = 1; j <= nz; j++) {
        fprintf(pfile, "\tflagSE[%d]:=z[%d]>0;\n", j, j);
        fprintf(pfile, "\tindSE[%d]:=change(flagSE[%d]);\n", j, j);
        fprintf(pfile, "\tzXprez[%d]:=z[%d] * prez[%d];\n", j, j, j);
      }
      fprintf(pfile, "algorithm \n");
      fprintf(pfile, "\tfmuStateEvtCheck(stateEvt, nz, z, prez);\n");
    }
    fprintf(
        pfile,
        "\tfmuEvtUpdate(fmufun, inst, evtInfo, timeEvt, stepEvt, stateEvt, interMediateRes);\n");
    if (nx > 0) {
      fprintf(pfile, "\tout_x:=fmuGetContStates(fmufun, inst, nx);\n");
      fprintf(pfile, "\tout_der_x:=fmuGetDer(fmufun, inst, nx, out_x);\n");
      fprintf(pfile, "equation\n");
      fprintf(pfile, "\twhen indSE then\n");
      for (j = 1; j <= nx; j++) {
        fprintf(pfile, "\t\treinit(x[%d], out_x[%d]);\n", j, j);
        fprintf(pfile, "\t\treinit(der_x[%d], out_der_x[%d]);\n", j, j);
      }
    }
    fprintf(pfile, "\tend when;\n");
    // fprintf(pfile,"equation\n");
    fprintf(pfile, "\twhen terminal() then\n");
    //fprintf(pfile,"\t\t freeAll:=fmuFreeAll(inst, fmufun, functions);\n");
    fprintf(pfile, "\tend when;\n");
    fputs("end FMUBlock;\n", pfile);
    fprintf(pfile, "end FMUImport_%s;\n", mid);
  }

  // Free memory
  free(id);
  fclose(pfile);
}

void printUsage() {
  printf("Usage: fmigenerator [--fmufile=NAME] [--outputdir=PATH]\n");
  printf("--fmufile	The FMU file that contains the model description to be imported.\n");
  printf("--outputdir	The output directory.");
}

int main(int argc, char *argv[]) {
  if (argc < 2) {
    printUsage();
    return EXIT_FAILURE;
  }
  else if (strcasecmp(argv[1], "-h") == 0) {
    printUsage();
    return EXIT_FAILURE;
  }
  else if (strcasecmp(argv[1], "--help") == 0) {
    printUsage();
    return EXIT_FAILURE;
  }

  size_t nx; // number of state variables
  size_t nz; // number of state event indicators
  size_t nsv; // number of scalar variables
  fmiScalarVariable* list = NULL; // list of fmiScalarVariable;
  char omPath[PATHSIZE]; // OpenModelica installation directory
  // Allocated memory needed to be freed
  const char * fmuname; // name of the fmu file <fmuname>.fmu
  ModelDescription* md = NULL; // handle to the parsed XML file
  const char* mid = NULL;
  const char* guid = NULL; // global unique id of the fmu
  const char * decompPath = 0;
  const char * xmlFile = NULL;
  const char * fmuDllPath = NULL;
  printf("\n\n");
  if (strncmp(argv[1], "--fmufile=", 10) == 0) {
    fmuname = getFMUname(argv[1] + 10);
  }
  if (argc > 2) {
    if (strncmp(argv[2], "--outputdir=", 12) == 0) {
      decompPath = (char*) malloc(strlen(argv[2]) - 11);
      strcpy((char*)decompPath, argv[2] + 12);
      strcat((char*)decompPath, "/");
      if (access(decompPath, F_OK) == -1) {
        free((char*) decompPath);
        decompPath = getDecompPath(omPath, fmuname);
      }
    }
  }
  else {
    decompPath = getDecompPath(omPath, fmuname);
  }
#ifdef _DEBUG_
  printf("#### %s decompPath: %s\n",QUOTEME(__LINE__),decompPath);
#endif
  decompress(argv[1] + 10, decompPath);
  xmlFile = getXMLfile(decompPath, MODEL_DESCRIPTION);
  md = parse(xmlFile);
  mid = getModelIdentifier(md);
  guid = getString(md, att_guid);
  nx = getNumberOfStates(md);
  nz = getNumberOfEventIndicators(md);
  nsv = getNumberOfSV(md);
  list = (fmiScalarVariable*) calloc(sizeof(fmiScalarVariable), nsv);
  instScalarVariable(md, list);

# ifdef _DEBUG_
  printf("#### sizeof(fmiScalarVariable): %d, sizeof(list): %d\n",sizeof(fmiScalarVariable),sizeof(list));
#endif
  fmuDllPath = getDllPath(decompPath, mid);
  printf("#### fmuDllPath is: %s\n", fmuDllPath);
  tmpcodegen(nx, nz, mid, guid, decompPath);
  blockcodegen(md, nx, nz, mid, guid, decompPath, fmuDllPath);
  // size_t nr = getNumberOfReal();
  // size_t ni = getNumberOfInteger();
  // size_t nb = getNumberOfBoolean();
  // size_t ns = getNumberOfString();
  printf("#### ModelIdentifier mid = %s\n", mid);
  printf("#### guid = %s\n", guid);
  printf("#### NumberOfStates nx = %d\n", nx);
  printf("#### NumberOfEventIndicators ni = %d\n", nz);
  printf("#### NumberOfScalarVariables nsv = %d\n", nsv);

  // Free memory
  /* uncommenting it SEGFAULTS. Wuzhu fix your memory allocations.. */
  /*free((void*) xmlFile);
  free((void*) fmuDllPath);
  free((void*) fmuname);
  free((void*) decompPath);
  free(list);
  freeScalarVariableLst(list, nsv);
  freeElement((void*) md);*/
  return EXIT_SUCCESS;
}
