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
#include <QtCore/QDebug>
#include <QtCore/QDir>
#include <QtCore/QProcess>
#include <QtCore/QThread>
#include <QtCore/QMutex>
#include <QtGui/QMessageBox>

//IAEX Headers
#include "omcinteractiveenvironment.h"
#include "../../Compiler/runtime/config.h"

using namespace std;

namespace IAEX
{
  class SleeperThread : public QThread
  {
  public:
    static void msleep(unsigned long msecs)
    {
      QThread::msleep(msecs);
    }
  };


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
  OmcInteractiveEnvironment::OmcInteractiveEnvironment():comm_(OmcCommunicator::getInstance()),result_(""),error_("")
  {
    //Communicate with Omc.
    if(!comm_.isConnected())
    {
      if(!comm_.establishConnection())
      {
  throw runtime_error("OmcInteractiveEnvironment(): No connection to Omc established");
      }
    }
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

  // QMutex omcMutex;

  /*!
   * \author Ingemar Axelsson and Anders FernstrÃ¶m
   * \date 2006-02-02 (update)
   *
   *\brief Method for evaluationg expressions
   *
   * 2006-02-02 AF, Added try-catch statement
   */
  void OmcInteractiveEnvironment::evalExpression(const QString expr)
  {
    //omcMutex.lock();
    // 2006-02-02 AF, Added try-catch
    try
    {
      error_.clear(); // clear any error!
      // call OMC with expression
      result_ = comm_.callOmc(expr);
      // see if there are any errors if the expr is not "quit()"
      if( !expr.endsWith("quit()", Qt::CaseSensitive ) )
      {
  error_ = comm_.callOmc( "getErrorString()" );
  // cerr << "result:" << result_.toStdString() << " error:" << error_.toStdString() << endl;
  if( error_.size() > 2 )
  {
    error_ = QString( "OMC-ERROR: \n" ) + error_;
  }
  else // no errors, clear the error.
    error_.clear();
      }
    }
    catch( exception &e )
    {
      //omcMutex.unlock();
      throw e;
    }
    //omcMutex.unlock();
  }

  /*!
   * \author Anders FernstrÃ¶m
   * \date 2006-02-02
   *
   *\brief Method for closing connection to OMC
   */
  void OmcInteractiveEnvironment::closeConnection()
  {
    comm_.closeConnection();
  }

  /*!
   * \author Anders FernstrÃ¶m
   * \date 2006-02-02
   *
   *\brief Method for closing reconnection to OMC
   */
  void OmcInteractiveEnvironment::reconnect()
  {
    //Communicate with Omc.
    if(!comm_.isConnected())
    {
      if(!comm_.establishConnection())
      {
  throw runtime_error("OmcInteractiveEnvironment(): No connection to Omc established");
      }
    }
  }

  /*!
   * \author Anders FernstrÃ¶m
   * \date 2006-02-09
   *
   *\brief Method for starting OMC
   */
  bool OmcInteractiveEnvironment::startDelegate()
  {
    // if not connected and can not establish connection,
    // try to start OMC
    if( !comm_.isConnected() && !comm_.establishConnection() )
    {
      return  OmcInteractiveEnvironment::startOMC();
    }
    else
      return false;
  }

  /*!
   * \author Anders FernstrÃ¶m
   * \date 2006-02-09
   * \date 2006-03-14 (update)
   *
   *\brief Ststic method for starting OMC
   *
   * 2006-02-28 AF, added code so the environment variable OPENMODELICAHOME
   * is used to locate omc.exe.
   * 2006-03-14 AF, changed so omnotebook uses qt to start omc
   */
  bool OmcInteractiveEnvironment::startOMC()
  {
    bool flag = false;

    try
    {
      const char *omhome = getenv("OPENMODELICAHOME");

      QString omc;
#ifdef WIN32
      omc = QString( omhome ) + "/bin/omc.exe";
#else /* unix */
      omc = (omhome ? QString(omhome)+"/bin/omc" : QString(CONFIG_DEFAULT_OPENMODELICAHOME)+"/bin/omc");
#endif

      QStringList parameters;
      parameters << "+d=interactiveCorba";

      // 2006-03-14 AF, create qt process
      QProcess *omcProcess = new QProcess();

      fprintf(stdout, "Starting omc: %s\n", omc.toStdString().c_str());
      // 2006-03-14 AF, start omc
      omcProcess->start( omc, parameters );

      // give time to start up..
      if( omcProcess->waitForStarted(7000) )
  flag = true;
      else
  flag = false;
//#ifdef _MSC_VER
//      _sleep(1);
//#else
//      sleep(1);
//#endif

    }
    catch( exception &e )
    {
      QString msg = e.what();
      QMessageBox::warning( 0, "Error", msg, "OK" );
    }

    return flag;
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
      QMessageBox::critical( 0, "OMC Error", "Unable to get OMC version, OMC is not started." );
    }

    return version;
  }

  bool OmcInteractiveEnvironment::setPlotSilent(QString silent)
  {
    OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance();
    env->evalExpression(QString("setPlotSilent("+silent+")"));
    QString result = env->getResult();
    if (result.toLower().compare("true") == 0)
      return true;
    else
      return false;
  }

  QString OmcInteractiveEnvironment::OpenModelicaHome()
  {
    OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance();
    env->evalExpression(QString("getInstallationDirectoryPath()"));
    QString result = env->getResult();
    result.remove( "\"" );
    return result;
  }

  QString OmcInteractiveEnvironment::TmpPath()
  {
    OmcInteractiveEnvironment *env = OmcInteractiveEnvironment::getInstance();
    env->evalExpression(QString("getTempDirectoryPath()"));
    QString result = env->getResult();
    result.remove( "\"" );
    return result+"/OpenModelica/";
  }
}
