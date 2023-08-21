/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Martin Sjölund <martin.sjolund@liu.se>
 */

#ifndef OMDUMPXML_H
#define OMDUMPXML_H

#include <QFile>
#include <QHash>

#include "diff_match_patch.h"

class OMOperation {
public:
  virtual ~OMOperation() {}
  virtual OMOperation* clone() const {return new OMOperation(*this);}
  virtual QString toString();
  virtual QString toHtml(HtmlDiff htmlDiff = HtmlDiff::Both);
  QString diffHtml(QString &before, QString &after, HtmlDiff htmlDiff);
};

class OMOperationInfo : public OMOperation
{
public:
  QString name,info;
  OMOperationInfo(QString name, QString info);
  // OMOperation interface
public:
  virtual OMOperation* clone() const override {return new OMOperationInfo(*this);}
  virtual QString toString() override;
  virtual QString toHtml(HtmlDiff htmlDiff) override;
};

class OMOperationBeforeAfter : public OMOperation
{
public:
  QString name,before,after;
  OMOperationBeforeAfter(QString name, QStringList ops);
  // OMOperation interface
public:
  virtual OMOperation* clone() const override {return new OMOperationBeforeAfter(*this);}
  virtual QString toString() override;
  virtual QString toHtml(HtmlDiff htmlDiff) override;
};

class OMOperationSimplify : public OMOperationBeforeAfter
{
public:
  OMOperationSimplify(QStringList ops) : OMOperationBeforeAfter("simplify",ops) {}
  // OMOperation interface
public:
  virtual OMOperation* clone() const override {return new OMOperationSimplify(*this);}
};

class OMOperationScalarize : public OMOperation
{
public:
  int index;
  QString before,after;
  OMOperationScalarize(int _index,QStringList ops);
  // OMOperation interface
public:
  virtual OMOperation* clone() const override {return new OMOperationScalarize(*this);}
  virtual QString toString() override;
};

class OMOperationInline : public OMOperationBeforeAfter
{
public:
  OMOperationInline(QStringList ops) : OMOperationBeforeAfter("inline",ops) {}
  // OMOperation interface
public:
  virtual OMOperation* clone() const override {return new OMOperationInline(*this);}
};

class OMOperationSubstitution : public OMOperationBeforeAfter
{
public:
  OMOperationSubstitution(QStringList ops) : OMOperationBeforeAfter("substitution",ops) {}
  // OMOperation interface
public:
  virtual OMOperation* clone() const override {return new OMOperationSubstitution(*this);}
};

class OMOperationSolved : public OMOperation
{
public:
  QString lhs,rhs;
  OMOperationSolved(QStringList ops);
  // OMOperation interface
public:
  virtual OMOperation* clone() const override {return new OMOperationSolved(*this);}
  virtual QString toString() override;
};

class OMOperationLinearSolved : public OMOperation
{
public:
  QString text;
  OMOperationLinearSolved(QStringList ops);
  // OMOperation interface
public:
  virtual OMOperation* clone() const override {return new OMOperationLinearSolved(*this);}
  virtual QString toString() override;
};

class OMOperationSolve : public OMOperation
{
public:
  QString lhs_old,rhs_old;
  QString lhs_new,rhs_new;
  OMOperationSolve(QStringList ops);
  // OMOperation interface
public:
  virtual OMOperation* clone() const override {return new OMOperationSolve(*this);}
  virtual QString toString() override;
};

class OMOperationDifferentiate : public OMOperation
{
public:
  QString exp,wrt,result;
  OMOperationDifferentiate(QStringList ops);
  // OMOperation interface
public:
  virtual OMOperation* clone() const override {return new OMOperationDifferentiate(*this);}
  virtual QString toString() override;
};

class OMOperationResidual : public OMOperation
{
public:
  QString lhs,rhs,result;
  OMOperationResidual(QStringList ops);
  // OMOperation interface
public:
  virtual OMOperation* clone() const override {return new OMOperationResidual(*this);}
  virtual QString toString() override;
};

class OMOperationDummyDerivative : public OMOperation
{
public:
  QString chosen;
  QStringList candidates;
  OMOperationDummyDerivative(QStringList ops);
  // OMOperation interface
public:
  virtual OMOperation* clone() const override {return new OMOperationDummyDerivative(*this);}
  virtual QString toString() override;
};

class OMOperationFlattening : public OMOperationBeforeAfter
{
public:
  OMOperationFlattening(QStringList ops) : OMOperationBeforeAfter("flattening", ops) {}
  // OMOperation interface
public:
  virtual OMOperation* clone() const override {return new OMOperationFlattening(*this);}
};

struct OMInfo {
  QString file;
  int lineStart,lineEnd,colStart,colEnd;
  bool isValid;
  OMInfo();
  QString toString();
};

struct OMVariable {
  QString name;
  QString comment;
  OMInfo info;
  QStringList types;
  QList<int> definedIn;
  QList<int> usedIn;
  QList<OMOperation*> ops;
  OMVariable();
  OMVariable(const OMVariable& var);
  OMVariable& operator=(const OMVariable& var);
  void copyData(const OMVariable& var);
  ~OMVariable();
};

struct OMEquation {
  QString section;
  int index,profileBlock,parent,ncall;
  double time,maxTime,fraction;
  QString tag, display;
  QStringList text;
  OMInfo info;
  QStringList types;
  QStringList defines;
  QStringList depends;
  QList<OMOperation*> ops;
  QList<int> eqs;
  int unknowns;
  OMEquation();
  ~OMEquation();
  QString toString();
};

class MyHandler {
public:
  bool hasOperationsEnabled;
  MyHandler(QFile &file, QHash<QString,OMVariable> &vars, QList<OMEquation*> &eqs);
  ~MyHandler();
private:
  QHash<QString,OMVariable> &variables;
  QList<OMEquation*> &equations;
  OMVariable currentVariable;
  OMEquation *currentEquation;
  QList<int> nestedEquations;
  OMInfo currentInfo;
  QString currentSection;
  QString currentText;
  QStringList texts;
  QList<OMOperation*> operations;
  int currentIndex;
  static const QSet<QString> equationTags;
  static const QSet<QString> equationPartTags;
  static const QSet<QString> operationTags;
  static const QSet<QString> operationExpTags;
};

#endif
