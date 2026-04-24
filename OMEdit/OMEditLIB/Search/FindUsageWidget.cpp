/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "FindUsageWidget.h"
#include "MainWindow.h"
#include "Modeling/MessagesWidget.h"
#include "Modeling/ModelicaClassDialog.h"
#include "OMC/OMCProxy.h"
#include "Modeling/ItemDelegate.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"

#include <QGridLayout>

/*!
 * \class ClassTreeItem
 * \brief A tree item in the Element Browser.
 */
/*!
 * \brief ClassTreeItem::ClassTreeItem
 */
ClassTreeItem::ClassTreeItem()
{
  mIsRootItem = true;
}

/*!
 * \brief ClassTreeItem::ClassTreeItem
 * \param fileName
 * \param pParentClassTreeItem
 */
ClassTreeItem::ClassTreeItem(const QString &fileName, ClassTreeItem *pParentClassTreeItem)
{
  mFileName = fileName;
  mpParentClassTreeItem = pParentClassTreeItem;
}

/*!
 * \brief ClassTreeItem::ClassTreeItem
 * \param name
 * \param className
 * \param lineStart
 * \param columnStart
 * \param lineEnd
 * \param columnEnd
 * \param pParentClassTreeItem
 */
ClassTreeItem::ClassTreeItem(const QString &name, const QString &className, int lineStart, int columnStart, int lineEnd, int columnEnd, ClassTreeItem *pParentClassTreeItem)
{
  mName = name;
  mClassName = className;
  mLineStart = lineStart;
  mColumnStart = columnStart;
  mLineEnd = lineEnd;
  mColumnEnd = columnEnd;
  mpParentClassTreeItem = pParentClassTreeItem;
}

/*!
 * \brief ClassTreeItem::~ClassTreeItem
 */
ClassTreeItem::~ClassTreeItem()
{
  removeChildren();
}

/*!
 * \brief ClassTreeItem::child
 * Returns the child at the given row.
 * \param row
 * \return
 */
ClassTreeItem* ClassTreeItem::child(int row) const
{
  if (row >= 0 && row < mChildren.size()) {
    return mChildren.at(row);
  } else {
    return nullptr;
  }
}

/*!
 * \brief ClassTreeItem::insertChild
 * Inserts the given child at the given position.
 * \param position
 * \param pClassTreeItem
 */
void ClassTreeItem::insertChild(int position, ClassTreeItem *pClassTreeItem)
{
  mChildren.insert(position, pClassTreeItem);
}

/*!
 * \brief ClassTreeItem::removeChildren
 * Removes all the children.
 */
void ClassTreeItem::removeChildren()
{
  qDeleteAll(mChildren);
  mChildren.clear();
}

/*!
 * \brief ClassTreeItem::data
 * Returns the data stored under the given role for the item referred to by the column.
 * \param column
 * \param role
 * \return
 */
QVariant ClassTreeItem::data(int column, int role) const
{
  // Matches items don't have any children. So, we show file name for items with children and name for items without children.
  const QString text = mChildren.isEmpty() ? QString::number(mLineStart) +  "\t" + mClassName : mFileName;
  switch (column) {
    case 0:
      switch (role) {
        case Qt::DisplayRole:
        case Qt::ToolTipRole:
          return text;
        default:
          return QVariant();
      }
    default:
      return QVariant();
  }
}

/*!
 * \brief ClassTreeItem::row
 * Returns the row number corresponding to ClassTreeItem.
 * \return
 */
int ClassTreeItem::row() const
{
  if (mpParentClassTreeItem) {
    return mpParentClassTreeItem->mChildren.indexOf(const_cast<ClassTreeItem*>(this));
  }

  return 0;
}

/*!
 * \brief ClassTreeItem::getText
 * Returns the text to be shown for ClassTreeItem. If ClassTreeItem has children then it returns file name otherwise it returns class name.
 * \return
 */
QString ClassTreeItem::getText() const
{
  return mChildren.isEmpty() ? mClassName : mFileName;
}

/*!
 * \class ClassTreeProxyModel
 * \brief A sort filter proxy model for find usage tree.
 */
/*!
 * \brief ClassTreeProxyModel::ClassTreeProxyModel
 * \param pParent
 */
ClassTreeProxyModel::ClassTreeProxyModel(QWidget *pParent)
  : QSortFilterProxyModel(pParent)
{

}

/*!
 * \brief ClassTreeProxyModel::filterAcceptsRow
 * Filters the ClassTreeItems based on the filter reguler expression.
 * Also checks if ClassTreeItem is protected and show/hide it based on Show Protected Classes settings value.
 * \param sourceRow
 * \param sourceParent
 * \return
 */
bool ClassTreeProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
  QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
  ClassTreeItem *pClassTreeItem = static_cast<ClassTreeItem*>(index.internalPointer());

  if (pClassTreeItem) {
    // If any ancestor matches the filter, accept this row unconditionally
    QModelIndex parentIndex = sourceParent;
    while (parentIndex.isValid()) {
      ClassTreeItem *pParentItem = static_cast<ClassTreeItem*>(parentIndex.internalPointer());
      if (pParentItem) {
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
        if (pParentItem->getText().contains(filterRegularExpression())) {
#else
        if (pParentItem->getText().contains(filterRegExp())) {
#endif
          return true;  // Parent matches → accept all descendants
        }
      }
      parentIndex = parentIndex.parent();
    }

    // if any of children matches the filter, then current index matches the filter as well
    int rows = sourceModel()->rowCount(index);
    for (int i = 0; i < rows; ++i) {
      if (filterAcceptsRow(i, index)) {
        return true;
      }
    }
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    return pClassTreeItem->getText().contains(filterRegularExpression());
#else
    return pClassTreeItem->getText().contains(filterRegExp());
#endif
  } else {
    return QSortFilterProxyModel::filterAcceptsRow(sourceRow, sourceParent);
  }
}

/*!
 * \class ClassTreeModel
 * \brief A model for find usage tree.
 */
/*!
 * \brief ClassTreeModel::ClassTreeModel
 * \param pParent
 */
ClassTreeModel::ClassTreeModel(QWidget *pParent)
  : QAbstractItemModel(pParent)
{
  mpRootClassTreeItem = new ClassTreeItem();
}

/*!
 * \brief ClassTreeModel::~ClassTreeModel
 */
ClassTreeModel::~ClassTreeModel()
{
  delete mpRootClassTreeItem;
}

/*!
 * \brief ClassTreeModel::columnCount
 * Returns the number of columns for the children of the given parent.
 * \param parent
 * \return
 */
int ClassTreeModel::columnCount(const QModelIndex &parent) const
{
  Q_UNUSED(parent);
  return 1;
}

/*!
 * \brief ClassTreeModel::rowCount
 * Returns the number of rows under the given parent.
 * When the parent is valid it means that rowCount is returning the number of children of parent.
 * \param parent
 * \return
 */
int ClassTreeModel::rowCount(const QModelIndex &parent) const
{
  ClassTreeItem *pParentClassTreeItem;
  if (parent.column() > 0) {
    return 0;
  }

  if (!parent.isValid()) {
    pParentClassTreeItem = mpRootClassTreeItem;
  } else {
    pParentClassTreeItem = static_cast<ClassTreeItem*>(parent.internalPointer());
  }
  return pParentClassTreeItem ? pParentClassTreeItem->childrenSize() : 0;
}

/*!
 * \brief ClassTreeModel::index
 * Returns the index of the item in the model specified by the given row, column and parent index.
 * \param row
 * \param column
 * \param parent
 * \return
 */
QModelIndex ClassTreeModel::index(int row, int column, const QModelIndex &parent) const
{
  if (!hasIndex(row, column, parent)) {
    return QModelIndex();
  }

  ClassTreeItem *pParentClassTreeItem;
  if (!parent.isValid()) {
    pParentClassTreeItem = mpRootClassTreeItem;
  } else {
    pParentClassTreeItem = static_cast<ClassTreeItem*>(parent.internalPointer());
  }

  if (row < 0 || row >= pParentClassTreeItem->childrenSize()) {
    return QModelIndex();
  }

  return createIndex(row, column, pParentClassTreeItem->child(row));
}

/*!
 * \brief ClassTreeModel::parent
 * Finds the parent for QModelIndex
 * \param index
 * \return
 */
QModelIndex ClassTreeModel::parent(const QModelIndex &index) const
{
  if (!index.isValid()) {
    return QModelIndex();
  }

  ClassTreeItem *pChildClassTreeItem = static_cast<ClassTreeItem*>(index.internalPointer());
  ClassTreeItem *pParentClassTreeItem = pChildClassTreeItem->parent();
  if (pParentClassTreeItem == mpRootClassTreeItem)
    return QModelIndex();

  return createIndex(pParentClassTreeItem->row(), 0, pParentClassTreeItem);
}

/*!
 * \brief ClassTreeModel::data
 * Returns the ClassTreeModel data.
 * \param index
 * \param role
 * \return
 */
QVariant ClassTreeModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid()) {
    return QVariant();
  }

  ClassTreeItem *pClassTreeItem = static_cast<ClassTreeItem*>(index.internalPointer());
  return pClassTreeItem->data(index.column(), role);
}

/*!
 * \brief ClassTreeModel::flags
 * Returns the flags for ClassTreeItem.
 * \param index
 * \return
 */
Qt::ItemFlags ClassTreeModel::flags(const QModelIndex &index) const
{
  if (!index.isValid()) {
    return Qt::ItemFlags();
  } else {
    return Qt::ItemIsEnabled | Qt::ItemIsSelectable;
  }
}

/*!
 * \brief ClassTreeModel::ClassTreeItemIndex
 * Finds the QModelIndex attached to ClassTreeItem.
 * \param pClassTreeItem
 * \return
 */
QModelIndex ClassTreeModel::ClassTreeItemIndex(const ClassTreeItem *pClassTreeItem) const
{
  if (!pClassTreeItem || pClassTreeItem == mpRootClassTreeItem) {
    return QModelIndex();
  }

  return createIndex(pClassTreeItem->row(), 0, const_cast<ClassTreeItem *>(pClassTreeItem));
}

/*!
 * \brief ClassTreeModel::removeClasses
 * Removes all the Classes from the Class Tree.
 */
void ClassTreeModel::removeClasses()
{
  const int n = mpRootClassTreeItem->childrenSize();
  if (n > 0) {
    beginRemoveRows(ClassTreeItemIndex(mpRootClassTreeItem), 0, n - 1);
    mpRootClassTreeItem->removeChildren();
    endRemoveRows();
  }
}

/*!
 * \brief ClassTreeModel::addClasses
 * \param jsonArray
 * \return
 */
int ClassTreeModel::addClasses(const QJsonArray &jsonArray)
{
  // remove the existing classes if there are any
  removeClasses();
  // add classes
  int matchesCount = 0;
  beginResetModel();
  for (const QJsonValue &value : jsonArray) {
    const QJsonObject classObject = value.toObject();
    const QString fileName = classObject["filename"].toString();
    const QJsonArray matchesArray = classObject["matches"].toArray();
    if (matchesArray.isEmpty()) {
      continue;
    }
    // create filename ClassTreeItem and add to root
    ClassTreeItem *pClassTreeItem = new ClassTreeItem(fileName, mpRootClassTreeItem);
    mpRootClassTreeItem->insertChild(mpRootClassTreeItem->childrenSize(), pClassTreeItem);
    // create matches ClassTreeItem and add to filename ClassTreeItem
    matchesCount += matchesArray.size();
    for (const QJsonValue &matchValue : matchesArray) {
      const QJsonObject matchObject = matchValue.toObject();
      int lineStart = matchObject["lineStart"].toInt();
      int lineEnd = matchObject["lineEnd"].toInt();
      int columnStart = matchObject["columnStart"].toInt();
      int columnEnd = matchObject["columnEnd"].toInt();
      const QString name = matchObject["name"].toString();
      const QString className = matchObject["class"].toString();
      ClassTreeItem *pMatchClassTreeItem = new ClassTreeItem(name, className, lineStart, lineEnd, columnStart, columnEnd, pClassTreeItem);
      pClassTreeItem->insertChild(pClassTreeItem->childrenSize(), pMatchClassTreeItem);
    }
  }
  endResetModel();
  return matchesCount;
}

/*!
 * \class ClassTreeView
 * \brief A tree view for find usage.
 */
/*!
 * \brief ClassTreeView::ClassTreeView
 * \param pParent
 */
ClassTreeView::ClassTreeView(QWidget *pParent)
  : QTreeView(pParent)
{
  setItemDelegate(new ItemDelegate(this));
  setTextElideMode(Qt::ElideMiddle);
  setIndentation(Helper::treeIndentation);
  setUniformRowHeights(true);
  setHeaderHidden(true);
}

/*!
 * \brief ClassTreeView::onDoubleClicked
 * Handles the double click on ClassTreeItem. If the double clicked item is a match item then opens the corresponding file at line number.
 * \param index
 */
void ClassTreeView::onDoubleClicked(const QModelIndex &index)
{
  if (!index.isValid()) {
    return;
  }
  // Map proxy index → source index before touching internalPointer
  QModelIndex sourceIndex = FindUsageWidget::instance()->getClassTreeProxyModel()->mapToSource(index);
  if (sourceIndex.isValid()) {
    ClassTreeItem *pClassTreeItem = static_cast<ClassTreeItem*>(sourceIndex.internalPointer());
    if (pClassTreeItem && pClassTreeItem->childrenSize() == 0) {
      QString url = QString("omeditmessagesbrowser:///%1?lineNumber=%2").arg(pClassTreeItem->getClassName()).arg(pClassTreeItem->getLineStart());
      MessagesWidget::instance()->getAllMessageWidget()->openErrorMessageClass(QUrl(url));
    }
  }
}

FindUsageWidget *FindUsageWidget::mpInstance = 0;

/*!
 * \brief FindUsageWidget::create
 */
void FindUsageWidget::create()
{
  if (!mpInstance) {
    mpInstance = new FindUsageWidget;
  }
}

/*!
 * \brief FindUsageWidget::destroy
 */
void FindUsageWidget::destroy()
{
  /* We want to delete right away instead to clean stuff properly in beforeClosingMainWindow
   * So don not use deleteLater();
   */
  //mpInstance->deleteLater();
  delete mpInstance;
  mpInstance = 0;
}

/*!
 * \brief FindUsageWidget::FindUsageWidget
 * \param pParent
 */
FindUsageWidget::FindUsageWidget(QWidget *pParent)
  : QWidget(pParent)
{
  // find usage
  mpFindUsageTextBox = new LineEdit(this);
  mpFindUsageTextBox->setPlaceholderText(tr("Enter class name to find its usage"));
  // scope
  LineEdit *pScopeTextBox = new LineEdit(this);
  pScopeTextBox->setPlaceholderText(tr("Enter scope or browse (optional)"));
  QPushButton *pBrowseButton = new QPushButton(Helper::browse);
  connect(pBrowseButton, &QPushButton::clicked, [ pScopeTextBox](){
    LibraryBrowseDialog *pLibraryBrowseDialog = new LibraryBrowseDialog(tr("Select Scope"), pScopeTextBox, MainWindow::instance()->getLibraryWidget());
    pLibraryBrowseDialog->exec();
  });
  // exact match
  QCheckBox *pExactMatch = new QCheckBox(tr("Exact Match"));
  pExactMatch->setChecked(true);
  // find usage button
  QPushButton *pFindUsageButton = new QPushButton(tr("Find Usage"), this);
  connect(pFindUsageButton, &QPushButton::clicked, [this, pScopeTextBox, pExactMatch](){
    const QString className = mpFindUsageTextBox->text().trimmed();
    const QString scope = pScopeTextBox->text().trimmed();
    if (!className.isEmpty()) {
      findUsageOfClass(className, scope, pExactMatch->isChecked());
    }
  });
  // tree model, proxy and view
  mpClassTreeModel = new ClassTreeModel(this);
  mpClassTreeProxyModel = new ClassTreeProxyModel(this);
  mpClassTreeProxyModel->setDynamicSortFilter(true);
  mpClassTreeProxyModel->setSourceModel(mpClassTreeModel);
  mpClassTreeView = new ClassTreeView(this);
  mpClassTreeView->setModel(mpClassTreeProxyModel);
  connect(mpClassTreeView, &QTreeView::doubleClicked, mpClassTreeView, &ClassTreeView::onDoubleClicked);
  mpMatchesFoundLabel = new Label;
  mpMatchesFoundLabel->hide();
  // tree search filters
  mpTreeSearchFilters = new TreeSearchFilters(this);
  mpTreeSearchFilters->getFilterTextBox()->setPlaceholderText(tr("Filter Matches"));
  connect(mpTreeSearchFilters->getFilterTextBox(), SIGNAL(returnPressed()), SLOT(filterMatches()));
  connect(mpTreeSearchFilters->getFilterTextBox(), SIGNAL(textEdited(QString)), SLOT(filterMatches()));
  connect(mpTreeSearchFilters->getCaseSensitiveCheckBox(), SIGNAL(toggled(bool)), SLOT(filterMatches()));
  connect(mpTreeSearchFilters->getSyntaxComboBox(), SIGNAL(currentIndexChanged(int)), SLOT(filterMatches()));
  connect(mpTreeSearchFilters->getExpandAllButton(), SIGNAL(clicked()), mpClassTreeView, SLOT(expandAll()));
  connect(mpTreeSearchFilters->getCollapseAllButton(), SIGNAL(clicked()), mpClassTreeView, SLOT(collapseAll()));
  // create the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setContentsMargins(0, 0, 0, 0);
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpFindUsageTextBox, 0, 0);
  pMainLayout->addWidget(pScopeTextBox, 0, 1);
  pMainLayout->addWidget(pBrowseButton, 0, 2);
  pMainLayout->addWidget(pExactMatch, 0, 3);
  pMainLayout->addWidget(pFindUsageButton, 0, 4);
  pMainLayout->addWidget(mpMatchesFoundLabel, 1, 0, 1, 5);
  pMainLayout->addWidget(mpTreeSearchFilters, 2, 0, 1, 5);
  pMainLayout->addWidget(mpClassTreeView, 3, 0, 1, 5);
  setLayout(pMainLayout);
}

/*!
 * \brief FindUsageWidget::updateMatchesFoundLabel
 * Updates the matches found label with the given class name and matches count.
 * \param className
 * \param matchesCount
 */
void FindUsageWidget::updateMatchesFoundLabel(const QString &className, int matchesCount)
{
  const QString text = QString(tr("%1 matches found for <b>%2</b>").arg(matchesCount).arg(className));
  mpMatchesFoundLabel->setText(text);
  mpMatchesFoundLabel->show();
}

/*!
 * \brief FindUsageWidget::findUsageOfClass
 * Finds the usage of the given class name in the given scope and updates the Class Tree with the results.
 * \param className
 * \param scope
 * \param exactMatch
 */
void FindUsageWidget::findUsageOfClass(const QString &className, const QString &scope, bool exactMatch)
{
  mpFindUsageTextBox->setText(className);
  const QJsonArray classesJSON = MainWindow::instance()->getOMCProxy()->reverseLookup(className, scope.isEmpty() ? "AllLoadedClasses" : scope, exactMatch);
  updateMatchesFoundLabel(className, mpClassTreeModel->addClasses(classesJSON));
}

/*!
 * \brief FindUsageWidget::filterMatches
 * Filters the matches in Class Tree based on the filter text, case sensitivity and syntax.
 */
void FindUsageWidget::filterMatches()
{
  QString searchText = mpTreeSearchFilters->getFilterTextBox()->text();
  Qt::CaseSensitivity caseSensitivity = mpTreeSearchFilters->getCaseSensitiveCheckBox()->isChecked() ? Qt::CaseSensitive: Qt::CaseInsensitive;
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
  // TODO: handle PatternSyntax: https://doc.qt.io/qt-6/qregularexpression.html
  mpClassTreeProxyModel->setFilterRegularExpression(QRegularExpression::fromWildcard(searchText, caseSensitivity, QRegularExpression::UnanchoredWildcardConversion));
#else
  QRegExp::PatternSyntax syntax = QRegExp::PatternSyntax(mpTreeSearchFilters->getSyntaxComboBox()->itemData(mpTreeSearchFilters->getSyntaxComboBox()->currentIndex()).toInt());
  QRegExp regExp(searchText, caseSensitivity, syntax);
  mpClassTreeProxyModel->setFilterRegExp(regExp);
#endif
}
