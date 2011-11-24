/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*

 */

#include "error.h"

#include "simulation_result_mat.h"
#include <cstring>
#include <cstdlib>
#include <stdint.h>
#include <assert.h>

static const struct VAR_INFO timeValName = {0,"time","Simulation time [s]",{"",-1,-1,-1,-1}};

int simulation_result_mat::calcDataSize(MODEL_DATA *modelData)
{
  int sz = 1; /* start with one for the timeValue */
  for (int i = 0; i < modelData->nVariablesReal; i++) 
    if (!modelData->realData[i].filterOutput)
    {
       r_indx_map[i] = sz; 
       sz++;
    }
  for (int i = 0; i < modelData->nVariablesInteger; i++) 
    if (!modelData->integerData[i].filterOutput)
    {
       i_indx_map[i] = sz; 
       sz++;
    }
  for (int i = 0; i < modelData->nVariablesBoolean; i++) 
    if (!modelData->booleanData[i].filterOutput)
    {
       b_indx_map[i] = sz; 
       sz++;
    }
  for (int i = 0; i < modelData->nAliasReal; i++)
    if (!modelData->realAlias[i].filterOutput) sz++;
  for (int i = 0; i < modelData->nAliasInteger; i++)
    if (!modelData->integerAlias[i].filterOutput) sz++;
  for (int i = 0; i < modelData->nAliasBoolean; i++)
    if (!modelData->booleanAlias[i].filterOutput) sz++;
  return sz;
}

const VAR_INFO** simulation_result_mat::calcDataNames(int dataSize, MODEL_DATA *modelData)
    {
  const VAR_INFO** names = (const VAR_INFO**) malloc((dataSize)*sizeof(struct VAR_INFO*));
  int curVar = 0;
  int sz = 1;
  names[curVar++] = &timeValName;
  for (int i = 0; i < modelData->nVariablesReal; i++) if (!modelData->realData[i].filterOutput)
    names[curVar++] = &(modelData->realData[i].info);
  for (int i = 0; i < modelData->nVariablesInteger; i++) if (!modelData->integerData[i].filterOutput)
    names[curVar++] = &(modelData->integerData[i].info);
  for (int i = 0; i < modelData->nVariablesBoolean; i++) if (!modelData->booleanData[i].filterOutput)
    names[curVar++] = &(modelData->booleanData[i].info);
  for (int i = 0; i < modelData->nAliasReal; i++) if (!modelData->realAlias[i].filterOutput)
    names[curVar++] = &(modelData->realAlias[i].info);
  for (int i = 0; i < modelData->nAliasInteger; i++) if (!modelData->integerAlias[i].filterOutput)
    names[curVar++] = &(modelData->integerAlias[i].info);
  for (int i = 0; i < modelData->nAliasBoolean; i++) if (!modelData->booleanAlias[i].filterOutput)
    names[curVar++] = &(modelData->booleanAlias[i].info);


  for (int i = 0; i < modelData->nParametersReal; i++) {
    names[curVar++] = &(modelData->realParameter[i].info);
    r_indx_parammap[i]=sz; 
    sz++;
  }
  for (int i = 0; i < modelData->nParametersInteger; i++) {
    names[curVar++] = &(modelData->integerParameter[i].info);
    i_indx_parammap[i]=sz; 
    sz++;
  }
  for (int i = 0; i < modelData->nParametersBoolean; i++) {
    names[curVar++] = &(modelData->booleanParameter[i].info);
    b_indx_parammap[i]=sz;  
    sz++;
  }
  return names;
}

/* write the parameter data after bound_parameters is called */
void simulation_result_mat::writeParameterData(MODEL_DATA *modelData)
{
  int rows, cols;
  double *doubleMatrix = NULL;
  try{
    std::ofstream::pos_type remember = fp.tellp();
    fp.seekp(data1HdrPos);
    /* generate `data_1' matrix (with parameter data) */
    generateData_1(doubleMatrix, rows, cols, modelData, startTime, stopTime);
    /*  write `data_1' matrix */
    writeMatVer4Matrix("data_1", cols, rows, doubleMatrix, sizeof(double));
    delete[] doubleMatrix; doubleMatrix = NULL;
    fp.seekp(remember);
  } catch(...) {
    fp.close();
    delete[] doubleMatrix;
    throw;
  }
};



simulation_result_mat::simulation_result_mat(const char* filename,
               double tstart, double tstop, MODEL_DATA *modelData)
  : simulation_result(filename,numpoints),fp(),data1HdrPos(-1),data2HdrPos(-1),ntimepoints(0),startTime(tstart),stopTime(tstop)
{
  const char Aclass[] = "A1 bt. ir1 na  Tj  re  ac  nt  so   r   y   ";

  const struct VAR_INFO** names = NULL;
  const int nParams = modelData->nParametersReal + modelData->nParametersInteger + modelData->nParametersBoolean;

  char *stringMatrix = NULL;
  int rows, cols;
  int32_t *intMatrix = NULL;
  double *doubleMatrix = NULL;
  assert(sizeof(char) == 1);
  rt_tick(SIM_TIMER_OUTPUT);
  numVars = calcDataSize(modelData);
  names = calcDataNames(numVars+nParams, modelData);

  try {
    /* open file */
    fp.open(filename, std::ofstream::binary|std::ofstream::trunc);
    if (!fp) 
      THROW1("Cannot open File %s for writing",filename);

    /* write `AClass' matrix */
    writeMatVer4Matrix("Aclass", 4, 11, Aclass, sizeof(int8_t));
    /* flatten variables' names */
    flattenStrBuf(numVars+nParams, names, stringMatrix, rows, cols, false /* We cannot plot derivatives if we fix the names ... */, false);
    /* write `name' matrix */
    writeMatVer4Matrix("name", rows, cols, stringMatrix, sizeof(int8_t));
    free(stringMatrix); stringMatrix = NULL;

    /* flatten variables' comments */
    flattenStrBuf(numVars+nParams, names, stringMatrix, rows, cols, false, true);
    /* write `description' matrix */
    writeMatVer4Matrix("description", rows, cols, stringMatrix, sizeof(int8_t));
    free(stringMatrix); stringMatrix = NULL;

    /* generate dataInfo table */
    generateDataInfo(intMatrix, rows, cols, modelData, numVars, nParams);
    /* write `dataInfo' matrix */
    writeMatVer4Matrix("dataInfo", cols, rows, intMatrix, sizeof(int32_t));

    /* remember data1HdrPos */
    data1HdrPos = fp.tellp();

    /* adrpo: i cannot use writeParameterData here as it would return back to dataHdr1Pos */
    /* generate `data_1' matrix (with parameter data) */
    generateData_1(doubleMatrix, rows, cols, modelData, tstart, tstop);
    /*  write `data_1' matrix */
    writeMatVer4Matrix("data_1", cols, rows, doubleMatrix, sizeof(double));

    /* remember data2HdrPos */
    data2HdrPos = fp.tellp();
    /* write `data_2' header */
    writeMatVer4MatrixHeader("data_2", r_indx_map.size() + i_indx_map.size() + b_indx_map.size() + 1 /* add one more for timeValue*/, 0, sizeof(double));

    free(doubleMatrix);
    doubleMatrix = NULL;
    fp.flush();

  } catch(...) {
    fp.close();
    free(names); names=NULL;
    delete[] stringMatrix;
    delete[] doubleMatrix;
    rt_accumulate(SIM_TIMER_OUTPUT);
    THROW1("Error while writing mat file %s",filename);
  }
  free(names); names=NULL;
  rt_accumulate(SIM_TIMER_OUTPUT);
}
simulation_result_mat::~simulation_result_mat()
{
  rt_tick(SIM_TIMER_OUTPUT);
  /* this is a bad programming practice - closing file in destructor,
     where a proper error reporting can't be done */
  if (fp) {
    try {
      fp.seekp(data2HdrPos);
      writeMatVer4MatrixHeader("data_2", r_indx_map.size() + i_indx_map.size() + b_indx_map.size() + 1 /* add one more for timeValue*/, ntimepoints, sizeof(double));
      fp.close();
    } catch (...) {
      /* just ignore, we are in destructor */
    }
  }
  rt_accumulate(SIM_TIMER_OUTPUT);
}

void simulation_result_mat::emit(_X_DATA *data)
{
  double datPoint=0;

  rt_tick(SIM_TIMER_OUTPUT);

  /* this is done wrong -- a buffering should be used
     although ofstream does have some buffering, but it is not enough and 
     not for this purpose */
  fp.write((char*)&(data->localData[0]->timeValue),sizeof(double));
  for (int i = 0; i < data->modelData.nVariablesReal; i++) if (!data->modelData.realData[i].filterOutput)
    fp.write((char*)&(data->localData[0]->realVars[i]),sizeof(double));
  for (int i = 0; i < data->modelData.nVariablesInteger; i++) if (!data->modelData.integerData[i].filterOutput)
    {
      datPoint = (double) data->localData[0]->integerVars[i];
      fp.write((char*)&datPoint,sizeof(double));
    }
  for (int i = 0; i < data->modelData.nVariablesBoolean; i++) if (!data->modelData.booleanData[i].filterOutput)
    {
      datPoint = (double) data->localData[0]->booleanVars[i];
      fp.write((char*)&datPoint,sizeof(double));
    }
  if (!fp)
    THROW1("Error while writing file %s",filename);
  ++ntimepoints;
  rt_accumulate(SIM_TIMER_OUTPUT);
}

/* from an array of string creates flatten 'char*'-array suitable to be 
   stored as MAT-file matrix */
static inline void fixDerInName(char *str, size_t len)
{
  char* dot;
  if (len < 6) return;

  /* check if name start with "der(" and includes at least one dot */
  while (strncmp(str,"der(",4) == 0 && (dot = strrchr(str,'.')) != NULL) {
    size_t pos = (size_t)(dot-str)+1;
    /* move prefix to the begining of string :"der(a.b.c.d)" -> "a.b.c.b.c.d)" */
    for(size_t i = 4; i < pos; ++i)
      str[i-4] = str[i];
    /* move "der(" to the end of prefix
       "a.b.c.b.c.d)" -> "a.b.c.der(d)" */
    strncpy(&str[pos-4],"der(",4);
  }
}

long simulation_result_mat::flattenStrBuf(int dims,
    const struct VAR_INFO** src,
    char* &dest, int& longest, int& nstrings,
    bool fixNames, bool useComment)
{
  int i,len;
  nstrings = dims;
  longest = 0; /* the longest-string length */

  /* calculate required size */
  for (i = 0; i < dims; ++i) {
      len = strlen(useComment ? src[i]->comment : src[i]->name);
      if (len > longest) longest = len;
  }

  /* allocate memory */
  dest = (char*) calloc(longest*nstrings+1, sizeof(char));
  ASSERT(dest,"Cannot allocate memory");
  /* copy data */
  char *ptr = dest;
/*  for (i=0;i<dims;i++) {
      len = strlen(useComment ? src[i]->comment : src[i]->name);
      for (j = 0; j < len; ++j) {
         strncpy(ptr + i + j*dims,useComment ? &src[i]->comment[j] : &src[i]->name[j],1);
    }
    } */
  for (i = 0; i < dims; ++i) {
      strncpy(ptr,useComment ? src[i]->comment : src[i]->name,longest+1 /* ensures that we get \0 after the longest string*/);
      if (fixNames) fixDerInName(ptr,strlen(useComment ? src[i]->comment : src[i]->name));
      ptr += longest;
  }
  /* return the size of the `dest' buffer */
  return (longest*nstrings);
}

// writes MAT-file matrix header to file
void simulation_result_mat::writeMatVer4MatrixHeader(const char *name,
    int rows, int cols,
    unsigned int size)
{
  typedef struct {
    uint32_t type;
    uint32_t mrows;
    uint32_t ncols;
    uint32_t imagf;
    uint32_t namelen;
  } MHeader_t;
  const int endian_test = 1;
  MHeader_t hdr;

  int type = 0;
  if (size == 1 /* char */)
    type = 51;
  if (size == 4 /* int32 */)
    type = 20;

  /* create matrix header structure */
  hdr.type = 1000*((*(char*)&endian_test) == 0) + type;
  hdr.mrows = rows;
  hdr.ncols = cols;
  hdr.imagf = 0;
  hdr.namelen = strlen(name)+1;
  /* write header to file */
  fp.write((char*)&hdr, sizeof(MHeader_t));
  if (!fp)
    THROW1("Cannot write to file %s",filename);
  fp.write(name, sizeof(char)*hdr.namelen);
  if (!fp)
    THROW1("Cannot write to file %s",filename);
}

void simulation_result_mat::writeMatVer4Matrix(const char *name,
    int rows, int cols,
    const void *data, unsigned int size)
{
  writeMatVer4MatrixHeader(name,rows,cols,size);

  /* write data */
  fp.write((const char*)data, (size)*rows*cols);
  if (!fp)
    THROW1("Cannot write to file %s",filename);
}


void simulation_result_mat::generateDataInfo(int32_t* &dataInfo,
    int& rows, int& cols,
    const MODEL_DATA *mdl_data,
    int nVars, int nParams)
{
  /* size_t nVars = mdl_data->nStates*2+mdl_data->nAlgebraic;
    rows = 1+nVars+mdl_data->nParameters+mdl_data->nVarsAliases; */
  size_t ccol = 0; /* current column - index offset */
  INTMAP::iterator it;
  /* assign rows & cols */
  rows = nVars + nParams;
  cols = 4;

  dataInfo = new int[rows*cols];
  ASSERT(dataInfo,"Cannot alloc memory");
  /* continuous and discrete variables, including time */
  for(size_t i = 0; i < (size_t)(r_indx_map.size() + i_indx_map.size() + b_indx_map.size() + 1/* add one more for timeValue*/ ); ++i) {
      /* row 1 - which table */
      dataInfo[ccol++] = 2;
      /* row 2 - index of var in table (variable 'Time' have index 1) */
      dataInfo[ccol++] = i+1;
      /* row 3 - linear interpolation == 0 */
      dataInfo[ccol++] = 0;
      /* row 4 - not defined outside of the defined time range == -1 */
      dataInfo[ccol++] = -1;
  }
  /* alias variables */
  for (int i = 0; i < mdl_data->nAliasReal; i++) {
    if (!mdl_data->realAlias[i].filterOutput) 
    {
      int table = 0;
      if (mdl_data->realAlias[i].aliasType == 0) /* variable */
      {
        it = r_indx_map.find(mdl_data->realAlias[i].nameID);
        if (it != r_indx_map.end()) 
          table = 2;
      }
      else if (mdl_data->realAlias[i].aliasType == 1) /* parameter */
      {
        it = r_indx_parammap.find(mdl_data->realAlias[i].nameID);
        if (it != r_indx_map.end()) 
          table = 1;
      } else if (mdl_data->realAlias[i].aliasType == 2) /* time */
      {
        table = 2;
      }
      if(table)
      {
        /* row 1 - which table */
        dataInfo[ccol] = table;
        /* row 2 - index of var in table (variable 'Time' have index 1) */
        if (mdl_data->realAlias[i].negate)
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
  for (int i = 0; i < mdl_data->nAliasInteger; i++) {
    if (!mdl_data->integerAlias[i].filterOutput) 
    {
      int table = 0;
      if (mdl_data->integerAlias[i].aliasType == 0) /* variable */
      {
        it = i_indx_map.find(mdl_data->integerAlias[i].nameID);
        if (it != i_indx_map.end()) 
          table = 2;
      }
      else if (mdl_data->integerAlias[i].aliasType == 1) /* parameter */
      {
        it = i_indx_parammap.find(mdl_data->integerAlias[i].nameID);
        if (it != i_indx_map.end()) 
          table = 1;
      } 
      if(table)
      {
        /* row 1 - which table */
        dataInfo[ccol] = table;
        /* row 2 - index of var in table (variable 'Time' have index 1) */
        if (mdl_data->integerAlias[i].negate)
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
  for (int i = 0; i < mdl_data->nAliasBoolean; i++) {
    if (!mdl_data->booleanAlias[i].filterOutput) 
    {
      int table = 0;
      if (mdl_data->booleanAlias[i].aliasType == 0) /* variable */
      {
        it = b_indx_map.find(mdl_data->booleanAlias[i].nameID);
        if (it != b_indx_map.end()) 
          table = 2;
      }
      else if (mdl_data->booleanAlias[i].aliasType == 1) /* parameter */
      {
        it = b_indx_parammap.find(mdl_data->booleanAlias[i].nameID);
        if (it != b_indx_map.end()) 
          table = 1;
      } 
      if(table)
      {
        /* row 1 - which table */
        dataInfo[ccol] = table;
        /* row 2 - index of var in table (variable 'Time' have index 1) */
        if (mdl_data->booleanAlias[i].negate)
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

void simulation_result_mat::generateData_1(double* &data_1,
    int& rows, int& cols,
    const MODEL_DATA *mdl_data,
    double tstart, double tstop)
{
  int offset;
  long i = 0;
  /* calculate number of rows and columns */
  rows = 2;
  cols = 1+mdl_data->nParametersReal+mdl_data->nParametersInteger
      +mdl_data->nParametersBoolean;
  /* allocate data buffer */
  data_1 = (double*)calloc(rows*cols,sizeof(double));
  ASSERT(data_1,"Malloc failed");
  data_1[0] = tstart; /* start time */
  data_1[cols] = tstop; /* stop time */
  offset = 1;
  /* double variables */
  for(i = 0; i < mdl_data->nParametersReal; ++i) {
    data_1[offset+i] = mdl_data->realParameter[i].attribute.initial;
    data_1[offset+i+cols] =  mdl_data->realParameter[i].attribute.initial;
  }
  offset += mdl_data->nParametersReal;
  /* integer variables */
  for(i = 0; i < mdl_data->nParametersInteger; ++i) {
    data_1[offset+i] = (double)mdl_data->integerParameter[i].attribute.initial;
    data_1[offset+i+cols] = (double)mdl_data->integerParameter[i].attribute.initial;
  }
  offset += mdl_data->nParametersInteger;
  /* bool variables */
  for(i = 0; i < mdl_data->nParametersBoolean; ++i) {
    data_1[offset+i] = (double)mdl_data->booleanParameter[i].attribute.initial;
    data_1[offset+i+cols] = (double)mdl_data->booleanParameter[i].attribute.initial;
  }

}
