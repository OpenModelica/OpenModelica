/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2006, Linköpings universitet,
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

/*! 
* \file openmodelicahighlighter.h
* \author Anders Fernström
* \date 2005-12-17
*
* Part of this code for taken from the example highlighter on TrollTechs website.
* http://doc.trolltech.com/4.0/richtext-syntaxhighlighter-highlighter-h.html
*
* Part of this code is also based on the old modelicahighligter (for the old
* version of OMNotebook). That file can have been renamed to:
* modelicahighlighter.h.old
*/

#ifndef OPENMODELICAHIGHLIGHTER_H
#define OPENMODELICAHIGHLIGHTER_H


//STD Headers
#include <exception>

//QT Headers
#include <QtCore/QHash>
#include <QtCore/QString>
#include <QtCore/QRegExp>
#include <QtGui/QTextCharFormat>

//IAEX Headers
#include "syntaxhighlighter.h"

//Forward declaration
class QTextBlock;
class QDomElement;



namespace IAEX
{
	class OpenModelicaHighlighter : public SyntaxHighlighter
	{
	public:
		OpenModelicaHighlighter( QString filename, QTextCharFormat standard );
		virtual ~OpenModelicaHighlighter();
		void highlight( QTextDocument *doc );

	private:
		void highlightBlock( QTextBlock block );
		void initializeQTextCharFormat();
		void initializeMapping();
		void parseSettings( QDomElement e, QTextCharFormat *format );

	private:
		QString filename_;
		QHash<QString,QTextCharFormat> mappings_;

		bool insideString_;
		bool insideComment_;
		QRegExp stringStart_;
		QRegExp stringEnd_;
		QRegExp commentStart_;
		QRegExp commentEnd_;
		QRegExp commentLine_;
		
		QTextCharFormat standardTextFormat_;
		QTextCharFormat typeFormat_;
		QTextCharFormat keywordFormat_;
		QTextCharFormat functionNameFormat_;
		QTextCharFormat constantFormat_;
		QTextCharFormat warningFormat_;
		QTextCharFormat builtInFormat_;
		QTextCharFormat variableNameFormat_;
		QTextCharFormat stringFormat_;
		QTextCharFormat commentFormat_;
	};
}

#endif
