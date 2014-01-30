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
class TransformationsWidget;
class TVariablesTreeView;
class VariablePage;
class EquationPage;

class TVariablesTreeItem
{
public:
  TVariablesTreeItem(const QVector<QVariant> &tVariableItemData, TVariablesTreeItem *pParent = 0, bool isRootItem = false);
  ~TVariablesTreeItem();
  QList<TVariablesTreeItem*> getChildren() const {return mChildren;}
  bool isRootItem() {return mIsRootItem;}
  QString getVariableName() {return mVariableName;}
  QString getFilePath() {return mFilePath;}
  void insertChild(int position, TVariablesTreeItem *pVariablesTreeItem);
  TVariablesTreeItem *child(int row);
  void removeChildren();
  void removeChild(TVariablesTreeItem *pTVariablesTreeItem);
  int columnCount() const;
  QVariant data(int column, int role = Qt::DisplayRole) const;
  int row() const;
  TVariablesTreeItem *parent();
private:
  QList<TVariablesTreeItem*> mChildren;
  TVariablesTreeItem *mpParentTVariablesTreeItem;
  bool mIsRootItem;
  QString mVariableName;
  QString mDisplayVariableName;
  QString mComment;
  QString mFilePath;
  QString mLineNumber;
};

class TVariablesTreeModel : public QAbstractItemModel
{
  Q_OBJECT
public:
  TVariablesTreeModel(TVariablesTreeView *pTVariablesTreeView);
  TVariablesTreeItem* getRootTVariablesTreeItem() {return mpRootTVariablesTreeItem;}
  int columnCount(const QModelIndex &parent = QModelIndex()) const;
  int rowCount(const QModelIndex &parent = QModelIndex()) const;
  QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const;
  QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const;
  QModelIndex parent(const QModelIndex & index) const;
  QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;
  Qt::ItemFlags flags(const QModelIndex &index) const;
  TVariablesTreeItem* findTVariablesTreeItem(const QString &name, TVariablesTreeItem *root) const;
  QModelIndex tVariablesTreeItemIndex(const TVariablesTreeItem *pTVariablesTreeItem) const;
  QModelIndex tVariablesTreeItemIndexHelper(const TVariablesTreeItem *pTVariablesTreeItem, const TVariablesTreeItem *pParentTVariablesTreeItem,
                                           const QModelIndex &parentIndex) const;
  void insertTVariablesItems();
  void clearTVariablesTreeItems();
private:
  TVariablesTreeView *mpTVariablesTreeView;
  TVariablesTreeItem *mpRootTVariablesTreeItem;
  QHash<QString, QHash<QString,QString> > mScalarVariablesList;
};

class TVariableTreeProxyModel : public QSortFilterProxyModel
{
  Q_OBJECT
public:
  TVariableTreeProxyModel(QObject *parent = 0);
protected:
  bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;
};

class IntegerTreeWidgetItem : public QTreeWidgetItem
{
public:
  IntegerTreeWidgetItem(const QStringList &strings, QTreeWidget *pTreeWidget) : QTreeWidgetItem(strings) {mpTreeWidget = pTreeWidget;}
private:
  QTreeWidget *mpTreeWidget;
protected:
  virtual bool operator <(const QTreeWidgetItem &other) const
  {
    int column = mpTreeWidget ? mpTreeWidget->sortColumn() : 0;
    switch (column)
    {
      case 0:
        return text(column).toInt() < other.text(column).toInt();
      default:
        return text(column) < other.text(column);
    }
  }
};

class TVariablesTreeView : public QTreeView
{
  Q_OBJECT
public:
  TVariablesTreeView(TransformationsWidget *pTransformationsWidget);
  TransformationsWidget* getTransformationsWidget() {return mpTransformationsWidget;}
private:
  TransformationsWidget *mpTransformationsWidget;
};

class InfoBar;
class TSourceEditor;
class TransformationsWidget : public QWidget
{
  Q_OBJECT
public:
  TransformationsWidget(QString infoXMLFullFileName, MainWindow *pMainWindow);
  MainWindow* getMainWindow() {return mpMainWindow;}
  MyHandler* getInfoXMLFileHandler() {return mpInfoXMLFileHandler;}
  QTreeWidget* getEquationsTreeWidget() {return mpEquationsTreeWidget;}
  InfoBar* getTSourceEditorInfoBar() {return mpTSourceEditorInfoBar;}
  bool eventFilter(QObject *pObject, QEvent *pEvent);
  void loadTransformations();
  void fetchDefinedInEquations(OMVariable &variable);
  void fetchUsedInEquations(OMVariable &variable);
  void fetchOperations(OMVariable &variable);
  void fetchEquations();
  QTreeWidgetItem* findEquationTreeItem(int equationIndex);
  void fetchEquationData(int equationIndex);
  void fetchDefines(OMEquation &equation);
  void fetchDepends(OMEquation &equation);
  void fetchOperations(OMEquation &equation);
  void clearTreeWidgetItems(QTreeWidget *pTreeWidget);
private:
  MainWindow *mpMainWindow;
  QString mInfoXMLFullFileName;
  MyHandler *mpInfoXMLFileHandler;
  QLineEdit *mpFindVariablesTextBox;
  QComboBox *mpFindSyntaxComboBox;
  QCheckBox *mpFindCaseSensitiveCheckBox;
  QPushButton *mpExpandAllButton;
  QPushButton *mpCollapseAllButton;
  TVariablesTreeView *mpTVariablesTreeView;
  TVariablesTreeModel *mpTVariablesTreeModel;
  TVariableTreeProxyModel *mpTVariableTreeProxyModel;
  QTreeWidget *mpDefinedInEquationsTreeWidget;
  QTreeWidget *mpUsedInEquationsTreeWidget;
  QTreeWidget *mpVariableOperationsTreeWidget;
  QTreeWidget *mpEquationsTreeWidget;
  QTreeWidget *mpDefinesVariableTreeWidget;
  QTreeWidget *mpDependsVariableTreeWidget;
  QTreeWidget *mpEquationOperationsTreeWidget;
  Label *mpTSourceEditorFileLabel;
  InfoBar *mpTSourceEditorInfoBar;
  TSourceEditor *mpTSourceEditor;
public slots:
  void reloadTransformations();
  void findVariables();
  void fetchVariableData(const QModelIndex &index);
  void fetchEquationData(QTreeWidgetItem *pEquationTreeItem, int column);
};

#endif // TRANSFORMATIONSWIDGET_H
