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

#ifndef CRMLBINDINGENGINE_H
#define CRMLBINDINGENGINE_H

#include "BindingModel.h"

/*
 * Diagnostic codes:
 *  VW001 missing observer: no candidate observer has a signature that the instance binding covers
 *  VW002 ambiguous mapping: several instances of an input class and no role to choose one
 *  VW003 type mismatch between an observer input and the variable bound to it
 *  VW004 role conflict
 *  VW005 unresolved instance: no instance of an input class in the instance binding
 *  VW006 fallback observer used (not the first candidate)
 *  VW007 missing binding
 *  VW008 unknown model element (set, class, observer, instance or variable)
 *  VW009 architecture attribute without a value
 *  VW010 duplicate binding
 */

namespace CRMLBindings {

/*! An argument of an observer call. */
struct ResolvedArgument {
  QString mInput;
  QString mExpression; // the Modelica expression in the verification model
};

/*! A parameter of the verification model that holds an architecture attribute. */
struct ArchitectureParameter {
  QString mName;
  QString mType;
  QStringList mDims;
  QJsonValue mValue;
  QString mElement;
  QString mAttribute;
};

/*! p.y = H(e1.x, ..., en.x) for one element p of an external set, or for the requirement model itself. */
struct ResolvedExpression {
  QString mSet;     // empty for a top level external
  int mIndex = 0;   // 1-based index of p in the set
  QString mElement; // p
  QString mVariable;
  QString mObserver;
  int mObserverRank = 0;
  QList<ResolvedArgument> mArguments;
  QString mLeft;    // the left hand side in the verification model
  QString call() const;
};

struct ResolvedSet {
  QString mName;
  QString mElementClass;
  QString mSizeParameter;
  QStringList mElements;
};

struct Resolution {
  QList<ResolvedSet> mSets;
  QList<ResolvedExpression> mExpressions;
  QList<ArchitectureParameter> mParameters;
  QList<Diagnostic> mDiagnostics;
  bool hasErrors() const;
};

class BindingEngine
{
public:
  static constexpr const char *behaviourInstanceName = "behav";
  static constexpr const char *requirementInstanceName = "req";

  BindingEngine(const VerificationConfiguration &configuration, const CrmlExternals &externals,
                const ArchitectureModel &architecture, const ModelIndex &index);
  /*! Checks the configuration without resolving it: constraints C1 to C4 of the metamodel. */
  QList<Diagnostic> validate() const;
  /*! Validates, then forms p.y = H(e1.x, ..., en.x) for every element of every set (MODRIO D2.1.1 3.4.5). */
  Resolution resolve() const;
  /*! Sets the status of every binding of the configuration from the diagnostics of a resolution. */
  static void updateStatus(VerificationConfiguration &configuration, const Resolution &resolution);
  /*! The class of an instance: a Modelica class for a behaviour instance, a type for an architecture element. */
  QString classOf(const QString &instance) const;
  bool isA(const QString &className, const QString &base) const;
private:
  const VerificationConfiguration &mConfiguration;
  const CrmlExternals &mExternals;
  const ArchitectureModel &mArchitecture;
  const ModelIndex &mIndex;

  QStringList setElements(const SetBinding &binding, QList<Diagnostic> &diagnostics) const;
  bool resolveVariable(const QString &element, const QString &className, const QString &variable,
                       ResolvedExpression &expression, Resolution &resolution) const;
  bool observerTypesMatch(const Observer &observer, const InputBinding &inputBinding, QList<Diagnostic> &diagnostics) const;
  QString variableType(const InputMapping &mapping, QStringList *pDims) const;
};

/*!
 * Proposes bindings from names, types, annotations and allocations (WP4).
 * Bindings already in the configuration are kept; only missing ones are added.
 */
class BindingDiscovery
{
public:
  BindingDiscovery(const CrmlExternals &externals, const ArchitectureModel &architecture, const ModelIndex &index);
  void discover(VerificationConfiguration &configuration) const;
  /*! A similarity between 0 and 1 of two identifiers or descriptions. */
  static double similarity(const QString &a, const QString &b);
private:
  const CrmlExternals &mExternals;
  const ArchitectureModel &mArchitecture;
  const ModelIndex &mIndex;

  void discoverSetBindings(VerificationConfiguration &configuration) const;
  void discoverVariableBindings(VerificationConfiguration &configuration) const;
  void discoverInputBindings(VerificationConfiguration &configuration) const;
  void discoverInstanceBindings(VerificationConfiguration &configuration) const;
};

} // namespace CRMLBindings

#endif // CRMLBINDINGENGINE_H
