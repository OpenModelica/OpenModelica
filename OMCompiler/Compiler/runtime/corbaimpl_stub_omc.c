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

#include <stdio.h>
#include "meta/meta_modelica.h"

static void errmsg() {
  fputs("CORBA disabled. Configure with --with-omniORB (or --with-MICO) and recompile to enable.", stderr);
}

extern int Corba_haveCorba()
{
  return 0;
}

extern void Corba_setObjectReferenceFilePath(const char* path)
{
  errmsg();
  MMC_THROW();
}

extern void Corba_setSessionName(const char* _inSessionName)
{
  errmsg();
  MMC_THROW();
}

extern const char* Corba_waitForCommand()
{
  errmsg();
  MMC_THROW();
}

extern void Corba_initialize()
{
  errmsg();
  MMC_THROW();
}

extern void Corba_close()
{
  errmsg();
  MMC_THROW();
}

extern void Corba_sendreply(const char* _inString)
{
  errmsg();
  MMC_THROW();
}
