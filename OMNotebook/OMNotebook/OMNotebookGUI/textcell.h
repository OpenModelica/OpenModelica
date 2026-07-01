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
 * \file textcell.h
 * \author Ingemar Axelsson and Anders Fernström
 * \date 2005-02-08
 *
 * \brief Describes a textcell.
 */

#ifndef TEXTCELL_H
#define TEXTCELL_H


// Qt headers
#include <QtGlobal>
#include <QtWidgets>
#include <QResizeEvent>
#include <QUrl>
#include <QWidget>

// IAEX headers
#include "cell.h"


namespace IAEX
{
  class TextCell : public Cell
  {
    Q_OBJECT

  public:
    TextCell(QWidget *parent = 0);
    virtual ~TextCell();

    QString text() override;
    QString textHtml() override;
    QTextCursor textCursor() override;
    QTextEdit* textEdit() override;
    void cutText() override;
    void copyText() override;
    void pasteText() override;

    void clear();
    virtual void accept(Visitor &v) override;
    virtual bool isEditable() const override;
    virtual void viewExpression(bool expr) override;

  signals:
    void textChanged();
    void textChanged( bool );
    void hoverOverUrl( const QUrl &link );
    void forwardAction( int );

  public slots:
    void clickEvent();
    void setText(QString text) override;
    void setText(QString text, QTextCharFormat format) override;
    void setTextHtml(QString html) override;
    void setStyle(const QString &stylename) override;
    void setStyle(CellStyle style) override;
    void setChapterCounter(QString number);
    QString ChapterCounter();
    QString ChapterCounterHtml();
    void setReadOnly(bool readonly) override;
    virtual void setFocus(bool focus) override;



  protected slots:
    void contentChanged();
    void hoverOverLink(const QUrl &link);
    void openLinkInternal(const QUrl *url);
    void openLinkInternal(const QUrl &url);
    void textChangedInternal();
    void charFormatChanged(const QTextCharFormat &);

  protected:
    void resizeEvent(QResizeEvent *event) override;

  private:
    void createTextWidget();
    void createChapterCounter();

  public:
    QTextBrowser *text_;
  private:
    QTextBrowser *chaptercounter_;

    QString oldHoverLink_;

    int oldHeight_;
  };

  //***************************************************
  class MyTextBrowser : public QTextBrowser
  {
    Q_OBJECT

  public:
    MyTextBrowser(QWidget *parent=0);
    virtual ~MyTextBrowser();

    void setActive( bool active );

  signals:
    void openLink(const QUrl *);
    void clickOnCell();
    void wheelMove( QWheelEvent* );
    void forwardAction( int );

  public slots:
#if (QT_VERSION < QT_VERSION_CHECK(6, 0, 0))
    void setSource(const QUrl &name) override;
#endif

  protected:
    void mousePressEvent(QMouseEvent *event) override;
    void wheelEvent(QWheelEvent * event) override;
    void insertFromMimeData(const QMimeData *source) override;
    void keyPressEvent(QKeyEvent *event ) override;

#if (QT_VERSION >= QT_VERSION_CHECK(6, 0, 0))
    // QTextBrowser interface
  protected:
    virtual void doSetSource(const QUrl &name, QTextDocument::ResourceType type) override;
#endif
  };

}
#endif
