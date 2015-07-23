#include "Draw_Arc.h"

Draw_Arc::Draw_Arc()
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

  isObjectSelected=false;



    click=-1;

  angle=0.0;
}

void Draw_Arc::setStartPoint(QPointF strt_pnt)
{
    StrtPnt=strt_pnt;
}

void Draw_Arc::setEndPoint(QPointF lst_pnt)
{
    EndPnt=lst_pnt;
}

void Draw_Arc::setCurvePoint(QPointF curve_pnt)
{
    CurvePnt=curve_pnt;
}


QPointF Draw_Arc::getStartPnt()
{
    return StrtPnt;
}

QPointF Draw_Arc::getEndPnt()
{
    return EndPnt;
}

QPointF Draw_Arc::getCurvePnt()
{
    return CurvePnt;
}


QPointF Draw_Arc::getRectstartPnt()
{
    QPointF pnt;
    pnt.setX(StrtPnt.x()-6.0);
    pnt.setY(StrtPnt.y()-2.5);
    return pnt;
}

QPointF Draw_Arc::getRectendPnt()
{
    QPointF pnt;
    pnt.setX(EndPnt.x()+1.0);
    pnt.setY(EndPnt.y()-2.5);
    return pnt;
}

void Draw_Arc::setEdgeRects()
{
    QBrush rectbrush;
    rectbrush.setColor(QColor(0,175,225));
    rectbrush.setStyle(Qt::SolidPattern);
    qDebug()<<"strt pnt "<<StrtPnt<<" "<<"end pnt "<<EndPnt<<"\n";
    Strt_Rect = new QGraphicsRectItem(QRectF(QPointF(StrtPnt.x()-5.0,StrtPnt.y()-5.0),QPointF(StrtPnt.x()+5.0,StrtPnt.y()+5.0)));
    Strt_Rect->setBrush(rectbrush);

    End_Rect = new QGraphicsRectItem(QRectF(QPointF(EndPnt.x()-5.0,EndPnt.y()-5.0),QPointF(EndPnt.x()+5.0,EndPnt.y()+5.0)));
    End_Rect->setBrush(rectbrush);

    Curve_Rect = new QGraphicsRectItem(QRectF(QPointF(CurvePnt.x()-5.0,CurvePnt.y()-5.0),QPointF(CurvePnt.x()+5.0,CurvePnt.y()+5.0)));
    Curve_Rect->setBrush(rectbrush);

    QPen bound_rect;
    bound_rect.setStyle(Qt::DashLine);
    Bounding_Rect = new QGraphicsRectItem(QRectF(item->boundingRect().topLeft(),item->boundingRect().bottomRight()));
    Bounding_Rect->setPen(bound_rect);

  QPointF pnt1,pnt2;

    pnt1.setX(((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2)-5);
    pnt1.setY(item->boundingRect().topLeft().y()-20);

    pnt2.setX(((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2)+5);
    pnt2.setY(item->boundingRect().topLeft().y()-10);

    Rot_Rect = new QGraphicsEllipseItem(QRectF(pnt1,pnt2));
    Rot_Rect->setBrush(rectbrush);


}

void Draw_Arc::updateEdgeRects()
{
    Strt_Rect->setRect(QRectF(QPointF(StrtPnt.x()-5.0,StrtPnt.y()-5.0),QPointF(StrtPnt.x()+5.0,StrtPnt.y()+5.0)));

    End_Rect->setRect(QRectF(QPointF(EndPnt.x()-5.0,EndPnt.y()-5.0),QPointF(EndPnt.x()+5.0,EndPnt.y()+5.0)));

    Curve_Rect->setRect(QRectF(QPointF(CurvePnt.x()-5.0,CurvePnt.y()-5.0),QPointF(CurvePnt.x()+5.0,CurvePnt.y()+5.0)));

    Bounding_Rect->setRect(QRectF(item->boundingRect().topLeft(),item->boundingRect().bottomRight()));

    QPointF pnt1,pnt2;

    pnt1.setX(((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2)-5);
    pnt1.setY(item->boundingRect().topLeft().y()-20);

    pnt2.setX(((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2)+5);
    pnt2.setY(item->boundingRect().topLeft().y()-10);

    Rot_Rect->setRect(QRectF(pnt1,pnt2));
}

QPointF Draw_Arc::getBoundMinPnt()
{
    return bounding_min_pnt;
}

QPointF Draw_Arc::getBoundMaxPnt()
{
    return bounding_max_pnt;
}


void Draw_Arc::setState(int state)
{
    draw_state=state;
}

int Draw_Arc::getState()
{
    return draw_state;
}

void Draw_Arc::setMode(bool mode)
{
    draw_mode=mode;
}

bool Draw_Arc::getMode()
{
    return draw_mode;
}

bool Draw_Arc::isMouseClickedOnStartHandle(QPointF pnt)
{

    if(Strt_Rect->isUnderMouse())
    {
        draw_state=1;
        return true;
    }
    else
        return false;

}

bool Draw_Arc::isMouseClickedOnEndHandle(QPointF pnt)
{

    if(this->End_Rect->isUnderMouse())
    {
        draw_state=2;
        return true;
    }
    else
        return false;

}


bool Draw_Arc::isMouseClickedOnCurveHandle(QPointF pnt)
{

    if(this->Curve_Rect->isUnderMouse())
    {
        draw_state=3;
        return true;
    }
    else
        return false;

}


bool Draw_Arc::isMouseClickedOnRotateHandle(const QPointF pnt)
{

    if(Rot_Rect->isUnderMouse())
    {
        draw_state=5;
        QPointF pnt1;
        pnt1.setX((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2);
        pnt1.setY((item->boundingRect().topLeft().y()+item->boundingRect().bottomRight().y())/2);
        item->setTransformOriginPoint(pnt1);
        Strt_Rect->setTransformOriginPoint(pnt1);
        End_Rect->setTransformOriginPoint(pnt1);
        Curve_Rect->setTransformOriginPoint(pnt1);
        Rot_Rect->setTransformOriginPoint(pnt1);
        Bounding_Rect->setTransformOriginPoint(pnt1);
        return true;
    }
    else
        return false;

}

bool Draw_Arc::isMouseClickedOnShape(const QPointF pnt)
{
    if(item->isUnderMouse())
    {
        draw_state=4;
        item->setCursor(Qt::SizeAllCursor);
        return true;
    }
    else
        return false;
}

void Draw_Arc::BoundingBox()
{
    /*bounding_min_pnt.setX(rect_strt_pnt.x());
    bounding_min_pnt.setY(rect_strt_pnt.y()-2.5);
    bounding_max_pnt.setX(rect_end_pnt.x());
    bounding_max_pnt.setY(rect_end_pnt.y()+5.0);*/
}

QColor Draw_Arc::getPenColor()
{
   return pen.color();
}

void Draw_Arc::setTranslate(QPointF pnt,QPointF pnt1)
{
   /* setStartPoint(getStartPnt()-(pnt-pnt1));
    setEndPoint(getEndPnt()-(pnt-pnt1));
    setCurvePoint(getCurvePnt()-(pnt-pnt1));*/


  item->setPos(item->pos()-(pnt-pnt1));
  item->update();

  Strt_Rect->setPos(Strt_Rect->pos()-(pnt-pnt1));
  Strt_Rect->update();

  End_Rect->setPos(End_Rect->pos()-(pnt-pnt1));
  End_Rect->update();

  Curve_Rect->setPos(Curve_Rect->pos()-(pnt-pnt1));
  Curve_Rect->update();

  Rot_Rect->setPos(Rot_Rect->pos()-(pnt-pnt1));
  Rot_Rect->update();


  Bounding_Rect->setPos(Bounding_Rect->pos()-(pnt-pnt1));
  Bounding_Rect->update();

    //BoundingBox();
}

void Draw_Arc::translate_items(QPointF pnt,QPointF pnt1)
{
    /*for(int i=0;i<round_rects.size();i++)
    {
       round_rects[i]->StrtPnt-=pnt-pnt1;
       round_rects[i]->EndPnt-=pnt-pnt1;
       //rects[i]->Bounding_box();
    }*/
}


void Draw_Arc::setRotate(const QPointF &pnt,const QPointF &pnt1)
{
   if(pnt1.x()>pnt.x())
    {
       angle+=0.5;
       item->setRotation(angle);
       Strt_Rect->setRotation(angle);
       End_Rect->setRotation(angle);
       Rot_Rect->setRotation(angle);
       Curve_Rect->setRotation(angle);
       Bounding_Rect->setRotation(angle);
    }

    if(pnt.x()>pnt1.x())
    {
       angle-=0.5;
       item->setRotation(angle);
       Strt_Rect->setRotation(angle);
       End_Rect->setRotation(angle);
       Rot_Rect->setRotation(angle);
       Curve_Rect->setRotation(angle);
       Bounding_Rect->setRotation(angle);
    }

    item->update();
    Strt_Rect->update();
    End_Rect->update();
    Rot_Rect->update();
    Bounding_Rect->update();
    Curve_Rect->update();

    QPointF rot_pnt(item->boundingRect().topLeft()-item->sceneBoundingRect().topLeft());
    QPointF rot_pnt1(item->boundingRect().bottomRight()-item->sceneBoundingRect().bottomRight());

    setStartPoint(item->sceneBoundingRect().topLeft()+rot_pnt);
    setEndPoint(item->sceneBoundingRect().bottomRight()+rot_pnt1);

}

void Draw_Arc::setScale(float x,float y)
{
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
   item->setTransform(QTransform::fromScale(x, y), true);
#else
   item->scale(x,y);
#endif
}

QPainterPath Draw_Arc::getArc()
{
    QPainterPath arc;
    arc.moveTo(StrtPnt.x(),StrtPnt.y());
    arc.cubicTo(CurvePnt.x(),CurvePnt.y(),CurvePnt.x(),CurvePnt.y(),EndPnt.x(),EndPnt.y());
    return arc;
}

void Draw_Arc::drawImage(QPainter *painter, QString &text,QPointF point)
{

    QString str_x,str_y,str_x1,str_y1;
    QString color_r,color_g,color_b;

    QVector<QPointF> pnts;

  QPointF pnt,pnt1,pnt2;

  pnt=this->StrtPnt;
  pnt1=this->EndPnt;
  pnt2=this->CurvePnt;

  qDebug()<<"curve pnts "<<StrtPnt<<"  "<<EndPnt<<"  "<<CurvePnt<<"\n";

  pnt+=point;
  pnt1+=point;
  pnt2+=point;

    QPainterPath arc;
    arc.moveTo(pnt.x(),pnt.y());
    arc.cubicTo(pnt2.x(),pnt2.y(),pnt2.x(),pnt2.y(),pnt1.x(),pnt1.y());

    painter->setPen(this->pen);
    painter->setBrush(this->brush);
    painter->drawPath(arc);

    pnts.push_back(this->StrtPnt);
    pnts.push_back(this->EndPnt);
  pnts.push_back(this->CurvePnt);

  for(int i=0;i<pnts.size();i++)
     qDebug()<<"curve pnts in pnts "<<pnts[i]<<"\n";

    text+="Arc\n";
    text+="Coords";
    text+=" "+str_x.setNum(6);

    for(int j=0;j<pnts.size();j++)
    {
         text+=" "+str_x.setNum((pnts[j].x()))+" "+str_y.setNum((pnts[j].y()))+" ";
    }


    text+="PenColor";
    text+=" "+color_r.setNum(this->pen.color().red())+" "+color_g.setNum(this->pen.color().green())+" "+color_b.setNum(this->pen.color().blue())+"\n";
    text+="PenStyle";
    text+=" "+color_r.setNum(this->pen.style())+"\n";
    text+="PenWidth";
    text+=" "+color_r.setNum(this->pen.width())+"\n";

  text+="Rotation";
  text+=" "+color_r.setNum(this->item->rotation(),'g',6)+"\n";


}


void Draw_Arc::setPen(const QColor color)
{
    this->pen=item->pen();
    this->pen.setColor(color);
    item->setPen(pen);
}

void Draw_Arc::setPenStyle(const int style)
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

void Draw_Arc::setPenWidth(const int width)
{
    this->pen=item->pen();
    this->pen.setWidth(width);
    item->setPen(pen);
}

QPen Draw_Arc::getPen()
{
    return item->pen();
}

void Draw_Arc::showHandles()
{
   if(!Strt_Rect->isVisible())
         Strt_Rect->show();
     if(!End_Rect->isVisible())
         End_Rect->show();
     if(!Curve_Rect->isVisible())
         Curve_Rect->show();
   if(!Rot_Rect->isVisible())
     Rot_Rect->show();
}

void Draw_Arc::hideHandles()
{
   if(Strt_Rect->isVisible())
         Strt_Rect->hide();
     if(End_Rect->isVisible())
         End_Rect->hide();
     if(Curve_Rect->isVisible())
         Curve_Rect->hide();
     if(Rot_Rect->isVisible())
     Rot_Rect->hide();
}

bool Draw_Arc::isClickedOnHandleOrShape(QPointF point)
{
  if(getMode())
    {
        if(isMouseClickedOnStartHandle(point))
            return true;
        else if(isMouseClickedOnEndHandle(point))
            return true;
        else if(isMouseClickedOnCurveHandle(point))
            return true;
        else if(isMouseClickedOnShape(point))
            return true;
        else if(isMouseClickedOnRotateHandle(point))
            return true;
    }

    return false;
}


void Draw_Arc::rotateShape(float angle)
{

   item->setRotation(angle);
     Strt_Rect->setRotation(angle);
     End_Rect->setRotation(angle);
     Rot_Rect->setRotation(angle);
     Curve_Rect->setRotation(angle);
     Bounding_Rect->setRotation(angle);

   item->update();
   Strt_Rect->update();
   End_Rect->update();
   Rot_Rect->update();
   Curve_Rect->update();
   Bounding_Rect->update();

  QPointF pnt1;
    pnt1.setX((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2);
    pnt1.setY((item->boundingRect().topLeft().y()+item->boundingRect().bottomRight().y())/2);
    item->setTransformOriginPoint(pnt1);
    Strt_Rect->setTransformOriginPoint(pnt1);
    End_Rect->setTransformOriginPoint(pnt1);
    Curve_Rect->setTransformOriginPoint(pnt1);
    Rot_Rect->setTransformOriginPoint(pnt1);
    Bounding_Rect->setTransformOriginPoint(pnt1);
}

void Draw_Arc::print()
{
    qDebug()<<"Starting and Ending  points of line"<<getStartPnt()<<"  "<<getEndPnt()<<"\n";
}

