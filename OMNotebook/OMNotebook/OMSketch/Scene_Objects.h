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

#ifndef SCENE_OBJECTS_H
#define SCENE_OBJECTS_H

#include "basic.h"
#include "Draw_Rectangle.h"


class Scene_Objects
{
  public:
    Scene_Objects();
    ~Scene_Objects();
    Scene_Objects *clone();
    void setObjects(int Object_type,int position);
    void setBoundPos(QPointF pnt, QPointF pnt1);
    void setObjectPos(QPointF pnt, QPointF pnt1);
    void CheckPnt(QPointF curr_pnt);
    int getObject(int &position);
    void setSelected(bool selected);
    bool getSelected();

    void setColor(int r, int g,int b);
    void setColor(const QColor rgb);
    QColor getColor();

    void setpen(const QPen pen);
    void setPenColor(const int r, const int g,const int b);
    void setPenStyle(const int style);
    void setPenWidth(const int width);
    QPen getpen();

    void setbrush(const QBrush brush);
    void setBrushColor(const int r,const int g,const int b);
    void setBrushStyle(const int style);
    QBrush getbrush();

    void print();
    QPointF ObjectStrtPnt,ObjectEndPnt,pnt,ObjectStrtBoundPnt,ObjectEndBoundPnt;
    bool selected;
    QVector<QPointF> pnts;
    int ObjectId,ObjectPos,ObjectState,ObjectIndx;
    int rotation;
    QGraphicsPathItem *item;
    QGraphicsRectItem *Strt_Rect,*End_Rect;
    QGraphicsEllipseItem *Rot_Rect;
    QPen pen;
    QBrush brush;
};

#endif // SCENE_OBJECTS_H
