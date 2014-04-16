#ifndef DRAW_TRIANGLE_H
#define DRAW_TRIANGLE_H

#include "basic.h"

class Draw_Triangle:public QGraphicsPathItem
{

  public:
   Draw_Triangle();
   //~Draw_Arc();

   QPointF getStartPnt();
   QPointF getEndPnt();
   QPointF getHeightPnt();
   QPointF getBoundMinPnt();
   QPointF getBoundMaxPnt();


   void setStartPoint(QPointF strt_pnt);
   void setEndPoint(QPointF lst_pnt);
   void setHeightPoint(QPointF curve_pnt);

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

  //sets the brush and style
  void setBrush(const QBrush brush);
    void setBrushStyle(const int style);
  //returns the current brush
    QBrush getBrush();


    //checking the mouse position to resize and move rectangle
    bool isMouseClickedOnHandle(const QPointF pnt);
  bool isMouseClickedOnRotateHandle(const QPointF pnt);
    bool isMouseClickedOnShape(const QPointF pnt);
    bool get_line(QPointF pnt);
  bool isClickedOnHandleOrShape(QPointF point);

    //setting the pen color
    QColor getPenColor();

    void setTranslate(QPointF pnt,QPointF pnt1);
    void setRotate(const QPointF &pnt,const QPointF &pnt1);
    void setScale(float x,float y);

    void translate_items(QPointF pnt,QPointF pnt1);

    virtual QPointF getTranslate(){return QPointF(0,0);}
    virtual float getRotate(float angle){return 0;}
    virtual QPointF getScale(float x,float y){return QPointF(0,0);}

    virtual void BoundingBox();
    void print();

    QPainterPath getTriangle();
  //writes the shapes and shapes attributes to an image
  void drawImage(QPainter *painter,QString &text,QPointF point);

  //show handles
  void showHandles();
  //hide handles
  void hideHandles();

    //rotate the shapes
    void rotateShape(float angle);

    QGraphicsPathItem *item;
    QGraphicsRectItem *Strt_Rect,*End_Rect,*Height_Rect,*Bounding_Rect;
    QGraphicsEllipseItem *Rot_Rect;
    QPointF bounding_strt_pnt,bounding_end_pnt;
    int click,handle_index;
    float angle;
  bool isObjectSelected;
    QVector<QPointF> triangle_pnts;

  QVector<QGraphicsRectItem*> handles;

 private:
   QPointF StrtPnt,EndPnt,HeightPnt;
   QPointF bounding_min_pnt,bounding_max_pnt;
   int draw_state;
   bool draw_mode;
   QPen pen;
   QBrush brush;

};

#endif // DRAW_TRIANGLE_H
