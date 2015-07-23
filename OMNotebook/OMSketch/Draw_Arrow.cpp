#include "Draw_Arrow.h"

Draw_Arrow::Draw_Arrow()
{
    draw_state=0;
    draw_mode=false;

    pen =  QPen();
    pen.setColor(QColor(0,0,0));
    pen.setStyle(Qt::SolidLine);
    pen.setWidth(1);

    brush = QBrush();
    brush.setColor(QColor(255,255,255));
    brush.setStyle(Qt::NoBrush);

    click=0;
    angle=0.0;

  isObjectSelected=false;

  handles.clear();

    arrow_pnts.clear();
    arrow_pnts.resize(8);

}

void Draw_Arrow::setStartPoint(QPointF strt_pnt)
{
    StrtPnt=strt_pnt;
}

void Draw_Arrow::setEndPoint(QPointF lst_pnt)
{
    EndPnt=lst_pnt;
}


QPointF Draw_Arrow::getStartPnt()
{
    return StrtPnt;
}

QPointF Draw_Arrow::getEndPnt()
{
    return EndPnt;
}

QPointF Draw_Arrow::getRectstartPnt()
{
    QPointF pnt;
    pnt.setX(StrtPnt.x()-6.0);
    pnt.setY(StrtPnt.y()-2.5);
    return pnt;
}

QPointF Draw_Arrow::getRectendPnt()
{
    QPointF pnt;
    pnt.setX(EndPnt.x()+1.0);
    pnt.setY(EndPnt.y()-2.5);
    return pnt;
}

void Draw_Arrow::setEdgeRects()
{
    QBrush rectbrush;
    rectbrush.setColor(QColor(0,175,225));
    rectbrush.setStyle(Qt::SolidPattern);
    qDebug()<<"strt pnt "<<StrtPnt<<" "<<"end pnt "<<EndPnt<<"\n";

  QPointF pnt,pnt1;

  //arrow pnts
  //pnt1-------pnt2---------pnt3
  //pnt8                    pnt4
  //pnt7------pnt6----------pnt5

  pnt=item->boundingRect().topLeft();

  QGraphicsRectItem *rect = new QGraphicsRectItem(QRectF(QPointF(pnt.x()-5.0,pnt.y()-5.0),QPointF(pnt.x()+5.0,pnt.y()+5.0)));
    rect->setBrush(rectbrush);
  //pnt1
  handles.push_back(rect);

  pnt1=item->boundingRect().topRight();

  rect = new QGraphicsRectItem(QRectF(QPointF((pnt.x()+pnt1.x())/2-5.0,pnt.y()-5.0),QPointF((pnt.x()+pnt1.x())/2+5.0,pnt.y()+5.0)));
    rect->setBrush(rectbrush);
  //pnt2
  handles.push_back(rect);


  rect = new QGraphicsRectItem(QRectF(QPointF((pnt1.x()+pnt1.x())/2-5.0,pnt1.y()-5.0),QPointF((pnt1.x()+pnt1.x())/2+5.0,pnt1.y()+5.0)));
    rect->setBrush(rectbrush);

  //pnt3
  handles.push_back(rect);

  pnt=item->boundingRect().topRight();
  pnt1=item->boundingRect().bottomRight();

  rect = new QGraphicsRectItem(QRectF(QPointF(pnt.x()-5.0,(pnt.y()+pnt1.y())/2-5.0),QPointF(pnt1.x()+5.0,(pnt.y()+pnt1.y())/2+5.0)));
    rect->setBrush(rectbrush);

  //pnt4
  handles.push_back(rect);

  rect = new QGraphicsRectItem(QRectF(QPointF(pnt1.x()-5.0,pnt1.y()-5.0),QPointF(pnt1.x()+5.0,pnt1.y()+5.0)));
    rect->setBrush(rectbrush);

  //pnt5
  handles.push_back(rect);

  pnt=item->boundingRect().bottomLeft();

  rect = new QGraphicsRectItem(QRectF(QPointF((pnt.x()+pnt1.x())/2-5.0,pnt1.y()-5.0),QPointF((pnt.x()+pnt1.x())/2+5.0,pnt1.y()+5.0)));
    rect->setBrush(rectbrush);

  //pnt6
  handles.push_back(rect);

  rect = new QGraphicsRectItem(QRectF(QPointF(pnt.x()-5.0,pnt.y()-5.0),QPointF(pnt.x()+5.0,pnt.y()+5.0)));
    rect->setBrush(rectbrush);
  //pnt7
  handles.push_back(rect);

  pnt=item->boundingRect().topLeft();
  pnt1=item->boundingRect().bottomLeft();

  rect = new QGraphicsRectItem(QRectF(QPointF(pnt.x()-5.0,(pnt.y()+pnt1.y())/2-5.0),QPointF(pnt1.x()+5.0,(pnt.y()+pnt1.y())/2+5.0)));
    rect->setBrush(rectbrush);

  //pnt8
  handles.push_back(rect);


    QPen bound_rect;
    bound_rect.setStyle(Qt::DashLine);
    Bounding_Rect = new QGraphicsRectItem(QRectF(item->boundingRect().topLeft(),item->boundingRect().bottomRight()));
    Bounding_Rect->setPen(bound_rect);

    QPointF pnt2;

    pnt1.setX(((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2)-5);
    pnt1.setY(item->boundingRect().topLeft().y()-20);

    pnt2.setX(((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2)+5);
    pnt2.setY(item->boundingRect().topLeft().y()-10);

    Rot_Rect = new QGraphicsEllipseItem(QRectF(pnt1,pnt2));
    Rot_Rect->setBrush(rectbrush);
}

void Draw_Arrow::updateEdgeRects()
{

  QPointF pnt,pnt1;

  pnt=item->boundingRect().topLeft();

  handles[0]->setRect(QRectF(QPointF(pnt.x()-5.0,pnt.y()-5.0),QPointF(pnt.x()+5.0,pnt.y()+5.0)));

  pnt1=item->boundingRect().topRight();

  handles[1]->setRect(QRectF(QPointF((pnt.x()+pnt1.x())/2-5.0,pnt.y()-5.0),QPointF((pnt.x()+pnt1.x())/2+5.0,pnt.y()+5.0)));


  handles[2]->setRect(QRectF(QPointF((pnt1.x()+pnt1.x())/2-5.0,pnt1.y()-5.0),QPointF((pnt1.x()+pnt1.x())/2+5.0,pnt1.y()+5.0)));

  pnt=item->boundingRect().topRight();
  pnt1=item->boundingRect().bottomRight();

  handles[3]->setRect(QRectF(QPointF(pnt.x()-5.0,(pnt.y()+pnt1.y())/2-5.0),QPointF(pnt1.x()+5.0,(pnt.y()+pnt1.y())/2+5.0)));

  handles[4]->setRect(QRectF(QPointF(pnt1.x()-5.0,pnt1.y()-5.0),QPointF(pnt1.x()+5.0,pnt1.y()+5.0)));

  pnt=item->boundingRect().bottomLeft();

  handles[5]->setRect(QRectF(QPointF((pnt.x()+pnt1.x())/2-5.0,pnt1.y()-5.0),QPointF((pnt.x()+pnt1.x())/2+5.0,pnt1.y()+5.0)));

  handles[6]->setRect(QRectF(QPointF(pnt.x()-5.0,pnt.y()-5.0),QPointF(pnt.x()+5.0,pnt.y()+5.0)));

  pnt=item->boundingRect().topLeft();
  pnt1=item->boundingRect().bottomLeft();

  handles[7]->setRect(QRectF(QPointF(pnt.x()-5.0,(pnt.y()+pnt1.y())/2-5.0),QPointF(pnt1.x()+5.0,(pnt.y()+pnt1.y())/2+5.0)));



    Bounding_Rect->setRect(QRectF(item->boundingRect().topLeft(),item->boundingRect().bottomRight()));

    QPointF pnt2;

    pnt1.setX(((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2)-5);
    pnt1.setY(item->boundingRect().topLeft().y()-20);

    pnt2.setX(((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2)+5);
    pnt2.setY(item->boundingRect().topLeft().y()-10);

    Rot_Rect->setRect(QRectF(pnt1,pnt2));
  //Strt_Rect->update();
  //End_Rect->update();
  Rot_Rect->update();

}

QPointF Draw_Arrow::getBoundMinPnt()
{
    return bounding_min_pnt;
}

QPointF Draw_Arrow::getBoundMaxPnt()
{
    return bounding_max_pnt;
}


void Draw_Arrow::setState(int state)
{
    draw_state=state;
}

int Draw_Arrow::getState()
{
    return draw_state;
}

void Draw_Arrow::setMode(bool mode)
{
    draw_mode=mode;
}

bool Draw_Arrow::getMode()
{
    return draw_mode;
}

bool Draw_Arrow::isMouseClickedOnHandle(QPointF pnt)
{
    bool found=false;

    for(int i=0;i<handles.size();i++)
    {
        if(handles[i]->isUnderMouse()) {
            draw_state=1;
            handle_index=i;
            qDebug()<<"handle index "<<handle_index<<"\n";
            handles[i]->setCursor(Qt::CrossCursor);
            found=true;
            break;
        }
    }

    return found;

}

bool Draw_Arrow::isMouseClickedOnEndHandle(QPointF pnt)
{

    if(this->End_Rect->isUnderMouse())
    {
        draw_state=2;
        return true;
    }
    else
        return false;

}



bool Draw_Arrow::isMouseClickedOnRotateHandle(const QPointF pnt)
{

    if(Rot_Rect->isUnderMouse())
    {
        draw_state=4;
        QPointF pnt1;
        pnt1.setX((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2);
        pnt1.setY((item->boundingRect().topLeft().y()+item->boundingRect().bottomRight().y())/2);
        item->setTransformOriginPoint(pnt1);
        Strt_Rect->setTransformOriginPoint(pnt1);
        End_Rect->setTransformOriginPoint(pnt1);
        Rot_Rect->setTransformOriginPoint(pnt1);
        Bounding_Rect->setTransformOriginPoint(pnt1);
        return true;
    }
    else
        return false;
}

bool Draw_Arrow::isMouseClickedOnShape(const QPointF pnt)
{
    if(item->isUnderMouse())
    {
        draw_state=3;
        item->setCursor(Qt::SizeAllCursor);
        return true;
    }
    else
        return false;
}

void Draw_Arrow::BoundingBox()
{
    /*bounding_min_pnt.setX(rect_strt_pnt.x());
    bounding_min_pnt.setY(rect_strt_pnt.y()-2.5);
    bounding_max_pnt.setX(rect_end_pnt.x());
    bounding_max_pnt.setY(rect_end_pnt.y()+5.0);*/
}

QColor Draw_Arrow::getPenColor()
{
   return pen.color();
}

void Draw_Arrow::setTranslate(QPointF pnt,QPointF pnt1)
{
  if(getState()==1)
  {
       if(handle_index==0)
     {
       qDebug()<<"diiff y "<<pnt1<<"\n";
       arrow_pnts[0]=pnt1;
       arrow_pnts[1]=QPointF(arrow_pnts[1].x(),pnt1.y());
       arrow_pnts[2]=QPointF(arrow_pnts[2].x(),pnt1.y()-25);
       arrow_pnts[3]=QPointF(arrow_pnts[3].x(),(arrow_pnts[0].y()+arrow_pnts[6].y())/2);
       //arrow_pnts[4]=QPointF(arrow_pnts[4].x(),(arrow_pnts[4].y()-pnt1.y())+25);
       //arrow_pnts[5]=QPointF(pnt1.x()+75,arrow_pnts[5].y()+25);
       arrow_pnts[6]=QPointF(pnt1.x(),(arrow_pnts[6].y()));
       arrow_pnts[7]=pnt1;
     }
       if(handle_index==7)
       {
          arrow_pnts[0]=QPointF(pnt1.x(),arrow_pnts[0].y());
      arrow_pnts[6]=QPointF(pnt1.x(),arrow_pnts[6].y());
      arrow_pnts[7]=QPointF(pnt1.x(),arrow_pnts[7].y());
       }

     if(handle_index==3)
       {
          arrow_pnts[1]=QPointF(pnt1.x()-25,arrow_pnts[1].y());
      arrow_pnts[2]=QPointF(pnt1.x()-25,arrow_pnts[2].y());
      arrow_pnts[3]=QPointF(pnt1.x(),arrow_pnts[3].y());
      arrow_pnts[4]=QPointF(pnt1.x()-25,arrow_pnts[4].y());
      arrow_pnts[5]=QPointF(pnt1.x()-25,arrow_pnts[5].y());
     }
  }



    if(draw_state==3)
    {

       item->setPos(item->pos()-(pnt-pnt1));
       Strt_Rect->setPos(Strt_Rect->pos()-(pnt-pnt1));
       End_Rect->setPos(End_Rect->pos()-(pnt-pnt1));
       Rot_Rect->setPos(Rot_Rect->pos()-(pnt-pnt1));
       Bounding_Rect->setPos(Bounding_Rect->pos()-(pnt-pnt1));
       item->update();
       Strt_Rect->update();
       End_Rect->update();
     Rot_Rect->update();
     Bounding_Rect->update();


    }


}


void Draw_Arrow::setRotate(const QPointF &pnt,const QPointF &pnt1)
{

    if(pnt1.x()>pnt.x())
    {
       angle+=0.5;
       item->setRotation(angle);
       Strt_Rect->setRotation(angle);
       End_Rect->setRotation(angle);
       Rot_Rect->setRotation(angle);
       Bounding_Rect->setRotation(angle);
    }

    if(pnt.x()>pnt1.x())
    {
       angle-=0.5;
       item->setRotation(angle);
       Strt_Rect->setRotation(angle);
       End_Rect->setRotation(angle);
       Rot_Rect->setRotation(angle);
       Bounding_Rect->setRotation(angle);
    }

    item->update();
    Strt_Rect->update();
    End_Rect->update();
    Rot_Rect->update();
    Bounding_Rect->update();


    QPointF rot_pnt(item->boundingRect().topLeft()-item->sceneBoundingRect().topLeft());
    QPointF rot_pnt1(item->boundingRect().bottomRight()-item->sceneBoundingRect().bottomRight());

    setStartPoint(item->sceneBoundingRect().topLeft()+rot_pnt);
    setEndPoint(item->sceneBoundingRect().bottomRight()+rot_pnt1);


}

void Draw_Arrow::setScale(float x,float y)
{
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
   item->setTransform(QTransform::fromScale(x, y), true);
#else
   item->scale(x,y);
#endif
}

QPainterPath Draw_Arrow::getArrow()
{
    QPainterPath arrow;

    if(!draw_mode)
    {
       QPointF pnt;

       arrow_pnts[0]=StrtPnt;

       pnt.setX(StrtPnt.x()+75);
       pnt.setY(StrtPnt.y());

       arrow_pnts[1]=pnt;

       pnt.setX(StrtPnt.x()+75);
       pnt.setY(StrtPnt.y()-25);

       arrow_pnts[2]=pnt;

       pnt.setX(StrtPnt.x()+100);
       pnt.setY(StrtPnt.y()+25);

       arrow_pnts[3]=pnt;

       pnt.setX(StrtPnt.x()+75);
       pnt.setY(StrtPnt.y()+75);

       arrow_pnts[4]=pnt;

       pnt.setX(StrtPnt.x()+75);
       pnt.setY(StrtPnt.y()+50);

       arrow_pnts[5]=pnt;


       pnt.setX(StrtPnt.x());
       pnt.setY(StrtPnt.y()+50);

       arrow_pnts[6]=pnt;

       arrow_pnts[7]=StrtPnt;

       arrow.moveTo(StrtPnt.x(),StrtPnt.y());
       arrow.addPolygon(QPolygonF(arrow_pnts));

       pnt.setX(StrtPnt.x()+75);
       pnt.setY(StrtPnt.y()+25);
       EndPnt=pnt;

       pnt.setX(StrtPnt.x());
       pnt.setY(StrtPnt.y()-25);
       StrtPnt=pnt;

   }

    if(draw_mode)
    {
        arrow.addPolygon(QPolygonF(arrow_pnts));
    return arrow;
    }

    return arrow;
}

QPainterPath Draw_Arrow::drawArrow()
{
  QPainterPath arrow;

  if(!arrow_pnts.isEmpty())
  {
    arrow.addPolygon(arrow_pnts);
    return arrow;
  }

  return arrow;
}


void Draw_Arrow::updateArrowPoints(QPointF updatePoint)
{

     QPointF pnt,pnt1;

     pnt1=updatePoint;

       arrow_pnts[0]=pnt1;

       pnt.setX(pnt1.x()+25);
       pnt.setY(pnt1.y());

       arrow_pnts[1]=pnt;

       pnt.setX(pnt1.x()+25);
       pnt.setY(pnt1.y()-25);

       arrow_pnts[2]=pnt;

       pnt.setX(pnt1.x()+50);
       pnt.setY(pnt1.y()+25);

       arrow_pnts[3]=pnt;

       pnt.setX(pnt1.x()+25);
       pnt.setY(pnt1.y()+75);

       arrow_pnts[4]=pnt;

       pnt.setX(pnt1.x()+25);
       pnt.setY(pnt1.y()+50);

       arrow_pnts[5]=pnt;


       pnt.setX(pnt1.x());
       pnt.setY(pnt1.y()+50);

       arrow_pnts[6]=pnt;

       arrow_pnts[7]=pnt1;


       pnt.setX(pnt1.x()+50);
       pnt.setY(pnt1.y()+75);
       EndPnt=pnt;

       pnt.setX(pnt1.x());
       pnt.setY(pnt1.y()-25);
       StrtPnt=pnt;
     //updateEdgeRects();

     //Strt_Rect->setRect(QRectF(QPointF(StrtPnt.x()-5.0,StrtPnt.y()-5.0),QPointF(StrtPnt.x()+5.0,StrtPnt.y()+5.0)));

       //End_Rect->setRect(QRectF(QPointF(EndPnt.x()-5.0,EndPnt.y()-5.0),QPointF(EndPnt.x()+5.0,EndPnt.y()+5.0)));
}

void Draw_Arrow::drawImage(QPainter *painter,QString &text,QPointF point)
{
    QPainterPath arrow;

    QString str_x,str_y,str_x1,str_y1;
    QString color_r,color_g,color_b;

  QPointF pnt;

  QVector<QPointF> pnts(arrow_pnts.size());

  /*if(item->pos()!=QPointF(0,0))
  {
    StrtPnt=item->sceneBoundingRect().topLeft();
    arrow_pnts[0]=StrtPnt;

      pnt.setX(StrtPnt.x()+25);
      pnt.setY(StrtPnt.y());

      arrow_pnts[1]=pnt;

      pnt.setX(StrtPnt.x()+25);
      pnt.setY(StrtPnt.y()-25);

      arrow_pnts[2]=pnt;

      pnt.setX(StrtPnt.x()+50);
      pnt.setY(StrtPnt.y()+25);

      arrow_pnts[3]=pnt;

      pnt.setX(StrtPnt.x()+25);
      pnt.setY(StrtPnt.y()+75);

      arrow_pnts[4]=pnt;

      pnt.setX(StrtPnt.x()+25);
      pnt.setY(StrtPnt.y()+50);

      arrow_pnts[5]=pnt;


     pnt.setX(StrtPnt.x());
     pnt.setY(StrtPnt.y()+50);

     arrow_pnts[6]=pnt;

     arrow_pnts[7]=StrtPnt;

   EndPnt=item->sceneBoundingRect().bottomRight();
  }*/


  for(int i=0;i<pnts.size();i++)
  {
    qDebug()<<"arrow pnts "<<arrow_pnts[i]<<"\n";
    pnts[i]=arrow_pnts[i];
    pnts[i]+=point;
  }

        painter->setPen(this->pen);
        painter->setBrush(this->brush);
        arrow.addPolygon(QPolygonF(pnts));
        painter->drawPath(arrow);
        text+="Arrow\n";
        text+="Coords";

        text+=" "+str_x.setNum(arrow_pnts.size()*2);

    qDebug()<<"number of points "<<arrow_pnts.size()*2<<"\n";

        for(int j=0;j<this->arrow_pnts.size();j++)
        {
           text+=" "+str_x.setNum((arrow_pnts[j].x()))+" "+str_y.setNum((arrow_pnts[j].y()))+" ";
        }


        text+="PenColor";
        text+=" "+color_r.setNum(this->pen.color().red())+" "+color_g.setNum(this->pen.color().green())+" "+color_b.setNum(this->pen.color().blue())+"\n";
        text+="PenStyle";
        text+=" "+color_r.setNum(this->pen.style())+"\n";
        text+="PenWidth";
        text+=" "+color_r.setNum(this->pen.width())+"\n";
        text+="BrushColor";
        text+=" "+color_r.setNum(this->brush.color().red())+" "+color_g.setNum(this->brush.color().green())+" "+color_b.setNum(this->brush.color().blue())+"\n";
        text+="BrushStyle";
        text+=" "+color_r.setNum(this->brush.style())+"\n";

    text+="Rotation";
      text+=" "+color_r.setNum(this->item->rotation(),'g',6)+"\n";




}


void Draw_Arrow::setPen(const QColor color)
{
    this->pen=item->pen();
    this->pen.setColor(color);
    item->setPen(pen);
}

void Draw_Arrow::setPenStyle(const int style)
{
    this->pen=item->pen();
    switch(style)
    {
      case 1:
          this->pen.setStyle(Qt::SolidLine);
          item->setPen(pen);
         break;
      case 2:
          this->pen.setStyle(Qt::DashLine);
          item->setPen(pen);
          break;
      case 3:
          this->pen.setStyle(Qt::DashLine);
          item->setPen(pen);
          break;
      case 4:
          this->pen.setStyle(Qt::DashDotLine);
          item->setPen(pen);
          break;
      case 5:
          this->pen.setStyle(Qt::DashDotDotLine);
          item->setPen(pen);
          break;
    default:
          break;
    }

}

void Draw_Arrow::setPenWidth(const int width)
{
    this->pen=item->pen();
    this->pen.setWidth(width);
    item->setPen(pen);
}

QPen Draw_Arrow::getPen()
{
    return item->pen();
}

void Draw_Arrow::setBrush(const QBrush brush)
{
     this->brush=item->brush();
     this->brush.setColor(brush.color());
     item->setBrush(this->brush);
}

void Draw_Arrow::setBrushStyle(const int style)
{
    this->brush=item->brush();
    /*QLinearGradient lgradient(50, 50, 50, 50);
    QRadialGradient rgradient(50, 50, 50, 50,50);
    QConicalGradient cgradient(50, 50, 30);*/
    switch(style)
    {
      case 0:
         this->brush=item->brush();
         this->brush.setStyle(Qt::NoBrush);
         item->setBrush(brush);
         break;
      case 1:
         brush.setStyle(Qt::SolidPattern);
         item->setBrush(brush);
         break;
      case 2:
         brush.setStyle(Qt::Dense1Pattern);
         item->setBrush(brush);
         break;
      case 3:
         brush.setStyle(Qt::Dense2Pattern);
         item->setBrush(brush);
         break;
      case 4:
         brush.setStyle(Qt::Dense3Pattern);
         item->setBrush(brush);
         break;
      case 5:
         brush.setStyle(Qt::Dense4Pattern);
         item->setBrush(brush);
         break;
      case 6:
         brush.setStyle(Qt::Dense5Pattern);
         item->setBrush(brush);
         break;
      case 7:
         brush.setStyle(Qt::Dense6Pattern);
         item->setBrush(brush);
         break;
      case 8:
         brush.setStyle(Qt::Dense7Pattern);
         item->setBrush(brush);
         break;
      case 9:
         brush.setStyle(Qt::HorPattern);
         item->setBrush(brush);
         break;
      case 10:
         brush.setStyle(Qt::VerPattern);
         item->setBrush(brush);
         break;
      case 11:
         brush.setStyle(Qt::CrossPattern);
         item->setBrush(brush);
         break;
      case 12:
         brush.setStyle(Qt::BDiagPattern);
         item->setBrush(brush);
         break;
      case 13:
         brush.setStyle(Qt::FDiagPattern);
         item->setBrush(brush);
         break;
      case 14:
         brush.setStyle(Qt::DiagCrossPattern);
         item->setBrush(brush);
         break;
      /*case 15:
         lgradient.setColorAt(0, QColor::fromRgbF(item->brush().color().redF(),item->brush().color().greenF(),item->brush().color().blueF(),1.0));
         lgradient.setColorAt(1, QColor::fromRgbF(0, 0, 0, 0));
         this->brush=QBrush(lgradient);
         item->setBrush(brush);
         break;
      case 16:
         rgradient.setColorAt(0, item->brush().color());
         rgradient.setColorAt(1, QColor::fromRgbF(0, 0, 0, 0));
         this->brush=QBrush(rgradient);
         item->setBrush(brush);
         break;
      case 17:
         cgradient.setColorAt(0, item->brush().color());
         cgradient.setColorAt(1, QColor::fromRgbF(0, 0, 0, 0));
         this->brush=QBrush(cgradient);
         item->setBrush(brush);
         break;*/
      default:
         break;
    }

}

QBrush Draw_Arrow::getBrush()
{
        return brush;
}


void Draw_Arrow::showHandles()
{

  for(int i=0;i<handles.size();i++)
  {
    if(!handles[i]->isVisible())
      handles[i]->show();
  }

  if(!Rot_Rect->isVisible())
    Rot_Rect->show();
}

void Draw_Arrow::hideHandles()
{
  for(int i=0;i<handles.size();i++)
  {
    if(handles[i]->isVisible())
      handles[i]->hide();
  }
    if(Rot_Rect->isVisible())
        Rot_Rect->hide();
}


bool Draw_Arrow::isClickedOnHandleOrShape(QPointF point)
{
  if(getMode())
    {
        if(isMouseClickedOnHandle(point))
            return true;
        else if(isMouseClickedOnShape(point))
            return true;
        else if(isMouseClickedOnRotateHandle(point))
            return true;
    }

    return false;
}

void Draw_Arrow::rotateShape(float angle)
{

   item->setRotation(angle);
     Strt_Rect->setRotation(angle);
     End_Rect->setRotation(angle);
     Rot_Rect->setRotation(angle);
     Bounding_Rect->setRotation(angle);

   item->update();
     Strt_Rect->update();
     End_Rect->update();
   Rot_Rect->update();
   Bounding_Rect->update();

  QPointF pnt1;
    pnt1.setX((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2);
    pnt1.setY((item->boundingRect().topLeft().y()+item->boundingRect().bottomRight().y())/2);
    item->setTransformOriginPoint(pnt1);
    Strt_Rect->setTransformOriginPoint(pnt1);
    End_Rect->setTransformOriginPoint(pnt1);
    Rot_Rect->setTransformOriginPoint(pnt1);
    Bounding_Rect->setTransformOriginPoint(pnt1);
}

void Draw_Arrow::print()
{
    qDebug()<<"Starting and Ending  points of line"<<getStartPnt()<<"  "<<getEndPnt()<<"\n";
}
