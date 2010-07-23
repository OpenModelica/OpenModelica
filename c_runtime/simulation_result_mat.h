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

#include <fstream>

#include "simulation_result.h"
#include "simulation_runtime.h"

class simulation_result_mat : public simulation_result {
public:
  simulation_result_mat(const char* filename, double tstart, double tstop);
  virtual ~simulation_result_mat();
  virtual void emit();
  virtual const char* result_type() { 
    //return "Dymosim's compatible MAT-file"; 
    return "mat";
  }
private:
  std::ofstream fp;
  std::ofstream::pos_type data2HdrPos; // position of data_2 matrix's header in a file
  unsigned long ntimepoints; // count of how many time emits() was called

  // helper functions  
  static long flattenStrBuf(int rank, const int *dims, const char ** const src[],
			    char* &dest, int& longest, int& nstrings);
  void writeMatVer4MatrixHeader(const char *name, int rows, int cols,
				bool is_text);
  void writeMatVer4Matrix(const char *name, int rows, int cols, 
			  const void *data, bool is_text);
  static void generateDataInfo(double* &dataInfo, int& rows, int& cols,
			       const sim_DATA *mdl_data);
};

#endif /* _SIMULATION_RESULT_MAT_H_ */
