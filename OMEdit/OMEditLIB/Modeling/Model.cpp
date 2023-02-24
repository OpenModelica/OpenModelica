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

  Annotation::Annotation(Model *pParentModel)
    : mPlacementAnnotation(pParentModel)
  {
    mpParentModel = pParentModel;
    mpIconAnnotation = std::make_unique<IconDiagramAnnotation>(pParentModel);
    mpDiagramAnnotation = std::make_unique<IconDiagramAnnotation>(pParentModel);
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
    mDialogAnnotation = DialogAnnotation();
  }

  void Annotation::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("Icon")) {
      mpIconAnnotation->deserialize(jsonObject.value("Icon").toObject());
    }

    if (jsonObject.contains("Diagram")) {
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

  IconDiagramAnnotation::IconDiagramAnnotation(Model *pParentModel)
  {
    mpParentModel = pParentModel;
    mGraphics.clear();
  }

  IconDiagramAnnotation::~IconDiagramAnnotation()
  {
    qDeleteAll(mGraphics);
    mGraphics.clear();
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

  QString Modifier::getModifierValue(QStringList qualifiedModifierName)
  {
    if (qualifiedModifierName.isEmpty()) {
      return "";
    }

    return Modifier::getModifierValue(*this, qualifiedModifierName.takeFirst(), qualifiedModifierName);
  }

  QString Modifier::getModifierValue(const Modifier &modifier, const QString &modifierName, QStringList qualifiedModifierName)
  {
    foreach (auto subModifier, modifier.getModifiers()) {
      if (subModifier.getName().compare(modifierName) == 0) {
        if (qualifiedModifierName.isEmpty()) {
          return subModifier.getValueWithoutQuotes();
        } else {
          return Modifier::getModifierValue(subModifier, qualifiedModifierName.takeFirst(), qualifiedModifierName);
        }
      }
    }

    return "";
  }

  Replaceable::Replaceable(Model *pParentModel)
  {
    mpParentModel = pParentModel;
    mIsReplaceable = false;
    mConstrainedby = "";
    mpAnnotation = std::make_unique<Annotation>(pParentModel);
  }

  void Replaceable::deserialize(const QJsonValue &jsonValue)
  {
    if (jsonValue.isObject()) {
      mIsReplaceable = true;
      QJsonObject replaceableObject = jsonValue.toObject();
      mConstrainedby = replaceableObject.value("constrainedby").toString();

      if (replaceableObject.contains("modifiers")) {
        mModifier.deserialize(replaceableObject.value("modifiers"));
      }

      if (replaceableObject.contains("comment")) {
        mComment = replaceableObject.value("comment").toString();
      }

      if (replaceableObject.contains("annotation")) {
        mpAnnotation->deserialize(replaceableObject.value("annotation").toObject());
      }
    } else {
      mIsReplaceable = jsonValue.toBool();
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

    if (mModelJson.contains("dims")) {
      QJsonObject dims = mModelJson.value("dims").toObject();

      if (dims.contains("absyn")) {
        QJsonArray dimsAbsynArray = dims.value("absyn").toArray();
        foreach (auto dim, dimsAbsynArray) {
          mDims.append(dim.toString());
        }
      }
    }

    if (mModelJson.contains("restriction")) {
      mRestriction = mModelJson.value("restriction").toString();
    }

    // short type definitions have modifiers
    if (mModelJson.contains("modifiers")) {
      mModifier.deserialize(mModelJson.value("modifiers"));
    }

    if (mModelJson.contains("prefixes")) {
      QJsonObject prefixes = mModelJson.value("prefixes").toObject();

      if (prefixes.contains("public")) {
        mPublic = prefixes.value("public").toBool();
      }

      if (prefixes.contains("final")) {
        mFinal = prefixes.value("final").toBool();
      }

      if (prefixes.contains("inner")) {
        mInner = prefixes.value("inner").toBool();
      }

      if (prefixes.contains("outer")) {
        mOuter = prefixes.value("outer").toBool();
      }

      if (prefixes.contains("replaceable")) {
        auto replaceable = prefixes.value("replaceble");

        if (replaceable.isObject()) {
          mReplaceable = true;
          // constrainedby stuff goes here
        } else {
          mReplaceable = replaceable.toBool();
        }
      }

      if (prefixes.contains("redeclare")) {
        mRedeclare = prefixes.value("redeclare").toBool();
      }

      if (prefixes.contains("partial")) {
        mPartial = prefixes.value("partial").toBool();
      }

      if (prefixes.contains("encapsulated")) {
        mEncapsulated = prefixes.value("encapsulated").toBool();
      }
    }

    QJsonArray elements = mModelJson.value("elements").toArray();

    foreach (const QJsonValue &element, elements) {
      QJsonObject elementObject = element.toObject();
      QString kind = elementObject.value("$kind").toString();

      if (kind == "extends") {
        mElements.append(new Extend(this, elementObject));
      } else if (kind == "component") {
        mElements.append(new Component(this, elementObject));
      } else {
        qDebug() << "Unhandled kind of element" << kind;
      }
    }

    if (mModelJson.contains("comment")) {
      mComment = mModelJson.value("comment").toString();
    }

    if (mModelJson.contains("annotation")) {
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
    if (!mpAnnotation->getIconAnnotation()->mMergedCoOrdinateSystem.isComplete()) {
      readCoordinateSystemFromExtendsClass(&mpAnnotation->getIconAnnotation()->mMergedCoOrdinateSystem, true);
    }

    if (!mpAnnotation->getDiagramAnnotation()->mMergedCoOrdinateSystem.isComplete()) {
      readCoordinateSystemFromExtendsClass(&mpAnnotation->getDiagramAnnotation()->mMergedCoOrdinateSystem, false);
    }

    if (mModelJson.contains("source")) {
      QJsonObject source = mModelJson.value("source").toObject();

      if (source.contains("filename")) {
        mFileName = source.value("filename").toString();
      }

      if (source.contains("lineStart")) {
        mLineStart = source.value("lineStart").toInt();
      }

      if (source.contains("columnStart")) {
        mColumnStart = source.value("columnStart").toInt();
      }

      if (source.contains("lineEnd")) {
        mLineEnd = source.value("lineEnd").toInt();
      }

      if (source.contains("columnEnd")) {
        mColumnEnd = source.value("columnEnd").toInt();
      }

      if (source.contains("readonly")) {
        mReadonly = source.value("readonly").toBool();
      }
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
        value = pExtend->getExtendsModifier().getModifierValue(QStringList() << parameter);
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

  FlatModelica::Expression Model::getVariableBinding(const QString &variableName)
  {
    FlatModelica::Expression expression;
    foreach (auto pElement, mElements) {
      if (pElement->isComponent()) {
        auto pComponent = dynamic_cast<Component*>(pElement);
        if (pComponent->getName().compare(variableName) == 0) {
          return pComponent->getBinding();
        }
      } else if (pElement->isExtend() && pElement->getModel()) {
        auto pExtend = dynamic_cast<Extend*>(pElement);
        expression = pExtend->getModel()->getVariableBinding(variableName);
        if (!expression.isNull()) {
          return expression;
        }
      }
    }

    return expression;
  }

  void Model::initialize()
  {
    mModelJson = QJsonObject();
    mDims.clear();
    mRestriction = "";
    mPublic = false;
    mFinal = false;
    mInner = false;
    mOuter = false;
    mReplaceable = false;
    mRedeclare = false;
    mPartial = false;
    mEncapsulated = false;
    mComment = "";
    mpAnnotation = std::make_unique<Annotation>(this);
    mElements.clear();
    mFileName = "";
    mLineStart = 0;
    mColumnStart = 0;
    mLineEnd = 0;
    mColumnEnd = 0;
    mReadonly = false;
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
        if (choice.isObject()) {
          QJsonObject choiceObject = choice.toObject();
          if (choiceObject.contains("$value")) {
            mChoice.append(choiceObject.value("$value").toString());
          }
        } else {
          mChoice.append(choice.toString());
        }
      }
    }
  }

  Element::Element(Model *pParentModel)
  {
    mpParentModel = pParentModel;
  }

  Element::~Element()
  {
    if (mpModel) {
      delete mpModel;
    }
  }

  Component::Component(Model *pParentModel)
    : Element(pParentModel)
  {
    initialize();
  }

  Component::Component(Model *pParentModel, const QJsonObject &jsonObject)
    : Element(pParentModel)
  {
    initialize();
    deserialize(jsonObject);
  }

  void Component::initialize()
  {
    mName = "";
    mCondition = true;
    mType = "";
    if (mpModel) {
      delete mpModel;
    }
    mpModel = 0;
    mAbsynDims.clear();
    mTypedDims.clear();
    mPublic = true;
    mFinal = false;
    mInner = false;
    mOuter = false;
    mpReplaceable = std::make_unique<Replaceable>(mpParentModel);
    mRedeclare = false;
    mConnector = "";
    mVariability = "";
    mDirection = "";
    mComment = "";
    mpAnnotation = std::make_unique<Annotation>(mpParentModel);
  }

  void Component::deserialize(const QJsonObject &jsonObject)
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

    if (jsonObject.contains("modifiers")) {
      mModifier.deserialize(jsonObject.value("modifiers"));
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
      QJsonObject dims = jsonObject.value("dims").toObject();

      if (dims.contains("absyn")) {
        QJsonArray absynDimsArray = dims.value("absyn").toArray();
        foreach (auto absynDim, absynDimsArray) {
          mAbsynDims.append(absynDim.toString());
        }
      }

      if (dims.contains("typed")) {
        QJsonArray typedDimsArray = dims.value("typed").toArray();
        foreach (auto typedDim, typedDimsArray) {
          mTypedDims.append(typedDim.toString());
        }
      }
    }

    if (jsonObject.contains("prefixes")) {
      QJsonObject prefixes = jsonObject.value("prefixes").toObject();

      if (prefixes.contains("public")) {
        mPublic = prefixes.value("public").toBool();
      }

      if (prefixes.contains("final")) {
        mFinal = prefixes.value("final").toBool();
      }

      if (prefixes.contains("inner")) {
        mInner = prefixes.value("inner").toBool();
      }

      if (prefixes.contains("outer")) {
        mOuter = prefixes.value("outer").toBool();
      }

      if (prefixes.contains("replaceable")) {
        mpReplaceable->deserialize(prefixes.value("replaceable"));
      }

      if (prefixes.contains("redeclare")) {
        mRedeclare = prefixes.value("redeclare").toBool();
      }

      if (prefixes.contains("connector")) {
        mConnector = prefixes.value("connector").toString();
      }

      if (prefixes.contains("variability")) {
        mVariability = prefixes.value("variability").toString();
      }

      if (prefixes.contains("direction")) {
        mDirection = prefixes.value("direction").toString();
      }

    }

    if (jsonObject.contains("comment")) {
      mComment = jsonObject.value("comment").toString();
    }

    if (jsonObject.contains("annotation")) {
      mpAnnotation->deserialize(jsonObject.value("annotation").toObject());
    }
  }

  QString Component::getModifierValueFromType(QStringList modifierNames)
  {
    /* 1. First check if unit is defined with in the component modifier.
     * 2. If no unit is found then check it in the derived class modifier value.
     * 3. A derived class can be inherited, so look recursively.
     */
    // Case 1
    QString modifierValue = mModifier.getModifierValue(modifierNames);
    if (modifierValue.isEmpty() && mpModel) {
      // Case 2
      modifierValue = mpModel->getModifier().getModifierValue(modifierNames);
      // Case 3
      if (modifierValue.isEmpty()) {
        modifierValue = Component::getModifierValueFromInheritedType(mpModel, modifierNames);
      }
    }
    return modifierValue;
  }

  QString Component::getModifierValueFromInheritedType(Model *pModel, QStringList modifierNames)
  {
    QString modifierValue = "";
    foreach (auto pElement, pModel->getElements()) {
      if (pElement->isExtend() && pElement->getModel()) {
        auto pExtend = dynamic_cast<Extend*>(pElement);
        modifierValue = pExtend->getModel()->getModifier().getModifierValue(modifierNames);
        if (modifierValue.isEmpty()) {
          modifierValue = Component::getModifierValueFromInheritedType(pExtend->getModel(), modifierNames);
        } else {
          return modifierValue;
        }
      }
    }
    return modifierValue;
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

  Extend::Extend(Model *pParentModel, const QJsonObject &jsonObject)
    : Element(pParentModel)
  {
    mpExtendsAnnotation = std::make_unique<Annotation>(pParentModel);
    deserialize(jsonObject);
  }

  void Extend::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("modifiers")) {
      mExtendsModifier.deserialize(jsonObject.value("modifiers"));
    }

    if (jsonObject.contains("annotation")) {
      mpExtendsAnnotation->deserialize(jsonObject.value("annotation").toObject());
    }

    if (jsonObject.contains("baseClass")) {
      mpModel = new Model(jsonObject.value("baseClass").toObject(), this);
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

  Part::Part()
  {
    mName = "";
    mSubScripts.clear();
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

  QString Part::getName() const
  {
    if (mSubScripts.isEmpty()) {
      return mName;
    } else {
      return mName % "[" % mSubScripts.join(",") % "]";
    }
  }

  Connector::Connector()
  {
    mKind = "";
    mParts.clear();
  }

  void Connector::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("$kind")) {
      mKind = jsonObject.value("$kind").toString();
    }

    if (jsonObject.contains("parts")) {
      QJsonArray parts = jsonObject.value("parts").toArray();
      foreach (QJsonValue part, parts) {
        Part partObject;
        partObject.deserialize(part.toObject());
        mParts.append(partObject);
      }
    }
  }

  QString Connector::getName() const
  {
    return getNameParts().join(".");
  }

  QStringList Connector::getNameParts() const
  {
    QStringList parts;
    foreach (auto part, mParts) {
      parts.append(part.getName());
    }
    return parts;
  }

  Connection::Connection(Model *pParentModel)
  {
    mpParentModel = pParentModel;
    mpAnnotation = std::make_unique<Annotation>(pParentModel);
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
      mpAnnotation->deserialize(jsonObject.value("annotation").toObject());
    }
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
    mpAnnotation = std::make_unique<Annotation>(pParentModel);
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
      mpAnnotation->deserialize(jsonObject.value("annotation").toObject());
    }
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
    mpAnnotation = std::make_unique<Annotation>(pParentModel);
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
      mpAnnotation->deserialize(jsonObject.value("annotation").toObject());
    }
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
