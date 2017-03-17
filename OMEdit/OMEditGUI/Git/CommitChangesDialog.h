#ifndef COMMITCHANGESDIALOG_H
#define COMMITCHANGESDIALOG_H

#include "QDialog"
#include "QStandardItemModel"
#include "QTreeView"
#include "QPlainTextEdit"
#include "QLineEdit"
#include "QCheckBox"
#include "QDialogButtonBox"

class Label;
class CommitChangesDialog : public QDialog
{
  Q_OBJECT
public:
  CommitChangesDialog(QWidget *pParent = 0);
  void generateTraceabilityURI(QString activity, QString modelFileName, QString nameStructure, QString fmuFileName);
  void commitAndGenerateTraceabilityURI(QString fileName);
private:
  QStandardItemModel *mpCommitChangedFilesModel;
  QTreeView * mpCommitChangedFilesTreeView;
  void getChangedFiles();
  void addFile(QString fileStatus, QString fileName, bool checked);
  QString getFileStatus(QString status);
  QStringList mpModifiedFiles;
  Label *mpRepositoryLabel;
  QLineEdit *mpRepositoryNameTextBox;
  Label *mpBranchLabel;
  QLineEdit *mpBranchNameTextBox;
  Label *mpAuthorLabel;
  QLineEdit *mpAuthorTextBox;
  Label *mpEmailLabel;
  QLineEdit *mpEmailTextBox;
  Label *mpCommitDescriptionLabel;
  QPlainTextEdit *mpCommitDescriptionTextBox;
  QCheckBox *mpSelectAllCheckBox;
  QPushButton *mpCommitButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
private slots:
  void commitFiles();
  void commitDescriptionTextChanged();
};

#endif // COMMITCHANGESDIALOG_H
