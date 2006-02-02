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

// FILE/CLASS ADDED 2005-10-26 /AF

/*! 
 * \file cellstyle.h
 * \author Anders Fernström
 */

#ifndef CELLSTYLE_H
#define CELLSTYLE_H

//QT Headers
#include <QtCore/QString>
#include <QtGui/QTextCharFormat>
#include <QtGui/QTextFrameFormat>


namespace IAEX
{	
	/*! 
	 * \class CellStyle
	 * \author Anders Fernström
	 * \date 2005-10-26
	 * \date 2005-11-15 (update)
	 * 
	 * \brief A class that store the different styleoptions that 
	 * can be changed in a cell.
	 *
	 * 2005-11-10 AF, Added some default values in the constructor
	 * 2005-11-15 AF, Added some more default values
	 */
	class CellStyle
	{
	public:
		CellStyle()
		{
			textFormat_.setFontFamily( "Times New Roman" );
			textFormat_.setFontItalic( false );
			textFormat_.setFontOverline( false );
			textFormat_.setFontStrikeOut( false );
			textFormat_.setFontUnderline( false );
			textFormat_.setFontWeight( QFont::Normal );
			textFormat_.setFontPointSize( 12 );

			textFormat_.setForeground( QBrush( QColor(0,0,0) ));
		}
		virtual ~CellStyle(){}

		QString name(){ return name_; }
		QTextCharFormat* textCharFormat(){ return &textFormat_; }
		QTextFrameFormat* textFrameFormat(){ return &frameFormat_; }
		int alignment(){ return alignment_; }

		void setName( QString name ){ name_ = name; }
		void setTextCharFormat( QTextCharFormat format ){ textFormat_ = format; }
		void setTextFrameFormat( QTextFrameFormat format ){ frameFormat_ = format; }
		void setAlignment( int alignment ){ alignment_ = alignment; }

	private:
		QString name_;
		QTextCharFormat textFormat_;
        QTextFrameFormat frameFormat_;
		int alignment_;
	};
}

#endif
