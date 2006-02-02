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

// FILE/CLASS ADDED 2005-12-12 /AF

/*! 
 * \file commandunit.h
 * \author Anders Fernström
 */

#ifndef COMMANDUNIT_H
#define COMMANDUNIT_H

//QT Headers
#include <QtCore/QHash>
#include <QtCore/QString>


namespace IAEX
{
	/*! 
	 * \class CommandUnit
	 * \author Anders Fernström
	 * \date 2005-12-12
	 * 
	 * \brief A class that store an omc command
	 */
	class CommandUnit
	{
	public:
		CommandUnit( QString name ) : name_(name){}
		virtual ~CommandUnit(){}

		QString name(){ return name_; }
		QString fullName()
		{
			QString tmp = name_;
			QHash<QString,QString>::iterator d_iter = datafields_.begin();
			while( d_iter != datafields_.end() )
			{
				tmp.replace( d_iter.key(), d_iter.value() );
				++d_iter;
			}

			return tmp;
		}
		QString helptext(){ return helptext_; }

		int numbersField(){ return datafields_.size(); }
		QString datafield( QString fieldID )
		{ 
			if( datafields_.contains( fieldID ))
				return datafields_[fieldID];
			else
				return QString::null;
		}
		void addDataField( QString fieldID, QString data )
		{
			datafields_[fieldID] = data;
		}

		void setHelptext( QString text ){ helptext_ = text; }

	private:
		QString name_;
		QHash<QString,QString> datafields_;
		QString helptext_;
	};
}

#endif
