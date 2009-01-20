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
