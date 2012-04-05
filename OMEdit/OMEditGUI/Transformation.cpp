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

/*
 * RCS: $Id$
 */

#include <stdexcept>

#include "Transformation.h"

Transformation::Transformation(Component *pComponent)
{
  mVisible = true;
  mPositionX = 0.0;
  mPositionXIcon = 0.0;
  mPositionY = 0.0;
  mPositionYIcon = 0.0;
  mFlipHorizontal = false;
  mFlipHorizontalIcon = false;
  mFlipVertical = false;
  mFlipVerticalIcon = false;
  mRotateAngle = 0.0;
  mRotateAngleIcon = 0.0;
  mScale = 1.0;
  mScaleIcon = 1.0;
  mAspectRatio = 1.0;
  mAspectRatioIcon = 1.0;

  mpComponent = pComponent;

  if (mpComponent->mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
    parseTransformationString3X(mpComponent->mTransformationString);
  else if (mpComponent->mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION2X)
    parseTransformationString2X(mpComponent->mTransformationString);
}

void Transformation::parseTransformationString2X(QString value)
{
  value = StringHandler::removeFirstLastCurlBrackets(value);
  if (value.isEmpty())
    return;
  QStringList list = StringHandler::getStrings(value);
  int i = 0;

  // get the visible value
  mVisible = static_cast<QString>(list.at(0)).contains("true");
  // parse the values for diagram
  if (mpComponent->mType == StringHandler::DIAGRAM)
  {
    mPositionX = static_cast<QString>(list.at(1)).toFloat();
    // y position
    mPositionY = static_cast<QString>(list.at(2)).toFloat();
    // scale
    mScale = static_cast<QString>(list.at(3)).toFloat();
    // aspectratio
    mAspectRatio = static_cast<QString>(list.at(4)).toFloat();
    // flip horizontal
    mFlipHorizontal = static_cast<QString>(list.at(5)).contains("true");
    // flip vertical
    mFlipVertical = static_cast<QString>(list.at(6)).contains("true");
    // rotate angle
    mRotateAngle = static_cast<QString>(list.at(7)).toFloat();
  }
  // now parse the values for icon
  // x position
  else if (mpComponent->mType == StringHandler::ICON)
  {
    mPositionX = static_cast<QString>(list.at(8)).toFloat();
    // y position
    mPositionY = static_cast<QString>(list.at(9)).toFloat();
    // scale
    mScale = static_cast<QString>(list.at(10)).toFloat();
    // aspectratio
    mAspectRatio = static_cast<QString>(list.at(11)).toFloat();
    // flip horizontal
    mFlipHorizontal = static_cast<QString>(list.at(12)).contains("true");
    // flip vertical
    mFlipVertical = static_cast<QString>(list.at(13)).contains("true");
    // rotate angle
    mRotateAngle = static_cast<QString>(list.at(14)).toFloat();
  }
}

void Transformation::parseTransformationString3X(QString value)
{
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

      mWidth = mpComponent->boundingRect().width();
      mHeight = mpComponent->boundingRect().height();

      // if mWidth and mHeight is zero then give it fixed with and height of 200. Otherwise OMEdit will crash!!!!
      // e.g BusUsage crash problem!!!!!
      if (mWidth < 1)
        mWidth = 200.0;
      if (mHeight < 1)
        mHeight = 200.0;

      // get transformations of diagram
      // get the visible value
      mVisible = static_cast<QString>(list.at(0)).contains("true");
      // origin x position
      mOrigin.setX(static_cast<QString>(list.at(1)).toFloat());
      // origin y position
      mOrigin.setY(static_cast<QString>(list.at(2)).toFloat());
      // extent1 x
      mExtent1.setX(static_cast<QString>(list.at(3)).toFloat());
      // extent1 y
      mExtent1.setY(static_cast<QString>(list.at(4)).toFloat());
      // extent1 x
      mExtent2.setX(static_cast<QString>(list.at(5)).toFloat());
      // extent1 y
      mExtent2.setY(static_cast<QString>(list.at(6)).toFloat());

      if ((mExtent1.x() == -mExtent2.x()) and (mExtent1.y() == -mExtent2.y()))
      {
        mPositionX = mOrigin.x();
        mPositionY = mOrigin.y();
      }
      else
      {
        mPositionX = (mExtent1.x() + mExtent2.x()) / 2;
        mPositionY = (mExtent1.y() + mExtent2.y()) / 2;
      }

      qreal tempwidth = fabs(mExtent1.x() - mExtent2.x());
      qreal tempHeight = fabs(mExtent1.y() - mExtent2.y());

      mScale = tempwidth / mWidth;
      mAspectRatio = tempHeight / (mHeight * mScale);

      mFlipHorizontal = mExtent2.x() < mExtent1.x();
      mFlipVertical = mExtent2.y() < mExtent1.y();

      // rotate angle
      mRotateAngle = static_cast<QString>(list.at(7)).toFloat();

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
        mOriginIcon = mOrigin;
        mExtent1Icon = mExtent1;
        mExtent2Icon = mExtent2;
        mRotateAngleIcon = mRotateAngle;
      }
      if ((mExtent1Icon.x() == -mExtent2Icon.x()) and (mExtent1Icon.y() == -mExtent2Icon.y()))
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

      mScaleIcon = tempwidthIcon / mWidth;
      mAspectRatioIcon = tempHeightIcon / (mHeight * mScale);

      mFlipHorizontalIcon = mExtent2Icon.x() < mExtent1Icon.x();
      mFlipVerticalIcon = mExtent2Icon.y() < mExtent1Icon.y();
    }
  }
}

QTransform Transformation::getTransformationMatrix()
{
  qreal m11, m12, m21, m22, m31, m32;

  qreal sx = mScale;
  qreal sy = mScale * mAspectRatio;

  if (mpComponent->mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION2X)
  {
    if (mFlipHorizontal)
      sy = -sy;
    if (mFlipVertical)
      sx = -sx;
  }
  else if (mpComponent->mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
  {
    if (mFlipHorizontal)
      sx = -sx;
    if (mFlipVertical)
      sy = -sy;
  }

  m11 = sx * cos(mRotateAngle * (M_PI / 180));
  m12 = sx * sin(mRotateAngle * (M_PI / 180));

  m21 = -sy * sin(mRotateAngle * (M_PI / 180));
  m22 = sy * cos(mRotateAngle * (M_PI / 180));

  m31 = mPositionX;
  m32 = mPositionY;

  return QTransform (m11, m12, m21, m22, m31, m32);
}

QTransform Transformation::getLibraryTransformationMatrix()
{
  qreal m11, m12, m21, m22, m31, m32;

  qreal sx = mScale;
  qreal sy = mScale * mAspectRatio;

  mRotateAngle = -mRotateAngle;

  if (mpComponent->mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION2X)
  {
    if (mFlipHorizontal)
      sy = -sy;
    if (mFlipVertical)
      sx = -sx;
  }
  else if (mpComponent->mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
  {
    if (mFlipHorizontal)
      sx = -sx;
    if (mFlipVertical)
      sy = -sy;
  }

  m11 = sx * cos(mRotateAngle * (M_PI / 180));
  m12 = sx * sin(mRotateAngle * (M_PI / 180));

  m21 = -sy * sin(mRotateAngle * (M_PI / 180));
  m22 = sy * cos(mRotateAngle * (M_PI / 180));

  m31 = mPositionX;
  m32 = -(mPositionY);

  return QTransform (m11, m12, m21, m22, m31, m32);
}

qreal Transformation::getRotateAngle()
{
  return mRotateAngle;
}

qreal Transformation::getScale()
{
  return mScale;
}

qreal Transformation::getPositionX()
{
  return mPositionX;
}

qreal Transformation::getPositionY()
{
  return mPositionY;
}

qreal Transformation::getRotateAngleIcon()
{
  return mRotateAngleIcon;
}

qreal Transformation::getScaleIcon()
{
  return mScaleIcon;
}

qreal Transformation::getPositionXIcon()
{
  return mPositionXIcon;
}

qreal Transformation::getPositionYIcon()
{
  return mPositionYIcon;
}

bool Transformation::getFlipHorizontalIcon()
{
  return mFlipHorizontalIcon;
}

bool Transformation::getFlipVerticalIcon()
{
  return mFlipVerticalIcon;
}
