/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Author 2011: Adeel Asghar
 *
 */

#ifndef PLOTCURVE_H
#define PLOTCURVE_H

#include "OMPlot.h"

namespace OMPlot
{
class PlotCurve : public QwtPlotCurve
{
private:
  QString mName;
  QString mNameStructure;
  QString mFileName;
  QString mXVariable;
  QString mYVariable;
  bool mCustomColor;
  QString mUnit;
  QString mDisplayUnit;
  qreal mWidth;
  int mStyle;

  Plot *mpParentPlot;
public:
  PlotCurve(QString fileName, QString name, QString xVariableName, QString yVariableName, QString unit, QString displayUnit, Plot *pParent);
  ~PlotCurve();

  QwtArray<double> mXAxisVector;
  QwtArray<double> mYAxisVector;

  void setTitleLocal();
  Qt::PenStyle getPenStyle(int style);
  QwtPlotCurve::CurveStyle getCurveStyle(int style);
  void setUnit(QString unit) {mUnit = unit;}
  QString getUnit() {return mUnit;}
  void setDisplayUnit(QString displayUnit) {mDisplayUnit = displayUnit;}
  QString getDisplayUnit() {return mDisplayUnit;}
  void setCurveWidth(qreal width);
  qreal getCurveWidth() {return mWidth;}
  void setCurveStyle(int style);
  int getCurveStyle() {return mStyle;}
  void setXAxisVector(QVector<double> vector);
  void addXAxisValue(double value);
  void updateXAxisValue(int index, double value);
  const double* getXAxisVector() const;
  void clearXAxisVector() {mXAxisVector.clear();}
  void setYAxisVector(QVector<double> vector);
  void addYAxisValue(double value);
  void updateYAxisValue(int index, double value);
  const double* getYAxisVector() const;
  void clearYAxisVector() {mYAxisVector.clear();}
  int getSize();
  QString getName() {return mName;}
  void setFileName(QString fileName);
  QString getFileName();
  void setNameStructure(QString variableName);
  QString getNameStructure() {return mNameStructure;}
  void setXVariable(QString xVariable);
  QString getXVariable();
  void setYVariable(QString yVariable);
  QString getYVariable();
  void setCustomColor(bool value);
  bool hasCustomColor();
  void toggleVisibility();
  void setData(const double* xData, const double* yData, int size);
#if QWT_VERSION < 0x060000
  virtual void updateLegend(QwtLegend *legend) const;
#endif
  virtual int closestPoint(const QPoint &pos, double *dist = NULL) const;
};
}

#endif // PLOTCURVE_H
