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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE. 
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
 * RCS: $Id$
 *
 */

#ifndef TRANSFORMATIONSWIDGET_H
#define TRANSFORMATIONSWIDGET_H

#include "MainWindow.h"
#include "OMDumpXML.h"

class MainWindow;
class VariablePage;
class EquationPage;
class TransformationsWidget : public QWidget
{
  Q_OBJECT
public:
  TransformationsWidget(MainWindow *pMainWindow);
  MainWindow* getMainWindow() {return mpMainWindow;}
  MyHandler* getInfoXMLFileHandler() {return mpInfoXMLFileHandler;}
  EquationPage* getEquationPage() {return mpEquationPage;}
  void showTransformations(QString fileName);
  void showInfoText(QString message);
private:
  MainWindow *mpMainWindow;
  MyHandler *mpInfoXMLFileHandler;
  Label *mpEquationIndexLabel;
  QLineEdit *mpEquationIndexTextBox;
  QPushButton *mpSearchEquationIndexButton;
  QToolButton *mpPreviousToolButton;
  QToolButton *mpNextToolButton;
  Label *mpInfoXMLFilePathLabel;
  QStackedWidget *mpPagesWidget;
  VariablePage *mpVariablePage;
  EquationPage *mpEquationPage;
  QPlainTextEdit *mpInfoTextBox;
public slots:
  void searchEquationIndex();
  void previousPage();
  void nextPage();
};

class VariablePage : public QWidget
{
  Q_OBJECT
public:
  VariablePage(TransformationsWidget *pTransformationsWidget);
  void initialize();
private:
  TransformationsWidget *mpTransformationsWidget;
  QTreeWidget *mpVariablesTreeWidget;
  QTreeWidget *mpTypesTreeWidget;
  QTreeWidget *mpOperationsTreeWidget;
  QTreeWidget *mpDefinedInTreeWidget;
  QTreeWidget *mpUsedInTreeWidget;
  void fetchTypes(OMVariable &variable);
  void fetchOperations(OMVariable &variable);
  void fetchDefinedInEquations(OMVariable &variable);
  void fetchUsedInEquations(OMVariable &variable);
public slots:
  void fetchVariableData(QTreeWidgetItem *pVariableTreeItem, int column);
  void variablesItemChanged(QTreeWidgetItem *current);
  void typesItemChanged(QTreeWidgetItem *current);
  void operationsItemChanged(QTreeWidgetItem *current);
  void definedInItemChanged(QTreeWidgetItem *current);
  void usedInItemChanged(QTreeWidgetItem *current);
  void showEquation(QTreeWidgetItem *pVariableTreeItem, int column);
};

class EquationPage : public QWidget
{
  Q_OBJECT
public:
  EquationPage(TransformationsWidget *pTransformationsWidget);
  void fetchEquationData(int equationIndex);
  void fetchDefines(OMEquation &equation);
  void fetchDepends(OMEquation &equation);
  void fetchOperations(OMEquation &equation);
private:
  TransformationsWidget *mpTransformationsWidget;
  QTreeWidget *mpDefinesTreeWidget;
  QTreeWidget *mpDependsTreeWidget;
  QTreeWidget *mpOperationsTreeWidget;
public slots:
  void definesItemChanged(QTreeWidgetItem *current);
  void dependsItemChanged(QTreeWidgetItem *current);
  void operationsItemChanged(QTreeWidgetItem *current);
};

#endif // TRANSFORMATIONSWIDGET_H
