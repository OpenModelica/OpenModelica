/*
 * This file is part of Modelica Development Tooling.
 *
 * Copyright (c) 2005, Linköpings universitet, Department of
 * Computer and Information Science, PELAB
 *
 * All rights reserved.
 *
 * (The new BSD license, see also
 * http://www.opensource.org/licenses/bsd-license.php)
 *
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in
 *   the documentation and/or other materials provided with the
 *   distribution.
 *
 * * Neither the name of Linköpings universitet nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package org.openmodelica.corba;

/**
 * Thrown when compiler reports an unexpected error while invoking
 * some command via the 'interactive api' interface. That is when
 * compiler replys 'error' instead of returning the results in a situation
 * where no error are expected.
 *
 * @author Elmir Jagudin
 */
public class InvocationError extends CompilerException
{
	private static final long serialVersionUID = 1437868457853593664L;
	private String action;
	private String expression;

	/**
	 * @param action human readable decscription of what action failed
	 * @param expression the expression what was send to OMC that failed
	 * @see InvocationError#getAction()
	 * @see InvocationError#getExpression()
	 */
	public InvocationError(String action, String expression)
	{
		super("OMC replyed 'error' to '" + expression + "'");
		this.action = action;
		this.expression = expression;
	}

	/**
	 * Get the human readable description of the action that triggered this
	 * error. E.g. 'fetching contents of class foo.bar'
	 *
	 * The description should be phrased so that
	 */
	public String getAction()
	{
		return action;
	}

	public String getExpression()
	{
		return expression;
	}
}
