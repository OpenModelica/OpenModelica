#include "Draw_Rectangle.h"

Draw_Rectangle::Draw_Rectangle(){
  draw_state=0;
  draw_mode=false;
  angle=0;
  //setFlag(QGraphicsItem::ItemIsSelectable,true);

  pen =  QPen();
  pen.setColor(QColor(0,0,0));
  pen.setStyle(Qt::SolidLine);
  pen.setWidth(1);

  brush = QBrush();
  brush.setColor(QColor(255,255,255));
  brush.setStyle(Qt::NoBrush);

  isObjectSelected=false;
}

void Draw_Rectangle::setStartPoint(QPointF strt_pnt) {
  StrtPnt=strt_pnt;
}

void Draw_Rectangle::setEndPoint(QPointF lst_pnt) {
  EndPnt=lst_pnt;
}

QPainterPath Draw_Rectangle::getRect(QPointF pnt,QPointF pnt1) {
  StrtPnt=pnt;
  EndPnt=pnt1;
  QPainterPath path;
  path.addRect(QRectF(StrtPnt,EndPnt));

  return path;
}

QPainterPath Draw_Rectangle::getRotRect(QPointF pnt,QPointF pnt1) {
  StrtPnt=pnt;
  EndPnt=pnt1;
  QPainterPath path;
  //qDebug()<<"roated point "<<pnt<<"\n";
  path.addRect(QRectF(pnt,EndPnt));
  //qDebug()<<"rectangle points "<<path.boundingRect().left()<<"  "<<path.boundingRect().bottom()<<"  "<<path.boundingRect().right()<<"\n";
  return path;
}

void Draw_Rectangle::drawImage(QPainter *painter,QString &text,QPointF point) {
    QString str_x,str_y,str_x1,str_y1;
    QString color_r,color_g,color_b;
  QPointF pnt,pnt1;

  if(item->rotation()==0)
  {
     //this->StrtPnt=item->sceneBoundingRect().topLeft();
     //this->EndPnt = item->sceneBoundingRect().bottomRight();
     pnt=this->StrtPnt;
     pnt1=this->EndPnt;

     pnt+=point;
       pnt1+=point;
  } else {
     pnt=item->boundingRect().topLeft();
     pnt1=item->boundingRect().bottomRight();

    //pnt = rotationStartPoint;
    //pnt1 = rotationEndPoint;

    /* pnt+=point;
       pnt1+=point;*/

     pnt+=point;
     pnt1+=point;
     qDebug()<<"rotation points "<<pnt<<"  "<<pnt1<<"\n";
  }

  //qDebug()<<"item points "<<item->boundingRect().topLeft()<<"  "<<item->boundingRect().bottomRight()<<"\n";
  //this->print();
    painter->setPen(this->pen);
    painter->setBrush(this->brush);

  painter->drawRect(pnt.x(),pnt.y(),pnt1.x()-pnt.x(),pnt1.y()-pnt.y());

  /*if(item->rotation() < 0 )
  {
    qDebug()<<"rot lesser \n";
    painter->translate(pnt1.x(),pnt1.y());
        painter->rotate(item->rotation());
    painter->translate(-pnt1.x()/2,-pnt1.y()/2);
    painter->drawRect(pnt.x(),pnt.y(),pnt1.x()-pnt.x(),pnt1.y()-pnt.y());

  }


  if(item->rotation()>0)
  {
    qDebug()<<"rot greater \n";
    painter->translate(pnt1.x(),pnt1.y());
        painter->rotate(item->rotation());
    painter->translate(-pnt1.x()/2,-pnt1.y()/2);
    painter->drawRect(pnt.x(),pnt.y(),pnt1.x()-pnt.x(),pnt1.y()-pnt.y());

  }*/

  print();

  text+="Rectangle\n";
    text+="Coords";
    text+=" "+str_x.setNum(4);
    text+=" "+str_x.setNum(this->StrtPnt.x())+" "+str_y.setNum(this->StrtPnt.y())+" "+str_x1.setNum(this->EndPnt.x())+" "+str_y1.setNum(this->EndPnt.y())+"\n";
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

  qDebug()<<"saved text "<<text<<"\n";

}


QPointF Draw_Rectangle::getStartPnt()
{
    return StrtPnt;
}

QPointF Draw_Rectangle::getEndPnt()
{
    return EndPnt;
}

QPointF Draw_Rectangle::getRectstartPnt()
{
    QPointF pnt;
    //pnt.setX(StrtPnt.x()-6.0);
    //pnt.setY(StrtPnt.y()-2.5);
    return pnt;
}

QPointF Draw_Rectangle::getRectendPnt()
{
    QPointF pnt;
    //pnt.setX(EndPnt.x()+1.0);
    //pnt.setY(EndPnt.y()-2.5);
    return pnt;
}

void Draw_Rectangle::setEdgeRects()
{
    QBrush rectbrush;
    rectbrush.setColor(QColor(0,175,225));
    rectbrush.setStyle(Qt::SolidPattern);

    Strt_Rect = new QGraphicsRectItem(QRectF(QPointF(StrtPnt.x()-5.0,StrtPnt.y()-5.0),QPointF(StrtPnt.x()+5.0,StrtPnt.y()+5.0)));
    Strt_Rect->setBrush(rectbrush);

    End_Rect = new QGraphicsRectItem(QRectF(QPointF(EndPnt.x()-5.0,EndPnt.y()-5.0),QPointF(EndPnt.x()+5.0,EndPnt.y()+5.0)));
    End_Rect->setBrush(rectbrush);


    QPointF pnt1,pnt2;

    pnt1.setX(((StrtPnt.x()+EndPnt.x())/2)-5);
    pnt1.setY(StrtPnt.y()-20);

    pnt2.setX(((StrtPnt.x()+EndPnt.x())/2)+5);
    pnt2.setY(StrtPnt.y()-10);

    Rot_Rect = new QGraphicsEllipseItem(QRectF(pnt1,pnt2));
    Rot_Rect->setBrush(rectbrush);


}

void Draw_Rectangle::updateEdgeRects()
{
    //print();
  //if(item->rotation()==0)
  {
       Strt_Rect->setRect(QRectF(QPointF(StrtPnt.x()-5.0,StrtPnt.y()-5.0),QPointF(StrtPnt.x()+5.0,StrtPnt.y()+5.0)));

       End_Rect->setRect(QRectF(QPointF(EndPnt.x()-5.0,EndPnt.y()-5.0),QPointF(EndPnt.x()+5.0,EndPnt.y()+5.0)));

       QPointF pnt1,pnt2;

       pnt1.setX(((StrtPnt.x()+EndPnt.x())/2)-5);
       pnt1.setY(StrtPnt.y()-20);

       pnt2.setX(((StrtPnt.x()+EndPnt.x())/2)+5);
       pnt2.setY(StrtPnt.y()-10);

       //print();

      Rot_Rect->setRect(QRectF(pnt1,pnt2));

      Strt_Rect->update();
      End_Rect->update();
      Rot_Rect->update();
  }

  if(item->rotation()!=0)
  {
       /*Strt_Rect->setRect(QRectF(QPointF(StrtPnt.x()-5.0,StrtPnt.y()-5.0),QPointF(StrtPnt.x()+5.0,StrtPnt.y()+5.0)));

       End_Rect->setRect(QRectF(QPointF(EndPnt.x()-5.0,EndPnt.y()-5.0),QPointF(EndPnt.x()+5.0,EndPnt.y()+5.0)));

       QPointF pnt1,pnt2;

       pnt1.setX(((StrtPnt.x()+EndPnt.x())/2)-5);
       pnt1.setY(StrtPnt.y()-20);

       pnt2.setX(((StrtPnt.x()+EndPnt.x())/2)+5);
       pnt2.setY(StrtPnt.y()-10);*/

       //print();


      //Rot_Rect->setRect(QRectF(pnt1,pnt2));

    //Strt_Rect->setPos(Strt_Rect->pos()

      Strt_Rect->update();
      End_Rect->update();
      Rot_Rect->update();
  }

}



QPointF Draw_Rectangle::getBoundMinPnt()
{
    return bounding_min_pnt;
}

QPointF Draw_Rectangle::getBoundMaxPnt()
{
    return bounding_max_pnt;
}


void Draw_Rectangle::setState(int state)
{
    draw_state=state;
}

int Draw_Rectangle::getState()
{
    return draw_state;
}

void Draw_Rectangle::setMode(bool mode)
{
    draw_mode=mode;
}


bool Draw_Rectangle::getMode()
{
    return draw_mode;
}

bool Draw_Rectangle::isMouseClickedOnStartHandle(QPointF pnt)
{


    if(Strt_Rect->isUnderMouse())
    {
        draw_state=1;
        Strt_Rect->setCursor(Qt::CrossCursor);
    return true;
    }
    else
        return false;
}

bool Draw_Rectangle::isMouseClickedOnEndHandle(QPointF pnt)
{

    if(End_Rect->isUnderMouse())
    {
        draw_state=2;
        End_Rect->setCursor(Qt::CrossCursor);
        return true;
    }
    else
        return false;
}

bool Draw_Rectangle::isMouseClickedOnRotateHandle(const QPointF pnt)
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
        return true;
    }
    else
        return false;


}

bool Draw_Rectangle::isMouseClickedOnShape(const QPointF pnt)
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


QColor Draw_Rectangle::getPenColor()
{
     return pen.color();

}

void Draw_Rectangle::setTranslate(QPointF pnt,QPointF pnt1)
{
    //setStartPoint(getStartPnt()-(pnt-pnt1));
    //setEndPoint(getEndPnt()-(pnt-pnt1));
    if(draw_state==3)
    {
       item->setPos(item->pos()-(pnt-pnt1));
       Strt_Rect->setPos(Strt_Rect->pos()-(pnt-pnt1));
       End_Rect->setPos(End_Rect->pos()-(pnt-pnt1));
       Rot_Rect->setPos(Rot_Rect->pos()-(pnt-pnt1));
       item->update();
       Strt_Rect->update();
       End_Rect->update();

    }

    if(draw_state==1)
    {
       Strt_Rect->setPos(Strt_Rect->pos()-(pnt-pnt1));
       Strt_Rect->update();
    }

    if(draw_state==2)
    {
       End_Rect->setPos(End_Rect->pos()-(pnt-pnt1));
       End_Rect->update();

    }


}

void Draw_Rectangle::translate_items(QPointF pnt,QPointF pnt1)
{
    for(int i=0;i<rects.size();i++)
    {
       rects[i]->StrtPnt-=pnt-pnt1;
       rects[i]->EndPnt-=pnt-pnt1;
    }
}


void Draw_Rectangle::setRotate(const QPointF &pnt,const QPointF &pnt1)
{

    if(pnt1.x()>pnt.x())
    {
       angle+=0.5;
       item->setRotation(angle);
       Strt_Rect->setRotation(angle);
       End_Rect->setRotation(angle);
       Rot_Rect->setRotation(angle);
    }

    if(pnt.x()>pnt1.x())
    {
       angle-=0.5;
       item->setRotation(angle);
       Strt_Rect->setRotation(angle);
       End_Rect->setRotation(angle);
       Rot_Rect->setRotation(angle);
    }

    item->update();
    Strt_Rect->update();
    End_Rect->update();
    Rot_Rect->update();

  qDebug()<<"scene coords "<<item->sceneBoundingRect().topLeft()<<"  "<<item->sceneBoundingRect().bottomRight()<<"\n";

    QPointF rot_pnt(item->boundingRect().topLeft()-item->sceneBoundingRect().topLeft());
    QPointF rot_pnt1(item->boundingRect().bottomRight()-item->sceneBoundingRect().bottomRight());

}

void Draw_Rectangle::setScale(float x,float y)
{
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
   item->setTransform(QTransform::fromScale(x, y), true);
#else
   item->scale(x,y);
#endif
}

void Draw_Rectangle::setItemId(int id)
{
    //ItemId=id;
}

void Draw_Rectangle::setGraphicsItem(QGraphicsItem *item)
{
    //shapes->setGraphicsItem(item);
}


void Draw_Rectangle::setPen(const QColor color)
{

    this->pen=item->pen();
    this->pen.setColor(color);
    item->setPen(pen);

}

void Draw_Rectangle::setPenStyle(const int style)
{
    switch(style)
    {
      case 1:
          this->pen=item->pen();
          this->pen.setStyle(Qt::SolidLine);
          item->setPen(pen);
         break;
      case 2:
          this->pen=item->pen();
          this->pen.setStyle(Qt::DashLine);
          item->setPen(pen);
          break;
      case 3:
          this->pen=item->pen();
          this->pen.setStyle(Qt::DotLine);
          item->setPen(pen);
          break;
      case 4:
          this->pen=item->pen();
          this->pen.setStyle(Qt::DashDotLine);
          item->setPen(pen);
          break;
      case 5:
          this->pen=item->pen();
          this->pen.setStyle(Qt::DashDotDotLine);
          item->setPen(pen);
          break;
    default:
          break;
    }

}

void Draw_Rectangle::setPenWidth(const int width)
{
    this->pen=item->pen();
    this->pen.setWidth(width);
    item->setPen(pen);
}

QPen Draw_Rectangle::getPen()
{
    return pen;
}

void Draw_Rectangle::setBrush(const QBrush brush)
{
     this->brush=item->brush();
     this->brush.setColor(brush.color());
     item->setBrush(this->brush);
}

void Draw_Rectangle::setBrushStyle(const int style)
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

QBrush Draw_Rectangle::getBrush()
{
        return brush;
}

void Draw_Rectangle::showHandles()
{
  if(!Strt_Rect->isVisible())
        Strt_Rect->show();
    if(!End_Rect->isVisible())
    End_Rect->show();
    if(!Rot_Rect->isVisible())
    Rot_Rect->show();
}

void Draw_Rectangle::hideHandles()
{

  if(Strt_Rect->isVisible())
        Strt_Rect->hide();
    if(End_Rect->isVisible())
        End_Rect->hide();
    if(Rot_Rect->isVisible())
        Rot_Rect->hide();
}


bool Draw_Rectangle::isClickedOnHandleOrShape(QPointF point)
{
  if(getMode())
    {
        if(isMouseClickedOnStartHandle(point))
            return true;
        else if(isMouseClickedOnEndHandle(point))
            return true;
        else if(isMouseClickedOnShape(point))
            return true;
        else if(isMouseClickedOnRotateHandle(point))
            return true;
    }

    return false;
}

void Draw_Rectangle::rotateShape(float angle)
{

  item->setRotation(angle);
    Strt_Rect->setRotation(angle);
    End_Rect->setRotation(angle);
    Rot_Rect->setRotation(angle);

  item->update();
  Strt_Rect->update();
    End_Rect->update();
    Rot_Rect->update();

  QPointF pnt1;
    pnt1.setX((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2);
    pnt1.setY((item->boundingRect().topLeft().y()+item->boundingRect().bottomRight().y())/2);
    item->setTransformOriginPoint(pnt1);
    Strt_Rect->setTransformOriginPoint(pnt1);
    End_Rect->setTransformOriginPoint(pnt1);
    Rot_Rect->setTransformOriginPoint(pnt1);
}


void Draw_Rectangle::print()
{
    qDebug()<<"Starting and Ending  points of line"<<getStartPnt()<<"  "<<getEndPnt()<<"\n";
}

/*void Draw_Rectangle::updatePosition(QPointF pnt,QPointF pnt1)
{
     this->pnt=pnt;
     this->pnt1=pnt1;
}*/
