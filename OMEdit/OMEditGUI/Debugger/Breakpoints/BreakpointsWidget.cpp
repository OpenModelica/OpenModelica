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

#include "BreakpointsWidget.h"
#include "Debugger/GDB/GDBAdapter.h"
#include "BreakpointDialog.h"
#include "Debugger/GDB/CommandFactory.h"
#include "Util/Helper.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Modeling/ItemDelegate.h"

#include <QGridLayout>
#include <QMenu>

/*!
 * \class BreakPointsWidget
 * \brief A widget containing BreakpointsTreeView.
 */
/*!
 * \brief BreakpointsWidget::BreakpointsWidget
 * \param pParent
 */
BreakpointsWidget::BreakpointsWidget(QWidget *pParent)
  : QWidget(pParent)
{
  /* Breakpoints Tree view */
  mpBreakpointsTreeView = new BreakpointsTreeView(this);
  mpBreakpointsTreeModel = new BreakpointsTreeModel(mpBreakpointsTreeView);
  mpBreakpointsTreeView->setModel(mpBreakpointsTreeModel);
  /* set layout */
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setSpacing(0);
  pMainLayout->addWidget(mpBreakpointsTreeView, 0, 0);
  setLayout(pMainLayout);
}

/*!
  \class BreakpointsTreeView
  \brief A tree view of breakpoints.
  */
/*!
  \param pBreakPointsWidget - pointer to BreakpointsWidget
  */
BreakpointsTreeView::BreakpointsTreeView(BreakpointsWidget *pBreakPointsWidget)
  : QTreeView(pBreakPointsWidget)
{
  mpBreakpointsWidget = pBreakPointsWidget;
  setItemDelegate(new ItemDelegate(this));
  setTextElideMode(Qt::ElideMiddle);
  setIndentation(0);
  setIconSize(QSize(15, 15));
  setExpandsOnDoubleClick(false);
  setContextMenuPolicy(Qt::CustomContextMenu);
  setUniformRowHeights(true);
  createActions();
  connect(this, SIGNAL(customContextMenuRequested(QPoint)), SLOT(showContextMenu(QPoint)));
  connect(this, SIGNAL(doubleClicked(QModelIndex)), SLOT(breakPointDoubleClicked(QModelIndex)));
}

/*!
  Defines the actions used by the BreakpointsTreeView context menu.
  */
void BreakpointsTreeView::createActions()
{
  /* Go to file action */
  mpGotoFileAction = new QAction(QIcon(":/Resources/icons/next.svg"), tr("Go to File"), this);
  mpGotoFileAction->setStatusTip(tr("Goto file location"));
  connect(mpGotoFileAction, SIGNAL(triggered()), SLOT(gotoFile()));
  /* Add breakpoint action */
  mpAddBreakpointAction = new QAction(QIcon(":/Resources/icons/add-icon.svg"), Helper::add, this);
  mpAddBreakpointAction->setStatusTip(tr("Adds a breakpoint"));
  connect(mpAddBreakpointAction, SIGNAL(triggered()), SLOT(addBreakpoint()));
  /* Edit breakpoint action */
  mpEditBreakpointAction = new QAction(QIcon(":/Resources/icons/edit-icon.svg"), Helper::edit, this);
  mpEditBreakpointAction->setStatusTip(tr("Edits a breakpoint"));
  connect(mpEditBreakpointAction, SIGNAL(triggered()), SLOT(editBreakpoint()));
  /* Remove breakpoint action */
  mpDeleteBreakpointAction = new QAction(QIcon(":/Resources/icons/delete.svg"), Helper::deleteStr, this);
  mpDeleteBreakpointAction->setStatusTip(tr("Deletes a breakpoint"));
  connect(mpDeleteBreakpointAction, SIGNAL(triggered()), SLOT(deleteBreakpoint()));
  /* remove all breakpoints action */
  mpDeleteAllBreakpointsAction = new QAction(tr("Delete All"), this);
  mpDeleteAllBreakpointsAction->setStatusTip(tr("Deletes all the breakpoints"));
  connect(mpDeleteAllBreakpointsAction, SIGNAL(triggered()), SLOT(deleteAllBreakpoints()));
}

/*!
  Returns the list of selecetd breakpoints.
  */
BreakpointTreeItem* BreakpointsTreeView::getSelectedBreakpointTreeItem() {
  const QModelIndexList modelIndexes = selectedIndexes();
  foreach (QModelIndex modelIndex, modelIndexes) {
    return static_cast<BreakpointTreeItem*>(modelIndex.internalPointer());
  }
  return 0;
}

/*!
  Slot activated when mpDeleteBreakpointAction triggered signal is raised.\n
  Deletes the breakpoint.
  */
void BreakpointsTreeView::deleteBreakpoint(BreakpointTreeItem *pBreakpointTreeItem) {
  BreakpointsTreeModel *pBreakpointsTreeModel = mpBreakpointsWidget->getBreakpointsTreeModel();
  if (pBreakpointTreeItem) {
    if (pBreakpointTreeItem->getLibraryTreeItem()) {
      ModelWidget *pModelWidget = pBreakpointTreeItem->getLibraryTreeItem()->getModelWidget();
      if (pModelWidget && pModelWidget->getEditor()) {
        QString fileName = pBreakpointTreeItem->getFilePath();
        int lineNumber = pBreakpointTreeItem->getLineNumber().toInt();
        BreakpointMarker *pBreakpointMarker = pBreakpointsTreeModel->findBreakpointMarker(fileName, lineNumber);
        if (pBreakpointMarker) {
          pModelWidget->getEditor()->getDocumentMarker()->removeMark(pBreakpointMarker);
          mpBreakpointsWidget->getBreakpointsTreeModel()->removeBreakpoint(pBreakpointMarker);
        }
      }
    } else {
      mpBreakpointsWidget->getBreakpointsTreeModel()->removeBreakpoint(pBreakpointTreeItem);
    }
  }
}

/*!
  Shows the breakpoint location in the editor.
  Slot activated when mpGotoFileAction triggered signal is raised.
  */
void BreakpointsTreeView::gotoFile() {
  BreakpointTreeItem *pBreakpointTreeItem = getSelectedBreakpointTreeItem();
  if (pBreakpointTreeItem && pBreakpointTreeItem->getLibraryTreeItem()) {
    ModelWidget *pModelWidget = pBreakpointTreeItem->getLibraryTreeItem()->getModelWidget();
    if (pModelWidget && pModelWidget->getEditor()) {
      pModelWidget->getModelWidgetContainer()->addModelWidget(pModelWidget, false);
      pModelWidget->getTextViewToolButton()->setChecked(true);
      pModelWidget->getEditor()->getPlainTextEdit()->goToLineNumber(pBreakpointTreeItem->getLineNumber().toInt());
    }
  }
}

/*!
  Adds a breakpoint.
  Slot activated when mpAddBreakpointAction triggered signal is raised.
  */
void BreakpointsTreeView::addBreakpoint()
{
  BreakpointDialog *pBreakpointDialog = new BreakpointDialog(0, mpBreakpointsWidget->getBreakpointsTreeModel());
  pBreakpointDialog->exec();
}

/*!
  Edits a breakpoint.
  Slot activated when mpEditBreakpointAction triggered signal is raised.
  */
void BreakpointsTreeView::editBreakpoint()
{
  BreakpointTreeItem *pBreakpointTreeItem = getSelectedBreakpointTreeItem();
  if (pBreakpointTreeItem) {
    BreakpointDialog *pBreakpointDialog = new BreakpointDialog(pBreakpointTreeItem, mpBreakpointsWidget->getBreakpointsTreeModel());
    pBreakpointDialog->exec();
  }
}

/*!
  Deletes a breakpoint.
  Slot activated when mpDeleteBreakpointAction triggered signal is raised.
  */
void BreakpointsTreeView::deleteBreakpoint()
{
  deleteBreakpoint(getSelectedBreakpointTreeItem());
}

/*!
  Delete all a breakpoint.
  Slot activated when mpDeleteAllBreakpointsAction triggered signal is raised.
  */
void BreakpointsTreeView::deleteAllBreakpoints()
{
  int i = 0;
  BreakpointTreeItem *pRootBreakpointTreeItem = mpBreakpointsWidget->getBreakpointsTreeModel()->getRootBreakpointTreeItem();

  while(i < pRootBreakpointTreeItem->getChildren().size())
  {
    deleteBreakpoint(pRootBreakpointTreeItem->child(i));
    i = 0;  //Restart iteration
  }
}

/*!
  Shows a context menu when user right click on the Breakpoints tree.
  Slot activated when BreakpointsTreeView::customContextMenuRequested() signal is raised.
  */
void BreakpointsTreeView::showContextMenu(QPoint point) {
  QMenu menu(this);
  menu.addAction(mpGotoFileAction);
  menu.addSeparator();
  menu.addAction(mpAddBreakpointAction);
  menu.addAction(mpEditBreakpointAction);
  menu.addAction(mpDeleteBreakpointAction);
  menu.addAction(mpDeleteAllBreakpointsAction);
  /* check if breakpoint is selected */
  QModelIndex index = indexAt(point);
  BreakpointTreeItem *pBreakpointTreeItem = static_cast<BreakpointTreeItem*>(index.internalPointer());
  if (pBreakpointTreeItem) {
    pBreakpointTreeItem->getLibraryTreeItem() ? mpGotoFileAction->setEnabled(true) : mpGotoFileAction->setEnabled(false);
    mpEditBreakpointAction->setEnabled(true);
    mpDeleteBreakpointAction->setEnabled(true);
  } else {
    mpGotoFileAction->setEnabled(false);
    mpEditBreakpointAction->setEnabled(false);
    mpDeleteBreakpointAction->setEnabled(false);
  }
  mpDeleteAllBreakpointsAction->setEnabled(model()->rowCount() > 0);

  int adjust = 24;
  point.setY(point.y() + adjust);
  menu.exec(mapToGlobal(point));
}

/*!
  Slot activated when BreakpointsTreeView::doubleClicked() signal is raised.
  */
void BreakpointsTreeView::breakPointDoubleClicked(const QModelIndex &index)
{
  Q_UNUSED(index);
  gotoFile();
}

/*!
  \class BreakpointsTreeModel
  \brief Contains the list of breakpoints.
  */
/*!
  \param pBreakpointsTreeView - pointer to BreakpointsTreeView
  */
BreakpointsTreeModel::BreakpointsTreeModel(BreakpointsTreeView *pBreakpointsTreeView)
  : QAbstractItemModel(pBreakpointsTreeView)
{
  mpBreakpointsTreeView = pBreakpointsTreeView;
  QVector<QVariant> headers;
  headers << Helper::file << Helper::line;
  mpRootBreakpointTreeItem = new BreakpointTreeItem(headers);
  mpRootBreakpointTreeItem->setIsRootItem(true);
}

/*!
  Deletes the breakpoints.
  */
BreakpointsTreeModel::~BreakpointsTreeModel()
{
  mpRootBreakpointTreeItem->removeChildren();
  delete mpRootBreakpointTreeItem;
}

int BreakpointsTreeModel::columnCount(const QModelIndex &parent) const
{
  Q_UNUSED(parent);
  return 2;
}

int BreakpointsTreeModel::rowCount(const QModelIndex &parent) const
{
  BreakpointTreeItem *pParentBreakpointTreeItem;
  if (parent.column() > 0)
    return 0;

  if (!parent.isValid())
    pParentBreakpointTreeItem = mpRootBreakpointTreeItem;
  else
    pParentBreakpointTreeItem = static_cast<BreakpointTreeItem*>(parent.internalPointer());
  return pParentBreakpointTreeItem->getChildren().size();
}

QVariant BreakpointsTreeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
  if (orientation == Qt::Horizontal && role == Qt::DisplayRole)
    return mpRootBreakpointTreeItem->data(section);
  return QVariant();
}

QModelIndex BreakpointsTreeModel::index(int row, int column, const QModelIndex &parent) const
{
  if (!hasIndex(row, column, parent))
    return QModelIndex();

  BreakpointTreeItem *pParentBreakpointTreeItem;

  if (!parent.isValid())
    pParentBreakpointTreeItem = mpRootBreakpointTreeItem;
  else
    pParentBreakpointTreeItem = static_cast<BreakpointTreeItem*>(parent.internalPointer());

  BreakpointTreeItem *pChildBreakpointTreeItem = pParentBreakpointTreeItem->child(row);
  if (pChildBreakpointTreeItem)
    return createIndex(row, column, pChildBreakpointTreeItem);
  else
    return QModelIndex();
}

QModelIndex BreakpointsTreeModel::parent(const QModelIndex &index) const
{
  if (!index.isValid())
    return QModelIndex();

  BreakpointTreeItem *pChildBreakpointTreeItem = static_cast<BreakpointTreeItem*>(index.internalPointer());
  BreakpointTreeItem *pParentBreakpointTreeItem = pChildBreakpointTreeItem->parent();
  if (pParentBreakpointTreeItem == mpRootBreakpointTreeItem)
    return QModelIndex();

  return createIndex(pParentBreakpointTreeItem->row(), 0, pParentBreakpointTreeItem);
}

QVariant BreakpointsTreeModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid())
    return QVariant();

  BreakpointTreeItem *pBreakpointTreeItem = static_cast<BreakpointTreeItem*>(index.internalPointer());
  return pBreakpointTreeItem->data(index.column(), role);
}

/*!
  Finds a BreakpointMarker.
  \return BreakpointMarker
  */
BreakpointMarker* BreakpointsTreeModel::findBreakpointMarker(const QString &fileName, int lineNumber)
{
  foreach (BreakpointMarker *pBreakpointMarker, mBreakpointMarkersList)
  {
    if ((pBreakpointMarker->filePath().compare(fileName) == 0) && (pBreakpointMarker->lineNumber() == lineNumber))
      return pBreakpointMarker;
  }
  return 0;
}

/*!
  Finds a BreakpointTreeItem
  \param fileName - the breakpoint fileName.
  \param lineNumber - the breakpoint line number.
  \param pRootBreakpointTreeItem - pointer to BreakpointTreeItem.
  */
BreakpointTreeItem* BreakpointsTreeModel::findBreakpointTreeItem(const QString &fileName, int lineNumber, BreakpointTreeItem *pRootBreakpointTreeItem) const
{
  QString ln = QString::number(lineNumber);
  if ((pRootBreakpointTreeItem->getFilePath().compare(fileName) == 0) && (pRootBreakpointTreeItem->getLineNumber().compare(ln) == 0))
    return pRootBreakpointTreeItem;
  for (int i = pRootBreakpointTreeItem->getChildren().size(); --i >= 0; )
    if (BreakpointTreeItem *pBreakpointTreeItem = findBreakpointTreeItem(fileName, lineNumber, pRootBreakpointTreeItem->getChildren().at(i)))
      return pBreakpointTreeItem;
  return 0;
}

/*!
  Finds the BreakpointTreeItem QModelIndex.
  \return QModelIndex
  */
QModelIndex BreakpointsTreeModel::breakpointTreeItemIndex(const BreakpointTreeItem *pBreakpointTreeItem) const
{
  return breakpointTreeItemIndexHelper(pBreakpointTreeItem, mpRootBreakpointTreeItem, QModelIndex());
}

/*!
  Helper function to find BreakpointTreeItem QModelIndex
  \see BreakpointsTreeModel::breakpointTreeItemIndex
  */
QModelIndex BreakpointsTreeModel::breakpointTreeItemIndexHelper(const BreakpointTreeItem *pBreakpointTreeItem,
                                                             const BreakpointTreeItem *pParentBreakpointTreeItem,
                                                             const QModelIndex &parentIndex) const
{
  if (pBreakpointTreeItem == pParentBreakpointTreeItem)
    return parentIndex;
  for (int i = pParentBreakpointTreeItem->getChildren().size(); --i >= 0; ) {
    const BreakpointTreeItem *childItem = pParentBreakpointTreeItem->getChildren().at(i);
    QModelIndex childIndex = index(i, 0, parentIndex);
    QModelIndex index = breakpointTreeItemIndexHelper(pBreakpointTreeItem, childItem, childIndex);
    if (index.isValid())
      return index;
  }
  return QModelIndex();
}

/*!
  Inserts a new breakpoint.\n
  Adds the BreakpointMarker to the list.\n
  Inserts the BreakpointTreeItem into BreakpointsTreeView.\n
  If the debugger is running then also inserts the breakpoint in GDB.\n
  \param pBreakpointMarker - pointer to BreakpointMarker
  \param pLibraryTreeItem - pointer LibraryTreeItem
  \param pParentBreakpointTreeItem - pointer BreakpointTreeItem
  */
void BreakpointsTreeModel::insertBreakpoint(BreakpointMarker *pBreakpointMarker, LibraryTreeItem *pLibraryTreeItem,
                                            BreakpointTreeItem *pParentBreakpointTreeItem)
{
  // Add the breakpoint to the list.
  mBreakpointMarkersList.append(pBreakpointMarker);
  // Create BreakpointTreeItem object and add it to the tree.
  QVector<QVariant> breakpointItemData;
  breakpointItemData << pBreakpointMarker->filePath() << QString::number(pBreakpointMarker->lineNumber());
  QModelIndex index = breakpointTreeItemIndex(pParentBreakpointTreeItem);
  BreakpointTreeItem *pBreakpointTreeItem = new BreakpointTreeItem(breakpointItemData, pLibraryTreeItem, pParentBreakpointTreeItem);
  pBreakpointTreeItem->setEnabled(pBreakpointMarker->isEnabled());
  pBreakpointTreeItem->setIgnoreCount(pBreakpointMarker->getIgnoreCount());
  pBreakpointTreeItem->setCondition(pBreakpointMarker->getCondition());
  int row = pParentBreakpointTreeItem->getChildren().size();
  beginInsertRows(index, row, row);
  pParentBreakpointTreeItem->insertChild(row, pBreakpointTreeItem);
  endInsertRows();
  // insert the breakpoint in gdb
  if (GDBAdapter::instance()->isGDBRunning()) {
    GDBAdapter::instance()->insertBreakpoint(pBreakpointTreeItem);
  }
}

/*!
  Updates a breakpoint.
  \param pBreakpointMarker - pointer to BreakpointMarker
  \param lineNumber - new line number for breakpoint.
  */
void BreakpointsTreeModel::updateBreakpoint(BreakpointMarker *pBreakpointMarker, int lineNumber)
{
  BreakpointTreeItem *pBreakpointTreeItem = findBreakpointTreeItem(pBreakpointMarker->filePath(), pBreakpointMarker->lineNumber(),
                                                                   mpRootBreakpointTreeItem);
  if (pBreakpointTreeItem) {
    updateBreakpoint(pBreakpointTreeItem, pBreakpointMarker->filePath(), lineNumber, pBreakpointMarker->isEnabled(),
                     pBreakpointMarker->getIgnoreCount(), pBreakpointMarker->getCondition());
  }
}

/*!
  Updates the breakpoint.\n
  If the debugger is running then enable or disable the breakpoint in GDB.\n
  \param pBreakpointTreeItem - pointer to BreakpointTreeItem
  \param filePath - the breakpoint file location.
  \param lineNumber - the breakpoint line number.
  \param enabled - the breakpoint enabled state.
  */
void BreakpointsTreeModel::updateBreakpoint(BreakpointTreeItem *pBreakpointTreeItem, QString filePath, int lineNumber, bool enabled,
                                            int ignoreCount, QString condition)
{
  // enable/disable the breakpoint in gdb.
  if (GDBAdapter::instance()->isGDBRunning() && !pBreakpointTreeItem->getBreakpointID().isEmpty()) {
    if (pBreakpointTreeItem->isEnabled() != enabled) {
      if (enabled) {
        GDBAdapter::instance()->postCommand(CommandFactory::breakEnable(QStringList() << pBreakpointTreeItem->getBreakpointID()),
                                            GDBAdapter::NonCriticalResponse);
      } else {
        GDBAdapter::instance()->postCommand(CommandFactory::breakDisable(QStringList() << pBreakpointTreeItem->getBreakpointID()),
                                            GDBAdapter::NonCriticalResponse);
      }
    }
    // add the ignore count in gdb
    if (pBreakpointTreeItem->getIgnoreCount() != ignoreCount) {
      GDBAdapter::instance()->postCommand(CommandFactory::breakAfter(pBreakpointTreeItem->getBreakpointID(), ignoreCount),
                                          GDBAdapter::NonCriticalResponse);
    }
    // add the condition in gdb
    if (pBreakpointTreeItem->getCondition().compare(condition) != 0) {
      GDBAdapter::instance()->postCommand(CommandFactory::breakCondition(pBreakpointTreeItem->getBreakpointID(), condition),
                                          GDBAdapter::NonCriticalResponse);
    }
  }
  // update the breakpoint in the tree.
  pBreakpointTreeItem->setFilePath(filePath);
  pBreakpointTreeItem->setLineNumber(QString::number(lineNumber));
  pBreakpointTreeItem->setEnabled(enabled);
  pBreakpointTreeItem->setIgnoreCount(ignoreCount);
  pBreakpointTreeItem->setCondition(condition);
  QModelIndex index = breakpointTreeItemIndex(pBreakpointTreeItem);
  emit dataChanged(index, index);
}

/*!
  Removes the breakpoint.\n
  Removes the BreakpointMarker from the list.\n
  \param pBreakpointMarker - pointer to BreakpointMarker
  */
void BreakpointsTreeModel::removeBreakpoint(BreakpointMarker *pBreakpointMarker)
{
  mBreakpointMarkersList.removeOne(pBreakpointMarker);
  removeBreakpoint(findBreakpointTreeItem(pBreakpointMarker->filePath(), pBreakpointMarker->lineNumber(), mpRootBreakpointTreeItem));
}

/*!
  Removes the breakpoint from the BreakpointsTreeView.\n
  If the debugger is running then deletes the breakpoint from GDB.\n
  \param pBreakpointTreeItem - pointer to BreakpointTreeItem
  */
void BreakpointsTreeModel::removeBreakpoint(BreakpointTreeItem *pBreakpointTreeItem)
{
  if (pBreakpointTreeItem) {
    // remove the breakpoint in gdb
    if (GDBAdapter::instance()->isGDBRunning() && !pBreakpointTreeItem->getBreakpointID().isEmpty()) {
      GDBAdapter::instance()->postCommand(CommandFactory::breakDelete(QStringList() << pBreakpointTreeItem->getBreakpointID()),
                                          GDBAdapter::NonCriticalResponse);
    }
    // remove the breakpoint from the tree.
    int row = pBreakpointTreeItem->row();
    beginRemoveRows(breakpointTreeItemIndex(pBreakpointTreeItem), row, row);
    pBreakpointTreeItem->removeChildren();
    BreakpointTreeItem *pParentBreakpointTreeItem = pBreakpointTreeItem->parent();
    pParentBreakpointTreeItem->removeChild(pBreakpointTreeItem);
    endRemoveRows();
  }
}

/*!
  \class BreakpointTreeItem
  \brief Contains the information about the breakpoint.
  */
/*!
  \param breakpointItemData - a list of items.\n
  0 -> filePath\n
  1 -> lineNumber
  */
BreakpointTreeItem::BreakpointTreeItem(const QVector<QVariant> &breakpointItemData, LibraryTreeItem *pLibraryTreeItem,
                                       BreakpointTreeItem *pParent)
  : mIsRootItem(false)
{
  mpLibraryTreeItem = pLibraryTreeItem;
  mpParentBreakpointTreeItem = pParent;
  mFilePath = breakpointItemData[0].toString();
  mLineNumber = breakpointItemData[1].toString();
  mBreakpointId = "";
  mEnabled = true;
  mIgnoreCount = 0;
  mCondition = "";
}

/*!
  Deletes the breakpoint and its children.
  */
BreakpointTreeItem::~BreakpointTreeItem()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

/*!
  Returns the enable or disable icon for breakpoint.
  */
QIcon BreakpointTreeItem::getBreakpointTreeItemIcon() const
{
  return isEnabled() ? QIcon(":/Resources/icons/breakpoint_enabled.svg") : QIcon(":/Resources/icons/breakpoint_disabled.svg");
}

void BreakpointTreeItem::insertChild(int position, BreakpointTreeItem *pBreakpointTreeItem)
{
  mChildren.insert(position, pBreakpointTreeItem);
}

BreakpointTreeItem* BreakpointTreeItem::child(int row)
{
  return mChildren.value(row);
}

void BreakpointTreeItem::removeChildren()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

void BreakpointTreeItem::removeChild(BreakpointTreeItem *pBreakpointTreeItem)
{
  mChildren.removeOne(pBreakpointTreeItem);
}

QVariant BreakpointTreeItem::data(int column, int role) const
{
  switch (column)
  {
    case 0:
      switch (role)
      {
        case Qt::DisplayRole:
          return mLineNumber;
        case Qt::DecorationRole:
          return mIsRootItem ? QIcon() : getBreakpointTreeItemIcon();
        default:
          return QVariant();
      }
    case 1:
      switch (role)
      {
        case Qt::DisplayRole:
          return mFilePath;
        default:
          return QVariant();
      }
    default:
      return QVariant();
  }
}

int BreakpointTreeItem::row() const
{
  if (mpParentBreakpointTreeItem)
    return mpParentBreakpointTreeItem->mChildren.indexOf(const_cast<BreakpointTreeItem*>(this));

  return 0;
}
