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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
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

#include "Model.h"
#include "Util/StringHandler.h"
#include "Util/Helper.h"
#include "MessagesWidget.h"
#include "Options/OptionsDialog.h"

#include <QRectF>
#include <QtMath>
#include <QVariant>
#include <QStringBuilder>
#include <QDebug>

namespace ModelInstance
{
  /*!
   * \class CoordinateSystem
   * \brief A class to represent the coordinate system of view.
   */
  /*!
   * \brief CoordinateSystem::CoordinateSystem
   */
  CoordinateSystem::CoordinateSystem()
  {
    reset();
  }

  /*!
   * \brief CoordinateSystem::CoordinateSystem
   * \param coOrdinateSystem
   */
  CoordinateSystem::CoordinateSystem(const CoordinateSystem &coOrdinateSystem)
  {
    setExtent(coOrdinateSystem.getExtent());
    setHasExtent(coOrdinateSystem.hasExtent());
    setPreserveAspectRatio(coOrdinateSystem.getPreserveAspectRatio());
    setHasPreserveAspectRatio(coOrdinateSystem.hasPreserveAspectRatio());
    setInitialScale(coOrdinateSystem.getInitialScale());
    setHasInitialScale(coOrdinateSystem.hasInitialScale());
    setGrid(coOrdinateSystem.getGrid());
    setHasGrid(coOrdinateSystem.hasGrid());
  }

  void CoordinateSystem::setExtent(const QVector<QPointF> extent)
  {
    mExtent = extent;
    setHasExtent(true);
  }

  void CoordinateSystem::setPreserveAspectRatio(const bool preserveAspectRatio)
  {
    mPreserveAspectRatio = preserveAspectRatio;
    setHasPreserveAspectRatio(true);
  }

  void CoordinateSystem::setInitialScale(const qreal initialScale)
  {
    mInitialScale = initialScale;
    setHasInitialScale(true);
  }

  void CoordinateSystem::setGrid(const QPointF grid)
  {
    mGrid = grid;
    setHasGrid(true);
  }

  /*!
   * \brief CoordinateSystem::getHorizontalGridStep
   * \return
   */
  double CoordinateSystem::getHorizontalGridStep()
  {
    if (mGrid.x() < 1) {
      return 2;
    }
    return mGrid.x();
  }

  /*!
   * \brief CoordinateSystem::getVerticalGridStep
   * \return
   */
  double CoordinateSystem::getVerticalGridStep()
  {
    if (mGrid.y() < 1) {
      return 2;
    }
    return mGrid.y();
  }

  QRectF CoordinateSystem::getExtentRectangle() const
  {
    QPointF leftBottom = mExtent.at(0);
    QPointF topRight = mExtent.at(1);

    qreal left = qMin(leftBottom.x(), topRight.x());
    qreal bottom = qMin(leftBottom.y(), topRight.y());
    qreal right = qMax(leftBottom.x(), topRight.x());
    qreal top = qMax(leftBottom.y(), topRight.y());
    return QRectF(left, bottom, qFabs(left - right), qFabs(bottom - top));
  }

  void CoordinateSystem::reset()
  {
    mExtent.clear();
    mHasExtent = false;
    mPreserveAspectRatio = true;
    mHasPreserveAspectRatio = false;
    mInitialScale = 0.1;
    mHasInitialScale = false;
    mGrid = QPointF(2, 2);
    mHasGrid = false;
  }

  bool CoordinateSystem::isComplete() const
  {
    return mHasExtent && mHasPreserveAspectRatio;
  }

  void CoordinateSystem::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("extent")) {
      mHasExtent = mExtent.deserialize(jsonObject.value("extent"));
    }
    if (jsonObject.contains("preserveAspectRatio")) {
      mHasPreserveAspectRatio = mPreserveAspectRatio.deserialize(jsonObject.value("preserveAspectRatio"));
    }
    if (jsonObject.contains("initialScale")) {
      mHasInitialScale = mInitialScale.deserialize(jsonObject.value("initialScale"));
    }
    if (jsonObject.contains("grid")) {
      mHasGrid = mGrid.deserialize(jsonObject.value("grid"));
    }
  }

  GraphicItem::GraphicItem()
  {
    mVisible = true;
    mOrigin = QPointF(0, 0);
    mRotation = 0;
  }

  void GraphicItem::deserialize(const QJsonArray &jsonArray)
  {
    mVisible.deserialize(jsonArray.at(0));
    mOrigin.deserialize(jsonArray.at(1));
    mRotation.deserialize(jsonArray.at(2));
  }

  void GraphicItem::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("visible")) {
      mVisible.deserialize(jsonObject.value("visible"));
    }

    if (jsonObject.contains("origin")) {
      mOrigin.deserialize(jsonObject.value("origin"));
    }

    if (jsonObject.contains("rotation")) {
      mRotation.deserialize(jsonObject.value("rotation"));
    }
  }

  FilledShape::FilledShape()
  {
    OptionsDialog *pOptionsDialog = OptionsDialog::instance();
    if (pOptionsDialog->getLineStylePage()->getLineColor().isValid()) {
      mLineColor = pOptionsDialog->getLineStylePage()->getLineColor();
    } else {
      mLineColor = QColor(0, 0, 0);
    }
    if (pOptionsDialog->getFillStylePage()->getFillColor().isValid()) {
      mFillColor = pOptionsDialog->getFillStylePage()->getFillColor();
    } else {
      mFillColor = QColor(0, 0, 0);
    }
    mPattern = StringHandler::getLinePatternType(pOptionsDialog->getLineStylePage()->getLinePattern());
    mFillPattern = StringHandler::getFillPatternType(pOptionsDialog->getFillStylePage()->getFillPattern());
    mLineThickness = pOptionsDialog->getLineStylePage()->getLineThickness();
  }

  void FilledShape::deserialize(const QJsonArray &jsonArray)
  {
    mLineColor.deserialize(jsonArray.at(3));
    mFillColor.deserialize(jsonArray.at(4));
    mPattern.deserialize(jsonArray.at(5));
    mFillPattern.deserialize(jsonArray.at(6));
    mLineThickness.deserialize(jsonArray.at(7));
  }

  void FilledShape::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("lineColor")) {
      mLineColor.deserialize(jsonObject.value("lineColor"));
    }

    if (jsonObject.contains("fillColor")) {
      mFillColor.deserialize(jsonObject.value("fillColor"));
    }

    if (jsonObject.contains("pattern")) {
      mPattern.deserialize(jsonObject.value("pattern"));
    }

    if (jsonObject.contains("fillPattern")) {
      mFillPattern.deserialize(jsonObject.value("fillPattern"));
    }

    if (jsonObject.contains("lineThickness")) {
      mLineThickness.deserialize(jsonObject.value("lineThickness"));
    }
  }

  Shape::Shape(Model *pParentModel)
    : GraphicItem(), FilledShape()
  {
    mpParentModel = pParentModel;
  }

  Extend *Shape::getParentExtend() const
  {
    if (mpParentModel) {
      return mpParentModel->getParentExtend();
    }
    return 0;
  }

  Shape::~Shape() = default;

  Line::Line(Model *pParentModel)
    : Shape(pParentModel)
  {
    OptionsDialog *pOptionsDialog = OptionsDialog::instance();
    if (pOptionsDialog->getLineStylePage()->getLineColor().isValid()) {
      mColor = pOptionsDialog->getLineStylePage()->getLineColor();
    } else {
      mColor = QColor(0, 0, 0);
    }
    mPattern = StringHandler::getLinePatternType(pOptionsDialog->getLineStylePage()->getLinePattern());
    mThickness = pOptionsDialog->getLineStylePage()->getLineThickness();
    mArrow.replace(0, StringHandler::getArrowType(pOptionsDialog->getLineStylePage()->getLineStartArrow()));
    mArrow.replace(1, StringHandler::getArrowType(pOptionsDialog->getLineStylePage()->getLineEndArrow()));
    mArrowSize = pOptionsDialog->getLineStylePage()->getLineArrowSize();
    if (pOptionsDialog->getLineStylePage()->getLineSmooth()) {
      mSmooth = StringHandler::SmoothBezier;
    } else {
      mSmooth = StringHandler::SmoothNone;
    }
  }

  void Line::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 10) {
      GraphicItem::deserialize(jsonArray);

      mPoints.deserialize(jsonArray.at(3));
      mColor.deserialize(jsonArray.at(4));
      mPattern.deserialize(jsonArray.at(5));
      mThickness.deserialize(jsonArray.at(6));
      mArrow.deserialize(jsonArray.at(7));
      mArrowSize.deserialize(jsonArray.at(8));
      mSmooth.deserialize(jsonArray.at(9));
    }
  }

  void Line::deserialize(const QJsonObject &jsonObject)
  {
    GraphicItem::deserialize(jsonObject);

    if (jsonObject.contains("points")) {
      mPoints.deserialize(jsonObject.value("points"));
    }

    if (jsonObject.contains("color")) {
      mColor.deserialize(jsonObject.value("color"));
    }

    if (jsonObject.contains("pattern")) {
      mPattern.deserialize(jsonObject.value("pattern"));
    }

    if (jsonObject.contains("thickness")) {
      mThickness.deserialize(jsonObject.value("thickness"));
    }

    if (jsonObject.contains("arrow")) {
      mArrow.deserialize(jsonObject.value("arrow"));
    }

    if (jsonObject.contains("arrowSize")) {
      mArrowSize.deserialize(jsonObject.value("arrowSize"));
    }

    if (jsonObject.contains("smooth")) {
      mSmooth.deserialize(jsonObject.value("smooth"));
    }
  }

  void Line::setColor(const QColor &color)
  {
    mColor = color;
  }

  Polygon::Polygon(Model *pParentModel)
    : Shape(pParentModel)
  {
    mSmooth = StringHandler::SmoothNone;
  }

  void Polygon::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 10) {
      GraphicItem::deserialize(jsonArray);
      FilledShape::deserialize(jsonArray);

      mPoints.deserialize(jsonArray.at(8));
      mSmooth.deserialize(jsonArray.at(9));
    }
  }


  Rectangle::Rectangle(Model *pParentModel)
    : Shape(pParentModel)
  {
    mBorderPattern = StringHandler::BorderNone;
    mExtent = QVector<QPointF>(2, QPointF(0, 0));
    mRadius = 0;
  }

  void Rectangle::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 11) {
      GraphicItem::deserialize(jsonArray);
      FilledShape::deserialize(jsonArray);

      mBorderPattern.deserialize(jsonArray.at(8));
      mExtent.deserialize(jsonArray.at(9));
      mRadius.deserialize(jsonArray.at(10));
    }
  }

  Ellipse::Ellipse(Model *pParentModel)
    : Shape(pParentModel)
  {
    mExtent = QVector<QPointF>(2, QPointF(0, 0));
    mStartAngle = 0;
    mEndAngle = 360;
    if (mStartAngle == 0 && mEndAngle == 360) {
      mClosure = StringHandler::ClosureChord;
    } else {
      mClosure = StringHandler::ClosureRadial;
    }
  }

  void Ellipse::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 12) {
      GraphicItem::deserialize(jsonArray);
      FilledShape::deserialize(jsonArray);

      mExtent.deserialize(jsonArray.at(8));
      mStartAngle.deserialize(jsonArray.at(9));
      mEndAngle.deserialize(jsonArray.at(10));
      mClosure.deserialize(jsonArray.at(11));
    }
  }

  Text::Text(Model *pParentModel)
    : Shape(pParentModel)
  {
    mExtent = QVector<QPointF>(2, QPointF(0, 0));
    mTextString = "";
    mFontSize = 0;
    mFontName = Helper::systemFontInfo.family();
    mTextColor = QColor(0, 0, 0);
    mHorizontalAlignment = StringHandler::TextAlignmentCenter;
  }

  void Text::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 15) {
      GraphicItem::deserialize(jsonArray);
      FilledShape::deserialize(jsonArray);

      mExtent.deserialize(jsonArray.at(8));
      mTextString.deserialize(jsonArray.at(9));
      mFontSize.deserialize(jsonArray.at(10));
      // if invalid color
      QJsonArray colorArray = jsonArray.at(11).toArray();
      if (colorArray.size() == 3 && colorArray.at(0).toInt() == -1 && colorArray.at(1).toInt() == -1 && colorArray.at(2).toInt() == -1) {
        mTextColor = QColor();
      } else {
        mTextColor.deserialize(jsonArray.at(11));
      }
      mFontName.deserialize(jsonArray.at(12));
      QJsonArray textStyles = jsonArray.at(13).toArray();
      if (!textStyles.isEmpty()) {
        mTextStyle.deserialize(jsonArray.at(13));
      }
      mHorizontalAlignment.deserialize(jsonArray.at(14));
    }
  }

  void Text::deserialize(const QJsonObject &jsonObject)
  {
    GraphicItem::deserialize(jsonObject);
    FilledShape::deserialize(jsonObject);

    if (jsonObject.contains("extent")) {
      mExtent.deserialize(jsonObject.value("extent"));
    }

    if (jsonObject.contains("string")) {
      mTextString.deserialize(jsonObject.value("string"));
    }

    if (jsonObject.contains("fontSize")) {
      mFontSize.deserialize(jsonObject.value("fontSize"));
    }

    if (jsonObject.contains("textColor")) {
      mTextColor.deserialize(jsonObject.value("textColor"));
    }

    if (jsonObject.contains("fontName")) {
      mFontName.deserialize(jsonObject.value("fontName"));
    }

    if (jsonObject.contains("textStyle")) {
      mTextStyle.deserialize(jsonObject.value("textStyle"));
    }

    if (jsonObject.contains("horizontalAlignment")) {
      mHorizontalAlignment.deserialize(jsonObject.value("horizontalAlignment"));
    }

//    if (jsonObject.contains("index")) {
//      mIndex = jsonObject.value("index").toDouble();
//    }
  }

  Bitmap::Bitmap(Model *pParentModel)
    : Shape(pParentModel)
  {
    mExtent = QVector<QPointF>(2, QPointF(0, 0));
    mFileName = "";
    mImageSource = "";
  }

  void Bitmap::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 6) {
      GraphicItem::deserialize(jsonArray);

      mExtent.deserialize(jsonArray.at(3));
      mFileName = jsonArray.at(4).toString();
      mImageSource = jsonArray.at(5).toString();
    }
  }

  Annotation Annotation::defaultAnnotation{nullptr};

  Annotation::Annotation(Model *pParentModel)
    : mPlacementAnnotation(pParentModel)
  {
    mpParentModel = pParentModel;
    mDocumentationClass = false;
    mVersion = "";
    mVersionDate = "";
    mVersionBuild = 0;
    mDateModified = "";
    mPreferredView = "";
    mState = false;
    mAccess = "";
    // Element annotation
    mChoicesAllMatching = false;
    mHasDialogAnnotation = false;
  }

  void Annotation::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("Icon")) {
      mpIconAnnotation = std::make_unique<IconDiagramAnnotation>(mpParentModel);
      mpIconAnnotation->deserialize(jsonObject.value("Icon").toObject());
    }

    if (jsonObject.contains("Diagram")) {
      mpDiagramAnnotation = std::make_unique<IconDiagramAnnotation>(mpParentModel);
      mpDiagramAnnotation->deserialize(jsonObject.value("Diagram").toObject());
    }

    if (jsonObject.contains("DocumentationClass")) {
      mDocumentationClass.deserialize(jsonObject.value("DocumentationClass"));
    }

    if (jsonObject.contains("version")) {
      mVersion.deserialize(jsonObject.value("version"));
    }

    if (jsonObject.contains("versionDate")) {
      mVersionDate.deserialize(jsonObject.value("versionDate"));
    }

    if (jsonObject.contains("versionBuild")) {
      mVersionBuild.deserialize(jsonObject.value("versionBuild"));
    }

    if (jsonObject.contains("dateModified")) {
      mDateModified.deserialize(jsonObject.value("dateModified"));
    }

    if (jsonObject.contains("preferredView")) {
      mPreferredView.deserialize(jsonObject.value("preferredView"));
    }

    if (jsonObject.contains("__Dymola_state")) {
      mState.deserialize(jsonObject.value("__Dymola_state"));
    }

    if (jsonObject.contains("Protection")) {
      QJsonObject protection = jsonObject.value("Protection").toObject();
      if (protection.contains("access")) {
        QJsonObject access = protection.value("access").toObject();
        if (access.contains("name")) {
          mAccess.deserialize(access.value("name"));
        }
      }
    }
    // Element annotation
    if (jsonObject.contains("choicesAllMatching")) {
      mChoicesAllMatching.deserialize(jsonObject.value("choicesAllMatching"));
    }

    if (jsonObject.contains("Placement")) {
      mPlacementAnnotation = PlacementAnnotation(mpParentModel);
      mPlacementAnnotation.deserialize(jsonObject.value("Placement").toObject());
    }

    if (jsonObject.contains("Dialog")) {
      mHasDialogAnnotation = true;
      mDialogAnnotation = DialogAnnotation();
      mDialogAnnotation.deserialize(jsonObject.value("Dialog").toObject());
    }

    if (jsonObject.contains("Evaluate")) {
      mEvaluate.deserialize(jsonObject.value("Evaluate"));
    }

    if (jsonObject.contains("choices")) {
      mChoices.deserialize(jsonObject.value("choices").toObject());
    }
    // Connection annotation
    if (jsonObject.contains("Line")) {
      mpLine = std::make_unique<Line>(mpParentModel);
      mpLine->deserialize(jsonObject.value("Line").toObject());
    }

    if (jsonObject.contains("Text")) {
      mpText = std::make_unique<Text>(mpParentModel);
      mpText->deserialize(jsonObject.value("Text").toObject());
    }
    // Extend annotation
    if (jsonObject.contains("IconMap")) {
      mIconMap.deserialize(jsonObject.value("IconMap").toObject());
    }

    if (jsonObject.contains("DiagramMap")) {
      mDiagramMap.deserialize(jsonObject.value("DiagramMap").toObject());
    }
  }

  IconDiagramAnnotation *Annotation::getIconAnnotation() const
  {
    return mpIconAnnotation ? mpIconAnnotation.get() : &IconDiagramAnnotation::defaultIconDiagramAnnotation;
  }

  IconDiagramAnnotation *Annotation::getDiagramAnnotation() const
  {
    return mpDiagramAnnotation ? mpDiagramAnnotation.get() : &IconDiagramAnnotation::defaultIconDiagramAnnotation;
  }

  IconDiagramAnnotation IconDiagramAnnotation::defaultIconDiagramAnnotation{nullptr};

  IconDiagramAnnotation::IconDiagramAnnotation(Model *pParentModel)
  {
    mpParentModel = pParentModel;
  }

  IconDiagramAnnotation::~IconDiagramAnnotation()
  {
    qDeleteAll(mGraphics);
  }

  void IconDiagramAnnotation::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("coordinateSystem")) {
      mCoordinateSystem.deserialize(jsonObject.value("coordinateSystem").toObject());
      mMergedCoOrdinateSystem = mCoordinateSystem;
    }

    if (jsonObject.contains("graphics")) {
      if (jsonObject.value("graphics").isObject()) {
        QJsonObject graphicsObject = jsonObject.value("graphics").toObject();
        if (graphicsObject.contains("$error")) {
          MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, graphicsObject.value("$error").toString(), Helper::scriptingKind, Helper::errorLevel));
        }
      } else if (jsonObject.value("graphics").isArray()) {
        QJsonArray graphicsArray = jsonObject.value("graphics").toArray();
        for (int i = 0; i < graphicsArray.size(); ++i) {
          QJsonObject graphicObject = graphicsArray.at(i).toObject();
          if (graphicObject.contains("name") && graphicObject.contains("elements")) {
            const QString name = graphicObject.value("name").toString();
            if (name.compare(QStringLiteral("Line")) == 0) {
              Line *pLine = new Line(mpParentModel);
              pLine->deserialize(graphicObject.value("elements").toArray());
              mGraphics.append(pLine);
            } else if (name.compare(QStringLiteral("Polygon")) == 0) {
              Polygon *pPolygon = new Polygon(mpParentModel);
              pPolygon->deserialize(graphicObject.value("elements").toArray());
              mGraphics.append(pPolygon);
            } else if (name.compare(QStringLiteral("Rectangle")) == 0) {
              Rectangle *pRectangle = new Rectangle(mpParentModel);
              pRectangle->deserialize(graphicObject.value("elements").toArray());
              mGraphics.append(pRectangle);
            } else if (name.compare(QStringLiteral("Ellipse")) == 0) {
              Ellipse *pEllipse = new Ellipse(mpParentModel);
              pEllipse->deserialize(graphicObject.value("elements").toArray());
              mGraphics.append(pEllipse);
            } else if (name.compare(QStringLiteral("Text")) == 0) {
              Text *pText = new Text(mpParentModel);
              pText->deserialize(graphicObject.value("elements").toArray());
              mGraphics.append(pText);
            } else if (name.compare(QStringLiteral("Bitmap")) == 0) {
              Bitmap *pBitmap = new Bitmap(mpParentModel);
              pBitmap->deserialize(graphicObject.value("elements").toArray());
              mGraphics.append(pBitmap);
            }
          }
        }
      }
    }
  }

  Dimensions::Dimensions()
  {
    mAbsynDims.clear();
    mTypedDims.clear();
  }

  void Dimensions::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("absyn")) {
      QJsonArray absynDimsArray = jsonObject.value("absyn").toArray();
      foreach (auto absynDim, absynDimsArray) {
        mAbsynDims.append(absynDim.toString());
      }
    }

    if (jsonObject.contains("typed")) {
      QJsonArray typedDimsArray = jsonObject.value("typed").toArray();
      foreach (auto typedDim, typedDimsArray) {
        mTypedDims.append(typedDim.toString());
      }
    }
  }

  Modifier::Modifier()
  {
    mName = "";
    mValue = "";
    mFinal = false;
    mEach = false;
    mModifiers.clear();
  }

  void Modifier::deserialize(const QJsonValue &jsonValue)
  {
    if (jsonValue.isObject()) {
      QJsonObject modifiers = jsonValue.toObject();
      for (QJsonObject::iterator modifiersIterator = modifiers.begin(); modifiersIterator != modifiers.end(); ++modifiersIterator) {
        const QString modifierKey = modifiersIterator.key();
        const QJsonValue modifierValue = modifiersIterator.value();
        if (modifierKey.compare(QStringLiteral("$value")) == 0) {
          mValue = modifierValue.toString();
        } else if (modifierKey.compare(QStringLiteral("final")) == 0) {
          mFinal = true;
        } else if (modifierKey.compare(QStringLiteral("each")) == 0) {
          mEach = true;
        } else {
          Modifier modifier;
          modifier.setName(modifierKey);
          modifier.deserialize(modifierValue);
          mModifiers.append(modifier);
        }
      }
    } else {
      mValue = jsonValue.toString();
    }
  }

  QString Modifier::getValueWithSubModifiers() const
  {
    if (mModifiers.isEmpty()) {
      return mValue;
    } else {
      QStringList modifiers;
      foreach (auto subModifier, mModifiers) {
        if (subModifier.getModifiers().isEmpty()) {
          modifiers.append(subModifier.getName() % "=" % subModifier.getValue());
        } else {
          modifiers.append(subModifier.getName() % subModifier.getValueWithSubModifiers());
        }
      }
      return "(" % modifiers.join(",") % ")";
    }
  }

  QString Modifier::getModifier(const QString &m) const
  {
    foreach (auto modifier, mModifiers) {
      if (modifier.getName().compare(m) == 0) {
        return modifier.getValue();
      }
    }
    return "";
  }

  bool Modifier::hasModifier(const QString &m) const
  {
    foreach (auto modifier, mModifiers) {
      if (modifier.getName().compare(m) == 0) {
        return true;
      }
    }
    return false;
  }

  QString Modifier::getModifierValue(QStringList qualifiedModifierName) const
  {
    if (qualifiedModifierName.isEmpty()) {
      return "";
    }

    /* Fixes issues #10819 and #10846.
     * There is no sequence point between function arguments so call qualifiedModifierName.takeFirst() before calling the Modifier::getModifierValue function
     * so correct list items are passed to the function.
     */
    const QString name = qualifiedModifierName.takeFirst();
    return Modifier::getModifierValue(*this, name, qualifiedModifierName);
  }

  QString Modifier::getModifierValue(const Modifier &modifier, const QString &modifierName, QStringList qualifiedModifierName)
  {
    foreach (auto subModifier, modifier.getModifiers()) {
      if (subModifier.getName().compare(modifierName) == 0) {
        if (qualifiedModifierName.isEmpty()) {
          return subModifier.getValueWithoutQuotes();
        } else {
          const QString name = qualifiedModifierName.takeFirst();
          return Modifier::getModifierValue(subModifier, name, qualifiedModifierName);
        }
      }
    }

    return "";
  }

  Replaceable::Replaceable(Model *pParentModel)
  {
    mpParentModel = pParentModel;
    mConstrainedby = "";
    mComment = "";
  }

  void Replaceable::deserialize(const QJsonValue &jsonValue)
  {
    if (jsonValue.isObject()) {
      QJsonObject replaceableObject = jsonValue.toObject();
      mConstrainedby = replaceableObject.value("constrainedby").toString();

      if (replaceableObject.contains("modifiers")) {
        mModifier.deserialize(replaceableObject.value("modifiers"));
      }

      if (replaceableObject.contains("comment")) {
        mComment = replaceableObject.value("comment").toString();
      }

      if (replaceableObject.contains("annotation")) {
        mpAnnotation = std::make_unique<Annotation>(mpParentModel);
        mpAnnotation->deserialize(replaceableObject.value("annotation").toObject());
      }
    }
  }

  Prefixes::Prefixes(Model *pParentModel)
  {
    mpParentModel = pParentModel;
    mPublic = true;
    mFinal = false;
    mInner = false;
    mOuter = false;
    mRedeclare = false;
    mPartial = false;
    mEncapsulated = false;
    mConnector = "";
    mVariability = "";
    mDirection = "";
  }

  void Prefixes::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("public")) {
      mPublic = jsonObject.value("public").toBool();
    }

    if (jsonObject.contains("final")) {
      mFinal = jsonObject.value("final").toBool();
    }

    if (jsonObject.contains("inner")) {
      mInner = jsonObject.value("inner").toBool();
    }

    if (jsonObject.contains("outer")) {
      mOuter = jsonObject.value("outer").toBool();
    }

    if (jsonObject.contains("replaceable")) {
      mpReplaceable = std::make_unique<Replaceable>(mpParentModel);
      mpReplaceable->deserialize(jsonObject.value("replaceable"));
    }

    if (jsonObject.contains("redeclare")) {
      mRedeclare = jsonObject.value("redeclare").toBool();
    }

    if (jsonObject.contains("partial")) {
      mPartial = jsonObject.value("partial").toBool();
    }

    if (jsonObject.contains("encapsulated")) {
      mEncapsulated = jsonObject.value("encapsulated").toBool();
    }

    if (jsonObject.contains("connector")) {
      mConnector = jsonObject.value("connector").toString();
    }

    if (jsonObject.contains("variability")) {
      mVariability = jsonObject.value("variability").toString();
    }

    if (jsonObject.contains("direction")) {
      mDirection = jsonObject.value("direction").toString();
    }
  }

  Source::Source()
  {
    mFileName = "";
    mLineStart = 0;
    mColumnStart = 0;
    mLineEnd = 0;
    mColumnEnd = 0;
    mReadonly = false;
  }

  void Source::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("filename")) {
      mFileName = jsonObject.value("filename").toString();
    }

    if (jsonObject.contains("lineStart")) {
      mLineStart = jsonObject.value("lineStart").toInt();
    }

    if (jsonObject.contains("columnStart")) {
      mColumnStart = jsonObject.value("columnStart").toInt();
    }

    if (jsonObject.contains("lineEnd")) {
      mLineEnd = jsonObject.value("lineEnd").toInt();
    }

    if (jsonObject.contains("columnEnd")) {
      mColumnEnd = jsonObject.value("columnEnd").toInt();
    }

    if (jsonObject.contains("readonly")) {
      mReadonly = jsonObject.value("readonly").toBool();
    }
  }

  Model::Model(const QJsonObject &jsonObject, Element *pParentElement)
  {
    mpParentElement = pParentElement;
    initialize();
    mModelJson = jsonObject;
    deserialize();
  }

  Model::~Model()
  {
    qDeleteAll(mElements);
    mElements.clear();

    qDeleteAll(mConnections);
    mConnections.clear();

    qDeleteAll(mTransitions);
    mTransitions.clear();

    qDeleteAll(mInitialStates);
    mInitialStates.clear();
  }

  void Model::deserialize()
  {
    if (mModelJson.contains("name")) {
      mName = mModelJson.value("name").toString();
    }

    if (mModelJson.contains("missing")) {
      mMissing = mModelJson.value("missing").toBool();
    }

    if (mModelJson.contains("dims")) {
      mDims.deserialize(mModelJson.value("dims").toObject());
    }

    if (mModelJson.contains("restriction")) {
      mRestriction = mModelJson.value("restriction").toString();
    }

    if (mModelJson.contains("prefixes")) {
      mpPrefixes = std::make_unique<Prefixes>(this);
      mpPrefixes->deserialize(mModelJson.value("prefixes").toObject());
    }

    QJsonArray elements = mModelJson.value("elements").toArray();

    foreach (const QJsonValue &element, elements) {
      QJsonObject elementObject = element.toObject();
      QString kind = elementObject.value("$kind").toString();

      if (kind.compare(QStringLiteral("extends")) == 0) {
        mElements.append(new Extend(this, elementObject));
      } else if (kind.compare(QStringLiteral("component")) == 0) {
        mElements.append(new Component(this, elementObject));
      } else if (kind.compare(QStringLiteral("class")) == 0) {
        mElements.append(new ReplaceableClass(this, elementObject));
      } else {
        qDebug() << "Unhandled kind of element" << kind;
      }
    }

    if (mModelJson.contains("comment")) {
      mComment = mModelJson.value("comment").toString();
    }

    if (mModelJson.contains("annotation")) {
      mpAnnotation = std::make_unique<Annotation>(this);
      mpAnnotation->deserialize(mModelJson.value("annotation").toObject());
    }

    /* From Modelica Specification Version 3.5-dev
     * The coordinate system (including preserveAspectRatio) of a class is defined by the following priority:
     * 1. The coordinate system annotation given in the class (if specified).
     * 2. The coordinate systems of the first base-class where the extent on the extends-clause specifies a
     *    null-region (if any). Note that null-region is the default for base-classes, see section 18.6.3.
     * 3. The default coordinate system CoordinateSystem(extent={{-100, -100}, {100, 100}}).
     *
     * Following is the second case. First case is covered when we read the annotation of the class. Third case is handled by default values of IconDiagramAnnotation class.
     */
    if (!getAnnotation()->getIconAnnotation()->mMergedCoOrdinateSystem.isComplete()) {
      readCoordinateSystemFromExtendsClass(&getAnnotation()->getIconAnnotation()->mMergedCoOrdinateSystem, true);
    }

    if (!getAnnotation()->getDiagramAnnotation()->mMergedCoOrdinateSystem.isComplete()) {
      readCoordinateSystemFromExtendsClass(&getAnnotation()->getDiagramAnnotation()->mMergedCoOrdinateSystem, false);
    }

    if (mModelJson.contains("connections")) {
      QJsonArray connections = mModelJson.value("connections").toArray();
      foreach (QJsonValue connection, connections) {
        QJsonObject connectionObject = connection.toObject();
        if (!connectionObject.isEmpty()) {
          Connection *pConnection = new Connection(this);
          pConnection->deserialize(connection.toObject());
          mConnections.append(pConnection);
        }
      }
    }

    if (mModelJson.contains("transitions")) {
      QJsonArray transitions = mModelJson.value("transitions").toArray();
      foreach (QJsonValue transition, transitions) {
        QJsonObject transitionObject = transition.toObject();
        if (!transitionObject.isEmpty()) {
          Transition *pTransition = new Transition(this);
          pTransition->deserialize(transition.toObject());
          mTransitions.append(pTransition);
        }
      }
    }

    if (mModelJson.contains("initialStates")) {
      QJsonArray initialStates = mModelJson.value("initialStates").toArray();
      foreach (QJsonValue initialState, initialStates) {
        QJsonObject initialStateObject = initialState.toObject();
        if (!initialStateObject.isEmpty()) {
          InitialState *pInitialState = new InitialState(this);
          pInitialState->deserialize(initialState.toObject());
          mInitialStates.append(pInitialState);
        }
      }
    }

    if (mModelJson.contains("source")) {
      mSource.deserialize(mModelJson.value("source").toObject());
    }
  }

  Extend *Model::getParentExtend() const
  {
    if (mpParentElement && mpParentElement->isExtend()) {
      return dynamic_cast<ModelInstance::Extend*>(mpParentElement);
    } else {
      return 0;
    }
  }

  Component *Model::getParentComponent() const
  {
    if (mpParentElement && mpParentElement->isComponent()) {
      return dynamic_cast<ModelInstance::Component*>(mpParentElement);
    } else {
      return 0;
    }
  }

  const QString &Model::getRootType() const
  {
    if (isDerivedType() && mElements.size() > 0) {
      return mElements.at(0)->getRootType();
    }
    return mName;
  }

  bool Model::isConnector() const
  {
    if (isExpandableConnector() || (mRestriction.compare(QStringLiteral("connector")) == 0)) {
      return true;
    }
    return false;
  }

  bool Model::isExpandableConnector() const
  {
    return (mRestriction.compare(QStringLiteral("expandable connector")) == 0);
  }

  bool Model::isEnumeration() const
  {
    return (mRestriction.compare(QStringLiteral("enumeration")) == 0);
  }

  bool Model::isType() const
  {
    return (mRestriction.compare(QStringLiteral("type")) == 0);
  }

  /*!
   * \brief Model::isDerivedType
   * Returns true if the class is a type or a class derived from a type, otherwise false.
   * \return
   */
  bool Model::isDerivedType() const
  {
    if (isType()) return true;

    if (mElements.size() > 0 && mElements[0]->isExtend()) {
      if (mElements[0]->getModel()) {
        return mElements[0]->getModel()->isDerivedType();
      } else {
        return true;
      }
    }

    return false;
  }

  /*!
   * \brief Model::getDirection
   * Returns the direction of the model, either from the declaration or in the
   * case of a short class definition from the extended class.
   * \return
   */
  QString Model::getDirection() const
  {
    QString dir;

    if (mpPrefixes) {
      dir = mpPrefixes->getDirection();
    }

    if (dir.isEmpty() && mElements.size() == 1 && mElements.at(0)->isExtend()) {
      auto m = mElements.at(0)->getModel();
      if (m) {
        dir = m->getDirection();
      }
    }

    return dir;
  }

  Annotation *Model::getAnnotation() const
  {
    return mpAnnotation ? mpAnnotation.get() : &Annotation::defaultAnnotation;
  }

  void Model::readCoordinateSystemFromExtendsClass(CoordinateSystem *pCoordinateSystem, bool isIcon)
  {
    /* From Modelica Specification Version 3.6-dev
     * The coordinate system attributes (extent and preserveAspectRatio) of a class are separately defined by the following priority:
     * 1. The coordinate system annotation given in the class (if specified).
     * 2. The coordinate systems of the first base-class where the extent on the extends-clause specifies a
     *    null-region (if any). Note that null-region is the default for base-classes, see section 18.6.1.1.
     * 3. The default coordinate system CoordinateSystem(extent={{-100, -100}, {100, 100}}).
     *
     * Following is the second case.
     */
    foreach (auto pElement, mElements) {
      if (pElement->isExtend() && pElement->getModel()) {
        auto pExtend = dynamic_cast<Extend*>(pElement);
        ModelInstance::CoordinateSystem coordinateSystem;
        if (isIcon) {
          coordinateSystem = pExtend->getModel()->getAnnotation()->getIconAnnotation()->mCoordinateSystem;
        } else {
          coordinateSystem = pExtend->getModel()->getAnnotation()->getDiagramAnnotation()->mCoordinateSystem;
        }

        if (!pCoordinateSystem->hasExtent() && coordinateSystem.hasExtent()) {
          pCoordinateSystem->setExtent(coordinateSystem.getExtent());
        }
        if (!pCoordinateSystem->hasPreserveAspectRatio() && coordinateSystem.hasPreserveAspectRatio()) {
          pCoordinateSystem->setPreserveAspectRatio(coordinateSystem.getPreserveAspectRatio());
        }

        if (!pCoordinateSystem->isComplete()) {
          pExtend->getModel()->readCoordinateSystemFromExtendsClass(pCoordinateSystem, isIcon);
        }
        break; // we only check coordinate system of first inherited class. See the comment in start of function i.e., "The coordinate systems of the first base-class ..."
      }
    }
  }

  /*!
   * \brief Model::getComponents
   * Returns all components of the model, including inherited ones.
   */
  QList<Element *> Model::getComponents() const
  {
    QList<Element *> comps;

    foreach (auto pElement, mElements) {
      if (pElement->isExtend() && pElement->getModel()) {
        comps.append(pElement->getModel()->getComponents());
      } else if (pElement->isComponent()) {
        comps.append(pElement);
      }
    }

    return comps;
  }

  bool Model::isParameterConnectorSizing(const QString &parameter)
  {
    foreach (auto pElement, mElements) {
      if (pElement->isComponent()) {
        auto pComponent = dynamic_cast<Component*>(pElement);
        if (pComponent->getName().compare(parameter) == 0) {
          return pComponent->getAnnotation()->getDialogAnnotation().isConnectorSizing();
        }
      }
    }
    return false;
  }

  bool isOutsideConnector(const Name &connector, const Model &model)
  {
    // An outside connector is a connector where the first part of the name is a
    // connector. This is automatically true for a simple name.
    if (connector.size() == 1) return true;

    auto elem = model.lookupElement(connector.first().getName(false));
    return elem && elem->getModel() && elem->getModel()->isConnector();
  }

  bool Model::isValidConnection(const Name &lhsConnector, const Name &rhsConnector) const
  {
    const Element *lhs = lookupElement(lhsConnector);
    const Element *rhs = lookupElement(rhsConnector);

    if (!lhs || !rhs) {
      qDebug() << "Failed to find connector " << (lhs ? rhsConnector : lhsConnector).getName();
      return true;
    }

    // A inside output should not be connected to an inside output,
    // or a public outside input to a public outside input.
    auto dir = lhs->getDirection();
    if (!dir.isEmpty() && dir == rhs->getDirection()) {
      auto lhs_outside = isOutsideConnector(lhsConnector, *this);
      auto rhs_outside = isOutsideConnector(rhsConnector, *this);

      if (dir == "output" && !lhs_outside && !rhs_outside) {
        return false;
      } else if (dir == "input" && lhs_outside && rhs_outside && lhs->isPublic() && rhs->isPublic()) {
        return false;
      }
    }

    // Check that the connectors are type compatible.
    Model *lhs_model = lhs->getModel();
    Model *rhs_model = rhs->getModel();

    if (!lhs_model || !rhs_model) return false;

    return lhs_model->isTypeCompatibleWith(*rhs_model);
  }

  bool Model::isTypeCompatibleWith(const Model &other) const
  {
    if (isExpandableConnector() || other.isExpandableConnector()) {
      // Don't type check expandable connectors, since we don't really know what
      // they contain here.
      return true;
    } else if (isConnector() && other.isConnector()) {
      if (isDerivedType()) {
        // If the connectors are derived from types, then they must have the same root type.
        return getRootType() == other.getRootType();
      } else {
        // If they are not types, then check the components they contain.
        auto comps = getComponents();

        // The connectors must contain the same number of components.
        if (comps.size() != other.getComponents().size()) return false;

        // The connectors must contain the same named components, but the order
        // doesn't matter.
        foreach (auto e1, comps) {
          if (e1->isComponent()) {
            auto e2 = other.lookupElement(e1->getName());

            if (e2) {
              // The component exists, check that it's type compatible with e1.
              auto m1 = e1->getModel();
              auto m2 = e2->getModel();

              if (m1 && m2 && !m1->isTypeCompatibleWith(*m2)) {
                return false;
              }

              // The components should not have the same input/output prefix.
              auto dir = e1->getDirection();
              if (!dir.isEmpty() && dir == e2->getDirection()) {
                return false;
              }
            } else {
              // The component doesn't exist, the connectors are not type compatible.
              return false;
            }
          }
        }
      }
    } else if (isType()) {
      // Types, check that they're derived from the same basic type.
      return getRootType() == other.getRootType();
    } else {
      // Any other type of class, check that their components are type compatible.
      auto comps1 = getComponents();
      auto comps2 = other.getComponents();

      if (comps1.size() != comps2.size()) return false;

      for (int i = 0; i < comps1.size(); ++i) {
        auto m1 = comps1.at(i)->getModel();
        auto m2 = comps2.at(i)->getModel();

        if (m1 && m2 && !m1->isTypeCompatibleWith(*m2)) {
          return false;
        }
      }
    }

    return true;
  }

  QString Model::getParameterValue(const QString &parameter, QString &typeName)
  {
    QString value = "";
    foreach (auto pElement, mElements) {
      if (pElement->isComponent()) {
        auto pComponent = dynamic_cast<Component*>(pElement);
        if (pComponent->getName().compare(StringHandler::getFirstWordBeforeDot(parameter)) == 0) {
          value = pComponent->getModifier().getValueWithoutQuotes();
          // Fixes issue #7493. Handles the case where value is from instance name e.g., %instanceName.parameterName
          if (value.isEmpty() && pComponent->getModel()) {
            value = pComponent->getModel()->getParameterValue(StringHandler::getLastWordAfterDot(parameter), typeName);
          }
          typeName = pComponent->getType();
          break;
        }
      }
    }
    return value;
  }

  QString Model::getParameterValueFromExtendsModifiers(const QString &parameter)
  {
    QString value = "";
    foreach (auto pElement, mElements) {
      if (pElement->isExtend()) {
        auto pExtend = dynamic_cast<Extend*>(pElement);
        value = pExtend->getModifier().getModifierValue(QStringList() << parameter);
        if (!value.isEmpty()) {
          return value;
        } else {
          if (pExtend->getModel()) {
            value = pExtend->getModel()->getParameterValueFromExtendsModifiers(parameter);
            if (!value.isEmpty()) {
              return value;
            }
          }
        }
      }
    }

    return value;
  }

  FlatModelica::Expression* Model::getVariableBinding(const QString &variableName)
  {
    foreach (auto pElement, mElements) {
      if (pElement->isComponent()) {
        if (pElement->getName().compare(variableName) == 0) {
          return &pElement->getBinding();
        }
      } else if (pElement->isExtend() && pElement->getModel()) {
        auto expression = pElement->getModel()->getVariableBinding(variableName);
        if (expression) return expression;
      }
    }

    return nullptr;
  }

  const Element *Model::lookupElement(const QString &name) const
  {
    foreach (auto pElement, mElements) {
      if (pElement->isExtend() && pElement->getModel()) {
        auto e = pElement->getModel()->lookupElement(name);
        if (e) return e;
      } else if (pElement->getName() == name) {
        return pElement;
      }
    }

    return nullptr;
  }

  Element *Model::lookupElement(const QString &name)
  {
    return const_cast<Element*>(const_cast<const Model*>(this)->lookupElement(name));
  }

  const Element *Model::lookupElement(const Name &name) const
  {
    const Element *e = nullptr;
    const Model *model = this;

    foreach (const auto &part, name.getParts()) {
      if (!model) break;
      e = model->lookupElement(part.getName(false));
      if (!e) break;
      model = e->getModel();
    }

    return e;
  }

  Element *Model::lookupElement(const Name &name)
  {
    return const_cast<Element*>(const_cast<const Model*>(this)->lookupElement(name));
  }

  void Model::initialize()
  {
    mModelJson = QJsonObject();
    mName = "";
    mMissing = false;
    mRestriction = "";
    mComment = "";
    mElements.clear();
    mConnections.clear();
    mTransitions.clear();
    mInitialStates.clear();
  }

  Transformation::Transformation()
  {
    mOrigin = QPointF(0, 0);
    mExtent.clear();
    mExtent = QVector<QPointF>(2, QPointF(0, 0));
    mRotation = 0;
  }

  void Transformation::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("origin")) {
      mOrigin.deserialize(jsonObject.value("origin"));
    }
    if (jsonObject.contains("extent")) {
      mExtent.deserialize(jsonObject.value("extent"));
    }
    if (jsonObject.contains("rotation")) {
      mRotation.deserialize(jsonObject.value("rotation"));
    }
  }

  PlacementAnnotation::PlacementAnnotation(Model *pParentModel)
  {
    mpParentModel = pParentModel;
    // set the visible to false. Otherwise we get elements in the center of the view.
    mVisible = false;
    mIconVisible = false;
  }

  void PlacementAnnotation::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("visible")) {
      mVisible.deserialize(jsonObject.value("visible"));
    } else {
      // if there is no visible then assume it to be true.
      mVisible = true;
    }

    if (jsonObject.contains("transformation")) {
      mTransformation.deserialize(jsonObject.value("transformation").toObject());
    }

    if (jsonObject.contains("iconVisible")) {
      mIconVisible.deserialize(jsonObject.value("iconVisible"));
    } else {
      mIconVisible = mVisible;
    }

    if (jsonObject.contains("iconTransformation")) {
      mIconTransformation.deserialize(jsonObject.value("iconTransformation").toObject());
    } else {
      mIconTransformation = mTransformation;
    }
  }

  Selector::Selector()
  {
    mFilter = "-";
    mCaption = "-";
  }

  void Selector::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("filter")) {
      mFilter.deserialize(jsonObject.value("filter"));
    }

    if (jsonObject.contains("caption")) {
      mCaption.deserialize(jsonObject.value("caption"));
    }
  }

  DialogAnnotation::DialogAnnotation()
  {
    mTab = "General";
    mGroup = "";
    mEnable = true;
    mShowStartAttribute = false;
    mColorSelector = false;
    mGroupImage = "";
    mConnectorSizing = false;
  }

  void DialogAnnotation::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("tab")) {
      mTab.deserialize(jsonObject.value("tab"));
    }

    if (jsonObject.contains("group")) {
      mGroup.deserialize(jsonObject.value("group"));
    }

    if (jsonObject.contains("enable")) {
      mEnable.deserialize(jsonObject.value("enable"));
    }

    if (jsonObject.contains("showStartAttribute")) {
      mShowStartAttribute.deserialize(jsonObject.value("showStartAttribute"));
    }

    if (jsonObject.contains("colorSelector")) {
      mColorSelector.deserialize(jsonObject.value("colorSelector"));
    }

    if (jsonObject.contains("loadSelector")) {
      mLoadSelector.deserialize(jsonObject.value("loadSelector").toObject());
    }

    if (jsonObject.contains("saveSelector")) {
      mSaveSelector.deserialize(jsonObject.value("saveSelector").toObject());
    }

    if (jsonObject.contains("directorySelector")) {
      mDirectorySelector.deserialize(jsonObject.value("directorySelector").toObject());
    }

    if (jsonObject.contains("groupImage")) {
      mGroupImage.deserialize(jsonObject.value("groupImage"));
    }

    if (jsonObject.contains("connectorSizing")) {
      mConnectorSizing.deserialize(jsonObject.value("connectorSizing"));
    }
  }

  Choices::Choices()
  {
    mCheckBox = false;
    mDymolaCheckBox = false;
    mChoices.clear();
  }

  void Choices::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("checkBox")) {
      mCheckBox.deserialize(jsonObject.value("checkBox"));
    }

    if (jsonObject.contains("__Dymola_checkBox")) {
      mDymolaCheckBox.deserialize(jsonObject.value("__Dymola_checkBox"));
    }

    if (jsonObject.contains("choice")) {
      QJsonArray choices = jsonObject.value("choice").toArray();
      foreach (auto choice, choices) {
        QString type = "";
        if (choice.isObject()) {
          QJsonObject choiceObject = choice.toObject();
          if (choiceObject.contains("$type")) {
            type = choiceObject.value("$type").toString();
          }
          if (choiceObject.contains("$value")) {
            mChoices.append(qMakePair(choiceObject.value("$value").toString(), type));
          }
        } else {
          mChoices.append(qMakePair(choice.toString(), type));
        }
      }
    }
  }

  QStringList Choices::getChoices() const
  {
    QStringList choices;
    foreach (Choice choice, mChoices) {
      choices.append(choice.first);
    }
    return choices;
  }

  Element::Element(Model *pParentModel)
  {
    mpParentModel = pParentModel;
    mComment = "";
  }

  Element::~Element()
  {
    if (mpModel) {
      delete mpModel;
    }
  }

  void Element::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("modifiers")) {
      mModifier.deserialize(jsonObject.value("modifiers"));
    }

    if (jsonObject.contains("comment")) {
      mComment = jsonObject.value("comment").toString();
    }

    if (jsonObject.contains("annotation")) {
      mpAnnotation = std::make_unique<Annotation>(mpParentModel);
      mpAnnotation->deserialize(jsonObject.value("annotation").toObject());
    }

    deserialize_impl(jsonObject);
  }

  /*!
   * \brief Element::getTopLevelExtendName
   * Returns the top level extend name where the element is located.
   * \return
   */
  QString Element::getTopLevelExtendName() const
  {
    Element *pElement = mpParentModel->getParentElement();
    while (pElement && pElement->getParentModel() && pElement->getParentModel()->getParentElement()) {
      pElement = pElement->getParentModel()->getParentElement();
    }

    if (pElement->getModel()) {
      return pElement->getModel()->getName();
    } else {
      return mpParentModel->getName();
    }
  }

  QString Element::getModifierValueFromType(QStringList modifierNames)
  {
    /* 1. First check if unit is defined with in the component modifier.
     * 2. If no unit is found then check it in the derived class modifier value recursively.
     */
    // Case 1
    QString modifierValue = mModifier.getModifierValue(modifierNames);
    if (modifierValue.isEmpty() && mpModel) {
      // Case 2
      if (modifierValue.isEmpty()) {
        modifierValue = Element::getModifierValueFromInheritedType(mpModel, modifierNames);
      }
    }
    return modifierValue;
  }

  bool Element::isPublic() const
  {
    return mpPrefixes ? mpPrefixes.get()->isPublic() : true;
  }

  bool Element::isFinal() const
  {
    return mpPrefixes ? mpPrefixes.get()->isFinal() : false;
  }

  bool Element::isInner() const
  {
    return mpPrefixes ? mpPrefixes.get()->isInner() : false;
  }

  bool Element::isOuter() const
  {
    return mpPrefixes ? mpPrefixes.get()->isOuter() : false;
  }

  Replaceable *Element::getReplaceable() const
  {
    return mpPrefixes ? mpPrefixes.get()->getReplaceable() : nullptr;
  }

  QString Element::getConnector() const
  {
    return mpPrefixes ? mpPrefixes.get()->getConnector() : "";
  }

  QString Element::getVariability() const
  {
    return mpPrefixes ? mpPrefixes.get()->getVariability() : "";
  }

  QString Element::getDirectionPrefix() const
  {
    return mpPrefixes ? mpPrefixes.get()->getDirection() : "";
  }

  /*!
   * \brief Component::getComment
   * Returns the Component comment.
   * Prefer the comment given in replaceable part.
   * \return
   */
  const QString& Element::getComment() const
  {
    if (mpPrefixes && mpPrefixes->getReplaceable() && !mpPrefixes->getReplaceable()->getComment().isEmpty()) {
      return mpPrefixes->getReplaceable()->getComment();
    } else {
      return mComment;
    }
  }

  /*!
   * \brief Element::getAnnotation
   * Returns the Element Annotation.
   * Prefer the annotation given in replaceable part.
   * \return
   */
  Annotation *Element::getAnnotation() const
  {
    if (mpPrefixes && mpPrefixes->getReplaceable() && mpPrefixes->getReplaceable()->getAnnotation()) {
      return mpPrefixes->getReplaceable()->getAnnotation();
    } else if (mpAnnotation) {
      return mpAnnotation.get();
    } else {
      return &Annotation::defaultAnnotation;
    }
  }

  /*!
   * \brief Element::getDirection
   * Returns the direction of the element, either from the element itself or
   * from its type.
   * \return
   */
  QString Element::getDirection() const
  {
    QString dir;

    if (mpPrefixes) {
      dir = mpPrefixes->getDirection();
    }

    if (dir.isEmpty() && mpModel) {
      dir = mpModel->getDirection();
    }

    return dir;
  }

  QString Element::getModifierValueFromInheritedType(Model *pModel, QStringList modifierNames)
  {
    QString modifierValue = "";
    foreach (auto pElement, pModel->getElements()) {
      if (pElement->isExtend()) {
        auto pExtend = dynamic_cast<Extend*>(pElement);
        modifierValue = pExtend->getModifier().getModifierValue(modifierNames);
        if (modifierValue.isEmpty() && pExtend->getModel()) {
          modifierValue = Element::getModifierValueFromInheritedType(pExtend->getModel(), modifierNames);
        } else {
          return modifierValue;
        }
      }
    }
    return modifierValue;
  }

  Extend::Extend(Model *pParentModel, const QJsonObject &jsonObject)
    : Element(pParentModel)
  {
    deserialize(jsonObject);
  }

  void Extend::deserialize_impl(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("baseClass")) {
      if (jsonObject.value("baseClass").isString()) {
        mBaseClass = jsonObject.value("baseClass").toString();
      } else if (jsonObject.value("baseClass").isObject()) {
        mpModel = new Model(jsonObject.value("baseClass").toObject(), this);
        mBaseClass = mpModel->getName();
      }
    }
  }

  /*!
   * \brief Extend::getQualifiedName
   * Returns the qualified name of component.
   * \return
   */
  QString Extend::getQualifiedName() const
  {
    if (mpParentModel && mpParentModel->getParentElement()) {
      return mpParentModel->getParentElement()->getQualifiedName();
    } else {
      return "";
    }
  }

  const QString &Extend::getRootType() const
  {
    if (mpModel && mpModel->isDerivedType() && mpModel->getElements().size() > 0) {
      return mpModel->getElements().at(0)->getRootType();
    }
    return mBaseClass;
  }

  Component::Component(Model *pParentModel)
    : Element(pParentModel)
  {

  }

  Component::Component(Model *pParentModel, const QJsonObject &jsonObject)
    : Element(pParentModel)
  {
    deserialize(jsonObject);
  }

  void Component::deserialize_impl(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("name")) {
      mName = jsonObject.value("name").toString();
    }

    if (jsonObject.contains("condition")) {
      mCondition = jsonObject.value("condition").toBool(true);
    }

    if (jsonObject.contains("type")) {
      if (jsonObject.value("type").isString()) {
        mType = jsonObject.value("type").toString();
      } else if (jsonObject.value("type").isObject()) {
        mpModel = new Model(jsonObject.value("type").toObject(), this);
        mType = mpModel->getName();
      }
    }

    if (jsonObject.contains("value")) {
      QJsonObject valueObject = jsonObject.value("value").toObject();

      if (valueObject.contains("value")) {
        try {
          mBinding.deserialize(valueObject.value("value"));
          mBindingForReset = mBinding;
        } catch (const std::exception &e) {
          qDebug() << "Failed to deserialize json: " << valueObject.value("value");
          qDebug() << e.what();
        }
      } else if (valueObject.contains("binding")) {
        try {
          mBinding.deserialize(valueObject.value("binding"));
          mBindingForReset = mBinding;
        } catch (const std::exception &e) {
          qDebug() << "Failed to deserialize json: " << valueObject.value("binding");
          qDebug() << e.what();
        }
      }
    }

    if (jsonObject.contains("dims")) {
      mDims.deserialize(jsonObject.value("dims").toObject());
    }

    if (jsonObject.contains("prefixes")) {
      mpPrefixes = std::make_unique<Prefixes>(mpParentModel);
      mpPrefixes->deserialize(jsonObject.value("prefixes").toObject());
    }
  }

  /*!
   * \brief Component::getQualifiedName
   * Returns the qualified name of the component.
   * \return
   */
  QString Component::getQualifiedName() const
  {
    if (mpParentModel && mpParentModel->getParentElement()) {
      return mpParentModel->getParentElement()->getQualifiedName() % "." % mName;
    } else {
      return mName;
    }
  }

  const QString &Component::getRootType() const
  {
    if (mpModel && mpModel->isDerivedType() && mpModel->getElements().size() > 0) {
      return mpModel->getElements().at(0)->getRootType();
    }
    return mType;
  }

  ReplaceableClass::ReplaceableClass(Model *pParentModel, const QJsonObject &jsonObject)
    : Element(pParentModel)
  {
    mIsShortClassDefinition = false;
    deserialize(jsonObject);
  }

  void ReplaceableClass::deserialize_impl(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("name")) {
      mName = jsonObject.value("name").toString();
    }

    if (jsonObject.contains("restriction")) {
      mType = jsonObject.value("restriction").toString();
    }

    if (jsonObject.contains("prefixes")) {
      mpPrefixes = std::make_unique<Prefixes>(mpParentModel);
      mpPrefixes->deserialize(jsonObject.value("prefixes").toObject());
    }

    if (jsonObject.contains("baseClass")) {
      mIsShortClassDefinition = true;
      mBaseClass = jsonObject.value("baseClass").toString();
    }

    if (jsonObject.contains("dims")) {
      mDims.deserialize(jsonObject.value("dims").toObject());
    }

    if (jsonObject.contains("source")) {
      mSource.deserialize(jsonObject.value("source").toObject());
    }
  }

  QString ReplaceableClass::getQualifiedName() const
  {
    if (mpParentModel && mpParentModel->getParentElement()) {
      return mpParentModel->getParentElement()->getQualifiedName() % "." % mName;
    } else {
      return mName;
    }
  }

  Part::Part()
  {
    mName = "";
    mSubScripts.clear();
  }

  Part::Part(const QString &str)
  {
    int i = str.indexOf('[');

    if (i < 0) {
      mName = str;
    } else {
      mName = str.left(i);

      for (const auto& sub: str.midRef(i + 1, str.size() - i - 2).split(',')) {
        mSubScripts.append(sub.toString());
      }
    }
  }

  void Part::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("name")) {
      mName = jsonObject.value("name").toString();
    }

    if (jsonObject.contains("subscripts")) {
      QJsonArray subscripts = jsonObject.value("subscripts").toArray();
      foreach (QJsonValue subscript, subscripts) {
        mSubScripts.append(QString::number(subscript.toInt()));
      }
    }
  }

  QString Part::getName(bool includeSubscripts) const
  {
    if (mSubScripts.isEmpty() || !includeSubscripts) {
      return mName;
    } else {
      return mName % "[" % mSubScripts.join(",") % "]";
    }
  }

  Name::Name() = default;

  Name::Name(QString str)
  {
    while (!str.isEmpty()) {
      mParts.append(StringHandler::getFirstWordBeforeDot(str));
      auto next_str = StringHandler::removeFirstWordAfterDot(str);
      if (next_str.size() == str.size()) break;
      str = next_str;
    }
  }

  void Name::deserialize(const QJsonArray &jsonObject)
  {
    foreach (QJsonValue part, jsonObject) {
      Part partObject;
      partObject.deserialize(part.toObject());
      mParts.append(partObject);
    }
  }

  QString Name::getName() const
  {
    return getNameParts().join(".");
  }

  QStringList Name::getNameParts() const
  {
    QStringList parts;
    foreach (auto part, mParts) {
      parts.append(part.getName());
    }
    return parts;
  }

  Connector::Connector()
  {
    mKind = "";
  }

  void Connector::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("$kind")) {
      mKind = jsonObject.value("$kind").toString();
    }

    if (jsonObject.contains("parts")) {
      mName.deserialize(jsonObject.value("parts").toArray());
    }
  }

  QString Connector::getName() const
  {
    return mName.getName();
  }

  QStringList Connector::getNameParts() const
  {
    return mName.getNameParts();
  }

  Connection::Connection(Model *pParentModel)
  {
    mpParentModel = pParentModel;
  }

  void Connection::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("lhs")) {
      mpStartConnector = std::make_unique<Connector>();
      mpStartConnector->deserialize(jsonObject.value("lhs").toObject());
    }

    if (jsonObject.contains("rhs")) {
      mpEndConnector = std::make_unique<Connector>();
      mpEndConnector->deserialize(jsonObject.value("rhs").toObject());
    }

    if (jsonObject.contains("annotation")) {
      mpAnnotation = std::make_unique<Annotation>(mpParentModel);
      mpAnnotation->deserialize(jsonObject.value("annotation").toObject());
    }
  }

  Annotation *Connection::getAnnotation() const
  {
    return mpAnnotation ? mpAnnotation.get() : &Annotation::defaultAnnotation;
  }

  QString Connection::toString() const
  {
    return "connect(" % mpStartConnector->getName() % ", " % mpEndConnector->getName() % ")";
  }

  Transition::Transition(Model *pParentModel)
  {
    mpParentModel = pParentModel;
    mCondition = false;
    mImmediate = true;
    mReset = true;
    mSynchronize = false;
    mPriority = 1;
  }

  void Transition::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("arguments")) {
      QJsonArray arguments = jsonObject.value("arguments").toArray();
      if (arguments.size() > 6) {
        if (arguments.at(0).isObject()) {
          mpStartConnector = std::make_unique<Connector>();
          mpStartConnector->deserialize(arguments.at(0).toObject());
        }

        if (arguments.at(1).isObject()) {
          mpEndConnector = std::make_unique<Connector>();
          mpEndConnector->deserialize(arguments.at(1).toObject());
        }

        mCondition = arguments.at(2).toBool();
        mImmediate = arguments.at(3).toBool();
        mReset = arguments.at(4).toBool();
        mSynchronize = arguments.at(5).toBool();
        mPriority = arguments.at(6).toInt();
      }
    }

    if (jsonObject.contains("annotation")) {
      mpAnnotation = std::make_unique<Annotation>(mpParentModel);
      mpAnnotation->deserialize(jsonObject.value("annotation").toObject());
    }
  }

  Annotation *Transition::getAnnotation() const
  {
    return mpAnnotation ? mpAnnotation.get() : &Annotation::defaultAnnotation;
  }

  QString Transition::toString() const
  {
    QStringList transitionArgs;
    transitionArgs << mpStartConnector->getName()
                   << mpEndConnector->getName()
                   << QVariant(mCondition).toString()
                   << QVariant(mCondition).toString()
                   << QVariant(mImmediate).toString()
                   << QVariant(mReset).toString()
                   << QVariant(mSynchronize).toString()
                   << QString::number(mPriority);
    return "transition(" % transitionArgs.join(", ") % ")";
  }

  InitialState::InitialState(Model *pParentModel)
  {
    mpParentModel = pParentModel;
  }

  void InitialState::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("arguments")) {
      QJsonArray arguments = jsonObject.value("arguments").toArray();
      if (!arguments.isEmpty()) {
        if (arguments.at(0).isObject()) {
          mpStartConnector = std::make_unique<Connector>();
          mpStartConnector->deserialize(arguments.at(0).toObject());
        }
      }
    }

    if (jsonObject.contains("annotation")) {
      mpAnnotation = std::make_unique<Annotation>(mpParentModel);
      mpAnnotation->deserialize(jsonObject.value("annotation").toObject());
    }
  }

  Annotation *InitialState::getAnnotation() const
  {
    return mpAnnotation ? mpAnnotation.get() : &Annotation::defaultAnnotation;
  }

  QString InitialState::toString() const
  {
    return "initialState(" % mpStartConnector->getName() % ")";
  }

  IconDiagramMap::IconDiagramMap()
  {
    mExtent = QVector<QPointF>(2, QPointF(0, 0));
    mPrimitivesVisible = true;
  }

  void IconDiagramMap::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("extent")) {
      mExtent.deserialize(jsonObject.value("extent"));
    }

    if (jsonObject.contains("primitivesVisible")) {
      mPrimitivesVisible.deserialize(jsonObject.value("primitivesVisible"));
    }
  }

}
