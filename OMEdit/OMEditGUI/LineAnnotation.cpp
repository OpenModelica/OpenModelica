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

#include "LineAnnotation.h"

LineAnnotation::LineAnnotation(QString shape, Component *pParent)
    : ShapeAnnotation(pParent), mpComponent(pParent)
{
    // initialize the Line Patterns map.
    this->mLinePatternsMap.insert("None", Qt::NoPen);
    this->mLinePatternsMap.insert("Solid", Qt::SolidLine);
    this->mLinePatternsMap.insert("Dash", Qt::DashLine);
    this->mLinePatternsMap.insert("Dot", Qt::DotLine);
    this->mLinePatternsMap.insert("DashDot", Qt::DashDotLine);
    this->mLinePatternsMap.insert("DashDotDot", Qt::DashDotDotLine);

    // parse the shape to get the list of attributes of Line.
    QStringList list = StringHandler::getStrings(shape);
    if (list.size() < 8)
    {
        return;
    }

    // if first item of list is true then the Line should be visible.
    this->mVisible = static_cast<QString>(list.at(0)).contains("true");

    int index = 0;
    if (mpComponent->mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
    {
        QStringList originList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(1)));
        mOrigin.setX(static_cast<QString>(originList.at(0)).toFloat());
        mOrigin.setY(static_cast<QString>(originList.at(1)).toFloat());

        mRotation = static_cast<QString>(list.at(2)).toFloat();
        index = 2;
    }

    // second item of list contains the points.
    index = index + 1;
    QStringList pointsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(index)));

    foreach (QString point, pointsList)
    {
        QStringList linePoints = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(point));
        if (linePoints.size() < 2)
        {
            return;
        }

        qreal x = static_cast<QString>(linePoints.at(0)).toFloat();
        qreal y = static_cast<QString>(linePoints.at(1)).toFloat();
        QPointF p (x, y);
        this->mPoints.append(p);
    }

    // third item of list contains the color.
    index = index + 1;
    QStringList colorList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(index)));
    if (colorList.size() < 3)
    {
        return;
    }

    int red = static_cast<QString>(colorList.at(0)).toInt();
    int green = static_cast<QString>(colorList.at(1)).toInt();
    int blue = static_cast<QString>(colorList.at(2)).toInt();

    this->mLineColor = QColor (red, green, blue);

    // fourth item of list contains the Line Pattern.
    index = index + 1;
    QString linePattern = StringHandler::getLastWordAfterDot(list.at(index));
    QMap<QString, Qt::PenStyle>::iterator it;
    for (it = this->mLinePatternsMap.begin(); it != this->mLinePatternsMap.end(); ++it)
    {
        if (it.key().compare(linePattern) == 0)
        {
            this->mLinePattern = it.value();
            break;
        }
    }

    // fifth item of list contains the Line thickness.
    index = index + 1;
    this->mThickness = static_cast<QString>(list.at(index)).toFloat();

    // sixth item of list contains the Line Arrows.
    index = index + 1;
    // Leave it for now.

    // seventh item of list contains the Line Arrow Size.
    index = index + 1;

    // eighth item of list contains the smooth.
    index = index + 1;
    if (mpComponent->mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
    {
        this->mSmooth = static_cast<QString>(list.at(index)).toLower().contains("smooth.bezier");
    }
    else if (mpComponent->mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION2X)
    {
        this->mSmooth = static_cast<QString>(list.at(index)).toLower().contains("true");
    }
}

QRectF LineAnnotation::boundingRect() const
{
    return QRectF();
}

void LineAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(option);
    Q_UNUSED(widget);

    drawLineAnnotaion(painter);
}

void LineAnnotation::drawLineAnnotaion(QPainter *painter)
{
    QPainterPath path;
    //painter->setPen(QPen(this->mLineColor, this->mThickness, this->mLinePattern, Qt::RoundCap, Qt::MiterJoin));
    painter->setPen(QPen(this->mLineColor, this->mThickness, this->mLinePattern));

    if (this->mPoints.size() > 0)
    {
        for (int i = 0 ; i < this->mPoints.size() ; i++)
        {
            QPointF p1 = this->mPoints.at(i);
            if (i == 0)
                path.moveTo(p1.x(), p1.y());

            //! @todo add the support for splines..........
            if (this->mSmooth)
            {

            }
            else
            {
                path.lineTo(p1.x(), p1.y());
            }
        }
        painter->strokePath(path, this->mLineColor);
    }
}
