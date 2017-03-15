#include "Tools.h"


Tools::Tools(Document *document1,DocumentView *doc1):document(document1),doc_view(doc1)
{
    //
    fileMenu = new QMenu;
    editMenu = new QMenu;
    toolMenu = new QMenu;

    tool_bar1 = new QToolBar();
    tool_bar2 = new QToolBar();
    tool_bar3 = new QToolBar();
    tool_bar4 = new QToolBar();
    rect = new QToolButton();
    hlayout = new QVBoxLayout;
    main_widget = new QWidget;
    //file_dialog = new QFileDialog(this,"Open",QString(),".skh");

    color_dialog = new QColorDialog(this);

    files = new Sketch_Files();

    edit=false;
    isSaved=false;

    add_components();
    addToolBarBreak();

    statusBar = new QStatusBar();

    statusBar->showMessage("OMSketch");


    setStatusBar(statusBar);

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

    scene->isObjectEdited=false;

    /*if(application =="Text")
    {
        textEdit = new QTextEdit;
        openFile();
        setCentralWidget(textEdit);
    }*/

    button_action();
    menu();
    draw_shapes();

    filenames.clear();
    onbfilenames.clear();
    imagefilenames.clear();
    positions.clear();
    texts.clear();
    cellIds.clear();
    this->cells.clear();

    scene->new_Scene();

    drawn_images.clear();

    images_info.clear();
    documents_info.clear();
    edit_imgs_info.clear();
    file_read=false;

    itemSelected=false;
}

void Tools::button_action()
{
    arc = new QAction(QIcon(":/Resources/sketchIcons/qpainter-arc.svg"),tr("&Arc"),this);
    connect(arc,SIGNAL(triggered()), this, SLOT(draw_arc()));

    arrow = new QAction(QIcon(":/Resources/sketchIcons/arrow.svg"),tr("&Arrow"),this);
    connect(arrow,SIGNAL(triggered()), this, SLOT(draw_arrow()));

    line = new QAction(QIcon(":/Resources/sketchIcons/qpainter-line.svg"),tr("&Line"),this);
    connect(line,SIGNAL(triggered()), this, SLOT(draw_line()));

    rectangle = new QAction(QIcon(":/Resources/sketchIcons/qpainter-rectangle.svg"),tr("&Rectangle"),this);
    connect(rectangle,SIGNAL(triggered()), this, SLOT(draw_rect()));

    round_rectangle = new QAction(QIcon(":/Resources/sketchIcons/qpainter-roundrect.svg"),tr("&Rounded Rectangle"),this);
    connect(round_rectangle,SIGNAL(triggered()), this, SLOT(draw_round_rect()));

    ellipse = new QAction(QIcon(":/Resources/sketchIcons/qpainter-ellipse.svg"),tr("&Ellipse"),this);
    connect(ellipse,SIGNAL(triggered()), this, SLOT(draw_ellipse()));

    polygon = new QAction(QIcon(":/Resources/sketchIcons/qpainter-polygon.svg"),tr("&Polygon"),this);
    connect(polygon,SIGNAL(triggered()), this, SLOT(draw_polygon()));

    linearrow = new QAction(QIcon(":/Resources/sketchIcons/linearrow.svg"),tr("&LineArrow"),this);
    connect(linearrow,SIGNAL(triggered()), this, SLOT(draw_linearrow()));

    triangle = new QAction(QIcon(":/Resources/sketchIcons/triangle.svg"),tr("&Triangle"),this);
    connect(triangle,SIGNAL(triggered()), this, SLOT(draw_triangle()));

    text = new QAction(QIcon(":/Resources/sketchIcons/text.svg"),tr("&Text"),this);
    connect(text,SIGNAL(triggered()), this, SLOT(draw_text()));

    file_new = new QAction(tr("&New"),this);
    connect(file_new,SIGNAL(triggered()), this, SLOT(draw_new()));

    file_open = new QAction(tr("&Open"),this);
    connect(file_open,SIGNAL(triggered()), this, SLOT(draw_open()));

    file_save = new QAction(tr("&Save"),this);
    connect(file_save,SIGNAL(triggered()), this, SLOT(draw_save()));

    close_me = new QAction(tr("&Close"),this);
    close_me->setShortcut(QKeySequence("Ctrl+W"));
    connect(close_me,SIGNAL(triggered()), this, SLOT(close()));

    file_image_save = new QAction(tr("&Export Image"),this);
    connect(file_image_save,SIGNAL(triggered()), this, SLOT(draw_image_save()));

    copy = new QAction(tr("&Copy"),this);
    copy->setShortcut(QKeySequence("Ctrl+C"));
    connect(copy,SIGNAL(triggered()), this, SLOT(draw_copy()));

    cut = new QAction(tr("&Cut"),this);
    cut->setShortcut(QKeySequence("Ctrl+X"));
    connect(cut,SIGNAL(triggered()), this, SLOT(draw_cut()));

    paste = new QAction(tr("&Paste"),this);
    paste->setShortcut(QKeySequence("Ctrl+V"));
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

void Tools::draw_element(int id) {
  isSaved=false;
  if(!copy_shape->isEnabled())
    copy_shape->setDisabled(false);
  if(!cut_shape->isEnabled())
    cut_shape->setDisabled(false);
  if(!paste_shape->isEnabled())
    paste_shape->setDisabled(false);
  itemSelected=true;
  scene->hide_object_edges();
  enableProperties();
  reloadShapesProerties();
  scene->setObject(id);
}

void Tools::draw_arc() {
  draw_element(3);
  //select_pen->clear();
  //select_brush->clear();
  //penWidth->clear();
}

void Tools::draw_arrow() {
    QMessageBox::about(this,"Arrow","In Process");
    //in process
    //draw_element(9);
}

void Tools::draw_rect() {
  draw_element(2);
}

void Tools::draw_round_rect() {
  draw_element(5);
}

void Tools::draw_line() {
  draw_element(1);
}

void Tools::draw_linearrow() {
  draw_element(7);
}

void Tools::draw_ellipse() {
  draw_element(3);
}

void Tools::draw_polygon() {
  draw_element(4);
}

void Tools::draw_triangle() {
  draw_element(8);
}

void Tools::draw_text() {
  draw_element(10);
}

void Tools::draw_new()
{
  if(!isSaved) {
    int opt=QMessageBox::question(this,"Save file",tr("Do you want to save file."),QMessageBox::Yes | QMessageBox::Default, QMessageBox::No,  QMessageBox::Cancel);
    if(opt==QMessageBox::Cancel) {
      return;
    } else if(opt==QMessageBox::Yes) {
      QString file_name=QFileDialog::getSaveFileName(this,"Save",QString(),tr("Image(*.png)"));
      //file_dialog->deleteLater();
      if(file_name.contains(".png")) {
        writeImage(file_name);
      }
    }
  }

  scene->new_Scene();
  isSaved=true;
  statusBar->showMessage("New Scene");
}

void Tools::draw_save() {
    //if(application=="Sketch")
    {
        while(!isSaved)
        {
            int opt=QMessageBox::question(this,"Save file","Save File",QMessageBox::Yes | QMessageBox::Default, QMessageBox::No,  QMessageBox::Cancel);
            if(opt==QMessageBox::No)
                break;
            else if(opt==QMessageBox::Yes)
            {
                QString file_name=QFileDialog::getSaveFileName(this,"Save",QString(),tr("Image(*.png);;Image(*.jpg);;Images(*.bmp)"));

                QMessageBox::about(this,"file name ",file_name);
                writeImage(file_name);

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
    QString file_name=QFileDialog::getOpenFileName(this,"Open",QString(),"*.png *.jpg *.bmp" );

  if(!isSaved)
    draw_save();
  //else
      imageinfo(file_name);
  edit=true;
}


//exporting of image
void Tools::draw_image_save() {
    QDir dir;
    QVector<QPointF> objectsPos;
    QPointF minPos,maxPos;
    objectsPos.clear();
    QString text = QString();

    scene->getObjectsPos(objectsPos);

    // Debug output:
    //for(int i=0;i<scene->getObjects().size();i++)
    //  scene->getObjects().at(i)->print();

    QPointF pnt = scene->getDim();

    QImage *image = new QImage(pnt.x()+1, pnt.y()+1, QImage::Format_ARGB32_Premultiplied);
    image->fill(qRgb(255,255,255));

    scene->getMinPosition(minPos);
    scene->getMaxPosition(maxPos);

    QPainter *p = new QPainter(image);

    //writes the shapes to the image
    scene->writeToImage(p,text,-(minPos));

    document->attach(doc_view);
    QTextImageFormat imageformat;
    QTextCursor cursor = document->getCursor()->currentCell()->textCursor();

    QTextCharFormat format2 = cursor.charFormat();

    //p->end();
    isSaved=false;
    if(edit==false) {
        QString num;

        QSize size;
        QString num1;

        //copies the image and coordinates into image_info struct
        images.image = new QImage();
        images.image=image;

        size.setWidth(images.image->width());
        size.setHeight(images.image->height());

        //QMessageBox::about(this,"image text first export ",text);

        if(!cursor.isNull())
        {
            dir.setPath(dir.absolutePath()+"/OMNotebook_tempfiles");
            QString imagename="temp";
            //QString imagename="sketch_";
            imagename="OMSketchImage"+num.setNum(filenames.size()+1,10)+".png";
            images.imageName=dir.absolutePath() + "/" +imagename;
            imagename=images.imageName;
            filenames.push_back(imagename);
            imagename = QString("file:///") + imagename;
            //image->setText("Shapes",text);
            images.text=text;
            writeImage(images);
            //QMessageBox::about(this,"image name",images.imageName);
            imagefilenames.push_back(imagename);
            QTextEdit *editor = document->getCursor()->currentCell()->textEdit();

            if( editor )
            {
                // save text settings and set them after image have been inserted
                QTextCharFormat format = cursor.charFormat();
                if( editor->toPlainText().isEmpty() )
                    format = *document->getCursor()->currentCell()->style()->textCharFormat();
                format2 = *document->getCursor()->currentCell()->style()->textCharFormat();

                //qDebug()<<"images width and height "<<images.image->width()<<" "<<images.image->height()<<"\n";
                //qDebug()<<"image width and height "<<image->width()<<"  "<<image->height()<<"\n";

                imageformat.merge( format );
                imageformat.setHeight( images.image->height());
                imageformat.setWidth( images.image->width());
                imageformat.setName( imagename );

                cursor.insertImage( imageformat );
                statusBar->showMessage("Image Exported ",10000);
            }
        }
    } else { // edit==true
        QSize size;
        QString num1;

        if(!edit_imgs_info.isEmpty())
        {
            edit_img_info=edit_imgs_info[edit_imgs_info.size()-1];
        }

        if(edit_img_info.image)
        {
            //QMessageBox::about(this,"edit image info name ",edit_img_info.imageName);
            delete edit_img_info.image;
            edit_img_info.image=NULL;
        }
        edit_img_info.image = new QImage();
        edit_img_info.image=image;
        QString num;
        //image->setText("Shapes",text);
        //QMessageBox::about(this,"image text ",text);
        edit_img_info.text=text;

        //QMessageBox::about(this,"edit image info name ",edit_img_info.imageName);

        size.setWidth(image->width());
        size.setHeight(image->height());
        document->attach(doc_view);
        QTextImageFormat imageformat1;
        QTextCursor cursor = document->getCursor()->currentCell()->textCursor();
        document->getCursor()->currentCell()->textCursor().deletePreviousChar();
        document->getCursor()->currentCell()->textCursor().setPosition(cursor.position()-1);
        document->getCursor()->currentCell()->update();

        if(!cursor.isNull())
        {
            QString imagename = QFileInfo(edit_img_info.imageName).completeBaseName();
            imagename+=".png";
            if(imagename.contains("OMSketchImage"))
            {

                QMessageBox::about(this,"image",imagename);
                int strt_indx = imagename.lastIndexOf("e",-1);
                int end_indx = imagename.lastIndexOf(".",-1);

                QString sub = imagename.mid(strt_indx+1,(end_indx-strt_indx)-1);
                QMessageBox::about(this,"image name sub ",sub);
                bool ok;
                int pos = sub.toInt(&ok,10);
                pos+=1;

                imagename.remove(sub+".png");
                dir.setPath(dir.absolutePath()+"/OMNotebook_tempfiles");
                imagename="OMSketchImage";
                imagename+=num.number(pos);
                imagename=dir.absolutePath() + "/" +imagename;
                imagename+=".png";

                //dir.setPath(dir.absolutePath()+"/OMNotebook_tempfiles");
                //QString imagename="temp";
                //QString imagename="sketch_";
                //imagename="OMSketchImage"+num.setNum(filenames.size(),10)+".png";
                //imagename=dir.absolutePath() + "/" +imagename;

                edit_img_info.imageName=imagename;
            }

            else if(imagename.contains("png"))
            {
                int strt_indx = imagename.lastIndexOf("/",-1);
                int end_indx = imagename.lastIndexOf(".",-1);

                //QString sub=imagename.right(2);

                QString sub = imagename.mid(strt_indx+1,(end_indx-strt_indx)-1);
                QMessageBox::about(this,"image",sub);
                bool ok;
                int pos = sub.toInt(&ok,10);
                pos+=1;

                imagename.remove(sub+".png");

                dir.setPath(dir.absolutePath()+"/OMNotebook_tempfiles");
                imagename+="OMSketchImage";

                imagename+=num.number(pos);

                imagename+=".png";

                edit_img_info.imageName=imagename;
            }

            else
            {
                imagename.remove(".png");
                QString sub = imagename;
                //QMessageBox::about(this,"image",sub);
                bool ok;
                int pos = sub.toInt(&ok,10);
                //pos+=1;
                dir.setPath(dir.absolutePath()+"/OMNotebook_tempfiles");
                imagename="OMSketchImage";
                imagename=num.number(pos);

                imagename+=".png";

                dir.setPath(dir.absolutePath()+"/OMNotebook_tempfiles");
                QString imagename="temp";
                //QString imagename="sketch_";
                imagename="OMSketchImage"+num.setNum(filenames.size()+1,10)+".png";
                imagename=dir.absolutePath() + "/" +imagename;

                edit_img_info.imageName=imagename;
            }

            //QMessageBox::about(this,"image name after editing",edit_img_info.imageName);

            writeImage(edit_img_info);

            QTextEdit *editor = document->getCursor()->currentCell()->textEdit();
            if( editor )
            {
                // save text settings and set them after image have been inserted
                QMessageBox::about(this,"message ","Entered inserting image");
                qDebug()<<"image width and height "<<image->width()<<"  "<<image->height()<<"\n";
                qDebug()<<"imgae info image width and height "<<edit_img_info.image->width()<<"  "<<edit_img_info.image->height()<<"\n";
                QTextCharFormat format1 = cursor.charFormat();
                if( editor->toPlainText().isEmpty() )
                    format1 = *document->getCursor()->currentCell()->style()->textCharFormat();

                imageformat1.merge( format1 );
                imageformat1.setHeight( image->height());
                imageformat1.setWidth(  image->width());
                imageformat1.setName( edit_img_info.imageName );

                cursor.insertImage( imageformat1 );
                document->getCursor()->currentCell()->update();
                statusBar->showMessage("Image Exported ",10000);
            }
        }

        edit_imgs_info[edit_imgs_info.size()-1]=edit_img_info;
        edit=false;
    }
}


void Tools::SaveSketchImage(QString filename)
{
   if(!filenames.isEmpty()||!edit_imgs_info.isEmpty())
   {
        if(!edit_imgs_info.isEmpty())
      edit_imgs_info.clear();
    QFileInfo file_info(filename);

      filename=file_info.absolutePath();

    QFile fd1(filename+"/files.xml");//It is a datafile from which we are taking the data
    QXmlStreamWriter xw1(&fd1);
    fd1.open(QFile::WriteOnly);//checks whther the file is open or not
    xw1.setAutoFormatting(true);
    xw1.writeStartDocument();
    xw1.writeStartElement("Files");

    for(int i=0;i<documents_info.size();i++)
    {
      for(int j=0;j<documents_info[i].images_info.size();j++)
      {
        xw1.writeTextElement("FileName",documents_info[i].images_info[j].imageName);
        xw1.writeTextElement("OnbFileName",documents_info[i].onbFileName);
        xw1.writeTextElement("Position",documents_info[i].images_info[j].cursor_position);
        xw1.writeTextElement("Text",documents_info[i].images_info[j].cell_text);
        xw1.writeTextElement("CellId",documents_info[i].images_info[j].cellId);
      }
    }

    xw1.writeEndElement();
    xw1.writeEndDocument();
   }
 }

void Tools::readXml(QString file_name)
{
  QString file_name1=file_name;
  file_name1=QFileInfo(file_name1).absolutePath()+"/files.xml";
  QString num;

  //QMessageBox::about(this,"file path",file_name1);

  QVector<QString> filenames1,onbfilenames1,positions1,texts1,cellIds1;

  filenames1.clear();
  onbfilenames1.clear();
  positions1.clear();
  texts1.clear();
  cellIds1.clear();

  if(QFileInfo(file_name1).isFile()) {
    QFile fd(file_name1);//It is a data file from which we are taking the data
    fd.open(QFile::ReadWrite);
    QXmlStreamReader xr(&fd);

    bool ok;
     //QMessageBox::about(this,"entered","Entered reading files");
     QString num1;

     while(!xr.atEnd()) {
       QStringRef name = xr.name();

        //QMessageBox::about(this,"entered","Entered reading file contents");
      if(name=="FileName") {
         num1=(QString)xr.readElementText(QXmlStreamReader::IncludeChildElements);
         filenames1.push_back(num1);
       } else if(name=="OnbFileName") {
         num1=(QString)xr.readElementText(QXmlStreamReader::IncludeChildElements);
         onbfilenames1.push_back(num1);
       } else if(name=="Position") {
         num1=(QString)xr.readElementText(QXmlStreamReader::IncludeChildElements);
         positions1.push_back(num1);
       } else if(name=="Text") {
         num1=(QString)xr.readElementText(QXmlStreamReader::IncludeChildElements);
         texts1.push_back(num1);
       } else if(name=="CellId") {
         num1=(QString)xr.readElementText(QXmlStreamReader::IncludeChildElements);
         cellIds1.push_back(num1);
        }

        xr.readNext();
     }
  }

  document_info doc;
  image_info img;

  //QMessageBox::about(this,"filenames",num.number(onbfilenames1.size()));

  for(int i=0;i<onbfilenames1.size();i++) {
    if(documents_info.size()==0) {
      //QMessageBox::about(this,"onbfile",onbfilenames1[i]);
      doc.onbFileName=onbfilenames1[i];
      documents_info.push_back(doc);
    } else {
      for(int j=0;j<documents_info.size();j++) {
        if(onbfilenames1[i]!=documents_info[j].onbFileName) {
          doc.onbFileName=onbfilenames1[i];
          documents_info.push_back(doc);
        }
      }
    }
    file_read=true;
  }

  QString str,str1;

  for(int i=0;i<documents_info.size();i++) {
    documents_info[i].images_info.clear();
    for(int j=0;j<filenames1.size();j++) {
      str=QFileInfo(documents_info[i].onbFileName).absoluteFilePath();
      QString str2=str;
      //QMessageBox::about(this,"files",filenames1[j]);
      //QMessageBox::about(this,"onbfiles",str);
      str1=QFileInfo(filenames1[j]).absoluteFilePath();
      str.remove(str.length()-4,4);
      int indx=str1.lastIndexOf('_',-1,Qt::CaseSensitive);
      //QMessageBox::about(this,"indx",num.number(indx));
      //QMessageBox::about(this,"str1 len",num.number(str1.length()));

      /*In order to compare whether an image belongs to a document, it's enough to compare the image name and document name,
      str1 conatins the image name and every image is index after its onb document name,In order to extract the onb document name
      from the image. The last part of image file name is reomved by following function.*/
      /*The two sting lengths are subtracted to get by how much length the image is differed from document*/

      str1.remove(str1.length()-(str1.length()-indx),(str1.length()-indx));

      //QMessageBox::about(this,"str",str);
      //QMessageBox::about(this,"str1",str1);

      if(str==str1) {
        //QMessageBox::about(this,"attrib",filenames1[j]+" "+positions1[j]+" "+texts1[j]+" "+cellIds1[j]+" "+img.imageName);
        img.imageName=filenames1[j];
        img.cursor_position=positions1[j];
        img.cell_text=texts1[j];
        img.cellId=cellIds1[j];
        QImage* img1 = new QImage(img.imageName);
        img.image=img1;
        img.text=QImageReader(img.imageName).text("Shapes");
        documents_info[i].images_info.push_back(img);
      }
     }
  }

  /*for(int i=0;i<documents_info.size();i++)
  {
    QMessageBox::about(this,"images info ",num.number(documents_info[i].images_info.size()));
  }*/
}

void Tools::writeXml(QString &image_name) {
}


void Tools::draw_copy() {
  if(cut_shape->isEnabled()) {
    cut_shape->setDisabled(true);
  }
  scene->copy_object();
}

void Tools::draw_cut() {
  if(copy_shape->isEnabled())
    copy_shape->setDisabled(true);
  scene->cut_object();
}

void Tools::draw_paste() {
  if(!copy_shape->isEnabled())
    copy_shape->setDisabled(false);
  if(!cut_shape->isEnabled())
    cut_shape->setDisabled(false);
  scene->paste_object();
}

void Tools::mousePressEvent(QMouseEvent *event) {
  if(itemSelected) {
    QPen shapePen;
    QBrush shapeBrush;

    scene->getSelectedShapeProperties(shapePen,shapeBrush);
    select_pen->setCurrentIndex(shapePen.style());
    penWidth->setValue(shapePen.width());
    pen.setColor(QColor(shapePen.color().red(),shapePen.color().green(),shapePen.color().blue(),255));
    select_brush->setCurrentIndex(shapeBrush.style());
    if(scene->isObjectEdited)
      isSaved=false;
  }
}

void Tools::menu() {
  fileMenu=menuBar()->addMenu(tr("&File"));
  fileMenu->addAction(file_new);
  fileMenu->addAction(file_open);
  fileMenu->addAction(file_save);
  fileMenu->addAction(file_image_save);
  fileMenu->addAction(close_me);

  editMenu=menuBar()->addMenu(tr("&Edit"));
  editMenu->addAction(copy);
  editMenu->addAction(cut);
  editMenu->addAction(paste);
}

void Tools::draw_shapes() {
  tool_bar1->addAction(arc);
  tool_bar1->addAction(arrow);
  tool_bar1->addAction(line);
  tool_bar1->addAction(linearrow);
  tool_bar1->addAction(rectangle);
  tool_bar1->addAction(round_rectangle);
  tool_bar1->addAction(ellipse);
  tool_bar1->addAction(polygon);
  tool_bar1->addAction(triangle);
  tool_bar1->addAction(text);
  tool_bar1->setCursor(Qt::ArrowCursor);
  addToolBar(tool_bar1);
}

void Tools::openFile()
{
   /*QTextCursor cursor(textEdit->textCursor());

   QFile fd(this->file_name);//It is a datafile from which we are taking the data
   fd.open(QFile::ReadOnly);//checks whther the file is open r not
   QTextStream inputStream(&fd);//reads the data as streams i.e in bytes

   cursor.movePosition(QTextCursor::Start);
   cursor.beginEditBlock();
   while(!inputStream.atEnd())
   {
      cursor.insertText(inputStream.readLine()+"\n");
   }
   cursor.endEditBlock();*/

}

void Tools::open(const QString filename)
{
  /*file_name=filename;

  if(file_name!=NULL)
    {
       scene->open_Scene(file_name);
     edit=true;
    }*/
}

//opens when crtl-E is pressed
void Tools::open()//edit
{
  int id;
  bool ok;
  QString str,str1,file_name1;
  scene->new_Scene();
  enableProperties();
  getCellId(document->getCursor()->currentCell(),id);

  //gets the format at the current cursor position
  QTextCharFormat format = document->getCursor()->currentCell()->textCursor().charFormat();

  image_info img;

  //checks for image at that cursor position
  if(format.objectType()==1)
  {
    QTextImageFormat format1 = format.toImageFormat();
    QString imagename=format1.name();

    //editing  an image from saved file, that is when an open file option is used choosed in OMnotebook
    if(imagename.contains("file:///"))
    {
          QImage *image=document->getImage(imagename);
          imagename.remove( "file:///" );
      file_name=imagename;
      onb_file_name=document->getFilename();
      filenames.push_back(file_name);
      img.imageName=imagename;
      img.image=image;
      edit_imgs_info.push_back(img);
      QMessageBox::about(this,"filename",edit_imgs_info[0].imageName);
      imageinfo(imagename);
      edit=true;
    }
    else //editing an image from an unsaved file
    {
          file_name=imagename;
      onb_file_name=document->getFilename();
      img.imageName=imagename;
      img.image=new QImage(imagename);
      edit_imgs_info.push_back(img);
          //QMessageBox::about(this,"filename",file_name);
       imageinfo(imagename);
      edit=true;
    }
    //QMessageBox::about(this,"image name",imagename);
  }

}

//reads the data is stored in image that is text data
void Tools::imageinfo(QString filename)
{
  scene->new_Scene();
  QImageReader imr(filename);

   QString text;
   text=imr.text("Shapes");
   QMessageBox::about(this,"Shapes contents ",text);

   QVector<int> values;
   QVector<float> value;
   values.clear();
   value.clear();


   //values contains cooridinates, color info etc
   files->parseText(text,values,value);

   QString num;

  //QMessageBox::about(this,"values size",num.number(values.size()));

   /*for(int i=0;i<values.size();i++)
   {
       QMessageBox::about(this,"image values ",num.setNum(values[i]));
   }*/

  if(values.size()!=0)
    {
       scene->open_Scene(values,value);
     edit=true;
    }
}

void Tools::getCells(const QVector<Cell*> cells)
{
  if(cells.size()!=0)
  {
     QString cell_size;
     //QMessageBox::about(this,"cells in tools from notebook",cell_size.number(cells.size()));

     this->cells=cells;
     //QMessageBox::about(this,"cells in tools",cell_size.number(this->cells.size()));
  }
  /*else
       QMessageBox::about(this,"cells in tools","Empty cells");*/


  /*doc_images.clear();

  QString num;

  for(int i=0;i<cells.size();i++)
  {
    int pos(0);
    while( true )
    {
      int start = cells[i]->textHtml().indexOf( "<img src=", pos, Qt::CaseInsensitive );
      if( 0 <= start )
      {
        // found an image
        start += 10; // pos of first letter in imagename
        int end = cells[i]->textHtml().indexOf( "\"", start );

        // get the image name
        QString imagename = cells[i]->textHtml().mid( start, end - start );

        QImage *image=document->getImage(imagename);

        //QMessageBox::about(this,"images in cells ",image->text("Shapes"));
        imagename.remove( "file:///" );
        image_info img;

        //img.image = new QImage();
        img.image = image;
        img.imageName=imagename;
        img.cellId =num.number(i);
        doc_images.push_back(img);

        pos = end + 1;
      }
      else
        break;
    }
  }

  //QMessageBox::about(this,"images cells ",num.number(doc_images.size()));
  QVector<int> values;
  values.clear();

  for(int i=0;i<doc_images.size();i++)
  {
    //QString text=(this,"images in structure cells ",doc_images[i].image->text("Shapes"));
    QString text=doc_images[i].image->text("Shapes");
    if(text!=NULL)
    {
      files->parseText(text,values);
      doc_images[i].cursor_position=num.number(values[5]);
      values.clear();
        }
  }

  /*for(int i=0;i<doc_images.size();i++)
  {
       QMessageBox::about(this,"images attributes ",doc_images[i].cellId);
     QMessageBox::about(this,"images attributes ",doc_images[i].cursor_position);
  }

  bool found=false;

  if(documents_info.isEmpty())
   {
       document_info doc;
     doc.onbFileName=document->getFilename();
     doc.images_info=doc_images;
     documents_info.push_back(doc);
   }
   else
   {
        for(int i=0;i<documents_info.size();i++)
      {
       if(documents_info[i].onbFileName==document->getFilename())
       {
         found=true;
       }
      }
    if(found)
      {
         for(int i=0;i<documents_info.size();i++)
      {
          if(documents_info[i].onbFileName==document->getFilename())
          {
           for(int j=0;j<images_info.size();j++)
           {
                     documents_info[i].images_info.push_back(doc_images[j]);
           //QMessageBox::about(this,"entered","new image is added");

           }
         break;
          }
       }
       }
       else
       {
          document_info doc;
          doc.onbFileName=document->getFilename();
          doc.images_info=images_info;
          documents_info.push_back(doc);
       }
     }

  images_info.clear();*/

}

void Tools::getCellId(const Cell* cell,int &id)
{
  /*bool found=false;
  QVector<Cell *> temp_cells;
  temp_cells.clear();

   for(int i=0;i<cells.size();i++)
   {
    if(cells[i]==cell)
    {
      id=i;
      found=true;
      break;
    }
   }

   if(found==false)
   {
     Cell *temp = document->getCursor()->currentCell()->previous();
     int indx = cells.indexOf(temp,0);
     Cell* c;
     c=const_cast<Cell*>(cell);
     cells.insert(indx+1,c);
     id=indx+1;
   }*/

}

void Tools::getFileName(const QString &FileName)
{

}


//for closing main window of sketch application
void Tools::closeEvent(QCloseEvent* event)
{
  if(!isSaved)
  {
      int opt=QMessageBox::question(this,"Save file","File not saved, do you want to save",QMessageBox::Yes | QMessageBox::Default, QMessageBox::No,  QMessageBox::Cancel);
    if(opt==QMessageBox::No)
    {
      edit=false;
      scene->new_Scene();

        //break;
    }
    else if(opt==QMessageBox::Yes)
    {
           if(!isSaved)
       {
                      QString file_name=QFileDialog::getSaveFileName(this,"Save",QString(),tr("Image(*.png)"));
          if(file_name.contains(".png"))
           writeImage(file_name);
       }
       isSaved=true;
       edit=false;
       scene->new_Scene();
    }
    else if(opt == QMessageBox::Cancel)
    {
      event->ignore();
      return;
    }
   }
  else
    scene->new_Scene();


}

void Tools::writeImage(QImage *&image)
{
  //QMessageBox::about(this,"image edited ", img_file_name);
  QImageWriter writer( img_file_name, "png" );
  writer.setDescription( "Temporary OMNotebook image" );
  writer.setQuality( 100 );
  writer.write( *image );
}


void Tools::writeImage(QImage *image,QString fileName)
{
  //QMessageBox::about(this,"image edited ", fileName);
  QImageWriter writer( fileName, "png" );
  writer.setDescription( "Temporary OMNotebook image" );
  writer.setQuality( 100 );
  writer.write( *image );

}


void Tools::setColors()
{
    color=color_dialog->getColor(QColor(255,255,255),this);
    if(color.isValid())
  {
       pen.setColor(QColor(color));
       scene->setPen(pen);
     isSaved=false;
  }

}

void Tools::setPenStyles(int indx) {
  switch(indx) {
    case 0:
      pen_lineSolidStyle();
      break;
    case 1:
      pen_lineDashStyle();
      break;
    case 2:
      pen_lineDotStyle();
      break;
    case 3:
      pen_lineDashDotStyle();
      break;
    case 4:
      pen_lineDashDotDotStyle();
      break;
    default:
      break;
  }
  isSaved = false;
}

void Tools::setPenWidths(int width) {
  //setting different pen widths
  scene->setPenWidth(width);
  if (width >= 0 && width <= 4) {
    pen.setWidth(width+1);
  }
  isSaved=false;
}

void Tools::setBrushStyles(int indx) {
  scene->setBrushStyle(indx);
  switch(indx) {
    case 0:
      brush.setStyle(Qt::NoBrush);
      break;
    case 1:
      brush.setStyle(Qt::SolidPattern);
      break;
    case 2:
      brush.setStyle(Qt::Dense1Pattern);
      break;
    case 3:
      brush.setStyle(Qt::Dense2Pattern);
      break;
    case 4:
      brush.setStyle(Qt::Dense3Pattern);
      break;
    case 5:
      brush.setStyle(Qt::Dense4Pattern);
      break;
    case 6:
      brush.setStyle(Qt::Dense5Pattern);
      break;
    case 7:
      brush.setStyle(Qt::Dense6Pattern);
      break;
    case 8:
      brush.setStyle(Qt::Dense7Pattern);
      break;
    case 9:
      brush.setStyle(Qt::HorPattern);
      break;
    case 10:
      brush.setStyle(Qt::VerPattern);
      break;
    case 11:
      brush.setStyle(Qt::CrossPattern);
      break;
    case 12:
      brush.setStyle(Qt::BDiagPattern);
      break;
    case 13:
      brush.setStyle(Qt::FDiagPattern);
      break;
    case 14:
      brush.setStyle(Qt::DiagCrossPattern);
      break;
    default:
      break;
  }
  isSaved = false;
}



void Tools::pen_lineSolidStyle() {
  scene->setPenStyle(1);
  pen.setStyle(Qt::SolidLine);
  scene->setPen(pen);
  isSaved = false;
}

void Tools::pen_lineDashStyle() {
  scene->setPenStyle(2);
  pen.setStyle(Qt::DashLine);
  scene->setPen(pen);
  isSaved = false;
}

void Tools::pen_lineDotStyle() {
  scene->setPenStyle(3);
  pen.setStyle(Qt::DotLine);
  scene->setPen(pen);
  isSaved = false;
}

void Tools::pen_lineDashDotStyle() {
  scene->setPenStyle(4);
  pen.setStyle(Qt::DashDotLine);
  scene->setPen(pen);
  isSaved = false;
}

void Tools::pen_lineDashDotDotStyle() {
  scene->setPenStyle(5);
  pen.setStyle(Qt::DashDotDotLine);
  scene->setPen(pen);
  isSaved = false;
}

void Tools::brush_color() {
  color=color_dialog->getColor(QColor(255,255,255),this);
  if(color.isValid())
  {
    brush.setColor(color);
    brush.setStyle(Qt::SolidPattern);
    scene->setBrush(brush);
    //scene->setBackgroundBrush(brush.color());
    isSaved = false;
  }
}

void Tools::readFileAttributes(QVector<QString> &subStrings) {
  int id;
  bool ok;
  QString str,str1;
  scene->clear();
  getCellId(document->getCursor()->currentCell(),id);

  /*if(file_read==false)
  {
       readXml(document->getFilename());
  }*/

  if(documents_info.size()!=0)
  {
    for(int i=0;i<documents_info.size();i++)
    {
      if(documents_info[i].onbFileName==document->getFilename())
      {
        for(int j=0;j<documents_info[i].images_info.size();j++)
        {
          int pos=document->getCursor()->currentCell()->textCursor().position();
          if((documents_info[i].images_info[j].cellId==str.number(id))&&(documents_info[i].images_info[j].cursor_position.toInt(&ok,10)==pos))
          {
               file_name=documents_info[i].images_info[j].imageName;
               onb_file_name=documents_info[i].onbFileName;
           edit_imgs_info.push_back(documents_info[i].images_info[j]);
               //QMessageBox::about(this,"filename",file_name);
           edit=true;
           break;
          }
          else
            file_name=" ";
        }
      }
    }
  }

   scene->new_Scene();

   QImageReader imr(file_name);
   QString text;
   text=imr.text("Shapes");
   //QMessageBox::about(this,"Shapes contents ",text);

   if(text!=NULL)
     {
       files->parseText(text,subStrings);
     }

}

void Tools::insertImage(QString imageName)
{

   /*QString img_name=imageName;

   QString num;

   bool found=false;

   //QMessageBox::about(this,"images ",num.number(images_info.size()));
   //QMessageBox::about(this,"onbFileName ",img_name);

   //QMessageBox::about(this,"onb Documents size ",num.number(documents_info.size()));

  QVector<image_info> imgs;
  imgs.clear();
    //updateCells();

  for(int i=0;i<cells.size();i++)
  {
    int pos(0);
    while( true )
    {
      int start = cells[i]->textHtml().indexOf( "<img src=", pos, Qt::CaseInsensitive );
      if( 0 <= start )
      {
        // found an image
        start += 10; // pos of first letter in imagename
        int end = cells[i]->textHtml().indexOf( "\"", start );

        // get the image name
        QString imagename = cells[i]->textHtml().mid( start, end - start );

        QMessageBox::about(this,"image name  ",imagename);


        QImage *image = new QImage(imagename);

        QMessageBox::about(this,"images in cells ",image->text("Shapes"));

        image_info img;

        //img.image = new QImage();
        img.image = image;
        img.text = image->text("Shapes");
        img.cellId =num.number(i);
        imgs.push_back(img);

        pos = end + 1;
      }
      else
        break;
    }
  }

  QMessageBox::about(this,"images cells ",num.number(imgs.size()));
  QVector<int> values;
  values.clear();

  for(int i=0;i<imgs.size();i++)
  {
    QString text=(this,"images in structure cells ",imgs[i].image->text("Shapes"));

    if(text!=NULL)
    {
      files->parseText(text,values);
      imgs[i].cursor_position=num.number(values[5]);
      values.clear();
        }
  }

  for(int i=0;i<imgs.size();i++)
  {
       QMessageBox::about(this,"images attributes ",imgs[i].cellId);
     QMessageBox::about(this,"images attributes ",imgs[i].cursor_position);
  }

   isSaved = true;
   if(documents_info.isEmpty()&&!images_info.isEmpty())
   {
       document_info doc;
     doc.onbFileName=img_name;
     doc.images_info=images_info;
     documents_info.push_back(doc);
   }
   else
   {
        for(int i=0;i<documents_info.size();i++)
      {
       if(documents_info[i].onbFileName==img_name)
       {
         found=true;
       }
      }
    if(found)
      {

         for(int i=0;i<documents_info.size();i++)
      {
          if(documents_info[i].onbFileName==img_name)
          {
                 for(int j=0;j<images_info.size();j++)
           {
           documents_info[i].images_info.push_back(images_info[j]);

           //QMessageBox::about(this,"entered","new image is added");

           }
         break;
          }
       }
       }
       else
       {
          document_info doc;
          doc.onbFileName=img_name;
          doc.images_info=images_info;
          documents_info.push_back(doc);
       }
     }

  //QMessageBox::about(this,"onb Documents size after reading  ",num.number(documents_info.size()));


  for(int i=0;i<documents_info.size();i++)
  {
      if(img_name==documents_info[i].onbFileName)
    {
       writeImage(documents_info[i]);
       break;
    }
  }

  images_info.clear();*/

}

//function to write the image of each shape the data the image_info object

void Tools::writeImage(image_info imageinfo)
{
    //QMessageBox::about(this,"image edited ", imageinfo.imageName);
  QImageWriter writer( imageinfo.imageName, "png" );
  writer.setDescription( "Temporary OMNotebook image" );
  writer.setQuality( 100 );

  writer.setText("Shapes",imageinfo.text);
  writer.write( *imageinfo.image );
}


void Tools::writeImage(image_info imageinfo,QString filename,int indx)
{

}

void Tools::writeImage(document_info &docs)
{

  /*QTextEdit *editor = new QTextEdit();
    QTextImageFormat imageformat;
    QTextCursor cursor;

  QString num;
  QString str;

     bool ok;

   if(edit==false)
   {
   for(int i=0;i<docs.images_info.size();i++)
   {

      //if(!QFile(docs.images_info[i].imageName).exists())
      {
           str=QFileInfo(docs.onbFileName).completeBaseName();
       //QMessageBox::about(this,"base name ",str);
       //the extension of the file is removed and this file name is added to image name
         //str.remove(str.length()-4,4);
           //str=str+"_"+num.setNum(i+1,10)+".png";
           //docs.images_info[i].imageName=str;
       str=docs.images_info[i].imageName;
       //if(QFile(docs.images_info[i].imageName).exists())
         //QFile(docs.images_info[i].imageName).remove();
       //QMessageBox::about(this,"text in images", docs.images_info[i].text);
       //QMessageBox::about(this,"filename", str);
         QString cell_indx=docs.images_info[i].cellId;
         Cell* cell = cells[cell_indx.toInt(&ok,10)];
         cursor = cell->textCursor();
         /*cell->textCursor().setPosition(docs.images_info[i].cursor_position.toInt(&ok,10));
         cell->textCursor().deletePreviousChar();
         cell->textCursor().setPosition(cursor.position()-1);
           if(!cursor.isNull())
         {
          //QString imagename = document->addImage(image);
          writeImage(docs.images_info[i]);
          //QString imagename = img_file_name;
          /*editor = cell->textEdit();

          if( editor )
          {
           // save text settings and set them after image have been inserted
           QTextCharFormat format = cursor.charFormat();
           if( editor->toPlainText().isEmpty() )
             format = *cell->style()->textCharFormat();

           imageformat.merge( format );
           imageformat.setHeight( docs.images_info[i].image->height());
           imageformat.setWidth( docs.images_info[i].image->width());
           imageformat.setName(str);

            cursor.insertImage( imageformat );
          }//end of if
          }//end of if
      }//end of if
     }//end of for
   }//end of if

   if(!edit_imgs_info.isEmpty())
   {
     for(int i=0;i<documents_info.size();i++)
     {
          if(documents_info[i].onbFileName==document->getFilename())
      {
      for(int j=0;j<documents_info[i].images_info.size();j++)
      {
               for(int k=0;k<edit_imgs_info.size();k++)
         {
            if(documents_info[i].images_info[j].imageName==edit_imgs_info[k].imageName)
            {
                     QString str = QFileInfo(documents_info[i].onbFileName).completeBaseName();
           str=str+"_"+num.setNum(j+1,10)+".png";
                     edit_imgs_info[k].imageName=str;
           //QMessageBox::about(this,"base name edit",str);
                     QString cell_indx=edit_imgs_info[k].cellId;
                   Cell* cell = cells[cell_indx.toInt(&ok,10)];
           //QMessageBox::about(this,"cellIndex",cell_indx);

           //QMessageBox::about(this,"curpos",edit_imgs_info[k].cursor_position);

                   cursor = cell->textCursor();
           cursor.setPosition(edit_imgs_info[k].cursor_position.toInt(&ok,10));
                   cursor.deletePreviousChar();
                   cursor.setPosition(edit_imgs_info[k].cursor_position.toInt(&ok,10)-1);
                     if(!cursor.isNull())
                   {
                    writeImage(edit_imgs_info[k]);
                    editor = cell->textEdit();

                    if( editor )
                    {
                     // save text settings and set them after image have been inserted
                     QTextCharFormat format = cursor.charFormat();
                     if( editor->toPlainText().isEmpty() )
                       format = *cell->style()->textCharFormat();

                     imageformat.merge( format );
                     imageformat.setHeight( edit_imgs_info[k].image->height());
                     imageformat.setWidth( edit_imgs_info[k].image->width());
                     imageformat.setName(edit_imgs_info[k].imageName);

                      cursor.insertImage( imageformat );
                    }//end of if
                   }//end of if

            }
         }
      }
      }
     }

   }

   edit_imgs_info.clear();

   if(!filenames.isEmpty())
   {
     for(int i=0;i<filenames.size();i++)
     {
       if(QFile(filenames[i]).exists())
       {
         QFile(filenames[i]).remove();
       }
     }
   }*/

}

void Tools::updateCells()
{

}

void Tools::updateImages()
{

}


void Tools::writeImage(QString filename) {
  if(!scene->getObjects().isEmpty()) {
    QVector<QPointF> objectsPos;
    QPointF minPos,maxPos;
    objectsPos.clear();
    QString text = QString();
    //QString str_x,str_y,str_x1,str_y1;
    //QString color_r,color_g,color_b;
    //int r,g,b;

    scene->getObjectsPos(objectsPos);


    for(int i=0;i<scene->getObjects().size();i++)
      scene->getObjects().at(i)->print();

    QPointF pnt;
    scene->getDim();

    scene->getMaxPosition(pnt);
    QImage *image = new QImage(scene->getDim().x()+1, scene->getDim().y()+1, QImage::Format_ARGB32_Premultiplied);
    //QImage *image = new QImage(1200,800, QImage::Format_ARGB32_Premultiplied);
    //QImage *image = new QImage(ceil(pnt.x())+1.0, ceil(pnt.y())+1.0, QImage::Format_ARGB32_Premultiplied);
    image->fill(qRgb(255,255,255));

    scene->getMinPosition(minPos);
    scene->getMaxPosition(maxPos);

    QPainter* p = new QPainter(image);

    qDebug()<<"min position "<<minPos<<"\n";
    scene->writeToImage(p,text,-(minPos));

    if(filename.contains(".png")) {
      QImageWriter writer_img(filename,"png");
      writer_img.setDescription( "Temporary OMNotebook image" );
      writer_img.setQuality( 100 );
      writer_img.setText("Shapes",text);
      writer_img.write( *image );
    }

    if(filename.contains(".jpg")) {
      QImageWriter writer_img(filename,"jpg");
      writer_img.setDescription( "Temporary OMNotebook image" );
      writer_img.setQuality( 100 );
      //writer_img.setText("Shapes",text);
      qDebug()<<"image written "<<writer_img.write( *image )<<"\n";
    }

    if(filename.contains(".bmp")) {
      QImageWriter writer_img(filename,"bmp");
      writer_img.setDescription( "Temporary OMNotebook image" );
      writer_img.setQuality( 100 );
      writer_img.setText("Shapes",text);
      writer_img.write( *image );
    }

    p->end();
  } else {
    QImage *image = new QImage(1200,800, QImage::Format_ARGB32_Premultiplied);
    image->fill(qRgb(255,255,255));

    QImageWriter writer_img(filename,"png");
    writer_img.setDescription( "Temporary OMNotebook image" );
    writer_img.setQuality( 100 );
    writer_img.write( *image );
  }
}

void Tools::add_components() {
  size.setWidth(25);
  size.setHeight(25);
  file_components();
  edit_components();
  color_pen_components();
}

void Tools::file_components() {
  new_file = new QToolButton(this);
  new_file->setIcon(QIcon(":/Resources/sketchIcons/new.svg"));
  open_file = new QToolButton(this);
  open_file->setIcon(QIcon(":/Resources/sketchIcons/fileopen.png"));

  save_file = new QToolButton(this);
  save_file->setIcon(QIcon(":/Resources/sketchIcons/save.svg"));
  saveas_file = new QToolButton(this);
  saveas_file->setIcon(QIcon(":/Resources/sketchIcons/saveas.svg"));

  export_file = new QToolButton(this);
  export_file->setIcon(QIcon(":/Resources/sketchIcons/export.svg"));
  import_file = new QToolButton(this);
  import_file->setIcon(QIcon(":/Resources/sketchIcons/import.svg"));

  new_file->setIconSize(size);
  new_file->setToolTip("New File");

  open_file->setIconSize(size);
  open_file->setToolTip("Open File");

  save_file->setIconSize(size);
  save_file->setToolTip("Save File");

  saveas_file->setIconSize(size);
  saveas_file->setToolTip("Saveas File");

  export_file->setIconSize(size);
  export_file->setToolTip("Export File to  modelica");

  import_file->setIconSize(size);
  import_file->setToolTip("Import File");

  tool_bar2->addWidget(new_file);
  tool_bar2->addWidget(open_file);
  tool_bar2->addWidget(save_file);
  tool_bar2->addWidget(saveas_file);
  tool_bar2->addWidget(import_file);
  tool_bar2->addWidget(export_file);
  addToolBar(tool_bar2);

  //events
  connect(new_file,SIGNAL(clicked()),SLOT(draw_new()));
  connect(save_file,SIGNAL(clicked()),SLOT(draw_save()));
  connect(open_file,SIGNAL(clicked()),SLOT(draw_open()));
  connect(export_file,SIGNAL(clicked()),SLOT(draw_image_save()));
}

void Tools::edit_components() {
  cut_shape = new QToolButton(this);
  cut_shape->setIcon(QIcon(":/Resources/sketchIcons/editcut.png"));
  cut_shape->setIconSize(size);
  cut_shape->setToolTip(tr("Cut Shape"));
  copy_shape = new QToolButton(this);
  copy_shape->setIcon(QIcon(":/Resources/sketchIcons/editcopy.png"));
  copy_shape->setIconSize(size);
  copy_shape->setToolTip(tr("Copy Shape"));
  paste_shape = new QToolButton(this);
  paste_shape->setIcon(QIcon(":/Resources/sketchIcons/editpaste.png"));
  paste_shape->setIconSize(size);
  paste_shape->setToolTip(tr("Paste Shape"));
  redo_shape = new QToolButton(this);
  redo_shape->setIcon(QIcon(":/Resources/sketchIcons/editredo.png"));
  redo_shape->setIconSize(size);
  redo_shape->setToolTip(tr("Redo"));
  undo_shape = new QToolButton(this);
  undo_shape->setIcon(QIcon(":/Resources/sketchIcons/editundo.png"));
  undo_shape->setIconSize(size);
  undo_shape->setToolTip(tr("Undo"));

  tool_bar3->addWidget(cut_shape);
  tool_bar3->addWidget(copy_shape);
  tool_bar3->addWidget(paste_shape);
  tool_bar3->addWidget(redo_shape);
  tool_bar3->addWidget(undo_shape);
  addToolBar(tool_bar3);

  //events
  connect(cut_shape,SIGNAL(clicked()),SLOT(draw_cut()));
  connect(copy_shape,SIGNAL(clicked()),SLOT(draw_copy()));
  connect(paste_shape,SIGNAL(clicked()),SLOT(draw_paste()));
}

void Tools::color_pen_components() {
  select_color = new QToolButton(this);
  select_color->setIcon(QIcon(":/Resources/sketchIcons/paint.png"));
  select_color->setIconSize(size);
  select_color->setToolTip("Select Colors");

  fill_color = new QToolButton(this);
  fill_color->setIcon(QIcon(":/Resources/sketchIcons/fillcolor.png"));
  fill_color->setIconSize(size);
  fill_color->setToolTip("Select Fill Colors");

  select_pen = new QComboBox();
  select_pen->addItem(QIcon(":/Resources/sketchIcons/pencil.png"),"Solid Line");
  select_pen->addItem(QIcon(":/Resources/sketchIcons/pencil.png"),"Dash Line");
  select_pen->addItem(QIcon(":/Resources/sketchIcons/pencil.png"),"Dot Line");
  select_pen->addItem(QIcon(":/Resources/sketchIcons/pencil.png"),"Dash Dot Line");
  select_pen->addItem(QIcon(":/Resources/sketchIcons/pencil.png"),"Dash Dot Dot Line");
  select_pen->setIconSize(size);
  select_pen->setToolTip("Select Pen Styles");

  select_brush = new QComboBox();
  select_brush->addItem(QIcon(":/Resources/sketchIcons/brush.png"),"No Brush");
  select_brush->addItem(QIcon(":/Resources/sketchIcons/solidpattern.png"),"Solid Fill");
  select_brush->addItem(QIcon(":/Resources/sketchIcons/dense1pattern.png"),"Dense 1 Fill");
  select_brush->addItem(QIcon(":/Resources/sketchIcons/dense2pattern.png"),"Dense 2 Fill");
  select_brush->addItem(QIcon(":/Resources/sketchIcons/dense3pattern.png"),"Dense 3 Fill");
  select_brush->addItem(QIcon(":/Resources/sketchIcons/dense4pattern.png"),"Dense 4 Fill");
  select_brush->addItem(QIcon(":/Resources/sketchIcons/dense5pattern.png"),"Dense 5 Fill");
  select_brush->addItem(QIcon(":/Resources/sketchIcons/dense6pattern.png"),"Dense 6 Fill");
  select_brush->addItem(QIcon(":/Resources/sketchIcons/dense7pattern.png"),"Dense 7 Fill");
  select_brush->addItem(QIcon(":/Resources/sketchIcons/horpattern.png"),"Hor Fill");
  select_brush->addItem(QIcon(":/Resources/sketchIcons/verpattern.png"),"Ver Fill");
  select_brush->addItem(QIcon(":/Resources/sketchIcons/crosspattern.png"),"Cross Fill");
  select_brush->addItem(QIcon(":/Resources/sketchIcons/bdiagpattern.png"),"BDiag Fill");
  select_brush->addItem(QIcon(":/Resources/sketchIcons/fdiagpattern.png"),"FDiag Fill");
  select_brush->addItem(QIcon(":/Resources/sketchIcons/diagcrosspattern.png"),"Diag Cross Fill");
  select_brush->setIconSize(size);
  select_brush->setToolTip("Select Brush Styles");

  QLabel *label = new QLabel(tr("Pen Width"));
  label->setToolTip(tr("Select Pen Width"));
  penWidth = new QSpinBox();
  penWidth->setMinimum(1);
  penWidth->setMaximum(5);
  penWidth->setToolTip(tr("Select Pen Width"));

  tool_bar4->addWidget(label);
  tool_bar4->addWidget(penWidth);
  tool_bar4->addWidget(select_color);
  tool_bar4->addWidget(fill_color);
  tool_bar4->addWidget(select_pen);
  tool_bar4->addWidget(select_brush);
  tool_bar4->setEnabled(false);
  addToolBar(tool_bar4);

  connect(select_color,SIGNAL(clicked()),SLOT(setColors()));
  connect(fill_color,SIGNAL(clicked()),SLOT(brush_color()));
  connect(select_pen,SIGNAL(activated(int)),SLOT(setPenStyles(int)));
  connect(select_brush,SIGNAL(activated(int)),SLOT(setBrushStyles(int)));
  connect(penWidth,SIGNAL(valueChanged(int)),SLOT(setPenWidths(int)));
}

void Tools::reloadShapesProerties() {
  select_pen->setCurrentIndex(0);
  select_brush->setCurrentIndex(0);
  penWidth->setValue(0);
  pen.setColor(QColor(0,0,0,255));
}

void Tools::enableProperties() {
  tool_bar4->setEnabled(true);
}

void Tools::disableProperties() {
  tool_bar4->setEnabled(false);
}

void Tools::item_selected(Graph_Scene* scene_item) {
  if(!scene_item->getObjects().isEmpty()) {
    for(int i=0;i<scene_item->getObjects().size();i++) {
      qDebug()<<"entered \n";
    }
  }
}

void Tools::mouseReleaseEvent(QMouseEvent *event) {
  if(event->button()==Qt::LeftButton) {
    if(scene->isMultipleSelected==true) {
      setCursor(Qt::ArrowCursor);
      pen.setStyle(Qt::SolidLine);
      brush.setStyle(Qt::NoBrush);
    }
  }
}

void Tools::keyPressEvent(QKeyEvent *event) {
  //setCursor(Qt::SizeAllCursor);
  if(event->key()==Qt::Key_Control) {
    scene->isMultipleSelected=true;
    //qDebug()<<"multiple selected "<<scene->isMultipleSelected<<"\n";
  }
}

void Tools::keyReleaseEvent(QKeyEvent* event) {
  //setCursor(Qt::ArrowCursor);
  if(event->key()==Qt::Key_Control) {
     scene->isMultipleSelected=false;
  }
}
