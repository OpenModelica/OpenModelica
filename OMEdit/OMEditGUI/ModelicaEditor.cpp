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
    setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
    setTabStopWidth(Helper::tabWidth);
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
    QTextEdit::focusOutEvent(e);
//    if (document()->isModified())
//    {
//        // if the user makes few mistakes in the text then dont let him change the perspective
//        if (!emit focusOut())
//        {
//            MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
//            QMessageBox *msgBox = new QMessageBox(pMainWindow);
//            msgBox->setWindowTitle(QString(Helper::applicationName).append(" - Error"));
//            msgBox->setIcon(QMessageBox::Critical);
//            msgBox->setText(GUIMessages::getMessage(GUIMessages::ERROR_IN_MODELICA_TEXT)
//                            .arg(pMainWindow->mpOMCProxy->getResult()));
//            msgBox->setText(msgBox->text().append(GUIMessages::getMessage(GUIMessages::UNDO_OR_FIX_ERRORS)));
//            msgBox->addButton(tr("Undo changes"), QMessageBox::AcceptRole);
//            msgBox->addButton(tr("Let me fix errors"), QMessageBox::RejectRole);

//            int answer = msgBox->exec();

//            switch (answer)
//            {
//            case QMessageBox::AcceptRole:
//                document()->setModified(false);
//                // revert back to last valid block
//                setText(mLastValidText);
//                e->accept();
//                mpParentProjectTab->showIconView(true);
//                break;
//            case QMessageBox::RejectRole:
//                document()->setModified(true);
//                e->ignore();
//                setFocus();
//                break;
//            default:
//                // should never be reached
//                document()->setModified(true);
//                e->ignore();
//                setFocus();
//                break;
//            }
//        }
//        else
//        {
//            qDebug() << "going back";
//            e->accept();
//        }
//    }
//    else
//    {
//        e->accept();
//    }
}

ModelicaTextHighlighter::ModelicaTextHighlighter(ModelicaTextSettings *pSettings, QTextDocument *pParent)
    : QSyntaxHighlighter(pParent)
{
    mpModelicaTextSettings = pSettings;
    initializeSettings();
}

void ModelicaTextHighlighter::initializeSettings()
{
    QTextDocument *textDocument = dynamic_cast<QTextDocument*>(this->parent());
    textDocument->setDefaultFont(QFont(mpModelicaTextSettings->getFontFamily(),
                                       mpModelicaTextSettings->getFontSize()));

    mHighlightingRules.clear();
    HighlightingRule rule;

    mKeywordFormat.setForeground(mpModelicaTextSettings->getKeywordRuleColor());
    QStringList keywordPatterns;
    keywordPatterns << "\\balgorithm\\b" << "\\band\\b" << "\\bannotation\\b" << "\\bassert\\b" << "\\bbreak\\b"
                    << "\\bBoolean\\b" << "\\bconnect\\b" <<"\\bconstant\\b" << "\\bconstrainedby\\b" << "\\bder\\b" << "\\bdiscrete\\b"
                    << "\\beach\\b" << "\\belse\\b" << "\\belseif\\b" "\\belsewhen\\b" << "\\bencapsulated\\b"
                    << "\\bend\\b" << "\\benumeration\\b" << "\\bequation\\b" << "\\bexpandable\\b" << "\\bextends\\b"
                    << "\\bexternal\\b" << "\\bfalse\\b" << "\\bfinal\\b" << "\\bflow\\b" << "\\bfor\\b"
                    << "\\bif\\b" << "\\bimport\\b" << "\\bin\\b" << "\\binitial\\b" << "\\binner\\b" << "\\binput\\b"
                    << "\\bloop\\b" << "\\bnot\\b" << "\\boperator\\b" << "\\bor\\b" << "\\bouter\\b"
                    << "\\boutput\\b" << "\\bpartial\\b" << "\\bpublic\\b" << "\\bReal\\b" << "\\bredeclare\\b"
                    << "\\breplaceable\\b" << "\\breturn\\b" << "\\bstream\\b" << "\\bthen\\b" << "\\btrue\\b"
                    << "\\bwhen\\b" << "\\bwhile\\b" << "\\bwithin\\b";
    foreach (const QString &pattern, keywordPatterns)
    {
        rule.mPattern = QRegExp(pattern);
        rule.mFormat = mKeywordFormat;
        mHighlightingRules.append(rule);
    }

    mTypeFormat.setForeground(mpModelicaTextSettings->getTypeRuleColor());
    QStringList typePatterns;
    typePatterns << "\\b" + StringHandler::getModelicaClassType(StringHandler::MODEL).toLower() + "\\b"
                 << "\\b" + StringHandler::getModelicaClassType(StringHandler::CLASS).toLower() + "\\b"
                 << "\\b" + StringHandler::getModelicaClassType(StringHandler::CONNECTOR).toLower() + "\\b"
                 << "\\b" + StringHandler::getModelicaClassType(StringHandler::RECORD).toLower() + "\\b"
                 << "\\b" + StringHandler::getModelicaClassType(StringHandler::BLOCK).toLower() + "\\b"
                 << "\\b" + StringHandler::getModelicaClassType(StringHandler::FUNCTION).toLower() + "\\b"
                 << "\\b" + StringHandler::getModelicaClassType(StringHandler::PACKAGE).toLower() + "\\b"
                 << "\\b" + StringHandler::getModelicaClassType(StringHandler::PRIMITIVE).toLower() + "\\b"
                 << "\\b" + StringHandler::getModelicaClassType(StringHandler::TYPE).toLower() + "\\b"
                 << "\\b" + StringHandler::getModelicaClassType(StringHandler::PARAMETER).toLower() + "\\b"
                 << "\\b" + StringHandler::getModelicaClassType(StringHandler::CONSTANT).toLower() + "\\b"
                 << "\\b" + StringHandler::getModelicaClassType(StringHandler::PROTECTED).toLower() + "\\b";
    foreach (const QString &pattern, typePatterns)
    {
        rule.mPattern = QRegExp(pattern);
        rule.mFormat = mTypeFormat;
        mHighlightingRules.append(rule);
    }

    mSingleLineCommentFormat.setForeground(mpModelicaTextSettings->getCommentRuleColor());
    rule.mPattern = QRegExp("//[^\n]*");
    rule.mFormat = mSingleLineCommentFormat;
    mHighlightingRules.append(rule);

    mMultiLineCommentFormat.setForeground(mpModelicaTextSettings->getCommentRuleColor());

    mFunctionFormat.setForeground(mpModelicaTextSettings->getFunctionRuleColor());
    rule.mPattern = QRegExp("\\b[A-Za-z0-9_]+(?=\\()");
    rule.mFormat = mFunctionFormat;
    mHighlightingRules.append(rule);

    mQuotationFormat.setForeground(QColor(mpModelicaTextSettings->getQuotesRuleColor()));
    rule.mPattern = QRegExp("\".*\"");
    rule.mFormat = mQuotationFormat;
    mHighlightingRules.append(rule);

    mCommentStartExpression = QRegExp("/\\*");
    mCommentEndExpression = QRegExp("\\*/");
}

void ModelicaTextHighlighter::highlightBlock(const QString &text)
{
    setFormat(0, text.length(), mpModelicaTextSettings->getTextRuleColor());
    foreach (const HighlightingRule &rule, mHighlightingRules)
    {
        QRegExp expression(rule.mPattern);
        int index = expression.indexIn(text);
        while (index >= 0)
        {
            int length = expression.matchedLength();
            setFormat(index, length, rule.mFormat);
            index = expression.indexIn(text, index + length);
        }
    }
    setCurrentBlockState(0);

    int startIndex = 0;
    if (previousBlockState() != 1)
    startIndex = mCommentStartExpression.indexIn(text);

    while (startIndex >= 0)
    {
        int endIndex = mCommentEndExpression.indexIn(text, startIndex);
        int commentLength;
        if (endIndex == -1)
        {
            setCurrentBlockState(1);
            commentLength = text.length() - startIndex;
        }
        else
        {
            commentLength = endIndex - startIndex + mCommentEndExpression.matchedLength();
        }
        setFormat(startIndex, commentLength, mMultiLineCommentFormat);
        startIndex = mCommentStartExpression.indexIn(text, startIndex + commentLength);
    }
}

void ModelicaTextHighlighter::settingsChanged()
{
    initializeSettings();
    rehighlight();
}
