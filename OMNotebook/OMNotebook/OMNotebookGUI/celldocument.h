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
* \file celldocument.h
* \author Ingemar Axelsson and Anders Fernström
*
* \brief Describes the mainwidget used in other applications.
*/

#ifndef CELLDOCUMENT_H
#define CELLDOCUMENT_H

#include <memory>

//QT Headers
#include <QtGlobal>
#include <QtWidgets>
#include <QDomDocument>
#include <QEvent>
#include <QLayout>
#include <QScrollArea>
#include <QUrl>


//IAEX Headers
#include "cellapplication.h"
#include "document.h"
#include "xmlparser.h"


namespace IAEX
{

  class CellDocument : public Document
  {
    Q_OBJECT

  public:
    typedef std::vector<DocumentView*> observers_t;

    CellDocument(CellApplication *a, const QString filename, int readmode = READMODE_NORMAL);
    virtual ~CellDocument();

    void setApplication(CellApplication *app){app_ = app;}
    CellApplication *application(){ return app_;}

    //Document implementations
    virtual void open( const QString filename, int readmode = READMODE_NORMAL );
    virtual void close();
    virtual QString getFilename();
    virtual void setFilename( QString filename );  //AF
    virtual void setSaved( bool saved );      //AF

    virtual void attach(DocumentView *d);
    virtual void detach(DocumentView *d);
    virtual void notify();

    // Cursor methods
    virtual void cursorStepUp();
    virtual void cursorStepDown();
    virtual void cursorAddCell();
    virtual void cursorUngroupCell();
    virtual void cursorSplitCell();
    virtual void cursorDeleteCell();
    virtual void cursorCutCell();
    virtual void cursorCopyCell();
    virtual void cursorPasteCell();
    virtual void cursorChangeStyle(CellStyle style);

    // TextCursor operations
    virtual void textcursorCutText();
    virtual void textcursorCopyText();
    virtual void textcursorPasteText();
    virtual void textcursorChangeFontFamily( QString family );
    virtual void textcursorChangeFontFace( int face );
    virtual void textcursorChangeFontSize( int size );
    virtual void textcursorChangeFontStretch( int stretch );
    virtual void textcursorChangeFontColor( QColor color );
    virtual void textcursorChangeTextAlignment( int alignment );
    virtual void textcursorChangeVerticalAlignment( int alignment );
    virtual void textcursorChangeMargin( int margin );
    virtual void textcursorChangePadding( int padding );
    virtual void textcursorChangeBorder( int border );

    // Image operations
    virtual void textcursorInsertImage( QString filepath, QSize size );
    virtual QString addImage( QImage image );
    virtual QImage getImage( QString name );

    // Link operations
    virtual void textcursorInsertLink( QString filepath, QTextCursor& cursor);

    //State operations
    virtual bool hasChanged() const;
    bool isOpen() const;
    bool isSaved() const;
    bool isEmpty() const;

    //Cursor operations
    CellCursor *getCursor();
    Factory *cellFactory();
    Cell* getMainCell();
    std::vector<Cell*> getSelection();

    //Command
    void executeCommand(std::unique_ptr<Command> cmd);

    //Traversals.
    void runVisitor(Visitor &v);

    virtual void setAutoIndent2(bool);

    //observer
    QFrame *getState();

  public slots:
    void toggleMainTreeView();
    void setEditable(bool editable);
    void cursorChangedPosition();
    void updateScrollArea();
    void setChanged( bool changed );
    void hoverOverUrl( const QUrl &link );
    void selectedACell(Cell *selected, Qt::KeyboardModifiers);
    void clearSelection();
    void mouseClickedOnCell(Cell *clickedCell);
    void mouseClickedOnCellOutput(Cell *clickedCell);
    void linkClicked(const QUrl *url);
//    void anchorClicked(const QUrl *url);
    virtual void cursorMoveAfter(Cell *aCell, bool open);
    void showHTML(bool b);


  signals:
    void setAutoIndent(bool);
    void widthChanged(int);
    void cursorChanged();
    void viewExpression(bool);
    void contentChanged();
    void hoverOverFile( QString );
    void forwardAction( int );

  protected:
    void setWorkspace(Cell *newWorkspace);
    bool eventFilter(QObject *o, QEvent *e);

  private:
    void addSelectedCell( Cell* cell );
    void removeSelectedCell( Cell* cell );


  private:
    bool changed_ = false;
    bool open_ = false;
    bool saved_ = false;

    CellApplication *app_;
    QString filename_;

    Cell *workspace_ = nullptr;        //This should alwas be a cellgroup.
    Cell *lastClickedCell_ = nullptr;
    std::unique_ptr<QFrame> mainFrame_;


    QScrollArea *scroll_ = nullptr;
    QGridLayout *mainLayout_ = nullptr;

    CellCursor *current_ = nullptr;
    std::unique_ptr<Factory> factory_;

    std::vector<Cell*> selectedCells_;

  public:
    observers_t observers_;
    bool autoIndent = false;
  private:
    QHash<QString, QImage> images_;
    int currentImageNo_ = 0;
  };

}

#endif
