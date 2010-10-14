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
    this->mMessages << Helper::applicationName << Helper::applicationVersion << Helper::applicationIntroText;

    this->mPoints.append(QPointF(20, 100));
    this->mFonts.append(QFont("Helvetica", 50));
    this->mColors.append(QColor(213, 218, 220));

    this->mPoints.append(QPointF(30, 140));
    this->mFonts.append(QFont("Arial", 20));
    this->mColors.append(QColor(213, 218, 220));

    this->mPoints.append(QPointF(98, 322));
    this->mFonts.append(QFont("Verdana", 21));
    this->mColors.append(QColor(Qt::white));

    repaint();
}

void SplashScreen::mousePressEvent(QMouseEvent *event)
{
    Q_UNUSED(event);
}

void SplashScreen::drawContents(QPainter *painter)
{
    painter->setFont(this->mFonts.at(0));
    painter->setPen(this->mColors.at(0));
    painter->drawText(this->mPoints.at(0), this->mMessages.at(0));

    painter->setFont(this->mFonts.at(1));
    painter->setPen(this->mColors.at(1));
    painter->drawText(this->mPoints.at(1), this->mMessages.at(1));

    painter->setFont(this->mFonts.at(2));
    painter->setPen(this->mColors.at(2));
    painter->drawText(this->mPoints.at(2), this->mMessages.at(2));

    painter->setFont(QFont("Verdana", 9));
    QSplashScreen::drawContents(painter);
}
