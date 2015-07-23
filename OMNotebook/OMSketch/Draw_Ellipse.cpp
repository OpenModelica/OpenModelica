#include "Draw_Ellipse.h"

Draw_Ellipse::Draw_Ellipse()
{
    draw_state=0;
    draw_mode=false;
    angle=0;

  isObjectSelected=false;

    pen =  QPen();
    pen.setColor(QColor(0,0,0));
    pen.setStyle(Qt::SolidLine);
    pen.setWidth(1);

    brush = QBrush();
    brush.setColor(QColor(255,255,255));
    brush.setStyle(Qt::NoBrush);
}

Draw_Ellipse::Draw_Ellipse(QPointF pnt,QPointF pnt1):StrtPnt(pnt),EndPnt(pnt1)
{
    draw_state=0;
    draw_mode=false;
    angle=0;
    pen = QPen();
}

void Draw_Ellipse::setStartPoint(QPointF strt_pnt)
{
    StrtPnt=strt_pnt;
}

void Draw_Ellipse::setEndPoint(QPointF lst_pnt)
{
    EndPnt=lst_pnt;
}


QPainterPath Draw_Ellipse::getEllep(QPointF pnt,QPointF pnt1)
{
        QPainterPath path;
        path.addEllipse(QRectF(pnt,pnt1));
        return path;
}

void Draw_Ellipse::drawImage(QPainter *painter,QString &text,QPointF point)
{

    QString str_x,str_y,str_x1,str_y1;
    QString color_r,color_g,color_b;

  QPointF pnt,pnt1;

  //this->StrtPnt=item->sceneBoundingRect().topLeft();
    //this->EndPnt = item->sceneBoundingRect().bottomRight();
  pnt=this->StrtPnt;
  pnt1=this->EndPnt;

  pnt+=point;
  pnt1+=point;

    painter->setPen(this->pen);
    painter->setBrush(this->brush);
    painter->drawEllipse(pnt.x(),pnt.y(),pnt1.x()-pnt.x(),pnt1.y()-pnt.y());
    text+="Ellipse\n";
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

QPointF Draw_Ellipse::getStartPnt()
{
    return StrtPnt;
}

QPointF Draw_Ellipse::getEndPnt()
{
    return EndPnt;
}

QPointF Draw_Ellipse::getRectstartPnt()
{
    QPointF pnt;
    pnt.setX(StrtPnt.x()-6.0);
    pnt.setY(StrtPnt.y()-2.5);
    return pnt;
}

QPointF Draw_Ellipse::getRectendPnt()
{
    QPointF pnt;
    pnt.setX(EndPnt.x()+1.0);
    pnt.setY(EndPnt.y()-2.5);
    return pnt;
}

void Draw_Ellipse::setEdgeRects()
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

void Draw_Ellipse::updateEdgeRects()
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

QPointF Draw_Ellipse::getBoundMinPnt()
{
    return bounding_min_pnt;
}

QPointF Draw_Ellipse::getBoundMaxPnt()
{
    return bounding_max_pnt;
}


void Draw_Ellipse::setState(int state)
{
    draw_state=state;
}

int Draw_Ellipse::getState()
{
    return draw_state;
}

void Draw_Ellipse::setMode(bool mode)
{
    draw_mode=mode;
}

bool Draw_Ellipse::getMode()
{
    return draw_mode;
}

bool Draw_Ellipse::isMouseClickedOnStartHandle(QPointF pnt)
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

bool Draw_Ellipse::isMouseClickedOnEndHandle(QPointF pnt)
{

    if(this->End_Rect->isUnderMouse())
    {
        draw_state=2;
        End_Rect->setCursor(Qt::CrossCursor);
        return true;
    }
    else
        return false;

}

bool Draw_Ellipse::isMouseClickedOnRotateHandle(const QPointF pnt)
{

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

bool Draw_Ellipse::isMouseClickedOnShape(const QPointF pnt)
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


void Draw_Ellipse::BoundingBox()
{
    /*bounding_min_pnt.setX(rect_strt_pnt.x());
    bounding_min_pnt.setY(rect_strt_pnt.y()-2.5);
    bounding_max_pnt.setX(rect_end_pnt.x());
    bounding_max_pnt.setY(rect_end_pnt.y()+5.0);*/
}

QColor Draw_Ellipse::getPenColor()
{
     return pen.color();
}

void Draw_Ellipse::setTranslate(QPointF pnt,QPointF pnt1)
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

void Draw_Ellipse::translate_items(QPointF pnt,QPointF pnt1)
{
    for(int i=0;i<ellipses.size();i++)
    {
       ellipses[i]->StrtPnt-=pnt-pnt1;
       ellipses[i]->EndPnt-=pnt-pnt1;
       //rects[i]->Bounding_box();
    }
}


void Draw_Ellipse::setRotate(const QPointF &pnt,const QPointF &pnt1)
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

    setStartPoint(item->sceneBoundingRect().topLeft()+rot_pnt);
    setEndPoint(item->sceneBoundingRect().bottomRight()+rot_pnt1);

}

void Draw_Ellipse::setScale(float x,float y)
{
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
   item->setTransform(QTransform::fromScale(x, y), true);
#else
   item->scale(x,y);
#endif
}

void Draw_Ellipse::setItemId(int id)
{
    //ItemId=id;
}

void Draw_Ellipse::setGraphicsItem(QGraphicsItem *item)
{
    //shapes->setGraphicsItem(item);
}

/*QGraphicsItem* Draw_Ellipse::getGraphicsItem()
{
    //return shapes->getGraphicsItem();
}*/


/*int Draw_Ellipse::getItemId()
{
    //return ItemId;
    return 1;
}*/

void Draw_Ellipse::setPen(const QColor color)
{
    this->pen=item->pen();
    this->pen.setColor(color);
    item->setPen(this->pen);
}

void Draw_Ellipse::setPenStyle(const int style)
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

void Draw_Ellipse::setPenWidth(const int width)
{
    this->pen=item->pen();
    this->pen.setWidth(width);
    item->setPen(pen);
}


QPen Draw_Ellipse::getPen()
{
    return item->pen();
}

void Draw_Ellipse::print()
{
    qDebug()<<"Starting and Ending  points of line"<<getStartPnt()<<"  "<<getEndPnt()<<"\n";
}

void Draw_Ellipse::setBrush(const QBrush brush)
{
    this->brush=item->brush();
    this->brush.setColor(brush.color());
    item->setBrush(this->brush);
}

void Draw_Ellipse::setBrushStyle(const int style)
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

QBrush Draw_Ellipse::getBrush()
{
     return item->brush();
}


void Draw_Ellipse::showHandles()
{
  if(!Strt_Rect->isVisible())
        Strt_Rect->show();
    if(!End_Rect->isVisible())
    End_Rect->show();
    if(!Rot_Rect->isVisible())
    Rot_Rect->show();
}

void Draw_Ellipse::hideHandles()
{
  if(Strt_Rect->isVisible())
        Strt_Rect->hide();
    if(End_Rect->isVisible())
        End_Rect->hide();
    if(Rot_Rect->isVisible())
        Rot_Rect->hide();
}

bool Draw_Ellipse::isClickedOnHandleOrShape(QPointF point)
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

void Draw_Ellipse::rotateShape(float angle)
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