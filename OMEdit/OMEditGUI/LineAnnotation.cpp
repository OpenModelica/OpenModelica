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
    // initialize all fields with default values
    initializeFields();
    parseShapeAnnotation(shape, mpComponent->mpOMCProxy);
}

LineAnnotation::LineAnnotation(GraphicsView *graphicsView, QGraphicsItem *pParent)
    : ShapeAnnotation(graphicsView, pParent)
{
    // initialize all fields with default values
    initializeFields();
    mIsCustomShape = true;
    setAcceptHoverEvents(true);
    connect(this, SIGNAL(updateShapeAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

LineAnnotation::LineAnnotation(QString shape, GraphicsView *graphicsView, QGraphicsItem *pParent)
    : ShapeAnnotation(graphicsView, pParent)
{
    // initialize all fields with default values
    initializeFields();
    parseShapeAnnotation(shape, mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy);
    mIsCustomShape = true;
    setAcceptHoverEvents(true);
    connect(this, SIGNAL(updateShapeAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

QPainterPath LineAnnotation::getShape() const
{
    QPainterPath path;

    if (this->mPoints.size() > 0)
    {
        if (mSmooth)
        {
            for (int i = 0 ; i < this->mPoints.size() ; i++)
            {
                QPointF point3 = this->mPoints.at(i);
                if (i == 0)
                    path.moveTo(point3);
                else
                {
                    // if points are only two then spline acts as simple line
                    if (i < 2)
                    {
                        if (mPoints.size() < 3)
                            path.lineTo(point3);
                    }
                    else
                    {
                        // calculate middle points for bezier curves
                        QPointF point2 = this->mPoints.at(i - 1);
                        QPointF point1 = this->mPoints.at(i - 2);
                        QPointF point12((point1.x() + point2.x())/2, (point1.y() + point2.y())/2);
                        QPointF point23((point2.x() + point3.x())/2, (point2.y() + point3.y())/2);

                        path.lineTo(point12);
                        path.cubicTo(point12, point2, point23);
                        // if its the last point
                        if (i == mPoints.size() - 1)
                            path.lineTo(point3);
                    }
                }
            }
        }
        else
        {
            for (int i = 0 ; i < this->mPoints.size() ; i++)
            {
                QPointF point1 = this->mPoints.at(i);
                if (i == 0)
                    path.moveTo(point1);
                else
                    path.lineTo(point1);
            }
        }
    }
    return path;
}

QRectF LineAnnotation::boundingRect() const
{
    return shape().boundingRect();
}

QPainterPath LineAnnotation::shape() const
{
    QPainterPath path = getShape();
    return addPathStroker(path);
}

void LineAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(option);
    Q_UNUSED(widget);

    setTransformOriginPoint(boundingRect().center());
    drawLineAnnotaion(painter);
}

void LineAnnotation::drawLineAnnotaion(QPainter *painter)
{
    qreal thickness;

    // make the pen width upper rounded for spline, otherwise spline is distorted
    if (mSmooth)
        thickness = ceil(mThickness);
    else
        thickness = mThickness;

    QPen pen(this->mLineColor, thickness, this->mLinePattern);
    pen.setCosmetic(true);
    painter->setPen(pen);
    // draw start arrow
    if (mStartArrow == ShapeAnnotation::Filled)
    {
        painter->save();
        painter->setBrush(QBrush(mLineColor, Qt::SolidPattern));
        painter->drawPolygon(drawArrow(mPoints.at(0), mPoints.at(1), mArrowSize * 2, mStartArrow));
        painter->restore();
    }
    else
        painter->drawPolygon(drawArrow(mPoints.at(0), mPoints.at(1), mArrowSize * 2, mStartArrow));

    painter->drawPath(getShape());

    // draw end arrow
    if (mEndArrow == ShapeAnnotation::Filled)
    {
        painter->save();
        painter->setBrush(QBrush(mLineColor, Qt::SolidPattern));
        painter->drawPolygon(drawArrow(mPoints.at(mPoints.size() - 1), mPoints.at(mPoints.size() - 2),
                                       mArrowSize * 2, mEndArrow));
        painter->restore();
    }
    else
        painter->drawPolygon(drawArrow(mPoints.at(mPoints.size() - 1), mPoints.at(mPoints.size() - 2),
                                       mArrowSize * 2, mEndArrow));
}

void LineAnnotation::addPoint(QPointF point)
{
    mPoints.append(point);
}

void LineAnnotation::updateEndPoint(QPointF point)
{
    mPoints.back() = point;
}

void LineAnnotation::drawRectangleCornerItems()
{
    mIsFinishedCreatingShape = true;
    // remove the last point since mouse double click event has added an extra point to it.....
    mPoints.remove(mPoints.size() - 1);
    for (int i = 0 ; i < this->mPoints.size() ; i++)
    {
        QPointF point = this->mPoints.at(i);
        RectangleCornerItem *rectangleCornerItem = new RectangleCornerItem(point.x(), point.y(), i, this);
        mRectangleCornerItemsList.append(rectangleCornerItem);
    }
    emit updateShapeAnnotation();
}

QString LineAnnotation::getShapeAnnotation()
{
    QString annotationString;
    annotationString.append("Line(");

    if (!mVisible)
    {
        annotationString.append("visible=false,");
    }

    annotationString.append("points={");
    for (int i = 0 ; i < mPoints.size() ; i++)
    {
        annotationString.append("{").append(QString::number(mapToScene(mPoints[i]).x())).append(",");
        annotationString.append(QString::number(mapToScene(mPoints[i]).y())).append("}");
        if (i < mPoints.size() - 1)
            annotationString.append(",");
    }
    annotationString.append("},");

    annotationString.append("rotation=").append(QString::number(this->rotation())).append(",");

    annotationString.append("color={");
    annotationString.append(QString::number(mLineColor.red())).append(",");
    annotationString.append(QString::number(mLineColor.green())).append(",");
    annotationString.append(QString::number(mLineColor.blue()));
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

    annotationString.append("thickness=").append(QString::number(mThickness));
    if (mSmooth)
    {
        annotationString.append(",smooth=Smooth.Bezier");
    }

    annotationString.append(")");
    return annotationString;
}

void LineAnnotation::updatePoint(int index, QPointF point)
{
    mPoints.replace(index, point);
}

void LineAnnotation::parseShapeAnnotation(QString shape, OMCProxy *omc)
{
    // parse the shape to get the list of attributes of Line.
    QStringList list = StringHandler::getStrings(shape);
    if (list.size() < 8)
    {
        return;
    }

    // if first item of list is true then the Line should be visible.
    this->mVisible = static_cast<QString>(list.at(0)).contains("true");

    int index = 0;
    if (omc->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
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
    QStringList arrowList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(index)));
    if (arrowList.size() < 2)
        return;

    QMap<QString, ArrowType>::iterator arrow_it;
    for (arrow_it = mArrowsMap.begin(); arrow_it != mArrowsMap.end(); ++arrow_it)
    {
        if (arrow_it.key().compare(StringHandler::getLastWordAfterDot(arrowList.at(0))) == 0)
            mStartArrow = arrow_it.value();
        if (arrow_it.key().compare(StringHandler::getLastWordAfterDot(arrowList.at(1))) == 0)
            mEndArrow = arrow_it.value();
    }

    // seventh item of list contains the Line Arrow Size.
    index = index + 1;
    mArrowSize = static_cast<QString>(list.at(index)).toFloat();

    // eighth item of list contains the smooth.
    index = index + 1;
    if (omc->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
    {
        this->mSmooth = static_cast<QString>(list.at(index)).toLower().contains("smooth.bezier");
    }
    else if (mpComponent->mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION2X)
    {
        this->mSmooth = static_cast<QString>(list.at(index)).toLower().contains("true");
    }
}

QPolygonF LineAnnotation::drawArrow(QPointF startPos, QPointF endPos, qreal size, int arrowType) const
{
    double xA = size / 2;
    double yA = size * sqrt(3) / 2;

    double xB = -xA;
    double yB = yA;

    switch (arrowType)
    {
        case ShapeAnnotation::Filled:
            break;
        case ShapeAnnotation::Half:
            xB = 0;
            break;
        case ShapeAnnotation::None:
            return QPolygonF();
        case ShapeAnnotation::Open:
            break;
    }

    double angle = 0.0f;
    if (endPos.x() - startPos.x() == 0)
    {
        if (endPos.y() - startPos.y() >= 0)
            angle = 0;
        else
            angle = M_PI;
    }
    else
    {
        angle = -(M_PI / 2 - (atan((endPos.y() - startPos.y())/(endPos.x() - startPos.x()))));
        if(startPos.x() > endPos.x())
            angle += M_PI;
    }

    qreal m11, m12, m13, m21, m22, m23, m31, m32, m33;

    m11 = cos(angle);
    m12 = -sin(angle);
    m13 = startPos.x();
    m21 = sin(angle);
    m22 = cos(angle);
    m23 = startPos.y();
    m31 = 0;
    m32 = 0;
    m33 = 1;

    QTransform t1(m11, m12, m13, m21, m22, m23, m31, m32, m33);
    QTransform t2(xA, 1, 1, yA, 1, 1, 1, 1, 1);
    QTransform t3 = t1 * t2;

    QPolygonF polygon;
    polygon << startPos;
    polygon << QPointF(t3.m11(), t3.m21());

    t2.setMatrix(xB, 1, 1, yB, 1, 1, 1, 1, 1);
    t3 = t1 * t2;

    polygon << QPointF(t3.m11(), t3.m21());
    polygon << startPos;

    return polygon;
}
