#include "indent.h"
#include <QRegExp>
#include <QMessageBox>
#include <QVariant>
#include <QDebug>
#include <cmath>
using namespace std;

IndentationState::~IndentationState()
{
	
}
Indent::ISM::ISM()
{
	level = 0;
	state = 0;
	skipNext = false;
	lMod = false;
	nextMod = 0;
}
Indent::ISM::~ISM()
{

}

void Indent::ISM::newToken(QString s, QString s2)
{
	if(skipNext)
	{
		skipNext = false;
		return;
	}

	if(state != 4 && s.count("\"")%2)
	{
		oldState = state;
		state = 4;
		return;
	}
/*
	if(state != 5 && s.left(2) == "//")
	{
		oldState = state;
		state = 5;
		return;
	}
*/
	switch(state)
	{
	case 0:
		loopBlock = false;

		if(s == "equation")
		{
			equationSection = true;
			lMod = true;
			break;
		}
		else if(s == "algorithm")
		{
			equationSection = false;
			lMod = true;
			break;
		}
		else if(s == "class" || s == "package" || s == "function" || s == "model" || s == "record" || s == "connector")
		{
			++level;
			skipNext = true;
			lMod = true;
			break;
		}
		else if(s == "end")
		{
			//			--level;
			nextMod = -1;
			skipNext = true;
			lMod = true;
			break;
		}
		else if(s == "public" || s == "protected")
		{
			lMod = true;
			break;
		}
		lMod = false;

		if(s2 == "if" || s == "if" )
		{
			if(s == "=")
				equation = true;
			else
				equation = false;

			state = 1;
			//			lMod = true;
		}
		else if(s == "when" || s == "for")
		{
			loopBlock = true;
			state = 1;

		}
		break;

	case 1:
		if(loopBlock && (s == "then" || s == "loop"))
		{
//			++level;
//			lMod = true;
			nextMod = +1;
			state = 0;
		}
		else if(s == "then" )
		{
//			++level;
			if(equation || equationSection)
				state = 2;
			else
				state = 3;
//			lMod = true;
			nextMod = +1;
		}

		break;

	case 2:
		if(s == "elseif" || (s == "else" && s2 == "if" && (skipNext = true)))
		{
//			lMod = true;;
			--level;
//						nextMod = -1;
			state = 1;
			break;
		}
		else if(s2 == "else")
		{
			//			lMod = true;
		}
		else if(s == "else")
		{
			lMod = true;

		}
		else
		{
			//			lMod = false;
			//--level;
			nextMod = -1;
			state = 0;
		}
		break;

	case 3:
		if( s == "elseif" || (s == "else" && s2 == "if" && (skipNext = true)))
		{
//			lMod = true;
			state = 1;
			//			nextMod = -1;
			--level;
		}
		else if(s == "when" || s == "for")
		{
			lMod = true;
			state = 1;

		}
		else if(s == "else")
		{
			lMod = true;
			state = 1;
			//			nextMod = -1;
			//			--level;
		}
		else if(s == "end" && (s2.left(2) == "if" || s2.left(3) == "for" || s2.left(4) == "when") && (skipNext = true))
		{
			//		skipNext = true;
			state = 0;
			--level;
			
			//			nextMod = -1;
			//			lMod = true;

		}

		break;
	case 4: //Text strings

		if(s.count("\"")%2)
			state = oldState;
		break;

	case 5: //Comments
	//	QMessageBox::information(0, "uu", s);
		if(s == "<newLine>")
			state = oldState;

		break;
	}
	//switch(state)
	//{
	//case 0: //default state
	//	if(s == QString("=") && s2 == QString("if"))
	//	{
	//		state = 1;
	//		break;
	//	}
	//	if(s == QString("algorithm"))
	//	{
	//		equation = false;
	//		break;
	//	}
	//	else if (s == QString("equation"))
	//	{
	//		equation = true;
	//		break;
	//	}

	//	if(s == QString("if"))
	//		state = equation?1:4;

	//	break;
	//case 1: // then, loop
	//	if(s == QString("then"))
	//	{
	//		state = 2;
	//		++currentLevel;
	//	}
	//	break;
	//case 2: // else

	//	if(s2 == QString("elseif"))
	//		state = 1;
	//	else if(s2 == QString("else"))
	//		state = 3;
	//	else
	//		state = 0;
	//	--currentLevel;

	//	break;
	//case 3: // if, elseif, end
	//	if(s == QString("else"))
	//	{
	//		if(s2 == QString("if"))
	//		{
	//			state = 1;
	//		}
	//		else
	//		{
	//			++currentLevel;
	//			state = 2;
	//		}
	//	}
	//	else if (s == QString("elseif"))
	//	{
	//		state = 1;
	//	}
	//	else
	//	{
	//		state = 0;
	//		equation = false;
	//	}
	//	break;
	//case 4: // if, elseif, end
	//	if(s == QString("then"))
	//	{
	//		++currentLevel;
	//		state = 5;
	//	}

	//	break;
	//case 5: // if, elseif, end
	//	if(s == QString("else"))
	//	{
	//		if(s2 == QString("if"))
	//		{
	//			state = 4;
	//			--currentLevel;

	//		}
	//		else
	//		{
	//			state = 6;
	//		}
	//	}
	//	else if(s == QString("end") && s2 == QString("if"))
	//		state = 7;
	//	break;
	//case 6: // if, elseif, end
	//	state = 5;
	//	break;
	//case 7:
	//	state = 0;
	//	--currentLevel;
	//	break;

	//}

}

Indent::Indent(QString s, bool aggressive_)
{
	//	ts.reset();
	buffer1 = s;
	//	QMessageBox::information(0, "uu3", s);
	//	ts.setString(s);
	//	ts << s.trimmed();
	//	ts.string()->append(s);
	//	ts.resetStatus();

	aggressive = aggressive_;
	currentLevel = 0;
	lineModifiers = 0;
}

Indent::~Indent()
{
}

void Indent::setText(QString s)
{
	ts.reset();
	ts << s;
}

int Indent::level()
{
	return ism.level;
}

bool Indent::lMod()
{
	return lmod;
}

QString Indent::indentedText(QMap<int, IndentationState*>* states)
{
	buffer1 = buffer1.replace('\n', " <newLine> ") + " <newLine> " + " <newLine> ";
	buffer1 = buffer1.replace("//", " //");
	buffer1 = buffer1.replace("=", " = ");
	QTextStream ts(&buffer1, QIODevice::ReadWrite);

	//QString current, next, comment;

	QString comment;

		current = "";
		ts >> next;
//	next = "";

	int newline, n, N=1;
	QString tmp, res, tmp2;
	while(!ts.atEnd())
	{
		current = next;
		ts >> next;
		newline = 0;
//*****************
		if((n=next.indexOf("//")) >=0)
		{
			//	QMessageBox::information(0, "uu", "." + next.right(next.size() -n) +".");
			comment = " " + next.right(next.size() -n);
			//			QMessageBox::information(0, "uu", "." + comment + ".");
			next = next.left(n);

			ts >> tmp2;
			while(tmp2 != "<newLine>")
			{
				//				QMessageBox::information(0, "uu2", tmp2);
				comment += " " + tmp2;
				ts >> tmp2;


			}
			//			tmp2 = ts.readLine();
			//			next = "<newLine>";
			//			comment += tmp2.left(tmp2.size() - next.size());
			next = tmp2;
			++newline;

		}
//********************
		//	newline = false;


		while(next == "<newLine>")
		{
			++newline;
			ts >> next;
		}


		//		if(next.left(2) == "//")
		//			comment = true;

//		qDebug() << current << ", " << next << endl;		

		ism.newToken(current, next);
//		qDebug() << ism.state << ", " << ism.level << ", " << ism.lMod << endl;

		if(current == "<newLine>")
		{
			current = "\n";
//			if(ism.state == 5)
//				ism.state = ism.oldState;
		}

		if(newline)
		{
			N += newline;
			//			qDebug() << ism.level << endl;
			//			if(ism.lMod)
			//				--ism.level;
			//			ism.level = max(ism.level, 0);
			//			QMessageBox::information(0, "uu", "." + comment + ".");
			if(comment.size())
			{
				res = res + "\n"  + QString(2*ism.level -2*ism.lMod, ' ')   +tmp   + current.trimmed()  +" " + comment.trimmed(); //QString(tmp.size()?1:0, ' ') + current.trimmed();
			}
			else
				res = res + "\n"  + QString(2*ism.level -2*ism.lMod, ' ')   +tmp   + current.trimmed()  +  QString(newline-1, '\n'); //QString(tmp.size()?1:0, ' ') + current.trimmed();
			//			res = res + "\n"  + QString(2*ism.level -2*ism.lMod, ' ')   +tmp   + current.trimmed()  + QString(comment.size()?1:0,'\n') + QString(newline-1, '\n'); //QString(tmp.size()?1:0, ' ') + current.trimmed();


			//			res = res + "\n" + QString(2*4 -2*2, '#') + tmp + QString(tmp.size()?0:1, ' ') + current;
			comment = "";
			tmp = "";
			ism.level += ism.nextMod;
			ism.nextMod = 0;
			
			lmod = ism.lMod;
			ism.lMod = false;
//			qDebug() << "nu" << endl;
			if(states && !(N % 10))
			{
				if(states->find(N) != states->end())
					states->remove(N);
					//					delete states->find(N);
				(*states)[N] = new IndentationState(ism.state, ism.level, ism.nextMod, current, next, ism.skipNext, ism.lMod, ism.equation, ism.equationSection, ism.loopBlock);
			}
		}
		else
			tmp +=  current.trimmed() +  QString(current.size()?1:0, ' ') ;


	}



	return res.trimmed();

}