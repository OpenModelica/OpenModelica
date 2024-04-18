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
#include "Modeling/Model.h"

class Element;

class Transformation
{
public:
  Transformation();
  Transformation(StringHandler::ViewType viewType, Element *pComponent = 0);
  Transformation(const Transformation &transformation);
  void initialize(StringHandler::ViewType viewType);
  void parseTransformationString(QString value, qreal width, qreal height);
  void parseTransformation(const ModelInstance::PlacementAnnotation &placementAnnotation, const ModelInstance::CoordinateSystem &coordinateSystem);
  void updateTransformation(const Transformation &transformation);
  QTransform getTransformationMatrix();
  Element* getComponent() const {return mpComponent;}
  bool isValid() const {return mValid;}
  void setWidth(const qreal &width) {mWidth = width;}
  void setHeight(const qreal &height) {mHeight = height;}
  const BooleanAnnotation& getVisible() const {return mVisible;}
  const BooleanAnnotation& getVisibleIcon() const {return mVisibleIcon;}
  void adjustPosition(qreal x, qreal y);
  void setOrigin(QPointF origin);
  PointAnnotation getOrigin() const;
  void setExtent(QVector<QPointF> extent);
  ExtentAnnotation getExtent() const;
  void setRotateAngle(qreal rotateAngle);
  RealAnnotation getRotateAngle() const;
  QPointF getPosition();
  void setExtentCenter(QPointF extentCenter);
  // operator overloading
  bool operator==(const Transformation &transformation) const;
private:
  bool mValid;
  Element *mpComponent;
  StringHandler::ViewType mViewType;
  qreal mWidth;
  qreal mHeight;
  BooleanAnnotation mVisible;
  PointAnnotation mOriginDiagram;
  ExtentAnnotation mExtentDiagram;
  RealAnnotation mRotateAngleDiagram;
  PointAnnotation mPositionDiagram;
  QPointF mExtentCenterDiagram;
  BooleanAnnotation mVisibleIcon;
  PointAnnotation mOriginIcon;
  ExtentAnnotation mExtentIcon;
  RealAnnotation mRotateAngleIcon;
  PointAnnotation mPositionIcon;
  QPointF mExtentCenterIcon;

  QTransform getTransformationMatrixDiagram() const;
  StringHandler::ViewType getViewType() const {return mViewType;}

  qreal getWidth() const {return mWidth;}
  qreal getHeight() const {return mHeight;}
  void adjustPositionDiagram(qreal x, qreal y);
  void setOriginDiagram(QPointF origin);
  const PointAnnotation &getOriginDiagram() const {return mOriginDiagram;}
  void setExtentDiagram(QVector<QPointF> extent) {mExtentDiagram = extent;}
  const ExtentAnnotation &getExtentDiagram() const {return mExtentDiagram;}
  void setRotateAngleDiagram(qreal rotateAngle) {mRotateAngleDiagram = rotateAngle;}
  const RealAnnotation &getRotateAngleDiagram() const {return mRotateAngleDiagram;}
  QPointF getPositionDiagram() const;
  void setExtentCenterDiagram(QPointF extentCenter) {mExtentCenterDiagram = extentCenter;}
  QPointF getExtentCenterDiagram() const {return mExtentCenterDiagram;}
  QTransform getTransformationMatrixIcon();
  void adjustPositionIcon(qreal x, qreal y);
  void setOriginIcon(QPointF origin);
  const PointAnnotation &getOriginIcon() const {return mOriginIcon;}
  void setExtentIcon(QVector<QPointF> extent) {mExtentIcon = extent;}
  const ExtentAnnotation &getExtentIcon() const {return mExtentIcon;}
  void setRotateAngleIcon(qreal rotateAngle) {mRotateAngleIcon = rotateAngle;}
  const RealAnnotation &getRotateAngleIcon() const {return mRotateAngleIcon;}
  QPointF getPositionIcon() const;
  void setExtentCenterIcon(QPointF extentCenter) {mExtentCenterIcon = extentCenter;}
  QPointF getExtentCenterIcon() const {return mExtentCenterIcon;}
};

#endif // TRANSFORMATION_H
