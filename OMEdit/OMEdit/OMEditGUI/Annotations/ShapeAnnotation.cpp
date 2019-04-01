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

#include "ShapeAnnotation.h"
#include "Util/Helper.h"
#include "MainWindow.h"
#include "Options/OptionsDialog.h"
#include "ShapePropertiesDialog.h"
#include "Modeling/Commands.h"
#include "Component/ComponentProperties.h"
#include "TLM/FetchInterfaceDataDialog.h"
#include "Plotting/VariablesWidget.h"

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
  mDynamicVisible = pShapeAnnotation->mDynamicVisible;
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
  if (list.at(0).startsWith("{")) {
    // DynamicSelect
    QStringList args = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(0)));
    if (args.count() > 0)
      mVisible = args.at(0).contains("true");
    if (args.count() > 1)
      mDynamicVisible = args.at(1);  // variable name
  }
  else {
    mVisible = list.at(0).contains("true");
  }
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
 * \brief GraphicItem::getOMCShapeAnnotation
 * Returns the annotation values of the GraphicItem in format as returned by OMC.
 * \return the annotation values as a list.
 */
QStringList GraphicItem::getOMCShapeAnnotation()
{
  QStringList annotationString;
  /* get visible */
  annotationString.append(mVisible ? "true" : "false");
  /* get origin */
  QString originString;
  originString.append("{").append(QString::number(mOrigin.x())).append(",");
  originString.append(QString::number(mOrigin.y())).append("}");
  annotationString.append(originString);
  /* get rotation */
  annotationString.append(QString::number(mRotation));
  return annotationString;
}

/*!
 * \brief GraphicItem::getShapeAnnotation
 * Returns the annotation values of the GraphicItem.
 * \return the annotation values as a list.
 */
QStringList GraphicItem::getShapeAnnotation()
{
  QStringList annotationString;
  /* get visible */
  if (!mVisible) {
    annotationString.append("visible=false");
  }
  /* get origin */
  if (mOrigin != QPointF(0, 0)) {
    QString originString;
    originString.append("origin=");
    originString.append("{").append(QString::number(mOrigin.x())).append(",");
    originString.append(QString::number(mOrigin.y())).append("}");
    annotationString.append(originString);
  }
  /* get rotation */
  if (mRotation != 0) {
    annotationString.append(QString("rotation=").append(QString::number(mRotation)));
  }
  return annotationString;
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
 * \brief FilledShape::getOMCShapeAnnotation
 * Returns the annotation values of the FilledShape in format as returned by OMC.
 * \return the annotation values as a list.
 */
QStringList FilledShape::getOMCShapeAnnotation()
{
  QStringList annotationString;
  /* get the line color */
  QString lineColorString;
  lineColorString.append("{");
  lineColorString.append(QString::number(mLineColor.red())).append(",");
  lineColorString.append(QString::number(mLineColor.green())).append(",");
  lineColorString.append(QString::number(mLineColor.blue()));
  lineColorString.append("}");
  annotationString.append(lineColorString);
  /* get the fill color */
  QString fillColorString;
  fillColorString.append("{");
  fillColorString.append(QString::number(mFillColor.red())).append(",");
  fillColorString.append(QString::number(mFillColor.green())).append(",");
  fillColorString.append(QString::number(mFillColor.blue()));
  fillColorString.append("}");
  annotationString.append(fillColorString);
  /* get the line pattern */
  annotationString.append(StringHandler::getLinePatternString(mLinePattern));
  /* get the fill pattern */
  annotationString.append(StringHandler::getFillPatternString(mFillPattern));
  // get the thickness
  annotationString.append(QString::number(mLineThickness));
  return annotationString;
}

/*!
 * \brief FilledShape::getShapeAnnotation
 * Returns the annotation values of the FilledShape.
 * \return the annotation values as a list.
 */
QStringList FilledShape::getShapeAnnotation()
{
  QStringList annotationString;
  /* get the line color */
  if (mLineColor != Qt::black) {
    QString lineColorString;
    lineColorString.append("lineColor={");
    lineColorString.append(QString::number(mLineColor.red())).append(",");
    lineColorString.append(QString::number(mLineColor.green())).append(",");
    lineColorString.append(QString::number(mLineColor.blue()));
    lineColorString.append("}");
    annotationString.append(lineColorString);
  }
  /* get the fill color */
  if (mFillColor != Qt::black) {
    QString fillColorString;
    fillColorString.append("fillColor={");
    fillColorString.append(QString::number(mFillColor.red())).append(",");
    fillColorString.append(QString::number(mFillColor.green())).append(",");
    fillColorString.append(QString::number(mFillColor.blue()));
    fillColorString.append("}");
    annotationString.append(fillColorString);
  }
  /* get the line pattern */
  if (mLinePattern != StringHandler::LineSolid) {
    annotationString.append(QString("pattern=").append(StringHandler::getLinePatternString(mLinePattern)));
  }
  /* get the fill pattern */
  if (mFillPattern != StringHandler::FillNone) {
    annotationString.append(QString("fillPattern=").append(StringHandler::getFillPatternString(mFillPattern)));
  }
  // get the thickness
  if (mLineThickness != 0.25) {
    annotationString.append(QString("lineThickness=").append(QString::number(mLineThickness)));
  }
  return annotationString;
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
  setOldScenePosition(QPointF(0, 0));
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
  mpParentComponent = 0;
  mTransformation = Transformation(StringHandler::Diagram);
  mIsCustomShape = true;
  mIsInheritedShape = inheritedShape;
  setOldScenePosition(QPointF(0, 0));
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
  mFontName = Helper::systemFontInfo.family();
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
  mTextStyles = pShapeAnnotation->mTextStyles;
  mHorizontalAlignment = pShapeAnnotation->mHorizontalAlignment;
  mOriginalFileName = mOriginalFileName;
  mFileName = pShapeAnnotation->mFileName;
  mClassFileName = pShapeAnnotation->mClassFileName;
  mImageSource = pShapeAnnotation->mImageSource;
  mImage = pShapeAnnotation->mImage;
  mDynamicTextString = pShapeAnnotation->mDynamicTextString;
}

/*!
  Reads the user defined line and fill style values. Overrides the Modelica specification 3.2 default values.
  \sa setDefaults()
  */
void ShapeAnnotation::setUserDefaults()
{
  OptionsDialog *pOptionsDialog = OptionsDialog::instance();
  /* Set user Line Style settings */
  if (pOptionsDialog->getLineStylePage()->getLineColor().isValid()) {
    mLineColor = pOptionsDialog->getLineStylePage()->getLineColor();
  }
  mLinePattern = StringHandler::getLinePatternType(pOptionsDialog->getLineStylePage()->getLinePattern());
  mLineThickness = pOptionsDialog->getLineStylePage()->getLineThickness();
  mArrow.replace(0, StringHandler::getArrowType(pOptionsDialog->getLineStylePage()->getLineStartArrow()));
  mArrow.replace(1, StringHandler::getArrowType(pOptionsDialog->getLineStylePage()->getLineEndArrow()));
  mArrowSize = pOptionsDialog->getLineStylePage()->getLineArrowSize();
  if (pOptionsDialog->getLineStylePage()->getLineSmooth()) {
    mSmooth = StringHandler::SmoothBezier;
  } else {
    mSmooth = StringHandler::SmoothNone;
  }
  /* Set user Fill Style settings */
  if (pOptionsDialog->getFillStylePage()->getFillColor().isValid()) {
    mFillColor = pOptionsDialog->getFillStylePage()->getFillColor();
  }
  mFillPattern = StringHandler::getFillPatternType(pOptionsDialog->getFillStylePage()->getFillPattern());
}

bool ShapeAnnotation::isInheritedShape()
{
  return mIsInheritedShape;
}

/*!
 * \brief ShapeAnnotation::createActions
 * Defines the actions used by the shape's context menu.
 */
void ShapeAnnotation::createActions()
{
  // shape properties
  mpShapePropertiesAction = new QAction(Helper::properties, mpGraphicsView);
  mpShapePropertiesAction->setStatusTip(tr("Shows the shape properties"));
  connect(mpShapePropertiesAction, SIGNAL(triggered()), SLOT(showShapeProperties()));
  // shape attributes
  mpAlignInterfacesAction = new QAction(QIcon(":/Resources/icons/align-interfaces.svg"), Helper::alignInterfaces, mpGraphicsView);
  mpAlignInterfacesAction->setStatusTip(Helper::alignInterfacesTip);
  connect(mpAlignInterfacesAction, SIGNAL(triggered()), SLOT(alignInterfaces()));
  // shape attributes
  mpShapeAttributesAction = new QAction(Helper::attributes, mpGraphicsView);
  mpShapeAttributesAction->setStatusTip(tr("Shows the shape attributes"));
  connect(mpShapeAttributesAction, SIGNAL(triggered()), SLOT(showShapeAttributes()));
  // edit transition action
  mpEditTransitionAction = new QAction(Helper::editTransition, mpGraphicsView);
  mpEditTransitionAction->setStatusTip(tr("Edits the transition"));
  connect(mpEditTransitionAction, SIGNAL(triggered()), SLOT(editTransition()));
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
 * \brief ShapeAnnotation::applyLinePattern
 * Applies the shape line pattern.
 * \param painter - pointer to QPainter
 */
void ShapeAnnotation::applyLinePattern(QPainter *painter)
{
  qreal thickness = Utilities::convertMMToPixel(mLineThickness);
  /* Ticket #4490
   * The specification doesn't say anything about it.
   * But just to keep this consist with Dymola set a default line thickness for border patterns raised & sunken.
   * We need better handling of border patterns.
   */
  if (mBorderPattern == StringHandler::BorderRaised || mBorderPattern == StringHandler::BorderSunken) {
    thickness = Utilities::convertMMToPixel(0.25);
  }
  QPen pen(mLineColor, thickness, StringHandler::getLinePatternType(mLinePattern), Qt::SquareCap, Qt::MiterJoin);
  /* The specification doesn't say anything about it.
   * But just to keep this consist with Dymola we use Qt::BevelJoin for Line shapes.
   * All other shapes use Qt::MiterJoin
   */
  if (dynamic_cast<LineAnnotation*>(this)) {
    pen.setJoinStyle(Qt::BevelJoin);
  }
  /* Ticket #3222
   * Make all the shapes use cosmetic pens so that they perserve their pen width when scaled i.e zoomed in/out.
   */
  pen.setCosmetic(true);
  /* Ticket #2272, Ticket #2268.
   * If thickness is greater than 2 then don't make the pen cosmetic since cosmetic pens don't change the width with respect to zoom.
   * Use non cosmetic pens for Libraries Browser and shapes inside component when thickness is greater than 2.
   */
  if (thickness > 2
      && ((mpGraphicsView && mpGraphicsView->isRenderingLibraryPixmap())
          || mpParentComponent)) {
    pen.setCosmetic(false);
  }
  // if thickness is greater than 1 pixel then use antialiasing.
  if (thickness > 1) {
    painter->setRenderHint(QPainter::Antialiasing);
  }
  painter->setPen(pen);
}

/*!
  Applies the shape fill pattern.
  \param painter - pointer to QPainter
  */
void ShapeAnnotation::applyFillPattern(QPainter *painter)
{
  QRectF boundingRectangle;
  if (dynamic_cast<PolygonAnnotation*>(this)) {
    boundingRectangle = boundingRect();
  } else {
    boundingRectangle = getBoundingRect();
  }
  QLinearGradient linearGradient;
  QRadialGradient radialGradient;
  switch (mFillPattern) {
    case StringHandler::FillHorizontalCylinder:
      linearGradient = QLinearGradient(boundingRectangle.center().x(), boundingRectangle.top(), boundingRectangle.center().x(), boundingRectangle.bottom());
      linearGradient.setColorAt(0.0, mLineColor);
      linearGradient.setColorAt(0.5, mFillColor);
      linearGradient.setColorAt(1.0, mLineColor);
      painter->setBrush(linearGradient);
      break;
    case StringHandler::FillVerticalCylinder:
      linearGradient = QLinearGradient(boundingRectangle.left(), boundingRectangle.center().y(), boundingRectangle.right(), boundingRectangle.center().y());
      linearGradient.setColorAt(0.0, mLineColor);
      linearGradient.setColorAt(0.5, mFillColor);
      linearGradient.setColorAt(1.0, mLineColor);
      painter->setBrush(linearGradient);
      break;
    case StringHandler::FillSphere:
      radialGradient = QRadialGradient(boundingRectangle.center().x(), boundingRectangle.center().y(), boundingRectangle.width());
      radialGradient.setColorAt(0.0, mFillColor);
      radialGradient.setColorAt(1.0, mLineColor);
      painter->setBrush(radialGradient);
      break;
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
 * \brief ShapeAnnotation::parseShapeAnnotation
 * Parses the shape annotation. Reimplemented by each child shape class to parse their annotation.
 * \param annotation
 */
void ShapeAnnotation::parseShapeAnnotation(QString annotation)
{
  Q_UNUSED(annotation);
}

/*!
 * \brief ShapeAnnotation::getOMCShapeAnnotation
 * Returns the shape annotation in format as returned by OMC. Reimplemented by each child shape class to return their annotation.
 * \return the shape annotation string.
 */
QString ShapeAnnotation::getOMCShapeAnnotation()
{
  return "";
}

/*!
 * \brief ShapeAnnotation::getShapeAnnotation
 * Returns the shape annotation. Reimplemented by each child shape class to return their annotation.
 * \return the shape annotation string.
 */
QString ShapeAnnotation::getShapeAnnotation()
{
  return "";
}

/*!
 * \brief ShapeAnnotation::initializeTransformation
 * Initializes the transformation matrix with the default transformation values of the shape.
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
 * \brief ShapeAnnotation::drawCornerItems
 * Draws the CornerItem around the shape.\n
 * If the shape is LineAnnotation or PolygonAnnotation then their points are used to draw CornerItem's.\n
 * If the shape is RectangleAnnotation, EllipseAnnotation, TextAnnotation or BitmapAnnotation
 * then their extents are used to draw CornerItem's.
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
      /* if line is a connection or transition then make the first and last point non movable.
       * if line is initial state then make the first point non movable.
       */
      if ((((lineType == LineAnnotation::ConnectionType || lineType == LineAnnotation::TransitionType) && (i == 0 || i == mPoints.size() - 1))
           || (lineType == LineAnnotation::InitialStateType && i == 0))) {
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
 * \brief ShapeAnnotation::setCornerItemsActiveOrPassive
 * Makes the corner points of the shape active/passive.
 */
void ShapeAnnotation::setCornerItemsActiveOrPassive()
{
  foreach (CornerItem *pCornerItem, mCornerItemsList) {
    if (isSelected()) {
      pCornerItem->setToolTip(Helper::clickAndDragToResize);
      pCornerItem->setVisible(true);
    } else {
      pCornerItem->setToolTip("");
      pCornerItem->setVisible(false);
    }
  }
}

/*!
 * \brief ShapeAnnotation::removeCornerItems
 * Removes the CornerItem's around the shape.
 */
void ShapeAnnotation::removeCornerItems()
{
  foreach (CornerItem *pCornerItem, mCornerItemsList) {
    pCornerItem->deleteLater();
  }
  mCornerItemsList.clear();
}

/*!
 * \brief ShapeAnnotation::replaceExtent
 * Adds the extent point value.
 * \param index - the index of extent point.
 * \param point - the point value to add.
 */
void ShapeAnnotation::replaceExtent(int index, QPointF point)
{
  if (index >= 0 && index <= 1) {
    mExtents.replace(index, point);
  }
}

/*!
 * \brief ShapeAnnotation::updateEndExtent
 * Updates the end extent point.
 * \param point
 */
void ShapeAnnotation::updateEndExtent(QPointF point)
{
  if (mExtents.size() > 1) {
    mExtents.replace(1, point);
  }
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
 * \brief ShapeAnnotation::setFileName
 * Sets the file name.
 * \param fileName
 */
void ShapeAnnotation::setFileName(QString fileName)
{
  if (fileName.isEmpty()) {
    mOriginalFileName = fileName;
    mFileName = fileName;
    return;
  }

  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  mOriginalFileName = fileName;
  QUrl fileUrl(mOriginalFileName);
  QFileInfo fileInfo(mOriginalFileName);
  QFileInfo classFileInfo(mClassFileName);
  /* if its a modelica:// link then make it absolute path */
  if (fileUrl.scheme().toLower().compare("modelica") == 0) {
    mFileName = pOMCProxy->uriToFilename(mOriginalFileName);
  } else if (fileInfo.isRelative()) {
    mFileName = QString(classFileInfo.absoluteDir().absolutePath()).append("/").append(mOriginalFileName);
  } else if (fileInfo.isAbsolute()) {
    mFileName = mOriginalFileName;
  } else {
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
  Returns a dynamic value or null if no dynamic value exists
  */
QVariant ShapeAnnotation::getDynamicValue(QString name)
{
  QVariant dynamicValue; // isNull() per default
  if (mpParentComponent) {
    ModelWidget *pModelWidget = mpParentComponent->getGraphicsView()->getModelWidget();
    if (!pModelWidget->getResultFileName().isEmpty()) {
      QString fullName = pModelWidget->getResultFileName() + "." + mpParentComponent->getComponentInfo()->getName() + "." + name;
      MainWindow *pMainWindow = MainWindow::instance();
      VariablesTreeModel *pVariablesTreeModel = pMainWindow->getVariablesWidget()->getVariablesTreeModel();
      VariablesTreeItem *pVariablesTreeItem = pVariablesTreeModel->findVariablesTreeItem(fullName, pVariablesTreeModel->getRootVariablesTreeItem());
      if (pVariablesTreeItem != NULL) {
        dynamicValue = pVariablesTreeItem->getValue(pVariablesTreeItem->getPreviousUnit(), pVariablesTreeItem->getUnit());
      }
    }
  }
  return dynamicValue;
}

/*!
 * \brief ShapeAnnotation::applyRotation
 * Applies the rotation on the shape and sets the shape transformation matrix accordingly.
 * \param angle - the rotation angle to apply.
 * \sa rotateClockwise() and rotateAntiClockwise()
 */
void ShapeAnnotation::applyRotation(qreal angle)
{
  if (angle == 360) {
    angle = 0;
  }
  QString oldAnnotation = getOMCShapeAnnotation();
  setRotationAngle(angle);
  QString newAnnotation = getOMCShapeAnnotation();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, newAnnotation));
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
    if (mPoints.size() <= 2) {
      break;
    }
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
  /* Only set the ItemIsMovable & ItemSendsGeometryChanges flags on shape if the class is not a system library class
   * AND shape is not an inherited shape.
   * AND shape is not a OMS connector i.e., input/output signals of fmu.
   */
  if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() && !isInheritedShape()
      && !(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS
           && (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getOMSConnector()
               || mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getOMSBusConnector()
               || mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getOMSTLMBusConnector()))) {
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
 * \brief ShapeAnnotation::initUpdateVisible
 * Initialize optional DynamicSelect for the visible status
 */
void ShapeAnnotation::initUpdateVisible()
{
  if (mpParentComponent) {
    if (!mDynamicVisible.isEmpty()) {
      updateVisible();
      connect(mpParentComponent, SIGNAL(displayTextChanged()), SLOT(updateVisible()), Qt::UniqueConnection);
    }
  }
}

/*!
 * \brief ShapeAnnotation::updateVisible
 * DynamicSelect for the visible status
 */
void ShapeAnnotation::updateVisible()
{
  bool visible = mVisible; // model provided default value
  if (!mDynamicVisible.isEmpty()) {
    QVariant dynamicValue = getDynamicValue(mDynamicVisible);
    if (!dynamicValue.isNull()) {
      visible = dynamicValue.toBool();
    }
  }
  setVisible(visible);
}

/*!
 * \brief ShapeAnnotation::manhattanizeShape
 * Slot activated when mpManhattanizeShapeAction triggered signal is raised.\n
 * Finds the curved lines in the Line shape and makes in manhattanize/right-angle line.
 * \param addToStack
 */
void ShapeAnnotation::manhattanizeShape(bool addToStack)
{
  if (mSmooth == StringHandler::SmoothBezier) {
    return;
  }
  QString oldAnnotation = getOMCShapeAnnotation();
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
    if (addToStack) {
      ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
      pModelWidget->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, getOMCShapeAnnotation()));
    }
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
      setVisible(true);
      mpParentComponent->shapeAdded();
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
      prepareGeometryChange();
      updateShape(pShapeAnnotation);
      setTransform(pShapeAnnotation->mTransformation.getTransformationMatrix());
      removeCornerItems();
      drawCornerItems();
      setCornerItemsActiveOrPassive();
      update();
    } else if (mpParentComponent) {
      prepareGeometryChange();
      updateShape(pShapeAnnotation);
      setPos(mOrigin);
      setRotation(mRotation);
      if (dynamic_cast<TextAnnotation*>(this)) {
        TextAnnotation *pTextAnnotation = dynamic_cast<TextAnnotation*>(this);
        pTextAnnotation->updateTextString();
      }
      update();
      mpParentComponent->shapeUpdated();
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
 * \brief ShapeAnnotation::deleteMe
 * Deletes the shape. Slot activated when Del key is pressed while the shape is selected.\n
 * Slot activated when Delete option is chosen from context menu of the shape.\n
 */
void ShapeAnnotation::deleteMe()
{
  // delete the shape
  LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(this);
  if (pLineAnnotation && pLineAnnotation->getLineType() == LineAnnotation::ConnectionType) {
    mpGraphicsView->deleteConnection(pLineAnnotation);
  } else if (pLineAnnotation && pLineAnnotation->getLineType() == LineAnnotation::TransitionType) {
    mpGraphicsView->deleteTransition(pLineAnnotation);
  } else if (pLineAnnotation && pLineAnnotation->getLineType() == LineAnnotation::InitialStateType) {
    mpGraphicsView->deleteInitialState(pLineAnnotation);
  } else {
    mpGraphicsView->deleteShape(this);
  }
}

/*!
 * \brief ShapeAnnotation::duplicate
 * Reimplemented by each child shape class to duplicate the shape.
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
 * \brief ShapeAnnotation::rotateClockwise
 * Rotates the shape clockwise.
 * \sa rotateAntiClockwise() and applyRotation()
 */
void ShapeAnnotation::rotateClockwise()
{
  qreal oldRotation = StringHandler::getNormalizedAngle(mTransformation.getRotateAngle());
  qreal rotateIncrement = -90;
  qreal angle = oldRotation + rotateIncrement;
  applyRotation(angle);
}

/*!
 * \brief ShapeAnnotation::rotateAntiClockwise
 * Rotates the shape anti clockwise.
 * \sa rotateClockwise() and applyRotation()
 */
void ShapeAnnotation::rotateAntiClockwise()
{
  qreal oldRotation = StringHandler::getNormalizedAngle(mTransformation.getRotateAngle());
  qreal rotateIncrement = 90;
  qreal angle = oldRotation + rotateIncrement;
  applyRotation(angle);
}

/*!
 * \brief ShapeAnnotation::moveUp
 * Slot that moves shape upwards depending on the grid step size value
 * \sa moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveUp()
{
  QString oldAnnotation = getOMCShapeAnnotation();
  mTransformation.adjustPosition(0, mpGraphicsView->mCoOrdinateSystem.getVerticalGridStep());
  setTransform(mTransformation.getTransformationMatrix());
  setOrigin(mTransformation.getPosition());
  QString newAnnotation = getOMCShapeAnnotation();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, newAnnotation));
}

/*!
 * \brief ShapeAnnotation::moveShiftUp
 * Slot that moves shape upwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveShiftUp()
{
  QString oldAnnotation = getOMCShapeAnnotation();
  mTransformation.adjustPosition(0, mpGraphicsView->mCoOrdinateSystem.getVerticalGridStep() * 5);
  setTransform(mTransformation.getTransformationMatrix());
  setOrigin(mTransformation.getPosition());
  QString newAnnotation = getOMCShapeAnnotation();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, newAnnotation));
}

/*!
 * \brief ShapeAnnotation::moveCtrlUp
 * Slot that moves shape one pixel upwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveCtrlUp()
{
  QString oldAnnotation = getOMCShapeAnnotation();
  mTransformation.adjustPosition(0, 1);
  setTransform(mTransformation.getTransformationMatrix());
  setOrigin(mTransformation.getPosition());
  QString newAnnotation = getOMCShapeAnnotation();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, newAnnotation));
}

/*!
 * \brief ShapeAnnotation::moveDown
 * Slot that moves shape downwards depending on the grid step size value
 * \sa moveUp(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveDown()
{
  QString oldAnnotation = getOMCShapeAnnotation();
  mTransformation.adjustPosition(0, -mpGraphicsView->mCoOrdinateSystem.getVerticalGridStep());
  setTransform(mTransformation.getTransformationMatrix());
  setOrigin(mTransformation.getPosition());
  QString newAnnotation = getOMCShapeAnnotation();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, newAnnotation));
}

/*!
 * \brief ShapeAnnotation::moveShiftDown
 * Slot that moves shape downwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveShiftDown()
{
  QString oldAnnotation = getOMCShapeAnnotation();
  mTransformation.adjustPosition(0, -(mpGraphicsView->mCoOrdinateSystem.getVerticalGridStep() * 5));
  setTransform(mTransformation.getTransformationMatrix());
  setOrigin(mTransformation.getPosition());
  QString newAnnotation = getOMCShapeAnnotation();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, newAnnotation));
}

/*!
 * \brief ShapeAnnotation::moveCtrlDown
 * Slot that moves shape one pixel downwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveCtrlDown()
{
  QString oldAnnotation = getOMCShapeAnnotation();
  mTransformation.adjustPosition(0, -1);
  setTransform(mTransformation.getTransformationMatrix());
  setOrigin(mTransformation.getPosition());
  QString newAnnotation = getOMCShapeAnnotation();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, newAnnotation));
}

/*!
 * \brief ShapeAnnotation::moveLeft
 * Slot that moves shape leftwards depending on the grid step size
 * \sa moveUp(), moveDown(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveLeft()
{
  QString oldAnnotation = getOMCShapeAnnotation();
  mTransformation.adjustPosition(-mpGraphicsView->mCoOrdinateSystem.getHorizontalGridStep(), 0);
  setTransform(mTransformation.getTransformationMatrix());
  setOrigin(mTransformation.getPosition());
  QString newAnnotation = getOMCShapeAnnotation();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, newAnnotation));
}

/*!
 * \brief ShapeAnnotation::moveShiftLeft
 * Slot that moves shape leftwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveShiftLeft()
{
  QString oldAnnotation = getOMCShapeAnnotation();
  mTransformation.adjustPosition(-(mpGraphicsView->mCoOrdinateSystem.getHorizontalGridStep() * 5), 0);
  setTransform(mTransformation.getTransformationMatrix());
  setOrigin(mTransformation.getPosition());
  QString newAnnotation = getOMCShapeAnnotation();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, newAnnotation));
}

/*!
 * \brief ShapeAnnotation::moveCtrlLeft
 * Slot that moves shape one pixel leftwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(),
 * moveCtrlDown() and moveCtrlRight()
 */
void ShapeAnnotation::moveCtrlLeft()
{
  QString oldAnnotation = getOMCShapeAnnotation();
  mTransformation.adjustPosition(-1, 0);
  setTransform(mTransformation.getTransformationMatrix());
  setOrigin(mTransformation.getPosition());
  QString newAnnotation = getOMCShapeAnnotation();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, newAnnotation));
}

/*!
 * \brief ShapeAnnotation::moveRight
 * Slot that moves shape rightwards depending on the grid step size
 * \sa moveUp(), moveDown(), moveLeft(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveRight()
{
  QString oldAnnotation = getOMCShapeAnnotation();
  mTransformation.adjustPosition(mpGraphicsView->mCoOrdinateSystem.getHorizontalGridStep(), 0);
  setTransform(mTransformation.getTransformationMatrix());
  setOrigin(mTransformation.getPosition());
  QString newAnnotation = getOMCShapeAnnotation();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, newAnnotation));
}

/*!
 * \brief ShapeAnnotation::moveShiftRight
 * Slot that moves shape rightwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveShiftRight()
{
  QString oldAnnotation = getOMCShapeAnnotation();
  mTransformation.adjustPosition(mpGraphicsView->mCoOrdinateSystem.getHorizontalGridStep() * 5, 0);
  setTransform(mTransformation.getTransformationMatrix());
  setOrigin(mTransformation.getPosition());
  QString newAnnotation = getOMCShapeAnnotation();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, newAnnotation));
}

/*!
 * \brief ShapeAnnotation::moveCtrlRight
 * Slot that moves shape one pixel rightwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(),
 * moveCtrlDown() and moveCtrlLeft()
 */
void ShapeAnnotation::moveCtrlRight()
{
  QString oldAnnotation = getOMCShapeAnnotation();
  mTransformation.adjustPosition(1, 0);
  setTransform(mTransformation.getTransformationMatrix());
  setOrigin(mTransformation.getPosition());
  QString newAnnotation = getOMCShapeAnnotation();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, newAnnotation));
}

/*!
 * \brief ShapeAnnotation::cornerItemPressed
 * Slot activated when CornerItem around the shape is pressed. Sets the flag that CornerItem is pressed.
 */
void ShapeAnnotation::cornerItemPressed()
{
  mIsCornerItemClicked = true;
  setSelected(false);
}

/*!
 * \brief ShapeAnnotation::cornerItemReleased
 * Slot activated when CornerItem around the shape is release. Unsets the flag that CornerItem is pressed.
 */
void ShapeAnnotation::cornerItemReleased()
{
  mIsCornerItemClicked = false;
  if (isSelected()) {
    setCornerItemsActiveOrPassive();
  } else {
    setSelected(true);
  }
}

/*!
 * \brief ShapeAnnotation::updateCornerItemPoint
 * Slot activated when CornerItem around the shape is moved. Sends the new position values for the associated shape point.
 * \param index - the index of the CornerItem
 * \param point - the new CornerItem position
 */
void ShapeAnnotation::updateCornerItemPoint(int index, QPointF point)
{
  prepareGeometryChange();
  if (dynamic_cast<LineAnnotation*>(this)) {
    LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(this);
    if (pLineAnnotation->getLineType() == LineAnnotation::ConnectionType) {
      if (mPoints.size() > index) {
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
        if (mGeometries.size() > index - 1 && mGeometries[index - 1] == ShapeAnnotation::HorizontalLine && mPoints.size() > index - 1) {
          mPoints[index - 1] = QPointF(mPoints[index - 1].x(), mPoints[index - 1].y() +  dy);
          updateCornerItem(index - 1);
        } else if (mGeometries.size() > index - 1 && mGeometries[index - 1] == ShapeAnnotation::VerticalLine && mPoints.size() > index - 1) {
          mPoints[index - 1] = QPointF(mPoints[index - 1].x() + dx, mPoints[index - 1].y());
          updateCornerItem(index - 1);
        }
        // update next point
        if (mGeometries.size() > index && mGeometries[index] == ShapeAnnotation::HorizontalLine && mPoints.size() > index + 1) {
          mPoints[index + 1] = QPointF(mPoints[index + 1].x(), mPoints[index + 1].y() +  dy);
          updateCornerItem(index + 1);
        } else if (mGeometries.size() > index && mGeometries[index] == ShapeAnnotation::VerticalLine && mPoints.size() > index + 1) {
          mPoints[index + 1] = QPointF(mPoints[index + 1].x() + dx, mPoints[index + 1].y());
          updateCornerItem(index + 1);
        }
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
 * \brief ShapeAnnotation::showShapeProperties
 * Slot activated when Properties option is chosen from context menu of the shape.
 */
void ShapeAnnotation::showShapeProperties()
{
  if (!mpGraphicsView || mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::CompositeModel) {
    return;
  }
  MainWindow *pMainWindow = MainWindow::instance();
  ShapePropertiesDialog *pShapePropertiesDialog = new ShapePropertiesDialog(this, pMainWindow);
  pShapePropertiesDialog->exec();
}

/*!
 * \brief ShapeAnnotation::showShapeAttributes
 * Slot activated when Attributes option is chosen from context menu of the shape.
 */
void ShapeAnnotation::showShapeAttributes()
{
  if (!mpGraphicsView) {
    return;
  }
  LineAnnotation *pConnectionLineAnnotation = dynamic_cast<LineAnnotation*>(this);
  CompositeModelConnectionAttributes *pCompositeModelConnectionAttributes;
  pCompositeModelConnectionAttributes = new CompositeModelConnectionAttributes(mpGraphicsView, pConnectionLineAnnotation, true, MainWindow::instance());
  pCompositeModelConnectionAttributes->exec();
}

/*!
 * \brief ShapeAnnotation::editTransition
 * Slot activated when edit transition option is chosen from context menu of the transition.
 */
void ShapeAnnotation::editTransition()
{
  if (!mpGraphicsView) {
    return;
  }
  LineAnnotation *pTransitionLineAnnotation = dynamic_cast<LineAnnotation*>(this);
  CreateOrEditTransitionDialog *pCreateOrEditTransitionDialog = new CreateOrEditTransitionDialog(mpGraphicsView, pTransitionLineAnnotation,
                                                                                                 true, MainWindow::instance());
  pCreateOrEditTransitionDialog->exec();
}

/*!
 * \brief ShapeAnnotation::alignInterfaces
 * Slot activated when Align Interfaces option is chosen from context menu of the shape.
 */
void ShapeAnnotation::alignInterfaces()
{
  if (!mpGraphicsView) {
    return;
  }
  LineAnnotation *pConnectionLineAnnotation = dynamic_cast<LineAnnotation*>(this);
  AlignInterfacesDialog *pAlignInterfacesDialog = new AlignInterfacesDialog(mpGraphicsView->getModelWidget(), pConnectionLineAnnotation);
  pAlignInterfacesDialog->exec();
}

/*!
 * \brief ShapeAnnotation::contextMenuEvent
 * Reimplementation of contextMenuEvent.\n
 * Creates a context menu for the shape.\n
 * No context menu for the shapes that are part of Component.
 * \param pEvent - pointer to QGraphicsSceneContextMenuEvent
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
  if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::CompositeModel) {
    menu.addAction(mpShapeAttributesAction);

    //Only show align interfaces action for bidirectional connections
    LineAnnotation *pConnectionLineAnnotation = dynamic_cast<LineAnnotation*>(this);
    QString startName = pConnectionLineAnnotation->getStartComponentName();
    QString endName = pConnectionLineAnnotation->getEndComponentName();
    CompositeModelEditor *pEditor = dynamic_cast<CompositeModelEditor*>(mpGraphicsView->getModelWidget()->getEditor());
    if(pEditor->getInterfaceCausality(startName) == StringHandler::getTLMCausality(StringHandler::TLMBidirectional) &&
       pEditor->getInterfaceCausality(endName) == StringHandler::getTLMCausality(StringHandler::TLMBidirectional)) {
        menu.addSeparator();
        menu.addAction(mpAlignInterfacesAction);
    }

    menu.addSeparator();
    menu.addAction(mpGraphicsView->getDeleteAction());
  } else if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::Modelica) {
    menu.addAction(mpShapePropertiesAction);
    menu.addSeparator();
    if (isInheritedShape()) {
      mpGraphicsView->getManhattanizeAction()->setDisabled(true);
      mpGraphicsView->getDeleteAction()->setDisabled(true);
      mpGraphicsView->getDuplicateAction()->setDisabled(true);
      mpGraphicsView->getBringToFrontAction()->setDisabled(true);
      mpGraphicsView->getBringForwardAction()->setDisabled(true);
      mpGraphicsView->getSendToBackAction()->setDisabled(true);
      mpGraphicsView->getSendBackwardAction()->setDisabled(true);
      mpGraphicsView->getRotateClockwiseAction()->setDisabled(true);
      mpGraphicsView->getRotateAntiClockwiseAction()->setDisabled(true);
    }
    LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(this);
    LineAnnotation::LineType lineType = LineAnnotation::ShapeType;
    if (pLineAnnotation) {
      lineType = pLineAnnotation->getLineType();
      if (lineType != LineAnnotation::ConnectionType && lineType != LineAnnotation::TransitionType) {
        menu.addAction(mpGraphicsView->getManhattanizeAction());
      }
    }
    menu.addAction(mpGraphicsView->getDeleteAction());
    if (lineType != LineAnnotation::ConnectionType && lineType != LineAnnotation::TransitionType) {
      menu.addAction(mpGraphicsView->getDuplicateAction());
      menu.addSeparator();
      menu.addAction(mpGraphicsView->getBringToFrontAction());
      menu.addAction(mpGraphicsView->getBringForwardAction());
      menu.addAction(mpGraphicsView->getSendToBackAction());
      menu.addAction(mpGraphicsView->getSendBackwardAction());
      menu.addSeparator();
      menu.addAction(mpGraphicsView->getRotateClockwiseAction());
      menu.addAction(mpGraphicsView->getRotateAntiClockwiseAction());
    } else if (lineType == LineAnnotation::TransitionType) {
      menu.addSeparator();
      menu.addAction(mpEditTransitionAction);
    }
  } else if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType()== LibraryTreeItem::OMS) {
    BitmapAnnotation *pBitmapAnnotation = dynamic_cast<BitmapAnnotation*>(this);
    if (pBitmapAnnotation && mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getOMSElement()) {
      menu.addAction(MainWindow::instance()->getAddOrEditIconAction());
      menu.addAction(MainWindow::instance()->getDeleteIconAction());
    } else {
      return;
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
      setCornerItemsActiveOrPassive();
      setCursor(Qt::SizeAllCursor);
      /* Only allow manipulations on shapes if the class is not a system library class OR shape is not an inherited component. */
      if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() && !isInheritedShape()) {
        if (pLineAnnotation) {
          connect(mpGraphicsView, SIGNAL(mouseManhattanize()), this, SLOT(manhattanizeShape()), Qt::UniqueConnection);
        }
        connect(mpGraphicsView, SIGNAL(mouseDelete()), this, SLOT(deleteMe()), Qt::UniqueConnection);
        connect(mpGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()), Qt::UniqueConnection);
        if (lineType == LineAnnotation::ShapeType) {
          connect(mpGraphicsView, SIGNAL(mouseDuplicate()), this, SLOT(duplicate()), Qt::UniqueConnection);
          connect(mpGraphicsView->getBringToFrontAction(), SIGNAL(triggered()), this, SLOT(bringToFront()), Qt::UniqueConnection);
          connect(mpGraphicsView->getBringForwardAction(), SIGNAL(triggered()), this, SLOT(bringForward()), Qt::UniqueConnection);
          connect(mpGraphicsView->getSendToBackAction(), SIGNAL(triggered()), this, SLOT(sendToBack()), Qt::UniqueConnection);
          connect(mpGraphicsView->getSendBackwardAction(), SIGNAL(triggered()), this, SLOT(sendBackward()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(mouseRotateClockwise()), this, SLOT(rotateClockwise()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(mouseRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressDuplicate()), this, SLOT(duplicate()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), this, SLOT(rotateClockwise()), Qt::UniqueConnection);
          connect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()), Qt::UniqueConnection);
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
        }
      }
    } else if (!mIsCornerItemClicked) {
      setCornerItemsActiveOrPassive();
      unsetCursor();
      /* Only allow manipulations on shapes if the class is not a system library class OR shape is not an inherited component. */
      if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() && !isInheritedShape()) {
        if (pLineAnnotation) {
          disconnect(mpGraphicsView, SIGNAL(mouseManhattanize()), this, SLOT(manhattanizeShape()));
        }
        disconnect(mpGraphicsView, SIGNAL(mouseDelete()), this, SLOT(deleteMe()));
        disconnect(mpGraphicsView, SIGNAL(keyPressDelete()), this, SLOT(deleteMe()));
        if (lineType == LineAnnotation::ShapeType) {
          disconnect(mpGraphicsView, SIGNAL(mouseDuplicate()), this, SLOT(duplicate()));
          disconnect(mpGraphicsView->getBringToFrontAction(), SIGNAL(triggered()), this, SLOT(bringToFront()));
          disconnect(mpGraphicsView->getBringForwardAction(), SIGNAL(triggered()), this, SLOT(bringForward()));
          disconnect(mpGraphicsView->getSendToBackAction(), SIGNAL(triggered()), this, SLOT(sendToBack()));
          disconnect(mpGraphicsView->getSendBackwardAction(), SIGNAL(triggered()), this, SLOT(sendBackward()));
          disconnect(mpGraphicsView, SIGNAL(mouseRotateClockwise()), this, SLOT(rotateClockwise()));
          disconnect(mpGraphicsView, SIGNAL(mouseRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()));
          disconnect(mpGraphicsView, SIGNAL(keyPressDuplicate()), this, SLOT(duplicate()));
          disconnect(mpGraphicsView, SIGNAL(keyPressRotateClockwise()), this, SLOT(rotateClockwise()));
          disconnect(mpGraphicsView, SIGNAL(keyPressRotateAntiClockwise()), this, SLOT(rotateAntiClockwise()));
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
