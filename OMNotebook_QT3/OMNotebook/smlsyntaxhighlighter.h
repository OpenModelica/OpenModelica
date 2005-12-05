/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2005, Linköpings universitet,
Department of Computer and Information Science, PELAB
See also: www.ida.liu.se/projects/OpenModelica

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    
	* Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

    * Neither the name of Linköpings universitet nor the names of its contributors
      may be used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

For more information about the Qt-library visit TrollTech:s webpage regarding
licence: http://www.trolltech.com/products/qt/licensing.html

------------------------------------------------------------------------------------
*/

#ifndef SML_SYNTAX_HIGHLIGHTER_H_
#define SML_SYNTAX_HIGHLIGHTER_H_

// QT includes
#include "qregexp.h"
#include <qsyntaxhighlighter.h>

// QT forward declarations
class QTextEdit;
class QFont;

class TextEditorFontAndColors
{
public:
   friend bool operator==(const TextEditorFontAndColors& lhs, const
			  TextEditorFontAndColors& rhs);
   friend bool operator!=(const TextEditorFontAndColors& lhs, const
			  TextEditorFontAndColors& rhs);
   
public:
   QString fontFamily_;
   int fontSize_;
   
   QColor textForeground_;
   QColor textBackground_;
   QColor typeForeground_;
   QColor typeBackground_;
   QColor keywordForeground_;
   QColor keywordBackground_;
   QColor functionNameForeground_;
   QColor functionNameBackground_;
   QColor constantForeground_;
   QColor constantBackground_;
   QColor warningForeground_;
   QColor warningBackground_;
   QColor builtInForeground_;
   QColor builtInBackground_;
   QColor variableNameForeground_;
   QColor variableNameBackground_;
   QColor stringForeground_;
   QColor stringBackground_;
   QColor commentForeground_;
   QColor commentBackground_;
};

/**
 *
 */
class SmlSyntaxHighlighter : public QSyntaxHighlighter//, QObject
{
//   Q_OBJECT

public:
   SmlSyntaxHighlighter(QTextEdit* textEdit, 
			     const TextEditorFontAndColors& fontAndColors);
   ~SmlSyntaxHighlighter();

   int highlightParagraph(const QString& text, int previousEndState);

public slots:
   //void setFontAndColors(const TextEditorFontAndColors& fontAndColors);

private:
   enum EndState { InComment = 1, InString = 2 };

private:
   int getIndexOfMinPositive(int value1, int value2, int value3) const;
   int highlightStringsAndComments(const QString& text, int startPosition);

private:
   TextEditorFontAndColors fontAndColors_;
   QFont font_;

   QRegExp keyword_;
   QRegExp type_;
   QRegExp functionName_;
   QRegExp constant_;
   QRegExp warning_;
   QRegExp builtIn_;
   QRegExp variableName_;
   QRegExp string_;
   QRegExp endString_;
   QRegExp lineComment_;
   QRegExp comment_;
   QRegExp endComment_;

   QColor foregroundColor_;
   QColor typeColor_;
   QColor keywordColor_;
   QColor functionNameColor_;
   QColor constantColor_;
   QColor warningColor_;
   QColor builtInColor_;
   QColor variableNameColor_;
   QColor stringColor_;
   QColor commentColor_;
};

#endif
