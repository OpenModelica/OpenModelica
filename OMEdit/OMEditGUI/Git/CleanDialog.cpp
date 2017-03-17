
#include "CleanDialog.h"
#include "MainWindow.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Git/GitCommands.h"
#include "Util/Helper.h"
#include "QFrame"
#include "QDialogButtonBox"
#include "QStyle"
#include "QFileInfo"
#include "QGridLayout"
#include "QStandardItemModel"
#include "QApplication"

enum { columnCount };
enum { fileNameRole = Qt::UserRole, isDirectoryRole = Qt::UserRole + 1 };

/*!
 * \class CleanDialog
 * \brief Creates a dialog that allows to select untracked files to be cleaned
 */
/*!
 * \brief CleanDialog::CleanDialog
 * \param pMainWindow - pointer to MainWindow
 */
CleanDialog::CleanDialog(QWidget *pParent)
  : QDialog(pParent)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Clean Repository")));
  setAttribute(Qt::WA_DeleteOnClose);
  resize(500, 400);
  // Select all check box
  mpSelectAllCheckBox = new QCheckBox(tr("Select All"));
  mpCleanFilesModel = new QStandardItemModel(0, columnCount, this);
  mpCleanFilesModel->setHorizontalHeaderLabels(QStringList(tr("Name")));
  // files tree view
  mpCleanFilesTreeView = new QTreeView;
  mpCleanFilesTreeView->setModel(mpCleanFilesModel);
  mpCleanFilesTreeView->setUniformRowHeights(true);
  mpCleanFilesTreeView->setSelectionMode(QAbstractItemView::NoSelection);
  mpCleanFilesTreeView->setAllColumnsShowFocus(true);
  mpCleanFilesTreeView->setRootIsDecorated(false);
  // Create the buttons
  mpCleanRepositoryButton = new QPushButton(tr("Clean"));
  mpCleanRepositoryButton->setEnabled(true);
  connect(mpCleanRepositoryButton, SIGNAL(clicked()), SLOT(accept()));
  mpCancelButton = new QPushButton(Helper::cancel);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpCleanRepositoryButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  //
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
  connect(mpSelectAllCheckBox, &QAbstractButton::clicked, this, &CleanDialog::selectAllItems);
  connect(mpCleanFilesTreeView, &QAbstractItemView::clicked, this, &CleanDialog::updateSelectAllCheckBox);
#else // Qt4
#endif
  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpSelectAllCheckBox, 0, 0);
  pMainLayout->addWidget(mpCleanFilesTreeView, 1, 0);
  pMainLayout->addWidget(mpButtonBox, 2, 0,  Qt::AlignRight);
  setLayout(pMainLayout);

  getUntrackedFiles();
}

void CleanDialog::getUntrackedFiles()
{
  QString fileName = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName();
  QString workingDirectory = GitCommands::instance()->getRepositoryName(fileName);
  QStringList untrackedFiles = GitCommands::instance()->getUntrackedFiles(fileName);

  if (const int oldRowCount = mpCleanFilesModel->rowCount())
      mpCleanFilesModel->removeRows(0, oldRowCount);
  foreach (const QString &fileName, untrackedFiles)
     if(!fileName.isEmpty())
       addFile(workingDirectory, fileName, true);
  for (int c = 0; c < mpCleanFilesModel->columnCount(); c++)
      mpCleanFilesTreeView->resizeColumnToContents(c);
   mpSelectAllCheckBox->setChecked(true);
}

void CleanDialog::addFile(const QString &workingDirectory, QString fileName, bool checked)
{
  const QChar slash = QLatin1Char('/');
  // Clean the trailing slash of directories
  if (fileName.endsWith(slash))
      fileName.chop(1);
  QFileInfo fi(workingDirectory + slash + fileName);
  bool isDir = fi.isDir();
  if (isDir)
      checked = false;
  auto nameItem = new QStandardItem(QDir::toNativeSeparators(fileName));
  nameItem->setFlags(Qt::ItemIsUserCheckable|Qt::ItemIsEnabled);
  QFileInfo fileInfo(fileName);
  nameItem->setIcon(Utilities::FileIconProvider::icon(fileInfo));
  nameItem->setCheckable(true);
  nameItem->setCheckState(checked ? Qt::Checked : Qt::Unchecked);
  nameItem->setData(QVariant(fi.absoluteFilePath()), fileNameRole);
  mpCleanFilesModel->appendRow(nameItem);
}

QStringList CleanDialog::checkedFiles() const
{
  QStringList rc;
  if (const int rowCount = mpCleanFilesModel->rowCount()) {
      for (int r = 0; r < rowCount; r++) {
          const QStandardItem *item = mpCleanFilesModel->item(r, 0);
          if (item->checkState() == Qt::Checked)
              rc.push_back(item->data(fileNameRole).toString());
      }
  }
  return rc;
}

void CleanDialog::selectAllItems(bool checked)
{
  if (const int rowCount = mpCleanFilesModel->rowCount()) {
      for (int r = 0; r < rowCount; ++r) {
          QStandardItem *item = mpCleanFilesModel->item(r, 0);
          item->setCheckState(checked ? Qt::Checked : Qt::Unchecked);
      }
  }
}

void CleanDialog::updateSelectAllCheckBox(void)
{
  bool checked = true;
  if (const int rowCount = mpCleanFilesModel->rowCount()) {
      for (int r = 0; r < rowCount; ++r) {
          const QStandardItem *item = mpCleanFilesModel->item(r, 0);
          if (item->checkState() == Qt::Unchecked) {
              checked = false;
              break;
          }
      }
      mpSelectAllCheckBox->setChecked(checked);
  }
}
