#include "Draw_RoundRect.h"

Draw_RoundRect::Draw_RoundRect()
{
    draw_state=0;
    draw_mode=false;
    angle=0;
    radius=15;

    pen =  QPen();
    pen.setColor(QColor(0,0,0));
    pen.setStyle(Qt::SolidLine);
    pen.setWidth(1);

    brush = QBrush();
    brush.setColor(QColor(255,255,255));
    brush.setStyle(Qt::NoBrush);

    prev_pos.setX(0);
    prev_pos.setY(0);

  isObjectSelected=false;
}

Draw_RoundRect::Draw_RoundRect(QPointF pnt,QPointF pnt1):StrtPnt(pnt),EndPnt(pnt1)
{
    draw_state=0;
    draw_mode=false;
    angle=0;
    pen = QPen();
}

void Draw_RoundRect::setStartPoint(QPointF strt_pnt)
{
    StrtPnt=strt_pnt;
}

void Draw_RoundRect::setEndPoint(QPointF lst_pnt)
{
    EndPnt=lst_pnt;
}


QPointF Draw_RoundRect::getStartPnt()
{
    return StrtPnt;
}

QPointF Draw_RoundRect::getEndPnt()
{
    return EndPnt;
}

QPointF Draw_RoundRect::getRectstartPnt()
{
    QPointF pnt;
    pnt.setX(StrtPnt.x()-6.0);
    pnt.setY(StrtPnt.y()-2.5);
    return pnt;
}

QPointF Draw_RoundRect::getRectendPnt()
{
    QPointF pnt;
    pnt.setX(EndPnt.x()+1.0);
    pnt.setY(EndPnt.y()-2.5);
    return pnt;
}

void Draw_RoundRect::setEdgeRects()
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

void Draw_RoundRect::updateEdgeRects()
{
    Strt_Rect->setRect(QRectF(QPointF(StrtPnt.x()-5.0,StrtPnt.y()-5.0),QPointF(StrtPnt.x()+5.0,StrtPnt.y()+5.0)));

    End_Rect->setRect(QRectF(QPointF(EndPnt.x()-5.0,EndPnt.y()-5.0),QPointF(EndPnt.x()+5.0,EndPnt.y()+5.0)));

    QPointF pnt1,pnt2;

    pnt1.setX(((StrtPnt.x()+EndPnt.x())/2)-5);
    pnt1.setY(StrtPnt.y()-20);

    pnt2.setX(((StrtPnt.x()+EndPnt.x())/2)+5);
    pnt2.setY(StrtPnt.y()-10);

    Rot_Rect->setRect(QRectF(pnt1,pnt2));

}

QPointF Draw_RoundRect::getBoundMinPnt()
{
    return bounding_min_pnt;
}

QPointF Draw_RoundRect::getBoundMaxPnt()
{
    return bounding_max_pnt;
}


void Draw_RoundRect::setState(int state)
{
    draw_state=state;
}

int Draw_RoundRect::getState()
{
    return draw_state;
}

void Draw_RoundRect::setMode(bool mode)
{
    draw_mode=mode;
}

bool Draw_RoundRect::getMode()
{
    return draw_mode;
}

bool Draw_RoundRect::isMouseClickedOnStartHandle(QPointF pnt)
{

    /*if(Strt_Rect->isUnderMouse())
    {
        draw_state=1;
        Strt_Rect->setCursor(Qt::CrossCursor);
        return true;
    }*/

    if(Strt_Rect->isUnderMouse())
    {
        draw_state=1;
        Strt_Rect->setCursor(Qt::CrossCursor);
        return true;
    }
    else
        return false;

}

bool Draw_RoundRect::isMouseClickedOnEndHandle(QPointF pnt)
{

    /*if(End_Rect->isUnderMouse())
    {
        qDebug()<<"mouse clicked on end rect "<<pnt<<"\n";
        qDebug()<<"scene pos "<<End_Rect->mapFromScene(pnt)<<"\n";
        qDebug()<<"end rect "<<End_Rect->boundingRect().topLeft()<<" "<<End_Rect->boundingRect().bottomRight()<<"\n";
        draw_state=2;
        End_Rect->setCursor(Qt::CrossCursor);
        return true;
    }*/

    if(this->End_Rect->isUnderMouse())
    {
        draw_state=2;
        End_Rect->setCursor(Qt::CrossCursor);
        return true;
    }
    else
        return false;

}

bool Draw_RoundRect::isMouseClickedOnRotateHandle(const QPointF pnt)
{

    /*if(this->Rot_Rect->isUnderMouse())
    {
        draw_state=4;
        QPointF pnt1;
        pnt1.setX((Rot_Rect->boundingRect().topLeft().x()+Rot_Rect->boundingRect().bottomRight().x())/2);
        pnt1.setY((Rot_Rect->boundingRect().topLeft().y()+Rot_Rect->boundingRect().bottomRight().y())/2);
        item->setTransformOriginPoint(pnt1);
        Strt_Rect->setTransformOriginPoint(pnt1);
        End_Rect->setTransformOriginPoint(pnt1);
        Rot_Rect->setTransformOriginPoint(pnt1);
        return true;
    }*/

    if(this->Rot_Rect->isUnderMouse())
    {
        qDebug()<<"Clicked on rot point\n";
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

bool Draw_RoundRect::isMouseClickedOnShape(const QPointF pnt)
{
    /*if(item->isUnderMouse())
    {
        draw_state=3;
        item->setCursor(Qt::SizeAllCursor);
        return true;
    }*/

    if(item->isUnderMouse())
    {
        draw_state=3;
        item->setCursor(Qt::SizeAllCursor);
        return true;
    }
    else
        return false;
}

void Draw_RoundRect::BoundingBox()
{
    /*bounding_min_pnt.setX(rect_strt_pnt.x());
    bounding_min_pnt.setY(rect_strt_pnt.y()-2.5);
    bounding_max_pnt.setX(rect_end_pnt.x());
    bounding_max_pnt.setY(rect_end_pnt.y()+5.0);*/
}

QColor Draw_RoundRect::getPenColor()
{
   return pen.color();
}

void Draw_RoundRect::setTranslate(QPointF pnt,QPointF pnt1)
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

void Draw_RoundRect::translate_items(QPointF pnt,QPointF pnt1)
{
    /*for(int i=0;i<round_rects.size();i++)
    {
       round_rects[i]->StrtPnt-=pnt-pnt1;
       round_rects[i]->EndPnt-=pnt-pnt1;
       //rects[i]->Bounding_box();
    }*/
}


void Draw_RoundRect::setRotate(const QPointF &pnt,const QPointF &pnt1)
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


    QPointF rot_pnt(item->boundingRect().topLeft()-item->sceneBoundingRect().topLeft());
    QPointF rot_pnt1(item->boundingRect().bottomRight()-item->sceneBoundingRect().bottomRight());
  qDebug()<<"item scene bounding rect "<<rot_pnt<<" "<<rot_pnt1<<"\n";
    setStartPoint(item->sceneBoundingRect().topLeft());
    setEndPoint(item->sceneBoundingRect().bottomRight());


}

void Draw_RoundRect::setScale(float x,float y)
{
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
   item->setTransform(QTransform::fromScale(x, y), true);
#else
   item->scale(x,y);
#endif
}

void Draw_RoundRect::setItemId(int id)
{
    //ItemId=id;
}

void Draw_RoundRect::setGraphicsItem(QGraphicsItem *item)
{
    //shapes->setGraphicsItem(item);
}

/*QGraphicsItem* Draw_RoundRect::getGraphicsItem()
{
    //return shapes->getGraphicsItem();
}*/


/*int Draw_RoundRect::getItemId()
{
    //return ItemId;
    return 1;
}*/

QPainterPath Draw_RoundRect::getRoundRect(const QPointF pnt,const QPointF pnt1)
{


    QPainterPath round_rect;

    StrtPnt=pnt;
    EndPnt=pnt1;
    rect = QRectF(StrtPnt,EndPnt);
    //print();
    round_rect.addRoundedRect(rect,radius,radius,Qt::AbsoluteSize);
    return round_rect;
}

void Draw_RoundRect::drawImage(QPainter *painter,QString &text,QPointF point)
{

    QString str_x,str_y,str_x1,str_y1;
    QString color_r,color_g,color_b;

  QPointF pnt,pnt1;

  //this->StrtPnt=item->sceneBoundingRect().topLeft();
  //this->EndPnt = item->sceneBoundingRect().bottomRight();

  pnt = this->StrtPnt;
  pnt1 = this->EndPnt;

  pnt+=point;
  pnt1+=point;


  QPainterPath round_rect;

    rect = QRectF(pnt,pnt1);
    //print();
    round_rect.addRoundedRect(rect,radius,radius,Qt::AbsoluteSize);

    painter->setPen(this->pen);
    painter->setBrush(this->brush);
    painter->drawPath(round_rect);
    text+="RoundRect\n";
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

}


void Draw_RoundRect::setPen(const QColor color)
{
    this->pen=item->pen();
    this->pen.setColor(color);
    item->setPen(pen);
}

void Draw_RoundRect::setPenStyle(const int style)
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

void Draw_RoundRect::setPenWidth(const int width)
{
    this->pen=item->pen();
    this->pen.setWidth(width);
    item->setPen(pen);
}

QPen Draw_RoundRect::getPen()
{
    return item->pen();
}

void Draw_RoundRect::print()
{
    qDebug()<<"Starting and Ending  points of rounded rectangle "<<getStartPnt()<<"  "<<getEndPnt()<<"\n";
}

void Draw_RoundRect::setBrush(const QBrush brush)
{
    this->brush=item->brush();
    this->brush.setColor(brush.color());
    item->setBrush(this->brush);
}

void Draw_RoundRect::setBrushStyle(const int style)
{
    this->brush=item->brush();
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
      default:
         break;
    }

}

QBrush Draw_RoundRect::getBrush()
{
     return item->brush();
}

void Draw_RoundRect::showHandles()
{
  if(!Strt_Rect->isVisible())
        Strt_Rect->show();
    if(!End_Rect->isVisible())
    End_Rect->show();
    if(!Rot_Rect->isVisible())
    Rot_Rect->show();
}

void Draw_RoundRect::hideHandles()
{
  if(Strt_Rect->isVisible())
        Strt_Rect->hide();
    if(End_Rect->isVisible())
        End_Rect->hide();
    if(Rot_Rect->isVisible())
        Rot_Rect->hide();
}

bool Draw_RoundRect::isClickedOnHandleOrShape(QPointF point)
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

void Draw_RoundRect::rotateShape(float angle)
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

Draw_RoundRect::~Draw_RoundRect()
{

}