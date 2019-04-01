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
 * For more information about the Qt-library visit TrollTech's webpage
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
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
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#else
#include <QtCore>
#include <QtGui/QMessageBox>
#endif

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

#define GC_THREADS

extern "C" {
#include "meta/meta_modelica.h"
}

#include <locale.h>

using namespace std;
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
    CellApplication a(argc, argv, threadData);
    return a.exec();
  }
  catch(exception &e)
  {
    // 2006-01-30 AF, add message box
    QString msg = QString("In main(), exception: \n") + e.what();
    QMessageBox::warning( 0, "Warning", msg, "OK" );
  }

  return 0;

  MMC_CATCH_TOP();
}

