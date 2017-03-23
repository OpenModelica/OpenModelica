#include "CommitChangesDialog.h"
#include "MainWindow.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Modeling/MessagesWidget.h"
#include "Git/GitCommands.h"
#include "Options/OptionsDialog.h"
#include "Traceability/TraceabilityInformationURI.h"
#include "Util/Helper.h"
#include "QFrame"
#include "QGridLayout"
#include "QGroupBox"
#include "QPushButton"
#include "QDialogButtonBox"
#include "QDateTime"
#include "QTextStream"
#include "QFileInfo"

enum { statusColumn, nameColumn, columnCount};
//enum { fileNameRole = Qt::UserRole, isDirectoryRole = Qt::UserRole + 1 };

/*!
 * \class CommitChangesDialog
 * \brief Creates a dialog that shows the list of unsaved files to be commited.
 */
/*!
 * \brief CommitChangesDialog::CommitChangesDialog
 * \param pMainWindow - pointer to MainWindow
 */
CommitChangesDialog::CommitChangesDialog(QWidget *pParent)
: QDialog(pParent)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Commit")));
  setAttribute(Qt::WA_DeleteOnClose);
  resize(850, 600);
  QString repository = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName();
  // repository information
  mpRepositoryLabel = new Label(tr("Repository:"));
  mpRepositoryNameTextBox = new QLineEdit;
  mpRepositoryNameTextBox->setEnabled(false);
  mpRepositoryNameTextBox->setText(GitCommands::instance()->getRepositoryName(repository));
  //Branch
  mpBranchLabel = new Label(tr("Branch:"));
  mpBranchNameTextBox = new QLineEdit;
  mpBranchNameTextBox->setEnabled(false);
  mpBranchNameTextBox->setText(GitCommands::instance()->getBranchName(repository));
  QGroupBox *pRepositoryInformationGroupBox = new QGroupBox(tr("Repository Information:"));
  QGridLayout *pRepositoryInformationGridLayout = new QGridLayout;
  pRepositoryInformationGridLayout->addWidget(mpRepositoryLabel, 0, 0);
  pRepositoryInformationGridLayout->addWidget(mpRepositoryNameTextBox, 0, 1);
  pRepositoryInformationGridLayout->addWidget(mpBranchLabel, 1, 0);
  pRepositoryInformationGridLayout->addWidget(mpBranchNameTextBox, 1, 1);
  pRepositoryInformationGroupBox->setLayout(pRepositoryInformationGridLayout);
  // commit information
  QGroupBox *pCommitInformationGroupBox = new QGroupBox(tr("Commit Information:"));
  mpAuthorLabel = new Label(tr("Author:"));
  mpAuthorTextBox = new QLineEdit;
  mpAuthorTextBox->setText(GitCommands::instance()->getAuthorName());
  mpEmailLabel = new Label(tr("Email:"));
  mpEmailTextBox = new QLineEdit;
  mpEmailTextBox->setText(GitCommands::instance()->getEmailName());
  QGridLayout *pCommitInformationGridLayout = new QGridLayout;
  pCommitInformationGridLayout->addWidget(mpAuthorLabel, 0, 0);
  pCommitInformationGridLayout->addWidget(mpAuthorTextBox, 0, 1);
  pCommitInformationGridLayout->addWidget(mpEmailLabel, 1, 0);
  pCommitInformationGridLayout->addWidget(mpEmailTextBox, 1, 1);
  pCommitInformationGroupBox->setLayout(pCommitInformationGridLayout);
  // Commit description
  QGroupBox *pCommitDescriptionGroupBox = new QGroupBox(tr("Description:"));
  mpCommitDescriptionTextBox = new QPlainTextEdit;
  QGridLayout *pCommitDescriptionLayout = new QGridLayout;
  pCommitDescriptionLayout->addWidget(mpCommitDescriptionTextBox);
  pCommitDescriptionGroupBox->setLayout(pCommitDescriptionLayout);
  // Select all check box
  mpSelectAllCheckBox = new QCheckBox(tr("Select All"));
  mpCommitChangedFilesModel = new QStandardItemModel(0, columnCount, this);
  QStringList headers;
  headers << tr("Status")<< tr("File");
  mpCommitChangedFilesModel->setHorizontalHeaderLabels(headers);
  // files tree view
  mpCommitChangedFilesTreeView = new QTreeView;
  mpCommitChangedFilesTreeView->setModel(mpCommitChangedFilesModel);
  mpCommitChangedFilesTreeView->setUniformRowHeights(true);
  mpCommitChangedFilesTreeView->setSelectionMode(QAbstractItemView::NoSelection);
  mpCommitChangedFilesTreeView->setAllColumnsShowFocus(true);
  mpCommitChangedFilesTreeView->setRootIsDecorated(false);
  // files layout
  QGroupBox *pCommitFilesGroupBox = new QGroupBox(tr("Files:"));
  QGridLayout *pCommitFilesLayout = new QGridLayout;
  pCommitFilesLayout->addWidget(mpSelectAllCheckBox, 0, 0);
  pCommitFilesLayout->addWidget(mpCommitChangedFilesTreeView, 1, 0);
  pCommitFilesGroupBox->setLayout(pCommitFilesLayout);
  // Create the buttons
  mpCommitButton = new QPushButton(tr("commit"));
  mpCommitButton->setEnabled(false);
  connect(mpCommitButton, SIGNAL(clicked()), SLOT(commitFiles()));
  mpCancelButton = new QPushButton(Helper::cancel);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // create buttons box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpCommitButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  connect(mpCommitDescriptionTextBox, SIGNAL(textChanged()), this, SLOT(commitDescriptionTextChanged()));

  // set the layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(pRepositoryInformationGroupBox, 0, 0, 1, 2);
  pMainLayout->addWidget(pCommitInformationGroupBox, 1, 0);
  pMainLayout->addWidget(pCommitDescriptionGroupBox, 2, 0);
  pMainLayout->addWidget(pCommitFilesGroupBox, 3, 0);
  pMainLayout->addWidget(mpButtonBox, 4, 0, Qt::AlignRight);
  setLayout(pMainLayout);

  getChangedFiles();
}

void CommitChangesDialog::getChangedFiles()
{
  QString fileName = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName();

  mpModifiedFiles = GitCommands::instance()->getChangedFiles(fileName);

  if (const int oldRowCount = mpCommitChangedFilesModel->rowCount())
      mpCommitChangedFilesModel->removeRows(0, oldRowCount);
  foreach (const QString &fileName, mpModifiedFiles)
     if(!fileName.isEmpty()) {
       QString status = getFileStatus(fileName.mid(0, 2));
       QString file = fileName.mid(3);
       addFile(status, file, true);
     }
  for (int c = 0; c < mpCommitChangedFilesModel->columnCount(); c++)
      mpCommitChangedFilesTreeView->resizeColumnToContents(c);
   mpSelectAllCheckBox->setChecked(true);
}

void CommitChangesDialog::addFile(QString fileStatus, QString fileName, bool checked)
{

  /*QStyle *style = QApplication::style();
  const QIcon folderIcon = style->standardIcon(QStyle::SP_DirIcon);
  const QIcon fileIcon = style->standardIcon(QStyle::SP_FileIcon);
  const QChar slash = QLatin1Char('/');
  // Clean the trailing slash of directories
//  if (fileName.endsWith(slash))
//      fileName.chop(1);
//  QFileInfo fi(workingDirectory + slash + fileName);
//  bool isDir = fi.isDir();
//  if (isDir)
//      checked = false;
  auto nameItem = new QStandardItem(QDir::toNativeSeparators(fileName));
  nameItem->setFlags(Qt::ItemIsUserCheckable|Qt::ItemIsEnabled);
  nameItem->setIcon(isDir ? folderIcon : fileIcon);
  nameItem->setCheckable(true);
  nameItem->setCheckState(checked ? Qt::Checked : Qt::Unchecked);
  nameItem->setData(QVariant(fi.absoluteFilePath()), fileNameRole);
  mpCleanFilesModel->appendRow(nameItem);*/

   QList<QStandardItem *> row;
   for (int c = 0; c < columnCount; ++c) {
       auto item = new QStandardItem;
       item->setFlags(Qt::ItemIsEnabled | Qt::ItemIsSelectable);
       row.push_back(item);
   }
   row[statusColumn]->setText(fileStatus);
   row[nameColumn]->setText(fileName);
   row[statusColumn]->setData(Qt::Checked, Qt::CheckStateRole);
   row[statusColumn]->setCheckable(true);
   mpCommitChangedFilesModel->appendRow(row);
}

QString CommitChangesDialog::getFileStatus(QString status)
{
 if (status.trimmed().compare("M")== 0)
    return "Model Modification";
  else if (status.trimmed().compare("A")== 0)
    return "Model Creation";
  else if (status.trimmed().compare("D")== 0)
    return "Deleted";
  else if (status.trimmed().compare("R")== 0)
    return "Renamed";
  else if (status.trimmed().compare("C")== 0)
    return "Copied";
  else if (status.trimmed().compare("??")== 0)
    return "Model Creation";
 else if (status.trimmed().compare("AM")== 0)
   return "Model Creation";
  else
    // should never be reached
    return "UnknownFileStatus";
}

/*!
  Slot activated when mpCommitDescriptionTextBox textChanged signal is raised.\n
  */
void CommitChangesDialog::commitDescriptionTextChanged()
{
  if(!mpCommitDescriptionTextBox->toPlainText().isEmpty())
     mpCommitButton->setEnabled(true);
  else
     mpCommitButton->setEnabled(false);
}

void CommitChangesDialog::commitFiles()
{
  QString filePath = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName();
  QString nameStructure = MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getNameStructure();
  QFileInfo info(filePath);
  GitCommands::instance()->commitFiles(filePath, mpCommitDescriptionTextBox->toPlainText());
  foreach (const QString &fileName, mpModifiedFiles) {
    if(!fileName.isEmpty()) {
//      QString activity = getFileStatus(fileName.mid(0, 2));
//      QString fileURI = fileName.mid(3);
//      generateTraceabilityURI(nameStructure, info.absolutePath(), filePath, activity, fileURI );
      }
   }
  accept();
}

void CommitChangesDialog::generateTraceabilityURI(QString activity, QString modelFileName, QString nameStructure, QString fmuFileName)
{
  QString toolURI, activityURI, agentURI, sourceModelFileNameURI, fmuFileNameURI;
  QDir dir(OptionsDialog::instance()->getTraceabilityPage()->getGitRepository()->text());
  QDateTime time = QDateTime::currentDateTime();
  if(activity.compare("ModelDescription Import")== 0) {
    fmuFileNameURI = "Entity.model: " + dir.relativeFilePath(modelFileName) + "#" + GitCommands::instance()->commitAndGetFileHash(modelFileName, activity);
    sourceModelFileNameURI = "Entity.modelDescription xml:" + dir.relativeFilePath(fmuFileName) + "#" + GitCommands::instance()->getGitHash(fmuFileName);
  }else {
    fmuFileNameURI = "Entity.fmu: " + dir.relativeFilePath(fmuFileName) + "#" + GitCommands::instance()->commitAndGetFileHash(fmuFileName, activity);
    sourceModelFileNameURI = "Entity.model:" + dir.relativeFilePath(modelFileName) + "#" + GitCommands::instance()->getGitHash(modelFileName);
  }
  toolURI = "Entity.softwareTool: " + MainWindow::instance()->getOMCProxy()->getVersion();
  agentURI = "Agent:" + OptionsDialog::instance()->getTraceabilityPage()->getUserName()->text();
  activityURI = "Activity."+ activity +":" + time.toString("yyyy-MM-dd-hh-mm-ss");
  MainWindow::instance()->getTraceabilityInformationURI()->translateURIToJsonMessageFormat(activity,  toolURI,  activityURI,  agentURI,  sourceModelFileNameURI,  fmuFileNameURI);
}

void CommitChangesDialog::commitAndGenerateTraceabilityURI(QString fileName)
{
  QString status = GitCommands::instance()->getSingleFileStatus(fileName);
  QString activity = getFileStatus(status.mid(0, 2));
  QString commitMessage = "OpenModelica Modeling";
#if (QT_VERSION >= QT_VERSION_CHECK(5, 2, 0))
   commitMessage = QInputDialog::getMultiLineText(MainWindow::instance(), tr("Commit Message "), "Please Enter Commit Description:");
#else // Qt4
#endif
  QString toolURI, activityURI, agentURI, sourceModelFileNameURI, fmuFileNameURI;
  QDir dir(OptionsDialog::instance()->getTraceabilityPage()->getGitRepository()->text());
  QDateTime time = QDateTime::currentDateTime();
  toolURI = "Entity.softwareTool: " + MainWindow::instance()->getOMCProxy()->getVersion();
  agentURI = "Agent:" + OptionsDialog::instance()->getTraceabilityPage()->getUserName()->text();
  activityURI = "Activity."+ activity +":" + time.toString("yyyy-MM-dd-hh-mm-ss");
  if(activity.compare("Model Modification")== 0) {
    sourceModelFileNameURI = "Entity.model:" + dir.relativeFilePath(fileName) + "#" + GitCommands::instance()->getGitHash(fileName);
    fmuFileNameURI = "Entity.model:" + dir.relativeFilePath(fileName) + "#" + GitCommands::instance()->commitAndGetFileHash(fileName, commitMessage);
    MainWindow::instance()->getTraceabilityInformationURI()->translateURIToJsonMessageFormat(activity,  toolURI,  activityURI,  agentURI,  sourceModelFileNameURI,  fmuFileNameURI);
  }
  else if(activity.compare("Model Creation")== 0) {
    sourceModelFileNameURI = "Entity.model: " + dir.relativeFilePath(fileName) + "#" + GitCommands::instance()->commitAndGetFileHash(fileName, commitMessage);
    MainWindow::instance()->getTraceabilityInformationURI()->translateModelCreationURIToJsonMessageFormat(activity,  toolURI,  activityURI,  agentURI,  sourceModelFileNameURI);
  }
}


