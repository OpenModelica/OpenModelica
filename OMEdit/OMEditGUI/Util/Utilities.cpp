/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR 
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2. 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE. 
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * 
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include "MainWindow.h"
#include "Utilities.h"

MdiArea::MdiArea(QWidget *pParent)
  : QMdiArea(pParent)
{
  mpMainWindow = qobject_cast<MainWindow*>(pParent);
  setHorizontalScrollBarPolicy(Qt::ScrollBarAsNeeded);
  setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
  setActivationOrder(QMdiArea::ActivationHistoryOrder);
  setDocumentMode(true);
}

MainWindow* MdiArea::getMainWindow()
{
  return mpMainWindow;
}

ElidedLabel::ElidedLabel(const QString &text, Qt::TextElideMode elideMode, QWidget *parent)
  : QFrame(parent), mElideMode(elideMode), elided(false), content(text)
{
  setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Preferred);
  setMinimumHeight(18); /* set minimum height for single line. */
}

void ElidedLabel::setText(const QString &newText)
{
  content = newText;
  update();
}

void ElidedLabel::paintEvent(QPaintEvent *event)
{
  QFrame::paintEvent(event);
  QPainter painter(this);
  QFontMetrics fontMetrics = painter.fontMetrics();
  bool didElide = false;
  int lineSpacing = fontMetrics.lineSpacing();
  int y = 0;
  QTextLayout textLayout(content, painter.font());
  textLayout.beginLayout();
  forever {
    QTextLine line = textLayout.createLine();
    if (!line.isValid())
      break;

    line.setLineWidth(width());
    int nextLineY = y + lineSpacing;
    if (height() >= nextLineY + lineSpacing)
    {
      line.draw(&painter, QPoint(0, y));
      y = nextLineY;
    }
    else
    {
      QString lastLine = content.mid(line.textStart());
      QString elidedLastLine = fontMetrics.elidedText(lastLine, mElideMode, width());
      if (y == 0) y = height() / 6;
      painter.drawText(QPoint(2, y + fontMetrics.ascent()), elidedLastLine);
      line = textLayout.createLine();
      didElide = line.isValid();
      break;
    }
  }
  textLayout.endLayout();
  if (didElide != elided)
  {
    elided = didElide;
    emit elisionChanged(didElide);
  }
}
