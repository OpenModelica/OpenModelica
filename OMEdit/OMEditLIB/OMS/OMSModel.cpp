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

/*
 * @author Arunkumar Palanisamy <arunkumar.palanisamy@liu.se>
 */


#include "OMSModel.h"

#include <cstring>
#include <QPointF>

namespace OMSModel
{
  /*!
   * \class ConnectorGeometry
   * \brief Stores the 2-D position of a connector on its parent element icon (x, y in [0,1]).
   * \brief Populates geometry from a JSON object.
   * \param jsonObject - JSON object containing "x" and "y" fields.
   */
  void ConnectorGeometry::deserialize(const QJsonObject &jsonObject)
  {
    x = jsonObject.value("x").toDouble(0.5);
    y = jsonObject.value("y").toDouble(0.5);
  }

  /*!
   * \class ElementGeometry
   * \brief Stores the bounding box, rotation, and icon source of a system or component element.
   * \brief Populates geometry from a JSON object.
   * \param jsonObject - JSON object from the getElements reply geometry field.
   */
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

  /*!
   * \class Connector
   * \brief Represents a single connector (port) on an element with its causality, type, and geometry.
   * \brief Populates connector fields from a JSON object.
   * \param jsonObject - JSON object from the connectors array in a getElements reply.
   */
  void Connector::deserialize(const QJsonObject &jsonObject)
  {
    mName = jsonObject.value("name").toString();
    mCausality = causalityFromString(jsonObject.value("causality").toString());
    mSignalType = signalTypeFromString(jsonObject.value("signalType").toString());

    if (jsonObject.value("geometry").isObject()) {
      mGeometry.deserialize(jsonObject.value("geometry").toObject());
    }
  }

  /*!
   * \brief Converts a causality string (e.g. "input") to the Causality enum value.
   * \param value - the string to convert.
   * \return the matching Causality enum value, or oms_causality_undefined if unrecognised.
   */
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

  /*!
   * \brief Converts a signal type string (e.g. "Real") to the SignalType enum value.
   * \param value - the string to convert.
   * \return the matching SignalType enum value.
   */
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

  /*!
   * \brief Returns the causality as a human-readable string.
   * \return causality string (e.g. "Input", "Output", "Parameter").
   */
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

  /*!
   * \brief Returns the signal type as a human-readable string.
   * \return signal type string (e.g. "Real", "Integer", "Boolean").
   */
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

  /*!
   * \brief Converts a Causality enum value to its string representation.
   * \param causality - the enum value to convert.
   * \return the string representation (e.g. "Input", "Output").
   */
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

  /*!
   * \brief Converts a SignalType enum value to its string representation.
   * \param signalType - the enum value to convert.
   * \return the string representation (e.g. "Real", "Integer").
   */
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

  /*!
   * \class ConnectionGeometry
   * \brief Stores the polyline waypoints of a connection line as parallel X and Y vectors.
   * \brief Populates waypoints from a JSON object.
   * \param jsonObject - JSON object containing "pointsX" and "pointsY" arrays.
   */
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

  /*!
   * \class Connection
   * \brief Represents a signal connection between two connectors in an OMSimulator system.
   * \brief Populates connection fields from a JSON object.
   * \param jsonObject - JSON object containing "conA", "conB", and "geometry".
   */
  void Connection::deserialize(const QJsonObject &jsonObject)
  {
    mConA = jsonObject.value("conA").toString();
    mConB = jsonObject.value("conB").toString();

    if (jsonObject.value("geometry").isObject()) {
      mGeometry.deserialize(jsonObject.value("geometry").toObject());
    }
  }

  /*!
   * \class FMUInfo
   * \brief Holds static metadata about an FMU read from its modelDescription.xml.
   * Deserialized from the "fmuInfo" field of a component element returned by
   * the getElements ZMQ command.
   * \brief Populates FMUInfo fields from a JSON object.
   * \param jsonObject - the "fmuInfo" JSON object from the getElements reply.
   */
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


  /*!
   * \class Element
   * \brief Represents a node in the OMSimulator model tree — either a System or a Component (FMU).
   * Elements are deserialized recursively: a System element may contain child elements
   * (sub-systems or components), connectors, and connections.
   * \brief Recursively deletes all child elements, connectors, and connections.
   */
  Element::~Element()
  {
    qDeleteAll(mElements);
    qDeleteAll(mConnectors);
    qDeleteAll(mConnections);
  }

  /*!
   * \brief Populates this element and its children recursively from a JSON object.
   * \param jsonObject - one element node from the getElements reply.
   */
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

    mFilePath = jsonObject.value("filePath").toString();

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

  /*!
   * \brief Returns true if this element represents a System.
   * \return true if the element type is "system".
   */
  bool Element::isSystem() const
  {
    return mType == "system";
  }

  /*!
   * \brief Returns true if this element represents a Component (FMU instance).
   * \return true if the element type is "component".
   */
  bool Element::isComponent() const
  {
    return mType == "component";
  }

  /*!
   * \brief Returns true if this element represents a ComponentTable.
   * \return true if the element type is "componenttable" (stored lowercase after deserialization).
   */
  bool Element::isComponentTable() const
  {
    return mType == "componenttable";
  }

  /*!
   * \class Model
   * \brief Top-level container that holds the deserialized OMSimulator model tree.
   * Constructed from the JSON array returned by the getElements ZMQ command and
   * owns the root Element objects for the lifetime of the loaded model.
   * \brief Constructs a Model from the raw elements JSON array.
   * \param elementsJson - the "elements" array from the getElements ZMQ reply.
   */
  Model::Model(const QJsonArray &elementsJson)
      : mElementsJson(elementsJson)
  {
  }

  /*!
   * \brief Recursively deletes all root elements.
   */
  Model::~Model()
  {
    qDeleteAll(mRootElements);
  }

  /*!
   * \brief Deserializes the stored JSON into root Element objects.
   */
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

  /*!
   * \brief Recursively prints an element tree node to stdout for debugging.
   * \param element - the element to print.
   * \param indent  - current indentation depth.
   */
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

  /*!
   * \brief Prints the full model tree to stdout for debugging.
   */
  void Model::debugPrint()
  {
    for (const OMSModel::Element *root : getRootElements()) {
      printElement(root);
    }
  }
}
