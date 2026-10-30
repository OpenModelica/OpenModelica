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

#include "ElementProperties.h"
#include "MainWindow.h"
#include "Modeling/Commands.h"
#include "Modeling/ItemDelegate.h"
#include "Options/OptionsDialog.h"
#include "OMPlot.h"
#include "FlatModelica/Parser.h"
#include "FlatModelica/Expression.h"

#include <QApplication>
#include <QMenu>
#include <QWidgetAction>
#include <QButtonGroup>
#include <QMessageBox>
#include <QDesktopServices>
#include <QList>
#include <QScreen>
#include <QSet>
#include <QStringList>
#include <QStringBuilder>
#include <QTableWidget>

#include <algorithm>

// tabs
static QString General("General");
static QString Modifiers("Modifiers");
// groups
static QString Parameters("Parameters");
static QString Initialization("Initialization");
static QString AddNewModifiers("Add New Modifiers");

static int DefaultMinimumWidthForValue = 100;
static int DefaultMinimumWidthForComment = 300;

/*!
 * \class FinalEachToolButton
 * \brief Creates a toolbutton with drop menu for final and each modifiers.
 */
/*!
 * \brief FinalEachToolButton::FinalEachToolButton
 * \param canHaveEach
 * \param parent
 */
FinalEachToolButton::FinalEachToolButton(bool canHaveEach, QWidget *parent)
  : QToolButton(parent)
{
  setIcon(QIcon(":/Resources/icons/drop-menu.svg"));
  setAutoRaise(true);
  // final action
  mpFinalAction = new QAction("final");
  mpFinalAction->setCheckable(true);
  // each action
  mpEachAction = new QAction("each");
  mpEachAction->setCheckable(true);
  // break action
  mpBreakAction = new QAction(Helper::BREAK);
  mpBreakAction->setCheckable(true);
  connect(mpBreakAction, SIGNAL(toggled(bool)), SIGNAL(breakToggled(bool)));
  // create a menu
  mpFinalEachMenu = new QMenu;
  mpFinalEachMenu->addAction(mpFinalAction);
  if (canHaveEach) {
    mHasEach = canHaveEach;
    mpFinalEachMenu->addAction(mpEachAction);
  }
  mpFinalEachMenu->addSeparator();
  mpFinalEachMenu->addAction(mpBreakAction);

  connect(this, SIGNAL(clicked()), SLOT(showParameterMenu()));
}

void FinalEachToolButton::setFinal(bool final)
{
  mpFinalAction->setChecked(final);
  mFinalDefault = final;
}

void FinalEachToolButton::setEach(bool each)
{
  mpEachAction->setChecked(each);
  mEachDefault = each;
}

void FinalEachToolButton::setBreak(bool break_)
{
  bool state = mpBreakAction->blockSignals(true);
  mpBreakAction->setChecked(break_);
  mpBreakAction->blockSignals(state);
  mBreakDefault = break_;
}

/*!
 * \brief FinalEachToolButton::isModified
 * \return true if final or each or break are modified.
 */
bool FinalEachToolButton::isModified() const
{
  if (mFinalDefault != isFinal() || mEachDefault != isEach() || mBreakDefault != isBreak()) {
    return true;
  } else {
    return false;
  }
}

/*!
 * \brief FinalEachToolButton::showParameterMenu
 * Slot activated when clicked SIGNAL is raised.
 * Shows the menu.
 */
void FinalEachToolButton::showParameterMenu()
{
  mpFinalEachMenu->exec(mapToGlobal(QPoint(0, 0)));
}

/*!
 * \brief ArrayParameterEditorDialog::ArrayParameterEditorDialog
 * Creates an editor to enter the cells of an array parameter like a table on paper.
 * \a arrayValue is shown as text in the expression field.
 * \a defaultValue is shown as placeholder text and used when clearing the expression.
 * Dimension expressions control which rows and columns are fixed. Typed dimensions
 * provide values for symbolic dimensions.
 * Unfixed dimensions can be changed with the Rows and Columns spin boxes.
 * Arrays with more than 2 dimensions are shown as a 2D table where each cell
 * holds a nested array literal e.g. a 3D array is shown as a matrix of vectors.
 * When \a arrayValue is a supported array literal, the table is filled with the
 * parsed cells. Unsupported expressions stay in the expression field while the
 * table remains editable.
 * \param arrayValue current array value e.g. [[1, 2]; [3, 4]]
 * \param defaultValue default array value shown as placeholder
 * \param elementName name of the edited element shown in the window title
 * \param absynDimensions dimensions as written in the model
 * \param typedDimensions evaluated dimensions
 * \param pParent parent widget
 */
ArrayParameterEditorDialog::ArrayParameterEditorDialog(const QString &arrayValue, const QString &defaultValue, const QString &elementName,
                                                       const QStringList &absynDimensions, const QStringList &typedDimensions, QWidget *pParent)
  : QDialog(pParent)
{
  setWindowTitle(tr("%1 - %2 %3").arg(Helper::applicationName, Helper::editArray, elementName));
  mArrayDimensions = qMax(absynDimensions.size(), typedDimensions.size());
  mVector = mArrayDimensions == 1;
  for (int i = 2; i < mArrayDimensions; ++i) {
    const QString absynDimension = i < absynDimensions.size() ? absynDimensions.at(i).trimmed() : QString();
    bool ok = false;
    int dimension = absynDimension.toInt(&ok);
    if (!ok && i < typedDimensions.size()) {
      dimension = typedDimensions.at(i).trimmed().toInt(&ok);
    }
    if (!ok || dimension < 0) {
      mCellDimensions.clear();
      break;
    }
    mCellDimensions.append(QString::number(dimension));
  }
  mpArrayTableWidget = new QTableWidget;
  mpArrayTableWidget->setItemDelegate(new ItemDelegate(mpArrayTableWidget));
  mpArrayTableWidget->setMinimumSize(500, 300);
  Label *pRowsLabel = new Label(tr("Rows:"));
  mpRowsSpinBox = new QSpinBox;
  mpRowsSpinBox->setRange(0, 1000);
  Label *pColumnsLabel = new Label(tr("Columns:"));
  mpColumnsSpinBox = new QSpinBox;
  mpColumnsSpinBox->setRange(0, 1000);
  for (int i = 0; i < qMin(2, mArrayDimensions); ++i) {
    const QString absynDimension = i < absynDimensions.size() ? absynDimensions.at(i).trimmed() : QString();
    if (absynDimension == QLatin1String(":")) {
      continue;
    }

    bool ok = false;
    int dimension = absynDimension.toInt(&ok);
    if (!ok && i < typedDimensions.size()) {
      dimension = typedDimensions.at(i).trimmed().toInt(&ok);
    }
    if (ok && dimension >= 0) {
      if (i == 0) {
        mRowsFixed = true;
        mFixedRows = dimension;
        mpRowsSpinBox->setRange(0, qMax(1000, dimension));
        mpRowsSpinBox->setValue(dimension);
      } else {
        mColumnsFixed = true;
        mFixedColumns = dimension;
        mpColumnsSpinBox->setRange(0, qMax(1000, dimension));
        mpColumnsSpinBox->setValue(dimension);
      }
    }
  }
  if (mVector) {
    mColumnsFixed = true;
    mFixedColumns = 1;
    mpColumnsSpinBox->setValue(1);
    pColumnsLabel->hide();
    mpColumnsSpinBox->hide();
  }
  mpRowsSpinBox->setEnabled(!mRowsFixed);
  mpColumnsSpinBox->setEnabled(!mColumnsFixed && !mVector);
  connect(mpRowsSpinBox, SIGNAL(valueChanged(int)), SLOT(rowsChanged(int)));
  connect(mpColumnsSpinBox, SIGNAL(valueChanged(int)), SLOT(columnsChanged(int)));
  connect(mpArrayTableWidget, SIGNAL(itemChanged(QTableWidgetItem*)), SLOT(updateExpressionFromTable()));
  mpArrayTableWidget->setSelectionMode(QAbstractItemView::ExtendedSelection);
  mpArrayTableWidget->setContextMenuPolicy(Qt::CustomContextMenu);
  connect(mpArrayTableWidget, &QTableWidget::customContextMenuRequested,
          this, &ArrayParameterEditorDialog::showTableContextMenu);
  Label *pExpressionLabel = new Label(tr("Expression:"));
  mpExpressionLineEdit = new QLineEdit;
  mpExpressionLineEdit->setPlaceholderText(defaultValue);
  connect(mpExpressionLineEdit, SIGNAL(textEdited(const QString &)), SLOT(expressionTextEdited(const QString &)));
  QDialogButtonBox *pButtonBox = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel);
  connect(pButtonBox, SIGNAL(accepted()), SLOT(okClicked()));
  connect(pButtonBox, SIGNAL(rejected()), SLOT(reject()));
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->addWidget(pRowsLabel, 0, 0);
  pMainLayout->addWidget(mpRowsSpinBox, 0, 1);
  pMainLayout->addWidget(pColumnsLabel, 0, 2);
  pMainLayout->addWidget(mpColumnsSpinBox, 0, 3);
  pMainLayout->addWidget(mpArrayTableWidget, 1, 0, 1, 4);
  pMainLayout->addWidget(pExpressionLabel, 2, 0);
  pMainLayout->addWidget(mpExpressionLineEdit, 2, 1, 1, 3);
  pMainLayout->addWidget(pButtonBox, 3, 0, 1, 4);
  setLayout(pMainLayout);
  setArrayCells(QList<QStringList>(), mVector ? 1 : 0);
  mOriginalArrayValue = arrayValue;
  loadArrayValue(arrayValue);
  // show the passed value as text so it is clearly visible; clearing the
  // expression reverts to the placeholder (default value).
  mpExpressionLineEdit->setText(arrayValue);
  mInitializing = false;
}

/*!
 * \brief ArrayParameterEditorDialog::setArrayCells
 * Resizes the editor for the given rows and fills the cells with their text.
 */
void ArrayParameterEditorDialog::setArrayCells(const QList<QStringList> &rows, int columns)
{
  int columnCount = columns;
  for (int i = 0; i < rows.size(); ++i) {
    columnCount = qMax(columnCount, rows.at(i).size());
  }
  const int rowCount = mRowsFixed ? mFixedRows : rows.size();
  if (mColumnsFixed) {
    columnCount = mFixedColumns;
  }
  mpRowsSpinBox->setRange(0, qMax(mpRowsSpinBox->maximum(), rowCount));
  mpColumnsSpinBox->setRange(0, qMax(mpColumnsSpinBox->maximum(), columnCount));
  mpRowsSpinBox->blockSignals(true);
  mpColumnsSpinBox->blockSignals(true);
  mpRowsSpinBox->setValue(rowCount);
  mpColumnsSpinBox->setValue(columnCount);
  mpRowsSpinBox->blockSignals(false);
  mpColumnsSpinBox->blockSignals(false);
  const bool tableSignalsBlocked = mpArrayTableWidget->blockSignals(true);
  mpArrayTableWidget->setRowCount(rowCount);
  mpArrayTableWidget->setColumnCount(columnCount);
  // fill every cell; empty cells get their default value so the table looks complete
  // when rows/columns are added.
  for (int i = 0; i < rowCount; ++i) {
    for (int j = 0; j < columnCount; ++j) {
      QString cell;
      if (i < rows.size() && j < rows.at(i).size()) {
        cell = rows.at(i).at(j).trimmed();
      }
      if (cell.isEmpty()) {
        cell = getCellText(i, j);
      }
      mpArrayTableWidget->setItem(i, j, new QTableWidgetItem(cell));
    }
  }
  mpArrayTableWidget->blockSignals(tableSignalsBlocked);
}

void ArrayParameterEditorDialog::fillEmptyCells()
{
  for (int i = 0; i < mpArrayTableWidget->rowCount(); ++i) {
    for (int j = 0; j < mpArrayTableWidget->columnCount(); ++j) {
      if (!mpArrayTableWidget->item(i, j)) {
        mpArrayTableWidget->setItem(i, j, new QTableWidgetItem(getCellText(i, j)));
      }
    }
  }
}

/*!
 * \brief ArrayParameterEditorDialog::showTableContextMenu
 * Offers deletion when the selection covers complete rows or columns.
 * Fixed dimensions cannot be deleted.
 * \param position position of the context-menu request in the table viewport
 */
void ArrayParameterEditorDialog::showTableContextMenu(const QPoint &position)
{
  QSet<int> selectedRows;
  QSet<int> selectedColumns;
  for (const QTableWidgetSelectionRange &range : mpArrayTableWidget->selectedRanges()) {
    if (range.leftColumn() == 0 && range.rightColumn() == mpArrayTableWidget->columnCount() - 1) {
      for (int row = range.topRow(); row <= range.bottomRow(); ++row) {
        selectedRows.insert(row);
      }
    }
    if (range.topRow() == 0 && range.bottomRow() == mpArrayTableWidget->rowCount() - 1) {
      for (int column = range.leftColumn(); column <= range.rightColumn(); ++column) {
        selectedColumns.insert(column);
      }
    }
  }

  QMenu menu(this);
  if (!mRowsFixed && !selectedRows.isEmpty()) {
    QAction *pDeleteRowsAction = menu.addAction(tr("Delete %n row(s)", nullptr, selectedRows.size()));
    connect(pDeleteRowsAction, &QAction::triggered, this, &ArrayParameterEditorDialog::deleteSelectedRows);
  } else if (!mColumnsFixed && !selectedColumns.isEmpty()) {
    QAction *pDeleteColumnsAction = menu.addAction(tr("Delete %n column(s)", nullptr, selectedColumns.size()));
    connect(pDeleteColumnsAction, &QAction::triggered, this, &ArrayParameterEditorDialog::deleteSelectedColumns);
  }
  if (!menu.isEmpty()) {
    menu.exec(mpArrayTableWidget->viewport()->mapToGlobal(position));
  }
}

/*!
 * \brief ArrayParameterEditorDialog::deleteSelectedRows
 * Removes selected complete rows and synchronizes the Rows spin box.
 */
void ArrayParameterEditorDialog::deleteSelectedRows()
{
  if (mRowsFixed) {
    return;
  }
  QSet<int> selectedRows;
  for (const QTableWidgetSelectionRange &range : mpArrayTableWidget->selectedRanges()) {
    if (range.leftColumn() == 0 && range.rightColumn() == mpArrayTableWidget->columnCount() - 1) {
      for (int row = range.topRow(); row <= range.bottomRow(); ++row) {
        selectedRows.insert(row);
      }
    }
  }
  QList<int> rows = selectedRows.values();
  // Remove from bottom to top so earlier row indices remain valid.
  std::sort(rows.begin(), rows.end(), [](int left, int right) {return left > right;});
  for (int row : rows) {
    mpArrayTableWidget->removeRow(row);
  }
  if (!rows.isEmpty()) {
    mpRowsSpinBox->setValue(mpArrayTableWidget->rowCount());
  }
}

/*!
 * \brief ArrayParameterEditorDialog::deleteSelectedColumns
 * Removes selected complete columns and synchronizes the Columns spin box.
 */
void ArrayParameterEditorDialog::deleteSelectedColumns()
{
  if (mColumnsFixed) {
    return;
  }
  QSet<int> selectedColumns;
  for (const QTableWidgetSelectionRange &range : mpArrayTableWidget->selectedRanges()) {
    if (range.topRow() == 0 && range.bottomRow() == mpArrayTableWidget->rowCount() - 1) {
      for (int column = range.leftColumn(); column <= range.rightColumn(); ++column) {
        selectedColumns.insert(column);
      }
    }
  }
  QList<int> columns = selectedColumns.values();
  // Remove from right to left so earlier column indices remain valid.
  std::sort(columns.begin(), columns.end(), [](int left, int right) {return left > right;});
  for (int column : columns) {
    mpArrayTableWidget->removeColumn(column);
  }
  if (!columns.isEmpty()) {
    mpColumnsSpinBox->setValue(mpArrayTableWidget->columnCount());
  }
}

/*!
 * \brief ArrayParameterEditorDialog::loadArrayValue
 * Loads \a arrayValue into the editor. When \a arrayValue is empty the
 * placeholder (default value) is used instead. Returns true when the value
 * can be parsed into table cells.
 * \return true if the value is a supported array expression.
 */
bool ArrayParameterEditorDialog::loadArrayValue(const QString &arrayValue)
{
  // an empty value falls back to the placeholder (default value) so that
  // clearing the expression still loads a table with default cell values.
  QString value = arrayValue;
  if (value.isEmpty()) {
    value = mpExpressionLineEdit->placeholderText();
  }
  return parseArrayValue(value);
}

/*!
 * \brief ArrayParameterEditorDialog::updateExpressionFromTable
 * Keeps the expression field in sync with the table view contents.
 */
void ArrayParameterEditorDialog::updateExpressionFromTable()
{
  if (!mInitializing) {
    mExpressionTextModified = true;
  }
  mpExpressionLineEdit->blockSignals(true);
  mpExpressionLineEdit->setText(createArrayValue());
  mpExpressionLineEdit->blockSignals(false);
}

/*!
 * \brief ArrayParameterEditorDialog::expressionTextEdited
 * Slot activated when the user edits the expression field.
 * Fills the table view when the expression is supported. Otherwise the current
 * table contents remain available for editing.
 */
void ArrayParameterEditorDialog::expressionTextEdited(const QString &text)
{
  mExpressionTextModified = true;
  const QString value = text.trimmed();
  const bool isLiteralArray = value.startsWith('{') || value.startsWith('[');
  const bool parsed = loadArrayValue(value);
  if (parsed && isLiteralArray) {
    mpExpressionLineEdit->blockSignals(true);
    mpExpressionLineEdit->setText(createArrayValue());
    mpExpressionLineEdit->blockSignals(false);
  }
}

/*!
 * \brief ArrayParameterEditorDialog::parseArrayValue
 * Parses a Modelica array expression using the FlatModelica expression parser.
 * Supported are array literals with curly braces e.g. {1, 2, 3}, {{1, 2}, {3, 4}}
 * or square brackets e.g. [1, 2], [1, 2; 3, 4]. Arrays with more than 2 dimensions are flattened into a 2D
 * table where each cell holds a nested array literal.
 * An empty value is valid: the table stays enabled and the user can edit it.
 * \return true if the value is a supported array expression.
 */
bool ArrayParameterEditorDialog::parseArrayValue(const QString &arrayValue)
{
  const QString value = arrayValue.trimmed();
  QList<QStringList> rows;

  // an empty value is not invalid: the table stays enabled and the user can edit it.
  if (value.isEmpty()) {
    setArrayCells(rows);
    return true;
  }

  FlatModelica::Expression exp;
  try {
    exp = FlatModelica::Expression::parse(value);
  } catch (const std::exception &) {
    return false;
  }
  if (exp.isNull()) {
    return false;
  }

  if (exp.isArray()) {
    // array literal: {1, 2, 3} / {{1, 2}, {3, 4}} / [1, 2] / [1, 2; 3, 4]
    const size_t ndims = exp.ndims();
    if (ndims == 1) {
      // vectors are displayed vertically, with one value in each row.
      const auto &elements = exp.elements();
      rows.reserve(elements.size());
      for (const auto &element : elements) {
        rows.append(QStringList() << element.toQString());
      }
    } else {
      // matrix or higher dimensional: rows = size(0), cols = size(1);
      // cells of higher dimensional arrays hold nested array literals
      const size_t numRows = exp.size(0);
      const size_t numCols = exp.size(1);
      for (size_t i = 0; i < numRows; ++i) {
        QStringList cells;
        const auto &rowExp = exp.elements()[i];
        cells.reserve(numCols);
        for (size_t j = 0; j < numCols; ++j) {
          const auto &cellExp = rowExp.elements()[j];
          cells.append(cellExp.toQString());
        }
        rows.append(cells);
      }
    }
    int columnCount = 0;
    for (const QStringList &row : rows) {
      columnCount = qMax(columnCount, row.size());
    }
    if ((mRowsFixed && rows.size() != mFixedRows) || (mColumnsFixed && columnCount != mFixedColumns)) {
      return false;
    }
    setArrayCells(rows);
    return true;
  }

  // Expressions other than array literals cannot be loaded into table cells.
  return false;
}

/*!
 * \brief ArrayParameterEditorDialog::rowsChanged
 * Slot activated when mpRowsSpinBox valueChanged(int) SIGNAL is raised.
 * Updates the number of rows in the editor.
 */
void ArrayParameterEditorDialog::rowsChanged(int rows)
{
  if (!mInitializing) {
    mExpressionTextModified = true;
  }
  mpArrayTableWidget->setRowCount(rows);
  fillEmptyCells();
  updateExpressionFromTable();
}

/*!
 * \brief ArrayParameterEditorDialog::columnsChanged
 * Slot activated when mpColumnsSpinBox valueChanged(int) SIGNAL is raised.
 * Updates the number of columns in the editor.
 */
void ArrayParameterEditorDialog::columnsChanged(int columns)
{
  if (!mInitializing) {
    mExpressionTextModified = true;
  }
  mpArrayTableWidget->setColumnCount(columns);
  fillEmptyCells();
  updateExpressionFromTable();
}

/*!
 * \brief ArrayParameterEditorDialog::okClicked
 * Slot activated when QDialogButtonBox accepted SIGNAL is raised.
 * Creates the array value for the edited table and closes the dialog.
 */
void ArrayParameterEditorDialog::okClicked()
{
  if (mExpressionTextModified) {
    const QString text = mpExpressionLineEdit->text().trimmed();
    if (text.isEmpty()) {
      // clearing the expression reverts to the default value (placeholder)
      mArrayValue = mpExpressionLineEdit->placeholderText();
    } else {
      mArrayValue = text;
    }
  } else {
    mArrayValue = mOriginalArrayValue;
  }
  accept();
}

/*!
 * \brief ArrayParameterEditorDialog::createArrayValue
 * Creates the Modelica array literal for the edited table using curly braces.
 * Vectors are serialized as a single-dimensional array and empty tables return an empty value.
 */
QString ArrayParameterEditorDialog::createArrayValue() const
{
  const int rowCount = mpRowsSpinBox->value();
  const int columnCount = mpColumnsSpinBox->value();
  if (rowCount == 0 || columnCount == 0) {
    return "";
  }
  if (mVector) {
    QStringList cellStrings;
    for (int i = 0; i < rowCount; ++i) {
      cellStrings.append(getCellText(i, 0));
    }
    return "{" % cellStrings.join(",") % "}";
  }
  QStringList rowStrings;
  for (int i = 0; i < rowCount; ++i) {
    QStringList cellStrings;
    for (int j = 0; j < columnCount; ++j) {
      cellStrings.append(getCellText(i, j));
    }
    rowStrings.append("{" % cellStrings.join(",") % "}");
  }
  return "{" % rowStrings.join(",") % "}";
}

QString ArrayParameterEditorDialog::createDefaultCellValue(int dimensionIndex) const
{
  if (dimensionIndex == mCellDimensions.size()) {
    return mArrayDimensions > 3 ? QStringLiteral("0.0") : QStringLiteral("0");
  }
  const int dimension = mCellDimensions.at(dimensionIndex).toInt();
  QStringList elements;
  elements.reserve(dimension);
  for (int i = 0; i < dimension; ++i) {
    elements.append(createDefaultCellValue(dimensionIndex + 1));
  }
  return "{" % elements.join(",") % "}";
}

/*!
 * \brief ArrayParameterEditorDialog::getCellText
 * Returns the text of the given cell or an appropriately shaped default value.
 */
QString ArrayParameterEditorDialog::getCellText(int row, int column) const
{
  const QTableWidgetItem *pItem = mpArrayTableWidget->item(row, column);
  const QString text = pItem ? pItem->text().trimmed() : "";
  if (text.isEmpty()) {
    if (mArrayDimensions > 2 && mCellDimensions.size() == mArrayDimensions - 2) {
      return createDefaultCellValue(0);
    }
    if (mArrayDimensions > 2) {
      // Infer unknown trailing dimensions from another populated cell.
      const QString defaultValue = QStringLiteral("0");
      int cellSize = 0;
      for (int k = 0; k < mpArrayTableWidget->columnCount(); ++k) {
        const QTableWidgetItem *pExisting = mpArrayTableWidget->item(row, k);
        if (pExisting && !pExisting->text().trimmed().isEmpty()) {
          cellSize = countTopLevelElements(pExisting->text().trimmed());
          break;
        }
      }
      if (cellSize == 0) {
        for (int k = 0; k < mpArrayTableWidget->rowCount(); ++k) {
          if (k == row) {
            continue;
          }
          const QTableWidgetItem *pExisting = mpArrayTableWidget->item(k, column);
          if (pExisting && !pExisting->text().trimmed().isEmpty()) {
            cellSize = countTopLevelElements(pExisting->text().trimmed());
            break;
          }
        }
      }
      if (cellSize == 0) {
        for (int i = 0; i < mpArrayTableWidget->rowCount() && cellSize == 0; ++i) {
          for (int k = 0; k < mpArrayTableWidget->columnCount(); ++k) {
            const QTableWidgetItem *pExisting = mpArrayTableWidget->item(i, k);
            if (pExisting && !pExisting->text().trimmed().isEmpty()) {
              cellSize = countTopLevelElements(pExisting->text().trimmed());
              break;
            }
          }
        }
      }
      if (cellSize == 0) {
        cellSize = 1;
      }
      QStringList cellStrings;
      for (int k = 0; k < cellSize; ++k) {
        cellStrings.append(defaultValue);
      }
      return "{" % cellStrings.join(",") % "}";
    }
    return QStringLiteral("0");
  }
  return text;
}

/*!
 * \brief ArrayParameterEditorDialog::countTopLevelElements
 * Counts the top-level comma-separated elements inside a braced cell literal
 * e.g. "{1, 2}" -> 2, "{0}" -> 1, "{1, {2, 3}}" -> 2.
 */
int ArrayParameterEditorDialog::countTopLevelElements(const QString &cellText)
{
  QString inner = cellText.trimmed();
  if ((inner.startsWith('{') && inner.endsWith('}')) ||
      (inner.startsWith('[') && inner.endsWith(']'))) {
    inner = inner.mid(1).chopped(1);
  }
  if (inner.trimmed().isEmpty()) {
    return 0;
  }
  int count = 1;
  int depth = 0;
  for (const QChar &ch : inner) {
    if (ch == QLatin1Char('{') || ch == QLatin1Char('[')) {
      ++depth;
    } else if (ch == QLatin1Char('}') || ch == QLatin1Char(']')) {
      --depth;
    } else if (ch == QLatin1Char(',') && depth == 0) {
      ++count;
    }
  }
  return count;
}

Parameter::Parameter(ModelInstance::Element *pElement, bool defaultValue, ElementParameters *pElementParameters)
{
  mpModelInstanceElement = pElement;
  mExtendName = mpModelInstanceElement->getTopLevelParentElementName();
  mInherited = defaultValue;
  mpElementParameters = pElementParameters;
  auto &dialogAnnotation = mpModelInstanceElement->getAnnotation()->getDialogAnnotation();
  mTab = dialogAnnotation.getTab();
  mTabDefined = dialogAnnotation.isTabDefined();
  mGroup = dialogAnnotation.getGroup();
  mGroupDefined = !mGroup.isEmpty();
  mEnable = dialogAnnotation.isEnabled();
  mShowStartAttribute = dialogAnnotation.getShowStartAttribute();
  mShowStartAndFixed = mShowStartAttribute;
  mColorSelector = dialogAnnotation.isColorSelector();
  auto &loadSelector = dialogAnnotation.getLoadSelector();
  mLoadSelectorFilter = loadSelector.getFilter();
  mLoadSelectorCaption = loadSelector.getCaption();
  auto &saveSelector = dialogAnnotation.getSaveSelector();
  mSaveSelectorFilter = saveSelector.getFilter();
  mSaveSelectorCaption = saveSelector.getCaption();
  mGroupImage = dialogAnnotation.getGroupImage();
  mHasGroupImage = dialogAnnotation.hasGroupImage();
  if (mHasGroupImage && !mGroupImage.isEmpty()) {
    mGroupImage = MainWindow::instance()->getOMCProxy()->uriToFilename(mGroupImage);
  }
  mConnectorSizing = dialogAnnotation.isConnectorSizing();

  // If mShowStartAttribute is not set then check for start modifier
  if (!mShowStartAndFixed && !dialogAnnotation.hasShowStartAttribute()
      && !mpModelInstanceElement->isParameter() && !mpModelInstanceElement->isInput() && mpModelInstanceElement->getModifier()) {
    mShowStartAndFixed = mpModelInstanceElement->getModifier()->hasModifier("start");
  }
  /* if mShowStartAndFixed and group name is empty then set group name to Initialization.
   * else set group name to Parameters for actual parameters or elements that have dialog annotation or replaceable elements.
   * other elements show in modifiers.
   */
  if (mShowStartAndFixed && mGroup.isEmpty()) {
    mGroup = Initialization;
  } else if (mGroup.isEmpty() && !mShowStartAndFixed && (mpModelInstanceElement->isParameter() || mpModelInstanceElement->getAnnotation()->hasDialogAnnotation()
                                  || mpModelInstanceElement->getReplaceable())) {
    mGroup = Parameters;
  }

  mpNameLabel = new Label;
  mpFixedCheckBox = new FixedCheckBox;
  connect(mpFixedCheckBox, SIGNAL(clicked()), SLOT(showFixedMenu()));
  setFixedState("", true);
  mpFixedFinalEachMenuButton = new FinalEachToolButton((mpElementParameters->hasElement() && mpElementParameters->isElementArray())
                                                       || mpModelInstanceElement->getDimensions().isArray());
  // set the value type based on element type.
  bool isChoicesType = mpModelInstanceElement->getAnnotation()->getChoices() && !mpModelInstanceElement->getAnnotation()->getChoices()->getChoices().isEmpty();
  if (mpModelInstanceElement->getRootType().compare(QStringLiteral("Boolean")) == 0) {
    if (mpModelInstanceElement->getAnnotation()->getChoices()
        && (mpModelInstanceElement->getAnnotation()->getChoices()->isCheckBox() || mpModelInstanceElement->getAnnotation()-> getChoices()->isDymolaCheckBox())) {
      mValueType = Parameter::CheckBox;
    } else {
      mValueType = Parameter::Boolean;
    }
  }
  // Choices take precedence over enumeration so annotated enumeration parameters use their choices (see issue #16620).
  else if (!isChoicesType && mpModelInstanceElement->getModel() && mpModelInstanceElement->getModel()->isEnumeration()) {
    mValueType = Parameter::Enumeration;
  } else if (mpModelInstanceElement->getReplaceable()) {
    // replaceable component or short element definition
    if (mpModelInstanceElement->isShortClassDefinition()) {
      mValueType = Parameter::ReplaceableClass;
    } else {
      mValueType = Parameter::ReplaceableComponent;
    }
  } else if (isChoicesType) {
    mValueType = Parameter::Choices;
  } else if (mpModelInstanceElement->getAnnotation()->isChoicesAllMatching()) {
    mValueType = Parameter::ChoicesAllMatching;
  } else {
    mValueType = Parameter::Normal;
  }

  /* edit class button
   * if the element is replaceable and has model or is short class definition
   * OR if the element has model and that model is record
   * See issue #10700
   */
  if ((mpModelInstanceElement->getReplaceable() && (mpModelInstanceElement->getModel() || mpModelInstanceElement->isShortClassDefinition()))
      || (mpModelInstanceElement->getModel() && mpModelInstanceElement->getModel()->isRecord())) {
    createEditClassButton();
  }

  // final and each menu
  mpFinalEachMenuButton = new FinalEachToolButton((mpElementParameters->hasElement() && mpElementParameters->isElementArray())
                                                  || mpModelInstanceElement->getDimensions().isArray());
  connect(mpFinalEachMenuButton, SIGNAL(breakToggled(bool)), SLOT(setBreakValue(bool)));
  mValueCheckBoxModified = false;
  mDefaultValue = "";
  mpFileSelectorButton = new QToolButton;
  mpFileSelectorButton->setText("...");
  mpFileSelectorButton->setToolButtonStyle(Qt::ToolButtonTextOnly);
  connect(mpFileSelectorButton, SIGNAL(clicked()), SLOT(fileSelectorButtonClicked()));
  createValueWidget();
  // Get unit value
  QPair<QString, bool> unit = mpModelInstanceElement->getModifierValueFromType(QStringList() << "unit");
  mUnit = unit.first;
  // Get displayUnit value
  QPair<QString, bool> displayUnit = mpModelInstanceElement->getModifierValueFromType(QStringList() << "displayUnit");
  if (displayUnit.first.isEmpty()) {
    displayUnit.first = mUnit;
  }
  mDisplayUnit = displayUnit.first;
  mPreviousUnit = mDisplayUnit;
  QStringList units;
  if (!mUnit.isEmpty()) {
    units << mUnit;
    if (mDisplayUnit.compare(mUnit) != 0) {
      units << mDisplayUnit;
    }
    Utilities::addDefaultDisplayUnit(mUnit, units);
  }
  mpUnitComboBox = new ComboBox;
  foreach (QString unit, units) {
    mpUnitComboBox->addItem(OMPlot::Plot::convertUnitToSymbol(unit), unit);
  }
  if (mDisplayUnit.compare(mUnit) != 0) {
    mpUnitComboBox->setCurrentIndex(1);
  }
  connect(mpUnitComboBox, SIGNAL(currentIndexChanged(int)), SLOT(unitComboBoxChanged(int)));
  /* Issue #11715.
   * Do not add each menu item to displayUnit modifiers.
   * We will automatically add the each prefix for arrays.
   */
  mpDisplayUnitFinalEachMenuButton = new FinalEachToolButton(false);
  // comment
  const QString comment = mpModelInstanceElement->getComment();
  mpCommentLabel = new Label(comment.simplified());
  mpCommentLabel->setToolTip(comment); // set tooltip with original comment string that might have newline characters and extra spaces.
  /* Set size policy to expanding and word wrap to true so that the comment label can take up multiple lines if the comment is long
   * and also take up the remaining space in the layout.
   * See issue #15596.
   */
  mpCommentLabel->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
  mpCommentLabel->setWordWrap(true);
  // create a dummy label to calculate the minimum width for comment label based on the comment text
  QLabel dummyLabel(comment.simplified());
  mpCommentLabel->setMinimumWidth(qMin(DefaultMinimumWidthForComment, dummyLabel.sizeHint().width()));
  // if comment is empty then hide the comment label so that it doesn't take up space in the layout.
  if (comment.isEmpty()) {
    mpCommentLabel->hide();
  }

  if (isReplaceableClass()) {
    auto pReplaceableClass = dynamic_cast<ModelInstance::ReplaceableClass*>(mpModelInstanceElement);
    setValueWidget(pReplaceableClass->getBaseClass(), true, mUnit);
  } else if (isReplaceableComponent()) {
    QString value;
    if (mpModelInstanceElement->getModifier()) {
      if (mpModelInstanceElement->getModifier()->isValueDefined()) {
        value = mpModelInstanceElement->getModifier()->getValue();
      } else {
        value = "redeclare " % mpModelInstanceElement->getType() % " " % mpModelInstanceElement->getName();
        QString modifier = mpModelInstanceElement->getModifier()->toString(true);
        if (!modifier.isEmpty()) {
          if (modifier.startsWith("(")) {
            value = value % modifier;
          } else {
            value = value % "(" % modifier % ")";
          }
        }
      }
    }
    setValueWidget(value, defaultValue, mUnit);
  } else {
    mpElementParameters->applyFinalStartFixedAndDisplayUnitModifiers(this, mpModelInstanceElement->getModifier(), defaultValue, false);
  }
  update();
}

/*!
 * \brief Parameter::updateNameLabel
 * Updates the name label.
 */
void Parameter::updateNameLabel()
{
  mName = mpModelInstanceElement->getName();
  QString name = mName;
  if (mpModelInstanceElement->getDimensions().isArray()) {
    name.append("[" % mpModelInstanceElement->getDimensions().getTypedDimensionsString() % "]");
  }
  if (mShowStartAndFixed) {
    name.append(".start");
  }
  mpNameLabel->setText(name);
}

/*!
 * \brief Parameter::setValueWidget
 * Sets the value and defaultValue for the parameter.
 * \param value
 * \param defaultValue
 * \param fromUnit
 * \param valueModified
 * \param unitComboBoxChanged
 */
void Parameter::setValueWidget(QString value, bool defaultValue, QString fromUnit, bool valueModified, bool unitComboBoxChanged)
{
  /* ticket:5618 if we don't have a literal constant and array of constants
   * then we assume its an expression and don't do any conversions.
   * So just show the unit in the unit drop down list
   */
  if (!unitComboBoxChanged && !defaultValue) {
    enableDisableUnitComboBox(value);
  }

  QStringList valueParts = Utilities::extractArrayParts(value);
  // convert the value to display unit
  if (!fromUnit.isEmpty() && mpUnitComboBox->itemData(mpUnitComboBox->currentIndex()).toString().compare(fromUnit) != 0) {
    if (valueParts.size() == 1) {
      bool ok = true;
      qreal realValue = valueParts.at(0).toDouble(&ok);
      // if the modifier is a literal constant
      if (ok) {
        OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
        OMCInterface::convertUnits_res convertUnit = pOMCProxy->convertUnits(fromUnit, mpUnitComboBox->itemData(mpUnitComboBox->currentIndex()).toString());
        if (convertUnit.unitsCompatible) {
          realValue = Utilities::convertUnit(realValue, convertUnit.offset, convertUnit.scaleFactor);
          value = StringHandler::number(realValue);
        }
      }
    } else { // if array expression
      value = Utilities::arrayExpressionUnitConversion(MainWindow::instance()->getOMCProxy(), value, fromUnit, mpUnitComboBox->itemData(mpUnitComboBox->currentIndex()).toString());
    }
  }

  if (defaultValue) {
    mDefaultValue = value;
    /* Issue #11847
     * Show the default values as arrays, either as {0, 0, 0} or fill(0, 3).
     * Use first version if the number of dimensions is small (say, <= 4, which works for 3-phase, 3D mechanics and quaternions).
     * Use the second version for larger arrays, to avoid overbloating it.
     */
    if (Utilities::isValueScalarLiteralConstant(value) && ((mpElementParameters->hasElement() && mpElementParameters->isElementArray())
                                                           || mpModelInstanceElement->getDimensions().isArray())) {
      bool ok;
      int dims = mpElementParameters->getElementDimensions().toInt(&ok);
      if (ok) {
        if (dims <= 4) {
          QStringList valueList;
          for (int i = 0; i < dims; ++i) {
            valueList.append(value);
          }
          value = "{" % valueList.join(",") % "}";
        } else {
          value = "fill(" % value % ", " % mpElementParameters->getElementDimensions() % ")";
        }
      }
    }
  }
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
    case Parameter::ReplaceableClass:
    case Parameter::ReplaceableComponent:
    case Parameter::Choices:
    case Parameter::ChoicesAllMatching:
      {
        int index = mpValueComboBox->findData(value);
        if (defaultValue) {
          mpValueComboBox->lineEdit()->setPlaceholderText(value);
        } else {
          // update the value combobox index when setting the value on the line edit
          bool state = mpValueComboBox->blockSignals(true);
          /* Issue #12756
           * Reset the value combobox selection for choices.
           * Since we always want to update the unit combobox when value selection changes for choices.
           * Also don't add the new value to the combobox.
           */
          if (isChoices()) {
            mpValueComboBox->setCurrentIndex(-1);
          } else {
            if (index > -1) {
              mpValueComboBox->setCurrentIndex(index);
            } else { // if we fail to find the value in the combobox then add it to the combobox
              mpValueComboBox->insertItem(1, value, value);
              mpValueComboBox->setItemData(1, value, Qt::ToolTipRole);
              index = 1;
            }
          }
          mpValueComboBox->lineEdit()->setText(value);
          mpValueComboBox->lineEdit()->setModified(valueModified);
          mpValueComboBox->blockSignals(state);
        }
        mpValueComboBox->setToolTip(mpValueComboBox->itemData(index, Qt::ToolTipRole).toString());
      }
      break;
    case Parameter::CheckBox:
      {
        bool signalsState = mpValueCheckBox->blockSignals(true);
        mpValueCheckBox->setChecked(value.compare("true") == 0);
        mpValueCheckBox->blockSignals(signalsState);
        mValueCheckBoxModified = valueModified && !defaultValue;
      }
      break;
    case Parameter::Normal:
    default:
      if (defaultValue) {
        mpValueTextBox->setPlaceholderText(value);
      } else {
        mpValueTextBox->setText(value);
        mpValueTextBox->setModified(valueModified);
      }
      mpValueTextBox->setCursorPosition(0); /* move the cursor to start so that parameter value will show up from start instead of end. */
      break;
  }
}

QWidget* Parameter::getValueWidget()
{
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
    case Parameter::ReplaceableClass:
    case Parameter::ReplaceableComponent:
    case Parameter::Choices:
    case Parameter::ChoicesAllMatching:
      return mpValueComboBox;
    case Parameter::CheckBox:
      return mpValueCheckBox;
    case Parameter::Normal:
    default:
      return mpValueTextBox;
  }
}

/*!
 * \brief Parameter::isValueModified
 * Returns true if value widget is changed.
 * \return
 */
bool Parameter::isValueModified()
{
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
    case Parameter::ReplaceableClass:
    case Parameter::ReplaceableComponent:
    case Parameter::Choices:
    case Parameter::ChoicesAllMatching:
      return mpValueComboBox->lineEdit()->isModified() || isValueModifiedHelper();
    case Parameter::CheckBox:
      return mValueCheckBoxModified || isValueModifiedHelper();
    case Parameter::Normal:
    default:
      return mpValueTextBox->isModified() || isValueModifiedHelper();
  }
}

/*!
 * \brief Parameter::getValue
 * Returns the value.
 * \return
 */
QString Parameter::getValue()
{
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
    case Parameter::ReplaceableClass:
    case Parameter::ReplaceableComponent:
    case Parameter::Choices:
    case Parameter::ChoicesAllMatching:
      return mpValueComboBox->lineEdit()->text().trimmed();
    case Parameter::CheckBox:
      return mpValueCheckBox->isChecked() ? "true" : "false";
    case Parameter::Normal:
    default:
      return mpValueTextBox->text().trimmed();
  }
}

/*!
 * \brief Parameter::hideValueWidget
 * Hides the value widget.
 */
void Parameter::hideValueWidget()
{
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
    case Parameter::ReplaceableClass:
    case Parameter::ReplaceableComponent:
    case Parameter::Choices:
    case Parameter::ChoicesAllMatching:
      mpValueComboBox->setVisible(false);
      break;
    case Parameter::CheckBox:
      mpValueCheckBox->setVisible(false);
      break;
    case Parameter::Normal:
    default:
      mpValueTextBox->setVisible(false);
      break;
  }
}

void Parameter::setFixedState(QString fixed, bool defaultValue)
{
  mOriginalFixedValue = defaultValue ? "" : fixed;
  if (fixed.compare(QStringLiteral("true")) == 0) {
    mpFixedCheckBox->setTickState(defaultValue, true);
  } else {
    mpFixedCheckBox->setTickState(defaultValue, false);
  }
}

QString Parameter::getFixedState() const
{
  return mpFixedCheckBox->getTickStateString();
}

/*!
  Sets the input field of the parameter enable/disable.
  \param enable
  */
void Parameter::setEnabled(bool enable)
{
  // enable/disable fixed checkbox
  mpFixedCheckBox->setEnabled(enable);
  // enable/disable fixed final each menu button
  mpFixedFinalEachMenuButton->setEnabled(enable);
  // enable/disable value widget
  switch (mValueType) {
    case Parameter::Boolean:
    case Parameter::Enumeration:
    case Parameter::ReplaceableComponent:
    case Parameter::ReplaceableClass:
    case Parameter::Choices:
    case Parameter::ChoicesAllMatching:
      mpValueComboBox->setEnabled(enable);
      break;
    case Parameter::CheckBox:
      mpValueCheckBox->setEnabled(enable);
      break;
    case Parameter::Normal:
    default:
      mpValueTextBox->setEnabled(enable);
      break;
  }
  // enable/disable final each menu button
  mpFinalEachMenuButton->setEnabled(enable);
  // enable/disable unit combobox
  mpUnitComboBox->setEnabled(enable);
  // if enable is true then enable/disable the unit combobox based on value
  if (enable) {
    enableDisableUnitComboBox(getValue());
  }
  // enable/disable edit class button
  if (mpEditClassButton) {
    mpEditClassButton->setEnabled(enable);
  }
  // enable/disable displayunit final each menu button
  mpDisplayUnitFinalEachMenuButton->setEnabled(enable);
}

/*!
 * \brief Parameter::update
 * Enable/disable the parameter.
 */
void Parameter::update()
{
  mEnable.evaluate(mpElementParameters->getGraphicsView()->getModelWidget()->getModelInstance());
  setEnabled(mEnable);
}

/*!
 * \brief Parameter::createEditClassButton
 * Creates the edit class button.
 */
void Parameter::createEditClassButton()
{
  mpEditClassButton = new QToolButton;
  mpEditClassButton->setIcon(QIcon(":/Resources/icons/edit-icon.svg"));
  mpEditClassButton->setToolTip(tr("Edit"));
  mpEditClassButton->setAutoRaise(true);
  connect(mpEditClassButton, SIGNAL(clicked()), SLOT(editClassButtonClicked()));
}

void Parameter::createValueWidget()
{
  int i;
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QString className = mpModelInstanceElement->getType();
  QString constrainedByClassName;
  QString parentClassName = "", restriction = "", elementName = "";
  QStringList enumerationLiterals, enumerationLiteralsTooltip, displayChoices, valueChoices, commentChoices;
  QList<QList<QString>> replaceableChoices;

  switch (mValueType) {
    case Parameter::Boolean:
      createValueComboBox();
      mpValueComboBox->addItemWithToolTip("true", "true", "true");
      mpValueComboBox->addItemWithToolTip("false", "false", "false");
      connect(mpValueComboBox, SIGNAL(currentIndexChanged(int)), SLOT(valueComboBoxChanged(int)));
      break;

    case Parameter::Enumeration:
      createValueComboBox();
      foreach (auto pModelInstanceElement, mpModelInstanceElement->getModel()->getElements()) {
        if (pModelInstanceElement->isComponent()) {
          auto pModelInstanceComponent = dynamic_cast<ModelInstance::Component*>(pModelInstanceElement);
          enumerationLiterals.append(pModelInstanceComponent->getName());
          enumerationLiteralsTooltip.append(pModelInstanceComponent->getName() % " \"" % pModelInstanceComponent->getComment() % "\"");
        }
      }
      for (i = 0 ; i < enumerationLiterals.size(); i++) {
        mpValueComboBox->addItemWithToolTip(enumerationLiterals[i], className + "." + enumerationLiterals[i], enumerationLiteralsTooltip[i]);
      }
      connect(mpValueComboBox, SIGNAL(currentIndexChanged(int)), SLOT(valueComboBoxChanged(int)));
      break;

    case Parameter::CheckBox:
      mpValueCheckBox = new QCheckBox;
      connect(mpValueCheckBox, SIGNAL(toggled(bool)), SLOT(valueCheckBoxChanged(bool)));
      break;

    case Parameter::ReplaceableComponent:
    case Parameter::ReplaceableClass:
    case Parameter::Choices:
    case Parameter::ChoicesAllMatching:
      if (isReplaceableComponent() || isReplaceableClass()) {
        constrainedByClassName = mpModelInstanceElement->getReplaceable()->getConstrainedby();
        if (constrainedByClassName.isEmpty()) {
          auto pReplaceableClass = dynamic_cast<ModelInstance::ReplaceableClass*>(mpModelInstanceElement);
          if (pReplaceableClass) {
            constrainedByClassName = pReplaceableClass->getBaseClass();
          }
        }
      }
      if (mpModelInstanceElement->getAnnotation()->getChoices()) {
        displayChoices = mpModelInstanceElement->getAnnotation()->getChoices()->getChoicesDisplayStringList();
        valueChoices = mpModelInstanceElement->getAnnotation()->getChoices()->getChoicesValueStringList();
        commentChoices = mpModelInstanceElement->getAnnotation()->getChoices()->getChoicesCommentStringList();
      }
      parentClassName = mpElementParameters->getElementParentClassName();
      if (mpModelInstanceElement->getModel()) {
        restriction = mpModelInstanceElement->getModel()->getRestriction();
      } else {
        restriction = mpModelInstanceElement->getType();
      }
      elementName = mpModelInstanceElement->getName();

      if (constrainedByClassName.isEmpty()) {
        constrainedByClassName = className;
      }

      createValueComboBox();
      // add choices if there are any
      for (i = 0; i < valueChoices.size(); i++) {
        QString value = valueChoices[i];
        QString display = i < displayChoices.size() ? displayChoices[i] : value;
        QString comment = i < commentChoices.size() ? commentChoices[i] : value;
        mpValueComboBox->addItemWithToolTip(display, value, comment);
      }

      // choicesAllMatching
      if (mpModelInstanceElement->getAnnotation()->isChoicesAllMatching()) {
        replaceableChoices = pOMCProxy->getReplaceableChoices(constrainedByClassName, parentClassName);
      }

      {
        const bool isClass = isReplaceableClass();
        const bool isReplaceable = isClass || isReplaceableComponent();
        const bool isRecord = (restriction == QStringLiteral("record"));
        const QString scopePrefix = parentClassName + ".";

        for (const QStringList &choice : replaceableChoices) {
          QString text = choice.value(0);
          const QString comment = choice.value(1);

          QString value;
          if (isReplaceable) {
            // if the choice points to a class in this scope, remove the scope
            if (text.startsWith(scopePrefix)) {
              text.remove(0, scopePrefix.size());
            }
            value = isClass ? QString("redeclare %1 %2 = %3").arg(restriction, elementName, text)
                            : QString("redeclare %1 %2").arg(text, elementName);
          } else {
            // Records need () to be instantiated, e.g. DC01() instead of DC01. See issue #17600.
            if (isRecord) {
              text += "()";
            }
            value = text;
          }

          // add comment if available
          QString toolTip = text;
          if (!comment.isEmpty()) {
            toolTip += " \"" + comment + "\"";
          }

          mpValueComboBox->addItemWithToolTip(text, value, toolTip);
        }
      }

      connect(mpValueComboBox, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &Parameter::valueComboBoxChanged);
      break;
    case Parameter::Normal:
    default:
      mpValueTextBox = new QLineEdit;
      mpValueTextBox->setMinimumWidth(DefaultMinimumWidthForValue);
      mpValueTextBox->installEventFilter(this);
      if (mpModelInstanceElement->getDimensions().isArray()) {
        mpArrayEditorButton = new QToolButton;
        mpArrayEditorButton->setIcon(QIcon(":/Resources/icons/general.svg"));
        mpArrayEditorButton->setToolTip(tr("Edit array"));
        mpArrayEditorButton->setAutoRaise(true);
        connect(mpArrayEditorButton, &QToolButton::clicked, this, &Parameter::arrayEditorButtonClicked);
      }
      break;
  }
}

/*!
 * \brief Parameter::createValueComboBox
 * Creates the value combobox.
 */
void Parameter::createValueComboBox()
{
  mpValueComboBox = new ComboBox;
  mpValueComboBox->setMinimumWidth(DefaultMinimumWidthForValue);
  mpValueComboBox->setEditable(true);
  mpValueComboBox->setInsertPolicy(QComboBox::NoInsert);
  mpValueComboBox->addItemWithToolTip("", "", "");
}

/*!
 * \brief Parameter::enableDisableUnitComboBox
 * Enables/disables the unit combobox.
 * \param value
 */
void Parameter::enableDisableUnitComboBox(const QString &value)
{
  mpFinalEachMenuButton->setBreak(value.compare(Helper::BREAK) == 0);
  // Do not do anything when the value is empty
  if (value.isEmpty()) {
    return;
  }
  /* Enable/disable the unit combobox based on the literalConstant
   * Set the display unit as current when value is literalConstant otherwise use unit
   * ticket:5618 Disable the unit drop down when we have a symbolic parameter
   */
  bool literalConstant = Utilities::isValueLiteralConstant(value);
  mpUnitComboBox->setEnabled(mEnable && literalConstant);
  /* ticket:5976 don't change the unit combobox when the literalConstant is true
   * We only want to disbale and switch to unit when literalConstant is false and we got a symbolic or expression parameter.
   */
  if (!literalConstant) {
    resetUnitCombobox();
  }
  /* Issue #13636
   * Set each if value is scalar or remove it if value is not scalar.
   */
  if (mpFinalEachMenuButton->hasEach()) {
    mpFinalEachMenuButton->setEach(Utilities::isValueScalarLiteralConstant(value));
  }
}

/*!
 * \brief Parameter::updateValueBinding
 * Updates the value binding of the parameter and call updateParameters so depending parameters gets updated.
 * \param value
 */
void Parameter::updateValueBinding(const FlatModelica::Expression& expression)
{
  // update the binding with the new value
  mpModelInstanceElement->setBinding(expression);
  mpElementParameters->updateParameters();
}

/*!
 * \brief Parameter::isValueModifiedHelper
 * \return
 */
bool Parameter::isValueModifiedHelper() const
{
  const QString unit = mpUnitComboBox->itemData(mpUnitComboBox->currentIndex()).toString();
  /* if final each are modified
   * OR if fixed is modified
   * OR if fixed final each are modified
   * OR if displayUnit is modified
   * OR if displayUnit final each are modified
   */
  if ((mpFinalEachMenuButton && mpFinalEachMenuButton->isModified())
      || (isShowStartAndFixed() && getFixedState().compare(getOriginalFixedValue()) != 0)
      || (isShowStartAndFixed() && mpFixedFinalEachMenuButton && mpFixedFinalEachMenuButton->isModified())
      || (mpUnitComboBox->isEnabled() && !unit.isEmpty() && mDisplayUnit.compare(unit) != 0)
      || (mpDisplayUnitFinalEachMenuButton && mpDisplayUnitFinalEachMenuButton->isModified())) {
    return true;
  } else {
    return false;
  }
}

/*!
 * \brief Parameter::resetUnitCombobox
 * Resets the unit combobox to the default unit.
 */
void Parameter::resetUnitCombobox()
{
  int index = mpUnitComboBox->findData(mUnit);
  if (index > -1 && index != mpUnitComboBox->currentIndex()) {
    mpUnitComboBox->setCurrentIndex(index);
    mPreviousUnit = mpUnitComboBox->itemData(mpUnitComboBox->currentIndex()).toString();
  }
}

/*!
 * \brief Parameter::valueTextBoxChanged
 * Called when the focus is lost from the value textbox.\n
 * Updates the value according to the value entered.
 * \param text
 */
void Parameter::valueTextBoxChanged(const QString &text)
{
  try {
    updateValueBinding(FlatModelica::Expression::parse(text));
  } catch (const std::exception &e) {
    qDebug() << "Failed to parse value in Parameter::valueTextBoxChanged(): " << text;
    qDebug() << e.what();
  }
}

/*!
 * \brief Parameter::setBreakValue
 * Slot activated when break is toggled in the menu.
 * \param breakValue
 */
void Parameter::setBreakValue(bool breakValue)
{
  const QString breakStr = breakValue ? Helper::BREAK : "";
  setValueWidget(breakStr, false, mUnit, true);
}

/*!
 * \brief Parameter::editClassButtonClicked
 * Slot activate when mpEditClassButton clicked signal is raised.
 * Opens ElementParameters dialog for the redeclare class.
 */
void Parameter::editClassButtonClicked()
{
  QString type;
  QString value;
  QString defaultValue;
  if (isEnumeration() || isReplaceableComponent() || isReplaceableClass() || isChoicesAllMatching() || isChoices()) {
    value = mpValueComboBox->lineEdit()->text();
    defaultValue = mpValueComboBox->lineEdit()->placeholderText();
  } else {
    value = mpValueTextBox->text();
    defaultValue = mpValueTextBox->placeholderText();
  }
  value = value.startsWith('(') ? mName % value : value;
  QString modifier = value;
  QString defaultModifier = defaultValue;
  ModelInstance::Modifier *pReplaceableConstrainedByModifier = nullptr;
  QString comment;
  if (isReplaceableComponent()) {
    type = mpModelInstanceElement->getType();
    pReplaceableConstrainedByModifier = mpModelInstanceElement->getReplaceable()->getModifier();
  } else if (isReplaceableClass()) {
    auto pReplaceableClass = dynamic_cast<ModelInstance::ReplaceableClass*>(mpModelInstanceElement);
    type = pReplaceableClass->getBaseClass();
    pReplaceableConstrainedByModifier = pReplaceableClass->getReplaceable()->getModifier();
  } else {
    type = mpModelInstanceElement->getType();
  }
  // parse the Modelica code of element redeclaration to get the type and modifiers
  if (value.startsWith("redeclare")) {
    if (isReplaceableComponent()) {
      FlatModelica::Parser::getTypeFromElementRedeclaration(value, type, modifier, comment);
    } else if (isReplaceableClass()) {
      FlatModelica::Parser::getShortClassTypeFromElementRedeclaration(value, type, modifier, comment);
    }
  } else if (!value.isEmpty()) {
    FlatModelica::Parser::getModifierFromElementModification(value, modifier);
  }

  QString classPath;
  if (mpElementParameters && mpElementParameters->hasElement()) {
    // if we fail to find the type
    if ((mpModelInstanceElement == NULL) ||
        (mpModelInstanceElement->getTopLevelParentElement() == NULL) ||
        (mpModelInstanceElement->getTopLevelParentElement()->getParentModel() == NULL) ||
        (mpModelInstanceElement->getTopLevelParentElement()->getParentModel()->getName() == QString())) {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), tr("Unable to find the redeclare class."), QMessageBox::Ok);
      return;
    }
    classPath = mpModelInstanceElement->getTopLevelParentElement()->getParentModel()->getName();
  } else {
    classPath = mpElementParameters->getElementParentClassName();
  }
  // get type as qualified path
  const QString qualifiedType = MainWindow::instance()->getOMCProxy()->qualifyPath(classPath, type);
  // qDebug() << "element modifier" << modifier;
  const QJsonObject modifierJSON = MainWindow::instance()->getOMCProxy()->modifierToJSON(modifier);
  ModelInstance::Modifier *pElementModifier = new ModelInstance::Modifier("", QJsonValue(modifierJSON), mpModelInstanceElement->getParentModel());
  if (pReplaceableConstrainedByModifier) {
    // qDebug() << "replaceable constrainedby modifier" << pReplaceableConstrainedByModifier->toString();
    /*! Read the constrainedby modifiers and if they have a modifier from this class then use its value.
     *  See issue #14393
     */
    foreach (auto *pModifier, pReplaceableConstrainedByModifier->getModifiers()) {
      Parameter *pParameter = mpElementParameters->findParameter(pModifier->getName());
      /* Use the value of the parameter or its default value when the value is not set.
       * Never override the modifier value with an empty value, the value is used to
       * instantiate the class below the sub dialog.
       * See issue #16642
       */
      if (pParameter) {
        QString parameterValue = pParameter->getValue();
        if (parameterValue.isEmpty()) {
          parameterValue = pParameter->getDefaultValue();
        }
        if (!parameterValue.isEmpty()) {
          pModifier->setValue(parameterValue);
        }
      }
    }
    // qDebug() << "replaceable constrainedby modifier" << pReplaceableConstrainedByModifier->toString();
    QVector<const ModelInstance::Modifier*> modifiers;
    modifiers.append(pReplaceableConstrainedByModifier);
    modifiers.append(pElementModifier);
    ModelInstance::Modifier *pMergedModifier = ModelInstance::Modifier::mergeModifiersIntoOne(modifiers, mpModelInstanceElement->getParentModel());
    modifier = pMergedModifier->toString();
    delete pMergedModifier;
  }
  // qDebug() << "element and replaceable constrainedby merged modifier" << modifier;
  ModelInstance::Model *pCurrentModel = mpModelInstanceElement->getModel();
  const QJsonObject newModelJSON = MainWindow::instance()->getOMCProxy()->getModelInstance(qualifiedType, mpModelInstanceElement->getQualifiedName(), modifier);
  if (!newModelJSON.isEmpty()) {
    const QJsonObject defaultModifierJSON = MainWindow::instance()->getOMCProxy()->modifierToJSON(defaultModifier);
    ModelInstance::Modifier *pDefaultElementModifier = new ModelInstance::Modifier("", QJsonValue(defaultModifierJSON), mpModelInstanceElement->getParentModel());
    ModelInstance::Model *pNewModel = new ModelInstance::Model(newModelJSON, mpModelInstanceElement);
    mpModelInstanceElement->setModel(pNewModel);
    MainWindow::instance()->getProgressBar()->setRange(0, 0);
    MainWindow::instance()->showProgressBar();
    ElementParameters *pElementParameters = new ElementParameters(mpModelInstanceElement, mpElementParameters->getGraphicsView(), mpElementParameters->isInherited(), true,
                                                                  true, pDefaultElementModifier, pReplaceableConstrainedByModifier, pElementModifier, mpElementParameters);
    MainWindow::instance()->hideProgressBar();
    MainWindow::instance()->getStatusBar()->clearMessage();
    if (pElementParameters->exec() == QDialog::Accepted) {
      const QString modification = pElementParameters->getModification();
      if (isReplaceableClass()) {
        QString restriction;
        if (mpModelInstanceElement->getModel()) {
          restriction = mpModelInstanceElement->getModel()->getRestriction();
        } else {
          restriction = mpModelInstanceElement->getType();
        }
        QString elementRedeclaration = "redeclare " % restriction % " " % mpModelInstanceElement->getName() % " = " % type % " " % modification;
        if (!comment.isEmpty()) {
          elementRedeclaration = elementRedeclaration % " " % comment;
        }
        setValueWidget(elementRedeclaration, false, mUnit, true);
      } else {
        if (value.startsWith("redeclare")) {
          QString elementRedeclaration = "redeclare " % type % " " % mpModelInstanceElement->getName() % modification;
          if (!comment.isEmpty()) {
            elementRedeclaration = elementRedeclaration % " " % comment;
          }
          setValueWidget(elementRedeclaration, false, mUnit, true);
        } else {
          if (modification.isEmpty()) {
            setValueWidget("", false, mUnit, true);
          } else {
            /*! Issue #15548
             *  If record then prepend the type. It will become a binding equation.
             */
            if (mpModelInstanceElement->getModel() && mpModelInstanceElement->getModel()->isRecord()) {
              const QString name = StringHandler::makeClassNameRelative(mpModelInstanceElement->getType(),
                                                                        mpElementParameters->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure());
              setValueWidget(name % modification, false, mUnit, true);
            } else {
              setValueWidget(modification, false, mUnit, true);
            }
          }
        }
      }
    }
    pElementParameters->deleteLater();
    delete pDefaultElementModifier;
    // reset the actual model of the element
    mpModelInstanceElement->setModel(pCurrentModel);
    delete pNewModel;
  }
  delete pElementModifier;
}

/*!
 * \brief Parameter::fileSelectorButtonClicked
 * Slot activated when mpFileSelectorButton clicked SIGNAL is raised.
 * Opens a QFileDialog::getOpenFileName or QFileDialog::getSaveFileName so user can select a file.
 */
void Parameter::fileSelectorButtonClicked()
{
  QString filter, caption = "";
  QString fileName;
  /* saveSelector is given precedence if present.
   * There is nothing about it in the specification but we do so to keep consistant with Dymola.
   */
  if (mSaveSelectorFilter.compare("-") != 0 && mSaveSelectorCaption.compare("-") != 0) {
    if (mSaveSelectorFilter.compare("-") != 0) {
      filter = mSaveSelectorFilter;
    }
    caption = tr("Save");
    if (mSaveSelectorCaption.compare("-") != 0) {
      caption = mSaveSelectorCaption;
    }
    fileName = StringHandler::getSaveFileName(MainWindow::instance(), caption, NULL, filter, NULL);
  } else {
    filter = "";
    if (mLoadSelectorFilter.compare("-") != 0) {
      filter = mLoadSelectorFilter;
    }
    caption = tr("Load");
    if (mLoadSelectorCaption.compare("-") != 0) {
      caption = mLoadSelectorCaption;
    }
    fileName = StringHandler::getOpenFileName(MainWindow::instance(), caption, NULL, filter, NULL);
  }
  // if user press ESC
  if (fileName.isEmpty()) {
    return;
  }
  setValueWidget(QString("\"%1\"").arg(fileName), false, mUnit, true);
}

/*!
 * \brief Parameter::arrayEditorButtonClicked
 * Slot activated when mpArrayEditorButton clicked SIGNAL is raised.
 * Opens the array parameter editor dialog so the user can edit array cells.
 */
void Parameter::arrayEditorButtonClicked()
{
  const ModelInstance::Dimensions &dimensions = mpModelInstanceElement->getDimensions();
  ArrayParameterEditorDialog dialog(getValue(), mDefaultValue, mName,
                                    dimensions.getAbsynDimensions(), dimensions.getTypedDimensions(),
                                    MainWindow::instance());
  if (dialog.exec() == QDialog::Accepted) {
    const QString arrayValue = dialog.getArrayValue();
    if (arrayValue.compare(getValue()) != 0) {
      setValueWidget(arrayValue, false, mUnit, true);
    }
  }
}

/*!
 * \brief Parameter::unitComboBoxChanged
 * SLOT activated when mpUnitComboBox currentIndexChanged(int) SIGNAL is raised.\n
 * Updates the value according to the unit selected.
 * \param text
 */
void Parameter::unitComboBoxChanged(int index)
{
  if (!mDefaultValue.isEmpty()) {
    setValueWidget(mDefaultValue, true, mPreviousUnit, false, true);
  }
  QString value = getValue();
  if (!value.isEmpty()) {
    setValueWidget(value, false, mPreviousUnit, true, true);
  }
  mPreviousUnit = mpUnitComboBox->itemData(index).toString();
}

/*!
 * \brief Parameter::valueComboBoxChanged
 * SLOT activated when mpValueComboBox currentIndexChanged(int) SIGNAL is raised.\n
 * Updates the value according to the value selected.
 * \param index
 */
void Parameter::valueComboBoxChanged(int index)
{
  mpValueComboBox->lineEdit()->setText(mpValueComboBox->itemData(index).toString());
  mpValueComboBox->lineEdit()->setModified(true);

  QString value = mpValueComboBox->lineEdit()->text();
  if (value.isEmpty()) {
    value = mpValueComboBox->lineEdit()->placeholderText();
  }

  int toolTipIndex = mpValueComboBox->findData(value);
  mpValueComboBox->setToolTip(mpValueComboBox->itemData(toolTipIndex, Qt::ToolTipRole).toString());

  // reset in case of empty selection
  if (index == 0) {
    resetUnitCombobox();
    mpModelInstanceElement->resetBinding();
    try {
      updateValueBinding(static_cast<const ModelInstance::Element*>(mpModelInstanceElement)->getBinding());
    } catch (const std::exception &e) {
      qDebug() << "Failed to reset expression to binding in Parameter::valueComboBoxChanged()";
      qDebug() << e.what();
    }
  } else {
    try {
      if (isEnumeration()) {
        updateValueBinding(FlatModelica::Expression(value.toStdString(), index));
      } else {
        if (isChoices()) {
          resetUnitCombobox();
        }
        updateValueBinding(FlatModelica::Expression::parse(value));
      }
    } catch (const std::exception &e) {
      qDebug() << "Failed to parse value in Parameter::valueComboBoxChanged(): " << value;
      qDebug() << e.what();
    }
  }
}

/*!
 * \brief Parameter::valueCheckBoxChanged
 * SLOT activated when mpValueCheckBox toggled(bool) SIGNAL is raised.\n
 * Updates the value according to the checkbox state.
 * \param toggle
 */
void Parameter::valueCheckBoxChanged(bool toggle)
{
  mValueCheckBoxModified = true;
  updateValueBinding(FlatModelica::Expression(toggle));
}

void Parameter::showFixedMenu()
{
  // create a menu
  QMenu menu;
  Label *pTitleLabel = new Label("Fixed");
  QWidgetAction *pTitleAction = new QWidgetAction(&menu);
  pTitleAction->setDefaultWidget(pTitleLabel);
  menu.addAction(pTitleAction);
  // fixed action group
  QActionGroup *pFixedActionGroup = new QActionGroup(this);
  pFixedActionGroup->setExclusive(false);
  // true case action
  QString trueText = tr("true: start-value is used to initialize");
  QAction *pTrueAction = new QAction(trueText, pFixedActionGroup);
  pTrueAction->setCheckable(true);
  connect(pTrueAction, SIGNAL(triggered()), SLOT(trueFixedClicked()));
  menu.addAction(pTrueAction);
  // false case action
  QString falseText = tr("false: start-value is only a guess-value");
  QAction *pFalseAction = new QAction(falseText, pFixedActionGroup);
  pFalseAction->setCheckable(true);
  connect(pFalseAction, SIGNAL(triggered()), SLOT(falseFixedClicked()));
  menu.addAction(pFalseAction);
  // inherited case action
  QString inheritedText = tr("inherited: (%1)").arg(mpFixedCheckBox->getInheritedValue() ? trueText : falseText);
  QAction *pInheritedAction = new QAction(inheritedText, pFixedActionGroup);
  pInheritedAction->setCheckable(true);
  connect(pInheritedAction, SIGNAL(triggered()), SLOT(inheritedFixedClicked()));
  menu.addAction(pInheritedAction);
  // set the menu actions states
  if (mpFixedCheckBox->getTickStateString().compare("true") == 0) {
    pTrueAction->setChecked(true);
  } else if (mpFixedCheckBox->getTickStateString().compare("false") == 0) {
    pFalseAction->setChecked(true);
  } else {
    pInheritedAction->setChecked(true);
  }
  // show the menu
  menu.exec(mpFixedCheckBox->mapToGlobal(QPoint(0, 0)));
}

void Parameter::trueFixedClicked()
{
  mpFixedCheckBox->setTickState(false, true);
}

void Parameter::falseFixedClicked()
{
  mpFixedCheckBox->setTickState(false, false);
}

void Parameter::inheritedFixedClicked()
{
  mpFixedCheckBox->setTickState(true, mpFixedCheckBox->getInheritedValue());
}

/*!
 * \brief Parameter::eventFilter
 * Handles the FocusOut event of value textbox.
 * \param pWatched
 * \param pEvent
 * \return
 */
bool Parameter::eventFilter(QObject *pWatched, QEvent *pEvent)
{
  if (mpValueTextBox == pWatched && pEvent->type() == QEvent::FocusOut
      && mpElementParameters && !mpElementParameters->skipFocusOutEvent()) {
    const QString text = mpValueTextBox->text();
    enableDisableUnitComboBox(text);
    valueTextBoxChanged(text);
  }

  return QObject::eventFilter(pWatched, pEvent);
}

/*!
  \class GroupBox
  \brief Creates a group for parameters.
  */
GroupBox::GroupBox(const QString &title, QWidget *parent)
  : QGroupBox(title, parent)
{
  mpGroupImageLabel = new Label;
  mpGroupImageLabel->setScaledContents(true);
  mpGridLayout = new QGridLayout;
  mpGridLayout->setObjectName(title);
  mpGridLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  mpHorizontalLayout = new QHBoxLayout;
  mpHorizontalLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  mpHorizontalLayout->addLayout(mpGridLayout, 1);
  mpHorizontalLayout->addWidget(mpGroupImageLabel, 0, Qt::AlignRight);
  setLayout(mpHorizontalLayout);
}

/*!
  Sets the group image.
  \param groupImage - the absolute path of the image.
  */
void GroupBox::setGroupImage(QString groupImage)
{
  if (QFile::exists(groupImage)) {
    QPixmap pixmap(groupImage);
    mpGroupImageLabel->setMaximumWidth(pixmap.width() / qApp->devicePixelRatio());
    mpGroupImageLabel->setMaximumHeight(pixmap.height() / qApp->devicePixelRatio());
    mpGroupImageLabel->setPixmap(pixmap);
  } else {
    mpGroupImageLabel->hide();
  }
}

/*!
  \class ParametersScrollArea
  \brief Creates a scroll area for each tab of the element parameters dialog.
  */
ParametersScrollArea::ParametersScrollArea()
{
  mpWidget = new QWidget;
  setFrameShape(QFrame::NoFrame);
  setBackgroundRole(QPalette::Base);
  setWidgetResizable(true);
  mGroupBoxesList.clear();
  mpVerticalLayout = new QVBoxLayout;
  mpVerticalLayout->setAlignment(Qt::AlignLeft | Qt::AlignTop);
  mpWidget->setLayout(mpVerticalLayout);
  setWidget(mpWidget);
}

/*!
 * Reimplementation of minimumSizeHint.
 * Finds maximum optimal size for ElementParameters dialog. If the dialog is larger than screen then shows the scrollbars.
 */
QSize ParametersScrollArea::minimumSizeHint() const
{
  QSize size = QWidget::sizeHint();
  // find optimal width and height
  int screenWidth = QApplication::primaryScreen()->availableGeometry().width() - 100;
  int screenHeight = QApplication::primaryScreen()->availableGeometry().height() - 300;
  int widgetWidth = mpWidget->minimumSizeHint().width() + (verticalScrollBar()->isVisible() ? verticalScrollBar()->width() : 0);
  size.rwidth() = qMin(screenWidth, widgetWidth);
  int widgetHeight = mpWidget->minimumSizeHint().height() + (horizontalScrollBar()->isVisible() ? horizontalScrollBar()->height() : 0);
  size.rheight() = qMin(screenHeight, widgetHeight);
  return size;
}

/*!
  Adds a QGroupBox to the layout.
  \param pGroupBox - pointer to QGroupBox.
  \param pGroupBoxLayout - pointer to QGridLayout.
  */
void ParametersScrollArea::addGroupBox(GroupBox *pGroupBox)
{
  if (!getGroupBox(pGroupBox->title())) {
    pGroupBox->hide();  /* create a hidden groupbox, we show it when it contains the parameters. */
    mGroupBoxesList.append(pGroupBox);
    mpVerticalLayout->addWidget(pGroupBox, 0, Qt::AlignTop);
  }
}

/*!
  Returns the GroupBox by reading the list of GroupBoxes.
  \return the GroupBox
  */
GroupBox* ParametersScrollArea::getGroupBox(const QString &title)
{
  foreach (GroupBox *pGroupBox, mGroupBoxesList) {
    if (pGroupBox->title().compare(title) == 0) {
      return pGroupBox;
    }
  }
  return 0;
}

/*!
  Returns the main layout of the widget.
  \return the QVBoxLayout
  */
QVBoxLayout *ParametersScrollArea::getLayout()
{
  return mpVerticalLayout;
}

/*!
 * \class ElementParameters
 * \brief A dialog for displaying Element's parameters.
 */
/*!
 * \brief ElementParameters::ElementParameters
 * \param pElement - pointer to ModelInstance::Element
 * \param pGraphicsView
 * \param inherited
 * \param nested
 * \param pDefaultElementModifier
 * \param pReplaceableConstrainedByModifier
 * \param pElementModifier
 * \param pParent
 */
ElementParameters::ElementParameters(ModelInstance::Element *pElement, GraphicsView *pGraphicsView, bool inherited, bool nested, bool subDialog,
                                     ModelInstance::Modifier *pDefaultElementModifier, ModelInstance::Modifier *pReplaceableConstrainedByModifier,
                                     ModelInstance::Modifier *pElementModifier, QWidget *pParent)
  : QDialog(pParent)
{
  mpElement = pElement;
  mpGraphicsView = pGraphicsView;
  const QString className = pGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  if (pElement) {
    setWindowTitle(tr("%1 - %2 - %3 in %4").arg(Helper::applicationName, tr("Element Parameters"), getElementQualifiedName(), className));
  } else {
    setWindowTitle(tr("%1 - %2 - %3").arg(Helper::applicationName, Helper::parameters, className));
  }
  mInherited = inherited;
  mNested = nested;
  mSubDialog = subDialog;
  mpDefaultElementModifier = pDefaultElementModifier;
  mpReplaceableConstrainedByModifier = pReplaceableConstrainedByModifier;
  mpElementModifier = pElementModifier;
  mModification.clear();
  setUpDialog();
}

/*!
 * \brief ElementParameters::~ElementParameters
 * Deletes the list of Parameter objects.
 */
ElementParameters::~ElementParameters()
{
  qDeleteAll(mParametersList.begin(), mParametersList.end());
  mParametersList.clear();
}

/*!
 * \brief ElementParameters::getElementQualifiedName
 * Returns the qualified name of the element.
 * \return
 */
QString ElementParameters::getElementQualifiedName() const
{
  return hasElement() ? mpElement->getQualifiedName() : "";
}

/*!
 * \brief ElementParameters::getElementParentClassName
 * Returns the class name where the component is defined.
 * \return
 */
QString ElementParameters::getElementParentClassName() const
{
  return hasElement() ? mpElement->getParentModel()->getName() : mpGraphicsView->getModelWidget()->getModelInstance()->getName();
}

/*!
 * \brief ElementParameters::getComponentClassName
 * Returns the component's class name in case of component or class name in case of top level.
 * \return
 */
QString ElementParameters::getComponentClassName() const
{
  return hasElement() ? mpElement->getModel()->getName() : mpGraphicsView->getModelWidget()->getModelInstance()->getName();
}

/*!
 * \brief ElementParameters::getComponentClassComment
 * Returns the component's class comment in case of component or class comment in case of top level.
 * \return
 */
QString ElementParameters::getComponentClassComment() const
{
  return hasElement() ? mpElement->getModel()->getComment() : mpGraphicsView->getModelWidget()->getModelInstance()->getComment();
}

/*!
 * \brief ElementParameters::getModel
 * Return the model instance.
 * \return
 */
ModelInstance::Model *ElementParameters::getModel() const
{
  return hasElement() ? mpElement->getModel() : mpGraphicsView->getModelWidget()->getModelInstance();
}

/*!
 * \brief ElementParameters::findParameter
 * Finds the Parameter.
 * \param parameter
 * \param caseSensitivity
 * \return
 */
Parameter* ElementParameters::findParameter(const QString &parameter, Qt::CaseSensitivity caseSensitivity) const
{
  foreach (Parameter *pParameter, mParametersList) {
    if (pParameter->getModelInstanceElement()->getName().compare(parameter, caseSensitivity) == 0) {
      return pParameter;
    }
  }
  return nullptr;
}

/*!
 * \brief setFinalEachBreak
 * Helper function to set final, each and break in the FinalEachToolButton according to the modifier.
 * \param pFinalEachToolButton
 * \param pModifier
 */
static void setFinalEachBreak(FinalEachToolButton *pFinalEachToolButton, ModelInstance::Modifier *pModifier)
{
  if (pFinalEachToolButton && pModifier) {
    pFinalEachToolButton->setFinal(pModifier->isFinal());
    pFinalEachToolButton->setEach(pModifier->isEach());
    pFinalEachToolButton->setBreak(pModifier->isBreak());
  }
}

/*!
 * \brief ElementParameters::applyFinalStartFixedAndDisplayUnitModifiers
 * \param pParameter
 * \param pModifier
 * \param defaultValue
 * \param isElementModification
 */
void ElementParameters::applyFinalStartFixedAndDisplayUnitModifiers(Parameter *pParameter, ModelInstance::Modifier *pModifier, bool defaultValue, bool isElementModification)
{
  if (pParameter && pModifier) {
    /* Ticket #2531
     * Check if parameter is marked final.
     * Redeclared but not replaceable classes should not show up in the parameter window. See issue #11311.
     * Only check for redeclare and replaceable modification for top level and when its not element modification. See issue #13334.
     */
    if (defaultValue && (pModifier->isFinal() || (!isElementModification && !pParameter->getModelInstanceElement()->isParameter() && pModifier->isRedeclare() && !pModifier->isReplaceable()))) {
      if (mParametersList.removeOne(pParameter)) {
        delete pParameter;
      }
    } else {
      // if builtin type
      if (MainWindow::instance()->getOMCProxy()->isBuiltinType(pParameter->getModelInstanceElement()->getRootType())) {
        const QString value = pModifier->getValue();
        // if value is not empty then use it otherwise try to read start and fixed modifiers
        if (pParameter->isShowStartAttribute() || (value.isEmpty() && !pParameter->getModelInstanceElement()->isParameter() && !pParameter->getModelInstanceElement()->isInput())) {
          bool hasStart = pModifier->hasModifier("start");
          bool isStartFinal = false;
          bool hasFixed = pModifier->hasModifier("fixed");
          bool isFixedFinal = false;
          if (hasStart) {
            if (!pParameter->isGroupDefined() && !pParameter->getModelInstanceElement()->isParameter() && !pParameter->getModelInstanceElement()->isInput()) {
              if (!pParameter->isTabDefined()) {
                pParameter->setTab(General);
              }
              pParameter->setGroup(Initialization);
              addOrUpdateParametersScrollArea(pParameter);
            }
            pParameter->setShowStartAndFixed(true);
          }
          if (hasStart) {
            ModelInstance::Modifier *pStartModifier = pModifier->getModifier("start");
            if (pStartModifier) {
              isStartFinal = pStartModifier->isFinal();
              pParameter->setValueWidget(StringHandler::removeFirstLastQuotes(pStartModifier->getValue()), defaultValue, pParameter->getUnit(), mNested);
              setFinalEachBreak(pParameter->getFinalEachMenu(), pStartModifier);
            }
          }
          if (hasFixed) {
            ModelInstance::Modifier *pFixedModifier = pModifier->getModifier("fixed");
            if (pFixedModifier) {
              isFixedFinal = pFixedModifier->isFinal();
              const QString fixedValue = StringHandler::removeFirstLastQuotes(pFixedModifier->getValue());
              /* only set the fixed state if the value is true or false.
               * Don't try to set if value is not defined e.g., in the case of `x(final fixed)`
               */
              if (fixedValue == "true" || fixedValue == "false") {
                pParameter->setFixedState(fixedValue, defaultValue);
              }
              setFinalEachBreak(pParameter->getFixedFinalEachMenu(), pFixedModifier);
            }
          }
          /* Issue #12898
           * If start is final then hide the value box.
           * If fixed is final then hide the fixed checkbox.
           * If both are final then delete the parameter.
           * They can be set final at different levels e.g., start can be set final at declaration and fixed set final via extends modifier in parent.
           * so we set start and fixed final in the hierarchy flags and then check them when removing the parameter.
           * We do these checks only for the defaultValue i.e., when it comes from declaration and not from component or extends modification. See issue #13333.
           */
          if (defaultValue) {
            if (isStartFinal) {
              pParameter->hideValueWidget();
              pParameter->getFinalEachMenu()->setVisible(false);
              pParameter->setStartFinalInHierarchy(true);
            }
            if (isFixedFinal) {
              pParameter->getFixedCheckBox()->setVisible(false);
              pParameter->getFixedFinalEachMenu()->setVisible(false);
              pParameter->setFixedFinalInHierarchy(true);
            }
            if (pParameter->isStartFinalInHierarchy() && pParameter->isFixedFinalInHierarchy()) {
              if (mParametersList.removeOne(pParameter)) {
                delete pParameter;
              }
              return;
            }
          }
        } else {
          pParameter->setValueWidget(value, defaultValue, pParameter->getUnit(), mNested);
          // set final and each checkboxes in the menu
          setFinalEachBreak(pParameter->getFinalEachMenu(), pModifier);
        }
      } else {
        pParameter->setValueWidget(pModifier->toString(true, true, false, true), defaultValue, pParameter->getUnit(), mNested);
        setFinalEachBreak(pParameter->getFinalEachMenu(), pModifier);
      }
      // displayUnit
      ModelInstance::Modifier *pDisplayUnitModifier = pModifier->getModifier("displayUnit");
      QString displayUnit;
      if (pDisplayUnitModifier) {
        displayUnit = StringHandler::removeFirstLastQuotes(pDisplayUnitModifier->getValue());
      }
      if (!displayUnit.isEmpty()) {
        int index = pParameter->getUnitComboBox()->findData(displayUnit);
        if (index < 0) {
          if (pDisplayUnitModifier && displayUnit.compare(Helper::BREAK) == 0) {
            pParameter->getDisplayUnitFinalEachMenu()->setBreak(pDisplayUnitModifier->isBreak());
          } else {
            // add modifier as additional display unit if compatible
            OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
            if (pParameter->getUnitComboBox()->count() > 0 && pOMCProxy->convertUnits(pParameter->getUnitComboBox()->itemData(0).toString(), displayUnit).unitsCompatible) {
              pParameter->getUnitComboBox()->addItem(OMPlot::Plot::convertUnitToSymbol(displayUnit), displayUnit);
              index = pParameter->getUnitComboBox()->count() - 1;
            }
          }
        }
        if (index > -1) {
          /* Issue #11782.
           * Setting the display unit trigger SIGNAL currentIndexChanged and calls SLOT unitComboBoxChanged which will set the correct value.
           */
          pParameter->getUnitComboBox()->setCurrentIndex(index);
          pParameter->setDisplayUnit(displayUnit);
          if (!defaultValue) {
            pParameter->setHasDisplayUnit(true);
          }
          if (pDisplayUnitModifier) {
            pParameter->getDisplayUnitFinalEachMenu()->setFinal(pDisplayUnitModifier->isFinal());
            pParameter->getDisplayUnitFinalEachMenu()->setEach(pDisplayUnitModifier->isEach());
          }
        }
      }
    }
  }
}

/*!
 * \brief ElementParameters::updateParameters
 * Updates the parameters.
 */
void ElementParameters::updateParameters()
{
  foreach (Parameter *pParameter, mParametersList) {
    pParameter->update();
  }
}

/*!
 * \brief ElementParameters::setUpDialog
 * Creates the Dialog and set up all the controls with default values.
 */
void ElementParameters::setUpDialog()
{
  // heading label
  mpParametersHeading = Utilities::getHeadingLabel(Helper::parameters);
  // set separator line
  mHorizontalLine = Utilities::getHeadingLine();
  // parameters tab widget
  mpParametersTabWidget = new QTabWidget;
  // Component Group Box
  mpComponentGroupBox = new QGroupBox(tr("Component"));
  // Component name
  mpComponentNameLabel = new Label(Helper::name);
  QString name;
  if (hasElement()) {
    name = getElementQualifiedName();
    if (isElementArray()) {
      name.append("[" % getElementDimensions() % "]");
    }
  }
  mpComponentNameTextBox = new Label(name);
  mpComponentCommentLabel = new Label(Helper::comment);
  mpComponentCommentTextBox = new Label(hasElement() ? mpElement->getComment() : "");
  QGridLayout *pComponentGroupBoxLayout = new QGridLayout;
  pComponentGroupBoxLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pComponentGroupBoxLayout->addWidget(mpComponentNameLabel, 0, 0);
  pComponentGroupBoxLayout->addWidget(mpComponentNameTextBox, 0, 1);
  pComponentGroupBoxLayout->addWidget(mpComponentCommentLabel, 1, 0);
  pComponentGroupBoxLayout->addWidget(mpComponentCommentTextBox, 1, 1);
  mpComponentGroupBox->setLayout(pComponentGroupBoxLayout);
  // Component Class Group Box
  mpComponentClassGroupBox = new QGroupBox(tr("Class"));
  // Component class name
  mpComponentClassNameLabel = new Label(Helper::path);
  mpComponentClassNameTextBox = new Label(getComponentClassName());
  // Component comment
  mpComponentClassCommentLabel = new Label(Helper::comment);
  mpComponentClassCommentTextBox = new Label;
  mpComponentClassCommentTextBox->setTextFormat(Qt::RichText);
  mpComponentClassCommentTextBox->setTextInteractionFlags(mpComponentClassCommentTextBox->textInteractionFlags() | Qt::LinksAccessibleByMouse | Qt::LinksAccessibleByKeyboard);
  mpComponentClassCommentTextBox->setText(getComponentClassComment());
  connect(mpComponentClassCommentTextBox, SIGNAL(linkActivated(QString)), SLOT(commentLinkClicked(QString)));
  QGridLayout *pComponentClassGroupBoxLayout = new QGridLayout;
  pComponentClassGroupBoxLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pComponentClassGroupBoxLayout->addWidget(mpComponentClassNameLabel, 0, 0);
  pComponentClassGroupBoxLayout->addWidget(mpComponentClassNameTextBox, 0, 1);
  pComponentClassGroupBoxLayout->addWidget(mpComponentClassCommentLabel, 1, 0);
  pComponentClassGroupBoxLayout->addWidget(mpComponentClassCommentTextBox, 1, 1);
  mpComponentClassGroupBox->setLayout(pComponentClassGroupBoxLayout);
  // Create General tab and Parameters GroupBox
  ParametersScrollArea *pParametersScrollArea = new ParametersScrollArea;
  // first add the Component Group Box and component class group box
  if (hasElement()) {
    pParametersScrollArea->getLayout()->addWidget(mpComponentGroupBox);
  }
  pParametersScrollArea->getLayout()->addWidget(mpComponentClassGroupBox);
  mTabsMap.insert(General, mpParametersTabWidget->addTab(pParametersScrollArea, General));
  // create parameters tabs and groupboxes
  createTabsGroupBoxesAndParameters(getModel(), hasElement());
  fetchElementExtendsModifiers(getModel(), hasElement());
  if (hasElement()) {
    fetchModifiers(mpElement->getModifier());
    // In case of element mode use the root parent ModelInstance::Element to read the element modifiers.
    if (mpGraphicsView->getModelWidget()->isElementMode()) {
      fetchRootElementModifiers(mpGraphicsView->getModelWidget()->getModelInstance()->getRootParentElement());
    }
    fetchClassExtendsModifiers(mpElement);
    // In case of element mode use the root parent ModelInstance::Element to read the extends modifiers.
    if (mpGraphicsView->getModelWidget()->isElementMode()) {
      fetchRootClassExtendsModifiers(mpGraphicsView->getModelWidget()->getModelInstance()->getRootParentElement());
    }
  }
  // Apply the default modifiers that are given in the redeclaration of the replaceable class or component.
  applyModifier(mpDefaultElementModifier, true);
  // Apply the modifiers that are given in the constainedBy of the replaceable class or component.
  applyModifier(mpReplaceableConstrainedByModifier, true);
  // Apply the modifiers that are given in the redeclaration of the replaceable class or component.
  applyModifier(mpElementModifier, false);

  foreach (Parameter *pParameter, mParametersList) {
    ParametersScrollArea *pParametersScrollArea = qobject_cast<ParametersScrollArea*>(mpParametersTabWidget->widget(mTabsMap.value(pParameter->getTab())));
    if (pParametersScrollArea) {
      if (!pParameter->getGroup().isEmpty()) {
        GroupBox *pGroupBox = pParametersScrollArea->getGroupBox(pParameter->getGroup());
        if (pGroupBox) {
          /* We hide the groupbox when we create it. Show the groupbox now since it has a parameter. */
          pGroupBox->show();
          QGridLayout *pGroupBoxGridLayout = pGroupBox->getGridLayout();
          int rowIndex = pGroupBoxGridLayout->rowCount();
          int columnIndex = 0;
          mHandledModifiersVector.append(pParameter->getModelInstanceElement()->getName());
          pParameter->updateNameLabel();
          pGroupBoxGridLayout->addWidget(pParameter->getNameLabel(), rowIndex, columnIndex++, Qt::AlignRight);
          if (pParameter->isShowStartAndFixed()) {
            pGroupBoxGridLayout->addWidget(pParameter->getFixedCheckBox(), rowIndex, columnIndex++);
            pGroupBoxGridLayout->addWidget(pParameter->getFixedFinalEachMenu(), rowIndex, columnIndex++);
          } else {
            pGroupBoxGridLayout->addItem(new QSpacerItem(0, 0), rowIndex, columnIndex++);
            pGroupBoxGridLayout->addItem(new QSpacerItem(0, 0), rowIndex, columnIndex++);
          }
          pGroupBoxGridLayout->addWidget(pParameter->getValueWidget(), rowIndex, columnIndex++);

          if (pParameter->getArrayEditorButton()) {
            pGroupBoxGridLayout->addWidget(pParameter->getArrayEditorButton(), rowIndex, columnIndex++);
          } else {
            pGroupBoxGridLayout->addItem(new QSpacerItem(0, 0), rowIndex, columnIndex++);
          }
          if (pParameter->getEditClassButton()) {
            pGroupBoxGridLayout->addWidget(pParameter->getEditClassButton(), rowIndex, columnIndex++);
          } else {
            pGroupBoxGridLayout->addItem(new QSpacerItem(0, 0), rowIndex, columnIndex++);
          }
          pGroupBoxGridLayout->addWidget(pParameter->getFinalEachMenu(), rowIndex, columnIndex++);
          if (pParameter->getLoadSelectorFilter().compare("-") != 0 || pParameter->getLoadSelectorCaption().compare("-") != 0 ||
              pParameter->getSaveSelectorFilter().compare("-") != 0 || pParameter->getSaveSelectorCaption().compare("-") != 0) {
            pGroupBoxGridLayout->addWidget(pParameter->getFileSelectorButton(), rowIndex, columnIndex++);
          } else {
            pGroupBoxGridLayout->addItem(new QSpacerItem(0, 0), rowIndex, columnIndex++);
          }
          if (pParameter->getUnitComboBox()->count() > 0) { // only add the unit combobox if we really have a unit
            /* ticket:4421
             * Show a fixed value when there is only one unit.
             */
            if (pParameter->getUnitComboBox()->count() == 1) {
              pGroupBoxGridLayout->addWidget(new Label(pParameter->getUnitComboBox()->currentText()), rowIndex, columnIndex++);
            } else {
              pGroupBoxGridLayout->addWidget(pParameter->getUnitComboBox(), rowIndex, columnIndex++);
            }
            pGroupBoxGridLayout->addWidget(pParameter->getDisplayUnitFinalEachMenu(), rowIndex, columnIndex++);
          } else {
            pGroupBoxGridLayout->addItem(new QSpacerItem(0, 0), rowIndex, columnIndex++);
            pGroupBoxGridLayout->addItem(new QSpacerItem(0, 0), rowIndex, columnIndex++);
          }
          pGroupBoxGridLayout->addWidget(pParameter->getCommentLabel(), rowIndex, columnIndex);
        }
      }
    }
  }
  // Issue #7494. Hide any empty tab. We start the loop from 1 since we don't want to remove General tab.
  for (int i = 1; i < mpParametersTabWidget->count(); ++i) {
    ParametersScrollArea *pParametersScrollArea = qobject_cast<ParametersScrollArea*>(mpParametersTabWidget->widget(i));
    if (pParametersScrollArea) {
      bool tabIsEmpty = true;
      // The tab is empty if its groupbox layout is empty.
      for (int j = 0; j < pParametersScrollArea->groupBoxesSize(); ++j) {
        GroupBox *pGroupBox = pParametersScrollArea->getGroupBox(j);
        if (pGroupBox && !pGroupBox->getGridLayout()->isEmpty()) {
          tabIsEmpty = false;
          break;
        }
      }
      // If the tab is empty then remove it and move one step back.
      if (tabIsEmpty) {
        mpParametersTabWidget->removeTab(i);
        --i;
        pParametersScrollArea->deleteLater();
      }
    }
  }

  mpModifiersLabel = new Label("Add new modifiers, e.g., phi(start = 1), x(max = 2) = y, system1(component3(p = 3))");
  mpModifiersTextBox = new QLineEdit;
  /* Do not add "Add New Modifiers" group when we are modifying top level parameters.
   * We don't know yet how to set the modifiers in the top level parameter editing.
   * For now simply hide the Modifiers tab in that case.
   */
  if (hasElement()) {
    // create Modifiers tab
    ParametersScrollArea *pModifiersParametersScrollArea = new ParametersScrollArea;
    GroupBox *pGroupBox = new GroupBox(AddNewModifiers);
    pModifiersParametersScrollArea->addGroupBox(pGroupBox);
    // We hide the groupbox when we create it. Show the groupbox now.
    pGroupBox->show();
    QGridLayout *pGroupBoxGridLayout = pGroupBox->getGridLayout();
    // we match the layout same as defined for parameters layout below.
    // label
    pGroupBoxGridLayout->addWidget(mpModifiersLabel, 0, 0);
    // text field
    pGroupBoxGridLayout->addWidget(mpModifiersTextBox, 1, 0);
    // Modifiers group box
    GroupBox *pModifiersGroupBox = new GroupBox(Modifiers);
    QGridLayout *pModifiersGroupBoxGridLayout = pModifiersGroupBox->getGridLayout();
    pModifiersParametersScrollArea->addGroupBox(pModifiersGroupBox);
    // We hide the groupbox when we create it. Show the groupbox now.
    ModelInstance::Modifier *pModifier = mNested ? mpElementModifier : mpElement->getModifier();
    int modifiersCount = 0;
    if (pModifier) {
      foreach (auto *pModifier, pModifier->getModifiers()) {
        if (mHandledModifiersVector.contains(pModifier->getName())) {
          continue;
        }
        Label *pModifierLabel = new Label(pModifier->getName());
        mModifierLabelsVector.append(pModifierLabel);
        QString modifierValue = pModifier->toString(true, true);
        if (!modifierValue.isEmpty() && !modifierValue.startsWith("(")) {
          modifierValue = QLatin1String("=") % modifierValue;
        }
        QLineEdit *pModifierValueTextBox = new QLineEdit(modifierValue);
        mModifierTextBoxesVector.append(pModifierValueTextBox);
        pModifiersGroupBoxGridLayout->addWidget(pModifierLabel, modifiersCount, 0, Qt::AlignRight);
        pModifiersGroupBoxGridLayout->addWidget(pModifierValueTextBox, modifiersCount, 1);
        modifiersCount++;
      }
    }
    if (modifiersCount > 0) {
      // We hide the groupbox when we create it. Show the groupbox now.
      pModifiersGroupBox->show();
      mpParametersTabWidget->addTab(pModifiersParametersScrollArea, QString("Modifiers (%1)").arg(modifiersCount));
    } else {
      mpParametersTabWidget->addTab(pModifiersParametersScrollArea, Modifiers);
    }
  }
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(updateElementParameters()));
  mpOkButton->setDisabled(!mpGraphicsView->getModelWidget()->isElementMode() && (mpGraphicsView->getModelWidget()->getLibraryTreeItem()->isSystemLibrary()
                                                                                 || mpGraphicsView->isVisualizationView()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // main layout
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addWidget(mpParametersHeading);
  pMainLayout->addWidget(mHorizontalLine);
  pMainLayout->addWidget(mpParametersTabWidget);
  pMainLayout->addWidget(mpButtonBox);
  setLayout(pMainLayout);
}

/*!
 * \brief ElementParameters::createTabsGroupBoxesAndParameters
 * \param pModelInstance
 */
void ElementParameters::createTabsGroupBoxesAndParameters(ModelInstance::Model *pModelInstance, bool defaultValue)
{
  foreach (auto pElement, pModelInstance->getElements()) {
    if (pElement->isComponent() || pElement->isShortClassDefinition()) {
      // if we already have the parameter with same name then just skip this one.
      if (findParameter(pElement->getName())) {
        continue;
      }
      /* Ticket #2531
       * Do not show the protected & final parameters.
       * Issue #14750
       * Do not show the outer elements.
       */
      if (!pElement->isPublic() || pElement->isFinal() || pElement->isOuter()) {
        continue;
      }
      /* Ticket #12898
       * Do not show parameter if start and fixed are final.
       */
      ModelInstance::Modifier *pModifier = pElement->getModifier();
      if (pModifier) {
        ModelInstance::Modifier *pStartModifier = pModifier->getModifier("start");
        ModelInstance::Modifier *pFixedModifier = pModifier->getModifier("fixed");
        if (pStartModifier && pStartModifier->isFinal() && pFixedModifier && pFixedModifier->isFinal()) {
          continue;
        }
      }
      auto &dialogAnnotation = pElement->getAnnotation()->getDialogAnnotation();
      // if connectorSizing is present then don't show the parameter
      if (dialogAnnotation.isConnectorSizing()) {
        continue;
      }
      /* Issue #13973
       * if showStart is present and false then don't show the variable.
       * annotation(Dialog(showStartAttribute = false))
       */
      if (!pElement->isParameter() && dialogAnnotation.hasShowStartAttribute() && !dialogAnnotation.getShowStartAttribute()) {
        continue;
      }
      // create the Parameter
      Parameter *pParameter = new Parameter(pElement, defaultValue, this);
      addOrUpdateParametersScrollArea(pParameter);
      mParametersList.append(pParameter);
    } else if (pElement->isExtend() && pElement->getModel()) {
      createTabsGroupBoxesAndParameters(pElement->getModel(), true);
    }
  }
}

/*!
 * \brief ElementParameters::addOrUpdateParametersScrollArea
 * Adds or updates the ParametersScrollArea for the parameter.
 * \param pParameter
 */
void ElementParameters::addOrUpdateParametersScrollArea(Parameter *pParameter)
{
  const QString tab = pParameter->getTab();
  const QString group = pParameter->getGroup();
  ParametersScrollArea *pParametersScrollArea = nullptr;

  if (!mTabsMap.contains(tab)) {
    pParametersScrollArea = new ParametersScrollArea;
    mTabsMap.insert(tab, mpParametersTabWidget->addTab(pParametersScrollArea, tab));
  } else {
    pParametersScrollArea = qobject_cast<ParametersScrollArea*>(mpParametersTabWidget->widget(mTabsMap.value(tab)));
  }

  if (!pParametersScrollArea) {
    return;
  }

  GroupBox *pGroupBox = pParametersScrollArea->getGroupBox(group);
  if (!pGroupBox) {
    pGroupBox = new GroupBox(group);
    pParametersScrollArea->addGroupBox(pGroupBox);
  }
  // set the group image if any
  if (pParameter->hasGroupImage()) {
    pGroupBox->setGroupImage(pParameter->getGroupImage());
  }
}

/*!
 * \brief ElementParameters::fetchElementExtendsModifiers
 * Fetches the Element's extends modifiers and apply modifier values on the appropriate Parameters.
 * \param pModelInstance
 * \param defaultValue
 */
void ElementParameters::fetchElementExtendsModifiers(ModelInstance::Model *pModelInstance, bool defaultValue)
{
  foreach (auto pElement, pModelInstance->getElements()) {
    if (pElement->isExtend() && pElement->getModel()) {
      auto pExtend = dynamic_cast<ModelInstance::Extend*>(pElement);
      /* Issue #10811
       * Go deep in the extends hierarchy and then apply the values in bottom to top order.
       */
      fetchElementExtendsModifiers(pExtend->getModel(), true);
      if (pExtend->getModifier()) {
        foreach (auto *pModifier, pExtend->getModifier()->getModifiers()) {
          Parameter *pParameter = findParameter(pModifier->getName());
          applyFinalStartFixedAndDisplayUnitModifiers(pParameter, pModifier, defaultValue, false);
        }
      }
    }
  }
}

/*!
 * \brief ElementParameters::fetchModifiers
 * Fetches the modifiers and apply modifier values on the appropriate Parameters.
 */
void ElementParameters::fetchModifiers(ModelInstance::Modifier *pModifier)
{
  if (pModifier) {
    foreach (auto *pModifier, pModifier->getModifiers()) {
      Parameter *pParameter = findParameter(pModifier->getName());
      // Pass false for isElementModification. See issue #14196.
      applyFinalStartFixedAndDisplayUnitModifiers(pParameter, pModifier, mInherited || mNested, false);
    }
  }
}

/*!
 * \brief ElementParameters::fetchRootElementModifiers
 * \param pModelElement
 */
void ElementParameters::fetchRootElementModifiers(ModelInstance::Element *pModelElement)
{
  if (pModelElement && pModelElement->isComponent() && pModelElement->getModifier()) {
    QStringList nameList = StringHandler::makeVariableParts(mpElement->getQualifiedName());
    // the first item is element name
    if (!nameList.isEmpty()) {
      nameList.removeFirst();
    }
    ModelInstance::Modifier *pModifier = pModelElement->getModifier();
    foreach (QString name, nameList) {
      pModifier = pModifier->getModifier(name);
      if (!pModifier) {
        return;
      }
    }
    fetchModifiers(pModifier);
  }
}

/*!
 * \brief ElementParameters::fetchClassExtendsModifiers
 * If the Element is inherited then fetch the class extends modifiers and apply modifier values on the appropriate Parameters.
 * \param pModelElement
 */
void ElementParameters::fetchClassExtendsModifiers(ModelInstance::Element *pModelElement)
{
  /* Issue #10864
   * Fetch the class extends modifiers recursively.
   */
  if (pModelElement && pModelElement->getParentModel()) {
    auto pExtend = pModelElement->getParentModel()->getParentElement();
    if (pExtend && pExtend->isExtend()) {
      bool hasParentElement = pExtend->getParentModel() && pExtend->getParentModel()->getParentElement();
      if (pExtend->getModifier()) {
        foreach (auto pModifier, pExtend->getModifier()->getModifiers()) {
          if (pModifier->getName().compare(mpElement->getName()) == 0) {
            foreach (auto *pSubModifier, pModifier->getModifiers()) {
              Parameter *pParameter = findParameter(pSubModifier->getName());
              applyFinalStartFixedAndDisplayUnitModifiers(pParameter, pSubModifier, hasParentElement, true);
            }
            break;
          }
        }
      }
      if (hasParentElement) {
        fetchClassExtendsModifiers(pExtend);
      }
    }
  }
}

/*!
 * \brief ElementParameters::fetchRootClassExtendsModifiers
 * In case of element mode if the root parent ModelInstance::Element is extend and has modifier.
 * Apply modifier values on the appropriate Parameters.
 * \param pModelElement
 */
void ElementParameters::fetchRootClassExtendsModifiers(ModelInstance::Element *pModelElement)
{
  if (pModelElement && pModelElement->isExtend() && pModelElement->getModifier()) {
    QStringList nameList = StringHandler::makeVariableParts(mpElement->getQualifiedName());
    ModelInstance::Modifier *pModifier = pModelElement->getModifier();
    foreach (QString name, nameList) {
      pModifier = pModifier->getModifier(name);
      if (!pModifier) {
        return;
      }
    }

    if (pModifier && pModifier->getName().compare(mpElement->getName()) == 0) {
      foreach (auto *pSubModifier, pModifier->getModifiers()) {
        Parameter *pParameter = findParameter(pSubModifier->getName());
        applyFinalStartFixedAndDisplayUnitModifiers(pParameter, pSubModifier, false, true);
      }
    }
  }
}

/*!
 * \brief ElementParameters::applyModifier
 * Apply the modifier of the component.
 * \param pModifier
 * \param defaultValue
 */
void ElementParameters::applyModifier(ModelInstance::Modifier *pModifier, bool defaultValue)
{
  if (mNested && pModifier) {
    foreach (auto pSubModifier, pModifier->getModifiers()) {
      Parameter *pParameter = findParameter(pSubModifier->getName());
      applyFinalStartFixedAndDisplayUnitModifiers(pParameter, pSubModifier, defaultValue, false);
      // set final and each checkboxes in the menu
      if (pParameter && !pParameter->isShowStartAndFixed()) {
        pParameter->getFinalEachMenu()->setFinal(pSubModifier->isFinal());
        pParameter->getFinalEachMenu()->setEach(pSubModifier->isEach());
        pParameter->getFinalEachMenu()->setBreak(pSubModifier->isBreak());
      }
    }
  }
}

/*!
 * \brief ElementParameters::commentLinkClicked
 * \param link
 */
void ElementParameters::commentLinkClicked(QString link)
{
  QUrl linkUrl(link);
  if (linkUrl.scheme().compare("modelica") == 0) {
    link = link.remove("modelica://");
    LibraryTreeItem *pLibraryTreeItem = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->findLibraryTreeItem(link);
    if (pLibraryTreeItem) {
      MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel()->showModelWidget(pLibraryTreeItem);
    }
  } else {
    QDesktopServices::openUrl(link);
  }
}

typedef struct {
  QString mName;
  QString mExtendName;
  bool mInherited;
  QString mKey;
  QString mValue;
  bool mIsReplaceable;
  bool mFinal;
  bool mEach;
  bool mBreak;
  bool mStartAndFixed;
} ElementModifier;

typedef struct {
  QString mName;
  QString mExtendName;
  bool mInherited;
  QString mValue;
} Modifier;

static int accumulatedSize(const QList<Modifier> &list, int seplen)
{
  int result = 0;
  if (!list.isEmpty()) {
    for (const auto &e : list) {
      result += e.mValue.size() + seplen;
    }
    result -= seplen;
  }
  return result;
}

QString modifiersJoin(const QList<Modifier> &list, const QString &sep)
{
  QString result;
  if (!list.isEmpty()) {
    result.reserve(accumulatedSize(list, sep.size()));
    int len = 0;
    for (const auto &e : list) {
      len++;
      result += e.mValue;
      if (len < list.size()) {
        result += sep;
      }
    }
  }
  return result;
}

/*!
 * \brief ElementParameters::updateElementParameters
 * Slot activated when mpOkButton clicked signal is raised.\n
 * Checks the list of parameters i.e mParametersList and if the value is changed then sets the new value.
 */
void ElementParameters::updateElementParameters()
{
  ModelWidget *pModelWidget = mpGraphicsView->getModelWidget();
  ModelInfo oldModelInfo = pModelWidget->createModelInfo();
  QString className = pModelWidget->isElementMode() ? pModelWidget->getRootLibraryTreeItem()->getNameStructure() : pModelWidget->getLibraryTreeItem()->getNameStructure();
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  bool valueChanged = false;
  QList<ElementModifier> elementModifiersList;
  // any parameter changed
  foreach (Parameter *pParameter, mParametersList) {
    // if parameter is not visible then continue
    if (pParameter->getGroup().isEmpty()) {
      continue;
    }

    QStringList subModifiers;
    // if value is changed
    if (pParameter->isValueModified()) {
      valueChanged = true;
      ElementModifier elementModifier;
      elementModifier.mName = pParameter->getName();
      elementModifier.mExtendName = pParameter->getExtendName();
      elementModifier.mInherited = pParameter->isInherited();
      elementModifier.mKey = pParameter->getName();
      QString elementModifierValue = pParameter->getValue();
      elementModifier.mIsReplaceable = (pParameter->isReplaceableComponent() || pParameter->isReplaceableClass());
      elementModifier.mFinal = pParameter->getFinalEachMenu()->isFinal();
      elementModifier.mEach = pParameter->getFinalEachMenu()->isEach();
      elementModifier.mBreak = pParameter->getFinalEachMenu()->isBreak();
      elementModifier.mStartAndFixed = pParameter->isShowStartAndFixed();
      // if break
      if (elementModifier.mBreak) {
        elementModifierValue = Helper::BREAK;
      } else {
        // convert the value to display unit
        if (!pParameter->getUnit().isEmpty()
            && pParameter->getUnit().compare(pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString()) != 0) {
          bool ok = true;
          qreal elementModifierRealValue = elementModifierValue.toDouble(&ok);
          // if the modifier is a literal constant
          if (ok) {
            OMCInterface::convertUnits_res convertUnit = pOMCProxy->convertUnits(pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString(),
                                                                                 pParameter->getUnit());
            if (convertUnit.unitsCompatible) {
              elementModifierRealValue = Utilities::convertUnit(elementModifierRealValue, convertUnit.offset, convertUnit.scaleFactor);
              elementModifierValue = StringHandler::number(elementModifierRealValue);
            }
          } else { // if expression
            elementModifierValue = Utilities::arrayExpressionUnitConversion(pOMCProxy, elementModifierValue,
                                                                            pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString(),
                                                                            pParameter->getUnit());
          }
        }
      }
      // set start value
      if (pParameter->isShowStartAndFixed()) {
        QString startModifier;
        if (pParameter->getFinalEachMenu()->isVisible()) {
          if (pParameter->getFinalEachMenu()->isEach()) {
            startModifier.append("each ");
          }
          if (pParameter->getFinalEachMenu()->isFinal()) {
            startModifier.append("final ");
          }
          if (elementModifierValue.isEmpty()) {
            subModifiers.append(startModifier.append("start"));
          } else {
            subModifiers.append(startModifier.append("start=" % elementModifierValue));
          }
        }
        // set fixed
        if (pParameter->getFixedFinalEachMenu()->isVisible()) {
          QString fixedModifier;
          if (pParameter->getFixedFinalEachMenu()->isEach()) {
            fixedModifier.append("each ");
          }
          if (pParameter->getFixedFinalEachMenu()->isFinal()) {
            fixedModifier.append("final ");
          }
          if (pParameter->getFixedFinalEachMenu()->isBreak()) {
            subModifiers.append(fixedModifier.append("fixed=" % Helper::BREAK));
          } else if (pParameter->getFixedState().isEmpty()) {
            subModifiers.append(fixedModifier.append("fixed"));
          } else {
            subModifiers.append(fixedModifier.append("fixed=" % pParameter->getFixedState()));
          }
        }
      }
      // set displayUnit
      const QString unit = pParameter->getUnitComboBox()->itemData(pParameter->getUnitComboBox()->currentIndex()).toString();
      QString displayUnitModifier;
      /* Issue #11715 and #11839
       * Add each prefix if element is an array OR parameter is an array.
       */
      if ((hasElement() && isElementArray()) || pParameter->getModelInstanceElement()->getDimensions().isArray()) {
        displayUnitModifier.append("each ");
      }
      if (pParameter->getDisplayUnitFinalEachMenu()->isFinal()) {
        displayUnitModifier.append("final ");
      }
      // if break displayUnit
      if (pParameter->getDisplayUnitFinalEachMenu()->isBreak()) {
        subModifiers.append(displayUnitModifier.append("displayUnit=" % Helper::BREAK));
      } else if (pParameter->getUnitComboBox()->isEnabled() && !unit.isEmpty() && (pParameter->hasDisplayUnit() || pParameter->getDisplayUnit().compare(unit) != 0)) {
        // if displayUnit is changed OR if we already have the displayUnit modifier then set it
        subModifiers.append(displayUnitModifier.append("displayUnit=\"" % unit % "\""));
      }
      // join the submodifiers
      if (!subModifiers.isEmpty()) {
        elementModifier.mKey.append("(" % subModifiers.join(",") % ")");
      }
      if (pParameter->isShowStartAndFixed()) {
        elementModifier.mValue = "";
      } else {
        elementModifier.mValue = elementModifierValue;
      }
      elementModifiersList.append(elementModifier);
    }
  }

  // check if any modifier is modified in the modifiers tab
   for (int i = 0; i < mModifierTextBoxesVector.size(); i++) {
     QLineEdit *pModifierTextBox = mModifierTextBoxesVector.at(i);
     if (pModifierTextBox->isModified()) {
       valueChanged = true;
       break;
     }
   }

  // if valueChanged is true then put the change in the undo stack.
  if (valueChanged || !mpModifiersTextBox->text().isEmpty()) {
    // apply the new Component modifiers if any
    QList<Modifier> modifiersList;
    foreach (ElementModifier elementModifier, elementModifiersList) {
      QString modifierValue = elementModifier.mValue.trimmed();

      if (modifierValue.isEmpty()) {
        modifierValue = elementModifier.mKey;
      } else if (modifierValue.startsWith(QLatin1String("redeclare"))) {
        // keep as-is
      } else if (modifierValue.startsWith("(")) {
        modifierValue = elementModifier.mKey % modifierValue;
      } else {
        modifierValue = elementModifier.mKey % QLatin1String(" = ") % modifierValue;
      }
      // if startandfixed then the final and each are handled with the start value.
      if (!elementModifier.mStartAndFixed) {
        QString modifier;
        // if each
        if (elementModifier.mEach) {
          modifier.append("each ");
        }
        // if final
        if (elementModifier.mFinal) {
          modifier.append("final ");
        }
        // handle redeclare
        if (modifierValue.startsWith(QStringLiteral("redeclare"))) {
          modifierValue.replace("redeclare ", "redeclare " % modifier);
        } else {
          modifierValue.prepend(modifier);
        }
      }

      if (!modifierValue.isEmpty()) {
        Modifier modifier;
        modifier.mName = elementModifier.mName;
        modifier.mExtendName = elementModifier.mExtendName;
        modifier.mInherited = elementModifier.mInherited;
        modifier.mValue = modifierValue;
        modifiersList.append(modifier);
      }
    }

    if (hasElement()) {
      // add custom modifiers added by user. See issue #5105
      if (!mpModifiersTextBox->text().isEmpty()) {
        Modifier modifier;
        modifier.mValue = mpModifiersTextBox->text();
        modifiersList.append(modifier);
      }
      // add modifiers from the Modifiers tab
      for (int i = 0; i < mModifierTextBoxesVector.size(); i++) {
        // only add if value is modified
        QLineEdit *pModifierTextBox = mModifierTextBoxesVector.at(i);
        if (pModifierTextBox->isModified()) {
          Modifier modifier;
          modifier.mName = mModifierLabelsVector.at(i)->text();
          modifier.mValue = modifier.mName % pModifierTextBox->text();
          modifiersList.append(modifier);
        }
      }
    }

    if (mSubDialog) {
      if (modifiersList.isEmpty()) {
        mModification.clear();
      } else {
        mModification = "(" % modifiersJoin(modifiersList, ", ") % ")";
      }
    } else {
      if (hasElement()) {
        QString modifiers = modifiersJoin(modifiersList, ", ");
        if (!modifiers.isEmpty()) {
          // if the element is inherited then add the modifier value into the extends.
          if (mInherited) {
            if (pModelWidget->isElementMode()) {
              ModelInstance::Element *pParentElement = mpElement;
              while (pParentElement) {
                if (pParentElement->isComponent()) {
                  /* Skip adding `each` to this element since it will be added from the dialog if user selects it.
                   * We only automatically add `each` to upper hierarchy elements.
                   * See issue #13126
                   */
                  if (pParentElement != mpElement && pParentElement->getDimensions().isArray()) {
                    modifiers = pParentElement->getName() % "(each " % modifiers % ")";
                  } else {
                    modifiers = pParentElement->getName() % "(" % modifiers % ")";
                  }
                }
                pParentElement = pParentElement->getParentModel() ? pParentElement->getParentModel()->getParentElement() : nullptr;
              }
              pOMCProxy->setExtendsModifierValue(className, mpElement->getTopLevelParentElementName(), "_", modifiers);
            } else {
              pOMCProxy->setExtendsModifierValue(className, mpElement->getTopLevelParentElementName(), mpElement->getQualifiedName(), modifiers);
            }
          } else {
            pOMCProxy->setElementModifierValue(className, mpElement->getQualifiedName(), modifiers);
          }
          if (pModelWidget->isElementMode()) {
            pModelWidget->setComponentModified(true);
          } else {
            ModelInfo newModelInfo = pModelWidget->createModelInfo();
            pModelWidget->getUndoStack()->push(new OMCUndoCommand(pModelWidget->getLibraryTreeItem(), oldModelInfo, newModelInfo,
                                                                  QString("Update Element %1 Parameters").arg(mpElement->getQualifiedName())));
            pModelWidget->updateModelText();
          }
        }
      } else {
        for (const auto &modifier : modifiersList) {
          const QString name = modifier.mName;
          QString value = modifier.mValue;
          if (modifier.mInherited) {
            pOMCProxy->setExtendsModifierValue(className, modifier.mExtendName, "_", value);
          } else {
            if (value.startsWith(name)) {
              value.remove(0, name.size());
            }
            pOMCProxy->setElementModifierValue(className, name, value);
          }
        }

        if (!modifiersList.isEmpty()) {
          ModelInfo newModelInfo = pModelWidget->createModelInfo();
          pModelWidget->getUndoStack()->push(new OMCUndoCommand(pModelWidget->getLibraryTreeItem(), oldModelInfo, newModelInfo,
                                                                QString("Update %1 Parameters").arg(mpGraphicsView->getModelWidget()->getLibraryTreeItem()->getNameStructure())));
          pModelWidget->updateModelText();
        }
      }
    }
  }
  /* Skip the focus out event when we are closing the dialog.
   * Otherwise it will call valueTextBoxChanged which tries to use the delete model instance.
   */
  mSkipFocusOutEvent = true;
  accept();
}

/*!
 * \brief ElementParameters::reject
 * Reimplementation of QDialog::reject()
 */
void ElementParameters::reject()
{
  foreach (Parameter *pParameter, mParametersList) {
    // reset any changed parameter binding
    if (pParameter->isValueModified()) {
      pParameter->getModelInstanceElement()->resetBinding();
    }
  }
  mSkipFocusOutEvent = true;
  QDialog::reject();
}

/*!
 * \class ElementAttributes
 * \brief A dialog for displaying elements attributes like visibility, stream, casuality etc.
 */
/*!
 * \brief ElementAttributes::ElementAttributes
 * \param pElement
 * \param pParent
 */
ElementAttributes::ElementAttributes(Element *pElement, QWidget *pParent)
  : QDialog(pParent)
{
  QString className = pElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure();
  setWindowTitle(tr("%1 - %2 - %3 in %4").arg(Helper::applicationName, tr("Element Attributes"), pElement->getName(), className));
  setAttribute(Qt::WA_DeleteOnClose);
  mpElement = pElement;
  setUpDialog();
  initializeDialog();
}

/*!
 * \brief ElementAttributes::setUpDialog
 * Creates the Dialog and set up all the controls with default values.
 */
void ElementAttributes::setUpDialog()
{
  // heading label
  mpAttributesHeading = Utilities::getHeadingLabel(Helper::attributes);
  // set separator line
  mHorizontalLine = Utilities::getHeadingLine();
  // create Type Group Box
  mpTypeGroupBox = new QGroupBox(Helper::type);
  QGridLayout *pTypeGroupBoxLayout = new QGridLayout;
  mpNameLabel = new Label(Helper::name);
  mpNameTextBox = new QLineEdit;
  // dimensions
  mpDimensionsLabel = new Label(tr("Dimensions:"));
  mpDimensionsTextBox = new QLineEdit;
  mpDimensionsTextBox->setToolTip(tr("Array of dimensions e.g [1, 5, 2]"));
  mpCommentLabel = new Label(Helper::comment);
  mpCommentTextBox = new QLineEdit;
  mpPathLabel = new Label(Helper::path);
  mpPathTextBox = new Label;
  pTypeGroupBoxLayout->addWidget(mpNameLabel, 0, 0);
  pTypeGroupBoxLayout->addWidget(mpNameTextBox, 0, 1);
  pTypeGroupBoxLayout->addWidget(mpDimensionsLabel, 1, 0);
  pTypeGroupBoxLayout->addWidget(mpDimensionsTextBox, 1, 1);
  pTypeGroupBoxLayout->addWidget(mpCommentLabel, 2, 0);
  pTypeGroupBoxLayout->addWidget(mpCommentTextBox, 2, 1);
  pTypeGroupBoxLayout->addWidget(mpPathLabel, 3, 0);
  pTypeGroupBoxLayout->addWidget(mpPathTextBox, 3, 1);
  mpTypeGroupBox->setLayout(pTypeGroupBoxLayout);
  // create Variablity Group Box
  mpVariabilityGroupBox = new QGroupBox("Variability");
  mpConstantRadio = new QRadioButton("Constant");
  mpParameterRadio = new QRadioButton("Parameter");
  mpDiscreteRadio = new QRadioButton("Discrete");
  mpDefaultRadio = new QRadioButton("Unspecified (Default)");
  QVBoxLayout *pVariabilityGroupBoxLayout = new QVBoxLayout;
  pVariabilityGroupBoxLayout->addWidget(mpConstantRadio);
  pVariabilityGroupBoxLayout->addWidget(mpParameterRadio);
  pVariabilityGroupBoxLayout->addWidget(mpDiscreteRadio);
  pVariabilityGroupBoxLayout->addWidget(mpDefaultRadio);
  mpVariabilityButtonGroup = new QButtonGroup(this);
  mpVariabilityButtonGroup->addButton(mpConstantRadio);
  mpVariabilityButtonGroup->addButton(mpParameterRadio);
  mpVariabilityButtonGroup->addButton(mpDiscreteRadio);
  mpVariabilityButtonGroup->addButton(mpDefaultRadio);
  mpVariabilityGroupBox->setLayout(pVariabilityGroupBoxLayout);
  // create Variablity Group Box
  mpPropertiesGroupBox = new QGroupBox("Properties");
  mpFinalCheckBox = new QCheckBox("Final");
  mpProtectedCheckBox = new QCheckBox("Protected");
  mpReplaceAbleCheckBox = new QCheckBox("Replaceable");
  QVBoxLayout *pPropertiesGroupBoxLayout = new QVBoxLayout;
  pPropertiesGroupBoxLayout->addWidget(mpFinalCheckBox);
  pPropertiesGroupBoxLayout->addWidget(mpProtectedCheckBox);
  pPropertiesGroupBoxLayout->addWidget(mpReplaceAbleCheckBox);
  mpPropertiesGroupBox->setLayout(pPropertiesGroupBoxLayout);
  // create Variablity Group Box
  mpCausalityGroupBox = new QGroupBox("Causality");
  mpInputRadio = new QRadioButton("Input");
  mpOutputRadio = new QRadioButton("Output");
  mpNoneRadio = new QRadioButton("None");
  QVBoxLayout *pCausalityGroupBoxLayout = new QVBoxLayout;
  pCausalityGroupBoxLayout->addWidget(mpInputRadio);
  pCausalityGroupBoxLayout->addWidget(mpOutputRadio);
  pCausalityGroupBoxLayout->addWidget(mpNoneRadio);
  mpCausalityButtonGroup = new QButtonGroup(this);
  mpCausalityButtonGroup->addButton(mpInputRadio);
  mpCausalityButtonGroup->addButton(mpOutputRadio);
  mpCausalityButtonGroup->addButton(mpNoneRadio);
  mpCausalityGroupBox->setLayout(pCausalityGroupBoxLayout);
  // create Variablity Group Box
  mpInnerOuterGroupBox = new QGroupBox("Inner/Outer");
  mpInnerCheckBox = new QCheckBox("Inner");
  mpOuterCheckBox = new QCheckBox("Outer");
  QVBoxLayout *pInnerOuterGroupBoxLayout = new QVBoxLayout;
  pInnerOuterGroupBoxLayout->addWidget(mpInnerCheckBox);
  pInnerOuterGroupBoxLayout->addWidget(mpOuterCheckBox);
  mpInnerOuterGroupBox->setLayout(pInnerOuterGroupBoxLayout);
  // create Conditional Group Box
  mpConditionGroupBox = new QGroupBox(tr("Conditional Component"));
  mpConditionGroupBox->setCheckable(true);
  mpConditionGroupBox->setChecked(false);
  mpConditionTextBox = new QLineEdit;
  mpConditionTextBox->setPlaceholderText(tr("Boolean expression e.g. useSensor"));
  mpConditionTextBox->setToolTip(tr("Boolean expression e.g. useSensor"));
  mpConditionTextBox->setEnabled(false);
  connect(mpConditionGroupBox, &QGroupBox::toggled, mpConditionTextBox, &QLineEdit::setEnabled);
  QHBoxLayout *pConditionGroupBoxLayout = new QHBoxLayout;
  pConditionGroupBoxLayout->addWidget(new Label("if"));
  pConditionGroupBoxLayout->addWidget(mpConditionTextBox);
  mpConditionGroupBox->setLayout(pConditionGroupBoxLayout);
  // Create the buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), this, SLOT(updateElementAttributes()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), this, SLOT(reject()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  if (mpElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->isSystemLibrary() || mpElement->isInheritedElement()) {
    mpOkButton->setDisabled(true);
  }
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // Create a layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpAttributesHeading, 0, 0, 1, 2);
  pMainLayout->addWidget(mHorizontalLine, 1, 0, 1, 2);
  pMainLayout->addWidget(mpTypeGroupBox, 2, 0, 1, 2);
  pMainLayout->addWidget(mpVariabilityGroupBox, 3, 0);
  pMainLayout->addWidget(mpPropertiesGroupBox, 3, 1);
  pMainLayout->addWidget(mpCausalityGroupBox, 4, 0);
  pMainLayout->addWidget(mpInnerOuterGroupBox, 4, 1);
  pMainLayout->addWidget(mpConditionGroupBox, 5, 0, 1, 2);
  pMainLayout->addWidget(mpButtonBox, 6, 0, 1, 2);
  setLayout(pMainLayout);
}

/*!
 * \brief ElementAttributes::initializeDialog
 * Initialize the fields with default values.
 */
void ElementAttributes::initializeDialog()
{
  // get Class Name
  mpNameTextBox->setText(mpElement->getModelComponent()->getName());
  mpNameTextBox->setCursorPosition(0);
  // get dimensions
  QString dimensions = mpElement->getModelComponent()->getDimensions().getAbsynDimensionsString();
  mpDimensionsTextBox->setText(QString("[%1]").arg(dimensions));
  // get Comment
  mpCommentTextBox->setText(mpElement->getModelComponent()->getComment());
  mpCommentTextBox->setCursorPosition(0);
  // get classname
  mpPathTextBox->setText(mpElement->getModelComponent()->getType());
  // get Variability
  const QString variability = mpElement->getModelComponent()->getVariability();
  if (variability.compare(QStringLiteral("constant")) == 0) {
    mpConstantRadio->setChecked(true);
  } else if (variability.compare(QStringLiteral("parameter")) == 0) {
    mpParameterRadio->setChecked(true);
  } else if (variability.compare(QStringLiteral("discrete")) == 0) {
    mpDiscreteRadio->setChecked(true);
  } else {
    mpDefaultRadio->setChecked(true);
  }
  // get Properties
  mpFinalCheckBox->setChecked(mpElement->getModelComponent()->isFinal());
  mpProtectedCheckBox->setChecked(!mpElement->getModelComponent()->isPublic());
  mpReplaceAbleCheckBox->setChecked(mpElement->getModelComponent()->getReplaceable());
  // get Casuality
  const QString direction = mpElement->getModelComponent()->getDirectionPrefix();
  if (direction.compare(QStringLiteral("input")) == 0) {
    mpInputRadio->setChecked(true);
  } else if (direction.compare(QStringLiteral("output")) == 0) {
    mpOutputRadio->setChecked(true);
  } else {
    mpNoneRadio->setChecked(true);
  }
  // get InnerOuter
  mpInnerCheckBox->setChecked(mpElement->getModelComponent()->isInner());
  mpOuterCheckBox->setChecked(mpElement->getModelComponent()->isOuter());
  // get Conditional
  mOldCondition = MainWindow::instance()->getOMCProxy()->getComponentCondition(mpElement->getGraphicsView()->getModelWidget()->getLibraryTreeItem()->getNameStructure(), mpElement->getName()).trimmed();
  if (!mOldCondition.isEmpty()) {
    mpConditionGroupBox->setChecked(true);
    mpConditionTextBox->setText(mOldCondition);
    mpConditionTextBox->setCursorPosition(0);
  }
}

/*!
 * \brief ElementAttributes::updateElementAttributes
 * Slot activated when mpOkButton clicked signal is raised.\n
 * Updates the element attributes.
 */
void ElementAttributes::updateElementAttributes()
{
  ModelWidget *pModelWidget = mpElement->getGraphicsView()->getModelWidget();
  /* Check the same element name problem before setting any attributes. */
  if (mpElement->getName().compare(mpNameTextBox->text()) != 0) {
    if (!mpElement->getGraphicsView()->checkElementName(mpElement->getClassName(), mpNameTextBox->text())) {
      QMessageBox::information(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::information),
                               GUIMessages::getMessage(GUIMessages::SAME_COMPONENT_NAME).arg(mpNameTextBox->text()), QMessageBox::Ok);
      return;
    }
  }
  // check for comma
  if (StringHandler::nameContainsComma(mpNameTextBox->text())) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::INVALID_INSTANCE_NAME).arg(mpNameTextBox->text()), QMessageBox::Ok);
    return;
  }
  // check for invalid names
  MainWindow::instance()->getOMCProxy()->setLoggingEnabled(false);
  QList<QString> result = MainWindow::instance()->getOMCProxy()->parseString(QString("model M N %1; end M;").arg(mpNameTextBox->text()), "M", false);
  MainWindow::instance()->getOMCProxy()->setLoggingEnabled(true);
  if (result.isEmpty()) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::INVALID_INSTANCE_NAME).arg(mpNameTextBox->text()), QMessageBox::Ok);
    return;
  }
  // check the condition expression
  QString condition;
  if (mpConditionGroupBox->isChecked()) {
    condition = mpConditionTextBox->text().trimmed();
    if (condition.isEmpty()) {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            tr("A conditional component requires a condition expression."), QMessageBox::Ok);
      mpConditionTextBox->setFocus();
      return;
    }
    MainWindow::instance()->getOMCProxy()->setLoggingEnabled(false);
    QList<QString> conditionResult = MainWindow::instance()->getOMCProxy()->parseString(QString("model M Boolean b if %1; end M;").arg(condition), "M", false);
    MainWindow::instance()->getOMCProxy()->setLoggingEnabled(true);
    if (conditionResult.isEmpty()) {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                            tr("Invalid condition expression: %1").arg(condition), QMessageBox::Ok);
      mpConditionTextBox->setFocus();
      return;
    }
  }
  QString variability;
  if (mpConstantRadio->isChecked()) {
    variability = "constant";
  } else if (mpParameterRadio->isChecked()) {
    variability = "parameter";
  } else if (mpDiscreteRadio->isChecked()) {
    variability = "discrete";
  } else {
    variability = "";
  }
  QString causality;
  if (mpInputRadio->isChecked()) {
    causality = "input";
  } else if (mpOutputRadio->isChecked()) {
    causality = "output";
  } else {
    causality = "";
  }
  ModelInfo oldModelInfo = pModelWidget->createModelInfo();
  OMCProxy *pOMCProxy = MainWindow::instance()->getOMCProxy();
  QString modelName = pModelWidget->getLibraryTreeItem()->getNameStructure();
  bool attributesChanged = false;
  attributesChanged |= mpElement->getModelComponent()->isFinal() != mpFinalCheckBox->isChecked();
  attributesChanged |= !mpElement->getModelComponent()->isPublic() != mpProtectedCheckBox->isChecked();
  attributesChanged |= mpElement->getModelComponent()->getReplaceable() ? true : false != mpReplaceAbleCheckBox->isChecked();
  attributesChanged |= mpElement->getModelComponent()->getVariability().compare(variability) != 0;
  attributesChanged |= mpElement->getModelComponent()->isInner() != mpInnerCheckBox->isChecked();
  attributesChanged |= mpElement->getModelComponent()->isOuter() != mpOuterCheckBox->isChecked();
  attributesChanged |= mpElement->getModelComponent()->getDirectionPrefix().compare(causality) != 0;
  attributesChanged |= mOldCondition.compare(condition) != 0;

  QString isFinal = mpFinalCheckBox->isChecked() ? "true" : "false";
  QString flow = (mpElement->getModelComponent()->getConnector().compare(QStringLiteral("flow")) == 0) ? "true" : "false";
  QString isProtected = mpProtectedCheckBox->isChecked() ? "true" : "false";
  QString isReplaceAble = mpReplaceAbleCheckBox->isChecked() ? "true" : "false";
  QString isInner = mpInnerCheckBox->isChecked() ? "true" : "false";
  QString isOuter = mpOuterCheckBox->isChecked() ? "true" : "false";

  // update element attributes if needed
  if (attributesChanged) {
    if (!pOMCProxy->setComponentProperties(modelName, mpElement->getName(), isFinal, flow, isProtected, isReplaceAble, variability, isInner, isOuter, causality)) {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), QMessageBox::Ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }

  // update the element comment only if its changed.
  if (mpElement->getModelComponent()->getComment().compare(mpCommentTextBox->text()) != 0) {
    QString comment = StringHandler::escapeString(mpCommentTextBox->text());
    if (pOMCProxy->setComponentComment(modelName, mpElement->getName(), comment)) {
      attributesChanged = true;
    } else {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), QMessageBox::Ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
  // update the element condition only if its changed.
  if (mOldCondition.compare(condition) != 0) {
    if (pOMCProxy->setComponentCondition(modelName, mpElement->getName(), StringHandler::escapeString(condition))) {
      attributesChanged = true;
    } else {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), QMessageBox::Ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
  // update the element dimensions
  const QString dimensions = StringHandler::removeFirstLastSquareBrackets(mpDimensionsTextBox->text());
  if (mpElement->getModelComponent()->getDimensions().getAbsynDimensionsString().compare(dimensions) != 0) {
    const QString arrayIndex = QString("{%1}").arg(dimensions);
    if (pOMCProxy->setComponentDimensions(modelName, mpElement->getName(), arrayIndex)) {
      attributesChanged = true;
    } else {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), QMessageBox::Ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
  // update the element name only if its changed.
  if (mpElement->getName().compare(mpNameTextBox->text()) != 0) {
    // if renameComponentInClass command is successful update the element with new name
    if (pOMCProxy->renameComponentInClass(modelName, mpElement->getName(), mpNameTextBox->text())) {
      attributesChanged = true;
    } else {
      QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error), pOMCProxy->getResult(), QMessageBox::Ok);
      pOMCProxy->printMessagesStringInternal();
    }
  }
  // push the attributes updated change to the stack
  if (attributesChanged) {
    ModelInfo newModelInfo = pModelWidget->createModelInfo();
    pModelWidget->getUndoStack()->push(new OMCUndoCommand(pModelWidget->getLibraryTreeItem(), oldModelInfo, newModelInfo, QString("Update Element %1 Attributes").arg(mpElement->getName())));
    pModelWidget->updateModelText();
  }
  accept();
}
