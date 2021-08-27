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
  setLeft(coOrdinateSystem.getLeft());
  setHasLeft(coOrdinateSystem.hasLeft());
  setBottom(coOrdinateSystem.getBottom());
  setHasBottom(coOrdinateSystem.hasBottom());
  setRight(coOrdinateSystem.getRight());
  setHasRight(coOrdinateSystem.hasRight());
  setTop(coOrdinateSystem.getTop());
  setHasTop(coOrdinateSystem.hasTop());
  setPreserveAspectRatio(coOrdinateSystem.getPreserveAspectRatio());
  setHasPreserveAspectRatio(coOrdinateSystem.hasPreserveAspectRatio());
  setInitialScale(coOrdinateSystem.getInitialScale());
  setHasInitialScale(coOrdinateSystem.hasInitialScale());
  setHorizontal(coOrdinateSystem.getHorizontal());
  setHasHorizontal(coOrdinateSystem.hasHorizontal());
  setVertical(coOrdinateSystem.getVertical());
  setHasVertical(coOrdinateSystem.hasVertical());
}

void CoOrdinateSystem::setLeft(const qreal left)
{
  mLeft = left;
  setHasLeft(true);
}

void CoOrdinateSystem::setLeft(const QString &left)
{
  bool ok;
  if (left.compare(QStringLiteral("0.0")) == 0) {
    setLeft(0.0);
  } else if (left.toDouble(&ok) && ok) {
    setLeft(left.toDouble());
  }
}

void CoOrdinateSystem::setBottom(const qreal bottom)
{
  mBottom = bottom;
  setHasBottom(true);
}

void CoOrdinateSystem::setBottom(const QString &bottom)
{
  bool ok;
  if (bottom.compare(QStringLiteral("0.0")) == 0) {
    setBottom(0.0);
  } else if (bottom.toDouble(&ok) && ok) {
    setBottom(bottom.toDouble());
  }
}

void CoOrdinateSystem::setRight(const qreal right)
{
  mRight = right;
  setHasRight(true);
}

void CoOrdinateSystem::setRight(const QString &right)
{
  bool ok;
  if (right.compare(QStringLiteral("0.0")) == 0) {
    setRight(0.0);
  } else if (right.toDouble(&ok) && ok) {
    setRight(right.toDouble());
  }
}

void CoOrdinateSystem::setTop(const qreal top)
{
  mTop = top;
  setHasTop(true);
}

void CoOrdinateSystem::setTop(const QString &top)
{
  bool ok;
  if (top.compare(QStringLiteral("0.0")) == 0) {
    setTop(0.0);
  } else if (top.toDouble(&ok) && ok) {
    setTop(top.toDouble());
  }
}

void CoOrdinateSystem::setPreserveAspectRatio(const bool preserveAspectRatio)
{
  mPreserveAspectRatio = preserveAspectRatio;
  setHasPreserveAspectRatio(true);
}

void CoOrdinateSystem::setPreserveAspectRatio(const QString &preserveAspectRatio)
{
  if (preserveAspectRatio.compare("true") == 0) {
    setPreserveAspectRatio(true);
  } else if (preserveAspectRatio.compare("false") == 0) {
    setPreserveAspectRatio(false);
  }
}

void CoOrdinateSystem::setInitialScale(const qreal initialScale)
{
  mInitialScale = initialScale;
  setHasInitialScale(true);
}

void CoOrdinateSystem::setInitialScale(const QString &initialScale)
{
  bool ok;
  if (initialScale.toDouble(&ok) && ok) {
    setInitialScale(initialScale.toDouble());
  }
}

/*!
 * \brief CoOrdinateSystem::getHorizontalGridStep
 * \return
 */
qreal CoOrdinateSystem::getHorizontalGridStep()
{
  if (mHorizontal < 1) {
    return 2;
  }
  return mHorizontal;
}

/*!
 * \brief CoOrdinateSystem::getVerticalGridStep
 * \return
 */
qreal CoOrdinateSystem::getVerticalGridStep()
{
  if (mVertical < 1) {
    return 2;
  }
  return mVertical;
}

void CoOrdinateSystem::setHorizontal(const qreal horizontal)
{
  mHorizontal = horizontal;
  setHasHorizontal(true);
}

void CoOrdinateSystem::setHorizontal(const QString &horizontal)
{
  bool ok;
  if (horizontal.toDouble(&ok) && ok) {
    setHorizontal(horizontal.toDouble());
  }
}

void CoOrdinateSystem::setVertical(qreal vertical)
{
  mVertical = vertical;
  setHasVertical(true);
}

void CoOrdinateSystem::setVertical(const QString &vertical)
{
  bool ok;
  if (vertical.toDouble(&ok) && ok) {
    setVertical(vertical.toDouble());
  }
}

QRectF CoOrdinateSystem::getExtentRectangle() const
{
  qreal left = qMin(getLeft(), getRight());
  qreal bottom = qMin(getBottom(), getTop());
  qreal right = qMax(getLeft(), getRight());
  qreal top = qMax(getBottom(), getTop());
  return QRectF(left, bottom, qFabs(left - right), qFabs(bottom - top));
}

void CoOrdinateSystem::reset()
{
  setLeft(-100);
  setHasLeft(false);
  setBottom(-100);
  setHasBottom(false);
  setRight(100);
  setHasRight(false);
  setTop(100);
  setHasTop(false);
  setPreserveAspectRatio(true);
  setHasPreserveAspectRatio(false);
  setInitialScale(0.1);
  setHasInitialScale(false);
  setHorizontal(2);
  setHasHorizontal(false);
  setVertical(2);
  setHasVertical(false);
}

bool CoOrdinateSystem::isComplete() const
{
  return mHasLeft && mHasBottom && mHasRight && mHasTop && mHasPreserveAspectRatio && mHasInitialScale && mHasHorizontal && mHasVertical;
}
