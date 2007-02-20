#ifndef GRAPHSCENE_H
#define GRAPHSCENE_H

#include <QMessageBox>
#include <QGraphicsScene>
#include <QGraphicsView>

class GraphScene: public QGraphicsScene
{
public:
	GraphScene(QObject * parent = 0): QGraphicsScene(parent)
	{
		grid = 0;
		gridVisible = false;

		xRulerScene = new QGraphicsScene(this);
		yRulerScene = new QGraphicsScene(this);


	}

	~GraphScene()
	{

	}

	QGraphicsItemGroup *grid;
	QList<QRectF> zoomHistory;
	bool gridVisible;

	QGraphicsScene* xRulerScene, *yRulerScene;
};


#endif