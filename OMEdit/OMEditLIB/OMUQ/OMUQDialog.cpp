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

#include "OMUQDialog.h"
#include "OMUQOutputWidget.h"
#include "MainWindow.h"
#include "Modeling/LibraryTreeWidget.h"
#include "Modeling/MessagesWidget.h"
#include "OMS/OMSProxy.h"
#include "Options/OptionsDialog.h"
#include "Util/Helper.h"
#include "Util/StringHandler.h"
#include "Util/Utilities.h"

#include <QApplication>
#include <QDir>
#include <QDoubleValidator>
#include <QFileInfo>
#include <QGridLayout>
#include <QGroupBox>
#include <QHeaderView>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMessageBox>
#include <QProcess>

#include <utility>

/*!
 * \class OMUQDialog
 * \brief Lists the omuq studies attached to an SSP model and runs one of their activities.
 *
 * omuq is a separately installed Python package; OMEdit drives its command line
 * interface "python -m omuq list|run <package.ssp> --json".
 */
/*!
 * \brief OMUQDialog::OMUQDialog
 * \param pLibraryTreeItem - the top level SSP model.
 * \param pParent
 */
OMUQDialog::OMUQDialog(LibraryTreeItem *pLibraryTreeItem, QWidget *pParent)
  : QDialog(pParent), mpLibraryTreeItem(pLibraryTreeItem)
{
  setAttribute(Qt::WA_DeleteOnClose);
  setWindowTitle(QString("%1 - %2 - %3").arg(Helper::applicationName, tr("UQ Activities"), mpLibraryTreeItem->getNameStructure()));
  setMinimumWidth(600);
  // heading
  mpHeadingLabel = Utilities::getHeadingLabel(QString("%1 - %2").arg(tr("UQ Activities"), mpLibraryTreeItem->getNameStructure()));
  mpHeadingLabel->setElideMode(Qt::ElideMiddle);
  mpHorizontalLine = Utilities::getHeadingLine();
  // study and activity
  mpStudyLabel = new Label(tr("Study:"));
  mpStudyComboBox = new QComboBox;
  connect(mpStudyComboBox, SIGNAL(currentIndexChanged(int)), SLOT(studyChanged(int)));
  mpActivityLabel = new Label(tr("Activity:"));
  mpActivityComboBox = new QComboBox;
  connect(mpActivityComboBox, SIGNAL(currentIndexChanged(int)), SLOT(activityChanged(int)));
  mpActivityInformationLabel = new Label;
  mpActivityInformationLabel->setWordWrap(true);
  // domains
  mpDomainsTreeWidget = new QTreeWidget;
  mpDomainsTreeWidget->setRootIsDecorated(false);
  mpDomainsTreeWidget->setHeaderLabels({tr("Domain"), tr("Kind"), tr("Boundary"), tr("Variables")});
  mpDomainsTreeWidget->header()->setSectionResizeMode(QHeaderView::ResizeToContents);
  mpDomainsTreeWidget->setMinimumHeight(100);
  QGroupBox *pStudyGroupBox = new QGroupBox(tr("Study"));
  QGridLayout *pStudyGridLayout = new QGridLayout;
  pStudyGridLayout->addWidget(mpStudyLabel, 0, 0);
  pStudyGridLayout->addWidget(mpStudyComboBox, 0, 1);
  pStudyGridLayout->addWidget(mpActivityLabel, 1, 0);
  pStudyGridLayout->addWidget(mpActivityComboBox, 1, 1);
  pStudyGridLayout->addWidget(mpActivityInformationLabel, 2, 0, 1, 2);
  pStudyGridLayout->addWidget(new Label(tr("Domains:")), 3, 0, 1, 2);
  pStudyGridLayout->addWidget(mpDomainsTreeWidget, 4, 0, 1, 2);
  pStudyGroupBox->setLayout(pStudyGridLayout);
  // run settings
  QDoubleValidator *pDoubleValidator = new QDoubleValidator(this);
  mpStopTimeLabel = new Label(QString("%1:").arg(Helper::stopTime));
  mpStopTimeTextBox = new QLineEdit;
  mpStopTimeTextBox->setValidator(pDoubleValidator);
  mpStepSizeLabel = new Label(tr("Step Size:"));
  mpStepSizeTextBox = new QLineEdit;
  mpStepSizeTextBox->setValidator(pDoubleValidator);
  mpReportEveryLabel = new Label(tr("Show Progress Every:"));
  mpReportEverySpinBox = new QSpinBox;
  mpReportEverySpinBox->setRange(1, 1000000);
  mpReportEverySpinBox->setValue(10);
  mpReportEverySpinBox->setSuffix(tr(" samples"));
  mpReportEverySpinBox->setToolTip(tr("The result file always has every sample."));
  mpDriverLabel = new Label(tr("Simulator:"));
  mpDriverComboBox = new QComboBox;
  mpDriverComboBox->addItem(tr("Automatic"), "auto");
  mpDriverComboBox->addItem(tr("Local OMSimulator"), "local");
  mpDriverComboBox->addItem(tr("Docker"), "docker");
  mpRecordResultsCheckBox = new QCheckBox(tr("Record the run in the study and save the package as:"));
  mpResultsFileTextBox = new QLineEdit;
  mpResultsFileTextBox->setEnabled(false);
  mpBrowseResultsFileButton = new QPushButton(Helper::browse);
  mpBrowseResultsFileButton->setAutoDefault(false);
  mpBrowseResultsFileButton->setEnabled(false);
  connect(mpBrowseResultsFileButton, SIGNAL(clicked()), SLOT(browseResultsFile()));
  connect(mpRecordResultsCheckBox, SIGNAL(toggled(bool)), mpResultsFileTextBox, SLOT(setEnabled(bool)));
  connect(mpRecordResultsCheckBox, SIGNAL(toggled(bool)), mpBrowseResultsFileButton, SLOT(setEnabled(bool)));
  mpLiveViewLabel = new Label(tr("Live View:"));
  mpLiveViewComboBox = new QComboBox;
  mpLiveViewComboBox->addItem(tr("Off"), OMUQRunOptions::NoLiveView);
#ifdef OMUQ_LIVE_VIEW_IN_OMEDIT
  mpLiveViewComboBox->addItem(tr("In OMEdit"), OMUQRunOptions::LiveViewInOMEdit);
#endif
  mpLiveViewComboBox->addItem(tr("In the web browser"), OMUQRunOptions::LiveViewInBrowser);
  mpLiveViewComboBox->setToolTip(tr("omuq serves the live view until it is stopped from the output tab."));
  // remember the choice of the last run
  const int liveViewIndex = mpLiveViewComboBox->findData(Utilities::getApplicationSettings()->value("OMSimulator/omuqLiveView", OMUQRunOptions::LiveViewInOMEdit).toInt());
  mpLiveViewComboBox->setCurrentIndex(liveViewIndex > -1 ? liveViewIndex : 0);
  QGroupBox *pRunGroupBox = new QGroupBox(tr("Run"));
  QGridLayout *pRunGridLayout = new QGridLayout;
  pRunGridLayout->addWidget(mpStopTimeLabel, 0, 0);
  pRunGridLayout->addWidget(mpStopTimeTextBox, 0, 1, 1, 2);
  pRunGridLayout->addWidget(mpStepSizeLabel, 1, 0);
  pRunGridLayout->addWidget(mpStepSizeTextBox, 1, 1, 1, 2);
  pRunGridLayout->addWidget(mpReportEveryLabel, 2, 0);
  pRunGridLayout->addWidget(mpReportEverySpinBox, 2, 1, 1, 2);
  pRunGridLayout->addWidget(mpDriverLabel, 3, 0);
  pRunGridLayout->addWidget(mpDriverComboBox, 3, 1, 1, 2);
  pRunGridLayout->addWidget(mpRecordResultsCheckBox, 4, 0, 1, 3);
  pRunGridLayout->addWidget(mpResultsFileTextBox, 5, 0, 1, 2);
  pRunGridLayout->addWidget(mpBrowseResultsFileButton, 5, 2);
  pRunGridLayout->addWidget(mpLiveViewLabel, 6, 0);
  pRunGridLayout->addWidget(mpLiveViewComboBox, 6, 1, 1, 2);
  pRunGroupBox->setLayout(pRunGridLayout);
  // buttons
  mpRunButton = new QPushButton(tr("Run"));
  mpRunButton->setAutoDefault(true);
  connect(mpRunButton, SIGNAL(clicked()), SLOT(runActivity()));
  mpCancelButton = new QPushButton(Helper::cancel);
  mpCancelButton->setAutoDefault(false);
  connect(mpCancelButton, SIGNAL(clicked()), SLOT(reject()));
  mpButtonBox = new QDialogButtonBox(Qt::Horizontal);
  mpButtonBox->addButton(mpRunButton, QDialogButtonBox::ActionRole);
  mpButtonBox->addButton(mpCancelButton, QDialogButtonBox::ActionRole);
  // layout
  QGridLayout *pMainLayout = new QGridLayout;
  pMainLayout->setAlignment(Qt::AlignTop);
  pMainLayout->addWidget(mpHeadingLabel, 0, 0);
  pMainLayout->addWidget(mpHorizontalLine, 1, 0);
  pMainLayout->addWidget(pStudyGroupBox, 2, 0);
  pMainLayout->addWidget(pRunGroupBox, 3, 0);
  pMainLayout->addWidget(mpButtonBox, 4, 0, Qt::AlignRight);
  setLayout(pMainLayout);
}

/*!
 * \brief OMUQDialog::pythonExecutable
 * The Python executable that runs omuq, see Tools > Options > OMSimulator/SSP.
 * \return
 */
QString OMUQDialog::pythonExecutable()
{
  return OptionsDialog::instance()->getOMSimulatorPage()->getOMUQPythonTextBox()->text().trimmed();
}

/*!
 * \brief OMUQDialog::exec
 * Exports the model and lists its studies before showing the dialog.
 * \return
 */
int OMUQDialog::exec()
{
  if (!exportPackage() || !listStudies()) {
    deleteLater();
    return QDialog::Rejected;
  }
  return QDialog::exec();
}

/*!
 * \brief OMUQDialog::exportPackage
 * Exports the model to a temporary .ssp, so that unsaved changes are part of the run.
 * \return
 */
bool OMUQDialog::exportPackage()
{
  const QString directory = QString("%1/omuq/%2").arg(Utilities::tempDirectory(), mpLibraryTreeItem->getNameStructure());
  if (!QDir().mkpath(directory)) {
    QMessageBox::critical(MainWindow::instance(), QString("%1 - %2").arg(Helper::applicationName, Helper::error),
                          tr("Unable to create the directory %1.").arg(directory));
    return false;
  }
  mPackage = QString("%1/%2.ssp").arg(directory, mpLibraryTreeItem->getNameStructure());
  return OMSProxy::instance()->saveModel(mpLibraryTreeItem->getNameStructure(), mPackage);
}

/*!
 * \brief OMUQDialog::listStudies
 * Reads the studies, activities and domains with "omuq list --json".
 * \return false when omuq cannot be run or the model has no study.
 */
bool OMUQDialog::listStudies()
{
#if QT_CONFIG(process)
  const QString title = QString("%1 - %2").arg(Helper::applicationName, tr("UQ Activities"));
  const QString python = pythonExecutable();
  QProcess process;
  QApplication::setOverrideCursor(Qt::WaitCursor);
  process.start(python, {"-m", "omuq", "list", mPackage, "--json"});
  const bool finished = process.waitForStarted() && process.waitForFinished(120000);
  QApplication::restoreOverrideCursor();
  const QString error = QString::fromUtf8(process.readAllStandardError()).trimmed();
  if (!finished || process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
    QString message;
    if (process.error() == QProcess::FailedToStart) {
      message = tr("Failed to start %1: %2").arg(python, process.errorString());
    } else if (error.contains("No module named")) {
      message = tr("omuq is not installed for %1.").arg(python);
    } else {
      message = tr("omuq failed to read the model:\n%1").arg(error.isEmpty() ? process.errorString() : error);
    }
    message += "\n\n" + tr("Set the Python executable that has omuq installed in Tools > Options > OMSimulator/SSP.");
    if (process.state() != QProcess::NotRunning) {
      process.kill();
      process.waitForFinished();
    }
    QMessageBox::critical(MainWindow::instance(), title, message);
    return false;
  }
  QJsonParseError parseError;
  const QJsonDocument document = QJsonDocument::fromJson(process.readAllStandardOutput(), &parseError);
  if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
    QMessageBox::critical(MainWindow::instance(), title, tr("Unable to read the output of omuq: %1").arg(parseError.errorString()));
    return false;
  }
  mStudies = document.object().value("studies").toArray();
  if (mStudies.isEmpty()) {
    QMessageBox::information(MainWindow::instance(), title, tr("No omuq study is attached to %1.").arg(mpLibraryTreeItem->getNameStructure()));
    return false;
  }
  for (const QJsonValue &study : std::as_const(mStudies)) {
    mpStudyComboBox->addItem(study.toObject().value("name").toString());
  }
  // the default for the recorded run: next to the model file, or in the temporary directory
  const QFileInfo modelFile(mpLibraryTreeItem->getFileName());
  const QString resultsDirectory = mpLibraryTreeItem->isSaved() && modelFile.exists() ? modelFile.absolutePath() : QFileInfo(mPackage).absolutePath();
  mpResultsFileTextBox->setText(QString("%1/%2.uq.results.ssp").arg(resultsDirectory, mpLibraryTreeItem->getNameStructure()));
  return true;
#else
  return false;
#endif // QT_CONFIG(process)
}

/*!
 * \brief OMUQDialog::activityLabel
 * \param activity
 * \return a name for the activity, e.g., "Validation activity 1".
 */
QString OMUQDialog::activityLabel(const QJsonObject &activity) const
{
  QString name = activity.value("id").toString();
  if (name.isEmpty()) {
    name = activity.value("name").toString();
  }
  if (name.isEmpty()) {
    return tr("%1 activity %2").arg(activity.value("type").toString()).arg(activity.value("index").toInt() + 1);
  }
  return QString("%1 activity %2").arg(activity.value("type").toString(), name);
}

/*!
 * \brief OMUQDialog::studyChanged
 * Shows the activities and domains of the selected study.
 * \param index
 */
void OMUQDialog::studyChanged(int index)
{
  mpActivityComboBox->clear();
  mpDomainsTreeWidget->clear();
  if (index < 0 || index >= mStudies.size()) {
    return;
  }
  const QJsonObject study = mStudies.at(index).toObject();
  for (const QJsonValue &activity : study.value("activities").toArray()) {
    mpActivityComboBox->addItem(activityLabel(activity.toObject()));
  }
  for (const QJsonValue &value : study.value("domains").toArray()) {
    const QJsonObject domain = value.toObject();
    QStringList axes;
    for (const QJsonValue &axis : domain.value("axes").toArray()) {
      axes << axis.toString();
    }
    QString name = domain.value("id").toString();
    if (!domain.value("name").toString().isEmpty()) {
      name = QString("%1 (%2)").arg(name, domain.value("name").toString());
    }
    const QString geometry = domain.value("geometry").toString();
    mpDomainsTreeWidget->addTopLevelItem(new QTreeWidgetItem({name, domain.value("kind").toString(),
                                                              geometry.isEmpty() ? tr("none") : geometry, axes.join(", ")}));
  }
  mpRunButton->setEnabled(mpActivityComboBox->count() > 0);
}

/*!
 * \brief OMUQDialog::activityChanged
 * Shows what the selected activity observes and uses its grid as the default run settings.
 * \param index
 */
void OMUQDialog::activityChanged(int index)
{
  mpActivityInformationLabel->clear();
  const QJsonArray activities = mStudies.at(mpStudyComboBox->currentIndex()).toObject().value("activities").toArray();
  if (index < 0 || index >= activities.size()) {
    return;
  }
  const QJsonObject activity = activities.at(index).toObject();
  QStringList observed;
  for (const QJsonValue &variable : activity.value("observed").toArray()) {
    observed << variable.toString();
  }
  QString information = tr("Observes: %1").arg(observed.isEmpty() ? tr("nothing") : observed.join(", "));
  information += "\n" + tr("Recorded results: %1").arg(activity.value("results").toInt());
  mpActivityInformationLabel->setText(information);
  // empty fields keep the activity's own grid, show it as the placeholder
  const QJsonValue stopTime = activity.value("stopTime");
  mpStopTimeTextBox->clear();
  mpStopTimeTextBox->setPlaceholderText(stopTime.isDouble() ? QString::number(stopTime.toDouble()) : tr("from the model"));
  const QJsonValue interval = activity.value("interval");
  mpStepSizeTextBox->clear();
  mpStepSizeTextBox->setPlaceholderText(interval.isDouble() ? QString::number(interval.toDouble()) : tr("from the model"));
}

/*!
 * \brief OMUQDialog::browseResultsFile
 * Selects the package the recorded run is saved to.
 */
void OMUQDialog::browseResultsFile()
{
  QString directory = QFileInfo(mpResultsFileTextBox->text()).absolutePath();
  const QString fileName = StringHandler::getSaveFileName(this, QString("%1 - %2").arg(Helper::applicationName, Helper::chooseFile), &directory,
                                                          tr("System Structure and Parameterization Files (*.ssp)"), NULL, "ssp");
  if (!fileName.isEmpty()) {
    mpResultsFileTextBox->setText(fileName);
  }
}

/*!
 * \brief OMUQDialog::runActivity
 * Runs the selected activity in an output tab of the Messages Browser.
 */
void OMUQDialog::runActivity()
{
  if (mpRecordResultsCheckBox->isChecked() && mpResultsFileTextBox->text().trimmed().isEmpty()) {
    QMessageBox::critical(this, QString("%1 - %2").arg(Helper::applicationName, Helper::error), tr("Enter the file the recorded run is saved to."));
    return;
  }
  const QJsonObject study = mStudies.at(mpStudyComboBox->currentIndex()).toObject();
  const QJsonObject activity = study.value("activities").toArray().at(mpActivityComboBox->currentIndex()).toObject();
  OMUQRunOptions options;
  options.mPython = pythonExecutable();
  options.mPackage = mPackage;
  options.mModelName = mpLibraryTreeItem->getNameStructure();
  options.mStudy = mpStudyComboBox->currentIndex();
  options.mActivity = mpActivityComboBox->currentIndex();
  options.mActivityLabel = activityLabel(activity);
  options.mStopTime = mpStopTimeTextBox->text().trimmed();
  options.mStepSize = mpStepSizeTextBox->text().trimmed();
  options.mReportEvery = mpReportEverySpinBox->value();
  options.mDriver = mpDriverComboBox->currentData().toString();
  options.mCsvFile = QString("%1/%2_study%3_activity%4.csv").arg(QFileInfo(mPackage).absolutePath(), options.mModelName)
                     .arg(options.mStudy + 1).arg(options.mActivity + 1);
  options.mResultsFile = mpRecordResultsCheckBox->isChecked() ? mpResultsFileTextBox->text().trimmed() : QString();
  options.mLiveView = static_cast<OMUQRunOptions::LiveView>(mpLiveViewComboBox->currentData().toInt());
  Utilities::getApplicationSettings()->setValue("OMSimulator/omuqLiveView", options.mLiveView);
  // a previous run's samples must not be loaded if this run fails
  QFile::remove(options.mCsvFile);
  OMUQOutputWidget *pOMUQOutputWidget = new OMUQOutputWidget(options);
  MessagesWidget::instance()->addSimulationOutputTab(pOMUQOutputWidget, QString("%1 - %2").arg(options.mModelName, options.mActivityLabel));
  pOMUQOutputWidget->start();
  accept();
}
