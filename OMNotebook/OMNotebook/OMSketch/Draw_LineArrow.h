#ifndef DRAW_LINEARROW_H
#define DRAW_LINEARROW_H

#include "basic.h"

class QGraphicsItem;
class QGraphicsPathItem;
class QPainter;
class QStyleOptionGraphicsItem;
class QWidget;
class QRectF;

class Draw_LineArrow:public QGraphicsPathItem
{
   public:
    Draw_LineArrow();

    Draw_LineArrow(QPointF strt_pnt,QPointF end_pnt);

    void setDefaults();

    //Getting and setting lines initial and last positions
    QPointF getStartPnt();
    QPointF getEndPnt();
    QPointF getPnt();
    QPointF getBoundMinPnt();
    QPointF getBoundMaxPnt();

    void setStartPoint(QPointF strt_pnt);
    void setEndPoint(QPointF lst_pnt);
    void setPnt(QPointF pnt);
    //void setGraphicsItem(QGraphicsItem *item);
    void setItemId(int id);


    //Getting and setting lines drawing states and drawing mode
    int getState();
    void setState(int State);

    bool getMode();
    void setMode(bool mode);

    void setPen(const QColor color);
    void setPenStyle(const int style);
    void setPenWidth(const int width);
    QPen getPen();

    //QGraphicsItem* getGraphicsItem();
    int getItemId();

    //getting Rectangle Points
    QPointF getRectStartPnt();
    QPointF getRectEndPnt();

    //checking the mouse position to resize and move line
    bool isMouseClickedOnStartHandle(const QPointF pnt);
    bool isMouseClickedOnEndHandle(const QPointF pnt);
    bool isMouseClickedOnRotateHandle(const QPointF pnt);
    bool isMouseClickedOnShape(const QPointF pnt);
    bool get_line(QPointF pnt);
    bool isClickedOnHandleOrShape(QPointF point);

    QPainterPath getLineArrow(QPointF pnt);
    //writes the shapes and shapes attributes to an image
    void drawImage(QPainter *painter,QString &text,QPointF point);

    void setEdgeRects();
    void updateEdgeRects();

    //setting the pen color
    QPen getPenColor();

    void setTranslate(QPointF pnt,QPointF pnt1);
    void setRotate(const QPointF &pnt,const QPointF &pnt1);
    void setScale(float x,float y);

    //show handles
    void showHandles();
    //hide handles
    void hideHandles();

    //rotate the shapes
    void rotateShape(float angle);

    //gets the min and max of linearrow points
    QPointF getMinPoint();
    QPointF getMaxPoint();

    virtual QPointF getTranslate(){return QPointF(0,0);}
    virtual float getRotate(float angle){return 0;}
    virtual QPointF getScale(float x,float y){return QPointF(0,0);}

    virtual void BoundingBox();


    QPointF pnt,bounding_strt_pnt,bounding_end_pnt;
    QGraphicsPathItem* item;
    QGraphicsRectItem *Strt_Rect,*End_Rect;
    QGraphicsEllipseItem *Rot_Rect;
    void print();

    float angle;
    bool isObjectSelected;
    QVector<QPointF> arrow_pnts;
    ~Draw_LineArrow(){}


private:

    QPointF bounding_min_pnt,bounding_max_pnt;
    QPointF StrtPnt,EndPnt;
    int draw_state;
    bool draw_mode;
    QPen pen;
    int ItemId;
    Draw_LineArrow* object;
};
#endif // DRAW_LINEARROW_H
