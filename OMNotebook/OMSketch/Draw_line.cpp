#include "Draw_Line.h"

Draw_Line::Draw_Line():line_draw_state(false)
{
    line_draw_mode=false;

    lines.clear();

    line = new QGraphicsLineItem();

    poly_pnts.clear();
    edgelines.clear();

    pen = QPen();
    pen.setColor(QColor(0,0,0));
    pen.setStyle(Qt::SolidLine);
    pen.setWidth(1);

    brush = QBrush();
    brush.setColor(QColor(255,255,255));
    brush.setStyle(Qt::NoBrush);

    angle=0;

  isObjectSelected=false;
}

void Draw_Line::setStartPoint(QPointF pnt)
{
     if(lines.isEmpty())
     {
          line->setLine(QLineF(pnt,pnt));
     }
     else
     {
          line = new QGraphicsLineItem();
          line->setLine(QLineF(pnt,pnt));
     }
}

void Draw_Line::setEndPoint(QPointF pnt)
{
     line->setLine(QLineF(line->line().p1(),pnt));
     lines.push_back(line);
}

QPointF Draw_Line::getStartPnt()
{
    return item->boundingRect().topLeft();
}

QPointF Draw_Line::getEndPnt()
{
    return item->boundingRect().bottomRight();
}

void Draw_Line::setPnt(QPointF pnt)
{
    line->setLine(QLineF(line->line().p1(),pnt));
    lines.push_back(line);
}


void Draw_Line::set_draw_mode(bool mode)
{
    line_draw_mode=mode;
}

bool Draw_Line::get_draw_mode()
{
    return line_draw_mode;
}

void Draw_Line::setLine(QLineF pline)
{
     line->setLine(pline);
}

void Draw_Line::setLine(int indx,QLineF pline)
{
     line=lines[indx];
     line->setLine(pline);
}

void Draw_Line::setState(int State)
{
    draw_state=State;
}

int Draw_Line::getState()
{
    return draw_state;
}

bool Draw_Line::isMouseClickedOnHandle(const QPointF pnt)
{
        bool found = false;

        for(int i=0;i<edge_items.size();i++)
        {
            if(edge_items[i]->isUnderMouse())
            {
                 draw_state=1;
                 found=true;
                 handle_index=i;
                 edge_items[i]->setCursor(Qt::CrossCursor);
                 break;
            }
        }
        return found;
}



bool Draw_Line::isMouseClickedOnRotateHandle(const QPointF pnt)
{
    if(Rot_Rect->isUnderMouse())
    {
        draw_state=3;

    QPointF pnt1;
        pnt1.setX((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2);
        pnt1.setY((item->boundingRect().topLeft().y()+item->boundingRect().bottomRight().y())/2);
        for(int i=0;i<edge_items.size();i++)
            edge_items[i]->setTransformOriginPoint(pnt1);
        item->setTransformOriginPoint(pnt1);
        Rot_Rect->setTransformOriginPoint(pnt1);
        return true;
    }
    else
        return false;

}

bool Draw_Line::isMouseClickedOnShape(const QPointF pnt)
{
     if(item->isUnderMouse())
     {
         draw_state=2;
         item->setCursor(Qt::SizeAllCursor);
         return true;
     }
     else
       return false;
}

void Draw_Line::setTranslate(QPointF pnt,QPointF pnt1)
{

  if(item->rotation()==0)
  {
        for(int i=0;i<poly_pnts.size();i++)
            poly_pnts[i]-=(pnt-pnt1);

       for(int i=0;i<poly_pnts.size();i++)
         edge_items[i]->setRect((QRectF(QPointF(poly_pnts[i].x()-5.0,poly_pnts[i].y()-5.0),QPointF(poly_pnts[i].x()+5.0,poly_pnts[i].y()+5.0))));


       QPainterPath polygon;

       if(!poly_pnts.isEmpty())
       {
          QPolygonF polygon_pnts(poly_pnts);
          polygon.addPolygon(polygon_pnts);
     }

     item->setPath(polygon);

       pnt.setX(((polygon.boundingRect().topLeft().x()+polygon.boundingRect().bottomRight().x())/2)-5);
       pnt.setY(polygon.boundingRect().topLeft().y()-20);

       pnt1.setX(((polygon.boundingRect().topLeft().x()+polygon.boundingRect().bottomRight().x())/2)+5);
       pnt1.setY(polygon.boundingRect().topLeft().y()-10);

       Rot_Rect->setRect(QRectF(pnt,pnt1));
     Rot_Rect->update();
  }

  if(item->rotation()!=0)
  {
    item->setPos(item->pos()-(pnt-pnt1));
    item->update();
    for(int i=0;i<edge_items.size();i++)
    {

      edge_items[i]->setPos(edge_items[i]->pos()-(pnt-pnt1));
      edge_items[i]->update();

    }

    Rot_Rect->setPos(Rot_Rect->pos()-(pnt-pnt1));
    Rot_Rect->update();
  }

}

void Draw_Line::setRotate(const QPointF &pnt,const QPointF &pnt1)
{
    if(pnt1.x()>pnt.x())
    {
       angle+=0.5;
       item->setRotation(angle);
     Rot_Rect->setRotation(angle);
       for(int i=0;i<edge_items.size();i++)
       {
           edge_items[i]->setRotation(angle);
           edge_items[i]->update();
       }
    }

    if(pnt.x()>pnt1.x())
    {
       angle-=0.5;
       item->setRotation(angle);
     Rot_Rect->setRotation(angle);
       for(int i=0;i<edge_items.size();i++)
       {
           edge_items[i]->setRotation(angle);
           edge_items[i]->update();
       }
    }

    item->update();
    Rot_Rect->update();


    /*QPointF rot_pnt(item->boundingRect().topLeft()-item->sceneBoundingRect().topLeft());
    QPointF rot_pnt1(item->boundingRect().bottomRight()-item->sceneBoundingRect().bottomRight());

    setStartPoint(item->sceneBoundingRect().topLeft()+rot_pnt);
    setEndPoint(item->sceneBoundingRect().bottomRight()+rot_pnt1);*/
}

void Draw_Line::setScale(float x,float y)
{
        /*for(int i=0;i<lines.size();i++)
        {
            lines[i]->setScale(x,y);
        }*/
}

QGraphicsLineItem* Draw_Line::getLine()
{
    return line;

}

QGraphicsLineItem* Draw_Line::getLine(int indx)
{
    if(!lines.isEmpty())
    {
        return lines[indx];
    }
  return NULL;
}

void Draw_Line::clear_lines()
{
     if(!lines.isEmpty())
         lines.clear();
}

void Draw_Line::setLines(QVector<QGraphicsLineItem*> plines)
{
     lines=plines;
}

QVector<QGraphicsLineItem*> Draw_Line::getLines()
{
    return lines;
}

void Draw_Line::drawEdges()
{
   QBrush rectbrush;
   rectbrush.setColor(QColor(0,175,225));
   rectbrush.setStyle(Qt::SolidPattern);
   for(int i=0;i<poly_pnts.size();i++)
   {
       QGraphicsRectItem *rect = new QGraphicsRectItem(QRectF(QPointF(poly_pnts[i].x()-5.0,poly_pnts[i].y()-5.0),QPointF(poly_pnts[i].x()+5.0,poly_pnts[i].y()+5.0)));
       rect->setBrush(rectbrush);
       edge_items.push_back(rect);
   }
}

QPainterPath Draw_Line::getPolyLine()
{
  QPainterPath polygon;
    if(!poly_pnts.isEmpty())
    {

        polygon.addPolygon(QPolygonF(poly_pnts));
        drawEdges();

        QBrush rectbrush;
        rectbrush.setColor(QColor(0,175,225));
        rectbrush.setStyle(Qt::SolidPattern);

        QPointF pnt1,pnt2;

        pnt1.setX(((polygon.boundingRect().topLeft().x()+polygon.boundingRect().bottomRight().x())/2)-5);
        pnt1.setY(polygon.boundingRect().topLeft().y()-20);

        pnt2.setX(((polygon.boundingRect().topLeft().x()+polygon.boundingRect().bottomRight().x())/2)+5);
        pnt2.setY(polygon.boundingRect().topLeft().y()-10);

        Rot_Rect = new QGraphicsEllipseItem(QRectF(pnt1,pnt2));
        Rot_Rect->setBrush(rectbrush);

        return polygon;
    }

  return polygon;
}

void Draw_Line::drawImage(QPainter *painter, QString &text,QPointF point)
{

    QString str_x,str_y,str_x1,str_y1;
    QString color_r,color_g,color_b;

  QVector<QPointF> pnts(poly_pnts.size());

  for(int i=0;i<pnts.size();i++)
  {
    pnts[i]=poly_pnts[i];
    pnts[i]+=point;
  }

    if(!poly_pnts.isEmpty())
    {
        QPainterPath polygon;
        polygon.addPolygon(QPolygonF(pnts));
        painter->setPen(this->pen);
        painter->setBrush(this->brush);
        painter->drawPath(polygon);

        text+="Line\n";
        text+="Coords";

        text+=" "+str_x.setNum(this->poly_pnts.size()*2);

        for(int j=0;j<this->poly_pnts.size();j++)
        {
           text+=" "+str_x.setNum((this->poly_pnts[j].x()))+" "+str_y.setNum((this->poly_pnts[j].y()))+" ";
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
}



QPainterPath Draw_Line::getPolyLine(int indx,QPointF pnt1,QPointF pnt2)
{
    if(indx==0)
    {
       poly_pnts[0]-=(pnt1-pnt2);
       poly_pnts[poly_pnts.size()]-=(pnt1-pnt2);
    }
    else
       poly_pnts[indx]-=(pnt1-pnt2);

    QPainterPath polygon;

    if(!poly_pnts.isEmpty())
    {
        QPolygonF polygon_pnts(poly_pnts);
        polygon.addPolygon(polygon_pnts);
    }


    pnt1.setX(((polygon.boundingRect().topLeft().x()+polygon.boundingRect().bottomRight().x())/2)-5);
    pnt1.setY(polygon.boundingRect().topLeft().y()-20);

    pnt2.setX(((polygon.boundingRect().topLeft().x()+polygon.boundingRect().bottomRight().x())/2)+5);
    pnt2.setY(polygon.boundingRect().topLeft().y()-10);

    Rot_Rect->setRect(QRectF(pnt1,pnt2));

    return polygon;
}


void Draw_Line::setEdgeLines()
{
    EdgeLine edgeLines;

    edgeLines.pnt=poly_pnts[0];
    edgeLines.next_line=1;
    edgeLines.prev_line=poly_pnts.size()-2;
    edgelines.push_back(edgeLines);

    for(int i=1;i<poly_pnts.size()-2;i++)
    {
       edgeLines.pnt=poly_pnts[i];
       edgeLines.next_line=i+1;
       edgeLines.prev_line=i-1;
       edgelines.push_back(edgeLines);
    }

    edgeLines.pnt=poly_pnts[poly_pnts.size()-1];
    edgeLines.next_line=poly_pnts.size()-3;
    edgeLines.prev_line=0;
    edgelines.push_back(edgeLines);
}

void Draw_Line::setPen(const QColor color)
{
    this->pen=item->pen();
    this->pen.setColor(color);
    item->setPen(pen);
}

void Draw_Line::setPenStyle(const int style)
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

void Draw_Line::setPenWidth(const int width)
{
    this->pen=item->pen();
    this->pen.setWidth(width);
    item->setPen(pen);
}

QPen Draw_Line::getPen()
{
    return item->pen();
}

void Draw_Line::showHandles()
{
   for(int i=0;i<edge_items.size();i++)
     {
          if(!edge_items[i]->isVisible())
          {
                edge_items[i]->show();
          }
   }

   if(!Rot_Rect->isVisible())
     Rot_Rect->show();
}

void Draw_Line::hideHandles()
{
   for(int i=0;i<edge_items.size();i++)
     {
          if(edge_items[i]->isVisible())
          {
                edge_items[i]->hide();
          }
   }

   if(Rot_Rect->isVisible())
     Rot_Rect->hide();

}

bool Draw_Line::isClickedOnHandleOrShape(QPointF point)
{
  if(getPolyLineDrawn())
    {
        if(isMouseClickedOnHandle(point))
           return true;
        else if(isMouseClickedOnShape(point))
            return true;
        else if(isMouseClickedOnRotateHandle(point))
            return true;
    }

  return false;
}

int Draw_Line::getHandelIndex()
{
  return handle_index;
}

void Draw_Line::rotateShape(float angle)
{

  item->setRotation(angle);
  Rot_Rect->setRotation(angle);
    for(int i=0;i<edge_items.size();i++)
    {
         edge_items[i]->setRotation(angle);
         edge_items[i]->update();
    }

  item->update();
    Rot_Rect->update();

  QPointF pnt1;

  pnt1.setX((item->boundingRect().topLeft().x()+item->boundingRect().bottomRight().x())/2);
    pnt1.setY((item->boundingRect().topLeft().y()+item->boundingRect().bottomRight().y())/2);
    for(int i=0;i<edge_items.size();i++)
          edge_items[i]->setTransformOriginPoint(pnt1);
    item->setTransformOriginPoint(pnt1);
    Rot_Rect->setTransformOriginPoint(pnt1);
}

Draw_Line::~Draw_Line()
{

}
