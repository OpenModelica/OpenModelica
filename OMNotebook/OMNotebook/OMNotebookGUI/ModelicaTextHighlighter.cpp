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

// Qt headers
#include <QtCore/QFile>
#include <QtCore/QRegularExpression>
#include <QtGui/QTextBlock>
#include <QtGui/QTextDocument>
#include <QtGui/QTextLayout>
#include <QtXml/QDomDocument>
#include <QMessageBox>

// IAEX Headers
#include "ModelicaTextHighlighter.h"

namespace IAEX
{

//  ModelicaTextHighlighter implementation
ModelicaTextHighlighter::ModelicaTextHighlighter(QTextDocument *pTextDocument)
    : QSyntaxHighlighter(pTextDocument)
{
    initializeSettings();
}

//  Highlighting rule container – stores a QRegularExpression
struct HighlightingRule
{
    QRegularExpression mPattern;
    QTextCharFormat   mFormat;
};

//  Initialise default colours and regular‑expression based rules
void ModelicaTextHighlighter::initializeSettings()
{
    mHighlightingRules.clear();

    // colour definitions
    mTextFormat.setForeground(QColor(0, 0, 0));          // black
    mKeywordFormat.setForeground(QColor(180, 0, 0));    // dark red
    mTypeFormat.setForeground(QColor(255, 10, 10));     // red
    mSingleLineCommentFormat.setForeground(QColor(0, 120, 0)); // green
    mMultiLineCommentFormat.setForeground(QColor(0, 120, 0)); // green
    mFunctionFormat.setForeground(QColor(180, 0, 0));   // dark red
    mQuotationFormat.setForeground(QColor(120, 120, 120)); // gray
    mNumberFormat.setForeground(QColor(139, 0, 139));   // purple

    HighlightingRule rule;

    // numbers
    rule.mPattern = QRegularExpression(R"([0-9][0-9]*([.][0-9]*)?([eE][+-]?[0-9]*)?)");
    rule.mFormat  = mNumberFormat;
    mHighlightingRules.append(rule);

    // identifiers
    rule.mPattern = QRegularExpression(R"(\b[A-Za-z_][A-Za-z0-9_]*\b)");
    rule.mFormat  = mTextFormat;
    mHighlightingRules.append(rule);

    // functions (look‑ahead for '(')
    rule.mPattern = QRegularExpression(R"(\b[A-Za-z0-9_]+(?=\())");
    rule.mFormat  = mFunctionFormat;
    mHighlightingRules.append(rule);

    // keywords
    const QStringList keywordPatterns = {
        R"(\balgorithm\b)", R"(\band\b)",            R"(\bannotation\b)",
        R"(\bassert\b)",    R"(\bblock\b)",          R"(\bbreak\b)",
        R"(\bBoolean\b)",   R"(\bclass\b)",          R"(\bconnect\b)",
        R"(\bconnector\b)", R"(\bconstant\b)",       R"(\bconstrainedby\b)",
        R"(\bder\b)",       R"(\bdiscrete\b)",       R"(\beach\b)",
        R"(\belse\b)",      R"(\belseif\b)",         R"(\belsewhen\b)",
        R"(\bencapsulated\b)", R"(\bend\b)",         R"(\benumeration\b)",
        R"(\bequation\b)",  R"(\bexpandable\b)",     R"(\bextends\b)",
        R"(\bexternal\b)",  R"(\bfalse\b)",          R"(\bfinal\b)",
        R"(\bflow\b)",      R"(\bfor\b)",            R"(\bfunction\b)",
        R"(\bif\b)",        R"(\bimport\b)",         R"(\bimpure\b)",
        R"(\bin\b)",        R"(\binitial\b)",        R"(\binner\b)",
        R"(\binput\b)",     R"(\bloop\b)",           R"(\bmodel\b)",
        R"(\bnot\b)",       R"(\boperator\b)",       R"(\bor\b)",
        R"(\bouter\b)",     R"(\boutput\b)",         R"(\boptimization\b)",
        R"(\bpackage\b)",   R"(\bparameter\b)",      R"(\bpartial\b)",
        R"(\bprotected\b)", R"(\bpublic\b)",         R"(\bpure\b)",
        R"(\brecord\b)",    R"(\bredeclare\b)",      R"(\breplaceable\b)",
        R"(\breturn\b)",    R"(\bstream\b)",         R"(\bthen\b)",
        R"(\btrue\b)",      R"(\btype\b)",           R"(\bwhen\b)",
        R"(\bwhile\b)",     R"(\bwithin\b)"
    };

    for (const QString &pattern : keywordPatterns) {
        rule.mPattern = QRegularExpression(pattern);
        rule.mFormat  = mKeywordFormat;
        mHighlightingRules.append(rule);
    }

    // Modelica types
    const QStringList typePatterns = {
        R"(\bString\b)", R"(\bInteger\b)", R"(\bBoolean\b)", R"(\bReal\b)"
    };

    for (const QString &pattern : typePatterns) {
        rule.mPattern = QRegularExpression(pattern);
        rule.mFormat  = mTypeFormat;
        mHighlightingRules.append(rule);
    }
}

  /*!
   * \brief ModelicaTextHighlighter::highlightMultiLine
   * Highlights the multilines text.
   * Quoted text or multiline comments.
   * \param text
   */
void ModelicaTextHighlighter::highlightMultiLine(const QString &text)
{
    /* Hand‑written recogniser beats the crap known as QRegEx ;) */
    int index = 0, startIndex = 0;
    int blockState = previousBlockState();

    while (index < text.length()) {
        switch (blockState) {
        case 1: // inside a single‑line comment
            if (text[index] == '/' && index + 1 < text.length() && text[index + 1] == '/') {
                ++index;               // stay in the comment state
                blockState = 1;
            }
            break;

        case 2: // inside a multi‑line comment
            if (text[index] == '*' && index + 1 < text.length() && text[index + 1] == '/') {
                ++index;
                setFormat(startIndex, index - startIndex + 1, mMultiLineCommentFormat);
                blockState = 0;
            }
            break;

        case 3: // inside a quoted string
            if (text[index] == '\\') {
                ++index;               // escape sequence – skip next char
            } else if (text[index] == '"') {
                setFormat(startIndex, index - startIndex + 1, mQuotationFormat);
                blockState = 0;
            }
            break;

        default: // not inside any special construct
            if (text[index] == '/' && index + 1 < text.length() && text[index + 1] == '/') {
                startIndex = index++;
                setFormat(startIndex, text.length() - startIndex, mSingleLineCommentFormat);
                blockState = 1;
            } else if (text[index] == '/' && index + 1 < text.length() && text[index + 1] == '*') {
                startIndex = index++;
                blockState = 2;
            } else if (text[index] == '"') {
                startIndex = index;
                blockState = 3;
            }
            break;
        }
        ++index;
    }

    switch (blockState) {
    case 2:
        setFormat(startIndex, text.length() - startIndex, mMultiLineCommentFormat);
        setCurrentBlockState(2);
        break;
    case 3:
        setFormat(startIndex, text.length() - startIndex, mQuotationFormat);
        setCurrentBlockState(3);
        break;
    }
}

//  Highlight a single text block
void ModelicaTextHighlighter::highlightBlock(const QString &text)
{
    // default state & base formatting
    setCurrentBlockState(0);
    setFormat(0, text.length(), mTextFormat);

    // apply all regular‑expression based rules
    for (const HighlightingRule &rule : std::as_const(mHighlightingRules)) {
        QRegularExpressionMatchIterator it = rule.mPattern.globalMatch(text);
        while (it.hasNext()) {
            QRegularExpressionMatch match = it.next();
            setFormat(match.capturedStart(), match.capturedLength(), rule.mFormat);
        }
    }

    // handle comments and strings that may span several blocks
    highlightMultiLine(text);
}

} // namespace IAEX
