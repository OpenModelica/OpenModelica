#include "OMSModel.h"

#include <cstring>

namespace OMSModel
{
void ConnectorGeometry::deserialize(const QJsonObject &jsonObject)
{
    mX = jsonObject.value("x").toDouble(0.5);
    mY = jsonObject.value("y").toDouble(0.5);
}

void ElementGeometry::deserialize(const QJsonObject &jsonObject)
{
    mX1 = jsonObject.value("x1").toDouble(-10.0);
    mY1 = jsonObject.value("y1").toDouble(-10.0);
    mX2 = jsonObject.value("x2").toDouble(10.0);
    mY2 = jsonObject.value("y2").toDouble(10.0);
    mRotation = jsonObject.value("rotation").toDouble(0.0);
    mIconSource = jsonObject.value("iconSource").toString();
    mIconRotation = jsonObject.value("iconRotation").toDouble(0.0);
    mIconFlip = jsonObject.value("iconFlip").toBool(false);
    mIconFixedAspectRatio = jsonObject.value("iconFixedAspectRatio").toBool(false);
}

ssd_element_geometry_t ElementGeometry::toSsdElementGeometry() const
{
    ssd_element_geometry_t geometry;
    geometry.x1 = mX1;
    geometry.y1 = mY1;
    geometry.x2 = mX2;
    geometry.y2 = mY2;
    geometry.rotation = mRotation;
    geometry.iconRotation = mIconRotation;
    geometry.iconFlip = mIconFlip;
    geometry.iconFixedAspectRatio = mIconFixedAspectRatio;

    if (mIconSource.isEmpty()) {
        geometry.iconSource = NULL;
    } else {
        QByteArray iconSourceBytes = mIconSource.toUtf8();
        geometry.iconSource = new char[iconSourceBytes.size() + 1];
        strcpy(geometry.iconSource, iconSourceBytes.constData());
    }

    return geometry;
}

void Connector::deserialize(const QJsonObject &jsonObject)
{
    mName = jsonObject.value("name").toString();
    mCausality = jsonObject.value("causality").toString().toLower();
    mSignalType = jsonObject.value("signalType").toString().toLower();

    if (jsonObject.value("geometry").isObject()) {
        mGeometry.deserialize(jsonObject.value("geometry").toObject());
    }
}

bool Connector::isInput() const
{
    return mCausality == "input";
}

bool Connector::isOutput() const
{
    return mCausality == "output";
}

bool Connector::isParameter() const
{
    return mCausality == "parameter";
}

Element::~Element()
{
    qDeleteAll(mElements);
    qDeleteAll(mConnectors);
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
        << "causality:" << conn->getCausality()
        << "signalType:" << conn->getSignalType()
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
