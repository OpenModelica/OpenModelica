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

//STD Headers
#include <iostream>
#include <exception>
#include <stdexcept>
//#include <cstdlib>
//#include <algorithm>
#include <string>

//QT Headers
#include <qdom.h>
#include <qfile.h>
#include <qapplication.h>

//IAEX Headers
#include "xmlparser.h"
#include "factory.h"

using namespace std;

namespace IAEX
{


   /*!\class XMLParser
    * \brief Open an XML file. See cells.xml
    *
    * \todo implement the function to open a file with filename.  
    *
    * \todo Add a parameter describing how the file should be read. This
    * should be done with some filereader class that can parse a specific
    * filetype. This to easy allow extensibility. What should the file
    * reader return? What about a delegate? The CellContainer will be set
    * as a delegate object for the filereader. Then when a Cell is
    * created the CellContainer is the object that creates the cell. The
    * file reader just gives it some information. This could probably be
    * designed in some better way.
    *
    * \todo Throw exceptions instead of exit if file is problematic.
    *
    */
   XMLParser::XMLParser(const QString filename, Factory *f)
      : filename_(filename), factory_(f)
   {
   }
   
   XMLParser::~XMLParser(){}
   
	Cell *XMLParser::parse()
	{
		QDomDocument doc("CellFile");    

		QFile file(filename_); 

		if(!file.open(IO_ReadOnly))
			throw runtime_error("Could not open " + string(filename_));

		if(!doc.setContent(&file))
		{
			file.close();
			throw runtime_error("Could not understand content of " + string(filename_));
		}
		file.close();

		QDomElement root = doc.documentElement();
		QDomNode n = root.firstChild();

		//Remove first cellgroup.
		if(!n.isNull())
		{
			QDomElement f = n.toElement();

			if(!f.isNull())
			{
				if(f.tagName() == "CellGroupData")
				{
					n = f.firstChild();
				}
			}
		}

		Cell *rootcell = factory_->createCell("cellgroup", 0);

		xmltraverse(rootcell, n);

		return rootcell;
	}
   
   
	void XMLParser::xmltraverse(Cell *ws, QDomNode &n)
	{
		while( !n.isNull())
		{
			QDomElement e = n.toElement();
			if(!e.isNull())
			{
				if(e.tagName() == "Notebook")
				{

				}
				else if(e.tagName() == "CellGroupData")
				{	       
					Cell *aGroup = factory_->createCell("cellgroup", ws);

					QDomNode p = e.firstChild();
					xmltraverse(aGroup, p);

					aGroup->setClosed(e.attribute("closed"));

					ws->addChild(aGroup);
				}
				else if(e.tagName() == "Cell")
				{
					//TextCell *aCell = factory_->createCell("text", ws);
					Cell *aCell;
					if(e.attribute("style") == "Image")
					{
						aCell = factory_->createCell(e.attribute("filename"),
							e.attribute("style"), ws);
						e.attributes().removeNamedItem("filename");
					}
					else
					{
						aCell = factory_->createCell(e.attribute("style"), ws);
					}

					//For all attributes
					//	       QDomNamedNodeMap attributes = e.attributes();
					//	       attributes.removeNamedItem("style");
					/*	       for(unsigned int i=0; i < attributes.count(); ++i)
					{
					QDomNode n = attributes.item(i);
					QDomAttr a = n.toAttr();
					aCell->setStyle(a.name(), a.value());
					}
					*/	       
					aCell->setText(e.text());
					aCell->setStyle(e.attribute("style",""));

					ws->addChild(aCell);
				}
				else
				{
					throw runtime_error("Unknown tag: <"+ std::string(e.tagName()) +">");
				}
			}
			n = n.nextSibling();
		}
	}
      
};
