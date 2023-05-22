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
#include <QCborArray>

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

  void CoordinateSystem::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("extent"))) {
      mHasExtent = mExtent.deserialize(cborMap.value("extent"));
    }
    if (cborMap.contains(QString("preserveAspectRatio"))) {
      mHasPreserveAspectRatio = mPreserveAspectRatio.deserialize(cborMap.value("preserveAspectRatio"));
    }
    if (cborMap.contains(QString("initialScale"))) {
      mHasInitialScale = mInitialScale.deserialize(cborMap.value("initialScale"));
    }
    if (cborMap.contains(QString("grid"))) {
      mHasGrid = mGrid.deserialize(cborMap.value("grid"));
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

  void GraphicItem::deserialize(const QCborArray &cborArray)
  {
    mVisible.deserialize(cborArray.at(0));
    mOrigin.deserialize(cborArray.at(1));
    mRotation.deserialize(cborArray.at(2));
  }

  void GraphicItem::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("visible"))) {
      mVisible.deserialize(cborMap.value("visible"));
    }

    if (cborMap.contains(QString("origin"))) {
      mOrigin.deserialize(cborMap.value("origin"));
    }

    if (cborMap.contains(QString("rotation"))) {
      mRotation.deserialize(cborMap.value("rotation"));
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

  void FilledShape::deserialize(const QCborArray &cborArray)
  {
    mLineColor.deserialize(cborArray.at(3));
    mFillColor.deserialize(cborArray.at(4));
    mPattern.deserialize(cborArray.at(5));
    mFillPattern.deserialize(cborArray.at(6));
    mLineThickness.deserialize(cborArray.at(7));
  }

  void FilledShape::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("lineColor"))) {
      mLineColor.deserialize(cborMap.value("lineColor"));
    }

    if (cborMap.contains(QString("fillColor"))) {
      mFillColor.deserialize(cborMap.value("fillColor"));
    }

    if (cborMap.contains(QString("pattern"))) {
      mPattern.deserialize(cborMap.value("pattern"));
    }

    if (cborMap.contains(QString("fillPattern"))) {
      mFillPattern.deserialize(cborMap.value("fillPattern"));
    }

    if (cborMap.contains(QString("lineThickness"))) {
      mLineThickness.deserialize(cborMap.value("lineThickness"));
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

  void Line::deserialize(const QCborArray &cborArray)
  {
    if (cborArray.size() == 10) {
      GraphicItem::deserialize(cborArray);

      mPoints.deserialize(cborArray.at(3));
      mColor.deserialize(cborArray.at(4));
      mPattern.deserialize(cborArray.at(5));
      mThickness.deserialize(cborArray.at(6));
      mArrow.deserialize(cborArray.at(7));
      mArrowSize.deserialize(cborArray.at(8));
      mSmooth.deserialize(cborArray.at(9));
    }
  }

  void Line::deserialize(const QCborMap &cborMap)
  {
    GraphicItem::deserialize(cborMap);

    if (cborMap.contains(QString("points"))) {
      mPoints.deserialize(cborMap.value("points"));
    }

    if (cborMap.contains(QString("color"))) {
      mColor.deserialize(cborMap.value("color"));
    }

    if (cborMap.contains(QString("pattern"))) {
      mPattern.deserialize(cborMap.value("pattern"));
    }

    if (cborMap.contains(QString("thickness"))) {
      mThickness.deserialize(cborMap.value("thickness"));
    }

    if (cborMap.contains(QString("arrow"))) {
      mArrow.deserialize(cborMap.value("arrow"));
    }

    if (cborMap.contains(QString("arrowSize"))) {
      mArrowSize.deserialize(cborMap.value("arrowSize"));
    }

    if (cborMap.contains(QString("smooth"))) {
      mSmooth.deserialize(cborMap.value("smooth"));
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

  void Polygon::deserialize(const QCborArray &cborArray)
  {
    if (cborArray.size() == 10) {
      GraphicItem::deserialize(cborArray);
      FilledShape::deserialize(cborArray);

      mPoints.deserialize(cborArray.at(8));
      mSmooth.deserialize(cborArray.at(9));
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

  void Rectangle::deserialize(const QCborArray &cborArray)
  {
    if (cborArray.size() == 11) {
      GraphicItem::deserialize(cborArray);
      FilledShape::deserialize(cborArray);

      mBorderPattern.deserialize(cborArray.at(8));
      mExtent.deserialize(cborArray.at(9));
      mRadius.deserialize(cborArray.at(10));
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

  void Ellipse::deserialize(const QCborArray &cborArray)
  {
    if (cborArray.size() == 12) {
      GraphicItem::deserialize(cborArray);
      FilledShape::deserialize(cborArray);

      mExtent.deserialize(cborArray.at(8));
      mStartAngle.deserialize(cborArray.at(9));
      mEndAngle.deserialize(cborArray.at(10));
      mClosure.deserialize(cborArray.at(11));
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

  void Text::deserialize(const QCborArray &cborArray)
  {
    if (cborArray.size() == 15) {
      GraphicItem::deserialize(cborArray);
      FilledShape::deserialize(cborArray);

      mExtent.deserialize(cborArray.at(8));
      mTextString.deserialize(cborArray.at(9));
      mFontSize.deserialize(cborArray.at(10));
      // if invalid color
      QCborArray colorArray = cborArray.at(11).toArray();
      if (colorArray.size() == 3 && colorArray.at(0).toInteger() == -1 && colorArray.at(1).toInteger() == -1 && colorArray.at(2).toInteger() == -1) {
        mTextColor = QColor();
      } else {
        mTextColor.deserialize(cborArray.at(11));
      }
      mFontName.deserialize(cborArray.at(12));
      QCborArray textStyles = cborArray.at(13).toArray();
      if (!textStyles.isEmpty()) {
        mTextStyle.deserialize(cborArray.at(13));
      }
      mHorizontalAlignment.deserialize(cborArray.at(14));
    }
  }

  void Text::deserialize(const QCborMap &cborMap)
  {
    GraphicItem::deserialize(cborMap);
    FilledShape::deserialize(cborMap);

    if (cborMap.contains(QString("extent"))) {
      mExtent.deserialize(cborMap.value("extent"));
    }

    if (cborMap.contains(QString("string"))) {
      mTextString.deserialize(cborMap.value("string"));
    }

    if (cborMap.contains(QString("fontSize"))) {
      mFontSize.deserialize(cborMap.value("fontSize"));
    }

    if (cborMap.contains(QString("textColor"))) {
      mTextColor.deserialize(cborMap.value("textColor"));
    }

    if (cborMap.contains(QString("fontName"))) {
      mFontName.deserialize(cborMap.value("fontName"));
    }

    if (cborMap.contains(QString("textStyle"))) {
      mTextStyle.deserialize(cborMap.value("textStyle"));
    }

    if (cborMap.contains(QString("horizontalAlignment"))) {
      mHorizontalAlignment.deserialize(cborMap.value("horizontalAlignment"));
    }

//    if (cborMap.contains(QString("index"))) {
//      mIndex = cborMap.value("index").toDouble();
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

  void Bitmap::deserialize(const QCborArray &cborArray)
  {
    if (cborArray.size() == 6) {
      GraphicItem::deserialize(cborArray);

      mExtent.deserialize(cborArray.at(3));
      mFileName = cborArray.at(4).toString();
      mImageSource = cborArray.at(5).toString();
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

  void IconDiagramAnnotation::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("coordinateSystem"))) {
      mCoordinateSystem.deserialize(cborMap.value("coordinateSystem").toMap());
      mMergedCoOrdinateSystem = mCoordinateSystem;
    }

    if (cborMap.contains(QString("graphics"))) {
      if (cborMap.value("graphics").isMap()) {
        QCborMap graphicsObject = cborMap.value("graphics").toMap();
        if (graphicsObject.contains(QString("$error"))) {
          MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, graphicsObject.value("$error").toString(), Helper::scriptingKind, Helper::errorLevel));
        }
      } else if (cborMap.value("graphics").isArray()) {
        QCborArray graphicsArray = cborMap.value("graphics").toArray();
        for (int i = 0; i < graphicsArray.size(); ++i) {
          QCborMap graphicMap = graphicsArray.at(i).toMap();
          if (graphicMap.contains(QString("name")) && graphicMap.contains(QString("elements"))) {
            const QString name = graphicMap.value("name").toString();
            if (name.compare(QStringLiteral("Line")) == 0) {
              Line *pLine = new Line(mpParentModel);
              pLine->deserialize(graphicMap.value("elements").toArray());
              mGraphics.append(pLine);
            } else if (name.compare(QStringLiteral("Polygon")) == 0) {
              Polygon *pPolygon = new Polygon(mpParentModel);
              pPolygon->deserialize(graphicMap.value("elements").toArray());
              mGraphics.append(pPolygon);
            } else if (name.compare(QStringLiteral("Rectangle")) == 0) {
              Rectangle *pRectangle = new Rectangle(mpParentModel);
              pRectangle->deserialize(graphicMap.value("elements").toArray());
              mGraphics.append(pRectangle);
            } else if (name.compare(QStringLiteral("Ellipse")) == 0) {
              Ellipse *pEllipse = new Ellipse(mpParentModel);
              pEllipse->deserialize(graphicMap.value("elements").toArray());
              mGraphics.append(pEllipse);
            } else if (name.compare(QStringLiteral("Text")) == 0) {
              Text *pText = new Text(mpParentModel);
              pText->deserialize(graphicMap.value("elements").toArray());
              mGraphics.append(pText);
            } else if (name.compare(QStringLiteral("Bitmap")) == 0) {
              Bitmap *pBitmap = new Bitmap(mpParentModel);
              pBitmap->deserialize(graphicMap.value("elements").toArray());
              mGraphics.append(pBitmap);
            }
          }
        }
      }
    }
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

  void Transformation::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("origin"))) {
      mOrigin.deserialize(cborMap.value("origin"));
    }
    if (cborMap.contains(QString("extent"))) {
      mExtent.deserialize(cborMap.value("extent"));
    }
    if (cborMap.contains(QString("rotation"))) {
      mRotation.deserialize(cborMap.value("rotation"));
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

  void PlacementAnnotation::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("visible"))) {
      mVisible.deserialize(cborMap.value("visible"));
    } else {
      // if there is no visible then assume it to be true.
      mVisible = true;
    }

    if (cborMap.contains(QString("transformation"))) {
      mTransformation.deserialize(cborMap.value("transformation").toMap());
    }

    if (cborMap.contains(QString("iconVisible"))) {
      mIconVisible.deserialize(cborMap.value("iconVisible"));
    } else {
      mIconVisible = mVisible;
    }

    if (cborMap.contains(QString("iconTransformation"))) {
      mIconTransformation.deserialize(cborMap.value("iconTransformation").toMap());
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

  void Selector::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("filter"))) {
      mFilter.deserialize(cborMap.value("filter"));
    }

    if (cborMap.contains(QString("caption"))) {
      mCaption.deserialize(cborMap.value("caption"));
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

  void DialogAnnotation::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("tab"))) {
      mTab.deserialize(cborMap.value("tab"));
    }

    if (cborMap.contains(QString("group"))) {
      mGroup.deserialize(cborMap.value("group"));
    }

    if (cborMap.contains(QString("enable"))) {
      mEnable.deserialize(cborMap.value("enable"));
    }

    if (cborMap.contains(QString("showStartAttribute"))) {
      mShowStartAttribute.deserialize(cborMap.value("showStartAttribute"));
    }

    if (cborMap.contains(QString("colorSelector"))) {
      mColorSelector.deserialize(cborMap.value("colorSelector"));
    }

    if (cborMap.contains(QString("loadSelector"))) {
      mLoadSelector.deserialize(cborMap.value("loadSelector").toMap());
    }

    if (cborMap.contains(QString("saveSelector"))) {
      mSaveSelector.deserialize(cborMap.value("saveSelector").toMap());
    }

    if (cborMap.contains(QString("directorySelector"))) {
      mDirectorySelector.deserialize(cborMap.value("directorySelector").toMap());
    }

    if (cborMap.contains(QString("groupImage"))) {
      mGroupImage.deserialize(cborMap.value("groupImage"));
    }

    if (cborMap.contains(QString("connectorSizing"))) {
      mConnectorSizing.deserialize(cborMap.value("connectorSizing"));
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

  void Choices::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("checkBox"))) {
      mCheckBox.deserialize(cborMap.value("checkBox"));
    }

    if (cborMap.contains(QString("__Dymola_checkBox"))) {
      mDymolaCheckBox.deserialize(cborMap.value("__Dymola_checkBox"));
    }

    if (cborMap.contains(QString("choice"))) {
      QCborArray choices = cborMap.value("choice").toArray();
      foreach (auto choice, choices) {
        QString type = "";
        if (choice.isMap()) {
          QCborMap choiceObject = choice.toMap();
          if (choiceObject.contains(QString("$type"))) {
            type = choiceObject.value("$type").toString();
          }
          if (choiceObject.contains(QString("$value"))) {
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

  void IconDiagramMap::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("extent"))) {
      mExtent.deserialize(cborMap.value("extent"));
    }

    if (cborMap.contains(QString("primitivesVisible"))) {
      mPrimitivesVisible.deserialize(cborMap.value("primitivesVisible"));
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

  void Annotation::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("Icon"))) {
      mpIconAnnotation->deserialize(cborMap.value("Icon").toMap());
    }

    if (cborMap.contains(QString("Diagram"))) {
      mpDiagramAnnotation->deserialize(cborMap.value("Diagram").toMap());
    }

    if (cborMap.contains(QString("DocumentationClass"))) {
      mDocumentationClass.deserialize(cborMap.value("DocumentationClass"));
    }

    if (cborMap.contains(QString("version"))) {
      mVersion.deserialize(cborMap.value("version"));
    }

    if (cborMap.contains(QString("versionDate"))) {
      mVersionDate.deserialize(cborMap.value("versionDate"));
    }

    if (cborMap.contains(QString("versionBuild"))) {
      mVersionBuild.deserialize(cborMap.value("versionBuild"));
    }

    if (cborMap.contains(QString("dateModified"))) {
      mDateModified.deserialize(cborMap.value("dateModified"));
    }

    if (cborMap.contains(QString("preferredView"))) {
      mPreferredView.deserialize(cborMap.value("preferredView"));
    }

    if (cborMap.contains(QString("__Dymola_state"))) {
      mState.deserialize(cborMap.value("__Dymola_state"));
    }

    if (cborMap.contains(QString("Protection"))) {
      QCborMap protection = cborMap.value("Protection").toMap();
      if (protection.contains(QString("access"))) {
        QCborMap access = protection.value("access").toMap();
        if (access.contains(QString("name"))) {
          mAccess.deserialize(access.value("name"));
        }
      }
    }
    // Element annotation
    if (cborMap.contains(QString("choicesAllMatching"))) {
      mChoicesAllMatching.deserialize(cborMap.value("choicesAllMatching"));
    }

    if (cborMap.contains(QString("Placement"))) {
      mPlacementAnnotation = PlacementAnnotation(mpParentModel);
      mPlacementAnnotation.deserialize(cborMap.value("Placement").toMap());
    }

    if (cborMap.contains(QString("Dialog"))) {
      mHasDialogAnnotation = true;
      mDialogAnnotation = DialogAnnotation();
      mDialogAnnotation.deserialize(cborMap.value("Dialog").toMap());
    }

    if (cborMap.contains(QString("Evaluate"))) {
      mEvaluate.deserialize(cborMap.value("Evaluate"));
    }

    if (cborMap.contains(QString("choices"))) {
      mChoices.deserialize(cborMap.value("choices").toMap());
    }
    // Connection annotation
    if (cborMap.contains(QString("Line"))) {
      mpLine = std::make_unique<Line>(mpParentModel);
      mpLine->deserialize(cborMap.value("Line").toMap());
    }

    if (cborMap.contains(QString("Text"))) {
      mpText = std::make_unique<Text>(mpParentModel);
      mpText->deserialize(cborMap.value("Text").toMap());
    }
    // Extend annotation
    if (cborMap.contains(QString("IconMap"))) {
      mIconMap.deserialize(cborMap.value("IconMap").toMap());
    }

    if (cborMap.contains(QString("DiagramMap"))) {
      mDiagramMap.deserialize(cborMap.value("DiagramMap").toMap());
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

  void Dimensions::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("absyn"))) {
      QCborArray absynDimsArray = cborMap.value("absyn").toArray();
      foreach (auto absynDim, absynDimsArray) {
        mAbsynDims.append(absynDim.toString());
      }
    }

    if (cborMap.contains(QString("typed"))) {
      QCborArray typedDimsArray = cborMap.value("typed").toArray();
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

  void Modifier::deserialize(const QCborValue &cborValue)
  {
    if (cborValue.isMap()) {
      QCborMap modifiers = cborValue.toMap();
      for (QCborMap::iterator modifiersIterator = modifiers.begin(); modifiersIterator != modifiers.end(); ++modifiersIterator) {
        const QString modifierKey = modifiersIterator.key().toString();
        const QCborValue modifierValue = modifiersIterator.value();
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
      mValue = cborValue.toString();
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

  void Replaceable::deserialize(const QCborValue &cborValue)
  {
    if (cborValue.isMap()) {
      QCborMap replaceableMap = cborValue.toMap();
      mConstrainedby = replaceableMap.value("constrainedby").toString();
      mModifier.deserialize(replaceableMap.value("modifiers"));

      if (replaceableMap.contains(QString("comment"))) {
        mComment = replaceableMap.value("comment").toString();
      }

      if (replaceableMap.contains(QString("annotation"))) {
        mpAnnotation = std::make_unique<Annotation>(mpParentModel);
        mpAnnotation->deserialize(replaceableMap.value("annotation").toMap());
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

  void Prefixes::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("public"))) {
      mPublic = cborMap.value("public").toBool();
    }

    if (cborMap.contains(QString("final"))) {
      mFinal = cborMap.value("final").toBool();
    }

    if (cborMap.contains(QString("inner"))) {
      mInner = cborMap.value("inner").toBool();
    }

    if (cborMap.contains(QString("outer"))) {
      mOuter = cborMap.value("outer").toBool();
    }

    if (cborMap.contains(QString("replaceable"))) {
      mpReplaceable = std::make_unique<Replaceable>(mpParentModel);
      mpReplaceable->deserialize(cborMap.value("replaceable"));
    }

    if (cborMap.contains(QString("redeclare"))) {
      mRedeclare = cborMap.value("redeclare").toBool();
    }

    if (cborMap.contains(QString("partial"))) {
      mPartial = cborMap.value("partial").toBool();
    }

    if (cborMap.contains(QString("encapsulated"))) {
      mEncapsulated = cborMap.value("encapsulated").toBool();
    }

    if (cborMap.contains(QString("connector"))) {
      mConnector = cborMap.value("connector").toString();
    }

    if (cborMap.contains(QString("variability"))) {
      mVariability = cborMap.value("variability").toString();
    }

    if (cborMap.contains(QString("direction"))) {
      mDirection = cborMap.value("direction").toString();
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

  void Source::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("filename"))) {
      mFileName = cborMap.value("filename").toString();
    }

    if (cborMap.contains(QString("lineStart"))) {
      mLineStart = cborMap.value("lineStart").toInteger();
    }

    if (cborMap.contains(QString("columnStart"))) {
      mColumnStart = cborMap.value("columnStart").toInteger();
    }

    if (cborMap.contains(QString("lineEnd"))) {
      mLineEnd = cborMap.value("lineEnd").toInteger();
    }

    if (cborMap.contains(QString("columnEnd"))) {
      mColumnEnd = cborMap.value("columnEnd").toInteger();
    }

    if (cborMap.contains(QString("readonly"))) {
      mReadonly = cborMap.value("readonly").toBool();
    }
  }

  Model::Model(const QJsonObject &jsonObject, Element *pParentElement)
  {
    mpParentElement = pParentElement;
    initialize();
    mModelJson = jsonObject;
    deserializeJson();
  }

  Model::Model(const QCborMap &cborMap, Element *pParentElement)
  {
    mpParentElement = pParentElement;
    initialize();
    mCborMap = cborMap;
    deserializeCbor();
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

  void Model::deserializeJson()
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

  void Model::deserializeCbor()
  {
    if (mCborMap.contains(QString("name"))) {
      mName = mCborMap.value("name").toString();
    }

    if (mCborMap.contains(QString("missing"))) {
      mMissing = mCborMap.value("missing").toBool();
    }

    if (mCborMap.contains(QString("dims"))) {
      mDims.deserialize(mCborMap.value("dims").toMap());
    }

    if (mCborMap.contains(QString("restriction"))) {
      mRestriction = mCborMap.value("restriction").toString();
    }

    if (mCborMap.contains(QString("prefixes"))) {
      mpPrefixes->deserialize(mCborMap.value("prefixes").toMap());
    }

    QCborArray elements = mCborMap.value("elements").toArray();

    foreach (const QCborValue &element, elements) {
      QCborMap elementMap = element.toMap();
      QString kind = elementMap.value("$kind").toString();

      if (kind.compare(QStringLiteral("extends")) == 0) {
        mElements.append(new Extend(this, elementMap));
      } else if (kind.compare(QStringLiteral("component")) == 0) {
        mElements.append(new Component(this, elementMap));
      } else if (kind.compare(QStringLiteral("class")) == 0) {
        mElements.append(new ReplaceableClass(this, elementMap));
      } else {
        qDebug() << "Unhandled kind of element" << kind;
      }
    }

    if (mCborMap.contains(QString("comment"))) {
      mComment = mCborMap.value("comment").toString();
    }

    if (mCborMap.contains(QString("annotation"))) {
      mpAnnotation->deserialize(mCborMap.value("annotation").toMap());
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

    if (mCborMap.contains(QString("connections"))) {
      QCborArray connections = mCborMap.value("connections").toArray();
      foreach (QCborValue connection, connections) {
        QCborMap connectionObject = connection.toMap();
        if (!connectionObject.isEmpty()) {
          Connection *pConnection = new Connection(this);
          pConnection->deserialize(connection.toMap());
          mConnections.append(pConnection);
        }
      }
    }

    if (mCborMap.contains(QString("transitions"))) {
      QCborArray transitions = mCborMap.value("transitions").toArray();
      foreach (QCborValue transition, transitions) {
        QCborMap transitionObject = transition.toMap();
        if (!transitionObject.isEmpty()) {
          Transition *pTransition = new Transition(this);
          pTransition->deserialize(transition.toMap());
          mTransitions.append(pTransition);
        }
      }
    }

    if (mCborMap.contains(QString("initialStates"))) {
      QCborArray initialStates = mCborMap.value("initialStates").toArray();
      foreach (QCborValue initialState, initialStates) {
        QCborMap initialStateObject = initialState.toMap();
        if (!initialStateObject.isEmpty()) {
          InitialState *pInitialState = new InitialState(this);
          pInitialState->deserialize(initialState.toMap());
          mInitialStates.append(pInitialState);
        }
      }
    }

    if (mCborMap.contains(QString("source"))) {
      mSource.deserialize(mCborMap.value("source").toMap());
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
    mName = "";
    mMissing = false;
    mRestriction = "";
    mpPrefixes = std::make_unique<Prefixes>(this);
    mComment = "";
    mpAnnotation = std::make_unique<Annotation>(this);
    mElements.clear();
    mConnections.clear();
    mTransitions.clear();
    mInitialStates.clear();
  }

  Element::Element(Model *pParentModel)
  {
    mpParentModel = pParentModel;
    mpPrefixes = std::make_unique<Prefixes>(pParentModel);
    mComment = "";
    mpAnnotation = std::make_unique<Annotation>(pParentModel);
  }

  Element::~Element()
  {
    if (mpModel) {
      delete mpModel;
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

  /*!
   * \brief Component::getComment
   * Returns the Component comment.
   * Prefer the comment given in replaceable part.
   * \return
   */
  QString Element::getComment() const
  {
    if (mpPrefixes->getReplaceable() && !mpPrefixes->getReplaceable()->getComment().isEmpty()) {
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
    if (mpPrefixes->getReplaceable() && mpPrefixes->getReplaceable()->getAnnotation()) {
      return mpPrefixes->getReplaceable()->getAnnotation();
    } else {
      return mpAnnotation.get();
    }
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

  Extend::Extend(Model *pParentModel, const QCborMap &cborMap)
    : Element(pParentModel)
  {
    deserialize(cborMap);
  }

  void Extend::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("modifiers")) {
      mModifier.deserialize(jsonObject.value("modifiers"));
    }

    if (jsonObject.contains("annotation")) {
      mpAnnotation->deserialize(jsonObject.value("annotation").toObject());
    }

    if (jsonObject.contains("baseClass")) {
      if (jsonObject.value("baseClass").isString()) {
        mBaseClass = jsonObject.value("baseClass").toString();
      } else if (jsonObject.value("baseClass").isObject()) {
        mpModel = new Model(jsonObject.value("baseClass").toObject(), this);
        mBaseClass = mpModel->getName();
      }
    }
  }

  void Extend::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("modifiers"))) {
      mModifier.deserialize(cborMap.value("modifiers"));
    }

    if (cborMap.contains(QString("annotation"))) {
      mpAnnotation->deserialize(cborMap.value("annotation").toMap());
    }

    if (cborMap.contains(QString("baseClass"))) {
      if (cborMap.value("baseClass").isString()) {
        mBaseClass = cborMap.value("baseClass").toString();
      } else if (cborMap.value("baseClass").isMap()) {
        mpModel = new Model(cborMap.value("baseClass").toMap(), this);
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

  QString Extend::getRootType() const
  {
    if (mpModel && mpModel->isType() && mpModel->getElements().size() > 0) {
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

  Component::Component(Model *pParentModel, const QCborMap &cborMap)
    : Element(pParentModel)
  {
    deserialize(cborMap);
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
      mDims.deserialize(jsonObject.value("dims").toObject());
    }

    if (jsonObject.contains("prefixes")) {
      mpPrefixes->deserialize(jsonObject.value("prefixes").toObject());
    }

    if (jsonObject.contains("comment")) {
      mComment = jsonObject.value("comment").toString();
    }

    if (jsonObject.contains("annotation")) {
      mpAnnotation->deserialize(jsonObject.value("annotation").toObject());
    }
  }

  void Component::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("name"))) {
      mName = cborMap.value("name").toString();
    }

    if (cborMap.contains(QString("condition"))) {
      mCondition = cborMap.value("condition").toBool(true);
    }

    if (cborMap.contains(QString("type"))) {
      if (cborMap.value("type").isString()) {
        mType = cborMap.value("type").toString();
      } else if (cborMap.value("type").isMap()) {
        mpModel = new Model(cborMap.value("type").toMap(), this);
        mType = mpModel->getName();
      }
    }

    if (cborMap.contains(QString("modifiers"))) {
      mModifier.deserialize(cborMap.value("modifiers"));
    }

    if (cborMap.contains(QString("value"))) {
      QCborMap valueObject = cborMap.value("value").toMap();

      if (valueObject.contains(QString("value"))) {
        try {
          mBinding.deserialize(valueObject.value("value"));
          mBindingForReset = mBinding;
        } catch (const std::exception &e) {
          qDebug() << "Failed to deserialize json: " << valueObject.value("value");
          qDebug() << e.what();
        }
      } else if (valueObject.contains(QString("binding"))) {
        try {
          mBinding.deserialize(valueObject.value("binding"));
          mBindingForReset = mBinding;
        } catch (const std::exception &e) {
          qDebug() << "Failed to deserialize json: " << valueObject.value("binding");
          qDebug() << e.what();
        }
      }
    }

    if (cborMap.contains(QString("dims"))) {
      mDims.deserialize(cborMap.value("dims").toMap());
    }

    if (cborMap.contains(QString("prefixes"))) {
      mpPrefixes->deserialize(cborMap.value("prefixes").toMap());
    }

    if (cborMap.contains(QString("comment"))) {
      mComment = cborMap.value("comment").toString();
    }

    if (cborMap.contains(QString("annotation"))) {
      mpAnnotation->deserialize(cborMap.value("annotation").toMap());
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

  QString Component::getRootType() const
  {
    if (mpModel && mpModel->isType() && mpModel->getElements().size() > 0) {
      return mpModel->getElements().at(0)->getRootType();
    }
    return mType;
  }

  ReplaceableClass::ReplaceableClass(Model *pParentModel, const QJsonObject &jsonObject)
    : Element(pParentModel)
  {
    mpParentModel = pParentModel;
    mIsShortClassDefinition = false;
    deserialize(jsonObject);
  }

  ReplaceableClass::ReplaceableClass(Model *pParentModel, const QCborMap &cborMap)
    : Element(pParentModel)
  {
    mpParentModel = pParentModel;
    mIsShortClassDefinition = false;
    deserialize(cborMap);
  }

  void ReplaceableClass::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("name")) {
      mName = jsonObject.value("name").toString();
    }

    if (jsonObject.contains("prefixes")) {
      mpPrefixes->deserialize(jsonObject.value("prefixes").toObject());
    }

    if (jsonObject.contains("baseClass")) {
      mIsShortClassDefinition = true;
      mBaseClass = jsonObject.value("baseClass").toString();
    }

    if (jsonObject.contains("dims")) {
      mDims.deserialize(jsonObject.value("dims").toObject());
    }

    if (jsonObject.contains("modifiers")) {
      mModifier.deserialize(jsonObject.value("modifiers"));
    }

    if (jsonObject.contains("annotation")) {
      mpAnnotation->deserialize(jsonObject.value("annotation").toObject());
    }

    if (jsonObject.contains("source")) {
      mSource.deserialize(jsonObject.value("source").toObject());
    }
  }

  void ReplaceableClass::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("name"))) {
      mName = cborMap.value("name").toString();
    }

    if (cborMap.contains(QString("prefixes"))) {
      mpPrefixes->deserialize(cborMap.value("prefixes").toMap());
    }

    if (cborMap.contains(QString("baseClass"))) {
      mIsShortClassDefinition = true;
      mBaseClass = cborMap.value("baseClass").toString();
    }

    if (cborMap.contains(QString("dims"))) {
      mDims.deserialize(cborMap.value("dims").toMap());
    }

    if (cborMap.contains(QString("modifiers"))) {
      mModifier.deserialize(cborMap.value("modifiers"));
    }

    if (cborMap.contains(QString("annotation"))) {
      mpAnnotation->deserialize(cborMap.value("annotation").toMap());
    }

    if (cborMap.contains(QString("source"))) {
      mSource.deserialize(cborMap.value("source").toMap());
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

  void Part::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("name"))) {
      mName = cborMap.value("name").toString();
    }

    if (cborMap.contains(QString("subscripts"))) {
      QCborArray subscripts = cborMap.value("subscripts").toArray();
      foreach (QCborValue subscript, subscripts) {
        mSubScripts.append(QString::number(subscript.toInteger()));
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

  void Connector::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("$kind"))) {
      mKind = cborMap.value("$kind").toString();
    }

    if (cborMap.contains(QString("parts"))) {
      QCborArray parts = cborMap.value("parts").toArray();
      foreach (QCborValue part, parts) {
        Part partObject;
        partObject.deserialize(part.toMap());
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

  void Connection::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("lhs"))) {
      mpStartConnector = std::make_unique<Connector>();
      mpStartConnector->deserialize(cborMap.value("lhs").toMap());
    }

    if (cborMap.contains(QString("rhs"))) {
      mpEndConnector = std::make_unique<Connector>();
      mpEndConnector->deserialize(cborMap.value("rhs").toMap());
    }

    if (cborMap.contains(QString("annotation"))) {
      mpAnnotation->deserialize(cborMap.value("annotation").toMap());
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

  void Transition::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("arguments"))) {
      QCborArray arguments = cborMap.value("arguments").toArray();
      if (arguments.size() > 6) {
        if (arguments.at(0).isMap()) {
          mpStartConnector = std::make_unique<Connector>();
          mpStartConnector->deserialize(arguments.at(0).toMap());
        }

        if (arguments.at(1).isMap()) {
          mpEndConnector = std::make_unique<Connector>();
          mpEndConnector->deserialize(arguments.at(1).toMap());
        }

        mCondition = arguments.at(2).toBool();
        mImmediate = arguments.at(3).toBool();
        mReset = arguments.at(4).toBool();
        mSynchronize = arguments.at(5).toBool();
        mPriority = arguments.at(6).toInteger();
      }
    }

    if (cborMap.contains(QString("annotation"))) {
      mpAnnotation->deserialize(cborMap.value("annotation").toMap());
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

  void InitialState::deserialize(const QCborMap &cborMap)
  {
    if (cborMap.contains(QString("arguments"))) {
      QCborArray arguments = cborMap.value("arguments").toArray();
      if (!arguments.isEmpty()) {
        if (arguments.at(0).isMap()) {
          mpStartConnector = std::make_unique<Connector>();
          mpStartConnector->deserialize(arguments.at(0).toMap());
        }
      }
    }

    if (cborMap.contains(QString("annotation"))) {
      mpAnnotation->deserialize(cborMap.value("annotation").toMap());
    }
  }

  QString InitialState::toString() const
  {
    return "initialState(" % mpStartConnector->getName() % ")";
  }

}
