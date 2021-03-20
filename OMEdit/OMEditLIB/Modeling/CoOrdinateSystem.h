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

class CoOrdinateSystem
{
public:
  CoOrdinateSystem();
  CoOrdinateSystem(const CoOrdinateSystem &coOrdinateSystem);
  void setLeft(const qreal left);
  void setLeft(const QString &left);
  qreal getLeft() const {return mLeft;}
  bool hasLeft() const {return mHasLeft;}
  void setHasLeft(const bool hasLeft) {mHasLeft = hasLeft;}
  void setBottom(const qreal bottom);
  void setBottom(const QString &bottom);
  qreal getBottom() const {return mBottom;}
  bool hasBottom() const {return mHasBottom;}
  void setHasBottom(const bool hasBottom) {mHasBottom = hasBottom;}
  void setRight(const qreal right);
  void setRight(const QString &right);
  qreal getRight() const {return mRight;}
  bool hasRight() const {return mHasRight;}
  void setHasRight(const bool hasRight) {mHasRight = hasRight;}
  void setTop(const qreal top);
  void setTop(const QString &top);
  qreal getTop() const {return mTop;}
  bool hasTop() const {return mHasTop;}
  void setHasTop(const bool hasTop) {mHasTop = hasTop;}
  void setPreserveAspectRatio(const bool preserveAspectRatio);
  void setPreserveAspectRatio(const QString &preserveAspectRatio);
  bool getPreserveAspectRatio() const {return mPreserveAspectRatio;}
  bool hasPreserveAspectRatio() const {return mHasPreserveAspectRatio;}
  void setHasPreserveAspectRatio(const bool hasPreserveAspectRatio) {mHasPreserveAspectRatio = hasPreserveAspectRatio;}
  void setInitialScale(const qreal initialScale);
  void setInitialScale(const QString &initialScale);
  qreal getInitialScale() const {return mInitialScale;}
  bool hasInitialScale() const {return mHasInitialScale;}
  void setHasInitialScale(const bool hasInitialScale) {mHasInitialScale = hasInitialScale;}
  qreal getHorizontalGridStep();
  qreal getVerticalGridStep();
  void setHorizontal(const qreal horizontal);
  void setHorizontal(const QString &horizontal);
  qreal getHorizontal() const {return mHorizontal;}
  bool hasHorizontal() const {return mHasHorizontal;}
  void setHasHorizontal(const bool hasHorizontal) {mHasHorizontal = hasHorizontal;}
  void setVertical(const qreal vertical);
  void setVertical(const QString &vertical);
  qreal getVertical() const {return mVertical;}
  bool hasVertical() const {return mHasVertical;}
  void setHasVertical(const bool hasVertical) {mHasVertical = hasVertical;}

  QRectF getExtentRectangle() const;
  void reset();
  bool isComplete() const;

  CoOrdinateSystem& operator=(const CoOrdinateSystem &coOrdinateSystem) noexcept = default;
private:
  qreal mLeft;
  bool mHasLeft;
  qreal mBottom;
  bool mHasBottom;
  qreal mRight;
  bool mHasRight;
  qreal mTop;
  bool mHasTop;
  bool mPreserveAspectRatio;
  bool mHasPreserveAspectRatio;
  qreal mInitialScale;
  bool mHasInitialScale;
  qreal mHorizontal;
  bool mHasHorizontal;
  qreal mVertical;
  bool mHasVertical;
};

#endif // COORDINATESYSTEM_H
