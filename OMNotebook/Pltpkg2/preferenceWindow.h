#ifndef PREFERENCEWINDOW_H
#define PREFERENCEWINDOW_H

#include <QtGui/QDialog>
#include "ui_preferences.h"
#include "compoundWidget.h"

class PreferenceWindow: public QDialog, public Ui::PreferenceDialog
{
	Q_OBJECT
public:
	PreferenceWindow(CompoundWidget* cw, QWidget* parent = 0);

	~PreferenceWindow();

public slots:
	void apply();

signals:
	void setLegend(bool visible);
	void setGrid(bool visible);


	

private:
	CompoundWidget* compoundWidget;

};



#endif

