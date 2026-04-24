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
  void initializeVisAttributes(const double time) override;
  void simulate(TimeManager& omvm) override;
  double simulateStep(const double time);
  void updateSystem();
  void updateScene(const double time) override;
  void updateVisualizerAttribute(VisualizerAttribute& attr, const double time) override;
  void updateVisualizerAttributeFMU(VisualizerAttribute& attr);
  unsigned int getFmuVariableReferenceForVisualizerAttribute(VisualizerAttribute& attr) override;
  unsigned int getFmuVariableReferenceForVisualizerAttributeFMU(VisualizerAttribute& attr);
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
