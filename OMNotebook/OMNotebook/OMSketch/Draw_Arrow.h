#ifndef DRAW_ARROW_H
#define DRAW_ARROW_H
#include "basic.h"

class Draw_Arrow:public QGraphicsPathItem
{

  public:
   Draw_Arrow();
   //~Draw_Arc();

   QPointF getStartPnt();
   QPointF getEndPnt();
   QPointF getBoundMinPnt();
   QPointF getBoundMaxPnt();


   void setStartPoint(QPointF strt_pnt);
   void setEndPoint(QPointF lst_pnt);

   void setEdgeRects();
   void updateEdgeRects();
   void updateArrowPoints(QPointF updatePoint);

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

  //sets the brush and style
  void setBrush(const QBrush brush);
    void setBrushStyle(const int style);
  //returns the current brush
    QBrush getBrush();


    //checking the mouse position to resize and move rectangle
    bool isMouseClickedOnHandle(const QPointF pnt);
    bool isMouseClickedOnEndHandle(const QPointF pnt);
    bool isMouseClickedOnRotateHandle(const QPointF pnt);
    bool isMouseClickedOnShape(const QPointF pnt);
    bool isClickedOnHandleOrShape(QPointF point);

    //setting the pen color
    QColor getPenColor();

    void setTranslate(QPointF pnt,QPointF pnt1);
    void setRotate(const QPointF &pnt,const QPointF &pnt1);
    void setScale(float x,float y);

    virtual QPointF getTranslate(){return QPointF(0,0);}
    virtual float getRotate(float angle){return 0;}
    virtual QPointF getScale(float x,float y){return QPointF(0,0);}

    virtual void BoundingBox();
    void print();

    QPainterPath getArrow();
  QPainterPath drawArrow();
  //writes the shapes and shapes attributes to an image
  void drawImage(QPainter *painter,QString &text,QPointF point);

  //show handles
  void showHandles();
  //hide handles
  void hideHandles();

  //rotate the shapes
    void rotateShape(float angle);

    QGraphicsPathItem *item;
    QGraphicsRectItem *Strt_Rect,*End_Rect,*Bounding_Rect;
    QGraphicsEllipseItem *Rot_Rect;
    QPointF bounding_strt_pnt,bounding_end_pnt;
    int click,handle_index;
    float angle;
    QVector<QPointF> arrow_pnts;

  QVector<QGraphicsRectItem*> handles;

  bool isObjectSelected;

 private:
   QPointF StrtPnt,EndPnt;
   QPointF bounding_min_pnt,bounding_max_pnt;
   int draw_state;
   bool draw_mode;
   QPen pen;
   QBrush brush;

};


#endif // DRAW_ARROW_H
