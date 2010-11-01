#include "Scene_Objects.h"

Scene_Objects::Scene_Objects()
{
    ObjectId=0;
    ObjectPos=0;

}

void Scene_Objects::setObjectPos(QPointF pnt,QPointF pnt1)
{
    ObjectStrtPnt=pnt;
    ObjectEndPnt=pnt1;
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

int Scene_Objects::getObject(int &position)
{
    qDebug()<<pnt<<"\n";
    qDebug()<<ObjectStrtPnt<<"   "<<ObjectEndPnt<<"  "<<pnt<<"\n";
    if((ObjectStrtPnt.x()<=pnt.x())&&(ObjectEndPnt.x()>=pnt.x())&&(ObjectStrtPnt.y()<=pnt.y())&&(ObjectEndPnt.y()>=pnt.y()))
    {
        qDebug()<<ObjectStrtPnt<<"   "<<ObjectEndPnt<<"  "<<pnt<<"\n";
        if(ObjectId==1)
        {
            qDebug()<<"ObjectId  "<<ObjectId<<"\n";
            position=ObjectPos;
            return ObjectId;
        }

        if(ObjectId==2)
        {
            qDebug()<<ObjectStrtPnt<<"   "<<ObjectEndPnt<<"  "<<pnt<<"\n";
            qDebug()<<"ObjectId  "<<ObjectId<<"\n";
            position=ObjectPos;
            return ObjectId;
        }

        if(ObjectId==3)
        {
            qDebug()<<ObjectStrtPnt<<"   "<<ObjectEndPnt<<"  "<<pnt<<"\n";
            qDebug()<<"ObjectId  "<<ObjectId<<"\n";
            position=ObjectPos;
            return ObjectId;
        }
    }

}

Scene_Objects::~Scene_Objects()
{

}
