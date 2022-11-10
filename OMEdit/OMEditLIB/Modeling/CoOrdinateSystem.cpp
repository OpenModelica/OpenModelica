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

#include <QtCore/qmath.h>

/*!
 * \class CoOrdinateSystem
 * \brief A class to represent the coordinate system of view.
 */
/*!
 * \brief CoOrdinateSystem::CoOrdinateSystem
 */
CoOrdinateSystem::CoOrdinateSystem()
{
  reset();
}

/*!
 * \brief CoOrdinateSystem::CoOrdinateSystem
 * \param coOrdinateSystem
 */
CoOrdinateSystem::CoOrdinateSystem(const CoOrdinateSystem &coOrdinateSystem)
{
  setExtent(coOrdinateSystem.getExtent());
  setPreserveAspectRatio(coOrdinateSystem.getPreserveAspectRatio());
  setHasPreserveAspectRatio(coOrdinateSystem.hasPreserveAspectRatio());
  setInitialScale(coOrdinateSystem.getInitialScale());
  setHasInitialScale(coOrdinateSystem.hasInitialScale());
  setGrid(coOrdinateSystem.getGrid());
  setHasGrid(coOrdinateSystem.hasGrid());
}

void CoOrdinateSystem::setExtent(const QVector<QPointF> extent)
{
  mExtent = extent;
  setHasExtent(true);
}

void CoOrdinateSystem::setPreserveAspectRatio(const bool preserveAspectRatio)
{
  mPreserveAspectRatio = preserveAspectRatio;
  setHasPreserveAspectRatio(true);
}

void CoOrdinateSystem::setInitialScale(const qreal initialScale)
{
  mInitialScale = initialScale;
  setHasInitialScale(true);
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

void CoOrdinateSystem::setGrid(const QPointF grid)
{
  mGrid = grid;
  setHasGrid(true);
}

QRectF CoOrdinateSystem::getExtentRectangle() const
{
  QPointF extent1 = mExtent.at(0);
  QPointF extent2 = mExtent.at(1);

  qreal left = qMin(extent1.x(), extent2.x());
  qreal bottom = qMin(extent1.y(), extent2.y());
  qreal right = qMax(extent1.x(), extent2.x());
  qreal top = qMax(extent1.y(), extent2.y());
  return QRectF(left, bottom, qFabs(left - right), qFabs(bottom - top));
}

void CoOrdinateSystem::reset()
{
  mExtent.clear();
  setHasExtent(false);
  mPreserveAspectRatio = true;
  setHasPreserveAspectRatio(false);
  mInitialScale = 0.1;
  setHasInitialScale(false);
  mGrid = QPointF(2, 2);
  setHasGrid(false);
}

bool CoOrdinateSystem::isComplete() const
{
  return mHasExtent && mHasPreserveAspectRatio && mHasInitialScale && mHasGrid;
}
