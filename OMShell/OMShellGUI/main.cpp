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


/*!
 * \file otherdlg.h
 * \author Anders Fernström
 */

// QT Headers
#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#define toAscii toLatin1
#else
#include <QtGui/QApplication>
#include <QTranslator>
#include <QLocale>
#endif

#include "oms.h"
#include "omcinteractiveenvironment.h"
#include <stdio.h>

#define GC_THREADS

extern "C" {
#include "meta/meta_modelica.h"
}

#define CONSUME_CHAR(value,res,i) \
    if (value.at(i) == '\\') { \
    i++; \
    switch (value[i].toAscii()) { \
    case '\'': res.append('\''); break; \
    case '"':  res.append('\"'); break; \
    case '?':  res.append('\?'); break; \
    case '\\': res.append('\\'); break; \
    case 'a':  res.append('\a'); break; \
    case 'b':  res.append('\b'); break; \
    case 'f':  res.append('\f'); break; \
    case 'n':  res.append('\n'); break; \
    case 'r':  res.append('\r'); break; \
    case 't':  res.append('\t'); break; \
    case 'v':  res.append('\v'); break; \
    } \
    } else { \
    res.append(value[i]); \
    }

QString unparse(QString value)
{
    QString res;
    value = value.trimmed();
    if (value.length() > 1 && value.at(0) == '\"' && value.at(value.length() - 1) == '\"') {
        value = value.mid(1, (value.length() - 2));
        for (int i=0; i < value.length(); i++) {
            CONSUME_CHAR(value,res,i);
        }
        return res;
    } else {
        return "";
    }
}

int main(int argc, char *argv[])
{
  MMC_INIT();
  MMC_TRY_TOP()

  QApplication app(argc, argv);

  IAEX::OmcInteractiveEnvironment *env = IAEX::OmcInteractiveEnvironment::getInstance(threadData);
  env->evalExpression("getInstallationDirectoryPath()");
  QString dir = unparse(env->getResult()) + "/share/omshell/nls";
  QString locale = QString("OMShell_") + QLocale::system().name();

  QTranslator translator;
  translator.load(locale, dir);
  app.installTranslator(&translator);

  // Avoid cluttering the whole disk with omc temp-files
  QString tmpDir = env->TmpPath();
  if (!QDir().exists(tmpDir)) QDir().mkdir(tmpDir);
  tmpDir = QDir(tmpDir).canonicalPath();
  //std::cout << "Temp.Dir " << tmpDir.toStdString() << std::endl;
  QString cdCmd = "cd(\"" + tmpDir + "\")";
  env->evalExpression(cdCmd);
  QString cdRes = env->getResult();
  cdRes.remove("\"");
  if (0 != tmpDir.compare(cdRes)) {
    QMessageBox::critical( 0, "OpenModelica Error", QString("Could not create or cd to temp-dir\nCommand:\n  %1\nReturned:\n  %2").arg(cdCmd).arg(cdRes));
    exit(1);
  }

  OMS oms;
  oms.show();

  return app.exec();

  MMC_CATCH_TOP();
}
