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

/*! Equivalent to Modelica.Mechanics.MultiBody.Types.VectorQuantity */
enum class VectorQuantity {force = 1, torque, velocity, acceleration, angularVelocity, angularAcceleration, relativePosition};

std::ostream& operator<<(std::ostream& os, const VectorQuantity quantity);

class VectorObject : public AbstractVisualizerObject
{
public:
  VectorObject();
  ~VectorObject() = default;
  VectorObject(const VectorObject&) = default;
  VectorObject& operator=(const VectorObject&) = default;
  void dumpVisualizerAttributes() const override;
  float getScale() const;
  float getLength() const;
  float getRadius() const {return kRadius;}
  float getHeadLength() const {return kHeadLength;}
  float getHeadRadius() const {return kHeadRadius;}
  VectorQuantity getQuantity() const {return static_cast<VectorQuantity>(_quantity.exp);}
  bool hasHeadAtOrigin() const {return _headAtOrigin.exp;}
  bool isTwoHeadedArrow() const {return _twoHeadedArrow.exp;}
private:
  const float kRadius      = 0.0125; //!< Modelica.Mechanics.MultiBody.World.defaultArrowDiameter / 2 = 1 / 40 / 2 = 0.0125
  const float kHeadLength  = 0.1000; //!< Modelica.Mechanics.MultiBody.Types.Defaults.ArrowHeadLengthFraction * (2 * kRadius) = 4 * 0.025 = 0.1000
  const float kHeadRadius  = 0.0375; //!< Modelica.Mechanics.MultiBody.Types.Defaults.ArrowHeadWidthFraction * (2 * kRadius) / 2 = 3 * 0.025 / 2 = 0.0375
  const float kScaleForce  =   1200; //!< Modelica.Mechanics.MultiBody.Examples.Elementary.ForceAndTorque.world.defaultN_to_m = 1200
  const float kScaleTorque =    120; //!< Modelica.Mechanics.MultiBody.Examples.Elementary.ForceAndTorque.world.defaultNm_to_m = 120
public:
  VisualizerAttribute _coords[3];
  VisualizerAttribute _quantity;
  VisualizerAttribute _headAtOrigin;
  VisualizerAttribute _twoHeadedArrow;
};

#endif
