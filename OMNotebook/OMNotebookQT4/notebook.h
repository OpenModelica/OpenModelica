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

/*! 
 * \file notebook.h
 * \author Ingemar Axelsson and Anders Fernström
 * \date 2005-02-07
 */

#ifndef NOTEBOOK_WINDOW_H
#define NOTEBOOK_WINDOW_H


//STD Headers
#include <map>

//QT Headers
#include <QtCore/QHash>

//IAEX Headers
#include "application.h"
#include "document.h"
#include "documentview.h"

//Forward declaration
class QAction;
class QActionGroup;
class QKeyEvent;
class QMenu;
class QMenuBar;
class QStatusbar;
class QWidget;
class QLabel;


namespace IAEX
{
	// forward declaration
	class SearchForm;

	class NotebookWindow : public DocumentView
	{
		Q_OBJECT

	public:
		NotebookWindow(Document *subject, const QString& filename=0,
			QWidget *parent=0);
		virtual ~NotebookWindow();

		virtual void update();
		virtual Document* document();
		Application *application();

	public slots:
		void updateMenus();						// Added 2005-11-07 AF
		void updateStyleMenu();
		void updateEditMenu();					// Added 2005-11-02 AF
		void updateCellMenu();					// Added 2006-02-03 AF
		void updateFontMenu();					// Added 2005-11-03 AF
		void updateFontFaceMenu();				// Added 2005-11-03 AF
		void updateFontSizeMenu();				// Added 2005-11-04 AF
		void updateFontStretchMenu();			// Added 2005-11-04 AF
		void updateFontColorMenu();				// Added 2005-11-07 AF
		void updateTextAlignmentMenu();			// Added 2005-11-07 AF
		void updateVerticalAlignmentMenu();		// Added 2005-11-07 AF
		void updateBorderMenu();				// Added 2005-11-07 AF
		void updateMarginMenu();				// Added 2005-11-07 AF
		void updatePaddingMenu();				// Added 2005-11-07 AF
		void updateWindowMenu();				// Added 2006-01-27 AF
		void updateWindowTitle();				// Added 2006-01-17 AF
		void updateChapterCounters();			// Added 2006-03-02 AF
		void setStatusMessage( QString msg );	// Added 2006-02-10 AF
		void forwardedAction( int action );		// Added 2006-04-27 AF
		void setPosition(int r, int c);
		void setState(QString);
		void setStatusMenu(QList<QAction*>);
		void recentTriggered();
	protected:
		void keyPressEvent(QKeyEvent *event);
		void keyReleaseEvent(QKeyEvent *event);

	private slots:
		void newFile();
		void openFile(const QString &filename=0);
		void closeFile();
		void closeEvent( QCloseEvent *event );			// Added 2006-01-19 AF
		void aboutQTNotebook();
		void aboutQT();									// Added 2006-02-21 AF
		void helpText();								// Added 2006-02-03 AF
		void saveas();
		void save();
		void quitOMNotebook();							// Added 2006-01-18 AF
		void print();									// Added 2005-12-19 AF
		void selectFont();								// Added 2005-11-07 AF
		void changeStyle(QAction *action);
		void changeStyle();
		void changeFont(QAction *action);				// Added 2005-11-03 AF
		void changeFontFace(QAction *action);			// Added 2005-11-03 AF
		void changeFontSize(QAction *action);			// Added 2005-11-04 AF
		void changeFontStretch(QAction *action);		// Added 2005-11-04 AF
		void changeFontColor(QAction *action);			// Added 2005-11-07 AF
		void changeTextAlignment(QAction *action);		// Added 2005-11-07 AF
		void changeVerticalAlignment(QAction *action);	// Added 2005-11-07 AF
		void changeBorder(QAction *action);				// Added 2005-11-07 AF
		void changeMargin(QAction *action);				// Added 2005-11-07 AF
		void changePadding(QAction *action);			// Added 2005-11-07 AF
		void changeWindow(QAction *action);				// Added 2006-01-27 AF

		void undoEdit();				// Added 2006-02-03 AF
		void redoEdit();				// Added 2006-02-03 AF
		void cutEdit();					// Added 2006-02-03 AF
		void copyEdit();				// Added 2006-02-03 AF
		void pasteEdit();				// Added 2006-02-03 AF
		void findEdit();				// Added 2006-08-24 AF
		void replaceEdit();				// Added 2006-08-24 AF
		
		void insertImage();				// Added 2005-11-18 AF
		void insertLink();				// Added 2005-12-05 AF
		void openOldFile();				// Added 2005-12-01 AF
		void pureText();				// Added 2005-11-21 AF

		void createNewCell();
		void deleteCurrentCell();
		void cutCell();
		void copyCell();
		void pasteCell();
		void ungroupCell();				// Added 2006-04-26 AF
		void splitCell();				// Added 2006-04-26 AF
		void moveCursorUp();
		void moveCursorDown();
		void groupCellsAction();
		void inputCellsAction();
		void graphCellsAction();
		void textCellsAction();
		void updateRecentFiles(QString);

	private:
		void createFileMenu();
		void createEditMenu();
		void createCellMenu();
		void createFormatMenu();
		void createInsertMenu();
		void createWindowMenu();		//Added 2006-01-27 AF
		void createAboutMenu();

		bool cellEditable();			//Added 2005-11-11 AF
		void evalCells();				//Added 2006-02-14 AF
		void createSavingTimer();

	private:
		QToolBar* toolBar;
		// 2005-10-07 AF, Porting, Added this menus
		QMenu *fileMenu;
		QMenu *recentMenu;
		QMenu *editMenu;
		QMenu *cellMenu;
		QMenu *formatMenu;
		QMenu *insertMenu;					// Added 2005-11-18 AF
		QMenu *windowMenu;					// Added 2006-01-27 AF
		QMenu *aboutMenu;

		// 2005-11-03/04/07 AF, Added some more for text setting changes
		QMenu *styleMenu;
		QMenu *fontMenu;
		QMenu *faceMenu;
		QMenu *sizeMenu;
		QMenu *stretchMenu;
		QMenu *colorMenu;
		QMenu *alignmentMenu;
		QMenu *verticalAlignmentMenu;
		QMenu *borderMenu;
		QMenu *marginMenu;
		QMenu *paddingMenu;
		// 2005-12-01 AF, added for import old omnotebook file
		QMenu *importMenu;
		// 2005-11-21 AF, added for export pure text
		QMenu *exportMenu;

		// 2005-10-07 AF, Porting, Added this actions
		// 2005-11-03/04/07 AF, Added some more for text setting changes
		QActionGroup *stylesgroup;
		QActionGroup *fontsgroup;
		QActionGroup *sizesgroup;
		QActionGroup *stretchsgroup;
		QActionGroup *colorsgroup;
		QActionGroup *alignmentsgroup;
		QActionGroup *verticalAlignmentsgroup;
		QActionGroup *bordersgroup;
		QActionGroup *marginsgroup;
		QActionGroup *paddingsgroup;

		QAction *newAction;
		QAction *openFileAction;
		QAction *saveAsAction;
		QAction *saveAction;
		QAction *printAction;				// Added 2005-12-19 AF
		QAction *closeFileAction;
		QAction *quitWindowAction;

		QAction *undoAction;
		QAction *redoAction;
		QAction *cutAction;
		QAction *copyAction;
		QAction *pasteAction;
		QAction *findAction;				// Changed 2006-08-24 AF
		QAction *replaceAction;				// Added 2006-08-24 AF
		QAction *showExprAction;

		//QAction *cutCellAction;
		//QAction *copyCellAction;
		//QAction *pasteCellAction;
		QAction *addCellAction;
		QAction *ungroupCellAction;			// Added 2006-04-26 AF
		QAction *splitCellAction;			// Added 2006-04-26 AF
		QAction *deleteCellAction;
		QAction *nextCellAction;
		QAction *previousCellAction;
		
		QAction *groupAction;
		QAction *inputAction;
		QAction *graphAction;
		QAction *textAction;

		QAction *aboutAction;
		QAction *helpAction;				// Added 2006-02-03 AF
		QAction *aboutQtAction;				// Added 2006-02-21 AF

		QAction *facePlain;
		QAction *faceBold;
		QAction *faceItalic;
		QAction *faceUnderline;

		QAction *sizeSmaller;
		QAction *sizeLarger;
		QAction *size8pt;
		QAction *size9pt;
		QAction *size10pt;
		QAction *size12pt;
		QAction *size14pt;
		QAction *size16pt;
		QAction *size18pt;
		QAction *size20pt;
		QAction *size24pt;
		QAction *size36pt;
		QAction *size72pt;
		QAction *sizeOther;

		QAction *stretchUltraCondensed;
		QAction *stretchExtraCondensed;
		QAction *stretchCondensed;
		QAction *stretchSemiCondensed;
		QAction *stretchUnstretched;
		QAction *stretchSemiExpanded;
		QAction *stretchExpanded;
		QAction *stretchExtraExpanded;
		QAction *stretchUltraExpanded;

		QAction *colorBlack;
		QAction *colorWhite;
		QAction *color10Gray;
		QAction *color33Gray;
		QAction *color50Gray;
		QAction *color66Gray;
		QAction *color90Gray;
		QAction *colorRed;
		QAction *colorGreen;
		QAction *colorBlue;
		QAction *colorCyan;
		QAction *colorMagenta;
		QAction *colorYellow;
		QAction *colorOther;

		QAction *chooseFont;

		QAction *alignmentLeft;
		QAction *alignmentRight;
		QAction *alignmentCenter;
		QAction *alignmentJustify;
		QAction *verticalNormal;
		QAction *verticalSub;
		QAction *verticalSuper;

		QAction *borderOther;
		QAction *marginOther;
		QAction *paddingOther;

		QAction *insertImageAction;		// Added 2005-11-18 AF
		QAction *insertLinkAction;		// Added 2005-12-05 AF
		QAction *importOldFile;			// Added 2005-12-01 AF
		QAction *exportPureText;		// Added 2005-11-21 AF

		// 2005-11-03/04/07 AF, Added for the new menus (for text changes)
		QHash<QString, QAction*> fonts_;
		QHash<QString, QAction*> sizes_;
		QHash<int, QAction*> stretchs_;
		QHash<QAction*, QColor*> colors_;
		QHash<int, QAction*> alignments_;
		QHash<int, QAction*> verticals_;
		QHash<int, QAction*> borders_;
		QHash<int, QAction*> margins_;
		QHash<int, QAction*> paddings_;
		QHash<QAction*, DocumentView*> windows_;

		//Change to Document.
		Application *app_;
		Document *subject_;

		//list<Document *> opendocs_;
		QString filename_;

		QTimer *savingTimer_;
		map<QString, QAction*> styles_;   

		SearchForm* findForm_;		// added 2006-08-24 AF
		bool closing_;				// Added 2006-02-09 AF

		static QString openDir_;	// Added 2006-03-01 AF
		static QString saveDir_;	// Added 2006-03-01 AF
		static QString imageDir_;	// Added 2006-03-01 AF
		static QString linkDir_;	// Added 2006-03-01 AF

		QLabel* posIndicator, *stateIndicator;
	};
}
#endif
