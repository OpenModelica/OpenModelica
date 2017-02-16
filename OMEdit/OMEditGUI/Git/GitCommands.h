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
public:
  GitCommands(QObject *pParent = 0);
  QProcess* getGitProcess() {return mpGitProcess;}
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
  QString getRepositoryName(QString directory);
  QString getBranchName(QString directory);
  QString getAuthorName();
  QString getEmailName();
  QString getGitHash(QString fileName);
  void commitFiles(QString repositoryPath, QString commitMessage);
  QString commitAndGetFileHash(QString fileName, QString activity);
private:
  QProcess *mpGitProcess;
  QString mGitProgram;
  QStringList mGitArguments;

signals:

public slots:

private slots:
   // void readGitStandardOutput();
};

#endif // GITCOMMANDS_H
