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

// REMADE LARGE PART OF THIS CLASS 2005-11-30 /AF

/*!
* \file serializingvisitor.cpp
* \author Anders Fernström (and Ingemar Axelsson)
* \date 2005-11-30
*
* \brief Remake this class to work with the specified xml format that
* document are to be saved in. The old file have been renamed to
* 'serializingvisitor.cpp.old' /AF
*/


//STD Headers
#include <iostream>

// QT Headers
#include <QtCore/QBuffer>
#include <QtCore/QDataStream>
#include <QtXml/QDomDocument>
#include <QtXml/QDomElement>

//IAEX Headers
#include "serializingvisitor.h"
#include "cellgroup.h"
#include "textcell.h"
#include "latexcell.h"
#include "inputcell.h"
#include "cellcursor.h"
#include "celldocument.h"
#include "xmlnodename.h"
#include "graphcell.h"
#include <QDataStream>
#include <QGraphicsRectItem>

using namespace OMPlot;

namespace IAEX
{
  /*!
   * \class SerializingVisitor
   * \date 2005-11-30 (update)
   *
   * \brief Saves a celltree to an xml file, by converting cell
   * structure to XML.
   *
   * Traverses the cellstructure and creates a serialized
   * stream of the internal representation of the document.
   *
   * 2005-11-30 AF, This class was remade when another xml format
   * was used to save the cell structure.
   */

  /*!
   * \author Anders Fernström and Ingemar Axelsson
   * \date 2005-11-30 (update)
   *
   * \brief The class constructor
   */
  SerializingVisitor::SerializingVisitor( QDomDocument &domdoc, Document* doc)
    : domdoc_(domdoc),
    doc_(doc)
  {
    currentElement_ = domdoc_.createElement( XML_NOTEBOOK );
    domdoc_.appendChild( currentElement_ );
  }

  /*!
   * \author Ingemar Axelsson
   *
   * \brief The class deconstructor
   */
  SerializingVisitor::~SerializingVisitor()
  {}


  // CELL
  // ******************************************************************
  void SerializingVisitor::visitCellNodeBefore(Cell *)
  {}

  void SerializingVisitor::visitCellNodeAfter(Cell *)
  {}


  // GROUPCELL
  // ******************************************************************
  void SerializingVisitor::visitCellGroupNodeBefore(CellGroup *node)
  {
    parents_.push( currentElement_ );
    QDomElement groupcell = domdoc_.createElement( XML_GROUPCELL );
    currentElement_.appendChild( groupcell );

    if( node->isClosed() )
      groupcell.setAttribute( XML_CLOSED, XML_TRUE );
    else
      groupcell.setAttribute( XML_CLOSED, XML_FALSE );

    // set the new current element
    currentElement_ = groupcell;
  }

  void SerializingVisitor::visitCellGroupNodeAfter(CellGroup *)
  {
    currentElement_ = parents_.top();
    parents_.pop();
  }


  // TEXTCELL
  // ******************************************************************
  void SerializingVisitor::visitTextCellNodeBefore(TextCell *node)
  {
    QDomElement textcell = domdoc_.createElement( XML_TEXTCELL );

    // Make sure that the text is viewed correct
    node->viewExpression(false);

    // Add style setting to textcell element
    textcell.setAttribute( XML_STYLE, node->style()->name() );

    // Create an text element and append an text node to the element
    QDomElement textelement = domdoc_.createElement( XML_TEXT );
    QDomText textnode = domdoc_.createTextNode( node->textHtml() );
    textelement.appendChild( textnode );
    textcell.appendChild( textelement );

    // Creates ruleelemetns
    Cell::rules_t r = node->rules();
    Cell::rules_t::const_iterator r_iter = r.begin();
    for( ; r_iter != r.end(); ++r_iter )
    {
      QDomElement ruleelement = domdoc_.createElement( XML_RULE );
      ruleelement.setAttribute( XML_NAME, (*r_iter)->attribute() );

      QDomText rulenode = domdoc_.createTextNode( (*r_iter)->value() );
      ruleelement.appendChild( rulenode );

      textcell.appendChild( ruleelement );
    }

    // Check if any image have been include in the text and add them
    // to the the the textcell element
    QString xoyz = node->textHtml();
    saveImages( textcell, xoyz );

    // Add textcell element to current element
    currentElement_.appendChild( textcell );
  }

  void SerializingVisitor::visitTextCellNodeAfter(TextCell *)
  {}


  //INPUTCELL
  // ******************************************************************
  void SerializingVisitor::visitInputCellNodeBefore(InputCell *node)
  {
    QDomElement inputcell = domdoc_.createElement( XML_INPUTCELL );

    // Add style setting to inputcell element
    inputcell.setAttribute( XML_STYLE, node->style()->name() );

    // Add close setting to inputcell element
    if( node->isClosed() )
      inputcell.setAttribute( XML_CLOSED, XML_TRUE );
    else
      inputcell.setAttribute( XML_CLOSED, XML_FALSE );

    // Create an text element (for input) and append it to the element
    QDomElement inputelement = domdoc_.createElement( XML_INPUTPART );
    QDomText inputnode = domdoc_.createTextNode( node->text() );
    inputelement.appendChild( inputnode );
    inputcell.appendChild( inputelement );

    // Create an text element (for output) and append it to the element
    QDomElement outputelement = domdoc_.createElement( XML_OUTPUTPART );

    QDomText outputnode;
    outputnode = domdoc_.createTextNode( node->textOutput() );

    outputelement.appendChild( outputnode );
    inputcell.appendChild( outputelement );

    // Creates ruleelemetns
    Cell::rules_t r = node->rules();
    Cell::rules_t::const_iterator r_iter = r.begin();
    for( ; r_iter != r.end(); ++r_iter )
    {
      QDomElement ruleelement = domdoc_.createElement( XML_RULE );
      ruleelement.setAttribute( XML_NAME, (*r_iter)->attribute() );

      QDomText rulenode = domdoc_.createTextNode( (*r_iter)->value() );
      ruleelement.appendChild( rulenode );

      inputcell.appendChild( ruleelement );
    }

    // Check if any image have been include in the text and add them
    // to the the the inputcell element
    QString xoyz = node->textOutputHtml();
    saveImages( inputcell, xoyz );

    // Add inputcell element to current element
    currentElement_.appendChild( inputcell );
  }

  void SerializingVisitor::visitInputCellNodeAfter(InputCell *)
  {}

  //GRAPHCELL
  // ******************************************************************
  void SerializingVisitor::visitGraphCellNodeBefore(GraphCell *node)
  {
    QDomElement graphcell = domdoc_.createElement( XML_GRAPHCELL );

    // Add style setting to inputcell element
    graphcell.setAttribute( XML_STYLE, node->style()->name() );


    // Add close setting to inputcell element
    if( node->isClosed() )
      graphcell.setAttribute( XML_CLOSED, XML_TRUE );
    else
      graphcell.setAttribute( XML_CLOSED, XML_FALSE );

    if(node->mpPlotWindow && node->mpPlotWindow->isVisible())
    {
      // Create a OMCPLOT tag
      QDomElement omcPlotElement = domdoc_.createElement( XML_GRAPHCELL_OMCPLOT );
      // set all attributes
      omcPlotElement.setAttribute(XML_GRAPHCELL_TITLE, node->mpPlotWindow->getPlot()->title().text());
      omcPlotElement.setAttribute(XML_GRAPHCELL_GRID, node->mpPlotWindow->getGrid());
      omcPlotElement.setAttribute(XML_GRAPHCELL_PLOTTYPE, node->mpPlotWindow->getPlotType());
      omcPlotElement.setAttribute(XML_GRAPHCELL_LOGX, node->mpPlotWindow->getLogXCheckBox()->isChecked() ? "true" : "false");
      omcPlotElement.setAttribute(XML_GRAPHCELL_LOGY, node->mpPlotWindow->getLogXCheckBox()->isChecked() ? "true" : "false");
      omcPlotElement.setAttribute(XML_GRAPHCELL_XLABEL, node->mpPlotWindow->getPlot()->axisTitle(QwtPlot::xBottom).text());
      omcPlotElement.setAttribute(XML_GRAPHCELL_YLABEL, node->mpPlotWindow->getPlot()->axisTitle(QwtPlot::yLeft).text());
      omcPlotElement.setAttribute(XML_GRAPHCELL_XRANGE_MIN, node->mpPlotWindow->getXRangeMin());
      omcPlotElement.setAttribute(XML_GRAPHCELL_XRANGE_MAX, node->mpPlotWindow->getXRangeMax());
      omcPlotElement.setAttribute(XML_GRAPHCELL_YRANGE_MIN, node->mpPlotWindow->getYRangeMin());
      omcPlotElement.setAttribute(XML_GRAPHCELL_YRANGE_MAX, node->mpPlotWindow->getYRangeMax());
      omcPlotElement.setAttribute(XML_GRAPHCELL_CURVE_WIDTH, node->mpPlotWindow->getCurveWidth());
      omcPlotElement.setAttribute(XML_GRAPHCELL_CURVE_STYLE, node->mpPlotWindow->getCurveStyle());
      omcPlotElement.setAttribute(XML_GRAPHCELL_LEGENDPOSITION, node->mpPlotWindow->getLegendPosition());
      omcPlotElement.setAttribute(XML_GRAPHCELL_FOOTER, node->mpPlotWindow->getFooter());
      omcPlotElement.setAttribute(XML_GRAPHCELL_AUTOSCALE, node->mpPlotWindow->getAutoScaleButton()->isChecked() ? "true" : "false");

      foreach (PlotCurve *pPlotCurve, node->mpPlotWindow->getPlot()->getPlotCurvesList())
      {
        QDomElement omcPlotCurve = domdoc_.createElement( XML_GRAPHCELL_CURVE );
        // set the curve attributes
        omcPlotCurve.setAttribute(XML_GRAPHCELL_TITLE, pPlotCurve->title().text());
        omcPlotCurve.setAttribute(XML_GRAPHCELL_VISIBLE, pPlotCurve->isVisible() ? "true" : "false");
        omcPlotCurve.setAttribute(XML_GRAPHCELL_COLOR, pPlotCurve->pen().color().rgba());
        // set the curve data
        QByteArray xByteArray, yByteArray;
        QDataStream xOutStream(&xByteArray,QIODevice::WriteOnly);
        QVector<double> xAxisData = pPlotCurve->mXAxisVector;
        foreach (double d, xAxisData)
          xOutStream << d;
        QDataStream yOutStream(&yByteArray,QIODevice::WriteOnly);
        QVector<double> yAxisData = pPlotCurve->mYAxisVector;
        foreach (double d, yAxisData)
          yOutStream << d;
        omcPlotCurve.setAttribute(XML_GRAPHCELL_XDATA, QString(xByteArray.toBase64()));
        omcPlotCurve.setAttribute(XML_GRAPHCELL_YDATA, QString(yByteArray.toBase64()));
        omcPlotElement.appendChild(omcPlotCurve);
      }
      graphcell.appendChild(omcPlotElement);
    }
    // Create an text element (for input) and append it to the element
    QDomElement textelement = domdoc_.createElement( XML_INPUTPART );
    QDomText textnode = domdoc_.createTextNode( node->text() );
    textelement.appendChild( textnode );
    graphcell.appendChild( textelement );

    // Create an text element (for output) and append it to the element
    QDomElement outputelement = domdoc_.createElement( XML_OUTPUTPART );

    QDomText outputnode;
    outputnode = domdoc_.createTextNode( node->textOutput() );

    outputelement.appendChild( outputnode );
    graphcell.appendChild( outputelement );
/*
    // Create an text element (for output) and append it to the element
    QDomElement outputelement = domdoc_.createElement( XML_OUTPUTPART );

    QDomText outputnode;
    outputnode = domdoc_.createTextNode( node->textOutput() );

    outputelement.appendChild( outputnode );
    graphcell.appendChild( outputelement );
*/
    // Creates ruleelemetns
    Cell::rules_t r = node->rules();
    Cell::rules_t::const_iterator r_iter = r.begin();
    for( ; r_iter != r.end(); ++r_iter )
    {
      QDomElement ruleelement = domdoc_.createElement( XML_RULE );
      ruleelement.setAttribute( XML_NAME, (*r_iter)->attribute() );

      QDomText rulenode = domdoc_.createTextNode( (*r_iter)->value() );
      ruleelement.appendChild( rulenode );

      graphcell.appendChild( ruleelement );
    }

    // Check if any image have been include in the text and add them
    // to the the the inputcell element
    QString xoyz = node->textOutputHtml();
    saveImages( graphcell, xoyz );

    // Add inputcell element to current element
    currentElement_.appendChild( graphcell );
  }

  void SerializingVisitor::visitGraphCellNodeAfter(GraphCell *)
  {}

  //LATEXCELL

  void SerializingVisitor::visitLatexCellNodeBefore(LatexCell *node)
  {

    QDomElement latexcell = domdoc_.createElement( XML_LATEXCELL );

    // Add style setting to inputcell element
    latexcell.setAttribute( XML_STYLE, node->style()->name() );


    // Add close setting to inputcell element
    if( node->isClosed() )
      latexcell.setAttribute( XML_CLOSED, XML_TRUE );
    else
      latexcell.setAttribute( XML_CLOSED, XML_FALSE );

    // Create an text element (for input) and append it to the element
    QDomElement textelement = domdoc_.createElement( XML_INPUTPART );
    QDomText textnode = domdoc_.createTextNode( node->textHtml());
    textelement.appendChild( textnode );
    latexcell.appendChild( textelement );

    // Create an text element (for output) and append it to the element
    QDomElement outputelement = domdoc_.createElement( XML_OUTPUTPART );

    QDomText outputnode;
    outputnode = domdoc_.createTextNode( node->textOutput());

    outputelement.appendChild( outputnode );
    latexcell.appendChild( outputelement );

    // Creates ruleelemetns
    Cell::rules_t r = node->rules();
    Cell::rules_t::const_iterator r_iter = r.begin();
    for( ; r_iter != r.end(); ++r_iter )
    {
      QDomElement ruleelement = domdoc_.createElement( XML_RULE );
      ruleelement.setAttribute( XML_NAME, (*r_iter)->attribute() );

      QDomText rulenode = domdoc_.createTextNode( (*r_iter)->value() );
      ruleelement.appendChild( rulenode );

      latexcell.appendChild( ruleelement );
    }

    // Check if any image have been include in the text and add them
    // to the the the inputcell element
   // QString xoyz = node->textOutputHtml();
    QString xoyz = node->textHtml();
    saveImages( latexcell, xoyz );

    // Add inputcell element to current element
    currentElement_.appendChild( latexcell );
  }

  void SerializingVisitor::visitLatexCellNodeAfter(LatexCell *)
  {}


  //CELLCURSOR
  // ******************************************************************
  void SerializingVisitor::visitCellCursorNodeBefore(CellCursor *)
  {}

  void SerializingVisitor::visitCellCursorNodeAfter(CellCursor *)
  {}


  /*!
   * \author Anders Fernström
   * \date 2005-11-30
   * \date 2005-12-12 (update)
   *
   * \brief Look through a html text and find all the images included.
   * When a image is found the images is saved to the xml file and
   * included in the current element
   *
   * 2005-12-12 AF, Added support for pasting images from clipboard
   */
  void SerializingVisitor::saveImages( QDomElement &current, QString &text )
  {
    int pos(0);
    while( true )
    {
      int start = text.indexOf( "<img src=", pos, Qt::CaseInsensitive );
      if( 0 <= start )
      {
        // found an image
        start += 10; // pos of first letter in imagename
        int end = text.indexOf( "\"", start );

        // get the image name
        QString imagename = text.mid( start, end - start );
        CellDocument *doc = dynamic_cast<CellDocument*>(doc_);
        QImage *image = doc->getImage( imagename );

        // 2005-12-12 AF, Added support of pasting images from clipboard
        if( image->isNull() )
        {
          // found image that isn't part of the document,
          // probably images that have been pasted into the text or
          // from copied cell
          QString tmpImagename = imagename;
          tmpImagename.remove( "file:///" );
          image = new QImage( tmpImagename );
        }

        if( !image->isNull() )
        {
          // create element and save the image to file
          QDomElement imageelement = domdoc_.createElement( XML_IMAGE );
          imageelement.setAttribute( XML_NAME, imagename );

          QBuffer buffer;
          buffer.open( QBuffer::WriteOnly );
          QDataStream out( &buffer );
          out << *image;
          buffer.close();

          QDomText imagedata = domdoc_.createTextNode( buffer.buffer().toBase64() );
          imageelement.appendChild( imagedata );

          current.appendChild( imageelement );
        }

        pos = end + 1;
      }
      else
        break;
    }
  }
}
