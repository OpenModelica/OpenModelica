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

/*! \file stylesheet.h
 * \author Ingemar Axelsson
 */

#ifndef STYLESHEET_H
#define STYLESHEET_H

#include <qstylesheet.h>
#include <qstring.h>
#include <qdom.h>
#include <qtextedit.h>
//#include <qtextbrowser.h>
#include <vector>

using namespace std;

namespace IAEX
{

   class Stylesheet : public QObject
   {
      Q_OBJECT
      
   public:
      static Stylesheet *instance(const QString &filename);
      
      QStyleSheet *getStyle(QStyleSheet *sheet, 
			    const QString &style) const;

      QStyleSheet *getStyle(QStyleSheet *sheet,
			    const QString &attribute, 
			    const QString &value) const;

      QString getStyle(QTextEdit *text, 
		       const QString &style) const;
      
      vector<QString> getAvailableStyles() const;
      void removeTagsFromString(QString &txt, const QString &style);
   protected:
      void traverseStyleSettings(QDomNode p, QStyleSheetItem *item) const;
      void parseMarginTag(QDomElement f, QStyleSheetItem *item) const;
      void parseAlignmentTag(QDomElement f, QStyleSheetItem *item) const;
      void parseVAlignmentTag(QDomElement f, QStyleSheetItem *item) const;
      void parseWhitespaceTag(QDomElement f, QStyleSheetItem *item) const;
      void parseFontTag(QDomElement f, QStyleSheetItem *item) const;
      void parseListstyleTag(QDomElement f, QStyleSheetItem *item) const;
      
   private:
      Stylesheet(const QString &filename);

      QDomDocument *doc_;
      static Stylesheet *instance_;

      vector<QString> styles_;
   };
}
#endif
