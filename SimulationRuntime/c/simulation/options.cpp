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

#include "options.h"
#include "omc_error.h"

#include <string>

using namespace std;

int checkCommandLineArguments(int argc, char **argv)
{
  for(int i=1; i<argc; ++i)
  {
    int error = 1;  /* first, suggest an error anyway */
    string tmpStr = string(argv[i]);
    
    for(int j=1; j<FLAG_MAX; ++j)
    {
      if(tmpStr == ("-" + string(FLAG_NAME[j])))
      {
        if(FLAG_TYPE[j] == FLAG_TYPE_FLAG)
          error = 0;
        else if((FLAG_TYPE[j] == FLAG_TYPE_FLAG_VALUE) && (++i < argc))
          error = 0;
      }
      else if(tmpStr.substr(0,tmpStr.find("=")) == ("-" + string(FLAG_NAME[j])))
        error = 0;
    }
    
    if(error)
    {
      WARNING1(LOG_STDOUT, "invalid command line option: %s", argv[i]);
      return 1;
    }
  }
  
  return 0;
}

int flagSet(const char *option, int argc, char** argv)
{
  for(int i=0; i<argc;i++)
  {
    if(("-"+string(option)) == string(argv[i]))
      return 1;
  }
  return 0;
}

int optionSet(const char *option, int argc, char** argv)
{
  for(int i=0; i<argc;i++)
  {
    string tmpStr=string(argv[i]);
    if(("-"+string(option)) == (tmpStr.substr(0,tmpStr.find("="))))
      return 1;
  }
  return 0;
}

/* returns the value of a flag on the form -flagname=value */
const string* getOption(const char *option, int argc, char **argv)
{
  for(int i=0; i<argc;i++)
  {
    string tmpStr=string(argv[i]);
    if(("-"+string(option)) == (tmpStr.substr(0,tmpStr.find("="))))
      return new string(tmpStr.substr(tmpStr.find("=")+1));
  }
  return NULL;
}

/* returns the value of a flag on the form -flagname value */
const string* getFlagValue(const char *option, int argc, char **argv)
{
  for(int i=0; i<argc;i++)
  {
    string tmpStr=string(argv[i]);
    if(("-"+string(option)) == string(argv[i]))
      if(argc > i+1)
        return new string(argv[i+1]);
  }
  return NULL;
}
