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

#ifndef TRANSFORMATION_H
#define TRANSFORMATION_H

#include <QPointF>
#include <QTransform>
#include "Util/StringHandler.h"

class Component;

class Transformation
{
public:
  Transformation();
  Transformation(StringHandler::ViewType viewType, Component *pComponent = 0);
  Transformation(const Transformation &transformation);
  void initialize(StringHandler::ViewType viewType);
  void parseTransformationString(QString value, qreal width, qreal height);
  void updateTransformation(const Transformation &transformation);
  QTransform getTransformationMatrix();
  Component* getComponent() const {return mpComponent;}
  bool isValid() const {return mValid;}
  bool getVisible() const {return mVisible;}
  void adjustPosition(qreal x, qreal y);
  bool hasOrigin();
  void setOrigin(QPointF origin);
  QPointF getOrigin() const;
  void setExtent1(QPointF extent);
  QPointF getExtent1() const;
  void setExtent2(QPointF extent);
  QPointF getExtent2() const;
  void setRotateAngle(qreal rotateAngle);
  qreal getRotateAngle() const;
  QPointF getPosition();
  // operator overloading
  bool operator==(const Transformation &transformation) const;
private:
  bool mValid;
  Component *mpComponent;
  StringHandler::ViewType mViewType;
  qreal mWidth;
  qreal mHeight;
  bool mVisible;
  QPointF mOriginDiagram;
  bool mHasOriginDiagramX;
  bool mHasOriginDiagramY;
  QPointF mExtent1Diagram;
  QPointF mExtent2Diagram;
  qreal mRotateAngleDiagram;
  QPointF mPositionDiagram;
  QPointF mOriginIcon;
  bool mHasOriginIconX;
  bool mHasOriginIconY;
  QPointF mExtent1Icon;
  QPointF mExtent2Icon;
  qreal mRotateAngleIcon;
  QPointF mPositionIcon;

  QTransform getTransformationMatrixDiagram();
  StringHandler::ViewType getViewType() const {return mViewType;}
  qreal getWidth() const {return mWidth;}
  qreal getHeight() const {return mHeight;}
  void adjustPositionDiagram(qreal x, qreal y);
  bool hasOriginDiagramX() const {return mHasOriginDiagramX;}
  bool hasOriginDiagramY() const {return mHasOriginDiagramY;}
  bool hasOriginDiagram() {return hasOriginDiagramX() && hasOriginDiagramY();}
  void setOriginDiagram(QPointF origin);
  QPointF getOriginDiagram() const {return mOriginDiagram;}
  void setExtent1Diagram(QPointF extent) {mExtent1Diagram = extent;}
  QPointF getExtent1Diagram() const {return mExtent1Diagram;}
  void setExtent2Diagram(QPointF extent) {mExtent2Diagram = extent;}
  QPointF getExtent2Diagram() const {return mExtent2Diagram;}
  void setRotateAngleDiagram(qreal rotateAngle) {mRotateAngleDiagram = rotateAngle;}
  qreal getRotateAngleDiagram() const {return mRotateAngleDiagram;}
  QPointF getPositionDiagram() const {return mPositionDiagram;}
  QTransform getTransformationMatrixIcon();
  void adjustPositionIcon(qreal x, qreal y);
  bool hasOriginIconX() const {return mHasOriginIconX;}
  bool hasOriginIconY() const {return mHasOriginIconY;}
  bool hasOriginIcon() {return hasOriginIconX() && hasOriginIconY();}
  void setOriginIcon(QPointF origin);
  QPointF getOriginIcon() const {return mOriginIcon;}
  void setExtent1Icon(QPointF extent) {mExtent1Icon = extent;}
  QPointF getExtent1Icon() const {return mExtent1Icon;}
  void setExtent2Icon(QPointF extent) {mExtent2Icon = extent;}
  QPointF getExtent2Icon() const {return mExtent2Icon;}
  void setRotateAngleIcon(qreal rotateAngle) {mRotateAngleIcon = rotateAngle;}
  qreal getRotateAngleIcon() const {return mRotateAngleIcon;}
  QPointF getPositionIcon() const {return mPositionIcon;}
};

#endif // TRANSFORMATION_H
