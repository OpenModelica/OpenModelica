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

#include <QtGui>
#include <QDebug>
#include <QImage>
#include <QPainter>
#include <QPixmap>
#include <QLabel>
#include "Line.h"
#include <iostream>

Line::Line(QWidget *parent):QWidget(parent)
{
        label = new QLabel(this);

        QPainter painter1;

        QImage image1(100,100,QImage::Format_ARGB32_Premultiplied);
        image=image1.copy(0,0,100,100);
        image.fill(qRgba(0,0,0,0));
        painter1.begin(&image);
        painter1.setRenderHint(QPainter::Antialiasing);
        painter1.drawRect(1,1,1,1);
        painter1.end();

        QPixmap pixmap1;
        pixmap1=pixmap1.fromImage(image,0x000000);
        label->setPixmap(pixmap1);
        label->hide();
        added=false;

}

void Line::mousePressEvent(QMouseEvent *event)
{
    //cout<<"entered event\n ";
        if(event->button()==Qt::LeftButton)
        {
            strt_pnt=event->pos();
        }
        label->move(event->pos());
        strt1_pnt=event->pos();
        strt_pnt.setX(0);
        strt_pnt.setY(0);
        qDebug()<<"Started Points";
        qDebug()<<strt1_pnt.x()<<" "<<strt1_pnt.y();
}

void Line::mouseMoveEvent(QMouseEvent *event)
{
    QPainter painter1;
    last_pnt=event->pos();
    image.size().setWidth(last_pnt.x()-strt1_pnt.x());
    image.size().setHeight(last_pnt.y()-strt1_pnt.y());
    image.fill(qRgb(255,255,255));
    //if(event->button()==Qt::LeftButton)
        {

           painter1.begin(&image);
           painter1.setRenderHint(QPainter::Antialiasing);
           painter1.drawRect(strt_pnt.x(),strt_pnt.y(),last_pnt.x()-strt1_pnt.x(),last_pnt.y()-strt1_pnt.y());
           painter1.end();
           update();

           QPixmap pixmap1;
           pixmap1=pixmap1.fromImage(image,0x000000);
           label->setPixmap(pixmap1);
           label->show();
           //qDebug()<<"entered mouse move event\n";
        }

}

void Line::mouseReleaseEvent(QMouseEvent *event)
{
    QPainter painter1;
    last_pnt=event->pos();
    QImage image1(100,100,QImage::Format_ARGB32);
    image=image1.copy(0,0,last_pnt.x()-strt1_pnt.x(),last_pnt.y()-strt1_pnt.y());
    image.fill(qRgb(255,255,255));

    qDebug()<<last_pnt.x()-strt1_pnt.x()<<" "<<last_pnt.y()-strt1_pnt.y();
    if(event->button()==Qt::LeftButton)
        {
           last_pnt=event->pos();

           painter1.begin(&image);
           painter1.setRenderHint(QPainter::Antialiasing);
           painter1.drawRect(strt_pnt.x(),strt_pnt.y(),last_pnt.x()-strt1_pnt.x(),last_pnt.y()-strt1_pnt.y());
           painter1.end();

           QPixmap pixmap1;
           pixmap1=pixmap1.fromImage(image,0x000000);
           label->setPixmap(pixmap1);
           label->show();
         }
}

void Line::paintEvent(QPaintEvent *event)
{

}

void Line::draw_line()
{
    QPainter painter1;


        painter1.begin(&image);
        painter1.setRenderHint(QPainter::Antialiasing);
        painter1.drawRect(1,1,1,1);
        painter1.end();

        QPixmap pixmap1;
        pixmap1=pixmap1.fromImage(image,0x000000);
        label->setPixmap(pixmap1);

}

Line::~Line()
{
    delete label;
}
