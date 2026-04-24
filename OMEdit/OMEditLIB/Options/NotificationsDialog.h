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

#ifndef NOTIFICATIONSDIALOG_H
#define NOTIFICATIONSDIALOG_H

#include <QDialog>
#include <QCheckBox>
#include <QDialogButtonBox>

class Label;
class NotificationsDialog : public QDialog
{
  Q_OBJECT
public:
  enum NotificationType {
    QuitApplication,
    ItemDroppedOnItself,
    ReplaceableIfPartial,
    InnerModelNameChanged,
    SaveModelForBitmapInsertion,
    RevertPreviousOrFixErrorsManually
  };
  enum NotificationIcon {NoIcon, QuestionIcon, InformationIcon, WarningIcon, CriticalIcon};
  NotificationsDialog(NotificationType notificationType, NotificationIcon notificationIcon, QWidget *pParent = 0);
  void setNotificationLabelString(QString label);
  QCheckBox* getNotificationCheckBox() {return mpNotificationCheckBox;}
  QPushButton* getOkButton() {return mpOkButton;}
  QPushButton* getCancelButton() {return mpCancelButton;}
  QPushButton *getSaveWithErrorsButton() const {return mpSaveWithErrorsButton;}
  QDialogButtonBox* getButtonBox() {return mpButtonBox;}
private:
  Label *mpNotificationLabel;
  QCheckBox *mpNotificationCheckBox;
  QPushButton *mpOkButton;
  QPushButton *mpCancelButton;
  QPushButton *mpSaveWithErrorsButton;
  QDialogButtonBox *mpButtonBox;
  NotificationType mNotificationType;
  QPixmap getNotificationIcon(NotificationIcon notificationIcon);
  QString getNotificationTitleString();
  QString getNotificationLabelString();
  QString getNotificationCheckBoxString();
  void saveQuitNotificationSettings();
  void saveItemDroppedOnItselfNotificationSettings();
  void saveReplaceableIfPartialNotificationSettings();
  void saveInnerModelNameChangedNotificationSettings();
  void saveModelForBitmapInsertionNotificationSettings();
  void saveAlwaysAskForTextEditorErrorSettings();
private slots:
  void saveNotification();
  void rejectNotification();
  void saveWithErrors();
};

#endif // NOTIFICATIONSDIALOG_H
