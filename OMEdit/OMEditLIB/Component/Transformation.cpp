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

#include "Transformation.h"
#include "Component.h"

Transformation::Transformation()
{
  mValid = false;
  mpComponent = 0;
  initialize(StringHandler::Diagram);
}

Transformation::Transformation(StringHandler::ViewType viewType, Component *pComponent)
{
  mValid = true;
  mpComponent = pComponent;
  initialize(viewType);
}

Transformation::Transformation(const Transformation &transformation)
{
  updateTransformation(transformation);
}

void Transformation::initialize(StringHandler::ViewType viewType)
{
  mViewType = viewType;
  mWidth = 200.0;
  mHeight = 200.0;
  mVisible = true;
  mOriginDiagram = QPointF(0.0, 0.0);
  mHasOriginDiagramX = true;
  mHasOriginDiagramY = true;
  mExtent1Diagram = QPointF(-100.0, -100.0);
  mExtent2Diagram = QPointF(100.0, 100.0);
  mRotateAngleDiagram = 0.0;
  mPositionDiagram = QPointF(0.0, 0.0);
  mOriginIcon = QPointF(0.0, 0.0);
  mHasOriginIconX = true;
  mHasOriginIconY = true;
  mExtent1Icon = QPointF(-100.0, -100.0);
  mExtent2Icon = QPointF(100.0, 100.0);
  mRotateAngleIcon = 0.0;
  mPositionIcon = QPointF(0.0, 0.0);
}

void Transformation::parseTransformationString(QString value, qreal width, qreal height)
{
  /*
    if width and height are greater than zero then use them else use fixed width and height of 200. Otherwise OMEdit will crash!!!!
    e.g BusUsage crash problem!!!!!
    */
  if (width > 0) {
    mWidth = width;
  }
  if (height > 0) {
    mHeight = height;
  }
  value = StringHandler::removeFirstLastCurlBrackets(value);
  if (value.isEmpty()) {
    return;
  }
  QStringList annotations = StringHandler::getStrings(value, '(', ')');
  foreach (QString annotation, annotations) {
    if (annotation.startsWith("Placement")) {
      annotation = annotation.mid(QString("Placement").length());
      annotation = StringHandler::removeFirstLastParentheses(annotation);
      QStringList list = StringHandler::getStrings(annotation);
      // get transformations of diagram
      // get the visible value
      mVisible = list.at(0).contains("true");
      // origin x position
      mOriginDiagram.setX(list.at(1).toFloat(&mHasOriginDiagramX));
      // origin y position
      mOriginDiagram.setY(list.at(2).toFloat(&mHasOriginDiagramY));
      // extent1 x
      mExtent1Diagram.setX(list.at(3).toFloat());
      // extent1 y
      mExtent1Diagram.setY(list.at(4).toFloat());
      // extent2 x
      mExtent2Diagram.setX(list.at(5).toFloat());
      // extent2 y
      mExtent2Diagram.setY(list.at(6).toFloat());
      // rotate angle
      mRotateAngleDiagram = list.at(7).toFloat();
      // get transformations of icon now
      // origin x position
      bool hasExtent1X, hasExtent1Y, hasExtent2X, hasExtent2Y, hasRotation = false;
      mOriginIcon.setX(list.at(8).toFloat(&mHasOriginIconX));
      // origin y position
      mOriginIcon.setY(list.at(9).toFloat(&mHasOriginIconY));
      // extent1 x
      mExtent1Icon.setX(list.at(10).toFloat(&hasExtent1X));
      // extent1 y
      mExtent1Icon.setY(list.at(11).toFloat(&hasExtent1Y));
      // extent1 x
      mExtent2Icon.setX(list.at(12).toFloat(&hasExtent2X));
      // extent1 y
      mExtent2Icon.setY(list.at(13).toFloat(&hasExtent2Y));
      // rotate angle
      if (list.size() > 14) {
        mRotateAngleIcon = list.at(14).toFloat(&hasRotation);
      }
      /* Ticket:4215
       * Only use transformation values when no iconTransformation value is available. Don't mix.
       */
      if (!mHasOriginIconX && !mHasOriginIconY && !hasExtent1X && !hasExtent1Y && !hasExtent2X && !hasExtent2Y && !hasRotation) {
        mOriginIcon.setX(mOriginDiagram.x());
        mOriginIcon.setY(mOriginDiagram.y());
        mExtent1Icon.setX(mExtent1Diagram.x());
        mExtent1Icon.setY(mExtent1Diagram.y());
        mExtent2Icon.setX(mExtent2Diagram.x());
        mExtent2Icon.setY(mExtent2Diagram.y());
        mRotateAngleIcon = mRotateAngleDiagram;
      }
    }
  }
}

void Transformation::updateTransformation(const Transformation &transformation)
{
  mValid = transformation.isValid();
  mpComponent = transformation.getComponent();
  mViewType = transformation.getViewType();
  mWidth = transformation.getWidth();
  mHeight = transformation.getHeight();
  mVisible = transformation.getVisible();
  mOriginDiagram = transformation.getOriginDiagram();
  mHasOriginDiagramX = transformation.hasOriginDiagramX();
  mHasOriginDiagramY = transformation.hasOriginDiagramY();
  mExtent1Diagram = transformation.getExtent1Diagram();
  mExtent2Diagram = transformation.getExtent2Diagram();
  mRotateAngleDiagram = transformation.getRotateAngleDiagram();
  mPositionDiagram = transformation.getPositionDiagram();
  mOriginIcon = transformation.getOriginIcon();
  mHasOriginIconX = transformation.hasOriginIconX();
  mHasOriginIconY = transformation.hasOriginIconY();
  mExtent1Icon = transformation.getExtent1Icon();
  mExtent2Icon = transformation.getExtent2Icon();
  mRotateAngleIcon = transformation.getRotateAngleIcon();
  mPositionIcon = transformation.getPositionIcon();
}

QTransform Transformation::getTransformationMatrix()
{
  switch (mViewType) {
    case StringHandler::Icon:
      return getTransformationMatrixIcon();
    case StringHandler::Diagram:
    case StringHandler::ModelicaText:
    default:
      return getTransformationMatrixDiagram();
  }
}

void Transformation::adjustPosition(qreal x, qreal y)
{
  switch (mViewType) {
    case StringHandler::Icon:
      adjustPositionIcon(x, y);
      break;
    case StringHandler::Diagram:
    case StringHandler::ModelicaText:
    default:
      adjustPositionDiagram(x, y);
      break;
  }
}

bool Transformation::hasOrigin()
{
  switch (mViewType) {
    case StringHandler::Icon:
      return hasOriginIcon();
    case StringHandler::Diagram:
    case StringHandler::ModelicaText:
    default:
      return hasOriginDiagram();
  }
}

void Transformation::setOrigin(QPointF origin)
{
  switch (mViewType) {
    case StringHandler::Icon:
      setOriginIcon(origin);
      break;
    case StringHandler::Diagram:
    case StringHandler::ModelicaText:
    default:
      setOriginDiagram(origin);
      break;
  }
}

QPointF Transformation::getOrigin() const
{
  switch (mViewType) {
    case StringHandler::Icon:
      return getOriginIcon();
    case StringHandler::Diagram:
    case StringHandler::ModelicaText:
    default:
      return getOriginDiagram();
  }
}

QPointF Transformation::getPosition()
{
  switch (mViewType) {
    case StringHandler::Icon:
      return getPositionIcon();
    case StringHandler::Diagram:
    case StringHandler::ModelicaText:
    default:
      return getPositionDiagram();
  }
}

bool Transformation::operator==(const Transformation &transformation) const
{
  return (transformation.getVisible() == this->getVisible()) &&
      (transformation.getOrigin().x() == this->getOrigin().x()) &&
      (transformation.getOrigin().y() == this->getOrigin().y()) &&
      (transformation.getExtent1().x() == this->getExtent1().x()) &&
      (transformation.getExtent1().y() == this->getExtent1().y()) &&
      (transformation.getExtent2().x() == this->getExtent2().x()) &&
      (transformation.getExtent2().y() == this->getExtent2().y()) &&
      (transformation.getRotateAngle() == this->getRotateAngle());
}

void Transformation::setExtent1(QPointF extent)
{
  switch (mViewType) {
    case StringHandler::Icon:
      setExtent1Icon(extent);
      break;
    case StringHandler::Diagram:
    case StringHandler::ModelicaText:
    default:
      setExtent1Diagram(extent);
      break;
  }
}

QPointF Transformation::getExtent1() const
{
  switch (mViewType) {
    case StringHandler::Icon:
      return getExtent1Icon();
    case StringHandler::Diagram:
    case StringHandler::ModelicaText:
    default:
      return getExtent1Diagram();
  }
}

void Transformation::setExtent2(QPointF extent)
{
  switch (mViewType) {
    case StringHandler::Icon:
      setExtent2Icon(extent);
      break;
    case StringHandler::Diagram:
    case StringHandler::ModelicaText:
    default:
      setExtent2Diagram(extent);
      break;
  }
}

QPointF Transformation::getExtent2() const
{
  switch (mViewType) {
    case StringHandler::Icon:
      return getExtent2Icon();
    case StringHandler::Diagram:
    case StringHandler::ModelicaText:
    default:
      return getExtent2Diagram();
  }
}

void Transformation::setRotateAngle(qreal rotateAngle)
{
  switch (mViewType) {
    case StringHandler::Icon:
      setRotateAngleIcon(rotateAngle);
      break;
    case StringHandler::Diagram:
    case StringHandler::ModelicaText:
    default:
      setRotateAngleDiagram(rotateAngle);
      break;
  }
}

qreal Transformation::getRotateAngle() const
{
  switch (mViewType) {
    case StringHandler::Icon:
      return getRotateAngleIcon();
    case StringHandler::Diagram:
    case StringHandler::ModelicaText:
    default:
      return getRotateAngleDiagram();
  }
}

QTransform Transformation::getTransformationMatrixDiagram()
{
  // calculate X position
  mPositionDiagram.setX(mOriginDiagram.x() + ((mExtent1Diagram.x() + mExtent2Diagram.x()) / 2));
  // calculate Y position
  mPositionDiagram.setY(mOriginDiagram.y() + ((mExtent1Diagram.y() + mExtent2Diagram.y()) / 2));
  /* Ticket #3032. Adjust position based on the coordinate system of the component. */
  if (mpComponent) {
    mPositionDiagram = mPositionDiagram - (mpComponent->boundingRect().center() * mpComponent->getCoOrdinateSystem().getInitialScale());
  }
  // get scale
  qreal tempwidth = fabs(mExtent1Diagram.x() - mExtent2Diagram.x());
  qreal sx = tempwidth / mWidth;
  qreal tempHeight = fabs(mExtent1Diagram.y() - mExtent2Diagram.y());
  qreal sy = tempHeight / mHeight;
  // get the horizontal flip
  if (mExtent2Diagram.x() < mExtent1Diagram.x()) {
    sx = -sx;
  }
  // get the vertical flip
  if (mExtent2Diagram.y() < mExtent1Diagram.y()) {
    sy = -sy;
  }
  // rotation origin point
  QPointF rotationOriginPoint;
  if (mHasOriginDiagramX && mHasOriginDiagramY) {
    rotationOriginPoint = mOriginDiagram;
  } else {
    rotationOriginPoint = mPositionDiagram;
  }
  // return the transformations
  return QTransform().translate(rotationOriginPoint.x(), rotationOriginPoint.y())
      .rotate(mRotateAngleDiagram)
      .translate(-rotationOriginPoint.x(), -rotationOriginPoint.y())
      .translate(mPositionDiagram.x(), mPositionDiagram.y())
      .scale(sx, sy);
}

void Transformation::adjustPositionDiagram(qreal x, qreal y)
{
  // adjust X position
  if (mHasOriginDiagramX) {
    mOriginDiagram.setX(mOriginDiagram.x() +  x);
  } else {
    mExtent1Diagram.setX(mExtent1Diagram.x() +  x);
    mExtent2Diagram.setX(mExtent2Diagram.x() +  x);
  }
  // adjust Y position
  if (mHasOriginDiagramY) {
    mOriginDiagram.setY(mOriginDiagram.y() +  y);
  } else {
    mExtent1Diagram.setY(mExtent1Diagram.y() +  y);
    mExtent2Diagram.setY(mExtent2Diagram.y() +  y);
  }
}

void Transformation::setOriginDiagram(QPointF origin)
{
  mHasOriginDiagramX = true;
  mHasOriginDiagramY = true;
  mOriginDiagram = origin;
}

QTransform Transformation::getTransformationMatrixIcon()
{
  // calculate X position
  mPositionIcon.setX(mOriginIcon.x() + ((mExtent1Icon.x() + mExtent2Icon.x()) / 2));
  // calculate Y position
  mPositionIcon.setY(mOriginIcon.y() + ((mExtent1Icon.y() + mExtent2Icon.y()) / 2));
  /* Ticket #3032. Adjust position based on the coordinate system of the component. */
  if (mpComponent) {
    mPositionIcon = mPositionIcon - (mpComponent->boundingRect().center() * mpComponent->getCoOrdinateSystem().getInitialScale());
  }
  // get scale
  qreal tempwidth = fabs(mExtent1Icon.x() - mExtent2Icon.x());
  qreal sx = tempwidth / mWidth;
  qreal tempHeight = fabs(mExtent1Icon.y() - mExtent2Icon.y());
  qreal sy = tempHeight / mHeight;
  // get the horizontal flip
  if (mExtent2Icon.x() < mExtent1Icon.x()) {
    sx = -sx;
  }
  // get the vertical flip
  if (mExtent2Icon.y() < mExtent1Icon.y()) {
    sy = -sy;
  }
  // rotation origin point
  QPointF rotationOriginPoint;
  if (mHasOriginIconX && mHasOriginIconY) {
    rotationOriginPoint = mOriginIcon;
  } else {
    rotationOriginPoint = mPositionIcon;
  }
  // return the transformations
  return QTransform().translate(rotationOriginPoint.x(), rotationOriginPoint.y())
      .rotate(mRotateAngleIcon)
      .translate(-rotationOriginPoint.x(), -rotationOriginPoint.y())
      .translate(mPositionIcon.x(), mPositionIcon.y())
      .scale(sx, sy);
}

void Transformation::adjustPositionIcon(qreal x, qreal y)
{
  // determine X position
  if (mHasOriginIconX) {
    mOriginIcon.setX(mOriginIcon.x() +  x);
  } else {
    mExtent1Icon.setX(mExtent1Icon.x() +  x);
    mExtent2Icon.setX(mExtent2Icon.x() +  x);
  }
  // determine Y position
  if (mHasOriginIconY) {
    mOriginIcon.setY(mOriginIcon.y() +  y);
  } else {
    mExtent1Icon.setY(mExtent1Icon.y() +  y);
    mExtent2Icon.setY(mExtent2Icon.y() +  y);
  }
}

void Transformation::setOriginIcon(QPointF origin)
{
  mHasOriginIconX = true;
  mHasOriginIconY = true;
  mOriginIcon = origin;
}
