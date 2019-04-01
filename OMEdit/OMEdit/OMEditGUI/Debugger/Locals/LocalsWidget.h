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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef LOCALSWIDGET_H
#define LOCALSWIDGET_H

#include <QVector>
#include <QSortFilterProxyModel>
#include <QTreeView>
#include <QPlainTextEdit>

class LocalsWidget;
class LocalsTreeModel;
class ModelicaValue;

class LocalsTreeItem : public QObject
{
  Q_OBJECT
public:
  LocalsTreeItem(const QVector<QVariant> &localItemData, LocalsTreeModel *pLocalsTreeModel, LocalsTreeItem *pLocalsTreeItem = 0);
  ~LocalsTreeItem();
  LocalsTreeModel* getLocalsTreeModel() {return mpLocalsTreeModel;}
  QList<LocalsTreeItem*> getChildren() const {return mChildren;}
  void setName(QString name) {mName = name;}
  QString getName() {return mName;}
  void setDisplayName(QString displayName) {mDisplayName = displayName;}
  QString getDisplayName() const {return mDisplayName;}
  void setNameStructure(QString nameStructure) {mNameStructure = nameStructure;}
  QString getNameStructure() {return mNameStructure;}
  void setType(QString type) {mType = type;}
  QString getType() {return mType;}
  void setDisplayType(QString displayType) {mDisplayType = displayType;}
  QString getDisplayType() const {return mDisplayType;}
  ModelicaValue* getModelicaValue() {return mpModelicaValue;}
  void setDisplayValue(QString displayValue) {mDisplayValue = displayValue;}
  QString getDisplayValue() const {return mDisplayValue;}
  bool valueChanged() const {return mValueChanged;}
  void setValueChanged(bool change) {mValueChanged = change;}
  bool isExpanded() const {return mExpanded;}
  void setExpanded(bool expanded) {mExpanded = expanded;}
  bool isCoreType();
  bool isCoreTypeExceptString();
  void insertChild(int position, LocalsTreeItem *pLocalsTreeItem);
  LocalsTreeItem *child(int row);
  void removeChildren();
  void removeChild(LocalsTreeItem *pLocalsTreeItem);
  int columnCount() const;
  QVariant data(int column, int role = Qt::DisplayRole) const;
  int row() const;
  LocalsTreeItem *parent();
  void retrieveType();
  void retrieveModelicaMetaType();
  void retrieveValue();
  void setModelicaMetaType(QString type);
  void setValue(QString value);
  void retrieveLocalChildren();
private:
  LocalsTreeModel *mpLocalsTreeModel;
  QList<LocalsTreeItem*> mChildren;
  LocalsTreeItem *mpParentLocalsTreeItem;
  QString mName;
  QString mDisplayName;
  QString mNameStructure;
  QString mType;
  QString mDisplayType;
  ModelicaValue *mpModelicaValue;
  QString mDisplayValue;
  bool mValueChanged;
  bool mExpanded;
};

class LocalsTreeModel : public QAbstractItemModel
{
  Q_OBJECT
public:
  LocalsTreeModel(LocalsWidget *pLocalsWidget);
  LocalsWidget* getLocalsWidget() {return mpLocalsWidget;}
  LocalsTreeItem* getRootLocalsTreeItem() {return mpRootLocalsTreeItem;}
  int columnCount(const QModelIndex &parent = QModelIndex()) const;
  int rowCount(const QModelIndex &parent = QModelIndex()) const;
  bool hasChildren(const QModelIndex &parent = QModelIndex()) const;
  bool canFetchMore(const QModelIndex &parent) const;
  QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const;
  QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const;
  QModelIndex parent(const QModelIndex & index) const;
  QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;
  LocalsTreeItem* findLocalsTreeItem(const QString &name, LocalsTreeItem *root) const;
  QModelIndex localsTreeItemIndex(const LocalsTreeItem *pLocalsTreeItem) const;
  QModelIndex localsTreeItemIndexHelper(const LocalsTreeItem *pLocalsTreeItem, const LocalsTreeItem *pParentLocalsTreeItem,
                                        const QModelIndex &parentIndex) const;
  void insertLocalItemData(const QVector<QVariant> &localItemData, LocalsTreeItem *pParentLocalsTreeItem);
  void insertLocalsList(const QList<QVector<QVariant> > &locals);
  void removeLocalItem(LocalsTreeItem *pLocalsTreeItem);
  void removeLocalItems();
  void updateLocalsTreeItem(LocalsTreeItem *pLocalsTreeItem);
private:
  LocalsWidget *mpLocalsWidget;
  LocalsTreeItem *mpRootLocalsTreeItem;
};

class LocalsTreeProxyModel : public QSortFilterProxyModel
{
  Q_OBJECT
public:
  LocalsTreeProxyModel(QObject *parent = 0);
protected:
  virtual bool lessThan(const QModelIndex &left, const QModelIndex &right) const;
};

class LocalsTreeView : public QTreeView
{
  Q_OBJECT
public:
  LocalsTreeView(LocalsWidget *pLocalsWidget);
  LocalsWidget* getLocalsWidget() {return mpLocalsWidget;}
private:
  LocalsWidget *mpLocalsWidget;
};

class LocalsWidget : public QWidget
{
  Q_OBJECT
public:
  LocalsWidget(QWidget *pParent = 0);
  LocalsTreeView* getLocalsTreeView() {return mpLocalsTreeView;}
  LocalsTreeModel* getLocalsTreeModel() {return mpLocalsTreeModel;}
  LocalsTreeProxyModel* getLocalsTreeProxyModel() {return mpLocalsTreeProxyModel;}
private:
  LocalsTreeView *mpLocalsTreeView;
  LocalsTreeModel *mpLocalsTreeModel;
  LocalsTreeProxyModel *mpLocalsTreeProxyModel;
  QPlainTextEdit *mpLocalValueViewer;
public slots:
  void localsTreeItemExpanded(QModelIndex index);
  void showLocalValue(QModelIndex currentIndex, QModelIndex previousIndex);
  void handleGDBProcessFinished();
};

#endif // LOCALSWIDGET_H
