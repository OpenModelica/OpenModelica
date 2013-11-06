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
#include "SimulationDialog.h"
#include "PlotWindow.h"

class MainWindow;
class SimulationOptions;
class VariablesTreeItem
{
public:
  VariablesTreeItem(const QVector<QVariant> &variableItemData, VariablesTreeItem *pParent = 0, bool isRootItem = false);
  ~VariablesTreeItem();
  QList<VariablesTreeItem*> getChildren() const {return mChildren;}
  bool isRootItem() {return mIsRootItem;}
  QString getFilePath() {return mFilePath;}
  QString getFileName() {return mFileName;}
  QString getPlotVariable();
  QString getVariableName() {return mVariableName;}
  bool isValueChanged() {return mValueChanged;}
  bool isChecked() const {return mChecked;}
  void setChecked(bool set) {mChecked = set;}
  bool isEditable() const {return mEditable;}
  void setEditable(bool set) {mEditable = set;}
  SimulationOptions getSimulationOptions() {return mSimulationOptions;}
  void setSimulationOptions(SimulationOptions simulationOptions) {mSimulationOptions = simulationOptions;}
  QIcon getVariableTreeItemIcon(QString name) const;
  void insertChild(int position, VariablesTreeItem *pVariablesTreeItem);
  VariablesTreeItem *child(int row);
  int childCount() const;
  void removeChildren();
  void removeChild(VariablesTreeItem *pVariablesTreeItem);
  int columnCount() const;
  bool setData(int column, const QVariant &value, int role = Qt::EditRole);
  QVariant data(int column, int role = Qt::DisplayRole) const;
  int row() const;
  VariablesTreeItem *parent();
private:
  QList<VariablesTreeItem*> mChildren;
  VariablesTreeItem *mpParentVariablesTreeItem;
  bool mIsRootItem;
  QString mFilePath;
  QString mFileName;
  QString mVariableName;
  QString mDisplayVariableName;
  QString mValue;
  bool mValueChanged;
  QString mDescription;
  QString mToolTip;
  bool mChecked;
  bool mEditable;
  SimulationOptions mSimulationOptions;
};

class VariablesTreeView;
class VariablesTreeModel : public QAbstractItemModel
{
  Q_OBJECT
public:
  VariablesTreeModel(VariablesTreeView *pVariablesTreeView = 0);
  VariablesTreeItem* getRootVariablesTreeItem() {return mpRootVariablesTreeItem;}
  int columnCount(const QModelIndex &parent = QModelIndex()) const;
  int rowCount(const QModelIndex &parent = QModelIndex()) const;
  QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const;
  QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const;
  QModelIndex parent(const QModelIndex & index) const;
  bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole);
  QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;
  Qt::ItemFlags flags(const QModelIndex &index) const;
  VariablesTreeItem* findVariablesTreeItem(const QString &name, VariablesTreeItem *root) const;
  QModelIndex variablesTreeItemIndex(const VariablesTreeItem *pVariablesTreeItem) const;
  QModelIndex VariablesTreeItemIndexHelper(const VariablesTreeItem *pVariablesTreeItem, const VariablesTreeItem *pParentVariablesTreeItem,
                                            const QModelIndex &parentIndex) const;
  void parseInitXml(QXmlStreamReader &xmlReader);
  QHash<QString, QString> parseScalarVariable(QXmlStreamReader &xmlReader);
  void insertVariablesItems(QString fileName, QString filePath, QStringList variablesList, SimulationOptions simulationOptions);
  QStringList makeVariableParts(QString variable);
  bool removeVariableTreeItem(QString variable);
  void unCheckVariables(VariablesTreeItem *pVariablelsTreeItem);
private:
  VariablesTreeView *mpVariablesTreeView;
  VariablesTreeItem *mpRootVariablesTreeItem;
  QHash<QString, QHash<QString,QString> > mScalarVariablesList;
  VariablesTreeItem* getVariablesTreeItem(const QModelIndex &index) const;
  QString getVariableValueAndDescription(QString variableToFind, bool *found, QString *description);
signals:
  void itemChecked(const QModelIndex &index);
  void variableTreeItemRemoved(QString variable);
public slots:
  void removeVariableTreeItem();
};

class VariableTreeProxyModel : public QSortFilterProxyModel
{
  Q_OBJECT
public:
  VariableTreeProxyModel(QObject *parent = 0);
  void clearfilter();
protected:
  bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;
};

class VariablesWidget;
class VariablesTreeView : public QTreeView
{
  Q_OBJECT
public:
  VariablesTreeView(VariablesWidget *pVariablesWidget);
  VariablesWidget* getVariablesWidget() {return mpVariablesWidget;}
private:
  VariablesWidget *mpVariablesWidget;
};

class VariablesWidget : public QWidget
{
  Q_OBJECT
public:
  VariablesWidget(MainWindow *pMainWindow);
  MainWindow* getMainWindow() {return mpMainWindow;}
  VariableTreeProxyModel* getVariableTreeProxyModel() {return mpVariableTreeProxyModel;}
  void insertVariablesItemsToTree(QString fileName, QString filePath, QStringList variablesList, SimulationOptions simulationOptions);
  void variablesUpdated();
  void updateVariablesTreeHelper(QMdiSubWindow *pSubWindow);
  bool eventFilter(QObject *pObject, QEvent *pEvent);
  void readVariablesAndUpdateXML(VariablesTreeItem *pVariablesTreeItem, QString outputFileName,
                                 QHash<QString, QHash<QString, QString> > *variables);
  void findVariableAndUpdateValue(QDomDocument xmlDocument, QHash<QString, QHash<QString, QString> > variables);
private:
  MainWindow *mpMainWindow;
  QLineEdit *mpFindVariablesTextBox;
  QComboBox *mpFindSyntaxComboBox;
  QCheckBox *mpFindCaseSensitiveCheckBox;
  QPushButton *mpExpandAllButton;
  QPushButton *mpCollapseAllButton;
  VariableTreeProxyModel *mpVariableTreeProxyModel;
  VariablesTreeModel *mpVariablesTreeModel;
  VariablesTreeView *mpVariablesTreeView;
  QList<QStringList> mPlotParametricVariables;
  QString mFileName;
  QMdiSubWindow *mpLastActiveSubWindow;
public slots:
  void plotVariables(const QModelIndex &index, OMPlot::PlotWindow *pPlotWindow = 0);
  void updateVariablesTree(QMdiSubWindow *pSubWindow);
  void showContextMenu(QPoint point);
  void findVariables();
  void reSimulate();
};

#endif // VARIABLESWIDGET_H
