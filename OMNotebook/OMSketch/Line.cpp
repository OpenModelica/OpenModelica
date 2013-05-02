#include <QtGui>
#include <QDebug>
#include <QImage>
#include <QPainter>
#include <QPixmap>
#include <QLabel>
#include "Line.h"
#include <iostream>

using namespace std;

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
