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
/*
 * @author Arunkumar Palanisamy <arunkumar.palanisamy@liu.se>
 */



#ifndef OMSMODEL_H
#define OMSMODEL_H

#include "OMSimulator/OMSimulator.h"

#include <QJsonArray>
#include <QJsonObject>
#include <QString>
#include <QVector>

namespace OMSModel
{
class ConnectorGeometry
{
public:
    void deserialize(const QJsonObject &jsonObject);

    double getX() const {return mX;}
    double getY() const {return mY;}

private:
    double mX = 0.5;
    double mY = 0.5;
};

class ElementGeometry
{
public:
    void deserialize(const QJsonObject &jsonObject);
    ssd_element_geometry_t toSsdElementGeometry() const;

private:
    double mX1 = -10.0;
    double mY1 = -10.0;
    double mX2 = 10.0;
    double mY2 = 10.0;
    double mRotation = 0.0;
    QString mIconSource;
    double mIconRotation = 0.0;
    bool mIconFlip = false;
    bool mIconFixedAspectRatio = false;
};

class Connector
{
public:
    void deserialize(const QJsonObject &jsonObject);

    const QString& getName() const {return mName;}
    const QString& getCausality() const {return mCausality;}
    const QString& getSignalType() const {return mSignalType;}
    const ConnectorGeometry& getGeometry() const {return mGeometry;}

    bool isInput() const;
    bool isOutput() const;
    bool isParameter() const;

private:
    QString mName;
    QString mCausality;
    QString mSignalType;
    ConnectorGeometry mGeometry;
};

class Element
{
public:
    ~Element();

    void deserialize(const QJsonObject &jsonObject);

    const QString& getName() const {return mName;}
    const QString& getType() const {return mType;}
    const ElementGeometry& getGeometry() const {return mGeometry;}
    const QVector<Element*>& getElements() const {return mElements;}
    const QVector<Connector*>& getConnectors() const {return mConnectors;}

    bool isSystem() const;
    bool isComponent() const;

private:
    QString mName;
    QString mType;
    ElementGeometry mGeometry;
    QVector<Element*> mElements;
    QVector<Connector*> mConnectors;
};

class Model
{
public:
    Model(const QJsonArray &elementsJson);
    ~Model();

    void deserialize();
    void printElement(const OMSModel::Element *element, int indent = 0);
    void debugPrint();
    const QVector<Element*>& getRootElements() const {return mRootElements;}

private:
    QJsonArray mElementsJson;
    QVector<Element*> mRootElements;
};
}

#endif // OMSMODEL_H
