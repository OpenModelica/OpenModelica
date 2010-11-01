#include "Draw_rect.h"

Draw_rect::Draw_rect()
{
    draw_state=0;
    draw_mode=false;
    pen = new QPen();
}

void Draw_rect::setRectStartPnt(QPointF strt_pnt)
{
    rect_strt_pnt=strt_pnt;
}

void Draw_rect::setRectEndPnt(QPointF lst_pnt)
{
    rect_end_pnt=lst_pnt;
}


QPointF Draw_rect::getRectStartPnt()
{
    return rect_strt_pnt;
}

QPointF Draw_rect::getRectEndPnt()
{
    return rect_end_pnt;
}

QPointF Draw_rect::getRectstartPnt()
{
    QPointF pnt;
    pnt.setX(rect_strt_pnt.x()-5.0);
    pnt.setY(rect_strt_pnt.y()-2.5);
    return pnt;
}

QPointF Draw_rect::getRectendPnt()
{
    QPointF pnt;
    pnt.setX(rect_end_pnt.x());
    pnt.setY(rect_end_pnt.y()-2.5);
    return pnt;
}

QPointF Draw_rect::getBoundMinPnt()
{
    return bounding_min_pnt;
}

QPointF Draw_rect::getBoundMaxPnt()
{
    return bounding_max_pnt;
}


void Draw_rect::setState(int state)
{
    draw_state=state;
}

int Draw_rect::getState()
{
    return draw_state;
}

void Draw_rect::setMode(bool mode)
{
    draw_mode=mode;
}

bool Draw_rect::getMode()
{
    return draw_mode;
}

int Draw_rect::get_strt_edge(QPointF pnt)
{

    if(((rect_strt_pnt.x()-5.0<pnt.x())&&(rect_strt_pnt.x()>pnt.x()))&&(rect_strt_pnt.y()-2.5<pnt.y())&&(rect_strt_pnt.y()+5.0>pnt.y()))
    {
        qDebug()<<"Clicked at start point\n";
        this->pnt=rect_end_pnt;
        this->draw_state=1;
        return draw_state;
    }
}

int Draw_rect::get_end_edge(QPointF pnt)
{
    if(((rect_end_pnt.x()+5.0>pnt.x())&&(rect_end_pnt.x()<pnt.x()))&&(rect_end_pnt.y()-2.5<pnt.y())&&(rect_end_pnt.y()+5.0>pnt.y()))
    {
         qDebug()<<"Clicked at end point\n";
         this->pnt=rect_strt_pnt;
         this->draw_state=2;
         qDebug()<<"draw state "<<draw_state;
         return draw_state;
    }


}

int Draw_rect::get_line(QPointF pnt)
{
    Bounding_box();
    if(( bounding_min_pnt.x()<pnt.x())&&(bounding_min_pnt.y()-2.5<pnt.y())&&(bounding_max_pnt.x()>pnt.x())&&(bounding_max_pnt.y()+5.0>pnt.y()))
    {
         draw_state=3;
         qDebug()<<"line move\n";
         return draw_state;
    }
}

void Draw_rect::Bounding_box()
{
    bounding_min_pnt.setX(rect_strt_pnt.x());
    bounding_min_pnt.setY(rect_strt_pnt.y()-2.5);
    bounding_max_pnt.setX(rect_end_pnt.x());
    bounding_max_pnt.setY(rect_end_pnt.y()+5.0);
}

QPen Draw_rect::getPenColor()
{
     pen->setColor(QColor(0,0,255));
     return *pen;
}

void Draw_rect::translate(QPointF pnt,QPointF pnt1)
{
    rect_strt_pnt-=pnt-pnt1;
    rect_end_pnt-=pnt-pnt1;
    Bounding_box();
}

bool Draw_rect::Bounding_region(QPointF pnt)
{
    //bounding_end_pnt=bounding_end_pnt-bounding_strt_pnt;
    if((pnt.x()>bounding_strt_pnt.x()-5.0)&&(pnt.x()<bounding_end_pnt.x()+5.0)&&(pnt.y()>bounding_strt_pnt.y()-2.5) &&(pnt.y()<(bounding_end_pnt.y()+5.0)))
    {
        qDebug()<<"entered\n";
        return true;
    }
}

