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

#ifndef CRASHREPORTDIALOG_H
#define CRASHREPORTDIALOG_H

#include <QtGlobal>
#include <QNetworkReply>
#include <QHttpMultiPart>

#include "Util/Utilities.h"

#include <QDialog>
#include <QDialogButtonBox>
#include <QProgressBar>

class CrashReportDialog : public QDialog
{
  Q_OBJECT
public:
  /*!
   * \enum CrashSource
   * Describes what the dialog is reporting so we can use the right wording and
   * decide whether a backtrace needs to be captured.
   */
  enum CrashSource {
    ReportIssue,    /* manual Help->Report Issue; nothing crashed */
    LiveCrash,      /* shown by the crash-reporter sub-process right after a crash */
    PreviousCrash   /* shown at the next startup because an earlier session crashed */
  };
  CrashReportDialog(QString stacktrace, CrashSource source = LiveCrash);
private:
  CrashSource mSource;
  QString mStackTrace;
  Label *mpCrashReportHeading;
  QFrame *mpHorizontalLine;
  Label *mpEmailLabel;
  QLineEdit *mpEmailTextBox;
  Label *mpBugDescriptionLabel;
  QPlainTextEdit *mpBugDescriptionTextBox;
  Label *mpFilesDescriptionLabel;
  QCheckBox *mpOMEditCommunicationLogFileCheckBox;
  QCheckBox *mpOMEditCommandsMosFileCheckBox;
  QCheckBox *mpOMStackTraceFileCheckBox;
  QPushButton *mpSendReportButton;
  QPushButton *mpCancelButton;
  QDialogButtonBox *mpButtonBox;
  Label *mpProgressLabel;

  void createGDBBacktrace();
public slots:
  void sendReport();
  void reportSent(QNetworkReply *pNetworkReply);
};

#endif // CRASHREPORTDIALOG_H
