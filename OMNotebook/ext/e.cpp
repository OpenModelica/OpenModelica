#include <QApplication>
#include "../Pltpkg2/graphWindow.h" 
using namespace std;

int main(int argc, char** argv)
{
   QApplication a(argc, argv);
   QFrame *mainFrame_ = new QFrame();
   SoQt::init(mainFrame_);
   GraphWindow *w = new GraphWindow(mainFrame_);
   w->compoundWidget->gwMain->setServerState(true);
   w->show();

   return a.exec();
}
