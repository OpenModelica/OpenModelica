/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 *
 */

/*
 * RCS: $Id$
 */

#include "SplashScreen.h"
#include "Helper.h"

SplashScreen::SplashScreen(QPixmap pixmap)
  : QSplashScreen(pixmap)
{

}

SplashScreen::~SplashScreen()
{

}

void SplashScreen::setMessage()
{
  mMessages << Helper::applicationName << Helper::applicationVersion << Helper::applicationIntroText;
  // co-ordinates, font and colot for message 1
  mPoints.append(QPointF(20, 100));
  mFonts.append(QFont("Helvetica", 50));
  mColors.append(QColor(213, 218, 220));
  // co-ordinates, font and colot for message 2
  mPoints.append(QPointF(30, 140));
  mFonts.append(QFont("Helvetica", 18));
  mColors.append(QColor(213, 218, 220));
  // Font and colot for message 3
  mFonts.append(QFont("Helvetica", 21));
  mColors.append(QColor(Qt::white));
  // raise paint event
  repaint();
}

void SplashScreen::drawContents(QPainter *painter)
{
  // paint message 1
  painter->setFont(mFonts.at(0));
  painter->setPen(mColors.at(0));
  painter->drawText(mPoints.at(0), mMessages.at(0));
  // paint message 2
  painter->setFont(mFonts.at(1));
  painter->setPen(mColors.at(1));
  painter->drawText(mPoints.at(1), mMessages.at(1));
  // paint message 3
  painter->setFont(mFonts.at(2));
  painter->setPen(mColors.at(2));
  QRect r = rect();
  r.setRect(r.x(), r.y(), r.width(), r.height() -12);
  painter->drawText(r, Qt::AlignBottom | Qt::AlignCenter, mMessages.at(2));
  // reset the painter font for future messages
  painter->setFont(QFont("Verdana", 9));
  QSplashScreen::drawContents(painter);
}
