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

// REMADE LARGE PART OF THIS CLASS 2005-10-26 /AF

/*!
* \file stylesheet.cpp
* \author Anders Fernström (and Ingemar Axelsson)
* \date 2005-10-26
*
* \brief Had to remake the class to be compatible with the richtext
* system that is used in QT4. The old file have been renamed to
* 'stylesheet.cpp.old' /AF
*/


//STD Headers
#include <exception>
#include <stdexcept>
#include <iostream>
#include <cstdlib>

//QT Headers
#include <QtCore/QFile>
#include <QtCore/QString>
#include <QtGui/QColor>

//IAEX Headers
#include "stylesheet.h"



namespace IAEX
{
  /*!
   * \class Stylesheet
   * \author Anders Fernström (and Ingemar Axelsson)
   * \date 2005-10-26
   *
   * \brief Reads a stylesheet file and creates CellStyle object
   * for all styles in the stylesheet file.
   */

  /*!
   * \brief Reads a given file and tries to construct a DOM tree
    * from that file. If the file is corrupt a exception will be thrown.
   * \author Ingemar Axelsson (large part of this function is untouched)
   *
   * \param filename The file that will be read.
   */
  Stylesheet::Stylesheet(const QString filename)
  {
    //read a stylesheet file.
    doc_ = new QDomDocument("StyleDoc");

    QFile file(filename);
    if(!file.open(QIODevice::ReadOnly))
    {
      // 2005-10-03 AF, throw exception instead of exit
      std::string tmp = "Could not open file: " + filename.toStdString();
      throw std::runtime_error( tmp.c_str() );
    }

    //Här kan det bli feeeeel!
    if(!doc_->setContent(&file))
    {
      file.close();

      // 2005-10-26 AF, throw exception instead of exit
      std::string tmp = "Could not read content from file: " +
        filename.toStdString() +
        " Probably some syntax error in the xml file";
      throw std::runtime_error( tmp.c_str() );
    }
    file.close();


    // initialize all the styles in the stylesheet file
    initializeStyle();
  }

  Stylesheet *Stylesheet::instance_ = 0;

  /*
   * \author Anders Fernström
   * \date 2005-10-26
   *
   * \brief Instance the Stylesheet object.
   * \author Ingemar Axelsson (this function is untouched)
   *
   * \param filename The file that will be read.
   * \return The Stylesheet object
   */
  Stylesheet *Stylesheet::instance(const QString &filename)
  {
    if(!instance_)
      instance_ = new Stylesheet(filename);

    return instance_;
  }

  /*
   * \author Anders Fernström
   * \date 2005-10-26
   *
   * \brief Returns the CellStyle that correspondence with the
   * style name. The function retuns a CellStyle with the name
   * null if no CellStyle is found with the style name.
   *
   * \param style The name of the style you looking for
   * \return A CellStyle
   */
  CellStyle Stylesheet::getStyle( const QString &style )
  {
    if( styles_.contains( style ))
      return styles_.value( style );
    else
    {
      CellStyle tmp;
      tmp.setName( "null" );
      return tmp;
    }
  }

  /*
   * \author Anders Fernström
   * \date 2005-10-26
   *
   * \brief Returns all the CellStyles.
   * \return A QHash with all CellStyles mapped to there name
   */
  QHash<QString,CellStyle> Stylesheet::getAvailableStyles() const
  {
    return styles_;
  }

  /*
   * \author Anders Fernström
   * \date 2005-10-26
   *
   * \brief Returns all the CellStyle names of the visible styles
   * \return A std::vector with all CellStyle names
   */
  std::vector<QString> Stylesheet::getAvailableStyleNames() const
  {
    return styleNames_;
  }

  /*!
   * \example stylesheet.xml
   *
   * There are a lot of different attribute values that can be used.
   * Here is a list of all values that can be used for different
   * attributes:
   *  - style
   *    > name [attribute, {string}]
   *    > visible [attribute, {"true", "false"}]
   *  - border
   *    > value [attribute, {integer}]    //border thickness
   *    > margin [attribute, {integer}]
   *    > padding [attribute, {integer}]
   *  - alignment
   *    > value [attribute, {"left", "right", "center", "justify"}]
   *    > vertical [attribute, {"baseline", "sub", "super"}]
   *  - font
   *    - family [{string}]
   *    - size [{integer}]
   *    - weight [{integer <0-99>, "light", "normal", "demibold", "bold", "black"}]
   *    - stretch [{"ultracondensed", "extracondensed", "condensed", "semicondensed", "unstretched", "semiexpanded", "expanded", "extraexpanded", "ultraexpanded"}]
   *    - italic
   *    - strikeout
   *    - underline
   *    - overline
   *    - color
   *      > red [attribute, {integer <0-255>}]
   *      > green [attribute, {integer <0-255>}]
   *      > blue [attribute, {integer <0-255>}]
   *  - chapter [{string}]
   *
   * Read the stylesheet file if something is unclear.
   */


  /*
   * \author Anders Fernström
   * \date 2005-10-26
   *
   * \brief loop through the DOM tree and creates CellStyle after
   * specified styles.
   */
  void Stylesheet::initializeStyle()
  {
    QDomElement root = doc_->documentElement();
    QDomNode n = root.firstChild();

    // loop through the DOM tree
    while( !n.isNull() )
    {
      QDomElement e = n.toElement();
      if( !e.isNull() )
      {
        if( e.tagName() == "style" )
        {
          CellStyle style;
          style.setName( e.attribute( "name" ));

          // get visibility
          if( e.attribute( "visible", "true" ).indexOf( "false", 0, Qt::CaseInsensitive ) < 0 )
                        style.setVisible( true );
          else
            style.setVisible( false );

          QDomNode node = e.firstChild();
          traverseStyleSettings(node, &style);

          styles_.insert( style.name(), style );

          // 2006-03-02 AF, only add styles that are visible
          if( style.visible() )
            styleNames_.push_back( style.name() );
        }
      }
      n = n.nextSibling();
    }
  }

  /*
   * \author Anders Fernström
   * \date 2005-10-26
   *
   * \brief traverse through a style tag in the DOM tree
   */
  void Stylesheet::traverseStyleSettings( QDomNode node, CellStyle *item ) const
  {
    if( !item )
      throw std::runtime_error( "STYLESHEET TRAVERSE... No ITEM SET!!" );

    while( !node.isNull() )
    {
      QDomElement element = node.toElement();

      if( element.tagName() == "border" )
        parseBorderTag( element, item );
      else if( element.tagName() == "alignment" )
        parseAlignmentTag( element, item );
      else if( element.tagName() == "font" )
        parseFontTag( element, item );
      else if( element.tagName() == "chapterlevel" )
        parseChapterLevelTag( element, item );
      else
        std::cout << "Tag not known" << element.tagName().toStdString();

      node = node.nextSibling();
    }
  }

  /*
   * \author Anders Fernström
   * \date 2005-10-26
   *
   * \brief Parse the BORDER tag
   */
  void Stylesheet::parseBorderTag( QDomElement element,
    CellStyle *item ) const
  {
    bool ok;

    // VALUE
    int value = element.attribute( "value", "" ).toInt(&ok);
    if(ok)
      item->textFrameFormat()->setBorder( value );

    // MARGIN
    value = element.attribute( "margin", "" ).toInt(&ok);
    if(ok)
      item->textFrameFormat()->setMargin( value );

    // PADDING
    value = element.attribute( "padding", "" ).toInt(&ok);
    if(ok)
      item->textFrameFormat()->setPadding( value );
  }

  /*
   * \author Anders Fernström
   * \date 2005-10-26
   *
   * \brief Parse the ALIGNMENT tag
   */
  void Stylesheet::parseAlignmentTag( QDomElement element,
    CellStyle *item ) const
  {
    // ALIGNMENT
    QString alignment = element.attribute( "value", "left" );
    if( alignment == "left" )
      item->setAlignment( Qt::AlignLeft );
    else if( alignment == "right" )
      item->setAlignment( Qt::AlignRight );
    else if( alignment == "center" )
      item->setAlignment( Qt::AlignCenter );
    else if( alignment == "justify" )
      item->setAlignment( Qt::AlignJustify );
    else
      std::cout << "Alignment value not correct: " << alignment.toStdString();


    // VERTICAL ALIGNMENT
    QString vertical = element.attribute( "vertical", "baseline" );
    if( vertical == "baseline" )
      item->textCharFormat()->setVerticalAlignment( QTextCharFormat::AlignNormal );
    else if( vertical == "sub" )
      item->textCharFormat()->setVerticalAlignment( QTextCharFormat::AlignSubScript );
    else if( vertical == "super" )
      item->textCharFormat()->setVerticalAlignment( QTextCharFormat::AlignSuperScript );
    else
      std::cout << "Vertical Alignment value not correct: " << vertical.toStdString();
  }

  /*
   * \author Anders Fernström
   * \date 2005-10-26
   *
   * \brief Parse the FONT tag
   */
  void Stylesheet::parseFontTag( QDomElement element,
    CellStyle *item ) const
  {
    QDomNode fontNode = element.firstChild();
    while( !fontNode.isNull() )
    {
      QDomElement fontElement = fontNode.toElement();
      if( !fontElement.isNull() )
      {
        // FAMILY
        if( fontElement.tagName() == "family" )
        {
          item->textCharFormat()->setFontFamily( fontElement.text() );
        }
        // SIZE
        else if( fontElement.tagName() == "size" )
        {
          bool ok;
          int size = fontElement.text().toInt(&ok);

          if(ok)
            item->textCharFormat()->setFontPointSize( size );
          else
            item->textCharFormat()->setFontPointSize( 12 );
        }
        // WEIGHT
        else if( fontElement.tagName() == "weight" )
        {
          QString weight = fontElement.text();

          if( weight == "light" )
            item->textCharFormat()->setFontWeight( QFont::Light );
          else if( weight == "normal" )
            item->textCharFormat()->setFontWeight( QFont::Normal );
          else if( weight == "demibold" )
            item->textCharFormat()->setFontWeight( QFont::DemiBold );
          else if( weight == "bold" )
            item->textCharFormat()->setFontWeight( QFont::Bold );
          else if( weight == "black" )
            item->textCharFormat()->setFontWeight( QFont::Black );
          else
          {
            bool ok;
            int size = weight.toInt(&ok);

            if(ok)
              item->textCharFormat()->setFontWeight( size );
            else
              item->textCharFormat()->setFontWeight( QFont::Normal );
          }
        }
        // STRETCH
        else if( fontElement.tagName() == "stretch" )
        {
          QString stretch = fontElement.text();

          if( stretch == "ultracondensed" )
            item->textCharFormat()->font().setStretch( QFont::UltraCondensed );
          else if( stretch == "extracondensed" )
            item->textCharFormat()->font().setStretch( QFont::ExtraCondensed );
          else if( stretch == "condensed" )
            item->textCharFormat()->font().setStretch( QFont::Condensed );
          else if( stretch == "semicondensed" )
            item->textCharFormat()->font().setStretch( QFont::SemiCondensed );
          else if( stretch == "unstretched" )
            item->textCharFormat()->font().setStretch( QFont::Unstretched );
          else if( stretch == "semiexpanded" )
            item->textCharFormat()->font().setStretch( QFont::SemiExpanded );
          else if( stretch == "expanded" )
            item->textCharFormat()->font().setStretch( QFont::Expanded );
          else if( stretch == "extraexpanded" )
            item->textCharFormat()->font().setStretch( QFont::ExtraExpanded );
          else if( stretch == "ultraexpanded" )
            item->textCharFormat()->font().setStretch( QFont::UltraExpanded );
          else
          {
            std::cout << "Stretch value not correct: " << stretch.toStdString();
            item->textCharFormat()->font().setStretch( QFont::Unstretched );
          }
        }
        // ITALIC
        else if( fontElement.tagName() == "italic" )
        {
          //This only occur when italic tag is present.
          //delete italic tag to disable.
          item->textCharFormat()->setFontItalic( true );
        }
        // STRIKEOUT
        else if( fontElement.tagName() == "strikeout" )
        {
          //This only occur when strikeout tag is present.
          //delete strikeout tag to disable.
          item->textCharFormat()->setFontStrikeOut( true );
        }
        // UNDERLINE
        else if( fontElement.tagName() == "underline" )
        {
          //This only occur when underline tag is present.
          //delete underline tag to disable.
          item->textCharFormat()->setFontUnderline( true );
        }
        // OVERLINE
        else if( fontElement.tagName() == "overline" )
        {
          //This only occur when overline tag is present.
          //delete overline tag to disable.
          item->textCharFormat()->setFontOverline( true );
        }
        // COLOR
        else if( fontElement.tagName() == "color" )
        {
          bool okRed;
          bool okGreen;
          bool okBlue;

          int red = fontElement.attribute( "red", "0" ).toInt(&okRed);
          int green = fontElement.attribute( "green", "0" ).toInt(&okGreen);
          int blue = fontElement.attribute( "blue", "0" ).toInt(&okBlue);

          if( okRed && okGreen && okBlue )
            item->textCharFormat()->setForeground( QBrush( QColor(red, green, blue) ));
          else
            item->textCharFormat()->setForeground( QBrush( QColor(0, 0, 0) ));
        }
        else
        {
          std::cout << "font tag not specified: " <<
            fontElement.tagName().toStdString();
        }
      }

      fontNode = fontNode.nextSibling();
    }
  }

  /*
   * \author Anders Fernström
   * \date 2006-03-02
   *
   * \brief Parse the CHAPTERLEVEL tag
   */
  void Stylesheet::parseChapterLevelTag(QDomElement element,
    CellStyle *item) const
  {
    bool ok;

    // Level
    int level = element.text().toInt(&ok);
    if(ok)
      item->setChapterLevel( level );
  }
}
