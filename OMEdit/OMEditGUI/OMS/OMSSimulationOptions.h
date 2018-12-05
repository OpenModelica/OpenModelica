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

#ifndef OMSSIMULATIONOPTIONS_H
#define OMSSIMULATIONOPTIONS_H

#include <QString>
#include <QStringList>

class OMSSimulationOptions
{
public:
  OMSSimulationOptions() {
    setIsValid(false);
    setModelName("");
    setStartTime(0);
    setStopTime(1);
    setWorkingDirectory("");
    setResultFileName("");
    setResultFileBufferSize(100);
  }

  void setIsValid(bool isValid) {mValid = isValid;}
  bool isValid() {return mValid;}
  void setModelName(QString className) {mModelName = className;}
  QString getModelName() {return mModelName;}
  void setStartTime(double startTime) {mStartTime = startTime;}
  double getStartTime() {return mStartTime;}
  void setStopTime(double stopTime) {mStopTime = stopTime;}
  double getStopTime() {return mStopTime;}
  void setWorkingDirectory(QString workingDirectory) {mWorkingDirectory = workingDirectory;}
  QString getWorkingDirectory() {return mWorkingDirectory;}
  void setResultFileName(QString fileName) {mResultFileName = fileName;}
  QString getResultFileName() {return mResultFileName;}
  int getResultFileBufferSize() const {return mResultFileBufferSize;}
  void setResultFileBufferSize(int bufferSize) {mResultFileBufferSize = bufferSize;}

private:
  bool mValid;
  QString mModelName;
  double mStartTime;
  double mStopTime;
  QString mWorkingDirectory;
  QString mResultFileName;
  int mResultFileBufferSize;
};

#endif // OMSSIMULATIONOPTIONS_H
