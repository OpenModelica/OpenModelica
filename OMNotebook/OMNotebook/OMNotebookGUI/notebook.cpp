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

#define QT_NO_DEBUG_OUTPUT


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
#include <array>

//QT Headers
#include <QtGlobal>
#include <QtWidgets>

//IAEX Headers
#include "command.h"
#include "cellcommands.h"
#include "celldocument.h"
#include "cursorcommands.h"
#include "imagesizedlg.h"
#include "notebook.h"
#include "notebookcommands.h"
#include "cursorposvisitor.h"
#include "otherdlg.h"
#include "stylesheet.h"
#include "searchform.h"
#include "xmlparser.h"
#include "removehighlightervisitor.h"
#include "omcinteractiveenvironment.h"

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

namespace
{
  constexpr int MaxRecentFiles = 8;
  const QString RecentFilesKey = QStringLiteral("RecentFiles");

  QSettings recentFilesSettings()
  {
    return QSettings(QSettings::IniFormat, QSettings::UserScope, "openmodelica", "omnotebook");
  }

  /*!
   * \brief Reads the list of recently used files, newest first.
   *
   * Older versions stored one entry per key ("Recent" + QChar(i), i.e. a control
   * character in the key). If the new key does not exist yet, those entries are
   * migrated once.
   */
  QStringList readRecentFiles()
  {
    QSettings s = recentFilesSettings();
    if(s.contains(RecentFilesKey))
      return s.value(RecentFilesKey).toStringList();

    QStringList list;
    for(int i = 0; i < MaxRecentFiles; ++i)
    {
      const QString key = QStringLiteral("Recent") + QString(QChar(i));
      const QString value = s.value(key).toString();
      if(value.isEmpty())
        break;
      list << value;
    }
    if(!list.isEmpty())
    {
      s.setValue(RecentFilesKey, list);
      for(int i = 0; i < MaxRecentFiles; ++i)
        s.remove(QStringLiteral("Recent") + QString(QChar(i)));
    }
    return list;
  }

  void writeRecentFiles(const QStringList &list)
  {
    QSettings s = recentFilesSettings();
    s.setValue(RecentFilesKey, list);
  }
}


/*!
  * \author Ingemar Axelsson and Anders Fernström
  * \date 2006-01-17 (update)
  *
  * \brief The class constructor
  *
  * 2006-01-16 AF, Added an icon to the window
  * Also made som other updates /AF
  */
NotebookWindow::NotebookWindow(std::unique_ptr<Document> subject,
                               const QString filename, int isDrModelica, QWidget *parent)
  : DocumentView(parent),
    app_( subject->application() ),
    subject_(std::move(subject)),
    filename_(filename),
    findForm_( 0 ),
    closing_(false)
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
  createViewMenu();
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

  // Delete the window (with its document and cells) when it is closed. Without this a closed
  // window only gets hidden: ~NotebookWindow() never runs, the window stays in the application's
  // list and in the Window menu, and the document, the cells and the plots are never freed.
  setAttribute(Qt::WA_DeleteOnClose);

  statusBar()->showMessage(tr("Ready"));
  resize(800, 600);

  connect( subject_->getCursor(), SIGNAL( changedPosition() ),
           this, SLOT( updateMenus() ));
  connect( subject_.get(), SIGNAL( contentChanged() ),
           this, SLOT( updateWindowTitle() ));
  connect( subject_.get(), SIGNAL( hoverOverFile(QString) ),
           this, SLOT( setStatusMessage(QString) ));
  // 2006-04-27 AF
  connect( subject_.get(), SIGNAL( forwardAction(int) ),
           this, SLOT( forwardedAction(int) ));

  connect( subject_.get(), SIGNAL(updatePos(int, int)), this, SLOT(setPosition(int, int)));

  connect( subject_.get(), SIGNAL(newState(QString)), this, SLOT(setState(QString)));

  connect( subject_.get(), SIGNAL(setStatusMenu(QList<QAction*>)), this, SLOT(setStatusMenu(QList<QAction*>)));

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
  /**find  and inserts all the present cells in document in a std::vector**/
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
  //2006-01-27 AF, remove document view from application list
  application()->removeDocumentView( this );

  qApp->removeEventFilter( this );

  //2006-01-05 AF, add all inputcell to removelist on highlighter
  RemoveHighlighterVisitor visitor;
  subject_->runVisitor( visitor );

  subject_->detach(this);
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
  * \brief Return the notebook windows document
  */
Document* NotebookWindow::document()
{
  return subject_.get();
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
  auto newAction = new QAction( tr("&New"), this );
  newAction->setShortcut( QKeySequence("Ctrl+N") );
  newAction->setStatusTip( tr("Create a new document") );
  connect(newAction, SIGNAL(triggered()), this, SLOT(newFile()));
  newAction->setIcon(QIcon(":/Resources/toolbarIcons/filenew.png"));

  toolBar->addAction(newAction);

  recentMenu_ = new QMenu(tr("Recent &Files"), this);

  // OPEN FILE
  auto openFileAction = new QAction( tr("&Open"), this );
  openFileAction->setShortcut( QKeySequence("Ctrl+O") );
  openFileAction->setStatusTip( tr("Open a file") );
  connect(openFileAction, SIGNAL(triggered()), this, SLOT(openFile()));
  openFileAction->setIcon(QIcon(":/Resources/toolbarIcons/fileopen.png"));

  QToolButton *b = new QToolButton(this);
  b->setDefaultAction(openFileAction);
  b->setMenu(recentMenu_);
  b->setPopupMode(QToolButton::MenuButtonPopup);
  //    toolBar->addAction(openFileAction);
  toolBar->addWidget(b);

  // SAVE AS
  auto saveAsAction = new QAction( tr("Save &As..."), this );
  saveAsAction->setShortcut( QKeySequence("Ctrl+Shift+S") );
  saveAsAction->setStatusTip( tr("Save the document as a new file") );
  connect(saveAsAction, SIGNAL(triggered()), this, SLOT(saveas()));

  // SAVE
  auto saveAction = new QAction( tr("&Save"), this );
  saveAction->setShortcut( QKeySequence("Ctrl+S") );
  saveAction->setStatusTip( tr("Save the document") );
  connect(saveAction, SIGNAL(triggered()), this, SLOT(save()));
  saveAction->setIcon(QIcon(":/Resources/toolbarIcons/filesave.png"));
  toolBar->addAction(saveAction);

  toolBar->addSeparator();

  // CLOSE FILE
  auto closeFileAction = new QAction( tr("&Close"), this );
  closeFileAction->setShortcut( QKeySequence("Ctrl+W") );
  closeFileAction->setStatusTip( tr("Close the window") );
  connect(closeFileAction, SIGNAL(triggered()), this, SLOT(closeFile()));

  // PRINT
  auto printAction = new QAction( tr("&Print"), this );
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
  auto fileMenu = menuBar()->addMenu( tr("&File") );
  fileMenu->addAction( newAction );
  fileMenu->addAction( openFileAction );
  fileMenu->addAction( saveAction );
  fileMenu->addAction( saveAsAction );
  fileMenu->addAction( closeFileAction );
  fileMenu->addSeparator();
  fileMenu->addAction( printAction );
  fileMenu->addSeparator();

  // RECENT FILES
  fileMenu->addMenu(recentMenu_);

  // The list is shared between all windows (and instances) through QSettings,
  // so rebuild it whenever one of the menus is about to be shown. The toolbar
  // button shows recentMenu_ without opening the file menu.
  connect(fileMenu, &QMenu::aboutToShow, this, &NotebookWindow::rebuildRecentMenu);
  connect(recentMenu_, &QMenu::aboutToShow, this, &NotebookWindow::rebuildRecentMenu);
  rebuildRecentMenu();

  fileMenu->addSeparator();

  auto importMenu = fileMenu->addMenu( tr("&Import") );
  auto exportMenu = fileMenu->addMenu( tr("E&xport") );
  fileMenu->addSeparator();
  fileMenu->addAction( quitWindowAction );


  // IMPORT MENU
  // Added 2005-12-01
  auto importOldFile = new QAction( tr("&Old OMNotebook file"), this );
  importOldFile->setStatusTip( tr("Import an old OMNotebook file") );
  connect( importOldFile, SIGNAL( triggered() ),
           this, SLOT( openOldFile() ));

  importMenu->addAction( importOldFile );


  // EXPORT MENU
  // Added 2005-11-21
  auto exportPureText = new QAction( tr("&Pure text"), this );
  exportPureText->setStatusTip( tr("Export the document content to pure text") );
  connect( exportPureText, SIGNAL( triggered() ),
           this, SLOT( pureText() ));

  exportMenu->addAction( exportPureText );

  // PDF
  auto pdfAction = new QAction( tr("P&DF"), this );
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

  // CUT/COPY/PASTE. On wasm the menu/toolbar entries and shortcuts are omitted
  // (the programmatic QClipboard path doesn't work there; the cell widgets handle
  // Ctrl+C/X/V directly). The QActions are still created so the enable/disable
  // wiring stays valid.
  // CUT
  cutAction = new QAction( tr("Cu&t"), this);
  cutAction->setStatusTip( tr("Cut selected text") );
  connect( cutAction, SIGNAL( triggered() ),
           this, SLOT( cutEdit() ));

  cutAction->setEnabled(false);
  cutAction->setIcon(QIcon(":/Resources/toolbarIcons/editcut.png"));

  // COPY
  copyAction = new QAction( tr("&Copy"), this);
  copyAction->setStatusTip( tr("Copy selected text") );
  connect( copyAction, SIGNAL( triggered() ),
           this, SLOT( copyEdit() ));

  copyAction->setEnabled(false);
  copyAction->setIcon(QIcon(":/Resources/toolbarIcons/editcopy.png"));

  // PASTE
  pasteAction = new QAction( tr("&Paste"), this);
  pasteAction->setStatusTip( tr("Paste text from clipboard") );
  connect( pasteAction, SIGNAL( triggered() ),
           this, SLOT( pasteEdit() ));

  pasteAction->setIcon(QIcon(":/Resources/toolbarIcons/editpaste.png"));

#ifndef __EMSCRIPTEN__
  cutAction->setShortcut( QKeySequence("Ctrl+X") );
  copyAction->setShortcut( QKeySequence("Ctrl+C") );
  pasteAction->setShortcut( QKeySequence("Ctrl+V") );
  toolBar->addAction(cutAction);
  toolBar->addAction(copyAction);
  toolBar->addAction(pasteAction);
  toolBar->addSeparator();
#endif


  // FIND
  auto findAction = new QAction( tr("&Find"), this);
  findAction->setShortcut( QKeySequence("Ctrl+F") );
  findAction->setStatusTip( tr("Search through the document") );
  connect( findAction, SIGNAL( triggered() ),
           this, SLOT( findEdit() ));

  findAction->setIcon(QIcon(":/Resources/toolbarIcons/find.png"));
  toolBar->addAction(findAction);
  toolBar->addSeparator();

  // REPLACE, added 2006-08-24 AF
  auto replaceAction = new QAction( tr("Re&place"), this);
  replaceAction->setShortcut( QKeySequence("Ctrl+H") );
  replaceAction->setStatusTip( tr("Search through the document and replace") );
  connect( replaceAction, SIGNAL( triggered() ),
           this, SLOT( replaceEdit() ));


  showExprAction = new QAction( tr("&View Raw Text"), this);
  showExprAction->setStatusTip( tr("View the raw text in the cell") );
  showExprAction->setCheckable(true);
  showExprAction->setChecked(false);
  connect(showExprAction, SIGNAL(toggled(bool)), subject_.get(), SLOT(showHTML(bool)));


#if USE_OMSKETCH
  //Edit Sketch image,and view the attributes added by jhansi
  auto editSketchImage = new QAction( tr("&EditSketchImage"), this );
  editSketchImage->setShortcut( QKeySequence("Ctrl+E") );
  editSketchImage->setStatusTip( tr("Sketch Image Edit") );
  connect( editSketchImage, SIGNAL( triggered() ),
           this, SLOT( sketchImageEdit() ));
  editSketchImage->setIcon(QIcon(":/Resources/toolbarIcons/editimage.png"));
  toolBar->addAction(editSketchImage);
  toolBar->addSeparator();
#endif

  auto editMenu = menuBar()->addMenu( tr("&Edit") );
  editMenu->addAction( undoAction );
  editMenu->addAction( redoAction );
#ifndef __EMSCRIPTEN__
  // Omitted on wasm; see the cut/copy/paste action setup above.
  editMenu->addSeparator();
  editMenu->addAction( cutAction );
  editMenu->addAction( copyAction );
  editMenu->addAction( pasteAction );
#endif
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
  auto addCellAction = new QAction( tr("&Add Cell (previous cell style)"), this);
  addCellAction->setShortcut( QKeySequence("Alt+Enter") );
  addCellAction->setStatusTip( tr("Add a new textcell with the previuos cells style") );
  connect(addCellAction, SIGNAL(triggered()), this, SLOT(createNewCell()));

  auto inputAction = new QAction( tr("Add &Input Cell"), this);
  inputAction->setShortcut( QKeySequence("Ctrl+Shift+I") );
  inputAction->setStatusTip( tr("Add an input cell") );
  connect(inputAction, SIGNAL(triggered()), this, SLOT(inputCellsAction()));

  auto latexAction = new QAction( tr("Add &LaTeX Cell"), this);
  latexAction->setShortcut( QKeySequence("Ctrl+Shift+E") );
  latexAction->setStatusTip( tr("Add Latex cell") );
  connect(latexAction, SIGNAL(triggered()), this, SLOT(latexCellsAction()));

  auto textAction = new QAction( tr("Add &Text Cell"), this);
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

  auto nextCellAction = new QAction( tr("&Next Cell"), this);
  nextCellAction->setStatusTip( tr("Move to next cell") );
  nextCellAction->setShortcut( QKeySequence("Alt+Down") );
  connect(nextCellAction, SIGNAL(triggered()), this, SLOT(moveCursorDown()));

  auto previousCellAction = new QAction( tr("P&revious Cell"), this);
  previousCellAction->setShortcut( QKeySequence("Alt+Up") );
  previousCellAction->setStatusTip( tr("Move to previous cell") );
  connect(previousCellAction, SIGNAL(triggered()), this, SLOT(moveCursorUp()));

  auto evalCellAction = new QAction(tr("&Evaluate Cell"), this);
  evalCellAction->setShortcut( QKeySequence("Shift+Enter") );
  evalCellAction->setStatusTip(tr("Evaluate the selected cell"));
  connect(evalCellAction, SIGNAL(triggered()), this, SLOT(eval()));

  auto evalAllCellsAction = new QAction(tr("Evaluate all Input&cells"), this);
  evalAllCellsAction->setStatusTip(tr("Evaluate all Input cells in the document"));
  evalAllCellsAction->setShortcut( QKeySequence("Ctrl+R") );
  connect(evalAllCellsAction, SIGNAL(triggered()), this, SLOT(evalall()));

  auto evalAllLatexCellsAction = new QAction(tr("Evaluate all Late&xcells"), this);
  evalAllLatexCellsAction->setStatusTip(tr("Evaluate all Latex cells in the document"));
  evalAllLatexCellsAction->setShortcut( QKeySequence("Ctrl+Shift+R") );
  connect(evalAllLatexCellsAction, SIGNAL(triggered()), this, SLOT(evalallLatex()));

  // 2006-04-27 AF, remove cut,copy,paste cell from menu
  auto cellMenu = menuBar()->addMenu( tr("&Cell") );
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
  auto stylesgroup = new QActionGroup( this );
  formatMenu = menuBar()->addMenu( tr("&Format") );
  styleMenu = formatMenu->addMenu( tr("&Styles") );

  std::vector<QString> styles = sheet->getAvailableStyleNames();
  std::vector<QString>::iterator i = styles.begin();
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
  auto fontsgroup = new QActionGroup( this );
  fontMenu = formatMenu->addMenu( tr("&Font") );

  QStringList fonts = QFontDatabase::families( QFontDatabase::Latin );

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

  auto facePlain = new QAction( tr("&Plain"), this);
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
  auto sizesgroup = new QActionGroup( this );

  auto sizeSmaller = new QAction( tr("&Smaller"), this);
  sizeSmaller->setWhatsThis("Smaller");
  sizeSmaller->setShortcut( QKeySequence("Ctrl+-") );
  sizeSmaller->setCheckable( false );
  sizeSmaller->setStatusTip( tr("Set font size smaller") );

  auto sizeLarger = new QAction( tr("&Larger"), this);
  sizeLarger->setWhatsThis("Larger");
  sizeLarger->setShortcut( QKeySequence("Ctrl++") );
  sizeLarger->setCheckable( false );
  sizeLarger->setStatusTip( tr("Set font size larger") );

  auto size8pt = new QAction( "8", this);
  size8pt->setCheckable( true );
  sizes_.insert( "8", size8pt );
  sizesgroup->addAction( size8pt );

  auto size9pt = new QAction( "9", this);
  size9pt->setCheckable( true );
  sizes_.insert( "9", size9pt );
  sizesgroup->addAction( size9pt );

  auto size10pt = new QAction( "10", this);
  size10pt->setCheckable( true );
  sizes_.insert( "10", size10pt );
  sizesgroup->addAction( size10pt );

  auto size12pt = new QAction( "12", this);
  size12pt->setCheckable( true );
  sizes_.insert( "12", size12pt );
  sizesgroup->addAction( size12pt );

  auto size14pt = new QAction( "14", this);
  size14pt->setCheckable( true );
  sizes_.insert( "14", size14pt );
  sizesgroup->addAction( size14pt );

  auto size16pt = new QAction( "16", this);
  size16pt->setCheckable( true );
  sizes_.insert( "16", size16pt );
  sizesgroup->addAction( size16pt );

  auto size18pt = new QAction( "18", this);
  size18pt->setCheckable( true );
  sizes_.insert( "18", size18pt );
  sizesgroup->addAction( size18pt );

  auto size20pt = new QAction( "20", this);
  size20pt->setCheckable( true );
  sizes_.insert( "20", size20pt );
  sizesgroup->addAction( size20pt );

  auto size24pt = new QAction( "24", this);
  size24pt->setCheckable( true );
  sizes_.insert( "24", size24pt );
  sizesgroup->addAction( size24pt );

  auto size36pt = new QAction( "36", this);
  size36pt->setCheckable( true );
  sizes_.insert( "36", size36pt );
  sizesgroup->addAction( size36pt );

  auto size72pt = new QAction( "72", this);
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
  auto stretchsgroup = new QActionGroup( this );

  auto stretchUltraCondensed = new QAction( tr("U&ltra Condensed"), this);
  stretchUltraCondensed->setCheckable( true );
  stretchUltraCondensed->setWhatsThis("ucon");
  stretchUltraCondensed->setStatusTip( tr("Set font stretch to Ultra Condensed") );
  stretchs_.insert( QFont::UltraCondensed, stretchUltraCondensed );
  stretchsgroup->addAction( stretchUltraCondensed );

  auto stretchExtraCondensed = new QAction( tr("E&xtra Condensed"), this);
  stretchExtraCondensed->setCheckable( true );
  stretchExtraCondensed->setWhatsThis("econ");
  stretchExtraCondensed->setStatusTip( tr("Set font stretch to Extra Condensed") );
  stretchs_.insert( QFont::ExtraCondensed, stretchExtraCondensed );
  stretchsgroup->addAction( stretchExtraCondensed );

  auto stretchCondensed = new QAction( tr("&Condensed"), this);
  stretchCondensed->setCheckable( true );
  stretchCondensed->setWhatsThis("con");
  stretchCondensed->setStatusTip( tr("Set font stretch to Condensed") );
  stretchs_.insert( QFont::Condensed, stretchCondensed );
  stretchsgroup->addAction( stretchCondensed );

  auto stretchSemiCondensed = new QAction( tr("S&emi Condensed"), this);
  stretchSemiCondensed->setCheckable( true );
  stretchSemiCondensed->setWhatsThis("scon");
  stretchSemiCondensed->setStatusTip( tr("Set font stretch to Semi Condensed") );
  stretchs_.insert( QFont::SemiCondensed, stretchSemiCondensed );
  stretchsgroup->addAction( stretchSemiCondensed );

  auto stretchUnstretched = new QAction( tr("&Unstretched"), this);
  stretchUnstretched->setCheckable( true );
  stretchUnstretched->setWhatsThis("uns");
  stretchUnstretched->setStatusTip( tr("Set font stretch to Unstretched") );
  stretchs_.insert( QFont::Unstretched, stretchUnstretched );
  stretchsgroup->addAction( stretchUnstretched );

  auto stretchSemiExpanded = new QAction( tr("&Semi Expanded"), this);
  stretchSemiExpanded->setCheckable( true );
  stretchSemiExpanded->setWhatsThis("sexp");
  stretchSemiExpanded->setStatusTip( tr("Set font stretch to Semi Expanded") );
  stretchs_.insert( QFont::SemiExpanded, stretchSemiExpanded );
  stretchsgroup->addAction( stretchSemiExpanded );

  auto stretchExpanded = new QAction( tr("&Expanded"), this);
  stretchExpanded->setCheckable( true );
  stretchExpanded->setWhatsThis("exp");
  stretchExpanded->setStatusTip( tr("Set font stretch to Expanded") );
  stretchs_.insert( QFont::Expanded, stretchExpanded );
  stretchsgroup->addAction( stretchExpanded );

  auto stretchExtraExpanded = new QAction( tr("Ex&tra Expanded"), this);
  stretchExtraExpanded->setCheckable( true );
  stretchExtraExpanded->setWhatsThis("eexp");
  stretchExtraExpanded->setStatusTip( tr("Set font stretch to Extra Expanded") );
  stretchs_.insert( QFont::ExtraExpanded, stretchExtraExpanded );
  stretchsgroup->addAction( stretchExtraExpanded );

  auto stretchUltraExpanded = new QAction( tr("Ult&ra Expanded"), this);
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
  auto colorsgroup = new QActionGroup( this );

  auto colorBlack = new QAction( tr("Blac&k"), this);
  colorBlack->setCheckable( true );
  colorBlack->setStatusTip( tr("Set font color to Black") );
  colors_.insert( colorBlack, QColor(0,0,0) );
  colorsgroup->addAction( colorBlack );

  auto colorWhite = new QAction( tr("&White"), this);
  colorWhite->setCheckable( true );
  colorWhite->setStatusTip( tr("Set font color to White") );
  colors_.insert( colorWhite, QColor(255,255,255) );
  colorsgroup->addAction( colorWhite );

  auto color10Gray = new QAction( tr("&10% Gray"), this);
  color10Gray->setCheckable( true );
  color10Gray->setStatusTip( tr("Set font color to 10% Gray") );
  colors_.insert( color10Gray, QColor(25,25,25) );
  colorsgroup->addAction( color10Gray );

  auto color33Gray = new QAction( tr("&33% Gray"), this);
  color33Gray->setCheckable( true );
  color33Gray->setStatusTip( tr("Set font color to 33% Gray") );
  colors_.insert( color33Gray, QColor(85,85,85) );
  colorsgroup->addAction( color33Gray );

  auto color50Gray = new QAction( tr("&50% Gray"), this);
  color50Gray->setCheckable( true );
  color50Gray->setStatusTip( tr("Set font color to 50% Gray") );
  colors_.insert( color50Gray, QColor(128,128,128) );
  colorsgroup->addAction( color50Gray );

  auto color66Gray = new QAction( tr("&66% Gray"), this);
  color66Gray->setCheckable( true );
  color66Gray->setStatusTip( tr("Set font color to 66% Gray") );
  colors_.insert( color66Gray, QColor(170,170,170) );
  colorsgroup->addAction( color66Gray );

  auto color90Gray = new QAction( tr("&90% Gray"), this);
  color90Gray->setCheckable( true );
  color90Gray->setStatusTip( tr("Set font color to 90% Gray") );
  colors_.insert( color90Gray, QColor(230,230,230) );
  colorsgroup->addAction( color90Gray );

  auto colorRed = new QAction( tr("&Red"), this);
  colorRed->setCheckable( true );
  colorRed->setStatusTip( tr("Set font color to Red") );
  colors_.insert( colorRed, QColor(255,0,0) );
  colorsgroup->addAction( colorRed );

  auto colorGreen = new QAction( tr("&Green"), this);
  colorGreen->setCheckable( true );
  colorGreen->setStatusTip( tr("Set font color to Green") );
  colors_.insert( colorGreen, QColor(0,255,0) );
  colorsgroup->addAction( colorGreen );

  auto colorBlue = new QAction( tr("&Blue"), this);
  colorBlue->setCheckable( true );
  colorBlue->setStatusTip( tr("Set font color to Blue") );
  colors_.insert( colorBlue, QColor(0,0,255) );
  colorsgroup->addAction( colorBlue );

  auto colorCyan = new QAction( tr("&Cyan"), this);
  colorCyan->setCheckable( true );
  colorCyan->setStatusTip( tr("Set font color to Cyan") );
  colors_.insert( colorCyan, QColor(0,255,255) );
  colorsgroup->addAction( colorCyan );

  auto colorMagenta = new QAction( tr("&Magenta"), this);
  colorMagenta->setCheckable( true );
  colorMagenta->setStatusTip( tr("Set font color to Magenta") );
  colors_.insert( colorMagenta, QColor(255,0,255) );
  colorsgroup->addAction( colorMagenta );

  auto colorYellow = new QAction( tr("&Yellow"), this);
  colorYellow->setCheckable( true );
  colorYellow->setStatusTip( tr("Set font color to Yellow") );
  colors_.insert( colorYellow, QColor(255,255,0) );
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
  auto alignmentsgroup = new QActionGroup( this );
  verticalAlignmentMenu = formatMenu->addMenu( tr("&Vertical Alignment") );
  auto verticalAlignmentsgroup = new QActionGroup( this );

  auto alignmentLeft = new QAction( tr("&Left"), this);
  alignmentLeft->setCheckable( true );
  alignmentLeft->setStatusTip( tr("Set text alignment to Left") );
  alignments_.insert( Qt::AlignLeft, alignmentLeft );
  alignmentsgroup->addAction( alignmentLeft );

  auto alignmentRight = new QAction( tr("&Right"), this);
  alignmentRight->setCheckable( true );
  alignmentRight->setStatusTip( tr("Set text alignment to Right") );
  alignments_.insert( Qt::AlignRight, alignmentRight );
  alignmentsgroup->addAction( alignmentRight );

  auto alignmentCenter = new QAction( tr("&Center"), this);
  alignmentCenter->setCheckable( true );
  alignmentCenter->setStatusTip( tr("Set text alignment to Center") );
  alignments_.insert( Qt::AlignHCenter, alignmentCenter );
  alignmentsgroup->addAction( alignmentCenter );

  auto alignmentJustify = new QAction( tr("&Justify"), this);
  alignmentJustify->setCheckable( true );
  alignmentJustify->setStatusTip( tr("Set text alignment to Justify") );
  alignments_.insert( Qt::AlignJustify, alignmentJustify );
  alignmentsgroup->addAction( alignmentJustify );

  auto verticalNormal = new QAction( tr("&Normal/Baseline"), this);
  verticalNormal->setCheckable( true );
  verticalNormal->setStatusTip( tr("Set vertical text alignment to Normal") );
  verticals_.insert( QTextCharFormat::AlignNormal, verticalNormal );
  verticalAlignmentsgroup->addAction( verticalNormal );

  auto verticalSub = new QAction( tr("&Subscript"), this);
  verticalSub->setCheckable( true );
  verticalSub->setStatusTip( tr("Set vertical text alignment to Subscript") );
  verticals_.insert( QTextCharFormat::AlignSubScript, verticalSub );
  verticalAlignmentsgroup->addAction( verticalSub );

  auto verticalSuper = new QAction( tr("S&uperscript"), this);
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
  auto bordersgroup = new QActionGroup( this );

  auto borderSizes = std::array{ 0,1,2,3,4,5,6,7,8,9,10 };
  for (auto sz: borderSizes)
  {
    QString name;
    name.setNum( sz );
    QAction *tmp = new QAction( name, this );
    tmp->setCheckable( true );
    borders_.insert( sz, tmp );
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
  auto marginsgroup = new QActionGroup( this );

  auto marginSizes = std::array{ 0,1,2,3,4,5,6,7,8,9,10,15,20,25,30 };
  for (auto sz: marginSizes)
  {
    QString name;
    name.setNum( sz );
    QAction *tmp = new QAction( name, this );
    tmp->setCheckable( true );
    margins_.insert( sz, tmp );
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
  auto paddingsgroup = new QActionGroup( this );

  auto paddingSizes = std::array{ 0,2,4,6,8,10,15 };
  for (auto sz: paddingSizes)
  {
    QString name;
    name.setNum( sz );
    QAction *tmp = new QAction( name, this );
    tmp->setCheckable( true );
    paddings_.insert( sz, tmp );
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

  // WEB LINK
  insertWebLinkAction = new QAction( tr("&Web link..."), this );
  insertWebLinkAction->setShortcut( QKeySequence("Ctrl+Shift+K") );
  insertWebLinkAction->setStatusTip( tr("Insert or change a link to a web page (http/https)") );
  connect( insertWebLinkAction, SIGNAL( triggered() ),
           this, SLOT( insertWebLink() ));

  toolBar->addSeparator();

#if USE_OMSKETCH
  //Sketch
  auto insertSketch = new QAction( tr("&Sketch"), this );
  insertSketch->setStatusTip( tr("Sketch App") );
  connect( insertSketch, SIGNAL( triggered() ),
           this, SLOT( Sketch() ));
  insertSketch->setIcon(QIcon(":/Resources/toolbarIcons/sketch.png"));
  toolBar->addAction(insertSketch);
  toolBar->addSeparator();
#endif

  //INDENT
  auto indentAction = new QAction(tr("Indent"), this);
  indentAction->setStatusTip(tr("Indent the code in the selected cell"));
  indentAction->setIcon(QIcon(":/Resources/toolbarIcons/text_right.png"));
  connect(indentAction, SIGNAL(triggered()), this, SLOT(indent()));


  QToolButton * b = new QToolButton;
  b->setDefaultAction(indentAction);
  auto indentMenu = new QMenu(this);
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
  auto evalAction = new QAction(tr("Evaluate"), this);
  evalAction->setStatusTip(tr("Evaluate the selected cell"));
  evalAction->setIcon(QIcon(":/Resources/toolbarIcons/apply.png"));
  connect(evalAction, SIGNAL(triggered()), this, SLOT(eval()));
  toolBar->addAction(evalAction);

  auto evalallAction = new QAction(tr("Evaluate all cells"), this);
  evalallAction->setStatusTip(tr("Evaluate all cells in the document"));
  evalallAction->setIcon(QIcon(":/Resources/toolbarIcons/evalall.png"));
//  evalallAction->setShortcut( QKeySequence("Ctrl+R") );
  connect(evalallAction, SIGNAL(triggered()), this, SLOT(evalall()));
  toolBar->addAction(evalallAction);

  auto shiftcellsupAction = new QAction(tr("Move cells up"), this);
  shiftcellsupAction->setStatusTip(tr("Move cells up, by clicking on the cell"));
  shiftcellsupAction->setIcon(QIcon(":/Resources/toolbarIcons/up.png"));
  connect(shiftcellsupAction, SIGNAL(triggered()), this, SLOT(shiftcellsUp()));
  toolBar->addAction(shiftcellsupAction);

  auto shiftcellsdownAction = new QAction(tr("Move cells down"), this);
  shiftcellsdownAction->setStatusTip(tr("Move cells down, by clicking on the cell"));
  shiftcellsdownAction->setIcon(QIcon(":/Resources/toolbarIcons/down.png"));
  connect(shiftcellsdownAction, SIGNAL(triggered()), this, SLOT(shiftcellsDown()));
  toolBar->addAction(shiftcellsdownAction);

  auto shiftselectedcellsAction = new QAction(tr("Move selected cells"), this);
  shiftselectedcellsAction->setStatusTip(tr("Put the cursor to a position where you want the cells to be moved, and then select the cells you would like to move that position"));
  shiftselectedcellsAction->setIcon(QIcon(":/Resources/toolbarIcons/updown.png"));
  connect(shiftselectedcellsAction, SIGNAL(triggered()), this, SLOT(shiftselectedcells()));
  toolBar->addAction(shiftselectedcellsAction);

  // MENU
  auto insertMenu = menuBar()->addMenu( tr("&Insert") );
  insertMenu->addAction( insertImageAction );
  insertMenu->addAction( insertLinkAction );
  insertMenu->addAction( insertWebLinkAction );

  connect( insertMenu, SIGNAL( aboutToShow() ),
           this, SLOT( updateMenus() ));
}

/*!
  * \author Anders Fernström
  * \date 2006-01-27
  *
  * \brief Method for creating window nemu.
  */
void NotebookWindow::createViewMenu()
{
  auto viewMenu = menuBar()->addMenu( tr("&View") );

  // Ctrl++ and Ctrl+- are already used by Format->Size (font size of the selection)
  zoomInAction = new QAction( tr("Zoom &In"), this );
  zoomInAction->setStatusTip( tr("Enlarge the displayed text of the cells (the notebook is not changed)") );
  connect( zoomInAction, SIGNAL( triggered() ), this, SLOT( zoomTextIn() ));
  viewMenu->addAction( zoomInAction );

  zoomOutAction = new QAction( tr("Zoom &Out"), this );
  zoomOutAction->setStatusTip( tr("Reduce the displayed text of the cells (the notebook is not changed)") );
  connect( zoomOutAction, SIGNAL( triggered() ), this, SLOT( zoomTextOut() ));
  viewMenu->addAction( zoomOutAction );

  zoomResetAction = new QAction( tr("&Reset Zoom"), this );
  zoomResetAction->setShortcut( QKeySequence("Ctrl+0") );
  zoomResetAction->setStatusTip( tr("Display the text of the cells in its original size") );
  connect( zoomResetAction, SIGNAL( triggered() ), this, SLOT( zoomTextReset() ));
  viewMenu->addAction( zoomResetAction );

  // the zoom is done by a paint device with scaled resolution
  zoomDevice_ = QImage( 1, 1, QImage::Format_ARGB32 );
  zoomResetAction->setEnabled( false );

  // Ctrl (macOS: Cmd) + mouse wheel zooms the texts, see eventFilter()
  qApp->installEventFilter( this );
}

namespace {
  const std::array zoomSteps = { 50, 60, 70, 80, 90, 100, 110, 125, 150, 175, 200, 250, 300, 400 };
}

void NotebookWindow::zoomTextIn()
{
  for( int step : zoomSteps )
  {
    if( step > textZoom_ )
    {
      setTextZoom( step );
      return;
    }
  }
}

void NotebookWindow::zoomTextOut()
{
  for( int i = zoomSteps.size() - 1; i >= 0; --i )
  {
    if( zoomSteps[i] < textZoom_ )
    {
      setTextZoom( zoomSteps[i] );
      return;
    }
  }
}

void NotebookWindow::zoomTextReset()
{
  setTextZoom( 100 );
}

/*!
  * \brief Sets the zoom of the cell texts in percent.
  *
  * Only the display is scaled, the notebook content (font sizes in the
  * cells, the saved .onb file) and the size of the GUI are not changed.
  * All text, also text with a fixed font size from the cell style, is scaled
  * by giving the text layout a paint device with a scaled resolution.
  * (QTextEdit::zoomIn() doesn't work here, it ignores fixed font sizes.)
  */
void NotebookWindow::setTextZoom( int percent )
{
  if( percent == textZoom_ )
    return;

  // remember which part of the document has to stay in place
  captureZoomAnchor();

  // The cells change their height. Don't let the document scroll the active
  // cell into view meanwhile, the zoom scrolls to the remembered place itself.
  subject_->blockScrollUpdates( true );

  textZoom_ = percent;

  const double dpi = logicalDpiY() * percent / 100.0;
  const int dotsPerMeter = qRound( dpi / 0.0254 );
  zoomDevice_.setDotsPerMeterX( dotsPerMeter );
  zoomDevice_.setDotsPerMeterY( dotsPerMeter );

  zoomResetAction->setEnabled( percent != 100 );
  statusBar()->showMessage( tr("Zoom: %1%").arg( percent ), 3000 );

  // cells that are created later (open file, new cell) are zoomed in eventFilter()
  applyTextZoom();

  // The cells have new heights now. Scroll so that the remembered point of the
  // document is at the same place as before. The layouts that run later in the
  // event loop can change positions again, so repeat it afterwards.
  restoreZoomAnchor();
  QTimer::singleShot( 0, this, [this]() { restoreZoomAnchor(); });
  QTimer::singleShot( 50, this, [this]() { restoreZoomAnchor(); });

  // height changes can still be reported a little later (layouts, queued updates)
  QTimer::singleShot( 150, this, [this]() { subject_->blockScrollUpdates( false ); });
}

namespace {
  /*!
    * \brief Calculates the vertical position of a cell in the document from the
    * heights of the cells before it, like CursorPosVisitor does.
    *
    * The positions of the cell widgets can't be used right after the cells got
    * new heights: the layouts of the (nested) cell groups are not finished yet.
    * The heights of the cells are up to date immediately.
    * Cells in closed groups are not visible and not counted.
    */
  class CellTopVisitor : public Visitor
  {
  public:
    explicit CellTopVisitor( QWidget *target ) : target_( target ) {}
    bool found() const { return found_; }
    int top() const { return top_; }

    void visitCellNodeBefore( Cell * ) override {}
    void visitCellNodeAfter( Cell * ) override {}

    void visitCellGroupNodeBefore( CellGroup *node ) override
    {
      check( node );
      if( !closedGroup_ && node->isClosed() )
        closedGroup_ = node;
    }
    void visitCellGroupNodeAfter( CellGroup *node ) override
    {
      if( closedGroup_ == node )
      {
        position_ += node->height();
        closedGroup_ = nullptr;
      }
    }

    void visitTextCellNodeBefore( TextCell *node ) override { check( node ); }
    void visitTextCellNodeAfter( TextCell *node ) override { add( node ); }
    void visitGraphCellNodeBefore( GraphCell *node ) override { check( node ); }
    void visitGraphCellNodeAfter( GraphCell *node ) override { add( node ); }
    void visitLatexCellNodeBefore( LatexCell *node ) override { check( node ); }
    void visitLatexCellNodeAfter( LatexCell *node ) override { add( node ); }
    void visitInputCellNodeBefore( InputCell *node ) override { check( node ); }
    void visitInputCellNodeAfter( InputCell *node ) override { add( node ); }
    void visitCellCursorNodeBefore( CellCursor *node ) override { check( node ); }
    void visitCellCursorNodeAfter( CellCursor *node ) override { add( node ); }

  private:
    void check( QWidget *node )
    {
      if( node == target_ && !found_ && !closedGroup_ )
      {
        found_ = true;
        top_ = position_;
      }
    }
    void add( QWidget *node )
    {
      if( !closedGroup_ )
        position_ += node->height();
    }

    QWidget *target_;
    CellGroup *closedGroup_ = nullptr;
    bool found_ = false;
    int top_ = 0;
    int position_ = 0;
  };

  // Let the pending layout work run now: positions of widgets and the scroll
  // range are updated, also for nested cell groups.
  void settleLayouts()
  {
    for( int i = 0; i < 8; ++i )
      QCoreApplication::sendPostedEvents( nullptr, QEvent::LayoutRequest );
  }
}

/*!
  * \brief Remembers the point of the document that has to keep its place on
  * the screen when the zoom changes.
  *
  * Visible active cell: its top (the topmost visible part), except for wheel zoom
  * with the mouse over the active cell, there the point under the mouse.
  * No visible active cell: the point under the mouse (wheel zoom) or the middle
  * of the visible area (menu/keyboard zoom).
  */
void NotebookWindow::captureZoomAnchor()
{
  zoomAnchorCell_ = nullptr;

  // a previous zoom step can still be in progress (fast wheel)
  settleLayouts();

  QScrollArea *scroll = documentScrollArea();
  if( !scroll || !scroll->widget() )
    return;

  QWidget *viewport = scroll->viewport();
  QWidget *under = nullptr;
  int refY = 0;

  // The active cell, if it is (partly) visible. It must not get lost by the zoom.
  QWidget *visibleActive = nullptr;
  int activeRefY = 0;
  CellCursor *cursor = subject_->getCursor();
  Cell *active = cursor ? cursor->currentCell() : nullptr;
  if( active && scroll->widget()->isAncestorOf( active ) )
  {
    const int top = active->mapTo( viewport, QPoint( 0, 0 ) ).y();
    if( top + active->height() > 0 && top < viewport->height() )
    {
      visibleActive = active;
      activeRefY = qMax( top, 0 );   // the topmost visible part of the cell
    }
  }

  if( zoomByMouse_ && zoomMouseWidget_ )
  {
    // Wheel: the point under the mouse stays in place. Exception: the active
    // cell is visible, but the mouse is somewhere else. Then the active cell
    // stays in place, otherwise it would move away and may leave the window.
    const bool mouseOnActive = visibleActive &&
      ( zoomMouseWidget_ == visibleActive || visibleActive->isAncestorOf( zoomMouseWidget_ ) );

    if( visibleActive && !mouseOnActive )
    {
      under = visibleActive;
      refY = activeRefY;
    }
    else
    {
      under = zoomMouseWidget_;
      refY = viewport->mapFromGlobal( zoomMousePos_ ).y();
    }
  }
  else if( visibleActive )
  {
    // Menu/keyboard: the active cell stays in place
    under = visibleActive;
    refY = activeRefY;
  }
  else
  {
    // no (visible) active cell: keep the middle of the visible area
    refY = viewport->height() / 2;
    under = QApplication::widgetAt( viewport->mapToGlobal( QPoint( viewport->width() / 2, refY ) ) );
  }

  // the innermost cell at that point
  QWidget *cell = nullptr;
  for( QWidget *w = under; w; w = w->parentWidget() )
  {
    if( dynamic_cast<Cell*>( w ) )
    {
      cell = w;
      break;
    }
  }
  if( !cell || !( scroll->widget() == cell || scroll->widget()->isAncestorOf( cell ) ) )
    return;

  CellTopVisitor visitor( cell );
  subject_->runVisitor( visitor );
  if( !visitor.found() )
    return;

  const int cellTop = cell->mapTo( scroll->widget(), QPoint( 0, 0 ) ).y();
  const int contentY = scroll->verticalScrollBar()->value() + refY;

  zoomAnchorOffset_ = cellTop - visitor.top();
  zoomAnchorCell_ = cell;
  zoomAnchorFraction_ = qBound( 0.0, double( contentY - cellTop ) / qMax( 1, cell->height() ), 1.0 );
  zoomAnchorViewportY_ = refY;
}

/*!
  * \brief Scrolls the document so that the point remembered by
  * captureZoomAnchor() is at its old place on the screen.
  */
void NotebookWindow::restoreZoomAnchor()
{
  if( !zoomAnchorCell_ )
    return;

  QScrollArea *scroll = documentScrollArea();
  if( !scroll || !scroll->widget() )
    return;

  // Cell heights have just been changed. Let the (nested) layouts update the
  // scroll range now, not at the next event loop run.
  settleLayouts();

  // The position of the cell comes from the cell heights, not from the widget
  // position: that is still the old one, as long as the layouts of the cell
  // groups are not finished. The (constant) difference between both was
  // measured before the zoom.
  CellTopVisitor visitor( zoomAnchorCell_ );
  subject_->runVisitor( visitor );
  if( !visitor.found() )
    return;

  const int cellTop = visitor.top() + zoomAnchorOffset_;
  const int contentY = cellTop + qRound( zoomAnchorFraction_ * zoomAnchorCell_->height() );
  scroll->verticalScrollBar()->setValue( contentY - zoomAnchorViewportY_ );
}

/*!
  * \brief The scroll area that contains the cells.
  *
  * There can be more than one QScrollArea in the window: CellDocument::setWorkspace()
  * creates a new one each time and leaves the old (empty) one. findChild() would
  * return the wrong one.
  */
QScrollArea *NotebookWindow::documentScrollArea()
{
  CellCursor *cursor = subject_->getCursor();
  for( QWidget *w = cursor; w; w = w->parentWidget() )
  {
    if( QScrollArea *area = qobject_cast<QScrollArea*>( w ) )
      return area;
  }
  return nullptr;
}

namespace {
  // immediate: now (needed to scroll to the right place afterwards), otherwise in the event loop
  void requestCellHeightUpdate( QWidget *editor, bool immediate )
  {
    for( QWidget *w = editor->parentWidget(); w; w = w->parentWidget() )
    {
      if( Cell *cell = dynamic_cast<Cell*>( w ) )
      {
        bool success = QMetaObject::invokeMethod( cell, &Cell::contentChanged,
                                   immediate ? Qt::DirectConnection : Qt::QueuedConnection );
        Q_ASSERT(success);
        return;
      }
    }
  }
}

void NotebookWindow::applyTextZoom()
{
  const QList<QTextEdit*> editors = centralWidget()->findChildren<QTextEdit*>();
  for( QTextEdit *editor : editors )
    applyTextZoom( editor, true );

  // the code editor of a GraphCell is a QPlainTextEdit (not a QTextEdit)
  const QList<QPlainTextEdit*> codeEditors = centralWidget()->findChildren<QPlainTextEdit*>();
  for( QPlainTextEdit *editor : codeEditors )
    applyTextZoom( editor, true );
}

void NotebookWindow::applyTextZoom( QTextEdit *editor, bool immediate )
{
  QAbstractTextDocumentLayout *layout = editor->document()->documentLayout();
  if( !layout )
    return;

  if( textZoom_ == 100 )
    layout->setPaintDevice( editor->viewport() );
  else
    layout->setPaintDevice( &zoomDevice_ );

  editor->document()->markContentsDirty( 0, editor->document()->characterCount() );
  editor->viewport()->update();

  requestCellHeightUpdate( editor, immediate );
}

/*!
  * \brief Zoom for a QPlainTextEdit (code editor of the GraphCell).
  *
  * All text of such an editor uses the font of the widget, so the zoom scales
  * the widget font. The original size is remembered in a property of the
  * editor. Child widgets (the line number area) follow the font of the editor.
  */
void NotebookWindow::applyTextZoom( QPlainTextEdit *editor, bool immediate )
{
  static const char *baseSizeProperty = "omnotebookZoomBaseSize";

  QFont font = editor->font();
  const bool usePoints = font.pointSizeF() > 0;
  if( !editor->property( baseSizeProperty ).isValid() )
    editor->setProperty( baseSizeProperty,
                         usePoints ? font.pointSizeF() : static_cast<qreal>( font.pixelSize() ) );

  const qreal size = editor->property( baseSizeProperty ).toReal() * textZoom_ / 100.0;
  if( usePoints )
    font.setPointSizeF( size );
  else
    font.setPixelSize( qMax( 1, qRound( size ) ) );

  if( font == editor->font() )
    return;

  editor->setFont( font );
  editor->viewport()->update();

  requestCellHeightUpdate( editor, immediate );
}

/*!
  * \brief Applies the zoom to text editors that are shown after the zoom was set
  * (new cells, opened notebooks, opened cell groups).
  */
bool NotebookWindow::eventFilter( QObject *obj, QEvent *event )
{
  // Ctrl (macOS: Cmd, Qt reports it as ControlModifier) + mouse wheel changes the zoom
  if( event->type() == QEvent::Wheel )
  {
    QWheelEvent *wheel = static_cast<QWheelEvent*>( event );
    QWidget *widget = qobject_cast<QWidget*>( obj );
    if( widget && centralWidget() && ( wheel->modifiers() & Qt::ControlModifier ) &&
        wheel->angleDelta().y() != 0 &&
        ( widget == centralWidget() || centralWidget()->isAncestorOf( widget ) ) )
    {
      const int delta = wheel->angleDelta().y();
      if( zoomWheelDelta_ * delta < 0 )   // direction changed
        zoomWheelDelta_ = 0;
      zoomWheelDelta_ += delta;

      // the point under the mouse keeps its place while zooming
      zoomByMouse_ = true;
      zoomMousePos_ = wheel->globalPosition().toPoint();
      zoomMouseWidget_ = widget;

      // one step per notch (120), touchpads send many small values
      while( zoomWheelDelta_ >= 120 )
      {
        zoomTextIn();
        zoomWheelDelta_ -= 120;
      }
      while( zoomWheelDelta_ <= -120 )
      {
        zoomTextOut();
        zoomWheelDelta_ += 120;
      }

      zoomByMouse_ = false;
      zoomMouseWidget_ = nullptr;
      return true;
    }
  }

  if( event->type() == QEvent::Show && textZoom_ != 100 )
  {
    if( QTextEdit *editor = qobject_cast<QTextEdit*>( obj ) )
    {
      if( editor->window() == this &&
          editor->document()->documentLayout()->paintDevice() != &zoomDevice_ )
        applyTextZoom( editor );
    }
    else if( QPlainTextEdit *codeEditor = qobject_cast<QPlainTextEdit*>( obj ) )
    {
      if( codeEditor->window() == this )
        applyTextZoom( codeEditor );
    }
  }
  return DocumentView::eventFilter( obj, event );
}

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
  auto aboutAction = new QAction( tr("&About OMNotebook"), this );
  aboutAction->setStatusTip( tr("Display OMNotebook's About dialog") );
  aboutAction->setMenuRole(QAction::AboutRole);
  connect(aboutAction, SIGNAL(triggered()), this, SLOT(aboutQTNotebook()));

  // 2006-02-03 AF, Added a help action
  auto helpAction = new QAction( tr("&Help Text"), this );
  helpAction->setShortcut( QKeySequence("F1") );
  helpAction->setStatusTip( tr("Open help document") );
  connect( helpAction, SIGNAL( triggered() ),
           this, SLOT( helpText() ));

  // 2006-02-21 AF, Added a about qt action
  auto aboutQtAction = new QAction( tr("About &Qt"), this );
  aboutQtAction->setStatusTip( tr("Display information about Qt") );
  aboutQtAction->setMenuRole(QAction::AboutQtRole);
  connect( aboutQtAction, SIGNAL( triggered() ),
           this, SLOT( aboutQT() ));

#ifdef __EMSCRIPTEN__
  // Web build: the example notebooks are staged into MEMFS at startup (see
  // CellApplication). Expose each tree as a menu mirroring its directory layout.
  addExampleMenu("/DrModelica");
  addExampleMenu("/DrControl");
#endif

  // 2005-10-07 AF, Porting, new code for creating menu
  auto aboutMenu = menuBar()->addMenu( tr("&Help") );
  aboutMenu->addAction( aboutAction );
  aboutMenu->addAction( aboutQtAction );
  aboutMenu->addSeparator();
  aboutMenu->addAction( helpAction );
}

#ifdef __EMSCRIPTEN__
void NotebookWindow::addExampleMenu(const QString &root)
{
  QDir dir(root);
  if (!dir.exists())
    return;
  QMenu *menu = menuBar()->addMenu(dir.dirName());
  populateExampleMenu(menu, root);
}

void NotebookWindow::populateExampleMenu(QMenu *menu, const QString &path)
{
  QDir dir(path);
  const auto subdirs = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
  for (const QFileInfo &fi : subdirs)
    populateExampleMenu(menu->addMenu(fi.fileName()), fi.absoluteFilePath());

  const auto files = dir.entryInfoList(QStringList() << "*.onb" << "*.onbz", QDir::Files, QDir::Name);
  for (const QFileInfo &fi : files) {
    const QString p = fi.absoluteFilePath();
    QAction *a = menu->addAction(fi.completeBaseName());
    connect(a, &QAction::triggered, this, [this, p]() { openFile(p); });
  }
}
#endif

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
  application()->commandCenter().executeCommand(
        std::make_unique<EvalSelectedCells>( subject_.get() ));
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
  insertWebLinkAction->setEnabled( editable );
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
  std::map<QString, QAction*>::iterator cs = styles_.find(style.name());

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
  QTextDocument *doc = subject_->getCursor()->currentCell()->document();
  if( doc )
  {
    // undo
    if( doc->isUndoAvailable() )
      undoAction->setEnabled( true );
    else
      undoAction->setEnabled( false );

    // redo
    if( doc->isRedoAvailable() )
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
        in_cursor = subject_->getCursor()->currentCell()->textCursor();
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
#if (QT_VERSION < QT_VERSION_CHECK(7, 0, 0))
    const QStringList families = cursor.charFormat().fontFamilies().toStringList();
#else
    const QStringList families = cursor.charFormat().fontFamilies();
#endif

    for ( const auto &family: families )
    {
      if ( fonts_.contains( family ) )
      {
        fonts_[family]->setChecked( true );
        return;
      }
    }

    qDebug("No font found");
    QHash<QString, QAction*>::iterator f_iter = fonts_.begin();
    while( f_iter != fonts_.end() )
    {
      f_iter.value()->setChecked( false );
      ++f_iter;
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

    QHash<QAction*, QColor>::iterator c_iter = colors_.begin();
    while( c_iter != colors_.end() )
    {
      if( c_iter.value() == color )
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
  int k = 1;
  for (auto v: application()->documentViewList())
  {
    QString title = v->windowTitle();
    title.remove( "OMNotebook: " );

    QAction *action = new QAction( title, windowMenu );
    if (k < 10 ) {
      action->setShortcut( QKeySequence::fromString("Ctrl+"+QString::number(k)) );
      k++;
    }
    windows_[action] = v;
    windowMenu->addAction( action );
  }
}

/*!
  * \author Anders Fernström
  * \date 2006-01-17
  *
  * \brief Method for updating the window title
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
  * \brief Method for updating the chapter counters
  */
void NotebookWindow::updateChapterCounters()
{
  application()->commandCenter().executeCommand(
        std::make_unique<UpdateChapterCounters>( subject_.get() ));
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
    // the actions are created without parent (GraphCell/InputCell), take ownership
    // so they are deleted with the label and not leaked when the window closes
    for(QAction *a : l)
      a->setParent(stateIndicator);
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
      std::vector<Cell *> cells = subject_->getSelection();
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
  application()->commandCenter().executeCommand(new NewFileCommand());

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
    application()->commandCenter().executeCommand(std::make_unique<OpenFileCommand>(QString()));
  }
  else
  {
    if(subject_->hasChanged())
    {
      int res = QMessageBox::question(this, tr("Save document?"), tr("The document has been modified. Do you want to save the changes?"), QMessageBox::Yes | QMessageBox::No, QMessageBox::No);
      if(res == QMessageBox::Yes)
      {
        save();
        if(subject_->getFilename().isNull())
          return;
      }
      else if(res == QMessageBox::No)
        return;
    }

    subject_ = std::make_unique<CellDocument>(app_, QString());
    dynamic_cast<CellDocument*>(subject_.get())->autoIndent = autoIndentAction->isChecked();
    subject_->executeCommand(std::make_unique<NewFileCommand>());
    subject_->attach(this);

    // the connections of the constructor were to the old document
    connect( subject_->getCursor(), SIGNAL( changedPosition() ),
             this, SLOT( updateMenus() ));
    connect( subject_.get(), SIGNAL( contentChanged() ),
             this, SLOT( updateWindowTitle() ));
    connect( subject_.get(), SIGNAL( hoverOverFile(QString) ),
             this, SLOT( setStatusMessage(QString) ));
    connect( subject_.get(), SIGNAL( forwardAction(int) ),
             this, SLOT( forwardedAction(int) ));
    connect( subject_.get(), SIGNAL(updatePos(int, int)), this, SLOT(setPosition(int, int)));
    connect( subject_.get(), SIGNAL(newState(QString)), this, SLOT(setState(QString)));
    connect( subject_.get(), SIGNAL(setStatusMenu(QList<QAction*>)), this, SLOT(setStatusMenu(QList<QAction*>)));

    update();
    updateWindowTitle();
  }
}

void NotebookWindow::updateRecentFiles(const QString &filename)
{
  const QString path = QDir::cleanPath(QFileInfo(filename).absoluteFilePath());
  QStringList list = readRecentFiles();
  list.removeAll(path);
  list.prepend(path);
  while(list.size() > MaxRecentFiles)
    list.removeLast();
  writeRecentFiles(list);
}

void NotebookWindow::rebuildRecentMenu()
{
  recentMenu_->clear();
  for(const QString &path : readRecentFiles())
  {
    // '&' would be interpreted as a mnemonic marker
    QString text = path;
    text.replace('&', QLatin1String("&&"));
    QAction *a = recentMenu_->addAction(text, this, [this, path]() { openRecent(path); });
    // do not let macOS move entries like "About.onb" into the application menu
    a->setMenuRole(QAction::NoRole);
  }
}

void NotebookWindow::openRecent(const QString &path)
{
  if(!QFileInfo::exists(path))
  {
    QMessageBox::warning(this, tr("Warning"), tr("The file does not exist anymore:\n%1").arg(path));
    QStringList list = readRecentFiles();
    list.removeAll(path);
    writeRecentFiles(list);  // the menu is rebuilt the next time it is shown
    return;
  }
  openFile(path);
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
#ifdef __EMSCRIPTEN__
    // Web build: File->Open uploads a file from the user's computer through the
    // browser. The bytes arrive in a callback; stage them into MEMFS and open
    // from there. Opening a known path (menu entry or link) falls through below.
    if(filename.isEmpty())
    {
      QFileDialog::getOpenFileContent(
        "Notebooks (*.onb *.onbz *.nb)",
        [this](const QString &name, const QByteArray &content) {
          if(name.isEmpty())
            return;
          QString path = "/uploads/" + QFileInfo(name).fileName();
          QDir().mkpath("/uploads");
          QFile f(path);
          if(f.open(QIODevice::WriteOnly)) {
            f.write(content);
            f.close();
          }
          updateRecentFiles(path);
          application()->commandCenter().executeCommand(std::make_unique<OpenFileCommand>(path));
        });
      return;
    }
    filename_ = filename;
#else
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
#endif

    if(!filename_.isEmpty())
    {
      // 2006-03-01 AF, Update openDir_
      openDir_ = QFileInfo( filename_ ).absolutePath();

      updateRecentFiles(filename_);

      application()->commandCenter().executeCommand(std::make_unique<OpenFileCommand>(filename_));
    }
    else
    {
      //Cancel pushed. Do nothing
    }
  }
  catch(const std::exception &e)
  {
    QMessageBox::warning(nullptr, tr("Warning"), tr("In OpenFile(), Exception: \n") + e.what());
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
       "Distributed under OSMC-PL and AGPL3, see <u><a href=\"http://www.openmodelica.org\">www.openmodelica.org</a></u>.<br /><br />"
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
      application()->commandCenter().executeCommand(
            std::make_unique<OpenFileCommand>( helpFile ));
    }
    else
    {
      QMessageBox::warning(nullptr, tr("Warning"), tr("Could not find the help document OMNotebookHelp.onb"));
    }
  }
  catch(const std::exception &e)
  {
    QString msg = tr("In HelpText(), Exception: \n") + e.what();
    QMessageBox::warning(nullptr, tr("Warning"), msg);
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
#ifdef __EMSCRIPTEN__
  // Web build: there is no writable disk. Serialize to a MEMFS temp file, then
  // hand the bytes to the browser as a download.
  {
    QString name = QFileInfo(subject_->getFilename()).fileName();
    if(name.isEmpty())
      name = "untitled.onb";
    bool ok = false;
    name = QInputDialog::getText(this, tr("Save As"), tr("File name:"),
                                 QLineEdit::Normal, name, &ok);
    if(!ok || name.isEmpty())
      return;
    if(!name.endsWith(".onb", Qt::CaseInsensitive) && !name.endsWith(".onbz", Qt::CaseInsensitive))
      name += ".onb";
    QString tmp = "/tmp/" + name;
    QDir().mkpath("/tmp");
    application()->commandCenter().executeCommand(std::make_unique<SaveDocumentCommand>(subject_.get(), tmp));
    QFile f(tmp);
    if(f.open(QIODevice::ReadOnly)) {
      QByteArray bytes = f.readAll();
      f.close();
      QFileDialog::saveFileContent(bytes, name);
    }
    return;
  }
#endif
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
    application()->commandCenter().executeCommand(std::make_unique<SaveDocumentCommand>(subject_.get(), filename));

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
#ifdef __EMSCRIPTEN__
  // No persistent disk on the web; every save is a download via saveas().
  saveas();
  return;
#endif
  // Added a check to see if the document has been saved before,
  // if the document havn't been saved before - call saveas() instead.
  if( !subject_->isSaved() )
  {
    saveas();
  }
  else
  {
    statusBar()->showMessage(tr("Saving file"));
    application()->commandCenter().executeCommand(std::make_unique<SaveDocumentCommand>(subject_.get()));
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

  QPrintDialog dlg(&printer, this);
  if( dlg.exec() == QDialog::Accepted )
  {
    // 2006-03-03 AF, make sure that chapter numbers are updated
    updateChapterCounters();

    application()->commandCenter().executeCommand(
          std::make_unique<PrintDocumentCommand>(subject_.get(), &printer));

    //currentEditor->document()->print(&printer);

    // 2006-02-23 AF, display message box after printing document
    QString title = QFileInfo( subject_->getFilename() ).fileName();
    title.remove( "\n" );
    if( title.isEmpty() )
      title = "(untitled)";

    if( printer.outputFormat() == QPrinter::NativeFormat ) {
      QMessageBox::information(nullptr, tr("Document printed"), tr( "The document %1 has been printed on %2." ).arg(title, printer.printerName()));
    } else {
      QMessageBox::information(nullptr, tr("Document printed"), tr( "The document %1 has been printed to %2." ).arg(title, printer.outputFileName()));
    }
  }
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

    application()->commandCenter().executeCommand(
          std::make_unique<PrintDocumentCommand>(subject_.get(), &printer));

    //currentEditor->document()->print(&printer);

    QString title = QFileInfo( subject_->getFilename() ).fileName();
    title.remove( "\n" );
    if( title.isEmpty() )
      title = "(untitled)";
    QMessageBox::information(nullptr, tr("Document exported"), tr("The document %1 has been exported as PDF to %2.").arg(title, filename));
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
    QMessageBox::warning(nullptr, tr("Warning"), tr("Not a valid style name: %1").arg(action->text()));
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
  std::map<QString, QAction*>::iterator cs = styles_.begin();
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
        QMessageBox::warning(nullptr, tr("Warning"), tr("Not a value between %1 and %2.").arg(6).arg(200));
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
      QMessageBox::warning(nullptr, tr("Warning"), msg);
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

  auto it = colors_.find( action );
  if (it != colors_.end())
  {
    subject_->textcursorChangeFontColor( *it );
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
    QMessageBox::warning(nullptr, tr("Warning"), msg);
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
    QMessageBox::warning(nullptr, tr("Warning"), msg);
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
        QMessageBox::warning(nullptr, tr("Warning"), tr("Not a value between %1 and %2.").arg(0).arg(30));
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
      QMessageBox::warning(nullptr, tr("Warning"), tr("Error converting string to integer."));
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
        QMessageBox::warning(nullptr, tr("Warning"), tr("Not a value between %1 and %2.").arg(0).arg(80));
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
      QMessageBox::warning(nullptr, tr("Warning"), tr("Error converting string to integer."));
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
        QMessageBox::warning(nullptr, tr("Warning"), tr("Not a value between %1 and %2.").arg(0).arg(60));
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
      QMessageBox::warning(nullptr, tr("Warning"), tr("Error converting string to integer."));
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
  QTextDocument *doc = subject_->getCursor()->currentCell()->document();
  if( doc ) doc->undo();
}

/*!
  * \author Anders Fernström
  * \date 2006-02-03
  *
  * \brief Method for doing redo on text
  */
void NotebookWindow::redoEdit()
{
  QTextDocument *doc = subject_->getCursor()->currentCell()->document();
  if( doc ) doc->redo();
}

namespace {
  // The text of a cell as it is visible on the screen: a closed group shows
  // only its first cell, an open group all its cells.
  QString visibleCellText( Cell *cell )
  {
    if( !dynamic_cast<CellGroup *>( cell ) )
      return cell->text();

    QStringList texts;
    for( Cell *child = cell->child(); child; child = child->next() )
    {
      // the cell cursor is part of the cell list, but it is not a cell of the group
      if( dynamic_cast<CellCursor *>( child ) )
        continue;

      texts << visibleCellText( child );
      if( cell->isClosed() )
        break;
    }
    return texts.join( "\n\n" );
  }

  // The text of the cells, as plain text for the clipboard of the system
  QString cellsText( const std::vector<Cell *> &cells )
  {
    QStringList texts;
    for( Cell *cell : cells )
      texts << visibleCellText( cell );
    return texts.join( "\n\n" );
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
    const std::vector<Cell *> cells = subject_->getSelection();
    if( cells.size() > 0 )
    {
      const QString text = cellsText( cells );
      cutCell();
      putCellsOnClipboard( text );
    }
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
    const std::vector<Cell *> cells = subject_->getSelection();
    if( cells.size() > 0 )
    {
      const QString text = cellsText( cells );
      copyCell();
      putCellsOnClipboard( text );
    }
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
  * Pastes the copied cells at the position of the cell cursor if the
  * clipboard contains the mark of a cell copy, otherwise the text.
  */
void NotebookWindow::pasteEdit()
{
  if( subject_ )
  {
    if( cellsOnClipboard() )
      pasteCell();
    else
      subject_->textcursorPasteText();
  }
}

namespace {
  // The copied cells are in the pasteboard of the application. The clipboard of
  // the system gets the text of the cells and a mark in this format.
  const char cellsMimeType[] = "application/x-openmodelica-notebook-cells";
  int cellsCopyCounter = 0;   // the same for all windows of the process

  QString cellsCopyId()
  {
    return QString( "%1:%2" ).arg( QCoreApplication::applicationPid() ).arg( cellsCopyCounter );
  }
}

/*!
  * \brief Puts the text of the copied cells and the mark of a cell copy on the
  * clipboard of the system.
  */
void NotebookWindow::putCellsOnClipboard( const QString &text )
{
  if( application()->pasteboard().size() == 0 )
    return;

  ++cellsCopyCounter;
  QMimeData *mime = new QMimeData;
  mime->setText( text );
  mime->setData( cellsMimeType, cellsCopyId().toUtf8() );
  qApp->clipboard()->setMimeData( mime );
}

/*!
  * \brief True if the last thing that was copied to the clipboard are the cells
  * in the pasteboard of the application.
  */
bool NotebookWindow::cellsOnClipboard()
{
  const QMimeData *mime = qApp->clipboard()->mimeData();
  return mime && mime->hasFormat( cellsMimeType ) &&
         QString::fromUtf8( mime->data( cellsMimeType ) ) == cellsCopyId() &&
         application()->pasteboard().size() > 0;
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
      findForm_ = new SearchForm( this, subject_.get() );
    else
      findForm_->setDocument( subject_.get() );

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
      findForm_ = new SearchForm( this, subject_.get(), true );
    else
      findForm_->setDocument( subject_.get() );

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
      QMessageBox::warning(this, "Error",
        tr("A text that should make up the link, must be selected"));
    }
  }
}

/*!
  * \brief Method for inserting a link to a web page (http/https).
  *
  * If text is selected it becomes the link text. If the cursor is placed in
  * an existing web link, that link is edited.
  */
void NotebookWindow::insertWebLink()
{
  if( !cellEditable() )
    return;

  QTextCursor cursor = subject_->getCursor()->currentCell()->textCursor();
  if( cursor.isNull() )
    return;

  QString url;

  bool editing = false;

  // If the cursor is in (or at the border of) a web link, or the selection
  // lies inside one, select the whole link to change its text and/or url.
  {
    const int selStart = cursor.selectionStart();
    const int selEnd = cursor.selectionEnd();
    QString runHref;
    int runStart = -1, runEnd = -1;
    bool found = false;

    auto isWeb = []( const QString &href )
    {
      const QString scheme = QUrl( href ).scheme().toLower();
      return scheme == QLatin1String("http") || scheme == QLatin1String("https");
    };
    auto runContains = [&]()
    {
      return runStart >= 0 && runStart <= selStart && selEnd <= runEnd;
    };

    const QTextBlock block = cursor.document()->findBlock( selStart );
    for( QTextBlock::iterator it = block.begin(); !it.atEnd(); ++it )
    {
      const QTextFragment f = it.fragment();
      const QTextCharFormat fmt = f.charFormat();
      const bool web = fmt.isAnchor() && isWeb( fmt.anchorHref() );

      if( web && runStart >= 0 && fmt.anchorHref() == runHref )
      {
        // same link continues (e.g. partly bold text)
        runEnd = f.position() + f.length();
      }
      else
      {
        if( runContains() )
        {
          found = true;
          break;
        }
        if( web )
        {
          runStart = f.position();
          runEnd = f.position() + f.length();
          runHref = fmt.anchorHref();
        }
        else
          runStart = -1;
      }
    }
    if( !found && runContains() )
      found = true;

    if( found )
    {
      cursor.setPosition( runStart );
      cursor.setPosition( runEnd, QTextCursor::KeepAnchor );
      url = runHref;
      editing = true;
    }
  }

  QString text = cursor.selectedText();
  text.replace( QChar::ParagraphSeparator, QLatin1Char(' ') );
  text.replace( QChar::LineSeparator, QLatin1Char(' ') );

  QDialog dialog( this );
  dialog.setWindowTitle( editing ? tr("Edit Web Link") : tr("Insert Web Link") );
  QFormLayout *form = new QFormLayout( &dialog );
  // let the input fields use the full width of the dialog (some styles
  // keep them at their small size hint otherwise)
  form->setFieldGrowthPolicy( QFormLayout::AllNonFixedFieldsGrow );
  QLineEdit *textEdit = new QLineEdit( text, &dialog );
  QLineEdit *urlEdit = new QLineEdit( url, &dialog );
  urlEdit->setPlaceholderText( "https://www.openmodelica.org" );
  textEdit->setSizePolicy( QSizePolicy::Expanding, QSizePolicy::Fixed );
  urlEdit->setSizePolicy( QSizePolicy::Expanding, QSizePolicy::Fixed );
  form->addRow( tr("Text:"), textEdit );
  form->addRow( tr("URL:"), urlEdit );
  QDialogButtonBox *buttons = new QDialogButtonBox(
        QDialogButtonBox::Ok | QDialogButtonBox::Cancel, &dialog );
  form->addRow( buttons );
  dialog.setMinimumWidth( 500 );

  QString validUrl;
  connect( buttons, &QDialogButtonBox::rejected, &dialog, &QDialog::reject );
  connect( buttons, &QDialogButtonBox::accepted, &dialog, [&]()
  {
    QString u = urlEdit->text().trimmed();
    if( !u.contains( "://" ) )
      u = "https://" + u;
    const QUrl parsed( u, QUrl::StrictMode );
    const QString scheme = parsed.scheme().toLower();
    if( !parsed.isValid() || parsed.host().isEmpty() ||
        ( scheme != QLatin1String("http") && scheme != QLatin1String("https") ) )
    {
      QMessageBox::warning( &dialog, tr("Error"),
        tr("Please enter a valid web address starting with http:// or https://") );
      return;
    }
    validUrl = u;
    dialog.accept();
  });

  ( url.isEmpty() ? urlEdit : textEdit )->setFocus();
  // resizable in width only: fix the height to what the layout needs
  dialog.setFixedHeight( dialog.sizeHint().height() );
  if( dialog.exec() != QDialog::Accepted )
    return;

  subject_->textcursorInsertWebLink( validUrl, textEdit->text().trimmed(), cursor );
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

      application()->commandCenter().executeCommand(
            std::make_unique<OpenOldFileCommand>( filename, READMODE_OLD ));
    }
  }
  catch(const std::exception &e )
  {
    QString msg = QString("In NotebookWindow(), Exception:\r\n") + e.what();
    QMessageBox::warning(nullptr, tr("Warning"), msg);
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

    application()->commandCenter().executeCommand(
          std::make_unique<ExportToPureText>(subject_.get(), filename) );

    // 2006-03-24 AF, added message box - so user know when
    // export is done
    QString title = QFileInfo( subject_->getFilename() ).fileName();
    title.remove( "\n" );
    if( title.isEmpty() )
      title = "(untitled)";

    QMessageBox::information(nullptr, "Document exported", tr("The document %1 has been exported as pure text to %2.").arg(title,filename));
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
  if (QMessageBox::warning(nullptr, "Delete Cell", tr("Delete current cell?\nThis action cannot be undone!"), QMessageBox::Ok|QMessageBox::Default,QMessageBox::Cancel ) == QMessageBox::Ok)
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
      subject_->executeCommand(std::make_unique<MakeGroupCellCommand>());
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
  subject_->executeCommand(std::make_unique<CreateNewCellCommand>("Graph"));
  subject_->updateScrollArea();
  updateChapterCounters();
}

void NotebookWindow::latexCellsAction()
{
  subject_->executeCommand(std::make_unique<CreateNewCellCommand>("Latex"));
  subject_->updateScrollArea();
  updateChapterCounters();
}

void NotebookWindow::textCellsAction()
{
  subject_->executeCommand(std::make_unique<CreateNewCellCommand>("Text"));
  subject_->updateScrollArea();
  updateChapterCounters();
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
    std::vector<Cell *> cells = subject_->getSelection();
    qDebug()<<cells.size();

    if( !cells.empty() )
    {
      // open closed groupcells otherwise OMNotebook does not copy right and crashes afterwards
      std::vector<Cell *>::iterator i = cells.begin();
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
        QMessageBox::warning(nullptr, tr("Warning"), msg);
    }
}

void NotebookWindow::shiftcellsUp()
{
  std::vector<Cell *> cells = subject_->getSelection();

  if (cells.size()==0)
  {
    Cell *current=subject_->getCursor()->currentCell();
    if (current->hasPrevious())
    {
      if( dynamic_cast<CellGroup*>(current->previous()) )
      {
        QMessageBox::warning(nullptr, tr("Warning"), err_hierarchy);
      }
      else
      {
        if (current->isClosed())
        {
          QMessageBox::warning(nullptr, tr("Warning"), tr("Cannot move closed cells."));
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
            subject_->executeCommand(std::make_unique<CreateNewCellCommand>("Graph"));
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
            subject_->executeCommand(std::make_unique<CreateNewCellCommand>("Graph"));
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
            subject_->executeCommand(std::make_unique<CreateNewCellCommand>("Latex"));
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
            subject_->executeCommand(std::make_unique<CreateNewCellCommand>("Latex"));
            subject_->getCursor()->currentCell()->setText(currenttext);
          }
        }
        else
        {
          Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" );
          std::vector<QString> styles = sheet->getAvailableStyleNames();
          if (std::find(styles.begin(), styles.end(), style) != styles.end() )
          {
            QString textoutput=current->textHtml();
            subject_->cursorDeleteCell();
            //subject_->getCursor()->moveUp();
            subject_->cursorStepUp();
            subject_->executeCommand(std::make_unique<CreateNewCellCommand>(style));
            subject_->getCursor()->currentCell()->setTextHtml(textoutput);
          }
        }
      }
    }
    else
    {
      QMessageBox::warning(nullptr, tr("Warning"), err_hierarchy);
    }
  }
  else
  {
    QMessageBox::warning(nullptr, tr("Warning"), tr("This functionality does not work on selected cells. Click on the cell to move up, and press this action."));
  }
}

void NotebookWindow::shiftcellsDown()
{
  std::vector<Cell *> cells = subject_->getSelection();
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
          QMessageBox::warning(nullptr, tr("Warning"), err_hierarchy);
      }
      else
      {
        if (current->isClosed())
        {
          QMessageBox::warning(nullptr, tr("Warning"), tr("Cannot move closed cells."));
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
            subject_->executeCommand(std::make_unique<CreateNewCellCommand>("Graph"));
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
            subject_->executeCommand(std::make_unique<CreateNewCellCommand>("Graph"));
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
            subject_->executeCommand(std::make_unique<CreateNewCellCommand>("Latex"));
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
            subject_->executeCommand(std::make_unique<CreateNewCellCommand>("Latex"));
            subject_->getCursor()->currentCell()->setText(currenttext);
          }
        }
        else
        {
          Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" );
          std::vector<QString> styles = sheet->getAvailableStyleNames();
          if (std::find(styles.begin(), styles.end(), style) != styles.end() )
          {
            QString textoutput=current->textHtml();
            subject_->cursorDeleteCell();
            subject_->cursorStepDown();
            subject_->executeCommand(std::make_unique<CreateNewCellCommand>(style));
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
      QMessageBox::warning(nullptr, tr("Warning"), tr("This functionality does not work on selected cells. Click on the cell to move down, and press this action"));
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
