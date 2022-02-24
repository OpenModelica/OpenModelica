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

#include "EllipseAnnotation.h"
#include "Modeling/Commands.h"

EllipseAnnotation::EllipseAnnotation(QString annotation, GraphicsView *pGraphicsView)
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

EllipseAnnotation::EllipseAnnotation(ShapeAnnotation *pShapeAnnotation, Element *pParent)
  : ShapeAnnotation(pShapeAnnotation, pParent)
{
  mpOriginItem = 0;
  updateShape(pShapeAnnotation);
  applyTransformation();
}

EllipseAnnotation::EllipseAnnotation(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(true, pGraphicsView, pShapeAnnotation, 0)
{
  mpOriginItem = new OriginItem(this);
  mpOriginItem->setPassive();
  updateShape(pShapeAnnotation);
  setShapeFlags(true);
  mpGraphicsView->addItem(this);
  mpGraphicsView->addItem(mpOriginItem);
}

void EllipseAnnotation::parseShapeAnnotation(QString annotation)
{
  GraphicItem::parseShapeAnnotation(annotation);
  FilledShape::parseShapeAnnotation(annotation);
  // parse the shape to get the list of attributes of Ellipse.
  QStringList list = StringHandler::getStrings(annotation);
  if (list.size() < 12) {
    return;
  }
  // 9th item is the extent points
  mExtents.parse(list.at(8));
  // 10th item of the list contains the start angle.
  mStartAngle.parse(list.at(9));
  // 11th item of the list contains the end angle.
  mEndAngle.parse(list.at(10));
  // 12th item of the list contains the closure
  mClosure = StringHandler::getClosureType(stripDynamicSelect(list.at(11)));
}

QRectF EllipseAnnotation::boundingRect() const
{
  return shape().boundingRect();
}

QPainterPath EllipseAnnotation::shape() const
{
  QPainterPath path;
  path.addEllipse(getBoundingRect());
  if (mFillPattern == StringHandler::FillNone) {
    return addPathStroker(path);
  } else {
    return path;
  }
}

void EllipseAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(option);
  Q_UNUSED(widget);
  if (mVisible) {
    drawEllipseAnnotation(painter);
  }
}

void EllipseAnnotation::drawEllipseAnnotation(QPainter *painter)
{
  // first we invert the painter since we have our coordinate system inverted.
  // inversion is required to draw the elliptic curves at correct angles.
  painter->scale(1.0, -1.0);
  painter->translate(0, ((-boundingRect().top()) - boundingRect().bottom()));
  applyLinePattern(painter);
  if (mClosure != StringHandler::ClosureNone) {
    applyFillPattern(painter);
  }

  if (mClosure == StringHandler::ClosureNone) {
    painter->drawArc(getBoundingRect(), mStartAngle*16, mEndAngle*16 - mStartAngle*16);
  } else if (mClosure == StringHandler::ClosureChord) {
    painter->drawChord(getBoundingRect(), mStartAngle*16, mEndAngle*16 - mStartAngle*16);
  } else { // StringHandler::ClosureRadial
    painter->drawPie(getBoundingRect(), mStartAngle*16, mEndAngle*16 - mStartAngle*16);
  }
}

/*!
 * \brief EllipseAnnotation::getOMCShapeAnnotation
 * Returns Ellipse annotation in format as returned by OMC.
 * \return
 */
QString EllipseAnnotation::getOMCShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getOMCShapeAnnotation());
  annotationString.append(FilledShape::getOMCShapeAnnotation());
  // get the extents
  annotationString.append(mExtents.toQString());
  // get the start angle
  annotationString.append(mStartAngle.toQString());
  // get the end angle
  annotationString.append(mEndAngle.toQString());
  // get the closure
  annotationString.append(StringHandler::getClosureString(mClosure));
  return annotationString.join(",");
}

/*!
 * \brief EllipseAnnotation::getOMCShapeAnnotationWithShapeName
 * Returns Ellipse annotation in format as returned by OMC wrapped in Ellipse keyword.
 * \return
 */
QString EllipseAnnotation::getOMCShapeAnnotationWithShapeName()
{
  return QString("Ellipse(%1)").arg(getOMCShapeAnnotation());
}

/*!
 * \brief EllipseAnnotation::getShapeAnnotation
 * Returns Ellipse annotation.
 * \return
 */
QString EllipseAnnotation::getShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getShapeAnnotation());
  annotationString.append(FilledShape::getShapeAnnotation());
  // get the extents
  if (mExtents.isDynamicSelectExpression() || mExtents.size() > 1) {
    annotationString.append(QString("extent=%1").arg(mExtents.toQString()));
  }
  // get the start angle
  if (mStartAngle.isDynamicSelectExpression() || mStartAngle != 0) {
    annotationString.append(QString("startAngle=%1").arg(mStartAngle.toQString()));
  }
  // get the end angle
  if (mEndAngle.isDynamicSelectExpression() || mEndAngle != 360) {
    annotationString.append(QString("endAngle=%1").arg(mEndAngle.toQString()));
  }
  // get the closure
  if (!((mStartAngle == 0 && mEndAngle == 360 && mClosure == StringHandler::ClosureChord)
        || (!(mStartAngle == 0 && mEndAngle == 360) && mClosure == StringHandler::ClosureRadial))) {
    annotationString.append(QString("closure=").append(StringHandler::getClosureString(mClosure)));
  }
  return QString("Ellipse(").append(annotationString.join(",")).append(")");
}

void EllipseAnnotation::updateShape(ShapeAnnotation *pShapeAnnotation)
{
  // set the default values
  GraphicItem::setDefaults(pShapeAnnotation);
  FilledShape::setDefaults(pShapeAnnotation);
  ShapeAnnotation::setDefaults(pShapeAnnotation);
}

/*!
 * \brief EllipseAnnotation::duplicate
 * Duplicates the shape.
 */
void EllipseAnnotation::duplicate()
{
  EllipseAnnotation *pEllipseAnnotation = new EllipseAnnotation("", mpGraphicsView);
  pEllipseAnnotation->updateShape(this);
  QPointF gridStep(mpGraphicsView->mMergedCoOrdinateSystem.getHorizontalGridStep() * 5,
                   mpGraphicsView->mMergedCoOrdinateSystem.getVerticalGridStep() * 5);
  pEllipseAnnotation->setOrigin(mOrigin + gridStep);
  pEllipseAnnotation->drawCornerItems();
  pEllipseAnnotation->setCornerItemsActiveOrPassive();
  pEllipseAnnotation->applyTransformation();
  pEllipseAnnotation->update();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new AddShapeCommand(pEllipseAnnotation));
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitShapeAdded(pEllipseAnnotation, mpGraphicsView);
  setSelected(false);
  pEllipseAnnotation->setSelected(true);
}
