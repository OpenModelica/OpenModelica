#ifndef UI_OTHERDLG_H
#define UI_OTHERDLG_H

#include <QtCore/QVariant>
#include <QtGui/QAction>
#include <QtGui/QApplication>
#include <QtGui/QButtonGroup>
#include <QtGui/QDialog>
#include <QtGui/QLabel>
#include <QtGui/QLineEdit>
#include <QtGui/QPushButton>
#include <QtGui/QSpacerItem>
#include <QtGui/QVBoxLayout>
#include <QtGui/QWidget>

class Ui_Dialog
{
public:
    QWidget *verticalLayout;
    QVBoxLayout *vboxLayout;
    QLabel *label;
    QLineEdit *lineEdit;
    QWidget *layoutWidget;
    QVBoxLayout *vboxLayout1;
    QSpacerItem *spacerItem;
    QPushButton *okButton;

    void setupUi(QDialog *Dialog)
    {
    Dialog->setObjectName(QString::fromUtf8("Dialog"));
    Dialog->resize(QSize(315, 58).expandedTo(Dialog->minimumSizeHint()));
    verticalLayout = new QWidget(Dialog);
    verticalLayout->setObjectName(QString::fromUtf8("verticalLayout"));
    verticalLayout->setGeometry(QRect(10, 10, 221, 41));
    vboxLayout = new QVBoxLayout(verticalLayout);
    vboxLayout->setSpacing(6);
    vboxLayout->setMargin(0);
    vboxLayout->setObjectName(QString::fromUtf8("vboxLayout"));
    label = new QLabel(verticalLayout);
    label->setObjectName(QString::fromUtf8("label"));

    vboxLayout->addWidget(label);

    lineEdit = new QLineEdit(verticalLayout);
    lineEdit->setObjectName(QString::fromUtf8("lineEdit"));

    vboxLayout->addWidget(lineEdit);

    layoutWidget = new QWidget(Dialog);
    layoutWidget->setObjectName(QString::fromUtf8("layoutWidget"));
    layoutWidget->setGeometry(QRect(230, 10, 77, 41));
    vboxLayout1 = new QVBoxLayout(layoutWidget);
    vboxLayout1->setSpacing(6);
    vboxLayout1->setMargin(0);
    vboxLayout1->setObjectName(QString::fromUtf8("vboxLayout1"));
    spacerItem = new QSpacerItem(20, 40, QSizePolicy::Minimum, QSizePolicy::Expanding);

    vboxLayout1->addItem(spacerItem);

    okButton = new QPushButton(layoutWidget);
    okButton->setObjectName(QString::fromUtf8("okButton"));

    vboxLayout1->addWidget(okButton);

    retranslateUi(Dialog);
    QObject::connect(okButton, SIGNAL(clicked()), Dialog, SLOT(accept()));

    QMetaObject::connectSlotsByName(Dialog);
    } // setupUi

    void retranslateUi(QDialog *Dialog)
    {
    Dialog->setWindowTitle(QApplication::translate("Dialog", "Dialog", 0, QApplication::UnicodeUTF8));
    label->setText(QApplication::translate("Dialog", "TextLabel", 0, QApplication::UnicodeUTF8));
    okButton->setText(QApplication::translate("Dialog", "OK", 0, QApplication::UnicodeUTF8));
    Q_UNUSED(Dialog);
    } // retranslateUi

};

namespace Ui {
    class Dialog: public Ui_Dialog {};
} // namespace Ui

#endif // UI_OTHERDLG_H
