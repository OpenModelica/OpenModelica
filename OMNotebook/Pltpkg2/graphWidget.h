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
 * For more information about the Qt-library visit TrollTech's webpage 
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
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
