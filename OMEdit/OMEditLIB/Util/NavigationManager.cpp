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

#include "Util/NavigationManager.h"

#include "MainWindow.h"
#include "Editors/BaseEditor.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Plotting/PlotWindowContainer.h"
#include "Modeling/DocumentationWidget.h"

#include <QApplication>
#include <QKeyEvent>
#include <QMouseEvent>
#include <QMdiSubWindow>

NavigationManager *NavigationManager::mpInstance = nullptr;

/*!
 * \brief NavigationManager::NavigationManager
 * \param pParent
 */
NavigationManager::NavigationManager(QObject *pParent)
  : QObject(pParent)
{
  // detect the back/forward navigation globally no matter which widget has the focus
  qApp->installEventFilter(this);
}

/*!
 * \brief NavigationManager::instance
 * Returns the singleton instance of NavigationManager.
 * \return
 */
NavigationManager *NavigationManager::instance()
{
  if (!mpInstance) {
    mpInstance = new NavigationManager;
  }
  return mpInstance;
}

/*!
 * \brief NavigationManager::eventFilter
 * Handles the Alt+Left/Alt+Right keys and the mouse buttons 4/5 globally so the
 * back/forward navigation works no matter which widget currently has the focus.
 * The events are left untouched when they occur inside the documentation viewer
 * so the web engine can handle its own back/forward navigation.
 * \param pObject
 * \param pEvent
 * \return
 */
bool NavigationManager::eventFilter(QObject *pObject, QEvent *pEvent)
{
  if (pEvent->type() == QEvent::MouseButtonPress) {
    QMouseEvent *pMouseEvent = static_cast<QMouseEvent*>(pEvent);
    if (pMouseEvent->button() == Qt::BackButton || pMouseEvent->button() == Qt::ForwardButton) {
      if (!isInsideDocumentationViewer(pObject)) {
        if (pMouseEvent->button() == Qt::BackButton) {
          goBack();
        } else {
          goForward();
        }
        pEvent->accept();
        return true;
      }
    }
  } else if (pEvent->type() == QEvent::KeyPress) {
    QKeyEvent *pKeyEvent = static_cast<QKeyEvent*>(pEvent);
    bool altModifier = pKeyEvent->modifiers().testFlag(Qt::AltModifier);
    bool controlModifier = pKeyEvent->modifiers().testFlag(Qt::ControlModifier);
    bool shiftModifier = pKeyEvent->modifiers().testFlag(Qt::ShiftModifier);
    if (altModifier && !controlModifier && !shiftModifier && (pKeyEvent->key() == Qt::Key_Left || pKeyEvent->key() == Qt::Key_Right)) {
      if (!isInsideDocumentationViewer(pObject)) {
        if (pKeyEvent->key() == Qt::Key_Left) {
          goBack();
        } else {
          goForward();
        }
        pEvent->accept();
        return true;
      }
    }
  }
  return QObject::eventFilter(pObject, pEvent);
}

/*!
 * \brief NavigationManager::isInsideDocumentationViewer
 * Returns true if the given object is part of the documentation viewer. The
 * documentation viewer is a web engine view and handles its own back/forward
 * navigation so the navigation history must not interfere with it.
 * \param pObject
 * \return
 */
bool NavigationManager::isInsideDocumentationViewer(QObject *pObject) const
{
  QObject *pCurrentObject = pObject;
  while (pCurrentObject) {
    if (qobject_cast<DocumentationViewer*>(pCurrentObject)) {
      return true;
    }
    pCurrentObject = pCurrentObject->parent();
  }
  return false;
}

/*!
 * \brief NavigationManager::recordNavigationPoint
 * Records the current cursor position of the given editor in the navigation
 * history. Used to implement the back/forward cursor navigation (mouse buttons
 * 4/5 and Alt+Left/Alt+Right). The history is shared between all editors so the
 * navigation works across different tabs, models and editors. A new point
 * truncates any forward points and the history is limited to
 * mNavigationHistorySize points.
 * \param pEditor
 */
void NavigationManager::recordNavigationPoint(PlainTextEdit *pEditor)
{
  NavigationPoint navigationPoint;
  navigationPoint.type = NavigationPoint::Type::Editor;
  navigationPoint.editor = pEditor;
  navigationPoint.position = pEditor->textCursor().position();
  recordNavigationPoint(navigationPoint);
}

/*!
 * \brief NavigationManager::recordNavigationPoint
 * Records a model widget in the given view in the navigation history. Used to
 * remember switches between the icon, diagram and text views so they can be
 * restored with the back/forward navigation.
 * \param pModelWidget - the model widget the navigation point belongs to.
 * \param viewType - the view of the model widget.
 */
void NavigationManager::recordNavigationPoint(ModelWidget *pModelWidget, StringHandler::ViewType viewType)
{
  NavigationPoint navigationPoint;
  navigationPoint.type = NavigationPoint::Type::View;
  navigationPoint.modelWidget = pModelWidget;
  navigationPoint.viewType = viewType;
  recordNavigationPoint(navigationPoint);
}

/*!
 * \brief NavigationManager::recordNavigationPoint
 * Records a perspective tab in the navigation history. Used to remember
 * switches between the welcome, modeling, plotting and debugging perspectives
 * so they can be restored with the back/forward navigation.
 * \param perspectiveIndex - the index of the perspective tab.
 */
void NavigationManager::recordNavigationPoint(int perspectiveIndex)
{
  NavigationPoint navigationPoint;
  navigationPoint.type = NavigationPoint::Type::Perspective;
  navigationPoint.perspectiveIndex = perspectiveIndex;
  recordNavigationPoint(navigationPoint);
}

/*!
 * \brief NavigationManager::recordNavigationPoint
 * Records a plot subwindow in the navigation history. Used to remember switches
 * between the plot windows so they can be restored with the back/forward
 * navigation.
 * \param pPlotSubWindow - the plot subwindow the navigation point belongs to.
 */
void NavigationManager::recordNavigationPoint(QMdiSubWindow *pPlotSubWindow)
{
  NavigationPoint navigationPoint;
  navigationPoint.type = NavigationPoint::Type::Plot;
  navigationPoint.plotSubWindow = pPlotSubWindow;
  recordNavigationPoint(navigationPoint);
}

/*!
 * \brief NavigationManager::recordNavigationPoint
 * Appends the given navigation point to the navigation history. A new point
 * truncates any forward points and the history is limited to
 * mNavigationHistorySize points.
 * \param navigationPoint - the navigation point to record.
 */
void NavigationManager::recordNavigationPoint(const NavigationPoint &navigationPoint)
{
  if (mNavigationActive) {
    return;
  }
  pruneStaleNavigationPoints();
  if (mNavigationPos >= 0 && mNavigationPos < mNavigationPoints.size()
      && navigationPointEquals(navigationPoint, mNavigationPoints.at(mNavigationPos))) {
    return;
  }
  if (mNavigationPos >= 0 && mNavigationPos < mNavigationPoints.size() - 1) {
    mNavigationPoints.resize(mNavigationPos + 1);
  }
  mNavigationPoints.append(navigationPoint);
  mNavigationPos = mNavigationPoints.size() - 1;
  while (mNavigationPoints.size() > mNavigationHistorySize) {
    mNavigationPoints.removeFirst();
    --mNavigationPos;
  }
  emit navigationChanged();
}

/*!
 * \brief NavigationManager::goBack
 * Moves to the previous navigation point, activating the tab of the editor the
 * point belongs to if needed. Returns true if the navigation happened.
 * \return
 */
bool NavigationManager::goBack()
{
  pruneStaleNavigationPoints();
  if (mNavigationPos <= 0) {
    return false;
  }
  --mNavigationPos;
  navigateToNavigationPoint(mNavigationPoints.at(mNavigationPos));
  emit navigationChanged();
  return true;
}

/*!
 * \brief NavigationManager::goForward
 * Moves to the next navigation point, activating the tab of the editor the
 * point belongs to if needed. Returns true if the navigation happened.
 * \return
 */
bool NavigationManager::goForward()
{
  pruneStaleNavigationPoints();
  if (mNavigationPos < 0 || mNavigationPos >= mNavigationPoints.size() - 1) {
    return false;
  }
  ++mNavigationPos;
  navigateToNavigationPoint(mNavigationPoints.at(mNavigationPos));
  emit navigationChanged();
  return true;
}

/*!
 * \brief NavigationManager::navigateToNavigationPoint
 * Restores the state described by the given navigation point without recording
 * a new navigation point. The function activates the perspective, the model
 * widget and/or the editor and moves the cursor as required.
 * \param navigationPoint - the navigation point to restore.
 */
void NavigationManager::navigateToNavigationPoint(const NavigationPoint &navigationPoint)
{
  mNavigationActive = true;
  MainWindow *pMainWindow = MainWindow::instance();
  switch (navigationPoint.type) {
    case NavigationPoint::Type::Editor: {
      PlainTextEdit *pEditor = navigationPoint.editor;
      if (!pEditor) {
        break;
      }
      ModelWidget *pModelWidget = pEditor->getBaseEditor()->getModelWidget();
      if (pModelWidget) {
        ModelWidgetContainer *pModelWidgetContainer = pMainWindow->getModelWidgetContainer();
        if (pModelWidgetContainer) {
          QMdiSubWindow *pSubWindow = pModelWidgetContainer->getMdiSubWindow(pModelWidget);
          if (pSubWindow) {
            pModelWidgetContainer->setActiveSubWindow(pSubWindow);
          }
        }
      }
      pEditor->moveToNavigationPoint(navigationPoint.position);
      pEditor->setFocus(Qt::ActiveWindowFocusReason);
      break;
    }
    case NavigationPoint::Type::View: {
      ModelWidget *pModelWidget = navigationPoint.modelWidget;
      if (!pModelWidget) {
        break;
      }
      // make sure the modeling perspective is active so the model widget is visible
      if (!pMainWindow->isModelingPerspectiveActive()) {
        pMainWindow->switchToModelingPerspectiveSlot();
      }
      ModelWidgetContainer *pModelWidgetContainer = pMainWindow->getModelWidgetContainer();
      if (pModelWidgetContainer) {
        QMdiSubWindow *pSubWindow = pModelWidgetContainer->getMdiSubWindow(pModelWidget);
        if (pSubWindow) {
          pModelWidgetContainer->setActiveSubWindow(pSubWindow);
        }
      }
      switch (navigationPoint.viewType) {
        case StringHandler::Icon:
          pModelWidget->getIconViewToolButton()->setChecked(true);
          break;
        case StringHandler::ModelicaText:
          pModelWidget->getTextViewToolButton()->setChecked(true);
          break;
        case StringHandler::Diagram:
        default:
          pModelWidget->getDiagramViewToolButton()->setChecked(true);
          break;
      }
      break;
    }
    case NavigationPoint::Type::Perspective:
      if (navigationPoint.perspectiveIndex >= 0) {
        pMainWindow->switchToPerspectiveTab(navigationPoint.perspectiveIndex);
      }
      break;
    case NavigationPoint::Type::Plot: {
      QMdiSubWindow *pSubWindow = navigationPoint.plotSubWindow;
      if (!pSubWindow) {
        break;
      }
      // make sure the plotting perspective is active so the plot window is visible
      if (!pMainWindow->isPlottingPerspectiveActive()) {
        pMainWindow->switchToPlottingPerspectiveSlot();
      }
      PlotWindowContainer *pPlotWindowContainer = pMainWindow->getPlotWindowContainer();
      if (pPlotWindowContainer) {
        pPlotWindowContainer->setActiveSubWindow(pSubWindow);
      }
      break;
    }
  }
  mNavigationActive = false;
}

/*!
 * \brief NavigationManager::clearNavigationHistory
 * Removes the navigation points of the given editor from the navigation history
 * but keeps a single point at the current cursor position. Used when the content
 * of the editor is replaced (e.g. the text view is regenerated with the diff API)
 * so stale points do not point to the old content while the current position
 * remains available for the back/forward navigation to the text view.
 * \param pEditor
 */
void NavigationManager::clearNavigationHistory(PlainTextEdit *pEditor)
{
  int currentPosition = pEditor->textCursor().position();
  int firstRemovedIndex = -1;
  bool currentPositionRemoved = false;
  for (int i = 0; i < mNavigationPoints.size(); ++i) {
    if (mNavigationPoints.at(i).editor == pEditor) {
      if (firstRemovedIndex == -1) {
        firstRemovedIndex = i;
      }
      if (i == mNavigationPos) {
        currentPositionRemoved = true;
      }
      mNavigationPoints.removeAt(i);
      if (i <= mNavigationPos) {
        --mNavigationPos;
      }
      --i;
    }
  }
  if (firstRemovedIndex >= 0) {
    NavigationPoint navigationPoint;
    navigationPoint.type = NavigationPoint::Type::Editor;
    navigationPoint.editor = pEditor;
    navigationPoint.position = currentPosition;
    mNavigationPoints.insert(firstRemovedIndex, navigationPoint);
    if (currentPositionRemoved) {
      mNavigationPos = firstRemovedIndex;
    } else if (firstRemovedIndex <= mNavigationPos) {
      ++mNavigationPos;
    }
  } else if (mNavigationPoints.isEmpty()) {
    mNavigationPos = -1;
  } else {
    mNavigationPos = qBound(0, mNavigationPos, mNavigationPoints.size() - 1);
  }
  emit navigationChanged();
}

/*!
 * \brief NavigationManager::navigationPointEquals
 * Returns true if the two navigation points represent the same navigation state.
 * \param navigationPoint1
 * \param navigationPoint2
 * \return
 */
bool NavigationManager::navigationPointEquals(const NavigationPoint &navigationPoint1, const NavigationPoint &navigationPoint2)
{
  if (navigationPoint1.type != navigationPoint2.type) {
    return false;
  }
  switch (navigationPoint1.type) {
    case NavigationPoint::Type::Editor:
      return navigationPoint1.editor == navigationPoint2.editor && navigationPoint1.position == navigationPoint2.position;
    case NavigationPoint::Type::View:
      return navigationPoint1.modelWidget == navigationPoint2.modelWidget && navigationPoint1.viewType == navigationPoint2.viewType;
    case NavigationPoint::Type::Perspective:
      return navigationPoint1.perspectiveIndex == navigationPoint2.perspectiveIndex;
    case NavigationPoint::Type::Plot:
      return navigationPoint1.plotSubWindow == navigationPoint2.plotSubWindow;
  }
  return false;
}

/*!
 * \brief NavigationManager::pruneStaleNavigationPoints
 * Removes the navigation points of editors or model widgets that have been
 * destroyed from the navigation history and keeps mNavigationPos pointing to
 * the same logical position.
 */
void NavigationManager::pruneStaleNavigationPoints()
{
  for (int i = 0; i < mNavigationPoints.size(); ++i) {
    NavigationPoint navigationPoint = mNavigationPoints.at(i);
    bool stale = false;
    switch (navigationPoint.type) {
      case NavigationPoint::Type::Editor:
        stale = navigationPoint.editor.isNull();
        break;
      case NavigationPoint::Type::View:
        stale = navigationPoint.modelWidget.isNull();
        break;
      case NavigationPoint::Type::Perspective:
        stale = false;
        break;
      case NavigationPoint::Type::Plot:
        stale = navigationPoint.plotSubWindow.isNull();
        break;
    }
    if (stale) {
      mNavigationPoints.removeAt(i);
      if (i <= mNavigationPos) {
        --mNavigationPos;
      }
      --i;
    }
  }
  if (mNavigationPoints.isEmpty()) {
    mNavigationPos = -1;
  } else {
    mNavigationPos = qBound(0, mNavigationPos, mNavigationPoints.size() - 1);
  }
}
