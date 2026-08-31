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

#ifndef NAVIGATIONMANAGER_H
#define NAVIGATIONMANAGER_H

#include "Util/StringHandler.h"

#include <QObject>
#include <QPointer>
#include <QVector>

class ModelWidget;
class PlainTextEdit;
class QMdiSubWindow;

/*!
 * \class NavigationManager
 * \brief Manages the global back/forward navigation history.
 * The navigation history is shared between all editors, model widgets and
 * perspectives so the back/forward navigation (Alt+Left/Alt+Right and the
 * mouse buttons 4/5) works across different tabs, models and perspectives
 * no matter which widget currently has the focus.
 */
class NavigationManager : public QObject
{
  Q_OBJECT
public:
  static NavigationManager *instance();

  /*!
   * \brief The NavigationPoint struct
   * Stores the navigation target to jump to when navigating back and forward
   * through the navigation history. A point can either be an editor with a
   * cursor position, a model widget in a specific view or a perspective tab.
   */
  struct NavigationPoint {
    enum class Type {Editor, View, Perspective, Plot};
    Type type = Type::Editor;
    /*! The editor and cursor position used for Editor points. */
    QPointer<PlainTextEdit> editor;
    int position = -1;
    /*! The model widget and view type used for View points. */
    QPointer<ModelWidget> modelWidget;
    StringHandler::ViewType viewType = StringHandler::NoView;
    /*! The perspective tab index used for Perspective points. */
    int perspectiveIndex = -1;
    /*! The plot subwindow used for Plot points. */
    QPointer<QMdiSubWindow> plotSubWindow;
  };

  /*! Records the current cursor position of the given editor in the navigation history. */
  void recordNavigationPoint(PlainTextEdit *pEditor);
  /*! Records the given model widget in the given view in the navigation history. */
  void recordNavigationPoint(ModelWidget *pModelWidget, StringHandler::ViewType viewType);
  /*! Records a switch to the perspective tab with the given index in the navigation history. */
  void recordNavigationPoint(int perspectiveIndex);
  /*! Records the given plot subwindow in the navigation history. */
  void recordNavigationPoint(QMdiSubWindow *pPlotSubWindow);
  /*! Navigates to the previous navigation point. Returns true if the navigation happened. */
  bool goBack();
  /*! Navigates to the next navigation point. Returns true if the navigation happened. */
  bool goForward();
  /*! Removes the navigation points of the given editor from the navigation history but keeps a single point at the current cursor position. */
  void clearNavigationHistory(PlainTextEdit *pEditor);
  /*! Returns the navigation history points. */
  QVector<NavigationPoint> getNavigationPoints() const {return mNavigationPoints;}
  /*! Returns the current position in the navigation history. */
  int getNavigationPosition() const {return mNavigationPos;}
signals:
  /*! Emitted whenever the navigation history changes. */
  void navigationChanged();
protected:
  bool eventFilter(QObject *pObject, QEvent *pEvent) override;
private:
  NavigationManager(QObject *pParent = 0);
  static NavigationManager *mpInstance;
  void recordNavigationPoint(const NavigationPoint &navigationPoint);
  void navigateToNavigationPoint(const NavigationPoint &navigationPoint);
  void pruneStaleNavigationPoints();
  bool navigationPointEquals(const NavigationPoint &navigationPoint1, const NavigationPoint &navigationPoint2);
  bool isInsideDocumentationViewer(QObject *pObject) const;

  QVector<NavigationPoint> mNavigationPoints;
  int mNavigationPos = -1;
  bool mNavigationActive = false;
  const int mNavigationHistorySize = 50;
};

#endif // NAVIGATIONMANAGER_H
