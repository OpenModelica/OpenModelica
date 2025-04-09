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

#ifndef PLOTCURVE_H
#define PLOTCURVE_H

#include "PlotWindow.h"

#include "qwt_plot_directpainter.h"
#include "qwt_plot_marker.h"

namespace OMPlot
{
class PlotCurve : public QwtPlotCurve
{
private:
  QString mNameStructure;
  QString mFileName;
  QString mAbsoluteFilePath;
  QString mXVariable;
  QString mYVariable;
  bool mCustomColor;
  QString mXUnit;
  QString mXDisplayUnit;
  QString mXUnitPrefix;
  int mXExponent = 0;
  QString mYUnit;
  QString mYDisplayUnit;
  QString mYUnitPrefix;
  int mYExponent = 0;
  qreal mWidth;
  int mStyle;
  bool mToggleSign;
  QString mCustomTitle;

  Plot *mpParentPlot;
  QwtPlotDirectPainter *mpPlotDirectPainter;
  QwtPlotMarker *mpPointMarker;
public:
  PlotCurve(const QString &fileName, const QString &absoluteFilePath, const QString &xVariableName, const QString &xUnit, const QString &xDisplayUnit,
            const QString &yVariableName, const QString &yUnit, const QString &yDisplayUnit, Plot *pParent);

  QwtArray<double> mXAxisVector;
  QwtArray<double> mYAxisVector;

  void setTitleLocal();
  Qt::PenStyle getPenStyle(int style) const;
  QwtPlotCurve::CurveStyle getCurveStyle(int style) const;
  void setXUnit(QString xUnit) {mXUnit = xUnit;}
  QString getXUnit() const {return mXUnit;}
  void setXDisplayUnit(QString xDisplayUnit) {mXDisplayUnit = xDisplayUnit;}
  QString getXDisplayUnit() const {return mXDisplayUnit;}
  QString getXUnitPrefix() const {return mXUnitPrefix;}
  void setYUnit(QString yUnit) {mYUnit = yUnit;}
  QString getYUnit() const {return mYUnit;}
  void setYDisplayUnit(QString yDisplayUnit) {mYDisplayUnit = yDisplayUnit;}
  QString getYDisplayUnit() const {return mYDisplayUnit;}
  QString getYUnitPrefix() const {return mYUnitPrefix;}
  void setCurveWidth(qreal width);
  qreal getCurveWidth() {return mWidth;}
  void setCurveStyle(int style);
  int getCurveStyle() {return mStyle;}
  bool getToggleSign() const {return mToggleSign;}
  void setToggleSign(bool toggleSign) {mToggleSign = toggleSign;}
  QString getCustomTitle() const {return mCustomTitle;}
  void setCustomTitle(const QString &customTitle) {mCustomTitle = customTitle;}
  void addXAxisValue(double value);
  void updateXAxisValue(int index, double value);
  QPair<QVector<double>*, QVector<double>*> getAxisVectors();
  void clearXAxisVector() {mXAxisVector.clear();}
  void addYAxisValue(double value);
  void updateYAxisValue(int index, double value);
  void clearYAxisVector() {mYAxisVector.clear();}
  int getXAxisSize() const;
  int getYAxisSize() const;
  void setFileName(QString fileName);
  QString getFileName() const;
  QString getAbsoluteFilePath() const;
  void setNameStructure(QString variableName);
  QString getNameStructure() {return mNameStructure;}
  void setXVariable(QString xVariable);
  QString getXVariable();
  void setYVariable(QString yVariable);
  QString getYVariable();
  void setCustomColor(bool value);
  bool hasCustomColor();
  void toggleVisibility(bool visibility);
  void resetPrefixUnit(bool resetValues);
  void plotData(bool toggleSign = false);
  QwtPlotDirectPainter* getPlotDirectPainter() {return mpPlotDirectPainter;}
  QwtPlotMarker* getPointMarker() const {return mpPointMarker;}
#if QWT_VERSION < 0x060000
  virtual void updateLegend(QwtLegend *legend) const;
#endif
  virtual int closestPoint(const QPointF &pos, double *dist = NULL) const override;

  // QwtPlotItem interface
public:
  virtual QRectF boundingRect() const override;
};
}

#endif // PLOTCURVE_H
