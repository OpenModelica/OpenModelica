#include "Shapes.h"

Shapes::Shapes(QWidget *parent):QWidget(parent)
{
        label = new QLabel(this);

        shape.label = new QLabel(this);
        rubber_rect = new QRubberBand(QRubberBand::Rectangle,label);

        QImage image1(200,200,QImage::Format_ARGB32_Premultiplied);
        image=image1.copy(0,0,200,200);
        image.fill(qRgba(0,0,0,0));
        image2=image.copy(0,0,200,200);
        image2.fill(qRgba(0,0,0,0));

        state=0;

        rubber_state=false;
        button_state=false;
}

void Shapes::mousePressEvent(QMouseEvent *event)
{
    //cout<<"entered event\n ";
    //qDebug()<<event->pos().x();
    /*QImage image1(200,200,QImage::Format_ARGB32_Premultiplied);
    image=image1.copy(event->pos().x()+10,event->pos().y()+10,200,200);
    image.fill(qRgba(0,0,0,0));
    image2=image.copy(event->pos().x()+10,event->pos().y()+10,200,200);
    image2.fill(qRgba(0,0,0,0));*/

        if(event->button()==Qt::LeftButton)
        {
            strt_pnt=event->pos();
            button_state=true;
        }

        if(state==4&&rubber_state==false)
        {
           rubber_state=true;
           button_state=true;
        }
}

void Shapes::mouseMoveEvent(QMouseEvent *event)
{
    QPainter painter1;
    QPoint pnt;
    //image.fill(qRgba(0,0,0,0));
    //pnt=event->pos();
    if( button_state==true)
        {

           last_pnt=event->pos();
           if(state==1)
           {
              image.fill(qRgb(255,255,255));
              painter1.begin(&image);
                  painter1.setRenderHint(QPainter::Antialiasing);
                  painter1.drawLine(strt_pnt.x(),strt_pnt.y(),last_pnt.x(),last_pnt.y());
                  painter1.end();
                  update();
                  QPixmap pixmap1;
                  pixmap1=pixmap1.fromImage(image,0x000000);
                  label->setPixmap(pixmap1);
                  label->show();
           }

           if(state==2)
           {

              //if(last_pnt!=pnt)
              {
                  image.fill(qRgb(255,255,255));
                  //update();
                  //cout<<"entered\n";
                  painter1.begin(&image);
                  painter1.setRenderHint(QPainter::Antialiasing);
                  painter1.drawRect(strt_pnt.x(),strt_pnt.y(),last_pnt.x()-strt_pnt.x(),last_pnt.y()-strt_pnt.y());
                  painter1.end();
                  update();
                  QPixmap pixmap1;
                  pixmap1=pixmap1.fromImage(image,0x000000);
                  label->setPixmap(pixmap1);
                  label->show();
              }
              pnt=last_pnt;
           }



           if(state==3)
           {
                  rubber_rect->setGeometry(QRect(strt_pnt,event->pos()).normalized());
                  rubber_rect->show();
                  label->show();
           }


           if(state==4 && rubber_state==true)
           {

              QLinearGradient gradient(0, 0, 0, image.height()-1);
              gradient.setColorAt(0.0, Qt::white);
              gradient.setColorAt(0.2, QColor(255, 255, 255));
              gradient.setColorAt(0.8, QColor(255, 255, 255));
              gradient.setColorAt(1.0, QColor(255, 255, 255));

              painter1.begin(&image);
                  painter1.setRenderHint(QPainter::Antialiasing);
                  painter1.setBrush(gradient);
                  painter1.drawRect(last_pnt.x(),strt_pnt.y(),last_pnt.x()-strt_pnt.x(),last_pnt.y()-strt_pnt.y());
                  painter1.end();

                  QPixmap pixmap1;
                  pixmap1=pixmap1.fromImage(image,0x000000);
                  label->setPixmap(pixmap1);
                  label->show();

           }

        }

}

void Shapes::mouseReleaseEvent(QMouseEvent *event)
{
    QPainter painter1;
    //image.fill(qRgba(0,0,0,0));
    if(event->button()==Qt::LeftButton)
        {
           last_pnt=event->pos();
           button_state=false;
           rubber_state=false;
           if(state==1)
           {
                  painter1.begin(&image);
                  painter1.setRenderHint(QPainter::Antialiasing);
                  painter1.drawLine(strt_pnt.x(),strt_pnt.y(),last_pnt.x(),last_pnt.y());
                  painter1.end();

                  QPixmap pixmap1;
                  pixmap1=pixmap1.fromImage(image,0x000000);
                  label->setPixmap(pixmap1);
                  label->show();
           }

           if(state==2)
           {
              image.fill(qRgb(255,255,255));
              image2=image.copy(0,0,200,200);
              painter1.begin(&image2);
              painter1.setRenderHint(QPainter::Antialiasing);
              painter1.drawRect(strt_pnt.x(),strt_pnt.y(),last_pnt.x()-strt_pnt.x(),last_pnt.y()-strt_pnt.y());
              painter1.end();
              update();
              QPixmap pixmap1;
              pixmap1=pixmap1.fromImage(image2,0x000000);
              label->setPixmap(pixmap1);
              label->show();
              label->update();
              shape.label=label;
              shape.start_x=strt_pnt.x();
              shape.start_y=strt_pnt.y();
              shape.end_x=last_pnt.x()-strt_pnt.x();
              shape.end_y=last_pnt.y()-strt_pnt.y();
              shapes.push_back(shape);



          }

           if(state==3)
           {
                  rubber_rect->setGeometry(QRect(strt_pnt,event->pos()).normalized());
                  rubber_rect->show();
                  label->show();
       }

           if(state==4 && rubber_state==true)
           {
              rubber_state=false;
           }
        }


}

void Shapes::draw_rect()
{
    //cout<<"entered\n";
    state=2;
        QPainter painter1;


        painter1.begin(&image);
        painter1.setRenderHint(QPainter::Antialiasing);
        painter1.drawRect(1,1,1,1);
        painter1.end();

        QPixmap pixmap1;
        pixmap1=pixmap1.fromImage(image,0x000000);
        label->setPixmap(pixmap1);
        label->hide();



}

void Shapes::draw_line()
{
    state=1;
    QPainter painter1;


        painter1.begin(&image);
        painter1.setRenderHint(QPainter::Antialiasing);
        painter1.drawLine(1,1,1,1);
        painter1.end();

        QPixmap pixmap1;
        pixmap1=pixmap1.fromImage(image,0x000000);
        label->setPixmap(pixmap1);
        label->hide();
}

void Shapes::draw_rubber_rect()
{
    state=3;
    rubber_rect = new QRubberBand(QRubberBand::Rectangle,label);
}

void Shapes::draw_rubber()
{
     state=4;

     QPainter painter1;

     QLinearGradient gradient(0, 0, 0, image.height()-1);
     gradient.setColorAt(0.0, Qt::white);
     gradient.setColorAt(0.2, QColor(255, 255, 255));
     gradient.setColorAt(0.8, QColor(255, 255, 255));
     gradient.setColorAt(1.0, QColor(255, 255, 255));


     painter1.begin(&image);
     painter1.setRenderHint(QPainter::Antialiasing);
     painter1.setBrush(gradient);
     painter1.drawRect(1,10,1,10);
     painter1.end();

     QPixmap pixmap1;
     pixmap1=pixmap1.fromImage(image,0x000000);
     label->setPixmap(pixmap1);
     label->hide();

}

void Shapes::paintEvent(QPaintEvent *event)
{
       //last_pnt=event->pos();

       /*QPainter painter1;
           if(state==1)
           {
              painter1.begin(&image);
                  painter1.setRenderHint(QPainter::Antialiasing);
                  painter1.drawLine(strt_pnt.x(),strt_pnt.y(),last_pnt.x(),last_pnt.y());
                  painter1.end();

                  QPixmap pixmap1;
                  pixmap1=pixmap1.fromImage(image,0x000000);
                  label->setPixmap(pixmap1);
                  label->show();
           }

           if(state==2)
           {
                  painter1.begin(&image);
                  painter1.setRenderHint(QPainter::Antialiasing);
                  painter1.drawRect(strt_pnt.x(),strt_pnt.y(),last_pnt.x()-strt_pnt.x(),last_pnt.y()-strt_pnt.y());
                  painter1.end();
                  QPixmap pixmap1;
              pixmap1=pixmap1.fromImage(image,0x000000);
                  label->setPixmap(pixmap1);
                  label->show();
           }



           if(state==3)
           {
                  rubber_rect->setGeometry(QRect(strt_pnt,last_pnt).normalized());
                  rubber_rect->show();
                  label->show();
           }


           if(state==4 && rubber_state==true)
           {

              QLinearGradient gradient(0, 0, 0, image.height()-1);
              gradient.setColorAt(0.0, Qt::white);
              gradient.setColorAt(0.2, QColor(255, 255, 255));
              gradient.setColorAt(0.8, QColor(255, 255, 255));
              gradient.setColorAt(1.0, QColor(255, 255, 255));

              painter1.begin(&image);
                  painter1.setRenderHint(QPainter::Antialiasing);
                  painter1.setBrush(gradient);
                  painter1.drawRect(last_pnt.x(),strt_pnt.y(),last_pnt.x()-strt_pnt.x(),last_pnt.y()-strt_pnt.y());
                  painter1.end();

                  QPixmap pixmap1;
                  pixmap1=pixmap1.fromImage(image,0x000000);
                  label->setPixmap(pixmap1);
              label->show();
           }*/

}

