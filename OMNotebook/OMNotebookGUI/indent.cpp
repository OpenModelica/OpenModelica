/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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

#include "indent.h"
#include <QRegExp>
#include <QMessageBox>
#include <QDebug>

IndentationState::~IndentationState() {
}

Indent::ISM::ISM() {
  level = 0;
  state = 0;
  skipNext = false;
  lMod = false;
  nextMod = 0;
}

Indent::ISM::~ISM() {
}

void Indent::ISM::newToken(QString s, QString s2) {
  if(skipNext) {
    skipNext = false;
    return;
  }

  if(state != 4 && s.count("\"")%2) {
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
  switch(state) {
  case 0:
    loopBlock = false;

    if(s == "equation") {
      equationSection = true;
      lMod = true;
      break;
    } else if(s == "algorithm") {
      equationSection = false;
      lMod = true;
      break;
    } else if(s == "class" || s == "package" || s == "function" || s == "model" || s == "block" || s == "record" || s == "connector") {
      ++level;
      skipNext = true;
      lMod = true;
      break;
    } else if(s == "end") {
      //--level;
      nextMod = -1;
      skipNext = true;
      lMod = true;
      break;
    } else if(s == "public" || s == "protected") {
      lMod = true;
      break;
    }
    //lMod = false;

    if(s2 == "if" || s == "if" ) {
      if(s == "=") {
        equation = true;
      } else {
        equation = false;
      }
      state = 1;
      ++level;
      lMod = true;
    } else if(s == "when" || s == "for") {
      loopBlock = true;
      ++level;
      state = 1;
    }
    break;

  case 1:
    if(loopBlock && (s == "then" || s == "loop")) {
      //++level;
      lMod = true;
      //nextMod = +1;
      state = 0;
    } else if(s == "then" ) {
      //++level;
      lMod = true;
      if(equation || equationSection) {
        state = 2;
      } else {
        state = 3;
      }
    }
    break;

  case 2:
    if(s == "elseif" || (s == "else" && s2 == "if" && (skipNext = true))) {
      lMod = true;
      //--level;
      //nextMod = -1;
      state = 1;
      break;
    } else if(s == "else") {
      lMod = true;
    } else if(s == "end" && s2.left(2)=="if") {
      //lMod = true;
      level--;
      state = 0;
      skipNext = true;
    } else {
      //lMod = false;
      //--level;
      //nextMod = -1;
      //state = 0;
    }
    if (equation && s.right(1)==";") {
      nextMod = -1;
      state = 0;
    }
    break;

  case 3:
    if( s == "elseif" || (s == "else" && s2 == "if" && (skipNext = true))) {
      //lMod = true;
      state = 1;
      //nextMod = -1;
      --level;
    } else if(s == "when" || s == "for") {
      lMod = true;
      state = 1;
    } else if(s == "else") {
      lMod = true;
      state = 1;
      //nextMod = -1;
      //--level;
    } else if(s == "end" && (s2.left(2) == "if" || s2.left(3) == "for" || s2.left(4) == "when") && (skipNext = true)) {
      //skipNext = true;
      state = 0;
      --level;
      //nextMod = -1;
      //lMod = true;
    }
    break;

  case 4: //Text strings
    if(s.count("\"")%2) {
      state = oldState;
    }
    break;

  case 5: //Comments
    if(s == "<newLine>") {
      state = oldState;
    }
    break;
  }
}

Indent::Indent(QString s, bool aggressive_) {
  //  ts.reset();
  buffer1 = s;
  //  ts.setString(s);
  //  ts << s.trimmed();
  //  ts.string()->append(s);
  //  ts.resetStatus();
  aggressive = aggressive_;
  currentLevel = 0;
  lineModifiers = 0;
}

Indent::~Indent() {
}

void Indent::setText(QString s) {
  ts.reset();
  ts << s;
}

int Indent::level() {
  return ism.level;
}

bool Indent::lMod() {
  return lmod;
}

QString Indent::indentedText(QMap<int, IndentationState*>* states) {
  buffer1 = buffer1.replace(QRegExp("(==|:=|<=|>=|<>|=|<|>)"), " \\1 ");
  buffer1 = buffer1.replace('\n', " <newLine> ") + " <newLine> " + " <newLine> ";
  buffer1 = buffer1.replace("//", " //");
  QTextStream ts(&buffer1, QIODevice::ReadWrite);

  //QString current, next, comment;
  QString comment;

  current = "";
  ts >> next;
  //next = "";

  int newline, n, N=1;
  QString tmp, res, tmp2;
  while(!ts.atEnd()) {
    current = next;
    ts >> next;
    newline = 0;
//*****************
    if((n=next.indexOf("//")) >=0) {
      comment = " " + next.right(next.size() -n);
      next = next.left(n);

      ts >> tmp2;
      while(tmp2 != "<newLine>") {
        comment += " " + tmp2;
        ts >> tmp2;
      }
      //tmp2 = ts.readLine();
      //next = "<newLine>";
      //comment += tmp2.left(tmp2.size() - next.size());
      next = tmp2;
      ++newline;
    }
//********************
    //  newline = false;

    while(next == "<newLine>") {
      ++newline;
      ts >> next;
    }

    //if(next.left(2) == "//") {
    //  comment = true;
    //}

    ism.newToken(current, next);
    //qDebug() << ism.state << ", " << ism.level << ", " << ism.lMod << endl;

    if(current == "<newLine>") {
      current = "\n";
      //if(ism.state == 5) {
      //  ism.state = ism.oldState;
      //}
    }

    if(newline) {
      N += newline;
      //if(ism.lMod) {
      //  --ism.level;
      //}
      //ism.level = max(ism.level, 0);
      if(comment.size()) {
        res = res + "\n"  + QString(2*ism.level -2*ism.lMod, ' ')   +tmp   + current.trimmed()  +" " + comment.trimmed(); //QString(tmp.size()?1:0, ' ') + current.trimmed();
      } else {
        res = res + "\n"  + QString(2*ism.level -2*ism.lMod, ' ')   +tmp   + current.trimmed()  +  QString(newline-1, '\n'); //QString(tmp.size()?1:0, ' ') + current.trimmed();
        //res = res + "\n"  + QString(2*ism.level -2*ism.lMod, ' ')   +tmp   + current.trimmed()  + QString(comment.size()?1:0,'\n') + QString(newline-1, '\n'); //QString(tmp.size()?1:0, ' ') + current.trimmed();
        //res = res + "\n" + QString(2*4 -2*2, '#') + tmp + QString(tmp.size()?0:1, ' ') + current;
      }
      comment = "";
      tmp = "";
      ism.level += ism.nextMod;
      ism.nextMod = 0;

      lmod = ism.lMod;
      ism.lMod = false;
      if(states && !(N % 10)) {
        if(states->find(N) != states->end()) {
          states->remove(N);
        }
        (*states)[N] = new IndentationState(ism.state, ism.level, ism.nextMod, current, next, ism.skipNext, ism.lMod, ism.equation, ism.equationSection, ism.loopBlock);
      }
    } else {
      tmp +=  current.trimmed() +  QString(current.size()?1:0, ' ') ;
    }
  }
  return res.trimmed();
}
