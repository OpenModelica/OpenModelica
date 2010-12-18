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

#include "EllipseAnnotation.h"

EllipseAnnotation::EllipseAnnotation(QString shape, Component *pParent)
    : ShapeAnnotation(pParent), mpComponent(pParent)
{
    initializeFields();
    parseShapeAnnotation(shape, mpComponent->mpOMCProxy);
}

EllipseAnnotation::EllipseAnnotation(GraphicsView *graphicsView, QGraphicsItem *pParent)
    : ShapeAnnotation(graphicsView, pParent)
{
    // initialize all fields with default values
    initializeFields();
    mIsCustomShape = true;
    setAcceptHoverEvents(true);
    connect(this, SIGNAL(updateShapeAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

EllipseAnnotation::EllipseAnnotation(QString shape, GraphicsView *graphicsView, QGraphicsItem *pParent)
    : ShapeAnnotation(graphicsView, pParent)
{
    // initialize all fields with default values
    initializeFields();
    parseShapeAnnotation(shape, mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy);
    mIsCustomShape = true;
    setAcceptHoverEvents(true);
    connect(this, SIGNAL(updateShapeAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

QRectF EllipseAnnotation::boundingRect() const
{
//    if ((mExtent.size() < 2) or (mIsCustomRectangle and !mIsFinishedCreatingRectangle))
//        return QRectF();
//    else
//        return QRectF(mExtent.at(0), mExtent.at(1));
    return shape().boundingRect();
}

QPainterPath EllipseAnnotation::shape() const
{
    QPainterPath path;
    QPointF p1 = this->mExtent.at(0);
    QPointF p2 = this->mExtent.at(1);

    qreal left = qMin(p1.x(), p2.x());
    qreal top = qMin(p1.y(), p2.y());
    qreal width = fabs(p1.x() - p2.x());
    qreal height = fabs(p1.y() - p2.y());

    QRectF ellipse (left, top, width, height);
    path.addEllipse(ellipse);

    QPainterPathStroker stroker;
    stroker.setWidth(Helper::shapesStrokeWidth);
    return stroker.createStroke(path);
}

void EllipseAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(option);
    Q_UNUSED(widget);

    drawEllipseAnnotaion(painter);
}

void EllipseAnnotation::drawEllipseAnnotaion(QPainter *painter)
{
    QPainterPath path;

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
    // make the pen width upper rounded, otherwise ellipse is distorted
    qreal thickness = ceil(mThickness);

    QPen pen(mLineColor, thickness, this->mLinePattern);
    pen.setCosmetic(true);
    painter->setPen(pen);

    path.addEllipse(ellipse);
    painter->drawPath(path);
}

void EllipseAnnotation::addPoint(QPointF point)
{
    mExtent.append(point);
}

void EllipseAnnotation::updateEndPoint(QPointF point)
{
    mExtent.back() = point;
}

void EllipseAnnotation::drawRectangleCornerItems()
{
    mIsFinishedCreatingShape = true;
    for (int i = 0 ; i < this->mExtent.size() ; i++)
    {
        QPointF point = this->mExtent.at(i);
        RectangleCornerItem *rectangleCornerItem = new RectangleCornerItem(point.x(), point.y(), i, this);
        mRectangleCornerItemsList.append(rectangleCornerItem);
    }
    emit updateShapeAnnotation();
}

QString EllipseAnnotation::getShapeAnnotation()
{
    QString annotationString;
    annotationString.append("Ellipse(");

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

void EllipseAnnotation::updatePoint(int index, QPointF point)
{
    mExtent.replace(index, point);
}

void EllipseAnnotation::parseShapeAnnotation(QString shape, OMCProxy *omc)
{
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

    // 11, 12, 13, 14 items of the list contains the extent points of Ellipse.
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
}
