/*
Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/* tables-h 
 * Author : PA
 * 
 * This file contain declarations for table interpolation functions used by
 * Modelica.Blocks.Source.CombiTable. The are the equivalent implementation of Dymolas
 * functions dymTableTimeIni2, etc.
 */
 
#ifdef __cplusplus
extern "C" 
{
#endif

int omcTableTimeIni(double timeIn, double startTime,int ipoType,int expoType,
	char *tableName,char* fileName, double *table,int tableDim1,int tableDim2,int colWise);

double omcTableTimeIpo(int tableID,int icol,double timeIn);

double omcTableTimeTmax(int tableID);

double omcTableTimeTmin(int tableID);

#ifdef __cplusplus
} //end extern "C"

#include <string>

class InterpolationTable {
	
public:
	InterpolationTable(double time,double startTime, int ipoType, int expoType,
			char* tableName, char* fileName, double *table, int tableDim1, int tableDim2,int colWise);
	InterpolationTable();
	~InterpolationTable();
	double Interpolate(double time, int col);
	double MaxTime();
	double MinTime();
	char* getTableName() {return tableName_;};
	char* getFileName() {return fileName_;};
	double* getData() {return data_;};
protected: 
    void readMatFile(std::string& fileName, std::string& columnName);
    void readTextFile(std::string& fileName, std::string& columnName);
    void readCSVFile(std::string& fileName, std::string& columnName);
    
    bool isTableHeaderNamed(std::string line,std::string& columnName);
    bool readTableHeader(std::string line);    
    double getElt(int row, int col);
    double extrapolate(double time,int col,bool beforeData);

	char* fileName_;
	char* tableName_;    
	double time_;
	double startTime_;
	int ipoType_;
	int expoType_;
	int colWise_;
	
    double *data_;
    int nRows_;
    int nCols_;
};


#endif

