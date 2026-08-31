/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

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
