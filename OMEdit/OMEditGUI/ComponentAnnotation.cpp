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

#include "ComponentAnnotation.h"

ComponentAnnotation::ComponentAnnotation(QString value, QString className, QString transformationStr,
                                         ComponentsProperties *pComponentProperties, IconAnnotation *pParent)
    : ShapeAnnotation(pParent), mClassName(className)
{
    mpParentIcon = pParent;
    mpComponentProperties = pComponentProperties;
    mpParentIcon->parseIconAnnotationString(this, value);
    parseTransformationString(transformationStr);
    connect(this, SIGNAL(componentClicked(ComponentAnnotation*)), mpParentIcon->mpGraphicsView,
            SLOT(addConnector(ComponentAnnotation*)));
}

void ComponentAnnotation::parseTransformationString(QString value)
{
    value = StringHandler::removeFirstLastCurlBrackets(value);
    if (value.isEmpty())
        return;
    QStringList list = StringHandler::getStrings(value);
    int i = 0;

    if (list.size() > i)
    {
        this->mVisible = static_cast<QString>(list.at(i)).contains("true");
        if (!this->mVisible)
            this->hide();
        i++;
    }
    else
        return;

    // now parse the values for diagram
    // x position
    if (list.size() > i)
        i++;
    else
        return;
    // y position
    if (list.size() > i)
        i++;
    else
        return;
    // scale
    if (list.size() > i)
        i++;
    else
        return;
    // aspectratio
    if (list.size() > i)
        i++;
    else
        return;
    // flip horizontal
    if (list.size() > i)
        i++;
    else
        return;
    // flip vertical
    if (list.size() > i)
        i++;
    else
        return;
    // rotate angle
    if (list.size() > i)
        i++;
    else
        return;

    // now parse the values for icon
    // x position
    if (list.size() > i)
    {
        this->mPositionX = static_cast<QString>(list.at(i)).toFloat();
        i++;
    }
    else
        return;
    // y position
    if (list.size() > i)
    {
        this->mPositionY = static_cast<QString>(list.at(i)).toFloat();
        i++;
    }
    else
        return;
    this->setPos(this->mPositionX, this->mPositionY);
    // scale
    if (list.size() > i)
    {
        this->mScale = static_cast<QString>(list.at(i)).toFloat();
        this->scale(this->mScale, this->mScale);
        i++;
    }
    else
        return;
    // aspectratio
    if (list.size() > i)
    {
        this->mAspectRatio = static_cast<QString>(list.at(i)).toFloat();
        i++;
    }
    else
        return;
    // flip horizontal
    if (list.size() > i)
    {
        this->mFlipHorizontal = static_cast<QString>(list.at(i)).contains("true");
        if (this->mFlipHorizontal)
            this->scale(-1.0, 1.0);
        i++;
    }
    else
        return;
    // flip vertical
    if (list.size() > i)
    {
        this->mFlipVertical = static_cast<QString>(list.at(i)).contains("true");
        if (this->mFlipVertical)
            this->scale(1.0, -1.0);
        i++;
    }
    else
        return;
    // rotate angle
    if (list.size() > i)
    {
        this->mRotateAngle = static_cast<QString>(list.at(i)).toFloat();
        this->rotate(this->mRotateAngle);
        i++;
    }
    else
        return;
}

QRectF ComponentAnnotation::boundingRect() const
{
    return this->mRectangle;
}

void ComponentAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
    Q_UNUSED(painter);
    Q_UNUSED(option);
    Q_UNUSED(widget);

    //painter->rotate(ShapeAnnotation::mRotationAngle);
    //painter->scale(ShapeAnnotation::mScale, ShapeAnnotation::mScale);
    //painter->drawRect(boundingRect());
    //painter->drawLine(this->line);
}

qreal ComponentAnnotation::getRotateAngle()
{
    return mRotateAngle;
}

IconAnnotation* ComponentAnnotation::getParentIcon()
{
    return mpParentIcon;
}

void ComponentAnnotation::mousePressEvent(QGraphicsSceneMouseEvent *event)
{
    if (event->button() == Qt::LeftButton)
    {
        emit componentClicked(this);
    }
}
