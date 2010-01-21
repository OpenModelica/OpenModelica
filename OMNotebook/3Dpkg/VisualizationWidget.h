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
    QWidget *visframe_;
    QVBoxLayout *buttonlayout_;
    QTimer* timer_;
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
