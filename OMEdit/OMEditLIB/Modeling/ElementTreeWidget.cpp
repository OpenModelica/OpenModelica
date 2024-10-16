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

#include "ElementTreeWidget.h"
#include "ItemDelegate.h"
#include "Util/Helper.h"
#include "MainWindow.h"

#include <QGridLayout>
#include <QStringBuilder>

/*!
 * \class ElementTreeItem
 * \brief A tree item in the Element Browser.
 */
/*!
 * \brief ElementTreeItem::ElementTreeItem
 */
ElementTreeItem::ElementTreeItem()
  : QObject(0)
{
  mIsRootItem = true;
}

/*!
 * \brief makeTooltip
 * Makes a tooltip from restriction, name and comment.
 * \param restriction
 * \param name
 * \param comment
 * \return
 */
QString makeTooltip(QString restriction, QString name, QString comment)
{
  QString tooltip = restriction % " <b>" % name % "</b>";
  if (!comment.isEmpty()) {
    return tooltip % "<br /><br />" % comment;
  } else {
    return tooltip;
  }
}

/*!
 * \brief ElementTreeItem::ElementTreeItem
 * \param pModel
 * \param pParentElementTreeItem
 */
ElementTreeItem::ElementTreeItem(ModelInstance::Model *pModel, ElementTreeItem *pParentElementTreeItem)
  : QObject(pParentElementTreeItem)
{
  mpParentElementTreeItem = pParentElementTreeItem;
  mName = pModel->getName();
  mDisplayName = pModel->getName();
  mTooltip = makeTooltip(pModel->getRestriction(), mName, pModel->getComment());
}

/*!
 * \brief ElementTreeItem::ElementTreeItem
 * \param pElement
 * \param pParentElementTreeItem
 */
ElementTreeItem::ElementTreeItem(ModelInstance::Element *pElement, ElementTreeItem *pParentElementTreeItem)
  : QObject(pParentElementTreeItem)
{
  mpParentElementTreeItem = pParentElementTreeItem;
  if (pElement->isExtend()) {
    mName = pElement->getType();
    mDisplayName = "extends " % pElement->getType();
    if (pElement->getModel()) {
      mTooltip = makeTooltip(pElement->getModel()->getRestriction(), mName, pElement->getModel()->getComment());
    }
  } else if (pElement->isClass()) {
    auto pReplaceableClass = dynamic_cast<ModelInstance::ReplaceableClass*>(pElement);
    mName = pReplaceableClass->getName();
    mDisplayName = pReplaceableClass->getName() % " = " % pReplaceableClass->getBaseClass();
    mTooltip = "<b>" % pReplaceableClass->getBaseClass() % "</b>";
  } else {
    mName = pElement->getName();
    mDisplayName = pElement->getName();
    mTooltip = makeTooltip(pElement->getType(), mName, pElement->getComment());
  }
}

/*!
 * \brief ElementTreeItem::~ElementTreeItem
 */
ElementTreeItem::~ElementTreeItem()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

/*!
 * \brief ElementTreeItem::removeChildren
 * Removes all the children.
 */
void ElementTreeItem::removeChildren()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

/*!
 * \brief ElementTreeItem::data
 * Returns the data stored under the given role for the item referred to by the column.
 * \param column
 * \param role
 * \return
 */
QVariant ElementTreeItem::data(int column, int role) const
{
  switch (column) {
    case 0:
      switch (role) {
        case Qt::DisplayRole:
          return mDisplayName;
         case Qt::ToolTipRole:
           return mTooltip;
        default:
          return QVariant();
      }
    default:
      return QVariant();
  }
}

/*!
 * \brief ElementTreeItem::row
 * Returns the row number corresponding to ElementTreeItem.
 * \return
 */
int ElementTreeItem::row() const
{
  if (mpParentElementTreeItem) {
    return mpParentElementTreeItem->mChildren.indexOf(const_cast<ElementTreeItem*>(this));
  }

  return 0;
}

/*!
 * \class ElementTreeProxyModel
 * \brief A sort filter proxy model for Element Browser.
 */
/*!
 * \brief ElementTreeProxyModel::ElementTreeProxyModel
 * \param pElementWidget
 */
ElementTreeProxyModel::ElementTreeProxyModel(ElementWidget *pElementWidget)
    : QSortFilterProxyModel(pElementWidget)
{
  mpElementWidget = pElementWidget;
}

/*!
 * \brief ElementTreeProxyModel::filterAcceptsRow
 * Filters the ElementTreeItems based on the filter reguler expression.
 * Also checks if ElementTreeItem is protected and show/hide it based on Show Protected Classes settings value.
 * \param sourceRow
 * \param sourceParent
 * \return
 */
bool ElementTreeProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
  QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
  ElementTreeItem *pElementTreeItem = static_cast<ElementTreeItem*>(index.internalPointer());
  if (pElementTreeItem) {
    // if any of children matches the filter, then current index matches the filter as well
    int rows = sourceModel()->rowCount(index);
    for (int i = 0 ; i < rows ; ++i) {
      if (filterAcceptsRow(i, index)) {
        return true;
      }
    }
#if (QT_VERSION >= QT_VERSION_CHECK(6, 0, 0))
    return pElementTreeItem->getName().contains(filterRegularExpression());
#else
    return pElementTreeItem->getName().contains(filterRegExp());
#endif
  } else {
    return QSortFilterProxyModel::filterAcceptsRow(sourceRow, sourceParent);
  }
}

/*!
 * \class ElementTreeModel
 * \brief A model for Element Browser tree.
 */
/*!
 * \brief ElementTreeModel::ElementTreeModel
 * \param pElementWidget
 */
ElementTreeModel::ElementTreeModel(ElementWidget *pElementWidget)
  : QAbstractItemModel(pElementWidget)
{
  mpElementWidget = pElementWidget;
  mpRootElementTreeItem = new ElementTreeItem();
}

ElementTreeModel::~ElementTreeModel()
{
  delete mpRootElementTreeItem;
}

/*!
 * \brief ElementTreeModel::columnCount
 * Returns the number of columns for the children of the given parent.
 * \param parent
 * \return
 */
int ElementTreeModel::columnCount(const QModelIndex &parent) const
{
  Q_UNUSED(parent);
  return 1;
}

/*!
 * \brief ElementTreeModel::rowCount
 * Returns the number of rows under the given parent.
 * When the parent is valid it means that rowCount is returning the number of children of parent.
 * \param parent
 * \return
 */
int ElementTreeModel::rowCount(const QModelIndex &parent) const
{
  if (parent.column() > 0) {
    return 0;
  }

  const ElementTreeItem *pParentElementTreeItem = parent.isValid() ? static_cast<const ElementTreeItem*>(parent.internalPointer()) : mpRootElementTreeItem;
  return pParentElementTreeItem->childrenSize();
}

/*!
 * \brief ElementTreeModel::headerData
 * Returns the data for the given role and section in the header with the specified orientation.
 * \param section
 * \param orientation
 * \param role
 * \return
 */
QVariant ElementTreeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
  Q_UNUSED(section);
  if (orientation == Qt::Horizontal && role == Qt::DisplayRole) {
    return Helper::elements;
  }
  return QVariant();
}

/*!
 * \brief ElementTreeModel::index
 * Returns the index of the item in the model specified by the given row, column and parent index.
 * \param row
 * \param column
 * \param parent
 * \return
 */
QModelIndex ElementTreeModel::index(int row, int column, const QModelIndex &parent) const
{
  if (!hasIndex(row, column, parent)) {
    return QModelIndex();
  }

  ElementTreeItem *pParentElementTreeItem = parent.isValid() ? static_cast<ElementTreeItem*>(parent.internalPointer()) : mpRootElementTreeItem;
  if (auto *childItem = pParentElementTreeItem->child(row)) {
    return createIndex(row, column, childItem);
  }

  return QModelIndex();
}

/*!
 * \brief ElementTreeModel::parent
 * Finds the parent for QModelIndex
 * \param index
 * \return
 */
QModelIndex ElementTreeModel::parent(const QModelIndex &index) const
{
  if (!index.isValid()) {
    return QModelIndex();
  }

  ElementTreeItem *pChildElementTreeItem = static_cast<ElementTreeItem*>(index.internalPointer());
  ElementTreeItem *pParentElementTreeItem = pChildElementTreeItem->parent();
  if (pParentElementTreeItem == mpRootElementTreeItem)
    return QModelIndex();

  return createIndex(pParentElementTreeItem->row(), 0, pParentElementTreeItem);
}

/*!
 * \brief ElementTreeModel::data
 * Returns the ElementTreeModel data.
 * \param index
 * \param role
 * \return
 */
QVariant ElementTreeModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid()) {
    return QVariant();
  }

  ElementTreeItem *pElementTreeItem = static_cast<ElementTreeItem*>(index.internalPointer());
  return pElementTreeItem->data(index.column(), role);
}

/*!
 * \brief ElementTreeModel::flags
 * Returns the flags for ElementTreeItem.
 * \param index
 * \return
 */
Qt::ItemFlags ElementTreeModel::flags(const QModelIndex &index) const
{
  if (!index.isValid()) {
    return Qt::ItemFlags();
  } else {
    return Qt::ItemIsEnabled | Qt::ItemIsSelectable;
  }
}

/*!
 * \brief ElementTreeModel::elementsTreeItemIndex
 * Finds the QModelIndex attached to ElementTreeItem.
 * \param pElementTreeItem
 * \return
 */
QModelIndex ElementTreeModel::elementsTreeItemIndex(const ElementTreeItem *pElementTreeItem) const
{
  return elementsTreeItemIndexHelper(pElementTreeItem, mpRootElementTreeItem, QModelIndex());
}

/*!
 * \brief ElementTreeModel::addElements
 * Adds the Elements of the model to the Element Browser.
 * \param pModel
 * \param pParentElementTreeItem
 */
void ElementTreeModel::addElements(ModelInstance::Model *pModel, ElementTreeItem *pParentElementTreeItem)
{
  // Element Browser is only available with new API.
  if (!MainWindow::instance()->isNewApi()) {
    return;
  }
  // remove the existing elements if we are adding elements of new model.
  if (!pParentElementTreeItem && mpRootElementTreeItem->childrenSize() > 0) {
    beginRemoveRows(elementsTreeItemIndex(mpRootElementTreeItem->parent()), 0, mpRootElementTreeItem->childrenSize() - 1);
    mpRootElementTreeItem->removeChildren();
    endRemoveRows();
  }
  // add model name item
  pParentElementTreeItem = mpRootElementTreeItem;
  QModelIndex index = elementsTreeItemIndex(pParentElementTreeItem);
  beginInsertRows(index, 0, 1);
  ElementTreeItem *pElementTreeItem = new ElementTreeItem(pModel, pParentElementTreeItem);
  pParentElementTreeItem->insertChild(0, pElementTreeItem);
  endInsertRows();
  // add model elements
  addElementsHelper(pModel, pElementTreeItem);
  // expand the top item
  index = elementsTreeItemIndex(pElementTreeItem);
  index = mpElementWidget->getElementTreeProxyModel()->mapFromSource(index);
  mpElementWidget->getElementTreeView()->expand(index);
  mpElementWidget->getElementTreeView()->setCurrentIndex(index);
}

/*!
 * \brief ElementTreeModel::addElementsHelper
 * Helper function for ElementTreeModel::addElements
 * Adds the items recursivly.
 * \param pModel
 * \param pParentElementTreeItem
 */
void ElementTreeModel::addElementsHelper(ModelInstance::Model *pModel, ElementTreeItem *pParentElementTreeItem)
{
  if (pModel) {
    QModelIndex index = elementsTreeItemIndex(pParentElementTreeItem);
    int row = 0;
    QList<ModelInstance::Element*> elements = pModel->getElements();
    beginInsertRows(index, row, elements.size() - 1);
    foreach (auto pElement, elements) {
      pParentElementTreeItem->insertChild(row++, new ElementTreeItem(pElement, pParentElementTreeItem));
    }
    endInsertRows();

    for (int i = 0; i < pParentElementTreeItem->childrenSize(); ++i) {
      ElementTreeItem *pElementTreeItem = pParentElementTreeItem->child(i);
      addElementsHelper(elements.at(i)->getModel(), pElementTreeItem);
    }
  }
}

/*!
 * \brief ElementTreeModel::elementsTreeItemIndexHelper
 * Helper function for ElementTreeModel::ElementsTreeItemIndex()
 * \param pElementTreeItem
 * \param pParentElementTreeItem
 * \param parentIndex
 * \return
 */
QModelIndex ElementTreeModel::elementsTreeItemIndexHelper(const ElementTreeItem *pElementTreeItem, const ElementTreeItem *pParentElementTreeItem,
                                                          const QModelIndex &parentIndex) const
{
  if (pElementTreeItem == pParentElementTreeItem) {
    return parentIndex;
  }
  for (int i = pParentElementTreeItem->childrenSize(); --i >= 0; ) {
    const ElementTreeItem *pChildElementTreeItem = pParentElementTreeItem->child(i);
    QModelIndex childIndex = index(i, 0, parentIndex);
    QModelIndex index = elementsTreeItemIndexHelper(pElementTreeItem, pChildElementTreeItem, childIndex);
    if (index.isValid()) {
      return index;
    }
  }
  return QModelIndex();
}

/*!
 * \class ElementTreeView
 * \brief A treeview for Element Browser.
 */
/*!
 * \brief ElementTreeView::ElementTreeView
 * \param pElementWidget
 */
ElementTreeView::ElementTreeView(ElementWidget *pElementWidget)
  : QTreeView(pElementWidget), mpElementWidget(pElementWidget)
{
  setItemDelegate(new ItemDelegate(this));
  setTextElideMode(Qt::ElideMiddle);
  setIndentation(Helper::treeIndentation);
  setUniformRowHeights(true);
  setHeaderHidden(true);
}

/*!
 * \class ElementWidget
 * \brief A widget for Element Browser.
 */
/*!
 * \brief ElementWidget::ElementWidget
 * \param pParent
 */
ElementWidget::ElementWidget(QWidget *pParent)
  : QWidget(pParent)
{
  // tree search filters
  mpTreeSearchFilters = new TreeSearchFilters(this);
  mpTreeSearchFilters->getFilterTextBox()->setPlaceholderText(Helper::filterElements);
  connect(mpTreeSearchFilters->getFilterTextBox(), SIGNAL(returnPressed()), SLOT(filterElements()));
  connect(mpTreeSearchFilters->getFilterTextBox(), SIGNAL(textEdited(QString)), SLOT(filterElements()));
  connect(mpTreeSearchFilters->getCaseSensitiveCheckBox(), SIGNAL(toggled(bool)), SLOT(filterElements()));
  connect(mpTreeSearchFilters->getSyntaxComboBox(), SIGNAL(currentIndexChanged(int)), SLOT(filterElements()));
  // create tree view
  mpElementTreeModel = new ElementTreeModel(this);
  mpElementTreeProxyModel = new ElementTreeProxyModel(this);
  mpElementTreeProxyModel->setDynamicSortFilter(true);
  mpElementTreeProxyModel->setSourceModel(mpElementTreeModel);
  mpElementTreeView = new ElementTreeView(this);
  mpElementTreeView->setModel(mpElementTreeProxyModel);
  connect(mpElementTreeModel, SIGNAL(rowsInserted(QModelIndex,int,int)), mpElementTreeProxyModel, SLOT(invalidate()));
  connect(mpElementTreeModel, SIGNAL(rowsRemoved(QModelIndex,int,int)), mpElementTreeProxyModel, SLOT(invalidate()));
  connect(mpTreeSearchFilters->getExpandAllButton(), SIGNAL(clicked()), mpElementTreeView, SLOT(expandAll()));
  connect(mpTreeSearchFilters->getCollapseAllButton(), SIGNAL(clicked()), mpElementTreeView, SLOT(collapseAll()));
  // create the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpTreeSearchFilters, 0, 0);
  pMainLayout->addWidget(mpElementTreeView, 2, 0);
  setLayout(pMainLayout);
}

/*!
 * \brief ElementWidget::filterElements
 * Filters the Elements in the Element Browser.
 */
void ElementWidget::filterElements()
{
  QString searchText = mpTreeSearchFilters->getFilterTextBox()->text();
  Qt::CaseSensitivity caseSensitivity = mpTreeSearchFilters->getCaseSensitiveCheckBox()->isChecked() ? Qt::CaseSensitive: Qt::CaseInsensitive;
#if (QT_VERSION >= QT_VERSION_CHECK(6, 0, 0))
  // TODO: handle PatternSyntax: https://doc.qt.io/qt-6/qregularexpression.html
  mpElementTreeProxyModel->setFilterRegularExpression(QRegularExpression::fromWildcard(searchText, caseSensitivity, QRegularExpression::UnanchoredWildcardConversion));
#else
  QRegExp::PatternSyntax syntax = QRegExp::PatternSyntax(mpTreeSearchFilters->getSyntaxComboBox()->itemData(mpTreeSearchFilters->getSyntaxComboBox()->currentIndex()).toInt());
  QRegExp regExp(searchText, caseSensitivity, syntax);
  mpElementTreeProxyModel->setFilterRegExp(regExp);
#endif
}
