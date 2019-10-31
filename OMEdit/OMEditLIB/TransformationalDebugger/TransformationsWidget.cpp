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

#include "MainWindow.h"
#include "TransformationsWidget.h"
#include "Options/OptionsDialog.h"
#include "Util/StringHandler.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ItemDelegate.h"
#include "Editors/TransformationsEditor.h"
#include "Editors/ModelicaEditor.h"
#include <qjson/parser.h>
#include "diff_match_patch.h"

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
  qDeleteAll(mChildren);
  mChildren.clear();
}

void TVariablesTreeItem::insertChild(int position, TVariablesTreeItem *pTVariablesTreeItem)
{
  mChildren.insert(position, pTVariablesTreeItem);
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

void TVariablesTreeItem::removeChild(TVariablesTreeItem *pTVariablesTreeItem)
{
  mChildren.removeOne(pTVariablesTreeItem);
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
  if (parent.column() > 0)
    return 0;

  if (!parent.isValid())
    pParentTVariablesTreeItem = mpRootTVariablesTreeItem;
  else
    pParentTVariablesTreeItem = static_cast<TVariablesTreeItem*>(parent.internalPointer());
  return pParentTVariablesTreeItem->getChildren().size();
}

QVariant TVariablesTreeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
  if (orientation == Qt::Horizontal && role == Qt::DisplayRole)
    return mpRootTVariablesTreeItem->data(section);
  return QVariant();
}

QModelIndex TVariablesTreeModel::index(int row, int column, const QModelIndex &parent) const
{
  if (!hasIndex(row, column, parent))
    return QModelIndex();

  TVariablesTreeItem *pParentTVariablesTreeItem;

  if (!parent.isValid())
    pParentTVariablesTreeItem = mpRootTVariablesTreeItem;
  else
    pParentTVariablesTreeItem = static_cast<TVariablesTreeItem*>(parent.internalPointer());

  TVariablesTreeItem *pChildTVariablesTreeItem = pParentTVariablesTreeItem->child(row);
  if (pChildTVariablesTreeItem)
    return createIndex(row, column, pChildTVariablesTreeItem);
  else
    return QModelIndex();
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
      return 0;

  Qt::ItemFlags flags = Qt::ItemIsEnabled | Qt::ItemIsSelectable;
  /* Ticket #3207. Make all the items enable and selectable.
   */
//  TVariablesTreeItem *pTVariablesTreeItem = static_cast<TVariablesTreeItem*>(index.internalPointer());
//  if (pTVariablesTreeItem && pTVariablesTreeItem->getChildren().size() == 0)
//    flags |= Qt::ItemIsEnabled | Qt::ItemIsSelectable;

  return flags;
}

TVariablesTreeItem* TVariablesTreeModel::findTVariablesTreeItem(const QString &name, TVariablesTreeItem *root) const
{
  if (root->getVariableName() == name)
    return root;
  for (int i = root->getChildren().size(); --i >= 0; )
    if (TVariablesTreeItem *item = findTVariablesTreeItem(name, root->getChildren().at(i)))
      return item;
  return 0;
}

QModelIndex TVariablesTreeModel::tVariablesTreeItemIndex(const TVariablesTreeItem *pTVariablesTreeItem) const
{
  return tVariablesTreeItemIndexHelper(pTVariablesTreeItem, mpRootTVariablesTreeItem, QModelIndex());
}

QModelIndex TVariablesTreeModel::tVariablesTreeItemIndexHelper(const TVariablesTreeItem *pTVariablesTreeItem,
                                                             const TVariablesTreeItem *pParentTVariablesTreeItem,
                                                             const QModelIndex &parentIndex) const
{
  if (pTVariablesTreeItem == pParentTVariablesTreeItem)
    return parentIndex;
  for (int i = pParentTVariablesTreeItem->getChildren().size(); --i >= 0; ) {
    const TVariablesTreeItem *childItem = pParentTVariablesTreeItem->getChildren().at(i);
    QModelIndex childIndex = index(i, 0, parentIndex);
    QModelIndex index = tVariablesTreeItemIndexHelper(pTVariablesTreeItem, childItem, childIndex);
    if (index.isValid())
      return index;
  }
  return QModelIndex();
}

void TVariablesTreeModel::insertTVariablesItems(QHashIterator<QString, OMVariable> variables)
{
  while (variables.hasNext())
  {
    variables.next();
    const OMVariable &variable = variables.value();
    if (variable.name.startsWith("$PRE.") || variable.name.startsWith("$res"))
      continue;

    QStringList tVariables;
    QString parentTVariable;
    if (variable.name.startsWith("der(")) {
      QString str = variable.name;
      str.chop((str.lastIndexOf("der(")/4)+1);
      tVariables = StringHandler::makeVariableParts(str.mid(str.lastIndexOf("der(") + 4));
    } else {
      tVariables = StringHandler::makeVariableParts(variable.name);
    }
    int count = 1;
    TVariablesTreeItem *pParentTVariablesTreeItem = 0;
    foreach (QString tVariable, tVariables) {
      if (count == 1) /* first loop iteration */ {
        pParentTVariablesTreeItem = mpRootTVariablesTreeItem;
      }
      QString findVariable;
      /* if last item */
      if (tVariables.size() == count && variable.name.startsWith("der(")) {
        if (parentTVariable.isEmpty()) {
          findVariable = StringHandler::joinDerivativeAndPreviousVariable(variable.name, tVariable, "der(");
        } else {
          findVariable = QString("%1.%2").arg(parentTVariable, StringHandler::joinDerivativeAndPreviousVariable(variable.name, tVariable, "der("));
        }
      } else {
        findVariable = parentTVariable.isEmpty() ? tVariable : parentTVariable + "." + tVariable;
      }
      if ((pParentTVariablesTreeItem = findTVariablesTreeItem(findVariable, pParentTVariablesTreeItem))) {
        if (count == 1) {
          parentTVariable = tVariable;
        } else {
          parentTVariable += "." + tVariable;
        }
        count++;
        continue;
      }
      /*
        If pParentTVariablesTreeItem is 0 and it is first loop iteration then use mpRootTVariablesTreeItem as parent.
        If loop iteration is not first and pParentTVariablesTreeItem is 0 then find the parent item.
        */
      if (!pParentTVariablesTreeItem && count > 1) {
        pParentTVariablesTreeItem = findTVariablesTreeItem(parentTVariable, mpRootTVariablesTreeItem);
      } else {
        pParentTVariablesTreeItem = mpRootTVariablesTreeItem;
      }
      QModelIndex index = tVariablesTreeItemIndex(pParentTVariablesTreeItem);
      QVector<QVariant> tVariableData;
      QString parentVarName = pParentTVariablesTreeItem->getVariableName();
      parentVarName = parentVarName.isEmpty() ? parentVarName : parentVarName.append(".");
      /* if last item */
      if (tVariables.size() == count && variable.name.startsWith("der(")) {
        tVariableData << variable.name << StringHandler::joinDerivativeAndPreviousVariable(variable.name, tVariable, "der(") << variable.comment << variable.info.lineStart << variable.info.file;
      } else {
        tVariableData << parentVarName + tVariable << tVariable << variable.comment << variable.info.lineStart << variable.info.file;
      }
      TVariablesTreeItem *pTVariablesTreeItem = new TVariablesTreeItem(tVariableData, pParentTVariablesTreeItem);
      int row = rowCount(index);
      beginInsertRows(index, row, row);
      pParentTVariablesTreeItem->insertChild(row, pTVariablesTreeItem);
      endInsertRows();
      if (count == 1) {
        parentTVariable = tVariable;
      } else {
        parentTVariable += "." + tVariable;
      }
      count++;
    }
  }
}

void TVariablesTreeModel::clearTVariablesTreeItems()
{
  beginRemoveRows(tVariablesTreeItemIndex(mpRootTVariablesTreeItem), 0, mpRootTVariablesTreeItem->getChildren().size());
  mpRootTVariablesTreeItem->removeChildren();
  endRemoveRows();
}

TVariableTreeProxyModel::TVariableTreeProxyModel(QObject *parent)
  : QSortFilterProxyModel(parent)
{
}

bool TVariableTreeProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
  if (!filterRegExp().isEmpty())
  {
    QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
    if (index.isValid())
    {
      // if any of children matches the filter, then current index matches the filter as well
      int rows = sourceModel()->rowCount(index);
      for (int i = 0 ; i < rows ; ++i)
      {
        if (filterAcceptsRow(i, index))
        {
          return true;
        }
      }
      // check current index itself
      TVariablesTreeItem *pTVariablesTreeItem = static_cast<TVariablesTreeItem*>(index.internalPointer());
      if (pTVariablesTreeItem)
      {
        QString variableName = pTVariablesTreeItem->getVariableName();
        variableName.remove(QRegExp("(\\.mat|\\.plt|\\.csv|_res.mat|_res.plt|_res.csv)"));
        return variableName.contains(filterRegExp());
      }
      else
      {
        return sourceModel()->data(index).toString().contains(filterRegExp());
      }
      QString key = sourceModel()->data(index, filterRole()).toString();
      return key.contains(filterRegExp());
    }
  }
  return QSortFilterProxyModel::filterAcceptsRow(sourceRow, sourceParent);
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

EquationTreeWidget::EquationTreeWidget(TransformationsWidget *pTransformationWidget)
  : QTreeWidget(pTransformationWidget), mpTransformationWidget(pTransformationWidget)
{
  setItemDelegate(new ItemDelegate(this));
  setIndentation(0);
  setColumnCount(7);
  setTextElideMode(Qt::ElideMiddle);
  setSortingEnabled(true);
  sortByColumn(0, Qt::AscendingOrder);
  setColumnWidth(0, 55);
  setColumnWidth(1, 60);
  setColumnWidth(2, 200);
  setColumnWidth(3, 55);
  setColumnWidth(4, 80);
  setColumnWidth(5, 80);
  setColumnWidth(6, 60);
  setExpandsOnDoubleClick(false);
  QStringList headerLabels;
  headerLabels << Helper::index << Helper::type << Helper::equation << Helper::executionCount << Helper::executionMaxTime << Helper::executionTime << Helper::executionFraction;
  setHeaderLabels(headerLabels);
  connect(this, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), mpTransformationWidget, SLOT(fetchEquationData(QTreeWidgetItem*,int)));
}

TransformationsWidget::TransformationsWidget(QString infoJSONFullFileName, QWidget *pParent)
  : QWidget(pParent), mInfoJSONFullFileName(infoJSONFullFileName)
{
  if (!mInfoJSONFullFileName.endsWith("_info.json")) {
    mProfJSONFullFileName = "";
    mProfilingDataRealFileName = "";
  } else {
    mProfJSONFullFileName = infoJSONFullFileName.left(infoJSONFullFileName.size() - 9) + "prof.json";
    mProfilingDataRealFileName = infoJSONFullFileName.left(infoJSONFullFileName.size() - 9) + "prof.realdata";
  }
  mCurrentEquationIndex = 0;
  setWindowIcon(QIcon(":/Resources/icons/equational-debugger.svg"));
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::transformationalDebugger));
  QToolButton *pReloadToolButton = new QToolButton;
  pReloadToolButton->setToolTip(Helper::reload);
  pReloadToolButton->setAutoRaise(true);
  pReloadToolButton->setIcon(QIcon(":/Resources/icons/refresh.svg"));
  connect(pReloadToolButton, SIGNAL(clicked()), SLOT(reloadTransformations()));
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
  Label *pVariablesBrowserLabel = new Label(Helper::variablesBrowser);
  pVariablesBrowserLabel->setObjectName("LabelWithBorder");
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
  pVariablesGridLayout->addWidget(pVariablesBrowserLabel, 0, 0);
  pVariablesGridLayout->addWidget(mpTreeSearchFilters, 1, 0);
  pVariablesGridLayout->addWidget(mpTVariablesTreeView, 2, 0);
  QFrame *pVariablesFrame = new QFrame;
  pVariablesFrame->setLayout(pVariablesGridLayout);
  /* Defined in tree widget */
  Label *pDefinedInLabel = new Label(tr("Defined In Equations"));
  pDefinedInLabel->setObjectName("LabelWithBorder");
  mpDefinedInEquationsTreeWidget = new EquationTreeWidget(this);
  QGridLayout *pDefinedInGridLayout = new QGridLayout;
  pDefinedInGridLayout->setSpacing(1);
  pDefinedInGridLayout->setContentsMargins(0, 0, 0, 0);
  pDefinedInGridLayout->addWidget(pDefinedInLabel, 0, 0);
  pDefinedInGridLayout->addWidget(mpDefinedInEquationsTreeWidget, 1, 0);
  QFrame *pDefinedInFrame = new QFrame;
  pDefinedInFrame->setLayout(pDefinedInGridLayout);
  /* Used in tree widget  */
  Label *pUsedInLabel = new Label(tr("Used In Equations"));
  pUsedInLabel->setObjectName("LabelWithBorder");
  mpUsedInEquationsTreeWidget = new EquationTreeWidget(this);
  QGridLayout *pUsedInGridLayout = new QGridLayout;
  pUsedInGridLayout->setSpacing(1);
  pUsedInGridLayout->setContentsMargins(0, 0, 0, 0);
  pUsedInGridLayout->addWidget(pUsedInLabel, 0, 0);
  pUsedInGridLayout->addWidget(mpUsedInEquationsTreeWidget, 1, 0);
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
  Label *pEquationsBrowserLabel = new Label(tr("Equations Browser"));
  pEquationsBrowserLabel->setObjectName("LabelWithBorder");
  /* Equations tree widget */
  mpEquationsTreeWidget = new EquationTreeWidget(this);
  mpEquationsTreeWidget->setIndentation(Helper::treeIndentation);
  QGridLayout *pEquationsGridLayout = new QGridLayout;
  pEquationsGridLayout->setSpacing(1);
  pEquationsGridLayout->setContentsMargins(0, 0, 0, 0);
  pEquationsGridLayout->addWidget(pEquationsBrowserLabel, 0, 0);
  pEquationsGridLayout->addWidget(mpEquationsTreeWidget, 1, 0);
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

static QStringList variantListToStringList(const QVariantList lst)
{
  QStringList strs;
  foreach(QVariant v, lst) {
    strs << v.toString().trimmed();
  }
  return strs;
}

static OMOperation* variantToOperationPtr(QVariantMap var)
{
  QString op = var["op"].toString();
  QString display = var["display"].toString();
  QStringList dataStrings = variantListToStringList(var["data"].toList());

  if (op == "before-after") {
    return new OMOperationBeforeAfter(display != "" ? display : op, dataStrings);
  } else if (op == "before-after-assert") {
    return new OMOperationBeforeAfter(display != "" ? display : op, dataStrings);
  } else if (op == "chain") {
    QStringList firstLast;
    firstLast << dataStrings.first() << dataStrings.last();
    return new OMOperationBeforeAfter(display != "" ? display : op, firstLast);
  } else if (op == "info") {
    return new OMOperationInfo(display != "" ? display : op, dataStrings.join(", "));
  }
  // "chain"
  return NULL;
}


static void variantToSource(QVariantMap var, OMInfo &info, QStringList &types, QList<OMOperation*> &ops)
{
  Q_UNUSED(types);
  QVariantMap vinfo = var["info"].toMap();
  info.file = vinfo["file"].toString();
  info.lineStart = vinfo["lineStart"].toInt();
  info.lineEnd = vinfo["lineEnd"].toInt();
  info.colStart = vinfo["colStart"].toInt();
  info.colEnd = vinfo["colEnd"].toInt();
  info.isValid = true;
  QVariantList vops = var["operations"].toList();
  foreach (QVariant vop, vops) {
    OMOperation *op = variantToOperationPtr(vop.toMap());
    if (op) {
      ops += op;
    }
  }
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

void TransformationsWidget::loadTransformations()
{
  QFile file(mInfoJSONFullFileName);
  mEquations.clear();
  mVariables.clear();
  hasOperationsEnabled = false;
  if (mInfoJSONFullFileName.endsWith(".json")) {
    QJson::Parser parser;
    bool ok;
    QVariantMap result;
    result = parser.parse(&file, &ok).toMap();
    if (!ok) {
      QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::parsingFailedJson), Helper::parsingFailedJson + ": " + mInfoJSONFullFileName, Helper::ok);
      return;
    }
    QVariantMap vars = result["variables"].toMap();
    QVariantList eqs = result["equations"].toList();
    for(QVariantMap::const_iterator iter = vars.begin(); iter != vars.end(); ++iter) {
      QVariantMap value = iter.value().toMap();
      OMVariable *var = new OMVariable();
      var->name = iter.key();
      var->comment = value["comment"].toString();
      QVariantMap sourceMap = value["source"].toMap();
      variantToSource(value["source"].toMap(), var->info, var->types, var->ops);
      if (!hasOperationsEnabled && sourceMap.contains("operations")) {
        hasOperationsEnabled = true;
      }
      mVariables[iter.key()] = *var;
    }
    mpTVariablesTreeModel->insertTVariablesItems(mVariables);
    for (int i=0; i<eqs.size(); i++) {
      mEquations << new OMEquation();
    }
    for (int i=0; i<eqs.size(); i++) {
      QVariantMap veq = eqs[i].toMap();
      OMEquation *eq = mEquations[i];
      eq->section = veq["section"].toString();
      if (veq["eqIndex"].toInt() != i) {
        QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::parsingFailedJson), Helper::parsingFailedJson + QString(": got index ") + veq["eqIndex"].toString() + QString(" expected ") + QString::number(i), Helper::ok);
        return;
      }
      eq->index = i;
      eq->profileBlock = -1;
      if (veq.find("parent") != veq.end()) {
        eq->parent = veq["parent"].toInt();
        mEquations[eq->parent]->eqs << eq->index;
      } else {
        eq->parent = 0;
      }
      if (veq.find("defines") != veq.end()) {
        eq->defines = variantListToStringList(veq["defines"].toList());
        foreach (QString v, eq->defines) {
          mVariables[v].definedIn << eq->index;
        }
      }
      if (veq.find("uses") != veq.end()) {
        eq->depends = variantListToStringList(veq["uses"].toList());
        foreach (QString v, eq->depends) {
          mVariables[v].usedIn << eq->index;
        }
      }
      eq->text = variantListToStringList(veq["equation"].toList());
      eq->tag = veq["tag"].toString();
      if (veq.find("display") != veq.end()) {
        eq->display = veq["display"].toString();
      } else {
        eq->display = eq->tag;
      }
      eq->unknowns = veq["unknowns"].toInt();
      QVariantMap sourceMap = veq["source"].toMap();
      variantToSource(veq["source"].toMap(), eq->info, eq->types, eq->ops);
      if (!hasOperationsEnabled && sourceMap.contains("operations")) {
        hasOperationsEnabled = true;
      }
    }
    parseProfiling(mProfJSONFullFileName);
    fetchEquations();
  } else {
    mpInfoXMLFileHandler = new MyHandler(file,mVariables,mEquations);
    mpTVariablesTreeModel->insertTVariablesItems(mVariables);
    /* load equations */
    parseProfiling(mProfJSONFullFileName);
    fetchEquations();
    hasOperationsEnabled = mpInfoXMLFileHandler->hasOperationsEnabled;
  }
  fetchVariableData(mpTVariableTreeProxyModel->index(0, 0));
}

void TransformationsWidget::fetchDefinedInEquations(const OMVariable &variable)
{
  /* Clear the defined in tree. */
  clearTreeWidgetItems(mpDefinedInEquationsTreeWidget);
  /* add defined in equations */
  for (int i=0; i<variable.definedIn.size(); i++) {
    OMEquation *equation = getOMEquation(mEquations, variable.definedIn[i]);
    if (equation) {
      QStringList values;
      values << QString::number(variable.definedIn[i]) << equation->section << equation->toString();
      QTreeWidgetItem *pDefinedInTreeItem = new IntegerTreeWidgetItem(values, mpDefinedInEquationsTreeWidget);
      pDefinedInTreeItem->setToolTip(0, values[0]);
      pDefinedInTreeItem->setToolTip(1, values[1]);
      pDefinedInTreeItem->setToolTip(2, values[2]);
      mpDefinedInEquationsTreeWidget->addTopLevelItem(pDefinedInTreeItem);
    }
  }
}

void TransformationsWidget::fetchUsedInEquations(const OMVariable &variable)
{
  /* Clear the used in tree. */
  clearTreeWidgetItems(mpUsedInEquationsTreeWidget);
  /* add used in equations */
  foreach (int index, variable.usedIn) {
    OMEquation *equation = getOMEquation(mEquations, index);
    if (equation) {
      QStringList values;
      values << QString::number(index) << equation->section << equation->toString();
      QTreeWidgetItem *pUsedInTreeItem = new IntegerTreeWidgetItem(values, mpUsedInEquationsTreeWidget);
      pUsedInTreeItem->setToolTip(0, values[0]);
      pUsedInTreeItem->setToolTip(1, values[1]);
      pUsedInTreeItem->setToolTip(2, values[2]);
      mpUsedInEquationsTreeWidget->addTopLevelItem(pUsedInTreeItem);
    }
  }
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
    QString message = GUIMessages::getMessage(GUIMessages::SET_INFO_XML_FLAG).arg(Helper::toolsOptionsPath).arg(Helper::toolsOptionsPath);
    QStringList values;
    values << message;
    QString toolTip = message;
    QTreeWidgetItem *pOperationTreeItem = new QTreeWidgetItem(values);
    pOperationTreeItem->setToolTip(0, toolTip);
    mpVariableOperationsTreeWidget->addTopLevelItem(pOperationTreeItem);
  }
  mpVariableOperationsTreeWidget->resizeColumnToContents(0);
}

QTreeWidgetItem* TransformationsWidget::makeEquationTreeWidgetItem(int equationIndex, int allowChild)
{
  OMEquation *equation = mEquations[equationIndex];
  if (!allowChild && equation->parent) {
    return NULL; // Only output equations in one position
  }
  QStringList values;
  values << QString::number(equation->index)
         << equation->section
         << equation->toString();
  if (equation->profileBlock >= 0) {
    values << QString::number(equation->ncall)
         << QString::number(equation->maxTime, 'g', 3)
         << QString::number(equation->time, 'g', 3)
         << QString::number(100 * equation->fraction, 'g', 3) + "%";
  }

  QTreeWidgetItem *pEquationTreeItem = new IntegerTreeWidgetItem(values, mpEquationsTreeWidget);
  pEquationTreeItem->setToolTip(0, values[0]);
  pEquationTreeItem->setToolTip(1, values[1]);
  pEquationTreeItem->setToolTip(2, "<html><div style=\"margin:3px;\">" +
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
  QString(values[2]).toHtmlEscaped()
#else /* Qt4 */
  Qt::escape(values[2])
#endif
  + "</div></html>");
  pEquationTreeItem->setToolTip(4, "Maximum execution time in a single step");
  pEquationTreeItem->setToolTip(5, "Total time excluding the overhead of measuring.");
  pEquationTreeItem->setToolTip(6, "Fraction of time, 100% is the total time of all non-child equations.");
  return pEquationTreeItem;
}

void TransformationsWidget::fetchEquations()
{
  for (int i = 1 ; i < mEquations.size() ; i++)
  {
    QTreeWidgetItem *pEquationTreeItem = makeEquationTreeWidgetItem(i,0);
    if (pEquationTreeItem) {
      mpEquationsTreeWidget->addTopLevelItem(pEquationTreeItem);
      fetchNestedEquations(pEquationTreeItem, i);
    }
  }
}

void TransformationsWidget::fetchNestedEquations(QTreeWidgetItem *pParentTreeWidgetItem, int index)
{
  foreach (int nestedIndex, mEquations[index]->eqs)
  {
    // OMEquation *nestedEquation = mpInfoXMLFileHandler->equations[nestedIndex];
    QTreeWidgetItem *pNestedEquationTreeItem = makeEquationTreeWidgetItem(nestedIndex,1);
    if (pNestedEquationTreeItem) {
      pParentTreeWidgetItem->addChild(pNestedEquationTreeItem);
      fetchNestedEquations(pNestedEquationTreeItem, nestedIndex);
    }
  }
}

QTreeWidgetItem* TransformationsWidget::findEquationTreeItem(int equationIndex)
{
  QTreeWidgetItemIterator it(mpEquationsTreeWidget);
  while (*it)
  {
    QTreeWidgetItem *pEquationTreeItem = dynamic_cast<QTreeWidgetItem*>(*it);
    if (pEquationTreeItem->text(0).toInt() == equationIndex)
      return pEquationTreeItem;
    ++it;
  }
  return 0;
}

#include <qwt_plot.h>

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
  if (file.exists()) {
    mpTSourceEditorFileLabel->setText(file.fileName());
    mpTSourceEditorFileLabel->show();
    file.open(QIODevice::ReadOnly);
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
    QString message = GUIMessages::getMessage(GUIMessages::SET_INFO_XML_FLAG).arg(Helper::toolsOptionsPath).arg(Helper::toolsOptionsPath);
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

void TransformationsWidget::reloadTransformations()
{
  mCurrentEquationIndex = 0;
  /* clear trees */
  mpTVariablesTreeModel->clearTVariablesTreeItems();
  /* Clear the defined in tree. */
  clearTreeWidgetItems(mpDefinedInEquationsTreeWidget);
  /* Clear the used in tree. */
  clearTreeWidgetItems(mpUsedInEquationsTreeWidget);
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
  mpTVariableTreeProxyModel->setFilterRegExp(QRegExp());
  /* clear equations tree */
  clearTreeWidgetItems(mpEquationsTreeWidget);
  /* clear defines in tree */
  clearTreeWidgetItems(mpDefinesVariableTreeWidget);
  /* clear depends tree */
  clearTreeWidgetItems(mpDependsVariableTreeWidget);
  /* clear equation operations tree */
  clearTreeWidgetItems(mpEquationOperationsTreeWidget);
  /* clear TSourceEditor */
  mpTSourceEditorFileLabel->setText("");
  mpTSourceEditorFileLabel->hide();
  mpTransformationsEditor->getPlainTextEdit()->clear();
  mpTSourceEditorInfoBar->hide();
  /* Clear the equations tree. */
  clearTreeWidgetItems(mpEquationsTreeWidget);
  /* initialize all fields again */
  loadTransformations();
}

/*!
 * \brief TransformationsWidget::findVariables
 * Finds the variables in the TransformationsWidget Variables Browser.
 */
void TransformationsWidget::findVariables()
{
  QString findText = mpTreeSearchFilters->getFilterTextBox()->text();
  QRegExp::PatternSyntax syntax = QRegExp::PatternSyntax(mpTreeSearchFilters->getSyntaxComboBox()->itemData(mpTreeSearchFilters->getSyntaxComboBox()->currentIndex()).toInt());
  Qt::CaseSensitivity caseSensitivity = mpTreeSearchFilters->getCaseSensitiveCheckBox()->isChecked() ? Qt::CaseSensitive: Qt::CaseInsensitive;
  QRegExp regExp(findText, caseSensitivity, syntax);
  mpTVariableTreeProxyModel->setFilterRegExp(regExp);
  /* expand all so that the filtered items can be seen. */
  if (!findText.isEmpty()) {
    mpTVariablesTreeView->expandAll();
  }
}

void TransformationsWidget::fetchVariableData(const QModelIndex &index)
{
  if (!index.isValid())
    return;
  QModelIndex modelIndex = mpTVariableTreeProxyModel->mapToSource(index);
  TVariablesTreeItem *pTVariableTreeItem = static_cast<TVariablesTreeItem*>(modelIndex.internalPointer());
  if (!pTVariableTreeItem)
    return;

  const OMVariable &variable = mVariables[pTVariableTreeItem->getVariableName()];
  /* fetch defined in equations */
  fetchDefinedInEquations(variable);
  /* fetch used in equations */
  fetchUsedInEquations(variable);
  /* fetch operations */
  fetchOperations(variable);

  if (!variable.info.isValid)
    return;
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
  QFile file(fileName);
  if (file.exists()) {
    mpTSourceEditorFileLabel->setText(file.fileName());
    mpTSourceEditorFileLabel->show();
    file.open(QIODevice::ReadOnly);
    mpTransformationsEditor->getPlainTextEdit()->setPlainText(QString(file.readAll()));
    mpTSourceEditorInfoBar->hide();
    file.close();
    mpTransformationsEditor->getPlainTextEdit()->goToLineNumber(variable.info.lineStart);
    mpTransformationsEditor->getPlainTextEdit()->foldAll();
  }
}

void TransformationsWidget::fetchEquationData(QTreeWidgetItem *pEquationTreeItem, int column)
{
  Q_UNUSED(column);
  if (!pEquationTreeItem) {
    return;
  }

  int equationIndex = pEquationTreeItem->text(0).toInt();
  /* if the sender is mpEquationsTreeWidget then there is no need to select the item. */
  EquationTreeWidget *pSender = qobject_cast<EquationTreeWidget*>(sender());
  if (pSender != mpEquationsTreeWidget) {
    QTreeWidgetItem *pTreeWidgetItem = findEquationTreeItem(equationIndex);
    if (pTreeWidgetItem) {
      mpEquationsTreeWidget->clearSelection();
      mpEquationsTreeWidget->setCurrentItem(pTreeWidgetItem);
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
  QFile *file = new QFile(fileName);
  if (!file->exists()) {
    delete file;
    return;
  }
  QJson::Parser parser;
  bool ok;
  QVariantMap result = parser.parse(file, &ok).toMap();
  double totalStepsTime = result["totalTimeProfileBlocks"].toDouble();
  QVariantList functions = result["functions"].toList();
  QVariantList list = result["profileBlocks"].toList();
  profilingNumSteps = result["numStep"].toInt() + 1; // Initialization is not a step, but part of the file
  for (int i=0; i<list.size(); i++) {
    QVariantMap eq = list[i].toMap();
    long id = eq["id"].toInt();
    double time = eq["time"].toDouble();
    mEquations[id]->ncall = eq["ncall"].toInt();
    mEquations[id]->maxTime = eq["maxTime"].toDouble();
    mEquations[id]->time = time;
    mEquations[id]->fraction = time / totalStepsTime;
    mEquations[id]->profileBlock = i + functions.size();
  }
  delete file;
}
