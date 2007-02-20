#include "graphWidget.h"
#include <QString>
#include <QVariant>
#include <fstream>
#include <iostream>
#include <QGraphicsTextItem>
#include "line2D.h"
#include <QPen>
#include <cmath>
#include "lineGroup.h"
#include "dataSelect.h"
#include "variableData.h"
#include <QTextStream>
#include <QImage>
#include "graphWindow.h"
#include <QtGui/QMessageBox>
#include <QGraphicsEllipseItem>
#include <QtAlgorithms>
#include <QPointF>
#include <QMouseEvent>
#include <QPolygonF>
#include <QScrollBar>
#include "point.h"
#include <QGraphicsScene>
#include <QGraphicsView>
#include <QBuffer>
#include <QFile>
#include <QSizePolicy>
#include "LegendLabel.h"
#include <QColor>
#include <QToolTip>
using namespace std;

GraphWidget::GraphWidget(QWidget* parent): QGraphicsView(parent)
{

	graphicsScene = new GraphScene;
	//	graphicsScene->setItemIndexMethod(QGraphicsScene::NoIndex);
	setScene(graphicsScene);
	this->setBackgroundBrush(QBrush(Qt::white));

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


	this->setSizePolicy(QSizePolicy::Preferred, QSizePolicy::Expanding);
	this->setMinimumHeight(150);

	this->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
	this->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);

	updateScaleFactors();

	QAction* tmp;

	contextMenu = new QMenu(this);
//	(contextMenu->addAction("Active"))->setCheckable(true);

//	contextMenu->addSeparator();

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

	contextMenu->addSeparator();

	tmp =contextMenu->addAction("Clear");
	connect(tmp, SIGNAL(triggered()), this, SLOT(clear()));

	tmp=contextMenu->addAction("Save");
	connect(tmp, SIGNAL(triggered()), this, SLOT(saveImage()));
	contextMenu->addSeparator();

	tmp=contextMenu->addAction("New window");
	connect(tmp, SIGNAL(triggered()), this, SLOT(newWindow()));

	tmp=contextMenu->addAction("Preferences");
	connect(tmp, SIGNAL(triggered()), this, SLOT(showPreferences()));

//	connect(this, SIGNAL(scrolled()), this, SLOT(updateGrid()));


	tmp = contextMenu->addAction("Antialiasing");
	tmp->setCheckable(true);
	connect(tmp, SIGNAL(toggled(bool)), this, SLOT(setAntiAliasing(bool)));

	graphicsItems = new QGraphicsItemGroup;

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
	gw->gwMain->fitInView(this->sceneRect());
	//	connect(this, SIGNAL(destroyed()), g, SLOT(close()));
	connect(g->actionGrid, SIGNAL(toggled(bool)), gw->gwMain, SLOT(showGrid(bool)));

	connect(this, SIGNAL(zoomEvent(QRectF)), gw->gwMain, SLOT(zoomIn(QRectF)));
	connect(gw->gwMain, SIGNAL(zoomEvent(QRectF)), this, SLOT(zoomIn(QRectF)));

	connect(gw->gwMain, SIGNAL(areaChanged(const QRectF&)), this, SLOT(setArea(const QRectF&)));
	connect(this, SIGNAL(areaChanged(const QRectF&)), gw->gwMain, SLOT(setArea(const QRectF&)));

	g->show();


	gw->gwMain->fitInView(this->sceneRect());

}

GraphWidget::~GraphWidget()
{
	for(map<QString, VariableData*>::iterator i = variables.begin(); i != variables.end(); ++i)
		delete i->second;

	delete contextMenu;
	int nr = graphicsScene->views().count();
	if(nr <= 1)
		delete graphicsScene;


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
void GraphWidget::plotVariables(const QString& xVar, const QString& yVar)
{
	VariableData* X = variables[xVar];
	VariableData* Y = variables[yVar];

	LineGroup* group = new LineGroup;
	curves << group;

	for(int i = 1; i < min(X->size(), Y->size()); ++i)
	{
		Line2D* l = new Line2D((*X)[i-1], (*Y)[i-1], (*X)[i], (*Y)[i]);
		group->addToGroup(l);
	}

	graphicsScene->addItem(group);

	fitInView(graphicsScene->sceneRect());

}


void GraphWidget::getData()
{

	QDataStream in(activeSocket);
	in.setVersion(QDataStream::Qt_4_2);

	disconnect(activeSocket, SIGNAL(readyRead()), 0, 0);

	while(activeSocket->bytesAvailable())
	{
		if (blockSize == 0)
		{
			if (activeSocket->bytesAvailable() < sizeof(quint32))
				return;

			in >> blockSize;
		}

		if (activeSocket->bytesAvailable() < blockSize)
			return;

		QString command;
		in >> command;



		if(command == QString("clear"))
			//		clear(in);
			;
		else if(command == QString("drawLine"))
			drawLine(in);
		else if(command == QString("drawPoint"))
			drawPoint(in);
		else if(command == QString("drawText"))
			drawText(in);
		else if(command == QString("drawRect"))
		{	
			drawRect(in);
			blockSize = 0;
		}
		else if(command == QString("drawEllipse"))
		{
			drawEllipse(in);
		}
		else if(command == QString("closeServer"))
		{
			setServerState(false);
			activeSocket->disconnect();
			activeSocket->disconnectFromHost();
		}
		else if(command == QString("testSocket"))
			;
		else if(command == QString("ptolemyData"))
			plotPtolemyData(in);
		else if(command == QString("ptolemyDataStream"))
		{

			emit newMessage("Recieving streaming data...");
			disconnect(activeSocket, SIGNAL(readyRead()), 0, 0);

			connect(activeSocket, SIGNAL(readyRead()), this, SLOT(plotPtolemyDataStream()));
			connect(activeSocket, SIGNAL(disconnected()), this, SLOT(ptolemyDataStreamClosed()));

			variableCount = 0;
			packetSize = 0;
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


	if(event->button() == Qt::RightButton)
	{

		contextMenu->exec(event->globalPos());


	}
	else
		zoomStart = event->pos();

	QGraphicsView::mousePressEvent(event);		
	
}

void GraphWidget::resetZoom()
{
	bool visible;
	if(visible = graphicsScene->gridVisible)
	{
		showGrid(false);

	}
	graphicsScene->setSceneRect(graphicsScene->itemsBoundingRect());
	fitInView(graphicsScene->sceneRect());
	if(visible)
		showGrid(true);



}
void GraphWidget::mouseReleaseEvent ( QMouseEvent * event )
{
	QGraphicsView::mouseReleaseEvent(event);

	zoomStart = mapToScene(zoomStart.toPoint());
	QPointF zoomEnd = QPointF(mapToScene(event->pos()));


	//	if(zoom && graphicsScene->selectedItems().size() > 0)
	if(zoom)
	{

		if(event->button() == Qt::RightButton)
		{
			/*
			//			graphicsScene->setSceneRect(originalSize);
			showGrid(false);
			fitInView(graphicsScene->sceneRect());
			
			updateScaleFactors();
			//			rescale();
			showGrid(true);
			update();
			*/
		}

		else
		{

			double left, right, top, bottom;

			if(zoomStart.x() > zoomEnd.x())
			{
				left = 	zoomEnd.x();
				right = zoomStart.x();
			}
			else
			{
				left = zoomStart.x();
				right = zoomEnd.x();
			}

			if(zoomStart.y() > zoomEnd.y())
			{
				bottom = 	zoomEnd.y();
				top = zoomStart.y();
			}
			else
			{
				top = zoomStart.y();
				bottom = zoomEnd.y();
			}



			bottom += mapToScene(0,0,0,this->horizontalScrollBar()->height()).boundingRect().height();
			right += mapToScene(0,0,this->verticalScrollBar()->width(), 0).boundingRect().width();


			fitInView(QRectF(left, bottom, right-left, top-bottom));

			update(rect());

		}
	}

}

void GraphWidget::zoomIn(QRectF r)
{
	fitInView(r);

	if(graphicsScene->gridVisible)
		showGrid(true);
}

void GraphWidget::clear()
{

	try
	{
		delete graphicsItems;
		graphicsItems = new QGraphicsItemGroup;
	}
	catch(...)
	{
	}
	graphicsScene->update();

	//	graphicsScene->setSceneRect(0, -.5, 1, 1);
}

qreal GraphWidget::gridDist(qreal &min, qreal &max)
{
	qreal distance = (max - min) / 10.;

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

	//	min = floor(min/distance)*distance;
	//	max = ceil(max/distance)*distance;
	min = ceil(min/distance)*distance;
	max = floor(max/distance)*distance;

	return distance;

}
void GraphWidget::createGrid()
{
	QRectF scene = graphicsScene->sceneRect();
	graphicsScene->xRulerScene->setSceneRect(scene);
	graphicsScene->yRulerScene->setSceneRect(scene);


	qreal xMin, xMax, yMin, yMax;
	if(xLog)
	{
		xMin =exp(mapToScene(0, 0).x());
		xMax = exp(mapToScene(width(), 0).x());
	}
	else
	{
		xMin =mapToScene(0, 0).x();
		xMax = mapToScene(width(), 0).x();
	}

	if(yLog)
	{
		yMin = exp(mapToScene(0, height()).y());
		yMax = exp(mapToScene(0, 0).y());
	}
	else
	{
		yMin = mapToScene(0, height()).y();
		yMax = mapToScene(0, 0).y();
	}

	qreal xDist = gridDist(xMin, xMax) ;

	qreal yDist = gridDist(yMin, yMax);	

	delete graphicsScene->grid;
	graphicsScene->grid = new QGraphicsItemGroup;

	foreach(QGraphicsItem* ti, graphicsScene->xRulerScene->items())
		delete ti;

	double x0, y0;

	QPen pen(Qt::gray);	

	for(qreal x = xMin-xDist; x < 1.5* xDist + xMax; x+= xDist)	{
		if(xLog)
			x0=log(x);
		else
			x0=x;

		Line2D* l = new Line2D(x0, yMin-yDist, x0,  yMax+yDist, pen);
		graphicsScene->grid->addToGroup(l);

		
		//////		
		QGraphicsTextItem* tmp2 = graphicsScene->xRulerScene->addText(QVariant(x).toString());
		tmp2->setPos(gvBottom->mapToScene(mapFromScene(x0, yMax)).x()-tmp2->boundingRect().width()/2, gvBottom->sceneRect().y());
		tmp2->moveBy(0, -tmp2->boundingRect().height()/2.);
		tmp2->show();
		/////

	}


	foreach(QGraphicsItem* ti, graphicsScene->yRulerScene->items())
		delete ti;

	quint32 width=0;

	gvLeft->setMatrix(QMatrix(1, 0,0,-1,0,0));
	for(qreal y = yMin-yDist; y < 1.5* yDist + yMax ; y+= yDist)
	{


		if(yLog)
			y0=log(y);
		else
			y0=y;

		graphicsScene->grid->addToGroup(new Line2D(xMin-xDist, y0, xMax+xDist, y0, pen));

		////
		QGraphicsTextItem* tmp2 = graphicsScene->yRulerScene->addText(QVariant(y).toString());
		tmp2->setPos(gvLeft->mapToScene( gvLeft->sceneRect().x() ,mapFromScene(xMax, y0).y()+tmp2->boundingRect().height()/2 ));

		tmp2->scale(1, -1);
		tmp2->moveBy(0, tmp2->boundingRect().height());

		tmp2->moveBy(gvLeft->width()-tmp2->boundingRect().width(),0);
		tmp2->show();


		if(width < tmp2->boundingRect().width())
			width = tmp2->boundingRect().width();

	}

	if(width != gvLeft->width())

		emit resizeY(width);

	graphicsScene->grid->setZValue(-1);
	graphicsScene->addItem(graphicsScene->grid);
	graphicsScene->update(currentArea);

	gvLeft->update();
	gvBottom->update();
}

void GraphWidget::paintEvent(QPaintEvent *pe)
{

	if(currentArea != mapToScene(rect()).boundingRect())
	{
		currentArea = mapToScene(this->rect()).boundingRect();

		if(graphicsScene->gridVisible)
			showGrid(true);

		emit areaChanged(currentArea);

	}
	QGraphicsView::paintEvent(pe);

}

void GraphWidget::setAntiAliasing(bool on)
{
	setRenderHint(QPainter::Antialiasing, on);

}
//void GraphWidget::drawRulers()
//{
//	///////////////////////



//	QRectF scene = graphicsScene->sceneRect();


//	qreal xMin =mapToScene(0, 0).x();
//	qreal xMax = mapToScene(width(), 0).x();
//	//	qreal xMin = graphicsScene->sceneRect().x();
//	//	qreal xMax = graphicsScene->sceneRect().width() + xMin;
//	qreal yMin = mapToScene(0, height()).y();
//	qreal yMax = mapToScene(0, 0).y();

//	qreal xDist = gridDist(xMin, xMax) ;

//	qreal yDist = gridDist(yMin, yMax);	

//	foreach(QGraphicsItem* ti, graphicsScene->xRulerScene->items())
//		delete ti;

//	//	foreach(QGraphicsItem* ti, yRulerScene->items())
//	//		delete ti;


//	for(qreal x = xMin ; x <= xMax+.5*xDist; x += xDist)
//		//	for(qreal x = xMin - int((xMin - graphicsScene->sceneRect().x())/xDist)*xDist; x < .5* xDist + xMax +int((graphicsScene->sceneRect().width() + graphicsScene->sceneRect().x() - xMax)/xDist)*xDist; x+= xDist)
//	{
//		QGraphicsTextItem* tmp2 = graphicsScene->xRulerScene->addText(QVariant(x).toString());
//		tmp2->setPos(gvBottom->mapToScene(mapFromScene(x, yMax)).x()-tmp2->boundingRect().width()/2, gvBottom->sceneRect().y());
//		tmp2->show();
//	}


//	/* 070116
//	for(qreal y = yMin; y <= yMax + .5*yDist; y+= yDist)
//	{
//	QGraphicsTextItem* tmp2 = yRulerScene->addText(QVariant(y).toString());
//	tmp2->setPos(gvLeft->mapToScene( gvLeft->sceneRect().x() ,mapFromScene(xMax, y).y()-tmp2->boundingRect().height()/2 ));
//	tmp2->show();

//	}
//	*/




//	////////////////////////
//}

void GraphWidget::updateGrid()
{
	showGrid(true);

}

void GraphWidget::scrollContentsBy(int dx, int dy)
{

	QGraphicsView::scrollContentsBy(dx, dy);



	emit scrollBy(dx,dy);

}

void GraphWidget::setArea(const QRectF& r)
{
	if(r != currentArea)
	{
		fitInView(r);

		currentArea = mapToScene(rect()).boundingRect();
		update(rect());



	}
}

void GraphWidget::showGrid(bool b)
{

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

void GraphWidget::saveImage()
{
	QImage qi(rect().size(),QImage::Format_RGB32);
	QPainter qp;
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
}

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
	default:
		return Qt::black;
	}

}
void GraphWidget::drawLine(QDataStream& ds)
{
	qreal x1, x2, y1, y2;
	ds >> x1 >> y1 >> x2 >> y2;

	graphicsScene->addLine(QLineF(x1, y1, x2, y2));
	graphicsScene->update();
}
void GraphWidget::drawPoint(QDataStream& ds)
{


}
void GraphWidget::drawText(QDataStream& ds)
{
	QString str;
	qreal x, y;
	ds >> x >> y >>str;
	(graphicsScene->addText(str))->setPos(x, y);
}
void GraphWidget::drawRect(QDataStream& ds)
{
	qreal x0, y0, x1, y1;
	ds >> x0 >> y0 >> x1 >> y1;
	graphicsScene->addRect(QRectF(QPointF(x0, y0), QSizeF(x1-x0, y1-y0)), QPen(Qt::black), QBrush(Qt::SolidPattern));

	graphicsScene->update();
}
void GraphWidget::drawEllipse(QDataStream& ds)
{

	qreal x0, y0, x1, y1;
	ds >> x0 >> y0 >> x1 >> y1;
	graphicsItems->addToGroup(graphicsScene->addEllipse(QRectF(QPointF(x0, y0), QSizeF(x1-x0, y1-y0)), QPen(Qt::black)));
	graphicsScene->update();


}

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

	if(stretch)
		resetZoom();

	emit newMessage("Connection closed");

}

void GraphWidget::plotPtolemyDataStream()
{
	QDataStream ds(activeSocket);
	ds.setVersion(QDataStream::Qt_4_2);

	QString tmp;
	QColor color = QColor(Qt::color0);
	double d;

	quint32 it = 0;
	do
	{

		//		if(!(it % 100))
		//			qApp->processEvents(QEventLoop::ExcludeSocketNotifiers);

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

			QString title, xLabel, yLabel;
			ds >> title;
			ds >> xLabel;
			ds >> yLabel;

			bool legend, grid;
			ds >> legend >> grid;

			double xmin, xmax, ymin, ymax;
			ds >> xmin >> xmax >> ymin >> ymax;
			bool logX, logY;
			ds >> logX >> logY;
			QString interpolation;
			ds >> interpolation;

			yVars.clear();
			ds >> variableCount;

			LegendLabel* ll;

			for(quint32 i = 0; i < variableCount; ++i)
			{
				ds >> tmp;
				ds >> color;
				if(color == Qt::color0)
					color = generateColor(variables.size()-1);

				tmp = tmp.trimmed();
				if(variables.find(tmp) != variables.end())
					delete variables[tmp];
				variables[tmp] = new VariableData(tmp, color);

				if(i == 0)
					currentXVar = tmp;
				else //if(i == 1)
					//					currentYVar = tmp;
					if(yVars.indexOf(tmp) == -1)
					{
						yVars.push_back(tmp); 
						ll = new LegendLabel(color, tmp,legendFrame);
						ll->setMaximumHeight(21);
						legendLayout->addWidget(ll);
						ll->show(); 
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

		QPen color; 

		for(quint32 k=0; k < quint32(yVars.size()); ++k)
		{

			currentYVar=yVars[k];
			color = variables[currentYVar]->color;

			int maxIndex = min(variables[currentXVar]->size()-1, variables[currentYVar]->size()-1);

			if(int(variables[currentYVar]->currentIndex) < maxIndex)
			{
				for(int i = int(variables[currentYVar]->currentIndex); i < maxIndex; ++i)
				{
					if(xLog)
					{
						x0 = log((*variables[currentXVar])[i]);
						x1 = log((*variables[currentXVar])[i+1]);
					}
					else
					{
						x0 = (*variables[currentXVar])[i];
						x1 = (*variables[currentXVar])[i+1];
					}

					if(yLog)
					{
						y0 = log((*variables[currentYVar])[i]);
						y1 = log((*variables[currentYVar])[i+1]);
					}
					else
					{
						y0 = (*variables[currentYVar])[i];
						y1 = (*variables[currentYVar])[i+1];
					}

					Line2D* l = new Line2D(x0, y0, x1, y1,color);

					//  QGraphicsEllipseItem *li = new QGraphicsEllipseItem(x0, y0, .0001, .0001,0,graphicsScene);

					//	Line2D* l2 = new Line2D((*variables[currentXVar])[i], (*variables[currentYVar])[i],(*variables[currentXVar])[i+1], (*variables[currentYVar])[i]);
					//	graphicsScene->addItem(l2);
					//	Line2D* l = new Line2D((*variables[currentXVar])[i+1], (*variables[currentYVar])[i],(*variables[currentXVar])[i+1], (*variables[currentYVar])[i+1]);


					//  //	QGraphicsEllipseItem* l = new QGraphicsEllipseItem((*variables[QString("time")])[i], (*variables[QString("x")])[i],.1, .1);
					//  //	l->show();
					//	graphicsScene->addItem(l);

					//	Point* p = new Point((*variables[currentXVar])[i], (*variables[currentYVar])[i], .1, .1, this);
					//	graphicsScene->addItem(p);

					graphicsScene->addItem(l);
					graphicsItems->addToGroup(l);

					variables[currentYVar]->currentIndex++;
					//	variables[currentYVar]->currentIndex = i+1;
				}


				//if(stretch && !(it % 50))
				//{
				//	fitInView(graphicsScene->sceneRect());
				//	//	updateScaleFactors();
				//	//	rescale();
				//}

			}
		}


		packetSize = 0;
		++it;

	}
	while(activeSocket->bytesAvailable() >= sizeof(quint32));

	if(activeSocket->state() != QAbstractSocket::ConnectedState)
		ptolemyDataStreamClosed();
}

