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

#ifndef MODELICAEDITOR_H
#define MODELICAEDITOR_H

#include "ProjectTabWidget.h"

class ProjectTab;

class ModelicaEditor : public QTextEdit
{
    Q_OBJECT
public:
    ModelicaEditor(ProjectTab *pParent);
    QString getModelName();
    void findText(const QString &text, bool forward);
    bool validateText();

    ProjectTab *mpParentProjectTab;
    QString mLastValidText;
    QString mErrorString;
    QWidget *mpFindWidget;
    QLabel *mpSearchLabelImage;
    QLabel *mpSearchLabel;
    QLineEdit *mpSearchTextBox;
    QToolButton *mpPreviuosButton;
    QToolButton *mpNextButton;
    QCheckBox *mpMatchCaseCheckBox;
    QCheckBox *mpMatchWholeWordCheckBox;
    QToolButton *mpCloseButton;
signals:
    bool focusOut();
public slots:
    void hideFindWidget();
    void updateButtons();
    void findNextText();
    void findPreviuosText();
};

class ModelicaTextSettings;

class ModelicaTextHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT
public:
    ModelicaTextHighlighter(ModelicaTextSettings *pSettings, QTextDocument *pParent = 0);
    void initializeSettings();
    void highlightMultiLine(const QString &text);

    ModelicaTextSettings *mpModelicaTextSettings;
protected:
    virtual void highlightBlock(const QString &text);
private:
    struct HighlightingRule
    {
        QRegExp mPattern;
        QTextCharFormat mFormat;
    };
    QVector<HighlightingRule> mHighlightingRules;

    QRegExp mCommentStartExpression;
    QRegExp mCommentEndExpression;
    QRegExp mStringStartExpression;
    QRegExp mStringEndExpression;

    QTextCharFormat mKeywordFormat;
    QTextCharFormat mTypeFormat;
    QTextCharFormat mFunctionFormat;
    QTextCharFormat mQuotationFormat;
    QTextCharFormat mSingleLineCommentFormat;
    QTextCharFormat mMultiLineCommentFormat;
public slots:
    void settingsChanged();
};

#endif // MODELICAEDITOR_H
