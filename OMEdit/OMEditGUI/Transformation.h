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

#ifndef TRANSFORMATION_H
#define TRANSFORMATION_H

#include <QtCore>
#include <QtGui>

#include "Component.h"

class Component;

class Transformation
{
private:
    bool mVisible;
    qreal mPositionX;
    qreal mPositionY;
    qreal mScale;
    qreal mAspectRatio;
    bool mFlipHorizontal;
    bool mFlipVertical;
    qreal mRotateAngle;
    QPointF mOrigin;
    QPointF mExtent1;
    QPointF mExtent2;
    qreal mWidth;
    qreal mHeight;

    Component *mpComponent;
public:
    Transformation(Component *pComponent);
    void parseTransformationString2X(QString value);
    void parseTransformationString3X(QString value);
    QTransform getTransformationMatrix();
    QTransform getLibraryTransformationMatrix();
    qreal getRotateAngle();
    qreal getScale();
    qreal getPositionX();
    qreal getPositionY();
};

#endif // TRANSFORMATION_H
