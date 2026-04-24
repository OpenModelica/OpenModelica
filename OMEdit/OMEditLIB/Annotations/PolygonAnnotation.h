/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef POLYGONANNOTATION_H
#define POLYGONANNOTATION_H

#include "ShapeAnnotation.h"

class Element;
class PolygonAnnotation : public ShapeAnnotation
{
  Q_OBJECT
public:
  // Used for icon/diagram shape
  PolygonAnnotation(QString annotation, GraphicsView *pGraphicsView);
  PolygonAnnotation(ModelInstance::Polygon *pPolygon, bool inherited, GraphicsView *pGraphicsView);
  // Used for shape inside a component
  PolygonAnnotation(ModelInstance::Polygon *pPolygon, Element *pParent);
  // Used for OMS Element shape
  PolygonAnnotation(ShapeAnnotation *pShapeAnnotation, Element *pParent);
  // Used for default input/output component
  PolygonAnnotation(Element *pParent);
  void parseShapeAnnotation(QString annotation) override;
  void parseShapeAnnotation() override;
  QPainterPath getShape() const;
  QRectF boundingRect() const override;
  QPainterPath shape() const override;
  void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0) override;
  virtual void drawAnnotation(QPainter *painter) override;
  QString getOMCShapeAnnotation() override;
  QString getOMCShapeAnnotationWithShapeName() override;
  QString getShapeAnnotation() override;
  void addPoint(QPointF point) override;
  void removePoint(int index);
  void clearPoints() override;
  void updateEndPoint(QPointF point);
  void updateShape(ShapeAnnotation *pShapeAnnotation) override;
  ModelInstance::Extend *getExtend() const override;
  void setPolygon(ModelInstance::Polygon *pPolygon) {mpPolygon = pPolygon;}
private:
  ModelInstance::Polygon *mpPolygon;
};

#endif // POLYGONANNOTATION_H
