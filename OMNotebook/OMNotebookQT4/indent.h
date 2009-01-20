/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2009, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * For more information about the Qt-library visit TrollTech's webpage 
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
 */

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
