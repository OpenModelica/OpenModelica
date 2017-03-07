#include "Draw_Text.h"

Draw_Text::Draw_Text(QPointF strt_pnt) {
  item = this;//new QGraphicsTextItem();
  draw_state=0;
  draw_mode=false;
  angle=0;
  isObjectSelected = false;
  text = "OMSketch";
  StrtPnt=strt_pnt;
  getText();
  setEdgeRects();
}

Draw_Text::Draw_Text() {
  item = this;//new QGraphicsTextItem();
  draw_state=0;
  draw_mode=false;
  angle=0;
  isObjectSelected = false;
  text = "OMSketch";
  getText();
  setEdgeRects();
}

void Draw_Text::setStartPoint(QPointF strt_pnt) {
  StrtPnt=strt_pnt;
}

void Draw_Text::setEndPoint(QPointF end_pnt) {
  EndPnt=end_pnt;
}

void Draw_Text::setDrawText(QString text) {
  this->text=text;
}

void Draw_Text::getText() {
  item->setPos(StrtPnt);
  item->setPlainText(this->text);
}

void Draw_Text::setMode(bool mode) {
  draw_mode=mode;
}

bool Draw_Text::getMode() {
  return draw_mode;
}

void Draw_Text::setState(int State) {
  draw_state=State;
}

int Draw_Text::getState() {
  return draw_state;
}

bool Draw_Text::getStrtEdge(QPointF pnt) {
  if(Strt_Rect->isUnderMouse()) {
    draw_state=1;
    Strt_Rect->setCursor(Qt::CrossCursor);
    return true;
  } else {
    return false;
  }
}

bool Draw_Text::getEndEdge(QPointF pnt) {
  if(End_Rect->isUnderMouse()) {
    draw_state=2;
    End_Rect->setCursor(Qt::CrossCursor);
    return true;
  } else {
    return false;
  }
}

bool Draw_Text::getRotEdge(const QPointF pnt) {
  if(Rot_Rect->isUnderMouse()) {
    draw_state=4;
    QPointF pnt1;
    pnt1.setX((Rot_Rect->boundingRect().topLeft().x()+Rot_Rect->boundingRect().bottomRight().x())/2);
    pnt1.setY((Rot_Rect->boundingRect().topLeft().y()+Rot_Rect->boundingRect().bottomRight().y())/2);
    item->setTransformOriginPoint(pnt1);
    Strt_Rect->setTransformOriginPoint(pnt1);
    End_Rect->setTransformOriginPoint(pnt1);
    Rot_Rect->setTransformOriginPoint(pnt1);
    return true;
  } else {
    return false;
  }
}

bool Draw_Text::getItemSelected(const QPointF pnt) {
  if(item->isUnderMouse()) {
    draw_state=3;
    setCursor(Qt::SizeAllCursor);
    return true;
  } else {
    return false;
  }
}

void Draw_Text::setEdgeRects() {
  QBrush rectbrush;
  rectbrush.setColor(QColor(0,175,225));
  rectbrush.setStyle(Qt::SolidPattern);

  StrtPnt+=item->boundingRect().topLeft();
  Strt_Rect = new QGraphicsRectItem(QRectF(QPointF(StrtPnt.x()-5.0,StrtPnt.y()-5.0),QPointF(StrtPnt.x()+5.0,StrtPnt.y()+5.0)));
  Strt_Rect->setBrush(rectbrush);

  EndPnt=item->boundingRect().bottomRight();
  EndPnt+=StrtPnt;
  End_Rect = new QGraphicsRectItem(QRectF(QPointF(EndPnt.x()-5.0,EndPnt.y()-5.0),QPointF(EndPnt.x()+5.0,EndPnt.y()+5.0)));
  End_Rect->setBrush(rectbrush);
  //qDebug()<<"Start & EndPnt pnt "<<StrtPnt<<" "<<EndPnt<<"\n";

  QPen bound_rect;
  bound_rect.setStyle(Qt::DashLine);
  Bounding_Rect = new QGraphicsRectItem(QRectF(item->boundingRect().topLeft(),item->boundingRect().bottomRight()));
  Bounding_Rect->setPen(bound_rect);

  QPointF pnt1,pnt2;
  pnt1.setX(((StrtPnt.x()+EndPnt.x())/2)-5);
  pnt1.setY(StrtPnt.y()-20);
  pnt2.setX(((StrtPnt.x()+EndPnt.x())/2)+5);
  pnt2.setY(StrtPnt.y()-10);
  Rot_Rect = new QGraphicsEllipseItem(QRectF(pnt1,pnt2));
  Rot_Rect->setBrush(rectbrush);
}

void Draw_Text::updateEdgeRects() {
  Strt_Rect->setRect(QRectF(QPointF(StrtPnt.x()-5.0,StrtPnt.y()-5.0),QPointF(StrtPnt.x()+5.0,StrtPnt.y()+5.0)));
  End_Rect->setRect(QRectF(QPointF(EndPnt.x()-5.0,EndPnt.y()-5.0),QPointF(EndPnt.x()+5.0,EndPnt.y()+5.0)));
  Bounding_Rect->setRect(QRectF(item->boundingRect().topLeft(),item->boundingRect().bottomRight()));

  QPointF pnt1,pnt2;
  pnt1.setX(((StrtPnt.x()+EndPnt.x())/2)-5);
  pnt1.setY(StrtPnt.y()-20);
  pnt2.setX(((StrtPnt.x()+EndPnt.x())/2)+5);
  pnt2.setY(StrtPnt.y()-10);
  Rot_Rect->setRect(QRectF(pnt1,pnt2));
  Strt_Rect->update();
  End_Rect->update();
  Rot_Rect->update();
}


void Draw_Text::setTranslate(QPointF pnt,QPointF pnt1) {
  if(draw_state==3) {
    item->setPos(item->pos()-(pnt-pnt1));
    Strt_Rect->setPos(Strt_Rect->pos()-(pnt-pnt1));
    End_Rect->setPos(End_Rect->pos()-(pnt-pnt1));
    Rot_Rect->setPos(Rot_Rect->pos()-(pnt-pnt1));
    item->update();
    Strt_Rect->update();
    End_Rect->update();
  } else if(draw_state==1) {
    Strt_Rect->setPos(Strt_Rect->pos()-(pnt-pnt1));
    Strt_Rect->update();
  } else if(draw_state==2) {
    End_Rect->setPos(End_Rect->pos()-(pnt-pnt1));
    End_Rect->update();
  }
}

void Draw_Text::setRotate(const QPointF &pnt,const QPointF &pnt1) {
  if(pnt1.x()>pnt.x()) {
    angle+=0.5;
    item->setRotation(angle);
    Strt_Rect->setRotation(angle);
    End_Rect->setRotation(angle);
    Rot_Rect->setRotation(angle);
  }
  if(pnt.x()>pnt1.x()) {
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

void Draw_Text::setScale(float x,float y)
{
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
   item->setTransform(QTransform::fromScale(x, y), true);
#else
   item->scale(x,y);
#endif
}

void Draw_Text::showHandles() {
  if(!Strt_Rect->isVisible())
    Strt_Rect->show();
  if(!End_Rect->isVisible())
    End_Rect->show();
  if(!Rot_Rect->isVisible())
    Rot_Rect->show();
}

void Draw_Text::hideHandles() {
  if(Strt_Rect->isVisible())
    Strt_Rect->hide();
  if(End_Rect->isVisible())
    End_Rect->hide();
  if(Rot_Rect->isVisible())
    Rot_Rect->hide();
}
