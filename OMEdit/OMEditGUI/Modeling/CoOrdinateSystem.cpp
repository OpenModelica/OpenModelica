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

#include "CoOrdinateSystem.h"

/*!
 * \class CoOrdinateSystem
 * \brief A class to represent the coordinate system of view.
 */
/*!
 * \brief CoOrdinateSystem::CoOrdinateSystem
 */
CoOrdinateSystem::CoOrdinateSystem()
{
  QList<QPointF> extents;
  extents << QPointF(-100, -100) << QPointF(100, 100);
  setExtent(extents);
  setPreserveAspectRatio(true);
  setInitialScale(0.1);
  setGrid(QPointF(2, 2));
  setValid(false);
}

/*!
 * \brief CoOrdinateSystem::CoOrdinateSystem
 * \param coOrdinateSystem
 */
CoOrdinateSystem::CoOrdinateSystem(const CoOrdinateSystem &coOrdinateSystem)
{
  setExtent(coOrdinateSystem.getExtent());
  setPreserveAspectRatio(coOrdinateSystem.getPreserveAspectRatio());
  setInitialScale(coOrdinateSystem.getInitialScale());
  setGrid(coOrdinateSystem.getGrid());
  setValid(coOrdinateSystem.isValid());
}

/*!
 * \brief CoOrdinateSystem::getHorizontalGridStep
 * \return
 */
qreal CoOrdinateSystem::getHorizontalGridStep()
{
  if (mGrid.x() < 1) {
    return 2;
  }
  return mGrid.x();
}

/*!
 * \brief CoOrdinateSystem::getVerticalGridStep
 * \return
 */
qreal CoOrdinateSystem::getVerticalGridStep()
{
  if (mGrid.y() < 1) {
    return 2;
  }
  return mGrid.y();
}
