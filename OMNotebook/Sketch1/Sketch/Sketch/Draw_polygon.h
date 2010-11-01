#ifndef DRAW_POLYGON_H
#define DRAW_POLYGON_H

#include "basic.h"


class Draw_polygon
{
  public:
   Draw_polygon();
   ~Draw_polygon();

   //stores the intial or starting point of the polygon
   void polygonSetStrtPnt(QPointF pnt);

   //stores the intial or starting point of the polygon
   void polygonSetEndPnt(QPointF pnt);

   //return number of edges of polygon
   int get_numberof_polypnts();

   //set the draw mode
   void set_draw_mode(bool);

   //get draw mode
   bool get_draw_mode();

   void insert_pnt(QPointF pnt);

   int check_pnt(QPointF pnt);


   void create_bound_edges();

   void print_pnts();

   void translate(QPointF pnt,QPointF pnt1);

   QVector<QPointF> polygon_pnts;
   QVector<QPointF> bounding_edge_pnts;
   QVector<QPointF> bounding_end_pnts;
   QPointF polygon_strt_pnt,polygon_end_pnt;
   int point_on_polygon_edges(QPointF pnt);

 private:
   bool polygon_draw_mode,check_edge;

   //check weather a pnt is on a paticualr edge if so, return the paticualr edge
   int polygonCheckPnts(QPointF pnt,QPointF Strt_pnt,QPointF end_pnt);
   bool check_edges(QPointF pnt,QPointF pnt1,QPointF pnt2);
};


#endif // DRAW_POLYGON_H
