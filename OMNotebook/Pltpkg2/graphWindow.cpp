#include "graphWindow.h"
#include <QString>
#include <QFileDialog>
#include <iostream>
#include <QFile>
#include <QTextStream>
#include "dataSelect.h"
#include <QMessageBox>
#include "preferenceWindow.h"
using namespace std;

GraphWindow::GraphWindow(QWidget* parent): QMainWindow(parent)
{
	setupUi(this);

	compoundWidget =graphicsView;
	QObject::connect(actionOpen, SIGNAL(activated()), this, SLOT(openFile()));

	connect(graphicsView->gwMain, SIGNAL(newMessage(QString)), this, SLOT(showMessage(QString)));
    QObject::connect(actionGrid, SIGNAL(toggled(bool)), graphicsView->gwMain, SLOT(showGrid(bool)));

    QObject::connect(actionPan, SIGNAL(toggled(bool)), graphicsView->gwMain, SLOT(setPan(bool)));
	QObject::connect(actionSelect, SIGNAL(toggled(bool)), graphicsView->gwMain, SLOT(setSelect(bool)));
	QObject::connect(actionZoom, SIGNAL(toggled(bool)), graphicsView->gwMain, SLOT(setZoom(bool)));

	connect(actionPreferences, SIGNAL(triggered()), compoundWidget, SLOT(showPreferences()));

	QActionGroup* ag = new QActionGroup(this);
	ag->addAction(actionPan);
	ag->addAction(actionSelect);
	ag->addAction(actionZoom);
	ag->setExclusive(true);
	
	
	connect(actionAboutQt, SIGNAL(triggered()), qApp, SLOT(aboutQt()));


}

GraphWindow::~GraphWindow()
{

}

void GraphWindow::showPreferences()
{

	PreferenceWindow* pw = new PreferenceWindow(compoundWidget, 0);
	pw->setAttribute(Qt::WA_DeleteOnClose);
	pw->show();

}

void GraphWindow::showMessage(QString message)
{
	statusbar->showMessage(message);

}
void GraphWindow::openFile()
{
	QString fileName = QFileDialog::getOpenFileName(this, tr("Open File"), "", tr("PtPlot files (*.plt);;All files (*)"));

	if(fileName.toLower().endsWith(".plt"))
		readPLTFile(fileName);
}


void GraphWindow::sceneDestroyed()
{

}
bool GraphWindow::readPLTFile(QString fileName)
{
	QFile file(fileName);

	if(!file.open(QFile::ReadOnly))
		return false;

	QTextStream ts(&file);

	QString tmp;
	VariableData *var1, *var2;
	var1 = new VariableData(QString("ptX"));

	while(!ts.atEnd())
	{
		do
		{
			if(ts.atEnd())
				break;

			tmp = ts.readLine().trimmed();
		}
		while(tmp.size() == 0);

		if(tmp.trimmed().size() == 0)
			break;

		graphicsView->gwMain->variables[var1->variableName()] = var1;

		if(tmp.startsWith("#"))
			continue;
		else if(tmp.startsWith("TitleText:"))
			;
		else if(tmp.startsWith("XLabel:"))
			;
		else if(tmp.startsWith("YLabel:"))
			;
		else if(tmp.startsWith("DataSet:"))
		{
			var2 = new VariableData(tmp.section(": ", 1, 1));
			if(graphicsView->gwMain->variables.find(var2->variableName()) != graphicsView->gwMain->variables.end())
				delete graphicsView->gwMain->variables[var2->variableName()];

			graphicsView->gwMain->variables[var2->variableName()] = var2;
			var1->clear();

		}
		else
		{
			*var1 << tmp.section(',', 0, 0).toDouble();
			*var2 << tmp.section(',', 1, 1).toDouble();

		}

	}
	for(map<QString, VariableData*>::iterator i = graphicsView->gwMain->variables.begin(); i != graphicsView->gwMain->variables.end(); ++i)
		cout << "variables: " << i->first.toStdString() << ", " << i->second->size() << endl;

	DataSelect* dataSelect = new DataSelect(this);

	QString xVar, yVar;
	QStringList variableNames;

	for(map<QString, VariableData*>::iterator i = graphicsView->gwMain->variables.begin(); i != graphicsView->gwMain->variables.end(); ++i)
		variableNames <<i->first;

	variableNames.sort();

	if(!dataSelect->getVariables(variableNames, xVar, yVar))
		return true;


	graphicsView->gwMain->plotVariables(xVar, yVar);

	return true;
}
