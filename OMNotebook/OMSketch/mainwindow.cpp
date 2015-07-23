
//QT Headers
#include <QtGlobal>
#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
#include <QtWidgets>
#else
#include <QtGui/QApplication>
#include <QtGui/QMenuBar>
#include <QtGui/QStatusBar>
#include <QtGui/QToolBar>
#include <QtGui/QWidget>
#endif

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

#if (QT_VERSION >= QT_VERSION_CHECK(5, 0, 0))
  this->setWindowTitle(QApplication::translate("MainWindow", "MainWindow", 0));
#else
  this->setWindowTitle(QApplication::translate("MainWindow", "MainWindow", 0, QApplication::UnicodeUTF8));
#endif

  QMetaObject::connectSlotsByName(this);
}

MainWindow::~MainWindow()
{

}
