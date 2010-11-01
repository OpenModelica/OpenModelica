#include "Draw_RoundRect.h"

Draw_RoundRect::Draw_RoundRect()
{
    draw_state=0;
    draw_mode=false;
    pen = new QPen();

    radius=15;

}

void Draw_RoundRect::setRoundRectStartPnt(QPointF strt_pnt)
{
    round_rect_strt_pnt=strt_pnt;
}

void Draw_RoundRect::setRoundRectEndPnt(QPointF lst_pnt)
{
    round_rect_end_pnt=lst_pnt;
}


QPointF Draw_RoundRect::getRoundRectStartPnt()
{
    return round_rect_strt_pnt;
}

QPointF Draw_RoundRect::getRoundRectEndPnt()
{
    return round_rect_end_pnt;
}

QPointF Draw_RoundRect::getRoundRectstartPnt()
{
    QPointF pnt;
    pnt.setX(round_rect_strt_pnt.x()-5.0);
    pnt.setY(round_rect_strt_pnt.y()-2.5);
    return pnt;
}

QPointF Draw_RoundRect::getRoundRectendPnt()
{
    QPointF pnt;
    pnt.setX(round_rect_end_pnt.x());
    pnt.setY(round_rect_end_pnt.y()-2.5);
    return pnt;
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

int Draw_RoundRect::get_strt_edge(QPointF pnt)
{

    if(((round_rect_strt_pnt.x()-5.0<pnt.x())&&(round_rect_strt_pnt.x()>pnt.x()))&&(round_rect_strt_pnt.y()-2.5<pnt.y())&&(round_rect_strt_pnt.y()+5.0>pnt.y()))
    {
        qDebug()<<"Clicked at start point\n";
        this->pnt=round_rect_end_pnt;
        this->draw_state=1;
        return draw_state;
    }
}

int Draw_RoundRect::get_end_edge(QPointF pnt)
{
    if(((round_rect_end_pnt.x()+5.0>pnt.x())&&(round_rect_end_pnt.x()<pnt.x()))&&(round_rect_end_pnt.y()-2.5<pnt.y())&&(round_rect_end_pnt.y()+5.0>pnt.y()))
    {
         qDebug()<<"Clicked at end point\n";
         this->pnt=round_rect_strt_pnt;
         this->draw_state=2;
         qDebug()<<"draw state "<<draw_state;
         return draw_state;
    }


}

int Draw_RoundRect::get_line(QPointF pnt)
{
    Bounding_box();
    if(( bounding_min_pnt.x()<pnt.x())&&(bounding_min_pnt.y()<pnt.y())&&(bounding_max_pnt.x()>pnt.x())&&(bounding_max_pnt.y()>pnt.y()))
    {
         draw_state=3;
         qDebug()<<"line move\n";
         return draw_state;
    }
}

void Draw_RoundRect::Bounding_box()
{
    bounding_min_pnt.setX(round_rect_strt_pnt.x());
    bounding_min_pnt.setY(round_rect_strt_pnt.y());
    bounding_max_pnt.setX(round_rect_end_pnt.x());
    bounding_max_pnt.setY(round_rect_end_pnt.y());
}

QPen Draw_RoundRect::getPenColor()
{
     pen->setColor(QColor(0,0,255));
     return *pen;
}

void Draw_RoundRect::translate(QPointF pnt,QPointF pnt1)
{
    round_rect_strt_pnt-=pnt-pnt1;
    round_rect_end_pnt-=pnt-pnt1;
    Bounding_box();
}

bool Draw_RoundRect::Bounding_region(QPointF pnt)
{
    //bounding_end_pnt=bounding_end_pnt-bounding_strt_pnt;
    if((pnt.x()>bounding_strt_pnt.x()-5.0)&&(pnt.x()<bounding_end_pnt.x()+5.0)&&(pnt.y()>bounding_strt_pnt.y()-2.5) &&(pnt.y()<(bounding_end_pnt.y()+5.0)))
    {
        qDebug()<<"entered\n";
        return true;
    }
}


