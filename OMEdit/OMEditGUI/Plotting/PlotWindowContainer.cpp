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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "PlotWindowContainer.h"
#include "VariablesWidget.h"

using namespace OMPlot;

/*!
  \class PlotWindowContainer
  \brief A MDI area for plot windows.
  */
/*!
 * \brief PlotWindowContainer::PlotWindowContainer
 * \param pParent
 */
PlotWindowContainer::PlotWindowContainer(MainWindow *pParent)
  : MdiArea(pParent)
{
  if (mpMainWindow->getOptionsDialog()->getPlottingPage()->getPlottingViewMode().compare(Helper::subWindow) == 0) {
    setViewMode(QMdiArea::SubWindowView);
  } else {
    setViewMode(QMdiArea::TabbedView);
  }
}

/*!
 * \brief PlotWindowContainer::getUniqueName
 * Returns a unique name for new plot window.
 * \param name
 * \param number
 * \return
 */
QString PlotWindowContainer::getUniqueName(QString name, int number)
{
  QString newName;
  newName = name + QString::number(number);

  foreach (QMdiSubWindow *pWindow, subWindowList()) {
    if (pWindow->widget()->windowTitle().compare(newName) == 0) {
      newName = getUniqueName(name, ++number);
      break;
    }
  }
  return newName;
}

/*!
 * \brief PlotWindowContainer::getCurrentWindow
 * Returns the current plot window, if the last window is animation, return null
 * \return
 */
PlotWindow* PlotWindowContainer::getCurrentWindow()
{
  if (subWindowList(QMdiArea::ActivationHistoryOrder).size() == 0) {
    return 0;
  } else {
    bool isPlotWidget = (0 != subWindowList(QMdiArea::ActivationHistoryOrder).last()->widget()->objectName().compare(QString("animationWidget")));
    if (isPlotWidget) {
      return qobject_cast<PlotWindow*>(subWindowList(QMdiArea::ActivationHistoryOrder).last()->widget());
    } else {
      return 0;
    }
  }
}

/*!
 * \brief PlotWindowContainer::getCurrentAnimationWindow
 * Returns the current animation window, if the last window is plot, return null
 * \return
 */
AnimationWindow* PlotWindowContainer::getCurrentAnimationWindow()
{
  if (subWindowList(QMdiArea::ActivationHistoryOrder).size() == 0) {
    return 0;
  } else {
    bool isAnimationWidget = (0 == subWindowList(QMdiArea::ActivationHistoryOrder).last()->widget()->objectName().compare(QString("animationWidget")));
    if (isAnimationWidget) {
      return qobject_cast<AnimationWindow*>(subWindowList(QMdiArea::ActivationHistoryOrder).last()->widget());
    } else {
      return 0;
    }
  }
}

/*!
 * \brief PlotWindowContainer::eventFilter
 * \param pObject
 * \param pEvent
 * \return
 */
bool PlotWindowContainer::eventFilter(QObject *pObject, QEvent *pEvent)
{
  bool isPlotWidget = (0 != pObject->objectName().compare(QString("animationWidget")));
  PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(pObject);
  if (pPlotWindow && isPlotWidget && pEvent->type() == QEvent::Paint) {
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
 * \brief PlotWindowContainer::addPlotWindow
 * Adds a new Plot Window.
 * \param maximized - sets the window state maximized
 */
void PlotWindowContainer::addPlotWindow(bool maximized)
{
  try {
    PlotWindow *pPlotWindow = new PlotWindow(QStringList(), this);
    pPlotWindow->setPlotType(PlotWindow::PLOT);
    pPlotWindow->setWindowTitle(getUniqueName("Plot : "));
    pPlotWindow->setTitle("");
    pPlotWindow->setLegendPosition("top");
    pPlotWindow->setAutoScale(mpMainWindow->getOptionsDialog()->getPlottingPage()->getAutoScaleCheckBox()->isChecked());
    pPlotWindow->setTimeUnit(mpMainWindow->getVariablesWidget()->getSimulationTimeComboBox()->currentText());
    pPlotWindow->setXLabel(QString("time [%1]").arg(pPlotWindow->getTimeUnit()));
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
 * \brief PlotWindowContainer::addParametricPlotWindow
 * Adds a new Plot Parametric Window.
 */
void PlotWindowContainer::addParametricPlotWindow()
{
  try {
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

/*!
 * \brief PlotWindowContainer::clearPlotWindow
 * Clears the plot window
 */
void PlotWindowContainer::clearPlotWindow()
{
  PlotWindow *pPlotWindow = getCurrentWindow();
  if (!pPlotWindow) {
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

/*!
 * \brief PlotWindowContainer::exportVariables
 * Exports the selected variables to CSV file.
 */
void PlotWindowContainer::exportVariables()
{
  PlotWindow *pPlotWindow = getCurrentWindow();
  if (!pPlotWindow) {
    QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                             tr("No plot window is active for exporting variables."), Helper::ok);
    return;
  }
  if (pPlotWindow->getPlot()->getPlotCurvesList().isEmpty()) {
    QMessageBox::information(this, QString(Helper::applicationName).append(" - ").append(Helper::information),
                             tr("No variables are selected for exporting."), Helper::ok);
    return;
  }
  QString name = QString("exportedVariables");
  QString fileName = StringHandler::getSaveFileName(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::exportVariables), NULL,
                                                    "CSV Files (*.csv)", NULL, "csv", &name);
  if (fileName.isEmpty()) { // if user press ESC
    return;
  }
  QString contents;
  QStringList headers;
  int dataPoints = 0;
  headers << "\"time\"";
  foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
    headers << "\"" + pPlotCurve->getName() + "\"";
    dataPoints = pPlotCurve->getXAxisData().size();
  }
  // write the csv header
  contents.append(headers.join(",")).append("\n");
  // write csv data
  for (int i = 0 ; i < dataPoints ; ++i) {
    QStringList data;
    // write time data
    data << QString::number(pPlotWindow->getPlot()->getPlotCurvesList().at(0)->getXAxisData().at(i));
    for (int j = 0; j < headers.size() - 1; ++j) {
      data << QString::number(pPlotWindow->getPlot()->getPlotCurvesList().at(j)->getYAxisData().at(i));
    }
    contents.append(data.join(",")).append("\n");
  }
  // create a file
  if (mpMainWindow->getLibraryWidget()->saveFile(fileName, contents)) {
    mpMainWindow->getMessagesWidget()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, tr("Exported variables in %1")
                                                                 .arg(fileName), Helper::scriptingKind, Helper::notificationLevel));
  }
}

/*!
 * \brief PlotWindowContainer::updatePlotWindows
 * Updates the plot windows when the result file is updated.
 * \param variable
 */
void PlotWindowContainer::updatePlotWindows(QString variable)
{
  foreach (QMdiSubWindow *pSubWindow, subWindowList()) {
    bool isPlotWidget = (0 != pSubWindow->widget()->objectName().compare(QString("animationWidget")));
    if (isPlotWidget) {
      PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(pSubWindow->widget());
      foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
        if (variable.compare(pPlotCurve->getFileName()) == 0) {
          pPlotWindow->getPlot()->removeCurve(pPlotCurve);
          pPlotCurve->detach();
          if (pPlotWindow->getAutoScaleButton()->isChecked()) {
            pPlotWindow->fitInView();
          } else {
            pPlotWindow->getPlot()->replot();
          }
        }
      }
    } // is plotWidget
  }
}

/*!
 * \brief PlotWindowContainer::addAnimationWindow
 * Adds an animation widget as subwindow
 */
void PlotWindowContainer::addAnimationWindow(){
  AnimationWindow *pAnimation = new AnimationWindow(this);
  pAnimation->setWindowTitle(getUniqueName("Animation : "));
  QMdiSubWindow *pSubWindow = addSubWindow(pAnimation);
  pSubWindow->setWindowIcon(QIcon(":/Resources/icons/animation.svg"));
  pAnimation->show();
}
