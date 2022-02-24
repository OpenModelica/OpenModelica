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
  : ShapeAnnotation(false, pGraphicsView, 0, 0)
{
  mpComponent = 0;
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

TextAnnotation::TextAnnotation(ShapeAnnotation *pShapeAnnotation, Element *pParent)
  : ShapeAnnotation(pShapeAnnotation, pParent), mpComponent(pParent)
{
  mpOriginItem = 0;
  updateShape(pShapeAnnotation);
  initUpdateTextString();
  applyTransformation();
}

TextAnnotation::TextAnnotation(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(true, pGraphicsView, pShapeAnnotation, 0)
{
  mpComponent = 0;
  mpOriginItem = new OriginItem(this);
  mpOriginItem->setPassive();
  updateShape(pShapeAnnotation);
  setShapeFlags(true);
  mpGraphicsView->addItem(this);
  mpGraphicsView->addItem(mpOriginItem);
}

TextAnnotation::TextAnnotation(Element *pParent)
  : ShapeAnnotation(0, pParent), mpComponent(pParent)
{
  mpOriginItem = 0;
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // give a reasonable size to default component text
  mExtents.replace(0, QPointF(-100, -50));
  mExtents.replace(1, QPointF(100, 50));
  setTextString("%name");
  initUpdateTextString();
  setPos(mOrigin);
  setRotation(mRotation);
}

TextAnnotation::TextAnnotation(QString annotation, LineAnnotation *pLineAnnotation)
  : ShapeAnnotation(0, pLineAnnotation)
{
  mpComponent = 0;
  mpOriginItem = 0;
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
  : ShapeAnnotation(true, pGraphicsView, 0, 0)
{
  mpComponent = 0;
  mpOriginItem = 0;
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
  if (list.size() < 15) {
    return;
  }
  // 9th item of the list contains the extent points
  mExtents.parse(list.at(8));
  // 10th item of the list contains the textString.
  mTextString.parse(list.at(9));
  initUpdateTextString();

  // 11th item of the list contains the fontSize.
  mFontSize.parse(list.at(10));
  // 12th item of the list contains the optional textColor, {-1, -1, -1} if not set
  if (!list.at(11).contains("-1")) {
    mLineColor.parse(list.at(11));
  }
  // 13th item of the list contains the font name.
  QString fontName = StringHandler::removeFirstLastQuotes(stripDynamicSelect(list.at(12)));
  if (!fontName.isEmpty()) {
    mFontName = fontName;
  }
  // 14th item of the list contains the text styles.
  QStringList textStyles = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(stripDynamicSelect(list.at(13))));
  foreach (QString textStyle, textStyles) {
    if (textStyle == "TextStyle.Bold") {
      mTextStyles.append(StringHandler::TextStyleBold);
    } else if (textStyle == "TextStyle.Italic") {
      mTextStyles.append(StringHandler::TextStyleItalic);
    } else if (textStyle == "TextStyle.UnderLine") {
      mTextStyles.append(StringHandler::TextStyleUnderLine);
    }
  }
  // 15th item of the list contains the text alignment.
  QString horizontalAlignment = StringHandler::removeFirstLastQuotes(stripDynamicSelect(list.at(14)));
  if (horizontalAlignment == "TextAlignment.Left") {
    mHorizontalAlignment = StringHandler::TextAlignmentLeft;
  } else if (horizontalAlignment == "TextAlignment.Center") {
    mHorizontalAlignment = StringHandler::TextAlignmentCenter;
  } else if (horizontalAlignment == "TextAlignment.Right") {
    mHorizontalAlignment = StringHandler::TextAlignmentRight;
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
  //! @note We don't show text annotation that contains % for Library Icons or if it is too long.
  if (mpGraphicsView && mpGraphicsView->isRenderingLibraryPixmap()) {
    if (mTextString.contains("%") || mTextString.length() > maxTextLengthToShowOnLibraryIcon) {
      return;
    }
  } else if (mpComponent && mpComponent->getGraphicsView()->isRenderingLibraryPixmap()) {
    return;
  }
  if (mVisible) {
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
    drawTextAnnotation(painter);
  }
}

/*!
 * \brief TextAnnotation::drawTextAnnotation
 * Draws the Text annotation
 * \param painter
 */
void TextAnnotation::drawTextAnnotation(QPainter *painter)
{
  applyLinePattern(painter);
  /* Don't apply the fill patterns on Text shapes. */
  /*applyFillPattern(painter);*/
  // store the existing transformations
  const QTransform painterTransform = painter->transform();
  const qreal scaleX = painterTransform.m11();
  const qreal scaleY = painterTransform.m22();
  const qreal shearX = painterTransform.m21();
  const qreal shearY = painterTransform.m12();
  // set new transformation for the text based on rotation or scale.
  qreal sx, sy;
  if (painterTransform.type() == QTransform::TxRotate) {
    // if no flip or XY flip
    if ((shearX >= 0 && shearY >= 0) || (shearX < 0 && shearY < 0)) {
      painter->setTransform(QTransform(painterTransform.m11(), (shearY < 0 ? -1.0 : 1.0), painterTransform.m13(),
                                       (shearX >= 0 ? -1.0 : 1.0), painterTransform.m22(), painterTransform.m23(),
                                       painterTransform.m31(), painterTransform.m32(), painterTransform.m33()));
      sx = shearX * (shearX < 0 ? -1.0 : 1.0);
      sy = shearY * (shearY >= 0 ? -1.0 : 1.0);
    } else { // if x or y flip
      painter->setTransform(QTransform(painterTransform.m11(), (shearY < 0 ? 1.0 : -1.0), painterTransform.m13(),
                                       (shearX >= 0 ? -1.0 : 1.0), painterTransform.m22(), painterTransform.m23(),
                                       painterTransform.m31(), painterTransform.m32(), painterTransform.m33()));
      sx = shearX * (shearX < 0 ? 1.0 : -1.0);
      sy = shearY * (shearY >= 0 ? -1.0 : 1.0);
    }
  } else {
    painter->setTransform(QTransform(1.0, painterTransform.m12(), painterTransform.m13(),
                                     painterTransform.m21(), 1.0, painterTransform.m23(),
                                     painterTransform.m31(), painterTransform.m32(), painterTransform.m33()));
    sx = scaleX;
    sy = scaleY;
  }
  // map the existing bounding rect to new transformation
  QRectF mappedBoundingRect = QRectF(boundingRect().x() * sx, boundingRect().y() * sy, boundingRect().width() * sx, boundingRect().height() * sy);
  // map the existing bounding rect to new transformation but with positive width and height so that font metrics can work
  QRectF absMappedBoundingRect = QRectF(boundingRect().x() * sx, boundingRect().y() * sy, qAbs(boundingRect().width() * sx), qAbs(boundingRect().height() * sy));
  // normalize the text for drawing
  QString textString = StringHandler::removeFirstLastQuotes(mTextString);
  textString = StringHandler::unparse(QString("\"").append(mTextString).append("\""));
  // Don't create new QFont instead get a font from painter and set the values on it and set it back.
  QFont font = painter->font();
  font.setFamily(mFontName);
  if (mFontSize > 0) {
    font.setPointSizeF(mFontSize);
  }
  font.setWeight(StringHandler::getFontWeight(mTextStyles));
  font.setItalic(StringHandler::getFontItalic(mTextStyles));
  // set font underline
  if (StringHandler::getFontUnderline(mTextStyles)) {
    font.setUnderline(true);
  }
  painter->setFont(font);
  /* From Modelica specification version 3.5-dev
   * "The style attribute fontSize specifies the font size. If the fontSize attribute is 0 the text is scaled to fit its extent. Otherwise, the size specifies the absolute size."
   */
  // if absolute font size is defined and is greater than 0 then we don't need to calculate the font size.
  if (mFontSize <= 0) {
    QFontMetrics fontMetrics(painter->font());
    QRect fontBoundRect = fontMetrics.boundingRect(absMappedBoundingRect.toRect(), Qt::TextDontClip, textString);
    const qreal xFactor = absMappedBoundingRect.width() / fontBoundRect.width();
    const qreal yFactor = absMappedBoundingRect.height() / fontBoundRect.height();
    /* Ticket:4256
     * Text aspect when x1=x2 i.e, width is 0.
     * Use height.
     */
    const qreal factor = (absMappedBoundingRect.width() != 0 && xFactor < yFactor) ? xFactor : yFactor;
    qreal fontSizeFactor = font.pointSizeF() * factor;
    // Yes we don't go below Helper::minimumTextFontSize font pt.
    font.setPointSizeF(qMax(fontSizeFactor, Helper::minimumTextFontSize));
    painter->setFont(font);
  }
  /* Try to get the elided text if calculated font size <= Helper::minimumTextFontSize
   * OR if font size is absolute.
   */
  QString textToDraw = textString;
  if (absMappedBoundingRect.width() > 1 && ((mFontSize <= 0 && painter->font().pointSizeF() <= Helper::minimumTextFontSize) || mFontSize > 0)) {
    QFontMetrics fontMetrics(painter->font());
    textToDraw = fontMetrics.elidedText(textString, Qt::ElideRight, absMappedBoundingRect.width());
    // if we get "..." i.e., QChar(0x2026) as textToDraw then don't draw anything
    if (textToDraw.compare(QChar(0x2026)) == 0) {
      textToDraw = "";
    }
  }
  // draw the font
  if (mpComponent || mappedBoundingRect.width() != 0 || mappedBoundingRect.height() != 0) {
    painter->drawText(mappedBoundingRect, StringHandler::getTextAlignment(mHorizontalAlignment) | Qt::AlignVCenter | Qt::TextDontClip, textToDraw);
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
  annotationString.append(mExtents.toQString());
  // get the text string
  annotationString.append(mTextString.toQString());
  // get the font size
  annotationString.append(mFontSize.toQString());
  // get the text color
  annotationString.append(mLineColor.toQString());
  // get the font name
  if (!mFontName.isEmpty() && mFontName.compare(Helper::systemFontInfo.family()) != 0) {
    annotationString.append(QString("\"").append(mFontName).append("\""));
  } else {
    annotationString.append(QString("\"\""));
  }
  // get the font styles
  QString textStylesString;
  QStringList stylesList;
  textStylesString.append("{");
  for (int i = 0 ; i < mTextStyles.size() ; i++) {
    stylesList.append(StringHandler::getTextStyleString(mTextStyles[i]));
  }
  textStylesString.append(stylesList.join(","));
  textStylesString.append("}");
  annotationString.append(textStylesString);
  // get the font horizontal alignment
  annotationString.append(StringHandler::getTextAlignmentString(mHorizontalAlignment));
  return annotationString.join(",");
}

/*!
 * \brief TextAnnotation::getOMCShapeAnnotationWithShapeName
 * \return the shape annotation in format as returned by OMC wrapped in Text keyword.
 */
QString TextAnnotation::getOMCShapeAnnotationWithShapeName()
{
  return QString("Text(%1)").arg(getOMCShapeAnnotation());
}

/*!
 * \brief TextAnnotation::getShapeAnnotation
 * \return the shape annotation in Modelica syntax.
 */
QString TextAnnotation::getShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getShapeAnnotation());
  annotationString.append(FilledShape::getTextShapeAnnotation());
  // get the extents
  if (mExtents.isDynamicSelectExpression() || mExtents.size() > 1) {
    annotationString.append(QString("extent=%1").arg(mExtents.toQString()));
  }
  // get the text string
  annotationString.append(QString("textString=%1").arg(mTextString.toQString()));
  // get the font size
  if (mFontSize.isDynamicSelectExpression() || mFontSize != 0) {
    annotationString.append(QString("fontSize=%1").arg(mFontSize.toQString()));
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
    if (mTextString.contains("%")) {
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
    QString variable = regExp.cap(0).trimmed();
    if ((!variable.isEmpty()) && (variable.compare("%%") != 0) && (variable.compare("%name") != 0) && (variable.compare("%class") != 0)) {
      variable.remove("%");
      variable = StringHandler::removeFirstLastCurlBrackets(variable);
      if (!variable.isEmpty()) {
        QString textValue;
        /* Ticket:4204
         * If we have extend component then call Element::getParameterDisplayString from root component.
         */
        textValue = mpComponent->getRootParentComponent()->getParameterDisplayString(variable);
        if (!textValue.isEmpty()) {
          QString unit = mpComponent->getRootParentComponent()->getParameterModifierValue(variable, "unit");
          QString displayUnit = mpComponent->getRootParentComponent()->getParameterModifierValue(variable, "displayUnit");
          Element *pElement = mpComponent->getRootParentComponent()->getElementByName(variable);
          if (pElement) {
            if (displayUnit.isEmpty()) {
              displayUnit = pElement->getDerivedClassModifierValue("displayUnit");
            }
            if (unit.isEmpty()) {
              unit = pElement->getDerivedClassModifierValue("unit");
            }
            // if display unit is still empty then use unit
            if (displayUnit.isEmpty()) {
              displayUnit = unit;
            }
          }
          if (displayUnit.isEmpty() || unit.isEmpty()) {
            mTextString.replace(pos, regExp.matchedLength(), textValue);
            pos += textValue.length();
          } else {
            QString textValueWithDisplayUnit;
            OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
            OMCInterface::convertUnits_res convertUnit = pOMCProxy->convertUnits(unit, displayUnit);
            if (convertUnit.unitsCompatible) {
              qreal convertedValue = Utilities::convertUnit(textValue.toDouble(), convertUnit.offset, convertUnit.scaleFactor);
              textValue = StringHandler::number(convertedValue);
              displayUnit = Utilities::convertUnitToSymbol(displayUnit);
              textValueWithDisplayUnit = QString("%1 %2").arg(textValue, displayUnit);
            } else {
              unit = Utilities::convertUnitToSymbol(unit);
              textValueWithDisplayUnit = QString("%1 %2").arg(textValue, unit);
            }
            mTextString.replace(pos, regExp.matchedLength(), textValueWithDisplayUnit);
            pos += textValueWithDisplayUnit.length();
          }
        } else { /* if the value of %\\W* is empty then remove the % sign. */
          mTextString.replace(pos, 1, "");
        }
      } else { /* if there is just alone % then remove it. Because if you want to print % then use %%. */
        mTextString.replace(pos, 1, "");
      }
    } else if (variable.compare("%%") == 0) { /* if string is %% then just move over it. We replace it with % in TextAnnotation::updateTextString(). */
      pos += regExp.matchedLength();
    }
  }
}

/*!
 * \brief TextAnnotation::updateTextString
 * Updates the text to display.
 */
void TextAnnotation::updateTextString()
{
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
    if (mTextString.toLower().contains("%condition")) {
      if (!pLineAnnotation->getCondition().isEmpty()) {
        mTextString.replace(QRegExp("%condition"), pLineAnnotation->getCondition());
      }
      if (pLineAnnotation->getPriority() > 1) {
        mTextString.prepend(QString("%1: ").arg(pLineAnnotation->getPriority()));
      }
    }
  } else if (mpComponent) {
    mTextString.reset();

    if (!mTextString.contains("%")) {
      return;
    }
    if (mTextString.toLower().contains("%name")) {
      mTextString.replace(QRegExp("%name"), mpComponent->getName());
    }
    if (mTextString.toLower().contains("%class") && mpComponent->getLibraryTreeItem()) {
      mTextString.replace(QRegExp("%class"), mpComponent->getLibraryTreeItem()->getNameStructure());
    }
    if (!mTextString.contains("%")) {
      return;
    }
    /* handle variables now */
    updateTextStringHelper(QRegExp("(%%|%\\{?\\w+(\\.\\w+)*\\}?)"));
    /* call again with non-word characters so invalid % can be removed. */
    updateTextStringHelper(QRegExp("(%%|%\\{?\\W+(\\.\\W+)*\\}?)"));
    /* handle %% */
    if (mTextString.toLower().contains("%%")) {
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
  QPointF gridStep(mpGraphicsView->mMergedCoOrdinateSystem.getHorizontalGridStep() * 5,
                   mpGraphicsView->mMergedCoOrdinateSystem.getVerticalGridStep() * 5);
  pTextAnnotation->setOrigin(mOrigin + gridStep);
  pTextAnnotation->drawCornerItems();
  pTextAnnotation->setCornerItemsActiveOrPassive();
  pTextAnnotation->applyTransformation();
  pTextAnnotation->update();
  mpGraphicsView->getModelWidget()->getUndoStack()->push(new AddShapeCommand(pTextAnnotation));
  mpGraphicsView->getModelWidget()->getLibraryTreeItem()->emitShapeAdded(pTextAnnotation, mpGraphicsView);
  setSelected(false);
  pTextAnnotation->setSelected(true);
}
