/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2009, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * For more information about the Qt-library visit TrollTech's webpage 
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
 */

//Qt headers
#include <QPen>
#include <QGraphicsItem>
#include <QMessageBox>

//Std headers
#include <iostream>

//IAEX headers
#include "line2D.h"

using namespace std;

Line2D::Line2D(qreal x1, qreal y1, qreal x2, qreal y2, QPen newPen, 
               qreal width,  bool bCosmetic,
               QGraphicsItem* parent, QGraphicsScene* scene):
QGraphicsLineItem(x1, y1, x2, y2, parent, scene)
{
  //setFlag(flag, enabled);  
	setPen(newPen);
  pen().setWidth(width);
  pen().setCosmetic(bCosmetic);
}

Line2D::~Line2D()
{

}

QRectF Line2D::boundingRect() const
{
    const qreal x1 = line().p1().x();
    const qreal x2 = line().p2().x();
    const qreal y1 = line().p1().y();
    const qreal y2 = line().p2().y();
    qreal lx = qMin(x1, x2);
    qreal rx = qMax(x1, x2);
    qreal ty = qMin(y1, y2);
    qreal by = qMax(y1, y2);
    return QRectF(lx, ty, rx - lx, by - ty);
}
