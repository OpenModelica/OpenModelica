#include "CustomDialog.h"

CustomDialog::CustomDialog(QWidget* parent):QDialog(parent)
{
    groups.clear();
    group.optLabels.clear();
    group.radioButtons.clear();
    button_box = new QDialogButtonBox(Qt::Vertical);
    button_box1 = new QDialogButtonBox(QDialogButtonBox::Ok|QDialogButtonBox::Cancel,Qt::Horizontal);


    connect(button_box1,SIGNAL(accepted()),this,SLOT(accept()));
    connect(button_box1,SIGNAL(rejected()),this,SLOT(reject()));

    values.clear();

}

void CustomDialog::Initialize()
{
    groups.clear();
    group.optLabels.clear();
    group.radioButtons.clear();
}

void CustomDialog::addGroup(QString grpname,QString checkName,int numOptions)
{
    group.CheckBox = new QCheckBox(grpname);
    group.button = new QPushButton(checkName);
    group.group_widget = new QWidget();
    group.num_options=numOptions;

    connect(group.button,SIGNAL(toggled(bool)),group.group_widget,SLOT(setVisible(bool)));

    groups.push_back(group);
}

void CustomDialog::addSubGroup(QString optionLabel,int indx)
{
    //group=groups[groups.size()-1];
    //group=groups.at(indx);
    qDebug()<<"size of groups "<<groups.size()<<"\n";
    groups[indx].optLabels.push_back(optionLabel);
    QRadioButton* button1 = new QRadioButton(optionLabel);
    groups[indx].radioButtons.push_back(button1);

}



void CustomDialog::add(int indx)
{
   //group=groups[groups.size()-1];
   qDebug()<<"size of groups "<<groups.size()<<"\n";
   //group=groups.at(indx);
   if(groups[indx].num_options==groups[indx].radioButtons.size())
   {

       QMessageBox::about(this,"hi","entered");
       groups[indx].grp_hlayout = new QHBoxLayout;
       groups[indx].grp_vlayout = new QVBoxLayout;
       groups[indx].grp_hlayout->addWidget(groups[indx].CheckBox);
       //groups[indx].grp_hlayout->addWidget(groups[indx].button);
       groups[indx].button->setCheckable(true);
       groups[indx].button->setAutoDefault(false);
       button_box->addButton(groups[indx].button,QDialogButtonBox::AcceptRole);

       groups[indx].grp_vlayout->addLayout(groups[indx].grp_hlayout);

       for(int i=0;i<groups[indx].radioButtons.size();i++)
       {
           groups[indx].grp_vlayout->addWidget(groups[indx].radioButtons[i]);
       }

       groups[indx].group_widget->setLayout(groups[indx].grp_vlayout);
   }
}

void CustomDialog::open()
{
    QGridLayout* layout = new QGridLayout;
    layout->setSizeConstraint(QLayout::SetFixedSize);

    qDebug()<<"size of groups "<<groups.size()<<"\n";

    layout->addWidget(button_box,0,1);
    //groups[0].group_widget->show();

    for(int i=0;i<groups.size();i++)
        groups[i].group_widget->hide();
    int i=0;
    for(i;i<groups.size();i++)
        layout->addWidget(groups[i].group_widget,i+2,0,i+3,groups[i].radioButtons.size());
    setLayout(layout);

    layout->addWidget(button_box1,i+3,1);


    setWindowTitle(tr("Styles"));

}

void CustomDialog::getValue(QString grpName,int &property)
{
   for(int i=0;i<groups.size();i++)
   {
       if(grpName==groups[i].CheckBox->text())
       {
          for(int j=0;j<groups[i].radioButtons.size();j++)
          {
              if(groups[0].radioButtons[j]->isChecked())
              {
                 QMessageBox::about(this,"hi",groups[0].radioButtons[j]->text());
                 property=j;
              }
          }
       }
   }
}

/*void CustomDialog::accept()
{
   values.clear();
   for(int i=0;i<groups.size();i++)
   {
       for(int j=0;j<groups[i].radioButtons.size();j++)
       {
           if(groups[0].radioButtons[j]->isChecked())
           {
              values.push_back(j);
           }
       }
   }
   QDialog::close();
}


void CustomDialog::reject()
{
    values.clear();
}*/


void CustomDialog::changeEvent(QEvent *event)
{
    if(event->type()==QEvent::OkRequest)
        QMessageBox::about(this,"hi","event accepted");

}


