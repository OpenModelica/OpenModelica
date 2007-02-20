#ifndef VARIABLEDATA_H
#define VARIABLEDATA_H
#include <QList>
#include <QString>
#include <QColor>

class VariableData: public QList<qreal>
{
   public:
	   VariableData(QString name_, QColor color_ = Qt::color0): currentIndex(0), name(name_), color(color_) {}
      ~VariableData();
      
      QString variableName() {return name;}
      void setVariableName(QString name_) {name = name_;}
	
	  quint32 currentIndex;
	  QColor color;
	
	private:

      QString name;

};





#endif
