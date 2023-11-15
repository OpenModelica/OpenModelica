
//QT Headers
#include <QtGlobal>
#include <QtWidgets>

#include "mainwindow.h"

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent)
{
  QMenuBar *menuBar;
  QToolBar *mainToolBar;
  QWidget *centralWidget;
  QStatusBar *statusBar;
  if (this->objectName().isEmpty())
      this->setObjectName(QString::fromUtf8("MainWindow"));
  this->resize(400, 300);
  menuBar = new QMenuBar(this);
  menuBar->setObjectName(QString::fromUtf8("menuBar"));
  this->setMenuBar(menuBar);
  mainToolBar = new QToolBar(this);
  mainToolBar->setObjectName(QString::fromUtf8("mainToolBar"));
  this->addToolBar(mainToolBar);
  centralWidget = new QWidget(this);
  centralWidget->setObjectName(QString::fromUtf8("centralWidget"));
  this->setCentralWidget(centralWidget);
  statusBar = new QStatusBar(this);
  statusBar->setObjectName(QString::fromUtf8("statusBar"));
  this->setStatusBar(statusBar);

  this->setWindowTitle(QApplication::translate("MainWindow", "MainWindow", 0));

  QMetaObject::connectSlotsByName(this);
}

MainWindow::~MainWindow()
{

}
