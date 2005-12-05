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

#ifndef _NOTEBOOK_COMMANDS_H
#define _NOTEBOOK_COMMANDS_H

//STD Headers
#include <iostream>
#include <stdexcept>
#include <exception>

//QT Headers
#include <qdom.h>
#include <qfile.h>

#include "command.h"
#include "celldocument.h"
#include "application.h"
#include "serializingvisitor.h"

using namespace std;

namespace IAEX
{
	/*! \class SaveDocumentCommand
	* \brief Saves the document.
	*/
	class SaveDocumentCommand : public Command
	{
	public:
		SaveDocumentCommand(Document *doc) : doc_(doc)
		{
			filename_ = doc_->getFilename();
		}
		SaveDocumentCommand(Document *doc, const QString &filename)
			:filename_(filename), doc_(doc){}
		virtual ~SaveDocumentCommand(){}
		void execute()
		{
			try
			{
				QDomDocument doc("qtNotebook");
				QDomElement root = doc.createElement("Notebook");
				doc.appendChild(root);

				SerializingVisitor save(root, doc);
				doc_->runVisitor(save);

				//Write to file.
				QFile file(filename_);
				if(file.open(IO_WriteOnly))
				{
					// Hade to change from 'doc.toString()' to 
					// 'doc.toCString()', so the xml file was saved in
					// UTF-8, otherwise swedish letters didn't work.
					// AF, 2005-09-28
					QTextStream filestream(&file);
					filestream << doc.toCString();
					file.close();

					doc_->setFilename( filename_ ); //AF
					doc_->setSaved( true ); //AF
				}
				else
				{
					throw runtime_error("Could not save documet to file: " + string(filename_));
				}
			}
			catch(exception &e)
			{
				cerr << "SaveDocumentCommand(), Exception: " << e.what() << endl;
			}
		}
	private:
		QString filename_;
		Document *doc_;
	};

	/*! \class OpenFileCommand
	* 
	* Opens the specified filename.
	*
	*/
	class OpenFileCommand : public Command
	{
	public:
		OpenFileCommand(const QString &filename) : filename_(filename){}
		virtual ~OpenFileCommand(){}
		void execute()
		{
			try
			{
				application()->open(filename_);
			}
			catch(exception &e)
			{
				cerr << "OpenFileCommand(), Exception: " << e.what() << endl;
			}
		}
	private:
		QString filename_;
	};

	/*! \class CloseFileCommand
	*
	* Closes the current document. 
	*/
	class CloseFileCommand : public Command
	{
	public:
		CloseFileCommand(){}
		virtual ~CloseFileCommand(){}
		void execute()
		{
			try
			{

				document()->close();
			}
			catch(exception &e)
			{
				cerr << "CloseFileCommand(), Exception: " << e.what() << endl;
			}
		}
	};

	/*! \class NewFileCommand
	*
	* Create a new document in a notebook window
	*/
	class NewFileCommand : public Command
	{
	public:
		NewFileCommand(){}
		virtual ~NewFileCommand(){}
		void execute()
		{
			try
			{
				/*
				Document *doc = document();
				doc = new CellDocument( application(), QString::null );
				*/
			}
			catch(exception &e)
			{
				cerr << "NewFileCommand(), Exception: " << e.what() << endl;
			}
		}
	};
};

#endif
