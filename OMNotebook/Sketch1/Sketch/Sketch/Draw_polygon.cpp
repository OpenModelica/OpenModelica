#include "Draw_polygon.h"

Draw_polygon::Draw_polygon()
{
    polygon_pnts.clear();
    bounding_edge_pnts.clear();
    polygon_draw_mode=false;
    check_edge=false;
}

void Draw_polygon::polygonSetStrtPnt(QPointF pnt)
{
       polygon_strt_pnt=pnt;
}

void Draw_polygon::polygonSetEndPnt(QPointF pnt)
{
       polygon_end_pnt=pnt;
}

int Draw_polygon::get_numberof_polypnts()
{
    return polygon_pnts.size()-1;
}

void Draw_polygon::set_draw_mode(bool mode)
{
    polygon_draw_mode=mode;
}

bool Draw_polygon::get_draw_mode()
{
    return polygon_draw_mode;
}




void Draw_polygon::insert_pnt(QPointF pnt)
{
    int count=0;
    QPointF pnt1;
    qDebug()<<"The size of pnts "<<polygon_pnts.size()<<"\n";
    if(polygon_pnts.size()==0)
    {
        polygon_pnts.push_back(pnt);
    }
    for(int i=0;i<this->polygon_pnts.size();i++)
    {
        if(pnt!=polygon_pnts[i]&&(count==polygon_pnts.size()-1))
        {
            polygon_pnts.push_back(pnt);
        }
        count++;
    }

    for(int i=0;i<polygon_pnts.size();i++)
    {
       pnt1.setX(polygon_pnts[i].x()-2.0);
       pnt1.setY(polygon_pnts[i].y()-2.0);
       bounding_end_pnts.push_back(pnt1);
       pnt1.setX(polygon_pnts[i].x()+2.0);
       pnt1.setY(polygon_pnts[i].y()+2.0);
       bounding_end_pnts.push_back(pnt1);
    }

}

void Draw_polygon::create_bound_edges()
{
    QPointF pnt1;
    pnt1.setX(polygon_pnts[0].x()-5.0);
    pnt1.setY(polygon_pnts[0].y()-5.0);
    bounding_edge_pnts.push_back(pnt1);
    pnt1.setX(polygon_pnts[0].x());
    pnt1.setY(polygon_pnts[0].y());
    bounding_edge_pnts.push_back(pnt1);

    /*for(int i=0;i<polygon_pnts.size()-2;i++)
    {
        if((polygon_pnts[i].y()<polygon_pnts[i+1].y())&&(polygon_pnts[i+2].y()<polygon_pnts[i+1].y()))
        {
            pnt1.setX(polygon_pnts[i+1].x());
            pnt1.setY(polygon_pnts[i+1].y());
            bounding_edge_pnts.push_back(pnt1);
            pnt1.setX(polygon_pnts[i+1].x()+5.0);
            pnt1.setY(polygon_pnts[i+1].y()+5.0);
            bounding_edge_pnts.push_back(pnt1);
        }
        else if((polygon_pnts[i].y()>polygon_pnts[i+1].y())&&(polygon_pnts[i+2].y()>polygon_pnts[i+1].y()))
        {
            pnt1.setX(polygon_pnts[i+1].x());
            pnt1.setY(polygon_pnts[i+1].y());
            bounding_edge_pnts.push_back(pnt1);
            pnt1.setX(polygon_pnts[i+1].x()+5.0);
            pnt1.setY(polygon_pnts[i+1].y()+5.0);
            bounding_edge_pnts.push_back(pnt1);
        }
        else
        {
           pnt1.setX(polygon_pnts[i+1].x());
           pnt1.setY(polygon_pnts[i+1].y()-5.0);
           bounding_edge_pnts.push_back(pnt1);
           pnt1.setX(polygon_pnts[i+1].x()+5.0);
           pnt1.setY(polygon_pnts[i+1].y());
           bounding_edge_pnts.push_back(pnt1);
       }

   }

    if((polygon_pnts[0].y()<polygon_pnts[polygon_pnts.size()-1].y())&&(polygon_pnts[polygon_pnts.size()-2].y()<polygon_pnts[polygon_pnts.size()-1].y()))
    {
        pnt1.setX(polygon_pnts[polygon_pnts.size()-1].x());
        pnt1.setY(polygon_pnts[polygon_pnts.size()-1].y());
        bounding_edge_pnts.push_back(pnt1);
        pnt1.setX(polygon_pnts[polygon_pnts.size()-1].x()+5.0);
        pnt1.setY(polygon_pnts[polygon_pnts.size()-1].y()+5.0);
        bounding_edge_pnts.push_back(pnt1);
    }
    else if((polygon_pnts[0].y()>polygon_pnts[polygon_pnts.size()-1].y())&&(polygon_pnts[polygon_pnts.size()-2].y()>polygon_pnts[polygon_pnts.size()-1].y()))
    {
        pnt1.setX(polygon_pnts[polygon_pnts.size()-1].x());
        pnt1.setY(polygon_pnts[polygon_pnts.size()-1].y());
        bounding_edge_pnts.push_back(pnt1);
        pnt1.setX(polygon_pnts[polygon_pnts.size()-1].x()+5.0);
        pnt1.setY(polygon_pnts[polygon_pnts.size()-1].y()+5.0);
        bounding_edge_pnts.push_back(pnt1);
    }

    else
    {
       pnt1.setX(polygon_pnts[polygon_pnts.size()-1].x());
       pnt1.setY(polygon_pnts[polygon_pnts.size()-1].y()-5.0);
       bounding_edge_pnts.push_back(pnt1);
       pnt1.setX(polygon_pnts[polygon_pnts.size()-1].x()+5.0);
       pnt1.setY(polygon_pnts[polygon_pnts.size()-1].y());
       bounding_edge_pnts.push_back(pnt1);
   }

    /*pnt1.setX(polygon_pnts[polygon_pnts.size()-1].x());
    pnt1.setY(polygon_pnts[polygon_pnts.size()-1].y());
    bounding_edge_pnts.push_back(pnt1);
    pnt1.setX(polygon_pnts[polygon_pnts.size()-1].x()+5.0);
    pnt1.setY(polygon_pnts[polygon_pnts.size()-1].y()+5.0);
    bounding_edge_pnts.push_back(pnt1);*/

    for(int i=1;i<polygon_pnts.size()-1;i++)
    {
        if((polygon_pnts[i].x()==polygon_pnts[i+1].x())&&(polygon_pnts[i].y()<polygon_pnts[i+1].y()))
        {
            pnt1.setX(polygon_pnts[i].x());
            pnt1.setY(polygon_pnts[i].y());
            bounding_edge_pnts.push_back(pnt1);
            pnt1.setX(polygon_pnts[i].x()+5.0);
            pnt1.setY(polygon_pnts[i].y()+5.0);
            bounding_edge_pnts.push_back(pnt1);
        }

        if((polygon_pnts[i].x()==polygon_pnts[i+1].x())&&(polygon_pnts[i].y()>polygon_pnts[i+1].y()))
        {
            pnt1.setX(polygon_pnts[i].x());
            pnt1.setY(polygon_pnts[i].y());
            bounding_edge_pnts.push_back(pnt1);
            pnt1.setX(polygon_pnts[i].x()+5.0);
            pnt1.setY(polygon_pnts[i].y()+5.0);
            bounding_edge_pnts.push_back(pnt1);
        }

        if((polygon_pnts[i].x()>polygon_pnts[i+1].x())&&(polygon_pnts[i].y()==polygon_pnts[i+1].y()))
        {
            pnt1.setX(polygon_pnts[i].x());
            pnt1.setY(polygon_pnts[i].y());
            bounding_edge_pnts.push_back(pnt1);
            pnt1.setX(polygon_pnts[i].x()+5.0);
            pnt1.setY(polygon_pnts[i].y()+5.0);
            bounding_edge_pnts.push_back(pnt1);
        }

        if((polygon_pnts[i].x()<polygon_pnts[i+1].x())&&(polygon_pnts[i].y()==polygon_pnts[i+1].y()))
        {
            pnt1.setX(polygon_pnts[i].x()-5.0);
            pnt1.setY(polygon_pnts[i].y());
            bounding_edge_pnts.push_back(pnt1);
            pnt1.setX(polygon_pnts[i].x());
            pnt1.setY(polygon_pnts[i].y()+5.0);
            bounding_edge_pnts.push_back(pnt1);
        }




    }

}

int Draw_polygon::check_pnt(QPointF pnt)
{
    //qDebug()<<"click point "<<pnt<<"\n";
    QPointF strt_pnt,end_pnt;
    for(int i=0;i<bounding_edge_pnts.size();i+=2)
    {
       strt_pnt.setX(bounding_edge_pnts[i].x());
       strt_pnt.setY(bounding_edge_pnts[i].y());
       end_pnt.setX(bounding_edge_pnts[i+1].x());
       end_pnt.setY(bounding_edge_pnts[i+1].y());
       if(polygonCheckPnts(pnt,strt_pnt,end_pnt)==1)
       {
            return i+1;
            break;
       }
    }

    strt_pnt.setX(bounding_edge_pnts[0].x());
    strt_pnt.setY(bounding_edge_pnts[0].y());
    end_pnt.setX(bounding_edge_pnts[bounding_edge_pnts.size()-1].x());
    end_pnt.setY(bounding_edge_pnts[bounding_edge_pnts.size()-1].y());
    if(polygonCheckPnts(pnt,strt_pnt,end_pnt)==1)
    {
         return bounding_edge_pnts.size()-1;

    }
}

int  Draw_polygon::point_on_polygon_edges(QPointF pnt)
{
   QPointF strt_edge,end_edge,check_pnt;
   for(int i=0;i<polygon_pnts.size()-1;i++)
   {
      strt_edge=polygon_pnts[i];
      end_edge=polygon_pnts[i+1];
      check_pnt=pnt;
      if(polygonCheckPnts(check_pnt,strt_edge,end_edge)==1)
      {
         qDebug()<<"Entered checking region\n";
         return polygon_pnts.size();
      }
   }

   strt_edge=polygon_pnts[0];
   end_edge=polygon_pnts[polygon_pnts.size()-1];
   if(polygonCheckPnts(pnt,strt_edge,end_edge)==1)
   {
      qDebug()<<"Entered checking region\n";
      return polygon_pnts.size();
   }

}

void Draw_polygon::print_pnts()
{
    for(int i=0;i<polygon_pnts.size();i++)
    {
        qDebug()<<"polygon points "<<polygon_pnts[i]<<"\n";
    }
}

int Draw_polygon::polygonCheckPnts(QPointF pnt,QPointF Strt_pnt,QPointF end_pnt)
{

     qDebug()<<"pnts "<<Strt_pnt<<"  "<<end_pnt<<" "<<pnt<<"\n";

     float x=(end_pnt.x()-Strt_pnt.x());
     float y=(end_pnt.y()-Strt_pnt.y());
     int dist=sqrt((y*y)+(x*x));
     float px=(end_pnt.x()-pnt.x())/*+(pnt.x()-Strt_pnt.x())*/;
     float py=(end_pnt.y()-pnt.y())/*+(pnt.y()-Strt_pnt.y())*/;
     int dist1=sqrt((py*py)+(px*px));
     int dist2=sqrt(((pnt.x()-Strt_pnt.x())*(pnt.x()-Strt_pnt.x()))+((pnt.y()-Strt_pnt.y())*(pnt.y()-Strt_pnt.y())));

     //qDebug()<<"values "<<sqrt((x*x)+(y*y))<<"\n";
     //qDebug()<<"ponts value "<<sqrt((px*px)+(py*py))+pz<<"\n";

     if(dist==(dist1+dist2))
     {
         return 1;
     }
     /*if((x==px)&&(y==py))
     {
         return 1;
     }*/


}

void Draw_polygon::translate(QPointF pnt, QPointF pnt1)
{

     for(int i=0;i<polygon_pnts.size();i++)
     {
         polygon_pnts[i]-=pnt-pnt1;
     }

     for(int i=0;i<bounding_edge_pnts.size();i++)
     {
         bounding_edge_pnts[i]-=pnt-pnt1;
     }


}


