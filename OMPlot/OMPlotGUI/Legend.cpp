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

#include "Legend.h"
#include "iostream"
#if QWT_VERSION < 0x060100
#include "qwt_legend_item.h"
#else
#include "qwt_legend_label.h"
#endif

using namespace OMPlot;

Legend::Legend(Plot *pParent)
{
  mpPlot = pParent;
  mpPlotCurve = 0;

  mpSetupAction = new QAction(tr("Setup"), this);
  connect(mpSetupAction, SIGNAL(triggered()), SLOT(showSetupDialog()));

  setContextMenuPolicy(Qt::CustomContextMenu);
  connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(legendMenu(QPoint)));
  /* Ticket #3984
   * In order to show tooltip for each legend item we need to install event filter for contentsWidget()
   * contentsWidget() contains a list of legend item
   * Since the tooltip is shown on mouse over so we need to enable mouse tracking for it.
   */
  contentsWidget()->installEventFilter(this);
  contentsWidget()->setMouseTracking(true);
}

/*!
 * \brief Legend::eventFilter
 * Handles the mousemove event for contentsWidget().
 * \param object
 * \param event
 * \return
 */
bool Legend::eventFilter(QObject *object, QEvent *event)
{
  QWidget *pContentsWidget = qobject_cast<QWidget*>(object);
  if (pContentsWidget == contentsWidget() && event->type() == QEvent::MouseMove) {
    QMouseEvent *pMouseEvent = static_cast<QMouseEvent*>(event);
    PlotCurve *pPlotCurve;
#if QWT_VERSION >= 0x060100
    QwtPlotItem *pQwtPlotItem = qvariant_cast<QwtPlotItem*>(itemInfo(childAt(pMouseEvent->pos())));
    pPlotCurve = dynamic_cast<PlotCurve*>(pQwtPlotItem);
#else
    pPlotCurve = dynamic_cast<PlotCurve*>(find(childAt(pMouseEvent->pos())));
#endif
    if (pPlotCurve) {
      QString toolTip = tr("Name: <b>%1</b><br />Filename: <b>%2</b>").arg(pPlotCurve->getName()).arg(pPlotCurve->getFileName());
      QToolTip::showText(pMouseEvent->globalPos(), toolTip, this);
    } else {
      QToolTip::hideText();
    }
  }
  return QwtLegend::eventFilter(object, event);
}

void Legend::showSetupDialog()
{
  if (mpPlotCurve) {
    mpPlot->getParentPlotWindow()->showSetupDialog(mpPlotCurve->getNameStructure());
    mpPlotCurve = 0;
  }
}

void Legend::legendMenu(const QPoint& pos)
{
#if QWT_VERSION >= 0x060100
  QwtPlotItem *pQwtPlotItem = qvariant_cast<QwtPlotItem*>(itemInfo(childAt(pos)));
  mpPlotCurve = dynamic_cast<PlotCurve*>(pQwtPlotItem);
#else
  mpPlotCurve = dynamic_cast<PlotCurve*>(find(childAt(pos)));
#endif
  if (mpPlotCurve) {
    /* context menu */
    QMenu menu(mpPlot);
    menu.addAction(mpSetupAction);
    menu.exec(mapToGlobal(pos));
  }
}

/*!
 * \brief Legend::createWidget
 * Reimplementation of QwtLegend::createWidget()
 * We need to setMouseTracking on each legend item so that we can show tooltip on hover.
 * \sa Legend::eventFilter
 * \param data
 * \return
 */
QWidget* Legend::createWidget(const QwtLegendData &data) const
{
  QWidget *pWidget = QwtLegend::createWidget(data);
  pWidget->setMouseTracking(true);
  return pWidget;
}

/*!
 * \brief Legend::mousePressEvent
 * Reimplementation of QWidget::mousePressEvent()
 * Show/hide the PlotCurve item clicked in the legend.
 * \param event
 */
void Legend::mousePressEvent(QMouseEvent *event)
{
  if (event->button() == Qt::RightButton) {
    QwtLegend::mousePressEvent(event);
    return;
  }
  QwtLegend::mousePressEvent(event);
#if QWT_VERSION >= 0x060100
  QwtPlotItem *pQwtPlotItem = qvariant_cast<QwtPlotItem*>(itemInfo(childAt(event->pos())));
  mpPlotCurve = dynamic_cast<PlotCurve*>(pQwtPlotItem);
#else
  mpPlotCurve = dynamic_cast<PlotCurve*>(find(childAt(event->pos())));
#endif
  if (mpPlotCurve) {
    mpPlotCurve->toggleVisibility();
  }

}

/*!
 * \brief Legend::mouseDoubleClickEvent
 * Reimplementation of QWidget::mouseDoubleClickEvent()
 * Show the PlotCurve item double clicked in the legend and hide all other.
 * \param event
 */
void Legend::mouseDoubleClickEvent(QMouseEvent *event)
{
  QwtLegend::mouseDoubleClickEvent(event);
#if QWT_VERSION >= 0x060100
  QwtPlotItem *pQwtPlotItem = qvariant_cast<QwtPlotItem*>(itemInfo(childAt(event->pos())));
  mpPlotCurve = dynamic_cast<PlotCurve*>(pQwtPlotItem);
#else
  mpPlotCurve = dynamic_cast<PlotCurve*>(find(childAt(event->pos())));
#endif
  if (mpPlotCurve) {
    foreach (PlotCurve *pPlotCurve, mpPlot->getPlotCurvesList()) {
      if (pPlotCurve == mpPlotCurve) {
        pPlotCurve->setVisible(false);
      } else {
        pPlotCurve->setVisible(true);
      }
      pPlotCurve->toggleVisibility();
    }
  }
}
