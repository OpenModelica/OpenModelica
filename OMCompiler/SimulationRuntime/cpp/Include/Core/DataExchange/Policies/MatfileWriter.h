/** @addtogroup dataexchangePolicies
 *
 *  @{
 */

/*=={info}======================================================================================*/
/*!
 * \title      MatfileWriter
 * \date       2014-07-29
 *
 * \content    Policy class to write simulation results in a MATLAB file
 */
/*========================================================================================{end}==*/
#pragma once
/*includes removed for static linking not needed any more
#ifdef RUNTIME_STATIC_LINKING
#include <sstream>
#include <vector>
#endif

#include <fstream>
using std::ios;
*/
#include <Core/DataExchange/FactoryPolicy.h>


class MatFileWriter : public ContainerManager
{
 public:
    MatFileWriter(unsigned long size, string file_name)
            : ContainerManager(),
              _dataHdrPos(),
              _dataEofPos(),
              _curser_position(0),
              _uiValueCount(0),
              _file_name(file_name),
              _doubleMatrixData1(NULL),
              _doubleMatrixData2(NULL),
              _stringMatrix(NULL),
              _pacString(NULL),
              _intMatrix(NULL)
    {

    }
    ~MatFileWriter()
    {
        // free memory and initialize pointer
        delete[] _doubleMatrixData1;
        delete[] _doubleMatrixData2;
        delete[] _stringMatrix;
        delete[] _pacString;
        delete[] _intMatrix;

        _doubleMatrixData1 = NULL;
        _doubleMatrixData2 = NULL;
        _stringMatrix = NULL;
        _pacString = NULL;
        _intMatrix = NULL;

        if (_output_stream.is_open())
            _output_stream.close();
    }

    /*=={function}===================================================================================*/
    /*!
     *  static inline void vFixVarName(char *pcStr, size_t uiLength)
     *
     *  brief:
     *  ------
     *  function changes names of derivated variables
     *  e.g. der(secondOrder.y) is changed in secondOrder.der(y)
     *
     * \param[in]      *pcStr
     * \n        usage: pointer to changing string
     *            range: not relevant
     *
     * \param[in]       uiLength
     * \n        usage: length of changing string
     * \n        range: [0 ; +4294967295]
     *
     * \return
     */
    /*========================================================================================{end}==*/
    static inline void vFixVarName(char *pcStr, size_t uiLength)
    {
        char* pcDot;

        if (uiLength < 6)
            return;

        while (strncmp(pcStr, "der(", 4) == 0 && (pcDot = strrchr(pcStr, '.')) != NULL)
        {
            size_t uiPos = (size_t) (pcDot - pcStr) + 1;

            for (size_t uiIndex = 4; uiIndex < uiPos; ++uiIndex)
                pcStr[uiIndex - 4] = pcStr[uiIndex];

            strncpy(&pcStr[uiPos - 4], "der(", 4);
        }
    }

    /*=={function}===================================================================================*/
    /*!
     *  void writeMatVer4MatrixHeader(const char *name, int rows, int cols, unsigned int size)
     *
     *  brief:
     *  ------
     *  function writes a matrix header
     *
     * \param[in]       *name
     * \n        usage: pointer to name of matrix
     *            range: not relevant
     *
     * \param[in]       rows
     * \n        usage: number of rows
     * \n        range: [-2147483648 ; +2147483647]
     *
     * \param[in]       cols
     * \n        usage: number of cols
     * \n        range: [-2147483648 ; +2147483647]
     *
     * \param[in]       size
     * \n        usage: length of changing string
     * \n        range: [0 ; +4294967295]
     *
     * \return
     */
    /*========================================================================================{end}==*/
    void writeMatVer4MatrixHeader(const char *name, int rows, int cols, unsigned int size)
    {
        // matrix header struct
        typedef struct MHeader
        {
            unsigned int type;
            unsigned int mrows;
            unsigned int ncols;
            unsigned int imagf;
            unsigned int namelen;
        } MHeader_t;
        const int endian_test = 1;
        MHeader_t hdr;

        // every data type has an own type value
        int type = 0;
        if (size == 1)  //char
            type = 51;
        if (size == 4)  //int32
            type = 20;

        // initializing header
        hdr.type = 1000 * ((*(char*) &endian_test) == 0) + type;
        hdr.mrows = rows;
        hdr.ncols = cols;
        hdr.imagf = 0;
        hdr.namelen = strlen(name) + 1;

        // special treatment for "data_2" matrix. After new simualtion data, header has to be written
        if ((strcmp(name, "data_2") == 0) && (_dataHdrPos != _output_stream.tellp()))
        {
            _dataEofPos = _output_stream.tellp();
            _output_stream.seekp(_dataHdrPos);
            _output_stream.write((char*) &hdr, sizeof(MHeader_t));
            _output_stream.write(name, sizeof(char) * hdr.namelen);
            _output_stream.seekp(_dataEofPos);
        }
        else  // standard routine for header
        {
            _output_stream.write((char*) &hdr, sizeof(MHeader_t));
            _output_stream.write(name, sizeof(char) * hdr.namelen);
        }
    }

    /*=={function}===================================================================================*/
    /*!
     *  void writeMatVer4Matrix(const char *name, int rows, int cols, const void *matrixData, unsigned int size)
     *
     *  brief:
     *  ------
     *  function writes the data of a matrix
     *
     * \param[in]       *name
     * \n        usage: pointer to name of matrix
     *            range: not relevant
     *
     * \param[in]       rows
     * \n        usage: number of rows
     * \n        range: [-2147483648 ; +2147483647]
     *
     * \param[in]       cols
     * \n        usage: number of cols
     * \n        range: [-2147483648 ; +2147483647]
     *
     * \param[in]       *matrixData
     * \n        usage: pointer to data
     * \n        range: not relevant
     *
     * \param[in]       size
     * \n        usage: length of changing string
     * \n        range: [0 ; +4294967295]
     *
     * \return
     */
    /*========================================================================================{end}==*/
    void writeMatVer4Matrix(const char *name, int rows, int cols, const void *matrixData, unsigned int size)
    {
        // first matrix header has to be written
        writeMatVer4MatrixHeader(name, rows, cols, size);

        // special treatment for "data_2" matrix. cols = 1
        if (strcmp(name, "data_2") == 0)
        {
            _output_stream.write((const char*) matrixData, (size) * rows * 1);
            //dataDummy = _output_stream.tellp(); // workaround: because with gcc compiled, sporadicaly the last simulation data is not written to file
        }
        else  // standard write routine
        {
            _output_stream.write((const char*) matrixData, (size) * rows * cols);
        }
    }

    /*=={function}===================================================================================*/
    /*!
     *  void  init(std::string file_name)
     *
     *  brief:
     *  ------
     *  function initialize a matlab file
     *
     * \param[in]       file_name
     * \n        usage: file name
     * \n        range: not relevant
     *
     * \return
     */
    /*========================================================================================{end}==*/
    void init(std::string file_name, size_t dim)
    {
        const char Aclass[] = "A1 bt. ir1 na  Tj  re  ac  nt  so   r   y   ";  // special header string

        _file_name = file_name;

        if (_output_stream.is_open())
            _output_stream.close();

        // open new file
        _output_stream.open(file_name.c_str(), ios::binary | ios::trunc);
        if (_output_stream.fail())
          throw ModelicaSimulationError(DATASTORAGE, string("Failed to open results file ") + file_name);

        // write header matrix
        writeMatVer4Matrix("Aclass", 4, 11, Aclass, sizeof(char));

        // initialize help variables
        _uiValueCount = 0;
        _dataHdrPos = 0;
        _dataEofPos = 0;

        _doubleMatrixData1 = NULL;
        _doubleMatrixData2 = NULL;
        _stringMatrix = NULL;
        _pacString = NULL;
        _intMatrix = NULL;

        // allocate temp buffer for simulation data:
        // dim_1 (number of variables) + dim_2 (number of der. variables) + 1 (time)
        _doubleMatrixData2 = new double[dim + 1];
    }

    /*=={function}===================================================================================*/
    /*!
     *  void write(const value_type_p& v_list,double start_time,double end_time)
     *
     *  brief:
     *  ------
     *  function writes the parameters, which are constant over simulation time
     *
     * \param[in]       v_list
     * \n        usage: list of parameters
     * \n        range: not relevant
     *
     * \param[in]       start_time
     * \n        usage: simulation start time
     * \n        range: [1,7E-308 ; +2147483647]
     *
     * \param[in]       end_time
     * \n        usage: simulation end time
     * \n        range: [-2147483648 ; +2147483647]
     *
     * \return
     */
    /*========================================================================================{end}==*/
    virtual void write(const all_vars_t& v_list, double start_time, double end_time)
    {
        unsigned int uiParCount = get<0>(v_list).size() +get<1>(v_list).size()+get<2>(v_list).size()+ 1;  // all variables + time
        double *doubleHelpMatrix = NULL;

        // get memory and reset to zero
        _doubleMatrixData1 = new double[2 * uiParCount];
        memset(_doubleMatrixData1, 0, sizeof(double) * 2 * uiParCount);
        doubleHelpMatrix = _doubleMatrixData1;

        // first we have to put in start and stop time...
        *doubleHelpMatrix = start_time;
        *(doubleHelpMatrix + uiParCount) = end_time;
        doubleHelpMatrix++;

        // ...then the other real variables
        for (real_vars_t::const_iterator it = get<0>(v_list).begin(); it != get<0>(v_list).end(); ++it)
        {
            *doubleHelpMatrix = *(*it);
            *(doubleHelpMatrix + uiParCount) = *(*it);
            doubleHelpMatrix++;
        }
        // ...then the other int variables
        for (int_vars_t::const_iterator it = get<1>(v_list).begin(); it != get<1>(v_list).end(); ++it)
        {
            *doubleHelpMatrix = *(*it);
            *(doubleHelpMatrix + uiParCount) = *(*it);
            doubleHelpMatrix++;
        }
        // ...then the other bool variables
        for (bool_vars_t::const_iterator it = get<2>(v_list).begin(); it != get<2>(v_list).end(); ++it)
        {
            *doubleHelpMatrix = *(*it);
            *(doubleHelpMatrix + uiParCount) = *(*it);
            doubleHelpMatrix++;
        }

        // if matrix is complete, write to file!
        writeMatVer4Matrix("data_1", uiParCount, 2, _doubleMatrixData1, sizeof(double));

        // initialize pointer
        doubleHelpMatrix = NULL;

        // remember file position. it's the position of the "data_2" header
        // is needed to change header afterwards
        _dataHdrPos = _output_stream.tellp();
    }

    /*=={function}===================================================================================*/
    /*!
     *  void write(var_names_t& s_list,var_names_t& s_desc_list,var_names_t& s_parameter_list,var_names_t& s_desc_parameter_list)
     *
     *  brief:
     *  ------
     *  function writes names and descriptions of simulation variables and parameters
     *
     * \param[in]       s_list
     * \n        usage: list with names of the simulation variables
     * \n        range: not relevant
     *
     * \param[in]       s_desc_list
     * \n        usage: list with descriptions of the simulation variables
     * \n        range: not relevant
     *
     * \param[in]       s_parameter_list
     * \n        usage: list with names of the simulation parameters
     * \n        range: not relevant
     *
     * \param[in]       s_desc_parameter_list
     * \n        usage: list with descriptions of the simulation parameters
     * \n        range: not relevant
     *
     * \return
     */
    /*========================================================================================{end}==*/
    virtual void write(const all_names_t& s_list, const all_description_t& s_desc_list,const all_names_t& s_parameter_list, const all_description_t& s_desc_parameter_list)
    {
        unsigned int uilongest = 12;  // help variable for temp buffer size
        unsigned int uilongestName = 5;    // because of "Time"
        unsigned int uilongestDesc = 12;  // because of "Time in [s]"
        unsigned int uiVarCount = get<0>(s_list).size() +get<1>(s_list).size() +get<2>(s_list).size()  + get<0>(s_parameter_list).size() + get<1>(s_parameter_list).size() + get<2>(s_parameter_list).size()+ 1;  // all variables, all parameters + time
        unsigned int uiIndex = 2;
        int iCols = 0;
        char *stringHelpMatrix = NULL;
        int *intHelpMatrix = NULL;
        char *pacHelpString = NULL;

        // get longest string of the variable names
        for (var_names_t::const_iterator it = get<0>(s_list).begin(); it !=  get<0>(s_list).end(); ++it)
        {
            if (it->size() > uilongestName)
                uilongestName = it->size() + 1;  // +1 because of string end
        }
        for (var_names_t::const_iterator it = get<1>(s_list).begin(); it !=  get<1>(s_list).end(); ++it)
        {
            if (it->size() > uilongestName)
                uilongestName = it->size() + 1;  // +1 because of string end
        }
        for (var_names_t::const_iterator it = get<2>(s_list).begin(); it !=  get<2>(s_list).end(); ++it)
        {
            if (it->size() > uilongestName)
                uilongestName = it->size() + 1;  // +1 because of string end
        }

        // get longest string of the parameter names
        for (var_names_t::const_iterator it = get<0>(s_parameter_list).begin(); it != get<0>(s_parameter_list).end(); ++it)
        {
            if (it->size() > uilongestName)
                uilongestName = it->size() + 1;  // +1 because of string end
        }
        // get longest string of the parameter names
        for (var_names_t::const_iterator it = get<1>(s_parameter_list).begin(); it != get<1>(s_parameter_list).end(); ++it)
        {
            if (it->size() > uilongestName)
                uilongestName = it->size() + 1;  // +1 because of string end
        }
        // get longest string of the parameter names
        for (var_names_t::const_iterator it = get<2>(s_parameter_list).begin(); it != get<2>(s_parameter_list).end(); ++it)
        {
            if (it->size() > uilongestName)
                uilongestName = it->size() + 1;  // +1 because of string end
        }

        // get longest string of the variable descriptions
        for (var_names_t::const_iterator it = get<0>(s_desc_list).begin(); it != get<0>(s_desc_list).end(); ++it)
        {
            if (it->size() > uilongestDesc)
                uilongestDesc = it->size() + 1;  // +1 because of string end
        }
         // get longest string of the variable descriptions
        for (var_names_t::const_iterator it = get<1>(s_desc_list).begin(); it != get<1>(s_desc_list).end(); ++it)
        {
            if (it->size() > uilongestDesc)
                uilongestDesc = it->size() + 1;  // +1 because of string end
        }
         // get longest string of the variable descriptions
        for (var_names_t::const_iterator it = get<2>(s_desc_list).begin(); it != get<2>(s_desc_list).end(); ++it)
        {
            if (it->size() > uilongestDesc)
                uilongestDesc = it->size() + 1;  // +1 because of string end
        }

        // get longest string of the parameter descriptions
        for (var_names_t::const_iterator it = get<0>(s_desc_parameter_list).begin(); it != get<0>(s_desc_parameter_list).end(); ++it)
        {
            if (it->size() > uilongestDesc)
                uilongestDesc = it->size() + 1;  // +1 because of string end
        }
        for (var_names_t::const_iterator it = get<1>(s_desc_parameter_list).begin(); it != get<1>(s_desc_parameter_list).end(); ++it)
        {
            if (it->size() > uilongestDesc)
                uilongestDesc = it->size() + 1;  // +1 because of string end
        }
        for (var_names_t::const_iterator it = get<2>(s_desc_parameter_list).begin(); it != get<2>(s_desc_parameter_list).end(); ++it)
        {
            if (it->size() > uilongestDesc)
                uilongestDesc = it->size() + 1;  // +1 because of string end
        }

        // get longest string. is needed for temp buffer
        uilongest = max(uilongestName, uilongestDesc);

        // get memory and reset to zero
        _stringMatrix = new char[uiVarCount * uilongest];
        memset(_stringMatrix, 0, sizeof(char) * uiVarCount * uilongest);
        stringHelpMatrix = _stringMatrix;
        _pacString = new char[uilongest];
        memset(_pacString, 0, sizeof(char) * (uilongest));
        pacHelpString = _pacString;

        // first time ist written to "name" matrix...
        strncpy(stringHelpMatrix, "time", uilongestName);
        stringHelpMatrix += uilongestName;

        // ...followed by variable names...
        for (var_names_t::const_iterator it = get<0>(s_list).begin(); it != get<0>(s_list).end(); ++it)
        {
            strncpy(pacHelpString, it->c_str(), uilongestName);
            vFixVarName(pacHelpString, it->size());
            strncpy(stringHelpMatrix, pacHelpString, uilongestName);
            stringHelpMatrix += uilongestName;
        }
        for (var_names_t::const_iterator it = get<1>(s_list).begin(); it != get<1>(s_list).end(); ++it)
        {
            strncpy(pacHelpString, it->c_str(), uilongestName);
            vFixVarName(pacHelpString, it->size());
            strncpy(stringHelpMatrix, pacHelpString, uilongestName);
            stringHelpMatrix += uilongestName;
        }
        for (var_names_t::const_iterator it = get<2>(s_list).begin(); it != get<2>(s_list).end(); ++it)
        {
            strncpy(pacHelpString, it->c_str(), uilongestName);
            vFixVarName(pacHelpString, it->size());
            strncpy(stringHelpMatrix, pacHelpString, uilongestName);
            stringHelpMatrix += uilongestName;
        }

        // ...followed by parameter names
        for (var_names_t::const_iterator it = get<0>(s_parameter_list).begin(); it != get<0>(s_parameter_list).end(); ++it)
        {
            strncpy(pacHelpString, it->c_str(), uilongestName);
            vFixVarName(pacHelpString, it->size());
            strncpy(stringHelpMatrix, pacHelpString, uilongestName);
            stringHelpMatrix += uilongestName;
        }
         for (var_names_t::const_iterator it = get<1>(s_parameter_list).begin(); it != get<1>(s_parameter_list).end(); ++it)
        {
            strncpy(pacHelpString, it->c_str(), uilongestName);
            vFixVarName(pacHelpString, it->size());
            strncpy(stringHelpMatrix, pacHelpString, uilongestName);
            stringHelpMatrix += uilongestName;
        }
         for (var_names_t::const_iterator it = get<2>(s_parameter_list).begin(); it != get<2>(s_parameter_list).end(); ++it)
        {
            strncpy(pacHelpString, it->c_str(), uilongestName);
            vFixVarName(pacHelpString, it->size());
            strncpy(stringHelpMatrix, pacHelpString, uilongestName);
            stringHelpMatrix += uilongestName;
        }

        // write matrix to file
        writeMatVer4Matrix("name", (int) uilongestName, (int) uiVarCount, _stringMatrix, sizeof(char));

        // initialize pointer and reset to zero
        memset(_stringMatrix, 0, sizeof(char) * uiVarCount * uilongest);
        stringHelpMatrix = _stringMatrix;
        memset(_pacString, 0, sizeof(char) * (uilongest));
        pacHelpString = _pacString;

        // first description of time ist written to "name" matrix...
        strncpy(stringHelpMatrix, "Time in [s]", uilongestDesc);
        stringHelpMatrix += uilongestDesc;

        // ...followed by variable descriptions...
        for (var_names_t::const_iterator it = get<0>(s_desc_list).begin(); it != get<0>(s_desc_list).end(); ++it)
        {
            strncpy(pacHelpString, it->c_str(), uilongestDesc);
            vFixVarName(pacHelpString, it->size());
            strncpy(stringHelpMatrix, pacHelpString, uilongestDesc);
            stringHelpMatrix += uilongestDesc;
        }
        for (var_names_t::const_iterator it = get<1>(s_desc_list).begin(); it != get<1>(s_desc_list).end(); ++it)
        {
            strncpy(pacHelpString, it->c_str(), uilongestDesc);
            vFixVarName(pacHelpString, it->size());
            strncpy(stringHelpMatrix, pacHelpString, uilongestDesc);
            stringHelpMatrix += uilongestDesc;
        }
        for (var_names_t::const_iterator it = get<2>(s_desc_list).begin(); it != get<2>(s_desc_list).end(); ++it)
        {
            strncpy(pacHelpString, it->c_str(), uilongestDesc);
            vFixVarName(pacHelpString, it->size());
            strncpy(stringHelpMatrix, pacHelpString, uilongestDesc);
            stringHelpMatrix += uilongestDesc;
        }

        // ...followed by parameter descriptions...
        for (var_names_t::const_iterator it = get<0>(s_desc_parameter_list).begin(); it != get<0>(s_desc_parameter_list).end(); ++it)
        {
            strncpy(pacHelpString, it->c_str(), uilongestDesc);
            vFixVarName(pacHelpString, it->size());
            strncpy(stringHelpMatrix, pacHelpString, uilongestDesc);
            stringHelpMatrix += uilongestDesc;
        }
        for (var_names_t::const_iterator it = get<1>(s_desc_parameter_list).begin(); it != get<1>(s_desc_parameter_list).end(); ++it)
        {
            strncpy(pacHelpString, it->c_str(), uilongestDesc);
            vFixVarName(pacHelpString, it->size());
            strncpy(stringHelpMatrix, pacHelpString, uilongestDesc);
            stringHelpMatrix += uilongestDesc;
        }
        for (var_names_t::const_iterator it = get<2>(s_desc_parameter_list).begin(); it != get<2>(s_desc_parameter_list).end(); ++it)
        {
            strncpy(pacHelpString, it->c_str(), uilongestDesc);
            vFixVarName(pacHelpString, it->size());
            strncpy(stringHelpMatrix, pacHelpString, uilongestDesc);
            stringHelpMatrix += uilongestDesc;
        }

        // write matrix to file
        writeMatVer4Matrix("description", (int) uilongestDesc, (int) uiVarCount, _stringMatrix, sizeof(char));

        // initialize pointer
        stringHelpMatrix = NULL;
        pacHelpString = NULL;

        // get memory and reset to zero
        _intMatrix = new int[4 * uiVarCount];
        memset(_intMatrix, 0, sizeof(int) * 4 * uiVarCount);
        intHelpMatrix = _intMatrix;

        /*==========================================================================================================*/
        /* Die "dataInfo"-Matrix schluesselt die Speicherung der Simulationswerte in "data_1" und "data_2"
         *
         * Beispiel:
         * =========
         * int dataInfo(5,4)
         * 0 1 0 -1  # Time
         * 2 2 0 -1  # _dummy
         * 2 3 0 -1  # _derdummy
         * 1 2 0  0  # Parameter1
         * 2 4 0 -1  # Variable1
         *
         * Auszug aus einem Dymola-Export mit Erklaerung der Architektur:
         * ==============================================================
         * dataInfo(i,1)= j: name i data is stored in matrix "data_j".
         * (1,1)=0, means that name(1) is used as abscissa
         * for ALL data matrices!
         *
         * dataInfo(i,2)= k: name i data is stored in column abs(k) of matrix
         * data_j with sign(k) used as sign.
         *
         * dataInfo(i,3)= 0: Linear interpolation of the column data
         * = 1..4: Piecewise convex hermite spline interpolation
         * of the column data. Curve is differentiable upto
         * order 1..4. The spline is defined by a polygon.
         * It touches the polygon in the middle of every segment
         * and at the beginning and final point. Between such
         * points the spline is convex. The polygon is also the
         * convex envelope of the spline.
         *
         * dataInfo(i,4)= -1: name i is not defined outside of the defined time range
         * = 0: Keep first/last value outside of time range
         * = 1: Linear interpolation through first/last two points outside
         * of time range.
         */
         /*==========================================================================================================*/

        // time
        *intHelpMatrix++ = 2;   // according to Dymola-Spec the value should be 0. But in the Matlab export method of the C-Runtime the value is 2.
        *intHelpMatrix++ = 1;
        *intHelpMatrix++ = 0;
        *intHelpMatrix++ = -1;

        // dataInfo-code for all variables
        for (var_names_t::const_iterator it = get<0>(s_list).begin(); it != get<0>(s_list).end(); ++it)
        {
            *intHelpMatrix++ = 2;
            *intHelpMatrix++ = uiIndex++;
            *intHelpMatrix++ = 0;
            *intHelpMatrix++ = -1;
        }
        for (var_names_t::const_iterator it = get<1>(s_list).begin(); it != get<1>(s_list).end(); ++it)
        {
            *intHelpMatrix++ = 2;
            *intHelpMatrix++ = uiIndex++;
            *intHelpMatrix++ = 0;
            *intHelpMatrix++ = -1;
        }
        for (var_names_t::const_iterator it = get<2>(s_list).begin(); it != get<2>(s_list).end(); ++it)
        {
            *intHelpMatrix++ = 2;
            *intHelpMatrix++ = uiIndex++;
            *intHelpMatrix++ = 0;
            *intHelpMatrix++ = -1;
        }

        uiIndex = 2;

        // dataInfo-code for all parameters
        for (var_names_t::const_iterator it = get<0>(s_parameter_list).begin(); it != get<0>(s_parameter_list).end(); ++it)
        {
            *intHelpMatrix++ = 1;
            *intHelpMatrix++ = uiIndex++;
            *intHelpMatrix++ = 0;
            *intHelpMatrix++ = 0;
        }
        for (var_names_t::const_iterator it = get<1>(s_parameter_list).begin(); it != get<1>(s_parameter_list).end(); ++it)
        {
            *intHelpMatrix++ = 1;
            *intHelpMatrix++ = uiIndex++;
            *intHelpMatrix++ = 0;
            *intHelpMatrix++ = 0;
        }
        for (var_names_t::const_iterator it = get<2>(s_parameter_list).begin(); it != get<2>(s_parameter_list).end(); ++it)
        {
            *intHelpMatrix++ = 1;
            *intHelpMatrix++ = uiIndex++;
            *intHelpMatrix++ = 0;
            *intHelpMatrix++ = 0;
        }

        // write matrix to file
        writeMatVer4Matrix("dataInfo", 4, uiVarCount, _intMatrix, sizeof(int));

        // initialize pointer
        intHelpMatrix = NULL;
    }

    /*=={function}===================================================================================*/
    /*!
     *  void write(const value_type_v& v_list,const value_type_dv& v2_list,double time)
     *
     *  brief:
     *  ------
     *  function writes variables, which are NOT constant over simulation time
     *
     * \param[in]       v_list
     * \n        usage: list with names of the simulation variables
     * \n        range: not relevant
     *
     * \param[in]       v2_list
     * \n        usage: list with names of the derivated simulation variables
     * \n        range: not relevant
     *
     * \param[in]       time
     * \n        usage: actual simulation time
     * \n        range: [1,7E-308 ; +2147483647]
     *
     * \return
     */
    /*========================================================================================{end}==*/
    virtual void write(const all_vars_time_t& v_list,const neg_all_vars_t& neg_v_list)
    {
        unsigned int uiVarCount = get<0>(v_list).size() + get<1>(v_list).size() + get<2>(v_list).size() + 1;  // alle Variablen, alle abgeleiteten Variablen und die Zeit
        double *doubleHelpMatrix = NULL;

        _uiValueCount++;

        // reset tempbuffer to zero
        memset(_doubleMatrixData2, 0, sizeof(double) * uiVarCount);
        doubleHelpMatrix = _doubleMatrixData2;

        // first time ist written to "data_2" matrix...
        *doubleHelpMatrix = get<3>(v_list);
        doubleHelpMatrix++;

        // ...followed by real variable values...
        /*for (real_vars_t::const_iterator it = get<0>(v_list).begin(); it != get<0>(v_list).end(); ++it)
        {
            *doubleHelpMatrix = *(*it);
            doubleHelpMatrix++;
        }*/

        std::transform(get<0>(v_list).begin(), get<0>(v_list).end(), get<0>(neg_v_list).begin(),
            doubleHelpMatrix, WriteOutputVar<double>());


        // ...followed by int variable values.
        /*for (int_vars_t::const_iterator it = get<1>(v_list).begin(); it != get<1>(v_list).end(); ++it)
        {
            *doubleHelpMatrix = *(*it);
            doubleHelpMatrix++;
        }*/
            size_t nReal = get<0>(v_list).size();
        std::transform(get<1>(v_list).begin(), get<1>(v_list).end(), get<1>(neg_v_list).begin(),
            doubleHelpMatrix + nReal, WriteOutputVar<int>());
        // ...followed by bool variable values.
        /*for (bool_vars_t::const_iterator it = get<2>(v_list).begin(); it != get<2>(v_list).end(); ++it)
        {
            *doubleHelpMatrix = *(*it);
            doubleHelpMatrix++;
        }
        */
             size_t nInt = get<1>(v_list).size();
        std::transform(get<2>(v_list).begin(), get<2>(v_list).end(), get<2>(neg_v_list).begin(),
            doubleHelpMatrix+nReal+nInt, WriteOutputVar<bool>());

        // write matrix to file
        writeMatVer4Matrix("data_2", uiVarCount, _uiValueCount, _doubleMatrixData2, sizeof(double));

        // initialize pointer
        doubleHelpMatrix = NULL;
    }

    /*=================================================================================*/
    /*
     *    the following functions are not used, but must be declared
     */
    /*=================================================================================*/
    void write(const char c)
    {

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
        //_curser_position=0;
        //_output_stream.seekp(_curser_position);
    }

 protected:
    std::ofstream _output_stream;
    std::ofstream::pos_type _dataHdrPos;
    std::ofstream::pos_type _dataEofPos;
    unsigned int _curser_position;
    unsigned int _uiValueCount;
    std::string _file_name;
    double *_doubleMatrixData1;
    double *_doubleMatrixData2;
    char *_stringMatrix;
    char *_pacString;
    int *_intMatrix;
    vector<string> _var_outputs;
};
/** @} */ // end of dataexchangePolicies
