#ifndef SHAPES_H
#define SHAPES_H

#include "basic.h"

class Shapes:public QGraphicsItem
{
   public:
     Shapes(QPointF strt_pnt,QPointF end_pnt);
     ~Shapes(){}

     QPointF getStrtPnt();
     QPointF getEndPnt();

     void setStrtPnt(const QPointF &strt_pnt);
     void setEndPnt(const QPointF &end_pnt);

     virtual void boundingBox()=0;
     //virtual bool  getStrtEdge(const QPointF pnt)=0;
     //virtual bool  getEndEdge(const QPointF pnt)=0;
     //virtual bool objectSelected(const QPointF pnt)=0;

     //virtual void setTranslate(QPointF pnt,QPointF pnt1)=0;
     //virtual void setRotate(float angle)=0;
     //virtual void setScale(float x,float y)=0;

     virtual QPointF getTranslate(float x,int y)=0;
     virtual float getRotate(float angle)=0;
     virtual QPointF getScale(float x,float y)=0;

     void setGraphicsItem(QGraphicsItem *item);
     QGraphicsItem* getGraphicsItem();

  private:
     QPointF StrtPnt;
     QPointF EndPnt;
     QGraphicsItem *Item;

};

#endif // SHAPES_H
