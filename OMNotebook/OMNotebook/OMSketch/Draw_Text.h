#ifndef DRAW_TEXT_H
#define DRAW_TEXT_H

#include "basic.h"
class Draw_Text: public QGraphicsTextItem
{
   public:
     Draw_Text();
     Draw_Text(QPointF strt_pnt);

     //Getting and setting lines initial and last positions
     QPointF getStartPnt() {return StrtPnt;}
     QPointF getEndPnt() {return EndPnt;}

     void setStartPoint(QPointF strt_pnt);
     void setEndPoint(QPointF lst_pnt);

     void setDrawText(QString text);
     void getText();

     bool getMode();
     void setMode(bool mode);

     int getState();
     void setState(int State);

     //show handles
     void showHandles();
     //hide handles
     void hideHandles();

     //checking the mouse position to resize and move rectangle
     bool getStrtEdge(const QPointF pnt);
     bool getEndEdge(const QPointF pnt);
     bool getRotEdge(const QPointF pnt);
     bool getItemSelected(const QPointF pnt);

     void setEdgeRects();
     void updateEdgeRects();

     void setTranslate(QPointF pnt,QPointF pnt1);
     void setRotate(const QPointF &pnt,const QPointF &pnt1);
     void setScale(float x,float y);

     QGraphicsTextItem* item;
     QGraphicsRectItem *Strt_Rect,*End_Rect,*Bounding_Rect;
     QGraphicsEllipseItem *Rot_Rect;

     float angle;
     bool isObjectSelected;

   private:
      QPointF StrtPnt,EndPnt;
      QString text;
      bool draw_mode;
      int draw_state;
};

#endif // DRAW_TEXT_H
