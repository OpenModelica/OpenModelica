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

#ifndef SIMULATIONOUTPUTHANDLER_H
#define SIMULATIONOUTPUTHANDLER_H

#include "Simulation/SimulationOutputWidget.h"

#include <QXmlStreamReader>

class SimulationMessage
{
public:
  QString mStream;
  StringHandler::SimulationMessageType mType;
  QString mText;
  int mLevel;
  QString mIndex;
  QString mDeweyId;
  QList<SimulationMessage*> mChildren;
  SimulationMessage* mpParentSimulationMessage;
public:
  SimulationMessage(SimulationMessage *pParentSimulationMessage = 0)
    : mpParentSimulationMessage(pParentSimulationMessage)
  {mStream = ""; mType = StringHandler::Unknown; mText = ""; mIndex = ""; mDeweyId="";}
  void setParent(SimulationMessage *pParentSimulationMessage) {mpParentSimulationMessage = pParentSimulationMessage;}
  SimulationMessage *parent() {return mpParentSimulationMessage;}
  SimulationMessage *child(int row) {return mChildren.value(row);}
  QList<SimulationMessage*> children() const {return mChildren;}
  void insertChild(int position, SimulationMessage *pSimulationMessage) {mChildren.insert(position, pSimulationMessage);}
  int row() const
  {
    if (mpParentSimulationMessage) {
      return mpParentSimulationMessage->mChildren.indexOf(const_cast<SimulationMessage*>(this));
    } else {
      return 0;
    }
  }
};

class SimulationMessageModel : public QAbstractItemModel
{
  Q_OBJECT
public:
  SimulationMessageModel(SimulationOutputWidget *pSimulationOutputWidget, QObject *pParent = 0);
  virtual QModelIndex index(int row, int column, const QModelIndex &parent) const override;
  virtual QModelIndex parent(const QModelIndex &child) const override;
  virtual int rowCount(const QModelIndex &parent) const override;
  virtual int columnCount(const QModelIndex &parent) const override;
  virtual QVariant data(const QModelIndex &index, int role) const override;
  SimulationMessage* getRootSimulationMessage() {return mpRootSimulationMessage;}
  int getDepth(const QModelIndex &index) const;
  void insertSimulationMessage(SimulationMessage *pSimulationMessage);
  void callLayoutChanged();
private:
  SimulationOutputWidget *mpSimulationOutputWidget;
  SimulationMessage* mpRootSimulationMessage;
  QModelIndexList mSelectedRowsList;

  QModelIndex simulationMessageIndexHelper(const SimulationMessage *pSimulationMessage, const SimulationMessage *pParentSimulationMessage, const QModelIndex &parentIndex) const;
};

class SimulationOutputHandler
{
private:
  SimulationOutputWidget *mpSimulationOutputWidget;
  int mLevel;
  int mNumberOfBytes;
  bool mShownDisplayLimitReachedMessage;
  SimulationMessage* mpSimulationMessage;
  QMap<int, SimulationMessage*> mSimulationMessagesLevelMap;
  SimulationMessageModel *mpSimulationMessageModel;
  QXmlStreamReader mXmlStreamReader;
  FILE *mpSimulationLogFile;

  bool isMaximumDisplayLimitReached() const;
  void endElement();
  void writeSimulationMessage(SimulationMessage *pSimulationMessage, SimulationOutputWidget *pSimulationOutputWidget = nullptr);
public:
  SimulationOutputHandler(SimulationOutputWidget *pSimulationOutputWidget, QString simulationOutput);
  ~SimulationOutputHandler();
  SimulationMessageModel* getSimulationMessageModel() {return mpSimulationMessageModel;}
  void parseSimulationOutput(const QString &output);
  void addSimulationMessage(SimulationMessage *pSimulationMessage);
  void simulationProcessFinished();
};

#endif // SIMULATIONOUTPUTHANDLER_H
