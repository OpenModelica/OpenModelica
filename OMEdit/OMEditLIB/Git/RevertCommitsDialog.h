#ifndef REVERTCOMMITSDIALOG_H
#define REVERTCOMMITSDIALOG_H

#include "QStandardItemModel"
#include "QTreeView"
#include "QPlainTextEdit"
#include "QCheckBox"
#include "QDialogButtonBox"
#include <QDialog>

#include<QProcess>

class Label;
class RevertCommitsDialog : public QDialog
{
  Q_OBJECT
public:
  RevertCommitsDialog(QWidget *pParent = 0);
  void setCommit(QString commit );
private:
  void getCommitHistory();
  Label *mpWorkingDirectoryLabel;
  QLineEdit *mpWorkingDirectoryTextBox;
  QPushButton *mpDirectoryBrowseButton;
  Label *mpCommitLabel;
  QLineEdit *mpCommitTextBox;
  QPushButton *mpCommitBrowseButton;
  QPlainTextEdit *mpCommitDescriptionTextBox;
  QPushButton *mpRevertButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  QProcess *mpProcess;
private slots:
  void revertCommit();
  void browseCommitLog();
  void workingDirectoryChanged(const QString &workingDirectory);
  void browseWorkingDirectory();
  void commitTextChanged(const QString &commit);
};


class LogCommitDialog : public QDialog
{
  Q_OBJECT
public:
  LogCommitDialog(RevertCommitsDialog *pRevertCommitsDialog);
  QString commit() const;
  int commitIndex() const;
  const QStandardItem *currentItem(int column = 0) const;
private:
  RevertCommitsDialog *mpRevertCommitsDialog;
  void getCommitLog();
  QStandardItemModel *mpLogModel;
  QTreeView *mpLogTreeView;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  QProcess *mpProcess;
private slots:
  void ok();

};

#endif // REVERTCOMMITSDIALOG_H
