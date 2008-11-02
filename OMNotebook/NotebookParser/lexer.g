/*! \file lexer.g
* \author Ingemar Axelsson
*
* Lexer that recognizes all tokens in a notebookfile. The lexer has a
* lookahead of 3. This is mostly because of the comments. But it is
* fast enough. Note that everything inside a notebookfile that is
* between (* and *) are comments. Even the cache is comments. Therefore
* most of the notebookfile does not need to be read.
*
*
* Entering characters in Mathematica
*
* -directly (All ASCII 7 Characters)
* -fullname ex. \[Alpha]
* -alias ??
* -character code ex. \053
*
*
* Character strings
* - "characters"
* - \" - a literal " in a string
* - \\ - a literal \ in a string
* - \< ... \> - a substring in which newlines are interpreted literally
* - \!\( ... \) - a substring representing two-dimensional boxes
*
* SYMBOLS
* Can contain digits, but can not start with digits.
* - name   - symbol name
* - `name  - symbol name in current context
* - context`name - symbol name in specified context
*
* NUMBERS
* - digits                  integer
* - digits.digits           approximate number
* - base^^digits            integer in specified base
* - base^^digits.digits     approx. in specified base
* - mantissa *^ n           sci.not (mantissa * 10^n)
* - base^^mantissa *^ n     (mantissa * base^n) base == 2..36
* - number`                 Machine precision approx, number
* - number`s                arbitrary precision number with precision s
* - number``s               arbitrary precision number with accuracy s
*
* BRACKETS
*
* - (* ... *)         Comments
* - { ... }           list
* - < ... >           AngleBracket
* - | ... |           BracketingBar
* - || ... ||         DoubleBracketingBar
* - \( input \)       Input or grouping of boxes.
*
*/

options
{
language="Cpp";     //Generate C++ languages.
genHashLines=false; //Do not generate hashlines.
}

class AntlrNotebookLexer extends Lexer;
options
{
  k= 3;
  charVocabulary='\u0000'..'\u007F'; //Allow ascii
  exportVocab=notebookgrammar;
  defaultErrorHandler = true;
}
tokens
{
    MODULENAME      = "FrontEnd";
    LIST            = "List";
    LIST_SMALL      = "list";
    NOTEBOOK        = "Notebook";
    CELL            = "Cell";
    TEXTDATA        = "TextData";
    CELLGROUPDATA   = "CellGroupData";

    RULE            = "Rule";
    RULE_SMALL      = "rule";
    RULEDELAYED     = "RuleDelayed";

    GRAYLEVEL       = "GrayLevel";
    RGBCOLOR        = "RGBColor";
    FILENAME        = "FileName";

    STYLEBOX        = "StyleBox";
    STYLEDATA       = "StyleData";
    BOXDATA         = "BoxData";
    BUTTONBOX       = "ButtonBox";
    FORMBOX         = "FormBox";
    ROWBOX          = "RowBox";
    GRIDBOX         = "GridBox";
    TAGBOX          = "TagBox";
    COUNTERBOX      = "CounterBox";
    ADJUSTMENTBOX   = "AdjustmentBox";
    SUPERSCRBOX     = "SuperscriptBox";
    SUBSCRBOX       = "SubscriptBox";
    SUBSUPERSCRIPTBOX = "SubsuperscriptBox";
    UNDERSCRIPTBOX  = "UnderscriptBox";
    OVERSCRIPTBOX   = "OverscriptBox";
    UNDEROVERSCRIPTBOX = "UnderoverscriptBox";
    FRACTIONBOX     = "FractionBox";
    SQRTBOX         = "SqrtBox";
    RADICALBOX      = "RadicalBox";
    INTERPRETATIONBOX          = "InterpretationBox";
    ANNOTATION                 = "Annotation";
    EQUAL                      = "Equal";
    DIAGRAM                    = "Diagram";
    ICON                       = "Icon";
    POLYGON                    = "Polygon";
    ELLIPSE                    = "Ellipse";
    LINE                       = "Line";
    DIREXTEDINFINITY           = "DirectedInfinity";
    NOT_MATH_STARTMODELEDITOR  = "StartModelEditor";
    NOT_MATH_OLEDATE           = "OLEData";

//ATTRIBUTE
    FONTSLANT             = "FontSlant";
    FONTSIZE              = "FontSize";
    FONTCOLOR             = "FontColor";
    FONTWEIGHT            = "FontWeight";
    FONTFAMILY            = "FontFamily";
    FONTVARIATIONS        = "FontVariations";
    TEXTALIGNMENT         = "TextAlignment";
    TEXTJUSTIFICATION     = "TextJustification";
    INITIALIZATIONCELL    = "InitializationCell";
    FORMATTYPE_TOKEN      = "FormatType";
    PAGEWIDTH             = "PageWidth";
    PAGEHEADERS           = "PageHeaders";
    PAGEHEADERLINES       = "PageHeaderLines";
    PAGEFOOTERS           = "PageFooters";
    PAGEFOOTERLINES       = "PageFooterLines";
    PAGEBREAKBELOW        = "PageBreakBelow";
    PAGEBREAKWITHIN       = "PageBreakWithin";
    BOXMARGINS            = "BoxMargins";
    BOXBASELINESHIFT      = "BoxBaselineShift";
    LINESPACING           = "LineSpacing";
    HYPHENATION           = "Hyphenation";
    ACTIVE_TOKEN	      = "Active";
    VISIBLE_TOKEN         = "Visible";
    EVALUATABLE           = "Evaluatable";
    BUTTONFUNCTION        = "ButtonFunction";
    BUTTONDATA            = "ButtonData";
    BUTTONEVALUATOR       = "ButtonEvaluator";
    BUTTONSTYLE           = "ButtonStyle";
    CHARACHTERENCODING    = "CharacterEncoding";
    SHOWSTRINGCHARACTERS  = "ShowStringCharacters";
    SCREENRECTANGLE       = "ScreenRectangle";
    AUTOGENERATEDPACKAGE  = "AutoGeneratedPackage";
    AUTOITALICWORDS       = "AutoItalicWords";
    INPUTAUTOREPLACEMENTS = "InputAutoReplacements";
    SCRIPTMINSIZE         = "ScriptMinSize";
    STYLEMEMULISTING      = "StyleMenuListing";
    COUNTERINCREMENTS     = "CounterIncrements";
    COUNTERASSIGNMENTS    = "CounterAssignments";
    PRIVATEEVALOPTIONS    = "PrivateEvaluationOptions";
    GROUPPAGEBREAKWITHIN  = "GroupPageBreakWithin";
    DEFAULTFORMATTYPE     = "DefaultFormatType";
    NUMBERMARKS           = "NumberMarks";
    LINEBREAKADJUSTMENTS  = "LinebreakAdjustments";
    VISIOLINEFORMAT       = "VisioLineFormat";
    VISIOFILLFORMAT       = "VisioFillFormat";
    EXTENT                = "Extent";
    NAMEPOSITION          = "NamePosition";

//CELLOPTIONS
    CELLTAGS              = "CellTags";
    CELLFRAME             = "CellFrame";
    CELLFRAMECOLOR        = "CellFrameColor";
    CELLFRAMELABELS       = "CellFrameLabels";
    CELLFRAMEMARGINS      = "CellFrameMargins";
    CELLFRAMELABELMARGINS = "CellFrameLabelMargins";
    CELLLABRLMARGINS      = "CellLabelMargins";
    CELLLABELPOSITIONING  = "CellLabelPositioning";
    CELLMARGINS		      = "CellMargins";
    CELLDINGBAT           = "CellDingbat";
    CELLHORIZONTALSCROLL  = "CellHorizontalScrolling";
    CELLOPEN			  = "CellOpen";
    CELLGENERATED         = "GeneratedCell";
    SHOWCELLBRACKET       = "ShowCellBracket";
    SHOWCELLLABEL         = "ShowCellLabel";
    CELLBRACKETOPT        = "CellBracketOptions";
    EDITABLE              = "Editable";
    BACKGROUNT            = "Background";
    CELLGROUPINGRULES     = "CellGroupingRules";

//NOTEBOOKOPTIONS
    WINDOWSIZE         = "WindowSize";
    WINDOWMARGINS      = "WindowMargins";
    WINDOWFRAME        = "WindowFrame";
    WINDOWELEMENTS     = "WindowElements";
    WINDOWTITLE        = "WindowTitle";
    WINDOWTOOLBARS     = "WindowToolbars";
    WINDOWMOVEABLE     = "WindowMoveable";
    WINDOWFLOATING     = "WindowFloating";
    WINDOWCLICKSELECT  = "WindowClickSelect";
    STYLEDEFINITIONS   = "StyleDefinitions";
    FRONTENDVERSION    = "FrontEndVersion";
    SCREENSTYLEENV     = "ScreenStyleEnvironment";
    PRINTINGSTYLEENV   = "PrintingStyleEnvironment";
    PRINTINGOPTIONS    = "PrintingOptions";
    PRINTINGCOPIES     = "PrintingCopies";
    PRINTINGPAGERANGE  = "PrintingPageRange";
    PRIVATEFONTOPTIONS = "PrivateFontOptions";

//ANNAT
    CELLGROUPOPEN   = "Open";
    CELLGROUPCLOSED = "Closed";
    VALUERIGHT      = "Right";
    VALUELEFT       = "Left";
    VALUECENTER     = "Center";
    VALUESMALLER    = "Smaller";
    INHERITED       = "Inherited";
    PAPERWIDTH      = "PaperWidth";
    WINDOWWIDTH     = "WindowWidth";
    TRUE_           = "True";
    FALSE_          = "False";
    AUTOMATIC       = "Automatic";
    TRADITIONALFORM = "TraditionalForm";
    STANDARDFORM    = "StandardForm";
    INPUTFORM       = "InputForm";
    OUTPUTFORM      = "OutputForm";
    DEFAULTINPUTFORMATTYPE = "DefaultInputFormatType";
    NULLSYM         = "Null";
    NONESYM         = "None";
    ALLSYM          = "All";

    GRAPHICSDATA    = "GraphicsData";
    IMAGESIZE       = "ImageSize";
    IMAGEMARGINS    = "ImageMargins";
    IMAGEREGION     = "ImageRegion";
    IMAGERANGECACHE = "ImageRangeCache";
    IMAGECACHE      = "ImageCache";
    NOT_MATH_MODELEDITOR  = "ModelEditor";
    GENERATECELL    = "GenerateCell";
    CELLAUTOOVRT    = "CellAutoOverwrite";
    MAGNIFICATION   = "Magnification";
    PARENTDIRECTORY = "ParentDirectory";


    //Old tokens? Needed.
//     LISTBODY;
//     SEXPR;
//     EXPRESSIONS;
//     EXPRESSION;
//     ATTRIBUTE;
//     VALUE;
//     STRING;
}

RBRACK      : ']';
LBRACK      : '[';
RCURLY      : '}';
LCURLY      : '{';
COMMA       : ',';
THICK       : '`';

COMMENTSTART    : "(*";
COMMENTEND      : "*)";

/*
* NUMBERS
* - digits                  integer
* - digits.digits           approximate number
* - base^^digits            integer in specified base
* - base^^digits.digits     approx. in specified base
* - mantissa *^ n           sci.not (mantissa * 10^n)
* - base^^mantissa *^ n     (mantissa * base^n) base == 2..36
* - number`                 Machine precision approx, number
* - number`s                arbitrary precision number with precision s
* - number``s               arbitrary precision number with accuracy s
*/
NUMBER
    : ('-')?(DIGIT)+ ('.' (DIGIT)+)? (EXP)?
    ;

ID  : ('a'..'z'|'A'..'Z')+
    ;

protected
EXP
    :    ('e'|'E') NUMBER
    |    (THICK (THICK)? (NUMBER)?)
    ;

protected
DIGIT
    : '0'..'9'
    | '`'
    | '*'
    | '^'
    ;

/*
 * Strings can not be implemented in the lexer. Some part of them must
 * be in the parser
 * Character strings
 * - "characters"
 * - \" - a literal " in a string
 * - \\ - a literal \ in a string
 * - \< ... \> - a substring in which newlines are interpreted literally
 * - \!\( ... \) - a substring representing two-dimensional boxes
 */
QSTRING
    :   '"'
        ({LA(2) != '"'}? '\\'
        | ('\r'|'\n'){ newline();}
        | '\\' '"'
        | ~('"'|'\r'|'\n'|'\\')
        )*
        '"'
    ;

WHITESPACE
    :   (' '
        |'\t'
        |('\r'|'\n'|"\r\n") {newline();}
        )
        { $setType(ANTLR_USE_NAMESPACE(antlr)Token::SKIP);}
    ;

COMMENT    : COMMENTSTART //'(' '*'
           ({LA(2) != ')'}? '*'
           | ('\r'|'\n'){ newline();}
           | ~('*'|'\r'|'\n')
           )*
           COMMENTEND //'*'')'
           { $setType(ANTLR_USE_NAMESPACE(antlr)Token::SKIP); }
           ;
