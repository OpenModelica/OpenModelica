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

#include "omc_communicator.h"

// STD includes
#include <cmath>
#include <iostream>
#include <stdlib.h> //This should be cstdlib, if it even should be used!! 
#include <fstream>
#include <sstream>

// Windows includes
#include "windows.h"

// QT includes
#include <QtGui/QApplication>
#include <QtGui/QMessageBox>
#include <QtCore/QFile>


using namespace std;

/**
* \brief 
* Creates and initializes the Omc communicator.
*/
OmcCommunicator::OmcCommunicator()
: QObject(),
omc_(0)
{
}

/**
* \brief 
* Destroys the Omc communicator.
*/
OmcCommunicator::~OmcCommunicator()
{
}

/**
* \brief 
* Returns a reference to the Omc communicator.
*/
OmcCommunicator& OmcCommunicator::getInstance()
{
	static OmcCommunicator instance;
	return instance;
}

/**
* \brief 
* Attempts to establish a connection to Omc.
*
* \return true if a connection was established successfully or if a connection already exists,
* false otherwise.
*/
bool OmcCommunicator::establishConnection()
{
	if (omc_) 
	{
		return true;
	}

	// ORB initialization.
	int argc(0); char* argv = new char[1];
	CORBA::ORB_var orb = CORBA::ORB_init(argc, &argv);

	QFile objectRefFile;

#ifdef WIN32

	char tempDirectory[1024];
	GetTempPath(1024, tempDirectory);
	objectRefFile.setFileName(*(new QString(tempDirectory)) + "openmodelica.objid");

#else	// UNIX environment

	char *user = getenv("USER");
	if (!user) { user = "nobody"; }

	objectRefFile.setName("/tmp/openmodelica." + *(new QString(user)) + ".objid");

#endif

	if (!objectRefFile.exists()) 
		return false;

	objectRefFile.open(QIODevice::ReadOnly);

	char buf[1024];
	objectRefFile.readLine( buf, sizeof(buf) );
	QString uri( (const char*)buf );

	CORBA::Object_var obj = orb->string_to_object( uri.trimmed().toLatin1() );

	omc_ = OmcCommunication::_narrow(obj);


	// Test if we have a connection.
	try {
		omc_->sendExpression("getClassNames()");
	}
	catch (CORBA::Exception&) {
		omc_ = 0;
		return false;
	}

	return true;
}

/**
* \brief 
* Returns true if a connection has been established to Omc, false otherwise.
*/
bool OmcCommunicator::isConnected() const
{
	return omc_ != 0;
}

/**
* \brief
* Closes the connection to Omc. Omc is not terminated by closing the connection.
*/
void OmcCommunicator::closeConnection()
{
	// 2006-02-02 AF, added this code:
	omc_ = 0;
}


/**
* \brief Executes the specified Omc function and returns the return
* value received from Omc.
*
* \throw OmcError if the Omc function call fails.
* \throw OmcConnectionLost if the connection to Omc is lost.
*/
QString OmcCommunicator::callOmc(const QString& fnCall)
{
	if (!omc_) {
		//throw OmcError(fnCall);

		// 2006-02-02 AF, Added throw exception
		string msg = string("OMC-ERROR in function call: ") + fnCall.toStdString();
		throw exception( msg.c_str() );
	}

	QString returnString;
	while (true) {
		try {
			returnString = omc_->sendExpression( fnCall.toLatin1() );
			break;
		}
		catch (CORBA::Exception&) 
		{
			if( fnCall != "quit()" && fnCall != "quit();" )
			{
				throw exception("NOT RESPONDING");
			}
			else
				break;
		}
	}

	// PORT >> returnString = returnString.stripWhiteSpace();
	returnString = returnString.trimmed();
	if (fnCall.startsWith("list(")) {
		//emit omcOutput("...");
		// qDebug("...");
	} else {
		//emit omcOutput(returnString);
		//qDebug(QString(returnString).replace("%"," "));
	}

	if (returnString == "-1") {
		string tmp = "[Internal Error] OmcCommunicator::callOmc():\nOmc call \"" 
			+ fnCall.toStdString() + "\" failed!\n\n";

		qWarning( tmp.c_str() );
		//throw OmcError(fnCall, returnString);
		cerr << "OmcError(" << fnCall.toStdString() << ", " << returnString.toStdString() << ")" << endl;
	}

	return returnString;
}




