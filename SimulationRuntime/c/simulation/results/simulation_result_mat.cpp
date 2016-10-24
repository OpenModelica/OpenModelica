/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

#include "util/omc_error.h"
#include "util/rtclock.h"
#include "simulation/options.h"
#include "simulation_result_mat.h"

#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <utility>
#include <cstring>
#include <cstdlib>
#include <stdint.h>
#include <assert.h>

extern "C" {

typedef std::pair<void*,int> indx_type;
typedef std::map<int,int> INTMAP;

typedef struct mat_data {
  std::ofstream fp;
  std::ofstream::pos_type data1HdrPos; /* position of data_1 matrix's header in a file */
  std::ofstream::pos_type data2HdrPos; /* position of data_2 matrix's header in a file */
  unsigned long ntimepoints; /* count of how many time emits() was called */
  double startTime; /* the start time */
  double stopTime;  /* the stop time */

  INTMAP r_indx_map;
  INTMAP r_indx_parammap;
  INTMAP i_indx_map;
  INTMAP i_indx_parammap;
  INTMAP b_indx_map;
  INTMAP b_indx_parammap;

  unsigned int negatedboolaliases;
  int numVars;
  int numParams;
} mat_data;

static long flattenStrBuf(int dims, const struct VAR_INFO** src, char* &dest, int& longest, int& nstrings, bool fixNames, bool useComment);
static void mat_writeMatVer4MatrixHeader(simulation_result *self,DATA *data, threadData_t *threadData,const char *name, int rows, int cols, unsigned int size);
static void mat_writeMatVer4Matrix(simulation_result *self,DATA *data, threadData_t *threadData, const char *name, int rows, int cols, const void *, unsigned int size);
static void generateDataInfo(simulation_result *self,DATA *data, threadData_t *threadData,int* &dataInfo, int& rows, int& cols, int nVars, int nParams);
static void generateData_1(DATA *data, threadData_t *threadData, double* &data_1, int& rows, int& cols, double tstart, double tstop);

static int calcDataSize(simulation_result *self,DATA *data);
static int calcParamsSize(simulation_result *self, DATA *data);
static const VAR_INFO** calcDataNames(simulation_result *self,DATA *data,int dataSize);

static const struct VAR_INFO timeValName = {0,-1,"time","Simulation time [s]",{"",-1,-1,-1,-1}};
static const struct VAR_INFO cpuTimeValName = {0,-1,"$cpuTime","cpu time [s]",{"",-1,-1,-1,-1}};
static const struct VAR_INFO solverStepsValName = {0,-1,"$solverSteps","number of steps taken by the integrator",{"",-1,-1,-1,-1}};

static int calcDataSize(simulation_result *self,DATA *data)
{
  mat_data *matData = (mat_data*) self->storage;
  const MODEL_DATA *modelData = data->modelData;

  int sz = 1; /* start with one for the timeValue */

  if(self->cpuTime)
    sz++;

  if(omc_flag[FLAG_SOLVER_STEPS])
    sz++;

  for(int i = 0; i < modelData->nVariablesReal; i++)
    if(!modelData->realVarsData[i].filterOutput)
    {
       matData->r_indx_map[i] = sz;
       sz++;
    }

  /* put sensitivity analysis also to the result file */
  if (omc_flag[FLAG_IDAS])
  {
    sz += (data->modelData->nSensitivityVars-data->modelData->nSensitivityParamVars);
  }

  for(int i = 0; i < modelData->nVariablesInteger; i++)
    if(!modelData->integerVarsData[i].filterOutput)
    {
       matData->i_indx_map[i] = sz;
       sz++;
    }
  for(int i = 0; i < modelData->nVariablesBoolean; i++)
    if(!modelData->booleanVarsData[i].filterOutput)
    {
       matData->b_indx_map[i] = sz;
       sz++;
    }
  for(int i = 0; i < modelData->nAliasReal; i++)
    if(!modelData->realAlias[i].filterOutput) sz++;
  for(int i = 0; i < modelData->nAliasInteger; i++)
    if(!modelData->integerAlias[i].filterOutput) sz++;
  matData->negatedboolaliases = 0;
  for(int i = 0; i < modelData->nAliasBoolean; i++)
    if(!modelData->booleanAlias[i].filterOutput)
    {
       if(modelData->booleanAlias[i].negate)
          matData->negatedboolaliases++;
       sz++;
    }
  return sz;
}

static int calcParamsSize(simulation_result *self, DATA *data)
{
  mat_data *matData = (mat_data*) self->storage;
  const MODEL_DATA *modelData = data->modelData;

  int i, sz = 1;

  for (i = 0; i < modelData->nParametersReal; i++)
    if (!modelData->realParameterData[i].filterOutput)
    {
      matData->r_indx_parammap[i] = sz;
      sz ++;
    }

  for (i = 0; i < modelData->nParametersInteger; i++)
    if(!modelData->integerParameterData[i].filterOutput)
    {
      matData->i_indx_parammap[i] = sz;
      sz ++;
    }

  for (i = 0; i < modelData->nParametersBoolean; i++)
    if(!modelData->booleanParameterData[i].filterOutput)
    {
      matData->b_indx_parammap[i] = sz;
      sz ++;
    }

  return sz - 1;
}

static const VAR_INFO** calcDataNames(simulation_result *self,DATA *data,int dataSize)
{
  const MODEL_DATA *modelData = data->modelData;

  const VAR_INFO** names = (const VAR_INFO**) malloc((dataSize)*sizeof(struct VAR_INFO*));
  int curVar = 0;

  names[curVar++] = &timeValName;

  if(self->cpuTime)
    names[curVar++] = &cpuTimeValName;

  if(omc_flag[FLAG_SOLVER_STEPS])
    names[curVar++] = &solverStepsValName;

  for(int i = 0; i < modelData->nVariablesReal; i++) if(!modelData->realVarsData[i].filterOutput)
    names[curVar++] = &(modelData->realVarsData[i].info);

  /* put sensitivity analysis also to the result file */
  if (omc_flag[FLAG_IDAS])
  {
    for(int i = data->modelData->nSensitivityParamVars; i < data->modelData->nSensitivityVars; i++)
    {
      names[curVar++] = &(modelData->realSensitivityData[i].info);
    }
  }
  for(int i = 0; i < modelData->nVariablesInteger; i++) if(!modelData->integerVarsData[i].filterOutput)
    names[curVar++] = &(modelData->integerVarsData[i].info);
  for(int i = 0; i < modelData->nVariablesBoolean; i++) if(!modelData->booleanVarsData[i].filterOutput)
    names[curVar++] = &(modelData->booleanVarsData[i].info);
  for(int i = 0; i < modelData->nAliasReal; i++) if(!modelData->realAlias[i].filterOutput)
    names[curVar++] = &(modelData->realAlias[i].info);
  for(int i = 0; i < modelData->nAliasInteger; i++) if(!modelData->integerAlias[i].filterOutput)
    names[curVar++] = &(modelData->integerAlias[i].info);
  for(int i = 0; i < modelData->nAliasBoolean; i++) if(!modelData->booleanAlias[i].filterOutput)
    names[curVar++] = &(modelData->booleanAlias[i].info);

  for(int i = 0; i < modelData->nParametersReal; i++)
  {
    if (!modelData->realParameterData[i].filterOutput)
      names[curVar++] = &(modelData->realParameterData[i].info);
  }
  for(int i = 0; i < modelData->nParametersInteger; i++)
  {
    if (!modelData->integerParameterData[i].filterOutput)
      names[curVar++] = &(modelData->integerParameterData[i].info);
  }
  for(int i = 0; i < modelData->nParametersBoolean; i++)
  {
    if (!modelData->booleanParameterData[i].filterOutput)
      names[curVar++] = &(modelData->booleanParameterData[i].info);
  }

  return names;
}

/* write the parameter data after updateBoundParameters is called */
void mat4_writeParameterData(simulation_result *self,DATA *data, threadData_t *threadData)
{
  mat_data *matData = (mat_data*) self->storage;
  int rows, cols;
  double *doubleMatrix = NULL;
  try
  {
    std::ofstream::pos_type remember = matData->fp.tellp();
    matData->fp.seekp(matData->data1HdrPos);
    /* generate `data_1' matrix (with parameter data) */
    generateData_1(data, threadData, doubleMatrix, rows, cols, matData->startTime, matData->stopTime);
    /*  write `data_1' matrix */
    mat_writeMatVer4Matrix(self,data, threadData,"data_1", cols, rows, doubleMatrix, sizeof(double));
    free(doubleMatrix); doubleMatrix = NULL;
    matData->fp.seekp(remember);
  }
  catch(...)
  {
    matData->fp.close();
    free(doubleMatrix);
    throw;
  }
}

void mat4_init(simulation_result *self,DATA *data, threadData_t *threadData)
{
  mat_data *matData = new mat_data();
  self->storage = matData;
  const MODEL_DATA *mData = data->modelData;

  const char Aclass[] = "A1 bt. ir1 na  Tj  re  ac  nt  so   r   y   ";

  const struct VAR_INFO** names = NULL;

  char *stringMatrix = NULL;
  int rows, cols;
  int32_t *intMatrix = NULL;
  double *doubleMatrix = NULL;
  int nSensitivities = omc_flag[FLAG_IDAS] ? mData->nSensitivityVars-data->modelData->nSensitivityParamVars: 0;
  assert(sizeof(char) == 1);
  rt_tick(SIM_TIMER_OUTPUT);
  matData->numVars = calcDataSize(self,data);
  matData->numParams = calcParamsSize(self, data);
  names = calcDataNames(self, data, matData->numVars + matData->numParams);
  matData->data1HdrPos = -1;
  matData->data2HdrPos = -1;
  matData->ntimepoints = 0;
  matData->startTime = data->simulationInfo->startTime;
  matData->stopTime = data->simulationInfo->stopTime;

  try {
    /* open file */
    matData->fp.open(self->filename, std::ofstream::binary|std::ofstream::trunc);
    if(!matData->fp) {
      throwStreamPrint(threadData, "Cannot open File %s for writing",self->filename);
    }

    /* write `AClass' matrix */
    mat_writeMatVer4Matrix(self,data, threadData,"Aclass", 4, 11, Aclass, sizeof(int8_t));
    /* flatten variables' names */
    flattenStrBuf(matData->numVars + matData->numParams, names, stringMatrix, rows, cols, false /* We cannot plot derivatives if we fix the names ... */, false);
    /* write `name' matrix */
    mat_writeMatVer4Matrix(self,data,threadData,"name", rows, cols, stringMatrix, sizeof(int8_t));
    free(stringMatrix); stringMatrix = NULL;

    /* flatten variables' comments */
    flattenStrBuf(matData->numVars + matData->numParams, names, stringMatrix, rows, cols, false, true);
    /* write `description' matrix */
    mat_writeMatVer4Matrix(self,data,threadData,"description", rows, cols, stringMatrix, sizeof(int8_t));
    free(stringMatrix); stringMatrix = NULL;

    /* generate dataInfo table */
    generateDataInfo(self, data, threadData, intMatrix, rows, cols, matData->numVars, matData->numParams);
    /* write `dataInfo' matrix */
    mat_writeMatVer4Matrix(self, data, threadData, "dataInfo", cols, rows, intMatrix, sizeof(int32_t));

    /* remember data1HdrPos */
    matData->data1HdrPos = matData->fp.tellp();

    /* adrpo: i cannot use writeParameterData here as it would return back to dataHdr1Pos */
    /* generate `data_1' matrix (with parameter data) */
    generateData_1(data, threadData, doubleMatrix, rows, cols, matData->startTime, matData->stopTime);
    /*  write `data_1' matrix */
    mat_writeMatVer4Matrix(self,data,threadData,"data_1", cols, rows, doubleMatrix, sizeof(double));

    /* remember data2HdrPos */
    matData->data2HdrPos = matData->fp.tellp();
    /* write `data_2' header */
    mat_writeMatVer4MatrixHeader(self,data,threadData,"data_2", matData->r_indx_map.size() + matData->i_indx_map.size() + matData->b_indx_map.size() + matData->negatedboolaliases + 1 /* add one more for timeValue*/ + self->cpuTime + /* add one more for solverSteps*/ + omc_flag[FLAG_SOLVER_STEPS] + nSensitivities, 0, sizeof(double));

    free(doubleMatrix);
    free(intMatrix);
    doubleMatrix = NULL;
    intMatrix = NULL;
    matData->fp.flush();

  }
  catch(...)
  {
    matData->fp.close();
    free(names); names=NULL;
    free(stringMatrix);
    free(doubleMatrix);
    free(intMatrix);
    rt_accumulate(SIM_TIMER_OUTPUT);
    throwStreamPrint(threadData, "Error while writing mat file %s",self->filename);
  }
  free(names); names=NULL;
  rt_accumulate(SIM_TIMER_OUTPUT);
}

void mat4_free(simulation_result *self,DATA *data, threadData_t *threadData)
{
  mat_data *matData = (mat_data*) self->storage;
  int nSensitivities = omc_flag[FLAG_IDAS] ? data->modelData->nSensitivityVars - data->modelData->nSensitivityParamVars : 0;
  rt_tick(SIM_TIMER_OUTPUT);
  /* this is a bad programming practice - closing file in destructor,
   * where a proper error reporting can't be done
   * It's ok now; it's not even C++ code :D
   */
  if(matData->fp)
  {
    try
    {
      matData->fp.seekp(matData->data2HdrPos);
      mat_writeMatVer4MatrixHeader(self,data,threadData,"data_2", matData->r_indx_map.size() + matData->i_indx_map.size() + matData->b_indx_map.size() + matData->negatedboolaliases + 1 /* add one more for timeValue*/ + self->cpuTime + /* add one more for solverSteps*/ + omc_flag[FLAG_SOLVER_STEPS] + nSensitivities, matData->ntimepoints, sizeof(double));
      matData->fp.close();
    }
    catch (...)
    {
      /* just ignore, we are in destructor */
    }
  }
  delete matData;
  self->storage = NULL;
  rt_accumulate(SIM_TIMER_OUTPUT);
}

void mat4_emit(simulation_result *self,DATA *data, threadData_t *threadData)
{
  mat_data *matData = (mat_data*) self->storage;
  double datPoint=0;
  rt_tick(SIM_TIMER_OUTPUT);

  rt_accumulate(SIM_TIMER_TOTAL);
  double cpuTimeValue = rt_accumulated(SIM_TIMER_TOTAL);
  rt_tick(SIM_TIMER_TOTAL);

  /* this is done wrong -- a buffering should be used
     although ofstream does have some buffering, but it is not enough and
     not for this purpose */
  matData->fp.write((char*)&(data->localData[0]->timeValue), sizeof(double));

  if(self->cpuTime)
    matData->fp.write((char*)&cpuTimeValue, sizeof(double));

  if(omc_flag[FLAG_SOLVER_STEPS])
    matData->fp.write((char*)&(data->simulationInfo->solverSteps), sizeof(double));

  for(int i = 0; i < data->modelData->nVariablesReal; i++) if(!data->modelData->realVarsData[i].filterOutput)
    matData->fp.write((char*)&(data->localData[0]->realVars[i]),sizeof(double));

  /* put parameter sensitivity analysis also to the result file */
  if (omc_flag[FLAG_IDAS])
  {
    for(int i = 0; i < data->modelData->nSensitivityVars-data->modelData->nSensitivityParamVars; i++)
      matData->fp.write((char*)&(data->simulationInfo->sensitivityMatrix[i]),sizeof(double));
  }
  for(int i = 0; i < data->modelData->nVariablesInteger; i++) if(!data->modelData->integerVarsData[i].filterOutput)
    {
      datPoint = (double) data->localData[0]->integerVars[i];
      matData->fp.write((char*)&datPoint,sizeof(double));
    }
  for(int i = 0; i < data->modelData->nVariablesBoolean; i++) if(!data->modelData->booleanVarsData[i].filterOutput)
    {
      datPoint = (double) data->localData[0]->booleanVars[i];
      matData->fp.write((char*)&datPoint,sizeof(double));
    }
  for(int i = 0; i < data->modelData->nAliasBoolean; i++) if(!data->modelData->booleanAlias[i].filterOutput)
    {
      if(data->modelData->booleanAlias[i].negate)
      {
        datPoint = (double) (data->localData[0]->booleanVars[data->modelData->booleanAlias[i].nameID]==1?0:1);
        matData->fp.write((char*)&datPoint,sizeof(double));
      }
    }
  if (!matData->fp) {
    throwStreamPrint(threadData, "Error while writing file %s",self->filename);
  }
  ++matData->ntimepoints;
  rt_accumulate(SIM_TIMER_OUTPUT);
}

/* from an array of string creates flatten 'char*'-array suitable to be
   stored as MAT-file matrix */
static inline void fixDerInName(char *str, size_t len)
{
  char* dot;
  if(len < 6) return;

  /* check if name start with "der(" and includes at least one dot */
  while(strncmp(str,"der(",4) == 0 && (dot = strrchr(str,'.')) != NULL) {
    size_t pos = (size_t)(dot-str)+1;
    /* move prefix to the beginning of string :"der(a.b.c.d)" -> "a.b.c.b.c.d)" */
    for(size_t i = 4; i < pos; ++i)
      str[i-4] = str[i];
    /* move "der(" to the end of prefix
       "a.b.c.b.c.d)" -> "a.b.c.der(d)" */
    strncpy(&str[pos-4],"der(",4);
  }
}

long flattenStrBuf(int dims, const struct VAR_INFO** src, char* &dest, int& longest, int& nstrings, bool fixNames, bool useComment)
{
  int i,len;
  nstrings = dims;
  longest = 0; /* the longest-string length */

  /* calculate required size */
  for(i = 0; i < dims; ++i) {
      len = strlen(useComment ? src[i]->comment : src[i]->name);
      if(len > longest) longest = len;
  }

  /* allocate memory */
  dest = (char*) calloc(longest*nstrings+1, sizeof(char));
  assertStreamPrint(NULL, 0!=dest,"Cannot allocate memory");
  /* copy data */
  char *ptr = dest;
/*  for(i=0;i<dims;i++) {
      len = strlen(useComment ? src[i]->comment : src[i]->name);
      for(j = 0; j < len; ++j) {
         strncpy(ptr + i + j*dims,useComment ? &src[i]->comment[j] : &src[i]->name[j],1);
    }
    } */
  for(i = 0; i < dims; ++i) {
      strncpy(ptr,useComment ? src[i]->comment : src[i]->name,longest+1 /* ensures that we get \0 after the longest string*/);
      if(fixNames) fixDerInName(ptr,strlen(useComment ? src[i]->comment : src[i]->name));
      ptr += longest;
  }
  /* return the size of the `dest' buffer */
  return (longest*nstrings);
}

// writes MAT-file matrix header to file
void mat_writeMatVer4MatrixHeader(simulation_result *self, DATA *data, threadData_t *threadData, const char *name, int rows, int cols, unsigned int size)
{
  mat_data *matData = (mat_data*) self->storage;
  typedef struct MHeader {
    uint32_t type;
    uint32_t mrows;
    uint32_t ncols;
    uint32_t imagf;
    uint32_t namelen;
  } MHeader_t;
  const int endian_test = 1;
  MHeader_t hdr;

  int type = 0;
  if(size == 1 /* char */)
    type = 51;
  if(size == 4 /* int32 */)
    type = 20;

  /* create matrix header structure */
  hdr.type = 1000*((*(char*)&endian_test) == 0) + type;
  hdr.mrows = rows;
  hdr.ncols = cols;
  hdr.imagf = 0;
  hdr.namelen = strlen(name)+1;
  /* write header to file */
  matData->fp.write((char*)&hdr, sizeof(MHeader_t));
  if (!matData->fp) {
    throwStreamPrint(threadData, "Cannot write to file %s",self->filename);
  }
  matData->fp.write(name, sizeof(char)*hdr.namelen);
  if (!matData->fp) {
    throwStreamPrint(threadData, "Cannot write to file %s",self->filename);
  }
}

void mat_writeMatVer4Matrix(simulation_result *self, DATA *data, threadData_t *threadData, const char *name, int rows, int cols, const void *matrixData, unsigned int size)
{
  mat_data *matData = (mat_data*) self->storage;
  mat_writeMatVer4MatrixHeader(self, data, threadData, name, rows, cols, size);

  /* write data */
  matData->fp.write((const char*)matrixData, (size)*rows*cols);
  if(!matData->fp) {
    throwStreamPrint(threadData, "Cannot write to file %s",self->filename);
  }
}


void generateDataInfo(simulation_result *self, DATA *data, threadData_t *threadData, int32_t* &dataInfo, int& rows, int& cols, int nVars, int nParams)
{
  mat_data *matData = (mat_data*) self->storage;
  const MODEL_DATA *mdl_data = data->modelData;
  int nSensitivities = omc_flag[FLAG_IDAS] ? mdl_data->nSensitivityVars - data->modelData->nSensitivityParamVars : 0;

  /* size_t nVars = mdl_data->nStates*2+mdl_data->nAlgebraic;
    rows = 1+nVars+mdl_data->nParameters+mdl_data->nVarsAliases; */
  size_t ccol = 0; /* current column - index offset */
  size_t indx = 1;
  size_t aliascol = 0;
  INTMAP::iterator it;
  /* assign rows & cols */
  rows = nVars + nParams;
  cols = 4;

  dataInfo = (int*) calloc(rows*cols,sizeof(int));
  assertStreamPrint(threadData, 0!=dataInfo,"Cannot alloc memory");
  /* continuous and discrete variables, including time */
  for(size_t i = 0; i < (size_t)(matData->r_indx_map.size() + matData->i_indx_map.size() + matData->b_indx_map.size() + 1 /* add one more for timeValue*/ + self->cpuTime /* add one more for solverSteps*/ + omc_flag[FLAG_SOLVER_STEPS] + nSensitivities); ++i) {
      /* row 1 - which table */
      dataInfo[ccol++] = 2;
      /* row 2 - index of var in table (variable 'Time' have index 1) */
      dataInfo[ccol++] = indx;
      /* row 3 - linear interpolation == 0 */
      dataInfo[ccol++] = 0;
      /* row 4 - not defined outside of the defined time range == -1 */
      dataInfo[ccol++] = -1;
      indx++;
  }
  /* alias variables */
  for(int i = 0; i < mdl_data->nAliasReal; i++) {
    if(!mdl_data->realAlias[i].filterOutput)
    {
      int table = 0;
      if(mdl_data->realAlias[i].aliasType == 0) /* variable */
      {
        it = matData->r_indx_map.find(mdl_data->realAlias[i].nameID);
        if(it != matData->r_indx_map.end())
        {
          table = 2;
          aliascol = it->second+1;
        }
      }
      else if(mdl_data->realAlias[i].aliasType == 1) /* parameter */
      {
        it = matData->r_indx_parammap.find(mdl_data->realAlias[i].nameID);
        if(it != matData->r_indx_parammap.end())
        {
          table = 1;
          aliascol = it->second+1;
        }
      } else if(mdl_data->realAlias[i].aliasType == 2) /* time */
      {
        table = 2;
        aliascol = 1;
      }
      if(table)
      {
        /* row 1 - which table */
        dataInfo[ccol] = table;
        /* row 2 - index of var in table (variable 'Time' have index 1) */
        if(mdl_data->realAlias[i].negate)
          dataInfo[ccol+1] = -aliascol;
        else
          dataInfo[ccol+1] = aliascol;
        /* row 3 - linear interpolation == 0 */
        dataInfo[ccol+2] = 0;
        /* row 4 - not defined outside of the defined time range == -1 */
        dataInfo[ccol+3] = -1;
        ccol += 4;
      }
    }
  }
  for(int i = 0; i < mdl_data->nAliasInteger; i++) {
    if(!mdl_data->integerAlias[i].filterOutput)
    {
      int table = 0;
      if(mdl_data->integerAlias[i].aliasType == 0) /* variable */
      {
        it = matData->i_indx_map.find(mdl_data->integerAlias[i].nameID);
        if(it != matData->i_indx_map.end())
          table = 2;
      }
      else if(mdl_data->integerAlias[i].aliasType == 1) /* parameter */
      {
        it = matData->i_indx_parammap.find(mdl_data->integerAlias[i].nameID);
        if(it != matData->i_indx_parammap.end())
          table = 1;
      }
      if(table)
      {
        /* row 1 - which table */
        dataInfo[ccol] = table;
        /* row 2 - index of var in table */
        if(mdl_data->integerAlias[i].negate)
          dataInfo[ccol+1] = -(it->second+1);
        else
          dataInfo[ccol+1] = it->second+1;
        /* row 3 - linear interpolation == 0 */
        dataInfo[ccol+2] = 0;
        /* row 4 - not defined outside of the defined time range == -1 */
        dataInfo[ccol+3] = -1;
        ccol += 4;
      }
    }
  }
  for(int i = 0; i < mdl_data->nAliasBoolean; i++) {
    if(!mdl_data->booleanAlias[i].filterOutput)
    {
      int table = 0;

      if(mdl_data->booleanAlias[i].negate)
        table = 2;
      else
      {
        if(mdl_data->booleanAlias[i].aliasType == 0) /* variable */
        {
          it = matData->b_indx_map.find(mdl_data->booleanAlias[i].nameID);
          if(it != matData->b_indx_map.end())
            table = 2;
        }
        else if(mdl_data->booleanAlias[i].aliasType == 1) /* parameter */
        {
          it = matData->b_indx_parammap.find(mdl_data->booleanAlias[i].nameID);
          if(it != matData->b_indx_parammap.end())
            table = 1;
        }
      }
      if(table)
      {
        /* row 1 - which table */
        dataInfo[ccol] = table;
        /* row 2 - index of var in table */
        if(mdl_data->booleanAlias[i].negate)
        {
          dataInfo[ccol+1] = indx;
          indx++;
        }
        else
          dataInfo[ccol+1] = it->second+1;
        /* row 3 - linear interpolation == 0 */
        dataInfo[ccol+2] = 0;
        /* row 4 - not defined outside of the defined time range == -1 */
        dataInfo[ccol+3] = -1;
        ccol += 4;
      }
    }
  }
  /* parameters and constants */
  for(size_t i = 0; i < (size_t)nParams; ++i) {
      /* col 1 - which table */
      dataInfo[ccol+4*i] = 1;
      /* col 2 - index of var in the table (first parameter has index 2) */
      dataInfo[ccol+4*i+1] = i+2;
      /* col 3 (== 0 <- interpolation doesn't matter here) */
      dataInfo[ccol+4*i+2] = 0;
      /* col 4 - keep first/last value outside of time range */
      dataInfo[ccol+4*i+3] = 0;

  }
  /* ccol += mdl_data->nParameters*4; */
}

void generateData_1(DATA *data, threadData_t *threadData, double* &data_1, int& rows, int& cols, double tstart, double tstop)
{
  const SIMULATION_INFO *sInfo = data->simulationInfo;
  const MODEL_DATA      *mData = data->modelData;

  int offset = 1;
  long i = 0;

  /* calculate number of rows and columns */
  rows = 2;
  cols = 1 + mData->nParametersReal +
             mData->nParametersInteger +
             mData->nParametersBoolean;

  /* allocate data buffer */
  data_1 = (double*)calloc(rows*cols, sizeof(double));
  assertStreamPrint(threadData, 0!=data_1, "Malloc failed");
  data_1[0] = tstart;     /* start time */
  data_1[cols] = tstop;   /* stop time */

  /* double variables */
  for(i = 0; i < mData->nParametersReal; ++i)
  {
    if (!mData->realParameterData[i].filterOutput) {
      data_1[offset] = sInfo->realParameter[i];
      data_1[offset+cols] = sInfo->realParameter[i];
      offset ++;
    }
  }

  /* integer variables */
  for(i = 0; i < mData->nParametersInteger; ++i)
  {
    if (!mData->integerParameterData[i].filterOutput) {
      data_1[offset] = (double)sInfo->integerParameter[i];
      data_1[offset+cols] = (double)sInfo->integerParameter[i];
      offset ++;
    }
  }

  /* bool variables */
  for(i = 0; i < mData->nParametersBoolean; ++i)
  {
    if (!mData->booleanParameterData[i].filterOutput) {
      data_1[offset] = (double)sInfo->booleanParameter[i];
      data_1[offset+cols] = (double)sInfo->booleanParameter[i];
      offset ++;
    }
  }
}

}
