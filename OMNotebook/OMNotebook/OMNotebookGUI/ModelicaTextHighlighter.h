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
#ifndef MODELICATEXTHIGHLIGHTER_H
#define MODELICATEXTHIGHLIGHTER_H

// ---------------------------------------------------------------------------
// Qt headers
// ---------------------------------------------------------------------------
#include <QtCore/QString>
#include <QtCore/QRegularExpression>
#include <QtGui/QSyntaxHighlighter>
#include <QtGui/QTextCharFormat>
#include <QtGui/QTextDocument>
#include <QtCore/QVector>

namespace IAEX
{

/**
 * @class ModelicaTextHighlighter
 * @brief Syntax highlighter for the Modelica language.
 *
 * The implementation uses QRegularExpression (Qt 5/6).
 */
class ModelicaTextHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT
public:
    explicit ModelicaTextHighlighter(QTextDocument *pTextDocument);
    ~ModelicaTextHighlighter() override = default;

    /** Initialise the colour/format tables and the regex rules. */
    void initializeSettings();

    /** Highlight multi‑line comments / quoted strings. */
    void highlightMultiLine(const QString &text);

protected:
    /** Reimplemented from QSyntaxHighlighter – now marked `override`. */
    void highlightBlock(const QString &text) override;

private:
    /** Container for a single “pattern → format” rule. */
    struct HighlightingRule
    {
        QRegularExpression   mPattern;
        QTextCharFormat      mFormat;
    };

    QVector<HighlightingRule> mHighlightingRules;

    // -----------------------------------------------------------------------
    //  Text formats (re‑used by many rules)
    // -----------------------------------------------------------------------
    QTextCharFormat mTextFormat;
    QTextCharFormat mKeywordFormat;
    QTextCharFormat mTypeFormat;
    QTextCharFormat mFunctionFormat;
    QTextCharFormat mQuotationFormat;
    QTextCharFormat mSingleLineCommentFormat;
    QTextCharFormat mMultiLineCommentFormat;
    QTextCharFormat mNumberFormat;
};

} // namespace IAEX

#endif // MODELICATEXTHIGHLIGHTER_H
