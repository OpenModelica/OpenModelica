#include "Draw_ellipse.h"

Draw_ellipse::Draw_ellipse()
{
    draw_state=0;
    draw_mode=false;
}


void Draw_ellipse::setEllepStartPnt(QPointF strt_pnt)
{
    ellep_strt_pnt=strt_pnt;
}

void Draw_ellipse::setEllepEndPnt(QPointF lst_pnt)
{
    ellep_end_pnt=lst_pnt;
}


QPointF Draw_ellipse::getEllepStartPnt()
{
    return ellep_strt_pnt;
}

QPointF Draw_ellipse::getEllepEndPnt()
{
    return ellep_end_pnt;
}

QPointF Draw_ellipse::getRectStartPnt()
{
    QPointF pnt;
    pnt.setX(ellep_strt_pnt.x()-5.0);
    pnt.setY(ellep_strt_pnt.y()-2.5);
    return pnt;
}

QPointF Draw_ellipse::getRectEndPnt()
{
    QPointF pnt;
    pnt.setX(ellep_end_pnt.x());
    pnt.setY(ellep_end_pnt.y()-2.5);
    return pnt;
}

QPointF Draw_ellipse::getBoundMinPnt()
{
    return bounding_min_pnt;
}

QPointF Draw_ellipse::getBoundMaxPnt()
{
    return bounding_max_pnt;
}


void Draw_ellipse::setState(int state)
{
    draw_state=state;
}

int Draw_ellipse::getState()
{
    return draw_state;
}

void Draw_ellipse::setMode(bool mode)
{
    draw_mode=mode;
}

bool Draw_ellipse::getMode()
{
    return draw_mode;
}

int Draw_ellipse::get_strt_edge(QPointF pnt)
{

    if(((ellep_strt_pnt.x()-5.0<pnt.x())&&(ellep_strt_pnt.x()>pnt.x()))&&(ellep_strt_pnt.y()-2.5<pnt.y())&&(ellep_strt_pnt.y()+5.0>pnt.y()))
    {
        qDebug()<<"Clicked at start point\n";
        this->pnt=ellep_end_pnt;
        this->draw_state=1;
        return draw_state;
    }
}

int Draw_ellipse::get_end_edge(QPointF pnt)
{
    if(((ellep_end_pnt.x()+5.0>pnt.x())&&(ellep_end_pnt.x()<pnt.x()))&&(ellep_end_pnt.y()-2.5<pnt.y())&&(ellep_end_pnt.y()+5.0>pnt.y()))
    {
         qDebug()<<"Clicked at end point\n";
         this->pnt=ellep_strt_pnt;
         this->draw_state=2;
         qDebug()<<"draw state "<<draw_state;
         return draw_state;
    }


}

int Draw_ellipse::get_line(QPointF pnt)
{
    Bounding_box();
    if(( bounding_min_pnt.x()<pnt.x())&&(bounding_min_pnt.y()-2.5<pnt.y())&&(bounding_max_pnt.x()>pnt.x())&&(bounding_max_pnt.y()+5.0>pnt.y()))
    {
         draw_state=3;
         qDebug()<<"line move\n";
         return draw_state;
    }
}

void Draw_ellipse::Bounding_box()
{
    bounding_min_pnt.setX(ellep_strt_pnt.x());
    bounding_min_pnt.setY(ellep_strt_pnt.y()-2.5);
    bounding_max_pnt.setX(ellep_end_pnt.x());
    bounding_max_pnt.setY(ellep_end_pnt.y()+5.0);
}

QPen Draw_ellipse::getPenColor()
{
     pen->setColor(QColor(0,0,255));
     return *pen;
}

void Draw_ellipse::translate(QPointF pnt,QPointF pnt1)
{
    ellep_strt_pnt-=pnt-pnt1;
    ellep_end_pnt-=pnt-pnt1;
    Bounding_box();
}

bool Draw_ellipse::Bounding_region(QPointF pnt)
{
    //bounding_end_pnt=bounding_end_pnt-bounding_strt_pnt;
    if((pnt.x()>bounding_strt_pnt.x()-5.0)&&(pnt.x()<bounding_end_pnt.x()+5.0)&&(pnt.y()>bounding_strt_pnt.y()-2.5) &&(pnt.y()<(bounding_end_pnt.y()+5.0)))
    {
        qDebug()<<"entered\n";
        return true;
    }
}

