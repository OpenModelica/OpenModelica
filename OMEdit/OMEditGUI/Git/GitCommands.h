#ifndef GITCOMMANDS_H
#define GITCOMMANDS_H


#include <QObject>
#include "QStandardItemModel"
#include "QTreeView"
#include "QPlainTextEdit"
#include "QCheckBox"
#include "QDialogButtonBox"
#include <QProcess>


class GitCommands : public QObject
{
  Q_OBJECT
private:
  // the only class that is allowed to create and destroy
  friend class MainWindow;

  static void create();
  static void destroy();
  GitCommands(QWidget *pParent = 0);
  static GitCommands *mpInstance;
  static QString getGitStdout(const QStringList &args);
  static QString getGitStdout(const QString &fileName, const QStringList &args);
public:
//  GitCommands(QObject *pParent = 0);
  static GitCommands* instance() {return mpInstance;}
  void logCurrentFile(QString currentFile);
  void stageCurrentFileForCommit(QString currentFile);
  void unstageCurrentFileFromCommit(QString currentFile);
  void cleanWorkingDirectory();
  void createGitRepository(QString reporitoryPath);
  void addStructuresToRepository(QString reporitoryPath);
  bool isGitInstalled();
  bool isSavedUnderGitRepository(QString filePath);
  QStringList getUntrackedFiles(QString workingDirectory);
  QStringList getChangedFiles(QString filePath);
  QString getSingleFileStatus(QString fileName);
  QString getRepositoryName(QString directory);
  QString getBranchName(QString directory);
  QString getAuthorName();
  QString getEmailName();
  QString getGitHash(QString fileName);
  void commitFiles(QString repositoryPath, QString commitMessage);
  QString commitAndGetFileHash(QString fileName, QString activity);
private:
  QString mGitProgram;
  QStringList mGitArguments;
  void runGitCommand(QString driectory, QStringList args);
private slots:
//  void gitProcessStarted();
//  void readGitStandardOutput();
//  void readGitStandardError();
//  void gitProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
//signals:
//  void sendGitProcessStarted();
//  void sendGitProcessOutput(QString, StringHandler::SimulationMessageType type);
//  void sendGitProcessFinished(int, QProcess::ExitStatus);
//  void sendGitProgress(int);
};

#endif // GITCOMMANDS_H
