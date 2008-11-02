#include "evalthread.h"
#include <QPushButton>
#include <fstream>
#include <QApplication>
#include <QMessageBox>
using namespace std;




EvalThread::EvalThread(InputCellDelegate* delegate_, QString expr_, QObject* parent): QThread(parent), delegate(delegate_), expr(expr_)
{



}

EvalThread::~EvalThread()
{

}

void EvalThread::exceptionInEval(exception &e)
{
	// 2006-0-09 AF, try to reconnect to OMC first.
	try
	{
		delegate->closeConnection();
		delegate->reconnect();
		run();
	}
	catch( exception &e )
	{
		// unable to reconnect, ask if user want to restart omc.
		QString msg = QString( e.what() ) + "\n\nUnable to reconnect with OMC. Do you want to restart OMC?";
		int result = QMessageBox::critical( 0, tr("Communication Error with OMC"),
			msg,
			QMessageBox::Yes | QMessageBox::Default,
			QMessageBox::No );

		if( result == QMessageBox::Yes )
		{
			delegate->closeConnection();
			if( delegate->startDelegate() )
			{
				// 2006-03-14 AF, wait before trying to reconnect,
				// give OMC time to start up
				sleep(1000);
//				SleeperThread::msleep( 1000 );

				//delegate_->closeConnection();
				try
				{
					delegate->reconnect();
//					eval();
					run();
				}
				catch( exception &e )
				{
					QMessageBox::critical( 0, tr("Communication Error"),
						tr("<B>Unable to communication correctlly with OMC.</B>") );
				}
			}
		}
	}
}

void EvalThread::run()
{

	try
	{
		delegate->evalExpression(expr);
	}
	catch( exception &e )
	{
		exceptionInEval(e);
//		input_->blockSignals(false);
//		output_->blockSignals(false);
		return;
	}



}
