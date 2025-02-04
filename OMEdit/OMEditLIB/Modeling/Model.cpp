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
#include "MainWindow.h"
#include "OMC/OMCProxy.h"

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
   * \param CoordinateSystem
   */
  CoordinateSystem::CoordinateSystem(const CoordinateSystem &coordinateSystem)
  {
    setExtent(coordinateSystem.getExtent());
    setHasExtent(coordinateSystem.hasExtent());
    setPreserveAspectRatio(coordinateSystem.getPreserveAspectRatio());
    setHasPreserveAspectRatio(coordinateSystem.hasPreserveAspectRatio());
    setInitialScale(coordinateSystem.getInitialScale());
    setHasInitialScale(coordinateSystem.hasInitialScale());
    setGrid(coordinateSystem.getGrid());
    setHasGrid(coordinateSystem.hasGrid());
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

  void IconDiagramMap::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("extent")) {
      mHasExtent = true;
      mExtent.deserialize(jsonObject.value("extent"));
    }

    if (jsonObject.contains("primitivesVisible")) {
      mPrimitivesVisible.deserialize(jsonObject.value("primitivesVisible"));
    }
  }

  void ExperimentAnnotation::deserialize(const QJsonObject &jsonObject)
  {
    /* We only use this to check if the model has Interval defined in experiment annotation.
     * The simulation still uses getSimulationOptions() API.
     * We might change this in future.
     */
    if (jsonObject.contains("Interval")) {
      mHasInterval = true;
      //mInterval.deserialize(jsonObject.value("extent"));
    }
  }

  Annotation Annotation::defaultAnnotation{nullptr};

  Annotation::Annotation(Model *pParentModel)
    : mPlacementAnnotation(pParentModel)
  {
    mpParentModel = pParentModel;
    mpIconAnnotation = std::make_unique<IconDiagramAnnotation>(mpParentModel);
    mpDiagramAnnotation = std::make_unique<IconDiagramAnnotation>(mpParentModel);
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

  Annotation::~Annotation()
  {
    if (mpChoices) {
      delete mpChoices;
    }
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
      mpChoices = new Choices(jsonObject.value("choices").toObject(), mpParentModel);
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
    // experiment annotation
    if (jsonObject.contains("experiment")) {
      mExperimentAnnotation.deserialize(jsonObject.value("experiment").toObject());
    }
  }

  /*!
   * \brief Annotation::getMap
   * Returns either the IconMap or DiagramMap annotation.
   * \param icon
   * \return
   */
  const IconDiagramMap &Annotation::getMap(bool icon) const
  {
    if (icon) {
      return mIconMap;
    } else {
      return mDiagramMap;
    }
  }

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
      mMergedCoordinateSystem = mCoordinateSystem;
    }

    if (jsonObject.contains("graphics")) {
      if (jsonObject.value("graphics").isArray()) {
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
          } else if (graphicObject.contains("$error")) {
            MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, graphicObject.value("$error").toString(), Helper::scriptingKind, Helper::errorLevel));
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
      for (const QJsonValue &absynDim: jsonObject.value("absyn").toArray()) {
        mAbsynDims.append(absynDim.toString());
      }
    }

    if (jsonObject.contains("typed")) {
      for (const QJsonValue &typedDim: jsonObject.value("typed").toArray()) {
        mTypedDims.append(typedDim.toString());
      }
    }
  }

  Modifier::Modifier(const QString &name, const QJsonValue &jsonValue, Model *pParentModel)
  {
    mName = name;
    mpParentModel = pParentModel;
    deserialize(jsonValue);
  }

  Modifier::~Modifier()
  {
    if (mpElement) {
      delete mpElement;
    }

    qDeleteAll(mModifiers);
    mModifiers.clear();
  }

  void Modifier::deserialize(const QJsonValue &jsonValue)
  {
    if (jsonValue.isObject()) {
      QJsonObject modifiers = jsonValue.toObject();
      for (QJsonObject::iterator modifiersIterator = modifiers.begin(); modifiersIterator != modifiers.end(); ++modifiersIterator) {
        const QString modifierKey = modifiersIterator.key();
        const QJsonValue modifierValue = modifiersIterator.value();
        if (modifierKey.compare(QStringLiteral("$type")) == 0) {
          mType = modifierValue.toString();
        } else if (modifierKey.compare(QStringLiteral("final")) == 0) {
          mFinal = true;
        } else if (modifierKey.compare(QStringLiteral("each")) == 0) {
          mEach = true;
        } else if (modifierKey.compare(QStringLiteral("comment")) == 0) {
          mComment = modifierValue.toString();
        } else if (modifierKey.compare(QStringLiteral("$value")) == 0) {
          if (modifierValue.isObject()) {
            QJsonObject valueObject = modifierValue.toObject();
            QString kind = valueObject.value("$kind").toString();

            if (kind.compare(QStringLiteral("component")) == 0) {
              mpElement = new Component(mpParentModel, valueObject);
            } else if (kind.compare(QStringLiteral("class")) == 0) {
              mpElement = new ReplaceableClass(mpParentModel, valueObject);
            } else {
              qDebug() << "Modifier::deserialize() unhandled kind of element" << kind;
            }
          } else {
            mValue = modifierValue.toString();
            mValueDefined = true;
          }
        } else {
          mModifiers.append(new Modifier(modifierKey, modifierValue, mpParentModel));
        }
      }
    } else {
      mValue = jsonValue.toString();
      mValueDefined = true;
    }
  }

  QString Modifier::toString(bool skipTopLevel, bool includeComment) const
  {
    if (mpElement) {
      return mpElement->toString(skipTopLevel);
    } else {
      QString value;
      if (!skipTopLevel) {
        value.append(toStringEach());
        value.append(toStringFinal());
      }
      value.append(mName);
      QStringList subModifiers;
      foreach (auto *pSubModifier, mModifiers) {
        subModifiers.append(pSubModifier->toString());
      }
      if (!subModifiers.isEmpty()) {
        value.append("(" % subModifiers.join(", ") % ")");
      }
      if (!mValue.isEmpty()) {
        value.append(mName.isEmpty() ? mValue : " = " % mValue);
      }
      if (includeComment && !mComment.isEmpty()) {
        value.append(" \"" % mComment % "\"");
      }

      return value.compare(mName) == 0 ? "" : value;
    }
  }

  Modifier *Modifier::getModifier(const QString &modifier) const
  {
    foreach (auto *pModifier, mModifiers) {
      if (pModifier->getName().compare(modifier) == 0) {
        return pModifier;
      }
    }
    return 0;
  }

  QPair<QString, bool> Modifier::getModifierValue(const QString &modifier) const
  {
    Modifier *pModifier = getModifier(modifier);
    if (pModifier) {
      return qMakePair(pModifier->getValue(), true);
    } else {
      return qMakePair(QString(""), false);
    }
  }

  bool Modifier::hasModifier(const QString &modifier) const
  {
    Modifier *pModifier = getModifier(modifier);
    return pModifier && pModifier->getName().compare(modifier) == 0;
  }

  /*!
   * \brief createModifier
   * Creates the Modifier from another Modifier.\n
   * See issue #13301 and #13516.\n
   * Dump the modifier as string and use OMCProxy::modifierToJSON to convert it to JSON.\n
   * Contruct new Modifier instance with JSON.
   * \param pModifier
   * \return
   */
  Modifier *createModifier(const Modifier *pModifier, Model *pParentModel)
  {
    // If value is defined then we wrap within parenthesis otherwise its not needed.
    if (pModifier->isValueDefined()) {
      QJsonObject jsonObject = MainWindow::instance()->getOMCProxy()->modifierToJSON("(" % pModifier->toString() % ")");
      return new Modifier(pModifier->getName(), jsonObject.value(pModifier->getName()), pParentModel);
    } else {
      QJsonObject jsonObject;
      jsonObject.insert("modifiers", MainWindow::instance()->getOMCProxy()->modifierToJSON(pModifier->toString()));
      return new Modifier(pModifier->getName(), jsonObject.value("modifiers"), pParentModel);
    }
  }

  void Modifier::addModifier(const Modifier *pModifier)
  {
    mModifiers.append(createModifier(pModifier, mpParentModel));
  }

  bool Modifier::isBreak() const
  {
    return mValue.compare(Helper::BREAK) == 0 ? true : false;
  }

  bool Modifier::isRedeclare() const
  {
    return mpElement && mpElement->isRedeclare();
  }

  bool Modifier::isReplaceable() const
  {
    return mpElement && mpElement->getReplaceable();
  }

  QPair<QString, bool> Modifier::getModifierValue(QStringList qualifiedModifierName) const
  {
    if (qualifiedModifierName.isEmpty()) {
      return qMakePair(QString(""), false);
    }

    /* Fixes issues #10819 and #10846.
     * There is no sequence point between function arguments so call qualifiedModifierName.takeFirst() before calling the Modifier::getModifierValue function
     * so correct list items are passed to the function.
     */
    const QString name = qualifiedModifierName.takeFirst();
    return Modifier::getModifierValue(this, name, qualifiedModifierName);
  }

  QString Modifier::toStringEach() const
  {
    return isEach() ? "each " : "";
  }

  QString Modifier::toStringFinal() const
  {
    return isFinal() ? "final " : "";
  }

  QPair<QString, bool> Modifier::getModifierValue(const Modifier *pModifier, const QString &modifierName, QStringList qualifiedModifierName)
  {
    foreach (auto *pSubModifier, pModifier->getModifiers()) {
      if (pSubModifier->getName().compare(modifierName) == 0) {
        if (qualifiedModifierName.isEmpty()) {
          return qMakePair(pSubModifier->getValueWithoutQuotes(), true);
        } else {
          const QString name = qualifiedModifierName.takeFirst();
          return Modifier::getModifierValue(pSubModifier, name, qualifiedModifierName);
        }
      }
    }

    return qMakePair(QString(""), false);
  }

  Replaceable::Replaceable(Model *pParentModel)
  {
    mpParentModel = pParentModel;
    mConstrainedby = "";
    mComment = "";
  }

  Replaceable::~Replaceable()
  {
    if (mpModifier) {
      delete mpModifier;
    }
  }

  void Replaceable::deserialize(const QJsonValue &jsonValue)
  {
    if (jsonValue.isObject()) {
      QJsonObject replaceableObject = jsonValue.toObject();
      mConstrainedby = replaceableObject.value("constrainedby").toString();

      if (replaceableObject.contains("modifiers")) {
        mpModifier = new Modifier("", replaceableObject.value("modifiers"), mpParentModel);
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

  QString Prefixes::toString(bool skipTopLevel) const
  {
    QStringList value;

    if (mFinal && !skipTopLevel) {
      value.append("final");
    }

    if (mRedeclare) {
      value.append("redeclare");
    }

    if (mInner) {
      value.append("inner");
    }

    if (mOuter) {
      value.append("outer");
    }

    if (mpReplaceable) {
      value.append("replaceable");
    }

    return value.join(" ");
  }

  QString Prefixes::typePrefixes() const
  {
    QStringList value;

    if (!mConnector.isEmpty()) value.append(mConnector);
    if (!mVariability.isEmpty()) value.append(mVariability);
    if (!mDirection.isEmpty()) value.append(mDirection);

    return value.join(" ");
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

    mImports.clear();

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

    deserializeElements(mModelJson.value("elements").toArray());

    if (mModelJson.contains("comment")) {
      mComment = mModelJson.value("comment").toString();
    }

    if (mModelJson.contains("annotation")) {
      mpAnnotation->deserialize(mModelJson.value("annotation").toObject());
    }

    updateMergedCoordinateSystem();

    if (mModelJson.contains("imports")) {
      for (const QJsonValue &import: mModelJson.value("imports").toArray()) {
        QJsonObject importObject = import.toObject();
        if (!importObject.isEmpty()) {
          mImports.append(Import(importObject));
        }
      }
    }

    if (mModelJson.contains("connections")) {
      for (const QJsonValue &connection: mModelJson.value("connections").toArray()) {
        QJsonObject connectionObject = connection.toObject();
        if (!connectionObject.isEmpty()) {
          Connection *pConnection = new Connection(this);
          pConnection->deserialize(connection.toObject());
          mConnections.append(pConnection);
        }
      }
    }

    if (mModelJson.contains("transitions")) {
      for (const QJsonValue &transition: mModelJson.value("transitions").toArray()) {
        QJsonObject transitionObject = transition.toObject();
        if (!transitionObject.isEmpty()) {
          Transition *pTransition = new Transition(this);
          pTransition->deserialize(transition.toObject());
          mTransitions.append(pTransition);
        }
      }
    }

    if (mModelJson.contains("initialStates")) {
      for (const QJsonValue &initialState: mModelJson.value("initialStates").toArray()) {
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

  /*!
   * \brief Model::deserializeElements
   * Deserializes the elements JSON and adds the elements to the model.
   * \param elements
   */
  void Model::deserializeElements(const QJsonArray elements)
  {
    for (const QJsonValue &element: elements) {
      QJsonObject elementObject = element.toObject();
      QString kind = elementObject.value("$kind").toString();

      if (kind.compare(QStringLiteral("extends")) == 0) {
        mElements.append(new Extend(this, elementObject));
      } else if (kind.compare(QStringLiteral("component")) == 0) {
        mElements.append(new Component(this, elementObject));
      } else if (kind.compare(QStringLiteral("class")) == 0) {
        mElements.append(new ReplaceableClass(this, elementObject));
      } else {
        qDebug() << "Model::deserialize() unhandled kind of element" << kind;
      }
    }
  }

  void Model::updateMergedCoordinateSystem()
  {
    /* From Modelica Specification Version 3.5-dev
     * The coordinate system (including preserveAspectRatio) of a class is defined by the following priority:
     * 1. The coordinate system annotation given in the class (if specified).
     * 2. The coordinate systems of the first base-class where the extent on the extends-clause specifies a
     *    null-region (if any). Note that null-region is the default for base-classes, see section 18.6.3.
     * 3. The default coordinate system CoordinateSystem(extent={{-100, -100}, {100, 100}}).
     *
     * Following is the second case. First case is covered when we read the annotation of the class. Third case is handled by default values of IconDiagramAnnotation class.
     */
    if (!getAnnotation()->getIconAnnotation()->mMergedCoordinateSystem.isComplete()) {
      readCoordinateSystemFromExtendsClass(&getAnnotation()->getIconAnnotation()->mMergedCoordinateSystem, true);
    }

    if (!getAnnotation()->getDiagramAnnotation()->mMergedCoordinateSystem.isComplete()) {
      readCoordinateSystemFromExtendsClass(&getAnnotation()->getDiagramAnnotation()->mMergedCoordinateSystem, false);
    }
  }

  Element *Model::getRootParentElement() const
  {
    Element *pElement = getParentElement();
    while (pElement && pElement->getParentModel() && pElement->getParentModel()->getParentElement()) {
      pElement = pElement->getParentModel()->getParentElement();
    }
    return pElement;
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
    return getRootType() == QLatin1String("enumeration");
  }

  bool Model::isRecord() const
  {
    return (mRestriction.compare(QStringLiteral("record")) == 0);
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

  bool Model::isPartial() const
  {
    return mpPrefixes ? mpPrefixes.get()->isPartial() : false;
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
   * \brief Model::removeElement
   * Removes the element.
   * \param name
   */
  void Model::removeElement(const QString &name)
  {
    foreach (auto pElement, mElements) {
      if (pElement->getName().compare(name) == 0) {
        mElements.removeOne(pElement);
        delete pElement;
        break;
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

  bool isCompatibleConnectorDirection(const Element &lhs, bool lhsOutside, const Element &rhs, bool rhsOutside)
  {
    // A inside output should not be connected to an inside output,
    // or a public outside input to a public outside input.
    auto dir = lhs.getDirection();
    if (!dir.isEmpty() && dir == rhs.getDirection()) {
      if (dir == "output" && !lhsOutside && !rhsOutside) {
        return false;
      } else if (dir == "input" && lhsOutside && rhsOutside && lhs.isPublic() && rhs.isPublic()) {
        return false;
      }
    }

    return true;
  }

  bool Model::isValidConnection(const Name &lhsConnector, const Name &rhsConnector) const
  {
    const Element *lhs = lookupElement(lhsConnector);
    const Element *rhs = lookupElement(rhsConnector);

    if (!lhs || !rhs) {
      qDebug() << "Failed to find connector " << (lhs ? rhsConnector : lhsConnector).getName();
      return true;
    }

    Model *lhs_model = lhs->getModel();
    Model *rhs_model = rhs->getModel();

    if (!lhs_model || !rhs_model) return true;

    auto lhs_outside = isOutsideConnector(lhsConnector, *this);
    auto rhs_outside = isOutsideConnector(rhsConnector, *this);

    if (!isCompatibleConnectorDirection(*lhs, lhs_outside, *rhs, rhs_outside)) {
      return false;
    }

    // Check that the connectors are type compatible.
    return lhs_model->isTypeCompatibleWith(*rhs_model, lhs_outside, rhs_outside);
  }

  bool Model::isTypeCompatibleWith(const Model &other, bool lhsOutside, bool rhsOutside) const
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

              if (m1 && m2 && !m1->isTypeCompatibleWith(*m2, lhsOutside, rhsOutside)) {
                return false;
              }

              if (!isCompatibleConnectorDirection(*e1, lhsOutside, *e2, rhsOutside)) {
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

        if (m1 && m2 && !m1->isTypeCompatibleWith(*m2, lhsOutside, rhsOutside)) {
          return false;
        }
      }
    }

    return true;
  }

  QPair<QString, bool> Model::getParameterValue(const QString &parameter, QString &typeName)
  {
    QPair<QString, bool> value("", false);
    foreach (auto pElement, mElements) {
      if (pElement->isComponent()) {
        auto pComponent = dynamic_cast<Component*>(pElement);
        if (pComponent->getName().compare(StringHandler::getFirstWordBeforeDot(parameter)) == 0) {
          if (pComponent->getModifier() && pComponent->getModifier()->isValueDefined()) {
            value = qMakePair(pComponent->getModifier()->getValueWithoutQuotes(), true);
          }
          // Fixes issue #7493. Handles the case where value is from instance name e.g., %instanceName.parameterName
          if (!value.second && pComponent->getModel()) {
            value = pComponent->getModel()->getParameterValue(StringHandler::getLastWordAfterDot(parameter), typeName);
          }
          typeName = pComponent->getType();
          break;
        }
      }
    }
    return value;
  }

  QPair<QString, bool> Model::getParameterValueFromExtendsModifiers(const QStringList &parameter)
  {
    QPair<QString, bool> value("", false);
    foreach (auto pElement, mElements) {
      if (pElement->isExtend()) {
        auto pExtend = dynamic_cast<Extend*>(pElement);
        if (pExtend->getModifier()) {
          value = pExtend->getModifier()->getModifierValue(parameter);
        }
        if (value.second) {
          return value;
        } else {
          if (pExtend->getModel()) {
            value = pExtend->getModel()->getParameterValueFromExtendsModifiers(parameter);
            if (value.second) {
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
    QString curName;
    bool last;

    if (variableName.contains("."))
    {
      curName = StringHandler::getFirstWordBeforeDot(variableName);
      last = false;
    }
    else
    {
      curName = variableName;
      last = true;
    }

    foreach (auto pElement, mElements) {
      if (pElement->isComponent()) {
        if (pElement->getName().compare(curName) == 0) {
          if (last) {
            return &pElement->getBinding();
          } else {
            if (!pElement->getModel()) {
              return nullptr;
            }
            return pElement->getModel()->getVariableBinding(StringHandler::removeFirstWordAfterDot(variableName));
          }
        }
      } else if (pElement->isExtend() && pElement->getModel()) {
        auto expression = pElement->getModel()->getVariableBinding(variableName);
        if (expression) {
          return expression;
        }
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
    mpAnnotation = std::make_unique<Annotation>(this);
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
      if (!mVisible.deserialize(jsonObject.value("visible"))) {
        // if we fail to deserialize the visible value then set it to true.
        mVisible = true;
      }
    } else {
      // if there is no visible then assume it to be true.
      mVisible = true;
    }

    if (jsonObject.contains("transformation")) {
      mTransformation.deserialize(jsonObject.value("transformation").toObject());
    }

    if (jsonObject.contains("iconVisible")) {
      if (mIconVisible.deserialize(jsonObject.value("iconVisible"))) {
        // if we fail to deserialize the iconVisible value then set it to true.
        mIconVisible = true;
      }
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

  Choices::Choices(const QJsonObject &jsonObject, Model *pParentModel)
  {
    mpParentModel = pParentModel;
    mCheckBox = false;
    mDymolaCheckBox = false;
    mChoices.clear();
    deserialize(jsonObject);
  }

  Choices::~Choices()
  {
    qDeleteAll(mChoices);
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
      for (const auto& choice: jsonObject.value("choice").toArray()) {
        mChoices.append(new Modifier("", choice, mpParentModel));
      }
    }
  }

  QStringList Choices::getChoicesValueStringList() const
  {
    QStringList choices;
    foreach (auto *pChoice, mChoices) {
      choices.append(pChoice->toString());
    }
    return choices;
  }

  QStringList Choices::getChoicesCommentStringList() const
  {
    QStringList choices;
    foreach (auto *pChoice, mChoices) {
      choices.append(pChoice->toString(false, true));
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

    if (mpModifier) {
      delete mpModifier;
    }
  }

  void Element::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("modifiers")) {
      mpModifier = new Modifier("", jsonObject.value("modifiers"), mpParentModel);
    }

    if (jsonObject.contains("comment")) {
      mComment = jsonObject.value("comment").toString();
    }

    if (jsonObject.contains("$error")) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, jsonObject.value("$error").toString(), Helper::scriptingKind, Helper::errorLevel));
    }

    deserialize_impl(jsonObject);
  }

  Element *Element::getTopLevelExtendElement() const
  {
    Element *pElement = mpParentModel->getParentElement();
    while (pElement && pElement->getParentModel() && pElement->getParentModel()->getParentElement()) {
      pElement = pElement->getParentModel()->getParentElement();
    }

    return pElement;
  }

  /*!
   * \brief Element::getTopLevelExtendName
   * Returns the top level extend name where the element is located.
   * \return
   */
  QString Element::getTopLevelExtendName() const
  {
    Element *pElement = getTopLevelExtendElement();

    if (pElement && pElement->getModel()) {
      return pElement->getModel()->getName();
    } else {
      return mpParentModel->getName();
    }
  }

  QPair<QString, bool> Element::getModifierValueFromType(QStringList modifierNames)
  {
    /* 1. First check if unit is defined with in the component modifier.
     * 2. If no unit is found then check it in the derived class modifier value recursively.
     */
    // Case 1
    QPair<QString, bool> modifierValue("", false);
    if (mpModifier) {
      modifierValue = mpModifier->getModifierValue(modifierNames);
    }
    if (!modifierValue.second && mpModel) {
      // Case 2
      modifierValue = Element::getModifierValueFromInheritedType(mpModel, modifierNames);
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

  bool Element::isRedeclare() const
  {
    return mpPrefixes ? mpPrefixes.get()->isRedeclare() : false;
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
   * \brief Element::getIconDiagramMapPrimitivesVisible
   * Recursively look for primitivesVisible annotation.
   * \param icon
   * \return
   */
  bool Element::getIconDiagramMapPrimitivesVisible(bool icon) const
  {
    /* Issue #12097
     * The IconMap/DiagramMap annotation can be defined with extends clause or with short class definition.
     */
    if (!getAnnotation()->getMap(icon).getprimitivesVisible()) {
      return false;
    }
    if (mpParentModel && !mpParentModel->getAnnotation()->getMap(icon).getprimitivesVisible()) {
      return false;
    }

    if (mpParentModel && mpParentModel->getParentElement()) {
      return mpParentModel->getParentElement()->getIconDiagramMapPrimitivesVisible(icon);
    } else {
      return true;
    }
  }

  /*!
   * \brief Element::getIconDiagramMapHasExtent
   * Recursively look if IconDiagramMap contains the extent.
   * \param icon
   * \return
   */
  bool Element::getIconDiagramMapHasExtent(bool icon) const
  {
    if (getAnnotation()->getMap(icon).hasExtent()) {
      return getAnnotation()->getMap(icon).hasExtent();
    }
    if (mpParentModel && !mpParentModel->getAnnotation()->getMap(icon).hasExtent()) {
      return mpParentModel->getAnnotation()->getMap(icon).hasExtent();
    }

    if (mpParentModel && mpParentModel->getParentElement()) {
      return mpParentModel->getParentElement()->getIconDiagramMapHasExtent(icon);
    } else {
      return false;
    }
  }

  /*!
   * \brief Element::getIconDiagramMapExtent
   * Recursively look for IconDiagramMap extent.
   * \param icon
   * \return
   */
  const ExtentAnnotation &Element::getIconDiagramMapExtent(bool icon) const
  {
    if (getAnnotation()->getMap(icon).hasExtent()) {
      return getAnnotation()->getMap(icon).getExtent();
    }
    if (mpParentModel && !mpParentModel->getAnnotation()->getMap(icon).hasExtent()) {
      return mpParentModel->getAnnotation()->getMap(icon).getExtent();
    }

    if (mpParentModel && mpParentModel->getParentElement()) {
      return mpParentModel->getParentElement()->getIconDiagramMapExtent(icon);
    } else {
      return getAnnotation()->getMap(icon).getExtent();
    }
  }

  QString Element::toString(bool skipTopLevel, bool mergeExtendsModifiers) const
  {
    Q_UNUSED(mergeExtendsModifiers);
    if (mpPrefixes) {
      return mpPrefixes->toString(skipTopLevel);
    }
    return "";
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

  QPair<QString, bool> Element::getModifierValueFromInheritedType(Model *pModel, QStringList modifierNames)
  {
    QPair<QString, bool> modifierValue("", false);
    foreach (auto pElement, pModel->getElements()) {
      if (pElement->isExtend()) {
        auto pExtend = dynamic_cast<Extend*>(pElement);
        if (pExtend->getModifier()) {
          modifierValue = pExtend->getModifier()->getModifierValue(modifierNames);
          if (modifierValue.second) {
            return modifierValue;
          }
        }
        if (!modifierValue.second && pExtend->getModel()) {
          modifierValue = Element::getModifierValueFromInheritedType(pExtend->getModel(), modifierNames);
          if (modifierValue.second) {
            return modifierValue;
          }
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

    // Always create Annotation for extend element. See #11363
    mpAnnotation = std::make_unique<Annotation>(mpParentModel);
    if (jsonObject.contains("annotation")) {
      mpAnnotation->deserialize(jsonObject.value("annotation").toObject());
    }
  }

  /*!
   * \brief Extend::getQualifiedName
   * Returns the qualified name of extend.
   * \param includeBaseName
   * \return
   */
  QString Extend::getQualifiedName(bool includeBaseName) const
  {
    if (mpParentModel && mpParentModel->getParentElement()) {
      if (includeBaseName) {
        QString name = mpParentModel->getParentElement()->getQualifiedName(includeBaseName);
        if (name.isEmpty()) {
          return mBaseClass;
        } else {
          return name % "." % mBaseClass;
        }
      } else {
        return mpParentModel->getParentElement()->getQualifiedName(includeBaseName);
      }
    } else {
      return includeBaseName ? mBaseClass : "";
    }
  }

  const QString &Extend::getRootType() const
  {
    if (mpModel && mpModel->isDerivedType() && mpModel->getElements().size() > 0) {
      return mpModel->getElements().at(0)->getRootType();
    }
    return mBaseClass;
  }

  QString Extend::toString(bool skipTopLevel, bool mergeExtendsModifiers) const
  {
    return Element::toString(skipTopLevel, mergeExtendsModifiers);
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

    if (jsonObject.contains("annotation")) {
      mpAnnotation = std::make_unique<Annotation>(mpParentModel);
      mpAnnotation->deserialize(jsonObject.value("annotation").toObject());
    }
  }

  /*!
   * \brief Component::getExtendsModifiers
   * Makes a list of all extends modifiers.
   * \param pParentModel
   * \return
   */
  QList<Modifier*> Component::getExtendsModifiers(const Model *pParentModel) const
  {
    QList<Modifier*> modifiers;
    if (pParentModel && pParentModel->getParentElement() && pParentModel->getParentElement()->getModifier()) {
      Modifier *pExtentElementModifier = pParentModel->getParentElement()->getModifier();
      foreach (auto *pSubModifier, pExtentElementModifier->getModifiers()) {
        if (pSubModifier->getName().compare(mName) == 0) {
          modifiers.append(pSubModifier);
        }
      }
      modifiers.append(getExtendsModifiers(pExtentElementModifier->getParentModel()));
    }
    return modifiers;
  }

  /*!
   * \brief Component::mergeModifiersIntoOne
   * Merges the list of all extends modifiers into one modifier.
   * \param extendsModifiers
   * \return
   */
  Modifier *Component::mergeModifiersIntoOne(QList<Modifier *> extendsModifiers) const
  {
    Modifier *pModifier = nullptr;
    if (!extendsModifiers.isEmpty()) {
      pModifier = createModifier(extendsModifiers.last(), mpParentModel);
      for (int i = extendsModifiers.size() - 2 ; i >= 0 ; i--) {
        Component::mergeModifiers(pModifier, extendsModifiers.at(i));
      }
    }
    return pModifier;
  }

  /*!
   * \brief Component::mergeModifiers
   * Merges pModifier2 into pModifier1
   * \param pModifier1
   * \param pModifier2
   */
  void Component::mergeModifiers(Modifier *pModifier1, Modifier *pModifier2)
  {
    foreach (auto pSubModifier2, pModifier2->getModifiers()) {
      bool subModifierFound = false;
      foreach (auto pSubModifier1, pModifier1->getModifiers()) {
        /* if modifier exists then check if its value is defined
         * if the value is not defined then merge sub modifiers
         */
        if (pSubModifier2->getName().compare(pSubModifier1->getName()) == 0) {
          subModifierFound = true;
          if (!pSubModifier1->isValueDefined()) {
            Component::mergeModifiers(pSubModifier1, pSubModifier2);
          }
        }
      }
      // if modifier doesn't exist then add it
      if (!subModifierFound) {
        pModifier1->addModifier(pSubModifier2);
      }
    }
  }

  /*!
   * \brief Component::getQualifiedName
   * Returns the qualified name of the component.
   * \param includeBaseName
   * \return
   */
  QString Component::getQualifiedName(bool includeBaseName) const
  {
    if (mpParentModel && mpParentModel->getParentElement()) {
      QString name = mpParentModel->getParentElement()->getQualifiedName(includeBaseName);
      if (name.isEmpty()) {
        return mName;
      } else {
        return name % "." % mName;
      }
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

  QString Component::toString(bool skipTopLevel, bool mergeExtendsModifiers) const
  {
    QStringList value;

    value.append(Element::toString(skipTopLevel, mergeExtendsModifiers));

    if (mpPrefixes) {
      auto prefixes = mpPrefixes->typePrefixes();
      if (!prefixes.isEmpty()) value.append(prefixes);
    }

    value.append(mType);
    value.append(mName);
    const QString dims = getDimensions().getAbsynDimensionsString();
    if (!dims.isEmpty()) {
      value.append("[" % dims % "]");
    }
    // modifiers
    Modifier *pModifier = nullptr;
    if (mergeExtendsModifiers) {
      // Merge extends modifiers. See issue #13301 and #13516.
      QList<Modifier *> extendsModifiers = getExtendsModifiers(mpParentModel);
      pModifier = mergeModifiersIntoOne(extendsModifiers);
    }
    // if merge modifiers
    if (pModifier) {
      // if this modifier exists then merge it
      if (mpModifier) {
        Component::mergeModifiers(pModifier, mpModifier);
      }
      // we don't need the name coming from the extend modification
      pModifier->setName("");
      value.append(pModifier->toString());
      delete pModifier;
    } else if (mpModifier) {
      // if there are no merged modifiers then just use this modifier if exists.
      value.append(mpModifier->toString());
    }
    // constrainedby issue #13300
    if (mpPrefixes && mpPrefixes->getReplaceable() && !mpPrefixes->getReplaceable()->getConstrainedby().isEmpty()) {
      value.append("constrainedby " % mpPrefixes->getReplaceable()->getConstrainedby());
      if (mpPrefixes->getReplaceable()->getModifier()) {
        value.append(mpPrefixes->getReplaceable()->getModifier()->toString());
      }
    }
    // comment
    if (mpPrefixes && mpPrefixes->getReplaceable() && !mpPrefixes->getReplaceable()->getComment().isEmpty()) {
      value.append("\"" % mpPrefixes->getReplaceable()->getComment() % "\"");
    } else if (!mComment.isEmpty()) {
      value.append("\"" % mComment % "\"");
    }

    value.removeAll(QString(""));
    return value.join(" ");
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

    if (jsonObject.contains("annotation")) {
      mpAnnotation = std::make_unique<Annotation>(mpParentModel);
      mpAnnotation->deserialize(jsonObject.value("annotation").toObject());
    }
  }

  /*!
   * \brief ReplaceableClass::getQualifiedName
   * Returns the qualified name of the replaceable class.
   * \param includeBaseName
   * \return
   */
  QString ReplaceableClass::getQualifiedName(bool includeBaseName) const
  {
    if (mpParentModel && mpParentModel->getParentElement()) {
      QString name = mpParentModel->getParentElement()->getQualifiedName(includeBaseName);
      if (name.isEmpty()) {
        return mName;
      } else {
        return name % "." % mName;
      }
    } else {
      return mName;
    }
  }

  QString ReplaceableClass::toString(bool skipTopLevel, bool mergeExtendsModifiers) const
  {
    QStringList value;

    value.append(Element::toString(skipTopLevel, mergeExtendsModifiers));
    value.append(mType);
    value.append(mName);
    if (!mBaseClass.isEmpty()) {
      value.append("= ");

      if (mpPrefixes) {
        auto prefixes = mpPrefixes->typePrefixes();
        if (!prefixes.isEmpty()) value.append(prefixes);
      }

      value.append(mBaseClass);
      if (mpModifier) {
        value.append(mpModifier->toString());
      }
      if (!mComment.isEmpty()) {
        value.append("\"" % mComment % "\"");
      }
    }

    value.removeAll(QString(""));
    return value.join(" ");
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

#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
      for (const auto& sub: QStringView(str).mid(i + 1, str.size() - i - 2).split(',')) {
#else
      for (const auto& sub: str.midRef(i + 1, str.size() - i - 2).split(',')) {
#endif
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
      for (const QJsonValue &subscript: jsonObject.value("subscripts").toArray()) {
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

  Name::Name(QString str)
  {
    while (!str.isEmpty()) {
      mParts.append(StringHandler::getFirstWordBeforeDot(str));
      auto next_str = StringHandler::removeFirstWordAfterDot(str);
      if (next_str.size() == str.size()) break;
      str = next_str;
    }
  }

  void Name::deserialize(const QJsonArray &jsonArray)
  {
    for (const QJsonValue &part: jsonArray) {
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

  Import::Import(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("path")) {
      mPath = jsonObject.value("path").toString();
    }

    if (jsonObject.contains("shortName")) {
      mShortName = jsonObject.value("shortName").toString();
    }
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

}
