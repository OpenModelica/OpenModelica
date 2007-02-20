#ifndef COMPOSITEWIDGET_H
#define COMPOSITEWIDGET_H
#include "ui_compoundWidget.h"
#include <QWidget>
#include <QGraphicsView>
#include "graphWidget.h"

using namespace std;

class CompoundWidget: public QWidget, public Ui::CompoundWidget
{
	Q_OBJECT
   public slots:
	
	   void resizeY(quint32 w)
	   {
			gvLeft->setMinimumWidth(w);
			gvLeft->update();
	   }

	   void showPreferences();

   public:
	   CompoundWidget(QWidget* parent = 0); 


	   ~CompoundWidget(); 

      
	   QVBoxLayout* layout;
};


#endif