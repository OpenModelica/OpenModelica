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

#ifndef FINDUSAGEWIDGET_H
#define FINDUSAGEWIDGET_H

#include <QTreeView>
#include <QSortFilterProxyModel>

class ClassTreeItem
{
public:
  ClassTreeItem();
  ClassTreeItem(const QString &fileName, ClassTreeItem *pParentClassTreeItem);
  ClassTreeItem(const QString &name, const QString &className, int lineStart, int columnStart, int lineEnd, int columnEnd, ClassTreeItem *pParentClassTreeItem);
  ~ClassTreeItem();
  bool isRootItem() const {return mIsRootItem;}
  int childrenSize() const {return mChildren.size();}
  ClassTreeItem* child(int row) const;
  void insertChild(int position, ClassTreeItem *pClassTreeItem);
  void removeChildren();
  QVariant data(int column, int role = Qt::DisplayRole) const;
  int row() const;
  ClassTreeItem* parent() const {return mpParentClassTreeItem;}
  QString getText() const;
  QString getName() const {return mName;}
  QString getClassName() const {return mClassName;}
  int getLineStart() const {return mLineStart;}
private:
  QString mFileName;
  QString mName;
  QString mClassName;
  int mLineStart = 0;
  int mLineEnd = 0;
  int mColumnStart = 0;
  int mColumnEnd = 0;
  ClassTreeItem *mpParentClassTreeItem = nullptr;
  bool mIsRootItem = false;
  QList<ClassTreeItem*> mChildren;
};

class ElementWidget;
class ClassTreeProxyModel : public QSortFilterProxyModel
{
  Q_OBJECT
public:
  ClassTreeProxyModel(QWidget *pParent = nullptr);
private:
  ElementWidget *mpElementWidget;
protected:
  virtual bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
};

class ClassTreeModel : public QAbstractItemModel
{
  Q_OBJECT
public:
#if QT_VERSION >= QT_VERSION_CHECK(5, 13, 0)
  Q_DISABLE_COPY_MOVE(ClassTreeModel)
#endif
  ClassTreeModel(QWidget *pParent = nullptr);
  ~ClassTreeModel();
  ClassTreeItem* getRootClassTreeItem() {return mpRootClassTreeItem;}
  int columnCount(const QModelIndex &parent = QModelIndex()) const override;
  int rowCount(const QModelIndex &parent = QModelIndex()) const override;
  QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const override;
  QModelIndex parent(const QModelIndex &index) const override;
  QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
  Qt::ItemFlags flags(const QModelIndex &index) const override;
  QModelIndex ClassTreeItemIndex(const ClassTreeItem *pClassTreeItem) const;
  void removeClasses();
  int addClasses(const QJsonArray &jsonArray);
private:
  ClassTreeItem* mpRootClassTreeItem;
};

class ClassTreeView : public QTreeView
{
  Q_OBJECT
public:
  ClassTreeView(QWidget *pParent = nullptr);
public slots:
  void onDoubleClicked(const QModelIndex &index);
};

class LineEdit;
class Label;
class TreeSearchFilters;
class FindUsageWidget : QWidget
{
  Q_OBJECT
private:
  // the only class that is allowed to create and destroy
  friend class MainWindow;

  static void create();
  static void destroy();
  explicit FindUsageWidget(QWidget *pParent = nullptr);
  void updateMatchesFoundLabel(const QString &className, int matchesCount);

  static FindUsageWidget *mpInstance;
  LineEdit *mpFindUsageTextBox;
  ClassTreeModel *mpClassTreeModel;
  ClassTreeProxyModel *mpClassTreeProxyModel;
  ClassTreeView *mpClassTreeView;
  Label *mpMatchesFoundLabel;
  TreeSearchFilters *mpTreeSearchFilters;
public:
  static FindUsageWidget* instance() {return mpInstance;}
  ClassTreeProxyModel* getClassTreeProxyModel() {return mpClassTreeProxyModel;}
  void findUsageOfClass(const QString &className, const QString &scope = QString("AllLoadedClasses"), bool exactMatch = true);
private slots:
  void filterMatches();
};

#endif // FINDUSAGEWIDGET_H
