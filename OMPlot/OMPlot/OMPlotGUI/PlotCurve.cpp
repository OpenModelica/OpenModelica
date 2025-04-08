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

#include "PlotCurve.h"
#if QWT_VERSION < 0x060000
#include "qwt_legend_item.h"
#else
#include "qwt_painter.h"
#endif
#include "qwt_symbol.h"
#include "qwt_scale_map.h"
#include "qwt_point_polar.h"

#include <QStringBuilder>

using namespace OMPlot;

PlotCurve::PlotCurve(const QString &fileName, const QString &absoluteFilePath, const QString &xVariableName, const QString &xUnit, const QString &xDisplayUnit,
                     const QString &yVariableName, const QString &yUnit, const QString &yDisplayUnit, Plot *pParent)
  : mCustomColor(false)
{
  mpParentPlot = pParent;
  mXVariable = xVariableName;
  mYVariable = yVariableName;
  mNameStructure = fileName + "." + yVariableName;
  mFileName = fileName;
  mAbsoluteFilePath = absoluteFilePath;
  mCustomColor = false;
  setXUnit(xUnit);
  setXDisplayUnit(xDisplayUnit);
  setYUnit(yUnit);
  setYDisplayUnit(yDisplayUnit);
  mCustomTitle = "";
  setToggleSign(false);
  setTitleLocal();
  /* set curve width and style */
  setCurveWidth(mpParentPlot->getParentPlotWindow()->getCurveWidth());
  setCurveStyle(mpParentPlot->getParentPlotWindow()->getCurveStyle());
#if QWT_VERSION > 0x060000
  setLegendAttribute(QwtPlotCurve::LegendShowLine);
  setLegendIconSize(QSize(30, 30));
#endif
  mpPlotDirectPainter = new QwtPlotDirectPainter();
  mpPointMarker = new QwtPlotMarker();
  mpPointMarker->attach(mpParentPlot);
  mpPointMarker->setVisible(false);
  mpPointMarker->setSymbol(new QwtSymbol(QwtSymbol::Rect, QColor(Qt::red), QColor(Qt::red), QSize(6, 6)));
}

void PlotCurve::setTitleLocal()
{
  if (mCustomTitle.isEmpty()) {
    QString titleStr = getYVariable();
    if (!getYDisplayUnit().isEmpty() || !getYUnitPrefix().isEmpty()) {
      titleStr += QString(" (%1)").arg(Plot::convertUnitToSymbol(getYUnitPrefix() % getYDisplayUnit()));
    }

    if (mpParentPlot->getParentPlotWindow()->isPlotParametric() || mpParentPlot->getParentPlotWindow()->isPlotArrayParametric()) {
      QString xVariable = getXVariable();
      if (!getXDisplayUnit().isEmpty() || !getXUnitPrefix().isEmpty()) {
        xVariable += QString(" (%1)").arg(Plot::convertUnitToSymbol(getXUnitPrefix() % getXDisplayUnit()));
      }
      if (!xVariable.isEmpty()) {
        titleStr += QString(" <b>vs</b> %1").arg(xVariable);
      }
    }
    // Add - sign if curve is toggled
    if (getToggleSign()) {
      titleStr.prepend(QString("-"));
    }
    setTitle(titleStr);
    // visibility
    QwtText text = title();
    if (isVisible()) {
      text.setColor(QColor(Qt::black));
    } else {
      text.setColor(QColor(Qt::gray));
    }
    setTitle(text);
  } else {
    setTitle(mCustomTitle);
  }
}

Qt::PenStyle PlotCurve::getPenStyle(int style) const
{
  switch (style)
  {
    case 2:
      return Qt::DashLine;
    case 3:
      return Qt::DotLine;
    case 4:
      return Qt::DashDotLine;
    case 5:
      return Qt::DashDotDotLine;
    default:
      return Qt::SolidLine;
  }
}

QwtPlotCurve::CurveStyle PlotCurve::getCurveStyle(int style) const
{
  switch (style)
  {
    case 6:
      return QwtPlotCurve::Sticks;
    case 7:
      return QwtPlotCurve::Steps;
    default:
      return QwtPlotCurve::Lines;
  }
}

void PlotCurve::setCurveWidth(qreal width)
{
  mWidth = width;
  QPen customPen = pen();
  customPen.setWidthF(mWidth);
  setPen(customPen);
}

void PlotCurve::setCurveStyle(int style)
{
  setStyle(QwtPlotCurve::Lines);
  mStyle = style;
  QPen customPen = pen();
  customPen.setStyle(getPenStyle(mStyle));
  setPen(customPen);
  if (mStyle > 5)
    setStyle(getCurveStyle(mStyle));
}

void PlotCurve::addXAxisValue(double value)
{
  mXAxisVector.push_back(value);
}

void PlotCurve::updateXAxisValue(int index, double value)
{
  mXAxisVector.replace(index, value);
}

QPair<QVector<double>*, QVector<double>*> PlotCurve::getAxisVectors()
{
  return qMakePair(&mXAxisVector, &mYAxisVector);
}

void PlotCurve::addYAxisValue(double value)
{
  mYAxisVector.push_back(value);
}

void PlotCurve::updateYAxisValue(int index, double value)
{
  mYAxisVector.replace(index, value);
}

int PlotCurve::getXAxisSize() const
{
  return mXAxisVector.size();
}

int PlotCurve::getYAxisSize() const
{
  return mYAxisVector.size();
}

void PlotCurve::setFileName(QString fileName)
{
  mFileName = fileName;
}

QString PlotCurve::getFileName() const
{
  return mFileName;
}

QString PlotCurve::getAbsoluteFilePath() const
{
  return mAbsoluteFilePath;
}

void PlotCurve::setNameStructure(QString variableName)
{
  mNameStructure = getFileName() + "." + variableName;
}

void PlotCurve::setXVariable(QString xVariable)
{
  mXVariable = xVariable;
}

QString PlotCurve::getXVariable()
{
  return mXVariable;
}

void PlotCurve::setYVariable(QString yVariable)
{
  mYVariable = yVariable;
}

QString PlotCurve::getYVariable()
{
  return mYVariable;
}

void PlotCurve::setCustomColor(bool value)
{
  mCustomColor = value;
}

bool PlotCurve::hasCustomColor()
{
  return mCustomColor;
}

/*!
 * \brief PlotCurve::toggleVisibility
 * Toggles the curve visibility.
 */
void PlotCurve::toggleVisibility(bool visibility)
{
  setVisible(visibility);
}

/*!
 * \brief PlotCurve::resetPrefixUnit
 * Resets the unit prefix and exponent.
 * \param resetValues - reset the values.
 */
void PlotCurve::resetPrefixUnit(bool resetValues)
{
  if (!mXUnitPrefix.isEmpty() && resetValues) {
    for (int i = 0 ; i < mXAxisVector.size() ; i++) {
      updateXAxisValue(i, mXAxisVector.at(i) * qPow(10, mXExponent));
    }
  }
  mXUnitPrefix = "";
  mXExponent = 0;

  if (!mYUnitPrefix.isEmpty() && resetValues) {
    for (int i = 0 ; i < mYAxisVector.size() ; i++) {
      updateYAxisValue(i, mYAxisVector.at(i) * qPow(10, mYExponent));
    }
  }
  mYUnitPrefix = "";
  mYExponent = 0;
}

/*!
 * \brief PlotCurve::plotData
 * Plot the curve data.
 * Finds the upper and lower bounds and add the prefix if auto prefix units is on.
 * \param toggleSign - Skips the prefixing of units. When toggle is on then we have already switched the values and just want to plot them as it is.
 */
void PlotCurve::plotData(bool toggleSign)
{
  if (!toggleSign) {
    if (mpParentPlot->getParentPlotWindow()->getPrefixUnits()) {
      bool canUseXPrefixUnits;
      if ((mpParentPlot->getParentPlotWindow()->isPlotParametric() || mpParentPlot->getParentPlotWindow()->isPlotArrayParametric())
          && Plot::prefixableUnit(getXDisplayUnit())) {
        canUseXPrefixUnits = true;
      } else {
        canUseXPrefixUnits = false;
      }

      bool canUseYPrefixUnits = Plot::prefixableUnit(getYDisplayUnit());

      double xLowerBound = 0.0;
      double xUpperBound = 0.0;
      double yLowerBound = 0.0;
      double yUpperBound = 0.0;

      for (int i = 0 ; i < getXAxisSize() ; i++) {
        xLowerBound = qMin(xLowerBound, mXAxisVector.at(i));
        xUpperBound = qMax(xUpperBound, mXAxisVector.at(i));
      }

      for (int i = 0 ; i < getYAxisSize() ; i++) {
        yLowerBound = qMin(yLowerBound, mYAxisVector.at(i));
        yUpperBound = qMax(yUpperBound, mYAxisVector.at(i));
      }

      if (canUseXPrefixUnits) {
        Plot::getUnitPrefixAndExponent(xLowerBound, xUpperBound, mXUnitPrefix, mXExponent);
        // update if unit prefix is not empty.
        if (!mXUnitPrefix.isEmpty()) {
          for (int i = 0 ; i < mXAxisVector.size() ; i++) {
            updateXAxisValue(i, mXAxisVector.at(i) / qPow(10, mXExponent));
          }
        }
      }

      if (canUseYPrefixUnits) {
        Plot::getUnitPrefixAndExponent(yLowerBound, yUpperBound, mYUnitPrefix, mYExponent);
        // update if unit prefix is not empty.
        if (!mYUnitPrefix.isEmpty()) {
          for (int i = 0 ; i < mYAxisVector.size() ; i++) {
            updateYAxisValue(i, mYAxisVector.at(i) / qPow(10, mYExponent));
          }
        }
      }
    } else {
      // revert the values when there is no perfixUnits.
      resetPrefixUnit(true);
    }
  }
  setSamples(mXAxisVector, mYAxisVector);
}

#if QWT_VERSION < 0x060000
void PlotCurve::updateLegend(QwtLegend *legend) const
{
  QwtPlotCurve::updateLegend(legend);
  QwtLegendItem *pQwtLegendItem = dynamic_cast<QwtLegendItem*>(legend->find(this));
  if (pQwtLegendItem)
  {
    pQwtLegendItem->setIdentifierMode(QwtLegendItem::ShowLine);
    pQwtLegendItem->setIdentifierWidth(30);
  }
  QwtPlotItem::updateLegend(legend);
}
#endif

/*!
 * \brief QwtPlotCurve::closestPoint
 * Reimplentation of QwtPlotCurve::closestPoint()
 * Just doesn't fail if first time f < dmin instead we use the first f value to initialize dmin.
 * \param pos
 * \param dist
 * \return
 */
int PlotCurve::closestPoint(const QPointF &pos, double *dist) const
{
  const size_t numSamples = dataSize();
  if (plot() == NULL || numSamples <= 0) {
    return -1;
  }
  const QwtSeriesData<QPointF> *series = data();

  const QwtScaleMap xMap = plot()->canvasMap(xAxis());
  const QwtScaleMap yMap = plot()->canvasMap(yAxis());

  int index = -1;
  double dmin = 1.0e10;

  for (uint i = 0; i < numSamples; i++) {
    const QPointF sample = series->sample( i );

    const double cx = xMap.transform(sample.x() ) - pos.x();
    const double cy = yMap.transform(sample.y() ) - pos.y();

    const double f = qwtSqr(cx) + qwtSqr(cy);
    if ((i == 0) || (f < dmin)) {
      index = i;
      dmin = f;
    }
  }
  if (dist) {
    *dist = qSqrt(dmin);
  }

  return index;
}

/*!
 * \brief PlotCurve::boundingRect
 * Reimplentation of QwtPlotCurve::boundingRect() to add a margin.
 * \return
 */
QRectF PlotCurve::boundingRect() const
{
  QRectF existingBoundingRect = QwtPlotCurve::boundingRect();
  if (existingBoundingRect.isValid()) {
    /* Ticket:5515 Allow for some margin at the top and bottom of plot windows in OMEdit
     * We add a margin of 10% to the curves bottom and top to better visualize them.
     */
    const double margin = existingBoundingRect.height() * 0.1;
    QRectF newBoundingRect = existingBoundingRect.adjusted(0, -margin, 0, margin);

    /* Issue:7468 Check for negative values doing log plot.
     * Do not add margin if the value becomes negative.
     */
    if ((mpParentPlot->getParentPlotWindow()->getLogXCheckBox()->isChecked() || mpParentPlot->getParentPlotWindow()->getLogYCheckBox()->isChecked())
        && (newBoundingRect.top() < 0.0 || newBoundingRect.bottom() < 0.0)) {
      return existingBoundingRect;
    } else {
      return newBoundingRect;
    }
  }
  return existingBoundingRect;
}
