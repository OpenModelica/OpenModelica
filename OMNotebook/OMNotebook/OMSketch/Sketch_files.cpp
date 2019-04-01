#include "Sketch_Files.h"

Sketch_Files::Sketch_Files()
{

}

void Sketch_Files::readXml(QString FileName)//Opens the sketch file
{
    if(FileName.contains(".xml")||FileName.contains(".skh"))
    {
         QFile fd(FileName);
         fd.open(QFile::ReadWrite);
         QXmlStreamReader rw(&fd);

         while(!rw.atEnd())
         {
            object = new Scene_Objects;
            if(rw.name()=="Type")//what type of object ex:line,rect...
            {
                QTextStream readline;
                QString str,subText;
                str=rw.readElementText();
                readline.setString(&str,QIODevice::ReadWrite);

                while(!readline.atEnd())
                {
                    readline>>subText;
                    if(subText.contains("Line"))
                        object->ObjectId=1;
                    if(subText.contains("Rectangle"))
                        object->ObjectId=2;
                    if(subText.contains("Ellipse"))
                        object->ObjectId=3;
                    if(subText.contains("RoundRect"))
                        object->ObjectId=5;
                }


            }

            if(rw.name()=="Dim")
            {
              parseText(rw.readElementText());
              object->print();
            }

            rw.readNext();
         }

    }

        if(FileName.contains(".png"))
        {
       QImageReader imr(FileName);
           QString text;
           text=imr.text("Shapes");
           qDebug()<<"image text "<<text<<"\n";
        }
}


void Sketch_Files::readXml(QString FileName,QVector<QString> &subStrings)
{
        if(FileName.contains(".xml")||FileName.contains(".skh"))
    {
         QFile fd(FileName);
         fd.open(QFile::ReadWrite);
         QXmlStreamReader rw(&fd);

         while(!rw.atEnd())
         {
            object = new Scene_Objects;
            if(rw.name()=="Type")
            {
               subStrings.push_back(rw.readElementText());
               subStrings.push_back("\n");
            }

            if(rw.name()=="Dim")
            {
              subStrings.push_back(rw.readElementText());
              subStrings.push_back("\n");
            }
                        rw.readNext();
         }

    }
}

void Sketch_Files::readXml(QVector<Scene_Objects *> &objects,QString FileName)
{
    if(FileName.contains(".xml")||FileName.contains(".skh"))
    {
         QFile fd(FileName);
         fd.open(QFile::ReadWrite);
         QXmlStreamReader rw(&fd);
         object = new Scene_Objects;
         while(!rw.atEnd())
         {

            if(rw.name()=="Type")
            {
                QTextStream readline;
                QString str,subText;
                str=rw.readElementText();
                readline.setString(&str,QIODevice::ReadWrite);

                while(!readline.atEnd())
                {
                    readline>>subText;
                    qDebug()<<"subText "<<subText<<"\n";
                    object = new Scene_Objects;
                    if(subText.contains("Line"))
                    {
                        qDebug()<<"In subText "<<subText<<"\n";
                        object->ObjectId=1;
                    }
                    if(subText.contains("Rectangle"))
                    {
                        qDebug()<<"In subText "<<subText<<"\n";
                        object->ObjectId=2;
                    }
                    if(subText.contains("Ellipse"))
                    {
                        qDebug()<<"In subText "<<subText<<"\n";
                        object->ObjectId=3;
                    }
                    if(subText.contains("RoundRect"))
                    {
                        qDebug()<<"In subText "<<subText<<"\n";
                        object->ObjectId=5;
                    }
                }
            }
            if(rw.name()=="Dim")
            {
              parseText(rw.readElementText());
              objects.push_back(object);
            }

            rw.readNext();
         }

    }

    for(int i=0;i<objects.size();i++)
    {
        objects[i]->print();
    }

        if(FileName.contains(".mo"))
        {
       QFile fd(FileName);
           fd.open(QIODevice::ReadWrite);
           QTextStream reader(&fd);
           QTextStream reader1;
           QString subText,subText1;
           //qDebug()<<"Text  "<<reader.readAll()<<"\n";
           subText=reader.readAll();
           reader1.setString(&subText,QIODevice::ReadWrite);
           while(!reader1.atEnd())
           {
                   reader1>>subText1;
                   qDebug()<<"Text in file "<<subText1<<"\n";
           }
        }
}


void Sketch_Files::writeXml(QString FileName)
{

}

void Sketch_Files::writeXml(QVector<Scene_Objects *> &objects,QString FileName)
{
    QFile fd(FileName);
    fd.open(QFile::WriteOnly);

    QXmlStreamWriter xw(&fd);
    xw.setAutoFormatting(true);
    xw.writeStartDocument();
    xw.writeStartElement("Object");
    QString num,num1,num2,num3,num4;
    //num.clear();

    int x,y,x1,y1;

    for(int i=0;i<objects.size();i++)
    {
       //objects.at(i)->print();

       qDebug()<<"objects "<<objects.at(i)->ObjectStrtPnt<<" "<<objects.at(i)->ObjectEndPnt<<"\n";
       if(objects.at(i)->ObjectId==1)
       {
          xw.writeTextElement("Type","Line");
          xw.writeTextElement("ObjectId"," "+num.setNum(objects.at(i)->ObjectId)+" ");
          //xw.writeTextElement("Color",num.setNum(objects[i]->Object_pen.color().red())+" "+num.setNum(objects[i]->Object_pen.color().green())+" "+num.setNum(objects[i]->Object_pen.color().blue()));
          //xw.writeTextElement("Dim"," "+num.setNum((objects.at(i)->ObjectStrtPnt.x()))+" "+num.setNum((objects.at(i)->ObjectStrtPnt.y()))+" "+num.setNum((objects.at(i)->ObjectEndPnt.x()))+" "+num.setNum((objects.at(i)->ObjectEndPnt.y()))+" ");

       }

       if(objects.at(i)->ObjectId==2)
       {
           xw.writeTextElement("Type","Rectangle");
           xw.writeTextElement("ObjectId"," "+num.setNum(objects.at(i)->ObjectId)+" ");
           //xw.writeTextElement("Color",num.setNum(objects[i]->Object_pen.color().red())+" "+num.setNum(objects[i]->Object_pen.color().green())+" "+num.setNum(objects[i]->Object_pen.color().blue()));
           //xw.writeTextElement("Dim"," "+num.setNum((objects.at(i)->ObjectStrtPnt.x()))+" "+num.setNum((objects.at(i)->ObjectStrtPnt.y()))+" "+num.setNum((objects.at(i)->ObjectEndPnt.x()))+" "+num.setNum((objects.at(i)->ObjectEndPnt.y()))+" ");
       }

       if(objects.at(i)->ObjectId==3)
       {
          xw.writeTextElement("Type","Ellipse");
          xw.writeTextElement("ObjectId"," "+num.setNum(objects.at(i)->ObjectId)+" ");
          //xw.writeTextElement("Color",num.setNum(objects[i]->Object_pen.color().red())+" "+num.setNum(objects[i]->Object_pen.color().green())+" "+num.setNum(objects[i]->Object_pen.color().blue()));
          //xw.writeTextElement("Dim"," "+num.setNum((objects.at(i)->ObjectStrtPnt.x()))+" "+num.setNum((objects.at(i)->ObjectStrtPnt.y()))+" "+num.setNum((objects.at(i)->ObjectEndPnt.x()))+" "+num.setNum((objects.at(i)->ObjectEndPnt.y()))+" ");

       }

       if(objects.at(i)->ObjectId==5)
       {
          xw.writeTextElement("Type","RoundRect");
          xw.writeTextElement("ObjectId"," "+num.setNum(objects.at(i)->ObjectId)+" ");
          //xw.writeTextElement("Color",num.setNum(objects[i]->Object_pen.color().red())+" "+num.setNum(objects[i]->Object_pen.color().green())+" "+num.setNum(objects[i]->Object_pen.color().blue()));
          /*x=objects.at(i)->ObjectStrtPnt.x();
          y=objects.at(i)->ObjectStrtPnt.y();
          x1=objects.at(i)->ObjectEndPnt.x();
          y1=objects.at(i)->ObjectEndPnt.y();
          xw.writeTextElement("Dim"," "+num1.setNum(x)+" "+num2.setNum(y)+" "+num3.setNum(x1)+" "+num4.setNum(y1)+" ");*/

       }

       x=objects.at(i)->ObjectStrtPnt.x();
       y=objects.at(i)->ObjectStrtPnt.y();
       x1=objects.at(i)->ObjectEndPnt.x();
       y1=objects.at(i)->ObjectEndPnt.y();
       xw.writeTextElement("Dim"," "+num1.setNum(x)+" "+num2.setNum(y)+" "+num3.setNum(x1)+" "+num4.setNum(y1)+" ");

    }
    xw.writeEndElement();
    xw.writeEndDocument();
}


void Sketch_Files::parseText(QString text)
{
    QTextStream readline;
    QString subText;
    bool ok;

    values.clear();

    readline.setString(&text,QIODevice::ReadWrite);

    while(!readline.atEnd())
    {
        readline>>subText;

        if(!subText.isNull())
        {
            values.push_back(subText.toInt(&ok,10));
        }
    }

    if(values.size()!=0)
    {
        //for(int i=0;i<values.size();i++)
        {
            object->ObjectStrtPnt.setX(values[0]);
            object->ObjectStrtPnt.setY(values[1]);
            object->ObjectEndPnt.setX(values[2]);
            object->ObjectEndPnt.setY(values[3]);

        }
    }
}

void Sketch_Files::parseText(QString text,QVector<int> &values,QVector<float> &value)
{
    QTextStream readline;
    QString subText;
  int state;
    bool ok;

    if(text.contains("Sketch:"))
        text.remove("Sketch:");

    readline.setString(&text,QIODevice::ReadWrite);

    while(!readline.atEnd())
    {
        readline>>subText;
        //qDebug()<<"subtexts "<<subText<<"\n";

        if(subText.contains("Line"))
        {
      state=0;
      values.push_back(1);
        }

        if(subText.contains("Rectangle"))
        {
      state=0;
            values.push_back(2);
        }

        if(subText.contains("Ellipse"))
        {
      state=0;
            values.push_back(3);
        }

        if(subText.contains("Polygon"))
        {
      state=0;
            values.push_back(4);
        }

        if(subText.contains("RoundRect"))
        {
      state=0;
            values.push_back(5);
        }

        if(subText.contains("Arc"))
        {
      state=0;
            values.push_back(6);
        }

    if(subText.contains("linearrow"))
        {
      state=0;
      values.push_back(7);
        }

    if(subText.contains("Triangle"))
        {
      state=0;
            values.push_back(8);
        }

    if(subText.contains("Arrow"))
        {
      state=0;
            values.push_back(9);
        }

    if(subText.contains("Text"))
        {
      state=0;
            values.push_back(10);
        }

        if(!subText.isNull()&&(!subText.contains("\n"))&&(!subText.contains(" ")))
        {
            if((!subText.contains("Coords"))&&(!subText.contains("Line"))&&(!subText.contains("Rectangle"))&&(!subText.contains("Ellipse"))&&(!subText.contains("Polygon"))&&(!subText.contains("RoundRect"))&&(!subText.contains("Arc"))&&(!subText.contains("linearrow"))&&(!subText.contains("Triangle"))&&(!subText.contains("Arrow"))&&(!subText.contains("Text"))&&(!subText.contains("PenColor"))&&(!subText.contains("PenStyle")&&(!subText.contains("PenWidth"))&&(!subText.contains("BrushColor"))&&(!subText.contains("BrushStyle"))))
            {
        if(subText.contains("Rotation"))
          state=1;
        if(state!=1)
        {
                    qDebug()<<"values "<<subText<<"\n";
                    values.push_back(subText.toInt(&ok,10));

        }

        if(state==1)
        {
          if(!subText.contains("Rotation"))
            value.push_back(subText.toFloat(&ok));
        }
            }


        }


    }
}

void Sketch_Files::parseText(QString text,QVector<QString> &subStrings)
{
    QTextStream readline;
    QString subText;

    readline.setString(&text,QIODevice::ReadWrite);

    while(!readline.atEnd())
    {
        readline>>subText;

        if(subText.contains("Line"))
        {
             if(subStrings.size()!=0)
             {
                  subStrings.push_back("\n");
             }
             subStrings.push_back(subText);
             subStrings.push_back("\n");
        }

        if(subText.contains("Rectangle"))
        {
             if(subStrings.size()!=0)
             {
                 subStrings.push_back("\n");
             }
             subStrings.push_back(subText);
             subStrings.push_back("\n");
        }

        if(subText.contains("Ellipse"))
        {
            if(subStrings.size()!=0)
            {
                subStrings.push_back("\n");
            }
            subStrings.push_back(subText);
            subStrings.push_back("\n");
        }

        if(subText.contains("RoundRect"))
        {
             if(subStrings.size()!=0)
             {
                  subStrings.push_back("\n");
             }
             subStrings.push_back(subText);
             subStrings.push_back("\n");
        }

        if(subText.contains("PenColor"))
        {
             if(subStrings.size()!=0)
             {
                  subStrings.push_back("\n");
             }
             subStrings.push_back(subText);
             subStrings.push_back("\n");
        }

        if(subText.contains("PenStyle"))
        {
             if(subStrings.size()!=0)
             {
                  subStrings.push_back("\n");
             }
             subStrings.push_back(subText);
             subStrings.push_back("\n");
        }

        if(subText.contains("PenWidth"))
        {
             if(subStrings.size()!=0)
             {
                  subStrings.push_back("\n");
             }
             subStrings.push_back(subText);
             subStrings.push_back("\n");
        }

        if(subText.contains("BrushColor"))
        {
             if(subStrings.size()!=0)
             {
                  subStrings.push_back("\n");
             }
             subStrings.push_back(subText);
             subStrings.push_back("\n");
        }

        if(subText.contains("BrushStyle"))
        {
             if(subStrings.size()!=0)
             {
                  subStrings.push_back("\n");
             }
             subStrings.push_back(subText);
             subStrings.push_back("\n");
        }


        if((!subText.contains("Coords"))&&(!subText.contains("Line"))&&(!subText.contains("Rectangle"))&&(!subText.contains("Ellipse"))&&(!subText.contains("RoundRect"))&&(!subText.contains("Color")))
        {
            subStrings.push_back(subText+" ");
        }

    }
}
