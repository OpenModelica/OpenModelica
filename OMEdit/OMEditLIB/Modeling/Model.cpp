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

#include <QRectF>
#include <QtMath>
#include <QVariant>
#include <QStringBuilder>

namespace ModelInstance
{
  Point::Point() = default;

  Point::Point(double x, double y)
  {
    mValue[0] = x;
    mValue[1] = y;
  }

  Point::Point(const Point &point)
  {
    mValue[0] = point.x();
    mValue[1] = point.y();
  }

  void Point::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 2) {
      mValue[0] = jsonArray.at(0).toDouble();
      mValue[1] = jsonArray.at(1).toDouble();
    }
  }

  bool Point::operator==(const Point &point)
  {
    return (qFuzzyCompare(point.x(), this->x()) && qFuzzyCompare(point.y(), this->y()));
  }

  Extent::Extent() = default;

  Extent::Extent(const Point &extent1, const Point extent2)
  {
    mPoint[0] = extent1;
    mPoint[1] = extent2;
  }

  Extent::Extent(const Extent &extent)
  {
    mPoint[0] = extent.getExtent1();
    mPoint[1] = extent.getExtent2();
  }

  void Extent::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 2) {
      mPoint[0].deserialize(jsonArray.at(0).toArray());
      mPoint[1].deserialize(jsonArray.at(1).toArray());
    }
  }

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

  void CoordinateSystem::setExtent(const Extent &extent)
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

  void CoordinateSystem::setGrid(const Point &grid)
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
    Point leftBottom = mExtent.getExtent1();
    Point topRight = mExtent.getExtent2();

    qreal left = qMin(leftBottom.x(), topRight.x());
    qreal bottom = qMin(leftBottom.y(), topRight.y());
    qreal right = qMax(leftBottom.x(), topRight.x());
    qreal top = qMax(leftBottom.y(), topRight.y());
    return QRectF(left, bottom, qFabs(left - right), qFabs(bottom - top));
  }

  void CoordinateSystem::reset()
  {
    setExtent(Extent(Point(-100, -100), Point(100, 100)));
    setHasExtent(false);
    setPreserveAspectRatio(true);
    setHasPreserveAspectRatio(false);
    setInitialScale(0.1);
    setHasInitialScale(false);
    setGrid(Point(2, 2));
    setHasGrid(false);
  }

  bool CoordinateSystem::isComplete() const
  {
    return mHasExtent && mHasPreserveAspectRatio && mHasInitialScale && mHasGrid;
  }

  void CoordinateSystem::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("extent")) {
      mExtent.deserialize(jsonObject.value("extent").toArray());
      setHasExtent(true);
    }
    if (jsonObject.contains("preserveAspectRatio")) {
      setPreserveAspectRatio(jsonObject.value("preserveAspectRatio").toBool());
    }
    if (jsonObject.contains("initialScale")) {
      setInitialScale(jsonObject.value("initialScale").toDouble());
    }
    if (jsonObject.contains("grid")) {
      mGrid.deserialize(jsonObject.value("grid").toArray());
      setHasGrid(true);
    }
  }

  GraphicItem::GraphicItem()
  {
    mVisible = true;
    mOrigin = Point(0, 0);
    mRotation = 0;
  }

  void GraphicItem::deserialize(const QJsonArray &jsonArray)
  {
    mVisible = jsonArray.at(0).toBool();
    mOrigin.deserialize(jsonArray.at(1).toArray());
    mRotation = jsonArray.at(2).toDouble();
  }

  void GraphicItem::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("visible")) {
      mVisible = jsonObject.value("visible").toBool();
    }

    if (jsonObject.contains("origin")) {
      mOrigin.deserialize(jsonObject.value("origin").toArray());
    }

    if (jsonObject.contains("rotation")) {
      mRotation = jsonObject.value("rotation").toDouble();
    }
  }

  Color::Color()
  {
    mColor = Qt::black;
  }

  void Color::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 3) {
      // if invalid color
      if (jsonArray.at(0).toInt() == -1 && jsonArray.at(1).toInt() == -1 && jsonArray.at(2).toInt() == -1) {
        mColor = QColor();
      } else {
        mColor.setRed(jsonArray.at(0).toInt());
        mColor.setGreen(jsonArray.at(1).toInt());
        mColor.setBlue(jsonArray.at(2).toInt());
      }
    }
  }

  bool Color::operator==(const Color &color) const
  {
    return (color.getColor() == this->getColor());
  }

  FilledShape::FilledShape()
  {
    mPattern = "LinePattern.Solid";
    mFillPattern = "FillPattern.None";
    mLineThickness = 0.25;
  }

  void FilledShape::deserialize(const QJsonArray &jsonArray)
  {
    mLineColor.deserialize(jsonArray.at(3).toArray());
    mFillColor.deserialize(jsonArray.at(4).toArray());
    QJsonObject pattern = jsonArray.at(5).toObject();
    if (pattern.contains("name")) {
      mPattern = pattern.value("name").toString();
    }
    QJsonObject fillPattern = jsonArray.at(6).toObject();
    if (fillPattern.contains("name")) {
      mFillPattern = fillPattern.value("name").toString();
    }
    mLineThickness = jsonArray.at(7).toDouble();
  }

  void FilledShape::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("lineColor")) {
      mLineColor.deserialize(jsonObject.value("lineColor").toArray());
    }

    if (jsonObject.contains("fillColor")) {
      mFillColor.deserialize(jsonObject.value("fillColor").toArray());
    }

    if (jsonObject.contains("pattern")) {
      QJsonObject pattern = jsonObject.value("pattern").toObject();
      if (pattern.contains("name")) {
        mPattern = pattern.value("name").toString();
      }
    }

    if (jsonObject.contains("fillPattern")) {
      QJsonObject fillPattern = jsonObject.value("fillPattern").toObject();
      if (fillPattern.contains("name")) {
        mFillPattern = fillPattern.value("name").toString();
      }
    }

    if (jsonObject.contains("lineThickness")) {
      mLineThickness = jsonObject.value("lineThickness").toDouble();
    }
  }

  Shape::Shape()
    : GraphicItem(), FilledShape()
  {

  }

  Shape::~Shape() = default;

  Line::Line()
  {
    mPoints.clear();
    mPattern = "LinePattern.Solid";
    mThickness = 0.25;
    mArrow[0] = "Arrow.None";
    mArrow[1] = "Arrow.None";
    mArrowSize = 3;
    mSmooth = "Smooth.None";
  }

  void Line::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 10) {
      GraphicItem::deserialize(jsonArray);

      QJsonArray points = jsonArray.at(3).toArray();
      foreach (QJsonValue pointValue, points) {
        Point point;
        point.deserialize(pointValue.toArray());
        mPoints.append(point);
      }
      mColor.deserialize(jsonArray.at(4).toArray());
      mPattern = jsonArray.at(5).toString();
      mThickness = jsonArray.at(6).toDouble();
      QJsonArray arrows = jsonArray.at(7).toArray();
      if (arrows.size() == 2) {
        QJsonObject startArrow = arrows.at(0).toObject();
        if (startArrow.contains("name")) {
          mArrow[0] = startArrow.value("name").toString();
        }
        QJsonObject endArrow = arrows.at(1).toObject();
        if (endArrow.contains("name")) {
          mArrow[1] = endArrow.value("name").toString();
        }
      }
      mArrowSize = jsonArray.at(8).toDouble();
      QJsonObject smooth = jsonArray.at(9).toObject();
      if (smooth.contains("name")) {
        mSmooth = smooth.value("name").toString();
      }
    }
  }

  void Line::deserialize(const QJsonObject &jsonObject)
  {
    GraphicItem::deserialize(jsonObject);

    if (jsonObject.contains("points")) {
      QJsonArray points = jsonObject.value("points").toArray();
      foreach (QJsonValue pointValue, points) {
        Point point;
        point.deserialize(pointValue.toArray());
        mPoints.append(point);
      }
    }

    if (jsonObject.contains("color")) {
      mColor.deserialize(jsonObject.value("color").toArray());
    }

    if (jsonObject.contains("pattern")) {
      mPattern = jsonObject.value("pattern").toString();
    }

    if (jsonObject.contains("thickness")) {
      mThickness = jsonObject.value("thickness").toDouble();
    }

    if (jsonObject.contains("arrow")) {
      QJsonArray arrows = jsonObject.value("arrow").toArray();
      if (arrows.size() == 2) {
        QJsonObject startArrow = arrows.at(0).toObject();
        if (startArrow.contains("name")) {
          mArrow[0] = startArrow.value("name").toString();
        }
        QJsonObject endArrow = arrows.at(1).toObject();
        if (endArrow.contains("name")) {
          mArrow[1] = endArrow.value("name").toString();
        }
      }
    }

    if (jsonObject.contains("arrowSize")) {
      mArrowSize = jsonObject.value("arrowSize").toDouble();
    }

    if (jsonObject.contains("smooth")) {
      QJsonObject smooth = jsonObject.value("smooth").toObject();
      if (smooth.contains("name")) {
        mSmooth = smooth.value("name").toString();
      }
    }
  }

  void Line::addPoint(const QPointF &point)
  {
    mPoints.append(Point(point.x(), point.y()));
  }

  void Line::setColor(const QColor &color)
  {
    mColor.setColor(color);
  }

  bool Line::operator==(const Line &line) const
  {
    return (line.getPoints() == this->getPoints()) &&
        (line.getColor() == this->getColor()) &&
        (line.getPattern() == this->getPattern()) &&
        (line.getThickness() == this->getThickness()) &&
        (line.getStartArrow() == this->getStartArrow()) &&
        (line.getEndArrow() == this->getEndArrow()) &&
        (line.getArrowSize() == this->getArrowSize()) &&
        (line.getSmooth() == this->getSmooth());
  }

  Polygon::Polygon()
  {
    mPoints.clear();
    mSmooth = "Smooth.None";
  }

  void Polygon::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 10) {
      GraphicItem::deserialize(jsonArray);
      FilledShape::deserialize(jsonArray);

      QJsonArray points = jsonArray.at(8).toArray();
      foreach (QJsonValue pointValue, points) {
        Point point;
        point.deserialize(pointValue.toArray());
        mPoints.append(point);
      }
      QJsonObject smooth = jsonArray.at(9).toObject();
      if (smooth.contains("name")) {
        mSmooth = smooth.value("name").toString();
      }
    }
  }


  Rectangle::Rectangle()
  {
    mBorderPattern = "BorderPattern::None";
    mRadius = 0;
  }

  void Rectangle::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 11) {
      GraphicItem::deserialize(jsonArray);
      FilledShape::deserialize(jsonArray);

      QJsonObject borderPattern = jsonArray.at(8).toObject();
      if (borderPattern.contains("name")) {
        mBorderPattern = borderPattern.value("name").toString();
      }
      mExtent.deserialize(jsonArray.at(9).toArray());
      mRadius = jsonArray.at(10).toDouble();
    }
  }

  Ellipse::Ellipse()
  {
    mStartAngle = 0;
    mEndAngle = 360;
    if (mStartAngle == 0 && mEndAngle == 360) {
      mClosure = "EllipseClosure::Chord";
    } else {
      mClosure = "EllipseClosure::Radial";
    }
  }

  void Ellipse::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 12) {
      GraphicItem::deserialize(jsonArray);
      FilledShape::deserialize(jsonArray);

      mExtent.deserialize(jsonArray.at(8).toArray());
      mStartAngle = jsonArray.at(9).toDouble();
      mEndAngle = jsonArray.at(10).toDouble();
      QJsonObject closure = jsonArray.at(11).toObject();
      if (closure.contains("name")) {
        mClosure = closure.value("name").toString();
      }
    }
  }

  Text::Text()
  {
    mTextString = "";
    mFontSize = 0;
    mFontName = "";
    mTextStyle.clear();
    mHorizontalAlignment = "TextAlignment.Center";
  }

  void Text::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 15) {
      GraphicItem::deserialize(jsonArray);
      FilledShape::deserialize(jsonArray);

      mExtent.deserialize(jsonArray.at(8).toArray());
      mTextString = jsonArray.at(9).toString();
      mFontSize = jsonArray.at(10).toDouble();
      mTextColor.deserialize(jsonArray.at(11).toArray());
      mFontName = jsonArray.at(12).toString();
      QJsonArray textStyles = jsonArray.at(13).toArray();
      foreach (QJsonValue textStyle, textStyles) {
        QJsonObject textStyleObject = textStyle.toObject();
        if (textStyleObject.contains("name")) {
          mTextStyle.append(textStyleObject.value("name").toString());
        }
      }
      QJsonObject horizontalAlignment = jsonArray.at(14).toObject();
      if (horizontalAlignment.contains("name")) {
        mHorizontalAlignment = horizontalAlignment.value("name").toString();
      }
    }
  }

  void Text::deserialize(const QJsonObject &jsonObject)
  {
    GraphicItem::deserialize(jsonObject);
    FilledShape::deserialize(jsonObject);

    if (jsonObject.contains("extent")) {
      mExtent.deserialize(jsonObject.value("extent").toArray());
    }

    if (jsonObject.contains("string")) {
      mTextString = jsonObject.value("string").toString();
    }

    if (jsonObject.contains("fontSize")) {
      mFontSize = jsonObject.value("fontSize").toDouble();
    }

    if (jsonObject.contains("textColor")) {
      mTextColor.deserialize(jsonObject.value("textColor").toArray());
    }

    if (jsonObject.contains("fontName")) {
      mFontName = jsonObject.value("fontName").toString();
    }

    if (jsonObject.contains("textStyle")) {
      QJsonArray textStyles = jsonObject.value("textStyle").toArray();
      foreach (QJsonValue textStyle, textStyles) {
        QJsonObject textStyleObject = textStyle.toObject();
        if (textStyleObject.contains("name")) {
          mTextStyle.append(textStyleObject.value("name").toString());
        }
      }
    }

    if (jsonObject.contains("horizontalAlignment")) {
      QJsonObject horizontalAlignment = jsonObject.value("horizontalAlignment").toObject();
      if (horizontalAlignment.contains("name")) {
        mHorizontalAlignment = horizontalAlignment.value("name").toString();
      }
    }

//    if (jsonObject.contains("index")) {
//      mIndex = jsonObject.value("index").toDouble();
//    }
  }

  Bitmap::Bitmap()
  {
    mFileName = "";
    mImageSource = "";
  }

  void Bitmap::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 6) {
      GraphicItem::deserialize(jsonArray);

      mExtent.deserialize(jsonArray.at(3).toArray());
      mFileName = jsonArray.at(4).toString();
      mImageSource = jsonArray.at(5).toString();
    }
  }

  IconDiagramAnnotation::IconDiagramAnnotation()
  {
    mGraphics.clear();
  }

  IconDiagramAnnotation::~IconDiagramAnnotation()
  {
    foreach (auto pShape, mGraphics) {
      delete pShape;
    }
  }

  void IconDiagramAnnotation::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("coordinateSystem")) {
      mCoordinateSystem.deserialize(jsonObject.value("coordinateSystem").toObject());
      mMergedCoOrdinateSystem = mCoordinateSystem;
    }

    if (jsonObject.contains("graphics")) {
      QJsonArray graphicsArray = jsonObject.value("graphics").toArray();
      for (int i = 0; i < graphicsArray.size(); ++i) {
        QJsonObject graphicObject = graphicsArray.at(i).toObject();
        if (graphicObject.contains("name") && graphicObject.contains("elements")) {
          const QString name = graphicObject.value("name").toString();
          if (name.compare(QStringLiteral("Line")) == 0) {
            Line *pLine = new Line;
            pLine->deserialize(graphicObject.value("elements").toArray());
            mGraphics.append(pLine);
          } else if (name.compare(QStringLiteral("Polygon")) == 0) {
            Polygon *pPolygon = new Polygon;
            pPolygon->deserialize(graphicObject.value("elements").toArray());
            mGraphics.append(pPolygon);
          } else if (name.compare(QStringLiteral("Rectangle")) == 0) {
            Rectangle *pRectangle = new Rectangle;
            pRectangle->deserialize(graphicObject.value("elements").toArray());
            mGraphics.append(pRectangle);
          } else if (name.compare(QStringLiteral("Ellipse")) == 0) {
            Ellipse *pEllipse = new Ellipse;
            pEllipse->deserialize(graphicObject.value("elements").toArray());
            mGraphics.append(pEllipse);
          } else if (name.compare(QStringLiteral("Text")) == 0) {
            Text *pText = new Text;
            pText->deserialize(graphicObject.value("elements").toArray());
            mGraphics.append(pText);
          } else if (name.compare(QStringLiteral("Bitmap")) == 0) {
            Bitmap *pBitmap = new Bitmap;
            pBitmap->deserialize(graphicObject.value("elements").toArray());
            mGraphics.append(pBitmap);
          }
        }
      }
    }
  }

  Model::Model()
  {
    initialize();
  }

  Model::Model(const QJsonObject &jsonObject)
  {
    initialize();
    mModelJson = jsonObject;
    deserialize();
  }

  Model::~Model()
  {
    foreach (auto pExtend, mExtends) {
      delete pExtend;
    }

    delete mpIconAnnotation;
    delete mpDiagramAnnotation;

    foreach (auto pElement, mElements) {
      delete pElement;
    }

    foreach (auto pConnection, mConnections) {
      delete pConnection;
    }

    foreach (auto pTransition, mTransitions) {
      delete pTransition;
    }

    foreach (auto pInitialState, mInitialStates) {
      delete pInitialState;
    }
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
        mReplaceable = prefixes.value("replaceable").toBool();
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

    if (mModelJson.contains("extends")) {
      QJsonArray extends = mModelJson.value("extends").toArray();
      foreach (QJsonValue extend, extends) {
        Extend *pExtend = new Extend;
        pExtend->deserialize(extend.toObject());
        mExtends.append(pExtend);
      }
    }

    if (mModelJson.contains("comment")) {
      mComment = mModelJson.value("comment").toString();
    }

    if (mModelJson.contains("annotation")) {
      QJsonObject annotation = mModelJson.value("annotation").toObject();

      if (annotation.contains("Icon")) {
        mpIconAnnotation->deserialize(annotation.value("Icon").toObject());
      }

      if (annotation.contains("Diagram")) {
        mpDiagramAnnotation->deserialize(annotation.value("Diagram").toObject());
      }

      if (annotation.contains("DocumentationClass")) {
        mDocumentationClass = annotation.value("DocumentationClass").toBool();
      }

      if (annotation.contains("version")) {
        mVersion = annotation.value("version").toString();
      }

      if (annotation.contains("versionDate")) {
        mVersionDate = annotation.value("versionDate").toString();
      }

      if (annotation.contains("versionBuild")) {
        mVersionDate = QString::number(annotation.value("versionBuild").toInt());
      }

      if (annotation.contains("dateModified")) {
        mDateModified = annotation.value("dateModified").toString();
      }

      if (annotation.contains("preferredView")) {
        mPreferredView = annotation.value("preferredView").toString();
      }

      if (annotation.contains("__Dymola_state")) {
        mState = annotation.value("__Dymola_state").toBool();
      }

      if (annotation.contains("Protection")) {
        QJsonObject protection = annotation.value("Protection").toObject();
        if (protection.contains("access")) {
          QJsonObject access = protection.value("access").toObject();
          if (access.contains("name")) {
            mAccess = access.value("name").toString();
          }
        }
      }
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
    if (!mpIconAnnotation->getCoordinateSystem().isComplete()) {
      readCoordinateSystemFromExtendsClass(true);
    }

    if (!mpDiagramAnnotation->getCoordinateSystem().isComplete()) {
      readCoordinateSystemFromExtendsClass(false);
    }

    if (mModelJson.contains("components")) {
      QJsonArray components = mModelJson.value("components").toArray();
      foreach (QJsonValue component, components) {
        QJsonObject componentObject = component.toObject();
        if (!componentObject.isEmpty()) {
          Element *pElement = new Element(this);
          pElement->deserialize(component.toObject());
          mElements.append(pElement);
        }
      }
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
          Connection *pConnection = new Connection;
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
          Transition *pTransition = new Transition;
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
          InitialState *pInitialState = new InitialState;
          pInitialState->deserialize(initialState.toObject());
          mInitialStates.append(pInitialState);
        }
      }
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

  void Model::readCoordinateSystemFromExtendsClass(bool isIcon)
  {
    /* From Modelica Specification Version 3.5-dev
     * The coordinate system (including preserveAspectRatio) of a class is defined by the following priority:
     * 1. The coordinate system annotation given in the class (if specified).
     * 2. The coordinate systems of the first base-class where the extent on the extends-clause specifies a
     *    null-region (if any). Note that null-region is the default for base-classes, see section 18.6.3.
     * 3. The default coordinate system CoordinateSystem(extent={{-100, -100}, {100, 100}}).
     *
     * Following is the second case.
     */
    foreach (auto pExtend, mExtends) {
      ModelInstance::CoordinateSystem coordinateSystem;
      IconDiagramAnnotation *pIconDiagramAnnotation = 0;
      if (isIcon) {
        coordinateSystem = pExtend->getIconAnnotation()->getCoordinateSystem();
        pIconDiagramAnnotation = mpIconAnnotation;
      } else {
        coordinateSystem = pExtend->getDiagramAnnotation()->getCoordinateSystem();
        pIconDiagramAnnotation = mpDiagramAnnotation;
      }

      if (!pIconDiagramAnnotation->mMergedCoOrdinateSystem.hasExtent() && coordinateSystem.hasExtent()) {
        pIconDiagramAnnotation->mMergedCoOrdinateSystem.setExtent(coordinateSystem.getExtent());
      }
      if (!pIconDiagramAnnotation->mMergedCoOrdinateSystem.hasPreserveAspectRatio() && coordinateSystem.hasPreserveAspectRatio()) {
        pIconDiagramAnnotation->mMergedCoOrdinateSystem.setPreserveAspectRatio(coordinateSystem.getPreserveAspectRatio());
      }
      if (!pIconDiagramAnnotation->mMergedCoOrdinateSystem.hasInitialScale() && coordinateSystem.hasInitialScale()) {
        pIconDiagramAnnotation->mMergedCoOrdinateSystem.setInitialScale(coordinateSystem.getInitialScale());
      }
      if (!pIconDiagramAnnotation->mMergedCoOrdinateSystem.hasGrid() && coordinateSystem.hasGrid()) {
        pIconDiagramAnnotation->mMergedCoOrdinateSystem.setGrid(coordinateSystem.getGrid());
      }
      break; // we only check coordinate system of first inherited class. See the comment in start of function i.e., "The coordinate systems of the first base-class ..."
    }
  }

  bool Model::isParameterConnectorSizing(const QString &parameter)
  {
    foreach (auto pModelElement, mElements) {
      if (pModelElement->getName().compare(parameter) == 0) {
        return pModelElement->getDialogAnnotation().isConnectorSizing();
      }
    }
    return false;
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
    mExtends.clear();
    mComment = "";
    mpIconAnnotation = new IconDiagramAnnotation;
    mpDiagramAnnotation = new IconDiagramAnnotation;
    mDocumentationClass = false;
    mVersion = "";
    mVersionDate = "";
    mVersionBuild = "";
    mDateModified = "";
    mPreferredView = "";
    mState = false;
    mAccess = "";
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
    mOrigin = Point(0, 0);
    mRotation = 0;
  }

  void Transformation::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("origin")) {
      mOrigin.deserialize(jsonObject.value("origin").toArray());
    }
    if (jsonObject.contains("extent")) {
      mExtent.deserialize(jsonObject.value("extent").toArray());
    }
    if (jsonObject.contains("rotation")) {
      mRotation = jsonObject.value("rotation").toDouble();
    }
  }

  PlacementAnnotation::PlacementAnnotation()
  {
    // set the visible to false. Otherwise we get elements in the center of the view.
    mVisible = false;
    mIconVisible = false;
  }

  void PlacementAnnotation::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("visible")) {
      mVisible = jsonObject.value("visible").toBool();
    } else {
      // if there is no visible then assume it to be true.
      mVisible = true;
    }

    if (jsonObject.contains("transformation")) {
      mTransformation.deserialize(jsonObject.value("transformation").toObject());
    }

    if (jsonObject.contains("iconVisible")) {
      mIconVisible = jsonObject.value("iconVisible").toBool();
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
      mFilter = jsonObject.value("filter").toString();
    }

    if (jsonObject.contains("caption")) {
      mCaption = jsonObject.value("caption").toString();
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
      mTab = jsonObject.value("tab").toString();
    }

    if (jsonObject.contains("group")) {
      mGroup = jsonObject.value("group").toString();
    }

    if (jsonObject.contains("enable")) {
      mEnable = jsonObject.value("enable").toBool();
    }

    if (jsonObject.contains("showStartAttribute")) {
      mShowStartAttribute = jsonObject.value("showStartAttribute").toBool();
    }

    if (jsonObject.contains("colorSelector")) {
      mColorSelector = jsonObject.value("colorSelector").toBool();
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
      mGroupImage = jsonObject.value("groupImage").toString();
    }

    if (jsonObject.contains("connectorSizing")) {
      mConnectorSizing = jsonObject.value("connectorSizing").toBool();
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
          return StringHandler::removeFirstLastQuotes(subModifier.getValue());
        } else {
          return Modifier::getModifierValue(subModifier, qualifiedModifierName.takeFirst(), qualifiedModifierName);
        }
      }
    }

    return "";
  }

  Choices::Choices()
  {
    mCheckBox = false;
    mDymolaCheckBox = false;
  }

  void Choices::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("checkBox")) {
      mCheckBox = jsonObject.value("checkBox").toBool();
    }

    if (jsonObject.contains("__Dymola_checkBox")) {
      mDymolaCheckBox = jsonObject.value("__Dymola_checkBox").toBool();
    }
  }

  Element::Element(Model *pParentModel)
  {
    mpParentModel = pParentModel;
    mpModel = 0;
    initialize();
  }

  Element::~Element()
  {
    if (mpModel) {
      delete mpModel;
    }
  }

  void Element::initialize()
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
    mReplaceable = false;
    mRedeclare = false;
    mConnector = "";
    mVariability = "";
    mDirection = "";
    mComment = "";
    mChoicesAllMatching = false;
    mHasDialogAnnotation = false;
  }

  void Element::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("name")) {
      mName = jsonObject.value("name").toString();
    }

    if (jsonObject.contains("condition")) {
      mCondition = jsonObject.value("condition").toBool();
    }

    if (jsonObject.contains("type")) {
      if (jsonObject.value("type").isString()) {
        mType = jsonObject.value("type").toString();
      } else if (jsonObject.value("type").isObject()) {
        mpModel = new Model(jsonObject.value("type").toObject());
        mType = mpModel->getName();
      }
    }

    if (jsonObject.contains("modifiers")) {
      mModifier.deserialize(jsonObject.value("modifiers"));
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
        mReplaceable = prefixes.value("replaceable").toBool();
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
      QJsonObject annotation = jsonObject.value("annotation").toObject();

      if (annotation.contains("choicesAllMatching")) {
        mChoicesAllMatching = annotation.value("choicesAllMatching").toBool();
      }

      if (annotation.contains("Placement")) {
        mPlacementAnnotation.deserialize(annotation.value("Placement").toObject());
      }

      if (annotation.contains("Dialog")) {
        mHasDialogAnnotation = true;
        mDialogAnnotation.deserialize(annotation.value("Dialog").toObject());
      }

      if (annotation.contains("Evaluate")) {
        mEvaluate = annotation.value("Evaluate").toBool();
      }

      if (annotation.contains("choices")) {
        mChoices.deserialize(annotation.value("choices").toObject());
      }
    }
  }

  QString Element::getModifierValueFromType(QStringList modifierNames)
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
        modifierValue = Element::getModifierValueFromInheritedType(mpModel, modifierNames);
      }
    }
    return modifierValue;
  }

  QString Element::getModifierValueFromInheritedType(Model *pModel, QStringList modifierNames)
  {
    QString modifierValue = "";
    foreach (auto pExtend, pModel->getExtends()) {
      modifierValue = pExtend->getModifier().getModifierValue(modifierNames);
      if (modifierValue.isEmpty()) {
        modifierValue = Element::getModifierValueFromInheritedType(pExtend, modifierNames);
      } else {
        return modifierValue;
      }
    }
    return modifierValue;
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
      return QString("%1[%2]").arg(mName, mSubScripts.join(","));
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

  Connection::Connection()
  {
    mpStartConnector = 0;
    mpEndConnector = 0;
    mpLine = 0;
    mpText = 0;
  }

  Connection::~Connection()
  {
    if (mpStartConnector) {
      delete mpStartConnector;
    }
    if (mpEndConnector) {
      delete mpEndConnector;
    }
    if (mpLine) {
      delete mpLine;
    }
    if (mpText) {
      delete mpText;
    }
  }

  void Connection::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("lhs")) {
      mpStartConnector = new Connector;
      mpStartConnector->deserialize(jsonObject.value("lhs").toObject());
    }

    if (jsonObject.contains("rhs")) {
      mpEndConnector = new Connector;
      mpEndConnector->deserialize(jsonObject.value("rhs").toObject());
    }

    if (jsonObject.contains("annotation")) {
      QJsonObject annotation = jsonObject.value("annotation").toObject();
      if (annotation.contains("Line")) {
        mpLine = new Line;
        mpLine->deserialize(annotation.value("Line").toObject());
      }

      if (annotation.contains("Text")) {
        mpText = new Text;
        mpText->deserialize(annotation.value("Text").toObject());
      }
    }
  }

  QString Connection::toString() const
  {
    return "connect(" % mpStartConnector->getName() % ", " % mpEndConnector->getName() % ")";
  }

  Transition::Transition()
  {
    mpStartConnector = 0;
    mpEndConnector = 0;
    mCondition = false;
    mImmediate = true;
    mReset = true;
    mSynchronize = false;
    mPriority = 1;
    mpLine = 0;
    mpText = 0;
  }

  void Transition::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("arguments")) {
      QJsonArray arguments = jsonObject.value("arguments").toArray();
      if (arguments.size() > 6) {
        if (arguments.at(0).isObject()) {
          mpStartConnector = new Connector;
          mpStartConnector->deserialize(arguments.at(0).toObject());
        }

        if (arguments.at(1).isObject()) {
          mpEndConnector = new Connector;
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
      QJsonObject annotation = jsonObject.value("annotation").toObject();
      if (annotation.contains("Line")) {
        mpLine = new Line;
        mpLine->deserialize(annotation.value("Line").toObject());
      }

      if (annotation.contains("Text")) {
        mpText = new Text;
        mpText->deserialize(annotation.value("Text").toObject());
      }
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

  InitialState::InitialState()
  {
    mpStartConnector = 0;
    mpLine = 0;
  }

  void InitialState::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("arguments")) {
      QJsonArray arguments = jsonObject.value("arguments").toArray();
      if (!arguments.isEmpty()) {
        if (arguments.at(0).isObject()) {
          mpStartConnector = new Connector;
          mpStartConnector->deserialize(arguments.at(0).toObject());
        }
      }
    }

    if (jsonObject.contains("annotation")) {
      QJsonObject annotation = jsonObject.value("annotation").toObject();
      if (annotation.contains("Line")) {
        mpLine = new Line;
        mpLine->deserialize(annotation.value("Line").toObject());
      }
    }
  }

  QString InitialState::toString() const
  {
    return "initialState(" % mpStartConnector->getName() % ")";
  }

  Extend::Extend()
    : Model()
  {

  }

  Extend::~Extend()
  {

  }

  void Extend::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("modifiers")) {
      mExtendsModifier.deserialize(jsonObject.value("modifiers"));
    }

    if (jsonObject.contains("baseClass")) {
      Model::setModelJson(jsonObject.value("baseClass").toObject());
      Model::deserialize();
    }

  }

}
