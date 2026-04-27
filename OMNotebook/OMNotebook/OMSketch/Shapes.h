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

#ifndef SHAPES_H
#define SHAPES_H

#include "basic.h"

class Shapes:public QGraphicsItem
{
   public:
     Shapes(QPointF strt_pnt,QPointF end_pnt);
     ~Shapes(){}

     QPointF getStrtPnt();
     QPointF getEndPnt();

     void setStrtPnt(const QPointF &strt_pnt);
     void setEndPnt(const QPointF &end_pnt);

     virtual void boundingBox()=0;
     //virtual bool  getStrtEdge(const QPointF pnt)=0;
     //virtual bool  getEndEdge(const QPointF pnt)=0;
     //virtual bool objectSelected(const QPointF pnt)=0;

     //virtual void setTranslate(QPointF pnt,QPointF pnt1)=0;
     //virtual void setRotate(float angle)=0;
     //virtual void setScale(float x,float y)=0;

     virtual QPointF getTranslate(float x,int y)=0;
     virtual float getRotate(float angle)=0;
     virtual QPointF getScale(float x,float y)=0;

     void setGraphicsItem(QGraphicsItem *item);
     QGraphicsItem* getGraphicsItem();

  private:
     QPointF StrtPnt;
     QPointF EndPnt;
     QGraphicsItem *Item;

};

#endif // SHAPES_H
