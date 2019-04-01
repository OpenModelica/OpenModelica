#ifndef GRAPH_SCENE_H
#define GRAPH_SCENE_H

#include "basic.h"
#include "Draw_Arc.h"
#include "Draw_Arrow.h"
#include "Draw_Line.h"
#include "Draw_LineArrow.h"
#include "Draw_Rectangle.h"
#include "Draw_Ellipse.h"
#include "Draw_Polygon.h"
#include "Draw_RoundRect.h"
#include "Draw_Triangle.h"
#include "Draw_Text.h"
#include "Scene_Objects.h"
#include "Sketch_Files.h"


class Graph_Scene:public QGraphicsScene
{
    Q_OBJECT
  public:
    Graph_Scene(QObject *parent=0);
    void draw_object(QPointF pnt,QPointF pnt1,Draw_Line* line1,QPen pen);
    int objectToDraw,objectToEdit,object_pos;
    void setObject(int object_id);
    void new_Scene();
    void save_Scene(QString file_name);

    void open_Scene(QString file_name);
    void open_Scene(const QVector<int> &values,QVector<float> &value);

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

    void setPen(const QPen Pen);
    void setPenStyle(const int style);
    void setPenWidth(const int width);
    QPen getPen();

    void setBrush(const QBrush brush);
    void setBrushStyle(const int style);
    QBrush getBrush();

    //method to write to an image
    void writeToImage(QPainter *painter,QString &text,QPointF point);

    bool isMultipleSelected;

    //hides the shapes handles
    void hide_object_edges();

    void getSelectedShapeProperties(QPen &shapePen,QBrush &shapeBrush);

    Draw_Rectangle *rect;
    bool isObjectEdited;
    bool isShapeImported;

  signals:
    void item_selected(Graph_Scene* scene_item);

  protected:
    void mousePressEvent(QGraphicsSceneMouseEvent *);
    void mouseMoveEvent(QGraphicsSceneMouseEvent *);
    void mouseReleaseEvent(QGraphicsSceneMouseEvent *);
    void mouseDoubleClickEvent(QGraphicsSceneMouseEvent *);

    void keyPressEvent(QKeyEvent *);
    void keyReleaseEvent(QKeyEvent *);

  private:
    void draw_objects();
    void updateObjects();
    void selectedObjects();
    void deleteShapes();

    //object_indx stores the index of the object in objects vector.
    //index stores the index of slected object that is line,rectangle,ellipse.
    int object_indx,indx;
    bool linemode,mode,isCopySelected,line_drawn;
    int polyline_indx,polygon_indx;

    //variables to store the minimum and maximum position among the objects in the scene
    QPointF minPos,maxPos;

    void draw_line();
    void draw_line_move(QPointF pnt,QPointF pnt1);
    void draw_line_state(QPointF pnt,QPointF pnt1);
    int  check_intersection(QPointF pnt,QPointF pnt1);

    void draw_rect();
    void draw_rect_move(QPointF pnt,QPointF pnt1);
    void draw_rect_state(QPointF pnt,QPointF pnt1);

    void draw_round_rect();
    void draw_round_rect_move(QPointF pnt,QPointF pnt1);
    void draw_round_rect_state(QPointF pnt,QPointF pnt1);

    void draw_ellep();
    void draw_ellep_move(QPointF pnt,QPointF pnt1);
    void draw_ellep_state(QPointF pnt,QPointF pnt1);

    void draw_polygon();
    void draw_polygon_move(QPointF pnt,QPointF pnt1);
    void draw_polygon_state(QPointF pnt,QPointF pnt1);

    void draw_arc();
    void draw_arc_move(QPointF pnt,QPointF pnt1);
    void draw_arc_state(QPointF pnt,QPointF pnt1);

    void draw_arrow();
    void draw_arrow_move(QPointF pnt,QPointF pnt1);
    void draw_arrow_state(QPointF pnt,QPointF pnt1);

    void draw_linearrow();
    void draw_linearrow_move(QPointF pnt,QPointF pnt1);
    void draw_linearrow_state(QPointF pnt,QPointF pnt1);

    void draw_triangle();
    void draw_triangle_move(QPointF pnt,QPointF pnt1);
    void draw_triangle_state(QPointF pnt,QPointF pnt1);

    void draw_text();
    void draw_text_move(QPointF pnt,QPointF pnt1);
    void draw_text_state(QPointF pnt,QPointF pnt1);
    bool check_object(QPointF pnt,Draw_Text* text1);

    void select_objects(Scene_Objects objects1);

    void getDist(QPointF &vertex,float &dist);

    template<class T> void setMinMax(T* &object, int objectId,QPointF pnt,QPointF pnt1);

    //Arc class variables
    Draw_Arc *arc,*temp_arc;
    QVector<Draw_Arc*> arcs;

    Draw_Arrow *arrow;
    QVector<Draw_Arrow*> arrows;

    QPointF strt_pnt,strt1_pnt;
    QPointF last_pnt,objectPnt,objectPnt1;

    Draw_Line *line,*polygon_line;
    QVector<Draw_Line*> lines,poly_lines;

    Draw_LineArrow *linearrow;
    QVector<Draw_LineArrow*> linearrows;

    QVector<Draw_Rectangle*> rects;

    //Round Rectangle variables
    Draw_RoundRect *round_rect,*temp_round_rect;
    QVector<Draw_RoundRect*> round_rects;

    Draw_Ellipse *ellep;
    QVector<Draw_Ellipse*> elleps;

    Draw_Polygon *polygon,*temp_polygon;
    QVector<Draw_Polygon*> polygons;
    int poly_indx,next_line_indx,prev_line_indx;

    Draw_Triangle *triangle;
    QVector<Draw_Triangle*> triangles;

    Draw_Text *text;
    QVector<Draw_Text*> texts;

    Scene_Objects *object1,*object2,*object3,*object4,*object5,*object6,*object7,*object8,*object9,*object10;
    QVector<Scene_Objects*> objects,copy_objects,temp_copy_objects,paste_selected_objects;

    QVector<QPointF> pnts;

    QGraphicsLineItem *line_item;

    QPen pen;
    QBrush brush;
    Sketch_Files files;
};

#endif // GRAPH_SCENE_H
