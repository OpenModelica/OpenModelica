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
	class Application;


	class NotebookSocket : public QObject
	{
		Q_OBJECT

	public:
		NotebookSocket( Application* application );
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
		Application* application_;

		QTcpSocket* socket_;
		QTcpSocket* incommingSocket_;
		QTcpServer* server_;

		bool foundServer_;
	};
}

#endif
