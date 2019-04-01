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
#include <algorithm>

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
modelica_metatype omc_Main_init(void *threadData, modelica_metatype args);
modelica_metatype omc_Main_readSettings(void *threadData, modelica_metatype args);
#ifdef WIN32
void omc_Main_setWindowsPaths(threadData_t *threadData, void* _inOMHome);
#endif
}

static std::string trim(std::string str);
static bool contains(std::string s1, std::string s2);

  OmcInteractiveEnvironment* OmcInteractiveEnvironment::selfInstance = NULL;
  OmcInteractiveEnvironment* OmcInteractiveEnvironment::getInstance()
  {
    if (selfInstance == NULL)
    {
      selfInstance = new OmcInteractiveEnvironment();
    }
    return selfInstance;
  }

  /*! \class OmcInteractiveEnvironment
  *
  * \brief Implements evaluation for modelica code.
  */
  OmcInteractiveEnvironment::OmcInteractiveEnvironment():result_(""),error_("")
  {
    modelica_metatype args = mmc_mk_nil();
    // set the language by reading the OMEdit settings file.
    //QSettings settings(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omedit");
    //QLocale settingsLocale = QLocale(settings.value("language").toString());
    //settingsLocale = settingsLocale.name() == "C" ? settings.value("language").toLocale() : settingsLocale;
    //string locale = "+locale=" + settingsLocale.name();
    //args = mmc_mk_cons(mmc_mk_scon(locale.toStdString().c_str()), args);
    args = mmc_mk_cons(mmc_mk_scon("+locale=C"), args);

    // initialize threadData
    threadData_t *threadData = (threadData_t *) GC_malloc_uncollectable(sizeof(threadData_t));
    MMC_TRY_TOP_INTERNAL()
    omc_Main_init(threadData, args);
    MMC_CATCH_TOP()
    threadData_ = threadData;
    threadData_->plotClassPointer = 0;
    threadData_->plotCB = 0;
    // set the -d=initialization flag default.
    evalExpression("setCommandLineOptions(\"-d=initialization\")");
#ifdef WIN32
    evalExpression("getInstallationDirectoryPath()");
    std::string result = getResult();
    //result = result.remove( "\"" );
    result.erase(std::remove(result.begin(), result.end(), '\"'), result.end());
    MMC_TRY_TOP_INTERNAL()
    omc_Main_setWindowsPaths(threadData, mmc_mk_scon(result.c_str()));
    MMC_CATCH_TOP()
#endif
  }

  OmcInteractiveEnvironment::~OmcInteractiveEnvironment()
  {
    GC_free(threadData_);
  }

  std::string OmcInteractiveEnvironment::getResult() {
    return result_;
  }

  /*!
   * \author Anders FernstrÃ¶m
   * \date 2006-02-02
   *
   *\brief Method for get error message from OMC
   */
  std::string OmcInteractiveEnvironment::getError() {
    return error_;
  }

  /*!
   * \author Hennning Kiel
   * \date 2017-05-24
   *
   *\brief Method to get error message severity from OMC
   */
  int OmcInteractiveEnvironment::getErrorLevel() {
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
  void OmcInteractiveEnvironment::evalExpression(const std::string expr) {
    error_.clear(); // clear any error!
    // call OMC with expression
    void *reply_str = NULL;
    threadData_t *threadData = threadData_;
    MMC_TRY_TOP_INTERNAL()

    MMC_TRY_STACK()

    if (!omc_Main_handleCommand(threadData, mmc_mk_scon(expr.c_str()), &reply_str)) {
      return;
    }
    result_ = MMC_STRINGDATA(reply_str);
    result_ = trim(result_);
    reply_str = NULL;
    // see if there are any errors if the expr is not "quit()"
    if (!omc_Main_handleCommand(threadData, mmc_mk_scon("getErrorString()"), &reply_str)) {
      return;
    }
    error_ = MMC_STRINGDATA(reply_str);
    error_ = trim(error_);
    if( error_.size() > 2 ) {
      if (contains(error_,"Error:")) {
        severity = 2;
        error_ = "OMC-ERROR: \n" + error_;
      } else if (contains(error_,"Warning:")) {
        severity = 1;
        error_ = "OMC-WARNING: \n" + error_;
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
  std::string OmcInteractiveEnvironment::OMCVersion()
  {
    std::string version( "(version)" );

    try
    {
      OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance();
      std::string getVersion = "getVersion()";
      env->evalExpression( getVersion );
      version = env->getResult();
      //version.remove( "\"" );
      version.erase(std::remove(version.begin(), version.end(), '\"'), version.end());
      //delete env;
    }
    catch( std::exception &e )
    {
      e.what();
      std::cerr << "Unable to get OMC version, OMC is not started." << std::endl;
    }

    return version;
  }

  std::string OmcInteractiveEnvironment::OpenModelicaHome()
  {
    OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance();
    env->evalExpression("getInstallationDirectoryPath()");
    std::string result = env->getResult();
    //result = result.remove( "\"" );
    result.erase(std::remove(result.begin(), result.end(), '\"'), result.end());
    return result;
  }

  std::string OmcInteractiveEnvironment::TmpPath()
  {
    OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance();
    env->evalExpression("getTempDirectoryPath()");
    std::string result = env->getResult();
    //result = result.replace("\\", "/");
    result.replace( result.begin(), result.end(), '\\', '/');
    //result.remove( "\"" );
    result.erase(std::remove(result.begin(), result.end(), '\"'), result.end());
    return result+"/OpenModelica/";
  }


std::string trimRight(std::string str) {
  // trim trailing spaces
  size_t endpos = str.find_last_not_of(" \t");
  size_t startpos = str.find_first_not_of(" \t");
  if( std::string::npos != endpos )
  {
      str = str.substr( 0, endpos+1 );
      str = str.substr( startpos );
  }
  else {
      str.erase(std::remove(str.begin(), str.end(), ' '), str.end());
  }
  return str;
}
std::string trimLeft(std::string str) {
  // trim leading spaces
  size_t startpos = str.find_first_not_of(" \t");
  if( std::string::npos != startpos )
  {
      str = str.substr( startpos );
  }
  return str;
}
std::string trim(std::string str) {
  return trimLeft(trimRight(str));
}
bool contains(std::string s1, std::string s2) {
  return (s1.find(s2) != std::string::npos);
}
