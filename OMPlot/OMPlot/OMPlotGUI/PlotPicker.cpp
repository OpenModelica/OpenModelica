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

#include "PlotPicker.h"
#include "qwt_symbol.h"

using namespace OMPlot;

/*!
 * \brief containsPoint
 * Checks if the point is contained inside the two points.
 * \param point - point to detect
 * \param point1 - start point
 * \param point2 - end point
 * \param xSelectionMargin - x margin for selecting the line by clicking on it
 * \param ySelectionMargin - y margin for selecting the line by clicking on it
 * \return
 */
bool containsPoint(QPointF point, QPointF point1, QPointF point2, double xSelectionMargin, double ySelectionMargin)
{
  QPointF leftPoint;
  QPointF rightPoint;
  // Normalize start/end to left right to make the offset calc simpler.
  if (point1.x() <= point2.x()) {
    leftPoint = point1;
    rightPoint = point2;
  } else {
    leftPoint = point2;
    rightPoint = point1;
  }
  // If point is out of bounds, no need to do further checks.
  if (point.x() + xSelectionMargin < leftPoint.x() || rightPoint.x() < point.x() - xSelectionMargin) {
    return false;
  } else if (point.y() + ySelectionMargin < qMin(leftPoint.y(), rightPoint.y()) || qMin(leftPoint.y(), rightPoint.y()) < point.y() - ySelectionMargin) {
    return false;
  }
  double deltaX = rightPoint.x() - leftPoint.x();
  double deltaY = rightPoint.y() - leftPoint.y();
  // If the line is straight, the earlier boundary check is enough to determine that the point is on the line.
  // Also prevents division by zero exceptions.
  if (deltaX == 0 || deltaY == 0) {
    return true;
  }
  double slope = deltaY / deltaX;
  double offset = leftPoint.y() - leftPoint.x() * slope;
  double calculatedY = point.x() * slope + offset;
  // Check calculated Y matches the points Y coord with some easing.
  bool lineContains = point.y() - ySelectionMargin <= calculatedY && calculatedY <= point.y() + ySelectionMargin;
  return lineContains;
}

/*!
 * \brief PlotPicker::PlotPicker
 * \param pCanvas
 * \param pPlot
 */
PlotPicker::PlotPicker(QWidget *pCanvas, Plot *pPlot)
  : QwtPlotPicker(pCanvas)
{
  mpPlot = pPlot;
  mpPointMarker = new QwtPlotMarker();
  mpPointMarker->attach(mpPlot);
  mpPointMarker->setVisible(false);
  mpPointMarker->setSymbol(new QwtSymbol(QwtSymbol::Rect, QColor(Qt::red), QColor(Qt::red), QSize(6, 6)));
}

/*!
 * \brief PlotPicker::curveAtPosition
 * Checks the curve at the mouse position.
 * Finds the closest point on the curve and then checks if this point is close enough to our mouse position.
 * \param pos
 * \param pPlotCurve
 * \param index
 * \return
 */
bool PlotPicker::curveAtPosition(const QPoint pos, PlotCurve *&pPlotCurve, int &index) const
{
  QPointF posF = invTransform(pos);
  const QwtPlotItemList plotCurves = plot()->itemList(QwtPlotItem::Rtti_PlotCurve);
  for (int i = 0 ; i < plotCurves.size() ; i++) {
    pPlotCurve = static_cast<PlotCurve*>(plotCurves[i]);
    if (pPlotCurve->isVisible()) {
      // find the closest point
      index = pPlotCurve->closestPoint(pos);
      if (index > -1) {
        int index1, previousIndex, nextIndex;
        if (index == 0) {
          index1 = 1;
        } else if (index == pPlotCurve->mXAxisVector.size()) {
          index1 = index - 1;
        } else {
          previousIndex = index - 1;
          nextIndex = index + 1;
          QPointF previousCurvePoint(pPlotCurve->mXAxisVector.at(previousIndex), pPlotCurve->mYAxisVector.at(previousIndex));
          QPointF nextCurvePoint(pPlotCurve->mXAxisVector.at(nextIndex), pPlotCurve->mYAxisVector.at(nextIndex));
          // find which point is closest to mouse point.
          qreal pseudoDistance1 = qPow(posF.x() - previousCurvePoint.x(), 2) + qPow(posF.y() - previousCurvePoint.y(), 2);
          qreal pseudoDistance2 = qPow(posF.x() - nextCurvePoint.x(), 2) + qPow(posF.y() - nextCurvePoint.y(), 2);
          if (pseudoDistance1 < pseudoDistance2) {
            index1 = previousIndex;
          } else {
            index1 = nextIndex;
          }
        }
        QList<double> xMajorTicks = mpPlot->getPlotGrid()->xScaleDiv().ticks(QwtScaleDiv::MajorTick);
        QList<double> yMajorTicks = mpPlot->getPlotGrid()->yScaleDiv().ticks(QwtScaleDiv::MajorTick);
        if (xMajorTicks.size() > 1 && yMajorTicks.size() > 1) {
          double x = (xMajorTicks[1] - xMajorTicks[0]) / mpPlot->axisMaxMinor(QwtPlot::xBottom);
          double y = (yMajorTicks[1] - yMajorTicks[0]) / mpPlot->axisMaxMinor(QwtPlot::yLeft);
          QPointF curvePointA(pPlotCurve->mXAxisVector.at(index), pPlotCurve->mYAxisVector.at(index));
          QPointF curvePointB(pPlotCurve->mXAxisVector.at(index1), pPlotCurve->mYAxisVector.at(index1));
          if (containsPoint(posF, curvePointA, curvePointB, x, y)) {
            return true;
          }
        }
      }
    }
  }
  return false;
}

/*!
 * \brief PlotPicker::trackerText
 * Reimplentation of QwtPlotPicker::trackerText()
 * Only shows the tooltip when we have a curve at mouse position.
 * \param pos
 * \return
 */
QwtText PlotPicker::trackerText(const QPoint &pos) const
{
  int index = -1;
  PlotCurve *pPlotCurve = 0;
  if (curveAtPosition(pos, pPlotCurve, index)) {
    mpPointMarker->setValue(pPlotCurve->mXAxisVector.at(index), pPlotCurve->mYAxisVector.at(index));
    mpPointMarker->setVisible(true);
    QString timeUnit = "";
    if (!mpPlot->getParentPlotWindow()->getTimeUnit().isEmpty()) {
      timeUnit = QString("%1").arg(mpPlot->getParentPlotWindow()->getTimeUnit());
    }
    QString toolTip = QString("Name: <b>%1</b> %2<br />Value: <b>%3</b> at <b>%4</b> %5<br />Filename: <b>%6</b>")
        .arg(pPlotCurve->getName()).arg(pPlotCurve->getDisplayUnit())
        .arg(pPlotCurve->mYAxisVector.at(index))
        .arg(pPlotCurve->mXAxisVector.at(index))
        .arg(timeUnit)
        .arg(pPlotCurve->getFileName());
    QToolTip::showText(canvas()->mapToGlobal(pos), toolTip, nullptr);
  } else {
    mpPointMarker->setVisible(false);
    QToolTip::hideText();
  }
  return QString("");
}
