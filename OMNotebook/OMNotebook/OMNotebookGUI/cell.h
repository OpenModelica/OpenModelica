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

// QT Headers
#include <QtGlobal>
#include <QtWidgets>
#include <QGridLayout>
#include <QLabel>
#include <QMouseEvent>
#include <QResizeEvent>
#include <QTextCharFormat>
#include <QTextCursor>
#include <QTextEdit>
#include <QUrl>


//IAEX Headers
#include "cellstyle.h"
#include "rule.h"
#include "treeview.h"
#include "visitor.h"


using namespace IAEX;

namespace IAEX
{
  class Cell : public QWidget
  {
    Q_OBJECT

  public:
    typedef std::vector<Rule> rules_t;

    Cell(QWidget *parent = nullptr);
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
    virtual QString textHtml(){return QString();}
    virtual QTextDocument* document() { return nullptr; }
    virtual QTextCursor textCursor();
    virtual QTextEdit* textEdit(){return 0;}
    virtual void viewExpression(bool){}
    virtual void cutText() {}
    virtual void copyText() {}
    virtual void pasteText() {}
    virtual bool findText(const QString &/*exp*/, QTextDocument::FindFlags /*options*/) { return false; }

    virtual void clearSelection() {}
    virtual void moveCursor(QTextCursor::MoveOperation /*operation*/) {}

    //Cellgroup interface.
    virtual void addChild(Cell *){}
    virtual void removeChild(Cell *){}
    virtual bool isClosed() const { return false; }
    virtual void setClosed(bool /*closed*/, bool /*update*/ = true){}

    virtual void addCellWidget(Cell *newCell); //Protected?

    //Rename to insertCellWidgets() instead.
    virtual void addCellWidgets(){parentCell()->addCellWidgets();}
    virtual void removeCellWidgets(){parentCell()->removeCellWidgets();}

    //Traversal methods
    virtual void accept(Visitor &v);

    //Flags
    bool isSelected() const;
    bool isTreeViewVisible() const;
    virtual bool isEditable() const = 0;
    bool isViewExpression() const;

    //Properties
    const QColor backgroundColor() const;
    virtual CellStyle *style();
    QString cellTag();
    virtual const rules_t& rules() const;
    QWidget *mainWidget();
    TreeView *treeView();
    QLabel *label();



  public slots:
    virtual void addRule(Rule r);
    virtual void setText(QString /*text*/) {}
    virtual void setText(QString /*text*/, QTextCharFormat /*format*/) {}
    virtual void setTextHtml(QString /*html*/) {}
    virtual void setStyle(const QString &stylename);
    virtual void setStyle(CellStyle style);
    void setCellTag(QString tagname);
    virtual void setReadOnly(bool) {}
    virtual void setFocus(bool focus) = 0;
    virtual void applyLinksToText() {}

    virtual void setBackgroundColor(const QColor color);
    virtual void setSelected(bool selected);
    virtual void setHeight(int height);
    void hideTreeView(bool hidden);

    void wheelEvent(QWheelEvent * event) override;      //tmp

  protected slots:
    void setLabel(QLabel *label);
    void setTreeWidget(TreeView *newTreeWidget);
    void setMainWidget(QWidget *mainWidget);
    void addChapterCounter(QWidget *counter);

  signals:
    void clicked(Cell*);
    void doubleClicked(int);
    void changedWidth(int);
    void selected(bool);

    // 2005-10-06 AF, bytt från Qt::ButtonState till
    // Qt::KeyboardModifiers p.g.a. portning
    void cellselected(Cell *, Qt::KeyboardModifiers);

    void heightChanged();
    void openLink(const QUrl *link);
    void cellOpened(Cell *, bool);

  protected:
    //Events
    void resizeEvent(QResizeEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;

    void applyRulesToStyle();

    // variables
    bool viewexpression_ = false;
    CellStyle style_;

  private:
    QString celltag_;
    QGridLayout *mainlayout_ = nullptr;
    TreeView *treeView_ = nullptr;
    QWidget *mainWidget_ = nullptr;
    QLabel *label_ = nullptr;

    bool selected_ = false;
    bool treeviewVisible_ = true;
    QColor backgroundColor_;

    rules_t rules_;

    Cell *parent_ = nullptr;
    Cell *next_ = nullptr;
    Cell *last_ = nullptr;
    Cell *previous_ = nullptr;
    Cell *child_ = nullptr;
  };
}
#endif
