#ifndef GRAPHWIDGET_H
#define GRAPHWIDGET_H
#include <QtNetwork/QTcpSocket>
#include <QtNetwork/QTcpServer>
#include <QGraphicsScene>
#include <QGraphicsView>
#include "variableData.h"
#include <map>
#include <QGraphicsItemGroup>
#include "lineGroup.h"
#include <QPointF>
#include <iostream>
#include <QList>
#include "graphScene.h"
#include <QVBoxLayout>

using namespace std;



class GraphWidget: public QGraphicsView
{
	Q_OBJECT

public:
	GraphWidget(QWidget* parent = 0);
	~GraphWidget();

	void plotVariables(const QString& xVar, const QString& yVar);
	void printData(QString data);
	void printData2(qreal x0, qreal y0, qreal x1, qreal y1);



	quint16 serverPort() {return server->serverPort();}

	public slots:
		

		void getData();
		void acCon();


//		void clear(QDataStream& ds);
		void drawLine(QDataStream& ds);
		void drawPoint(QDataStream& ds);
		void drawText(QDataStream& ds);
		void drawRect(QDataStream& ds);
		void drawEllipse(QDataStream& ds);
		void plotPtolemyData(QDataStream& ds);
		void readPtolemyDataStream();
		void ptolemyDataStreamClosed();
		void plotPtolemyDataStream();

		void setServerState(bool listen);
		void setStretch(bool b) {stretch = b;}

		void saveImage();
		void newWindow();

		void zoomIn(QRectF);

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

//		void scrollTo(int, int);
		void setArea(const QRectF& r);

		void showPreferences();
		
		void setAntiAliasing(bool);

	signals:
		void showPreferences2();

		void serverState(bool);
		void newMessage(QString message);
		void resizeY(quint32);
		void zoomEvent(QRectF);
		void scrolled();
		void scrollBy(int x, int y);
		void areaChanged(const QRectF& r);
		
public:
		GraphScene* graphicsScene;

protected:
	void resizeEvent ( QResizeEvent * event );
    void mouseReleaseEvent ( QMouseEvent * event );  
    void mousePressEvent ( QMouseEvent * event );
	void scrollContentsBy(int dx, int dy);
//	void mouseMoveEvent ( QMouseEvent * event );		


	void paintEvent(QPaintEvent* pe);

	quint32 blockSize;

	QTcpServer* server;
	QTcpSocket* activeSocket;
//	QGraphicsScene* graphicsScene;

	int nr;
	bool getNames;
	quint32 variableCount;
	quint32 packetSize;

	void createGrid();
	qreal gridDist(qreal &min, qreal &max);

public:
	bool getServerState();
	map<QString, VariableData*> variables;
	QList<LineGroup*> curves;



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
	bool zoom;
	bool pan;
	bool select;
	double xScaleFactor, yScaleFactor;


	QGraphicsItemGroup *graphicsItems;

	QColor generateColor(int index);

	QPointF zoomStart;

	QMenu* contextMenu;

public:
////////////// 
	bool xLog, yLog;
	QRectF currentArea;
	QRectF gridArea;
	QRectF manualArea;
	bool useManualArea;
	bool gridVisible;


//////////////

public:
	QString currentXVar, currentYVar;
	QStringList yVars;
//	QGraphicsScene* xRulerScene, *yRulerScene;
	QGraphicsView *gvLeft, *gvBottom;
	QVBoxLayout* legendLayout;
	QFrame* legendFrame;
	
};
#endif
