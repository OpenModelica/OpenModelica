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

#include <string.h>
#include <stdio.h>

int checkCommandLineArguments(int argc, char **argv)
{
  int i,j;
  for(i=1; i<argc; ++i)
  {
    int found=0;
    for(j=1; j<FLAG_MAX; ++j)
    {
      if (((FLAG_TYPE[j] == FLAG_TYPE_FLAG) && flagSet(FLAG_NAME[j],1,argv+i)) ||
          ((FLAG_TYPE[j] == FLAG_TYPE_FLAG_VALUE) && flagSet(FLAG_NAME[j],1,argv+i) && (++i < argc)) ||
          ((FLAG_TYPE[j] == FLAG_TYPE_OPTION) && optionSet(FLAG_NAME[j],1,argv+i))) {
        found=1;
        break;
      }
    }
    if (!found) {
      WARNING1(LOG_STDOUT, "invalid command line option: %s", argv[i]);
      return 1;
    }
  }
  
  return 0;
}

int flagSet(const char *option, int argc, char** argv)
{
  int i;
  for (i=0; i<argc;i++)
  {
    if (argv[i][0] == '-' && 0==strcmp(option,argv[i]+1))
      return 1;
  }
  return 0;
}

int optionSet(const char *option, int argc, char** argv)
{
  return getOption(option,argc,argv) != NULL;
}

/* returns the value of a flag on the form -flagname=value */
const char* getOption(const char *option, int argc, char **argv)
{
  int optLen = strlen(option), i;
  for (i=0; i<argc;i++) {
    if (argv[i][0] == '-' && 0==strncmp(option,argv[i]+1,optLen) && argv[i][optLen+1]=='=') {
      return argv[i]+optLen+2;
    }
  }
  return NULL;
}

/* returns the value of a flag on the form -flagname value */
const char* getFlagValue(const char *option, int argc, char **argv)
{
  int i;
  for(i=0; i<argc-1;i++)
  {
    if (argv[i][0] == '-' && 0==strcmp(option,argv[i]+1))
      return argv[i+1];
  }
  return NULL;
}
