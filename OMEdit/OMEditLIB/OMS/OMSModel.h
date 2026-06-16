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


#ifndef OMSMODEL_H
#define OMSMODEL_H

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
    oms_causality_bidir,               ///< bidirectional
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

  enum class FMIKind
  {
    ModelExchange,
    CoSimulation,
    ModelExchangeAndCoSimulation,
    Unknown
  };

  enum class ConnectionType
  {
    oms_connection_single
  };

  class FMUInfo
  {
  public:
    void deserialize(const QJsonObject &jsonObject);
    QString getDescription() const {return mDescription;}
    QString getFMIKind() const {return mFMIKind;}
    QString getFMIKindString() const;
    QString getFMIKindShortString() const;
    QString getFMIVersion() const {return mFMIVersion;}
    QString getGenerationTool() const {return mGenerationTool;}
    QString getGuid() const {return mGuid;}
    QString getGenerationDateAndTime() const {return mGenerationDateAndTime;}
    QString getModelName() const {return mModelName;}
    QString getPath() const {return mPath;}
    QString getVersion() const {return mVersion;}
    bool getCanBeInstantiatedOnlyOncePerProcess() const {return mCanBeInstantiatedOnlyOncePerProcess;}
    bool getCanGetAndSetFMUstate() const {return mCanGetAndSetFMUstate;}
    bool getCanNotUseMemoryManagementFunctions() const {return mCanNotUseMemoryManagementFunctions;}
    bool getCanSerializeFMUstate() const {return mCanSerializeFMUstate;}
    bool getCompletedIntegratorStepNotNeeded() const {return mCompletedIntegratorStepNotNeeded;}
    bool getNeedsExecutionTool() const {return mNeedsExecutionTool;}
    bool getProvidesDirectionalDerivative() const {return mProvidesDirectionalDerivative;}
    bool getCanInterpolateInputs() const {return mCanInterpolateInputs;}
    int getMaxOutputDerivativeOrder() const {return mMaxOutputDerivativeOrder;}
  private:
    QString mDescription;
    QString mFMIKind;
    QString mFMIVersion;
    QString mGenerationTool;
    QString mGuid;
    QString mGenerationDateAndTime;
    QString mModelName;
    QString mPath;
    QString mVersion;
    bool mCanBeInstantiatedOnlyOncePerProcess = false;
    bool mCanGetAndSetFMUstate = false;
    bool mCanNotUseMemoryManagementFunctions = false;
    bool mCanSerializeFMUstate = false;
    bool mCompletedIntegratorStepNotNeeded = false;
    bool mNeedsExecutionTool = false;
    bool mProvidesDirectionalDerivative = false;
    bool mCanInterpolateInputs = false;
    int mMaxOutputDerivativeOrder = 0;
  };

  class ConnectorGeometry
  {
  public:
    void deserialize(const QJsonObject &jsonObject);
    double getX() const {return x;}
    double getY() const {return y;}
    void setX(double value) {x = value;}
    void setY(double value) {y = value;}
  private:
    double x = 0.5;
    double y = 0.5;
  };

  class ElementGeometry
  {
  public:
    void deserialize(const QJsonObject &jsonObject);
    double getX1() const {return x1;}
    double getY1() const {return y1;}
    double getX2() const {return x2;}
    double getY2() const {return y2;}
    double getRotation() const {return rotation;}
    QString getIconSource() const {return iconSource;}
    double getIconRotation() const {return iconRotation;}
    bool getIconFlip() const {return iconFlip;}
    bool getIconFixedAspectRatio() const {return iconFixedAspectRatio;}
    void setX1(double value) {x1 = value;}
    void setY1(double value) {y1 = value;}
    void setX2(double value) {x2 = value;}
    void setY2(double value) {y2 = value;}
    void setRotation(double value) {rotation = value;}
    void setIconSource(const QString &value) {iconSource = value;}
  private:
    double x1 = -10.0;
    double y1 = -10.0;
    double x2 = 10.0;
    double y2 = 10.0;
    double rotation = 0.0;
    QString iconSource;
    double iconRotation = 0.0;
    bool iconFlip = false;
    bool iconFixedAspectRatio = false;
  };

  class ConnectionGeometry
  {
  public:
    void deserialize(const QJsonObject &jsonObject);
    const QVector<double>& getPointsX() const {return mPointsX;}
    const QVector<double>& getPointsY() const {return mPointsY;}
    void setPoints(const QVector<double> &pointsX, const QVector<double> &pointsY)
    {
      mPointsX = pointsX;
      mPointsY = pointsY;
    }
    int getPointsSize() const {return qMin(mPointsX.size(), mPointsY.size());}
  private:
      QVector<double> mPointsX;
      QVector<double> mPointsY;
  };

  class Connection
  {
  public:
    void deserialize(const QJsonObject &jsonObject);
    QString getConnectorA() const {return mConA;}
    QString getConnectorB() const {return mConB;}
    const ConnectionGeometry& getGeometry() const {return mGeometry;}
    ConnectionGeometry& getGeometry() {return mGeometry;}
  private:
    QString mConA;
    QString mConB;
    ConnectionGeometry mGeometry;
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
    static QString signalTypeToString(SignalType signalType);
    static QString causalityToString(Causality causality);
    QString getCausalityString() const;
    QString getSignalTypeString() const;
    void setGeometry(const ConnectorGeometry &geometry) {mGeometry = geometry;}
    bool isInput() const {return mCausality == Causality::oms_causality_input;}
    bool isOutput() const {return mCausality == Causality::oms_causality_output;}
    bool isParameter() const {return mCausality == Causality::oms_causality_parameter;}
  private:
    QString mName;
    Causality mCausality = Causality::oms_causality_undefined;
    SignalType mSignalType = SignalType::oms_signal_type_real;
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
    const QVector<Connection*>& getConnections() const {return mConnections;}
    bool isSystem() const;
    bool isComponent() const;
    void setGeometry(const ElementGeometry &geometry) {mGeometry = geometry;}
    bool hasFMUInfo() const {return mHasFMUInfo;}
    const FMUInfo& getFMUInfo() const {return mFMUInfo;}
  private:
    QString mName;
    QString mType;
    ElementGeometry mGeometry;
    QVector<Element*> mElements;
    QVector<Connector*> mConnectors;
    QVector<Connection*> mConnections;
    bool mHasFMUInfo = false;
    FMUInfo mFMUInfo;
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
