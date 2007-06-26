#ifndef EVALTHREAD_H
#define EVALTHREAD_H
#include <QThread>
#include "inputcelldelegate.h"
#include <QString>
using namespace std;
using namespace IAEX;

class EvalThread: public QThread
{
public:
	EvalThread(InputCellDelegate* delegate_, QString expr, QObject * parent = 0);
	~EvalThread();

	void run();
	void exceptionInEval(exception &e);

private:
	InputCellDelegate* delegate;
	QString expr;


};

#endif