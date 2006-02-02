/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet,
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

#include "omc_communicator.hpp"

// STD includes
#include <cmath>
#include <iostream>
#include <stdlib.h> //This should be cstdlib, if it even should be used!! 
#include <fstream>
#include <sstream>

// MME includes
//#include "annotation.hpp"
//#include "annotation_compiler.hpp"
//#include "application.hpp"
//#include "modelica_class.hpp"
//#include "modification.hpp"

// Windows includes
#include "windows.h"

// QT includes
#include <QtGui/QApplication>
#include <QtGui/QMessageBox>
#include <QtCore/QFile>
//#include <QtCore/QString> //AF, removed
//#include <QtCore/QStringList> //AF, removed



// MICO includes
//#include <CORBA.h> //AF, removed

using namespace std;

/**
 * \brief
 * Creates and initializes the Omc communicator.
 */
OmcCommunicator::OmcCommunicator()
  : QObject(),
    omc_(0) //,
    //compiler_(new AnnotationCompiler())
{
}

/**
 * \brief
 * Destroys the Omc communicator.
 */
OmcCommunicator::~OmcCommunicator()
{
   //delete compiler_;
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

#ifdef WIN32 // Win32

	// Win32 + Cygwin?
	//Cygwin support is removed due to missing code.
	//Ingemar Axelsson 2005-09-14.

	//   if ((dynamic_cast<Application*>(qApp))->inCygwinMode()) {
	//      char *user(getenv("USERNAME"));
	//      if (!user) { user = "nobody"; }
	//      
	//      char *cygwinPath(getenv("CYGWINHOME"));
	//      if (!cygwinPath) { cygwinPath = "c:/cygwin"; }

	// There seems to be a bug in the QString(const char*) constructor which makes QString free the
	// memory pointed to by its argument when the QString object gets destroyed. Therefore it is
	// neccessary to create the QString objects on the heap and just leave them there.
	//      objectRefFile.setName(*(new QString(cygwinPath)) + "/tmp/openmodelica." + *(new QString(user)) + ".objid");
	//   }
	// Pure Win32
	//   else
	//   {
	char tempDirectory[1024];
	GetTempPath(1024, tempDirectory);
	//GetTempPath(1024, (LPWSTR)tempDirectory);
	
	
	// PORT >> objectRefFile.setName(*(new QString(tempDirectory)) + "openmodelica.objid");
	objectRefFile.setFileName(*(new QString(tempDirectory)) + "openmodelica.objid");
	
	//   }

#else	// UNIX environment

	char *user = getenv("USER");
	if (!user) { user = "nobody"; }

	objectRefFile.setName("/tmp/openmodelica." + *(new QString(user)) + ".objid");

#endif

	if (!objectRefFile.exists()) 
		return false;

	objectRefFile.open(QIODevice::ReadOnly);

	// 2005-10-10 AF, Porting, changes
	//objectRefFile.readLine( uri, 1024); //org
	//qint64 length = objectRefFile.readLine( ((char*)uri.ascii()), 1024);

	char buf[1024];
	objectRefFile.readLine( buf, sizeof(buf) );
	QString uri( (const char*)buf );

	// 2005-10-10 AF, Porting, changes
	//CORBA::Object_var obj = orb->string_to_object(uri.stripWhiteSpace().latin1()); //org
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
	if (!omc_) 
	{
		//throw OmcError(fnCall);
		cout << "OmcError(" << fnCall.toStdString() << ")" << endl;
	}

	//emit omcInput(fnCall + "\n");
	//qDebug(QString(fnCall).replace("%"," "));

	QString returnString;
	while (true) 
	{
		try 
		{
			returnString = omc_->sendExpression( fnCall.toLatin1() );
			break;
		}
		catch (CORBA::Exception&) 
		{
			// 2005-11-24 AF, added otherwise it crashes when command quit() is called.
			// ignore if quit() is the first in the function call
			if( 0 != fnCall.indexOf( "quit()", 0, Qt::CaseInsensitive ))
			{
				int result(QMessageBox::critical(0, tr("Communication Error"),
					tr("<NOBR><B>The Modelica kernel is not responding.</B>"), tr("Try Again"), tr("Abort")));
				qApp->processEvents();
				if (result == 1) {
					QMessageBox::critical(0, tr("Communication Error"),
						tr("<NOBR><B>Connection to the Modelica kernel lost.</B><BR><BR>The editor has to be restarted.", "Quit"));
					qApp->processEvents();
					//throw OmcConnectionLost();
					cerr << "OmcConnectionLost()" << endl;
				}
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
		cout << "OmcError(" << fnCall.toStdString() << ", " << returnString.toStdString() << ")" << endl;
	}

	return returnString;
}

/** NOT USED ********************************************************/

/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::loadFile(const QString& file)
// {
//   QString fnCall("loadFile(\"" + file + "\")");
//   QString returnString(callModeq(fnCall));

//   if (returnString != "true") {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Loads the specified Modelica class by looking up the correct file to load in the
 * environment variable MODELICAPATH.
 *
 * \return true if a file with the specified Modelica class was found, false otherwise.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// bool ModeqCommunicator::loadClass(const QString& ref)
// {
// 	QString fnCall("loadModel(" + ref + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString == "true") {
//     return true;
//   } else if (returnString == "false") {
//     return false;
//   } else {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::saveClass(const QString& file, const QString& ref)
// {
//   QString fnCall("saveModel(\"" + file + "\"," + ref + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString != "true") {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::createConnector(const QString& ref,
// 																				const QStringList& baseClassRefs,
// 																				const QString& comment, 
// 																				bool encapsulated,
// 																				bool partial)
// {
// 	QString name(ModelicaClassManager::getName(ref));
// 	QString parentClassRef(ModelicaClassManager::getPath(ref));

// 	QString fnCall(!parentClassRef.isEmpty() ? "within " + parentClassRef + "; " : "");
// 	fnCall +=
// 		QString((encapsulated ? "encapsulated " : "")) +
// 		QString((partial ? "partial " : "")) + "connector " + name + " \"" + comment + "\"";
// 	for (QStringList::const_iterator it = baseClassRefs.begin(); it != baseClassRefs.end(); ++it) {
// 		fnCall += " extends " + *it + ";";
// 	}
// 	fnCall += " end " + name + ";";
// 	QString returnString(callModeq(fnCall));

// 	if (returnString.lower() != "ok") {
// 		throw ModeqError(fnCall, returnString);
// 	}
// }

/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::createModel(const QString& ref,
// 																		const QStringList& baseClassRefs,
// 																		const QString& comment, 
// 																		bool encapsulated,
// 																		bool partial)
// {
// 	QString name(ModelicaClassManager::getName(ref));
// 	QString parentClassRef(ModelicaClassManager::getPath(ref));

//   QString fnCall(!parentClassRef.isEmpty() ? "within " + parentClassRef + "; " : "");
//   fnCall +=
//     QString((encapsulated ? "encapsulated " : "")) +
//     QString((partial ? "partial " : "")) + "model " + name + " \"" + comment + "\"";
//   for (QStringList::const_iterator it = baseClassRefs.begin(); it != baseClassRefs.end(); ++it) {
//     fnCall += " extends " + *it + ";";
//   }
//   fnCall += " end " + name + ";";
//   QString returnString(callModeq(fnCall));

//   if (returnString.lower() != "ok") {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::createBlock(const QString& ref,
// 																		const QStringList& baseClassRefs,
// 																		const QString& comment, 
// 																		bool encapsulated,
// 																		bool partial)
// {
// 	QString name(ModelicaClassManager::getName(ref));
// 	QString parentClassRef(ModelicaClassManager::getPath(ref));

//   QString fnCall(!parentClassRef.isEmpty() ? "within " + parentClassRef + "; " : "");
//   fnCall +=
//     QString((encapsulated ? "encapsulated " : "")) +
//     QString((partial ? "partial " : "")) + "block " + name + " \"" + comment + "\"";
//   for (QStringList::const_iterator it = baseClassRefs.begin(); it != baseClassRefs.end(); ++it) {
//     fnCall += " extends " + *it + ";";
//   }
//   fnCall += " end " + name + ";";
//   QString returnString(callModeq(fnCall));

//   if (returnString.lower() != "ok") {
//     throw ModeqError(fnCall, returnString);
//   }
// }


/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::createRecord(const QString& ref,
// 																		const QStringList& baseClassRefs,
// 																		const QString& comment, 
// 																		bool encapsulated,
// 																		bool partial)
// {
// 	QString name(ModelicaClassManager::getName(ref));
// 	QString parentClassRef(ModelicaClassManager::getPath(ref));

//   QString fnCall(!parentClassRef.isEmpty() ? "within " + parentClassRef + "; " : "");
//   fnCall +=
//     QString((encapsulated ? "encapsulated " : "")) +
//     QString((partial ? "partial " : "")) + "record " + name + " \"" + comment + "\"";
//   for (QStringList::const_iterator it = baseClassRefs.begin(); it != baseClassRefs.end(); ++it) {
//     fnCall += " extends " + *it + ";";
//   }
//   fnCall += " end " + name + ";";
//   QString returnString(callModeq(fnCall));

//   if (returnString.lower() != "ok") {
//     throw ModeqError(fnCall, returnString);
//   }
// }


/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::createFunction(const QString& ref,
// 																		const QStringList& baseClassRefs,
// 																		const QString& comment, 
// 																		bool encapsulated,
// 																		bool partial)
// {
// 	QString name(ModelicaClassManager::getName(ref));
// 	QString parentClassRef(ModelicaClassManager::getPath(ref));

//   QString fnCall(!parentClassRef.isEmpty() ? "within " + parentClassRef + "; " : "");
//   fnCall +=
//     QString((encapsulated ? "encapsulated " : "")) +
//     QString((partial ? "partial " : "")) + "function " + name + " \"" + comment + "\"";
//   for (QStringList::const_iterator it = baseClassRefs.begin(); it != baseClassRefs.end(); ++it) {
//     fnCall += " extends " + *it + ";";
//   }
//   fnCall += " end " + name + ";";
//   QString returnString(callModeq(fnCall));

//   if (returnString.lower() != "ok") {
//     throw ModeqError(fnCall, returnString);
//   }
// }


/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::createPackage(const QString& ref,
// 																			const QStringList& baseClassRefs,
// 																			const QString& comment, 
// 																			bool encapsulated,
// 																			bool partial)
// {
// 	QString name(ModelicaClassManager::getName(ref));
// 	QString parentClassRef(ModelicaClassManager::getPath(ref));

//   QString fnCall(!parentClassRef.isEmpty() ? "within " + parentClassRef + "; " : "");
//   fnCall +=
//     QString((encapsulated ? "encapsulated " : "")) +
//     QString((partial ? "partial " : "")) + "package " + name + " \"" + comment + "\"";
//   for (QStringList::const_iterator it = baseClassRefs.begin(); it != baseClassRefs.end(); ++it) {
//     fnCall += " extends " + *it + ";";
//   }
//   fnCall += " end " + name + ";";
//   QString returnString(callModeq(fnCall));

//   if (returnString.lower() != "ok") {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Deletes the specified Modelica class in Modeq.
 */
// bool ModeqCommunicator::deleteClass(const QString& ref)
// {
//   QString fnCall("deleteClass(" + ref + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString == "true") {
//     return true;
//   } else if (returnString == "false") {
//     return false;
//   } else {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Returns true if the specified Modelica class exists, false otherwise.
 *
 * The class reference must not be empty.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// bool ModeqCommunicator::existsClass(const QString& ref)
// {
//   QString fnCall("existClass(" + ref + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString == "true") {
//     return true;
//   } else if (returnString == "false") {
//     return false;
//   } else {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Returns true if \a ref is a reference to a restricted Modelica class of type Block, false
 * otherwise.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// bool ModeqCommunicator::isBlock(const QString& ref)
// {
//   QString fnCall("isBlock(" + ref + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString == "false") {
//     return false;
//   } else if (returnString == "true") {
//     return true;
//   } else {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Returns true if \a ref is a reference to an unrestricted Modelica class, false otherwise.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// bool ModeqCommunicator::isClass(const QString& ref)
// {
//   QString fnCall("isClass(" + ref + ")");
//   QString returnString(callModeq(fnCall));
  
//   if (returnString == "false") {
//     return false;
//   } else if (returnString == "true") {
//     return true;
//   } else {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Returns true if \a ref is a reference to a restricted Modelica class of type Connector, false
 * otherwise.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// bool ModeqCommunicator::isConnector(const QString& ref)
// {
//   QString fnCall("isConnector(" + ref + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString == "false") {
//     return false;
//   } else if (returnString == "true") {
//     return true;
//   } else {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Returns true if \a ref is a reference to a restricted Modelica class of type Function, false
 * otherwise.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// bool ModeqCommunicator::isFunction(const QString& ref)
// {
//   QString fnCall("isFunction(" + ref + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString == "false") {
//     return false;
//   } else if (returnString == "true") {
//     return true;
//   } else {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Returns true if \a ref is a reference to a restricted Modelica class of type Model, false
 * otherwise.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// bool ModeqCommunicator::isModel(const QString& ref)
// {
//   QString fnCall("isModel(" + ref + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString == "false") {
//     return false;
//   } else if (returnString == "true") {
//     return true;
//   } else {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Returns true if \a ref is a reference to a restricted Modelica class of type Package, false
 * otherwise.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// bool ModeqCommunicator::isPackage(const QString& ref)
// {
//   QString fnCall("isPackage(" + ref + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString == "false") {
//     return false;
//   } else if (returnString == "true") {
//     return true;
//   } else {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Returns true if \a ref is a reference to a restricted Modelica class of type Record, false
 * otherwise.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// bool ModeqCommunicator::isRecord(const QString& ref)
// {
//   QString fnCall("isRecord(" + ref + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString == "false") {
//     return false;
//   } else if (returnString == "true") {
//     return true;
//   } else {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Returns true if \a ref is a reference to a restricted Modelica class of type Type, false
 * otherwise.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// bool ModeqCommunicator::isType(const QString& ref)
// {
//   QString fnCall("isType(" + ref + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString == "false") {
//     return false;
//   } else if (returnString == "true") {
//     return true;
//   } else {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Returns true if \a ref is a Modelica primitive type, false otherwise.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// bool ModeqCommunicator::isPrimitive(const QString& ref)
// {
// 	// Real and Integer are known primitives. No need to ask Modeq.
// 	if (ref == "Real" || ref == "Integer") {
// 		return true;
// 	}
  
// 	QString fnCall("isPrimitive(" + ref + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString == "false") {
//     return false;
//   } else if (returnString == "true") {
//     return true;
//   } else {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Returns a comma separated list (surrounded with braces) with the names of all class definitions
 * in the specified Modelica class.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// QString ModeqCommunicator::getClassNames(const QString& ref)
// {
//   QString fnCall("getClassNames(" + ref + ")");
//   QString list(callModeq(fnCall));

// 	// Remove the surrounding braces before returning the list.
// 	return list.mid(1, list.length() - 2);
// }

/**
 * \brief
 * Returns the icon layer annotation stored in Modeq of the specified Modelica class.
 *
 * A null pointer is returned if no annotation exists. The annotation returned is the one available
 * in Modeq and is not neccessarly up to date. Use the functions of the ModelicaClass object to
 * obtain the latest version of the annotation.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 * \throw SyntaxError if the compilation of the icon layer annotation fails.
 *
 * \see ModelicaClass::getIconLayerAnnotation()
 * \see ModelicaClass::getLayerAnnotation()
 */
// IconLayerAnnotation* ModeqCommunicator::getIconLayerAnnotation(const QString& ref)
// {
//   QString fnCall("getIconAnnotation(" + ref + ")");
//   QString annotationString(callModeq(fnCall));

//   if (annotationString.isEmpty()) {
//     return 0;
//   } else {
//     return compiler_->compileIconLayerAnnotation(annotationString.latin1(), ref.latin1());
//   }
// }

/**
 * \brief
 * Returns the diagram layer annotation stored in Modeq of the specified Modelica class.
 *
 * A null pointer is returned if no annotation exists. The annotation returned is the one
 * available in Modeq and is not neccessarly up to date. Use the functions of the ModelicaClass
 * object to obtain the latest version of the annotation.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 * \throw SyntaxError if the compilation of the diagram layer annotation fails.
 *
 * \see ModelicaClass::getDiagramLayerAnnotation()
 * \see ModelicaClass::getLayerAnnotation()
 */
// DiagramLayerAnnotation* ModeqCommunicator::getDiagramLayerAnnotation(const QString& ref)
// {
//   QString fnCall("getDiagramAnnotation(" + ref + ")");
//   QString annotationString(callModeq(fnCall));

//   if (annotationString.isEmpty()) {
//     return 0;
//   } else {
//     return compiler_->compileDiagramLayerAnnotation(annotationString.latin1(), ref.latin1());
//   }
// }

/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::setClassLayerAnnotation(const QString& ref, const QString& annotation)
// {
//   QString fnCall("addClassAnnotation(" + ref + "," + annotation + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString.lower() != "true" && returnString.lower() != "ok") {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Returns the number of classes inherited by the the specified Modelica class.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// int ModeqCommunicator::getInheritanceCount(const QString& ref)
// {
//   QString fnCall("getInheritanceCount(" + ref + ")");
//   QString returnString(callModeq(fnCall));

//   bool conversionResult;
//   int count(returnString.toInt(&conversionResult));
//   if (!conversionResult) {
//     throw ModeqError(fnCall, returnString);
//   }

//   return count;
// }

/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// QString ModeqCommunicator::getNthInheritedClass(const QString& ref, int index)
// {
//   QString fnCall("getNthInheritedClass(" + ref + "," + QString::number(index) + ")");
//   return callModeq(fnCall);
// }

/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::addComponent(const QString& name,
// 																		 const QString& type,
// 																		 const QString& ref,
// 																		 const QString& annotation)
// {
//   QString fnCall;
//   if (annotation.isEmpty()) {
//     fnCall = "addComponent(" + name + "," + type + "," + ref + ")";
//   } else {
//     fnCall = "addComponent(" + name + "," + type + "," + ref + "," + annotation + ")";
//   }
//   QString returnString(callModeq(fnCall));

//   if (returnString != "true") {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::updateComponent(const QString& name,
// 																				const QString& type,
// 																				const QString& ref,
// 																				const QString& comment,
// 																				const QString& annotation)
// {
// 	QString temporaryComment(comment);
// 	temporaryComment.replace("\\", "\\\\").replace("\"", "\\\"");

// 	QString fnCall;
//   if (annotation.isEmpty()) {
//     fnCall = "updateComponent(" + name + "," + type + "," + ref +
// 			", comment=\"" + temporaryComment + "\")";
//   } else {
//     fnCall = "updateComponent(" + name + "," + type + "," + ref +
// 			", comment=\"" + temporaryComment + "\",annotate=" + annotation + ")";
//   }
//   QString returnString(callModeq(fnCall));

//   if (returnString != "true") {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * Deletes the specified component from the specified Modelica class.
 *
 * \param name the name of the component to delete.
 * \param ref the reference to the Modelica class in which the component exists.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::deleteComponent(const QString& name, const QString& ref)
// {
//   QString fnCall("deleteComponent(" + name + "," + ref + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString != "true") {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * Returns true if the specified component is protected, false otherwise.
 *
 * \param name the name of the component.
 * \param ref the reference to the Modelica class in which the component exists.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// bool ModeqCommunicator::isProtected(const QString& name, const QString& ref)
// {
//   QString fnCall("isProtected(" + name + "," + ref + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString == "false") {
//     return false;
//   } else if (returnString == "true") {
//     return true;
//   } else {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Returns the number of components of the specified Modelica class.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// int ModeqCommunicator::getComponentCount(const QString& ref)
// {
//   QString fnCall("getComponentCount(" + ref + ")");
//   QString returnString(callModeq(fnCall));

//   bool conversionResult;
//   int count(returnString.toInt(&conversionResult));
//   if (!conversionResult) {
//     throw ModeqError(fnCall, returnString);
//   }

//   return count;
// }
 
/**
 * \brief
 * Returns all component declarations in the Modelica class specifed by \a ref.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// std::vector<ComponentDeclaration> ModeqCommunicator::getComponents(const QString& ref)
// {
//   QString fnCall("getComponents(" + ref + ")");
// 	QString returnString(callModeq(fnCall));

// 	std::vector<ComponentDeclaration> componentDeclarations;
// 	if (returnString == "{{}}") return componentDeclarations;

// 	// Remove surrounding braces.
// 	QString componentList(returnString.mid(1, returnString.length() - 2));

// 	// Extract each component from the list of components returned from Modeq.
// 	while (!componentList.isEmpty())
// 	{
// 		int i;

// 		// Extract the type.
// 		i = componentList.find(',');
// 		if (i == -1) throw ModeqError(fnCall, returnString);	// Parse error.
// 		QString type(componentList.mid(1, i - 1).stripWhiteSpace());
// 		componentList = componentList.remove(0, i + 1).stripWhiteSpace();

// 		// Extract the name.
// 		i = componentList.find(',');
// 		if (i == -1) throw ModeqError(fnCall, returnString);	// Parse error.
// 		QString name(componentList.left(i).stripWhiteSpace());
// 		componentList = componentList.remove(0, i + 1).stripWhiteSpace();

// 		// Extract the comment.
// 		i = 0;
// 		do {
// 			i = componentList.find('"', i + 1);
// 		} while (componentList.at(i - 1) == '\\');
// 		QString comment(componentList.mid(1, i - 1));
// 		comment.replace("\\\"", "\"").replace("\\\\", "\\");
// 		componentList = componentList.remove(0, i + 3).stripWhiteSpace();

// 		// Create declaration record.
// 		componentDeclarations.push_back(ComponentDeclaration(type, name, comment));
// 	}

// 	return componentDeclarations;
// }

/**
 * \brief
 * Returns the placement annotations for the components in the Modelica class specified by \a ref.
 *
 * The annotations returned are the one available in Modeq. Use the functions of the
 * ModelicaComponent object to obtain the local version of the annotations.
 *
 * \param ref the reference to the Modelica class.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 *
 * \see ModelicaComponent::getPlacementAnnotation()
 */
// std::vector<PlacementAnnotation*> ModeqCommunicator::getComponentAnnotations(const QString& ref)
// {
//   QString fnCall("getComponentAnnotations(" + ref + ")");
// 	QString returnString(callModeq(fnCall));

// 	std::vector<PlacementAnnotation*> componentAnnotations;

// 	// Remove surrounding braces.
// 	QString annotationList(returnString.mid(1, returnString.length() - 2));

// 	// Remove any whitespace in the string to simplify the extraction of annotations.
// 	annotationList = annotationList.remove(' ');
// 	while (!annotationList.isEmpty()) {
// 		if (annotationList.startsWith("{}")) {
// 			componentAnnotations.push_back(0);
// 			annotationList = annotationList.remove(0, 3);
// 		} else {
// 			int i(annotationList.find('}'));
// 			QString annotation(annotationList.mid(0, i + 1));
// 			annotationList = annotationList.remove(0, i + 2);	
// 			try {
// 				componentAnnotations.push_back(compiler_->compilePlacementAnnotation(annotation.latin1()));
// 			} catch (SyntaxError&) {
// 				// compilePlacementAnnotation never throws SyntaxError as modeq returns {} if a component has a invalid annotation
// 				qWarning(QString("[Internal Error] ModeqCommunicator::getComponentAnnotations():\n") +
// 					"Parsing of placement annotation failed. The annotation is ignored.\n");
// 				QMessageBox::critical(0, tr("Modelica Kernel Error"),
// 					tr(QString("<NOBR><B>A function call to the Modelica kernel failed.</B><BR><BR>") +
// 					"The editor and kernel might be in an inconsistent state.<BR>Please restart the editor."));
				
// 				componentAnnotations.push_back(0);
// 			}
// 		}
// 	}

// 	return componentAnnotations;
// }

/**
 * \brief
 * Returns the modification of the component with the given index in the Modelica class specified
 * by \a ref.
 *
 * \param ref the reference to the Modelica class.
 * \param index the index of the component in the Modelica class.
 * \param name the name of the component with the specified index.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 *
 * \see setNthComponentModification()
 */
// Modification* ModeqCommunicator::getNthComponentModification(const QString& ref, int index, const QString& name)
// {
// 	QString fnCall("getNthComponentModification(" + ref + "," + QString::number(index) + ")");
// 	QString returnString(callModeq(fnCall));

// 	std::vector<ComponentModifier*> modifiers;

// 	if (returnString == "{Code()}") return 0;

// 	// Remove enclosing {Code()}.
// 	returnString = returnString.mid(6, returnString.length() - 8).stripWhiteSpace();
// 	QString modificationString = returnString;
// //	qDebug(returnString);
// //	qDebug("MODIFICATION: " + modificationString);

// 	// = <expr>?
// 	if (modificationString.startsWith("=")) {
// 		QString value(modificationString.mid(1));
// 		modifiers.push_back(new ComponentModifier("", value));
// //		qDebug(">>> =" + value);
// //		qDebug("");
// 		return new Modification(name, returnString, modifiers);
// 	}
// 	// := <expr>?
// 	else if (modificationString.startsWith(":=")) {
// 		QString value(modificationString.mid(2));
// 		modifiers.push_back(new ComponentModifier("", value));
// //		qDebug(">>> =" + value);
// //		qDebug("");
// 		return new Modification(name, returnString, modifiers);
// 	} else {
// 		if( modificationString.startsWith("(") && modificationString.endsWith(")") )
// 		{		
// 			// Remove surrounding ()
// 			modificationString = modificationString.mid(1, modificationString.length() - 2);
// 		}		

// 	}

// 	// Redclaration?
// 	if (modificationString.startsWith("redeclare")) {
// 		// Skip modifier
// 		int pDepth(0);
// 		while (!modificationString.isEmpty()) {
// 			if (modificationString.startsWith("(")) {
// 				++pDepth;
// 			} else if (modificationString.startsWith(")")) {
// 				--pDepth;
// 			} else if (modificationString.startsWith(",") && pDepth == 0) {
// 				modificationString = modificationString.remove(0, 1).stripWhiteSpace();
// 				break;
// 			}
// 			modificationString = modificationString.remove(0, 1);
// 		}
// 	}
// 	// Modification.
// 	else {
// 		QString componentReference("");
// 		QString value("");
		
// 		while (!modificationString.isEmpty()) {
// 			// Remove any occurence of each and final.
// 			while (true) {
// 				if (modificationString.startsWith("each")) {
// 					modificationString = modificationString.remove(0,4).stripWhiteSpace();
// 				} else if (modificationString.startsWith("final")) {
// 					modificationString = modificationString.remove(0,5).stripWhiteSpace();
// 				} else {
// 					break;
// 				}
// 			}
// 			int pDepth(0);

// 			// Take care of the case (unit="m")=2, (unit="m") is removed
// 			if( modificationString.startsWith("(") && !modificationString.endsWith(")") ){
				
// 				while(!modificationString.isEmpty())
// 				{
// 					if (modificationString.startsWith("(")) { ++pDepth; }
// 					else if (modificationString.startsWith(")")) { --pDepth; }
// 					else if( modificationString.startsWith("=") && pDepth == 0 )
// 					{
// 						break;
// 					}
// 					modificationString = modificationString.remove(0, 1);
// 				}
				
// 				pDepth = 0;
// 			}

// 			while (!modificationString.isEmpty()) {
// 				if (modificationString.startsWith("(")) { ++pDepth; }
// 				else if (modificationString.startsWith(")")) { --pDepth; }
// 				else if (modificationString.startsWith("=") && pDepth == 0) {
// 					int bDepth(0), btDepth(0);
// 					modificationString = modificationString.mid(1).stripWhiteSpace();
// 					while (true) {
// 						// Last modifier? (No comma found).
// 						if (modificationString.isEmpty()) {
// 							break;
// 						}
// 						else if (modificationString.startsWith("(")) { ++pDepth; }
// 						else if (modificationString.startsWith(")")) { --pDepth; }
// 						else if (modificationString.startsWith("{")) { ++bDepth; }
// 						else if (modificationString.startsWith("}")) { --bDepth; }
// 						else if (modificationString.startsWith("[")) { ++btDepth; }
// 						else if (modificationString.startsWith("]")) { --btDepth;	}
// 						else if (modificationString.startsWith(",") && pDepth == 0 && bDepth == 0 && btDepth == 0) {
// 							modificationString = modificationString.mid(1).stripWhiteSpace();
// 							break;
// 						}
// 						value += modificationString.at(0);
// 						modificationString = modificationString.remove(0, 1);
// 					}
// 					break;
// 				}
				
// 				componentReference += modificationString.at(0);
// 				modificationString = modificationString.remove(0, 1);
// 			}

// 			// Remove any colon at the end of the component reference (happens when := is used).
// 			if (componentReference.endsWith(":")) {
// 				componentReference = componentReference.left(componentReference.length() - 1);
// 			}

// 			// Remove any inner modifications from the component reference.
// 			int i(componentReference.find('('));
// 			if (i > 0) {
// 				componentReference = componentReference.left(i);
// 			}

// 			// Do not store any deep modifiers.
// 			if (componentReference.find('.') > 0) {
// 				continue;
// 			}
// 			modifiers.push_back(new ComponentModifier(componentReference, value));

// 			//			qDebug(">>> " + componentReference + "=" + value);
// 			//			qDebug(modificationString);
// 			componentReference = "";
// 			value = "";
// 		}

// 	}

// 	return new Modification(name, returnString, modifiers);
// }

/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::addConnection(const QString& sourceConnectorRef,
// 																			const QString& destinationConnectorRef,
// 																			const QString& ref,
// 																			const QString& annotation)
// {
//   QString fnCall = "addConnection(" + sourceConnectorRef + "," + destinationConnectorRef + "," +
//     ref + "," + annotation + ")";
//   QString returnString(callModeq(fnCall));

//   if (returnString.lower() != "true" && returnString.lower() != "ok") {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::updateConnection(const QString& sourceConnectorRef,
// 																				 const QString& destinationConnectorRef,
// 																				 const QString& ref,
// 																				 const QString& annotation)
// {
//   QString fnCall = "updateConnection(" + sourceConnectorRef + "," + destinationConnectorRef + "," +
//     ref + "," + annotation + ")";
//   QString returnString(callModeq(fnCall));

//   if (returnString.lower() != "true" && returnString.lower() != "ok") {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::deleteConnection(const QString& sourceConnectorRef,
// 																				 const QString& destinationConnectorRef,
// 																				 const QString& ref)
// {
//   QString fnCall("deleteConnection(" + sourceConnectorRef + "," + destinationConnectorRef + "," + ref + ")");
//   QString returnString(callModeq(fnCall));

//   if (returnString.lower() != "true" && returnString.lower() != "ok") {
//     throw ModeqError(fnCall, returnString);
//   }
// }

/**
 * \brief
 * Returns the number of connections of the specified Modelica class.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// int ModeqCommunicator::getConnectionCount(const QString& ref)
// {
//   QString fnCall("getConnectionCount(" + ref + ")");
//   QString returnString(callModeq(fnCall));

//   bool conversionResult;
//   int count(returnString.toInt(&conversionResult));
//   if (!conversionResult) throw ModeqError(fnCall, returnString);

//   return count;
// }

/**
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// QString ModeqCommunicator::getNthConnection(const QString& ref, int index)
// {
//   QString fnCall("getNthConnection(" + ref + "," + QString::number(index) + ")");
//   return callModeq(fnCall);
// }

/**
 * \brief
 * Returns the connection annotation of the connection with the given index in the Modelica class
 * specified by \a ref.
 *
 * A null pointer is returned if no annotation exists. The annotation returned is the one available
 * in Modeq and is not neccessarly up to date. Use the functions of the ModelicaConnection object to
 * obtain the latest version of the annotation.
 *
 * \param ref the reference to the Modelica class.
 * \param index the index of the connection in the Modelica class.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 * \throw SyntaxError if the compilation of the connection annotation fails.
 *
 * \see ModelicaConnection::getConnectionLine()
 */
// Line* ModeqCommunicator::getNthConnectionAnnotation(const QString& ref, int index)
// {
//   QString fnCall("getNthConnectionAnnotation(" + ref + "," + QString::number(index) + ")");
//   QString annotationString(callModeq(fnCall));

//   if (annotationString.isEmpty()) {
//     return 0;
//   } else {
//     return compiler_->compileConnectionAnnotation(annotationString.latin1());
//   }
// }

/**
 * \brief
 * Returns the class definition of the specified Modelica class.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// QString ModeqCommunicator::list(const QString& ref)
// {
//   QString fnCall("list(" + ref + ")");
//   QString classDefinition(callModeq(fnCall));

//   // Remove the surrounding " characters.
//   return classDefinition.mid(1, classDefinition.length() - 2);
// }

/**
 * \brief
 * Quits Modeq.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 */
// void ModeqCommunicator::quit()
// {
//   QString fnCall("quit()");
//   callModeq(fnCall);
// }

/**
 * \brief
 * Updates the specified Modelica class with the given class definition.
 *
 * Never call this function directly, use the setClassDefinition() function of the
 * ModelicaClassManager, it will also update the internal caches of the editor.
 *
 * \throw ModeqError if the Modeq function call fails.
 * \throw ModeqConnectionLost if the connection to Modeq is lost.
 * \throw SyntaxError if the parsing of the specified class definition fails.
 *
 * \see ModelicaClassManager::setClassDefinition()
 */
// void ModeqCommunicator::updateClassDefinition(const QString& ref,
// 																							const QString& definition)
// {
// 	QString fnCall;
// 	if (!ModelicaClassManager::getPath(ref).isEmpty()) {
// 		fnCall += "within " + ModelicaClassManager::getPath(ref) + "; ";
// 	}
// 	fnCall += definition;
//   QString returnString(callModeq(fnCall));

// 	if (returnString != "Ok") {
// 		throw SyntaxError(returnString);
// 	}
// }


