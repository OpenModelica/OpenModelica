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

// REMADE THIS CLASS 2005-12-17 /AF

/*!
* \file syntaxhighlighter.h
* \author Anders Fernström
* \date 2005-12-17
*
* \brief Had to remake the class to be compatible with the richtext
* system that is used in QT4. The old file have been renamed to
* 'syntaxhighlighter.h.old' /AF
*/


#ifndef SYNTAXHIGHLIGHTER_H
#define SYNTAXHIGHLIGHTER_H

//forwars declaration
class QTextDocument;


namespace IAEX
{
	/*!
	* \interface SyntaxHighlighter
	* \brief Interface that syntaxhighlighters needs to obey to.
	*
	* updated file 2006-01-09 to represent the new highlighter that have
	* been made to run in an new thread.
	*/
	class SyntaxHighlighter
	{
	public:
		virtual void highlight(QTextDocument *) = 0;
	};
}

#endif
