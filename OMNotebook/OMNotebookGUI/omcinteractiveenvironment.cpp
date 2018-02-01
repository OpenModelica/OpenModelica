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

//STD Headers
#include <exception>
#include <stdexcept>

//QT Headers
#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#else
#include <QtCore/QDir>
#include <QtCore/QLocale>
#include <QtCore/QProcess>
#include <QtCore/QThread>
#include <QtCore/QMutex>
#include <QtCore/QSettings>
#include <QtGui/QMessageBox>
#endif

//IAEX Headers
#include "omcinteractiveenvironment.h"
#ifndef WIN32
#include "omc_config.h"
#endif
#include "gc.h"

extern "C" {
void (*omc_assert)(threadData_t*,FILE_INFO info,const char *msg,...) __attribute__((noreturn)) = omc_assert_function;
void (*omc_assert_warning)(FILE_INFO info,const char *msg,...) = omc_assert_warning_function;
void (*omc_terminate)(FILE_INFO info,const char *msg,...) = omc_terminate_function;
void (*omc_throw)(threadData_t*) __attribute__ ((noreturn)) = omc_throw_function;
int omc_Main_handleCommand(void *threadData, void *imsg, void **omsg);
void* omc_Main_init(void *threadData, void *args);
void omc_System_initGarbageCollector(void *threadData);
#ifdef WIN32
void omc_Main_setWindowsPaths(threadData_t *threadData, void* _inOMHome);
#endif
}

using namespace std;

namespace IAEX
{
  OmcInteractiveEnvironment* OmcInteractiveEnvironment::selfInstance = NULL;
  OmcInteractiveEnvironment* OmcInteractiveEnvironment::getInstance(threadData_t *threadData)
  {
    if (selfInstance == NULL)
    {
      selfInstance = new OmcInteractiveEnvironment(threadData);
    }
    return selfInstance;
  }

  /*! \class OmcInteractiveEnvironment
  *
  * \brief Implements evaluation for modelica code.
  */
  OmcInteractiveEnvironment::OmcInteractiveEnvironment(threadData_t *threadData):threadData_(threadData),result_(""),error_("")
  {
    // set the language by reading the OMEdit settings file.
    QSettings settings(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omedit");
    QLocale settingsLocale = QLocale(settings.value("language").toString());
    settingsLocale = settingsLocale.name() == "C" ? settings.value("language").toLocale() : settingsLocale;
    void *args = mmc_mk_nil();
    QString locale = "+locale=" + settingsLocale.name();
    args = mmc_mk_cons(mmc_mk_scon(locale.toStdString().c_str()), args);
    // initialize garbage collector
    omc_System_initGarbageCollector(NULL);
    MMC_TRY_TOP_INTERNAL()
    omc_Main_init(threadData, args);
    threadData_->plotClassPointer = 0;
    threadData_->plotCB = 0;
    MMC_CATCH_TOP()
    // set the +d=initialization flag default.
    evalExpression(QString("setCommandLineOptions(\"+d=initialization\")"));
#ifdef WIN32
    evalExpression(QString("getInstallationDirectoryPath()"));
    QString result = getResult();
    result = result.remove( "\"" );
    MMC_TRY_TOP_INTERNAL()
    omc_Main_setWindowsPaths(threadData, mmc_mk_scon(result.toStdString().c_str()));
    MMC_CATCH_TOP()
#endif
  }

  OmcInteractiveEnvironment::~OmcInteractiveEnvironment()
  {
    //if (selfInstance)
    //  delete selfInstance;
  }

  QString OmcInteractiveEnvironment::getResult()
  {
    return result_;
  }

  /*!
   * \author Anders FernstrÃ¶m
   * \date 2006-02-02
   *
   *\brief Method for get error message from OMC
   */
  QString OmcInteractiveEnvironment::getError()
  {
    return error_;
  }

  /*!
   * \author Hennning Kiel
   * \date 2017-05-24
   *
   *\brief Method to get error message severity from OMC
   */
  int OmcInteractiveEnvironment::getErrorLevel()
  {
    return severity;
  }

  // QMutex omcMutex;

  /*!
   * \author Ingemar Axelsson and Anders FernstrÃ¶m
   * \date 2006-02-02 (update)
   *
   * \brief Method for evaluationg expressions
   *
   * 2006-02-02 AF, Added try-catch statement
   */
  void OmcInteractiveEnvironment::evalExpression(const QString expr)
  {
    error_.clear(); // clear any error!
    // call OMC with expression
    void *reply_str = NULL;
    threadData_t *threadData = threadData_;
    MMC_TRY_TOP_INTERNAL()

    MMC_TRY_STACK()

    if (!omc_Main_handleCommand(threadData, mmc_mk_scon(expr.toStdString().c_str()), &reply_str)) {
      return;
    }
    result_ = MMC_STRINGDATA(reply_str);
    result_ = result_.trimmed();
    reply_str = NULL;
    // see if there are any errors if the expr is not "quit()"
    if (!omc_Main_handleCommand(threadData, mmc_mk_scon("getErrorString()"), &reply_str)) {
      return;
    }
    error_ = MMC_STRINGDATA(reply_str);
    error_ = error_.trimmed();
    if( error_.size() > 2 ) {
      if (error_.contains("Error:")) {
        severity = 2;
        error_ = QString( "OMC-ERROR: \n" ) + error_;
      } else if (error_.contains("Warning:")) {
        severity = 1;
        error_ = QString( "OMC-WARNING: \n" ) + error_;
      } else {
        severity = 0;
      }
    } else { // no errors, clear the error.
      error_.clear();
      severity = 0;
    }

    MMC_ELSE()
      result_ = "";
      error_ = "";
      severity = 3;
      fprintf(stderr, "Stack overflow detected and was not caught.\nSend us a bug report at https://trac.openmodelica.org/OpenModelica/newticket\n    Include the following trace:\n");
      printStacktraceMessages();
      fflush(NULL);
    MMC_CATCH_STACK()

    MMC_CATCH_TOP(result_ = "");
  }

  /*!
   * \author Anders FernstrÃ¶m
   * \date 2006-08-17
   *
   *\brief Ststic method for returning the version of omc
   */
  QString OmcInteractiveEnvironment::OMCVersion()
  {
    QString version( "(version)" );

    try
    {
      OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance();
      QString getVersion = "getVersion()";
      env->evalExpression( getVersion );
      version = env->getResult();
      version.remove( "\"" );
      //delete env;
    }
    catch( exception &e )
    {
      e.what();
      QMessageBox::critical( 0, QObject::tr("OMC Error"), QObject::tr("Unable to get OMC version, OMC is not started.") );
    }

    return version;
  }

  QString OmcInteractiveEnvironment::OpenModelicaHome()
  {
    OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance();
    env->evalExpression(QString("getInstallationDirectoryPath()"));
    QString result = env->getResult();
    result = result.remove( "\"" );
    return result;
  }

  QString OmcInteractiveEnvironment::TmpPath()
  {
    OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance();
    env->evalExpression(QString("getTempDirectoryPath()"));
    QString result = env->getResult();
    result = result.replace("\\", "/");
    result.remove( "\"" );
    return result+"/OpenModelica/";
  }
}
