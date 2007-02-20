#include "line2D.h"
#include <QPen>
#include <iostream>
#include <QGraphicsItem>
#include <QMessageBox>
using namespace std;

Line2D::Line2D(qreal x1, qreal y1, qreal x2, qreal y2, QPen& pen, QGraphicsItem* parent, QGraphicsScene* scene): QGraphicsLineItem(x1, y1, x2, y2, parent, scene)
{
//	setAcceptsHoverEvents(true);

	//	QPen qp;
//	qp.setWidthF(.01);
//	qp.setColor(Qt::green);
//	pen.setWidthF(.01);
	setPen(pen);
	
}

Line2D::~Line2D()
{

}


void Line2D::hoverEnterEvent ( QGraphicsSceneHoverEvent * event )
{

	QPen qp;
//	qp.setWidthF(.01);
	qp.setColor(Qt::red);
	setPen(qp);
}
void Line2D::hoverLeaveEvent ( QGraphicsSceneHoverEvent * event )
{

	QPen qp;
//	qp.setWidthF(.01);
	qp.setColor(Qt::green);
	setPen(qp);
}

void Line2D::mousePressEvent ( QGraphicsSceneMouseEvent * event )
{
	QList<QGraphicsItem*> l = group()->children();
	for(int i = 0; i < l.size(); ++i)
		static_cast<Line2D*>(l[i])->setPen(QPen(Qt::red));
}
