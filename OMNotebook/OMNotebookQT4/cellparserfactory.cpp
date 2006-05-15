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

#include <exception>
#include <stdexcept>

#include "parserfactory.h"
#include "xmlparser.h"
#include "notebookparser.h"


namespace IAEX
{
   
   /*! \class CellParserFactory
    * \brief Nows how to open xml and nb files.
    *
    * This factory class knows how to open different fileformats. If a
    * new fileformat should be added the code for parsing the new format.
    *
	* Do not forget to delete a parser when it is not used anymore.
	*
	*
    * \todo Check for whitespaces in filename. Whitespaces at the end
    * of a file should be taken care of in some way.(Ingemar Axelsson)
    *
    */
   CellParserFactory::CellParserFactory(){}
   CellParserFactory::~CellParserFactory(){}
   
   NBParser *CellParserFactory::createParser(QString filename, Factory *f, Document *document, int readmode)
   {
      // PORT >>filename = filename.stripWhiteSpace();
	  filename = filename.trimmed();

	  
	  if( filename.endsWith(".onb", Qt::CaseInsensitive) ||
		  filename.endsWith(".xml", Qt::CaseInsensitive) )
      { 
		 return new XMLParser(filename, f, document, readmode);//openXMLFile(filename);
      }
      else if(filename.endsWith(".nb", Qt::CaseInsensitive))
      {
		 return new NotebookParser(filename, f, readmode); //openNotebookFile(filename);
      }
      else
      {
		 throw runtime_error("Can only open files ending with .onb or .nb,\n(can open old OMNotebooks file that ends with .xml)");
      }
   }
};
