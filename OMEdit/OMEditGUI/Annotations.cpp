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

#include "Annotations.h"
#include "StringHandler.h"

// Shape Annotation Class
ShapeAnnotation::ShapeAnnotation(QGraphicsItem *parent)
    : QGraphicsItem(parent)
{

}

// Line Annotation Class
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

// Polygon Annotation Class
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

// Rectangle Annotation Class
RectangleAnnotation::RectangleAnnotation(QString shape, QGraphicsItem *parent)
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

    // 2,3,4 items of list contains the line color.
    int red, green, blue;

    red = static_cast<QString>(list.at(1)).toInt();
    green = static_cast<QString>(list.at(2)).toInt();
    blue = static_cast<QString>(list.at(3)).toInt();
    this->mLineColor = QColor (red, green, blue);

    // 5,6,7 items of list contains the fill color.
    red = static_cast<QString>(list.at(4)).toInt();
    green = static_cast<QString>(list.at(5)).toInt();
    blue = static_cast<QString>(list.at(6)).toInt();
    this->mFillColor = QColor (red, green, blue);

    // 8 item of the list contains the line pattern.
    QString linePattern = StringHandler::getLastWordAfterDot(list.at(7));
    QMap<QString, Qt::PenStyle>::iterator it;
    for (it = this->mLinePatternsMap.begin(); it != this->mLinePatternsMap.end(); ++it)
    {
        if (it.key() == linePattern)
        {
            this->mLinePattern = it.value();
            break;
        }
    }

    // 9 item of the list contains the fill pattern.
    QString fillPattern = StringHandler::getLastWordAfterDot(list.at(8));
    QMap<QString, Qt::BrushStyle>::iterator fill_it;
    for (fill_it = this->mFillPatternsMap.begin(); fill_it != this->mFillPatternsMap.end(); ++fill_it)
    {
        if (fill_it.key() == fillPattern)
        {
            this->mFillPattern = fill_it.value();
            break;
        }
    }

    // 10 item of the list contains the thickness.
    this->mThickness = static_cast<QString>(list.at(9)).toFloat();

    // 11 item of the list contains the border pattern.
    QString borderPattern = StringHandler::getLastWordAfterDot(list.at(10));
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
    qreal x = static_cast<QString>(list.at(11)).toFloat();
    qreal y = static_cast<QString>(list.at(12)).toFloat();
    QPointF p1 (x, y);
    x = static_cast<QString>(list.at(13)).toFloat();
    y = static_cast<QString>(list.at(14)).toFloat();
    QPointF p2 (x, y);

    this->mExtent.append(p1);
    this->mExtent.append(p2);

    // 16 item of the list contains the corner radius.

    this->mCornerRadius = static_cast<QString>(list.at(15)).toFloat();
}

QRectF RectangleAnnotation::boundingRect() const
{
    return QRectF();
}

void RectangleAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(option);
    Q_UNUSED(widget);

    QPainterPath path;
    //painter->rotate(ShapeAnnotation::mRotationAngle);
    //painter->scale(ShapeAnnotation::mScaleX, ShapeAnnotation::mScaleY);
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

    painter->setPen(QPen(this->mLineColor, this->mThickness, this->mLinePattern, Qt::RoundCap, Qt::MiterJoin));

    path.addRect(rect);
    painter->drawPath(path);
    painter->strokePath(path, this->mLineColor);
}

// Ellipse Annotation Class
EllipseAnnotation::EllipseAnnotation(QString shape, QGraphicsItem *parent)
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

    // Remove { } from shape

    shape = shape.replace("{", "");
    shape = shape.replace("}", "");

    // parse the shape to get the list of attributes of Ellipse.
    QStringList list = StringHandler::getStrings(shape);
    if (list.size() < 14)
    {
        return;
    }

    // if first item of list is true then the Ellipse should be visible.
    this->mVisible = static_cast<QString>(list.at(0)).contains("true");

    // 2,3,4 items of list contains the line color.
    int red, green, blue;

    red = static_cast<QString>(list.at(1)).toInt();
    green = static_cast<QString>(list.at(2)).toInt();
    blue = static_cast<QString>(list.at(3)).toInt();
    this->mLineColor = QColor (red, green, blue);

    // 5,6,7 items of list contains the fill color.
    red = static_cast<QString>(list.at(4)).toInt();
    green = static_cast<QString>(list.at(5)).toInt();
    blue = static_cast<QString>(list.at(6)).toInt();
    this->mFillColor = QColor (red, green, blue);

    // 8 item of the list contains the line pattern.
    QString linePattern = StringHandler::getLastWordAfterDot(list.at(7));
    QMap<QString, Qt::PenStyle>::iterator it;
    for (it = this->mLinePatternsMap.begin(); it != this->mLinePatternsMap.end(); ++it)
    {
        if (it.key() == linePattern)
        {
            this->mLinePattern = it.value();
            break;
        }
    }

    // 9 item of the list contains the fill pattern.
    QString fillPattern = StringHandler::getLastWordAfterDot(list.at(8));
    QMap<QString, Qt::BrushStyle>::iterator fill_it;
    for (fill_it = this->mFillPatternsMap.begin(); fill_it != this->mFillPatternsMap.end(); ++fill_it)
    {
        if (fill_it.key() == fillPattern)
        {
            this->mFillPattern = fill_it.value();
            break;
        }
    }

    // 10 item of the list contains the thickness.
    this->mThickness = static_cast<QString>(list.at(9)).toFloat();

    // 11, 12, 13, 14 items of the list contains the extent points of Ellipse.
    qreal x = static_cast<QString>(list.at(10)).toFloat();
    qreal y = static_cast<QString>(list.at(11)).toFloat();
    QPointF p1 (x, y);
    x = static_cast<QString>(list.at(12)).toFloat();
    y = static_cast<QString>(list.at(13)).toFloat();
    QPointF p2 (x, y);

    this->mExtent.append(p1);
    this->mExtent.append(p2);
}

QRectF EllipseAnnotation::boundingRect() const
{
    return QRectF();
}

void EllipseAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(option);
    Q_UNUSED(widget);

    QPainterPath path;
    //painter->rotate(ShapeAnnotation::mRotationAngle);
    //painter->scale(ShapeAnnotation::mScaleX, ShapeAnnotation::mScaleY);

    QPointF p1 = this->mExtent.at(0);
    QPointF p2 = this->mExtent.at(1);

    qreal left = qMin(p1.x(), p2.x());
    qreal top = qMin(p1.y(), p2.y());
    qreal width = fabs(p1.x() - p2.x());
    qreal height = fabs(p1.y() - p2.y());

    QRectF ellipse (left, top, width, height);

    switch (this->mFillPattern)
    {
    case Qt::LinearGradientPattern:
        {
            QLinearGradient gradient(ellipse.center().x(), ellipse.center().y(), ellipse.center().x(), ellipse.y());
            gradient.setColorAt(0.0, this->mFillColor);
            gradient.setColorAt(1.0, this->mLineColor);
            gradient.setSpread(QGradient::ReflectSpread);
            painter->setBrush(gradient);
            break;
        }
    case Qt::Dense1Pattern:
        {
            QLinearGradient gradient(ellipse.center().x(), ellipse.center().y(), ellipse.x(), ellipse.center().y());
            gradient.setColorAt(0.0, this->mFillColor);
            gradient.setColorAt(1.0, this->mLineColor);
            gradient.setSpread(QGradient::ReflectSpread);
            painter->setBrush(gradient);
            break;
        }
    case Qt::RadialGradientPattern:
        {
            QRadialGradient gradient(ellipse.center().x(), ellipse.center().y(), width);
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
    painter->setPen(QPen(this->mLineColor, this->mThickness, this->mLinePattern, Qt::RoundCap, Qt::MiterJoin));

    path.addEllipse(ellipse);
    painter->drawPath(path);
    painter->strokePath(path, this->mLineColor);
}

// Text Annotation Class
TextAnnotation::TextAnnotation(QString shape, QGraphicsItem *parent)
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

    // initialize font weigth and italic property.
    this->mFontWeight = -1;
    this->mFontItalic = false;

    // Remove { } from shape

    shape = shape.replace("{", "");
    shape = shape.replace("}", "");

    // parse the shape to get the list of attributes of Text Annotation.
    QStringList list = StringHandler::getStrings(shape);
    if (list.size() < 17)
    {
        return;
    }

    // if first item of list is true then the Text Annotation should be visible.
    this->mVisible = static_cast<QString>(list.at(0)).contains("true");

    // 2,3,4 items of list contains the line color.
    int red, green, blue;

    red = static_cast<QString>(list.at(1)).toInt();
    green = static_cast<QString>(list.at(2)).toInt();
    blue = static_cast<QString>(list.at(3)).toInt();
    this->mLineColor = QColor (red, green, blue);

    // 5,6,7 items of list contains the fill color.
    red = static_cast<QString>(list.at(4)).toInt();
    green = static_cast<QString>(list.at(5)).toInt();
    blue = static_cast<QString>(list.at(6)).toInt();
    this->mFillColor = QColor (red, green, blue);

    // 8 item of the list contains the line pattern.
    QString linePattern = StringHandler::getLastWordAfterDot(list.at(7));
    QMap<QString, Qt::PenStyle>::iterator it;
    for (it = this->mLinePatternsMap.begin(); it != this->mLinePatternsMap.end(); ++it)
    {
        if (it.key() == linePattern)
        {
            this->mLinePattern = it.value();
            break;
        }
    }

    // 9 item of the list contains the fill pattern.
    QString fillPattern = StringHandler::getLastWordAfterDot(list.at(8));
    QMap<QString, Qt::BrushStyle>::iterator fill_it;
    for (fill_it = this->mFillPatternsMap.begin(); fill_it != this->mFillPatternsMap.end(); ++fill_it)
    {
        if (fill_it.key() == fillPattern)
        {
            this->mFillPattern = fill_it.value();
            break;
        }
    }

    // 10 item of the list contains the thickness.
    this->mThickness = static_cast<QString>(list.at(9)).toFloat();

    // 11, 12, 13, 14 items of the list contains the extent points of Ellipse.
    qreal x = static_cast<QString>(list.at(10)).toFloat();
    qreal y = static_cast<QString>(list.at(11)).toFloat();
    QPointF p1 (x, y);
    x = static_cast<QString>(list.at(12)).toFloat();
    y = static_cast<QString>(list.at(13)).toFloat();
    QPointF p2 (x, y);

    this->mExtent.append(p1);
    this->mExtent.append(p2);

    // 15 item of the list contains the text string.
    this->mTextString = StringHandler::removeFirstLastQuotes(list.at(14));

    // 16 item of the list contains the font size.
    this->mFontSize = static_cast<QString>(list.at(15)).toInt();

    // 17 item of the list contains the font name.
    this->mFontName = StringHandler::removeFirstLastQuotes(list.at(16));

    this->mDefaultFontSize = 25;
}

QRectF TextAnnotation::boundingRect() const
{
    return QRectF();
}

void TextAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(option);
    Q_UNUSED(widget);

    QPainterPath path;
    QPointF p1 = this->mExtent.at(0);
    QPointF p2 = this->mExtent.at(1);

    qreal left = qMin(p1.x(), p2.x());
    qreal top = qMin(p1.y(), p2.y());
    qreal width = fabs(p1.x() - p2.x());
    qreal height = fabs(p1.y() - p2.y());

    top = -top;
    height = -height;

    QRectF rect (left, top, width, height);

    /*switch (this->mFillPattern)
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
    case Qt::NoBrush:
        {
            painter->setBrush(QBrush(this->mFillColor, Qt::SolidPattern));
        }
    default:
        painter->setBrush(QBrush(this->mFillColor, this->mFillPattern));
        break;
    }*/
    painter->scale(1.0, -1.0);
    painter->setPen(QPen(this->mFillColor, this->mThickness, this->mLinePattern));
    painter->setBrush(QBrush(this->mFillColor, Qt::SolidPattern));
    painter->setFont(QFont(this->mFontName, this->mDefaultFontSize + this->mFontSize, this->mFontWeight, this->mFontItalic));
    painter->drawText(rect, Qt::AlignCenter | Qt::AlignVCenter, this->mTextString, &rect);
}

//Inheritance Annotation Class
InheritanceAnnotation::InheritanceAnnotation(QString value, QString className, OMCProxy *omc,
                                             GraphicsScene *graphicsScene, GraphicsView *graphicsView,
                                             IconAnnotation *pIcon, QGraphicsItem *parent)
    : ShapeAnnotation(parent), mClassName(className), mpOMCProxy(omc), mpGraphicsScene(graphicsScene),
      mpGraphicsView(graphicsView)
{
    setFlag(QGraphicsItem::ItemStacksBehindParent);
    mpParentIcon = pIcon;
    parseIconAnnotationString(value);
}

void InheritanceAnnotation::parseIconAnnotationString(QString value)
{
    value = StringHandler::removeFirstLastCurlBrackets(value);
    if (value.isEmpty())
    {
        return;
    }
    QStringList list = StringHandler::getStrings(value);
    if (list.size() < 4)
    {
        return;
    }
    qreal x1, x2, y1, y2, width, height;
    x1 = static_cast<QString>(list.at(0)).toFloat();
    y1 = static_cast<QString>(list.at(1)).toFloat();
    x2 = static_cast<QString>(list.at(2)).toFloat();
    y2 = static_cast<QString>(list.at(3)).toFloat();
    width = fabs(x1 - x2);
    height = fabs(y1 - y2);
    this->mRectangle = QRectF (x1, y1, width, height);

    if (list.size() < 5)
    {
        return;
    }

    // Check with Mohsen about the new IconAnnotation Standard Problem of SimForge

    QStringList shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(4)), '(', ')');

    // Now parse the shapes available in list

    foreach (QString shape, shapesList)
    {
        shape = StringHandler::removeFirstLastCurlBrackets(shape);
        if (shape.startsWith("Line"))
        {
            shape = shape.mid(QString("Line").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            LineAnnotation *lineAnnotation = new LineAnnotation(shape, this);
            Q_UNUSED(lineAnnotation);
        }
        if (shape.startsWith("Polygon"))
        {
            shape = shape.mid(QString("Polygon").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            PolygonAnnotation *polygonAnnotation = new PolygonAnnotation(shape, this);
            Q_UNUSED(polygonAnnotation);
        }
        if (shape.startsWith("Rectangle"))
        {
            shape = shape.mid(QString("Rectangle").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            RectangleAnnotation *rectangleAnnotation = new RectangleAnnotation(shape, this);
            Q_UNUSED(rectangleAnnotation);
        }
        if (shape.startsWith("Ellipse"))
        {
            shape = shape.mid(QString("Ellipse").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            EllipseAnnotation *ellipseAnnotation = new EllipseAnnotation(shape, this);
            Q_UNUSED(ellipseAnnotation);
        }
        if (shape.startsWith("Text"))
        {
            shape = shape.mid(QString("Text").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            TextAnnotation *textAnnotation = new TextAnnotation(shape, this);
            Q_UNUSED(textAnnotation);
        }
    }
}

QRectF InheritanceAnnotation::boundingRect() const
{
    return this->mRectangle;
}

void InheritanceAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(painter);
    Q_UNUSED(option);
    Q_UNUSED(widget);
}

//Component Annotation Class
ComponentAnnotation::ComponentAnnotation(QString value, QString className, QString transformationStr, OMCProxy *omc,
                                         GraphicsScene *graphicsScene, GraphicsView *graphicsView,
                                         IconAnnotation *pIcon, QGraphicsItem *parent)
    : ShapeAnnotation(parent), mClassName(className), mpOMCProxy(omc), mpGraphicsScene(graphicsScene),
      mpGraphicsView(graphicsView)
{
    mpParentIcon = pIcon;
    parseIconAnnotationString(value);
    parseTransformationString(transformationStr);
    connect(this, SIGNAL(componentClicked(ComponentAnnotation*)), mpGraphicsView, SLOT(addConnector(ComponentAnnotation*)));
}

void ComponentAnnotation::parseIconAnnotationString(QString value)
{
    value = StringHandler::removeFirstLastCurlBrackets(value);
    if (value.isEmpty())
    {
        return;
    }
    QStringList list = StringHandler::getStrings(value);
    if (list.size() < 4)
    {
        return;
    }
    qreal x1, x2, y1, y2, width, height;
    x1 = static_cast<QString>(list.at(0)).toFloat();
    y1 = static_cast<QString>(list.at(1)).toFloat();
    x2 = static_cast<QString>(list.at(2)).toFloat();
    y2 = static_cast<QString>(list.at(3)).toFloat();
    width = fabs(x1 - x2);
    height = fabs(y1 - y2);
    this->mRectangle = QRectF (x1, y1, width, height);

    if (list.size() < 5)
    {
        return;
    }

    // Check with Mohsen about the new IconAnnotation Standard Problem of SimForge

    QStringList shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(4)), '(', ')');

    // Now parse the shapes available in list

    foreach (QString shape, shapesList)
    {
        shape = StringHandler::removeFirstLastCurlBrackets(shape);
        if (shape.startsWith("Line"))
        {
            shape = shape.mid(QString("Line").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            LineAnnotation *lineAnnotation = new LineAnnotation(shape, this);
            Q_UNUSED(lineAnnotation);
        }
        if (shape.startsWith("Polygon"))
        {
            shape = shape.mid(QString("Polygon").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            PolygonAnnotation *polygonAnnotation = new PolygonAnnotation(shape, this);
            Q_UNUSED(polygonAnnotation);
        }
        if (shape.startsWith("Rectangle"))
        {
            shape = shape.mid(QString("Rectangle").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            RectangleAnnotation *rectangleAnnotation = new RectangleAnnotation(shape, this);
            Q_UNUSED(rectangleAnnotation);
        }
        if (shape.startsWith("Ellipse"))
        {
            shape = shape.mid(QString("Ellipse").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            EllipseAnnotation *ellipseAnnotation = new EllipseAnnotation(shape, this);
            Q_UNUSED(ellipseAnnotation);
        }
        if (shape.startsWith("Text"))
        {
            shape = shape.mid(QString("Text").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            TextAnnotation *textAnnotation = new TextAnnotation(shape, this);
            Q_UNUSED(textAnnotation);
        }
    }
}

void ComponentAnnotation::parseTransformationString(QString value)
{
    value = StringHandler::removeFirstLastCurlBrackets(value);
    if (value.isEmpty())
        return;
    QStringList list = StringHandler::getStrings(value);
    int i = 0;

    if (list.size() > i)
    {
        this->mVisible = static_cast<QString>(list.at(i)).contains("true");
        if (!this->mVisible)
            this->hide();
        i++;
    }
    else
        return;

    // now parse the values for diagram
    // x position
    if (list.size() > i)
        i++;
    else
        return;
    // y position
    if (list.size() > i)
        i++;
    else
        return;
    // scale
    if (list.size() > i)
        i++;
    else
        return;
    // aspectratio
    if (list.size() > i)
        i++;
    else
        return;
    // flip horizontal
    if (list.size() > i)
        i++;
    else
        return;
    // flip vertical
    if (list.size() > i)
        i++;
    else
        return;
    // rotate angle
    if (list.size() > i)
        i++;
    else
        return;

    // now parse the values for icon
    // x position
    if (list.size() > i)
    {
        this->mPositionX = static_cast<QString>(list.at(i)).toFloat();
        i++;
    }
    else
        return;
    // y position
    if (list.size() > i)
    {
        this->mPositionY = static_cast<QString>(list.at(i)).toFloat();
        i++;
    }
    else
        return;
    this->setPos(this->mPositionX, this->mPositionY);
    // scale
    if (list.size() > i)
    {
        this->mScale = static_cast<QString>(list.at(i)).toFloat();
        this->scale(this->mScale, this->mScale);
        i++;
    }
    else
        return;
    // aspectratio
    if (list.size() > i)
    {
        this->mAspectRatio = static_cast<QString>(list.at(i)).toFloat();
        i++;
    }
    else
        return;
    // flip horizontal
    if (list.size() > i)
    {
        this->mFlipHorizontal = static_cast<QString>(list.at(i)).contains("true");
        if (this->mFlipHorizontal)
            this->scale(-1.0, 1.0);
        i++;
    }
    else
        return;
    // flip vertical
    if (list.size() > i)
    {
        this->mFlipVertical = static_cast<QString>(list.at(i)).contains("true");
        if (this->mFlipVertical)
            this->scale(1.0, -1.0);
        i++;
    }
    else
        return;
    // rotate angle
    if (list.size() > i)
    {
        this->mRotateAngle = static_cast<QString>(list.at(i)).toFloat();
        this->rotate(this->mRotateAngle);
        i++;
    }
    else
        return;
}

QRectF ComponentAnnotation::boundingRect() const
{
    return this->mRectangle;
}

void ComponentAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    //Q_UNUSED(painter);
    Q_UNUSED(option);
    Q_UNUSED(widget);

    //painter->rotate(ShapeAnnotation::mRotationAngle);
    //painter->scale(ShapeAnnotation::mScale, ShapeAnnotation::mScale);
    //painter->drawRect(boundingRect());
    //painter->drawLine(this->line);
}

qreal ComponentAnnotation::getRotateAngle()
{
    return mRotateAngle;
}

IconAnnotation* ComponentAnnotation::getParentIcon()
{
    return mpParentIcon;
}

void ComponentAnnotation::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
    if (event->button() == Qt::LeftButton)
    {
        emit componentClicked(this);
    }
}

void ComponentAnnotation::mouseReleaseEvent(QGraphicsSceneMouseEvent *event)
{
    unsetCursor();
}

// Icon Annotation Class
IconAnnotation::IconAnnotation(QString value, QString className, QPointF position, OMCProxy *omc, GraphicsScene *graphicsScene, GraphicsView *graphicsView)
    : mClassName(className), mpOMCProxy(omc), mpGraphicsScene(graphicsScene), mpGraphicsView(graphicsView)
{
    this->scale(Helper::globalXScale, Helper::globalYScale);
    mpGraphicsScene->addItem(this);
    setPos(position);
    setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable | QGraphicsItem::ItemSendsGeometryChanges);
    setAcceptHoverEvents(true);
    parseIconAnnotationString(value);
    getClassComponents(this->mClassName);

    // get the co-ordinates of rectangle and map them to item
    QList<QPointF> pointsList = getBoundingRect();
    // create top left selection box
    this->mpTopLeftCornerItem = new CornerItem(pointsList.at(0).x(), pointsList.at(1).y(), Qt::TopLeftCorner,
                                               mpGraphicsScene, mpGraphicsView);
    connect(mpTopLeftCornerItem, SIGNAL(iconSelected()), this, SLOT(showSelectionBox()));
    connect(mpTopLeftCornerItem, SIGNAL(iconResized(qreal, qreal)), this, SLOT(resizeIcon(qreal, qreal)));
    // create top right selection box
    this->mpTopRightCornerItem = new CornerItem(pointsList.at(1).x(), pointsList.at(1).y(), Qt::TopRightCorner,
                                                mpGraphicsScene, mpGraphicsView);
    connect(mpTopRightCornerItem, SIGNAL(iconSelected()), this, SLOT(showSelectionBox()));
    connect(mpTopRightCornerItem, SIGNAL(iconResized(qreal, qreal)), this, SLOT(resizeIcon(qreal, qreal)));
    // create bottom left selection box
    this->mpBottomLeftCornerItem = new CornerItem(pointsList.at(0).x(), pointsList.at(0).y(), Qt::BottomLeftCorner,
                                                  mpGraphicsScene, mpGraphicsView);
    connect(mpBottomLeftCornerItem, SIGNAL(iconSelected()), this, SLOT(showSelectionBox()));
    connect(mpBottomLeftCornerItem, SIGNAL(iconResized(qreal, qreal)), this, SLOT(resizeIcon(qreal, qreal)));
    // create bottom right selection box
    this->mpBottomRightCornerItem = new CornerItem(pointsList.at(1).x(), pointsList.at(0).y(), Qt::BottomRightCorner,
                                                   mpGraphicsScene, mpGraphicsView);
    connect(mpBottomRightCornerItem, SIGNAL(iconSelected()), this, SLOT(showSelectionBox()));
    connect(mpBottomRightCornerItem, SIGNAL(iconResized(qreal, qreal)), this, SLOT(resizeIcon(qreal, qreal)));
}

//! Parses the result of getIconAnnotation command.
//! @param value is the result of getIconAnnotation command obtained from OMC.
void IconAnnotation::parseIconAnnotationString(QString value)
{
    this->setFocus();
    value = StringHandler::removeFirstLastCurlBrackets(value);
    if (value.isEmpty())
    {
        return;
    }
    QStringList list = StringHandler::getStrings(value);
    if (list.size() < 4)
    {
        return;
    }
    qreal x1, x2, y1, y2, width, height;
    x1 = static_cast<QString>(list.at(0)).toFloat();
    y1 = static_cast<QString>(list.at(1)).toFloat();
    x2 = static_cast<QString>(list.at(2)).toFloat();
    y2 = static_cast<QString>(list.at(3)).toFloat();
    width = fabs(x1 - x2);
    height = fabs(y1 - y2);
    this->mRectangle = QRectF (x1, y1, width, height);

    if (list.size() < 5)
    {
        return;
    }

    // Check with Mohsen about the new IconAnnotation Standard Problem of SimForge

    QStringList shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(4)), '(', ')');

    // Now parse the shapes available in list

    foreach (QString shape, shapesList)
    {
        shape = StringHandler::removeFirstLastCurlBrackets(shape);
        if (shape.startsWith("Line"))
        {
            shape = shape.mid(QString("Line").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            LineAnnotation *lineAnnotation = new LineAnnotation(shape, this);
            Q_UNUSED(lineAnnotation);
        }
        if (shape.startsWith("Polygon"))
        {
            shape = shape.mid(QString("Polygon").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            PolygonAnnotation *polygonAnnotation = new PolygonAnnotation(shape, this);
            Q_UNUSED(polygonAnnotation);
        }
        if (shape.startsWith("Rectangle"))
        {
            shape = shape.mid(QString("Rectangle").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            RectangleAnnotation *rectangleAnnotation = new RectangleAnnotation(shape, this);
            Q_UNUSED(rectangleAnnotation);
        }
        if (shape.startsWith("Ellipse"))
        {
            shape = shape.mid(QString("Ellipse").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            EllipseAnnotation *ellipseAnnotation = new EllipseAnnotation(shape, this);
            Q_UNUSED(ellipseAnnotation);
        }
        if (shape.startsWith("Text"))
        {
            shape = shape.mid(QString("Text").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            TextAnnotation *textAnnotation = new TextAnnotation(shape, this);
            Q_UNUSED(textAnnotation);
        }
    }
}

QRectF IconAnnotation::boundingRect() const
{
    return this->mRectangle;
}

QList<QPointF> IconAnnotation::getBoundingRect()
{
    QList<QPointF> points;
    qreal x1, y1, x2, y2;
    QPointF scenePoints;
    this->boundingRect().getCoords(&x1, &y1, &x2, &y2);

    scenePoints = mapToScene(x1, y1);
    points.append(scenePoints);

    scenePoints = mapToScene(x2, y2);
    points.append(scenePoints);

    return points;
}

void IconAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    //Q_UNUSED(painter);
    Q_UNUSED(option);
    Q_UNUSED(widget);

    //painter->rotate(ShapeAnnotation::mRotationAngle);
    //painter->scale(ShapeAnnotation::mScale, ShapeAnnotation::mScale);
    //painter->drawRect(boundingRect());
}

//! Event when mouse cursor enters component icon.
void IconAnnotation::hoverEnterEvent(QGraphicsSceneHoverEvent *event)
{
    if(!this->isSelected())
        setSelectionBoxHover();
}

//! Event when mouse cursor leaves component icon.
void IconAnnotation::hoverLeaveEvent(QGraphicsSceneHoverEvent *event)
{
    if(!this->isSelected())
        setSelectionBoxPassive();
}

QVariant IconAnnotation::itemChange(GraphicsItemChange change, const QVariant &value)
{
    if (change == QGraphicsItem::ItemSelectedHasChanged)
    {
        if (this->isSelected())
        {
            setSelectionBoxActive();
            setCursor(Qt::SizeAllCursor);
        }
        else
        {
            setSelectionBoxPassive();
            unsetCursor();
        }
    }
    else if (change == QGraphicsItem::ItemPositionHasChanged)
    {
        emit componentMoved();
        updateSelectionBox();
    }
    return QGraphicsItem::itemChange(change, value);
}

void IconAnnotation::setSelectionBoxActive()
{
    this->mpTopLeftCornerItem->setActive();
    this->mpTopRightCornerItem->setActive();
    this->mpBottomLeftCornerItem->setActive();
    this->mpBottomRightCornerItem->setActive();
}

void IconAnnotation::setSelectionBoxPassive()
{
    this->mpTopLeftCornerItem->setPassive();
    this->mpTopRightCornerItem->setPassive();
    this->mpBottomLeftCornerItem->setPassive();
    this->mpBottomRightCornerItem->setPassive();
}

void IconAnnotation::setSelectionBoxHover()
{
    this->mpTopLeftCornerItem->setHovered();
    this->mpTopRightCornerItem->setHovered();
    this->mpBottomLeftCornerItem->setHovered();
    this->mpBottomRightCornerItem->setHovered();
}

void IconAnnotation::showSelectionBox()
{
    setSelectionBoxActive();
}

void IconAnnotation::updateSelectionBox()
{
    QList<QPointF> pointsList = getBoundingRect();
    // create top left selection box
    this->mpTopLeftCornerItem->updateCornerItem(pointsList.at(0).x(), pointsList.at(1).y(), Qt::TopLeftCorner);
    this->mpTopRightCornerItem->updateCornerItem(pointsList.at(1).x(), pointsList.at(1).y(), Qt::TopRightCorner);
    this->mpBottomLeftCornerItem->updateCornerItem(pointsList.at(0).x(), pointsList.at(0).y(), Qt::BottomLeftCorner);
    this->mpBottomRightCornerItem->updateCornerItem(pointsList.at(1).x(), pointsList.at(0).y(), Qt::BottomRightCorner);
}

void IconAnnotation::addConnector(Connector *item)
{
    connect(this, SIGNAL(componentMoved()), item, SLOT(drawConnector()));
}

void IconAnnotation::resizeIcon(qreal resizeFactorX, qreal resizeFactorY)
{
    if (resizeFactorX > 0 && resizeFactorY > 0)
    {
        this->scale(resizeFactorX, resizeFactorY);
        update();
        updateSelectionBox();
    }
}

QPixmap IconAnnotation::getIcon()
{
    return this->mIconPixmap.scaled(QSize(20,20), Qt::KeepAspectRatio);

/*
    if (value.isEmpty())
    {
        return;
    }
    QStringList list = StringHandler::getStrings(value);
    if (list.size() < 4)
    {
        return;
    }
    float x1, x2, y1, y2;
    int width, height;
    x1 = static_cast<QString>(list.at(0)).toFloat();
    y1 = static_cast<QString>(list.at(1)).toFloat();
    x2 = static_cast<QString>(list.at(2)).toFloat();
    y2 = static_cast<QString>(list.at(3)).toFloat();
    width = abs(static_cast<int>(x1) - static_cast<int>(x2));
    height = abs(static_cast<int>(y1) - static_cast<int>(y2));
    this->mRectangle = QRect (-100, -100, width, height);

    if (list.size() < 5)
    {
        return;
    }

    // Check with Mohsen about the new IconAnnotation Standard Problem of SimForge

    QStringList shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(4)), '(', ')');

    //ShapeAnnotation *shapeAnnotation = new ShapeAnnotation(shapesList);
    // Now parse the shapes available in list

    this->mIconPixmap = QPixmap(width * 0.20, height * 0.20);
    this->mIconPixmap.fill(QColor(Qt::transparent));
    QPainter painter(&this->mIconPixmap);
    painter.setWindow(this->mRectangle);
    painter.rotate(+180.0);
    //painter.scale(0.20, 0.20);

    foreach (QString shape, shapesList)
    {
        shape = StringHandler::removeFirstLastCurlBrackets(shape);
        if (shape.startsWith("Line"))
        {
            shape = shape.mid(QString("Line").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            LineAnnotation *lineAnnotation = new LineAnnotation(shape, this);
            lineAnnotation->drawLineAnnotaion(&painter);
        }
    }
    painter.end();
    //this->mIconPixmap = this->mIconPixmap.scaled(QSize(100,100), Qt::KeepAspectRatio);
    this->mIconPixmap.save("ground.png");
    */
}

void IconAnnotation::getClassComponents(QString className)
{
    int inheritanceCount = this->mpOMCProxy->getInheritanceCount(className);

    for(int i = 1 ; i <= inheritanceCount ; i++)
    {
        QString result = this->mpOMCProxy->getNthInheritedClass(className, i);
        QString annotationString = this->mpOMCProxy->getIconAnnotation(result);
        InheritanceAnnotation *inheritanceAnnotation = new InheritanceAnnotation(annotationString, result, mpOMCProxy,
                                                                                 mpGraphicsScene, mpGraphicsView, this, this);
        getClassComponents(result);
    }

    QList<ComponentsProperties*> components = this->mpOMCProxy->getComponents(className);
    QStringList componentsAnnotationsList = this->mpOMCProxy->getComponentAnnotations(className);
    int i = 0;
    foreach (ComponentsProperties *component, components)
    {
        if (StringHandler::removeFirstLastCurlBrackets(componentsAnnotationsList.at(i)).length() > 0)
        {
            if (this->mpOMCProxy->isWhat(StringHandler::CONNECTOR, component->getClassName()))
            {
                QString result = this->mpOMCProxy->getIconAnnotation(component->getClassName());
                ComponentAnnotation *componentAnnotation = new ComponentAnnotation(result, component->getClassName(),
                                                                                   componentsAnnotationsList.at(i),
                                                                                   mpOMCProxy, mpGraphicsScene,
                                                                                   mpGraphicsView, this, this);
                Q_UNUSED(componentAnnotation);
            }
        }
        i++;
    }
}

// Diagram Annotation Class
DiagramAnnotation::DiagramAnnotation(QString value, QString className)
    :   className(className)
{
    parseDiagramAnnotationString(StringHandler::removeFirstLastCurlBrackets(value));
}

//! Parses the result of getDiagramAnnotation command.
//! @param value is the result of getDiagramAnnotation command obtained from OMC.
void DiagramAnnotation::parseDiagramAnnotationString(QString value)
{
    if (value.isEmpty())
    {
        return;
    }
    QStringList list = StringHandler::getStrings(value);
    if (list.size() < 4)
    {
        return;
    }
    float x1, x2, y1, y2;
    int width, height;
    x1 = static_cast<QString>(list.at(0)).toFloat();
    y1 = static_cast<QString>(list.at(1)).toFloat();
    x2 = static_cast<QString>(list.at(2)).toFloat();
    y2 = static_cast<QString>(list.at(3)).toFloat();
    width = abs(static_cast<int>(x1) - static_cast<int>(x2));
    height = abs(static_cast<int>(y1) - static_cast<int>(y2));
    this->mRectangle = QRect (-100, -100, width, height);

    if (list.size() < 5)
    {
        return;
    }

    // Check with Mohsen about the new IconAnnotation Standard Problem of SimForge

    QStringList shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(4)), '(', ')');

    // Now parse the shapes available in list

    foreach (QString shape, shapesList)
    {
        shape = StringHandler::removeFirstLastCurlBrackets(shape);
        if (shape.startsWith("Line"))
        {
            shape = shape.mid(QString("Line").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            LineAnnotation *lineAnnotation = new LineAnnotation(shape, this);
            Q_UNUSED(lineAnnotation);
        }
        if (shape.startsWith("Polygon"))
        {
            shape = shape.mid(QString("Polygon").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            PolygonAnnotation *polygonAnnotation = new PolygonAnnotation(shape, this);
            Q_UNUSED(polygonAnnotation);
        }
        if (shape.startsWith("Rectangle"))
        {
            shape = shape.mid(QString("Rectangle").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            RectangleAnnotation *rectangleAnnotation = new RectangleAnnotation(shape, this);
            Q_UNUSED(rectangleAnnotation);
        }
        if (shape.startsWith("Ellipse"))
        {
            shape = shape.mid(QString("Ellipse").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            EllipseAnnotation *ellipseAnnotation = new EllipseAnnotation(shape, this);
            Q_UNUSED(ellipseAnnotation);
        }
        if (shape.startsWith("Text"))
        {
            shape = shape.mid(QString("Text").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            TextAnnotation *textAnnotation = new TextAnnotation(shape, this);
            Q_UNUSED(textAnnotation);
        }
    }
}

QRectF DiagramAnnotation::boundingRect() const
{
    return QRectF();
}

void DiagramAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(painter);
    Q_UNUSED(option);
    Q_UNUSED(widget);
}
