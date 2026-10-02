/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/DataExchange/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>
#include <Core/DataExchange/XmlPropertyReader.h>
#include <expat.h>
#include <fstream>
#include <iostream>
#include <list>
#include <locale>
#include <optional>
#include <regex>
#include <sstream>
#include <type_traits>
#include <vector>

namespace {

struct XmlElement
{
  std::string name;
  std::map<std::string, std::string> attributes;
  std::list<XmlElement> children;

  const std::string* attribute(const std::string& key) const
  {
    std::map<std::string, std::string>::const_iterator it = attributes.find(key);
    return it == attributes.end() ? nullptr : &it->second;
  }

  const std::string& requiredAttribute(const std::string& key) const
  {
    const std::string* value = attribute(key);
    if (!value)
      throw std::runtime_error("missing attribute " + key + " of " + name);
    return *value;
  }

  const XmlElement& child(const std::string& childName) const
  {
    for (const XmlElement& c : children)
      if (c.name == childName)
        return c;
    throw std::runtime_error("missing element " + childName + " in " + name);
  }

  // The whole attribute has to parse as a T.
  template <class T>
  std::optional<T> attributeAs(const std::string& key) const
  {
    const std::string* str = attribute(key);
    if (!str)
      return std::nullopt;
    std::istringstream is(*str);
    is.imbue(std::locale::classic());
    T value;
    is >> value;
    if (is.fail()) {
      if constexpr (!std::is_same_v<T, bool>)
        return std::nullopt;
      is.clear();
      is.str(*str);
      is >> std::boolalpha >> value;
      if (is.fail())
        return std::nullopt;
    }
    is >> std::ws;
    if (!is.eof())
      return std::nullopt;
    return value;
  }
};

void XMLCALL startElement(void* userData, const XML_Char* name, const XML_Char** atts)
{
  std::vector<XmlElement*>& stack = *static_cast<std::vector<XmlElement*>*>(userData);
  stack.back()->children.emplace_back();
  XmlElement& e = stack.back()->children.back();
  e.name = name;
  for (int i = 0; atts[i]; i += 2)
    e.attributes[atts[i]] = atts[i + 1];
  stack.push_back(&e);
}

void XMLCALL endElement(void* userData, const XML_Char*)
{
  static_cast<std::vector<XmlElement*>*>(userData)->pop_back();
}

void readXml(std::istream& in, XmlElement& document)
{
  std::vector<XmlElement*> stack(1, &document);
  XML_Parser parser = XML_ParserCreate(NULL);
  XML_SetUserData(parser, &stack);
  XML_SetElementHandler(parser, startElement, endElement);
  std::vector<char> buf(65536);
  bool done = false;
  while (!done) {
    in.read(buf.data(), buf.size());
    done = in.gcount() < (std::streamsize)buf.size();
    if (XML_Parse(parser, buf.data(), (int)in.gcount(), done) == XML_STATUS_ERROR) {
      std::stringstream ss;
      ss << XML_ErrorString(XML_GetErrorCode(parser)) << " at line " << XML_GetCurrentLineNumber(parser);
      XML_ParserFree(parser);
      throw std::runtime_error(ss.str());
    }
  }
  XML_ParserFree(parser);
}

}

static std::string realToString(double value)
{
  std::ostringstream os;
  os.precision(17);
  os << value;
  return os.str();
}

// Offset in column-major storage of the element at the given row-major offset.
static int rowMajorToColumnMajor(const std::vector<int>& dims, int rowMajorOffset)
{
  std::vector<int> idx(dims.size());
  int rem = rowMajorOffset;
  for (int k = (int)dims.size() - 1; k >= 0; k--) { idx[k] = rem % dims[k]; rem /= dims[k]; }
  int off = 0, stride = 1;
  for (size_t k = 0; k < dims.size(); k++) { off += idx[k] * stride; stride *= dims[k]; }
  return off;
}

// Build the Modelica name of a scalar element of a column-major array, the
// storage order of the arrays of this runtime (StatArrayDimN/DynArrayDimN),
// e.g. arrayElementName("a", {2,3}, 4) -> "a[1,3]". Used to expose the
// elements of a non-scalarized array variable as individual result signals.
static std::string arrayElementName(const std::string& base, const std::vector<int>& dims, int linearOffset)
{
  std::vector<int> idx(dims.size());
  int rem = linearOffset;
  for (size_t k = 0; k < dims.size(); k++) { idx[k] = rem % dims[k]; rem /= dims[k]; }
  std::stringstream ss;
  ss << base << "[";
  for (size_t k = 0; k < idx.size(); k++) { if (k) ss << ","; ss << (idx[k] + 1); }
  ss << "]";
  return ss.str();
}

XmlPropertyReader::XmlPropertyReader(IGlobalSettings *globalSettings, std::string propertyFile)
  : IPropertyReader()
  ,_globalSettings(globalSettings)
  ,_propertyFile(globalSettings->getInputPath() + propertyFile)
  ,_isInitialized(false)
{
}
XmlPropertyReader::~XmlPropertyReader()
{
}

void XmlPropertyReader::readInitialValues(IContinuous& system, shared_ptr<ISimVars> sim_vars)
{
  std::ifstream file;
  file.open (_propertyFile.c_str(), std::ifstream::in);
  if (file.good())
  {
    double *realVars = sim_vars->getRealVarsVector();
    int *intVars = sim_vars->getIntVarsVector();
    bool *boolVars = sim_vars->getBoolVarsVector();
    string *stringVars = sim_vars->getStringVarsVector();
    double *derVars= sim_vars-> getDerStateVector();
    int refIdx = -1;
    std::optional<int> refIdxOpt;
    std::regex filterRegex(_globalSettings->getVariableFilter());
    EmitResults emitResults = _globalSettings->getEmitResults();
    try
    {
      XmlElement document;
      readXml(file, document);

      const XmlElement& modelDescription = document.child("ModelDescription");

      LOGGER_WRITE_BEGIN("Initialize start values:", LC_INIT, LL_DEBUG);
      for (const XmlElement& vars : modelDescription.child("ModelVariables").children)
      {
        if (vars.name == "ScalarVariable" || vars.name == "ArrayVariable")
        {
          refIdxOpt = vars.attributeAs<int>("valueReference");

          if (!refIdxOpt)
            continue;

          string name = vars.requiredAttribute("name");
          const string* descriptonOpt = vars.attribute("description");
          string descripton;
          if (descriptonOpt)
            descripton  = *descriptonOpt;

          refIdx = *refIdxOpt;
          std::string aliasInfo = vars.requiredAttribute("alias");
          std::string variabilityInfo = vars.requiredAttribute("variability");
          bool isParameter = (variabilityInfo.compare("parameter") == 0);
          //If a start value is given for the alias and the referred variable, skip the alias declaration
          bool isAlias = aliasInfo.compare("alias") == 0;
          bool isNegatedAlias = aliasInfo.compare("negatedAlias") == 0;

          // For a non-scalarized array (kept un-expanded with simCodeScalarize=false),
          // collect the per-dimension sizes so each scalar element a[i,j,...] can be
          // registered as its own result signal at the contiguous reference refIdx+offset.
          bool isArray = (vars.name == "ArrayVariable");
          std::vector<int> arrayDims;
          int arraySize = 1;
          if (isArray)
          {
            for (const XmlElement& dimNode : vars.children)
            {
              if (dimNode.name == "Dimension")
              {
                std::optional<int> d = dimNode.attributeAs<int>("start");
                if (d) { arrayDims.push_back(*d); arraySize *= *d; }
              }
            }
            if (arrayDims.empty()) { arrayDims.push_back(1); }
          }

          bool emitResult = false;
          if (emitResults != EMIT_NONE) {
            emitResult = std::regex_match(name, filterRegex);
            if (emitResults != EMIT_ALL) {
              const string* isProtectedOpt = vars.attribute("isProtected");
              bool isProtected = isProtectedOpt && *isProtectedOpt == "true";
              const string* hideResultOpt = vars.attribute("hideResult");
              bool hideResultIsTrue = hideResultOpt && *hideResultOpt == "true";
              bool hideResultIsFalse = hideResultOpt && *hideResultOpt == "false";
              emitResult &= emitResults == EMIT_HIDDEN || !hideResultIsTrue;
              emitResult &= emitResults == EMIT_PROTECTED || (!isProtected || (emitResults != EMIT_HIDDEN && hideResultIsFalse));
            }
          }

          for (const XmlElement& var : vars.children)
          {
            if ((var.name == "Real") /* Todo: this is needed for reduce dae method but breaks tests*/ /*&& (name.substr(0, 3) != "der")*/)
            {
               //If a start value is given for the alias and the referred variable, skip the alias declaration
              if (!(isAlias || isNegatedAlias))
              {
                std::optional<double> v = var.attributeAs<double>("start");
                if (v) {
                  double value = *v;
                  LOGGER_WRITE("XMLPropertyReader: Setting real variable for " + name + " with reference " + to_string(refIdx) + " to " + realToString(value), LC_INIT, LL_DEBUG);
                  for (int off = 0; off < (isArray ? arraySize : 1); off++)
                    system.setRealStartValue(realVars[refIdx + off], value);
                }
                else if (isArray)
                {
                  // an array start value with one entry per element, in row-major order
                  const string* startStr = var.attribute("start");
                  if (startStr) {
                    std::vector<double> values;
                    std::istringstream is(*startStr);
                    double d;
                    while (is >> d) values.push_back(d);
                    if ((int)values.size() == arraySize) {
                      for (int pos = 0; pos < arraySize; pos++)
                        system.setRealStartValue(realVars[refIdx + rowMajorToColumnMajor(arrayDims, pos)], values[pos]);
                    }
                  }
                }
              }
              if (emitResult)
              {
                if (isArray)
                {
                  // expose each scalar element a[i,j,...] as its own result signal
                  for (int off = 0; off < arraySize; off++)
                  {
                    const double* p = &sim_vars->getRealVar(refIdx + off);
                    std::string elname = arrayElementName(name, arrayDims, off);
                    if (isParameter)
                      _realVars.addParameter(elname, descripton, p);
                    else
                      _realVars.addOutputVar(elname, descripton, p, isNegatedAlias);
                  }
                }
                else
                {
                  const double* realVarPtr = &sim_vars->getRealVar(refIdx);
                  if (isParameter)
                    _realVars.addParameter(name, descripton, realVarPtr);
                  else
                    _realVars.addOutputVar(name, descripton, realVarPtr, isNegatedAlias);
                }
              }
            }
            else if (var.name == "Integer")
            {
               //If a start value is given for the alias and the referred variable, skip the alias declaration
              if (!(isAlias || isNegatedAlias))
              {
                std::optional<int> v = var.attributeAs<int>("start");
                if (v) {
                  int value = *v;
                  LOGGER_WRITE("XMLPropertyReader: Setting int variable for " + name + " with reference " + to_string(refIdx) + " to " + to_string(value), LC_INIT, LL_DEBUG);
                  system.setIntStartValue(intVars[refIdx], value);
                }
              }
              const int& intVar = sim_vars->getIntVar(refIdx);
              const int* intVarPtr = &intVar;
              if (emitResult)
              {
                if (isParameter)
                  _intVars.addParameter(name, descripton, intVarPtr);
                else
                  _intVars.addOutputVar(name, descripton, intVarPtr, isNegatedAlias);
              }
            }
            else if (var.name == "Boolean")
            {
               //If a start value is given for the alias and the referred variable, skip the alias declaration
              if (!(isAlias || isNegatedAlias))
              {
                std::optional<bool> v = var.attributeAs<bool>("start");
                if (v) {
                  bool value = *v;
                  LOGGER_WRITE("XMLPropertyReader: Setting bool variable for " + name + " with reference " + to_string(refIdx) + " to " + to_string(value), LC_INIT, LL_DEBUG);
                  system.setBoolStartValue(boolVars[refIdx], value);
                }
              }
              const bool& boolVar = sim_vars->getBoolVar(refIdx);
              const bool* boolVarPtr = &boolVar;
              if (emitResult)
              {
                if (isParameter)
                  _boolVars.addParameter(name, descripton, boolVarPtr);
                else
                  _boolVars.addOutputVar(name, descripton, boolVarPtr, isNegatedAlias);
              }
            }
            else if (var.name == "String")
            {
               //If a start value is given for the alias and the referred variable, skip the alias declaration
              if (!(isAlias || isNegatedAlias))
              {
                const string* v = var.attribute("start");
                if (v) {
                  string value = *v;
                  LOGGER_WRITE("XMLPropertyReader: Setting string variable for " + name + " with reference " + to_string(refIdx) + " to " + value, LC_INIT, LL_DEBUG);
                  system.setStringStartValue(stringVars[refIdx], value);
                }
              }
            }
          }
        }
      }

      size_t derSize = sim_vars->getDimStateVars();
      string name = "der";
      string descripton = "der";
      for (size_t i = 0; i < derSize; i++)
      {
        _derVars.addOutputVar(name, descripton, derVars + i, false);
      }

      LOGGER_WRITE_END(LC_INIT, LL_DEBUG);
    }
    catch(exception &ex)
    {
      std::stringstream sstream;
      sstream << "Could not read start values. Current variable reference is " << refIdx;
      throw ModelicaSimulationError(UTILITY, sstream.str());
    }
    _isInitialized = true;
    file.close();

  }
}

const output_int_vars_t&  XmlPropertyReader::getIntOutVars()
{
  if (_isInitialized)
    return _intVars;
  else
    throw ModelicaSimulationError(UTILITY, "init xml file has not been read");
}

const output_real_vars_t& XmlPropertyReader::getRealOutVars()
{
  if (_isInitialized)
    return _realVars;
  else
    throw ModelicaSimulationError(UTILITY, "init xml file has not been read");
}

const output_bool_vars_t& XmlPropertyReader::getBoolOutVars()
{
  if (_isInitialized)
    return _boolVars;
  else
    throw ModelicaSimulationError(UTILITY, "init xml file has not been read");
}

const output_der_vars_t& XmlPropertyReader::getDerOutVars()
{
  if (_isInitialized)
    return _derVars;
  else
    throw ModelicaSimulationError(UTILITY, "Derivatives xml file has not been read");
}

const output_res_vars_t& XmlPropertyReader::getResOutVars()
{
  if (_isInitialized)
    return _resVars;
  else
    throw ModelicaSimulationError(UTILITY, "Residues xml file has not been read");
}

std::string XmlPropertyReader::getPropertyFile()
{
  return _propertyFile;
}

void XmlPropertyReader::setPropertyFile(std::string file)
{
  _propertyFile = file;
}
