/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "util/omc_error.h"
#include "simulation_data.h"
#include "openmodelica_func.h"
#include "simulation/solver/external_input.h"
#include "simulation/options.h"
#include "simulation/solver/model_help.h"
#include <iostream>
#include <sstream>
#include <string>
#include <fstream>
#include <vector>
#include <algorithm>
#include <iomanip>
#include <stdlib.h>
#include <math.h>
#include <ctime>
#include "omc_config.h"
#include <cmath>
#include "dataReconciliation.h"

extern "C"
{
int dgesv_(int *n, int *nrhs, double *a, int *lda, int *ipiv, double *b, int *ldb, int *info);
int dgemm_(char *transa, char *transb, int *m, int *n, int *k, double *alpha, double *a, int *lda,
		double *b, int *ldb, double *beta, double *c, int *ldc);
int dgetrf_(int *m, int *n, double *a, int *lda, int *ipiv, int *info);
int dgetri_(int *n, double *a, int *lda, int *ipiv, double *work, int *lwork, int *info);
int dscal_(int *n, double *da, double *dx, int *incx);
int dcopy_(int *n, double *dx, int *incx, double *dy, int *incy);
}


using namespace std;

extern "C" {

// only 200 values of chisquared x^2 values are added with degree of freedom
static double chisquaredvalue[200] = {3.84146,5.99146,7.81473,9.48773,11.0705,12.5916,14.0671,15.5073,16.919,18.307,19.6751,21.0261,22.362,23.6848,24.9958,26.2962,27.5871,28.8693,30.1435,31.4104,32.6706,33.9244,35.1725,36.415,37.6525,38.8851,40.1133,41.3371,42.557,43.773,44.9853,46.1943,47.3999,48.6024,49.8018,50.9985,52.1923,53.3835,54.5722,55.7585,56.9424,58.124,59.3035,60.4809,61.6562,62.8296,64.0011,65.1708,66.3386,67.5048,68.6693,69.8322,70.9935,72.1532,73.3115,74.4683,75.6237,76.7778,77.9305,79.0819,80.2321,81.381,82.5287,83.6753,84.8206,85.9649,87.1081,88.2502,89.3912,90.5312,91.6702,92.8083,93.9453,95.0815,96.2167,97.351,98.4844,99.6169,100.749,101.879,103.01,104.139,105.267,106.395,107.522,108.648,109.773,110.898,112.022,113.145,114.268,115.39,116.511,117.632,118.752,119.871,120.99,122.108,123.225,124.342,125.458,126.574,127.689,128.804,129.918,131.031,132.144,133.257,134.369,135.48,136.591,137.701,138.811,139.921,141.03,142.138,143.246,144.354,145.461,146.567,147.674,148.779,149.885,150.989,152.094,153.198,154.302,155.405,156.508,157.61,158.712,159.814,160.915,162.016,163.116,164.216,165.316,166.415,167.514,168.613,169.711,170.809,171.907,173.004,174.101,175.198,176.294,177.39,178.485,179.581,180.676,181.77,182.865,183.959,185.052,186.146,187.239,188.332,189.424,190.516,191.608,192.7,193.791,194.883,195.973,197.064,198.154,199.244,200.334,201.423,202.513,203.602,204.69,205.779,206.867,207.955,209.042,210.13,211.217,212.304,213.391,214.477,215.563,216.649,217.735,218.82,219.906,220.991,222.076,223.16,224.245,225.329,226.413,227.496,228.58,229.663,230.746,231.829,232.912};

struct csvData {
	int linecount;
	int rowcount;
	int columncount;
	vector<double> xdata;
	vector<double> sxdata;
	vector<string> headers;
	vector< vector<string> > rx;
};

struct matrixData {
	int rows;
	int column;
	double * data;
};

struct inputData {
	int rows;
	int column;
	double * data;
	vector<int> index;
};

/*
 * Function which reads the csv file
 * and stores the covariance matrix Sx for DataReconciliation
 */
csvData readcsvfiles(const char * filename, ofstream & logfile)
{
	ifstream ip(filename);
	string line;
	vector<double> xdata;
	vector<double> vals;
	vector<string> names;
	vector< vector<string> > rx;
	int Sxrowcount=0;
	int linecount=1;
	int Sxcolscount=0;
	bool flag=false;
	int myarraycount=0;
	if(!ip.good())
	{
		//errorStreamPrint(LOG_STDOUT, 0, "file name not found %s.",filename);
		logfile << "|  error   |   " << "file name not found " << filename << "\n";
		logfile.close();
		exit(1);
	}
	while(ip.good())
	{
		getline(ip,line);
		if(linecount>1 && !line.empty())
		{
			//cout << "array info:" << line << "\n";
			std::replace(line.begin(), line.end(), ';', ' ');
			std::replace(line.begin(), line.end(), ',', ' ');
			stringstream ss(line);
			string temp;
			int skip=0;
			while(ss >> temp){
				if(skip==0)
				{
					names.push_back(temp.c_str());
					Sxrowcount++;
				}
				if(skip>0){
					//cout << "check temp:" << temp << " double" << atof(temp.c_str()) <<"\n";
					vals.push_back(atof(temp.c_str()));
					if(flag==false){
						Sxcolscount++;
					}
				}
				skip++;
			}
			flag=true;
			//Sxrowcount++;
		}
		linecount++;
	}
	//cout << "csvdata header:" << names[0] << names[1] << names[2] << "";
	//cout << "linecount:" << linecount << " " << "rowcount :" << Sxrowcount << " " << "colscount:" << Sxcolscount << "\n";
	csvData  data={linecount,Sxrowcount,Sxcolscount,xdata,vals,names,rx};
	return data;
}
/*
 * function which returns the index pos
 * of input variables
 */
int getVariableIndex(vector<string> headers, string name, ofstream & logfile)
{
	int pos=-1;
	for(unsigned int i=0; i<headers.size(); i++)
	{
		//logfile << "founded headers " << headers[i] << i << "\n";
		if(strcmp(headers[i].c_str(),name.c_str())==0)
		{
			pos = i;
			break;
		}
	}
	//logfile << "founded pos " << name << ": " << pos << "\n";
	if(pos==-1)
	{
		//logfile << "Variable Name not Matched :" << name;
		logfile << "|  error   |   " << "CoRelation-Coefficient Variable Name not Matched:  " << name << " ,getVariableIndex() failed!"<< "\n";
		logfile.close();
		exit(1);
	}
	return pos;
}

/*
 * Function which reads the csv file
 * and stores the initial measured value X and HalfWidth confidence
 * interval Wx and also the input variable names
 */
csvData readcsvInputs(const char * filename, ofstream & logfile)
{
	ifstream ip(filename);
	string line;
	vector<double> xdata;
	vector<double> sxdata;
	vector<string> names;
	//vector<double> rx_ik;
	vector< vector<string> > rx;
	int Sxrowcount=0;
	int linecount=1;
	int Sxcolscount=0;
	bool flag=false,rx_ik=false;
	int myarraycount=0;
	if(!ip.good())
	{
		//errorStreamPrint(LOG_STDOUT, 0, "file name not found %s.",filename);
		logfile << "|  error   |   " << "file name not found " << filename << "\n";
		logfile.close();
		exit(1);
	}
	while(ip.good())
	{
		getline(ip,line);
		vector<string> t1;
		if(linecount>1 && !line.empty())
		{
			//logfile << "array info:" << line << "\n";
			std::replace(line.begin(), line.end(), ';', ' ');
			std::replace(line.begin(), line.end(), ',', ' ');
			stringstream ss(line);
			string temp;
			int skip=0;
			while(ss >> temp){
				if(skip==0)
				{
					names.push_back(temp.c_str());
					Sxrowcount++;
					if(flag==false){
						Sxcolscount++;
					}
				}
				if(skip==1)
				{
					//logfile << "xdata" << temp << " double" << atof(temp.c_str()) <<"\n";
					xdata.push_back(atof(temp.c_str()));
					if(flag==false){
						Sxcolscount++;
					}
				}
				if(skip==2){
					//logfile << "sxdata" << temp << " double" << atof(temp.c_str()) <<"\n";
					sxdata.push_back(atof(temp.c_str()));
					if(flag==false){
						Sxcolscount++;
					}
				}

				if(skip>2)
				{
					//logfile << "found xi " << line << "\n";
					t1.push_back(temp.c_str());
					rx_ik=true;
				}
				skip++;
			}
			flag=true;
			//Sxrowcount++;
		}
		if(rx_ik==true)
		{
			rx.push_back(t1);
		}
		linecount++;
	}
	//logfile << "csvdata header:" << "header length: " << names.size() << "   " << names[0] << names[1] << names[2] << "" << "\n";
	//logfile << "linecount:" << linecount << " " << "rowcount :" << Sxrowcount << " " << "colscount:" << Sxcolscount << "\n";
	csvData  data={linecount,Sxrowcount,Sxcolscount,xdata,sxdata,names,rx};
	return data;
}

/*
 * Function which arranges the elements in column major
 */
void initColumnMatrix(vector<double> data, int rows, int cols, double * tempSx)
{
	for (int i=0; i<rows; i++)
	{
		for (int j=0; j<cols;j++)
		{
			// store the matrix in column order
			tempSx[j+i*rows]=data[i+j*rows];
		}
	}
}

/*
 * Function to print and debug whether the matrices are stored in column major
 */
void printColumnAlginment(double * matrix, int rows, int cols, string name)
{
	cout << "\n" << "************ "<< name << " **********" << "\n";
	for (int i=0; i < rows*cols ; i++)
	{
		cout << matrix[i] << " ";
	}
	cout << "\n";
}

/*
 * Function to Print the matrix in row based format
 */
void printMatrix(double* matrix, int rows, int cols, string name, ofstream& logfile)
{
	logfile << "\n" << "************ "<< name << " **********" <<"\n";
	for (int i=0;i<rows; i++)
	{
		for (int j=0;j<cols;j++)
		{
			//cout << setprecision(5);
			logfile << std::right << setw(15) << matrix[i+j*rows];
			logfile.flush();
		}
		logfile << "\n";
	}
	logfile << "\n";
}

/*
 *
 Function to Print the matrix in row based format with headers
 */
void printMatrixWithHeaders(double* matrix, int rows, int cols, vector<string> headers, string name, ofstream& logfile)
{
	logfile << "\n" << "************ "<< name << " **********" <<"\n";
	for (int i=0;i<rows; i++)
	{
		logfile << std::right << setw(10) << headers[i];
		for (int j=0;j<cols;j++)
		{
			//cout << setprecision(5);
			logfile << std::right << setw(15) << matrix[i+j*rows];
			logfile.flush();
			//printf("% .5e ", matrix[i+j*rows]);
		}
		logfile << "\n";
	}
	logfile << "\n";
}

/*
 *Function to Print the vecomatrix in row based format with headers
 *based on vector arrays
 */
void printVectorMatrixWithHeaders(vector<double> matrix, int rows, int cols, vector<string> headers, string name, ofstream& logfile)
{
	logfile << "\n" << "************ "<< name << " **********" <<"\n";
	for (int i=0;i<rows; i++)
	{
		logfile << std::right << setw(10) << headers[i];
		for (int j=0;j<cols;j++)
		{
			//cout << setprecision(5);
			logfile << std::right << setw(15) << matrix[i+j*rows];
			logfile.flush();
			//printf("% .5e ", matrix[i+j*rows]);
		}
		logfile << "\n";
	}
	logfile << "\n";
}

/*
 *
 Function Which gets the diagonal elements of the matrix
 */
void getDiagonalElements(double *matrix, int rows, int cols, double* result)
{
	int k=0;
	for (int i=0;i<rows; i++)
	{
		for (int j=0;j<cols;j++)
		{
			if(i==j)
			{
				result[k++] = matrix[i+j*rows];
			}
		}
	}
}

/*
 * Function to transpose the Matrix
 */
void transposeMatrix(double * jacF, double * jacFT, int rows, int cols)
{
	for (int i=0;i<rows; i++)
	{
		for (int j=0;j<cols;j++)
		{
			// Perform matrix transpose store the elements in column major
			jacFT[i*cols+j]= jacF[i+j*rows] ;
		}
	}
}


/*
 * Matrix Multiplication using dgemm LaPack routine
 */
void solveMatrixMultiplication(double *matrixA, double *matrixB, int rowsa, int colsa, int rowsb, int colsb , double *matrixC, ofstream & logfile)
{
	char trans = 'N';
	double one = 1.0, zero = 0.0;
	int rowsA = rowsa;
	int colsA = colsa;
	int rowsB = rowsb;
	int colsB = colsb;
	int common = colsa;

	if(colsA!=rowsB)
	{
		//cout << "\n Error: Column of First Matrix not equal to Rows  of Second Matrix \n ";
		//errorStreamPrint(LOG_STDOUT, 0, "solveMatrixMultiplication() Failed!, Column of First Matrix not equal to Rows of Second Matrix %i != %i.",colsA,rowsB);
		logfile << "|  error   |   " << "solveMatrixMultiplication() Failed!, Column of First Matrix not equal to Rows of Second Matrix " << colsA << " != "<< rowsB <<  "\n";
		logfile.close();
		exit(1);
	}
	// solve matrix multiplication using dgemm_ LAPACK routine
	dgemm_(&trans, &trans, &rowsA, &colsB, &common, &one, matrixA, &rowsA, matrixB, &common, &zero, matrixC, &rowsA);
}

/*
 * Solve the Linear System A*x=b using LAPACK Solver routine dgesv_
 */
void solveSystemFstar(int n, int nhrs, double * tmpMatrixD, double * tmpMatrixC, ofstream & logfile)
{
	int N=n; // number of rows of Matrix A
	int NRHS=nhrs;  // number of columns of Matrix B
	int LDA=N;
	int LDB=N;
	int ipiv[N];
	int info;
	// call the external function
	dgesv_( &N, &NRHS, tmpMatrixD, &LDA, ipiv, tmpMatrixC, &LDB, &info);
	if( info > 0 ) {
		//cout << "The solution could not be computed, The info satus is : " << info;
		//errorStreamPrint(LOG_STDOUT, 0, "solveSystemFstar() Failed !, The solution could not be computed, The info satus is %i.", info);
		logfile << "|  error   |   " << "solveSystemFstar() Failed !, The solution could not be computed, The info satus is" << info << "\n";
		logfile.close();
		exit(1);
	}
}

/*
 * Solve the matrix Subtraction of two matrices
 */
void solveMatrixSubtraction(matrixData A, matrixData B, double * result, ofstream & logfile)
{
	if(A.rows!=B.rows && A.column!=B.column)
	{
		//cout << "The Matrix Dimensions are not equal to Compute ! \n";
		//errorStreamPrint(LOG_STDOUT, 0, "solveMatrixSubtraction() Failed !, The Matrix Dimensions are not equal to Compute ! %i != %i.", A.rows,B.rows);
		logfile << "|  error   |   " << "solveMatrixSubtraction() Failed !, The Matrix Dimensions are not equal to Compute" << A.rows << " != " << B.rows << "\n";
		logfile.close();
		exit(1);
	}
	//printColumnAlginment(A.data,A.rows,A.column,"A-Matrix");
	//printColumnAlginment(B.data,B.rows,B.column,"B-Matrix");

	// subtract elements in cloumn major
	for(int i=0; i < A.rows*A.column; i++)
	{
		result[i]=A.data[i]-B.data[i];
	}
}

/*
 * Solve the matrix addition of two matrices
 */
matrixData solveMatrixAddition(matrixData A, matrixData B, ofstream & logfile)
{
	double* result = (double*)calloc(A.rows*A.column,sizeof(double));
	if(A.rows!=B.rows && A.column!=B.column)
	{
		//cout << "The Matrix Dimensions are not equal to Compute ! \n";
		//errorStreamPrint(LOG_STDOUT, 0, "solveMatrixAddition() Failed !, The Matrix Dimensions are not equal to Compute ! %i != %i.", A.rows,B.rows);
		logfile << "|  error   |   " << "solveMatrixAddition() Failed !, The Matrix Dimensions are not equal to Compute" << A.rows << " != " << B.rows << "\n";
		logfile.close();
		exit(1);
	}
	//printColumnAlginment(A.data,A.rows,A.column,"A-Matrix");
	//printColumnAlginment(B.data,B.rows,B.column,"B-Matrix");
	// Add the elements in cloumn major
	for(int i=0; i < A.rows*A.column; i++)
	{
		result[i]=A.data[i]+B.data[i];
	}
	matrixData tmpadd_a_b = {A.rows,A.column,result};
	return tmpadd_a_b;
}

/*
 * Function which Calculates the Matrix Multiplication
 * of (Sx*Ft)*Fstar
 */
matrixData Calculate_Sx_Ft_Fstar(matrixData Sx, matrixData Ft, matrixData Fstar, ofstream & logfile)
{
	// Sx*Ft
	double* tmpMatrixA = (double*)calloc(Sx.rows*Ft.column,sizeof(double));
	solveMatrixMultiplication(Sx.data,Ft.data,Sx.rows,Sx.column,Ft.rows,Ft.column,tmpMatrixA,logfile);
	//printMatrix1(tmpMatrixA,Sx.rows,Ft.column,"Reconciled-(Sx*Ft)");
	//printMatrix1(Fstar.data,Fstar.rows,Fstar.column,"REconciled-FStar");

	//(Sx*Ft)*Fstar
	double* tmpMatrixB = (double*)calloc(Sx.rows*Fstar.column,sizeof(double));
	solveMatrixMultiplication(tmpMatrixA,Fstar.data,Sx.rows,Ft.column,Fstar.rows,Fstar.column,tmpMatrixB,logfile);
	matrixData rhsdata= {Sx.rows,Fstar.column,tmpMatrixB};

	free(tmpMatrixA);
	free(tmpMatrixB);
	return rhsdata;
}

/*
 * Solves the system
 * recon_x = x - (Sx*Ft*fstar)
 */
matrixData solveReconciledX(matrixData x, matrixData Sx, matrixData Ft, matrixData Fstar, ofstream& logfile)
{
	// Sx*Ft
	double* tmpMatrixAf = (double*)calloc(Sx.rows*Ft.column,sizeof(double));
	solveMatrixMultiplication(Sx.data,Ft.data,Sx.rows,Sx.column,Ft.rows,Ft.column,tmpMatrixAf,logfile);
	//printMatrix(tmpMatrixAf,Sx.rows,Ft.column,"Sx*Ft");
	//(Sx*Ft)*fstar
	double* tmpMatrixBf = (double*)calloc(Sx.rows*Fstar.column,sizeof(double));
	solveMatrixMultiplication(tmpMatrixAf,Fstar.data,Sx.rows,Ft.column,Fstar.rows,Fstar.column,tmpMatrixBf,logfile);
	//printMatrix(tmpMatrixBf,Sx.rows,Fstar.column,"(Sx*Ft*fstar)");

	matrixData rhs= {Sx.rows,Fstar.column,tmpMatrixBf};
	//matrixData rhs = Calculate_Sx_Ft_Fstar(Sx,Ft,Fstar);

	double* reconciledX = (double*)calloc(x.rows*x.column,sizeof(double));
	solveMatrixSubtraction(x,rhs,reconciledX,logfile);
	//printMatrix(reconciledX,x.rows,x.column,"reconciled X^cap ===> (x - (Sx*Ft*fstar))");
	if(ACTIVE_STREAM(LOG_JAC))
	{
		logfile << "Calculations of Reconciled_x ==> (x - (Sx*Ft*f*))" << "\n";
		logfile << "====================================================";
		printMatrix(tmpMatrixAf,Sx.rows,Ft.column,"Sx*Ft",logfile);
		printMatrix(tmpMatrixBf,Sx.rows,Fstar.column,"(Sx*Ft*f*)",logfile);
		printMatrix(reconciledX,x.rows,x.column,"x - (Sx*Ft*f*))",logfile);
		logfile << "***** Completed ****** \n\n";
	}
	matrixData recon_x = {x.rows,x.column,reconciledX};
	//free(reconciledX);
	free(tmpMatrixAf);
	free(tmpMatrixBf);
	return recon_x;
}

/*
 * Solves the system
 * recon_Sx = Sx - (Sx*Ft*Fstar)
 */
matrixData solveReconciledSx(matrixData Sx, matrixData Ft, matrixData Fstar, ofstream& logfile)
{
	// Sx*Ft
	double* tmpMatrixA = (double*)calloc(Sx.rows*Ft.column,sizeof(double));
	solveMatrixMultiplication(Sx.data,Ft.data,Sx.rows,Sx.column,Ft.rows,Ft.column,tmpMatrixA, logfile);
	//printMatrix(tmpMatrixA,Sx.rows,Ft.column,"Reconciled-(Sx*Ft)");
	//printMatrix(Fstar.data,Fstar.rows,Fstar.column,"REconciled-FStar");

	//(Sx*Ft)*Fstar
	double* tmpMatrixB = (double*)calloc(Sx.rows*Fstar.column,sizeof(double));
	solveMatrixMultiplication(tmpMatrixA,Fstar.data,Sx.rows,Ft.column,Fstar.rows,Fstar.column,tmpMatrixB, logfile);
	//printMatrix(tmpMatrixB,Sx.rows,Fstar.column,"Reconciled-(Sx*Ft*Fstar)");

	matrixData rhs= {Sx.rows,Fstar.column,tmpMatrixB};

	//matrixData rhs = Calculate_Sx_Ft_Fstar(Sx,Ft,Fstar);
	double* reconciledSx = (double*)calloc(Sx.rows*Sx.column,sizeof(double));
	solveMatrixSubtraction(Sx,rhs,reconciledSx, logfile);
	//printMatrix(reconciledSx,Sx.rows,Sx.column,"reconciled Sx ===> (Sx - (Sx*Ft*Fstar))");
	if(ACTIVE_STREAM(LOG_JAC))
	{
		logfile << "Calculations of Reconciled_Sx ===> (Sx - (Sx*Ft*F*))" << "\n";
		logfile << "============================================";
		printMatrix(tmpMatrixA,Sx.rows,Ft.column,"(Sx*Ft)",logfile);
		printMatrix(tmpMatrixB,Sx.rows,Fstar.column,"(Sx*Ft*F*)",logfile);
		printMatrix(reconciledSx,Sx.rows,Sx.column,"Sx - (Sx*Ft*F*))",logfile);
		logfile << "***** Completed ****** \n\n";
	}
	matrixData recon_sx ={Sx.rows,Sx.column,reconciledSx};
	//free(reconciledSx);
	free(tmpMatrixA);
	free(tmpMatrixB);
	return recon_sx;
}

/*
 * Function Which Computes the
 * Jacobian Matrix F
 */
matrixData getJacobianMatrixF(DATA* data, threadData_t *threadData, ofstream & logfile)
{
	// initialize the jacobian call
	const int index = data->callback->INDEX_JAC_F;
	ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[index]);
	data->callback->initialAnalyticJacobianF(data, threadData, jacobian);
	int cols = jacobian->sizeCols;
	int rows = jacobian->sizeRows;
	if(cols == 0) {
		//errorStreamPrint(LOG_STDOUT, 0, "Cannot Compute Jacobian Matrix F");
		logfile << "|  error   |   " << "Cannot Compute Jacobian Matrix F" << "\n";
		logfile.close();
		exit(1);
	}
	double* jacF = (double*)calloc(rows*cols,sizeof(double)); // allocate for Matrix F
	int k=0;
	for (int x=0; x < cols ; x++)
	{
		jacobian->seedVars[x] = 1.0;
		data->callback->functionJacF_column(data, threadData, jacobian, NULL);
		//cout << "Calculate one column\n:";
		for (int y=0; y < rows ; y++)
		{
			jacF[k++]=jacobian->resultVars[y];
		}
		jacobian->seedVars[x] = 0.0;
	}
	matrixData Fdata ={rows,cols,jacF};
	return Fdata;
}

/*
 * Function Which Computes the
 * Transpose of Jacobian Matrix FT
 */
matrixData getTransposeMatrix(matrixData jacF)
{
	int rows=jacF.column;
	int cols=jacF.rows;
	double* jacFT = (double*)calloc(rows*cols,sizeof(double)); // allocate for Matrix F-transpose
	int k=0;
	for (int i=0;i<jacF.rows; i++)
	{
		for (int j=0;j<jacF.column;j++)
		{
			// Perform matrix transpose store the elements in column major
			//cout << (i1*jacF.rows+j1) << " index :" << (i1+j1*jacF.rows) << " value is: " << jacF.data[i1+j1*jacF.rows] << "\n";
			jacFT[k++]= jacF.data[i+j*jacF.rows];

		}
	}
	matrixData Ft_data ={rows,cols,jacFT};
	return Ft_data;
}

/*
 * function which checks and reads
 * covariance matrix Sx from csv files
 * and stores the data in vector format
 */
csvData readCovarianceMatrixSx(DATA* data, threadData_t *threadData, ofstream & logfile)
{
	char * Sxfile = NULL;
	Sxfile = (char*)omc_flagValue[FLAG_DATA_RECONCILE_Sx];
	if(Sxfile==NULL)
	{
		//errorStreamPrint(LOG_STDOUT, 0, "Sx file not given (eg:-sx=filename.csv), DataReconciliation cannot be computed!.");
		logfile << "|  error   |   " << "Sx file not given (eg:-sx=filename.csv), DataReconciliation cannot be computed!.\n";
		logfile.close();
		exit(1);
	}
	//csvData Sx_result=readcsvfiles(Sxfile,logfile);
	csvData Sx_result=readcsvInputs(Sxfile,logfile);
	return Sx_result;
}

/*
 * Function which reads the vector
 * and assign to c pointer arrays
 */
matrixData getCovarianceMatrixSx(csvData Sx_result, DATA* data, threadData_t *threadData)
{
	double* tempSx = (double*)calloc(Sx_result.rowcount*Sx_result.columncount,sizeof(double));
	initColumnMatrix(Sx_result.sxdata , Sx_result.rowcount, Sx_result.columncount, tempSx);
	matrixData Sx_data = {Sx_result.rowcount,Sx_result.columncount,tempSx};
	return Sx_data;
}

/*
 * Function which Computes
 * covariance matrix Sx based on
 * Half width confidence interval provided by user
 * Sx=(Wxi/1.96)^2
 */

matrixData computeCovarianceMatrixSx(csvData Sx_result, DATA* data, threadData_t *threadData, ofstream & logfile)
{
	double* tempSx = (double*)calloc(Sx_result.sxdata.size()*Sx_result.sxdata.size(),sizeof(double));
	vector<double> tmpdata;
	int k=0;
	for (unsigned int i=0;i<Sx_result.sxdata.size(); i++)
	{
		double data = pow(Sx_result.sxdata[k]/1.96,2);
		for (unsigned int j=0;j<Sx_result.sxdata.size();j++)
		{
			if(i==j)
			{
				//tmpdata.push_back(pow(Sx_result.sxdata[k]/1.96,2));
				//k++;
				tmpdata.push_back(data);
			}
			else
			{
				tmpdata.push_back(0);
			}
			// logfile << " data " << count << "=="<< tmpdata[count++] << "\n";
		}
		k++;
	}
	//logfile << "tmpdatasize" << tmpdata.size() << "\n";
	//logfile << "Size of vector :" << Sx_result.rx.size() << "\n";

	/* check for corelation coefficient matrix and insert the elements in correct position*/
	for (unsigned int l=0; l < Sx_result.rx.size();l++)
	{
		int pos1;
		int pos2;
		double xi;
		double xk ;
		for(unsigned int m=0; m<Sx_result.rx[l].size();m++)
		{
			if(m==0)
			{
				pos1 = getVariableIndex(Sx_result.headers,Sx_result.rx[l][m],logfile);
				xi   =  tmpdata[(Sx_result.rowcount*pos1)+pos1];
				//logfile << "xi =>"<< pos1 << "= "<< xi << "\n";
			}

			if(m==1)
			{
				pos2 = getVariableIndex(Sx_result.headers,Sx_result.rx[l][m],logfile);
				xk   = tmpdata[(Sx_result.rowcount*pos2)+pos2];
				//logfile << "xk =>"<< pos2 << "= "<< xk << "\n";
			}
			if(m==2)
			{
				//logfile << "position:" << pos1 << ": " << pos2 << "\n";
				//logfile << "rx_ik" << Sx_result.rx[l][m] << "*" << xi << "*" << xk << "\n";
				//logfile << atof((Sx_result.rx[l][m]).c_str())*sqrt(xi)*sqrt(xk) << "\n";
				double tmprx = atof((Sx_result.rx[l][m]).c_str())*sqrt(xi)*sqrt(xk);
				// find the symmetric position and insert the elements
				//logfile << "final position :" << (Sx_result.rowcount*pos1)+pos2 << "value is: "<< tmprx << "\n";
				//logfile << "final position :" << (Sx_result.rowcount*pos2)+pos1 << "value is: "<< tmprx << "\n";
				tmpdata[(Sx_result.rowcount*pos1)+pos2]=tmprx;
				tmpdata[(Sx_result.rowcount*pos2)+pos1]=tmprx;
			}
		}
		//logfile << "\n";
	}
	initColumnMatrix(tmpdata , Sx_result.rowcount, Sx_result.rowcount, tempSx);
	matrixData Sx_data = {Sx_result.rowcount,Sx_result.rowcount,tempSx};
	return Sx_data;
}

/*
 * Function which reads the input data X from start Attribute
 * and also stores the index of input variables which are the
 * variables to be reconciled for Data Reconciliation
 */
inputData getInputDataFromStartAttribute(csvData Sx_result , DATA* data, threadData_t *threadData, ofstream & logfile)
{
	double *tempx = (double*)calloc(Sx_result.rowcount,sizeof(double));
	char ** knowns = (char**)malloc(data->modelData->nInputVars * sizeof(char*));
	vector<int> index;
	data->callback->inputNames(data, knowns);
	int headercount = Sx_result.headers.size();
	/* Read data from input vars which has start attribute value set as input */
	for (int h=0; h < headercount; h++)
	{
		tempx[h]=Sx_result.xdata[h];
		bool flag=false;
		for (int in=0; in < data->modelData->nInputVars; in++)
		{
			if(strcmp(knowns[in], Sx_result.headers[h].c_str()) == 0)
			{
				//tempx[h] = data->simulationInfo->inputVars[in];
				index.push_back(in);
				flag=true;
				//logfile << knowns[in] << "  start value :" << data->simulationInfo->inputVars[in] << "\n";
				//logfile << "fetch index :" << in << "\n";
			}
		}
		if(flag==false)
		{
			logfile << "|  error   |   " << "Input Variable Not matched or not generated: "<< Sx_result.headers[h] << " , getInputDataFromStartAttribute failed()! \n";
			logfile.close();
			exit(1);
		}
	}
	inputData x_data ={Sx_result.rowcount,1,tempx,index};
	free(knowns);
	return x_data;
}

/*
 * Function  which Copy Matrix
 * using dcopy_ LAPACK routine
 * this is mostly used when LAPACK routines override arrays
 */
matrixData copyMatrix(matrixData matdata)
{
	double * tmpcopymatrix = (double*)calloc(matdata.rows*matdata.column,sizeof(double));
	int n = matdata.rows*matdata.column;
	int inc = 1;
	dcopy_(&n,matdata.data,&inc,tmpcopymatrix,&inc);

	//  for (int i=0; i < matdata.rows*matdata.column; i++)
	//  {
	//	  tmpcopymatrix[i]=matdata.data[i];
	//  }
	matrixData tmpcopymatrixdata = {matdata.rows, matdata.column, tmpcopymatrix};
	return tmpcopymatrixdata;
}

/*
 * Function which scales the MAtrix with constant
 * dscal_ LAPACK_routine and result is updated in data
 * eg: alpha = 2, data=[2,4,5]
 * result = [4,8,10]
 */
void scaleVector(int rows, int cols, double alpha, double * data)
{
	int n=rows*cols;
	int inc=1;
	dscal_(&n, &alpha, data, &inc);
}

/*
 * Function which calculates the square root of elements
 * eg : a=[1,2,3,4]
 * result a = [srt(1),sqrt(2).......]
 */
void calculateSquareRoot(double * data, int length)
{
	for(int i=0; i<length; i++)
	{
		data[i]=sqrt(data[i]);
	}
}

/*
 * Function which calculates
 * J*=(recon_x-x)T*(Sx^-1)*(recon_x-x)+2.[f+F*(recon_x-x)]T*fstar
 * where T= transpose of matrix
 * and returns the converged value
 */

double solveConvergence(DATA* data, matrixData conv_recon_x, matrixData conv_recon_sx, inputData conv_x, matrixData conv_sx, matrixData conv_jacF, matrixData conv_vector_c, matrixData conv_fstar, ofstream & logfile)
{

	//printMatrix(conv_vector_c.data,conv_vector_c.rows,conv_vector_c.column,"Convergence_C(x,y)");
	//printMatrix(conv_fstar.data,conv_fstar.rows,conv_fstar.column,"Convergence_f*");
	//printMatrix(conv_recon_x.data,conv_recon_x.rows,conv_recon_x.column,"check_recon_x*");

	// calculate(recon_x-x)
	double* conv_data1 = (double*)calloc(conv_x.rows*conv_x.column,sizeof(double));
	matrixData conv_inputs = {conv_x.rows,conv_x.column,conv_x.data};
	solveMatrixSubtraction(conv_recon_x,conv_inputs,conv_data1,logfile);
	matrixData conv_data1result={conv_x.rows,conv_x.column,conv_data1};
	matrixData copy_reconx_x = copyMatrix(conv_data1result);

	//printMatrix(conv_inputs.data,conv_inputs.rows,conv_inputs.column,"check_inputs");
	//printMatrix(conv_data1result.data,conv_data1result.rows,conv_data1result.column,"(recon_X - X)");

	// calculate Transpose_(recon_x-x)
	matrixData conv_data1Transpose = getTransposeMatrix(conv_data1result);
	//printMatrix(conv_data1Transpose.data,conv_data1Transpose.rows,conv_data1Transpose.column,"Transpose(recon_X - X)");

	/* solves (Sx^-1)*(recon_x-x)
	 * Solve the inverse of matrix Sx using linear form
	 * Ax=b
	 * where A=Sx and b= (recon_x-x) to avoid inversion of Sx which is
	 * expensive
	 */
	solveSystemFstar(conv_sx.rows,1,conv_sx.data,conv_data1result.data,logfile);
	//printMatrix(conv_data1result.data,conv_sx.rows,conv_data1result.column,"inverse multiplication_without inverse");

	double *conv_tmpmatrixlhs = (double*)calloc(conv_data1Transpose.rows*conv_data1result.column,sizeof(double));
	/*
	 * Solve (recon_x-x)T*(Sx^-1)*(recon_x-x)
	 */
	solveMatrixMultiplication(conv_data1Transpose.data,conv_data1result.data,conv_data1Transpose.rows,conv_data1Transpose.column,conv_data1result.rows,conv_data1result.column,conv_tmpmatrixlhs,logfile);
	//printMatrix(conv_tmpmatrixlhs,conv_data1Transpose.rows,conv_data1result.column,"(recon_x-x)T*(Sx^-1)*(recon_x-x)");
	matrixData struct_conv_tmpmatrixlhs = {conv_data1Transpose.rows,conv_data1result.column,conv_tmpmatrixlhs};

	/*
	 * Solve rhs = 2.[f+F*(recon_x-x)]T*fstar
	 *
	 */
	// Calculate F*(recon_x-x)
	double * tmp_F_recon_x_x = (double*)calloc(conv_jacF.rows*copy_reconx_x.column,sizeof(double));
	solveMatrixMultiplication(conv_jacF.data, copy_reconx_x.data, conv_jacF.rows, conv_jacF.column, copy_reconx_x.rows, copy_reconx_x.column,tmp_F_recon_x_x, logfile);
	//printMatrix(tmp_F_recon_x_x,conv_jacF.rows,copy_reconx_x.column,"F*(recon_x-x)");
	matrixData mult_F_recon_x_x = {conv_jacF.rows,copy_reconx_x.column,tmp_F_recon_x_x};

	// Calculate f + F*(recon_x-x)
	matrixData add_f_F_recon_x_x = solveMatrixAddition(conv_vector_c, mult_F_recon_x_x, logfile);
	//printMatrix(add_f_F_recon_x_x.data,add_f_F_recon_x_x.rows,add_f_F_recon_x_x.column,"f + F*(recon_x-x)");

	matrixData transpose_add_f_F_recon_x_x = getTransposeMatrix(add_f_F_recon_x_x);
	//printMatrix(transpose_add_f_F_recon_x_x.data,transpose_add_f_F_recon_x_x.rows,transpose_add_f_F_recon_x_x.column,"transpose-[f + F*(recon_x-x)]");

	// calculate [f + F*(recon_x-x)]T*fstar
	double *conv_tmpmatrixrhs = (double*)calloc(transpose_add_f_F_recon_x_x.rows*conv_fstar.column,sizeof(double));
	solveMatrixMultiplication(transpose_add_f_F_recon_x_x.data, conv_fstar.data, transpose_add_f_F_recon_x_x.rows, transpose_add_f_F_recon_x_x.column, conv_fstar.rows, conv_fstar.column, conv_tmpmatrixrhs, logfile);
	//printMatrix(conv_tmpmatrixrhs, transpose_add_f_F_recon_x_x.rows, conv_fstar.column,"[f + F*(recon_x-x)]*fstar");

	// scale the matrix with 2*[f + F*(recon_x-x)]T*fstar
	scaleVector(transpose_add_f_F_recon_x_x.rows , conv_fstar.column, 2.0, conv_tmpmatrixrhs);
	//printMatrix(conv_tmpmatrixrhs, transpose_add_f_F_recon_x_x.rows, conv_fstar.column,"2*[f + F*(recon_x-x)]*fstar");
	matrixData struct_conv_tmpmatrixrhs= {transpose_add_f_F_recon_x_x.rows, conv_fstar.column,conv_tmpmatrixrhs};

	/*
	 * solve the final J*=J*=(recon_x-x)T*(Sx^-1)*(recon_x-x)+2.[f+F*(recon_x-x)]T*fstar
	 * J*=_struct_conv_tmpmatrixlhs + struct_conv_tmpmatrixrhs
	 */
	matrixData struct_Jstar= solveMatrixAddition(struct_conv_tmpmatrixlhs,struct_conv_tmpmatrixrhs, logfile);
	//printMatrix(struct_Jstar.data,struct_Jstar.rows,struct_Jstar.column,"J*",logfile);

	int r=data->modelData->nSetcVars; // number of setc equations
	double val=1.0/r;

	/*
	 * calculate J/r < epselon
	 */
	scaleVector(struct_Jstar.rows,struct_Jstar.column,val,struct_Jstar.data);
	//printMatrix(struct_Jstar.data,struct_Jstar.rows,struct_Jstar.column,"J*/r ");
	double convergedvalue=struct_Jstar.data[0];

	//  free(struct_Jstar.data);
	//  free(struct_conv_tmpmatrixrhs.data);
	//  free(conv_tmpmatrixrhs);
	//  free(transpose_add_f_F_recon_x_x.data);
	//  free(add_f_F_recon_x_x.data);
	//  free(transpose_add_f_F_recon_x_x.data);
	//  free(mult_F_recon_x_x.data);
	//  free(tmp_F_recon_x_x);
	//  free(struct_conv_tmpmatrixlhs.data);
	//  free(conv_tmpmatrixlhs);
	//  free(conv_data1Transpose.data);
	//  free(copy_reconx_x.data);
	//  free(conv_data1result.data);
	//  free(conv_data1);

	return convergedvalue;
}

/*
 * Example Function which performs matrix inverse
 * using dgetri_ and dgetrf_ LAPACK routine
 * which is expensive one and not recommended
 * use it when no other way to compute it
 */
void checkExpensiveMatrixInverse()
{
	double  newval[3*3]={3,2,0,
			0,0,1,
			2,-2,1};

	int N=3;
	int LDA=N;
	int LDB=N;
	int ipiv[N];
	int info=1;
	int LWORK =N;
	double * WORK = (double*)calloc(LWORK,sizeof(double));

	dgetrf_(&N,&N,newval,&N,ipiv,&info);
	dgetri_(&N,newval,&N,ipiv,WORK,&LWORK,&info);
	//printMatrix(newval,3,3,"Expensive_Matrix_Inverse");
}

/*
 * Function which performs matrix inverse without performing
 * actual matrix inverse, Instead use the dgesv to get result
 * Ax=b where matrix mutiplication of x=bA gives the inversed
 * mutiplication result b with A inverse
 */
void checkInExpensiveMatrixInverse(ofstream & logfile)
{
	double newchecksx[3*3]={1,1,1,
			0,0.95,0,
			0,0,0.95};
	double checksx[3*1]={-0.028,0.026,-0.004};
	solveSystemFstar(3,1,newchecksx,checksx,logfile);
	//printMatrix(checksx,3,1,"InExpensive_Matrix_Inverse");
}

int RunReconciliation(DATA* data, threadData_t *threadData, inputData x, matrixData Sx, matrixData tmpjacF, matrixData tmpjacFt, double eps, int iterationcount, csvData csvinputs, matrixData xdiag, matrixData sxdiag, ofstream& logfile)
{
	// set the inputs first
	for (int i=0; i< x.rows*x.column; i++)
	{
		data->simulationInfo->inputVars[x.index[i]]=x.data[i];
		//logfile << "input data:" << x.data[i]<<"\n";
	}
	//data->callback->input_function_updateStartValues(data, threadData);
	data->callback->input_function(data, threadData);
	data->callback->functionDAE(data,threadData);
	//data->callback->functionODE(data,threadData);
	data->callback->setc_function(data, threadData);

	matrixData jacF = getJacobianMatrixF(data,threadData,logfile);
	matrixData jacFt = getTransposeMatrix(jacF);

	printMatrix(jacF.data,jacF.rows,jacF.column,"F",logfile);
	printMatrix(jacFt.data,jacFt.rows,jacFt.column,"Ft",logfile);


	double* setc = (double*)calloc(data->modelData->nSetcVars,sizeof(double)); // allocate data for setc array
	// store the setc data to compute for convergence as setc will be overriddeen with new values
	double* tmpsetc = (double*)calloc(data->modelData->nSetcVars,sizeof(double));

	/* loop to store the data C(x,y) rhs side, get the elements in reverse order */
	int t=0;
	for (int i=data->modelData->nSetcVars; i > 0; i--)
	{
		setc[t]=data->simulationInfo->setcVars[i-1];
		tmpsetc[t]=data->simulationInfo->setcVars[i-1];
		t++;
		//cout << "array_setc_vars:=>" << t << ":" << data->simulationInfo->setcVars[i-1] << "\n";
	}

	int nsetcvars= data->modelData->nSetcVars;
	matrixData vector_c = {nsetcvars,1,tmpsetc};
	//allocate data for matrix multiplication F*Sx
	double * tmpmatrixC = (double*)calloc(jacF.rows*Sx.column,sizeof(double));
	solveMatrixMultiplication(jacF.data,Sx.data,jacF.rows,jacF.column,Sx.rows,Sx.column,tmpmatrixC,logfile);
	//printMatrix(tmpmatrixC,jacF.rows,Sx.column,"F*Sx");

	//allocate data for matrix multiplication (F*Sx)*Ftranspose
	double * tmpmatrixD = (double*)calloc(jacF.rows*jacFt.column,sizeof(double));
	solveMatrixMultiplication(tmpmatrixC,jacFt.data,jacF.rows,Sx.column,jacFt.rows,jacFt.column,tmpmatrixD,logfile);
	//printMatrix(tmpmatrixD,jacF.rows,jacFt.column,"F*Sx*Ft");
	//printMatrix(setc,nsetcvars,1,"c(x,y)");
	/*
	 * Copy tmpmatrixC and tmpmatrixD to avoid loss of data
	 * when calculating F*
	 */
	matrixData cpytmpmatrixC = {jacF.rows,Sx.column,tmpmatrixC};
	matrixData cpytmpmatrixD = {jacF.rows,jacFt.column,tmpmatrixD};
	matrixData tmpmatrixC1 = copyMatrix(cpytmpmatrixC);
	matrixData tmpmatrixD1 = copyMatrix(cpytmpmatrixD);

	if(ACTIVE_STREAM(LOG_JAC))
	{
		logfile << "Calculations of Matrix (F*Sx*Ft) f* = c(x,y) " << "\n";
		logfile << "============================================\n";
		printMatrix(tmpmatrixC,jacF.rows,Sx.column,"F*Sx",logfile);
		printMatrix(tmpmatrixD,jacF.rows,jacFt.column,"F*Sx*Ft",logfile);
		printMatrix(setc,nsetcvars,1,"c(x,y)",logfile);
	}
	/*
	 * calculate f* for covariance matrix (F*Sx*Ftranspose).F*= c(x,y)
	 * matrix setc will be overridden with new values which is the output
	 * for the calculation A *x =B
	 * A = tmpmatrixD
	 * B = setc
	 */
	solveSystemFstar(jacF.rows,1,tmpmatrixD,setc,logfile);
	//printMatrix(setc,jacF.rows,1,"f*");
	if(ACTIVE_STREAM(LOG_JAC))
	{
		printMatrix(setc,jacF.rows,1,"f*",logfile);
		logfile << "***** Completed ****** \n\n";
	}
	matrixData tmpxcap ={x.rows,1,x.data};
	matrixData tmpfstar = {jacF.rows,1,setc};
	matrixData reconciled_X = solveReconciledX(tmpxcap,Sx,jacFt,tmpfstar,logfile);
	//printMatrix(reconciled_X.data,reconciled_X.rows,reconciled_X.column,"reconciled_X ===> (x - (Sx*Ft*fstar))");
	if(ACTIVE_STREAM(LOG_JAC))
	{
		logfile << "Calculations of Matrix (F*Sx*Ft) F* = F*Sx " << "\n";
		logfile << "===============================================\n";
		//printMatrix(tmpmatrixC,jacF.rows,Sx.column,"F*Sx");
		//printMatrix(tmpmatrixD,jacF.rows,jacFt.column,"F*Sx*Ft");
		printMatrix(tmpmatrixC1.data,tmpmatrixC1.rows,tmpmatrixC1.column,"F*Sx",logfile);
		printMatrix(tmpmatrixD1.data,tmpmatrixD1.rows,tmpmatrixD1.column,"F*Sx*Ft",logfile);
	}
	/*
	 * calculate F* for covariance matrix (F*Sx*Ftranspose).F*= (F*Sx)
	 * tmpmatrixC1 will be overridden with new values which is the output
	 * for the calculation A *x =B
	 * A = tmpmatrixD
	 * B = tmpmatrixC
	 */
	solveSystemFstar(jacF.rows,Sx.column,tmpmatrixD1.data,tmpmatrixC1.data,logfile);
	//printMatrix(tmpmatrixC,jacF.rows,Sx.column,"Sx_F*");
	if(ACTIVE_STREAM(LOG_JAC))
	{
		printMatrix(tmpmatrixC1.data,jacF.rows,Sx.column,"F*",logfile);
		logfile << "***** Completed ****** \n\n";
	}

	matrixData tmpFstar = {jacF.rows,Sx.column,tmpmatrixC1.data};
	matrixData reconciled_Sx = solveReconciledSx(Sx,jacFt,tmpFstar,logfile);
	//printMatrix(reconciled_Sx.data,reconciled_Sx.rows,reconciled_Sx.column,"reconciled Sx ===> (Sx - (Sx*Ft*Fstar))");

	double value = solveConvergence(data,reconciled_X,reconciled_Sx,x,Sx,jacF,vector_c,tmpfstar,logfile);
	if(value > eps )
	{
		logfile << "J*/r" << "(" << value << ")"  << " > " << eps << ", Value not Converged \n";
		logfile << "==========================================\n\n";
	}
	if(value > eps)
	{
		logfile << "Running Convergence iteration: " << iterationcount << " with the following reconciled values:" << "\n";
		logfile << "========================================================================" << "\n";
		//cout << "J*/r :=" << value << "\n";
		//printMatrix(jacF.data,jacF.rows,jacF.column,"F");
		//printMatrix(jacFt.data,jacFt.rows,jacFt.column,"Ft");
		//printMatrix(setc,jacF.rows,1,"f*");
		//printMatrix(tmpmatrixC,jacF.rows,Sx.column,"F*");
		printMatrixWithHeaders(reconciled_X.data,reconciled_X.rows,reconciled_X.column,csvinputs.headers,"reconciled_X ===> (x - (Sx*Ft*fstar))",logfile);
		printMatrixWithHeaders(reconciled_Sx.data,reconciled_Sx.rows,reconciled_Sx.column,csvinputs.headers,"reconciled_Sx ===> (Sx - (Sx*Ft*Fstar))",logfile);
		//free(x.data);
		//free(Sx.data);
		x.data=reconciled_X.data;
		//Sx.data=reconciled_Sx.data;
		iterationcount++;
		return RunReconciliation(data, threadData, x, Sx, jacF, jacFt,eps,iterationcount,csvinputs,xdiag,sxdiag,logfile);
	}
	if(value < eps && iterationcount==1)
	{
		logfile << "J*/r" << "(" << value << ")"  << " > " << eps << ", Convergence iteration not required \n\n";
	}
	else
	{
		logfile << "***** Value Converged, Convergence Completed******* \n\n";
	}
	logfile << "Final Results:\n";
	logfile << "=============\n";
	logfile << "Total Iteration to Converge : " << iterationcount << "\n";
	logfile << "Final Converged Value(J*/r) : " << value << "\n";
	logfile << "Epsilon                     : " << eps << "\n";
	printMatrixWithHeaders(reconciled_X.data,reconciled_X.rows,reconciled_X.column,csvinputs.headers,"reconciled_X ===> (x - (Sx*Ft*fstar))",logfile);
	printMatrixWithHeaders(reconciled_Sx.data,reconciled_Sx.rows,reconciled_Sx.column,csvinputs.headers,"reconciled_Sx ===> (Sx - (Sx*Ft*Fstar))",logfile);

	/*
	 * Calculate half width Confidence interval
	 * W=lambda*sqrt(Sx)
	 * where lamba = 1.96 and
	 * Sx - diagonal elements of reconciled_Sx
	 */
	double* reconSx_diag = (double*)calloc(reconciled_Sx.rows*1,sizeof(double));
	getDiagonalElements(reconciled_Sx.data,reconciled_Sx.rows,reconciled_Sx.column,reconSx_diag);

	matrixData copyreconSx_diag = {reconciled_Sx.rows,1,reconSx_diag};
	matrixData tmpcopyreconSx_diag = copyMatrix(copyreconSx_diag);
	if(ACTIVE_STREAM(LOG_JAC))
	{
		logfile << "Calculations of HalfWidth Confidence Interval " << "\n";
		logfile << "===============================================\n";
		printMatrix(copyreconSx_diag.data,reconciled_Sx.rows,1,"reconciled-Sx_Diagonal",logfile);
	}
	calculateSquareRoot(copyreconSx_diag.data,reconciled_Sx.rows);
	if(ACTIVE_STREAM(LOG_JAC))
	{
		printMatrix(copyreconSx_diag.data,reconciled_Sx.rows,1,"reconciled-Sx_SquareRoot",logfile);
		logfile << "*****Completed***********\n";
	}
	scaleVector(reconciled_Sx.rows,1,1.96,copyreconSx_diag.data);
	printMatrixWithHeaders(copyreconSx_diag.data,reconciled_Sx.rows,1,csvinputs.headers,"Wx-HalfWidth-Interval-(1.96)*sqrt(Sx_diagonal)",logfile);


	/*
	 * Calculate individual tests
	 * (recon_x - x)/sqrt(Sx-recon_Sx)
	 */
	double* newSx_diag = (double*)calloc(reconciled_Sx.rows*1,sizeof(double));
	solveMatrixSubtraction(sxdiag,tmpcopyreconSx_diag,newSx_diag,logfile);
	if(ACTIVE_STREAM(LOG_JAC))
	{
		logfile << "Calculations of Individual Tests " << "\n";
		logfile << "===============================================\n";
		printMatrix(newSx_diag,sxdiag.rows,sxdiag.column,"Sx-recon_Sx",logfile);
	}
	calculateSquareRoot(newSx_diag,reconciled_Sx.rows);
	if(ACTIVE_STREAM(LOG_JAC))
	{
		printMatrix(newSx_diag,sxdiag.rows,sxdiag.column,"squareroot-newSx",logfile);
	}

	double *newX = (double*)calloc(xdiag.rows*1,sizeof(double));
	solveMatrixSubtraction(reconciled_X,xdiag,newX,logfile);
	// calculate absolute value for this numeric analysis
	for (unsigned int a=0; a < sizeof(newX); a++)
	{
		newX[a] = fabs(newX[a]);
	}
	if(ACTIVE_STREAM(LOG_JAC))
	{
		printMatrix(newX,xdiag.rows,xdiag.column,"recon_X - X",logfile);
		logfile << "*********Completed***********\n";
	}

	for (int val=0; val < xdiag.rows; val++)
	{
		newX[val]=newX[val]/max(newSx_diag[val],sqrt(sxdiag.data[val]/10));
	}

	printMatrixWithHeaders(newX,xdiag.rows,xdiag.column,csvinputs.headers,"IndividualTests_Value- (recon_x-x)/sqrt(Sx_diag)",logfile);

	/*
	 * create HTML Report
	 */
	ofstream myfile;
	time_t now = time(0);
	std::stringstream htmlfile;
	if (omc_flag[FLAG_OUTPUT_PATH])
	{
		htmlfile << string(omc_flagValue[FLAG_OUTPUT_PATH]) << "/" << data->modelData->modelName << ".html";
	}
	else
	{
		htmlfile << data->modelData->modelName << ".html";
	}
	string html= htmlfile.str();
	myfile.open(html.c_str());

	/* create a csv file */
	ofstream csvfile;
	std::stringstream csv_file;
	if (omc_flag[FLAG_OUTPUT_PATH])
	{
		csv_file << string(omc_flagValue[FLAG_OUTPUT_PATH]) << "/" << data->modelData->modelName << "_Outputs.csv";
	}
	else
	{
		csv_file << data->modelData->modelName <<"_Outputs.csv";
	}
	string tmpcsv= csv_file.str();
	csvfile.open(tmpcsv.c_str());

	/* Add Overview Data */
	myfile << "<!DOCTYPE html><html>\n <head> <h1> DataReconciliation Report</h1></head> \n <body> \n ";
	myfile << "<h2> Overview: </h2>\n";
	myfile << "<table> \n";
	myfile << "<tr> \n" << "<th align=right> ModelFile: </th> \n" << "<td>" << data->modelData->modelFilePrefix << ".mo" << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> ModelName: </th> \n" << "<td>" << data->modelData->modelName << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> ModelDirectory: </th> \n" << "<td>" << data->modelData->modelDir << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Measurement Files: </th> \n" << "<td>" << omc_flagValue[FLAG_DATA_RECONCILE_Sx] << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Generated: </th> \n" << "<td>" << ctime(&now) << " by <b>OpenModelica-</b>"<< "<b>" << CONFIG_VERSION << "</b>" << "</td> </tr>\n";
	myfile << "</table>\n";

	/* Add Analysis data */
	myfile << "<h2> Analysis: </h2>\n";
	myfile << "<table> \n";
	myfile << "<tr> \n" << "<th align=right> Number of Extracted equations: </th> \n" << "<td>" << data->modelData->nSetcVars << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Number of Variables to be Reconciled: </th> \n" << "<td>" << csvinputs.headers.size() << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Number of Iteration to Converge: </th> \n" << "<td>" << iterationcount << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Final Converged Value(J*/r) : </th> \n" << "<td>" << value << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Epsilon : </th> \n" << "<td>" << eps << "</td> </tr>\n";
	myfile << "<tr> \n" << "<th align=right> Final Value of the objective Function (J*) : </th> \n" << "<td>" << (value*data->modelData->nSetcVars) << "</td> </tr>\n";
	//myfile << "<tr> \n" << "<th align=right> Chi-square value : </th> \n" << "<td>" << quantile(complement(chi_squared(data->modelData->nSetcVars), 0.05)) << "</td> </tr>\n";
	if(data->modelData->nSetcVars > 200){
		myfile << "<tr> \n" << "<th align=right> Chi-square value : </th> \n" << "<td>" << "NOT Available for equations > 200 in setC" << "</td> </tr>\n";
	}
	else
	{
		myfile << "<tr> \n" << "<th align=right> Chi-square value : </th> \n" << "<td>" << chisquaredvalue[data->modelData->nSetcVars-1] << "</td> </tr>\n";
	}
	myfile << "<tr> \n" << "<th align=right> Result of Global Test : </th> \n" << "<td>" << "TRUE" << "</td> </tr>\n";
	myfile << "</table>\n";

	/* Add Results data */
	myfile << "<h2> Results: </h2>\n";
	myfile << "<table border=2>\n";
	myfile << "<tr>\n" << "<th> Variables to be Reconciled </th>\n" << "<th> Initial Measured Values </th>\n" << "<th> Reconciled Values </th>\n" << "<th> Initial Uncertainty Values </th>\n" <<"<th> Reconciled Uncertainty Values </th>\n";
	csvfile << "Variables to be Reconciled ," << "Initial Measured Values ," << "Reconciled Values ," << "Initial Uncertainty Values ," << "Reconciled Uncertainty Values,";
	myfile << "<th> Results of Local Tests </th>\n" << "<th> Values of Local Tests </th>\n" << "<th> Margin to Correctness(distance from 1.96) </th>\n" << "</tr>\n";
	csvfile << "Results of Local Tests ," << "Values of Local Tests ," << "Margin to Correctness(distance from 1.96) ," << "\n";

	for (unsigned int r=0; r < csvinputs.headers.size(); r++)
	{
		myfile << "<tr>\n";
		myfile << "<td>" << csvinputs.headers[r] << "</td>\n";
		csvfile << csvinputs.headers[r] << ",";
		myfile << "<td>" << xdiag.data[r] << "</td>\n";
		csvfile << xdiag.data[r] << ",";
		myfile << "<td>" << reconciled_X.data[r] << "</td>\n";
		csvfile << reconciled_X.data[r] << ",";

		myfile << "<td>" << csvinputs.sxdata[r] << "</td>\n";
		csvfile << csvinputs.sxdata[r] << ",";

		myfile << "<td>" << copyreconSx_diag.data[r] << "</td>\n";
		csvfile << copyreconSx_diag.data[r] << ",";

		if(newX[r] < 1.96)
		{
			myfile << "<td>" << "TRUE" << "</td>\n";
			csvfile << "TRUE" << ",";
		}
		else
		{
			myfile << "<td>" << "FALSE" << "</td>\n";
			csvfile << "FALSE" << ",";
		}
		myfile << "<td>" << newX[r] << "</td>\n";
		csvfile << newX[r] << ",";

		myfile << "<td>" << (1.96-newX[r]) << "</td>\n";
		csvfile << (1.96-newX[r]) << ",\n";
		csvfile.flush();
		myfile << "</tr>\n";
		myfile.flush();
	}
	csvfile.close();
	myfile << "</table>\n";
	myfile << "</body>\n</html>";
	myfile.close();

	free(tmpFstar.data);
	free(tmpfstar.data);
	//free(tmpmatrixC);
	//free(tmpmatrixD);
	//free(setc);
	free(reconciled_Sx.data);
	free(reconciled_X.data);
	free(copyreconSx_diag.data);
	free(tmpcopyreconSx_diag.data);
	free(newSx_diag);
	free(newX);
	//free(jacF.data);
	//free(jacFt.data);
	//free(x.data);
	//free(Sx.data);
	return 0;
}


int dataReconciliation(DATA* data, threadData_t *threadData)
{
	TRACE_PUSH
	const char* epselon = NULL;
	epselon = (char*)omc_flagValue[FLAG_DATA_RECONCILE_Eps];

	/*
	 * Create a Debug Log file
	 */
	ofstream  logfile;
	std::stringstream logfilename;
	if (omc_flag[FLAG_OUTPUT_PATH])
	{
		logfilename << omc_flagValue[FLAG_OUTPUT_PATH] << "/" << data->modelData->modelName << "_debug.log";
	}
	else
	{
		logfilename << data->modelData->modelName << "_debug.log";
	}
	string tmplogfilename= logfilename.str();
	logfile.open(tmplogfilename.c_str());
	logfile << "|  info    |   " << "DataReconciliation Starting!\n";
	logfile << "|  info    |   " << data->modelData->modelName << "\n";

	if(epselon==NULL)
	{
		//errorStreamPrint(LOG_STDOUT, 0, "Epsilon Value not given, Please specify a convergence value (eg: -eps=0.0002), DataReconciliation cannot be computed!.");
		logfile << "|  error   |   " << "Epsilon Value not given, Please specify a convergence value (eg: -eps=0.0002), DataReconciliation cannot be computed!.\n";
		logfile.close();
		exit(1);
	}
	csvData Sx_data = readCovarianceMatrixSx(data, threadData,logfile);
	//matrixData Sx = getCovarianceMatrixSx(Sx_data, data, threadData); // Prepare the data from csv file *
	matrixData Sx = computeCovarianceMatrixSx(Sx_data,data,threadData,logfile); // Compute the covariance matrix from csv inputs
	inputData x = getInputDataFromStartAttribute(Sx_data, data, threadData, logfile);  // Read the inputs from the start attribute of the modelica model
	matrixData jacF = getJacobianMatrixF(data, threadData, logfile); // Compute the Jacobian Matrix F
	matrixData jacFt = getTransposeMatrix(jacF); // Compute the Transpose of jacobian Matrix F

	double* Sx_diag = (double*)calloc(Sx.rows*1,sizeof(double));
	getDiagonalElements(Sx.data,Sx.rows,Sx.column,Sx_diag);
	matrixData tmpSx_diag={Sx.rows,1,Sx_diag};

	matrixData tmp_x={x.rows,x.column,x.data};
	matrixData x_diag=copyMatrix(tmp_x);

	// Print the initial information
	logfile << "\n\nInitial Data \n" << "=============\n";
	printMatrixWithHeaders(x.data,x.rows,x.column,Sx_data.headers,"X",logfile);
	printVectorMatrixWithHeaders(Sx_data.sxdata,Sx_data.rowcount,1,Sx_data.headers,"Half-WidthConfidenceInterval",logfile);
	printMatrixWithHeaders(Sx.data,Sx.rows,Sx.column,Sx_data.headers,"Sx",logfile);
	//printMatrix(Sx_diag,Sx.rows,1,"Sx-Diagonal elements",logfile);

	//printMatrix(jacF.data,jacF.rows,jacF.column,"F",logfile);
	//printMatrix(jacFt.data,jacFt.rows,jacFt.column,"Ft",logfile);
	// Start the Algorithm
	RunReconciliation(data,threadData,x,Sx,jacF,jacFt,atof(epselon),1,Sx_data,x_diag,tmpSx_diag,logfile);
	logfile << "|  info    |   " << "DataReconciliation Completed! \n";
	logfile.close();
	free(Sx.data);
	free(x.data);
	free(jacF.data);
	free(jacFt.data);
	free(tmpSx_diag.data);
	free(x_diag.data);
	TRACE_POP
	return 0;
}

}
