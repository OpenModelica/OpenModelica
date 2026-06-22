/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef INDENT_H
#define INDENT_H
#include <QString>
#include <QTextStream>
#include <QMap>

struct IndentationState {
  IndentationState(int state, int level, int nextMod, QString current, QString next, bool skipNext,
                   bool lMod, bool equation, bool equationSection, bool loopBlock)
    : level(level), state(state), nextMod(nextMod), current(current), next(next), skipNext(skipNext),
      lMod(lMod), equation(equation), equationSection(equationSection), loopBlock(loopBlock)
  {
  }

  int level, state, nextMod;
  QString current, next;
  bool skipNext, lMod, equation, equationSection, loopBlock;
};

class Indent {
public:
  Indent(QString s = QString(), bool aggressive = false);

  QString indentedText(QMap<int, IndentationState>* states = 0);
  void setText(QString);
  void setState(const IndentationState &state);
  int level();
  bool lMod();

private:
  int currentLevel;
  int lineModifiers;
  QTextStream ts;
  bool aggressive, lmod;
  QString buffer1, buffer2;

  struct ISM {
    ISM() = default;
    void newToken(QString, QString);

    int level = 0;
    int lineModifiers = 0;
    int state = 0;
    int nextMod = 0;
    bool equation = false;
    bool equationSection = false;
    bool loopBlock = false;
    bool skipNext = false;
    bool lMod = false;
    int oldState = 0;
  };

  ISM ism;
  QString current, next;
};

#endif
