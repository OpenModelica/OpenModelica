/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet,
Department of Computer and Information Science, PELAB
See also: www.ida.liu.se/projects/OpenModelica

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

* Neither the name of Linköpings universitet nor the names of its contributors
may be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

For more information about the Qt-library visit TrollTech:s webpage regarding
licence: http://www.trolltech.com/products/qt/licensing.html

------------------------------------------------------------------------------------
*/

//STD Headers
#include <exception>
#include <stdexcept>

//QT Headers
#include <QtCore/QDir>
#include <QtCore/QProcess>
#include <QtCore/QThread>
#include <QtGui/QMessageBox>

//IAEX Headers
#include "omcinteractiveenvironment.h"

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

	OmcInteractiveEnvironment::~OmcInteractiveEnvironment(){}

	QString OmcInteractiveEnvironment::getResult()
	{
		return result_;
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-02-02
	 *
	 *\brief Method for get error message from OMC
	 */
	QString OmcInteractiveEnvironment::getError()
	{
    return error_;
	}

	/*!
	 * \author Ingemar Axelsson and Anders Fernström
	 * \date 2006-02-02 (update)
	 *
	 *\brief Method for evaluationg expressions
	 *
	 * 2006-02-02 AF, Added try-catch statement
	 */
	void OmcInteractiveEnvironment::evalExpression(const QString expr)
	{
		// 2006-02-02 AF, Added try-catch
		try
		{
      error_.clear(); // clear any error!
      // call OMC with expression
			result_ = comm_.callOmc(expr);
      // see if there are any errors
			error_ = comm_.callOmc( "getErrorString()" );
      cerr << "result:" << result_.toStdString() << " error:" << error_.toStdString() << endl;
		  if( error_.size() > 2 )
		  {
			  error_ = QString( "OMC-ERROR: \n" ) + error_;
		  }
		  else // no errors, clear the error.
			  error_.clear();
		}
		catch( exception &e )
		{
			throw e;
		}
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-02-02
	 *
	 *\brief Method for closing connection to OMC
	 */
	void OmcInteractiveEnvironment::closeConnection()
	{
		comm_.closeConnection();
	}

	/*!
	 * \author Anders Fernström
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
	 * \author Anders Fernström
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
	 * \author Anders Fernström
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
			// 2006-02-28 AF, use environment varable to find omc.exe
			// string OMCPath( getenv( "OPENMODELICAHOME" ) );
			QString OMCPath( getenv( "OPENMODELICAHOME" ) );

			if( OMCPath.isEmpty() )
				throw std::runtime_error( "Could not find environment variable OPENMODELICAHOME" );

			// location of omc in openmodelica folder
			QDir dir;
#ifdef WIN32
			if( dir.exists( OMCPath + "\\bin\\omc.exe" ) )
				OMCPath += "\\bin\\";
			else if( dir.exists( OMCPath + "\\omc.exe" ) )
				OMCPath;
			else if( dir.exists( "omc.exe" ))
				OMCPath = "";
			else
			{
				QString msg = "Unable to find OMC, searched in:\n" +
					OMCPath + "\\bin\\\n" +
					OMCPath + "\n" +
					dir.absolutePath();

				throw std::runtime_error( msg.toStdString().c_str() );
			}
#else /* unix */
			if( dir.exists( OMCPath + "/bin/omc" ) )
				OMCPath += "/bin/";
			else if( dir.exists( OMCPath + "/omc" ) )
				OMCPath;
			else if( dir.exists( "omc.exe" ))
				OMCPath = "";
			else
			{
				QString msg = "Unable to find OMC, searched in:\n" +
				  OMCPath + "/bin/\n" +
				  OMCPath + "\n" +
				  dir.absolutePath();

				throw std::runtime_error( msg.toStdString().c_str() );
			}
#endif


			// 2006-03-14 AF, set omc loaction and parameters
			QString omc;
			#ifdef WIN32
				omc = OMCPath + "omc.exe";
			#else
				omc = OMCPath + "omc";
			#endif

			QStringList parameters;
			parameters << "+d=interactiveCorba";

			// 2006-03-14 AF, create qt process
			QProcess *omcProcess = new QProcess();

			// 2006-03-14 AF, start omc
			omcProcess->start( omc, parameters );

			// give time to start up..
			if( omcProcess->waitForStarted(20000) )
				flag = true;
			else
				flag = false;


/*
			STARTUPINFO startinfo;
			PROCESS_INFORMATION procinfo;
			memset(&startinfo, 0, sizeof(startinfo));
			memset(&procinfo, 0, sizeof(procinfo));
			startinfo.cb = sizeof(STARTUPINFO);
			startinfo.wShowWindow = SW_MINIMIZE;
			startinfo.dwFlags = STARTF_USESHOWWINDOW;

			//string parameter = "\"omc.exe\" +d=interactiveCorba";
			string parameter = "\"" + drmodelica + "omc.exe\" +d=interactiveCorba";
			char *pParameter = new char[parameter.size() + 1];
			const char *cpParameter = parameter.c_str();
			strcpy(pParameter, cpParameter);

			flag = CreateProcess(NULL,pParameter,NULL,NULL,FALSE,CREATE_NEW_CONSOLE,NULL,NULL,&startinfo,&procinfo);

			Sleep(1000);

			if( !flag )
				throw std::runtime_error("Was unable to start OMC");

				*/
		}
		catch( exception &e )
		{
			QString msg = e.what();
			QMessageBox::warning( 0, "Error", msg, "OK" );
		}

		return flag;
	}

	/*!
	 * \author Anders Fernström
	 * \date 2006-08-17
	 *
	 *\brief Ststic method for returning the version of omc
	 */
	QString OmcInteractiveEnvironment::OMCVersion()
	{
		QString version( "(version)" );

		try
		{
			OmcInteractiveEnvironment *env = new OmcInteractiveEnvironment();
			QString getVersion = "getVersion()";
			env->evalExpression( getVersion );
			version = env->getResult();
			version.remove( "\"" );
			delete env;
		}
		catch( exception &e )
		{
			QMessageBox::critical( 0, "OMC Error", "Unable to get OMC version, OMC is not started." );
		}

		return version;
	}
}
