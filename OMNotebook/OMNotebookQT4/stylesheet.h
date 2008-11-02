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

// REMADE LARGE PART OF THIS CLASS 2005-10-26 /AF

/*!
* \file stylesheet.h
* \author Anders Fernström (and Ingemar Axelsson)
* \date 2005-10-26
*
* \brief Had to remake the class to be compatible with the richtext
* system that is used in QT4. The old file have been renamed to
* 'stylesheet.h.old' /AF
*/

#ifndef STYLESHEET_H
#define STYLESHEET_H


//STD Headers
#include <vector>

//QT Headers
#include <QtCore/QString>
#include <QtCore/QHash>
#include <QtXml/qdom.h>

//IAEX Headers
#include "cellstyle.h"


namespace IAEX
{
	class Stylesheet : public QObject
	{
		Q_OBJECT

	public:
		static Stylesheet *instance(const QString &filename);

		CellStyle getStyle(const QString &style);
		QHash<QString,CellStyle> getAvailableStyles() const;
		std::vector<QString> getAvailableStyleNames() const;

	protected:
		void initializeStyle();
		void traverseStyleSettings(QDomNode p, CellStyle *item) const;
		void parseBorderTag(QDomElement element, CellStyle *item) const;
		void parseAlignmentTag(QDomElement element, CellStyle *item) const;
		void parseFontTag(QDomElement element, CellStyle *item) const;
		void parseChapterLevelTag(QDomElement element, CellStyle *item) const;

	private:
		Stylesheet(const QString &filename);

		QDomDocument *doc_;
		static Stylesheet *instance_;

		QHash<QString,CellStyle> styles_;
		std::vector<QString> styleNames_;
	};
}
#endif
