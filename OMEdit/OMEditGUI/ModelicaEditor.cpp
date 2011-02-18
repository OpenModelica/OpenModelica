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
    setObjectName(tr("ModelicaEditor"));
    // depending on the project tab readonly state set the text view readonly state
    setReadOnly(mpParentProjectTab->isReadOnly());
    connect(this, SIGNAL(focusOut()), mpParentProjectTab, SLOT(modelicaEditorTextChanged()));

    mpFindWidget = new QWidget;
    mpFindWidget->setContentsMargins(0, 0, 0, 0);
    mpFindWidget->hide();

    mpSearchLabelImage = new QLabel;
    mpSearchLabelImage->setPixmap(QPixmap(":/Resources/icons/search.png"));
    mpSearchLabel = new QLabel(tr("Search"));
    mpSearchTextBox = new QLineEdit;
    connect(mpSearchTextBox, SIGNAL(textChanged(QString)), SLOT(updateButtons()));
    connect(mpSearchTextBox, SIGNAL(returnPressed()), SLOT(findNextText()));

    mpPreviuosButton = new QToolButton;
    mpPreviuosButton->setAutoRaise(true);
    mpPreviuosButton->setText(tr("Previous"));
    mpPreviuosButton->setIcon(QIcon(":/Resources/icons/previous.png"));
    mpPreviuosButton->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
    connect(mpPreviuosButton, SIGNAL(clicked()), SLOT(findPreviuosText()));

    mpNextButton = new QToolButton;
    mpNextButton->setAutoRaise(true);
    mpNextButton->setText(tr("Next"));
    mpNextButton->setIcon(QIcon(":/Resources/icons/next.png"));
    mpNextButton->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
    connect(mpNextButton, SIGNAL(clicked()), SLOT(findNextText()));

    mpMatchCaseCheckBox = new QCheckBox(tr("Match case"));
    mpMatchWholeWordCheckBox = new QCheckBox(tr("Match whole word"));

    mpCloseButton = new QToolButton;
    mpCloseButton->setAutoRaise(true);
    mpCloseButton->setIcon(QIcon(":/Resources/icons/exit.png"));
    connect(mpCloseButton, SIGNAL(clicked()), SLOT(hideFindWidget()));

    // make previous and next buttons disabled for first time
    updateButtons();
}

QString ModelicaEditor::getModelName()
{
    // read the name from the text
    OMCProxy *omc = new OMCProxy(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow, false);
    QString modelName = QString();
    if (omc->saveModifiedModel(this->toPlainText()))
        modelName = StringHandler::removeFirstLastCurlBrackets(omc->getResult());
    else
        mErrorString = omc->getResult();
    omc->stopServer();
    return modelName;
}

void ModelicaEditor::findText(const QString &text, bool forward)
{
    QTextCursor currentTextCursor = textCursor();
    QTextDocument::FindFlags options;

    if (currentTextCursor.hasSelection())
    {
        currentTextCursor.setPosition(forward ? currentTextCursor.position() : currentTextCursor.anchor(),
                                      QTextCursor::MoveAnchor);
    }

    if (!forward)
        options |= QTextDocument::FindBackward;

    if (mpMatchCaseCheckBox->isChecked())
        options |= QTextDocument::FindCaseSensitively;

    if (mpMatchWholeWordCheckBox->isChecked())
        options |= QTextDocument::FindWholeWords;

    bool found = true;
    QTextCursor newTextCursor = document()->find(text, currentTextCursor, options);
    if (newTextCursor.isNull())
    {
        QTextCursor ac(document());
        ac.movePosition(options & QTextDocument::FindBackward ? QTextCursor::End : QTextCursor::Start);
        newTextCursor = document()->find(text, ac, options);
        if (newTextCursor.isNull())
        {
            found = false;
            newTextCursor = currentTextCursor;
        }
    }
    setTextCursor(newTextCursor);

    if (mpSearchTextBox->text().isEmpty())
        found = true;

    if (!found)
    {
        QMessageBox::information(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow,
                                 Helper::applicationName + " - Information",
                                 GUIMessages::getMessage(GUIMessages::SEARCH_STRING_NOT_FOUND).arg(text), "OK");
    }
}

bool ModelicaEditor::validateText()
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
                return true;
            case QMessageBox::RejectRole:
                document()->setModified(true);
                return false;
            default:
                // should never be reached
                document()->setModified(true);
                return false;
            }
        }
        else
        {
            document()->setModified(false);
        }
    }
    return true;
}

void ModelicaEditor::hideFindWidget()
{
    mpFindWidget->hide();
}

void ModelicaEditor::updateButtons()
{
    const bool enable = !mpSearchTextBox->text().isEmpty();
    mpPreviuosButton->setEnabled(enable);
    mpNextButton->setEnabled(enable);
}

void ModelicaEditor::findNextText()
{
    findText(mpSearchTextBox->text(), true);
}

void ModelicaEditor::findPreviuosText()
{
    findText(mpSearchTextBox->text(), false);
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

    mQuotesExpression = QRegExp("\"");
    mCommentStartExpression = QRegExp("/\\*");
    mCommentEndExpression = QRegExp("\\*/");
}

void ModelicaTextHighlighter::highlightMultiLine(const QString &text, QRegExp &startExpression, QRegExp &endExpression,
                                                 QTextCharFormat &format)
{
    int startIndex = 0;
    if (previousBlockState() != 1)
        startIndex = startExpression.indexIn(text);

    while (startIndex >= 0)
    {
        int endIndex = endExpression.indexIn(text, startIndex);
        int textLength;
        if (endIndex == -1)
        {
            setCurrentBlockState(1);
            textLength = text.length() - startIndex;
        }
        else
        {
            textLength = endIndex - startIndex + endExpression.matchedLength();
        }
        setFormat(startIndex, textLength, format);
        startIndex = startExpression.indexIn(text, startIndex + textLength);
    }
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
    highlightMultiLine(text, mCommentStartExpression, mCommentEndExpression, mMultiLineCommentFormat);
//    setCurrentBlockState(0);
//    highlightMultiLine(text, mQuotesExpression, mQuotesExpression, mQuotationFormat);
}

void ModelicaTextHighlighter::settingsChanged()
{
    initializeSettings();
    rehighlight();
}
