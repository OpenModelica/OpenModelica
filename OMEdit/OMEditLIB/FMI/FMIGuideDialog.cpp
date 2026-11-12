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

#include "FMIGuideDialog.h"
#include "FMIGuide.h"
#include "Util/Helper.h"

#include <QButtonGroup>
#include <QCheckBox>
#include <QDialogButtonBox>
#include <QHBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QRadioButton>
#include <QScrollArea>
#include <QVBoxLayout>

QJsonObject FMIGuideDialog::mAnswers;

static QJsonObject findById(const QJsonArray &items, const char *key, const QString &id)
{
  foreach (const QJsonValue &item, items) {
    if (item.toObject().value(key).toString() == id) {
      return item.toObject();
    }
  }
  return QJsonObject();
}

/*!
 * \brief FMIGuideDialog::FMIGuideDialog
 * \param host - what the caller can export: {name, offers: {setting: [options]}, applies: [setting]}.
 * \param pParent
 */
FMIGuideDialog::FMIGuideDialog(const QJsonObject &host, QWidget *pParent)
  : QDialog(pParent), mHost(host), mSynchronizing(false)
{
  setWindowTitle(QString("%1 - %2").arg(Helper::applicationName, tr("Recommend FMU Settings")));
  resize(940, 660);
  mModel = FMIGuide::call(QJsonObject{{"op", "model"}}).value("model").toObject();
  // questions
  QWidget *pQuestionsWidget = new QWidget;
  mpQuestionsLayout = new QVBoxLayout(pQuestionsWidget);
  mpQuestionsLayout->setAlignment(Qt::AlignTop);
  QScrollArea *pQuestionsScrollArea = new QScrollArea;
  pQuestionsScrollArea->setWidgetResizable(true);
  pQuestionsScrollArea->setWidget(pQuestionsWidget);
  // recommendation
  mpResultLabel = new QLabel;
  mpResultLabel->setTextFormat(Qt::RichText);
  mpResultLabel->setWordWrap(true);
  mpResultLabel->setAlignment(Qt::AlignTop | Qt::AlignLeft);
  mpResultLabel->setMargin(8);
  QScrollArea *pResultScrollArea = new QScrollArea;
  pResultScrollArea->setWidgetResizable(true);
  pResultScrollArea->setWidget(mpResultLabel);
  // buttons
  mpApplyButton = new QPushButton(Helper::apply);
  QDialogButtonBox *pButtonBox = new QDialogButtonBox;
  pButtonBox->addButton(mpApplyButton, QDialogButtonBox::AcceptRole);
  pButtonBox->addButton(new QPushButton(Helper::cancel), QDialogButtonBox::RejectRole);
  connect(pButtonBox, SIGNAL(accepted()), SLOT(accept()));
  connect(pButtonBox, SIGNAL(rejected()), SLOT(reject()));
  // layout
  QHBoxLayout *pColumnsLayout = new QHBoxLayout;
  pColumnsLayout->addWidget(pQuestionsScrollArea, 1);
  pColumnsLayout->addWidget(pResultScrollArea, 1);
  QVBoxLayout *pMainLayout = new QVBoxLayout;
  pMainLayout->addLayout(pColumnsLayout);
  pMainLayout->addWidget(pButtonBox);
  setLayout(pMainLayout);
  refresh();
}

/*!
 * \brief FMIGuideDialog::createQuestions
 * \param asked - the ids of the questions that can change a setting of the host.
 */
void FMIGuideDialog::createQuestions(const QJsonArray &asked)
{
  foreach (const QJsonValue &group, mModel.value("inputGroups").toArray()) {
    bool heading = false;
    foreach (const QJsonValue &inputValue, mModel.value("inputs").toArray()) {
      const QJsonObject input = inputValue.toObject();
      const QString id = input.value("id").toString();
      if (input.value("group") != group.toObject().value("id") || !asked.contains(id)) {
        continue;
      }
      if (!heading) {
        QLabel *pHeadingLabel = new QLabel(FMIGuide::translate(group.toObject().value("label").toString()).toUpper());
        pHeadingLabel->setEnabled(false);
        mpQuestionsLayout->addSpacing(mQuestions.isEmpty() ? 0 : 10);
        mpQuestionsLayout->addWidget(pHeadingLabel);
        heading = true;
      }
      Question question;
      question.input = input;
      question.pLabel = new QLabel(FMIGuide::translate(input.value("label").toString()));
      question.pLabel->setWordWrap(true);
      QFont font = question.pLabel->font();
      font.setBold(true);
      question.pLabel->setFont(font);
      mpQuestionsLayout->addWidget(question.pLabel);
      const bool multi = input.value("type").toString() == "multi";
      question.pButtonGroup = new QButtonGroup(this);
      question.pButtonGroup->setExclusive(!multi);
      foreach (const QJsonValue &option, input.value("options").toArray()) {
        const QString text = FMIGuide::translate(option.toObject().value("label").toString());
        QAbstractButton *pButton = multi ? static_cast<QAbstractButton*>(new QCheckBox(text)) : new QRadioButton(text);
        pButton->setProperty("input", id);
        pButton->setProperty("value", option.toObject().value("value").toString());
        question.pButtonGroup->addButton(pButton);
        question.buttons.append(pButton);
        connect(pButton, SIGNAL(clicked()), SLOT(answerChanged()));
        mpQuestionsLayout->addWidget(pButton);
      }
      question.pNoteLabel = new QLabel;
      question.pNoteLabel->setWordWrap(true);
      question.pNoteLabel->setEnabled(false);
      mpQuestionsLayout->addWidget(question.pNoteLabel);
      mQuestions.append(question);
    }
  }
}

QJsonObject FMIGuideDialog::setting(const QString &id) const
{
  return findById(mModel.value("settings").toArray(), "id", id);
}

QString FMIGuideDialog::optionLabel(const QString &settingId, const QString &value) const
{
  return FMIGuide::translate(findById(setting(settingId).value("options").toArray(), "value", value).value("label").toString());
}

/*!
 * \brief FMIGuideDialog::refresh
 * Asks omc for the advice and shows it.
 */
void FMIGuideDialog::refresh()
{
  const QJsonObject reply = FMIGuide::call(QJsonObject{{"op", "advise"}, {"answers", mAnswers}, {"host", mHost}});
  if (!reply.value("ok").toBool()) {
    mpResultLabel->setText(reply.value("error").toString().toHtmlEscaped());
    mpApplyButton->setEnabled(false);
    return;
  }
  if (mQuestions.isEmpty()) {
    createQuestions(reply.value("asked").toArray());
  }
  const QJsonObject today = reply.value("today").toObject();
  // the answers, and which of them are possible
  mSynchronizing = true;
  foreach (const Question &question, mQuestions) {
    const QJsonObject state = today.value("inputs").toObject().value(question.input.value("id").toString()).toObject();
    const bool enabled = state.value("enabled").toBool();
    const QJsonValue value = state.value("value");
    question.pLabel->setEnabled(enabled);
    question.pButtonGroup->setExclusive(false);
    foreach (QAbstractButton *pButton, question.buttons) {
      const QString option = pButton->property("value").toString();
      const bool possible = enabled && state.value("options").toObject().value(option).toBool();
      pButton->setEnabled(possible);
      pButton->setChecked(possible && (value.isArray() ? value.toArray().contains(option) : value.toString() == option));
    }
    question.pButtonGroup->setExclusive(question.input.value("type").toString() != "multi");
    const QString note = question.input.value(enabled ? "help" : "disabledNote").toString();
    question.pNoteLabel->setText(FMIGuide::translate(note));
    question.pNoteLabel->setVisible(!note.isEmpty());
  }
  mSynchronizing = false;
  // the recommendation
  const QString hostName = mHost.value("name").toString();
  const QJsonArray applies = mHost.value("applies").toArray();
  QStringList blocked, rows;
  mValues = QJsonObject();
  foreach (const QJsonValue &settingValue, today.value("settings").toArray()) {
    const QJsonObject result = settingValue.toObject();
    const QString id = result.value("id").toString();
    const QString label = FMIGuide::translate(setting(id).value("label").toString());
    if (result.value("blocked").toBool()) {
      foreach (const QJsonValue &option, result.value("options").toArray()) {
        const QJsonArray excludedBy = option.toObject().value("excludedBy").toArray();
        if (option.toObject().value("support").toObject().value("available").toBool() && !excludedBy.isEmpty()) {
          blocked.append(QString("%1, %2: %3").arg(label, optionLabel(id, option.toObject().value("value").toString()),
                                                   FMIGuide::translate(excludedBy.first().toObject().value("because").toString())).toHtmlEscaped());
        }
      }
      if (blocked.isEmpty()) {
        blocked.append(label.toHtmlEscaped());
      }
      continue;
    }
    if (!result.value("relevant").toBool() || !applies.contains(id)) {
      continue;
    }
    const QString pick = result.value("pick").toString();
    mValues.insert(id, pick);
    const QJsonObject option = findById(result.value("options").toArray(), "value", pick);
    QStringList notes;
    QJsonObject why;
    foreach (const QJsonValue &reason, option.value("reasons").toArray()) {
      if (reason.toObject().value("points").toInt() > why.value("points").toInt()) {
        why = reason.toObject();
      }
    }
    if (!why.isEmpty()) {
      notes.append(FMIGuide::translate(why.value("because").toString()));
    } else if (!result.value("displaced").toArray().isEmpty()) {
      const QString other = result.value("displaced").toArray().first().toString();
      const QJsonObject otherOption = findById(result.value("options").toArray(), "value", other);
      notes.append(QString("%1: %2").arg(optionLabel(id, other),
                                         FMIGuide::translate(otherOption.value("excludedBy").toArray().first().toObject().value("because").toString())));
    }
    const QString supportNote = option.value("support").toObject().value("note").toString();
    if (!supportNote.isEmpty()) {
      notes.append(FMIGuide::translate(supportNote));
    }
    foreach (const QJsonValue &gap, reply.value("gaps").toArray()) {
      if (gap.toObject().value("setting").toString() == id) {
        const QString ideal = gap.toObject().value("ideal").toString();
        const QJsonObject idealSetting = findById(reply.value("ideal").toObject().value("settings").toArray(), "id", id);
        const QJsonObject support = findById(idealSetting.value("options").toArray(), "value", ideal).value("support").toObject();
        const QString why = support.value("offered").toBool() ? FMIGuide::translate(support.value("note").toString())
                                                              : tr("Not available in %1.").arg(hostName);
        notes.append(tr("Would fit better: %1.").arg(optionLabel(id, ideal)) + " " + why);
      }
    }
    QString row = QString("<p>%1<br><b>%2</b>").arg(label.toHtmlEscaped(), optionLabel(id, pick).toHtmlEscaped());
    foreach (const QString &note, notes) {
      row += "<br><small>" + note.toHtmlEscaped() + "</small>";
    }
    rows.append(row + "</p>");
  }
  QString html;
  if (!blocked.isEmpty()) {
    html = QString("<p><b>%1</b></p><p>%2</p>").arg(tr("No FMU from %1 fits these answers").arg(hostName).toHtmlEscaped(), blocked.join("<br>"));
  } else {
    html = rows.join("");
    foreach (const QJsonValue &note, today.value("notes").toArray()) {
      const bool warning = note.toObject().value("level").toString() == "warn";
      html += QString("<p>%1%2</p>").arg(warning ? QString("<b>%1</b> ").arg(tr("Check:").toHtmlEscaped()) : QString(),
                                          FMIGuide::translate(note.toObject().value("text").toString()).toHtmlEscaped());
    }
  }
  mpResultLabel->setText(html);
  mpApplyButton->setEnabled(blocked.isEmpty());
}

/*!
 * \brief FMIGuideDialog::answerChanged
 * Reads the answer of the question whose button was clicked.
 */
void FMIGuideDialog::answerChanged()
{
  if (mSynchronizing) {
    return;
  }
  foreach (const Question &question, mQuestions) {
    if (!question.buttons.contains(qobject_cast<QAbstractButton*>(sender()))) {
      continue;
    }
    QJsonArray checked;
    foreach (QAbstractButton *pButton, question.buttons) {
      if (pButton->isChecked()) {
        checked.append(pButton->property("value").toString());
      }
    }
    const bool multi = question.input.value("type").toString() == "multi";
    mAnswers.insert(question.input.value("id").toString(), multi ? QJsonValue(checked) : checked.first());
  }
  refresh();
}
