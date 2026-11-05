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

#include "BindingModel.h"

#include <QFile>
#include <QJsonDocument>
#include <QSaveFile>

namespace CRMLBindings {

QString statusToString(Status status)
{
  switch (status) {
    case Status::Valid: return QStringLiteral("valid");
    case Status::Ambiguous: return QStringLiteral("ambiguous");
    case Status::Missing: return QStringLiteral("missing");
  }
  return QStringLiteral("missing");
}

Status statusFromString(const QString &status)
{
  if (status == QLatin1String("ambiguous")) {
    return Status::Ambiguous;
  } else if (status == QLatin1String("missing")) {
    return Status::Missing;
  }
  return Status::Valid;
}

QString Diagnostic::toString() const
{
  QString severity = mSeverity == Error ? QStringLiteral("Error") : (mSeverity == Warning ? QStringLiteral("Warning") : QStringLiteral("Info"));
  QString text = QString("%1 %2: %3").arg(severity, mCode, mMessage);
  if (!mBindingId.isEmpty()) {
    text += QString(" [%1]").arg(mBindingId);
  }
  return text;
}

bool readJsonFile(const QString &fileName, QJsonObject &json, QString *pError)
{
  QFile file(fileName);
  if (!file.open(QIODevice::ReadOnly)) {
    if (pError) *pError = QString("Cannot open %1: %2").arg(fileName, file.errorString());
    return false;
  }
  QJsonParseError parseError;
  QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &parseError);
  if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
    if (pError) *pError = QString("%1 is not a JSON object: %2").arg(fileName, parseError.errorString());
    return false;
  }
  json = document.object();
  return true;
}

static bool checkSchema(const QJsonObject &json, const QString &schema, QString *pError)
{
  QString found = json.value("schema").toString();
  if (!found.startsWith(schema.section('/', 0, 0) + "/")) {
    if (pError) *pError = QString("Expected schema %1, found \"%2\"").arg(schema, found);
    return false;
  }
  return true;
}

static QStringList toStringList(const QJsonValue &value)
{
  QStringList list;
  for (const QJsonValue &item : value.toArray()) {
    list.append(item.isString() ? item.toString() : QString::number(item.toDouble()));
  }
  return list;
}

/* ---------------------------------------------------------------- CRML side */

static QList<CrmlVariable> crmlVariables(const QJsonValue &value)
{
  QList<CrmlVariable> variables;
  for (const QJsonValue &item : value.toArray()) {
    QJsonObject object = item.toObject();
    CrmlVariable variable;
    variable.mName = object.value("name").toString();
    variable.mType = object.value("type").toString();
    variable.mLine = object.value("line").toInt();
    variable.mSizeParameter = object.value("sizeParameter").toString();
    variables.append(variable);
  }
  return variables;
}

bool CrmlExternals::fromJson(const QJsonObject &json, QString *pError)
{
  if (!checkSchema(json, "crml-externals/0.1", pError)) {
    return false;
  }
  mModel = json.value("model").toString();
  mSource = json.value("source").toString();
  mClasses.clear();
  for (const QJsonValue &item : json.value("classes").toArray()) {
    QJsonObject object = item.toObject();
    CrmlClass crmlClass;
    crmlClass.mName = object.value("name").toString();
    crmlClass.mLine = object.value("line").toInt();
    crmlClass.mExternals = crmlVariables(object.value("externals"));
    crmlClass.mRequirements = crmlVariables(object.value("requirements"));
    mClasses.append(crmlClass);
  }
  mExternals = crmlVariables(json.value("externals"));
  mSets = crmlVariables(json.value("sets"));
  mRequirements = crmlVariables(json.value("requirements"));
  return true;
}

const CrmlClass *CrmlExternals::findClass(const QString &name) const
{
  for (const CrmlClass &crmlClass : mClasses) {
    if (crmlClass.mName == name) {
      return &crmlClass;
    }
  }
  return nullptr;
}

const CrmlVariable *CrmlExternals::findSet(const QString &name) const
{
  for (const CrmlVariable &set : mSets) {
    if (set.mName == name) {
      return &set;
    }
  }
  return nullptr;
}

/* -------------------------------------------------------- architecture side */

static void addArchitectureElements(const QJsonArray &elements, const QString &prefix, QList<ArchitectureElement> &result)
{
  for (const QJsonValue &item : elements) {
    QJsonObject object = item.toObject();
    ArchitectureElement element;
    element.mName = prefix + object.value("name").toString();
    element.mType = object.value("type").toString();
    element.mValues = object.value("values").toObject();
    result.append(element);
    addArchitectureElements(object.value("parts").toArray(), element.mName + ".", result);
  }
}

bool ArchitectureModel::fromJson(const QJsonObject &json, QString *pError)
{
  if (!checkSchema(json, "om-crml-architecture/0.1", pError)) {
    return false;
  }
  mName = json.value("name").toString();
  mSourceKind = json.value("source").toObject().value("kind").toString();
  mTypes.clear();
  for (const QJsonValue &item : json.value("types").toArray()) {
    QJsonObject object = item.toObject();
    ArchitectureType type;
    type.mName = object.value("name").toString();
    type.mSpecializes = toStringList(object.value("specializes"));
    for (const QJsonValue &attributeValue : object.value("attributes").toArray()) {
      QJsonObject attributeObject = attributeValue.toObject();
      ArchitectureAttribute attribute;
      attribute.mName = attributeObject.value("name").toString();
      attribute.mType = attributeObject.value("type").toString();
      attribute.mDims = toStringList(attributeObject.value("dims"));
      attribute.mExternal = attributeObject.value("external").toBool();
      type.mAttributes.append(attribute);
    }
    mTypes.append(type);
  }
  mElements.clear();
  addArchitectureElements(json.value("elements").toArray(), QString(), mElements);
  mAllocations.clear();
  for (const QJsonValue &item : json.value("allocations").toArray()) {
    QJsonObject object = item.toObject();
    ArchitectureAllocation allocation;
    allocation.mFrom = object.value("from").toString();
    allocation.mTo = object.value("to").toString();
    allocation.mRole = object.value("role").toString();
    mAllocations.append(allocation);
  }
  return true;
}

const ArchitectureType *ArchitectureModel::findType(const QString &name) const
{
  for (const ArchitectureType &type : mTypes) {
    if (type.mName == name) {
      return &type;
    }
  }
  return nullptr;
}

const ArchitectureElement *ArchitectureModel::findElement(const QString &name) const
{
  for (const ArchitectureElement &element : mElements) {
    if (element.mName == name) {
      return &element;
    }
  }
  return nullptr;
}

bool ArchitectureModel::isA(const QString &type, const QString &base) const
{
  QStringList pending = {type};
  QStringList visited;
  while (!pending.isEmpty()) {
    QString current = pending.takeFirst();
    if (current == base) {
      return true;
    }
    if (visited.contains(current)) {
      continue;
    }
    visited.append(current);
    if (const ArchitectureType *pType = findType(current)) {
      pending.append(pType->mSpecializes);
    }
  }
  return false;
}

const ArchitectureAttribute *ArchitectureModel::findAttribute(const QString &type, const QString &attribute) const
{
  QStringList pending = {type};
  QStringList visited;
  while (!pending.isEmpty()) {
    QString current = pending.takeFirst();
    if (visited.contains(current)) {
      continue;
    }
    visited.append(current);
    if (const ArchitectureType *pType = findType(current)) {
      for (const ArchitectureAttribute &candidate : pType->mAttributes) {
        if (candidate.mName == attribute) {
          return &candidate;
        }
      }
      pending.append(pType->mSpecializes);
    }
  }
  return nullptr;
}

QStringList ArchitectureModel::elementsOfType(const QString &type) const
{
  QStringList elements;
  for (const ArchitectureElement &element : mElements) {
    if (isA(element.mType, type)) {
      elements.append(element.mName);
    }
  }
  return elements;
}

/* ------------------------------------------------------------ Modelica side */

const ModelicaVariable *ModelicaClass::findVariable(const QString &name) const
{
  for (const ModelicaVariable &variable : mVariables) {
    if (variable.mName == name) {
      return &variable;
    }
  }
  return nullptr;
}

const ModelicaVariable *Observer::findInput(const QString &name) const
{
  for (const ModelicaVariable &input : mInputs) {
    if (input.mName == name) {
      return &input;
    }
  }
  return nullptr;
}

static QString typeName(const QJsonValue &type)
{
  return type.isObject() ? type.toObject().value("name").toString() : type.toString();
}

static ModelicaVariable modelicaVariable(const QJsonObject &component)
{
  ModelicaVariable variable;
  variable.mName = component.value("name").toString();
  variable.mType = typeName(component.value("type"));
  variable.mDims = toStringList(component.value("dims").toObject().value("typed"));
  variable.mComment = component.value("comment").toString();
  QJsonObject prefixes = component.value("prefixes").toObject();
  variable.mVariability = prefixes.value("variability").toString();
  variable.mDirection = prefixes.value("direction").toString();
  variable.mHasDefault = component.contains("value") || component.contains("modifiers");
  return variable;
}

static bool isClassType(const QJsonValue &type)
{
  if (!type.isObject()) {
    return false;
  }
  QString restriction = type.toObject().value("restriction").toString();
  return restriction == QLatin1String("model") || restriction == QLatin1String("block") || restriction == QLatin1String("class")
      || restriction == QLatin1String("connector") || restriction == QLatin1String("expandable connector");
}

/*!
 * Adds the class of a component type, with the variables of the class and of its base classes.
 * Returns the class name.
 */
QString ModelIndex::addClass(const QJsonObject &type)
{
  QString name = type.value("name").toString();
  if (mClasses.contains(name)) {
    return name;
  }
  ModelicaClass modelicaClass;
  modelicaClass.mName = name;
  modelicaClass.mComment = type.value("comment").toString();
  mClasses.insert(name, modelicaClass);
  QStringList baseClasses;
  QList<ModelicaVariable> variables;
  for (const QJsonValue &item : type.value("elements").toArray()) {
    QJsonObject element = item.toObject();
    QString kind = element.value("$kind").toString();
    if (kind == QLatin1String("extends")) {
      QJsonObject baseClass = element.value("baseClass").toObject();
      if (isClassType(baseClass)) {
        QString baseName = addClass(baseClass);
        baseClasses.append(baseName);
        baseClasses.append(mClasses.value(baseName).mBaseClasses);
        variables.append(mClasses.value(baseName).mVariables);
      }
    } else if (kind == QLatin1String("component")) {
      variables.append(modelicaVariable(element));
    }
  }
  mClasses[name].mBaseClasses = baseClasses;
  mClasses[name].mVariables = variables;
  return name;
}

void ModelIndex::addInstances(const QJsonArray &elements, const QString &prefix)
{
  for (const QJsonValue &item : elements) {
    QJsonObject element = item.toObject();
    QString kind = element.value("$kind").toString();
    if (kind == QLatin1String("extends")) {
      addInstances(element.value("baseClass").toObject().value("elements").toArray(), prefix);
    } else if (kind == QLatin1String("component") && isClassType(element.value("type"))) {
      QJsonObject type = element.value("type").toObject();
      ModelicaInstance instance;
      instance.mPath = prefix + element.value("name").toString();
      instance.mClassName = addClass(type);
      instance.mComment = element.value("comment").toString();
      mInstances.append(instance);
      addInstances(type.value("elements").toArray(), instance.mPath + ".");
    }
  }
}

void ModelIndex::setBehaviourModel(const QJsonObject &modelInstance)
{
  mBehaviourModel = modelInstance.value("name").toString();
  mBehaviourComment = modelInstance.value("comment").toString();
  QJsonObject experiment = modelInstance.value("annotation").toObject().value("experiment").toObject();
  mStopTime = experiment.contains("StopTime") ? experiment.value("StopTime").toDouble() : -1;
  mInstances.clear();
  mClasses.clear();
  addInstances(modelInstance.value("elements").toArray(), QString());
}

bool ModelIndex::addObserver(const QJsonObject &functionInstance)
{
  if (functionInstance.value("restriction").toString() != QLatin1String("function")) {
    return false;
  }
  Observer observer;
  observer.mName = functionInstance.value("name").toString();
  observer.mComment = functionInstance.value("comment").toString();
  int outputs = 0;
  for (const QJsonValue &item : functionInstance.value("elements").toArray()) {
    QJsonObject element = item.toObject();
    if (element.value("$kind").toString() != QLatin1String("component")) {
      continue;
    }
    ModelicaVariable variable = modelicaVariable(element);
    if (variable.mDirection == QLatin1String("input")) {
      observer.mInputs.append(variable);
    } else if (variable.mDirection == QLatin1String("output")) {
      if (outputs++ == 0) {
        observer.mOutput = variable;
      }
    }
  }
  if (outputs != 1) {
    return false;
  }
  QJsonObject crml = functionInstance.value("annotation").toObject().value("__OpenModelica_CRML").toObject();
  observer.mObserves = crml.value("observes").toString();
  observer.mRank = crml.value("rank").toInt();
  for (int i = 0; i < mObservers.size(); ++i) {
    if (mObservers.at(i).mName == observer.mName) {
      mObservers[i] = observer;
      return true;
    }
  }
  mObservers.append(observer);
  return true;
}

const ModelicaInstance *ModelIndex::findInstance(const QString &path) const
{
  for (const ModelicaInstance &instance : mInstances) {
    if (instance.mPath == path) {
      return &instance;
    }
  }
  return nullptr;
}

const ModelicaClass *ModelIndex::findClass(const QString &name) const
{
  auto it = mClasses.constFind(name);
  return it == mClasses.constEnd() ? nullptr : &it.value();
}

const Observer *ModelIndex::findObserver(const QString &name) const
{
  for (const Observer &observer : mObservers) {
    if (observer.mName == name) {
      return &observer;
    }
  }
  return nullptr;
}

bool ModelIndex::isA(const QString &className, const QString &base) const
{
  if (className == base) {
    return true;
  }
  const ModelicaClass *pClass = findClass(className);
  return pClass && pClass->mBaseClasses.contains(base);
}

/* ------------------------------------------------------------ configuration */

static void readCommon(const QJsonObject &object, QString &id, Status &status, double &confidence)
{
  id = object.value("id").toString();
  status = statusFromString(object.value("status").toString());
  confidence = object.value("confidence").toDouble(1.0);
}

static void writeCommon(QJsonObject &object, const QString &id, Status status, double confidence)
{
  object.insert("id", id);
  object.insert("status", statusToString(status));
  object.insert("confidence", confidence);
}

QJsonObject VerificationConfiguration::toJson() const
{
  QJsonObject json;
  json.insert("schema", "om-crml-bindings/0.1");
  json.insert("name", mName);
  if (!mDescription.isEmpty()) {
    json.insert("description", mDescription);
  }
  QJsonObject models;
  models.insert("requirement", mRequirementFile);
  models.insert("architecture", mArchitectureFile);
  models.insert("behaviour", mBehaviourModel);
  models.insert("observers", QJsonArray::fromStringList(mObserverLibraries));
  json.insert("models", models);

  QJsonArray setBindings;
  for (const SetBinding &binding : mSetBindings) {
    QJsonObject object;
    writeCommon(object, binding.mId, binding.mStatus, binding.mConfidence);
    object.insert("set", binding.mSet);
    QJsonArray targets;
    for (const SetTarget &target : binding.mTargets) {
      QJsonObject targetObject;
      targetObject.insert(target.mKind == SetTarget::Collection ? "collection" : "instance", target.mName);
      targets.append(targetObject);
    }
    object.insert("targets", targets);
    object.insert("active", binding.mActive);
    setBindings.append(object);
  }
  json.insert("setBindings", setBindings);

  QJsonArray variableBindings;
  for (const VariableBinding &binding : mVariableBindings) {
    QJsonObject object;
    writeCommon(object, binding.mId, binding.mStatus, binding.mConfidence);
    object.insert("class", binding.mClass);
    object.insert("variable", binding.mVariable);
    QJsonArray observers;
    for (const ObserverCandidate &candidate : binding.mObservers) {
      QJsonObject candidateObject;
      candidateObject.insert("observer", candidate.mObserver);
      candidateObject.insert("enabled", candidate.mEnabled);
      observers.append(candidateObject);
    }
    object.insert("observers", observers);
    if (!binding.mRole.isEmpty()) {
      object.insert("role", binding.mRole);
    }
    variableBindings.append(object);
  }
  json.insert("variableBindings", variableBindings);

  QJsonArray inputBindings;
  for (const InputBinding &binding : mInputBindings) {
    QJsonObject object;
    writeCommon(object, binding.mId, binding.mStatus, binding.mConfidence);
    object.insert("observer", binding.mObserver);
    QJsonArray inputs;
    for (const InputMapping &mapping : binding.mInputs) {
      QJsonObject mappingObject;
      mappingObject.insert("input", mapping.mInput);
      mappingObject.insert("source", mapping.mSource == InputMapping::Architecture ? "architecture" : "behaviour");
      mappingObject.insert("class", mapping.mClass);
      mappingObject.insert("variable", mapping.mVariable);
      inputs.append(mappingObject);
    }
    object.insert("inputs", inputs);
    inputBindings.append(object);
  }
  json.insert("inputBindings", inputBindings);

  QJsonArray instanceBindings;
  for (const InstanceBinding &binding : mInstanceBindings) {
    QJsonObject object;
    writeCommon(object, binding.mId, binding.mStatus, binding.mConfidence);
    object.insert("instance", binding.mInstance);
    QJsonArray targets;
    for (const InstanceTarget &target : binding.mTargets) {
      QJsonObject targetObject;
      targetObject.insert("instance", target.mInstance);
      if (!target.mRole.isEmpty()) {
        targetObject.insert("role", target.mRole);
      }
      targets.append(targetObject);
    }
    object.insert("targets", targets);
    instanceBindings.append(object);
  }
  json.insert("instanceBindings", instanceBindings);
  return json;
}

bool VerificationConfiguration::fromJson(const QJsonObject &json, QString *pError)
{
  if (!checkSchema(json, "om-crml-bindings/0.1", pError)) {
    return false;
  }
  *this = VerificationConfiguration();
  mName = json.value("name").toString();
  mDescription = json.value("description").toString();
  QJsonObject models = json.value("models").toObject();
  mRequirementFile = models.value("requirement").toString();
  mArchitectureFile = models.value("architecture").toString();
  mBehaviourModel = models.value("behaviour").toString();
  mObserverLibraries = toStringList(models.value("observers"));

  for (const QJsonValue &item : json.value("setBindings").toArray()) {
    QJsonObject object = item.toObject();
    SetBinding binding;
    readCommon(object, binding.mId, binding.mStatus, binding.mConfidence);
    binding.mSet = object.value("set").toString();
    for (const QJsonValue &targetValue : object.value("targets").toArray()) {
      QJsonObject targetObject = targetValue.toObject();
      SetTarget target;
      if (targetObject.contains("instance")) {
        target.mKind = SetTarget::Instance;
        target.mName = targetObject.value("instance").toString();
      } else {
        target.mKind = SetTarget::Collection;
        target.mName = targetObject.value("collection").toString();
      }
      binding.mTargets.append(target);
    }
    binding.mActive = object.value("active").toBool(true);
    mSetBindings.append(binding);
  }

  for (const QJsonValue &item : json.value("variableBindings").toArray()) {
    QJsonObject object = item.toObject();
    VariableBinding binding;
    readCommon(object, binding.mId, binding.mStatus, binding.mConfidence);
    binding.mClass = object.value("class").toString();
    binding.mVariable = object.value("variable").toString();
    for (const QJsonValue &candidateValue : object.value("observers").toArray()) {
      QJsonObject candidateObject = candidateValue.toObject();
      ObserverCandidate candidate;
      candidate.mObserver = candidateObject.value("observer").toString();
      candidate.mEnabled = candidateObject.value("enabled").toBool(true);
      binding.mObservers.append(candidate);
    }
    binding.mRole = object.value("role").toString();
    mVariableBindings.append(binding);
  }

  for (const QJsonValue &item : json.value("inputBindings").toArray()) {
    QJsonObject object = item.toObject();
    InputBinding binding;
    readCommon(object, binding.mId, binding.mStatus, binding.mConfidence);
    binding.mObserver = object.value("observer").toString();
    for (const QJsonValue &mappingValue : object.value("inputs").toArray()) {
      QJsonObject mappingObject = mappingValue.toObject();
      InputMapping mapping;
      mapping.mInput = mappingObject.value("input").toString();
      mapping.mSource = mappingObject.value("source").toString() == QLatin1String("architecture") ? InputMapping::Architecture : InputMapping::Behaviour;
      mapping.mClass = mappingObject.value("class").toString();
      mapping.mVariable = mappingObject.value("variable").toString();
      binding.mInputs.append(mapping);
    }
    mInputBindings.append(binding);
  }

  for (const QJsonValue &item : json.value("instanceBindings").toArray()) {
    QJsonObject object = item.toObject();
    InstanceBinding binding;
    readCommon(object, binding.mId, binding.mStatus, binding.mConfidence);
    binding.mInstance = object.value("instance").toString();
    for (const QJsonValue &targetValue : object.value("targets").toArray()) {
      QJsonObject targetObject = targetValue.toObject();
      InstanceTarget target;
      target.mInstance = targetObject.value("instance").toString();
      target.mRole = targetObject.value("role").toString();
      binding.mTargets.append(target);
    }
    mInstanceBindings.append(binding);
  }
  return true;
}

bool VerificationConfiguration::save(const QString &fileName, QString *pError) const
{
  QSaveFile file(fileName);
  if (!file.open(QIODevice::WriteOnly)) {
    if (pError) *pError = QString("Cannot write %1: %2").arg(fileName, file.errorString());
    return false;
  }
  file.write(QJsonDocument(toJson()).toJson(QJsonDocument::Indented));
  if (!file.commit()) {
    if (pError) *pError = QString("Cannot write %1: %2").arg(fileName, file.errorString());
    return false;
  }
  return true;
}

bool VerificationConfiguration::load(const QString &fileName, QString *pError)
{
  QJsonObject json;
  return readJsonFile(fileName, json, pError) && fromJson(json, pError);
}

const SetBinding *VerificationConfiguration::activeSetBinding(const QString &set) const
{
  for (const SetBinding &binding : mSetBindings) {
    if (binding.mSet == set && binding.mActive) {
      return &binding;
    }
  }
  return nullptr;
}

const VariableBinding *VerificationConfiguration::findVariableBinding(const QString &className, const QString &variable) const
{
  for (const VariableBinding &binding : mVariableBindings) {
    if (binding.mClass == className && binding.mVariable == variable) {
      return &binding;
    }
  }
  return nullptr;
}

const InputBinding *VerificationConfiguration::findInputBinding(const QString &observer) const
{
  for (const InputBinding &binding : mInputBindings) {
    if (binding.mObserver == observer) {
      return &binding;
    }
  }
  return nullptr;
}

const InstanceBinding *VerificationConfiguration::findInstanceBinding(const QString &instance) const
{
  for (const InstanceBinding &binding : mInstanceBindings) {
    if (binding.mInstance == instance) {
      return &binding;
    }
  }
  return nullptr;
}

const InputMapping *InputBinding::findInput(const QString &input) const
{
  for (const InputMapping &mapping : mInputs) {
    if (mapping.mInput == input) {
      return &mapping;
    }
  }
  return nullptr;
}

template <typename T>
static void assignIdsTo(QList<T> &bindings, const QString &prefix)
{
  QStringList used;
  for (const T &binding : bindings) {
    used.append(binding.mId);
  }
  int counter = 1;
  for (T &binding : bindings) {
    if (binding.mId.isEmpty()) {
      while (used.contains(prefix + QString::number(counter))) {
        ++counter;
      }
      binding.mId = prefix + QString::number(counter);
      used.append(binding.mId);
    }
  }
}

void VerificationConfiguration::assignIds()
{
  assignIdsTo(mSetBindings, "s");
  assignIdsTo(mVariableBindings, "v");
  assignIdsTo(mInputBindings, "i");
  assignIdsTo(mInstanceBindings, "b");
}

} // namespace CRMLBindings
