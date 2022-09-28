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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
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
 * @author Volker Waurich <volker.waurich@tu-dresden.de>
 */

#include "VisualizationMAT.h"

VisualizationMAT::VisualizationMAT(const std::string& modelFile, const std::string& path)
  : VisualizationAbstract(modelFile, path, VisType::MAT),
    _matReader()
{
}

/*!
 * \brief VisualizationMAT::~VisualizationMAT
 * Free the ModelicaMatReader
 */
VisualizationMAT::~VisualizationMAT()
{
  if (_matReader.file) {
    omc_free_matlab4_reader(&_matReader);
  }
}

void VisualizationMAT::initData()
{
  VisualizationAbstract::initData();
  readMat(mpOMVisualBase->getModelFile(), mpOMVisualBase->getPath());
  mpTimeManager->setStartTime(omc_matlab4_startTime(&_matReader));
  mpTimeManager->setEndTime(omc_matlab4_stopTime(&_matReader));
}

void VisualizationMAT::initializeVisAttributes(const double time)
{
  if (0.0 > time) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                          QObject::tr("Cannot load visualization attributes for time point < 0.0."),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
  updateVisAttributes(time);
}

void VisualizationMAT::readMat(const std::string& modelFile, const std::string& path)
{
  std::string resFileName = path + modelFile;     // + "_res.mat";

  // Check if the MAT file exists.
  if (!fileExists(resFileName))
  {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, QString(QObject::tr("Could not find MAT file %1."))
                                                          .arg(resFileName.c_str()),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
  else
  {
    // Read mat file.
    omc_new_matlab4_reader(resFileName.c_str(), &_matReader);
    //auto ret = omc_new_matlab4_reader(resFileName.c_str(), &_matReader);
    // Check return value.
//    if (0 != ret)
//    {
//      std::string msg(ret);
//      std::cout<<msg<<std::endl;
//    }
  }

  /*
     FILE * fileA = omc_fopen("allVArs.txt", "w+");
     omc_matlab4_print_all_vars(fileA, &matReader);
     fclose(fileA);
     */
}

void VisualizationMAT::setSimulationSettings(const UserSimSettingsMAT& simSetMAT)
{
  auto newVal = simSetMAT.speedup * mpTimeManager->getHVisual();
  mpTimeManager->setHVisual(newVal);
}

void VisualizationMAT::updateScene(const double time)
{
  mpTimeManager->updateTick();  //for real-time measurement
  double visTime = mpTimeManager->getRealTime();
  updateVisAttributes(time);
  mpTimeManager->updateTick();  //for real-time measurement
  visTime = mpTimeManager->getRealTime() - visTime;
  mpTimeManager->setRealTimeFactor(mpTimeManager->getHVisual() / visTime);
}

void VisualizationMAT::updateVisualizerAttribute(VisualizerAttribute& attr, const double time)
{
  updateVisualizerAttributeMAT(attr, time);
}

void VisualizationMAT::updateVisualizerAttributeMAT(VisualizerAttribute& attr, const double time)
{
  if (!attr.isConst) {
    attr.exp = omcGetVarValue(&_matReader, attr.cref.c_str(), time);
  }
}

double VisualizationMAT::omcGetVarValue(ModelicaMatReader* reader, const char* varName, const double time)
{
  double val = 0.0;
  ModelicaMatVariable_t* var = nullptr;
  var = omc_matlab4_find_var(reader, varName);
  if (var == nullptr) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica,
                                                          QString(QObject::tr("Did not get variable from result file. Variable name is %1."))
                                                          .arg(varName), Helper::scriptingKind, Helper::errorLevel));
  } else {
    omc_matlab4_val(&val, reader, var, time);
  }

  return val;
}
