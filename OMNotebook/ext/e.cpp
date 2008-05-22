#include <QApplication>
#include "../Pltpkg2/graphWindow.h" 
using namespace std;

int main(int argc, char** argv)
{
   QApplication a(argc, argv);

   GraphWindow w;
   w.compoundWidget->gwMain->setServerState(true);
   w.show();

	
   return a.exec();


}
