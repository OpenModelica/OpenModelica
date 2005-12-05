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

#include "syntax_highlighter.hpp"

// MME includes
//#include "options_manager.hpp"

// QT includes
#include "qapplication.h"
#include "qfont.h"
#include "qtextedit.h"

/**
 *
 */
ModelicaSyntaxHighlighter::ModelicaSyntaxHighlighter(QTextEdit* textEdit,
						     const TextEditorFontAndColors& fontAndColors)
   : QSyntaxHighlighter(textEdit),
     fontAndColors_(fontAndColors)
{
   font_ = QFont(fontAndColors_.fontFamily_, fontAndColors_.fontSize_);
   
   QString keywordPattern(QString("\\b(a(lgorithm|nd)|e(lse(if|when)?|quation|xtends)|for") +
			  "|i(f|mport|n)|loop|not|or|p(rotected|ublic)|then|w(h(en|ile)|ithin))\\b");
   
   QString typePattern(QString("\\b(block|c(lass|on(nector|stant))|discrete|e(n(capsulated|d)") +
		       "|xternal)|f(inal|low|unction)|in(ner|put)|model|out(er|put)|pa(ckage|r(tial|ameter))" +
		       "|re(cord|declare|placeable)|type)\\b");
   
   QString functionNamePattern(QString("\\b(a(bs|nalysisType)|c(ardinality|hange|eil|ross)|d(e(lay|der)") +
			       "|i(v|agonal))|edge|f(ill|loor)|i(dentity|n(itial|teger))|linspace|ma(trix|x)|min|mod|n(dims" +
			       "|oEvent)|o(nes|uterProduct)|pr(e|o(duct|mote))|re(init|m)|s(amle|calar|i(gn|ze)|kew" +
			       "|qrt|um|ymmetric)|t(erminal|ranspose)|vector|zeros)\\b");
   
   QString constantPattern("\\b(false|true)\\b");
   
   QString warningPattern("\\b(assert|terminate)\\b");
   
   QString builtInPattern("\\b(annotation|connect)\\b");
   
   QString variableNamePattern("\\b(time)\\b");
   
   QString stringPattern("(\".*(([^\\\\]\")|$)|\"\")");
   QString endStringPattern(".*(([^\\\\]\")|^\"|$)");
   
   QString lineCommentPattern("//.*");
   QString commentPattern("/\\*.*((\\*/)|$)");
   QString endCommentPattern(".*((\\*/)|$)"); 
   
   keyword_.setPattern(keywordPattern);
   type_.setPattern(typePattern);
   functionName_.setPattern(functionNamePattern);
   constant_.setPattern(constantPattern);
   warning_.setPattern(warningPattern);
   builtIn_.setPattern(builtInPattern);
   variableName_.setPattern(variableNamePattern);
   
   string_.setPattern(stringPattern);
   string_.setMinimal(true);
   endString_.setPattern(endStringPattern);
   endString_.setMinimal(true);
   
   lineComment_.setPattern(lineCommentPattern);
   comment_.setPattern(commentPattern);
   comment_.setMinimal(true);
   endComment_.setPattern(endCommentPattern);
   endComment_.setMinimal(true);
}

/**
 *
 */
ModelicaSyntaxHighlighter::~ModelicaSyntaxHighlighter()
{
}

/**
 *
 */
// void ModelicaSyntaxHighlighter::setFontAndColors(const TextEditorFontAndColors& fontAndColors)
// {
//    fontAndColors_ = fontAndColors;
//    font_ = QFont(fontAndColors_.fontFamily_, fontAndColors_.fontSize_);
//    rehighlight();
// }

/**
 *
 */
int ModelicaSyntaxHighlighter::getIndexOfMinPositive(int value1, 
						     int value2, 
						     int value3) const
{
   if (value1 < 0 && value2 < 0 && value3 < 0) {
      return -1;
   }
   else if ((value1 >= 0 && value2 < 0 && value3 < 0) ||
	    (value1 >= 0 && value2 >= 0 && value3 < 0  && value1 < value2) ||
	    (value1 >= 0 && value2 < 0  && value3 >= 0 && value1 < value3) ||
	    (value1 >= 0 && value2 >= 0 && value3 >= 0 && value1 < value2 && value1 < value3))
   {
      return 1;
   }
   else if ((value2 >= 0 && value1 < 0 && value3 < 0) ||
	    (value2 >= 0 && value1 >= 0 && value3 < 0  && value2 < value1) ||
	    (value2 >= 0 && value1 < 0  && value3 >= 0 && value2 < value3) ||
	    (value2 >= 0 && value1 >= 0 && value3 >= 0 && value2 < value1 && value2 < value3))
   {
      return 2;
   }
   else
   {
      return 3;
   }
}

 int ModelicaSyntaxHighlighter::highlightStringsAndComments(const QString& text, int startPosition)
 {
   // Highlight strings and comments.
   int pos(startPosition);
   while (true) {
      int lineCommentPos(lineComment_.search(text, pos));
      int commentPos(comment_.search(text, pos));
      int stringPos(string_.search(text, pos));
      switch(getIndexOfMinPositive(lineCommentPos, commentPos, stringPos))
      {
      case 1:	// Line comment (C++ comment)
	 setFormat(lineCommentPos, lineComment_.matchedLength(), font_, fontAndColors_.commentForeground_);
	 return 0;
	 
      case 2:	// Comment (C comment)
	 setFormat(commentPos, comment_.matchedLength(), font_, fontAndColors_.commentForeground_);
	 pos = commentPos + comment_.matchedLength();
	 if (pos == (int)text.length()) {
	    return InComment;
	 }
	 break;
	 
      case 3: // String
	 setFormat(stringPos, string_.matchedLength(), font_, fontAndColors_.stringForeground_);
	 pos = stringPos + string_.matchedLength();
	 if (pos == (int)text.length()) {
	    return InString;
	 }
	 break;
	 
      default:
	 return 0;
      }
   }
}

/**
 *
 */
int ModelicaSyntaxHighlighter::highlightParagraph(const QString& text, int previousEndState)
{
   setFormat(0, text.length(), font_, fontAndColors_.textForeground_);
   
   // Keyword
   int pos(0);
   while (pos >= 0) {
      pos = keyword_.search(text, pos);
      if (pos >= 0) {
	 setFormat(pos, keyword_.matchedLength(), font_, fontAndColors_.keywordForeground_);
	 pos += keyword_.matchedLength();
      }
   }

   // Type
   pos = 0;
   while (pos >= 0) {
      pos = type_.search(text, pos);
      if (pos >= 0) {
	 setFormat(pos, type_.matchedLength(), font_, fontAndColors_.typeForeground_);
	 pos += type_.matchedLength();
      }
   }

   // Function name
   pos = 0;
   while (pos >= 0) {
      pos = functionName_.search(text, pos);
      if (pos >= 0) {
	 setFormat(pos, functionName_.matchedLength(), font_, fontAndColors_.functionNameForeground_);
	 pos += functionName_.matchedLength();
      }
   }

   // Constant
   pos = 0;
   while (pos >= 0) {
      pos = constant_.search(text, pos);
      if (pos >= 0) {
	 setFormat(pos, constant_.matchedLength(), font_, fontAndColors_.constantForeground_);
	 pos += constant_.matchedLength();
      }
   }

   // Warning
   pos = 0;
   while (pos >= 0) {
      pos = warning_.search(text, pos);
      if (pos >= 0) {
	 setFormat(pos, warning_.matchedLength(), font_, fontAndColors_.warningForeground_);
	 pos += warning_.matchedLength();
      }
   }

   // Built-in
   pos = 0;
   while (pos >= 0) {
      pos = builtIn_.search(text, pos);
      if (pos >= 0) {
	 setFormat(pos, builtIn_.matchedLength(), font_, fontAndColors_.builtInForeground_);
	 pos += builtIn_.matchedLength();
      }
   }

   // Variable name
   pos = 0;
   while (pos >= 0) {
      pos = variableName_.search(text, pos);
      if (pos >= 0) {
	 setFormat(pos, variableName_.matchedLength(), font_, fontAndColors_.variableNameForeground_);
	 pos += variableName_.matchedLength();
      }
   }

   // Open strings.
   pos = 0;
   if (previousEndState == InString) {
      pos = endString_.search(text, pos);
      setFormat(pos, endString_.matchedLength(), font_, fontAndColors_.stringForeground_);
      pos += endString_.matchedLength();
      if (pos == (int)text.length()) {
	 return InString;
      } else {
	 return highlightStringsAndComments(text, pos);
      }
   }

   // Open comments.
   pos = 0;
   if (previousEndState == InComment) {
      pos = endComment_.search(text, pos);
      setFormat(pos, endComment_.matchedLength(), font_, fontAndColors_.commentForeground_);
      pos += endComment_.matchedLength();
      if (pos == (int)text.length()) {
	 return InComment;
      } else {
	 return highlightStringsAndComments(text, pos);
      }
   }

   // Strings and comments.
   return highlightStringsAndComments(text, 0);
}
