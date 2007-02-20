#ifndef POINT_H
#define POINT_H
#include <QGraphicsPathItem>
#include "GraphWidget.h"

class Point: public QGraphicsEllipseItem
{
//	Q_OBJECT
   public:
      Point(qreal x1, qreal y1, qreal h, qreal w, const GraphWidget* graphwidget, QGraphicsItem* parent=0, QGraphicsScene* scene=0);
      ~Point();
	double xFactor, yFactor;
	double xPos, yPos, height, width;

   protected:
      virtual void hoverEnterEvent ( QGraphicsSceneHoverEvent * event );
      virtual void hoverLeaveEvent ( QGraphicsSceneHoverEvent * event );
      virtual void mousePressEvent ( QGraphicsSceneMouseEvent * event );      
	  virtual void paint(QPainter *painter, const QStyleOptionGraphicsItem *option,QWidget *widget);


};




#endif
