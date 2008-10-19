#pragma once
#include <iostream>
#include <QtGui/QWidget>

//QT Headers
#include <QtNetwork/QTcpSocket>
#include <QtNetwork/QTcpServer>
#include <QtGui/QTextBrowser>
#include <QtGui/QPushButton>
#include <QtGui/QVBoxLayout>
#include <QtGui/QSlider>
#include <QtGui/QLabel>
#include <QtCore/QTimer>
#include <QtGui/QMessageBox>
#include <QtGui/QApplication>

#ifndef __APPLE_CC__
#include <Inventor/Qt/SoQt.h>
#include <Inventor/Qt/SoQtRenderArea.h>
#include <Inventor/Qt/viewers/SoQtExaminerViewer.h>
#include <Inventor/nodes/SoBaseColor.h>
#include <Inventor/nodes/SoCube.h>
#include <Inventor/nodes/SoRotor.h>
#include <Inventor/nodes/SoArray.h>
#include <Inventor/nodes/SoSeparator.h>
#include <Inventor/nodes/SoDirectionalLight.h>
#include <Inventor/nodes/SoPerspectiveCamera.h>
#endif

#include "SimulationData.h"

namespace IAEX {
	class VisualizationWidget :
		public QWidget
	{
		Q_OBJECT
			
	public:
		VisualizationWidget(QWidget *parent);
		~VisualizationWidget(void);

		void setServerState(bool listen);
		bool getServerState(void);


    signals:
		void newMessage(QString message);
		void serverState(bool);

	public slots:
		void getData();
		void acceptConnection();
		void sliderChanged(int val);
		void nextFrame();
		void readPtolemyDataStream();
		void ptolemyDataStreamClosed();

	private:
#ifndef __APPLE_CC__
		SoQtExaminerViewer *eviewer_;
		SoQtRenderArea *renderarea_;
#endif
		QFrame *frame_;
		QSlider *slider_;
		QLabel *label_;
		SimulationData *simdata_;
		int currentTime_;
		QTextBrowser *input_;

		QTcpServer* server;
		QTcpSocket* activeSocket;
		QDataStream ds;
		quint32 blockSize;
		quint32 variableCount;
		quint32 packetSize;

	};
}