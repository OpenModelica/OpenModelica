#pragma once
/** @addtogroup dataexchangePolicies
 *
 *  @{
 */

#include <Core/DataExchange/FactoryPolicy.h>
#include <fstream>

/**
 Policy class to write simulation results in a text file
*/
const char SEPERATOR = ',';
const char EXTENSION = ',';

class TextFileWriter : public ContainerManager
{
 public:
    TextFileWriter(unsigned long size, string output_path, string file_name)
            : ContainerManager(),
              _output_stream(),
              _curser_position(0),
              _output_path(output_path),
              _file_name(file_name)
    {
    }

    ~TextFileWriter()
    {
        if (_output_stream.is_open())
            _output_stream.close();
    }

    void init(std::string output_path, std::string file_name,size_t dim)
    {
        _file_name = file_name;
        _output_path = output_path;
        if (_output_stream.is_open())
            _output_stream.close();
        std::stringstream res_output_path;
        res_output_path << output_path << file_name;
        _output_stream.open(res_output_path.str().c_str(), ios::out);

    }
    void read(ublas::matrix<double>& R, ublas::matrix<double>& dR)
    {
        //not supported for file output

    }

    void read(ublas::matrix<double>& R, ublas::matrix<double>& dR, ublas::matrix<double>& Re)
    {
        //not supported for file output

    }

    void read(const double& time, ublas::vector<double>& dv, ublas::vector<double>& v)
    {
        //not supported for file output

    }

    void read(ublas::matrix<double>& R)
    {
        //not supported for file output

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
        std::string s;
        _output_stream << "\"time\"" << SEPERATOR;

        for (var_names_t::const_iterator it = get<0>(s_list).begin(); it != get<0>(s_list).end(); ++it)
            _output_stream << "\"" << (*it) << "\"" << SEPERATOR;
        for (var_names_t::const_iterator it = get<1>(s_list).begin(); it != get<1>(s_list).end(); ++it)
            _output_stream << "\"" << (*it) << "\"" << SEPERATOR;
        for (var_names_t::const_iterator it = get<2>(s_list).begin(); it != get<2>(s_list).end(); ++it)
            _output_stream << "\"" << (*it) << "\"" << SEPERATOR;
        _output_stream << std::endl;
    }

    void write(const char c)
    {
        _output_stream << c;
    }

    /*
     writes simulation results for a time step
     @v_list variables and state vars
     @v2_list derivatives vars
     @time
     */
    virtual void write(const all_vars_time_t& v_list,const neg_all_vars_t& neg_v_list)
    {
        _output_stream << get<3>(v_list) << SEPERATOR;


        std::transform(get<0>(v_list).begin(), get<0>(v_list).end(), get<0>(neg_v_list).begin(),
            std::ostream_iterator<double>(_output_stream,","), WriteOutputVar<double>());


        std::transform(get<1>(v_list).begin(), get<1>(v_list).end(), get<1>(neg_v_list).begin(),
            std::ostream_iterator<int>(_output_stream,","), WriteOutputVar<int>());


        std::transform(get<2>(v_list).begin(), get<2>(v_list).end(), get<2>(neg_v_list).begin(),
           std::ostream_iterator<bool>(_output_stream,","), WriteOutputVar<bool>());

        _output_stream << std::endl;
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
        _curser_position = 0;
        _output_stream.seekp(_curser_position);
    }

 protected:


    std::fstream _output_stream;
    unsigned int _curser_position;       ///< Controls current Curser-Position
    std::string _output_path;
    std::string _file_name;
    vector<string> _var_outputs;
};
/** @} */ // end of dataexchangePolicies
