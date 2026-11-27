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

#ifndef CRMLBINDINGMODEL_H
#define CRMLBINDINGMODEL_H

/*
 * The data the CRML bindings work on (MODRIO D2.1.1 3.4):
 *  - CrmlExternals: what the requirement model needs, read from the CRML compiler's --externals-json file;
 *  - ArchitectureModel: the optional architecture model, read from the neutral architecture.json format;
 *  - ModelIndex: the behaviour model instances and the observers, read from omc's getModelInstance JSON;
 *  - VerificationConfiguration: the four binding kinds, saved as <Name>.crmlbind.json.
 * None of these classes depends on the GUI, so they can be tested without OMEdit's main window.
 */

#include <QJsonArray>
#include <QJsonObject>
#include <QJsonValue>
#include <QList>
#include <QMap>
#include <QString>
#include <QStringList>

namespace CRMLBindings {

/*! The status of one binding, shown colour-coded in the editor. */
enum class Status { Valid, Ambiguous, Missing };
QString statusToString(Status status);
Status statusFromString(const QString &status);

/*! A message of the validation or of the resolution of the bindings. */
struct Diagnostic {
  enum Severity { Error, Warning, Info };
  Severity mSeverity = Error;
  QString mCode;      // VWnnn, see BindingEngine.h
  QString mMessage;
  QString mBindingId; // the binding the message is about, if any
  QString toString() const;
};

/* ---------------------------------------------------------------- CRML side */

struct CrmlVariable {
  QString mName;
  QString mType;
  int mLine = 0;
  QString mSizeParameter; // external sets only: the Modelica parameter holding the number of elements
};

struct CrmlClass {
  QString mName;
  int mLine = 0;
  QList<CrmlVariable> mExternals;
  QList<CrmlVariable> mRequirements;
};

/*! The externals of a requirement model, schema crml-externals/0.1. */
struct CrmlExternals {
  QString mModel;
  QString mSource;
  QList<CrmlClass> mClasses;
  QList<CrmlVariable> mExternals;    // top level external variables
  QList<CrmlVariable> mSets;         // external sets
  QList<CrmlVariable> mRequirements; // top level requirements

  bool fromJson(const QJsonObject &json, QString *pError = nullptr);
  const CrmlClass *findClass(const QString &name) const;
  const CrmlVariable *findSet(const QString &name) const;
};

/* -------------------------------------------------------- architecture side */

struct ArchitectureAttribute {
  QString mName;
  QString mType;
  QStringList mDims;
  bool mExternal = false;
};

struct ArchitectureType {
  QString mName;
  QStringList mSpecializes;
  QList<ArchitectureAttribute> mAttributes;
};

/*! An element of the architecture; nested parts are flattened to dotted names (a.b). */
struct ArchitectureElement {
  QString mName;
  QString mType;
  QJsonObject mValues;
};

/*! An allocation of an architecture element to a behaviour element, e.g. SysML allocate. */
struct ArchitectureAllocation {
  QString mFrom;
  QString mTo;
  QString mRole;
};

/*! The neutral architecture model, schema om-crml-architecture/0.1. */
struct ArchitectureModel {
  QString mName;
  QString mSourceKind;
  QList<ArchitectureType> mTypes;
  QList<ArchitectureElement> mElements;
  QList<ArchitectureAllocation> mAllocations;

  bool fromJson(const QJsonObject &json, QString *pError = nullptr);
  bool isEmpty() const {return mName.isEmpty() && mElements.isEmpty();}
  const ArchitectureType *findType(const QString &name) const;
  const ArchitectureElement *findElement(const QString &name) const;
  /*! True when type is base or specializes base, directly or not. */
  bool isA(const QString &type, const QString &base) const;
  /*! The attribute of a type, also looked up in the types it specializes. */
  const ArchitectureAttribute *findAttribute(const QString &type, const QString &attribute) const;
  /*! The class collection: all elements whose type is type or specializes it, in declaration order. */
  QStringList elementsOfType(const QString &type) const;
};

/* ------------------------------------------------------------ Modelica side */

struct ModelicaVariable {
  QString mName;
  QString mType;
  QStringList mDims;
  QString mComment;
  QString mVariability;
  QString mDirection;
  bool mHasDefault = false;
};

struct ModelicaClass {
  QString mName;
  QString mComment;
  QStringList mBaseClasses; // all base classes, transitively
  QList<ModelicaVariable> mVariables;
  const ModelicaVariable *findVariable(const QString &name) const;
};

/*! A component of the behaviour model, with its dotted path from the behaviour model. */
struct ModelicaInstance {
  QString mPath;
  QString mClassName;
  QString mComment;
};

/*! An observation operator: a function with inputs and one output. */
struct Observer {
  QString mName;
  QString mComment;
  QList<ModelicaVariable> mInputs;
  ModelicaVariable mOutput;
  QString mObserves; // from annotation(__OpenModelica_CRML(observes = "..."))
  int mRank = 0;     // from annotation(__OpenModelica_CRML(rank = n)), 0 if not given
  const ModelicaVariable *findInput(const QString &name) const;
};

/*! What the bindings need to know about the Modelica models, built from getModelInstance JSON. */
struct ModelIndex {
  QString mBehaviourModel;
  QString mBehaviourComment;
  double mStopTime = -1;
  QList<ModelicaInstance> mInstances;
  QMap<QString, ModelicaClass> mClasses;
  QList<Observer> mObservers;

  /*! Reads the behaviour model: every component of a class type becomes an instance, recursively. */
  void setBehaviourModel(const QJsonObject &modelInstance);
  /*! Reads one observer function; returns false if the JSON is not a function. */
  bool addObserver(const QJsonObject &functionInstance);
  const ModelicaInstance *findInstance(const QString &path) const;
  const ModelicaClass *findClass(const QString &name) const;
  const Observer *findObserver(const QString &name) const;
  bool isA(const QString &className, const QString &base) const;
private:
  void addInstances(const QJsonArray &elements, const QString &prefix);
  QString addClass(const QJsonObject &type);
};

/* ------------------------------------------------------------ configuration */

/*! A member of a set binding: a class collection or one instance. */
struct SetTarget {
  enum Kind { Collection, Instance };
  Kind mKind = Collection;
  QString mName;
};

struct SetBinding {
  QString mId;
  QString mSet; // external set of the requirement model
  QList<SetTarget> mTargets;
  bool mActive = true;
  Status mStatus = Status::Valid;
  double mConfidence = 1.0;
};

struct ObserverCandidate {
  QString mObserver;
  bool mEnabled = true;
};

/*! Variable binding R.y -> [H1, ..., Hp], with an optional role. R is empty for a top level external. */
struct VariableBinding {
  QString mId;
  QString mClass;
  QString mVariable;
  QList<ObserverCandidate> mObservers;
  QString mRole;
  Status mStatus = Status::Valid;
  double mConfidence = 1.0;
  QString key() const {return mClass.isEmpty() ? mVariable : mClass + "." + mVariable;}
};

/*! One input u = E.x of an input binding; E is a Modelica class or an architecture type. */
struct InputMapping {
  enum Source { Behaviour, Architecture };
  QString mInput;
  Source mSource = Behaviour;
  QString mClass;
  QString mVariable;
};

/*! Input binding H(u1, ..., un) -> (u1 = E1.x, ..., un = En.x). */
struct InputBinding {
  QString mId;
  QString mObserver;
  QList<InputMapping> mInputs;
  Status mStatus = Status::Valid;
  double mConfidence = 1.0;
  const InputMapping *findInput(const QString &input) const;
};

struct InstanceTarget {
  QString mInstance; // behaviour instance path, or architecture element name
  QString mRole;
};

/*! Instance binding a -> {e1, ..., en}. a is empty for the requirement model itself (top level externals). */
struct InstanceBinding {
  QString mId;
  QString mInstance;
  QList<InstanceTarget> mTargets;
  Status mStatus = Status::Valid;
  double mConfidence = 1.0;
};

/*! The verification configuration, schema om-crml-bindings/0.1. */
struct VerificationConfiguration {
  QString mName;
  QString mDescription;
  QString mRequirementFile;   // the CRML file
  QString mArchitectureFile;  // architecture.json, optional
  QString mBehaviourModel;    // Modelica class name
  QStringList mObserverLibraries; // Modelica packages that hold the observers
  QList<SetBinding> mSetBindings;
  QList<VariableBinding> mVariableBindings;
  QList<InputBinding> mInputBindings;
  QList<InstanceBinding> mInstanceBindings;

  QJsonObject toJson() const;
  bool fromJson(const QJsonObject &json, QString *pError = nullptr);
  bool save(const QString &fileName, QString *pError = nullptr) const;
  bool load(const QString &fileName, QString *pError = nullptr);

  const SetBinding *activeSetBinding(const QString &set) const;
  const VariableBinding *findVariableBinding(const QString &className, const QString &variable) const;
  const InputBinding *findInputBinding(const QString &observer) const;
  const InstanceBinding *findInstanceBinding(const QString &instance) const;
  /*! Gives every binding without an id a unique one (s1, v1, i1, b1, ...). */
  void assignIds();
};

/*! Reads a JSON object from a file. */
bool readJsonFile(const QString &fileName, QJsonObject &json, QString *pError = nullptr);

} // namespace CRMLBindings

#endif // CRMLBINDINGMODEL_H
