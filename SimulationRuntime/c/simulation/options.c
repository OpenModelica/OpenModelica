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

static int flagSet(const char*, int, char**);                        /* -f */
static int optionSet(const char *option, int argc, char** argv);     /* -f=value */
static const char* getOption(const char*, int, char **);             /* -f=value; returns NULL if not found */
static const char* getFlagValue(const char *, int , char **);        /* -f value; returns NULL if not found */

int omc_flag[FLAG_MAX];
const char *omc_flagValue[FLAG_MAX];

int helpFlagSet(int argc, char** argv)
{
  return flagSet("?", argc, argv) || flagSet("help", argc, argv);
}

int checkCommandLineArguments(int argc, char **argv)
{
  int i,j;

  /* This works not that well - but is probably better than no check */
  ASSERT(!strcmp(FLAG_NAME[FLAG_MAX], "FLAG_MAX"), "unbalanced command line flag structure: FLAG_NAME");
  ASSERT(!strcmp(FLAG_DESC[FLAG_MAX], "FLAG_MAX"), "unbalanced command line flag structure: FLAG_DESC");
  ASSERT(!strcmp(FLAG_DETAILED_DESC[FLAG_MAX], "FLAG_MAX"), "unbalanced command line flag structure: FLAG_DETAILED_DESC");

  for(i=0; i<FLAG_MAX; ++i)
  {
    omc_flag[i] = 0;
    omc_flagValue[i] = NULL;
  }

#ifdef USE_DEBUG_OUTPUT
  DEBUG(LOG_STDOUT, "used command line options");
  INDENT(LOG_STDOUT);
  for(i=1; i<argc; ++i)
    DEBUG1(LOG_STDOUT, "%s", argv[i]);
  RELEASE(LOG_STDOUT);

  DEBUG(LOG_STDOUT, "interpreted command line options");
#endif

  for(i=1; i<argc; ++i)
  {
    int found=0;

    for(j=1; j<FLAG_MAX; ++j)
    {
      if((FLAG_TYPE[j] == FLAG_TYPE_FLAG) && flagSet(FLAG_NAME[j], 1, argv+i))
      {
        if(omc_flag[j])
        {
          WARNING1(LOG_STDOUT, "each command line option can only be used once: %s", argv[i]);
          return 1;
        }

        omc_flag[j] = 1;
        found=1;

#ifdef USE_DEBUG_OUTPUT
        INDENT(LOG_STDOUT);
        DEBUG1(LOG_STDOUT, "-%s", FLAG_NAME[j]);
        RELEASE(LOG_STDOUT);
#endif

        break;
      }
      else if((FLAG_TYPE[j] == FLAG_TYPE_OPTION) && flagSet(FLAG_NAME[j], 1, argv+i) && (i+1 < argc))
      {
        if(omc_flag[j])
        {
          WARNING1(LOG_STDOUT, "each command line option can only be used once: %s", argv[i]);
          return 1;
        }

        omc_flag[j] = 1;
        omc_flagValue[j] = (char*)getFlagValue(FLAG_NAME[j], 1, argv+i);
        i++;
        found=1;

#ifdef USE_DEBUG_OUTPUT
        INDENT(LOG_STDOUT);
        DEBUG2(LOG_STDOUT, "-%s %s", FLAG_NAME[j], omc_flagValue[j]);
        RELEASE(LOG_STDOUT);
#endif

        break;
      }
      else if((FLAG_TYPE[j] == FLAG_TYPE_OPTION) && optionSet(FLAG_NAME[j], 1, argv+i))
      {
        if(omc_flag[j])
        {
          WARNING1(LOG_STDOUT, "each command line option can only be used once: %s", argv[i]);
          return 1;
        }

        omc_flag[j] = 1;
        omc_flagValue[j] = (char*)getOption(FLAG_NAME[j], 1, argv+i);
        found=1;

#ifdef USE_DEBUG_OUTPUT
        INDENT(LOG_STDOUT);
        DEBUG2(LOG_STDOUT, "-%s=%s", FLAG_NAME[j], omc_flagValue[j]);
        RELEASE(LOG_STDOUT);
#endif
        break;
      }
    }

    if(!found)
    {
      WARNING1(LOG_STDOUT, "invalid command line option: %s", argv[i]);
      return 1;
    }
  }

  return 0;
}

static int flagSet(const char *option, int argc, char** argv)
{
  int i;
  for(i=0; i<argc; i++)
  {
    if((argv[i][0] == '-') && (0 == strcmp(option, argv[i]+1)))
      return 1;
  }
  return 0;
}

static int optionSet(const char *option, int argc, char** argv)
{
  return getOption(option, argc, argv) != NULL;
}

/* returns the value of a flag on the form -flagname=value */
static const char* getOption(const char *option, int argc, char **argv)
{
  int optLen = strlen(option), i;
  for(i=0; i<argc; i++)
  {
    if((argv[i][0] == '-') && (0 == strncmp(option, argv[i]+1, optLen)) && (argv[i][optLen+1] == '='))
      return argv[i] + optLen + 2;
  }
  return NULL;
}

/* returns the value of a flag on the form -flagname value */
static const char* getFlagValue(const char *option, int argc, char **argv)
{
  int i;
  for(i=0; i<argc; i++)
  {
    if((argv[i][0] == '-') && (0 == strcmp(option, argv[i]+1)))
      return argv[i+1];
  }
  return NULL;
}
