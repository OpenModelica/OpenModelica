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

#ifndef GRAPHWIDGET_H
#define GRAPHWIDGET_H

//Qt headers
#include <QtNetwork/QTcpSocket>
#include <QtNetwork/QTcpServer>
#include <QGraphicsScene>
#include <QGraphicsView>
#include <QGraphicsItemGroup>
#include <QPointF>
#include <QList>
#include <QVBoxLayout>

//Std headers
#include <map>
#include <iostream>

//IAEX headers
#include "curve.h"
#include "graphScene.h"
#include "variableData.h"
#include "lineGroup.h"

using namespace std;

class Point;
class CompoundWidget;
//class Curve;

class GraphWidget: public QGraphicsView
{
	Q_OBJECT

public:
	GraphWidget(QWidget* parent = 0);
	~GraphWidget();

	//	void printData(QString data);
	//	void printData2(qreal x0, qreal y0, qreal x1, qreal y1);

	quint16 serverPort() {return server->serverPort();}

public slots:
	void getData();
	void acCon();
	void drawGraphics();
	void drawLine(QDataStream& ds);
	void drawPoint(QDataStream& ds);
	void drawText(QDataStream& ds);
	void drawRect(QDataStream& ds);
	void drawEllipse(QDataStream& ds);
	void readPtolemyDataStream();
	void ptolemyDataStreamClosed();
	void plotPtolemyDataStream();
	void dataStreamClosed();
	void graphicsStreamClosed();
	void receiveDataStream();

	void setLogarithmic(bool);
	void setServerState(bool listen, bool graphics = false);
	void setStretch(bool b) {stretch = b;}

	void newWindow();
	void zoomIn(QRectF);

	void setExpr(QString);

	void setPan(bool b) 
	{ 
		pan = b; 
		if(b)
		{
			zoom = false;
			select=false;
			setDragMode(QGraphicsView::ScrollHandDrag);
		}
	}

	void setSelect(bool b) 
	{
		select = b;
		if(b)
		{
			zoom = false;
			pan = false;
			setDragMode(QGraphicsView::RubberBandDrag);
			setDragMode(QGraphicsView::NoDrag);
		}
	}

	void setZoom(bool b) 
	{
		zoom = b;
		if(b)
		{
			select = false;
			pan = false;
			setDragMode(QGraphicsView::RubberBandDrag);
		}
	}

	void resetZoom();

	void clear();

	void showGrid(bool);
	void updateGrid();

	void setArea(const QRectF& r);
	void showPreferences();
	void showVariables();
	void setAntiAliasing(bool);
	void setHold(bool);
	void setHold(QDataStream& ds);

	void originalZoom();
	void addFocusBox();
	void syncCall();
	void enableServers(bool);

signals:
	void showPreferences2();
	void serverState(bool);
	void newMessage(QString message);
	void resizeY(quint32);
	void zoomEvent(QRectF);
	void scrolled();
	void scrollBy(int x, int y);
	void areaChanged(const QRectF& r);
	void setGridVisible(bool);
	void holdSet(bool);
	void newExpr(QString);
	void showGraphics();
	void showVariableButton(bool);
//	void serverState(bool);

public:
	GraphScene* graphicsScene;

protected:
	void resizeEvent ( QResizeEvent * event );
	void mouseReleaseEvent ( QMouseEvent * event );  
	void mousePressEvent ( QMouseEvent * event );

	void paintEvent(QPaintEvent* pe);

	void showEvent(QShowEvent* event);
	quint32 blockSize;

	QTcpServer* server, *graphicsServer;
	QTcpSocket* activeSocket, *graphicsSocket;
	QDataStream ds, ds2;

	int tmpint;

	int nr;
	bool getNames;
	quint32 variableCount;
	quint32 packetSize, packetSize2;

	void createGrid(bool numbersOnly = false);
	qreal gridDist(qreal &min, qreal &max, qreal dist = -1);

public:
	bool getServerState();
	map<QString, VariableData*> variables;
	map<QString, Curve*> temporaryCurves;

	void updatePointSizes(QRect r = QRect());

	QRectF currentArea()
	{
		return currentArea_;
	}

	void setCurrentArea(const QRectF& r)
	{
		currentArea_ = r;
	}

private:
	void drawRulers();
	void updateScaleFactors()
	{
		QPolygonF p = mapToScene(QRect(0,0,10,10));
		xScaleFactor = p.boundingRect().width()/10;
		yScaleFactor = p.boundingRect().height()/10;

	}

	
	void rescale()
	{

	}

	bool stretch;
	bool hold;
	bool zoom;
	bool pan;
	bool select;
	double xScaleFactor, yScaleFactor;

	QList<Point*> *dataPoints;
	QColor generateColor(int index);
	QPoint zoomStart;
	QMenu* contextMenu;

	QRectF currentArea_;
	QString zoomStr, gridStr, aAStr;
	QRectF range;
	double dataStreamVersion;

public:
	QString currentExpr;

	QRectF originalArea;


	QGraphicsItemGroup *graphicsItems;

	QList<VariableData*> variableData;

	QList<Curve*> curves;
	bool xLog, yLog;

	QRectF gridArea;
	QRectF manualArea;
	bool useManualArea;
	bool gridVisible;

public:
	bool antiAliasing;
	QString currentXVar, currentYVar;
	QStringList yVars;
	QGraphicsView *gvLeft, *gvBottom;
	QVBoxLayout* legendLayout;
	QFrame* legendFrame;

	CompoundWidget* compoundwidget;

	qreal xMajorDist, xMinorDist, yMajorDist, yMinorDist; //grid parameters
	bool fixedYSize, fixedXSize;
	bool fixedGrid;

	bool doFitInView, doSetArea;
	QRectF newRect;
	QAction* aaAction;
};
#endif
