/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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
 *
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 *
 */

#include "PlotWindowContainer.h"
#include "VariablesWidget.h"

using namespace OMPlot;

PlotWindowContainer::PlotWindowContainer(MainWindow *pParent)
  : MdiArea(pParent)
{
  if (mpMainWindow->getOptionsDialog()->getPlottingPage()->getPlottingViewMode().compare(Helper::subWindow) == 0) {
    setViewMode(QMdiArea::SubWindowView);
  } else {
    setViewMode(QMdiArea::TabbedView);
  }
  // dont show this widget at startup
  setVisible(false);
}

QString PlotWindowContainer::getUniqueName(QString name, int number)
{
  QString newName;
  newName = name + QString::number(number);

  foreach (QMdiSubWindow *pWindow, subWindowList())
  {
    if (pWindow->widget()->windowTitle().compare(newName) == 0)
    {
      newName = getUniqueName(name, ++number);
      break;
    }
  }
  return newName;
}

PlotWindow* PlotWindowContainer::getCurrentWindow()
{
  if (subWindowList(QMdiArea::ActivationHistoryOrder).size() == 0)
    return 0;
  else
    return qobject_cast<PlotWindow*>(subWindowList(QMdiArea::ActivationHistoryOrder).last()->widget());
}

bool PlotWindowContainer::eventFilter(QObject *pObject, QEvent *pEvent)
{
  PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(pObject);
  if (pPlotWindow && pEvent->type() == QEvent::Paint) {
    QPainter painter (pPlotWindow);
    painter.setPen(Qt::gray);
    QRect rectangle = pPlotWindow->rect();
    rectangle.setWidth(pPlotWindow->rect().width() - 1);
    rectangle.setHeight(pPlotWindow->rect().height() - 1);
    painter.drawRect(rectangle);
    return true;
  }
  return QMdiArea::eventFilter(pObject, pEvent);
}

/*!
  Adds a new Plot Window.
  \param maximized - sets the window state maximized
  */
void PlotWindowContainer::addPlotWindow(bool maximized)
{
  try
  {
    PlotWindow *pPlotWindow = new PlotWindow(QStringList(), this);
    pPlotWindow->setPlotType(PlotWindow::PLOT);
    pPlotWindow->setWindowTitle(getUniqueName("Plot : "));
    pPlotWindow->setTitle("");
    pPlotWindow->setLegendPosition("top");
    pPlotWindow->setAutoScale(mpMainWindow->getOptionsDialog()->getPlottingPage()->getAutoScaleCheckBox()->isChecked());
    pPlotWindow->installEventFilter(this);
    QMdiSubWindow *pSubWindow = addSubWindow(pPlotWindow);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/plot-window.svg"));
    pPlotWindow->show();
    if (maximized) {
      pPlotWindow->setWindowState(Qt::WindowMaximized);
    }
  }
  catch (PlotException &e) {
    getMainWindow()->getMessagesWidget()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, e.what(), Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
  Adds a new Plot Parametric Window.
  \param maximized - sets the window state maximized
  */
void PlotWindowContainer::addParametricPlotWindow()
{
  try
  {
    PlotWindow *pPlotWindow = new PlotWindow(QStringList(), this);
    pPlotWindow->setPlotType(PlotWindow::PLOTPARAMETRIC);
    pPlotWindow->setWindowTitle(getUniqueName("Parametric Plot : "));
    pPlotWindow->setTitle("");
    pPlotWindow->setLegendPosition("top");
    pPlotWindow->setAutoScale(mpMainWindow->getOptionsDialog()->getPlottingPage()->getAutoScaleCheckBox()->isChecked());
    pPlotWindow->installEventFilter(this);
    QMdiSubWindow *pSubWindow = addSubWindow(pPlotWindow);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/parametric-plot-window.svg"));
    pPlotWindow->show();
  }
  catch (PlotException &e) {
    getMainWindow()->getMessagesWidget()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, e.what(), Helper::scriptingKind, Helper::errorLevel));
  }
}

void PlotWindowContainer::clearPlotWindow()
{
  PlotWindow *pPlotWindow = getCurrentWindow();
  if (!pPlotWindow)
  {
    QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                             tr("No plot window is active for clearing curves."), Helper::ok);
    return;
  }
  int i = 0;
  while(i != pPlotWindow->getPlot()->getPlotCurvesList().size()) {
    PlotCurve *pPlotCurve = pPlotWindow->getPlot()->getPlotCurvesList()[i];
    pPlotWindow->getPlot()->removeCurve(pPlotCurve);
    pPlotCurve->detach();
    i = 0;   //Restart iteration
  }
  pPlotWindow->fitInView();
  mpMainWindow->getVariablesWidget()->updateVariablesTreeHelper(subWindowList(QMdiArea::ActivationHistoryOrder).last());
}

void PlotWindowContainer::updatePlotWindows(QString variable)
{
  foreach (QMdiSubWindow *pSubWindow, subWindowList())
  {
    PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(pSubWindow->widget());
    foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList())
    {
      if (variable.compare(pPlotCurve->getFileName()) == 0)
      {
        pPlotWindow->getPlot()->removeCurve(pPlotCurve);
        pPlotCurve->detach();
        if (pPlotWindow->getAutoScaleButton()->isChecked()) {
          pPlotWindow->fitInView();
        } else {
          pPlotWindow->getPlot()->replot();
        }
      }
    }
  }
}
