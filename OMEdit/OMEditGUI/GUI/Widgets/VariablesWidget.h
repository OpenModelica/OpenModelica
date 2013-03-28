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

#ifndef VARIABLESWIDGET_H
#define VARIABLESWIDGET_H

#include "MainWindow.h"

class MainWindow;

class VariableTreeItem : public QTreeWidgetItem
{
public:
  VariableTreeItem(QString text, QString parentName, QString nameStructure, QString fileName, QString filePath, QString tooltip,
                   QTreeWidget *parent = 0);
  void setName(QString name);
  QString getName();
  void setParentName(QString parentName);
  QString getParentName();
  void setNameStructure(QString nameStructure);
  QString getNameStructure();
  void setFileName(QString fileName);
  QString getFileName();
  void setFilePath(QString filePath);
  QString getFilePath();
  QString getPlotVariable();
private:
  QString mName;
  QString mParentName;
  QString mNameStructure;
  QString mFileName;
  QString mFilePath;
};

class VariablesWidget;

class VariablesTreeWidget : public QTreeWidget
{
  Q_OBJECT
public:
  VariablesTreeWidget(VariablesWidget *pParent);
  VariableTreeItem* getVariableTreeItem(QString name);
  VariablesWidget* getVariablesWidget();
private:
  VariablesWidget *mpVariablesWidget;
};

class VariablesWidget : public QWidget
{
  Q_OBJECT
public:
  VariablesWidget(MainWindow *pParent);
  void createActions();
  void addPlotVariablestoTree(QString fileName, QString filePath, QList<QString> plotVariablesList);
  void addPlotVariableToTree(QString fileName, QString filePath, QString parentStructure, QString childName,
                             QString fullStructure = QString(), bool derivative = false);
  bool eventFilter(QObject *pObject, QEvent *pEvent);
  void unHideChildItems(QTreeWidgetItem *pItem);
private:
  MainWindow *mpMainWindow;
  QLineEdit *mpFindVariablesTextBox;
  VariablesTreeWidget *mpVariablesTreeWidget;
  QList<QStringList> mPlotParametricVariables;
  QString mFileName;
  VariableTreeItem *mSelectedPlotTreeItem;
  QAction *mpDeleteResultAction;
signals:
  void removeResultFile(VariableTreeItem *item);
public slots:
  void plotVariables(QTreeWidgetItem *item, int column);
  void updatePlotVariablesTree(QMdiSubWindow *window);
  void showContextMenu(QPoint point);
  void deleteVariablesTreeItem();
  void findVariables();
};

#endif // VARIABLESWIDGET_H
