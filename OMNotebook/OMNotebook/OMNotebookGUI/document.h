/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*!
 * \file document.h
 * \author Ingemar Axelsson and Anders Fernström
 *
 * \brief Describes a celldocument.
 */

#ifndef DOCUMENT_H
#define DOCUMENT_H

//STD Haders
#include <vector>
#include <memory>

//QT Headers
#include <QtCore/QObject>
#include <QColor>
#include <QFrame>
#include <QImage>
#include <QUrl>

//IAEX Headers
#include "cellcursor.h"

//Forward declaration
class CellStyle;


namespace IAEX
{
  //Forward declaration
  class CellApplication;
  class Cell;
  class Command;
  class DocumentView;
  class Factory;
  class Visitor;

  /*!
   *\interface Document
   *
   * \brief Describes all operations that is needed by a document.
   *
   * The Document interface describes all methods that must be
   * implemented by a concrete document class.
   */
  class Document : public QObject
  {
    Q_OBJECT

  public:
    virtual ~Document() = default;

    //Application
    virtual CellApplication *application() = 0;

    //State
    virtual bool hasChanged() const = 0;
    virtual bool isOpen() const = 0;
    virtual bool isSaved() const = 0;
    virtual bool isEmpty() const = 0;

    //File operations
    virtual void open( const QString filename, int readmode ) = 0;
    virtual void close() = 0;
    virtual QString getFilename() = 0;
    virtual void setFilename( QString filename ) = 0;
    virtual void setSaved( bool saved ) = 0;
    virtual void setChanged( bool changed ) = 0;
    virtual void hoverOverUrl( const QUrl &link ) = 0;

    //Cursor operations
    virtual CellCursor *getCursor() = 0;
    virtual void cursorStepUp() = 0;
    virtual void cursorStepDown() = 0;
    virtual void cursorMoveAfter(Cell *aCell, const bool open) = 0;
    virtual void cursorUngroupCell() = 0;
    virtual void cursorSplitCell() = 0;
    virtual void cursorAddCell() = 0;
    virtual void cursorDeleteCell() = 0;
    virtual void cursorCutCell() = 0;
    virtual void cursorCopyCell() = 0;
    virtual void cursorPasteCell() = 0;
    virtual void cursorChangeStyle(CellStyle style) = 0;

    //TextCursor operations
    virtual void textcursorCutText() = 0;
    virtual void textcursorCopyText() = 0;
    virtual void textcursorPasteText() = 0;
    //TextCursor operations
    virtual void textcursorChangeFontFamily( QString family ) = 0;
    virtual void textcursorChangeFontFace( int face ) = 0;
    virtual void textcursorChangeFontSize( int size ) = 0;
    virtual void textcursorChangeFontStretch( int stretch ) = 0;
    virtual void textcursorChangeFontColor( QColor color ) = 0;
    virtual void textcursorChangeTextAlignment( int alignment ) = 0;
    virtual void textcursorChangeVerticalAlignment( int alignment ) = 0;
    virtual void textcursorChangeMargin( int margin ) = 0;
    virtual void textcursorChangePadding( int padding ) = 0;
    virtual void textcursorChangeBorder( int border ) = 0;

    // Image operations
    virtual void textcursorInsertImage( QString filepath, QSize size ) = 0;
    virtual QString addImage( QImage image ) = 0;
    virtual QImage getImage( QString name ) = 0;

    // Link operations
    virtual void textcursorInsertLink( QString filepath, QTextCursor& cursor ) = 0;

    //Utility operations
    virtual Factory *cellFactory() = 0;
    virtual Cell* getMainCell() = 0;
    virtual std::vector<Cell *> getSelection() = 0;
    virtual void clearSelection() = 0;

    //command operations
    virtual void executeCommand(std::unique_ptr<Command> cmd) = 0;

    //Observer interface
    virtual void attach(DocumentView *d) = 0;
    virtual void detach(DocumentView *d) = 0;
    virtual void notify() = 0;
    virtual QFrame *getState() = 0;

    //Visitor Initializations
    virtual void runVisitor(Visitor &v) = 0;

    virtual void setAutoIndent2(bool) = 0;

  public slots:
    virtual void updateScrollArea() = 0;


signals:
    void copyAvailable(bool);
    void undoAvailable(bool);
    void redoAvailable(bool);

    void updatePos(int, int);
    void newState(QString);
    void setStatusMenu(QList<QAction*>);

  };
}
#endif
