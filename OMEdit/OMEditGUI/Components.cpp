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

#include "Components.h"

Components::Components(QString value, QString className, OMCProxy *omc)
    : mIconAnnotationString(value), mClassName(className)
{
    mpIcon = new IconAnnotation(value, "", className, omc);
    if (mpIcon->mRectangle.width() < 1)
        return;
    mpIcon->getClassComponents(className, true);

    this->mIconPixmap = QPixmap(mpIcon->mRectangle.width() * 0.10, mpIcon->mRectangle.height() * 0.10);
    this->mIconPixmap.fill(QColor(Qt::transparent));
    QPainter painter(&this->mIconPixmap);
    painter.scale(1.0, -1.0);
    painter.scale(0.82, 0.82);
    painter.setWindow(mpIcon->mRectangle.toRect());

    foreach (LineAnnotation *line, mpIcon->mpLinesList)
        line->drawLineAnnotaion(&painter);

    foreach (PolygonAnnotation *poly, mpIcon->mpPolygonsList)
        poly->drawPolygonAnnotaion(&painter);

    foreach (RectangleAnnotation *rect, mpIcon->mpRectanglesList)
        rect->drawRectangleAnnotaion(&painter);

    foreach (EllipseAnnotation *ellipse, mpIcon->mpEllipsesList)
        ellipse->drawEllipseAnnotaion(&painter);


    foreach (InheritanceAnnotation *inheritance, mpIcon->mpInheritanceList)
    {
        foreach (LineAnnotation *line, inheritance->mpLinesList)
            line->drawLineAnnotaion(&painter);

        foreach (PolygonAnnotation *poly, inheritance->mpPolygonsList)
            poly->drawPolygonAnnotaion(&painter);

        foreach (RectangleAnnotation *rect, inheritance->mpRectanglesList)
            rect->drawRectangleAnnotaion(&painter);

        foreach (EllipseAnnotation *ellipse, inheritance->mpEllipsesList)
            ellipse->drawEllipseAnnotaion(&painter);
    }

    foreach (ComponentAnnotation *component, mpIcon->mpComponentsList)
    {
        painter.save();
        painter.translate(component->mPositionX, component->mPositionY);
        painter.scale(Helper::globalXScale, Helper::globalYScale);
        foreach (LineAnnotation *line, component->mpLinesList)
            line->drawLineAnnotaion(&painter);

        foreach (PolygonAnnotation *poly, component->mpPolygonsList)
            poly->drawPolygonAnnotaion(&painter);

        foreach (RectangleAnnotation *rect, component->mpRectanglesList)
            rect->drawRectangleAnnotaion(&painter);

        foreach (EllipseAnnotation *ellipse, component->mpEllipsesList)
            ellipse->drawEllipseAnnotaion(&painter);
        painter.restore();
    }

    painter.end();
}

QPixmap Components::getIcon()
{
    return mIconPixmap;
}
