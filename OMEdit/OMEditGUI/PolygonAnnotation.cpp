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

#include "PolygonAnnotation.h"

PolygonAnnotation::PolygonAnnotation(QString shape, QGraphicsItem *parent)
    : ShapeAnnotation(parent)
{
    // initialize the Line Patterns map.
    this->mLinePatternsMap.insert("None", Qt::NoPen);
    this->mLinePatternsMap.insert("Solid", Qt::SolidLine);
    this->mLinePatternsMap.insert("Dash", Qt::DashLine);
    this->mLinePatternsMap.insert("Dot", Qt::DotLine);
    this->mLinePatternsMap.insert("DashDot", Qt::DashDotLine);
    this->mLinePatternsMap.insert("DashDotDot", Qt::DashDotDotLine);

    // initialize the Fill Patterns map.
    this->mFillPatternsMap.insert("None", Qt::NoBrush);
    this->mFillPatternsMap.insert("Solid", Qt::SolidPattern);
    this->mFillPatternsMap.insert("Horizontal", Qt::HorPattern);
    this->mFillPatternsMap.insert("Vertical", Qt::VerPattern);
    this->mFillPatternsMap.insert("Cross", Qt::CrossPattern);
    this->mFillPatternsMap.insert("Forward", Qt::FDiagPattern);
    this->mFillPatternsMap.insert("Backward", Qt::BDiagPattern);
    this->mFillPatternsMap.insert("CrossDiag", Qt::DiagCrossPattern);
    this->mFillPatternsMap.insert("HorizontalCylinder", Qt::LinearGradientPattern);
    this->mFillPatternsMap.insert("VerticalCylinder", Qt::LinearGradientPattern);
    this->mFillPatternsMap.insert("Sphere", Qt::RadialGradientPattern);

    // parse the shape to get the list of attributes of Polygon.
    QStringList list = StringHandler::getStrings(shape);
    if (list.size() < 8)
    {
        return;
    }

    // if first item of list is true then the Polygon should be visible.
    this->mVisible = static_cast<QString>(list.at(0)).contains("true");

    // second item of list contains the color.
    QStringList colorList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(1)));
    if (colorList.size() < 3)
    {
        return;
    }

    int red = static_cast<QString>(colorList.at(0)).toInt();
    int green = static_cast<QString>(colorList.at(1)).toInt();
    int blue = static_cast<QString>(colorList.at(2)).toInt();
    this->mLineColor = QColor (red, green, blue);

    // third item of list contains the color.
    QStringList fillColorList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(2)));
    if (fillColorList.size() < 3)
    {
        return;
    }

    red = static_cast<QString>(fillColorList.at(0)).toInt();
    green = static_cast<QString>(fillColorList.at(1)).toInt();
    blue = static_cast<QString>(fillColorList.at(2)).toInt();
    this->mFillColor = QColor (red, green, blue);

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

    // fifth item of list contains the Line Pattern.
    QString fillPattern = StringHandler::getLastWordAfterDot(list.at(4));
    QMap<QString, Qt::BrushStyle>::iterator fill_it;
    for (fill_it = this->mFillPatternsMap.begin(); fill_it != this->mFillPatternsMap.end(); ++fill_it)
    {
        if (fill_it.key() == fillPattern)
        {
            this->mFillPattern = fill_it.value();
            break;
        }
    }

    // sixth item of list contains the thickness.
    this->mThickness = static_cast<QString>(list.at(5)).toFloat();

    // seventh item of list contains the points.
    QStringList pointsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(6)));
    foreach (QString point, pointsList)
    {
        QStringList polygonPoints = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(point));
        if (polygonPoints.size() < 2)
            return;

        qreal x = static_cast<QString>(polygonPoints.at(0)).toFloat();
        qreal y = static_cast<QString>(polygonPoints.at(1)).toFloat();
        QPointF p (x, y);
        this->mPoints.append(p);
    }

    // eighth item of the list contains the corner radius.
    this->mSmooth = static_cast<QString>(list.at(7)).contains("true");
}

QRectF PolygonAnnotation::boundingRect() const
{
    return QRectF();
}

void PolygonAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(option);
    Q_UNUSED(widget);

    QPainterPath path;
    //painter->rotate(ShapeAnnotation::mRotationAngle);
    //painter->scale(ShapeAnnotation::mScaleX, ShapeAnnotation::mScaleY);

    switch (this->mFillPattern)
    {
    case Qt::LinearGradientPattern:
    case Qt::Dense1Pattern:
    case Qt::RadialGradientPattern:
        painter->setBrush(QBrush(this->mFillColor, Qt::SolidPattern));
            break;
    default:
        painter->setBrush(QBrush(this->mFillColor, this->mFillPattern));
        break;
    }
    painter->setPen(QPen(this->mLineColor, this->mThickness, this->mLinePattern, Qt::RoundCap, Qt::MiterJoin));

    QVector<QPointF> points;
    for (int i = 0 ; i < this->mPoints.size() ; i ++)
        points.append(this->mPoints.at(i));

    path.addPolygon(QPolygonF(points));
    painter->drawPath(path);
    painter->strokePath(path, this->mLineColor);
}
