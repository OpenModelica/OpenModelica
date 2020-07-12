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


/* Interface for pltolemy plot format.
  Peter Aronsson. 2003-10-30
*/
#include <iostream>
#include <fstream>
#include <string>

#include "util/omc_numbers.h"


using namespace std;

extern "C"
{
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include "util/omc_msvc.h" /* For INFINITY and NAN */
#include "ptolemyio.h"
#include "errorext.h"

/* Given a file name and an array of variables, return the MetaModelica datastructure
   in Values for Real[size(vars,1],:] i.e. a matrix of variable values, one column for each variable. */
void * read_ptolemy_dataset(const char*filename, void* vars,int datasize)
{
  char buf[255];
  void *lst,*olst,*dimLst,*odimLst;
  ifstream stream(filename);

  if (!stream) {
    c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, "Error opening result file %s.", &filename, 1);
    return NULL;
  }

  // Find interval size
  while( stream.getline(buf,255) && string(buf).find("#IntervalSize") == string(buf).npos);
  string intervalText=string(buf);
  int equalPos=intervalText.find("=");
  int readIntervalSize = atoi(intervalText.substr(equalPos+1).c_str());
  // exit if intervals not compatible...
  if (datasize == 0) {
    datasize = readIntervalSize;
  } else {
    if( readIntervalSize == 0) {
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, "could not read interval size.", NULL, 0);
      return NULL;
    }
    if (readIntervalSize != datasize) {
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, "interval size not matching data size.", NULL, 0);
      return NULL;
    }
  }
  olst = mmc_mk_nil();
  while (MMC_NILHDR != MMC_GETHDR(vars)) {
    string readstr;
    double val; char ch;
    const char *cvar = MMC_STRINGDATA(MMC_CAR(vars));
    string var(string("DataSet: ")+cvar);
    vars = MMC_CDR(vars);

    stream.seekg(0); //Reset stream
    // Search to the correct position.
    stream.getline(buf,255);
    while( string(buf).find(var) == string(buf).npos || strlen(buf) > var.length()) {
      if (!stream.getline(buf,255)) {
        // if we reached end of file return..
        c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, "Variable %s not found in simulation result.", &cvar, 1);
        return NULL;
      }
    }

    lst = mmc_mk_nil();
    int j=0;
    while(j<datasize) {
      const char* buf1;
      char* buf2;

      stream.getline(buf,255);

      if (string(buf).find("DataSet:") == 1) {
        break;
      }
      string values(buf);
      int commapos=values.find(",");

      buf1 = values.substr(commapos+1).c_str();
      val = om_strtod(buf1,&buf2); // Second value after comma

      if (buf1 == buf2) {
        // We may be trying to parse Infinity on a Windows platform.
        // Don't we feel stupid expecting this to work?
        if (0 == strncmp(buf1,"Inf",3)) val = INFINITY;
        else if (0 == strncmp(buf1,"-Inf",4)) val = -INFINITY;
        else if (0 == strncmp(buf1,"inf",3)) val = INFINITY;
        else if (0 == strncmp(buf1,"-inf",4)) val = -INFINITY;
        // Don't put 0.0 if the value is undefined.
        // NaN sends a clear signal to the user that he has a problem.
        else val = NAN;
      }

      lst = (void*)mmc_mk_cons(mmc_mk_rcon(val),lst);
      j++;
    }

    olst = (void*)mmc_mk_cons(lst,olst);
  }
  return olst;
}

void* read_ptolemy_variables(const char* filename)
{
  string intervalText;
  void *res;
  char var[256];
  ifstream stream(filename);
  if (!stream) return mmc_mk_nil();
  res = mmc_mk_nil();
  while (getline(stream,intervalText)) {
    if (sscanf(intervalText.c_str(),"DataSet: %250s", var) == 1) res = mmc_mk_cons(mmc_mk_scon(var),res);
  }
  return res;
}

/* Given a file name, returns the size of that simulation result in that file*/
int read_ptolemy_dataset_size(const char*filename)
{
  char buf[255];
  ifstream stream(filename);

  if (!stream) return -1;

  string intervalText;
  // Find interval size
  while (getline(stream,intervalText) && intervalText.find("#IntervalSize") == string::npos);
  if (intervalText.find("#IntervalSize") == string::npos) return -1;
  int equalPos=intervalText.find("=");
  int readIntervalSize = atoi(intervalText.substr(equalPos+1).c_str());
  // exit if intervals not compatible...
  if( readIntervalSize == 0) return -1;
  return readIntervalSize;
}

}
