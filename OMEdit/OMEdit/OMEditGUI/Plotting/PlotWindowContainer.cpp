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

#include "PlotWindowContainer.h"
#include "MainWindow.h"
#include "Options/OptionsDialog.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Modeling/MessagesWidget.h"
#include "Plotting/VariablesWidget.h"
#include "Plotting/DiagramWindow.h"

using namespace OMPlot;

/*!
 * \class PlotWindowContainer
 * \brief A MDI area for plot windows.
 */
/*!
 * \brief PlotWindowContainer::PlotWindowContainer
 * \param pParent
 */
PlotWindowContainer::PlotWindowContainer(QWidget *pParent)
  : QMdiArea(pParent), mpDiagramWindow(0)
{
  setHorizontalScrollBarPolicy(Qt::ScrollBarAsNeeded);
  setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
  setActivationOrder(QMdiArea::ActivationHistoryOrder);
  setDocumentMode(true);
#if QT_VERSION >= 0x040800
  setTabsClosable(true);
#endif
  if (OptionsDialog::instance()->getPlottingPage()->getPlottingViewMode().compare(Helper::subWindow) == 0) {
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
    if (isPlotWindow(subWindowList(QMdiArea::ActivationHistoryOrder).last()->widget())) {
      return qobject_cast<PlotWindow*>(subWindowList(QMdiArea::ActivationHistoryOrder).last()->widget());
    } else {
      return 0;
    }
  }
}

PlotWindow* PlotWindowContainer::getInteractiveWindow(QString targetWindow)
{
  if (subWindowList().size() == 0) {
    return 0;
  } else {
    foreach (QMdiSubWindow *pSubWindow, subWindowList()) {
      PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(pSubWindow->widget());
      if (pPlotWindow) {
        if (pPlotWindow->getInteractiveOwner() == targetWindow) {
          return pPlotWindow;
        }
      }
    }
    return 0;
  }
}

/*!
 * \brief PlotWindowContainer::getTopPlotWindow
 * Finds the top PlotWindow and returns it. If there is no PlotWindow then return 0.
 * \return
 */
PlotWindow* PlotWindowContainer::getTopPlotWindow()
{
  QList<QMdiSubWindow*> subWindowsList = subWindowList(QMdiArea::ActivationHistoryOrder);
  for (int i = subWindowsList.size() - 1 ; i >= 0 ; i--) {
    if (isPlotWindow(subWindowsList.at(i)->widget())) {
      return qobject_cast<PlotWindow*>(subWindowsList.at(i)->widget());
    }
  }
  return 0;
}

/*!
 * \brief PlotWindowContainer::setTopPlotWindowActive
 * Finds the top PlotWindow and sets it as active subwindow.
 */
void PlotWindowContainer::setTopPlotWindowActive()
{
  QList<QMdiSubWindow*> subWindowsList = subWindowList(QMdiArea::ActivationHistoryOrder);
  for (int i = subWindowsList.size() - 1 ; i >= 0 ; i--) {
    if (isPlotWindow(subWindowsList.at(i)->widget())) {
      setActiveSubWindow(subWindowsList.at(i));
      return;
    }
  }
}

#if !defined(WITHOUT_OSG)
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
    if (isAnimationWindow(subWindowList(QMdiArea::ActivationHistoryOrder).last()->widget())) {
      return qobject_cast<AnimationWindow*>(subWindowList(QMdiArea::ActivationHistoryOrder).last()->widget());
    } else {
      return 0;
    }
  }
}
#endif

/*!
 * \brief PlotWindowContainer::getDiagramSubWindowFromMdi
 * Returns the diagram sub window, if there is any in the PlotWindowContainer
 * \return
 */
QMdiSubWindow* PlotWindowContainer::getDiagramSubWindowFromMdi()
{
  if (subWindowList(QMdiArea::ActivationHistoryOrder).size() == 0) {
    return 0;
  } else {
    QList<QMdiSubWindow*> subWindowsList = subWindowList(QMdiArea::ActivationHistoryOrder);
    for (int i = subWindowsList.size() - 1 ; i >= 0 ; i--) {
      if (isDiagramWindow(subWindowsList.at(i)->widget())) {
        return subWindowsList.at(i);
      }
    }
    return 0;
  }
}

/*!
 * \brief PlotWindowContainer::isPlotWindow
 * Returns true if pObject is a PlotWindow.
 * \param pObject
 * \return
 */
bool PlotWindowContainer::isPlotWindow(QObject *pObject)
{
  if (0 != pObject->objectName().compare("animationWindow")
      && 0 != pObject->objectName().compare("diagramWindow")) {
    return true;
  }
  return false;
}

/*!
 * \brief PlotWindowContainer::isAnimationWindow
 * Returns true if pObject is a AnimationWindow.
 * \param pObject
 * \return
 */
bool PlotWindowContainer::isAnimationWindow(QObject *pObject)
{
  if (0 == pObject->objectName().compare("animationWindow")) {
    return true;
  }
  return false;
}

/*!
 * \brief PlotWindowContainer::isDiagramWindow
 * Returns true if pObject is a DiagramWindow.
 * \param pObject
 * \return
 */
bool PlotWindowContainer::isDiagramWindow(QObject *pObject)
{
  if (0 == pObject->objectName().compare("diagramWindow")) {
    return true;
  }
  return false;
}

/*!
 * \brief PlotWindowContainer::eventFilter
 * \param pObject
 * \param pEvent
 * \return
 */
bool PlotWindowContainer::eventFilter(QObject *pObject, QEvent *pEvent)
{
  PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(pObject);
  if (pPlotWindow && isPlotWindow(pObject) && pEvent->type() == QEvent::Paint) {
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
    pPlotWindow->setAutoScale(OptionsDialog::instance()->getPlottingPage()->getAutoScaleCheckBox()->isChecked());
    pPlotWindow->setTimeUnit(MainWindow::instance()->getVariablesWidget()->getSimulationTimeComboBox()->currentText());
    pPlotWindow->setXLabel(QString("time (%1)").arg(pPlotWindow->getTimeUnit()));
    pPlotWindow->installEventFilter(this);
    QMdiSubWindow *pSubWindow = addSubWindow(pPlotWindow);
    addCloseActionsToSubWindowSystemMenu(pSubWindow);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/plot-window.svg"));
    pPlotWindow->show();
    if (maximized) {
      pPlotWindow->setWindowState(Qt::WindowMaximized);
    }
  }
  catch (PlotException &e) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, e.what(), Helper::scriptingKind, Helper::errorLevel));
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
    pPlotWindow->setAutoScale(OptionsDialog::instance()->getPlottingPage()->getAutoScaleCheckBox()->isChecked());
    pPlotWindow->setTimeUnit(MainWindow::instance()->getVariablesWidget()->getSimulationTimeComboBox()->currentText());
    pPlotWindow->installEventFilter(this);
    QMdiSubWindow *pSubWindow = addSubWindow(pPlotWindow);
    addCloseActionsToSubWindowSystemMenu(pSubWindow);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/parametric-plot-window.svg"));
    pPlotWindow->show();
  }
  catch (PlotException &e) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, e.what(), Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief PlotWindowContainer::addArrayPlotWindow
 * Adds a new ArrayPlot Window.
 * \param maximized - sets the window state maximized
 */
void PlotWindowContainer::addArrayPlotWindow(bool maximized)
{
  try {
    PlotWindow *pPlotWindow = new PlotWindow(QStringList(), this);
    pPlotWindow->setPlotType(PlotWindow::PLOTARRAY);
    pPlotWindow->setWindowTitle(getUniqueName("Array Plot : "));
    pPlotWindow->setTitle("");
    pPlotWindow->setLegendPosition("top");
    pPlotWindow->setAutoScale(OptionsDialog::instance()->getPlottingPage()->getAutoScaleCheckBox()->isChecked());
    QComboBox* unitComboBox = MainWindow::instance()->getVariablesWidget()->getSimulationTimeComboBox();
    if (unitComboBox->currentText() == ""){
        int currentIndex = unitComboBox->findText("s", Qt::MatchExactly);
        if (currentIndex > -1) {
          unitComboBox->setCurrentIndex(currentIndex);
        }
    }
    pPlotWindow->setTimeUnit(unitComboBox->currentText());
    pPlotWindow->setXLabel(QString("index"));
    pPlotWindow->installEventFilter(this);
    QMdiSubWindow *pSubWindow = addSubWindow(pPlotWindow);
    addCloseActionsToSubWindowSystemMenu(pSubWindow);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/array-plot-window.svg"));
    pPlotWindow->show();
    if (maximized) {
      pPlotWindow->setWindowState(Qt::WindowMaximized);
    }
  }
  catch (PlotException &e) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, e.what(), Helper::scriptingKind, Helper::errorLevel));
  }
}
/*!
 * \brief PlotWindowContainer::addInteractivePlotWindow
 * Adds a new Interactive Plot Window
 */
PlotWindow* PlotWindowContainer::addInteractivePlotWindow(bool maximized, QString owner, int port)
{
  try {
    PlotWindow *pPlotWindow = new PlotWindow(QStringList(), this, true);
    pPlotWindow->setPlotType(PlotWindow::PLOTINTERACTIVE);
    pPlotWindow->setInteractiveOwner(owner);
    pPlotWindow->setInteractivePort(port);
    connect(pPlotWindow, SIGNAL(closingDown()), SLOT(removeInteractivePlotWindow()));
    pPlotWindow->setWindowTitle(tr("Interactive Plot : %1").arg(owner));
    pPlotWindow->setTitle("");
    pPlotWindow->setLegendPosition("top");
    pPlotWindow->setAutoScale(OptionsDialog::instance()->getPlottingPage()->getAutoScaleCheckBox()->isChecked());
    pPlotWindow->setTimeUnit(MainWindow::instance()->getVariablesWidget()->getSimulationTimeComboBox()->currentText());
    pPlotWindow->setXLabel(QString("time (%1)").arg(pPlotWindow->getTimeUnit()));
    pPlotWindow->installEventFilter(this);
    QMdiSubWindow *pSubWindow = addSubWindow(pPlotWindow);
    pPlotWindow->setSubWindow(pSubWindow);
    addCloseActionsToSubWindowSystemMenu(pSubWindow);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/interaction.svg"));
    pPlotWindow->show();
    if (maximized) {
      pPlotWindow->setWindowState(Qt::WindowMaximized);
    }
    return pPlotWindow;
  }
  catch (PlotException &e) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, e.what(), Helper::scriptingKind, Helper::errorLevel));
    return 0;
  }
}

/*!
 * \brief PlotWindowContainer::addParametricArrayPlotWindow
 * Adds a new Array Parametric Plot  Window.
 */
void PlotWindowContainer::addArrayParametricPlotWindow()
{
  try {
    PlotWindow *pPlotWindow = new PlotWindow(QStringList(), this);
    pPlotWindow->setPlotType(PlotWindow::PLOTARRAYPARAMETRIC);
    pPlotWindow->setWindowTitle(getUniqueName("Array Parametric Plot : "));
    pPlotWindow->setTitle("");
    pPlotWindow->setLegendPosition("top");
    pPlotWindow->setAutoScale(OptionsDialog::instance()->getPlottingPage()->getAutoScaleCheckBox()->isChecked());
    QComboBox* unitComboBox = MainWindow::instance()->getVariablesWidget()->getSimulationTimeComboBox();
    if (unitComboBox->currentText() == ""){
        int currentIndex = unitComboBox->findText("s", Qt::MatchExactly);
        if (currentIndex > -1) {
          unitComboBox->setCurrentIndex(currentIndex);
        }
    }
    pPlotWindow->setTimeUnit(unitComboBox->currentText());
    pPlotWindow->installEventFilter(this);
    QMdiSubWindow *pSubWindow = addSubWindow(pPlotWindow);
    addCloseActionsToSubWindowSystemMenu(pSubWindow);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/array-parametric-plot-window.svg"));
    pPlotWindow->show();
  }
  catch (PlotException &e) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, e.what(), Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief PlotWindowContainer::addAnimationWindow
 * Adds an animation widget as subwindow
 * \param maximized - sets the window state maximized
 */
void PlotWindowContainer::addAnimationWindow(bool maximized)
{
#if !defined(WITHOUT_OSG)
  AnimationWindow *pAnimationWindow = new AnimationWindow(this);
  pAnimationWindow->setWindowTitle(getUniqueName("Animation : "));
  QMdiSubWindow *pSubWindow = addSubWindow(pAnimationWindow);
  addCloseActionsToSubWindowSystemMenu(pSubWindow);
  pSubWindow->setWindowIcon(QIcon(":/Resources/icons/animation.svg"));
  pAnimationWindow->show();
  if (maximized) {
    pAnimationWindow->setWindowState(Qt::WindowMaximized);
  }
#else
  assert(0);
#endif
}

/*!
 * \brief PlotWindowContainer::addDiagramWindow
 * Adds a diagram window as subwindow
 * \param maximized - sets the window state maximized
 */
void PlotWindowContainer::addDiagramWindow(bool maximized)
{
  if (!mpDiagramWindow) {
    mpDiagramWindow = new DiagramWindow(this);
    mpDiagramWindow->drawDiagram();
  }
  QMdiSubWindow *pSubWindow = getDiagramSubWindowFromMdi();
  if (!pSubWindow) {
    pSubWindow = addSubWindow(mpDiagramWindow);
    addCloseActionsToSubWindowSystemMenu(pSubWindow);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/modeling.png"));
  }
  mpDiagramWindow->show();
  if (maximized) {
    mpDiagramWindow->setWindowState(Qt::WindowMaximized);
  }
  setActiveSubWindow(pSubWindow);
}

/*!
 * \brief PlotWindowContainer::removeInteractivePlotWindow
 * If an interactive plot window is closed, also remove the tree item
 */
void PlotWindowContainer::removeInteractivePlotWindow()
{
  PlotWindow *pPlotWindow = qobject_cast<PlotWindow*>(sender());
  QString owner = pPlotWindow->getInteractiveOwner();
  MainWindow::instance()->getVariablesWidget()->getVariablesTreeModel()->removeVariableTreeItem(owner);
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
  MainWindow::instance()->getVariablesWidget()->updateVariablesTreeHelper(subWindowList(QMdiArea::ActivationHistoryOrder).last());
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
    dataPoints = pPlotCurve->mXAxisVector.size();
  }
  // write the csv header
  contents.append(headers.join(",")).append("\n");
  // write csv data
  for (int i = 0 ; i < dataPoints ; ++i) {
    QStringList data;
    // write time data
    data << QString::number(pPlotWindow->getPlot()->getPlotCurvesList().at(0)->mXAxisVector.at(i));
    for (int j = 0; j < headers.size() - 1; ++j) {
      PlotCurve *pPlotCurve = pPlotWindow->getPlot()->getPlotCurvesList().at(j);
      OMCInterface::convertUnits_res convertUnit = MainWindow::instance()->getOMCProxy()->convertUnits(pPlotCurve->getDisplayUnit(),
                                                                                                       pPlotCurve->getUnit());
      if (convertUnit.unitsCompatible) {
        data << QString::number(Utilities::convertUnit(pPlotCurve->mYAxisVector.at(i), convertUnit.offset, convertUnit.scaleFactor));
      } else {
        data << QString::number(pPlotCurve->mYAxisVector.at(i));
      }
    }
    contents.append(data.join(",")).append("\n");
  }
  // create a file
  if (MainWindow::instance()->getLibraryWidget()->saveFile(fileName, contents)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, "", false, 0, 0, 0, 0, tr("Exported variables in %1")
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
    if (isPlotWindow(pSubWindow->widget())) {
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
