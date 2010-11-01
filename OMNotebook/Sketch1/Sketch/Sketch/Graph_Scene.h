#ifndef GRAPH_SCENE_H
#define GRAPH_SCENE_H

#include "basic.h"
#include "Draw_Line.h"
#include "Draw_rect.h"
#include "Draw_ellipse.h"
#include "Draw_polygon.h"
#include "Draw_RoundRect.h"
#include "Draw_Arc.h"
#include "Scene_Objects.h"



class Graph_Scene:public QGraphicsScene
{
    Q_OBJECT
  public:
    Graph_Scene(QObject *parent=0);
    void draw_object(QPointF pnt,QPointF pnt1,Draw_Line* line1,QPen pen);
    /*void draw_rect();
    void draw_line();
    void draw_rubber_rect();
    void draw_rubber();*/
    int draw_object_state,prev_draw_object_state,object_pos;
    void setObject(int object_id);
    void new_Scene();
    void save_Scene(QString file_name);
    void open_Scene(QString file_name);

    void save_xml_Scene(QString file_name);
    void save_image_Scene();

    void copy_object();
    void cut_object();
    void paste_object();

    //functions returing the minimum and maximum positions of the objects in the scene
    QPointF getDim();

    //Returns the postion of the objects
    void getObjectsPos(QVector<QPointF> &objectsPos);

   //Returns the objects in the scene
   QVector<Scene_Objects*> getObjects();

   //Retunrs the minimum and maximum of the overall objects
   void getMinPosition(QPointF &pnt);
   void getMaxPosition(QPointF &pnt1);


  protected:
     void mousePressEvent(QGraphicsSceneMouseEvent *);
     void mouseMoveEvent(QGraphicsSceneMouseEvent *);
     void mouseReleaseEvent(QGraphicsSceneMouseEvent *);
     void mouseDoubleClickEvent(QGraphicsSceneMouseEvent *);

     void keyPressEvent(QKeyEvent *);


  private:
     void draw_objects();

     void draw_line();
     void draw_line_move(QPointF pnt,QPointF pnt1);
     void draw_line_state(QPointF pnt,QPointF pnt1);
     bool check_object(QPointF pnt,Draw_Line* line1);
     int  check_intersection(QPointF pnt,QPointF pnt1);
     void draw_Scene();
     void draw_object();
     //object_indx stores the index of the object in objects vector.
     //index stores the index of slected object that is line,rectangle,ellipse.
     int object_indx,indx;
     bool mode;
     int polygon_indx;

     //variables to store the minimum and maximum position among the objects in the scene
     QPointF minPos,maxPos;

     void draw_rect();
     void draw_rect_move(QPointF pnt,QPointF pnt1);
     void draw_rect_state(QPointF pnt,QPointF pnt1);
     bool check_object(QPointF pnt,Draw_rect* line1);

     void draw_round_rect();
     void draw_round_rect_move(QPointF pnt,QPointF pnt1);
     void draw_round_rect_state(QPointF pnt,QPointF pnt1);
     bool check_object(QPointF pnt,Draw_RoundRect* round_rect1);

     void draw_ellep();
     void draw_ellep_move(QPointF pnt,QPointF pnt1);
     void draw_ellep_state(QPointF pnt,QPointF pnt1);
     bool check_object(QPointF pnt,Draw_ellipse* ellep1);

     void draw_polygon();
     void draw_polygon_move(QPointF pnt,QPointF pnt1);
     void draw_polygon_state(QPointF pnt,QPointF pnt1);
     bool check_object(QPointF pnt,Draw_polygon* polygon1);
     void draw_polygons();
     void hide_edges();

     void draw_arc();
     void draw_arc_move(QPointF pnt,QPointF pnt1);
     void draw_arc_state(QPointF pnt,QPointF pnt1);
     bool check_object(QPointF pnt,Draw_Arc* arc1);
     void draw_arcs();
     void hide_arc_edges();


     void hide_object_edges();

     void getDist(QPointF &vertex,float &dist);

     //Arc class variables
     Draw_Arc *arc,*temp_arc;
     QVector<Draw_Arc*> arcs;

     QPointF strt_pnt,strt1_pnt;
     QPointF last_pnt,objectPnt,objectPnt1;

     Draw_Line *line,*polygon_line;
     QVector<Draw_Line*> lines,poly_lines;

     Draw_rect *rect;
     QVector<Draw_rect*> rects;

     //Round Rectangle variables
     Draw_RoundRect *round_rect,*temp_round_rect;
     QVector<Draw_RoundRect*> round_rects;

     Draw_ellipse *ellep;
     QVector<Draw_ellipse*> elleps;
     Draw_polygon *polygon,*temp_polygon;
     QVector<Draw_polygon*> polygons;

     Scene_Objects *object1,*object2,*object3,*object5,*copy_object1;
     QVector<Scene_Objects*> objects,copy_objects;


     QVector<QPointF> pnts;

};

#endif // GRAPH_SCENE_H
