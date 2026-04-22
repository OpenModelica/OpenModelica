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

#include <Core/Modelica.h>
#include <Core/ReduceDAE/ReduceDAESettings.h>
#include <boost/property_tree/xml_parser.hpp>
#include <boost/property_tree/ptree.hpp>


ReduceDAESettings::ReduceDAESettings(IGlobalSettings* globalSettings)
    : _globalSettings(globalSettings),
      _ranking_method(RESIDUEN),
      _reduction_method(CANCEL_TERMS)

{
    //initialize max errro vector with default size
    //_max_error.resize(3);
}

unsigned int ReduceDAESettings::getRankingMethod()
{
    return _ranking_method;
}

void ReduceDAESettings::setRankingMethod(unsigned int method)
{
    _ranking_method = method;
}

unsigned int ReduceDAESettings::getReductionMethod()
{
    return _reduction_method;
}

void ReduceDAESettings::setReductionMethod(unsigned int method)
{
    _reduction_method = method;
}

unsigned int ReduceDAESettings::getNFail()
{
    return _nfail;
}

void ReduceDAESettings::setNFail(unsigned int fail)
{
    _nfail = fail;
}

ublas::vector<double> ReduceDAESettings::getMaxError()
{
    return _max_error;
}

void ReduceDAESettings::setMaxError(ublas::vector<double>& error)
{
    _max_error = error;
}

IGlobalSettings* ReduceDAESettings::getGlobalSettings()
{
    return _globalSettings;
}

vector<string> ReduceDAESettings::getOutputNames()
{
    return _output_names;
}

/**
initializes settings object by an xml file
*/
void ReduceDAESettings::load(std::string xml_file)
{
    try
    {
        using boost::property_tree::ptree;
        std::ifstream file;
        file.open(xml_file.c_str(), std::ifstream::in);
        if (!file.good())
            cout << "Settings file not found for :" << xml_file << std::endl;
        else
        {
            ptree tree;
            read_xml(file, tree);

            FOREACH(ptree::value_type const& vars, tree.get_child("ReduceDAESettings"))
            {
                if (vars.first == "NFail")
                {
                    _nfail = vars.second.get<int>("<xmlattr>.value");
                }


                if (vars.first == "RakingMethod")
                {
                    _ranking_method = vars.second.get<int>("<xmlattr>.value");
                }

                if (vars.first == "ReductionMethod")
                {
                    _reduction_method = vars.second.get<int>("<xmlattr>.value");
                }

                if (vars.first == "MaximumError")
                {
                    ublas::vector<double>::size_type i = 0;
                    FOREACH(ptree::value_type const& var, vars.second.get_child(""))
                    {
                        if (var.first == "size")
                        {
                            int size = var.second.get<int>("<xmlattr>.value");
                            _max_error.resize(size);
                        }
                        if (var.first == "item")
                        {
                            double error = var.second.get<double>("<xmlattr>.value");
                            _max_error.insert_element(i, error);

                            string name = var.second.get<string>("<xmlattr>.name");
                            _output_names.push_back(name);

                            i++;
                        }
                    }
                }
            }
        }
    }
    catch (std::exception& ex)
    {
        std::string error = ex.what();
        cout << "error in loading or initializing from ReduceDAESettings.xml " << error << std::endl;
    }
}
