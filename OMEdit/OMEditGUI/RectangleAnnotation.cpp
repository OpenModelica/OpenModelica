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

#include "RectangleAnnotation.h"

RectangleAnnotation::RectangleAnnotation(QString shape, Component *pParent)
    : ShapeAnnotation(pParent), mpCompnent(pParent)
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
    this->mFillPatternsMap.insert("VerticalCylinder", Qt::Dense1Pattern);
    this->mFillPatternsMap.insert("Sphere", Qt::RadialGradientPattern);

    // Remove { } from shape

    shape = shape.replace("{", "");
    shape = shape.replace("}", "");

    // parse the shape to get the list of attributes of Rectangle.
    QStringList list = StringHandler::getStrings(shape);
    if (list.size() < 16)
    {
        return;
    }

    // if first item of list is true then the Rectangle should be visible.
    this->mVisible = static_cast<QString>(list.at(0)).contains("true");

    int index = 0;
    if (mpCompnent->mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
    {
        mOrigin.setX(static_cast<QString>(list.at(1)).toFloat());
        mOrigin.setY(static_cast<QString>(list.at(2)).toFloat());

        mRotation = static_cast<QString>(list.at(3)).toFloat();
        index = 3;
    }

    // 2,3,4 items of list contains the line color.
    index = index + 1;
    int red, green, blue;

    red = static_cast<QString>(list.at(index)).toInt();
    index = index + 1;
    green = static_cast<QString>(list.at(index)).toInt();
    index = index + 1;
    blue = static_cast<QString>(list.at(index)).toInt();
    this->mLineColor = QColor (red, green, blue);

    // 5,6,7 items of list contains the fill color.
    index = index + 1;
    red = static_cast<QString>(list.at(index)).toInt();
    index = index + 1;
    green = static_cast<QString>(list.at(index)).toInt();
    index = index + 1;
    blue = static_cast<QString>(list.at(index)).toInt();
    this->mFillColor = QColor (red, green, blue);

    // 8 item of the list contains the line pattern.
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

    // 9 item of the list contains the fill pattern.
    index = index + 1;
    QString fillPattern = StringHandler::getLastWordAfterDot(list.at(index));
    QMap<QString, Qt::BrushStyle>::iterator fill_it;
    for (fill_it = this->mFillPatternsMap.begin(); fill_it != this->mFillPatternsMap.end(); ++fill_it)
    {
        if (fill_it.key().compare(fillPattern) == 0)
        {
            this->mFillPattern = fill_it.value();
            break;
        }
    }

    // 10 item of the list contains the thickness.
    index = index + 1;
    this->mThickness = static_cast<QString>(list.at(index)).toFloat();

    // 11 item of the list contains the border pattern.
    index = index + 1;
    QString borderPattern = StringHandler::getLastWordAfterDot(list.at(index));
    QMap<QString, Qt::BrushStyle>::iterator border_it;
    for (border_it = this->mBorderPatternsMap.begin(); border_it != this->mBorderPatternsMap.end(); ++border_it)
    {
        if (border_it.key() == borderPattern)
        {
            this->mBorderPattern = border_it.value();
            break;
        }
    }

    // 12, 13, 14, 15 items of the list contains the extent points of rectangle.
    index = index + 1;
    qreal x = static_cast<QString>(list.at(index)).toFloat();
    index = index + 1;
    qreal y = static_cast<QString>(list.at(index)).toFloat();
    QPointF p1 (x, y);
    index = index + 1;
    x = static_cast<QString>(list.at(index)).toFloat();
    index = index + 1;
    y = static_cast<QString>(list.at(index)).toFloat();
    QPointF p2 (x, y);

    this->mExtent.append(p1);
    this->mExtent.append(p2);

    // 16 item of the list contains the corner radius.
    index = index + 1;
    this->mCornerRadius = static_cast<QString>(list.at(index)).toFloat();
}

QRectF RectangleAnnotation::boundingRect() const
{
    return QRectF();
}

void RectangleAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(option);
    Q_UNUSED(widget);

    drawRectangleAnnotaion(painter);
}

void RectangleAnnotation::drawRectangleAnnotaion(QPainter *painter)
{
    QPainterPath path;
    QPointF p1 = this->mExtent.at(0);
    QPointF p2 = this->mExtent.at(1);

    qreal left = qMin(p1.x(), p2.x());
    qreal top = qMin(p1.y(), p2.y());
    qreal width = fabs(p1.x() - p2.x());
    qreal height = fabs(p1.y() - p2.y());

    QRectF rect (left, top, width, height);

    switch (this->mFillPattern)
    {
    case Qt::LinearGradientPattern:
        {
            QLinearGradient gradient(rect.center().x(), rect.center().y(), rect.center().x(), rect.y());
            gradient.setColorAt(0.0, this->mFillColor);
            gradient.setColorAt(1.0, this->mLineColor);
            gradient.setSpread(QGradient::ReflectSpread);
            painter->setBrush(gradient);
            break;
        }
    case Qt::Dense1Pattern:
        {
            QLinearGradient gradient(rect.center().x(), rect.center().y(), rect.x(), rect.center().y());
            gradient.setColorAt(0.0, this->mFillColor);
            gradient.setColorAt(1.0, this->mLineColor);
            gradient.setSpread(QGradient::ReflectSpread);
            painter->setBrush(gradient);
            break;
        }
    case Qt::RadialGradientPattern:
        {
            QRadialGradient gradient(rect.center().x(), rect.center().y(), width);
            gradient.setColorAt(0.0, this->mFillColor);
            gradient.setColorAt(1.0, this->mLineColor);
            gradient.setSpread(QGradient::ReflectSpread);
            painter->setBrush(gradient);
            break;
        }
    default:
        painter->setBrush(QBrush(this->mFillColor, this->mFillPattern));
        break;
    }

    painter->setPen(QPen(this->mLineColor, this->mThickness, this->mLinePattern));

    path.addRect(rect);
    painter->drawPath(path);
    painter->strokePath(path, this->mLineColor);
}
