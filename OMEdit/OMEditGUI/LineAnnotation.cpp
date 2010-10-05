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

LineAnnotation::LineAnnotation(QString shape, QGraphicsItem *parent)
    : ShapeAnnotation(parent)
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

    // second item of list contains the points.
    QStringList pointsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(1)));

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
    QStringList colorList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(2)));
    if (colorList.size() < 3)
    {
        return;
    }

    int red = static_cast<QString>(colorList.at(0)).toInt();
    int green = static_cast<QString>(colorList.at(1)).toInt();
    int blue = static_cast<QString>(colorList.at(2)).toInt();

    this->mLineColor = QColor (red, green, blue);

    // fourth item of list contains the Line Pattern.
    QString linePattern = StringHandler::getLastWordAfterDot(list.at(3));
    QMap<QString, Qt::PenStyle>::iterator it;
    for (it = this->mLinePatternsMap.begin(); it != this->mLinePatternsMap.end(); ++it)
    {
        if (it.key() == linePattern)
        {
            this->mLinePattern = it.value();
            break;
        }
    }

    // fifth item of list contains the Line thickness.
    this->mThickness = static_cast<QString>(list.at(4)).toFloat();

    // sixth item of list contains the Line Arrows.
    // Leave it for now.

    // seventh item of list contains the Line Arrow Size.

    // eighth item of list contains the smooth.
    this->mSmooth = static_cast<QString>(list.at(7)).contains("true");
}

QRectF LineAnnotation::boundingRect() const
{
    return QRectF();
}

void LineAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(option);
    Q_UNUSED(widget);

    QPainterPath path;
    //painter->rotate(ShapeAnnotation::mRotationAngle);
    //painter->scale(ShapeAnnotation::mScaleX, ShapeAnnotation::mScaleY);
    painter->setPen(QPen(this->mLineColor, this->mThickness, this->mLinePattern, Qt::RoundCap, Qt::MiterJoin));

    if (this->mPoints.size() > 0)
    {
        for (int i = 0 ; i < this->mPoints.size() ; i++)
        {
            QPointF p1 = this->mPoints.at(i);
            if (i == 0)
                path.moveTo(p1.x(), p1.y());
            if (this->mSmooth)
            {

            }
            else
            {
                path.lineTo(p1.x(), p1.y());
            }
        }
        painter->drawPath(path);
        painter->strokePath(path, this->mLineColor);
    }
}

void LineAnnotation::drawLineAnnotaion(QPainter *painter)
{
    //painter->setBackground(QBrush(Qt::transparent));
    //painter->setPen(QPen(QBrush(this->mColor), static_cast<qreal>(this->mThickness), this->mLinePattern));
    painter->setPen(QPen(QBrush(Qt::blue), static_cast<qreal>(this->mThickness), this->mLinePattern));
    if (!(this->mPoints.size() < 2))
    {
        painter->drawLine(this->mPoints.at(0), this->mPoints.at(1));
    }
}
