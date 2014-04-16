#include "Draw_LineArrow.h"

Draw_LineArrow::Draw_LineArrow()
{
    draw_state=0;
    draw_mode=false;
    arrow_pnts.clear();
    arrow_pnts.resize(6);

    pen =  QPen();
    pen.setColor(QColor(0,0,0));
    pen.setStyle(Qt::SolidLine);
    pen.setWidth(1);

    angle=0.0;

  isObjectSelected=false;
}

void Draw_LineArrow::setDefaults()
{
    draw_state=0;
    draw_mode=false;


}

Draw_LineArrow::Draw_LineArrow(QPointF strt_pnt,QPointF end_pnt)
{
    draw_state=0;
    draw_mode=false;

    //lines.clear();

    StrtPnt=strt_pnt;
    EndPnt=end_pnt;
}

void Draw_LineArrow::setStartPoint(QPointF strt_pnt)
{
    StrtPnt=strt_pnt;
}

void Draw_LineArrow::setEndPoint(QPointF lst_pnt)
{
    EndPnt=lst_pnt;
}

void Draw_LineArrow::setPnt(QPointF pnt)
{
    pnt=pnt;
}

QPointF Draw_LineArrow::getPnt()
{
    return pnt;
}

QPointF Draw_LineArrow::getStartPnt()
{
    return StrtPnt;
}

QPointF Draw_LineArrow::getEndPnt()
{
    return EndPnt;
}

QPointF Draw_LineArrow::getRectStartPnt()
{
    QPointF pnt;
    pnt.setX(getStartPnt().x()-5.0);
    pnt.setY(getStartPnt().y()-2.5);
    return pnt;
}

QPointF Draw_LineArrow::getRectEndPnt()
{
    QPointF pnt;
    pnt.setX(getEndPnt().x());
    pnt.setY(getEndPnt().y()-2.5);
    return pnt;
}

QPointF Draw_LineArrow::getBoundMinPnt()
{
    return bounding_min_pnt;
}

QPointF Draw_LineArrow::getBoundMaxPnt()
{
    return bounding_max_pnt;
}


void Draw_LineArrow::setState(int state)
{
    draw_state=state;
}

int Draw_LineArrow::getState()
{
    return draw_state;
}

void Draw_LineArrow::setMode(bool mode)
{
    draw_mode=mode;
}

bool Draw_LineArrow::getMode()
{
    return draw_mode;
}

bool Draw_LineArrow::isMouseClickedOnStartHandle(const QPointF pnt)
{

    if(this->Strt_Rect->isUnderMouse())
    {
        draw_state=1;
        return true;
    }
    else
        return false;

}

bool Draw_LineArrow::isMouseClickedOnEndHandle(const QPointF pnt)
{
    if(this->End_Rect->isUnderMouse())
    {
        draw_state=2;
        return true;
    }
    else
        return false;

}

bool Draw_LineArrow::isMouseClickedOnRotateHandle(const QPointF pnt)
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


bool Draw_LineArrow::isMouseClickedOnShape(const QPointF pnt)
{
    if(get_line(pnt))
    {
        qDebug()<<"entered item \n";
        item->setCursor(Qt::SizeAllCursor);
        draw_state=3;
        return true;
    }
    else
        return false;

}

bool Draw_LineArrow::get_line(QPointF pnt)
{
    //Bounding_box();

    /*To find a point is on the line, calcualte the distance between the end points of the line and
      distances between the clicked point and line start point and end point and sum them and compare with
      the line distance. if they are equal then the point is on the line*/

    //calculating the  distance between the end points of the line
    float x=(getEndPnt().x()-getStartPnt().x());
    float y=(getEndPnt().y()-getStartPnt().y());
    int dist=sqrt((y*y)+(x*x));

    //calculating the distance between the mouse clicked point and end point of the line
    float px=(getStartPnt().x()-pnt.x());
    float py=(getStartPnt().y()-pnt.y());
    int dist1=sqrt((py*py)+(px*px));

    //calculating the distance between the mouse clicked point and start point of the line
    int dist2=sqrt(((pnt.x()-getEndPnt().x())*(pnt.x()-getEndPnt().x()))+((pnt.y()-getEndPnt().y())*(pnt.y()-getEndPnt().y())));

    //qDebug()<<"values "<<dist<<" "<<dist1<<" "<<dist2<<"\n";

    //checking weather a clicked point is on the line,by compaing the distances
    if((((dist-2)<=(dist1+dist2))&&((dist+2)>=(dist1+dist2))||(dist==(dist1+dist2))))
    {
       return true;
    }
    else
        return false;

}

void Draw_LineArrow::BoundingBox()
{

}

QPen Draw_LineArrow::getPenColor()
{
     return pen;
}

void Draw_LineArrow::setTranslate(QPointF pnt,QPointF pnt1)
{

    if(getState()==1)
    {
        arrow_pnts[0]=(arrow_pnts[0]-(pnt-pnt1));
    QPointF pnt1,pnt2;

    pnt1.setX(((arrow_pnts[0].x()+arrow_pnts[3].x())/2)-5);
        pnt1.setY(arrow_pnts[0].y()-20);

        pnt2.setX(((arrow_pnts[0].x()+arrow_pnts[3].x())/2)+5);
        pnt2.setY(arrow_pnts[0].y()-10);

      Rot_Rect->setRect(QRectF(pnt1,pnt2));

    }

    if(getState()==2)
    {
       if(getStartPnt().x()<pnt1.x() && getStartPnt().y()==pnt1.y())
     {
          arrow_pnts[1]=pnt1;
      //arrow_pnts[1]=(arrow_pnts[1]-QPointF(5.0,0.0));
      arrow_pnts[2]=(arrow_pnts[1]+QPointF(0.0,-10.0));
      arrow_pnts[3]=(arrow_pnts[1]+QPointF(5.0,0.0));
      arrow_pnts[4]=(arrow_pnts[1]+QPointF(0.0,10.0));
      arrow_pnts[5]=arrow_pnts[1];

      End_Rect->setRect(QRectF(QPointF(arrow_pnts[3].x()+5.0,arrow_pnts[3].y()-5),QPointF(arrow_pnts[3].x()+10,arrow_pnts[3].y()+5)));

      QPointF pnt1,pnt2;

        pnt1.setX(((arrow_pnts[0].x()+arrow_pnts[3].x())/2)-5);
          pnt1.setY(arrow_pnts[0].y()-20);

          pnt2.setX(((arrow_pnts[0].x()+arrow_pnts[3].x())/2)+5);
          pnt2.setY(arrow_pnts[0].y()-10);

        Rot_Rect->setRect(QRectF(pnt1,pnt2));
     }

     if(getStartPnt().x()<pnt1.x() && getStartPnt().y()<pnt1.y())
     {
          arrow_pnts[1]=pnt1;
      arrow_pnts[1]=(arrow_pnts[1]-QPointF(5.0,5.0));
      arrow_pnts[2]=(arrow_pnts[1]+QPointF(10.0,-10.0));
      arrow_pnts[3]=(arrow_pnts[1]+QPointF(5.0,5.0));
      arrow_pnts[4]=(arrow_pnts[1]+QPointF(-10.0,10.0));
      arrow_pnts[5]=arrow_pnts[1];

      End_Rect->setRect(QRectF(QPointF(arrow_pnts[3].x(),arrow_pnts[3].y()),QPointF(arrow_pnts[3].x()+10,arrow_pnts[3].y()+10)));

      QPointF pnt1,pnt2,pnt3;


          pnt1.setX((arrow_pnts[3].x()-arrow_pnts[0].x())/2);
      pnt1.setY((arrow_pnts[3].y()-arrow_pnts[0].y())/2-20);

      pnt2.setX(arrow_pnts[0].x()+pnt1.x()+5);
      pnt2.setY(arrow_pnts[0].y()+pnt1.y()+5);

      pnt3.setX(arrow_pnts[0].x()+pnt1.x()+15);
      pnt3.setY(arrow_pnts[0].y()+pnt1.y()+15);


        Rot_Rect->setRect(QRectF(pnt2,pnt3));

     }

     if(getStartPnt().x()==pnt1.x() && getStartPnt().y()<pnt1.y())
     {
          arrow_pnts[1]=pnt1;
      arrow_pnts[1]=(arrow_pnts[1]-QPointF(0.0,5.0));
      arrow_pnts[2]=(arrow_pnts[1]+QPointF(10.0,0.0));
      arrow_pnts[3]=(arrow_pnts[1]+QPointF(0.0,5.0));
      arrow_pnts[4]=(arrow_pnts[1]+QPointF(-10.0,0.0));
      arrow_pnts[5]=arrow_pnts[1];


      End_Rect->setRect(QRectF(QPointF(arrow_pnts[3].x()-5,arrow_pnts[3].y()),QPointF(arrow_pnts[3].x()+5,arrow_pnts[3].y()+10)));

      QPointF pnt1,pnt2,pnt3;


          pnt1.setX(arrow_pnts[0].x());
      pnt1.setY((arrow_pnts[3].y()-arrow_pnts[0].y())/2);

      pnt2.setX(arrow_pnts[0].x()+5);
      pnt2.setY(arrow_pnts[0].y()+pnt1.y()+5);

      pnt3.setX(arrow_pnts[0].x()+15);
      pnt3.setY(arrow_pnts[0].y()+pnt1.y()+15);


        Rot_Rect->setRect(QRectF(pnt2,pnt3));

     }

     if(getStartPnt().x()>pnt1.x() && getStartPnt().y()<pnt1.y())
     {
          arrow_pnts[1]=pnt1;
      arrow_pnts[1]=(arrow_pnts[1]-QPointF(5.0,5.0));
      arrow_pnts[2]=(arrow_pnts[1]+QPointF(-10.0,-10.0));
      arrow_pnts[3]=(arrow_pnts[1]+QPointF(-5.0,5.0));
      arrow_pnts[4]=(arrow_pnts[1]+QPointF(10.0,10.0));
      arrow_pnts[5]=arrow_pnts[1];

      End_Rect->setRect(QRectF(QPointF(arrow_pnts[3].x()-10,arrow_pnts[3].y()-5),QPointF(arrow_pnts[3].x(),arrow_pnts[3].y()+5)));

      QPointF pnt1,pnt2,pnt3;


          pnt1.setX((arrow_pnts[3].x()-arrow_pnts[0].x())/2+25);
      pnt1.setY((arrow_pnts[3].y()-arrow_pnts[0].y())/2+15);

      pnt2.setX(arrow_pnts[0].x()+pnt1.x()+5);
      pnt2.setY(arrow_pnts[0].y()+pnt1.y()+5);

      pnt3.setX(arrow_pnts[0].x()+pnt1.x()+15);
      pnt3.setY(arrow_pnts[0].y()+pnt1.y()+15);


        Rot_Rect->setRect(QRectF(pnt2,pnt3));

     }

     if(getStartPnt().x()>pnt1.x() && getStartPnt().y()==pnt1.y())
     {
          arrow_pnts[1]=pnt1;
      arrow_pnts[1]=(arrow_pnts[1]-QPointF(5.0,0.0));
      arrow_pnts[2]=(arrow_pnts[1]+QPointF(0.0,-10.0));
      arrow_pnts[3]=(arrow_pnts[1]+QPointF(-5.0,0.0));
      arrow_pnts[4]=(arrow_pnts[1]+QPointF(0.0,10.0));
      arrow_pnts[5]=arrow_pnts[1];

      End_Rect->setRect(QRectF(QPointF(arrow_pnts[3].x()-10,arrow_pnts[3].y()-5),QPointF(arrow_pnts[3].x(),arrow_pnts[3].y()+5)));

      QPointF pnt1,pnt2,pnt3;

          pnt1.setX((arrow_pnts[3].x()-arrow_pnts[0].x())/2-5);
      pnt1.setY((arrow_pnts[3].y()-arrow_pnts[0].y())/2+15);

      pnt2.setX(arrow_pnts[0].x()+pnt1.x()+5);
      pnt2.setY(arrow_pnts[0].y()+pnt1.y()+5);

      pnt3.setX(arrow_pnts[0].x()+pnt1.x()+15);
      pnt3.setY(arrow_pnts[0].y()+pnt1.y()+15);


        Rot_Rect->setRect(QRectF(pnt2,pnt3));

     }

     if(getStartPnt().x()>pnt1.x() && getStartPnt().y()>pnt1.y())
     {
          arrow_pnts[1]=pnt1;
      arrow_pnts[1]=(arrow_pnts[1]+QPointF(5.0,5.0));
      arrow_pnts[2]=(arrow_pnts[1]+QPointF(10.0,-10.0));
      arrow_pnts[3]=(arrow_pnts[1]+QPointF(-5.0,-5.0));
      arrow_pnts[4]=(arrow_pnts[1]+QPointF(-10.0,10.0));
      arrow_pnts[5]=arrow_pnts[1];


      End_Rect->setRect(QRectF(QPointF(arrow_pnts[3].x()-10,arrow_pnts[3].y()-5),QPointF(arrow_pnts[3].x(),arrow_pnts[3].y()+5)));

      QPointF pnt1,pnt2,pnt3;

          pnt1.setX((arrow_pnts[3].x()-arrow_pnts[0].x())/2-20);
      pnt1.setY((arrow_pnts[3].y()-arrow_pnts[0].y())/2-5);

      pnt2.setX(arrow_pnts[0].x()+pnt1.x()+5);
      pnt2.setY(arrow_pnts[0].y()+pnt1.y()+5);

      pnt3.setX(arrow_pnts[0].x()+pnt1.x()+15);
      pnt3.setY(arrow_pnts[0].y()+pnt1.y()+15);


        Rot_Rect->setRect(QRectF(pnt2,pnt3));

     }

     if(getStartPnt().x()==pnt1.x() && getStartPnt().y()>pnt1.y())
     {
          arrow_pnts[1]=pnt1;
      arrow_pnts[1]=(arrow_pnts[1]+QPointF(0.0,5.0));
      arrow_pnts[2]=(arrow_pnts[1]+QPointF(10.0,0.0));
      arrow_pnts[3]=(arrow_pnts[1]+QPointF(0.0,-5.0));
      arrow_pnts[4]=(arrow_pnts[1]+QPointF(-10.0,0.0));
      arrow_pnts[5]=arrow_pnts[1];

      End_Rect->setRect(QRectF(QPointF(arrow_pnts[3].x()-10,arrow_pnts[3].y()-5),QPointF(arrow_pnts[3].x(),arrow_pnts[3].y()+5)));

      QPointF pnt1,pnt2,pnt3;

          pnt1.setX((arrow_pnts[3].x()-arrow_pnts[0].x())/2);
      pnt1.setY((arrow_pnts[3].y()-arrow_pnts[0].y())/2-5);

      pnt2.setX(arrow_pnts[0].x()+pnt1.x()+5);
      pnt2.setY(arrow_pnts[0].y()+pnt1.y()+5);

      pnt3.setX(arrow_pnts[0].x()+pnt1.x()+15);
      pnt3.setY(arrow_pnts[0].y()+pnt1.y()+15);


        Rot_Rect->setRect(QRectF(pnt2,pnt3));

     }

     if(getStartPnt().x()<pnt1.x() && getStartPnt().y()>pnt1.y())
     {
          arrow_pnts[1]=pnt1;
      arrow_pnts[1]=(arrow_pnts[1]+QPointF(5.0,5.0));
      arrow_pnts[2]=(arrow_pnts[1]+QPointF(-10.0,-10.0));
      arrow_pnts[3]=(arrow_pnts[1]+QPointF(5.0,-5.0));
      arrow_pnts[4]=(arrow_pnts[1]+QPointF(10.0,10.0));
      arrow_pnts[5]=arrow_pnts[1];

      End_Rect->setRect(QRectF(QPointF(arrow_pnts[3].x(),arrow_pnts[3].y()-5),QPointF(arrow_pnts[3].x()+10,arrow_pnts[3].y()+5)));

      QPointF pnt1,pnt2,pnt3;

          pnt1.setX((arrow_pnts[3].x()-arrow_pnts[0].x())/2-25);
      pnt1.setY((arrow_pnts[3].y()-arrow_pnts[0].y())/2-20);

      pnt2.setX(arrow_pnts[0].x()+pnt1.x()+5);
      pnt2.setY(arrow_pnts[0].y()+pnt1.y()+5);

      pnt3.setX(arrow_pnts[0].x()+pnt1.x()+15);
      pnt3.setY(arrow_pnts[0].y()+pnt1.y()+15);


        Rot_Rect->setRect(QRectF(pnt2,pnt3));

     }

    }

    if(getState()==3)
    {
       for(int i=0;i<arrow_pnts.size();i++)
       {
           arrow_pnts[i]=(arrow_pnts[i]-(pnt-pnt1));
       }

     item->setPos(item->pos()-(pnt-pnt1));
     item->update();
     Strt_Rect->setPos(Strt_Rect->pos()-(pnt-pnt1));
     Strt_Rect->update();
     End_Rect->setPos(End_Rect->pos()-(pnt-pnt1));
     End_Rect->update();
     Rot_Rect->setPos(Rot_Rect->pos()-(pnt-pnt1));
     Rot_Rect->update();

    }


    setStartPoint(arrow_pnts[0]);
    setEndPoint(arrow_pnts[3]);


    /*if(draw_state==3)
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
    }*/

}



void Draw_LineArrow::setRotate(const QPointF &pnt,const QPointF &pnt1)
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

void Draw_LineArrow::setScale(float x,float y)
{
   //shapes->scale(x,y);
}

void Draw_LineArrow::setItemId(int id)
{
    ItemId=id;
}


QPainterPath Draw_LineArrow::getLineArrow(QPointF pnt)
{
    QPainterPath linearrow;
    QPointF pnt1,pnt2;

    if(!getMode() && (getStartPnt().y()==pnt.y())&& (getStartPnt().x()<pnt.x()))
    {
    arrow_pnts[0]=getStartPnt();
      arrow_pnts[1]=pnt;

    pnt1.setX(pnt.x());
      pnt1.setY(pnt.y()-10.0);
      arrow_pnts[2]=pnt1;

      pnt1.setX(pnt.x()+5.0);
      pnt1.setY(pnt.y());
      arrow_pnts[3]=pnt1;

      pnt1.setX(pnt.x());
      pnt1.setY(pnt.y()+10.0);
      arrow_pnts[4]=pnt1;

      arrow_pnts[5]=pnt;

      linearrow.moveTo(getStartPnt());
      linearrow.addPolygon(QPolygonF(arrow_pnts));


      pnt2.setX(arrow_pnts[3].x());
      pnt2.setY(arrow_pnts[3].y());
      setEndPoint(pnt2);



   }


    if(!getMode() && (getStartPnt().y()< pnt.y())&& (getStartPnt().x()< pnt.x()))
    {

      arrow_pnts[0]=getStartPnt();
      arrow_pnts[1]=pnt;

      pnt1.setX(pnt.x()+(getEndPnt().x()-pnt.x()));
      pnt1.setY(pnt.y()-10.0);
      arrow_pnts[2]=pnt1;

      pnt1.setX(pnt.x()+5.0);
      pnt1.setY(pnt.y()+5.0);
      arrow_pnts[3]=pnt1;

      pnt1.setX(pnt.x()-(getEndPnt().x()-pnt.x()));
      pnt1.setY(pnt.y()+10.0);
      arrow_pnts[4]=pnt1;

      arrow_pnts[5]=pnt;



      linearrow.moveTo(getStartPnt());
      linearrow.addPolygon(QPolygonF(arrow_pnts));


      pnt2.setX(arrow_pnts[3].x());
      pnt2.setY(arrow_pnts[3].y());
      setEndPoint(pnt2);


   }

    if(!getMode() && (getStartPnt().y()> pnt.y())&& (getStartPnt().x()< pnt.x()))
    {

      arrow_pnts[0]=getStartPnt();
      arrow_pnts[1]=pnt;

      pnt1.setX(pnt.x()-(getEndPnt().x()-pnt.x()));
      pnt1.setY(pnt.y()-10.0);
      arrow_pnts[2]=pnt1;

      pnt1.setX(pnt.x()+5.0);
      pnt1.setY(pnt.y()-5.0);
      arrow_pnts[3]=pnt1;

      pnt1.setX(pnt.x()+(getEndPnt().x()-pnt.x()));
      pnt1.setY(pnt.y()+10.0);
      arrow_pnts[4]=pnt1;

      arrow_pnts[5]=pnt;

      linearrow.moveTo(getStartPnt());
      linearrow.addPolygon(QPolygonF(arrow_pnts));


      pnt2.setX(arrow_pnts[3].x());
      pnt2.setY(arrow_pnts[4].y());
      setEndPoint(pnt2);


   }

    if(!getMode() && (getStartPnt().x()==pnt.x())&&(getStartPnt().y()<pnt.y()))
    {

      arrow_pnts[0]=getStartPnt();
      arrow_pnts[1]=pnt;

      pnt1.setX(pnt.x()-10.0);
      pnt1.setY(pnt.y());
      arrow_pnts[2]=pnt1;

      pnt1.setX(pnt.x());
      pnt1.setY(pnt.y()+5.0);
      arrow_pnts[3]=pnt1;

      pnt1.setX(pnt.x()+10.0);
      pnt1.setY(pnt.y());
      arrow_pnts[4]=pnt1;

      arrow_pnts[5]=pnt;

      linearrow.moveTo(getStartPnt());
      linearrow.addPolygon(QPolygonF(arrow_pnts));


      pnt2.setX(arrow_pnts[3].x());
      pnt2.setY(arrow_pnts[3].y());
      setEndPoint(pnt2);


   }

    if(!getMode() && (getStartPnt().x()>pnt.x())&&(getStartPnt().y()<pnt.y()))
    {

      arrow_pnts[0]=getStartPnt();
      arrow_pnts[1]=pnt;

      pnt1.setX(pnt.x()-10.0);
      pnt1.setY(pnt.y()-(10.0));
      arrow_pnts[2]=pnt1;

      pnt1.setX(pnt.x()-5.0);
      pnt1.setY(pnt.y()+5.0);
      arrow_pnts[3]=pnt1;

      pnt1.setX(pnt.x()+10.0);
      pnt1.setY(pnt.y()+(10.0));
      arrow_pnts[4]=pnt1;

      arrow_pnts[5]=pnt;

      linearrow.moveTo(getStartPnt());
      linearrow.addPolygon(QPolygonF(arrow_pnts));


      pnt2.setX(arrow_pnts[3].x());
      pnt2.setY(arrow_pnts[3].y());
      setEndPoint(pnt2);


   }


    if(!getMode() && (getStartPnt().y()==pnt.y())&& (getStartPnt().x()>pnt.x()))
    {

      arrow_pnts[0]=getStartPnt();
      arrow_pnts[1]=pnt;

      pnt1.setX(pnt.x());
      pnt1.setY(pnt.y()-10.0);
      arrow_pnts[2]=pnt1;

      pnt1.setX(pnt.x()-5.0);
      pnt1.setY(pnt.y());
      arrow_pnts[3]=pnt1;

      pnt1.setX(pnt.x());
      pnt1.setY(pnt.y()+10.0);
      arrow_pnts[4]=pnt1;

      arrow_pnts[5]=pnt;

      linearrow.moveTo(getStartPnt());
      linearrow.addPolygon(QPolygonF(arrow_pnts));


      pnt2.setX(arrow_pnts[3].x());
      pnt2.setY(arrow_pnts[3].y());
      setEndPoint(pnt2);


   }


    if(!getMode() &&(getStartPnt().y()>pnt.y())&& (getStartPnt().x()>pnt.x()))
    {

        arrow_pnts[0]=getStartPnt();
        arrow_pnts[1]=pnt;

        pnt1.setX(pnt.x()-(getEndPnt().x()-pnt.x()));
        pnt1.setY(pnt.y()-10.0);
        arrow_pnts[2]=pnt1;

        pnt1.setX(pnt.x()-5.0);
        pnt1.setY(pnt.y()-5.0);
        arrow_pnts[3]=pnt1;

        pnt1.setX(pnt.x()+(getEndPnt().x()-pnt.x()));
        pnt1.setY(pnt.y()+10.0);
        arrow_pnts[4]=pnt1;

        arrow_pnts[5]=pnt;

        linearrow.moveTo(getStartPnt());
        linearrow.addPolygon(QPolygonF(arrow_pnts));


        pnt2.setX(arrow_pnts[3].x());
        pnt2.setY(arrow_pnts[3].y());
        setEndPoint(pnt2);


   }

    if(!getMode() && (getStartPnt().y()>pnt.y())&& (getStartPnt().x()==pnt.x()))
    {

        arrow_pnts[0]=getStartPnt();
        arrow_pnts[1]=pnt;

        pnt1.setX(pnt.x()-10.0);
        pnt1.setY(pnt.y());
        arrow_pnts[2]=pnt1;

        pnt1.setX(pnt.x());
        pnt1.setY(pnt.y()-5.0);
        arrow_pnts[3]=pnt1;

        pnt1.setX(pnt.x()+10.0);
        pnt1.setY(pnt.y());
        arrow_pnts[4]=pnt1;

        arrow_pnts[5]=pnt;

        linearrow.moveTo(getStartPnt());
        linearrow.addPolygon(QPolygonF(arrow_pnts));


        pnt2.setX(arrow_pnts[3].x());
        pnt2.setY(arrow_pnts[3].y());
        setEndPoint(pnt2);


   }

   if(getMode())
   {
     linearrow.moveTo(getStartPnt());
     linearrow.addPolygon(QPolygonF(arrow_pnts));
   }

  linearrow.moveTo(getStartPnt());
    linearrow.addPolygon(QPolygonF(arrow_pnts));
    //qDebug()<<"line arrow "<<linearrow.boundingRect().topLeft()<<"  "<<linearrow.boundingRect().bottomRight()<<"\n";

   return linearrow;
}

void Draw_LineArrow::drawImage(QPainter *painter, QString &text,QPointF point)
{

    QString str_x,str_y;
    QString color_r,color_g,color_b;

  QVector<QPointF> pnts(arrow_pnts.size());

  for(int i=0;i<pnts.size();i++)
  {
    pnts[i]=arrow_pnts[i];
    pnts[i]+=point;
  }

    QPainterPath linearrow;
    linearrow.addPolygon(QPolygonF(pnts));

    painter->setPen(this->pen);
    painter->drawPath(linearrow);


    text+="linearrow\n";
    text+="Coords";
  text+=" "+str_x.setNum(arrow_pnts.size()*2);

    for(int j=0;j<this->arrow_pnts.size();j++)
    {
         text+=" "+str_x.setNum((this->arrow_pnts[j].x()))+" "+str_y.setNum((this->arrow_pnts[j].y()))+" ";
     //text+=" "+str_x.setNum((this->StrtPnt.x()))+" "+str_y.setNum((this->StrtPnt.y()))+" ";
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

void Draw_LineArrow::setEdgeRects()
{
    QBrush rectbrush;
    rectbrush.setColor(QColor(0,175,225));
    rectbrush.setStyle(Qt::SolidPattern);

    Strt_Rect = new QGraphicsRectItem(QRectF(QPointF(StrtPnt.x()-5.0,StrtPnt.y()-5.0),QPointF(StrtPnt.x()+5.0,StrtPnt.y()+5.0)));
    Strt_Rect->setBrush(rectbrush);

    End_Rect = new QGraphicsRectItem(QRectF(QPointF(EndPnt.x(),EndPnt.y()-5.0),QPointF(EndPnt.x()+10.0,EndPnt.y()+5.0)));
    End_Rect->setBrush(rectbrush);


    QPointF pnt1,pnt2;

    pnt1.setX(((StrtPnt.x()+EndPnt.x())/2)-5);
    pnt1.setY(StrtPnt.y()-20);

    pnt2.setX(((StrtPnt.x()+EndPnt.x())/2)+5);
    pnt2.setY(StrtPnt.y()-10);

    Rot_Rect = new QGraphicsEllipseItem(QRectF(pnt1,pnt2));
    Rot_Rect->setBrush(rectbrush);
}


void Draw_LineArrow::updateEdgeRects()
{
    Strt_Rect->setRect(QRectF(QPointF(StrtPnt.x()-5.0,StrtPnt.y()-5.0),QPointF(StrtPnt.x()+5.0,StrtPnt.y()+5.0)));

    End_Rect->setRect(QRectF(QPointF(EndPnt.x(),EndPnt.y()-5.0),QPointF(EndPnt.x()+10.0,EndPnt.y()+5.0)));

    QPointF pnt1,pnt2;

    pnt1.setX(((StrtPnt.x()+EndPnt.x())/2)-5);
    pnt1.setY(StrtPnt.y()-20);

    pnt2.setX(((StrtPnt.x()+EndPnt.x())/2)+5);
    pnt2.setY(StrtPnt.y()-10);

    //print();
  //Rot_Rect->setRect(QRectF(pnt1,pnt2));

  //if(item->rotation()!=0)
       //Rot_Rect->setRect(QRectF(-pnt1,-pnt2));

    Strt_Rect->update();
    End_Rect->update();
    Rot_Rect->update();
}

int Draw_LineArrow::getItemId()
{
    return ItemId;
}


void Draw_LineArrow::setPen(const QColor color)
{
    this->pen=item->pen();
    this->pen.setColor(color);
    item->setPen(pen);

}

void Draw_LineArrow::setPenStyle(const int style)
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

void Draw_LineArrow::setPenWidth(const int width)
{
    this->pen=item->pen();
    this->pen.setWidth(width);
    item->setPen(pen);
}

QPen Draw_LineArrow::getPen()
{
    return pen;
}

void Draw_LineArrow::showHandles()
{
  if(!Strt_Rect->isVisible())
        Strt_Rect->show();
    if(!End_Rect->isVisible())
    End_Rect->show();
    if(!Rot_Rect->isVisible())
    Rot_Rect->show();
}

void Draw_LineArrow::hideHandles()
{
  if(Strt_Rect->isVisible())
        Strt_Rect->hide();
    if(End_Rect->isVisible())
        End_Rect->hide();
    if(Rot_Rect->isVisible())
        Rot_Rect->hide();
}


bool Draw_LineArrow::isClickedOnHandleOrShape(QPointF point)
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

void Draw_LineArrow::rotateShape(float angle)
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

QPointF Draw_LineArrow::getMinPoint()
{
  int minPntx,minPnty;
  QPointF pnt;

  minPntx=arrow_pnts[0].x();
  minPnty=arrow_pnts[0].y();

  for(int i=0;i<arrow_pnts.size();i++)
  {
    if(arrow_pnts[i].x()<minPntx)
      minPntx=arrow_pnts[i].x();
    if(arrow_pnts[i].y()<minPnty)
      minPnty=arrow_pnts[i].y();
  }

  pnt.setX(minPntx);
  pnt.setY(minPnty);

  return pnt;
}

QPointF Draw_LineArrow::getMaxPoint()
{
  int maxPntx,maxPnty;
  QPointF pnt;

  maxPntx=arrow_pnts[0].x();
  maxPnty=arrow_pnts[0].y();

  for(int i=0;i<arrow_pnts.size();i++)
  {
    if(arrow_pnts[i].x()>maxPntx)
      maxPntx=arrow_pnts[i].x();
    if(arrow_pnts[i].y()>maxPnty)
      maxPnty=arrow_pnts[i].y();
  }

  pnt.setX(maxPntx);
  pnt.setY(maxPnty);

  return pnt;
}



void Draw_LineArrow::print()
{
    qDebug()<<"Starting and Ending  points of line"<<getStartPnt()<<"  "<<getEndPnt()<<"\n";
}

