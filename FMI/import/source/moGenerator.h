#include "xmlparser.h"
#include "fmuWrapper.h"

typedef enum{flat, structured} fmiNamingConvention;
typedef enum{constant, parameter, discrete, continuous} fmiVariability;
typedef enum{input, output, internal, none} fmiCausality;
typedef enum{noalias,alias,negatedAlias} fmiAlias;
typedef enum{fmi_false, fmi_true} fmiBooleanXML;
typedef enum{sv_real, sv_integer, sv_boolean, sv_string,sv_enum} fmiScalarVariableType;

typedef struct {
	const char* name;
	fmiValueReference vr;
	void* next;
} fmuOutputVar;


typedef struct{
	const char* declType;
	const char* start;
	fmiBooleanXML fixed;
} fmiSTRING;

typedef struct{
	fmiBooleanXML start;
	const char* declType;
	fmiBooleanXML fixed;
} fmiBOOLEAN;

typedef struct{
	const char* declType;
	const char* quantity;
	double min;
	double max;
	int start;
	fmiBooleanXML fixed;
} fmiINTEGER;

typedef struct{
	const char* declType;
	const char* quantity;
	const char* unit;
	const char* displayUnit;
	fmiBooleanXML relQuantity;
	double min;
	double max;
	double nominal;
	double start;
	fmiBooleanXML fixed;
} fmiREAL;

typedef struct{
	const char* name;
	char* flatName;
	fmiValueReference vr; // value reference;
	const char* description;
	Enu var;
	Enu causality;
	Enu alias;
	fmiScalarVariableType type;
	void* variable;	
} fmiScalarVariable;

typedef struct{
	
} fmiArrayVariable;

typedef struct{
	int nsv; // number of scalar variables
	fmiScalarVariable* list_sv;
	int nav; // number of array variables
	fmiArrayVariable* list_av;	
} fmiModelVariable;

typedef struct{
	const char* fmiver; // fmi version number;
	const char* mn; // fmi model name
	const char* mid; // model identifier;
	const char* guid; // fingerprint of xml-file content
	const char* description; // string describing the model
	const char* author;
	const char* mver; // model version
	const char* genTool;// generation tool;
	const char* genTime; // generation date and time;
	fmiNamingConvention nconv; // variable naming convention;
	unsigned int ncs; // number of continuous states;
	unsigned int nei; // number of event indicators;
	fmiModelVariable* modelVariable;
} fmuModelDescription;

static char* getDecompPath(const char * omPath, const char* mid);
static char* getDllPath(const char* decompPath,const char* mid);
static char* getNameXMLfile(const char * decompPath, const char * modeldes);
static int decompress(const char* fmuPath, const char* decompPath);
static char* getFMUname(const char* fmupath);
static int getNumberOfSV(ModelDescription* md);
void* allocateElmSV(fmiScalarVariable sv);
static void instScalarVariable(ModelDescription* md,fmiScalarVariable* list);
static void instFmuModelDescription(ModelDescription* md, fmuModelDescription* fmuMD, fmiModelVariable* fmuMV);
void tmpcodegen(fmuModelDescription* /*fmuMD*/, const char* /*decompPath*/);
void blockcodegen(fmuModelDescription* /*fmuMD*/, const char* /*decompPath*/, const char* /*fmudllpath*/);
