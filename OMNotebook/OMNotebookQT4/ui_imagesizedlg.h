#ifndef UI_IMAGESIZEDLG_H
#define UI_IMAGESIZEDLG_H

#include <QtCore/QVariant>
#include <QtGui/QAction>
#include <QtGui/QApplication>
#include <QtGui/QButtonGroup>
#include <QtGui/QDialog>
#include <QtGui/QHBoxLayout>
#include <QtGui/QLabel>
#include <QtGui/QLineEdit>
#include <QtGui/QPushButton>
#include <QtGui/QSpacerItem>
#include <QtGui/QVBoxLayout>
#include <QtGui/QWidget>

class Ui_ImageDialog
{
public:
    QWidget *layoutWidget;
    QWidget *verticalLayout_2;
    QVBoxLayout *vboxLayout;
    QLabel *label;
    QHBoxLayout *hboxLayout;
    QLabel *label_2;
    QLineEdit *widthEdit;
    QLabel *label_3;
    QLineEdit *heightEdit;
    QWidget *verticalLayout;
    QVBoxLayout *vboxLayout1;
    QSpacerItem *spacerItem;
    QPushButton *okButton;

    void setupUi(QDialog *ImageDialog)
    {
    ImageDialog->setObjectName(QString::fromUtf8("ImageDialog"));
    ImageDialog->resize(QSize(317, 41).expandedTo(ImageDialog->minimumSizeHint()));
    layoutWidget = new QWidget(ImageDialog);
    layoutWidget->setObjectName(QString::fromUtf8("layoutWidget"));
    layoutWidget->setGeometry(QRect(20, 250, 351, 33));
    verticalLayout_2 = new QWidget(ImageDialog);
    verticalLayout_2->setObjectName(QString::fromUtf8("verticalLayout_2"));
    verticalLayout_2->setGeometry(QRect(0, 0, 241, 41));
    vboxLayout = new QVBoxLayout(verticalLayout_2);
    vboxLayout->setSpacing(6);
    vboxLayout->setMargin(0);
    vboxLayout->setObjectName(QString::fromUtf8("vboxLayout"));
    label = new QLabel(verticalLayout_2);
    label->setObjectName(QString::fromUtf8("label"));
    QSizePolicy sizePolicy(static_cast<QSizePolicy::Policy>(0), static_cast<QSizePolicy::Policy>(0));
    sizePolicy.setHorizontalStretch(0);
    sizePolicy.setVerticalStretch(0);
    sizePolicy.setHeightForWidth(label->sizePolicy().hasHeightForWidth());
    label->setSizePolicy(sizePolicy);

    vboxLayout->addWidget(label);

    hboxLayout = new QHBoxLayout();
    hboxLayout->setSpacing(6);
    hboxLayout->setMargin(0);
    hboxLayout->setObjectName(QString::fromUtf8("hboxLayout"));
    label_2 = new QLabel(verticalLayout_2);
    label_2->setObjectName(QString::fromUtf8("label_2"));

    hboxLayout->addWidget(label_2);

    widthEdit = new QLineEdit(verticalLayout_2);
    widthEdit->setObjectName(QString::fromUtf8("widthEdit"));

    hboxLayout->addWidget(widthEdit);

    label_3 = new QLabel(verticalLayout_2);
    label_3->setObjectName(QString::fromUtf8("label_3"));

    hboxLayout->addWidget(label_3);

    heightEdit = new QLineEdit(verticalLayout_2);
    heightEdit->setObjectName(QString::fromUtf8("heightEdit"));

    hboxLayout->addWidget(heightEdit);


    vboxLayout->addLayout(hboxLayout);

    verticalLayout = new QWidget(ImageDialog);
    verticalLayout->setObjectName(QString::fromUtf8("verticalLayout"));
    verticalLayout->setGeometry(QRect(240, 10, 77, 31));
    vboxLayout1 = new QVBoxLayout(verticalLayout);
    vboxLayout1->setSpacing(6);
    vboxLayout1->setMargin(0);
    vboxLayout1->setObjectName(QString::fromUtf8("vboxLayout1"));
    spacerItem = new QSpacerItem(20, 40, QSizePolicy::Minimum, QSizePolicy::Expanding);

    vboxLayout1->addItem(spacerItem);

    okButton = new QPushButton(verticalLayout);
    okButton->setObjectName(QString::fromUtf8("okButton"));

    vboxLayout1->addWidget(okButton);

    retranslateUi(ImageDialog);
    QObject::connect(okButton, SIGNAL(clicked()), ImageDialog, SLOT(accept()));

    QMetaObject::connectSlotsByName(ImageDialog);
    } // setupUi

    void retranslateUi(QDialog *ImageDialog)
    {
    ImageDialog->setWindowTitle(QApplication::translate("ImageDialog", "Set Image Size", 0, QApplication::UnicodeUTF8));
    label->setText(QApplication::translate("ImageDialog", "Select image size", 0, QApplication::UnicodeUTF8));
    label_2->setText(QApplication::translate("ImageDialog", "Width:", 0, QApplication::UnicodeUTF8));
    label_3->setText(QApplication::translate("ImageDialog", "Height:", 0, QApplication::UnicodeUTF8));
    okButton->setText(QApplication::translate("ImageDialog", "OK", 0, QApplication::UnicodeUTF8));
    Q_UNUSED(ImageDialog);
    } // retranslateUi

};

namespace Ui {
    class ImageDialog: public Ui_ImageDialog {};
} // namespace Ui

#endif // UI_IMAGESIZEDLG_H
