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

#include "ShapeAnnotation.h"
#include "ModelWidgetContainer.h"
#include "ShapePropertiesDialog.h"

/*!
 * \brief GraphicItem::setDefaults
 * Sets the default value.
 */
void GraphicItem::setDefaults()
{
  mVisible = true;
  mOrigin = QPointF(0, 0);
  mRotation = 0;
}

/*!
 * \brief GraphicItem::setDefaults
 * Sets the default value from ShapeAnnotation.
 * \param pShapeAnnotation
 */
void GraphicItem::setDefaults(ShapeAnnotation *pShapeAnnotation)
{
  mVisible = pShapeAnnotation->mVisible;
  mOrigin = pShapeAnnotation->mOrigin;
  mRotation = pShapeAnnotation->mRotation;
}

/*!
  Parses the GraphicItem annotation values.
  \param annotation - the annotation string.
  */
void GraphicItem::parseShapeAnnotation(QString annotation)
{
  // parse the shape to get the list of attributes
  QStringList list = StringHandler::getStrings(annotation);
  if (list.size() < 3)
    return;
  // if first item of list is true then the shape should be visible.
  mVisible = list.at(0).contains("true");
  // 2nd item is the origin
  QStringList originList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(1)));
  if (originList.size() >= 2)
  {
    mOrigin.setX(originList.at(0).toFloat());
    mOrigin.setY(originList.at(1).toFloat());
  }
  // 3rd item is the rotation
  mRotation = list.at(2).toFloat();
}

/*!
  Returns the annotation values of the GraphicItem.
  \return the annotation values as a list.
  */
QStringList GraphicItem::getShapeAnnotation()
{
  QStringList annotationString;
  /* get visible */
  if (!mVisible)
  {
    annotationString.append("visible=false");
  }
  /* get origin */
  if (mOrigin != QPointF(0, 0))
  {
    QString originString;
    originString.append("origin=");
    originString.append("{").append(QString::number(mOrigin.x())).append(",");
    originString.append(QString::number(mOrigin.y())).append("}");
    annotationString.append(originString);
  }
  /* get rotation */
  if (mRotation != 0)
  {
    annotationString.append(QString("rotation=").append(QString::number(mRotation)));
  }
  return annotationString;
}

/*!
  Sets the origin value.
  \param origin - the origin value.
  */
void GraphicItem::setOrigin(QPointF origin)
{
  mOrigin = origin;
}

/*!
  Returns the origin value.
  \return the origin value.
  */
QPointF GraphicItem::getOrigin()
{
  return mOrigin;
}

/*!
  Sets the rotation value.
  \param rotation - the rotation value.
  */
void GraphicItem::setRotationAngle(qreal rotation)
{
  mRotation = rotation;
}

/*!
  Returns the rotation value.
  \return the rotation value.
  */
qreal GraphicItem::getRotation()
{
  return mRotation;
}

/*!
 * \brief FilledShape::setDefaults
 * Sets the default values.
 */
void FilledShape::setDefaults()
{
  mLineColor = QColor(0, 0, 0);
  mFillColor = QColor(0, 0, 0);
  mLinePattern = StringHandler::LineSolid;
  mFillPattern = StringHandler::FillNone;
  mLineThickness = 0.25;
}

/*!
 * \brief FilledShape::setDefaults
 * Sets the default value from ShapeAnnotation.
 * \param pShapeAnnotation
 */
void FilledShape::setDefaults(ShapeAnnotation *pShapeAnnotation)
{
  mLineColor = pShapeAnnotation->mLineColor;
  mFillColor = pShapeAnnotation->mFillColor;
  mLinePattern = pShapeAnnotation->mLinePattern;
  mFillPattern = pShapeAnnotation->mFillPattern;
  mLineThickness = pShapeAnnotation->mLineThickness;
}

/*!
  Parses the FilledShape annotation values.
  \param annotation - the annotation string.
  */
void FilledShape::parseShapeAnnotation(QString annotation)
{
  // parse the shape to get the list of attributes
  QStringList list = StringHandler::getStrings(annotation);
  if (list.size() < 8)
    return;
  // 4th item of the list is the line color
  QStringList colorList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(3)));
  if (colorList.size() >= 3)
  {
    int red, green, blue = 0;
    red = colorList.at(0).toInt();
    green = colorList.at(1).toInt();
    blue = colorList.at(2).toInt();
    mLineColor = QColor (red, green, blue);
  }
  // 5th item of list contains the fill color.
  QStringList fillColorList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(4)));
  if (fillColorList.size() >= 3)
  {
    int red, green, blue = 0;
    red = fillColorList.at(0).toInt();
    green = fillColorList.at(1).toInt();
    blue = fillColorList.at(2).toInt();
    mFillColor = QColor (red, green, blue);
  }
  // 6th item of list contains the Line Pattern.
  mLinePattern = StringHandler::getLinePatternType(list.at(5));
  // 7th item of list contains the Fill Pattern.
  mFillPattern = StringHandler::getFillPatternType(list.at(6));
  // 8th item of list contains the thickness.
  mLineThickness = list.at(7).toFloat();
}

/*!
  Returns the annotation values of the FilledShape.
  \return the annotation values as a list.
  */
QStringList FilledShape::getShapeAnnotation()
{
  QStringList annotationString;
  /* get the line color */
  if (mLineColor != Qt::black)
  {
    QString lineColorString;
    lineColorString.append("lineColor={");
    lineColorString.append(QString::number(mLineColor.red())).append(",");
    lineColorString.append(QString::number(mLineColor.green())).append(",");
    lineColorString.append(QString::number(mLineColor.blue()));
    lineColorString.append("}");
    annotationString.append(lineColorString);
  }
  /* get the fill color */
  if (mFillColor != Qt::black)
  {
    QString fillColorString;
    fillColorString.append("fillColor={");
    fillColorString.append(QString::number(mFillColor.red())).append(",");
    fillColorString.append(QString::number(mFillColor.green())).append(",");
    fillColorString.append(QString::number(mFillColor.blue()));
    fillColorString.append("}");
    annotationString.append(fillColorString);
  }
  /* get the line pattern */
  if (mLinePattern != StringHandler::LineSolid)
    annotationString.append(QString("pattern=").append(StringHandler::getLinePatternString(mLinePattern)));
  /* get the fill pattern */
  if (mFillPattern != StringHandler::FillNone)
    annotationString.append(QString("fillPattern=").append(StringHandler::getFillPatternString(mFillPattern)));
  // get the thickness
  if (mLineThickness != 0.25)
    annotationString.append(QString("lineThickness=").append(QString::number(mLineThickness)));
  return annotationString;
}

/*!
  Sets the line color value.
  \param color - the line color.
  */
void FilledShape::setLineColor(QColor color)
{
  mLineColor = color;
}

/*!
  Returns the line color value.
  \return the line color value.
  */
QColor FilledShape::getLineColor()
{
  return mLineColor;
}

/*!
  Sets the fill color value.
  \param color - the fill color.
  */
void FilledShape::setFillColor(QColor color)
{
  mFillColor = color;
}

/*!
  Returns the fill color value.
  \return the fill color value.
  */
QColor FilledShape::getFillColor()
{
  return mFillColor;
}

/*!
  Sets the line pattern value.
  \param pattern - the line pattern.
  */
void FilledShape::setLinePattern(StringHandler::LinePattern pattern)
{
  mLinePattern = pattern;
}

/*!
  Returns the line pattern value.
  \return the line pattern value.
  */
StringHandler::LinePattern FilledShape::getLinePattern()
{
  return mLinePattern;
}

/*!
  Sets the fill pattern value.
  \param pattern - the fill pattern.
  */
void FilledShape::setFillPattern(StringHandler::FillPattern pattern)
{
  mFillPattern = pattern;
}

/*!
  Returns the fill pattern value.
  \return the fill pattern value.
  */
StringHandler::FillPattern FilledShape::getFillPattern()
{
  return mFillPattern;
}

/*!
  Sets the thickness value.
  \param thickness - the line thickness.
  */
void FilledShape::setLineThickness(qreal thickness)
{
  mLineThickness = thickness;
}

/*!
  Returns the thickness value.
  \return the thickness value.
  */
qreal FilledShape::getLineThickness()
{
  return mLineThickness;
}

/*!
  \class ShapeAnnotation
  \brief The base class for all shapes LineAnnotation, PolygonAnnotation, RectangleAnnotation, EllipseAnnotation, TextAnnotation,
         BitmapAnnotation.
  */
/*!
  \param pParent - pointer to QGraphicsItem
  */
ShapeAnnotation::ShapeAnnotation(QGraphicsItem *pParent)
  : QGraphicsItem(pParent)
{
  mpGraphicsView = 0;
  mpParentComponent = dynamic_cast<Component*>(pParent);
  //mTransformation = 0;
  mIsCustomShape = false;
  mIsInheritedShape = false;
  setOldPosition(QPointF(0, 0));
  mIsCornerItemClicked = false;
}

/*!
  \param pGraphicsView - pointer to GraphicsView
  \param pParent - pointer to QGraphicsItem
  */
ShapeAnnotation::ShapeAnnotation(bool inheritedShape, GraphicsView *pGraphicsView, QGraphicsItem *pParent)
  : QGraphicsItem(pParent)
{
  mpGraphicsView = pGraphicsView;
  mTransformation = Transformation(StringHandler::Diagram);
  mIsCustomShape = true;
  mIsInheritedShape = inheritedShape;
  setOldPosition(QPointF(0, 0));
  mIsCornerItemClicked = false;
  createActions();
}

/*!
 * \brief ShapeAnnotation::setDefaults
 * Sets the default values for the shape annotations. Defaults valued as defined in Modelica specification 3.2 are used.
 * \sa setUserDefaults()
 */
void ShapeAnnotation::setDefaults()
{
  mLineColor = QColor(0, 0, 0);
  mLinePattern = StringHandler::LineSolid;
  mLineThickness = 0.25;
  mArrow.append(StringHandler::ArrowNone);
  mArrow.append(StringHandler::ArrowNone);
  mArrowSize = 3;
  mSmooth = StringHandler::SmoothNone;
  mExtents.append(QPointF(0, 0));
  mExtents.append(QPointF(0, 0));
  mBorderPattern = StringHandler::BorderNone;
  mRadius = 0;
  mStartAngle = 0;
  mEndAngle = 360;
  mOriginalTextString = "";
  mTextString = "";
  mFontSize = 0;
  mFontName = "";
  mHorizontalAlignment = StringHandler::TextAlignmentCenter;
  mOriginalFileName = "";
  mFileName = "";
  mImageSource = "";
  mImage = QImage(":/Resources/icons/bitmap-shape.svg");
}

/*!
 * \brief ShapeAnnotation::setDefaults
 * Sets the default values for the shape annotations using another ShapeAnnotation.
 * \param pShapeAnnotation
 * \sa setUserDefaults()
 */
void ShapeAnnotation::setDefaults(ShapeAnnotation *pShapeAnnotation)
{
  mLineColor = pShapeAnnotation->mLineColor;
  mLinePattern = pShapeAnnotation->mLinePattern;
  mLineThickness = pShapeAnnotation->mLineThickness;
  mArrow.append(StringHandler::ArrowNone);
  mArrow.append(StringHandler::ArrowNone);
  setStartArrow(pShapeAnnotation->getStartArrow());
  setEndArrow(pShapeAnnotation->getEndArrow());
  mArrowSize = pShapeAnnotation->mArrowSize;
  mSmooth = pShapeAnnotation->mSmooth;
  setExtents(pShapeAnnotation->getExtents());
  mBorderPattern = pShapeAnnotation->mBorderPattern;
  mRadius = pShapeAnnotation->mRadius;
  mStartAngle = pShapeAnnotation->mStartAngle;
  mEndAngle = pShapeAnnotation->mEndAngle;
  mOriginalTextString = pShapeAnnotation->mOriginalTextString;
  mTextString = pShapeAnnotation->mTextString;
  mFontSize = pShapeAnnotation->mFontSize;
  mFontName = pShapeAnnotation->mFontName;
  mHorizontalAlignment = pShapeAnnotation->mHorizontalAlignment;
  mOriginalFileName = mOriginalFileName;
  mFileName = pShapeAnnotation->mFileName;
  mClassFileName = pShapeAnnotation->mClassFileName;
  mImageSource = pShapeAnnotation->mImageSource;
  mImage = pShapeAnnotation->mImage;
}

/*!
  Reads the user defined line and fill style values. Overrides the Modelica specification 3.2 default values.
  \sa setDefaults()
  */
void ShapeAnnotation::setUserDefaults()
{
  OptionsDialog *pOptionsDialog = mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getOptionsDialog();
  /* Set user Line Style settings */
  if (pOptionsDialog->getLineStylePage()->getLineColor().isValid())
  {
    mLineColor = pOptionsDialog->getLineStylePage()->getLineColor();
  }
  mLinePattern = StringHandler::getLinePatternType(pOptionsDialog->getLineStylePage()->getLinePattern());
  mLineThickness = pOptionsDialog->getLineStylePage()->getLineThickness();
  mArrow.replace(0, StringHandler::getArrowType(pOptionsDialog->getLineStylePage()->getLineStartArrow()));
  mArrow.replace(1, StringHandler::getArrowType(pOptionsDialog->getLineStylePage()->getLineEndArrow()));
  mArrowSize = pOptionsDialog->getLineStylePage()->getLineArrowSize();
  if (pOptionsDialog->getLineStylePage()->getLineSmooth())
  {
    mSmooth = StringHandler::SmoothBezier;
  }
  else
  {
    mSmooth = StringHandler::SmoothNone;
  }
  /* Set user Fill Style settings */
  if (pOptionsDialog->getFillStylePage()->getFillColor().isValid())
  {
    mFillColor = pOptionsDialog->getFillStylePage()->getFillColor();
  }
  mFillPattern = StringHandler::getFillPatternType(pOptionsDialog->getFillStylePage()->getFillPattern());
}

bool ShapeAnnotation::isInheritedShape()
{
  return mIsInheritedShape;
}

/*!
  Defines the actions used by the shape's context menu.
  */
void ShapeAnnotation::createActions()
{
  // shape properties
  mpShapePropertiesAction = new QAction(Helper::properties, mpGraphicsView);
  mpShapePropertiesAction->setStatusTip(tr("Shows the shape properties"));
  connect(mpShapePropertiesAction, SIGNAL(triggered()), SLOT(showShapeProperties()));
  // manhattanize properties
  mpManhattanizeShapeAction = new QAction(tr("Manhattanize"), mpGraphicsView);
  mpManhattanizeShapeAction->setStatusTip(tr("Manhattanize the lines"));
  connect(mpManhattanizeShapeAction, SIGNAL(triggered()), SLOT(manhattanizeShape()));
}

/*!
  Adds a transparent path around the shape so that shape selection becomes easy.\n
  Otherwise the shape selection can be very difficult because the shape drawing lines can be very small in thickness.
  \param path - reference to QPainterPath
  \return the path object.
  */
QPainterPath ShapeAnnotation::addPathStroker(QPainterPath &path) const
{
  QPainterPathStroker stroker;
  stroker.setWidth(Helper::shapesStrokeWidth);
  return stroker.createStroke(path);
}

/*!
  Returns the bounding rectangle of the shape.
  \return the bounding rectangle.
  */
QRectF ShapeAnnotation::getBoundingRect() const
{
  QPointF p1 = mExtents.size() > 0 ? mExtents.at(0) : QPointF(-100.0, -100.0);
  QPointF p2 = mExtents.size() > 1 ? mExtents.at(1) : QPointF(100.0, 100.0);
  qreal left = qMin(p1.x(), p2.x());
  qreal top = qMin(p1.y(), p2.y());
  qreal width = fabs(p1.x() - p2.x());
  qreal height = fabs(p1.y() - p2.y());
  return QRectF (left, top, width, height);
}

/*!
  Applies the shape line pattern.
  \param painter - pointer to QPainter
  */
void ShapeAnnotation::applyLinePattern(QPainter *painter)
{
  qreal thicknessFactor = mLineThickness / 0.5;
  qreal thickness = thicknessFactor < 1 ? 1.0 : thicknessFactor;
  QPen pen(mLineColor, thickness, StringHandler::getLinePatternType(mLinePattern), Qt::SquareCap, Qt::MiterJoin);
  /* Ticket #3222
   * Make all the shapes use cosmetic pens so that they perserve their pen widht when scaled i.e zoomed in/out.
   * Only shapes with border patterns raised & sunken don't use cosmetic pens. We need better handling of border patterns.
   */
  if (mBorderPattern != StringHandler::BorderRaised && mBorderPattern != StringHandler::BorderSunken) {
    pen.setCosmetic(true);
  }
  if (mpGraphicsView && mpGraphicsView->isRenderingLibraryPixmap()) {
    /* Ticket #2272, Ticket #2268.
     * If thickness is greater than 2 then don't make the pen cosmetic since cosmetic pens don't change the width with respect to zoom.
     */
    if (thickness <= 2) {
      pen.setCosmetic(true);
    } else {
      pen.setCosmetic(false);
    }
  }
  painter->setPen(pen);
}

/*!
  Applies the shape fill pattern.
  \param painter - pointer to QPainter
  */
void ShapeAnnotation::applyFillPattern(QPainter *painter)
{
  switch (mFillPattern)
  {
    case StringHandler::FillHorizontalCylinder:
    {
      QLinearGradient gradient(getBoundingRect().center().x(), getBoundingRect().center().y(),
                               getBoundingRect().center().x(), getBoundingRect().y());
      gradient.setColorAt(0.0, mFillColor);
      gradient.setColorAt(1.0, mLineColor);
      gradient.setSpread(QGradient::ReflectSpread);
      painter->setBrush(gradient);
      break;
    }
    case StringHandler::FillVerticalCylinder:
    {
      QLinearGradient gradient(getBoundingRect().center().x(), getBoundingRect().center().y(),
                               getBoundingRect().x(), getBoundingRect().center().y());
      gradient.setColorAt(0.0, mFillColor);
      gradient.setColorAt(1.0, mLineColor);
      gradient.setSpread(QGradient::ReflectSpread);
      painter->setBrush(gradient);
      break;
    }
    case StringHandler::FillSphere:
    {
      QRadialGradient gradient(getBoundingRect().center().x(), getBoundingRect().center().y(),
                               getBoundingRect().width());
      gradient.setColorAt(0.0, mFillColor);
      gradient.setColorAt(1.0, mLineColor);
      //gradient.setSpread(QGradient::ReflectSpread);
      painter->setBrush(gradient);
      break;
    }
    case StringHandler::FillSolid:
      painter->setBrush(QBrush(mFillColor, StringHandler::getFillPatternType(mFillPattern)));
      break;
    case StringHandler::FillNone:
      break;
    default:
      painter->setBackgroundMode(Qt::OpaqueMode);
      painter->setBackground(mFillColor);
      QBrush brush(mLineColor, StringHandler::getFillPatternType(mFillPattern));
      brush.setTransform(QTransform(1, 0, 0, 0, 1, 0, 0, 0, 0));
      painter->setBrush(brush);
      break;
  }
}

/*!
  Returns the shape annotation. Reimplemented by each child shape class to return their annotation.
  \return the shape annotation string.
  */
QString ShapeAnnotation::getShapeAnnotation()
{
  return "";
}

/*!
  Initializes the transformation matrix with the default transformation values of the shape.
  */
void ShapeAnnotation::initializeTransformation()
{
  mTransformation.setOrigin(mOrigin);
  mTransformation.setExtent1(QPointF(-100.0, -100.0));
  mTransformation.setExtent2(QPointF(100.0, 100.0));
  mTransformation.setRotateAngle(mRotation);
  setTransform(mTransformation.getTransformationMatrix());
}

/*!
  Draws the CornerItem around the shape.\n
  If the shape is LineAnnotation or PolygonAnnotation then their points are used to draw CornerItem's.\n
  If the shape is RectangleAnnotation, EllipseAnnotation, TextAnnotation or BitmapAnnotation
  then their extents are used to draw CornerItem's.
  */
void ShapeAnnotation::drawCornerItems()
{
  if (dynamic_cast<LineAnnotation*>(this) || dynamic_cast<PolygonAnnotation*>(this)) {
    LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(this);
    LineAnnotation::LineType lineType = LineAnnotation::ShapeType;
    if (pLineAnnotation) {
      lineType = pLineAnnotation->getLineType();
    }
    for (int i = 0 ; i < mPoints.size() ; i++) {
      QPointF point = mPoints.at(i);
      CornerItem *pCornerItem = new CornerItem(point.x(), point.y(), i, this);
      /* if line is a connection then make the first and last point non moveable. */
      if ((lineType == LineAnnotation::ConnectionType) && (i == 0 || i == mPoints.size() - 1)) {
        pCornerItem->setFlag(QGraphicsItem::ItemIsMovable, false);
      }
      mCornerItemsList.append(pCornerItem);
    }
  } else {
    for (int i = 0 ; i < mExtents.size() ; i++) {
      QPointF extent = mExtents.at(i);
      CornerItem *pCornerItem = new CornerItem(extent.x(), extent.y(), i, this);
      mCornerItemsList.append(pCornerItem);
    }
  }
}

/*!
  Makes the corner points of the shape visible.
  */
void ShapeAnnotation::setCornerItemsActive()
{
  foreach (CornerItem *pCornerItem, mCornerItemsList)
  {
    pCornerItem->setVisible(true);
  }
}

/*!
  Makes the corner points of the shape hidden.
  */
void ShapeAnnotation::setCornerItemsPassive()
{
  foreach (CornerItem *pCornerItem, mCornerItemsList)
  {
    pCornerItem->setVisible(false);
  }
}

/*!
  Removes the CornerItem's around the shape.
  */
void ShapeAnnotation::removeCornerItems()
{
  foreach (CornerItem *pCornerItem, mCornerItemsList)
  {
    pCornerItem->deleteLater();
  }
  mCornerItemsList.clear();
}

/*!
  Saves the old position of the shape.
  \param oldPosition - the old position of the shape.
  */
void ShapeAnnotation::setOldPosition(QPointF oldPosition)
{
  mOldPosition = oldPosition;
}

/*!
  Returns the old position of the shape.
  \return the old position of the shape.
  */
QPointF ShapeAnnotation::getOldPosition()
{
  return mOldPosition;
}

void ShapeAnnotation::addPoint(QPointF point)
{
  Q_UNUSED(point);
}

void ShapeAnnotation::clearPoints()
{

}

/*!
  Adds the extent point value.
  \param index - the index of extent point.
  \param point - the point value to add.
  */
void ShapeAnnotation::replaceExtent(int index, QPointF point)
{
  if (index >= 0 && index <= 1)
  {
    mExtents.replace(index, point);
  }
}

/*!
  Returns the GraphicsView object.
  \return the pointer to GraphicsView.
  */
void ShapeAnnotation::updateEndExtent(QPointF point)
{
  if (mExtents.size() > 1)
  {
    mExtents.replace(1, point);
  }
}

/*!
  Sets the start arrow value.
  \return startArrow - the start arrow value.
  */
void ShapeAnnotation::setStartArrow(StringHandler::Arrow startArrow)
{
  mArrow.replace(0, startArrow);
}

/*!
  Returns the start arrow value.
  \return the start arrow value.
  */
StringHandler::Arrow ShapeAnnotation::getStartArrow()
{
  return mArrow.at(0);
}

/*!
  Sets the end arrow value.
  \return endArrow - the end arrow value.
  */
void ShapeAnnotation::setEndArrow(StringHandler::Arrow endArrow)
{
  mArrow.replace(1, endArrow);
}

/*!
  Returns the end arrow value.
  \return the end arrow value.
  */
StringHandler::Arrow ShapeAnnotation::getEndArrow()
{
  return mArrow.at(1);
}

/*!
  Sets the arrow size.
  \return arrowSize - the arrow size.
  */
void ShapeAnnotation::setArrowSize(qreal arrowSize)
{
  mArrowSize = arrowSize;
}

/*!
  Returns the arrow size value.
  \return the arrow size value.
  */
qreal ShapeAnnotation::getArrowSize()
{
  return mArrowSize;
}

/*!
  Sets the smooth value.
  \return smooth - the smooth value.
  */
void ShapeAnnotation::setSmooth(StringHandler::Smooth smooth)
{
  mSmooth = smooth;
}


/*!
  Returns the smooth value.
  \return the smooth value.
  */
StringHandler::Smooth ShapeAnnotation::getSmooth()
{
  return mSmooth;
}

/*!
  Sets the extents list.
  \param extents - the extents list.
  */
void ShapeAnnotation::setExtents(QList<QPointF> extents)
{
  mExtents = extents;
}

/*!
  Returns the points list.
  \return the points list.
  */
QList<QPointF> ShapeAnnotation::getExtents()
{
  return mExtents;
}

/*!
  Sets the border pattern value.
  \param pattern - the border pattern.
  */
void ShapeAnnotation::setBorderPattern(StringHandler::BorderPattern pattern)
{
  mBorderPattern = pattern;
}

/*!
  Returns the border pattern value.
  \return the border pattern value.
  */
StringHandler::BorderPattern ShapeAnnotation::getBorderPattern()
{
  return mBorderPattern;
}

/*!
  Sets the corner radius size.
  \return radius - the corner radius.
  */
void ShapeAnnotation::setRadius(qreal radius)
{
  mRadius = radius;
}

/*!
  Returns the corner radius value.
  \return the corner radius.
  */
qreal ShapeAnnotation::getRadius()
{
  return mRadius;
}

/*!
  Sets the start angle.
  \return startAngle - the start angle.
  */
void ShapeAnnotation::setStartAngle(qreal startAngle)
{
  mStartAngle = startAngle;
}

/*!
  Returns the start angle.
  \return the start angle.
  */
qreal ShapeAnnotation::getStartAngle()
{
  return mStartAngle;
}

/*!
  Sets the end angle.
  \return endAngle - the end angle.
  */
void ShapeAnnotation::setEndAngle(qreal endAngle)
{
  mEndAngle = endAngle;
}

/*!
  Returns the end angle.
  \return the end angle.
  */
qreal ShapeAnnotation::getEndAngle()
{
  return mEndAngle;
}

/*!
  Sets the text string.
  \return textString - the string to set.
  */
void ShapeAnnotation::setTextString(QString textString)
{
  mOriginalTextString = textString;
  mTextString = textString;
}

/*!
  Returns the text string.
  \return the text string.
  */
QString ShapeAnnotation::getTextString()
{
  return mOriginalTextString;
}

/*!
  Sets the font name.
  \return fontName - the font name.
  */
void ShapeAnnotation::setFontName(QString fontName)
{
  mFontName = fontName;
}

/*!
  Returns the font name.
  \return the font name.
  */
QString ShapeAnnotation::getFontName()
{
  return mFontName;
}

/*!
  Sets the font size.
  \return fontSize - the font size.
  */
void ShapeAnnotation::setFontSize(qreal fontSize)
{
  mFontSize = fontSize;
}

/*!
  Returns the font size.
  \return the font size.
  */
qreal ShapeAnnotation::getFontSize()
{
  return mFontSize;
}

/*!
  Sets the text styles.
  \return textStyles - the text styles.
  */
void ShapeAnnotation::setTextStyles(QList<StringHandler::TextStyle> textStyles)
{
  mTextStyles = textStyles;
}

/*!
  Returns the text styles.
  \return the text styles.
  */
QList<StringHandler::TextStyle> ShapeAnnotation::getTextStyles()
{
  return mTextStyles;
}

/*!
  Sets the text horizontal alignment.
  \return textStyles - the text horizontal alignment.
  */
void ShapeAnnotation::setTextHorizontalAlignment(StringHandler::TextAlignment textAlignment)
{
  mHorizontalAlignment = textAlignment;
}

/*!
  Returns the text horizontal alignment.
  \return the text horizontal alignment.
  */
StringHandler::TextAlignment ShapeAnnotation::getTextHorizontalAlignment()
{
  return mHorizontalAlignment;
}

/*!
  Sets the file name.
  \return fileName - the file name to set.
  */
void ShapeAnnotation::setFileName(QString fileName, Component *pComponent)
{
  if (fileName.isEmpty())
  {
    mOriginalFileName = fileName;
    mFileName = fileName;
    return;
  }

  OMCProxy *pOMCProxy = 0;
  if (pComponent)
  {
    pOMCProxy = pComponent->getGraphicsView()->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getOMCProxy();
  }
  else
  {
     pOMCProxy = mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow()->getOMCProxy();
  }

  mOriginalFileName = fileName;
  QUrl fileUrl(mOriginalFileName);
  QFileInfo fileInfo(mOriginalFileName);
  QFileInfo classFileInfo(mClassFileName);

  /* if its a modelica:// link then make it absolute path */
  if (fileUrl.scheme().toLower().compare("modelica") == 0)
  {
    mFileName = pOMCProxy->uriToFilename(mOriginalFileName);
  }
  else if (fileInfo.isRelative())
  {
    mFileName = QString(classFileInfo.absoluteDir().absolutePath()).append("/").append(mOriginalFileName);
  }
  else if (fileInfo.isAbsolute())
  {
    mFileName = mOriginalFileName;
  }
  else
  {
    mFileName = "";
  }
}

/*!
  Returns the file name.
  \return the file name.
  */
QString ShapeAnnotation::getFileName()
{
  return mOriginalFileName;
}

/*!
  Sets the image source.
  \return image - the image source.
  */
void ShapeAnnotation::setImageSource(QString imageSource)
{
  mImageSource = imageSource;
}

/*!
  Returns the base 64 image source.
  \return the image source.
  */
QString ShapeAnnotation::getImageSource()
{
  return mImageSource;
}

/*!
  Sets the image.
  \return image - the QImage object.
  */
void ShapeAnnotation::setImage(QImage image)
{
  mImage = image;
}

/*!
  Returns the image.
  \return the image.
  */
QImage ShapeAnnotation::getImage()
{
  return mImage;
}

/*!
  Rotates the shape clockwise.
  \sa rotateAntiClockwise(),
      applyRotation(),
      rotateClockwiseKeyPress(),
      rotateAntiClockwiseKeyPress(),
      rotateClockwiseMouseRightClick(),
      rotateAntiClockwiseMouseRightClick()
  */
void ShapeAnnotation::rotateClockwise()
{
  qreal oldRotation = StringHandler::getNormalizedAngle(mTransformation.getRotateAngle());
  qreal rotateIncrement = -90;
  qreal angle = 0;
  if (oldRotation == -270)
  {
    angle = 0;
  }
  else
  {
    angle = oldRotation + rotateIncrement;
  }
  applyRotation(angle);
}

/*!
  Rotates the shape anti clockwise.
  \sa rotateClockwise(),
      applyRotation(),
      rotateClockwiseKeyPress(),
      rotateAntiClockwiseKeyPress(),
      rotateClockwiseMouseRightClick(),
      rotateAntiClockwiseMouseRightClick()
  */
void ShapeAnnotation::rotateAntiClockwise()
{
  qreal oldRotation = StringHandler::getNormalizedAngle(mTransformation.getRotateAngle());
  qreal rotateIncrement = 90;
  qreal angle = 0;
  if (oldRotation == 270)
  {
    angle = 0;
  }
  else
  {
    angle = oldRotation + rotateIncrement;
  }
  applyRotation(angle);
}

/*!
  Applies the rotation on the shape and sets the shape transformation matrix accordingly.
  \param angle - the rotation angle to apply.
  \sa rotateClockwise(),
      rotateAntiClockwise(),
      rotateClockwiseKeyPress(),
      rotateAntiClockwiseKeyPress(),
      rotateClockwiseMouseRightClick(),
      rotateAntiClockwiseMouseRightClick()
  */
void ShapeAnnotation::applyRotation(qreal angle)
{
  mTransformation.setRotateAngle(angle);
  setTransform(mTransformation.getTransformationMatrix());
  mRotation = angle;
}

/*!
  Adjusts the points according to the origin.
  */
void ShapeAnnotation::adjustPointsWithOrigin()
{
  QList<QPointF> points;
  foreach (QPointF point, mPoints) {
    QPointF adjustedPoint = point - mOrigin;
    points.append(adjustedPoint);
  }
  mPoints = points;
}

/*!
  Adjusts the extents according to the origin.
  */
void ShapeAnnotation::adjustExtentsWithOrigin()
{
  QList<QPointF> extents;
  foreach (QPointF extent, mExtents)
  {
    extent.setX(extent.x() - mOrigin.x());
    extent.setY(extent.y() - mOrigin.y());
    extents.append(extent);
  }
  mExtents = extents;
}

/*!
  Returns the CornerItem located at index.
  \param index
  \return CornerItem
  */
CornerItem* ShapeAnnotation::getCornerItem(int index)
{
  for (int i = 0 ; i < mCornerItemsList.size() ; i++) {
    if (mCornerItemsList[i]->getConnectetPointIndex() == index) {
      return mCornerItemsList[i];
    }
  }
  return 0;
}

/*!
  Updates the position of the CornerItem located at index.
  \param index
  */
void ShapeAnnotation::updateCornerItem(int index)
{
  CornerItem *pCornerItem = getCornerItem(index);
  if (pCornerItem) {
    bool signalsState = pCornerItem->blockSignals(true);
    bool flagState = pCornerItem->flags().testFlag(QGraphicsItem::ItemSendsGeometryChanges);
    pCornerItem->setFlag(QGraphicsItem::ItemSendsGeometryChanges, false);
    pCornerItem->setPos(mPoints.at(index));
    pCornerItem->setFlag(QGraphicsItem::ItemSendsGeometryChanges, flagState);
    pCornerItem->blockSignals(signalsState);
  }
}

/*!
  Adds new points, geometries & CornerItems at index. \n
  This function is called when resizing the connection lines and new points are needed to keep the lines manhattanized.
  \param index
  */
void ShapeAnnotation::insertPointsGeometriesAndCornerItems(int index)
{
  QPointF point = (mPoints[index - 1] + mPoints[index]) / 2;
  mPoints.insert(index, point);
  mPoints.insert(index, point);
  if (mGeometries[index - 1] == ShapeAnnotation::HorizontalLine) {
    mGeometries.insert(index, ShapeAnnotation::HorizontalLine);
    mGeometries.insert(index, ShapeAnnotation::VerticalLine);
  } else if (mGeometries[index - 1] == ShapeAnnotation::VerticalLine) {
    mGeometries.insert(index, ShapeAnnotation::VerticalLine);
    mGeometries.insert(index, ShapeAnnotation::HorizontalLine);
  }
  // if we add new points then we need to add new CornerItems and also need to adjust CornerItems connected indexes.
  mCornerItemsList.insert(index, new CornerItem(point.x(), point.y(), index, this));
  mCornerItemsList.insert(index, new CornerItem(point.x(), point.y(), index, this));
  adjustCornerItemsConnectedIndexes();
}

/*!
  Makes the CornerItems & points indexes same.
  */
void ShapeAnnotation::adjustCornerItemsConnectedIndexes()
{
  for (int i = 0 ; i < mPoints.size() ; i++) {
    if (i < mCornerItemsList.size()) {
      mCornerItemsList[i]->setConnectedPointIndex(i);
    }
  }
}

/*!
  Finds and removes the unncessary points in a connection.\n
  For example if there are three points on same horizontal line then the center point will be removed.
  */
void ShapeAnnotation::removeRedundantPointsGeometriesAndCornerItems()
{
  for (int i = 0 ; i < mPoints.size() ; i++) {
    if ((i+1 < mPoints.size() && mPoints[i].y() == mPoints[i + 1].y() && i+2 < mPoints.size() && mPoints[i + 1].y() == mPoints[i + 2].y()) ||
        (i+1 < mPoints.size() && mPoints[i].x() == mPoints[i + 1].x() && i+2 < mPoints.size() && mPoints[i + 1].x() == mPoints[i + 2].x())) {
      mPoints.removeAt(i + 1);
      mGeometries.removeAt(i);
      CornerItem *pCornerItem = getCornerItem(i + 1);
      if (pCornerItem) {
        pCornerItem->deleteLater();
        mCornerItemsList.removeOne(pCornerItem);
      }
      // adjust CornerItem's and Geometries
      adjustCornerItemsConnectedIndexes();
      adjustGeometries();
      // if we removed the point then start from this point again
      i--;
    }
  }
}

/*!
  Adjusts the Geometries list according to points list.
  */
void ShapeAnnotation::adjustGeometries()
{
  mGeometries.clear();
  for (int i = 1 ; i < mPoints.size() ; i++) {
    if (mGeometries.size() == 0) {
      QPointF currentPoint = mPoints[i];
      QPointF previousPoint = mPoints[i - 1];
      mGeometries.append(findLineGeometryType(previousPoint, currentPoint));
    } else {
      if (mGeometries.back() == ShapeAnnotation::HorizontalLine) {
        mGeometries.push_back(ShapeAnnotation::VerticalLine);
      } else if (mGeometries.back() == ShapeAnnotation::VerticalLine) {
        mGeometries.push_back(ShapeAnnotation::HorizontalLine);
      }
    }
  }
}

/*!
  Sets the shape flags.
  */
void ShapeAnnotation::setShapeFlags(bool enable)
{
  /*
    Only set the ItemIsMovable & ItemSendsGeometryChanges flags on shape if the class is not a system library class
    AND shape is not an inherited shape.
    */
  if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() && !isInheritedShape()) {
    setFlag(QGraphicsItem::ItemIsMovable, enable);
    setFlag(QGraphicsItem::ItemSendsGeometryChanges, enable);
  }
  setFlag(QGraphicsItem::ItemIsSelectable, enable);
}

void ShapeAnnotation::updateShape(ShapeAnnotation *pShapeAnnotation)
{
  Q_UNUSED(pShapeAnnotation);
}

/*!
  Slot activated when mpManhattanizeShapeAction triggered signal is raised.\n
  Finds the curved lines in the Line shape and makes in manhattanize/right-angle line.
  */
void ShapeAnnotation::manhattanizeShape()
{
  int startIndex = -1;
  for (int i = 0 ; i < mPoints.size() ; i++) {
    if (i + 1 < mPoints.size()) {
      if (!isLineStraight(mPoints[i], mPoints[i + 1])) {
        startIndex = i;
        break;
      }
    }
  }
  if (startIndex > -1) {
    int lastIndex = mPoints.size() - 1;
    for (int i = mPoints.size() - 1 ; i >= 0 ; i--) {
      if (i - 1 > -1) {
        if (!isLineStraight(mPoints[i], mPoints[i - 1])) {
          lastIndex = i;
          break;
        }
      }
    }

    QPointF startPoint = mPoints[startIndex];
    QPointF lastPoint = mPoints[lastIndex];
    qreal dx = lastPoint.x() - startPoint.x();
    qreal dy = lastPoint.y() - startPoint.y();
    QList<QPointF> points;
    if (dx == 0) {
      points.append(QPointF(startPoint.x(), startPoint.y() + dy));
    } else if (dy == 0) {
      points.append(QPointF(startPoint.x() + dx, startPoint.y()));
    } else {
      points.append(QPointF(startPoint.x(), startPoint.y() + dy));
      points.append(QPointF(points[0].x() + dx, points[0].y()));
    }
    points.removeLast();
    QList<QPointF> oldPoints = mPoints;
    clearPoints();
    for (int i = 0 ; i <= startIndex ; i++) {
      addPoint(oldPoints[i]);
    }
    if (points.size() > 0) {
      addPoint(points[0]);
    }
    for (int i = lastIndex ; i < oldPoints.size() ; i++) {
      addPoint(oldPoints[i]);
    }
    removeCornerItems();
    drawCornerItems();
    cornerItemReleased();
  }
}

/*!
 * \brief ShapeAnnotation::referenceShapeAdded
 */
void ShapeAnnotation::referenceShapeAdded()
{
  ShapeAnnotation *pShapeAnnotation = qobject_cast<ShapeAnnotation*>(sender());
  if (pShapeAnnotation) {
    if (mpGraphicsView) {
      mpGraphicsView->addItem(this);
    } else if (mpParentComponent) {
      mpParentComponent->shapeAdded();
      setVisible(true);
    }
  }
}

/*!
 * \brief ShapeAnnotation::referenceShapeChanged
 */
void ShapeAnnotation::referenceShapeChanged()
{
  ShapeAnnotation *pShapeAnnotation = qobject_cast<ShapeAnnotation*>(sender());
  if (pShapeAnnotation) {
    if (mpGraphicsView) {
      updateShape(pShapeAnnotation);
      setTransform(pShapeAnnotation->mTransformation.getTransformationMatrix());
    } else if (mpParentComponent) {
      updateShape(pShapeAnnotation);
      setPos(mOrigin);
      setRotation(mRotation);
    }
  }
}

/*!
 * \brief ShapeAnnotation::referenceShapeDeleted
 */
void ShapeAnnotation::referenceShapeDeleted()
{
  ShapeAnnotation *pShapeAnnotation = qobject_cast<ShapeAnnotation*>(sender());
  if (pShapeAnnotation) {
    if (mpGraphicsView) {
      mpGraphicsView->removeItem(this);
    } else if (mpParentComponent) {
      setVisible(false);
      mpParentComponent->shapeDeleted();
    }
  }
}

/*!
  Slot activated when Delete option is choosen from context menu of the shape.\n
  Deletes the connection.
  */
void ShapeAnnotation::deleteConnection()
{
  LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(this);
  if (pLineAnnotation) {
    mpGraphicsView->deleteConnection(pLineAnnotation, true);
    mpGraphicsView->deleteConnectionObject(pLineAnnotation);
    deleteLater();
  }
}

/*!
  Slot activated when Del key is pressed while selecting the shape.\n
  Slot activated when Delete option is choosen from context menu of the shape.\n
  Deletes the shape. Emits the GraphicsView::updateClassAnnotation() SIGNAL.\n
  Since GraphicsView::addClassAnnotation() sets the GraphicsView::mCanAddClassAnnotation flag to false we must set it true again.
  */
void ShapeAnnotation::deleteMe()
{
  // delete the shape
  mpGraphicsView->deleteShape(this);
}

/*!
  Reimplemented by each child shape class to duplicate the shape.
  */
void ShapeAnnotation::duplicate()
{
  /* duplicate code is implemented in each child shape class. */
}

/*!
 * \brief ShapeAnnotation::bringToFront
 * Brings the shape to front of all other shapes.
 */
void ShapeAnnotation::bringToFront()
{
  mpGraphicsView->bringToFront(this);
}

/*!
 * \brief ShapeAnnotation::bringForward
 * Brings the shape one level forward.
 */
void ShapeAnnotation::bringForward()
{
  mpGraphicsView->bringForward(this);
}

/*!
 * \brief ShapeAnnotation::sendToBack
 * Sends the shape to back of all other shapes.
 */
void ShapeAnnotation::sendToBack()
{
  mpGraphicsView->sendToBack(this);
}

/*!
 * \brief ShapeAnnotation::sendBackward
 * Sends the shape one level backward.
 */
void ShapeAnnotation::sendBackward()
{
  mpGraphicsView->sendBackward(this);
}

/*!
  Slot activated when ctrl+r is pressed while selecting the shape.
  \sa rotateClockwise(),
      rotateAntiClockwise(),
      applyRotation(),
      rotateAntiClockwiseKeyPress(),
      rotateClockwiseMouseRightClick(),
      rotateAntiClockwiseMouseRightClick()
  */
void ShapeAnnotation::rotateClockwiseKeyPress()
{
  rotateClockwise();
}

/*!
  Slot activated when ctrl+shift+r is pressed while selecting the shape.
  \sa rotateClockwise(),
      rotateAntiClockwise(),
      applyRotation(),
      rotateClockwiseKeyPress(),
      rotateClockwiseMouseRightClick(),
      rotateAntiClockwiseMouseRightClick()
  */
void ShapeAnnotation::rotateAntiClockwiseKeyPress()
{
  rotateAntiClockwise();
}

/*!
  Slot activated when Rotate Clockwise option is choosen from context menu of the shape.\n
  Emits the GraphicsView::updateClassAnnotation() SIGNAL.\n
  Since GraphicsView::addClassAnnotation() sets the GraphicsView::mCanAddClassAnnotation flag to false we must set it to true again.
  \sa rotateClockwise(),
      rotateAntiClockwise(),
      applyRotation(),
      rotateClockwiseKeyPress(),
      rotateAntiClockwiseKeyPress(),
      rotateAntiClockwiseMouseRightClick()
  */
void ShapeAnnotation::rotateClockwiseMouseRightClick()
{
  rotateClockwise();
  emit updateClassAnnotation();
  mpGraphicsView->setCanAddClassAnnotation(true);
}

/*!
  Slot activated when Rotate Anti Clockwise option is choosen from context menu of the shape.\n
  Emits the GraphicsView::updateClassAnnotation() SIGNAL.\n
  Since GraphicsView::addClassAnnotation() sets the GraphicsView::mCanAddClassAnnotation flag to false we must set it to true again.
  \sa rotateClockwise(),
      rotateAntiClockwise(),
      applyRotation(),
      rotateClockwiseKeyPress(),
      rotateAntiClockwiseKeyPress(),
      rotateClockwiseMouseRightClick()
  */
void ShapeAnnotation::rotateAntiClockwiseMouseRightClick()
{
  rotateAntiClockwise();
  emit updateClassAnnotation();
  mpGraphicsView->setCanAddClassAnnotation(true);
}

/*!
  Slot that moves shape upwards depending on the grid step size value
  \sa moveDown(),
      moveLeft(),
      moveRight(),
      moveShiftUp(),
      moveShiftDown(),
      moveShiftLeft(),
      moveShiftRight(),
      moveCtrlUp(),
      moveCtrlDown(),
      moveCtrlLeft(),
      moveCtrlRight()
  */
void ShapeAnnotation::moveUp()
{
  mTransformation.adjustPosition(0, mpGraphicsView->getCoOrdinateSystem()->getVerticalGridStep());
  setTransform(mTransformation.getTransformationMatrix());
  mOrigin = mTransformation.getPosition();
}

/*!
  Slot that moves shape upwards depending on the grid step size value multiplied by 5
  \sa moveUp(),
      moveDown(),
      moveLeft(),
      moveRight(),
      moveShiftDown(),
      moveShiftLeft(),
      moveShiftRight(),
      moveCtrlUp(),
      moveCtrlDown(),
      moveCtrlLeft(),
      moveCtrlRight()
  */
void ShapeAnnotation::moveShiftUp()
{
  mTransformation.adjustPosition(0, mpGraphicsView->getCoOrdinateSystem()->getVerticalGridStep() * 5);
  setTransform(mTransformation.getTransformationMatrix());
  mOrigin = mTransformation.getPosition();
}

/*!
  Slot that moves shape one pixel upwards
  \sa moveUp(),
      moveDown(),
      moveLeft(),
      moveRight(),
      moveShiftUp(),
      moveShiftDown(),
      moveShiftLeft(),
      moveShiftRight(),
      moveCtrlDown(),
      moveCtrlLeft(),
      moveCtrlRight()
  */
void ShapeAnnotation::moveCtrlUp()
{
  mTransformation.adjustPosition(0, 1);
  setTransform(mTransformation.getTransformationMatrix());
  mOrigin = mTransformation.getPosition();
}

/*!
  Slot that moves shape downwards depending on the grid step size value
  \sa moveUp(),
      moveLeft(),
      moveRight(),
      moveShiftUp(),
      moveShiftDown(),
      moveShiftLeft(),
      moveShiftRight(),
      moveCtrlUp(),
      moveCtrlDown(),
      moveCtrlLeft(),
      moveCtrlRight()
  */
void ShapeAnnotation::moveDown()
{
  mTransformation.adjustPosition(0, -mpGraphicsView->getCoOrdinateSystem()->getVerticalGridStep());
  setTransform(mTransformation.getTransformationMatrix());
  mOrigin = mTransformation.getPosition();
}


/*!
  Slot that moves shape downwards depending on the grid step size value multiplied by 5
  \sa moveUp(),
      moveDown(),
      moveLeft(),
      moveRight(),
      moveShiftUp(),
      moveShiftLeft(),
      moveShiftRight(),
      moveCtrlUp(),
      moveCtrlDown(),
      moveCtrlLeft(),
      moveCtrlRight()
  */
void ShapeAnnotation::moveShiftDown()
{
  mTransformation.adjustPosition(0, -(mpGraphicsView->getCoOrdinateSystem()->getVerticalGridStep() * 5));
  setTransform(mTransformation.getTransformationMatrix());
  mOrigin = mTransformation.getPosition();
}

/*!
  Slot that moves shape one pixel downwards
  \sa moveUp(),
      moveDown(),
      moveLeft(),
      moveRight(),
      moveShiftUp(),
      moveShiftDown(),
      moveShiftLeft(),
      moveShiftRight(),
      moveCtrlUp(),
      moveCtrlLeft(),
      moveCtrlRight()
  */
void ShapeAnnotation::moveCtrlDown()
{
  mTransformation.adjustPosition(0, -1);
  setTransform(mTransformation.getTransformationMatrix());
  mOrigin = mTransformation.getPosition();
}

/*!
  Slot that moves shape leftwards depending on the grid step size
  \sa moveUp(),
      moveDown(),
      moveRight(),
      moveShiftUp(),
      moveShiftDown(),
      moveShiftLeft(),
      moveShiftRight(),
      moveCtrlUp(),
      moveCtrlDown(),
      moveCtrlLeft(),
      moveCtrlRight()
  */
void ShapeAnnotation::moveLeft()
{
  mTransformation.adjustPosition(-mpGraphicsView->getCoOrdinateSystem()->getHorizontalGridStep(), 0);
  setTransform(mTransformation.getTransformationMatrix());
  mOrigin = mTransformation.getPosition();
}

/*!
  Slot that moves shape leftwards depending on the grid step size value multiplied by 5
  \sa moveUp(),
      moveDown(),
      moveLeft(),
      moveRight(),
      moveShiftUp(),
      moveShiftDown(),
      moveShiftRight(),
      moveCtrlUp(),
      moveCtrlDown(),
      moveCtrlLeft(),
      moveCtrlRight()
  */
void ShapeAnnotation::moveShiftLeft()
{
  mTransformation.adjustPosition(-(mpGraphicsView->getCoOrdinateSystem()->getHorizontalGridStep() * 5), 0);
  setTransform(mTransformation.getTransformationMatrix());
  mOrigin = mTransformation.getPosition();
}

/*!
  Slot that moves shape one pixel leftwards
  \sa moveUp(),
      moveDown(),
      moveLeft(),
      moveRight(),
      moveShiftUp(),
      moveShiftDown(),
      moveShiftLeft(),
      moveShiftRight(),
      moveCtrlUp(),
      moveCtrlDown(),
      moveCtrlRight()
  */
void ShapeAnnotation::moveCtrlLeft()
{
  mTransformation.setOrigin(QPointF(mTransformation.getPosition().x() - 1, mTransformation.getPosition().y()));
  setTransform(mTransformation.getTransformationMatrix());
  mOrigin = mTransformation.getPosition();
}

/*!
  Slot that moves shape rightwards depending on the grid step size
  \sa moveUp(),
      moveDown(),
      moveLeft(),
      moveShiftUp(),
      moveShiftDown(),
      moveShiftLeft(),
      moveShiftRight(),
      moveCtrlUp(),
      moveCtrlDown(),
      moveCtrlLeft(),
      moveCtrlRight()
  */
void ShapeAnnotation::moveRight()
{
  mTransformation.adjustPosition(mpGraphicsView->getCoOrdinateSystem()->getHorizontalGridStep(), 0);
  setTransform(mTransformation.getTransformationMatrix());
  mOrigin = mTransformation.getPosition();
}

/*!
  Slot that moves shape rightwards depending on the grid step size value multiplied by 5
  \sa moveUp(),
      moveDown(),
      moveLeft(),
      moveRight(),
      moveShiftUp(),
      moveShiftDown(),
      moveShiftLeft(),
      moveCtrlUp(),
      moveCtrlDown(),
      moveCtrlLeft(),
      moveCtrlRight()
  */
void ShapeAnnotation::moveShiftRight()
{
  mTransformation.adjustPosition(mpGraphicsView->getCoOrdinateSystem()->getHorizontalGridStep() * 5, 0);
  setTransform(mTransformation.getTransformationMatrix());
  mOrigin = mTransformation.getPosition();
}

/*!
  Slot that moves shape one pixel rightwards
  \sa moveUp(),
      moveDown(),
      moveLeft(),
      moveRight(),
      moveShiftUp(),
      moveShiftDown(),
      moveShiftLeft(),
      moveShiftRight(),
      moveCtrlUp(),
      moveCtrlDown(),
      moveCtrlLeft()
  */
void ShapeAnnotation::moveCtrlRight()
{
  mTransformation.setOrigin(QPointF(mTransformation.getPosition().x() + 1, mTransformation.getPosition().y()));
  setTransform(mTransformation.getTransformationMatrix());
  mOrigin = mTransformation.getPosition();
}

/*!
  Slot activated when CornerItem around the shape is pressed. Sets the flag that CornerItem is pressed.
  */
void ShapeAnnotation::cornerItemPressed()
{
  mIsCornerItemClicked = true;
  setSelected(false);
}

/*!
  Slot activated when CornerItem around the shape is release. Unsets the flag that CornerItem is pressed.
  */
void ShapeAnnotation::cornerItemReleased()
{
  mIsCornerItemClicked = false;
  if (isSelected()) {
    setCornerItemsActive();
  } else {
    setSelected(true);
  }
}

/*!
  Slot activated when CornerItem around the shape is moved. Sends the new position values for the associated shape point.
  \param index - the index of the CornerItem
  \param point - the new CornerItem position
  */
void ShapeAnnotation::updateCornerItemPoint(int index, QPointF point)
{
  if (dynamic_cast<LineAnnotation*>(this)) {
    LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(this);
    if (pLineAnnotation->getLineType() == LineAnnotation::ConnectionType) {
      // if moving the 2nd last point then we need to add more points after it to keep the last point manhattanized with connector
      int secondLastIndex = mPoints.size() - 2;
      if (index == secondLastIndex) {
        // just check if additional points are really needed or not.
        if ((mGeometries[secondLastIndex] == ShapeAnnotation::HorizontalLine && mPoints[index].y() != point.y()) ||
            (mGeometries[secondLastIndex] == ShapeAnnotation::VerticalLine && mPoints[index].x() != point.x())) {
          insertPointsGeometriesAndCornerItems(mPoints.size() - 1);
        }
      }
      // if moving the 2nd point then we need to add more points behind it to keep the first point manhattanized with connector
      if (index == 1) {
        // just check if additional points are really needed or not.
        if ((mGeometries[0] == ShapeAnnotation::HorizontalLine && mPoints[index].y() != point.y()) ||
            (mGeometries[0] == ShapeAnnotation::VerticalLine && mPoints[index].x() != point.x())) {
          insertPointsGeometriesAndCornerItems(1);
          index = index + 2;
        }
      }
      qreal dx = point.x() - mPoints[index].x();
      qreal dy = point.y() - mPoints[index].y();
      mPoints.replace(index, point);
      // update previous point
      if (mGeometries[index - 1] == ShapeAnnotation::HorizontalLine) {
        mPoints[index - 1] = QPointF(mPoints[index - 1].x(), mPoints[index - 1].y() +  dy);
        updateCornerItem(index - 1);
      } else if (mGeometries[index - 1] == ShapeAnnotation::VerticalLine) {
        mPoints[index - 1] = QPointF(mPoints[index - 1].x() + dx, mPoints[index - 1].y());
        updateCornerItem(index - 1);
      }
      // update next point
      if (mGeometries[index] == ShapeAnnotation::HorizontalLine) {
        mPoints[index + 1] = QPointF(mPoints[index + 1].x(), mPoints[index + 1].y() +  dy);
        updateCornerItem(index + 1);
      } else if (mGeometries[index] == ShapeAnnotation::VerticalLine) {
        mPoints[index + 1] = QPointF(mPoints[index + 1].x() + dx, mPoints[index + 1].y());
        updateCornerItem(index + 1);
      }
    } else {
      mPoints.replace(index, point);
    }
  } else if (dynamic_cast<PolygonAnnotation*>(this)) { /* if shape is the PolygonAnnotation then update the start and end point together */
    mPoints.replace(index, point);
    /* if first point */
    if (index == 0) {
      mPoints.back() = point;
      updateCornerItem(mPoints.size() - 1);
    } else if (index == mPoints.size() - 1) { /* if last point */
      mPoints.first() = point;
      updateCornerItem(0);
    }
  } else {
    mExtents.replace(index, point);
  }
}

ShapeAnnotation::LineGeometryType ShapeAnnotation::findLineGeometryType(QPointF point1, QPointF point2)
{
  QLineF line(point1, point2);
  qreal angle = StringHandler::getNormalizedAngle(line.angle());

  if ((angle > 45 && angle < 135) || (angle > 225 && angle < 315)) {
    return ShapeAnnotation::VerticalLine;
  } else {
    return ShapeAnnotation::HorizontalLine;
  }
}

bool ShapeAnnotation::isLineStraight(QPointF point1, QPointF point2)
{
  QLineF line(point1, point2);
  qreal angle = StringHandler::getNormalizedAngle(line.angle());

  if (angle == 0 || angle == 90 || angle == 180 || angle == 270 || angle == 360) {
    return true;
  } else {
    return false;
  }
}

/*!
  Slot activated when Properties option is choosen from context menu of the shape.
  */
void ShapeAnnotation::showShapeProperties()
{
  if (!mpGraphicsView || mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::TLM)
    return;
  MainWindow *pMainWindow = mpGraphicsView->getModelWidget()->getModelWidgetContainer()->getMainWindow();
  ShapePropertiesDialog *pShapePropertiesDialog = new ShapePropertiesDialog(this, pMainWindow);
  pShapePropertiesDialog->exec();
}

/*!
  Reimplementation of contextMenuEvent.\n
  Creates a context menu for the shape.\n
  No context menu for the shapes that are part of Component.
  \param pEvent - pointer to QGraphicsSceneContextMenuEvent
  */
void ShapeAnnotation::contextMenuEvent(QGraphicsSceneContextMenuEvent *pEvent)
{
  if (!mIsCustomShape) {
    QGraphicsItem::contextMenuEvent(pEvent);
    return;
  }
  if (!isSelected()) {
    setSelected(true);
  }

  QMenu menu(mpGraphicsView);
  if(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::TLM){
    menu.addAction(mpGraphicsView->getDeleteConnectionAction());
  } else {
    menu.addAction(mpShapePropertiesAction);
    menu.addSeparator();
    if (isInheritedShape()) {
      mpGraphicsView->getDeleteAction()->setDisabled(true);
      mpGraphicsView->getDuplicateAction()->setDisabled(true);
      mpGraphicsView->getRotateClockwiseAction()->setDisabled(true);
      mpGraphicsView->getRotateAntiClockwiseAction()->setDisabled(true);
    }
    LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(this);
    LineAnnotation::LineType lineType = LineAnnotation::ShapeType;
    if (pLineAnnotation) {
      lineType = pLineAnnotation->getLineType();
      menu.addAction(mpManhattanizeShapeAction);
    }
    if (lineType == LineAnnotation::ConnectionType) {
      menu.addAction(mpGraphicsView->getDeleteConnectionAction());
    } else {
      menu.addAction(mpGraphicsView->getDeleteAction());
      menu.addAction(mpGraphicsView->getDuplicateAction());
      menu.addSeparator();
      menu.addAction(mpGraphicsView->getBringToFrontAction());
      menu.addAction(mpGraphicsView->getBringForwardAction());
      menu.addAction(mpGraphicsView->getSendToBackAction());
      menu.addAction(mpGraphicsView->getSendBackwardAction());
      menu.addSeparator();
      menu.addAction(mpGraphicsView->getRotateClockwiseAction());
      menu.addAction(mpGraphicsView->getRotateAntiClockwiseAction());
    }
  }
  menu.exec(pEvent->screenPos());
}

/*!
  Reimplementation of itemChange.\n
  Connects the operations/signals, that can be performed on this shape, with the methods/slots depending on the shape's selection value.\n
  No operations/signals connection for shapes that are part of system library classes.
  \param change - GraphicsItemChange
  \param value - QVariant
  */
QVariant ShapeAnnotation::itemChange(GraphicsItemChange change, const QVariant &value)
{
  QGraphicsItem::itemChange(change, value);
  if (change == QGraphicsItem::ItemSelectedHasChanged) {
    LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(this);
    LineAnnotation::LineType lineType = LineAnnotation::ShapeType;
    if (pLineAnnotation) {
      lineType = pLineAnnotation->getLineType();
    }
    if (isSelected()) {
      setCornerItemsActive();
      setCursor(Qt::SizeAllCursor);
      /* Only allow manipulations on shapes if the class is not a system library class OR shape is not an inherited component. */
      if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() && !isInheritedShape()) {
        if (lineType == LineAnnotation::ConnectionType) {
          connect(mpGraphicsView->getDeleteConnectionAction(), SIGNAL(triggered()), SLOT(deleteConnection()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressDelete()), SLOT(deleteConnection()), Qt::UniqueConnection);
        } else {
          connect(mpGraphicsView, SIGNAL(mouseDelete()), this, SLOT(deleteMe()), Qt::UniqueConnection);
          connect(mpGraphicsView->getDuplicateAction(), SIGNAL(triggered()), this, SLOT(duplicate()), Qt::UniqueConnection);
          connect(mpGraphicsView->getBringToFrontAction(), SIGNAL(triggered()), this, SLOT(bringToFront()), Qt::UniqueConnection);
          connect(mpGraphicsView->getBringForwardAction(), SIGNAL(triggered()), this, SLOT(bringForward()), Qt::UniqueConnection);
          connect(mpGraphicsView->getSendToBackAction(), SIGNAL(triggered()), this, SLOT(sendToBack()), Qt::UniqueConnection);
          connect(mpGraphicsView->getSendBackwardAction(), SIGNAL(triggered()), this, SLOT(sendBackward()), Qt::UniqueConnection);
          connect(mpGraphicsView->getRotateClockwiseAction(), SIGNAL(triggered()), this, SLOT(rotateClockwiseMouseRightClick()), Qt::UniqueConnection);
          connect(mpGraphicsView->getRotateAntiClockwiseAction(), SIGNAL(triggered()), this, SLOT(rotateAntiClockwiseMouseRightClick()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressDuplicate()), this, SLOT(duplicate()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), this, SLOT(rotateClockwiseKeyPress()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), this, SLOT(rotateAntiClockwiseKeyPress()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressUp()), this, SLOT(moveUp()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressShiftUp()), this, SLOT(moveShiftUp()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressCtrlUp()), this, SLOT(moveCtrlUp()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressDown()), this, SLOT(moveDown()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressShiftDown()), this, SLOT(moveShiftDown()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressCtrlDown()), this, SLOT(moveCtrlDown()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressLeft()), this, SLOT(moveLeft()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressShiftLeft()), this, SLOT(moveShiftLeft()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressCtrlLeft()), this, SLOT(moveCtrlLeft()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressRight()), this, SLOT(moveRight()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressShiftRight()), this, SLOT(moveShiftRight()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressCtrlRight()), this, SLOT(moveCtrlRight()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyRelease()), this, SIGNAL(updateClassAnnotation()), Qt::UniqueConnection);
        }
      }
    } else if (!mIsCornerItemClicked) {
      setCornerItemsPassive();
      unsetCursor();
      /* Only allow manipulations on shapes if the class is not a system library class OR shape is not an inherited component. */
      if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() && !isInheritedShape()) {
        if (lineType == LineAnnotation::ConnectionType) {
          disconnect(mpGraphicsView->getDeleteConnectionAction(), SIGNAL(triggered()), this, SLOT(deleteConnection()));
          disconnect(mpGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteConnection()));
        } else {
          disconnect(mpGraphicsView, SIGNAL(mouseDelete()), this, SLOT(deleteMe()));
          disconnect(mpGraphicsView->getDuplicateAction(), SIGNAL(triggered()), this, SLOT(duplicate()));
          disconnect(mpGraphicsView->getBringToFrontAction(), SIGNAL(triggered()), this, SLOT(bringToFront()));
          disconnect(mpGraphicsView->getBringForwardAction(), SIGNAL(triggered()), this, SLOT(bringForward()));
          disconnect(mpGraphicsView->getSendToBackAction(), SIGNAL(triggered()), this, SLOT(sendToBack()));
          disconnect(mpGraphicsView->getSendBackwardAction(), SIGNAL(triggered()), this, SLOT(sendBackward()));
          disconnect(mpGraphicsView->getRotateClockwiseAction(), SIGNAL(triggered()), this, SLOT(rotateClockwiseMouseRightClick()));
          disconnect(mpGraphicsView->getRotateAntiClockwiseAction(), SIGNAL(triggered()), this, SLOT(rotateAntiClockwiseMouseRightClick()));
          disconnect(mpGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()));
          disconnect(mpGraphicsView, SIGNAL(keyPressDuplicate()), this, SLOT(duplicate()));
          disconnect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), this, SLOT(rotateClockwiseKeyPress()));
          disconnect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), this, SLOT(rotateAntiClockwiseKeyPress()));
          disconnect(mpGraphicsView, SIGNAL(keyPressUp()), this, SLOT(moveUp()));
          disconnect(mpGraphicsView, SIGNAL(keyPressShiftUp()), this, SLOT(moveShiftUp()));
          disconnect(mpGraphicsView, SIGNAL(keyPressCtrlUp()), this, SLOT(moveCtrlUp()));
          disconnect(mpGraphicsView, SIGNAL(keyPressDown()), this, SLOT(moveDown()));
          disconnect(mpGraphicsView, SIGNAL(keyPressShiftDown()), this, SLOT(moveShiftDown()));
          disconnect(mpGraphicsView, SIGNAL(keyPressCtrlDown()), this, SLOT(moveCtrlDown()));
          disconnect(mpGraphicsView, SIGNAL(keyPressLeft()), this, SLOT(moveLeft()));
          disconnect(mpGraphicsView, SIGNAL(keyPressShiftLeft()), this, SLOT(moveShiftLeft()));
          disconnect(mpGraphicsView, SIGNAL(keyPressCtrlLeft()), this, SLOT(moveCtrlLeft()));
          disconnect(mpGraphicsView, SIGNAL(keyPressRight()), this, SLOT(moveRight()));
          disconnect(mpGraphicsView, SIGNAL(keyPressShiftRight()), this, SLOT(moveShiftRight()));
          disconnect(mpGraphicsView, SIGNAL(keyPressCtrlRight()), this, SLOT(moveCtrlRight()));
          disconnect(mpGraphicsView, SIGNAL(keyRelease()), this, SIGNAL(updateClassAnnotation()));
        }
      }
    }
  } else if (change == QGraphicsItem::ItemPositionChange) {
    // move by grid distance while dragging component
    QPointF positionDifference = mpGraphicsView->movePointByGrid(value.toPointF() - pos());
    return pos() + positionDifference;
  }
  return value;
}
