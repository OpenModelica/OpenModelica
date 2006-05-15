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

#include <exception>
#include <stdexcept>

#include <QtCore/QDir>
#include <QtCore/QProcess>
#include <QtGui/QMessageBox>

#include "omcinteractiveenvironment.h"

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
   
   void OmcInteractiveEnvironment::evalExpression(QString& expr)
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
			// 2006-02-28 AF, use environment varable to find omc.exe
			string OMCPath( getenv( "OPENMODELICAHOME" ) );
			if( OMCPath.empty() )
				throw std::runtime_error( "Could not find environment variable OPENMODELICAHOME" );

			// location of omc in openmodelica folder
			QDir dir;
#ifdef WIN32
			if( dir.exists( QString(OMCPath.c_str()) + "\\bin\\omc.exe" ) )
				OMCPath += "\\bin\\";
			else if( dir.exists( QString(OMCPath.c_str()) + "\\omc.exe" ) )
				OMCPath;
			else if( dir.exists( "omc.exe" ))
				OMCPath = "";
			else
			{
				string msg = "Unable to find OMC, searched in:\n" +
					OMCPath + "\\bin\\\n" +
					OMCPath + "\n" +
					dir.absolutePath().toStdString();

				throw std::runtime_error( msg.c_str() );
			}
#else /* unix */
			if( dir.exists( QString(OMCPath.c_str()) + "/bin/omc" ) )
				OMCPath += "/bin/";
			else if( dir.exists( QString(OMCPath.c_str()) + "/omc" ) )
				OMCPath;
			else if( dir.exists( "omc.exe" ))
				OMCPath = "";
			else
			{
				string msg = "Unable to find OMC, searched in:\n" +
					OMCPath + "/bin/\n" +
					OMCPath + "\n" +
					dir.absolutePath().toStdString();

				throw std::runtime_error( msg.c_str() );
			}
#endif 

			// 2006-03-14 AF, set omc loaction and parameters
			QString omc;
#ifdef WIN32
				omc = QString( OMCPath.c_str() ) + "omc.exe";
#else /* unix */
				omc = QString( OMCPath.c_str() ) + "omc";
#endif
			
			QStringList parameters;
			parameters << "+d=interactiveCorba";

			// 2006-03-14 AF, create qt process
			QProcess *omcProcess = new QProcess();
		
			// 2006-03-14 AF, start omc
			omcProcess->start( omc, parameters );

			if( omcProcess->waitForStarted(2000) )
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
