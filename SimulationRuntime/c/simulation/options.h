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

#ifndef OPTIONS_H
#define OPTIONS_H

#include <string>

enum _FLAG
{
  FLAG_UNKNOWN = 0,
  
  FLAG_CPU,
  FLAG_F,
  FLAG_HELP,
  FLAG_IIF,
  FLAG_IIM,
  FLAG_IIT,
  FLAG_ILS,
  FLAG_INTERACTIVE,
  FLAG_IOM,
  FLAG_JAC,
  FLAG_L,
  FLAG_LV,
  FLAG_MEASURETIMEPLOTFORMAT,
  FLAG_NLS,
  FLAG_NOEMIT,
  FLAG_NUMJAC,
  FLAG_OUTPUT,
  FLAG_OVERRIDE,
  FLAG_OVERRIDE_FILE,
  FLAG_PORT,
  FLAG_R,
  FLAG_S,
  FLAG_W,
  
  FLAG_MAX
};

enum _FLAG_TYPE
{
  FLAG_TYPE_UNKNOWN = 0,
  
  FLAG_TYPE_FLAG,         /* e.g. -f */
  FLAG_TYPE_OPTION,       /* e.g. -f=value */
  FLAG_TYPE_FLAG_VALUE,   /* e.g. -f value */
  
  FLAG_TYPE_MAX
};

extern const char *FLAG_NAME[FLAG_MAX];
extern const char *FLAG_DESC[FLAG_MAX];
extern const char *FLAG_DETAILED_DESC[FLAG_MAX];
extern const int FLAG_TYPE[FLAG_MAX];

int checkCommandLineArguments(int argc, char **argv);

int flagSet(const char*, int, char**);                        /* -f */
int optionSet(const char *option, int argc, char** argv);     /* -f=value */
const std::string* getOption(const char*, int, char **);      /* -f=value; returns NULL if not found */
const std::string* getFlagValue(const char *, int , char **); /* -f value; returns NULL if not found */

#endif
