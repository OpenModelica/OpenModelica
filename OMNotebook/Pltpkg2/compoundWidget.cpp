#include "compoundWidget.h"
#include "preferenceWindow.h"

CompoundWidget::CompoundWidget(QWidget* parent):  QWidget(parent)
{
	setupUi(this);

	QFont f("Arial",10);
	f.setBold(true);
	plotTitle->setFont(f); 
	gwMain->gvBottom = gvBottom;
	gwMain->gvLeft = gvLeft;



	gvBottom->setScene(gwMain->graphicsScene->xRulerScene);
	gvLeft->setScene(gwMain->graphicsScene->yRulerScene);
	gvBottom->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
	gvBottom->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
	gvLeft->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
	gvLeft->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);	

	connect(gwMain, SIGNAL(resizeY(quint32)), this, SLOT(resizeY(quint32)));
	connect(gwMain, SIGNAL(showPreferences2()), this, SLOT(showPreferences()));

	layout = new QVBoxLayout;
	legendFrame->setLayout(layout);

	gwMain->legendLayout = layout;
	gwMain->legendFrame = legendFrame;

}

CompoundWidget::~CompoundWidget()
{

	delete layout;

}

void CompoundWidget::showPreferences()
{
	PreferenceWindow* pw = new PreferenceWindow(this, 0);
	pw->setAttribute(Qt::WA_DeleteOnClose);
	pw->show();

}