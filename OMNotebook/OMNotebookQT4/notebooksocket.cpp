/*! 
 * \file notebooksocket.cpp
 * \author Anders Fernström
 * \date 2006-05-03
 *
 * File/class is taken from a personal project by Anders Fernström,
 * modified to fit OMNotebook
 */

#define IAEX_SOCKET_PORT		2643

// STD Headers
#include <iostream>

// QT Headers
#include <QtNetwork/QHostAddress>
#include <QtNetwork/QTcpServer>
#include <QtNetwork/QTcpSocket>

// IAEX Headers
#include "application.h"
#include "notebooksocket.h"


using namespace std;
namespace IAEX
{
	/*!
	 * \class NotebookSocket
	 * \author Anders Fernström
	 * \date 2006-05-03
	 *
     * \brief Handles communication with other instances (processes) 
	 * of the application using tcp sockets.
	 */
	NotebookSocket::NotebookSocket( Application* application )
		: application_( application ),
		server_( 0 ),
		foundServer_( false )
	{
		socket_ = new QTcpSocket();

		//connection
		connect( socket_, SIGNAL( readyRead() ),
			this, SLOT( receiveNewSocketMsg() ));
	}
	
	/*! 
	 * \author Anders Fernström
	 * \date 2006-05-03
	 *
	 * \brief The class destructor
	 */
	NotebookSocket::~NotebookSocket()
	{
		if( socket_ || server_ )
			closeNotebookSocket();
	}


	// NOTEBOOK SOCKET CORE FUNCTIONS
	// ------------------------------------------------------------------

	/*! 
	 * \author Anders Fernström
	 * \date 2006-05-03
	 *
	 * \brief Try to connect with other notebook instance, if 
	 * succesfull the function will return true. If unable to 
	 * connect the function trys to start a server (that waits 
	 * for incomming communiction). Returns false if successful 
	 * in setting up the loop. If both attemps fails the function 
	 * throws an exception.
	 */
	bool NotebookSocket::connectToNotebook()
	{
		// first try to connect to existing notebook process/application
        if( tryToConnect() )
			return true;

		// unable to connect, try to start server
		if( startServer() )
			return false;

		// something is wrong, throw exception
		throw runtime_error( "Unable to connect OR start server" );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-05-03
	 *
	 * \brief Closes socket and dose clean up.
	 */
	bool NotebookSocket::closeNotebookSocket()
	{
		// socket
		if( socket_ )
		{
			if( socket_->state() == QAbstractSocket::ConnectedState )
			{
				socket_->disconnectFromHost();
				
				if( socket_->state() == QAbstractSocket::ConnectedState )
					if( !socket_->waitForDisconnected( 5000 ))
						throw runtime_error( "Unable to disconnect socket from host" );
			}

			delete socket_;
			socket_ = 0;
		}
		
		// server
		if( server_ )
		{
			if( server_->isListening() )
				server_->close();

			delete server_;
			server_ = 0;
		}

		return true;
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-05-03
	 *
	 * \brief Sends a filename to the main/correct process,
	 * returns true on success - otherwise false
	 */
	bool NotebookSocket::sendFilename( QString filename )
	{
		cout << "sendFilename()" << endl;

		// connected socket to correct server
		if( foundServer_ )
		{
			QString file = "FILE: " + filename;
			if( socket_->write( file.toStdString().c_str(), file.size() ) == -1 )
			{
				cout << "[Socket Error] Socket->sendFilename(): " << 
					socket_->errorString().toStdString() << endl;
				return false;
			}

			if( !socket_->waitForBytesWritten( 5000 ))
				return false;

			// sucess
			return true;
		}

		throw runtime_error( "Didn't found correct server" );
	}


	// PRIVATE SLOTS
	// ------------------------------------------------------------------

	/*! 
	 * \author Anders Fernström
	 * \date 2006-05-03
	 *
	 * \brief Handles incomming connections
	 */
	void NotebookSocket::receiveNewConnection()
	{
		if( server_->hasPendingConnections() )
		{
			cout << "NotebookSocket: {new Connection}" << endl;
			QTcpSocket* socket = server_->nextPendingConnection();
			
			// write, ask if OMNNotebook
			if( socket->write( "Hello! OMNNotebook?", 25 ) == -1 )
			{
				cout << "[Socket Error] Server->receiveNewConnection(): " << 
					socket->errorString().toStdString() << endl;
				return;
			}
			
			// wait and see if receive filepath from socket, if not
			// asume that it isn't correct notebook.
			socket->waitForBytesWritten( 5000 );
			if( socket->waitForReadyRead( 8000 ))
			{
				// read socket data
				QByteArray msg = socket->readAll();
				QString filename( msg );

				// check if correkt data
				if( filename.startsWith( "FILE: " ))
				{
					// exstract filename
					filename = filename.mid( 6, filename.size() - 6 );
					cout << "Received filename: <" << filename.toStdString() << ">" << endl;

					// tell applicaiton to open filename
					application_->open( filename );
				}
				else
					cout << "[Socket Error] Server->receiveNewConnection(): " << 
					"Received wrong message." << endl;
			}
			else
				cout << "[Socket Error] Server->receiveNewConnection(): " << 
					"Didn't receive any message." << endl;

			// close socket
			socket->close();
			delete socket;
		}
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-05-03
	 *
	 * \brief Handles incomming messages
	 */
	void NotebookSocket::receiveNewSocketMsg()
	{
		cout << "Socket: Recive new message" << endl;
		if( socket_ )
		{
			QByteArray msg = socket_->readAll();
			cout << "Message: <" << msg.data() << ">" << endl;

			if( string( msg.data() ) == string( "Hello! OMNNotebook?" ))
				foundServer_ = true;
			else
				cout << "Received worng message." << endl;
		}
	}


	// HELP FUNCTIONS
	// ------------------------------------------------------------------
	
	/*! 
	 * \author Anders Fernström
	 * \date 2006-05-03
	 *
	 * \brief Trys to connect with another notebook process and recive a
	 * message from that process, returns true if successful - otherwise 
	 * false.
	 */
	bool NotebookSocket::tryToConnect()
	{
		// try to connect
		socket_->connectToHost( QHostAddress::LocalHost, IAEX_SOCKET_PORT );
		if( socket_->waitForConnected( 100 ))
		{
			if( !socket_->waitForReadyRead( 5000 ))
			{
				cout << "[Socket Error] tryToConnect(): Didn't recevie any message" << endl;
				return false;
			}

			// success
			return true;
		}

		// unable to connect
		socket_->disconnectFromHost();
		return false;
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2006-05-03
	 *
	 * \brief Trys to setup a server, returns true if successful - 
	 * otherwise false.
	 */
	bool NotebookSocket::startServer()
	{
		// setup server
		server_ = new QTcpServer();
		server_->setMaxPendingConnections( 5 );

		// connect server
		connect( server_, SIGNAL( newConnection() ),
			this, SLOT( receiveNewConnection() ));

		// listen
		if( !server_->listen( QHostAddress::LocalHost, IAEX_SOCKET_PORT ) )
		{
			cout << "[Socket Error] Server->listen(): " << server_->errorString().toStdString() << endl;
			return false;
		}

		// success
		return true;
	}

}
