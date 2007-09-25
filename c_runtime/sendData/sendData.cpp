/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1997-2007, Linköpings universitet,
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

//IAEX headers
#include "sendData.h"

using namespace std;

Connection::Connection()
{
	app = 0;
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

QTcpSocket* Connection::newConnection()
{
	socket = new QTcpSocket;
	socket->connectToHost(QHostAddress::LocalHost, 7778);
	if(socket->waitForConnected(100))
		return socket;
	else if(QFile::exists("ext.exe"))
	{

		//		QProcess* p = new QProcess;

		QProcess::startDetached("ext.exe");
		//		p->waitForStarted(5000);

		socket->connectToHost(QHostAddress::LocalHost, 7778);

		if(socket->waitForConnected(2000))
			return socket;

		socket->connectToHost(QHostAddress::LocalHost, 7778);
		if(socket->waitForConnected(2000))
			return socket;

		socket->abort();
		delete socket;
		socket = 0;
		app = 0;
		return 0;
	}
	else
		return 0;
}   

QColor stringToColor(QString str)
{
	str = str.toLower();

	if(str == "white")
		return Qt::white;
	else if(str == "black")
		return Qt::black;
	else if(str == "red")
		return Qt::red;
	else if(str == "darkred")
		return Qt::darkRed;
	else if(str == "green")
		return Qt::green;
	else if(str == "darkgreen")
		return Qt::darkGreen;
	else if(str == "blue")
		return Qt::blue;
	else if(str == "darkblue")
		return Qt::darkBlue;
	else if(str == "cyan")
		return Qt::cyan;
	else if(str == "darkcyan")
		return Qt::darkCyan;
	else if(str == "magenta")
		return Qt::magenta;
	else if(str == "darkmagenta")
		return Qt::darkMagenta;
	else if(str == "yellow")
		return Qt::yellow;
	else if(str == "darkyellow")
		return Qt::darkYellow;
	else if(str == "gray")
		return Qt::gray;
	else if(str == "darkgray")
		return Qt::darkGray;
	else if(str == "lightgray")
		return Qt::lightGray;
	else if(str == "transparent")
		return Qt::transparent;
	else
		return Qt::black;
}

QColor getColor(const char* color, int colorR, int colorG, int colorB)
{
	if(colorR == -1 && colorG == -1 && colorB == -1)
		return stringToColor(color);
	else
		return QColor(min(255,max(0,colorR)), min(255,max(0,colorG)), min(255,max(0,colorB)));
}

bool ellipse(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB)
{
	Connection c;
	QTcpSocket* socket = c.newConnection();
	if(socket)
	{
		QByteArray block;
		QDataStream out(&block, QIODevice::WriteOnly);
		out.setVersion(QDataStream::Qt_4_2);

		out << (quint32)0;
		out << QString("drawEllipse-1.1");
		out << x0 << y0 << x1 << y1;

		out << getColor(color, colorR, colorG, colorB) << getColor(fillColor, fillColorR, fillColorG, fillColorB);

		out.device()->seek(0);
		out << (quint32)(block.size() - sizeof(quint32));
		socket->write(block);
		socket->flush();

		socket->disconnectFromHost();
		if(socket->state() == QAbstractSocket::ConnectedState)
			socket->waitForDisconnected(-1);
		delete socket;
	}
	return true;
}

bool rect(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB)
{
	Connection c;
	QTcpSocket* socket = c.newConnection();
	if(socket)
	{
		QByteArray block;
		QDataStream out(&block, QIODevice::WriteOnly);
		out.setVersion(QDataStream::Qt_4_2);

		out << (quint32)0;
		out << QString("drawRect-1.1");
		out << x0 << y0 << x1 << y1;

		out << getColor(color, colorR, colorG, colorB) << getColor(fillColor, fillColorR, fillColorG, fillColorB);

		out.device()->seek(0);
		out << (quint32)(block.size() - sizeof(quint32));
		socket->write(block);
		socket->flush();

//		socket->disconnectFromHost();
		if(socket->state() == QAbstractSocket::ConnectedState)
			socket->waitForDisconnected(-1);
		delete socket;
	}
	return true;
}

bool line(double x0, double y0, double x1, double y1, const char* color, int colorR, int colorG, int colorB, const char* fillColor, int fillColorR, int fillColorG, int fillColorB)
{
	Connection c;
	QTcpSocket* socket = c.newConnection();
	if(socket)
	{
		QByteArray block;
		QDataStream out(&block, QIODevice::WriteOnly);
		out.setVersion(QDataStream::Qt_4_2);

		out << (quint32)0;
		out << QString("drawLine-1.1");
		out << x0 << y0 << x1 << y1;

		out << getColor(color, colorR, colorG, colorB) << getColor(fillColor, fillColorR, fillColorG, fillColorB);

		out.device()->seek(0);
		out << (quint32)(block.size() - sizeof(quint32));
		socket->write(block);
		socket->flush();

		socket->disconnectFromHost();
		if(socket->state() == QAbstractSocket::ConnectedState)
			socket->waitForDisconnected(-1);
		delete socket;
	}
	return true;
}


bool hold(int status)
{
	Connection c;
	QTcpSocket* socket = c.newConnection();
	if(socket)
	{
		QByteArray block;
		QDataStream out(&block, QIODevice::WriteOnly);
		out.setVersion(QDataStream::Qt_4_2);

		out << (quint32)0;
		out << QString("hold-1.1");
		out << status;

		out.device()->seek(0);
		out << (quint32)(block.size() - sizeof(quint32));
		socket->write(block);
		socket->flush();

		socket->disconnectFromHost();
		if(socket->state() == QAbstractSocket::ConnectedState)
			socket->waitForDisconnected(-1);
		delete socket;
	}
	return true;
}

bool wait(unsigned long msecs)
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

void emulateStreamData(const char* data, int port, const char* title, const char* xLabel, const char* yLabel, const char* interpolation5, int legend, int grid, double xMin, double xMax, double yMin, double yMax, int logX, int logY, int drawPoints, const char* range)
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
	out << QString("ptolemyDataStream-1.1");
	out.device()->seek(0);
	out << (quint32)(block.size() - sizeof(quint32));

	socket->write(block);
	socket->flush();

//ofstream of2("ut225.txt");
//	of2 << title << endl << xLabel << endl << range << endl;
//	of2.close();

	block.clear();

	out.device()->seek(0);
	out << (quint32)0;
	out << QString(title);
	out << QString(xLabel);
	out << QString(yLabel);

	out << (int)legend;
	out << (int)grid;
	out << xMin << xMax << yMin << yMax;

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

	block.clear();

//ofstream of("ut2.txt");

	for(quint32 i = 0; i < variableValues[0]->size(); ++i)
	{
		out.device()->seek(0);
		out << (quint32)0;
		out << (quint32)variableNames.size();

		for(quint32 j = 0; j < variableNames.size(); ++j)
		{
			out << variableNames[j];
			out << (*variableValues[j])[i];

//			of << variableNames[j].toStdString() << endl;
//			of << (*variableValues[j])[i] << endl;
			
		}
		out.device()->seek(0);
		out << (quint32)(block.size() - sizeof(quint32));

		socket->write(block);
		block.clear();

if(!(i%100))
	socket->flush();
	
	}
//of.close();
	socket->flush();

	for(quint32 i = 0; i < variableValues.size(); ++i)
		delete variableValues[i];

	socket->disconnectFromHost();
	if(socket->state() == QAbstractSocket::ConnectedState)
		socket->waitForDisconnected(-1);
	if(socket)
		delete socket;
}

bool plt(const char* var, const char* model, const char* title, const char* xLabel, const char* yLabel, bool legend, bool grid, double xmin, double xmax, double ymin, double ymax, bool logX, bool logY, const char* interpolation, bool drawPoints, const char* range)
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

	emulateStreamData(res.toStdString().c_str(), 7778, title, xLabel, yLabel, interpolation, (int)legend, (int)grid, xmin, xmax, ymin, ymax, (int)logX, (int)logY, (int)drawPoints, range);
	return true;
}
