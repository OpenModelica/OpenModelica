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

#include "VerificationGenerator.h"

#include <QRegularExpression>
#include <QTextStream>

namespace CRMLBindings {

QString requirementResultToString(RequirementResult result)
{
  switch (result) {
    case RequirementResult::Satisfied: return QStringLiteral("Satisfied");
    case RequirementResult::Violated: return QStringLiteral("Violated");
    case RequirementResult::Undecided: return QStringLiteral("Undecided");
  }
  return QStringLiteral("Undecided");
}

RequirementResult requirementResultFromBoolean4(int value)
{
  // enumeration(undefined, undecided, false4, true4)
  if (value == 4) {
    return RequirementResult::Satisfied;
  } else if (value == 3) {
    return RequirementResult::Violated;
  }
  return RequirementResult::Undecided;
}

VerificationGenerator::VerificationGenerator(const VerificationConfiguration &configuration, const CrmlExternals &externals,
                                             const ModelIndex &index, const Resolution &resolution)
  : mConfiguration(configuration), mExternals(externals), mIndex(index), mResolution(resolution)
{
}

QString VerificationGenerator::packageName() const
{
  QString name = mConfiguration.mName;
  name.replace(QRegularExpression("[^A-Za-z0-9_]"), "_");
  if (name.isEmpty() || name.at(0).isDigit()) {
    name.prepend("V_");
  }
  return name;
}

QString VerificationGenerator::toModelica(const QJsonValue &value)
{
  switch (value.type()) {
    case QJsonValue::Bool:
      return value.toBool() ? "true" : "false";
    case QJsonValue::Double:
      return QString::number(value.toDouble(), 'g', 17);
    case QJsonValue::String: {
      QString text = value.toString();
      text.replace("\\", "\\\\").replace("\"", "\\\"");
      return "\"" + text + "\"";
    }
    case QJsonValue::Array: {
      QStringList items;
      for (const QJsonValue &item : value.toArray()) {
        items.append(toModelica(item));
      }
      return "{" + items.join(", ") + "}";
    }
    default:
      return QString();
  }
}

static QString indent(const QString &text, const QString &prefix)
{
  QStringList lines = text.split('\n');
  for (QString &line : lines) {
    while (line.endsWith(' ') || line.endsWith('\t') || line.endsWith('\r')) {
      line.chop(1);
    }
    if (!line.isEmpty()) {
      line.prepend(prefix);
    }
  }
  return lines.join('\n');
}

static QString componentName(const QString &name)
{
  QString result = name;
  return result.replace('.', '_');
}

static QString placement(int x, int y, int w = 20, int h = 20)
{
  return QString("annotation(Placement(transformation(origin = {%1, %2}, extent = {{-%3, -%4}, {%3, %4}})))").arg(x).arg(y).arg(w/2).arg(h/2);
}

QString VerificationGenerator::generate(const QString &translatedRequirement)
{
  mStatusVariables.clear();
  const QString req = BindingEngine::requirementInstanceName;
  const QString behav = BindingEngine::behaviourInstanceName;
  QString requirement = translatedRequirement;
  requirement.remove(QRegularExpression("^\\s*within[^;]*;\\s*"));
  requirement = requirement.trimmed();

  QString text;
  QTextStream out(&text);
  out << "package " << packageName() << " \"Verification model generated from configuration " << mConfiguration.mName << "\"\n";
  out << indent(requirement, "  ") << "\n\n";
  out << "  block RequirementStatus \"Accumulates a Boolean4 requirement over the simulation run\"\n"
         "    input CRMLtoModelica.Types.Boolean4 u \"Value of the requirement at the current instant\";\n"
         "    output CRMLtoModelica.Types.Boolean4 y \"true4: satisfied, false4: violated, else undecided\";\n"
         "    Real tTrue(start = 0, fixed = true) \"Time during which u was true4\";\n"
         "    Real tFalse(start = 0, fixed = true) \"Time during which u was false4\";\n"
         "  equation\n"
         "    // the observers are functions, so u can change without an event: integrate instead of using when\n"
         "    der(tTrue) = if u == CRMLtoModelica.Types.Boolean4.true4 then 1 else 0;\n"
         "    der(tFalse) = if u == CRMLtoModelica.Types.Boolean4.false4 then 1 else 0;\n"
         "    y = if tFalse > 0 then CRMLtoModelica.Types.Boolean4.false4 elseif tTrue > 0 then CRMLtoModelica.Types.Boolean4.true4 else CRMLtoModelica.Types.Boolean4.undefined;\n"
         "  end RequirementStatus;\n\n";

  out << "  model " << verificationModelName << " \"Verification of " << mExternals.mModel << " on " << mConfiguration.mBehaviourModel << "\"\n";
  out << "    " << mConfiguration.mBehaviourModel << " " << behav << " \"Behavioural model\" " << placement(-60, 0, 40, 40) << ";\n";
  QStringList sizes;
  for (const ResolvedSet &set : mResolution.mSets) {
    sizes.append(QString("%1 = %2").arg(set.mSizeParameter).arg(set.mElements.size()));
  }
  out << "    " << mExternals.mModel << " " << req;
  if (!sizes.isEmpty()) {
    out << "(" << sizes.join(", ") << ")";
  }
  out << " \"Requirement model\" " << placement(60, 0, 40, 40) << ";\n";
  for (const ArchitectureParameter &parameter : mResolution.mParameters) {
    out << "    parameter " << parameter.mType << " " << parameter.mName;
    if (!parameter.mDims.isEmpty()) {
      out << "[" << parameter.mDims.join(", ") << "]";
    }
    QString value = toModelica(parameter.mValue);
    if (!value.isEmpty()) {
      out << " = " << value;
    }
    out << " \"" << parameter.mElement << "." << parameter.mAttribute << "\";\n";
  }

  int y = 80;
  auto addStatus = [&](const QString &requirementName, const QString &element, const QString &input, int line) {
    RequirementStatusVariable status;
    status.mRequirement = requirementName;
    status.mElement = element;
    status.mLine = line;
    status.mComponent = element.isEmpty() ? requirementName + "_status" : QString("%1_%2_status").arg(requirementName, componentName(element));
    out << "    RequirementStatus " << status.mComponent << "(u = " << input << ") \"" << (element.isEmpty() ? requirementName : element + "." + requirementName)
        << "\" " << placement(140, y) << ";\n";
    y -= 30;
    mStatusVariables.append(status);
  };
  for (const CrmlVariable &requirementVariable : mExternals.mRequirements) {
    addStatus(requirementVariable.mName, QString(), req + "." + requirementVariable.mName, requirementVariable.mLine);
  }
  for (const ResolvedSet &set : mResolution.mSets) {
    if (const CrmlClass *pClass = mExternals.findClass(set.mElementClass)) {
      for (const CrmlVariable &requirementVariable : pClass->mRequirements) {
        for (int i = 0; i < set.mElements.size(); ++i) {
          addStatus(requirementVariable.mName, set.mElements.at(i), QString("%1.%2[%3].%4").arg(req, set.mName).arg(i + 1).arg(requirementVariable.mName),
                    requirementVariable.mLine);
        }
      }
    }
  }

  out << "  equation\n";
  for (const ResolvedExpression &expression : mResolution.mExpressions) {
    out << "    " << expression.mLeft << " = " << expression.call() << ";";
    if (!expression.mElement.isEmpty()) {
      out << " // " << expression.mElement << "." << expression.mVariable;
    }
    out << "\n";
  }
  out << "    annotation(";
  if (mIndex.mStopTime > 0) {
    out << "experiment(StopTime = " << QString::number(mIndex.mStopTime, 'g', 17) << "), ";
  }
  out << "Diagram(coordinateSystem(extent = {{-100, -100}, {160, 100}})));\n";
  out << "  end " << verificationModelName << ";\n";
  out << "end " << packageName() << ";\n";
  return text;
}

} // namespace CRMLBindings
