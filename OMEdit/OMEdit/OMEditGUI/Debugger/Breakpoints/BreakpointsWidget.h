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

#ifndef BREAKPOINTSWIDGET_H
#define BREAKPOINTSWIDGET_H

#include <QTreeView>
#include <QAction>

class BreakpointsTreeView;
class BreakpointsTreeModel;
class BreakpointMarker;
class BreakpointTreeItem;
class LibraryTreeItem;

class BreakpointsWidget : public QWidget
{
  Q_OBJECT
public:
  BreakpointsWidget(QWidget *pParent = 0);
  BreakpointsTreeView* getBreakpointsTreeView() {return mpBreakpointsTreeView;}
  BreakpointsTreeModel* getBreakpointsTreeModel() {return mpBreakpointsTreeModel;}
private:
  BreakpointsTreeView *mpBreakpointsTreeView;
  BreakpointsTreeModel *mpBreakpointsTreeModel;
};

class BreakpointsTreeView : public QTreeView
{
  Q_OBJECT
public:
  BreakpointsTreeView(BreakpointsWidget *pBreakPointsWidget);
  BreakpointsWidget* getBreakpointsWidget() {return mpBreakpointsWidget;}
private:
  BreakpointsWidget *mpBreakpointsWidget;
  QAction *mpGotoFileAction;
  QAction *mpAddBreakpointAction;
  QAction *mpEditBreakpointAction;
  QAction *mpDeleteBreakpointAction;
  QAction *mpDeleteAllBreakpointsAction;

  void createActions();
  BreakpointTreeItem* getSelectedBreakpointTreeItem();
  void deleteBreakpoint(BreakpointTreeItem *pBreakpointTreeItem);
private slots:
  void gotoFile();
  void addBreakpoint();
  void editBreakpoint();
  void deleteBreakpoint();
  void deleteAllBreakpoints();
  void showContextMenu(QPoint point);
  void breakPointDoubleClicked(const QModelIndex &index);
};

class BreakpointsTreeModel : public QAbstractItemModel
{
  Q_OBJECT
public:
  BreakpointsTreeModel(BreakpointsTreeView *pBreakpointsTreeView = 0);
  ~BreakpointsTreeModel();
  BreakpointsTreeView* getBreakpointsTreeView() {return mpBreakpointsTreeView;}
  BreakpointTreeItem* getRootBreakpointTreeItem() {return mpRootBreakpointTreeItem;}
  int columnCount(const QModelIndex &parent = QModelIndex()) const;
  int rowCount(const QModelIndex &parent = QModelIndex()) const;
  QVariant headerData(int section, Qt::Orientation orientation, int role = Qt::DisplayRole) const;
  QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const;
  QModelIndex parent(const QModelIndex & index) const;
  QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;
  BreakpointMarker* findBreakpointMarker(const QString &fileName, int lineNumber);
  BreakpointTreeItem* findBreakpointTreeItem(const QString &fileName, int lineNumber, BreakpointTreeItem *pRootBreakpointTreeItem) const;
  QModelIndex breakpointTreeItemIndex(const BreakpointTreeItem *pBreakpointTreeItem) const;
  QModelIndex breakpointTreeItemIndexHelper(const BreakpointTreeItem *pBreakpointTreeItem, const BreakpointTreeItem *pParentBreakpointTreeItem,
                                            const QModelIndex &parentIndex) const;
  void insertBreakpoint(BreakpointMarker *pBreakpointMarker, LibraryTreeItem *pLibraryTreeItem, BreakpointTreeItem *pParentBreakpointTreeItem);
  void updateBreakpoint(BreakpointMarker *pBreakpointMarker, int lineNumber);
  void updateBreakpoint(BreakpointTreeItem *pBreakpointTreeItem, QString filePath, int lineNumber, bool enabled, int ignoreCount,
                        QString condition);
  void removeBreakpoint(BreakpointMarker *pBreakpointMarker);
  void removeBreakpoint(BreakpointTreeItem *pBreakpointTreeItem);
private:
  BreakpointsTreeView *mpBreakpointsTreeView;
  BreakpointTreeItem *mpRootBreakpointTreeItem;
  QList<BreakpointMarker*> mBreakpointMarkersList;
};

class BreakpointTreeItem : public QObject
{
  Q_OBJECT
public:
  BreakpointTreeItem(const QVector<QVariant> &breakpointItemData, LibraryTreeItem *pLibraryTreeItem = 0, BreakpointTreeItem *pParent = 0);
  ~BreakpointTreeItem();
  QList<BreakpointTreeItem*> getChildren() const {return mChildren;}
  void setLibraryTreeItem(LibraryTreeItem *pLibraryTreeItem) {mpLibraryTreeItem = pLibraryTreeItem;}
  LibraryTreeItem* getLibraryTreeItem() {return mpLibraryTreeItem;}
  void setIsRootItem(bool isRootItem) {mIsRootItem = isRootItem;}
  bool isRootItem() {return mIsRootItem;}
  void setFilePath(QString filePath) {mFilePath = filePath;}
  QString getFilePath() {return mFilePath;}
  void setLineNumber(QString lineNumber) {mLineNumber = lineNumber;}
  QString getLineNumber() {return mLineNumber;}
  void setBreakpointID(QString breakpointId) {mBreakpointId = breakpointId;}
  QString getBreakpointID() {return mBreakpointId;}
  void setEnabled(bool enable) {mEnabled = enable;}
  bool isEnabled() const {return mEnabled;}
  void setIgnoreCount(int ignoreCount) {mIgnoreCount = ignoreCount;}
  int getIgnoreCount() {return mIgnoreCount;}
  void setCondition(QString condition) {mCondition = condition;}
  QString getCondition() {return mCondition;}
  QIcon getBreakpointTreeItemIcon() const;
  void insertChild(int position, BreakpointTreeItem *pBreakpointTreeItem);
  BreakpointTreeItem *child(int row);
  void removeChildren();
  void removeChild(BreakpointTreeItem *pBreakpointTreeItem);
  QVariant data(int column, int role = Qt::DisplayRole) const;
  int row() const;
  BreakpointTreeItem *parent() {return mpParentBreakpointTreeItem;}
private:
  QList<BreakpointTreeItem*> mChildren;
  LibraryTreeItem *mpLibraryTreeItem;
  BreakpointTreeItem *mpParentBreakpointTreeItem;
  bool mIsRootItem;
  QString mFilePath;
  QString mLineNumber;
  QString mBreakpointId;
  bool mEnabled;
  int mIgnoreCount;
  QString mCondition;
};

#endif // BREAKPOINTSWIDGET_H
