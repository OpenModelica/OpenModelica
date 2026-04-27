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

#ifndef DRAW_RECTANGLE_H
#define DRAW_RECTANGLE_H

#include "basic.h"

class QGraphicsItem;
class QGraphicsPathItem;
class QPainter;
class QStyleOptionGraphicsItem;
class QWidget;
class QRectF;

class Draw_Rectangle:public QGraphicsPathItem
{
  public:
    Draw_Rectangle();

    //Getting and setting lines initial and last positions
    QPointF getStartPnt();
    QPointF getEndPnt();
    QPointF getPnt();
    QPointF getBoundMinPnt();
    QPointF getBoundMaxPnt();

    QPainterPath getRect(QPointF pnt,QPointF pnt1);
    QPainterPath getRotRect(QPointF pnt,QPointF pnt1);

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

    QPointF rotationStartPoint,rotationEndPoint;

    //show handles
    void showHandles();
    //hide handles
    void hideHandles();

    //rotate the shapes
    void rotateShape(float angle);

    virtual QPointF getTranslate(){return QPointF(0,0);}
    virtual float getRotate(float angle){return 0;}
    virtual QPointF getScale(float x,float y){return QPointF(0,0);}


    QGraphicsPathItem *item;
    QGraphicsRectItem *Strt_Rect,*End_Rect;
    QGraphicsEllipseItem *Rot_Rect;

    QPointF bounding_strt_pnt,bounding_end_pnt;

    QVector<Draw_Rectangle*> rects;

    float angle;
    bool isObjectSelected;

  private:
    void print();

    QPointF StrtPnt,EndPnt;
    QPointF bounding_min_pnt,bounding_max_pnt;
    int draw_state;
    bool draw_mode;
    QPainterPath path1;
    QPen pen;
    QRectF rect;
    QBrush brush;
};

#endif // DRAW_RECTANGLE_H
