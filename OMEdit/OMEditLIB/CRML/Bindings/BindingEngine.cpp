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

#include "BindingEngine.h"

#include <QRegularExpression>
#include <QSet>
#include <algorithm>

namespace CRMLBindings {

static Diagnostic diagnostic(Diagnostic::Severity severity, const QString &code, const QString &message, const QString &bindingId = QString())
{
  Diagnostic d;
  d.mSeverity = severity;
  d.mCode = code;
  d.mMessage = message;
  d.mBindingId = bindingId;
  return d;
}

static QString describe(const QString &element, const QString &variable)
{
  return element.isEmpty() ? variable : element + "." + variable;
}

QString ResolvedExpression::call() const
{
  QStringList arguments;
  for (const ResolvedArgument &argument : mArguments) {
    arguments.append(argument.mInput + " = " + argument.mExpression);
  }
  return QString("%1(%2)").arg(mObserver, arguments.join(", "));
}

bool Resolution::hasErrors() const
{
  return std::any_of(mDiagnostics.cbegin(), mDiagnostics.cend(), [](const Diagnostic &d) {return d.mSeverity == Diagnostic::Error;});
}

BindingEngine::BindingEngine(const VerificationConfiguration &configuration, const CrmlExternals &externals,
                             const ArchitectureModel &architecture, const ModelIndex &index)
  : mConfiguration(configuration), mExternals(externals), mArchitecture(architecture), mIndex(index)
{
}

QString BindingEngine::classOf(const QString &instance) const
{
  if (const ArchitectureElement *pElement = mArchitecture.findElement(instance)) {
    return pElement->mType;
  }
  if (const ModelicaInstance *pInstance = mIndex.findInstance(instance)) {
    return pInstance->mClassName;
  }
  return QString();
}

bool BindingEngine::isA(const QString &className, const QString &base) const
{
  return mIndex.isA(className, base) || mArchitecture.isA(className, base);
}

static QString baseType(const QString &type)
{
  if (type == QLatin1String("Integer") || type == QLatin1String("Real")) {
    return QStringLiteral("Real");
  }
  return type;
}

QString BindingEngine::variableType(const InputMapping &mapping, QStringList *pDims) const
{
  if (mapping.mSource == InputMapping::Architecture) {
    if (const ArchitectureAttribute *pAttribute = mArchitecture.findAttribute(mapping.mClass, mapping.mVariable)) {
      *pDims = pAttribute->mDims;
      return pAttribute->mType;
    }
  } else if (const ModelicaClass *pClass = mIndex.findClass(mapping.mClass)) {
    if (const ModelicaVariable *pVariable = pClass->findVariable(mapping.mVariable)) {
      *pDims = pVariable->mDims;
      return pVariable->mType;
    }
  }
  return QString();
}

bool BindingEngine::observerTypesMatch(const Observer &observer, const InputBinding &inputBinding, QList<Diagnostic> &diagnostics) const
{
  bool ok = true;
  for (const InputMapping &mapping : inputBinding.mInputs) {
    const ModelicaVariable *pInput = observer.findInput(mapping.mInput);
    if (!pInput) {
      diagnostics.append(diagnostic(Diagnostic::Error, "VW008", QString("Observer %1 has no input %2.").arg(observer.mName, mapping.mInput), inputBinding.mId));
      ok = false;
      continue;
    }
    QStringList dims;
    QString type = variableType(mapping, &dims);
    if (type.isEmpty()) {
      diagnostics.append(diagnostic(Diagnostic::Error, "VW008", QString("%1.%2, bound to input %3 of %4, does not exist.")
                                    .arg(mapping.mClass, mapping.mVariable, mapping.mInput, observer.mName), inputBinding.mId));
      ok = false;
      continue;
    }
    if (baseType(type) != baseType(pInput->mType) || dims.size() != pInput->mDims.size()) {
      diagnostics.append(diagnostic(Diagnostic::Error, "VW003", QString("Input %1 of %2 is %3%4, but %5.%6 is %7%8.")
                                    .arg(mapping.mInput, observer.mName, pInput->mType,
                                         pInput->mDims.isEmpty() ? QString() : "[" + pInput->mDims.join(", ") + "]",
                                         mapping.mClass, mapping.mVariable, type, dims.isEmpty() ? QString() : "[" + dims.join(", ") + "]"),
                                    inputBinding.mId));
      ok = false;
    }
  }
  for (const ModelicaVariable &input : observer.mInputs) {
    if (!input.mHasDefault && !inputBinding.findInput(input.mName)) {
      diagnostics.append(diagnostic(Diagnostic::Error, "VW007", QString("Input %1 of %2 is not bound and has no default value.").arg(input.mName, observer.mName), inputBinding.mId));
      ok = false;
    }
  }
  return ok;
}

QList<Diagnostic> BindingEngine::validate() const
{
  QList<Diagnostic> diagnostics;
  // C1: one active set binding per set
  QMap<QString, int> activeSetBindings;
  for (const SetBinding &binding : mConfiguration.mSetBindings) {
    if (!mExternals.findSet(binding.mSet)) {
      diagnostics.append(diagnostic(Diagnostic::Error, "VW008", QString("%1 is not an external set of %2.").arg(binding.mSet, mExternals.mModel), binding.mId));
    }
    if (binding.mActive && ++activeSetBindings[binding.mSet] == 2) {
      diagnostics.append(diagnostic(Diagnostic::Error, "VW010", QString("Set %1 has more than one active binding.").arg(binding.mSet), binding.mId));
    }
  }
  // C2: one observer list per variable, with at least one enabled observer
  QSet<QString> variables;
  for (const VariableBinding &binding : mConfiguration.mVariableBindings) {
    if (variables.contains(binding.key())) {
      diagnostics.append(diagnostic(Diagnostic::Error, "VW010", QString("Variable %1 has more than one binding.").arg(binding.key()), binding.mId));
    }
    variables.insert(binding.key());
    if (std::none_of(binding.mObservers.cbegin(), binding.mObservers.cend(), [](const ObserverCandidate &c) {return c.mEnabled;})) {
      diagnostics.append(diagnostic(Diagnostic::Error, "VW007", QString("Variable %1 has no observer.").arg(binding.key()), binding.mId));
    }
    for (const ObserverCandidate &candidate : binding.mObservers) {
      if (!mIndex.findObserver(candidate.mObserver)) {
        diagnostics.append(diagnostic(Diagnostic::Error, "VW008", QString("Observer %1 of variable %2 is not loaded.").arg(candidate.mObserver, binding.key()), binding.mId));
      }
    }
  }
  // C3: compatible input types
  for (const InputBinding &binding : mConfiguration.mInputBindings) {
    if (const Observer *pObserver = mIndex.findObserver(binding.mObserver)) {
      observerTypesMatch(*pObserver, binding, diagnostics);
    } else {
      diagnostics.append(diagnostic(Diagnostic::Error, "VW008", QString("Observer %1 is not loaded.").arg(binding.mObserver), binding.mId));
    }
  }
  // C4: unique roles among the instances of one class in an instance binding
  for (const InstanceBinding &binding : mConfiguration.mInstanceBindings) {
    QSet<QString> classRoles;
    for (const InstanceTarget &target : binding.mTargets) {
      QString className = classOf(target.mInstance);
      if (className.isEmpty()) {
        diagnostics.append(diagnostic(Diagnostic::Error, "VW008", QString("%1, bound to %2, is neither a behaviour instance nor an architecture element.")
                                      .arg(target.mInstance, binding.mInstance), binding.mId));
        continue;
      }
      QString key = className + "|" + target.mRole;
      if (classRoles.contains(key)) {
        diagnostics.append(diagnostic(Diagnostic::Warning, "VW004", QString("%1 has several instances of %2 with the same role \"%3\".")
                                      .arg(binding.mInstance, className, target.mRole), binding.mId));
      }
      classRoles.insert(key);
    }
  }
  return diagnostics;
}

QStringList BindingEngine::setElements(const SetBinding &binding, QList<Diagnostic> &diagnostics) const
{
  QStringList elements;
  for (const SetTarget &target : binding.mTargets) {
    QStringList found;
    if (target.mKind == SetTarget::Instance) {
      if (!classOf(target.mName).isEmpty()) {
        found.append(target.mName);
      }
    } else if (mArchitecture.findType(target.mName)) {
      found = mArchitecture.elementsOfType(target.mName);
    } else {
      for (const ModelicaInstance &instance : mIndex.mInstances) {
        if (mIndex.isA(instance.mClassName, target.mName)) {
          found.append(instance.mPath);
        }
      }
    }
    if (found.isEmpty()) {
      diagnostics.append(diagnostic(Diagnostic::Error, "VW008", QString("%1 %2 of set %3 has no element.")
                                    .arg(target.mKind == SetTarget::Instance ? "Instance" : "Class collection", target.mName, binding.mSet), binding.mId));
    }
    for (const QString &element : std::as_const(found)) {
      if (!elements.contains(element)) {
        elements.append(element);
      }
    }
  }
  return elements;
}

static QString parameterName(const QString &element, const QString &attribute)
{
  QString name = element + "_" + attribute;
  return name.replace('.', '_');
}

bool BindingEngine::resolveVariable(const QString &element, const QString &className, const QString &variable,
                                    ResolvedExpression &expression, Resolution &resolution) const
{
  const QString what = describe(element, variable);
  const VariableBinding *pVariableBinding = mConfiguration.findVariableBinding(className, variable);
  if (!pVariableBinding) {
    resolution.mDiagnostics.append(diagnostic(Diagnostic::Error, "VW007", QString("External variable %1 has no variable binding.")
                                              .arg(className.isEmpty() ? variable : className + "." + variable)));
    return false;
  }
  // the instance binding of p; p is always bound to itself (D2.1.1 3.5 step 3)
  const InstanceBinding *pInstanceBinding = mConfiguration.findInstanceBinding(element);
  QList<InstanceTarget> targets = pInstanceBinding ? pInstanceBinding->mTargets : QList<InstanceTarget>();
  if (!element.isEmpty() && std::none_of(targets.cbegin(), targets.cend(), [&element](const InstanceTarget &t) {return t.mInstance == element;})) {
    InstanceTarget self;
    self.mInstance = element;
    targets.append(self);
  }
  QStringList targetClasses;
  for (const InstanceTarget &target : std::as_const(targets)) {
    targetClasses.append(classOf(target.mInstance));
  }
  const QString instanceBindingId = pInstanceBinding ? pInstanceBinding->mId : QString();

  // 1. the observer of lowest rank whose signature is covered by the instance binding
  const Observer *pObserver = nullptr;
  const InputBinding *pInputBinding = nullptr;
  int rank = 0;
  for (const ObserverCandidate &candidate : pVariableBinding->mObservers) {
    if (!candidate.mEnabled) {
      continue;
    }
    const Observer *pCandidate = mIndex.findObserver(candidate.mObserver);
    const InputBinding *pCandidateInputs = mConfiguration.findInputBinding(candidate.mObserver);
    if (!pCandidate || !pCandidateInputs) {
      if (pCandidate) {
        resolution.mDiagnostics.append(diagnostic(Diagnostic::Error, "VW007", QString("Observer %1 has no input binding.").arg(candidate.mObserver), pVariableBinding->mId));
      }
      ++rank;
      continue;
    }
    bool covered = true;
    for (const InputMapping &mapping : pCandidateInputs->mInputs) {
      if (std::none_of(targetClasses.cbegin(), targetClasses.cend(), [&](const QString &c) {return isA(c, mapping.mClass);})) {
        covered = false;
        break;
      }
    }
    if (covered) {
      pObserver = pCandidate;
      pInputBinding = pCandidateInputs;
      break;
    }
    ++rank;
  }
  if (!pObserver) {
    resolution.mDiagnostics.append(diagnostic(Diagnostic::Error, "VW001", QString("No observer of %1 can be computed from the instances bound to %2.")
                                              .arg(pVariableBinding->key(), element.isEmpty() ? mExternals.mModel : element),
                                              instanceBindingId.isEmpty() ? pVariableBinding->mId : instanceBindingId));
    return false;
  }
  if (rank > 0) {
    resolution.mDiagnostics.append(diagnostic(Diagnostic::Warning, "VW006", QString("%1 uses %2, candidate %3 of %4.")
                                              .arg(what, pObserver->mName).arg(rank + 1).arg(pVariableBinding->key()), pVariableBinding->mId));
  }

  // 2.-4. replace each input class by the unique, or role selected, instance of the binding
  expression.mVariable = variable;
  expression.mObserver = pObserver->mName;
  expression.mObserverRank = rank;
  bool ok = true;
  for (const ModelicaVariable &input : pObserver->mInputs) {
    const InputMapping *pMapping = pInputBinding->findInput(input.mName);
    if (!pMapping) {
      continue;
    }
    QList<int> candidates;
    for (int i = 0; i < targets.size(); ++i) {
      if (isA(targetClasses.at(i), pMapping->mClass)) {
        candidates.append(i);
      }
    }
    int targetIndex = -1;
    if (candidates.size() == 1) {
      targetIndex = candidates.first();
      const InstanceTarget *pTarget = &targets.at(targetIndex);
      if (!pTarget->mRole.isEmpty() && !pVariableBinding->mRole.isEmpty() && pTarget->mRole != pVariableBinding->mRole) {
        resolution.mDiagnostics.append(diagnostic(Diagnostic::Warning, "VW004", QString("%1 has role \"%2\" in the binding of %3, but %4 has role \"%5\".")
                                                  .arg(pTarget->mInstance, pTarget->mRole, element, pVariableBinding->key(), pVariableBinding->mRole),
                                                  instanceBindingId));
      }
    } else if (candidates.size() > 1) {
      QList<int> withRole;
      for (int candidate : std::as_const(candidates)) {
        if (!pVariableBinding->mRole.isEmpty() && targets.at(candidate).mRole == pVariableBinding->mRole) {
          withRole.append(candidate);
        }
      }
      if (withRole.size() == 1) {
        targetIndex = withRole.first();
      } else {
        resolution.mDiagnostics.append(diagnostic(Diagnostic::Error, "VW002", QString("%1: %2 instances of %3 are bound to %4 and no role \"%5\" selects one of them.")
                                                  .arg(what).arg(candidates.size()).arg(pMapping->mClass, element, pVariableBinding->mRole),
                                                  instanceBindingId));
        ok = false;
        continue;
      }
    } else {
      resolution.mDiagnostics.append(diagnostic(Diagnostic::Error, "VW005", QString("%1: no instance of %2 is bound to %3 for input %4 of %5.")
                                                .arg(what, pMapping->mClass, element.isEmpty() ? mExternals.mModel : element, input.mName, pObserver->mName),
                                                instanceBindingId));
      ok = false;
      continue;
    }

    const InstanceTarget *pTarget = &targets.at(targetIndex);
    ResolvedArgument argument;
    argument.mInput = input.mName;
    if (const ArchitectureElement *pElement = mArchitecture.findElement(pTarget->mInstance)) {
      const ArchitectureAttribute *pAttribute = mArchitecture.findAttribute(pElement->mType, pMapping->mVariable);
      if (!pAttribute) {
        resolution.mDiagnostics.append(diagnostic(Diagnostic::Error, "VW008", QString("Architecture type %1 has no attribute %2.").arg(pElement->mType, pMapping->mVariable), pInputBinding->mId));
        ok = false;
        continue;
      }
      argument.mExpression = parameterName(pElement->mName, pMapping->mVariable);
      bool known = std::any_of(resolution.mParameters.cbegin(), resolution.mParameters.cend(),
                               [&argument](const ArchitectureParameter &p) {return p.mName == argument.mExpression;});
      if (!known) {
        ArchitectureParameter parameter;
        parameter.mName = argument.mExpression;
        parameter.mType = pAttribute->mType;
        parameter.mDims = pAttribute->mDims;
        parameter.mValue = pElement->mValues.value(pMapping->mVariable);
        parameter.mElement = pElement->mName;
        parameter.mAttribute = pMapping->mVariable;
        if (parameter.mValue.isUndefined() || parameter.mValue.isNull()) {
          resolution.mDiagnostics.append(diagnostic(Diagnostic::Warning, "VW009", QString("%1.%2 has no value in architecture %3; set parameter %4 in the verification model.")
                                                    .arg(pElement->mName, pMapping->mVariable, mArchitecture.mName, parameter.mName)));
        }
        resolution.mParameters.append(parameter);
      }
    } else {
      const ModelicaClass *pClass = mIndex.findClass(targetClasses.at(targetIndex));
      if (!pClass || !pClass->findVariable(pMapping->mVariable)) {
        resolution.mDiagnostics.append(diagnostic(Diagnostic::Error, "VW008", QString("%1 has no variable %2.").arg(pTarget->mInstance, pMapping->mVariable), pInputBinding->mId));
        ok = false;
        continue;
      }
      argument.mExpression = QString("%1.%2.%3").arg(behaviourInstanceName, pTarget->mInstance, pMapping->mVariable);
    }
    expression.mArguments.append(argument);
  }
  return ok;
}

Resolution BindingEngine::resolve() const
{
  Resolution resolution;
  resolution.mDiagnostics = validate();
  for (const CrmlVariable &set : mExternals.mSets) {
    const SetBinding *pSetBinding = mConfiguration.activeSetBinding(set.mName);
    if (!pSetBinding) {
      resolution.mDiagnostics.append(diagnostic(Diagnostic::Error, "VW007", QString("External set %1 has no active set binding.").arg(set.mName)));
      continue;
    }
    ResolvedSet resolvedSet;
    resolvedSet.mName = set.mName;
    resolvedSet.mElementClass = set.mType;
    resolvedSet.mSizeParameter = set.mSizeParameter.isEmpty() ? set.mName + "_n" : set.mSizeParameter;
    resolvedSet.mElements = setElements(*pSetBinding, resolution.mDiagnostics);
    resolution.mSets.append(resolvedSet);
    const CrmlClass *pClass = mExternals.findClass(set.mType);
    if (!pClass) {
      continue; // a set of Booleans has no external variables of its own
    }
    for (int i = 0; i < resolvedSet.mElements.size(); ++i) {
      for (const CrmlVariable &variable : pClass->mExternals) {
        ResolvedExpression expression;
        expression.mSet = set.mName;
        expression.mIndex = i + 1;
        expression.mElement = resolvedSet.mElements.at(i);
        expression.mLeft = QString("%1.%2[%3].%4").arg(requirementInstanceName, set.mName).arg(i + 1).arg(variable.mName);
        if (resolveVariable(expression.mElement, pClass->mName, variable.mName, expression, resolution)) {
          resolution.mExpressions.append(expression);
        }
      }
    }
  }
  for (const CrmlVariable &variable : mExternals.mExternals) {
    ResolvedExpression expression;
    expression.mLeft = QString("%1.%2").arg(requirementInstanceName, variable.mName);
    if (resolveVariable(QString(), QString(), variable.mName, expression, resolution)) {
      resolution.mExpressions.append(expression);
    }
  }
  return resolution;
}

template <typename T>
static void setStatus(QList<T> &bindings, const QList<Diagnostic> &diagnostics)
{
  for (T &binding : bindings) {
    binding.mStatus = Status::Valid;
    for (const Diagnostic &d : diagnostics) {
      if (d.mSeverity == Diagnostic::Error && d.mBindingId == binding.mId) {
        binding.mStatus = d.mCode == QLatin1String("VW002") ? Status::Ambiguous : Status::Missing;
        break;
      }
    }
  }
}

void BindingEngine::updateStatus(VerificationConfiguration &configuration, const Resolution &resolution)
{
  setStatus(configuration.mSetBindings, resolution.mDiagnostics);
  setStatus(configuration.mVariableBindings, resolution.mDiagnostics);
  setStatus(configuration.mInputBindings, resolution.mDiagnostics);
  setStatus(configuration.mInstanceBindings, resolution.mDiagnostics);
}

/* ------------------------------------------------------------------ discovery */

BindingDiscovery::BindingDiscovery(const CrmlExternals &externals, const ArchitectureModel &architecture, const ModelIndex &index)
  : mExternals(externals), mArchitecture(architecture), mIndex(index)
{
}

static QStringList tokens(const QString &text)
{
  static const QSet<QString> stopWords = {"a", "an", "the", "of", "at", "in", "on", "to", "for", "is", "and", "or", "by", "with", "from", "obs", "model"};
  QString spaced = text;
  spaced.replace(QRegularExpression("([a-z0-9])([A-Z])"), "\\1 \\2");
  QStringList result;
  for (const QString &token : spaced.toLower().split(QRegularExpression("[^a-z0-9]+"), Qt::SkipEmptyParts)) {
    if (!stopWords.contains(token)) {
      result.append(token);
    }
  }
  return result;
}

static bool tokensMatch(const QString &a, const QString &b)
{
  if (a == b) {
    return true;
  }
  // inflections: cavitate ~ cavitating
  int common = 0;
  while (common < a.size() && common < b.size() && a.at(common) == b.at(common)) {
    ++common;
  }
  return common >= 5;
}

double BindingDiscovery::similarity(const QString &a, const QString &b)
{
  QStringList ta = tokens(a);
  QStringList tb = tokens(b);
  if (ta.isEmpty() || tb.isEmpty()) {
    return 0.0;
  }
  int matches = 0;
  QList<bool> used(tb.size(), false);
  for (const QString &x : std::as_const(ta)) {
    for (int j = 0; j < tb.size(); ++j) {
      if (!used.at(j) && tokensMatch(x, tb.at(j))) {
        used[j] = true;
        ++matches;
        break;
      }
    }
  }
  return double(matches) / double(ta.size() + tb.size() - matches);
}

static QString shortName(const QString &name)
{
  return name.section('.', -1);
}

/*! Pump_R, Pump_A and Pump_A1 have the same stem Pump. */
static QString stem(const QString &name)
{
  QString result = shortName(name);
  result.remove(QRegularExpression("_[A-Z][0-9]*$"));
  return result;
}

void BindingDiscovery::discover(VerificationConfiguration &configuration) const
{
  discoverSetBindings(configuration);
  discoverVariableBindings(configuration);
  discoverInputBindings(configuration);
  discoverInstanceBindings(configuration);
  configuration.assignIds();
}

void BindingDiscovery::discoverSetBindings(VerificationConfiguration &configuration) const
{
  for (const CrmlVariable &set : mExternals.mSets) {
    if (configuration.activeSetBinding(set.mName)) {
      continue;
    }
    SetBinding binding;
    binding.mSet = set.mName;
    QString best;
    double bestScore = 0;
    for (const ArchitectureType &type : mArchitecture.mTypes) {
      double score = stem(type.mName).compare(stem(set.mType), Qt::CaseInsensitive) == 0 ? 1.0 : similarity(stem(type.mName), stem(set.mType));
      if (score > bestScore && !mArchitecture.elementsOfType(type.mName).isEmpty()) {
        best = type.mName;
        bestScore = score;
      }
    }
    if (best.isEmpty()) {
      // no architecture: bind the set straight to the behaviour instances of a class
      QSet<QString> classes;
      for (const ModelicaInstance &instance : mIndex.mInstances) {
        classes.insert(instance.mClassName);
      }
      for (const QString &className : std::as_const(classes)) {
        double score = similarity(shortName(className), stem(set.mType));
        if (score > bestScore) {
          best = className;
          bestScore = score;
        }
      }
    }
    if (!best.isEmpty() && bestScore >= 0.5) {
      SetTarget target;
      target.mKind = SetTarget::Collection;
      target.mName = best;
      binding.mTargets.append(target);
      binding.mConfidence = 0.9*bestScore;
      binding.mStatus = Status::Valid;
    } else {
      binding.mConfidence = 0;
      binding.mStatus = Status::Missing;
    }
    configuration.mSetBindings.append(binding);
  }
}

void BindingDiscovery::discoverVariableBindings(VerificationConfiguration &configuration) const
{
  QList<QPair<QString, QString>> variables;
  for (const CrmlVariable &set : mExternals.mSets) {
    if (const CrmlClass *pClass = mExternals.findClass(set.mType)) {
      for (const CrmlVariable &variable : pClass->mExternals) {
        if (!variables.contains(qMakePair(pClass->mName, variable.mName))) {
          variables.append(qMakePair(pClass->mName, variable.mName));
        }
      }
    }
  }
  for (const CrmlVariable &variable : mExternals.mExternals) {
    variables.append(qMakePair(QString(), variable.mName));
  }

  for (const auto &variable : std::as_const(variables)) {
    if (configuration.findVariableBinding(variable.first, variable.second)) {
      continue;
    }
    VariableBinding binding;
    binding.mClass = variable.first;
    binding.mVariable = variable.second;
    QList<const Observer*> annotated;
    QList<QPair<double, const Observer*>> similar;
    for (const Observer &observer : mIndex.mObservers) {
      if (observer.mObserves == variable.second) {
        annotated.append(&observer);
      } else if (observer.mObserves.isEmpty()) {
        double score = similarity(variable.second, shortName(observer.mName));
        if (score >= 0.5) {
          similar.append(qMakePair(score, &observer));
        }
      }
    }
    if (!annotated.isEmpty()) {
      std::stable_sort(annotated.begin(), annotated.end(), [](const Observer *a, const Observer *b) {
        return (a->mRank > 0 ? a->mRank : INT_MAX) < (b->mRank > 0 ? b->mRank : INT_MAX);
      });
      for (const Observer *pObserver : std::as_const(annotated)) {
        ObserverCandidate candidate;
        candidate.mObserver = pObserver->mName;
        binding.mObservers.append(candidate);
      }
      binding.mConfidence = 0.95;
    } else if (!similar.isEmpty()) {
      std::stable_sort(similar.begin(), similar.end(), [](const auto &a, const auto &b) {return a.first > b.first;});
      for (const auto &item : std::as_const(similar)) {
        ObserverCandidate candidate;
        candidate.mObserver = item.second->mName;
        binding.mObservers.append(candidate);
      }
      binding.mConfidence = similar.first().first;
    } else {
      binding.mConfidence = 0;
    }
    binding.mStatus = binding.mObservers.isEmpty() ? Status::Missing : Status::Valid;
    configuration.mVariableBindings.append(binding);
  }
}

void BindingDiscovery::discoverInputBindings(VerificationConfiguration &configuration) const
{
  QStringList observers;
  for (const VariableBinding &binding : std::as_const(configuration.mVariableBindings)) {
    for (const ObserverCandidate &candidate : binding.mObservers) {
      if (!observers.contains(candidate.mObserver)) {
        observers.append(candidate.mObserver);
      }
    }
  }
  QStringList behaviourClasses;
  for (const ModelicaInstance &instance : mIndex.mInstances) {
    if (!behaviourClasses.contains(instance.mClassName)) {
      behaviourClasses.append(instance.mClassName);
    }
  }

  for (const QString &observerName : std::as_const(observers)) {
    const Observer *pObserver = mIndex.findObserver(observerName);
    if (!pObserver || configuration.findInputBinding(observerName)) {
      continue;
    }
    InputBinding binding;
    binding.mObserver = observerName;
    binding.mConfidence = 1.0;
    binding.mStatus = Status::Valid;
    for (const ModelicaVariable &input : pObserver->mInputs) {
      struct Candidate {double mScore; InputMapping mMapping;};
      QList<Candidate> candidates;
      auto consider = [&](InputMapping::Source source, const QString &className, const QString &name, const QString &type,
                          const QStringList &dims, const QString &comment) {
        if (baseType(type) != baseType(input.mType) || dims.size() != input.mDims.size()) {
          return;
        }
        double score = name == input.mName ? 1.0 : 0.8*similarity(name, input.mName);
        if (!comment.isEmpty() && !input.mComment.isEmpty()) {
          score = std::max(score, 0.9*similarity(comment, input.mComment));
        }
        if (score > 0) {
          Candidate candidate;
          candidate.mScore = score;
          candidate.mMapping.mInput = input.mName;
          candidate.mMapping.mSource = source;
          candidate.mMapping.mClass = className;
          candidate.mMapping.mVariable = name;
          candidates.append(candidate);
        }
      };
      for (const QString &className : std::as_const(behaviourClasses)) {
        if (const ModelicaClass *pClass = mIndex.findClass(className)) {
          for (const ModelicaVariable &variable : pClass->mVariables) {
            consider(InputMapping::Behaviour, className, variable.mName, variable.mType, variable.mDims, variable.mComment);
          }
        }
      }
      for (const ArchitectureType &type : mArchitecture.mTypes) {
        for (const ArchitectureAttribute &attribute : type.mAttributes) {
          consider(InputMapping::Architecture, type.mName, attribute.mName, attribute.mType, attribute.mDims, QString());
        }
      }
      std::stable_sort(candidates.begin(), candidates.end(), [](const Candidate &a, const Candidate &b) {return a.mScore > b.mScore;});
      // an input with a default value is a tuning parameter: bind it only on an exact name match
      double threshold = input.mHasDefault ? 1.0 : 0.5;
      if (candidates.isEmpty() || candidates.first().mScore < threshold) {
        if (!input.mHasDefault) {
          binding.mStatus = Status::Missing;
          binding.mConfidence = 0;
        }
        continue;
      }
      if (candidates.size() > 1 && candidates.at(1).mScore == candidates.first().mScore && binding.mStatus == Status::Valid) {
        binding.mStatus = Status::Ambiguous;
      }
      binding.mInputs.append(candidates.first().mMapping);
      binding.mConfidence = std::min(binding.mConfidence, candidates.first().mScore);
    }
    configuration.mInputBindings.append(binding);
  }
}

void BindingDiscovery::discoverInstanceBindings(VerificationConfiguration &configuration) const
{
  QStringList elements;
  for (const SetBinding &setBinding : std::as_const(configuration.mSetBindings)) {
    if (!setBinding.mActive) {
      continue;
    }
    for (const SetTarget &target : setBinding.mTargets) {
      if (target.mKind == SetTarget::Instance) {
        elements.append(target.mName);
      } else if (mArchitecture.findType(target.mName)) {
        elements.append(mArchitecture.elementsOfType(target.mName));
      }
    }
  }
  for (const QString &element : std::as_const(elements)) {
    const ArchitectureElement *pElement = mArchitecture.findElement(element);
    if (!pElement || configuration.findInstanceBinding(element)) {
      continue;
    }
    InstanceBinding binding;
    binding.mInstance = element;
    for (const ArchitectureAllocation &allocation : mArchitecture.mAllocations) {
      if (allocation.mFrom == element && mIndex.findInstance(allocation.mTo)) {
        InstanceTarget target;
        target.mInstance = allocation.mTo;
        target.mRole = allocation.mRole;
        binding.mTargets.append(target);
      }
    }
    if (!binding.mTargets.isEmpty()) {
      binding.mConfidence = 0.95;
    } else {
      // the element id in the description of the behaviour instance, e.g. "Model for pump PO1"
      QString id = pElement->mValues.value("id").toString();
      QRegularExpression idPattern(id.isEmpty() ? QString() : "\\b" + QRegularExpression::escape(id) + "\\b");
      QRegularExpression numberPattern("(\\d+)$");
      QString number = numberPattern.match(element).captured(1);
      double score = 0;
      QStringList selected;
      for (const ModelicaInstance &instance : mIndex.mInstances) {
        if (std::any_of(selected.cbegin(), selected.cend(), [&instance](const QString &s) {return instance.mPath.startsWith(s + ".");})) {
          continue;
        }
        double instanceScore = 0;
        if (!id.isEmpty() && idPattern.match(instance.mComment).hasMatch()) {
          instanceScore = 0.9;
        } else if (!number.isEmpty() && !instance.mPath.contains('.') && numberPattern.match(instance.mPath).captured(1) == number) {
          instanceScore = 0.6;
        }
        if (instanceScore > score) {
          score = instanceScore;
          selected.clear();
        }
        if (instanceScore > 0 && instanceScore == score) {
          selected.append(instance.mPath);
        }
      }
      for (const QString &path : std::as_const(selected)) {
        InstanceTarget target;
        target.mInstance = path;
        binding.mTargets.append(target);
      }
      binding.mConfidence = score;
    }
    binding.mStatus = binding.mTargets.isEmpty() ? Status::Missing : Status::Valid;
    configuration.mInstanceBindings.append(binding);
  }
}

} // namespace CRMLBindings
