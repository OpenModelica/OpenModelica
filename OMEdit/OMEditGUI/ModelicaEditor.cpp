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

#include "ModelicaEditor.h"

ModelicaEditor::ModelicaEditor(ProjectTab *pParent)
    : QTextEdit(pParent)
{
    mpParentProjectTab = pParent;
    connect(this, SIGNAL(focusOut()), mpParentProjectTab, SLOT(ModelicaEditorTextChanged()));
}

QString ModelicaEditor::getModelName()
{
    // read the name from the text
    QTextStream inStream(this->toPlainText().toLatin1());
    while (!inStream.atEnd())
    {
        QString line = inStream.readLine();
        if (line.contains(StringHandler::getModelicaClassType(StringHandler::MODEL).toLower()) or
            line.contains(StringHandler::getModelicaClassType(StringHandler::CLASS).toLower()) or
            line.contains(StringHandler::getModelicaClassType(StringHandler::CONNECTOR).toLower()) or
            line.contains(StringHandler::getModelicaClassType(StringHandler::RECORD).toLower()) or
            line.contains(StringHandler::getModelicaClassType(StringHandler::BLOCK).toLower()) or
            line.contains(StringHandler::getModelicaClassType(StringHandler::FUNCTION).toLower()) or
            line.contains(StringHandler::getModelicaClassType(StringHandler::PACKAGE).toLower()))
        {
            int firstpos = line.indexOf(" ");
            int secondpos = line.indexOf(" ", firstpos);
            return line.mid(firstpos+1, secondpos+1);
        }
    }
    return QString();
}

void ModelicaEditor::focusOutEvent(QFocusEvent *e)
{
    if (document()->isModified())
    {
        // if the user makes few mistakes in the text then dont let him change the perspective
        if (!emit focusOut())
        {
            MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
            QMessageBox *msgBox = new QMessageBox(pMainWindow);
            msgBox->setWindowTitle(QString(Helper::applicationName).append(" - Error"));
            msgBox->setIcon(QMessageBox::Critical);
            msgBox->setText(GUIMessages::getMessage(GUIMessages::ERROR_IN_MODELICA_TEXT)
                            .arg(pMainWindow->mpOMCProxy->getResult()));
            msgBox->setText(msgBox->text().append(GUIMessages::getMessage(GUIMessages::UNDO_OR_FIX_ERRORS)));
            msgBox->addButton(tr("Undo changes"), QMessageBox::AcceptRole);
            msgBox->addButton(tr("Let me fix errors"), QMessageBox::RejectRole);

            int answer = msgBox->exec();

            switch (answer)
            {
            case QMessageBox::AcceptRole:
                document()->setModified(false);
                // revert back to last valid block
                setText(mLastValidText);
                e->accept();
                mpParentProjectTab->showIconView(true);
                break;
            case QMessageBox::RejectRole:
                document()->setModified(true);
                e->ignore();
                setFocus();
                break;
            default:
                // should never be reached
                document()->setModified(true);
                e->ignore();
                setFocus();
                break;
            }
        }
    }
    else
    {
        e->accept();
    }
}
