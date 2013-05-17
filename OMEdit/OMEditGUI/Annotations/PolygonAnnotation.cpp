/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include "PolygonAnnotation.h"

PolygonAnnotation::PolygonAnnotation(QString annotation, Component *pParent)
  : ShapeAnnotation(pParent)
{
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  parseShapeAnnotation(annotation);
  setPos(mOrigin);
}

PolygonAnnotation::PolygonAnnotation(QString annotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(pGraphicsView, 0)
{
  setFlag(QGraphicsItem::ItemIsSelectable);
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation(annotation);
  /* Only set the ItemIsMovable flag on shape if the class is not a system library class. */
  if (!mpGraphicsView->getModelWidget()->getLibraryTreeNode()->isSystemLibrary())
    setFlag(QGraphicsItem::ItemIsMovable);
  mpGraphicsView->addShapeObject(this);
  mpGraphicsView->scene()->addItem(this);
  connect(this, SIGNAL(updateClassAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

void PolygonAnnotation::parseShapeAnnotation(QString annotation)
{
  GraphicItem::parseShapeAnnotation(annotation);
  FilledShape::parseShapeAnnotation(annotation);
  // parse the shape to get the list of attributes of Polygon.
  QStringList list = StringHandler::getStrings(annotation);
  if (list.size() < 10)
    return;
  // 9th item of list contains the points.
  QStringList pointsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(8)));
  foreach (QString point, pointsList)
  {
    QStringList polygonPoints = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(point));
    if (polygonPoints.size() >= 2)
      mPoints.append(QPointF(polygonPoints.at(0).toFloat(), polygonPoints.at(1).toFloat()));
  }
  /* The polygon is automatically closed, if the first and the last points are not identical. */
  if (mPoints.size() == 1)
  {
    mPoints.append(mPoints.first());
    mPoints.append(mPoints.first());
  }
  else if (mPoints.size() == 2)
  {
    mPoints.append(mPoints.first());
  }
  if (mPoints.size() > 0)
    if (mPoints.first() != mPoints.last())
      mPoints.append(mPoints.first());
  // 10th item of the list is smooth.
  mSmooth = StringHandler::getSmoothType(list.at(9));
}

QPainterPath PolygonAnnotation::getShape() const
{
  QPainterPath path;
  if (mPoints.size() > 0)
  {
    if (mSmooth)
    {
      for (int i = 0 ; i < mPoints.size() ; i++)
      {
        QPointF point3 = mPoints.at(i);
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
            QPointF point2 = mPoints.at(i - 1);
            QPointF point1 = mPoints.at(i - 2);
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
      path.addPolygon(QPolygonF(mPoints.toVector()));
    }
  }
  return path;
}

QRectF PolygonAnnotation::boundingRect() const
{
  return shape().boundingRect();
}

QPainterPath PolygonAnnotation::shape() const
{
  QPainterPath path = getShape();
  if (mFillPattern == StringHandler::FillNone)
    return addPathStroker(path);
  else
    return path;
}

void PolygonAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(option);
  Q_UNUSED(widget);
  if (mVisible)
    drawPolygonAnnotaion(painter);
}

void PolygonAnnotation::drawPolygonAnnotaion(QPainter *painter)
{
  applyLinePattern(painter);
  applyFillPattern(painter);
  painter->drawPath(getShape());
}

QString PolygonAnnotation::getShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getShapeAnnotation());
  annotationString.append(FilledShape::getShapeAnnotation());
  // get points
  QString pointsString;
  if (mPoints.size() > 0)
    pointsString.append("points={");
  for (int i = 0 ; i < mPoints.size() ; i++)
  {
    pointsString.append("{").append(QString::number(mPoints[i].x())).append(",");
    pointsString.append(QString::number(mPoints[i].y())).append("}");
    if (i < mPoints.size() - 1)
      pointsString.append(",");
  }
  if (mPoints.size() > 0)
  {
    pointsString.append("}");
    annotationString.append(pointsString);
  }
  // get the smooth
  if (mSmooth != StringHandler::SmoothNone)
    annotationString.append(QString("smooth=").append(StringHandler::getSmoothString(mSmooth)));
  return QString("Polygon(").append(annotationString.join(",")).append(")");
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
