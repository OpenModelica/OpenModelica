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

/*
  Stores results into MAT-file version 4 in format of Dymosim's result file.

  Specifications of MAT-file ver4 are available from:
  http://www.mathworks.com/access/helpdesk/help/pdf_doc/matlab/matfile_format.pdf

  Specification of Dymosim's result file are available from (pages 213-214):
  http://www.inf.ethz.ch/personal/cellier/Lect/MMPS/Refs/Dymola5Manual.pdf
 */

#ifndef _SIMULATION_RESULT_MAT_H_
#define _SIMULATION_RESULT_MAT_H_

#include "simulation_result.h"
#include "simulation_data.h"

#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <utility>



class simulation_result_mat : public simulation_result {
public:
  simulation_result_mat(const char* filename, double tstart, double tstop, MODEL_DATA *modelData);
  virtual ~simulation_result_mat();
  virtual void emit(DATA *data);
  void writeParameterData(MODEL_DATA *modelData);
  virtual const char* result_type() { 
    /* return "Dymosim's compatible MAT-file"; */
    return "mat";
  }

  typedef std::pair<void*,int> indx_type;

private:
  std::ofstream fp;
  std::ofstream::pos_type data1HdrPos; // position of data_1 matrix's header in a file
  std::ofstream::pos_type data2HdrPos; /* position of data_2 matrix's header in a file */
  unsigned long ntimepoints; /* count of how many time emits() was called */
  double startTime; // the start time
  double stopTime;  // the stop time

  typedef std::map<int,int> INTMAP;

  INTMAP r_indx_map;
  INTMAP r_indx_parammap;
  INTMAP i_indx_map;
  INTMAP i_indx_parammap;
  INTMAP b_indx_map;
  INTMAP b_indx_parammap;
  
  int numVars;

  /* helper functions */  
  long flattenStrBuf(int dims, const struct VAR_INFO** src,
          char* &dest, int& longest, int& nstrings, 
          bool fixNames, bool useComment);
  void writeMatVer4MatrixHeader(const char *name, int rows, int cols,
        unsigned int size);
  void writeMatVer4Matrix(const char *name, int rows, int cols, 
        const void *data, unsigned int size);
  void generateDataInfo(int* &dataInfo, int& rows, int& cols,
             const MODEL_DATA *mdl_data, int nVars, int nParams);
  void generateData_1(double* &data_1, int& rows, int& cols,
           const MODEL_DATA *mdl_data, double tstart, double tstop);

  int calcDataSize(MODEL_DATA *modelData);
  const VAR_INFO** calcDataNames(int dataSize, MODEL_DATA *modelData);
};

#endif /* _SIMULATION_RESULT_MAT_H_ */
