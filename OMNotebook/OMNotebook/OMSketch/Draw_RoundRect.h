#ifndef DRAW_ROUNDRECT_H
#define DRAW_ROUNDRECT_H

#include "basic.h"

class Draw_RoundRect:public QGraphicsPathItem
{
    public:
    Draw_RoundRect();
    Draw_RoundRect(QPointF strt_pnt,QPointF end_pnt);

    void setDefaults(){}

    //QGraphicsItem getGraphicsItem(){}

    //Getting and setting lines initial and last positions
    QPointF getStartPnt();
    QPointF getEndPnt();
    QPointF getPnt();
    QPointF getBoundMinPnt();
    QPointF getBoundMaxPnt();

    QPainterPath getRoundRect(const QPointF pnt,const QPointF pnt1);
  //writes the shapes and shapes attributes to an image
  void drawImage(QPainter *painter,QString &text,QPointF point);

    void setStartPoint(QPointF strt_pnt);
    void setEndPoint(QPointF lst_pnt);
    void setPnt(QPointF pnt);
    void setGraphicsItem(QGraphicsItem *item);
    void setItemId(int id);

    void setEdgeRects();
    void updateEdgeRects();

    QPointF getRectstartPnt();
    QPointF getRectendPnt();



     //Getting and setting rectangles drawing states and drawing mode
     int getState();
     void setState(int State);

     bool getMode();
     void setMode(bool mode);

     void setPen(const QColor color);
     void setPenStyle(const int style);
     void setPenWidth(const int width);
     QPen getPen();

     void setBrush(const QBrush brush);
     void setBrushStyle(const int style);
     QBrush getBrush();

     //checking the mouse position to resize and move rectangle
     bool isMouseClickedOnStartHandle(const QPointF pnt);
   bool isMouseClickedOnEndHandle(const QPointF pnt);
   bool isMouseClickedOnRotateHandle(const QPointF pnt);
     bool isMouseClickedOnShape(const QPointF pnt);
     bool isClickedOnHandleOrShape(QPointF point);

     //setting the pen color
     QColor getPenColor();

     void setTranslate(QPointF pnt,QPointF pnt1);
     void setRotate(const QPointF &pnt,const QPointF &pnt1);
     void setScale(float x,float y);

     void translate_items(QPointF pnt,QPointF pnt1);

  //show handles
  void showHandles();
  //hide handles
  void hideHandles();

  //rotate the shapes
    void rotateShape(float angle);

     virtual QPointF getTranslate(){return QPointF(0,0);}
     virtual float getRotate(float angle){return 0;}
     virtual QPointF getScale(float x,float y){return QPointF(0,0);}

     virtual void BoundingBox();

     void print();

   ~Draw_RoundRect();

     QGraphicsPathItem *item;
     QGraphicsRectItem *Strt_Rect,*End_Rect;
     QGraphicsEllipseItem *Rot_Rect;
     QPointF bounding_strt_pnt,bounding_end_pnt;

     QVector<Draw_RoundRect*> round_rects;

     float angle;
     int radius;
   bool isObjectSelected;
     QRectF rect;
     QPointF prev_pos;
 private:

     QPointF StrtPnt,EndPnt,pnt;
     QPointF bounding_min_pnt,bounding_max_pnt;
     int draw_state;
     bool draw_mode;
     QPen pen;
     QBrush brush;

};


#endif // DRAW_ROUNDRECT_H
