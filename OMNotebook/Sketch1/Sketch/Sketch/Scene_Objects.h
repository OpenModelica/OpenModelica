#ifndef SCENE_OBJECTS_H
#define SCENE_OBJECTS_H

#include "basic.h"


class Scene_Objects
{
  public:
    Scene_Objects();
    ~Scene_Objects();
    void setObjects(int Object_type,int position);
    void setObjectPos(QPointF pnt, QPointF pnt1);
    void CheckPnt(QPointF curr_pnt);
    int getObject(int &position);
    QPointF ObjectStrtPnt,ObjectEndPnt,pnt;
    int ObjectId,ObjectPos;
    QGraphicsItem *item;

};

#endif // SCENE_OBJECTS_H
