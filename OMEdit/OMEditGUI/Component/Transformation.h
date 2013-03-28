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

#ifndef TRANSFORMATION_H
#define TRANSFORMATION_H

#include <QPointF>
#include <QTransform>
#include "StringHandler.h"

class Component;

class Transformation
{
public:
  Transformation(StringHandler::ViewType viewType);
  void parseTransformationString(QString value, qreal width, qreal height);
  QTransform getTransformationMatrix();
  bool getVisible();
  void setOrigin(QPointF origin);
  QPointF getOrigin();
  void setExtent1(QPointF extent);
  QPointF getExtent1();
  void setExtent2(QPointF extent);
  QPointF getExtent2();
  void setRotateAngle(qreal rotateAngle);
  qreal getRotateAngle();
  qreal getScale();
  void setFlipHorizontal(bool On);
  bool getFlipHorizontal();
  void setFlipVertical(bool On);
  bool getFlipVertical();
private:
  StringHandler::ViewType mViewType;
  qreal mWidth;
  qreal mHeight;
  bool mVisible;
  QPointF mOriginDiagram;
  qreal mPositionXDiagram;
  qreal mPositionYDiagram;
  QPointF mExtent1Diagram;
  QPointF mExtent2Diagram;
  qreal mRotateAngleDiagram;
  qreal mScaleDiagram;
  qreal mAspectRatioDiagram;
  bool mFlipHorizontalDiagram;
  bool mFlipVerticalDiagram;
  QPointF mOriginIcon;
  qreal mPositionXIcon;
  qreal mPositionYIcon;
  QPointF mExtent1Icon;
  QPointF mExtent2Icon;
  qreal mRotateAngleIcon;
  qreal mScaleIcon;
  qreal mAspectRatioIcon;
  bool mFlipHorizontalIcon;
  bool mFlipVerticalIcon;
  QTransform getTransformationMatrixDiagram();
  QTransform getTransformationMatrixIcon();
  void setOriginDiagram(QPointF origin);
  QPointF getOriginDiagram();
  void setExtent1Diagram(QPointF extent);
  QPointF getExtent1Diagram();
  void setExtent2Diagram(QPointF extent);
  QPointF getExtent2Diagram();
  void setRotateAngleDiagram(qreal rotateAngle);
  qreal getRotateAngleDiagram();
  qreal getScaleDiagram();
  void setFlipHorizontalDiagram(bool On);
  bool getFlipHorizontalDiagram();
  void setFlipVerticalDiagram(bool On);
  bool getFlipVerticalDiagram();
  void setOriginIcon(QPointF origin);
  QPointF getOriginIcon();
  void setExtent1Icon(QPointF extent);
  QPointF getExtent1Icon();
  void setExtent2Icon(QPointF extent);
  QPointF getExtent2Icon();
  void setRotateAngleIcon(qreal rotateAngle);
  qreal getRotateAngleIcon();
  qreal getScaleIcon();
  void setFlipHorizontalIcon(bool On);
  bool getFlipHorizontalIcon();
  void setFlipVerticalIcon(bool On);
  bool getFlipVerticalIcon();
};

#endif // TRANSFORMATION_H
