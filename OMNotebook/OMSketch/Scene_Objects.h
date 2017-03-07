#ifndef SCENE_OBJECTS_H
#define SCENE_OBJECTS_H

#include "basic.h"
#include "Draw_Rectangle.h"


class Scene_Objects
{
  public:
    Scene_Objects();
    ~Scene_Objects();
    Scene_Objects *clone();
    void setObjects(int Object_type,int position);
    void setBoundPos(QPointF pnt, QPointF pnt1);
    void setObjectPos(QPointF pnt, QPointF pnt1);
    void CheckPnt(QPointF curr_pnt);
    int getObject(int &position);
    void setSelected(bool selected);
    bool getSelected();

    void setColor(int r, int g,int b);
    void setColor(const QColor rgb);
    QColor getColor();

    void setpen(const QPen pen);
    void setPenColor(const int r, const int g,const int b);
    void setPenStyle(const int style);
    void setPenWidth(const int width);
    QPen getpen();

    void setbrush(const QBrush brush);
    void setBrushColor(const int r,const int g,const int b);
    void setBrushStyle(const int style);
    QBrush getbrush();

    void print();
    QPointF ObjectStrtPnt,ObjectEndPnt,pnt,ObjectStrtBoundPnt,ObjectEndBoundPnt;
    bool selected;
    QVector<QPointF> pnts;
    int ObjectId,ObjectPos,ObjectState,ObjectIndx;
    int rotation;
    QGraphicsPathItem *item;
    QGraphicsRectItem *Strt_Rect,*End_Rect;
    QGraphicsEllipseItem *Rot_Rect;
    QPen pen;
    QBrush brush;
};

#endif // SCENE_OBJECTS_H
