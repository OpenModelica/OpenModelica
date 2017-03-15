#include "Graph_Scene.h"

Graph_Scene::Graph_Scene(QObject* parent):QGraphicsScene(parent) {
  object1 = new Scene_Objects();
  object2 = new Scene_Objects();
  object3 = new Scene_Objects();
  object4 = new Scene_Objects();
  object5 = new Scene_Objects();
  object6 = new Scene_Objects();
  object7 = new Scene_Objects();
  object8 = new Scene_Objects();
  object9 = new Scene_Objects();
  object10 = new Scene_Objects();

  arcs.clear();
  arrows.clear();
  lines.clear();
  objectToEdit=0;
  linearrows.clear();
  rects.clear();
  round_rects.clear();
  elleps.clear();
  triangles.clear();
  texts.clear();
  polygons.clear();

  objects.clear();
  copy_objects.clear();

  pnts.clear();
  linemode=false;
  mode=false;

  polygon=new Draw_Polygon();
  polygon->set_draw_mode(false);
  line = new Draw_Line();
  line->set_draw_mode(false);
  rect = new Draw_Rectangle();
  rect->setMode(false);
  round_rect = new Draw_RoundRect();
  round_rect->setMode(false);
  ellep = new Draw_Ellipse();
  ellep->setMode(false);
  arc  = new Draw_Arc();
  arc->setMode(false);
  arc->click=-1;
  arrow  = new Draw_Arrow();
  arrow->setMode(false);
  triangle = new Draw_Triangle();
  triangle->setMode(false);
  linearrow = new Draw_LineArrow();
  linearrow->setMode(false);

  pen = QPen();
  brush = QBrush();
  brush.setColor(QColor(255,255,255));

  isMultipleSelected=false;
  isCopySelected=false;
  line_drawn=false;
 }

void Graph_Scene::mousePressEvent(QGraphicsSceneMouseEvent *event) {
    bool k=false;

    if((event->button()==Qt::LeftButton)||(isMultipleSelected)) {
      //Mouse position is stored in strt_pnt and strt1_pnt;
      //qDebug()<<"mouse clicked \n";
      strt_pnt=event->scenePos();
      //Function to select the object to be drawn
      //if(objectToEdit==0 && objectToDraw==0)
      draw_objects();

      switch (objectToDraw) {
        case 1: draw_line(); break;
        case 2: draw_rect(); break;
        case 3: draw_ellep(); break;
        case 4: draw_polygon(); break;
        case 5: draw_round_rect(); break;
        case 6: draw_arc(); break;
        case 7: draw_linearrow(); break;
        case 8: draw_triangle(); break;
        case 9: draw_arrow(); break;
        case 10: draw_text(); break;
        default: break;
      }
    }

    if(event->button()==Qt::RightButton) {
      //Mouse position is stored in strt_pnt and strt1_pnt;
      strt1_pnt=event->scenePos();
      //qDebug()<<"right button pressed "<<strt1_pnt<<"\n";
    }

    QGraphicsScene::mousePressEvent(event);
}

void Graph_Scene::mouseMoveEvent(QGraphicsSceneMouseEvent *event) {
  if(objectToDraw==1 || objectToEdit==1)
    draw_line_move(event->lastScenePos(),event->scenePos());
  if(objectToDraw==2 || objectToEdit==2)
    draw_rect_move(event->lastScenePos(),event->scenePos());
  if(objectToDraw==3 || objectToEdit==3)
    draw_ellep_move(event->lastScenePos(),event->scenePos());
  if(objectToDraw==4 || objectToEdit==4)
    draw_polygon_move(event->lastScenePos(),event->scenePos());
  if(objectToDraw==5 || objectToEdit==5)
    draw_round_rect_move(event->lastScenePos(),event->scenePos());
  if(objectToDraw==6 || objectToEdit==6)
    draw_arc_move(event->lastScenePos(),event->scenePos());
  if(objectToDraw==7 || objectToEdit==7)
    draw_linearrow_move(event->lastScenePos(),event->scenePos());
  if(objectToDraw==8 || objectToEdit==8)
    draw_triangle_move(event->lastScenePos(),event->scenePos());
  if(objectToDraw==9 || objectToEdit==9)
    draw_arrow_move(event->lastScenePos(),event->scenePos());
  if(objectToDraw==10 || objectToEdit==10)
    draw_text_move(event->lastScenePos(),event->scenePos());

  QGraphicsScene::mouseMoveEvent(event);
}

void Graph_Scene::mouseReleaseEvent(QGraphicsSceneMouseEvent *event) {
  if((event->button()==Qt::LeftButton)) {
    if(objectToDraw==1 || objectToEdit==1 ) {
      draw_line_state(event->lastScenePos(),event->scenePos());
    }
    if(objectToDraw==2 || objectToEdit==2) {
      draw_rect_state(event->lastScenePos(),event->scenePos());
    }
     if(objectToDraw==3 || objectToEdit==3) {
      draw_ellep_state(event->lastScenePos(),event->scenePos());
    }
     if(objectToDraw==4 || objectToEdit==4) {
      draw_polygon_state(event->lastScenePos(),event->scenePos());
    }
     if(objectToDraw==5 || objectToEdit==5) {
      draw_round_rect_state(event->lastScenePos(),event->scenePos());
    }
     if(objectToDraw==6 || objectToEdit==6) {
      draw_arc_state(event->lastScenePos(),event->scenePos());
    }
    if(objectToDraw==7 || objectToEdit==7) {
      draw_linearrow_state(event->lastScenePos(),event->scenePos());
    }
     if(objectToDraw==8 || objectToEdit==8) {
      draw_triangle_state(event->lastScenePos(),event->scenePos());
    }
    if(objectToDraw==9 || objectToEdit==9) {
      draw_arrow_state(event->lastScenePos(),event->scenePos());
    }
    if(objectToDraw==10 || objectToEdit==10) {
      draw_text_state(event->lastScenePos(),event->scenePos());
    }
  }

  QGraphicsScene::mouseReleaseEvent(event);
}

void Graph_Scene::mouseDoubleClickEvent(QGraphicsSceneMouseEvent *event) {
  Scene_Objects* object1 = new Scene_Objects();
  if((event->button()==Qt::LeftButton)) {
    Draw_Polygon* poly2 = new Draw_Polygon();
    poly2=polygon; //TODO copy object
    if((objectToDraw==4)&&(poly2->get_draw_mode()==false)) {
      poly2->setStartPoint(last_pnt);
      poly2->setLine(QLineF(last_pnt,poly2->getLine(0)->line().p1()));
      poly2->poly_pnts.push_back(poly2->getLine(0)->line().p1());
      if(!poly2->getLines().isEmpty()) {
        for(int i=0;i<poly2->getLines().size();i++) {
           removeItem(poly2->getLine(i));
        }
      }
      poly2->item = new QGraphicsPathItem(poly2->getPolygon());
      addItem(poly2->item);
      addItem(poly2->Rot_Rect);

      if(!poly2->edge_items.isEmpty()) {
        for(int i=0;i<poly2->edge_items.size();i++) {
          addItem(poly2->edge_items[i]);
        }
      }
      poly2->setPolygonDrawn(true);
      mode=true;
      poly2->lines.clear();
      poly2->isObjectSelected=true;
      for(int i=0;i<polygons.size();i++) {
        polygons[i]->isObjectSelected=false;
      }
      polygons.push_back(poly2);
      QRectF poly_rect=poly2->item->boundingRect();
      object1->ObjectStrtPnt=poly_rect.topLeft();
      object1->ObjectEndPnt=poly_rect.bottomRight();
      object1->pnts=poly2->poly_pnts;
      object1->setObjects(4,polygons.size()-1);
      object1->ObjectIndx=polygons.size()-1;
      objects.push_back(object1);
      objectToDraw=0;
      objectToEdit=4;
    }

    if((objectToDraw==1)&&(line->get_draw_mode()==false)) {
      Draw_Line *line2 = new Draw_Line();
      line2=line; //TODO copy object
      if(!line2->getLines().isEmpty()) {
        for(int i=0;i<line2->getLines().size();i++) {
          removeItem(line2->getLine(i));
        }
      }
      line2->item = new QGraphicsPathItem(line2->getPolyLine());
      addItem(line2->item);
      addItem(line2->Rot_Rect);

      line2->isObjectSelected=true;

      if(!line2->edge_items.isEmpty()) {
        for(int i=0;i<line2->edge_items.size();i++) {
          addItem(line2->edge_items[i]);
        }
      }
      line2->setPolyLineDrawn(true);
      linemode=true;
      line2->lines.clear();

      for(int i=0;i<lines.size();i++) {
        lines[i]->isObjectSelected=false;
      }

      lines.push_back(line2);
      QRectF poly_line=line2->item->boundingRect();
      object1->ObjectStrtPnt=poly_line.topLeft();
      object1->ObjectEndPnt=poly_line.bottomRight();
      object1->pnts=line2->poly_pnts;
      object1->setObjects(1,lines.size()-1);
      object1->ObjectIndx=lines.size()-1;
      objects.push_back(object1);
      objectToDraw=0;
      objectToEdit=1;
    }

    if(objectToDraw==10 && text->getMode()) {
      text->item->setTextInteractionFlags(Qt::TextEditorInteraction);
      objectToDraw=0;
      objectToEdit=10;
      text->isObjectSelected = true;
    } else if (objectToEdit==10 && text->getMode()) {
      text->item->setTextInteractionFlags(Qt::NoTextInteraction);
      objectToDraw=10;
      objectToEdit=0;
      text->isObjectSelected = true;
    }
  }
}

//KeyBoard event
void Graph_Scene::keyPressEvent(QKeyEvent *event) {
  if(event->key()==0x01000007) {
    deleteShapes();
  }
  QGraphicsScene::keyPressEvent(event);
}

void Graph_Scene::keyReleaseEvent(QKeyEvent *event) {
  QGraphicsScene::keyReleaseEvent(event);
}


void Graph_Scene::draw_object(QPointF pnt, QPointF pnt1, Draw_Line *line1,QPen pen) {
  this->addLine(pnt.x(),pnt.y(),pnt1.x(),pnt1.y(),pen);
}

void Graph_Scene::draw_objects() {
  int k=0,position;
  //qDebug()<<"entered the condition "<<objects.size()<<" "<<objects.isEmpty()<<"\n";
  if(!objects.isEmpty()) {
    for(int i=0;i<objects.size();i++) {
      objects[i]->CheckPnt(strt_pnt);
      k=objects[i]->getObject(position);
      if(k==1) {
        object1=objects[i];
        object1->ObjectPos=i;
        object_indx=i;
        objects[i]->ObjectPos=i;
        if(isMultipleSelected) {
          select_objects(*objects[i]);
        }
        break;
      }
      if(k==2) {
        object2=objects[i];
        object2->ObjectPos=i;
        object_indx=i;
        objects[i]->ObjectPos=i;
        if(isMultipleSelected) {
          select_objects(*objects[i]);
        }
        break;
      }
      if(k==3) {
        object3=objects[i];
        object3->ObjectPos=i;
        object_indx=i;
        objects[i]->ObjectPos=i;
        if(isMultipleSelected) {
          select_objects(*objects[i]);
        }
        break;
      }
      if(k==4) {
        object4=objects[i];
        object4->ObjectPos=i;
        object_indx=i;
        objects[i]->ObjectPos=i;
        if(isMultipleSelected) {
          select_objects(*objects[i]);
        }
        break;
      }
      if(k==5) {
        object5=objects[i];
        object5->ObjectPos=i;
        object_indx=i;
        objects[i]->ObjectPos=i;
        if(isMultipleSelected) {
          select_objects(*objects[i]);
        }
        break;
      }
      if(k==6) {
        object6=objects[i];
        object6->ObjectPos=i;
        object_indx=i;
        objects[i]->ObjectPos=i;
        if(isMultipleSelected) {
          select_objects(*objects[i]);
        }
        break;
      }
      if(k==7) {
        object7=objects[i];
        object7->ObjectPos=i;
        object_indx=i;
        objects[i]->ObjectPos=i;
        if(isMultipleSelected) {
          select_objects(*objects[i]);
        }
        break;
      }
      if(k==8) {
        object8=objects[i];
        object8->ObjectPos=i;
        object_indx=i;
        objects[i]->ObjectPos=i;
        if(isMultipleSelected) {
          select_objects(*objects[i]);
        }
        break;
      }
      if(k==9) {
        object9=objects[i];
        object9->ObjectPos=i;
        object_indx=i;
        objects[i]->ObjectPos=i;
        if(isMultipleSelected) {
          select_objects(*objects[i]);
        }
        break;
      }
      if(k==10) {
        object10=objects[i];
        object10->ObjectPos=i;
        object_indx=i;
        objects[i]->ObjectPos=i;
        if(isMultipleSelected) {
          select_objects(*objects[i]);
        }
        break;
      }
    }
  }
  if ((k >= 1) && (k <= 10)) {
    objectToEdit=k;
  }
  if(objectToEdit==1) {
    draw_line();
  }
  if(objectToEdit==2) {
    draw_rect();
  }
  if(objectToEdit==3) {
    draw_ellep();
  }
  if(objectToEdit==4) {
    draw_polygon();
  }
  if(objectToEdit==5) {
    draw_round_rect();
  }
  if(objectToEdit==6) {
    draw_arc();
  }
  if(objectToEdit==7) {
    draw_linearrow();
  }
  if(objectToEdit==8) {
    draw_triangle();
  }
  if(objectToEdit==9) {
    draw_arrow();
  }
  if(objectToEdit==10) {
    draw_text();
  }
}


void Graph_Scene::draw_arc() {
  bool k=false;

  if(arcs.isEmpty() && objectToDraw==6) {
    if(arc && arc->click==0) {
      Draw_Arc *arc2 = new Draw_Arc();
      arc2->setStartPoint(strt_pnt);
      arc2->setEndPoint(strt_pnt);
      arc2->setCurvePoint(strt_pnt);
      arc2->item = new QGraphicsPathItem(arc2->getArc());
      addItem(arc2->item);
      arc=arc2;
    }
    if(arc && arc->click==1) {
      arc->setCurvePoint(strt_pnt);
      arc->item->setPath(arc->getArc());
    }
  }
  if(!isMultipleSelected) {
    hide_object_edges();
  }

  for(int i=0;i<arcs.size();i++) {
    if(arcs[i]->isClickedOnHandleOrShape(strt_pnt)&&(arcs[i]->getMode()==true)) {
      arc=arcs[i];
      indx=i;
      k=true;
      break;
    }
  }

  if(!arcs.isEmpty() && objectToDraw==6) {
    if(!k && arcs[arcs.size()-1]->getMode()==true && arc) {
      if(arc->click==0) {
        Draw_Arc *arc2 = new Draw_Arc();
        arc2->setStartPoint(strt_pnt);
        arc2->setEndPoint(strt_pnt);
        arc2->setCurvePoint(strt_pnt);
        arc2->item = new QGraphicsPathItem(arc2->getArc());
        arc=arc2;
        addItem(arc->item);
       }
     }
    if(arc && arc->click==1) {
      arc->setCurvePoint(strt_pnt);
      arc->item->setPath(arc->getArc());
    }
  }
}

void Graph_Scene::draw_arc_move(QPointF pnt,QPointF pnt1) {
  if((pnt1!=pnt)&&(arc && arc->getMode()==false)) {
    if(arc && arc->click==0) {
      arc->setEndPoint(pnt1);
      arc->item->setPath(arc->getArc());
    }
    if(arc && arc->click==1||arc->click==2) {
      arc->setCurvePoint(pnt1);
      arc->item->setPath(arc->getArc());
      arc->click=2;
    }
  }
  if(arc && arc->getMode()) {
    if(arc->getState()==1) {
      arc->isObjectSelected=true;
      arc->showHandles();
      if(pnt1!=pnt) {
        if(arc->item->rotation()==0) {
          arc->item->setPath(arc->getArc());
          arc->updateEdgeRects();
          arc->setStartPoint(pnt1);
          arc->bounding_strt_pnt=pnt1;
          arc->bounding_end_pnt=arc->getEndPnt();
        }
        if(arc->item->rotation()!=0) {
          pnt1=arc->Strt_Rect->mapFromScene(pnt1);
          arc->setEndPoint(arc->item->boundingRect().bottomRight());
          arc->item->setPath(arc->getArc());
          arc->updateEdgeRects();
          arc->setStartPoint(pnt1);
          arc->bounding_strt_pnt=pnt1;
          arc->bounding_end_pnt=arc->getEndPnt();
        }
        isObjectEdited=true;
      }
    }
    if(arc->getState()==2) {
      arc->isObjectSelected=true;
      arc->showHandles();
      if(pnt1!=pnt) {
        if(arc->item->rotation()==0) {
          arc->item->setPath(arc->getArc());
          arc->updateEdgeRects();
          arc->setEndPoint(pnt1);
          arc->bounding_strt_pnt=arc->getStartPnt();
          arc->bounding_end_pnt=pnt1;
        }
        if(arc->item->rotation()!=0) {
          pnt1=arc->End_Rect->mapFromScene(pnt1);
          arc->setStartPoint(arc->item->boundingRect().bottomLeft());
          arc->item->setPath(arc->getArc());
          arc->updateEdgeRects();
          arc->setEndPoint(pnt1);
          arc->bounding_strt_pnt=pnt1;
          arc->bounding_end_pnt=arc->getEndPnt();
        }
        isObjectEdited=true;
      }
    }
    if(arc->getState()==3) {
      arc->isObjectSelected=true;
      arc->showHandles();
      if(pnt1!=pnt) {
        if(arc->item->rotation()==0) {
          arc->item->setPath(arc->getArc());
          arc->updateEdgeRects();
          arc->setCurvePoint(pnt1);
          arc->bounding_strt_pnt=arc->getStartPnt();
          arc->bounding_end_pnt=pnt1;
        }
        if(arc->item->rotation()!=0) {
          pnt1=arc->Curve_Rect->mapFromScene(pnt1);
          arc->item->setPath(arc->getArc());
          arc->updateEdgeRects();
          arc->setCurvePoint(pnt1);
          arc->bounding_strt_pnt=arc->getStartPnt();
          arc->bounding_end_pnt=pnt1;
        }
        isObjectEdited=true;
      }
    }
    if(arc->getState()==4) {
      arc->Bounding_Rect->show();
      arc->isObjectSelected=true;
      arc->showHandles();
      if(pnt1!=pnt) {
        arc->setTranslate(pnt,pnt1);
      }
      isObjectEdited=true;
    }
    if(arc->getState()==5) {
      arc->isObjectSelected=true;
      arc->Bounding_Rect->show();
      if(pnt1!=pnt) {
        arc->setRotate(pnt,pnt1);
      }
      isObjectEdited=true;
    }
  }
}

void Graph_Scene::draw_arc_state(QPointF pnt,QPointF pnt1) {
  Scene_Objects *object = new Scene_Objects();
  Draw_Arc *arc2 = new Draw_Arc();
  arc2=arc;
  if(arc && (arc->getMode()==false)&& objectToDraw==6) {
    if(arc2->click==0) {
      arc2->setEndPoint(pnt1);
      arc2->item->setPath(arc2->getArc());
      arc2->click+=1;
    }
    if(arc2->click==2) {
      arc2->setMode(true);
      arc2->click=0;
      removeItem(arc2->item);
      arc2->item = new QGraphicsPathItem(arc2->getArc());
      addItem(arc2->item);
      arc2->setEdgeRects();
      addItem(arc2->Strt_Rect);
      addItem(arc2->End_Rect);
      addItem(arc2->Curve_Rect);
      addItem(arc2->Bounding_Rect);
      addItem(arc2->Rot_Rect);
      arc2->Bounding_Rect->hide();
      arc2->isObjectSelected=true;
      for(int i=0;i<arcs.size();i++)
        arcs[i]->isObjectSelected=false;
      arcs.push_back(arc2);
      object->setObjectPos(arc2->item->boundingRect().topLeft(),arc2->item->boundingRect().bottomRight());
      object->setBoundPos(arc2->item->boundingRect().topLeft(),arc2->item->boundingRect().bottomRight());
      object->pnts.push_back(QPointF(arc2->getCurvePnt()));
      object->setObjects(6,arcs.size()-1);
      object->ObjectIndx=arcs.size()-1;
      objects.push_back(object);
      objectToDraw=0;
      objectToEdit=6;
    }
  }
  if(arc && arc->getMode()==true) {
    if(arc->getState()==1) {
      object6->setObjectPos(arc->item->boundingRect().topLeft(),arc->item->boundingRect().bottomRight());
      object6->setBoundPos(arc->item->boundingRect().topLeft(),arc->item->boundingRect().bottomRight());
      object6->pnts.empty();
      object6->pnts.push_back(QPointF(arc->getCurvePnt()));
      arc->setState(0);
      objectToEdit=6;
    }
    if(arc->getState()==2) {
      object6->setObjectPos(arc->item->boundingRect().topLeft(),arc->item->boundingRect().bottomRight());
      object6->setBoundPos(arc->item->boundingRect().topLeft(),arc->item->boundingRect().bottomRight());
      object6->pnts.empty();
      object6->pnts.push_back(QPointF(arc->getCurvePnt()));
      arc->setState(0);
      objectToEdit=6;
    }
    if(arc->getState()==3) {
      object6->setObjectPos(arc->item->boundingRect().topLeft(),arc->item->boundingRect().bottomRight());
      object6->setBoundPos(arc->item->boundingRect().topLeft(),arc->item->boundingRect().bottomRight());
      object6->pnts.empty();
      object6->pnts.push_back(QPointF(arc->getCurvePnt()));
      arc->setState(0);
      objectToEdit=6;
    }
    if(arc->getState()==4) {
      object6->setObjectPos(arc->item->boundingRect().topLeft(),arc->item->boundingRect().bottomRight());
      object6->setBoundPos(arc->item->boundingRect().topLeft(),arc->item->boundingRect().bottomRight());
      object6->pnts.empty();
      object6->pnts.push_back(QPointF(arc->getCurvePnt()));
      arc->setState(0);
      arc->Bounding_Rect->hide();
      objectToEdit=6;
    }
    if(arc->getState()==5) {
      object6->setObjectPos(arc->item->boundingRect().topLeft(),arc->item->boundingRect().bottomRight());
      object6->setBoundPos(arc->item->boundingRect().topLeft(),arc->item->boundingRect().bottomRight());
      object6->pnts.empty();
      object6->pnts.push_back(QPointF(arc->getCurvePnt()));
      arc->setState(0);
      arc->Bounding_Rect->hide();
      objectToEdit=6;
    }
  }
}

void Graph_Scene::draw_arrow() {
  bool k=false;
  if(arrows.isEmpty() && objectToDraw==9) {
    Draw_Arrow *arrow2 = new Draw_Arrow();
    arrow2->setStartPoint(strt_pnt);
    arrow2->item = new QGraphicsPathItem(arrow2->getArrow());
    addItem(arrow2->item);
    arrow=arrow2;
  }
  if(!isMultipleSelected) {
    hide_object_edges();
  }

  for(int i=0;i<arrows.size();i++) {
    if((arrows[i]->isClickedOnHandleOrShape(strt_pnt))&&(arrows[i]->getMode()==true)) {
      arrow=arrows[i];
      indx=i;
      k=true;
      break;
    }
  }

  if(!arrows.isEmpty() && objectToDraw==9) {
    if(arrow && !k && arrows[arrows.size()-1]->getMode()==true) {
      Draw_Arrow *arrow2 = new Draw_Arrow();
      arrow2->setStartPoint(strt_pnt);
      arrow2->item = new QGraphicsPathItem(arrow2->getArrow());
      //addItem(arrow2->item);
      arrow=arrow2;
    }
  }
}

void Graph_Scene::draw_arrow_move(QPointF pnt,QPointF pnt1) {
  if(arrow && arrow->getMode()) {
    //qDebug()<<"State of arrow "<<arrow->getState()<<"\n";
    if(arrow->getState()==1) {
      arrow->isObjectSelected=true;
      arrow->showHandles();
      //qDebug()<<"State of arrow "<<arrow->getState()<<" "<<arrow->handle_index<<"\n";
      if(pnt1!=pnt) {
        if(arrow->handle_index==0) {
          pnt1=arrow->handles[0]->mapFromScene(pnt1);
          arrow->setTranslate(pnt-arrow->item->pos(),pnt1-arrow->item->pos());
          arrow->item->setPath(arrow->getArrow());
          arrow->updateEdgeRects();
          arrow->setStartPoint(QPointF(pnt1.x(),pnt1.y()-25));
          arrow->bounding_strt_pnt=pnt1;
          arrow->bounding_end_pnt=arrow->getEndPnt();
        }
        if(arrow->handle_index==7) {
          pnt1=arrow->handles[7]->mapFromScene(pnt1);
          arrow->setTranslate(pnt-arrow->item->pos(),pnt1-arrow->item->pos());
          //qDebug()<<"entered condition1 "<<arrow->handle_index<<"\n";
          arrow->item->setPath(arrow->getArrow());
          arrow->updateEdgeRects();
          arrow->setStartPoint(QPointF(pnt1.x(),pnt1.y()-25));
          arrow->bounding_strt_pnt=pnt1;
          arrow->bounding_end_pnt=arrow->getEndPnt();
        }
        if(arrow->handle_index==3) {
          pnt1=arrow->handles[3]->mapFromScene(pnt1);
          arrow->setTranslate(pnt-arrow->item->pos(),pnt1-arrow->item->pos());
          arrow->item->setPath(arrow->getArrow());
          arrow->updateEdgeRects();
          arrow->bounding_strt_pnt=pnt1;
          arrow->bounding_end_pnt=arrow->getEndPnt();
        }
        isObjectEdited=true;
      }
    }
    if(arrow->getState()==2) {
      arrow->isObjectSelected=true;
      arrow->showHandles();
      if(pnt1!=pnt) {
        if(arrow->item->rotation()==0) {
          arrow->setTranslate(pnt,pnt1);
          arrow->item->setPath(arrow->getArrow());
          arrow->updateEdgeRects();
          arrow->Strt_Rect->setPos(arrow->Strt_Rect->pos()+(pnt-pnt1));
          arrow->End_Rect->setPos(arrow->End_Rect->pos()-(pnt-pnt1));
          arrow->setEndPoint(pnt1-arrow->item->pos());
          arrow->bounding_strt_pnt=arrow->getStartPnt();
          arrow->bounding_end_pnt=pnt1;
        }
        if(arrow->item->rotation()!=0) {
          arrow->setTranslate(pnt,pnt1);
          pnt1=arrow->End_Rect->mapFromScene(pnt1);
          arrow->item->setPath(arrow->getArrow());
          arrow->updateEdgeRects();
          arrow->setEndPoint(pnt1);
          arrow->bounding_strt_pnt=pnt1;
          arrow->bounding_end_pnt=arrow->getEndPnt();
        }
        isObjectEdited=true;
      }
    }
    if(arrow->getState()==3) {
      arrow->isObjectSelected=true;
      arrow->showHandles();
      arrow->Bounding_Rect->show();
      if(pnt1!=pnt) {
        arrow->setTranslate(pnt,pnt1);
      }
      isObjectEdited=true;
    }
    if(arrow->getState()==4) {
      arrow->isObjectSelected=true;
      arrow->showHandles();
      arrow->Bounding_Rect->show();
      if(pnt1!=pnt) {
        arrow->setRotate(pnt,pnt1);
      }
      isObjectEdited=true;
    }
  }
}

void Graph_Scene::draw_arrow_state(QPointF pnt,QPointF pnt1)
{
    Scene_Objects *object = new Scene_Objects();
  Draw_Arrow *arrow2 = new Draw_Arrow();
  arrow2=arrow;
    if(arrow && (arrow->getMode()==false) && objectToDraw==9)
    {
       removeItem(arrow2->item);
       arrow2->setMode(true);
     arrow2->item = new QGraphicsPathItem(arrow2->getArrow());
     addItem(arrow2->item);
       arrow2->setEdgeRects();
       addItem(arrow2->Bounding_Rect);
       addItem(arrow2->Rot_Rect);
     for(int i=0;i<arrow2->handles.size();i++)
       addItem(arrow2->handles[i]);

       arrow2->Bounding_Rect->hide();
     arrow2->isObjectSelected=true;
     for(int i=0;i<arrows.size();i++)
       arrows[i]->isObjectSelected=false;
       arrows.push_back(arrow2);
       object->setObjectPos(arrow2->getStartPnt(),arrow2->getEndPnt());
       object->setBoundPos(arrow2->item->boundingRect().topLeft(),arrow2->item->boundingRect().bottomRight());
       object->setObjects(9,arrows.size()-1);
       object->ObjectIndx=arrows.size()-1;
       objects.push_back(object);
     objectToDraw=0;
     objectToEdit=9;

     qDebug()<<"arrow count "<<arrows.size()<<"\n";
    }

    if(arrow && arrow->getMode()==true)
    {
        if(arrow->getState()==1)
        {
           for(int i=0;i<pnts.size();i++)
              qDebug()<<"arrow pnts in graph scene "<<arrow->arrow_pnts[i]<<"\n";

           object9->setObjectPos(arrow->getStartPnt(),arrow->getEndPnt());
       //object9->setObjectPos(arrow->Bounding_Rect->sceneBoundingRect().topLeft(),arrow->Bounding_Rect->sceneBoundingRect().bottomRight());
           object9->setBoundPos(arrow->item->boundingRect().topLeft(),arrow->item->boundingRect().bottomRight());
           //object9->pnts.push_back(QPointF(arrow->getArrowPnt()));
           arrow->setState(0);
       objectToEdit=9;

        }

        if(arrow->getState()==2)
        {

      for(int i=0;i<pnts.size();i++)
              qDebug()<<"arrow pnts in graph scene "<<arrow->arrow_pnts[i]<<"\n";

            object9->setObjectPos(arrow->getStartPnt(),arrow->getEndPnt());
      //object9->setObjectPos(arrow->Bounding_Rect->sceneBoundingRect().topLeft(),arrow->Bounding_Rect->sceneBoundingRect().bottomRight());
            object9->setBoundPos(arrow->item->boundingRect().topLeft(),arrow->item->boundingRect().bottomRight());
            //object9->pnts.push_back(QPointF(arrow->getArrowPnt()));
            arrow->setState(0);
      objectToEdit=9;
        }

        if(arrow->getState()==3)
        {
      for(int i=0;i<arrow->arrow_pnts.size();i++)
      {
         QPointF pnt(arrow->arrow_pnts[i].x()+arrow->item->pos().x(),arrow->arrow_pnts[i].y()+arrow->item->pos().y());
         arrow->arrow_pnts[i]=pnt;
      }
      arrow->item->setPath(arrow->getArrow());
      arrow->item->setPos(0,0);
      qDebug()<<"arrow pnts in translate"<<arrow->arrow_pnts[0]<<"  "<<arrow->item->sceneBoundingRect().topLeft()<<" "<<arrow->item->pos()<<"\n";
      //arrow->updateArrowPoints(arrow->item->sceneBoundingRect().topLeft());
      object9->setObjectPos(QPointF(arrow->Bounding_Rect->sceneBoundingRect().topLeft().x(),arrow->Bounding_Rect->sceneBoundingRect().topLeft().y()-25),arrow->Bounding_Rect->sceneBoundingRect().bottomRight());
      //object9->setObjectPos(arrow->getStartPnt(),arrow->getEndPnt());
      /*QPointF pnt(arrow->item->sceneBoundingRect().topLeft().x(),arrow->item->sceneBoundingRect().topLeft().y()-25);
      QPointF pnt1(arrow->item->sceneBoundingRect().bottomRight().x(),arrow->item->sceneBoundingRect().bottomRight().y()-25);
      object9->setObjectPos(pnt,pnt1);*/
            object9->setBoundPos(arrow->item->boundingRect().topLeft(),arrow->item->boundingRect().bottomRight());
            arrow->setState(0);
            arrow->Bounding_Rect->hide();
      objectToEdit=9;
        }

        if(arrow->getState()==4)
        {
            arrow->setState(0);
            arrow->Bounding_Rect->hide();
      objectToEdit=9;
        }


     }
}

void Graph_Scene::draw_line()
{
    bool k=false;

    if(lines.isEmpty() && objectToDraw==1)
    {
       line->poly_pnts.push_back(strt_pnt);

       if(line && line->getLines().isEmpty())
       {
          line->setStartPoint(strt_pnt);
       }
       else
       {
          QPointF point;
          point=line->getLine(line->getLines().size()-1)->line().p2();
          line->setStartPoint(point);
       }
       addItem(line->getLine());

       if(linemode)
       {
           strt_pnt=strt1_pnt;
           linemode=false;
       }
    }

    if(!isMultipleSelected)
        hide_object_edges();


    for(int i=0;i<lines.size();i++)
    {
       //qDebug()<<"polygon region "<<polygons[i]->item->boundingRect().topLeft()<<" "<< polygons[i]->item->boundingRect().bottomRight()<<"\n";
       if(lines[i]->isClickedOnHandleOrShape(strt_pnt))
       {
        line=lines[i];
            indx=i;
      polyline_indx=lines[i]->getHandelIndex();
            k=true;
            break;
       }
    }



    if(lines.size()>=1 && (!k) && objectToDraw==1)
    {
    qDebug()<<"lines size "<<lines.size()<<"\n";

        if(line && line->getLines().isEmpty()&&(lines[lines.size()-1]->getPolyLineDrawn()))
        {
            Draw_Line* line2 = new Draw_Line();

      qDebug()<<"strt pnt before "<<strt_pnt<<"\n";

            line2->setPolyLineDrawn(false);
            line=line2;
            line->poly_pnts.push_back(strt_pnt);
            line->setStartPoint(strt_pnt);

      qDebug()<<"strt pnt after "<<strt_pnt<<"\n";
        }
        else
        {
           QPointF point;
           line->poly_pnts.push_back(strt_pnt);
           point=line->getLine(line->getLines().size()-1)->line().p2();
           line->setStartPoint(point);
        }
        addItem(line->getLine());

        if(linemode)
        {
            //strt_pnt=strt1_pnt;
            linemode=false;
        }
    }

}



void Graph_Scene::draw_line_move(QPointF pnt,QPointF pnt1)
{

    if(lines.isEmpty()&&(!line->getPolyLineDrawn()))
     {
         QLineF newLine(line->getLine()->line().p1(),pnt1);
         line->setLine(newLine);
     }

     //for(int i=1;i<polygons.size();i++)
     {
        if(lines.size()>=1&&(lines[lines.size()-1]->getPolyLineDrawn()))
        {
            QLineF newLine(line->getLine()->line().p1(),pnt1);
            line->setLine(newLine);
        }
     }

     if((!lines.isEmpty()) && line && (line->getPolyLineDrawn()))
     {

         /*if(polyline_indx<line->poly_pnts.size())
         {
       line->showHandles();
         }*/
          if(line->getState()==1)
          {
             line->isObjectSelected=true;
       line->showHandles();
             if(pnt1!=pnt)
             {
                 if(polyline_indx<line->poly_pnts.size())
                 {
                    if(line->item->rotation()==0)
                    {
                       line->item->setPath(line->getPolyLine(polyline_indx,pnt,pnt1));

                       QPointF pnt2,pnt3;
                       pnt2=pnt1;
                       pnt3=pnt1;
                       pnt2-=QPointF(5.0,5.0);
                       pnt3+=QPointF(5.0,5.0);
                       QRectF newRect(pnt2,pnt3);
                       line->edge_items[polyline_indx]->setRect(newRect);
             qDebug()<<"entered line when clicked on edge rect \n";
                    }

                    if(line->item->rotation()!=0)
                    {

                        pnt=line->item->mapFromScene(pnt);
                        pnt1=line->item->mapFromScene(pnt1);
                        line->item->setPath(line->getPolyLine(polyline_indx,pnt,pnt1));

                        QPointF pnt2,pnt3;
                        pnt2=pnt1;
                        pnt3=pnt1;
                        pnt2-=QPointF(5.0,5.0);
                        pnt3+=QPointF(5.0,5.0);
                        QRectF newRect(pnt2,pnt3);
                        line->edge_items[polyline_indx]->setRect(newRect);
                    }

                    object1->setObjectPos(line->item->boundingRect().topLeft(),line->item->boundingRect().bottomRight());
                    object1->setBoundPos(line->item->boundingRect().topLeft(),line->item->boundingRect().bottomRight());
                    object1->pnts=line->poly_pnts;
          isObjectEdited=true;
                  }
                }
           }

         if(line && line->getState()==2)
         {
       line->isObjectSelected=true;
       line->showHandles();
             /*if(polygon->item->isSelected())
             {
                for(int i=0;i<polygon->edge_items.size();i++)
                {
                    if(!polygon->edge_items[i]->isVisible())
                    {
                        polygon->edge_items[i]->show();
                    }
                }
             }*/
             line->setTranslate(pnt,pnt1);
             //polygon->item->setPath(polygon->getPolygon());
             object1->setObjectPos(line->item->boundingRect().topLeft(),line->item->boundingRect().bottomRight());
             object1->setBoundPos(line->item->boundingRect().topLeft(),line->item->boundingRect().bottomRight());
             object1->pnts=line->poly_pnts;
       isObjectEdited=true;
         }

         if(line && line->getState()==3)
         {
       line->isObjectSelected=true;
       line->showHandles();
             line->setRotate(pnt,pnt1);

            //polygon->item->setPath(polygon->getPolygon());
            //object4->setObjectPos(polygon->item->boundingRect().topLeft(),polygon->item->boundingRect().bottomRight());
            //object4->setBoundPos(polygon->item->boundingRect().topLeft(),polygon->item->boundingRect().bottomRight());
            //object4->pnts=polygon->poly_pnts;
      isObjectEdited=true;
         }
     }
 }

void Graph_Scene::draw_line_state(QPointF pnt, QPointF pnt1)
{
    if(line && (lines.isEmpty())&&!line->getPolyLineDrawn() && objectToDraw==1)
    {
        line->setEndPoint(pnt1);
    }

    if(line && (lines.size()>=1)&&!line->getPolyLineDrawn() && objectToDraw==1)
    {
        line->setEndPoint(pnt1);
        line->setPolyLineDrawn(false);
    }

    if(line && line->getPolyLineDrawn())
    {
        if(line->getState()==1)
        {
            object1->setObjectPos(line->item->boundingRect().topLeft(),line->item->boundingRect().bottomRight());
            object1->setBoundPos(line->item->boundingRect().topLeft(),line->item->boundingRect().bottomRight());
            object1->pnts=line->poly_pnts;
            line->setState(0);
      objectToEdit=1;
        }

        if(line->getState()==2)
        {
            object1->setObjectPos(line->item->boundingRect().topLeft(),line->item->boundingRect().bottomRight());
            object1->setBoundPos(line->item->boundingRect().topLeft(),line->item->boundingRect().bottomRight());
            object1->pnts=line->poly_pnts;
            line->setState(0);
      objectToEdit=1;
        }

    if(line->getState()==3)
    {
      line->setState(0);
      objectToEdit=1;
    }

    }
}
void Graph_Scene::draw_linearrow()
{
    bool k=false;

    if(linearrows.size()==0  && objectToDraw==7)
    {
        Draw_LineArrow* linearrow2 = new Draw_LineArrow();
        linearrow2->setStartPoint(strt_pnt);
        linearrow=linearrow2;
        linearrows.push_back(linearrow2);
        linearrow->angle=0.0;
        linearrow->item=new QGraphicsPathItem(linearrow->getLineArrow(strt_pnt));
        addItem(linearrow->item);

    }

    if(!isMultipleSelected)
        hide_object_edges();

    for(int i=0;i<linearrows.size();i++)
    {
        if((linearrows[i]->isClickedOnHandleOrShape(strt_pnt))&&(linearrows[i]->getMode()==true))
        {
             linearrow=linearrows[i];
             indx=i;
             k=true;
             break;
        }
    }
    if(k!=true)
    {
    if(linearrow && linearrows[linearrows.size()-1]->getMode()==true  && objectToDraw==7)
      {
        Draw_LineArrow* linearrow2 = new Draw_LineArrow();
        linearrow2->setStartPoint(strt_pnt);
    for(int i=0;i<linearrows.size();i++)
      linearrows[i]->isObjectSelected=false;
        linearrows.push_back(linearrow2);
        linearrow=linearrow2;
        linearrow->item=new QGraphicsPathItem(linearrow->getLineArrow(strt_pnt));
        addItem(linearrow->item);
      }
    }
}


void Graph_Scene::draw_linearrow_move(QPointF pnt,QPointF pnt1)
{

    for(int i=0;i<linearrows.size();i++)
    {
        if((pnt1!=pnt)&&(linearrows[i]->getMode()==false))
        {
            linearrow->item->setPath(linearrow->getLineArrow(pnt1));
        }
     }

     if(linearrow && linearrow->getMode())
     {
     if(linearrow->getState()==1)
         {
       linearrow->isObjectSelected=true;
       linearrow->showHandles();
           if(pnt1!=pnt)
           {

              if(linearrow->item->rotation()==0)
              {
                 linearrow->setStartPoint(pnt1);
                 linearrow->setTranslate(pnt,pnt1);
                 linearrow->item->setPath(linearrow->getLineArrow(linearrow->getEndPnt()));
                 linearrow->updateEdgeRects();
                 linearrow->bounding_strt_pnt=pnt1;
                 linearrow->bounding_end_pnt=linearrow->getEndPnt();
              }

              if(linearrow->item->rotation()!=0)
              {
                 pnt=linearrow->Strt_Rect->mapFromScene(pnt);
                 pnt1=linearrow->Strt_Rect->mapFromScene(pnt1);
                 linearrow->setStartPoint(pnt1);
                 linearrow->setTranslate(pnt,pnt1);
                 linearrow->item->setPath(linearrow->getLineArrow(linearrow->getEndPnt()));
                 linearrow->updateEdgeRects();
                 linearrow->bounding_strt_pnt=pnt1;
                 linearrow->bounding_end_pnt=linearrow->getEndPnt();
              }
        isObjectEdited=true;
           }
          }

          if(linearrow->getState()==2)
          {

      linearrow->isObjectSelected=true;
        linearrow->showHandles();

            if(pnt1!=pnt)
            {
              if(linearrow->item->rotation()==0)
              {
                 QPointF pnt2=pnt1;
                 linearrow->setTranslate(pnt,pnt1);
                 linearrow->item->setPath(linearrow->getLineArrow(pnt2));
                 //linearrow->updateEdgeRects();
                 //linearrow->setEndPoint(pnt1);
                 linearrow->bounding_strt_pnt=linearrow->getStartPnt();
                 linearrow->bounding_end_pnt=pnt1;
              }

              if(linearrow->item->rotation()!=0)
              {
                 QPointF pnt2=pnt1;
                 pnt=linearrow->End_Rect->mapFromScene(pnt);
         pnt1=linearrow->End_Rect->mapFromScene(pnt1);
                 linearrow->setTranslate(pnt,pnt1);
         linearrow->item->setPath(linearrow->getLineArrow(linearrow->getStartPnt()));
                 linearrow->updateEdgeRects();
                 //linearrow->setEndPoint(pnt1);
                 linearrow->bounding_strt_pnt=linearrow->getStartPnt();
                 linearrow->bounding_end_pnt=pnt1;
              }
        isObjectEdited=true;
            }
          }

          if(linearrow->getState()==3)
          {
        linearrow->isObjectSelected=true;
          linearrow->showHandles();

               if(pnt1!=pnt)
               {
                 linearrow->setTranslate(pnt,pnt1);

               }
         isObjectEdited=true;
          }

          if(linearrow->getState()==4)
          {
        linearrow->isObjectSelected=true;
          linearrow->showHandles();

               if(pnt1!=pnt)
               {
                 linearrow->setRotate(pnt,pnt1);
               }
         isObjectEdited=true;
          }

     }
 }

void Graph_Scene::draw_linearrow_state(QPointF pnt, QPointF pnt1)
{

    Scene_Objects* object = new Scene_Objects();

    if(linearrow && linearrow->getMode()==false && objectToDraw==7)
    {

        Draw_LineArrow *linearrow2 = new Draw_LineArrow();
        linearrow2=linearrow;

        removeItem(linearrow2->item);
        removeItem(linearrow->item);
        last_pnt=pnt1;


        //qDebug()<<"line strt point "<<linearrow2->getStartPnt()<<"\n";
        linearrow2->bounding_strt_pnt = linearrow2->getStartPnt();
        linearrow2->bounding_end_pnt = linearrow2->getEndPnt();
        //qDebug()<<"return items coords "<<linearrow2->getLineArrow(linearrow2->getStartPnt()).boundingRect().bottomRight()<<"\n";
        linearrow2->item = new QGraphicsPathItem(linearrow2->getLineArrow(linearrow2->getStartPnt()));
        addItem(linearrow2->item);
        linearrow2->setEdgeRects();
        //qDebug()<<"line arrow item "<<linearrow2->item->boundingRect().topLeft()<<"  "<<linearrow2->item->boundingRect().bottomRight()<<"\n";

        addItem(linearrow2->Strt_Rect);
        addItem(linearrow2->End_Rect);
        addItem(linearrow2->Rot_Rect);

        linearrow->setMode(true);

        linearrow2->setMode(true);
        linearrow2->isObjectSelected=true;

        //qDebug()<<"line length "<<linearrow2->arrow_pnts[0]<<" "<<linearrow2->arrow_pnts[1]<<" "<<linearrow2->arrow_pnts[3]<<"\n";

        qDebug()<<"line ptns "<<linearrow2->getMinPoint()<<"  "<<linearrow2->getMaxPoint()<<"\n";

        linearrows[linearrows.size()-1] = linearrow2;
        object->setObjectPos(linearrow2->getMinPoint(),linearrow2->getMaxPoint());
        object->pnts=linearrow->arrow_pnts;
        object->setObjects(7,linearrows.size()-1);
        object->ObjectIndx=linearrows.size()-1;
        object->pen=pen;
        objects.push_back(object);
        objectToDraw=0;
        objectToEdit=7;
    }

    if(linearrow && linearrow->getMode()==true)
    {

        if(linearrow->getState()==1)
        {
           object7->setObjectPos(linearrow->item->boundingRect().topLeft(),linearrow->item->boundingRect().bottomRight());
           object7->pnts=linearrow->arrow_pnts;
           linearrow->setState(0);
           objectToEdit=7;
        }

        if(linearrow->getState()==2)
        {
            object7->setObjectPos(linearrow->item->boundingRect().topLeft(),linearrow->item->boundingRect().bottomRight());
            linearrow->setState(0);
      objectToEdit=7;
        }

        if(linearrow->getState()==3)
        {
            object7->setObjectPos(linearrow->item->boundingRect().topLeft(),linearrow->item->boundingRect().bottomRight());
            linearrow->setState(0);
      objectToEdit=7;
        }

        if(linearrow->getState()==4)
        {
            /*QRectF rect1(line->getStartPnt().x()-5.0,line->getStartPnt().y()-2.5,5.0,5.0);
            line->Strt_Rect->setRect(rect1);
            line->Strt_Rect->show();
            //Ending edge of line
            QRectF rect2(line->getEndPnt().x(),line->getEndPnt().y()-2.5,5.0,5.0);
            line->End_Rect->setRect(rect2);
            line->End_Rect->show();
            //Middle of the line
            QRectF rect3((line->getStartPnt().x()+line->getEndPnt().x())/2,line->getStartPnt().y()-10,5.0,5.0);
            line->Rot_Rect->setRect(rect3);
            object1->setObjectPos(line->getStartPnt(),line->getEndPnt());
            line->setState(0);*/
      linearrow->setState(0);
      objectToEdit=7;

        }

     }
}


void Graph_Scene::draw_rect() {
  bool k=false;
  if(rects.isEmpty() && objectToDraw==2) {
    rect->setStartPoint(strt_pnt);
    rects.push_back(rect);
    rect->item= new QGraphicsPathItem(rect->getRect(strt_pnt,strt_pnt));
    addItem(rect->item);
  }
  if(!isMultipleSelected)
    hide_object_edges();
  for(int i=0;i<rects.size();i++) {
    if((rects[i]->isClickedOnHandleOrShape(strt_pnt))&&(rects[i]->getMode()==true)) {
      rect=rects[i];
      indx=i;
      k=true;
      break;
    }
  }
  if(!k && rect  && rects[rects.size()-1]->getMode() &&  objectToDraw==2) {
    Draw_Rectangle* rect2 = new Draw_Rectangle();
    rect2->setStartPoint(strt_pnt);
    rect=rect2;
    for(int i=0;i<rects.size();i++)
      rects[i]->isObjectSelected=false;
    rects.push_back(rect);
    rect->item= new QGraphicsPathItem(rect->getRect(strt_pnt,strt_pnt));
    addItem(rect->item);
  }
}

void Graph_Scene::draw_rect_move(QPointF pnt,QPointF pnt1)
{

    for(int i=0;i<rects.size();i++)
    {
        if((pnt1!=pnt)&&(rects[i]->getMode()==false))
        {
      rect->item->setPath(rect->getRect(rect->getStartPnt(),pnt1));
        }
    }

     if(rect && rect->getMode())
     {
     if(rect->getState()==1)
         {
      rect->isObjectSelected=true;
      rect->showHandles();

            if(pnt1!=pnt)
            {
                if(rect->item->rotation()==0)
                {
           rect->item->setPath(rect->getRect(pnt1-rect->item->pos(),rect->getEndPnt()));
                   rect->setStartPoint(pnt1-rect->item->pos());
                   rect->updateEdgeRects();
                }

                if(rect->item->rotation()!=0)
                {
          pnt1=rect->Strt_Rect->mapFromScene(pnt1);
                    QPointF boundPnt,boundPnt1;
          //boundPnt=rect->Strt_Rect->sceneBoundingRect().bottomRight()+(pnt1-rect->Strt_Rect->sceneBoundingRect().bottomRight());
          //boundPnt1=rect->getEndPnt();
          //qDebug()<<"rectangle "<<pnt.x()<<" "<<rect->item->sceneBoundingRect().right()<<" "<<rect->item->sceneBoundingRect().bottomLeft()<<" "<<rect->item->sceneBoundingRect().bottomRight()<<"\n";
          //rect->setEndPoint(rect->item->sceneBoundingRect().bottomRight());
          rect->item->setPath(rect->getRotRect(pnt1,rect->item->boundingRect().bottomRight()));

                    //rect->setStartPoint(rect->Strt_Rect->sceneBoundingRect().bottomRight()+(pnt1-rect->Strt_Rect->sceneBoundingRect().bottomRight()));
          rect->setStartPoint(pnt1);
                    rect->updateEdgeRects();
                }
        isObjectEdited=true;
             }
          }

          if(rect->getState()==2)
          {
       rect->isObjectSelected=true;
       rect->showHandles();

             if(pnt1!=pnt)
             {
                 if(rect->item->rotation()==0)
                 {
                    rect->item->setPath(rect->getRect(rect->getStartPnt(),pnt1-rect->item->pos()));
                    rect->setEndPoint(pnt1-rect->item->pos());
                    rect->updateEdgeRects();
                 }

                 if(rect->item->rotation()!=0)
                 {
                     pnt1=rect->End_Rect->mapFromScene(pnt1);
                     qDebug()<<"mouse press point1 "<<pnt1<<"\n";
           rect->item->setPath(rect->getRect(rect->item->boundingRect().topLeft(),pnt1));
                     rect->setEndPoint(pnt1);
                     rect->updateEdgeRects();
                 }

         isObjectEdited=true;
               }
           }

           if(rect->getState()==3)
           {
         rect->isObjectSelected=true;
         rect->showHandles();
               if(pnt1!=pnt)
               {
           rect->setTranslate(pnt,pnt1);

               }

         isObjectEdited=true;
            }

            if(rect->getState()==4)
            {
         rect->isObjectSelected=true;
         rect->showHandles();
         if(pnt1!=pnt)
                 {
                   rect->setRotate(pnt,pnt1);

                 }
         isObjectEdited=true;
            }
        }
}

void Graph_Scene::draw_rect_state(QPointF pnt,QPointF pnt1)
{
    Scene_Objects* object = new Scene_Objects();

    if(rect && rect->getMode()==false && objectToDraw==2)
    {
    Draw_Rectangle *rect2 = new Draw_Rectangle();
      rect2=rect;
    removeItem(rect2->item);
        last_pnt=pnt1;
    rect->setMode(true);
        rect2->setMode(true);
        rect2->setEndPoint(pnt1);
        rect2->setPos(0,0);
        rect2->bounding_strt_pnt = rect2->getStartPnt();
        rect2->bounding_end_pnt = rect2->getEndPnt();
        object->setObjectPos(rect2->getStartPnt(),rect->getEndPnt());
        object->setBoundPos(rect2->item->boundingRect().topLeft(),rect->item->boundingRect().bottomLeft());
    rect2->item = new QGraphicsPathItem(rect2->getRect(rect2->getStartPnt(),rect2->getEndPnt()));
    addItem(rect2->item);
        rect2->setEdgeRects();
        addItem(rect2->Strt_Rect);
        addItem(rect2->End_Rect);
        addItem(rect2->Rot_Rect);

    rect2->Strt_Rect->update();
    rect2->End_Rect->update();
    rect2->Rot_Rect->update();
    rect2->isObjectSelected=true;
    rects[rects.size()-1]=rect2;
        object->setObjects(2,rects.size()-1);
        object->ObjectIndx=rects.size()-1;

        object->pen=rect2->getPen();
        object->setbrush(rect2->getBrush());
      objects.push_back(object);
    objectToDraw=0;
    objectToEdit=2;

    }

    if(rect && rect->getMode()==true)
    {
        if(rect->getState()==1)
        {
           /*if(rect->item->rotation()==0)
           {
             rect->setStartPoint(rect->item->sceneBoundingRect().topLeft()-rect->item->pos());
             rect->setEndPoint(rect->item->sceneBoundingRect().bottomRight()-rect->item->pos());
             rect->item->setPath(rect->getRect(rect->getStartPnt(),rect->getEndPnt()));
             rect->updateEdgeRects();
           }*/
           rect->Strt_Rect->unsetCursor();
       rect->setState(0);
       this->objectToEdit=2;
       object2->setObjectPos(rect->item->sceneBoundingRect().topLeft(),rect->item->sceneBoundingRect().bottomRight());
       object2->setBoundPos(rect->item->boundingRect().topLeft(),rect->item->boundingRect().bottomLeft());

        }

        if(rect->getState()==2)
        {

            /*if(rect->item->rotation()==0)
            {
               rect->setStartPoint(rect->item->sceneBoundingRect().topLeft()-rect->item->pos());
               rect->setEndPoint(rect->item->sceneBoundingRect().bottomRight()-rect->item->pos());
               rect->item->setPath(rect->getRect(rect->getStartPnt(),rect->getEndPnt()));
               rect->updateEdgeRects();
            }*/
            rect->End_Rect->unsetCursor();
            rect->setState(0);

            object2->setObjectPos(rect->item->sceneBoundingRect().topLeft(),rect->item->sceneBoundingRect().bottomRight());
            object2->setBoundPos(rect->item->boundingRect().topLeft(),rect->item->boundingRect().bottomLeft());

        }

        if(rect->getState()==3)
        {
            /*if(rect->item->rotation()==0)
            {
               rect->setStartPoint(rect->item->sceneBoundingRect().topLeft()-rect->item->pos());
               rect->setEndPoint(rect->item->sceneBoundingRect().bottomRight()-rect->item->pos());
               rect->item->setPath(rect->getRect(rect->getStartPnt(),rect->getEndPnt()));
               rect->updateEdgeRects();
      }*/
      rect->item->unsetCursor();
            rect->setState(0);
      //rect->setStartPoint(rect->item->sceneBoundingRect().topLeft());
      //rect->setEndPoint(rect->item->sceneBoundingRect().bottomRight());
      object2->setObjectPos(rect->item->sceneBoundingRect().topLeft(),rect->item->sceneBoundingRect().bottomRight());
            object2->setBoundPos(rect->item->boundingRect().topLeft(),rect->item->boundingRect().bottomRight());
      //qDebug()<<"rectangle points"<<rect->getStartPnt()<<"  "<<rect->getEndPnt()<<"\n";
      //qDebug()<<"object points"<<object2->ObjectStrtPnt  <<"  "<<object2->ObjectEndPnt<<"\n";
      //objects[object_indx]=object2;
            objectToEdit=0;
        }

        if(rect->getState()==4)
        {

            //rect->item->setPath(rect->getRect(rect->getStartPnt(),rect->getEndPnt()));
            //rect->updateEdgeRects();
      if(rect->item->pos()==QPointF(0,0))
      {
         QPointF rot_pnt(rect->item->boundingRect().topLeft()-rect->item->sceneBoundingRect().topLeft());
               QPointF rot_pnt1(rect->item->boundingRect().bottomRight()-rect->item->sceneBoundingRect().bottomRight());

         rect->setStartPoint(rect->item->sceneBoundingRect().topLeft());
         rect->setEndPoint(rect->item->sceneBoundingRect().bottomRight());
      }

      if(rect->item->pos()!=QPointF(0,0))
      {
         QPointF rot_pnt(rect->item->boundingRect().topLeft()-rect->item->sceneBoundingRect().topLeft()-rect->item->pos());
               QPointF rot_pnt1(rect->item->boundingRect().bottomRight()-rect->item->sceneBoundingRect().bottomRight()-rect->item->pos());

         rect->setStartPoint(rect->item->sceneBoundingRect().topLeft()-rect->item->pos());
         rect->setEndPoint(rect->item->sceneBoundingRect().bottomRight()-rect->item->pos());
      }

       rect->setStartPoint(rect->item->sceneBoundingRect().topLeft());
       rect->setEndPoint(rect->item->sceneBoundingRect().bottomRight());

       //rect->setStartPoint(rect->item->sceneBoundingRect().topLeft());
       //rect->setEndPoint(rect->item->sceneBoundingRect().bottomRight());

       rect->rotationStartPoint=rect->getStartPnt();
       rect->rotationEndPoint=rect->getEndPnt();

      qDebug()<<"rotated  coords "<<rect->getStartPnt()<<" "<<rect->getEndPnt()<<"\n";
            object2->setObjectPos(rect->getStartPnt(),rect->getEndPnt());
            object2->setBoundPos(rect->item->boundingRect().topLeft(),rect->item->boundingRect().bottomLeft());
            rect->setState(0);
      //objects[indx]=object2;
        }

     }

  objectToEdit=2;
}

void Graph_Scene::draw_round_rect()
{
    bool k=false;

    if(round_rects.size()==0 && objectToDraw==5)
    {
        Draw_RoundRect* round_rect2 = new Draw_RoundRect();
        round_rect2->setStartPoint(strt_pnt);
        round_rect=round_rect2;
        temp_round_rect=round_rect2;
        round_rects.push_back(round_rect2);
        round_rect->item=new QGraphicsPathItem(round_rect->getRoundRect(strt_pnt,strt_pnt));
        addItem(round_rect->item);
    }

    if(!isMultipleSelected)
        hide_object_edges();

    for(int i=0;i<round_rects.size();i++)
    {

        if((round_rects[i]->isClickedOnHandleOrShape(strt_pnt))&&(round_rects[i]->getMode()==true))
        {
      round_rect=round_rects[i];
            indx=i;
            k=true;
            break;
        }
    }

    if(!k && round_rect && round_rects[round_rects.size()-1]->getMode()==true && objectToDraw==5)
    {

        Draw_RoundRect* round_rect2 = new Draw_RoundRect();
        round_rect=round_rect2;
    for(int i=0;i<round_rects.size();i++)
      round_rects[i]->isObjectSelected=false;
        round_rects.push_back(round_rect2);
        round_rect2->setStartPoint(strt_pnt);
        round_rect->item=new QGraphicsPathItem(round_rect->getRoundRect(strt_pnt,strt_pnt));
        addItem(round_rect->item);

    }
}



void Graph_Scene::draw_round_rect_move(QPointF pnt,QPointF pnt1)
{

    for(int i=0;i<round_rects.size();i++)
    {
        if((pnt1!=pnt)&&(round_rects[i]->getMode()==false))
        {
            round_rect->item->setPath(round_rect->getRoundRect(round_rects[i]->getStartPnt(),pnt1));

        }
     }

     if(round_rect && round_rect->getMode())
     {
     if(round_rect->getState()==1)
         {
           round_rect->isObjectSelected=true;
       round_rect->showHandles();
           if(pnt1!=pnt)
           {
              if(round_rect->item->rotation()==0)
              {
                 round_rect->item->setPath(round_rect->getRoundRect(pnt1-round_rect->item->pos(),round_rect->getEndPnt()));
                 round_rect->setStartPoint(pnt1-round_rect->item->pos());
                 round_rect->updateEdgeRects();
              }

              if(round_rect->item->rotation()!=0)
              {
                  pnt1=round_rect->End_Rect->mapFromScene(pnt1);
                  qDebug()<<"mouse press point1 "<<pnt1<<"\n";
          round_rect->item->setPath(round_rect->getRoundRect(pnt1,round_rect->item->boundingRect().bottomRight()));
                  round_rect->setStartPoint(pnt1);
                  round_rect->updateEdgeRects();
              }
           }
       isObjectEdited=true;
         }

          if(round_rect->getState()==2)
          {
             if(pnt1!=pnt)
             {
         round_rect->isObjectSelected=true;
         round_rect->showHandles();
                 if(round_rect->item->rotation()==0)
                 {
                     round_rect->item->setPath(round_rect->getRoundRect(round_rect->getStartPnt(),pnt1-round_rect->item->pos()));
                     round_rect->setEndPoint(pnt1-round_rect->item->pos());
                     round_rect->updateEdgeRects();
                 }

                 if(round_rect->item->rotation()!=0)
                 {
                     pnt1=round_rect->End_Rect->mapFromScene(pnt1);
                     qDebug()<<"mouse press point1 "<<pnt1<<"\n";
           round_rect->item->setPath(round_rect->getRoundRect(round_rect->item->boundingRect().topLeft(),pnt1));
                     round_rect->setEndPoint(pnt1);
                     round_rect->updateEdgeRects();
                 }

               }
         isObjectEdited=true;
           }

           if(round_rect->getState()==3)
           {
         round_rect->isObjectSelected=true;
         round_rect->showHandles();
               if(pnt1!=pnt)
               {

                   round_rect->setTranslate(pnt,pnt1);
                   //round_rect->item->setPath(round_rect->getRoundRect(round_rect->getStartPnt(),round_rect->getEndPnt()));
                   //round_rect->updateEdgeRects();
                   //object5->setObjectPos(round_rect->getStartPnt(),round_rect->getEndPnt());
                   //object5->setBoundPos(round_rect->item->boundingRect().topLeft(),round_rect->item->boundingRect().bottomLeft());
                }
         isObjectEdited=true;
            }

           if(round_rect->getState()==4)
           {
         round_rect->isObjectSelected=true;
         round_rect->showHandles();
               if(pnt1!=pnt)
               {

                  round_rect->setRotate(pnt,pnt1);
                  //round_rect->item->setPath(round_rect->getRoundRect(round_rect->getStartPnt(),round_rect->getEndPnt()));
                  //round_rect->updateEdgeRects();
                  object5->setObjectPos(round_rect->getStartPnt(),round_rect->getEndPnt());
                  object5->setBoundPos(round_rect->item->boundingRect().topLeft(),round_rect->item->boundingRect().bottomLeft());
               }
         isObjectEdited=true;
           }
       }
}

void Graph_Scene::draw_round_rect_state(QPointF pnt,QPointF pnt1)
{

    Scene_Objects* object = new Scene_Objects();
  Draw_RoundRect *round_rect2 = new Draw_RoundRect();
  round_rect2 = round_rect;

    if(round_rect && round_rect->getMode()==false  && objectToDraw==5)
    {
        last_pnt=pnt1;

    removeItem(round_rect2->item);
    round_rect->setMode(true);
        round_rect2->setMode(true);
        round_rect2->setEndPoint(pnt1);
        round_rect2->item->setPos(0,0);
        round_rect2->bounding_strt_pnt = round_rect2->getStartPnt();
        round_rect2->bounding_end_pnt = round_rect2->getEndPnt();
        object->setObjectPos(round_rect2->getStartPnt(),round_rect2->getEndPnt());
        object->setBoundPos(round_rect2->item->boundingRect().topLeft(),round_rect2->item->boundingRect().bottomLeft());
    round_rect2->item = new QGraphicsPathItem(round_rect2->getRoundRect(round_rect->getStartPnt(),round_rect->getEndPnt()));
    addItem(round_rect2->item);
    round_rect2->setEdgeRects();
        addItem(round_rect2->Strt_Rect);
        addItem(round_rect2->End_Rect);
        addItem(round_rect2->Rot_Rect);

        round_rect2->Strt_Rect->setPos(0,0);
        round_rect2->End_Rect->setPos(0,0);
        round_rect2->Rot_Rect->setPos(0,0);
    round_rect2->isObjectSelected=true;
    round_rects[round_rects.size()-1]=round_rect2;

        object->setObjects(5,round_rects.size()-1);
        object->pen=pen;
        object->setbrush(brush);
        object->ObjectIndx=round_rects.size()-1;
        objects.push_back(object);
    objectToDraw=0;


    }

    if(round_rect && round_rect->getMode()==true)
    {
        if(round_rect->getState()==1)
        {
           /*if(round_rect->item->rotation()==0)
           {
             round_rect->setStartPoint(round_rect->item->sceneBoundingRect().topLeft()-round_rect->item->pos());
             round_rect->setEndPoint(round_rect->item->sceneBoundingRect().bottomRight()-round_rect->item->pos());
             round_rect->item->setPath(round_rect->getRoundRect(round_rect->getStartPnt(),round_rect->getEndPnt()));
             round_rect->updateEdgeRects();
           }*/
           round_rect->Strt_Rect->unsetCursor();
           round_rect->setState(0);
       object5->setObjectPos(round_rect->item->sceneBoundingRect().topLeft(),round_rect->item->sceneBoundingRect().bottomRight());

        }

        if(round_rect->getState()==2)
        {
            //object5->setObjectPos(round_rect->getStartPnt(),round_rect->getEndPnt());
            //object5->setBoundPos(round_rect->item->boundingRect().topLeft(),round_rect->item->boundingRect().bottomLeft());
            /*if(round_rect->item->rotation()==0)
            {
               round_rect->setStartPoint(round_rect->item->sceneBoundingRect().topLeft()-round_rect->item->pos());
               round_rect->setEndPoint(round_rect->item->sceneBoundingRect().bottomRight()-round_rect->item->pos());
               round_rect->item->setPath(round_rect->getRoundRect(round_rect->getStartPnt(),round_rect->getEndPnt()));
               round_rect->updateEdgeRects();
            }*/
            round_rect->End_Rect->unsetCursor();
            round_rect->setState(0);
      object5->setObjectPos(round_rect->item->sceneBoundingRect().topLeft(),round_rect->item->sceneBoundingRect().bottomRight());
        }

        if(round_rect->getState()==3)
        {
            //round_rect->setEndPoint(round_rect->getEndPnt()-round_rect->item->pos());
            qDebug()<<"end point "<<round_rect->getEndPnt()<<"\n";
            //object5->setObjectPos(round_rect->getStartPnt(),round_rect->getEndPnt());
            //object5->setBoundPos(round_rect->item->boundingRect().topLeft(),round_rect->item->boundingRect().bottomLeft());
            //round_rect->prev_pos=round_rect->item->pos();
            /*if(round_rect->item->rotation()==0)
            {
               round_rect->setStartPoint(round_rect->item->sceneBoundingRect().topLeft()-round_rect->item->pos());
               round_rect->setEndPoint(round_rect->item->sceneBoundingRect().bottomRight()-round_rect->item->pos());
               round_rect->item->setPath(round_rect->getRoundRect(round_rect->getStartPnt(),round_rect->getEndPnt()));
               round_rect->updateEdgeRects();
            }*/
            round_rect->item->unsetCursor();
            round_rect->setState(0);
      object5->setObjectPos(round_rect->item->sceneBoundingRect().topLeft(),round_rect->item->sceneBoundingRect().bottomRight());
      object5->setBoundPos(round_rect->item->boundingRect().topLeft(),round_rect->item->boundingRect().bottomLeft());
      //objects[object_indx]=object5;
      this->objectToEdit=0;
        }

        if(round_rect->getState()==4)
        {
            //round_rect->prev_pos=round_rect->End_Rect->scenePos();
            //round_rect->prev_pos=round_rect->item->pos();
            //round_rect->item->setPath(round_rect->getRoundRect(round_rect->getStartPnt(),round_rect->getEndPnt()));
            //round_rect->updateEdgeRects();
            object5->setObjectPos(round_rect->getStartPnt(),round_rect->getEndPnt());
            object5->setBoundPos(round_rect->item->boundingRect().topLeft(),round_rect->item->boundingRect().bottomLeft());
            round_rect->setState(0);
        }

     }

  objectToEdit=5;
}


void Graph_Scene::draw_ellep()
{
    bool k=false;

    if(elleps.size()==0 && objectToDraw==3)
    {
        Draw_Ellipse* ellep2 = new Draw_Ellipse();
        ellep2->setStartPoint(strt_pnt);
        ellep=ellep2;
        elleps.push_back(ellep2);
        ellep->item = new QGraphicsPathItem(ellep->getEllep(strt_pnt,strt_pnt));
        addItem(ellep->item);
    }

    if(!isMultipleSelected)
        hide_object_edges();

    for(int i=0;i<elleps.size();i++)
    {
        if((elleps[i]->isClickedOnHandleOrShape(strt_pnt))&&(elleps[i]->getMode()==true))
        {
             ellep=elleps[i];
             indx=i;
             k=true;
             break;
        }
    }
  if(!k && ellep && elleps[elleps.size()-1]->getMode()==true && objectToDraw==3)
    {
        Draw_Ellipse* ellep2 = new Draw_Ellipse();
        ellep=ellep2;
    for(int i=0;i<elleps.size();i++)
      elleps[i]->isObjectSelected=false;
        elleps.push_back(ellep2);
        ellep2->setStartPoint(strt_pnt);
        ellep->item = new QGraphicsPathItem(ellep->getEllep(strt_pnt,strt_pnt));
        addItem(ellep->item);
    }
}


void Graph_Scene::draw_ellep_move(QPointF pnt,QPointF pnt1)
{

    for(int i=0;i<elleps.size();i++)
    {
        if((pnt1!=pnt)&&(elleps[i]->getMode()==false))
        {
           elleps[i]->item->setPath(elleps[i]->getEllep(elleps[i]->getStartPnt(),pnt1));
        }
     }

     if(ellep && ellep->getMode())
     {
     if(ellep->getState()==1)
         {
       ellep->isObjectSelected=true;
       ellep->showHandles();
             if(ellep->item->rotation()==0)
             {
                ellep->item->setPath(ellep->getEllep(pnt1-ellep->item->pos(),ellep->getEndPnt()));
                ellep->setStartPoint(pnt1-ellep->item->pos());
                ellep->updateEdgeRects();
             }

             if(ellep->item->rotation()!=0)
             {
                 pnt1=ellep->End_Rect->mapFromScene(pnt1);
                 qDebug()<<"mouse press point1 "<<pnt1<<"\n";
         ellep->item->setPath(ellep->getEllep(pnt1,ellep->item->boundingRect().bottomRight()));
                 ellep->setStartPoint(pnt1);
                 ellep->updateEdgeRects();
             }
             object3->setObjectPos(ellep->getStartPnt(),ellep->getEndPnt());
             object3->setBoundPos(ellep->item->boundingRect().topLeft(),ellep->item->boundingRect().bottomLeft());
       isObjectEdited=true;
          }

          if(ellep->getState()==2)
          {
        ellep->isObjectSelected=true;
        ellep->showHandles();
              if(ellep->item->rotation()==0)
              {
                  ellep->item->setPath(ellep->getEllep(ellep->getStartPnt(),pnt1-ellep->item->pos()));
                  ellep->setEndPoint(pnt1-ellep->item->pos());
                  ellep->updateEdgeRects();
              }

              if(ellep->item->rotation()!=0)
              {
                  pnt1=ellep->End_Rect->mapFromScene(pnt1);
                  qDebug()<<"mouse press point1 "<<pnt1<<"\n";
          ellep->item->setPath(ellep->getEllep(ellep->item->boundingRect().topLeft(),pnt1));
                  ellep->setEndPoint(pnt1);
                  ellep->updateEdgeRects();
              }

              object3->setObjectPos(ellep->getStartPnt(),ellep->getEndPnt());
              object3->setBoundPos(ellep->item->boundingRect().topLeft(),ellep->item->boundingRect().bottomLeft());
        isObjectEdited=true;

           }

           if(ellep->getState()==3)
           {
               if(pnt1!=pnt)
               {
           ellep->isObjectSelected=true;
           ellep->showHandles();
                   ellep->setTranslate(pnt,pnt1);

                   //ellep->item->setPath(ellep->getEllep(ellep->getStartPnt(),ellep->getEndPnt()));
                   //ellep->updateEdgeRects();
                   //object3->setObjectPos(ellep->getStartPnt(),ellep->getEndPnt());
                   //object3->setBoundPos(ellep->item->boundingRect().topLeft(),ellep->item->boundingRect().bottomLeft());
               }
         isObjectEdited=true;
            }

            if(ellep->getState()==4)
            {
         ellep->isObjectSelected=true;
         ellep->showHandles();
                 if(pnt1!=pnt)
                 {
                   ellep->setRotate(pnt,pnt1);

                 }
         isObjectEdited=true;
            }
        }
}

void Graph_Scene::draw_ellep_state(QPointF pnt,QPointF pnt1)
{
    Scene_Objects* object = new Scene_Objects();
  Draw_Ellipse *ellep2  = new Draw_Ellipse();
  ellep2=ellep;

    if(ellep && ellep->getMode()==false && objectToDraw==3)
    {
        last_pnt=pnt1;

    removeItem(ellep2->item);
    ellep->setMode(true);
        ellep2->setMode(true);
        ellep2->setEndPoint(pnt1);
        ellep2->bounding_strt_pnt = ellep2->getStartPnt();
        ellep2->bounding_end_pnt = ellep2->getEndPnt();
        object->setObjectPos(ellep2->getStartPnt(),ellep2->getEndPnt());
        object->setBoundPos(ellep2->item->boundingRect().topLeft(),ellep2->item->boundingRect().bottomLeft());
    ellep2->item = new QGraphicsPathItem(ellep2->getEllep(ellep2->getStartPnt(),ellep2->getEndPnt()));
    addItem(ellep2->item);
        ellep2->setEdgeRects();
        addItem(ellep2->Strt_Rect);
        addItem(ellep2->End_Rect);
        addItem(ellep2->Rot_Rect);
    ellep2->isObjectSelected=true;
    elleps[elleps.size()-1]=ellep2;
        object->setObjects(3,elleps.size()-1);
        object->pen=pen;
        object->setbrush(brush);
        object->ObjectIndx=elleps.size()-1;
        objects.push_back(object);
    objectToDraw=0;
    }

    if(ellep && ellep->getMode()==true)
    {
        if(ellep->getState()==1)
        {
           /* if(ellep->item->rotation()==0)
            {
              ellep->setStartPoint(ellep->item->sceneBoundingRect().topLeft()-ellep->item->pos());
              ellep->setEndPoint(ellep->item->sceneBoundingRect().bottomRight()-ellep->item->pos());
              ellep->item->setPath(ellep->getEllep(ellep->getStartPnt(),ellep->getEndPnt()));
              ellep->updateEdgeRects();
            }*/
            ellep->Strt_Rect->unsetCursor();
            ellep->setState(0);

           object3->setObjectPos(ellep->item->sceneBoundingRect().topLeft(),ellep->item->sceneBoundingRect().bottomRight());
           object3->setBoundPos(ellep->item->boundingRect().topLeft(),ellep->item->boundingRect().bottomLeft());

        }

        if(ellep->getState()==2)
        {
           /* if(ellep->item->rotation()==0)
            {
               ellep->setStartPoint(ellep->item->sceneBoundingRect().topLeft()-ellep->item->pos());
               ellep->setEndPoint(ellep->item->sceneBoundingRect().bottomRight()-ellep->item->pos());
               ellep->item->setPath(ellep->getEllep(ellep->getStartPnt(),ellep->getEndPnt()));
               ellep->updateEdgeRects();
            }*/
            ellep->End_Rect->unsetCursor();
            ellep->setState(0);

            object3->setObjectPos(ellep->item->sceneBoundingRect().topLeft(),ellep->item->sceneBoundingRect().bottomRight());
            object3->setBoundPos(ellep->item->boundingRect().topLeft(),ellep->item->boundingRect().bottomLeft());

        }

        if(ellep->getState()==3)
        {

            /*if(ellep->item->rotation()==0)
            {
               ellep->setStartPoint(ellep->item->sceneBoundingRect().topLeft()-ellep->item->pos());
               ellep->setEndPoint(ellep->item->sceneBoundingRect().bottomRight()-ellep->item->pos());
               ellep->item->setPath(ellep->getEllep(ellep->getStartPnt(),ellep->getEndPnt()));
               ellep->updateEdgeRects();
            }*/
            ellep->item->unsetCursor();
            ellep->setState(0);

            object3->setObjectPos(ellep->item->sceneBoundingRect().topLeft(),ellep->item->sceneBoundingRect().bottomRight());
            object3->setBoundPos(ellep->item->boundingRect().topLeft(),ellep->item->boundingRect().bottomLeft());

        }

        if(ellep->getState()==4)
        {
            ellep->item->setPath(ellep->getEllep(ellep->getStartPnt(),ellep->getEndPnt()));
            ellep->updateEdgeRects();
            object3->setObjectPos(ellep->getStartPnt(),ellep->getEndPnt());
            object3->setBoundPos(ellep->item->boundingRect().topLeft(),ellep->item->boundingRect().bottomLeft());
            ellep->setState(0);
        }

     }

  objectToEdit=3;
}

void Graph_Scene::draw_polygon()
{
    bool k=false;
    if(polygons.isEmpty() && objectToDraw==4)
    {
       polygon->poly_pnts.push_back(strt_pnt);

       if(polygon && polygon->getLines().isEmpty())
       {
          polygon->setStartPoint(strt_pnt);
       }
       else
       {
          QPointF point;
          point=polygon->getLine(polygon->getLines().size()-1)->line().p2();
          polygon->setStartPoint(point);
       }
       addItem(polygon->getLine());

       if(mode)
       {
           strt_pnt=strt1_pnt;
           mode=false;
       }
    }

    if(!isMultipleSelected)
        hide_object_edges();


    for(int i=0;i<polygons.size();i++)
    {
       //qDebug()<<"polygon region "<<polygons[i]->item->boundingRect().topLeft()<<" "<< polygons[i]->item->boundingRect().bottomRight()<<"\n";
       if(polygons[i]->isClickedOnHandleOrShape(strt_pnt))
       {
            polygon=polygons[i];
            indx=i;
      poly_indx=polygons[i]->getHandelIndex();
            k=true;
            break;
       }
    }



    if(polygons.size()>=1 && (!k) && objectToDraw==4)
    {
    qDebug()<<"polygon line size "<<polygon->getLines().size()<<"\n";
        if(polygon && polygon->getLines().isEmpty()&&(polygons[polygons.size()-1]->getPolygonDrawn()))
        {
            Draw_Polygon* poly2 = new Draw_Polygon();
            poly2->setPolygonDrawn(false);
            polygon=poly2;
            polygon->poly_pnts.push_back(strt_pnt);
            polygon->setStartPoint(strt_pnt);
      qDebug()<<"entered second polygon "<<polygon->poly_pnts[0]<<"  "<<polygon->lines.size()<<"\n";
        }
        else
        {
           QPointF point;
           polygon->poly_pnts.push_back(strt_pnt);
           point=polygon->getLine(polygon->getLines().size()-1)->line().p2();
           polygon->setStartPoint(point);
        }
        addItem(polygon->getLine());

        if(mode)
        {
            //strt_pnt=strt1_pnt;
            mode=false;
        }
    }
}


void Graph_Scene::draw_polygon_move(QPointF pnt,QPointF pnt1)
{
     if(polygons.isEmpty()&&(!polygon->getPolygonDrawn()))
     {
         QLineF newLine(polygon->getLine()->line().p1(),pnt1);
         polygon->setLine(newLine);
     }

     //for(int i=1;i<polygons.size();i++)
     {
        if(polygons.size()>=1&&(polygons[polygons.size()-1]->getPolygonDrawn()))
        {
            QLineF newLine(polygon->getLine()->line().p1(),pnt1);
            polygon->setLine(newLine);
        }
     }

     if((!polygons.isEmpty()) && polygon && (polygon->getPolygonDrawn()))
     {
         /*if(poly_indx<polygon->poly_pnts.size())
         {
       polygon->showHandles();
         }*/
          if(polygon->getState()==1)
          {
       polygon->isObjectSelected=true;
       polygon->showHandles();
             if(pnt1!=pnt)
             {
                 if(poly_indx<polygon->poly_pnts.size())
                 {
                    if(polygon->item->rotation()==0)
                    {
                       polygon->item->setPath(polygon->getPolygon(poly_indx,pnt,pnt1));

                       QPointF pnt2,pnt3;
                       pnt2=pnt1;
                       pnt3=pnt1;
                       pnt2-=QPointF(5.0,5.0);
                       pnt3+=QPointF(5.0,5.0);
                       QRectF newRect(pnt2,pnt3);
                       polygon->edge_items[poly_indx]->setRect(newRect);
                    }

                    if(polygon->item->rotation()!=0)
                    {

                        pnt=polygon->item->mapFromScene(pnt);
                        pnt1=polygon->item->mapFromScene(pnt1);
                        polygon->item->setPath(polygon->getPolygon(poly_indx,pnt,pnt1));

                        QPointF pnt2,pnt3;
                        pnt2=pnt1;
                        pnt3=pnt1;
                        pnt2-=QPointF(5.0,5.0);
                        pnt3+=QPointF(5.0,5.0);
                        QRectF newRect(pnt2,pnt3);
                        polygon->edge_items[poly_indx]->setRect(newRect);
                    }

                    object4->setObjectPos(polygon->item->boundingRect().topLeft(),polygon->item->boundingRect().bottomRight());
                    object4->setBoundPos(polygon->item->boundingRect().topLeft(),polygon->item->boundingRect().bottomRight());
                    object4->pnts=polygon->poly_pnts;
          isObjectEdited=true;

                  }
                }
           }

         if(polygon && polygon->getState()==2)
         {
       polygon->isObjectSelected=true;
       polygon->showHandles();
             /*if(polygon->item->isSelected())
             {
                for(int i=0;i<polygon->edge_items.size();i++)
                {
                    if(!polygon->edge_items[i]->isVisible())
                    {
                        polygon->edge_items[i]->show();
                    }
                }
             }*/
             polygon->setTranslate(pnt,pnt1);
             //polygon->item->setPath(polygon->getPolygon());
             object4->setObjectPos(polygon->item->boundingRect().topLeft(),polygon->item->boundingRect().bottomRight());
             object4->setBoundPos(polygon->item->boundingRect().topLeft(),polygon->item->boundingRect().bottomRight());
             object4->pnts=polygon->poly_pnts;
       isObjectEdited=true;
         }

         if(polygon && polygon->getState()==3)
         {
       polygon->isObjectSelected=true;
       polygon->showHandles();

             polygon->setRotate(pnt,pnt1);

            //polygon->item->setPath(polygon->getPolygon());
            //object4->setObjectPos(polygon->item->boundingRect().topLeft(),polygon->item->boundingRect().bottomRight());
            //object4->setBoundPos(polygon->item->boundingRect().topLeft(),polygon->item->boundingRect().bottomRight());
            //object4->pnts=polygon->poly_pnts;
            isObjectEdited=true;
         }
     }
}


void Graph_Scene::draw_polygon_state(QPointF pnt,QPointF pnt1)
{
    if(polygon && (polygons.isEmpty())&&!polygon->getPolygonDrawn() && objectToDraw==4)
    {
      polygon->setEndPoint(pnt1);
    }

    if(polygon && (polygons.size()>=1)&&!polygon->getPolygonDrawn() && objectToDraw==4)
    {
      qDebug()<<"entered polyon state\n";
      polygon->setEndPoint(pnt1);
      polygon->setPolygonDrawn(false);
    }

    if(polygon && polygon->getPolygonDrawn())
    {
        if(polygon->getState()==1)
        {
            object4->setObjectPos(polygon->item->boundingRect().topLeft(),polygon->item->boundingRect().bottomRight());
            object4->setBoundPos(polygon->item->boundingRect().topLeft(),polygon->item->boundingRect().bottomRight());
            object4->pnts=polygon->poly_pnts;
            polygon->setState(0);
            objectToEdit=4;
        }

        if(polygon->getState()==2)
        {
            object4->setObjectPos(polygon->item->boundingRect().topLeft(),polygon->item->boundingRect().bottomRight());
            object4->setBoundPos(polygon->item->boundingRect().topLeft(),polygon->item->boundingRect().bottomRight());
            object4->pnts=polygon->poly_pnts;
            polygon->setState(0);
            objectToEdit=4;
        }

        if(polygon->getState()==3)
        {
            polygon->setState(0);
            objectToEdit=4;
        }

    }

}



void Graph_Scene::draw_triangle() {
  bool k=false;
  if(triangles.isEmpty() && objectToDraw==8) {
    Draw_Triangle *triangle2 = new Draw_Triangle();
    triangle2->setStartPoint(strt_pnt);
    triangle2->item = new QGraphicsPathItem(triangle2->getTriangle());
    addItem(triangle2->item);
    triangle=triangle2;
  }
  if(!isMultipleSelected) {
    hide_object_edges();
  }
  for(int i=0;i<triangles.size();i++) {
    if((triangles[i]->isClickedOnHandleOrShape(strt_pnt))&&(triangles[i]->getMode()==true)) {
      triangle=triangles[i];
      indx=i;
      k=true;
      break;
    }
  }
  if(!triangles.isEmpty() && objectToDraw==8) {
    if(!k && triangle && triangles[triangles.size()-1]->getMode()==true) {
      Draw_Triangle *triangle2 = new Draw_Triangle();
      triangle2->setStartPoint(strt_pnt);
      triangle2->item = new QGraphicsPathItem(triangle2->getTriangle());
      triangle=triangle2;
    }
  }
}

void Graph_Scene::draw_triangle_move(QPointF pnt,QPointF pnt1)
{
  QPointF move_pnt;

    if(triangle && triangle->getMode())
    {
    if(triangle->getState()==1)
        {
      triangle->isObjectSelected=true;
      triangle->showHandles();
          if(pnt1!=pnt)
          {
        if(triangle->item->rotation()==0 || triangle->item->rotation()!=0)
             {

         qDebug()<<"handle index "<<triangle->handle_index<<"\n";


         if(triangle->handle_index==0)
         {
           if((pnt.x()!=pnt1.x())&&(pnt.y()!=pnt1.y()))
           {
             if(pnt1.y()>pnt.y()||pnt1.y()<pnt.y())
             {
                triangle->item->setPath(triangle->getTriangle());
                    triangle->updateEdgeRects();
              //if(triangle->item->rotation()!=0)
                pnt1=triangle->handles[0]->mapFromScene(pnt1);
                triangle->setStartPoint(QPointF(pnt1.x(),triangle->getStartPnt().y()));
              triangle->setEndPoint(triangle->getEndPnt());
                            move_pnt.setX((triangle->getEndPnt().x()+triangle->getStartPnt().x())/2.0);
                  move_pnt.setY(pnt1.y());
                            triangle->setHeightPoint(move_pnt);
                         }
           }

                 }

         if(triangle->handle_index==1)
         {
          triangle->item->setPath(triangle->getTriangle());
            triangle->updateEdgeRects();
          //if(triangle->item->rotation()!=0)
            pnt1=triangle->handles[1]->mapFromScene(pnt1);
          triangle->setStartPoint(QPointF(pnt1.x(),triangle->getStartPnt().y()));
                    triangle->setEndPoint(triangle->getEndPnt());
                    move_pnt.setX((triangle->getEndPnt().x()+triangle->getStartPnt().x())/2.0);
          move_pnt.setY(triangle->getHeightPnt().y());
                    triangle->setHeightPoint(move_pnt);
         }


         if(triangle->handle_index==2)
         {
          triangle->item->setPath(triangle->getTriangle());
            triangle->updateEdgeRects();
          //if(triangle->item->rotation()!=0)
            pnt1=triangle->handles[2]->mapFromScene(pnt1);
          triangle->setStartPoint(triangle->getStartPnt());
                    triangle->setEndPoint(QPointF(pnt1.x(),triangle->getEndPnt().y()));
                    move_pnt.setX((triangle->getEndPnt().x()+triangle->getStartPnt().x())/2.0);
          move_pnt.setY(pnt1.y());
                    triangle->setHeightPoint(move_pnt);
         }

         if(triangle->handle_index==3)
         {
          triangle->item->setPath(triangle->getTriangle());
            triangle->updateEdgeRects();
          //if(triangle->item->rotation()!=0)
            pnt1=triangle->handles[3]->mapFromScene(pnt1);
          triangle->setStartPoint(triangle->getStartPnt());
                    triangle->setEndPoint(QPointF(pnt1.x(),triangle->getEndPnt().y()));
                    move_pnt.setX((triangle->getEndPnt().x()+triangle->getStartPnt().x())/2.0);
          move_pnt.setY(triangle->getHeightPnt().y());
                    triangle->setHeightPoint(move_pnt);
         }

         if(triangle->handle_index==4)
         {
           if((pnt.x()!=pnt1.x())&&(pnt.y()!=pnt1.y()))
           {
             if(pnt1.y()>pnt.y()||pnt1.y()<pnt.y())
             {
                triangle->item->setPath(triangle->getTriangle());
                    triangle->updateEdgeRects();
              //if(triangle->item->rotation()!=0)
                pnt1=triangle->handles[4]->mapFromScene(pnt1);
                triangle->setStartPoint(pnt1);
              triangle->setEndPoint(QPointF(triangle->getEndPnt().x(),pnt1.y()));
                            move_pnt.setX((triangle->getEndPnt().x()+triangle->getStartPnt().x())/2.0);
                  move_pnt.setY(triangle->getHeightPnt().y());
                            triangle->setHeightPoint(move_pnt);
                         }
           }

                 }

         if(triangle->handle_index==6)
         {
           if((pnt.x()!=pnt1.x())&&(pnt.y()!=pnt1.y()))
           {
             if(pnt1.y()>pnt.y()||pnt1.y()<pnt.y())
             {
                triangle->item->setPath(triangle->getTriangle());
                    triangle->updateEdgeRects();
              //if(triangle->item->rotation()!=0)
                pnt1=triangle->handles[6]->mapFromScene(pnt1);
                triangle->setStartPoint(QPointF(triangle->getStartPnt().x(),pnt1.y()));
              triangle->setEndPoint(pnt1);
                            move_pnt.setX((triangle->getEndPnt().x()+triangle->getStartPnt().x())/2.0);
                  move_pnt.setY(triangle->getHeightPnt().y());
                            triangle->setHeightPoint(move_pnt);
                         }
           }

                 }



         if(triangle->handle_index==5)
         {
          triangle->item->setPath(triangle->getTriangle());
            triangle->updateEdgeRects();
          //if(triangle->item->rotation()!=0)
            pnt1=triangle->handles[5]->mapFromScene(pnt1);
          triangle->setStartPoint(QPointF(triangle->getStartPnt().x(),pnt1.y()));
                    triangle->setEndPoint(QPointF(triangle->getEndPnt().x(),pnt1.y()));
                    move_pnt.setX((triangle->getEndPnt().x()+triangle->getStartPnt().x())/2.0);
          move_pnt.setY(triangle->getHeightPnt().y());
                    triangle->setHeightPoint(move_pnt);
         }

         if(triangle->handle_index==7)
         {
          triangle->item->setPath(triangle->getTriangle());
                    triangle->updateEdgeRects();
          //if(triangle->item->rotation()!=0)
            pnt1=triangle->handles[7]->mapFromScene(pnt1);
                    triangle->setHeightPoint(QPointF(triangle->getHeightPnt().x(),pnt1.y()));
                    triangle->bounding_strt_pnt=triangle->getStartPnt();
                    triangle->bounding_end_pnt=triangle->getEndPnt();
         }


             }
       isObjectEdited=true;
          }
        }


          if(triangle->getState()==4)
          {
        triangle->isObjectSelected=true;
          triangle->showHandles();
              if(pnt1!=pnt)
              {
                 triangle->setTranslate(pnt,pnt1);
              }
        isObjectEdited=true;
           }

          if(triangle->getState()==5)
          {
        triangle->isObjectSelected=true;
          triangle->showHandles();
              if(pnt1!=pnt)
              {
                 triangle->setRotate(pnt,pnt1);
              }
        isObjectEdited=true;
          }
      }
}

void Graph_Scene::draw_triangle_state(QPointF pnt,QPointF pnt1)
{
    Scene_Objects *object = new Scene_Objects();
  Draw_Triangle *triangle2 = new Draw_Triangle();
  triangle2 = triangle;
    if(triangle && (triangle->getMode()==false) && objectToDraw==8)
    {
     removeItem(triangle2->item);
       triangle->setMode(true);
     triangle2->setMode(true);
     triangle2->item = new QGraphicsPathItem(triangle2->getTriangle());
     addItem(triangle2->item);
       triangle2->setEdgeRects();

     for(int i=0;i<triangle2->handles.size();i++)
       addItem(triangle2->handles[i]);

     addItem(triangle2->Bounding_Rect);
       addItem(triangle2->Rot_Rect);
       triangle2->Bounding_Rect->hide();
     triangle2->isObjectSelected=true;
     for(int i=0;i<triangles.size();i++)
       triangles[i]->isObjectSelected=false;
       triangles.push_back(triangle2);
       object->setObjectPos(triangle2->item->boundingRect().topLeft(),triangle2->item->boundingRect().bottomRight());
       object->setBoundPos(triangle2->item->boundingRect().topLeft(),triangle2->item->boundingRect().bottomRight());
     object->pnts.push_back(QPointF(triangle2->getStartPnt()));
       object->pnts.push_back(QPointF(triangle2->getEndPnt()));
       object->pnts.push_back(QPointF(triangle2->getHeightPnt()));
       object->setObjects(8,triangles.size()-1);
       object->ObjectIndx=triangles.size()-1;
       objects.push_back(object);
     objectToDraw=0;

     qDebug()<<"triangle points "<<triangle->getStartPnt()<<"  "<<triangle->getEndPnt()<<" "<<triangle->getHeightPnt()<<"\n";
     qDebug()<<"enter data when  drawn "<<triangle->item->transform()<<"  "<<triangle->item->sceneTransform().map(QPointF(0,0))<<"\n";
    }

    if(triangle && triangle->getMode()==true)
    {
        if(triangle->getState()==1)
        {
           object8->setObjectPos(triangle->item->boundingRect().topLeft(),triangle->item->boundingRect().bottomRight());
           object8->setBoundPos(triangle->item->boundingRect().topLeft(),triangle->item->boundingRect().bottomRight());
           object8->pnts.empty();
           object8->pnts.push_back(QPointF(triangle->getHeightPnt()));
           triangle->setState(0);
        }

        if(triangle->getState()==2)
        {
            object8->setObjectPos(triangle->item->boundingRect().topLeft(),triangle->item->boundingRect().bottomRight());
            object8->setBoundPos(triangle->item->boundingRect().topLeft(),triangle->item->boundingRect().bottomRight());
            object8->pnts.empty();
            object8->pnts.push_back(QPointF(triangle->getHeightPnt()));
            triangle->setState(0);
        }

        if(triangle->getState()==3)
        {

            object8->setObjectPos(triangle->item->boundingRect().topLeft(),triangle->item->boundingRect().bottomRight());
            object8->setBoundPos(triangle->item->boundingRect().topLeft(),triangle->item->boundingRect().bottomRight());
            object8->pnts.empty();
            object8->pnts.push_back(QPointF(triangle->getHeightPnt()));
            triangle->setState(0);
        }

        if(triangle->getState()==4)
        {
      //reset and the reset the positin attribute of triangle and its handles
      if(triangle->item->rotation()==0)
      {
         triangle->item->setPath(triangle->getTriangle());
         triangle->updateEdgeRects();
         triangle->item->setPos(0,0);
         /*triangle->Strt_Rect->setPos(0,0);
         triangle->End_Rect->setPos(0,0);
         triangle->Height_Rect->setPos(0,0);*/
         for(int i=0;i<triangle->handles.size();i++)
           triangle->handles[i]->setPos(0,0);
         triangle->Rot_Rect->setPos(0,0);
         triangle->Bounding_Rect->setPos(0,0);


      }

           /* if(triangle->item->rotation()!=0)
      {
         triangle->item->setPath(triangle->getTriangle());
         triangle->updateEdgeRects();
         triangle->item->setRotation(0.0);
         triangle->item->setPos(0,0);
         triangle->Strt_Rect->setRotation(0.0);
         triangle->Strt_Rect->setPos(0,0);
         triangle->End_Rect->setRotation(0.0);
         triangle->End_Rect->setPos(0,0);
         triangle->Height_Rect->setRotation(0.0);
         triangle->Height_Rect->setPos(0,0);
         triangle->Rot_Rect->setRotation(0.0);
         triangle->Rot_Rect->setPos(0,0);
         triangle->Bounding_Rect->setRotation(0.0);
         triangle->Bounding_Rect->setPos(0,0);
      } */

      object8->setObjectPos(triangle->item->boundingRect().topLeft(),triangle->item->boundingRect().bottomRight());
            object8->setBoundPos(triangle->item->boundingRect().topLeft(),triangle->item->boundingRect().bottomRight());
            object8->pnts.empty();
            object8->pnts.push_back(QPointF(triangle->getHeightPnt()));
            triangle->setState(0);
            triangle->Bounding_Rect->hide();
        }

        if(triangle->getState()==5)
        {
            /*object6->setObjectPos(arc->getStartPnt(),arc->getEndPnt());
            object6->setBoundPos(arc->item->boundingRect().topLeft(),arc->item->boundingRect().bottomRight());
            object6->pnts.empty();
            object6->pnts.push_back(QPointF(arc->getCurvePnt()));*/
      /*QPointF map_pnt(0,0);
      triangle->item->mapToItem(triangle->Strt_Rect,map_pnt);
      qDebug()<<"item rotation angle "<<triangle->item->rotation()<<"  "<<triangle->mapToScene(QPointF(0,0))<<"\n";
      qDebug()<<"enter data "<<triangle->item->transform()<<"  "<<triangle->item->sceneTransform().map(QPointF(0,0))<<"\n";
      qDebug()<<"enter data top map "<<triangle->item->sceneBoundingRect().topLeft()<<"  "<<triangle->item->sceneBoundingRect().topRight()<<"\n";
      qDebug()<<"enter data map "<<triangle->item->sceneBoundingRect().bottomLeft()<<"  "<<triangle->item->sceneBoundingRect().bottomRight()<<"\n";
            triangle->setState(0);
            triangle->Bounding_Rect->hide();*/
        }


     }

  objectToEdit=8;
}

void Graph_Scene::draw_text() {
  bool k=false;
  if(texts.isEmpty() && objectToDraw==10) {
    Draw_Text *text2 = new Draw_Text(strt_pnt);
    texts.push_back(text2);
    addItem(text2->item);
    text = text2;
  }
  //if(!isMultipleSelected)
  //  hide_object_edges();
  for(int i=0;i<texts.size();i++) {
    texts[i]->isObjectSelected=false;
    if((check_object(strt_pnt,texts[i]))&&(texts[i]->getMode()==true)) {
      text=texts[i];
      indx=i;
      k=true;
      break;
    }
  }

  if(!texts.isEmpty() && objectToDraw==10)
  if(!k && text && text && texts[texts.size()-1]->getMode()) {
    Draw_Text *text2 = new Draw_Text(strt_pnt);
    for(int i=0;i<rects.size();i++)
      rects[i]->isObjectSelected=false;
    texts.push_back(text);
    text=text2;
    addItem(text->item);
  }
}

bool Graph_Scene::check_object(QPointF pnt,Draw_Text* text1) {
  int k=0;
  if(text1->getMode()) {
    if(text1->getStrtEdge(pnt))
      k=text1->getState();
    else if(text1->getEndEdge(pnt))
      k=text1->getState();
    else if(text1->getItemSelected(pnt))
      k=text1->getState();
    else if(text1->getRotEdge(pnt))
      k=text1->getState();
    else
      k=0;
  }
  if(k==1||k==2||k==3||k==4)
    return true;
  else
    return false;
}


void Graph_Scene::draw_text_move(QPointF pnt,QPointF pnt1)
{

    if(text && text->getMode())
    {
        if(!text->Strt_Rect->isVisible())
            text->Strt_Rect->show();
        if(!text->End_Rect->isVisible())
            text->End_Rect->show();

        if(text->getState()==1)
        {
          text->isObjectSelected = true;
          if(pnt1!=pnt)
          {
             if(text->item->rotation()==0)
             {
                text->updateEdgeRects();
                text->setStartPoint(pnt1);
                //text->bounding_strt_pnt=pnt1;
                //text->bounding_end_pnt=text->getEndPnt();
             }
             if(text->item->rotation()!=0)
             {
                pnt1=text->Strt_Rect->mapFromScene(pnt1);
                text->updateEdgeRects();
                text->setStartPoint(pnt1);
                //text->bounding_strt_pnt=pnt1;
                //text->bounding_end_pnt=text->getEndPnt();
             }
       isObjectEdited=true;
          }
        }

         if(text->getState()==2)
         {
           text->isObjectSelected = true;
            if(pnt1!=pnt)
            {
                if(text->item->rotation()==0)
                {
                   //triangle->item->setPath(triangle->getTriangle());
                   text->updateEdgeRects();
                   text->setEndPoint(pnt1);
                   //text->bounding_strt_pnt=triangle->getStartPnt();
                   //text->bounding_end_pnt=pnt1;
                }

                if(text->item->rotation()!=0)
                {
                   pnt1=text->End_Rect->mapFromScene(pnt1);
                   //text->item->setPath(triangle->getTriangle());
                   text->updateEdgeRects();
                   text->setEndPoint(pnt1);
                   //text->bounding_strt_pnt=pnt1;
                   //text->bounding_end_pnt=text->getEndPnt();
                }
        isObjectEdited=true;
            }
          }


          if(text->getState()==3)
          {
            text->isObjectSelected = true;
              text->Bounding_Rect->show();
              if(pnt1!=pnt)
              {
                  text->setTranslate(pnt,pnt1);
                  //text->item->setPath(triangle->getTriangle());
                  text->updateEdgeRects();
              }
        isObjectEdited=true;
           }

          if(text->getState()==4)
          {
            text->isObjectSelected = true;
              text->Bounding_Rect->show();
              if(pnt1!=pnt)
              {
                 text->setRotate(pnt,pnt1);
              }
        isObjectEdited=true;
          }
      }
}

void Graph_Scene::draw_text_state(QPointF pnt,QPointF pnt1)
{
    Scene_Objects *object = new Scene_Objects();
    if(text && (text->getMode()==false) && objectToDraw==10)
    {
      removeItem(text->item);
       text->setMode(true);
       texts.push_back(text);
       text->setEdgeRects();
       addItem(text->item);
       addItem(text->Strt_Rect);
       addItem(text->End_Rect);
       addItem(text->Bounding_Rect);
       addItem(text->Rot_Rect);
       text->Bounding_Rect->hide();
       texts.push_back(text);
       object->setObjectPos(text->getStartPnt(),text->getEndPnt());
       object->setBoundPos(text->item->boundingRect().topLeft(),text->item->boundingRect().bottomRight());
       object->setObjects(10,texts.size()-1);
       object->ObjectIndx=texts.size()-1;
       objects.push_back(object);
       objectToDraw=0;
       objectToEdit=10;
    }

    if(text && text->getMode()==true)
    {
        if(text->getState()==1)
        {
           //object10->setObjectPos(text->getStartPnt(),text->getEndPnt());
           //object10->setBoundPos(text->item->boundingRect().topLeft(),text->item->boundingRect().bottomRight());
           //object10->pnts.push_back(QPointF(text->getHeightPnt()));
           text->setState(0);
        }

        if(text->getState()==2)
        {
            //object10->setObjectPos(text->getStartPnt(),text->getEndPnt());
            //object10->setBoundPos(text->item->boundingRect().topLeft(),text->item->boundingRect().bottomRight());
            text->setState(0);
        }

        if(text->getState()==3)
        {
            //object10->setObjectPos(text->getStartPnt(),text->getEndPnt());
            //object10->setBoundPos(text->item->boundingRect().topLeft(),text->item->boundingRect().bottomRight());
            text->setState(0);
        }

        if(text->getState()==4)
        {
            //object10->setObjectPos(text->getStartPnt(),text->getEndPnt());
            //object10->setBoundPos(text->item->boundingRect().topLeft(),text->item->boundingRect().bottomRight());
            text->setState(0);
            text->Bounding_Rect->hide();
        }
     }


}


void Graph_Scene::setObject(int object_id)
{
  objectToDraw=object_id;
  //qDebug()<<"object to draw "<<objectToDraw<<"\n";

  polygon=new Draw_Polygon();
  polygon->set_draw_mode(false);
  line = new Draw_Line();
  line->set_draw_mode(false);
  rect = new Draw_Rectangle();
  rect->setMode(false);
  round_rect = new Draw_RoundRect();
  round_rect->setMode(false);
  ellep = new Draw_Ellipse();
  ellep->setMode(false);
  arc  = new Draw_Arc();
  arc->setMode(false);
  arc->click=-1;
  if(objectToDraw==6)
    arc->click=0;
  arrow  = new Draw_Arrow();
  arrow->setMode(false);
  triangle = new Draw_Triangle();
  triangle->setMode(false);
  linearrow = new Draw_LineArrow();
  linearrow->setMode(false);
  text = new Draw_Text();
  text->setMode(false);

  if(!lines.isEmpty()) {
    for(int i=0;i<lines.size();i++)
      lines[i]->isObjectSelected=false;
  }
  if(!rects.isEmpty()) {
    for(int i=0;i<rects.size();i++)
      rects[i]->isObjectSelected=false;
  }
  if(!round_rects.isEmpty()) {
    for(int i=0;i<round_rects.size();i++)
      round_rects[i]->isObjectSelected=false;
  }
  if(!elleps.isEmpty()) {
    for(int i=0;i<elleps.size();i++)
      elleps[i]->isObjectSelected=false;
  }
  if(!polygons.isEmpty()) {
    for(int i=0;i<polygons.size();i++)
      polygons[i]->isObjectSelected=false;
  }
  if(!arcs.isEmpty()) {
    for(int i=0;i<arcs.size();i++)
      arcs[i]->isObjectSelected=false;
  }
  if(!linearrows.isEmpty()) {
    for(int i=0;i<linearrows.size();i++)
      linearrows[i]->isObjectSelected=false;
  }
  if(!triangles.isEmpty()) {
    for(int i=0;i<triangles.size();i++)
      triangles[i]->isObjectSelected=false;
  }
  if(!arrows.isEmpty()) {
    for(int i=0;i<arrows.size();i++)
      arrows[i]->isObjectSelected=false;
  }
  if(!texts.isEmpty()) {
    for(int i=0;i<texts.size();i++)
      texts[i]->isObjectSelected=false;
  }
}


int Graph_Scene::check_intersection(QPointF pnt, QPointF pnt1)
{
     for(int i=0;i<objects.size();i++)
     {
         if((pnt!=objects[i]->ObjectStrtPnt)&&(pnt1!=objects[i]->ObjectEndPnt))
         {
            if((pnt.x()>objects[i]->ObjectStrtPnt.x())&&(pnt.y()>objects[i]->ObjectStrtPnt.y())&&(pnt.x()<objects[i]->ObjectEndPnt.x())&&(pnt.y()<objects[i]->ObjectEndPnt.y())||
               (pnt1.x()>objects[i]->ObjectStrtPnt.x())&&(pnt1.y()>objects[i]->ObjectStrtPnt.y())&&(pnt1.x()<objects[i]->ObjectEndPnt.x())&&(pnt1.y()<objects[i]->ObjectEndPnt.y()))
            {
                if(objects[i]->ObjectId==1)
                {
                    objectPnt=objects[i]->ObjectStrtPnt;
                    objectPnt1=objects[i]->ObjectEndPnt;
                    return 1;
                }

                if(objects[i]->ObjectId==2)
                {
                    objectPnt=objects[i]->ObjectStrtPnt;
                    objectPnt1=objects[i]->ObjectEndPnt;
                    qDebug()<<"entered pnt Rect\n";
                    return 2;
                }

                if(objects[i]->ObjectId==3)
                {
                    objectPnt=objects[i]->ObjectStrtPnt;
                    objectPnt1=objects[i]->ObjectEndPnt;
                    return 3;
                }
           }
        }

     }
}

void Graph_Scene::hide_object_edges() {
  for(int i=0;i<objects.size();i++) {
    if(objects[i]->ObjectId==2) {
      if(rect && rect->getMode() && rect->Strt_Rect->isVisible()) {
        rect->hideHandles();
      }
    }
    if(objects[i]->ObjectId==3) {
      if(ellep && ellep->getMode() &&  ellep->Strt_Rect->isVisible()) {
        ellep->hideHandles();
      }
    }
    if(objects[i]->ObjectId==5) {
      if(round_rect && round_rect->getMode() &&  round_rect->Strt_Rect->isVisible()) {
        round_rect->hideHandles();
      }
    }
    if((objects[i]->ObjectId==7)) {
      if(linearrow && linearrow->getMode() && linearrow->Strt_Rect->isVisible()) {
        linearrow->hideHandles();
      }
    }
    if((objects[i]->ObjectId==8)) {
      if(triangle && triangle->getMode() && triangle->handles[0]->isVisible()) {
        triangle->hideHandles();
      }
    }
    if((objects[i]->ObjectId==9)) {
      if(arrow && arrow->getMode() && arrow->handles[0]->isVisible()) {
        arrow->hideHandles();
      }
    }
  }

  if(!lines.isEmpty()) {
    for(int i=0;i<lines.size();i++) {
      if(lines[i]->getPolyLineDrawn()) {
        lines[i]->hideHandles();
      }
    }
  }
  if(!polygons.isEmpty()) {
    for(int i=0;i<polygons.size();i++) {
      if(polygons[i]->getPolygonDrawn()) {
        polygons[i]->hideHandles();
      }
    }
  }
  if(!arcs.isEmpty()) {
    for(int i=0;i<arcs.size();i++) {
      arcs[i]->hideHandles();
    }
  }
  if(!texts.isEmpty()) {
    for(int i=0;i<texts.size();i++) {
      texts[i]->hideHandles();
    }
  }

  if(!temp_copy_objects.isEmpty()) {
    for(int i=0;i<temp_copy_objects.size();i++) {
      for(int j=0;j<lines.size();j++) {
        if(temp_copy_objects[i]->ObjectStrtPnt==lines[j]->getStartPnt()) {
          lines[j]->hideHandles();
        }
      }
      for(int j=0;j<rects.size();j++) {
        if(temp_copy_objects[i]->ObjectStrtPnt==rects[j]->getStartPnt()) {
          rects[j]->hideHandles();
        }
      }
      for(int j=0;j<texts.size();j++) {
        if(temp_copy_objects[i]->ObjectStrtPnt==texts[j]->getStartPnt()) {
          texts[j]->hideHandles();
        }
      }
      for(int j=0;j<round_rects.size();j++) {
        if(temp_copy_objects[i]->ObjectStrtPnt==round_rects[j]->getStartPnt()) {
          round_rects[j]->hideHandles();
        }
      }
      for(int j=0;j<elleps.size();j++) {
        if(temp_copy_objects[i]->ObjectStrtPnt==elleps[j]->getStartPnt()) {
          elleps[j]->hideHandles();
        }
      }
    }
  }

  if(!copy_objects.isEmpty()) {
    for(int i=0;i<copy_objects.size();i++) {
      for(int j=0;j<lines.size();j++) {
        if(temp_copy_objects[i]->ObjectStrtPnt==lines[j]->getStartPnt()) {
          lines[j]->hideHandles();
        }
      }
      for(int j=0;j<rects.size();j++) {
        if(copy_objects[i]->ObjectStrtPnt==rects[j]->getStartPnt()) {
          rects[j]->hideHandles();
        }
      }
      for(int j=0;j<texts.size();j++) {
        if(copy_objects[i]->ObjectStrtPnt==texts[j]->getStartPnt()) {
          texts[j]->hideHandles();
        }
      }
      for(int j=0;j<round_rects.size();j++) {
        if(copy_objects[i]->ObjectStrtPnt==round_rects[j]->getStartPnt()) {
          round_rects[j]->hideHandles();
        }
      }
      for(int j=0;j<polygons.size();j++) {
        if(temp_copy_objects[i]->ObjectStrtPnt==polygons[j]->getStartPnt()) {
          polygons[j]->hideHandles();
        }
      }
      for(int j=0;j<elleps.size();j++) {
        if(copy_objects[i]->ObjectStrtPnt==elleps[j]->getStartPnt()) {
          elleps[j]->hideHandles();
        }
      }
    }
  }
}

void Graph_Scene::new_Scene()
{
    if(objects.size()!=0)
    {
    objects.clear();
    copy_objects.clear();
    if(!arcs.isEmpty())
            arcs.clear();
    if(arc!=NULL)
    {
      delete arc;
      arc=NULL;
      objectToEdit=0;
    }

    if(!arrows.isEmpty())
      arrows.clear();
    if(arrow)
    {
      delete arrow;
      arrow=NULL;
      objectToEdit=0;
    }

    if(!lines.isEmpty())
            lines.clear();
    if(line)
    {
      delete line;
      line=NULL;
      objectToEdit=0;
    }
    if(!linearrows.isEmpty())
            linearrows.clear();
    if(linearrow)
    {
      delete linearrow;
      linearrow=NULL;
      objectToEdit=0;
    }
    if(!rects.isEmpty())
            rects.clear();
    if(rect)
    {
      delete rect;
      rect=NULL;
      objectToEdit=0;

    }
    if(!elleps.isEmpty())
            elleps.clear();
    if(ellep)
    {
      delete ellep;
      ellep=NULL;
      objectToEdit=0;
    }
    if(!round_rects.isEmpty())
            round_rects.clear();
    if(round_rect)
    {
      //if(round_rect->Strt_Rect->isVisible())
        //round_rect->hideHandles();
      delete round_rect;
      round_rect=NULL;
      objectToEdit=0;
    }
    if(!polygons.isEmpty())
            polygons.clear();
    if(polygon)
    {
      delete polygon;
      polygon=NULL;
      objectToEdit=0;
    }
    if(!triangles.isEmpty())
      triangles.clear();
    if(triangle)
    {
      delete triangle;
      triangle=NULL;
      objectToEdit=0;
    }
    //if(!texts.isEmpty())
      //texts.clear();
    clear();

    /*if(text)
    {
      delete text;
      text=NULL;
      objectToEdit=0;
    }*/
    }

}


void Graph_Scene::save_Scene(QString file_name) {
  files.writeXml(objects,file_name);
}

void Graph_Scene::save_xml_Scene(QString file_name)
{
    QStringList strlist;
    QFile fd(file_name);//It is a datafile from which we are taking the data
    fd.open(QFile::WriteOnly);//checks whther the file is open r not
    QTextStream outputStream(&fd);//reads the data as streams i.e in bytes

    outputStream<<"<?xml version='1.0'?>"<<"\n";
    outputStream<<"<Object>"<<"\n";

    for(int i=0;i<objects.size();i++)
    {
        if(objects[i]->ObjectId==1)
        {
           outputStream<<"<Type>"<<"Line"<<"</Type>"<<"\n";
           outputStream<<"<Dim>"<<objects[i]->ObjectStrtPnt.x()<<" "<<objects[i]->ObjectStrtPnt.y()<<" "<<objects[i]->ObjectEndPnt.x()<<" "<<objects[i]->ObjectEndPnt.y()<<"</Dim>"<<"\n";
        }

        if(objects[i]->ObjectId==2)
        {
           outputStream<<"<Type>"<<"Rectangle"<<"</Type>"<<"\n";
           outputStream<<"<Dim>"<<objects[i]->ObjectStrtPnt.x()<<" "<<objects[i]->ObjectStrtPnt.y()<<" "<<objects[i]->ObjectEndPnt.x()<<" "<<objects[i]->ObjectEndPnt.y()<<"</Dim>"<<"\n";
        }

        if(objects[i]->ObjectId==3)
        {
           outputStream<<"<Type>"<<"Ellipse"<<"</Type>"<<"\n";
           outputStream<<"<Dim>"<<objects[i]->ObjectStrtPnt.x()<<" "<<objects[i]->ObjectStrtPnt.y()<<" "<<objects[i]->ObjectEndPnt.x()<<" "<<objects[i]->ObjectEndPnt.y()<<"</Dim>"<<"\n";
        }

        if(objects[i]->ObjectId==5)
        {
           outputStream<<"<Type>"<<"Round Rectangle"<<"</Type>"<<"\n";
           outputStream<<"<Dim>"<<objects[i]->ObjectStrtPnt.x()<<" "<<objects[i]->ObjectStrtPnt.y()<<" "<<objects[i]->ObjectEndPnt.x()<<" "<<objects[i]->ObjectEndPnt.y()<<"</Dim>"<<"\n";
        }

    }

    outputStream<<"</Object>"<<"\n";
}

void Graph_Scene::save_image_Scene()
{
    QPainterPath paint_round_rect;
    QPen pen;

    hide_object_edges();

}

void Graph_Scene::open_Scene(QString file_name)
{
     lines.clear();
     rects.clear();
     elleps.clear();
     objects.clear();
     round_rects.clear();


    files.readXml(objects,file_name);


        for(int i=0;i<objects.size();i++)
        {
           Draw_Line* line2= new Draw_Line;
           Draw_Rectangle *rect2 = new Draw_Rectangle();
           Draw_Ellipse *ellep2 = new Draw_Ellipse;
           Draw_RoundRect *roundrect2 = new Draw_RoundRect;

                if(objects[i]->ObjectId==1)
                {
                   line2->setStartPoint(objects[i]->ObjectStrtPnt);
                   line2->setEndPoint(objects[i]->ObjectEndPnt);
                   line2->setState(0);
                   line2->set_draw_mode(true);
                   line=line2;
                   lines.push_back(line2);

                   objectToEdit=1;


                }

                if(objects[i]->ObjectId==2)
                {
                   rect2->setStartPoint(objects[i]->ObjectStrtPnt);
                   rect2->setEndPoint(objects[i]->ObjectEndPnt);
                   rect2->setState(0);
                   rect2->setMode(true);
                   rect=rect2;
                   rects.push_back(rect2);

                   objectToEdit=2;


                }

                if(objects[i]->ObjectId==3)
                {
                   ellep2->setStartPoint(objects[i]->ObjectStrtPnt);
                   ellep2->setEndPoint(objects[i]->ObjectEndPnt);
                   ellep2->setState(0);
                   ellep2->setMode(true);
                   ellep=ellep2;
                   elleps.push_back(ellep2);

                   objectToEdit=3;


                }

                if(objects[i]->ObjectId==5)
                {
                   roundrect2->setStartPoint(objects[i]->ObjectStrtPnt);
                   roundrect2->setEndPoint(objects[i]->ObjectEndPnt);
                   roundrect2->setState(0);
                   roundrect2->setMode(true);
                   round_rect=roundrect2;
                   round_rects.push_back(roundrect2);

                   objectToEdit=5;

                }

        }
}

void Graph_Scene::open_Scene(const QVector<int> &values,QVector<float> &value)
{
     arcs.clear();
   arrows.clear();
     lines.clear();
   linearrows.clear();
     rects.clear();
     elleps.clear();
     objects.clear();
     round_rects.clear();
     polygons.clear();
   triangles.clear();
   //texts.clear();

  //arrow = new Draw_Arrow();
  //arrow->setMode(0);

    for(int i=0,rotValue=0;i<values.size(); )
    {
        if(values[i]!=4 && values[i+1]==4)
        {
           Scene_Objects* object = new Scene_Objects();
           qDebug()<<"entered "<<"\n";
           object->ObjectId=values[i];
           object->ObjectStrtPnt.setX(values[i+2]);
           object->ObjectStrtPnt.setY(values[i+3]);
           object->ObjectEndPnt.setX(values[i+4]);
           object->ObjectEndPnt.setY(values[i+5]);
           object->setPenColor(values[i+6],values[i+7],values[i+8]);
           object->setPenStyle(values[i+9]);
           object->setPenWidth(values[i+10]);
           object->setBrushColor(values[i+11],values[i+12],values[i+13]);
           object->setBrushStyle(values[i+14]);
       object->rotation=value[rotValue];
           objects.push_back(object);
       i+=15;
       rotValue++;
        }

        if(i==values.size())
        {
            break;
        }


    if(values[i]==1)
        {
           qDebug()<<"value of i "<<i<<"\n";
           Scene_Objects* object = new Scene_Objects();
           object->ObjectId=values[i];
           int j;
           if(i==0)
           {
              j=values[i+1];
           }
           if(i!=0)
           {
              j=values[i+1];
              j=j+i;
           }

           for(i=i+2;i<j+2;i+=2)
           {
               QPointF pnt(values[i],values[i+1]);
               object->pnts.push_back(pnt);
           }
           j=i;
           qDebug()<<"value of j and rotValue"<<j<<" "<<value[rotValue]<<"\n";
       object->setPenColor(values[j],values[j+1],values[j+2]);
           object->setPenStyle(values[j+3]);
           object->setPenWidth(values[j+4]);
           object->rotation=value[rotValue];
           objects.push_back(object);
           i=j+5;
       rotValue++;

        }

    if(i==values.size())
        {
            break;
        }

        if(values[i]==4)
        {
           qDebug()<<"value of i "<<i<<"\n";
           Scene_Objects* object = new Scene_Objects();
           object->ObjectId=values[i];
           int j;
           if(i==0)
           {
              j=values[i+1];
           }
           if(i!=0)
           {
              j=values[i+1];
              j=j+i;
           }

           for(i=i+2;i<j+2;i+=2)
           {
               QPointF pnt(values[i],values[i+1]);
               object->pnts.push_back(pnt);
           }
           j=i;
           qDebug()<<"value of j and rotValue"<<j<<" "<<value[rotValue]<<"\n";
       object->setPenColor(values[j],values[j+1],values[j+2]);
           object->setPenStyle(values[j+3]);
           object->setPenWidth(values[j+4]);
           object->setBrushColor(values[j+5],values[j+6],values[j+7]);
           object->setBrushStyle(values[j+8]);
       object->rotation=value[rotValue];
           objects.push_back(object);
           i=j+9;
       rotValue++;

        }

    if(i==values.size())
        {
            break;
        }

        if(values[i]==6 && values[i+1]==6)
        {
           Scene_Objects* object = new Scene_Objects();
           qDebug()<<"entered "<<"\n";
           object->ObjectId=values[i];
           object->ObjectStrtPnt.setX(values[i+2]);
           object->ObjectStrtPnt.setY(values[i+3]);
           object->ObjectEndPnt.setX(values[i+4]);
           object->ObjectEndPnt.setY(values[i+5]);
           QPointF pnt;
           pnt.setX(values[i+6]);
           pnt.setY(values[i+7]);
           object->pnts.push_back(pnt);
           object->setPenColor(values[i+8],values[i+9],values[i+10]);
           object->setPenStyle(values[i+11]);
           object->setPenWidth(values[i+12]);
           object->rotation=values[rotValue];
           objects.push_back(object);

           i+=13;
       rotValue++;
        }

    if(i==values.size())
        {
            break;
        }

    if(values[i]==7)
        {
       Scene_Objects* object = new Scene_Objects();
           qDebug()<<"entered "<<"\n";
           object->ObjectId=values[i];
           int j;
           if(i==0)
           {
              j=values[i+1];
           }
           if(i!=0)
           {
              j=values[i+1];
              j=j+i;
           }

           for(i=i+2;i<j+2;i+=2)
           {
               QPointF pnt(values[i],values[i+1]);
               object->pnts.push_back(pnt);
           }
           j=i;
           qDebug()<<"value of j and rotValue"<<j<<" "<<value[rotValue]<<"\n";
       object->setPenColor(values[j],values[j+1],values[j+2]);
           object->setPenStyle(values[j+3]);
           object->setPenWidth(values[j+4]);
           object->rotation=value[rotValue];
           objects.push_back(object);
           i=j+5;
       rotValue++;

        }

    if(i==values.size())
        {
            break;
        }

    if(values[i]==8 && values[i+1]==8)
        {
           Scene_Objects* object = new Scene_Objects();
           qDebug()<<"entered "<<"\n";
           object->ObjectId=values[i];
           object->ObjectStrtPnt.setX(values[i+2]);
           object->ObjectStrtPnt.setY(values[i+3]);
           object->ObjectEndPnt.setX(values[i+4]);
           object->ObjectEndPnt.setY(values[i+5]);
           QPointF pnt;
           pnt.setX(values[i+6]);
           pnt.setY(values[i+7]);
           object->pnts.push_back(pnt);
           object->setPenColor(values[i+8],values[i+9],values[i+10]);
           object->setPenStyle(values[i+11]);
           object->setPenWidth(values[i+12]);
           object->setBrushColor(values[i+13],values[i+14],values[i+15]);
           object->setBrushStyle(values[i+16]);
       object->rotation=value[rotValue];
           objects.push_back(object);

           i+=17;
       rotValue++;
        }

    if(i==values.size())
        {
            break;
        }

    if(values[i]==9)
        {
           Scene_Objects* object = new Scene_Objects();
           //qDebug()<<"entered "<<"\n";
           object->ObjectId=values[i];
       int j;
           if(i==0)
           {
              j=values[i+1];
           }
           if(i!=0)
           {
              j=values[i+1];
              j=j+i;
           }

           for(i=i+2;i<j+2;i+=2)
           {
               QPointF pnt(values[i],values[i+1]);
               object->pnts.push_back(pnt);
           }
           j=i;
           //qDebug()<<"value of j and rotValue"<<j<<" "<<value[rotValue]<<"\n";
       object->setPenColor(values[j],values[j+1],values[j+2]);
           object->setPenStyle(values[j+3]);
           object->setPenWidth(values[j+4]);
           object->setBrushColor(values[j+5],values[j+6],values[j+7]);
           object->setBrushStyle(values[j+8]);
       object->rotation=value[rotValue];
           objects.push_back(object);
           i=j+9;
       rotValue++;
        }

    if(i==values.size())
        {
            break;
        }

    }


        for(int i=0;i<objects.size();i++)
        {
            Draw_Arc* arc2 = new Draw_Arc();
            Draw_Line* line2= new Draw_Line();
      Draw_LineArrow* linearrow2= new Draw_LineArrow();
            Draw_Rectangle *rect2 = new Draw_Rectangle();
            Draw_Ellipse *ellep2 = new Draw_Ellipse();
            Draw_RoundRect *roundrect2 = new Draw_RoundRect();
            Draw_Polygon *polygon2 = new Draw_Polygon();
      Draw_Triangle *triangle2 = new Draw_Triangle();
      Draw_Arrow *arrow2 = new Draw_Arrow();

            if(objects[i]->ObjectId==1)
            {
         line2->poly_pnts=objects[i]->pnts;
                 line=line2;

                 lines.push_back(line2);

                 objects[i]->ObjectIndx=lines.size()-1;


                 line->item = new QGraphicsPathItem(line->getPolyLine());
                 line->setPen(objects[i]->getpen().color());
                 line->setPenStyle(objects[i]->getpen().style());
                 line->setPenWidth(objects[i]->getpen().width());
                 addItem(line->item);

                 if(!line->edge_items.isEmpty())
                 {
                     for(int i=0;i<line->edge_items.size();i++)
                     {
                          addItem(line->edge_items[i]);
                     }
         }

         addItem(line->Rot_Rect);

         line->hideHandles();
         objectToEdit=1;
                 line->setPolyLineDrawn(true);
                 linemode=true;
                 line->lines.clear();
                 //lines.push_back(line2);

                 QRectF poly_rect=line->item->boundingRect();
                 objects[i]->ObjectStrtPnt=poly_rect.topLeft();
                 objects[i]->ObjectEndPnt=poly_rect.bottomRight();

             }

              if(objects[i]->ObjectId==2)
              {
          rect2->setStartPoint(objects[i]->ObjectStrtPnt);
                  rect2->setEndPoint(objects[i]->ObjectEndPnt);
                  rect2->setState(0);
                  rect2->setMode(true);
                  rect=rect2;
                  rects.push_back(rect2);
                  objectToEdit=2;

          objects[i]->ObjectIndx=rects.size()-1;

                  rect->item = new QGraphicsPathItem(rect->getRect(rect->getStartPnt(),rect->getEndPnt()));
                  rect->setPen(objects[i]->getpen().color());
                  rect->setPenStyle(objects[i]->getpen().style());
                  rect->setPenWidth(objects[i]->getpen().width());
                  rect->setBrush(objects[i]->getbrush());
                  rect->setBrushStyle(objects[i]->getbrush().style());
          qDebug()<<"object rotation "<<objects[i]->rotation<<"\n";
          if(objects[i]->rotation!=0)
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
            rect->item->setRotation(rect->item->rotation() + objects[i]->rotation);
#else
            rect->item->rotate(objects[i]->rotation);
#endif
                  addItem(rect->item);
                  rect->setEdgeRects();
                  addItem(rect->Strt_Rect);
                  addItem(rect->End_Rect);
                  addItem(rect->Rot_Rect);
          rect->hideHandles();


                }

                if(objects[i]->ObjectId==3)
                {
                   ellep2->setStartPoint(objects[i]->ObjectStrtPnt);
                   ellep2->setEndPoint(objects[i]->ObjectEndPnt);
                   ellep2->setState(0);
                   ellep2->setMode(true);
                   ellep=ellep2;
                   elleps.push_back(ellep2);

                   objectToEdit=3;


                   objects[i]->ObjectIndx=elleps.size()-1;

                   ellep->item = new QGraphicsPathItem(ellep->getEllep(ellep->getStartPnt(),ellep->getEndPnt()));
                   ellep->setPen(objects[i]->getpen().color());
                   ellep->setPenStyle(objects[i]->getpen().style());
                   ellep->setPenWidth(objects[i]->getpen().width());
                   ellep->setBrush(objects[i]->getbrush());
                   ellep->setBrushStyle(objects[i]->getbrush().style());
                   addItem(ellep->item);
                   ellep->setEdgeRects();
                   addItem(ellep->Strt_Rect);
                   addItem(ellep->End_Rect);
                   addItem(ellep->Rot_Rect);
           ellep->hideHandles();

                }


                if(objects[i]->ObjectId==4)
                {
          polygon2->poly_pnts=objects[i]->pnts;
                    polygon=polygon2;

                    polygons.push_back(polygon2);

                    objects[i]->ObjectIndx=polygons.size()-1;


                    polygon->item = new QGraphicsPathItem(polygon->getPolygon());
                    polygon->setPen(objects[i]->getpen().color());
                    polygon->setPenStyle(objects[i]->getpen().style());
                    polygon->setPenWidth(objects[i]->getpen().width());
                    polygon->setBrush(objects[i]->getbrush());
                    polygon->setBrushStyle(objects[i]->getbrush().style());
                    addItem(polygon->item);

                    if(!polygon->edge_items.isEmpty())
                    {
                        for(int i=0;i<polygon->edge_items.size();i++)
                        {
                            addItem(polygon->edge_items[i]);

                        }
                    }
          addItem(polygon->Rot_Rect);

          polygon->hideHandles();
          objectToEdit=4;
                    polygon->setPolygonDrawn(true);
                    mode=true;
                    polygon->lines.clear();
                    polygons.push_back(polygon2);

                    QRectF poly_rect=polygon->item->boundingRect();
                    objects[i]->ObjectStrtPnt=poly_rect.topLeft();
                    objects[i]->ObjectEndPnt=poly_rect.bottomRight();

                }


                if(objects[i]->ObjectId==5)
                {
                   roundrect2->setStartPoint(objects[i]->ObjectStrtPnt);
                   roundrect2->setEndPoint(objects[i]->ObjectEndPnt);
                   roundrect2->setState(0);
                   roundrect2->setMode(true);
                   round_rect=roundrect2;
                   round_rects.push_back(roundrect2);

                   objects[i]->ObjectIndx=round_rects.size()-1;

                   objectToEdit=5;

                   round_rect->item = new QGraphicsPathItem(round_rect->getRoundRect(round_rect->getStartPnt(),round_rect->getEndPnt()));
                   round_rect->setPen(objects[i]->getpen().color());
                   round_rect->setPenStyle(objects[i]->getpen().style());
                   round_rect->setPenWidth(objects[i]->getpen().width());
                   round_rect->setBrush(objects[i]->getbrush());
                   round_rect->setBrushStyle(objects[i]->getbrush().style());
                   addItem(round_rect->item);
                   round_rect->setEdgeRects();
                   addItem(round_rect->Strt_Rect);
                   addItem(round_rect->End_Rect);
                   addItem(round_rect->Rot_Rect);
           round_rect->hideHandles();

               }

                if(objects[i]->ObjectId==6)
                {
                    arc2->setStartPoint(objects[i]->ObjectStrtPnt);
                    arc2->setEndPoint(objects[i]->ObjectEndPnt);
                    arc2->setCurvePoint(objects[i]->pnts[0]);
                    arc2->setState(0);
                    arc2->setMode(true);
                    arc=arc2;
                    arcs.push_back(arc2);
                    objectToEdit=6;

          qDebug()<<"curve pnts  in open"<<arc2->getStartPnt()<<"  "<<arc2->getEndPnt()<<"  "<<arc2->getCurvePnt()<<"\n";

          objects[i]->ObjectIndx=arcs.size()-1;

                    arc->item = new QGraphicsPathItem(arc2->getArc());
                    arc->setPen(objects[i]->getpen().color());
                    arc->setPenStyle(objects[i]->getpen().style());
                    arc->setPenWidth(objects[i]->getpen().width());
                    addItem(arc->item);
                    arc->setEdgeRects();
                    addItem(arc->Strt_Rect);
                    addItem(arc->End_Rect);
                    addItem(arc->Curve_Rect);
          arc->hideHandles();
                    objects[i]->setBoundPos(arc->item->boundingRect().topLeft(),arc->item->boundingRect().bottomRight());

                    //rect->Rot_Rect= new QGraphicsRectItem(QRectF((rect->getStartPnt().x()+rect->getEndPnt().x())/2,rect->getStartPnt().y()-10,5.0,5.0));
                    //addItem(rect->Rot_Rect);
                    //rect->Rot_Rect->hide();


                  }

          if(objects[i]->ObjectId==7)
                  {
                    linearrow2->setStartPoint(objects[i]->ObjectStrtPnt);
                    linearrow2->setEndPoint(objects[i]->ObjectEndPnt);
          linearrow2->arrow_pnts=objects[i]->pnts;
                    linearrow2->setState(0);
                    linearrow2->setMode(true);
                    linearrow=linearrow2;
                    linearrows.push_back(linearrow2);
                    objectToEdit=7;

          objects[i]->ObjectIndx=linearrows.size()-1;

          linearrow->item = new QGraphicsPathItem(linearrow2->getLineArrow(linearrow2->getStartPnt()));
                    linearrow->setPen(objects[i]->getpen().color());
                    linearrow->setPenStyle(objects[i]->getpen().style());
                    linearrow->setPenWidth(objects[i]->getpen().width());
                    addItem(linearrow->item);
                    linearrow->setEdgeRects();
                    addItem(linearrow->Strt_Rect);
                    addItem(linearrow->End_Rect);
                    addItem(linearrow->Rot_Rect);
          linearrow->hideHandles();
                    objects[i]->setBoundPos(linearrow->item->boundingRect().topLeft(),linearrow->item->boundingRect().bottomRight());


                  }

         if(objects[i]->ObjectId==8)
                 {
                    triangle2->setStartPoint(objects[i]->ObjectStrtPnt);
                    triangle2->setEndPoint(objects[i]->ObjectEndPnt);
                    triangle2->setHeightPoint(objects[i]->pnts[0]);
                    triangle2->setState(0);
                    triangle2->setMode(true);
                    triangle=triangle2;
                    triangles.push_back(triangle2);
                    objectToEdit=8;

                    objects[i]->ObjectIndx=arcs.size()-1;

                    triangle->item = new QGraphicsPathItem(triangle2->getTriangle());
                    triangle->setPen(objects[i]->getpen().color());
                    triangle->setPenStyle(objects[i]->getpen().style());
                    triangle->setPenWidth(objects[i]->getpen().width());
                    addItem(triangle->item);
                    triangle->setEdgeRects();
                    addItem(triangle->Strt_Rect);
                    addItem(triangle->End_Rect);
          addItem(triangle->Height_Rect);
          addItem(triangle->Rot_Rect);
          triangle->hideHandles();
                    objects[i]->setBoundPos(triangle->item->boundingRect().topLeft(),triangle->item->boundingRect().bottomRight());


                  }

         if(objects[i]->ObjectId==9)
                 {
                    QPointF pnt(objects[i]->pnts[0].x(),objects[i]->pnts[0].y()-25);
                    arrow->setStartPoint(pnt);
          pnt=QPointF(objects[i]->pnts[3].x(),objects[i]->pnts[4].y());
          arrow->arrow_pnts=objects[i]->pnts;
          arrow->setEndPoint(pnt);
          qDebug()<<"values "<<arrow->getStartPnt()<<" "<<arrow->arrow_pnts[0]<<"\n";
          arrow->setState(0);
                    objectToEdit=9;

          arrow->item = new QGraphicsPathItem(arrow->drawArrow());
                    arrow->setPen(objects[i]->getpen().color());
                    arrow->setPenStyle(objects[i]->getpen().style());
                    arrow->setPenWidth(objects[i]->getpen().width());
                    addItem(arrow->item);
                    arrow->setEdgeRects();
                    addItem(arrow->Strt_Rect);
                    addItem(arrow->End_Rect);
          addItem(arrow->Rot_Rect);
          arrow->hideHandles();
          arrow->setMode(true);
          arrows.push_back(arrow);
          objects[i]->ObjectIndx=arrows.size()-1;
                    objects[i]->setBoundPos(arrow->item->boundingRect().topLeft(),arrow->item->boundingRect().bottomRight());
                  }

        }



}


//copy objects
void Graph_Scene::copy_object() {
    selectedObjects();

    isCopySelected=true;

    temp_copy_objects.clear();
    temp_copy_objects.reserve(copy_objects.size());
    for(int i=0;i<copy_objects.size();i++)
    {
        Scene_Objects *temp_object = new Scene_Objects();
        temp_object=copy_objects[i];
        temp_object->ObjectId=copy_objects[i]->ObjectId;
        temp_copy_objects.insert(i,temp_object);
    }
    copy_objects.clear();
    //qDebug()<<"value of temp_objects "<<temp_copy_objects.size()<<"\n";

   /* for(int i=0;i<temp_copy_objects.size();i++)
        temp_copy_objects[i]->print();*/
}


//cut objects
void Graph_Scene::cut_object() {
  QVector<int> indxs;
  indxs.clear();

  selectedObjects();
  if(isCopySelected)
     isCopySelected=false;
  temp_copy_objects.clear();
  temp_copy_objects.reserve(copy_objects.size());
  for(int i=0;i<copy_objects.size();i++) {
    Scene_Objects *object = copy_objects[i]->clone();
    temp_copy_objects.push_back(object);
  }
  copy_objects.clear();

  if(!temp_copy_objects.isEmpty()) {
    QVector<Draw_Arc*> arcs1;
    QVector<Draw_Line*> lines1;
    QVector<Draw_Rectangle*> rects1;
    QVector<Draw_RoundRect*> round_rects1;
    QVector<Draw_Ellipse*> elleps1;
    QVector<Draw_Polygon*> polys1;

    arcs1=arcs;
    lines1=lines;
    rects1=rects;
    round_rects1=round_rects;
    polys1=polygons;

    for(int i=0;i<temp_copy_objects.size();i++) {
      if(temp_copy_objects[i]->ObjectId==1) {
        for(int j=0;j<lines1.size();j++) {
          if(lines1[j]->item->boundingRect().topLeft()==temp_copy_objects[i]->ObjectStrtPnt) {
            removeItem(lines[j]->item);
            for(int k=0;k<lines[j]->edge_items.size();k++) {
              removeItem(lines[j]->edge_items[k]);
            }
          }
        }
      }
      if(temp_copy_objects[i]->ObjectId==2) {
        for(int j=0;j<rects.size();j++) {
          if(rects[j]->getStartPnt()==temp_copy_objects[i]->ObjectStrtPnt) {
            removeItem(rects[j]->item);
            removeItem(rects[j]->Strt_Rect);
            removeItem(rects[j]->End_Rect);
            removeItem(rects[j]->Rot_Rect);
          }
        }
      }
      if(temp_copy_objects[i]->ObjectId==3) {
        for(int j=0;j<elleps.size();j++) {
          if(temp_copy_objects[i]->ObjectStrtPnt==elleps[j]->getStartPnt()) {
            removeItem(elleps[j]->item);
            removeItem(elleps[j]->Strt_Rect);
            removeItem(elleps[j]->End_Rect);
            removeItem(elleps[j]->Rot_Rect);
          }
        }
      }
      if(temp_copy_objects[i]->ObjectId==4) {
        for(int j=0;j<polys1.size();j++) {
          if(polys1[j]->item->boundingRect().topLeft()==temp_copy_objects[i]->ObjectStrtPnt) {
            removeItem(polygons[j]->item);
            for(int k=0;k<polygons[j]->edge_items.size();k++) {
              removeItem(polygons[j]->edge_items[k]);
            }
          }
        }
      }
      if(temp_copy_objects[i]->ObjectId==5) {
        for(int j=0;j<round_rects1.size();j++) {
          if(round_rects1[j]->getStartPnt()==temp_copy_objects[i]->ObjectStrtPnt) {
            removeItem(round_rects[j]->item);
            removeItem(round_rects[j]->Strt_Rect);
            removeItem(round_rects[j]->End_Rect);
            removeItem(round_rects[j]->Rot_Rect);
          }
        }
      }
      if(temp_copy_objects[i]->ObjectId==6) {
        for(int j=0;j<arcs1.size();j++) {
          if(arcs1[j]->getStartPnt()==temp_copy_objects[i]->ObjectStrtPnt) {
            removeItem(arcs[j]->item);
            removeItem(arcs[j]->Strt_Rect);
            removeItem(arcs[j]->End_Rect);
            removeItem(arcs[j]->Rot_Rect);
            removeItem(arcs[j]->Curve_Rect);
          }
        }
      }
      if(temp_copy_objects[i]->ObjectId==7) {
        for(int j=0;j<linearrows.size();j++) {
          if(linearrows[j]->getStartPnt()==temp_copy_objects[i]->ObjectStrtPnt) {
            removeItem(linearrows[j]->item);
            removeItem(linearrows[j]->Strt_Rect);
            removeItem(linearrows[j]->End_Rect);
            removeItem(linearrows[j]->Rot_Rect);
          }
        }
      }
      if(temp_copy_objects[i]->ObjectId==8) {
        for(int j=0;j<triangles.size();j++) {
          if(triangles[j]->getStartPnt()==temp_copy_objects[i]->ObjectStrtPnt) {
            removeItem(triangles[j]->item);
            removeItem(triangles[j]->Strt_Rect);
            removeItem(triangles[j]->End_Rect);
            removeItem(triangles[j]->Height_Rect);
            removeItem(triangles[j]->Rot_Rect);
          }
        }
      }
      if(temp_copy_objects[i]->ObjectId==9) {
        for(int j=0;j<arrows.size();j++) {
          if(arrows[j]->getStartPnt()==temp_copy_objects[i]->ObjectStrtPnt) {
            removeItem(arrows[j]->item);
            removeItem(arrows[j]->Strt_Rect);
            removeItem(arrows[j]->End_Rect);
            removeItem(arrows[j]->Rot_Rect);
          }
        }
      }
    }
  }

  for(int i=0;i<temp_copy_objects.size();i++) {
    for(int j=0;j<objects.size();j++) {
      if(temp_copy_objects[i]->ObjectStrtPnt==objects[j]->ObjectStrtPnt) {
        objects.remove(j);
      }
    }
  }
  for(int i=temp_copy_objects.size()-1;i>=0;i--) {
    if(temp_copy_objects[i]->ObjectId==1) {
      lines.remove(temp_copy_objects[i]->ObjectIndx);
    }
    if(temp_copy_objects[i]->ObjectId==2) {
      rects.remove(temp_copy_objects[i]->ObjectIndx);
    }
    if(temp_copy_objects[i]->ObjectId==3) {
      elleps.remove(temp_copy_objects[i]->ObjectIndx);
    }
    if(temp_copy_objects[i]->ObjectId==4) {
      polygons.remove(temp_copy_objects[i]->ObjectIndx);
    }
    if(temp_copy_objects[i]->ObjectId==5) {
      round_rects.remove(temp_copy_objects[i]->ObjectIndx);
    }
    if(temp_copy_objects[i]->ObjectId==6) {
      arcs.remove(temp_copy_objects[i]->ObjectIndx);
    }
    if(temp_copy_objects[i]->ObjectId==7) {
      linearrows.remove(temp_copy_objects[i]->ObjectIndx);
    }
    if(temp_copy_objects[i]->ObjectId==7) {
      linearrows.remove(temp_copy_objects[i]->ObjectIndx);
    }
    if(temp_copy_objects[i]->ObjectId==8) {
      triangles.remove(temp_copy_objects[i]->ObjectIndx);
    }
    if(temp_copy_objects[i]->ObjectId==9) {
      arrows.remove(temp_copy_objects[i]->ObjectIndx);
    }
  }
}

//paste objects
void Graph_Scene::paste_object() {
  paste_selected_objects.clear();

  //qDebug()<<"entered paste size "<<temp_copy_objects.size()<<"\n";
  if((!temp_copy_objects.isEmpty())) {
    hide_object_edges();
    for(int i=0;i<temp_copy_objects.size();i++) {
      Scene_Objects *object =  new Scene_Objects();

      if(temp_copy_objects[i]->ObjectId==1) {
        Draw_Line *line2 = new Draw_Line();

        line2->poly_pnts=temp_copy_objects[i]->pnts;
        lines.push_back(line2);
        line2->item = new QGraphicsPathItem(line2->getPolyLine());
        line2->setPen(objects[i]->getpen().color());
        line2->setPenStyle(objects[i]->getpen().style());
        line2->setPenWidth(objects[i]->getpen().width());
        addItem(line2->item);

        if(!line2->edge_items.isEmpty()) {
          for(int i=0;i<line2->edge_items.size();i++) {
            addItem(line2->edge_items[i]);
          }
        }

        addItem(line2->Rot_Rect);
        if(temp_copy_objects[i]->rotation!=0) {
          line2->rotateShape(temp_copy_objects[i]->rotation);
        }

        line2->hideHandles();
        objectToEdit=1;
        line2->setPolyLineDrawn(true);
        linemode=true;
        line2->lines.clear();
        lines.push_back(line2);

        QRectF poly_line=line2->item->boundingRect();
        object->ObjectStrtPnt=poly_line.topLeft();
        object->ObjectEndPnt=poly_line.bottomRight();
        object->pnts=line2->poly_pnts;
        object->setObjects(1,lines.size()-1);
        object->ObjectIndx=lines.size()-1;
        objects.push_back(object);
        objectToDraw=0;
        objectToEdit=1;
        paste_selected_objects.push_back(object);
      }

      if(temp_copy_objects[i]->ObjectId==2) {
        Draw_Rectangle *rect2 = new Draw_Rectangle();

        rect2->setStartPoint(temp_copy_objects[i]->ObjectStrtPnt);
        rect2->setEndPoint(temp_copy_objects[i]->ObjectEndPnt);
        rect2->setState(0);
        rect2->setMode(true);

        rect2->item =  new QGraphicsPathItem(rect2->getRect(temp_copy_objects[i]->ObjectStrtPnt,temp_copy_objects[i]->ObjectEndPnt));
        if(isCopySelected) {
          rect2->setTranslate(QPointF(5,5),QPointF(20,20));
          rect2->item->setPath(rect2->getRect(rect2->getStartPnt(),rect2->getEndPnt()));
        }
        rect2->setPen(temp_copy_objects[i]->getpen().color());
        rect2->setPenStyle(temp_copy_objects[i]->getpen().style());
        rect2->setPenWidth(temp_copy_objects[i]->getpen().width());
        rect2->setBrush(temp_copy_objects[i]->getbrush());
        rect2->setBrushStyle(temp_copy_objects[i]->getbrush().style());
        addItem(rect2->item);
        rect2->setEdgeRects();
        addItem(rect2->Strt_Rect);
        addItem(rect2->End_Rect);
        addItem(rect2->Rot_Rect);

        if(temp_copy_objects[i]->rotation!=0)
        rect2->rotateShape(temp_copy_objects[i]->rotation);

        rect2->Rot_Rect->hide();
        rects.push_back(rect2);

        object->ObjectId=2;
        object->setObjectPos(rect2->getStartPnt(),rect2->getEndPnt());
        object->setpen(rect2->getPen());
        object->setbrush(rect2->getBrush());
        object->setObjects(2,rects.size()-1);
        object->ObjectIndx=rects.size()-1;
        objects.push_back(object);
        paste_selected_objects.push_back(object);
      }

      if(temp_copy_objects[i]->ObjectId==3) {
        Draw_Ellipse *ellep2 = new Draw_Ellipse();

        ellep2->setStartPoint(temp_copy_objects[i]->ObjectStrtPnt);
        ellep2->setEndPoint(temp_copy_objects[i]->ObjectEndPnt);
        ellep2->setState(0);
        ellep2->setMode(true);

        ellep2->item =  new QGraphicsPathItem(ellep2->getEllep(temp_copy_objects[i]->ObjectStrtPnt,temp_copy_objects[i]->ObjectEndPnt));
        if(isCopySelected) {
          ellep2->setTranslate(QPointF(5,5),QPointF(20,20));
          ellep2->item->setPath(ellep2->getEllep(ellep2->getStartPnt(),ellep2->getEndPnt()));
        }
        ellep2->setPen(temp_copy_objects[i]->getpen().color());
        ellep2->setPenStyle(temp_copy_objects[i]->getpen().style());
        ellep2->setPenWidth(temp_copy_objects[i]->getpen().width());
        ellep2->setBrush(temp_copy_objects[i]->getbrush());
        ellep2->setPen(temp_copy_objects[i]->getbrush().style());
        addItem(ellep2->item);
        ellep2->setEdgeRects();
        addItem(ellep2->Strt_Rect);
        addItem(ellep2->End_Rect);
        addItem(ellep2->Rot_Rect);
        elleps.push_back(ellep2);

        if(temp_copy_objects[i]->rotation!=0)
        ellep2->rotateShape(temp_copy_objects[i]->rotation);

        object->ObjectId=3;
        object->setObjectPos(ellep2->getStartPnt(),ellep2->getEndPnt());
        object->setpen(ellep2->getPen());
        object->setbrush(ellep2->getBrush());
        object->setObjects(3,elleps.size()-1);
        object->ObjectIndx=elleps.size()-1;
        objects.push_back(object);
        paste_selected_objects.push_back(object);
      }

      if(temp_copy_objects[i]->ObjectId==4) {
        Draw_Polygon *polygon2 = new Draw_Polygon();

        polygon2->poly_pnts = temp_copy_objects[i]->pnts;
        polygon2->item = new QGraphicsPathItem(polygon2->getPolygon());

        if(isCopySelected) {
          polygon2->setTranslate(QPointF(5,5),QPointF(20,20));
        }

        addItem(polygon2->item);
        polygon2->setPen(temp_copy_objects[i]->getpen().color());
        polygon2->setPenStyle(temp_copy_objects[i]->getpen().style());
        polygon2->setPenWidth(temp_copy_objects[i]->getpen().width());
        polygon2->setBrush(temp_copy_objects[i]->getbrush());
        polygon2->setBrushStyle(temp_copy_objects[i]->getbrush().style());

        if(!polygon2->edge_items.isEmpty())
        {
          for(int i=0;i<polygon2->edge_items.size();i++)
          {
            addItem(polygon2->edge_items[i]);
          }
        }

        addItem(polygon2->Rot_Rect);
        polygon2->setPolygonDrawn(true);
        mode=true;
        polygons.push_back(polygon2);

        if(temp_copy_objects[i]->rotation!=0)
        polygon2->rotateShape(temp_copy_objects[i]->rotation);

        object->ObjectId=4;
        object->setObjectPos(polygon2->item->boundingRect().topLeft(),polygon2->item->boundingRect().bottomRight());
        object->setpen(polygon2->getPen());
        object->setbrush(polygon2->getBrush());
        object->pnts=polygon2->poly_pnts;
        object->setObjects(4,polygons.size()-1);
        object->ObjectIndx=polygons.size()-1;
        objects.push_back(object);
        paste_selected_objects.push_back(object);
      }

      if(temp_copy_objects[i]->ObjectId==5) {
        Draw_RoundRect *round_rect2 = new Draw_RoundRect();
        //qDebug()<<"round copy selected "<<isCopySelected<<"\n";
        round_rect2->setStartPoint(temp_copy_objects[i]->ObjectStrtPnt);
        round_rect2->setEndPoint(temp_copy_objects[i]->ObjectEndPnt);
        round_rect2->setState(0);
        round_rect2->setMode(true);

        round_rect2->item = new QGraphicsPathItem(round_rect2->getRoundRect(temp_copy_objects[i]->ObjectStrtPnt,temp_copy_objects[i]->ObjectEndPnt));
        if(isCopySelected) {
          round_rect2->setTranslate(QPointF(5,5),QPointF(20,20));
          round_rect2->item->setPath(round_rect2->getRoundRect(round_rect2->getStartPnt(),round_rect2->getEndPnt()));
        }
        round_rect2->setPen(temp_copy_objects[i]->getpen().color());
        round_rect2->setPenStyle(temp_copy_objects[i]->getpen().style());
        round_rect2->setPenWidth(temp_copy_objects[i]->getpen().width());
        round_rect2->setBrush(temp_copy_objects[i]->getbrush());
        round_rect2->setPen(temp_copy_objects[i]->getbrush().style());
        addItem(round_rect2->item);
        round_rect2->setEdgeRects();
        addItem(round_rect2->Strt_Rect);
        addItem(round_rect2->End_Rect);
        addItem(round_rect2->Rot_Rect);
        round_rect2->Rot_Rect->hide();

        if(temp_copy_objects[i]->rotation!=0)
        round_rect2->rotateShape(temp_copy_objects[i]->rotation);

        round_rects.push_back(round_rect2);

        object->ObjectId=5;
        object->setObjectPos(round_rect2->getStartPnt(),round_rect2->getEndPnt());
        object->setpen(round_rect2->getPen());
        object->setbrush(round_rect2->getBrush());
        object->setObjects(5,round_rects.size()-1);
        object->ObjectIndx=round_rects.size()-1;
        objects.push_back(object);
        paste_selected_objects.push_back(object);
      }

      if(temp_copy_objects[i]->ObjectId==6)
      {
        Draw_Arc *arc2 = new Draw_Arc();

        arc2->setStartPoint(temp_copy_objects[i]->ObjectStrtPnt);
        arc2->setEndPoint(temp_copy_objects[i]->ObjectEndPnt);
        arc2->setCurvePoint(temp_copy_objects[i]->pnts[0]);
        arc2->setState(0);
        arc2->setMode(true);

        arc2->item = new QGraphicsPathItem(arc2->getArc());
        if(isCopySelected) {
          arc2->setTranslate(QPointF(5,5),QPointF(20,20));
          arc2->item->setPath(arc2->getArc());
        }
        arc2->setPen(temp_copy_objects[i]->getpen().color());
        arc2->setPenStyle(temp_copy_objects[i]->getpen().style());
        arc2->setPenWidth(temp_copy_objects[i]->getpen().width());
        addItem(arc2->item);
        arc2->setEdgeRects();
        addItem(arc2->Strt_Rect);
        addItem(arc2->End_Rect);
        addItem(arc2->Curve_Rect);
        addItem(arc2->Rot_Rect);

        if(temp_copy_objects[i]->rotation!=0) {
          arc2->rotateShape(temp_copy_objects[i]->rotation);
        }

        arcs.push_back(arc2);

        object->ObjectId=6;
        object->setObjectPos(arc2->getStartPnt(),arc2->getEndPnt());
        object->setBoundPos(arc2->item->boundingRect().topLeft(),arc2->item->boundingRect().bottomRight());
        object->pnts.push_back(arc2->getCurvePnt());
        object->setpen(arc2->getPen());
        object->setObjects(6,arcs.size()-1);
        object->ObjectIndx=arcs.size()-1;
        objects.push_back(object);
        paste_selected_objects.push_back(object);
      }

      if(temp_copy_objects[i]->ObjectId==7) {
        Draw_LineArrow *linearrow2 = new Draw_LineArrow();

        linearrow2->setStartPoint(temp_copy_objects[i]->ObjectStrtPnt);
        linearrow2->setEndPoint(temp_copy_objects[i]->ObjectEndPnt);

        QPointF pnt;

        pnt.setX(linearrow2->getEndPnt().x()-5.0);
        pnt.setY(linearrow2->getEndPnt().y());

        linearrow2->item = new QGraphicsPathItem(linearrow2->getLineArrow(pnt));

        pnt.setX(linearrow2->getEndPnt().x()-5.0);
        pnt.setY(linearrow2->getEndPnt().y());

        if(isCopySelected) {
          linearrow2->setTranslate(QPointF(5,5),QPointF(20,20));
          linearrow2->item->setPath(linearrow2->getLineArrow(pnt));
        }
        linearrow2->setPen(temp_copy_objects[i]->getpen().color());
        linearrow2->setPenStyle(temp_copy_objects[i]->getpen().style());
        linearrow2->setPenWidth(temp_copy_objects[i]->getpen().width());
        addItem(linearrow2->item);
        linearrow2->setEdgeRects();
        addItem(linearrow2->Strt_Rect);
        addItem(linearrow2->End_Rect);
        addItem(linearrow2->Rot_Rect);

        if(temp_copy_objects[i]->rotation!=0)
        linearrow2->rotateShape(temp_copy_objects[i]->rotation);

        linearrow2->setState(0);
        linearrow2->setMode(true);
        linearrows.push_back(linearrow2);

        object->ObjectId=7;
        object->setObjectPos(linearrow2->getStartPnt(),linearrow2->getEndPnt());
        object->setBoundPos(linearrow2->item->boundingRect().topLeft(),linearrow2->item->boundingRect().bottomRight());
        object->setpen(linearrow2->getPen());
        object->setObjects(7,linearrows.size()-1);
        object->ObjectIndx= linearrows.size()-1;
        objects.push_back(object);
        paste_selected_objects.push_back(object);
      }

      if(temp_copy_objects[i]->ObjectId==8) {
        Draw_Triangle *triangle2 = new Draw_Triangle();

        triangle2->setStartPoint(temp_copy_objects[i]->ObjectStrtPnt);
        triangle2->setEndPoint(temp_copy_objects[i]->ObjectEndPnt);
        triangle2->setState(0);
        triangle2->setMode(false);
        triangle2->item = new QGraphicsPathItem(triangle2->getTriangle());
        triangle2->setEdgeRects();

        addItem(triangle2->item);
        addItem(triangle2->Strt_Rect);
        addItem(triangle2->End_Rect);
        addItem(triangle2->Height_Rect);
        addItem(triangle2->Bounding_Rect);
        addItem(triangle2->Rot_Rect);

        if(isCopySelected) {
          triangle2->setTranslate(QPointF(5,5),QPointF(20,20));
          triangle2->item->setPath(triangle2->getTriangle());
        }

        triangle2->setPen(temp_copy_objects[i]->getpen().color());
        triangle2->setPenStyle(temp_copy_objects[i]->getpen().style());
        triangle2->setPenWidth(temp_copy_objects[i]->getpen().width());
        triangle2->setBrush(temp_copy_objects[i]->getbrush().color());
        triangle2->setBrushStyle(temp_copy_objects[i]->getbrush().style());
        triangle2->setMode(true);
        triangle2->Bounding_Rect->hide();

        if(temp_copy_objects[i]->rotation!=0) {
          triangle2->rotateShape(temp_copy_objects[i]->rotation);
        }

        triangles.push_back(triangle2);
        object->setObjectPos(triangle2->getStartPnt(),triangle2->getEndPnt());
        object->setBoundPos(triangle2->item->boundingRect().topLeft(),triangle2->item->boundingRect().bottomRight());
        object->pnts.push_back(QPointF(triangle2->getStartPnt()));
        object->pnts.push_back(QPointF(triangle2->getEndPnt()));
        object->pnts.push_back(QPointF(triangle2->getHeightPnt()));
        object->setObjects(8,triangles.size()-1);
        object->ObjectIndx=triangles.size()-1;
        object->setpen(triangle2->getPen());
        object->setbrush(triangle2->getBrush());
        objects.push_back(object);
      }

      if(temp_copy_objects[i]->ObjectId==9) {
        Draw_Arrow *arrow2 = new Draw_Arrow();

        arrow2->setStartPoint(temp_copy_objects[i]->ObjectStrtPnt);
        arrow2->setEndPoint(temp_copy_objects[i]->ObjectEndPnt);
        arrow2->setState(0);
        arrow2->setMode(false);

        arrow2->item = new QGraphicsPathItem(arrow2->getArrow());
        if(isCopySelected) {
          arrow2->setTranslate(QPointF(5,5),QPointF(20,20));
          arrow2->item->setPath(arrow2->getArrow());
        }
        arrow2->setPen(temp_copy_objects[i]->getpen().color());
        arrow2->setPenStyle(temp_copy_objects[i]->getpen().style());
        arrow2->setPenWidth(temp_copy_objects[i]->getpen().width());
        arrow2->setBrush(temp_copy_objects[i]->getbrush().color());
        arrow2->setBrushStyle(temp_copy_objects[i]->getbrush().style());
        addItem(arrow2->item);
        arrow2->setEdgeRects();
        addItem(arrow2->Strt_Rect);
        addItem(arrow2->End_Rect);
        addItem(arrow2->Bounding_Rect);
        addItem(arrow2->Rot_Rect);
        arrow2->Bounding_Rect->hide();
        arrow2->setMode(true);

        if(temp_copy_objects[i]->rotation!=0) {
          arrow2->rotateShape(temp_copy_objects[i]->rotation);
        }

        arrows.push_back(arrow2);

        object->ObjectId=9;
        object->setObjectPos(arrow2->getStartPnt(),arrow2->getEndPnt());
        object->setBoundPos(arrow2->item->boundingRect().topLeft(),arrow2->item->boundingRect().bottomRight());
        object->setpen(arrow2->getPen());
        object->setbrush(arrow2->getBrush());
        object->setObjects(9,arrows.size()-1);
        object->ObjectIndx=arrows.size()-1;
        objects.push_back(object);
        paste_selected_objects.push_back(object);
      }
    }
  }

  temp_copy_objects.clear();
  temp_copy_objects.reserve(paste_selected_objects.size());

  for(int i=0;i<paste_selected_objects.size();i++) {
    Scene_Objects* object = new Scene_Objects;
    object = paste_selected_objects[i];
    object->setpen(paste_selected_objects[i]->getpen());
    object->setbrush(paste_selected_objects[i]->getbrush());
    temp_copy_objects.insert(i,object);
  }

  paste_selected_objects.clear();
}


QPointF Graph_Scene::getDim()
{
  QPointF dim;

  selectedObjects();

  if(copy_objects.size()==0)
  {
       minPos.setX(objects[0]->ObjectStrtPnt.x());
       minPos.setY(objects[0]->ObjectStrtPnt.y());

       for(int i=1;i<objects.size();i++)
       {
           qDebug()<<objects[i]->ObjectStrtPnt<<"\n";
           qDebug()<<objects[i]->ObjectEndPnt<<"\n";

           if(minPos.x()>objects[i]->ObjectStrtPnt.x())
           {
              minPos.setX(objects[i]->ObjectStrtPnt.x());
           }

           if(minPos.y()>objects[i]->ObjectStrtPnt.y())
           {
              minPos.setY(objects[i]->ObjectStrtPnt.y());
          }
      }

      for(int i=0;i<objects.size();i++)
      {
          qDebug()<<objects[i]->ObjectStrtPnt<<"\n";
          qDebug()<<objects[i]->ObjectEndPnt<<"\n";

          if(minPos.x()>objects[i]->ObjectEndPnt.x())
          {
              minPos.setX(objects[i]->ObjectEndPnt.x());
          }

          if(minPos.y()>objects[i]->ObjectEndPnt.y())
          {
              minPos.setY(objects[i]->ObjectEndPnt.y());
          }
      }

    /*for(int i=0;i<objects.size();i++)
    {
      if(!objects[i]->pnts.isEmpty())
      {
       for(int j=0;j<objects[i]->pnts.size();j++)
      {

      }
    }
   }*/


   maxPos.setX(objects[0]->ObjectEndPnt.x());
     maxPos.setY(objects[0]->ObjectEndPnt.y());

     for(int i=1;i<objects.size();i++)
     {
        if(maxPos.x()<objects[i]->ObjectEndPnt.x())
        {
            maxPos.setX(objects[i]->ObjectEndPnt.x());
        }

        if(maxPos.y()<objects[i]->ObjectEndPnt.y())
        {
            maxPos.setY(objects[i]->ObjectEndPnt.y());
        }
     }


     for(int i=0;i<objects.size();i++)
     {
        if(maxPos.x()<objects[i]->ObjectStrtPnt.x())
        {
            maxPos.setX(objects[i]->ObjectStrtPnt.x());
        }

        if(maxPos.y()<objects[i]->ObjectStrtPnt.y())
        {
            maxPos.setY(objects[i]->ObjectStrtPnt.y());
        }
     }

   qDebug()<<"min Point "<<minPos.x()<<" "<<minPos.y()<<"\n";
     qDebug()<<"max Point "<<maxPos.x()<<"  "<<maxPos.y()<<"\n";
     //dim=maxPos-minPos;
   dim.setX(maxPos.x()-minPos.x());
   dim.setY(maxPos.y()-minPos.y());

   qDebug()<<"dim "<<dim<<"\n";
   return dim;
   }

   if(copy_objects.size()!=0)
  {
       minPos.setX(copy_objects[0]->ObjectStrtPnt.x());
       minPos.setY(copy_objects[0]->ObjectStrtPnt.y());


       for(int i=1;i<copy_objects.size();i++)
       {
           qDebug()<<copy_objects[i]->ObjectStrtPnt<<"\n";
           qDebug()<<copy_objects[i]->ObjectEndPnt<<"\n";

           if(minPos.x()>copy_objects[i]->ObjectStrtPnt.x())
           {
              minPos.setX(copy_objects[i]->ObjectStrtPnt.x());
           }

           if(minPos.y()>copy_objects[i]->ObjectStrtPnt.y())
           {
              minPos.setY(copy_objects[i]->ObjectStrtPnt.y());
          }
      }


      for(int i=0;i<copy_objects.size();i++)
      {
          qDebug()<<copy_objects[i]->ObjectStrtPnt<<"\n";
          qDebug()<<copy_objects[i]->ObjectEndPnt<<"\n";

          if(minPos.x()>copy_objects[i]->ObjectEndPnt.x())
          {
              minPos.setX(copy_objects[i]->ObjectEndPnt.x());
          }

          if(minPos.y()>copy_objects[i]->ObjectEndPnt.y())
          {
              minPos.setY(copy_objects[i]->ObjectEndPnt.y());
          }
      }

    /*for(int i=0;i<objects.size();i++)
    {
      if(!objects[i]->pnts.isEmpty())
      {
       for(int j=0;j<objects[i]->pnts.size();j++)
      {

      }
    }
   }*/


   maxPos.setX(copy_objects[0]->ObjectEndPnt.x());
     maxPos.setY(copy_objects[0]->ObjectEndPnt.y());

     for(int i=1;i<copy_objects.size();i++)
     {
        if(maxPos.x()<copy_objects[i]->ObjectEndPnt.x())
        {
            maxPos.setX(copy_objects[i]->ObjectEndPnt.x());
        }

        if(maxPos.y()<copy_objects[i]->ObjectEndPnt.y())
        {
            maxPos.setY(copy_objects[i]->ObjectEndPnt.y());
        }
     }


     for(int i=0;i<copy_objects.size();i++)
     {
        if(maxPos.x()<copy_objects[i]->ObjectStrtPnt.x())
        {
            maxPos.setX(copy_objects[i]->ObjectStrtPnt.x());
        }

        if(maxPos.y()<copy_objects[i]->ObjectStrtPnt.y())
        {
            maxPos.setY(copy_objects[i]->ObjectStrtPnt.y());
        }
     }

   qDebug()<<"min Point "<<ceil(minPos.x())<<" "<<ceil(minPos.y())<<"\n";
     qDebug()<<"max Point "<<ceil(maxPos.x())<<"  "<<ceil(maxPos.y())<<"\n";
     //dim=maxPos-minPos;
   dim.setX(ceil(maxPos.x())-ceil(minPos.x()));
   dim.setY(ceil(maxPos.y())-ceil(minPos.y()));

   qDebug()<<"dim "<<dim<<"\n";
   return dim;
   }

}

void Graph_Scene::getDist(QPointF &vertex, float &dist) {
  dist = sqrt(((vertex.x())*(vertex.x()))+((vertex.y())*(vertex.y())));
}

void Graph_Scene::getObjectsPos(QVector<QPointF> &objectsPos) {
  objectsPos.clear();
  selectedObjects();
  if(copy_objects.size()==0) {
    //qDebug()<<"entered data \n";
    for(int i=0;i<objects.size();i++) {
      objectsPos.push_back(objects[i]->ObjectStrtPnt);
      objectsPos.push_back(objects[i]->ObjectEndPnt);
    }
  } else {
    for(int i=0;i<copy_objects.size();i++) {
      objectsPos.push_back(copy_objects[i]->ObjectStrtPnt);
      objectsPos.push_back(copy_objects[i]->ObjectEndPnt);
    }
  }
}

QVector<Scene_Objects*> Graph_Scene::getObjects() {
  if(copy_objects.size()==0)
    return objects;
  else
    return copy_objects;
}

void Graph_Scene::getMinPosition(QPointF &pnt) {
  //qDebug()<<"min Pos "<<minPos<<"\n";
  //qDebug()<<"max Pos "<<maxPos<<"\n";
  pnt = minPos;
}

void Graph_Scene::getMaxPosition(QPointF &pnt1) {
  pnt1 = maxPos;
}

template<class T> void Graph_Scene::setMinMax(T* &object, int objectId,QPointF pnt,QPointF pnt1)
{
    QPen pen = QPen();

    if(objectId==1)
    {
       Draw_Line* object1=reinterpret_cast<Draw_Line*>(object);
       pen.setColor(QColor(255,255,255));
       if((object1->getStartPnt().x()>pnt.x())&&(object1->getStartPnt().y()<pnt.y()))
           addLine(pnt.x(),object1->getStartPnt().y(),object1->getStartPnt().x()-pnt.x(),pnt.y()-object1->getStartPnt().y(),pen);
       else if((object1->getStartPnt().y()>pnt.y())&&(object1->getStartPnt().x()<pnt.x()))
           addLine(object1->getStartPnt().x(),pnt.y(),pnt.x()-object1->getStartPnt().x(),object1->getStartPnt().y()-pnt.y(),pen);
       else if((object1->getStartPnt().x()>pnt.x()) && (object1->getStartPnt().y()>pnt.y()))
           addLine(pnt.x(),pnt.y(),object1->getStartPnt().x()-pnt.x(),object1->getStartPnt().y()-pnt.y(),pen);
       else
           addLine(object1->getStartPnt().x(),object1->getStartPnt().y(),pnt.x()-object1->getStartPnt().x(),pnt.y()-object1->getStartPnt().y(),pen);

       pen.setColor(QColor(0,0,0));
       if(object1->getStartPnt().x()>pnt1.x())
          addLine(pnt1.x(),object1->getStartPnt().y(),object1->getStartPnt().x()-pnt1.x(),pnt1.y()-object1->getStartPnt().y(),pen);
       else if(object1->getStartPnt().y()>pnt1.y())
          addLine(object1->getStartPnt().x(),pnt1.y(),pnt1.x()-object1->getStartPnt().x(),object1->getStartPnt().y()-pnt1.y(),pen);
       else if((object1->getStartPnt().x()>pnt1.x()) && (object1->getStartPnt().y()>pnt1.y()))
          addLine(pnt1.x(),pnt1.y(),object1->getStartPnt().x()-pnt1.x(),object1->getStartPnt().y()-pnt1.y(),pen);
       else
          addLine(object1->getStartPnt().x(),object1->getStartPnt().y(),pnt1.x()-object1->getStartPnt().x(),pnt1.y()-object1->getStartPnt().y(),pen);
   }

    if(objectId==2)
    {
       Draw_Rectangle* object2=reinterpret_cast<Draw_Rectangle*>(object);
       pen.setColor(QColor(255,255,255));
       if((object2->getStartPnt().x()>pnt.x())&&(object2->getStartPnt().y()<pnt.y()))
           addRect(pnt.x(),object2->getStartPnt().y(),object2->getStartPnt().x()-pnt.x(),pnt.y()-object2->getStartPnt().y(),pen);
       else if((object2->getStartPnt().y()>pnt.y())&&(object2->getStartPnt().x()<pnt.x()))
           addRect(object2->getStartPnt().x(),pnt.y(),pnt.x()-object2->getStartPnt().x(),object2->getStartPnt().y()-pnt.y(),pen);
       else if((object2->getStartPnt().x()>pnt.x()) && (object2->getStartPnt().y()>pnt.y()))
           addRect(pnt.x(),pnt.y(),object2->getStartPnt().x()-pnt.x(),object2->getStartPnt().y()-pnt.y(),pen);
       else
           addRect(object2->getStartPnt().x(),object2->getStartPnt().y(),pnt.x()-object2->getStartPnt().x(),pnt.y()-object2->getStartPnt().y(),pen);

       pen.setColor(QColor(0,0,0));
       if(object2->getStartPnt().x()>pnt1.x())
          addRect(pnt1.x(),object2->getStartPnt().y(),object2->getStartPnt().x()-pnt1.x(),pnt1.y()-object2->getStartPnt().y(),pen);
       else if(object2->getStartPnt().y()>pnt1.y())
          addRect(object2->getStartPnt().x(),pnt1.y(),pnt1.x()-object2->getStartPnt().x(),object2->getStartPnt().y()-pnt1.y(),pen);
       else if((object2->getStartPnt().x()>pnt1.x()) && (object2->getStartPnt().y()>pnt1.y()))
          addRect(pnt1.x(),pnt1.y(),object2->getStartPnt().x()-pnt1.x(),object2->getStartPnt().y()-pnt1.y(),pen);
       else
          addRect(object2->getStartPnt().x(),object2->getStartPnt().y(),pnt1.x()-object2->getStartPnt().x(),pnt1.y()-object2->getStartPnt().y(),pen);
   }

    if(objectId==3)
    {
       Draw_Ellipse* object3=reinterpret_cast<Draw_Ellipse*>(object);
       pen.setColor(QColor(255,255,255));
       if((object3->getStartPnt().x()>pnt.x())&&(object3->getStartPnt().y()<pnt.y()))
           addEllipse(pnt.x(),object3->getStartPnt().y(),object3->getStartPnt().x()-pnt.x(),pnt.y()-object3->getStartPnt().y(),pen);
       else if((object3->getStartPnt().y()>pnt.y())&&(object3->getStartPnt().x()<pnt.x()))
           addEllipse(object3->getStartPnt().x(),pnt.y(),pnt.x()-object3->getStartPnt().x(),object3->getStartPnt().y()-pnt.y(),pen);
       else if((object3->getStartPnt().x()>pnt.x()) && (object3->getStartPnt().y()>pnt.y()))
           addEllipse(pnt.x(),pnt.y(),object3->getStartPnt().x()-pnt.x(),object3->getStartPnt().y()-pnt.y(),pen);
       else
           addEllipse(object3->getStartPnt().x(),object3->getStartPnt().y(),pnt.x()-object3->getStartPnt().x(),pnt.y()-object3->getStartPnt().y(),pen);

       pen.setColor(QColor(0,0,0));
       if(object3->getStartPnt().x()>pnt1.x())
          addEllipse(pnt1.x(),object3->getStartPnt().y(),object3->getStartPnt().x()-pnt1.x(),pnt1.y()-object3->getStartPnt().y(),pen);
       else if(object3->getStartPnt().y()>pnt1.y())
          addEllipse(object3->getStartPnt().x(),pnt1.y(),pnt1.x()-object3->getStartPnt().x(),object3->getStartPnt().y()-pnt1.y(),pen);
       else if((object3->getStartPnt().x()>pnt1.x()) && (object3->getStartPnt().y()>pnt1.y()))
          addEllipse(pnt1.x(),pnt1.y(),object3->getStartPnt().x()-pnt1.x(),object3->getStartPnt().y()-pnt1.y(),pen);
       else
          addEllipse(object3->getStartPnt().x(),object3->getStartPnt().y(),pnt1.x()-object3->getStartPnt().x(),pnt1.y()-object3->getStartPnt().y(),pen);
   }
}

void Graph_Scene::setPen(const QPen Pen) { //HKchecked
  if(line && line->getPolyLineDrawn()&&(line->edge_items[0]->isVisible())) {
    line->setPen(Pen.color());
    if(!lines.isEmpty()) {
      for(int i=0;i<lines.size();i++) {
        if(lines[i]->edge_items[0]->isVisible()) {
          lines[i]->setPen(line->getPen().color());
        }
      }
    }
  }
  if(rect && rect->getMode()&&(rect->Strt_Rect->isVisible())) {
    rect->setPen(Pen.color());
    if(!rects.isEmpty()) {
      for(int i=0;i<rects.size();i++) {
        if(rects[i]->Strt_Rect->isVisible()) {
          rects[i]->setPen(rect->getPen().color());
        }
      }
    }
  }
  if(ellep && ellep->getMode()&&(ellep->Strt_Rect->isVisible())) {
    ellep->setPen(Pen.color());
    if(!elleps.isEmpty()) {
      for(int i=0;i<elleps.size();i++) {
        if(elleps[i]->Strt_Rect->isVisible()) {
          elleps[i]->setPen(ellep->getPen().color());
        }
      }
    }
  }
  if(polygon && polygon->getPolygonDrawn()&&(polygon->edge_items[0]->isVisible())) {
    polygon->setPen(Pen.color());
    if(!polygons.isEmpty()) {
      for(int i=0;i<polygons.size();i++) {
        if(polygons[i]->edge_items[0]->isVisible()) {
          polygons[i]->setPen(polygon->getPen().color());
        }
      }
    }
  }
  if(round_rect && round_rect->getMode()&&(round_rect->Strt_Rect->isVisible())) {
    round_rect->setPen(Pen.color());
    if(!round_rects.isEmpty()) {
      for(int i=0;i<round_rects.size();i++) {
        if(round_rects[i]->Strt_Rect->isVisible()) {
          round_rects[i]->setPen(round_rect->getPen().color());
        }
      }
    }
  }
  if(arc && arc->getMode()&&(arc->Strt_Rect->isVisible())) {
    arc->setPen(Pen.color());
    if(!arcs.isEmpty()) {
      for(int i=0;i<arcs.size();i++) {
        if(arcs[i]->Strt_Rect->isVisible()) {
          arcs[i]->setPen(arc->getPen().color());
        }
      }
    }
  }
  if(linearrow && linearrow->getMode()&&(linearrow->Strt_Rect->isVisible())) {
    linearrow->setPen(Pen.color());
    if(arc && !linearrows.isEmpty()) {
      for(int i=0;i<linearrows.size();i++) {
        if(linearrows[i]->Strt_Rect->isVisible()) {
          linearrows[i]->setPen(linearrow->getPen().color());
        }
      }
    }
  }
  if(triangle && triangle->getMode()&&(triangle->Strt_Rect->isVisible())) {
    triangle->setPen(Pen.color());
    if(!triangles.isEmpty()) {
      for(int i=0;i<triangles.size();i++) {
        if(triangles[i]->Strt_Rect->isVisible()) {
          triangles[i]->setPen(triangle->getPen().color());
        }
      }
    }
  }
  if(arrow && arrow->getMode()&&(arrow->Strt_Rect->isVisible())) {
    arrow->setPen(Pen.color());
    if(!arrows.isEmpty()) {
      for(int i=0;i<arrows.size();i++) {
        if(arrows[i]->Strt_Rect->isVisible()) {
          arrows[i]->setPen(arrow->getPen().color());
        }
      }
    }
  }
  updateObjects();
}

void Graph_Scene::setPenStyle(const int style) { //HKchecked
  if(line && line->getPolyLineDrawn()&&(line->edge_items[0]->isVisible())) {
    line->setPenStyle(style);
    if(!lines.isEmpty()) {
      for(int i=0;i<lines.size();i++) {
        if(lines[i]->edge_items[0]->isVisible()) {
          lines[i]->setPenStyle(line->getPen().style());
        }
      }
    }
  }
  if(rect && rect->getMode()&&(rect->Strt_Rect->isVisible())) {
    rect->setPenStyle(style);
    if(!rects.isEmpty()) {
      for(int i=0;i<rects.size();i++) {
        if(rects[i]->Strt_Rect->isVisible()) {
          rects[i]->setPenStyle(rect->getPen().style());
        }
      }
    }
  }
  if(ellep && ellep->getMode()&&(ellep->Strt_Rect->isVisible())) {
    ellep->setPenStyle(style);
    if(!elleps.isEmpty()) {
      for(int i=0;i<elleps.size();i++) {
        if(elleps[i]->Strt_Rect->isVisible()) {
          elleps[i]->setPenStyle(ellep->getPen().style());
        }
      }
    }
  }
  if(polygon && polygon->getPolygonDrawn()&&(polygon->edge_items[0]->isVisible())) {
    polygon->setPenStyle(style);
    if(!polygons.isEmpty()) {
      for(int i=0;i<polygons.size();i++) {
        if(polygons[i]->edge_items[0]->isVisible()) {
          polygons[i]->setPenStyle(polygon->getPen().style());
        }
      }
    }
  }
  if(round_rect && round_rect->getMode()&&(round_rect->Strt_Rect->isVisible())) {
    round_rect->setPenStyle(style);
    if(!round_rects.isEmpty()) {
      for(int i=0;i<round_rects.size();i++) {
        if(round_rects[i]->Strt_Rect->isVisible()) {
          round_rects[i]->setPenStyle(round_rect->getPen().style());
        }
      }
    }
  }
  if(arc && arc->getMode()&&(arc->Strt_Rect->isVisible())) {
    arc->setPenStyle(style);
    if(!arcs.isEmpty()) {
      for(int i=0;i<arcs.size();i++) {
        if(arcs[i]->Strt_Rect->isVisible()) {
          arcs[i]->setPenStyle(arc->getPen().style());
        }
      }
    }
  }
  if(linearrow && linearrow->getMode()&&(linearrow->Strt_Rect->isVisible())) {
    linearrow->setPenStyle(style);
    if(arc && !linearrows.isEmpty()) {
      for(int i=0;i<linearrows.size();i++) {
        if(linearrows[i]->Strt_Rect->isVisible()) {
          linearrows[i]->setPenStyle(linearrow->getPen().style());
        }
      }
    }
  }
  if(triangle && triangle->getMode()&&(triangle->Strt_Rect->isVisible())) {
    triangle->setPenStyle(style);
    if(!triangles.isEmpty()) {
      for(int i=0;i<triangles.size();i++) {
        if(triangles[i]->Strt_Rect->isVisible()) {
          triangles[i]->setPenStyle(triangle->getPen().style());
        }
      }
    }
  }
  if(arrow && arrow->getMode()&&(arrow->Strt_Rect->isVisible())) {
    arrow->setPenStyle(style);
    if(!arrows.isEmpty()) {
      for(int i=0;i<arrows.size();i++) {
        if(arrows[i]->Strt_Rect->isVisible()) {
          arrows[i]->setPenStyle(arrow->getPen().style());
        }
      }
    }
  }
  updateObjects();
}

void Graph_Scene::setPenWidth(const int width) { //HKchecked
  if(line && line->getPolyLineDrawn()&&(line->edge_items[0]->isVisible())) {
    line->setPenWidth(width);
    if(!lines.isEmpty()) {
      for(int i=0;i<lines.size();i++) {
        if(lines[i]->edge_items[0]->isVisible()) {
          lines[i]->setPenWidth(line->getPen().width());
        }
      }
    }
  }
  if(rect && rect->getMode()&&(rect->Strt_Rect->isVisible())) {
    rect->setPenWidth(width);
    if(!rects.isEmpty()) {
      for(int i=0;i<rects.size();i++) {
        if(rects[i]->Strt_Rect->isVisible()) {
          rects[i]->setPenWidth(rect->getPen().width());
        }
      }
    }
  }
  if(ellep && ellep->getMode()&&(ellep->Strt_Rect->isVisible())) {
    ellep->setPenWidth(width);
    if(!elleps.isEmpty()) {
      for(int i=0;i<elleps.size();i++) {
        if(elleps[i]->Strt_Rect->isVisible()) {
          elleps[i]->setPenWidth(ellep->getPen().width());
        }
      }
    }
  }
  if(polygon && polygon->getPolygonDrawn()&&(polygon->edge_items[0]->isVisible())) {
    polygon->setPenWidth(width);
    if(!polygons.isEmpty()) {
      for(int i=0;i<polygons.size();i++) {
        if(polygons[i]->edge_items[0]->isVisible()) {
          polygons[i]->setPenWidth(polygon->getPen().width());
        }
      }
    }
  }
  if(round_rect && round_rect->getMode()&&(round_rect->Strt_Rect->isVisible())) {
    round_rect->setPenWidth(width);
    if(!round_rects.isEmpty()) {
      for(int i=0;i<round_rects.size();i++) {
        if(round_rects[i]->Strt_Rect->isVisible()) {
          round_rects[i]->setPenWidth(round_rect->getPen().width());
        }
      }
    }
  }
  if(arc && arc->getMode()&&(arc->Strt_Rect->isVisible())) {
    arc->setPenWidth(width);
    if(!arcs.isEmpty()) {
      for(int i=0;i<arcs.size();i++) {
        if(arcs[i]->Strt_Rect->isVisible()) {
          arcs[i]->setPenWidth(arc->getPen().width());
        }
      }
    }
  }
  if(linearrow && linearrow->getMode()&&(linearrow->Strt_Rect->isVisible())) {
    linearrow->setPenWidth(width);
    if(arc && !linearrows.isEmpty()) {
      for(int i=0;i<linearrows.size();i++) {
        if(linearrows[i]->Strt_Rect->isVisible()) {
          linearrows[i]->setPenWidth(linearrow->getPen().width());
        }
      }
    }
  }
  if(triangle && triangle->getMode()&&(triangle->Strt_Rect->isVisible())) {
    triangle->setPenWidth(width);
    if(!triangles.isEmpty()) {
      for(int i=0;i<triangles.size();i++) {
        if(triangles[i]->Strt_Rect->isVisible()) {
          triangles[i]->setPenWidth(triangle->getPen().width());
        }
      }
    }
  }
  if(arrow && arrow->getMode()&&(arrow->Strt_Rect->isVisible())) {
    arrow->setPenWidth(width);
    if(!arrows.isEmpty()) {
      for(int i=0;i<arrows.size();i++) {
        if(arrows[i]->Strt_Rect->isVisible()) {
          arrows[i]->setPenWidth(arrow->getPen().width());
        }
      }
    }
  }
  updateObjects();
}

QPen Graph_Scene::getPen() {
    return pen;
}

void Graph_Scene::setBrush(const QBrush brush) { //HKchecked
  if(rect && rect->getMode()&&(rect->Strt_Rect->isVisible())) {
    rect->setBrush(brush);
    if(!rects.isEmpty()) {
      for(int i=0;i<rects.size();i++) {
        if(rects[i]->Strt_Rect->isVisible()) {
          rects[i]->setBrush(rect->getBrush());
        }
      }
    }
  }
  if(ellep && ellep->getMode()&&(ellep->Strt_Rect->isVisible())) {
    ellep->setBrush(brush);
    if(!elleps.isEmpty()) {
      for(int i=0;i<elleps.size();i++) {
        if(elleps[i]->Strt_Rect->isVisible()) {
          elleps[i]->setBrush(ellep->getBrush());
        }
      }
    }
  }
  if(polygon && polygon->getPolygonDrawn()&&(polygon->edge_items[0]->isVisible())) {
    polygon->setBrush(brush);
    if(!polygons.isEmpty()) {
      for(int i=0;i<polygons.size();i++) {
        if(polygons[i]->edge_items[0]->isVisible()) {
          polygons[i]->setBrush(polygon->getBrush());
        }
      }
    }
  }
  if(round_rect && round_rect->getMode()&&(round_rect->Strt_Rect->isVisible())) {
    round_rect->setBrush(brush);
    if(!round_rects.isEmpty()) {
      for(int i=0;i<round_rects.size();i++) {
        if(round_rects[i]->Strt_Rect->isVisible()) {
          round_rects[i]->setBrush(round_rect->getBrush());
        }
      }
    }
  }
  if(triangle && triangle->getMode()&&(triangle->Strt_Rect->isVisible())) {
    triangle->setBrush(brush);
    if(!triangles.isEmpty()) {
      for(int i=0;i<triangles.size();i++) {
        if(triangles[i]->Strt_Rect->isVisible()) {
          triangles[i]->setBrush(triangle->getBrush());
        }
      }
    }
  }
  if(arrow && arrow->getMode()&&(arrow->Strt_Rect->isVisible())) {
    arrow->setBrush(brush);
    if(!arrows.isEmpty()) {
      for(int i=0;i<arrows.size();i++) {
        if(arrows[i]->Strt_Rect->isVisible()) {
          arrows[i]->setBrush(arrow->getBrush());
        }
      }
    }
  }
  updateObjects();
}

void Graph_Scene::setBrushStyle(const int style) { //HKchecked
  if(rect && rect->getMode()&&(rect->Strt_Rect->isVisible())) {
    rect->setBrushStyle(style);
    if(!rects.isEmpty()) {
      for(int i=0;i<rects.size();i++) {
        if(rects[i]->Strt_Rect->isVisible()) {
          rects[i]->setBrushStyle(rect->getBrush().style());
        }
      }
    }
  }
  if(ellep && ellep->getMode()&&(ellep->Strt_Rect->isVisible())) {
    ellep->setBrushStyle(style);
    if(!elleps.isEmpty()) {
      for(int i=0;i<elleps.size();i++) {
        if(elleps[i]->Strt_Rect->isVisible()) {
          elleps[i]->setBrushStyle(ellep->getBrush().style());
        }
      }
    }
  }
  if(polygon && polygon->getPolygonDrawn()&&(polygon->edge_items[0]->isVisible())) {
    polygon->setBrushStyle(style);
    if(!polygons.isEmpty()) {
      for(int i=0;i<polygons.size();i++) {
        if(polygons[i]->edge_items[0]->isVisible()) {
          polygons[i]->setBrushStyle(polygon->getBrush().style());
        }
      }
    }
  }
  if(round_rect && round_rect->getMode()&&(round_rect->Strt_Rect->isVisible())) {
    round_rect->setBrushStyle(style);
    if(!round_rects.isEmpty()) {
      for(int i=0;i<round_rects.size();i++) {
        if(round_rects[i]->Strt_Rect->isVisible()) {
          round_rects[i]->setBrushStyle(round_rect->getBrush().style());
        }
      }
    }
  }
  if(triangle && triangle->getMode()&&(triangle->Strt_Rect->isVisible())) {
    triangle->setBrushStyle(style);
    if(!triangles.isEmpty()) {
      for(int i=0;i<triangles.size();i++) {
        if(triangles[i]->Strt_Rect->isVisible()) {
          triangles[i]->setBrushStyle(triangle->getBrush().style());
        }
      }
    }
  }
  if(arrow && arrow->getMode()&&(arrow->Strt_Rect->isVisible())) {
    arrow->setBrushStyle(style);
    if(!arrows.isEmpty()) {
      for(int i=0;i<arrows.size();i++) {
        if(arrows[i]->Strt_Rect->isVisible()) {
          arrows[i]->setBrushStyle(arrow->getBrush().style());
        }
      }
    }
  }
  updateObjects();
}

void Graph_Scene::updateObjects() {
  for(int i=0;i<objects.size();i++) {
    if(objects[i]->ObjectId==1) {
      objects[i]->pen = lines[objects[i]->ObjectIndx]->getPen();
    }
    if(objects[i]->ObjectId==2) {
      objects[i]->pen = rects[objects[i]->ObjectIndx]->getPen();
      objects[i]->brush = rects[objects[i]->ObjectIndx]->getBrush();
    }
    if(objects[i]->ObjectId==3) {
      objects[i]->pen = elleps[objects[i]->ObjectIndx]->getPen();
      objects[i]->brush = elleps[objects[i]->ObjectIndx]->getBrush();
    }
    if(objects[i]->ObjectId==4) {
      objects[i]->pen = polygons[objects[i]->ObjectIndx]->getPen();
      objects[i]->brush = polygons[objects[i]->ObjectIndx]->getBrush();
    }
    if(objects[i]->ObjectId==5) {
      objects[i]->pen = round_rects[objects[i]->ObjectIndx]->getPen();
      objects[i]->brush = round_rects[objects[i]->ObjectIndx]->getBrush();
    }
    if(objects[i]->ObjectId==6) {
      objects[i]->pen = arcs[objects[i]->ObjectIndx]->getPen();
    }
    if(objects[i]->ObjectId==8) {
      objects[i]->pen = triangles[objects[i]->ObjectIndx]->getPen();
      objects[i]->brush = triangles[objects[i]->ObjectIndx]->getBrush();
    }
    if(objects[i]->ObjectId==9) {
      objects[i]->pen = arrows[objects[i]->ObjectIndx]->getPen();
      objects[i]->brush = arrows[objects[i]->ObjectIndx]->getBrush();
    }
  }
}

void Graph_Scene::select_objects(Scene_Objects objects1) {
  if(!lines.isEmpty()&&(objects1.ObjectId==1)) {
    lines[objects1.ObjectIndx]->isObjectSelected=!lines[objects1.ObjectIndx]->isObjectSelected;
    if(lines[objects1.ObjectIndx]->isObjectSelected) {
      lines[objects1.ObjectIndx]->showHandles();
    } else {
      lines[objects1.ObjectIndx]->hideHandles();
    }
  }
  if(!rects.isEmpty()&&(objects1.ObjectId==2)) {
    rects[objects1.ObjectIndx]->isObjectSelected=!rects[objects1.ObjectIndx]->isObjectSelected;
    if(rects[objects1.ObjectIndx]->isObjectSelected){
      rects[objects1.ObjectIndx]->showHandles();
    } else {
      rects[objects1.ObjectIndx]->hideHandles();
    }
  }
  if(!round_rects.isEmpty()&&(objects1.ObjectId==5)) {
    round_rects[objects1.ObjectIndx]->isObjectSelected=!round_rects[objects1.ObjectIndx]->isObjectSelected;
    if(round_rects[objects1.ObjectIndx]->isObjectSelected) {
      round_rects[objects1.ObjectIndx]->showHandles();
    } else {
      round_rects[objects1.ObjectIndx]->hideHandles();
    }
  }
  if(!elleps.isEmpty()&&(objects1.ObjectId==3)) {
    elleps[objects1.ObjectIndx]->isObjectSelected=!elleps[objects1.ObjectIndx]->isObjectSelected;
    if(elleps[objects1.ObjectIndx]->isObjectSelected) {
      elleps[objects1.ObjectIndx]->showHandles();
    } else {
      elleps[objects1.ObjectIndx]->hideHandles();
    }
  }
  if(!polygons.isEmpty()&&(objects1.ObjectId==4)) {
    if(!polygons[objects1.ObjectIndx]->edge_items.isEmpty()) {
      for(int k=0;k<polygons[objects1.ObjectIndx]->edge_items.size();k++) {
        if(!polygons[objects1.ObjectIndx]->edge_items[k]->isVisible()) {
          polygons[objects1.ObjectIndx]->showHandles();
        } else {
          polygons[objects1.ObjectIndx]->hideHandles();
        }
      }
    }
  }
  if(!arcs.isEmpty()&&(objects1.ObjectId==6)) {
    arcs[objects1.ObjectIndx]->isObjectSelected=!arcs[objects1.ObjectIndx]->isObjectSelected;
    if(arcs[objects1.ObjectIndx]->isObjectSelected) {
      arcs[objects1.ObjectIndx]->showHandles();
    } else {
      arcs[objects1.ObjectIndx]->hideHandles();
    }
  }
  if(!arrows.isEmpty()&&(objects1.ObjectId==9)) {
    arrows[objects1.ObjectIndx]->isObjectSelected=!arrows[objects1.ObjectIndx]->isObjectSelected;
    if(arrows[objects1.ObjectIndx]->isObjectSelected) {
      arrows[objects1.ObjectIndx]->showHandles();
    } else {
      arrows[objects1.ObjectIndx]->hideHandles();
    }
  }
  if(!linearrows.isEmpty()&&(objects1.ObjectId==7)) {
    linearrows[objects1.ObjectIndx]->isObjectSelected=!linearrows[objects1.ObjectIndx]->isObjectSelected;
    if(linearrows[objects1.ObjectIndx]->isObjectSelected) {
      linearrows[objects1.ObjectIndx]->showHandles();
    } else {
      linearrows[objects1.ObjectIndx]->hideHandles();
    }
  }
  if(!triangles.isEmpty()&&(objects1.ObjectId==8)) {
    triangles[objects1.ObjectIndx]->isObjectSelected=!triangles[objects1.ObjectIndx]->isObjectSelected;
    if(triangles[objects1.ObjectIndx]->isObjectSelected) {
      triangles[objects1.ObjectIndx]->showHandles();
    } else {
      triangles[objects1.ObjectIndx]->hideHandles();
    }
  }
  if(!texts.isEmpty()&&(objects1.ObjectId==10)) {
    texts[objects1.ObjectIndx]->isObjectSelected=!texts[objects1.ObjectIndx]->isObjectSelected;
    if(texts[objects1.ObjectIndx]->isObjectSelected) {
      texts[objects1.ObjectIndx]->showHandles();
    } else {
      texts[objects1.ObjectIndx]->hideHandles();
    }
  }
}

void Graph_Scene::selectedObjects() {
  copy_objects.clear();
  if(!objects.isEmpty()) {
    for(int j=0;j<lines.size();j++) {
      //if(objects[i]->ObjectStrtPnt==lines[j]->item->boundingRect().topLeft())
      {
        if(lines[j]->edge_items[0]->isVisible()) {
          Scene_Objects* object = new Scene_Objects();
          //object=objects[i];
          QRectF poly_line=lines[j]->item->boundingRect();
          object->ObjectStrtPnt=poly_line.topLeft();
          object->ObjectEndPnt=poly_line.bottomRight();
          object->pnts=lines[j]->poly_pnts;
          object->rotation=lines[j]->item->rotation();
          object->setpen(lines[j]->getPen());
          copy_objects.push_back(object);
        }
      }
    }
    for(int j=0;j<rects.size();j++) {
      //if(objects[i]->ObjectStrtPnt==rects[j]->getStartPnt())
      {
        if(rects[j]->Strt_Rect->isVisible()) {
          //qDebug()<<"entered condition  "<<j<<"\n";
          Scene_Objects* object = new Scene_Objects();
          //object=objects[i];
          object->ObjectId=2;
          object->ObjectIndx=j;
          object->ObjectStrtPnt=rects[j]->getStartPnt();
          object->ObjectEndPnt=rects[j]->getEndPnt();
          object->rotation=rects[j]->item->rotation();
          object->setpen(rects[j]->getPen());
          object->setbrush(rects[j]->getBrush());
          copy_objects.push_back(object);
        }
      }
    }
    for(int j=0;j<elleps.size();j++) {
      //if(objects[i]->ObjectStrtPnt==elleps[j]->getStartPnt())
      {
        if(elleps[j]->Strt_Rect->isVisible()) {
          Scene_Objects* object = new Scene_Objects();
          //object=objects[i];
          object->ObjectIndx=j;
          object->ObjectId=3;
          object->ObjectStrtPnt=elleps[j]->getStartPnt();
          object->ObjectEndPnt=elleps[j]->getEndPnt();
          object->rotation=elleps[j]->item->rotation();
          object->setpen(elleps[j]->getPen());
          object->setbrush(elleps[j]->getBrush());
          copy_objects.push_back(object);
        }
      }
    }
    for(int j=0;j<polygons.size();j++) {
      //if(objects[i]->ObjectStrtPnt==polygons[j]->item->boundingRect().topLeft())
      {
        if(polygons[j]->edge_items[0]->isVisible()) {
          Scene_Objects* object = new Scene_Objects();
          //object=objects[i];
          object->ObjectIndx=j;
          object->ObjectId=4;
          object->pnts=polygon->poly_pnts;
          object->rotation=polygons[j]->item->rotation();
          object->setpen(polygons[j]->getPen());
          object->setbrush(polygons[j]->getBrush());
          copy_objects.push_back(object);
        }
      }
    }
    for(int j=0;j<round_rects.size();j++) {
      //if(objects[i]->ObjectStrtPnt==round_rects[j]->getStartPnt())
      {
        if(round_rects[j]->Strt_Rect->isVisible()) {
          Scene_Objects* object = new Scene_Objects();
          //object=objects[i];
          object->ObjectIndx=j;
          object->ObjectId=5;
          object->ObjectStrtPnt=round_rects[j]->getStartPnt();
          object->ObjectEndPnt=round_rects[j]->getEndPnt();
          object->rotation=round_rects[j]->item->rotation();
          object->setpen(round_rects[j]->getPen());
          object->setbrush(round_rects[j]->getBrush());
          copy_objects.push_back(object);
        }
      }
    }
    for(int j=0;j<arcs.size();j++) {
      //if(objects[i]->ObjectStrtPnt==arcs[j]->getStartPnt())
      {
        if(arcs[j]->Strt_Rect->isVisible()) {
          Scene_Objects* object = new Scene_Objects();
          //object=objects[i];
          object->ObjectIndx=j;
          object->ObjectId=6;
          object->ObjectStrtPnt=arcs[j]->getStartPnt();
          object->ObjectEndPnt = arcs[j]->getEndPnt();
          object->pnts.push_back(arcs[j]->getCurvePnt());
          object->rotation=arcs[j]->item->rotation();
          object->setpen(arcs[j]->getPen());
          copy_objects.push_back(object);
        }
      }
    }
    for(int j=0;j<linearrows.size();j++) {
      //if(objects[i]->ObjectStrtPnt==linearrows[j]->getStartPnt())
      {
        if(linearrows[j]->Strt_Rect->isVisible()) {
          Scene_Objects* object = new Scene_Objects();
          //object=objects[i];
          object->ObjectIndx=j;
          object->ObjectId=7;
          object->ObjectStrtPnt=linearrows[j]->getMinPoint();
          object->ObjectEndPnt = linearrows[j]->getMaxPoint();
          object->rotation=linearrows[j]->item->rotation();
          object->setpen(linearrows[j]->getPen());
          copy_objects.push_back(object);
        }
      }
    }
    for(int j=0;j<triangles.size();j++) {
      //if(objects[i]->ObjectStrtPnt==triangles[j]->getStartPnt())
      {
        if(triangles[j]->Strt_Rect->isVisible()) {
          Scene_Objects* object = new Scene_Objects();
          //object=objects[i];
          object->ObjectIndx=j;
          object->ObjectId=8;
          object->ObjectStrtPnt = triangles[j]->getStartPnt();
          object->ObjectEndPnt = triangles[j]->getEndPnt();
          object->pnts.push_back(QPointF(triangles[j]->getStartPnt()));
          object->pnts.push_back(QPointF(triangles[j]->getEndPnt()));
          object->pnts.push_back(QPointF(triangles[j]->getHeightPnt()));
          object->rotation=triangles[j]->item->rotation();
          object->setpen(triangles[j]->getPen());
          object->setbrush(triangles[j]->getBrush());
          copy_objects.push_back(object);
        }
      }
    }
    for(int j=0;j<arrows.size();j++) {
      //if(objects[i]->ObjectStrtPnt==arrows[j]->getStartPnt())
      {
        if(arrows[j]->Strt_Rect->isVisible()) {
          Scene_Objects* object = new Scene_Objects();
          //object=objects[i];
          object->ObjectIndx=j;
          object->ObjectId=9;
          object->ObjectStrtPnt=arrows[j]->getStartPnt();
          object->ObjectStrtPnt=arrows[j]->getEndPnt();
          object->pnts=arrows[j]->arrow_pnts;
          object->rotation=arrows[j]->item->rotation();
          object->setpen(arrows[j]->getPen());
          object->setbrush(arrows[j]->getBrush());
          copy_objects.push_back(object);
        }
      }
    }
  }
}


void Graph_Scene::writeToImage(QPainter *painter,QString &text,QPointF point) {
  selectedObjects();

  for(int i=0;i<getObjects().size();i++) {
    if(getObjects().at(i)->ObjectId==1) {
      this->lines[getObjects().at(i)->ObjectIndx]->drawImage(painter,text,point);
    }
    if(getObjects().at(i)->ObjectId==2) {
      this->rects[getObjects().at(i)->ObjectIndx]->drawImage(painter,text,point);
    }
    if(getObjects().at(i)->ObjectId==3) {
      this->elleps[getObjects().at(i)->ObjectIndx]->drawImage(painter,text,point);
    }
    if(getObjects().at(i)->ObjectId==4) {
      this->polygons[getObjects().at(i)->ObjectIndx]->drawImage(painter,text,point);
    }
    if(getObjects().at(i)->ObjectId==5) {
      this->round_rects[getObjects().at(i)->ObjectIndx]->drawImage(painter,text,point);
    }
    if(getObjects().at(i)->ObjectId==6) {
      this->arcs[getObjects().at(i)->ObjectIndx]->drawImage(painter,text,point);
    }
    if(getObjects().at(i)->ObjectId==7) {
      this->linearrows[getObjects().at(i)->ObjectIndx]->drawImage(painter,text,point);
    }
    if(getObjects().at(i)->ObjectId==8) {
      this->triangles[getObjects().at(i)->ObjectIndx]->drawImage(painter,text,point);
    }
    if(getObjects().at(i)->ObjectId==9) {
      this->arrows[getObjects().at(i)->ObjectIndx]->drawImage(painter,text,point);
    }
  }
  //qDebug()<<"text "<<text<<"\n";
}

void Graph_Scene::getSelectedShapeProperties(QPen &shapePen,QBrush &shapeBrush) {
  if(arc && arc->getMode() && arc->getState()==3) {
    shapePen = arc->getPen();
  }
  if(arrow && arrow->getMode() && arrow->getState()==3) {
    shapePen = arrow->getPen();
    shapeBrush = arrow->getBrush();
  }
  if(linearrow && linearrow->getMode() && linearrow->getState()==3) {
    shapePen = linearrow->getPen();
  }
  if(line && line->getPolyLineDrawn() && line->getState()==2) {
    shapePen = line->getPen();
  }
  if(rect && rect->getMode() && rect->getState()==3) {
    shapePen = rect->getPen();
    shapeBrush = rect->getBrush();
  }
  if(round_rect && round_rect->getMode() && round_rect->getState()==3) {
    shapePen = round_rect->getPen();
    shapeBrush = round_rect->getBrush();
  }
  if(round_rect && round_rect->getMode() && round_rect->getState()==3) {
    shapePen = round_rect->getPen();
    shapeBrush = round_rect->getBrush();
  }
  if(ellep && ellep->getMode() && ellep->getState()==3) {
    shapePen = ellep->getPen();
    shapeBrush = ellep->getBrush();
  }
  if(polygon && polygon->getPolygonDrawn() && polygon->getState()==2) {
    shapePen = polygon->getPen();
    shapeBrush = polygon->getBrush();
  }
  if(triangle && triangle->getMode() && triangle->getState()==3) {
    shapePen = triangle->getPen();
    shapeBrush = triangle->getBrush();
  }
}

void Graph_Scene::deleteShapes() {
  if(objectToDraw==10) {
    if (text) {
      removeItem(text->item);
      removeItem(text->Strt_Rect);
      removeItem(text->End_Rect);
      removeItem(text->Rot_Rect);
      objectToDraw = 0;
      if(!rects.isEmpty()) {
        for(int i=0;i<texts.size();i++) {
          if(texts[i]->getStartPnt()==text->getStartPnt()) {
            texts.remove(i);
            break;
          }
        }
      }
      if(!objects.isEmpty()) {
        for(int i=0;i<objects.size();i++) {
          if(objects[i]->ObjectStrtPnt==text->getStartPnt()) {
              objects.remove(i);
              break;
            }
          }
        }
        text=NULL;
    }
  }
  if(objectToEdit!=0) {
    if(line && (objectToEdit==1)&&(line->getPolyLineDrawn())) {
      removeItem(line->item);
      for(int i=0;i<line->edge_items.size();i++) {
        removeItem(line->edge_items[i]);
      }
      removeItem(line->Rot_Rect);
      objectToEdit=0;
      if(!lines.isEmpty()) {
        for(int i=0;i<lines.size();i++) {
          if(lines[i]->item==line->item) {
            lines.remove(i);
            break;
          }
        }
      }
      if(!objects.isEmpty()) {
        for(int i=0;i<objects.size();i++) {
          if(objects[i]->ObjectStrtPnt==line->item->boundingRect().topLeft()) {
            objects.remove(i);
            break;
          }
        }
      }
      line=NULL;
    }
    if(rect && (objectToEdit==2)&&(rect->getMode())) {
      removeItem(rect->item);
      removeItem(rect->Strt_Rect);
      removeItem(rect->End_Rect);
      removeItem(rect->Rot_Rect);
      objectToEdit=0;
      if(!rects.isEmpty()) {
        for(int i=0;i<rects.size();i++) {
          if(rects[i]->getStartPnt()==rect->getStartPnt()) {
            rects.remove(i);
            break;
          }
        }
      }
      if(!objects.isEmpty()) {
        for(int i=0;i<objects.size();i++) {
          if(objects[i]->ObjectStrtPnt==rect->getStartPnt()) {
              objects.remove(i);
              break;
            }
          }
        }
        rect=NULL;
      }
      if(ellep && (objectToEdit==3)&&(ellep->getMode())) {
        removeItem(ellep->item);
        removeItem(ellep->Strt_Rect);
        removeItem(ellep->End_Rect);
        removeItem(ellep->Rot_Rect);
        objectToEdit=0;
        if(!elleps.isEmpty()) {
          for(int i=0;i<elleps.size();i++) {
            if(elleps[i]->getStartPnt()==ellep->getStartPnt()) {
              elleps.remove(i);
              break;
            }
          }
        }
        if(!objects.isEmpty()) {
          for(int i=0;i<objects.size();i++) {
            if(objects[i]->ObjectStrtPnt==ellep->getStartPnt()) {
              objects.remove(i);
              break;
            }
          }
        }
        ellep=NULL;
      }
      if(polygon && (objectToEdit==4)&&(polygon->getPolygonDrawn())) {
        removeItem(polygon->item);
        for(int i=0;i<polygon->edge_items.size();i++) {
          removeItem(polygon->edge_items[i]);
        }
        removeItem(polygon->Rot_Rect);
        objectToEdit=0;
        if(!polygons.isEmpty()) {
          for(int i=0;i<polygons.size();i++) {
            if(polygons[i]->item==polygon->item) {
              polygons.remove(i);
              break;
            }
          }
        }
        if(!objects.isEmpty()) {
          for(int i=0;i<objects.size();i++) {
            if(objects[i]->ObjectStrtPnt==polygon->item->boundingRect().topLeft()) {
              objects.remove(i);
              break;
            }
          }
        }
        polygon=NULL;
      }
      if(round_rect && (objectToEdit==5)&&(round_rect->getMode())) {
        removeItem(round_rect->item);
        removeItem(round_rect->Strt_Rect);
        removeItem(round_rect->End_Rect);
        removeItem(round_rect->Rot_Rect);
        objectToEdit=0;
        if(!round_rects.isEmpty()) {
          for(int i=0;i<round_rects.size();i++) {
            if(round_rects[i]->getStartPnt()==round_rect->getStartPnt()) {
              round_rects.remove(i);
              break;
            }
          }
        }
        if(!objects.isEmpty()) {
          for(int i=0;i<objects.size();i++) {
            if(objects[i]->ObjectStrtPnt==round_rect->getStartPnt()) {
              objects.remove(i);
              break;
            }
          }
        }
        round_rect=NULL;
      }
      if(arc && (objectToEdit==6)&&(arc->getMode())) {
        removeItem(arc->item);
        removeItem(arc->Strt_Rect);
        removeItem(arc->End_Rect);
        removeItem(arc->Curve_Rect);
        removeItem(arc->Rot_Rect);
        removeItem(arc->Bounding_Rect);
        objectToEdit=0;
        if(!arcs.isEmpty()) {
          for(int i=0;i<arcs.size();i++) {
            if(arcs[i]->item==arc->item) {
              arcs.remove(i);
              break;
            }
          }
        }
        if(!objects.isEmpty()) {
          for(int i=0;i<objects.size();i++) {
            if(objects[i]->ObjectStrtPnt==arc->item->boundingRect().bottomLeft()) {
              objects.remove(i);
              break;
            }
          }
        }
        arc=NULL;
      }
      if(linearrow && (objectToEdit==7)&&(linearrow->getMode())) {
        removeItem(linearrow->item);
        removeItem(linearrow->Strt_Rect);
        removeItem(linearrow->End_Rect);
        removeItem(linearrow->Rot_Rect);
        objectToEdit=0;
        if(!linearrows.isEmpty()) {
          for(int i=0;i<linearrows.size();i++) {
            if(linearrows[i]->item==linearrow->item) {
              linearrows.remove(i);
              break;
            }
          }
        }
        if(!objects.isEmpty()) {
          for(int i=0;i<objects.size();i++) {
            if(objects[i]->ObjectStrtPnt==linearrow->getStartPnt()) {
              objects.remove(i);
              break;
            }
          }
        }
        linearrow=NULL;
      }
      if(triangle && (objectToEdit==8)&&(triangle->getMode())) {
        removeItem(triangle->item);
        removeItem(triangle->Strt_Rect);
        removeItem(triangle->End_Rect);
        removeItem(triangle->Height_Rect);
        removeItem(triangle->Rot_Rect);
        removeItem(triangle->Bounding_Rect);
        objectToEdit=0;
        if(!triangles.isEmpty()) {
          for(int i=0;i<triangles.size();i++) {
            if(triangles[i]->item==triangle->item) {
              triangles.remove(i);
              break;
            }
          }
        }
        if(!objects.isEmpty()) {
          for(int i=0;i<objects.size();i++) {
            if(!objects[i]->pnts.isEmpty()) {
              //qDebug()<<"coords "<<objects[i]->pnts[0]<<"  "<<triangle->getStartPnt()<<"\n";
              if(objects[i]->pnts[0]==triangle->getStartPnt()) {
                objects.remove(i);
                break;
              }
            }
          }
        }
        triangle=NULL;
      }
     if(arrow && (objectToEdit==9)&&(arrow->getMode())) {
      removeItem(arrow->item);
      removeItem(arrow->Strt_Rect);
      removeItem(arrow->End_Rect);
      removeItem(arrow->Rot_Rect);
      removeItem(arrow->Bounding_Rect);
      objectToEdit=0;
      if(!arrows.isEmpty()) {
        for(int i=0;i<arrows.size();i++) {
          if(arrows[i]->item==arrow->item) {
            arrows.remove(i);
            break;
          }
        }
      }
      if(!objects.isEmpty()) {
        for(int i=0;i<objects.size();i++) {
          if(objects[i]->ObjectStrtPnt==arrow->getStartPnt()) {
            objects.remove(i);
            break;
          }
        }
      }
      arrow=NULL;
    }
  }
}
