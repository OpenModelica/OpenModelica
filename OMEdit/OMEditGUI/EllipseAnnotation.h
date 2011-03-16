/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 *
 */

#ifndef ELLIPSEANNOTATION_H
#define ELLIPSEANNOTATION_H

#include "ShapeAnnotation.h"
#include "Component.h"

class OMCProxy;

class EllipseAnnotation : public ShapeAnnotation
{
    Q_OBJECT
public:
    EllipseAnnotation(QString shape, Component *pParent);
    EllipseAnnotation(GraphicsView *graphicsView, QGraphicsItem *pParent = 0);
    EllipseAnnotation(QString shape, GraphicsView *graphicsView, QGraphicsItem *pParent = 0);
    QRectF boundingRect() const;
    QPainterPath shape() const;
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
    void drawEllipseAnnotaion(QPainter *painter);
    void addPoint(QPointF point);
    void updateEndPoint(QPointF point);
    void drawRectangleCornerItems();
    QString getShapeAnnotation();
    void parseShapeAnnotation(QString shape, OMCProxy *omc);

    Component *mpComponent;
public slots:
    void updatePoint(int index, QPointF point);
};

#endif // ELLIPSEANNOTATION_H
