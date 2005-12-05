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

#ifndef _MODELICASYNTAXHIGHLIGHTER_H
#define _MODELICASYNTAXHIGHLIGHTER_H

#include <exception>
#include <stdexcept>

#include <qtextedit.h>
#include <qsyntaxhighlighter.h>
#include <qdom.h>
#include <qfile.h>

#include "syntaxhighlighter.h"
#include "syntax_highlighter.hpp"

namespace IAEX
{
	/*! \class ModelicaHighlighter
	 *
	 * \brief Implements syntaxhighlightning for Modelica code.
	 *
	 * Implements syntaxhighlightning for Modelica code. Uses Daniel
	 * Hedbergs ModelicaSyntaxHighlighter class to implement the
	 * syntaxhighlightning functionality. To change colors edit the
	 * modelicacolors.xml 
	 */
	class ModelicaHighlighter : public SyntaxHighlighter
	{
	public:
		ModelicaHighlighter()
			: highlighter_(0), textEdit_(0)
		{
			filename_ = QString("modelicacolors.xml");
			initializeColors();
		}
		virtual ~ModelicaHighlighter(){}
		void setTextEdit(QTextEdit *textEdit){ textEdit_ = textEdit;}
		virtual void rehighlight()
		{
			if(!highlighter_)
			{
				if(textEdit_)
					highlighter_ = new ModelicaSyntaxHighlighter(textEdit_, colors_);
				else
					throw runtime_error("ModelicaHighlighter: No QTextEdit.");
			}

			highlighter_->rehighlight();	    
		}

	private:
		void initializeColors()
		{
			QDomDocument doc("ModelicaColors");

			QFile file(filename_); 

			if(!file.open(IO_ReadOnly))
				throw std::exception( "Could not open " + filename_ );

			if(!doc.setContent(&file))
			{
				file.close();
				throw std::exception( "Could not understand content of " +  filename_ );
			}
			file.close();

			QDomElement root = doc.documentElement();
			QDomNode n = root.firstChild();

			while(!n.isNull())
			{
				QDomElement e = n.toElement();
				if(!e.isNull())
				{
					if(e.tagName() == "textForeground")
					{
						colors_.textForeground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "textBackground")
					{
						colors_.textBackground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "typeForeground")
					{
						colors_.typeForeground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "typeBackground")
					{
						colors_.typeBackground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "keywordForeground")
					{
						colors_.keywordForeground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "keywordBackground")
					{
						colors_.keywordBackground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "functionNameForeground")
					{
						colors_.functionNameForeground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "functionNameBackground")
					{
						colors_.functionNameBackground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "constantForeground")
					{
						colors_.constantForeground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "constantBackground")
					{
						colors_.constantBackground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "warningForeground")
					{
						colors_.warningForeground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "warningBackground")
					{
						colors_.warningBackground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "builtInForeground")
					{
						colors_.builtInForeground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "builtInBackground")
					{
						colors_.builtInBackground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "variableNameForeground")
					{
						colors_.variableNameForeground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "variableNameBackground")
					{
						colors_.variableNameBackground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "stringForeground")
					{
						colors_.stringForeground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "stringBackground")
					{
						colors_.stringBackground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "commentForeground")
					{
						colors_.commentForeground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else if(e.tagName() == "commentBackground")
					{
						colors_.commentBackground_ = QColor(atoi(e.attribute("red","")),
							atoi(e.attribute("green","")),
							atoi(e.attribute("blue","")));
					}
					else
					{
						//Move on.
					}
				}
				n = n.nextSibling();
			}	    
		}

	private:
		TextEditorFontAndColors colors_;
		QSyntaxHighlighter *highlighter_;
		QTextEdit *textEdit_;
		QString filename_;
	};
}

#endif
