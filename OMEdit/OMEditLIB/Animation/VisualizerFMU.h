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


#ifndef VISUALIZERFMU_H
#define VISUALIZERFMU_H

#include "Visualizer.h"
#include "FMUWrapper.h"
#include "Shapes.h"
#include "TimeManager.h"

class VisualizerFMU : public VisualizerAbstract
{
 public:
  VisualizerFMU() = delete;
  VisualizerFMU(const std::string& modelFile, const std::string& path);
  ~VisualizerFMU();
  VisualizerFMU(const VisualizerFMU& omvf) = delete;
  VisualizerFMU& operator=(const VisualizerFMU& omvf) = delete;

  void allocateContext(const std::string& modelFile, const std::string& path);
  void loadFMU(const std::string& modelFile, const std::string& path);
  void initData() override;
  void initializeVisAttributes(const double time = 0.0) override;
  unsigned int getVarReferencesForObjectAttribute(ShapeObjectAttribute* attr);
  int setVarReferencesInVisAttributes();
  void simulate(TimeManager& omvm) override;
  double simulateStep(const double time);
  void updateSystem();
  void updateVisAttributes(const double time) override;
  void updateScene(const double time = 0.0) override;
  void updateObjectAttributeFMU(ShapeObjectAttribute* attr, FMUWrapperAbstract* fmuWrapper);
  void setSimulationSettings(double stepsize, Solver solver, bool iterateEvents);
  FMUWrapperAbstract* getFMU();

 private:
  std::shared_ptr<fmi_import_context_t> mpContext;
  jm_callbacks mCallbacks;
  fmi_version_enu_t mVersion;
  FMUWrapperAbstract* mpFMU;
  std::shared_ptr<SimSettingsFMU> mpSimSettings;
};


#endif // end VISUALIZERFMU_H
