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

#ifndef FMIGUIDEDIALOG_H
#define FMIGUIDEDIALOG_H

#include <QDialog>
#include <QJsonArray>
#include <QJsonObject>
#include <QList>

class QAbstractButton;
class QButtonGroup;
class QLabel;
class QPushButton;
class QVBoxLayout;

/*!
 * \class FMIGuideDialog
 * \brief Asks how an FMU is used and recommends the export settings.
 */
class FMIGuideDialog : public QDialog
{
  Q_OBJECT
public:
  FMIGuideDialog(const QJsonObject &host, QWidget *pParent = 0);
  QJsonObject values() const {return mValues;}
private:
  struct Question
  {
    QJsonObject input;
    QLabel *pLabel;
    QLabel *pNoteLabel;
    QButtonGroup *pButtonGroup;
    QList<QAbstractButton*> buttons;
  };
  static QJsonObject mAnswers;
  QJsonObject mHost;
  QJsonObject mModel;
  QJsonObject mValues;
  QList<Question> mQuestions;
  bool mSynchronizing;
  QVBoxLayout *mpQuestionsLayout;
  QLabel *mpResultLabel;
  QPushButton *mpApplyButton;
  void createQuestions(const QJsonArray &asked);
  void refresh();
  QJsonObject setting(const QString &id) const;
  QString optionLabel(const QString &settingId, const QString &value) const;
private slots:
  void answerChanged();
};

#endif // FMIGUIDEDIALOG_H
