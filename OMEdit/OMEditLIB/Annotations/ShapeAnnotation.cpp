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
#include "Element/ElementProperties.h"
#include "TLM/FetchInterfaceDataDialog.h"
#include "Plotting/VariablesWidget.h"
#include "Util/ResourceCache.h"


QString stripDynamicSelect(const QString &str)
{
  return str.startsWith("DynamicSelect") ?
    StringHandler::getStrings(str.mid(14)).at(0) : str;
}

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
  mVisible.parse(list.at(0));
  // 2nd item is the origin
  mOrigin.parse(list.at(1));
  // 3rd item is the rotation
  mRotation.parse(list.at(2));
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
  annotationString.append(mVisible.toQString());
  /* get origin */
  annotationString.append(mOrigin.toQString());
  /* get rotation */
  annotationString.append(mRotation.toQString());
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
  if (mVisible.isDynamicSelectExpression() || !mVisible) {
    annotationString.append(QString("visible=%1").arg(mVisible.toQString()));
  }
  /* get origin */
  if (mOrigin.isDynamicSelectExpression() || mOrigin != QPointF(0, 0)) {
    annotationString.append(QString("origin=%1").arg(mOrigin.toQString()));
  }
  /* get rotation */
  if (mRotation.isDynamicSelectExpression() || mRotation != 0) {
    annotationString.append(QString("rotation=%1").arg(mRotation.toQString()));
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
  if (list.size() < 8) {
    return;
  }
  // 4th item of the list is the line color
  mLineColor.parse(list.at(3));
  // 5th item of list contains the fill color.
  mFillColor.parse(list.at(4));
  // 6th item of list contains the Line Pattern.
  mLinePattern = StringHandler::getLinePatternType(stripDynamicSelect(list.at(5)));
  // 7th item of list contains the Fill Pattern.
  mFillPattern = StringHandler::getFillPatternType(stripDynamicSelect(list.at(6)));
  // 8th item of list contains the thickness.
  mLineThickness.parse(list.at(7));
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
  annotationString.append(mLineColor.toQString());
  /* get the fill color */
  annotationString.append(mFillColor.toQString());
  /* get the line pattern */
  annotationString.append(StringHandler::getLinePatternString(mLinePattern));
  /* get the fill pattern */
  annotationString.append(StringHandler::getFillPatternString(mFillPattern));
  // get the thickness
  annotationString.append(mLineThickness.toQString());
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
  if (mLineColor.isDynamicSelectExpression() || mLineColor != Qt::black) {
    annotationString.append(QString("lineColor=%1").arg(mLineColor.toQString()));
  }
  /* get the fill color */
  if (mFillColor.isDynamicSelectExpression() || mFillColor != Qt::black) {
    annotationString.append(QString("fillColor=%1").arg(mFillColor.toQString()));
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
  if (mLineThickness.isDynamicSelectExpression() || mLineThickness != 0.25) {
    annotationString.append(QString("lineThickness=%1").arg(mLineThickness.toQString()));
  }
  return annotationString;
}

/*!
 * \brief FilledShape::getTextShapeAnnotation
 * Returns the annotation values for Text shape.
 * \return the annotation values as a list.
 */
QStringList FilledShape::getTextShapeAnnotation()
{
  QStringList annotationString;
  /* get the text color */
  if (mLineColor.isDynamicSelectExpression() || mLineColor != Qt::black) {
    annotationString.append(QString("lineColor=%1").arg(mLineColor.toQString()));
  }
  return annotationString;
}

/*!
 * \class ShapeAnnotation
 * \brief The base class for all shapes LineAnnotation, PolygonAnnotation, RectangleAnnotation, EllipseAnnotation, TextAnnotation, BitmapAnnotation.
 */
/*!
 * \brief ShapeAnnotation::ShapeAnnotation
 * \param pShapeAnnotation
 * \param pParent
 */
ShapeAnnotation::ShapeAnnotation(ShapeAnnotation *pShapeAnnotation, QGraphicsItem *pParent)
  : QGraphicsItem(pParent)
{
  mpGraphicsView = 0;
  mpParentComponent = dynamic_cast<Element*>(pParent);
  //mTransformation = 0;
  mpReferenceShapeAnnotation = pShapeAnnotation;
  mIsInheritedShape = false;
  setOldScenePosition(QPointF(0, 0));
  mIsCornerItemClicked = false;
  mOldAnnotation = "";
  if (pShapeAnnotation) {
    connect(pShapeAnnotation, SIGNAL(added()), this, SLOT(referenceShapeAdded()));
    connect(pShapeAnnotation, SIGNAL(changed()), this, SLOT(referenceShapeChanged()));
    connect(pShapeAnnotation, SIGNAL(deleted()), this, SLOT(referenceShapeDeleted()));
  }
}

/*!
 * \brief ShapeAnnotation::ShapeAnnotation
 * \param inheritedShape
 * \param pGraphicsView - pointer to GraphicsView
 * \param pShapeAnnotation
 * \param pParent - pointer to QGraphicsItem
 */
ShapeAnnotation::ShapeAnnotation(bool inheritedShape, GraphicsView *pGraphicsView, ShapeAnnotation *pShapeAnnotation, QGraphicsItem *pParent)
  : QGraphicsItem(pParent)
{
  mpGraphicsView = pGraphicsView;
  mpParentComponent = 0;
  mTransformation = Transformation(StringHandler::Diagram);
  mpReferenceShapeAnnotation = pShapeAnnotation;
  mIsInheritedShape = inheritedShape;
  setOldScenePosition(QPointF(0, 0));
  mIsCornerItemClicked = false;
  mOldAnnotation = "";
  createActions();
  if (pShapeAnnotation) {
    connect(pShapeAnnotation, SIGNAL(added()), this, SLOT(referenceShapeAdded()));
    connect(pShapeAnnotation, SIGNAL(changed()), this, SLOT(referenceShapeChanged()));
    connect(pShapeAnnotation, SIGNAL(deleted()), this, SLOT(referenceShapeDeleted()));
  }
  connect(mpGraphicsView, SIGNAL(updateDynamicSelect(double)), this, SLOT(updateDynamicSelect(double)));
  connect(mpGraphicsView, SIGNAL(resetDynamicSelect()), this, SLOT(resetDynamicSelect()));
}

int ShapeAnnotation::maxTextLengthToShowOnLibraryIcon = 2;

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
  mPoints.clear();
  mGeometries.clear();
  mArrow.clear();
  mArrow.append(StringHandler::ArrowNone);
  mArrow.append(StringHandler::ArrowNone);
  mArrowSize = 3;
  mSmooth = StringHandler::SmoothNone;
  mExtents.clear();
  mExtents.append(QPointF(0, 0));
  mExtents.append(QPointF(0, 0));
  mBorderPattern = StringHandler::BorderNone;
  mRadius = 0;
  mStartAngle = 0;
  mEndAngle = 360;
  mClosure = StringHandler::ClosureChord;
  mTextString = "";
  mFontSize = 0;
  mFontName = Helper::systemFontInfo.family();
  mTextStyles.clear();
  mHorizontalAlignment = StringHandler::TextAlignmentCenter;
  mOriginalFileName = "";
  mFileName = "";
  mImageSource = "";
  mImage = ResourceCache::getImage(":/Resources/icons/bitmap-shape.svg");
  mTextExpression = FlatModelica::Expression();
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
  mClosure = pShapeAnnotation->mClosure;
  mTextString = pShapeAnnotation->mTextString;
  mFontSize = pShapeAnnotation->mFontSize;
  mFontName = pShapeAnnotation->mFontName;
  mTextStyles = pShapeAnnotation->mTextStyles;
  mHorizontalAlignment = pShapeAnnotation->mHorizontalAlignment;
  mOriginalFileName = pShapeAnnotation->mOriginalFileName;
  mFileName = pShapeAnnotation->mFileName;
  mClassFileName = pShapeAnnotation->mClassFileName;
  mImageSource = pShapeAnnotation->mImageSource;
  mImage = pShapeAnnotation->mImage;
  mTextExpression = pShapeAnnotation->mTextExpression;
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
  mpAlignInterfacesAction = new QAction(ResourceCache::getIcon(":/Resources/icons/align-interfaces.svg"), Helper::alignInterfaces, mpGraphicsView);
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
  return QRectF(p1, p2);
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
  // Make the display of Library Browser icons sharper. Very low line thickness is hardly visible on high resolution.
  if (mLineThickness < 1.0 && ((mpGraphicsView && mpGraphicsView->useSharpLibraryPixmap())
                               || (mpParentComponent && mpParentComponent->getGraphicsView()->useSharpLibraryPixmap()))) {
    thickness = Utilities::convertMMToPixel(1.0);
  }

  QPen pen(QBrush(mLineColor), thickness, StringHandler::getLinePatternType(mLinePattern), Qt::SquareCap, Qt::MiterJoin);
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
   * If thickness is greater than 4 then don't make the pen cosmetic since cosmetic pens don't change the width with respect to zoom.
   * Use non cosmetic pens for Libraries Browser and shapes inside component when thickness is greater than 4.
   */
  if (thickness > 4
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
      painter->setBackground(QBrush(mFillColor));
      QBrush brush(mLineColor, StringHandler::getFillPatternType(mFillPattern));
      brush.setTransform(QTransform(1, 0, 0, 0, 1, 0, 0, 0, 0));
      painter->setBrush(brush);
      break;
  }
}

QList<QPointF> ShapeAnnotation::getExtentsForInheritedShapeFromIconDiagramMap(GraphicsView *pGraphicsView, ShapeAnnotation *pReferenceShapeAnnotation)
{
  QPointF defaultPoint1 = QPointF(pGraphicsView->mMergedCoOrdinateSystem.getLeft(), pGraphicsView->mMergedCoOrdinateSystem.getBottom());
  QPointF defaultPoint2 = QPointF(pGraphicsView->mMergedCoOrdinateSystem.getRight(), pGraphicsView->mMergedCoOrdinateSystem.getTop());
  QPointF point1 = defaultPoint1;
  QPointF point2 = defaultPoint2;

  int index = pGraphicsView->getModelWidget()->getInheritedClassesList().indexOf(pReferenceShapeAnnotation->getGraphicsView()->getModelWidget()->getLibraryTreeItem()) + 1;
  if (index > 0) {
    QList<QPointF> extent;
    if (pGraphicsView->getViewType() == StringHandler::Icon) {
      extent = pGraphicsView->getModelWidget()->getInheritedClassIconMap().value(index).mExtent;
    } else {
      extent = pGraphicsView->getModelWidget()->getInheritedClassDiagramMap().value(index).mExtent;
    }
    point1 = extent.size() > 0 ? extent.at(0) : defaultPoint1;
    point2 = extent.size() > 1 ? extent.at(1) : defaultPoint2;
    // find the width and height
    qreal width = qFabs(point1.x() - point2.x());
    qreal height = qFabs(point1.y() - point2.y());
    if (width < 1 || height < 1) {
      point1 = defaultPoint1;
      point2 = defaultPoint2;
    } else {
      /* if preserveAspectRatio of the base class is true
       * Take x if width is lesser than height otherwise take y
       */
      if (pReferenceShapeAnnotation->getGraphicsView() && pReferenceShapeAnnotation->getGraphicsView()->mMergedCoOrdinateSystem.getPreserveAspectRatio()) {
        if (width < height) {
          point1.setY(point1.x());
          point2.setY(point2.x());
        } else {
          point1.setX(point1.y());
          point2.setX(point2.y());
        }
      }
    }
  }
  return QList<QPointF>() << point1 << point2;
}

/*!
 * \brief ShapeAnnotation::applyTransformation
 * Applies the transformation by setting a transformation matrix.
 */
void ShapeAnnotation::applyTransformation()
{
  resetTransform();
  const bool state = flags().testFlag(QGraphicsItem::ItemSendsGeometryChanges);
  setFlag(QGraphicsItem::ItemSendsGeometryChanges, false);
  setPos(0, 0);
  setFlag(QGraphicsItem::ItemSendsGeometryChanges, state);

  mTransformation.setWidth(qFabs(mExtents.at(0).x() - mExtents.at(1).x()));
  mTransformation.setHeight(qFabs(mExtents.at(0).y() - mExtents.at(1).y()));
  mTransformation.setOrigin(mOrigin);
  mTransformation.setRotateAngle(mRotation);
  mTransformation.setExtent1(mExtents.at(0));
  mTransformation.setExtent2(mExtents.at(1));
  setTransform(mTransformation.getTransformationMatrix());

  QPointF origin = mOrigin;

  // Only apply the extends coordinate extents on the shapes and not on connection, transition etc.
  // Don't apply it also on shapes inside Element
  // if the extends have some new coordinate extents then use it to scale the shape
  LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(this);
  GraphicsView *pGraphicsView = mpGraphicsView ? mpGraphicsView : mpReferenceShapeAnnotation->getGraphicsView();
  if (!mpParentComponent && pGraphicsView
      && !(pLineAnnotation && pLineAnnotation->getLineType() != LineAnnotation::ShapeType)
      && mpReferenceShapeAnnotation && mpReferenceShapeAnnotation->getGraphicsView()) {
    QList<QPointF> extendsCoOrdinateExtents = getExtentsForInheritedShapeFromIconDiagramMap(pGraphicsView, mpReferenceShapeAnnotation);

    qreal left = pGraphicsView->mMergedCoOrdinateSystem.getLeft();
    qreal bottom = pGraphicsView->mMergedCoOrdinateSystem.getBottom();
    qreal right = pGraphicsView->mMergedCoOrdinateSystem.getRight();
    qreal top = pGraphicsView->mMergedCoOrdinateSystem.getTop();
    // map the origin to extends CoOrdinateSystem
    origin.setX(Utilities::mapToCoOrdinateSystem(mOrigin.x(), left, right, extendsCoOrdinateExtents.at(0).x(), extendsCoOrdinateExtents.at(1).x()));
    origin.setY(Utilities::mapToCoOrdinateSystem(mOrigin.y(), bottom, top, extendsCoOrdinateExtents.at(0).y(), extendsCoOrdinateExtents.at(1).y()));
    // scale the shape to new CoOrdinateSystem
    const qreal coOrdinateWidth = qFabs(left - right);
    const qreal extendsCoOrdinateWidth = qFabs(extendsCoOrdinateExtents.at(0).x() - extendsCoOrdinateExtents.at(1).x());
    const qreal sx = extendsCoOrdinateWidth / coOrdinateWidth;
    const qreal coOrdinateHeight = qFabs(bottom - top);
    const qreal extendsCoOrdinateHeight = qFabs(extendsCoOrdinateExtents.at(0).y() - extendsCoOrdinateExtents.at(1).y());
    const qreal sy = extendsCoOrdinateHeight / coOrdinateHeight;
    const QTransform scaledTransform = transform() * QTransform::fromScale(sx, sy);
    // map the position of shape to new CoOrdinateSystem
    const qreal x = Utilities::mapToCoOrdinateSystem(scenePos().x(), left, right, extendsCoOrdinateExtents.at(0).x(), extendsCoOrdinateExtents.at(1).x());
    const qreal y = Utilities::mapToCoOrdinateSystem(scenePos().y(), bottom, top, extendsCoOrdinateExtents.at(0).y(), extendsCoOrdinateExtents.at(1).y());
    QTransform finalTransform(scaledTransform.m11(), scaledTransform.m12(), scaledTransform.m13(),
                              scaledTransform.m21(), scaledTransform.m22(), scaledTransform.m23(),
                              x, y);
    setTransform(finalTransform);
  }
  updateCornerItems();
  setOriginItemPos(origin);
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
    for (int i = 0 ; i < mPoints.size() ; i++) {
      QPointF point = mPoints.at(i);
      CornerItem *pCornerItem = new CornerItem(point.x(), point.y(), i, this);
      mCornerItemsList.append(pCornerItem);
    }
  } else {
    QPointF extent1 = QPointF(qMin(mExtents.at(0).x(), mExtents.at(1).x()), qMin(mExtents.at(0).y(), mExtents.at(1).y()));
    QPointF extent2 = QPointF(qMax(mExtents.at(0).x(), mExtents.at(1).x()), qMax(mExtents.at(0).y(), mExtents.at(1).y()));
    mCornerItemsList.append(new CornerItem(extent1.x(), extent1.y(), 0, this));
    mCornerItemsList.append(new CornerItem(extent2.x(), extent2.y(), 1, this));
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
  if (mpOriginItem) {
    if (isSelected()) {
      mpOriginItem->setActive();
    } else {
      mpOriginItem->setPassive();
    }
  }
}

/*!
 * \brief ShapeAnnotation::updateCornerItems
 */
void ShapeAnnotation::updateCornerItems()
{
  if (dynamic_cast<LineAnnotation*>(this) || dynamic_cast<PolygonAnnotation*>(this)) {
    for (int i = 0 ; i < mCornerItemsList.size() ; i++) {
      if (mPoints.size() > i) {
        mCornerItemsList.at(i)->setPos(QPointF(mPoints.at(i).x(), mPoints.at(i).y()));
      }
    }
  } else {
    if (mExtents.size() > 1) {
      QPointF extent1 = QPointF(qMin(mExtents.at(0).x(), mExtents.at(1).x()), qMin(mExtents.at(0).y(), mExtents.at(1).y()));
      QPointF extent2 = QPointF(qMax(mExtents.at(0).x(), mExtents.at(1).x()), qMax(mExtents.at(0).y(), mExtents.at(1).y()));
      if (mCornerItemsList.size() > 1) {
        mCornerItemsList.at(0)->setPos(QPointF(extent1.x(), extent1.y()));
        mCornerItemsList.at(1)->setPos(QPointF(extent2.x(), extent2.y()));
      }
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
void ShapeAnnotation::replaceExtent(const int index, const QPointF point)
{
  if (mExtents.size() > 1 && index >= 0 && index <= 1) {
    prepareGeometryChange();
    mExtents.replace(index, point);
  }
}

/*!
 * \brief ShapeAnnotation::updateExtent
 * Updates the extent point.
 * \param index
 * \param point
 */
void ShapeAnnotation::updateExtent(const int index, const QPointF point)
{
  if (mExtents.size() > 1 && index >= 0 && index <= 1) {
    prepareGeometryChange();
    mExtents.replace(index, point);
  }
  applyTransformation();
}

void ShapeAnnotation::setOriginItemPos(const QPointF point)
{
  if (mpOriginItem) {
    mpOriginItem->setPos(point);
  }
}

/*!
  Sets the text string.
  \return textString - the string to set.
  */
void ShapeAnnotation::setTextString(QString textString)
{
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
    points.append(point - mOrigin);
  }
  mPoints = points;
}

/*!
  Adjusts the extents according to the origin.
  */
void ShapeAnnotation::adjustExtentsWithOrigin()
{
  QList<QPointF> extents;
  for (auto &extent: mExtents) {
    extents.append(extent - mOrigin);
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
    if (dynamic_cast<LineAnnotation*>(this) || dynamic_cast<PolygonAnnotation*>(this)) {
      pCornerItem->setPos(mPoints.at(index));
    } else {
      pCornerItem->setPos(mExtents.at(index));
    }
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
 * \brief ShapeAnnotation::moveShape
 * Moves the shape by dx and dy distance.
 * \param dx
 * \param dy
 */
void ShapeAnnotation::moveShape(const qreal dx, const qreal dy)
{
  QString oldAnnotation = getOMCShapeAnnotation();
  mTransformation.adjustPosition(dx, dy);
  setOrigin(mTransformation.getOrigin());
  QString newAnnotation = getOMCShapeAnnotation();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, newAnnotation));
}

/*!
  Sets the shape flags.
  */
void ShapeAnnotation::setShapeFlags(bool enable)
{
  /* Only set the ItemIsMovable & ItemSendsGeometryChanges flags on shape if the class is not a system library class
   * AND not a visualization view.
   * AND shape is not an inherited shape.
   * AND shape is not a OMS connector i.e., input/output signals of fmu.
   */
  if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() && !mpGraphicsView->isVisualizationView() && !isInheritedShape()
      && !(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS
           && (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getOMSConnector()
               || mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getOMSBusConnector()
               || mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getOMSTLMBusConnector()))) {
    setFlag(QGraphicsItem::ItemIsMovable, enable);
    setFlag(QGraphicsItem::ItemSendsGeometryChanges, enable);
  }
  setFlag(QGraphicsItem::ItemIsSelectable, enable);
}

/*!
 * \brief ShapeAnnotation::updateDynamicSelect
 * Updates the shapes according to the DynamicSelect annotation.
 * \param time
 */
void ShapeAnnotation::updateDynamicSelect(double time)
{
  if ((mpGraphicsView && mpGraphicsView->isVisualizationView())
      || (mpParentComponent && mpParentComponent->getGraphicsView() && mpParentComponent->getGraphicsView()->isVisualizationView())) {
    bool updated = false;

    updated |= mVisible.update(time, mpParentComponent);
    updated |= mOrigin.update(time, mpParentComponent);
    updated |= mRotation.update(time, mpParentComponent);
    updated |= mLineColor.update(time, mpParentComponent);
    updated |= mFillColor.update(time, mpParentComponent);
    updated |= mLineThickness.update(time, mpParentComponent);
    updated |= mArrowSize.update(time, mpParentComponent);
    updated |= mExtents.update(time, mpParentComponent);
    updated |= mRadius.update(time, mpParentComponent);
    updated |= mStartAngle.update(time, mpParentComponent);
    updated |= mEndAngle.update(time, mpParentComponent);
    updated |= mFontSize.update(time, mpParentComponent);
    updated |= mTextString.update(time, mpParentComponent);

    if (updated) {
      update();
    }
  }
}

/*!
 * \brief ShapeAnnotation::resetDynamicSelect
 * Resets the DynamicSelect back to static.
 */
void ShapeAnnotation::resetDynamicSelect()
{
  mVisible.resetDynamicToStatic();
  mOrigin.resetDynamicToStatic();
  mRotation.resetDynamicToStatic();
  mLineColor.resetDynamicToStatic();
  mFillColor.resetDynamicToStatic();
  mLineThickness.resetDynamicToStatic();
  mArrowSize.resetDynamicToStatic();
  mExtents.resetDynamicToStatic();
  mRadius.resetDynamicToStatic();
  mStartAngle.resetDynamicToStatic();
  mEndAngle.resetDynamicToStatic();
  mFontSize.resetDynamicToStatic();
  mTextString.resetDynamicToStatic();

  update();
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
      if (pModelWidget->getLibraryTreeItem()->getLibraryType() != LibraryTreeItem::OMS) {
        pModelWidget->getUndoStack()->push(new UpdateShapeCommand(this, oldAnnotation, getOMCShapeAnnotation()));
      }
    }
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
      mpGraphicsView->addItem(mpOriginItem);
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
      removeCornerItems();
      drawCornerItems();
      setCornerItemsActiveOrPassive();
      applyTransformation();
      update();
      mpGraphicsView->getModelWidget()->getLibraryTreeItem()->handleIconUpdated();
    } else if (mpParentComponent) {
      prepareGeometryChange();
      updateShape(pShapeAnnotation);
      applyTransformation();
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
      mpGraphicsView->removeItem(mpOriginItem);
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
  moveShape(0, mpGraphicsView->mMergedCoOrdinateSystem.getVerticalGridStep());
}

/*!
 * \brief ShapeAnnotation::moveShiftUp
 * Slot that moves shape upwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveShiftUp()
{
  moveShape(0, mpGraphicsView->mMergedCoOrdinateSystem.getVerticalGridStep() * 5);
}

/*!
 * \brief ShapeAnnotation::moveCtrlUp
 * Slot that moves shape one pixel upwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveCtrlUp()
{
  moveShape(0, 1);
}

/*!
 * \brief ShapeAnnotation::moveDown
 * Slot that moves shape downwards depending on the grid step size value
 * \sa moveUp(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveDown()
{
  moveShape(0, -mpGraphicsView->mMergedCoOrdinateSystem.getVerticalGridStep());
}

/*!
 * \brief ShapeAnnotation::moveShiftDown
 * Slot that moves shape downwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveShiftDown()
{
  moveShape(0, -(mpGraphicsView->mMergedCoOrdinateSystem.getVerticalGridStep() * 5));
}

/*!
 * \brief ShapeAnnotation::moveCtrlDown
 * Slot that moves shape one pixel downwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveCtrlDown()
{
  moveShape(0, -1);
}

/*!
 * \brief ShapeAnnotation::moveLeft
 * Slot that moves shape leftwards depending on the grid step size
 * \sa moveUp(), moveDown(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveLeft()
{
  moveShape(-mpGraphicsView->mMergedCoOrdinateSystem.getHorizontalGridStep(), 0);
}

/*!
 * \brief ShapeAnnotation::moveShiftLeft
 * Slot that moves shape leftwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveShiftLeft()
{
  moveShape(-(mpGraphicsView->mMergedCoOrdinateSystem.getHorizontalGridStep() * 5), 0);
}

/*!
 * \brief ShapeAnnotation::moveCtrlLeft
 * Slot that moves shape one pixel leftwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(),
 * moveCtrlDown() and moveCtrlRight()
 */
void ShapeAnnotation::moveCtrlLeft()
{
  moveShape(-1, 0);
}

/*!
 * \brief ShapeAnnotation::moveRight
 * Slot that moves shape rightwards depending on the grid step size
 * \sa moveUp(), moveDown(), moveLeft(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveRight()
{
  moveShape(mpGraphicsView->mMergedCoOrdinateSystem.getHorizontalGridStep(), 0);
}

/*!
 * \brief ShapeAnnotation::moveShiftRight
 * Slot that moves shape rightwards depending on the grid step size value multiplied by 5
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveCtrlUp(), moveCtrlDown(),
 * moveCtrlLeft() and moveCtrlRight()
 */
void ShapeAnnotation::moveShiftRight()
{
  moveShape(mpGraphicsView->mMergedCoOrdinateSystem.getHorizontalGridStep() * 5, 0);
}

/*!
 * \brief ShapeAnnotation::moveCtrlRight
 * Slot that moves shape one pixel rightwards
 * \sa moveUp(), moveDown(), moveLeft(), moveRight(), moveShiftUp(), moveShiftDown(), moveShiftLeft(), moveShiftRight(), moveCtrlUp(),
 * moveCtrlDown() and moveCtrlLeft()
 */
void ShapeAnnotation::moveCtrlRight()
{
  moveShape(1, 0);
}

/*!
 * \brief ShapeAnnotation::cornerItemPressed
 * Slot activated when CornerItem around the shape is pressed. Sets the flag that CornerItem is pressed.
 */
void ShapeAnnotation::cornerItemPressed(const int index)
{
  mIsCornerItemClicked = true;
  mOldAnnotation = getOMCShapeAnnotation();
  setSelected(false);

  mTransform = transform();
  mSceneBoundingRect = sceneBoundingRect().normalized();
  mOldOrigin = mOrigin;
  mOldExtents = mExtents;

  CornerItem *pClickedCornerItem = getCornerItem(index);
  int otherIndex = index == 0 ? 1 : 0;
  CornerItem *pOtherCornerItem = getCornerItem(otherIndex);
  assert(pClickedCornerItem);
  assert(pOtherCornerItem);

  mTransformationStartPosition = pClickedCornerItem->scenePos();
  mPivotPoint = pOtherCornerItem->scenePos();
}

/*!
 * \brief ShapeAnnotation::cornerItemReleased
 * Slot activated when CornerItem around the shape is release.
 * \param changed
 */
void ShapeAnnotation::cornerItemReleased(const bool changed)
{
  if (!mOldAnnotation.isEmpty()) {
    if (changed) {
      ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
      LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(this);

      if (pModelWidget->getLibraryTreeItem()->getLibraryType() == LibraryTreeItem::OMS) {
        if (pLineAnnotation) {
          pLineAnnotation->updateOMSConnection();
          pModelWidget->createOMSimulatorUndoCommand(QString("Update OMS Connection connect(%1, %2)").arg(pLineAnnotation->getStartComponentName(), pLineAnnotation->getEndComponentName()));
          pModelWidget->updateModelText();
          return;
        }
      } else {
        if (pLineAnnotation && pLineAnnotation->getLineType() == LineAnnotation::ConnectionType) {
          manhattanizeShape(false);
          removeRedundantPointsGeometriesAndCornerItems();
          // Call getOMCShapeAnnotation() after manhattanizeShape() and removeRedundantPointsGeometriesAndCornerItems() to get a correct new annotation
          QString newAnnotation = getOMCShapeAnnotation();
          pModelWidget->getUndoStack()->push(new UpdateConnectionCommand(pLineAnnotation, mOldAnnotation, newAnnotation));
        } else if (pLineAnnotation && pLineAnnotation->getLineType() == LineAnnotation::TransitionType) {
          manhattanizeShape(false);
          removeRedundantPointsGeometriesAndCornerItems();
          QString newAnnotation = getOMCShapeAnnotation();
          pModelWidget->getUndoStack()->push(new UpdateTransitionCommand(pLineAnnotation, pLineAnnotation->getCondition(), pLineAnnotation->getImmediate(),
                                                                         pLineAnnotation->getReset(), pLineAnnotation->getSynchronize(), pLineAnnotation->getPriority(),
                                                                         mOldAnnotation, pLineAnnotation->getCondition(), pLineAnnotation->getImmediate(),
                                                                         pLineAnnotation->getReset(), pLineAnnotation->getSynchronize(), pLineAnnotation->getPriority(), newAnnotation));
        } else {
          QString newAnnotation = getOMCShapeAnnotation();
          pModelWidget->getUndoStack()->push(new UpdateShapeCommand(this, mOldAnnotation, newAnnotation));
          pModelWidget->updateClassAnnotationIfNeeded();
        }
        pModelWidget->updateModelText();
      }
    } else {
      parseShapeAnnotation(mOldAnnotation);
      applyTransformation();
    }
  }

  mIsCornerItemClicked = false;
  mOldAnnotation = "";
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
    point = mapFromScene(point);
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
        } else if (mGeometries.size() > index - 1 && mGeometries[index - 1] == ShapeAnnotation::VerticalLine && mPoints.size() > index - 1) {
          mPoints[index - 1] = QPointF(mPoints[index - 1].x() + dx, mPoints[index - 1].y());
        }
        // update next point
        if (mGeometries.size() > index && mGeometries[index] == ShapeAnnotation::HorizontalLine && mPoints.size() > index + 1) {
          mPoints[index + 1] = QPointF(mPoints[index + 1].x(), mPoints[index + 1].y() +  dy);
        } else if (mGeometries.size() > index && mGeometries[index] == ShapeAnnotation::VerticalLine && mPoints.size() > index + 1) {
          mPoints[index + 1] = QPointF(mPoints[index + 1].x() + dx, mPoints[index + 1].y());
        }
      }
    } else {
      mPoints.replace(index, point);
    }
    applyTransformation();
  } else if (dynamic_cast<PolygonAnnotation*>(this)) { /* if shape is the PolygonAnnotation then update the start and end point together */
    point = mapFromScene(point);
    mPoints.replace(index, point);
    /* if first point */
    if (index == 0) {
      mPoints.back() = point;
    } else if (index == mPoints.size() - 1) { /* if last point */
      mPoints.first() = point;
    }
    applyTransformation();
  } else {
    qreal xDistance; //X distance between the current position of the mouse and the starting position mouse
    qreal yDistance; //Y distance between the current position of the mouse and the starting position mouse
    // Calculates the X distance
    xDistance = point.x() - mTransformationStartPosition.x();
    // If the starting point is on the negative side of the X plane we do an inverse of the value
    if (mTransformationStartPosition.x() < mPivotPoint.x()) {
      xDistance = xDistance * -1;
    }
    // Calculates the Y distance
    yDistance = point.y() - mTransformationStartPosition.y();
    // If the starting point is on the negative side of the Y plane we do an inverse of the value
    if (mTransformationStartPosition.y() < mPivotPoint.y()) {
      yDistance = yDistance * -1;
    }
    // Calculate the factors by dividing the distances againts the original size of this container
    qreal xFactor;
    if (qFuzzyCompare(mSceneBoundingRect.width(), 0.0)) {
      xFactor = xDistance;
    } else {
      xFactor = xDistance / mSceneBoundingRect.width();
      xFactor = 1 + xFactor;
    }
    qreal yFactor;
    if (qFuzzyCompare(mSceneBoundingRect.height(), 0.0)) {
      yFactor = yDistance;
    } else {
      yFactor = yDistance / mSceneBoundingRect.height();
      yFactor = 1 + yFactor;
    }
    // Creates a temporaty transformation
    QTransform tmpTransform = QTransform().translate(mPivotPoint.x(), mPivotPoint.y())
                              .scale(xFactor, yFactor)
                              .translate(-mPivotPoint.x(), -mPivotPoint.y());
    setTransform(mTransform * tmpTransform);

    qreal sx, sy;
    qreal radAngle = mRotation * (M_PI / 180);
    if (transform().type() == QTransform::TxRotate) {
      sx = transform().m12() / (sin(radAngle));
      sy = -transform().m21() / (sin(radAngle));
    } else {
      sx = transform().m11() / (cos(radAngle));
      sy = transform().m22() / (cos(radAngle));
    }

    QRectF rect = QRectF(mOldExtents.at(0), mOldExtents.at(1));
    // Apply the horizontal flip
    if ((mOldExtents.at(1).x() < mOldExtents.at(0).x())) {
      sx = -sx;
    }
    // Apply the vertical flip
    if ((mOldExtents.at(1).y() < mOldExtents.at(0).y())/* || (transform().type() == QTransform::TxRotate && qFuzzyCompare(rect.height(), 0.0))*/) {
      sy = -sy;
    }

    // This is a special case to handle scaling back from zero width and height.
    // Not sure why this combination is needed and working.
    qreal angle = StringHandler::getNormalizedAngle(mRotation);
    if ((angle >= 180 && angle <= 270) && qFuzzyCompare(rect.width(), 0.0)) {
      sx = -sx;
    }
    if ((angle >= 90 && angle <= 180) && qFuzzyCompare(rect.height(), 0.0)) {
      sy = -sy;
    }

    // Use qRound. See issue #7545
    QPointF extent1, extent2;
    if (qFuzzyCompare(rect.width(), 0.0)) {
      if (index == 0) {
        extent1.setX(qRound(sx));
        extent2.setX(rect.right());
      } else {
        extent1.setX(rect.left());
        extent2.setX(qRound(sx));
      }
    } else {
      extent1.setX(qRound(sx * rect.left()));
      extent2.setX(qRound(sx * rect.right()));
    }

    if (qFuzzyCompare(rect.height(), 0.0)) {
      if (index == 0) {
        extent1.setY(qRound(sy));
        extent2.setY(rect.bottom());
      } else {
        extent1.setY(rect.top());
        extent2.setY(qRound(sy));
      }
    } else {
      extent1.setY(qRound(sy * rect.top()));
      extent2.setY(qRound(sy * rect.bottom()));
    }

    QList<QPointF> extents;
    extents.append(extent1);
    extents.append(extent2);
    prepareGeometryChange();
    setExtents(extents);

    /*! Formula to find new origin
     * If the center of resizing is (xc,yc) and you're resizing by a factor of rx in the x-direction and ry in the y-direction then,
     * (xnew,ynew) = (xc+rx(xold−xc),yc+ry(yold−yc))
     * https://math.stackexchange.com/questions/109122/how-do-i-calculate-the-new-x-y-coordinates-and-width-height-of-a-re-sized-group
     */
    QPointF origin;
    origin.setX(mPivotPoint.x() + xFactor * (mOldOrigin.x() - mPivotPoint.x()));
    origin.setY(mPivotPoint.y() + yFactor * (mOldOrigin.y() - mPivotPoint.y()));
    setOrigin(mpGraphicsView->roundPoint(origin));

    setOriginItemPos(mOrigin);
    applyTransformation();
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
  CreateOrEditTransitionDialog *pCreateOrEditTransitionDialog = new CreateOrEditTransitionDialog(mpGraphicsView, pTransitionLineAnnotation, true, MainWindow::instance());
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
      /* Only allow manipulations on shapes if the class is not a system library class OR not a visualization view OR shape is not an inherited component. */
      if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() && !mpGraphicsView->isVisualizationView() && !isInheritedShape()) {
        if (pLineAnnotation) {
          connect(mpGraphicsView, SIGNAL(manhattanize()), this, SLOT(manhattanizeShape()), Qt::UniqueConnection);
        }
        connect(mpGraphicsView, SIGNAL(deleteSignal()), this, SLOT(deleteMe()), Qt::UniqueConnection);
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
      /* Only allow manipulations on shapes if the class is not a system library class OR not a visualization view OR shape is not an inherited component. */
      if (!mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() && !mpGraphicsView->isVisualizationView() && !isInheritedShape()) {
        if (pLineAnnotation) {
          disconnect(mpGraphicsView, SIGNAL(manhattanize()), this, SLOT(manhattanizeShape()));
        }
        disconnect(mpGraphicsView, SIGNAL(deleteSignal()), this, SLOT(deleteMe()));
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
    // move by grid distance while dragging shape
    QPointF positionDifference = mpGraphicsView->movePointByGrid(value.toPointF() - pos(), mTransformation.getOrigin() + pos(), true);
    return pos() + positionDifference;
  }
  return value;
}
