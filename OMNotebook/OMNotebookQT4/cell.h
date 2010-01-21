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
 * \file cell.h
 * \author Ingemar Axelsson and Anders Fernström
 * \brief Definition of the cellinterface.
 *
 *  This file contains the definition of the cellinterface.
 */
#ifndef CELL_H
#define CELL_H

#define _CRT_SECURE_NO_WARNINGS

//STD Headers
#include <vector>

//QT Headers
#include <QtGui/QWidget>

//IAEX Headers
#include "cellstyle.h"
#include "rule.h"
#include "treeview.h"
#include "visitor.h"

// forward declaration
class QGridLayout;
class QLabel;
class QMouseEvent;
class QResizeEvent;
class QTextCharFormat;
class QTextCursor;
class QTextEdit;
class QUrl;


using namespace IAEX;
using namespace Qt;

namespace IAEX
{
	class Cell : public QWidget
	{
		Q_OBJECT

	public:
		typedef vector<Rule *> rules_t;

		Cell(QWidget *parent=0);						// Changed 2005-10-27 AF
		Cell(Cell &c);
		virtual ~Cell();

		//Datastructure interface.
		void setNext(Cell *nxt);
		Cell *next();
		bool hasNext();

		void setLast(Cell *last);
		Cell *last();
		bool hasLast();

		void setPrevious(Cell *prev);
		Cell *previous();
		bool hasPrevious();

		Cell *parentCell();
		void setParentCell(Cell *parent);
		bool hasParentCell();

		void setChild(Cell *child);
		Cell *child();
		bool hasChilds();

		void printCell(Cell *current);
		void printSurrounding(Cell *current);

		//TextCell interface.
		virtual QString text() = 0;
		virtual QString textHtml(){return QString::null;}	// Added 2005-10-27 AF
		virtual QTextCursor textCursor();					// Added 2005-10-27 AF
		virtual QTextEdit* textEdit(){return 0;}			// Added 2005-10-27 AF
		virtual void viewExpression(const bool){};

		//Cellgroup interface.
		virtual void addChild(Cell *){}
		virtual void removeChild(Cell *){}
		virtual bool isClosed() const{ return false;}
		virtual void setClosed(const bool closed, bool update = true){}	// Changed 2006-08-24

		virtual void addCellWidget(Cell *newCell); //Protected?

		//Rename to insertCellWidgets() instead.
		virtual void addCellWidgets(){parentCell()->addCellWidgets();}
		virtual void removeCellWidgets(){parentCell()->removeCellWidgets();}

		//Traversal methods
		virtual void accept(Visitor &v);

		//Flags
		const bool isSelected() const;
		const bool isTreeViewVisible() const;
		virtual bool isEditable() = 0;				// Added 2005-10-27 AF
		const bool isViewExpression() const;		// Added 2005-11-02 AF

		//Properties
		const QColor backgroundColor() const;
		virtual CellStyle *style();					// Changed 2005-10-27 AF
		QString cellTag();							// Added 2006-01-16 AF
		virtual rules_t rules() const;
		QWidget *mainWidget();
		TreeView *treeView();
		QLabel *label();



	public slots:
		virtual void addRule(Rule *r);
		virtual void setText(QString text){}
		virtual void setText(QString text, QTextCharFormat format){}			// Added 2005-10-27 AF
		virtual void setTextHtml(QString html){}								// Added 2005-10-27 AF
		virtual void setStyle(const QString &stylename);						// Changed 2005-10-28 AF
		virtual void setStyle(CellStyle style);									// Changed 2005-10-27 AF
		void setCellTag(QString tagname);										// Added 2006-01-16 AF
		virtual void setReadOnly(const bool){}
		virtual void setFocus(const bool focus) = 0;
		virtual void applyLinksToText(){}										// Added 2005-11-09 AF

		virtual void setBackgroundColor(const QColor color);
		virtual void setSelected(const bool selected);
		virtual void setHeight(const int height);
		void hideTreeView(const bool hidden);

		void wheelEvent(QWheelEvent * event);			//tmp

	protected slots:
		void setLabel(QLabel *label);
		void setTreeWidget(TreeView *newTreeWidget);
		void setMainWidget(QWidget *newWidget);
		void addChapterCounter(QWidget *counter);		// Added 2006-02-03 AF

	signals:
		void clicked(Cell*);
		void doubleClicked(int);
		void changedWidth(const int);
		void selected(const bool);

		// 2005-10-06 AF, bytt från Qt::ButtonState till
		// Qt::KeyboardModifiers p.g.a. portning
		void cellselected(Cell *, Qt::KeyboardModifiers);

		void heightChanged();
		void openLink(const QUrl *link);
		void cellOpened(Cell *, const bool);

	protected:
		//Events
		void resizeEvent(QResizeEvent *event);
		void mouseReleaseEvent(QMouseEvent *event);
		void mouseMoveEvent(QMouseEvent *event);

		void applyRulesToStyle();						// Added 2005-10-27 AF

		// variables
		bool viewexpression_;							// Added 2005-11-02 AF
		CellStyle style_;								// Changed 2005-10-27 AF

	private:
		QString celltag_;								// Added 2005-11-03 AF
		QGridLayout *mainlayout_;
		TreeView *treeView_;
		QWidget *mainWidget_;
		QLabel *label_;

		bool selected_;
		bool treeviewVisible_;
		QColor backgroundColor_;

		rules_t rules_;

		Cell *parent_;
		Cell *next_;
		Cell *last_;
		Cell *previous_;
		Cell *child_;

		int references_;
	};
}
#endif
