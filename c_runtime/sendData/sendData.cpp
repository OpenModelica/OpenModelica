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
#include <QTemporaryFile>
#include <QtNetwork/QHostAddress>
//Std headers
//#include <iostream>
#include <vector>
//#include <fstream>
#include <cstdlib>
//IAEX headers
#include "sendData.h"
#include <sstream>

#if defined(_MSC_VER) || defined(__MINGW32__)
#define _CRT_SECURE_NO_WARNINGS
#include <windows.h>
#define sleep Sleep
#else
#include <unistd.h>
#endif


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

const char* Connection::getExternalViewerFileName()
{
  char* omdir = getenv("OPENMODELICAHOME");
  QString path(omdir);
  if(path.endsWith("/") || path.endsWith("\\"))
    path += "bin/ext";
  else
    path += "/bin/ext";
#ifdef WIN32
  path += ".exe";
#elif defined(__APPLE_CC__)
  path += ".app";
#endif
  return path.toStdString().c_str();
}


bool Connection::startExternalViewer()
{
  QString path = getExternalViewerFileName();
  if(QFile::exists(path))
  {
    QProcess *plotViewerProcess = new QProcess();
    QString tempPath(QDir::tempPath());
    QString tempFile = tempPath + "/OpenModelica-PlotViewer.log";
    plotViewerProcess->setWorkingDirectory(tempPath);
    // cerr << "simulation runtime: redirecting the output to: " << tempFile.toStdString() << endl;
    plotViewerProcess->setStandardErrorFile(tempFile, QIODevice::Truncate);
    plotViewerProcess->setStandardOutputFile(tempFile, QIODevice::Truncate);
    plotViewerProcess->setProcessChannelMode(QProcess::MergedChannels);


    // 2006-03-14 AF, start viewer
    plotViewerProcess->start( path );

    // wait until the process starts up ...
    int ticks = 0;
    while (1)
    {
      ticks++;
      if( plotViewerProcess->waitForStarted(-1) ) break;
      else
      {
        cerr << "simulation runtime: the plot viewer could not start: " << path.toStdString().c_str();
        cerr << "\n\t error: " << plotViewerProcess->errorString().toStdString() << "!" << endl;
        return false;
      }
      if (ticks > 100)
        break;
    }
    if (plotViewerProcess->state() == QProcess::NotRunning)
    {
      cerr << "\nsimulation runtime: the plot viewer: " << path.toStdString().c_str();
      cerr << " doesn't want to start" << "\n\t error: " << plotViewerProcess->errorString().toStdString() << "!" << endl;
      return false;
    }
    else
    {
      // we need to loose time until the process has time to do listen!
      ticks = 0;
      while (plotViewerProcess->state() != QProcess::Running)
      {
        sleep(1);
        if (ticks > 2)
          break;
      }
      sleep(2);
      return true;
    }
  }
  else
  {
    cerr << "simulation runtime: the plot viewer: " << \
      path.toStdString().c_str() << " doesn't exist!" << endl;
    return false;
  }
}

QTcpSocket* Connection::newConnection(bool graphics)
{

  socket = new QTcpSocket;
  socket->connectToHost(QHostAddress::LocalHost, Static::port1);
  if(socket->waitForConnected(500))
  {
    return socket;
  }
  else if (startExternalViewer())
  {
    int ticks = 0;
    while (1)
    {
      ticks++;
      socket->connectToHost(QHostAddress::LocalHost, graphics?7779:7778);
      if (socket->state() != QAbstractSocket::ConnectedState)
      {
        if(socket->waitForConnected(-1))
        {
          return socket;
        }
        else
        {
          cerr << "Could not connect to socket because: " << socket->errorString().toStdString() << endl;
        }
      }
      if (ticks > 100)
        break;
    }

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

    if (c->startExternalViewer())
    {
      int ticks = 0;
      while (1)
      {
        ticks++;
        socket2.connectToHost(QHostAddress::LocalHost, Static::port2);
        if (socket2.state() != QAbstractSocket::ConnectedState)
          if(socket2.waitForConnected(5000))
            return true;
        if (ticks > 100)
          break;
      }
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

    if (c->startExternalViewer())
    {
      int ticks = 0;
      while (1)
      {
        ticks++;
        socket1.connectToHost(QHostAddress::LocalHost, Static::port1);
        if (socket1.state() != QAbstractSocket::ConnectedState)
          if(socket1.waitForConnected(5000))
            return true;
        if (ticks > 100)
          break;
      }
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

  const char* legend[] = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"};
  //	size_t size = 3;
  size_t size = c;

  //	Connection C;
  //	QTcpSocket* socket = C.newConnection();
  //	if(!socket)
  //		return false;

  if(Static::connect(false))
  {
    QByteArray block;
    QDataStream out(&block, QIODevice::WriteOnly);
    out.setVersion(QDataStream::Qt_4_2);

    out << (quint32)0;
    out << QString("ptolemyDataStream-1.2");
    out.device()->seek(0);
    out << (quint32)(block.size() - sizeof(quint32));

    Static::socket1.write(block);
    Static::socket1.flush();
    Static::socket1.waitForBytesWritten(-1);

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

    Static::socket1.write(block);
    Static::socket1.flush();
    Static::socket1.waitForBytesWritten(-1);

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

      Static::socket1.write(block);
      Static::socket1.flush();
      Static::socket1.waitForBytesWritten(-1);

      block.clear();

      if(!(i%100))
        Static::socket1.flush();

    }

    Static::socket1.flush();



    Static::socket1.waitForBytesWritten(-1);
    Static::socket1.disconnectFromHost();
    if(Static::socket1.state() == QAbstractSocket::ConnectedState)
      Static::socket1.waitForDisconnected(-1);
    //	if(socket)
    //		delete socket;

    return true;
  }
  //	return true;
  return false;
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
  if (!Static::socket)
  {
    cerr << "simulation runtime: error, could not open socket to plotter!" << endl;
    return;
  }


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
  out << xMin << xMax << yMin << yMax;
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
  if(Static::block)
    delete Static::block;
  if(Static::out)
    delete Static::out;
  if(Static::c)
    delete Static::c;
}

void emulateStreamData(const char* data, const char* title, const char* xLabel, const char* yLabel, const char* interpolation5, int legend, int grid, int logX, int logY, int drawPoints, const char* range)
{

  Connection c;

  QTcpSocket* socket = c.newConnection();

  // cerr << "simulation runtime: emulateStreamData ..." << endl; 

  if(!socket)
  {
    cerr << "simulation runtime: error, could not connect to Plot Viewer socket!" << endl;
    cerr << "simulation runtime: please try to run the Plot Viewer manually: " << c.getExternalViewerFileName() << endl;
    return;
  }

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
  // cerr << "simulation runtime: " << "sending the command through the socket" << endl;
  out << QString("ptolemyDataStream-1.2");
  out.device()->seek(0);
  out << (quint32)(block.size() - sizeof(quint32));

  if (!socket->isValid())
  {
    cerr << "simulation runtime: Socket doesn't appear to be valid: " <<
      socket->errorString().toStdString() << "!" << endl;
  }

  if (socket->write(block) < 0)
  {
    cerr << "simulation runtime: error writing to socket 1: " <<
      socket->errorString().toStdString() << "!" << endl;
  }

  // cerr << "simulation runtime: sending the variable block! waiting for the bytes to be written..." << endl;

  if (!socket->waitForBytesWritten(-1))
  {
    cerr << "simulation runtime: error writing to socket 2: " <<
      socket->errorString().toStdString() << "!" << endl;
  }

  // cerr << "simulation runtime: bytes were written!" << endl;

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

  // cerr << "simulation runtime: sending variable names..." << endl;

  for(unsigned int i = 0; i < variableNames.size(); ++i)
  {
    out << variableNames[i];
    out << QColor(Qt::color0);
  }

  out.device()->seek(0);
  out << (quint32)(block.size() - sizeof(quint32));

  if (socket->write(block) < 0)
  {
    cerr << "simulation runtime: error writing to socket 3: " <<
      socket->errorString().toStdString() << "!" << endl;
  }
  if (!socket->waitForBytesWritten(-1))
  {
    cerr << "simulation runtime: error writing to socket 4: " <<
      socket->errorString().toStdString() << "!" << endl;
  }

  // cerr << "simulation runtime: bytes were written!" << endl;

  block.clear();

  // cerr << "simulation runtime: sending variable values..." << endl;

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

    if (socket->write(block) < 0)
    {
      cerr << "simulation runtime: error writing to socket 5: " <<
        socket->errorString().toStdString() << "!" << endl;
    }
    if (!socket->waitForBytesWritten(-1))
    {
      cerr << "simulation runtime: error writing to socket 6: " <<
        socket->errorString().toStdString() << "!" << endl;
    }

    block.clear();

  }

  // cerr << "simulation runtime: bytes were written!" << endl;

  for(quint32 i = 0; i < variableValues.size(); ++i)
    delete variableValues[i];

  socket->disconnectFromHost();
  if(socket->state() == QAbstractSocket::ConnectedState)
    socket->waitForDisconnected(-1);
  if(socket)
    delete socket;

  // cerr << "simulation runtime: emulateStreamData exiting..." << endl;

}



bool plt(const char* var, const char* model, const char* title, const char* xLabel, const char* yLabel, bool legend, bool grid, bool logX, bool logY, const char* interpolation, bool drawPoints, const char* range)
{
  QDir dir(QString(getenv("OPENMODELICAHOME")));
  dir.cd("tmp");

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

  emulateStreamData(res.toStdString().c_str(), title, xLabel, yLabel, interpolation, (int)legend,
    (int)grid, (int)logX, (int)logY, (int)drawPoints, range);
  return true;
}

bool Static::enabled()
{
  return enabled_;
}

QString getModelResultsFileName(const char* model)
{
  QDir dirCurrentDir = QDir::current();
  QDir dirOpenModelica(QString(getenv("OPENMODELICAHOME")));
  QString file1 = dirOpenModelica.path() + "/tmp/" + model;
  QString file2 = dirCurrentDir.path() + "/" + model;
  QString f;
  if (QFile::exists(file2)) // try first in the current directory!
  {
    f = file2;
  }
  else if (QFile::exists(file1)) // try then in $OPENMODELICA/tmp/
  {
    f = file1;
  }
  return f;
}


int getVariableListSize(const char* model)
{
  QString fileName = getModelResultsFileName(model);
  if (fileName.isEmpty())
    return 0;
  QFile f(fileName);
  f.open(QIODevice::ReadOnly);
  QTextStream ts(&f);
  QString str;

  int N = 0;
  while(!ts.atEnd())
  {
    str = ts.readLine();
    if(str.startsWith("DataSet: "))
      N += str.size() - 8; //reserve space for a separator
  }

  f.close();
  return N;
}

bool getVariableList(const char* model, char* lst)
{
  QString fileName = getModelResultsFileName(model);
  if (fileName.isEmpty())
    return 0;
  QFile f(fileName);
  f.open(QIODevice::ReadOnly);
  QTextStream ts(&f);
  QString str;

  QString L;
  while(!ts.atEnd())
  {
    str = ts.readLine();
    if(str.startsWith("DataSet: "))
      L += str.right(str.size() - 8);
  }

  f.close();
  strcpy(lst, L.trimmed().toStdString().c_str());;
  return true;
}


void emulateStreamData2(const char *info, const char* data, int port)
{
  Connection c;
  QTcpSocket* socket = c.newConnection();

  QString info_str(info);
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
      // cerr << "added " << tmp.section(": ", -1).toStdString() << endl;
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
  out << QString("ptolemyDataStream");
  out.device()->seek(0);
  out << (quint32)(block.size() - sizeof(quint32));

  socket->write(block);
  socket->flush();
  socket->waitForBytesWritten(-1);

  block.clear();
  out.device()->seek(0);
  out << (quint32)0;
  out << info_str;
  //	cout << "var size: " << variableNames.size() << endl;
  out << (quint32)variableNames.size();

  for(unsigned int i = 0; i < variableNames.size(); ++i)
  {
    //		cout << "name: " << variableNames[i].toStdString() << endl;
    out << variableNames[i];
  }

  out.device()->seek(0);
  out << (quint32)(block.size() - sizeof(quint32));

  socket->write(block);
  socket->flush();
  socket->waitForBytesWritten(-1);

  block.clear();

  //	cout << "varvals[0]->size = " << variableValues[0]->size() << endl;

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
    //		cout << "i: " << i << endl;
    //_sleep(500);
    if(!(i%100))
      socket->flush();

  }

  socket->flush();

  /*
  out << (quint32)0;
  out << QString("graphicsStream");
  out.device()->seek(0);
  out << (quint32)(block.size() - sizeof(quint32));

  socket->write(block);
  socket->flush();
  socket->waitForBytesWritten(-1);
  */

  for(quint32 i = 0; i < variableValues.size(); ++i)
    delete variableValues[i];

  socket->waitForBytesWritten(-1);
  socket->disconnectFromHost();
  if(socket->state() == QAbstractSocket::ConnectedState)
    socket->waitForDisconnected(-1);
  if(socket)
    delete socket;

  /*
  for(quint32 i = 0; i < variableValues[0]->size(); ++i)
  {
  out.device()->seek(0);
  out << (quint32)0;
  out << (quint32)variableNames.size();
  cout << "i = " << i;

  for(quint32 j = 0; j < variableNames.size(); ++j)
  {
  //			cout << variableNames[j].toStdString() << ": " << (*variableValues[j])[i] << endl;
  out << variableNames[j];
  out << (*variableValues[j])[i];
  cout << ".";
  }
  cout << "!";
  out.device()->seek(0);
  out << (quint32)(block.size() - sizeof(quint32));
  cout << (quint32)(block.size() - sizeof(quint32));

  socket->write(block);
  block.clear();
  cout << "!" << endl;
  socket->flush();
  socket->waitForBytesWritten(-1);
  _sleep(100);
  }

  socket->flush();

  for(quint32 i = 0; i < variableValues.size(); ++i)
  delete variableValues[i];

  socket->disconnectFromHost();
  if(socket->state() == QAbstractSocket::ConnectedState)
  socket->waitForDisconnected(-1);
  if(socket)
  delete socket;

  */
}

