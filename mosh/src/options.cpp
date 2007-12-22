/* 
 * This file is part of OpenModelica.
 * 
 * Copyright (c) 1998-2008, Linköpings University,
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

#include "options.h"

#include <string>

using namespace std;

bool flagSet(char *option, int argc, char** argv)
{
  for (int i=0; i<argc;i++) {
    if (("-"+string(option))==string(argv[i])) return true;
  }
  return false;
}
/* returns the value of a flag on the form -flagname=value
 */
const string* getOption(const char *option, int argc, char **argv)
{
  for (int i=0; i<argc;i++) {
    string tmpStr=string(argv[i]);
    if (("-"+string(option))==(tmpStr.substr(0,tmpStr.find("=")))) {
      string str=string(argv[i]);
      return new string(str.substr(str.find("=")+1));
    }
  }
  return NULL;
}
/* returns the value of a flag on the form -flagname value */
const string* getFlagValue(const char *option, int argc, char **argv)
{
  for (int i=0; i<argc;i++) {
    string tmpStr=string(argv[i]);
    if (("-"+string(option))==string(argv[i])) {
      if (argc >= i+1) {
	return new string(argv[i+1]);
      }
    }
  } 
  return NULL;
}
