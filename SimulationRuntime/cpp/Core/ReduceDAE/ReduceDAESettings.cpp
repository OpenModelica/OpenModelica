#include <Core/Modelica.h>
#include <Core/ReduceDAE/ReduceDAESettings.h>
#include <boost/property_tree/xml_parser.hpp>
#include <boost/property_tree/ptree.hpp>




ReduceDAESettings::ReduceDAESettings(IGlobalSettings*	globalSettings)
	:_globalSettings(globalSettings),
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
					ublas::vector<double>::size_type  i = 0;
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