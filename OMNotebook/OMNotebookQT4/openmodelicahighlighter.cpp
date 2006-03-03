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
* modelicahighlighter.cpp.old
*/


//STD Headers
#include <exception>
#include <iostream>

//QT Headers
#include <QtCore/QFile>
#include <QtGui/QTextBlock>
#include <QtGui/QTextDocument>
#include <QtGui/QTextLayout>
#include <QtXml/QDomDocument>

// IAEX Headers
#include "openmodelicahighlighter.h"


using namespace std;
namespace IAEX
{
	/*! 
	 * \class OpenModelicaHighlighter
	 * \author Anders Fernström
	 * \date 2005-12-17
	 *
	 * \brief Implements syntaxhighlightning for Modelica code. 
	 * Implements syntaxhighlightning for Modelica code. To change 
	 * colors edit the modelicacolors.xml 
	 */

	/*!
	 * \author Anders Fernström
	 * \date 2005-12-17
	 *
	 * \brief The class constructor
	 */
	OpenModelicaHighlighter::OpenModelicaHighlighter( QString filename, QTextCharFormat standard )
		: filename_(filename),
		standardTextFormat_(standard)
	{
		initializeQTextCharFormat();
		initializeMapping();
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-12-17
	 *
	 * \brief The class destructor
	 */
	OpenModelicaHighlighter::~OpenModelicaHighlighter()
	{
	}


	/*! 
	 * \author Anders Fernström
	 * \date 2005-12-17
	 *
	 * \brief Highlights a QTextDocument. The function highlights
	 * one text block at the time
	 *
	 * \param doc The text document that should be highlighted
	 */
	void OpenModelicaHighlighter::highlight( QTextDocument *doc )
	{
		//2005-12-29 AF, add block signal
		doc->blockSignals( true );
		
		QTextBlock block = doc->begin();

		insideString_ = false;
		insideComment_ = false;

		// loop thought blocks
		while( block.isValid() )
		{
			highlightBlock(block);
			block = block.next();
		}

		//2005-12-29 AF, add block signal
		doc->blockSignals( false );
	}

	/*! 
	 * \author Anders Fernström
	 * \date 2005-12-17
	 *
	 * \brief Highlights a block of thext
	 *
	 * \param block The text block that should be highlighted
	 */
	void OpenModelicaHighlighter::highlightBlock( QTextBlock block )
	{
		QTextLayout *layout = block.layout();
		const QString text = block.text();
		QList<QTextLayout::FormatRange> overrides;

		bool wholeBlock = false;
		int startPos = 0;

		if( insideString_ )
		{
			int end = text.indexOf( stringEnd_, startPos );

			if( end >= 0 )
			{ // found end in this block
				startPos = end + stringEnd_.matchedLength();
				insideString_ = false;

				QTextLayout::FormatRange range;
				range.start = 0;
				range.length = startPos;
				range.format = stringFormat_;
				overrides << range;
			}
			else
			{ // found no end, syntax highlight whole block
				wholeBlock = true;

				QTextLayout::FormatRange range;
				range.start = 0;
				range.length = block.length();
				range.format = stringFormat_;
				overrides << range;
			}
		}
		else if( insideComment_ )
		{
			int end = text.indexOf( commentEnd_, startPos );
			
			if( end >= 0 )
			{ // found end in this block
				startPos = end + commentEnd_.matchedLength();
				insideComment_ = false;

				QTextLayout::FormatRange range;
				range.start = 0;
				range.length = startPos;
				range.format = commentFormat_;
				overrides << range;
			}
			else
			{ // found no end, syntax highlight whole block
				wholeBlock = true;

				QTextLayout::FormatRange range;
				range.start = 0;
				range.length = block.length();
				range.format = commentFormat_;
				overrides << range;
			}
		}
		
		
		if( !wholeBlock )
		{
			foreach( QString pattern, mappings_.keys() ) 
			{
				QRegExp expression( pattern );
				int i = text.indexOf( expression, startPos );

				while( i >= 0 ) 
				{
					QTextLayout::FormatRange range;
					range.start = i;
					range.length = expression.matchedLength();
					range.format = mappings_[pattern];
					overrides << range;

					i = text.indexOf(expression, i + expression.matchedLength());
				}
			}
		

			while( true )
			{
				int firstString = -1;
				int firstComment = -1;
				int firstCommentLine = -1;


				if( !stringStart_.isEmpty() )
					firstString = text.indexOf( stringStart_, startPos );
				if( !commentStart_.isEmpty() )
					firstComment = text.indexOf( commentStart_, startPos );
				if( !commentLine_.isEmpty() )
					firstCommentLine = text.indexOf( commentLine_, startPos );


				if( firstString >= 0 && 
					( (firstString < firstComment) || (firstComment < 0) ) && 
					( (firstString < firstCommentLine) || (firstCommentLine < 0) ))
				{
					int end = text.indexOf( stringEnd_, 
						firstString + stringStart_.matchedLength() );
					if( end >= 0 )
					{
						startPos = end + stringEnd_.matchedLength();

						QTextLayout::FormatRange range;
						range.start = firstString;
						range.length = startPos - firstString;
						range.format = stringFormat_;
						overrides << range;
					}
					else
					{ // found no end, syntax highlight to the end of the block
						QTextLayout::FormatRange range;
						range.start = firstString;
						range.length = block.length() - firstString;
						range.format = stringFormat_;
						overrides << range;
						insideString_ = true;
						break;
					}
				}
				else if( firstComment >= 0 && 
					( (firstComment < firstString) || (firstString < 0) ) &&
					( (firstComment < firstCommentLine) || (firstCommentLine < 0) ))
				{
					int end = text.indexOf( commentEnd_, 
						firstComment + commentStart_.matchedLength() );
					if( end >= 0 )
					{
						startPos = end + commentEnd_.matchedLength();

						QTextLayout::FormatRange range;
						range.start = firstComment;
						range.length = startPos - firstComment;
						range.format = commentFormat_;
						overrides << range;
					}
					else
					{ // found no end, syntax highlight to the end of the block
						QTextLayout::FormatRange range;
						range.start = firstComment;
						range.length = block.length() - firstComment;
						range.format = commentFormat_;
						overrides << range;
						insideComment_ = true;
						break;
					}
				}
				else if( firstCommentLine >= 0 && 
					( (firstCommentLine < firstString) || (firstString < 0) ) &&
					( (firstCommentLine < firstComment) || (firstComment < 0) ))
				{
					QTextLayout::FormatRange range;
					range.start = firstCommentLine;
					range.length = (block.length() - firstCommentLine);
					range.format = commentFormat_;
					overrides << range;
					break;
				}
				else
					break;
			}
		}

		layout->setAdditionalFormats( overrides );
		//const_cast<QTextDocument *>(block.document())->markContentsDirty(
        //block.position(), block.length());
	}


	/*!
	 * \author Anders Fernström
	 * \date 2005-12-17
	 *
	 * \brief Initialize the different text formats by reading the
	 * settings from the file 'modelicacolors.xml'.
	 */
	void OpenModelicaHighlighter::initializeQTextCharFormat()
	{
		QDomDocument doc( "ModelicaColors" );
		QFile file( filename_ );

		if( !file.open(QIODevice::ReadOnly) )
		{
			string tmp = "Could not open " + filename_.toStdString();
			throw exception( tmp.c_str() );
		}

		if( !doc.setContent(&file) )
		{
			file.close();

			string tmp = "Could not understand content of " +  filename_.toStdString();
			throw exception( tmp.c_str() );
		}
		file.close();

		QDomElement root = doc.documentElement();
		QDomNode node = root.firstChild();


		// set all format to standard format to start with...
		typeFormat_.merge( standardTextFormat_ );
		keywordFormat_.merge( standardTextFormat_ );
		functionNameFormat_.merge( standardTextFormat_ );
		constantFormat_.merge( standardTextFormat_ );
		warningFormat_.merge( standardTextFormat_ );
		builtInFormat_.merge( standardTextFormat_ );
		variableNameFormat_.merge( standardTextFormat_ );
		stringFormat_.merge( standardTextFormat_ );
		commentFormat_.merge( standardTextFormat_ );
		

		while( !node.isNull() )
		{
			QDomElement element = node.toElement();
			if( !element.isNull() )
			{
				if( element.tagName() == "type" )
					parseSettings( element, &typeFormat_ );
				else if( element.tagName() == "keyword" )
					parseSettings( element, &keywordFormat_ );
				else if( element.tagName() == "functionName" )
					parseSettings( element, &functionNameFormat_ );
				else if( element.tagName() == "constant" )
					parseSettings( element, &constantFormat_ );
				else if( element.tagName() == "warning" )
					parseSettings( element, &warningFormat_ );
				else if( element.tagName() == "builtIn" )
					parseSettings( element, &builtInFormat_ );
				else if( element.tagName() == "variableName" )
					parseSettings( element, &variableNameFormat_ );
				else if( element.tagName() == "string" )
					parseSettings( element, &stringFormat_ );
				else if( element.tagName() == "comment" )
					parseSettings( element, &commentFormat_ );
				else
				{
					cout << "settings tag not specified: " << 
						element.tagName().toStdString();
				}
			}

			node = node.nextSibling();
		}
	}

	/*!
	 * \author Anders Fernström
	 * \date 2005-12-17
	 *
	 * \brief Initialize the mapping by adding different patterns to
	 * the highlighter.
	 */
	void OpenModelicaHighlighter::initializeMapping()
	{
		// TYPE
		mappings_.insert( QString("\\b(block|c(lass|on(nector|stant))|discrete|e(n(capsulated|d)") +
			"|xternal)|f(inal|low|unction)|in(ner|put)|model|out(er|put)|pa(ckage|r(tial|ameter))" + 
			"|re(cord|declare|placeable)|type)\\b", 
			typeFormat_ );
		
		// KEYWORD
		mappings_.insert( QString("\\b(a(lgorithm|nd)|e(lse(if|when)?|quation|xtends)|for") +
			"|i(f|mport|n)|loop|not|or|p(rotected|ublic)|then|w(h(en|ile)|ithin))\\b", 
			keywordFormat_ );
		
		// FUNCTION NAME
		// 2006-01-14 AF, added: der
		// 2006-03-01 AF, removed sign, added sin
		mappings_.insert( QString("\\b(a(bs|nalysisType)|c(ardinality|hange|eil|ross)|d(e(lay|der)") + 
			"|i(v|agonal))|edge|f(ill|loor)|i(dentity|n(itial|teger))|linspace|ma(trix|x)|min|mod|n(dims" +
			"|oEvent)|o(nes|uterProduct)|pr(e|o(duct|mote))|re(init|m)|s(amle|calar|i(n|ze)|kew" +
            "|qrt|um|ymmetric)|t(erminal|ranspose)|vector|zeros|der)\\b", 
			functionNameFormat_ );

		// CONSTANT
		mappings_.insert( "\\b(false|true)\\b", 
			constantFormat_ );

		// WARNING
		mappings_.insert( "\\b(assert|terminate)\\b", 
			warningFormat_ );

		// BUILT IN
		mappings_.insert( "\\b(annotation|connect)\\b", 
			builtInFormat_ );

		// VARIABLE NAME
		mappings_.insert( "\\b(time)\\b", 
			variableNameFormat_ );

		// STRING
		// A little diffrent because strings can span over several blocks
		stringStart_.setPattern( "\"" );
		stringEnd_.setPattern( "\"" );
		
		// COMMENT
		// A little diffrent because comments can span over several blocks
		commentStart_.setPattern( "/\\*" );
		commentEnd_.setPattern( "\\*/" );
		commentLine_.setPattern( "//.*" );		
	}

	/*!
	 * \author Anders Fernström
	 * \date 2005-12-17
	 *
	 * \brief Parse "type" settings tags
	 */
	void OpenModelicaHighlighter::parseSettings( QDomElement e, 
		QTextCharFormat *format )
	{
		QDomNode node = e.firstChild();
		while( !node.isNull() )
		{
			QDomElement element = node.toElement();
			if( !element.isNull() )
			{
				// FOREGROUND
				if( element.tagName() == "foreground" )
				{
					bool okRed;
					bool okGreen;
					bool okBlue;

					int red = element.attribute( "red", "0" ).toInt(&okRed);
					int green = element.attribute( "green", "0" ).toInt(&okGreen);
					int blue = element.attribute( "blue", "0" ).toInt(&okBlue);

					if( okRed && okGreen && okBlue )
						format->setForeground( QBrush( QColor(red, green, blue) ));
					else
						format->setForeground( QBrush( QColor(0, 0, 0) ));
				}
				// BACKGROUND
				else if( element.tagName() == "background" )
				{
					bool okRed;
					bool okGreen;
					bool okBlue;

					int red = element.attribute( "red", "200" ).toInt(&okRed);
					int green = element.attribute( "green", "200" ).toInt(&okGreen);
					int blue = element.attribute( "blue", "255" ).toInt(&okBlue);

					if( okRed && okGreen && okBlue )
						format->setBackground( QBrush( QColor(red, green, blue) ));
					else
						format->setBackground( QBrush( QColor(200, 200, 255) ));
				}
				// BOLD
				else if( element.tagName() == "bold" )
				{
					//This only occur when bold tag is present.
					//delete bold tag to disable.
					format->setFontWeight( QFont::Bold );
				}
				// ITALIC
				else if( element.tagName() == "italic" )
				{
					//This only occur when italic tag is present.
					//delete italic tag to disable.
					format->setFontItalic( true );
				}
				else
				{
					cout << "type settings tag not specified: " << 
						element.tagName().toStdString();
				}
			}

			node = node.nextSibling();
		}
	}
}