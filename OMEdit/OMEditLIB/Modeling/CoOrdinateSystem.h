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

#ifndef COORDINATESYSTEM_H
#define COORDINATESYSTEM_H

#include <QString>
#include <QRectF>

#include "Annotations/ExtentAnnotation.h"
#include "Annotations/BooleanAnnotation.h"
#include "Annotations/RealAnnotation.h"
#include "Annotations/PointAnnotation.h"

class CoOrdinateSystem
{
public:
  CoOrdinateSystem();
  CoOrdinateSystem(const CoOrdinateSystem &coOrdinateSystem);
  void setExtent(const QVector<QPointF> extent);
  ExtentAnnotation getExtent() const {return mExtent;}
  bool hasExtent() const {return mHasExtent;}
  void setHasExtent(const bool hasExtent) {mHasExtent = hasExtent;}
  void setPreserveAspectRatio(const bool preserveAspectRatio);
  BooleanAnnotation getPreserveAspectRatio() const {return mPreserveAspectRatio;}
  bool hasPreserveAspectRatio() const {return mHasPreserveAspectRatio;}
  void setHasPreserveAspectRatio(const bool hasPreserveAspectRatio) {mHasPreserveAspectRatio = hasPreserveAspectRatio;}
  void setInitialScale(const qreal initialScale);
  RealAnnotation getInitialScale() const {return mInitialScale;}
  bool hasInitialScale() const {return mHasInitialScale;}
  void setHasInitialScale(const bool hasInitialScale) {mHasInitialScale = hasInitialScale;}
  qreal getHorizontalGridStep();
  qreal getVerticalGridStep();
  void setGrid(const QPointF grid);
  PointAnnotation getGrid() const {return mGrid;}
  void setHasGrid(const bool hasGrid) {mHasGrid = hasGrid;}
  bool hasGrid() const {return mHasGrid;}

  QRectF getExtentRectangle() const;
  void reset();
  bool isComplete() const;

  CoOrdinateSystem& operator=(const CoOrdinateSystem &coOrdinateSystem) = default;
private:
  ExtentAnnotation mExtent;
  bool mHasExtent;
  BooleanAnnotation mPreserveAspectRatio;
  bool mHasPreserveAspectRatio;
  RealAnnotation mInitialScale;
  bool mHasInitialScale;
  PointAnnotation mGrid;
  bool mHasGrid;
};

#endif // COORDINATESYSTEM_H
