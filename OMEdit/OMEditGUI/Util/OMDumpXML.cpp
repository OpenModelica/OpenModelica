/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR 
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2. 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE. 
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

#include <QDebug>
#include <QXmlStreamReader>
#include "OMDumpXML.h"

const char* OMEquationTypeToString(int t)
{
  static const char *kindToString[equationTypeSize] = {"start","parameter","initial","regular"};
  return kindToString[t];
}

QString OMOperation::toString()
{
  return "unknown operation";
}

OMOperationSimplify::OMOperationSimplify(QStringList ops)
{
  before = ops[0];
  after = ops[1];
}

QString OMOperationSimplify::toString()
{
  return "simplify: " + before + " => " + after;
}

OMOperationScalarize::OMOperationScalarize(int _index,QStringList ops)
{
  index = _index;
  before = ops[0];
  after = ops[1];
}

QString OMOperationScalarize::toString()
{
  return QString("scalarize(%1): %2 => %3").arg(index).arg(before).arg(after);
}

OMOperationInline::OMOperationInline(QStringList ops)
{
  before = ops[0];
  after = ops[1];
}

QString OMOperationInline::toString()
{
  return "inline: " + before + " => " + after;
}

OMOperationSubstitution::OMOperationSubstitution(QStringList ops)
{
  before = ops.takeFirst();
  substitutions = ops;
}

QString OMOperationSubstitution::toString()
{
  return "substitute: " + before + " => " + substitutions.join(" => ");
}

OMOperationSolved::OMOperationSolved(QStringList ops)
{
  lhs = ops[0];
  rhs = ops[1];
}

QString OMOperationSolved::toString()
{
  return "solved: " + lhs + " = " + rhs;
}

OMOperationLinearSolved::OMOperationLinearSolved(QStringList ops)
{
  text = ops[0];
}

QString OMOperationLinearSolved::toString()
{
  return "linear-solved: " + text;
}

OMOperationSolve::OMOperationSolve(QStringList ops)
{
  lhs_old = ops[0];
  rhs_old = ops[1];
  lhs_new = ops[2];
  rhs_new = ops[3];
}

QString OMOperationSolve::toString()
{
  return "solve: " + lhs_old + " = " + rhs_old + " => " + lhs_new + " = " + rhs_new;
}

OMOperationDifferentiate::OMOperationDifferentiate(QStringList ops)
{
  exp = ops[0];
  wrt = ops[1];
  result = ops[2];
}

QString OMOperationDifferentiate::toString()
{
  return "differentiate: d" + exp + "/d" + wrt + " = " + result;
}

OMOperationResidual::OMOperationResidual(QStringList ops)
{
  lhs = ops[0];
  rhs = ops[1];
  result = ops[2];
}

QString OMOperationResidual::toString()
{
  return "residual: " + lhs + " = " + rhs + " => 0 = " + result;
}

OMOperationDummyDerivative::OMOperationDummyDerivative(QStringList ops)
{
  chosen = ops.takeFirst();
  candidates = ops;
}

QString OMOperationDummyDerivative::toString()
{
  return "dummy derivative: " + chosen + ", not chosen " + candidates.join(",");
}

QString OMInfo::toString() {
  QString result;
  QTextStream(&result) << "[" << file << ":" << lineStart << ":" << colStart << "-" << lineEnd << ":" << colEnd << "]";
  return result;
}

OMVariable::~OMVariable() {
  foreach (OMOperation *op, ops) {
    delete op;
  }
}

OMEquation::~OMEquation() {
  foreach (OMOperation *op, ops) {
    delete op;
  }
}

QString OMEquation::toString()
{
  if (text.size() < 1) {
    return "(dummy equation)";
  } else if (text[0] == "assign") {
    return QString("(assignment) %1 = %2").arg(defines[0]).arg(text[1]);
  } else if (text[0] == "statement") {
    return "(statement) " + text[1];
  } else {
    return "(" + text.join(",") + ")";
  }
}

MyHandler::MyHandler(QFile &file)
{
  QXmlSimpleReader xmlReader;
  QXmlInputSource *source = new QXmlInputSource(&file);
  xmlReader.setContentHandler(this);
  xmlReader.setErrorHandler(this);
  bool ok = xmlReader.parse(source);
  delete source;
  if (!ok) {
    throw QString("Parsing failed: %1").arg(file.fileName());
  }
}

bool MyHandler::startDocument()
{
  variables.clear();
  equations.clear();
  equations.append(OMEquation());
  currentKind = start;
  return true;
}

bool MyHandler::endDocument()
{
  currentVariable.ops.clear(); /* avoid double delete */
  currentEquation.ops.clear(); /* avoid double delete */
  return true;
}

bool MyHandler::characters( const QString & ch )
{
  currentText = ch;
  return true;
}

bool MyHandler::startElement( const QString & namespaceURI, const QString & localName, const QString & qName, const QXmlAttributes & atts)
{
  if (qName == "variable") {
    currentVariable.name = atts.value("name");
    currentVariable.comment = atts.value("comment");
    memset(currentVariable.definedIn,0,sizeof(currentVariable.definedIn));
    for (int i=0; i<equationTypeSize; i++) {
      currentVariable.usedIn[i].clear();
    }
  } else if (qName == "info") {
    currentInfo.file = atts.value("file");
    currentInfo.lineStart = atts.value("lineStart").toLong();
    currentInfo.lineEnd = atts.value("lineEnd").toLong();
    currentInfo.colStart = atts.value("colStart").toLong();
    currentInfo.colEnd = atts.value("colEnd").toLong();
  } else if (qName == "equation") {
    currentEquation.defines.clear();
    currentEquation.depends.clear();
    currentEquation.index = atts.value("index").toLong();
    currentEquation.kind = currentKind;
  } else if (qName == "equations" ||
             qName == "jacobian-equations") {
    currentKind = regular;
  } else if (qName == "initial-equations") {
    currentKind = initial;
  } else if (qName == "parameter-equations") {
    currentKind = parameter;
  } else if (qName == "start-equations") {
    currentKind = start;
  } else if (qName == "defines") {
    currentEquation.defines.append(atts.value("name"));
  } else if (qName == "depends") {
    currentEquation.depends.append(atts.value("name"));
  } else if (qName == "operations") {
    operations.clear();
  } else if (equationTags.contains(qName)) {
    texts.clear();
  } else if (operationTags.contains(qName)) {
    texts.clear();
    if (qName == "scalarize") {
      currentIndex = atts.value("index").toLong();
    }
  }

  return true;
}

bool MyHandler::endElement( const QString & namespaceURI, const QString & localName, const QString & qName)
{
  if (operationExpTags.contains(qName) || equationPartTags.contains(qName)) {
    texts.append(currentText.trimmed());
  }
  if (qName == "variable") {
    currentVariable.info = currentInfo;
    currentVariable.ops = operations;
    operations.clear();
    variables[currentVariable.name] = currentVariable;
  } else if (qName == "equation") {
    currentEquation.info = currentInfo;
    currentEquation.ops = operations;
    operations.clear();
    if (currentEquation.index != equations.size()) {
      printf("failing: %d expect %d\n", currentEquation.index, equations.size()+1);
      return false;
    }
    equations.append(currentEquation);
    foreach (QString def, currentEquation.defines) {
      int prev = variables[def].definedIn[currentEquation.kind];
      if (prev) {
        qDebug() << "failing: multiple define of " << def << ": " << prev << " and " << currentEquation.index << " for kind: " << currentEquation.kind;
        return false;
      }
      variables[def].definedIn[currentEquation.kind] = currentEquation.index;
    }
    foreach (QString def, currentEquation.depends) {
      variables[def].usedIn[currentEquation.kind].append(currentEquation.index);
    }
  } else if (equationTags.contains(qName)) {
    currentEquation.text = texts;
    currentEquation.text.prepend(qName);
    texts.clear();
  } else if (qName == "simplify") {
    operations.append(new OMOperationSimplify(texts));
  } else if (qName == "inline") {
    operations.append(new OMOperationInline(texts));
  } else if (qName == "substitution") {
    operations.append(new OMOperationSubstitution(texts));
  } else if (qName == "scalarize") {
    operations.append(new OMOperationScalarize(currentIndex,texts));
  } else if (qName == "solved") {
    operations.append(new OMOperationSolved(texts));
  } else if (qName == "linear-solved") {
    operations.append(new OMOperationLinearSolved(texts));
  } else if (qName == "solve") {
    operations.append(new OMOperationSolve(texts));
  } else if (qName == "derivative") {
    operations.append(new OMOperationDifferentiate(texts));
  } else if (qName == "op-residual") {
    operations.append(new OMOperationResidual(texts));
  } else if (qName == "dummyderivative") {
    operations.append(new OMOperationDummyDerivative(texts));
  }
  return true;
}

bool MyHandler::fatalError(const QXmlParseException & exception)
{
  qWarning() << "Fatal error on line" << exception.lineNumber()
             << ", column" << exception.columnNumber() << ":"
              << exception.message();
  return false;
}

const QSet<QString> MyHandler::operationTags = QSet<QString>() << "simplify" << "substitution" << "inline" << "scalarize" << "solved" << "linear-solved" << "solve" << "derivative" << "op-residual" << "dummyderivative";
const QSet<QString> MyHandler::operationExpTags = QSet<QString>() << "before" << "after" << "lhs" << "rhs" << "exp" << "result" << "with-respect-to";
const QSet<QString> MyHandler::equationTags = QSet<QString>() << "residual" << "assign" << "statement" << "linear" << "nonlinear" << "mixed" << "when" << "ifequation";
const QSet<QString> MyHandler::equationPartTags = QSet<QString>() << "residual" << "rhs" << "statement" << "row" << "cell";

#if 0

#include <time.h>
static clockid_t omc_clock = CLOCK_MONOTONIC;
struct timespec tick_tp;

void rt_tick() {
  clock_gettime(omc_clock, &tick_tp);
}

double rt_tock() {
  struct timespec tock_tp = {0,0};
  clock_gettime(omc_clock, &tock_tp);
  return (tock_tp.tv_sec - tick_tp.tv_sec) + (tock_tp.tv_nsec - tick_tp.tv_nsec)*1e-9;
}

int test_dump_xml_reader() {
  QFile file("Modelica.Mechanics.MultiBody.Examples.Elementary.DoublePendulum_info.xml");
  rt_tick();
  MyHandler handler(file);
  qDebug() << QString("streaming done in: %1 ms\n").arg(rt_tock() *1e3);
  qDebug() << handler.variables["revolute2.w"].info.toString();
  qDebug() << handler.variables["revolute2.w"].comment;
  qDebug() << handler.equations[1647].info.toString();
  for (int i=0; i<equationTypeSize; i++) {
    const char *var = "boxBody1.body.sphereDiameter";
    if (handler.variables[var].definedIn[i]) {
      qDebug() << var << " defined in (" << OMEquationTypeToString(i) << "): " << handler.variables["boxBody1.body.sphereDiameter"].definedIn[i];
    }
  }
  qDebug() << "text " << handler.equations[1647-1].toString();
  qDebug() << "defines " << handler.equations[1647-1].defines.join(",");
  qDebug() << handler.equations[1].info.toString();
  qDebug() << "eq text: " << handler.equations[1].toString();
  qDebug() << handler.equations[1].defines.join(",");
  qDebug() << "eq1 depends on: " << handler.equations[1].depends;
  qDebug() << "revolute1.frame_b.f[3] operations";
  foreach (OMOperation *op, handler.variables["revolute1.frame_b.f[3]"].ops) {
    qDebug() << op->toString();
  }
  const char *var = "world.nominalLength";
  for (int i=0; i<equationTypeSize; i++) {
    qDebug() << var << " used in (" << OMEquationTypeToString(i) << "): " << handler.variables[var].usedIn[i];
  }
  return 0;
}
#endif
