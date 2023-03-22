/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#define ANTLR4CPP_STATIC
#include "antlr4-runtime.h"
#include "modelicaLexer.h"
#include "modelicaParser.h"
#include "modelicaBaseListener.h"

#include "Parser.h"

static std::string cmt = "";

class ModelicaCommentListener : public openmodelica::modelicaBaseListener {
  void exitComment(openmodelica::modelicaParser::CommentContext *ctx) override {
    cmt = ctx->getText();
  }
};

/*!
 * \brief FlatModelica::Parser::getModelicaComment
 * \param element
 * \return comment
 */
QString FlatModelica::Parser::getModelicaComment(QString element)
{
  cmt = "";
  std::string s = element.toStdString();
  antlr4::ANTLRInputStream input(s);
  openmodelica::modelicaLexer lexer(&input);
  antlr4::CommonTokenStream tokens(&lexer);
  openmodelica::modelicaParser parser(&tokens);
  antlr4::tree::ParseTree* tree = parser.argument();
  ModelicaCommentListener listener;
  antlr4::tree::ParseTreeWalker::DEFAULT.walk(&listener, tree);
  if (cmt.size() > 1) {
    return QString::fromStdString(cmt);
  }
  return element;
}

/*!
 * \brief FlatModelica::Parser::getTypeFromElementRedeclaration
 * \param elmentRedeclaration
 * Parses the code like,
 * redeclare ClassA classA "A"
 * and returns ClassA, the type of the component.
 * \return
 */
QString FlatModelica::Parser::getTypeFromElementRedeclaration(const QString &elmentRedeclaration)
{
  antlr4::ANTLRInputStream input(elmentRedeclaration.toStdString());
  openmodelica::modelicaLexer lexer(&input);
  antlr4::CommonTokenStream tokens(&lexer);
  openmodelica::modelicaParser parser(&tokens);
  openmodelica::modelicaParser::Element_redeclarationContext *pElement_redeclarationContext = parser.element_redeclaration();
  if (pElement_redeclarationContext && pElement_redeclarationContext->component_clause1()) {
    return QString::fromStdString(pElement_redeclarationContext->component_clause1()->type_specifier()->getText());
  }
  return "";
}

/*!
 * \brief FlatModelica::Parser::getShortClassTypeFromElementRedeclaration
 * \param elmentRedeclaration
 * Parses the code like,
 * redeclare model M = C
 * and returns M, the type of the short class specifier.
 * \return
 */
QString FlatModelica::Parser::getShortClassTypeFromElementRedeclaration(const QString &elmentRedeclaration)
{
  antlr4::ANTLRInputStream input(elmentRedeclaration.toStdString());
  openmodelica::modelicaLexer lexer(&input);
  antlr4::CommonTokenStream tokens(&lexer);
  openmodelica::modelicaParser parser(&tokens);
  openmodelica::modelicaParser::Element_redeclarationContext *pElement_redeclarationContext = parser.element_redeclaration();
  if (pElement_redeclarationContext && pElement_redeclarationContext->short_class_definition()) {
    return QString::fromStdString(pElement_redeclarationContext->short_class_definition()->short_class_specifier()->type_specifier()->getText());
  }
  return "";
}
