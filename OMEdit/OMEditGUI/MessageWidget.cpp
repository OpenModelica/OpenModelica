/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 *
 */

/*
 * HopsanGUI
 * Fluid and Mechatronic Systems, Department of Management and Engineering, Linkoping University
 * Main Authors 2009-2010:  Robert Braun, Bjorn Eriksson, Peter Nordin
 * Contributors 2009-2010:  Mikael Axin, Alessandro Dell'Amico, Karl Pettersson, Ingo Staack
 */

#include "MessageWidget.h"
#include "mainwindow.h"

//! @class MessageWidget
//! @brief It creates a tab based messages window.
//! It contains three tabs four tabs General, Info, Warning and Error.

//! Constructor
//! @param pParent defines a parent to the new instanced object. pParent is the MainWindow object.
MessageWidget::MessageWidget(MainWindow *pParent)
    : QTabWidget(pParent)
{
    mpParentMainWindow = pParent;
    // creates general messages window
    mpGeneralMessages = new GeneralMessages(this);
    addTab(mpGeneralMessages, QString("General"));
    // creates info messages window
    mpInfoMessages = new InfoMessages(this);
    addTab(mpInfoMessages, QString("Info"));
    // creates warning messages window
    mpWarningMessages = new WarningMessages(this);
    addTab(mpWarningMessages, QString("Warning"));
    // creates error messages window
    mpErrorMessages = new ErrorMessages(this);
    addTab(mpErrorMessages, QString("Error"));

    setObjectName(tr("MessagesTab"));
}

//! Calls the GeneralMessage::printGUIMessage
//! @param message is the string that is passed.
void MessageWidget::printGUIMessage(QString message)
{
    mpGeneralMessages->printGUIMessage(message);
}

//! Calls the InfoMessage::printGUIMessage
//! @param message is the string that is passed.
void MessageWidget::printGUIInfoMessage(QString message)
{
    mpInfoMessages->printGUIMessage(message);
}

//! Calls the WarningMessage::printGUIMessage
//! @param message is the string that is passed.
void MessageWidget::printGUIWarningMessage(QString message)
{
    mpWarningMessages->printGUIMessage(message);
}

//! Calls the ErrorMessage::printGUIMessage
//! @param message is the string that is passed.
void MessageWidget::printGUIErrorMessage(QString message)
{
    mpErrorMessages->printGUIMessage(message);
}

//! @class Messages
//! @brief It is the base class for all types of messages.

//! Constructor
//! @param pParent defines a parent to the new instanced object. pParent is the MessageWidget object.
Messages::Messages(MessageWidget *pParent)
    : QTextEdit(pParent), mMessageCounter(0)
{
    setReadOnly(true);
    setObjectName(tr("MessagesTextBox"));

    mpMessageWidget = pParent;
}

//! Reimplementation of sizeHint function. Defines the minimum height for QTextEdit.
QSize Messages::sizeHint() const
{
    QSize size = QTextEdit::sizeHint();
    //Set very small height. A minimum apperantly stops at resonable size.
    size.rheight() = 100; //pixels
    return size;
}

//! Displays the message.
//! @param message is the string that is displayed.
void Messages::printGUIMessage(QString message)
{
    append(message + tr("\n"));
    mpMessageWidget->setCurrentWidget(this);
}

//! @class GeneralMessages
//! @brief This class is inherited from Messages. It is used to display general messages.

//! Constructor
//! @param pParent defines a parent to the new instanced object. pParent is the MessageWidget object.
GeneralMessages::GeneralMessages(MessageWidget *pParent)
    : Messages(pParent)
{
    setTextColor("BLACK");
}

//! Reimplementation of Messages::printGUIMessage function.
void GeneralMessages::printGUIMessage(QString message)
{
    append(message);
}

//! @class InfoMessages
//! @brief This class is inherited from Messages. It is used to display info messages.

//! Constructor
//! @param pParent defines a parent to the new instanced object. pParent is the MessageWidget object.
InfoMessages::InfoMessages(MessageWidget *pParent)
    : Messages(pParent)
{
    setTextColor("GREEN");
}

//! Reimplementation of Messages::printGUIMessage function.
void InfoMessages::printGUIMessage(QString message)
{
    mMessageCounter++;
    append(QString("---- Info ").append(QString::number(mMessageCounter)).append(" : ")
           .append(QTime::currentTime().toString()).append(" ----"));

    Messages::printGUIMessage(message);
}

//! @class WarningMessages
//! @brief This class is inherited from Messages. It is used to display warning messages.

//! Constructor
//! @param pParent defines a parent to the new instanced object. pParent is the MessageWidget object.
WarningMessages::WarningMessages(MessageWidget *pParent)
    : Messages(pParent)
{
    setTextColor("ORANGE");
}

//! Reimplementation of Messages::printGUIMessage function.
void WarningMessages::printGUIMessage(QString message)
{
    mMessageCounter++;
    append(QString("---- Warning ").append(QString::number(mMessageCounter)).append(" : ")
           .append(QTime::currentTime().toString()).append(" ----"));

    Messages::printGUIMessage(message);
}

//! @class ErrorMessages
//! @brief This class is inherited from Messages. It is used to display error messages.

//! Constructor
//! @param pParent defines a parent to the new instanced object. pParent is the MessageWidget object.
ErrorMessages::ErrorMessages(MessageWidget *pParent)
    : Messages(pParent)
{
    setTextColor("RED");
}

//! Reimplementation of Messages::printGUIMessage function.
void ErrorMessages::printGUIMessage(QString message)
{
    mMessageCounter++;
    append(QString("---- Error ").append(QString::number(mMessageCounter)).append(" : ")
           .append(QTime::currentTime().toString()).append(" ----"));

    Messages::printGUIMessage(message);
}
