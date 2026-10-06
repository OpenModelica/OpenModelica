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
#include <set>
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

// The values of a start attribute: one value, or one per element of an array in
// row-major order, separated by spaces. Empty if one of them does not parse.
template <class T>
static std::vector<T> parseValues(const std::string& str)
{
  std::vector<T> values;
  if constexpr (std::is_same_v<T, std::string>) {
    values.push_back(str);
  }
  else {
    std::istringstream is(str);
    is.imbue(std::locale::classic());
    std::string token;
    while (is >> token) {
      T value;
      if constexpr (std::is_same_v<T, bool>) {
        if (token == "true" || token == "1")
          value = true;
        else if (token == "false" || token == "0")
          value = false;
        else
          return std::vector<T>();
      }
      else {
        std::istringstream ts(token);
        ts.imbue(std::locale::classic());
        ts >> value;
        if (ts.fail() || !(ts >> std::ws).eof())
          return std::vector<T>();
      }
      values.push_back(value);
    }
  }
  return values;
}

// name=value,name=value as given with -override; commas inside [] belong to a name.
static std::map<std::string, std::string> parseOverrides(const std::string& str)
{
  std::map<std::string, std::string> overrides;
  std::string item;
  int depth = 0;
  for (size_t i = 0; i <= str.size(); i++) {
    char c = i < str.size() ? str[i] : ',';
    if (c == '[') depth++;
    if (c == ']') depth--;
    if (c == ',' && depth == 0) {
      size_t eq = item.find('=');
      if (eq != std::string::npos && eq > 0)
        overrides[item.substr(0, eq)] = item.substr(eq + 1);
      else if (!item.empty())
        throw ModelicaSimulationError(UTILITY, "Invalid -override " + item + ", expected name=value");
      item.clear();
    }
    else
      item += c;
  }
  return overrides;
}

static void setStartValue(IContinuous& system, double& var, double value) { system.setRealStartValue(var, value); }
static void setStartValue(IContinuous& system, int& var, int value) { system.setIntStartValue(var, value); }
static void setStartValue(IContinuous& system, bool& var, bool value) { system.setBoolStartValue(var, value); }
static void setStartValue(IContinuous& system, std::string& var, const std::string& value) { system.setStringStartValue(var, value); }

// Set the start value(s) of the variable at pos with n elements (an array if dims is not empty).
template <class T>
static void readStartValue(IContinuous& system, T* vars, int pos, int n, const std::vector<int>& dims,
                           const std::string& startStr, const std::string& name)
{
  std::vector<T> values = parseValues<T>(startStr);
  if (values.size() == 1) {
    for (int off = 0; off < n; off++)
      setStartValue(system, vars[pos + off], values[0]);
  }
  else if (!dims.empty() && (int)values.size() == n) {
    for (int p = 0; p < n; p++)
      setStartValue(system, vars[pos + rowMajorToColumnMajor(dims, p)], values[p]);
  }
  else if (!values.empty()) {
    LOGGER_WRITE("XMLPropertyReader: " + to_string(values.size()) + " start values for " + name + " with "
                 + to_string(n) + " elements, ignored", LC_INIT, LL_WARNING);
  }
}

// Register the variable at pos as result signal(s), each element of an array as a[i,j,...].
template <class T, class OutVars>
static void addResultVars(OutVars& outVars, const T* vars, int pos, int n, const std::vector<int>& dims,
                          const std::string& name, const std::string& description, bool isParameter, bool isNegatedAlias)
{
  std::string desc = description;
  for (int off = 0; off < n; off++) {
    std::string elname = dims.empty() ? name : arrayElementName(name, dims, off);
    if (isParameter)
      outVars.addParameter(elname, desc, vars + pos + off);
    else
      outVars.addOutputVar(elname, desc, vars + pos + off, isNegatedAlias);
  }
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
    std::map<std::string, std::string> overrides = parseOverrides(_globalSettings->getParameterOverrides());
    std::set<std::string> overridden;
    _realVars.clear();
    _intVars.clear();
    _boolVars.clear();
    _derVars.clear();
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
          std::vector<int> xmlDims;
          if (vars.name == "ArrayVariable")
          {
            for (const XmlElement& dimNode : vars.children)
            {
              if (dimNode.name == "Dimension")
              {
                std::optional<int> d = dimNode.attributeAs<int>("start");
                if (d) xmlDims.push_back(*d);
              }
            }
            if (xmlDims.empty()) { xmlDims.push_back(1); }
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
            char type;
            size_t dimVars;
            if (var.name == "Real") { type = 'r'; dimVars = sim_vars->getDimReal(); }
            else if (var.name == "Integer") { type = 'i'; dimVars = sim_vars->getDimInt(); }
            else if (var.name == "Boolean") { type = 'b'; dimVars = sim_vars->getDimBool(); }
            else if (var.name == "String") { type = 's'; dimVars = sim_vars->getDimString(); }
            else continue;

            // the model knows the position and the sizes of variables that depend on parameters
            int pos = refIdx;
            std::vector<int> dims = xmlDims;
            std::vector<int> layoutDims;
            if (system.getVariableLayout(type, refIdx, pos, layoutDims))
              dims = layoutDims;
            int n = 1;
            for (int d : dims)
              n *= d;
            if (pos < 0 || (n > 0 && (size_t)(pos + n) > dimVars))
              throw ModelicaSimulationError(UTILITY, "Variable " + name + " is outside of the variable memory");

            // start value, possibly replaced with -override
            const string* startStr = var.attribute("start");
            std::map<std::string, std::string>::const_iterator ov = overrides.find(name);
            if (ov != overrides.end()) {
              startStr = &ov->second;
              overridden.insert(name);
            }
            if (startStr && !(isAlias || isNegatedAlias)) {
              LOGGER_WRITE("XMLPropertyReader: Setting " + var.name + " variable " + name + " with reference " + to_string(refIdx)
                           + " at " + to_string(pos) + " to " + *startStr, LC_INIT, LL_DEBUG);
              switch (type) {
                case 'r': readStartValue(system, realVars, pos, n, dims, *startStr, name); break;
                case 'i': readStartValue(system, intVars, pos, n, dims, *startStr, name); break;
                case 'b': readStartValue(system, boolVars, pos, n, dims, *startStr, name); break;
                case 's': readStartValue(system, stringVars, pos, n, dims, *startStr, name); break;
              }
            }

            if (emitResult) {
              switch (type) {
                case 'r': addResultVars(_realVars, (const double*)realVars, pos, n, dims, name, descripton, isParameter, isNegatedAlias); break;
                case 'i': addResultVars(_intVars, (const int*)intVars, pos, n, dims, name, descripton, isParameter, isNegatedAlias); break;
                case 'b': addResultVars(_boolVars, (const bool*)boolVars, pos, n, dims, name, descripton, isParameter, isNegatedAlias); break;
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
    catch(ModelicaSimulationError &ex)
    {
      throw;
    }
    catch(exception &ex)
    {
      std::stringstream sstream;
      sstream << "Could not read start values. Current variable reference is " << refIdx;
      throw ModelicaSimulationError(UTILITY, sstream.str());
    }
    for (std::map<std::string, std::string>::const_iterator it = overrides.begin(); it != overrides.end(); ++it)
      if (overridden.find(it->first) == overridden.end())
        LOGGER_WRITE("XMLPropertyReader: -override of unknown variable " + it->first + " ignored", LC_INIT, LL_WARNING);
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
