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

#include "windows.h"

#include <qobject.h>
#include <qmessagebox.h>
#include <qdir.h>

#include "cellapplication.h"
#include "celldocument.h"
#include "commandcenter.h"
#include "cellcommandcenter.h"
#include "cursorcommands.h"
#include "notebook.h"
#include "omcinteractiveenvironment.h"

namespace IAEX
{
	/*! \class CellApplication
	 *
	 * \brief Implements the application interface. This class is the
	 * main controller of the program.
	 *
	 * This class has the responsibility to open new windows, open new
	 * documents and handle commands. Commands are sent to a
	 * commandCenter object where they are executed and stored (they
	 * should be stored).
	 *
	 * \todo replace with QString::NULL! before shipping!!
	 *
	 * \todo Make it possible to open from commandline, give a filename.
	 */
	CellApplication::CellApplication(int &argc, char **argv)
		: QObject()
	{  
		app_ = new QApplication(argc, argv);

		// 2005-10-25 AF, added a check if omc is running
		try
		{
			new OmcInteractiveEnvironment();
		}
		catch( exception &e )
		{
#ifdef WIN32

			try
			{
				STARTUPINFO startinfo;
				PROCESS_INFORMATION procinfo;
				memset(&startinfo, 0, sizeof(startinfo));
				memset(&procinfo, 0, sizeof(procinfo));
				startinfo.cb = sizeof(STARTUPINFO);
				startinfo.wShowWindow = SW_MINIMIZE;
				startinfo.dwFlags = STARTF_USESHOWWINDOW;
				
				string parameter = "\"omc.exe\" +d=interactiveCorba";
				char *pParameter = new char[parameter.size() + 1];
				const char *cpParameter = parameter.c_str();
				strcpy(pParameter, cpParameter);

				bool flag = CreateProcess(NULL,pParameter,NULL,NULL,FALSE,CREATE_NEW_CONSOLE,NULL,NULL,&startinfo,&procinfo);

				Sleep(2000);

				if( !flag )
					throw std::exception("Unable to start OMC");
			}
			catch( exception &e )
			{
				QString msg = e.what();
				msg += "\nWas unable to start OMC! Closeing OMNotebook!";
				QMessageBox::warning( 0, "Error", msg, "OK" );
				std::exit(-1);
			}

#else

			QString msg = e.what();
			msg += "\nOMC not started! Closeing OMNotebook!";
			QMessageBox::warning( 0, "Error", msg, "OK" );
			std::exit(-1);

#endif
		}


		QObject::connect(app_, SIGNAL(lastWindowClosed()),
			app_, SLOT(quit()));

		//Create a commandCenter.
		cmdCenter_ = new CellCommandCenter(this);

		//open(QString("drmodelica.xml"));

		QDir dir;
		if( dir.exists( "DrModelica/DrModelica.nb" ))
			open(QString("DrModelica/DrModelica.nb")); 
		else
			open(QString::null);
		//open(QString("anders.xml"));
		//open(QString("HelloWorld.nb"));
		//open(QString::null);
	}

   int CellApplication::exec()
   {
      return app_->exec();
   }

   CellApplication::~CellApplication()
   {
      	// 2005-11-24 AF,
		// check if omc server is still runing, if its runing -> send quit() command
		try
		{
			OmcInteractiveEnvironment *omc = new OmcInteractiveEnvironment();
			omc->evalExpression( QString("quit()") );
			//omc->getResult();
			//delete omc;
		}
		catch( exception &e )
		{ return; }
   }

   void CellApplication::add(Document *d)
   {
      documents_.push_back(d);
   }
   
   void CellApplication::add(DocumentView *d)
   {
      views_.push_back(d);
      d->show();
   }

   CommandCenter *CellApplication::commandCenter()
   {
      return cmdCenter_;
   }

   void CellApplication::setCommandCenter(CommandCenter *c)
   {
      cmdCenter_ = c;
      cmdCenter_->setApplication(this);
   }

   void CellApplication::open(const QString filename)
   {
      //1. Create a new document.
      Document *d = new CellDocument(this, filename);
      add(d);

      //2. Create a new View.
	  // 2005-09-22 AF: Added 'filename' in NotebookWindow() call
      DocumentView *v = new NotebookWindow(d, filename);
      add(v);
      v->show();
      //commandCenter()->executeCommand(new OpenFileCommand());
   }

   /*! 
    * \todo Create a pasteboard class as a Singleton that should be
    * used instead of having a singleton inside the application class.
    * Other things to do is to use the systemwide pasteboard instead.
    */
   void CellApplication::addToPasteboard(Cell *c)
   {
      pasteboard_.push_back(c);
   }
   
   /*!
	* This is used to clear the pasteboard. This is an ugly solution.
	*/
   void CellApplication::clearPasteboard()
   {
	  pasteboard_.clear();
   }

   /*!
    * returns a vector with all content of the pasteboard.
    *
    * When requesting the pasteboard, clear pasteboard. 
    */
   vector<Cell*> CellApplication::pasteboard()
   {
      return pasteboard_;
   }
}
