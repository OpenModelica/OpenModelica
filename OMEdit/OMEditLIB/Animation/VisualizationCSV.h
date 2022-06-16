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

#ifndef VISUALIZATIONCSV_H
#define VISUALIZATIONCSV_H

#include "Visualization.h"
#include "util/read_csv.h"

class VisualizationCSV : public VisualizationAbstract
{
public:
  VisualizationCSV() = delete;
  VisualizationCSV(const std::string& fileName, const std::string& path);
  ~VisualizationCSV();
  VisualizationCSV(const VisualizationCSV& omvm) = delete;
  VisualizationCSV& operator=(const VisualizationCSV& omvm) = delete;
  void initData() override;
  void initializeVisAttributes(const double time = -1.0) override;
  void readCSV(const std::string& modelFile, const std::string& path);
  void simulate(TimeManager& omvm) override {Q_UNUSED(omvm);}
  void updateVisAttributes(const double time) override;
  void updateScene(const double time) override;
  void updateVisualizerAttributeCSV(VisualizerAttribute& attr, double time);
  double omcGetVarValue(const char* varName, double time);
private:
  csv_data *mpCSVData;
};

#endif // VISUALIZATIONCSV_H
