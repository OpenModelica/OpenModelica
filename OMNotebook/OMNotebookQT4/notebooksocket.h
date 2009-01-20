/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2009, Linköpings University,
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
 * \file notebooksocket.h
 * \author Anders Fernström
 * \date 2006-05-03
 *
 * File/class is taken from a personal project by Anders Fernström,
 * modified to fit OMNotebook
 */

#ifndef IAEX_NOTEBOOK_SOCKET
#define IAEX_NOTEBOOK_SOCKET


// QT Headers
#include <QtCore/QObject>

// forward declaration
class QTcpServer;
class QTcpSocket;


namespace IAEX
{
	// forward declaration
	class CellApplication;


	class NotebookSocket : public QObject
	{
		Q_OBJECT

	public:
		NotebookSocket( CellApplication* application );
		~NotebookSocket();

		// core functions
		bool connectToNotebook();
		bool closeNotebookSocket();
		bool sendFilename( QString filename );


	private slots:
		void receiveNewConnection();
		void receiveNewSocketMsg();

	private:
		// help function
		bool tryToConnect();
		bool startServer();

	private:
		CellApplication* application_;

		QTcpSocket* socket_;
		QTcpSocket* incommingSocket_;
		QTcpServer* server_;

		bool foundServer_;
	};
}

#endif
