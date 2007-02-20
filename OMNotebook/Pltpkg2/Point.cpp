#include "point.h"
#include <QPen>
#include <iostream>
#include <QGraphicsItem>
#include "GraphWidget.h"
#include <QVariant>
using namespace std;

Point::Point(qreal x1, qreal y1,qreal h, qreal w, const GraphWidget* graphwidget, QGraphicsItem* parent, QGraphicsScene* scene): QGraphicsEllipseItem(x1, y1, h, w, parent, scene)
{
	xPos = x1;
	yPos = y1;
	height = h;
	width = w;

	setAcceptsHoverEvents(true);
	QPen qp;
	qp.setWidthF(.01);
	qp.setColor(Qt::red);
	setPen(qp);
	setToolTip(graphwidget->currentXVar + QString(": ") + QVariant(x1).toString() + QString("\n") + graphwidget->currentYVar +QString(": ") + QVariant(y1).toString());
	moveBy(-w/2., -h/2.);

}

Point::~Point()
{

}

void Point::paint(QPainter *painter, const QStyleOptionGraphicsItem *option,QWidget *widget)
{
//	painter->drawEllipse(QRectF(x(), y(), 1, 1));
	painter->setPen(QPen(Qt::red));
	

	painter->drawEllipse(QRectF(xPos,yPos,max(100/xFactor,.0001), max(100/yFactor, .0001)));
//	painter->drawEllipse(QRectF(xPos,yPos,height*yFactor, width*xFactor));	
//	cout << xFactor << ", " << yFactor << endl;
}

void Point::hoverEnterEvent ( QGraphicsSceneHoverEvent * event )
{

	QPen qp;
	qp.setWidthF(.01);
	qp.setColor(Qt::blue);
	setPen(qp);
}
void Point::hoverLeaveEvent ( QGraphicsSceneHoverEvent * event )
{

	QPen qp;
	qp.setWidthF(.01);
	qp.setColor(Qt::red);
	setPen(qp);
}

void Point::mousePressEvent ( QGraphicsSceneMouseEvent * event )
{
}
