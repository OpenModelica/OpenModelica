#include "ImportFMUModelDescriptionDialog.h"


/*!
  \class ImportFMUModelDescriptionDialog
  \brief Creates an interface for importing FMU model description.
  */

/*!
  \param pParent - pointer to MainWindow
  */
ImportFMUModelDescriptionDialog::ImportFMUModelDescriptionDialog(MainWindow *pParent)
  : QDialog(pParent)
{
  setWindowTitle(QString(Helper::applicationName).append(" - ").append(tr("Import FMU Model Description")));
  setAttribute(Qt::WA_DeleteOnClose);
  setMinimumWidth(550);
  // set parent widget
  mpMainWindow = pParent;
  // create FMU File selection controls
  mpFmuModelDescriptionLabel = new Label(tr("FMU Model Description:"));
  mpFmuModelDescriptionTextBox = new QLineEdit;
  mpBrowseFileButton = new QPushButton(Helper::browse);
  mpBrowseFileButton->setAutoDefault(false);
  connect(mpBrowseFileButton, SIGNAL(clicked()), SLOT(setSelectedFile()));
  // create Output Directory selection controls
  mpOutputDirectoryLabel = new Label(tr("Output Directory:"));
  mpOutputDirectoryTextBox = new QLineEdit;
  mpBrowseDirectoryButton = new QPushButton(Helper::browse);
  mpBrowseDirectoryButton->setAutoDefault(false);
  connect(mpBrowseDirectoryButton, SIGNAL(clicked()), SLOT(setSelectedDirectory()));
  // create OK button
  mpImportButton = new QPushButton(Helper::ok);
  mpImportButton->setAutoDefault(true);
  connect(mpImportButton, SIGNAL(clicked()), SLOT(importFMUModelDescription()));
  // set grid layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  pMainLayout->addWidget(mpFmuModelDescriptionLabel, 0, 0);
  pMainLayout->addWidget(mpFmuModelDescriptionTextBox, 0, 1);
  pMainLayout->addWidget(mpBrowseFileButton, 0, 2);
  pMainLayout->addWidget(mpOutputDirectoryLabel, 1, 0);
  pMainLayout->addWidget(mpOutputDirectoryTextBox, 1, 1);
  pMainLayout->addWidget(mpBrowseDirectoryButton, 1, 2);
  pMainLayout->addWidget(mpImportButton, 2, 0, 1, 3, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
  Slot activated when mpBrowseFileButton clicked signal is raised.\n
  Allows the user to select the FMU model description.
  */
void ImportFMUModelDescriptionDialog::setSelectedFile()
{
  mpFmuModelDescriptionTextBox->setText(StringHandler::getOpenFileName(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseFile),
                                                           NULL, Helper::xmlFileTypes, NULL));
}

/*!
  Slot activated when mpBrowseDirectoryButton clicked signal is raised.\n
  Allows the user to select the output directory for FMU models with input and output.
  */
void ImportFMUModelDescriptionDialog::setSelectedDirectory()
{
  mpOutputDirectoryTextBox->setText(StringHandler::getExistingDirectory(this, QString(Helper::applicationName).append(" - ").append(Helper::chooseDirectory), NULL));
}

/*!
  Slot activated when mpImportButton clicked signal is raised.\n
  Sends the importFMUModelDescription command to OMC.
  */
void ImportFMUModelDescriptionDialog::importFMUModelDescription()
{
  if (mpFmuModelDescriptionTextBox->text().isEmpty())
  {
    QMessageBox::critical(this, QString(Helper::applicationName).append(" - ").append(Helper::error),
                          GUIMessages::getMessage(GUIMessages::ENTER_NAME).arg(tr("FMU Model Description")), Helper::ok);
    return;
  }
  QString fmuFileName = mpMainWindow->getOMCProxy()->importFMUModelDescription(mpFmuModelDescriptionTextBox->text(), mpOutputDirectoryTextBox->text(), 1, false, true, true);

  if (!fmuFileName.isEmpty())
    mpMainWindow->getLibraryWidget()->openFile(fmuFileName);
  accept();
}
