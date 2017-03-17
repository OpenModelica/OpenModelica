#include "GitCommands.h"
#include "MainWindow.h"
#include "Modeling/MessagesWidget.h"
#include "Modeling/ModelWidgetContainer.h"
#include "Util/Helper.h"
#include "QFileInfo"
#include "QDir"
#include "QMessageBox"

#include "QGridLayout"

/*!
 * \class GitCommands
 * \brief Interface for communication with Git.
 */

GitCommands *GitCommands::mpInstance = 0;

/*!
 * \brief GitCommands::create
 */
void GitCommands::create()
{
  if (!mpInstance) {
    mpInstance = new GitCommands;
  }
}

/*!
 * \brief GitCommands::destroy
 */
void GitCommands::destroy()
{
  mpInstance->deleteLater();
}

/*!
 * \class GitCommands
 * \brief Interface for communication with Git.
 */
/*!
 * \brief GitCommands::GitCommands
 * \param pMainWindow - pointer to MainWindow
 */
GitCommands::GitCommands(QWidget *pParent)
  : QObject(pParent)
{
  mpGitProcess = new QProcess;
// mpGitProcess = 0;
}

/*!
 * \brief GitCommands::logCurrentFile
 * shows the logs for the current file.
 * \param currentFile
 */
void GitCommands::logCurrentFile(QString currentFile)
{
  QFileInfo fileInfo(MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName());
  mpGitProcess->setWorkingDirectory(fileInfo.absoluteDir().absolutePath());
  mpGitProcess->start("git", QStringList() << "log" << currentFile);
  mpGitProcess->waitForFinished();
  QByteArray bytes = mpGitProcess->readAllStandardOutput();
  QStringList lines = QString(bytes).split("\n");
  foreach (QString line, lines) {
    if(!line.isEmpty())
      qDebug () << line; //emit logString(line);
    }
}

//void GitCommands::readGitStandardOutput()
//{
//  QByteArray bytes = mpGitProcess->readAllStandardOutput();
//  QStringList lines = QString(bytes).split("\n");
//  foreach (QString line, lines) {
//    if(!line.isEmpty())
//      qDebug ()<<"readGitStandaroutput" << line; //emit logString(line);
//    }
//}

/*!
 * \brief GitCommands::stageCurrentFileForCommit
 * Stages the current file for next commit.
 * \param currentFile
 */
void GitCommands::stageCurrentFileForCommit(QString currentFile)
{
  QFileInfo fileInfo(MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName());
  mpGitProcess->setWorkingDirectory(fileInfo.absoluteDir().absolutePath());
  mpGitProcess->start("git", QStringList() << "add" << currentFile);
  mpGitProcess->waitForFinished();
  QString stage = mpGitProcess->readAllStandardOutput();
}
/*!
 * \brief GitCommands::unstageCurrentFileFromCommit
 * Unstages the current file from next commit.
 * \param currentFile
 */
void GitCommands::unstageCurrentFileFromCommit(QString currentFile)
{
  QFileInfo fileInfo(MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName());
  mpGitProcess->setWorkingDirectory(fileInfo.absoluteDir().absolutePath());
  mpGitProcess->start("git", QStringList() << "reset" << "HEAD" << "--"<< currentFile);
  mpGitProcess->waitForFinished();
  QString unstage = mpGitProcess->readAllStandardOutput();
}

/*!
 * \brief GitCommands::cleanWorkingDirectory
 * clean the working directory
 * \param currentFile
 */
void GitCommands::cleanWorkingDirectory()
{
  QFileInfo fileInfo(MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName());
  mpGitProcess->setWorkingDirectory(fileInfo.absoluteDir().absolutePath());
  mpGitProcess->start("git", QStringList() << "clean" <<"-f");
  mpGitProcess->waitForFinished();
  QString clean = mpGitProcess->readAllStandardOutput();
}

/*!
 * \brief GitCommands::createGitRepository
 * Creates a git repositoryt.
 * \param repositoryPath
 */
void GitCommands::createGitRepository(QString repositoryPath)
{
  if(!isGitInstalled()) {
    // Todo get Git path from settings
    QMessageBox::warning(0, QString(Helper::applicationName).append(" - ").append(tr("Repository Creation Failed")),
                         QString("A version control repository could not be created in %1").arg(repositoryPath), Helper::ok);
  }
  else {
    QStringList args;
    args << "init";
    runGitCommand(repositoryPath, args);

//    mpGitProcess->setWorkingDirectory(repositoryPath);
//    mpGitProcess->start("git", QStringList() << "init");
//    mpGitProcess->waitForFinished();
    QString createRepo = mpGitProcess->readAllStandardOutput();
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::CompositeModel, "", false, 0, 0, 0, 0, createRepo,
                                              Helper::scriptingKind, Helper::notificationLevel));

    addStructuresToRepository(repositoryPath);

  }
}

/*!
 * \brief GitCommands::addStructuresToRepository()
 * Adds structures such as Models,SimulationResults and FMU to the repository.
 * \param repositoryPath
 */
void GitCommands::addStructuresToRepository(QString repositoryPath)
{
  QDir::setCurrent(repositoryPath);
  QDir().mkdir("Models");
  QDir().mkdir("SimulationResults");
  QDir().mkdir("FMUs");
  QDir().mkdir("ModelDescriptions");
}

/*!
 * \brief GitCommands::isGitExists()
 * Returns true if Git is installed .
 * \return
 */
bool GitCommands::isGitInstalled()
{
  mpGitProcess->start("git", QStringList() << "--version");
  mpGitProcess->waitForFinished();
  QString git = mpGitProcess->readAllStandardOutput();
  /* Check for git installation */
  if(!git.isEmpty()){
    return true ;
  }
  else
    return false;
}

/*!
 * \brief GitCommands::isSavedUnderGitRepository
 * Returns true if the file is saved under Git repository .
 * \return
 */
bool GitCommands::isSavedUnderGitRepository(QString filePath)
{
  QFileInfo fileInfo(filePath);
  QString repository = fileInfo.absoluteDir().absolutePath();
//  mpGitProcess = new QProcess;
  mpGitProcess->setWorkingDirectory(repository);
  mpGitProcess->start("git", QStringList() << "rev-parse" << "--is-inside-work-tree");
  mpGitProcess->waitForFinished();
  QString isGitRepository =  mpGitProcess->readAllStandardOutput();
  if(!isGitRepository.isEmpty())
     return true;
  return false;
}

/*!
 * \brief GitCommands::getUntrackedFiles
 * Returns list of untracked files .
 * \return
 */
QStringList GitCommands::getUntrackedFiles(QString workingDirectory)
{
  QFileInfo fileInfo(workingDirectory);
  mpGitProcess->setWorkingDirectory(fileInfo.absoluteDir().absolutePath());
  mpGitProcess->start("git", QStringList() << "ls-files" << "--other" << "--exclude-standard");
  mpGitProcess->waitForFinished();
  QByteArray untrackedFilesOutput =  mpGitProcess->readAllStandardOutput();
  QStringList untrackedFilesList = QString(untrackedFilesOutput).split("\n");
  return untrackedFilesList;
}

/*!
 * \brief GitCommands::getChangedFiles
 * Returns list of changed files .
 * \return
 */
QStringList GitCommands::getChangedFiles(QString filePath)
{
  QFileInfo fileInfo(filePath);
  mpGitProcess->setWorkingDirectory(fileInfo.absoluteDir().absolutePath());
  mpGitProcess->start("git", QStringList() << "status"<< "--porcelain" << filePath);
  mpGitProcess->waitForFinished();
  QByteArray changedFilesOutput =  mpGitProcess->readAllStandardOutput();
  QStringList changedFilesOutputList = QString(changedFilesOutput).split("\n");
  return changedFilesOutputList;
}

/*!
 * \brief GitCommands::getSingleFileStatus
 * Returns the status of the file .
 * \return
 */
QString GitCommands::getSingleFileStatus(QString fileName)
{
//  QFileInfo fileInfo(filePath);
//  mpGitProcess->setWorkingDirectory(fileInfo.absoluteDir().absolutePath());
  mpGitProcess->start("git", QStringList() << "status"<< "--porcelain" << fileName);
  mpGitProcess->waitForFinished();
  QByteArray changedFileOutput =  mpGitProcess->readAllStandardOutput();
  QString status = QString(changedFileOutput);
  return status;
}


/*!
 * \brief GitCommands::getRepositoryName
 * Returns the repository .
 * \return
 */
QString GitCommands::getRepositoryName(QString filePath)
{
  QFileInfo fileInfo(filePath);
  QString repository = fileInfo.absoluteDir().absolutePath();
  mpGitProcess->setWorkingDirectory(repository);
  mpGitProcess->start("git", QStringList() << "rev-parse" << "--show-toplevel");
  mpGitProcess->waitForFinished();
  QString repositoryName =  mpGitProcess->readAllStandardOutput();
  return repositoryName;
}

/*!
 * \brief GitCommands::getBranchName
 * Returns the branch name .
 * \return
 */
QString GitCommands::getBranchName(QString filePath)
{
  QFileInfo fileInfo(filePath);
  QString repository = fileInfo.absoluteDir().absolutePath();
  mpGitProcess->setWorkingDirectory(repository);
  mpGitProcess->start("git", QStringList() << "rev-parse" << "--abbrev-ref" << "HEAD");
  mpGitProcess->waitForFinished();
  QString branchName =  mpGitProcess->readAllStandardOutput();
  return branchName;
}

/*!
 * \brief GitCommands::getAuthorName
 * Returns the author name .
 * \return
 */
QString GitCommands::getAuthorName()
{
  mpGitProcess->start("git", QStringList() << "config" << "user.name");
  mpGitProcess->waitForFinished();
  QString author =  mpGitProcess->readAllStandardOutput();
  return author;
}

/*!
 * \brief GitCommands::getEmailName
 * Returns the email name .
 * \return
 */
QString GitCommands::getEmailName()
{
  mpGitProcess->start("git", QStringList() << "config" << "user.email");
  mpGitProcess->waitForFinished();
  QString email =  mpGitProcess->readAllStandardOutput();
  return email;
}

/*!
 * \brief GitCommands::getGitHash
 * Returns the git hash of the file .
 * \return
 */
QString GitCommands::getGitHash(QString fileName)
{
  QFileInfo fileInfo(fileName);
  QString filePath = fileInfo.absoluteDir().absolutePath();
  mpGitProcess->setWorkingDirectory(filePath);
  mpGitProcess->start("git", QStringList() << "hash-object" << fileName);
  mpGitProcess->waitForFinished();
  QString gitHash =  mpGitProcess->readAllStandardOutput();
  return gitHash;
}

/*!
 * \brief GitCommands::commitFiles
 * commit files to the local repository.
 * \param repositoryPath
 */
void GitCommands::commitFiles(QString repositoryPath, QString commitMessage)
{
  QFileInfo fileInfo(repositoryPath);
  QString directory = fileInfo.absoluteDir().absolutePath();
  mpGitProcess->setWorkingDirectory(directory);
  mpGitProcess->start("git", QStringList() << "commit" <<"-m" << commitMessage);
  mpGitProcess->waitForFinished();
}

/*!
 * \brief GitCommands::getGitHash
 * Returns the git hash of the file .
 * \return
 */
QString GitCommands::commitAndGetFileHash(QString fileName, QString activity)
{
  mpGitProcess->start("git", QStringList() << "add" << fileName);
  mpGitProcess->waitForFinished();
  mpGitProcess->start("git", QStringList() << "commit" << fileName <<"-m" << activity);
  mpGitProcess->waitForFinished();
  return getGitHash(fileName);
}

void GitCommands::runGitCommand(QString repositoryPath, QStringList args)
{
//  mpGitProcess = new QProcess;
  QFileInfo fileInfo(repositoryPath);
  // mpGitProcess = new QProcess;
  mpGitProcess->setWorkingDirectory(fileInfo.absoluteDir().absolutePath());
  // qRegisterMetaType<QProcess::ExitStatus>("QProcess::ExitStatus");
  // connect(mpGitProcess, SIGNAL(started()), SLOT(gitProcessStarted()));
  connect(mpGitProcess, SIGNAL(readyReadStandardOutput()), SLOT(readGitStandardOutput()));
  connect(mpGitProcess, SIGNAL(readyReadStandardError()), SLOT(readGitStandardError()));
  // connect(mpGitProcess, SIGNAL(finished(int,QProcess::ExitStatus)), SLOT(gitProcessFinished(int,QProcess::ExitStatus)));
  // start the process
  mpGitProcess->start("git",args);
  mpGitProcess->waitForFinished();
}

void GitCommands::readGitStandardOutput()
{
  qDebug()<< mpGitProcess->readAllStandardOutput();
//  mpGitProcess->kill();
  //emit sendManagerOutput(QString(mpManagerProcess->readAllStandardOutput()), StringHandler::Unknown);
}

void GitCommands::readGitStandardError()
{
  qDebug("error");
  qDebug()<<mpGitProcess->readAllStandardError();
//  mpGitProcess->kill();
  //emit sendManagerOutput(QString(mpManagerProcess->readAllStandardError()), StringHandler::Error);
}
