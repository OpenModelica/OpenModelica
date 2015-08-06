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

#include <exception>
#include <stdexcept>

// QT includes
#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#else
#include <QtCore/QDir>
#include <QtCore/QProcess>
#include <QtGui/QMessageBox>
#endif

#include "omcinteractiveenvironment.h"
#ifndef WIN32
#include "omc_config.h"
#endif

using namespace std;

namespace IAEX
{
  /*! \class OmcInteractiveEnvironment
  *
  * \brief Implements evaluation for modelica code.
  */
  OmcInteractiveEnvironment::OmcInteractiveEnvironment()
    : comm_(OmcCommunicator::getInstance()),result_("")
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

  OmcInteractiveEnvironment::~OmcInteractiveEnvironment(){}

  QString OmcInteractiveEnvironment::getResult()
  {
    return result_;
  }

  void OmcInteractiveEnvironment::evalExpression(QString expr)
  {
    // 2006-02-02 AF, Added try-catch
    try
    {
      result_ = comm_.callOmc(expr);
    }
    catch( exception &e )
    {
      throw e;
    }
  }

  void OmcInteractiveEnvironment::closeConnection()
  {
    comm_.closeConnection();
  }

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
      omc = (omhome ? QString(omhome)+"/bin/omc" : QString(CONFIG_DEFAULT_OPENMODELICAHOME "/bin/omc"));
      QFileInfo checkFile(omc);
      if (!checkFile.exists() || !checkFile.isFile()) {
        omc = "omc";
      }
#endif

      QStringList parameters;
      parameters << "+d=interactiveCorba" << QString("+corbaObjectReferenceFilePath=").append(QDir::tempPath());

      // 2006-03-14 AF, create qt process
      QProcess *omcProcess = new QProcess();

      // 2006-03-14 AF, start omc
      omcProcess->start( omc, parameters );

      if( omcProcess->waitForStarted(7000) )
        flag = true;
      else
        flag = false;

    }
    catch( exception &e )
    {
      QString msg = e.what();
      QMessageBox::warning( 0, "Error", msg, "OK" );
    }

    return flag;
  }
}
