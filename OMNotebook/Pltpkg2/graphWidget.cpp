/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet,
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

//Std headers
#include <fstream>
#include <iostream>
#include <cmath>
#include <cstdlib>
#include <cfloat>
#include <map>

//IAEX headers
#include "graphWidget.h"
#include "line2D.h"
#include "lineGroup.h"
#include "dataSelect.h"
#include "variableData.h"
#include "graphWindow.h"
#include "point.h"
#include "LegendLabel.h"
#include "curve.h"

using namespace std;

GraphWidget::GraphWidget(QWidget* parent): QGraphicsView(parent)
{
	tmpint = 0;

	graphicsScene = new GraphScene;
	setScene(graphicsScene);
	scale(1, -1);
	server = new QTcpServer(this);
	server->setMaxPendingConnections(500);
	nr = 0;
	activeSocket = 0;
	gridVisible = false;
	pan = false;
	stretch = true;

	xLog=yLog = false;
	useManualArea = false;
	fixedGrid = false;
	fixedXSize = false;
	fixedYSize = false;


	this->setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Expanding);
	this->setMinimumHeight(150);

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

	tmp = ag->addAction(contextMenu->addAction("Select"));
	connect(tmp, SIGNAL(toggled(bool)), this, SLOT(setSelect(bool)));

	tmp = ag->addAction(contextMenu->addAction("Zoom"));
	connect(tmp, SIGNAL(toggled(bool)), this, SLOT(setZoom(bool)));

	QAction* a;
	foreach(a, ag->actions())
		a->setCheckable(true);

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

	/*
	tmp=contextMenu->addAction("Save");
	connect(tmp, SIGNAL(triggered()), this, SLOT(saveImage()));
	contextMenu->addSeparator();
	*/
	tmp=contextMenu->addAction("New window");
	connect(tmp, SIGNAL(triggered()), this, SLOT(newWindow()));

	tmp=contextMenu->addAction("Preferences");
	connect(tmp, SIGNAL(triggered()), this, SLOT(showPreferences()));

	//	connect(this, SIGNAL(scrolled()), this, SLOT(updateGrid()));


	tmp = contextMenu->addAction("Antialiasing");
	tmp->setCheckable(true);
	connect(tmp, SIGNAL(toggled(bool)), this, SLOT(setAntiAliasing(bool)));

	graphicsItems = new QGraphicsItemGroup;
	dataPoints = new QList<Point*>;


	setContextMenuPolicy(Qt::ActionsContextMenu);
	addActions(contextMenu->actions());
	antiAliasing = false;
	doSetArea = false;
	doFitInView = false;
	hold = false;
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

	delete contextMenu;
	int nr = graphicsScene->views().count();
	if(nr <= 1)
		delete graphicsScene;

	qDeleteAll(curves);
	qDeleteAll(variableData);
}

void GraphWidget::setServerState(bool listen)
{
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
			if(!connect(server, SIGNAL(newConnection()), this, SLOT(acCon())))
				QMessageBox::critical(0, QString("fel!"), QString("fel"));
	}
	else
	{
		server->close();
		emit newMessage("Port closed");
		emit serverState(false);
	}
}

void GraphWidget::showPreferences()
{
	emit showPreferences2();
}

bool GraphWidget::getServerState()
{
	return server->isListening();
}
/*
void GraphWidget::plotVariables(const QString& xVar, const QString& yVar)
{
VariableData* X = variables[xVar];
VariableData* Y = variables[yVar];

/#
LineGroup* group = new LineGroup;
curves << group;

for(int i = 1; i < min(X->size(), Y->size()); ++i)
{
Line2D* l = new Line2D((*X)[i-1], (*Y)[i-1], (*X)[i], (*Y)[i]);
group->addToGroup(l);
}

graphicsScene->addItem(group);

fitInView(graphicsScene->sceneRect());
#/
}
*/

void GraphWidget::getData()
{
	disconnect(activeSocket, SIGNAL(readyRead()), 0, 0);

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

		//		cout << "getData" << ": " <<  QVariant(activeSocket->bytesAvailable()).toString().toStdString() << endl;

		if(command == QString("clear"))
			//		clear(in);
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
		}
		else if(command == QString("closeServer"))
		{
			setServerState(false);
			activeSocket->disconnect();
			activeSocket->disconnectFromHost();
		}
		//		else if(command == QString("testSocket"))
		//			;
		//		else if(command == QString("ptolemyData"))
		//			plotPtolemyData(ds);
		else if(command == QString("ptolemyDataStream"))
		{
			if(!hold)
				clear();

			emit newMessage("Recieving streaming data...");
			disconnect(activeSocket, SIGNAL(readyRead()), 0, 0);

			connect(activeSocket, SIGNAL(readyRead()), this, SLOT(plotPtolemyDataStream()));
			connect(activeSocket, SIGNAL(disconnected()), this, SLOT(ptolemyDataStreamClosed()));

			variableCount = 0;
			packetSize = 0;
			//			plotPtolemyDataStream();
			return;
		}

		blockSize = 0;
	}

	connect(activeSocket, SIGNAL(readyRead()), this, SLOT(getData()));
}

void GraphWidget::acCon()
{
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


void GraphWidget::updatePointSizes(QRect& r)
{
	if( r == QRect())
		r = rect();

	QList<QGraphicsItem*> g3 = items(rect());

	Point* p;

	double xScale = matrix().m11()/125;
	double yScale = -matrix().m22()/200;

	for(int i = 0; i < g3.size(); ++i)
	{
		if((p = dynamic_cast<Point*>(g3.at(i))))	
			//		if(p)
		{


			p->move(-.03/xScale/2., -.03/yScale/2.); 
			p->setRect(p->xPos, p->yPos, .03/xScale, .03 /yScale);
		}
	}
}

void GraphWidget::resetZoom()
{
	bool visible;
	if(visible = graphicsScene->gridVisible)
	{
		showGrid(false);
	}
	graphicsScene->setSceneRect(graphicsScene->itemsBoundingRect());
	setArea(graphicsScene->sceneRect());

	updatePointSizes();

	if(visible)
		showGrid(true);
}
void GraphWidget::mouseReleaseEvent ( QMouseEvent * event )
{
	QGraphicsView::mouseReleaseEvent(event);

	QPointF zoomStartF = mapToScene(zoomStart);
	QPointF zoomEnd = QPointF(mapToScene(event->pos()));

	if(zoom)
	{
		if(event->button() == Qt::LeftButton)
		{
			double left, right, top, bottom;

			if(zoomStartF.x() > zoomEnd.x())
			{
				left = 	zoomEnd.x();
				right = zoomStartF.x();
			}
			else
			{
				left = zoomStartF.x();
				right = zoomEnd.x();
			}

			if(zoomStartF.y() > zoomEnd.y())
			{
				bottom = 	zoomEnd.y();
				top = zoomStartF.y();
			}
			else
			{
				top = zoomStartF.y();
				bottom = zoomEnd.y();
			}

			bottom += mapToScene(0,0,0,this->horizontalScrollBar()->height()).boundingRect().height();
			right += mapToScene(0,0,this->verticalScrollBar()->width(), 0).boundingRect().width();

			fitInView(QRectF(left, bottom, right-left, top-bottom));

			double xScale = matrix().m11()/125;
			double yScale = -matrix().m22()/200;

			/*
			QList<QGraphicsItem*> g3 = items(rect());

			Point* p;

			for(int i = 0; i < g3.size(); ++i)
			{
			p = dynamic_cast<Point*>(g3.at(i));	

			if(p)
			{


			p->move(-.03/xScale/2., -.03/yScale/2.); 
			p->setRect(p->xPos, p->yPos, .03/xScale, .03 /yScale);
			}
			}
			*/
			updatePointSizes();
			update(rect());
		}
	}
}

void GraphWidget::zoomIn(QRectF r)
{
	setArea(r);

	if(graphicsScene->gridVisible)
		showGrid(true);
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

		while(tmp < 1)
			tmp *= 10;


		while(tmp > 10)
			tmp /= 10;


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

void GraphWidget::createGrid()
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
		xMinorDist = xMajorDist/5;
	}

	if(fixedYSize)
	{
		gridDist(yMin, yMax, yMajorDist);
	}
	else
	{
		yMajorDist = gridDist(yMin, yMax);
		yMinorDist = yMajorDist/5;
	}

	delete graphicsScene->grid;
	graphicsScene->grid = new QGraphicsItemGroup;

	foreach(QGraphicsItem* ti, graphicsScene->xRulerScene->items())
		delete ti;

	QPen pen(Qt::lightGray);	
	QPen pen2(Qt::darkGray);	

	double xMin2, xMax2, yMin2, yMax2;

	if(xLog )
	{
		xMin = floor(xMin);
		xMax = ceil(xMax);

		xMin2 =	xMin-xMajorDist;
		xMax2 = xMax + xMajorDist;
	}
	else
	{
		xMin2 =	xMin-xMajorDist;
		xMax2 = xMax + xMajorDist;
	}

	if(yLog )
	{
		yMin = floor(yMin);
		yMax = ceil(yMax);

		yMin2 =	yMin-yMajorDist;
		yMax2 = yMax + yMajorDist;
	}
	else
	{
		yMin2 =	yMin-yMajorDist;
		yMax2 = yMax + yMajorDist;
	}


	if(xLog) /// x start
	{
		for(double x = xMin; x <= xMax; ++x)
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

			QGraphicsTextItem* tmp2 = graphicsScene->xRulerScene->addText("1e" + QVariant(x).toString());
			tmp2->setPos(gvBottom->mapToScene(mapFromScene(x, yMax)).x()-tmp2->boundingRect().width()/2, gvBottom->sceneRect().y());
			tmp2->moveBy(0, -tmp2->boundingRect().height()/2.);
			tmp2->show();		
		}
	}
	else
	{
		for(qreal x = xMin-xMajorDist; x < 1.5* xMajorDist + xMax; x+= xMinorDist)	
		{
			Line2D* l = new Line2D(x, yMin2, x,  yMax2, pen);
			l->setZValue(-2);
			graphicsScene->grid->addToGroup(l);
		}

		for(qreal x = xMin-xMajorDist; x < 1.5* xMajorDist + xMax; x+= xMajorDist)	
		{
			Line2D* l = new Line2D(x, yMin2, x,  yMax2, pen2);
			graphicsScene->grid->addToGroup(l);

			QGraphicsTextItem* tmp2 = graphicsScene->xRulerScene->addText(QVariant(x).toString());
			tmp2->setPos(gvBottom->mapToScene(mapFromScene(x, yMax)).x()-tmp2->boundingRect().width()/2, gvBottom->sceneRect().y());
			tmp2->moveBy(0, -tmp2->boundingRect().height()/2.);
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

			QGraphicsTextItem* tmp2 = graphicsScene->yRulerScene->addText(QString("1e") +QVariant(y).toString());
			tmp2->setPos(gvLeft->mapToScene( gvLeft->sceneRect().x() ,mapFromScene(xMax, y).y()+tmp2->boundingRect().height()/2 ));

			tmp2->scale(1, -1);
			tmp2->moveBy(0, tmp2->boundingRect().height());

			tmp2->moveBy(gvLeft->width()-tmp2->boundingRect().width(),0);

			if(width < tmp2->boundingRect().width())
				width = tmp2->boundingRect().width();
		}

	}
	else
	{

		for(qreal y = yMin-yMajorDist; y < 1.5* yMajorDist + yMax ; y+= yMinorDist)
		{
			Line2D* l = new Line2D(xMin2, y, xMax2, y, pen);
			l->setZValue(-2);
			graphicsScene->grid->addToGroup(l);
		}	

		for(qreal y = yMin-yMajorDist; y < 1.5* yMajorDist + yMax ; y+= yMajorDist)
		{
			if(abs(y) < 1e-16)
				y = 0;

			graphicsScene->grid->addToGroup(new Line2D(xMin2, y, xMax2, y, pen2));

			QGraphicsTextItem* tmp2 = graphicsScene->yRulerScene->addText(QVariant(y).toString());
			tmp2->setPos(gvLeft->mapToScene( gvLeft->sceneRect().x() ,mapFromScene(xMax, y).y()+tmp2->boundingRect().height()/2 ));

			tmp2->scale(1, -1);
			tmp2->moveBy(0, tmp2->boundingRect().height());

			tmp2->moveBy(gvLeft->width()-tmp2->boundingRect().width(),0);

			if(width < tmp2->boundingRect().width())
				width = tmp2->boundingRect().width();
		}
	} ////// y klar

	if(width != gvLeft->width())
		emit resizeY(width);

	graphicsScene->grid->setZValue(-1);
	graphicsScene->addItem(graphicsScene->grid);
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
			updatePointSizes();
			doFitInView = false;
		}
		else if(doSetArea)
		{
			setArea(newRect);
			doSetArea = false;
		}
		else
			setCurrentArea(mapToScene(this->rect()).boundingRect());

		if(graphicsScene->gridVisible)
			showGrid(true);

		emit areaChanged(currentArea());

	}
	QGraphicsView::paintEvent(pe);
}

void GraphWidget::setAntiAliasing(bool on)
{
	antiAliasing = on;
	setRenderHint(QPainter::Antialiasing, on);
}

void GraphWidget::updateGrid()
{
	showGrid(true);
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

	fitInView(r);

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

QColor GraphWidget::generateColor(int index)
{
	switch(index)
	{
	case 0:
		return Qt::blue;
	case 1:
		return Qt::red;
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
	QColor color, fillColor;
	qreal x0, y0, x1, y1;
	ds >> x0 >> y0 >> x1 >> y1 >> color >> fillColor;
	QPen pen(color);
	QBrush brush(fillColor);

	graphicsItems->addToGroup(graphicsScene->addLine(QLineF(x0, y0, x1, y1), pen));
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

}

void GraphWidget::drawText(QDataStream& ds)
{
	QString str;
	qreal x, y;
	ds >> x >> y >>str;
	QGraphicsTextItem* t = graphicsScene->addText(str);
	graphicsItems->addToGroup(t);
	t->setPos(x, y);
}

void GraphWidget::drawRect(QDataStream& ds)
{
	QColor color, fillColor;
	qreal x0, y0, x1, y1;
	ds >> x0 >> y0 >> x1 >> y1 >> color >> fillColor;
	QPen pen(color);
	QBrush brush(fillColor);

	graphicsItems->addToGroup(graphicsScene->addRect(QRectF(QPointF(x0,y0), QSizeF(x1-x0, y1-y0)), pen, brush));
	update(x0, y0, x1-x1, y1-y0);
}

void GraphWidget::drawEllipse(QDataStream& ds)
{
	QColor color, fillColor;
	qreal x0, y0, x1, y1;
	ds >> x0 >> y0 >> x1 >> y1 >> color >> fillColor;
	QPen pen(color);
	QBrush brush(fillColor);

	graphicsItems->addToGroup(graphicsScene->addEllipse(QRectF(QPointF(x0, y0), QSizeF(x1-x0, y1-y0)), pen, brush));
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

void GraphWidget::ptolemyDataStreamClosed()
{
	for(map<QString, Curve*>::iterator i = temporaryCurves.begin(); i != temporaryCurves.end(); ++i)
		curves.append(i->second);	

	for(map<QString, VariableData*>::iterator i = variables.begin(); i != variables.end(); ++i)
		variableData.append(i->second);

	temporaryCurves.clear();
	variables.clear();

	if(stretch)
		resetZoom();

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

		for(int j = index; j < curves[i]->x->size()-1; ++j, C = false)
		{
			x0 = x1;
			x0_= x1_;

			x1 = x1_ = (*curves[i]->x)[j];

			y0 = y1;
			y0_ = y1_;
			y1 = y1_ = (*curves[i]->y)[j];

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

			if(!C || drawNextPoint)
			{
				Point* p = new Point(x0, y0, .02, .02, pen.color(), this,0, graphicsScene, curves[i]->x->variableName() + ": " +QVariant(x0_).toString() +"\n" + curves[i]->y->variableName() + ": " + QVariant(y0_).toString());
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
				Line2D* l = new Line2D(x0, y0, x1, y1,pen);
				graphicsScene->addItem(l);
				curves[i]->line->addToGroup(l);
			}
			else if(curves[i]->interpolation == INTERPOLATION_CONSTANT)
			{
				Line2D* l = new Line2D(x0, y0,x1, y0, pen);
				graphicsScene->addItem(l);
				curves[i]->line->addToGroup(l);

				l = new Line2D(x1, y0,x1, y1, pen);
				graphicsScene->addItem(l);
				curves[i]->line->addToGroup(l);
			}


		}

		if(!C)
		{
			QPen pen(curves[i]->color_);
			Point* p = new Point(x1, y1, .02, .02, pen.color(), this,0, graphicsScene, curves[i]->x->variableName() + ": " +QVariant(x1_).toString() +"\n" + curves[i]->y->variableName() + ": " + QVariant(y1_).toString());
			curves[i]->dataPoints.append(p);
			p->setVisible(curves[i]->drawPoints);
		}


		curves[i]->line->setVisible(curves[i]->visible);
		doFitInView = true;

		if(truncated)
			QMessageBox::information(0, "Truncated data", "The data has been truncated to allow logarithmic scaling.");
	}
}


void GraphWidget::plotPtolemyDataStream()
{
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
			ds >> xmin >> xmax >> ymin >> ymax;
			int logX, logY;
			ds >> logX >> logY;
			QString interpolation;
			ds >> interpolation;
			int points;
			ds >> points;


			yVars.clear();
			ds >> variableCount;

			LegendLabel* ll;

			for(quint32 i = 0; i < variableCount; ++i)
			{
				ds >> tmp;
				ds >> color;
				if(color == Qt::color0)
					color = generateColor(curves.size()-1 +variables.size());
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
						yVars.push_back(tmp); 
						ll = new LegendLabel(color, tmp,legendFrame);

						ll->setMaximumHeight(21);
						legendLayout->addWidget(ll);
						ll->show(); 

						temporaryCurves[tmp] = (new Curve(variables[currentXVar], variables[tmp], color, ll));
						ll->setCurve(temporaryCurves[tmp]);

					}

					if(interpolation == QString("constant"))
						temporaryCurves[tmp]->interpolation = INTERPOLATION_CONSTANT;
					else if(interpolation == QString("linear"))
						temporaryCurves[tmp]->interpolation = INTERPOLATION_LINEAR;
					else
						temporaryCurves[tmp]->interpolation = INTERPOLATION_NONE;

					temporaryCurves[tmp]->drawPoints = points;
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

		double y0, y1;
		double x0, x1;

		double y0_, y1_;
		double x0_, x1_;

		QPen color; 

		for(quint32 k=0; k < quint32(yVars.size()); ++k)
		{
			currentYVar=yVars[k];
			color = temporaryCurves[currentYVar]->color_;

			int maxIndex = min(variables[currentXVar]->size()-1, variables[currentYVar]->size()-1);

			if(int(variables[currentYVar]->currentIndex) < maxIndex)
			{
				int i = int(variables[currentYVar]->currentIndex);
///

///		
				bool truncated = false;

				while(i < maxIndex)
			{
				x1=x1_ = (*variables[currentXVar])[i];
				y1=y1_ = (*variables[currentYVar])[i];				

//
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
//
				++i;
						
				for(; i < maxIndex; ++i)
				{
					variables[currentYVar]->currentIndex++;

					x0_ = x1_;
					x0 = x1;
					y0_ = y1_;
					y0 = y1;

					x1 =x1_ = (*variables[currentXVar])[i];
					y1= y1_ = (*variables[currentYVar])[i];
/*
					if(xLog)
						x1 = log10(x1_);

					if(yLog)
						y1 = log10(y1_);
*/
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
						Line2D* l = new Line2D(x0, y0, x1, y1,color);
						graphicsScene->addItem(l);
						l->show();
						temporaryCurves[currentYVar]->line->addToGroup(l);
					}
					else if(temporaryCurves[currentYVar]->interpolation == INTERPOLATION_CONSTANT)
					{
						Line2D* l = new Line2D((*variables[currentXVar])[i], (*variables[currentYVar])[i],(*variables[currentXVar])[i+1], (*variables[currentYVar])[i]);
						graphicsScene->addItem(l);
						temporaryCurves[currentYVar]->line->addToGroup(l);

						l = new Line2D((*variables[currentXVar])[i+1], (*variables[currentYVar])[i],(*variables[currentXVar])[i+1], (*variables[currentYVar])[i+1]);
						graphicsScene->addItem(l);
						temporaryCurves[currentYVar]->line->addToGroup(l);
					}
					else if(temporaryCurves[currentYVar]->interpolation == INTERPOLATION_NONE)
					{
						Line2D* l = new Line2D(x0, y0, x1, y1,color);
						l->setVisible(false);
						graphicsScene->addItem(l);
						temporaryCurves[currentYVar]->line->addToGroup(l);
					}

					Point* p = new Point(x0, y0, .02, .02, color.color(), this,0, graphicsScene);
					p->setVisible(temporaryCurves[currentYVar]->drawPoints);
					temporaryCurves[currentYVar]->dataPoints.append(p);

//					variables[currentYVar]->currentIndex++;
				}
			}
		}

		packetSize = 0;
		++it;
	}
	while(activeSocket->bytesAvailable() >= sizeof(quint32));

	if(activeSocket->state() != QAbstractSocket::ConnectedState)
		ptolemyDataStreamClosed();
}
