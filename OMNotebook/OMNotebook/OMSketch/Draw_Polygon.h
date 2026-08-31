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

#ifndef DRAW_POLYGON_H
#define DRAW_POLYGON_H

#include "basic.h"


class Draw_Polygon:QGraphicsPathItem
{
  public:

   struct EdgeLine
   {
     QPointF pnt;
     int next_line;
     int prev_line;
   };

   Draw_Polygon();
   ~Draw_Polygon();

   //stores the intial or starting point of the polygon
   void setStartPoint(QPointF pnt);

   //stores the intial or starting point of the polygon
   void setEndPoint(QPointF pnt);

   //sets the remaing points of polygon
   void setPnt(QPointF pnt);

   //get the start and edges of polygon
   QPointF getStartPnt();
   QPointF getEndPnt();

   //set the draw mode
   void set_draw_mode(bool);

   //get draw mode
   bool get_draw_mode();

   //checking the mouse position to resize and move line
   bool isMouseClickedOnHandle(const QPointF pnt);
   bool isMouseClickedOnShape(const QPointF pnt);
   bool isMouseClickedOnRotateHandle(const QPointF pnt);
   bool isClickedOnHandleOrShape(QPointF point);

   void setTranslate(QPointF pnt,QPointF pnt1);
   void setRotate(const QPointF &pnt,const QPointF &pnt1);
   void setScale(float x,float y);

   //void translate_items(QPointF pnt,QPointF pnt1);

   virtual QPointF getTranslate(){return QPointF(0,0);}
   virtual float getRotate(float angle){return 0;}
   virtual QPointF getScale(float x,float y){return QPointF(0,0);}

   void setLine(QLineF pline);
   void setLine(int indx,QLineF pline);
   void setLines(QVector<QGraphicsLineItem*> plines);


   QGraphicsLineItem* getLine();
   QGraphicsLineItem* getLine(int indx);
   QVector<QGraphicsLineItem*> getLines();
   void clear_lines();

   QPainterPath getPolygon();
   void drawEdges();
   QPainterPath getPolygon(int indx,QPointF pnt1,QPointF pnt2);

   //writes the shapes and shapes attributes to an image
   void drawImage(QPainter *painter,QString &text,QPointF point);

   int getState();
   void setState(int State);

   void setPolygonDrawn(bool draw_state)
   {
        polygon_draw_state=draw_state;
   }

   bool getPolygonDrawn()
   {
        return polygon_draw_state;
   }

   void setPen(const QColor color);
   void setPenStyle(const int style);
   void setPenWidth(const int width);
   QPen getPen();

   void setBrush(const QBrush brush);
   void setBrushStyle(const int style);
   QBrush getBrush();

   //show handles
   void showHandles();
   //hide handles
   void hideHandles();

   //return the handle index
   int getHandelIndex();

   //rotate the shapes
   void rotateShape(float angle);


   QVector<QGraphicsLineItem*> lines;

   QGraphicsPathItem* item;
   QVector<QGraphicsRectItem*> edge_items;
   QGraphicsEllipseItem *Rot_Rect;

   QVector<QPointF> poly_pnts;

   QVector<EdgeLine> edgelines;

   float angle;
   bool isObjectSelected;

 private:

   void setEdgeLines();

   bool polygon_draw_mode,polygon_draw_state;
   int draw_state,handle_index;
   QGraphicsLineItem* line;
   QPen pen;
   QBrush brush;

};

#endif // DRAW_POLYGON_H
