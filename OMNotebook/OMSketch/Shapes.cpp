#include "Shapes.h"

Shapes::Shapes(QPointF strt_pnt,QPointF end_pnt):StrtPnt(strt_pnt),EndPnt(end_pnt)
{

}

void Shapes::setStrtPnt(const QPointF &strt_pnt)
{
    StrtPnt=strt_pnt;
    qDebug()<<StrtPnt<<"\n";
}

void Shapes::setEndPnt(const QPointF &end_pnt)
{
    EndPnt=end_pnt;
    qDebug()<<EndPnt<<"\n";
}

QPointF Shapes::getStrtPnt()
{
    qDebug()<<StrtPnt<<"\n";
    return StrtPnt;
}


QPointF Shapes::getEndPnt()
{
    qDebug()<<EndPnt<<"\n";
    return EndPnt;
}

void Shapes::setGraphicsItem(QGraphicsItem *item)
{
    Item=item;
}

QGraphicsItem* Shapes::getGraphicsItem()
{
    return Item;
}


