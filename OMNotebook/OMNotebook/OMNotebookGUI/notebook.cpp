#define QT_NO_DEBUG_OUTPUT
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
 * \file notebook.h
 * \author Ingemar Axelsson and Anders Fernström
 * \date 2005-02-07
 */


//STD Headers
#include <exception>
#include <stdexcept>
#include <fstream>
#include <algorithm>
//QT Headers
#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#else
#include <QtCore/QTimer>
#include <QtGui/QAction>
#include <QtGui/QApplication>
#include <QtGui/QClipboard>
#include <QtGui/QColorDialog>
#include <QtGui/QFileDialog>
#include <QtGui/QFontDatabase>
#include <QtGui/QFontDialog>
#include <QtGui/QImageReader>
#include <QtGui/QKeyEvent>
#include <QtGui/QMenuBar>
#include <QtGui/QMessageBox>
#include <QtGui/QPrinter>
#include <QtGui/QPrintDialog>
#include <QtGui/QStatusBar>
#include <QtGui/QTextCursor>
#include <QtGui/QTextEdit>
#include <QtGui/QTextFrame>
#include <QtGui/QToolBar>
#include <QtGui/QLabel>
#include <QtGui/QMouseEvent>
#include <QDebug>
#include <QSettings>
#include <QToolButton>
#include <QObject>
#endif
#include <QDir>

//IAEX Headers
#include "command.h"
#include "cellcommands.h"
#include "celldocument.h"
#include "cursorcommands.h"
#include "imagesizedlg.h"
#include "notebook.h"
#include "notebookcommands.h"
#include "otherdlg.h"
#include "stylesheet.h"
#include "searchform.h"
#include "xmlparser.h"
#include "removehighlightervisitor.h"
#include "omcinteractiveenvironment.h"
using namespace std;

namespace IAEX
{
/*!
  * \class NotebookWindow
  * \author Ingemar Axelsson and Anders Fernström
  *
  * \brief This class describes a mainwindow using the CellDocument
  *
  * This is the main applicationwindow. It contains of a menu, a
  * toolbar, a statusbar and a workspace. The workspace will contain a
  * celldocument view.
  *
  *
  * \todo implement a timer that saves a document every 5 minutes
  * or so.
  *
  */


// 2006-03-01 AF, Open, Save, Image and Link dir
QString NotebookWindow::openDir_ = QString();
QString NotebookWindow::saveDir_ = QString();
QString NotebookWindow::imageDir_ = QString();
QString NotebookWindow::linkDir_ = QString();


/*!
  * \author Ingemar Axelsson and Anders Fernström
  * \date 2006-01-17 (update)
  *
  * \brief The class constructor
  *
  * 2006-01-16 AF, Added an icon to the window
  * Also made som other updates /AF
  */
NotebookWindow::NotebookWindow(Document *subject,
                               const QString filename, int isDrModelica, QWidget *parent)
  : DocumentView(parent),
    subject_(subject),
    filename_(filename),
    closing_(false),
    app_( subject->application() ), //AF
    findForm_( 0 )          //AF
{
  if(!isDrModelica && !filename_.isNull() ) {
    saveDir_ = openDir_ = QFileInfo( filename_ ).absolutePath();
  } else {
    QString documentsDir = QFileInfo( QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) ).absoluteFilePath();
    if (saveDir_.isNull()) {
      saveDir_ = documentsDir;
    }
    if (openDir_.isNull()) {
      openDir_ = documentsDir;
    }
  }

  //    subject_->attach(this);
  //    setMinimumSize( 150, 220 );    //AF

  toolBar = new QToolBar(tr("Show toolbar"), this);


  posIndicator = new QLabel("");
  posIndicator->setMinimumWidth(75);
  stateIndicator = new QLabel("");
  stateIndicator->setMinimumWidth(60);

  statusBar()->insertPermanentWidget(0,posIndicator);
  statusBar()->insertPermanentWidget(0,stateIndicator);
  createFileMenu();
  createEditMenu();
  createCellMenu();
  createFormatMenu();
  createInsertMenu();
  createWindowMenu();
  createAboutMenu();

  QWidget* spacer = new QWidget();
  spacer->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
  // toolBar is a pointer to an existing toolbar
  toolBar->addWidget(spacer);
  toolBar->addSeparator();
  toolBar->addAction(quitWindowAction);
  addToolBar(toolBar); //Add icons, update the edit menu etc.

  subject_->attach(this);
  setMinimumSize( 150, 220 );    //AF


  // 2006-01-16 AF, Added an icon to the window
  setWindowIcon( QIcon(":/Resources/OMNotebook_icon.svg"));

  statusBar()->showMessage(tr("Ready"));
  resize(800, 600);

  connect( subject_->getCursor(), SIGNAL( changedPosition() ),
           this, SLOT( updateMenus() ));
  connect( subject_, SIGNAL( contentChanged() ),
           this, SLOT( updateWindowTitle() ));
  connect( subject_, SIGNAL( hoverOverFile(QString) ),
           this, SLOT( setStatusMessage(QString) ));
  // 2006-04-27 AF
  connect( subject_, SIGNAL( forwardAction(int) ),
           this, SLOT( forwardedAction(int) ));

  connect( subject_, SIGNAL(updatePos(int, int)), this, SLOT(setPosition(int, int)));

  connect( subject_, SIGNAL(newState(QString)), this, SLOT(setState(QString)));

  connect( subject_, SIGNAL(setStatusMenu(QList<QAction*>)), this, SLOT(setStatusMenu(QList<QAction*>)));

  updateWindowTitle();//
  updateChapterCounters();
  update();

#if USE_OMSKETCH
  //Intializing sketch application
  window = new Tools(subject_,this);
  window->resize(1200,800);
  window->setWindowTitle("OMSketch");

  isShown=false;
#endif

  //int count=0;

  Cell *current = subject_->getMainCell()->child();
  cells.clear();
  /**find  and inserts all the present cells in document in a vector**/
  cells=SearchCells(current);

#if USE_OMSKETCH
  window->readXml(subject_->getFilename());
#endif
}

/*!
  * \author Ingemar Axelsson and Anders Fernström
  * \date 2006-08-24 (update)
  *
  * \brief The class destructor
  *
  * 2005-11-03/04/07 AF, added som things that should be deleted.
  * 2006-01-05 AF, added code so all inputcells are added to the
  * removelist in the highlighter
  * 2006-01-27 AF, remove this notebook window from the list of
  * notebook windows in the main application
  * 2006-08-24 AF, delete replace action
  */
NotebookWindow::~NotebookWindow()
{
  //2006-01-27 AF, remove document view from application lsit
  application()->removeDocumentView( this );

  //2006-01-05 AF, add all inputcell to removelist on highlighter
  RemoveHighlighterVisitor visitor;
  subject_->runVisitor( visitor );

  subject_->detach(this);
  delete subject_;
  //subject_ = 0;

  // 2005-11-03/04/07 AF, remova all created QAction
  map<QString, QAction*>::iterator s_iter = styles_.begin();
  while( s_iter != styles_.end() )
  {
    delete (*s_iter).second;
    ++s_iter;
  }

  QHash<QString, QAction*>::iterator f_iter = fonts_.begin();
  while( f_iter != fonts_.end() )
  {
    delete f_iter.value();
    ++f_iter;
  }

  QHash<QAction*, QColor*>::iterator c_iter = colors_.begin();
  while( c_iter != colors_.end() )
  {
    delete c_iter.value();
    ++c_iter;
  }

  QHash<QAction*, DocumentView*>::iterator w_iter = windows_.begin();
  while( w_iter != windows_.end() )
  {
    delete w_iter.key();
    ++w_iter;
  }

  delete stylesgroup;
  delete fontsgroup;
  delete sizesgroup;
  delete stretchsgroup;
  delete colorsgroup;
  delete alignmentsgroup;
  delete verticalAlignmentsgroup;
  delete bordersgroup;
  delete marginsgroup;
  delete paddingsgroup;


  delete newAction;
  delete openFileAction;
  delete saveAsAction;
  delete saveAction;
  delete printAction;
  delete pdfAction;
  delete closeFileAction;
  delete quitWindowAction;

  delete undoAction;
  delete redoAction;
  delete cutAction;
  delete copyAction;
  delete pasteAction;
  delete findAction;
  delete replaceAction;
  delete showExprAction;

  //delete cutCellAction;
  //delete copyCellAction;
  //delete pasteCellAction;
  delete addCellAction;
  delete ungroupCellAction;
  delete splitCellAction;
  delete deleteCellAction;
  delete nextCellAction;
  delete previousCellAction;
  delete evalCellAction;
  delete evalAllCellsAction;
  delete evalAllLatexCellsAction;

  delete groupAction;
  delete inputAction;
  delete latexAction;
  delete textAction;

  delete aboutAction;
  delete helpAction;
  delete aboutQtAction;

  delete facePlain;
  delete faceBold;
  delete faceItalic;
  delete faceUnderline;

  delete sizeSmaller;
  delete sizeLarger;
  delete size8pt;
  delete size9pt;
  delete size10pt;
  delete size12pt;
  delete size14pt;
  delete size16pt;
  delete size18pt;
  delete size20pt;
  delete size24pt;
  delete size36pt;
  delete size72pt;
  delete sizeOther;

  delete stretchUltraCondensed;
  delete stretchExtraCondensed;
  delete stretchCondensed;
  delete stretchSemiCondensed;
  delete stretchUnstretched;
  delete stretchSemiExpanded;
  delete stretchExpanded;
  delete stretchExtraExpanded;
  delete stretchUltraExpanded;

  delete colorBlack;
  delete colorWhite;
  delete color10Gray;
  delete color33Gray;
  delete color50Gray;
  delete color66Gray;
  delete color90Gray;
  delete colorRed;
  delete colorGreen;
  delete colorBlue;
  delete colorCyan;
  delete colorMagenta;
  delete colorYellow;
  delete colorOther;

  delete chooseFont;

  delete alignmentLeft;
  delete alignmentRight;
  delete alignmentCenter;
  delete alignmentJustify;
  delete verticalNormal;
  delete verticalSub;
  delete verticalSuper;

  delete borderOther;
  delete marginOther;
  delete paddingOther;

  delete insertImageAction;
  delete insertLinkAction;
  delete importOldFile;
  delete exportPureText;

  // 2006-08-24 AF, delete findForm if it exists
  if( findForm_ )
    delete findForm_;

  delete toolBar;
  delete posIndicator;
  delete stateIndicator;
}

/*!
  * \author Ingemar Axelsson
  */
void NotebookWindow::update()
{
  QFrame *mainWidget = subject_->getState();

  mainWidget->setParent(this);
  mainWidget->move( QPoint(0,0) );

  setCentralWidget(mainWidget);
  //    mainWidget->setMaximumHeight(250);
  mainWidget->show();
}

/*!
  * \author Anders Fernström
  * \date 2005-11-30
  *
  * \brief Return the notebook windons document
  */
Document* NotebookWindow::document()
{
  return subject_;
}

/*!
  * \author Ingemar Axelsson
  */
CellApplication *NotebookWindow::application()
{
  return subject_->application();
}

/*!
  * \author Anders Fernström
  * \date 2005-12-01 (update)
  *
  * \brief Method for creating file nemu.
  *
  * 2005-10-07 AF, Updated/Remade the function when porting to QT4.
  * 2005-11-21 AF, Added a export menu
  * 2005-12-01 AF, Added a import menu
  */
void NotebookWindow::createFileMenu()
{
  // NEW
  newAction = new QAction( tr("&New"), this );
  newAction->setShortcut( QKeySequence("Ctrl+N") );
  newAction->setStatusTip( tr("Create a new document") );
  connect(newAction, SIGNAL(triggered()), this, SLOT(newFile()));
  newAction->setIcon(QIcon(":/Resources/toolbarIcons/filenew.png"));

  toolBar->addAction(newAction);

  recentMenu = new QMenu(tr("Recent &Files"), this);

  // OPEN FILE
  openFileAction = new QAction( tr("&Open"), this );
  openFileAction->setShortcut( QKeySequence("Ctrl+O") );
  openFileAction->setStatusTip( tr("Open a file") );
  connect(openFileAction, SIGNAL(triggered()), this, SLOT(openFile()));
  openFileAction->setIcon(QIcon(":/Resources/toolbarIcons/fileopen.png"));

  QToolButton *b = new QToolButton(this);
  b->setDefaultAction(openFileAction);
  b->setMenu(recentMenu);
  b->setPopupMode(QToolButton::MenuButtonPopup);
  //    toolBar->addAction(openFileAction);
  toolBar->addWidget(b);

  // SAVE AS
  saveAsAction = new QAction( tr("Save &As..."), this );
  saveAsAction->setShortcut( QKeySequence("Ctrl+Shift+S") );
  saveAsAction->setStatusTip( tr("Save the document as a new file") );
  connect(saveAsAction, SIGNAL(triggered()), this, SLOT(saveas()));

  // SAVE
  saveAction = new QAction( tr("&Save"), this );
  saveAction->setShortcut( QKeySequence("Ctrl+S") );
  saveAction->setStatusTip( tr("Save the document") );
  connect(saveAction, SIGNAL(triggered()), this, SLOT(save()));
  saveAction->setIcon(QIcon(":/Resources/toolbarIcons/filesave.png"));
  toolBar->addAction(saveAction);

  toolBar->addSeparator();

  // CLOSE FILE
  closeFileAction = new QAction( tr("&Close"), this );
  closeFileAction->setShortcut( QKeySequence("Ctrl+W") );
  closeFileAction->setStatusTip( tr("Close the window") );
  connect(closeFileAction, SIGNAL(triggered()), this, SLOT(closeFile()));

  // PRINT
  printAction = new QAction( tr("&Print"), this );
  printAction->setShortcut( QKeySequence("Ctrl+P") );
  printAction->setStatusTip( tr("Print the document") );
  connect(printAction, SIGNAL(triggered()), this, SLOT(print()));
  printAction->setIcon(QIcon(":/Resources/toolbarIcons/fileprint.png"));
  toolBar->addAction(printAction);

  toolBar->addSeparator();



  // QUIT WINDOW
  quitWindowAction = new QAction( tr("&Quit"), this );
  quitWindowAction->setShortcut( QKeySequence("Ctrl+Q") );
  quitWindowAction->setStatusTip( tr("Quit OMNotebook") );
  quitWindowAction->setMenuRole(QAction::QuitRole);
  quitWindowAction->setIcon(QIcon(":/Resources/toolbarIcons/exit.png"));

  connect(quitWindowAction, SIGNAL(triggered()), this, SLOT(quitOMNotebook()));

  // CREATE MENU
  fileMenu = menuBar()->addMenu( tr("&File") );
  fileMenu->addAction( newAction );
  fileMenu->addAction( openFileAction );
  fileMenu->addAction( saveAction );
  fileMenu->addAction( saveAsAction );
  fileMenu->addAction( closeFileAction );
  fileMenu->addSeparator();
  fileMenu->addAction( printAction );
  fileMenu->addSeparator();

  // RECENT FILES
  //    recentMenu = fileMenu->addMenu("Recent &Files");
  fileMenu->addMenu(recentMenu);

  QSettings s(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omnotebook");
  QString recentFile;
  for(int i = 0; i < 8; ++i)
  {
    if((recentFile = s.value(QString("Recent")+QString(i), QString()).toString()) != QString())
    {
      QAction* tmpAction = recentMenu->addAction(recentFile);
      connect(tmpAction, SIGNAL(triggered()), this, SLOT(recentTriggered()));
    }
  }

  fileMenu->addSeparator();

  importMenu = fileMenu->addMenu( tr("&Import") );
  exportMenu = fileMenu->addMenu( tr("E&xport") );
  fileMenu->addSeparator();
  fileMenu->addAction( quitWindowAction );


  // IMPORT MENU
  // Added 2005-12-01
  importOldFile = new QAction( tr("&Old OMNotebook file"), this );
  importOldFile->setStatusTip( tr("Import an old OMNotebook file") );
  connect( importOldFile, SIGNAL( triggered() ),
           this, SLOT( openOldFile() ));

  importMenu->addAction( importOldFile );


  // EXPORT MENU
  // Added 2005-11-21
  exportPureText = new QAction( tr("&Pure text"), this );
  exportPureText->setStatusTip( tr("Export the document content to pure text") );
  connect( exportPureText, SIGNAL( triggered() ),
           this, SLOT( pureText() ));

  exportMenu->addAction( exportPureText );

  // PDF
  pdfAction = new QAction( tr("P&DF"), this );
  pdfAction->setShortcut( QKeySequence("Alt+P") );
  pdfAction->setStatusTip( tr("Export the document to PDF") );
  connect(pdfAction, SIGNAL(triggered()), this, SLOT(pdf()));
  exportMenu->addAction(pdfAction);
}

/*!
  * \author Anders Fernström
  * \date 2006-08-24 (update)
  *
  * \brief Method for creating edit nemu.
  *
  * 2005-10-07 AF, Remade the function when porting to QT4.
  * 2006-02-03 AF, Made undo, redo, cut, copy and paste actions for the editor
  * 2006-08-24 AF, added a replace action, renamed search action to find action
  */
void NotebookWindow::createEditMenu()
{
  undoAction = new QAction( tr("&Undo"), this);
  undoAction->setShortcut( QKeySequence("Ctrl+Z") );
  undoAction->setStatusTip( tr("Undo last action") );
  connect( undoAction, SIGNAL( triggered() ),
           this, SLOT( undoEdit() ));

  undoAction->setEnabled(false);
  undoAction->setIcon(QIcon(":/Resources/toolbarIcons/undo.png"));
  toolBar->addAction(undoAction);

  redoAction = new QAction( tr("&Redo"), this);
  redoAction->setShortcut( QKeySequence("Ctrl+Y") );
  redoAction->setStatusTip( tr("Redo last action") );
  connect( redoAction, SIGNAL( triggered() ),
           this, SLOT( redoEdit() ));

  redoAction->setEnabled(false);
  redoAction->setIcon(QIcon(":/Resources/toolbarIcons/redo.png"));
  toolBar->addAction(redoAction);

  toolBar->addSeparator();

  // CUT
  cutAction = new QAction( tr("Cu&t"), this);
  cutAction->setShortcut( QKeySequence("Ctrl+X") );
  cutAction->setStatusTip( tr("Cut selected text") );
  connect( cutAction, SIGNAL( triggered() ),
           this, SLOT( cutEdit() ));

  cutAction->setEnabled(false);
  cutAction->setIcon(QIcon(":/Resources/toolbarIcons/editcut.png"));
  toolBar->addAction(cutAction);

  // COPY
  copyAction = new QAction( tr("&Copy"), this);
  copyAction->setShortcut( QKeySequence("Ctrl+C") );
  copyAction->setStatusTip( tr("Copy selected text") );
  connect( copyAction, SIGNAL( triggered() ),
           this, SLOT( copyEdit() ));

  copyAction->setEnabled(false);
  copyAction->setIcon(QIcon(":/Resources/toolbarIcons/editcopy.png"));
  toolBar->addAction(copyAction);

  // PASTE
  pasteAction = new QAction( tr("&Paste"), this);
  pasteAction->setShortcut( QKeySequence("Ctrl+V") );
  pasteAction->setStatusTip( tr("Paste text from clipboard") );
  connect( pasteAction, SIGNAL( triggered() ),
           this, SLOT( pasteEdit() ));


  pasteAction->setIcon(QIcon(":/Resources/toolbarIcons/editpaste.png"));
  toolBar->addAction(pasteAction);

  toolBar->addSeparator();


  // FIND
  findAction = new QAction( tr("&Find"), this);
  findAction->setShortcut( QKeySequence("Ctrl+F") );
  findAction->setStatusTip( tr("Search through the document") );
  connect( findAction, SIGNAL( triggered() ),
           this, SLOT( findEdit() ));

  findAction->setIcon(QIcon(":/Resources/toolbarIcons/find.png"));
  toolBar->addAction(findAction);
  toolBar->addSeparator();

  // REPLACE, added 2006-08-24 AF
  replaceAction = new QAction( tr("Re&place"), this);
  replaceAction->setShortcut( QKeySequence("Ctrl+H") );
  replaceAction->setStatusTip( tr("Search through the document and replace") );
  connect( replaceAction, SIGNAL( triggered() ),
           this, SLOT( replaceEdit() ));


  showExprAction = new QAction( tr("&View Raw Text"), this);
  showExprAction->setStatusTip( tr("View the raw text in the cell") );
  showExprAction->setCheckable(true);
  showExprAction->setChecked(false);
  connect(showExprAction, SIGNAL(toggled(bool)), subject_, SLOT(showHTML(bool)));


#if USE_OMSKETCH
  //Edit Sketch image,and view the attributes added by jhansi
  editSketchImage = new QAction( tr("&EditSketchImage"), this );
  editSketchImage->setShortcut( QKeySequence("Ctrl+E") );
  editSketchImage->setStatusTip( tr("Sketch Image Edit") );
  connect( editSketchImage, SIGNAL( triggered() ),
           this, SLOT( sketchImageEdit() ));
  editSketchImage->setIcon(QIcon(":/Resources/toolbarIcons/editimage.png"));
  toolBar->addAction(editSketchImage);
  toolBar->addSeparator();
#endif

  editMenu = menuBar()->addMenu( tr("&Edit") );
  editMenu->addAction( undoAction );
  editMenu->addAction( redoAction );
  editMenu->addSeparator();
  editMenu->addAction( cutAction );
  editMenu->addAction( copyAction );
  editMenu->addAction( pasteAction );
  editMenu->addSeparator();
  editMenu->addAction( findAction );
  editMenu->addAction( replaceAction );
  editMenu->addSeparator();
  editMenu->addAction( showExprAction );
#if USE_OMSKETCH
  editMenu->addAction(editSketchImage);
#endif
}

/*!
  * \author Anders Fernström
  * \date 2006-04-27 (update)
  *
  * \brief Method for creating cell nemu.
  *
  * 2006-04-26 AF, Added UNGROUP and SPLIT CELL
  * 2006-04-27 AF, remove cut,copy,paste cell from menu
  */
void NotebookWindow::createCellMenu()
{
  addCellAction = new QAction( tr("&Add Cell (previous cell style)"), this);
  addCellAction->setShortcut( QKeySequence("Alt+Enter") );
  addCellAction->setStatusTip( tr("Add a new textcell with the previuos cells style") );
  connect(addCellAction, SIGNAL(triggered()), this, SLOT(createNewCell()));

  inputAction = new QAction( tr("Add &Input Cell"), this);
  inputAction->setShortcut( QKeySequence("Ctrl+Shift+I") );
  inputAction->setStatusTip( tr("Add an input cell") );
  connect(inputAction, SIGNAL(triggered()), this, SLOT(inputCellsAction()));

  latexAction = new QAction( tr("Add &LaTeX Cell"), this);
  latexAction->setShortcut( QKeySequence("Ctrl+Shift+E") );
  latexAction->setStatusTip( tr("Add Latex cell") );
  connect(latexAction, SIGNAL(triggered()), this, SLOT(latexCellsAction()));

  textAction = new QAction( tr("Add &Text Cell"), this);
  textAction->setShortcut( QKeySequence("Ctrl+Shift+T") );
  textAction->setStatusTip( tr("Add a text cell") );
  connect(textAction, SIGNAL(triggered()), this, SLOT(textCellsAction()));

  groupAction = new QAction( tr("&Group Cell"), this);
  groupAction->setShortcut( QKeySequence("Ctrl+Shift+G") );
  groupAction->setStatusTip( tr("Add a group cell") );
  connect(groupAction, SIGNAL(triggered()), this, SLOT(groupCellsAction()));

  ungroupCellAction = new QAction( tr("&Ungroup groupcell"), this);
  ungroupCellAction->setShortcut( QKeySequence("Ctrl+Shift+U") );
  ungroupCellAction->setStatusTip( tr("Ungroup the selected groupcell in the tree view") );
  connect(ungroupCellAction, SIGNAL(triggered()), this, SLOT(ungroupCell()));

  splitCellAction = new QAction( tr("&Split cell"), this);
  splitCellAction->setShortcut( QKeySequence("Ctrl+Shift+P") );
  splitCellAction->setStatusTip( tr("Split selected cell") );
  connect(splitCellAction, SIGNAL(triggered()), this, SLOT(splitCell()));

  deleteCellAction = new QAction( tr("&Delete Cell"), this);
  deleteCellAction->setShortcut( QKeySequence("Ctrl+Shift+D") );
  deleteCellAction->setStatusTip( tr("Delete selected cell") );
  connect(deleteCellAction, SIGNAL(triggered()), this, SLOT(deleteCurrentCellAsk()));

  nextCellAction = new QAction( tr("&Next Cell"), this);
  nextCellAction->setStatusTip( tr("Move to next cell") );
  nextCellAction->setShortcut( QKeySequence("Alt+Down") );
  connect(nextCellAction, SIGNAL(triggered()), this, SLOT(moveCursorDown()));

  previousCellAction = new QAction( tr("P&revious Cell"), this);
  previousCellAction->setShortcut( QKeySequence("Alt+Up") );
  previousCellAction->setStatusTip( tr("Move to previous cell") );
  connect(previousCellAction, SIGNAL(triggered()), this, SLOT(moveCursorUp()));

  evalCellAction = new QAction(tr("&Evaluate Cell"), this);
  evalCellAction->setShortcut( QKeySequence("Shift+Enter") );
  evalCellAction->setStatusTip(tr("Evaluate the selected cell"));
  connect(evalCellAction, SIGNAL(triggered()), this, SLOT(eval()));

  evalAllCellsAction = new QAction(tr("Evaluate all Input&cells"), this);
  evalAllCellsAction->setStatusTip(tr("Evaluate all Input cells in the document"));
  evalAllCellsAction->setShortcut( QKeySequence("Ctrl+R") );
  connect(evalAllCellsAction, SIGNAL(triggered()), this, SLOT(evalall()));

  evalAllLatexCellsAction = new QAction(tr("Evaluate all Late&xcells"), this);
  evalAllLatexCellsAction->setStatusTip(tr("Evaluate all Latex cells in the document"));
  evalAllLatexCellsAction->setShortcut( QKeySequence("Ctrl+Shift+R") );
  connect(evalAllLatexCellsAction, SIGNAL(triggered()), this, SLOT(evalallLatex()));

  // 2006-04-27 AF, remove cut,copy,paste cell from menu
  cellMenu = menuBar()->addMenu( tr("&Cell") );
  //cellMenu->addAction( cutCellAction );
  //cellMenu->addAction( copyCellAction );
  //cellMenu->addAction( pasteCellAction );
  //cellMenu->addSeparator();
  cellMenu->addAction( addCellAction );
  cellMenu->addAction( inputAction );
  cellMenu->addAction(latexAction);
  cellMenu->addAction( textAction );

  cellMenu->addAction( groupAction );
  cellMenu->addAction( ungroupCellAction );
  cellMenu->addAction( splitCellAction );
  cellMenu->addAction( deleteCellAction );
  cellMenu->addSeparator();
  cellMenu->addAction( nextCellAction );
  cellMenu->addAction( previousCellAction );
  cellMenu->addSeparator();
  cellMenu->addAction( evalCellAction );
  cellMenu->addAction( evalAllCellsAction );
  cellMenu->addAction( evalAllLatexCellsAction );

  QObject::connect(cellMenu, SIGNAL(aboutToShow()),
                   this, SLOT(updateCellMenu()));
}

/*!
  * \author Anders Fernström
  * \date 2005-10-07
  * \date 2005-11-03 (update)
  *
  * \brief Method for creating format nemu.
  *
  * 2005-11-03 AF, Updated this function with functionality for
  * changes text settings.
  */
void NotebookWindow::createFormatMenu()
{
  // 2005-10-03 AF, get the stylesheet instance
  Stylesheet *sheet = Stylesheet::instance("stylesheet.xml");

  // Create the style actions //AF
  stylesgroup = new QActionGroup( this );
  formatMenu = menuBar()->addMenu( tr("&Format") );
  styleMenu = formatMenu->addMenu( tr("&Styles") );

  vector<QString> styles = sheet->getAvailableStyleNames();
  vector<QString>::iterator i = styles.begin();
  for(;i != styles.end(); ++i)
  {
    if ((*i != "Latex") && (*i != "Graph") && (*i != "Input"))
    {
      QAction *tmp = new QAction( tr( (*i).toStdString().c_str() ), this );
      tmp->setCheckable( true );
      styleMenu->addAction( tmp );
      stylesgroup->addAction( tmp );
      styles_[(*i)] = tmp;
    }
  }

  connect( styleMenu, SIGNAL(triggered(QAction*)), this, SLOT(changeStyle(QAction*)));


  // FONT
  // -----------------------------------------------------
  // Code for creating the font menu
  formatMenu->addSeparator();
  fontsgroup = new QActionGroup( this );
  fontMenu = formatMenu->addMenu( tr("&Font") );

  QFontDatabase fontDatabase;
  QStringList fonts = fontDatabase.families( QFontDatabase::Latin );
  for( int index = 0; index < fonts.count(); ++index )
  {
    QAction *tmp = new QAction( fonts[index], this );
    tmp->setCheckable( true );
    fontMenu->addAction( tmp );
    fontsgroup->addAction( tmp );
    fonts_.insert( fonts[index], tmp );
  }

  connect( fontMenu, SIGNAL( triggered(QAction*) ),
           this, SLOT( changeFont(QAction*) ));
  connect( fontMenu, SIGNAL( aboutToShow() ),
           this, SLOT( updateFontMenu() ));

  // -----------------------------------------------------
  // END: FONT


  // FACE
  // -----------------------------------------------------
  // Code for creating the face menu
  faceMenu = formatMenu->addMenu( tr("Fa&ce") );

  facePlain = new QAction( tr("&Plain"), this);
  facePlain->setWhatsThis("Plain");
  facePlain->setCheckable( false );
  facePlain->setStatusTip( tr("Set font face to Plain") );

  faceBold = new QAction( tr("&Bold"), this);
  faceBold->setWhatsThis("Bold");
  faceBold->setShortcut( QKeySequence("Ctrl+B") );
  faceBold->setCheckable( true );
  faceBold->setStatusTip( tr("Set font face to Bold") );

  faceItalic = new QAction( tr("&Italic"), this);
  faceItalic->setWhatsThis("Italic");
  faceItalic->setShortcut( QKeySequence("Ctrl+I") );
  faceItalic->setCheckable( true );
  faceItalic->setStatusTip( tr("Set font face to Italic") );

  faceUnderline = new QAction( tr("&Underline"), this);
  faceUnderline->setWhatsThis("Underline");
  faceUnderline->setShortcut( QKeySequence("Ctrl+U") );
  faceUnderline->setCheckable( true );
  faceUnderline->setStatusTip( tr("Set font face to Underline") );


  connect( faceMenu, SIGNAL( aboutToShow() ),
           this, SLOT( updateFontFaceMenu() ));
  connect( faceMenu, SIGNAL( triggered(QAction*) ),
           this, SLOT( changeFontFace(QAction*) ));

  faceMenu->addAction( facePlain );
  faceMenu->addAction( faceBold );
  faceMenu->addAction( faceItalic );
  faceMenu->addAction( faceUnderline );

  // -----------------------------------------------------
  // END: FONT



  // SIZE
  // -----------------------------------------------------
  // Code for creating the size menu

  sizeMenu = formatMenu->addMenu( tr("Si&ze") );
  sizesgroup = new QActionGroup( this );

  sizeSmaller = new QAction( tr("&Smaller"), this);
  sizeSmaller->setWhatsThis("Smaller");
  sizeSmaller->setShortcut( QKeySequence("Ctrl+-") );
  sizeSmaller->setCheckable( false );
  sizeSmaller->setStatusTip( tr("Set font size smaller") );

  sizeLarger = new QAction( tr("&Larger"), this);
  sizeLarger->setWhatsThis("Larger");
  sizeLarger->setShortcut( QKeySequence("Ctrl++") );
  sizeLarger->setCheckable( false );
  sizeLarger->setStatusTip( tr("Set font size larger") );

  size8pt = new QAction( "8", this);
  size8pt->setCheckable( true );
  sizes_.insert( "8", size8pt );
  sizesgroup->addAction( size8pt );

  size9pt = new QAction( "9", this);
  size9pt->setCheckable( true );
  sizes_.insert( "9", size9pt );
  sizesgroup->addAction( size9pt );

  size10pt = new QAction( "10", this);
  size10pt->setCheckable( true );
  sizes_.insert( "10", size10pt );
  sizesgroup->addAction( size10pt );

  size12pt = new QAction( "12", this);
  size12pt->setCheckable( true );
  sizes_.insert( "12", size12pt );
  sizesgroup->addAction( size12pt );

  size14pt = new QAction( "14", this);
  size14pt->setCheckable( true );
  sizes_.insert( "14", size14pt );
  sizesgroup->addAction( size14pt );

  size16pt = new QAction( "16", this);
  size16pt->setCheckable( true );
  sizes_.insert( "16", size16pt );
  sizesgroup->addAction( size16pt );

  size18pt = new QAction( "18", this);
  size18pt->setCheckable( true );
  sizes_.insert( "18", size18pt );
  sizesgroup->addAction( size18pt );

  size20pt = new QAction( "20", this);
  size20pt->setCheckable( true );
  sizes_.insert( "20", size20pt );
  sizesgroup->addAction( size20pt );

  size24pt = new QAction( "24", this);
  size24pt->setCheckable( true );
  sizes_.insert( "24", size24pt );
  sizesgroup->addAction( size24pt );

  size36pt = new QAction( "36", this);
  size36pt->setCheckable( true );
  sizes_.insert( "36", size36pt );
  sizesgroup->addAction( size36pt );

  size72pt = new QAction( "72", this);
  size72pt->setCheckable( true );
  sizes_.insert( "72", size72pt );
  sizesgroup->addAction( size72pt );

  sizeOther = new QAction( tr("&Other..."), this);
  sizeOther->setWhatsThis("Other");
  sizeOther->setCheckable( true );
  sizeOther->setStatusTip( tr("Select font size") );


  connect( sizeMenu, SIGNAL( aboutToShow() ),
           this, SLOT( updateFontSizeMenu() ));
  connect( sizeMenu, SIGNAL( triggered(QAction*) ),
           this, SLOT( changeFontSize(QAction*) ));


  sizeMenu->addAction( sizeSmaller );
  sizeMenu->addAction( sizeLarger );
  sizeMenu->addSeparator();
  sizeMenu->addAction( size8pt );
  sizeMenu->addAction( size9pt );
  sizeMenu->addAction( size10pt );
  sizeMenu->addAction( size12pt );
  sizeMenu->addAction( size14pt );
  sizeMenu->addAction( size16pt );
  sizeMenu->addAction( size18pt );
  sizeMenu->addAction( size20pt );
  sizeMenu->addAction( size24pt );
  sizeMenu->addAction( size36pt );
  sizeMenu->addAction( size72pt );
  sizeMenu->addSeparator();
  sizeMenu->addAction( sizeOther );

  // -----------------------------------------------------
  // END: Size



  // STRETCH
  // -----------------------------------------------------
  // Code for creating the stretch menu

  stretchMenu = formatMenu->addMenu( tr("S&tretch") );
  stretchsgroup = new QActionGroup( this );

  stretchUltraCondensed = new QAction( tr("U&ltra Condensed"), this);
  stretchUltraCondensed->setCheckable( true );
  stretchUltraCondensed->setWhatsThis("ucon");
  stretchUltraCondensed->setStatusTip( tr("Set font stretch to Ultra Condensed") );
  stretchs_.insert( QFont::UltraCondensed, stretchUltraCondensed );
  stretchsgroup->addAction( stretchUltraCondensed );

  stretchExtraCondensed = new QAction( tr("E&xtra Condensed"), this);
  stretchExtraCondensed->setCheckable( true );
  stretchExtraCondensed->setWhatsThis("econ");
  stretchExtraCondensed->setStatusTip( tr("Set font stretch to Extra Condensed") );
  stretchs_.insert( QFont::ExtraCondensed, stretchExtraCondensed );
  stretchsgroup->addAction( stretchExtraCondensed );

  stretchCondensed = new QAction( tr("&Condensed"), this);
  stretchCondensed->setCheckable( true );
  stretchCondensed->setWhatsThis("con");
  stretchCondensed->setStatusTip( tr("Set font stretch to Condensed") );
  stretchs_.insert( QFont::Condensed, stretchCondensed );
  stretchsgroup->addAction( stretchCondensed );

  stretchSemiCondensed = new QAction( tr("S&emi Condensed"), this);
  stretchSemiCondensed->setCheckable( true );
  stretchSemiCondensed->setWhatsThis("scon");
  stretchSemiCondensed->setStatusTip( tr("Set font stretch to Semi Condensed") );
  stretchs_.insert( QFont::SemiCondensed, stretchSemiCondensed );
  stretchsgroup->addAction( stretchSemiCondensed );

  stretchUnstretched = new QAction( tr("&Unstretched"), this);
  stretchUnstretched->setCheckable( true );
  stretchUnstretched->setWhatsThis("uns");
  stretchUnstretched->setStatusTip( tr("Set font stretch to Unstretched") );
  stretchs_.insert( QFont::Unstretched, stretchUnstretched );
  stretchsgroup->addAction( stretchUnstretched );

  stretchSemiExpanded = new QAction( tr("&Semi Expanded"), this);
  stretchSemiExpanded->setCheckable( true );
  stretchSemiExpanded->setWhatsThis("sexp");
  stretchSemiExpanded->setStatusTip( tr("Set font stretch to Semi Expanded") );
  stretchs_.insert( QFont::SemiExpanded, stretchSemiExpanded );
  stretchsgroup->addAction( stretchSemiExpanded );

  stretchExpanded = new QAction( tr("&Expanded"), this);
  stretchExpanded->setCheckable( true );
  stretchExpanded->setWhatsThis("exp");
  stretchExpanded->setStatusTip( tr("Set font stretch to Expanded") );
  stretchs_.insert( QFont::Expanded, stretchExpanded );
  stretchsgroup->addAction( stretchExpanded );

  stretchExtraExpanded = new QAction( tr("Ex&tra Expanded"), this);
  stretchExtraExpanded->setCheckable( true );
  stretchExtraExpanded->setWhatsThis("eexp");
  stretchExtraExpanded->setStatusTip( tr("Set font stretch to Extra Expanded") );
  stretchs_.insert( QFont::ExtraExpanded, stretchExtraExpanded );
  stretchsgroup->addAction( stretchExtraExpanded );

  stretchUltraExpanded = new QAction( tr("Ult&ra Expanded"), this);
  stretchUltraExpanded->setCheckable( true );
  stretchUltraExpanded->setWhatsThis("uexp");
  stretchUltraExpanded->setStatusTip( tr("Set font stretch to Ultra Expanded") );
  stretchs_.insert( QFont::UltraExpanded, stretchUltraExpanded );
  stretchsgroup->addAction( stretchUltraExpanded );

  connect( stretchMenu, SIGNAL( aboutToShow() ),
           this, SLOT( updateFontStretchMenu() ));
  connect( stretchMenu, SIGNAL( triggered(QAction*) ),
           this, SLOT( changeFontStretch(QAction*) ));


  stretchMenu->addAction( stretchUltraCondensed );
  stretchMenu->addAction( stretchExtraCondensed );
  stretchMenu->addAction( stretchCondensed );
  stretchMenu->addAction( stretchSemiCondensed );
  stretchMenu->addSeparator();
  stretchMenu->addAction( stretchUnstretched );
  stretchMenu->addSeparator();
  stretchMenu->addAction( stretchSemiExpanded );
  stretchMenu->addAction( stretchExpanded );
  stretchMenu->addAction( stretchExtraExpanded );
  stretchMenu->addAction( stretchUltraExpanded );

  // -----------------------------------------------------
  // END: Stretch



  // COLOR
  // -----------------------------------------------------
  // Code for creating the color menu
  colorMenu = formatMenu->addMenu( tr("&Color") );
  colorsgroup = new QActionGroup( this );

  colorBlack = new QAction( tr("Blac&k"), this);
  colorBlack->setCheckable( true );
  colorBlack->setStatusTip( tr("Set font color to Black") );
  colors_.insert( colorBlack, new QColor(0,0,0) );
  colorsgroup->addAction( colorBlack );

  colorWhite = new QAction( tr("&White"), this);
  colorWhite->setCheckable( true );
  colorWhite->setStatusTip( tr("Set font color to White") );
  colors_.insert( colorWhite, new QColor(255,255,255) );
  colorsgroup->addAction( colorWhite );

  color10Gray = new QAction( tr("&10% Gray"), this);
  color10Gray->setCheckable( true );
  color10Gray->setStatusTip( tr("Set font color to 10% Gray") );
  colors_.insert( color10Gray, new QColor(25,25,25) );
  colorsgroup->addAction( color10Gray );

  color33Gray = new QAction( tr("&33% Gray"), this);
  color33Gray->setCheckable( true );
  color33Gray->setStatusTip( tr("Set font color to 33% Gray") );
  colors_.insert( color33Gray, new QColor(85,85,85) );
  colorsgroup->addAction( color33Gray );

  color50Gray = new QAction( tr("&50% Gray"), this);
  color50Gray->setCheckable( true );
  color50Gray->setStatusTip( tr("Set font color to 50% Gray") );
  colors_.insert( color50Gray, new QColor(128,128,128) );
  colorsgroup->addAction( color50Gray );

  color66Gray = new QAction( tr("&66% Gray"), this);
  color66Gray->setCheckable( true );
  color66Gray->setStatusTip( tr("Set font color to 66% Gray") );
  colors_.insert( color66Gray, new QColor(170,170,170) );
  colorsgroup->addAction( color66Gray );

  color90Gray = new QAction( tr("&90% Gray"), this);
  color90Gray->setCheckable( true );
  color90Gray->setStatusTip( tr("Set font color to 90% Gray") );
  colors_.insert( color90Gray, new QColor(230,230,230) );
  colorsgroup->addAction( color90Gray );

  colorRed = new QAction( tr("&Red"), this);
  colorRed->setCheckable( true );
  colorRed->setStatusTip( tr("Set font color to Red") );
  colors_.insert( colorRed, new QColor(255,0,0) );
  colorsgroup->addAction( colorRed );

  colorGreen = new QAction( tr("&Green"), this);
  colorGreen->setCheckable( true );
  colorGreen->setStatusTip( tr("Set font color to Green") );
  colors_.insert( colorGreen, new QColor(0,255,0) );
  colorsgroup->addAction( colorGreen );

  colorBlue = new QAction( tr("&Blue"), this);
  colorBlue->setCheckable( true );
  colorBlue->setStatusTip( tr("Set font color to Blue") );
  colors_.insert( colorBlue, new QColor(0,0,255) );
  colorsgroup->addAction( colorBlue );

  colorCyan = new QAction( tr("&Cyan"), this);
  colorCyan->setCheckable( true );
  colorCyan->setStatusTip( tr("Set font color to Cyan") );
  colors_.insert( colorCyan, new QColor(0,255,255) );
  colorsgroup->addAction( colorCyan );

  colorMagenta = new QAction( tr("&Magenta"), this);
  colorMagenta->setCheckable( true );
  colorMagenta->setStatusTip( tr("Set font color to Magenta") );
  colors_.insert( colorMagenta, new QColor(255,0,255) );
  colorsgroup->addAction( colorMagenta );

  colorYellow = new QAction( tr("&Yellow"), this);
  colorYellow->setCheckable( true );
  colorYellow->setStatusTip( tr("Set font color to Yellow") );
  colors_.insert( colorYellow, new QColor(255,255,0) );
  colorsgroup->addAction( colorYellow );

  colorOther = new QAction( tr("&Other..."), this);
  colorOther->setCheckable( true );
  colorOther->setStatusTip( tr("Select font color") );


  connect( colorMenu, SIGNAL( aboutToShow() ),
           this, SLOT( updateFontColorMenu() ));
  connect( colorMenu, SIGNAL( triggered(QAction*) ),
           this, SLOT( changeFontColor(QAction*) ));


  colorMenu->addAction( colorBlack );
  colorMenu->addAction( colorWhite );
  colorMenu->addAction( color10Gray );
  colorMenu->addAction( color33Gray );
  colorMenu->addAction( color50Gray );
  colorMenu->addAction( color66Gray );
  colorMenu->addAction( color90Gray );
  colorMenu->addAction( colorRed );
  colorMenu->addAction( colorGreen );
  colorMenu->addAction( colorBlue );
  colorMenu->addAction( colorCyan );
  colorMenu->addAction( colorMagenta );
  colorMenu->addAction( colorYellow );
  colorMenu->addSeparator();
  colorMenu->addAction( colorOther );

  // -----------------------------------------------------
  // END: Color


  // Extra menu for choosing font from a dialog, because all fonts
  // can't be displayed in the font menu
  chooseFont = new QAction( tr("C&hoose Font..."), this);
  chooseFont->setCheckable( false );
  chooseFont->setStatusTip( tr("Select font") );
  connect(chooseFont, SIGNAL(triggered()), this, SLOT(selectFont()));
  formatMenu->addAction( chooseFont );


  // ALIGNMENT
  // -----------------------------------------------------
  // Code for creating the alignment menus
  formatMenu->addSeparator();

  alignmentMenu = formatMenu->addMenu( tr("&Alignment") );
  alignmentsgroup = new QActionGroup( this );
  verticalAlignmentMenu = formatMenu->addMenu( tr("&Vertical Alignment") );
  verticalAlignmentsgroup = new QActionGroup( this );

  alignmentLeft = new QAction( tr("&Left"), this);
  alignmentLeft->setCheckable( true );
  alignmentLeft->setStatusTip( tr("Set text alignment to Left") );
  alignments_.insert( Qt::AlignLeft, alignmentLeft );
  alignmentsgroup->addAction( alignmentLeft );

  alignmentRight = new QAction( tr("&Right"), this);
  alignmentRight->setCheckable( true );
  alignmentRight->setStatusTip( tr("Set text alignment to Right") );
  alignments_.insert( Qt::AlignRight, alignmentRight );
  alignmentsgroup->addAction( alignmentRight );

  alignmentCenter = new QAction( tr("&Center"), this);
  alignmentCenter->setCheckable( true );
  alignmentCenter->setStatusTip( tr("Set text alignment to Center") );
  alignments_.insert( Qt::AlignHCenter, alignmentCenter );
  alignmentsgroup->addAction( alignmentCenter );

  alignmentJustify = new QAction( tr("&Justify"), this);
  alignmentJustify->setCheckable( true );
  alignmentJustify->setStatusTip( tr("Set text alignment to Justify") );
  alignments_.insert( Qt::AlignJustify, alignmentJustify );
  alignmentsgroup->addAction( alignmentJustify );

  verticalNormal = new QAction( tr("&Normal/Baseline"), this);
  verticalNormal->setCheckable( true );
  verticalNormal->setStatusTip( tr("Set vertical text alignment to Normal") );
  verticals_.insert( QTextCharFormat::AlignNormal, verticalNormal );
  verticalAlignmentsgroup->addAction( verticalNormal );

  verticalSub = new QAction( tr("&Subscript"), this);
  verticalSub->setCheckable( true );
  verticalSub->setStatusTip( tr("Set vertical text alignment to Subscript") );
  verticals_.insert( QTextCharFormat::AlignSubScript, verticalSub );
  verticalAlignmentsgroup->addAction( verticalSub );

  verticalSuper = new QAction( tr("S&uperscript"), this);
  verticalSuper->setCheckable( true );
  verticalSuper->setStatusTip( tr("Set vertical text alignment to Superscript") );
  verticals_.insert( QTextCharFormat::AlignSuperScript, verticalSuper );
  verticalAlignmentsgroup->addAction( verticalSuper );

  connect( alignmentMenu, SIGNAL( aboutToShow() ),
           this, SLOT( updateTextAlignmentMenu() ));
  connect( alignmentMenu, SIGNAL( triggered(QAction*) ),
           this, SLOT( changeTextAlignment(QAction*) ));
  connect( verticalAlignmentMenu, SIGNAL( aboutToShow() ),
           this, SLOT( updateVerticalAlignmentMenu() ));
  connect( verticalAlignmentMenu, SIGNAL( triggered(QAction*) ),
           this, SLOT( changeVerticalAlignment(QAction*) ));


  alignmentMenu->addAction( alignmentLeft );
  alignmentMenu->addAction( alignmentRight );
  alignmentMenu->addAction( alignmentCenter );
  alignmentMenu->addAction( alignmentJustify );
  verticalAlignmentMenu->addAction( verticalNormal );
  verticalAlignmentMenu->addAction( verticalSub );
  verticalAlignmentMenu->addAction( verticalSuper );

  // -----------------------------------------------------
  // END: Text Alignment


  // BORDER
  // -----------------------------------------------------
  // Code for creating the border menu
  formatMenu->addSeparator();
  borderMenu = formatMenu->addMenu( tr("&Border") );
  bordersgroup = new QActionGroup( this );

  int borderSizes[] = { 0,1,2,3,4,5,6,7,8,9,10 };
  for( int i = 0; i < sizeof(borderSizes)/sizeof(int); i++ )
  {
    QString name;
    name.setNum( borderSizes[i] );
    QAction *tmp = new QAction( name, this );
    tmp->setCheckable( true );
    borders_.insert( borderSizes[i], tmp );
    borderMenu->addAction( tmp );
    bordersgroup->addAction( tmp );
  }


  connect( borderMenu, SIGNAL( aboutToShow() ),
           this, SLOT( updateBorderMenu() ));
  connect( borderMenu, SIGNAL( triggered(QAction*) ),
           this, SLOT( changeBorder(QAction*) ));


  borderMenu->addSeparator();
  borderOther = new QAction( tr("&Other..."), this );
  borderOther->setWhatsThis("Other");
  borderOther->setCheckable( true );
  borderMenu->addAction( borderOther );

  // -----------------------------------------------------
  // END: Border


  // MARGIN
  // -----------------------------------------------------
  // Code for creating the margin menu
  marginMenu = formatMenu->addMenu( tr("&Margin") );
  marginsgroup = new QActionGroup( this );

  int marginSizes[] = { 0,1,2,3,4,5,6,7,8,9,10,15,20,25,30 };
  for( int i = 0; i < sizeof(marginSizes)/sizeof(int); i++ )
  {
    QString name;
    name.setNum( marginSizes[i] );
    QAction *tmp = new QAction( name, this );
    tmp->setCheckable( true );
    margins_.insert( marginSizes[i], tmp );
    marginMenu->addAction( tmp );
    marginsgroup->addAction( tmp );
  }


  connect( marginMenu, SIGNAL( aboutToShow() ),
           this, SLOT( updateMarginMenu() ));
  connect( marginMenu, SIGNAL( triggered(QAction*) ),
           this, SLOT( changeMargin(QAction*) ));


  marginMenu->addSeparator();
  marginOther = new QAction( tr("&Other..."), this );
  marginOther->setWhatsThis("Other");
  marginOther->setCheckable( true );
  marginMenu->addAction( marginOther );

  // -----------------------------------------------------
  // END: Margin


  // PADDING
  // -----------------------------------------------------
  // Code for creating the padding menu
  paddingMenu = formatMenu->addMenu( tr("&Padding") );
  paddingsgroup = new QActionGroup( this );

  int paddingSizes[] = { 0,2,4,6,8,10,15 };
  for( int i = 0; i < sizeof(paddingSizes)/sizeof(int); i++ )
  {
    QString name;
    name.setNum( paddingSizes[i] );
    QAction *tmp = new QAction( name, this );
    tmp->setCheckable( true );
    paddings_.insert( paddingSizes[i], tmp );
    paddingMenu->addAction( tmp );
    paddingsgroup->addAction( tmp );
  }


  connect( paddingMenu, SIGNAL( aboutToShow() ),
           this, SLOT( updatePaddingMenu() ));
  connect( paddingMenu, SIGNAL( triggered(QAction*) ),
           this, SLOT( changePadding(QAction*) ));


  paddingMenu->addSeparator();
  paddingOther = new QAction( tr("&Other..."), this );
  paddingOther->setWhatsThis("Other");
  paddingOther->setCheckable( true );
  paddingMenu->addAction( paddingOther );

  // -----------------------------------------------------
  // END: Padding


  connect(formatMenu, SIGNAL(aboutToShow()),
          this, SLOT(updateStyleMenu()));
  connect( formatMenu, SIGNAL( aboutToShow() ),
           this, SLOT( updateMenus() ));

  formatMenu->addSeparator();
  formatMenu->addAction(toolBar->toggleViewAction());
}

/*!
  * \author Anders Fernström
  * \date 2005-11-18
  *
  * \brief Method for creating insert nemu.
  */
void NotebookWindow::createInsertMenu()
{
  // IMAGE
  insertImageAction = new QAction( tr("&Image"), this );
  insertImageAction->setShortcut( QKeySequence("Ctrl+Shift+M") );
  insertImageAction->setStatusTip( tr("Insert a image into the cell") );
  connect( insertImageAction, SIGNAL( triggered() ),
           this, SLOT( insertImage() ));
  insertImageAction->setIcon(QIcon(":/Resources/toolbarIcons/image.png"));
  toolBar->addAction(insertImageAction);

  // LINK
  insertLinkAction = new QAction( tr("&Link"), this );
  insertLinkAction->setShortcut( QKeySequence("Ctrl+Shift+L") );
  insertLinkAction->setStatusTip( tr("Insert a link to the selected text") );
  connect( insertLinkAction, SIGNAL( triggered() ),
           this, SLOT( insertLink() ));
  insertLinkAction->setIcon(QIcon(":/Resources/toolbarIcons/text_under.png"));
  toolBar->addAction(insertLinkAction);

  toolBar->addSeparator();

#if USE_OMSKETCH
  //Sketch
  insertSketch = new QAction( tr("&Sketch"), this );
  insertSketch->setStatusTip( tr("Sketch App") );
  connect( insertSketch, SIGNAL( triggered() ),
           this, SLOT( Sketch() ));
  insertSketch->setIcon(QIcon(":/Resources/toolbarIcons/sketch.png"));
  toolBar->addAction(insertSketch);
  toolBar->addSeparator();
#endif

  //INDENT
  indentAction = new QAction(tr("Indent"), this);
  indentAction->setStatusTip(tr("Indent the code in the selected cell"));
  indentAction->setIcon(QIcon(":/Resources/toolbarIcons/text_right.png"));
  connect(indentAction, SIGNAL(triggered()), this, SLOT(indent()));


  QToolButton * b = new QToolButton;
  b->setDefaultAction(indentAction);
  indentMenu = new QMenu(this);
  autoIndentAction = new QAction("Autoindent", this);
  autoIndentAction->setStatusTip(tr("Tries to move the cursor to the right position when return is pressed"));
  autoIndentAction->setCheckable(true);
  //    autoIndentAction->setChecked(true);

  //b->hide(); //Disable indentation button

  QSettings s(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omnotebook");
  autoIndentAction->setChecked(s.value("AutoIndent", true).toBool());
  setAutoIndent(autoIndentAction->isChecked());

  connect(autoIndentAction, SIGNAL(toggled(bool)), this, SLOT(setAutoIndent(bool)));


  indentMenu->addAction(autoIndentAction);
  b->setMenu(indentMenu);
  b->setPopupMode(QToolButton::MenuButtonPopup);
  toolBar->addWidget(b);


  //EVAL
  evalAction = new QAction(tr("Evaluate"), this);
  evalAction->setStatusTip(tr("Evaluate the selected cell"));
  evalAction->setIcon(QIcon(":/Resources/toolbarIcons/apply.png"));
  connect(evalAction, SIGNAL(triggered()), this, SLOT(eval()));
  toolBar->addAction(evalAction);

  evalallAction = new QAction(tr("Evaluate all cells"), this);
  evalallAction->setStatusTip(tr("Evaluate all cells in the document"));
  evalallAction->setIcon(QIcon(":/Resources/toolbarIcons/evalall.png"));
//  evalallAction->setShortcut( QKeySequence("Ctrl+R") );
  connect(evalallAction, SIGNAL(triggered()), this, SLOT(evalall()));
  toolBar->addAction(evalallAction);

  shiftcellsupAction = new QAction(tr("Move cells up"), this);
  shiftcellsupAction->setStatusTip(tr("Move cells up, by clicking on the cell"));
  shiftcellsupAction->setIcon(QIcon(":/Resources/toolbarIcons/up.png"));
  connect(shiftcellsupAction, SIGNAL(triggered()), this, SLOT(shiftcellsUp()));
  toolBar->addAction(shiftcellsupAction);

  shiftcellsdownAction = new QAction(tr("Move cells down"), this);
  shiftcellsdownAction->setStatusTip(tr("Move cells down, by clicking on the cell"));
  shiftcellsdownAction->setIcon(QIcon(":/Resources/toolbarIcons/down.png"));
  connect(shiftcellsdownAction, SIGNAL(triggered()), this, SLOT(shiftcellsDown()));
  toolBar->addAction(shiftcellsdownAction);

  shiftselectedcellsAction = new QAction(tr("Move selected cells"), this);
  shiftselectedcellsAction->setStatusTip(tr("Put the cursor to a position where you want the cells to be moved, and then select the cells you would like to move that position"));
  shiftselectedcellsAction->setIcon(QIcon(":/Resources/toolbarIcons/updown.png"));
  connect(shiftselectedcellsAction, SIGNAL(triggered()), this, SLOT(shiftselectedcells()));
  toolBar->addAction(shiftselectedcellsAction);

  // MENU
  insertMenu = menuBar()->addMenu( tr("&Insert") );
  insertMenu->addAction( insertImageAction );
  insertMenu->addAction( insertLinkAction );

  connect( insertMenu, SIGNAL( aboutToShow() ),
           this, SLOT( updateMenus() ));
}

/*!
  * \author Anders Fernström
  * \date 2006-01-27
  *
  * \brief Method for creating window nemu.
  */
void NotebookWindow::createWindowMenu()
{
  windowMenu = menuBar()->addMenu( tr("&Window") );

  connect( windowMenu, SIGNAL( triggered(QAction *) ),
           this, SLOT( changeWindow(QAction *) ));
  connect( windowMenu, SIGNAL( aboutToShow() ),
           this, SLOT( updateWindowMenu() ));
}

/*!
  * \author Anders Fernström
  * \date 2006-02-03 (update)
  *
  * \brief Method for creating about nemu.
  *
  * 2006-02-03 AF, added help action.
  */
void NotebookWindow::createAboutMenu()
{
  aboutAction = new QAction( tr("&About OMNotebook"), this );
  aboutAction->setStatusTip( tr("Display OMNotebook's About dialog") );
  aboutAction->setMenuRole(QAction::AboutRole);
  connect(aboutAction, SIGNAL(triggered()), this, SLOT(aboutQTNotebook()));

  // 2006-02-03 AF, Added a help action
  helpAction = new QAction( tr("&Help Text"), this );
  helpAction->setShortcut( QKeySequence("F1") );
  helpAction->setStatusTip( tr("Open help document") );
  connect( helpAction, SIGNAL( triggered() ),
           this, SLOT( helpText() ));

  // 2006-02-21 AF, Added a about qt action
  aboutQtAction = new QAction( tr("About &Qt"), this );
  aboutQtAction->setStatusTip( tr("Display information about Qt") );
  aboutQtAction->setMenuRole(QAction::AboutQtRole);
  connect( aboutQtAction, SIGNAL( triggered() ),
           this, SLOT( aboutQT() ));

  // 2005-10-07 AF, Porting, new code for creating menu
  aboutMenu = menuBar()->addMenu( tr("&Help") );
  aboutMenu->addAction( aboutAction );
  aboutMenu->addAction( aboutQtAction );
  aboutMenu->addSeparator();
  aboutMenu->addAction( helpAction );
}

/*!
  * \author Anders Fernström
  * \date 2005-11-11
  *
  * \brief Check if the currentCell is editable
  */
bool NotebookWindow::cellEditable()
{
  return subject_->getCursor()->currentCell()->isEditable();
}

/*!
  * \author Anders Fernström
  * \date 2006-02-14
  *
  * \brief eval all selected cell
  */
void NotebookWindow::evalCells()
{
  application()->commandCenter()->executeCommand(
        new EvalSelectedCells( subject_ ));
}

/*!
  * \author Ingemar Axelsson
  */
/*
 void NotebookWindow::createSavingTimer()
 {
  //start a saving timer.
  savingTimer_ = new QTimer();
  savingTimer_->start(30000);

  connect(savingTimer_, SIGNAL(timeout()),
   this, SLOT(save()));
 }
  */




/*!
  * \author Anders Fernström
  * \date 2005-11-07
  * \date 2005-11-15 (update)
  *
  * \brief Method for enabling/disabling the menus depended on what have
  * been selected in the mainwindow
  *
  * 2005-11-15 AF, implemented the function
  */
void NotebookWindow::updateMenus()
{
  bool editable = false;

  if( cellEditable() ||
      (subject_->getCursor()->currentCell()->hasChilds() &&
       subject_->getCursor()->currentCell()->isClosed() &&
       subject_->getCursor()->currentCell()->child()->isEditable()) )
  {
    editable = true;
  }

  styleMenu->setEnabled( editable );
  fontMenu->setEnabled( editable );
  faceMenu->setEnabled( editable );
  sizeMenu->setEnabled( editable );
  stretchMenu->setEnabled( editable );
  colorMenu->setEnabled( editable );
  alignmentMenu->setEnabled( editable );
  verticalAlignmentMenu->setEnabled( editable );
  borderMenu->setEnabled( editable );
  marginMenu->setEnabled( editable );
  paddingMenu->setEnabled( editable );

  chooseFont->setEnabled( editable );
  insertImageAction->setEnabled( editable );
  insertLinkAction->setEnabled( editable );
  //    editSketchAttributes->setEnabled( editable );
}

/*!
  * \author Ingemar Axelsson and Anders Fernström
  * \date 2005-11-02 (update)
  *
  * \brief Method for updating the style menu
  *
  * 2005-10-28 AF, changed style from QString to CellStyle.
  * 2005-11-02 AF, changed from '->toggle()' to '->setChevked(true)'
  */
void NotebookWindow::updateStyleMenu()
{
  CellStyle style = *subject_->getCursor()->currentCell()->style();
  map<QString, QAction*>::iterator cs = styles_.find(style.name());

  if(cs != styles_.end())
  {
    (*cs).second->setChecked( true );
  }
  else
  {
    qDebug("No styles found");
    cs = styles_.begin();
    for(;cs != styles_.end(); ++cs)
    {
      (*cs).second->setChecked(false);
    }
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-02
  * \date 2006-04-27 (update)
  *
  * \brief Method for updating the edit menu
  *
  * 2006-02-03 AF, check if undo/redo is available.
  * 2006-04-27 AF, check if copied cells exsists.
  */
void NotebookWindow::updateEditMenu()
{
  QTextEdit *editor = subject_->getCursor()->currentCell()->textEdit();
  if( editor )
  {
    // undo
    if( editor->document()->isUndoAvailable() )
      undoAction->setEnabled( true );
    else
      undoAction->setEnabled( false );

    // redo
    if( editor->document()->isRedoAvailable() )
      redoAction->setEnabled( true );
    else
      redoAction->setEnabled( false );

    // cut & copy (special case for input)
    Cell *cell = document()->getCursor()->currentCell();
    if( cell )
    {
      QTextCursor in_cursor;

      if( typeid(InputCell) == typeid(*cell) )
      {
        InputCell *inputcell = dynamic_cast<InputCell*>(cell);
        if( inputcell->textEditOutput()->hasFocus() &&
            inputcell->isEvaluated() )
        {
          in_cursor = inputcell->textEditOutput()->textCursor();
        }
        else
        {
          in_cursor = inputcell->textEdit()->textCursor();
        }
      }
      else if( typeid(GraphCell) == typeid(*cell) ) //fjass
      {
        GraphCell *graphcell = dynamic_cast<GraphCell*>(cell);
        if( graphcell->textEditOutput()->hasFocus() &&
            graphcell->isEvaluated() )
        {
          in_cursor = graphcell->textEditOutput()->textCursor();
        }
        else
        {
          in_cursor = graphcell->textEdit()->textCursor();
        }
      }
      else
      {
        in_cursor = editor->textCursor();
      }

      if( in_cursor.hasSelection() ||
          subject_->getSelection().size() > 0 )
      {
        cutAction->setEnabled( true );
        copyAction->setEnabled( true );
      }
      else
      {
        cutAction->setEnabled( false );
        copyAction->setEnabled( false );
      }
    }
    else
    {
      cutAction->setEnabled( false );
      copyAction->setEnabled( false );
    }

    // paste
    if( !qApp->clipboard()->text().isEmpty() ||
        application()->pasteboard().size() > 0 )
      pasteAction->setEnabled( true );
    else
      pasteAction->setEnabled( false );
  }
  else
  {
    undoAction->setEnabled( false );
    redoAction->setEnabled( false );
    cutAction->setEnabled( false );
    copyAction->setEnabled( false );
    pasteAction->setEnabled( false );
  }

  showExprAction->setChecked( subject_->getCursor()->currentCell()->isViewExpression() );
}

/*!
  * \author Anders Fernström
  * \date 2006-02-03
  * \date 2006-04-26 (update)
  *
  * \brief Method for updating the cell menu
  *
  * 2006-04-26 AF, update UNGROUP, SLIT CELL
  */
void NotebookWindow::updateCellMenu()
{
  Cell *cell = subject_->getCursor()->currentCell();

  // GROUPCELL & DELETE
  if( cell )
  {
    if( cell->treeView()->isHidden() )
    {
      groupAction->setEnabled( false );
      deleteCellAction->setEnabled( false );
    }
    else
    {
      groupAction->setEnabled( true );
      deleteCellAction->setEnabled( true );
    }
  }
  else
  {
    groupAction->setEnabled( false );
    deleteCellAction->setEnabled( false );
  }

  // UNGROUP
  if( subject_->getSelection().size() > 0 )
    ungroupCellAction->setEnabled( true );
  else
    ungroupCellAction->setEnabled( false );

  // SLIT CELL
  if( cell )
  {
    if( typeid( *cell ) == typeid( TextCell ) ||
        typeid( *cell ) == typeid( InputCell ) )
    {
      splitCellAction->setEnabled( true );
    }
    else
      splitCellAction->setEnabled( false );
  }
  else
    splitCellAction->setEnabled( false );
}

/*!
  * \author Anders Fernström
  * \date 2005-11-03
  *
  * \brief Method for updating the font menu
  */
void NotebookWindow::updateFontMenu()
{
  QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
  if( !cursor.isNull() )
  {
    QString family = cursor.charFormat().fontFamily();
    if( fonts_.contains( family ))
    {
      fonts_[family]->setChecked( true );
    }
    else
    {
      qDebug("No font found");
      QHash<QString, QAction*>::iterator f_iter = fonts_.begin();
      while( f_iter != fonts_.end() )
      {
        f_iter.value()->setChecked( false );
        ++f_iter;
      }
    }
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-03
  *
  * \brief Method for updating the face menu
  */
void NotebookWindow::updateFontFaceMenu()
{
  QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
  if( !cursor.isNull() )
  {
    if( cursor.charFormat().fontWeight() > QFont::Normal )
      faceBold->setChecked( true );
    else
      faceBold->setChecked( false );

    if( cursor.charFormat().fontItalic() )
      faceItalic->setChecked( true );
    else
      faceItalic->setChecked( false );

    if( cursor.charFormat().fontUnderline() )
      faceUnderline->setChecked( true );
    else
      faceUnderline->setChecked( false );
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-04
  *
  * \brief Method for updating the size menu
  */
void NotebookWindow::updateFontSizeMenu()
{
  QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
  if( !cursor.isNull() )
  {
    int size = cursor.charFormat().font().pointSize();
    if( size > 0 )
    {
      QString txt;
      txt.setNum( size );

      if( sizes_.contains( txt ))
      {
        sizes_[txt]->setChecked( true );
        sizeOther->setChecked( false );
      }
      else
      {
        qDebug("No size found");
        sizeOther->setChecked( true );

        QHash<QString, QAction*>::iterator s_iter = sizes_.begin();
        while( s_iter != sizes_.end() )
        {
          s_iter.value()->setChecked( false );
          ++s_iter;
        }
      }
    }
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-04
  *
  * \brief Method for updating the stretch menu
  */
void NotebookWindow::updateFontStretchMenu()
{
  QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
  if( !cursor.isNull() )
  {
    int stretch = cursor.charFormat().font().stretch();
    if( stretchs_.contains( stretch ))
      stretchs_[stretch]->setChecked( true );
    else
    {
      qDebug("No stretch found");
      QHash<int, QAction*>::iterator s_iter = stretchs_.begin();
      while( s_iter != stretchs_.end() )
      {
        s_iter.value()->setChecked( false );
        ++s_iter;
      }
    }
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-07
  *
  * \brief Method for updating the color menu
  */
void NotebookWindow::updateFontColorMenu()
{
  QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
  if( !cursor.isNull() )
  {
    QColor color = cursor.charFormat().foreground().color();

    QHash<QAction*, QColor*>::iterator c_iter = colors_.begin();
    while( c_iter != colors_.end() )
    {
      if( (*c_iter.value()) == color )
      {
        c_iter.key()->setChecked( true );
        colorOther->setChecked( false );
        break;
      }
      else
        c_iter.key()->setChecked( false );

      ++c_iter;
    }

    if( c_iter == colors_.end() )
      colorOther->setChecked( true );
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-07
  *
  * \brief Method for updating the alignment menu
  */
void NotebookWindow::updateTextAlignmentMenu()
{
  QTextEdit *editor = subject_->getCursor()->currentCell()->textEdit();

  if( editor )
  {
    int alignment = editor->alignment();
    if( alignments_.contains( alignment ))
      alignments_[alignment]->setChecked( true );
    else
    {
      qDebug("No alignment found");
      QHash<int, QAction*>::iterator a_iter = alignments_.begin();
      while( a_iter != alignments_.end() )
      {
        a_iter.value()->setChecked( false );
        ++a_iter;
      }
    }
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-07
  *
  * \brief Method for updating the vertical alignment menu
  */
void NotebookWindow::updateVerticalAlignmentMenu()
{
  QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
  if( !cursor.isNull() )
  {
    int alignment = cursor.charFormat().verticalAlignment();
    if( verticals_.contains( alignment ))
      verticals_[alignment]->setChecked( true );
    else
    {
      qDebug("No vertical alignment found");
      QHash<int, QAction*>::iterator v_iter = verticals_.begin();
      while( v_iter != verticals_.end() )
      {
        v_iter.value()->setChecked( false );
        ++v_iter;
      }
    }
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-07
  *
  * \brief Method for updating the border menu
  */
void NotebookWindow::updateBorderMenu()
{
  QTextEdit *editor = subject_->getCursor()->currentCell()->textEdit();

  if( editor )
  {
    int border = editor->document()->rootFrame()->frameFormat().border();
    if( borders_.contains( border ))
    {
      borders_[border]->setChecked( true );
      borderOther->setChecked( false );
    }
    else
    {
      qDebug("No border found");
      borderOther->setChecked( true );

      QHash<int, QAction*>::iterator b_iter = borders_.begin();
      while( b_iter != borders_.end() )
      {
        b_iter.value()->setChecked( false );
        ++b_iter;
      }
    }
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-07
  *
  * \brief Method for updating the margin menu
  */
void NotebookWindow::updateMarginMenu()
{
  QTextEdit *editor = subject_->getCursor()->currentCell()->textEdit();

  if( editor )
  {
    int margin = editor->document()->rootFrame()->frameFormat().margin();
    if( margins_.contains( margin ))
    {
      margins_[margin]->setChecked( true );
      marginOther->setChecked( false );
    }
    else
    {
      qDebug("No margin found");
      marginOther->setChecked( true );

      QHash<int, QAction*>::iterator m_iter = margins_.begin();
      while( m_iter != margins_.end() )
      {
        m_iter.value()->setChecked( false );
        ++m_iter;
      }
    }
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-07
  *
  * \brief Method for updating the padding menu
  */
void NotebookWindow::updatePaddingMenu()
{
  QTextEdit *editor = subject_->getCursor()->currentCell()->textEdit();

  if( editor )
  {
    int padding = editor->document()->rootFrame()->frameFormat().padding();
    if( paddings_.contains( padding ))
    {
      paddings_[padding]->setChecked( true );
      paddingOther->setChecked( false );
    }
    else
    {
      qDebug("No padding found");
      paddingOther->setChecked( true );

      QHash<int, QAction*>::iterator p_iter = paddings_.begin();
      while( p_iter != paddings_.end() )
      {
        p_iter.value()->setChecked( false );
        ++p_iter;
      }
    }
  }
}

/*!
  * \author Anders Fernström
  * \date 2006-01-27
  *
  * \brief Method for updating the window menu
  */
void NotebookWindow::updateWindowMenu()
{
  // remove old windows
  windows_.clear();
  windowMenu->clear();

  // add new menu items
  vector<DocumentView *> windowViews = application()->documentViewList();
  vector<DocumentView *>::iterator v_iter = windowViews.begin();
  int k = 1;
  while( v_iter != windowViews.end() )
  {
    QString title = (*v_iter)->windowTitle();
    title.remove( "OMNotebook: " );

    QAction *action = new QAction( title, windowMenu );
    if (k < 10 ) {
      action->setShortcut( QKeySequence::fromString("Ctrl+"+QString::number(k)) );
      k++;
    }
    windows_[action] = (*v_iter);
    windowMenu->addAction( action );
    ++v_iter;
  }
}

/*!
  * \author Anders Fernström
  * \date 2006-01-17
  *
  * \brief Method for updateing the window title
  */
void NotebookWindow::updateWindowTitle()
{
  // QT functionality to strip the filepath and only keep
  // the filename.
  QString title = QFileInfo( subject_->getFilename() ).fileName();
  title.remove( "\n" );

  // if no name, set name to '(untitled)'
  if( title.isEmpty() )
    title = "(untitled)";

  title = QString( "OMNotebook: " ) + title;

  if( subject_->hasChanged() )
    title.append( "*" );

  setWindowTitle( title );
}

/*!
  * \author Anders Fernström
  * \date 2006-03-02
  *
  * \brief Method for updateing the chapter counters
  */
void NotebookWindow::updateChapterCounters()
{
  application()->commandCenter()->executeCommand(
        new UpdateChapterCounters( subject_ ));
}

/*!
  * \author Anders Fernström
  * \date 2006-02-10
  *
  * \brief Set the status message to msg, if msg is empty the default
  * status message 'Ready' is set.
  *
  * \param msg A QString containing the status message
  */
void NotebookWindow::setStatusMessage( QString msg )
{
  if( msg.isEmpty() )
    statusBar()->showMessage(tr("Ready"));
  else
    statusBar()->showMessage( msg );
}

void NotebookWindow::setPosition(int r, int c)
{
  posIndicator->setText(tr("Ln %1, Col %2").arg(r).arg(c));
}

void NotebookWindow::setState(QString s)
{
  stateIndicator->setText(s);
}

void NotebookWindow::setStatusMenu(QList<QAction*> l)
{
  QList<QAction*> a = stateIndicator->actions();
  qDeleteAll(a.begin(), a.end());

  if(!l.size())
    stateIndicator->setContextMenuPolicy(Qt::NoContextMenu);
  else
  {
    stateIndicator->setContextMenuPolicy(Qt::ActionsContextMenu);
    stateIndicator->addActions(l);
  }
}

/*!
  * \author Anders Fernström
  * \date 2006-04-27
  *
  * \brief handles forwarded actions
  */
void NotebookWindow::forwardedAction( int action )
{
  switch( action )
  {
    case 1: //COPY
      copyEdit();
      break;
    case 2: //CUT
      cutEdit();
      break;
    case 3: //PASTE
      pasteEdit();
      break;
    default:
      break;
  }
}

/*!
  * \author Ingemar Axelsson and Anders Fernström
  *
  */
void NotebookWindow::keyPressEvent(QKeyEvent *event)
{
  // 2006-01-30 AF, check if 'Alt+Enter'
  if( event->modifiers() == Qt::AltModifier )
  {
    if( event->key() == Qt::Key_Enter ||
        event->key() == Qt::Key_Return )
    {
      createNewCell();
    }
    else
      QMainWindow::keyPressEvent(event);
  }
  // 2006-02-14 AF, check id 'Shift+Enter'
  else if( event->modifiers() == Qt::ShiftModifier &&
           ( event->key() == Qt::Key_Enter || event->key() == Qt::Key_Return ))
  {
    evalCells();
  }
}

/*!
  * \author Ingemar Axelsson and Anders Fernström
  * \date 2005-11-22 (update)
  *
  * \brief Method for catching some keyevent, and given them
  * new functionality
  *
  * 2005-11-22 AF, Added support for deleting cells with 'DEL'
  * key.
  */
void NotebookWindow::keyReleaseEvent(QKeyEvent *event)
{
  // if Ctrl is pressed
  if(event->modifiers() == Qt::ControlModifier)
  {
    if(event->key() == Qt::Key_Up)
    {
      moveCursorUp();
      event->accept();
    }
    else if(event->key() == Qt::Key_Down)
    {
      moveCursorDown();
      event->accept();
    }
    else
      QMainWindow::keyReleaseEvent(event);
  }
  else
  {
    // 2005-11-22 AF, Support for deleting cells with 'DEL' key.
    if( event->key() == Qt::Key_Delete )
    {
      vector<Cell *> cells = subject_->getSelection();
      if( !cells.empty() )
      {
        deleteCurrentCellAsk();
        event->setAccepted( true );
      }
      else
        QMainWindow::keyReleaseEvent(event);
    }
    else
      QMainWindow::keyReleaseEvent(event);
  }
}

/*!
  * \author Ingemar Axelsson and Anders Fernström
  *
  * \todo Fix the code, when the window doesn't have any file open,
  * the command should create the new document, not this function //AF
  */
void NotebookWindow::newFile()
{
  /*
  application()->commandCenter()->executeCommand(new NewFileCommand());

  closeFile();

  createSavingTimer();

  subject_ = new CellDocument(this);

  connect(subject_, SIGNAL(cursorChanged()),
  this, SLOT(setSelectedStyle()));

  setCentralWidget(subject_);

  subject_->show();
  */

  // AF
  if( subject_->isOpen() )
  {
    // a file is open, open a new window with the new file //AF
    application()->commandCenter()->executeCommand(new OpenFileCommand(QString()));
  }
  else
  {
    if(subject_->hasChanged())
    {
      int res = QMessageBox::question(this, tr("Save document?"), tr("The document has been modified. Do you want to save the changes?"),  QMessageBox::Yes | QMessageBox::Default, QMessageBox::No,  QMessageBox::Cancel);
      if(res == QMessageBox::Yes)
      {
        save();
        if(subject_->getFilename().isNull())
          return;
      }
      else if(res == QMessageBox::Cancel)
        return;
    }

    subject_ = new CellDocument(app_, QString());
    dynamic_cast<CellDocument*>(subject_)->autoIndent = autoIndentAction->isChecked();
    subject_->executeCommand(new NewFileCommand());
    subject_->attach(this);

    update();
    updateWindowTitle();
  }
}

void NotebookWindow::updateRecentFiles(QString filename)
{
  QSettings s(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omnotebook");
  QStringList tmpLst;
  QString tmp;
  for(int i = 0; i < 8; ++i)
  {
    if((tmp = s.value(QString("Recent") + QString(i), QString()).toString()) != QString())
      tmpLst.push_back(tmp);
    else
      break;
  }

  if(tmpLst.indexOf(filename) != -1)
    tmpLst.move(tmpLst.indexOf(filename), 0);
  else
    tmpLst.push_front(filename);

  for(int i = 0; i < 8 && i < tmpLst.size(); ++i)
    s.setValue(QString("Recent") + QString(i), tmpLst[i]);

}

/*!
  * \author Ingemar Axelsson and Anders Fernström
  *
  * \brief Open a file. Shows a file dialog.
  */
void NotebookWindow::openFile(const QString filename)
{
  try
  {
    //Open a new document
    if(filename.isEmpty())
    {
      //Show a dialog for choosing a file.
      filename_ = QFileDialog::getOpenFileName(
            this,
            "OMNotebook --  New File Open",
            openDir_,
            "Notebooks (*.onb *.onbz *.nb)" );
    }
    else
    {
      filename_ = filename;
    }

    if(!filename_.isEmpty())
    {
      // 2006-03-01 AF, Update openDir_
      openDir_ = QFileInfo( filename_ ).absolutePath();

      updateRecentFiles(filename_);

      application()->commandCenter()->executeCommand(new OpenFileCommand(filename_));
    }
    else
    {
      //Cancel pushed. Do nothing
    }
  }
  catch(exception &e)
  {
    QMessageBox::warning( 0, tr("Warning"), tr("In OpenFile(), Exception: \n") + e.what(), "OK" );
    openFile();
  }
}

/*!
  * \author Ingemar Axelsson and Anders Fernström
  *
  */
void NotebookWindow::closeFile()
{
  // TODO: the function isn't used correctly, this function
  // should also close the window, if it isn't the last window
  //subject_->executeCommand(new CloseFileCommand());

  close();

  //application()->

  // if(savingTimer_)
  //       {
  //    savingTimer_->stop();
  //    delete savingTimer_;
  //       }
  //delete subject_;
}

/*!
  * \author Anders Fernström
  * \date 2006-01-19
  *
  * \brief Reimplemented closeEvent so all close event are handled
  * correctly. If the document is unsaved, the application will ask
  * the user if he/she wants to save before closing the document.
  */
void NotebookWindow::closeEvent( QCloseEvent *event )
{
  QString filename = QFileInfo( subject_->getFilename() ).fileName();
  filename.remove( "\n" );

  //qDebug()<<"enter notbook exit \n";
  QDir dir;
  dir.setPath(dir.absolutePath()+"/OMNotebook_tempfiles");

#if USE_OMSKETCH
  if(!window->filenames.isEmpty())
  {
    for(int i=0;i<window->filenames.size();i++)
      dir.remove(window->filenames[i]);
  }
#endif

  // if no name, set name to '(untitled)'
  if( filename.isEmpty() )
    filename = "(untitled)";

  // if the document has been changed, ask if the
  // user wants to save the document
  while( subject_->hasChanged() )
  {
    int res = QMessageBox::question(this, tr("Document is unsaved"), tr("The document \"%1\" is unsaved, do you want to save the document?").arg(filename),
                                    QMessageBox::Save | QMessageBox::Discard |  QMessageBox::Cancel, QMessageBox::Save);

    if( res == QMessageBox::Discard ) {
      break;
    }
    else if(res == QMessageBox::Save) {
      save();
    }
    else if(res == QMessageBox::Cancel)
    {
      event->ignore();
      return;
    }
  }
  application()->clearPasteboard(); // HACK: clear pasteboard as some items might refer to cells in the just closed document
}

/*!
 * \class AboutDialog
 * \brief Creates a dialog that shows the about text of OMNotebook.
 * Information about OpenModelica Notebook Editor. Shows the list of OMNotebook contributors.
 */
class AboutDialog : public QDialog {
/*!
 * \brief AboutDialog::AboutDialog
 * \param pMainWindow - pointer to MainWindow
 */
public:
  AboutDialog(QMainWindow *pMainWindow) : QDialog(pMainWindow) {
    QString version = OmcInteractiveEnvironment::OMCVersion();
    setWindowTitle(tr("About %1").arg("OMNotebook"));
    setAttribute(Qt::WA_DeleteOnClose);

    const QString aboutText = tr(
       "<h2>%1 - %2</h2>"
       "<b>%3</b><br />"
       "<b>Connected to %4</b><br /><br />"
       "Copyright <b>Open Source Modelica Consortium (OSMC)</b>.<br />"
       "Distributed under OSMC-PL and GPL, see <u><a href=\"http://www.openmodelica.org\">www.openmodelica.org</a></u>.<br /><br />"
       "Initially developed by <b>Ingemar Axelsson</b>, <b>Anders Fernstr&ouml;m</b> and <b>Henrik Eriksson</b> as part of their final theses.<br>"
       "<br /><br /><b>Contributors:</b>"
       "<ul>"
       "<li>Adeel Asghar"
       "<li>Dr. Henning Kiel"
       "<li>Arunkumar Palanisamy"
       "<li>Adrian Pop"
       "<li>Martin Sj&ouml;lund"
       "</ul>")
     .arg("OMNotebook",
          "OpenModelica Notebook Editor",
          version,
          version);
    // about text label
    QLabel *pAboutTextLabel = new QLabel(aboutText);
    pAboutTextLabel->setWordWrap(true);
    pAboutTextLabel->setOpenExternalLinks(true);
    pAboutTextLabel->setTextInteractionFlags(Qt::TextBrowserInteraction);
    pAboutTextLabel->setToolTip("");
    // close button
    QPushButton *pCloseButton = new QPushButton(tr("Close"));
    connect(pCloseButton, SIGNAL(clicked()), SLOT(reject()));
    // logo label
    QLabel *pLogoLabel = new QLabel;
    QPixmap pixmap(":/Resources/OMNotebook_icon.svg");
    pLogoLabel->setPixmap(pixmap.scaled(128, 128, Qt::KeepAspectRatio, Qt::SmoothTransformation));
    // main layout
    QGridLayout *pMainLayout = new QGridLayout;
    pMainLayout->addWidget(pLogoLabel, 0, 0, Qt::AlignTop | Qt::AlignLeft);
    pMainLayout->addWidget(pAboutTextLabel, 0, 1, Qt::AlignTop | Qt::AlignLeft);
    pMainLayout->addWidget(pCloseButton, 1, 0, 1, 2, Qt::AlignRight);
    setLayout(pMainLayout);
  }
};

/*!
  * \author Anders Fernström and Ingemar Axelsson
  *
  * \brief display an ABOUT message box with information about
  * OMNotebook.
  */
void NotebookWindow::aboutQTNotebook()
{
  AboutDialog *pAboutDialog = new AboutDialog(this);
  pAboutDialog->exec();
}

/*!
  * \author Anders Fernström
  *
  * \brief display an ABOUT message box with information about
  * Qt.
  */
void NotebookWindow::aboutQT()
{
  QMessageBox::aboutQt( this );
}

/*!
  * \author Anders Fernström
  * \date 2006-02-03
  *
  * \brief open the help document, if it exists
  */
void NotebookWindow::helpText()
{
  try
  {
    QDir dir;
    QString helpFile = OmcInteractiveEnvironment::OpenModelicaHome() + "/share/omnotebook/OMNotebookHelp.onb";

    if( dir.exists( helpFile ) )
    {
      application()->commandCenter()->executeCommand(
            new OpenFileCommand( helpFile ));
    }
    else
    {
      QMessageBox::warning( 0, tr("Warning"), tr("Could not find the help document OMNotebookHelp.onb"), "OK" );
    }
  }
  catch(exception &e)
  {
    QString msg = tr("In HelpText(), Exception: \n") + e.what();
    QMessageBox::warning( 0, tr("Warning"), msg, "OK" );
  }
}

/*!
  * \author Anders Fernström and Ingemar Axelsson
  * \date 2005-09-30 (update)
  *
  * \brief Save As function
  *
  * 2005-09-22 AF, added code for updating window title
  * 2005-09-30 AF, add check for fileend when saving.
  *
  *
  * \todo Some of this code should be moved to CellDocument
  *  instead. The filename should be connected to the document, not
  *  to the window for example.(Ingemar Axelsson)
  */
void NotebookWindow::saveas()
{
  // if a filename exists, use that filename as default
  QString filename;
  /*    don't work correctly.
  if( !subject_->getFilename().isEmpty() )
  {
   // open save as dialog
   filename = QFileDialog::getSaveFileName(
    this,
    "Choose a filename to save under",
    subject_->getFilename(),
    "OpenModelica Notebooks (*.onb)");
  }
  else
  {*/
  // open save as dialog
  filename = QFileDialog::getSaveFileName(
        this,
        tr("Choose a filename to save under"),
        saveDir_,
        "OpenModelica Notebooks (*.onb);;Compressed OM Notebooks (*.onbz)");
  //}

  if(!filename.isEmpty())
  {
    // 2005-09-30 AF, add check for fileend when saving.
    if( !filename.endsWith( ".onb", Qt::CaseInsensitive ) && !filename.endsWith( ".onbz", Qt::CaseInsensitive ) )
    {
      qDebug( ".onb not found" );
      filename.append( ".onb" );
    }

    //Added by Jhansi
    //Saves the image along with document
    //window->insertImage(filename);
    //window->SaveSketchImage(filename);

    //QMessageBox::about(this,"entered ","image witten ");

    statusBar()->showMessage(tr("Saving file"));
    application()->commandCenter()->executeCommand(new SaveDocumentCommand(subject_, filename));

    filename_ = filename;
    statusBar()->showMessage(tr("Ready"));

    updateRecentFiles(filename_);


    // 2006-03-01 AF, Update saveDir_
    saveDir_ = QFileInfo( filename_ ).absolutePath();

    // 2005-09-22 AF, update window title
    updateWindowTitle();
  }
}

/*!
  * \author Anders Fernström and Ingemar Axelsson
  *
  * Added a check that controlls if the user have saved before,
  * if not the function saveas should be used instead. //AF
  */
void NotebookWindow::save()
{
  // Added a check to see if the document has been saved before,
  // if the document havn't been saved before - call saveas() instead.
  if( !subject_->isSaved() )
  {
    saveas();
  }
  else
  {
    statusBar()->showMessage(tr("Saving file"));
    application()->commandCenter()->executeCommand(new SaveDocumentCommand(subject_));
    statusBar()->showMessage(tr("Ready"));

    updateWindowTitle();
  }
}

/*!
  * \author Anders Fernström
  * \date 2006-01-18
  *
  * \brief Quit OMNotebook
  */
void NotebookWindow::quitOMNotebook()
{
  closing_ = true;
  qApp->closeAllWindows();
}

/*!
  * \author Anders Fernström
  * \date 2005-12-19
  * \date 2006-02-23 (update)
  *
  * \brief Open printdialog and print the document
  *
  * 2006-02-23 AF, display message box after printing is done.
  */
void NotebookWindow::print()
{
  QPrinter printer( QPrinter::HighResolution );
  //printer.setFullPage( true );
  //printer.setColorMode( QPrinter::GrayScale );

  QPrintDialog *dlg = new QPrintDialog(&printer, this);
  if( dlg->exec() == QDialog::Accepted )
  {
    // 2006-03-03 AF, make sure that chapter numbers are updated
    updateChapterCounters();

    application()->commandCenter()->executeCommand(
          new PrintDocumentCommand(subject_, &printer));

    //currentEditor->document()->print(&printer);

    // 2006-02-23 AF, display message box after printing document
    QString title = QFileInfo( subject_->getFilename() ).fileName();
    title.remove( "\n" );
    if( title.isEmpty() )
      title = "(untitled)";

    QMessageBox::information( 0, tr("Document printed"), tr( "The document %1 has been printed on %2." ).arg(title, printer.printerName()), "OK" );
  }

  delete dlg;
}

/*!
  * \author Henning Kiel
  * \date 2016-12-01
  *
  * \brief Export the document as PDF
  *
  * 2016-12-01 HK
  */
void NotebookWindow::pdf()
{
  QPrinter printer( QPrinter::HighResolution );
  printer.setOutputFormat(QPrinter::PdfFormat);

  QString filename;
  if( !subject_->getFilename().isEmpty() )
  {
    QFileInfo fi(subject_->getFilename());
    QFileInfo fi2(fi.absoluteDir(), fi.completeBaseName());
    // open save as dialog
    filename = QFileDialog::getSaveFileName(
        this,
        tr("Choose a filename to save PDF under"),
        fi2.filePath(),
        "PDF (*.pdf)");
  }
  else
  {
  // open save as dialog
  filename = QFileDialog::getSaveFileName(
        this,
        tr("Choose a filename to save PDF under"),
        saveDir_,
        "PDF (*.pdf)");
  }

  if(!filename.isEmpty())
  {
    if( !filename.endsWith( ".pdf", Qt::CaseInsensitive ) )
    {
      filename.append( ".pdf" );
    }

  printer.setOutputFileName(filename);
  printer.setFullPage( true );

    // make sure that chapter numbers are updated
    updateChapterCounters();

    application()->commandCenter()->executeCommand(
          new PrintDocumentCommand(subject_, &printer));

    //currentEditor->document()->print(&printer);

    QString title = QFileInfo( subject_->getFilename() ).fileName();
    title.remove( "\n" );
    if( title.isEmpty() )
      title = "(untitled)";
    QMessageBox::information( 0, tr("Document exported"), tr("The document %1 has been exported as PDF to %2.").arg(title, filename), "OK" );
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-07
  *
  * \brief Method for changing the font
  */
void NotebookWindow::selectFont()
{
  if( !cellEditable() )
    return;

  bool ok;
  QFont font = QFontDialog::getFont(&ok, QFont("Times New Roman", 12), this);

  if( ok )
  {
    subject_->textcursorChangeFontFamily( font.family() );
    subject_->textcursorChangeFontSize( font.pointSize() );

    // sätt först plain text
    subject_->textcursorChangeFontFace( 0 );

    if( font.underline() )
      subject_->textcursorChangeFontFace( 3 );

    if( font.italic() )
      subject_->textcursorChangeFontFace( 2 );

    if( font.weight() > QFont::Normal )
      subject_->textcursorChangeFontFace( 1 );

    if( font.strikeOut() )
      subject_->textcursorChangeFontFace( 4 );
  }
}

/*!
  * \author Ingemar Axelsson
  */
void NotebookWindow::changeStyle(QAction *action)
{
  // 2005-10-28 changed here because style changed from QString
  // to CellStyle /AF
  //subject_->cursorChangeStyle(action->text());

  Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" );
  CellStyle style = sheet->getStyle( action->text() );

  if( style.name() != "null" )
    subject_->cursorChangeStyle( style );
  else
  {
    // 2006-01-30 AF, add message box
    QMessageBox::warning( 0, tr("Warning"), tr("Not a valid style name: %1").arg(action->text()), "OK" );
  }

  updateChapterCounters();
}

/*!
  * \author Ingemar Axelsson (and Anders Fernström)
  */
void NotebookWindow::changeStyle()
{
  // 2005-10-28 changed in the funtion here because style changed
  // from QString  to CellStyle /AF
  map<QString, QAction*>::iterator cs = styles_.begin();
  Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" ); //AF
  for(;cs != styles_.end(); ++cs)
  {
    if( (*cs).second->isChecked( ))
    {
      // look up style /AF
      CellStyle style = sheet->getStyle( (*cs).first );
      if( style.name() != "null" )
        subject_->cursorChangeStyle( style );

    }
  }

  updateChapterCounters();
}

/*!
  * \author Anders Fernström
  * \date 2005-11-03
  *
  * \brief Method for changing font on selected text
  */
void NotebookWindow::changeFont(QAction *action)
{
  if( !cellEditable() )
    return;

  subject_->textcursorChangeFontFamily( action->text() );
}

/*!
  * \author Anders Fernström
  * \date 2005-11-03
  *
  * \brief Method for changing face on selected text
  */
void NotebookWindow::changeFontFace( QAction *action )
{
  if( !cellEditable() )
    return;

  if( action->whatsThis() == "Plain" )
    subject_->textcursorChangeFontFace( 0 );
  else if( action->whatsThis() == "Bold" )
    subject_->textcursorChangeFontFace( 1 );
  else if( action->whatsThis() == "Italic" )
    subject_->textcursorChangeFontFace( 2 );
  else if( action->whatsThis() == "Underline" )
    subject_->textcursorChangeFontFace( 3 );
}

/*!
  * \author Anders Fernström
  * \date 2005-11-04
  *
  * \brief Method for changing size on selected text
  */
void NotebookWindow::changeFontSize( QAction *action )
{
  if( !cellEditable() )
    return;

  if( action->whatsThis() == "Smaller" )
  { // SMALLER
    QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
    if( !cursor.isNull() )
    {
      int size = cursor.charFormat().font().pointSize();
      if( size < 2 )
        size = 2;

      subject_->textcursorChangeFontSize( size - 1 );
    }
  }
  else if( action->whatsThis() == "Larger" )
  { // LARGER
    QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
    if( !cursor.isNull() )
    {
      int size = cursor.charFormat().fontPointSize();
      subject_->textcursorChangeFontSize( size + 1 );
    }

  }
  else if( action->whatsThis() == "Other" )
  { // OTHER
    OtherDlg other(this, 6, 200);
    if( QDialog::Accepted == other.exec() )
    {
      int size = other.value();
      if( size > 0 )
        subject_->textcursorChangeFontSize( size );
      else
      {
        // 2006-01-30 AF, add message box
        QMessageBox::warning( 0, tr("Warning"), tr("Not a value between %1 and %2.").arg(6).arg(200), "OK" );
      }
    }
  }
  else
  { // MISC
    bool ok;
    int size = action->text().toInt(&ok);

    if( ok )
      subject_->textcursorChangeFontSize( size );
    else
    {
      // 2006-01-30 AF, add message box
      QString msg = "Not a correct font size";
      QMessageBox::warning( 0, tr("Warning"), msg, "OK" );
    }
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-04
  *
  * \brief Method for changing stretch on selected text
  */
void NotebookWindow::changeFontStretch( QAction *action )
{
  if( !cellEditable() )
    return;

  if( action->whatsThis() == "ucon" )
    subject_->textcursorChangeFontStretch( QFont::UltraCondensed );
  else if( action->whatsThis() == "econ" )
    subject_->textcursorChangeFontStretch( QFont::ExtraCondensed );
  else if( action->whatsThis() == "con" )
    subject_->textcursorChangeFontStretch( QFont::Condensed );
  else if( action->whatsThis() == "scon" )
    subject_->textcursorChangeFontStretch( QFont::SemiCondensed );
  else if( action->whatsThis() == "uns" )
    subject_->textcursorChangeFontStretch( QFont::Unstretched );
  else if( action->whatsThis() == "sexp" )
    subject_->textcursorChangeFontStretch( QFont::SemiExpanded );
  else if( action->whatsThis() == "exp" )
    subject_->textcursorChangeFontStretch( QFont::Expanded );
  else if( action->whatsThis() == "eexp" )
    subject_->textcursorChangeFontStretch( QFont::ExtraExpanded );
  else if( action->whatsThis() == "uexp" )
    subject_->textcursorChangeFontStretch( QFont::UltraExpanded );
}

/*!
  * \author Anders Fernström
  * \date 2005-11-07
  *
  * \brief Method for changing color on selected text
  */
void NotebookWindow::changeFontColor( QAction *action )
{
  if( !cellEditable() )
    return;

  if( colors_.contains( action ))
  {
    subject_->textcursorChangeFontColor( (*colors_[action]) );
  }
  else
  {
    QColor color;
    QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
    if( !cursor.isNull() )
      color = cursor.charFormat().foreground().color();
    else
      color = Qt::black;

    QColor newColor = QColorDialog::getColor( color, this );
    if( newColor.isValid() )
      subject_->textcursorChangeFontColor( newColor );
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-07
  *
  * \brief Method for changing alignment on selected paragraf
  */
void NotebookWindow::changeTextAlignment( QAction *action )
{
  if( !cellEditable() )
    return;

  QHash<int, QAction*>::iterator a_iter = alignments_.begin();
  while( a_iter != alignments_.end() )
  {
    if( a_iter.value() == action )
    {
      subject_->textcursorChangeTextAlignment( a_iter.key() );
      break;
    }

    ++a_iter;
  }

  if( a_iter == alignments_.end() )
  {
    // 2006-01-30 AF, add message box
    QString msg = "Unable to find the correct alignment";
    QMessageBox::warning( 0, tr("Warning"), msg, "OK" );
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-07
  *
  * \brief Method for changing vertical alignment on selected text
  */
void NotebookWindow::changeVerticalAlignment( QAction *action )
{
  if( !cellEditable() )
    return;

  QHash<int, QAction*>::iterator v_iter = verticals_.begin();
  while( v_iter != verticals_.end() )
  {
    if( v_iter.value() == action )
    {
      subject_->textcursorChangeVerticalAlignment( v_iter.key() );
      break;
    }

    ++v_iter;
  }

  if( v_iter == verticals_.end() )
  {
    // 2006-01-30 AF, add message box
    QString msg = "Unable to find the correct vertical alignment";
    QMessageBox::warning( 0, tr("Warning"), msg, "OK" );
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-07
  *
  * \brief Method for changing border on selected cell
  */
void NotebookWindow::changeBorder( QAction *action )
{
  if( !cellEditable() )
    return;

  if( action->whatsThis() == "Other" )
  {
    OtherDlg other(this, 0, 30);
    if( QDialog::Accepted == other.exec() )
    {
      int border = other.value();
      if( border > 0 ) {
        subject_->textcursorChangeBorder( border );
      }
      else
      {
        // 2006-01-30 AF, add message box
        QMessageBox::warning( 0, tr("Warning"), tr("Not a value between %1 and %2.").arg(0).arg(30), "OK" );
      }
    }
  }
  else
  {
    bool ok;
    int border = action->text().toInt( &ok );

    if( ok ) {
      subject_->textcursorChangeBorder( border );
    }
    else
    {
      // 2006-01-30 AF, add message box
      QMessageBox::warning( 0, tr("Warning"), tr("Error converting string to integer."), "OK" );
    }
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-07
  *
  * \brief Method for changing margin on selected cell
  */
void NotebookWindow::changeMargin( QAction *action )
{
  if( !cellEditable() )
    return;

  if( action->whatsThis() == "Other" )
  {
    OtherDlg other(this, 0, 80);
    if( QDialog::Accepted == other.exec() )
    {
      int margin = other.value();
      if( margin > 0 )
        subject_->textcursorChangeMargin( margin );
      else
      {
        // 2006-01-30 AF, add message box
        QMessageBox::warning( 0, tr("Warning"), tr("Not a value between %1 and %2.").arg(0).arg(80), "OK" );
      }
    }
  }
  else
  {
    bool ok;
    int margin = action->text().toInt( &ok );

    if( ok )
      subject_->textcursorChangeMargin( margin );
    else
    {
      // 2006-01-30 AF, add message box
      QMessageBox::warning( 0, tr("Warning"), tr("Error converting string to integer."), "OK" );
    }
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-07
  *
  * \brief Method for changing padding on selected cell
  */
void NotebookWindow::changePadding( QAction *action )
{
  if( !cellEditable() )
    return;

  if( action->whatsThis() == "Other" )
  {
    OtherDlg other(this, 0, 60);
    if( QDialog::Accepted == other.exec() )
    {
      int padding = other.value();
      if( padding > 0 )
        subject_->textcursorChangePadding( padding );
      else
      {
        // 2006-01-30 AF, add message box
        QMessageBox::warning( 0, tr("Warning"), tr("Not a value between %1 and %2.").arg(0).arg(60), "OK" );
      }
    }
  }
  else
  {
    bool ok;
    int padding = action->text().toInt( &ok );

    if( ok )
      subject_->textcursorChangePadding( padding );
    else
    {
      // 2006-01-30 AF, add message box
      QMessageBox::warning( 0, tr("Warning"), tr("Error converting string to integer."), "OK" );
    }
  }
}

/*!
  * \author Anders Fernström
  * \date 2006-01-27
  *
  * \brief Method for changing the current notebook window
  */
void NotebookWindow::changeWindow(QAction *action)
{
  if( !windows_[action]->isActiveWindow() )
  {
    windows_[action]->activateWindow();
    windows_[action]->raise();
    //windows_[action]->showNormal();
  }
}

/*!
  * \author Anders Fernström
  * \date 2006-02-03
  *
  * \brief Method for doing undo on text
  */
void NotebookWindow::undoEdit()
{
  QTextEdit *editor = subject_->getCursor()->currentCell()->textEdit();
  if( editor )
  {
    editor->document()->undo();
  }
}

/*!
  * \author Anders Fernström
  * \date 2006-02-03
  *
  * \brief Method for doing redo on text
  */
void NotebookWindow::redoEdit()
{
  QTextEdit *editor = subject_->getCursor()->currentCell()->textEdit();
  if( editor )
  {
    editor->document()->redo();
  }
}

/*!
  * \author Anders Fernström
  * \date 2006-02-03
  * \date 2006-04-27 (update)
  *
  * \brief Method for cutting text
  *
  * 2006-04-27 AF, if cells are selected in the treeview cut
  * them instead of the text.
  */
void NotebookWindow::cutEdit()
{
  if( subject_ )
  {
    if( subject_->getSelection().size() > 0 )
      cutCell();
    else
      subject_->textcursorCutText();
  }
}

/*!
  * \author Anders Fernström
  * \date 2006-02-03
  * \date 2006-04-27 (update)
  *
  * \brief Method for copying text
  *
  * 2006-04-27 AF, if cells are selected in the treeview copy
  * them instead of the text.
  */
void NotebookWindow::copyEdit()
{
  if( subject_ )
  {
    if( subject_->getSelection().size() > 0 )
      copyCell();
    else
      subject_->textcursorCopyText();
  }
}

/*!
  * \author Anders Fernström
  * \date 2006-02-03
  * \date 2006-04-27 (update)
  *
  * \brief Method for pasteing text
  *
  * 2006-04-27 AF, if the cell cursor is selected, paste
  * cell instead of text.
  */
void NotebookWindow::pasteEdit()
{
  if( subject_ )
  {
    if( subject_->getCursor()->isClickedOn() )
      pasteCell();
    else
      subject_->textcursorPasteText();
  }
}

/*!
  * \author Anders Fernström
  * \date 2006-08-24
  *
  * \brief Menu function, perform find
  */
void NotebookWindow::findEdit()
{
  if( subject_ )
  {
    // initiate findform, check if it is already visible, or set the current document
    if( !findForm_ )
      findForm_ = new SearchForm( this, subject_ );
    else
      findForm_->setDocument( subject_ );

    // show/start find form
    if( !findForm_->isVisible() )
      findForm_->show();
  }
}

/*!
  * \author Anders Fernström
  * \date 2006-08-24
  *
  * \brief Menu function, perform replace
  */
void NotebookWindow::replaceEdit()
{
  if( subject_ )
  {
    // initiate findform(replace), check if it is already visible, or set the current document
    if( !findForm_ )
      findForm_ = new SearchForm( this, subject_, true );
    else
      findForm_->setDocument( subject_ );

    // show/start find form
    if( !findForm_->isVisible() )
      findForm_->show();
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-18
  *
  * \brief Method for inserting an image into the cell
  */
void NotebookWindow::insertImage()
{
  if( !cellEditable() )
    return;

  QString imageformat = "Images (";
  QList<QByteArray> list = QImageReader::supportedImageFormats();
  for( int i = 0; i < list.size(); ++i )
    imageformat += QString("*.") + QString(list.at(i)) + " ";
  imageformat += ")";

  QString filepath = QFileDialog::getOpenFileName(
        this, "Insert Image - Select Image", imageDir_,
        imageformat );

  if( !filepath.isNull() )
  {
    QImage image( filepath );
    if( !image.isNull() )
    {
      ImageSizeDlg imageSize( this, &image );
      if( QDialog::Accepted == imageSize.exec() )
      {
        QSize size = imageSize.value();
        if( size.isValid() )
          subject_->textcursorInsertImage( filepath, size );
        else
          qDebug("Not a valid image size");
      }
    }

    // 2006-03-01 AF, Update imageDir_
    imageDir_ = QFileInfo( filepath ).absolutePath();
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-12-05
  *
  * \brief Method for inserting an link to the selected cell
  */
void NotebookWindow::insertLink()
{
  if( !cellEditable() )
    return;

  // check if text is selected
  QTextCursor cursor = subject_->getCursor()->currentCell()->textCursor();
  if( !cursor.isNull() )
  {
    if( cursor.hasSelection() )
    {
      QString filepath = QFileDialog::getOpenFileName(
            this, "Insert Link - Select Document", linkDir_,
            "Notebooks (*.onb *.nb)" );

      if( !filepath.isNull() )
      {
        // 2006-03-01 AF, Update linkDir_
        linkDir_ = QFileInfo( filepath ).absolutePath();
        // change the link color to blue
        subject_->textcursorChangeFontColor(Qt::blue);
        subject_->textcursorInsertLink( filepath, cursor );

      }
    }
    else
    {
      QMessageBox::warning( this, "Error",
        tr("A text that should make up the link, must be selected"), "OK" );
    }
  }
}

void NotebookWindow::indent()
{
  GraphCell* g;
  if((g = dynamic_cast<GraphCell*>(subject_->getCursor()->currentCell())))
  {
    g->input_->indentText();
  }

}

//Functions added by Jhansi

#if USE_OMSKETCH
void NotebookWindow::Sketch()
{
  QString num;

  if(isShown==false)
  {
    window->getCells(this->cells);
    window->show();
    isShown=true;
  }
  else
    window->show();

}

void NotebookWindow::sketchImageEdit()
{
  if( !cellEditable() )
    return;

  QString file,num;

  // check if text is selected
  QTextCursor cursor = subject_->getCursor()->currentCell()->textCursor();
  //int pos=(subject_->getCursor()->currentCell()->textCursor().position());

  /*for(int i=0;i<cells.size();i++)
  {
   if(cells[i]==subject_->getCursor()->currentCell())
   {
    QMessageBox::about(this,"cell","Cell found");
    break;
   }
  }*/

  while( !cursor.isNull() )
  {
    if(isShown==false)
    {

      window->getCells(this->cells);
      window->show();
      window->open();
      isShown=true;
      break;
    }

    if(isShown==true)
    {
      //QMessageBox::about(this,"cell","");
      window->open();
      window->show();
      isShown=false;
      break;
    }
  }
}


void NotebookWindow::viewSketchImageAttributes()
{
  QTextCursor cursor = subject_->getCursor()->currentCell()->textCursor();

  QVector<QString> subTexts;
  subTexts.clear();

  QString text="";

  if( !cursor.isNull() )
  {
    window->getCells(this->cells);
    window->readFileAttributes(subTexts);

    if(!subTexts.isEmpty())
    {
      for(int i=0;i<subTexts.size();i++)
      {
        text+=subTexts[i];
      }
    }
  }

  cursor.insertText(text);
  //QTextCharFormat format =  *subject_->getCursor()->currentCell()->style()->textCharFormat();
  QMessageBox::about(this,"char format",subject_->getCursor()->currentCell()->text());
}
#endif

/*!
  * \author Anders Fernström
  * \date 2005-12-01
  *
  * \brief Method for opening an old file, saved with OMNotebook (QT3)
  */
void NotebookWindow::openOldFile()
{
  try
  {
    QString filename = QFileDialog::getOpenFileName(
          this,
          "OMNotebook -- Open old OMNotebook file",
          openDir_,
          "Old OMNotebook (*.xml)" );

    if( !filename.isEmpty() )
    {
      // 2006-03-01 AF, Update openDir_
      openDir_ = QFileInfo( filename ).absolutePath();

      application()->commandCenter()->executeCommand(
            new OpenOldFileCommand( filename, READMODE_OLD ));
    }
  }
  catch( exception &e )
  {
    QString msg = QString("In NotebookWindow(), Exception:\r\n") + e.what();
    QMessageBox::warning( 0, tr("Warning"), msg, "OK" );
    openOldFile();
  }
}

/*!
  * \author Anders Fernström
  * \date 2005-11-21
  * \date 2006-03-24 (update)
  *
  * \brief Method for exporting the document content to a file with
  * pure text only
  *
  * 2006-03-24 AF, Added message box to inform the user when export
  * is done.
  */
void NotebookWindow::pureText()
{
  QString filename = QFileDialog::getSaveFileName(
        this,
        tr("Choose a filename to export text to"),
        saveDir_,
        "Textfile (*.txt)");

  if( !filename.isEmpty() )
  {
    if( !filename.endsWith( ".txt", Qt::CaseInsensitive ) )
    {
      qDebug( ".txt not found" );
      filename.append( ".txt" );
    }

    // 2006-03-01 AF, Update saveDir_
    saveDir_ = QFileInfo( filename_ ).absolutePath();

    // 2006-03-03 AF, make sure that chapter numbers are updated
    updateChapterCounters();

    application()->commandCenter()->executeCommand(
          new ExportToPureText(subject_, filename) );

    // 2006-03-24 AF, added message box - so user know when
    // export is done
    QString title = QFileInfo( subject_->getFilename() ).fileName();
    title.remove( "\n" );
    if( title.isEmpty() )
      title = "(untitled)";

    QMessageBox::information( 0, "Document exported", tr("The document %1 has been exported as pure text to %2.").arg(title,filename), "OK" );
  }
}

/*!
  * \author Ingemar Axelsson
  */
void NotebookWindow::createNewCell()
{
  subject_->cursorAddCell();
  updateChapterCounters();
}

/*!
  * \author Ingemar Axelsson
  */
void NotebookWindow::deleteCurrentCell()
{
  subject_->cursorDeleteCell();
  updateChapterCounters();
}

void NotebookWindow::deleteCurrentCellAsk()
{
  if (QMessageBox::warning( 0, "Delete Cell", tr("Delete current cell?\nThis action cannot be undone!"), QMessageBox::Ok|QMessageBox::Default,QMessageBox::Cancel ) == QMessageBox::Ok)
  {
    subject_->cursorDeleteCell();
    updateChapterCounters();
  }
}

/*!
  * \author Ingemar Axelsson
  */
void NotebookWindow::cutCell()
{
  subject_->cursorCutCell();
  updateChapterCounters();
}

/*!
  * \author Ingemar Axelsson
  */
void NotebookWindow::copyCell()
{
  subject_->cursorCopyCell();
}

/*!
  * \author Ingemar Axelsson
  */
void NotebookWindow::pasteCell()
{
  subject_->cursorPasteCell();
  updateChapterCounters();
}

/*!
  * \author Anders Fernström
  * \date 2006-04-26
  *
  * \brief Ungroup all selected groupcells
  */
void NotebookWindow::ungroupCell()
{
  if( subject_->getSelection().size() == 1 )
    subject_->cursorUngroupCell();
  else
    QMessageBox::information( this, "Information", tr("Ungroup can only be done on one cell at the time. Please select only one cell") );
}

/*!
  * \author Anders Fernström
  * \date 2006-04-26
  *
  * \brief Split current cell
  */
void NotebookWindow::splitCell()
{
  subject_->cursorSplitCell();
}

/*!
  * \author Ingemar Axelsson
  */
void NotebookWindow::moveCursorDown()
{
  subject_->cursorStepDown();
}

/*!
  * \author Ingemar Axelsson
  */
void NotebookWindow::moveCursorUp()
{
  subject_->cursorStepUp();
}

/*!
  * \author Ingemar Axelsson and Anders Fernström
  * \date 2005-11-29 (update)
  *
  * 2005-11-29 AF, added call to updateScrollArea, so the scrollarea
  * are updated when new cell is added.
  */
void NotebookWindow::groupCellsAction()
{
  Cell *cell = subject_->getCursor()->currentCell();
  if( cell )
  {
    if( cell->treeView()->isHidden() )
    {
      QMessageBox::information( 0, tr("Warning"),
                                tr("A textcell, latexcell or inputcell must first be added, before a groupcell can be done") );
    }
    else
    {
      subject_->executeCommand(new MakeGroupCellCommand());
      subject_->updateScrollArea();
    }
  }
}

/*!
  * \author Ingemar Axelsson and Anders Fernström
  * \date 2005-11-29 (update)
  *
  * 2005-11-29 AF, added call to updateScrollArea, so the scrollarea
  * are updated when new cell is added.
  */
void NotebookWindow::inputCellsAction()
{
  subject_->executeCommand(new CreateNewCellCommand("Graph"));
  subject_->updateScrollArea();
  updateChapterCounters();
}

void NotebookWindow::latexCellsAction()
{
  subject_->executeCommand(new CreateNewCellCommand("Latex"));
  subject_->updateScrollArea();
  updateChapterCounters();
}

void NotebookWindow::textCellsAction()
{
  subject_->executeCommand(new CreateNewCellCommand("Text"));
  subject_->updateScrollArea();
  updateChapterCounters();
}

void NotebookWindow::recentTriggered() //Should only be called from the submenu "recent files"
{
  QObject* s = QObject::sender();
  if(s)
    emit openFile(static_cast<QAction*>(s)->text());
}

void NotebookWindow::setAutoIndent(bool b)
{
  //    if(CellDocument* d = dynamic_cast<CellDocument*>(subject_))
  subject_->setAutoIndent2(b);

  QSettings s(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omnotebook");
  s.setValue("AutoIndent", b);
}

void NotebookWindow::eval()
{
  if(GraphCell *g = dynamic_cast<GraphCell*>(subject_->getCursor()->currentCell())) {
    g->eval();
  }

  if(LatexCell *g = dynamic_cast<LatexCell*>(subject_->getCursor()->currentCell())) {
    g->eval();
  }

  if(InputCell *g = dynamic_cast<InputCell*>(subject_->getCursor()->currentCell())) {
    g->eval();
  }
}

/*** Search and Return the number of cells in the document ***/
void NotebookWindow::SearchCells(Cell* current, QVector<Cell*> * total)
{
  if(!current->hasChilds())
  {
    total->append(current);
  }
  else
  {
    Cell *current1 = current->child();
    while(current1!=NULL)
    {
      SearchCells(current1, total);
      current1=current1->next();
    }
  }
}

QVector<Cell*> NotebookWindow::SearchCells(Cell* current)
{
    QVector<Cell*> totalcells;
    Cell *current1;
    if( current != 0 )
    {
      while(current != 0)
      {
        current1=current->child();
        while(current1!=NULL)
        {
          SearchCells(current1, &totalcells);
          current1=current1->next();
        }
        totalcells.append(current);
        current=current->next();
      }
    }

    return totalcells;
}

void NotebookWindow::shiftselectedcells()
{
    vector<Cell *> cells = subject_->getSelection();
    qDebug()<<cells.size();

    if( !cells.empty() )
    {
      // open closed groupcells otherwise OMNotebook does not copy right and crashes afterwards
      vector<Cell *>::iterator i = cells.begin();
      for(;i != cells.end();++i)
      {
        (*i)->setClosed(false);
      }
      subject_->cursorCopyCell();
      subject_->cursorPasteCell();
      Cell* curpos=subject_->getCursor()->currentCell();
      i = cells.begin();
      for(;i != cells.end();++i)
      {
          subject_->getCursor()->moveAfter(*i);
          subject_->getCursor()->deleteCurrentCell();
      }
      subject_->getCursor()->moveAfter(curpos);
      // make sure that chapter numbers are updated
      updateChapterCounters();
    }
    else
    {
        QString msg=tr("This functionality works only on the selected cells. Put the cursor to a position where you want to shift and then select cells you like to move and press this button.");
        QMessageBox::warning( 0, tr("Warning"), msg, "OK" );
    }
}

void NotebookWindow::shiftcellsUp()
{
  vector<Cell *> cells = subject_->getSelection();

  if (cells.size()==0)
  {
    Cell *current=subject_->getCursor()->currentCell();
    if (current->hasPrevious())
    {
      if( typeid(CellGroup) == typeid( *current->previous()))
      {
        QMessageBox::warning( 0, tr("Warning"), err_hierarchy, "OK" );
      }
      else
      {
        if (current->isClosed())
        {
          QMessageBox::warning( 0, tr("Warning"), tr("Cannot move closed cells."), "OK" );
          return;
        }
        //qDebug()<<"not a groupcell" ;
        QString currenttext=current->text();
        QString style=current->style()->name();
        if (style=="Graph")
        {
          GraphCell *g = dynamic_cast<GraphCell *>(current);
          bool eval= g->isEvaluated();
          if(eval==true)
          {
            QString currentinput=g->text();
            QString currentoutput=g->textOutputHtml();
            subject_->cursorDeleteCell();
            subject_->cursorStepUp();
            subject_->executeCommand(new CreateNewCellCommand("Graph"));
            GraphCell *newcell = dynamic_cast<GraphCell *>(subject_->getCursor()->currentCell());
            newcell->setEvaluated(true);
            newcell->setClosed(false);
            newcell->setText(currentinput);
            newcell->setTextOutputHtml(currentoutput);
          }
          else
          {
            subject_->cursorDeleteCell();
            //subject_->getCursor()->moveUp();
            subject_->cursorStepUp();
            subject_->executeCommand(new CreateNewCellCommand("Graph"));
            subject_->getCursor()->currentCell()->setText(currenttext);
          }
        }
        else if(style=="Latex")
        {
          LatexCell *l = dynamic_cast<LatexCell *>(current);
          bool eval= l->isEvaluated();
          //qDebug()<<"latexcells"<<eval << l->textOutputHtml();
          if(eval==true)
          {
            QString latexinput=l->textHtml();
            QString latexoutput=l->textOutputHtml();
            subject_->cursorDeleteCell();
            subject_->cursorStepUp();
            subject_->executeCommand(new CreateNewCellCommand("Latex"));
            LatexCell *newcell = dynamic_cast<LatexCell *>(subject_->getCursor()->currentCell());
            //newcell->setEvaluated(true);
            //newcell->setClosed(false);
            newcell->setTextHtml(latexinput);
            newcell->setTextOutputHtml(latexoutput);
          }
          else
          {
            subject_->cursorDeleteCell();
            //subject_->getCursor()->moveUp();
            subject_->cursorStepUp();
            subject_->executeCommand(new CreateNewCellCommand("Latex"));
            subject_->getCursor()->currentCell()->setText(currenttext);
          }
        }
        else
        {
          Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" );
          std::vector<QString> vector = sheet->getAvailableStyleNames();
          if (std::find(vector.begin(), vector.end(), style) != vector.end() )
          {
            QString textoutput=current->textHtml();
            subject_->cursorDeleteCell();
            //subject_->getCursor()->moveUp();
            subject_->cursorStepUp();
            subject_->executeCommand(new CreateNewCellCommand(style));
            subject_->getCursor()->currentCell()->setTextHtml(textoutput);
          }
        }
      }
    }
    else
    {
      QMessageBox::warning( 0, tr("Warning"), err_hierarchy, "OK" );
    }
  }
  else
  {
    QMessageBox::warning( 0, tr("Warning"), tr("This functionality does not work on selected cells. Click on the cell to move up, and press this action."), "OK" );
  }
}

void NotebookWindow::shiftcellsDown()
{
  vector<Cell *> cells = subject_->getSelection();
  if (cells.size()==0)
  {
    Cell *current=subject_->getCursor()->currentCell();
    subject_->cursorStepDown();
    Cell *next=subject_->getCursor()->currentCell();

    if (current!=next)
    {
      subject_->cursorStepUp();
      if( typeid(CellGroup) == typeid(*next))
      {
          //qDebug()<<"group cell";
          QMessageBox::warning( 0, tr("Warning"), err_hierarchy, "OK" );
      }
      else
      {
        if (current->isClosed())
        {
          QMessageBox::warning( 0, tr("Warning"), tr("Cannot move closed cells."), "OK" );
          return;
        }
        //qDebug()<<"not a group cell";
        QString style=current->style()->name();
        QString currenttext=current->text();

        if (style=="Graph")
        {
          GraphCell *d = dynamic_cast<GraphCell *>(current);
          bool eval= d->isEvaluated();
          if(eval==true)
          {
            QString currentinput=d->text();
            QString currentoutput=d->textOutputHtml();
            subject_->cursorDeleteCell();
            subject_->cursorStepDown();
            subject_->executeCommand(new CreateNewCellCommand("Graph"));
            GraphCell *gcell = dynamic_cast<GraphCell *>(subject_->getCursor()->currentCell());
            gcell->setEvaluated(true);
            gcell->setClosed(false);
            gcell->setText(currentinput);
            gcell->setTextOutputHtml(currentoutput);
          }
          else
          {
            subject_->cursorDeleteCell();
            subject_->cursorStepDown();
            subject_->executeCommand(new CreateNewCellCommand("Graph"));
            subject_->getCursor()->currentCell()->setText(currenttext);
          }
        }
        else if(style=="Latex")
        {
          LatexCell *ld = dynamic_cast<LatexCell *>(current);
          bool eval= ld->isEvaluated();
          //qDebug()<<"latexcells"<<eval << ld->textOutputHtml();
          if(eval==true)
          {
            QString latexinput_d=ld->textHtml();
            QString latexoutput_d=ld->textOutputHtml();
            subject_->cursorDeleteCell();
            subject_->cursorStepDown();
            subject_->executeCommand(new CreateNewCellCommand("Latex"));
            LatexCell *newcell_d = dynamic_cast<LatexCell *>(subject_->getCursor()->currentCell());
            //newcell_d->setEvaluated(true);
            //newcell_d->setClosed(false);
            newcell_d->setTextHtml(latexinput_d);
            newcell_d->setTextOutputHtml(latexoutput_d);
          }
          else
          {
            subject_->cursorDeleteCell();
            //subject_->getCursor()->moveUp();
            subject_->cursorStepDown();
            subject_->executeCommand(new CreateNewCellCommand("Latex"));
            subject_->getCursor()->currentCell()->setText(currenttext);
          }
        }
        else
        {
          Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" );
          std::vector<QString> vector = sheet->getAvailableStyleNames();
          if (std::find(vector.begin(), vector.end(), style) != vector.end() )
          {
            QString textoutput=current->textHtml();
            subject_->cursorDeleteCell();
            subject_->cursorStepDown();
            subject_->executeCommand(new CreateNewCellCommand(style));
            subject_->getCursor()->currentCell()->setTextHtml(textoutput);
          }
        }
      }
    }
    else
    {
      qDebug()<<"last cell";
    }
  }
  else
  {
      QMessageBox::warning( 0, tr("Warning"), tr("This functionality does not work on selected cells. Click on the cell to move down, and press this action"), "OK" );
  }
}

void NotebookWindow::evalall()
{
    if (subject_->isEmpty()==false) {
        Cell* current=subject_->getMainCell()->child();
        QVector<Cell*> cellcount=SearchCells(current);

        for (int i =0;i<cellcount.size();i++) {
            if(GraphCell *g = dynamic_cast<GraphCell*>(cellcount[i])) {
                g->eval();
            }
            if(InputCell *g = dynamic_cast<InputCell*>(cellcount[i])) {
                g->eval();
            }
        }
    } else {
        qDebug()<<"The Document is Empty";
    }
}

void NotebookWindow::evalallLatex()
{
    if (subject_->isEmpty()==false) {
        Cell* current=subject_->getMainCell()->child();
        QVector<Cell*> cellcount=SearchCells(current);

        for (int i =0;i<cellcount.size();i++) {
            if(LatexCell *g = dynamic_cast<LatexCell*>(cellcount[i])) {
                g->eval(true);
            }
        }
    } else {
        qDebug()<<"The Document is Empty";
    }
}

}
