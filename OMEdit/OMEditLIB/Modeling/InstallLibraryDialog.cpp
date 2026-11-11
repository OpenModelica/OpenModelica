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

/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#include "InstallLibraryDialog.h"
#include "MainWindow.h"
#include "OMC/OMCProxy.h"
#include "Modeling/MessagesWidget.h"

#include <QFile>
#include <QDir>
#include <QDirIterator>
#include <QListWidget>
#if defined(__EMSCRIPTEN__)
#include "OMEditGUI/wasm/WasmLocalFiles.h"
#else
#include "omcruntime_rust.h"
#endif
#include <QMessageBox>
#include <QGridLayout>

/*!
 * \brief InstallLibraryDialog::InstallLibraryDialog
 * \param parent
 */
InstallLibraryDialog::InstallLibraryDialog(QDialog *parent)
  : QDialog(parent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, Helper::installLibrary));
  setMinimumWidth(400);
  Label *pHeadingLabel = Utilities::getHeadingLabel(Helper::installLibrary);
  pHeadingLabel->setElideMode(Qt::ElideMiddle);
  Label *pPackageManagerText = new Label(tr("The library will be installed using the <u><a href=\"https://openmodelica.org/doc/OpenModelicaUsersGuide/%1/packagemanager.html#the-package-manager\">package manager</a></u>.").arg(Helper::OpenModelicaUsersGuideVersion));
  pPackageManagerText->setOpenExternalLinks(true);
  pPackageManagerText->setTextInteractionFlags(Qt::TextBrowserInteraction);
  // support levels
  mpFullSupportCheckBox = new QCheckBox(tr("Full"));
  mpFullSupportCheckBox->setChecked(true);
  connect(mpFullSupportCheckBox, SIGNAL(toggled(bool)), SLOT(filterChanged(bool)));
  mpSupportCheckBox = new QCheckBox(tr("Partial"));
  mpSupportCheckBox->setChecked(true);
  connect(mpSupportCheckBox, SIGNAL(toggled(bool)), SLOT(filterChanged(bool)));
  mpExperimentalCheckBox = new QCheckBox(tr("Experimental"));
  connect(mpExperimentalCheckBox, SIGNAL(toggled(bool)), SLOT(filterChanged(bool)));
  mpObsoleteCheckBox = new QCheckBox(tr("Obsolete"));
  connect(mpObsoleteCheckBox, SIGNAL(toggled(bool)), SLOT(filterChanged(bool)));
  mpNoSupportCheckBox = new QCheckBox(tr("None"));
  connect(mpNoSupportCheckBox, SIGNAL(toggled(bool)), SLOT(filterChanged(bool)));
  QGroupBox *pSupportLevelsGroupBox = new QGroupBox(tr("Level of support by OpenModelica"));
  QGridLayout *pSupportLevelsGridLayout = new QGridLayout;
  pSupportLevelsGridLayout->addWidget(mpFullSupportCheckBox, 0, 0);
  pSupportLevelsGridLayout->addWidget(mpSupportCheckBox, 0, 1);
  pSupportLevelsGridLayout->addWidget(mpExperimentalCheckBox, 1, 0);
  pSupportLevelsGridLayout->addWidget(mpObsoleteCheckBox, 1, 1);
  pSupportLevelsGridLayout->addWidget(mpNoSupportCheckBox, 2, 0, 1, 2);
  pSupportLevelsGroupBox->setLayout(pSupportLevelsGridLayout);
  // name combobox
  mpNameComboBox = new QComboBox;
  connect(mpNameComboBox, SIGNAL(currentIndexChanged(int)), SLOT(libraryIndexChanged(int)));
  // source label
  mpSourceLabel = new Label;
  mpSourceLabel->setOpenExternalLinks(true);
  mpSourceLabel->setTextInteractionFlags(Qt::TextBrowserInteraction);
  // version combobox
  mpVersionComboBox = new QComboBox;
  // fetch libraries
  QString indexFilePath = MainWindow::instance()->getLibraryIndexFilePath();
  if (QFile::exists(indexFilePath)) {
    if (mIndexJsonDocument.parse(indexFilePath)) {
      QVariantMap result = mIndexJsonDocument.result.toMap();
      mLibrariesMap = result["libs"].toMap();
      for (QVariantMap::const_iterator librariesIterator = mLibrariesMap.begin(); librariesIterator != mLibrariesMap.end(); ++librariesIterator) {
        const QString library = librariesIterator.key();
        QStringList versions = MainWindow::instance()->getOMCProxy()->getAvailablePackageVersions(library, "");
        mLibrariesAndVersionsMap.insert(library, versions);
      }
    }
  } else {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          GUIMessages::getMessage(GUIMessages::LIBRARY_INDEX_FILE_NOT_FOUND).arg(indexFilePath), QMessageBox::Ok);
  }
  // exact match checkbox
  mpExactMatchCheckBox = new QCheckBox(tr("Exact Match (Install only the specified version of dependencies)"));
  mpExactMatchCheckBox->setChecked(true);
  // Progress label
  mpProgressLabel = new Label(tr("<b>Installing library. Please wait.</b>"));
  mpProgressLabel->hide();
  // buttons
  mpOkButton = new QPushButton(Helper::ok);
  mpOkButton->setAutoDefault(true);
  connect(mpOkButton, SIGNAL(clicked()), SLOT(installLibrary()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpOkButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);

  filterChanged(true);
  // layout
  QGridLayout *pMainGridLayout = new QGridLayout;
  int row = 0;
  pMainGridLayout->setAlignment(Qt::AlignTop);
  pMainGridLayout->addWidget(pHeadingLabel, row++, 0, 1, 2);
  pMainGridLayout->addWidget(Utilities::getHeadingLine(), row++, 0, 1, 2);
  pMainGridLayout->addWidget(pPackageManagerText, row++, 0, 1, 2);
  pMainGridLayout->addWidget(pSupportLevelsGroupBox, row++, 0, 1, 2);
  pMainGridLayout->addWidget(new Label(Helper::name), row, 0);
  pMainGridLayout->addWidget(mpNameComboBox, row++, 1);
  pMainGridLayout->addWidget(new Label(Helper::versionLabel), row, 0);
  pMainGridLayout->addWidget(mpVersionComboBox, row++, 1);
  pMainGridLayout->addWidget(mpSourceLabel, row++, 0, 1, 2);
  pMainGridLayout->addWidget(mpExactMatchCheckBox, row++, 0, 1, 2);
  pMainGridLayout->addWidget(mpProgressLabel, row, 0);
  pMainGridLayout->addWidget(mpButtonBox, row++, 1, Qt::AlignRight);
  setLayout(pMainGridLayout);
}

/*!
 * \brief InstallLibraryDialog::filterChanged
 * Updates the version combobox when any filter changes.
 * \param checked
 */
void InstallLibraryDialog::filterChanged(bool checked)
{
  Q_UNUSED(checked);

  mpNameComboBox->clear();
  mFilteredLibrariesMap.clear();

  for (QVariantMap::const_iterator librariesIterator = mLibrariesMap.begin(); librariesIterator != mLibrariesMap.end(); ++librariesIterator) {
    const QString library = librariesIterator.key();

    QVariantMap libraryMap = mLibrariesMap[library].toMap();
    QVariantMap libraryVersionsMap = libraryMap["versions"].toMap();
    QStringList versions = mLibrariesAndVersionsMap[library];
    QStringList filteredVersions = versions;
    QStringList supportList;
    QStringList providesList;

    if (mpFullSupportCheckBox->isChecked()) {
      supportList.append("fullSupport");
    }
    if (mpSupportCheckBox->isChecked()) {
      supportList.append("support");
    }
    if (mpExperimentalCheckBox->isChecked()) {
      supportList.append("experimental");
    }
    if (mpObsoleteCheckBox->isChecked()) {
      supportList.append("obsolete");
    }
    if (mpNoSupportCheckBox->isChecked()) {
      supportList.append("noSupport");
    }

    foreach (QString version, versions) {
      QVariantMap libraryVersionMap = libraryVersionsMap[version].toMap();
      QList<QVariant> provides = libraryVersionMap["provides"].toList();
      foreach (QVariant provide, provides) {
        providesList.append(provide.toString());
      }
      // support filter
      QString support = libraryVersionMap["support"].toString();
      if (!supportList.isEmpty() && !supportList.contains(support)) {
        filteredVersions.removeOne(version);
      }
    }

    filteredVersions.removeDuplicates();

    if (!filteredVersions.isEmpty()) {
      mpNameComboBox->addItem(library);
      FilteredLibrary filteredLibrary;
      filteredLibrary.source = libraryMap["git"].toString();
      filteredLibrary.versions = filteredVersions;
      mFilteredLibrariesMap.insert(library, filteredLibrary);
    }
  }

  libraryIndexChanged(mpNameComboBox->currentIndex());
}

/*!
 * \brief InstallLibraryDialog::libraryIndexChanged
 * Fills the version combobox when the library is changed.
 * \param index
 */
void InstallLibraryDialog::libraryIndexChanged(int index)
{
  const QString text = mpNameComboBox->itemText(index);
  mpSourceLabel->clear();
  mpVersionComboBox->clear();

  if (text.isEmpty()) {
    mpOkButton->setEnabled(false);
  } else {
    FilteredLibrary filteredLibrary = mFilteredLibrariesMap[text];
    mpSourceLabel->setText(QString("<a href=\"%1\">%1</a>").arg(filteredLibrary.source));
    foreach (QString version, filteredLibrary.versions) {
      mpVersionComboBox->addItem(StringHandler::convertSemVertoReadableString(version), version);
    }
    mpOkButton->setEnabled(true);
  }
}

/*!
 * \brief InstallLibraryDialog::installLibrary
 * Installs the library.
 */
void InstallLibraryDialog::installLibrary()
{
  mpProgressLabel->show();
  mpOkButton->setEnabled(false);
  repaint(); // repaint the dialog so progresslabel is updated.
  QString library = mpNameComboBox->currentText();
  QString version = mpVersionComboBox->itemData(mpVersionComboBox->currentIndex()).toString();
  bool exactMatch = mpExactMatchCheckBox->isChecked();

  if (MainWindow::instance()->getOMCProxy()->installPackage(library, version, exactMatch)) {
    MainWindow::instance()->addSystemLibraries();
    accept();
  } else {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          tr("The library <b>%1</b> is not installed. See message browser for any possible messages.").arg(library), QMessageBox::Ok);
    mpProgressLabel->hide();
    mpOkButton->setEnabled(true);
  }
}

/*!
 * \brief UpgradeInstalledLibrariesDialog::UpgradeInstalledLibrariesDialog
 * \param parent
 */
UpgradeInstalledLibrariesDialog::UpgradeInstalledLibrariesDialog(QDialog *parent)
  : QDialog(parent)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, Helper::upgradeInstalledLibraries));
  setMinimumWidth(400);
  Label *pHeadingLabel = Utilities::getHeadingLabel(Helper::upgradeInstalledLibraries);
  pHeadingLabel->setElideMode(Qt::ElideMiddle);
  // description label
  mpDescriptLabel = new Label(tr("Upgrade the installed libraries that have been registered by the package manager."));
  // installNewestVersions checkbox
  mpInstallNewestVersionsCheckBox = new QCheckBox(tr("Install Newest Versions (may install the latest non-compatible versions)"));
  // Progress label
  mpProgressLabel = new Label(tr("<b>Upgrading installed libraries. Please wait.</b>"));
  mpProgressLabel->hide();
  // buttons
  mpUpgradeButton = new QPushButton(tr("Upgrade"));
  mpUpgradeButton->setAutoDefault(true);
  connect(mpUpgradeButton, SIGNAL(clicked()), SLOT(upgradeInstalledLibraries()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  // add buttons to the button box
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpUpgradeButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // layout
  QGridLayout *pMainGridLayout = new QGridLayout;
  int row = 0;
  pMainGridLayout->setAlignment(Qt::AlignTop);
  pMainGridLayout->addWidget(pHeadingLabel, row++, 0, 1, 2);
  pMainGridLayout->addWidget(Utilities::getHeadingLine(), row++, 0, 1, 2);
  pMainGridLayout->addWidget(mpDescriptLabel, row++, 0, 1, 2);
  pMainGridLayout->addWidget(mpInstallNewestVersionsCheckBox, row++, 0, 1, 2);
  pMainGridLayout->addWidget(mpProgressLabel, row, 0);
  pMainGridLayout->addWidget(mpButtonBox, row++, 1, Qt::AlignRight);
  setLayout(pMainGridLayout);
}

/*!
 * \brief UpgradeInstalledLibrariesDialog::upgradeInstalledLibraries
 * Upgrade the installed libraries.
 */
void UpgradeInstalledLibrariesDialog::upgradeInstalledLibraries()
{
  mpProgressLabel->show();
  mpUpgradeButton->setEnabled(false);
  repaint(); // repaint the dialog so progresslabel is updated.

  if (MainWindow::instance()->getOMCProxy()->upgradeInstalledPackages(mpInstallNewestVersionsCheckBox->isChecked())) {
    MainWindow::instance()->addSystemLibraries();
    accept();
  } else {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          tr("Failed to upgrade libraries. See message browser for any possible messages."), QMessageBox::Ok);
    mpProgressLabel->hide();
    mpUpgradeButton->setEnabled(true);
  }
}

namespace {

/*!
 * \brief findPackages
 * The packages below dir: the directories with a package.mo that are not inside another one, and the other .mo files,
 * at most depth levels down.
 */
void findPackages(const QString &dir, int depth, QList<QPair<QString, bool> > *packages)
{
  if (QFile::exists(dir + "/package.mo")) {
    packages->append(qMakePair(dir, false));
    return;
  }
  const QFileInfoList entries = QDir(dir).entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
  foreach (const QFileInfo &entry, entries) {
    if (entry.isDir()) {
      if (depth > 0) {
        findPackages(entry.absoluteFilePath(), depth - 1, packages);
      }
    } else if (entry.suffix() == "mo") {
      packages->append(qMakePair(entry.absoluteFilePath(), true));
    }
  }
}

bool copyDirectory(const QString &from, const QString &to)
{
  QDirIterator it(from, QDir::Files | QDir::NoDotAndDotDot | QDir::Hidden, QDirIterator::Subdirectories);
  while (it.hasNext()) {
    const QString file = it.next();
    const QString target = to + file.mid(from.size());
    if (!QDir().mkpath(QFileInfo(target).absolutePath()) || !QFile::copy(file, target)) {
      return false;
    }
  }
  return true;
}

#if !defined(__EMSCRIPTEN__)
/*!
 * \brief findPackagesInZip
 * findPackages for the files of a zip file, named as omcrs_unzip_path takes them.
 */
QList<QPair<QString, bool> > findPackagesInZip(const QStringList &files)
{
  QStringList packageDirectories;
  foreach (const QString &file, files) {
    if (file == "package.mo" || file.endsWith("/package.mo")) {
      packageDirectories << file.left(qMax(0, file.size() - QString("/package.mo").size()));
    }
  }
  auto inPackage = [&packageDirectories](const QString &file) {
    foreach (const QString &dir, packageDirectories) {
      if (dir != file && (dir.isEmpty() || file.startsWith(dir + "/"))) {
        return true;
      }
    }
    return false;
  };
  QList<QPair<QString, bool> > packages;
  foreach (const QString &dir, packageDirectories) {
    if (!inPackage(dir) && dir.count('/') < 4) {
      packages.append(qMakePair(dir, false));
    }
  }
  foreach (const QString &file, files) {
    if (file.endsWith(".mo") && !file.endsWith("package.mo") && !inPackage(file) && file.count('/') < 4) {
      packages.append(qMakePair(file, true));
    }
  }
  return packages;
}

/*!
 * \brief zipResult
 * True if the omcruntime_rust call succeeded, else reports its error.
 */
bool zipResult(char *error)
{
  if (!error) {
    return true;
  }
  MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, QString::fromUtf8(error), Helper::scriptingKind, Helper::errorLevel));
  omcrs_free_string(error);
  return false;
}
#endif

/*!
 * \brief readTopFile
 * The text of a package's top-level file, in the zip file if there is one.
 */
QString readTopFile(const QString &zipFile, const QString &fileName)
{
#if !defined(__EMSCRIPTEN__)
  if (!zipFile.isEmpty()) {
    QString text;
    char *contents = nullptr;
    if (zipResult(omcrs_zip_read(zipFile.toUtf8().constData(), fileName.toUtf8().constData(), &contents))) {
      text = QString::fromUtf8(contents);
      omcrs_free_string(contents);
    }
    return text;
  }
#endif
  QFile file(fileName);
  return file.open(QIODevice::ReadOnly) ? QString::fromUtf8(file.readAll()) : QString();
}

}

/*!
 * \class InstallLibraryFromPathDialog
 * \brief Installs the packages of a .mo file, a .zip file or a directory into the user's library directory.
 */
/*!
 * \brief InstallLibraryFromPathDialog::InstallLibraryFromPathDialog
 * \param path
 * \param librariesDirectory - where to install, the package manager's directory.
 * \param parent
 */
InstallLibraryFromPathDialog::InstallLibraryFromPathDialog(const QString &path, const QString &librariesDirectory, QWidget *parent)
  : QDialog(parent), mLibrariesDirectory(librariesDirectory)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, Helper::installLibrary));
  setMinimumWidth(450);
  // The web clients get a staged copy of what the user picked, which is moved rather than copied.
#if defined(__EMSCRIPTEN__)
  mMove = true;
#else
  mMove = false;
#endif
  Label *pHeadingLabel = Utilities::getHeadingLabel(Helper::installLibrary);
  pHeadingLabel->setElideMode(Qt::ElideMiddle);
  Label *pDescriptionLabel = new Label(tr("Install these packages of <b>%1</b>:").arg(QFileInfo(path).fileName().toHtmlEscaped()));
  pDescriptionLabel->setWordWrap(true);
  mpPackagesListWidget = new QListWidget;
  QList<QPair<QString, bool> > packages;
  QString root = path;
  if (QFileInfo(path).suffix().compare("zip", Qt::CaseInsensitive) == 0) {
#if defined(__EMSCRIPTEN__)
    root = WasmLocalFiles::expandArchive(path);
    if (!root.isEmpty()) {
      findPackages(root, 3, &packages);
    }
#else
    char *entries = nullptr;
    if (zipResult(omcrs_zip_entries(path.toUtf8().constData(), &entries))) {
      mZipFile = path;
      packages = findPackagesInZip(QString::fromUtf8(entries).split('\n', Qt::SkipEmptyParts));
      omcrs_free_string(entries);
    }
#endif
  } else if (QFileInfo(path).isDir()) {
    findPackages(path, 3, &packages);
  } else {
    packages.append(qMakePair(path, true));
  }
  for (const auto &package : packages) {
    const QString topFile = package.second ? package.first : (package.first.isEmpty() ? "package.mo" : package.first + "/package.mo");
    addPackage(package.first, package.second, readTopFile(mZipFile, topFile));
  }
  connect(mpPackagesListWidget, SIGNAL(itemChanged(QListWidgetItem*)), SLOT(updateInstallButton()));
  Label *pReadOnlyLabel = new Label(tr("An installed library is read-only. To change a library, open it with %1 instead.")
                                    .arg(Helper::openModelicaFiles));
  pReadOnlyLabel->setWordWrap(true);
  mpProgressLabel = new Label(tr("<b>Installing the packages. Please wait.</b>"));
  mpProgressLabel->hide();
  mpInstallButton = new QPushButton(tr("Install"));
  mpInstallButton->setAutoDefault(true);
  connect(mpInstallButton, SIGNAL(clicked()), SLOT(installPackages()));
  QPushButton *pCancelButton = new QPushButton(Helper::cancel);
  pCancelButton->setAutoDefault(false);
  connect(pCancelButton, SIGNAL(clicked()), SLOT(reject()));
  QDialogButtonBox *pButtonBox = new QDialogButtonBox(Qt::Horizontal);
  pButtonBox->addButton(mpInstallButton, QDialogButtonBox::ActionRole);
  pButtonBox->addButton(pCancelButton, QDialogButtonBox::ActionRole);
  QGridLayout *pMainGridLayout = new QGridLayout;
  int row = 0;
  pMainGridLayout->setAlignment(Qt::AlignTop);
  pMainGridLayout->addWidget(pHeadingLabel, row++, 0, 1, 2);
  pMainGridLayout->addWidget(Utilities::getHeadingLine(), row++, 0, 1, 2);
  pMainGridLayout->addWidget(pDescriptionLabel, row++, 0, 1, 2);
  pMainGridLayout->addWidget(mpPackagesListWidget, row++, 0, 1, 2);
  pMainGridLayout->addWidget(pReadOnlyLabel, row++, 0, 1, 2);
  pMainGridLayout->addWidget(mpProgressLabel, row, 0);
  pMainGridLayout->addWidget(pButtonBox, row++, 1, Qt::AlignRight);
  setLayout(pMainGridLayout);
}

/*!
 * \brief InstallLibraryFromPathDialog::addPackage
 * Lists the package of a file or directory if its top-level file holds exactly one class.
 * \param path - the .mo file or the package directory.
 * \param isFile
 * \param text - the top-level file.
 */
void InstallLibraryFromPathDialog::addPackage(const QString &path, bool isFile, const QString &text)
{
  const QList<QString> classes = MainWindow::instance()->getOMCProxy()->parseString(text, path, false);
  if (classes.size() != 1) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                          tr("%1 does not contain exactly one top-level class, so it is not a package to install.").arg(path),
                                                          Helper::scriptingKind, Helper::notificationLevel));
    return;
  }
  const QString name = classes.first();
  QListWidgetItem *pItem = new QListWidgetItem(name);
  pItem->setData(Qt::UserRole, path);
  pItem->setData(Qt::UserRole + 1, isFile);
  pItem->setToolTip(path);
  if (QFile::exists(QString("%1/%2").arg(mLibrariesDirectory, name)) || QFile::exists(QString("%1/%2.mo").arg(mLibrariesDirectory, name))) {
    pItem->setText(tr("%1 (replaces the installed %1)").arg(name));
  }
  pItem->setData(Qt::UserRole + 2, name);
  pItem->setFlags(pItem->flags() | Qt::ItemIsUserCheckable);
  pItem->setCheckState(Qt::Checked);
  mpPackagesListWidget->addItem(pItem);
}

/*!
 * \brief InstallLibraryFromPathDialog::installPackage
 * Installs a package as the library directory Name or the library file Name.mo, replacing an installed one.
 */
bool InstallLibraryFromPathDialog::installPackage(const QString &name, const QString &path, bool isFile)
{
  const QString directory = QString("%1/%2").arg(mLibrariesDirectory, name);
  const QString target = isFile ? directory + ".mo" : directory;
  if (mZipFile.isEmpty() && QFileInfo(path).canonicalFilePath() == QFileInfo(target).canonicalFilePath()) {
    return true;
  }
  QDir(directory).removeRecursively();
  QFile::remove(directory + ".mo");
  if (!QDir().mkpath(mLibrariesDirectory)) {
    return false;
  }
#if !defined(__EMSCRIPTEN__)
  if (!mZipFile.isEmpty()) {
    return zipResult(omcrs_unzip_path(mZipFile.toUtf8().constData(), path.toUtf8().constData(), target.toUtf8().constData()));
  }
#endif
  if (mMove) {
    return QFile::rename(path, target);
  } else if (isFile) {
    return QFile::copy(path, target);
  } else {
    return copyDirectory(path, target);
  }
}

/*!
 * \brief InstallLibraryFromPathDialog::updateInstallButton
 * Enables the install button while some package is checked.
 */
void InstallLibraryFromPathDialog::updateInstallButton()
{
  bool checked = false;
  for (int i = 0; i < mpPackagesListWidget->count() && !checked; ++i) {
    checked = mpPackagesListWidget->item(i)->checkState() == Qt::Checked;
  }
  mpInstallButton->setEnabled(checked);
}

/*!
 * \brief InstallLibraryFromPathDialog::installPackages
 * Installs the checked packages.
 */
void InstallLibraryFromPathDialog::installPackages()
{
  mpProgressLabel->show();
  mpInstallButton->setEnabled(false);
  repaint(); // repaint the dialog so progresslabel is updated.
  QStringList failed;
  for (int i = 0; i < mpPackagesListWidget->count(); ++i) {
    QListWidgetItem *pItem = mpPackagesListWidget->item(i);
    const QString name = pItem->data(Qt::UserRole + 2).toString();
    if (pItem->checkState() == Qt::Checked && !installPackage(name, pItem->data(Qt::UserRole).toString(), pItem->data(Qt::UserRole + 1).toBool())) {
      failed << name;
    }
  }
  MainWindow::instance()->addSystemLibraries();
  if (failed.isEmpty()) {
    accept();
  } else {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          tr("Could not install %1. See message browser for any possible messages.").arg(failed.join(", ")), QMessageBox::Ok);
    mpProgressLabel->hide();
    mpInstallButton->setEnabled(true);
  }
}
