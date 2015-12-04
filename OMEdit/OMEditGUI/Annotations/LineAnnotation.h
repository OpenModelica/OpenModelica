/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#ifndef LINEANNOTATION_H
#define LINEANNOTATION_H

#include "ShapeAnnotation.h"
#include "Component.h"

class Component;

class LineAnnotation : public ShapeAnnotation
{
  Q_OBJECT
public:
  enum LineType {
    ComponentType,  /* Line is within Component. */
    ConnectionType,  /* Line is a connection. */
    ShapeType  /* Line is a custom shape. */
  };
  // Used for icon/diagram shape
  LineAnnotation(QString annotation, GraphicsView *pGraphicsView);
  // Used for shape inside a component
  LineAnnotation(ShapeAnnotation *pShapeAnnotation, Component *pParent);
  // Used for icon/diagram inherited shape
  LineAnnotation(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView);
  // Used for creating connection
  LineAnnotation(Component *pStartComponent, GraphicsView *pGraphicsView);
  // Used for reading a connection
  LineAnnotation(QString annotation, Component *pStartComponent, Component *pEndComponent, GraphicsView *pGraphicsView);
  // Used for non-exisiting component
  LineAnnotation(Component *pParent);
  // Used for non-existing class
  LineAnnotation(GraphicsView *pGraphicsView);
  void parseShapeAnnotation(QString annotation);
  QPainterPath getShape() const;
  QRectF boundingRect() const;
  QPainterPath shape() const;
  void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
  void drawLineAnnotaion(QPainter *painter);
  QPolygonF drawArrow(QPointF startPos, QPointF endPos, qreal size, int arrowType) const;
  QString getOMCShapeAnnotation();
  QString getShapeAnnotation();
  QString getTLMShapeAnnotation();
  void addPoint(QPointF point);
  void removePoint(int index);
  void clearPoints();
  void updateStartPoint(QPointF point);
  void updateEndPoint(QPointF point);
  void moveAllPoints(qreal offsetX, qreal offsetY);
  void setLineType(LineType lineType) {mLineType = lineType;}
  LineType getLineType() {return mLineType;}
  void setStartComponent(Component *pStartComponent) {mpStartComponent = pStartComponent;}
  Component* getStartComponent() {return mpStartComponent;}
  void setStartComponentName(QString name) {mStartComponentName = name;}
  QString getStartComponentName() {return mStartComponentName;}
  void setEndComponent(Component *pEndComponent) {mpEndComponent = pEndComponent;}
  Component* getEndComponent() {return mpEndComponent;}
  void setEndComponentName(QString name) {mEndComponentName = name;}
  QString getEndComponentName() {return mEndComponentName;}
  void setShapeFlags(bool enable);
  void updateShape(ShapeAnnotation *pShapeAnnotation);
private:
  LineType mLineType;
  Component *mpStartComponent;
  QString mStartComponentName;
  Component *mpEndComponent;
  QString mEndComponentName;
public slots:
  void handleComponentMoved();
  void updateConnectionAnnotation();
  void duplicate();
};

class ConnectionArray : public QDialog
{
  Q_OBJECT
public:
  ConnectionArray(GraphicsView *pGraphicsView, LineAnnotation *pConnectionLineAnnotation, QWidget *pParent = 0);
private:
  GraphicsView *mpGraphicsView;
  LineAnnotation *mpConnectionLineAnnotation;
  Label *mpHeading;
  QFrame *mpHorizontalLine;
  Label *mpDescriptionLabel;
  Label *mpStartComponentLabel;
  QLineEdit *mpStartComponentTextBox;
  Label *mpEndComponentLabel;
  QLineEdit *mpEndComponentTextBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
public slots:
  void saveArrayIndex();
  void cancelArrayIndex();
};

#endif // LINEANNOTATION_H
