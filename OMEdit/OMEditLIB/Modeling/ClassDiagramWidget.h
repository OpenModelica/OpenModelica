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

#include <QWidget>
#if defined(__EMSCRIPTEN__) || defined(OM_OMEDIT_NO_WEBENGINE)
#include "Modeling/qtwebengine_compat.h" // see DocumentationWidget.h
#else
#include <QWebEngineView>
#include <QWebEnginePage>
#include <QWebEngineNewWindowRequest>
#endif

class Label;
class QTabWidget;
class QSpinBox;
class QCheckBox;
class QComboBox;
class QToolButton;

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
  ClassDiagramWidget(const QString &className, QWidget *pParent = nullptr);
  ~ClassDiagramWidget();
  const QString &getClassName() const {return mClassName;}
private:
  QString mClassName;
  QString mDiagram;
  Label *mpClassNameLabel;
  QSpinBox *mpDepthSpinBox;
  QCheckBox *mpShowModifiersCheckBox;
  QComboBox *mpLayoutComboBox;
  QToolButton *mpRefreshToolButton;
  QToolButton *mpSaveAsToolButton;
  QWebEngineView *mpClassDiagramView;
  QString pageFileName() const;
  QString htmlPage(const QString &diagram) const;
public slots:
  void refresh();
  void saveAs();
  void openLink(const QUrl &url);
};

/*!
 * \brief The window of the class diagrams, a tab per class.
 */
class ClassDiagramWindow : public QWidget
{
  Q_OBJECT
public:
  ClassDiagramWindow();
  ~ClassDiagramWindow();
  ClassDiagramWidget* showClassDiagram(const QString &className);
protected:
  virtual void closeEvent(QCloseEvent *pEvent) override;
private:
  QTabWidget *mpTabWidget;
  void closeAllTabs();
private slots:
  void closeTab(int index);
  void currentTabChanged(int index);
};

#endif // CLASSDIAGRAMWIDGET_H
