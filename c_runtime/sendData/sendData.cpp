/* 
 * This file is part of OpenModelica.
 * 
 * Copyright (c) 1998-2008, Linköpings University,
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
 * 
 * For more information about the Qt-library visit TrollTech:s webpage regarding
 * licence: http://www.trolltech.com/products/qt/licensing.html
 * 
 */

//Qt headeers
//#include <QCoreApplication>
#include <QtNetwork/QTcpSocket>
#include <QByteArray>
#include <QDataStream>
#include <QString>
#include <QTextStream>
#include <QFile>
#include <QBuffer>
//#include <QtNetwork/QTcpServer>
//#include <QMessageBox>
#include <QVariant>
#include <QColor>
#include <QVector>
#include <QDir>
//#include <string>
//#include <QTime>
#include <QProcess>
#include <QThread>
#include <QtNetwork/QHostAddress>
//Std headers
//#include <iostream>
#include <vector>
//#include <fstream>
#include <cstdlib>
//IAEX headers
#include "sendData.h"
#include <sstream>

using namespace std;

Connection::Connection()
{
//	app = 0;
	socket = 0;

}

Connection::~Connection()
{
	/*
	if(app)
	{
	app->exec();
	delete app;
	}
	*/

	//   if(socket)
	//      delete socket;
}   

QTcpSocket* Connection::newConnection(bool graphics)
{
	socket = new QTcpSocket;
	socket->connectToHost(QHostAddress::LocalHost, Static::port1);
	if(socket->waitForConnected(100))
		return socket;
	else if(QFile::exists("ext.exe"))
	{

		//		QProcess* p = new QProcess;

		QProcess::startDetached("ext.exe");
		//		p->waitForStarted(5000);

		socket->connectToHost(QHostAddress::LocalHost, graphics?7779:7778);

		if(socket->waitForConnected(2000))
			return socket;

		socket->connectToHost(QHostAddress::LocalHost, graphics?7779:7778);
		if(socket->waitForConnected(2000))
			return socket;

		socket->abort();
		delete socket;
		socket = 0;
		//app = 0;
		return 0;
	}
	else
		return 0;
}   

bool Static::connect(bool graphics)
{
//	ofstream ofs("uu3u.txt", ios::app);
	
//	ofs << 1 << endl;	
	if(graphics)
	{
//	ofs << 2 << endl;	

		if(socket2.state() != QAbstractSocket::UnconnectedState)
		{
//		ofs << 3 << endl;	

			return true;
//			socket2.disconnectFromHost();
//			socket2.waitForDisconnected(1000);
		}
		
		socket2.connectToHost(QHostAddress::LocalHost, Static::port2);
//	ofs << 4 << endl;	

		if(socket2.waitForConnected(500))
			return true;	
		
		if(QFile::exists("ext.exe"))
		{
			QProcess::startDetached("ext.exe");
			socket2.connectToHost(QHostAddress::LocalHost, Static::port2);
			if(socket2.waitForConnected(2500))
				return true;	

			socket2.connectToHost(QHostAddress::LocalHost, Static::port2);
			if(socket2.waitForConnected(3500))
				return true;	
		}
//	ofs << 5 << endl;	
		
		return false;
//	ofs << 1 << endl;	
		
		
	}
	else
	{
//	ofs << 6 << endl;	

		if(socket1.state() != QAbstractSocket::UnconnectedState)
		{
			return true;
//			socket1.disconnectFromHost();
//			socket1.waitForDisconnected(1000);
		}
		
		socket1.connectToHost(QHostAddress::LocalHost, Static::port1);
		if(socket1.waitForConnected(500))
			return true;	
		
		if(QFile::exists("ext.exe"))
		{
			QProcess::startDetached("ext.exe");
			socket1.connectToHost(QHostAddress::LocalHost, Static::port1);
			if(socket1.waitForConnected(2500))
				return true;	

			socket1.connectToHost(QHostAddress::LocalHost, Static::port1);
			if(socket1.waitForConnected(3500))
				return true;	
		}
		
		return false;
		
		
	}

}

QColor* stringToColor(const char* str_)
{
	QString str = QString(str_).toLower();
	
	if(str == "white")
		return new QColor(Qt::white);
	else if(str == "black")
		return new QColor(Qt::black);
	else if(str == "red")
		return new QColor(Qt::red);
	else if(str == "darkred")
		return new QColor(Qt::darkRed);
	else if(str == "green")
		return new QColor(Qt::green);
	else if(str == "darkgreen")
		return new QColor(Qt::darkGreen);
	else if(str == "blue")
		return new QColor(Qt::blue);
	else if(str == "darkblue")
		return new QColor(Qt::darkBlue);
	else if(str == "cyan")
		return new QColor(Qt::cyan);
	else if(str == "darkcyan")
		return new QColor(Qt::darkCyan);
	else if(str == "magenta")
		return new QColor(Qt::magenta);
	else if(str == "darkmagenta")
		return new QColor(Qt::darkMagenta);
	else if(str == "yellow")
		return new QColor(Qt::yellow);
	else if(str == "darkyellow")
		return new QColor(Qt::darkYellow);
	else if(str == "gray")
		return new QColor(Qt::gray);
	else if(str == "darkgray")
		return new QColor(Qt::darkGray);
	else if(str == "lightgray")
		return new QColor(Qt::lightGray);
	else if(str == "transparent")
		return new QColor(Qt::transparent);
	else
		return new QColor(Qt::black);
}

QColor* getColor(const char* color, int colorR, int colorG, int colorB)
{
	if(colorR == -1 && colorG == -1 && colorB == -1)
		return stringToColor(color);
	else
		return new QColor(min(255,max(0,colorR)), min(255,max(0,colorG)), min(255,max(0,colorB)));
}

bool ellipse(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB)
//bool ellipse(double x0, double y0, double x1, double y1, const char* color, int* colorRGB, int tmp1, const char* fillColor, int* fillColorRGB, int tmp2)
{
	/*
	int colorR = colorRGB[0];
	int colorG = colorRGB[1];
	int colorB = colorRGB[2];
	
	int fillColorR = fillColorRGB[0];
	int fillColorG = fillColorRGB[1];
	int fillColorB = fillColorRGB[2];
*/

//	Connection c;
//	QTcpSocket* socket = c.newConnection();
	
	

	if(Static::connect(true))
	{
		QByteArray block;
		QDataStream out(&block, QIODevice::WriteOnly);
		out.setVersion(QDataStream::Qt_4_2);

		out << (quint32)0;
		out << QString("drawEllipse-1.1");
		out << x0 << y0 << x1 << y1;
		QColor *c = getColor(color, colorR, colorG, colorB);
		out << *c;
		delete c;
		c = getColor(fillColor, fillColorR, fillColorG, fillColorB);
		out << *c;
		delete c;

		out.device()->seek(0);
		out << (quint32)(block.size() - sizeof(quint32));
//		socket->write(block);
//		socket->flush();
//		socket->waitForBytesWritten(-1);
		Static::socket2.write(block);
		Static::socket2.flush();
		Static::socket2.waitForBytesWritten(-1);

/*
		socket->disconnectFromHost();
		if(socket->state() == QAbstractSocket::ConnectedState)
			socket->waitForDisconnected(-1);
		delete socket;
*/
	}
	return true;
}

bool rect(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB)
{
//	Connection c;
//	QTcpSocket* socket = c.newConnection();
	if(Static::connect(true))
	{
		QByteArray block;
		QDataStream out(&block, QIODevice::WriteOnly);
		out.setVersion(QDataStream::Qt_4_2);

		out << (quint32)0;
		out << QString("drawRect-1.1");
		out << x0 << y0 << x1 << y1;

		QColor* c = getColor(color, colorR, colorG, colorB); 
		out << *c;
		delete c;
		c = getColor(fillColor, fillColorR, fillColorG, fillColorB);
		out << *c;
		delete c;

		out.device()->seek(0);
		out << (quint32)(block.size() - sizeof(quint32));
		Static::socket2.write(block);
		Static::socket2.flush();
		Static::socket2.waitForBytesWritten(-1);

//		socket->write(block);
//		socket->flush();
//		socket->waitForBytesWritten(-1);
/*
		socket->disconnectFromHost();
		if(socket->state() == QAbstractSocket::ConnectedState)
			socket->waitForDisconnected(-1);
		delete socket;
		*/
	}
	return true;
}

bool line(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB)
{
//	Connection c;
//	QTcpSocket* socket = c.newConnection();
	if(Static::connect(true))
	{
		QByteArray block;
		QDataStream out(&block, QIODevice::WriteOnly);
		out.setVersion(QDataStream::Qt_4_2);

		out << (quint32)0;
		out << QString("drawLine-1.1");
		out << x0 << y0 << x1 << y1;

		QColor* c = getColor(color, colorR, colorG, colorB);   
		out << *c;
		delete c;
		c = getColor(fillColor, fillColorR, fillColorG, fillColorB);
		out << *c;
		delete c;

		out.device()->seek(0);
		out << (quint32)(block.size() - sizeof(quint32));

		Static::socket2.write(block);
		Static::socket2.flush();
		Static::socket2.waitForBytesWritten(-1);
/*
		socket->write(block);
		socket->flush();
		socket->waitForBytesWritten(-1);

		socket->disconnectFromHost();
		if(socket->state() == QAbstractSocket::ConnectedState)
			socket->waitForDisconnected(-1);
		delete socket;
		*/
	}
	return true;
}


bool hold(int status)
{
//	Connection c;
//	QTcpSocket* socket = c.newConnection();
	if(Static::connect(true))
	{
		QByteArray block;
		QDataStream out(&block, QIODevice::WriteOnly);
		out.setVersion(QDataStream::Qt_4_2);

		out << (quint32)0;
		out << QString("hold-1.1");
		out << status;

		out.device()->seek(0);
		out << (quint32)(block.size() - sizeof(quint32));

		Static::socket2.write(block);
		Static::socket2.flush();
		Static::socket2.waitForBytesWritten(-1);
/*
		socket->write(block);
		socket->flush();
		socket->waitForBytesWritten(-1);

		socket->disconnectFromHost();
		if(socket->state() == QAbstractSocket::ConnectedState)
			socket->waitForDisconnected(-1);
		delete socket;
		*/
	}
	return true;
}

bool pltWait(unsigned long msecs)
{
	class thread: public QThread
	{
	public:
		static void msleep ( unsigned long msecs )
		{
			QThread::msleep(msecs);
		}
	};

	thread::msleep(msecs);
	return true;
}

bool pltTable(double* table, size_t r, size_t c) //, const char* legend, int size)
{

	char* legend[] = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"};
//	size_t size = 3; 
	size_t size = c; 

	Connection C;
	QTcpSocket* socket = C.newConnection();
	if(!socket)
		return false;

	QByteArray block;
	QDataStream out(&block, QIODevice::WriteOnly);
	out.setVersion(QDataStream::Qt_4_2);

	out << (quint32)0;
	out << QString("ptolemyDataStream-1.2");
	out.device()->seek(0);
	out << (quint32)(block.size() - sizeof(quint32));

	socket->write(block);
	socket->flush();
	socket->waitForBytesWritten(-1);

	block.clear();

//	QString title = QString("title");
//	QString xLabel = QString("xlabel");
//	QString yLabel = QString("ylabel");
	bool legend_ = true;
	bool grid = true;
	bool logX = false;
	bool logY = false;

	QString interpolation5 = QString("linear");
	bool drawPoints = true;
	QString range = QString("0.0,0.0,0.0,0.0");
	
	out.device()->seek(0);
	out << (quint32)0;
	out << QString("title");
	out << QString("xLabel");
	out << QString("yLabel");
	out << (int)legend_;
	out << (int)grid;
//	out << xMin << xMax << yMin << yMax;
	out << (int)logX;
	out << (int)logY;
	out << QString(interpolation5);
	out << (int)drawPoints;
	out << QString("0.0,0.0,0.0,0.0");
	out << quint32(c);


	for( size_t i = 0; i < size; ++i)
	{

		out << QString(legend[i]);
		out << QColor(Qt::color0);
		
	}

	out.device()->seek(0);
	out << (quint32)(block.size() - sizeof(quint32));

	socket->write(block);
	socket->flush();
	socket->waitForBytesWritten(-1);

	block.clear();

	for(size_t i = 0; i < r; ++i)
	{
		out.device()->seek(0);
		out << (quint32)0;
		out << quint32(c);

		for(size_t j = 0; j < c; ++j)
		{
			out << QString(legend[j]);
			out << table[i*c+j];
			
		}
		out.device()->seek(0);
		out << (quint32)(block.size() - sizeof(quint32));

		socket->write(block);
		socket->flush();
		socket->waitForBytesWritten(-1);
		
		block.clear();

if(!(i%100))
	socket->flush();
	
	}

	socket->flush();



	socket->waitForBytesWritten(-1);
	socket->disconnectFromHost();
	if(socket->state() == QAbstractSocket::ConnectedState)
		socket->waitForDisconnected(-1);
	if(socket)
		delete socket;


	return true;
}

QTcpSocket Static::socket1;
QTcpSocket Static::socket2;
QTcpSocket* Static::socket = 0;
QByteArray* Static::block = 0;
QDataStream* Static::out = 0;
Connection* Static::c = 0;
QStringList* Static::filterVariables = 0;
int Static::port1 = 7778;
int Static::port2 = 7779;
bool Static::enabled_ = false;

void setVariableFilter(const char* variables)
{
	QString var(variables);
	var = var.replace("\"", " ");
	stringstream ss;
	ss << var.toStdString();
	if(!Static::filterVariables)
		Static::filterVariables = new QStringList;

	Static::filterVariables->clear();
	string str;
	while(ss.good() && ss >> str)
	{
		Static::filterVariables->push_back(QString(str.c_str()));	
	}	
}
	void setDataPort(int port)
	{
		Static::port1 = port;	
	}
	
	void enableSendData(int enable)
	{
		Static::enabled_ = enable;
	}

void initSendData(int variableCount1, int variableCount2, char** statesNames, char** stateDerivativesNames,  char** algebraicsNames)
{
	char* port = getenv("sendDataPort");
	if(port != NULL && strlen(port))
		setDataPort(QVariant(port).toInt());
	char* filter = getenv("sendDataFilter");
	if(filter != NULL && strlen(filter))
		setVariableFilter(filter);
	else
		setVariableFilter("");
		
	if(Static::socket)
	{
		delete Static::socket;
		Static::socket = 0;
	}
	Static::block = new QByteArray;
	Static::out = new QDataStream(Static::block, QIODevice::WriteOnly);
	Static::out->setVersion(QDataStream::Qt_4_2);
	
	Static::c = new Connection;
	Static::socket = Static::c->newConnection();


//*************

//	QByteArray block;
//	QDataStream out(&block, QIODevice::WriteOnly);
//	out.setVersion(QDataStream::Qt_4_2);

	*Static::out << (quint32)0;
	*Static::out << QString("simulationDataStream-1.2");
	Static::out->device()->seek(0);
	*Static::out << (quint32)(Static::block->size() - sizeof(quint32));

	Static::socket->write(*Static::block);
	Static::socket->flush();

	Static::socket->waitForBytesWritten(-1);

	Static::block->clear();

/*
	int legend = 1;
	int grid = 1;
	int logX = 0;
	int logY = 0;
	int drawPoints = 0;

	Static::out->device()->seek(0);
	*Static::out << (quint32)0;
	*Static::out << QString("title");
	*Static::out << QString("xLabel");
	*Static::out << QString("yLabel");
	*Static::out << (int)legend;
	*Static::out << (int)grid;
//	out << xMin << xMax << yMin << yMax;
	*Static::out << (int)logX;
	*Static::out << (int)logY;
	*Static::out << QString("linear");
	*Static::out << (int)drawPoints;
	*Static::out << QString("0.0,0.0 0.0,0.0");
*/
	Static::out->device()->seek(0);
	*Static::out << (quint32)0;
//	qint64 pos = Static::out->device()->pos();

	
	*Static::out << (quint32)25;//(2*variableCount1 + variableCount2);
	quint32 N = 1;

		*Static::out << QString("time");

	for(int i = 0; i < variableCount1; ++i)
	{
		if(!Static::filterVariables->empty() && !Static::filterVariables->contains(QString(statesNames[i])))
			continue;
//		cout << statesNames[i] << endl;
		*Static::out << QString(statesNames[i]);
//		*Static::out << QColor(Qt::color0);
		++N;
	}


	for(int i = 0; i < variableCount1; ++i)
	{
		if(!Static::filterVariables->empty() && !Static::filterVariables->contains(QString(stateDerivativesNames[i])))
			continue;
		*Static::out << QString(stateDerivativesNames[i]);
//		*Static::out << QColor(Qt::color0);
		++N;
	}

	for(int i = 0; i < variableCount2; ++i)
	{
		if(!Static::filterVariables->empty() && !Static::filterVariables->contains(QString(algebraicsNames[i])))
			continue;
		*Static::out << QString(algebraicsNames[i]);
//		*Static::out << QColor(Qt::color0);
		++N;
	}
//	Static::out->device()->seek(pos);	
	Static::out->device()->seek(0);
	*Static::out << (quint32)(Static::block->size() - sizeof(quint32));
	*Static::out << (quint32)N;

	Static::socket->write(*Static::block);
	Static::socket->flush();

	Static::socket->waitForBytesWritten(-1);

	Static::block->clear();

	//*************



}


void sendPacket(const char* data)
{
	Static::block->clear();
	stringstream ss;
	ss << data;
	string str;
	double data2;
	Static::out->device()->seek(0);
	*Static::out << (quint32)0;
	while(ss.good() && ss >> str)
	{
		ss >> data2;
		if(!Static::filterVariables->empty() && !Static::filterVariables->contains(QString(str.c_str())))
			continue;
		*Static::out << QString(str.c_str());
		*Static::out << (qreal)data2;
	}

//	cout << "sendPacket:" << endl << data << endl << endl;
	
	Static::out->device()->seek(0);
	*Static::out << (quint32)(Static::block->size() - sizeof(quint32));

	Static::socket->write(*Static::block);
	Static::socket->waitForBytesWritten(-1);
	Static::block->clear();
}

void closeSendData()
{
//	cout << "closeSendData" << endl;
	
	Static::socket->flush();
	Static::socket->waitForBytesWritten(-1);
	Static::socket->disconnectFromHost();
	if(Static::socket->state() == QAbstractSocket::ConnectedState)
		Static::socket->waitForDisconnected(-1);
	if(Static::socket)
		delete Static::socket;
	
	
	
	
}
void emulateStreamData(const char* data, const char* title, const char* xLabel, const char* yLabel, const char* interpolation5, int legend, int grid, int logX, int logY, int drawPoints, const char* range)
{
	Connection c;

	QTcpSocket* socket = c.newConnection();

	QString data_(data);
	QTextStream ts(&data_);
	QString tmp;

	vector<vector<double>*> variableValues;
	vector<QString> variableNames;

	variableValues.push_back(new vector<double>);
	variableNames.push_back(QString("time"));

	bool timeFinished = false;

	while(!ts.atEnd())
	{
		do
		{
			if(ts.atEnd())
				break;

			tmp = ts.readLine().trimmed();
		}
		while(tmp.size() == 0);

		if(tmp.trimmed().size() == 0)
			break;

		if(tmp.startsWith("#"))
			continue;
		else if(tmp.startsWith("TitleText"))
			continue;
		else if(tmp.startsWith("DataSet"))
		{
			if(variableValues[0]->size())
				timeFinished = true;

			variableValues.push_back(new vector<double>);
			variableNames.push_back(tmp.section(": ", -1));
		}
		else
		{
			if(!timeFinished)
				variableValues[0]->push_back(tmp.section(',', 0, 0).toDouble());

			variableValues[variableNames.size()-1]->push_back(tmp.section(',',-1).toDouble());
		}
	}


	QByteArray block;
	QDataStream out(&block, QIODevice::WriteOnly);
	out.setVersion(QDataStream::Qt_4_2);

	out << (quint32)0;
	out << QString("ptolemyDataStream-1.2");
	out.device()->seek(0);
	out << (quint32)(block.size() - sizeof(quint32));

	socket->write(block);
	socket->flush();
	socket->waitForBytesWritten(-1);


	block.clear();

	out.device()->seek(0);
	out << (quint32)0;
	out << QString(title);
	out << QString(xLabel);
	out << QString(yLabel);
	out << (int)legend;
	out << (int)grid;
//	out << xMin << xMax << yMin << yMax;
	out << (int)logX;
	out << (int)logY;
	out << QString(interpolation5);
	out << (int)drawPoints;
	out << QString(range);
	out << (quint32)variableNames.size();

	for(unsigned int i = 0; i < variableNames.size(); ++i)
	{

		out << variableNames[i];
		out << QColor(Qt::color0);
	}

	out.device()->seek(0);
	out << (quint32)(block.size() - sizeof(quint32));

	socket->write(block);
	socket->flush();
	socket->waitForBytesWritten(-1);

	block.clear();


	for(quint32 i = 0; i < variableValues[0]->size(); ++i)
	{
		out.device()->seek(0);
		out << (quint32)0;
		out << (quint32)variableNames.size();

		for(quint32 j = 0; j < variableNames.size(); ++j)
		{
			out << variableNames[j];
			out << (*variableValues[j])[i];

		}
		out.device()->seek(0);
		out << (quint32)(block.size() - sizeof(quint32));

		socket->write(block);
		socket->flush();
		socket->waitForBytesWritten(-1);
		
		block.clear();

if(!(i%100))
	socket->flush();
	
	}

	socket->flush();

	for(quint32 i = 0; i < variableValues.size(); ++i)
		delete variableValues[i];

	socket->waitForBytesWritten(-1);
	socket->disconnectFromHost();
	if(socket->state() == QAbstractSocket::ConnectedState)
		socket->waitForDisconnected(-1);
	if(socket)
		delete socket;


}



bool plt(const char* var, const char* model, const char* title, const char* xLabel, const char* yLabel, bool legend, bool grid, bool logX, bool logY, const char* interpolation, bool drawPoints, const char* range)
{
	QDir dir(QString(getenv("OPENMODELICAHOME")));
	dir.cd("bin");

	QString filename;

	if(QString(model).isEmpty())
	{
		QFile currentSimulation(dir.path() + "/currentSimulation");
		filename = currentSimulation.readLine();
		currentSimulation.close();
	}
	else
		filename = QString(model);

	filename += "_res.plt";

	QFile file(dir.path() + "/" + filename);
	file.open(QIODevice::ReadOnly);

	QString res;

	res += "#Ptolemy Plot generated by OpenModelica\n";
	res += "TitleText: Plot by OpenModelica\n";
	res += "DataSet: " + QString(var[0]) +QString("\n");

	QVector<double> time, values;

	QString currentVar;

	QString tmp;
	while(!file.atEnd())
	{
		do
		{
			if(file.atEnd())
				break;

			tmp = file.readLine().trimmed();
		}
		while(tmp.size() == 0);

		if(tmp.trimmed().size() == 0)
			break;

		if(tmp.startsWith("#"))
			continue;
		else if(tmp.startsWith("TitleText:"))
			;
		else if(tmp.startsWith("XLabel:"))
			;
		else if(tmp.startsWith("YLabel:"))
			;
		else if(tmp.startsWith("DataSet:"))
		{
			currentVar = tmp.section(": ", 1, 1);
		}
		else if(currentVar == QString(var))
		{
			time << tmp.section(',', 0, 0).toDouble();
			values << tmp.section(',', 1, 1).toDouble();
		}
	}

	for(long i = 0; i < time.size(); ++i)
		res += QVariant(time[i]).toString() +"," +QVariant(values[i]).toString() +"\n";

	file.close();

	emulateStreamData(res.toStdString().c_str(), title, xLabel, yLabel, interpolation, (int)legend, (int)grid, (int)logX, (int)logY, (int)drawPoints, range);
	return true;
}

bool Static::enabled()
{
	return enabled_;	
}
