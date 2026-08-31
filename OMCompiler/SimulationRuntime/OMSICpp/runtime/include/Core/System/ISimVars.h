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

#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */

/**
* Class for SimVars, stores all model variable in continuous block of memory
*/
class ISimVars
{
public:

    virtual ~ISimVars()
    {
    };

    virtual ISimVars* clone() = 0;

    /*Methods for access model variables*/
    virtual double* getStateVector() = 0;
    virtual double* getDerStateVector() = 0;
    virtual double* getRealVarsVector() const = 0;
    virtual int* getIntVarsVector() const = 0;
    virtual bool* getBoolVarsVector() const = 0;
    virtual int* getOMSIBoolVarsVector() const = 0;
    virtual string* getStringVarsVector() const = 0;
    virtual void setRealVarsVector(const double* vars) = 0;
    virtual void setIntVarsVector(const int* vars) = 0;
    virtual void setBoolVarsVector(const bool* vars) = 0;

    virtual void setStringVarsVector(const string* vars) = 0;

    /*Methods to get sizes of variable vectors*/
    virtual size_t getDimString() const = 0;
    virtual size_t getDimBool() const = 0;
    virtual size_t getDimInt() const = 0;
    virtual size_t getDimPreVars() const = 0;
    virtual size_t getDimReal() const = 0;
    virtual size_t getDimStateVars() const = 0;
    virtual size_t getStateVectorIndex() const = 0;

    /*Methods for initialize model array variables in simvars memory*/
    virtual double* initRealArrayVar(size_t size, size_t start_index) = 0;
    virtual int* initIntArrayVar(size_t size, size_t start_index) = 0;
    virtual bool* initBoolArrayVar(size_t size, size_t start_index) = 0;
    virtual int* initOMSIBoolArrayVar(size_t size, size_t start_index) = 0;
    virtual string* initStringArrayVar(size_t size, size_t start_index) = 0;
    virtual void initRealAliasArray(int indices[], size_t n, double* ref_data[]) = 0;
    virtual void initIntAliasArray(int indices[], size_t n, int* ref_data[]) = 0;
    virtual void initBoolAliasArray(int indices[], size_t n, bool* ref_data[]) = 0;
    virtual void initOMSIBoolAliasArray(int indices[], size_t n, int* ref_data[]) = 0;
    virtual void initStringAliasArray(int indices[], size_t n, string* ref_data[]) = 0;
    virtual void initRealAliasArray(std::vector<int> indices, double* ref_data[]) = 0;
    virtual void initIntAliasArray(std::vector<int> indices, int* ref_data[]) = 0;
    virtual void initBoolAliasArray(std::vector<int> indices, bool* ref_data[]) = 0;
    virtual void initOMSIBoolAliasArray(std::vector<int> indices, int* ref_data[]) = 0;
    virtual void initStringAliasArray(std::vector<int> indices, string* ref_data[]) = 0;
    /*Methods to read variable from simvars memory*/
    virtual const double& getRealVar(size_t i) = 0;
    virtual const int& getIntVar(size_t i) = 0;
    virtual const bool& getBoolVar(size_t i) = 0;
    virtual const int& getOMSIBoolVar(size_t i) = 0;
    virtual const std::string& getStringVar(size_t i) = 0;

    /*Methods for initialize scalar model variables in simvars memory*/
    virtual double& initRealVar(size_t i) = 0;
    virtual int& initIntVar(size_t i) = 0;
    virtual bool& initBoolVar(size_t i) = 0;
    virtual int& initOMSIBoolVar(size_t i) = 0;
    virtual string& initStringVar(size_t i) = 0;

    /*Methods for pre- variables*/
    virtual void savePreVariables() = 0;
    virtual void initPreVariables() = 0;
    /*access methods for pre-variable*/
    virtual double& getPreVar(const double& var) =0;
    virtual int& getPreVar(const int& var) =0;
    virtual bool& getPreVar(const bool& var) =0;
    virtual std::string& getPreVar(const std::string& var) =0;
};

/** @} */ // end of coreSystem
