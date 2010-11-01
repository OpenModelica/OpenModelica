#ifndef DRAW_LINE_H
#define DRAW_LINE_H

#include "basic.h"

class QGraphicsItem;
class QGraphicsScene;
class QGraphicsLineItem;
class QPen;
class QColor;
class QPointF;
class QGraphicsRectItem;

class Draw_Line
{
    public:
      Draw_Line();

      //Getting and setting lines initial and last positions
      QPointF getLineStartPnt();
      QPointF getLineEndPnt();
      QPointF getPnt();
      QPointF getBoundMinPnt();
      QPointF getBoundMaxPnt();

      void setLineStartPnt(QPointF strt_pnt);
      void setLineEndPnt(QPointF lst_pnt);
      void setPnt(QPointF pnt);


      //Getting and setting lines drawing states and drawing mode
      int getState();
      void setState(int State);

      bool getMode();
      void setMode(bool mode);

      //getting Rectangle Points
      QPointF getRectStartPnt();
      QPointF getRectEndPnt();

      //checking the mouse position to resize and move line
      int  get_strt_edge(QPointF pnt);
      int  get_end_edge(QPointF pnt);
      int  get_line(QPointF pnt);

      //setting the pen color
      QPen getPenColor();

      void translate(QPointF pnt,QPointF pnt1);

      bool Bounding_region(QPointF pnt);

      QPointF line_strt_pnt,line_end_pnt,pnt;
      QPointF bounding_strt_pnt,bounding_end_pnt;
      QGraphicsItem *item,*item1,*item2;

      Draw_Line *nxt;
      Draw_Line *prev;
  private:
      void Bounding_box();

      QPointF bounding_min_pnt,bounding_max_pnt;
      int draw_state;
      bool draw_mode;
      QPen* pen;


};



#endif // DRAW_LINE_H
