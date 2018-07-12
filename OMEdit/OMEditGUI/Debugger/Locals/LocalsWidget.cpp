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

#include "Debugger/Locals/LocalsWidget.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ItemDelegate.h"
#include "Debugger/GDB/GDBAdapter.h"
#include "Debugger/StackFrames/StackFramesWidget.h"
#include "Debugger/Locals/ModelicaValue.h"
#include "Debugger/GDB/CommandFactory.h"
#include "Util/Helper.h"

#include <QSplitter>
#include <QGridLayout>
#include <QHBoxLayout>

/*!
 * \class LocalsTreeItem
 * \brief Contains the information about the local variable.
 */
/*!
 * \brief LocalsTreeItem::LocalsTreeItem
 * \param localItemData - a list of items.\n
 * 0 -> name\n
 * 1 -> displayName\n
 * 2 -> type\n
 * 3 -> value
 * \param localItemData
 * \param pLocalsTreeModel
 * \param pLocalsTreeItem
 */
LocalsTreeItem::LocalsTreeItem(const QVector<QVariant> &localItemData, LocalsTreeModel *pLocalsTreeModel, LocalsTreeItem *pLocalsTreeItem)
  : QObject(pLocalsTreeModel)
{
  mpLocalsTreeModel = pLocalsTreeModel;
  mpParentLocalsTreeItem = pLocalsTreeItem;
  mpModelicaValue = 0;
  setName(localItemData[0].toString());
  setDisplayName(localItemData[1].toString());
  setNameStructure("");
  setType(localItemData[2].toString());
  /* if the item is a root item then its just a header */
  if (!mpParentLocalsTreeItem) {
    setDisplayName(getName());
    setDisplayType(getType());
    setDisplayValue(localItemData[3].toString());
  } else if (mpParentLocalsTreeItem == mpLocalsTreeModel->getRootLocalsTreeItem()) {
    /* if the item is a top level item then we need to fetch the type and value. */
    setDisplayType("");
    retrieveType();
    setDisplayValue("");
    retrieveValue();
  } else {
    /* child node */
    setDisplayName(getDisplayName());
    setDisplayType(getType());
    setDisplayValue("");
    retrieveValue();
  }
  setValueChanged(false);
  setExpanded(false);
}

LocalsTreeItem::~LocalsTreeItem()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

/*!
 * \brief LocalsTreeItem::isCoreType
 * Returns true if is core type.
 * \return
 */
bool LocalsTreeItem::isCoreType()
{
  if ((getDisplayType().compare(Helper::STRING) == 0) ||
      (getDisplayType().compare(Helper::BOOLEAN) == 0) ||
      (getDisplayType().compare(Helper::INTEGER) == 0) ||
      (getDisplayType().compare(Helper::REAL) == 0)) {
    return true;
  } else {
    return false;
  }
}

/*!
 * \brief LocalsTreeItem::isCoreTypeExceptString
 * Returns true if is core type except STRING.
 * \return
 */
bool LocalsTreeItem::isCoreTypeExceptString()
{
  if ((getDisplayType().compare(Helper::BOOLEAN) == 0) ||
      (getDisplayType().compare(Helper::INTEGER) == 0) ||
      (getDisplayType().compare(Helper::REAL) == 0)) {
    return true;
  } else {
    return false;
  }
}

void LocalsTreeItem::insertChild(int position, LocalsTreeItem *pLocalsTreeItem)
{
  mChildren.insert(position, pLocalsTreeItem);
}

LocalsTreeItem* LocalsTreeItem::child(int row)
{
  return mChildren.value(row);
}

void LocalsTreeItem::removeChildren()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

void LocalsTreeItem::removeChild(LocalsTreeItem *pLocalsTreeItem)
{
  mChildren.removeOne(pLocalsTreeItem);
}

int LocalsTreeItem::columnCount() const
{
  return 3;
}

QVariant LocalsTreeItem::data(int column, int role) const
{
  switch (role) {
    case Qt::DisplayRole:
      switch (column) {
        case 0:
          return getDisplayName();
        case 1:
          return getDisplayType();
        case 2:
          // display the string type with quotes.
          if (getDisplayType().compare(Helper::STRING) == 0) {
            return QString("\"%1\"").arg(getDisplayValue());
          } else {
            return getDisplayValue();
          }
        default:
          break;
      }
    case Qt::ToolTipRole:
      switch (column) {
        case 0:
          return getDisplayName();
        case 1:
          return getDisplayType();
        case 2:
          return getDisplayValue();
        default:
          break;
      }
    case Qt::BackgroundRole:
      return valueChanged() ? QColor(Qt::yellow) : QVariant();
    default:
      break;
  }
  return QVariant();
}

int LocalsTreeItem::row() const
{
  if (mpParentLocalsTreeItem) {
    return mpParentLocalsTreeItem->mChildren.indexOf(const_cast<LocalsTreeItem*>(this));
  }
  return 0;
}

LocalsTreeItem* LocalsTreeItem::parent()
{
  return mpParentLocalsTreeItem;
}

void LocalsTreeItem::retrieveType()
{
  if ((getType().compare(Helper::MODELICA_METATYPE) == 0) || (getType().compare(Helper::MODELICA_STRING) == 0)) {
    retrieveModelicaMetaType();
  } else if (getType().compare(Helper::MODELICA_BOOLEAN) == 0) {
    setDisplayType("Boolean");
  } else if (getType().compare(Helper::MODELICA_INETGER) == 0) {
    setDisplayType("Integer");
  } else if (getType().compare(Helper::MODELICA_REAL) == 0) {
    setDisplayType("Real");
  } else {
    setDisplayType(getType());
  }
}

void LocalsTreeItem::retrieveModelicaMetaType()
{
  if (getDisplayType().isEmpty() || (getDisplayType().compare(Helper::VALUE_OPTIMIZED_OUT) == 0)
      || (getDisplayType().compare(Helper::REPLACEABLE_TYPE_ANY) == 0)) {
    GDBAdapter *pGDBAdapter = GDBAdapter::instance();
    StackFramesWidget *pStackFramesWidget = MainWindow::instance()->getStackFramesWidget();
    if (parent() && parent()->getModelicaValue() && qobject_cast<ModelicaRecordValue*>(parent()->getModelicaValue())) {
      pGDBAdapter->postCommand(CommandFactory::getTypeOfAny(pStackFramesWidget->getSelectedThread(), pStackFramesWidget->getSelectedFrame(),
                                                            getName(), true),
                               GDBAdapter::BlockUntilResponse, this, &GDBAdapter::getTypeOfAnyCB);
    } else {
      pGDBAdapter->postCommand(CommandFactory::getTypeOfAny(pStackFramesWidget->getSelectedThread(), pStackFramesWidget->getSelectedFrame(),
                                                            getName(), false),
                               GDBAdapter::BlockUntilResponse, this, &GDBAdapter::getTypeOfAnyCB);
    }
  } else {
    retrieveValue();
  }
}

/*!
 * \brief LocalsTreeItem::retrieveValue
 * Gets the value of the LocalsTreeItem using CommandFactory::anyString
 */
void LocalsTreeItem::retrieveValue()
{
  GDBAdapter *pGDBAdapter = GDBAdapter::instance();
  StackFramesWidget *pStackFramesWidget = MainWindow::instance()->getStackFramesWidget();
  if (isCoreTypeExceptString()) {
    pGDBAdapter->postCommand(CommandFactory::dataEvaluateExpression(pStackFramesWidget->getSelectedThread(),
                                                                    pStackFramesWidget->getSelectedFrame(), getName()),
                             GDBAdapter::BlockUntilResponse, this, &GDBAdapter::dataEvaluateExpressionCB);
  } else if (isCoreType()) {
    pGDBAdapter->postCommand(CommandFactory::anyString(pStackFramesWidget->getSelectedThread(), pStackFramesWidget->getSelectedFrame(),
                                                       getName()), GDBAdapter::BlockUntilResponse, this, &GDBAdapter::anyStringCB);
  } else {
    setValue(getDisplayType());
  }
}

/*!
 * \brief LocalsTreeItem::setModelicaMetaType
 * Sets the type of the LocalsTreeItem and sends the command to retireve value.
 * \param type
 */
void LocalsTreeItem::setModelicaMetaType(QString type)
{
  setDisplayType(type);
  if (getDisplayType().compare(Helper::REPLACEABLE_TYPE_ANY) == 0) {
    setDisplayValue(tr("<uninitialized variable>"));
  } else {
    retrieveValue();
  }
  /* update the view with new values of LocalsTreeItem */
  mpLocalsTreeModel->updateLocalsTreeItem(this);
}

void LocalsTreeItem::setValue(QString value)
{
  if (mpModelicaValue) {
    QString previousValue = mpModelicaValue->getValueString();
    mpModelicaValue->setValue(value);
    setDisplayValue(mpModelicaValue->getValueString());
    /* if value is changed then set the value changed flag. */
    if (getDisplayValue().compare(previousValue) == 0) {
      setValueChanged(false);
    } else {
      setValueChanged(true);
    }
  } else if (isCoreType()) {
    mpModelicaValue = new ModelicaCoreValue(this);
    mpModelicaValue->setValue(value);
    setDisplayValue(mpModelicaValue->getValueString());
  } else if (getDisplayType().startsWith(Helper::RECORD)) {
    mpModelicaValue = new ModelicaRecordValue(this);
    mpModelicaValue->setValue(value);
    setDisplayValue(mpModelicaValue->getValueString());
    /* get the record elements size */
    mpModelicaValue->retrieveChildrenSize();
  } else if (getDisplayType().startsWith(Helper::LIST)) {
    mpModelicaValue = new ModelicaListValue(this);
    setDisplayValue(mpModelicaValue->getValueString());
    /* get the list items size */
    mpModelicaValue->retrieveChildrenSize();
  } else if (getDisplayType().startsWith(Helper::OPTION)) {
    mpModelicaValue = new ModelicaOptionValue(this);
    setDisplayValue(mpModelicaValue->getValueString());
    /* get the option item elements size */
    mpModelicaValue->retrieveChildrenSize();
  } else if (getDisplayType().startsWith(Helper::TUPLE)) {
    mpModelicaValue = new ModelicaTupleValue(this);
    setDisplayValue(mpModelicaValue->getValueString());
    /* get the tuple elements size */
    mpModelicaValue->retrieveChildrenSize();
  } else if (getDisplayType().startsWith(Helper::ARRAY)) {
    mpModelicaValue = new MetaModelicaArrayValue(this);
    setDisplayValue(mpModelicaValue->getValueString());
    /* get the tuple elements size */
    mpModelicaValue->retrieveChildrenSize();
  }
  /* update the view with new values of LocalsTreeItem */
  mpLocalsTreeModel->updateLocalsTreeItem(this);
}

void LocalsTreeItem::retrieveLocalChildren()
{
  if (!mpModelicaValue) {
    return;
  }
  mpModelicaValue->retrieveChildren();
}

LocalsTreeModel::LocalsTreeModel(LocalsWidget *pLocalsWidget)
  : QAbstractItemModel(pLocalsWidget)
{
  mpLocalsWidget = pLocalsWidget;
  QVector<QVariant> headers;
  headers << tr("Name") << "" << tr("Type") << tr("Value");
  mpRootLocalsTreeItem = new LocalsTreeItem(headers, this, 0);
}

int LocalsTreeModel::columnCount(const QModelIndex &parent) const
{
  if (parent.isValid()) {
    return static_cast<LocalsTreeItem*>(parent.internalPointer())->columnCount();
  } else {
    return mpRootLocalsTreeItem->columnCount();
  }
}

int LocalsTreeModel::rowCount(const QModelIndex &parent) const
{
  LocalsTreeItem *pParentLocalsTreeViewItem;
  if (parent.column() > 0) {
    return 0;
  }

  if (!parent.isValid()) {
    pParentLocalsTreeViewItem = mpRootLocalsTreeItem;
  } else {
    pParentLocalsTreeViewItem = static_cast<LocalsTreeItem*>(parent.internalPointer());
  }
  return pParentLocalsTreeViewItem->getChildren().size();
}

bool LocalsTreeModel::hasChildren(const QModelIndex &parent) const
{
  LocalsTreeItem *pParentLocalsTreeViewItem = static_cast<LocalsTreeItem*>(parent.internalPointer());
  if (!pParentLocalsTreeViewItem) {
    return true;
  }
  return pParentLocalsTreeViewItem->getModelicaValue() && pParentLocalsTreeViewItem->getModelicaValue()->hasChildren();
}

bool LocalsTreeModel::canFetchMore(const QModelIndex &parent) const
{
  Q_UNUSED(parent);
  return true;
//  LocalsTreeItem *pParentLocalsTreeViewItem = static_cast<LocalsTreeItem*>(parent.internalPointer());
//  return parent.isValid() && !m_fetchTriggered.contains(item->iname);
}

QVariant LocalsTreeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
  if (orientation == Qt::Horizontal && role == Qt::DisplayRole) {
    return mpRootLocalsTreeItem->data(section);
  }
  return QVariant();
}

QModelIndex LocalsTreeModel::index(int row, int column, const QModelIndex &parent) const
{
  if (!hasIndex(row, column, parent)) {
    return QModelIndex();
  }

  LocalsTreeItem *pParentLocalsTreeViewItem;
  if (!parent.isValid()) {
    pParentLocalsTreeViewItem = mpRootLocalsTreeItem;
  } else {
    pParentLocalsTreeViewItem = static_cast<LocalsTreeItem*>(parent.internalPointer());
  }

  LocalsTreeItem *pChildLocalsTreeViewItem = pParentLocalsTreeViewItem->child(row);
  if (pChildLocalsTreeViewItem) {
    return createIndex(row, column, pChildLocalsTreeViewItem);
  } else {
    return QModelIndex();
  }
}

QModelIndex LocalsTreeModel::parent(const QModelIndex &index) const
{
  if (!index.isValid()) {
    return QModelIndex();
  }

  LocalsTreeItem *pChildLocalsTreeViewItem = static_cast<LocalsTreeItem*>(index.internalPointer());
  LocalsTreeItem *pParentLocalsTreeViewItem = pChildLocalsTreeViewItem->parent();
  if (pParentLocalsTreeViewItem == mpRootLocalsTreeItem) {
    return QModelIndex();
  }

  return createIndex(pParentLocalsTreeViewItem->row(), 0, pParentLocalsTreeViewItem);
}

QVariant LocalsTreeModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid()) {
    return QVariant();
  }

  LocalsTreeItem *pLocalsTreeViewItem = static_cast<LocalsTreeItem*>(index.internalPointer());
  return pLocalsTreeViewItem->data(index.column(), role);
}

LocalsTreeItem* LocalsTreeModel::findLocalsTreeItem(const QString &name, LocalsTreeItem *root) const
{
  if (root->getNameStructure() == name) {
    return root;
  }
  for (int i = root->getChildren().size(); --i >= 0;) {
    if (LocalsTreeItem *item = findLocalsTreeItem(name, root->getChildren().at(i))) {
      return item;
    }
  }
  return 0;
}

QModelIndex LocalsTreeModel::localsTreeItemIndex(const LocalsTreeItem *pLocalsTreeItem) const
{
  return localsTreeItemIndexHelper(pLocalsTreeItem, mpRootLocalsTreeItem, QModelIndex());
}

QModelIndex LocalsTreeModel::localsTreeItemIndexHelper(const LocalsTreeItem *pLocalsTreeItem, const LocalsTreeItem *pParentLocalsTreeItem,
                                                       const QModelIndex &parentIndex) const
{
  if (pLocalsTreeItem == pParentLocalsTreeItem) {
    return parentIndex;
  }
  for (int i = pParentLocalsTreeItem->getChildren().size(); --i >= 0; ) {
    const LocalsTreeItem *childItem = pParentLocalsTreeItem->getChildren().at(i);
    QModelIndex childIndex = index(i, 0, parentIndex);
    QModelIndex index = localsTreeItemIndexHelper(pLocalsTreeItem, childItem, childIndex);
    if (index.isValid()) {
      return index;
    }
  }
  return QModelIndex();
}

void LocalsTreeModel::insertLocalItemData(const QVector<QVariant> &localItemData, LocalsTreeItem *pParentLocalsTreeItem)
{
  QString nameStructure;
  /* construct the item name structure. */
  if (mpRootLocalsTreeItem == pParentLocalsTreeItem) {
    nameStructure = QString("%1.%2").arg(pParentLocalsTreeItem->getNameStructure()).arg(localItemData[0].toString());
  } else {
    nameStructure = QString("%1.%2%3").arg(pParentLocalsTreeItem->getNameStructure()).arg(localItemData[0].toString()).arg(localItemData[1].toString());
  }
  /* find the item */
  LocalsTreeItem *pLocalsTreeItem = findLocalsTreeItem(nameStructure, pParentLocalsTreeItem);
  if (pLocalsTreeItem) {
    pLocalsTreeItem->retrieveModelicaMetaType();
  } else {
    QModelIndex index = localsTreeItemIndex(pParentLocalsTreeItem);
    pLocalsTreeItem = new LocalsTreeItem(localItemData, this, pParentLocalsTreeItem);
    pLocalsTreeItem->setNameStructure(nameStructure);
    int row = pParentLocalsTreeItem->getChildren().size();
    beginInsertRows(index, row, row);
    pParentLocalsTreeItem->insertChild(row, pLocalsTreeItem);
    endInsertRows();
  }
}

void LocalsTreeModel::insertLocalsList(const QList<QVector<QVariant> > &locals)
{
  QList<LocalsTreeItem*> localsTreeItems = mpRootLocalsTreeItem->getChildren();
  foreach (LocalsTreeItem *pLocalsTreeItem, localsTreeItems) {
    bool isFound = false;
    foreach (QVector<QVariant> local, locals) {
      QString nameStructure;
      /* construct the item name structure. */
      if (pLocalsTreeItem->parent() == mpRootLocalsTreeItem) {
        nameStructure = QString("%1.%2").arg(pLocalsTreeItem->parent()->getNameStructure()).arg(local[0].toString());
      } else {
        nameStructure = QString("%1.%2%3").arg(pLocalsTreeItem->parent()->getNameStructure()).arg(local[0].toString()).arg(local[1].toString());
      }
      /* compare the name structure to find the item. */
      if (nameStructure.compare(pLocalsTreeItem->getNameStructure()) == 0) {
        isFound = true;
        break;
      }
    }
    /* if not found then the item has been removed from the stack so we must also remove it from the locals tree. */
    if (!isFound) {
      removeLocalItem(pLocalsTreeItem);
    }
  }
  foreach (QVector<QVariant> local, locals) {
    insertLocalItemData(local, mpRootLocalsTreeItem);
  }
  mpLocalsWidget->getLocalsTreeProxyModel()->invalidate();
}

void LocalsTreeModel::removeLocalItem(LocalsTreeItem *pLocalsTreeItem)
{
  QModelIndex index = localsTreeItemIndex(pLocalsTreeItem);
  int row = index.row();
  beginRemoveRows(index, row, row);
  pLocalsTreeItem->removeChildren();
  endRemoveRows();
  LocalsTreeItem *pParentLocalsTreeItem = pLocalsTreeItem->parent();
  pParentLocalsTreeItem->removeChild(pLocalsTreeItem);
  pLocalsTreeItem->deleteLater();
}

void LocalsTreeModel::removeLocalItems()
{
  int n = mpRootLocalsTreeItem->getChildren().size();
  if (n == 0) {
    return;
  }
  QModelIndex index = localsTreeItemIndex(mpRootLocalsTreeItem);
  beginRemoveRows(index, 0, n - 1);
  mpRootLocalsTreeItem->removeChildren();
  endRemoveRows();
}

/*!
 * \brief LocalsTreeModel::updateLocalsTreeItem
 * Triggers a view update for the LocalsTreeItem in the Locals Browser.
 * \param pLocalsTreeItem
 */
void LocalsTreeModel::updateLocalsTreeItem(LocalsTreeItem *pLocalsTreeItem)
{
  QModelIndex index = localsTreeItemIndex(pLocalsTreeItem);
  emit dataChanged(index, index);
}

/*!
 * \class LocalsTreeProxyModel
 * \brief A sort filter proxy model for Locals Browser.
 */
/*!
 * \brief LocalsTreeProxyModel::LocalsTreeProxyModel
 * \param parent
 */
LocalsTreeProxyModel::LocalsTreeProxyModel(QObject *parent)
  : QSortFilterProxyModel(parent)
{
}

/*!
 * \brief LocalsTreeProxyModel::lessThan
 * Sorts the LocalsTreeItems except for members of a record type.
 * \param left
 * \param right
 * \return
 */
bool LocalsTreeProxyModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
  /* Ticket:4078
   * Do not sort the record members.
   */
  LocalsTreeItem *pLocalsTreeItem = static_cast<LocalsTreeItem*>(left.internalPointer());
  if (pLocalsTreeItem && pLocalsTreeItem->parent() && pLocalsTreeItem->parent()->getModelicaValue() &&
      qobject_cast<ModelicaRecordValue*>(pLocalsTreeItem->parent()->getModelicaValue())) {
    return false;
  } else {
    return QSortFilterProxyModel::lessThan(left, right);
  }
}

LocalsTreeView::LocalsTreeView(LocalsWidget *pLocalsWidget)
  : QTreeView(pLocalsWidget)
{
  mpLocalsWidget = pLocalsWidget;
  setItemDelegate(new ItemDelegate(this));
  setTextElideMode(Qt::ElideMiddle);
  setIndentation(Helper::treeIndentation);
  setContextMenuPolicy(Qt::CustomContextMenu);
  setExpandsOnDoubleClick(false);
  setSortingEnabled(true);
  sortByColumn(0, Qt::AscendingOrder);
  setUniformRowHeights(true);
}

/*!
 * \class LocalsWidget
 * \brief A widget containing local variables with type and values while debugging.
 */
/*!
 * \brief LocalsWidget::LocalsWidget
 * \param pParent
 */
LocalsWidget::LocalsWidget(QWidget *pParent)
  : QWidget(pParent)
{
  /* Locals Tree View */
  mpLocalsTreeView = new LocalsTreeView(this);
  mpLocalsTreeModel = new LocalsTreeModel(this);
  mpLocalsTreeProxyModel = new LocalsTreeProxyModel;
  mpLocalsTreeProxyModel->setDynamicSortFilter(true);
  mpLocalsTreeProxyModel->setSourceModel(mpLocalsTreeModel);
  mpLocalsTreeView->setModel(mpLocalsTreeProxyModel);
  connect(mpLocalsTreeView, SIGNAL(expanded(QModelIndex)), SLOT(localsTreeItemExpanded(QModelIndex)));
  /* Local value viewer */
  mpLocalValueViewer = new QPlainTextEdit;
  connect(mpLocalsTreeView->selectionModel(), SIGNAL(currentChanged(QModelIndex,QModelIndex)), SLOT(showLocalValue(QModelIndex,QModelIndex)));
  QSplitter *pLocalsSplitter = new QSplitter;
  pLocalsSplitter->setOrientation(Qt::Vertical);
  pLocalsSplitter->setChildrenCollapsible(false);
  pLocalsSplitter->setHandleWidth(4);
  pLocalsSplitter->addWidget(mpLocalsTreeView);
  pLocalsSplitter->addWidget(mpLocalValueViewer);
  pLocalsSplitter->setStretchFactor(0, 1);
  pLocalsSplitter->setStretchFactor(1, 0);
  /* set layout */
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->setContentsMargins(0, 0, 1, 0);
  pMainLayout->addWidget(pLocalsSplitter, 0, 0);
  setLayout(pMainLayout);
  connect(GDBAdapter::instance(), SIGNAL(GDBProcessFinished()), SLOT(handleGDBProcessFinished()));
}

void LocalsWidget::localsTreeItemExpanded(QModelIndex index)
{
  index = mpLocalsTreeProxyModel->mapToSource(index);
  LocalsTreeItem *pLocalsTreeItem = static_cast<LocalsTreeItem*>(index.internalPointer());
  if (!pLocalsTreeItem || pLocalsTreeItem->isExpanded()) {
    return;
  }

  pLocalsTreeItem->setExpanded(true);
  pLocalsTreeItem->retrieveLocalChildren();
}

void LocalsWidget::showLocalValue(QModelIndex currentIndex, QModelIndex previousIndex)
{
  Q_UNUSED(previousIndex);

  currentIndex = mpLocalsTreeProxyModel->mapToSource(currentIndex);
  LocalsTreeItem *pLocalsTreeItem = static_cast<LocalsTreeItem*>(currentIndex.internalPointer());
  if (!pLocalsTreeItem) {
    return;
  }
  if (pLocalsTreeItem->getDisplayType().compare(Helper::STRING) == 0) {
    mpLocalValueViewer->setPlainText(QString("\"%1\"").arg(pLocalsTreeItem->getDisplayValue()));
  } else {
    mpLocalValueViewer->setPlainText(pLocalsTreeItem->getDisplayValue());
  }
}

/*!
 * \brief LocalsWidget::handleGDBProcessFinished
 * Slot activated when GDBProcessFinished signal of GDBAdapter is raised.
 * Clears the LocalsTreeView by removing all the items.
 */
void LocalsWidget::handleGDBProcessFinished()
{
  mpLocalsTreeModel->removeLocalItems();
}
