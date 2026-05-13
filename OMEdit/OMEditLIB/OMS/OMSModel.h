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

enum class Causality
{
  oms_causality_input,               ///< input
  oms_causality_output,              ///< output
  oms_causality_parameter,           ///< parameter
  oms_causality_calculatedParameter, ///< calculated parameter
  oms_causality_bidir,               ///< bidirecitonal
  oms_causality_undefined
};

enum class SignalType
{
  oms_signal_type_real,
  oms_signal_type_integer,
  oms_signal_type_boolean,
  oms_signal_type_string,
  oms_signal_type_enum,
};

class ConnectorGeometry
{
public:
  void deserialize(const QJsonObject &jsonObject);
  double getX() const {return x;}
  double getY() const {return y;}
private:
  double x = 0.5;
  double y = 0.5;
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
  const Causality& getCausality() const {return mCausality;}
  const SignalType& getSignalType() const {return mSignalType;}
  const ConnectorGeometry& getGeometry() const {return mGeometry;}
  static Causality causalityFromString(const QString &value);
  static SignalType signalTypeFromString(const QString &value);
  QString getCausalityString() const;
  QString getSignalTypeString() const;
  bool isInput() const {return mCausality == Causality::oms_causality_input;}
  bool isOutput() const {return mCausality == Causality::oms_causality_output;}
  bool isParameter() const {return mCausality == Causality::oms_causality_parameter;}

private:
  QString mName;
  Causality mCausality;
  SignalType mSignalType;
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
