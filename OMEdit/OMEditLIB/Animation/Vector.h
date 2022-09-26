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

class VectorObject : public AbstractVisualizerObject
{
public:
  VectorObject();
  ~VectorObject() = default;
  VectorObject(const VectorObject&) = default;
  VectorObject& operator=(const VectorObject&) = default;
  VectorObject* asVector() override final {return this;}
  void dumpVisualizerAttributes() const override;
  void setScaleLength(const float scale) {mScaleLength = scale;}
  void setScaleRadius(const float scale) {mScaleRadius = scale;}
  void setScaleTransf(const float scale) {mScaleTransf = scale;}
  float getScaleTransf() const {return mScaleTransf;}
  void setAutoScaleCancellationRequired(const bool required) {mAutoScaleCancellationRequired = required;}
  bool getAutoScaleCancellationRequired() const {return mAutoScaleCancellationRequired;}
  float getLength    () const {return mScaleTransf * mScaleLength * std::sqrt(_coords[0].exp * _coords[0].exp + _coords[1].exp * _coords[1].exp + _coords[2].exp * _coords[2].exp);}
  float getRadius    () const {return mScaleTransf * mScaleRadius * kRadius    ;}
  float getHeadLength() const {return mScaleTransf * mScaleRadius * kHeadLength;}
  float getHeadRadius() const {return mScaleTransf * mScaleRadius * kHeadRadius;}
  VectorQuantity getQuantity() const {return static_cast<VectorQuantity>(_quantity.exp);}
  bool hasHeadAtOrigin() const {return _headAtOrigin.exp;}
  bool isTwoHeadedArrow() const {return _twoHeadedArrow.exp;}
  bool isAdjustableRadius() const {return getQuantity() != VectorQuantity::relativePosition;}
  bool isAdjustableLength() const {return getQuantity() != VectorQuantity::relativePosition;}
  bool isScaleInvariant  () const {return getQuantity() != VectorQuantity::relativePosition;}
  bool isDrawnOnTop      () const {return getQuantity() != VectorQuantity::relativePosition;}
public:
  static constexpr float kRadius      = 0.0125; //!< Modelica.Mechanics.MultiBody.World.defaultArrowDiameter / 2 = 1 / 40 / 2 = 0.0125
  static constexpr float kHeadLength  = 0.1000; //!< Modelica.Mechanics.MultiBody.Types.Defaults.ArrowHeadLengthFraction * (2 * kRadius) = 4 * 0.025 = 0.1000
  static constexpr float kHeadRadius  = 0.0375; //!< Modelica.Mechanics.MultiBody.Types.Defaults.ArrowHeadWidthFraction * (2 * kRadius) / 2 = 3 * 0.025 / 2 = 0.0375
  static constexpr float kScaleForce  =   1000; //!< Modelica.Mechanics.MultiBody.World.defaultN_to_m = 1000
  static constexpr float kScaleTorque =   1000; //!< Modelica.Mechanics.MultiBody.World.defaultNm_to_m = 1000
  static constexpr char  kAutoScaleRenderBinName[] = "RenderBin"; //!< See class RenderBinPrototypeList in osgUtil/RenderBin.cpp
  static constexpr int   kAutoScaleRenderBinNum    = std::numeric_limits<int>::max(); //!< To be rendered last
private:
  float mScaleLength;
  float mScaleRadius;
  float mScaleTransf;
  bool mAutoScaleCancellationRequired;
public:
  VisualizerAttribute _coords[3];
  VisualizerAttribute _quantity;
  VisualizerAttribute _headAtOrigin;
  VisualizerAttribute _twoHeadedArrow;
};

#endif
