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

#include "VisualizationWidget.h"

namespace IAEX {

	VisualizationWidget::VisualizationWidget(QWidget *parent) : QWidget(parent)
	{
//#ifdef HAVE_COIN
		this->setMinimumWidth(600);
		this->setMinimumHeight(300);
		this->setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding));

		visframe_ = new QWidget(this);

		visframe_->setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding));

#ifdef HAVE_COIN
		simdata_ = new SimulationData();
		simdata_->setFrame(0);
#endif

		QFrame *buttonframe = new QFrame();
		QPushButton *playbutton = new QPushButton("Play");
		playbutton->setFixedWidth(32);
		QPushButton *stopbutton = new QPushButton("Stop");
		stopbutton->setFixedWidth(32);
		QPushButton *rewbutton = new QPushButton("Rew");
		rewbutton->setFixedWidth(32);
		label_ = new QLabel();
		label_->setText("0");
		slider_ = new QSlider(Qt::Vertical);
#ifdef HAVE_COIN
		slider_->setRange(1000*simdata_->get_start_time(), 1000*simdata_->get_end_time());
#endif
		slider_->setValue(0);
#ifdef HAVE_COIN
    currentTime_ = 1000*simdata_->get_start_time();
#endif
		timer_ = new QTimer(this);
		// 40 fps
		timer_->setInterval(25);

		connect(slider_, SIGNAL(valueChanged(int)),
			this, SLOT(sliderChanged(int)));
		connect(playbutton, SIGNAL(clicked()),
			timer_, SLOT(start()));
		connect(stopbutton, SIGNAL(clicked()),
			timer_, SLOT(stop()));
		connect(timer_, SIGNAL(timeout()),
			this, SLOT(nextFrame()));

		buttonlayout_ = new QVBoxLayout();
		buttonlayout_->addWidget(playbutton);
		buttonlayout_->addWidget(stopbutton);
		buttonlayout_->addWidget(rewbutton);
		buttonlayout_->addWidget(slider_);
		buttonlayout_->addWidget(label_);
		buttonlayout_->setAlignment(slider_, Qt::AlignHCenter);
		buttonlayout_->setAlignment(label_, Qt::AlignHCenter);

		buttonframe->setLayout(buttonlayout_);

#ifdef HAVE_COIN
		eviewer_ = new SoQtExaminerViewer(visframe_, NULL, TRUE, SoQtFullViewer::BUILD_NONE);
		//eviewer_->setSize(SbVec2s(600,400));
    //eviewer_->setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding));
		eviewer_->setSceneGraph(simdata_->getSceneGraph());
		eviewer_->setBackgroundColor(SbColor(0.95f, 0.95f, 0.95f));
#else
    new QLabel(QString("Coin3D was disabled on this build.\nThe rest of the widget still works so\nthe application won't crash when we send it data."), visframe_);
#endif

		//SoCamera *cam = eviewer_->getCamera();
		//cam->

		QHBoxLayout *framelayout = new QHBoxLayout(this);
		framelayout->addWidget(visframe_);
		framelayout->addWidget(buttonframe);
		this->setLayout(framelayout);

		server = new QTcpServer(this);
		server->setMaxPendingConnections(500);
		activeSocket = 0;
//#endif

	}

	VisualizationWidget::~VisualizationWidget(void)
	{
    delete slider_;
#ifdef HAVE_COIN        
    delete eviewer_;
#endif        
    delete visframe_;
    delete server;
    delete buttonlayout_;
    delete timer_;
	}

	void VisualizationWidget::sliderChanged(int val) {
		currentTime_ = val;
		QString num;
		num.setNum(currentTime_/1000.0);
		label_->setText(num);
#ifdef HAVE_COIN
		simdata_->setFrame(currentTime_/1000.0);
#endif
	}

	void VisualizationWidget::nextFrame() {
		currentTime_ += 25; // FIIIIX!
#ifdef HAVE_COIN
		if (currentTime_ > 1000*simdata_->get_end_time()) {
			currentTime_ = 0;
		}
#endif

		QString num;
		num.setNum(currentTime_/1000.0);
		label_->setText(num);
		slider_->setValue(currentTime_);
#ifdef HAVE_COIN
		simdata_->setFrame(currentTime_/1000.0);
#endif
	}

	void  VisualizationWidget::setServerState(bool listen)
	{
//#ifdef HAVE_COIN
		if(listen)
		{

			if(!getServerState())
				if(!server->listen(QHostAddress::Any, quint16(7778)))
				{
					QTcpSocket s(this);
					s.connectToHost("localhost", quint16(7778));
					if(s.waitForConnected(2000))
					{
						QByteArray b;

						QDataStream ds(&b, QIODevice::WriteOnly);
						ds.setVersion(QDataStream::Qt_4_2);
						ds << quint32(0);
						ds << QString("closeServer");
						ds.device()->seek(0);
						ds << quint32(b.size()-sizeof(quint32));
						s.write(b);
						s.flush();

						s.disconnect();

						qApp->processEvents();
						server->listen(QHostAddress::Any, quint16(7778));
						qApp->processEvents();

					}
				}

				emit newMessage("Listening for connections");

				emit serverState(server->isListening());
				if(!connect(server, SIGNAL(newConnection()), this, SLOT(acceptConnection())))
					QMessageBox::critical(0, QString("fel!"), QString("fel"));
		}
		else
		{
			server->close();
			emit newMessage("Port closed");
			emit serverState(false);
		}
//#endif
	}

	bool VisualizationWidget::getServerState()
	{
//#ifdef HAVE_COIN
		return server->isListening();
//#else
        return 0;
//#endif
	}

	void VisualizationWidget::acceptConnection()
	{
//#ifdef HAVE_COIN
		while(server && server->hasPendingConnections())
		{
			if( (activeSocket && (activeSocket->state() == QAbstractSocket::UnconnectedState) || !activeSocket))
			{

				emit newMessage("New connection accepted");

				activeSocket = server->nextPendingConnection();
				ds.setDevice(activeSocket);
				ds.setVersion(QDataStream::Qt_4_2);

				blockSize = 0;

				connect(activeSocket, SIGNAL(readyRead()), this, SLOT(getData()));
			}

			qApp->processEvents();
		}
//#endif
	}

	void VisualizationWidget::getData()	{
//#ifdef HAVE_COIN
		disconnect(activeSocket, SIGNAL(readyRead()), 0, 0);
		connect(activeSocket, SIGNAL(readyRead()), this, SLOT(getData()));

		while(activeSocket->bytesAvailable())
		{
			if (blockSize == 0)
			{
				if (activeSocket->bytesAvailable() < sizeof(quint32))
					return;

				ds >> blockSize;
			}

			if (activeSocket->bytesAvailable() < blockSize)
				return;

			QString command;
			ds >> command;

			if(command == QString("closeServer"))
			{
				setServerState(false);
				activeSocket->disconnect();
				activeSocket->disconnectFromHost();
			}
			else if(command == QString("ptolemyDataStream"))
			{
#ifdef HAVE_COIN
				simdata_->clear();
#endif
				emit newMessage("Recieving streaming data...");
				disconnect(activeSocket, SIGNAL(readyRead()), 0, 0);

				connect(activeSocket, SIGNAL(readyRead()), this, SLOT(readPtolemyDataStream()));
				connect(activeSocket, SIGNAL(disconnected()), this, SLOT(ptolemyDataStreamClosed()));

				variableCount = 0;
				packetSize = 0;

				return;
			}

			blockSize = 0;
		}

		connect(activeSocket, SIGNAL(readyRead()), this, SLOT(getData()));
//#endif
	}



	void VisualizationWidget::readPtolemyDataStream() {
//#ifdef HAVE_COIN
		QString tmp;
		//qint32 variableCount = 0;
  //  	qint32 packetSize = 0;
		double d;
		quint32 it = 0;

		do
		{
			if(packetSize == 0)
			{
				if(ds.device()->bytesAvailable() >= sizeof(qint32))
					ds >> packetSize;
				else
					return;
			}

			uint a = ds.device()->bytesAvailable();
			if(a < packetSize) {
				return;
			}


			if(variableCount == 0)
			{
//				variables.clear();
				QString info;
				ds >> info;
				std::cout << "info: " << info.toStdString() << std::endl;
				QString tmp = info.trimmed();
				bool finished = false;
				while (!finished) {
					QString compound, objname, objtype, params;
					int i,j;
					i = tmp.indexOf("\n");
					int q = tmp.indexOf("Q");
					std::cout << "i: " << i << " & tmp = " << tmp.toStdString() << std::endl;
					if (i < 0) {
						finished = true;
						compound = tmp;
					} else {
						compound = tmp.left(i);
						tmp = tmp.mid(i+1);
					}
					std::cout << "compound: " << compound.toStdString() << std::endl;

					i = compound.indexOf(",");
					j = compound.indexOf(":");
					if (i < 0) {
						continue;
					} else {
						objname = compound.left(i);
						params = compound.mid(i+2,(j-i)-3);
						objtype = compound.mid(j+1);

						std::cout << "name: " << objname.toStdString()
							<< " & type: " << objtype.toStdString()
							<< " & params: " << params.toStdString() << std::endl;
#ifdef HAVE_COIN
						simdata_->addObject(objtype, objname, params);
#endif
					}
				}

				ds >> variableCount;
				//std::cout << "variables: " << variableCount << std::endl;

				for(quint32 i = 0; i < variableCount; ++i)
				{
					ds >> tmp;

					//tmp = tmp.trimmed();
					//std::cout << i << ": " << tmp.toStdString() << std::endl;
					//if(variables.find(tmp) != variables.end())
					//	delete variables[tmp];
					//variables[tmp] = new VariableData(tmp, color);
				}
				packetSize = 0;
				continue;
			}

			ds >> variableCount;
#ifdef HAVE_COIN
			SimulationKeypoint *point = new SimulationKeypoint();

			for(quint32 i = 0; i < variableCount; ++i)
			{
				ds >> tmp;
				ds >> d;
				if (0 == tmp.compare("time")) {
					point->setTime(d);
				} else {
					point->addVar(tmp, d);
				}
//				std::cout << "var: " << tmp.toStdString() << " = " << d << std::endl;
				//variables[tmp]->push_back(d);
			}
			simdata_->addKeypoint(point);

			packetSize = 0;
			++it;
#endif
		}
		while(activeSocket->bytesAvailable() >= sizeof(quint32));

		if(activeSocket->state() != QAbstractSocket::ConnectedState)
			ptolemyDataStreamClosed();
//#endif
	}

	void VisualizationWidget::ptolemyDataStreamClosed()	{
#ifdef HAVE_COIN
		slider_->setRange(1000*simdata_->get_start_time(), 1000*simdata_->get_end_time());
		slider_->setValue(0);
		//for(map<QString, VariableData*>::iterator i = variables.begin(); i != variables.end(); ++i)
		//	variableData.append(i->second);
		//variables.clear();
		setServerState(false);

		SoCamera *cam = eviewer_->getCamera();
		cam->viewAll(simdata_->getSceneGraph(), eviewer_->getViewportRegion());

		emit newMessage("Connection closed");
#endif
    }

}
