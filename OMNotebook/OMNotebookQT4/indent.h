#ifndef INDENT_H
#define INDENT_H
#include <QString>
#include <QTextStream>
#include <QMap>

class IndentationState
{
public:
	IndentationState(int state_, int level_, int nextMod_, QString current_, QString next_, bool skipNext_, bool lMod_, bool equation_, bool equationSection_, bool loopBlock_):
	  state(state_), level(level_), nextMod(nextMod_), current(current_), next(next_), skipNext(skipNext_), lMod(lMod_), equation(equation_), equationSection(equationSection_), loopBlock(loopBlock_)
	  {

	  }
	  ~IndentationState();

	int level, state, nextMod;
	QString current, next;
	bool skipNext, lMod, equation, equationSection, loopBlock;
};
class Indent
{
public:
	Indent(QString t = QString(), bool a = false);
	~Indent();

	QString indentedText(QMap<int, IndentationState*>* states = 0);
	void setText(QString);
	int level();
	bool lMod();

private:
	int currentLevel;
	int lineModifiers;
	QTextStream ts;
	bool aggressive, lmod;
	QString buffer1, buffer2;

	class ISM
	{
	public:
		ISM();
		~ISM();

		void newToken(QString, QString);
		int level, lineModifiers, state, nextMod;
		bool equation, equationSection, loopBlock;
		bool skipNext;
		bool lMod;
		int oldState;


	};
public:
	ISM ism;
	QString current, next;
};


#endif