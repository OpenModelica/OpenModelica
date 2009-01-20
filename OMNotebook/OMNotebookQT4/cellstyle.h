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
	 * \date 2006-03-02 (update)
	 *
	 * \brief A class that store the different styleoptions that
	 * can be changed in a cell.
	 *
	 * 2005-11-10 AF, Added some default values in the constructor
	 * 2005-11-15 AF, Added some more default values
	 * 2006-03-02 AF, Added a variable and functions that allows the
	 * style to be hidden from the style menu
	 * 2006-03-02 AF, Added a variable and functions that holds the
	 * styles chapter level, if any
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

			// 2006-03-02 AF, defalut visibliity
			visible_ = true;

			// 2006-03-02 AF, defalut chapter level
			chapterLevel_ = 0;
		}
		virtual ~CellStyle(){}

		QString name(){ return name_; }
		QTextCharFormat* textCharFormat(){ return &textFormat_; }
		QTextFrameFormat* textFrameFormat(){ return &frameFormat_; }
		int alignment(){ return alignment_; }
		bool visible(){ return visible_; }					// Added 2006-03-02 AF
		int chapterLevel(){ return chapterLevel_; }			// Added 2006-03-02 AF

		void setName( QString name ){ name_ = name; }
		void setTextCharFormat( QTextCharFormat format ){ textFormat_ = format; }
		void setTextFrameFormat( QTextFrameFormat format ){ frameFormat_ = format; }
		void setAlignment( int alignment ){ alignment_ = alignment; }
		void setVisible( bool visible ){ visible_ = visible; }			// Added 2006-03-02 AF
		void setChapterLevel( int level ){ chapterLevel_ = level; }		// Added 2006-03-02 AF

	private:
		QString name_;
		QTextCharFormat textFormat_;
        QTextFrameFormat frameFormat_;
		int alignment_;

		bool visible_;						// Added 2006-03-02 AF
		int chapterLevel_;					// Added 2006-03-02 AF
	};
}

#endif
