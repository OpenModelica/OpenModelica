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

#include "RectangleAnnotation.h"
#include "Modeling/Commands.h"

RectangleAnnotation::RectangleAnnotation(QString annotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0, 0)
{
  mpOriginItem = new OriginItem(this);
  mpOriginItem->setPassive();
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation(annotation);
  setShapeFlags(true);
}

RectangleAnnotation::RectangleAnnotation(ShapeAnnotation *pShapeAnnotation, Element *pParent)
  : ShapeAnnotation(pShapeAnnotation, pParent)
{
  mpOriginItem = 0;
  updateShape(pShapeAnnotation);
  applyTransformation();
}

RectangleAnnotation::RectangleAnnotation(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(true, pGraphicsView, pShapeAnnotation, 0)
{
  mpOriginItem = new OriginItem(this);
  mpOriginItem->setPassive();
  updateShape(pShapeAnnotation);
  setShapeFlags(true);
  mpGraphicsView->addItem(this);
  mpGraphicsView->addItem(mpOriginItem);
}

RectangleAnnotation::RectangleAnnotation(Element *pParent)
  : ShapeAnnotation(0, pParent)
{
  mpOriginItem = 0;
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // create a grey rectangle
  setLineColor(QColor(0, 0, 0));
  setFillColor(QColor(240, 240, 240));
  setFillPattern(StringHandler::FillSolid);
  QList<QPointF> extents;
  extents << QPointF(-100, -100) << QPointF(100, 100);
  setExtents(extents);
  setPos(mOrigin);
  setRotation(mRotation);
}

/*!
 * \brief RectangleAnnotation::RectangleAnnotation
 * Used by OMSimulator FMU ModelWidget\n
 * We always make this shape as inherited shape since its not allowed to be modified.
 * \param pGraphicsView
 */
RectangleAnnotation::RectangleAnnotation(GraphicsView *pGraphicsView)
  : ShapeAnnotation(true, pGraphicsView, 0, 0)
{
  mpOriginItem = 0;
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // create a grey rectangle
  setLineColor(QColor(0, 0, 0));
  setFillColor(QColor(240, 240, 240));
  setFillPattern(StringHandler::FillSolid);
  QList<QPointF> extents;
  extents << QPointF(-100, -100) << QPointF(100, 100);
  setExtents(extents);
  setPos(mOrigin);
  setRotation(mRotation);
  setShapeFlags(true);
}

void RectangleAnnotation::parseShapeAnnotation(QString annotation)
{
  GraphicItem::parseShapeAnnotation(annotation);
  FilledShape::parseShapeAnnotation(annotation);
  // parse the shape to get the list of attributes of Rectangle.
  QStringList list = StringHandler::getStrings(annotation);
  if (list.size() < 11) {
    return;
  }
  // 9th item of the list contains the border pattern.
  mBorderPattern = StringHandler::getBorderPatternType(stripDynamicSelect(list.at(8)));
  // 10th item is the extent points
  mExtents.parse(list.at(9));
  // 11th item of the list contains the corner radius.
  mRadius.parse(list.at(10));
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
  if (mVisible) {
    // state machine visualization
    if (mpParentComponent && mpParentComponent->getLibraryTreeItem() && mpParentComponent->getLibraryTreeItem()->isState()
        && mpParentComponent->getGraphicsView()->isVisualizationView()) {
      if (mpParentComponent->isActiveState()) {
        painter->setOpacity(1.0);
      } else {
        painter->setOpacity(0.2);
      }
    }
    drawRectangleAnnotation(painter);
  }
}

void RectangleAnnotation::drawRectangleAnnotation(QPainter *painter)
{
  applyLinePattern(painter);
  applyFillPattern(painter);
  painter->drawRoundedRect(getBoundingRect().normalized(), mRadius, mRadius);
}

/*!
 * \brief RectangleAnnotation::getOMCShapeAnnotation
 * Returns Rectangle annotation in format as returned by OMC.
 * \return
 */
QString RectangleAnnotation::getOMCShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getOMCShapeAnnotation());
  annotationString.append(FilledShape::getOMCShapeAnnotation());
  // get the border pattern
  annotationString.append(StringHandler::getBorderPatternString(mBorderPattern));
  // get the extents
  annotationString.append(mExtents.toQString());
  // get the radius
  annotationString.append(mRadius.toQString());
  return annotationString.join(",");
}

/*!
 * \brief RectangleAnnotation::getOMCShapeAnnotationWithShapeName
 * Returns Rectangle annotation in format as returned by OMC wrapped in Rectangle keyword.
 * \return
 */
QString RectangleAnnotation::getOMCShapeAnnotationWithShapeName()
{
  return QString("Rectangle(%1)").arg(getOMCShapeAnnotation());
}

/*!
 * \brief RectangleAnnotation::getShapeAnnotation
 * Returns Rectangle annotation.
 * \return
 */
QString RectangleAnnotation::getShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getShapeAnnotation());
  annotationString.append(FilledShape::getShapeAnnotation());
  // get the border pattern
  if (mBorderPattern != StringHandler::BorderNone) {
    annotationString.append(QString("borderPattern=").append(StringHandler::getBorderPatternString(mBorderPattern)));
  }
  // get the extents
  if (mExtents.isDynamicSelectExpression() || mExtents.size() > 1) {
    annotationString.append(QString("extent=%1").arg(mExtents.toQString()));
  }
  // get the radius
  if (mRadius.isDynamicSelectExpression() || mRadius != 0) {
    annotationString.append(QString("radius=%1").arg(mRadius.toQString()));
  }
  return QString("Rectangle(").append(annotationString.join(",")).append(")");
}

void RectangleAnnotation::updateShape(ShapeAnnotation *pShapeAnnotation)
{
  // set the default values
  GraphicItem::setDefaults(pShapeAnnotation);
  FilledShape::setDefaults(pShapeAnnotation);
  ShapeAnnotation::setDefaults(pShapeAnnotation);
}

/*!
 * \brief RectangleAnnotation::duplicate
 * Duplicates the shape.
 */
void RectangleAnnotation::duplicate()
{
  RectangleAnnotation *pRectangleAnnotation = new RectangleAnnotation("", mpGraphicsView);
  pRectangleAnnotation->updateShape(this);
  QPointF gridStep(mpGraphicsView->mMergedCoOrdinateSystem.getHorizontalGridStep() * 5,
                   mpGraphicsView->mMergedCoOrdinateSystem.getVerticalGridStep() * 5);
  pRectangleAnnotation->setOrigin(mOrigin + gridStep);
  pRectangleAnnotation->drawCornerItems();
  pRectangleAnnotation->setCornerItemsActiveOrPassive();
  pRectangleAnnotation->applyTransformation();
  pRectangleAnnotation->update();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new AddShapeCommand(pRectangleAnnotation));
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitShapeAdded(pRectangleAnnotation, mpGraphicsView);
  setSelected(false);
  pRectangleAnnotation->setSelected(true);
}
