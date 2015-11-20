/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include "LineAnnotation.h"
#include "Commands.h"

LineAnnotation::LineAnnotation(QString annotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0)
{
  setLineType(LineAnnotation::ShapeType);
  setStartComponent(0);
  setEndComponent(0);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation(annotation);
  setShapeFlags(true);
}

LineAnnotation::LineAnnotation(ShapeAnnotation *pShapeAnnotation, Component *pParent)
  : ShapeAnnotation(pParent)
{
  updateShape(pShapeAnnotation);
  setLineType(LineAnnotation::ComponentType);
  setStartComponent(0);
  setEndComponent(0);
  setPos(mOrigin);
  setRotation(mRotation);
  connect(pShapeAnnotation, SIGNAL(updateReferenceShapes()), pShapeAnnotation, SIGNAL(changed()));
  connect(pShapeAnnotation, SIGNAL(added()), this, SLOT(referenceShapeAdded()));
  connect(pShapeAnnotation, SIGNAL(changed()), this, SLOT(referenceShapeChanged()));
  connect(pShapeAnnotation, SIGNAL(deleted()), this, SLOT(referenceShapeDeleted()));
}

LineAnnotation::LineAnnotation(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView)
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

LineAnnotation::LineAnnotation(Component *pStartComponent, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0)
{
  setFlag(QGraphicsItem::ItemIsSelectable);
  mLineType = LineAnnotation::ConnectionType;
  setZValue(1000);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // use the linecolor of start component for the connection line.
  if (pStartComponent->getShapesList().size() > 0) {
    ShapeAnnotation *pShapeAnnotation = pStartComponent->getShapesList().at(0);
    mLineColor = pShapeAnnotation->getLineColor();
  }
  // set the graphics view
  mpGraphicsView->addItem(this);
  // set the start component
  setStartComponent(pStartComponent);
  setEndComponent(0);
}

LineAnnotation::LineAnnotation(QString annotation, Component *pStartComponent, Component *pEndComponent, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0)
{
  setFlag(QGraphicsItem::ItemIsSelectable);
  mLineType = LineAnnotation::ConnectionType;
  setZValue(1000);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set the start component
  setStartComponent(pStartComponent);
  // set the end component
  setEndComponent(pEndComponent);
  parseShapeAnnotation(annotation);
  /* make the points relative to origin */
  QList<QPointF> points;
  for (int i = 0 ; i < mPoints.size() ; i++) {
    QPointF point = mOrigin + mPoints[i];
    points.append(point);
  }
  mPoints = points;
  mOrigin = QPointF(0, 0);
  // set the graphics view
  mpGraphicsView->addItem(this);
}

LineAnnotation::LineAnnotation(Component *pParent)
  : ShapeAnnotation(pParent)
{
  setLineType(LineAnnotation::ComponentType);
  setStartComponent(0);
  setEndComponent(0);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // create a red cross
  setLineColor(QColor(255, 0, 0));
  // create a red cross with points
  addPoint(QPointF(-100, -100));
  addPoint(QPointF(100, 100));
  addPoint(QPointF(-100, 100));
  addPoint(QPointF(100, -100));
  addPoint(QPointF(-100, -100));
  addPoint(QPointF(-100, 100));
  addPoint(QPointF(100, 100));
  addPoint(QPointF(100, -100));
  setPos(mOrigin);
  setRotation(mRotation);
}

LineAnnotation::LineAnnotation(GraphicsView *pGraphicsView)
  : ShapeAnnotation(true, pGraphicsView, 0)
{
  setLineType(LineAnnotation::ShapeType);
  setStartComponent(0);
  setEndComponent(0);
  // set the default values
  GraphicItem::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  // create a red cross
  setLineColor(QColor(255, 0, 0));
  // create a red cross with points
  addPoint(QPointF(-100, -100));
  addPoint(QPointF(100, 100));
  addPoint(QPointF(-100, 100));
  addPoint(QPointF(100, -100));
  addPoint(QPointF(-100, -100));
  addPoint(QPointF(-100, 100));
  addPoint(QPointF(100, 100));
  addPoint(QPointF(100, -100));
  setShapeFlags(true);
  mpGraphicsView->addItem(this);
}

void LineAnnotation::parseShapeAnnotation(QString annotation)
{
  GraphicItem::parseShapeAnnotation(annotation);
  // parse the shape to get the list of attributes of Line.
  QStringList list = StringHandler::getStrings(annotation);
  if (list.size() < 10) {
    return;
  }
  mPoints.clear();
  // 4th item of list contains the points.
  QStringList pointsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(3)));
  foreach (QString point, pointsList) {
    QStringList linePoints = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(point));
    if (linePoints.size() >= 2) {
      addPoint(QPointF(linePoints.at(0).toFloat(), linePoints.at(1).toFloat()));
    }
  }
  // 5th item of list contains the color.
  QStringList colorList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(4)));
  if (colorList.size() >= 3) {
    int red, green, blue = 0;
    red = colorList.at(0).toInt();
    green = colorList.at(1).toInt();
    blue = colorList.at(2).toInt();
    mLineColor = QColor (red, green, blue);
  }
  // 6th item of list contains the Line Pattern.
  mLinePattern = StringHandler::getLinePatternType(list.at(5));
  // 7th item of list contains the Line thickness.
  mLineThickness = list.at(6).toFloat();
  // 8th item of list contains the Line Arrows.
  QStringList arrowList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(7)));
  if (arrowList.size() >= 2) {
    mArrow.replace(0, StringHandler::getArrowType(arrowList.at(0)));
    mArrow.replace(1, StringHandler::getArrowType(arrowList.at(1)));
  }
  // 9th item of list contains the Line Arrow Size.
  mArrowSize = list.at(8).toFloat();
  // 10th item of list contains the smooth.
  mSmooth = StringHandler::getSmoothType(list.at(9));
}

QPainterPath LineAnnotation::getShape() const
{
  QPainterPath path;
  if (mPoints.size() > 0) {
    // mPoints.size() is at least 1
    path.moveTo(mPoints.at(0));
    if (mSmooth) {
      if (mPoints.size() == 2) {
        // if points are only two then spline acts as simple line
        path.lineTo(mPoints.at(1));
      } else {
        for (int i = 2 ; i < mPoints.size() ; i++) {
          QPointF point3 = mPoints.at(i);
          // calculate middle points for bezier curves
          QPointF point2 = mPoints.at(i - 1);
          QPointF point1 = mPoints.at(i - 2);
          QPointF point12((point1.x() + point2.x())/2, (point1.y() + point2.y())/2);
          QPointF point23((point2.x() + point3.x())/2, (point2.y() + point3.y())/2);
          path.lineTo(point12);
          path.cubicTo(point12, point2, point23);
          // if its the last point
          if (i == mPoints.size() - 1) {
            path.lineTo(point3);
          }
        }
      }
    } else {
      for (int i = 1 ; i < mPoints.size() ; i++) {
        path.lineTo(mPoints.at(i));
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
  if (mVisible) {
    drawLineAnnotaion(painter);
  }
}

void LineAnnotation::drawLineAnnotaion(QPainter *painter)
{
  applyLinePattern(painter);
  // draw start arrow
  if (mPoints.size() > 1) {
    if (mArrow.at(0) == StringHandler::ArrowFilled) {
      painter->save();
      painter->setBrush(QBrush(mLineColor, Qt::SolidPattern));
      painter->drawPolygon(drawArrow(mPoints.at(0), mPoints.at(1), mArrowSize, mArrow.at(0)));
      painter->restore();
    } else {
      painter->drawPolygon(drawArrow(mPoints.at(0), mPoints.at(1), mArrowSize, mArrow.at(0)));
    }
  }
  painter->drawPath(getShape());
  // draw end arrow
  if (mPoints.size() > 1) {
    if (mArrow.at(1) == StringHandler::ArrowFilled) {
      painter->save();
      painter->setBrush(QBrush(mLineColor, Qt::SolidPattern));
      painter->drawPolygon(drawArrow(mPoints.at(mPoints.size() - 1), mPoints.at(mPoints.size() - 2), mArrowSize, mArrow.at(1)));
      painter->restore();
    } else {
      painter->drawPolygon(drawArrow(mPoints.at(mPoints.size() - 1), mPoints.at(mPoints.size() - 2), mArrowSize, mArrow.at(1)));
    }
  }
}

QPolygonF LineAnnotation::drawArrow(QPointF startPos, QPointF endPos, qreal size, int arrowType) const
{
  double xA = size / 2;
  double yA = size * sqrt(3) / 2;
  double xB = -xA;
  double yB = yA;
  switch (arrowType) {
    case StringHandler::ArrowFilled:
      break;
    case StringHandler::ArrowHalf:
      xB = 0;
      break;
    case StringHandler::ArrowNone:
      return QPolygonF();
    case StringHandler::ArrowOpen:
      break;
  }
  double angle = 0.0f;
  if (endPos.x() - startPos.x() == 0) {
    if (endPos.y() - startPos.y() >= 0) {
      angle = 0;
    } else {
      angle = M_PI;
    }
  } else {
    angle = -(M_PI / 2 - (atan((endPos.y() - startPos.y())/(endPos.x() - startPos.x()))));
    if(startPos.x() > endPos.x()) {
      angle += M_PI;
    }
  }
  qreal m11, m12, m13, m21, m22, m23, m31, m32, m33;
  m11 = cos(angle);
  m22 = m11;
  m21 = sin(angle);
  m12 = -m21;
  m13 = startPos.x();
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

/*!
 * \brief LineAnnotation::getOMCShapeAnnotation
 * Returns Line annotation in format as returned by OMC.
 * \return
 */
QString LineAnnotation::getOMCShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getOMCShapeAnnotation());
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
  // get the line color
  QString colorString;
  colorString.append("{");
  colorString.append(QString::number(mLineColor.red())).append(",");
  colorString.append(QString::number(mLineColor.green())).append(",");
  colorString.append(QString::number(mLineColor.blue()));
  colorString.append("}");
  annotationString.append(colorString);
  // get the line pattern
  annotationString.append(StringHandler::getLinePatternString(mLinePattern));
  // get the thickness
  annotationString.append(QString::number(mLineThickness));
  // get the start and end arrow
  QString arrowString;
  arrowString.append("{").append(StringHandler::getArrowString(mArrow.at(0))).append(",");
  arrowString.append(StringHandler::getArrowString(mArrow.at(1))).append("}");
  annotationString.append(arrowString);
  // get the arrow size
  annotationString.append(QString::number(mArrowSize));
  // get the smooth
  annotationString.append(StringHandler::getSmoothString(mSmooth));
  return annotationString.join(",");
}

/*!
 * \brief LineAnnotation::getShapeAnnotation
 * Returns Line annotation.
 * \return
 */
QString LineAnnotation::getShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getShapeAnnotation());
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
  // get the line color
  if (mLineColor != Qt::black) {
    QString colorString;
    colorString.append("color={");
    colorString.append(QString::number(mLineColor.red())).append(",");
    colorString.append(QString::number(mLineColor.green())).append(",");
    colorString.append(QString::number(mLineColor.blue()));
    colorString.append("}");
    annotationString.append(colorString);
  }
  // get the line pattern
  if (mLinePattern != StringHandler::LineSolid) {
    annotationString.append(QString("pattern=").append(StringHandler::getLinePatternString(mLinePattern)));
  }
  // get the thickness
  if (mLineThickness != 0.25) {
    annotationString.append(QString("thickness=").append(QString::number(mLineThickness)));
  }
  // get the start and end arrow
  if ((mArrow.at(0) != StringHandler::ArrowNone) || (mArrow.at(1) != StringHandler::ArrowNone)) {
    QString arrowString;
    arrowString.append("arrow=");
    arrowString.append("{").append(StringHandler::getArrowString(mArrow.at(0))).append(",");
    arrowString.append(StringHandler::getArrowString(mArrow.at(1))).append("}");
    annotationString.append(arrowString);
  }
  // get the arrow size
  if (mArrowSize != 3) {
    annotationString.append(QString("arrowSize=").append(QString::number(mArrowSize)));
  }
  // get the smooth
  if (mSmooth != StringHandler::SmoothNone) {
    annotationString.append(QString("smooth=").append(StringHandler::getSmoothString(mSmooth)));
  }
  return QString("Line(").append(annotationString.join(",")).append(")");
}

QString LineAnnotation::getTLMShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getShapeAnnotation());
  // get points
  QString pointsString;
  if (mPoints.size() > 0)
  {
    pointsString.append("{");
  }
  for (int i = 0 ; i < mPoints.size() ; i++)
  {
    pointsString.append("{").append(QString::number(mPoints[i].x())).append(",");
    pointsString.append(QString::number(mPoints[i].y())).append("}");
    if (i < mPoints.size() - 1)
    {
      pointsString.append(",");
    }
  }
  if (mPoints.size() > 0)
  {
    pointsString.append("}");
    annotationString.append(pointsString);
  }
  return annotationString.join(",");
}

void LineAnnotation::addPoint(QPointF point)
{
  mPoints.append(point);
  if (mPoints.size() > 1) {
    if (mGeometries.size() == 0) {
      QPointF currentPoint = mPoints[mPoints.size() - 1];
      QPointF previousPoint = mPoints[mPoints.size() - 2];
      mGeometries.append(findLineGeometryType(previousPoint, currentPoint));
    } else {
      if (mGeometries.back() == ShapeAnnotation::HorizontalLine) {
        mGeometries.push_back(ShapeAnnotation::VerticalLine);
      } else if (mGeometries.back() == ShapeAnnotation::VerticalLine) {
        mGeometries.push_back(ShapeAnnotation::HorizontalLine);
      }
    }
  }
}

void LineAnnotation::removePoint(int index)
{
  if (mPoints.size() > index) {
    mPoints.removeAt(index);
  }
  if (mGeometries.size() > index - 1) {
    mGeometries.removeAt(index  -1);
    // adjust the remaining geometries accordingly
    for (int i = index - 1 ; i < mGeometries.size() ; i++) {
      if (mGeometries.size() > i - 1) {
        if (mGeometries[i - 1] == ShapeAnnotation::HorizontalLine) {
          mGeometries[i] = ShapeAnnotation::VerticalLine;
        } else if (mGeometries[i - 1] == ShapeAnnotation::VerticalLine) {
          mGeometries[i] = ShapeAnnotation::HorizontalLine;
        }
      }
    }
  }
}

/*!
  Clears the points list.
  */
void LineAnnotation::clearPoints()
{
  mPoints.clear();
  mGeometries.clear();
}

/*!
  Updates the first point of the connection, and adjusts the second point accordingly depending on the geometry list.
  \param point - is the new start point.
  \sa updateEndPoint(QPointF point)
  */
void LineAnnotation::updateStartPoint(QPointF point)
{
  manhattanizeShape();
  removeRedundantPointsGeometriesAndCornerItems();
  qreal dx = point.x() - mPoints[0].x();
  qreal dy = point.y() - mPoints[0].y();
  // if connection points are just two we need to add extra points
  if (mPoints.size() == 2) {
    // just check if additional points are really needed or not.
    if ((mGeometries[0] == ShapeAnnotation::HorizontalLine && mPoints[0].y() != point.y()) ||
        (mGeometries[0] == ShapeAnnotation::VerticalLine && mPoints[0].x() != point.x())) {
      insertPointsGeometriesAndCornerItems(1);
      setCornerItemsActiveOrPassive();
    }
  }
  /* update the 1st point */
  if (mPoints.size() > 0) {
    mPoints[0] = point;
    updateCornerItem(0);
  }
  /* update the 2nd point */
  if (mPoints.size() > 1) {
    if (mGeometries[0] == ShapeAnnotation::HorizontalLine) {
      mPoints[1] = QPointF(mPoints[1].x(), mPoints[1].y() + dy);
    } else if (mGeometries[0] == ShapeAnnotation::VerticalLine) {
      mPoints[1] = QPointF(mPoints[1].x() + dx, mPoints[1].y());
    }
    updateCornerItem(1);
  }
  removeRedundantPointsGeometriesAndCornerItems();
}

/*!
  Updates the end point of the connection, and adjusts the second last point accordingly depending on the geometry list.
  \param point - is the new end point.
  \sa updateStartPoint(QPointF point)
  */
void LineAnnotation::updateEndPoint(QPointF point)
{
  if (mLineType == LineAnnotation::ConnectionType) {
    if (!mpGraphicsView->isCreatingConnection()) {
      manhattanizeShape();
      removeRedundantPointsGeometriesAndCornerItems();
    }
    int lastIndex = mPoints.size() - 1;
    int secondLastIndex = mPoints.size() - 2;
    qreal dx = point.x() - mPoints[lastIndex].x();
    qreal dy = point.y() - mPoints[lastIndex].y();
    /*
      if connection points are just two we need to add extra points
      This function is also called when creating a component so for that we don't need to add extra points. In order to avoid this we check
      for the mpEndComponent since mpEndComponent will only be set when the connection is complete.
      */
    if (mPoints.size() == 2 && mpEndComponent) {
      // just check if additional points are really needed or not.
      if ((mGeometries[secondLastIndex] == ShapeAnnotation::HorizontalLine && mPoints[lastIndex].y() != point.y()) ||
          (mGeometries[secondLastIndex] == ShapeAnnotation::VerticalLine && mPoints[lastIndex].x() != point.x())) {
        insertPointsGeometriesAndCornerItems(lastIndex);
        setCornerItemsActiveOrPassive();
        lastIndex = mPoints.size() - 1;
        secondLastIndex = mPoints.size() - 2;
      }
    }
    /* update the last point */
    if (mPoints.size() > 1) {
      mPoints.back() = point;
      updateCornerItem(lastIndex);
      /* update the 2nd point */
      if (mGeometries[secondLastIndex] == ShapeAnnotation::HorizontalLine) {
        mPoints[secondLastIndex] = QPointF(mPoints[secondLastIndex].x(), mPoints[secondLastIndex].y() + dy);
      } else if (mGeometries[secondLastIndex] == ShapeAnnotation::VerticalLine) {
        mPoints[secondLastIndex] = QPointF(mPoints[secondLastIndex].x() + dx, mPoints[secondLastIndex].y());
      }
      updateCornerItem(secondLastIndex);
    }
    if (!mpGraphicsView->isCreatingConnection()) {
      removeRedundantPointsGeometriesAndCornerItems();
    }
  } else {
    mPoints.back() = point;
  }
}

void LineAnnotation::moveAllPoints(qreal offsetX, qreal offsetY)
{
  for(int i = 0 ; i < mPoints.size() ; i++) {
    mPoints[i] = QPointF(mPoints[i].x()+offsetX, mPoints[i].y()+offsetY);
    /* updated the corresponding CornerItem */
    updateCornerItem(i);
  }
}

/*!
  Sets the shape flags.
  */
void LineAnnotation::setShapeFlags(bool enable)
{
  if ((mLineType == LineAnnotation::ConnectionType || mLineType == LineAnnotation::ShapeType) && mpGraphicsView) {
    /*
      Only set the ItemIsMovable & ItemSendsGeometryChanges flags on Line if the class is not a system library class
      AND Line is not an inherited Line AND Line type is not ConnectionType.
      */
    bool isSystemLibrary = mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary();
    if (!isSystemLibrary && !isInheritedShape() && mLineType != LineAnnotation::ConnectionType) {
      setFlag(QGraphicsItem::ItemIsMovable, enable);
      setFlag(QGraphicsItem::ItemSendsGeometryChanges, enable);
    }
    setFlag(QGraphicsItem::ItemIsSelectable, enable);
  }
}

void LineAnnotation::updateShape(ShapeAnnotation *pShapeAnnotation)
{
  LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(pShapeAnnotation);
  setLineType(pLineAnnotation->getLineType());
  setStartComponent(pLineAnnotation->getStartComponent());
  setStartComponentName(pLineAnnotation->getStartComponentName());
  setEndComponent(pLineAnnotation->getEndComponent());
  setEndComponentName(pLineAnnotation->getEndComponentName());
  // set the default values
  GraphicItem::setDefaults(pShapeAnnotation);
  mPoints.clear();
  QList<QPointF> points = pShapeAnnotation->getPoints();
  for (int i = 0 ; i < points.size() ; i++) {
    addPoint(points[i]);
  }
  ShapeAnnotation::setDefaults(pShapeAnnotation);
}

/*!
 * \brief LineAnnotation::handleComponentMoved
 * If the component associated with the connection is moved then update the connection accordingly.
 */
void LineAnnotation::handleComponentMoved()
{
  if (mPoints.size() < 2) {
    return;
  }
  prepareGeometryChange();
  if (mpStartComponent) {
    Component *pComponent = qobject_cast<Component*>(sender());
    if (pComponent == mpStartComponent->getRootParentComponent()) {
      updateStartPoint(mpGraphicsView->roundPoint(mpStartComponent->mapToScene(mpStartComponent->boundingRect().center())));
    }
  }
  if (mpEndComponent) {
    Component *pComponent = qobject_cast<Component*>(sender());
    if (pComponent == mpEndComponent->getRootParentComponent()) {
      updateEndPoint(mpGraphicsView->roundPoint(mpEndComponent->mapToScene(mpEndComponent->boundingRect().center())));
    }
  }
}

/*!
 * \brief LineAnnotation::updateConnectionAnnotation
 * Updates the connection annotation.
 */
void LineAnnotation::updateConnectionAnnotation()
{
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::TLM) {
    TLMEditor *pTLMEditor = dynamic_cast<TLMEditor*>(mpGraphicsView->getModelWidget()->getEditor());
    pTLMEditor->updateTLMConnectiontAnnotation(getStartComponentName(), getEndComponentName(), getTLMShapeAnnotation());

   } else {
    // get the connection line annotation.
    QString annotationString = QString("annotate=").append(getShapeAnnotation());
    // update the connection
    OMCProxy *pOMCProxy = mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getOMCProxy();
    pOMCProxy->updateConnection(getStartComponentName(), getEndComponentName(),
                                mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure(), annotationString);
  }
}

/*!
 * \brief LineAnnotation::duplicate
 * Duplicates the shape.
 */
void LineAnnotation::duplicate()
{
  LineAnnotation *pLineAnnotation = new LineAnnotation("", mpGraphicsView);
  pLineAnnotation->updateShape(this);
  QPointF gridStep(mpGraphicsView->mCoOrdinateSystem.getHorizontalGridStep() * 5,
                   mpGraphicsView->mCoOrdinateSystem.getVerticalGridStep() * 5);
  pLineAnnotation->setOrigin(mOrigin + gridStep);
  pLineAnnotation->initializeTransformation();
  pLineAnnotation->drawCornerItems();
  pLineAnnotation->setCornerItemsActiveOrPassive();
  pLineAnnotation->update();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new AddShapeCommand(pLineAnnotation));
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitShapeAdded(pLineAnnotation, mpGraphicsView);
  setSelected(false);
  pLineAnnotation->setSelected(true);
}

ConnectionArray::ConnectionArray(GraphicsView *pGraphicsView, LineAnnotation *pConnectionLineAnnotation, QWidget *pParent)
  : QDialog(pParent, Qt::WindowTitleHint), mpGraphicsView(pGraphicsView), mpConnectionLineAnnotation(pConnectionLineAnnotation)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::connectArray));
  setAttribute(Qt::WA_DeleteOnClose);
  // heading
  mpHeading = new Label(Helper::connectArray);
  mpHeading->setFont(QFont(Helper::systemFontInfo.family(), Helper::headingFontSize));
  mpHeading->setAlignment(Qt::AlignTop);
  // horizontal line
  mpHorizontalLine = new QFrame();
  mpHorizontalLine->setFrameShape(QFrame::HLine);
  mpHorizontalLine->setFrameShadow(QFrame::Sunken);
  // Description text
  QString indexString = tr("<b>[index]</b>");
  QString startComponentDescription;
  if (pConnectionLineAnnotation->getStartComponent()->getParentComponent()) {
    startComponentDescription = QString("<b>").append(pConnectionLineAnnotation->getStartComponent()->getParentComponent()->getName())
        .append(".").append(pConnectionLineAnnotation->getStartComponent()->getName()).append("</b>");
  } else {
    startComponentDescription = QString("<b>").append(pConnectionLineAnnotation->getStartComponent()->getName()).append("</b>");
  }
  if (pConnectionLineAnnotation->getStartComponent()->getComponentInfo()) {
    if (pConnectionLineAnnotation->getStartComponent()->getComponentInfo()->isArray()) {
      startComponentDescription.append(indexString);
    }
  }
  QString endComponentDescription;
  if (pConnectionLineAnnotation->getEndComponent()->getParentComponent()) {
    endComponentDescription = QString("<b>").append(pConnectionLineAnnotation->getEndComponent()->getParentComponent()->getName())
        .append(".").append(pConnectionLineAnnotation->getEndComponent()->getName()).append("</b>");
  } else {
    endComponentDescription = QString("<b>").append(pConnectionLineAnnotation->getEndComponent()->getName()).append("</b>");
  }
  if (pConnectionLineAnnotation->getEndComponent()->getComponentInfo()) {
    if (pConnectionLineAnnotation->getEndComponent()->getComponentInfo()->isArray()) {
      endComponentDescription.append(indexString);
    }
  }
  mpDescriptionLabel = new Label(tr("Connect ").append(startComponentDescription).append(tr(" with ")).append(endComponentDescription));
  // start component
  if (pConnectionLineAnnotation->getStartComponent()->getParentComponent()) {
    mpStartComponentLabel = new Label(tr("Enter <b>index</b> value for <b>").append(pConnectionLineAnnotation->getStartComponent()->getParentComponent()->getName())
                                      .append(".").append(pConnectionLineAnnotation->getStartComponent()->getName()).append("<b>"));
  } else {
    mpStartComponentLabel = new Label(tr("Enter <b>index</b> value for <b>").append(pConnectionLineAnnotation->getStartComponent()->getName()).append("<b>"));
  }
  mpStartComponentTextBox = new QLineEdit;
  // end component
  if (pConnectionLineAnnotation->getEndComponent()->getParentComponent()) {
    mpEndComponentLabel = new Label(tr("Enter <b>index</b> value for <b>").append(pConnectionLineAnnotation->getEndComponent()->getParentComponent()->getName())
                                    .append(".").append(pConnectionLineAnnotation->getEndComponent()->getName()).append("</b>"));
  } else {
    mpEndComponentLabel = new Label(tr("Enter <b>index</b> value for <b>").append(pConnectionLineAnnotation->getEndComponent()->getName()).append("</b>"));
  }
  mpEndComponentTextBox = new QLineEdit;
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(saveArrayIndex()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(cancelArrayIndex()));
  // add buttons
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *mainLayout = new QGridLayout;
  mainLayout->addWidget(mpHeading, 0, 0);
  mainLayout->addWidget(mpHorizontalLine, 1, 0);
  mainLayout->addWidget(mpDescriptionLabel, 2, 0);
  int i = 3;
  if (pConnectionLineAnnotation->getStartComponent()->getComponentInfo()) {
    if (pConnectionLineAnnotation->getStartComponent()->getComponentInfo()->isArray()) {
      mainLayout->addWidget(mpStartComponentLabel, i, 0);
      mainLayout->addWidget(mpStartComponentTextBox, i+1, 0);
      i = i + 2;
    }
  }
  if (pConnectionLineAnnotation->getEndComponent()->getComponentInfo()) {
    if (pConnectionLineAnnotation->getEndComponent()->getComponentInfo()->isArray()) {
      mainLayout->addWidget(mpEndComponentLabel, i, 0);
      mainLayout->addWidget(mpEndComponentTextBox, i+1, 0);
      i = i + 2;
    }
  }
  mainLayout->addWidget(mpButtonBox, i, 0);
  setLayout(mainLayout);
}

void ConnectionArray::saveArrayIndex()
{
  QString startComponentName, endComponentName;
  // set start component name
  if (mpConnectionLineAnnotation->getStartComponent()->getParentComponent()) {
    startComponentName = QString(mpConnectionLineAnnotation->getStartComponent()->getParentComponent()->getName()).append(".")
        .append(mpConnectionLineAnnotation->getStartComponent()->getName());
  } else {
    startComponentName = mpConnectionLineAnnotation->getStartComponent()->getName();
  }
  // set the start component name if start component is an array
  if (mpConnectionLineAnnotation->getStartComponent()->getComponentInfo()) {
    if (mpConnectionLineAnnotation->getStartComponent()->getComponentInfo()->isArray()) {
      if (!mpStartComponentTextBox->text().isEmpty()) {
        startComponentName = QString(startComponentName).append("[").append(mpStartComponentTextBox->text()).append("]");
      }
    }
  }
  // set end component name
  if (mpConnectionLineAnnotation->getEndComponent()->getParentComponent()) {
    endComponentName = QString(mpConnectionLineAnnotation->getEndComponent()->getParentComponent()->getName()).append(".")
        .append(mpConnectionLineAnnotation->getEndComponent()->getName());
  } else {
    endComponentName = mpConnectionLineAnnotation->getEndComponent()->getName();
  }
  // set the end component name if end component is an array
  if (mpConnectionLineAnnotation->getEndComponent()->getComponentInfo()) {
    if (mpConnectionLineAnnotation->getEndComponent()->getComponentInfo()->isArray()) {
      if (!mpEndComponentTextBox->text().isEmpty()) {
        endComponentName = QString(endComponentName).append("[").append(mpEndComponentTextBox->text()).append("]");
      }
    }
  }
  mpGraphicsView->addConnectionToClass(mpConnectionLineAnnotation);
  mpConnectionLineAnnotation->setToolTip(QString("<b>connect</b>(%1, %2)").arg(startComponentName, endComponentName));
  mpConnectionLineAnnotation->drawCornerItems();
  mpConnectionLineAnnotation->setCornerItemsActiveOrPassive();
  accept();
}

void ConnectionArray::cancelArrayIndex()
{
  mpGraphicsView->removeCurrentConnection();
  reject();
}
