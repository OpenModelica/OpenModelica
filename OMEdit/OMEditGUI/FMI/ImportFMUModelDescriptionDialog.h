#ifndef IMPORTFMUMODELDESCRIPTIONDIALOG_H
#define IMPORTFMUMODELDESCRIPTIONDIALOG_H

#include "MainWindow.h"

class MainWindow;

class ImportFMUModelDescriptionDialog : public QDialog
{
  Q_OBJECT
public:
  ImportFMUModelDescriptionDialog(MainWindow *pParent = 0);
private:
  MainWindow *mpMainWindow;
  Label *mpFmuModelDescriptionLabel;
  QLineEdit *mpFmuModelDescriptionTextBox;
  QPushButton *mpBrowseFileButton;
  Label *mpOutputDirectoryLabel;
  QLineEdit *mpOutputDirectoryTextBox;
  QPushButton *mpBrowseDirectoryButton;
  QPushButton *mpImportButton;
private slots:
  void setSelectedFile();
  void setSelectedDirectory();
  void importFMUModelDescription();
};

#endif // IMPORTFMUMODELDESCRIPTIONDIALOG_H
