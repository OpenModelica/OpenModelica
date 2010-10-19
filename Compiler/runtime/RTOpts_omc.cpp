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

#include "modelica.h"

extern "C" {
#include "rtoptsimpl.c"

extern int showErrorMessages;

const char* corbaSessionName = ""; // TODO: Move this to corbaimpl when bootstrapped version has that file

extern int RTOpts_debugFlag(const char* flag) {
  return check_debug_flag(flag)!=0;
}

extern modelica_metatype RTOpts_args(modelica_metatype args) {
  modelica_metatype res = mmc_mk_nil();

  while (MMC_GETHDR(args) != MMC_NILHDR)
  {
    modelica_metatype head = MMC_CAR(args);
    const char *arg = MMC_STRINGDATA(head);
    switch (RTOptsImpl__arg(arg)) {
    case ARG_FAILURE:
      throw 1;
      break;
    case ARG_CONSUME:
      break;
    case ARG_SUCCESS:
      res = mmc_mk_cons(head, res);
      break;
    }
    args = MMC_CDR(args);
  }
  return listReverse(res);
}

}
