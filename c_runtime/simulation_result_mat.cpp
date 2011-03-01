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

#include "simulation_result_mat.h"
#include <cstring>
#include <cstdlib>
#include <stdint.h>

static const struct omc_varInfo timeValName = {0,"time","Simulation time [s]",{"",-1,-1,-1,-1}};

static int calcDataSize()
{
  int sz = 1; // time
  for (int i = 0; i < globalData->nStates; i++) if (!globalData->statesFilterOutput[i]) sz++;
  for (int i = 0; i < globalData->nStates; i++) if (!globalData->statesDerivativesFilterOutput[i]) sz++;
  for (int i = 0; i < globalData->nAlgebraic; i++) if (!globalData->algebraicsFilterOutput[i]) sz++;
  for (int i = 0; i < globalData->intVariables.nAlgebraic; i++) if (!globalData->intVariables.algebraicsFilterOutput[i]) sz++;
  for (int i = 0; i < globalData->boolVariables.nAlgebraic; i++) if (!globalData->boolVariables.algebraicsFilterOutput[i]) sz++;
  return sz;
}

static const omc_varInfo** calcDataNames(int dataSize)
{
  const omc_varInfo** names = (const omc_varInfo**) malloc(dataSize*sizeof(struct omc_varInfo*));
  int curVar = 0;
  names[curVar++] = &timeValName;
  for (int i = 0; i < globalData->nStates; i++) if (!globalData->statesFilterOutput[i])
      names[curVar++] = &globalData->statesNames[i];
  for (int i = 0; i < globalData->nStates; i++) if (!globalData->statesDerivativesFilterOutput[i])
      names[curVar++] = &globalData->stateDerivativesNames[i];
  for (int i = 0; i < globalData->nAlgebraic; i++) if (!globalData->algebraicsFilterOutput[i])
      names[curVar++] = &globalData->algebraicsNames[i];
  for (int i = 0; i < globalData->intVariables.nAlgebraic; i++) if (!globalData->intVariables.algebraicsFilterOutput[i])
      names[curVar++] = &globalData->int_alg_names[i];
  for (int i = 0; i < globalData->boolVariables.nAlgebraic; i++) if (!globalData->boolVariables.algebraicsFilterOutput[i])
      names[curVar++] = &globalData->bool_alg_names[i];
  for (int i = 0; i < globalData->nParameters; i++)
      names[curVar++] = &globalData->parametersNames[i];
  for (int i = 0; i < globalData->intVariables.nParameters; i++)
      names[curVar++] = &globalData->int_param_names[i];
  for (int i = 0; i < globalData->boolVariables.nParameters; i++)
      names[curVar++] = &globalData->bool_param_names[i];
  return names;
}

simulation_result_mat::simulation_result_mat(const char* filename, 
               double tstart, double tstop)
  : simulation_result(filename,numpoints),fp(),data2HdrPos(-1),ntimepoints(0)
{
  const char Aclass[] = "A1 bt. ir1 na  Tj  re  ac  nt  so   r   y   ";
  
  const struct omc_varInfo** names;
  const int nParams = globalData->nParameters+globalData->intVariables.nParameters
    +globalData->boolVariables.nParameters;

  char *stringMatrix = NULL;
  int rows, cols, numVars;
  double *doubleMatrix = NULL;
  rt_tick(SIM_TIMER_OUTPUT);
  numVars = calcDataSize();
  names = calcDataNames(numVars+nParams);
  
  try {
    // open file
    fp.open(filename, std::ofstream::binary|std::ofstream::trunc);
    if (!fp) throw SimulationResultFileOpenException();
    
    // write `AClass' matrix
    writeMatVer4Matrix("Aclass", 4, 11, Aclass, true); 
    
    // flatten variables' names
    flattenStrBuf(numVars+nParams, names, stringMatrix, rows, cols, false /* We cannot plot derivatives if we fix the names ... */, false);
    // write `name' matrix
    writeMatVer4Matrix("name", rows, cols, stringMatrix, true);
    delete[] stringMatrix; stringMatrix = NULL;
    
    // flatten variables' comments
    flattenStrBuf(numVars+nParams, names, stringMatrix, rows, cols, false, true);
    // write `description' matrix
    writeMatVer4Matrix("description", rows, cols, stringMatrix, true);
    delete[] stringMatrix; stringMatrix = NULL;

    // generate dataInfo table
    generateDataInfo(doubleMatrix, rows, cols, globalData, numVars-1, nParams);
    // write `dataInfo' matrix
    writeMatVer4Matrix("dataInfo", cols, rows, doubleMatrix, false);
    delete[] doubleMatrix; doubleMatrix = NULL;
    

    // generate `data_1' matrix (with parameter data)
    generateData_1(doubleMatrix, rows, cols, globalData, tstart, tstop);
    //  write `data_1' matrix
    writeMatVer4Matrix("data_1", cols, rows, doubleMatrix, false);
    delete[] doubleMatrix; doubleMatrix = NULL;
    
    data2HdrPos = fp.tellp();
    // write `data_2' header
    writeMatVer4MatrixHeader("data_2", numVars, 0, false);

    fp.flush();

  } catch(...) {
    fp.close();
    free(names);
    delete[] stringMatrix;
    delete[] doubleMatrix;
    rt_accumulate(SIM_TIMER_OUTPUT);
    throw;
  }
  free(names);
  rt_accumulate(SIM_TIMER_OUTPUT);
}
simulation_result_mat::~simulation_result_mat()
{
  int nVars = calcDataSize();
  rt_tick(SIM_TIMER_OUTPUT);
  // this is a bad programming practice - closing file in destructor,
  // where a proper error reporting can't be done
  if (fp) {
    try {
      fp.seekp(data2HdrPos);
      writeMatVer4MatrixHeader("data_2", nVars, ntimepoints, false);
      fp.close();
    } catch (...) {
      // just ignore, we are in destructor
    }
  }
  rt_accumulate(SIM_TIMER_OUTPUT);
}

void simulation_result_mat::emit()
{
  double datPoint;

  // that does not belong here
  storeExtrapolationData();
  rt_tick(SIM_TIMER_OUTPUT);

  // this is done wrong -- a buffering should be used
  // although ofstream does have some buffering, but it is not enough and 
  // not for this purpose
  fp.write((char*)&globalData->timeValue,sizeof(double));
  for (int i = 0; i < globalData->nStates; i++) if (!globalData->statesFilterOutput[i])
      fp.write((char*)&globalData->states[i],sizeof(double));
  for (int i = 0; i < globalData->nStates; i++) if (!globalData->statesDerivativesFilterOutput[i])
      fp.write((char*)&globalData->statesDerivatives[i],sizeof(double));
  for (int i = 0; i < globalData->nAlgebraic; i++) if (!globalData->algebraicsFilterOutput[i])
      fp.write((char*)&globalData->algebraics[i],sizeof(double));
  for (int i = 0; i < globalData->intVariables.nAlgebraic; i++) if (!globalData->intVariables.algebraicsFilterOutput[i])
    {
      datPoint = (double) globalData->intVariables.algebraics[i];
      fp.write((char*)&datPoint,sizeof(double));
    }
  for (int i = 0; i < globalData->boolVariables.nAlgebraic; i++) if (!globalData->boolVariables.algebraicsFilterOutput[i])
    {
      datPoint = (double) globalData->boolVariables.algebraics[i];
      fp.write((char*)&datPoint,sizeof(double));
    }

  if (!fp) throw SimulationResultBaseException();
  ++ntimepoints;
  rt_accumulate(SIM_TIMER_OUTPUT);
}

// from an array of string creates flatten 'char*'-array suitable to be 
// stored as MAT-file matrix
static inline void fixDerInName(char *str, size_t len)
{
  char* dot;
  if (len < 6) return;
  
  // check if name start with "der(" and includes at least one dot
  while (strncmp(str,"der(",4) == 0 && (dot = strrchr(str,'.')) != NULL) {
    size_t pos = (size_t)(dot-str)+1;
    // move prefix to the begining of string :"der(a.b.c.d)" -> "a.b.c.b.c.d)"
    for(size_t i = 4; i < pos; ++i)
      str[i-4] = str[i];
    // move "der(" to the end of prefix
    // "a.b.c.b.c.d)" -> "a.b.c.der(d)"
    strncpy(&str[pos-4],"der(",4);
  }
}

long simulation_result_mat::flattenStrBuf(int dims, 
            const struct omc_varInfo** src,
            char* &dest, int& longest, int& nstrings,
            bool fixNames, bool useComment)
{
  int i,len;
  nstrings = dims;
  longest = 0; // the longest-string length

  // calculate required size
  for (i = 0; i < dims; ++i) {
    len = strlen(useComment ? src[i]->comment : src[i]->name);
    if (len > longest) longest = len;
  }

  // allocate memory
  dest = new char[longest*nstrings+1];
  memset(dest,0,(longest*nstrings+1)*sizeof(char));
  if (!dest) throw SimulationResultMallocException();
  // copy data
  char *ptr = dest;
  for (i = 0; i < dims; ++i) {
    strncpy(ptr,useComment ? src[i]->comment : src[i]->name,longest+1 /* ensures that we get \0 after the longest string*/);
    if (fixNames) fixDerInName(ptr,strlen(useComment ? src[i]->comment : src[i]->name));
    ptr += longest;
  }
  // return the size of the `dest' buffer
  return (longest*nstrings);
}

// writes MAT-file matrix header to file
void simulation_result_mat::writeMatVer4MatrixHeader(const char *name,
                 int rows, int cols,
                 bool is_text)
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
  
  // create matrix header structure
  hdr.type = 1000*((*(char*)&endian_test) == 0) + (is_text? 51 : 0);
  hdr.mrows = rows;
  hdr.ncols = cols;
  hdr.imagf = 0;
  hdr.namelen = strlen(name)+1;
  // write header to file
  fp.write((char*)&hdr, sizeof(MHeader_t));
  if (!fp) throw SimulationResultFileCloseException();
  fp.write(name, sizeof(char)*hdr.namelen);
  if (!fp) throw SimulationResultFileCloseException();
}

void simulation_result_mat::writeMatVer4Matrix(const char *name, 
                 int rows, int cols, 
                 const void *data, bool is_text)
{
  writeMatVer4MatrixHeader(name,rows,cols,is_text);

  // write data
  fp.write((const char*)data, (is_text ? sizeof(char) : sizeof(double))*rows*cols);
  if (!fp) throw SimulationResultFileCloseException();
}


void simulation_result_mat::generateDataInfo(double* &dataInfo, 
               int& rows, int& cols,
               const sim_DATA *mdl_data,
               int nVars, int nParams)
{
  //size_t nVars = mdl_data->nStates*2+mdl_data->nAlgebraic;
  //rows = 1+nVars+mdl_data->nParameters+mdl_data->nVarsAliases;
  size_t ccol = 0; // current column - index offset

  // assign rows & cols
  rows = 1+ nVars + nParams;
  cols = 4;
  
  dataInfo = new double[rows*cols];
  if (dataInfo == NULL) throw SimulationResultMallocException();
  // time variable
  dataInfo[0] = 0.0;
  dataInfo[1] = 1.0;
  dataInfo[2] = 0.0;
  dataInfo[3] = -1.0;
  ccol += 4;
  // continuous and discrete variables
  for(size_t i = 0; i < (size_t)nVars; ++i) {
    // row 1 - which table
    dataInfo[ccol+4*i] = 2.0;
    // row 2 - index of var in table (variable 'Time' have index 1)
    dataInfo[ccol+4*i+1] = i+2.0;
    // row 3 - linear interpolation == 0
    dataInfo[ccol+4*i+2] = 0.0;
    // row 4 - not defined outside of the defined time range == -1
    dataInfo[ccol+4*i+3] = -1.0;
  }
  ccol += nVars*4;
  // parameters and constants
  for(size_t i = 0; i < (size_t)nParams; ++i) {
    // col 1 - which table
    dataInfo[ccol+4*i] = 1.0;
    // col 2 - index of var in the table (first parameter has index 2)
    dataInfo[ccol+4*i+1] = i+2.0;
    // col 3 (== 0 <- interpolation doesn't matter here)
    dataInfo[ccol+4*i+2] = 0.0;
    // col 4 - keep first/last value outside of time range
    dataInfo[ccol+4*i+3] = 0.0;

  }
  //ccol += mdl_data->nParameters*4;
}

void simulation_result_mat::generateData_1(double* &data_1, 
             int& rows, int& cols,
             const sim_DATA *mdl_data,
             double tstart, double tstop)
{
  int offset;
  // calculate number of rows and columns
  rows = 2;
  cols = 1+mdl_data->nParameters+mdl_data->intVariables.nParameters
    +mdl_data->boolVariables.nParameters;
  // allocate data buffer
  data_1 = new double[rows*cols];
  if (data_1 == NULL) 
    throw SimulationResultMallocException();
  data_1[0] = tstart; // start time
  data_1[cols] = tstop; // stop time
  offset = 1;
  // double variables
  for(fortran_integer i = 0; i < mdl_data->nParameters; ++i) {
      data_1[offset+i] = mdl_data->parameters[i];
      data_1[offset+i+cols] = mdl_data->parameters[i];
  }
  offset += mdl_data->nParameters;
  // integer variables
  for(fortran_integer i = 0; i < mdl_data->intVariables.nParameters; ++i) {
    data_1[offset+i] = (double)mdl_data->intVariables.parameters[i];
    data_1[offset+i+cols] = (double)mdl_data->intVariables.parameters[i];
  }
  offset += mdl_data->intVariables.nParameters;
  // bool variables
  for(fortran_integer i = 0; i < mdl_data->boolVariables.nParameters; ++i) {
    data_1[offset+i] = (double)mdl_data->boolVariables.parameters[i];
    data_1[offset+i+cols] = (double)mdl_data->boolVariables.parameters[i];
  }
   
}
