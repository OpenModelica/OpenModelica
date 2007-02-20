#include "preferenceWindow.h"
#include "compoundWidget.h"
#include <QMessageBox>
#include <QRectF>


PreferenceWindow::PreferenceWindow(CompoundWidget* cw, QWidget *parent): QDialog(parent) 
{
	compoundWidget =cw;

	setupUi(this);

	vMin->setText(QVariant(compoundWidget->gwMain->currentArea.bottom()).toString());
	vMax->setText(QVariant(compoundWidget->gwMain->currentArea.top()).toString());
	hMin->setText(QVariant(compoundWidget->gwMain->currentArea.left()).toString());
	hMax->setText(QVariant(compoundWidget->gwMain->currentArea.right()).toString());

	connect(pbOk, SIGNAL(clicked()), this, SLOT(apply()));
	connect(pbApply, SIGNAL(clicked()), this, SLOT(apply()));
	connect(this, SIGNAL(setGrid(bool)), compoundWidget->gwMain, SLOT(showGrid(bool)));
}

PreferenceWindow::~PreferenceWindow()
{

}

void PreferenceWindow::apply()
{


	QRectF newArea = compoundWidget->gwMain->currentArea;
	if(vMin->isEnabled())
	{
		newArea.setBottom(QVariant(vMin->text()).toDouble());
		newArea.setTop(QVariant(vMax->text()).toDouble());
	}

	if(hMin->isEnabled())
	{
		newArea.setLeft(QVariant(hMin->text()).toDouble());
		newArea.setRight(QVariant(hMax->text()).toDouble());
	}


	if(newArea != compoundWidget->gwMain->currentArea)
		compoundWidget->gwMain->fitInView(newArea);

	compoundWidget->plotTitle->setText(plotTitle->text());
	compoundWidget->yLabel->setText(vLabel->text());
	compoundWidget->xLabel->setText(hLabel->text());
	
	emit setGrid(showGrid->isChecked());

	compoundWidget->legendFrame->setVisible(showLegend->isChecked());
	compoundWidget->gwMain->graphicsScene->update(compoundWidget->gwMain->currentArea);
	compoundWidget->gwMain->update();

}