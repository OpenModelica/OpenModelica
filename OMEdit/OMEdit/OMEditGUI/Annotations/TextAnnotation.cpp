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

#include "TextAnnotation.h"
#include "Modeling/Commands.h"

/*!
 * \class TextAnnotation
 * \brief Draws the text shapes.
 */
/*!
 * \brief TextAnnotation::TextAnnotation
 * \param annotation - text annotation string.
 * \param inheritedShape
 * \param pGraphicsView - pointer to GraphicsView
 */
TextAnnotation::TextAnnotation(QString annotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(false, pGraphicsView, 0)
{
  mpComponent = 0;
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation(annotation);
  setShapeFlags(true);
}

TextAnnotation::TextAnnotation(ShapeAnnotation *pShapeAnnotation, Component *pParent)
  : ShapeAnnotation(pParent), mpComponent(pParent)
{
  updateShape(pShapeAnnotation);
  initUpdateVisible(); // DynamicSelect for visible attribute
  initUpdateTextString();
  setPos(mOrigin);
  setRotation(mRotation);
  connect(pShapeAnnotation, SIGNAL(updateReferenceShapes()), pShapeAnnotation, SIGNAL(changed()));
  connect(pShapeAnnotation, SIGNAL(added()), this, SLOT(referenceShapeAdded()));
  connect(pShapeAnnotation, SIGNAL(changed()), this, SLOT(referenceShapeChanged()));
  connect(pShapeAnnotation, SIGNAL(deleted()), this, SLOT(referenceShapeDeleted()));
}

TextAnnotation::TextAnnotation(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(true, pGraphicsView, 0)
{
  mpComponent = 0;
  updateShape(pShapeAnnotation);
  setShapeFlags(true);
  mpGraphicsView->addItem(this);
  connect(pShapeAnnotation, SIGNAL(updateReferenceShapes()), pShapeAnnotation, SIGNAL(changed()));
  connect(pShapeAnnotation, SIGNAL(added()), this, SLOT(referenceShapeAdded()));
  connect(pShapeAnnotation, SIGNAL(changed()), this, SLOT(referenceShapeChanged()));
  connect(pShapeAnnotation, SIGNAL(deleted()), this, SLOT(referenceShapeDeleted()));
}

TextAnnotation::TextAnnotation(Component *pParent)
  : ShapeAnnotation(pParent), mpComponent(pParent)
{
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // give a reasonable size to default component text
  mExtents.replace(0, QPointF(-50, -50));
  mExtents.replace(1, QPointF(50, 50));
  setTextString("%name");
  initUpdateTextString();
  setPos(mOrigin);
  setRotation(mRotation);
}

TextAnnotation::TextAnnotation(QString annotation, LineAnnotation *pLineAnnotation)
  : ShapeAnnotation(pLineAnnotation)
{
  mpComponent = 0;
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  parseShapeAnnotation(annotation);
  updateTextString();
  /* From Modelica Spec 33revision1,
   * The extent of the Text is interpreted relative to either the first point of the Line, in the case of immediate=false,
   * or the last point (immediate=true).
   */
  if (pLineAnnotation->getPoints().size() > 0) {
    if (pLineAnnotation->getImmediate()) {
      setPos(pLineAnnotation->getPoints().last());
    } else {
      setPos(pLineAnnotation->getPoints().first());
    }
  }
}

/*!
 * \brief TextAnnotation::TextAnnotation
 * Used by OMSimulator FMU ModelWidget\n
 * We always make this shape as inherited shape since its not allowed to be modified.
 * \param pGraphicsView
 */
TextAnnotation::TextAnnotation(GraphicsView *pGraphicsView)
  : ShapeAnnotation(true, pGraphicsView, 0)
{
  mpComponent = 0;
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // give a reasonable size
  mExtents.replace(0, QPointF(-100, 20));
  mExtents.replace(1, QPointF(100, -20));
  setTextString("%name");
  initUpdateTextString();
  setPos(mOrigin);
  setRotation(mRotation);
  setShapeFlags(true);
}

/*!
 * \brief TextAnnotation::parseShapeAnnotation
 * Parses the text annotation string
 * \param annotation - text annotation string.
 */
void TextAnnotation::parseShapeAnnotation(QString annotation)
{
  GraphicItem::parseShapeAnnotation(annotation);
  FilledShape::parseShapeAnnotation(annotation);
  // parse the shape to get the list of attributes of Text.
  QStringList list = StringHandler::getStrings(annotation);
  if (list.size() < 11) {
    return;
  }
  // 9th item of the list contains the extent points
  QStringList extentsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(8)));
  for (int i = 0 ; i < qMin(extentsList.size(), 2) ; i++) {
    QStringList extentPoints = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(extentsList[i]));
    if (extentPoints.size() >= 2)
      mExtents.replace(i, QPointF(extentPoints.at(0).toFloat(), extentPoints.at(1).toFloat()));
  }
  // 10th item of the list contains the textString.
  if (list.at(9).startsWith("{")) {
    // DynamicSelect
    QStringList args = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(9)));
    if (args.count() > 0)
      mOriginalTextString = StringHandler::removeFirstLastQuotes(args.at(0));
    if (args.count() > 1)
      mDynamicTextString << args.at(1);  // variable name
    if (args.count() > 2)
      mDynamicTextString << args.at(2);  // significantDigits
  }
  else {
    mOriginalTextString = StringHandler::removeFirstLastQuotes(list.at(9));
  }
  mTextString = mOriginalTextString;
  initUpdateTextString();
  // 11th item of the list contains the fontSize.
  mFontSize = list.at(10).toFloat();
  //Now comes the optional parameters; fontName and textStyle.
  annotation = annotation.replace("{", "");
  annotation = annotation.replace("}", "");
  // parse the shape to get the list of attributes of Text Annotation.
  list = StringHandler::getStrings(annotation);
  int index = 19;
  mTextStyles.clear();
  while(index < list.size()) {
    QString annotationValue = StringHandler::removeFirstLastQuotes(list.at(index));
    // check textStyles enumeration.
    if(annotationValue == "TextStyle.Bold") {
      mTextStyles.append(StringHandler::TextStyleBold);
      index++;
    } else if(annotationValue == "TextStyle.Italic") {
      mTextStyles.append(StringHandler::TextStyleItalic);
      index++;
    } else if(annotationValue == "TextStyle.UnderLine") {
      mTextStyles.append(StringHandler::TextStyleUnderLine);
      index++;
    } else if(annotationValue == "TextAlignment.Left") {
      // check textAlignment enumeration.
      mHorizontalAlignment = StringHandler::TextAlignmentLeft;
      index++;
    } else if(annotationValue == "TextAlignment.Center") {
      mHorizontalAlignment = StringHandler::TextAlignmentCenter;
      index++;
    } else if(annotationValue == "TextAlignment.Right") {
      mHorizontalAlignment = StringHandler::TextAlignmentRight;
      index++;
    } else {
      mFontName = annotationValue;
      index++;
    }
  }
}

/*!
 * \brief TextAnnotation::boundingRect
 * Defines the bounding rectangle of the shape.
 * \return bounding rectangle
 */
QRectF TextAnnotation::boundingRect() const
{
  return shape().boundingRect();
}

/*!
 * \brief TextAnnotation::shape
 * Defines the shape path
 * \return shape path
 */
QPainterPath TextAnnotation::shape() const
{
  QPainterPath path;
  path.addRect(getBoundingRect());
  return path;
}

/*!
 * \brief TextAnnotation::paint
 * Reimplementation of QGraphicsItem::paint.
 * \param painter
 * \param option
 * \param widget
 */
void TextAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(option);
  Q_UNUSED(widget);
  //! @note We don't show text annotation that contains % for Library Icons. Only static text for functions are shown.
  if (mpGraphicsView && mpGraphicsView->isRenderingLibraryPixmap()) {
    if (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getRestriction() != StringHandler::Function) {
      return;
    }
    if (mOriginalTextString.contains("%")) {
      return;
    }
  } else if (mpComponent && mpComponent->getGraphicsView()->isRenderingLibraryPixmap()) {
    return;
  }
  if (mVisible || !mDynamicVisible.isEmpty()) {
    // state machine visualization
    // text annotation on a component
    if (mpComponent && mpComponent->getLibraryTreeItem() && mpComponent->getLibraryTreeItem()->isState()
        && mpComponent->getGraphicsView()->isVisualizationView()) {
      if (mpComponent->isActiveState()) {
        painter->setOpacity(1.0);
      } else {
        painter->setOpacity(0.2);
      }
    }
    // text annotation on a transition
    LineAnnotation *pTransitionLineAnnotation = dynamic_cast<LineAnnotation*>(parentItem());
    if (pTransitionLineAnnotation && pTransitionLineAnnotation->getLineType() == LineAnnotation::TransitionType
        && pTransitionLineAnnotation->getGraphicsView() && pTransitionLineAnnotation->getGraphicsView()->isVisualizationView()) {
      if (pTransitionLineAnnotation->isActiveState()) {
        painter->setOpacity(1.0);
      } else {
        painter->setOpacity(0.2);
      }
    }
    drawTextAnnotaion(painter);
  }
}

/*!
 * \brief TextAnnotation::drawTextAnnotaion
 * Draws the Text annotation
 * \param painter
 */
void TextAnnotation::drawTextAnnotaion(QPainter *painter)
{
  applyLinePattern(painter);
  /* Don't apply the fill patterns on Text shapes. */
  /*applyFillPattern(painter);*/
  qreal dx = ((-boundingRect().left()) - boundingRect().right());
  qreal dy = ((-boundingRect().top()) - boundingRect().bottom());
  // first we invert the painter since we have our coordinate system inverted.
  painter->scale(1.0, -1.0);
  painter->translate(0, dy);
  mTextString = StringHandler::removeFirstLastQuotes(mTextString);
  mTextString = StringHandler::unparse(QString("\"").append(mTextString).append("\""));
  QFont font;
  font = QFont(mFontName, mFontSize, StringHandler::getFontWeight(mTextStyles), StringHandler::getFontItalic(mTextStyles));
  // set font underline
  if (StringHandler::getFontUnderline(mTextStyles)) {
    font.setUnderline(true);
  }
  painter->setFont(font);
  QRect fontBoundRect = painter->fontMetrics().boundingRect(boundingRect().toRect(), Qt::TextDontClip, mTextString);
  bool calculateFontSize = true;
  if (mFontSize > 0) {
    if (boundingRect().width() != 0 && fontBoundRect.width() <= boundingRect().width()) {
      calculateFontSize = false;
    } else if (boundingRect().height() != 0 && fontBoundRect.height() <= boundingRect().height()) {
      calculateFontSize = false;
    }
  }
  if (calculateFontSize) {
    float xFactor = boundingRect().width() / fontBoundRect.width();
    float yFactor = boundingRect().height() / fontBoundRect.height();
    /* Ticket:4256
       * Text aspect when x1=x2 i.e, width is 0.
       * Use height.
       */
    float factor = (boundingRect().width() != 0 && xFactor < yFactor) ? xFactor : yFactor;
    QFont f = painter->font();
    qreal fontSizeFactor = f.pointSizeF()*factor;
    if ((fontSizeFactor < 12) && mpComponent) {
      f.setPointSizeF(12);
    } else if (fontSizeFactor <= 0) {
      f.setPointSizeF(1);
    } else {
      f.setPointSizeF(fontSizeFactor);
    }
    painter->setFont(f);
  }
  if (mpComponent) {
    Component *pComponent = mpComponent->getRootParentComponent();
    if (pComponent && pComponent->mTransformation.isValid()) {
      QPointF extent1 = pComponent->mTransformation.getExtent1();
      QPointF extent2 = pComponent->mTransformation.getExtent2();
      qreal componentAngle = StringHandler::getNormalizedAngle(pComponent->mTransformation.getRotateAngle());
      qreal shapeAngle = StringHandler::getNormalizedAngle(getRotation());
      // if shape has its own angle
      if (shapeAngle > 0) {
        shapeAngle = StringHandler::getNormalizedAngle(pComponent->mTransformation.getRotateAngle() + getRotation());
        if (shapeAngle == 180) {
          painter->scale(-1.0, -1.0);
          painter->translate(dx, dy);
        }
        if (extent2.x() < extent1.x()) {  // if vertical flip
          painter->scale(1.0, -1.0);
          painter->translate(0, dy);
        }
        if (extent2.y() < extent1.y()) {  // if horizontal flip
          painter->scale(-1.0, 1.0);
          painter->translate(dx, 0);
        }
      } else {
        if (componentAngle == 180) {
          painter->scale(-1.0, -1.0);
          painter->translate(dx, dy);
        }
        if (extent2.x() < extent1.x()) {  // if horizontal flip
          painter->scale(-1.0, 1.0);
          painter->translate(dx, 0);
        }
        if (extent2.y() < extent1.y()) {  // if vertical flip
          painter->scale(1.0, -1.0);
          painter->translate(0, dy);
        }
      }
    }
  } else {
    qreal angle = StringHandler::getNormalizedAngle(mTransformation.getRotateAngle());
    if (angle == 180) {
      painter->scale(-1.0, -1.0);
      painter->translate(((-boundingRect().left()) - boundingRect().right()), ((-boundingRect().top()) - boundingRect().bottom()));
    }
  }
  // draw the font
  if (mpComponent || boundingRect().width() > 0 || boundingRect().height() > 0) {
    painter->drawText(boundingRect(), StringHandler::getTextAlignment(mHorizontalAlignment) | Qt::AlignVCenter | Qt::TextDontClip, mTextString);
    mExportBoundingRect = painter->boundingRect(boundingRect(), StringHandler::getTextAlignment(mHorizontalAlignment) | Qt::AlignVCenter | Qt::TextDontClip, mTextString);
    if (mpComponent) {
      mExportBoundingRect = sceneTransform().mapRect(mExportBoundingRect);
    }
  }
}

/*!
 * \brief TextAnnotation::getOMCShapeAnnotation
 * \return the shape annotation in format as returned by OMC.
 */
QString TextAnnotation::getOMCShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getOMCShapeAnnotation());
  annotationString.append(FilledShape::getOMCShapeAnnotation());
  // get the extents
  QString extentString;
  extentString.append("{");
  extentString.append("{").append(QString::number(mExtents.at(0).x())).append(",");
  extentString.append(QString::number(mExtents.at(0).y())).append("},");
  extentString.append("{").append(QString::number(mExtents.at(1).x())).append(",");
  extentString.append(QString::number(mExtents.at(1).y())).append("}");
  extentString.append("}");
  annotationString.append(extentString);
  // get the text string
  annotationString.append(QString("\"").append(mOriginalTextString).append("\""));
  // get the font size
  annotationString.append(QString::number(mFontSize));
  // get the font name
  if (!mFontName.isEmpty()) {
    annotationString.append(QString("\"").append(mFontName).append("\""));
  }
  // get the font styles
  QString textStylesString;
  QStringList stylesList;
  if (mTextStyles.size() > 0) {
    textStylesString.append("{");
  }
  for (int i = 0 ; i < mTextStyles.size() ; i++) {
    stylesList.append(StringHandler::getTextStyleString(mTextStyles[i]));
  }
  if (mTextStyles.size() > 0) {
    textStylesString.append(stylesList.join(","));
    textStylesString.append("}");
    annotationString.append(textStylesString);
  }
  // get the font horizontal alignment
  annotationString.append(StringHandler::getTextAlignmentString(mHorizontalAlignment));
  return annotationString.join(",");
}

/*!
 * \brief TextAnnotation::getShapeAnnotation
 * \return the shape annotation in Modelica syntax.
 */
QString TextAnnotation::getShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getShapeAnnotation());
  annotationString.append(FilledShape::getShapeAnnotation());
  // get the extents
  if (mExtents.size() > 1) {
    QString extentString;
    extentString.append("extent={");
    extentString.append("{").append(QString::number(mExtents.at(0).x())).append(",");
    extentString.append(QString::number(mExtents.at(0).y())).append("},");
    extentString.append("{").append(QString::number(mExtents.at(1).x())).append(",");
    extentString.append(QString::number(mExtents.at(1).y())).append("}");
    extentString.append("}");
    annotationString.append(extentString);
  }
  // get the text string
  annotationString.append(QString("textString=\"").append(mOriginalTextString).append("\""));
  // get the font size
  if (mFontSize != 0) {
    annotationString.append(QString("fontSize=").append(QString::number(mFontSize)));
  }
  // get the font name
  /* Ticket:4204
   * Don't insert the default font name as it might be operating system specific.
   */
  if (!mFontName.isEmpty() && mFontName.compare(Helper::systemFontInfo.family()) != 0) {
    annotationString.append(QString("fontName=\"").append(mFontName).append("\""));
  }
  // get the font styles
  QString textStylesString;
  QStringList stylesList;
  if (mTextStyles.size() > 0) {
    textStylesString.append("textStyle={");
  }
  for (int i = 0 ; i < mTextStyles.size() ; i++) {
    stylesList.append(StringHandler::getTextStyleString(mTextStyles[i]));
  }
  if (mTextStyles.size() > 0) {
    textStylesString.append(stylesList.join(","));
    textStylesString.append("}");
    annotationString.append(textStylesString);
  }
  // get the font horizontal alignment
  if (mHorizontalAlignment != StringHandler::TextAlignmentCenter) {
    annotationString.append(QString("horizontalAlignment=").append(StringHandler::getTextAlignmentString(mHorizontalAlignment)));
  }
  return QString("Text(").append(annotationString.join(",")).append(")");
}

void TextAnnotation::updateShape(ShapeAnnotation *pShapeAnnotation)
{
  // set the default values
  GraphicItem::setDefaults(pShapeAnnotation);
  FilledShape::setDefaults(pShapeAnnotation);
  ShapeAnnotation::setDefaults(pShapeAnnotation);
}

void TextAnnotation::initUpdateTextString()
{
  if (mpComponent) {
    if (mOriginalTextString.contains("%") || mDynamicTextString.count() > 0) {
      updateTextString();
      connect(mpComponent, SIGNAL(displayTextChanged()), SLOT(updateTextString()), Qt::UniqueConnection);
    }
  }
}

/*!
 * \brief TextAnnotation::updateTextStringHelper
 * Helper function for TextAnnotation::updateTextString()
 * \param regExp
 */
void TextAnnotation::updateTextStringHelper(QRegExp regExp)
{
  int pos = 0;
  while ((pos = regExp.indexIn(mTextString, pos)) != -1) {
    QString variable = regExp.cap(0);
    if ((!variable.isEmpty()) && (variable.compare("%%") != 0) && (variable.compare("%name") != 0) && (variable.compare("%class") != 0)) {
      variable.remove("%");
      if (!variable.isEmpty()) {
        QString textValue;
        /* Ticket:4204
         * If we have extend component then call Component::getParameterDisplayString from root component.
         */
        if (mpComponent->getComponentType() == Component::Extend) {
          textValue = mpComponent->getRootParentComponent()->getParameterDisplayString(variable);
        } else {
          textValue = mpComponent->getRootParentComponent()->getParameterDisplayString(variable);
        }
        if (!textValue.isEmpty()) {
          mTextString.replace(pos, regExp.matchedLength(), textValue);
        } else { /* if the value of %\\W* is empty then remove the % sign. */
          mTextString.replace(pos, 1, "");
        }
      } else { /* if there is just alone % then remove it. Because if you want to print % then use %%. */
        mTextString.replace(pos, 1, "");
      }
    }
    pos += regExp.matchedLength();
  }
}

/*!
 * \brief TextAnnotation::updateTextString
 * Updates the text to display.
 */
void TextAnnotation::updateTextString()
{
  /* optional DynamicSelect of textString attribute */
  QVariant dynamicValue; // isNull() per default
  if (mDynamicTextString.count() > 0) {
    dynamicValue = getDynamicValue(mDynamicTextString.at(0).toString());
  }
  if (!dynamicValue.isNull()) {
    mTextString = dynamicValue.toString();
    if (mTextString.isEmpty()) {
      /* use variable name as default value if result not found */
      mTextString = mDynamicTextString.at(0).toString();
    }
    else if (mDynamicTextString.count() > 1) {
      int digits = mDynamicTextString.at(1).toInt();
      mTextString = QString::number(mTextString.toDouble(), 'g', digits);
    }
    return;
  }
  /* alternatively use model provided value */
  /* From Modelica Spec 32revision2,
   * There are a number of common macros that can be used in the text, and they should be replaced when displaying
   * the text as follows:
   * - %par replaced by the value of the parameter par. The intent is that the text is easily readable, thus if par is
   * of an enumeration type, replace %par by the item name, not by the full name.
   * [Example: if par="Modelica.Blocks.Types.Enumeration.Periodic", then %par should be displayed as "Periodic"]
   * - %% replaced by %
   * - %name replaced by the name of the component (i.e. the identifier for it in in the enclosing class).
   * - %class replaced by the name of the class.
   */
  LineAnnotation *pLineAnnotation = dynamic_cast<LineAnnotation*>(parentItem());
  if (pLineAnnotation) {
    if (mOriginalTextString.toLower().contains("%condition")) {
      if (!pLineAnnotation->getCondition().isEmpty()) {
        mTextString.replace(QRegExp("%condition"), pLineAnnotation->getCondition());
      }
      if (pLineAnnotation->getPriority() > 1) {
        mTextString.prepend(QString("%1: ").arg(pLineAnnotation->getPriority()));
      }
    }
  } else if (mpComponent) {
    mTextString = mOriginalTextString;
    if (!mTextString.contains("%")) {
      return;
    }
    if (mOriginalTextString.toLower().contains("%name")) {
      mTextString.replace(QRegExp("%name"), mpComponent->getName());
    }
    if (mOriginalTextString.toLower().contains("%class") && mpComponent->getLibraryTreeItem()) {
      mTextString.replace(QRegExp("%class"), mpComponent->getLibraryTreeItem()->getNameStructure());
    }
    if (!mTextString.contains("%")) {
      return;
    }
    /* handle variables now */
    updateTextStringHelper(QRegExp("(%%|%\\w*)"));
    /* call again with non-word characters so invalid % can be removed. */
    updateTextStringHelper(QRegExp("(%%|%\\W*)"));
    /* handle %% */
    if (mOriginalTextString.toLower().contains("%%")) {
      mTextString.replace(QRegExp("%%"), "%");
    }
  }
}

/*!
 * \brief TextAnnotation::duplicate
 * Duplicates the shape.
 */
void TextAnnotation::duplicate()
{
  TextAnnotation *pTextAnnotation = new TextAnnotation("", mpGraphicsView);
  pTextAnnotation->updateShape(this);
  QPointF gridStep(mpGraphicsView->mCoOrdinateSystem.getHorizontalGridStep() * 5,
                   mpGraphicsView->mCoOrdinateSystem.getVerticalGridStep() * 5);
  pTextAnnotation->setOrigin(mOrigin + gridStep);
  pTextAnnotation->initializeTransformation();
  pTextAnnotation->drawCornerItems();
  pTextAnnotation->setCornerItemsActiveOrPassive();
  pTextAnnotation->update();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new AddShapeCommand(pTextAnnotation));
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitShapeAdded(pTextAnnotation, mpGraphicsView);
  setSelected(false);
  pTextAnnotation->setSelected(true);
}
