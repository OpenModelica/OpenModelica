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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "PolygonAnnotation.h"
#include "Modeling/Commands.h"

PolygonAnnotation::PolygonAnnotation(QString annotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0)
{
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation(annotation);
  setShapeFlags(true);
}

PolygonAnnotation::PolygonAnnotation(ShapeAnnotation *pShapeAnnotation, Component *pParent)
  : ShapeAnnotation(pParent)
{
  updateShape(pShapeAnnotation);
  initUpdateVisible(); // DynamicSelect for visible attribute
  setPos(mOrigin);
  setRotation(mRotation);
  connect(pShapeAnnotation, SIGNAL(updateReferenceShapes()), pShapeAnnotation, SIGNAL(changed()));
  connect(pShapeAnnotation, SIGNAL(added()), this, SLOT(referenceShapeAdded()));
  connect(pShapeAnnotation, SIGNAL(changed()), this, SLOT(referenceShapeChanged()));
  connect(pShapeAnnotation, SIGNAL(deleted()), this, SLOT(referenceShapeDeleted()));
}

PolygonAnnotation::PolygonAnnotation(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(true, pGraphicsView, 0)
{
  updateShape(pShapeAnnotation);
  setShapeFlags(true);
  mpGraphicsView->addItem(this);
  connect(pShapeAnnotation, SIGNAL(updateReferenceShapes()), pShapeAnnotation, SIGNAL(changed()));
  connect(pShapeAnnotation, SIGNAL(added()), this, SLOT(referenceShapeAdded()));
  connect(pShapeAnnotation, SIGNAL(changed()), this, SLOT(referenceShapeChanged()));
  connect(pShapeAnnotation, SIGNAL(deleted()), this, SLOT(referenceShapeDeleted()));
}

PolygonAnnotation::PolygonAnnotation(Component *pParent)
  : ShapeAnnotation(pParent)
{
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  setPos(mOrigin);
  setRotation(mRotation);
}

void PolygonAnnotation::parseShapeAnnotation(QString annotation)
{
  GraphicItem::parseShapeAnnotation(annotation);
  FilledShape::parseShapeAnnotation(annotation);
  // parse the shape to get the list of attributes of Polygon.
  QStringList list = StringHandler::getStrings(annotation);
  if (list.size() < 10) {
    return;
  }
  mPoints.clear();
  // 9th item of list contains the points.
  QStringList pointsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(8)));
  foreach (QString point, pointsList) {
    QStringList polygonPoints = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(point));
    if (polygonPoints.size() >= 2) {
      mPoints.append(QPointF(polygonPoints.at(0).toFloat(), polygonPoints.at(1).toFloat()));
    }
  }
  /* The polygon is automatically closed, if the first and the last points are not identical. */
  if (mPoints.size() == 1) {
    mPoints.append(mPoints.first());
    mPoints.append(mPoints.first());
  } else if (mPoints.size() == 2) {
    mPoints.append(mPoints.first());
  }
  if (mPoints.size() > 0) {
    if (mPoints.first() != mPoints.last()) {
      mPoints.append(mPoints.first());
    }
  }
  // 10th item of the list is smooth.
  mSmooth = StringHandler::getSmoothType(list.at(9));
}

QPainterPath PolygonAnnotation::getShape() const
{
  QPainterPath path;
  if (mPoints.size() > 0) {
    if (mSmooth) {
      path.moveTo(mPoints.at(0));
      // if points are only two then spline acts as simple line
      if (mPoints.size() == 2) {
        path.lineTo(mPoints.at(1));
      } else {
        for (int i = 2 ; i < mPoints.size() ; i++) {
          QPointF point3 = mPoints.at(i);
          // calculate middle points for bezier curves
          QPointF point2 = mPoints.at(i - 1);
          QPointF point1 = mPoints.at(i - 2);
          QPointF point12((point1.x() + point2.x())/2, (point1.y() + point2.y())/2);
          QPointF point23((point2.x() + point3.x())/2, (point2.y() + point3.y())/2);
          if (i == 2) {
            path.moveTo(point12);
          }
          path.cubicTo(point12, point2, point23);
          // if its the last point
          if (i == mPoints.size() - 1) {
            /* ticket:4331 Close the polygon with angle using the bezier curve.
             */
            QPointF point3 = mPoints.at(1);
            // calculate middle points for bezier curves
            QPointF point2 = mPoints.at(i);
            QPointF point1 = mPoints.at(i - 1);
            QPointF point12((point1.x() + point2.x())/2, (point1.y() + point2.y())/2);
            QPointF point23((point2.x() + point3.x())/2, (point2.y() + point3.y())/2);
            path.cubicTo(point12, point2, point23);
          }
        }
      }
    } else {
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
  if (mFillPattern == StringHandler::FillNone) {
    return addPathStroker(path);
  } else {
    return path;
  }
}

void PolygonAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(option);
  Q_UNUSED(widget);
  if (mVisible || !mDynamicVisible.isEmpty()) {
    drawPolygonAnnotaion(painter);
  }
}

void PolygonAnnotation::drawPolygonAnnotaion(QPainter *painter)
{
  applyLinePattern(painter);
  applyFillPattern(painter);
  painter->drawPath(getShape());
}

/*!
 * \brief PolygonAnnotation::getOMCShapeAnnotation
 * Returns Polygon annotation in format as returned by OMC.
 * \return
 */
QString PolygonAnnotation::getOMCShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getOMCShapeAnnotation());
  annotationString.append(FilledShape::getOMCShapeAnnotation());
  // get points
  QString pointsString;
  if (mPoints.size() > 0) {
    pointsString.append("{");
  }
  for (int i = 0 ; i < mPoints.size() ; i++) {
    pointsString.append("{").append(QString::number(mPoints[i].x())).append(",");
    pointsString.append(QString::number(mPoints[i].y())).append("}");
    if (i < mPoints.size() - 1) {
      pointsString.append(",");
    }
  }
  if (mPoints.size() > 0) {
    pointsString.append("}");
    annotationString.append(pointsString);
  }
  // get the smooth
  annotationString.append(StringHandler::getSmoothString(mSmooth));
  return annotationString.join(",");
}

/*!
 * \brief PolygonAnnotation::getShapeAnnotation
 * Returns Polygon annotation.
 * \return
 */
QString PolygonAnnotation::getShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getShapeAnnotation());
  annotationString.append(FilledShape::getShapeAnnotation());
  // get points
  QString pointsString;
  if (mPoints.size() > 0) {
    pointsString.append("points={");
  }
  for (int i = 0 ; i < mPoints.size() ; i++) {
    pointsString.append("{").append(QString::number(mPoints[i].x())).append(",");
    pointsString.append(QString::number(mPoints[i].y())).append("}");
    if (i < mPoints.size() - 1) {
      pointsString.append(",");
    }
  }
  if (mPoints.size() > 0) {
    pointsString.append("}");
    annotationString.append(pointsString);
  }
  // get the smooth
  if (mSmooth != StringHandler::SmoothNone) {
    annotationString.append(QString("smooth=").append(StringHandler::getSmoothString(mSmooth)));
  }
  return QString("Polygon(").append(annotationString.join(",")).append(")");
}

void PolygonAnnotation::addPoint(QPointF point)
{
  mPoints.append(point);
  mPoints.back() = mPoints.first();
}

void PolygonAnnotation::removePoint(int index)
{
  if (mPoints.size() > index) {
    mPoints.removeAt(index);
  }
}

void PolygonAnnotation::clearPoints()
{
  mPoints.clear();
}

void PolygonAnnotation::updateEndPoint(QPointF point)
{
  // we update the second last point for polygon since the last point is connected to first one
  mPoints.replace(mPoints.size() - 2, point);
}

void PolygonAnnotation::updateShape(ShapeAnnotation *pShapeAnnotation)
{
  // set the default values
  GraphicItem::setDefaults(pShapeAnnotation);
  FilledShape::setDefaults(pShapeAnnotation);
  mPoints.clear();
  setPoints(pShapeAnnotation->getPoints());
  ShapeAnnotation::setDefaults(pShapeAnnotation);
}

/*!
 * \brief PolygonAnnotation::duplicate
 * Duplicates the shape.
 */
void PolygonAnnotation::duplicate()
{
  PolygonAnnotation *pPolygonAnnotation = new PolygonAnnotation("", mpGraphicsView);
  pPolygonAnnotation->updateShape(this);
  QPointF gridStep(mpGraphicsView->mCoOrdinateSystem.getHorizontalGridStep() * 5,
                   mpGraphicsView->mCoOrdinateSystem.getVerticalGridStep() * 5);
  pPolygonAnnotation->setOrigin(mOrigin + gridStep);
  pPolygonAnnotation->initializeTransformation();
  pPolygonAnnotation->drawCornerItems();
  pPolygonAnnotation->setCornerItemsActiveOrPassive();
  pPolygonAnnotation->update();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new AddShapeCommand(pPolygonAnnotation));
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitShapeAdded(pPolygonAnnotation, mpGraphicsView);
  setSelected(false);
  pPolygonAnnotation->setSelected(true);
}
