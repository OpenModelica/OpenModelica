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
#include "Element.h"

#include <QStringBuilder>

Transformation::Transformation()
{
  mValid = false;
  mpComponent = 0;
  initialize(StringHandler::Diagram);
}

Transformation::Transformation(StringHandler::ViewType viewType, Element *pComponent)
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
  mExtentDiagram.clear();
  mRotateAngleDiagram = 0.0;
  mPositionDiagram = QPointF(0.0, 0.0);
  mVisibleIcon = true;
  mOriginIcon = QPointF(0.0, 0.0);
  mExtentIcon.clear();
  mRotateAngleIcon = 0.0;
  mPositionIcon = QPointF(0.0, 0.0);
  mExtentCenterDiagram = QPointF(0.0, 0.0);
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
  QString value1 = StringHandler::removeFirstLastCurlBrackets(value);
  if (value1.isEmpty()) {
    return;
  }
  QStringList annotations = StringHandler::getStrings(value1);
  foreach (QString annotation, annotations) {
    if (annotation.startsWith("Placement")) {
      annotation = annotation.mid(QString("Placement").length());
      annotation = StringHandler::removeFirstLastParentheses(annotation);
      QStringList list = StringHandler::getStrings(annotation);
      if (list.size() > 13) {
        // get transformations of diagram
        // get the visible value
        mVisible.parse(list.at(0));
        // origin
        mOriginDiagram.parse("{" % QString::number(list.at(1).toDouble()) % ", " % QString::number(list.at(2).toDouble()) % "}");
        // extent
        mExtentDiagram.parse("{{" % QString::number(list.at(3).toDouble()) % ", " % QString::number(list.at(4).toDouble()) % "}, "
                             "{"  % QString::number(list.at(5).toDouble()) % ", " % QString::number(list.at(6).toDouble()) % "}}");
        // rotate angle
        mRotateAngleDiagram.parse(QString::number(list.at(7).toDouble()));
        // get transformations of icon now
        // origin x position
        bool hasOrigin = false, hasExtent = false, hasRotation = false;
        // origin
        mOriginIcon.parse("{" % QString::number(list.at(8).toDouble(&hasOrigin)) % ", " % QString::number(list.at(9).toDouble(&hasOrigin)) % "}");
        // extent
        mExtentIcon.parse("{{" % QString::number(list.at(10).toDouble(&hasExtent)) % ", " % QString::number(list.at(11).toDouble(&hasExtent)) % "}, "
                             "{"  % QString::number(list.at(12).toDouble(&hasExtent)) % ", " % QString::number(list.at(13).toDouble(&hasExtent)) % "}}");
        // rotate angle
        mRotateAngleIcon.parse(QString::number(list.at(14).toDouble(&hasRotation)));
        /* Ticket:4215
         * Only use transformation values when no iconTransformation value is available. Don't mix.
         */
        if (!hasOrigin && !hasExtent && !hasRotation) {
          mOriginIcon = mOriginDiagram;
          mExtentIcon = mExtentDiagram;
          mRotateAngleIcon = mRotateAngleDiagram;
        }
      } else {
        qDebug() << QString("The placement annotation string format is wrong. Received %1").arg(value);
      }
    }
  }
}

void Transformation::parseTransformation(const ModelInstance::PlacementAnnotation &placementAnnotation, const ModelInstance::CoordinateSystem &coordinateSystem)
{
  /*
    if width and height are greater than zero then use them else use fixed width and height of 200. Otherwise OMEdit will crash!!!!
    e.g BusUsage crash problem!!!!!
    */
  QRectF rect = coordinateSystem.getExtentRectangle();
  if (rect.width() > 0) {
    mWidth = rect.width();
  }
  if (rect.height() > 0) {
    mHeight = rect.height();
  }
  ExtentAnnotation elementCoordinateSystemExtent = coordinateSystem.getExtent();

  if (mpComponent) {
    mExtentCenterDiagram = mpComponent->boundingRect().center();
    mExtentCenterIcon = mpComponent->boundingRect().center();
  }

  ModelInstance::Extend *pExtend = 0;
  if (mpComponent && mpComponent->getModelComponent() && mpComponent->getModelComponent()->getParentModel()) {
    pExtend = mpComponent->getModelComponent()->getParentModel()->getParentExtend();
  }

  // transformation
  mVisible = placementAnnotation.getVisible();
  mVisible.evaluate(placementAnnotation.getParentModel());
  ModelInstance::Transformation transformation = placementAnnotation.getTransformation();
  mOriginDiagram = transformation.getOrigin();
  mOriginDiagram.evaluate(placementAnnotation.getParentModel());
  mExtentDiagram = transformation.getExtent();
  mExtentDiagram.evaluate(placementAnnotation.getParentModel());
  mRotateAngleDiagram = transformation.getRotation();
  mRotateAngleDiagram.evaluate(placementAnnotation.getParentModel());
  // map values from element coordinate system to DiagramMap extent
  if (pExtend && pExtend->getIconDiagramMapHasExtent(false)) {
    ExtentAnnotation extendsCoOrdinateExtents = pExtend->getIconDiagramMapExtent(false);
    if (elementCoordinateSystemExtent.size() > 1 && extendsCoOrdinateExtents.size() > 1) {
      const qreal x1 = elementCoordinateSystemExtent.at(0).x();
      const qreal y1 = elementCoordinateSystemExtent.at(0).y();
      const qreal x2 = elementCoordinateSystemExtent.at(1).x();
      const qreal y2 = elementCoordinateSystemExtent.at(1).y();

      const qreal x3 = extendsCoOrdinateExtents.at(0).x();
      const qreal y3 = extendsCoOrdinateExtents.at(0).y();
      const qreal x4 = extendsCoOrdinateExtents.at(1).x();
      const qreal y4 = extendsCoOrdinateExtents.at(1).y();

      QPointF origin;
      origin.setX(Utilities::mapToCoOrdinateSystem(mOriginDiagram.x(), x1, x2, x3, x4));
      origin.setY(Utilities::mapToCoOrdinateSystem(mOriginDiagram.y(), y1, y2, y3, y4));
      mOriginDiagram = origin;

      QVector<QPointF> extent;
      QPointF point;
      point.setX(Utilities::mapToCoOrdinateSystem(mExtentDiagram.at(0).x(), x1, x2, x3, x4));
      point.setY(Utilities::mapToCoOrdinateSystem(mExtentDiagram.at(0).y(), y1, y2, y3, y4));
      extent.append(point);
      point.setX(Utilities::mapToCoOrdinateSystem(mExtentDiagram.at(1).x(), x1, x2, x3, x4));
      point.setY(Utilities::mapToCoOrdinateSystem(mExtentDiagram.at(1).y(), y1, y2, y3, y4));
      extent.append(point);
      mExtentDiagram = extent;

      mExtentCenterDiagram.setX(Utilities::mapToCoOrdinateSystem(mExtentCenterDiagram.x(), x1, x2, x3, x4));
      mExtentCenterDiagram.setY(Utilities::mapToCoOrdinateSystem(mExtentCenterDiagram.y(), y1, y2, y3, y4));
    }
  }
  // icon transformation
  mVisibleIcon = placementAnnotation.getIconVisible();
  mVisibleIcon.evaluate(placementAnnotation.getParentModel());
  ModelInstance::Transformation iconTransformation = placementAnnotation.getIconTransformation();
  mOriginIcon = iconTransformation.getOrigin();
  mOriginIcon.evaluate(placementAnnotation.getParentModel());
  mExtentIcon = iconTransformation.getExtent();
  mExtentIcon.evaluate(placementAnnotation.getParentModel());
  mRotateAngleIcon = iconTransformation.getRotation();
  mRotateAngleIcon.evaluate(placementAnnotation.getParentModel());
  // map values from element coordinate system to IconMap extent.
  if (pExtend && pExtend->getIconDiagramMapHasExtent(true)) {
    ExtentAnnotation extendsCoOrdinateExtents = pExtend->getIconDiagramMapExtent(true);
    if (elementCoordinateSystemExtent.size() > 1 && extendsCoOrdinateExtents.size() > 1) {
      const qreal x1 = elementCoordinateSystemExtent.at(0).x();
      const qreal y1 = elementCoordinateSystemExtent.at(0).y();
      const qreal x2 = elementCoordinateSystemExtent.at(1).x();
      const qreal y2 = elementCoordinateSystemExtent.at(1).y();

      const qreal x3 = extendsCoOrdinateExtents.at(0).x();
      const qreal y3 = extendsCoOrdinateExtents.at(0).y();
      const qreal x4 = extendsCoOrdinateExtents.at(1).x();
      const qreal y4 = extendsCoOrdinateExtents.at(1).y();

      QPointF origin;
      origin.setX(Utilities::mapToCoOrdinateSystem(mOriginIcon.x(), x1, x2, x3, x4));
      origin.setY(Utilities::mapToCoOrdinateSystem(mOriginIcon.y(), y1, y2, y3, y4));
      mOriginIcon = origin;

      QVector<QPointF> extent;
      QPointF point;
      point.setX(Utilities::mapToCoOrdinateSystem(mExtentIcon.at(0).x(), x1, x2, x3, x4));
      point.setY(Utilities::mapToCoOrdinateSystem(mExtentIcon.at(0).y(), y1, y2, y3, y4));
      extent.append(point);
      point.setX(Utilities::mapToCoOrdinateSystem(mExtentIcon.at(1).x(), x1, x2, x3, x4));
      point.setY(Utilities::mapToCoOrdinateSystem(mExtentIcon.at(1).y(), y1, y2, y3, y4));
      extent.append(point);
      mExtentIcon = extent;

      mExtentCenterIcon.setX(Utilities::mapToCoOrdinateSystem(mExtentCenterIcon.x(), x1, x2, x3, x4));
      mExtentCenterIcon.setY(Utilities::mapToCoOrdinateSystem(mExtentCenterIcon.y(), y1, y2, y3, y4));
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
  mExtentDiagram = transformation.getExtentDiagram();
  mRotateAngleDiagram = transformation.getRotateAngleDiagram();
  mPositionDiagram = transformation.getPositionDiagram();
  mExtentCenterDiagram = transformation.getExtentCenterDiagram();
  mVisibleIcon = transformation.getVisibleIcon();
  mOriginIcon = transformation.getOriginIcon();
  mExtentIcon = transformation.getExtentIcon();
  mRotateAngleIcon = transformation.getRotateAngleIcon();
  mPositionIcon = transformation.getPositionIcon();
  mExtentCenterIcon = transformation.getExtentCenterIcon();
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

PointAnnotation Transformation::getOrigin() const
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

void Transformation::setExtentCenter(QPointF extentCenter)
{
  switch (mViewType) {
    case StringHandler::Icon:
      setExtentCenterIcon(extentCenter);
      break;
    case StringHandler::Diagram:
    case StringHandler::ModelicaText:
    default:
      setExtentCenterDiagram(extentCenter);
      break;
  }
}

bool Transformation::operator==(const Transformation &transformation) const
{
  return (transformation.getVisible() == this->getVisible()) &&
      (transformation.getVisibleIcon() == this->getVisibleIcon()) &&
      (transformation.getOrigin() == this->getOrigin()) &&
      (transformation.getExtent() == this->getExtent()) &&
      (transformation.getRotateAngle() == this->getRotateAngle());
}

void Transformation::setExtent(QVector<QPointF> extent)
{
  switch (mViewType) {
    case StringHandler::Icon:
      setExtentIcon(extent);
      break;
    case StringHandler::Diagram:
    case StringHandler::ModelicaText:
    default:
      setExtentDiagram(extent);
      break;
  }
}

ExtentAnnotation Transformation::getExtent() const
{
  switch (mViewType) {
    case StringHandler::Icon:
      return getExtentIcon();
    case StringHandler::Diagram:
    case StringHandler::ModelicaText:
    default:
      return getExtentDiagram();
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

RealAnnotation Transformation::getRotateAngle() const
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

QTransform Transformation::getTransformationMatrixDiagram() const
{
  // calculate position
  QPointF position = getPositionDiagram();
  // get scale
  const QPointF extent1Diagram = mExtentDiagram.at(0);
  const QPointF extent2Diagram = mExtentDiagram.at(1);
  qreal tempwidth = qFabs(extent1Diagram.x() - extent2Diagram.x());
  qreal sx = tempwidth / (mWidth > 0 ? mWidth : 1);
  if (!mpComponent && qFuzzyCompare(sx, 0.0)) {
    sx = 1;
  }
  qreal tempHeight = qFabs(extent1Diagram.y() - extent2Diagram.y());
  qreal sy = tempHeight / (mHeight > 0 ? mHeight : 1);
  if (!mpComponent && qFuzzyCompare(sy, 0.0)) {
    sy = 1;
  }

  // get the horizontal flip
  if (extent2Diagram.x() < extent1Diagram.x()) {
    sx = -sx;
  }
  // get the vertical flip
  if (extent2Diagram.y() < extent1Diagram.y()) {
    sy = -sy;
  }
  // return the transformations
  if (mpComponent) {
    QTransform transformationMatrix = QTransform::fromTranslate(-mExtentCenterDiagram.x(), -mExtentCenterDiagram.y());
    transformationMatrix *= QTransform::fromScale(sx, sy);
    transformationMatrix *= QTransform::fromTranslate(position.x(), position.y());
    transformationMatrix *= QTransform().translate(mOriginDiagram.x(), mOriginDiagram.y()).rotate(mRotateAngleDiagram).translate(-mOriginDiagram.x(), -mOriginDiagram.y());
    return transformationMatrix;
  } else {
    QPointF extentCentre;
    extentCentre.setX((extent1Diagram.x() + extent2Diagram.x()) / 2);
    extentCentre.setY((extent1Diagram.y() + extent2Diagram.y()) / 2);

    QTransform transformationMatrix = QTransform().translate(extentCentre.x(), extentCentre.y()).scale(sx, sy).translate(-extentCentre.x(), -extentCentre.y());
    transformationMatrix *= QTransform::fromTranslate(mOriginDiagram.x(), mOriginDiagram.y());
    transformationMatrix *= QTransform().translate(mOriginDiagram.x(), mOriginDiagram.y()).rotate(mRotateAngleDiagram).translate(-mOriginDiagram.x(), -mOriginDiagram.y());
    return transformationMatrix;
  }
}

void Transformation::adjustPositionDiagram(qreal x, qreal y)
{
  QPointF origin;
  // adjust X position
  origin.setX(mOriginDiagram.x() +  x);
  // adjust Y position
  origin.setY(mOriginDiagram.y() +  y);
  mOriginDiagram = origin;
}

void Transformation::setOriginDiagram(QPointF origin)
{
  mOriginDiagram = origin;
}

QPointF Transformation::getPositionDiagram() const
{
  QPointF position;
  position.setX(mOriginDiagram.x() + ((mExtentDiagram.at(0).x() + mExtentDiagram.at(1).x()) / 2));
  position.setY(mOriginDiagram.y() + ((mExtentDiagram.at(0).y() + mExtentDiagram.at(1).y()) / 2));
  return position;
}

QTransform Transformation::getTransformationMatrixIcon()
{
  // calculate position
  QPointF position = getPositionIcon();
  // get scale
  const QPointF extent1Icon = mExtentIcon.at(0);
  const QPointF extent2Icon = mExtentIcon.at(1);
  qreal tempwidth = qFabs(extent1Icon.x() - extent2Icon.x());
  qreal sx = tempwidth / (mWidth > 0 ? mWidth : 1);
  if (!mpComponent && qFuzzyCompare(sx, 0.0)) {
    sx = 1;
  }
  qreal tempHeight = qFabs(extent1Icon.y() - extent2Icon.y());
  qreal sy = tempHeight / (mHeight > 0 ? mHeight : 1);
  if (!mpComponent && qFuzzyCompare(sy, 0.0)) {
    sy = 1;
  }

  // get the horizontal flip
  if (extent2Icon.x() < extent1Icon.x()) {
    sx = -sx;
  }
  // get the vertical flip
  if (extent2Icon.y() < extent1Icon.y()) {
    sy = -sy;
  }
  // return the transformations
  if (mpComponent) {
    QTransform transformationMatrix = QTransform::fromTranslate(-mExtentCenterIcon.x(), -mExtentCenterIcon.y());
    transformationMatrix *= QTransform::fromScale(sx, sy);
    transformationMatrix *= QTransform::fromTranslate(position.x(), position.y());
    transformationMatrix *= QTransform().translate(mOriginIcon.x(), mOriginIcon.y()).rotate(mRotateAngleIcon).translate(-mOriginIcon.x(), -mOriginIcon.y());
    return transformationMatrix;
  } else {
    QPointF extentCentre;
    extentCentre.setX((extent1Icon.x() + extent2Icon.x()) / 2);
    extentCentre.setY((extent1Icon.y() + extent2Icon.y()) / 2);

    QTransform transformationMatrix = QTransform().translate(extentCentre.x(), extentCentre.y()).scale(sx, sy).translate(-extentCentre.x(), -extentCentre.y());
    transformationMatrix *= QTransform::fromTranslate(mOriginIcon.x(), mOriginIcon.y());
    transformationMatrix *= QTransform().translate(mOriginIcon.x(), mOriginIcon.y()).rotate(mRotateAngleIcon).translate(-mOriginIcon.x(), -mOriginIcon.y());
    return transformationMatrix;
  }
}

void Transformation::adjustPositionIcon(qreal x, qreal y)
{
  QPointF origin;
  // adjust X position
  origin.setX(mOriginIcon.x() +  x);
  // adjust Y position
  origin.setY(mOriginIcon.y() +  y);
  mOriginIcon = origin;
}

void Transformation::setOriginIcon(QPointF origin)
{
  mOriginIcon = origin;
}

QPointF Transformation::getPositionIcon() const
{
  QPointF position;
  position.setX(mOriginIcon.x() + ((mExtentIcon.at(0).x() + mExtentIcon.at(1).x()) / 2));
  position.setY(mOriginIcon.y() + ((mExtentIcon.at(0).y() + mExtentIcon.at(1).y()) / 2));
  return position;
}
