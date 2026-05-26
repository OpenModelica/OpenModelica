#include "OMSModel.h"

#include <cstring>
#include <QPointF>

namespace OMSModel
{
  void ConnectorGeometry::deserialize(const QJsonObject &jsonObject)
  {
    x = jsonObject.value("x").toDouble(0.5);
    y = jsonObject.value("y").toDouble(0.5);
  }

  void ElementGeometry::deserialize(const QJsonObject &jsonObject)
  {
    x1 = jsonObject.value("x1").toDouble(-10.0);
    y1 = jsonObject.value("y1").toDouble(-10.0);
    x2 = jsonObject.value("x2").toDouble(10.0);
    y2 = jsonObject.value("y2").toDouble(10.0);
    rotation = jsonObject.value("rotation").toDouble(0.0);
    iconSource = jsonObject.value("iconSource").toString();
    iconRotation = jsonObject.value("iconRotation").toDouble(0.0);
    iconFlip = jsonObject.value("iconFlip").toBool(false);
    iconFixedAspectRatio = jsonObject.value("iconFixedAspectRatio").toBool(false);
  }

  void Connector::deserialize(const QJsonObject &jsonObject)
  {
    mName = jsonObject.value("name").toString();
    mCausality = causalityFromString(jsonObject.value("causality").toString());
    mSignalType = signalTypeFromString(jsonObject.value("signalType").toString());

    if (jsonObject.value("geometry").isObject()) {
      mGeometry.deserialize(jsonObject.value("geometry").toObject());
    }
  }

  Causality Connector::causalityFromString(const QString &value)
  {
    const QString v = value.toLower();
    if (v == "input") {
        return Causality::oms_causality_input;
    } else if (v == "output") {
        return Causality::oms_causality_output;
    } else if (v == "parameter") {
        return Causality::oms_causality_parameter;
    } else if (v == "calculatedParameter") {
        return Causality::oms_causality_calculatedParameter;
    } else if (v == "bidir") {
        return Causality::oms_causality_bidir;
    }
    return Causality::oms_causality_undefined;
  }

  SignalType Connector::signalTypeFromString(const QString &value)
  {
    const QString v = value.toLower();
    if (v == "real") {
      return SignalType::oms_signal_type_real;
    } else if (v == "integer") {
        return SignalType::oms_signal_type_integer;
    } else if (v == "boolean") {
        return SignalType::oms_signal_type_boolean;
    } else if (v == "string") {
        return SignalType::oms_signal_type_string;
    } else if (v == "enum" || v == "enumeration") {
        return SignalType::oms_signal_type_enum;
    }
    return SignalType::oms_signal_type_real;
  }

  QString Connector::getCausalityString() const
  {
    switch (mCausality) {
      case Causality::oms_causality_input:
        return "Input";
      case Causality::oms_causality_output:
        return "Output";
      case Causality::oms_causality_parameter:
        return "Parameter";
      case Causality::oms_causality_calculatedParameter:
        return "CalculatedParameter";
      case Causality::oms_causality_bidir:
        return "bidir";
      case Causality::oms_causality_undefined:
      default:
        return "undefined";
    }
  }

  QString Connector::getSignalTypeString() const
  {
    switch (mSignalType) {
      case SignalType::oms_signal_type_real:
        return "Real";
      case SignalType::oms_signal_type_integer:
        return "Integer";
      case SignalType::oms_signal_type_boolean:
        return "Boolean";
      case SignalType::oms_signal_type_string:
        return "String";
      case SignalType::oms_signal_type_enum:
        return "Enum";
      default:
        return "unknown";
      }
  }

  QString Connector::causalityToString(Causality causality)
  {
    switch (causality) {
      case Causality::oms_causality_input:
        return "Input";
      case Causality::oms_causality_output:
        return "Output";
      case Causality::oms_causality_parameter:
        return "Parameter";
      case Causality::oms_causality_calculatedParameter:
        return "CalculatedParameter";
      case Causality::oms_causality_bidir:
        return "Bidir";
      case Causality::oms_causality_undefined:
      default:
        return "Undefined";
    }
  }

  QString Connector::signalTypeToString(SignalType signalType)
  {
    switch (signalType) {
      case SignalType::oms_signal_type_real:
        return "Real";
      case SignalType::oms_signal_type_integer:
        return "Integer";
      case SignalType::oms_signal_type_boolean:
        return "Boolean";
      case SignalType::oms_signal_type_string:
        return "String";
      case SignalType::oms_signal_type_enum:
        return "Enum";
      default:
        return "Real";
    }
  }

  void ConnectionGeometry::deserialize(const QJsonObject &jsonObject)
  {
    mPointsX.clear();
    mPointsY.clear();

    const QJsonArray pointsX = jsonObject.value("pointsX").toArray();
    const QJsonArray pointsY = jsonObject.value("pointsY").toArray();

    for (const QJsonValue &point : pointsX) {
      mPointsX.append(point.toDouble());
    }

    for (const QJsonValue &point : pointsY) {
      mPointsY.append(point.toDouble());
    }
  }

  void Connection::deserialize(const QJsonObject &jsonObject)
  {
    mConA = jsonObject.value("conA").toString();
    mConB = jsonObject.value("conB").toString();

    if (jsonObject.value("geometry").isObject()) {
      mGeometry.deserialize(jsonObject.value("geometry").toObject());
    }
  }

  void FMUInfo::deserialize(const QJsonObject &jsonObject)
  {
    mDescription = jsonObject.value("description").toString();
    mFMIVersion = jsonObject.value("fmiVersion").toString();
    mGenerationTool = jsonObject.value("generationTool").toString();
    mGuid = jsonObject.value("guid").toString();
    mGenerationDateAndTime = jsonObject.value("generationDateAndTime").toString();
    mModelName = jsonObject.value("modelName").toString();
    mPath = jsonObject.value("path").toString();
    mVersion = jsonObject.value("version").toString();
    mFMIKind = jsonObject.value("fmiKind").toString();

    mCanBeInstantiatedOnlyOncePerProcess = jsonObject.value("canBeInstantiatedOnlyOncePerProcess").toBool();
    mCanGetAndSetFMUstate = jsonObject.value("canGetAndSetFMUstate").toBool();
    mCanNotUseMemoryManagementFunctions = jsonObject.value("canNotUseMemoryManagementFunctions").toBool();
    mCanSerializeFMUstate = jsonObject.value("canSerializeFMUstate").toBool();
    mCompletedIntegratorStepNotNeeded = jsonObject.value("completedIntegratorStepNotNeeded").toBool();
    mNeedsExecutionTool = jsonObject.value("needsExecutionTool").toBool();
    mProvidesDirectionalDerivative = jsonObject.value("providesDirectionalDerivative").toBool();
    mCanInterpolateInputs = jsonObject.value("canInterpolateInputs").toBool();
    mMaxOutputDerivativeOrder = jsonObject.value("maxOutputDerivativeOrder").toInt();
  }

  Element::~Element()
  {
    qDeleteAll(mElements);
    qDeleteAll(mConnectors);
    qDeleteAll(mConnections);
  }

  void Element::deserialize(const QJsonObject &jsonObject)
  {
    mName = jsonObject.value("name").toString();
    mType = jsonObject.value("type").toString().toLower();

    if (jsonObject.value("geometry").isObject()) {
      mGeometry.deserialize(jsonObject.value("geometry").toObject());
    }

    const QJsonArray connectors = jsonObject.value("connectors").toArray();
    for (const QJsonValue &connectorValue : connectors) {
      if (!connectorValue.isObject()) {
          continue;
      }

      Connector *pConnector = new Connector;
      pConnector->deserialize(connectorValue.toObject());
      mConnectors.append(pConnector);
    }

    if (jsonObject.value("fmuInfo").isObject()) {
      mFMUInfo.deserialize(jsonObject.value("fmuInfo").toObject());
      mHasFMUInfo = true;
    }

    const QJsonArray connections = jsonObject.value("connections").toArray();
    for (const QJsonValue &connectionValue : connections) {
      if (!connectionValue.isObject()) {
        continue;
      }

      Connection *pConnection = new Connection;
      pConnection->deserialize(connectionValue.toObject());
      mConnections.append(pConnection);
    }

    const QJsonArray elements = jsonObject.value("elements").toArray();
    for (const QJsonValue &elementValue : elements) {
      if (!elementValue.isObject()) {
        continue;
      }

      Element *pElement = new Element;
      pElement->deserialize(elementValue.toObject());
      mElements.append(pElement);
    }
  }

  bool Element::isSystem() const
  {
    return mType == "system";
  }

  bool Element::isComponent() const
  {
    return mType == "component";
  }

  Model::Model(const QJsonArray &elementsJson)
      : mElementsJson(elementsJson)
  {
  }

  Model::~Model()
  {
    qDeleteAll(mRootElements);
  }

  void Model::deserialize()
  {
    qDeleteAll(mRootElements);
    mRootElements.clear();

    for (const QJsonValue &elementValue : mElementsJson) {
      if (!elementValue.isObject()) {
        continue;
      }

      Element *pElement = new Element;
      pElement->deserialize(elementValue.toObject());
      mRootElements.append(pElement);
    }
  }

  void Model::printElement(const OMSModel::Element *element, int indent)
  {
    QString pad(indent, ' ');

    qDebug() << pad << "element:" << element->getName()
             << "type:" << element->getType()
             << "children:" << element->getElements().size()
             << "connectors:" << element->getConnectors().size();

    for (const OMSModel::Connector *conn : element->getConnectors()) {
      qDebug() << pad + "  " << "connector:" << conn->getName()
      << "causality:" << conn->getCausalityString()
      << "signalType:" << conn->getSignalTypeString()
      << "x:" << conn->getGeometry().getX()
      << "y:" << conn->getGeometry().getY();
    }

    for (const OMSModel::Element *child : element->getElements()) {
      printElement(child, indent + 2);
    }
  }

  void Model::debugPrint()
  {
    for (const OMSModel::Element *root : getRootElements()) {
      printElement(root);
    }
  }
}
