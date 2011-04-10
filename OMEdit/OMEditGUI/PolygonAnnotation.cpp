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

PolygonAnnotation::PolygonAnnotation(QString shape, Component *pParent)
    : ShapeAnnotation(pParent), mpComponent(pParent)
{
    initializeFields();
    parseShapeAnnotation(shape, mpComponent->mpOMCProxy);
}

PolygonAnnotation::PolygonAnnotation(GraphicsView *graphicsView, QGraphicsItem *pParent)
    : ShapeAnnotation(graphicsView, pParent)
{
    // initialize all fields with default values
    initializeFields();
    mIsCustomShape = true;
    setAcceptHoverEvents(true);
    connect(this, SIGNAL(updateShapeAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

PolygonAnnotation::PolygonAnnotation(QString shape, GraphicsView *graphicsView, QGraphicsItem *pParent)
    : ShapeAnnotation(graphicsView, pParent)
{
    // initialize all fields with default values
    initializeFields();
    parseShapeAnnotation(shape, mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy);
    mIsCustomShape = true;
    setAcceptHoverEvents(true);
    connect(this, SIGNAL(updateShapeAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

QRectF PolygonAnnotation::boundingRect() const
{
    return shape().boundingRect();
}

QPainterPath PolygonAnnotation::shape() const
{
    QPainterPath path;
    path.addPolygon(QPolygonF(mPoints));
    return addPathStroker(path);
}

void PolygonAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(option);
    Q_UNUSED(widget);

    drawPolygonAnnotaion(painter);
}

void PolygonAnnotation::drawPolygonAnnotaion(QPainter *painter)
{
    QPainterPath path;

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
    QPen pen(this->mLineColor, this->mThickness, this->mLinePattern);
    pen.setCosmetic(true);
    painter->setPen(pen);

    path.addPolygon(QPolygonF(mPoints));
    painter->drawPath(path);
}

void PolygonAnnotation::addPoint(QPointF point)
{
    mPoints.append(point);
    mPoints.back() = mPoints.first();
}

void PolygonAnnotation::updateEndPoint(QPointF point)
{
    // we update the second last point for polygon since the last point is connected to first one
    mPoints.replace(mPoints.size() - 2, point);
}

void PolygonAnnotation::drawRectangleCornerItems()
{
    mIsFinishedCreatingShape = true;
    // remove the last point since mouse double click event has added an extra point to it.....
    mPoints.remove(mPoints.size() - 1);
    // the loop should run -1 size so that we dont have two corner item for starting and ending points
    for (int i = 0 ; i < this->mPoints.size() - 1 ; i++)
    {
        QPointF point = this->mPoints.at(i);
        RectangleCornerItem *rectangleCornerItem = new RectangleCornerItem(point.x(), point.y(), i, this);
        mRectangleCornerItemsList.append(rectangleCornerItem);
    }
    setTransformOriginPoint(boundingRect().center());
    emit updateShapeAnnotation();
}

QString PolygonAnnotation::getShapeAnnotation()
{
    QString annotationString;
    annotationString.append("Polygon(");

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

    annotationString.append("lineThickness=").append(QString::number(mThickness));
    if (mSmooth)
    {
        annotationString.append(",smooth=Smooth.Bezier");
    }

    annotationString.append(")");
    return annotationString;
}

void PolygonAnnotation::updatePoint(int index, QPointF point)
{
    // if updating the starting point then update the end point with it as well
    if (index == 0)
    {
        mPoints.replace(index, point);
        mPoints.back() = mPoints.first();
    }
    else
    {
        mPoints.replace(index, point);
    }
    setTransformOriginPoint(boundingRect().center());
}

void PolygonAnnotation::parseShapeAnnotation(QString shape, OMCProxy *omc)
{
    // parse the shape to get the list of attributes of Polygon.
    QStringList list = StringHandler::getStrings(shape);
    if (list.size() < 8)
    {
        return;
    }

    // if first item of list is true then the Polygon should be visible.
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

    // second item of list contains the color.
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

    // third item of list contains the color.
    index = index + 1;
    QStringList fillColorList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(index)));
    if (fillColorList.size() < 3)
    {
        return;
    }

    red = static_cast<QString>(fillColorList.at(0)).toInt();
    green = static_cast<QString>(fillColorList.at(1)).toInt();
    blue = static_cast<QString>(fillColorList.at(2)).toInt();
    this->mFillColor = QColor (red, green, blue);

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

    // fifth item of list contains the Line Pattern.
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

    // sixth item of list contains the thickness.
    index = index + 1;
    this->mThickness = static_cast<QString>(list.at(index)).toFloat();

    // seventh item of list contains the points.
    index = index + 1;
    QStringList pointsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(index)));
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
