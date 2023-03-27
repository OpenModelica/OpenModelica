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

#ifndef ANIMATIONUTIL_H
#define ANIMATIONUTIL_H

#include <QFileInfo>
#include <QString>

#include <string>

#include "MainWindow.h"
#include "OMC/OMCProxy.h"
#include "Util/Helper.h"
#include "Modeling/MessagesWidget.h"

enum class VisType
{
  NONE = 0,
  FMU = 1,
  FMU_REMOTE = 2,
  MAT = 3,
  MAT_REMOTE = 4,
  CSV = 5,
  CSV_REMOTE = 6
};

/*!
 * \brief isFMU
 * checks of the file is of type FMU
 */
inline bool isFMU(const std::string& fileIn){
  std::size_t fmu = fileIn.find(".fmu");
  return (fmu != std::string::npos);
}

/*!
 * \brief isMAT
 * checks of the file is of type mat
 */
inline bool isMAT(const std::string& fileIn){
  std::size_t mat = fileIn.find(".mat");
  return (mat != std::string::npos);
}

/*!
 * \brief isCSV
 * checks of the file is of type csv
 */
inline bool isCSV(const std::string& fileIn){
  std::size_t csv = fileIn.find(".csv");
  return (csv != std::string::npos);
}

/*!
 * \brief assembleXMLFileName
 * constructs the name of the corresponding xml file
 */
inline std::string assembleXMLFileName(const std::string& modelFile, const std::string& path){
  QFileInfo fi(modelFile.c_str());
  QString suf = fi.suffix();
  if (!(suf.compare("mat") || suf.compare("csv") || suf.compare("fmu"))) {
    MessagesWidget::instance()->addGUIMessage(MessageItem(MessageItem::Modelica, QObject::tr("This file extension is not supported."),
                                                          Helper::scriptingKind, Helper::errorLevel));
  }
  QString base = fi.completeBaseName();
  if (base.endsWith("_res")){
	  base.remove(base.length()-4,4);
  }
  // Construct XML file name
  std::string xmlFileName = path + base.toStdString() + "_visual.xml";
  return xmlFileName;
}

/*! \brief Checks if the file is accessible. */
inline bool fileExists(const std::string& file)
{
  QFileInfo fileInfo(file.c_str());
  return fileInfo.exists();
}

/*!
 * \brief checkForXMLFile
 * checks if the xml file is available
 */
inline bool checkForXMLFile(const std::string& modelFile, const std::string& path){
  // Cut off prefix [fmu|mat]
  std::string xmlFileName = assembleXMLFileName(modelFile, path);
  return fileExists(xmlFileName);
}

/*!
 * \brief Gets the filename of the CAD file
 */
inline std::string extractCADFilename(const std::string& typeName)
{
  QString str(typeName.c_str());
  if (str.startsWith("modelica://")) {
    const QString absoluteFileName = MainWindow::instance()->getOMCProxy()->uriToFilename(str);
    return absoluteFileName.toStdString();
  } else {
    const std::string fileKey = "file://";
    return typeName.substr(fileKey.length(), typeName.length());
  }
}

/*!
 * \brief Checks if the type is a CAD file
 */
inline bool isCADFile(const std::string& typeName)
{
  return ((typeName.size() >= 12 && std::string(typeName.begin(), typeName.begin() + 11) == "modelica://") ||
          (typeName.size() >=  8 && std::string(typeName.begin(), typeName.begin() +  7) == "file://"));
}

inline bool isDXFFile(const std::string& fileName)
{
  return fileName.substr(fileName.size() - 3) == "dxf";
}

inline bool isSTLFile(const std::string& fileName)
{
  return fileName.substr(fileName.size() - 3) == "stl";
}

inline bool isOBJFile(const std::string& fileName)
{
  return fileName.substr(fileName.size() - 3) == "obj";
}

inline bool is3DSFile(const std::string& fileName)
{
  return fileName.substr(fileName.size() - 3) == "3ds";
}

inline bool isDXFType(const std::string& type)
{
  return type == "DXF";
}

inline bool isSTLType(const std::string& type)
{
  return type == "STL";
}

inline bool isOBJType(const std::string& type)
{
  return type == "OBJ";
}

inline bool is3DSType(const std::string& type)
{
  return type == "3DS";
}

inline bool isCADType(const std::string& type)
{
  return isDXFType(type) || isSTLType(type) || isOBJType(type) || is3DSType(type);
}

inline bool isSimpleCADType(const std::string& type)
{
  return isDXFType(type) || isSTLType(type);
}

inline bool isAdvancedCADType(const std::string& type)
{
  return isOBJType(type) || is3DSType(type);
}

inline const char* boolToString(bool b)
{
    return b ? "true" : "false";
}

#endif //ANIMATIONUTIL_H
