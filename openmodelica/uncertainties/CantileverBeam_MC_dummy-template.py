
from openturns import *
from math import * 

<%distributions%>
<%correlationMatrix%>
<%collectionDistributions%>
<%inputDescriptions%>

# Use that function defined in the wrapper
# Create a NumericalMathFunction from wrapper
deviation = NumericalMathFunction("<%wrapperName%>")

dim = deviation.getInputDimension()
print 'Dimension of input to modelica model: '
print dim
print '\n'
x = NumericalPoint (dim)
x[0] = 10.
x[1] = 20.
x[2] = 30.
x[3] = 30.
print x
y = deviation (x)
print y
