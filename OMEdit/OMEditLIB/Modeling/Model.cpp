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

#include <QRectF>
#include <QtMath>

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

    qreal left = qMin(leftBottom.x(), topRight.y());
    qreal bottom = qMin(leftBottom.y(), topRight.x());
    qreal right = qMax(leftBottom.x(), topRight.y());
    qreal top = qMax(leftBottom.y(), topRight.x());
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

  Color::Color()
  {
    mColor = Qt::black;
  }

  void Color::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 3) {
      mColor.setRed(jsonArray.at(0).toInt());
      mColor.setGreen(jsonArray.at(1).toInt());
      mColor.setBlue(jsonArray.at(2).toInt());
    }
  }

  FilledShape::FilledShape()
  {
    mPattern = LinePattern::Solid;
    mFillPattern = FillPattern::None;
    mLineThickness = 0.25;
  }

  void FilledShape::deserialize(const QJsonArray &jsonArray)
  {
    mLineColor.deserialize(jsonArray.at(3).toArray());
    mFillColor.deserialize(jsonArray.at(4).toArray());
//    if (jsonArray.contains("pattern")) {

//    }
//    if (jsonArray.contains("pattern")) {

//    }
    mLineThickness = jsonArray.at(7).toDouble();
  }

  Shape::Shape()
    : GraphicItem(), FilledShape()
  {

  }

  Shape::~Shape() = default;

  Rectangle::Rectangle()
  {
    mBorderPattern = BorderPattern::None;
    mRadius = 0;
  }

  void Rectangle::deserialize(const QJsonArray &jsonArray)
  {
    if (jsonArray.size() == 11) {
      GraphicItem::deserialize(jsonArray);
      FilledShape::deserialize(jsonArray);

  //    if (jsonArray.contains("borderPattern")) {

  //    }
      mExtent.deserialize(jsonArray.at(9).toArray());
      mRadius = jsonArray.at(10).toDouble();
    }
  }

  Ellipse::Ellipse()
  {
    mStartAngle = 0;
    mEndAngle = 360;
    if (mStartAngle == 0 && mEndAngle == 360) {
      mClosure = EllipseClosure::Chord;
    } else {
      mClosure = EllipseClosure::Radial;
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
      //    if (jsonArray.contains("closure")) {

      //    }
    }
  }

  IconDiagramAnnotation::IconDiagramAnnotation() = default;

  void IconDiagramAnnotation::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("coordinateSystem")) {
      mCoordinateSystem.deserialize(jsonObject.value("coordinateSystem").toObject());
    }

    if (jsonObject.contains("graphics")) {
      QJsonArray graphicsArray = jsonObject.value("graphics").toArray();
      for (int i = 0; i < graphicsArray.size(); ++i) {
        QJsonObject graphicObject = graphicsArray.at(i).toObject();
        if (graphicObject.contains("name")) {
          const QString name = graphicObject.value("name").toString();
          if (name.compare(QStringLiteral("Rectangle")) == 0) {
            Rectangle *pRectangle = new Rectangle;
            pRectangle->deserialize(graphicObject.value("elements").toArray());
            mGraphics.append(pRectangle);
          } else if (name.compare(QStringLiteral("Ellipse")) == 0) {
            Ellipse *pEllipse = new Ellipse;
            pEllipse->deserialize(graphicObject.value("elements").toArray());
            mGraphics.append(pEllipse);
          }
        }
      }
    }
  }

  Model::Model() = default;

  void Model::deserialize(const QJsonObject &jsonObject)
  {
    if (jsonObject.contains("name")) {
      mName = jsonObject.value("name").toString();
    }

    if (jsonObject.contains("extends")) {
      QJsonArray extends = jsonObject.value("extends").toArray();
      foreach (QJsonValue extend, extends) {
        Extend *pExtend = new Extend;
        pExtend->deserialize(extend.toObject());
        mExtends.append(pExtend);
      }
    }

    if (jsonObject.contains("annotation")) {
      QJsonObject annotation = jsonObject.value("annotation").toObject();
      if (annotation.contains("Icon")) {
        mIconAnnotation.deserialize(annotation.value("Icon").toObject());
      }
      if (annotation.contains("Diagram")) {
        mIconAnnotation.deserialize(annotation.value("Diagram").toObject());
      }
      if (jsonObject.contains("components")) {
        QJsonObject componentsJsonObject = jsonObject.value("components").toObject();
        for (QJsonObject::const_iterator componentsIterator = componentsJsonObject.begin(); componentsIterator != componentsJsonObject.end(); ++componentsIterator) {
          Element *pElement = new Element;
          pElement->setName(componentsIterator.key());
          pElement->deserialize(componentsJsonObject.value(componentsIterator.key()).toObject());
          mElements.append(pElement);
        }
      }
    }
  }

  void Model::serialize(QJsonObject &jsonObject) const
  {
    jsonObject["name"] = mName;
  }

  Element::Element()
    : Model()
  {

  }

  void Element::deserialize(const QJsonObject &jsonObject)
  {
    Model::deserialize(jsonObject);

    if (jsonObject.contains("type") && jsonObject.value("type").isString()) {
      mType = jsonObject.value("type").toString();
    }

    if (jsonObject.contains("modifier")) {
      mModifier = jsonObject.value("modifier").toString();
    }
  }

  Extend::Extend()
    : Model()
  {

  }

  void Extend::deserialize(const QJsonObject &jsonObject)
  {
    Model::deserialize(jsonObject);
  }

}
