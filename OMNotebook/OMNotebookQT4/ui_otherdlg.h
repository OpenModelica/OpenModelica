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

class Ui_SelectDialog
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

    void setupUi(QDialog *SelectDialog)
    {
    SelectDialog->setObjectName(QString::fromUtf8("SelectDialog"));
    SelectDialog->resize(QSize(315, 58).expandedTo(SelectDialog->minimumSizeHint()));
    QSizePolicy sizePolicy(static_cast<QSizePolicy::Policy>(0), static_cast<QSizePolicy::Policy>(0));
    sizePolicy.setHorizontalStretch(0);
    sizePolicy.setVerticalStretch(0);
    sizePolicy.setHeightForWidth(SelectDialog->sizePolicy().hasHeightForWidth());
    SelectDialog->setSizePolicy(sizePolicy);
    verticalLayout = new QWidget(SelectDialog);
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

    layoutWidget = new QWidget(SelectDialog);
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

    retranslateUi(SelectDialog);
    QObject::connect(okButton, SIGNAL(clicked()), SelectDialog, SLOT(accept()));

    QMetaObject::connectSlotsByName(SelectDialog);
    } // setupUi

    void retranslateUi(QDialog *SelectDialog)
    {
    SelectDialog->setWindowTitle(QApplication::translate("SelectDialog", "Select value", 0, QApplication::UnicodeUTF8));
    label->setText(QApplication::translate("SelectDialog", "TextLabel", 0, QApplication::UnicodeUTF8));
    okButton->setText(QApplication::translate("SelectDialog", "OK", 0, QApplication::UnicodeUTF8));
    Q_UNUSED(SelectDialog);
    } // retranslateUi

};

namespace Ui {
    class SelectDialog: public Ui_SelectDialog {};
} // namespace Ui

#endif // UI_OTHERDLG_H
