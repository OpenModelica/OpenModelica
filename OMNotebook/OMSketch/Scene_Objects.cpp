#include "Scene_Objects.h"

Scene_Objects::Scene_Objects()
{
  ObjectId=0;
  ObjectPos=0;
  pnts.clear();
  pen = QPen();
  brush = QBrush();

  QPointF pnt1(0,0);

  ObjectStrtBoundPnt=pnt1;
  ObjectEndBoundPnt=pnt1;

  rotation=0;
}

Scene_Objects * Scene_Objects::clone() {
  Scene_Objects * obj = new Scene_Objects();
  obj->setpen(pen);
  obj->setbrush(brush);
  obj->ObjectId = ObjectId;
  obj->ObjectPos = ObjectPos;
  obj->pnts = pnts;
  obj->rotation = rotation;
  obj->ObjectStrtBoundPnt = ObjectStrtBoundPnt;
  obj->ObjectEndBoundPnt = ObjectEndBoundPnt;
  return obj;
}

void Scene_Objects::setObjectPos(QPointF pnt,QPointF pnt1)
{
  qDebug()<<"objects pnts "<<pnt<<"  "<<pnt1<<"\n";
    ObjectStrtPnt=pnt;
    ObjectEndPnt=pnt1;
    /*QPainterPath path;

    QBrush rectbrush;
    rectbrush.setColor(QColor(0,175,225));
    rectbrush.setStyle(Qt::SolidPattern);


    if(ObjectId==2)
    {
        path.addRect(QRectF(pnt,pnt1));
        item = new QGraphicsPathItem(path);


        Strt_Rect = new QGraphicsRectItem(QRectF(QPointF(ObjectStrtPnt.x()-5.0,ObjectStrtPnt.y()-5.0),QPointF(ObjectStrtPnt.x()+5.0,ObjectStrtPnt.y()+5.0)));
        Strt_Rect->setBrush(rectbrush);

        End_Rect = new QGraphicsRectItem(QRectF(QPointF(ObjectEndPnt.x()-5.0,ObjectEndPnt.y()-5.0),QPointF(ObjectEndPnt.x()+5.0,ObjectEndPnt.y()+5.0)));
        End_Rect->setBrush(rectbrush);

        QPointF rot_pnt1,rot_pnt2;

        rot_pnt1.setX(((ObjectEndPnt.x()+ObjectEndPnt.x())/2)-5);
        rot_pnt1.setY(ObjectEndPnt.y()-20);

        rot_pnt2.setX(((ObjectEndPnt.x()+ObjectEndPnt.x())/2)+5);
        rot_pnt2.setY(ObjectEndPnt.y()-10);

        Rot_Rect = new QGraphicsEllipseItem(QRectF(rot_pnt1,rot_pnt2));
        Rot_Rect->setBrush(rectbrush);

    }*/
}


void Scene_Objects::setBoundPos(QPointF pnt,QPointF pnt1)
{
    ObjectStrtBoundPnt=pnt;
    ObjectEndBoundPnt=pnt1;
}

void Scene_Objects::setObjects(int object_type, int position)
{
     ObjectId=object_type;
     ObjectPos=position;
}

void Scene_Objects::CheckPnt(QPointF curr_pnt)
{
    pnt=curr_pnt;
}

int Scene_Objects::getObject(int &position) {
  if((ObjectStrtPnt.x()<=pnt.x())&&(ObjectEndPnt.x()>=pnt.x())&&(ObjectStrtPnt.y()<=pnt.y())&&(ObjectEndPnt.y()>=pnt.y())) {
    if ((ObjectId==1) || (ObjectId==2) || (ObjectId==3) || (ObjectId==4) || (ObjectId==5) || (ObjectId==7) || (ObjectId==9)) {
      position=ObjectPos;
      return ObjectId;
    }
  }
  if((ObjectStrtPnt.x()<=pnt.x())&&(ObjectEndPnt.x()>=pnt.x())&&(ObjectStrtPnt.y()<=ObjectEndPnt.y())&&(ObjectEndPnt.y()>=pnt.y())) {
    //qDebug()<<"Entered the arc condition\n";
    if((ObjectId==6) || (ObjectId==8)) {
      position=ObjectPos;
      return ObjectId;
    }
  }
  return 0;
}

void Scene_Objects::setSelected(bool selected) {
  this->selected=selected;
}

bool Scene_Objects::getSelected() {
    return selected;
}

void Scene_Objects::print()
{
  qDebug()<<"ObjectId "<<ObjectId<<"\n";
  qDebug()<<"Start & End Pnts "<<ObjectStrtPnt<<" "<<ObjectEndPnt<<"\n";
}

void Scene_Objects::setpen(const QPen pen) {
  this->pen = pen;
}

void Scene_Objects::setPenColor(const int r,const int g,const int b) {
  this->pen.setColor(QColor(r,g,b));
}

void Scene_Objects::setPenStyle(const int style) {
  switch(style)
  {
    case 1:
      this->pen.setStyle(Qt::SolidLine);
      break;
    case 2:
      this->pen.setStyle(Qt::DashLine);
      break;
    case 3:
      this->pen.setStyle(Qt::DotLine);
      break;
    case 4:
      this->pen.setStyle(Qt::DashDotLine);
      break;
    case 5:
      this->pen.setStyle(Qt::DashDotDotLine);
      break;
    default:
      break;
  }
}

void Scene_Objects::setPenWidth(const int width) {
    this->pen.setWidth(width);
}

void Scene_Objects::setColor(int r,int g,int b) {
  pen.setColor(QColor(r,g,b));
}

void Scene_Objects::setColor(const QColor rgb) {
  pen.setColor(rgb);
}

QColor Scene_Objects::getColor() {
  return pen.color();
}

QPen Scene_Objects::getpen() {
  return this->pen;
}

void Scene_Objects::setbrush(const QBrush brush) {
  this->brush=brush;
}

void Scene_Objects::setBrushColor(const int r,const int g,const int b) {
  this->brush.setColor(QColor(r,g,b));
}

void Scene_Objects::setBrushStyle(const int style)
{
    switch(style)
    {
      case 0:
         this->brush.setStyle(Qt::NoBrush);
         break;
      case 1:
         brush.setStyle(Qt::SolidPattern);
         break;
      case 2:
         brush.setStyle(Qt::Dense1Pattern);
         break;
      case 3:
         brush.setStyle(Qt::Dense2Pattern);
         break;
      case 4:
         brush.setStyle(Qt::Dense3Pattern);
         break;
      case 5:
         brush.setStyle(Qt::Dense4Pattern);
         break;
      case 6:
         brush.setStyle(Qt::Dense5Pattern);
         break;
      case 7:
         brush.setStyle(Qt::Dense6Pattern);
         break;
      case 8:
         brush.setStyle(Qt::Dense7Pattern);
         break;
      case 9:
         brush.setStyle(Qt::HorPattern);
         break;
      case 10:
         brush.setStyle(Qt::VerPattern);
         break;
      case 11:
         brush.setStyle(Qt::CrossPattern);
         break;
      case 12:
         brush.setStyle(Qt::BDiagPattern);
         break;
      case 13:
         brush.setStyle(Qt::FDiagPattern);
         break;
      case 14:
         brush.setStyle(Qt::DiagCrossPattern);
         break;
      default:
         break;
   }
}

QBrush Scene_Objects::getbrush() {
  return this->brush;
}

Scene_Objects::~Scene_Objects() {

}
