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

#include "Transformation.h"

Transformation::Transformation(Component *pComponent)
{
    mVisible = true;
    mPositionX = 0.0;
    mPositionY = 0.0;
    mFlipHorizontal = false;
    mFlipVertical = false;
    mRotateAngle = 0.0;
    mScale = 1.0;
    mAspectRatio = 1.0;

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
    QStringList list = StringHandler::getStrings(value);

    mWidth = mpComponent->boundingRect().width();
    mHeight = mpComponent->boundingRect().height();

    // if mWidth and mHeight is zero then give it fixed with and height of 200. Otherwise OMEdit will crash!!!!
    // e.g BusUsage crash problem!!!!!
    if (mWidth < 1)
        mWidth = 200.0;
    if (mHeight < 1)
        mHeight = 200.0;

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
