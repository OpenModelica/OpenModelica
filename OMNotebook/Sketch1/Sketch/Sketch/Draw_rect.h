#ifndef DRAW_RECT_H
#define DRAW_RECT_H

#include "basic.h"

class Draw_rect
{
    public:
      Draw_rect();
     ~Draw_rect();

     void setRectStartPnt(QPointF pnt);
     void setRectEndPnt(QPointF pnt);

     QPointF getRectStartPnt();
     QPointF getRectEndPnt();


     QPointF getRectstartPnt();
     QPointF getRectendPnt();

     //Getting and setting rectangles drawing states and drawing mode
     int getState();
     void setState(int State);

     bool getMode();
     void setMode(bool mode);

     //checking the mouse position to resize and move rectangle
     int  get_strt_edge(QPointF pnt);
     int  get_end_edge(QPointF pnt);
     int  get_line(QPointF pnt);

     //setting the pen color
     QPen getPenColor();

     void translate(QPointF pnt,QPointF pnt1);

     bool Bounding_region(QPointF pnt);

     QPointF getBoundMinPnt();
     QPointF getBoundMaxPnt();

     QPointF rect_strt_pnt,rect_end_pnt,pnt;
     QPointF bounding_strt_pnt,bounding_end_pnt;
     QGraphicsItem *item,*item1,*item2;
 private:
     void Bounding_box();

     QPointF bounding_min_pnt,bounding_max_pnt;
     int draw_state;
     bool draw_mode;
     QPen* pen;

};

#endif // DRAW_RECT_H
