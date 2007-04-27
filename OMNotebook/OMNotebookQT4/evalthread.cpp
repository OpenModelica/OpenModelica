#include "evalthread.h"
#include <QPushButton>
#include <fstream>
#include <QApplication>
using namespace std;




EvalThread::EvalThread(InputCellDelegate* delegate_, QString expr_, QObject* parent): QThread(parent), delegate(delegate_), expr(expr_)
{
	


}

EvalThread::~EvalThread()
{

}

void EvalThread::run()
{

		delegate->evalExpression(expr);
		



}