#ifndef CUSTOMDIALOG_H
#define CUSTOMDIALOG_H

#include "basic.h"

class CustomDialog: public QDialog
{
    Q_OBJECT;

   public:
     struct Group
     {
       QCheckBox* CheckBox;
       QPushButton* button;
       QVector<QRadioButton*> radioButtons;
       QVector<QString> optLabels;
       int num_options;
       QHBoxLayout* grp_hlayout;
       QVBoxLayout* grp_vlayout;
       QWidget* group_widget;

     };

     CustomDialog(QWidget* parent=0);
     void addGroup(QString grpName,QString checkName,int numOptions);
     void addSubGroup(QString optionLabel,int indx);
     void Initialize();
     void open();
     void add(int indx);
     void getValue(QString grpName,int &property);

     QVector<int> values;

     /*public slots:
     virtual void accept();
     virtual void reject();*/

     virtual void changeEvent(QEvent *event);


    QVector<Group> groups;
   private:


     void addGroups();




     Group group;

     QGridLayout* layout;
     QDialogButtonBox *button_box,*button_box1;

};

#endif // CUSTOMDIALOG_H
