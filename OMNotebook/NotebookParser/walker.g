/*! \file walker.g 
 * \author Ingemar Axelsson
 * 
 * \brief TreeParser that creates the widgetstructure.
 * 
 * Traverses the ast and builds a widgettree using Textcells, 
 * groupcells and inputcells. 
 *
 * \todo Look for memory leaks in this code. There is probably a 
 * lot of them here.(Ingemar Axelsson)
 */

header {
//STD Headers
#include <iostream>
//#include <string>
#include <sstream>
#include <cstdlib>
#include <vector>
#include <map>
#include <algorithm>

#include <QtCore/QString>

//IAEX Headers
#include "cell.h"
#include "rule.h"
#include "factory.h"
#include "stripstring.h"

using namespace std;
using namespace IAEX;
        
typedef pair<string,string> rule_t;

typedef vector<rule_t> rules_t;

//typedef stringstream content_t;
//typedef pair<content_t, rules_t>  result_t;

///pair<stringstream,vector<pair<string,string> > > result_t

class result_t
{
public:
   result_t(ostringstream &f):first(f){}
   result_t(ostringstream &f, vector<rule_t> &s)
   :first(f), second(s){}
   
   ostringstream& first;
   vector<rule_t> second;
};

}

options
{
    language="Cpp";     //Generate C++ languages.
    genHashLines=false; //Do not generate hashlines.
}

//////////////////////////////////////////////////////////////////////

class AntlrNotebookTreeParser extends TreeParser;

options
{
    k=2;
    importVocab=notebookgrammar;
    buildAST=false;
}


{
    //This is in NotebookTreeParser.hpp
    Factory *factory;
    Cell *workspace;
    ostringstream output;
    //This is not very nice.   
    
    // AF
    bool imagePartOfText; 
}
document[Cell *ws, Factory *f]
{
    //This is in NotebookTreeParser.cpp
    factory = f;
    workspace = ws;
    
    
    // AF
    imagePartOfText = false;
    
    
    result_t result(output);// = new result_t; //??
}
    : expr[result]
        {
            //cout << (*result).first.str() << endl;
        }
    ;

expr [result_t &result]
{
    string val;
    string attr;
}
    : (MODULENAME THICK)* exprheader[result]
        {
        }
    | val = value
        {
            result.first << val;
        }
    | attr= attribute
        {
            result.first << attr;
        }
    ;

exprheader [result_t &result]
{
    rules_t rules;
}
    :   {
        }
        #(NOTEBOOK expr[result] (expr[result])* (rule[rules])*)
        {
        }
    |   {
            ostringstream listoutput;
            result_t list(listoutput);
        }
        #(LIST (listelement[list])*)
        {
			//2005-11-09 AF, Added a function for adding/removeing some
			//chars/symbols from the text
            string str = StripString::stripNBString( list.first.str() );
        
			result.first << str << endl;
        }
    |   #(LISTBODY expr[result])
        {
        }
    |   {  
    	    ostringstream contentoutput;
            result_t content(contentoutput);
        }
        #(CELL expr[content] (style:QSTRING)? (rule[rules])*)
        {               
			//2005-11-09 AF, Added a function for adding/removeing some
			//chars/symbols from the text
            string cnt = StripString::stripNBString( content.first.str() );
                        
            if(style)
            {
				QString qcnt(cnt.c_str());
	            	
				string s1 = style->getText();
				s1.assign(s1, 1, s1.length()-2);

				QString cellstyle(s1.c_str());
				
				// 2005-11-09 AF,	
				// if the cellstyle is "Graphics" a new cell shouldn't always be added, sometimes
				// a image should be added in the existing cell
				if( cellstyle == "Graphics" )
				{
					// TODO: DEBUG code, remove when doing release
					/*
					if( imagePartOfText )
					{
						result.first << "IMAGE" << endl;
					}
					else
					{
						Cell *text = factory->createCell("Text", workspace);
						text->setText("IMAGE CELL");
						text->setStyle("Text");
						
						workspace->addChild(text);
					}
					*/
				}
				else
				{	
					Cell *text = factory->createCell(cellstyle, workspace);
	                
					//RULES
					//Rules from content.
					for(rules_t::iterator i=content.second.begin();i!=content.second.end();++i)
					{
						//AF text->setStyle(QString((*i).first.c_str()), QString((*i).second.c_str()));
						//text->addRule(new Rule(QString((*i).first.c_str()), QString((*i).second.c_str())));
					}
	                
					//Rules from tag.
					for(rules_t::iterator j = rules.begin(); j != rules.end(); j++)
					{
						//AF text->setStyle(QString((*j).first.c_str()), QString((*j).second.c_str()));
						text->addRule(new Rule(QString((*j).first.c_str()), QString((*j).second.c_str())));
					}
	                
					//STYLE
					// 2005-11-08 AF, ändrat ordningen så att setText görs före setStyle
					text->setText( qcnt );
					//text->setStyle( cellstyle );
	                
					workspace->addChild(text);
				}
            }
            else
            {   //This is really ugly, but it works most of the time. 
                //This is only happening when a Cell does not have a style. It seems 
                //to happen only with cells inside textdata-expressions. 
                result.first << cnt;
            }
        }
    |   {
            //CellGroup *group = new CellGroup(workspace->doc());
            //CellGroup *parent = workspace;
            Cell *group = factory->createCell("cellgroup", workspace);
            Cell *parent = workspace;
            workspace = group;
        }   
        #(CELLGROUPDATA expr[result] (opengroup:CELLGROUPOPEN|closegroup:CELLGROUPCLOSED))
        {
        	if( opengroup )
				group->setClosed( false );
			else if( closegroup )
				group->setClosed( true );
		
					
            workspace = parent;
            workspace->addChild(group);
        }
    |   {
    	    ostringstream sboutput;
            result_t sbcontent(sboutput);
            rules_t stylerules;
        }
        #(STYLEBOX expr[sbcontent] (sbstyle:QSTRING|(rule[stylerules])+)?)
        {
            if(sbstyle)
            {
                //What happends if a style is added here?
            }
            else
            {   
                rules_t::iterator i = stylerules.begin();
                for(; i != stylerules.end();++i)
                {
                    //cout << "STYLERULES: " << (*i).first << "->" << (*i).second << endl;
                    result.second.push_back(*i);
                }
            }
            
            //2005-11-09 AF, Added a function for adding/removeing some
			//chars/symbols from the text
            string str = StripString::stripNBString( sbcontent.first.str() );
            
            // 2005-12-06 AF, Apply the rules to the text
            str = StripString::applyRulesToText( str, stylerules );
            
            result.first << str; //sbcontent.first.str();
        }
    | 
        {
			imagePartOfText = true;
        }
        #(TEXTDATA expr[result] (expr[result])* (rule[rules])*)
        {
            imagePartOfText = false;
        }
    | 
        {
            ostringstream baseoutput;
            ostringstream expoutput;
            result_t base(baseoutput);
            result_t exp(expoutput);
        }
        #(SUPERSCRBOX   expr[base] expr[exp])
        {
            result.first << base.first.str() << "<sup>" << exp.first.str() << "</sup>";
                        
            rules_t::iterator i = base.second.begin();
            for(; i != base.second.end(); ++i)
            {
                result.second.push_back((*i));               
            }
            rules_t::iterator j = exp.second.begin();
            for(; j != exp.second.end(); ++j)
            {
                result.second.push_back((*j));               
            }
        }
    |
        {
			ostringstream baseoutputSub;
            ostringstream expoutputSub;
            result_t baseSub(baseoutputSub);
            result_t expSub(expoutputSub);
        }
        #(SUBSCRBOX   expr[baseSub] expr[expSub])
        {
			result.first << baseSub.first.str() << "<sub>" << expSub.first.str() << "</sub>";
                        
            rules_t::iterator i = baseSub.second.begin();
            for(; i != baseSub.second.end(); ++i)
            {
                result.second.push_back((*i));               
            }
            rules_t::iterator j = expSub.second.begin();
            for(; j != expSub.second.end(); ++j)
            {
                result.second.push_back((*j));               
            }
        }
    |   
        {
            //Translates all buttons into hyperlinks.
            ostringstream btoutput;
            result_t buttonTitle(btoutput);
            rules_t buttonRules;
        }
        #(BUTTONBOX   expr[buttonTitle] (expr[result])* (rule[buttonRules])*)
        {         
            string filename;
            //Check rules. Look for ButtonData ->Filename and ButtonStyle=Hyperlink
            rules_t::iterator i = buttonRules.begin();
            for(; i != buttonRules.end();++i)
            {
                if((*i).first == "ButtonData")
                {
                    //cout << "BUTTONBOX RULES: " << (*i).first << "->" 
                    //     << (*i).second << endl;
                    filename = (*i).second;
                }
                //result.second.push_back(*i);
            }
            
            
            // 2006-02-10 AF, Add '#' to filename. Links should have '#'
            // for specifing internel references. For example internal 
            // referenses for a link;
            // HTML link: Dir/filename.html#ChaperSeven
            // filename looks like: Dir/filename.htmlChapterSeven
            // have to insert # symbol
            filename = StripString::fixFilename( filename );
            

            result.first << "<a href=\"" << filename << "\">" 
                         << buttonTitle.first.str() << "</a>";
        }
    |   {
    	    ostringstream diroutput;
    	    ostringstream filenameoutput;
            result_t dir(diroutput);
            result_t filename(filenameoutput);
            rules_t filenameRules;
        }
        #(FILENAME      expr[dir] (expr[filename])* (rule[filenameRules])* )
        {
            //Delete strange newline in directory string.
            string d = dir.first.str();
            d.assign(d, 0, d.length()-1);
           
            result.first << d << "/" << filename.first.str();
        }
    |   
        {
		}
		#(GRAPHICSDATA	 type:QSTRING	data:QSTRING)
		{
		}
	|	
	    {
	    }
	    #(DIREXTEDINFINITY infinitytype:NUMBER)
	    {
	    }
	|
	    {
			ostringstream boxdataoutput;
            result_t boxdata(boxdataoutput);
		}
		#(BOXDATA       expr[boxdata] (expr[result])* (rule[rules])*)
		{
			result.first << StripString::stripSimulationData(boxdata.first.str());
		}
	|	{
		}
		#(RGBCOLOR      red:NUMBER		green:NUMBER	blue:NUMBER)
		{
			if( red && green && blue )
				result.first << red->getText() << ":" << green->getText() << ":" << blue->getText();
			else
				result.first << "7777:3333:2222";
		}
    | #(ROWBOX        expr[result] (expr[result])* (rule[rules])*)
    | #(FORMBOX       expr[result] (expr[result])* (rule[rules])*)
    | #(TAGBOX        expr[result] (expr[result])* (rule[rules])*)
    | #(COUNTERBOX    expr[result] (expr[result])* (rule[rules])*)
    | #(ADJUSTMENTBOX expr[result] (expr[result])* (rule[rules])*)
    | #(SUBSUPERSCRIPTBOX expr[result] (expr[result])* (rule[rules])*)
    | #(UNDERSCRIPTBOX expr[result] (expr[result])* (rule[rules])*)
    | #(OVERSCRIPTBOX expr[result] (expr[result])* (rule[rules])*)
    | #(UNDEROVERSCRIPTBOX expr[result] (expr[result])* (rule[rules])*)
    | #(FRACTIONBOX expr[result] (expr[result])* (rule[rules])*)
    | #(SQRTBOX       expr[result] (expr[result])* (rule[rules])*)
    | #(RADICALBOX    expr[result] (expr[result])* (rule[rules])*)
    | #(GRAYLEVEL     expr[result] (expr[result])* (rule[rules])*)
    | #(STYLEDATA     expr[result] (expr[result])* (rule[rules])*)
    | #(NOT_MATH_OLEDATE expr[result] (expr[result])* (rule[rules])*)
    ;

listelement[result_t &list]
{ 
    ostringstream resoutput;
    result_t result(resoutput);
}
    :   expr[result]
        {
            list.first << result.first.str();
        }
    ;


rule [rules_t &rules]
{
    ostringstream attoutput;
    ostringstream valoutput;
    result_t attribute(attoutput);
    result_t value(valoutput);
}
    :   {
            
        }
        #(RULE expr[attribute] expr[value])
        {   
            //rules.push_back(Rule(attribute.first.str(), value.first.str()));
            rules.push_back(rule_t(attribute.first.str(), value.first.str()));
        }
    | #(RULEDELAYED expr[attribute] expr[value])
        {
            //rules.push_back(Rule(attribute.first.str(), value.first.str()));
            rules.push_back(rule_t(attribute.first.str(), value.first.str()));
        }
    ;


value returns [string value]
    : str:QSTRING
        {
            //Move this to TextCell.
            
            //Delete quotes
            value = str->getText();
            value.assign(value, 1, value.length()-2);            
        }
    | num:NUMBER
        {
            value = string(num->getText());   
        }
    | tr:TRUE_
        {
            value = string(tr->getText()); 
        }
    | fl:FALSE_
        {
            value =string(fl->getText());
        }
    | rightval:VALUERIGHT //Right / Left
        {
            value = string(rightval->getText()); 
        }
    | leftval:VALUELEFT //Right / Left
        {
            value = string(leftval->getText()); 
        }
    | centerval:VALUECENTER
        {
            value = string(centerval->getText());
        }
    | smallerval:VALUESMALLER
        {
            value = string(smallerval->getText());
        }
    | inherited:INHERITED
        {
		    value = string(inherited->getText());
		}
	| paperwidth:PAPERWIDTH
	    {
	        value = string(paperwidth->getText());
	    }
	| windowwidth:WINDOWWIDTH
	    {
	        value = string(windowwidth->getText());
	    }
    | tradform:TRADITIONALFORM
        {
            //value = string(tradform->getText()); 
        }
    | stdform:STANDARDFORM
        {
            //value = string(stdform->getText()); 
        }
    | inputform:INPUTFORM
        {
            //value = string(inputform->getText()); 
        }
    | outputform:OUTPUTFORM
        {
            //value = string(outputform->getText()); 
        }
    | defaultinputformattype:DEFAULTINPUTFORMATTYPE
        {
            value = string(defaultinputformattype->getText());
        }
    | automatic:AUTOMATIC
        {
            //value = string(automatic->getText()); 
        }
    | none:NONESYM
        {
            //value = string(none->getText()); 
        }
    | nullsym:NULLSYM
        {
            value = string(nullsym->getText());
        }
    | allsym:ALLSYM
        {
            value = string(allsym->getText());
        }
    ;

attribute returns [string value]
    : fontslant:FONTSLANT       
        {
            value = string(fontslant->getText());
        }
    | fontsize:FONTSIZE        
        {
            value = string(fontsize->getText());
        }
    | fontcolor:FONTCOLOR       
        {
            value = string(fontcolor->getText());
        }
    | fontweight:FONTWEIGHT      
        {
            value = string(fontweight->getText());
        }
    | fontfamily:FONTFAMILY      
        {
            value = string(fontfamily->getText());
        }
    | fontvariations:FONTVARIATIONS  
        {
            value = string(fontvariations->getText());
        }
    | textalignment:TEXTALIGNMENT   
        {
            value = string(textalignment->getText());
        }
    | textjustification:TEXTJUSTIFICATION
        {
            value = string(textjustification->getText());
        }
    | initializationcell:INITIALIZATIONCELL
        {
            value = string(initializationcell->getText());
        }
    | formattype:FORMATTYPE_TOKEN
        {
            value = string(formattype->getText());
        }
    | pagewidth:PAGEWIDTH
        {
            value = string(pagewidth->getText());
        }
    | pageheaders:PAGEHEADERS
        {
            value = string(pageheaders->getText());
        }
    | pageheaderlines:PAGEHEADERLINES
        {
            value = string(pageheaderlines->getText());
        }
    | pagefooters:PAGEFOOTERS
        {
            value = string(pagefooters->getText());
        }
    | pagefooterlines:PAGEFOOTERLINES
        {
            value = string(pagefooterlines->getText());
        }
    | pagebreakbelow:PAGEBREAKBELOW
        {
            value = string(pagebreakbelow->getText());
        }
    | pagebreakwithin:PAGEBREAKWITHIN
        {
            value = string(pagebreakwithin->getText());
        }
    | boxmargins:BOXMARGINS
        {
            value = string(boxmargins->getText());
        }
    | boxbaselineshift:BOXBASELINESHIFT
        {
            value = string(boxbaselineshift->getText());
        }
    | linespacing:LINESPACING
        {
            value = string(linespacing->getText());
        }
    | hyphenation:HYPHENATION
        {
            value = string(hyphenation->getText());
        }
    | activetoken:ACTIVE_TOKEN
        {
            value = string(activetoken->getText());
        }
    | evaluatable:EVALUATABLE
        {
            value = string(evaluatable->getText());
        }
    | buttonfunction:BUTTONFUNCTION
        {
            value = string(buttonfunction->getText());
        }
    | buttondata:BUTTONDATA      
        {
            value = string(buttondata->getText());
        }
    | buttonevaluator:BUTTONEVALUATOR
        {
            value = string(buttonevaluator->getText());
        }
    | buttonstyle:BUTTONSTYLE     
        {
            value = string(buttonstyle->getText());
        }
    | characterencoding:CHARACHTERENCODING
        {
            value = string(characterencoding->getText());
        }
    | showstringcharacters:SHOWSTRINGCHARACTERS
        {
            value = string(showstringcharacters->getText());
        }
    | screenrectangle:SCREENRECTANGLE
        {
            value = string(screenrectangle->getText());
        }
    | autogeneratedpackage:AUTOGENERATEDPACKAGE
        {
            value = string(autogeneratedpackage->getText());
        }
    | autoitalicwords:AUTOITALICWORDS
        {
            value = string(autoitalicwords->getText());
        }
    | inputautoreplacements:INPUTAUTOREPLACEMENTS
        {
            value = string(inputautoreplacements->getText());
        }
    | scriptminsize:SCRIPTMINSIZE
        {
            value = string(scriptminsize->getText());
        }
    | stylemenulisting:STYLEMEMULISTING
        {
            value = string(stylemenulisting->getText());
        }
    | counterincrements:COUNTERINCREMENTS
        {
            value = string(counterincrements->getText());
        }
    | counterassignments:COUNTERASSIGNMENTS
        {
            value = string(counterassignments->getText());
        }
    | privateevaloptions:PRIVATEEVALOPTIONS
        {
            value = string(privateevaloptions->getText());
        }
    | grouppagewithin:GROUPPAGEBREAKWITHIN
        {
            value = string(grouppagewithin->getText());
        }
    | defaultformattype:DEFAULTFORMATTYPE
        {
            value = string(defaultformattype->getText());
        }
    | numbermarks:NUMBERMARKS
        {
            value = string(numbermarks->getText());
        }
    | linebreakadjustments:LINEBREAKADJUSTMENTS
        {
            value = string(linebreakadjustments->getText());
        }
    | celltags:CELLTAGS
        {
            value = string(celltags->getText());
        }
    | cellframe:CELLFRAME
        {
            value = string(cellframe->getText());
        }
    | cellframecolor:CELLFRAMECOLOR
        {
            value = string(cellframecolor->getText());
        }
    | cellframelabels:CELLFRAMELABELS
        {
            value = string(cellframelabels->getText());
        }
    | cellframemargins:CELLFRAMEMARGINS
        {
            value = string(cellframemargins->getText());
        }
    | cellframelabelmargins:CELLFRAMELABELMARGINS
        {
            value = string(cellframelabelmargins->getText());
        }
    | celllabelmargins:CELLLABRLMARGINS
        {
            value = string(celllabelmargins->getText());
        }
    | celllabelpositioning:CELLLABELPOSITIONING
        {
            value = string(celllabelpositioning->getText());
        }
    | cellmargins:CELLMARGINS
        {
		    value = string(cellmargins->getText());
		}
	| celldingbat:CELLDINGBAT
	    {
	        value = string(celldingbat->getText());
	    }
	| cellhorizontalscrolling:CELLHORIZONTALSCROLL
	    {
	        value = string(cellhorizontalscrolling->getText());
	    }
    | cellgenerated:CELLGENERATED
        {
            value = string(cellgenerated->getText());
        }
    | cellshowbracket:SHOWCELLBRACKET
        {
            value = string(cellshowbracket->getText());
        }
    | cellshowlabel:SHOWCELLLABEL
        {
            value = string(cellshowlabel->getText());
        }
    | cellbracketoptions:CELLBRACKETOPT
        {
            value = string(cellbracketoptions->getText());
        }
    | editable:EDITABLE     
        {
            value = string(editable->getText());
        }
    | background:BACKGROUND   
        {
            value = string(background->getText());
        }
    | cellgroupingrules:CELLGROUPINGRULES
        {
            value = string(cellgroupingrules->getText());
        }
    | windowsize:WINDOWSIZE     
        {
            value = string(windowsize->getText());
        }
    | windowmargins:WINDOWMARGINS  
        {
            value = string(windowmargins->getText());
        }
    | windowframe:WINDOWFRAME    
        {
            value = string(windowframe->getText());
        }
    | windowelements:WINDOWELEMENTS 
        {
            //value = string(attr->getText());
        }
    | windowtitle:WINDOWTITLE    
        {
            //value = string(attr->getText());
        }
    | windowtoolbars:WINDOWTOOLBARS 
        {
            //value = string(attr->getText());
        }
    | windowmoveable:WINDOWMOVEABLE 
        {
            //value = string(attr->getText());
        }
    | windowfloating:WINDOWFLOATING 
        {
            //value = string(attr->getText());
        }
    | windowclickselect:WINDOWCLICKSELECT
        {
            //value = string(attr->getText());
        }
    | styledefinitions:STYLEDEFINITIONS
        {
            value = string(styledefinitions->getText());
        }
    | frontendversion:FRONTENDVERSION 
        {
            value = string(frontendversion->getText());
        }
    | screenstyleenv:SCREENSTYLEENV
        {
            value = string(screenstyleenv->getText());
        }
    | printingstyleenv:PRINTINGSTYLEENV
        {
            value = string(printingstyleenv->getText());
        }
    | printingoptions:PRINTINGOPTIONS
        {
            value = string(printingoptions->getText());
        }
    | privatefontoption:PRIVATEFONTOPTIONS
        {
            value = string(privatefontoption->getText());
        }
    | magnification:MAGNIFICATION 
        {
            value = string(magnification->getText());
        }
    | generatedCell:GENERATEDCELL
        {
            value = string(generatedCell->getText());
        }
    | cellautoovrt:CELLAUTOOVRT 
        {
            value = string(cellautoovrt->getText());
        }
    | imagesize:IMAGESIZE
        {
            value = string(imagesize->getText());
        }
    | imagemargins:IMAGEMARGINS     
        {
            value = string(imagemargins->getText());
        }
    | imageregion:IMAGEREGION      
        {   
            value = string(imageregion->getText());
        }
    | imagerangecache:IMAGERANGECACHE
        {
            value = string(imagerangecache->getText());
        }
    | imagecache:IMAGECACHE      
        {
            value = string(imagecache->getText());
        }
    ;
