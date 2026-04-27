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

/*! \file qtapp.cpp
 *  \brief Mainprogram. This is just Qt startup code.
 */

//STD Headers
#include <exception>
#include <stdexcept>
#include <iostream>

//QT Headers
#include <QtGlobal>
#include <QtWidgets>

//IAEX Headers
#include "notebook.h"
#include "application.h"
#include "cellapplication.h"

#ifdef Q_OS_MAC
//need to increase stack size on OSX
#include <sys/resource.h>
#include <sys/types.h>
#include <sys/time.h>
#endif

#ifndef GC_THREADS
#define GC_THREADS
#endif

extern "C" {
#include "meta/meta_modelica.h"
}

#include <locale.h>

using namespace IAEX;

int main(int argc, char *argv[])
{

#ifdef Q_OS_MAC
  //need to increase stack size on OSX
  rlimit limits;
  getrlimit(RLIMIT_STACK, &limits);
  limits.rlim_cur = limits.rlim_max;
  setrlimit(RLIMIT_STACK, &limits);

  // App path is not same as command line path, so add /Library/TeX/texbin and /usr/texbin for latex-cell support
  qputenv("PATH", qgetenv("PATH") + ":/Library/TeX/texbin:/usr/texbin");
#endif

  MMC_INIT();
  MMC_TRY_TOP()

  try
  {
#if (QT_VERSION >= QT_VERSION_CHECK(5, 6, 0) && QT_VERSION < QT_VERSION_CHECK(6, 0, 0))
    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    CellApplication a(argc, argv, threadData);
    return a.exec();
  }
  catch(std::exception &e)
  {
    // 2006-01-30 AF, add message box
    QString msg = QString("In main(), exception: \n") + e.what();
    QMessageBox::warning(nullptr, "Warning", msg);
  }

  return 0;

  MMC_CATCH_TOP();
}

