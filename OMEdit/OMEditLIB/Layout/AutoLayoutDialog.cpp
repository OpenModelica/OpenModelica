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
 * @author John Tinnerholm
 */

#include "AutoLayoutDialog.h"
#include "AutoLayout.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Util/Helper.h"
#include "Util/Utilities.h"
#include "Util/StringHandler.h"
#include "Modeling/MessagesWidget.h"

#include <QApplication>
#include <QHash>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGridLayout>
#include <QMessageBox>

namespace {
const char *keyPrefix = "autoLayout/";
// What one level of undo needs: the text of the class before the layout, OMC's listing of it after (to see whether
// the class was edited since), whether the class and its file were saved before the layout, and the file on disk
// then (to see whether it was saved since).
struct UndoEntry {
  QString before;
  QString after;
  bool itemSaved;
  bool fileSaved;
  QByteArray fileText;
};
QHash<QString, UndoEntry> undoEntries;

QByteArray readFile(const QString &fileName)
{
  QFile file(fileName);
  return file.open(QIODevice::ReadOnly) ? file.readAll() : QByteArray();
}

/*!
 * \brief startsWithWithin
 * True when the Modelica text starts with a within clause, after white space and comments.
 */
bool startsWithWithin(const QString &text)
{
  int i = 0;
  while (i < text.size()) {
    if (text.at(i).isSpace()) {
      i++;
    } else if (text.mid(i, 2) == "//") {
      const int end = text.indexOf('\n', i);
      i = end < 0 ? text.size() : end + 1;
    } else if (text.mid(i, 2) == "/*") {
      const int end = text.indexOf("*/", i + 2);
      i = end < 0 ? text.size() : end + 2;
    } else {
      break;
    }
  }
  return text.mid(i, 6) == "within" && (i + 6 == text.size() || !(text.at(i + 6).isLetterOrNumber() || text.at(i + 6) == '_'));
}

/*!
 * \brief validate
 * Takes over what the user typed in the text view of the class, as every other action does first. False when that
 * text has errors.
 */
bool validate(LibraryTreeItem **ppLibraryTreeItem, QString *pMessage)
{
  ModelWidget *pModelWidget = (*ppLibraryTreeItem)->getModelWidget();
  if (pModelWidget && !pModelWidget->validateText(ppLibraryTreeItem)) {
    *pMessage = QCoreApplication::translate("AutoLayoutDialog", "The text of %1 has errors. Correct it first.").arg((*ppLibraryTreeItem)->getNameStructure());
    return false;
  }
  return true;
}
}

/*!
 * \class AutoLayoutDialog
 * \brief Gives the components of a Modelica class a placement and its connections a line (mocoal).
 */
/*!
 * \brief AutoLayoutDialog::AutoLayoutDialog
 * \param pLibraryTreeItem the class to lay out
 * \param pParent
 */
AutoLayoutDialog::AutoLayoutDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent)
  : QDialog(pParent), mpLibraryTreeItem(pLibraryTreeItem)
{
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("Auto Layout")));
  setAttribute(Qt::WA_DeleteOnClose);
  setMinimumWidth(520);
  QSettings *pSettings = Utilities::getApplicationSettings();
  auto saved = [pSettings](const QString &name, const QVariant &fallback) {
    return pSettings->value(QString(keyPrefix) + name, fallback);
  };
  mpHeading = Utilities::getHeadingLabel(tr("Auto Layout"));
  mpHorizontalLine = Utilities::getHeadingLine();
  mpClassLabel = new Label(tr("Class:"));
  mpClassNameLabel = new Label(pLibraryTreeItem->getNameStructure());
  mpLayoutLabel = new Label(tr("Placement:"));
  mpLayoutComboBox = new QComboBox;
  mpLayoutComboBox->addItem(tr("Layered (signal flow)"), "layered");
  mpLayoutComboBox->addItem(tr("Spring"), "spring");
  mpLayoutComboBox->addItem(tr("Grid"), "grid");
  mpLayoutComboBox->setCurrentIndex(qMax(0, mpLayoutComboBox->findData(saved("layout", "layered"))));
  mpRouteLabel = new Label(tr("Connection lines:"));
  mpRouteComboBox = new QComboBox;
  mpRouteComboBox->addItem(tr("Orthogonal"), "orthogonal");
  mpRouteComboBox->addItem(tr("Straight"), "straight");
  mpRouteComboBox->addItem(tr("Bezier"), "bezier");
  mpRouteComboBox->addItem(tr("None"), "none");
  mpRouteComboBox->setCurrentIndex(qMax(0, mpRouteComboBox->findData(saved("route", "orthogonal"))));
  mpDirectionLabel = new Label(tr("Signal flow:"));
  mpDirectionComboBox = new QComboBox;
  mpDirectionComboBox->addItem(tr("Left to right"), "right");
  mpDirectionComboBox->addItem(tr("Top to bottom"), "down");
  mpDirectionComboBox->setCurrentIndex(qMax(0, mpDirectionComboBox->findData(saved("direction", "right"))));
  mpSpacingLabel = new Label(tr("Space between components (x, y):"));
  mpDxSpinBox = new QDoubleSpinBox;
  mpDxSpinBox->setRange(0, 500);
  mpDxSpinBox->setValue(saved("dx", 30.0).toDouble());
  mpDySpinBox = new QDoubleSpinBox;
  mpDySpinBox->setRange(0, 500);
  mpDySpinBox->setValue(saved("dy", 20.0).toDouble());
  mpScaleLabel = new Label(tr("Size factor of components without a size:"));
  mpScaleSpinBox = new QDoubleSpinBox;
  mpScaleSpinBox->setRange(0.1, 10);
  mpScaleSpinBox->setSingleStep(0.1);
  mpScaleSpinBox->setValue(saved("scale", 1.0).toDouble());
  mpKeepCheckBox = new QCheckBox(tr("Keep existing placements and lines, add what is missing"));
  mpKeepCheckBox->setChecked(saved("keep", false).toBool());
  mpRotateCheckBox = new QCheckBox(tr("Turn two-pin components along the connections"));
  mpRotateCheckBox->setChecked(saved("rotate", true).toBool());
  mpGraphicsLabel = new Label(tr("Shapes of the diagram (frames, texts):"));
  mpGraphicsComboBox = new QComboBox;
  mpGraphicsComboBox->addItem(tr("Move with the components"), "move");
  mpGraphicsComboBox->addItem(tr("Keep"), "keep");
  mpGraphicsComboBox->addItem(tr("Remove"), "drop");
  mpGraphicsComboBox->setCurrentIndex(qMax(0, mpGraphicsComboBox->findData(saved("graphics", "move"))));
  mpStackLabel = new Label(tr("Stack of the layout:"));
  mpStackSpinBox = new QSpinBox;
  mpStackSpinBox->setRange(1, 65536);
  mpStackSpinBox->setSuffix(" MB");
  mpStackSpinBox->setValue(saved("stackMB", 256).toInt());
  mpStackSpinBox->setToolTip(tr("A level of nesting in the model (parentheses, packages) takes about 3 KB; 256 MB is about 80000 levels."));
  mpProgramLabel = new Label(tr("Layout program (mocoal):"));
  // Empty: the program is found each time (MOCOAL, beside OMEdit, OPENMODELICAHOME/bin, PATH)
  mpProgramTextBox = new QLineEdit(AutoLayout::savedProgram());
  const QString foundProgram = AutoLayout::findProgram();
  mpProgramTextBox->setPlaceholderText(foundProgram.isEmpty() ? tr("MOCOAL, or mocoal beside OMEdit, in OPENMODELICAHOME/bin or on the PATH")
                                                              : tr("Found: %1").arg(foundProgram));
  mpBrowseProgramButton = new QPushButton(Helper::browse);
  connect(mpBrowseProgramButton, SIGNAL(clicked()), SLOT(browseProgram()));
  mpLayoutButton = new QPushButton(tr("Lay Out"));
  mpLayoutButton->setAutoDefault(true);
  connect(mpLayoutButton, SIGNAL(clicked()), SLOT(autoLayout()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpHeading, 0, 0, 1, 4);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0, 1, 4);
  pMainLayout->addWidget(mpClassLabel, 2, 0);
  pMainLayout->addWidget(mpClassNameLabel, 2, 1, 1, 3);
  pMainLayout->addWidget(mpLayoutLabel, 3, 0);
  pMainLayout->addWidget(mpLayoutComboBox, 3, 1, 1, 3);
  pMainLayout->addWidget(mpRouteLabel, 4, 0);
  pMainLayout->addWidget(mpRouteComboBox, 4, 1, 1, 3);
  pMainLayout->addWidget(mpDirectionLabel, 5, 0);
  pMainLayout->addWidget(mpDirectionComboBox, 5, 1, 1, 3);
  pMainLayout->addWidget(mpSpacingLabel, 6, 0);
  pMainLayout->addWidget(mpDxSpinBox, 6, 1);
  pMainLayout->addWidget(mpDySpinBox, 6, 2);
  pMainLayout->addWidget(mpScaleLabel, 7, 0);
  pMainLayout->addWidget(mpScaleSpinBox, 7, 1);
  pMainLayout->addWidget(mpKeepCheckBox, 8, 0, 1, 4);
  pMainLayout->addWidget(mpRotateCheckBox, 9, 0, 1, 4);
  pMainLayout->addWidget(mpGraphicsLabel, 10, 0);
  pMainLayout->addWidget(mpGraphicsComboBox, 10, 1, 1, 3);
  pMainLayout->addWidget(mpStackLabel, 11, 0);
  pMainLayout->addWidget(mpStackSpinBox, 11, 1);
  pMainLayout->addWidget(mpProgramLabel, 12, 0);
  pMainLayout->addWidget(mpProgramTextBox, 12, 1, 1, 2);
  pMainLayout->addWidget(mpBrowseProgramButton, 12, 3);
  QHBoxLayout *pButtons = new QHBoxLayout;
  pButtons->addStretch();
  pButtons->addWidget(mpLayoutButton);
  pButtons->addWidget(mpCancelButton);
  pMainLayout->addLayout(pButtons, 13, 0, 1, 4);
  setLayout(pMainLayout);
}

void AutoLayoutDialog::browseProgram()
{
  QString fileName = StringHandler::getOpenFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), NULL, "", NULL);
  if (!fileName.isEmpty()) {
    mpProgramTextBox->setText(fileName);
  }
}

/*!
 * \brief AutoLayoutDialog::apply
 * Lays out the class: the text of its file goes through mocoal (a child process), the new text of the class is loaded the way an
 * edit in the text view is, and the class is marked as changed (not saved).
 * \param pLibraryTreeItem the class (options.className is set from it)
 * \param options
 * \param pMessage the warnings of the layout, or what went wrong
 * \return false when the class could not be laid out
 */
bool AutoLayoutDialog::apply(LibraryTreeItem *pLibraryTreeItem, const AutoLayout::Options &optionsIn, QString *pMessage)
{
  MainWindow *pMainWindow = MainWindow::instance();
  LibraryTreeModel *pLibraryTreeModel = pMainWindow->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pItem = pLibraryTreeItem;
  if (AutoLayout::isRunning()) {
    *pMessage = tr("Another auto layout is running.");
    return false;
  }
  if (!validate(&pItem, pMessage)) {
    return false;
  }
  const QString className = pItem->getNameStructure();
  LibraryTreeItem *pTopLevel = pLibraryTreeModel->findLibraryTreeItem(StringHandler::getFirstWordBeforeDot(className));
  if (pTopLevel && (pTopLevel->isSystemLibrary() || pTopLevel->isReadOnly())) {
    *pMessage = tr("%1 is in a system library or read-only package and cannot be changed.").arg(className);
    return false;
  }
  AutoLayout::Options options = optionsIn;
  options.className = className;
  // the libraries OMC searches: the classes the model uses are looked up there
  const QStringList modelicaPath = pMainWindow->getOMCProxy()->getModelicaPath().split(QDir::listSeparator(), Qt::SkipEmptyParts);
  for (const QString &directory : modelicaPath) {
    if (QFileInfo(directory).isDir()) {
      options.libraries << QDir::fromNativeSeparators(directory);
    }
  }
  // The text of the file, with the class in it; the layout changes only the class (and the classes in it).
  // getClassText() first: it reads the text before and after the class of a class in a package in one file
  const QString classText = pItem->getClassText(pLibraryTreeModel);
  const bool oneFile = pItem->isInPackageOneFile();
  const QString before = oneFile ? pItem->getClassTextBefore() : QString();
  const QString after = oneFile ? pItem->getClassTextAfter() : QString();
  QString newClassText;
  QString message;
  QApplication::setOverrideCursor(Qt::WaitCursor);
  // A class that is not saved yet has a name, not a file: mocoal must not look for libraries next to it.
  const QString fileName = pItem->isFilePathValid() ? pItem->getFileName() : QString();
  bool ok = AutoLayout::layoutClass(before, classText, after, fileName, options, &newClassText, &message);
  QApplication::restoreOverrideCursor();
  if (!ok) {
    *pMessage = tr("Unable to lay out %1:\n%2").arg(className, message);
    return false;
  }
  for (const QString &line : message.split('\n', Qt::SkipEmptyParts)) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, line, Helper::scriptingKind, Helper::warningLevel));
  }
  if (newClassText == classText) {
    *pMessage = tr("Auto layout of %1: no change.").arg(className);
    return true;
  }
  const bool itemSaved = pItem->isSaved();
  LibraryTreeItem *pFileItem = pLibraryTreeModel->getContainingFileParentLibraryTreeItem(pItem);
  const bool fileSaved = pFileItem->isSaved();
  const QByteArray fileText = fileSaved && pFileItem->isFilePathValid() ? readFile(pFileItem->getFileName()) : QByteArray();
  if (!loadClassText(pItem, newClassText, pMessage)) {
    return false;
  }
  undoEntries[className] = {classText, pMainWindow->getOMCProxy()->list(className), itemSaved, fileSaved, fileText};
  updateUndoAction();
  *pMessage = tr("Auto layout of %1 done. Save the class to keep it, or use File > Format > Undo Auto Layout.").arg(className);
  return true;
}

/*!
 * \brief AutoLayoutDialog::loadClassText
 * Loads `text` as the new text of the class, the way an edit in the text view is: the class is marked as not saved.
 */
bool AutoLayoutDialog::loadClassText(LibraryTreeItem *pLibraryTreeItem, const QString &text, QString *pMessage)
{
  MainWindow *pMainWindow = MainWindow::instance();
  LibraryTreeModel *pLibraryTreeModel = pMainWindow->getLibraryWidget()->getLibraryTreeModel();
  const QString className = pLibraryTreeItem->getNameStructure();
  QStringList parts = StringHandler::splitPath(className);
  parts.removeLast();
  QString within;
  if (!parts.isEmpty() && !startsWithWithin(text)) {
    within = "within " + parts.join('.') + ";\n";
  }
  LibraryTreeItem *pParent = pLibraryTreeItem->isInPackageOneFile() ? pLibraryTreeItem->parent() : pLibraryTreeItem;
  if (!pMainWindow->getOMCProxy()->loadString(within + text, pParent->getFileName(), Helper::utf8, pParent->isSaveFolderStructure())) {
    *pMessage = tr("Unable to load the new text of %1.").arg(className);
    return false;
  }
  ModelWidget *pModelWidget = pLibraryTreeItem->getModelWidget();
  if (pModelWidget) {
    pModelWidget->reDrawModelWidget();
  }
  pLibraryTreeModel->updateLibraryTreeItemClassText(pLibraryTreeItem);
  return true;
}

/*!
 * \brief AutoLayoutDialog::canUndo
 * True when the last auto layout of the class can be undone.
 */
bool AutoLayoutDialog::canUndo(LibraryTreeItem *pLibraryTreeItem)
{
  return pLibraryTreeItem && undoEntries.contains(pLibraryTreeItem->getNameStructure());
}

/*!
 * \brief AutoLayoutDialog::changedSinceLayout
 * True when the text of the class is not the one the auto layout left: the class was edited since.
 */
bool AutoLayoutDialog::changedSinceLayout(LibraryTreeItem *pLibraryTreeItem)
{
  if (!canUndo(pLibraryTreeItem)) {
    return false;
  }
  // OMC's listing of the class, which every change of the class (text or diagram) goes through
  return MainWindow::instance()->getOMCProxy()->list(pLibraryTreeItem->getNameStructure())
         != undoEntries.value(pLibraryTreeItem->getNameStructure()).after;
}

/*!
 * \brief AutoLayoutDialog::undo
 * Puts the text the class had before the last auto layout back. When the class was saved before the layout, it is
 * saved again afterwards (the file is that text). Edits made since the layout are lost: without `force`, the undo
 * is refused then.
 */
bool AutoLayoutDialog::undo(LibraryTreeItem *pLibraryTreeItem, bool force, QString *pMessage)
{
  if (AutoLayout::isRunning()) {
    *pMessage = tr("An auto layout is running.");
    return false;
  }
  if (!validate(&pLibraryTreeItem, pMessage)) {
    return false;
  }
  const QString className = pLibraryTreeItem->getNameStructure();
  if (!canUndo(pLibraryTreeItem)) {
    *pMessage = tr("There is no auto layout of %1 to undo.").arg(className);
    return false;
  }
  if (!force && changedSinceLayout(pLibraryTreeItem)) {
    *pMessage = tr("%1 was changed after the auto layout. Undo with force to discard those changes too.").arg(className);
    return false;
  }
  const UndoEntry entry = undoEntries.value(className);
  if (!loadClassText(pLibraryTreeItem, entry.before, pMessage)) {
    return false;
  }
  LibraryTreeModel *pLibraryTreeModel = MainWindow::instance()->getLibraryWidget()->getLibraryTreeModel();
  LibraryTreeItem *pFileItem = pLibraryTreeModel->getContainingFileParentLibraryTreeItem(pLibraryTreeItem);
  // Saved again only when the file on disk is still the one from before the layout (not saved since the layout).
  if (entry.itemSaved && entry.fileSaved && pFileItem->isFilePathValid() && readFile(pFileItem->getFileName()) == entry.fileText) {
    pLibraryTreeItem->setIsSaved(true);
    pFileItem->setIsSaved(true);
    pLibraryTreeModel->updateLibraryTreeItem(pLibraryTreeItem);
    if (pFileItem != pLibraryTreeItem) {
      pLibraryTreeModel->updateLibraryTreeItem(pFileItem);
    }
    if (pFileItem->getModelWidget()) {
      pFileItem->getModelWidget()->setWindowTitle(pFileItem->getName());
    }
  }
  undoEntries.remove(className);
  updateUndoAction();
  *pMessage = tr("Auto layout of %1 undone.").arg(className);
  return true;
}

/*!
 * \brief AutoLayoutDialog::updateUndoAction
 * Enables File > Format > Undo Auto Layout when the class of the current model widget has an auto layout to undo.
 */
void AutoLayoutDialog::updateUndoAction()
{
  MainWindow *pMainWindow = MainWindow::instance();
  ModelWidget *pModelWidget = pMainWindow->getModelWidgetContainer()->getCurrentModelWidget();
  pMainWindow->getUndoAutoLayoutAction()->setEnabled(pModelWidget && canUndo(pModelWidget->getLibraryTreeItem()));
}

/*!
 * \brief AutoLayoutDialog::autoLayout
 * Remembers the options and lays out the class.
 */
void AutoLayoutDialog::autoLayout()
{
  AutoLayout::Options options;
  options.layout = mpLayoutComboBox->currentData().toString();
  options.route = mpRouteComboBox->currentData().toString();
  options.direction = mpDirectionComboBox->currentData().toString();
  options.dx = mpDxSpinBox->value();
  options.dy = mpDySpinBox->value();
  options.scale = mpScaleSpinBox->value();
  options.keep = mpKeepCheckBox->isChecked();
  options.rotate = mpRotateCheckBox->isChecked();
  options.graphics = mpGraphicsComboBox->currentData().toString();
  options.stackMB = mpStackSpinBox->value();
  AutoLayout::setProgram(mpProgramTextBox->text().trimmed());
  QSettings *pSettings = Utilities::getApplicationSettings();
  pSettings->setValue(QString(keyPrefix) + "layout", options.layout);
  pSettings->setValue(QString(keyPrefix) + "route", options.route);
  pSettings->setValue(QString(keyPrefix) + "direction", options.direction);
  pSettings->setValue(QString(keyPrefix) + "dx", options.dx);
  pSettings->setValue(QString(keyPrefix) + "dy", options.dy);
  pSettings->setValue(QString(keyPrefix) + "scale", options.scale);
  pSettings->setValue(QString(keyPrefix) + "keep", options.keep);
  pSettings->setValue(QString(keyPrefix) + "rotate", options.rotate);
  pSettings->setValue(QString(keyPrefix) + "graphics", options.graphics);
  pSettings->setValue(QString(keyPrefix) + "stackMB", options.stackMB);
  QString message;
  if (!apply(mpLibraryTreeItem, options, &message)) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), message, QMessageBox::Ok);
    return;
  }
  MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, message, Helper::scriptingKind, Helper::notificationLevel));
  accept();
}
