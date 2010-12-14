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

#ifndef MESSAGEWIDGET_H
#define MESSAGEWIDGET_H

#include <QTabWidget>
#include <QPlainTextEdit>

class MainWindow;
class GeneralMessages;
class InfoMessages;
class WarningMessages;
class ErrorMessages;

class MessageWidget : public QTabWidget
{
    Q_OBJECT
public:
    MessageWidget(MainWindow *pParent = 0);

    MainWindow *mpParentMainWindow;
    GeneralMessages *mpGeneralMessages;
    InfoMessages *mpInfoMessages;
    WarningMessages *mpWarningMessages;
    ErrorMessages *mpErrorMessages;

    void printGUIMessage(QString message);
    void printGUIInfoMessage(QString message);
    void printGUIWarningMessage(QString message);
    void printGUIErrorMessage(QString message);
};

class Messages : public QTextEdit
{
    Q_OBJECT
public:
    Messages(MessageWidget *pParent=0);
    QSize sizeHint() const;
    void printGUIMessage(QString message);

    MessageWidget *mpMessageWidget;
protected:
    int mMessageCounter;
};

class GeneralMessages : public Messages
{
    Q_OBJECT
public:
    GeneralMessages(MessageWidget *pParent=0);
    void printGUIMessage(QString message);
};

class InfoMessages : public Messages
{
    Q_OBJECT
public:
    InfoMessages(MessageWidget *pParent=0);
    void printGUIMessage(QString message);
};

class WarningMessages : public Messages
{
    Q_OBJECT
public:
    WarningMessages(MessageWidget *pParent=0);
    void printGUIMessage(QString message);
};

class ErrorMessages : public Messages
{
    Q_OBJECT
public:
    ErrorMessages(MessageWidget *pParent=0);
    void printGUIMessage(QString message);
};

#endif // MESSAGEWIDGET_H
