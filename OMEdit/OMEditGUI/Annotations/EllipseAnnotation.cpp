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

#include "EllipseAnnotation.h"

EllipseAnnotation::EllipseAnnotation(QString annotation, GraphicsView *pGraphicsView)
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
  connect(this, SIGNAL(updateClassAnnotation()), this, SIGNAL(updateReferenceShapes()));
  connect(this, SIGNAL(updateClassAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

EllipseAnnotation::EllipseAnnotation(ShapeAnnotation *pShapeAnnotation, Component *pParent)
  : ShapeAnnotation(pParent)
{
  updateShape(pShapeAnnotation);
  setPos(mOrigin);
  setRotation(mRotation);
  connect(pShapeAnnotation, SIGNAL(updateReferenceShapes()), pShapeAnnotation, SIGNAL(changed()));
  connect(pShapeAnnotation, SIGNAL(added()), this, SLOT(referenceShapeAdded()));
  connect(pShapeAnnotation, SIGNAL(changed()), this, SLOT(referenceShapeChanged()));
  connect(pShapeAnnotation, SIGNAL(deleted()), this, SLOT(referenceShapeDeleted()));
}

EllipseAnnotation::EllipseAnnotation(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView)
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

void EllipseAnnotation::parseShapeAnnotation(QString annotation)
{
  GraphicItem::parseShapeAnnotation(annotation);
  FilledShape::parseShapeAnnotation(annotation);
  // parse the shape to get the list of attributes of Ellipse.
  QStringList list = StringHandler::getStrings(annotation);
  if (list.size() < 11)
  {
    return;
  }
  // 9th item is the extent points
  QStringList extentsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(8)));
  for (int i = 0 ; i < qMin(extentsList.size(), 2) ; i++)
  {
    QStringList extentPoints = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(extentsList[i]));
    if (extentPoints.size() >= 2)
    {
      mExtents.replace(i, QPointF(extentPoints.at(0).toFloat(), extentPoints.at(1).toFloat()));
    }
  }
  // 10th item of the list contains the start angle.
  mStartAngle = list.at(9).toFloat();
  // 11th item of the list contains the end angle.
  mEndAngle = list.at(10).toFloat();
}

QRectF EllipseAnnotation::boundingRect() const
{
  return shape().boundingRect();
}

QPainterPath EllipseAnnotation::shape() const
{
  QPainterPath path;
  qreal startAngle = StringHandler::getNormalizedAngle(mStartAngle);
  qreal endAngle = StringHandler::getNormalizedAngle(mEndAngle);
  if ((startAngle - endAngle) == 0)
  {
    path.addEllipse(getBoundingRect());
    if (mFillPattern == StringHandler::FillNone)
    {
      return addPathStroker(path);
    }
    else
    {
      return path;
    }
  }
  path.addEllipse(getBoundingRect());
  return path;
}

void EllipseAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(option);
  Q_UNUSED(widget);
  if (mVisible)
  {
    drawEllipseAnnotaion(painter);
  }
}

void EllipseAnnotation::drawEllipseAnnotaion(QPainter *painter)
{
  QPainterPath path;
  // first we invert the painter since we have our coordinate system inverted.
  // inversion is required to draw the elliptic curves at correct angles.
  painter->scale(1.0, -1.0);
  painter->translate(0, ((-boundingRect().top()) - boundingRect().bottom()));
  applyLinePattern(painter);
  applyFillPattern(painter);
  qreal startAngle = StringHandler::getNormalizedAngle(mStartAngle);
  qreal endAngle = StringHandler::getNormalizedAngle(mEndAngle);
  if ((startAngle - endAngle) == 0) {
    path.addEllipse(getBoundingRect());
    painter->drawPath(path);
  } else {
    painter->drawPie(getBoundingRect(), mStartAngle*16, mEndAngle*16 - mStartAngle*16);
  }
}

QString EllipseAnnotation::getShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getShapeAnnotation());
  annotationString.append(FilledShape::getShapeAnnotation());
  // get the extents
  if (mExtents.size() > 1)
  {
    QString extentString;
    extentString.append("extent={");
    extentString.append("{").append(QString::number(mExtents.at(0).x())).append(",");
    extentString.append(QString::number(mExtents.at(0).y())).append("},");
    extentString.append("{").append(QString::number(mExtents.at(1).x())).append(",");
    extentString.append(QString::number(mExtents.at(1).y())).append("}");
    extentString.append("}");
    annotationString.append(extentString);
  }
  // get the start angle
  if (mStartAngle != 0)
  {
    annotationString.append(QString("startAngle=").append(QString::number(mStartAngle)));
  }
  // get the end angle
  if (mEndAngle != 0)
  {
    annotationString.append(QString("endAngle=").append(QString::number(mEndAngle)));
  }
  return QString("Ellipse(").append(annotationString.join(",")).append(")");
}

void EllipseAnnotation::updateShape(ShapeAnnotation *pShapeAnnotation)
{
  // set the default values
  GraphicItem::setDefaults(pShapeAnnotation);
  FilledShape::setDefaults(pShapeAnnotation);
  ShapeAnnotation::setDefaults(pShapeAnnotation);
}

void EllipseAnnotation::duplicate()
{
  EllipseAnnotation *pEllipseAnnotation = new EllipseAnnotation("", mpGraphicsView);
  QPointF gridStep(mpGraphicsView->getCoOrdinateSystem()->getHorizontalGridStep(),
                   mpGraphicsView->getCoOrdinateSystem()->getVerticalGridStep());
  pEllipseAnnotation->setOrigin(mOrigin + gridStep);
  pEllipseAnnotation->setRotationAngle(mRotation);
  pEllipseAnnotation->initializeTransformation();
  pEllipseAnnotation->setLineColor(getLineColor());
  pEllipseAnnotation->setFillColor(getFillColor());
  pEllipseAnnotation->setLinePattern(getLinePattern());
  pEllipseAnnotation->setFillPattern(getFillPattern());
  pEllipseAnnotation->setLineThickness(getLineThickness());
  pEllipseAnnotation->setExtents(getExtents());
  pEllipseAnnotation->setStartAngle(getStartAngle());
  pEllipseAnnotation->setEndAngle(getEndAngle());
  pEllipseAnnotation->drawCornerItems();
  pEllipseAnnotation->setCornerItemsPassive();
  pEllipseAnnotation->update();
  mpGraphicsView->addClassAnnotation();
  mpGraphicsView->setCanAddClassAnnotation(true);
}
