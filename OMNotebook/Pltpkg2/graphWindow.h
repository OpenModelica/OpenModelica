#ifndef GRAPHWINDOW_H
#define GRAPHWINDOW_H

#include <QtGui/QMainWindow>
#include "ui_graphWindow.h"
//#include "compoundWidget.h"

class GraphWindow: public QMainWindow, public Ui::graphWindow
{
	Q_OBJECT
public:
	GraphWindow(QWidget* parent = 0);
	~GraphWindow();
	int serverPort() {return graphicsView->gwMain->serverPort();}



signals:
	void destroyed2();

	public slots:

		void openFile();
		void showMessage(QString message);
		void sceneDestroyed();
		void showPreferences();
public:
		CompoundWidget* compoundWidget;

private:
	

	bool readPLTFile(QString fileName);
};



#endif

