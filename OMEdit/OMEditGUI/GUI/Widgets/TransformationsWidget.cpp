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

#include "TransformationsWidget.h"

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

  Qt::ItemFlags flags;
  TVariablesTreeItem *pTVariablesTreeItem = static_cast<TVariablesTreeItem*>(index.internalPointer());
  if (pTVariablesTreeItem && pTVariablesTreeItem->getChildren().size() == 0)
    flags |= Qt::ItemIsEnabled | Qt::ItemIsSelectable;

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

void TVariablesTreeModel::insertTVariablesItems()
{
  QHashIterator<QString, OMVariable> variables(mpTVariablesTreeView->getTransformationsWidget()->getInfoXMLFileHandler()->variables);
  while (variables.hasNext())
  {
    variables.next();
    OMVariable variable = variables.value();
    if (variable.name.startsWith("$PRE."))
      continue;

    QStringList tVariables;
    QString parentTVariable;
    if (variable.name.startsWith("der("))
    {
      QString str = variable.name;
      str.chop((str.lastIndexOf("der(")/4)+1);
      tVariables = StringHandler::makeVariableParts(str.mid(str.lastIndexOf("der(") + 4));
    }
    else
    {
      tVariables = StringHandler::makeVariableParts(variable.name);
    }
    int count = 1;
    TVariablesTreeItem *pParentTVariablesTreeItem = 0;
    foreach (QString tVariable, tVariables)
    {
      if (count == 1) /* first loop iteration */
      {
        pParentTVariablesTreeItem = mpRootTVariablesTreeItem;
      }
      QString findVariable = parentTVariable.isEmpty() ? tVariable : parentTVariable + "." + tVariable;
      if (pParentTVariablesTreeItem = findTVariablesTreeItem(findVariable, pParentTVariablesTreeItem))
      {
        if (count == 1)
          parentTVariable = tVariable;
        else
          parentTVariable += "." + tVariable;
        count++;
        continue;
      }
      /*
        If pParentTVariablesTreeItem is 0 and it is first loop iteration then use mpRootTVariablesTreeItem as parent.
        If loop iteration is not first and pParentTVariablesTreeItem is 0 then find the parent item.
        */
      if (!pParentTVariablesTreeItem && count > 1)
      {
        pParentTVariablesTreeItem = findTVariablesTreeItem(parentTVariable, mpRootTVariablesTreeItem);
      }
      else
      {
        pParentTVariablesTreeItem = mpRootTVariablesTreeItem;
      }
      QModelIndex index = tVariablesTreeItemIndex(pParentTVariablesTreeItem);
      QVector<QVariant> tVariableData;
      QString parentVarName = pParentTVariablesTreeItem->getVariableName();
      parentVarName = parentVarName.isEmpty() ? parentVarName : parentVarName.append(".");
      /* if last item */
      if (tVariables.size() == count && variable.name.startsWith("der("))
        tVariableData << variable.name << "der(" + tVariable + ")" << variable.comment << variable.info.lineStart << variable.info.file;
      else
        tVariableData << parentVarName + tVariable << tVariable << variable.comment << variable.info.lineStart << variable.info.file;
      TVariablesTreeItem *pTVariablesTreeItem = new TVariablesTreeItem(tVariableData, pParentTVariablesTreeItem);
      int row = rowCount(index);
      beginInsertRows(index, row, row);
      pParentTVariablesTreeItem->insertChild(row, pTVariablesTreeItem);
      endInsertRows();
      if (count == 1)
        parentTVariable = tVariable;
      else
        parentTVariable += "." + tVariable;
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
        variableName.remove(QRegExp("(_res.mat|_res.plt|_res.csv)"));
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
}

EquationTreeWidget::EquationTreeWidget(TransformationsWidget *pTransformationWidget)
  : QTreeWidget(pTransformationWidget), mpTransformationWidget(pTransformationWidget)
{
  setItemDelegate(new ItemDelegate(this));
  setObjectName("EquationsTree");
  setIndentation(Helper::treeIndentation);
  setColumnCount(3);
  setTextElideMode(Qt::ElideMiddle);
  setSortingEnabled(true);
  sortByColumn(0, Qt::AscendingOrder);
  setColumnWidth(0, 40);
  setColumnWidth(1, 60);
  QStringList headerLabels;
  headerLabels << Helper::index << Helper::type << Helper::equation;
  setHeaderLabels(headerLabels);
  connect(this, SIGNAL(itemDoubleClicked(QTreeWidgetItem*,int)), mpTransformationWidget, SLOT(fetchEquationData(QTreeWidgetItem*,int)));
}

TransformationsWidget::TransformationsWidget(QString infoXMLFullFileName, MainWindow *pMainWindow)
  : mInfoXMLFullFileName(infoXMLFullFileName), mpMainWindow(pMainWindow)
{
  setWindowIcon(QIcon(":/Resources/icons/debugger.svg"));
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::transformationalDebugger));
  QToolButton *pReloadToolButton = new QToolButton;
  pReloadToolButton->setToolTip(Helper::reload);
  pReloadToolButton->setAutoRaise(true);
  pReloadToolButton->setIcon(QIcon(":/Resources/icons/refresh.png"));
  connect(pReloadToolButton, SIGNAL(clicked()), SLOT(reloadTransformations()));
  /* info xml file path label */
  Label *pInfoXMLFilePathLabel = new Label(mInfoXMLFullFileName, this);
  /* create status bar */
  QStatusBar *pStatusBar = new QStatusBar;
  pStatusBar->setObjectName("ModelStatusBar");
  pStatusBar->setSizeGripEnabled(false);
  pStatusBar->addPermanentWidget(pReloadToolButton, 0);
  pStatusBar->addPermanentWidget(pInfoXMLFilePathLabel, 1);
  /* Variables Heading */
  Label *pVariablesBrowserLabel = new Label(Helper::variablesBrowser);
  pVariablesBrowserLabel->setObjectName("LabelWithBorder");
  // create the find text box
  mpFindVariablesTextBox = new QLineEdit(Helper::findVariables);
  mpFindVariablesTextBox->installEventFilter(this);
  connect(mpFindVariablesTextBox, SIGNAL(returnPressed()), SLOT(findVariables()));
  connect(mpFindVariablesTextBox, SIGNAL(textEdited(QString)), SLOT(findVariables()));
  // create the case sensitivity checkbox
  mpFindCaseSensitiveCheckBox = new QCheckBox(tr("Case Sensitive"));
  connect(mpFindCaseSensitiveCheckBox, SIGNAL(toggled(bool)), SLOT(findVariables()));
  // create the find syntax combobox
  mpFindSyntaxComboBox = new QComboBox;
  mpFindSyntaxComboBox->addItem(tr("Regular Expression"), QRegExp::RegExp);
  mpFindSyntaxComboBox->setItemData(0, tr("A rich Perl-like pattern matching syntax."), Qt::ToolTipRole);
  mpFindSyntaxComboBox->addItem(tr("Wildcard"), QRegExp::Wildcard);
  mpFindSyntaxComboBox->setItemData(1, tr("A simple pattern matching syntax similar to that used by shells (command interpreters) for \"file globbing\"."), Qt::ToolTipRole);
  mpFindSyntaxComboBox->addItem(tr("Fixed String"), QRegExp::FixedString);
  mpFindSyntaxComboBox->setItemData(2, tr("Fixed string matching."), Qt::ToolTipRole);
  connect(mpFindSyntaxComboBox, SIGNAL(currentIndexChanged(int)), SLOT(findVariables()));
  // expand all button
  mpExpandAllButton = new QPushButton(tr("Expand All"));
  // collapse all button
  mpCollapseAllButton = new QPushButton(tr("Collapse All"));
  /* variables tree view */
  mpTVariablesTreeView = new TVariablesTreeView(this);
  mpTVariablesTreeModel = new TVariablesTreeModel(mpTVariablesTreeView);
  mpTVariableTreeProxyModel = new TVariableTreeProxyModel;
  mpTVariableTreeProxyModel->setDynamicSortFilter(true);
  mpTVariableTreeProxyModel->setSourceModel(mpTVariablesTreeModel);
  mpTVariablesTreeView->setModel(mpTVariableTreeProxyModel);
  mpTVariablesTreeView->setColumnWidth(2, 40);  /* line number column */
  connect(mpTVariablesTreeView, SIGNAL(doubleClicked(QModelIndex)), SLOT(fetchVariableData(QModelIndex)));
  connect(mpExpandAllButton, SIGNAL(clicked()), mpTVariablesTreeView, SLOT(expandAll()));
  connect(mpCollapseAllButton, SIGNAL(clicked()), mpTVariablesTreeView, SLOT(collapseAll()));
  QGridLayout *pVariablesGridLayout = new QGridLayout;
  pVariablesGridLayout->setSpacing(1);
  pVariablesGridLayout->setContentsMargins(0, 0, 0, 0);
  pVariablesGridLayout->addWidget(pVariablesBrowserLabel, 0, 0, 1, 2);
  pVariablesGridLayout->addWidget(mpFindVariablesTextBox, 1, 0, 1, 2);
  pVariablesGridLayout->addWidget(mpFindCaseSensitiveCheckBox, 2, 0);
  pVariablesGridLayout->addWidget(mpFindSyntaxComboBox, 2, 1);
  pVariablesGridLayout->addWidget(mpExpandAllButton, 3, 0);
  pVariablesGridLayout->addWidget(mpCollapseAllButton, 3, 1);
  pVariablesGridLayout->addWidget(mpTVariablesTreeView, 4, 0, 1, 2);
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
  mpVariableOperationsTreeWidget->setObjectName("VariableOperationsTree");
  mpVariableOperationsTreeWidget->setIndentation(Helper::treeIndentation);
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
  mpDefinesVariableTreeWidget->setObjectName("DefinesTree");
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
  mpDependsVariableTreeWidget->setObjectName("DependsTree");
  mpDependsVariableTreeWidget->setIndentation(Helper::treeIndentation);
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
  mpEquationOperationsTreeWidget = new QTreeWidget;
  mpEquationOperationsTreeWidget->setItemDelegate(new ItemDelegate(mpEquationOperationsTreeWidget));
  mpEquationOperationsTreeWidget->setObjectName("EquationOperationsTree");
  mpEquationOperationsTreeWidget->setIndentation(Helper::treeIndentation);
  mpEquationOperationsTreeWidget->setColumnCount(1);
  mpEquationOperationsTreeWidget->setTextElideMode(Qt::ElideMiddle);
  mpEquationOperationsTreeWidget->setHeaderLabel(tr("Operations"));
  QGridLayout *pEquationOperationsGridLayout = new QGridLayout;
  pEquationOperationsGridLayout->setSpacing(1);
  pEquationOperationsGridLayout->setContentsMargins(0, 0, 0, 0);
  pEquationOperationsGridLayout->addWidget(pEquationOperationsLabel, 0, 0);
  pEquationOperationsGridLayout->addWidget(mpEquationOperationsTreeWidget, 1, 0);
  QFrame *pEquationOperationsFrame = new QFrame;
  pEquationOperationsFrame->setLayout(pEquationOperationsGridLayout);
  /* TSourceEditor */
  Label *pTSourceEditorBrowserLabel = new Label(tr("Source Browser"));
  pTSourceEditorBrowserLabel->setObjectName("LabelWithBorder");
  mpTSourceEditorFileLabel = new Label("");
  mpTSourceEditorFileLabel->hide();
  mpTSourceEditorInfoBar = new InfoBar(mpMainWindow);
  mpTSourceEditorInfoBar->hide();
  mpTSourceEditor = new TSourceEditor(this);
  ModelicaTextHighlighter *pModelicaTextHighlighter;
  pModelicaTextHighlighter = new ModelicaTextHighlighter(mpMainWindow->getOptionsDialog()->getModelicaTextSettings(), mpMainWindow,
                                                         mpTSourceEditor->document());
  connect(mpMainWindow->getOptionsDialog(), SIGNAL(modelicaTextSettingsChanged()), pModelicaTextHighlighter, SLOT(settingsChanged()));
  QVBoxLayout *pTSourceEditorVerticalLayout = new QVBoxLayout;
  pTSourceEditorVerticalLayout->setSpacing(1);
  pTSourceEditorVerticalLayout->setContentsMargins(0, 0, 0, 0);
  pTSourceEditorVerticalLayout->addWidget(pTSourceEditorBrowserLabel);
  pTSourceEditorVerticalLayout->addWidget(mpTSourceEditorFileLabel);
  pTSourceEditorVerticalLayout->addWidget(mpTSourceEditorInfoBar);
  pTSourceEditorVerticalLayout->addWidget(mpTSourceEditor);
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
  mpTransformationsVerticalSplitter->addWidget(pVariablesMainFrame);
  mpTransformationsVerticalSplitter->addWidget(pEquationsMainFrame);
  /* Transformations horizontal splitter */
  mpTransformationsHorizontalSplitter = new QSplitter;
  mpTransformationsHorizontalSplitter->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
  mpTransformationsHorizontalSplitter->setChildrenCollapsible(false);
  mpTransformationsHorizontalSplitter->setHandleWidth(4);
  mpTransformationsHorizontalSplitter->setContentsMargins(0, 0, 0, 0);
  mpTransformationsHorizontalSplitter->addWidget(mpTransformationsVerticalSplitter);
  mpTransformationsHorizontalSplitter->addWidget(pTSourceEditorFrame);
  /* Load the transformations before setting the layout */
  loadTransformations();
  /* set the layout */
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->addWidget(pStatusBar, 0, 0);
  pMainLayout->addWidget(mpTransformationsHorizontalSplitter, 1, 0);
  setLayout(pMainLayout);
  /* restore the TransformationsWidget geometry and splitters state. */
  QSettings settings(QSettings::IniFormat, QSettings::UserScope, Helper::organization, Helper::application);
  if (mpMainWindow->getOptionsDialog()->getGeneralSettingsPage()->getPreserveUserCustomizations())
  {
    settings.beginGroup("transformationalDebugger");
    restoreGeometry(settings.value("geometry").toByteArray());
    mpVariablesNestedHorizontalSplitter->restoreState(settings.value("variablesNestedHorizontalSplitter").toByteArray());
    mpVariablesNestedVerticalSplitter->restoreState(settings.value("variablesNestedVerticalSplitter").toByteArray());
    mpVariablesHorizontalSplitter->restoreState(settings.value("variablesHorizontalSplitter").toByteArray());
    mpEquationsNestedHorizontalSplitter->restoreState(settings.value("equationsNestedHorizontalSplitter").toByteArray());
    mpEquationsNestedVerticalSplitter->restoreState(settings.value("equationsNestedVerticalSplitter").toByteArray());
    mpEquationsHorizontalSplitter->restoreState(settings.value("equationsHorizontalSplitter").toByteArray());
    mpTransformationsVerticalSplitter->restoreState(settings.value("transformationsVerticalSplitter").toByteArray());
    mpTransformationsHorizontalSplitter->restoreState(settings.value("transformationsHorizontalSplitter").toByteArray());
    settings.endGroup();
  }
}

bool TransformationsWidget::eventFilter(QObject *pObject, QEvent *pEvent)
{
  if (pObject != mpFindVariablesTextBox)
    return false;
  if (pEvent->type() == QEvent::FocusIn)
  {
    if (mpFindVariablesTextBox->text().compare(Helper::findVariables) == 0)
      mpFindVariablesTextBox->setText("");
  }
  if (pEvent->type() == QEvent::FocusOut)
  {
    if (mpFindVariablesTextBox->text().isEmpty())
      mpFindVariablesTextBox->setText(Helper::findVariables);
  }
  return false;
}

void TransformationsWidget::loadTransformations()
{
  QFile infoXMLFile(mInfoXMLFullFileName);
  mpInfoXMLFileHandler = new MyHandler(infoXMLFile);
  mpTVariablesTreeModel->insertTVariablesItems();
  /* load equations */
  fetchEquations();
}

void TransformationsWidget::fetchDefinedInEquations(OMVariable &variable)
{
  /* Clear the defined in tree. */
  clearTreeWidgetItems(mpDefinedInEquationsTreeWidget);
  /* add defined in equations */
  for (int i = 0; i < equationTypeSize; i++)
  {
    if (variable.definedIn[i])
    {
      OMEquation equation = mpInfoXMLFileHandler->getOMEquation(variable.definedIn[i]);
      QStringList values;
      values << QString::number(variable.definedIn[i]) << OMEquationTypeToString(equation.kind) << equation.toString();
      QTreeWidgetItem *pDefinedInTreeItem = new IntegerTreeWidgetItem(values, mpDefinedInEquationsTreeWidget);
      pDefinedInTreeItem->setToolTip(0, values[0]);
      pDefinedInTreeItem->setToolTip(1, values[1]);
      pDefinedInTreeItem->setToolTip(2, values[2]);
      mpDefinedInEquationsTreeWidget->addTopLevelItem(pDefinedInTreeItem);
    }
  }
}

void TransformationsWidget::fetchUsedInEquations(OMVariable &variable)
{
  /* Clear the used in tree. */
  clearTreeWidgetItems(mpUsedInEquationsTreeWidget);
  /* add used in equations */
  for (int i = 0; i < equationTypeSize; i++)
  {
    foreach (int index, variable.usedIn[i])
    {
      OMEquation equation = mpInfoXMLFileHandler->getOMEquation(index);
      QStringList values;
      values << QString::number(index) << OMEquationTypeToString(equation.kind) << equation.toString();
      QTreeWidgetItem *pUsedInTreeItem = new IntegerTreeWidgetItem(values, mpUsedInEquationsTreeWidget);
      pUsedInTreeItem->setToolTip(0, values[0]);
      pUsedInTreeItem->setToolTip(1, values[1]);
      pUsedInTreeItem->setToolTip(2, values[2]);
      mpUsedInEquationsTreeWidget->addTopLevelItem(pUsedInTreeItem);
    }
  }
}

void TransformationsWidget::fetchOperations(OMVariable &variable)
{
  /* Clear the operations tree. */
  clearTreeWidgetItems(mpVariableOperationsTreeWidget);
  /* add operations */
  if (mpInfoXMLFileHandler->hasOperationsEnabled)
  {
    foreach (OMOperation *op, variable.ops)
    {
      QStringList values;
      values << op->toString();
      QString toolTip = op->toString();
      QTreeWidgetItem *pOperationTreeItem = new QTreeWidgetItem(values);
      pOperationTreeItem->setToolTip(0, toolTip);
      mpVariableOperationsTreeWidget->addTopLevelItem(pOperationTreeItem);
    }
  }
  else
  {
    QString message = GUIMessages::getMessage(GUIMessages::SET_INFO_XML_FLAG);
    QStringList values;
    values << message;
    QString toolTip = message;
    QTreeWidgetItem *pOperationTreeItem = new QTreeWidgetItem(values);
    pOperationTreeItem->setToolTip(0, toolTip);
    mpVariableOperationsTreeWidget->addTopLevelItem(pOperationTreeItem);
  }
}

void TransformationsWidget::fetchEquations()
{
  for (int i = 1 ; i < mpInfoXMLFileHandler->equations.size() ; i++)
  {
    OMEquation equation = mpInfoXMLFileHandler->equations[i];
    QStringList values;
    values << QString::number(equation.index) << OMEquationTypeToString(equation.kind) << equation.toString();
    QTreeWidgetItem *pEquationTreeItem = new IntegerTreeWidgetItem(values, mpEquationsTreeWidget);
    pEquationTreeItem->setToolTip(0, values[0]);
    pEquationTreeItem->setToolTip(1, values[1]);
    pEquationTreeItem->setToolTip(2, values[2]);
    mpEquationsTreeWidget->addTopLevelItem(pEquationTreeItem);
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

void TransformationsWidget::fetchEquationData(int equationIndex)
{
  OMEquation equation = mpInfoXMLFileHandler->getOMEquation(equationIndex);
  /* fetch defines */
  fetchDefines(equation);
  /* fetch depends */
  fetchDepends(equation);
  /* fetch operations */
  fetchOperations(equation);

  if (!equation.info.isValid)
    return;
  /* open the model with and go to the equation line */
  QFile file(equation.info.file);
  if (file.exists())
  {
    mpTSourceEditorFileLabel->setText(file.fileName());
    mpTSourceEditorFileLabel->show();
    file.open(QIODevice::ReadOnly);
    mpTSourceEditor->setPlainText(QString(file.readAll()));
    mpTSourceEditorInfoBar->hide();
    file.close();
    mpTSourceEditor->goToLineNumber(equation.info.lineStart);
  }
}

void TransformationsWidget::fetchDefines(OMEquation &equation)
{
  /* Clear the defines tree. */
  clearTreeWidgetItems(mpDefinesVariableTreeWidget);
  /* add defines */
  foreach (QString define, equation.defines)
  {
    QStringList values;
    values << define;
    QString toolTip = define;
    QTreeWidgetItem *pDefineTreeItem = new QTreeWidgetItem(values);
    pDefineTreeItem->setToolTip(0, toolTip);
    mpDefinesVariableTreeWidget->addTopLevelItem(pDefineTreeItem);
  }
}

void TransformationsWidget::fetchDepends(OMEquation &equation)
{
  /* Clear the depends tree. */
  clearTreeWidgetItems(mpDependsVariableTreeWidget);
  /* add depends */
  foreach (QString depend, equation.depends)
  {
    QStringList values;
    values << depend;
    QString toolTip = depend;
    QTreeWidgetItem *pDependTreeItem = new QTreeWidgetItem(values);
    pDependTreeItem->setToolTip(0, toolTip);
    mpDependsVariableTreeWidget->addTopLevelItem(pDependTreeItem);
  }
}

void TransformationsWidget::fetchOperations(OMEquation &equation)
{
  /* Clear the operations tree. */
  clearTreeWidgetItems(mpEquationOperationsTreeWidget);
  /* add operations */
  if (mpInfoXMLFileHandler->hasOperationsEnabled)
  {
    foreach (OMOperation *op, equation.ops)
    {
      QStringList values;
      values << op->toString();
      QString toolTip = op->toString();
      QTreeWidgetItem *pOperationTreeItem = new QTreeWidgetItem(values);
      pOperationTreeItem->setToolTip(0, toolTip);
      mpEquationOperationsTreeWidget->addTopLevelItem(pOperationTreeItem);
    }
  }
  else
  {
    QString message = GUIMessages::getMessage(GUIMessages::SET_INFO_XML_FLAG);
    QStringList values;
    values << message;
    QString toolTip = message;
    QTreeWidgetItem *pOperationTreeItem = new QTreeWidgetItem(values);
    pOperationTreeItem->setToolTip(0, toolTip);
    mpEquationOperationsTreeWidget->addTopLevelItem(pOperationTreeItem);
  }
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
  /* clear trees */
  mpTVariablesTreeModel->clearTVariablesTreeItems();
  /* Clear the defined in tree. */
  clearTreeWidgetItems(mpDefinedInEquationsTreeWidget);
  /* Clear the used in tree. */
  clearTreeWidgetItems(mpUsedInEquationsTreeWidget);
  /* Clear the variable operations tree. */
  clearTreeWidgetItems(mpVariableOperationsTreeWidget);
  /* clear the variable tree filters. */
  mpFindVariablesTextBox->setText(Helper::findVariables);
  mpFindSyntaxComboBox->setCurrentIndex(0);
  mpFindCaseSensitiveCheckBox->setChecked(false);
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
  mpTSourceEditor->clear();
  mpTSourceEditorInfoBar->hide();
  /* Clear the equations tree. */
  clearTreeWidgetItems(mpEquationsTreeWidget);
  /* initialize all fields again */
  loadTransformations();
}

void TransformationsWidget::findVariables()
{
  QString findText = mpFindVariablesTextBox->text();
  if (mpFindVariablesTextBox->text().isEmpty() || (mpFindVariablesTextBox->text().compare(Helper::findVariables) == 0))
  {
    findText = "";
  }
  QRegExp::PatternSyntax syntax = QRegExp::PatternSyntax(mpFindSyntaxComboBox->itemData(mpFindSyntaxComboBox->currentIndex()).toInt());
  Qt::CaseSensitivity caseSensitivity = mpFindCaseSensitiveCheckBox->isChecked() ? Qt::CaseSensitive: Qt::CaseInsensitive;
  QRegExp regExp(findText, caseSensitivity, syntax);
  mpTVariableTreeProxyModel->setFilterRegExp(regExp);
  /* expand all so that the filtered items can be seen. */
  if (!findText.isEmpty())
    mpTVariablesTreeView->expandAll();
}

void TransformationsWidget::fetchVariableData(const QModelIndex &index)
{
  if (!index.isValid())
    return;
  QModelIndex modelIndex = mpTVariableTreeProxyModel->mapToSource(index);
  TVariablesTreeItem *pTVariableTreeItem = static_cast<TVariablesTreeItem*>(modelIndex.internalPointer());
  if (!pTVariableTreeItem || pTVariableTreeItem->getChildren().size() != 0)
    return;

  OMVariable variable = mpInfoXMLFileHandler->variables.value(pTVariableTreeItem->getVariableName());
  /* fetch defined in equations */
  fetchDefinedInEquations(variable);
  /* fetch used in equations */
  fetchUsedInEquations(variable);
  /* fetch operations */
  fetchOperations(variable);

  if (!variable.info.isValid)
    return;
  /* open the model with and go to the variable line */
  QFile file(variable.info.file);
  if (file.exists())
  {
    mpTSourceEditorFileLabel->setText(file.fileName());
    mpTSourceEditorFileLabel->show();
    file.open(QIODevice::ReadOnly);
    mpTSourceEditor->setPlainText(QString(file.readAll()));
    mpTSourceEditorInfoBar->hide();
    file.close();
    mpTSourceEditor->goToLineNumber(variable.info.lineStart);
  }
}

void TransformationsWidget::fetchEquationData(QTreeWidgetItem *pEquationTreeItem, int column)
{
  Q_UNUSED(column);
  if (!pEquationTreeItem)
    return;

  int equationIndex = pEquationTreeItem->text(0).toInt();
  QTreeWidgetItem *pTreeWidgetItem = findEquationTreeItem(equationIndex);
  if (pTreeWidgetItem)
  {
    mpEquationsTreeWidget->clearSelection();
    mpEquationsTreeWidget->setCurrentItem(pTreeWidgetItem);
  }
  fetchEquationData(equationIndex);
}
