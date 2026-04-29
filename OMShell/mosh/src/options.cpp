/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "options.h"

#include <string>

bool flagSet(const char *option, int argc, char** argv)
{
  for (int i=0; i<argc;i++) {
    if (("-" + std::string(option)) == std::string(argv[i])) return true;
  }
  return false;
}
/* returns the value of a flag on the form -flagname=value
 */
const std::string* getOption(const char *option, int argc, char **argv)
{
  for (int i=0; i<argc;i++) {
    std::string tmpStr = std::string(argv[i]);
    if (("-" + std::string(option))==(tmpStr.substr(0,tmpStr.find("=")))) {
      std::string str = std::string(argv[i]);
      return new std::string(str.substr(str.find("=")+1));
    }
  }
  return NULL;
}
/* returns the value of a flag on the form -flagname value */
const std::string* getFlagValue(const char *option, int argc, char **argv)
{
  for (int i=0; i<argc;i++) {
    std::string tmpStr = std::string(argv[i]);
    if (("-" + std::string(option)) == std::string(argv[i])) {
      if (argc >= i+1) {
        return new std::string(argv[i+1]);
      }
    }
  }
  return NULL;
}
