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

EllipseAnnotation::EllipseAnnotation(ModelInstance::Ellipse *pEllipse, bool inherited, GraphicsView *pGraphicsView)
  : ShapeAnnotation(inherited, pGraphicsView, 0, 0)
{
  mpOriginItem = new OriginItem(this);
  mpOriginItem->setPassive();
  mpEllipse = pEllipse;
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation();
  setShapeFlags(true);
}

EllipseAnnotation::EllipseAnnotation(ModelInstance::Ellipse *pEllipse, Element *pParent)
  : ShapeAnnotation(pParent)
{
  mpOriginItem = 0;
  mpEllipse = pEllipse;
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation();
  applyTransformation();
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
  mExtent.parse(list.at(8));
  // 10th item of the list contains the start angle.
  mStartAngle.parse(list.at(9));
  // 11th item of the list contains the end angle.
  mEndAngle.parse(list.at(10));
  // 12th item of the list contains the closure
  mClosure = StringHandler::getClosureType(stripDynamicSelect(list.at(11)));
}

void EllipseAnnotation::parseShapeAnnotation()
{
  GraphicItem::parseShapeAnnotation(mpEllipse);
  FilledShape::parseShapeAnnotation(mpEllipse);

  mExtent = mpEllipse->getExtent();
  mExtent.evaluate(mpEllipse->getParentModel());
  mStartAngle = mpEllipse->getStartAngle();
  mStartAngle.evaluate(mpEllipse->getParentModel());
  mEndAngle = mpEllipse->getEndAngle();
  mEndAngle.evaluate(mpEllipse->getParentModel());
  mClosure = mpEllipse->getClosure();
  mClosure.evaluate(mpEllipse->getParentModel());
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
    drawAnnotation(painter);
  }
}

/*!
 * \brief EllipseAnnotation::drawAnnotation
 * Draws the ellipse.
 * \param painter
 */
void EllipseAnnotation::drawAnnotation(QPainter *painter)
{
  QRectF boundingRectangle = boundingRect();
  // first we invert the painter since we have our coordinate system inverted.
  // inversion is required to draw the elliptic curves at correct angles.
  painter->scale(1.0, -1.0);
  painter->translate(0, ((-boundingRectangle.top()) - boundingRectangle.bottom()));
  applyLinePattern(painter);
  if (mClosure != StringHandler::ClosureNone) {
    applyFillPattern(painter);
  }

  boundingRectangle = getBoundingRect();
  if (mClosure == StringHandler::ClosureNone) {
    painter->drawArc(boundingRectangle, mStartAngle*16, mEndAngle*16 - mStartAngle*16);
  } else if (mClosure == StringHandler::ClosureChord) {
    painter->drawChord(boundingRectangle, mStartAngle*16, mEndAngle*16 - mStartAngle*16);
  } else { // StringHandler::ClosureRadial
    painter->drawPie(boundingRectangle, mStartAngle*16, mEndAngle*16 - mStartAngle*16);
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
  annotationString.append(mExtent.toQString());
  // get the start angle
  annotationString.append(mStartAngle.toQString());
  // get the end angle
  annotationString.append(mEndAngle.toQString());
  // get the closure
  annotationString.append(mClosure.toQString());
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
  if (mExtent.isDynamicSelectExpression() || mExtent.size() > 1) {
    annotationString.append(QString("extent=%1").arg(mExtent.toQString()));
  }
  // get the start angle
  if (mStartAngle.isDynamicSelectExpression() || mStartAngle.toQString().compare(QStringLiteral("0")) != 0) {
    annotationString.append(QString("startAngle=%1").arg(mStartAngle.toQString()));
  }
  // get the end angle
  if (mEndAngle.isDynamicSelectExpression() || mEndAngle.toQString().compare(QStringLiteral("360")) != 0) {
    annotationString.append(QString("endAngle=%1").arg(mEndAngle.toQString()));
  }
  // get the closure
  if (mClosure.isDynamicSelectExpression() || !((mStartAngle == 0 && mEndAngle == 360 && mClosure.toQString().compare(QStringLiteral("EllipseClosure.Chord")) == 0)
                                                || (!(mStartAngle == 0 && mEndAngle == 360) && mClosure.toQString().compare(QStringLiteral("EllipseClosure.Radial")) == 0))) {
    annotationString.append(QString("closure=%1").arg(mClosure.toQString()));
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

ModelInstance::Extend *EllipseAnnotation::getExtend() const
{
  return mpEllipse->getParentExtend();
}

/*!
 * \brief EllipseAnnotation::duplicate
 * Duplicates the shape.
 */
void EllipseAnnotation::duplicate()
{
  EllipseAnnotation *pEllipseAnnotation = new EllipseAnnotation("", mpGraphicsView);
  pEllipseAnnotation->updateShape(this);
  QPointF gridStep(mpGraphicsView->mMergedCoordinateSystem.getHorizontalGridStep() * 5,
                   mpGraphicsView->mMergedCoordinateSystem.getVerticalGridStep() * 5);
  pEllipseAnnotation->setOrigin(mOrigin + gridStep);
  pEllipseAnnotation->drawCornerItems();
  pEllipseAnnotation->setCornerItemsActiveOrPassive();
  pEllipseAnnotation->applyTransformation();
  pEllipseAnnotation->update();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new AddShapeCommand(pEllipseAnnotation));
  setSelected(false);
  pEllipseAnnotation->setSelected(true);
}
