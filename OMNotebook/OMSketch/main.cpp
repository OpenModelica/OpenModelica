#include <QtGui/QApplication>
#include "mainwindow.h"
#include "c:/sketch/Tools.h"
int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    Tools window;
    window.resize(1200,800);
    window.show();

    return a.exec();
}
