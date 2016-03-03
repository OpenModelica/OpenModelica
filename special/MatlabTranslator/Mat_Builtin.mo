encapsulated package Mat_Builtin


public function builtIn
input String fnc_name;
output Boolean tf;
algorithm
  tf := matchcontinue (fnc_name)
  local
    String fnc_name1;
    Boolean tf1;
    // Matrices and Arrays
    //Array Creation and Concatenation
    case("accumarray") then true; //	Construct array with accumulation
    case("blkdiag") then true;    //	Construct block diagonal matrix from input arguments
    case("diag") then true;    //	Diagonal matrices and diagonals of matrix
    case("eye") then true;    //	Identity matrix
    case("false") then true;    //	Logical 0 (false)
    case("freqspace") then true;    //	Frequency spacing for frequency response
    case("linspace") then true;    //	Generate linearly spaced vectors
    case("logspace") then true;    //		Generate logarithmically spaced vectors
    case("meshgrid") then true;    //	Rectangular grid in 2-D and 3-D space
    case("ndgrid") then true;    //	Rectangular grid in N-D space
		case("ones") then true;    //	Create array of all ones
		case("rand") then true;    //	Uniformly distributed pseudorandom numbers
		case("true") then true;    //	Logical 1 (true)
		case("zeros") then true;    //	Create array of all zeros
		case("cat") then true;       //	Concatenate arrays along specified dimension
		case("horzcat") then true;    //	Concatenate arrays horizontally
		case("vertcat") then true;    //	Concatenate arrays vertically
    // Indexing
		case("ind2sub") then true;    //		Subscripts from linear index
		case("sub2ind") then true;    //		Convert subscripts to linear indices
		    // Array Dimensions
		case("length") then true;    //	Length of vector or largest array dimension
		case("ndims") then true;    //	Number of array dimensions
		case("numel") then true;    //	Number of array elements
		case("size") then true;    //	Array dimensions
		case("height") then true;    //	Number of table rows
		case("width") then true;    //	Number of table variables
		case("iscolumn") then true;    //	Determine whether input is column vector
		case("isempty") then true;    //	Determine whether array is empty
		case("ismatrix") then true;    //	Determine whether input is matrix
		case("isrow") then true;    //	Determine whether input is row vector
		case("isscalar") then true;    //	Determine whether input is scalar
		case("isvector") then true;    //	Determine whether input is vector
		// Sorting and Reshaping Arrays
		case("circshift") then true;    //	Shift array circularly
		case("ctranspose") then true;    //	Complex conjugate transpose
		case("diag") then true;    //	Diagonal matrices and diagonals of matrix
		case("flip") then true;    //	 Flip order of elements
		case("flipdim") then true;    //	Flip array along specified dimension
		case("fliplr") then true;    //	Flip matrix left to right
		case("flipud") then true;    //	Flip matrix up to down
		case("ipermute") then true;    //	Inverse permute dimensions of N-D array
		case("permute") then true;    //	Rearrange dimensions of N-D array
		case("repmat") then true;    //	Replicate and tile array
		case("reshape") then true;    //	Reshape array
		case("rot90") then true;    //	Rotate matrix 90 degrees
		case("shiftdim") then true;    //	Shift dimensions
		case("issorted") then true;    //	Determine whether set elements are in sorted order
		case("sort") then true;    //	Sort array elements in ascending or descending order
		case("sortrows") then true;    //	Sort rows in ascending order
		case("squeeze") then true;    //	Remove singleton dimensions
		case("transpose") then true;    //	Transpose
		case("vectorize") then true;    //	Vectorize expression
		// Operators and Elementary Operations
		// Arithmetic
		case("plus") then true;    //	 Addition
		case("uplus") then true;    //	Unary plus
		case("minus") then true;    //	Subtraction
		case("uminus") then true;    //	Unary minus
		case("times") then true;    //	Element-wise multiplication
		case("rdivide") then true;    //	 Right array division
		case("ldivide") then true;    //	Left array division
		case("power") then true;    //	Element-wise power
		case("mtimes") then true;    //	Matrix Multiplication
		case("mrdivide") then true;    //	Solve systems of linear equations xA = B for x
		case("mldivide") then true;    //	Solve systems of linear equations Ax = B for x
		case("mpower") then true;    //	Matrix power
		case("cumprod") then true;    //	Cumulative product
		case("cumsum") then true;    //	Cumulative sum
		case("diff") then true;    //	Differences and Approximate Derivatives
		case("prod") then true;    //	Product of array elements
		case("sum") then true;    //	Sum of array elements
		case("ceil") then true;    //	Round toward positive infinity
		case("fix") then true;    //	Round toward zero
		case("floor") then true;    //	Round toward negative infinity
		case("idivide") then true;    //	Integer division with rounding option
		case("mod") then true;    //	Modulus after division
		case("rem") then true;    //	Remainder after division
		case("round") then true;    //	Round to nearest integer
		// Relational Operations
		case("eq") then true;    //		Determine equality
		case("ge") then true;    //		Determine greater than or equal to
		case("gt") then true;    //		Determine greater than
		case("le") then true;    //		Determine less than or equal to
		case("lt") then true;    //		Determine less than
		case("ne") then true;    //		Determine inequality
		case("isequal") then true;    //		Determine array equality
		case("isequaln") then true;    //		Determine array equality, treating NaN values as equal
		// Logical Operations
		case("xor") then true;    //		Logical exclusive-OR
		case("all") then true;    //		Determine if all array elements are nonzero or true
		case("any") then true;    //		Determine if any array elements are nonzero
		case("false") then true;    //		Logical 0 (false)
		case("find") then true;    //		Find indices and values of nonzero elements
		case("islogical") then true;    //		Determine if input is logical array
		case("logical") then true;    //		Convert numeric values to logicals
		case("true") then true;    //		Logical 1 (true)
		// Set Operations
		case("intersect") then true;    //			Set intersection of two arrays
		case("ismember") then true;    //			Array elements that are members of set array
		case("issorted") then true;    //			Determine whether set elements are in sorted order
		case("setdiff") then true;    //			Set difference of two arrays
		case("setxor") then true;    //			Set exclusive OR of two arrays
		case("union") then true;    //			Set union of two arrays
		case("unique") then true;    //			Unique values in array
		case("join") then true;    //			Merge two tables by matching up rows using key variables
		case("innerjoin") then true;    //			Inner join between two tables
		case("outerjoin") then true;    //			Outer join between two tables
		// Bit-Wise Operations
		case("bitand") then true;    //			Bit-wise AND
		case("bitcmp") then true;    //			Bit-wise complement
		case("bitget") then true;    //			Get bit at specified position
		case("bitor") then true;    //			Bit-wise OR
		case("bitset") then true;    //			Set bit at specific location
		case("bitshift") then true;    //			Shift bits specified number of places
		case("bitxor") then true;    //			Bit-wise XOR
		case("swapbytes") then true;    //	Swap byte ordering
		// Data Types
		// Numeric Types
		case("double") then true;    //	Convert to double precision
		case("single") then true;    //	Convert to single precision
		case("int8") then true;    //	Convert to 8-bit signed integer
		case("int16") then true;    //	Convert to 16-bit signed integer
		case("int32") then true;    //	Convert to 32-bit signed integer
		case("int64") then true;    //	Convert to 64-bit signed integer
		case("uint8") then true;    //	Convert to 8-bit unsigned integer
		case("uint16") then true;    //	Convert to 16-bit unsigned integer
		case("uint32") then true;    //	Convert to 32-bit unsigned integer
		case("uint64") then true;    //	Convert to 64-bit unsigned integer
		case("cast") then true;    //	Cast variable to different data type
		case("typecast") then true;    //	Convert data types without changing underlying data
		case("isinteger") then true;    //	Determine if input is integer array
		case("isfloat") then true;    //	Determine if input is floating-point array
		case("isnumeric") then true;    //	Determine if input is numeric array
		case("isreal") then true;    //	Check if input is real array
		case("isfinite") then true;    //	Array elements that are finite
		case("isinf") then true;    //	Array elements that are infinite
		case("isnan") then true;    //	Array elements that are NaN
		case("eps") then true;    //	Floating-point relative accuracy
		case("flintmax") then true;    //	Largest consecutive integer in floating-point format
		case("Inf") then true;    //	Infinity
		case("intmax") then true;    //	Largest value of specified integer type
		case("intmin") then true;    //	Smallest value of specified integer type
		case("NaN") then true;    //	Not-a-Number
		case("realmax") then true;    //	Largest positive floating-point number
		case("realmin") then true;    //	Smallest positive normalized floating-point number
		// Characters and Strings
		// Create and Concatenate Strings
		case("blanks") then true;    //	Create string of blank characters
		case("cellstr") then true;    //	Create cell array of strings from character array
		case("char") then true;    //	Convert to character array (string)
		case("iscellstr") then true;    //	Determine whether input is cell array of strings
		case("ischar") then true;    //	Determine whether item is character array
		case("sprintf") then true;    //	Format data into string
		case("strcat") then true;    //	Concatenate strings horizontally
		case("strjoin") then true;    //	Join strings in cell array into single string
		// Parse Strings
		case("ischar") then true;    //	Determine whether item is character array
		case("isletter") then true;    //	Array elements that are alphabetic letters
		case("isspace") then true;    //	Array elements that are space characters
		case("isstrprop") then true;    //	Determine whether string is of specified category
		case("sscanf") then true;    //	Read formatted data from string
		case("strfind") then true;    //	Find one string within another
		case("strrep") then true;    //	Find and replace substring
		case("strsplit") then true;    //	Split string at specified delimiter
		case("strtok") then true;    //	Selected parts of string
		case("validatestring") then true;    //	Check validity of text string
		case("symvar") then true;    //	Determine symbolic variables in expression
		case("regexp") then true;    //	Match regular expression (case sensitive)
		case("regexpi") then true;    //	Match regular expression (case insensitive)
		case("regexprep") then true;    //	Replace string using regular expression
		case("regexptranslate") then true;    //	Translate string into regular expression
		// Compare Strings
		case("strcmp") then true;    //	Compare strings with case sensitivity
		case("strcmpi") then true;    //	Compare strings (case insensitive)
		case("strncmp") then true;    //	Compare first n characters of strings (case sensitive)
		case("strncmpi") then true;    //	Compare first n characters of strings (case insensitive)
		// Change String Case, Blanks, and Justification
		case("blanks") then true;    //	Create string of blank characters
		case("deblank") then true;    //	Strip trailing blanks from end of string
		case("strtrim") then true;    //	Remove leading and trailing white space from string
		case("lower") then true;    //	Convert string to lowercase
		case("upper") then true;    //	Convert string to uppercase
		case("strjust") then true;    //	Justify character array
		// Categorical Arrays
		case("categorical") then true;    //	Create categorical array
		case("iscategorical") then true;    //	Determine whether input is categorical array
		case("categories") then true;    //	Categories of categorical array
		case("iscategory") then true;    //	Test for categorical array categories
		case("isordinal") then true;    //	Determine whether input is ordinal categorical array
		case("isprotected") then true;    //	Determine whether categories of categorical array are protected
		case("addcats") then true;    //	Add categories to categorical array
		case("mergecats") then true;    //	Merge categories in categorical array
		case("removecats") then true;    //	Remove categories from categorical array
		case("renamecats") then true;    //	Rename categories in categorical array
		case("reordercats") then true;    //	Reorder categories in categorical array
		case("summary") then true;    //	Print summary of table or categorical array
		case("countcats") then true;    //	Count occurrences of categorical array elements by category
		case("isundefined") then true;    //	Find undefined elements in categorical array
		// Tables
		case("table") then true;    //	Create table from workspace variables
		case("array2table") then true;    //	Convert homogeneous array to table
		case("cell2table") then true;    //	Convert cell array to table
		case("struct2table") then true;    //	Convert structure array to table
		case("table2array") then true;    //	Convert table to homogenous array
		case("table2cell") then true;    //	Convert table to cell array
		case("table2struct") then true;    //	Convert table to structure array
		case("readtable") then true;    //	Create table from file
		case("writetable") then true;    //	Write table to file
		case("istable") then true;    //	Determine whether input is table
		case("height") then true;    //	Number of table rows
		case("width") then true;    //	Number of table variables
		case("summary") then true;    //	Print summary of table or categorical array
		case("intersect") then true;    //	Set intersection of two arrays
		case("ismember") then true;    //	Array elements that are members of set array
		case("setdiff") then true;    //	Set difference of two arrays
		case("setxor") then true;    //	Set exclusive OR of two arrays
		case("unique") then true;    //	Unique values in array
		case("union") then true;    //	Set union of two arrays
		case("join") then true;    //	Merge two tables by matching up rows using key variables
		case("innerjoin") then true;    //	Inner join between two tables
		case("outerjoin") then true;    //	Outer join between two tables
		case("sortrows") then true;    //	Sort rows in ascending order
		case("stack") then true;    //	Stack data from multiple variables into single variable
		case("unstack") then true;    //	Unstack data from single variable into multiple variables
		case("ismissing") then true;    //	Find table elements with missing values
		case("standardizeMissing") then true;    //	Insert missing value indicators into table
		case("varfun") then true;    //	Apply function to table variables
		case("rowfun") then true;    //	Apply function to table rows
		// Structures
		case("struct") then true;    //		Create structure array
		case("fieldnames") then true;    //		Field names of structure, or public fields of object
		case("getfield") then true;    //		Field of structure array
		case("isfield") then true;    //		Determine whether input is structure array field
		case("isstruct") then true;    //		Determine whether input is structure array
		case("orderfields") then true;    //		Order fields of structure array
		case("rmfield") then true;    //		Remove fields from structure
		case("setfield") then true;    //		Assign values to structure array field
		case("arrayfun") then true;    //		Apply function to each element of array
		case("structfun") then true;    //		Apply function to each field of scalar structure
		case("cell2struct") then true;    //		Convert cell array to structure array
		case("struct2cell") then true;    //		Convert structure to cell array
		// Cell Arrays
		case("cell") then true;    //		 Create cell array
		case("cell2mat") then true;    //		Convert cell array to numeric array
		case("cell2struct") then true;    //		Convert cell array to structure array
		case("celldisp") then true;    //		Cell array contents
		case("cellfun") then true;    //		Apply function to each cell in cell array
		case("cellplot") then true;    //		Graphically display structure of cell array
		case("cellstr") then true;    //		Create cell array of strings from character array
		case("iscell") then true;    //		Determine whether input is cell array
		case("iscellstr") then true;    //		Determine whether input is cell array of strings
		case("mat2cell") then true;    //		Convert array to cell array with potentially different sized cells
		case("num2cell") then true;    //		Convert array to cell array with consistently sized cells
		case("strjoin") then true;    //		Join strings in cell array into single string
		case("strsplit") then true;    //		Split string at specified delimiter
		case("struct2cell") then true;    //		Convert structure to cell array
		// Function Handles
		case("feval") then true;    //		Evaluate function
		case("func2str") then true;    //		Construct function name string from function handle
		case("str2func") then true;    //		Construct function handle from function name string
		case("localfunctions") then true;    //		 Function handles to all local functions in MATLAB file
		// functions	Information about function handle
		// Map Containers
		case("isKey") then true;    //		Determine if containers.Map object contains key
		case("keys") then true;    //		Identify keys of containers.Map object
		case("remove") then true;    //		Remove key-value pairs from containers.Map object
		case("values") then true;    //		Identify values in containers.Map object
		// Time Series
		// Time	 Series Basics
		case("append") then true;    //		Concatenate time series objects in time dimension
		case("get") then true;    //		Query timeseries object property values
		case("getdatasamplesize") then true;    //		Size of data sample in timeseries object
		case("getqualitydesc") then true;    //		Data quality descriptions
		case("getsamples") then true;    //		Subset of time series samples using subscripted index array
		case("plot") then true;    //		Plot time series
		case("set") then true;    //		Set properties of timeseries object
		case("tsdata.event") then true;    //		Construct event object for timeseries object
		case("timeseries") then true;    //		Create timeseries object
		// Data Manipulation
		case("addsample") then true;    //		Add data sample to timeseries object
		case("ctranspose") then true;    //		Transpose timeseries object
		case("delsample") then true;    //		Remove sample from timeseries object
		case("detrend") then true;    //		Subtract mean or best-fit line and all NaNs from timeseries object
		case("filter") then true;    //		Shape frequency content of time-series
		case("getabstime") then true;    //		Extract date-string time vector into cell array
		case("getinterpmethod") then true;    //		Interpolation method for timeseries object
		case("getsampleusingtime") then true;    //		Extract data samples into new timeseries object
		case("idealfilter") then true;    //		Apply ideal (noncausal) filter to timeseries object
		case("resample") then true;    //		Select or interpolate timeseries data using new time vector
		case("setabstime") then true;    //		Set times of timeseries object as date strings
		case("setinterpmethod") then true;    //		Set default interpolation method for timeseries object
		case("synchronize") then true;    //		Synchronize and resample two timeseries objects using common time vector
		case("transpose") then true;    //		Transpose timeseries object
		// Event Data
		case("addevent") then true;    //		Add event to timeseries object
		case("delevent") then true;    //		Remove tsdata.event objects from timeseries object
		case("gettsafteratevent") then true;    //		New timeseries object with samples occurring at or after event
		case("gettsafterevent") then true;    //		New timeseries object with samples occurring after event
		case("gettsatevent") then true;    //		New timeseries object with samples occurring at event
		case("gettsbeforeatevent") then true;    //		New timeseries object with samples occurring before or at event
		case("gettsbeforeevent") then true;    //		New timeseries object with samples occurring before event
		case("gettsbetweenevents") then true;    //		New timeseries object with samples occurring between events
		// Descriptive Statistics
		case("iqr") then true;    //		Interquartile range of timeseries data
		case("max") then true;    //		Maximum value of timeseries data
		case("mean") then true;    //		Mean value of timeseries data
		case("median") then true;    //		Median value of timeseries data
		case("min") then true;    //		 Minimum value of timeseries data
		case("std") then true;    //		Standard deviation of timeseries data
		case("sum") then true;    //		Sum of timeseries data
		case("var") then true;    //		Variance of timeseries data
		// Time Series Collections
		case("get") then true;    //	 (tscollection)	Query tscollection object property values
		case("isempty") then true;    //	 (tscollection)	Determine whether tscollection object is empty
		case("length") then true;    //	 (tscollection)	Length of time vector
		case("set") then true;    //	 (tscollection)	Set properties of tscollection object
		case("size") then true;    //	 (tscollection)	Size of tscollection object
		case("tscollection") then true;    //		Create tscollection object
		case("addsampletocollection") then true;    //		Add sample to tscollection object
		case("addts") then true;    //		Add timeseries object to tscollection object
		case("delsamplefromcollection") then true;    //		Remove sample from tscollection object
		case("getabstime") then true;    //	 (tscollection)	Extract date-string time vector into cell array
		case("getsampleusingtime") then true;    //	 (tscollection)	Extract data samples into new tscollection object
		case("gettimeseriesnames") then true;    //		Cell array of names of timeseries objects in tscollection object
		case("horzcat") then true;    //	 (tscollection)	Horizontal concatenation for tscollection objects
		case("removets") then true;    //		Remove timeseries objects from tscollection object
		case("resample") then true;    //	 (tscollection)	Select or interpolate data in tscollection using new time vector
		case("setabstime") then true;    //	 (tscollection)	Set times of tscollection object as date strings
		case("settimeseriesnames") then true;    //		Change name of timeseries object in tscollection
		case("vertcat") then true;    //	 (tscollection)	Vertical concatenation for tscollection objects
		// Data Type Identification
		case("isa") then true;    //	 	Determine if input is object of specified class
		case("iscategorical") then true;    //	 	Determine whether input is categorical array
		case("iscell") then true;    //	 	Determine whether input is cell array
		case("iscellstr") then true;    //	 	Determine whether input is cell array of strings
		case("ischar") then true;    //	 	Determine whether item is character array
		case("isfield") then true;    //	 	Determine whether input is structure array field
		case("isfloat") then true;    //	 	Determine if input is floating-point array
		case("ishghandle") then true;    //	 	True for Handle Graphics object handles
		case("isinteger") then true;    //	 	Determine if input is integer array
		case("isjava") then true;    //	 	Determine if input is Java object
		case("islogical") then true;    //	 	Determine if input is logical array
		case("isnumeric") then true;    //	 	Determine if input is numeric array
		case("isobject") then true;    //	 	Determine if input is MATLAB object
		case("isreal") then true;    //	 	Check if input is real array
		case("isscalar") then true;    //	 	Determine whether input is scalar
		case("isstr") then true;    //	 	Determine whether input is character array
		case("isstruct") then true;    //	 	Determine whether input is structure array
		case("istable") then true;    //	 	Determine whether input is table
		case("isvector") then true;    //	 	Determine whether input is vector
		case("class") then true;    //	 	Determine class of object
		case("validateattributes") then true;    //	 	Check validity of array
		// Data Type Conversion
		case("char") then true;    //	 	Convert to character array (string)
		case("int2str") then true;    //	 	Convert integer to string
		case("mat2str") then true;    //	 	Convert matrix to string
		case("num2str") then true;    //	 	Convert number to string
		case("str2double") then true;    //	 	Convert string to double-precision value
		case("str2num") then true;    //	 	Convert string to number
		case("native2unicode") then true;    //	 	Convert numeric bytes to Unicode character representation
		case("unicode2native") then true;    //	 	Convert Unicode character representation to numeric bytes
		case("base2dec") then true;    //	 	Convert base N number string to decimal number
		case("bin2dec") then true;    //	 	Convert binary number string to decimal number
		case("dec2base") then true;    //	 	Convert decimal to base N number in string
		case("dec2bin") then true;    //	 	Convert decimal to binary number in string
		case("dec2hex") then true;    //	 	Convert decimal to hexadecimal number in string
		case("hex2dec") then true;    //	 	Convert hexadecimal number string to decimal number
		case("hex2num") then true;    //	 	Convert hexadecimal number string to double-precision number
		case("num2hex") then true;    //	 	Convert singles and doubles to IEEE hexadecimal strings
		case("table2array") then true;    //	 	Convert table to homogenous array
		case("table2cell") then true;    //	 	Convert table to cell array
		case("table2struct") then true;    //	 	Convert table to structure array
		case("array2table") then true;    //	 	Convert homogeneous array to table
		case("cell2table") then true;    //	 	Convert cell array to table
		case("struct2table") then true;    //	 	Convert structure array to table
		case("cell2mat") then true;    //	 	Convert cell array to numeric array
		case("cell2struct") then true;    //	 	Convert cell array to structure array
		case("cellstr") then true;    //	 	Create cell array of strings from character array
		case("mat2cell") then true;    //	 	Convert array to cell array with potentially different sized cells
		case("num2cell") then true;    //	 	Convert array to cell array with consistently sized cells
		case("struct2cell") then true;    //	 	Convert structure to cell array
		// Dates and Time
		case("datenum") then true;    //	 	Convert date and time to serial date number
		case("datevec") then true;    //	 	Convert date and time to vector of components
		case("datestr") then true;    //	 	Convert date and time to string format
		case("now") then true;    //	 	Current date and time as serial date number
		case("clock") then true;    //	 	Current date and time as date vector
		case("date") then true;    //	 	Current date string
		case("calendar") then true;    //	 	Calendar for specified month
		case("eomday") then true;    //	 	Last day of month
		case("weekday") then true;    //	 	Day of week
		case("addtodate") then true;    //	 	Modify date number by field
		case("etime") then true;    //	 	Time elapsed between date vectors
		// Mathematics
		
		// Elementary Math
		// Arithmetic
		case("plus") then true;    //	 	 Addition
		case("uplus") then true;    //	 	Unary plus
		case("minus") then true;    //	 	Subtraction
		case("uminus") then true;    //	 	Unary minus
		case("times") then true;    //	 	Element-wise multiplication
		case("rdivide") then true;    //	 	 Right array division
		case("ldivide") then true;    //	 	Left array division
		case("power") then true;    //	 	Element-wise power
		case("mtimes") then true;    //	 	Matrix Multiplication
		case("mrdivide") then true;    //	 	Solve systems of linear equations xA = B for x
		case("mldivide") then true;    //	 	Solve systems of linear equations Ax = B for x
		case("mpower") then true;    //	 	Matrix power
		case("cumprod") then true;    //	 	Cumulative product
		case("cumsum") then true;    //	 	Cumulative sum
		case("diff") then true;    //	 	Differences and Approximate Derivatives
		case("prod") then true;    //	 	Product of array elements
		case("sum") then true;    //	 	Sum of array elements
		case("ceil") then true;    //	 	Round toward positive infinity
		case("fix") then true;    //	 	Round toward zero
		case("floor") then true;    //	 	Round toward negative infinity
		case("idivide") then true;    //	 	Integer division with rounding option
		case("mod") then true;    //	 	Modulus after division
		case("rem") then true;    //	 	Remainder after division
		case("round") then true;    //	 	Round to nearest integer
		// Trigonometry
		case("sin") then true;    //	 	Sine of argument in radians
		case("sind") then true;    //	 	Sine of argument in degrees
		case("asin") then true;    //	 	Inverse sine in radians
		case("asind") then true;    //	 	Inverse sine in degrees
		case("sinh") then true;    //	 	Hyperbolic sine of argument in radians
		case("asinh") then true;    //	 	Inverse hyperbolic sine
		case("cos") then true;    //	 	Cosine of argument in radians
		case("cosd") then true;    //	 	Cosine of argument in degrees
		case("acos") then true;    //	 	Inverse cosine in radians
		case("acosd") then true;    //	 	Inverse cosine in degrees
		case("cosh") then true;    //	 	Hyperbolic cosine
		case("acosh") then true;    //	 	Inverse hyperbolic cosine
		case("tan") then true;    //	 	Tangent of argument in radians
		case("tand") then true;    //	 	Tangent of argument in degrees
		case("atan") then true;    //	 	Inverse tangent in radians
		case("atand") then true;    //	 	Inverse tangent in degrees
		case("atan2") then true;    //	 	Four-quadrant inverse tangent
		case("atan2d") then true;    //	 	Four-quadrant inverse tangent in degrees
		case("tanh") then true;    //	 	Hyperbolic tangent
		case("atanh") then true;    //	 	Inverse hyperbolic tangent
		case("csc") then true;    //	 	Cosecant of argument in radians
		case("cscd") then true;    //	 	Cosecant of argument in degrees
		case("acsc") then true;    //	 	Inverse cosecant in radians
		case("acscd") then true;    //	 	Inverse cosecant in degrees
		case("csch") then true;    //	 	Hyperbolic cosecant
		case("acsch") then true;    //	 	Inverse hyperbolic cosecant
		case("sec") then true;    //	 	Secant of argument in radians
		case("secd") then true;    //	 	Secant of argument in degrees
		case("asec") then true;    //	 	Inverse secant in radians
		case("asecd") then true;    //	 	Inverse secant in degrees
		case("sech") then true;    //	 	Hyperbolic secant
		case("asech") then true;    //	 	Inverse hyperbolic secant
		case("cot") then true;    //	 	Cotangent of argument in radians
		case("cotd") then true;    //	 	Cotangent of argument in degrees
		case("acot") then true;    //	 	Inverse cotangent in radians
		case("acotd") then true;    //	 	Inverse cotangent in degrees
		case("coth") then true;    //	 	Hyperbolic cotangent
		case("acoth") then true;    //	 	Inverse hyperbolic cotangent
		case("hypot") then true;    //	 	Square root of sum of squares
		// Exponents and Logarithms
		case("exp") then true;    //	 	Exponential
		case("expm1") then true;    //	 	Compute exp(x)-1 accurately for small values of x
		case("log") then true;    //	 	Natural logarithm
		case("log10") then true;    //	 	Common (base 10) logarithm
		case("log1p") then true;    //	 	Compute log(1+x) accurately for small values of x
		case("log2") then true;    //	 	Base 2 logarithm and dissect floating-point numbers into exponent and mantissa
		case("nextpow2") then true;    //	 	Exponent of next higher power of 2
		case("nthroot") then true;    //	 	Real nth root of real numbers
		case("pow2") then true;    //	 	Base 2 power and scale floating-point numbers
		case("reallog") then true;    //	 	Natural logarithm for nonnegative real arrays
		case("realpow") then true;    //	 	Array power for real-only output
		case("realsqrt") then true;    //	 	Square root for nonnegative real arrays
		case("sqrt") then true;    //	 	Square root
		case("abx") then true; //absolute value

    case(_) then false;
end matchcontinue;
end builtIn;


end Mat_Builtin;
