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

#ifndef ELLIPSEANNOTATION_H
#define ELLIPSEANNOTATION_H

#include "ShapeAnnotation.h"

class Element;

class EllipseAnnotation : public ShapeAnnotation
{
  Q_OBJECT
public:
  // Used for icon/diagram shape
  EllipseAnnotation(QString annotation, GraphicsView *pGraphicsView);
  // Used for shape inside a component
  EllipseAnnotation(ShapeAnnotation *pShapeAnnotation, Element *pParent);
  // Used for icon/diagram inherited shape
  EllipseAnnotation(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView);
  void parseShapeAnnotation(QString annotation) override;
  QRectF boundingRect() const override;
  QPainterPath shape() const override;
  void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0) override;
  void drawEllipseAnnotaion(QPainter *painter);
  QString getOMCShapeAnnotation() override;
  QString getOMCShapeAnnotationWithShapeName() override;
  QString getShapeAnnotation() override;
  void updateShape(ShapeAnnotation *pShapeAnnotation) override;
public slots:
  void duplicate() override;
};

#endif // ELLIPSEANNOTATION_H
