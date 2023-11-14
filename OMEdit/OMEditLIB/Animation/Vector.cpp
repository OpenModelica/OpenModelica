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

#include "Vector.h"

VectorQuantity& operator++(VectorQuantity& quantity)
{
  quantity = static_cast<VectorQuantity>(static_cast<int>(quantity) + 1);
  return quantity;
}

std::ostream& operator<<(std::ostream& os, const VectorQuantity quantity)
{
  switch (quantity)
  {
    case VectorQuantity::force:
      return os << "force";
    case VectorQuantity::torque:
      return os << "torque";
    case VectorQuantity::velocity:
      return os << "velocity";
    case VectorQuantity::acceleration:
      return os << "acceleration";
    case VectorQuantity::angularVelocity:
      return os << "angular velocity";
    case VectorQuantity::angularAcceleration:
      return os << "angular acceleration";
    case VectorQuantity::relativePosition:
      return os << "relative position";
    default:
      return os;
  }
}

VectorObject::VectorObject()
    : AbstractVisualizerObjectWithVisualProperties(VisualizerType::vector),
      mLengthScale(1.0),
      mRadiusScale(1.0),
      mTransfScale(1.0),
      mAutoScaleCancellationRequired(false),
      mOnlyShaftLengthCounted(false),
      _quantity(VisualizerAttribute(0.0)),
      _headAtOrigin(VisualizerAttribute(0.0)),
      _twoHeadedArrow(VisualizerAttribute(0.0))
{
  _coords[0] = VisualizerAttribute(1.0);
  _coords[1] = VisualizerAttribute(0.0);
  _coords[2] = VisualizerAttribute(0.0);
}

void VectorObject::dumpVisualizerAttributes()
{
  AbstractVisualizerObjectWithVisualProperties::dumpVisualizerAttributes();
  std::cout << "coords " << _coords[0].getValueString() << " , " << _coords[1].getValueString() << " , " << _coords[2].getValueString() << std::endl;
  std::cout << "quantity " << _quantity.getValueString() << " = " << getQuantity() << std::endl;
  std::cout << "headAtOrigin " << _headAtOrigin.getValueString() << " = " << (hasHeadAtOrigin() ? "true" : "false") << std::endl;
  std::cout << "twoHeadedArrow " << _twoHeadedArrow.getValueString() << " = " << (isTwoHeadedArrow() ? "true" : "false") << std::endl;
}
