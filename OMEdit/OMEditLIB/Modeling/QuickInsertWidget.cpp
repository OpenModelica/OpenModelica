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
 * @author Quentin Huss <quentinhuss@hotmail.com>
 */

#include "QuickInsertWidget.h"
#include "Modeling/LibraryTreeWidget.h" // For LibraryTreeModel and LibraryTreeItem
#include "Modeling/MessagesWidget.h"    // For error reporting, good practice
#include "Options/OptionsDialog.h"
#include <QApplication>
#include <QScreen>
#include <QVBoxLayout>

static int rankingScore(const QString &pattern, const QString &className);

// --- ClassNameFilterProxyModel Implementation ---
ClassNameFilterProxyModel::ClassNameFilterProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
  // Enable dynamic sorting and sort by score in descending order.
  setDynamicSortFilter(true);
  sort(0, Qt::DescendingOrder);
}

void ClassNameFilterProxyModel::setFilterString(const QString &pattern)
{
  mFuzzyPattern = pattern;
  invalidateFilter();
}

bool ClassNameFilterProxyModel::filterAcceptsRow(int source_row,
                                                 const QModelIndex &source_parent) const
{
  Q_UNUSED(source_parent);
  if (mFuzzyPattern.isEmpty()) {
    return false;
  }
  QModelIndex index = sourceModel()->index(source_row, 0, source_parent);
  QString fullPath = sourceModel()->data(index).toString();

  int lastDot = fullPath.lastIndexOf('.');
  QString className = (lastDot != -1) ? fullPath.mid(lastDot + 1) : fullPath;

  return className.contains(mFuzzyPattern, Qt::CaseInsensitive);
}

bool ClassNameFilterProxyModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
  QString leftData = sourceModel()->data(left, Qt::DisplayRole).toString();
  QString rightData = sourceModel()->data(right, Qt::DisplayRole).toString();
  return rankingScore(mFuzzyPattern, leftData) < rankingScore(mFuzzyPattern, rightData);
}

QVariant ClassNameFilterProxyModel::data(const QModelIndex &index, int role) const
{
  if (role == Qt::DisplayRole && index.isValid()) {
    QModelIndex sourceIndex = mapToSource(index);
    QString fullPath = sourceModel()->data(sourceIndex).toString();
    int lastDot = fullPath.lastIndexOf('.');
    if (lastDot != -1) {
      QString className = fullPath.mid(lastDot + 1);
      QString path = fullPath.left(lastDot);
      return QString("%1 [%2]").arg(className, path);
    }
    return fullPath; // Fallback for names without a path
  }
  return QSortFilterProxyModel::data(index, role);
}

Qt::ItemFlags ClassNameFilterProxyModel::flags(const QModelIndex &index) const
{
  // Make the items non-editable.
  return QSortFilterProxyModel::flags(index) & ~Qt::ItemIsEditable;
}

// --- QuickInsertWidget Implementation ---
QuickInsertWidget::QuickInsertWidget(LibraryTreeModel *model, QWidget *parent)
    : QWidget(parent, Qt::Popup), mpLibraryTreeModel(model)
{
  setWindowFlags(Qt::Popup | Qt::FramelessWindowHint);
  setAttribute(Qt::WA_DeleteOnClose);

  mpSearchLineEdit = new QLineEdit(this);
  //: Placeholder text for the model search input field in the quick insert
  //: menu.
  mpSearchLineEdit->setPlaceholderText(tr("Search models..."));
  mpResultsListView = new QListView(this);
  mpSourceModel = new QStringListModel(this);
  mpProxyModel = new ClassNameFilterProxyModel(this);

  mpProxyModel->setSourceModel(mpSourceModel);
  mpResultsListView->setModel(mpProxyModel);

  QVBoxLayout *layout = new QVBoxLayout(this);
  layout->setContentsMargins(1, 1, 1, 1);
  layout->setSpacing(0);
  layout->addWidget(mpSearchLineEdit);
  layout->addWidget(mpResultsListView);
  setLayout(layout);

  populateModel();

  connect(mpSearchLineEdit, &QLineEdit::textChanged, this, &QuickInsertWidget::onSearchTextChanged);
  connect(mpResultsListView, &QListView::activated, this, &QuickInsertWidget::onListItemActivated);

  mpSearchLineEdit->installEventFilter(this);
  mpResultsListView->installEventFilter(this);

  // default window size
  resize(400, 300);
}

void QuickInsertWidget::populateModel()
{
  QStringList classes;
  std::function<void(const QModelIndex &)> recursive_populate = [&](const QModelIndex
                                                                        &parentIndex) {
    int rowCount = mpLibraryTreeModel->rowCount(parentIndex);
    for (int i = 0; i < rowCount; ++i) {
      QModelIndex index = mpLibraryTreeModel->index(i, 0, parentIndex);
      LibraryTreeItem *item = static_cast<LibraryTreeItem *>(index.internalPointer());

      if (item) {
        if (!item->isPartial() && !item->isInternal()) {
          // Filtering logic taken from `LibraryTreeProxyModel::filterAcceptsRow`
          bool hide =
              ((item->getAccess() == LibraryTreeItem::hide &&
                !(OptionsDialog::instance()->getGeneralSettingsPage()->getShowHiddenClasses() &&
                  !item->isEncryptedClass())) ||
               (item->isProtected() &&
                !OptionsDialog::instance()->getGeneralSettingsPage()->getShowProtectedClasses()));

          if (!hide) {
            const auto restriction = item->getRestriction();
            if (restriction == StringHandler::Model || restriction == StringHandler::Class ||
                restriction == StringHandler::Connector || restriction == StringHandler::Record ||
                restriction == StringHandler::Block) {
              if (!item->getNameStructure().contains(".Examples.", Qt::CaseInsensitive)) {
                classes.append(item->getNameStructure());
              }
            }
          }
        }
        if (mpLibraryTreeModel->hasChildren(index)) {
          recursive_populate(index);
        }
      }
    }
  };
  recursive_populate(QModelIndex());
  mpSourceModel->setStringList(classes);
}

void QuickInsertWidget::showAt(const QPoint &pos)
{
  move(pos);
  show();
  mpSearchLineEdit->setFocus();
  mpSearchLineEdit->selectAll();
}

QString QuickInsertWidget::getSelectedClass() const { return mSelectedClass; }

void QuickInsertWidget::keyPressEvent(QKeyEvent *event)
{
  if (event->key() == Qt::Key_Escape) {
    mSelectedClass.clear();
    close();
    event->accept();
  } else {
    QWidget::keyPressEvent(event);
  }
}

bool QuickInsertWidget::eventFilter(QObject *watched, QEvent *event)
{
  if (event->type() == QEvent::KeyPress) {
    QKeyEvent *keyEvent = static_cast<QKeyEvent *>(event);
    int key = keyEvent->key();

    if (watched == mpSearchLineEdit) {
      if (key == Qt::Key_Down) {
        mpResultsListView->setFocus();
        mpResultsListView->setCurrentIndex(mpProxyModel->index(0, 0));
        return true;
      } else if (key == Qt::Key_Return || key == Qt::Key_Enter) {
        if (mpProxyModel->rowCount() > 0) {
          onListItemActivated(mpProxyModel->index(0, 0));
        }
        return true;
      }
    } else if (watched == mpResultsListView) {
      if (key == Qt::Key_Return || key == Qt::Key_Enter) {
        onListItemActivated(mpResultsListView->currentIndex());
        return true;
      }
    }
  }
  return QWidget::eventFilter(watched, event);
}

void QuickInsertWidget::onSearchTextChanged(const QString &text)
{
  mpProxyModel->setFilterString(text);
  if (mpProxyModel->rowCount() > 0) {
    mpResultsListView->setCurrentIndex(mpProxyModel->index(0, 0));
  }
}

void QuickInsertWidget::onListItemActivated(const QModelIndex &index)
{
  if (index.isValid()) {
    QModelIndex sourceIndex = mpProxyModel->mapToSource(index);
    mSelectedClass = mpProxyModel->sourceModel()->data(sourceIndex).toString();
    emit classSelected(mSelectedClass);
    close();
  }
}

/*!
 * \brief rankingScore
 * Calculates a score for a match, used to rank search results.
 * \param pattern The search pattern entered by the user.
 * \param fullPath The full path of the model being checked.
 * \return An integer score. Higher is better.
 */
static int rankingScore(const QString &pattern, const QString &fullPath)
{
  if (pattern.isEmpty())
    return 1;
  if (fullPath.isEmpty())
    return 0;

  int lastDot = fullPath.lastIndexOf('.');
  QString className = (lastDot != -1) ? fullPath.mid(lastDot + 1) : fullPath;

  if (className.compare(pattern, Qt::CaseInsensitive) == 0) {
    return 1000; // Exact match
  }
  if (className.startsWith(pattern, Qt::CaseInsensitive)) {
    return 800 - className.length(); // "Starts with" match, prefer shorter results
  }
  if (className.contains(pattern, Qt::CaseInsensitive)) {
    return 500 - className.indexOf(pattern, 0, Qt::CaseInsensitive) -
           className.length(); // "Contains" match, prefer matches closer
                               // to the start
  }
  return 0; // No match
}
