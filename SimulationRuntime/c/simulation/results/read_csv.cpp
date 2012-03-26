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

#include <iostream>
#include <fstream>
#include <string>
#include <vector>

using namespace std;

extern "C"
{
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "read_csv.h"

char** read_csv_variables(const char* filename)
{
  string header;
  string variable;
  vector<string> variablesList;
  bool startReading = false;
  int length;

  ifstream stream(filename);

  getline(stream,header);
  length = strlen(header.c_str());

  for (int i = 0 ; i < length ; i++)
  {
    if (startReading)
      variable.append(1,header[i]);

    if (header[i] == '"') {
      if (startReading) {
        if (header[i+1] == ',') {
          startReading = false;
          variablesList.push_back(variable.erase((strlen(variable.c_str()) - 1), 1));
          variable.clear();
        }
      } else {
        startReading = true;
      }
    }
  }

  char **res = (char**)malloc((1+variablesList.size())*sizeof(char));
  for (unsigned int k = 0 ; k < variablesList.size(); k++)
  {
    res[k] = strdup(variablesList.at(k).c_str());
  }
  res[variablesList.size()] = NULL;
  return res;
}

}
