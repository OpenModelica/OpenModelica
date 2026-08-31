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

#include "openmodelica.h"
#include "modelica.h"
#include "meta_modelica.h"
#include "Database.c"

void Database_init(void)
{
   DatabaseImpl_init();
}

void Database__open(int index, const char* name)
{
  if (DatabaseImpl_open(index, name))
  {
    MMC_THROW();
  }
}

void* Database__query(int index, const char* sql)
{
  void* result = mmc_mk_nil();
  if (!DatabaseImpl_query(index, sql, &result))
  {
    return result;
  }
  MMC_THROW();
}

static int callback(void *result, int argc, char **argv, char **azColName){
  int i;
  void** res = (void**)result;
  for(i = 0; i < argc; i++)
  {
    /* the result is a list of string tuples (name, value)*/
    *res = mmc_mk_cons(mmc_mk_box2(0, mmc_mk_scon(azColName[i]), mmc_mk_scon(argv[i] ? argv[i] : "NULL")), *res);
  }
  return 0;
}
