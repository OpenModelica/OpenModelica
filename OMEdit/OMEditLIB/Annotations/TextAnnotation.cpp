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

#include <iostream>
#include "TextAnnotation.h"
#include "Modeling/Commands.h"
#include "Options/OptionsDialog.h"

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
  mpElement = 0;
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

TextAnnotation::TextAnnotation(ModelInstance::Text *pText, bool inherited, GraphicsView *pGraphicsView)
  : ShapeAnnotation(inherited, pGraphicsView, 0, 0)
{
  mpElement = 0;
  mpOriginItem = new OriginItem(this);
  mpOriginItem->setPassive();
  mpText = pText;
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation();
  setShapeFlags(true);
}

TextAnnotation::TextAnnotation(ShapeAnnotation *pShapeAnnotation, Element *pParent)
  : ShapeAnnotation(pShapeAnnotation, pParent), mpElement(pParent)
{
  mpOriginItem = 0;
  updateShape(pShapeAnnotation);
  initUpdateTextString();
  applyTransformation();
}

TextAnnotation::TextAnnotation(ModelInstance::Text *pText, Element *pParent)
  : ShapeAnnotation(pParent), mpElement(pParent)
{
  mpOriginItem = 0;
  mpText = pText;
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation();
  applyTransformation();
}

TextAnnotation::TextAnnotation(ShapeAnnotation *pShapeAnnotation, GraphicsView *pGraphicsView)
  : ShapeAnnotation(true, pGraphicsView, pShapeAnnotation, 0)
{
  mpElement = 0;
  mpOriginItem = new OriginItem(this);
  mpOriginItem->setPassive();
  updateShape(pShapeAnnotation);
  setShapeFlags(true);
  mpGraphicsView->addItem(this);
  mpGraphicsView->addItem(mpOriginItem);
}

TextAnnotation::TextAnnotation(Element *pParent)
  : ShapeAnnotation(0, pParent), mpElement(pParent)
{
  mpOriginItem = 0;
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // give a reasonable size to default element text
  mExtent.replace(0, QPointF(-100, -50));
  mExtent.replace(1, QPointF(100, 50));
  setTextString("%name");
  initUpdateTextString();
  setPos(mOrigin);
  setRotation(mRotation);
}

TextAnnotation::TextAnnotation(QString annotation, LineAnnotation *pLineAnnotation)
  : ShapeAnnotation(0, pLineAnnotation)
{
  mpElement = 0;
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
      setPos(pLineAnnotation->getPoints().at(mPoints.size() - 1));
    } else {
      setPos(pLineAnnotation->getPoints().at(0));
    }
  }
}

TextAnnotation::TextAnnotation(ModelInstance::Text *pText, LineAnnotation *pLineAnnotation)
  : ShapeAnnotation(pLineAnnotation)
{
  mpElement = 0;
  mpOriginItem = 0;
  mpText = pText;
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  parseShapeAnnotation();
  updateTextString();
  /* From Modelica Spec 33revision1,
   * The extent of the Text is interpreted relative to either the first point of the Line, in the case of immediate=false,
   * or the last point (immediate=true).
   */
  if (pLineAnnotation->getPoints().size() > 0) {
    if (pLineAnnotation->getImmediate()) {
      setPos(pLineAnnotation->getPoints().at(mPoints.size() - 1));
    } else {
      setPos(pLineAnnotation->getPoints().at(0));
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
  mpElement = 0;
  mpOriginItem = 0;
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // give a reasonable size
  mExtent.replace(0, QPointF(-100, 20));
  mExtent.replace(1, QPointF(100, -20));
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
  mExtent.parse(list.at(8));
  // 10th item of the list contains the textString.
  mTextString.parse(list.at(9));
  mOriginalTextString = mTextString;
  initUpdateTextString();

  // 11th item of the list contains the fontSize.
  mFontSize.parse(list.at(10));
  // 12th item of the list contains the optional textColor, {-1, -1, -1} if not set
  if (!list.at(11).contains("-1")) {
    mLineColor.parse(list.at(11));
  }
  // 13th item of the list contains the font name.
  const QString fontName = list.at(12);
  if (!StringHandler::removeFirstLastQuotes(fontName).isEmpty()) {
    mFontName.parse(fontName);
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

void TextAnnotation::parseShapeAnnotation()
{
  GraphicItem::parseShapeAnnotation(mpText);
  FilledShape::parseShapeAnnotation(mpText);

  mExtent = mpText->getExtent();
  mExtent.evaluate(mpText->getParentModel());
  mTextString = mpText->getTextString();
  mOriginalTextString = mTextString;
  initUpdateTextString();

  mFontSize = mpText->getFontSize();
  mFontSize.evaluate(mpText->getParentModel());
  if (mpText->getTextColor().isValid()) {
    mLineColor = mpText->getTextColor();
    mLineColor.evaluate(mpText->getParentModel());
  }
  if (!mpText->getFontName().isEmpty()) {
    mFontName = mpText->getFontName();
    mFontName.evaluate(mpText->getParentModel());
  }
  mTextStyles = mpText->getTextStyle();
  mTextStyles.evaluate(mpText->getParentModel());
  mHorizontalAlignment = mpText->getHorizontalAlignment();
  mHorizontalAlignment.evaluate(mpText->getParentModel());
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
    if (mOriginalTextString.contains("%") || mOriginalTextString.length() > OptionsDialog::instance()->getGeneralSettingsPage()->getLibraryIconTextLengthSpinBox()->value()) {
      return;
    }
  } else if (mpElement && mpElement->getGraphicsView()->isRenderingLibraryPixmap()) {
    return;
  }
  if (mVisible) {
    // state machine visualization
    // text annotation on a element
    if (mpElement && mpElement->getGraphicsView()->isVisualizationView()
        && ((mpElement->getGraphicsView()->getModelWidget()->isNewApi() && mpElement->getModel() && mpElement->getModel()->getAnnotation()->isState())
            || (mpElement->getLibraryTreeItem() && mpElement->getLibraryTreeItem()->isState()))) {
      if (mpElement->isActiveState()) {
        painter->setOpacity(1.0);
      } else {
        painter->setOpacity(0.2);
      }
    }
    // text annotation on a transition
    LineAnnotation *pTransitionLineAnnotation = dynamic_cast<LineAnnotation*>(parentItem());
    if (pTransitionLineAnnotation && pTransitionLineAnnotation->isTransition()
        && pTransitionLineAnnotation->getGraphicsView() && pTransitionLineAnnotation->getGraphicsView()->isVisualizationView()) {
      if (pTransitionLineAnnotation->isActiveState()) {
        painter->setOpacity(1.0);
      } else {
        painter->setOpacity(0.2);
      }
    }
    drawAnnotation(painter);
  }
}

/*!
 * \brief TextAnnotation::drawAnnotation
 * Draws the text.
 * \param painter
 */
void TextAnnotation::drawAnnotation(QPainter *painter)
{
  QPointF p1 = mExtent.size() > 0 ? mExtent.at(0) : QPointF(-100.0, -100.0);
  QPointF p2 = mExtent.size() > 1 ? mExtent.at(1) : QPointF(100.0, 100.0);
  bool startInv = p1.x() > p2.x();
  applyLinePattern(painter);
  /* Don't apply the fill patterns on Text shapes. */
  /*applyFillPattern(painter);*/
  // store the existing transformations
  const QTransform painterTransform = painter->transform();
  const qreal m11 = painterTransform.m11();
  const qreal m22 = painterTransform.m22();
  const qreal m12 = painterTransform.m12();
  const qreal m21 = painterTransform.m21();
  qreal xScale = qSqrt(m11*m11 + m12*m12);
  qreal yScale = qSqrt(m22*m22 + m21*m21);
  qreal curScale = qMin(xScale, yScale);
  // set new transformation for the text based on rotation or scale.
  qreal invx = (m11 >= 0) ? 1.0 : -1.0;
  qreal invy = (m22 >= 0) ? 1.0 : -1.0;
  if ((m11 == 0) && (m22 == 0))
  {
    invx = (m12 > 0) ? -1.0 : 1.0;
    invy = (m21 > 0) ? 1.0 : -1.0;

    if ((!startInv && (m12 > 0)) || (startInv && (m12 < 0)))
    {
      invx = -1.0 * invx;
      invy = -1.0 * invy;
    }
  }
  QTransform curTransform = QTransform(qAbs(painterTransform.m11()), invx * painterTransform.m12(), painterTransform.m13(),
                                  invy * painterTransform.m21(), qAbs(painterTransform.m22()), painterTransform.m23(),
                                  painterTransform.m31(), painterTransform.m32(), painterTransform.m33())
                            .scale(1/xScale, 1/yScale);
  painter->setTransform(curTransform);
  // map the existing bounding rect to new transformation
  QRectF boundingRectangle = boundingRect();
  qreal xtl = (invx >= 0) ? boundingRectangle.left() : -boundingRectangle.right();
  qreal ytl = (invy >= 0) ? boundingRectangle.top() : -boundingRectangle.bottom();
  QRectF mappedBoundingRect = QRectF(xtl * curScale, ytl * curScale, boundingRectangle.width() * curScale, boundingRectangle.height() * curScale);
  // normalize the text for drawing
  QString textString = StringHandler::removeFirstLastQuotes(mTextString);
  textString = StringHandler::unparse(QString("\"").append(mTextString).append("\""));
  // Don't create new QFont instead get a font from painter and set the values on it and set it back.
  QFont font = painter->font();
  font.setFamily(mFontName);
  if (mFontSize > 0) {
    font.setPointSizeF(mFontSize);
  }
  font.setWeight(mTextStyles.getWeight());
  font.setItalic(mTextStyles.isItalic());
  // set font underline
  font.setUnderline(mTextStyles.isUnderLine());
  painter->setFont(font);
  /* From Modelica specification version 3.5-dev
   * "The style attribute fontSize specifies the font size. If the fontSize attribute is 0 the text is scaled to fit its extent. Otherwise, the size specifies the absolute size."
   */
  // if absolute font size is defined and is greater than 0 then we don't need to calculate the font size.
  if (mFontSize <= 0) {
    QFontMetrics fontMetrics(painter->font());
    QRect fontBoundRect = fontMetrics.boundingRect(mappedBoundingRect.toRect(), Qt::TextDontClip, textString);
    const qreal xFactor = mappedBoundingRect.width() / fontBoundRect.width();
    const qreal yFactor = mappedBoundingRect.height() / fontBoundRect.height();
    /* Ticket:4256
     * Text aspect when x1=x2 i.e, width is 0.
     * Use height.
     */
    const qreal factor = (mappedBoundingRect.width() != 0 && xFactor < yFactor) ? xFactor : yFactor;
    qreal fontSizeFactor = font.pointSizeF() * factor;
    // Yes we don't go below Helper::minimumTextFontSize font pt.
    font.setPointSizeF(qMax(fontSizeFactor, Helper::minimumTextFontSize));
    painter->setFont(font);
  }
  /* Try to get the elided text if calculated font size <= Helper::minimumTextFontSize
   * OR if font size is absolute and text is not multiline.
   */
  QString textToDraw = textString;
  if (mappedBoundingRect.width() > 1 && ((mFontSize <= 0 && painter->font().pointSizeF() <= Helper::minimumTextFontSize) || (mFontSize > 0 && !Utilities::isMultiline(textString)))) {
    QFontMetrics fontMetrics(painter->font());
    textToDraw = fontMetrics.elidedText(textString, Qt::ElideRight, mappedBoundingRect.width());
    // if we get "..." i.e., QChar(0x2026) as textToDraw then don't draw anything
    if (textToDraw.compare(QChar(0x2026)) == 0) {
      textToDraw = "";
    }
  }
  Qt::Alignment alignment = StringHandler::getTextAlignment(mHorizontalAlignment);
  if ((invx < 0) ^ startInv)
  {
    if (alignment == Qt::AlignLeft)
      alignment = Qt::AlignRight;
    else if (alignment == Qt::AlignRight)
      alignment = Qt::AlignLeft;
  }
  // draw the font
  if (mpElement || mappedBoundingRect.width() != 0 || mappedBoundingRect.height() != 0) {
    painter->drawText(mappedBoundingRect, alignment | Qt::AlignVCenter | Qt::TextDontClip, textToDraw);
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
  annotationString.append(mExtent.toQString());
  // get the text string
  annotationString.append(mOriginalTextString.toQString());
  // get the font size
  annotationString.append(mFontSize.toQString());
  // get the text color
  annotationString.append(mLineColor.toQString());
  // font name
  annotationString.append(mFontName.toQString());
  // text style
  annotationString.append(mTextStyles.toQString());
  // horizontal alignment
  annotationString.append(mHorizontalAlignment.toQString());
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
  if (mExtent.isDynamicSelectExpression() || mExtent.size() > 1) {
    annotationString.append(QString("extent=%1").arg(mExtent.toQString()));
  }
  // get the text string
  annotationString.append(QString("textString=%1").arg(mOriginalTextString.toQString()));
  // get the font size
  if (mFontSize.isDynamicSelectExpression() || mFontSize.toQString().compare(QStringLiteral("0")) != 0) {
    annotationString.append(QString("fontSize=%1").arg(mFontSize.toQString()));
  }
  // get the font name
  /* Ticket:4204
   * Don't insert the default font name as it might be operating system specific.
   */
  if (mFontName.isDynamicSelectExpression() || (!mFontName.isEmpty() && StringHandler::removeFirstLastQuotes(mFontName.toQString()).compare(Helper::systemFontInfo.family()) != 0)) {
    annotationString.append(QString("fontName=%1").arg(mFontName.toQString()));
  }
  // get the font styles
  if (mTextStyles.size() > 0) {
    annotationString.append(QString("textStyle=%1").arg(mTextStyles.toQString()));
  }
  // get the font horizontal alignment
  if (mHorizontalAlignment.isDynamicSelectExpression() || mHorizontalAlignment.toQString().compare(QStringLiteral("TextAlignment.Center")) != 0) {
    annotationString.append(QString("horizontalAlignment=%1").arg(mHorizontalAlignment.toQString()));
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

ModelInstance::Extend *TextAnnotation::getExtend() const
{
  return mpText->getParentExtend();
}

void TextAnnotation::initUpdateTextString()
{
  if (mpElement) {
    if (mOriginalTextString.contains("%")) {
      updateTextString();
      connect(mpElement, SIGNAL(displayTextChanged()), SLOT(updateTextString()), Qt::UniqueConnection);
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
         * If we have extend element then call Element::getParameterDisplayString from root element.
         */
        textValue = mpElement->getRootParentElement()->getParameterDisplayString(variable);
        if (!textValue.isEmpty()) {
          QString unit = mpElement->getRootParentElement()->getParameterModifierValue(variable, "unit");
          QString displayUnit = mpElement->getRootParentElement()->getParameterModifierValue(variable, "displayUnit");
          if (MainWindow::instance()->isNewApi()) {
            ModelInstance::Component* pModelComponent = Element::getModelComponentByName(mpElement->getRootParentElement()->getModel(), variable);
            if (pModelComponent) {
              if (displayUnit.isEmpty()) {
                displayUnit = pModelComponent->getModifierValueFromType(QStringList() << "displayUnit");
              }
              if (unit.isEmpty()) {
                unit = pModelComponent->getModifierValueFromType(QStringList() << "unit");
              }
            }
          } else {
            Element *pElement = mpElement->getRootParentElement()->getElementByName(variable);
            if (pElement) {
              if (displayUnit.isEmpty()) {
                displayUnit = pElement->getDerivedClassModifierValue("displayUnit");
              }
              if (unit.isEmpty()) {
                unit = pElement->getDerivedClassModifierValue("unit");
              }
            }
          }
          // if display unit is still empty then use unit
          if (displayUnit.isEmpty()) {
            displayUnit = unit;
          }
          QString textValueWithDisplayUnit;
          // Do not show displayUnit if value is not a literal constant or if displayUnit is empty or if unit and displayUnit are 1!
          if (!Utilities::isValueLiteralConstant(textValue) || displayUnit.isEmpty() || (displayUnit.compare("1") == 0 && unit.compare("1") == 0)) {
            textValueWithDisplayUnit = textValue;
          } else if (unit.compare(displayUnit) == 0) {  // Do not do any conversion if unit and displayUnit are same.
            textValueWithDisplayUnit = QString("%1 %2").arg(textValue, Utilities::convertUnitToSymbol(displayUnit));
          } else {
            OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
            OMCInterface::convertUnits_res convertUnit = pOMCProxy->convertUnits(unit, displayUnit);
            if (convertUnit.unitsCompatible) {
              qreal convertedValue = Utilities::convertUnit(textValue.toDouble(), convertUnit.offset, convertUnit.scaleFactor);
              textValue = StringHandler::number(convertedValue, textValue);
              textValueWithDisplayUnit = QString("%1 %2").arg(textValue, Utilities::convertUnitToSymbol(displayUnit));
            } else {
              textValueWithDisplayUnit = QString("%1 %2").arg(textValue, Utilities::convertUnitToSymbol(unit));
            }
          }
          mTextString.replace(pos, regExp.matchedLength(), textValueWithDisplayUnit);
          pos += textValueWithDisplayUnit.length();
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
   * - %name replaced by the name of the element (i.e. the identifier for it in in the enclosing class).
   * - %class replaced by the name of the class.
   */
  mTextString = mOriginalTextString;
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
  } else if (mpElement) {
    if (!mTextString.contains("%")) {
      return;
    }
    if (mTextString.toLower().contains("%name")) {
      mTextString.replace(QRegExp("%name"), mpElement->getName());
    }
    if (mTextString.toLower().contains("%class")) {
      mTextString.replace(QRegExp("%class"), mpElement->getClassName());
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
