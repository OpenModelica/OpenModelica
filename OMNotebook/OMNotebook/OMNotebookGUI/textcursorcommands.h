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
 * \file cellcommands.h
 * \author Anders Fernström
 * \date 2005-11-03
 *
 * \brief Describes different textcursor commands
 */

#ifndef TEXTCURSORCOMMANDS_H
#define TEXTCURSORCOMMANDS_H

//IAEX Headers
#include "command.h"
#include "application.h"



namespace IAEX
{

  class TextCursorCutText : public Command
  {
  public:
    TextCursorCutText(){}
    virtual ~TextCursorCutText(){}
    virtual QString commandName() override { return QString("TextCursorCutText"); }
    void execute() override;
  };

  class TextCursorCopyText : public Command
  {
  public:
    TextCursorCopyText(){}
    virtual ~TextCursorCopyText(){}
    virtual QString commandName() override { return QString("TextCursorCopyText"); }
    void execute() override;
  };


  class TextCursorPasteText : public Command
  {
  public:
    TextCursorPasteText(){}
    virtual ~TextCursorPasteText(){}
    virtual QString commandName() override { return QString("TextCursorPasteText"); }
    void execute() override;
  };

  class TextCursorChangeFontFamily : public Command
  {
  public:
    TextCursorChangeFontFamily(QString family)
      : family_(family){}
    virtual ~TextCursorChangeFontFamily(){}
    virtual QString commandName() override { return QString("TextCursorChangeFontFamily"); }
    void execute() override;

  private:
    QString family_;
  };


  class TextCursorChangeFontFace : public Command
  {
  public:
    TextCursorChangeFontFace(int face)
      : face_(face){}
    virtual ~TextCursorChangeFontFace(){}
    virtual QString commandName() override { return QString("TextCursorChangeFontFace"); }
    void execute() override;

  private:
    int face_;
  };


  class TextCursorChangeFontSize : public Command
  {
  public:
    TextCursorChangeFontSize(int size)
      : size_(size){}
    virtual ~TextCursorChangeFontSize(){}
    virtual QString commandName() override { return QString("TextCursorChangeFontSize"); }
    void execute() override;

  private:
    int size_;
  };


  class TextCursorChangeFontStretch : public Command
  {
  public:
    TextCursorChangeFontStretch(int stretch)
      : stretch_(stretch){}
    virtual ~TextCursorChangeFontStretch(){}
    virtual QString commandName() override { return QString("TextCursorChangeFontStretch"); }
    void execute() override;

  private:
    int stretch_;
  };


  class TextCursorChangeFontColor : public Command
  {
  public:
    TextCursorChangeFontColor(QColor color)
      : color_(color){}
    virtual ~TextCursorChangeFontColor(){}
    virtual QString commandName() override { return QString("TextCursorChangeFontColor"); }
    void execute() override;

  private:
    QColor color_;
  };


  class TextCursorChangeTextAlignment : public Command
  {
  public:
    TextCursorChangeTextAlignment(int alignment)
      : alignment_(alignment){}
    virtual ~TextCursorChangeTextAlignment(){}
    virtual QString commandName() override { return QString("TextCursorChangeTextAlignment"); }
    void execute() override;

  private:
    int alignment_;
  };


  class TextCursorChangeVerticalAlignment : public Command
  {
  public:
    TextCursorChangeVerticalAlignment(int alignment)
      : alignment_(alignment){}
    virtual ~TextCursorChangeVerticalAlignment(){}
    virtual QString commandName() override { return QString("TextCursorChangeVerticalAlignment"); }
    void execute() override;

  private:
    int alignment_;
  };


  class TextCursorChangeMargin : public Command
  {
  public:
    TextCursorChangeMargin(int margin)
      : margin_(margin){}
    virtual ~TextCursorChangeMargin(){}
    virtual QString commandName() override { return QString("TextCursorChangeMargin"); }
    void execute() override;

  private:
    int margin_;
  };


  class TextCursorChangePadding : public Command
  {
  public:
    TextCursorChangePadding(int padding)
      : padding_(padding){}
    virtual ~TextCursorChangePadding(){}
    virtual QString commandName() override { return QString("TextCursorChangePadding"); }
    void execute() override;

  private:
    int padding_;
  };


  class TextCursorChangeBorder : public Command
  {
  public:
    TextCursorChangeBorder(int border)
      : border_(border){}
    virtual ~TextCursorChangeBorder(){}
    virtual QString commandName() override { return QString("TextCursorChangeBorder"); }
    void execute() override;

  private:
    int border_;
  };


  class TextCursorInsertImage : public Command
  {
  public:
    TextCursorInsertImage(QString filepath, QSize size)
      : filepath_(filepath), height_(size.height()), width_(size.width()){}
    virtual ~TextCursorInsertImage(){}
    virtual QString commandName() override { return QString("TextCursorInsertImage"); }
    void execute() override;

  private:
    QString filepath_;
    int height_;
    int width_;
  };


  class TextCursorInsertLink : public Command
  {
  public:
    TextCursorInsertLink( QString filepath, QTextCursor& cursor_ )
      : filepath_(filepath), cursor(cursor_){}
    virtual ~TextCursorInsertLink(){}
    virtual QString commandName() override { return QString("TextCursorInsertLink"); }
    void execute() override;

  private:
    QString filepath_;
    QTextCursor cursor;
  };
}

#endif

