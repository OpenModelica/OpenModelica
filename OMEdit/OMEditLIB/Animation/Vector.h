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

#ifndef VECTOR_H
#define VECTOR_H

#include "AbstractVisualizer.h"

#include <cmath>
#include <limits>

/*! Equivalent to Modelica.Mechanics.MultiBody.Types.VectorQuantity */
enum class VectorQuantity {force = 1, torque, velocity, acceleration, angularVelocity, angularAcceleration, relativePosition, END, BEGIN = force};

VectorQuantity& operator++(VectorQuantity& quantity);

std::ostream& operator<<(std::ostream& os, const VectorQuantity quantity);

class VectorObject final : public AbstractVisualizerObjectWithVisualProperties<VectorObject>
{
public:
  VectorObject();
  ~VectorObject() = default;
  VectorObject(const VectorObject&) = default;
  VectorObject& operator=(const VectorObject&) = default;
  VectorObject* asVector() override final {return this;}
  void dumpVisualizerAttributes() override;
  void setLengthScale(const float scale) {mLengthScale = scale;}
  void setRadiusScale(const float scale) {mRadiusScale = scale;}
  void setAutoLengthScaleCancellation(const float scale) {mAutoLengthScaleCancellation = scale;}
  void setAutoRadiusScaleCancellation(const float scale) {mAutoRadiusScaleCancellation = scale;}
  float getAutoLengthScaleCancellation() const {return mAutoLengthScaleCancellation;}
  float getAutoRadiusScaleCancellation() const {return mAutoRadiusScaleCancellation;}
  void setAutoScaleCancellationRequired(const bool autoScaleCancellationRequired) {mAutoScaleCancellationRequired = autoScaleCancellationRequired;}
  bool getAutoScaleCancellationRequired() const {return mAutoScaleCancellationRequired;}
  void setOnlyShaftLengthCounted(const bool onlyShaftLengthCounted) {mOnlyShaftLengthCounted = onlyShaftLengthCounted;}
  bool hasOnlyShaftLengthCounted() const {return mOnlyShaftLengthCounted;}
  void setInvisible() {mHidden = true;}
  void setVisible() {mHidden = false;}
  void setCoordinates(const float x, const float y, const float z) {_coords[0].exp = x, _coords[1].exp = y, _coords[2].exp = z;}
  void getCoordinates(float* x, float* y, float* z) const {*x = _coords[0].exp, *y = _coords[1].exp, *z = _coords[2].exp;}
  float getLength    () const {return mHidden ? 0 : mAutoLengthScaleCancellation * mLengthScale * std::sqrt(_coords[0].exp * _coords[0].exp + _coords[1].exp * _coords[1].exp + _coords[2].exp * _coords[2].exp);}
  float getRadius    () const {return mHidden ? 0 : mAutoRadiusScaleCancellation * mRadiusScale * kRadius;}
  float getHeadLength() const {return mHidden ? 0 : mAutoRadiusScaleCancellation * mRadiusScale * kHeadLength;}
  float getHeadRadius() const {return mHidden ? 0 : mAutoRadiusScaleCancellation * mRadiusScale * kHeadRadius;}
  VectorQuantity getQuantity() const {return static_cast<VectorQuantity>(_quantity.exp);}
  bool areCoordinatesConstant() const {return _coords[0].isConst && _coords[1].isConst && _coords[2].isConst;}
  bool hasHeadAtOrigin() const {return _headAtOrigin.exp;}
  bool isTwoHeadedArrow() const {return _twoHeadedArrow.exp;}
  bool isDrawnOnTop          () const {return getQuantity() != VectorQuantity::relativePosition;}
  bool isLengthAdjustable    () const {return getQuantity() != VectorQuantity::relativePosition;}
  bool isRadiusAdjustable    () const {return getQuantity() != VectorQuantity::relativePosition;}
  bool isLengthScaleInvariant() const {return getQuantity() != VectorQuantity::relativePosition;}
  bool isRadiusScaleInvariant() const {return getQuantity() != VectorQuantity::relativePosition;}
public:
  static constexpr float kRadius      = 0.0125; //!< Modelica.Mechanics.MultiBody.World.defaultArrowDiameter / 2 = 1 / 40 / 2 = 0.0125
  static constexpr float kHeadLength  = 0.1000; //!< Modelica.Mechanics.MultiBody.Types.Defaults.ArrowHeadLengthFraction * (2 * kRadius) = 4 * 0.025 = 0.1000
  static constexpr float kHeadRadius  = 0.0375; //!< Modelica.Mechanics.MultiBody.Types.Defaults.ArrowHeadWidthFraction * (2 * kRadius) / 2 = 3 * 0.025 / 2 = 0.0375
  static constexpr float kScaleForce  =   1000; //!< Modelica.Mechanics.MultiBody.World.defaultN_to_m = 1000
  static constexpr float kScaleTorque =   1000; //!< Modelica.Mechanics.MultiBody.World.defaultNm_to_m = 1000
  static constexpr char  kAutoScaleRenderBinName[] = "RenderBin"; //!< See class RenderBinPrototypeList in osgUtil/RenderBin.cpp
  static constexpr int   kAutoScaleRenderBinNum    = std::numeric_limits<int>::max(); //!< To be rendered last
private:
  float mLengthScale;
  float mRadiusScale;
  float mAutoLengthScaleCancellation;
  float mAutoRadiusScaleCancellation;
  bool mAutoScaleCancellationRequired;
  bool mOnlyShaftLengthCounted;
  bool mHidden;
public:
  VisualizerAttribute _coords[3];
  VisualizerAttribute _quantity;
  VisualizerAttribute _headAtOrigin;
  VisualizerAttribute _twoHeadedArrow;
};

#endif
