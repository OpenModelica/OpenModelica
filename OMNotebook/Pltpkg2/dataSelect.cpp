#include "dataSelect.h"
#include <iostream>
#include <QStringList>
using namespace std;


DataSelect::DataSelect(QWidget* parent): QDialog(parent)
{
	setupUi(this);

}

DataSelect::~DataSelect()
{


}

bool DataSelect::getVariables(const QStringList& vars, QString& xVar, QString& yVar)
{
	vData->addItems(vars);
	hData->addItems(vars);


	if(exec() == QDialog::Rejected)
		return false;

	xVar = hData->currentText();
	yVar = vData->currentText();

	return true;

}
