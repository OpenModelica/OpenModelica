#include "Draw_Arc.h"

Draw_Arc::Draw_Arc()
{
    draw_state=0;
    draw_mode=false;
    pen = new QPen();
}

void Draw_Arc::setArcStartPnt(QPointF strt_pnt)
{
    arc_strt_pnt=strt_pnt;
}

void Draw_Arc::setArcEndPnt(QPointF lst_pnt)
{
    arc_end_pnt=lst_pnt;
}


QPointF Draw_Arc::getArcStartPnt()
{
    return arc_strt_pnt;
}

QPointF Draw_Arc::getArcEndPnt()
{
    return arc_end_pnt;
}

QPointF Draw_Arc::getArcstartPnt()
{
    QPointF pnt;
    pnt.setX(arc_strt_pnt.x()-5.0);
    pnt.setY(arc_strt_pnt.y()-2.5);
    return pnt;
}

QPointF Draw_Arc::getArcendPnt()
{
    QPointF pnt;
    pnt.setX(arc_end_pnt.x());
    pnt.setY(arc_end_pnt.y()-2.5);
    return pnt;
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

int Draw_Arc::get_strt_edge(QPointF pnt)
{

    if(((arc_strt_pnt.x()-5.0<pnt.x())&&(arc_strt_pnt.x()>pnt.x()))&&(arc_strt_pnt.y()-2.5<pnt.y())&&(arc_strt_pnt.y()+5.0>pnt.y()))
    {
        qDebug()<<"Clicked at start point\n";
        this->pnt=arc_end_pnt;
        this->draw_state=1;
        return draw_state;
    }
}

int Draw_Arc::get_end_edge(QPointF pnt)
{
    if(((arc_end_pnt.x()+5.0>pnt.x())&&(arc_end_pnt.x()<pnt.x()))&&(arc_end_pnt.y()-2.5<pnt.y())&&(arc_end_pnt.y()+5.0>pnt.y()))
    {
         qDebug()<<"Clicked at end point\n";
         this->pnt=arc_strt_pnt;
         this->draw_state=2;
         qDebug()<<"draw state "<<draw_state;
         return draw_state;
    }


}

int Draw_Arc::get_line(QPointF pnt)
{
    Bounding_box();
    if(( bounding_min_pnt.x()<pnt.x())&&(bounding_min_pnt.y()<pnt.y())&&(bounding_max_pnt.x()>pnt.x())&&(bounding_max_pnt.y()>pnt.y()))
    {
         draw_state=3;
         qDebug()<<"line move\n";
         return draw_state;
    }
}

void Draw_Arc::Bounding_box()
{
    bounding_min_pnt.setX(arc_strt_pnt.x());
    bounding_min_pnt.setY(arc_strt_pnt.y());
    bounding_max_pnt.setX(arc_end_pnt.x());
    bounding_max_pnt.setY(arc_end_pnt.y());
}

QPen Draw_Arc::getPenColor()
{
     pen->setColor(QColor(0,0,255));
     return *pen;
}

void Draw_Arc::translate(QPointF pnt,QPointF pnt1)
{
    arc_strt_pnt-=pnt-pnt1;
    arc_end_pnt-=pnt-pnt1;
    Bounding_box();
}

bool Draw_Arc::Bounding_region(QPointF pnt)
{
    //bounding_end_pnt=bounding_end_pnt-bounding_strt_pnt;
    if((pnt.x()>bounding_strt_pnt.x()-5.0)&&(pnt.x()<bounding_end_pnt.x()+5.0)&&(pnt.y()>bounding_strt_pnt.y()-2.5) &&(pnt.y()<(bounding_end_pnt.y()+5.0)))
    {
        qDebug()<<"entered\n";
        return true;
    }
}

