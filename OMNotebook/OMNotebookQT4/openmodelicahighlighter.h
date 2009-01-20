/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2009, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * For more information about the Qt-library visit TrollTech's webpage 
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
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
