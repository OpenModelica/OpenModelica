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

#ifndef VISUALIZERMAT_H
#define VISUALIZERMAT_H

#include "Visualizer.h"
#include "util/read_matlab4.h"

class VisualizerMAT : public VisualizerAbstract
{
 public:
  VisualizerMAT() = delete;
  VisualizerMAT(const std::string& fileName, const std::string& path);
  ~VisualizerMAT();
  VisualizerMAT(const VisualizerMAT& omvm) = delete;
  VisualizerMAT& operator=(const VisualizerMAT& omvm) = delete;
  void initData() override;
  void initializeVisAttributes(const double time = -1.0) override;
  void readMat(const std::string& modelFile, const std::string& path);
  void setSimulationSettings(const UserSimSettingsMAT& simSetMAT);
  void simulate(TimeManager& omvm) override {Q_UNUSED(omvm);}
  void updateVisAttributes(const double time) override;
  void updateScene(const double time) override;
  void updateObjectAttributeMAT(ShapeObjectAttribute* attr, double time, ModelicaMatReader* reader);
  double omcGetVarValue(ModelicaMatReader* reader, const char* varName, double time);
private:
  ModelicaMatReader _matReader;
};

#endif // end VISUALIZERMAT_H
