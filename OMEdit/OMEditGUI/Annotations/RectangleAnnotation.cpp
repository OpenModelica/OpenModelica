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

#include "RectangleAnnotation.h"

RectangleAnnotation::RectangleAnnotation(QString annotation, Component *pParent)
  : ShapeAnnotation(pParent)
{
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  parseShapeAnnotation(annotation);
}

RectangleAnnotation::RectangleAnnotation(QString annotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(pGraphicsView, 0)
{
  setFlag(QGraphicsItem::ItemIsSelectable);
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation(annotation);
  /* Only set the ItemIsMovable flag on shape if the class is not a system library class. */
  if (!mpGraphicsView->getModelWidget()->getLibraryTreeNode()->isSystemLibrary())
    setFlag(QGraphicsItem::ItemIsMovable);
  mpGraphicsView->addShapeObject(this);
  mpGraphicsView->scene()->addItem(this);
  connect(this, SIGNAL(updateClassAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

void RectangleAnnotation::parseShapeAnnotation(QString annotation)
{
  GraphicItem::parseShapeAnnotation(annotation);
  FilledShape::parseShapeAnnotation(annotation);
  // parse the shape to get the list of attributes of Rectangle.
  QStringList list = StringHandler::getStrings(annotation);
  if (list.size() < 11)
    return;
  // 9th item of the list contains the border pattern.
  mBorderPattern = StringHandler::getBorderPatternType(list.at(8));
  // 10th item is the extent points
  QStringList extentsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(9)));
  for (int i = 0 ; i < qMin(extentsList.size(), 2) ; i++)
  {
    QStringList extentPoints = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(extentsList[i]));
    if (extentPoints.size() >= 2)
      mExtents.replace(i, QPointF(extentPoints.at(0).toFloat(), extentPoints.at(1).toFloat()));
  }
  // 11th item of the list contains the corner radius.
  mRadius = list.at(10).toFloat();
}

QRectF RectangleAnnotation::boundingRect() const
{
  return shape().boundingRect();
}

QPainterPath RectangleAnnotation::shape() const
{
  QPainterPath path;
  path.addRoundedRect(getBoundingRect(), mRadius, mRadius);
  if (mFillPattern == StringHandler::FillNone)
    return addPathStroker(path);
  else
    return path;
}

void RectangleAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(option);
  Q_UNUSED(widget);
  if (mVisible)
    drawRectangleAnnotaion(painter);
}

void RectangleAnnotation::drawRectangleAnnotaion(QPainter *painter)
{
  applyLinePattern(painter);
  applyFillPattern(painter);
  painter->drawRoundedRect(getBoundingRect(), mRadius, mRadius);
}

QString RectangleAnnotation::getShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getShapeAnnotation());
  annotationString.append(FilledShape::getShapeAnnotation());
  // get the border pattern
  if (mBorderPattern != StringHandler::BorderNone)
    annotationString.append(QString("borderPattern=").append(StringHandler::getBorderPatternString(mBorderPattern)));
  // get the extents
  if (mExtents.size() > 1)
  {
    QString extentString;
    extentString.append("extent={");
    extentString.append("{").append(QString::number(mExtents.at(0).x())).append(",");
    extentString.append(QString::number(mExtents.at(0).y())).append("},");
    extentString.append("{").append(QString::number(mExtents.at(1).x())).append(",");
    extentString.append(QString::number(mExtents.at(1).y())).append("}");
    extentString.append("}");
    annotationString.append(extentString);
  }
  // get the radius
  if (mRadius != 0)
    annotationString.append(QString("radius=").append(QString::number(mRadius)));
  return QString("Rectangle(").append(annotationString.join(",")).append(")");
}
