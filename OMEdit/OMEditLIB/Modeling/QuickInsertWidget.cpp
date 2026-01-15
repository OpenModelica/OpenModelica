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
#include "Options/OptionsDialog.h"
#include "Util/StringHandler.h"
#include <QApplication>
#include <QHBoxLayout>
#include <QKeyEvent>
#include <QLineEdit>
#include <QListView>
#include <QScreen>
#include <QStandardItemModel>
#include <QVBoxLayout>

namespace
{

/*!
 * \brief getClassName
 * Extracts the class name (e.g., "Sine") from a full path
 * (e.g., "Modelica.Blocks.Sources.Sine").
 */
QString getClassName(const QString &fullPath)
{
  return StringHandler::getLastWordAfterDot(fullPath);
}

/*!
 * \brief getPath
 * Extracts the path (e.g., "Modelica.Blocks.Sources") from a full path
 * (e.g., "Modelica.Blocks.Sources.Sine").
 */
QString getPath(const QString &fullPath) { return StringHandler::removeLastWordAfterDot(fullPath); }

/*!
 * \brief calculateNameScore
 * Calculates a score for a simple name match (Exact, StartsWith, Contains).
 * \param pattern The search pattern (e.g., "Sine").
 * \param className The class name (e.g., "Sine").
 * \return An integer score (1000, 800, 500) or 0.
 */
int calculateNameScore(const QString &pattern, const QString &className)
{
  if (pattern.isEmpty() || className.isEmpty()) {
    return 0;
  }
  if (className.compare(pattern, Qt::CaseInsensitive) == 0) {
    return 1000;
  }
  if (className.startsWith(pattern, Qt::CaseInsensitive)) {
    return 800 - className.length();
  }
  if (className.contains(pattern, Qt::CaseInsensitive)) {
    return 500 - className.indexOf(pattern, 0, Qt::CaseInsensitive) - className.length();
  }
  return 0;
}

/*!
 * \brief calculateFuzzyPathScore
 * Calculates a score for a "fuzzy" path match.
 * Splits pattern and path by '.' and checks if all pattern parts
 * are found in the path parts in the correct order using 'startsWith'.
 * \param pattern The search pattern (e.g., "mult.for").
 * \param fullPath The full path (e.g., "Modelica.Mechanics.MultiBody.Forces.Force").
 * \return An integer score (max 700). Higher is better.
 */
int calculateFuzzyPathScore(const QString &pattern, const QString &fullPath)
{
  const QStringList patternParts = pattern.split('.');
  const QStringList pathParts = fullPath.split('.');

  if (patternParts.isEmpty()) {
    return 0;
  }

  int pathIdx = 0;
  for (const QString &part : patternParts) {
    bool partFound = false;
    while (pathIdx < pathParts.size()) {
      if (pathParts.at(pathIdx).startsWith(part, Qt::CaseInsensitive)) {
        partFound = true;
        pathIdx++;
        break;
      }
      pathIdx++;
    }
    if (!partFound) {
      return 0;
    }
  }
  return 700 - pathParts.size();
}

/*!
 * \brief rankingScore
 * Calculates a score for a match, used to rank search results.
 *
 * - If pattern contains no '.', it searches only the className (Prioritizing Exact/StartsWith).
 * (e.g., "Sine" -> calculateNameScore("Sine", "Sine"))
 *
 * - If pattern contains a '.', it triggers a hybrid path/name search.
 * (e.g., "mul.force" -> path "mul" vs target path AND name "force" vs target name)
 *
 * \param pattern The search pattern entered by the user.
 * \param className The *pure* class name (not the full path) being checked.
 * \param fullPath The full path (e.g. Modelica.Blocks.Examples.Sine)
 * \return An integer score. Higher is better.
 */
int rankingScore(const QString &pattern, const QString &className, const QString &fullPath)
{
  if (pattern.isEmpty()) {
    return 0;
  }

  int score = 0;

  if (pattern.contains('.')) {
    // Hybrid path/name search
    const int lastDot = pattern.lastIndexOf('.');
    const QString patternPath = pattern.left(lastDot);
    const QString patternName = pattern.mid(lastDot + 1);

    // An empty patternPath (e.g., query ".Sine") is always a valid path match.
    const bool pathMatch = patternPath.isEmpty()
                               ? true
                               : (calculateFuzzyPathScore(patternPath, getPath(fullPath)) > 0);

    if (pathMatch) {
      score = calculateNameScore(patternName, className);
    }
  } else {
    // Name-only search
    score = calculateNameScore(pattern, className);
  }

  if (score == 0) {
    return 0;
  }

  // Apply penalty for examples so they don't show up first for exact name matches
  if (fullPath.contains(".Examples.", Qt::CaseInsensitive)) {
    score = qMax(1, score - 100);
  }

  return score;
}
} // namespace

ModelItemDelegate::ModelItemDelegate(QObject *parent) : QStyledItemDelegate(parent) {}

void ModelItemDelegate::paint(QPainter *painter, const QStyleOptionViewItem &option,
                              const QModelIndex &index) const
{
  painter->save();
  painter->setRenderHint(QPainter::Antialiasing, true);

  QIcon icon = index.data(Qt::DecorationRole).value<QIcon>();
  QString className = index.data(Qt::DisplayRole).toString();
  QString path = index.data(Qt::UserRole).toString();

  // Draw background (selection / hover)
  QStyle::State state = option.state;
  if (state & QStyle::State_Selected) {
    painter->fillRect(option.rect, option.palette.brush(QPalette::Highlight));
  } else if (state & QStyle::State_MouseOver) {
    painter->fillRect(option.rect, option.palette.brush(QPalette::Midlight));
  }

  // Set text color
  QPalette::ColorGroup cg =
      option.state & QStyle::State_Enabled ? QPalette::Normal : QPalette::Disabled;
  QColor textColor = (state & QStyle::State_Selected)
                         ? option.palette.color(cg, QPalette::HighlightedText)
                         : option.palette.color(cg, QPalette::Text);
  painter->setPen(textColor);

  // Geometry
  QRect contentRect = option.rect;
  int padding = 5;
  int iconSize = 24;

  // 1. Draw Icon
  QRect iconRect = QRect(contentRect.left() + padding, contentRect.center().y() - (iconSize / 2),
                         iconSize, iconSize);
  if (!icon.isNull()) {
    icon.paint(painter, iconRect, Qt::AlignCenter);
  }

  // 2. Define text layout area
  int textLeft = iconRect.right() + padding;
  QRect textRect(textLeft, contentRect.top(), contentRect.width() - textLeft - padding,
                 contentRect.height());

  // 3. Draw Class Name (Bold)
  QFont classNameFont = option.font;
  classNameFont.setBold(true);
  painter->setFont(classNameFont);

  QFontMetrics fm(classNameFont);
  int classNameHeight = fm.height();

  // 4. Draw Path (Normal / Faded)
  QFont pathFont = option.font;
  QFontMetrics fmPath(pathFont);
  int pathHeight = fmPath.height();

  // Vertical positioning for two lines
  int totalTextHeight = classNameHeight + pathHeight;
  int yOffset = (contentRect.height() - totalTextHeight) / 2; // Center vertically

  QRect classNameRect(textLeft, contentRect.top() + yOffset, textRect.width(), classNameHeight);
  painter->drawText(classNameRect, Qt::AlignVCenter | Qt::AlignLeft,
                    fm.elidedText(className, Qt::ElideRight, classNameRect.width()));

  QRect pathRect(textLeft, classNameRect.bottom(), textRect.width(), pathHeight);

  // Use faded color for path if not selected
  if (!(state & QStyle::State_Selected)) {
    painter->setPen(option.palette.color(QPalette::Disabled, QPalette::Text));
  }
  painter->setFont(pathFont);
  painter->drawText(pathRect, Qt::AlignVCenter | Qt::AlignLeft,
                    fmPath.elidedText(path, Qt::ElideRight, pathRect.width()));

  painter->restore();
}

QSize ModelItemDelegate::sizeHint(const QStyleOptionViewItem &option,
                                  const QModelIndex &index) const
{
  Q_UNUSED(index);
  QFontMetrics fm(option.font);
  int textHeight = fm.height();

  // Height for 2 lines of text + padding, or min icon size + padding
  int desiredHeight = (textHeight * 2) + 8;    // 8px padding
  desiredHeight = qMax(desiredHeight, 24 + 8); // Min height 32 (for 24px icon)
  return QSize(option.rect.width(), desiredHeight);
}

ClassNameFilterProxyModel::ClassNameFilterProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
  setDynamicSortFilter(true);
  sort(0, Qt::DescendingOrder);
}

void ClassNameFilterProxyModel::setFilterString(const QString &pattern)
{
  mFuzzyPattern = pattern;
  invalidateFilter(); // Retriggers filtering and sorting
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
  QString className = getClassName(fullPath);

  // Score will always be > 0
  bool scoreMatch = rankingScore(mFuzzyPattern, className, fullPath) > 0;
  if (!scoreMatch) {
    return false;
  }

  return true;
}

bool ClassNameFilterProxyModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
  QString leftFullPath = sourceModel()->data(left, Qt::DisplayRole).toString();
  QString rightFullPath = sourceModel()->data(right, Qt::DisplayRole).toString();

  QString leftClassName = getClassName(leftFullPath);
  QString rightClassName = getClassName(rightFullPath);

  int leftScore = rankingScore(mFuzzyPattern, leftClassName, leftFullPath);
  int rightScore = rankingScore(mFuzzyPattern, rightClassName, rightFullPath);

  return leftScore < rightScore;
}

QVariant ClassNameFilterProxyModel::data(const QModelIndex &index, int role) const
{
  if (!index.isValid())
    return QVariant();

  QModelIndex sourceIndex = mapToSource(index);
  QString fullPath = sourceModel()->data(sourceIndex, Qt::DisplayRole).toString();

  switch (role) {
    case Qt::DecorationRole:
      // Requested by delegate for the icon
      return sourceModel()->data(sourceIndex, Qt::DecorationRole);

    case Qt::DisplayRole:
      // Requested by delegate for the main text (Class Name)
      return getClassName(fullPath);

    case Qt::UserRole:
      // Requested by delegate for the sub-text (Path)
      return getPath(fullPath);

    default:
      // Handle other roles (e.g., ToolTipRole) normally
      return QSortFilterProxyModel::data(index, role);
  }
}

Qt::ItemFlags ClassNameFilterProxyModel::flags(const QModelIndex &index) const
{
  // Make the items non-editable.
  return QSortFilterProxyModel::flags(index) & ~Qt::ItemIsEditable;
}

QuickInsertWidget::QuickInsertWidget(LibraryTreeModel *model, QWidget *parent)
    : QWidget(parent, Qt::Popup), mpLibraryTreeModel(model)
{
  setWindowFlags(Qt::Popup | Qt::FramelessWindowHint);
  setAttribute(Qt::WA_DeleteOnClose);

  mpSearchLineEdit = new QLineEdit(this);
  mpSearchLineEdit->setPlaceholderText(tr("Search models..."));

  mpResultsListView = new QListView(this);
  mpSourceModel = new QStandardItemModel(this);
  mpProxyModel = new ClassNameFilterProxyModel(this);

  mpProxyModel->setSourceModel(mpSourceModel);
  mpResultsListView->setModel(mpProxyModel);
  mpResultsListView->setItemDelegate(new ModelItemDelegate(this));

  // Setup Layout
  QHBoxLayout *topLayout = new QHBoxLayout();
  topLayout->setContentsMargins(0, 0, 0, 0);
  topLayout->addWidget(mpSearchLineEdit);

  QVBoxLayout *layout = new QVBoxLayout(this);
  layout->setContentsMargins(1, 1, 1, 1);
  layout->setSpacing(0);
  layout->addLayout(topLayout);
  layout->addWidget(mpResultsListView);
  setLayout(layout);

  populateModel();

  connect(mpSearchLineEdit, &QLineEdit::textChanged, this, &QuickInsertWidget::onSearchTextChanged);
  connect(mpResultsListView, &QListView::activated, this, &QuickInsertWidget::onListItemActivated);

  mpSearchLineEdit->installEventFilter(this);
  mpResultsListView->installEventFilter(this);

  resize(400, 300);
}

void QuickInsertWidget::populateModel()
{
  std::function<void(const QModelIndex &)> recursive_populate =
      [&](const QModelIndex &parentIndex) {
        int rowCount = mpLibraryTreeModel->rowCount(parentIndex);
        for (int i = 0; i < rowCount; ++i) {
          QModelIndex index = mpLibraryTreeModel->index(i, 0, parentIndex);
          LibraryTreeItem *item = static_cast<LibraryTreeItem *>(index.internalPointer());

          if (item && item->isModelica() && !item->isPartial() && !item->isInternal()) {
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

                QStandardItem *modelItem = new QStandardItem();
                // Store full path in DisplayRole (used for filtering/sorting)
                modelItem->setData(item->getNameStructure(), Qt::DisplayRole);
                // Store icon in DecorationRole (used by delegate)
                modelItem->setData(mpLibraryTreeModel->data(index, Qt::DecorationRole),
                                   Qt::DecorationRole);
                mpSourceModel->appendRow(modelItem);
              }
            }
          }
          if (mpLibraryTreeModel->hasChildren(index)) {
            recursive_populate(index);
          }
        }
      };
  recursive_populate(QModelIndex());
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
  if (event->type() != QEvent::KeyPress) {
    return QWidget::eventFilter(watched, event);
  }

  QKeyEvent *keyEvent = static_cast<QKeyEvent *>(event);
  int key = keyEvent->key();

  if (watched == mpSearchLineEdit) {
    if (key == Qt::Key_Down) {
      // Focus list view if not empty
      if (mpProxyModel->rowCount() > 0) {
        mpResultsListView->setFocus();
        mpResultsListView->setCurrentIndex(mpProxyModel->index(0, 0));
      }
      return true; // Event handled
    }
    if (key == Qt::Key_Return || key == Qt::Key_Enter) {
      // Activate first item on Enter
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
    // Return focus to search bar when pressing Up at the top of the list
    if (key == Qt::Key_Up && mpResultsListView->currentIndex().row() == 0) {
      mpSearchLineEdit->setFocus();
      return true;
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
    // Get the original full path from the source model
    mSelectedClass = mpProxyModel->sourceModel()->data(sourceIndex).toString();
    emit classSelected(mSelectedClass);
    close();
  }
}
