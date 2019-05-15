/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

#include "options.h"
#include "../util/omc_error.h"
#include "simulation_runtime.h"

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

#if !defined(OMC_MINIMAL_RUNTIME)
int setLogFormat(int argc, char** argv)
{
  const char* value = getOption(FLAG_NAME[FLAG_LOG_FORMAT], argc, argv);
  if (NULL == value) {
    value = getFlagValue(FLAG_NAME[FLAG_LOG_FORMAT], argc, argv);
  }

  if (NULL != value) {
    if (0 == strcmp(value, "xml")) {
      setStreamPrintXML(1);
    } else if (0 == strcmp(value, "xmltcp")) {
      setStreamPrintXML(2);
    } else if (0 == strcmp(value, "text")) {
      setStreamPrintXML(0);
    } else {
      warningStreamPrint(LOG_STDOUT, 0, "invalid command line option: -logFormat=%s, expected text, xml, or xmltcp", value);
      return 1;
    }
  }
  return 0;
}
#endif

int checkCommandLineArguments(int argc, char **argv)
{
  int i,j;

  /* This works not that well - but is probably better than no check */
  assertStreamPrint(NULL, !strcmp(FLAG_NAME[FLAG_MAX], "FLAG_MAX"), "unbalanced command line flag structure: FLAG_NAME");
  assertStreamPrint(NULL, !strcmp(FLAG_DESC[FLAG_MAX], "FLAG_MAX"), "unbalanced command line flag structure: FLAG_DESC");
  assertStreamPrint(NULL, !strcmp(FLAG_DETAILED_DESC[FLAG_MAX], "FLAG_MAX"), "unbalanced command line flag structure: FLAG_DETAILED_DESC");

  for(i=0; i<FLAG_MAX; ++i)
  {
    omc_flag[i] = 0;
    omc_flagValue[i] = NULL;
  }

#ifdef USE_DEBUG_OUTPUT
  debugStreamPrint(LOG_STDOUT, 1, "used command line options");
  for(i=1; i<argc; ++i)
    debugStreamPrint(LOG_STDOUT, 0, "%s", argv[i]);
  messageClose(LOG_STDOUT);

  debugStreamPrint(LOG_STDOUT, 1, "interpreted command line options");
#endif

  for(i=1; i<argc; ++i)
  {
    int found=0;

    for(j=1; j<FLAG_MAX; ++j)
    {
      if((FLAG_TYPE[j] == FLAG_TYPE_FLAG) && flagSet(FLAG_NAME[j], 1, argv+i))
      {
        if(omc_flag[j]) {
          warningStreamPrint(LOG_STDOUT, 0, "each command line option can only be used once: %s", argv[i]);
          return 1;
        }

        omc_flag[j] = 1;
        found=1;

#ifdef USE_DEBUG_OUTPUT
        debugStreamPrint(LOG_STDOUT, 0, "-%s", FLAG_NAME[j]);
#endif

        break;
      } else if((FLAG_TYPE[j] == FLAG_TYPE_OPTION) && flagSet(FLAG_NAME[j], 1, argv+i) && (i+1 < argc)) {
        if(omc_flag[j]) {
          warningStreamPrint(LOG_STDOUT, 0, "each command line option can only be used once: %s", argv[i]);
          return 1;
        }

        omc_flag[j] = 1;
        omc_flagValue[j] = (char*)getFlagValue(FLAG_NAME[j], 1, argv+i);
        i++;
        found=1;

#ifdef USE_DEBUG_OUTPUT
        debugStreamPrint(LOG_STDOUT, 0, "-%s %s", FLAG_NAME[j], omc_flagValue[j]);
#endif

        break;
      } else if((FLAG_TYPE[j] == FLAG_TYPE_OPTION) && optionSet(FLAG_NAME[j], 1, argv+i)) {
        if(omc_flag[j]) {
          warningStreamPrint(LOG_STDOUT, 0, "each command line option can only be used once: %s", argv[i]);
          return 1;
        }

        omc_flag[j] = 1;
        omc_flagValue[j] = (char*)getOption(FLAG_NAME[j], 1, argv+i);
        found=1;

#ifdef USE_DEBUG_OUTPUT
        debugStreamPrint(LOG_STDOUT, 0, "-%s=%s", FLAG_NAME[j], omc_flagValue[j]);
#endif
        break;
      }
    }

    if(!found)
    {
#ifdef USE_DEBUG_OUTPUT
  messageClose(LOG_STDOUT);
#endif
      warningStreamPrint(LOG_STDOUT, 0, "invalid command line option: %s", argv[i]);
      return 1;
    }
  }

#ifdef USE_DEBUG_OUTPUT
  messageClose(LOG_STDOUT);
#endif

  return 0;
}

static int flagSet(const char *option, int argc, char** argv)
{
  int i;
  for(i=0; i<argc; i++) {
    if((argv[i][0] == '-') && (0 == strcmp(option, argv[i]+1))) {
      return 1;
    }
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
  for(i=0; i<argc; i++) {
    if((argv[i][0] == '-') && (0 == strncmp(option, argv[i]+1, optLen)) && (argv[i][optLen+1] == '=')) {
      return argv[i] + optLen + 2;
    }
  }
  return NULL;
}

/* returns the value of a flag on the form -flagname value */
static const char* getFlagValue(const char *option, int argc, char **argv)
{
  int i;
  for(i=0; i<argc; i++) {
    if((argv[i][0] == '-') && (0 == strcmp(option, argv[i]+1))) {
      return argv[i+1];
    }
  }
  return NULL;
}
