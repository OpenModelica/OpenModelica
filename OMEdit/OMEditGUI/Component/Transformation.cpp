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

#include <stdexcept>
#include "Transformation.h"

Transformation::Transformation(StringHandler::ViewType viewType)
{
  mViewType = viewType;
  mWidth = 200.0;
  mHeight = 200.0;
  mVisible = true;
  mPositionXDiagram = 0.0;
  mPositionYDiagram = 0.0;
  mFlipHorizontalDiagram = false;
  mFlipVerticalDiagram = false;
  mRotateAngleDiagram = 0.0;
  mScaleDiagram = 1.0;
  mAspectRatioDiagram = 1.0;
  mPositionXIcon = 0.0;
  mPositionYIcon = 0.0;
  mFlipHorizontalIcon = false;
  mFlipVerticalIcon = false;
  mRotateAngleIcon = 0.0;
  mScaleIcon = 1.0;
  mAspectRatioIcon = 1.0;
}

void Transformation::parseTransformationString(QString value, qreal width, qreal height)
{
  /*
    if width and height are greater than zero then use them else use fixed width and height of 200. Otherwise OMEdit will crash!!!!
    e.g BusUsage crash problem!!!!!
    */
  if (width > 0)
    mWidth = width;
  if (height > 0)
    mHeight = height;
  value = StringHandler::removeFirstLastCurlBrackets(value);
  if (value.isEmpty())
    return;
  QStringList annotations = StringHandler::getStrings(value, '(', ')');
  foreach (QString annotation, annotations)
  {
    if (annotation.startsWith("Placement"))
    {
      annotation = annotation.mid(QString("Placement").length());
      annotation = StringHandler::removeFirstLastBrackets(annotation);
      QStringList list = StringHandler::getStrings(annotation);
      // get transformations of diagram
      // get the visible value
      mVisible = static_cast<QString>(list.at(0)).contains("true");
      // origin x position
      mOriginDiagram.setX(static_cast<QString>(list.at(1)).toFloat());
      // origin y position
      mOriginDiagram.setY(static_cast<QString>(list.at(2)).toFloat());
      // extent1 x
      mExtent1Diagram.setX(static_cast<QString>(list.at(3)).toFloat());
      // extent1 y
      mExtent1Diagram.setY(static_cast<QString>(list.at(4)).toFloat());
      // extent2 x
      mExtent2Diagram.setX(static_cast<QString>(list.at(5)).toFloat());
      // extent2 y
      mExtent2Diagram.setY(static_cast<QString>(list.at(6)).toFloat());
      // rotate angle
      mRotateAngleDiagram = static_cast<QString>(list.at(7)).toFloat();
      try
      {
  // get transformations of icon now
  // origin x position
  bool ok = true;
  mOriginIcon.setX(static_cast<QString>(list.at(8)).toFloat(&ok));
  if (!ok)
    throw std::runtime_error("Invalid number format exception");
  // origin y position
  mOriginIcon.setY(static_cast<QString>(list.at(9)).toFloat(&ok));
  if (!ok)
    throw std::runtime_error("Invalid number format exception");
  // extent1 x
  mExtent1Icon.setX(static_cast<QString>(list.at(10)).toFloat(&ok));
  if (!ok)
    throw std::runtime_error("Invalid number format exception");
  // extent1 y
  mExtent1Icon.setY(static_cast<QString>(list.at(11)).toFloat(&ok));
  if (!ok)
    throw std::runtime_error("Invalid number format exception");
  // extent1 x
  mExtent2Icon.setX(static_cast<QString>(list.at(12)).toFloat(&ok));
  if (!ok)
    throw std::runtime_error("Invalid number format exception");
  // extent1 y
  mExtent2Icon.setY(static_cast<QString>(list.at(13)).toFloat(&ok));
  if (!ok)
    throw std::runtime_error("Invalid number format exception");
  // rotate angle
  mRotateAngleIcon = static_cast<QString>(list.at(14)).toFloat(&ok);
  if (!ok)
    throw std::runtime_error("Invalid number format exception");
      }
      catch(std::exception &exception)
      {
  Q_UNUSED(exception);
  mOriginIcon = mOriginDiagram;
  mExtent1Icon = mExtent1Diagram;
  mExtent2Icon = mExtent2Diagram;
  mRotateAngleIcon = mRotateAngleDiagram;
      }
    }
  }
}

QTransform Transformation::getTransformationMatrix()
{
  switch (mViewType)
  {
    case StringHandler::Diagram:
      return getTransformationMatrixDiagram();
    case StringHandler::Icon:
      return getTransformationMatrixIcon();
    case StringHandler::ModelicaText:
    default:
      return getTransformationMatrixDiagram();
  }
}

bool Transformation::getVisible()
{
  return mVisible;
}

void Transformation::setOrigin(QPointF origin)
{
  switch (mViewType)
  {
    case StringHandler::Diagram:
      setOriginDiagram(origin);
      break;
    case StringHandler::Icon:
      setOriginIcon(origin);
      break;
    case StringHandler::ModelicaText:
    default:
      setOriginDiagram(origin);
      break;
  }
}

QPointF Transformation::getOrigin()
{
  switch (mViewType)
  {
    case StringHandler::Diagram:
      return getOriginDiagram();
    case StringHandler::Icon:
      return getOriginIcon();
    case StringHandler::ModelicaText:
    default:
      return getOriginDiagram();
  }
}

void Transformation::setExtent1(QPointF extent)
{
  switch (mViewType)
  {
    case StringHandler::Diagram:
      setExtent1Diagram(extent);
      break;
    case StringHandler::Icon:
      setExtent1Icon(extent);
      break;
    case StringHandler::ModelicaText:
    default:
      setExtent1Diagram(extent);
      break;
  }
}

QPointF Transformation::getExtent1()
{
  switch (mViewType)
  {
    case StringHandler::Diagram:
      return getExtent1Diagram();
    case StringHandler::Icon:
      return getExtent1Icon();
    case StringHandler::ModelicaText:
    default:
      return getExtent1Diagram();
  }
}

void Transformation::setExtent2(QPointF extent)
{
  switch (mViewType)
  {
    case StringHandler::Diagram:
      setExtent2Diagram(extent);
      break;
    case StringHandler::Icon:
      setExtent2Icon(extent);
      break;
    case StringHandler::ModelicaText:
    default:
      setExtent2Diagram(extent);
      break;
  }
}

QPointF Transformation::getExtent2()
{
  switch (mViewType)
  {
    case StringHandler::Diagram:
      return getExtent2Diagram();
    case StringHandler::Icon:
      return getExtent2Icon();
    case StringHandler::ModelicaText:
    default:
      return getExtent2Diagram();
  }
}

void Transformation::setRotateAngle(qreal rotateAngle)
{
  switch (mViewType)
  {
    case StringHandler::Diagram:
      setRotateAngleDiagram(rotateAngle);
      break;
    case StringHandler::Icon:
      setRotateAngleIcon(rotateAngle);
      break;
    case StringHandler::ModelicaText:
    default:
      setRotateAngleDiagram(rotateAngle);
      break;
  }
}

qreal Transformation::getRotateAngle()
{
  switch (mViewType)
  {
    case StringHandler::Diagram:
      return getRotateAngleDiagram();
    case StringHandler::Icon:
      return getRotateAngleIcon();
    case StringHandler::ModelicaText:
    default:
      return getRotateAngleDiagram();
  }
}

qreal Transformation::getScale()
{
  switch (mViewType)
  {
    case StringHandler::Diagram:
      return getScaleDiagram();
    case StringHandler::Icon:
      return getScaleIcon();
    case StringHandler::ModelicaText:
    default:
      return getScaleDiagram();
  }
}

void Transformation::setFlipHorizontal(bool On)
{
  switch (mViewType)
  {
    case StringHandler::Diagram:
      setFlipHorizontalDiagram(On);
      break;
    case StringHandler::Icon:
      setFlipHorizontalIcon(On);
      break;
    case StringHandler::ModelicaText:
    default:
      setFlipHorizontalDiagram(On);
      break;
  }
}

bool Transformation::getFlipHorizontal()
{
  switch (mViewType)
  {
    case StringHandler::Diagram:
      return getFlipHorizontalDiagram();
    case StringHandler::Icon:
      return getFlipHorizontalIcon();
    case StringHandler::ModelicaText:
    default:
      return getFlipHorizontalDiagram();
  }
}

void Transformation::setFlipVertical(bool On)
{
  switch (mViewType)
  {
    case StringHandler::Diagram:
      setFlipVerticalDiagram(On);
      break;
    case StringHandler::Icon:
      setFlipVerticalIcon(On);
      break;
    case StringHandler::ModelicaText:
    default:
      setFlipVerticalDiagram(On);
      break;
  }
}

bool Transformation::getFlipVertical()
{
  switch (mViewType)
  {
    case StringHandler::Diagram:
      return getFlipVerticalDiagram();
    case StringHandler::Icon:
      return getFlipVerticalIcon();
    case StringHandler::ModelicaText:
    default:
      return getFlipVerticalDiagram();
  }
}

QTransform Transformation::getTransformationMatrixDiagram()
{
  QPoint extent1 = mExtent1Diagram.toPoint();
  QPoint extent2 = mExtent2Diagram.toPoint();
  if ((extent1.x() == -extent2.x()) and (extent1.y() == -extent2.y()))
  {
    mPositionXDiagram = mOriginDiagram.x();
    mPositionYDiagram = mOriginDiagram.y();
  }
  else
  {
    mPositionXDiagram = (mExtent1Diagram.x() + mExtent2Diagram.x()) / 2;
    mPositionYDiagram = (mExtent1Diagram.y() + mExtent2Diagram.y()) / 2;
  }
  qreal tempwidth = fabs(mExtent1Diagram.x() - mExtent2Diagram.x());
  qreal tempHeight = fabs(mExtent1Diagram.y() - mExtent2Diagram.y());
  // get scale
  mScaleDiagram = tempwidth / mWidth;
  // get aspectratio
  mAspectRatioDiagram = tempHeight / (mHeight * mScaleDiagram);
  // get the horizontal flip
  mFlipHorizontalDiagram = mExtent2Diagram.x() < mExtent1Diagram.x();
  // get the vertical flip
  mFlipVerticalDiagram = mExtent2Diagram.y() < mExtent1Diagram.y();
  // create transformation matrix
  qreal m11, m12, m21, m22, m31, m32;
  qreal sx = mScaleDiagram;
  qreal sy = mScaleDiagram * mAspectRatioDiagram;
  // if flipping
  if (mFlipHorizontalDiagram)
    sx = -sx;
  if (mFlipVerticalDiagram)
    sy = -sy;
  // calculate horizontal scale m11 and vertical shearing m12
  m11 = sx * cos(mRotateAngleDiagram * (M_PI / 180));
  m12 = sx * sin(mRotateAngleDiagram * (M_PI / 180));
  // calculate horizontal shearing m21 and vertical scaling m22
  m21 = -sy * sin(mRotateAngleDiagram * (M_PI / 180));
  m22 = sy * cos(mRotateAngleDiagram * (M_PI / 180));
  // set origin
  m31 = mPositionXDiagram;
  m32 = mPositionYDiagram;
  // return all transformations
  return QTransform (m11, m12, m21, m22, m31, m32);
}

QTransform Transformation::getTransformationMatrixIcon()
{
  QPoint extent1 = mExtent1Icon.toPoint();
  QPoint extent2 = mExtent2Icon.toPoint();
  if ((extent1.x() == -extent2.x()) and (extent1.y() == -extent2.y()))
  {
    mPositionXIcon = mOriginIcon.x();
    mPositionYIcon = mOriginIcon.y();
  }
  else
  {
    mPositionXIcon = (mExtent1Icon.x() + mExtent2Icon.x()) / 2;
    mPositionYIcon = (mExtent1Icon.y() + mExtent2Icon.y()) / 2;
  }
  qreal tempwidthIcon = fabs(mExtent1Icon.x() - mExtent2Icon.x());
  qreal tempHeightIcon = fabs(mExtent1Icon.y() - mExtent2Icon.y());
  // get scale
  mScaleIcon = tempwidthIcon / mWidth;
  // get aspectratio
  mAspectRatioIcon = tempHeightIcon / (mHeight * mScaleIcon);
  // get the horizontal flip
  mFlipHorizontalIcon = mExtent2Icon.x() < mExtent1Icon.x();
  // get the vertical flip
  mFlipVerticalIcon = mExtent2Icon.y() < mExtent1Icon.y();
  // create transformation matrix
  qreal m11, m12, m21, m22, m31, m32;
  qreal sx = mScaleIcon;
  qreal sy = mScaleIcon * mAspectRatioIcon;
  // if flipping
  if (mFlipHorizontalIcon)
    sx = -sx;
  if (mFlipVerticalIcon)
    sy = -sy;
  // calculate horizontal and vertical scaling
  m11 = sx * cos(mRotateAngleIcon * (M_PI / 180));
  m12 = sx * sin(mRotateAngleIcon * (M_PI / 180));
  // calculate horizontal and vertical shearing
  m21 = -sy * sin(mRotateAngleIcon * (M_PI / 180));
  m22 = sy * cos(mRotateAngleIcon * (M_PI / 180));
  // set origin
  m31 = mPositionXIcon;
  m32 = mPositionYIcon;
  // return all transformations
  return QTransform (m11, m12, m21, m22, m31, m32);
}

void Transformation::setOriginDiagram(QPointF origin)
{
  mOriginDiagram = origin;
}

QPointF Transformation::getOriginDiagram()
{
  return QPointF(mPositionXDiagram, mPositionYDiagram);
}

void Transformation::setExtent1Diagram(QPointF extent)
{
  mExtent1Diagram = extent;
}

QPointF Transformation::getExtent1Diagram()
{
  return mExtent1Diagram;
}

void Transformation::setExtent2Diagram(QPointF extent)
{
  mExtent2Diagram = extent;
}

QPointF Transformation::getExtent2Diagram()
{
  return mExtent2Diagram;
}

void Transformation::setRotateAngleDiagram(qreal rotateAngle)
{
  mRotateAngleDiagram = rotateAngle;
}

qreal Transformation::getRotateAngleDiagram()
{
  return mRotateAngleDiagram;
}

qreal Transformation::getScaleDiagram()
{
  return mScaleDiagram;
}

void Transformation::setFlipHorizontalDiagram(bool On)
{
  mFlipHorizontalDiagram = On;
}

bool Transformation::getFlipHorizontalDiagram()
{
  return mFlipHorizontalDiagram;
}

void Transformation::setFlipVerticalDiagram(bool On)
{
  mFlipVerticalDiagram = On;
}

bool Transformation::getFlipVerticalDiagram()
{
  return mFlipVerticalDiagram;
}

void Transformation::setOriginIcon(QPointF origin)
{
  mOriginIcon = origin;
}

QPointF Transformation::getOriginIcon()
{
  return mOriginIcon;
}

void Transformation::setExtent1Icon(QPointF extent)
{
  mExtent1Icon = extent;
}

QPointF Transformation::getExtent1Icon()
{
  return mExtent1Icon;
}

void Transformation::setExtent2Icon(QPointF extent)
{
  mExtent2Icon = extent;
}

QPointF Transformation::getExtent2Icon()
{
  return mExtent2Icon;
}

void Transformation::setRotateAngleIcon(qreal rotateAngle)
{
  mRotateAngleIcon = rotateAngle;
}

qreal Transformation::getRotateAngleIcon()
{
  return mRotateAngleIcon;
}

qreal Transformation::getScaleIcon()
{
  return mScaleIcon;
}

void Transformation::setFlipHorizontalIcon(bool On)
{
  mFlipHorizontalIcon = On;
}

bool Transformation::getFlipHorizontalIcon()
{
  return mFlipHorizontalIcon;
}

void Transformation::setFlipVerticalIcon(bool On)
{
  mFlipVerticalIcon = On;
}

bool Transformation::getFlipVerticalIcon()
{
  return mFlipVerticalIcon;
}
