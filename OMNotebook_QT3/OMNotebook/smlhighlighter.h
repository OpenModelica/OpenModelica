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

#ifndef _SML_SYNTAXHIGHLIGHTER_H
#define _SML_SYNTAXHIGHLIGHTER_H

#include <stdexcept>

#include <qtextedit.h>
#include <qsyntaxhighlighter.h>

#include "smlsyntaxhighlighter.h"

namespace IAEX
{
   /*! \class SmlHighlighter
    *  \brief Implements syntaxhighlightning for Standard ML.
    * 
    * Syntaxhighlightning for Standard ML. This class is not correctly
    * implemented, or it is not event close to be finished.
    *
    * \todo Implement this correct.
    */
   class SmlHighlighter : public SyntaxHighlighter
   {
   public:
      SmlHighlighter()
	 : highlighter_(0), textEdit_(0)
      {
	 initializeColors();
      }
      virtual ~SmlHighlighter(){}
      void setTextEdit(QTextEdit *textEdit){ textEdit_ = textEdit;}
      virtual void rehighlight()
      {
	 if(!highlighter_)
	 {
	    if(textEdit_)
	       highlighter_ = new SmlSyntaxHighlighter(textEdit_, colors_);
	    else
	       throw runtime_error("SMLHighlighter: No QTextEdit.");
	 }
	 
	 highlighter_->rehighlight();	    
      }
      
   private:
      void initializeColors()
      {
	 colors_.textForeground_         = QColor(0,0,0);
	 colors_.textBackground_         = QColor(0,0,0);
	 colors_.typeForeground_         = QColor(0,0,0);
	 colors_.typeBackground_         = QColor(0,0,0);
	 colors_.keywordForeground_      = QColor(255,0,0);
	 colors_.keywordBackground_      = QColor(0,0,0);
	 colors_.functionNameForeground_ = QColor(0,0,255);
	 colors_.functionNameBackground_ = QColor(0,0,0);
	 colors_.constantForeground_     = QColor(0,255,0);
	 colors_.constantBackground_     = QColor(0,0,0);
	 colors_.warningForeground_      = QColor(255,0,0);
	 colors_.warningBackground_      = QColor(0,0,0);
	 colors_.builtInForeground_      = QColor(0,0,255);
	 colors_.builtInBackground_      = QColor(0,0,0);
	 colors_.variableNameForeground_ = QColor(255,0,255);
	 colors_.variableNameBackground_ = QColor(0,0,0);
	 colors_.stringForeground_       = QColor(100,0,0);
	 colors_.stringBackground_       = QColor(0,0,0);
	 colors_.commentForeground_      = QColor(200,0,0);
	 colors_.commentBackground_      = QColor(0,0,0);
      }
      
   private:
      TextEditorFontAndColors colors_;
      QSyntaxHighlighter *highlighter_;
      QTextEdit *textEdit_;
   };
}

#endif
