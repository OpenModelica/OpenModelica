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

#ifndef TRANSFORMATIONSWIDGET_H
#define TRANSFORMATIONSWIDGET_H

#include <QTreeView>
#include <QSortFilterProxyModel>
#include <QTreeWidget>
#include <QComboBox>
#include <QSplitter>

#include "OMDumpXML.h"

class TransformationsWidget;
class TVariablesTreeView;
class TreeSearchFilters;
class Label;

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
  void insertTVariablesItems(QHashIterator<QString, OMVariable> variables);
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
    QString text1 = text(column);
    QString text2 = other.text(column);
    bool ok1=true,ok2=true;
    double d1,d2;
    // Check if both values are doubles, if so use number compare instead of lexical
    d1 = text1.remove("%").toDouble(&ok1);
    d2 = text2.remove("%").toDouble(&ok2);
    if (ok1 && ok2) {
      return d1 < d2;
    }
    return text1 < text2;
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

class EquationTreeWidget : public QTreeWidget
{
  Q_OBJECT
public:
  EquationTreeWidget(TransformationsWidget *pTransformationWidget);
private:
  TransformationsWidget *mpTransformationWidget;
};

class InfoBar;
class TransformationsEditor;
class TransformationsWidget : public QWidget
{
  Q_OBJECT
public:
  TransformationsWidget(QString infoJSONFullFileName, QWidget *pParent = 0);
  MyHandler* getInfoXMLFileHandler() {return mpInfoXMLFileHandler;}
  QTreeWidget* getEquationsTreeWidget() {return mpEquationsTreeWidget;}
  InfoBar* getTSourceEditorInfoBar() {return mpTSourceEditorInfoBar;}
  QSplitter* getVariablesNestedHorizontalSplitter() {return mpVariablesNestedHorizontalSplitter;}
  QSplitter* getVariablesNestedVerticalSplitter() {return mpVariablesNestedVerticalSplitter;}
  QSplitter* getVariablesHorizontalSplitter() {return mpVariablesHorizontalSplitter;}
  QSplitter* getEquationsNestedHorizontalSplitter() {return mpEquationsNestedHorizontalSplitter;}
  QSplitter* getEquationsNestedVerticalSplitter() {return mpEquationsNestedVerticalSplitter;}
  QSplitter* getEquationsHorizontalSplitter() {return mpEquationsHorizontalSplitter;}
  QSplitter* getTransformationsVerticalSplitter() {return mpTransformationsVerticalSplitter;}
  void loadTransformations();
  void fetchDefinedInEquations(const OMVariable &variable);
  void fetchUsedInEquations(const OMVariable &variable);
  void fetchOperations(const OMVariable &variable);
  void fetchEquations();
  void fetchNestedEquations(QTreeWidgetItem *pParentTreeWidgetItem, int index);
  QTreeWidgetItem* findEquationTreeItem(int equationIndex);
  void fetchEquationData(int equationIndex);
  void fetchDefines(OMEquation *equation);
  void fetchDepends(OMEquation *equation);
  void fetchOperations(OMEquation *equation, HtmlDiff htmlDiff);
  void clearTreeWidgetItems(QTreeWidget *pTreeWidget);
private:
  QString mInfoJSONFullFileName, mProfJSONFullFileName, mProfilingDataRealFileName;
  int profilingNumSteps;
  int mCurrentEquationIndex;
  MyHandler *mpInfoXMLFileHandler;
  TreeSearchFilters *mpTreeSearchFilters;
  TVariablesTreeView *mpTVariablesTreeView;
  TVariablesTreeModel *mpTVariablesTreeModel;
  TVariableTreeProxyModel *mpTVariableTreeProxyModel;
  EquationTreeWidget *mpDefinedInEquationsTreeWidget;
  EquationTreeWidget *mpUsedInEquationsTreeWidget;
  QTreeWidget *mpVariableOperationsTreeWidget;
  EquationTreeWidget *mpEquationsTreeWidget;
  QTreeWidget *mpDefinesVariableTreeWidget;
  QTreeWidget *mpDependsVariableTreeWidget;
  QComboBox *mpEquationDiffFilterComboBox;
  QTreeWidget *mpEquationOperationsTreeWidget;
  Label *mpTSourceEditorFileLabel;
  InfoBar *mpTSourceEditorInfoBar;
  TransformationsEditor *mpTransformationsEditor;
  QSplitter *mpVariablesNestedHorizontalSplitter;
  QSplitter *mpVariablesNestedVerticalSplitter;
  QSplitter *mpVariablesHorizontalSplitter;
  QSplitter *mpEquationsNestedHorizontalSplitter;
  QSplitter *mpEquationsNestedVerticalSplitter;
  QSplitter *mpEquationsHorizontalSplitter;
  QSplitter *mpTransformationsVerticalSplitter;
  QHash<QString,OMVariable> mVariables;
  QList<OMEquation*> mEquations;
  bool hasOperationsEnabled;

  void parseProfiling(QString fileName);
  QTreeWidgetItem* makeEquationTreeWidgetItem(int equationIndex, int allowChild);
public slots:
  void reloadTransformations();
  void findVariables();
  void fetchVariableData(const QModelIndex &index);
  void fetchEquationData(QTreeWidgetItem *pEquationTreeItem, int column);
  void filterEquationOperations(int index);
};

#endif // TRANSFORMATIONSWIDGET_H
