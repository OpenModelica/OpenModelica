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
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "PlotPicker.h"
#include "OMPlot.h"
#include "PlotCurve.h"
#include "PlotGrid.h"
#include "ScaleDraw.h"

#include "qwt_text.h"

#include <QToolTip>
#include <QtMath>

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
  } else if (point.y() + ySelectionMargin < qMin(leftPoint.y(), rightPoint.y()) || qMax(leftPoint.y(), rightPoint.y()) < point.y() - ySelectionMargin) {
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
}

/*!
 * \brief PlotPicker::curvesAtPosition
 * Checks the curves at the mouse position.
 * Finds the closest point on the curves and then checks if this point is close enough to our mouse position.
 * \param pos
 * \param indexes
 * \return
 */
QList<PlotCurve*> PlotPicker::curvesAtPosition(const QPoint pos, QList<int> *indexes) const
{
  QPointF posF = invTransform(pos);
  int index = -1;
  QList<PlotCurve*> plotCurvesList;
  PlotCurve *pPlotCurve = 0;
  const QwtPlotItemList plotCurves = plot()->itemList(QwtPlotItem::Rtti_PlotCurve);
  for (int i = 0 ; i < plotCurves.size() ; i++) {
    pPlotCurve = static_cast<PlotCurve*>(plotCurves[i]);
    pPlotCurve->getPointMarker()->setVisible(false);
    if (pPlotCurve->isVisible()) {
      // find the closest point
      index = pPlotCurve->closestPoint(pos);
      if (index > -1) {
        int index1, previousIndex, nextIndex;
        if (index == 0) {
          index1 = 1;
        } else if (index == pPlotCurve->mXAxisVector.size() - 1 || index == pPlotCurve->mYAxisVector.size() - 1) {
          index1 = index - 1;
        } else {
          previousIndex = index - 1;
          nextIndex = index + 1;
          if (pPlotCurve->mXAxisVector.size() <= previousIndex || pPlotCurve->mYAxisVector.size() <= previousIndex
              || pPlotCurve->mXAxisVector.size() <= nextIndex || pPlotCurve->mYAxisVector.size() <= nextIndex) {
            continue;
          }
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
          if (pPlotCurve->mXAxisVector.size() <= index || pPlotCurve->mYAxisVector.size() <= index
              || pPlotCurve->mXAxisVector.size() <= index1 || pPlotCurve->mYAxisVector.size() <= index1) {
            continue;
          }
          QPointF curvePointA(pPlotCurve->mXAxisVector.at(index), pPlotCurve->mYAxisVector.at(index));
          QPointF curvePointB(pPlotCurve->mXAxisVector.at(index1), pPlotCurve->mYAxisVector.at(index1));
          if (containsPoint(posF, curvePointA, curvePointB, x, y)) {
            plotCurvesList.append(pPlotCurve);
            indexes->append(index);
          }
        }
      }
    }
  }
  return plotCurvesList;
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
  QList<int> indexes;
  QList<PlotCurve*> plotCurves = curvesAtPosition(pos, &indexes);
  if (!plotCurves.isEmpty()) {
    QString timeUnit = "";
    if (!mpPlot->getParentPlotWindow()->isPlotParametric()
        && !mpPlot->getParentPlotWindow()->isPlotArrayParametric()
        && !mpPlot->getParentPlotWindow()->getTimeUnit().isEmpty()) {
      timeUnit = QString("%1%2").arg(mpPlot->getXScaleDraw()->getUnitPrefix(), mpPlot->getParentPlotWindow()->getTimeUnit());
    }
    QString toolTip;
    for (int i = 0 ; i < plotCurves.size() ; i++) {
      PlotCurve *pPlotCurve = plotCurves.at(i);
      int index = indexes.at(i);

      double x = pPlotCurve->mXAxisVector.at(index);
      double y = pPlotCurve->mYAxisVector.at(index);

      pPlotCurve->getPointMarker()->setValue(x, y);
      pPlotCurve->getPointMarker()->setVisible(true);

      // ScaleDraw::getExponent is only useable when time is on x-axis
      if (!mpPlot->getParentPlotWindow()->isPlotParametric() && !mpPlot->getParentPlotWindow()->isPlotArrayParametric()) {
        x = x / qPow(10, mpPlot->getXScaleDraw()->getExponent());
      }

      if (i > 0) {
        toolTip += QString("<br /><br />");
      }
      toolTip += QString("Name: <b>%1</b><br />Value: <b>%2</b> at <b>%3</b> %4<br />Filename: <b>%5</b>")
                 .arg(pPlotCurve->title().text())
                 .arg(y)
                 .arg(x)
                 .arg(timeUnit)
                 .arg(pPlotCurve->getFileName());
    }
    QToolTip::showText(canvas()->mapToGlobal(pos), toolTip, nullptr);
  } else {
    QToolTip::hideText();
  }
  return QString("");
}
