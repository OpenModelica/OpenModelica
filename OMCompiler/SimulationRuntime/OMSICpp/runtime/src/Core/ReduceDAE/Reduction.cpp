#include <Core/Modelica.h>
#include <Core/SimController/ISimController.h>
#include <Core/ReduceDAE/IReduceDAESettings.h>
#include <Core/ReduceDAE/IReduceDAE.h>
#include <Core/ReduceDAE/Reduction.h>
#include <boost/math/special_functions/fpclassify.hpp>

Reduction::Reduction( shared_ptr<IMixedSystem> system, IReduceDAESettings* settings)
	:_system(system)
	, _settings(settings)
{
}

Reduction::~Reduction(void)
{
}


//find difference between reference and current output values
ublas::vector<double> Reduction::getError(ublas::matrix<double>& R, ublas::matrix<double>& R2, vector<string> output_names)
{
	//using namespace boost::math;
	ublas::matrix<double>::size_type i, n;
	ublas::vector<double> o_i;
	ublas::vector<double> or_i;
	unsigned counter = 0;
	//number of output values
	n = R.size1();
	//vector for error
	ublas::vector<double> error(n);


	for (i = 0; i < n; ++i)
	{
		//vector for current output values
		o_i = ublas::row(R, i);
		//cout << "after reduction: Output variable "<<output_names[counter]<< " "<< o_i<<std::endl;
		//vector for reference output values
		or_i = ublas::row(R2, i);
		//cout << "original Output variable "<<output_names[counter]<< " "<< or_i<<std::endl;
		//check if both vectors have the same number of entries
		if (o_i.size() == or_i.size())
		{
			// cout << "subtraction of reduced values from originals "<<output_names[counter]<< " "<< sum(o_i-or_i)/n <<std::endl;
			//norm_2 (x)= sqrt (sum |xi|^2 )
			error(i) = ublas::norm_2(o_i - or_i);
			// cout << "Error by reduction: Output variable "<<output_names[counter]<< " "<< error(i) <<std::endl;
		}
		//if o_i and or_i are of different size, then simulation stopped - label should not be removed: error gets max possible value
#undef max
		else
			error(i) = std::numeric_limits<double>::max();

		if (boost::math::isnan(error(i)))
			error(i) = std::numeric_limits<double>::max();
		counter++;
	}


	return error;

}
std::vector<unsigned int> Reduction::cancelTerms(label_list_type& labels, ublas::matrix<double>& Ro, shared_ptr<IMixedSystem> _system, IReduceDAESettings* _settings
                                                 ,SimSettings simsettings, string modelKey, vector<string> output_names, double timeout,ISimController* sim_controller)
{

	//if the reference matrix for output variables has no rows, then there are no output variables
	if (Ro.size1() == 0)
		throw std::runtime_error("No output variables!");
	cout << "Start deletion:" << std::endl;

	//vector of labels to be canceled
	std::vector<unsigned int> canceled_labels;
	std::vector<unsigned int> help_canceled_labels;
	//cast modelica system to reduce dae object

	shared_ptr<IReduceDAE> reduce_dae = dynamic_pointer_cast<IReduceDAE>(_system);
	//get history object to query simulation results
	IHistory*  history;

	//simulation results for output variables of k.-reduction
	ublas::matrix<double> Rok;
	//current label


	unsigned int nfail = 0;
	unsigned int reductionStep = 1;
	if (reduce_dae)
	{

		//get max error
		ublas::vector<double> max_error = _settings->getMaxError();
		vector<string> output_names_xml = _settings->getOutputNames();
		ublas::vector<double> sorted_max_error(max_error.size());
		vector<int> indexes;
		ublas::vector<double>::size_type  i = 0;
		//make sorted vector of error based on given variables name from buffer
		for (int j = 0; j < output_names.size(); j++)
		{
			auto it = std::find(output_names_xml.begin(), output_names_xml.end(), output_names[j]);
			if (it == output_names_xml.end())
			{
				// name not in vector
			}
			else
			{
				auto index = std::distance(output_names_xml.begin(), it);
				sorted_max_error.insert_element(i, max_error[index]);
				i++;
				indexes.push_back(j);
			}
		}

		cout << "sorted_max_error " << sorted_max_error << std::endl;
        #ifdef USE_CHRONO
		auto start = high_resolution_clock::now();
        #endif
		//loop over labels
		FOREACH(label_type  label, labels)
		{
			try
			{

				//removing initialization from here and put it ouside of BOOST_FOREACH,
				//cause not updated output values on Rok vector!!
				#ifdef USE_CHRONO
                auto startSim1 = high_resolution_clock::now();
				#endif
                sim_controller->initialize(simsettings, modelKey, timeout);
				//set current label_1 to 0 and label_2 to 1
				*(get<1>(label)) = 0;
				*(get<2>(label)) = 1;
				//by initialization all labels becomes 1,
				// so with this help_canceled_labels we apply all labels which are zero untill now to the model again
				for (int i = 0; i < help_canceled_labels.size(); i++)
				{

					//cout << "indexes of deleted labels applied to the model " <<  get<0>(labels[help_canceled_labels[i]]) <<std::endl;
					*(get<1>(labels[help_canceled_labels[i]])) = 0;
					*(get<2>(labels[help_canceled_labels[i]])) = 1;
				}

				//number of output variables
				ublas::matrix<double>::size_type n;
				n = Ro.size1();
				//vector for errors
				ublas::vector<double> error(n);
				//run simulation
				sim_controller->runReducedSimulation();
				#ifdef USE_CHRONO
                auto endSim1 =  high_resolution_clock::now();
				double simtime = duration_cast<duration<double>>(endSim1 - startSim1).count();
				#endif
                std::cout << " time of simulation for reducing label " << get<0>(label) << " is " << simtime << " seconds" << std::endl;
				history = reduce_dae->getHistory();

				//query simulation result outputs
				Rok.clear();
				history->getOutputResults(Rok);

				//error

				Reduction reduction(_system, _settings);

				error = reduction.getError(Rok, Ro, output_names);

				//check if error of selected varibles based on indexes vector is less than max error
				if (reduction.isLess(error, sorted_max_error, indexes, output_names))
				{
					cout << "delete term for label " << get<0>(label) << " with error " << error << std::endl;
					//add label number to canceled_labels
					canceled_labels.push_back(get<0>(label));
					help_canceled_labels.push_back(reductionStep - 1);
				}
				else
				{
					cout << "do nothing for label " << get<0>(label) << " with error " << error << std::endl;
					//reset current label values
					*(get<1>(label)) = 1;
					*(get<2>(label)) = 0;
					nfail++;

					//check if looking for terms to reduce has failed more than allowed
					if ((nfail) > _settings->getNFail())
					{
						cout << "Redution stoped at step " << reductionStep + 1 << " because of exceeding max number of reduction fails" << std::endl;
						//stop looking for terms to delete
						break;
					}

				}

			}

			catch (ModelicaSimulationError& ex)
			{
				if (!ex.isSuppressed())
					cout << "do nothing for label " << get<0>(label) << " with error " << ex.what() << std::endl;
				// std::cerr << "Simulation stopped with error in " << error_id_string(ex.getErrorID()) << ": "  << ex.what();
				//reset current label values
				*(get<1>(label)) = 1;
				*(get<2>(label)) = 0;
				nfail++;

				//check if looking for terms to reduce has failed more than allowed
				if ((nfail) > _settings->getNFail())
				{
					cout << "Redution failed for " << nfail << " times. So, it stoped at step " << reductionStep + 1 << std::endl;
					//stop looking for terms to delete
					break;
				}

			}

			reductionStep++;

		}
        #ifdef USE_CHRONO
		auto end = high_resolution_clock::now();
        #endif
		std::cout << " time of reduction: " << std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count() << " milliseconds" << std::endl;
		return canceled_labels;
	}
	else
		throw std::runtime_error("Modelica system is not of type IReduceDAE");
}


//function for checking if error is less than max error
bool Reduction::isLess(ublas::vector<double>& v1, ublas::vector<double>& v2, vector<int> indexes, vector<string> output_names)
{
	//cout << " v1 "<<v1<<std::endl;
	//cout << " sorted_max_error "<<v2<<std::endl;
	//check if number of output variables corresponds to the number of output variables in ReduceDAESettings.xml
	//if(v1.size() == v2.size())
	//{
	ublas::vector<double>::iterator iter, iter2;
	//check if error is less than max error
	/*for(iter=v1.begin(),iter2=v2.begin();iter!=v1.end();++iter,++iter2)
	{if((*iter)>=(*iter2))
	return false;
	}*/
	for (int i = 0; i < indexes.size(); i++)
	{
		cout << indexes[i] << " error variable " << output_names[indexes[i]] << " with error bound " << v2[i] << " is " << v1[indexes[i]] << std::endl;
		if ((v1[indexes[i]] >= v2[i]) && v2[i] != 0)
			return false;
		else if (v2[i] == 0 && (v1[indexes[i]] != v2[i]))
			return false;
	}
	return true;
	//}
	//else{throw std::runtime_error("Number of output variables does not correspond to ReduceDAESettings.xml!"); }
}