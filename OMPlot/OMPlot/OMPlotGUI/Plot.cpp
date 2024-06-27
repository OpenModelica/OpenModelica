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

#include "PlotWindow.h"
#include "LinearScaleEngine.h"

#include "qwt_plot_canvas.h"
#include "qwt_plot_layout.h"
#include "qwt_scale_widget.h"
#if QWT_VERSION < 0x060000
#include "qwt_legend_item.h"
#endif
#include "qwt_text_label.h"

#include <QtMath>

namespace OMPlot{

Plot::Plot(PlotWindow *pParent)
  : QwtPlot(pParent)
{
  setAutoReplot(false);
  mpParentPlotWindow = pParent;
  // create an instance of legend
  mpLegend = new Legend(this);
  insertLegend(mpLegend, QwtPlot::TopLegend);
  // create an instance of grid
  mpPlotGrid = new PlotGrid(this);
  // create the scale engine
  LinearScaleEngine *pXLinearScaleEngine = new LinearScaleEngine;
  setAxisScaleEngine(QwtPlot::xBottom, pXLinearScaleEngine);
  setAxisAutoScale(QwtPlot::xBottom);
  LinearScaleEngine *pYLinearScaleEngine = new LinearScaleEngine;
  setAxisScaleEngine(QwtPlot::yLeft, pYLinearScaleEngine);
  setAxisAutoScale(QwtPlot::yLeft);
  // create the scale draw
  mpXScaleDraw = new ScaleDraw(true, this);
  setAxisScaleDraw(QwtPlot::xBottom, mpXScaleDraw);
  mpYScaleDraw = new ScaleDraw(false, this);
  setAxisScaleDraw(QwtPlot::yLeft, mpYScaleDraw);
  // create an instance of zoomer
  mpPlotZoomer = new PlotZoomer(QwtPlot::xBottom, QwtPlot::yLeft, canvas());
  // create an instance of panner
  mpPlotPanner = new PlotPanner(canvas(), this);
  // create an instance of picker
  mpPlotPicker = new PlotPicker(canvas(), this);
  mpPlotPicker->setTrackerPen(QPen(Qt::black));
  mpPlotPicker->setTrackerMode(QwtPicker::AlwaysOn);
  // set canvas arrow
  QwtPlotCanvas *pPlotCanvas = static_cast<QwtPlotCanvas*>(canvas());
  pPlotCanvas->setFrameStyle(QFrame::NoFrame);  /* Ticket #2679 point 6. Remove the default frame from the canvas. */
  setCanvasBackground(Qt::white);
  setContentsMargins(10, 10, 10, 10);
#if QWT_VERSION >= 0x060000
  /* Ticket #2679 point 2. */
  for (int i = 0; i < QwtPlot::axisCnt; i++) {
    QwtScaleWidget *pScaleWidget = axisWidget(i);
    if (pScaleWidget) {
      pScaleWidget->setMargin(0);
    }
  }
  plotLayout()->setAlignCanvasToScales(true);
#endif
  // Use monospaced font for better readability.
  QFont monospaceFont("Monospace");
  monospaceFont.setStyleHint(QFont::TypeWriter);
  // set the bottom axis title font size small.
  QwtText bottomTitle = axisTitle(QwtPlot::xBottom);
  bottomTitle.setFont(QFont(monospaceFont.family(), 11));
  setAxisTitle(QwtPlot::xBottom, bottomTitle);
  // set the left axis title font size small.
  QwtText leftTitle = axisTitle(QwtPlot::yLeft);
  leftTitle.setFont(QFont(monospaceFont.family(), 11));
  setAxisTitle(QwtPlot::yLeft, leftTitle);
  // fill colors list
  fillColorsList();
  setAutoReplot(true);
}

Plot::~Plot()
{

}

void Plot::fillColorsList()
{
  mColorsList.append(QColor(Qt::red));
  mColorsList.append(QColor(Qt::blue));
  mColorsList.append(QColor(85,170,0));     // Ticket #3098
  mColorsList.append(QColor(170,85,255));   // Ticket #3098
  mColorsList.append(QColor(Qt::magenta));
  mColorsList.append(QColor(255, 110, 25));  // Ticket #6399
  mColorsList.append(QColor(Qt::darkRed));
  mColorsList.append(QColor(Qt::darkBlue));
  mColorsList.append(QColor(Qt::darkGreen));
  mColorsList.append(QColor(Qt::darkCyan));
  mColorsList.append(QColor(Qt::darkMagenta));
  mColorsList.append(QColor(Qt::darkYellow));
}

PlotWindow* Plot::getParentPlotWindow()
{
  return mpParentPlotWindow;
}

void Plot::setLegend(Legend *pLegend)
{
  mpLegend = pLegend;
}

Legend* Plot::getLegend()
{
  return mpLegend;
}

PlotPicker* Plot::getPlotPicker()
{
  return mpPlotPicker;
}

PlotGrid* Plot::getPlotGrid()
{
  return mpPlotGrid;
}

PlotZoomer* Plot::getPlotZoomer()
{
  return mpPlotZoomer;
}

PlotPanner* Plot::getPlotPanner()
{
  return mpPlotPanner;
}

QList<PlotCurve*> Plot::getPlotCurvesList()
{
  return mPlotCurvesList;
}

PlotCurve* Plot::getPlotCurve(QString nameStructure)
{
  foreach (PlotCurve *pPlotCurve, mPlotCurvesList)
  {
    if (pPlotCurve->getNameStructure().compare(nameStructure) == 0)
      return pPlotCurve;
  }
  return 0;
}

void Plot::addPlotCurve(PlotCurve *pCurve)
{
  mPlotCurvesList.append(pCurve);
}

void Plot::removeCurve(PlotCurve *pCurve)
{
  mPlotCurvesList.removeOne(pCurve);
  pCurve->getPointMarker()->setVisible(false);
}

QColor Plot::getUniqueColor(int index, int total)
{
  if (mColorsList.size() < total)
    return QColor::fromHsvF(index/(total + 1.0), 1, 1);
  else
    return mColorsList.at(index);
}

void Plot::setFontSizes(double titleFontSize, double verticalAxisTitleFontSize, double verticalAxisNumbersFontSize, double horizontalAxisTitleFontSize,
                        double horizontalAxisNumbersFontSize, double footerFontSize, double legendFontSize)
{
  // title
  QFont font = titleLabel()->font();
  font.setPointSizeF(titleFontSize);
  titleLabel()->setFont(font);
  // vertical axis title
  QwtText verticalTitle = axisWidget(QwtPlot::yLeft)->title();
  font = verticalTitle.font();
  font.setPointSizeF(verticalAxisTitleFontSize);
  verticalTitle.setFont(font);
  axisWidget(QwtPlot::yLeft)->setTitle(verticalTitle);
  // vertical axis numbers
  font = axisWidget(QwtPlot::yLeft)->font();
  font.setPointSizeF(verticalAxisNumbersFontSize);
  axisWidget(QwtPlot::yLeft)->setFont(font);
  // horizontal axis title
  QwtText horizontalTitle = axisWidget(QwtPlot::xBottom)->title();
  font = horizontalTitle.font();
  font.setPointSizeF(horizontalAxisTitleFontSize);
  horizontalTitle.setFont(font);
  axisWidget(QwtPlot::xBottom)->setTitle(horizontalTitle);
  // horizontal axis numbers
  font = axisWidget(QwtPlot::xBottom)->font();
  font.setPointSizeF(horizontalAxisNumbersFontSize);
  axisWidget(QwtPlot::xBottom)->setFont(font);
  // footer
  font = footerLabel()->font();
  font.setPointSizeF(footerFontSize);
  footerLabel()->setFont(font);
  // legend
  font = mpParentPlotWindow->getLegendFont();
  font.setPointSizeF(legendFontSize);
  mpParentPlotWindow->setLegendFont(font);
}

/*!
 * \brief Plot::prefixableUnit
 * Returns true if the unit is prefixable.
 * \param unit
 * \return
 */
bool Plot::prefixableUnit(const QString &unit)
{
  QStringList prefixableUnits;
  prefixableUnits << "s"
                  << "m"
                  << "m/s"
                  << "m/s2"
                  << "rad"
                  << "rad/s"
                  << "rad/s2"
                  << "rpm"
                  << "Hz"
                  << "N"
                  << "N.m"
                  << "Pa"
                  << "Pa.s"
                  << "J"
                  << "J/kg"
                  << "J/(kg.K)"
                  << "K"
                  << "V"
                  << "V/m"
                  << "A"
                  << "C"
                  << "F"
                  << "T"
                  << "Wb"
                  << "Wb/m"
                  << "H"
                  << "Ohm"
                  << "S"
                  << "W"
                  << "W/m"
                  << "W/m2"
                  << "Wh"
                  << "var";

  return prefixableUnits.contains(unit);
}

/*!
 * \brief Plot::getUnitPrefixAndExponent
 * \param lowerBound
 * \param upperBound
 * \param unitPrefix
 * \param exponent
 */
void Plot::getUnitPrefixAndExponent(double lowerBound, double upperBound, QString &unitPrefix, int &exponent)
{
  /* Since log(1900) returns 3.278 so we need to round down for positive values to make it 3
   * And log(0.0011) return -2.95 so we also need to round down for negative value to make it -3
   * log(0) is undefined so avoid it
   */

  if (!(qFuzzyCompare(lowerBound, 0.0) && qFuzzyCompare(upperBound, 0.0))) {
    if (fabs(lowerBound) > fabs(upperBound)) {
      exponent = qFloor(std::log10(fabs(lowerBound)));
    } else {
      exponent = qFloor(std::log10(fabs(upperBound)));
    }

    // We don't do anything for exponent values between -1 and 2.
    if ((exponent < -1) || (exponent > 2)) {
      if (exponent > 2) {
        if (exponent >= 3 && exponent < 6) {
          unitPrefix = "k";
          exponent = 3;
        } else if (exponent >= 6 && exponent < 9) {
          unitPrefix = "M";
          exponent = 6;
        } else if (exponent >= 9 && exponent < 12) {
          unitPrefix = "G";
          exponent = 9;
        } else if (exponent >= 12 && exponent < 15) {
          unitPrefix = "T";
          exponent = 12;
        } else {
          unitPrefix = "P";
          exponent = 15;
        }
      } else if (exponent < -1) {
        if (exponent <= -2 && exponent > -6) {
          unitPrefix = "m";
          exponent = -3;
        } else if (exponent <= -6 && exponent > -9) {
          unitPrefix = QChar(0x03BC);
          exponent = -6;
        } else if (exponent <= -9 && exponent > -12) {
          unitPrefix = "n";
          exponent = -9;
        } else if (exponent <= -12 && exponent > -15) {
          unitPrefix = "p";
          exponent = -12;
        } else {
          unitPrefix = "f";
          exponent = -15;
        }
      }
    } else {
      unitPrefix = "";
      exponent = 0;
    }
  }
}

// just overloaded this function to get colors for curves.
void Plot::replot()
{
  mpXScaleDraw->invalidateCache();
  mpYScaleDraw->invalidateCache();
  QwtPlot::replot();

  // Now we need to again loop through curves to set the color and title.
  for (int i = 0 ; i < mPlotCurvesList.length() ; i++) {
    // if user has set the custom color for the curve then dont get automatic color for it
    if (!mPlotCurvesList[i]->hasCustomColor()) {
      QPen pen = mPlotCurvesList[i]->pen();
      pen.setColor(getUniqueColor(i, mPlotCurvesList.length()));
      mPlotCurvesList[i]->setPen(pen);
    }
    mPlotCurvesList[i]->setTitleLocal();
  }

  if (mpParentPlotWindow->getXCustomLabel().isEmpty()) {
    // ScaleDraw::getUnitPrefix is only set when time is on x-axis
    const QString timeUnit = mpXScaleDraw->getUnitPrefix() + mpParentPlotWindow->getTimeUnit();
    if (mpParentPlotWindow->isPlot()
        || mpParentPlotWindow->isPlotAll()
        || mpParentPlotWindow->isPlotInteractive()) {
      setAxisTitle(QwtPlot::xBottom, QString("%1 (%2)").arg(mpParentPlotWindow->getXLabel(), timeUnit));
    } else if (mpParentPlotWindow->isPlotArray()) {
      setAxisTitle(QwtPlot::xBottom, mpParentPlotWindow->getXLabel());
    } else {
      setAxisTitle(QwtPlot::xBottom, "");
    }
  } else {
    setAxisTitle(QwtPlot::xBottom, mpParentPlotWindow->getXCustomLabel());
  }

  if (mpParentPlotWindow->getYCustomLabel().isEmpty()) {
    setAxisTitle(QwtPlot::yLeft, "");
  } else {
    setAxisTitle(QwtPlot::yLeft, mpParentPlotWindow->getYCustomLabel());
  }
}

} // namespace OMPlot
