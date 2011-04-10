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
    initializeFields();
    parseShapeAnnotation(shape, mpCompnent->mpOMCProxy);
}

RectangleAnnotation::RectangleAnnotation(GraphicsView *graphicsView, QGraphicsItem *pParent)
    : ShapeAnnotation(graphicsView, pParent)
{
    // initialize all fields with default values
    initializeFields();
    mIsCustomShape = true;
    setAcceptHoverEvents(true);
    connect(this, SIGNAL(updateShapeAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

RectangleAnnotation::RectangleAnnotation(QString shape, GraphicsView *graphicsView, QGraphicsItem *pParent)
    : ShapeAnnotation(graphicsView, pParent)
{
    // initialize all fields with default values
    initializeFields();
    parseShapeAnnotation(shape, mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy);
    mIsCustomShape = true;
    setAcceptHoverEvents(true);
    connect(this, SIGNAL(updateShapeAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

QRectF RectangleAnnotation::boundingRect() const
{
    return shape().boundingRect();
}

QPainterPath RectangleAnnotation::shape() const
{
    QPainterPath path;
    path.addRoundedRect(getBoundingRect(), mCornerRadius, mCornerRadius);
    return addPathStroker(path);
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

    switch (this->mFillPattern)
    {
    case Qt::LinearGradientPattern:
        {
            QLinearGradient gradient(getBoundingRect().center().x(), getBoundingRect().center().y(),
                                     getBoundingRect().center().x(), getBoundingRect().y());
            gradient.setColorAt(0.0, this->mFillColor);
            gradient.setColorAt(1.0, this->mLineColor);
            gradient.setSpread(QGradient::ReflectSpread);
            painter->setBrush(gradient);
            break;
        }
    case Qt::Dense1Pattern:
        {
            QLinearGradient gradient(getBoundingRect().center().x(), getBoundingRect().center().y(),
                                     getBoundingRect().x(), getBoundingRect().center().y());
            gradient.setColorAt(0.0, this->mFillColor);
            gradient.setColorAt(1.0, this->mLineColor);
            gradient.setSpread(QGradient::ReflectSpread);
            painter->setBrush(gradient);
            break;
        }
    case Qt::RadialGradientPattern:
        {
            QRadialGradient gradient(getBoundingRect().center().x(), getBoundingRect().center().y(),
                                     getBoundingRect().width());
            gradient.setColorAt(0.0, this->mFillColor);
            gradient.setColorAt(1.0, this->mLineColor);
            gradient.setSpread(QGradient::ReflectSpread);
            painter->setBrush(gradient);
            break;
        }
    default:
        painter->setBrush(QBrush(this->mFillColor, mFillPattern));
        break;
    }

    // make the pen width upper rounded if rectangle is rounded
    qreal thickness;
    if (mCornerRadius > 0)
        thickness = ceil(mThickness);

    QPen pen(mLineColor, thickness, mLinePattern);
    pen.setCosmetic(true);
    painter->setPen(pen);

    path.addRoundedRect(getBoundingRect(), mCornerRadius, mCornerRadius);
    painter->drawPath(path);
}

void RectangleAnnotation::addPoint(QPointF point)
{
    mExtent.append(point);
}

void RectangleAnnotation::updateEndPoint(QPointF point)
{
    mExtent.back() = point;
}

void RectangleAnnotation::drawRectangleCornerItems()
{
    mIsFinishedCreatingShape = true;
    for (int i = 0 ; i < this->mExtent.size() ; i++)
    {
        QPointF point = this->mExtent.at(i);
        RectangleCornerItem *rectangleCornerItem = new RectangleCornerItem(point.x(), point.y(), i, this);
        mRectangleCornerItemsList.append(rectangleCornerItem);
    }
    setTransformOriginPoint(boundingRect().center());
    emit updateShapeAnnotation();
}

QString RectangleAnnotation::getShapeAnnotation()
{
    QString annotationString;
    annotationString.append("Rectangle(");

    if (!mVisible)
    {
        annotationString.append("visible=false,");
    }

    annotationString.append("rotation=").append(QString::number(this->rotation())).append(",");

    annotationString.append("lineColor={");
    annotationString.append(QString::number(mLineColor.red())).append(",");
    annotationString.append(QString::number(mLineColor.green())).append(",");
    annotationString.append(QString::number(mLineColor.blue()));
    annotationString.append("},");

    annotationString.append("fillColor={");
    annotationString.append(QString::number(mFillColor.red())).append(",");
    annotationString.append(QString::number(mFillColor.green())).append(",");
    annotationString.append(QString::number(mFillColor.blue()));
    annotationString.append("},");

    QMap<QString, Qt::PenStyle>::iterator it;
    for (it = this->mLinePatternsMap.begin(); it != this->mLinePatternsMap.end(); ++it)
    {
        if (it.value() == mLinePattern)
        {
            annotationString.append("pattern=LinePattern.").append(it.key()).append(",");
            break;
        }
    }

    QMap<QString, Qt::BrushStyle>::iterator fill_it;
    for (fill_it = this->mFillPatternsMap.begin(); fill_it != this->mFillPatternsMap.end(); ++fill_it)
    {
        if (fill_it.value() == mFillPattern)
        {
            annotationString.append("fillPattern=FillPattern.").append(fill_it.key()).append(",");
            break;
        }
    }

    annotationString.append("lineThickness=").append(QString::number(mThickness)).append(",");
    annotationString.append("extent={{");
    annotationString.append(QString::number(mapToScene(mExtent.at(0)).x())).append(",");
    annotationString.append(QString::number(mapToScene(mExtent.at(0)).y())).append("},{");
    annotationString.append(QString::number(mapToScene(mExtent.at(1)).x())).append(",");
    annotationString.append(QString::number(mapToScene(mExtent.at(1)).y()));
    annotationString.append("}}");        

    annotationString.append(")");
    return annotationString;
}

void RectangleAnnotation::updatePoint(int index, QPointF point)
{
    mExtent.replace(index, point);
    setTransformOriginPoint(boundingRect().center());
}

void RectangleAnnotation::parseShapeAnnotation(QString shape, OMCProxy *omc)
{
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
    if (omc->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
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
