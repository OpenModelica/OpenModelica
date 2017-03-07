#ifndef SKETCH_FILES_H
#define SKETCH_FILES_H

#include "basic.h"
#include "Scene_Objects.h"

class Sketch_Files
{
  public:
    Sketch_Files();
    void readXml(QString Filename);
    void readXml(QString Filename,QVector<QString> &subStrings);
    void readXml(QVector<Scene_Objects *> &objects,QString FileName);

    void writeXml(QString Filename);
    void writeXml(QVector<Scene_Objects *> &objects,QString FileName);

    void parseText(QString text, QVector<int> &values,QVector<float> &value);
    void parseText(QString text,QVector<QString> &subStrings);

  private:
    void parseText(QString text);
    QVector<int> values;
    Scene_Objects* object;
};

#endif // SKETCH_FILES_H
