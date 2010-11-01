#include "Tools.h"
#include "Shapes.h"


Tools::Tools(Document *document1,DocumentView *doc1):document(document1),doc_view(doc1)
{


    fileMenu = new QMenu;
    editMenu = new QMenu;
    toolMenu = new QMenu;


    tool_bar = new QToolBar();
    rect = new QToolButton();
    hlayout = new QHBoxLayout;
    main_widget = new QWidget;
    file_dialog = new QFileDialog(this,"Open","c:",".txt");

    //message Box
    msg = new QMessageBox(this);
    msg_save = new QPushButton;
    msg_dnt_save = new QPushButton;
    msg_cancle = new QPushButton;

	edit=false;
	isSaved=false;

    //if(application =="Sketch")
    {
        scene = new Graph_Scene;
        view = new QGraphicsView(scene);
        scene->setSceneRect(0,0,1200,800);
        hlayout->addWidget(view);
        main_widget->setLayout(hlayout);
        setCentralWidget(main_widget);
        if(file_name!=NULL)
        {
           scene->open_Scene(file_name);
        }
    }


    /*if(application =="Text")
    {
        textEdit = new QTextEdit;
        openFile();
        setCentralWidget(textEdit);
    }*/
	
    button_action();
    menu();

    msg->setText("Do you want to save file.");
    msg_save=msg->addButton("Save",QMessageBox::AcceptRole);
    msg_dnt_save=msg->addButton("Don't Save",QMessageBox::AcceptRole);
    msg_cancle=msg->addButton("Cancel",QMessageBox::AcceptRole);
	
	
    filenames.clear();
	onbfilenames.clear();
	imagefilenames.clear();
	positions.clear();
	texts.clear();
	cellIds.clear();
}

void Tools::button_action()
{

  arc = new QAction(QIcon("C:/Users/RJhansiR/Develop/OpenModelica/OMNotebook/OMNotebookQT4/Resources/sketchIcons/qpainter-arc.png"),tr("&Arc"),this);
  connect(arc,SIGNAL(triggered()), this, SLOT(draw_arc()));

  line = new QAction(QIcon("C:/Users/RJhansiR/Develop/OpenModelica/OMNotebook/OMNotebookQT4/Resources/sketchIcons/qpainter-line.png"),tr("&Line"),this);
  connect(line,SIGNAL(triggered()), this, SLOT(draw_line()));

  rectangle = new QAction(QIcon("C:/Users/RJhansiR/Develop/OpenModelica/OMNotebook/OMNotebookQT4/Resources/sketchIcons/qpainter-rectangle.png"),tr("&Rectangle"),this);
  connect(rectangle,SIGNAL(triggered()), this, SLOT(draw_rect()));

  round_rectangle = new QAction(QIcon("C:/Users/RJhansiR/Develop/OpenModelica/OMNotebook/OMNotebookQT4/Resources/sketchIcons/qpainter-roundrect.png"),tr("&Rounded Rectangle"),this);
  connect(round_rectangle,SIGNAL(triggered()), this, SLOT(draw_round_rect()));

  ellipse = new QAction(QIcon("C:/Users/RJhansiR/Develop/OpenModelica/OMNotebook/OMNotebookQT4/Resources/sketchIcons/qpainter-ellipse.png"),tr("&Ellipse"),this);
  connect(ellipse,SIGNAL(triggered()), this, SLOT(draw_ellipse()));

  polyline = new QAction(QIcon("C:/Users/RJhansiR/Develop/OpenModelica/OMNotebook/OMNotebookQT4/Resources/sketchIcons/qpainter-polygon.png"),tr("&Polygon"),this);
  connect(polyline,SIGNAL(triggered()), this, SLOT(draw_polyline()));


  file_new = new QAction(tr("&New"),this);
  connect(file_new,SIGNAL(triggered()), this, SLOT(draw_new()));

  file_open = new QAction(tr("&Open"),this);
  connect(file_open,SIGNAL(triggered()), this, SLOT(draw_open()));

  file_save = new QAction(tr("&Save"),this);
  connect(file_save,SIGNAL(triggered()), this, SLOT(draw_save()));

  file_xml_save = new QAction(tr("&Save_Xml"),this);
  connect(file_xml_save,SIGNAL(triggered()), this, SLOT(draw_xml_save()));

  file_image_save = new QAction(tr("&Export Image"),this);
  connect(file_image_save,SIGNAL(triggered()), this, SLOT(draw_image_save()));

  shapes = new QAction(tr("&Shapes"),this);
  connect(shapes,SIGNAL(triggered()), this, SLOT(draw_shapes()));

  copy = new QAction(tr("&Copy"),this);
  copy->setShortcut(tr("Ctrl+C"));
  connect(copy,SIGNAL(triggered()), this, SLOT(draw_copy()));

  cut = new QAction(tr("&Cut"),this);
  cut->setShortcut(tr("Ctrl+x"));
  connect(cut,SIGNAL(triggered()), this, SLOT(draw_cut()));

  paste = new QAction(tr("&Paste"),this);
  paste->setShortcut(tr("Ctrl+v"));
  connect(paste,SIGNAL(triggered()), this, SLOT(draw_paste()));


}

void Tools::action()
{

    /*rect->addAction(rectangle);
    rect->addAction(line);
    rect->addAction(ellipse);
    rect->addAction(new_scene);
    rect->addAction(save_scene);
    rect->addAction(open_scene);*/

}

void Tools::draw_arc()
{
    scene->setObject(6);
}

void Tools::draw_rect()
{
    scene->setObject(2);
}

void Tools::draw_round_rect()
{
    scene->setObject(5);
}


void Tools::draw_line()
{
   scene->setObject(1);
}


void Tools::draw_ellipse()
{
    scene->setObject(3);
}

void Tools::draw_polyline()
{
    scene->setObject(4);
}


void Tools::draw_new()
{

    msg->exec();


    if(msg->clickedButton()==msg_save)
    {
        QString file_name=file_dialog->getSaveFileName(this,"Save","c:","*.txt");
        file_dialog->deleteLater();
        scene->save_Scene(file_name);
        scene->new_Scene();
    }

    if(msg->clickedButton()==msg_dnt_save)
    {
        scene->new_Scene();
    }

    //scene->new_Scene();

}

void Tools::draw_save()
{

    //if(application=="Sketch")
    {
       while(!isSaved)
	   {
	      int opt=QMessageBox::question(this,"Save file","Save File",QMessageBox::Yes | QMessageBox::Default, QMessageBox::No,  QMessageBox::Cancel);
		  if(opt==QMessageBox::No)
			  break;
		  else if(opt==QMessageBox::Yes)
		  {
		
			  QString file_name=file_dialog->getSaveFileName(this,"Save","c:","*.txt");
			  scene->save_Scene(file_name);
			  isSaved=true;
		  } 
		  else if(opt == QMessageBox::Cancel)
		  {
			 break;
		  }
	   }
    }

    /*if(application=="Text")
    {
        QFile fd(this->file_name);
        QTextStream out(&fd);
        fd.open(QFile::WriteOnly);
        file_dialog->deleteLater();
        QApplication::setOverrideCursor(Qt::WaitCursor);
        out<<textEdit->toPlainText();
        QApplication::restoreOverrideCursor();
        fd.close();

        QPointF minPos,maxPos;

        Graph_Scene *scene = new Graph_Scene;
        scene->open_Scene(file_name);

        QVector<QPointF> objectsPos;
        objectsPos.clear();
        scene->getObjectsPos(objectsPos);
        scene->getDim();
        scene->getMinPosition(minPos);
        scene->getMaxPosition(maxPos);
        qDebug()<<"objectsPos size"<<objectsPos.size();

        qDebug()<<"min pos "<<minPos<<"\n";

        QPointF pnt,pnt1;

        QImage *image = new QImage(scene->getDim().x()+3, scene->getDim().y()+3, QImage::Format_ARGB32_Premultiplied);
        image->fill(qRgb(255,255,255));

        QPainter *p = new QPainter(image);

        for(int i=0;i<scene->getObjects().size();i++)
        {
           if(scene->getObjects().at(i)->ObjectId==1)
           {

               pnt.setX(scene->getObjects().at(i)->ObjectStrtPnt.x()-minPos.x());
               pnt.setY(scene->getObjects().at(i)->ObjectStrtPnt.y()-minPos.y());

               pnt1.setX((scene->getObjects().at(i)->ObjectEndPnt.x()-minPos.x())-(scene->getObjects().at(i)->ObjectStrtPnt.x()-minPos.x()));
               pnt1.setY((scene->getObjects().at(i)->ObjectEndPnt.y()-minPos.y())-(scene->getObjects().at(i)->ObjectStrtPnt.y()-minPos.y()));

               p->drawLine(pnt.x(),pnt.y(),pnt1.x(),pnt1.y());

           }

           if(scene->getObjects().at(i)->ObjectId==2)
           {

              pnt.setX(scene->getObjects().at(i)->ObjectStrtPnt.x()-minPos.x());
              pnt.setY(scene->getObjects().at(i)->ObjectStrtPnt.y()-minPos.y());

              pnt1.setX((scene->getObjects().at(i)->ObjectEndPnt.x()-minPos.x())-(scene->getObjects().at(i)->ObjectStrtPnt.x()-minPos.x()));
              pnt1.setY((scene->getObjects().at(i)->ObjectEndPnt.y()-minPos.y())-(scene->getObjects().at(i)->ObjectStrtPnt.y()-minPos.y()));


              p->drawRect(pnt.x(),pnt.y(),pnt1.x(),pnt1.y());

           }

           if(scene->getObjects().at(i)->ObjectId==3)
           {

               pnt.setX(scene->getObjects().at(i)->ObjectStrtPnt.x()-minPos.x());
               pnt.setY(scene->getObjects().at(i)->ObjectStrtPnt.y()-minPos.y());

               pnt1.setX((scene->getObjects().at(i)->ObjectEndPnt.x()-minPos.x())-(scene->getObjects().at(i)->ObjectStrtPnt.x()-minPos.x()));
               pnt1.setY((scene->getObjects().at(i)->ObjectEndPnt.y()-minPos.y())-(scene->getObjects().at(i)->ObjectStrtPnt.y()-minPos.y()));


               p->drawEllipse(pnt.x(),pnt.y(),pnt1.x(),pnt1.y());

           }

           if(scene->getObjects().at(i)->ObjectId==5)
           {

               pnt.setX(scene->getObjects().at(i)->ObjectStrtPnt.x()-minPos.x());
               pnt.setY(scene->getObjects().at(i)->ObjectStrtPnt.y()-minPos.y());

               pnt1.setX((scene->getObjects().at(i)->ObjectEndPnt.x()-minPos.x())-(scene->getObjects().at(i)->ObjectStrtPnt.x()-minPos.x()));
               pnt1.setY((scene->getObjects().at(i)->ObjectEndPnt.y()-minPos.y())-(scene->getObjects().at(i)->ObjectStrtPnt.y()-minPos.y()));

               p->drawRoundedRect(pnt.x(),pnt.y(),pnt1.x(),pnt1.y(),15,15,Qt::AbsoluteSize);

           }

        }

        p->end();
        // Save it..
        image->save("C:/Users/rjhansir/Desktop/png.png","PNG");
    }*/

}

void Tools::draw_open()
{
    QString file_name=file_dialog->getOpenFileName(this,"Open","c:","*.xml");
    scene->open_Scene(file_name);
	edit=true;
}

void Tools::draw_xml_save()
{
    QString file_name=file_dialog->getSaveFileName(this,"Save","c:","*.xml");
    scene->save_xml_Scene(file_name);
}

void Tools::draw_image_save()
{
    QRgb rgb;
    QVector<QPointF> objectsPos;
    QPointF minPos,maxPos;
    objectsPos.clear();
   
    scene->getObjectsPos(objectsPos);
    scene->getMinPosition(minPos);
    scene->getMaxPosition(maxPos);

	QPointF pnt,pnt1;

    QImage *image = new QImage(scene->getDim().x()+1, scene->getDim().y()+1, QImage::Format_ARGB32_Premultiplied);
    image->fill(qRgb(255,255,255));

    QPainter *p = new QPainter(image);

    for(int i=0;i<scene->getObjects().size();i++)
    {
       if(scene->getObjects().at(i)->ObjectId==1)
       {

          p->drawLine(scene->getObjects().at(i)->ObjectStrtPnt.x(),scene->getObjects().at(i)->ObjectStrtPnt.y(),scene->getObjects().at(i)->ObjectEndPnt.x(),scene->getObjects().at(i)->ObjectEndPnt.y());

       }

       if(scene->getObjects().at(i)->ObjectId==2)
       {

          p->drawRect(scene->getObjects().at(i)->ObjectStrtPnt.x(),scene->getObjects().at(i)->ObjectStrtPnt.y(),scene->getObjects().at(i)->ObjectEndPnt.x()-scene->getObjects().at(i)->ObjectStrtPnt.x(),scene->getObjects().at(i)->ObjectEndPnt.y()-scene->getObjects().at(i)->ObjectStrtPnt.y());

       }

       if(scene->getObjects().at(i)->ObjectId==3)
       {
		   p->drawEllipse(scene->getObjects().at(i)->ObjectStrtPnt.x(),scene->getObjects().at(i)->ObjectStrtPnt.y(),scene->getObjects().at(i)->ObjectEndPnt.x()-scene->getObjects().at(i)->ObjectStrtPnt.x(),scene->getObjects().at(i)->ObjectEndPnt.y()-scene->getObjects().at(i)->ObjectStrtPnt.y());

       }

       if(scene->getObjects().at(i)->ObjectId==5)
       {

           p->drawRoundedRect(scene->getObjects().at(i)->ObjectStrtPnt.x(),scene->getObjects().at(i)->ObjectStrtPnt.y(),scene->getObjects().at(i)->ObjectEndPnt.x()-scene->getObjects().at(i)->ObjectStrtPnt.x(),scene->getObjects().at(i)->ObjectEndPnt.y()-scene->getObjects().at(i)->ObjectStrtPnt.y(),15,15,Qt::AbsoluteSize);

       }

    }

    p->end();

	if(edit==false)
	{
	   QString num;

	   filenames.push_back("C:/Users/RJhansiR/Develop/OpenModelica/OMNotebook/Sketch1/XmlFiles/png"+num.number(filenames.size())+".xml");
	
    
       
	    

	    QSize size;
	    QString num1;

	    size.setWidth(image->width());
	    size.setHeight(image->height());
	    document->attach(doc_view);
	    QTextEdit *editor = new QTextEdit();
	    QTextImageFormat imageformat;
	    QTextCursor cursor = document->getCursor()->currentCell()->textCursor();

		
	    QPointF currntPos=document->getCursor()->mPoint;
	
	    if(!cursor.isNull())
	    {
		    QString imagename = document->addImage( image );
			imagefilenames.push_back(imagename);
		    editor = document->getCursor()->currentCell()->textEdit();
			
		    if( editor )
		    {
			    // save text settings and set them after image have been inserted
			    QTextCharFormat format = cursor.charFormat();
			    if( editor->toPlainText().isEmpty() )
					format = *document->getCursor()->currentCell()->style()->textCharFormat();
								    			    
					imageformat.merge( format );
					imageformat.setHeight( image->height());
					imageformat.setWidth( image->width());
					imageformat.setName( imagename );
					
					cursor.insertImage( imageformat );
	  	    }
		
	     }

		 int id;
		 getCellId(document->getCursor()->currentCell(),id);
		 positions.push_back(num.number(document->getCursor()->currentCell()->textCursor().position()));
		 texts.push_back(document->getCursor()->currentCell()->text());
		 cellIds.push_back(num.number(id));
		 	     
	 } 

	 if(edit==true)
	 {
        QSize size;
	    QString num1;

	    size.setWidth(image->width());
	    size.setHeight(image->height());
	    document->attach(doc_view);
	    QTextEdit *editor = new QTextEdit();
	    QTextImageFormat imageformat;
		QTextCursor cursor = document->getCursor()->currentCell()->textCursor();
		document->getCursor()->currentCell()->textCursor().deletePreviousChar();
		document->getCursor()->currentCell()->textCursor().setPosition(cursor.position()-1);

		QPointF currntPos=document->getCursor()->mPoint;
	
	    if(!cursor.isNull())
	    {
			QString imagename = document->addImage(image);
		    editor = document->getCursor()->currentCell()->textEdit();
		
		    if( editor )
		    {
			    // save text settings and set them after image have been inserted
			    QTextCharFormat format = cursor.charFormat();
			    if( editor->toPlainText().isEmpty() )
		    		 format = *document->getCursor()->currentCell()->style()->textCharFormat();

					imageformat.merge( format );
					imageformat.setHeight( image->height());
					imageformat.setWidth( image->width());
					imageformat.setName( imagename );
										
					cursor.insertImage( imageformat );
			}
		
	     }
	 }


 }


void Tools::SaveSketchImage()
{
	 writeXml();
	 QFile fd1("C:/Users/RJhansiR/Develop/OpenModelica/OMNotebook/Sketch1/XmlFiles/files.xml");//It is a datafile from which we are taking the data
     QXmlStreamWriter xw1(&fd1);	
	 if(fd1.exists())
	 {
        fd1.open(QFile::WriteOnly);//checks whther the file is open or not
        xw1.setAutoFormatting(true);
        xw1.writeStartDocument();
        xw1.writeStartElement("Files");
	 }
	 else
	 {
        fd1.open(QFile::WriteOnly);//checks whther the file is open or not
        xw1.setAutoFormatting(true);
        xw1.writeStartDocument();
        xw1.writeStartElement("Files");
	 }

     if(filenames.size()==0)
	 {
		 QMessageBox::about(this,"files size","files name empty");
	 }

	 for(int i=0;i<filenames.size();i++)
     {
		  xw1.writeTextElement("FileName",filenames[i]);
		  xw1.writeTextElement("OnbFileName",onbfilenames[i]);
		  xw1.writeTextElement("ImageFileName",imagefilenames[i]);
		  xw1.writeTextElement("Position",(positions[i]));
		  xw1.writeTextElement("Text",texts[i]);
		  xw1.writeTextElement("CellId",cellIds[i]);
	 }
	   
     xw1.writeEndElement();
     xw1.writeEndDocument();
 }

void Tools::readXml()
{
	QFile fd("C:/Users/RJhansiR/Develop/OpenModelica/OMNotebook/Sketch1/XmlFiles/files.xml");//It is a datafile from which we are taking the data
	fd.open(QFile::ReadWrite);
	QXmlStreamReader xr(&fd);

	bool ok;
	
	QString num;
	while(!xr.atEnd())
	{
	   if(xr.name()=="FileName")
	   {
			
		  num=(QString)xr.readElementText(QXmlStreamReader::IncludeChildElements);
		  filenames.push_back(num);
	
	   }

	   if(xr.name()=="OnbFileName")
	   {
			
		  num=(QString)xr.readElementText(QXmlStreamReader::IncludeChildElements);
		  onbfilenames.push_back(num);
	   }

	   if(xr.name()=="ImageFileName")
	   {
			
		  num=(QString)xr.readElementText(QXmlStreamReader::IncludeChildElements);
		  imagefilenames.push_back(num);
	   }

	   if(xr.name()=="Position")
	   {	
		  num=(QString)xr.readElementText(QXmlStreamReader::IncludeChildElements);
		  positions.push_back(num);
	   }

	   if(xr.name()=="Text")
	   {
		  num=(QString)xr.readElementText(QXmlStreamReader::IncludeChildElements);
		  texts.push_back(num);
	   }

	   if(xr.name()=="CellId")
	   {
		  num=(QString)xr.readElementText(QXmlStreamReader::IncludeChildElements);
		  cellIds.push_back(num);
	   }

	   xr.readNext();
	}
}

 void Tools::writeXml()
 {
       QString str_x,str_y,str_x1,str_y1;

	   for(int i=0;i<filenames.size();i++)
	   {
	      //writing the object contents to xml
 	      QFile fd(filenames[i]);//It is a datafile from which we are taking the data
          fd.open(QFile::WriteOnly);//checks whther the file is open or not

		  QXmlStreamWriter xw(&fd);
          xw.setAutoFormatting(true);
          xw.writeStartDocument();
          xw.writeStartElement("Object");
          for(int i=0;i<scene->getObjects().size();i++)
          {
              if(scene->getObjects().at(i)->ObjectId==1)
              {
                 xw.writeTextElement("Type","Line");
              }

              if(scene->getObjects().at(i)->ObjectId==2)
              {
                 xw.writeTextElement("Type","Rectangle");
              }

              if(scene->getObjects().at(i)->ObjectId==3)
              {
                 xw.writeTextElement("Type","Ellipse");
              }

              if(scene->getObjects().at(i)->ObjectId==5)
              {
                 xw.writeTextElement("Type","RoundRect");
              }

              xw.writeTextElement("Dim"," "+str_x.setNum((scene->getObjects().at(i)->ObjectStrtPnt.x()))+" "+str_y.setNum((scene->getObjects().at(i)->ObjectStrtPnt.y()))+" "+str_x1.setNum((scene->getObjects().at(i)->ObjectEndPnt.x()))+" "+str_y1.setNum((scene->getObjects().at(i)->ObjectEndPnt.y()))+" ");

             }
             xw.writeEndElement();
             xw.writeEndDocument();
	   }
 }


void Tools::draw_copy()
{

    scene->copy_object();

}

void Tools::draw_cut()
{
    scene->cut_object();
}

void Tools::draw_paste()
{
    scene->paste_object();
}


void Tools::mousePressEvent(QMouseEvent *event)
{

}

void Tools::menu()
{
    fileMenu=menuBar()->addMenu(tr("&File"));
    fileMenu->addAction(file_new);
    fileMenu->addAction(file_open);
    fileMenu->addAction(file_save);
    fileMenu->addAction(file_xml_save);
    fileMenu->addAction(file_image_save);

    editMenu=menuBar()->addMenu(tr("&Edit"));
    editMenu->addAction(copy);
    editMenu->addAction(cut);
    editMenu->addAction(paste);

    toolMenu = menuBar()->addMenu(tr("&Tools"));
    toolMenu->addAction(shapes);



}

void Tools::draw_shapes()
{
    tool_bar->addAction(arc);
    tool_bar->addAction(line);
    tool_bar->addAction(rectangle);
    tool_bar->addAction(round_rectangle);
    tool_bar->addAction(ellipse);
    tool_bar->addAction(polyline);
    addToolBar(tool_bar);
    
}

void Tools::msg_save_file()
{
   qDebug()<<"Entered \n";
   QString file_name=file_dialog->getSaveFileName(this,"Save","c:","*.txt");
   file_dialog->deleteLater();
   scene->save_Scene(file_name);
   scene->new_Scene();

}

void Tools::msg_dnt_save_file()
{
    scene->new_Scene();
}


void Tools::openFile()
{
   QTextCursor cursor(textEdit->textCursor());

   QFile fd(this->file_name);//It is a datafile from which we are taking the data
   fd.open(QFile::ReadOnly);//checks whther the file is open r not
   QTextStream inputStream(&fd);//reads the data as streams i.e in bytes

   cursor.movePosition(QTextCursor::Start);
   cursor.beginEditBlock();
   while(!inputStream.atEnd())
   {
      cursor.insertText(inputStream.readLine()+"\n");
   }
   cursor.endEditBlock();

}

void Tools::open(const QString filename)
{
	file_name=filename;
	
	if(file_name!=NULL)
    {
       scene->open_Scene(file_name);
	   edit=true;
    }
}


void Tools::open()
{
	
	int id;
	QString str;

	getCellId(document->getCursor()->currentCell(),id);

	QMessageBox::about(this,"filename",str.number(id));

	QMessageBox::about(this,"filename",str.number(filenames.size()));
	

	for(int i=0;i<filenames.size();i++)
	{
		if((cellIds[i]==str.number(id))&&((onbfilenames[i])==document->getFilename()))
		{
			file_name=filenames[i];
			onb_file_name=onbfilenames[i];
			QMessageBox::about(this,"filename",file_name);
			break;
		}
	
	}

	if(file_name!=NULL)
    {
       scene->open_Scene(file_name);
	   edit=true;
    }
}


void Tools::getCells(const QVector<Cell*> cells)
{
	this->cells.clear();
	this->cells=cells;
}

void Tools::getCellId(const Cell* cell,int &id)
{
	 for(int i=0;i<cells.size();i++)
	 {
		if(cells[i]==cell)
		{
			id=i;
			break;
		}
	 }
}

void Tools::getFileName(const QString &FileName)
{
	
	for(int i=0;i<filenames.size();i++)
	     onbfilenames.push_back(FileName);
}



void Tools::closeEvent(QCloseEvent* event)
{
	while(!isSaved)
	{
	    int opt=QMessageBox::question(this,"Save file","File not saved, do you want to save",QMessageBox::Yes | QMessageBox::Default, QMessageBox::No,  QMessageBox::Cancel);
		if(opt==QMessageBox::No)
		    break;
		else if(opt==QMessageBox::Yes)
		{
	   	   QString file_name=file_dialog->getSaveFileName(this,"Save","c:","*.txt");
		   scene->save_Scene(file_name);
		   isSaved=true;
		} 
		else if(opt == QMessageBox::Cancel)
		{
			event->ignore();
			return;
		}
	 }
}