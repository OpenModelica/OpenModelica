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

#ifndef VISUALIZATIONFMU_H
#define VISUALIZATIONFMU_H

#include "Visualization.h"
#include "FMUWrapper.h"

class VisualizationFMU : public VisualizationAbstract
{
public:
  VisualizationFMU() = delete;
  VisualizationFMU(const std::string& modelFile, const std::string& path);
  ~VisualizationFMU();
  VisualizationFMU(const VisualizationFMU& omvf) = delete;
  VisualizationFMU& operator=(const VisualizationFMU& omvf) = delete;
  void allocateContext(const std::string& modelFile, const std::string& path);
  void loadFMU(const std::string& modelFile, const std::string& path);
  void initData() override;
  void initializeVisAttributes(const double time = 0.0) override;
  unsigned int getVariableReferenceForVisualizerAttribute(VisualizerAttribute& attr);
  int setVarReferencesInVisAttributes();
  void simulate(TimeManager& omvm) override;
  double simulateStep(const double time);
  void updateSystem();
  void updateVisAttributes(const double time) override;
  void updateScene(const double time = 0.0) override;
  void updateVisualizerAttributeFMU(VisualizerAttribute& attr);
  void setSimulationSettings(double stepsize, Solver solver, bool iterateEvents);
  FMUWrapperAbstract* getFMU();
private:
  std::shared_ptr<fmi_import_context_t> mpContext;
  jm_callbacks mCallbacks;
  fmi_version_enu_t mVersion;
  FMUWrapperAbstract* mpFMU;
  std::shared_ptr<SimSettingsFMU> mpSimSettings;
};

#endif // VISUALIZATIONFMU_H
