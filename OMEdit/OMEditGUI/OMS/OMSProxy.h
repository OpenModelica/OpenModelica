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
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef OMSPROXY_H
#define OMSPROXY_H

#include "OMSimulator.h"

#include <QObject>

class OMSProxy : public QObject
{
  Q_OBJECT
private:
  // the only class that is allowed to create and destroy
  friend class MainWindow;

  static void create();
  static void destroy();
  OMSProxy();

  static OMSProxy *mpInstance;
public:
  static OMSProxy* instance() {return mpInstance;}
  bool statusToBool(oms_status_enu_t status);

  bool newFMIModel(QString ident);
  bool newTLMModel(QString ident);
  bool unloadModel(QString ident);
  bool addFMU(QString modelIdent, QString fmuPath, QString fmuIdent);
  bool deleteSubModel(QString modelIdent, QString subModelIdent);
  bool renameModel(QString identOld, QString identNew);
  bool loadModel(QString filename, QString *pModelName);
  bool saveModel(QString filename, QString ident);
  bool getElement(QString cref, oms_element_t **pElement);
  bool setElementGeometry(QString cref, const ssd_element_geometry_t *pGeometry);
  bool getElements(QString cref, oms_element_t ***pElements);
  bool getFMUPath(QString cref, QString *pFmuPath);
  bool getConnections(QString cref, oms_connection_t ***pConnections);
  bool addConnection(QString cref, QString conA, QString conB);
  bool deleteConnection(QString cref, QString conA, QString conB);
  bool updateConnection(QString cref, QString conA, QString conB, const oms_connection_t *pConnection);
  void setLoggingLevel(int logLevel);
  void setLogFile(QString filename);
  void setTempDirectory(QString path);
  void setWorkingDirectory(QString path);
  bool getRealParameter(QString signal, double *pValue);
  bool setRealParameter(const char* signal, double value);
};

#endif // OMSPROXY_H
