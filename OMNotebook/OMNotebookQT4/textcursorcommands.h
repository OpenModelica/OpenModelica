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

/*! 
 * \file cellcommands.h
 * \author Anders Fernström
 * \date 2005-11-03
 *
 * \brief Describes different textcursor commands
 */

#ifndef TEXTCURSORCOMMANDS_H
#define TEXTCURSORCOMMANDS_H

//IAEX Headers
#include "command.h"
#include "application.h"


using namespace std;

namespace IAEX
{
	// Added 2006-02-07 AF
	class TextCursorCutText : public Command
	{
	public:
		TextCursorCutText(){}
		virtual ~TextCursorCutText(){}
		virtual QString commandName(){ return QString("TextCursorCutText"); }
		void execute();
	};

	// Added 2006-02-07 AF
	class TextCursorCopyText : public Command
	{
	public:
		TextCursorCopyText(){}
		virtual ~TextCursorCopyText(){}
		virtual QString commandName(){ return QString("TextCursorCopyText"); }
		void execute();
	};


	// Added 2006-02-07 AF
	class TextCursorPasteText : public Command
	{
	public:
		TextCursorPasteText(){}
		virtual ~TextCursorPasteText(){}
		virtual QString commandName(){ return QString("TextCursorPasteText"); }
		void execute();
	};

	class TextCursorChangeFontFamily : public Command
	{
	public:
		TextCursorChangeFontFamily(QString family)
			: family_(family){}
		virtual ~TextCursorChangeFontFamily(){}
		virtual QString commandName(){ return QString("TextCursorChangeFontFamily"); }
		void execute();

	private:
		QString family_;
	};


	class TextCursorChangeFontFace : public Command
	{
	public:
		TextCursorChangeFontFace(int face)
			: face_(face){}
		virtual ~TextCursorChangeFontFace(){}
		virtual QString commandName(){ return QString("TextCursorChangeFontFace"); }
		void execute();

	private:
		int face_;
	};


	class TextCursorChangeFontSize : public Command
	{
	public:
		TextCursorChangeFontSize(int size)
			: size_(size){}
		virtual ~TextCursorChangeFontSize(){}
		virtual QString commandName(){ return QString("TextCursorChangeFontSize"); }
		void execute();

	private:
		int size_;
	};


	class TextCursorChangeFontStretch : public Command
	{
	public:
		TextCursorChangeFontStretch(int stretch)
			: stretch_(stretch){}
		virtual ~TextCursorChangeFontStretch(){}
		virtual QString commandName(){ return QString("TextCursorChangeFontStretch"); }
		void execute();

	private:
		int stretch_;
	};


	class TextCursorChangeFontColor : public Command
	{
	public:
		TextCursorChangeFontColor(QColor color)
			: color_(color){}
		virtual ~TextCursorChangeFontColor(){}
		virtual QString commandName(){ return QString("TextCursorChangeFontColor"); }
		void execute();

	private:
		QColor color_;
	};


	class TextCursorChangeTextAlignment : public Command
	{
	public:
		TextCursorChangeTextAlignment(int alignment)
			: alignment_(alignment){}
		virtual ~TextCursorChangeTextAlignment(){}
		virtual QString commandName(){ return QString("TextCursorChangeTextAlignment"); }
		void execute();

	private:
		int alignment_;
	};


	class TextCursorChangeVerticalAlignment : public Command
	{
	public:
		TextCursorChangeVerticalAlignment(int alignment)
			: alignment_(alignment){}
		virtual ~TextCursorChangeVerticalAlignment(){}
		virtual QString commandName(){ return QString("TextCursorChangeVerticalAlignment"); }
		void execute();

	private:
		int alignment_;
	};

	
	class TextCursorChangeMargin : public Command
	{
	public:
		TextCursorChangeMargin(int margin)
			: margin_(margin){}
		virtual ~TextCursorChangeMargin(){}
		virtual QString commandName(){ return QString("TextCursorChangeMargin"); }
		void execute();

	private:
		int margin_;
	};

	
	class TextCursorChangePadding : public Command
	{
	public:
		TextCursorChangePadding(int padding)
			: padding_(padding){}
		virtual ~TextCursorChangePadding(){}
		virtual QString commandName(){ return QString("TextCursorChangePadding"); }
		void execute();

	private:
		int padding_;
	};

	
	class TextCursorChangeBorder : public Command
	{
	public:
		TextCursorChangeBorder(int border)
			: border_(border){}
		virtual ~TextCursorChangeBorder(){}
		virtual QString commandName(){ return QString("TextCursorChangeBorder"); }
		void execute();

	private:
		int border_;
	};


	class TextCursorInsertImage : public Command
	{
	public:
		TextCursorInsertImage(QString filepath, QSize size)
			: filepath_(filepath), height_(size.height()), width_(size.width()){}
		virtual ~TextCursorInsertImage(){}
		virtual QString commandName(){ return QString("TextCursorInsertImage"); }
		void execute();

	private:
		QString filepath_;
		int height_;
		int width_;
	};


	class TextCursorInsertLink : public Command
	{
	public:
		TextCursorInsertLink( QString filepath, QTextCursor& cursor_ )
			: filepath_(filepath), cursor(cursor_){}
		virtual ~TextCursorInsertLink(){}
		virtual QString commandName(){ return QString("TextCursorInsertLink"); }
		void execute();

	private:
		QString filepath_;
		QTextCursor cursor;
	};
}

#endif

