#pragma once
/** @addtogroup dataexchangePolicies
 *
 *  @{
 */

#include <Core/DataExchange/FactoryPolicy.h>
#include <fstream>

/**
 Policy class to write simulation results
*/

class DefaultWriter : public ContainerManager
{
 public:
    DefaultWriter(unsigned long size, string output_path, string file_name)
            : ContainerManager()

    {
    }

    ~DefaultWriter()
    {

    }

    void init(std::string output_path, std::string file_name, size_t dim)
    {

    }
    void read(ublas::matrix<double>& R, ublas::matrix<double>& dR)
    {


    }

    void read(ublas::matrix<double>& R, ublas::matrix<double>& dR, ublas::matrix<double>& Re)
    {


    }

    void read(const double& time, ublas::vector<double>& dv, ublas::vector<double>& v)
    {


    }

    void read(ublas::matrix<double>& R)
    {


    }

    /*writes pramater values to results file
     @v_list values of parameter
     @start_time
     @end_time
     */
    virtual void write(const all_vars_t& v_list, double start_time, double end_time)
    {

        //not supported for file output
    }

    /*
     writes header of results file with the variable names
     @s_list name of variables
     @s_desc_list description of variables
     @s_parameter_list name of parameter
     @s_desc_parameter_list description of parameter
     */
    virtual void write(const all_names_t& s_list,const all_description_t& s_desc_list, const all_names_t& s_parameter_list,const all_description_t& s_desc_parameter_list)
    {

    }

    void write(const char c)
    {

    }

    /*
     writes simulation results for a time step
     @v_list variables and state vars
     @v2_list derivatives vars
     @time
     */
    virtual void write(const all_vars_time_t& v_list,const neg_all_vars_t& neg_v_list)
    {

    }

    void getTime(std::vector<double>& time)
    {
        //not supported for file output
    }

    unsigned long size()
    {
        //not supported for file output
        return 0;
    }

    void eraseAll()
    {

    }
 protected:
    vector<string> _var_outputs;

};
/** @} */ // end of dataexchangePolicies
