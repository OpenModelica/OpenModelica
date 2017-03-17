#include "RevertCommitsDialog.h"
#include "MainWindow.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Git/GitCommands.h"
#include "Util/Helper.h"
#include "Util/StringHandler.h"
#include "QPushButton"
#include "QDialogButtonBox"
#include "QLineEdit"
#include "QFileInfo"
#include "QFrame"
#include "QGridLayout"

/*!
 * \class RevertCommitsDialog
 * \brief Creates a dialog that shows to select a git commit to be reverted.
 */
/*!
 * \brief RevertCommitsDialog::RevertCommitsDialog
 * \param pMainWindow - pointer to MainWindow
 */
RevertCommitsDialog::RevertCommitsDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Revert Commit")));
  setAttribute(Qt::WA_DeleteOnClose);
  resize(500, 400);
  QString repository = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName();
  // Working directory
  mpWorkingDirectoryLabel = new Label(tr("Working Directory:"));
  mpWorkingDirectoryTextBox = new QLineEdit;
  mpWorkingDirectoryTextBox->setText(GitCommands::instance()->getRepositoryName(repository));
  connect(mpWorkingDirectoryTextBox, SIGNAL(textChanged(QString)), this, SLOT(workingDirectoryChanged(QString)));
  mpDirectoryBrowseButton = new QPushButton(tr("Browse Directory"));
  connect(mpDirectoryBrowseButton, SIGNAL(clicked()), SLOT(browseWorkingDirectory()));
  // Commit
  mpCommitLabel = new Label(tr("Commit:"));
  mpCommitTextBox = new QLineEdit;
  mpCommitTextBox->setText("HEAD");
  mpCommitTextBox->setFocus();
  mpCommitTextBox->selectAll();
  mpCommitTextBox->setReadOnly(true);
  connect(mpCommitTextBox, SIGNAL(textChanged(QString)), this, SLOT(commitTextChanged(QString)));
  mpCommitBrowseButton = new QPushButton(tr("Browse Commit"));
  connect(mpCommitBrowseButton, SIGNAL(clicked()), SLOT(browseCommitLog()));
  mpCommitDescriptionTextBox = new QPlainTextEdit;
  mpCommitDescriptionTextBox->setReadOnly(true);
  // Create the buttons
  mpRevertButton = new QPushButton(tr("Revert"));
  mpRevertButton->setEnabled(true);
  connect(mpRevertButton, SIGNAL(clicked()), SLOT(revertCommit()));
  mpCancelButton = new QPushButton(Helper::cancel);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpRevertButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpWorkingDirectoryLabel, 0, 0);
  pMainLayout->addWidget(mpWorkingDirectoryTextBox, 0, 1);
  pMainLayout->addWidget(mpDirectoryBrowseButton, 0, 2);
  pMainLayout->addWidget(mpCommitLabel, 1, 0);
  pMainLayout->addWidget(mpCommitTextBox, 1, 1);
  pMainLayout->addWidget(mpCommitBrowseButton, 1, 2);
  pMainLayout->addWidget(mpCommitDescriptionTextBox, 2, 0, 1, 3);
  pMainLayout->addWidget(mpButtonBox, 3, 0, 3, 3,  Qt::AlignRight);
  setLayout(pMainLayout);

  getCommitHistory();
}
/*!
  Slot activated when mpCommitTextBox textChanged signal is raised.\n
  */
void RevertCommitsDialog::commitTextChanged(const QString &commit)
{
  mpProcess = new QProcess(this);
  QString repository = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName();
  QFileInfo fileInfo(repository);
  QString directory = fileInfo.absoluteDir().absolutePath();
  mpProcess->setWorkingDirectory(directory);
  mpProcess->start("git", { "show", "--stat=80", commit });
  mpProcess->waitForFinished();
  QString commitHistory =  mpProcess->readAllStandardOutput();
  mpCommitDescriptionTextBox->setPlainText(commitHistory);
}

void RevertCommitsDialog::getCommitHistory()
{
  mpProcess = new QProcess(this);
  QString repository = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName();
  QFileInfo fileInfo(repository);
  QString directory = fileInfo.absoluteDir().absolutePath();
  mpProcess->setWorkingDirectory(directory);
  mpProcess->start("git", { "show", "--stat=80", mpCommitTextBox->text() });
  mpProcess->waitForFinished();
  QString commitHistory =  mpProcess->readAllStandardOutput();
  mpCommitDescriptionTextBox->setPlainText(commitHistory);
}

void RevertCommitsDialog::revertCommit()
{
  mpProcess = new QProcess(this);
  QString repository = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName();
  QFileInfo fileInfo(repository);
  QString directory = fileInfo.absoluteDir().absolutePath();
  mpProcess->setWorkingDirectory(directory);
  mpProcess->start("git", { "revert", mpCommitTextBox->text() });
  mpProcess->waitForFinished();
  QString revert =  mpProcess->readAllStandardOutput();
  accept();
}

void RevertCommitsDialog::browseCommitLog()
{
  LogCommitDialog *pLogCommitDialog = new LogCommitDialog(this);
  pLogCommitDialog->exec();
}

void RevertCommitsDialog::workingDirectoryChanged(const QString &workingDirectory)
{

}

void RevertCommitsDialog::browseWorkingDirectory()
{
  QString workingDirectory = StringHandler::getExistingDirectory(this, QString("%1 - %2").arg(Helper::applicationName).arg(Helper::chooseDirectory), NULL);
  if (workingDirectory.isEmpty())
    return;
  mpWorkingDirectoryTextBox->setText(workingDirectory);
}

void RevertCommitsDialog::setCommit(QString commit)
{
  mpCommitTextBox->setText(commit);
}
/*!
 * \class LogCommitDialog
 * \brief Creates a dialog that shows commit log.
 */
/*!
 * \brief LogCommitDialog::LogCommitDialog
 * \param pMainWindow - pointer to MainWindow
 */

enum Columns
{
    Sha1Column,
    SubjectColumn,
    ColumnCount
};

LogCommitDialog::LogCommitDialog(RevertCommitsDialog *pRevertCommitsDialog)
  : QDialog(pRevertCommitsDialog)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Select Commit")));
  setAttribute(Qt::WA_DeleteOnClose);
  resize(500, 400);
  mpRevertCommitsDialog = pRevertCommitsDialog;
  mpLogModel = new QStandardItemModel(0, ColumnCount, this);
  QStringList headers;
  headers << tr("Sha1")<< tr("Subject");
  mpLogModel->setHorizontalHeaderLabels(headers);
  // Log commit tree view
  mpLogTreeView = new QTreeView;
  mpLogTreeView->setModel(mpLogModel);
  mpLogTreeView->setMinimumWidth(300);
  mpLogTreeView->setUniformRowHeights(true);
  mpLogTreeView->setRootIsDecorated(false);
  mpLogTreeView->setSelectionBehavior(QAbstractItemView::SelectRows);
  mpLogTreeView->setSelectionMode(QAbstractItemView::SingleSelection);
  // Create the buttons
  mpOkButton = new QPushButton(tr("Ok"));
  mpOkButton->setEnabled(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(ok()));
  mpCancelButton = new QPushButton(Helper::cancel);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpLogTreeView, 0, 0);
  pMainLayout->addWidget(mpButtonBox, 1, 0);
  setLayout(pMainLayout);

  getCommitLog();
}

void LogCommitDialog::getCommitLog()
{
  mpProcess = new QProcess(this);
  QString repository = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName();
  QFileInfo fileInfo(repository);
  QString directory = fileInfo.absoluteDir().absolutePath();
  mpProcess->setWorkingDirectory(directory);
  mpProcess->start("git", { "log", "--stat=80", "--max-count=100", "--format=%h:%s "});
  mpProcess->waitForFinished();
  QString commitHistory =  mpProcess->readAllStandardOutput();

  const QString currentCommit = this->commit();
  int selected = currentCommit.isEmpty() ? 0 : -1;
  if (const int rowCount = mpLogModel->rowCount())
      mpLogModel->removeRows(0, rowCount);

  foreach (const QString &line, commitHistory.split('\n')) {
       const int colonPos = line.indexOf(':');
       if (colonPos != -1) {
           QList<QStandardItem *> row;
           for (int c = 0; c < ColumnCount; ++c) {
               auto item = new QStandardItem;
               item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
               if (line.endsWith(')')) {
                   QFont font = item->font();
                   font.setBold(true);
                   item->setFont(font);
               }
               row.push_back(item);
           }
           const QString sha1 = line.left(colonPos);
           row[Sha1Column]->setText(sha1);
           row[SubjectColumn]->setText(line.right(line.size() - colonPos - 1));
//           row[Sha1Column]->setData(Qt::Checked, Qt::CheckStateRole);
//           row[Sha1Column]->setCheckable(true);
           mpLogModel->appendRow(row);
           if (selected == -1 && currentCommit == sha1)
               selected = mpLogModel->rowCount() - 1;
       }
   }
  mpLogTreeView->setCurrentIndex(mpLogModel->index(selected, 0));
}

QString LogCommitDialog::commit() const
{
  if (const QStandardItem *sha1Item = currentItem(Sha1Column))
      return sha1Item->text();
  return QString();
}

const QStandardItem *LogCommitDialog::currentItem(int column) const
{
  const QModelIndex currentIndex = mpLogTreeView->selectionModel()->currentIndex();
  if (currentIndex.isValid())
      return mpLogModel->item(currentIndex.row(), column);
  return 0;
}

int LogCommitDialog::commitIndex() const
{
  const QModelIndex currentIndex = mpLogTreeView->selectionModel()->currentIndex();
  if (currentIndex.isValid())
      return currentIndex.row();
  return -1;
}

void LogCommitDialog::ok()
{
  mpRevertCommitsDialog->setCommit(commit());
  accept();

}
