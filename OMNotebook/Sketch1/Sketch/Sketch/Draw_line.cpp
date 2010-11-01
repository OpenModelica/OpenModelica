#include "Draw_Line.h"

Draw_Line::Draw_Line()
{
    draw_state=0;
    draw_mode=false;
    pen = new QPen();


}

void Draw_Line::setLineStartPnt(QPointF strt_pnt)
{
    line_strt_pnt=strt_pnt;
}

void Draw_Line::setLineEndPnt(QPointF lst_pnt)
{
    line_end_pnt=lst_pnt;
}

void Draw_Line::setPnt(QPointF pnt)
{
    pnt=pnt;
}

QPointF Draw_Line::getPnt()
{
    return pnt;
}

QPointF Draw_Line::getLineStartPnt()
{
    return line_strt_pnt;
}

QPointF Draw_Line::getLineEndPnt()
{
    return line_end_pnt;
}

QPointF Draw_Line::getRectStartPnt()
{
    QPointF pnt;
    pnt.setX(line_strt_pnt.x()-5.0);
    pnt.setY(line_strt_pnt.y()-2.5);
    return pnt;
}

QPointF Draw_Line::getRectEndPnt()
{
    QPointF pnt;
    pnt.setX(line_end_pnt.x());
    pnt.setY(line_end_pnt.y()-2.5);
    return pnt;
}

QPointF Draw_Line::getBoundMinPnt()
{
    return bounding_min_pnt;
}

QPointF Draw_Line::getBoundMaxPnt()
{
    return bounding_max_pnt;
}


void Draw_Line::setState(int state)
{
    draw_state=state;
}

int Draw_Line::getState()
{
    return draw_state;
}

void Draw_Line::setMode(bool mode)
{
    draw_mode=mode;
}

bool Draw_Line::getMode()
{
    return draw_mode;
}

int Draw_Line::get_strt_edge(QPointF pnt)
{

    if(((line_strt_pnt.x()-5.0<pnt.x())&&(line_strt_pnt.x()>pnt.x()))&&(line_strt_pnt.y()-2.5<pnt.y())&&(line_strt_pnt.y()+5.0>pnt.y()))
    {
        qDebug()<<"Clicked at start point\n";
        this->pnt=line_end_pnt;
        this->draw_state=1;
        return draw_state;
    }
}

int Draw_Line::get_end_edge(QPointF pnt)
{
    if(((line_end_pnt.x()+5.0>pnt.x())&&(line_end_pnt.x()<pnt.x()))&&(line_end_pnt.y()-2.5<pnt.y())&&(line_end_pnt.y()+5.0>pnt.y()))
    {
         qDebug()<<"Clicked at end point\n";
         this->pnt=line_strt_pnt;
         this->draw_state=2;
         qDebug()<<"draw state "<<draw_state;
         return draw_state;
    }


}

int Draw_Line::get_line(QPointF pnt)
{
    Bounding_box();
    if(( bounding_min_pnt.x()<pnt.x())&&(bounding_min_pnt.y()-2.5<pnt.y())&&(bounding_max_pnt.x()>pnt.x())&&(bounding_max_pnt.y()+5.0>pnt.y()))
    {
         draw_state=3;
         qDebug()<<"line move\n";
         return draw_state;
    }
}

void Draw_Line::Bounding_box()
{
    bounding_min_pnt.setX(line_strt_pnt.x());
    bounding_min_pnt.setY(line_strt_pnt.y()-2.5);
    bounding_max_pnt.setX(line_end_pnt.x());
    bounding_max_pnt.setY(line_end_pnt.y()+5.0);
}

QPen Draw_Line::getPenColor()
{
     pen->setColor(QColor(0,0,255));
     return *pen;
}

void Draw_Line::translate(QPointF pnt,QPointF pnt1)
{
    line_strt_pnt-=pnt-pnt1;
    line_end_pnt-=pnt-pnt1;
    Bounding_box();
}

bool Draw_Line::Bounding_region(QPointF pnt)
{
    //bounding_end_pnt=bounding_end_pnt-bounding_strt_pnt;
    if((pnt.x()>bounding_strt_pnt.x()-5.0)&&(pnt.x()<bounding_end_pnt.x()+5.0)&&(pnt.y()>bounding_strt_pnt.y()-2.5) &&(pnt.y()<(bounding_end_pnt.y()+5.0)))
    {
        qDebug()<<"entered\n";
        return true;
    }
}
