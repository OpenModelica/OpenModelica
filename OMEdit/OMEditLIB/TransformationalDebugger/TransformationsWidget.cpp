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

#include <utility>

#include "MainWindow.h"
#include "TransformationsWidget.h"
#include "Options/OptionsDialog.h"
#include "Util/StringHandler.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ItemDelegate.h"
#include "Editors/TransformationsEditor.h"
#include "Editors/ModelicaEditor.h"
#include "diff_match_patch.h"
#include "simdjson.h"

#include <QStatusBar>
#include <QGridLayout>
#include <QVBoxLayout>
#include <QMessageBox>

/*!
  \class TVariablesTreeItem
  \brief Contains the information about the result variable.
  */
/*!
  \param tVariableItemData - a list of items.\n
  0 -> name\n
  1 -> displayName\n
  2 -> comment\n
  3 -> lineNumber\n
  4 -> filePath
  */
TVariablesTreeItem::TVariablesTreeItem(const QVector<QVariant> &tVariableItemData, TVariablesTreeItem *pParent, bool isRootItem)
{
  mpParentTVariablesTreeItem = pParent;
  mIsRootItem = isRootItem;
  mVariableName = tVariableItemData[0].toString();
  mDisplayVariableName = tVariableItemData[1].toString();
  mComment = tVariableItemData[2].toString();
  mLineNumber = tVariableItemData[3].toString();
  mFilePath = tVariableItemData[4].toString();
}

TVariablesTreeItem::~TVariablesTreeItem()
{
  removeChildren();
}

void TVariablesTreeItem::appendChild(TVariablesTreeItem *pTVariablesTreeItem)
{
  mChildren.append(pTVariablesTreeItem);
}

TVariablesTreeItem* TVariablesTreeItem::child(int row)
{
  return mChildren.value(row);
}

void TVariablesTreeItem::removeChildren()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

int TVariablesTreeItem::columnCount() const
{
  return 4;
}

QVariant TVariablesTreeItem::data(int column, int role) const
{
  switch (column)
  {
    case 0:
      switch (role)
      {
        case Qt::DisplayRole:
          return mDisplayVariableName;
        case Qt::ToolTipRole:
          return mVariableName;
        default:
          return QVariant();
      }
    case 1:
      switch (role)
      {
        case Qt::DisplayRole:
          return mComment;
        case Qt::ToolTipRole:
          return mComment;
        default:
          return QVariant();
      }
    case 2:
      switch (role)
      {
        case Qt::DisplayRole:
          return mLineNumber;
        case Qt::ToolTipRole:
          return mLineNumber;
        default:
          return QVariant();
      }
    case 3:
      switch (role)
      {
        case Qt::DisplayRole:
          return mFilePath;
        case Qt::ToolTipRole:
          return mFilePath;
        default:
          return QVariant();
      }
    default:
      return QVariant();
  }
}

int TVariablesTreeItem::row() const
{
  if (mpParentTVariablesTreeItem)
    return mpParentTVariablesTreeItem->mChildren.indexOf(const_cast<TVariablesTreeItem*>(this));

  return 0;
}

TVariablesTreeItem* TVariablesTreeItem::parent()
{
  return mpParentTVariablesTreeItem;
}

TVariablesTreeModel::TVariablesTreeModel(TVariablesTreeView *pTVariablesTreeView)
  : QAbstractItemModel(pTVariablesTreeView)
{
  mpTVariablesTreeView = pTVariablesTreeView;
  QVector<QVariant> headers;
  headers << "" << Helper::variables << tr("Comment") << tr("Line") << Helper::fileLocation;
  mpRootTVariablesTreeItem = new TVariablesTreeItem(headers, 0, true);
}

int TVariablesTreeModel::columnCount(const QModelIndex &parent) const
{
  if (parent.isValid())
    return static_cast<TVariablesTreeItem*>(parent.internalPointer())->columnCount();
  else
    return mpRootTVariablesTreeItem->columnCount();
}

int TVariablesTreeModel::rowCount(const QModelIndex &parent) const
{
  TVariablesTreeItem *pParentTVariablesTreeItem;
  if (parent.column() > 0) {
    return 0;
  }

  if (!parent.isValid()) {
    pParentTVariablesTreeItem = mpRootTVariablesTreeItem;
  } else {
    pParentTVariablesTreeItem = static_cast<TVariablesTreeItem*>(parent.internalPointer());
  }
  return pParentTVariablesTreeItem ? pParentTVariablesTreeItem->childrenSize() : 0;
}

QVariant TVariablesTreeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
  if (orientation == Qt::Horizontal && role == Qt::DisplayRole)
    return mpRootTVariablesTreeItem->data(section);
  return QVariant();
}

QModelIndex TVariablesTreeModel::index(int row, int column, const QModelIndex &parent) const
{
  if (!hasIndex(row, column, parent)) {
    return QModelIndex();
  }

  TVariablesTreeItem *pParentTVariablesTreeItem;
  if (!parent.isValid()) {
    pParentTVariablesTreeItem = mpRootTVariablesTreeItem;
  } else {
    pParentTVariablesTreeItem = static_cast<TVariablesTreeItem*>(parent.internalPointer());
  }

  if (row < 0 || row >= pParentTVariablesTreeItem->childrenSize()) {
    return QModelIndex();
  }

  return createIndex(row, column, pParentTVariablesTreeItem->child(row));
}

QModelIndex TVariablesTreeModel::parent(const QModelIndex &index) const
{
  if (!index.isValid())
    return QModelIndex();

  TVariablesTreeItem *pChildTVariablesTreeItem = static_cast<TVariablesTreeItem*>(index.internalPointer());
  TVariablesTreeItem *pParentTVariablesTreeItem = pChildTVariablesTreeItem->parent();
  if (pParentTVariablesTreeItem == mpRootTVariablesTreeItem)
    return QModelIndex();

  return createIndex(pParentTVariablesTreeItem->row(), 0, pParentTVariablesTreeItem);
}

QVariant TVariablesTreeModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid())
    return QVariant();

  TVariablesTreeItem *pTVariablesTreeItem = static_cast<TVariablesTreeItem*>(index.internalPointer());
  return pTVariablesTreeItem->data(index.column(), role);
}

Qt::ItemFlags TVariablesTreeModel::flags(const QModelIndex &index) const
{
  if (!index.isValid())
      return Qt::ItemFlags();

  Qt::ItemFlags flags = Qt::ItemIsEnabled | Qt::ItemIsSelectable;
  /* Ticket #3207. Make all the items enable and selectable.
   */
//  TVariablesTreeItem *pTVariablesTreeItem = static_cast<TVariablesTreeItem*>(index.internalPointer());
//  if (pTVariablesTreeItem && pTVariablesTreeItem->childrenSize() == 0)
//    flags |= Qt::ItemIsEnabled | Qt::ItemIsSelectable;

  return flags;
}

TVariablesTreeItem* TVariablesTreeModel::findTVariablesTreeItem(const QString &name, TVariablesTreeItem *root) const
{
  if (root->getVariableName() == name)
    return root;
  for (int i = root->childrenSize(); --i >= 0; )
    if (TVariablesTreeItem *item = findTVariablesTreeItem(name, root->getChildren().at(i)))
      return item;
  return 0;
}

QModelIndex TVariablesTreeModel::tVariablesTreeItemIndex(const TVariablesTreeItem *pTVariablesTreeItem) const
{
  if (!pTVariablesTreeItem || pTVariablesTreeItem == mpRootTVariablesTreeItem) {
    return QModelIndex();
  }

  return createIndex(pTVariablesTreeItem->row(), 0, const_cast<TVariablesTreeItem *>(pTVariablesTreeItem));
}

void TVariablesTreeModel::insertTVariablesItems(QHashIterator<QString, OMVariable> variables)
{
  // create hash based VariableNode
  QVector<QVariant> variabledata;
  VariableNode *pRootVariableNode = new VariableNode(variabledata);
  while (variables.hasNext()) {
    variables.next();
    const OMVariable &variable = variables.value();
    if (variable.name.startsWith("$PRE.") || variable.name.startsWith("$res")) {
      continue;
    }

    QStringList parts;
    if (variable.name.startsWith("der(")) {
      QString str = variable.name;
      str.chop((str.lastIndexOf("der(")/4)+1);
      parts = StringHandler::makeVariablePartsWithInd(str.mid(str.lastIndexOf("der(") + 4));
    } else if (variable.name.startsWith("previous(")) {
      QString str = variable.name;
      str.chop((str.lastIndexOf("previous(")/9)+1);
      parts = StringHandler::makeVariablePartsWithInd(str.mid(str.lastIndexOf("previous(") + 9));
    } else {
      parts = StringHandler::makeVariablePartsWithInd(variable.name);
    }
    // prefix is empty — transformations uses bare variable names with no file prefix
    Utilities::buildVariableNodeTree(pRootVariableNode, "", variable.name, parts,
                                     [&variable](const QString &fullName, const QString &displayName, bool /*isMainArray*/) {
      QVector<QVariant> data;
      data << fullName
           << displayName
           << variable.comment
           << variable.info.lineStart
           << variable.info.file;
      return data;
    });
  }
  // insert variables to VariablesTreeModel
  beginResetModel();
  insertVariablesItems(pRootVariableNode, mpRootTVariablesTreeItem);
  endResetModel();
  // Delete VariableNode
  delete pRootVariableNode;
}

void TVariablesTreeModel::clearTVariablesTreeItems()
{
  if (mpRootTVariablesTreeItem->childrenSize() > 0) {
    beginResetModel();
    mpRootTVariablesTreeItem->removeChildren();
    endResetModel();
  }
}

/*!
 * \brief TVariablesTreeModel::insertVariablesItems
 * Creates TVariablesTreeItem using VariableNode and adds them to the TVariablesTreeView.
 * \param pParentVariableNode
 * \param pParentTVariablesTreeItem
 */
void TVariablesTreeModel::insertVariablesItems(VariableNode *pParentVariableNode, TVariablesTreeItem *pParentTVariablesTreeItem)
{
  if (pParentVariableNode && !pParentVariableNode->mChildren.isEmpty()) {
    QHash<QString, VariableNode*>::const_iterator iterator = pParentVariableNode->mChildren.constBegin();
    while (iterator != pParentVariableNode->mChildren.constEnd()) {
      VariableNode *pVariableNode = iterator.value();
      TVariablesTreeItem *pTVariablesTreeItem = new TVariablesTreeItem(pVariableNode->mVariableNodeData, pParentTVariablesTreeItem);
      pParentTVariablesTreeItem->appendChild(pTVariablesTreeItem);
      ++iterator;
    }

    foreach (TVariablesTreeItem *pTVariablesTreeItem, pParentTVariablesTreeItem->getChildren()) {
      VariableNode *pVariableNode = pParentVariableNode->mChildren.value(pTVariablesTreeItem->getVariableName());
      insertVariablesItems(pVariableNode, pTVariablesTreeItem);
    }
  }
}

TVariableTreeProxyModel::TVariableTreeProxyModel(QObject *parent)
  : QSortFilterProxyModel(parent)
{
}

bool TVariableTreeProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  if (!filterRegularExpression().pattern().isEmpty()) {
#else
  if (!filterRegExp().isEmpty()) {
#endif
    QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
    if (index.isValid()) {
      // if any of children matches the filter, then current index matches the filter as well
      int rows = sourceModel()->rowCount(index);
      for (int i = 0 ; i < rows ; ++i) {
        if (filterAcceptsRow(i, index)) {
          return true;
        }
      }
      // check current index itself
      TVariablesTreeItem *pTVariablesTreeItem = static_cast<TVariablesTreeItem*>(index.internalPointer());
      if (pTVariablesTreeItem) {
        QString variableName = pTVariablesTreeItem->getVariableName();
        variableName.remove(QRegularExpression("(\\.mat|\\.plt|\\.csv|_res.mat|_res.plt|_res.csv)"));
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
        return variableName.contains(filterRegularExpression());
#else
        return variableName.contains(filterRegExp());
#endif
      } else {
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
        return sourceModel()->data(index).toString().contains(filterRegularExpression());
#else
        return sourceModel()->data(index).toString().contains(filterRegExp());
#endif
      }
      QString key = sourceModel()->data(index, filterRole()).toString();
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
      return key.contains(filterRegularExpression());
#else
      return key.contains(filterRegExp());
#endif
    }
  }
  return QSortFilterProxyModel::filterAcceptsRow(sourceRow, sourceParent);
}

bool TVariableTreeProxyModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
  QVariant l = (left.model() ? left.model()->data(left) : QVariant());
  QVariant r = (right.model() ? right.model()->data(right) : QVariant());
  return StringHandler::naturalSort(l.toString(), r.toString());
}

TVariablesTreeView::TVariablesTreeView(TransformationsWidget *pTransformationsWidget)
  : QTreeView(pTransformationsWidget)
{
  mpTransformationsWidget = pTransformationsWidget;
  setItemDelegate(new ItemDelegate(this));
  setTextElideMode(Qt::ElideMiddle);
  setIndentation(Helper::treeIndentation);
  setSortingEnabled(true);
  sortByColumn(0, Qt::AscendingOrder);
  setExpandsOnDoubleClick(false);
  setUniformRowHeights(true);
}


EquationTreeItem::EquationTreeItem(const OMEquation *pOMEquation, EquationTreeItem *pParent, bool isRootItem)
{
  mpParentEquationTreeItem = pParent;
  mIsRootItem = isRootItem;
  mpOMEquation = pOMEquation;
}

EquationTreeItem::~EquationTreeItem()
{
  removeChildren();
}

/*!
 * \brief EquationTreeItem::insertChild
 * Inserts a child EquationTreeItem at the given position.
 * \param position
 * \param pEquationTreeItem
 */
void EquationTreeItem::insertChild(int position, EquationTreeItem *pEquationTreeItem)
{
  mChildren.insert(position, pEquationTreeItem);
}

/*!
 * \brief EquationTreeItem::child
 * Returns the child EquationTreeItem stored at given row.
 * \param row
 * \return
 */
EquationTreeItem* EquationTreeItem::child(int row)
{
  return mChildren.value(row);
}

void EquationTreeItem::removeChildren()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

QVariant EquationTreeItem::data(int column, int role) const
{
  // safeguard against null pointer
  if (!mpOMEquation) {
    return QVariant();
  }

  /* If the equation is not profiled then show only index, section and equation columns
   * and hide the rest of the columns by showing empty string in them.
   * This is done to avoid showing 0 and 0% in NCall, MaxTime, Time and Fraction columns for non-profiled equations.
   */
  if (column > 2 && mpOMEquation->profileBlock < 0) {
    column = 7;
  }

  switch (column)
  {
    case 0: // index
      switch (role)
      {
        case Qt::DisplayRole:
        case Qt::ToolTipRole:
          return QString::number(mpOMEquation->index);
        default:
          return QVariant();
      }
    case 1: // Section
      switch (role)
      {
        case Qt::DisplayRole:
        case Qt::ToolTipRole:
          return mpOMEquation->section;
        default:
          return QVariant();
      }
    case 2: // Equation
      switch (role)
      {
        case Qt::DisplayRole:
          return mpOMEquation->toString();
        case Qt::ToolTipRole:
          return QString("<html><div style=\"margin:3px;\">" +
                         QString(mpOMEquation->toString()).toHtmlEscaped()
                         + "</div></html>");
        default:
          return QVariant();
      }
    case 3: // NCall
      switch (role)
      {
        case Qt::DisplayRole:
          return QString::number(mpOMEquation->ncall);
        default:
          return QVariant();
      }
    case 4: // MaxTime
      switch (role)
      {
        case Qt::DisplayRole:
          return QString::number(mpOMEquation->maxTime, 'g', 3);
        case Qt::ToolTipRole:
          return QString("Maximum execution time in a single step.");
        default:
          return QVariant();
      }
    case 5: // Time
      switch (role)
      {
        case Qt::DisplayRole:
          return QString::number(mpOMEquation->time, 'g', 3);
        case Qt::ToolTipRole:
          return QString("Total time excluding the overhead of measuring.");
        default:
          return QVariant();
      }
    case 6: // Fraction
      switch (role)
      {
        case Qt::DisplayRole:
          return QString::number(100 * mpOMEquation->fraction, 'g', 3) + "%";
        case Qt::ToolTipRole:
          return QString("Fraction of time, 100% is the total time of all non-child equations.");
        default:
          return QVariant();
      }
    default:
      return QVariant();
  }
}

int EquationTreeItem::row() const
{
  if (mpParentEquationTreeItem)
    return mpParentEquationTreeItem->mChildren.indexOf(const_cast<EquationTreeItem*>(this));

  return 0;
}

int EquationTreeItem::getEquationIndex()
{
  return mpOMEquation ? mpOMEquation->index : -1;
}

EquationTreeModel::EquationTreeModel(QObject *parent)
  : QAbstractItemModel(parent)
{
  mpRootEquationTreeItem = new EquationTreeItem(nullptr, nullptr, true);
}

/*!
 * \brief EquationTreeModel::columnCount
 * Returns the number of columns for the children of the given parent.\n
 * \param parent
 * \return
 */
int EquationTreeModel::columnCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return 7;
}

/*!
 * \brief EquationTreeModel::rowCount
 * Returns the number of rows under the given parent.\n
 * \param parent
 * \return
 */
int EquationTreeModel::rowCount(const QModelIndex &parent) const
{
  EquationTreeItem *pParentEquationTreeItem;
  if (parent.column() > 0) {
    return 0;
  }

  if (!parent.isValid()) {
    pParentEquationTreeItem = mpRootEquationTreeItem;
  } else {
    pParentEquationTreeItem = static_cast<EquationTreeItem*>(parent.internalPointer());
  }
  return pParentEquationTreeItem ? pParentEquationTreeItem->childrenSize() : 0;
}

/*!
 * \brief EquationTreeModel::headerData
 * Returns the data for the given role and section in the header with the specified orientation.\n
 * \param section
 * \param orientation
 * \param role
 * \return
 */
QVariant EquationTreeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if (role != Qt::DisplayRole || orientation != Qt::Horizontal) return QVariant();
    switch (section) {
    case 0: return "Index";
    case 1: return "Type";
    case 2: return "Equation";
    case 3: return "NCall";
    case 4: return "MaxTime";
    case 5: return "Time";
    case 6: return "Fraction";
    default: return QVariant();
    }
}

/*!
 * \brief EquationTreeModel::index
 * Returns the index of the item in the model specified by the given row, column and parent index.\n
 * \param row
 * \param column
 * \param parent
 * \return
 */
QModelIndex EquationTreeModel::index(int row, int column, const QModelIndex &parent) const
{
  if (!hasIndex(row, column, parent)) {
    return QModelIndex();
  }

  EquationTreeItem *pParentEquationTreeItem;
  if (!parent.isValid()) {
    pParentEquationTreeItem = mpRootEquationTreeItem;
  } else {
    pParentEquationTreeItem = static_cast<EquationTreeItem*>(parent.internalPointer());
  }

  if (row < 0 || row >= pParentEquationTreeItem->childrenSize()) {
    return QModelIndex();
  }

  return createIndex(row, column, pParentEquationTreeItem->child(row));
}

/*!
 * \brief EquationTreeModel::parent
 * Returns the parent of the model item with the given index in the form of a QModelIndex.\n
 * \param child
 * \return
 */
QModelIndex EquationTreeModel::parent(const QModelIndex &index) const
{
  if (!index.isValid()) {
    return QModelIndex();
  }

  EquationTreeItem *pChildEquationTreeItem = static_cast<EquationTreeItem*>(index.internalPointer());
  EquationTreeItem *pParentEquationTreeItem = pChildEquationTreeItem->parent();
  if (pParentEquationTreeItem == mpRootEquationTreeItem)
    return QModelIndex();

  return createIndex(pParentEquationTreeItem->row(), 0, pParentEquationTreeItem);
}

/*!
 * \brief EquationTreeModel::data
 * Returns the data stored under the given role for the item referred to by the index.\n
 * \param index
 * \param role
 * \return
 */
QVariant EquationTreeModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid()) {
    return QVariant();
  }

  EquationTreeItem *pEquationTreeItem = static_cast<EquationTreeItem*>(index.internalPointer());
  return pEquationTreeItem->data(index.column(), role);
}

/*!
 * \brief EquationTreeModel::insertEquations
 * Inserts the equations in the model.\n
 * \param equations
 */
void EquationTreeModel::insertEquations(const QList<OMEquation*>& equations, bool nestedEquations)
{
  beginResetModel();

  mpRootEquationTreeItem->removeChildren();

  // Skip the first equation as it is a dummy equation. see model_info.json {"eqIndex":0,"tag":"dummy"}
  const int start = nestedEquations ? 1 : 0;
  for (int i = start; i < equations.size(); ++i)
  {
    OMEquation *equation = equations[i];

    if (nestedEquations && equation->parent) {
      continue; // Only output equations in one position
    }

    EquationTreeItem *pEquationTreeItem = new EquationTreeItem(equation, mpRootEquationTreeItem);
    mpRootEquationTreeItem->insertChild(mpRootEquationTreeItem->childrenSize(), pEquationTreeItem);

    if (nestedEquations) {
      insertNestedEquations(pEquationTreeItem, i, equations);
    }
  }

  endResetModel();
}

/*!
 * \brief EquationTreeModel::findEquationTreeItem
 * Finds the EquationTreeItem with the given equation index.\n
 * \param equationIndex
 * \param pEquationTreeItem
 * \return
 */
EquationTreeItem *EquationTreeModel::findEquationTreeItem(int equationIndex, EquationTreeItem *pEquationTreeItem) const
{
  if (!pEquationTreeItem) {
    pEquationTreeItem = mpRootEquationTreeItem;
  }

  if (pEquationTreeItem->getEquationIndex() == equationIndex) {
    return pEquationTreeItem;
  }

  for (int i = pEquationTreeItem->childrenSize(); --i >= 0; ) {
    if (EquationTreeItem *item = findEquationTreeItem(equationIndex, pEquationTreeItem->child(i))) {
      return item;
    }
  }
  return nullptr;
}

/*!
 * \brief EquationTreeModel::equationTreeItemIndex
 * Returns the QModelIndex of the given EquationTreeItem.\n
 * \param pEquationTreeItem
 * \return
 */
QModelIndex EquationTreeModel::equationTreeItemIndex(const EquationTreeItem *pEquationTreeItem) const
{
  if (!pEquationTreeItem || pEquationTreeItem == mpRootEquationTreeItem) {
    return QModelIndex();
  }

  return createIndex(pEquationTreeItem->row(), 0, const_cast<EquationTreeItem*>(pEquationTreeItem));
}

void EquationTreeModel::insertNestedEquations(EquationTreeItem *pParentItem, int index, const QList<OMEquation*> &equations)
{
  OMEquation *equation = equations[index];

  for (int nestedIndex : equation->eqs)
  {
    OMEquation *nestedEquation = equations[nestedIndex];

    EquationTreeItem *pNestedItem = new EquationTreeItem(nestedEquation, pParentItem);

    pParentItem->insertChild(pParentItem->childrenSize(), pNestedItem);

    insertNestedEquations(pNestedItem, nestedIndex, equations);
  }
}

/*!
 * \brief EquationTreeView::EquationTreeView
 * Constructor for the EquationTreeView class.\n
 * \param parent
 */
EquationTreeView::EquationTreeView(QWidget *parent)
  : QTreeView(parent)
{
  setItemDelegate(new ItemDelegate(this));
  setTextElideMode(Qt::ElideMiddle);
  setIndentation(Helper::treeIndentation);
  setSortingEnabled(true);
  sortByColumn(0, Qt::AscendingOrder);
  setExpandsOnDoubleClick(false);
  setUniformRowHeights(true);
}

/*!
 * \brief TransformationsWidget::TransformationsWidget
 * \param infoJSONFullFileName - model_info.json file path
 * \param profiling - is profiling enabled
 * \param checkForProfilingFiles - check if profiling files exists
 * \param pParent
 */
TransformationsWidget::TransformationsWidget(QString infoJSONFullFileName, bool profiling, bool checkForProfilingFiles, QWidget *pParent)
  : QWidget(pParent), mInfoJSONFullFileName(infoJSONFullFileName), mProfilingEnabled(profiling), mCheckForProfilingFiles(checkForProfilingFiles)
{
  mCurrentEquationIndex = 0;
  setWindowIcon(QIcon(":/Resources/icons/equational-debugger.svg"));
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::transformationalDebugger));
  QToolButton *pReloadToolButton = new QToolButton;
  pReloadToolButton->setToolTip(Helper::reload);
  pReloadToolButton->setAutoRaise(true);
  pReloadToolButton->setIcon(QIcon(":/Resources/icons/refresh.svg"));
  connect(pReloadToolButton, SIGNAL(clicked()), SLOT(loadTransformations()));
  /* info xml file path label */
  Label *pInfoXMLFilePathLabel = new Label(mInfoJSONFullFileName, this);
  pInfoXMLFilePathLabel->setElideMode(Qt::ElideMiddle);
  /* create status bar */
  QStatusBar *pStatusBar = new QStatusBar;
  pStatusBar->setObjectName("ModelStatusBar");
  pStatusBar->setSizeGripEnabled(false);
  pStatusBar->addPermanentWidget(pReloadToolButton, 0);
  pStatusBar->addPermanentWidget(pInfoXMLFilePathLabel, 1);
  /* Variables Heading */
  Label *pVariableBrowserLabel = new Label(Helper::variableBrowser);
  pVariableBrowserLabel->setObjectName("LabelWithBorder");
  // tree search filters
  mpTreeSearchFilters = new TreeSearchFilters(this);
  mpTreeSearchFilters->getFilterTextBox()->setPlaceholderText(Helper::filterVariables);
  connect(mpTreeSearchFilters->getFilterTextBox(), SIGNAL(returnPressed()), SLOT(findVariables()));
  connect(mpTreeSearchFilters->getFilterTextBox(), SIGNAL(textEdited(QString)), SLOT(findVariables()));
  connect(mpTreeSearchFilters->getCaseSensitiveCheckBox(), SIGNAL(toggled(bool)), SLOT(findVariables()));
  connect(mpTreeSearchFilters->getSyntaxComboBox(), SIGNAL(currentIndexChanged(int)), SLOT(findVariables()));
  /* variables tree view */
  mpTVariablesTreeView = new TVariablesTreeView(this);
  mpTVariablesTreeModel = new TVariablesTreeModel(mpTVariablesTreeView);
  mpTVariableTreeProxyModel = new TVariableTreeProxyModel;
  mpTVariableTreeProxyModel->setDynamicSortFilter(true);
  mpTVariableTreeProxyModel->setSourceModel(mpTVariablesTreeModel);
  mpTVariablesTreeView->setModel(mpTVariableTreeProxyModel);
  mpTVariablesTreeView->setColumnWidth(2, 40);  /* line number column */
  connect(mpTVariablesTreeView, SIGNAL(doubleClicked(QModelIndex)), SLOT(fetchVariableData(QModelIndex)));
  connect(mpTreeSearchFilters->getExpandAllButton(), SIGNAL(clicked()), mpTVariablesTreeView, SLOT(expandAll()));
  connect(mpTreeSearchFilters->getCollapseAllButton(), SIGNAL(clicked()), mpTVariablesTreeView, SLOT(collapseAll()));
  QGridLayout *pVariablesGridLayout = new QGridLayout;
  pVariablesGridLayout->setSpacing(1);
  pVariablesGridLayout->setContentsMargins(0, 0, 0, 0);
  pVariablesGridLayout->addWidget(pVariableBrowserLabel, 0, 0);
  pVariablesGridLayout->addWidget(mpTreeSearchFilters, 1, 0);
  pVariablesGridLayout->addWidget(mpTVariablesTreeView, 2, 0);
  QFrame *pVariablesFrame = new QFrame;
  pVariablesFrame->setLayout(pVariablesGridLayout);
  /* Defined in tree view */
  Label *pDefinedInLabel = new Label(tr("Defined In Equations"));
  pDefinedInLabel->setObjectName("LabelWithBorder");
  mpDefinedInEquationTreeModel = new EquationTreeModel(this);
  mpDefinedInEquationTreeView = new EquationTreeView(this);
  mpDefinedInEquationTreeView->setModel(mpDefinedInEquationTreeModel);
  connect(mpDefinedInEquationTreeView, SIGNAL(doubleClicked(QModelIndex)), SLOT(fetchEquationData(QModelIndex)));
  QGridLayout *pDefinedInGridLayout = new QGridLayout;
  pDefinedInGridLayout->setSpacing(1);
  pDefinedInGridLayout->setContentsMargins(0, 0, 0, 0);
  pDefinedInGridLayout->addWidget(pDefinedInLabel, 0, 0);
  pDefinedInGridLayout->addWidget(mpDefinedInEquationTreeView, 1, 0);
  QFrame *pDefinedInFrame = new QFrame;
  pDefinedInFrame->setLayout(pDefinedInGridLayout);
  /* Used in tree widget  */
  Label *pUsedInLabel = new Label(tr("Used In Equations"));
  pUsedInLabel->setObjectName("LabelWithBorder");
  mpUsedInEquationTreeModel = new EquationTreeModel(this);
  mpUsedInEquationTreeView = new EquationTreeView(this);
  mpUsedInEquationTreeView->setModel(mpUsedInEquationTreeModel);
  connect(mpUsedInEquationTreeView, SIGNAL(doubleClicked(QModelIndex)), SLOT(fetchEquationData(QModelIndex)));
  QGridLayout *pUsedInGridLayout = new QGridLayout;
  pUsedInGridLayout->setSpacing(1);
  pUsedInGridLayout->setContentsMargins(0, 0, 0, 0);
  pUsedInGridLayout->addWidget(pUsedInLabel, 0, 0);
  pUsedInGridLayout->addWidget(mpUsedInEquationTreeView, 1, 0);
  QFrame *pUsedInFrame = new QFrame;
  pUsedInFrame->setLayout(pUsedInGridLayout);
  /* variable operations tree widget */
  Label *pOperationsLabel = new Label(tr("Variable Operations"));
  pOperationsLabel->setObjectName("LabelWithBorder");
  mpVariableOperationsTreeWidget = new QTreeWidget;
  mpVariableOperationsTreeWidget->setItemDelegate(new ItemDelegate(mpVariableOperationsTreeWidget));
  mpVariableOperationsTreeWidget->setIndentation(0);
  mpVariableOperationsTreeWidget->setColumnCount(1);
  mpVariableOperationsTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpVariableOperationsTreeWidget->setHeaderLabel(tr("Operations"));
  QGridLayout *pVariableOperationsGridLayout = new QGridLayout;
  pVariableOperationsGridLayout->setSpacing(1);
  pVariableOperationsGridLayout->setContentsMargins(0, 0, 0, 0);
  pVariableOperationsGridLayout->addWidget(pOperationsLabel, 0, 0);
  pVariableOperationsGridLayout->addWidget(mpVariableOperationsTreeWidget, 1, 0);
  QFrame *pVariableOperationsFrame = new QFrame;
  pVariableOperationsFrame->setLayout(pVariableOperationsGridLayout);
  /* Equations Heading */
  Label *pEquationBrowserLabel = new Label(tr("Equations"));
  pEquationBrowserLabel->setObjectName("LabelWithBorder");
  /* Equations tree view */
  mpEquationTreeModel = new EquationTreeModel(this);
  mpEquationTreeView = new EquationTreeView(this);
  mpEquationTreeView->setModel(mpEquationTreeModel);
  connect(mpEquationTreeView, SIGNAL(doubleClicked(QModelIndex)), SLOT(fetchEquationData(QModelIndex)));
  QGridLayout *pEquationsGridLayout = new QGridLayout;
  pEquationsGridLayout->setSpacing(1);
  pEquationsGridLayout->setContentsMargins(0, 0, 0, 0);
  pEquationsGridLayout->addWidget(pEquationBrowserLabel, 0, 0);
  pEquationsGridLayout->addWidget(mpEquationTreeView, 1, 0);
  QFrame *pEquationsFrame = new QFrame;
  pEquationsFrame->setLayout(pEquationsGridLayout);
  /* defines tree widget */
  Label *pDefinesLabel = new Label(tr("Defines"));
  pDefinesLabel->setObjectName("LabelWithBorder");
  mpDefinesVariableTreeWidget = new QTreeWidget;
  mpDefinesVariableTreeWidget->setItemDelegate(new ItemDelegate(mpDefinesVariableTreeWidget));
  mpDefinesVariableTreeWidget->setIndentation(0);
  mpDefinesVariableTreeWidget->setColumnCount(1);
  mpDefinesVariableTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpDefinesVariableTreeWidget->setSortingEnabled(true);
  mpDefinesVariableTreeWidget->sortByColumn(0, Qt::AscendingOrder);
  QStringList headerLabels;
  headerLabels << tr("Variable");
  mpDefinesVariableTreeWidget->setHeaderLabels(headerLabels);
  QGridLayout *pDefinesGridLayout = new QGridLayout;
  pDefinesGridLayout->setSpacing(1);
  pDefinesGridLayout->setContentsMargins(0, 0, 0, 0);
  pDefinesGridLayout->addWidget(pDefinesLabel, 0, 0);
  pDefinesGridLayout->addWidget(mpDefinesVariableTreeWidget, 1, 0);
  QFrame *pDefinesFrame = new QFrame;
  pDefinesFrame->setLayout(pDefinesGridLayout);
  /* depends tree widget */
  Label *pDependsLabel = new Label(tr("Depends"));
  pDependsLabel->setObjectName("LabelWithBorder");
  mpDependsVariableTreeWidget = new QTreeWidget;
  mpDependsVariableTreeWidget->setItemDelegate(new ItemDelegate(mpDependsVariableTreeWidget));
  mpDependsVariableTreeWidget->setIndentation(0);
  mpDependsVariableTreeWidget->setColumnCount(1);
  mpDependsVariableTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpDependsVariableTreeWidget->setSortingEnabled(true);
  mpDependsVariableTreeWidget->sortByColumn(0, Qt::AscendingOrder);
  mpDependsVariableTreeWidget->setHeaderLabel(tr("Variable"));
  QGridLayout *pDependsGridLayout = new QGridLayout;
  pDependsGridLayout->setSpacing(1);
  pDependsGridLayout->setContentsMargins(0, 0, 0, 0);
  pDependsGridLayout->addWidget(pDependsLabel, 0, 0);
  pDependsGridLayout->addWidget(mpDependsVariableTreeWidget, 1, 0);
  QFrame *pDependsFrame = new QFrame;
  pDependsFrame->setLayout(pDependsGridLayout);
  /* operations tree widget */
  Label *pEquationOperationsLabel = new Label(tr("Equation Operations"));
  pEquationOperationsLabel->setObjectName("LabelWithBorder");
  mpEquationDiffFilterComboBox = new QComboBox;
  mpEquationDiffFilterComboBox->addItem(tr("Diff"), HtmlDiff::Both);
  mpEquationDiffFilterComboBox->addItem(tr("After"), HtmlDiff::Insertion);
  mpEquationDiffFilterComboBox->addItem(tr("Before"), HtmlDiff::Deletion);
  connect(mpEquationDiffFilterComboBox, SIGNAL(currentIndexChanged(int)), SLOT(filterEquationOperations(int)));
  QHBoxLayout *pEquationTransformationFilterLayout = new QHBoxLayout;
  pEquationTransformationFilterLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pEquationTransformationFilterLayout->addWidget(new Label(tr("Transformation:")));
  pEquationTransformationFilterLayout->addWidget(mpEquationDiffFilterComboBox);
  mpEquationOperationsTreeWidget = new QTreeWidget;
  mpEquationOperationsTreeWidget->setItemDelegate(new ItemDelegate(mpEquationOperationsTreeWidget));
  mpEquationOperationsTreeWidget->setIndentation(0);
  mpEquationOperationsTreeWidget->setColumnCount(1);
  mpEquationOperationsTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpEquationOperationsTreeWidget->setHeaderLabel(tr("Operations"));
  QGridLayout *pEquationOperationsGridLayout = new QGridLayout;
  pEquationOperationsGridLayout->setSpacing(1);
  pEquationOperationsGridLayout->setContentsMargins(0, 0, 0, 0);
  pEquationOperationsGridLayout->addWidget(pEquationOperationsLabel, 0, 0);
  pEquationOperationsGridLayout->addLayout(pEquationTransformationFilterLayout, 1, 0, Qt::AlignLeft);
  pEquationOperationsGridLayout->addWidget(mpEquationOperationsTreeWidget, 2, 0);
  QFrame *pEquationOperationsFrame = new QFrame;
  pEquationOperationsFrame->setLayout(pEquationOperationsGridLayout);
  /* TSourceEditor */
  Label *pTSourceEditorBrowserLabel = new Label(tr("Source Browser"));
  pTSourceEditorBrowserLabel->setObjectName("LabelWithBorder");
  mpTSourceEditorFileLabel = new Label("");
  mpTSourceEditorFileLabel->setElideMode(Qt::ElideMiddle);
  mpTSourceEditorFileLabel->hide();
  mpTSourceEditorInfoBar = new InfoBar(this);
  mpTSourceEditorInfoBar->hide();
  mpTransformationsEditor = new TransformationsEditor(this);
  ModelicaHighlighter *pModelicaTextHighlighter;
  pModelicaTextHighlighter = new ModelicaHighlighter(OptionsDialog::instance()->getModelicaEditorPage(),
                                                     mpTransformationsEditor->getPlainTextEdit());
  connect(OptionsDialog::instance(), SIGNAL(modelicaEditorSettingsChanged()), pModelicaTextHighlighter, SLOT(settingsChanged()));
  QVBoxLayout *pTSourceEditorVerticalLayout = new QVBoxLayout;
  pTSourceEditorVerticalLayout->setSpacing(1);
  pTSourceEditorVerticalLayout->setContentsMargins(0, 0, 0, 0);
  pTSourceEditorVerticalLayout->addWidget(pTSourceEditorBrowserLabel);
  pTSourceEditorVerticalLayout->addWidget(mpTSourceEditorFileLabel);
  pTSourceEditorVerticalLayout->addWidget(mpTSourceEditorInfoBar);
  pTSourceEditorVerticalLayout->addWidget(mpTransformationsEditor);
  QFrame *pTSourceEditorFrame = new QFrame;
  pTSourceEditorFrame->setLayout(pTSourceEditorVerticalLayout);
  /* variables nested horizontal splitter */
  mpVariablesNestedHorizontalSplitter = new QSplitter;
  mpVariablesNestedHorizontalSplitter->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
  mpVariablesNestedHorizontalSplitter->setChildrenCollapsible(false);
  mpVariablesNestedHorizontalSplitter->setHandleWidth(4);
  mpVariablesNestedHorizontalSplitter->setContentsMargins(0, 0, 0, 0);
  mpVariablesNestedHorizontalSplitter->addWidget(pDefinedInFrame);
  mpVariablesNestedHorizontalSplitter->addWidget(pUsedInFrame);
  /* variables vertical splitter */
  mpVariablesNestedVerticalSplitter = new QSplitter;
  mpVariablesNestedVerticalSplitter->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
  mpVariablesNestedVerticalSplitter->setOrientation(Qt::Vertical);
  mpVariablesNestedVerticalSplitter->setChildrenCollapsible(false);
  mpVariablesNestedVerticalSplitter->setHandleWidth(4);
  mpVariablesNestedVerticalSplitter->setContentsMargins(0, 0, 0, 0);
  mpVariablesNestedVerticalSplitter->addWidget(mpVariablesNestedHorizontalSplitter);
  mpVariablesNestedVerticalSplitter->addWidget(pVariableOperationsFrame);
  /* variables horizontal splitter */
  mpVariablesHorizontalSplitter = new QSplitter;
  mpVariablesHorizontalSplitter->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
  mpVariablesHorizontalSplitter->setChildrenCollapsible(false);
  mpVariablesHorizontalSplitter->setHandleWidth(4);
  mpVariablesHorizontalSplitter->setContentsMargins(0, 0, 0, 0);
  mpVariablesHorizontalSplitter->addWidget(pVariablesFrame);
  mpVariablesHorizontalSplitter->addWidget(mpVariablesNestedVerticalSplitter);
  Label *pVariablesHeadingLabel = new Label(Helper::variables);
  pVariablesHeadingLabel->setObjectName("LabelWithBorder");
  QVBoxLayout *pVariablesMainLayout = new QVBoxLayout;
  pVariablesMainLayout->setSpacing(1);
  pVariablesMainLayout->setContentsMargins(0, 0, 0, 0);
  pVariablesMainLayout->addWidget(pVariablesHeadingLabel);
  pVariablesMainLayout->addWidget(mpVariablesHorizontalSplitter);
  QFrame *pVariablesMainFrame = new QFrame;
  pVariablesMainFrame->setLayout(pVariablesMainLayout);
  /* Equations nested horizontal splitter */
  mpEquationsNestedHorizontalSplitter = new QSplitter;
  mpEquationsNestedHorizontalSplitter->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
  mpEquationsNestedHorizontalSplitter->setChildrenCollapsible(false);
  mpEquationsNestedHorizontalSplitter->setHandleWidth(4);
  mpEquationsNestedHorizontalSplitter->setContentsMargins(0, 0, 0, 0);
  mpEquationsNestedHorizontalSplitter->addWidget(pDefinesFrame);
  mpEquationsNestedHorizontalSplitter->addWidget(pDependsFrame);
  /* Equations nested vertical splitter */
  mpEquationsNestedVerticalSplitter = new QSplitter;
  mpEquationsNestedVerticalSplitter->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
  mpEquationsNestedVerticalSplitter->setOrientation(Qt::Vertical);
  mpEquationsNestedVerticalSplitter->setChildrenCollapsible(false);
  mpEquationsNestedVerticalSplitter->setHandleWidth(4);
  mpEquationsNestedVerticalSplitter->setContentsMargins(0, 0, 0, 0);
  mpEquationsNestedVerticalSplitter->addWidget(mpEquationsNestedHorizontalSplitter);
  mpEquationsNestedVerticalSplitter->addWidget(pEquationOperationsFrame);
  /* equations horizontal splitter */
  mpEquationsHorizontalSplitter = new QSplitter;
  mpEquationsHorizontalSplitter->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
  mpEquationsHorizontalSplitter->setChildrenCollapsible(false);
  mpEquationsHorizontalSplitter->setHandleWidth(4);
  mpEquationsHorizontalSplitter->setContentsMargins(0, 0, 0, 0);
  mpEquationsHorizontalSplitter->addWidget(pEquationsFrame);
  mpEquationsHorizontalSplitter->addWidget(mpEquationsNestedVerticalSplitter);
  Label *pEquationsHeadingLabel = new Label(tr("Equations"));
  pEquationsHeadingLabel->setObjectName("LabelWithBorder");
  QVBoxLayout *pEquationsMainLayout = new QVBoxLayout;
  pEquationsMainLayout->setSpacing(1);
  pEquationsMainLayout->setContentsMargins(0, 0, 0, 0);
  pEquationsMainLayout->addWidget(pEquationsHeadingLabel);
  pEquationsMainLayout->addWidget(mpEquationsHorizontalSplitter);
  QFrame *pEquationsMainFrame = new QFrame;
  pEquationsMainFrame->setLayout(pEquationsMainLayout);
  /* Transformations vertical splitter */
  mpTransformationsVerticalSplitter = new QSplitter;
  mpTransformationsVerticalSplitter->setObjectName("TransformationsVerticalSplitter");
  mpTransformationsVerticalSplitter->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
  mpTransformationsVerticalSplitter->setOrientation(Qt::Vertical);
  mpTransformationsVerticalSplitter->setChildrenCollapsible(false);
  mpTransformationsVerticalSplitter->setHandleWidth(4);
  mpTransformationsVerticalSplitter->setContentsMargins(0, 0, 0, 0);
  mpTransformationsVerticalSplitter->addWidget(pTSourceEditorFrame);
  mpTransformationsVerticalSplitter->addWidget(pVariablesMainFrame);
  mpTransformationsVerticalSplitter->addWidget(pEquationsMainFrame);
  /* Load the transformations before setting the layout */
  loadTransformations();
  /* set the layout */
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(pStatusBar, 0, 0);
  pMainLayout->addWidget(mpTransformationsVerticalSplitter, 1, 0);
  setLayout(pMainLayout);
  /* restore the TransformationsWidget geometry and splitters state. */
  QSettings *pSettings = Utilities::getApplicationSettings();
  if (OptionsDialog::instance()->getGeneralSettingsPage()->getPreserveUserCustomizations())
  {
    pSettings->beginGroup("transformationalDebugger");
    restoreGeometry(pSettings->value("geometry").toByteArray());
    mpVariablesNestedHorizontalSplitter->restoreState(pSettings->value("variablesNestedHorizontalSplitter").toByteArray());
    mpVariablesNestedVerticalSplitter->restoreState(pSettings->value("variablesNestedVerticalSplitter").toByteArray());
    mpVariablesHorizontalSplitter->restoreState(pSettings->value("variablesHorizontalSplitter").toByteArray());
    mpEquationsNestedHorizontalSplitter->restoreState(pSettings->value("equationsNestedHorizontalSplitter").toByteArray());
    mpEquationsNestedVerticalSplitter->restoreState(pSettings->value("equationsNestedVerticalSplitter").toByteArray());
    mpEquationsHorizontalSplitter->restoreState(pSettings->value("equationsHorizontalSplitter").toByteArray());
    mpTransformationsVerticalSplitter->restoreState(pSettings->value("transformationsVerticalSplitter").toByteArray());
    pSettings->endGroup();
  }
}

TransformationsWidget::~TransformationsWidget()
{
  if (mpInfoXMLFileHandler) {
    delete mpInfoXMLFileHandler;
  }
  qDeleteAll(mEquations);
}

/*!
 * \brief simdjsonToOperationPtr
 * Transforms a simdjson::ondemand::object to an OMOperation pointer.\n
 * \param var
 * \return
 */
static OMOperation* simdjsonToOperationPtr(simdjson::ondemand::object &var)
{
  std::string_view sv;
  QString op;
  if (!var["op"].get(sv)) {
    op = QString::fromUtf8(sv.data(), sv.size());
  }

  QString display;
  if (!var["display"].get(sv)) {
    display = QString::fromUtf8(sv.data(), sv.size());
  }

  QString name = display.isEmpty() ? op : display;

  QStringList dataStrings;
  simdjson::ondemand::array data;
  if (!var["data"].get(data)) {
    for (simdjson::ondemand::value v : data) {
      if (!v.get(sv)) {
        dataStrings << QString::fromUtf8(sv.data(), sv.size());
      }
    }
  }

  if (op == "before-after" || op == "before-after-assert") {
    return new OMOperationBeforeAfter(name, dataStrings);
  } else if (op == "chain") {
    QStringList firstLast;
    if (!dataStrings.isEmpty()) {
      firstLast << dataStrings.first() << dataStrings.last();
    }
    return new OMOperationBeforeAfter(name, firstLast);
  } else if (op == "info") {
    return new OMOperationInfo(name, dataStrings.join(", "));
  }
  return nullptr;
}

/*!
 * \brief simdjsonToSource
 * Transforms a simdjson::ondemand::object to source information and operations.\n
 * \param source
 * \param info
 * \param ops
 * \return
 */
static bool simdjsonToSource(simdjson::ondemand::object &source, OMInfo &info, QList<OMOperation*> &ops)
{
  bool hasOperations = false;

  simdjson::ondemand::object vinfo;
  if (!source["info"].get(vinfo)) {
    std::string_view sv;
    int64_t iv;
    if (!vinfo["file"].get(sv)) {
      info.file = QString::fromUtf8(sv.data(), sv.size());
    }
    if (!vinfo["lineStart"].get(iv)) {
      info.lineStart = (int)iv;
    }
    if (!vinfo["lineEnd"].get(iv)) {
      info.lineEnd = (int)iv;
    }
    if (!vinfo["colStart"].get(iv)) {
      info.colStart = (int)iv;
    }
    if (!vinfo["colEnd"].get(iv)) {
      info.colEnd = (int)iv;
    }
    info.isValid = true;
  }

  simdjson::ondemand::array vops;
  if (!source["operations"].get(vops)) {
    hasOperations = true;
    for (simdjson::ondemand::value vop : vops) {
      simdjson::ondemand::object opObj;
      if (!vop.get(opObj)) {
        OMOperation *op = simdjsonToOperationPtr(opObj);
        if (op) {
          ops << op;
        }
      }
    }
  }
  return hasOperations;
}

static OMEquation* getOMEquation(QList<OMEquation*> equations, int index)
{
  for (int i = 1 ; i < equations.size() ; i++) {
    if (equations[i]->index == index) {
      return equations[i];
    }
  }
  return NULL;
}

/*!
 * \brief TransformationsWidget::loadTransformations
 * \param profiling - is profiling enabled
 * \param checkForProfilingFiles - check if profiling files exists
 */
void TransformationsWidget::loadTransformations(bool profiling, bool checkForProfilingFiles)
{
  mProfilingEnabled = profiling;
  mCheckForProfilingFiles = checkForProfilingFiles;
  loadTransformations();
}

/*!
 * \brief TransformationsWidget::fetchDefinedInEquations
 * Fetches the equations in which the variable is defined and inserts them in the Defined In tree view.\n
 * \param variable
 */
void TransformationsWidget::fetchDefinedInEquations(const OMVariable &variable)
{
  // Fetch the equations in which the variable is defined.
  QList<OMEquation*> equations;
  for (int i=0; i<variable.definedIn.size(); i++) {
    OMEquation *equation = getOMEquation(mEquations, variable.definedIn[i]);
    if (equation) {
      equations << equation;
    }
  }
  mpDefinedInEquationTreeModel->insertEquations(equations, false);
}

/*!
 * \brief TransformationsWidget::fetchUsedInEquations
 * Fetches the equations in which the variable is used and inserts them in the Used In tree view.\n
 * \param variable
 */
void TransformationsWidget::fetchUsedInEquations(const OMVariable &variable)
{
  // Fetch the equations in which the variable is used.
  QList<OMEquation*> equations;
  foreach (int index, variable.usedIn) {
    OMEquation *equation = getOMEquation(mEquations, index);
    if (equation) {
      equations << equation;
    }
  }
  mpUsedInEquationTreeModel->insertEquations(equations, false);
}

void TransformationsWidget::fetchOperations(const OMVariable &variable)
{
  /* Clear the operations tree. */
  clearTreeWidgetItems(mpVariableOperationsTreeWidget);
  /* add operations */
  if (hasOperationsEnabled) {
    foreach (OMOperation *op, variable.ops) {
      QTreeWidgetItem *pOperationTreeItem = new QTreeWidgetItem();
      mpVariableOperationsTreeWidget->addTopLevelItem(pOperationTreeItem);
      // set label item
      Label *opText = new Label("<html><div style=\"margin:3px;\">" + op->toHtml() + "</div></html>");
      mpVariableOperationsTreeWidget->setItemWidget(pOperationTreeItem, 0, opText);
    }
  } else {
    QString message = GUIMessages::getMessage(GUIMessages::SET_INFO_XML_FLAG).arg(Helper::toolsOptionsPath);
    QStringList values;
    values << message;
    QString toolTip = message;
    QTreeWidgetItem *pOperationTreeItem = new QTreeWidgetItem(values);
    pOperationTreeItem->setToolTip(0, toolTip);
    mpVariableOperationsTreeWidget->addTopLevelItem(pOperationTreeItem);
  }
  mpVariableOperationsTreeWidget->resizeColumnToContents(0);
}

/*!
 * \brief TransformationsWidget::loadTransformations
 * Loads the transformations from the model_info.json file.
 */
void TransformationsWidget::loadTransformations()
{
  mCurrentEquationIndex = 0;
  /* clear trees */
  mpTVariablesTreeModel->clearTVariablesTreeItems();
  /* Clear the variable operations tree. */
  clearTreeWidgetItems(mpVariableOperationsTreeWidget);
  /* clear the variable tree filters. */
  bool signalsState = mpTreeSearchFilters->getFilterTextBox()->blockSignals(true);
  mpTreeSearchFilters->getFilterTextBox()->clear();
  mpTreeSearchFilters->getFilterTextBox()->blockSignals(signalsState);
  signalsState = mpTreeSearchFilters->getSyntaxComboBox()->blockSignals(true);
  mpTreeSearchFilters->getSyntaxComboBox()->setCurrentIndex(0);
  mpTreeSearchFilters->getSyntaxComboBox()->blockSignals(signalsState);
  signalsState = mpTreeSearchFilters->getCaseSensitiveCheckBox()->blockSignals(true);
  mpTreeSearchFilters->getCaseSensitiveCheckBox()->setChecked(false);
  mpTreeSearchFilters->getCaseSensitiveCheckBox()->blockSignals(signalsState);
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  mpTVariableTreeProxyModel->setFilterRegularExpression(QRegularExpression());
#else
  mpTVariableTreeProxyModel->setFilterRegExp(QRegExp());
#endif
  /* clear equation operations tree */
  clearTreeWidgetItems(mpEquationOperationsTreeWidget);
  /* clear TSourceEditor */
  mpTSourceEditorFileLabel->setText("");
  mpTSourceEditorFileLabel->hide();
  mpTransformationsEditor->getPlainTextEdit()->clear();
  mpTSourceEditorInfoBar->hide();
  /* initialize all fields again */
  mProfilingJSONFullFileName = "";
  /* check if profiling is enabled or checkProfilingExists is true then check if the profiling files exists
   * if user enabled profiling in the SimulationSetup then profiling will be true
   * checkProfilingExists is true when user opens the transformation file
   */
  if (mProfilingEnabled || mCheckForProfilingFiles) {
    QString profilingJSONFileName = mInfoJSONFullFileName.left(mInfoJSONFullFileName.size() - 9) + "prof.json";
    if (QFile::exists(profilingJSONFileName)) {
      mProfilingJSONFullFileName = profilingJSONFileName;
    }
  }
  qDeleteAll(mEquations);
  mEquations.clear();
  mVariables.clear();
  hasOperationsEnabled = false;

  if (mInfoJSONFullFileName.endsWith(".json")) {
    // Load file into simdjson padded buffer
    simdjson::ondemand::parser parser;
    simdjson::padded_string jsonStr;

    auto loadResult = simdjson::padded_string::load(mInfoJSONFullFileName.toStdString());
    if (loadResult.error()) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                            QString("Failed to load file %1: %2").arg(mInfoJSONFullFileName,
                                                                                                      QString::fromUtf8(simdjson::error_message(loadResult.error()))),
                                                            Helper::scriptingKind, Helper::errorLevel));
      MainWindow::instance()->printStandardOutAndErrorFilesMessages();
      return;
    }
    jsonStr = std::move(loadResult.value());

    simdjson::ondemand::document doc;
    if (parser.iterate(jsonStr).get(doc)) {
      MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                            QString("Failed to parse JSON %1").arg(mInfoJSONFullFileName),
                                                            Helper::scriptingKind, Helper::errorLevel));
      MainWindow::instance()->printStandardOutAndErrorFilesMessages();
      return;
    }
    // Parse variables
    simdjson::ondemand::object varsObj;
    if (!doc["variables"].get(varsObj)) {
      for (simdjson::ondemand::field field : varsObj) {
        std::string_view key = field.unescaped_key();
        QString name = QString::fromUtf8(key.data(), key.size());

        simdjson::ondemand::object valueObject;
        if (!field.value().get(valueObject)) {
          OMVariable var;
          var.name = name;

          std::string_view sv;
          if (!valueObject["comment"].get(sv)) {
            var.comment = QString::fromUtf8(sv.data(), sv.size());
          }

          simdjson::ondemand::object sourceObject;
          if (!valueObject["source"].get(sourceObject)) {
            bool hasOperations = simdjsonToSource(sourceObject, var.info, var.ops);
            if (!hasOperationsEnabled && hasOperations) {
              hasOperationsEnabled = true;
            }
          }

          mVariables[name] = std::move(var);
        }
      }
    }
    mpTVariablesTreeModel->insertTVariablesItems(mVariables);

    // Parse equations
    simdjson::ondemand::array eqsArr;
    if (!doc["equations"].get(eqsArr)) {
      int eqsCount = (int)eqsArr.count_elements();
      mEquations.reserve(eqsCount);
      for (int i = 0; i < eqsCount; i++) {
        mEquations << new OMEquation();
      }
      int i = 0;
      for (simdjson::ondemand::value eqVal : eqsArr) {
        simdjson::ondemand::object veq;
        if (!eqVal.get(veq)) {
          OMEquation *eq = mEquations[i];

          eq->index = i;
          eq->profileBlock = -1;

          std::string_view sv;
          int64_t iv;

          if (!veq["section"].get(sv)) {
            eq->section = QString::fromUtf8(sv.data(), sv.size());
          }
          if (!veq["tag"].get(sv)) {
            eq->tag = QString::fromUtf8(sv.data(), sv.size());
          }
          if (!veq["unknowns"].get(iv)) {
            eq->unknowns = (int)iv;
          }

          // eqIndex sanity check
          int64_t eqIndex = 0;
          if (!veq["eqIndex"].get(eqIndex) && (int)eqIndex != i) {
            QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::parsingFailedJson),
                                  Helper::parsingFailedJson + QString(": got index ") + QString::number((int)eqIndex) + QString(" expected ") + QString::number(i),
                                  QMessageBox::Ok);
            return;
          }
          // parent
          int64_t parent;
          if (!veq["parent"].get(parent)) {
            eq->parent = (int)parent;
            mEquations[eq->parent]->eqs << eq->index;
          } else {
            eq->parent = 0;
          }
          // defines
          simdjson::ondemand::array arr;
          if (!veq["defines"].get(arr)) {
            for (simdjson::ondemand::value v : arr) {
              if (!v.get(sv)) {
                QString vname = QString::fromUtf8(sv.data(), sv.size());
                eq->defines << vname;
                mVariables[vname].definedIn << eq->index;
              }
            }
          }
          // uses
          if (!veq["uses"].get(arr)) {
            for (simdjson::ondemand::value v : arr) {
              if (!v.get(sv)) {
                QString vname = QString::fromUtf8(sv.data(), sv.size());
                eq->depends << vname;
                mVariables[vname].usedIn << eq->index;
              }
            }
          }
          // display
          if (!veq["display"].get(sv)) {
            eq->display = QString::fromUtf8(sv.data(), sv.size());
          } else {
            eq->display = eq->tag;
          }
          // equation text
          if (!veq["equation"].get(arr)) {
            for (simdjson::ondemand::value v : arr) {
              if (!v.get(sv)) {
                eq->text << QString::fromUtf8(sv.data(), sv.size());
              }
            }
          }
          // source
          simdjson::ondemand::object sourceObject;
          if (!veq["source"].get(sourceObject)) {
            bool hasOperations = simdjsonToSource(sourceObject, eq->info, eq->ops);
            if (!hasOperationsEnabled && hasOperations) {
              hasOperationsEnabled = true;
            }
          }
          i++;
        }
      }
    }

    parseProfiling(mProfilingJSONFullFileName);
    mpEquationTreeModel->insertEquations(mEquations, true);
  } else {
    QFile file(mInfoJSONFullFileName);
    mpInfoXMLFileHandler = new MyHandler(file,mVariables,mEquations);
    mpTVariablesTreeModel->insertTVariablesItems(mVariables);
    /* load equations */
    parseProfiling(mProfilingJSONFullFileName);
    mpEquationTreeModel->insertEquations(mEquations, true);
    hasOperationsEnabled = mpInfoXMLFileHandler->hasOperationsEnabled;
  }
  fetchVariableData(mpTVariableTreeProxyModel->index(0, 0));
}

EquationTreeItem* TransformationsWidget::findEquationTreeItem(int equationIndex)
{
  return mpEquationTreeModel->findEquationTreeItem(equationIndex);
}

#include <qwt_plot.h>

/*!
 * \brief TransformationsWidget::selectEquation
 * Selects the equation in the equations tree view and scrolls to it.
 * \param equationIndex
 */
void TransformationsWidget::selectEquation(int equationIndex)
{
  EquationTreeItem *pEquationTreeItem = findEquationTreeItem(equationIndex);
  if (pEquationTreeItem) {
    mpEquationTreeView->clearSelection();
    QModelIndex idx = mpEquationTreeModel->equationTreeItemIndex(pEquationTreeItem);
    mpEquationTreeView->setCurrentIndex(idx);
    mpEquationTreeView->scrollTo(idx);
  }
}

void TransformationsWidget::fetchEquationData(int equationIndex)
{
  OMEquation *equation = getOMEquation(mEquations, equationIndex);
  if (!equation) {
    return;
  }
  mCurrentEquationIndex = equationIndex;
  /* fetch defines */
  fetchDefines(equation);
  /* fetch depends */
  fetchDepends(equation);
  /* fetch operations */
  fetchOperations(equation, (HtmlDiff)mpEquationDiffFilterComboBox->itemData(mpEquationDiffFilterComboBox->currentIndex()).toInt());

  /* TODO: This data is correct. Add this to some widget thingy somewhere.
   * Maybe a small one that you can click to enlarge.
   * Also add the count one (Model_prof.intdata)
   */
#if 0
  if (equation->profileBlock >= 0) {
    QFile file(mProfilingDataRealFileName);
    if (file.open(QIODevice::ReadOnly)) {

      QwtPlot *w;
      long c1;
      w = new QwtPlot();

      size_t rowSize = sizeof(double) * profilingNumSteps;
      file.seek(0);
      QByteArray datax = file.read(rowSize);
      file.seek((equation->profileBlock+2) * rowSize);
      QByteArray datay = file.read(rowSize);
      double *x = (double*)datax.data();
      double *y = (double*)datay.data();

      QwtPlotCurve *curve = new QwtPlotCurve("Curve 1");

      curve->setData(x, y, profilingNumSteps);
      curve->attach(w);
      w->replot();
      w->show();
    }
  } else {
    qDebug() << equation->profileBlock;
  }
#endif

  if (!equation->info.isValid) {
    return;
  }
  /* open the model with and go to the equation line */
  QString fileName = equation->info.file;
  QFileInfo fileInfo(fileName);
  if (fileInfo.isRelative()) {
    // find the class
    LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(fileName);
    if (pLibraryTreeItem) {
      fileName = pLibraryTreeItem->getFileName();
    }
  }
  QFile file(fileName);
  if (file.open(QIODevice::ReadOnly)) {
    mpTSourceEditorFileLabel->setText(file.fileName());
    mpTSourceEditorFileLabel->show();
    mpTransformationsEditor->getPlainTextEdit()->setPlainText(QString(file.readAll()));
    mpTSourceEditorInfoBar->hide();
    file.close();
    mpTransformationsEditor->getPlainTextEdit()->goToLineNumber(equation->info.lineStart);
    mpTransformationsEditor->getPlainTextEdit()->foldAll();
  }
}

void TransformationsWidget::fetchDefines(OMEquation *equation)
{
  /* Clear the defines tree. */
  clearTreeWidgetItems(mpDefinesVariableTreeWidget);
  /* add defines */
  if (equation) {
    foreach (QString define, equation->defines) {
      QStringList values;
      values << define;
      QString toolTip = define;
      QTreeWidgetItem *pDefineTreeItem = new QTreeWidgetItem(values);
      pDefineTreeItem->setToolTip(0, toolTip);
      mpDefinesVariableTreeWidget->addTopLevelItem(pDefineTreeItem);
    }
    if ((equation->tag.compare("residual") == 0) && (equation->defines.isEmpty())) {
      QStringList values;
      values << QString("Part of an implicit system of equations");
      QString toolTip = values.at(0);
      QTreeWidgetItem *pDefineTreeItem = new QTreeWidgetItem(values);
      pDefineTreeItem->setToolTip(0, toolTip);
      mpDefinesVariableTreeWidget->addTopLevelItem(pDefineTreeItem);
    }
    mpDefinesVariableTreeWidget->resizeColumnToContents(0);
  }
}

void TransformationsWidget::fetchDepends(OMEquation *equation)
{
  /* Clear the depends tree. */
  clearTreeWidgetItems(mpDependsVariableTreeWidget);
  /* add depends */
  if (equation) {
    foreach (QString depend, equation->depends) {
      QStringList values;
      values << depend;
      QString toolTip = depend;
      QTreeWidgetItem *pDependTreeItem = new QTreeWidgetItem(values);
      pDependTreeItem->setToolTip(0, toolTip);
      mpDependsVariableTreeWidget->addTopLevelItem(pDependTreeItem);
    }
    mpDependsVariableTreeWidget->resizeColumnToContents(0);
  }
}

void TransformationsWidget::fetchOperations(OMEquation *equation, HtmlDiff htmlDiff)
{
  /* Clear the operations tree. */
  clearTreeWidgetItems(mpEquationOperationsTreeWidget);
  /* add operations */
  if (hasOperationsEnabled) {
    if (equation) {
      foreach (OMOperation *op, equation->ops) {
        QTreeWidgetItem *pOperationTreeItem = new QTreeWidgetItem();
        mpEquationOperationsTreeWidget->addTopLevelItem(pOperationTreeItem);
        // set label item
        Label *opText = new Label("<html><div style=\"margin:3px;\">" + op->toHtml(htmlDiff) + "</div></html>");
        mpEquationOperationsTreeWidget->setItemWidget(pOperationTreeItem, 0, opText);
      }
    }
  } else {
    QString message = GUIMessages::getMessage(GUIMessages::SET_INFO_XML_FLAG).arg(Helper::toolsOptionsPath);
    QStringList values;
    values << message;
    QString toolTip = message;
    QTreeWidgetItem *pOperationTreeItem = new QTreeWidgetItem(values);
    pOperationTreeItem->setToolTip(0, toolTip);
    mpEquationOperationsTreeWidget->addTopLevelItem(pOperationTreeItem);
  }
  mpEquationOperationsTreeWidget->resizeColumnToContents(0);
}

void TransformationsWidget::clearTreeWidgetItems(QTreeWidget *pTreeWidget)
{
  int i = 0;
  while(i < pTreeWidget->topLevelItemCount())
  {
    qDeleteAll(pTreeWidget->topLevelItem(i)->takeChildren());
    delete pTreeWidget->topLevelItem(i);
    i = 0;   //Restart iteration
  }
}

/*!
 * \brief TransformationsWidget::findVariables
 * Finds the variables in the TransformationsWidget Variable Browser.
 */
void TransformationsWidget::findVariables()
{
  QString findText = mpTreeSearchFilters->getFilterTextBox()->text();
  Qt::CaseSensitivity caseSensitivity = mpTreeSearchFilters->getCaseSensitiveCheckBox()->isChecked() ? Qt::CaseSensitive: Qt::CaseInsensitive;
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  // TODO: handle PatternSyntax
  QRegularExpression regExp(QRegularExpression::fromWildcard(findText, caseSensitivity, QRegularExpression::UnanchoredWildcardConversion));
  mpTVariableTreeProxyModel->setFilterRegularExpression(regExp);
#else
  QRegExp::PatternSyntax syntax = QRegExp::PatternSyntax(mpTreeSearchFilters->getSyntaxComboBox()->itemData(mpTreeSearchFilters->getSyntaxComboBox()->currentIndex()).toInt());
  QRegExp regExp(findText, caseSensitivity, syntax);
  mpTVariableTreeProxyModel->setFilterRegExp(regExp);
#endif
  /* expand all so that the filtered items can be seen. */
  if (!findText.isEmpty()) {
    mpTVariablesTreeView->expandAll();
  }
}

void TransformationsWidget::fetchVariableData(const QModelIndex &index)
{
  if (!index.isValid()) {
    return;
  }

  QModelIndex modelIndex = mpTVariableTreeProxyModel->mapToSource(index);
  TVariablesTreeItem *pTVariableTreeItem = static_cast<TVariablesTreeItem*>(modelIndex.internalPointer());
  if (!pTVariableTreeItem) {
    return;
  }

  const OMVariable &variable = mVariables[pTVariableTreeItem->getVariableName()];
  /* fetch defined in equations */
  fetchDefinedInEquations(variable);
  /* fetch used in equations */
  fetchUsedInEquations(variable);
  /* fetch operations */
  fetchOperations(variable);

  if (!variable.info.isValid) {
    return;
  }
  /* open the model with and go to the variable line */
  QString fileName = variable.info.file;
  QFileInfo fileInfo(fileName);
  if (fileInfo.isRelative()) {
    // find the class
    LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(fileName);
    if (pLibraryTreeItem) {
      fileName = pLibraryTreeItem->getFileName();
    }
  }

  if (!QFile::exists(fileName)) {
    return;
  }

  QFile file(fileName);
  if (file.open(QIODevice::ReadOnly)) {
    mpTSourceEditorFileLabel->setText(file.fileName());
    mpTSourceEditorFileLabel->show();
    mpTransformationsEditor->getPlainTextEdit()->setPlainText(QString(file.readAll()));
    mpTSourceEditorInfoBar->hide();
    file.close();
    mpTransformationsEditor->getPlainTextEdit()->goToLineNumber(variable.info.lineStart);
    mpTransformationsEditor->getPlainTextEdit()->foldAll();
  }
}

void TransformationsWidget::fetchEquationData(const QModelIndex &index)
{
  if (!index.isValid()) {
    return;
  }

  EquationTreeItem *pEquationTreeItem = static_cast<EquationTreeItem*>(index.internalPointer());
  if (!pEquationTreeItem) {
    return;
  }

  int equationIndex = pEquationTreeItem->getEquationIndex();
  /* if the sender is mpEquationTreeView then there is no need to select the item. */
  EquationTreeView *pSender = qobject_cast<EquationTreeView*>(sender());
  if (pSender != mpEquationTreeView) {
    EquationTreeItem *pEquationTreeItem = findEquationTreeItem(equationIndex);
    if (pEquationTreeItem) {
      mpEquationTreeView->clearSelection();
      QModelIndex idx = mpEquationTreeModel->equationTreeItemIndex(pEquationTreeItem);
      mpEquationTreeView->setCurrentIndex(idx);
      mpEquationTreeView->scrollTo(idx);
    }
  }

  fetchEquationData(equationIndex);
}

void TransformationsWidget::filterEquationOperations(int index)
{
  if (mCurrentEquationIndex < 1) {
    return;
  }
  OMEquation *equation = getOMEquation(mEquations, mCurrentEquationIndex);
  if (!equation) {
    return;
  }
  fetchOperations(equation, (HtmlDiff)mpEquationDiffFilterComboBox->itemData(index).toInt());
}

void TransformationsWidget::parseProfiling(QString fileName)
{
  JsonDocument jsonDocument;
  bool index_error = false;

  if (jsonDocument.parse(fileName)) {
    QVariantMap result = jsonDocument.result.toMap();
    double totalStepsTime = result["totalTimeProfileBlocks"].toDouble();
    QVariantList functions = result["functions"].toList();
    QVariantList list = result["profileBlocks"].toList();
    profilingNumSteps = result["numStep"].toInt() + 1; // Initialization is not a step, but part of the file
    for (int i=0; i<list.size(); i++) {
      QVariantMap eq = list[i].toMap();
      long id = eq["id"].toInt();

      // Ignore the entry if the index is out of bounds.
      if (id < 0 || id >= mEquations.size()) {
        // Print an error only once.
        if (!index_error) {
          index_error = true;
          MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
            QStringLiteral("Out of bounds equation index %1").arg(id), Helper::scriptingKind, Helper::errorLevel));
        }
        continue;
      }

      double time = eq["time"].toDouble();
      mEquations[id]->ncall = eq["ncall"].toInt();
      mEquations[id]->maxTime = eq["maxTime"].toDouble();
      mEquations[id]->time = time;
      mEquations[id]->fraction = time / totalStepsTime;
      mEquations[id]->profileBlock = i + functions.size();
    }
  } else {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, jsonDocument.errorString, Helper::scriptingKind, Helper::errorLevel));
    MainWindow::instance()->printStandardOutAndErrorFilesMessages();
  }
}
