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

#include "smlinteractiveenvironment.h"

namespace IAEX
{
   /*! \class SmlInteractiveEnvironment
    *
    * \brief Implements evaluation for Standard ML code.
    *
    *
    * \todo Implement as singleton. All environments should use the
    * same process.
    *
    * \todo Add some settings so it is possible to change the path to
    * the sml application easily.
    */
   SmlInteractiveEnvironment::SmlInteractiveEnvironment()
      : smlprocess_(0)
   { 
      startProcess();
   }

   
   SmlInteractiveEnvironment::~SmlInteractiveEnvironment()
   {
      killProcess();
   }
   
   QString SmlInteractiveEnvironment::getResult()
   {
      return result_;
   }
   
   void SmlInteractiveEnvironment::evalExpression(QString &expr)
   {
      //Flush?
      smlprocess_->writeToStdin(QString(";"));
      //startProcess();
      smlprocess_->writeToStdin(expr);

      //smlprocess_->closeStdin();
   }
   
   void SmlInteractiveEnvironment::updateErrorOutput()
   {
      if(smlprocess_->isRunning())
      {	 
	 result_ = QString("<font color=\"red\">").append(
	    QString(smlprocess_->readStderr())).append("</font>");
      }
   }
   
   void SmlInteractiveEnvironment::updateOutput() 
   {
      result_ = QString(smlprocess_->readStdout());
   }

   void SmlInteractiveEnvironment::startProcess()
   { 
      //if(!smlprocess_->isRunning())
      if(!smlprocess_)
      {
	 smlprocess_ = new QProcess(this);
	 smlprocess_->addArgument("sml");
	 QObject::connect(smlprocess_, SIGNAL(readyReadStderr()),
			  this, SLOT(updateErrorOutput()));
	 QObject::connect(smlprocess_, SIGNAL(readyReadStdout()),
			  this, SLOT(updateOutput()));
      
 	 smlprocess_->start();
      } 
   }
   
   void SmlInteractiveEnvironment::killProcess()
   {
      smlprocess_->kill();//tryTerminate();      
      smlprocess_ = 0;
   } 
}
