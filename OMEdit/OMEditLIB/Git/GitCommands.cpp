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
  mpInstance = 0;
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
}
QString GitCommands::getGitStdout(const QStringList &args)
{
  return getGitStdout("", args);
}
QString GitCommands::getGitStdout(const QString &fileName, const QStringList &args)
{
  QProcess gitProcess;
  if (!fileName.isEmpty()) {
    QFileInfo fileInfo(fileName);
    gitProcess.setWorkingDirectory(fileInfo.absoluteDir().absolutePath());
  }
  gitProcess.start("git", args);
  gitProcess.waitForFinished();
  QString output = gitProcess.readAllStandardOutput();
  return output;
}

/*!
 * \brief GitCommands::logCurrentFile
 * shows the logs for the current file.
 * \param currentFile
 */
void GitCommands::logCurrentFile(QString currentFile)
{
  QString output = getGitStdout(
    MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName(),
    QStringList() << "log" << currentFile
  );
  QStringList lines = output.split("\n");
  foreach (QString line, lines) {
    if(!line.isEmpty())
      qDebug () << line; //emit logString(line);
    }
}

/*!
 * \brief GitCommands::stageCurrentFileForCommit
 * Stages the current file for next commit.
 * \param currentFile
 */
void GitCommands::stageCurrentFileForCommit(QString currentFile)
{
  getGitStdout(
        MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName(),
        QStringList() << "add" << currentFile
  );
}
/*!
 * \brief GitCommands::unstageCurrentFileFromCommit
 * Unstages the current file from next commit.
 * \param currentFile
 */
void GitCommands::unstageCurrentFileFromCommit(QString currentFile)
{
  getGitStdout(
        MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName(),
        QStringList() << "reset" << "HEAD" << "--"<< currentFile
  );
}

/*!
 * \brief GitCommands::cleanWorkingDirectory
 * clean the working directory
 * \param currentFile
 */
void GitCommands::cleanWorkingDirectory()
{
  getGitStdout(
        MainWindow::instance()->getModelWidgetContainer()->getCurrentModelWidget()->getLibraryTreeItem()->getFileName(),
        QStringList() << "clean" <<"-f"
  );
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
                         QString("A version control repository could not be created in %1").arg(repositoryPath), QMessageBox::Ok);
  }
  else {
    QString createRepo = getGitStdout(repositoryPath, QStringList() << "init");
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, createRepo,
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
  QString git = getGitStdout(QStringList() << "--version");
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
  QString isGitRepository = getGitStdout(
        filePath, QStringList() << "rev-parse" << "--is-inside-work-tree"
  );
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
  QString untrackedFilesOutput = getGitStdout(
        workingDirectory, QStringList() << "ls-files" << "--other" << "--exclude-standard"
  );
  QStringList untrackedFilesList = untrackedFilesOutput.split("\n");
  return untrackedFilesList;
}

/*!
 * \brief GitCommands::getChangedFiles
 * Returns list of changed files .
 * \return
 */
QStringList GitCommands::getChangedFiles(QString filePath)
{
  QString changedFilesOutput = getGitStdout(filePath, QStringList() << "status"<< "--porcelain" << filePath);
  QStringList changedFilesOutputList = changedFilesOutput.split("\n");
  return changedFilesOutputList;
}

/*!
 * \brief GitCommands::getSingleFileStatus
 * Returns the status of the file .
 * \return
 */
QString GitCommands::getSingleFileStatus(QString fileName)
{
  return getGitStdout(QStringList() << "status"<< "--porcelain" << fileName);
}


/*!
 * \brief GitCommands::getRepositoryName
 * Returns the repository .
 * \return
 */
QString GitCommands::getRepositoryName(QString filePath)
{
  return getGitStdout(filePath, QStringList() << "rev-parse" << "--show-toplevel");
}

/*!
 * \brief GitCommands::getBranchName
 * Returns the branch name .
 * \return
 */
QString GitCommands::getBranchName(QString filePath)
{
  return getGitStdout(filePath, QStringList() << "rev-parse" << "--abbrev-ref" << "HEAD");
}

/*!
 * \brief GitCommands::getAuthorName
 * Returns the author name .
 * \return
 */
QString GitCommands::getAuthorName()
{
  return getGitStdout(QStringList() << "config" << "user.name");
}

/*!
 * \brief GitCommands::getEmailName
 * Returns the email name .
 * \return
 */
QString GitCommands::getEmailName()
{
  return getGitStdout(QStringList() << "config" << "user.email");
}

/*!
 * \brief GitCommands::getGitHash
 * Returns the git hash of the file .
 * \return
 */
QString GitCommands::getGitHash(QString fileName)
{
  return getGitStdout(fileName, QStringList() << "hash-object" << fileName);
}

/*!
 * \brief GitCommands::commitFiles
 * commit files to the local repository.
 * \param repositoryPath
 */
void GitCommands::commitFiles(QString repositoryPath, QString commitMessage)
{
  getGitStdout(repositoryPath, QStringList() << "commit" <<"-m" << commitMessage);
}

/*!
 * \brief GitCommands::getGitHash
 * Returns the git hash of the file .
 * \return
 */
QString GitCommands::commitAndGetFileHash(QString fileName, QString activity)
{
  getGitStdout(QStringList() << "add" << fileName);
  getGitStdout(QStringList() << "commit" << fileName << "-m" << activity);
  return getGitHash(fileName);
}
