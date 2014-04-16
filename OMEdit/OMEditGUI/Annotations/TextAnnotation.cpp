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

#include "TextAnnotation.h"

TextAnnotation::TextAnnotation(QString annotation, Component *pParent)
  : ShapeAnnotation(pParent), mpComponent(pParent)
{
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  parseShapeAnnotation(annotation);
  setPos(mOrigin);
  setRotation(mRotation);
}

TextAnnotation::TextAnnotation(QString annotation, bool inheritedShape, GraphicsView *pGraphicsView)
  : ShapeAnnotation(inheritedShape, pGraphicsView, 0)
{
  setFlag(QGraphicsItem::ItemIsSelectable);
  mpComponent = 0;
  // set the default values
  GraphicItem::setDefaults();
  FilledShape::setDefaults();
  ShapeAnnotation::setDefaults();
  // set users default value by reading the settings file.
  ShapeAnnotation::setUserDefaults();
  parseShapeAnnotation(annotation);
  /* Only set the ItemIsMovable flag on shape if the class is not a system library class OR shape is not an inherited shape. */
  if (!mpGraphicsView->getModelWidget()->getLibraryTreeNode()->isSystemLibrary() && !isInheritedShape())
    setFlag(QGraphicsItem::ItemIsMovable);
  mpGraphicsView->addShapeObject(this);
  mpGraphicsView->scene()->addItem(this);
  connect(this, SIGNAL(updateClassAnnotation()), mpGraphicsView, SLOT(addClassAnnotation()));
}

void TextAnnotation::parseShapeAnnotation(QString annotation)
{
  GraphicItem::parseShapeAnnotation(annotation);
  FilledShape::parseShapeAnnotation(annotation);
  // parse the shape to get the list of attributes of Text.
  QStringList list = StringHandler::getStrings(annotation);
  if (list.size() < 11)
    return;
  // 9th item of the list contains the extent points
  QStringList extentsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(8)));
  for (int i = 0 ; i < qMin(extentsList.size(), 2) ; i++)
  {
    QStringList extentPoints = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(extentsList[i]));
    if (extentPoints.size() >= 2)
      mExtents.replace(i, QPointF(extentPoints.at(0).toFloat(), extentPoints.at(1).toFloat()));
  }
  // 10th item of the list contains the textString.
  mOriginalTextString = StringHandler::removeFirstLastQuotes(list.at(9));
  mTextString = mOriginalTextString;
  if (mpComponent)
  {
    if (mOriginalTextString.contains("%"))
    {
      updateTextString();
      connect(mpComponent->getRootParentComponent(), SIGNAL(componentDisplayTextChanged()), SLOT(updateTextString()));
    }
  }
  // 11th item of the list contains the fontSize.
  mFontSize = list.at(10).toFloat();
  //Now comes the optional parameters; fontName and textStyle.
  annotation = annotation.replace("{", "");
  annotation = annotation.replace("}", "");
  // parse the shape to get the list of attributes of Text Annotation.
  list = StringHandler::getStrings(annotation);
  int index = 19;
  while(index < list.size())
  {
    QString annotationValue = StringHandler::removeFirstLastQuotes(list.at(index));
    // check textStyles enumeration.
    if(annotationValue == "TextStyle.Bold")
    {
      mTextStyles.append(StringHandler::TextStyleBold);
      index++;
    }
    else if(annotationValue == "TextStyle.Italic")
    {
      mTextStyles.append(StringHandler::TextStyleItalic);
      index++;
    }
    else if(annotationValue == "TextStyle.UnderLine")
    {
      mTextStyles.append(StringHandler::TextStyleUnderLine);
      index++;
    }
    // check textAlignment enumeration.
    else if(annotationValue == "TextAlignment.Left")
    {
      mHorizontalAlignment = StringHandler::TextAlignmentLeft;
      index++;
    }
    else if(annotationValue == "TextAlignment.Center")
    {
      mHorizontalAlignment = StringHandler::TextAlignmentCenter;
      index++;
    }
    else if(annotationValue == "TextAlignment.Right")
    {
      mHorizontalAlignment = StringHandler::TextAlignmentRight;
      index++;
    }
    else
    {
      mFontName = annotationValue;
      index++;
    }
  }
}

QRectF TextAnnotation::boundingRect() const
{
  return shape().boundingRect();
}

QPainterPath TextAnnotation::shape() const
{
  QPainterPath path;
  path.addRect(getBoundingRect());
  return path;
}

void TextAnnotation::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget)
{
  Q_UNUSED(option);
  Q_UNUSED(widget);
  if (mVisible)
    drawTextAnnotaion(painter);
}

void TextAnnotation::drawTextAnnotaion(QPainter *painter)
{
  applyLinePattern(painter);
  /* Don't apply the fill patterns on Text shapes. */
  /*applyFillPattern(painter);*/
  // first we invert the painter since we have our coordinate system inverted.
  painter->scale(1.0, -1.0);
  painter->translate(0, ((-boundingRect().top()) - boundingRect().bottom()));
  mTextString = StringHandler::removeFirstLastQuotes(mTextString);
  mTextString = StringHandler::unparse(QString("\"").append(mTextString).append("\""));
  QFont font;
  if (mFontSize > 0)
  {
    font = QFont(mFontName, mFontSize, StringHandler::getFontWeight(mTextStyles), StringHandler::getFontItalic(mTextStyles));
    // set font underline
    if(StringHandler::getFontUnderline(mTextStyles))
      font.setUnderline(true);
    font.setPointSizeF(mFontSize/4);
    painter->setFont(font);
  }
  else
  {
    font = QFont(mFontName, mFontSize, StringHandler::getFontWeight(mTextStyles), StringHandler::getFontItalic(mTextStyles));
    // set font underline
    if(StringHandler::getFontUnderline(mTextStyles))
      font.setUnderline(true);
    painter->setFont(font);
    QRect fontBoundRect = painter->fontMetrics().boundingRect(boundingRect().toRect(), Qt::TextDontClip, mTextString);
    float xFactor = boundingRect().width() / fontBoundRect.width();
    float yFactor = boundingRect().height() / fontBoundRect.height();
    float factor = xFactor < yFactor ? xFactor : yFactor;
    QFont f = painter->font();
    qreal fontSizeFactor = f.pointSizeF()*factor;
    if ((fontSizeFactor < 12) && mpComponent)
      f.setPointSizeF(12);
    else if (fontSizeFactor <= 0)
      f.setPointSizeF(1);
    else
      f.setPointSizeF(fontSizeFactor);
    painter->setFont(f);
  }
  if (mpComponent)
  {
    if (sceneTransform().m11() < 0)
    {
      painter->scale(-1.0, 1.0);
      painter->translate(((-boundingRect().left()) - boundingRect().right()), 0);
    }
    if (sceneTransform().m22() < 0)
    {
      painter->scale(1.0, -1.0);
      painter->translate(0, ((-boundingRect().top()) - boundingRect().bottom()));
    }
  }
  else
  {
    qreal angle = StringHandler::getNormalizedAngle(mpTransformation->getRotateAngle());
    if (angle == 180)
    {
      painter->scale(-1.0, -1.0);
      painter->translate(((-boundingRect().left()) - boundingRect().right()), ((-boundingRect().top()) - boundingRect().bottom()));
    }
  }
  // draw the font
  if (mpComponent)
    painter->drawText(boundingRect(), StringHandler::getTextAlignment(mHorizontalAlignment) | Qt::AlignVCenter | Qt::TextDontClip, mTextString);
  else if (boundingRect().width() > 0 && boundingRect().height() > 0)
    painter->drawText(boundingRect(), StringHandler::getTextAlignment(mHorizontalAlignment) | Qt::AlignVCenter | Qt::TextDontClip, mTextString);
}

QString TextAnnotation::getShapeAnnotation()
{
  QStringList annotationString;
  annotationString.append(GraphicItem::getShapeAnnotation());
  annotationString.append(FilledShape::getShapeAnnotation());
  // get the extents
  if (mExtents.size() > 1)
  {
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
  if (mFontSize != 0)
    annotationString.append(QString("fontSize=").append(QString::number(mFontSize)));
  // get the font name
  if (!mFontName.isEmpty())
    annotationString.append(QString("fontName=\"").append(mFontName).append("\""));
  // get the font styles
  QString textStylesString;
  QStringList stylesList;
  if (mTextStyles.size() > 0)
    textStylesString.append("textStyle={");
  for (int i = 0 ; i < mTextStyles.size() ; i++)
  {
    stylesList.append(StringHandler::getTextStyleString(mTextStyles[i]));
  }
  if (mTextStyles.size() > 0)
  {
    textStylesString.append(stylesList.join(","));
    textStylesString.append("}");
    annotationString.append(textStylesString);
  }
  // get the font horizontal alignment
  if (mHorizontalAlignment != StringHandler::TextAlignmentCenter)
    annotationString.append(QString("horizontalAlignment=").append(StringHandler::getTextAlignmentString(mHorizontalAlignment)));
  return QString("Text(").append(annotationString.join(",")).append(")");
}

void TextAnnotation::updateTextStringHelper(QRegExp regExp)
{
  int pos = 0;
  while ((pos = regExp.indexIn(mTextString, pos)) != -1)
  {
    QString variable = regExp.cap(0);
    if ((!variable.isEmpty()) && (variable.compare("%%") != 0) && (variable.compare("%name") != 0) && (variable.compare("%class") != 0))
    {
      variable.remove("%");
      if (!variable.isEmpty())
      {
        QString textValue = mpComponent->getParameterDisplayString(variable);
        if (!textValue.isEmpty())
        {
          mTextString.replace(pos, regExp.matchedLength(), textValue);
        }
        /* if the value of %\\W* is empty then remove the % sign. */
        else
        {
          mTextString.replace(pos, 1, "");
        }
      }
      /* if there is just alone % then remove it. Because if you want to print % then use %%. */
      else
      {
        mTextString.replace(pos, 1, "");
      }
    }
    pos += regExp.matchedLength();
  }
}

void TextAnnotation::updateTextString()
{
  /*
    From Modelica Spec 32revision2,
    There are a number of common macros that can be used in the text, and they should be replaced when displaying
    the text as follows:
    - %par replaced by the value of the parameter par. The intent is that the text is easily readable, thus if par is
    of an enumeration type, replace %par by the item name, not by the full name.
    [Example: if par="Modelica.Blocks.Types.Enumeration.Periodic", then %par should be displayed as
    "Periodic"]
    - %% replaced by %
    - %name replaced by the name of the component (i.e. the identifier for it in in the enclosing class).
    - %class replaced by the name of the class.
  */
  mTextString = mOriginalTextString;
  if (!mTextString.contains("%"))
    return;
  if (mOriginalTextString.toLower().contains("%name"))
  {
    mTextString.replace(QRegExp("%name"), mpComponent->getRootParentComponent()->getName());
  }
  if (mOriginalTextString.toLower().contains("%class"))
  {
    mTextString.replace(QRegExp("%class"), mpComponent->getRootParentComponent()->getClassName());
  }
  if (!mTextString.contains("%"))
    return;
  /* handle variables now */
  updateTextStringHelper(QRegExp("(%%|%\\w*)"));
  /* call again with non-word characters so invalid % can be removed. */
  updateTextStringHelper(QRegExp("(%%|%\\W*)"));
  /* handle %% */
  if (mOriginalTextString.toLower().contains("%%"))
  {
    mTextString.replace(QRegExp("%%"), "%");
  }
}

void TextAnnotation::duplicate()
{
  TextAnnotation *pTextAnnotation = new TextAnnotation("", false, mpGraphicsView);
  QPointF gridStep(mpGraphicsView->getCoOrdinateSystem()->getHorizontalGridStep(),
                   mpGraphicsView->getCoOrdinateSystem()->getVerticalGridStep());
  pTextAnnotation->setOrigin(mOrigin + gridStep);
  pTextAnnotation->setRotationAngle(mRotation);
  pTextAnnotation->initializeTransformation();
  pTextAnnotation->setLineColor(getLineColor());
  pTextAnnotation->setFillColor(getFillColor());
  pTextAnnotation->setLinePattern(getLinePattern());
  pTextAnnotation->setFillPattern(getFillPattern());
  pTextAnnotation->setLineThickness(getLineThickness());
  pTextAnnotation->setExtents(getExtents());
  pTextAnnotation->setTextString(getTextString());
  pTextAnnotation->setFontSize(getFontSize());
  pTextAnnotation->setFontName(getFontName());
  pTextAnnotation->setTextStyles(getTextStyles());
  pTextAnnotation->setTextHorizontalAlignment(getTextHorizontalAlignment());
  pTextAnnotation->drawCornerItems();
  pTextAnnotation->setCornerItemsPassive();
  pTextAnnotation->update();
  mpGraphicsView->addClassAnnotation();
  mpGraphicsView->setCanAddClassAnnotation(true);
}
