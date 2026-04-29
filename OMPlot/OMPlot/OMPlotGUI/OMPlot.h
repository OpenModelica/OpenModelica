/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef OMPLOT_H
#define OMPLOT_H

#include "qwt_plot.h"

#include <QList>
#include <QColor>

namespace OMPlot
{
class PlotWindow;
class Legend;
class PlotGrid;
class PlotZoomer;
class PlotPanner;
class PlotPicker;
class ScaleDraw;
class PlotCurve;

class Plot : public QwtPlot
{
  Q_OBJECT
private:
  PlotWindow *mpParentPlotWindow;
  Legend *mpLegend;
  PlotGrid *mpPlotGrid;
  ScaleDraw *mpXScaleDraw;
  ScaleDraw *mpYScaleDraw;
  ScaleDraw* mpYRightScaleDraw;
  PlotZoomer *mpPlotZoomer;
  PlotPanner *mpPlotPanner;
  PlotPicker *mpPlotPicker;
  QList<PlotCurve*> mPlotCurvesList;
  QList<QColor> mColorsList;
public:
  Plot(PlotWindow *pParent);
  ~Plot();

  void fillColorsList();
  PlotWindow* getParentPlotWindow();
  void setLegend(Legend *pLegend);
  Legend* getLegend();
  PlotPicker *getPlotPicker();
  PlotGrid* getPlotGrid();
  ScaleDraw *getXScaleDraw() const {return mpXScaleDraw;}
  ScaleDraw *getYScaleDraw() const {return mpYScaleDraw;}
  ScaleDraw* getYRightScaleDraw() const {return mpYRightScaleDraw;}
  PlotZoomer* getPlotZoomer();
  PlotPanner* getPlotPanner();
  QList<PlotCurve*> getPlotCurvesList();
  PlotCurve* getPlotCurve(QString nameStructure);
  void addPlotCurve(PlotCurve *pCurve);
  void removeCurve(PlotCurve *pCurve);
  QColor getUniqueColor(int index, int total);
  void setFontSizes(double titleFontSize, double verticalAxisTitleFontSize, double verticalAxisNumbersFontSize,
      double rightVerticalAxisTitleFontSize, double rightVerticalAxisNumbersFontSize, double horizontalAxisTitleFontSize,
      double horizontalAxisNumbersFontSize, double footerFontSize, double legendFontSize);
  static bool prefixableUnit(const QString &unit);
  static QString convertUnitToSymbol(const QString &displayUnit);
  static QString convertSymbolToUnit(const QString &symbol);
  static void getUnitPrefixAndExponent(double lowerBound, double upperBound, QString &unitPrefix, int &exponent);
public slots:
  virtual void replot();
};
}

#endif // OMPLOT_H
