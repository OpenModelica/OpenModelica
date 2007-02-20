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

// REMADE LARGE PART OF THIS CLASS 2005-11-30 /AF

/*! 
 * \file xmlparser.h
 * \author Anders Fernström (and Ingemar Axelsson)
 * \date 2005-11-30
 *
 * \brief Remake this class to work with the specified xml format that
 * document are to be saved in. The old file have been renamed to 
 * 'xmlparser.h.old' /AF
 */

#ifndef XMLPARSER_H
#define XMLPARSER_H


//QT Headers 
#include <QtCore/QString>

//IAEX Headers
#include "nbparser.h"
#include "document.h"
#include "factory.h"
#include "xmlnodename.h"

//Forward declaration
class QDomDocument;
class QDomElement;
class QDomNode;


namespace IAEX
{
	class XMLParser : public NBParser
	{
	public:
		XMLParser( const QString filename, Factory *factory, Document *document, int readmode = READMODE_NORMAL );
		virtual ~XMLParser();
		virtual Cell *parse();

	private:
		Cell *parseNormal( QDomDocument &domdoc );
		Cell *parseOld( QDomDocument &domdoc );

		// READMODE_NORMAL
		void traverseCells( Cell *parent, QDomNode &node );
		void traverseGroupCell( Cell *parent, QDomElement &element );
		void traverseTextCell( Cell *parent, QDomElement &element );
		void traverseInputCell( Cell *parent, QDomElement &element );
		void traverseGraphCell( Cell *parent, QDomElement &element );
		void addImage( Cell *parent, QDomElement &element );

		// READMODE_OLD
		void xmltraverse( Cell *parent, QDomNode &node );


		// variables
		QString filename_;
		Factory *factory_;
		Document *doc_;
		int readmode_;
	};
};
#endif
