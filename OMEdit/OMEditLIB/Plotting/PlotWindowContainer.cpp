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

/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "PlotWindowContainer.h"
#include "MainWindow.h"
#include "Options/OptionsDialog.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Modeling/Model.h"
#include "Modeling/Commands.h"
#include "Modeling/MessagesWidget.h"
#include "Plotting/VariablesWidget.h"
#include "Plotting/DiagramWindow.h"
#include "PlotCurve.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Util/StringHandler.h"
#include "qwt_text.h"

#include <QFileInfo>
#include <QInputDialog>
#include <QMessageBox>
#include <QMenu>
#include <QMap>
#include <QVariant>

#include <algorithm>
#include <cmath>

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
  : QMdiArea(pParent), mpDiagramWindow(0), mLastPlotWindowMaximized(true)
{
  setHorizontalScrollBarPolicy(Qt::ScrollBarAsNeeded);
  setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
  setActivationOrder(QMdiArea::ActivationHistoryOrder);
  setDocumentMode(true);
  setTabsClosable(true);
  setTabsMovable(true);
  if (OptionsDialog::instance()->getPlottingPage()->getPlottingViewMode().compare(Helper::subWindow) == 0) {
    MainWindow::switchToWindowMode(this);
  } else {
    MainWindow::switchToTabbedMode(this);
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
    QString oldName = pWindow->widget()->windowTitle();
    if (oldName.compare(newName) == 0) {
      newName = getUniqueName(name, ++number);
      break;
    }
  }
  return newName;
}

bool PlotWindowContainer::isUniqueName(QString name)
{
  bool isUniqueName = true;
  foreach (QMdiSubWindow *pWindow, subWindowList()) {
    QString oldName = pWindow->widget()->windowTitle();
    if (oldName.compare(name) == 0) {
      isUniqueName = false;
      break;
    }
  }
  return isUniqueName;
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

/*!
 * \brief PlotWindowContainer::getPlotSubWindowFromMdi
 * Returns the topmost Plot subwindow, if there is any in the PlotWindowContainer
 * \return
 */
QMdiSubWindow* PlotWindowContainer::getPlotSubWindowFromMdi()
{
  if (subWindowList(QMdiArea::ActivationHistoryOrder).size() == 0) {
    return 0;
  } else {
    QList<QMdiSubWindow*> subWindowsList = subWindowList(QMdiArea::ActivationHistoryOrder);
    for (int i = subWindowsList.size() - 1 ; i >= 0 ; i--) {
      if (isPlotWindow(subWindowsList.at(i)->widget())) {
        return subWindowsList.at(i);
      }
    }
    return 0;
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

#if !defined(WITHOUT_ANIMATION)
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

/*!
 * \brief PlotWindowContainer::getAnimationWindow
 * Returns the most recently active animation window showing fileName, or null if there is none.
 * \param fileName
 * \return
 */
AnimationWindow* PlotWindowContainer::getAnimationWindow(const QString &fileName)
{
  QList<QMdiSubWindow*> subWindowsList = subWindowList(QMdiArea::ActivationHistoryOrder);
  for (int i = subWindowsList.size() - 1 ; i >= 0 ; i--) {
    if (isAnimationWindow(subWindowsList.at(i)->widget())) {
      AnimationWindow *pAnimationWindow = qobject_cast<AnimationWindow*>(subWindowsList.at(i)->widget());
      if (pAnimationWindow && QFileInfo(pAnimationWindow->getFilePath()) == QFileInfo(fileName)) {
        return pAnimationWindow;
      }
    }
  }
  return 0;
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
  if (pObject && 0 != pObject->objectName().compare("animationWindow")
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
  if (pObject && 0 == pObject->objectName().compare("animationWindow")) {
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
  if (pObject && 0 == pObject->objectName().compare("diagramWindow")) {
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
 * \brief PlotWindowContainer::removePlotCurves
 * Removes all the plot curves from PlotWindow
 * \param pPlotWindow
 */
void PlotWindowContainer::removePlotCurves(PlotWindow *pPlotWindow)
{
  int i = 0;
  while(i != pPlotWindow->getPlot()->getPlotCurvesList().size()) {
    PlotCurve *pPlotCurve = pPlotWindow->getPlot()->getPlotCurvesList()[i];
    pPlotWindow->getPlot()->removeCurve(pPlotCurve);
    pPlotCurve->detach();
    i = 0;   //Restart iteration
  }
}

/*!
 * \brief PlotWindowContainer::showDiagramWindow
 * Shows/Updates the Diagram Window if there is any.
 * \param pModelWidget
 * \param initializeVisualization
 */
void PlotWindowContainer::showDiagramWindow(ModelWidget *pModelWidget, bool initializeVisualization)
{
  if (mpDiagramWindow) {
    mpDiagramWindow->showVisualizationDiagram(pModelWidget ? pModelWidget : MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget());
    if (initializeVisualization) {
      MainWindow::instance()->getVariablesWidget()->initializeVisualization();
    }
  }
}

/*!
 * \brief PlotWindowContainer::addPlotWindow
 * Adds a new Plot Window.
 */
PlotWindow* PlotWindowContainer::addPlotWindow()
{
  try {
    PlotWindow *pPlotWindow = new PlotWindow(QStringList(), this, false, OptionsDialog::instance()->getGeneralSettingsPage()->getToolbarIconSizeSpinBox()->value());
    pPlotWindow->setPlotType(PlotWindow::PLOT);
    pPlotWindow->setWindowTitle(getUniqueName("Plot : "));
    pPlotWindow->setTitle("");
    pPlotWindow->setLegendPosition("top");
    pPlotWindow->setAutoScale(OptionsDialog::instance()->getPlottingPage()->getAutoScaleCheckBox()->isChecked());
    pPlotWindow->setCanHavePrefixUnits(true);
    pPlotWindow->setPrefixUnits(OptionsDialog::instance()->getPlottingPage()->getPrefixUnitsCheckbox()->isChecked());
    pPlotWindow->setTimeUnit(MainWindow::instance()->getVariablesWidget()->getSimulationTimeComboBox()->currentText());
    pPlotWindow->setXLabel(QString("time"));
    pPlotWindow->installEventFilter(this);
    bool maximize = subWindowList().isEmpty() ? mLastPlotWindowMaximized : false;
    QMdiSubWindow *pSubWindow = addSubWindow(pPlotWindow);
    connect(pPlotWindow, &PlotWindow::closingDown, this, [this, pSubWindow]() {
      mLastPlotWindowMaximized = pSubWindow->isMaximized();
    });
    PlottingPage *pPlottingPage = OptionsDialog::instance()->getPlottingPage();
    pPlotWindow->getPlot()->setFontSizes(pPlottingPage->getTitleFontSizeSpinBox()->value(), pPlottingPage->getVerticalAxisTitleFontSizeSpinBox()->value(), pPlottingPage->getVerticalAxisNumbersFontSizeSpinBox()->value(),
                                         pPlottingPage->getVerticalAxisTitleFontSizeSpinBox()->value(), pPlottingPage->getVerticalAxisNumbersFontSizeSpinBox()->value(),
                                         pPlottingPage->getHorizontalAxisTitleFontSizeSpinBox()->value(), pPlottingPage->getHorizontalAxisNumbersFontSizeSpinBox()->value(), pPlottingPage->getFooterFontSizeSpinBox()->value(),
                                         pPlottingPage->getLegendFontSizeSpinBox()->value());
    addCloseActionsToSubWindowSystemMenu(pSubWindow);
    addRenameTabToSubWindowSystemMenu(pSubWindow);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/plot-window.svg"));
    pPlotWindow->show();
    if (maximize) {
      pPlotWindow->setWindowState(Qt::WindowMaximized);
    }
    return pPlotWindow;
  }
  catch (PlotException &e) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, e.what(), Helper::scriptingKind, Helper::errorLevel));
  }
  return nullptr;
}

/*!
 * \brief PlotWindowContainer::addParametricPlotWindow
 * Adds a new Plot Parametric Window.
 */
void PlotWindowContainer::addParametricPlotWindow()
{
  try {
    PlotWindow *pPlotWindow = new PlotWindow(QStringList(), this, false, OptionsDialog::instance()->getGeneralSettingsPage()->getToolbarIconSizeSpinBox()->value());
    pPlotWindow->setPlotType(PlotWindow::PLOTPARAMETRIC);
    pPlotWindow->setWindowTitle(getUniqueName("Parametric Plot : "));
    pPlotWindow->setTitle("");
    pPlotWindow->setLegendPosition("top");
    pPlotWindow->setAutoScale(OptionsDialog::instance()->getPlottingPage()->getAutoScaleCheckBox()->isChecked());
    pPlotWindow->setCanHavePrefixUnits(true);
    pPlotWindow->setPrefixUnits(OptionsDialog::instance()->getPlottingPage()->getPrefixUnitsCheckbox()->isChecked());
    pPlotWindow->setTimeUnit(MainWindow::instance()->getVariablesWidget()->getSimulationTimeComboBox()->currentText());
    pPlotWindow->installEventFilter(this);
    bool maximize = subWindowList().isEmpty() ? mLastPlotWindowMaximized : false;
    QMdiSubWindow *pSubWindow = addSubWindow(pPlotWindow);
    connect(pPlotWindow, &PlotWindow::closingDown, this, [this, pSubWindow]() {
      mLastPlotWindowMaximized = pSubWindow->isMaximized();
    });
    PlottingPage *pPlottingPage = OptionsDialog::instance()->getPlottingPage();
    pPlotWindow->getPlot()->setFontSizes(pPlottingPage->getTitleFontSizeSpinBox()->value(), pPlottingPage->getVerticalAxisTitleFontSizeSpinBox()->value(), pPlottingPage->getVerticalAxisNumbersFontSizeSpinBox()->value(),
                                         pPlottingPage->getVerticalAxisTitleFontSizeSpinBox()->value(), pPlottingPage->getVerticalAxisNumbersFontSizeSpinBox()->value(),
                                         pPlottingPage->getHorizontalAxisTitleFontSizeSpinBox()->value(), pPlottingPage->getHorizontalAxisNumbersFontSizeSpinBox()->value(), pPlottingPage->getFooterFontSizeSpinBox()->value(),
                                         pPlottingPage->getLegendFontSizeSpinBox()->value());
    addCloseActionsToSubWindowSystemMenu(pSubWindow);
    addRenameTabToSubWindowSystemMenu(pSubWindow);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/parametric-plot-window.svg"));
    pPlotWindow->show();
    if (maximize) {
      pPlotWindow->setWindowState(Qt::WindowMaximized);
    }
  }
  catch (PlotException &e) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, e.what(), Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief PlotWindowContainer::addArrayPlotWindow
 * Adds a new ArrayPlot Window.
 */
void PlotWindowContainer::addArrayPlotWindow()
{
  try {
    PlotWindow *pPlotWindow = new PlotWindow(QStringList(), this, false, OptionsDialog::instance()->getGeneralSettingsPage()->getToolbarIconSizeSpinBox()->value());
    pPlotWindow->setPlotType(PlotWindow::PLOTARRAY);
    pPlotWindow->setWindowTitle(getUniqueName("Array Plot : "));
    pPlotWindow->setTitle("");
    pPlotWindow->setLegendPosition("top");
    pPlotWindow->setAutoScale(OptionsDialog::instance()->getPlottingPage()->getAutoScaleCheckBox()->isChecked());
    pPlotWindow->setCanHavePrefixUnits(true);
    pPlotWindow->setPrefixUnits(OptionsDialog::instance()->getPlottingPage()->getPrefixUnitsCheckbox()->isChecked());
    QComboBox* unitComboBox = MainWindow::instance()->getVariablesWidget()->getSimulationTimeComboBox();
    if (unitComboBox->currentText() == ""){
        int currentIndex = unitComboBox->findText("s", Qt::MatchExactly);
        if (currentIndex > -1) {
          unitComboBox->setCurrentIndex(currentIndex);
        }
    }
    pPlotWindow->setTimeUnit(unitComboBox->currentText());
    pPlotWindow->setXLabel(QString("array element index"));
    pPlotWindow->installEventFilter(this);
    bool maximize = subWindowList().isEmpty() ? mLastPlotWindowMaximized : false;
    QMdiSubWindow *pSubWindow = addSubWindow(pPlotWindow);
    connect(pPlotWindow, &PlotWindow::closingDown, this, [this, pSubWindow]() {
      mLastPlotWindowMaximized = pSubWindow->isMaximized();
    });
    PlottingPage *pPlottingPage = OptionsDialog::instance()->getPlottingPage();
    pPlotWindow->getPlot()->setFontSizes(pPlottingPage->getTitleFontSizeSpinBox()->value(), pPlottingPage->getVerticalAxisTitleFontSizeSpinBox()->value(), pPlottingPage->getVerticalAxisNumbersFontSizeSpinBox()->value(),
                                         pPlottingPage->getVerticalAxisTitleFontSizeSpinBox()->value(), pPlottingPage->getVerticalAxisNumbersFontSizeSpinBox()->value(),
                                         pPlottingPage->getHorizontalAxisTitleFontSizeSpinBox()->value(), pPlottingPage->getHorizontalAxisNumbersFontSizeSpinBox()->value(), pPlottingPage->getFooterFontSizeSpinBox()->value(),
                                         pPlottingPage->getLegendFontSizeSpinBox()->value());
    addCloseActionsToSubWindowSystemMenu(pSubWindow);
    addRenameTabToSubWindowSystemMenu(pSubWindow);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/array-plot-window.svg"));
    pPlotWindow->show();
    if (maximize) {
      pPlotWindow->setWindowState(Qt::WindowMaximized);
    }
  }
  catch (PlotException &e) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, e.what(), Helper::scriptingKind, Helper::errorLevel));
  }
}
/*!
 * \brief PlotWindowContainer::addInteractivePlotWindow
 * Adds a new Interactive Plot Window
 */
PlotWindow* PlotWindowContainer::addInteractivePlotWindow(QString owner, int port)
{
  try {
    PlotWindow *pPlotWindow = new PlotWindow(QStringList(), this, true, OptionsDialog::instance()->getGeneralSettingsPage()->getToolbarIconSizeSpinBox()->value());
    pPlotWindow->setPlotType(PlotWindow::PLOTINTERACTIVE);
    pPlotWindow->setInteractiveOwner(owner);
    pPlotWindow->setInteractivePort(port);
    connect(pPlotWindow, &PlotWindow::closingDown, this, &PlotWindowContainer::removeInteractivePlotWindow);
    pPlotWindow->setWindowTitle(tr("Interactive Plot: %1").arg(owner));
    pPlotWindow->setTitle("");
    pPlotWindow->setLegendPosition("top");
    pPlotWindow->setAutoScale(OptionsDialog::instance()->getPlottingPage()->getAutoScaleCheckBox()->isChecked());
    pPlotWindow->setCanHavePrefixUnits(true);
    pPlotWindow->setPrefixUnits(OptionsDialog::instance()->getPlottingPage()->getPrefixUnitsCheckbox()->isChecked());
    pPlotWindow->setTimeUnit(MainWindow::instance()->getVariablesWidget()->getSimulationTimeComboBox()->currentText());
    pPlotWindow->setXLabel(QString("time"));
    pPlotWindow->installEventFilter(this);
    bool maximize = subWindowList().isEmpty() ? mLastPlotWindowMaximized : false;
    QMdiSubWindow *pSubWindow = addSubWindow(pPlotWindow);
    connect(pPlotWindow, &PlotWindow::closingDown, this, [this, pSubWindow]() {
      mLastPlotWindowMaximized = pSubWindow->isMaximized();
    });
    PlottingPage *pPlottingPage = OptionsDialog::instance()->getPlottingPage();
    pPlotWindow->getPlot()->setFontSizes(pPlottingPage->getTitleFontSizeSpinBox()->value(), pPlottingPage->getVerticalAxisTitleFontSizeSpinBox()->value(), pPlottingPage->getVerticalAxisNumbersFontSizeSpinBox()->value(),
                                         pPlottingPage->getVerticalAxisTitleFontSizeSpinBox()->value(), pPlottingPage->getVerticalAxisNumbersFontSizeSpinBox()->value(),
                                         pPlottingPage->getHorizontalAxisTitleFontSizeSpinBox()->value(), pPlottingPage->getHorizontalAxisNumbersFontSizeSpinBox()->value(), pPlottingPage->getFooterFontSizeSpinBox()->value(),
                                         pPlottingPage->getLegendFontSizeSpinBox()->value());
    pPlotWindow->setSubWindow(pSubWindow);
    addCloseActionsToSubWindowSystemMenu(pSubWindow);
    addRenameTabToSubWindowSystemMenu(pSubWindow);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/interaction.svg"));
    pPlotWindow->show();
    if (maximize) {
      pPlotWindow->setWindowState(Qt::WindowMaximized);
    }
    return pPlotWindow;
  }
  catch (PlotException &e) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, e.what(), Helper::scriptingKind, Helper::errorLevel));
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
    PlotWindow *pPlotWindow = new PlotWindow(QStringList(), this, false, OptionsDialog::instance()->getGeneralSettingsPage()->getToolbarIconSizeSpinBox()->value());
    pPlotWindow->setPlotType(PlotWindow::PLOTARRAYPARAMETRIC);
    pPlotWindow->setWindowTitle(getUniqueName("Array Parametric Plot : "));
    pPlotWindow->setTitle("");
    pPlotWindow->setLegendPosition("top");
    pPlotWindow->setAutoScale(OptionsDialog::instance()->getPlottingPage()->getAutoScaleCheckBox()->isChecked());
    pPlotWindow->setCanHavePrefixUnits(true);
    pPlotWindow->setPrefixUnits(OptionsDialog::instance()->getPlottingPage()->getPrefixUnitsCheckbox()->isChecked());
    QComboBox* unitComboBox = MainWindow::instance()->getVariablesWidget()->getSimulationTimeComboBox();
    if (unitComboBox->currentText() == ""){
        int currentIndex = unitComboBox->findText("s", Qt::MatchExactly);
        if (currentIndex > -1) {
          unitComboBox->setCurrentIndex(currentIndex);
        }
    }
    pPlotWindow->setTimeUnit(unitComboBox->currentText());
    pPlotWindow->installEventFilter(this);
    bool maximize = subWindowList().isEmpty() ? mLastPlotWindowMaximized : false;
    QMdiSubWindow *pSubWindow = addSubWindow(pPlotWindow);
    connect(pPlotWindow, &PlotWindow::closingDown, this, [this, pSubWindow]() {
      mLastPlotWindowMaximized = pSubWindow->isMaximized();
    });
    PlottingPage *pPlottingPage = OptionsDialog::instance()->getPlottingPage();
    pPlotWindow->getPlot()->setFontSizes(pPlottingPage->getTitleFontSizeSpinBox()->value(), pPlottingPage->getVerticalAxisTitleFontSizeSpinBox()->value(), pPlottingPage->getVerticalAxisNumbersFontSizeSpinBox()->value(),
                                         pPlottingPage->getVerticalAxisTitleFontSizeSpinBox()->value(), pPlottingPage->getVerticalAxisNumbersFontSizeSpinBox()->value(),
                                         pPlottingPage->getHorizontalAxisTitleFontSizeSpinBox()->value(), pPlottingPage->getHorizontalAxisNumbersFontSizeSpinBox()->value(), pPlottingPage->getFooterFontSizeSpinBox()->value(),
                                         pPlottingPage->getLegendFontSizeSpinBox()->value());
    addCloseActionsToSubWindowSystemMenu(pSubWindow);
    addRenameTabToSubWindowSystemMenu(pSubWindow);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/array-parametric-plot-window.svg"));
    pPlotWindow->show();
    if (maximize) {
      pPlotWindow->setWindowState(Qt::WindowMaximized);
    }
  }
  catch (PlotException &e) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, e.what(), Helper::scriptingKind, Helper::errorLevel));
  }
}

/*!
 * \brief PlotWindowContainer::addAnimationWindow
 * Adds an animation widget as subwindow
 */
void PlotWindowContainer::addAnimationWindow()
{
#if !defined(WITHOUT_ANIMATION)
  AnimationWindow *pAnimationWindow = new AnimationWindow(this);
  pAnimationWindow->setWindowTitle(getUniqueName("Animation : "));
  bool maximize = subWindowList().isEmpty();
  QMdiSubWindow *pSubWindow = addSubWindow(pAnimationWindow);
  addCloseActionsToSubWindowSystemMenu(pSubWindow);
  addRenameTabToSubWindowSystemMenu(pSubWindow);
  pSubWindow->setWindowIcon(QIcon(":/Resources/icons/animation.svg"));
  pAnimationWindow->show();
  if (maximize) {
    pAnimationWindow->setWindowState(Qt::WindowMaximized);
  }
#else
  assert(0);
#endif
}

/*!
 * \brief PlotWindowContainer::addDiagramWindow
 * Adds a diagram window as subwindow
 * \param pModelWidget
 */
void PlotWindowContainer::addDiagramWindow(ModelWidget *pModelWidget)
{
  if (!mpDiagramWindow) {
    mpDiagramWindow = new DiagramWindow(this);
  }
  showDiagramWindow(pModelWidget);
  QMdiSubWindow *pSubWindow = getDiagramSubWindowFromMdi();
  bool maximize = false;
  if (!pSubWindow) {
    maximize = subWindowList().isEmpty();
    pSubWindow = addSubWindow(mpDiagramWindow);
    addCloseActionsToSubWindowSystemMenu(pSubWindow);
    addRenameTabToSubWindowSystemMenu(pSubWindow);
    pSubWindow->setWindowIcon(QIcon(":/Resources/icons/modeling.png"));
  }
  mpDiagramWindow->show();
  if (maximize) {
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
  MainWindow::instance()->getVariablesWidget()->getVariablesTreeModel()->removeVariableTreeItem(owner, false);
}

/*!
 * \brief PlotWindowContainer::renamePlotWindow
 * Enables the renaming of an existing plot window using right click.
 */
void PlotWindowContainer::renamePlotWindow()
{
  QAction *pAction = qobject_cast<QAction*>(sender());
  QMdiSubWindow *pMdiSubWindow = qobject_cast<QMdiSubWindow*>(pAction->parent());
  bool okPressed = false;
  QString text = QInputDialog::getText(this,
                                       tr("Name Plot Tab"),
                                       tr("Name:"),
                                       QLineEdit::Normal,
                                       pMdiSubWindow->windowTitle(), &okPressed);
  if (okPressed && !text.isEmpty()) {
    if (isUniqueName(text)) {
      pMdiSubWindow->widget()->setWindowTitle(text);
    }
    else /* Name it the users name + 1. Avoids another popup. */{
      QString uniqueName = getUniqueName(text, 1);
      pMdiSubWindow->widget()->setWindowTitle(uniqueName);
    }
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
                             tr("No plot window is active for clearing curves."), QMessageBox::Ok);
    return;
  }
  removePlotCurves(pPlotWindow);
  pPlotWindow->updatePlot();
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
    QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information), tr("No plot window is active for exporting variables."), QMessageBox::Ok);
    return;
  }
  if (pPlotWindow->isPlotParametric() || pPlotWindow->isPlotArrayParametric()) {
    QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information), tr("Cannot export parametric plot."), QMessageBox::Ok);
    return;
  }
  if (pPlotWindow->getPlot()->getPlotCurvesList().isEmpty()) {
    QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information), tr("No variables are selected for exporting."), QMessageBox::Ok);
    return;
  }

  QString filePath = "";
  QwtArray<double> timeVector;
  QStringList headers;
  headers << "\"time\"";
  int i = 0;
  foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
    if (pPlotCurve) {
      if (i == 0) { // first iteration
        filePath = pPlotCurve->getAbsoluteFilePath();
      }
      if (timeVector.size() < pPlotCurve->mXAxisVector.size()) {
        timeVector = pPlotCurve->mXAxisVector;
      }
      if (filePath.compare(pPlotCurve->getAbsoluteFilePath()) != 0) {
        QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information), tr("Not possible to export variables from different result files."), QMessageBox::Ok);
        return;
      }
      headers << QString("\"%1\"").arg(pPlotCurve->getYVariable());
    }
    ++i;
  }

  QString name = QStringLiteral("exportedVariables");
  QString fileName = StringHandler::getSaveFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::exportVariables), NULL, "CSV Files (*.csv)", NULL, "csv", &name);
  if (fileName.isEmpty()) { // if user press ESC
    return;
  }

  // write the csv header
  QString contents;
  contents.append(headers.join(",")).append("\n");
  // write csv data
  for (int i = 0 ; i < timeVector.size() ; ++i) {
    QStringList data;
    // write time data
    data << StringHandler::number(timeVector.at(i));
    foreach (PlotCurve *pPlotCurve, pPlotWindow->getPlot()->getPlotCurvesList()) {
      double value;
      if (pPlotCurve && pPlotCurve->mYAxisVector.size() > i) { // parameters have just start and stop points in the dataset
        value = pPlotCurve->mYAxisVector.at(i);
      } else if (pPlotCurve && pPlotCurve->mYAxisVector.size() > 0) { // Set last value to have constant values for parameters
        value = pPlotCurve->mYAxisVector.last();
      } else { // otherwise set value to 0.0 but perhaps we should never reach there.
        value = 0.0;
      }
      OMCInterface::convertUnits_res convertUnit = MainWindow::instance()->getOMCProxy()->convertUnits(pPlotCurve->getYDisplayUnit(), pPlotCurve->getYUnit());
      if (convertUnit.unitsCompatible) {
        data << StringHandler::number(Utilities::convertUnit(value, convertUnit.offset, convertUnit.scaleFactor));
      } else {
        data << StringHandler::number(value);
      }
    }
    contents.append(data.join(",")).append("\n");
  }
  // create a file
  if (MainWindow::instance()->getLibraryWidget()->saveFile(fileName, contents)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, tr("Exported variables in %1").arg(fileName), Helper::scriptingKind, Helper::notificationLevel));
  }
}

/*!
 * \brief PlotWindowContainer::saveFigureInModel
 * Saves the active plot into each source model's Documentation annotation.
 *
 * Curves are grouped by their own result model because one plot may contain
 * variables from multiple simulation results.
 */
void PlotWindowContainer::saveFigureInModel()
{
  PlotWindow *pPlotWindow = getCurrentWindow();
  if (!pPlotWindow || (!pPlotWindow->isPlot() && !pPlotWindow->isPlotParametric())) {
    QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                             tr("Select a plot window before saving a figure in a model."), QMessageBox::Ok);
    return;
  }

  const QList<PlotCurve*> plotCurves = pPlotWindow->getPlot()->getPlotCurvesList();
  if (plotCurves.isEmpty()) {
    QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                             tr("There are no curves to save in the model annotation."), QMessageBox::Ok);
    return;
  }

  VariablesWidget *pVariablesWidget = MainWindow::instance()->getVariablesWidget();
  VariablesTreeModel *pVariablesTreeModel = pVariablesWidget->getVariablesTreeModel();
  QMap<QString, QList<PlotCurve*>> curvesByModel;
  for (PlotCurve *pPlotCurve : plotCurves) {
    if (!pPlotCurve || pPlotCurve->getYVariable().isEmpty()) {
      continue;
    }
    VariablesTreeItem *pResultTreeItem = pVariablesTreeModel->findVariablesTreeItemOneLevel(pPlotCurve->getFileName());
    if (!pResultTreeItem) {
      QMessageBox::warning(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                           tr("Could not find the simulation result associated with curve %1.")
                           .arg(pPlotCurve->getYVariable()), QMessageBox::Ok);
      return;
    }
    const QString className = pResultTreeItem->getSimulationOptions().getClassName();
    curvesByModel[className].append(pPlotCurve);
  }
  if (curvesByModel.isEmpty()) {
    QMessageBox::information(this, QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                             tr("There are no valid curves to save in the model annotation."), QMessageBox::Ok);
    return;
  }

  auto makeAxis = [](const QString &label, bool hasRange, double min, double max, bool logarithmic) {
    auto pAxis = std::make_unique<ModelInstance::Axis>();
    if (hasRange && std::isfinite(min)) {
      pAxis->setMin(FlatModelica::Expression(min));
    }
    if (hasRange && std::isfinite(max)) {
      pAxis->setMax(FlatModelica::Expression(max));
    }
    pAxis->setLabel(label);
    if (logarithmic) {
      auto pScale = std::make_unique<ModelInstance::AxisScale>();
      pScale->setScaleType("Log");
      pAxis->setScale(std::move(pScale));
    }
    return pAxis;
  };

  const QwtScaleDiv &xScale = pPlotWindow->getPlot()->axisScaleDiv(QwtPlot::xBottom);
  const QwtScaleDiv &yScale = pPlotWindow->getPlot()->axisScaleDiv(QwtPlot::yLeft);
  const bool isZoomed = pPlotWindow->getPlot()->getPlotZoomer()->zoomRectIndex() > 0;
  const QRectF zoomRect = pPlotWindow->getPlot()->getPlotZoomer()->zoomRect();
  const double xMinimum = isZoomed ? zoomRect.left() : xScale.lowerBound();
  const double xMaximum = isZoomed ? zoomRect.right() : xScale.upperBound();
  const double yMinimum = isZoomed ? qMin(zoomRect.top(), zoomRect.bottom()) : yScale.lowerBound();
  const double yMaximum = isZoomed ? qMax(zoomRect.top(), zoomRect.bottom()) : yScale.upperBound();
  const bool yAxisAutoScale = pPlotWindow->getPlot()->axisAutoScale(QwtPlot::yLeft);
  const QwtScaleDiv &yRightScale = pPlotWindow->getPlot()->axisScaleDiv(QwtPlot::yRight);
  const bool yRightAxisAutoScale = pPlotWindow->getPlot()->axisAutoScale(QwtPlot::yRight);
  const QString plotTitle = pPlotWindow->getPlot()->title().text();
  const QVariant figureTitleProperty = pPlotWindow->property(Helper::modelicaFigureTitle.toStdString().c_str());
  const QString figureTitle = figureTitleProperty.isValid() ? figureTitleProperty.toString() : pPlotWindow->windowTitle();
  bool savedAnyFigure = false;
  foreach (const QString &className, curvesByModel.keys()) {
    auto pPlot = std::make_unique<ModelInstance::Plot>();
    const QList<PlotCurve*> modelCurves = curvesByModel.value(className);
    const bool usesRightYAxis = std::any_of(modelCurves.cbegin(), modelCurves.cend(), [](PlotCurve *pPlotCurve) {
      return pPlotCurve->isYAxisRight();
    });
    bool timeXAxis = pPlotWindow->isPlot();
    bool hasTimeValues = false;
    double timeStart = 0.0;
    double timeStop = 0.0;
    for (int i = 0; i < modelCurves.size(); ++i) {
      PlotCurve *pPlotCurve = modelCurves.at(i);
      const QString xVariable = pPlotCurve->getXVariable().isEmpty() ? QStringLiteral("time") : pPlotCurve->getXVariable();
      if (xVariable != QStringLiteral("time")) {
        timeXAxis = false;
      } else {
        for (double time : pPlotCurve->mXAxisVector) {
          if (!std::isfinite(time)) {
            continue;
          }
          if (!hasTimeValues) {
            timeStart = timeStop = time;
            hasTimeValues = true;
          } else {
            timeStart = qMin(timeStart, time);
            timeStop = qMax(timeStop, time);
          }
        }
      }
      auto pCurve = std::make_unique<ModelInstance::Curve>();
      try {
        pCurve->setX(FlatModelica::Expression::parse(xVariable));
        pCurve->setY(FlatModelica::Expression::parse(pPlotCurve->getYVariable()));
      } catch (const std::exception &) {
        MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                              tr("Cannot save curve %1 in figure %2 because it is not a valid expression.").arg(pPlotCurve->getYVariable(), figureTitle),
                                                              Helper::scriptingKind, Helper::errorLevel));
        continue;
      }
      pCurve->setLegend(pPlotCurve->getCustomTitle());
      if (pPlotCurve->isYAxisRight()) {
        pCurve->setYAxis(ModelInstance::Curve::YAxis::Right);
      }
      pCurve->setZOrder(i);
      pPlot->addCurve(std::move(pCurve));
    }
    const bool showsFullTimeRange = timeXAxis && hasTimeValues
        && xMinimum <= timeStart && xMaximum >= timeStop;
    const double timeUnitFactor = timeXAxis && !showsFullTimeRange ? pPlotWindow->getTimeUnitFactor() : 1.0;
    pPlot->setTitle(plotTitle);
    pPlot->setXAxis(makeAxis(pPlotWindow->getXCustomLabel(), !showsFullTimeRange, xMinimum / timeUnitFactor,
                             xMaximum / timeUnitFactor, pPlotWindow->getLogXCheckBox()->isChecked()));
    pPlot->setYAxis(makeAxis(pPlotWindow->getYCustomLabel(), !yAxisAutoScale, yMinimum, yMaximum,
                             pPlotWindow->getLogYCheckBox()->isChecked()));
    if (usesRightYAxis) {
      pPlot->setYRightAxis(makeAxis(pPlotWindow->getYRightCustomLabel(), !yRightAxisAutoScale, yRightScale.lowerBound(),
                                    yRightScale.upperBound(), pPlotWindow->getLogYCheckBox()->isChecked()));
    }
    auto pFigure = std::make_unique<ModelInstance::Figure>();
    pFigure->setTitle(figureTitle);
    pFigure->setPreferred(true);
    pFigure->addPlot(std::move(pPlot));

    LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(className);
    if (!pLibraryTreeItem || !pLibraryTreeItem->isModelica() || pLibraryTreeItem->isSystemLibrary()) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                            tr("Cannot save figure %1 in model %2 because the model cannot be annotated.").arg(figureTitle, className),
                                                            Helper::scriptingKind, Helper::errorLevel));
      continue;
    }

    ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
    if (!pModelWidget) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                            tr("The model %1 is not open; the figure was not saved.").arg(className),
                                                            Helper::scriptingKind, Helper::notificationLevel));
      continue;
    }
    if (!pModelWidget->getModelInstance()) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, tr("The model instance for %1 is not available; the figure was not saved.").arg(className),
                                                            Helper::scriptingKind, Helper::errorLevel));
      continue;
    }

    ModelInstance::Model *pModelInstance = pModelWidget->getModelInstance();
    const ModelInstance::DocumentationAnnotation *pDocumentationAnnotation = pModelInstance->getAnnotation()->getDocumentationAnnotation();
    const ModelInstance::DocumentationAnnotation emptyDocumentation;
    const ModelInstance::DocumentationAnnotation &documentation = pDocumentationAnnotation ? *pDocumentationAnnotation : emptyDocumentation;
    const QString newAnnotation = QString("annotate=%1").arg(documentation.toString(*pFigure));

    ModelInfo oldModelInfo = pModelWidget->createModelInfo();
    if (!MainWindow::instance()->getOMCProxy()->addClassAnnotation(className, newAnnotation)) {
      continue;
    }
    // Keep the loaded model-instance data in sync without reloading it from OMC.
    pModelInstance->getOrCreateAnnotation()->getOrCreateDocumentationAnnotation()->setFigure(std::move(pFigure));
    ModelInfo newModelInfo = pModelWidget->createModelInfo();
    pModelWidget->getUndoStack()->push(new OMCUndoCommand(pLibraryTreeItem, oldModelInfo, newModelInfo, tr("Save Figure in model %1").arg(className), true));
    pModelWidget->updateModelText();
    savedAnyFigure = true;
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, tr("Saved figure %1 in model %2.").arg(figureTitle, className),
                                                          Helper::scriptingKind, Helper::notificationLevel));
  }
  if (!savedAnyFigure) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, tr("Could not save the figure in any model."), Helper::scriptingKind, Helper::errorLevel));
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
          pPlotWindow->updatePlot();
        }
      }
    } // is plotWidget
  }
}

/*!
 * \brief addRenameTabToSubWindowSystemMenu
 * Adds the rename tab action to the sub system menu
 */
void PlotWindowContainer::addRenameTabToSubWindowSystemMenu(QMdiSubWindow *pMdiSubWindow)
{
  QAction *pRenamePlotWindowAction = new QAction(tr("Rename"), pMdiSubWindow);
  pRenamePlotWindowAction->setStatusTip(tr("Renames the plot tab"));
  connect(pRenamePlotWindowAction, &QAction::triggered, this, &PlotWindowContainer::renamePlotWindow);
  QMenu *pMenu = pMdiSubWindow->systemMenu();
  pMenu->addAction(pRenamePlotWindowAction);
}
