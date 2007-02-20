#ifndef LINE2D_H
#define LINE2D_H
#include <QGraphicsPathItem>
#include <QPen>

class Line2D: public QGraphicsLineItem
{
//	Q_OBJECT
   public:
      Line2D(qreal x1, qreal y1, qreal x2, qreal y2, QPen& pen = QPen(Qt::blue), QGraphicsItem* parent=0, QGraphicsScene* scene=0);
      ~Line2D();
      
   protected:
      virtual void hoverEnterEvent ( QGraphicsSceneHoverEvent * event );
      virtual void hoverLeaveEvent ( QGraphicsSceneHoverEvent * event );
      virtual void mousePressEvent ( QGraphicsSceneMouseEvent * event );      
 


};




#endif
