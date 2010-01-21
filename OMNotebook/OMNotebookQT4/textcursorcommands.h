/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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

