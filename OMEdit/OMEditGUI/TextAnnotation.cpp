/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 *
 */

/*
 * RCS: $Id$
 */

#include "TextAnnotation.h"

TextAnnotation::TextAnnotation(QString shape, Component *pParent)
  : ShapeAnnotation(pParent), mpComponent(pParent)
{
  initializeFields();
  mFontWeight = QFont::Normal;
  mFontItalic = false;
  mFontName = qApp->font().family();
  mHorizontalAlignment = Qt::AlignCenter;
  mFontUnderLine = false;
  mFontSize = 0;
  mCalculatedFontSize = 1;
  setLetterSpacing(2);

  connect(this, SIGNAL(extentChanged()), SLOT(calculateFontSize()));
  parseShapeAnnotation(shape, mpComponent->mpOMCProxy);
  emit extentChanged();
}

TextAnnotation::TextAnnotation(GraphicsView *graphicsView, QGraphicsItem *pParent)
  : ShapeAnnotation(graphicsView, pParent)
{
  // initialize all fields with default values
  initializeFields();
  mFontWeight = QFont::Normal;
  mFontItalic = false;
  mFontName = qApp->font().family();
  mHorizontalAlignment = Qt::AlignCenter;
  mFontUnderLine = false;
  mFontSize = 0;
  mCalculatedFontSize = 1;
  setLetterSpacing(2);
  mTextString = tr("Text Here");
  mIsCustomShape = true;
  mpComponent = 0;
  setAcceptHoverEvents(true);

  connect(this, SIGNAL(updateShapeAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
  connect(this, SIGNAL(extentChanged()), SLOT(calculateFontSize()));
}

TextAnnotation::TextAnnotation(QString shape, GraphicsView *graphicsView, QGraphicsItem *pParent)
  : ShapeAnnotation(graphicsView, pParent)
{
  // initialize all fields with default values
  initializeFields();
  mFontWeight = QFont::Normal;
  mFontItalic = false;
  mFontName = qApp->font().family();
  mHorizontalAlignment = Qt::AlignCenter;
  mFontUnderLine = false;
  mIsCustomShape = true;
  mFontSize = 0;
  mCalculatedFontSize = 1;
  setLetterSpacing(2);
  mpComponent = 0;

  connect(this, SIGNAL(extentChanged()), SLOT(calculateFontSize()));
  parseShapeAnnotation(shape, mpGraphicsView->mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy);
  emit extentChanged();
  setAcceptHoverEvents(true);
  connect(this, SIGNAL(updateShapeAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

QRectF TextAnnotation::boundingRect() const
{
  return shape().boundingRect();
}

QPainterPath TextAnnotation::shape() const
{
  QPainterPath path;
  path.addRoundedRect(getBoundingRect(), mCornerRadius, mCornerRadius);
  return path;
}

void TextAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(option);
  Q_UNUSED(widget);

  if (transformOriginPoint() != boundingRect().center())
  {
    setTransformOriginPoint(boundingRect().center());
  }

  QPen pen(mLineColor, mThickness, mLinePattern);
  pen.setCosmetic(true);
  painter->setPen(pen);
  //painter->setBrush(QBrush(mFillColor, Qt::SolidPattern));
  // create the font object
  QFont font;
  if (mFontSize == 0)
    font = QFont(mFontName, mCalculatedFontSize, mFontWeight, mFontItalic);
  else
    font = QFont(mFontName, mFontSize, mFontWeight, mFontItalic);
  // set font underline
  if(mFontUnderLine)
    font.setUnderline(true);
  // set letter spacing for the font
  setLetterSpacingOnFont(&font, getLetterSpacing());
  painter->setFont(font);
  // draw the font
  // first we invert the painter since we have outr coordinate system inverted.
  painter->scale(1.0, -1.0);
  painter->translate(0, ((-boundingRect().top()) - boundingRect().bottom()));

  if (mpComponent)
  {
    // get the root component to check the rotation and transformations.
    Component *pComponent = mpComponent->getRootParentComponent();
    pComponent = mpComponent->getRootParentComponent((pComponent->mType == StringHandler::DIAGRAM) ? true : false);
    if (pComponent->rotation() == -180 || pComponent->rotation() == 180)
    {
      painter->scale(-1.0, -1.0);
      painter->translate(((-boundingRect().left()) - boundingRect().right()), ((-boundingRect().top()) - boundingRect().bottom()));
    }
    // check transformations.
    if (pComponent->mpTransformation)
    {
      // the item could be flipped horizontally
      if (pComponent->mpTransformation->getFlipHorizontalIcon())
      {
        painter->scale(-1.0, 1.0);
        painter->translate(((-boundingRect().left()) - boundingRect().right()), 0);
      }
      // the item could be flipped vertically
      if (pComponent->mpTransformation->getFlipVerticalIcon())
      {
        painter->scale(1.0, -1.0);
        painter->translate(0, ((-boundingRect().top()) - boundingRect().bottom()));
      }
      // the item could be rotated
      if (pComponent->mpTransformation->getRotateAngleIcon() == -180 || pComponent->mpTransformation->getRotateAngleIcon() == 180)
      {
        painter->scale(-1.0, -1.0);
        painter->translate(((-boundingRect().left()) - boundingRect().right()), ((-boundingRect().top()) - boundingRect().bottom()));
      }
    }
  }
  else if (mIsCustomShape)
  {
    if (rotation() == -180 || rotation() == 180)
    {
      painter->scale(-1.0, -1.0);
      painter->translate(((-boundingRect().left()) - boundingRect().right()), ((-boundingRect().top()) - boundingRect().bottom()));
    }
  }
  if (boundingRect().width() > 0)
    painter->drawText(boundingRect(), mHorizontalAlignment | Qt::AlignJustify | Qt::TextDontClip, mTextString);
}

void TextAnnotation::checkNameString()
{
  /* the name of the component can be present in any inherited class . So we start with the main class and then
       move up the hierarchy looking for the name.
    */
  if (mTextString.contains("%name"))
  {
    if (!mpComponent->getName().isEmpty())
      mTextString = mpComponent->getName();
    else
    {
      Component *pComponent = mpComponent;
      while (pComponent->mpParentComponent)
      {
        pComponent = pComponent->mpParentComponent;
        if (!pComponent->getName().isEmpty())
        {
          mTextString = pComponent->getName();
          break;
        }
      }
    }
  }
}

void TextAnnotation::checkParameterString()
{
  // look for the string in parameters list
  foreach (IconParameters *parameter, mpComponent->mIconParametersList)
  {
    if (updateParameterString(parameter))
      break;
  }
}

bool TextAnnotation::updateParameterString(IconParameters *pParamter)
{
  QString parameterString;
  // paramter can be in form R=%R
  parameterString = QString(pParamter->getName()).append("=%").append(pParamter->getName());
  if (parameterString == mTextString)
  {
    mTextString = QString(pParamter->getName()).append("=").append(pParamter->getDefaultValue());
    return true;
  }
  // paramter can be in form %R
  parameterString = QString("%").append(pParamter->getName());
  if (parameterString == mTextString)
  {
    mTextString = QString(pParamter->getDefaultValue());
    return true;
  }
  return false;
}

QString TextAnnotation::getTextString()
{
  return mTextString.trimmed();
}

void TextAnnotation::setTextString(QString text)
{
  mTextString = text;
  update(boundingRect());
}

void TextAnnotation::setFontName(QString fontName)
{
  mFontName = fontName;
}

QString TextAnnotation::getFontName()
{
  return mFontName;
}

void TextAnnotation::setFontSize(double fontSize)
{
  mFontSize = fontSize;
}

double TextAnnotation::getFontSize()
{
  return mFontSize;
}

void TextAnnotation::setItalic(bool italic)
{
  mFontItalic = italic;
}

bool TextAnnotation::getItalic()
{
  return mFontItalic;
}

void TextAnnotation::setWeight(int bold)
{
  mFontWeight = bold;
}

bool TextAnnotation::getWeight()
{
  if (mFontWeight == QFont::Bold)
    return true;
  else
    return false;
}

void TextAnnotation::setUnderLine(bool underLine)
{
  mFontUnderLine = underLine;
}

bool TextAnnotation::getUnderLine()
{
  return mFontUnderLine;
}

void TextAnnotation::setAlignment(Qt::Alignment alignment)
{
  mHorizontalAlignment = alignment;
}

QString TextAnnotation::getAlignment()
{
  switch (mHorizontalAlignment)
  {
    case Qt::AlignLeft:
      return Helper::left;
    case Qt::AlignCenter:
      return Helper::center;
    case Qt::AlignRight:
      return Helper::right;
    default:
      return Helper::left;
  }
}

void TextAnnotation::drawRectangleCornerItems()
{
  mIsFinishedCreatingShape = true;
  for (int i = 0 ; i < mExtent.size() ; i++)
  {
    QPointF point = mExtent.at(i);
    RectangleCornerItem *rectangleCornerItem = new RectangleCornerItem(point.x(), point.y(), i, this);
    mRectangleCornerItemsList.append(rectangleCornerItem);
  }
  emit updateShapeAnnotation();
}

void TextAnnotation::addPoint(QPointF point)
{
  mExtent.append(point);
  if (mExtent.size() < 2)
    return;
  emit extentChanged();
}

void TextAnnotation::updatePoint(int index, QPointF point)
{
  mExtent.replace(index, point);
  emit extentChanged();
}

void TextAnnotation::updateEndPoint(QPointF point)
{
  mExtent.back() = point;
  emit extentChanged();
}

void TextAnnotation::updateAnnotation()
{
  emit updateShapeAnnotation();
}

QString TextAnnotation::getShapeAnnotation()
{
  QString annotationString;
  annotationString.append("Text(");

  if (!mVisible)
  {
    annotationString.append("visible=false,");
  }

  annotationString.append("rotation=").append(QString::number(rotation())).append(",");

  annotationString.append("lineColor={");
  annotationString.append(QString::number(mLineColor.red())).append(",");
  annotationString.append(QString::number(mLineColor.green())).append(",");
  annotationString.append(QString::number(mLineColor.blue()));
  annotationString.append("},");

  annotationString.append("fillColor={");
  annotationString.append(QString::number(mFillColor.red())).append(",");
  annotationString.append(QString::number(mFillColor.green())).append(",");
  annotationString.append(QString::number(mFillColor.blue()));
  annotationString.append("},");

  QMap<QString, Qt::PenStyle>::iterator it;
  for (it = mLinePatternsMap.begin(); it != mLinePatternsMap.end(); ++it)
  {
    if (it.value() == mLinePattern)
    {
      annotationString.append("pattern=LinePattern.").append(it.key()).append(",");
      break;
    }
  }

  QMap<QString, Qt::BrushStyle>::iterator fill_it;
  for (fill_it = mFillPatternsMap.begin(); fill_it != mFillPatternsMap.end(); ++fill_it)
  {
    if (fill_it.value() == mFillPattern)
    {
      annotationString.append("fillPattern=FillPattern.").append(fill_it.key()).append(",");
      break;
    }
  }

  annotationString.append("lineThickness=").append(QString::number(mThickness)).append(",");
  annotationString.append("extent={{");
  annotationString.append(QString::number(mapToScene(mExtent.at(0)).x())).append(",");
  annotationString.append(QString::number(mapToScene(mExtent.at(0)).y())).append("},{");
  annotationString.append(QString::number(mapToScene(mExtent.at(1)).x())).append(",");
  annotationString.append(QString::number(mapToScene(mExtent.at(1)).y()));
  annotationString.append("}}");

  annotationString.append(",textString=");
  annotationString.append('"');
  annotationString.append(getTextString());
  annotationString.append('"');

  if(mFontSize != 0)
  {
    annotationString.append(",fontSize=");
    annotationString.append(QString::number(mFontSize));

  }

  if(!(mFontName == qApp->font().family()))
  {
    annotationString.append(",fontName=");
    annotationString.append('"');
    annotationString.append(mFontName);
    annotationString.append('"');
  }

  //Annotation for text style bold italic underline
  if(mFontItalic || (mFontWeight == QFont::Bold) || mFontUnderLine)
  {
    annotationString.append(",textStyle={");
    {
      if(mFontItalic)
        annotationString.append("TextStyle.Italic");

      if(mFontWeight == QFont::Bold)
      {
        if(mFontItalic)
          annotationString.append(",TextStyle.Bold");
        else
          annotationString.append("TextStyle.Bold");
      }
      if(mFontUnderLine)
      {
        if(mFontItalic || mFontWeight == QFont::Bold)
          annotationString.append(",TextStyle.UnderLine");
        else
          annotationString.append("TextStyle.UnderLine");
      }
    }
    annotationString.append("}");
  }

  annotationString.append(")");
  return annotationString;
}

QRectF TextAnnotation::getDrawingRect()
{
  mDrawingRect = QRect (boundingRect().left(), -(boundingRect().top()), boundingRect().width(), -(boundingRect().height()));
  return mDrawingRect;
}

//! Sets the letter spacing for the Text Annotations.
//! @param letterSpacing is the new letter spacing.
//! @see setLetterSpacingOnFont(QFont *font, qreal letterSpacing)
//! @see getLetterSpacing()
void TextAnnotation::setLetterSpacing(qreal letterSpacing)
{
  mLetterSpacing = letterSpacing;
}

//! Sets the letter spacing of the Text Annotations for the given Font.
//! @param font
//! @param letterSpacing is the new letter spacing.
//! @see setLetterSpacing(qreal letterSpacing)
//! @see getLetterSpacing()
void TextAnnotation::setLetterSpacingOnFont(QFont *font, qreal letterSpacing)
{
//  if (font->letterSpacing() < letterSpacing)
//    font->setLetterSpacing(QFont::AbsoluteSpacing, letterSpacing);
}

//! Returns the letter spacing used by the Text Annotations.
//! @param font
//! @param letterSpacing is the new letter spacing.
//! @see setLetterSpacing(qreal letterSpacing)
//! @see setLetterSpacingOnFont(QFont *font, qreal letterSpacing)
qreal TextAnnotation::getLetterSpacing()
{
  return mLetterSpacing;
}

void TextAnnotation::parseShapeAnnotation(QString shape, OMCProxy *omc)
{
  shape = shape.replace("{", "");
  shape = shape.replace("}", "");
  // parse the shape to get the list of attributes of Text Annotation.
  QStringList list = StringHandler::getStrings(shape);
  if (list.size() < 18)
  {
    return;
  }
  int index = 0;
  // if first item of list is true then the Text Annotation should be visible.
  mVisible = static_cast<QString>(list.at(index)).contains("true");
  if (omc->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
  {
    mOrigin.setX(static_cast<QString>(list.at(1)).toFloat());
    mOrigin.setY(static_cast<QString>(list.at(2)).toFloat());
    mRotation = static_cast<QString>(list.at(3)).toFloat();
    index = 3;
  }
  // 4,5,6 items of list contains the line color.
  index = index + 1;
  int red, green, blue;
  red = static_cast<QString>(list.at(index)).toInt();
  index = index + 1;
  green = static_cast<QString>(list.at(index)).toInt();
  index = index + 1;
  blue = static_cast<QString>(list.at(index)).toInt();
  mLineColor = QColor (red, green, blue);
  // 7,8,9 items of list contains the fill color.
  index = index + 1;
  red = static_cast<QString>(list.at(index)).toInt();
  index = index + 1;
  green = static_cast<QString>(list.at(index)).toInt();
  index = index + 1;
  blue = static_cast<QString>(list.at(index)).toInt();
  mFillColor = QColor (red, green, blue);
  // 10 item of the list contains the line pattern.
  index = index + 1;
  QString linePattern = StringHandler::getLastWordAfterDot(list.at(index));
  QMap<QString, Qt::PenStyle>::iterator it;
  for (it = mLinePatternsMap.begin(); it != mLinePatternsMap.end(); ++it)
  {
    if (it.key().compare(linePattern) == 0)
    {
      mLinePattern = it.value();
      break;
    }
  }
  // 11 item of the list contains the fill pattern.
  index = index + 1;
  QString fillPattern = StringHandler::getLastWordAfterDot(list.at(index));
  QMap<QString, Qt::BrushStyle>::iterator fill_it;
  for (fill_it = mFillPatternsMap.begin(); fill_it != mFillPatternsMap.end(); ++fill_it)
  {
    if (fill_it.key().compare(fillPattern) == 0)
    {
      mFillPattern = fill_it.value();
      break;
    }
  }
  // 12 item of the list contains the thickness.
  index = index + 1;
  mThickness = static_cast<QString>(list.at(index)).toFloat();
  // 13, 14, 15, 16 items of the list contains the extent points of Text.
  index = index + 1;
  qreal x = static_cast<QString>(list.at(index)).toFloat();
  index = index + 1;
  qreal y = static_cast<QString>(list.at(index)).toFloat();
  QPointF p1 (x, y);
  index = index + 1;
  x = static_cast<QString>(list.at(index)).toFloat();
  index = index + 1;
  y = static_cast<QString>(list.at(index)).toFloat();
  QPointF p2 (x, y);
  mExtent.append(p1);
  mExtent.append(p2);
  // 17 item of the list contains the text string.
  index = index + 1;
  if (mIsCustomShape)
    mTextString = StringHandler::removeFirstLastQuotes(list.at(index));
  else
  {
    mTextString = StringHandler::removeFirstLastQuotes(list.at(index));
    checkNameString();
    checkParameterString();
  }
  // 18 item of the list contains the text size.
  index = index + 1;
  mFontSize = static_cast<QString>(list.at(index)).toFloat();
  index = index + 1;
  //Now comes the optional parameters; fontName and textStyle.
  while(index < list.size())
  {
    QString line = StringHandler::removeFirstLastQuotes(list.at(index));
    // check textStyles enumeration.
    if(line == "TextStyle.Italic")
    {
      mFontItalic = true;
      index++;
    }
    else if(line == "TextStyle.Bold")
    {
      mFontWeight = QFont::Bold;
      index++;
    }
    else if(line == "TextStyle.UnderLine")
    {
      mFontUnderLine = true;
      index++;
    }
    // check textAlignment enumeration.
    else if(line == "TextAlignment.Center")
    {
      mHorizontalAlignment = Qt::AlignCenter;
      index++;
    }
    else if(line == "TextAlignment.Left")
    {
      mHorizontalAlignment = Qt::AlignLeft;
      index++;
    }
    else if(line == "TextAlignment.Right")
    {
      mHorizontalAlignment = Qt::AlignRight;
      index++;
    }
    else
    {
      mFontName = line;
      index++;
    }
  }
}

void TextAnnotation::calculateFontSize()
{
  QFont font(mFontName, mCalculatedFontSize, mFontWeight, mFontItalic);
  if(mFontUnderLine)
    font.setUnderline(true);
  // set letter spacing for the font
  setLetterSpacingOnFont(&font, getLetterSpacing());
  QFontMetricsF fontMetric (font);

  //    if ((boundingRect().width() > fontMetric.boundingRect(mTextString).width()) &&
  //        (boundingRect().height() > fontMetric.boundingRect(mTextString).height()))
  //    {
  //        while ((boundingRect().width() > fontMetric.boundingRect(mTextString).width()) &&
  //               (boundingRect().height() > fontMetric.boundingRect(mTextString).height()))
  //        {
  //            mCalculatedFontSize += 1;
  //            font = QFont(mFontName, mCalculatedFontSize, mFontWeight, mFontItalic);
  //            if(mFontUnderLine)
  //                font.setUnderline(true);
  //            // set letter spacing for the font
  //            setLetterSpacingOnFont(&font, getLetterSpacing());
  //            fontMetric = QFontMetricsF(font);
  //        }
  //        mCalculatedFontSize -= 1;
  //    }
  //    else if ((boundingRect().width() < fontMetric.boundingRect(mTextString).width()) &&
  //             (boundingRect().height() < fontMetric.boundingRect(mTextString).height()))
  //    {
  //        while ((boundingRect().width() < fontMetric.boundingRect(mTextString).width()) &&
  //               (boundingRect().height() < fontMetric.boundingRect(mTextString).height()))
  //        {
  //            mCalculatedFontSize -= 1;
  //            // make sure calculated font doesn't go in negative.
  //            /*
  //             * if calculated font size becomes zero then we have problems because Qt automatically assigns font size
  //             * if your given font size is zero.
  //             */
  //            if (mCalculatedFontSize <= 0)
  //                break;
  //            font = QFont(mFontName, mCalculatedFontSize, mFontWeight, mFontItalic);
  //            if(mFontUnderLine)
  //                font.setUnderline(true);
  //            // set letter spacing for the font
  //            setLetterSpacingOnFont(&font, getLetterSpacing());
  //            fontMetric = QFontMetricsF(font);
  //        }
  //        mCalculatedFontSize += 1;
  //    }

  QRectF fontBoundingRect (boundingRect().left(), boundingRect().top(), fontMetric.boundingRect(mTextString).width(),
                           fontMetric.boundingRect(mTextString).height());

  // if font boundingrect is within original boundingrect
  if (boundingRect().contains(fontBoundingRect))
  {
    while (boundingRect().contains(fontBoundingRect))
    {
      mCalculatedFontSize += 1;
      font = QFont(mFontName, mCalculatedFontSize, mFontWeight, mFontItalic);
      if(mFontUnderLine)
        font.setUnderline(true);
      // set letter spacing for the font
      setLetterSpacingOnFont(&font, getLetterSpacing());
      fontMetric = QFontMetricsF(font);
      fontBoundingRect = QRectF(boundingRect().left(), boundingRect().top(), fontMetric.boundingRect(mTextString).width(),
                                fontMetric.boundingRect(mTextString).height());
    }
    mCalculatedFontSize -= 1;
  }
  // if font boundingrect is not within original boundingrect
  else
  {
    while (!boundingRect().contains(fontBoundingRect))
    {
      mCalculatedFontSize -= 1;
      // make sure calculated font doesn't go in negative.
      /*
       * if calculated font size becomes zero then we have problems because Qt automatically assigns font size
       * if your given font size is zero.
       */
      if (mCalculatedFontSize <= 0)
        break;
      font = QFont(mFontName, mCalculatedFontSize, mFontWeight, mFontItalic);
      if(mFontUnderLine)
        font.setUnderline(true);
      // set letter spacing for the font
      setLetterSpacingOnFont(&font, getLetterSpacing());
      fontMetric = QFontMetricsF(font);
      fontBoundingRect = QRectF(boundingRect().left(), boundingRect().top(), fontMetric.boundingRect(mTextString).width(),
                                fontMetric.boundingRect(mTextString).height());
    }
    mCalculatedFontSize += 1;
  }
}

//TextWidget declarations

TextWidget::TextWidget(TextAnnotation *pTextShape, MainWindow *parent)
  : QDialog(parent, Qt::WindowTitleHint)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::textProperties));
  setAttribute(Qt::WA_DeleteOnClose);
  setModal(true);
  setMinimumSize(300, 300);
  mpParentMainWindow = parent;
  mpTextAnnotation = pTextShape;
  setUpForm();
}

void TextWidget::setUpForm()
{
  // heading
  mpHeading = new QLabel(Helper::textProperties);
  mpHeading->setFont(QFont("", Helper::headingFontSize));
  mpHeading->setAlignment(Qt::AlignTop);

  QHBoxLayout *horizontalLayout = new QHBoxLayout;
  horizontalLayout->addWidget(mpHeading);

  mHorizontalLine = new QFrame();
  mHorizontalLine->setFrameShape(QFrame::HLine);
  mHorizontalLine->setFrameShadow(QFrame::Sunken);
  //Text Label
  mpTextLabel = new QLabel(tr("Text of Label:"));
  mpTextBox = new QLineEdit(mpTextAnnotation->getTextString());
  //Font Name
  mpFontLabel = new QLabel(tr("Font Name:"));
  mpFontFamilyComboBox = new QFontComboBox;
  int currentIndex;
  currentIndex = mpFontFamilyComboBox->findText(mpTextAnnotation->getFontName(), Qt::MatchExactly);
  mpFontFamilyComboBox->setCurrentIndex(currentIndex);
  //Font Size
  mpFontSizeLabel = new QLabel(tr("Font Size:"));
  mpFontSizeComboBox = new QComboBox;
  QStringList sizesList;
  sizesList << "0" << "2" << "4";
  mpFontSizeComboBox->addItems(sizesList);
  mpFontSizeComboBox->addItems(Helper::fontSizes.split(","));
  currentIndex = mpFontSizeComboBox->findText(QString::number(mpTextAnnotation->getFontSize()), Qt::MatchExactly);
  mpFontSizeComboBox->setCurrentIndex(currentIndex);
  //Cursive Bold Underline Checkboxes
  mpCursive = new QCheckBox(tr("Italic"), this);
  mpCursive->setChecked(mpTextAnnotation->getItalic());
  mpBold = new QCheckBox(tr("Bold"), this);
  mpBold->setChecked(mpTextAnnotation->getWeight());
  mpUnderline = new QCheckBox(tr("Underline"), this);
  mpUnderline->setChecked(mpTextAnnotation->getUnderLine());
  mpStylesGroup = new QGroupBox(tr("Styles"));
  QVBoxLayout *verticalPropertiesLayout = new QVBoxLayout;
  verticalPropertiesLayout->addWidget(mpCursive);
  verticalPropertiesLayout->addWidget(mpBold);
  verticalPropertiesLayout->addWidget(mpUnderline);
  mpStylesGroup->setLayout(verticalPropertiesLayout);
  //Alignment
  mpAlignmentLabel = new QLabel(tr("Alignment:"));
  mpAlignmentComboBox = new QComboBox;
  QStringList alignmentList;
  alignmentList << Helper::left << Helper::center << Helper::right;
  mpAlignmentComboBox->addItems(alignmentList);
  currentIndex = mpAlignmentComboBox->findText(mpTextAnnotation->getAlignment(), Qt::MatchExactly);
  mpAlignmentComboBox->setCurrentIndex(currentIndex);
  //Buttons
  mpEditButton = new QPushButton(Helper::ok);
  mpEditButton->setAutoDefault(true);
  connect(mpEditButton, SIGNAL(clicked()), this, SLOT(edit()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpEditButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *mainLayout = new QGridLayout;
  mainLayout->addLayout(horizontalLayout, 0, 0, 1, 2);
  mainLayout->addWidget(mHorizontalLine, 1, 0, 1, 2);
  mainLayout->addWidget(mpTextLabel, 2, 0);
  mainLayout->addWidget(mpTextBox, 2, 1);
  mainLayout->addWidget(mpFontLabel, 3, 0);
  mainLayout->addWidget(mpFontFamilyComboBox, 3, 1);
  mainLayout->addWidget(mpFontSizeLabel, 4, 0);
  mainLayout->addWidget(mpFontSizeComboBox, 4, 1);
  mainLayout->addWidget(mpStylesGroup, 5, 0, 1, 2);
  mainLayout->addWidget(mpAlignmentLabel, 6, 0);
  mainLayout->addWidget(mpAlignmentComboBox, 6, 1);
  mainLayout->addWidget(mpButtonBox, 7, 0, 1, 2);
  setLayout(mainLayout);
}

void TextWidget::edit()
{
  if(mpTextBox->text().isEmpty())
    return;

  mpTextAnnotation->setTextString(mpTextBox->text());
  mpTextAnnotation->setFontName(mpFontFamilyComboBox->currentText());
  mpTextAnnotation->setFontSize(mpFontSizeComboBox->currentText().toDouble());
  mpTextAnnotation->setItalic(mpCursive->isChecked());
  if (mpBold->isChecked())
    mpTextAnnotation->setWeight(QFont::Bold);
  else
    mpTextAnnotation->setWeight(QFont::Normal);
  mpTextAnnotation->setUnderLine(mpUnderline->isChecked());

  if (mpAlignmentComboBox->currentText() == "Left")
    mpTextAnnotation->setAlignment(Qt::AlignLeft);
  else if (mpAlignmentComboBox->currentText() == "Center")
    mpTextAnnotation->setAlignment(Qt::AlignCenter);
  else if (mpAlignmentComboBox->currentText() == "Right")
    mpTextAnnotation->setAlignment(Qt::AlignRight);

  mpTextAnnotation->updateAnnotation();
  accept();
}

void TextWidget::show()
{
  setVisible(true);
}
