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

#include "MetaModelEditor.h"
#include "ComponentProperties.h"

XMLDocument::XMLDocument()
  : QDomDocument()
{

}

XMLDocument::XMLDocument(MetaModelEditor *pMetaModelEditor)
  : QDomDocument()
{
  mpMetaModelEditor = pMetaModelEditor;
}

QString XMLDocument::toString() const
{
  TabSettings tabSettings = mpMetaModelEditor->getMainWindow()->getOptionsDialog()->getTabSettings();
  return QDomDocument::toString(tabSettings.getIndentSize());
}


MetaModelEditor::MetaModelEditor(ModelWidget *pModelWidget)
  : BaseEditor(pModelWidget), mLastValidText(""), mTextChanged(false), mForceSetPlainText(false)
{
  mXmlDocument = XMLDocument(this);
}

/*!
 * \brief MetaModelEditor::validateText
 * When user make some changes in the MetaModelEditor text then this method validates the text.
 * \return
 */
bool MetaModelEditor::validateText()
{
  if (mTextChanged) {
    // if the user makes few mistakes in the text then dont let him change the perspective
    if (!mpModelWidget->metaModelEditorTextChanged()) {
      QMessageBox *pMessageBox = new QMessageBox(mpMainWindow);
      pMessageBox->setWindowTitle(QString(Helper::applicationName).append(" - ").append(Helper::error));
      pMessageBox->setIcon(QMessageBox::Critical);
      pMessageBox->setAttribute(Qt::WA_DeleteOnClose);
      pMessageBox->setText(GUIMessages::getMessage(GUIMessages::ERROR_IN_TEXT).arg("MetaModel")
                           .append(GUIMessages::getMessage(GUIMessages::CHECK_MESSAGES_BROWSER))
                           .append(GUIMessages::getMessage(GUIMessages::REVERT_PREVIOUS_OR_FIX_ERRORS_MANUALLY)));
      pMessageBox->addButton(Helper::fixErrorsManually, QMessageBox::AcceptRole);
      pMessageBox->addButton(Helper::revertToLastCorrectVersion, QMessageBox::RejectRole);
      // we set focus to this widget here so when the error dialog is closed Qt gives back the focus to this widget.
      mpPlainTextEdit->setFocus(Qt::ActiveWindowFocusReason);
      int answer = pMessageBox->exec();
      switch (answer) {
        case QMessageBox::RejectRole:
          mTextChanged = false;
          // revert back to last correct version
          setPlainText(mLastValidText);
          return true;
        case QMessageBox::AcceptRole:
        default:
          mTextChanged = true;
          return false;
      }
    } else {
      mTextChanged = false;
      mLastValidText = mpPlainTextEdit->toPlainText();
    }
  }
  return true;
}

/*!
 * \brief MetaModelEditor::getSubModelsElement
 * Returns the SubModels element tag.
 * \return
 */
QDomElement MetaModelEditor::getSubModelsElement()
{
  QDomNodeList subModels = mXmlDocument.elementsByTagName("SubModels");
  if (subModels.size() > 0) {
    return subModels.at(0).toElement();
  }
  return QDomElement();
}

/*!
 * \brief MetaModelEditor::getSubModels
 * Returns the list of SubModel tags.
 * \return
 */
QDomNodeList MetaModelEditor::getSubModels()
{
  return mXmlDocument.elementsByTagName("SubModel");
}

/*!
 * \brief MetaModelEditor::getConnectionsElement
 * Returns the Connections element tag.
 * \return
 */
QDomElement MetaModelEditor::getConnectionsElement()
{
  QDomNodeList connections = mXmlDocument.elementsByTagName("Connections");
  if (connections.size() > 0) {
    return connections.at(0).toElement();
  }
  return QDomElement();
}

/*!
 * \brief MetaModelEditor::getConnections
 * Returns the list of Connection tags.
 * \return
 */
QDomNodeList MetaModelEditor::getConnections()
{
  return mXmlDocument.elementsByTagName("Connection");
}

/*!
 * \brief MetaModelEditor::addSubModel
 * Adds a SubModel tag with Annotation tag as child of it.
 * \param name
 * \param exactStep
 * \param modelFile
 * \param startCommand
 * \param visible
 * \param origin
 * \param extent
 * \param rotation
 * \return
 */
bool MetaModelEditor::addSubModel(QString name, QString exactStep, QString modelFile, QString startCommand, QString visible, QString origin,
                            QString extent, QString rotation)
{
  QDomElement subModels = getSubModelsElement();
  if (!subModels.isNull()) {
    QDomElement subModel = mXmlDocument.createElement("SubModel");
    subModel.setAttribute("Name", name);
    subModel.setAttribute("ExactStep", exactStep);
    subModel.setAttribute("ModelFile", modelFile);
    subModel.setAttribute("StartCommand", startCommand);
    // create Annotation Element
    QDomElement annotation = mXmlDocument.createElement("Annotation");
    annotation.setAttribute("Visible", visible);
    annotation.setAttribute("Origin", origin);
    annotation.setAttribute("Extent", extent);
    annotation.setAttribute("Rotation", rotation);
    subModel.appendChild(annotation);
    subModels.appendChild(subModel);
    setPlainText(mXmlDocument.toString());
    return true;
  }
  return false;
}

/*!
 * \brief MetaModelEditor::createAnnotationElement
 * Creates an Annotation tag for SubModel.
 * \param subModel
 * \param visible
 * \param origin
 * \param extent
 * \param rotation
 */
void MetaModelEditor::createAnnotationElement(QDomElement subModel, QString visible, QString origin, QString extent, QString rotation)
{
  QDomElement annotation = mXmlDocument.createElement("Annotation");
  annotation.setAttribute("Visible", visible);
  annotation.setAttribute("Origin", origin);
  annotation.setAttribute("Extent", extent);
  annotation.setAttribute("Rotation", rotation);
  subModel.insertBefore(annotation, QDomNode());
  setPlainText(mXmlDocument.toString());
}

/*!
 * \brief MetaModelEditor::updateSubModelPlacementAnnotation
 * Updates the SubModel annotation.
 * \param name
 * \param visible
 * \param origin
 * \param extent
 * \param rotation
 */
void MetaModelEditor::updateSubModelPlacementAnnotation(QString name, QString visible, QString origin, QString extent, QString rotation)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    if (subModel.attribute("Name").compare(name) == 0) {
      QDomNodeList subModelChildren = subModel.childNodes();
      for (int j = 0 ; j < subModelChildren.size() ; j++) {
        QDomElement annotationElement = subModelChildren.at(j).toElement();
        if (annotationElement.tagName().compare("Annotation") == 0) {
          annotationElement.setAttribute("Visible", visible);
          annotationElement.setAttribute("Origin", origin);
          annotationElement.setAttribute("Extent", extent);
          annotationElement.setAttribute("Rotation", rotation);
          setPlainText(mXmlDocument.toString());
          return;
        }
      }
      // create annotation element
      createAnnotationElement(subModel, visible, origin, extent, rotation);
      break;
    }
  }
}

/*!
 * \brief MetaModelEditor::updateSubModelParameters
 * Updates the SubModel parameters.
 * \param name
 * \param startCommand
 * \param ExactStepflag
 */
void MetaModelEditor::updateSubModelParameters(QString name, QString startCommand, QString exactStepFlag)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    if (subModel.attribute("Name").compare(name) == 0) {
      subModel.setAttribute("StartCommand", startCommand);
      subModel.setAttribute("ExactStep", exactStepFlag);
      setPlainText(mXmlDocument.toString());
      return;
     }
   }
}

/*!
 * \brief MetaModelEditor::createConnection
 * Adds a connection tag with Annotation tag as child of it.
 * \param pConnectionLineAnnotation
 * \return
 */
bool MetaModelEditor::createConnection(LineAnnotation *pConnectionLineAnnotation)
{
  QDomElement connections = getConnectionsElement();
  if (!connections.isNull()) {
    QDomElement connection = mXmlDocument.createElement("Connection");
    connection.setAttribute("From", pConnectionLineAnnotation->getStartComponentName());
    connection.setAttribute("To", pConnectionLineAnnotation->getEndComponentName());
    connection.setAttribute("Delay", pConnectionLineAnnotation->getDelay());
    connection.setAttribute("alpha", pConnectionLineAnnotation->getAlpha());
    connection.setAttribute("Zf", pConnectionLineAnnotation->getZf());
    connection.setAttribute("Zfr", pConnectionLineAnnotation->getZfr());
    // create Annotation Element
    QDomElement annotation = mXmlDocument.createElement("Annotation");
    annotation.setAttribute("Points", pConnectionLineAnnotation->getMetaModelShapeAnnotation());
    connection.appendChild(annotation);
    connections.appendChild(connection);
    setPlainText(mXmlDocument.toString());
    return true;
  }
  return false;
}

/*!
 * \brief MetaModelEditor::updateConnection
 * Updates the MetaModel connection annotation.
 * \param pConnectionLineAnnotation
 */
void MetaModelEditor::updateConnection(LineAnnotation *pConnectionLineAnnotation)
{
  QDomNodeList connectionList = mXmlDocument.elementsByTagName("Connection");
  for (int i = 0 ; i < connectionList.size() ; i++) {
    QDomElement connection = connectionList.at(i).toElement();
    if (connection.attribute("From").compare(pConnectionLineAnnotation->getStartComponentName()) == 0 &&
        connection.attribute("To").compare(pConnectionLineAnnotation->getEndComponentName()) == 0) {
      connection.setAttribute("Delay", pConnectionLineAnnotation->getDelay());
      connection.setAttribute("alpha", pConnectionLineAnnotation->getAlpha());
      connection.setAttribute("Zf", pConnectionLineAnnotation->getZf());
      connection.setAttribute("Zfr", pConnectionLineAnnotation->getZfr());
      QDomNodeList connectionChildren = connection.childNodes();
      bool annotationFound = false;
      for (int j = 0 ; j < connectionChildren.size() ; j++) {
        QDomElement annotationElement = connectionChildren.at(j).toElement();
        if (annotationElement.tagName().compare("Annotation") == 0) {
          annotationFound = true;
          annotationElement.setAttribute("Points", pConnectionLineAnnotation->getMetaModelShapeAnnotation());
          setPlainText(mXmlDocument.toString());
          return;
        }
      }
      // if we found the connection and there is no annotation with it then add the annotation element.
      if (!annotationFound) {
        QDomElement annotationElement = mXmlDocument.createElement("Annotation");
        annotationElement.setAttribute("Points", pConnectionLineAnnotation->getMetaModelShapeAnnotation());
        connection.appendChild(annotationElement);
        setPlainText(mXmlDocument.toString());
      }
      break;
    }
  }
}

/*!
 * \brief MetaModelEditor::updateSimulationParams
 * Updates the simulation parameters.
 * \param startTime
 * \param stopTime
 */
void MetaModelEditor::updateSimulationParams(QString startTime, QString stopTime)
{
  QDomElement simulationParamsElement = mXmlDocument.documentElement().firstChildElement("SimulationParams");
  if (!simulationParamsElement.isNull()) {
    simulationParamsElement.setAttribute("StartTime", startTime);
    simulationParamsElement.setAttribute("StopTime", stopTime);
  }
  setPlainText(mXmlDocument.toString());
}

/*!
 * \brief MetaModelEditor::isSimulationParams
 * Updates the simulation parameters.
 */
bool MetaModelEditor::isSimulationParams()
{
  QDomElement simulationParamsElement = mXmlDocument.documentElement().firstChildElement("SimulationParams");
  if (!simulationParamsElement.isNull()) {
    return true;
  }
  return false;
}

/*!
 * \brief MetaModelEditor::getSimulationStartTime
 * Gets the simulation start time.
 */
QString MetaModelEditor::getSimulationStartTime()
{
  QDomElement simulationParamsElement = mXmlDocument.documentElement().firstChildElement("SimulationParams");
  return simulationParamsElement.attribute("StartTime");
}

/*!
 * \brief MetaModelEditor::getSimulationStopTime
 * Gets the simulation stop time.
 */
QString MetaModelEditor::getSimulationStopTime()
{
  QDomElement simulationParamsElement = mXmlDocument.documentElement().firstChildElement("SimulationParams");
  return simulationParamsElement.attribute("StopTime");
}
/*!
 * \brief MetaModelEditor::addInterfacesData
 * Adds the InterfacePoint tag to SubModel.
 * \param interfaces
 */
void MetaModelEditor::addInterfacesData(QDomElement interfaces)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    QDomElement interfaceDataElement = interfaces.firstChildElement();
    while (!interfaceDataElement.isNull()) {
      if (subModel.attribute("Name").compare(interfaceDataElement.attribute("model")) == 0
          && !existInterfaceData(subModel.attribute("Name"), interfaceDataElement.attribute("name"))) {
        QDomElement interfacePoint = mXmlDocument.createElement("InterfacePoint");
        interfacePoint.setAttribute("Name",interfaceDataElement.attribute("name"));
        interfacePoint.setAttribute("Position",interfaceDataElement.attribute("Position"));
        interfacePoint.setAttribute("Angle321",interfaceDataElement.attribute("Angle321"));
        subModel.appendChild(interfacePoint);
        setPlainText(mXmlDocument.toString());

        TLMInterfacePointInfo *pTLMInterfacePointInfo;
        pTLMInterfacePointInfo = new TLMInterfacePointInfo(subModel.attribute("Name"),"shaft3" , interfaceDataElement.attribute("name"));
        getModelWidget()->getDiagramGraphicsView()->getComponentObject(subModel.attribute("Name"))->addInterfacePoint(pTLMInterfacePointInfo);
      }
      interfaceDataElement = interfaceDataElement.nextSiblingElement();
    }
  }
}

/*!
  Checks whether the interface already exists in MetaModel or not.
  \param interfaceName - the name for the interface to check.
  \return true on success.
  */
bool MetaModelEditor::existInterfaceData(QString subModelName, QString interfaceName)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    if (subModel.attribute("Name").compare(subModelName) == 0) {
      QDomNodeList subModelChildren = subModel.childNodes();
      for (int j = 0 ; j < subModelChildren.size() ; j++) {
        QDomElement interfaceElement = subModelChildren.at(j).toElement();
        if (interfaceElement.tagName().compare("InterfacePoint") == 0 && interfaceElement.attribute("Name").compare(interfaceName)== 0) {
           return true;
        }
      }
      break;
    }
  }
  return false;
}

/*!
 * \brief MetaModelEditor::deleteSubModel
 * Delets a SubModel.
 * \param name
 * \return
 */
bool MetaModelEditor::deleteSubModel(QString name)
{
  QDomNodeList subModelList = mXmlDocument.elementsByTagName("SubModel");
  for (int i = 0 ; i < subModelList.size() ; i++) {
    QDomElement subModel = subModelList.at(i).toElement();
    if (subModel.attribute("Name").compare(name) == 0) {
      QDomElement subModels = getSubModelsElement();
      if (!subModels.isNull()) {
        subModels.removeChild(subModel);
        setPlainText(mXmlDocument.toString());
        return true;
      }
      break;
    }
  }
  return false;
}

/*!
 * \brief MetaModelEditor::deleteConnection
 * Delets a connection.
 * \param name
 * \return
 */
bool MetaModelEditor::deleteConnection(QString startSubModelName, QString endSubModelName)
{
  QDomNodeList connectionList = mXmlDocument.elementsByTagName("Connection");
  for (int i = 0 ; i < connectionList.size() ; i++) {
    QDomElement connection = connectionList.at(i).toElement();
    QString startName = connection.attribute("From");
    QString endName = connection.attribute("To");
    if (startName.compare(startSubModelName) == 0 && endName.compare(endSubModelName) == 0 ) {
      QDomElement connections = getConnectionsElement();
      if (!connections.isNull()) {
        connections.removeChild(connection);
        setPlainText(mXmlDocument.toString());
        return true;
      }
      break;
    }
  }
  return false;
}

/*!
 * \brief MetaModelEditor::getRotationMatrix
 * \param rotation
 * \return
 */
QGenericMatrix<3,3, double> MetaModelEditor::getRotationMatrix(QGenericMatrix<3,1,double> rotation)
{
  double alpha = rotation(0,0);
  double beta = rotation(0,1);
  double gamma = rotation(0,2);

  //Compute rotational matrix around x-axis
  double Rx_data[9];
  Rx_data[0] = 1;             Rx_data[1] = 0;             Rx_data[2] = 0;
  Rx_data[3] = 0;             Rx_data[4] = cos(alpha);    Rx_data[5] = -sin(alpha);
  Rx_data[6] = 0;             Rx_data[7] = sin(alpha);    Rx_data[8] = cos(alpha);
  QGenericMatrix<3,3,double> Rx(Rx_data);

  //Compute rotational matrix around y-axis
  double Ry_data[9];
  Ry_data[0] = cos(beta);     Ry_data[1] = 0;             Ry_data[2] = sin(beta);
  Ry_data[3] = 0;             Ry_data[4] = 1;             Ry_data[5] = 0;
  Ry_data[6] = -sin(beta);    Ry_data[7] = 0;             Ry_data[8] = cos(beta);

  QGenericMatrix<3,3,double> Ry(Ry_data);

  //Compute rotational matrix around z-axis
  double Rz_data[9];
  Rz_data[0] = cos(gamma);    Rz_data[1] = -sin(gamma);   Rz_data[2] = 0;
  Rz_data[3] = sin(gamma);    Rz_data[4] = cos(gamma);    Rz_data[5] = 0;
  Rz_data[6] = 0;             Rz_data[7] = 0;             Rz_data[8] = 1;
  QGenericMatrix<3,3,double> Rz(Rz_data);


  //Compute complete rotational matrix
  QGenericMatrix<3,3,double> R = Rx*Ry*Rz;

  return R;
}

/*!
 * \brief MetaModelEditor::alignInterfaces
 * \param fromSubModel
 * \param toSubModel
 */
void MetaModelEditor::alignInterfaces(QString fromSubModel, QString toSubModel)
{
  //Extract submodel and interface names
  QString model1 = fromSubModel.split(".").at(0);
  QString interface1 = fromSubModel.split(".").at(1);
  QString model2 = toSubModel.split(".").at(0);
  QString interface2 = toSubModel.split(".").at(1);

  //Read positions and rotations from XML
  QDomElement subModelElement1;
  QString x1_c1_r_x1_str, x1_c1_phi_x1_str, x2_c2_r_x2_str, x2_c2_phi_x2_str;
  QString cg_x1_phi_cg_str, cg_x2_phi_cg_str, cg_x1_r_cg_str, cg_x2_r_cg_str;
  QDomElement modelElement = mXmlDocument.firstChildElement("Model");
  if(!modelElement.isNull()) {
    QDomElement subModelsElement = modelElement.firstChildElement("SubModels");
    if(!subModelsElement.isNull()) {
      QDomElement subModelElement = subModelsElement.firstChildElement("SubModel");
      while(!subModelElement.isNull()) {
        if(subModelElement.attribute("Name").compare(model1) == 0) {
          cg_x1_r_cg_str = subModelElement.attribute("Position");
          cg_x1_phi_cg_str = subModelElement.attribute("Angle321");
          subModelElement1 = subModelElement;     //Store this element for writing back data after transformation
        }
        else if(subModelElement.attribute("Name").compare(model2) == 0) {
          cg_x2_r_cg_str = subModelElement.attribute("Position");
          cg_x2_phi_cg_str = subModelElement.attribute("Angle321");
        }
        QDomElement interfaceElement = subModelElement.firstChildElement("InterfacePoint");
        while(!interfaceElement.isNull()) {
          if(subModelElement.attribute("Name").compare(model1) == 0 &&
             interfaceElement.attribute("Name").compare(interface1) == 0) {
            x1_c1_r_x1_str = interfaceElement.attribute("Position");
            x1_c1_phi_x1_str = interfaceElement.attribute("Angle321");
          }
          else if(subModelElement.attribute("Name").compare(model2) == 0 &&
                  interfaceElement.attribute("Name").compare(interface2) == 0) {
            x2_c2_r_x2_str = interfaceElement.attribute("Position");
            x2_c2_phi_x2_str = interfaceElement.attribute("Angle321");
          }
          interfaceElement = interfaceElement.nextSiblingElement("InterfacePoint");
        }
        subModelElement = subModelElement.nextSiblingElement("SubModel");
      }
    }
  }

  //Assert that all rotations and positions were found (do something smarter?)
  if(cg_x1_phi_cg_str.isEmpty() ||
     cg_x2_phi_cg_str.isEmpty() ||
     cg_x1_r_cg_str.isEmpty() ||
     cg_x2_r_cg_str.isEmpty() ||
     x1_c1_r_x1_str.isEmpty() ||
     x1_c1_phi_x1_str.isEmpty() ||
     x2_c2_r_x2_str.isEmpty() ||
     x2_c2_phi_x2_str.isEmpty())
  {
      QString msg = "Interface coordinates does not exist in xml";
      mpMainWindow->getMessagesWidget()->addGUIMessage(MessageItem(MessageItem::MetaModel, "",false,0,0,0,0,msg,Helper::scriptingKind,Helper::errorLevel));
      return;
  }

  //Convert from strings to arrays
  double cg_x1_phi_cg[3],cg_x2_phi_cg[3],x1_c1_phi_x1[3],x2_c2_phi_x2[3];
  double cg_x1_r_cg[3],cg_x2_r_cg[3],x1_c1_r_x1[3],x2_c2_r_x2[3];

  cg_x1_phi_cg[0] = cg_x1_phi_cg_str.split(",")[0].toDouble();
  cg_x1_phi_cg[1] = cg_x1_phi_cg_str.split(",")[1].toDouble();
  cg_x1_phi_cg[2] = cg_x1_phi_cg_str.split(",")[2].toDouble();

  cg_x2_phi_cg[0] = cg_x2_phi_cg_str.split(",")[0].toDouble();
  cg_x2_phi_cg[1] = cg_x2_phi_cg_str.split(",")[1].toDouble();
  cg_x2_phi_cg[2] = cg_x2_phi_cg_str.split(",")[2].toDouble();

  x1_c1_phi_x1[0] = x1_c1_phi_x1_str.split(",")[0].toDouble();
  x1_c1_phi_x1[1] = x1_c1_phi_x1_str.split(",")[1].toDouble();
  x1_c1_phi_x1[2] = x1_c1_phi_x1_str.split(",")[2].toDouble();

  x2_c2_phi_x2[0] = x2_c2_phi_x2_str.split(",")[0].toDouble();
  x2_c2_phi_x2[1] = x2_c2_phi_x2_str.split(",")[1].toDouble();
  x2_c2_phi_x2[2] = x2_c2_phi_x2_str.split(",")[2].toDouble();

  cg_x1_r_cg[0] = cg_x1_r_cg_str.split(",")[0].toDouble();
  cg_x1_r_cg[1] = cg_x1_r_cg_str.split(",")[1].toDouble();
  cg_x1_r_cg[2] = cg_x1_r_cg_str.split(",")[2].toDouble();

  cg_x2_r_cg[0] = cg_x2_r_cg_str.split(",")[0].toDouble();
  cg_x2_r_cg[1] = cg_x2_r_cg_str.split(",")[1].toDouble();
  cg_x2_r_cg[2] = cg_x2_r_cg_str.split(",")[2].toDouble();

  x1_c1_r_x1[0] = x1_c1_r_x1_str.split(",")[0].toDouble();
  x1_c1_r_x1[1] = x1_c1_r_x1_str.split(",")[1].toDouble();
  x1_c1_r_x1[2] = x1_c1_r_x1_str.split(",")[2].toDouble();

  x2_c2_r_x2[0] = x2_c2_r_x2_str.split(",")[0].toDouble();
  x2_c2_r_x2[1] = x2_c2_r_x2_str.split(",")[1].toDouble();
  x2_c2_r_x2[2] = x2_c2_r_x2_str.split(",")[2].toDouble();

  //Convert from arrays to Qt matrices
  QGenericMatrix<3,1,double> CG_X1_PHI_CG(cg_x1_phi_cg);  //Rotation of X1 relative to CG expressed in CG
  QGenericMatrix<3,1,double> CG_X2_PHI_CG(cg_x2_phi_cg);  //Rotation of X2 relative to CG expressed in CG
  QGenericMatrix<3,1,double> X1_C1_PHI_X1(x1_c1_phi_x1);  //Rotation of C1 relative to X1 expressed in X1
  QGenericMatrix<3,1,double> X2_C2_PHI_X2(x2_c2_phi_x2);  //Rotation of C2 relative to X2 expressed in X2
  QGenericMatrix<3,1,double> CG_X1_R_CG(cg_x1_r_cg);      //Position of X1 relative to CG expressed in CG
  QGenericMatrix<3,1,double> CG_X2_R_CG(cg_x2_r_cg);      //Position of X2 relative to CG expressed in CG
  QGenericMatrix<3,1,double> X1_C1_R_X1(x1_c1_r_x1);      //Position of C1 relative to X1 expressed in X1
  QGenericMatrix<3,1,double> X2_C2_R_X2(x2_c2_r_x2);      //Position of C2 relative to X2 expressed in X2

  QGenericMatrix<3,3,double> R_X2_C2, R_CG_X1, R_CG_X2, R_CG_C2, R_X1_C1;

  //Equations from BEAST
  R_X2_C2 = getRotationMatrix(X2_C2_PHI_X2);    //Rotation matrix between X2 and C2
  R_CG_X2 = getRotationMatrix(CG_X2_PHI_CG);    //Rotation matrix between CG and X2
  R_CG_C2 = R_X2_C2*R_CG_X2;                       //Rotation matrix between CG and C2

  R_X1_C1 = getRotationMatrix(X1_C1_PHI_X1);    //Rotation matrix between X1 and C1
  R_CG_X1 = R_X1_C1.transposed()*R_CG_C2;          //New rotation matrix between CG and X1

  //Extract angles from rotation matrix
  CG_X1_PHI_CG(0,0) = atan2(R_CG_X1(2,1),R_CG_X1(2,2));
  CG_X1_PHI_CG(0,1) = atan2(-R_CG_X1(2,0),sqrt(R_CG_X1(2,1)*R_CG_X1(2,1) + R_CG_X1(2,2)*R_CG_X1(2,2)));
  CG_X1_PHI_CG(0,2) = atan2(R_CG_X1(1,0),R_CG_X1(0,0));

  //New position of X1 relative to CG
  CG_X1_R_CG = CG_X2_R_CG + X2_C2_R_X2*R_CG_X2 - X1_C1_R_X1*R_CG_X1;

  //Write back new rotation and position to XML
  cg_x1_r_cg_str = QString("%1,%2,%3").arg(CG_X1_R_CG(0,0)).arg(CG_X1_R_CG(0,1)).arg(CG_X1_R_CG(0,2));
  subModelElement1.setAttribute("Position", cg_x1_r_cg_str);
  cg_x1_phi_cg_str = QString("%1,%2,%3").arg(CG_X1_PHI_CG(0,0)).arg(CG_X1_PHI_CG(0,1)).arg(CG_X1_PHI_CG(0,2));
  subModelElement1.setAttribute("Angle321", cg_x1_phi_cg_str);
  setPlainText(mXmlDocument.toString());
}

/*!
 * \brief MetaModelEditor::showContextMenu
 * Create a context menu.
 * \param point
 */
void MetaModelEditor::showContextMenu(QPoint point)
{
  QMenu *pMenu = createStandardContextMenu();
  pMenu->exec(mapToGlobal(point));
  delete pMenu;
}

/*!
 * \brief MetaModelEditor::setPlainText
 * Reimplementation of QPlainTextEdit::setPlainText method.
 * Makes sure we dont update if the passed text is same.
 * \param text the string to set.
 */
void MetaModelEditor::setPlainText(const QString &text)
{
  if (text != mpPlainTextEdit->toPlainText()) {
    mForceSetPlainText = true;
    mXmlDocument.setContent(text);
    // use the text from mXmlDocument so that we can map error to line numbers. We don't care about users formatting in the file.
    mpPlainTextEdit->setPlainText(mXmlDocument.toString());
    mForceSetPlainText = false;
    mLastValidText = text;
  }
}

/*!
 * \brief MetaModelEditor::contentsHasChanged
 * Slot activated when MetaModelEditor's QTextDocument contentsChanged SIGNAL is raised.\n
 * Sets the model as modified so that user knows that his current metamodel is not saved.
 * \param position
 * \param charsRemoved
 * \param charsAdded
 */
void MetaModelEditor::contentsHasChanged(int position, int charsRemoved, int charsAdded)
{
  Q_UNUSED(position);
  if (mpModelWidget->isVisible()) {
    if (charsRemoved == 0 && charsAdded == 0) {
      return;
    }
    /* if user is changing the read only file. */
    if (mpModelWidget->getLibraryTreeItem()->isReadOnly() && !mForceSetPlainText) {
      /* if user is changing the read-only class. */
      mpMainWindow->getInfoBar()->showMessage(tr("<b>Warning: </b>You are changing a read-only class."));
    } else {
      /* if user is changing, the normal file. */
      if (!mForceSetPlainText) {
        mpModelWidget->setWindowTitle(QString(mpModelWidget->getLibraryTreeItem()->getName()).append("*"));
        mpModelWidget->getLibraryTreeItem()->setIsSaved(false);
        mpMainWindow->getLibraryWidget()->getLibraryTreeModel()->updateLibraryTreeItem(mpModelWidget->getLibraryTreeItem());
        mTextChanged = true;
      }
    }
  }
}

//! @class MetaModelHighlighter
//! @brief A syntax highlighter for MetaModelEditor.

//! Constructor
MetaModelHighlighter::MetaModelHighlighter(MetaModelEditorPage *pMetaModelEditorPage, QPlainTextEdit *pPlainTextEdit)
    : QSyntaxHighlighter(pPlainTextEdit->document())
{
  mpMetaModelEditorPage = pMetaModelEditorPage;
  mpPlainTextEdit = pPlainTextEdit;
  initializeSettings();
}

//! Initialized the syntax highlighter with default values.
void MetaModelHighlighter::initializeSettings()
{
  QFont font;
  font.setFamily(mpMetaModelEditorPage->getOptionsDialog()->getTextEditorPage()->getFontFamilyComboBox()->currentFont().family());
  font.setPointSizeF(mpMetaModelEditorPage->getOptionsDialog()->getTextEditorPage()->getFontSizeSpinBox()->value());
  mpPlainTextEdit->document()->setDefaultFont(font);
  mpPlainTextEdit->setTabStopWidth(mpMetaModelEditorPage->getOptionsDialog()->getTextEditorPage()->getTabSizeSpinBox()->value() * QFontMetrics(font).width(QLatin1Char(' ')));
  // set color highlighting
  mHighlightingRules.clear();
  HighlightingRule rule;
  mTextFormat.setForeground(mpMetaModelEditorPage->getTextRuleColor());
  mTagFormat.setForeground(mpMetaModelEditorPage->getTagRuleColor());
  mElementFormat.setForeground(mpMetaModelEditorPage->getElementRuleColor());
  mCommentFormat.setForeground(mpMetaModelEditorPage->getCommentRuleColor());
  mQuotationFormat.setForeground(QColor(mpMetaModelEditorPage->getQuotesRuleColor()));

  rule.mPattern = QRegExp("\\b[A-Za-z_][A-Za-z0-9_]*");
  rule.mFormat = mTextFormat;
  mHighlightingRules.append(rule);

  // MetaModel Tags
  QStringList metaModelTags;
  metaModelTags << "<\\?"
                << "<"
                << "</"
                << "\\?>"
                << ">"
                << "/>";
  foreach (const QString &metaModelTag, metaModelTags) {
    rule.mPattern = QRegExp(metaModelTag);
    rule.mFormat = mTagFormat;
    mHighlightingRules.append(rule);
  }

 // MetaModel Elements
  QStringList elementPatterns;
  elementPatterns << "\\bxml\\b"
                  << "\\bModel\\b"
                  << "\\bAnnotations\\b"
                  << "\\bAnnotation\\b"
                  << "\\bSubModels\\b"
                  << "\\bSubModel\\b"
                  << "\\bInterfacePoint\\b"
                  << "\\bConnections\\b"
                  << "\\bConnection\\b"
                  << "\\bLines\\b"
                  << "\\bLine\\b"
                  << "\\bSimulationParams\\b";
  foreach (const QString &elementPattern, elementPatterns)
  {
    rule.mPattern = QRegExp(elementPattern);
    rule.mFormat = mElementFormat;
    mHighlightingRules.append(rule);
  }

  // MetaModel Comments
  mCommentStartExpression = QRegExp("<!--");
  mCommentEndExpression = QRegExp("-->");
}

/*!
  Highlights the multilines text.\n
  Quoted text.
  */
void MetaModelHighlighter::highlightMultiLine(const QString &text)
{
  int index = 0, startIndex = 0;
  int blockState = previousBlockState();
  // fprintf(stderr, "%s with blockState %d\n", text.toStdString().c_str(), blockState);

  while (index < text.length())
  {
    switch (blockState) {
      case 2:
        if (text[index] == '-' &&
            index+1<text.length() && text[index+1] == '-' &&
            index+2<text.length() && text[index+2] == '>') {
          index = index+2;
          setFormat(startIndex, index-startIndex+1, mCommentFormat);
          blockState = 0;
        }
        break;
      case 3:
        if (text[index] == '\\') {
          index++;
        } else if (text[index] == '"') {
          setFormat(startIndex, index-startIndex+1, mQuotationFormat);
          blockState = 0;
        }
        break;
      default:
        if (text[index] == '<' &&
            index+1<text.length() && text[index+1] == '!' &&
            index+2<text.length() && text[index+2] == '-' &&
            index+3<text.length() && text[index+3] == '-') {
          startIndex = index;
          blockState = 2;
        } else if (text[index] == '"') {
          startIndex = index;
          blockState = 3;
        }
    }
    index++;
  }
  switch (blockState) {
    case 2:
      setFormat(startIndex, text.length()-startIndex, mCommentFormat);
      setCurrentBlockState(2);
      break;
    case 3:
      setFormat(startIndex, text.length()-startIndex, mQuotationFormat);
      setCurrentBlockState(3);
      break;
  }
}

//! Reimplementation of QSyntaxHighlighter::highlightBlock
void MetaModelHighlighter::highlightBlock(const QString &text)
{
  /* Only highlight the text if user has enabled the syntax highlighting */
  if (!mpMetaModelEditorPage->getOptionsDialog()->getTextEditorPage()->getSyntaxHighlightingCheckbox()->isChecked()) {
    return;
  }
  setCurrentBlockState(0);
  setFormat(0, text.length(), mpMetaModelEditorPage->getTextRuleColor());
  foreach (const HighlightingRule &rule, mHighlightingRules)
  {
    QRegExp expression(rule.mPattern);
    int index = expression.indexIn(text);
    while (index >= 0)
    {
      int length = expression.matchedLength();
      setFormat(index, length, rule.mFormat);
      index = expression.indexIn(text, index + length);
    }
  }
  highlightMultiLine(text);
}

//! Slot activated whenever ModelicaEditor text settings changes.
void MetaModelHighlighter::settingsChanged()
{
  initializeSettings();
  rehighlight();
}
