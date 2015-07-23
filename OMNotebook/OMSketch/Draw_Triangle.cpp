#include "Draw_Triangle.h"

Draw_Triangle::Draw_Triangle()
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

    triangle_pnts.clear();
    triangle_pnts.resize(4);

  handles.clear();

}

void Draw_Triangle::setStartPoint(QPointF strt_pnt)
{
    StrtPnt=strt_pnt;
}

void Draw_Triangle::setEndPoint(QPointF lst_pnt)
{
    EndPnt=lst_pnt;
}

void Draw_Triangle::setHeightPoint(QPointF curve_pnt)
{
    HeightPnt=curve_pnt;
}


QPointF Draw_Triangle::getStartPnt()
{
    return StrtPnt;
}

QPointF Draw_Triangle::getEndPnt()
{
    return EndPnt;
}

QPointF Draw_Triangle::getHeightPnt()
{
    return HeightPnt;
}


QPointF Draw_Triangle::getRectstartPnt()
{
    QPointF pnt;
    pnt.setX(StrtPnt.x()-6.0);
    pnt.setY(StrtPnt.y()-2.5);
    return pnt;
}

QPointF Draw_Triangle::getRectendPnt()
{
    QPointF pnt;
    pnt.setX(EndPnt.x()+1.0);
    pnt.setY(EndPnt.y()-2.5);
    return pnt;
}

void Draw_Triangle::setEdgeRects()
{
    QBrush rectbrush;
    rectbrush.setColor(QColor(0,175,225));
    rectbrush.setStyle(Qt::SolidPattern);
    qDebug()<<"strt pnt "<<StrtPnt<<" "<<"end pnt "<<EndPnt<<"\n";

  QGraphicsRectItem *rect = new QGraphicsRectItem(QRectF(QPointF(item->boundingRect().topLeft().x()-5.0,item->boundingRect().topLeft().y()-5.0),QPointF(item->boundingRect().topLeft().x()+5.0,item->boundingRect().topLeft().y()+5.0)));
    rect->setBrush(rectbrush);

  handles.push_back(rect);

  rect = new QGraphicsRectItem(QRectF(QPointF(item->boundingRect().topLeft().x()-5.0,(item->boundingRect().topLeft().y()+25)-5.0),QPointF(item->boundingRect().topLeft().x()+5.0,(item->boundingRect().topLeft().y()+25)+5.0)));
    rect->setBrush(rectbrush);

  handles.push_back(rect);

  rect = new QGraphicsRectItem(QRectF(QPointF(item->boundingRect().topRight().x()-5.0,item->boundingRect().topRight().y()-5.0),QPointF(item->boundingRect().topRight().x()+5.0,item->boundingRect().topRight().y()+5.0)));
    rect->setBrush(rectbrush);

  handles.push_back(rect);

  rect = new QGraphicsRectItem(QRectF(QPointF(item->boundingRect().topRight().x()-5.0,(item->boundingRect().topRight().y()+25)-5.0),QPointF(item->boundingRect().topRight().x()+5.0,(item->boundingRect().topRight().y()+25)+5.0)));
    rect->setBrush(rectbrush);

  handles.push_back(rect);

    rect = new QGraphicsRectItem(QRectF(QPointF(StrtPnt.x()-5.0,StrtPnt.y()-5.0),QPointF(StrtPnt.x()+5.0,StrtPnt.y()+5.0)));
    rect->setBrush(rectbrush);

  handles.push_back(rect);

  rect = new QGraphicsRectItem(QRectF(QPointF((StrtPnt.x()+50)-5.0,StrtPnt.y()-5.0),QPointF((StrtPnt.x()+50)+5.0,StrtPnt.y()+5.0)));
    rect->setBrush(rectbrush);

  handles.push_back(rect);

    rect = new QGraphicsRectItem(QRectF(QPointF(EndPnt.x()-5.0,EndPnt.y()-5.0),QPointF(EndPnt.x()+5.0,EndPnt.y()+5.0)));
    rect->setBrush(rectbrush);

  handles.push_back(rect);

    rect = new QGraphicsRectItem(QRectF(QPointF(HeightPnt.x()-5.0,HeightPnt.y()-5.0),QPointF(HeightPnt.x()+5.0,HeightPnt.y()+5.0)));
    rect->setBrush(rectbrush);

  handles.push_back(rect);

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

void Draw_Triangle::updateEdgeRects()
{


  handles[0]->setRect(QRectF(QPointF(item->boundingRect().topLeft().x()-5.0,item->boundingRect().topLeft().y()-5.0),QPointF(item->boundingRect().topLeft().x()+5.0,item->boundingRect().topLeft().y()+5.0)));
  handles[1]->setRect(QRectF(QPointF(item->boundingRect().topLeft().x()-5.0,((item->boundingRect().topLeft().y()+StrtPnt.y())/2)-5.0),QPointF(item->boundingRect().topLeft().x()+5.0,((item->boundingRect().topLeft().y()+StrtPnt.y())/2)+5.0)));
  handles[2]->setRect(QRectF(QPointF(item->boundingRect().topRight().x()-5.0,item->boundingRect().topRight().y()-5.0),QPointF(item->boundingRect().topRight().x()+5.0,item->boundingRect().topRight().y()+5.0)));
  handles[3]->setRect(QRectF(QPointF(item->boundingRect().topRight().x()-5.0,((item->boundingRect().topRight().y()+EndPnt.y())/2)-5.0),QPointF(item->boundingRect().topRight().x()+5.0,((item->boundingRect().topRight().y()+EndPnt.y())/2)+5.0)));
  handles[4]->setRect(QRectF(QPointF(StrtPnt.x()-5.0,StrtPnt.y()-5.0),QPointF(StrtPnt.x()+5.0,StrtPnt.y()+5.0)));
  handles[6]->setRect(QRectF(QPointF(EndPnt.x()-5.0,EndPnt.y()-5.0),QPointF(EndPnt.x()+5.0,EndPnt.y()+5.0)));
  handles[5]->setRect(QRectF(QPointF(((StrtPnt.x()+EndPnt.x())/2)-5.0,StrtPnt.y()-5.0),QPointF((StrtPnt.x()+EndPnt.x())/2+5.0,StrtPnt.y()+5.0)));
  handles[7]->setRect(QRectF(QPointF(HeightPnt.x()-5.0,HeightPnt.y()-5.0),QPointF(HeightPnt.x()+5.0,HeightPnt.y()+5.0)));



  Bounding_Rect->setRect(QRectF(item->boundingRect().topLeft(),item->boundingRect().bottomRight()));

    QPointF pnt1,pnt2;

    pnt1.setX(((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2)-5);
    pnt1.setY(item->boundingRect().topLeft().y()-20);

    pnt2.setX(((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2)+5);
    pnt2.setY(item->boundingRect().topLeft().y()-10);

    Rot_Rect->setRect(QRectF(pnt1,pnt2));

}

QPointF Draw_Triangle::getBoundMinPnt()
{
    return bounding_min_pnt;
}

QPointF Draw_Triangle::getBoundMaxPnt()
{
    return bounding_max_pnt;
}


void Draw_Triangle::setState(int state)
{
    draw_state=state;
}

int Draw_Triangle::getState()
{
    return draw_state;
}

void Draw_Triangle::setMode(bool mode)
{
    draw_mode=mode;
}

bool Draw_Triangle::getMode()
{
    return draw_mode;
}

bool Draw_Triangle::isMouseClickedOnHandle(QPointF pnt)
{
    qDebug()<<"entered mouse clciked on handle function \n";

    bool found=false;

    for(int i=0;i<handles.size();i++)
    {
        if(handles[i]->isUnderMouse())
        {
        qDebug()<<"entered the state condition \n";
            draw_state=1;
            found=true;
            handle_index=i;
            handles[i]->setCursor(Qt::CrossCursor);
            break;
        }
    }
    return found;

}




bool Draw_Triangle::isMouseClickedOnRotateHandle(const QPointF pnt)
{

    if(Rot_Rect->isUnderMouse())
    {
        draw_state=5;
        QPointF pnt1;
        pnt1.setX((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2);
        pnt1.setY((item->boundingRect().topLeft().y()+item->boundingRect().bottomRight().y())/2);
        item->setTransformOriginPoint(pnt1);
        for(int i=0;i<handles.size();i++)
            handles[i]->setTransformOriginPoint(pnt1);

        //Strt_Rect->setTransformOriginPoint(pnt1);
        //End_Rect->setTransformOriginPoint(pnt1);
        //Height_Rect->setTransformOriginPoint(pnt1);
        Rot_Rect->setTransformOriginPoint(pnt1);
        Bounding_Rect->setTransformOriginPoint(pnt1);
        return true;
    }
    else
        return false;
}

bool Draw_Triangle::isMouseClickedOnShape(const QPointF pnt)
{
  qDebug()<<"enter state"<<"\n";
    if(item->isUnderMouse())
    {
    qDebug()<<"enter state"<<"\n";
        draw_state=4;
        //item->setCursor(Qt::SizeAllCursor);
        return true;
    }
    else
        return false;
}


void Draw_Triangle::BoundingBox()
{
    /*bounding_min_pnt.setX(rect_strt_pnt.x());
    bounding_min_pnt.setY(rect_strt_pnt.y()-2.5);
    bounding_max_pnt.setX(rect_end_pnt.x());
    bounding_max_pnt.setY(rect_end_pnt.y()+5.0);*/
}

QColor Draw_Triangle::getPenColor()
{
   return pen.color();
}

void Draw_Triangle::setTranslate(QPointF pnt,QPointF pnt1)
{
  if(item->rotation()==0)
  {
     setStartPoint(getStartPnt()-(pnt-pnt1));
       setEndPoint(getEndPnt()-(pnt-pnt1));
       setHeightPoint(getHeightPnt()-(pnt-pnt1));
  }

    item->setPos(item->pos()-(pnt-pnt1));
  item->update();

  for(int i=0;i<handles.size();i++)
  {
    handles[i]->setPos(handles[i]->pos()-(pnt-pnt1));
    handles[i]->update();
  }

    /*Strt_Rect->setPos(Strt_Rect->pos()-(pnt-pnt1));
    End_Rect->setPos(End_Rect->pos()-(pnt-pnt1));
    Height_Rect->setPos(Height_Rect->pos()-(pnt-pnt1));*/
    Rot_Rect->setPos(Rot_Rect->pos()-(pnt-pnt1));
  Rot_Rect->update();
    Bounding_Rect->setPos(Bounding_Rect->pos()-(pnt-pnt1));

}

void Draw_Triangle::translate_items(QPointF pnt,QPointF pnt1)
{
    /*for(int i=0;i<round_rects.size();i++)
    {
       round_rects[i]->StrtPnt-=pnt-pnt1;
       round_rects[i]->EndPnt-=pnt-pnt1;
       //rects[i]->Bounding_box();
    }*/
}


void Draw_Triangle::setRotate(const QPointF &pnt,const QPointF &pnt1)
{

    if(pnt1.x()>pnt.x())
    {
       angle+=0.5;
       item->setRotation(angle);
     for(int i=0;i<handles.size();i++)
     {
       handles[i]->setRotation(angle);
       handles[i]->update();
     }
       Rot_Rect->setRotation(angle);
       Bounding_Rect->setRotation(angle);
    }

    if(pnt.x()>pnt1.x())
    {
       angle-=0.5;
       item->setRotation(angle);
     for(int i=0;i<handles.size();i++)
     {
      handles[i]->setRotation(angle);
      handles[i]->update();
     }
       Rot_Rect->setRotation(angle);
       Bounding_Rect->setRotation(angle);
    }

    item->update();
    Rot_Rect->update();
    Bounding_Rect->update();


    QPointF rot_pnt(item->boundingRect().topLeft()-item->sceneBoundingRect().topLeft());
    QPointF rot_pnt1(item->boundingRect().bottomRight()-item->sceneBoundingRect().bottomRight());



    //setStartPoint(item->sceneBoundingRect().topLeft());
    //setEndPoint(item->sceneBoundingRect().bottomRight());



  //qDebug()<<"rot triangle pnts "<<Strt_Rect->mapFromScene(item->sceneBoundingRect().bottomLeft())<<"  "<<End_Rect->mapFromScene(item->sceneBoundingRect().bottomRight())<<"\n";

  print();


}

void Draw_Triangle::setScale(float x,float y)
{
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
   item->setTransform(QTransform::fromScale(x, y), true);
#else
   item->scale(x,y);
#endif
}

QPainterPath Draw_Triangle::getTriangle()
{
    QPainterPath triangle;

    if(!draw_mode)
    {
       qDebug()<<"entered mode"<<"\n";
       QPointF pnt;
       pnt.setX(StrtPnt.x()+100.0);
       pnt.setY(StrtPnt.y());

       EndPnt=pnt;

       pnt.setX(StrtPnt.x()+50.0);
       pnt.setY(StrtPnt.y()-50.0);

       HeightPnt=pnt;

       triangle_pnts[0]=StrtPnt;
       triangle_pnts[1]=EndPnt;
       triangle_pnts[2]=HeightPnt;
       triangle_pnts[3]=StrtPnt;

     qDebug()<<"triangle pnts "<<triangle_pnts[0]<<"  "<<triangle_pnts[1]<<"  "<<triangle_pnts[2]<<" "<<triangle_pnts[3]<<"\n";

       triangle.moveTo(StrtPnt.x(),StrtPnt.y());
       triangle.addPolygon(QPolygonF(triangle_pnts));
    }

    if(draw_mode)
    {
        triangle_pnts[0]=StrtPnt;
        triangle_pnts[1]=EndPnt;
        triangle_pnts[2]=HeightPnt;
        triangle_pnts[3]=StrtPnt;

        triangle.moveTo(StrtPnt.x(),StrtPnt.y());
        triangle.addPolygon(QPolygonF(triangle_pnts));

    qDebug()<<"entered draw mode\n";

    return triangle;
    }

    return triangle;
}

void Draw_Triangle::drawImage(QPainter *painter, QString &text,QPointF point)
{

    QString str_x,str_y;
    QString color_r,color_g,color_b;

    QPainterPath triangle;
    triangle_pnts[0]=StrtPnt;
    triangle_pnts[1]=EndPnt;
    triangle_pnts[2]=HeightPnt;
    triangle_pnts[3]=StrtPnt;

  QVector<QPointF> pnts(triangle_pnts.size());

  for(int i=0;i<pnts.size();i++)
  {
    pnts[i]=triangle_pnts[i];
    pnts[i]+=point;
    //qDebug()<<"triangle pnts "<<pnts[i]<<"\n";
  }

  //qDebug()<<"triangles "<<this->triangle_pnts.size()<<"\n";

    triangle.moveTo(pnts[0].x(),pnts[0].y());
    triangle.addPolygon(QPolygonF(pnts));

    painter->setPen(this->pen);
    painter->setBrush(this->brush);
    painter->drawPath(triangle);


    text+="Triangle\n";
    text+="Coords";
    text+=" "+str_x.setNum(this->triangle_pnts.size()*2.0);

    for(int j=0;j<this->triangle_pnts.size()-1;j++)
    {
         text+=" "+str_x.setNum((this->triangle_pnts[j].x()))+" "+str_y.setNum((this->triangle_pnts[j].y()))+" ";
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



void Draw_Triangle::setPen(const QColor color)
{
    this->pen=item->pen();
    this->pen.setColor(color);
    item->setPen(pen);
}

void Draw_Triangle::setPenStyle(const int style)
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

void Draw_Triangle::setPenWidth(const int width)
{
    this->pen=item->pen();
    this->pen.setWidth(width);
    item->setPen(pen);
}

QPen Draw_Triangle::getPen()
{
    return item->pen();
}

void Draw_Triangle::setBrush(const QBrush brush)
{
     this->brush=item->brush();
     this->brush.setColor(brush.color());
     item->setBrush(this->brush);
}

void Draw_Triangle::setBrushStyle(const int style)
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

QBrush Draw_Triangle::getBrush()
{
        return brush;
}

void Draw_Triangle::showHandles()
{

  for(int i=0;i<handles.size();i++)
  {
    if(!handles[i]->isVisible())
      handles[i]->show();
  }

  if(!Rot_Rect->isVisible())
    Rot_Rect->show();
  if(!Bounding_Rect->isVisible())
    Bounding_Rect->show();
}

void Draw_Triangle::hideHandles()
{
  /*if(Strt_Rect->isVisible())
         Strt_Rect->hide();
    if(End_Rect->isVisible())
        End_Rect->hide();
    if(Height_Rect->isVisible())
         Height_Rect->hide();*/
  for(int i=0;i<handles.size();i++)
  {
    if(handles[i]->isVisible())
       handles[i]->hide();
  }

  if(Rot_Rect->isVisible())
    Rot_Rect->hide();
}

bool Draw_Triangle::isClickedOnHandleOrShape(QPointF point)
{
    int k=0;
    if(getMode())
    {
    qDebug()<<"entered the condition \n";
        if(isMouseClickedOnHandle(point))
            return true;
        else if(isMouseClickedOnShape(point))
            return true;
        else if(isMouseClickedOnRotateHandle(point))
            return true;
    }

  return false;
}

void Draw_Triangle::rotateShape(float angle)
{

  item->setRotation(angle);
    Strt_Rect->setRotation(angle);
    End_Rect->setRotation(angle);
    Rot_Rect->setRotation(angle);
    Height_Rect->setRotation(angle);
    Bounding_Rect->setRotation(angle);

  item->update();
    Strt_Rect->update();
    End_Rect->update();
    Rot_Rect->update();
    Height_Rect->update();
  Bounding_Rect->update();

  QPointF pnt1;
    pnt1.setX((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2);
    pnt1.setY((item->boundingRect().topLeft().y()+item->boundingRect().bottomRight().y())/2);
    item->setTransformOriginPoint(pnt1);
    Strt_Rect->setTransformOriginPoint(pnt1);
    End_Rect->setTransformOriginPoint(pnt1);
    Height_Rect->setTransformOriginPoint(pnt1);
    Rot_Rect->setTransformOriginPoint(pnt1);
    Bounding_Rect->setTransformOriginPoint(pnt1);
}

void Draw_Triangle::print()
{
    qDebug()<<"Starting and Ending  points of line"<<getStartPnt()<<"  "<<getEndPnt()<<"\n";
}

