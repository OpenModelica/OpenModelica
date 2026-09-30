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

#ifndef CLASSDIAGRAMWIDGET_H
#define CLASSDIAGRAMWIDGET_H

// Needs QtWebEngine, see DocumentationWidget.h.
#if !defined(__EMSCRIPTEN__) && !defined(OM_OMEDIT_NO_WEBENGINE)
#define OM_OMEDIT_CLASS_DIAGRAM

#include <QWidget>
#include <QWebEngineView>
#include <QWebEnginePage>
#include <QWebEngineNewWindowRequest>

class Label;
class QSpinBox;
class QCheckBox;
class QComboBox;
class QToolButton;
class QDockWidget;
class QVBoxLayout;

/*!
 * \brief The page of the class diagram. Hands the links clicked in the diagram to
 * ClassDiagramWidget instead of following them.
 */
class ClassDiagramPage : public QWebEnginePage
{
  Q_OBJECT
public:
  ClassDiagramPage(QObject *pParent = nullptr);
protected:
  virtual bool acceptNavigationRequest(const QUrl &url, NavigationType type, bool isMainFrame) override;
signals:
  void linkClicked(const QUrl &url);
private slots:
  void newWindowRequested(QWebEngineNewWindowRequest &request);
};

class ClassDiagramWidget : public QWidget
{
  Q_OBJECT
public:
  ClassDiagramWidget(QWidget *pParent = nullptr);
  void showClassDiagram(const QString &className);
private:
  QString mClassName;
  QString mDiagram;
  Label *mpClassNameLabel;
  QSpinBox *mpDepthSpinBox;
  QCheckBox *mpShowModifiersCheckBox;
  QComboBox *mpLayoutComboBox;
  QToolButton *mpRefreshToolButton;
  QToolButton *mpSaveAsToolButton;
  QToolButton *mpDockToolButton;
  QWebEngineView *mpClassDiagramView;
  QVBoxLayout *mpMainLayout;
  QWebEngineView* createClassDiagramView();
  QString pageFileName() const;
  QString htmlPage(const QString &diagram) const;
  QDockWidget* dockWidget() const;
public slots:
  void toggleDocked();
  void floatingChanged(bool floating);
  void refresh();
  void saveAs();
  void openLink(const QUrl &url);
};

#endif // !defined(__EMSCRIPTEN__) && !defined(OM_OMEDIT_NO_WEBENGINE)

#endif // CLASSDIAGRAMWIDGET_H
