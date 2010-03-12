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

//Qt headers
#include <QString>
#include <QVariant>
#include <QGraphicsTextItem>
#include <QPen>
#include <QTextStream>
#include <QImage>
#include <QtGui/QMessageBox>
#include <QGraphicsEllipseItem>
#include <QtAlgorithms>
#include <QPointF>
#include <QMouseEvent>
#include <QPolygonF>
#include <QScrollBar>
#include <QGraphicsScene>
#include <QGraphicsView>
#include <QBuffer>
#include <QFile>
#include <QSizePolicy>
#include <QColor>
#include <QToolTip>
#include <QGraphicsRectItem>
#include <QInputDialog>
#include <QFileDialog>
#include <QFile>
#include <QClipboard>
#include <QApplication>

//Std headers
#include <fstream>
#include <iostream>
#include <cmath>
#include <cstdlib>
#include <cfloat>
#include <map>
#include <iomanip>

//IAEX headers
#include "graphWidget.h"
#include "line2D.h"
#include "lineGroup.h"
#include "dataSelect.h"
#include "variableData.h"
#include "graphWindow.h"
#include "point.h"
#include "legendLabel.h"
#include "curve.h"
#include "focusRect.h"
#include "variablewindow.h"

#include <QtOpenGL/QGLWidget>
using namespace std;

GraphWidget::GraphWidget(QWidget* parent): QGraphicsView(parent)
{
  tmpint = 0;

  graphicsScene = new GraphScene(this);
  setScene(graphicsScene);
  scale(1, -1);
  server = new QTcpServer(this);
  graphicsServer = new QTcpServer(this);
  nr = 0;
  activeSocket = 0;
  graphicsSocket = 0;
  gridVisible = false;
  pan = false;
  stretch = true;

  xLog=yLog = false;
  useManualArea = false;
  fixedGrid = false;
  fixedXSize = false;
  fixedYSize = false;

  graphicsItems = new QGraphicsItemGroup;
  dataPoints = new QList<Point*>;
  antiAliasing = false;
  doSetArea = false;
  doFitInView = false;
  hold = false;

  variableCount = 0;

  this->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
  this->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);

  updateScaleFactors();

  contextMenu = new QMenu(this);

  QAction* tmp;

  tmp=contextMenu->addAction("Fit in view");
  connect(tmp, SIGNAL(triggered()), this, SLOT(resetZoom()));

  contextMenu->addSeparator();

  QActionGroup *ag =new QActionGroup(this);
  tmp = ag->addAction(contextMenu->addAction("Pan"));
  connect(tmp, SIGNAL(toggled(bool)), this, SLOT(setPan(bool)));

  // tmp = ag->addAction(contextMenu->addAction("Select"));
  // connect(tmp, SIGNAL(toggled(bool)), this, SLOT(setSelect(bool)));

  tmp = ag->addAction(contextMenu->addAction("Zoom"));
  connect(tmp, SIGNAL(toggled(bool)), this, SLOT(setZoom(bool)));

  QAction* a;
  foreach(a, ag->actions())
    a->setCheckable(true);

  tmp->setChecked(true);

  contextMenu->addSeparator();

  tmp = contextMenu->addAction("Grid");
  tmp->setCheckable(true);
  connect(tmp, SIGNAL(toggled(bool)), this, SLOT(showGrid(bool)));
  connect(this, SIGNAL(setGridVisible(bool)), tmp, SLOT(setChecked(bool)));

  contextMenu->addSeparator();

  tmp =contextMenu->addAction("Clear");
  connect(tmp, SIGNAL(triggered()), this, SLOT(clear()));

  tmp =contextMenu->addAction("Hold");
  tmp->setCheckable(true);
  connect(tmp, SIGNAL(toggled(bool)), this, SLOT(setHold(bool)));
  connect(this, SIGNAL(holdSet(bool)), tmp, SLOT(setChecked(bool)));
  tmp->setChecked(hold);

  /*
  tmp=contextMenu->addAction("Save");
  connect(tmp, SIGNAL(triggered()), this, SLOT(saveImage()));
  contextMenu->addSeparator();
  */
  tmp=contextMenu->addAction("New window");
  connect(tmp, SIGNAL(triggered()), this, SLOT(newWindow()));
  //	tmp->setVisible(false);
  //	connect(this, SIGNAL(scrolled()), this, SLOT(updateGrid()));

  aaAction = contextMenu->addAction("Antialiasing");
  aaAction->setCheckable(true);
  connect(aaAction, SIGNAL(toggled(bool)), this, SLOT(setAntiAliasing(bool)));

  contextMenu->addSeparator();

  tmp=contextMenu->addAction("Save parameters");
  connect(tmp, SIGNAL(triggered()), this, SLOT(syncCall()));

  contextMenu->addSeparator();

  tmp=contextMenu->addAction("Simulation data...");
  connect(tmp, SIGNAL(triggered()), this, SLOT(showVariables()));

  tmp=contextMenu->addAction("Preferences...");
  connect(tmp, SIGNAL(triggered()), this, SLOT(showPreferences()));

  contextMenu->addSeparator();

  tmp=contextMenu->addAction("Export to Clipboard", this, SLOT(exportToClipboard()), QKeySequence(tr("Ctrl+C")));
  connect(tmp, SIGNAL(triggered()), this, SLOT(exportToClipboard()));

  tmp=contextMenu->addAction("Export as Image");
  connect(tmp, SIGNAL(triggered()), this, SLOT(saveImage()));

  tmp = contextMenu->addAction("oZm");
  connect(tmp, SIGNAL(triggered()), this, SLOT(originalZoom()));
  tmp->setVisible(false);

  tmp = contextMenu->addAction("Add focus box");
  connect(tmp, SIGNAL(triggered()), this, SLOT(addFocusBox()));
  tmp->setVisible(false);

  setContextMenuPolicy(Qt::ActionsContextMenu);
  addActions(contextMenu->actions());

  setZoom(true);

  /*
  #if QT_VERSION >= 0x040300
  setOptimizationFlags(QGraphicsView::DontAdjustForAntialiasing|QGraphicsView::DontSavePainterState);
  // setViewportUpdateMode(QGraphicsView::FullViewportUpdate);
  #endif
  */
}

void GraphWidget::setExpr(QString expr)
{
  currentExpr = expr;
}

void GraphWidget::syncCall()
{
  QRegExp r("(xRange[^\\}]*\\})");
  int i;


  if ((i = r.indexIn(currentExpr)) < 0)
  {
    i = currentExpr.lastIndexOf(")");
    currentExpr.insert(i, ", ");
    i+=2;
  }
  currentExpr.replace(i, r.cap().size(),QString("xRange={") + QVariant(currentArea_.x()).toString() + ", " +
    QVariant(currentArea_.x() + currentArea_.width()).toString() + "}");

  r.setPattern("(yRange[^\\}]*\\})");
  if ((i = r.indexIn(currentExpr)) < 0)
  {
    i = currentExpr.lastIndexOf(")");
    currentExpr.insert(i, ", ");
    i+=2;
  }
  currentExpr.replace(i, r.cap().size(),QString("yRange={") + QVariant(currentArea_.y()).toString() + ", " +
    QVariant(currentArea_.y() + currentArea_.height()).toString() + "}");

  r.setMinimal(true);
  r.setPattern("(grid(.*)(true|false))");
  if((i = r.indexIn(currentExpr)) < 0)
  {
    i = currentExpr.lastIndexOf(")");
    currentExpr.insert(i, ", ");
    i+=2;
  }

  QString b = graphicsScene->gridVisible?"true":"false";
  currentExpr.replace(i, r.cap().size(),QString("grid=") +b);

  r.setPattern("(antiAliasing(.*)(true|false))");
  if((i = r.indexIn(currentExpr)) < 0)
  {
    i = currentExpr.lastIndexOf(")");
    currentExpr.insert(i, ", ");
    i+=2;
  }

  b = antiAliasing?"true":"false";
  currentExpr.replace(i, r.cap().size(),QString("antiAliasing=") +b);

  r.setPattern("(logX(.*)(true|false))");
  if((i = r.indexIn(currentExpr)) < 0)
  {
    i = currentExpr.lastIndexOf(")");
    currentExpr.insert(i, ", ");
    i+=2;
  }

  b = xLog?"true":"false";
  currentExpr.replace(i, r.cap().size(),QString("logX=") +b);

  r.setPattern("(logY(.*)(true|false))");
  if((i = r.indexIn(currentExpr)) < 0)
  {
    i = currentExpr.lastIndexOf(")");
    currentExpr.insert(i, ", ");
    i+=2;
  }

  b = yLog?"true":"false";
  currentExpr.replace(i, r.cap().size(),QString("logY=") +b);

  r.setPattern("(title(.)*(\\\")(.)*(\\\"))");
  if((i = r.indexIn(currentExpr)) < 0)
  {
    i = currentExpr.lastIndexOf(")");
    currentExpr.insert(i, ", ");
    i+=2;
  }

  currentExpr.replace(i, r.cap().size(),(QString("title=%1%2%3").arg("\"").arg(compoundwidget->plotTitle->text()).arg("\"")));

  r.setPattern("(xLabel(.)*(\\\")(.)*(\\\"))");
  if((i = r.indexIn(currentExpr)) < 0)
  {
    i = currentExpr.lastIndexOf(")");
    currentExpr.insert(i, ", ");
    i+=2;
  }

  currentExpr.replace(i, r.cap().size(),(QString("xLabel=%1%2%3").arg("\"").arg(compoundwidget->xLabel->text()).arg("\"")));

  r.setPattern("(yLabel(.)*(\\\")(.)*(\\\"))");
  if((i = r.indexIn(currentExpr)) < 0)
  {
    i = currentExpr.lastIndexOf(")");
    currentExpr.insert(i, ", ");
    i+=2;
  }

  currentExpr.replace(i, r.cap().size(),(QString("yLabel=%1%2%3").arg("\"").arg(compoundwidget->yLabel->text()).arg("\"")));

  emit newExpr(currentExpr);
}

void GraphWidget::originalZoom()
{
  //	this->setMinimumHeight(height() + 50);
}

void GraphWidget::addFocusBox()
{
  FocusRect* r = new FocusRect(currentArea(), this);

  graphicsScene->addItem(r);
  r->show();

}

void GraphWidget::newWindow()
{
  GraphWindow* g = new GraphWindow(0);
  g->setAttribute(Qt::WA_DeleteOnClose);

  CompoundWidget* gw = new CompoundWidget(g);
  delete g->centralWidget();
  g->setCentralWidget(gw);
  g->compoundWidget = gw;

  gw->gvLeft->setScene(graphicsScene->yRulerScene);
  gw->gvBottom->setScene(graphicsScene->xRulerScene);

  gw->gwMain->setScene(graphicsScene);
  gw->gwMain->graphicsScene = graphicsScene;
  gw->gwMain->setArea(this->sceneRect());

  connect(g->actionGrid, SIGNAL(toggled(bool)), gw->gwMain, SLOT(showGrid(bool)));

  connect(this, SIGNAL(zoomEvent(QRectF)), gw->gwMain, SLOT(zoomIn(QRectF)));
  connect(gw->gwMain, SIGNAL(zoomEvent(QRectF)), this, SLOT(zoomIn(QRectF)));

  connect(gw->gwMain, SIGNAL(areaChanged(const QRectF&)), this, SLOT(setArea(const QRectF&)));
  connect(this, SIGNAL(areaChanged(const QRectF&)), gw->gwMain, SLOT(setArea(const QRectF&)));

  g->show();

  gw->gwMain->setArea(this->sceneRect());
}

GraphWidget::~GraphWidget()
{

  for(map<QString, VariableData*>::iterator i = variables.begin(); i != variables.end(); ++i)
    delete i->second;
  variables.clear();
  // variableData.clear();

  delete contextMenu;

  int nr = graphicsScene->views().count();

  foreach(Curve* c, curves)
  {
    graphicsScene->removeItem(c->line);
  }

  if(nr <= 1)
    delete graphicsScene;

  qDeleteAll(curves);
  // qDeleteAll(variableData); //This is handled by the variableData destructor..
}

void GraphWidget::enableServers(bool b)
{
  setServerState(b, true);
  setServerState(b, false);
}

void GraphWidget::setServerState(bool listen, bool graphics)
{
  if(listen)
  {
    if(!getServerState())
    {
      if(!server->listen(QHostAddress::Any, quint16(7778)))
      {
        QTcpSocket s(this);
        s.connectToHost("localhost", quint16(7778));
        if(s.waitForConnected(-1))
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
          // graphicsServer->listen(QHostAddress::Any, quint16(7779));
          qApp->processEvents();
        }
      }

      if(!graphicsServer->listen(QHostAddress::Any, quint16(7779)))
      {
        QTcpSocket s(this);
        s.connectToHost("localhost", quint16(7779));
        if(s.waitForConnected(-1))
        {
          QByteArray b;

          QDataStream ds(&b, QIODevice::WriteOnly);
          ds.setVersion(QDataStream::Qt_4_2);
          ds << quint32(0);
          ds << QString("closeGraphicsServer");
          ds.device()->seek(0);
          ds << quint32(b.size()-sizeof(quint32));
          s.write(b);
          s.flush();

          s.disconnect();

          qApp->processEvents();
          // server->listen(QHostAddress::Any, quint16(7779));
          graphicsServer->listen(QHostAddress::Any, quint16(7779));
          qApp->processEvents();
        }
      }
    }

    emit newMessage("Listening for connections");
    emit serverState(server->isListening());
    if(!connect(server, SIGNAL(newConnection()), this, SLOT(acCon())))
      QMessageBox::critical(0, 
      QString("Could not connect server.newConnection() signal to acCon()!"),
      QString("Could not connect server.newConnection() signal to acCon()!"));
    if (!connect(graphicsServer, SIGNAL(newConnection()), this, SLOT(acCon())))
      QMessageBox::critical(0, 
      QString("Could not connect graphicsServer.newConnection() signal to acCon()!"),
      QString("Could not connect graphicsServer.newConnection() signal to acCon()!"));
  }
  else
  {
    if(graphics)
      graphicsServer->close();
    else
      server->close();

    emit serverState(false);
    emit newMessage("Port closed");
  }
}

void GraphWidget::showPreferences()
{
  emit showPreferences2();
}

void GraphWidget::showVariables()
{
  VariableWindow* i = new VariableWindow(this);
  connect(i, SIGNAL(showGraphics()), this, SIGNAL(showGraphics()));
  i->setAttribute(Qt::WA_DeleteOnClose, true);
  i->show();
}

bool GraphWidget::getServerState()
{
  return server->isListening() && graphicsServer->isListening();
}

void GraphWidget::getData()
{
  if (!activeSocket)
    return;

  while(activeSocket->bytesAvailable())
  {
    if (blockSize == 0)
    {
      // cerr << "getData: blockSize = 0" << endl;
      if (activeSocket->bytesAvailable() < sizeof(quint32))
      {
        // cerr << "getData: returning due to bytesAvailable() < sizeof(quint32)" << endl;
        return;
      }
      ds >> blockSize;
    }

    if (activeSocket->bytesAvailable() < blockSize)
    {
      // cerr << "getData: returning due to bytesAvailable() < blockSize:" << blockSize << endl;
      return;
    }

    QString commandV, command, version;

    ds >> commandV;
    // cerr << "getData: got command: " << commandV.toStdString() << endl;
    command = commandV.section("-", 0, 0);
    version = commandV.section("-", 1, 1);
    // cout << "getData: got command: " << command.toStdString() <<  " version: " << version.toStdString() << endl;

    if(command == QString("clear"))
      // clear(in);
      ;
    else if(command == QString("hold"))
      setHold(ds);
    else if(command == QString("drawLine"))
      drawLine(ds);
    else if(command == QString("drawPoint"))
      drawPoint(ds);
    else if(command == QString("drawText"))
      drawText(ds);
    else if(command == QString("drawRect"))
    {
      drawRect(ds);
      blockSize = 0;
    }
    else if(command == QString("drawEllipse"))
    {
      drawEllipse(ds);
      activeSocket->disconnect();
    }
    else if(command == QString("closeServer"))
    {
      setServerState(false);
      if(activeSocket)
      {
        activeSocket->disconnect();
        activeSocket->disconnectFromHost();
      }
    }
    else if(command == QString("closeGraphicsServer"))
    {
      setServerState(false, true);
      if(graphicsSocket)
      {
        graphicsSocket->disconnect();
        graphicsSocket->disconnectFromHost();
      }
    }
    else if(command == QString("ptolemyDataStream"))
    {
      if(!version.size())
        dataStreamVersion = 1;
      else
        dataStreamVersion = QVariant(version).toDouble();

      if(!hold)
      {
        clear();
      }

      emit newMessage("Receiving streaming data...");
      disconnect(activeSocket, SIGNAL(readyRead()), 0, 0);

      connect(activeSocket, SIGNAL(readyRead()), this, SLOT(plotPtolemyDataStream()));
      connect(activeSocket, SIGNAL(disconnected()), this, SLOT(ptolemyDataStreamClosed()));

      variableCount = 0;
      packetSize = 0;
      plotPtolemyDataStream();

      // cerr << "getData: returning after data was received. block size: " << blockSize << endl;
      return;
    }
    else if(command == QString("graphicsStream"))
    {
      hold = false;
      showGrid(false);
      compoundwidget->showVis();
      emit newMessage("Receiving graphics data...");
      disconnect(graphicsSocket, SIGNAL(readyRead()), 0, 0);

      connect(graphicsSocket, SIGNAL(readyRead()), this, SLOT(showGraphics()));
      connect(graphicsSocket, SIGNAL(disconnected()), this, SLOT(graphicsStreamClosed()));

      packetSize2 = 0;
      drawGraphics();
      // cerr << "getData: returning after graphics data was received" << endl;
      return;
    }
    else if (command == QString("simulationDataStream"))
    {
      compoundwidget->hideVis();
      emit newMessage("Receiving streaming data...");
      disconnect(activeSocket, SIGNAL(readyRead()), 0, 0);
      // adrpo: change these to the ones below
      connect(activeSocket, SIGNAL(readyRead()), this, SLOT(receiveDataStream()));
      connect(activeSocket, SIGNAL(disconnected()), this, SLOT(dataStreamClosed()));
      // connect(activeSocket, SIGNAL(readyRead()), this, SLOT(plotPtolemyDataStream()));
      // connect(activeSocket, SIGNAL(disconnected()), this, SLOT(ptolemyDataStreamClosed()));

      variableCount = 0;
      packetSize = 0;

      receiveDataStream();
      // cerr << "getData: returning after streaming data was received" << endl;
      return;
    }
    blockSize = 0;
  }

  // cerr << "getData: outside while and returning." << endl;  

  connect(activeSocket, SIGNAL(readyRead()), this, SLOT(getData()));
  connect(activeSocket, SIGNAL(disconnected()), this, SLOT(getData()));
}

void GraphWidget::acCon()
{
  while(server && (server->hasPendingConnections() || graphicsServer->hasPendingConnections() ))
  {
    cerr << "acCon: server has pending connections!" << endl;

    if (server->hasPendingConnections()) 
      // && activeSocket && (activeSocket->state() == QAbstractSocket::UnconnectedState) || !activeSocket))
    {
      emit newMessage("New connection accepted");

      activeSocket = server->nextPendingConnection();
      ds.setDevice(activeSocket);
      ds.setVersion(QDataStream::Qt_4_2);

      blockSize = 0;

      cerr << "acCon: server -> connecting readyRead to getData!" << endl;

      connect(activeSocket, SIGNAL(readyRead()), this, SLOT(getData()));
    }

    if (graphicsServer->hasPendingConnections()) 
      // && (activeSocket && (activeSocket->state() == QAbstractSocket::UnconnectedState) || !activeSocket))
    {
      emit newMessage("New connection (graphics) accepted");
      graphicsSocket = graphicsServer->nextPendingConnection();
      ds2.setDevice(graphicsSocket);
      ds2.setVersion(QDataStream::Qt_4_2);
      // cerr << "acCon: graphics server -> connecting readyRead to getData!" << endl;
      connect(graphicsSocket, SIGNAL(readyRead()), this, SLOT(drawGraphics()));
      connect(graphicsSocket, SIGNAL(disconnected()), this, SLOT(graphicsStreamClosed()));
      packetSize2 = 0;
      drawGraphics();
    }

    qApp->processEvents();
  }
}

void GraphWidget::resizeEvent ( QResizeEvent * event )
{
  //fitInView(graphicsScene->sceneRect());
}

void GraphWidget::mousePressEvent ( QMouseEvent * event )
{
  if(event->button() == Qt::LeftButton)
    zoomStart = event->pos();

  QGraphicsView::mousePressEvent(event);
}

void GraphWidget::updatePointSizes(QRect r)
{
  if(r == QRect())
    r = rect();

  QList<QGraphicsItem*> g3;

  if(r.x() < 0)
    g3 = items();
  else
    g3 = items(rect());

  Point* p;

  double xScale = matrix().m11()/125;
  double yScale = -matrix().m22()/200;

  for(int i = 0; i < g3.size(); ++i)
  {
    if((p = dynamic_cast<Point*>(g3.at(i))))
    {
      p->move(-.03/xScale/2., -.03/yScale/2.);
      p->setRect(p->xPos, p->yPos, .03/xScale, .03 /yScale);
    }
  }
}

void GraphWidget::resetZoom()
{
  zoomStr = "";

  bool visible;
  if((visible = graphicsScene->gridVisible))
  {
    showGrid(false);
  }
  graphicsScene->setSceneRect(graphicsScene->itemsBoundingRect());
  setArea(graphicsScene->sceneRect());

  updatePointSizes();

  showGrid(visible);
}

void GraphWidget::mouseReleaseEvent ( QMouseEvent * event )
{
  QGraphicsView::mouseReleaseEvent(event);

  QPointF zoomStartF = mapToScene(zoomStart);
  QPointF zoomEnd = QPointF(mapToScene(event->pos()));

  QRectF prevRect = mapToScene(rect()).boundingRect();

  if(zoom)
  {
    if(event->button() == Qt::LeftButton)
    {
      double left, right, top, bottom;

      if(zoomStartF.x() > zoomEnd.x())
      {
        left = zoomEnd.x();
        right = zoomStartF.x();
      }
      else
      {
        left = zoomStartF.x();
        right = zoomEnd.x();
      }

      if(zoomStartF.y() > zoomEnd.y())
      {
        bottom = zoomEnd.y();
        top = zoomStartF.y();
      }
      else
      {
        top = zoomStartF.y();
        bottom = zoomEnd.y();
      }

      QRectF r(QPointF(left,top),QPointF(right, bottom));
      if(!r.width() || !r.height())
        return;

      zoomIn(r);

      double xScale = matrix().m11()/125;
      double yScale = -matrix().m22()/200;

      updatePointSizes(QRect(-1,0,0,0));
      update(rect());
    }
  }
}

void GraphWidget::zoomIn(QRectF r)
{
  zoomStr = QString("zoom={%1, %2, %3, %4}").arg(QVariant(r.left()).toString(),
    QVariant(r.top()).toString(),
    QVariant(r.width()).toString(),
    QVariant(r.height()).toString());
  setArea(r);
  showGrid(graphicsScene->gridVisible);
}

void GraphWidget::setHold(bool b)
{
  hold = b;
  emit holdSet(b);
}

void GraphWidget::clear()
{
  delete graphicsItems;
  graphicsItems = new QGraphicsItemGroup;

  foreach(Curve* c, curves)
  {
    qDeleteAll(c->dataPoints.begin(), c->dataPoints.end());
    delete c;
  }
  curves.clear();

  for(map<QString, VariableData*>::iterator i = variables.begin(); i != variables.end(); ++i)
    delete i->second;
  variables.clear();

  legendFrame->update();
  graphicsScene->update();

}

qreal GraphWidget::gridDist(qreal &min, qreal &max, qreal dist)
{
  qreal distance;
  if(dist < 0)
  {
    distance = (max - min) / 10.;
    qreal tmp = distance;
    while(tmp < 1)  tmp *= 10;
    while(tmp > 10) tmp /= 10;

    if(tmp > 5)
      distance = 10*distance/tmp;
    else if(tmp > 2)
      distance = 5*distance/tmp;
    else if(tmp > 1)
      distance = 2*distance/tmp;
    else
      distance /= tmp;
  }
  else
    distance = dist;

  min = ceil(min/distance)*distance;
  max = floor(max/distance)*distance;

  return distance;
}

void GraphWidget::createGrid(bool numbersOnly)
{
  QRectF scene = graphicsScene->sceneRect();
  graphicsScene->xRulerScene->setSceneRect(0, 0, 1, 1);
  graphicsScene->yRulerScene->setSceneRect(0, 0, 1, 1);

  qreal xMin, xMax, yMin, yMax;

  QRectF r = mapToScene(rect()).boundingRect();

  xMin = r.x();
  xMax = r.x() + r.width();

  yMin = r.top();
  yMax = r.top() + r.height();

  if(fixedXSize)
  {
    gridDist(xMin, xMax, xMajorDist);
  }
  else
  {
    xMajorDist = gridDist(xMin, xMax);
    xMinorDist = xMajorDist/2;
  }

  if(fixedYSize)
  {
    gridDist(yMin, yMax, yMajorDist);
  }
  else
  {
    yMajorDist = gridDist(yMin, yMax);
    yMinorDist = yMajorDist/2;
  }

  if(!numbersOnly)
  {
    delete graphicsScene->grid;
    graphicsScene->grid = new QGraphicsItemGroup;
  }

  foreach(QGraphicsItem* ti, graphicsScene->xRulerScene->items())
    delete ti;

  QPen pen(Qt::lightGray);
  QPen pen2(pen); // Qt::darkGray);

  double xMin2, xMax2, yMin2, yMax2;

  if(xLog )
  {
    xMin = floor(xMin);
    xMax = ceil(xMax);

    xMin2 = xMin-xMajorDist;
    xMax2 = xMax + xMajorDist;
  }
  else
  {
    xMin2 = xMin-xMajorDist;
    xMax2 = xMax + xMajorDist;
  }

  if(yLog )
  {
    yMin = floor(yMin);
    yMax = ceil(yMax);

    yMin2 = yMin-yMajorDist;
    yMax2 = yMax + yMajorDist;
  }
  else
  {
    yMin2 = yMin-yMajorDist;
    yMax2 = yMax + yMajorDist;
  }

  if(xLog) /// x start
  {
    for(double x = xMin; x <= xMax; ++x)
    {
      if(!numbersOnly)
      {
        Line2D* l = new Line2D(x,yMin2, x, yMax2, pen2);
        l->setZValue(-2);
        graphicsScene->grid->addToGroup(l);

        for(int i = 2; i < 10; ++i)
        {
          double x2 = x +log10(double(i));
          l = new Line2D(x2, yMin2, x2, yMax2, pen);
          l->setZValue(-2);
          graphicsScene->grid->addToGroup(l);
        }
      }

      QGraphicsTextItem* tmp2 = graphicsScene->xRulerScene->addText("1e" + QVariant(x).toString());
      tmp2->setPos(gvBottom->mapToScene(mapFromScene(x, yMax)).x()-tmp2->boundingRect().width()/2, 
                   gvBottom->sceneRect().y());
      tmp2->moveBy(0, -tmp2->boundingRect().height()/2.);

      if(tmp2->x() < gvBottom->mapToScene(gvBottom->rect()).boundingRect().x() ||
        tmp2->x() + tmp2->boundingRect().width() > 
        gvBottom->mapToScene(gvBottom->rect()).boundingRect().x() +
        gvBottom->mapToScene(gvBottom->rect()).boundingRect().width())
        tmp2->hide();
      else
        tmp2->show();
    }
  }
  else
  {
    if(!numbersOnly)
    {
      for(qreal x = xMin-xMajorDist; x < 1.5* xMajorDist + xMax; x+= xMinorDist)
      {
        Line2D* l = new Line2D(x, yMin2, x,  yMax2, pen);
        l->setZValue(-2);
        graphicsScene->grid->addToGroup(l);
      }
    }

    for(qreal x = xMin-xMajorDist; x < 1.5* xMajorDist + xMax; x+= xMajorDist)
    {
      if(!numbersOnly)
      {
        Line2D* l = new Line2D(x, yMin2, x,  yMax2, pen2);
        graphicsScene->grid->addToGroup(l);
      }
      QGraphicsTextItem* tmp2 = graphicsScene->xRulerScene->addText(QVariant(x).toString());
      if(abs(x) < xMinorDist)
      {
        tmp2->setPlainText("0");
        x = 0;
      }
      tmp2->setPos(gvBottom->mapToScene(mapFromScene(x, yMax)).x()-tmp2->boundingRect().width()/2, 
                   gvBottom->sceneRect().y());
      tmp2->moveBy(0, -tmp2->boundingRect().height()/2.);

      if(tmp2->x() < gvBottom->mapToScene(gvBottom->rect()).boundingRect().x() ||
        tmp2->x() + tmp2->boundingRect().width() > 
        gvBottom->mapToScene(gvBottom->rect()).boundingRect().x() +
        gvBottom->mapToScene(gvBottom->rect()).boundingRect().width())
        tmp2->hide();
      else
        tmp2->show();
    }

  } // x klar

  foreach(QGraphicsItem* ti, graphicsScene->yRulerScene->items())
    delete ti;

  qreal width=0;

  gvLeft->setMatrix(QMatrix(1, 0,0,-1,0,0));

  if(yLog)  // y start
  {
    for(double y = yMin-1; y <= yMax; ++y)
    {
      if(!numbersOnly)
      {
        Line2D* l = new Line2D(xMin2,y, xMax2, y, pen2);
        l->setZValue(-2);
        graphicsScene->grid->addToGroup(l);

        for(int i = 2; i < 10; ++i)
        {
          double y2 = y +log10(double(i));
          l = new Line2D(xMin2,y2, xMax2, y2, pen);
          l->setZValue(-2);
          graphicsScene->grid->addToGroup(l);
        }
      }
      QGraphicsTextItem* tmp2 = graphicsScene->yRulerScene->addText(QString("1e") +QVariant(y).toString());

      tmp2->setPos(gvLeft->mapToScene( gvLeft->sceneRect().x(),
                   mapFromScene(xMax, y).y()+tmp2->boundingRect().height()/2 ));
      tmp2->scale(1, -1);
      tmp2->moveBy(0, tmp2->boundingRect().height());

      tmp2->moveBy(gvLeft->width()-tmp2->boundingRect().width(),0);

      if(width < tmp2->boundingRect().width())
        width = tmp2->boundingRect().width();
      if(tmp2->y() > tmp2->boundingRect().height() + gvLeft->mapToScene(QPoint(gvLeft->x(), gvLeft->y())).y() ||
        tmp2->y() < gvLeft->mapToScene(QPoint(0, gvLeft->y() +gvLeft->height() )).y() +tmp2->boundingRect().height() ||
        tmp2->y()-1.5*tmp2->boundingRect().height() < gvLeft->mapToScene(QPoint(0, gvLeft->y()+gvLeft->height() )).y())
        tmp2->hide();
    }
  }
  else
  {
    if(!numbersOnly)
    {
      for(qreal y = yMin-yMajorDist; y < 1.5* yMajorDist + yMax ; y+= yMinorDist)
      {
        Line2D* l = new Line2D(xMin2, y, xMax2, y, pen);
        l->setZValue(-2);
        graphicsScene->grid->addToGroup(l);
      }
    }
    for(qreal y = yMin-yMajorDist; y < 1.5* yMajorDist + yMax ; y+= yMajorDist)
    {
      if(!numbersOnly)
      {
        graphicsScene->grid->addToGroup(new Line2D(xMin2, y, xMax2, y, pen2));
      }
      QGraphicsTextItem* tmp2 = graphicsScene->yRulerScene->addText(QVariant(y).toString());
      if(abs(y) < yMinorDist)
      {
        tmp2->setPlainText("0");
        y = 0;
      }
      tmp2->setPos(gvLeft->mapToScene( gvLeft->sceneRect().x(),
                   mapFromScene(xMax, y).y()+tmp2->boundingRect().height()/2 ));

      tmp2->scale(1, -1);
      tmp2->moveBy(0, tmp2->boundingRect().height());

      tmp2->moveBy(gvLeft->width()-tmp2->boundingRect().width(),0);

      if(width < tmp2->boundingRect().width())
        width = tmp2->boundingRect().width();

      if(tmp2->y() > tmp2->boundingRect().height() + gvLeft->mapToScene(QPoint(gvLeft->x(), gvLeft->y())).y() ||
        tmp2->y() < gvLeft->mapToScene(QPoint(0, gvLeft->y() +gvLeft->height() )).y() +tmp2->boundingRect().height() ||
        tmp2->y()-1.5*tmp2->boundingRect().height() < gvLeft->mapToScene(QPoint(0, gvLeft->y()+gvLeft->height() )).y())
        tmp2->hide();
    }
  } ////// y klar

  if(width != gvLeft->width())
    emit resizeY(width);
  if(!numbersOnly)
  {
    graphicsScene->grid->setZValue(-1);
    graphicsScene->addItem(graphicsScene->grid);
  }
  graphicsScene->update(currentArea());

  gvLeft->update();
  gvBottom->update();
}

void GraphWidget::paintEvent(QPaintEvent *pe)
{
  if(currentArea() != mapToScene(rect()).boundingRect())
  {
    if(doFitInView)
    {
      setArea(currentArea());
      bool visible;
      if(visible = graphicsScene->gridVisible)
      {
        showGrid(false);
      }
      graphicsScene->setSceneRect(graphicsScene->itemsBoundingRect());
      graphicsScene->gridVisible = visible;
      doFitInView = false;
    }
    else if(doSetArea)
    {
      originalZoom();
      setArea(newRect); // fjass
      // setArea(QRectF(10,-5,5,5));
      doSetArea = false;
    }
    else
      setCurrentArea(mapToScene(this->rect()).boundingRect());

    showGrid(graphicsScene->gridVisible); //fjass
    updatePointSizes();
  }
  QGraphicsView::paintEvent(pe);
}

void GraphWidget::setAntiAliasing(bool on)
{
  if(on)
    aAStr = QString("antiAliasing=true");
  else
    aAStr = "";
  antiAliasing = on;
  setRenderHint(QPainter::Antialiasing, on);
}

void GraphWidget::updateGrid()
{
  showGrid(gridVisible); //uu
}

void GraphWidget::showEvent(QShowEvent* event)
{
  QGraphicsView::showEvent(event);
  setArea(originalArea);
}

void GraphWidget::setArea(const QRectF& r)
{
  QRectF current = graphicsScene->sceneRect();

  if(r.left() < current.left())
    current.setLeft(r.left());
  if(r.right() > current.right())
    current.setRight(r.right());

  if(r.top() < current.top())
    current.setTop(r.top());
  if(r.bottom() > current.bottom())
    current.setBottom(r.bottom());

  graphicsScene->setSceneRect(current);
  setSceneRect(current);

  fitInView(r); //uu

  setCurrentArea(mapToScene(rect()).boundingRect());
  update(rect());
}

void GraphWidget::showGrid(bool b)
{
  emit setGridVisible(b);

  if(b)
  {
    if(graphicsScene->gridVisible)
    {
      graphicsScene->gridVisible=false;
      delete graphicsScene->grid;
    }

    setSceneRect(graphicsScene->sceneRect());
    graphicsScene->grid = new QGraphicsItemGroup(0, graphicsScene);
    createGrid();
    graphicsScene->gridVisible = true;
  }
  else
  {
    if(graphicsScene->gridVisible)
    {
      delete graphicsScene->grid;
      graphicsScene->grid = 0;
    }
    graphicsScene->gridVisible = false;
  }
  if(b)
    gridStr = QString("grid=true");
  else
    gridStr = "";
}

QColor GraphWidget::generateColor(int index)
{
  switch(index)
  {
  case 0:
    return Qt::red;
  case 1:
    return Qt::blue;
  case 2:
    return Qt::green;
  case 3:
    return Qt::magenta;
  case 4:
    return Qt::cyan;
  case 5:
    return Qt::yellow;
  case 6:
    return Qt::black;
  default:
    return QColor(rand()%255, rand()%255, rand()%255);
  }
}

void GraphWidget::drawLine(QDataStream& ds)
{
  emit showGraphics();
  QColor color, fillColor;
  qreal x0, y0, x1, y1;
  ds >> x0 >> y0 >> x1 >> y1 >> color >> fillColor;

  QPen pen(color);
  pen.setWidth(PLOT_LINE_WIDTH);
  pen.setCosmetic(true);
  QBrush brush(fillColor);

  QGraphicsLineItem *e = new QGraphicsLineItem(x0, y0, x1, y1);

  e->setPen(pen);
  // e->setBrush(brush);

  graphicsItems->addToGroup(e);
  graphicsScene->addItem(graphicsItems);

  // graphicsItems->addToGroup(graphicsScene->addLine(QLineF(x0, y0, x1, y1), pen));
  update(x0, y0, x1-x1, y1-y0);
}

void GraphWidget::setHold(QDataStream& ds)
{
  int status;
  ds >> status;
  setHold(status);
}

void GraphWidget::drawPoint(QDataStream& ds)
{
  emit showGraphics();
}

void GraphWidget::drawText(QDataStream& ds)
{
  emit showGraphics();
  QString str;
  qreal x, y;
  ds >> x >> y >>str;
  QGraphicsTextItem* t = graphicsScene->addText(str);
  graphicsItems->addToGroup(t);
  t->setPos(x, y);
}

void GraphWidget::drawRect(QDataStream& ds)
{
  emit showGraphics();
  QColor color, fillColor;
  qreal x0, y0, x1, y1;
  ds >> x0 >> y0 >> x1 >> y1 >> color >> fillColor;
  QPen pen(color);
  pen.setWidth(PLOT_LINE_WIDTH);
  pen.setCosmetic(true);
  QBrush brush(fillColor);
  // graphicsItems->addToGroup(graphicsScene->addRect(QRectF(QPointF(x0,y0), QSizeF(x1-x0, y1-y0)), pen, brush));
  QGraphicsRectItem *e = new QGraphicsRectItem(QRectF(QPointF(x0, y0), QSizeF(x1-x0, y1-y0)));
  e->setPen(pen);
  e->setBrush(brush);
  graphicsItems->addToGroup(e);
  graphicsScene->addItem(graphicsItems);
  update(x0, y0, x1-x1, y1-y0);
}

void GraphWidget::drawEllipse(QDataStream& ds)
{
  emit showGraphics();
  QColor color, fillColor;
  qreal x0, y0, x1, y1;
  ds >> x0 >> y0 >> x1 >> y1 >> color >> fillColor;
  QPen pen(color);
  pen.setWidth(PLOT_LINE_WIDTH);
  pen.setCosmetic(true);
  QBrush brush(fillColor);
  QGraphicsEllipseItem *e = new QGraphicsEllipseItem(QRectF(QPointF(x0, y0), QSizeF(x1-x0, y1-y0)));
  e->setPen(pen);
  e->setBrush(brush);
  graphicsItems->addToGroup(e);
  graphicsScene->addItem(graphicsItems);
  // graphicsItems->addToGroup(graphicsScene->addEllipse(QRectF(QPointF(x0, y0), QSizeF(x1-x0, y1-y0)), pen, brush));
  update(x0, y0, x1-x1, y1-y0);
}

/*
void GraphWidget::plotPtolemyData(QDataStream& ds_)
{
QString d;
ds_ >> d;
QTextStream ds(&d);

QString tmp;
VariableData *var1, *var2;
var1 = new VariableData(QString("ptX"));

while(!ds.atEnd())
{
do
{
if(ds.atEnd())
break;

tmp = ds.readLine().trimmed();
}
while(tmp.size() == 0);

if(tmp.trimmed().size() == 0)
break;

variables[var1->variableName()] = var1;

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
var2 = new VariableData(tmp.section(": ", 1, 1));
if(variables.find(var2->variableName()) != variables.end())
delete variables[var2->variableName()];

variables[var2->variableName()] = var2;
var1->clear();

}
else
{
*var1 << tmp.section(',', 0, 0).toDouble();
*var2 << tmp.section(',', 1, 1).toDouble();

}

}


DataSelect* dataSelect = new DataSelect(this);

QString xVar, yVar;
QStringList variableNames;

for(map<QString, VariableData*>::iterator i = variables.begin(); i != variables.end(); ++i)
variableNames <<i->first;

variableNames.sort();

if(!dataSelect->getVariables(variableNames, xVar, yVar))
return;

plotVariables(xVar, yVar);
}
*/

void GraphWidget::readPtolemyDataStream()
{
  QDataStream ds(activeSocket);
  ds.setVersion(QDataStream::Qt_4_2);

  QString tmp;
  double d;

  do
  {
    if(packetSize == 0)
    {
      if(ds.device()->bytesAvailable() >= sizeof(quint32))
        ds >> packetSize;
      else
        return;
    }

    if(ds.device()->bytesAvailable() < packetSize)
      return;

    if(variableCount == 0)
    {
      ds >> tmp;
      ds >> variableCount;
      getNames = true;
      packetSize = 0;
      continue;
    }
    for(quint32 i = 0; i < variableCount; ++i)
    {
      ds >> tmp;
      ds >> d;

      if(getNames)
      {
        if(variables.find(tmp) != variables.end())
          delete variables[tmp];
        variables[tmp] = new VariableData(tmp);
      }
      variables[tmp]->push_back(d);
    }

    getNames = false;
    packetSize = 0;
  }
  while(activeSocket->bytesAvailable() >= sizeof(quint32));
}

void GraphWidget::graphicsStreamClosed()
{
  if(graphicsSocket)
    graphicsSocket->disconnectFromHost();

  setServerState(false, true);
}

void GraphWidget::ptolemyDataStreamClosed()
{
  // cerr << "tempCurves size: " << temporaryCurves.size() << endl;
  for(map<QString, Curve*>::iterator i = temporaryCurves.begin(); i != temporaryCurves.end(); ++i)
  {
    curves.append(i->second);
    graphicsScene->addItem(i->second->line);
  }
  // cerr << "variables size: " << variables.size() << endl;
  // clear the variable data!
  variableData.clear();
  for(map<QString, VariableData*>::iterator i = variables.begin(); i != variables.end(); ++i)
    variableData.append(i->second);

  bool b = graphicsScene->gridVisible;

  if(b)
    showGrid(false);

  if(range.width() == 0)
  {
    range.setLeft(graphicsScene->itemsBoundingRect().left());
    range.setWidth(graphicsScene->itemsBoundingRect().width());
  }
  if(range.height() == 0)
  {
    range.setTop(graphicsScene->itemsBoundingRect().top());
    range.setHeight(graphicsScene->itemsBoundingRect().height());
  }

  setArea(range);
  updatePointSizes();
  showGrid(b);

  emit newMessage("Connection closed");
}

void GraphWidget::setLogarithmic(bool b)
{
  bool truncated = false;

  for(int i = 0; i < curves.size(); ++i)
  {
    delete curves[i]->line;
    curves[i]->line = new QGraphicsItemGroup;

    foreach(Point* p, curves[i]->dataPoints)
      delete p;
    curves[i]->dataPoints.clear();

    double x0, x1, y0, y1;
    double x0_, x1_, y0_, y1_;

    int index = 0;
    for(; index < curves[i]->x->size(); ++index)
    {
      x1 = x1_ = (*curves[i]->x)[index];
      y1 = y1_ = (*curves[i]->y)[index];

      if((yLog && y1 <= 0) || (xLog && x1 <= 0))
      {
        truncated = true;
        continue;
      }
      break;
    }

    if(xLog)
      x1 = log10(x1_);
    if(yLog)
      y1 = log10(y1_);

    bool C = false;
    bool drawNextPoint = true;

    for(int j = index; j < curves[i]->x->size(); ++j, C = false)
    {
      x0 = x1; x0_= x1_;  x1 = x1_ = (*curves[i]->x)[j];
      y0 = y1; y0_ = y1_; y1 = y1_ = (*curves[i]->y)[j];

      if(xLog)
      {
        if(x1_ > 0)
        {
          x1 = log10(x1_);
          if(x0_ <= 0)
            C = true;
        }
        else
          C = true;
      }

      if(yLog)
      {
        if(y1_ > 0)
        {
          y1 = log10(y1_);
          if(y0_ <= 0)
            C = true;
        }
        else
          C = true;
      }

      QPen pen(curves[i]->color_);
      pen.setWidth(PLOT_LINE_WIDTH);
      pen.setCosmetic(true);

      if(!C || drawNextPoint)
      {
        Point* p = new Point(x0, y0, .02, .02, pen.color(), this,0, graphicsScene,
          curves[i]->x->variableName() + ": " + QVariant(x0_).toString() +"\n" +
          curves[i]->y->variableName() + ": " + QVariant(y0_).toString());
        curves[i]->dataPoints.append(p);
        p->setVisible(curves[i]->drawPoints);
        drawNextPoint = !C;
      }

      if(C)
      {
        truncated = true;
        continue;
      }
      else
        drawNextPoint = true;

      if(curves[i]->interpolation == INTERPOLATION_LINEAR)
      {
        Line2D* l = new Line2D(x0, y0, x1, y1,pen, PLOT_LINE_WIDTH, true);
        curves[i]->line->addToGroup(l);
      }
      else if(curves[i]->interpolation == INTERPOLATION_CONSTANT)
      {
        Line2D* l = new Line2D(x0, y0,x1, y0, pen, PLOT_LINE_WIDTH, true);
        curves[i]->line->addToGroup(l);
        l = new Line2D(x1, y0,x1, y1, pen, PLOT_LINE_WIDTH, true);
        curves[i]->line->addToGroup(l);
      }
    }

    if(!C)
    {
      QPen pen(curves[i]->color_);
      pen.setWidth(PLOT_LINE_WIDTH);
      pen.setCosmetic(true);
      Point* p = new Point(x1, y1, .02, .02, pen.color(), this,0, graphicsScene,
        curves[i]->x->variableName() + ": " + QVariant(x1_).toString() +"\n" +
        curves[i]->y->variableName() + ": " + QVariant(y1_).toString());
      curves[i]->dataPoints.append(p);
      p->setVisible(curves[i]->drawPoints);

    }

    curves[i]->line->setVisible(curves[i]->visible);
    graphicsScene->addItem(curves[i]->line);

    doFitInView = true;

    if(truncated)
      QMessageBox::information(0, "Truncated data", "The data has been truncated to allow logarithmic scaling.");
  }
}

void GraphWidget::drawGraphics()
{
  QString commandV, command, version;

  do
  {
    if(packetSize2 == 0)
    {
      if(ds2.device()->bytesAvailable() >= sizeof(quint32))
        ds2 >> packetSize2;
      else
        return;
    }

    if(ds2.device()->bytesAvailable() < packetSize2)
      return;

    ds2 >> commandV;
    command = commandV.section("-", 0, 0);
    version = commandV.section("-", 1, 1);

    if(command == QString("drawEllipse"))
      drawEllipse(ds2);
    else if(command == QString("drawLine"))
      drawLine(ds2);
    else if(command == QString("drawRect"))
      drawRect(ds2);
    else if(command == QString("drawText"))
      drawText(ds2);
    else if(command == QString("hold"))
      setHold(ds2);
    else if(command == QString("closeServer"))
    {
      setServerState(false);
      setServerState(false, true);
      activeSocket->disconnect();
      activeSocket->disconnectFromHost();
      graphicsSocket->disconnect();
      graphicsSocket->disconnectFromHost();
    }
    packetSize2 = 0;
  }
  while(graphicsSocket->bytesAvailable() >= sizeof(quint32));
}

void GraphWidget::plotPtolemyDataStream()
{
  emit showGraphics();
  QString tmp;
  QColor color = QColor(Qt::color0);
  double d;
  quint32 it = 0;

  do
  {
    if(packetSize == 0)
    {
      if(ds.device()->bytesAvailable() >= sizeof(quint32))
        ds >> packetSize;
      else
        return;
    }

    if(ds.device()->bytesAvailable() < packetSize)
      return;

    if(variableCount == 0)
    {
      variables.clear();
      temporaryCurves.clear();
      QString title, xLabel, yLabel;
      ds >> title;
      ds >> xLabel;
      ds >> yLabel;
      compoundwidget->plotTitle->setText(title);
      compoundwidget->xLabel->setText(xLabel);
      compoundwidget->yLabel->setText(yLabel);
      int legend, grid;
      ds >> legend >> grid;
      compoundwidget->legendFrame->setVisible(legend);
      showGrid(grid);
      double xmin, xmax, ymin, ymax;

      if(dataStreamVersion < 1.2) ds >> xmin >> xmax >> ymin >> ymax;

      int logX, logY;
      ds >> logX >> logY;
      QString interpolation;
      ds >> interpolation;
      int points;
      ds >> points;

      if(dataStreamVersion >= 1.1)
      {
        QString range_; 
        ds >> range_; //fjass
        range.setLeft(QVariant(range_.section(QRegExp("[{,\\s}]+"), 1,1)).toDouble());
        range.setRight(QVariant(range_.section(QRegExp("[{,\\s}]+"), 2,2)).toDouble());
        range.setTop(QVariant(range_.section(QRegExp("[{,\\s}]+"), 3,3)).toDouble());
        range.setBottom(QVariant(range_.section(QRegExp("[{,\\s}]+"), 4,4)).toDouble());
      }
      else
        range.setRect(0,0,0,0);

      yVars.clear();
      ds >> variableCount;

      LegendLabel* ll;

      legendFrame->setMinimumWidth(0);

      for(quint32 i = 0; i < variableCount; ++i)
      {
        ds >> tmp;
        ds >> color;
        if(color == Qt::color0)
        {
          int colorInt = curves.size() - 1 + variables.size();
          // cerr << "graphWidget.plorPtolemyDataStream: setting color: " << colorInt << endl;
          color = generateColor(colorInt);
        }
        tmp = tmp.trimmed();
        if(variables.find(tmp) != variables.end())
          delete variables[tmp];
        variables[tmp] = new VariableData(tmp, color);

        if(i == 0)
          currentXVar = tmp;
        else
        {
          if(yVars.indexOf(tmp) == -1)
          {
            int interpolation_;

            if(interpolation == QString("constant"))
              interpolation_ = INTERPOLATION_CONSTANT;
            else if(interpolation == QString("linear"))
              interpolation_ = INTERPOLATION_LINEAR;
            else
              interpolation_ = INTERPOLATION_NONE;


            yVars.push_back(tmp);
            ll = new LegendLabel(color, tmp,legendFrame, !(interpolation_ == INTERPOLATION_NONE), points, 12);
            ll->graphWidget = this;
            legendFrame->setMinimumWidth(max(ll->fontMetrics().width(tmp)+41+4, legendFrame->minimumWidth()));
            legendLayout->addWidget(ll);
            ll->show();

            temporaryCurves[tmp] = (new Curve(variables[currentXVar], variables[tmp], color, ll));
            ll->setCurve(temporaryCurves[tmp]);

            temporaryCurves[tmp]->drawPoints = points;
            temporaryCurves[tmp]->interpolation = interpolation_;

          }
        }
      }
      packetSize = 0;
      continue;
    }

    ds >> variableCount;
    for(quint32 i = 0; i < variableCount; ++i)
    {
      ds >> tmp;
      ds >> d;
      variables[tmp]->push_back(d);
    }

    double y0, y1, x0, x1;
    double y0_, y1_, x0_, x1_;
    QPen color;

    for(quint32 k=0; k < quint32(yVars.size()); ++k)
    {
      currentYVar=yVars[k];
      color = temporaryCurves[currentYVar]->color_;
      color.setWidth(PLOT_LINE_WIDTH);
      color.setCosmetic(true);

      int maxIndex = min(variables[currentXVar]->size()-1, variables[currentYVar]->size()-1);

      if(int(variables[currentYVar]->currentIndex) < maxIndex)
      {
        int i = int(variables[currentYVar]->currentIndex);
        bool truncated = false;
        while(i < maxIndex)
        {
          x1=x1_ = (*variables[currentXVar])[i];
          y1=y1_ = (*variables[currentYVar])[i];
          if((yLog && y1 <= 0) || (xLog && x1 <= 0))
          {
            truncated = true;
            ++i;
            continue;
          }
          break;
        }

        if(xLog)
          x1=log10(x1_);
        if(yLog)
          y1 = log10(y1_);
        ++i;

        for(; i <= maxIndex; ++i)
        {
          variables[currentYVar]->currentIndex++;

          x0_ = x1_;
          x0 = x1;
          y0_ = y1_;
          y0 = y1;

          x1 =x1_ = (*variables[currentXVar])[i];
          y1= y1_ = (*variables[currentYVar])[i];

          bool C = false;

          if(xLog)
          {
            if(x1_ > 0)
            {
              x1 = log10(x1_);
              if(x0_ <= 0)
                C = true;
            }
            else
              C = true;
          }

          if(yLog)
          {
            if(y1_ > 0)
            {
              y1 = log10(y1_);
              if(y0_ <= 0)
                C = true;
            }
            else
              C = true;
          }

          if(C)
          {
            truncated = true;
            continue;
          }

          if(temporaryCurves[currentYVar]->interpolation == INTERPOLATION_LINEAR)
          {
            Line2D* l = new Line2D(x0, y0, x1, y1,color, PLOT_LINE_WIDTH, true);
            temporaryCurves[currentYVar]->line->addToGroup(l);
            l->show();
          }
          else if(temporaryCurves[currentYVar]->interpolation == INTERPOLATION_CONSTANT)
          {
            Line2D* l = new Line2D(x0, y0,x1,y0,color, PLOT_LINE_WIDTH, true);
            temporaryCurves[currentYVar]->line->addToGroup(l);
            l = new Line2D(x1, y0,x1,y1,color, PLOT_LINE_WIDTH, true);
            temporaryCurves[currentYVar]->line->addToGroup(l);
          }
          else if(temporaryCurves[currentYVar]->interpolation == INTERPOLATION_NONE)
          {
            Line2D* l = new Line2D(x0, y0, x1, y1,color, PLOT_LINE_WIDTH, true);
            l->setVisible(false);
            temporaryCurves[currentYVar]->line->addToGroup(l);
          }

          Point* p = new Point(x0, y0, .02, .02, color.color(), this,0, graphicsScene);
          p->setVisible(temporaryCurves[currentYVar]->drawPoints);
          temporaryCurves[currentYVar]->dataPoints.append(p);
        }

        //The last point
        Point* p = new Point(x1, y1, .02, .02, color.color(), this,0, graphicsScene);
        p->setVisible(temporaryCurves[currentYVar]->drawPoints);
        temporaryCurves[currentYVar]->dataPoints.append(p);
      }
    }

    packetSize = 0;
    ++it;
  }
  while(activeSocket->bytesAvailable() >= sizeof(quint32));

  if(activeSocket->state() != QAbstractSocket::ConnectedState)
    ptolemyDataStreamClosed();
}

void GraphWidget::receiveDataStream()
{

  emit showGraphics();
  QString tmp;
  QColor color = QColor(Qt::color0);
  double d;
  quint32 it = 0;

  bool visible;
  visible = graphicsScene->gridVisible;
  // hide grid so otherwise the bounding rectangle will be wrong.
  showGrid(false);

  do
  {
    if(packetSize == 0)
    {
      if(ds.device()->bytesAvailable() >= sizeof(quint32))
        ds >> packetSize;
      else
        return;
    }

    if(ds.device()->bytesAvailable() < packetSize)
      return;

    if(variableCount == 0)
    {
      variables.clear();
      temporaryCurves.clear();
      QString title("Plot by OpenModelica"), xLabel("time"), yLabel("y");
      compoundwidget->plotTitle->setText(title);
      compoundwidget->xLabel->setText(xLabel);
      compoundwidget->yLabel->setText(yLabel);
      compoundwidget->legendFrame->setVisible(true);
      int points = 0; // not show points
      range.setRect(0,0,0,0);
      yVars.clear();
      ds >> variableCount;
      LegendLabel* ll;
      legendFrame->setMinimumWidth(0);

      for(quint32 i = 0; i < variableCount; ++i)
      {
        ds >> tmp;
        int colorInt = curves.size() - 1 + variables.size();
        color = generateColor(colorInt);
        tmp = tmp.trimmed();
        if(variables.find(tmp) != variables.end())
          delete variables[tmp];
        variables[tmp] = new VariableData(tmp, color);

        if(i == 0)
          currentXVar = tmp;
        else
        {
          if(yVars.indexOf(tmp) == -1)
          {
            int interpolation_ = INTERPOLATION_LINEAR;

            yVars.push_back(tmp);
            ll = new LegendLabel(color, tmp,legendFrame, !(interpolation_ == INTERPOLATION_NONE), points, 12);
            ll->graphWidget = this;
            legendFrame->setMinimumWidth(max(ll->fontMetrics().width(tmp)+41+4, legendFrame->minimumWidth()));
            legendLayout->addWidget(ll);
            ll->show();

            temporaryCurves[tmp] = (new Curve(variables[currentXVar], variables[tmp], color, ll));
            ll->setCurve(temporaryCurves[tmp]);

            temporaryCurves[tmp]->drawPoints = points;
            temporaryCurves[tmp]->interpolation = interpolation_;
          }
        }
      }
      packetSize = 0;
      continue;
    }

    for(quint32 i = 0; i < variableCount; ++i)
    {
      ds >> tmp;
      ds >> d;
      variables[tmp]->push_back(d);
    }

    double y0, y1, x0, x1;
    double y0_, y1_, x0_, x1_;
    QPen color;

    for(quint32 k=0; k < quint32(yVars.size()); ++k)
    {
      currentYVar=yVars[k];
      color = temporaryCurves[currentYVar]->color_;
      color.setWidth(PLOT_LINE_WIDTH);
      color.setCosmetic(true);

      int maxIndex = min(variables[currentXVar]->size()-1, variables[currentYVar]->size()-1);

      if(int(variables[currentYVar]->currentIndex) < maxIndex)
      {
        int i = int(variables[currentYVar]->currentIndex);
        bool truncated = false;
        while(i < maxIndex)
        {
          x1=x1_ = (*variables[currentXVar])[i];
          y1=y1_ = (*variables[currentYVar])[i];
          break;
        }

        ++i;

        for(; i <= maxIndex; ++i)
        {
          variables[currentYVar]->currentIndex++;

          x0_ = x1_;
          x0 = x1;
          y0_ = y1_;
          y0 = y1;

          x1 =x1_ = (*variables[currentXVar])[i];
          y1= y1_ = (*variables[currentYVar])[i];

          if(temporaryCurves[currentYVar]->interpolation == INTERPOLATION_LINEAR)
          {
            Line2D* l = new Line2D(x0, y0, x1, y1,color, PLOT_LINE_WIDTH, true);
            temporaryCurves[currentYVar]->line->addToGroup(l);
            l->show();
			graphicsScene->addItem(l);
          }
          else if(temporaryCurves[currentYVar]->interpolation == INTERPOLATION_CONSTANT)
          {
            Line2D* l = new Line2D(x0, y0,x1,y0,color, PLOT_LINE_WIDTH, true);
			l->setVisible(true);
			graphicsScene->addItem(l);
            temporaryCurves[currentYVar]->line->addToGroup(l);
            l = new Line2D(x1, y0,x1,y1,color, PLOT_LINE_WIDTH, true);
			l->setVisible(true);
			graphicsScene->addItem(l);
            temporaryCurves[currentYVar]->line->addToGroup(l);
          }
          else if(temporaryCurves[currentYVar]->interpolation == INTERPOLATION_NONE)
          {
            Line2D* l = new Line2D(x0, y0, x1, y1,color, PLOT_LINE_WIDTH, true);
			graphicsScene->addItem(l);
            l->setVisible(true);
            temporaryCurves[currentYVar]->line->addToGroup(l);
          }

          // Point* p = new Point(x0, y0, .02, .02, color.color(), this, 0, graphicsScene);
          // p->setVisible(true);
          // temporaryCurves[currentYVar]->dataPoints.append(p);
        }

        // The last point
        Point* p = new Point(x1, y1, .02, .02, color.color(), this, 0, graphicsScene);
        p->setVisible(true);
        temporaryCurves[currentYVar]->dataPoints.append(p);
      }
    }

    packetSize = 0;
    ++it;

	graphicsScene->setSceneRect(graphicsScene->itemsBoundingRect());
    range = graphicsScene->sceneRect();
    setArea(graphicsScene->sceneRect());
	legendFrame->update();
    graphicsScene->update();
	update();
  }
  while(activeSocket->bytesAvailable() >= sizeof(quint32));

  if(activeSocket->state() != QAbstractSocket::ConnectedState)
    dataStreamClosed();
}

void GraphWidget::dataStreamClosed()
{
  emit showVariableButton(true);
  emit newMessage("Connection closed");

  // visible = graphicsScene->gridVisible;
  // showGrid(visible);

  // cerr << "tempCurves size: " << temporaryCurves.size() << endl;
  for(map<QString, Curve*>::iterator i = temporaryCurves.begin(); i != temporaryCurves.end(); ++i)
  {
	curves.append(i->second);
	graphicsScene->addItem(i->second->line);
  }
  // cerr << "variables size: " << variables.size() << endl;
  // clear the variable data!
  variableData.clear();
  for(map<QString, VariableData*>::iterator i = variables.begin(); i != variables.end(); ++i)
	variableData.append(i->second);

  bool b = graphicsScene->gridVisible;

  if (b) showGrid(false);

  if(range.width() == 0)
  {
	range.setLeft(graphicsScene->itemsBoundingRect().left());
	range.setWidth(graphicsScene->itemsBoundingRect().width());
  }
  if(range.height() == 0)
  {
	range.setTop(graphicsScene->itemsBoundingRect().top());
	range.setHeight(graphicsScene->itemsBoundingRect().height());
  }

  setArea(range);
  updatePointSizes();
  showGrid(b);
}

/*
void GraphWidget::saveImage()
{
//	this->setBackgroundBrush(QBrush(Qt::white));

//	graphicsScene->setBackgroundBrush(QBrush(Qt::white));

//	graphicsScene->setForegroundBrush(QBrush(Qt::red));

QGraphicsRectItem* r = new QGraphicsRectItem(mapToScene(rect()).boundingRect());
QBrush b(Qt::white);
r->setBrush(b);
r->setZValue(-100);
graphicsScene->addItem(r);

//	QImage qi(rect().size(),QImage::Format_RGB32);
QImage qi(rect().size().width()/2, rect().size().height(),QImage::Format_RGB32);
QPainter qp;

//	qp.setBackground(QBrush(Qt::white));

//	qp.setBackgroundMode( Qt::OpaqueMode);






qp.setRenderHints(renderHints(), true);
qp.begin(&qi);

render(&qp);

qp.end();
//	qi.save("u2.png", "PNG");

QByteArray ba;
QBuffer buffer(&ba);
buffer.open(QIODevice::WriteOnly);
qi.save(&buffer, "PNG");

QFile f("u.png");
f.open(QIODevice::WriteOnly);
f.write(ba);

f.close();

delete r;
}
*/

void GraphWidget::saveImage()
{

	QString filename = QFileDialog::getSaveFileName(this, "Export image", "untitled", "Portable Network Graphics (*.png);;Windows Bitmap (*.bmp);;Joint Photographic Experts Group (*.jpg)");

	if(!filename.size())
		return;

	QImage i3(compoundwidget->rect().size(),  QImage::Format_RGB32);

	i3.fill(QColor(Qt::white).rgb());
	QPainter p(&i3);
	QRectF target = QRectF(compoundwidget->gwMain->rect());
	target.moveTo(compoundwidget->gwMain->pos());
	compoundwidget->gwMain->render(&p, target);

	p.drawRect(target);

	target = QRectF(compoundwidget->gvLeft->rect());
	target.moveTo(compoundwidget->gvLeft->pos());
	compoundwidget->gvLeft->render(&p, target);

	target = QRectF(compoundwidget->gvBottom->rect());
	target.moveTo(compoundwidget->gvBottom->pos());
	compoundwidget->gvBottom->render(&p, target);

	compoundwidget->yLabel->render(&p, compoundwidget->yLabel->pos());
	compoundwidget->xLabel->render(&p, compoundwidget->xLabel->pos());
	compoundwidget->plotTitle->render(&p, compoundwidget->plotTitle->pos());


	QList<LegendLabel*> l = compoundwidget->legendFrame->findChildren<LegendLabel*>();
	for(int i = 0; i < l.size(); ++i)
		l[i]->render(&p, l[i]->pos()+compoundwidget->legendFrame->pos());


	if(filename.endsWith("png"))
		i3.save(filename, "PNG");
	else if(filename.endsWith("bmp"))
		i3.save(filename, "BMP");
	else if(filename.endsWith("jpg") || filename.endsWith("jpeg"))
		i3.save(filename, "JPG");
	else
		i3.save(filename+".bmp", "BMP");
}


void GraphWidget::exportToClipboard()
{

	QImage i3(compoundwidget->rect().size(),  QImage::Format_RGB32);

	i3.fill(QColor(Qt::white).rgb());
	QPainter p(&i3);
	QRectF target = QRectF(compoundwidget->gwMain->rect());
	target.moveTo(compoundwidget->gwMain->pos());
	compoundwidget->gwMain->render(&p, target);

	p.drawRect(target);

	target = QRectF(compoundwidget->gvLeft->rect());
	target.moveTo(compoundwidget->gvLeft->pos());
	compoundwidget->gvLeft->render(&p, target);

	target = QRectF(compoundwidget->gvBottom->rect());
	target.moveTo(compoundwidget->gvBottom->pos());
	compoundwidget->gvBottom->render(&p, target);

	compoundwidget->yLabel->render(&p, compoundwidget->yLabel->pos());
	compoundwidget->xLabel->render(&p, compoundwidget->xLabel->pos());
	compoundwidget->plotTitle->render(&p, compoundwidget->plotTitle->pos());


	QList<LegendLabel*> l = compoundwidget->legendFrame->findChildren<LegendLabel*>();
	for(int i = 0; i < l.size(); ++i)
		l[i]->render(&p, l[i]->pos()+compoundwidget->legendFrame->pos());

  QClipboard *clipboard = QApplication::clipboard();  
  clipboard->setImage(i3, QClipboard::Clipboard);
}
