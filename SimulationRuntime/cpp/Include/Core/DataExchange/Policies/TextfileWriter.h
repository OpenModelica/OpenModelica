#pragma once
/*includes removed for static linking not needed any more
#ifdef RUNTIME_STATIC_LINKING
#include <sstream>
#include <vector>
#endif

// Output
#include <fstream>
#include <Core/DataExchange/Writer.h>
using std::ios;
#define SEPERATOR ","
#define EXTENSION ","
*/
/**
 Policy class to write simulation results in a text file
 */
  const char SEPERATOR = ',';
    const char EXTENSION = ',';
template<size_t dim_1, size_t dim_2, size_t dim_3, size_t dim_4>
class TextFileWriter : public Writer<dim_1, dim_2, dim_3, dim_4>
{
 public:
    TextFileWriter(unsigned long size, string output_path, string file_name)
            : Writer<dim_1, dim_2, dim_3, dim_4>(),
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

    void init(std::string output_path, std::string file_name)
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
    void write(const typename Writer<dim_1, dim_2, dim_3, dim_4>::value_type_p& v_list, double start_time, double end_time)
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
    void write(const std::vector<std::string>& s_list, const std::vector<std::string>& s_desc_list, const std::vector<std::string>& s_parameter_list, const std::vector<std::string>& s_desc_parameter_list)
    {
        std::string s;
        _output_stream << "\"time\"" << SEPERATOR;

        for (std::vector<std::string>::const_iterator it = s_list.begin(); it != s_list.end(); ++it)
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
    void write(typename Writer<dim_1, dim_2, dim_3, dim_4>::value_type_v& v_list, typename Writer<dim_1, dim_2, dim_3, dim_4>::value_type_dv& v2_list, double time)
    {
        _output_stream << time << SEPERATOR;

        for (typename Writer<dim_1, dim_2, dim_3, dim_4>::value_type_v::const_iterator it = v_list.begin(); it != v_list.end(); ++it)
            _output_stream << (*it) << SEPERATOR;

        for (typename Writer<dim_1, dim_2, dim_3, dim_4>::value_type_dv::const_iterator it = v2_list.begin(); it != v2_list.end(); ++it)
            _output_stream << (*it) << SEPERATOR;

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
