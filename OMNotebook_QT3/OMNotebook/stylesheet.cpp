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

#include <exception>
#include <iostream>
#include <cstdlib>

#include <qfile.h>
#include <qstring.h>
#include <qtextedit.h>
#include <qcolor.h>

#include "stylesheet.h"
using namespace std;

namespace IAEX
{

/*! \class Stylesheet 
 * \brief Reads a stylesheet file and creates
 * correct QStyleSheet objects with the defined format.
 *
 *
 * \todo Add support for caching different styles, this will speed up
 * the creation of cells a little bit. It is just the first cell of
 * that type that will take time. Use some variant of the Singleton
 * pattern.
 *  
 */

/*! \brief Reads a file and create a DOM tree from that file.
 * \author Ingemar Axelsson 
 * \date 2004
 *
 * Reads a given file and tries to construct a DOM tree from that
 * file. If the file is corrupt the whole program will exit.
 *
 * \todo Add some exceptions here. Maybe program should not
 * exit. There are many way of dealing whit this error.
 * 
 * \todo Add stylesheet to IAEX namespace.
 *
 * \param filename File to be read.
 */
	Stylesheet::Stylesheet(const QString &filename)
	{		
		//read a stylesheet file.
		doc_ = new QDomDocument("StyleDoc");

		QFile file(filename);

		if(!file.open(IO_ReadOnly))
		{//return -1
			std::cerr << "Could not open file: " << filename;

			// 2005-10-03 AF, thorw exception insted of exit
			throw std::exception( "Could not open file: " + filename);
			//std::exit(-1);
		}

		//Här kan det bli feeeeel!    
		if(!doc_->setContent(&file))
		{
			file.close();
			//return -2;
			std::cerr << "Could not read content from file: " << filename
				<< " Probably some syntax error in the xml file";
			std::exit(-2);
		}
		file.close();

		//Get all available styles.
		QDomElement root = doc_->documentElement();
		QDomNode n = root.firstChild();

		//Search for the correct style
		while(!n.isNull())
		{
			QDomElement e = n.toElement();
			if(!e.isNull())
			{
				if(e.tagName() == "style")
				{
					styles_.push_back(QString(e.attribute("name","")));	    
				}
			}
			n = n.nextSibling();
		}
	}

   Stylesheet *Stylesheet::instance_ = 0;

   /*
    * \todo Make it possible to change stylesheet file.
    */
   Stylesheet *Stylesheet::instance(const QString &filename)
   {
      if(!instance_)	 
	 instance_ = new Stylesheet(filename);
      
      return instance_;
   }

   vector<QString> Stylesheet::getAvailableStyles() const
   {
      return styles_;
   }

   void Stylesheet::removeTagsFromString(QString &txt, const QString &style)
   {
      QDomElement root = doc_->documentElement();
      QDomNode n = root.firstChild();
      
      //Search for the correct style
      while( !n.isNull())
      {
	 QDomElement e = n.toElement();
	 if(!e.isNull())
	 {
	    if(e.attribute("name","") == style)
	    {
	       //cerr << "Before: " << txt << endl;
	       QString otag = e.attribute("tag","").prepend("<").append(">");
	       QString ctag = e.attribute("tag","").prepend("</").append(">");
	       txt.remove(otag);
	       txt.remove(ctag);

	       //cerr << "After: " << txt << endl;
	    }
	 }	    
	 n = n.nextSibling();
      }
   }

/*! 
 * \example stylesheet.xml
 *
 * There are a lot of different attribute values that can be
 * used. Here is a list of all values that can be used for different
 * attributes:
 * - style
 *   - name (string)
 * - margin
 *   - left (attribute, integer)
 *   - right (attribute, integer)
 *   - top (attribute, integer)
 *   - bottom (attribute, integer)
 * - alignment
 *   - left
 *   - right
 *   - center
 *   - justify
 * - verticalalignment
 *   - baseline
 *   - sub  - subscription
 *   - super - superscription
 * - whitespacemode
 *   - normal
 *   - pre - preformatted
 *   - nowrap
 * - font
 *   - family - see Qt manual
 *   - size (integer)
 *   - weight 
 *	- 0..99
 *	- light
 *	- normal
 *	- demibold
 *	- bold
 * 	- black
 *   - italic
 *   - strikeout
 *   - underline
 *   - color
 *   	- red
 *   	- green
 *   	- blue
 *
 *
 * Read the examplefile if something is unclear.
 *
 */

/*! \brief Get the correct formatting for a textcell.
 * \author Ingemar Axelsson
 *
 * \deprecated
 * 
 * Get the correct formatting for a textcell depending on what type of
 * textcell it is. The formatting is defined in a xml document. Below
 * is an example of a stylesheet xml document. 
 *
 * \todo Implement so styles uses the standard tags instead of just one
 * single tag. Then this works almost as it seems to.
 *
 * \param sheet Stylesheet to use for getting properties. Maybe not used.
 * \param style String identifying which style to return.
 * \return A stylesheet with the properties given in the stylesheet file.
 */
   QStyleSheet *Stylesheet::getStyle(QStyleSheet *sheet, 
				     const QString &style) const
   {
      //Create a new stylesheet
      //QStyleSheet *mysheet = new QStyleSheet(this, 0);
      //QStyleSheetItem *styleitem = sheet->item("div"); //Should not be DIV
      QStyleSheetItem *styleitem = sheet->item("body");    
      
      ///Parse the XML DOM tree.
      QDomElement root = doc_->documentElement();
      QDomNode n = root.firstChild();
      
      //Search for the correct style
      while( !n.isNull())
      {
	 QDomElement e = n.toElement();
	 if(!e.isNull())
	 {
	    if(e.attribute("name","") == style)
	    {
	       //Rätt style. Läs in och skapa QStylesheet.
	       QDomNode p = e.firstChild();

	       traverseStyleSettings(p, styleitem);
	    }
	 }	    
	 n = n.nextSibling();
      }
    
      return sheet;
   }


/*! \brief wraps notebook text attributes to QT text attributes.
 * \author Ingemar Axelsson
 * \date 2004-12-10, 10:13:31
 *
 * \deprecated
 *
 * \todo Give this member a better name. It is not very selfexplaining.
 *
 * \param attribute notebook attribute name.
 * \param value notebook attribute value.
 * \returns A QStyleSheet pointer with the correct values inserted.
 */
   QStyleSheet *Stylesheet::getStyle(QStyleSheet *sheet, 
				     const QString &attribute, 
				     const QString &value) const
   {
      QStyleSheetItem *styleitem = sheet->item("div");
      if(attribute == "TextAlignment")
      {
	 if(value == "Left")
	 {
	    styleitem->setAlignment(Qt::AlignLeft);
	 }
	 else if(value == "Right")
	 {
	    styleitem->setAlignment(Qt::AlignRight);
	 }	
	 else	
	 {
	    std::cerr << "Alignment value not correct: " << value;
	 }
      }
      else if(attribute == "FontWeight")
      {	
	 int weight = std::atoi(value);
      
	 if(weight > 99 || weight <= 0)
	    weight = 50;
   
	 styleitem->setFontWeight(weight);
      }
      else if(attribute == "FontSlant")
      {
	 //This does only occur when italic is present.
	 //delete italic property to disable.
	 if(value =="Italic")
	 {
	    styleitem->setFontItalic(true);
	 }
      }
      else if(attribute == "FontSize")
      {
	 styleitem->setFontSize(std::atoi(value));
      }
      else
      {
	 //std::cerr << "Attribute: " << attribute  
	 //<< ", is not implemented." << std::endl;
      }

      return sheet;
   }

   /*! Changes the style on the textcell to style.
    *
    * \return Could be void!
    */
   QString Stylesheet::getStyle(QTextEdit *textedit, 
				const QString &style) const
   {
      //Try to just get plaintext!
      Qt::TextFormat tmp = textedit->textFormat();
      textedit->setTextFormat(Qt::PlainText);

      QString text = textedit->text();

//      cerr << "STYLESHEET: " << text << endl;
      textedit->setTextFormat(tmp);  

      //QString text = textedit->text();
      QStyleSheet *sheet = QStyleSheet::defaultSheet();//textedit->styleSheet();
      
      
      //Create a new stylesheet
      //QStyleSheet *mysheet = new QStyleSheet(this, 0);
      //QStyleSheetItem *styleitem = sheet->item("qt");    
      
      ///Parse the XML DOM tree.
      QDomElement root = doc_->documentElement();
      QDomNode n = root.firstChild();
      
      //Search for the correct style
      while( !n.isNull())
      {
	 QDomElement e = n.toElement();
	 if(!e.isNull())
	 {
	    if(e.attribute("name","") == style)
	    {
	       //Insert tag.
	       QString tag = e.attribute("tag", "");
	       QString otag = tag;
	       QString ctag = tag;
	       otag.prepend("<").append(">");
	       ctag.prepend("</").append(">");
	       
	       //Tag inputtext.
	       text = text.prepend(otag).append(ctag);

	       QStyleSheetItem *styleitem = sheet->item(tag);
	       
	       //Rätt style. Läs in och skapa QStylesheet.
	       QDomNode p = e.firstChild();

	       traverseStyleSettings(p, styleitem);

	       textedit->setStyleSheet(sheet);	       
	    }
	 }	    
	 n = n.nextSibling();
      }
      
      return text;
   }


   void	Stylesheet::traverseStyleSettings(QDomNode p, 
					  QStyleSheetItem *item) const
   {
      if(!item)
	 cerr << "TRAVERSE... No ITEM SET!!" << endl;

      while(!p.isNull())
      {
	 QDomElement f = p.toElement();
	 if(f.tagName() == "margin")
	 {
	    parseMarginTag(f, item);
	 }
	 else if(f.tagName() == "alignment")
	 {
	    parseAlignmentTag(f, item);
	 }
	 else if(f.tagName() == "verticalalignment")
	 {
	    parseVAlignmentTag(f, item);
	 }
	 else if(f.tagName() == "whitespacemode")
	 {	
	    parseWhitespaceTag(f, item);
	 }
	 else if(f.tagName() == "font")
	 {
	    parseFontTag(f, item);
	 }
	 else if(f.tagName() == "liststyle")
	 {
	    parseListstyleTag(f, item);
	 }	
	 else
	 {
	    std::cerr << "Style not known" << f.tagName();
	 }
	 
	 p = p.nextSibling();
      }
   }

   
   void Stylesheet::parseMarginTag(QDomElement f, QStyleSheetItem *item) const
   {
      if(f.attribute("left",""))
	 item->setMargin(QStyleSheetItem::MarginLeft,
			 std::atoi(f.attribute("left","")));
      if(f.attribute("right",""))
	 item->setMargin(QStyleSheetItem::MarginRight,
			 std::atoi(f.attribute("right","")));
      if(f.attribute("top",""))
	 item->setMargin(QStyleSheetItem::MarginTop,
			 std::atoi(f.attribute("top","")));
      if(f.attribute("bottom",""))
	 item->setMargin(QStyleSheetItem::MarginBottom,
			 std::atoi(f.attribute("bottom","")));
   }

   void Stylesheet::parseAlignmentTag(QDomElement f, 
				      QStyleSheetItem *item) const
   {
      if(f.text() == "left")
      {
	 item->setAlignment(Qt::AlignLeft);
      }
      else if(f.text() == "right")
      {
	 item->setAlignment(Qt::AlignRight);
      }	
      else if(f.text() == "center")
      {
	 item->setAlignment(Qt::AlignCenter);
      }
      else if(f.text() == "justify")
      {
	 item->setAlignment(Qt::AlignJustify);
      }
      else	
      {
	 std::cerr << "Alignment value not correct: " << f.text();
      }      
   }

   void Stylesheet::parseVAlignmentTag(QDomElement f,
				       QStyleSheetItem *item) const
   {
      //Ska den här vara möjlig över huvudtaget?
      if(f.text() == "baseline")
      {
	 item->setVerticalAlignment(QStyleSheetItem::VAlignBaseline);
      }
      else if(f.text() == "sub")
      {
	 item->setVerticalAlignment(QStyleSheetItem::VAlignSub);
      }
      else if(f.text() == "super")
      {
	 item->setVerticalAlignment(QStyleSheetItem::VAlignSuper);
      }
      else 
      {
	 std::cerr << "Value not defined: " << f.text();
      }
   }
   void Stylesheet::parseWhitespaceTag(QDomElement f,
				       QStyleSheetItem *item) const
   {
      if(f.text() == "normal")
      {
	 item->setWhiteSpaceMode(QStyleSheetItem::WhiteSpaceNormal);
      }
      else if(f.text() == "pre")
      {
	 item->setWhiteSpaceMode(QStyleSheetItem::WhiteSpaceNoWrap);
      }
      else if(f.text() == "nowrap")
      {
	 item->setWhiteSpaceMode(QStyleSheetItem::WhiteSpaceNoWrap);
      }
      else 
      {
	 std::cerr << "Value not defined: " << f.text();
      }
   }
   void Stylesheet::parseFontTag(QDomElement f,
				 QStyleSheetItem *item) const
   {
      //cerr << "ParseFontTag()" << endl;
      
      item->setFontItalic(false);
      //item->setFontStrikeOut(false);
      //item->setFontUnderline(false);

      QDomNode fontnode = f.firstChild();
      while(!fontnode.isNull())
      {	
	 QDomElement fontelement = fontnode.toElement();
	 
	 if(fontelement.tagName() == "family")
	 {
	    item->setFontFamily(fontelement.text());
	 }
	 else if(fontelement.tagName() == "size")
	 {
	    item->setFontSize(std::atoi(fontelement.text()));
	 }
	 else if(fontelement.tagName() == "weight")
	 {	
	    //Error check must be done!
	    int weight = 50; //Normal by default
	    if(fontelement.text() == "bold")
	    {
	       weight = 75;
	    }
	    else if(fontelement.text() == "demibold")
	    {
	       weight = 63;
	    }
	    else if(fontelement.text() == "light")
	    {
	       weight = 25;
	    }
	    else if(fontelement.text() == "black")
	    {
	       weight = 87;
	    }
	    else if(fontelement.text() == "normal")
	    {
	       weight = 50;
	    }
	    else 
	    {  //kolla storlek. 0 - 99... text ger 0.
	       weight = std::atoi(fontelement.text());
	       
	       if(weight > 99 || weight <= 0)
		  weight = 50;
	    }
	    
	    item->setFontWeight(weight);
	 }
	 else if(fontelement.tagName() == "italic")
	 {
	    //qDebug("setItalic");
	    //This does only occur when italic is present.
	    //delete italic property to disable.
	    item->setFontItalic(true);
	 }
	 else if(fontelement.tagName() == "strikeout")
	 {
	    item->setFontStrikeOut(true);
	 }
	 else if(fontelement.tagName() == "underline")
	 {
	    item->setFontUnderline(true);
	 }
	 else if(fontelement.tagName() == "color")
	 {
	    int red   = std::atoi(fontelement.attribute("red",""));
	    int green = std::atoi(fontelement.attribute("green",""));
	    int blue  = std::atoi(fontelement.attribute("blue",""));
	    
	    item->setColor(QColor(red, green, blue));
	 }
	 else
	 {
	    std::cerr << "font tag not specified: " 
		      << fontelement.tagName();
	 }
	 
	 fontnode = fontnode.nextSibling();
      }
   }
   
   void Stylesheet::parseListstyleTag(QDomElement f,
				      QStyleSheetItem *item) const
   {
      if(f.text() == "disc")
      {
	 item->setListStyle(QStyleSheetItem::ListDisc);
      }
      else if(f.text() == "circle")
      {
	 item->setListStyle(QStyleSheetItem::ListCircle);
      }
      else if(f.text() == "square")
      {
	 item->setListStyle(QStyleSheetItem::ListSquare);
      }
      else if(f.text() == "decimal")
      {
	 item->setListStyle(QStyleSheetItem::ListDecimal);
      }
      else if(f.text() == "loweralpha")
      {
	 item->setListStyle(QStyleSheetItem::ListLowerAlpha);
      }
      else if(f.text() == "upperalpha")
      {
	 item->setListStyle(QStyleSheetItem::ListUpperAlpha);
      }
      else
      {
	 std::cerr << "Value not defined: " << f.text();
      }
   }
}
