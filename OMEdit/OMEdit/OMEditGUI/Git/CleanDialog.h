#ifndef CLEANDIALOG_H
#define CLEANDIALOG_H


#include <QDialog>
#include <QLineEdit>
#include <QCheckBox>
#include <QTreeView>
#include <QPushButton>
#include <QDialogButtonBox>
#include <QStandardItemModel>
#include<QProcess>


class CleanDialog : public QDialog
{
  Q_OBJECT
public:
  CleanDialog(QWidget *pParent = 0);
private:
  QStandardItemModel *mpCleanFilesModel;
  QTreeView * mpCleanFilesTreeView;
  QString *mpworkingDirectory;
  void getUntrackedFiles();
  QStringList checkedFiles() const;
  void addFile(const QString &workingDirectory, QString fileName, bool checked);
  QCheckBox *mpSelectAllCheckBox;
  QPushButton *mpCleanRepositoryButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  QProcess *mpProcess;
//private slots:
//  void revertCommit();
//  void browseCommitLog();
//  void workingDirectoryChanged(const QString &workingDirectory);
//  void browseWorkingDirectory();
//  void commitTextChanged(const QString &commit);
public slots:
  void selectAllItems(bool checked);
  void updateSelectAllCheckBox(void);
};

#endif // CLEANDIALOG_H
