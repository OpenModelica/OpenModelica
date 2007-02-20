#ifndef DATASELECT_H
#define DATASELECT_H
#include "ui_dataSelect.h"
#include <QDialog>
#include <QStringList>
#include <QString>

using namespace std;

class DataSelect: public QDialog, private Ui::dataSelect
{
   public:
      DataSelect(QWidget* parent = 0);
      ~DataSelect();

      
      bool getVariables(const QStringList&, QString&, QString&);

};


#endif
