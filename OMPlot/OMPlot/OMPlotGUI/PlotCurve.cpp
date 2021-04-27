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

#include "PlotCurve.h"
#if QWT_VERSION < 0x060000
#include "qwt_legend_item.h"
#else
#include "qwt_painter.h"
#endif
#include "qwt_symbol.h"

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
    if (!getYDisplayUnit().isEmpty() || !mpParentPlot->getYScaleDraw()->getUnitPrefix().isEmpty()) {
      titleStr += QString(" (%1%2)").arg(mpParentPlot->getYScaleDraw()->getUnitPrefix(), getYDisplayUnit());
    }

    if (mpParentPlot->getParentPlotWindow()->getPlotType() == PlotWindow::PLOTPARAMETRIC) {
      QString xVariable = getXVariable();
      if (!getXDisplayUnit().isEmpty() || !mpParentPlot->getXScaleDraw()->getUnitPrefix().isEmpty()) {
        xVariable += QString(" (%1%2)").arg(mpParentPlot->getXScaleDraw()->getUnitPrefix(), getXDisplayUnit());
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

Qt::PenStyle PlotCurve::getPenStyle(int style)
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

QwtPlotCurve::CurveStyle PlotCurve::getCurveStyle(int style)
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

void PlotCurve::setXAxisVector(QVector<double> vector)
{
  mXAxisVector = vector;
}

void PlotCurve::addXAxisValue(double value)
{
  mXAxisVector.push_back(value);
}

void PlotCurve::updateXAxisValue(int index, double value)
{
  mXAxisVector.replace(index, value);
}

const double* PlotCurve::getXAxisVector() const
{
  return mXAxisVector.data();
}

QPair<QVector<double>*, QVector<double>*> PlotCurve::getAxisVectors()
{
  return qMakePair(&mXAxisVector, &mYAxisVector);
}

void PlotCurve::setYAxisVector(QVector<double> vector)
{
  mYAxisVector = vector;
}

void PlotCurve::addYAxisValue(double value)
{
  mYAxisVector.push_back(value);
}

void PlotCurve::updateYAxisValue(int index, double value)
{
  mYAxisVector.replace(index, value);
}

const double* PlotCurve::getYAxisVector() const
{
  return mYAxisVector.data();
}

int PlotCurve::getSize()
{
  return mXAxisVector.size();
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

void PlotCurve::setData(const double* xData, const double* yData, int size)
{
#if QWT_VERSION >= 0x060000
  setRawSamples(xData, yData, size);
#else
  setRawData(xData, yData, size);
#endif
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
int PlotCurve::closestPoint(const QPoint &pos, double *dist) const
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
  QRectF r = QwtPlotCurve::boundingRect();
  if (r.isValid()) {
    /* Ticket:5515 Allow for some margin at the top and bottom of plot windows in OMEdit
     * We add a margin of 10% to the curves bottom and top to better visualize them.
     */
    const double margin = r.height() * 0.1;
    r.adjust(0, -margin, 0, margin);
  }
  return r;
}
