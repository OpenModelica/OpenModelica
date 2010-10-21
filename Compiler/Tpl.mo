
package Tpl

//import Util;
protected import Debug;
protected import System;
protected import Util;
protected import Print;
protected import CevalScript;



// indentation will be implemented through spaces
// where tabs will be converted where 1 tab = 4 spaces ??
public
type Tokens = list<StringToken>; 

public
uniontype Text
  record MEM_TEXT
    Tokens tokens; //reversed list of tokens
    list<tuple<Tokens,BlockType>> blocksStack;
  end MEM_TEXT;
end Text;

public constant Text emptyTxt = MEM_TEXT({}, {});

public
uniontype StringToken
  record ST_NEW_LINE "Always outputs the new-line char." end ST_NEW_LINE;
  
  record ST_STRING "A string without new-lines in it."
    String value;
  end ST_STRING;
  
  record ST_LINE "A (non-empty) string with new-line at the end."
    String line;
  end ST_LINE;
  
  record ST_STRING_LIST "Every string in the list can have a new-line at its end (but does not have to)."
    list<String> strList;
    Boolean lastHasNewLine "True when the last string in the list has new-line at the end."; 
  end ST_STRING_LIST;
  
  record ST_BLOCK
    Tokens tokens;
    BlockType blockType;    
  end ST_BLOCK;
end StringToken;

public
uniontype BlockType
  record BT_TEXT  end BT_TEXT;
  
  record BT_INDENT  
    Integer width;
  end BT_INDENT;
  
  record BT_ABS_INDENT
    Integer width;
  end BT_ABS_INDENT;
  
  record BT_REL_INDENT
    Integer offset;
  end BT_REL_INDENT;
  
  record BT_ANCHOR
    Integer offset;
  end BT_ANCHOR;
  
  record BT_ITER "Iteration items block, every token in the block is an item. 
                index0 is the active index during the build phase, then it is the last one + 1."
    IterOptions options;
    Integer index0;
  end BT_ITER;
end BlockType;

public
uniontype IterOptions
  record ITER_OPTIONS
    Integer startIndex0;
    Option<StringToken> empty;
    Option<StringToken> separator;
    
    Integer alignNum "Number of items to be aligned by. When 0, no alignment."; 
    Integer alignOfset;
    StringToken alignSeparator; 
    
    Integer wrapWidth "Number of chars on a line, after that the wrapping can occur. When 0, no wrapping.";
    StringToken wrapSeparator; 
  end ITER_OPTIONS;
end IterOptions;
  
//by default, we will parse new lines in every non-token string
public function writeStr
  input Text inText;
  input String inStr;
  
  output Text outText;
algorithm
  outText := matchcontinue (inText, inStr)
    local
      Tokens toks;
      list<tuple<Tokens,BlockType>> blstack;
      String str;
      Text txt;
    
    //empty string means nothing
    //to ensure invariant being able to check emptiness only through the tokens (list) emtiness
    case (txt, "")
      then 
        txt;
    
    case (MEM_TEXT(
            tokens = toks,
            blocksStack = blstack
            ), str)
      equation
        -1 = System.stringFind(str, "\n");
      then 
        MEM_TEXT(ST_STRING(str) :: toks, blstack);
    
    // a new-line is inside
    case (txt, str )
      then 
        writeChars(txt, stringListStringChar(str));            
  end matchcontinue;
end writeStr;


public function writeTok
  input Text inText;
  input StringToken inToken;
  
  output Text outText;
algorithm
  outText := matchcontinue (inText, inToken)
    local
      Text txt;
      Tokens toks;
      list<tuple<Tokens,BlockType>> blstack;
      StringToken tok;
    
    //to ensure invariant being able to check emptiness only through the tokens (list) emtiness
    //should not happen, tokens must have at least one element   
    case (txt, ST_BLOCK( tokens = {} ))
      then 
        txt;
    
    //same as above - compiler should not generate this value in any case
    case (txt, ST_STRING( value = "" ))
      then 
        txt;
    
    case (MEM_TEXT(
            tokens = toks,
            blocksStack = blstack
            ), tok)
      then 
        MEM_TEXT(tok :: toks, blstack);
    
  end matchcontinue;
end writeTok;


public function writeText
  input Text inText;
  input Text inTextToWrite;
  
  output Text outText;
algorithm
  outText := matchcontinue (inText, inTextToWrite)
    local
      Tokens toks, txttoks;
      list<tuple<Tokens,BlockType>> blstack;
      Text txt;
    
    //to ensure invariant being able to check emptiness only through the tokens (list) emtiness    
    case (txt, MEM_TEXT( tokens = {} ) )
      then 
        txt;
        
    case (MEM_TEXT(
            tokens = toks,
            blocksStack = blstack
            ), 
          MEM_TEXT(
            tokens = txttoks,
            blocksStack = {} 
            ))
      then 
        MEM_TEXT(ST_BLOCK(txttoks, BT_TEXT()) :: toks, blstack);
    
    //should not ever happen 
    //- when compilation is correct, this is impossible (only completed texts can be accessible to write out)
    case (_ , _)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.writeText failed - incomplete text was passed to be written\n");
      then 
        fail();
  end matchcontinue;
end writeText;

// can be optimized in C ... a tokenization function for "\n" is needed; strtok is insufficien
// even any substring function is not there (or is somwhere ??)
//-obsolete - writeStr will parse the string by default
public function writeParseNL "parses inStr for new lines"
  input Text inText;
  input String inStr;
  
  output Text outText;
algorithm
  outText := matchcontinue (inText, inStr)
    local
      Tokens toks, txttoks;
      list<tuple<Tokens,BlockType>> blstack;
      Text txt;
      String str;
      list<String> chars;
    
    case (txt, str)
      equation
        -1 = System.stringFind(str, "\n");
      then 
        writeStr(txt, str);
    
    // a new-len is inside
    case (txt, str )
      then 
        writeChars(txt, stringListStringChar(str));
    
    //should not ever happen 
    case (_ , _)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.writeParseNL failed.\n");
      then 
        fail();
  end matchcontinue;
end writeParseNL;


public function writeChars 
  input Text inText;
  input list<String> inChars;
  
  output Text outText;
algorithm
  outText := matchcontinue (inText, inChars)
    local
      Text txt;
      String c;
      list<String> chars, lschars;
      Boolean isline;
      
    case (txt, {} )
      then 
        txt;
    
    //leading new-lines
    case (txt, "\n" :: chars )
      equation
        txt = newLine(txt);
      then 
        writeChars(txt, chars);
    
    //non-new-line at the start of the string, so a string or line only follows
    case (txt, c :: chars )
      equation
        (lschars, chars, isline) = takeLineOrString(chars);
        txt = writeLineOrStr(txt, stringCharListString( c :: lschars), isline);
        //Error txt = writeLineOrStr(txt, stringCharListString( str :: lschars), isline);
      then 
        writeChars(txt, chars);
    
    //should not ever happen 
    case (_ , _)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.writeChars failed.\n");
      then 
        fail();
  end matchcontinue;
end writeChars;


public function writeLineOrStr
  input Text inText;
  input String inStr;
  input Boolean inIsLine;
  
  output Text outText;
algorithm
  outText := matchcontinue (inText, inStr, inIsLine)
    local
      Tokens toks;
      list<tuple<Tokens,BlockType>> blstack;
      String str;
      Text txt;
    
    //empty string means nothing
    //to ensure invariant being able to check emptiness only through the tokens (list) emtiness
    //should not happen
    case (txt, "", _)
      then 
        txt;
        
    case (MEM_TEXT(
            tokens = toks,
            blocksStack = blstack
            ), str, false)
      then 
        MEM_TEXT(ST_STRING(str) :: toks, blstack);
    
    case (MEM_TEXT(
            tokens = toks,
            blocksStack = blstack
            ), str, true)
      then 
        MEM_TEXT(ST_LINE(str) :: toks, blstack);
  end matchcontinue;
end writeLineOrStr;


public function takeLineOrString
  input list<String> inChars;
  
  output list<String> outTillNewLineChars;
  output list<String> outRestChars;
  output Boolean outIsLine;  
algorithm
  (outTillNewLineChars, outRestChars, outIsLine) := matchcontinue (inChars)
    local
      Text txt;
      String str, char;
      list<String> tnlchars, restchars, chars;
      Boolean isline;
    
    case ({})
      then 
        ({}, {}, false);
    
    case ("\n" :: chars)
      then 
        ({"\n"}, chars, true);
    
    case (char :: chars)
      equation
        (tnlchars, restchars, isline) = takeLineOrString(chars);
      then 
        (char ::  tnlchars, restchars, isline);
    
    //should not ever happen 
    case (_ )
      equation
        Debug.fprint("failtrace", "-!!!Tpl.takeLineOrString failed.\n");
      then 
        fail();
  end matchcontinue;
end takeLineOrString;


public function softNewLine
  input Text inText;
  output Text outText;
algorithm
  outText := matchcontinue (inText)
    local
      Text txt;
      Tokens toks;
      list<tuple<Tokens,BlockType>> blstack;
      StringToken tok;
    
    //empty - nothing
    case (txt as MEM_TEXT(
                   tokens = {} ))
      then
        txt;
    
    //at start of line - nothing
    case (txt as MEM_TEXT(
                   tokens = (tok :: _) ))
      equation
        isAtStartOfLine(tok);
      then
        txt;
    
    //otherwise put normal new-line
    case (MEM_TEXT(
            tokens = toks,
            blocksStack = blstack))
      then 
        MEM_TEXT(ST_NEW_LINE() :: toks, blstack);
    
    
    //should not ever happen 
    case (_)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.softNL failed. \n");
      then 
        fail();
        
  end matchcontinue;
end softNewLine;


public function isAtStartOfLine
  input StringToken inTok;
algorithm
  _ := matchcontinue (inTok)
    local
      Text txt;
      Tokens toks;
      list<tuple<Tokens,BlockType>> blstack;
      StringToken tok;
    
    //a new-line at the end
    case ( ST_NEW_LINE() )
      then
        ();
    
    //a new-line at the end
    case ( ST_LINE(_) )
      then
        ();
    
    //a new-line at the end
    case ( ST_STRING_LIST(lastHasNewLine = true) )
      then
        ();
    
    //recursively in the last block
    case ( ST_BLOCK(
             tokens = (tok :: _) ))
      equation
        isAtStartOfLine(tok);
      then
        ();

    //this should not ever happen - tokens should have at least one element, ... but for sure and completness
    case ( ST_BLOCK(
             tokens = {} ))      
      then
        ();
   
  // otherwise fail - not at the start           
            
  end matchcontinue;
end isAtStartOfLine;


public function newLine
  input Text inText;
  output Text outText;
algorithm
  outText := matchcontinue (inText)
    local
      Tokens toks;
      list<tuple<Tokens,BlockType>> blstack;
      StringToken tok;
    
    case (MEM_TEXT(
            tokens = toks,
            blocksStack = blstack
            ))
      then 
        MEM_TEXT(ST_NEW_LINE() :: toks, blstack);
  end matchcontinue;
end newLine;


public function pushBlock
  input Text inText;
  input BlockType inBlockType; 
  
  output Text outText;
algorithm
  outText := matchcontinue (inText, inBlockType)
    local
      Tokens toks;
      list<tuple<Tokens,BlockType>> blstack;
      BlockType blType;
    
    case (MEM_TEXT(
            tokens = toks,
            blocksStack = blstack
            ), blType)
      then 
        MEM_TEXT(
          {},
          (toks, blType) :: blstack
        );
    
    
    //should not ever happen 
    case (_, _)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.pushBlock failed \n");
      then 
        fail();
    
  end matchcontinue;
end pushBlock;


public function popBlock
  input Text inText;
  output Text outText;
algorithm
  outText := matchcontinue (inText)
    local
      Tokens toks, stacktoks;
      list<tuple<Tokens,BlockType>> blstack;
      StringToken tok;
      BlockType blType;
      Text txt;
    
    //when nothig was put, just pop tokens from the stack and no block output
    case (MEM_TEXT(
            tokens = {},
            blocksStack = ( (stacktoks,_) :: blstack )
            ))
      then 
          MEM_TEXT( stacktoks, blstack);
    
    case (MEM_TEXT(
            tokens = toks,
            blocksStack = ( (stacktoks, blType) :: blstack)
            ))
      then
        MEM_TEXT(
          ST_BLOCK(toks, blType) :: stacktoks,
          blstack);
          
    //should not ever happen 
    //- when compilation is correct, this is impossible (pushs and pops should be balanced)
    case (_)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.popBlock failed - probably pushBlock and popBlock are not well balanced !\n");
      then 
       fail();
  end matchcontinue;
end popBlock;


public function pushIter
  input Text inText;
  input IterOptions inIterOptions;
  
  output Text outText;
algorithm
  outText := matchcontinue (inText, inIterOptions)
    local
      Tokens toks, txttoks;
      list<tuple<Tokens,BlockType>> blstack;
      IterOptions iopts;
      Integer i0;
    
    case (MEM_TEXT(
            tokens = toks,
            blocksStack = blstack
            ), 
          iopts as ITER_OPTIONS(
            startIndex0 = i0))
      then //let the existing tokens on stack in the text block and start iterating       
        MEM_TEXT(
          {},
          ({}, BT_ITER(iopts, i0)) :: (toks, BT_TEXT()) :: blstack);
    
    //should not ever happen 
    case (_ , _)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.pushIter failed \n");
      then 
        fail();
  end matchcontinue;
end pushIter;


public function popIter
  input Text inText;
  output Text outText;
algorithm
  outText := matchcontinue (inText)
    local
      Tokens toks, stacktoks, itertoks;
      list<tuple<Tokens,BlockType>> blstack;
      StringToken tok;
      BlockType blType;
      Text txt;
    
    //nothing was iterated, pop only the stacked tokens
    case (MEM_TEXT(
            tokens = {},
            blocksStack = ( ({},_) :: (stacktoks,_) :: blstack )
            ))
      then 
          MEM_TEXT(stacktoks, blstack);
    
    case (MEM_TEXT(
            tokens = {},
            blocksStack = ( (itertoks,blType) :: (stacktoks,_) :: blstack )
            ))
      then 
          MEM_TEXT( 
            ST_BLOCK(itertoks, blType) :: stacktoks,
            blstack);
          
    //should not ever happen 
    //- when compilation is correct, this is impossible (pushs and pops should be balanced)
    case (_)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.popIter failed - probably pushIter and popIter are not well balanced or something was written between the last nextIter and popIter ?\n");
      then 
       fail();
  end matchcontinue;
end popIter;


public function nextIter
  input Text inText;
  output Text outText;
algorithm
  outText := matchcontinue (inText)
    local
      Tokens toks, itertoks;
      StringToken tok, emptok;
      list<tuple<Tokens,BlockType>> blstack;
      IterOptions iopts;
      Integer i0;
      BlockType bt;
      Text txt;
          
    //empty iteration segment and 'empty' option is NONE, so do nothing
    case (txt as MEM_TEXT(
            tokens = {},
            blocksStack = (_, BT_ITER(options = ITER_OPTIONS(empty = NONE()) )) :: _
            ))
      then
        txt;
    
    //empty iteration segment, but 'empty' option is specified, so put the value
    case (MEM_TEXT(
            tokens = {},
            blocksStack = (itertoks, BT_ITER(
                                       options = iopts as ITER_OPTIONS(
                                                            empty = SOME(emptok)),
                                       index0 = i0)) :: blstack
            ))
      equation
        i0 = i0 + 1;
      then 
        MEM_TEXT(
          {},
          (emptok :: itertoks, BT_ITER(iopts, i0)) :: blstack
        );
    
    
    //one token, put it as it is
    case (MEM_TEXT(
            tokens = {tok},
            blocksStack = (itertoks, BT_ITER(
                                        options = iopts,
                                        index0 = i0)) :: blstack
            ))
      equation
        i0 = i0 + 1;
      then 
        MEM_TEXT(
          {},
          (tok :: itertoks, BT_ITER(iopts, i0)) :: blstack
        );
    
    //more tokens, put them as a text block
    case (MEM_TEXT(
            tokens = toks /* as (_::_) */,
            blocksStack = (itertoks, BT_ITER(
                                        options = iopts,
                                        index0 = i0)) :: blstack
            ))
      equation
        i0 = i0 + 1;
      then 
        MEM_TEXT(
          {},
          (ST_BLOCK(toks,BT_TEXT()) :: itertoks, BT_ITER(iopts, i0)) :: blstack
        );
    
    
    //should not ever happen 
    case (_ )
      equation
        Debug.fprint("failtrace", "-!!!Tpl.nextIter failed - nextIter was called in a non-iteration context ? \n");
      then 
        fail();
  end matchcontinue;
end nextIter;


public function getIteri_i0
  input Text inText;
  output Integer outI0;
algorithm
  outI0 := matchcontinue (inText)
    local
      Integer i0;
          
    case (MEM_TEXT(
            blocksStack = (_, BT_ITER(index0 = i0)) :: _
            ))
      then
        i0;
    
    //should not ever happen 
    case (_ )
      equation
        Debug.fprint("failtrace", "-!!!Tpl.getIter_i0 failed - getIter_i0 was called in a non-iteration context ? \n");
      then 
        fail();
  end matchcontinue;
end getIteri_i0;


public function getIteri_i1
  input Text inText;
  output Integer outI1;
algorithm
  outI1 := matchcontinue (inText)
    local
      Integer i0;
          
    case (MEM_TEXT(
            blocksStack = (_, BT_ITER(index0 = i0)) :: _
            ))
      then
        i0 + 1;
    
    //should not ever happen 
    case (_ )
      equation
        Debug.fprint("failtrace", "-!!!Tpl.getIter_i1 failed - getIter_i1 was called in a non-iteration context ? \n");
      then 
        fail();
  end matchcontinue;
end getIteri_i1;


public function textString "function: textString:
This function renders a (memory-)text to string."
  input Text inText;
  output String outString;
algorithm
  outString := matchcontinue (inText)
    local
      Text txt;
      String str;   
    case (txt)
      equation
        Print.clearBuf();
        textStringBuf(txt);
        str = Print.getString();
        Print.clearBuf(); 
      then
        str;       
    
    //should not ever happen 
    case (_ )
      equation
        Debug.fprint("failtrace", "-!!!Tpl.textString failed.\n");
      then 
        fail();
  end matchcontinue;
end textString;

public function textStringBuf "function: textStringBuf:
This function renders a (memory-)text to (Print.)string buffer."
  input Text inText;
algorithm
  _ := matchcontinue (inText)
    local
      Integer i0;
      Tokens toks;
      String str;
          
    case (MEM_TEXT(
            tokens = toks,
            blocksStack = {}
            ))
      equation
        (_,_) = tokensString(listReverse(toks), 0, true, 0);         
      then
        ();
    
    case (MEM_TEXT(
            blocksStack = _::_
            ))
      equation
        Debug.fprint("failtrace", "-!!!Tpl.textString failed - a non-comlete text was given.\n");
      then 
        fail();
    
    //should not ever happen 
    case (_ )
      equation
        Debug.fprint("failtrace", "-!!!Tpl.textString failed.\n");
      then 
        fail();
  end matchcontinue;
end textStringBuf;

public function tokensString 
  input Tokens inTokens;
  input Integer inActualPositionOnLine;
  input Boolean inAtStartOfLine;
  input Integer inAfterNewLineIndent;
  
  output Integer outActualPositionOnLine;
  output Boolean outAtStartOfLine;
algorithm
  (outActualPositionOnLine, outAtStartOfLine)
   := matchcontinue (inTokens, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
    local
      Tokens toks, txttoks;
      StringToken tok;
      list<tuple<Tokens,BlockType>> blstack;
      Text txt;
      String str, tokstr;
      list<String> chars;
      Integer pos, aind;
      Boolean isstart;
    
    case ({}, pos, isstart, _)
      then 
        (pos, isstart);
    
    case (tok :: toks, pos, isstart, aind)
      equation
        (pos, isstart, aind) = tokString(tok, pos, isstart, aind);
        (pos, isstart) = tokensString(toks, pos, isstart, aind);
      then 
        (pos, isstart);
    
    //should not ever happen 
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.tokensString failed.\n");
      then 
        fail();
  end matchcontinue;
end tokensString;


public function tokString 
  input StringToken inStringToken;
  input Integer inActualPositionOnLine;
  input Boolean inAtStartOfLine;
  input Integer inAfterNewLineIndent;
  
  output Integer outActualPositionOnLine;
  output Boolean outAtStartOfLine;
  output Integer outAfterNewLineIndent;
algorithm
  (outActualPositionOnLine, outAtStartOfLine, outAfterNewLineIndent)
   := matchcontinue (inStringToken, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
    local
      Tokens toks, txttoks;
      list<tuple<Tokens,BlockType>> blstack;
      BlockType bt;
      Text txt;
      String str, accstr;
      list<String> chars, strLst;
      Integer nchars, pos, ind, aind, blen;
      Boolean isstart;
    
    case (ST_NEW_LINE(), _, _, aind)
      equation
        Print.printBufNewLine();
      then 
        (aind, true, aind);
    
    case (ST_STRING(value = str), nchars, true, aind)
      equation
        blen = Print.getBufLength();
        Print.printBufSpace(nchars);
        Print.printBuf(str);
        blen = Print.getBufLength() - blen;
        //str = spaceStr(nchars) +& str; //indent is actually stored in nchars when on start of the line
      then 
        (blen, false, aind);
    
    case (ST_STRING(value = str), nchars, false, aind)
      equation
        blen = Print.getBufLength();
        Print.printBuf(str);
        blen = Print.getBufLength() - blen;
      then 
        (nchars + blen, false, aind);
    
    case (ST_LINE(line = str), nchars, true, aind)
      equation
        Print.printBufSpace(nchars);
        Print.printBuf(str);
        //str = spaceStr(nchars) +& str; //indent is actually stored in nchars when on start of the line        
      then 
        (aind, true, aind);
    
    case (ST_LINE(line = str), nchars, false, aind)
      equation
        Print.printBuf(str);
      then 
        (aind, true, aind);
    
    case (ST_STRING_LIST( strList = strLst ), nchars, isstart, aind)
      equation
        (nchars, isstart, aind) 
          = stringListString(strLst, nchars, isstart, aind);
      then 
        (nchars, isstart, aind);
    
    case (ST_BLOCK(
           tokens = toks,
           blockType = bt), nchars, isstart, aind)
      equation
        (nchars, isstart, aind) 
          = blockString(bt, listReverse(toks), nchars, isstart, aind);
      then 
        (nchars, isstart, aind);
        
    //should not ever happen 
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.tokString failed.\n");
      then 
        fail();
  end matchcontinue;
end tokString;


public function stringListString 
  input list<String> inStringList;
  input Integer inActualPositionOnLine;
  input Boolean inAtStartOfLine;
  input Integer inAfterNewLineIndent;
  
  output Integer outActualPositionOnLine;
  output Boolean outAtStartOfLine;
  output Integer outAfterNewLineIndent;
algorithm
  (outActualPositionOnLine, outAtStartOfLine, outAfterNewLineIndent)
   := matchcontinue (inStringList, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
    local
      String str, accstr;
      list<String> strLst;
      Integer nchars, aind, blen;
      Boolean isstart, hasNL;
    
    
    case ({}, nchars, isstart, aind)
      then 
        (aind, isstart, aind);
    
    //empty string ... for sure -> it can be a special case when allowed; when let for the case at start of a line, it would output an indent
    case ("" :: strLst, nchars, isstart, aind)
      equation
        (nchars, isstart, aind)
         = stringListString(strLst, nchars, isstart, aind);
      then 
        (nchars, isstart, aind);
        
    
    //at start, new line or no new line
    case (str :: strLst, nchars, true, aind)
      equation
        blen = Print.getBufLength();
        Print.printBufSpace(nchars); //indent is actually stored in nchars when on start of the line
        Print.printBuf(str);
        blen = Print.getBufLength() - blen;
        hasNL = Print.hasBufNewLineAtEnd();
        nchars = Util.if_(hasNL, aind, blen);
        (nchars, isstart, aind) = stringListString(strLst, nchars, hasNL, aind);
        
        //"\n" = stringGetStringChar(str, stringLength(str));
        //accstr = accstr +& (spaceStr(nchars) +& str); //indent is actually stored in nchars when on start of the line
        //(str, nchars, isstart, aind)
        // = stringListString(strLst, aind, true, aind, accstr);
      then 
        (nchars, isstart, aind);
        
    
    //at start, no new line
    //case (str :: strLst, nchars, true, aind, accstr)
    //  equation
    //    //failure("\n" = stringGetStringChar(str, stringLength(str)));
    //    accstr = accstr +& (spaceStr(nchars) +& str); //indent is actually stored in nchars when on start of the line
    //    nchars = nchars + stringLength(str);
    //    (str, nchars, isstart, aind)
    //     = stringListString(strLst, nchars, false, aind, accstr);
    //  then 
    //    (str, nchars, isstart, aind);
        
    
    //not at start, new line or no new line
    case (str :: strLst, nchars, false, aind)
      equation
        blen = Print.getBufLength();
        Print.printBuf(str);
        blen = Print.getBufLength() - blen;
        hasNL = Print.hasBufNewLineAtEnd();
        nchars = Util.if_(hasNL, aind, nchars+blen);
        (nchars, isstart, aind) = stringListString(strLst, nchars, hasNL, aind);
        
        //"\n" = stringGetStringChar(str, stringLength(str));
        //accstr = accstr +& str;
        //(str, nchars, isstart, aind)
        // = stringListString(strLst, aind, true, aind, accstr);
      then 
        (nchars, isstart, aind);
    
    //not at start, no new line
    //case (str :: strLst, nchars, true, aind, accstr)
    //  equation
    //    //failure("\n" = stringGetStringChar(str, stringLength(str)));
    //    accstr = accstr +& str;
    //    nchars = nchars + stringLength(str);
    //    (str, nchars, isstart, aind)
    //     = stringListString(strLst, nchars, false, aind, accstr);
    // then 
    //    (str, nchars, isstart, aind);
    
    //should not ever happen 
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.stringListString failed.\n");
      then 
        fail();
  end matchcontinue;
end stringListString;


/* obsolete ... Print.printBufSpace()
// have fun!
// O(n.log n) ... could be done O(n) through listFill and stringCharListString (is this function O(n)?)... but not that funny:)
// will be implemented in C with O(n) ...
// how can we create a read-only reusable table of space strings up to a length e.g. 128 ?
public function spaceStr 
  input Integer inWidth;
  output String outString;
algorithm  
  outString := matchcontinue inWidth
    local
      Integer w;
    case 0  then ""; //also for bad user and to give a (better) chance to the C/MM compiler to optimize the cases 
    case 1  then " "; // will this be optimized by MM to a simple switch ?
    case 2  then "  ";
    case 3  then "   ";
    case 4  then "    ";
    case 5  then "     ";
    case 6  then "      ";
    case 7  then "       ";
    case 8  then "        ";
    case 9  then "         ";
    case 10 then "          ";
    case 11 then "           ";
    case 12 then "            ";
    case 13 then "             ";
    case 14 then "              ";
    case 15 then "               ";
    
    //a bad user!
    case w 
      equation
        true = w < 0;
      then "";
    
    case w 
      then spaceStr(w/2 + intMod(w,2)) +& spaceStr(w/2);
    
    //should not ever happen 
    case (_)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.spaceStr failed.\n");
      then 
        fail();
  end matchcontinue;
end spaceStr;
*/

public function blockString 
  input BlockType inBlockType;
  input Tokens inTokens;
  input Integer inActualPositionOnLine;
  input Boolean inAtStartOfLine;
  input Integer inAfterNewLineIndent;
  
  output Integer outActualPositionOnLine;
  output Boolean outAtStartOfLine;
  output Integer outAfterNewLineIndent;
algorithm
  (outActualPositionOnLine, outAtStartOfLine, outAfterNewLineIndent)
   := matchcontinue (inBlockType, inTokens, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
    local
      Tokens toks, txttoks;
      StringToken septok, tok, asep, wsep;
      list<tuple<Tokens,BlockType>> blstack;
      BlockType bt;
      Text txt;
      String str, accstr, tokstr;
      list<String> chars;
      Integer nchars, tsnchars, pos, ind, aind, w, aoffset, anum, wwidth, blen;
      Boolean isstart;
    
    case (BT_TEXT(), toks, nchars, isstart, aind)
      equation
        (nchars, isstart)
          = tokensString(toks, nchars, isstart, aind); 
      then 
        (nchars, isstart, aind);
    
    case (BT_INDENT(width = w), toks, nchars, true, aind)
      equation
        (tsnchars, isstart)
          = tokensString(toks, w + nchars, true, w + aind);
        nchars = Util.if_(isstart, nchars, tsnchars); //pop indent when at the start of a line 
      then 
        (nchars, isstart, aind);
    
    case (BT_INDENT(width = w), toks, nchars, false, aind)
      equation
        Print.printBufSpace(w);
        (tsnchars, isstart)
          = tokensString(toks, w + nchars, false, w + aind);
        nchars = Util.if_(isstart, aind, tsnchars); //pop indent when at the start of a line - there were a new line, so use the aind
      then 
        (nchars, isstart, aind);
    
    case (BT_ABS_INDENT(width = w), toks, nchars, true, aind)
      equation
        blen = Print.getBufLength();
        (tsnchars, isstart)
          = tokensString(toks, 0, true, w); //discard an indent when at the start of a line
        blen = Print.getBufLength() - blen;
        nchars = Util.if_(blen == 0, nchars, Util.if_(isstart, aind, tsnchars)); //when no chars -> pop indent; when something written -> aind for the start of a line otherwise actual position    
      then 
        (nchars, isstart, aind);
    
    case (BT_ABS_INDENT(width = w), toks, nchars, false, aind)
      equation
        (tsnchars, isstart)
          = tokensString(toks, nchars, false, w);
        nchars = Util.if_(isstart, aind, tsnchars); //pop indent when at the start of a line - there were a new line, so use the aind 
      then 
        (nchars, isstart, aind);
    
    case (BT_REL_INDENT(offset = w), toks, nchars, true, aind)
      equation
        blen = Print.getBufLength();
        (tsnchars, isstart)
          = tokensString(toks, nchars, true, aind + w);
        blen = Print.getBufLength() - blen;  
        nchars = Util.if_(blen == 0, nchars, Util.if_(isstart, aind, tsnchars)); //when no chars -> pop indent; when something written -> aind for the start of a line otherwise actual position
      then 
        (nchars, isstart, aind);
    
    case (BT_REL_INDENT(offset = w), toks, nchars, false, aind)
      equation
        (tsnchars, isstart)
          = tokensString(toks, nchars, false, aind + w);
        nchars = Util.if_(isstart, aind, tsnchars); //pop indent when at the start of a line - there were a new line, so use the aind
      then 
        (nchars, isstart, aind);
    
    case (BT_ANCHOR(offset = w), toks, nchars, true, aind)
      equation
        blen = Print.getBufLength();
        (tsnchars, isstart)
          = tokensString(toks, nchars, true, nchars + w);
        blen = Print.getBufLength() - blen;
        nchars = Util.if_(blen == 0, nchars, Util.if_(isstart, aind, tsnchars)); //when no chars -> pop indent; when something written -> aind for the start of a line otherwise actual position 
      then 
        (nchars, isstart, aind);
    
    case (BT_ANCHOR(offset = w), toks, nchars, false, aind)
      equation
        (tsnchars, isstart)
          = tokensString(toks, nchars, false, nchars + w); 
        nchars = Util.if_(isstart, aind, tsnchars); //pop indent when at the start of a line - there were a new line, so use the aind
      then 
        (nchars, isstart, aind);
    
    
    //iter block, no tokens ... should be impossible, but ...
    case (BT_ITER(_,_), {}, nchars, isstart, aind)
      then 
        (nchars, isstart, aind);
    
    //concat ... i.e. text
    case (BT_ITER(options = ITER_OPTIONS(
                              separator = NONE(),
                              alignNum = 0,
                              wrapWidth = 0)), toks, nchars, isstart, aind)
      equation
        (nchars, isstart)
          = tokensString(toks, nchars, isstart, aind); 
      then 
        (nchars, isstart, aind);
    
    
    //separator only ... 
    case (BT_ITER(options = ITER_OPTIONS(
                              separator = SOME(septok),
                              alignNum = 0,
                              wrapWidth = 0)), tok :: toks, nchars, isstart, aind)
      equation
        // put the first token, all the others with separator
        (nchars, isstart, aind) = tokString(tok, nchars, isstart, aind);
        (nchars, isstart)
          = iterSeparatorString(toks, septok, nchars, isstart, aind); 
      then 
        (nchars, isstart, aind);
    
    //separator and alignment and/or wrapping 
    case (BT_ITER(options = ITER_OPTIONS(
                              separator = SOME(septok),
                              alignNum = anum,
                              alignOfset = aoffset,
                              alignSeparator = asep,
                              wrapWidth = wwidth,
                              wrapSeparator = wsep)), tok :: toks, nchars, isstart, aind)
      equation
        // put the first token, all the others with separator
        (nchars, isstart, aind) = tokString(tok, nchars, isstart, aind);
        (nchars, isstart)
          = iterSeparatorAlignWrapString(toks, septok, 1 + aoffset, anum, asep, wwidth, wsep, nchars, isstart, aind); 
      then 
        (nchars, isstart, aind);
    
    //no separator and alignment and/or wrapping 
    case (BT_ITER(options = ITER_OPTIONS(
                              separator = NONE(),
                              alignNum = anum,
                              alignOfset = aoffset,
                              alignSeparator = asep,
                              wrapWidth = wwidth,
                              wrapSeparator = wsep)), toks, nchars, isstart, aind)
      equation
        (nchars, isstart)
          = iterAlignWrapString(toks, aoffset, anum, asep, wwidth, wsep, nchars, isstart, aind); 
      then 
        (nchars, isstart, aind);
    
        
    //should not ever happen 
    case (_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.tokString failed.\n");
      then 
        fail();
  end matchcontinue;
end blockString;


public function iterSeparatorString 
  input Tokens inTokens;
  input StringToken inSeparator;
  input Integer inActualPositionOnLine;
  input Boolean inAtStartOfLine;
  input Integer inAfterNewLineIndent;
  
  output Integer outActualPositionOnLine;
  output Boolean outAtStartOfLine;
algorithm
  (outActualPositionOnLine, outAtStartOfLine)
   := matchcontinue (inTokens, inSeparator, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
    local
      Tokens toks;
      StringToken tok, septok;
      String str, tokstr, sepstr;
      Integer pos, aind;
      Boolean isstart;
      
    case ({}, _, pos, isstart, _)
      then 
        (pos, isstart);
    
    case (tok :: toks, septok, pos, isstart, aind)
      equation
        (pos, isstart, aind) = tokString(septok, pos, isstart, aind);
        (pos, isstart, aind) = tokString(tok, pos, isstart, aind);
        (pos, isstart)
         = iterSeparatorString(toks, septok, pos, isstart, aind);
      then 
        (pos, isstart);
    //should not ever happen 
    case (_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.iterSeparatorString failed.\n");
      then 
        fail();
  end matchcontinue;
end iterSeparatorString;


public function iterSeparatorAlignWrapString 
  input Tokens inTokens;
  input StringToken inSeparator;
  input Integer inActualIndex;
  input Integer inAlignNum;
  input StringToken inAlignSeparator;
  input Integer inWrapWidth;
  input StringToken inWrapSeparator;
  input Integer inActualPositionOnLine;
  input Boolean inAtStartOfLine;
  input Integer inAfterNewLineIndent;
  
  output Integer outActualPositionOnLine;
  output Boolean outAtStartOfLine;
algorithm
  (outActualPositionOnLine, outAtStartOfLine)
   := matchcontinue (inTokens, inSeparator, inActualIndex, inAlignNum, inAlignSeparator, inWrapWidth, inWrapSeparator, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
    local
      Tokens toks;
      StringToken tok, septok, asep, wsep;
      String str, tokstr, sepstr, awsepstr;
      Integer pos, aind, idx, anum, wwidth;
      Boolean isstart;
      
    case ({}, _,_,_,_,_,_, pos, isstart, _)
      then 
        (pos, isstart);
    
    //align and try wrap
    //align separator includes the separator (by default - otherwise can be provided by user)
    //--> only align separator is written here    
    case (tok :: toks, septok, idx, anum, asep, wwidth, wsep, pos, isstart, aind)
      equation
        true = (idx > 0) and (intMod(idx,anum) == 0);
        (pos, isstart, aind) = tokString(asep, pos, isstart, aind);
        (pos, isstart, aind) = tryWrapString(wwidth, wsep, pos, isstart, aind);
        (pos, isstart, aind) = tokString(tok, pos, isstart, aind);
        (pos, isstart)
         = iterSeparatorAlignWrapString(toks, septok, idx + 1, anum, asep, wwidth, wsep,
              pos, isstart, aind);
      then 
        (pos, isstart);
    
    //separator + try wrap - no align
    case (tok :: toks, septok, idx, anum, asep, wwidth, wsep, pos, isstart, aind)
      equation
        (pos, isstart, aind) = tokString(septok, pos, isstart, aind);
        (pos, isstart, aind) = tryWrapString(wwidth, wsep, pos, isstart, aind);
        (pos, isstart, aind) = tokString(tok, pos, isstart, aind);
        (pos, isstart)
         = iterSeparatorAlignWrapString(toks, septok, idx + 1, anum, asep, wwidth, wsep,
               pos, isstart, aind);
      then 
        (pos, isstart);
        
        
    //should not ever happen 
    case (_,_,_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.iterSeparatorAlignWrapString failed.\n");
      then 
        fail();
  end matchcontinue;
end iterSeparatorAlignWrapString;


public function iterAlignWrapString 
  input Tokens inTokens;
  input Integer inActualIndex;
  input Integer inAlignNum;
  input StringToken inAlignSeparator;
  input Integer inWrapWidth;
  input StringToken inWrapSeparator;
  input Integer inActualPositionOnLine;
  input Boolean inAtStartOfLine;
  input Integer inAfterNewLineIndent;
  
  output Integer outActualPositionOnLine;
  output Boolean outAtStartOfLine;
algorithm
  (outActualPositionOnLine, outAtStartOfLine)
   := matchcontinue (inTokens, inActualIndex, inAlignNum, inAlignSeparator, inWrapWidth, inWrapSeparator, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
    local
      Tokens toks;
      StringToken tok, septok, asep, wsep;
      String str, tokstr, sepstr, awsepstr;
      Integer pos, aind, idx, anum, wwidth;
      Boolean isstart;
      
    case ({}, _,_,_,_,_, pos, isstart, _)
      then 
        (pos, isstart);
    
    //align and try wrap
    case (tok :: toks, idx, anum, asep, wwidth, wsep, pos, isstart, aind)
      equation
        true = (idx > 0) and (intMod(idx,anum) == 0);
        (pos, isstart, aind) = tokString(asep, pos, isstart, aind);
        (pos, isstart, aind) = tryWrapString(wwidth, wsep, pos, isstart, aind);
        (pos, isstart, aind) = tokString(tok, pos, isstart, aind);
        (pos, isstart)
         = iterAlignWrapString(toks, idx + 1, anum, asep, wwidth, wsep,
                pos, isstart, aind);
      then 
        (pos, isstart);
    //wrap 
    case (tok :: toks, idx, anum, asep, wwidth, wsep, pos, isstart, aind)
      equation
        //false = (idx > 0) and (intMod(idx,anum) == 0);
        true = (wwidth > 0) and (pos >= wwidth); //check wwidth for the invariant that should be always true here
        (pos, isstart, aind) = tokString(wsep, pos, isstart, aind);
        (pos, isstart, aind) = tokString(tok, pos, isstart, aind);
        (pos, isstart)
          = iterAlignWrapString(toks, idx + 1, anum, asep, wwidth, wsep,
                pos, isstart, aind);
      then 
        (pos, isstart);
    
    //item only 
    case (tok :: toks, idx, anum, asep, wwidth, wsep, pos, isstart, aind)
      equation
        //false = (idx > 0) and (intMod(idx,anum) == 0);
        //false = (wwidth > 0) and (pos >= wwidth); //check wwidth for the invariant that should be always true here
        (pos, isstart, aind) = tokString(tok, pos, isstart, aind);
        (pos, isstart)
         = iterAlignWrapString(toks, idx + 1, anum, asep, wwidth, wsep,
              pos, isstart, aind);
      then 
        (pos, isstart);
    
    //should not ever happen 
    case (_,_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.iterAlignWrapString failed.\n");
      then 
        fail();
  end matchcontinue;
end iterAlignWrapString;


public function tryWrapString
  input Integer inWrapWidth;
  input StringToken inWrapSeparator;
  input Integer inActualPositionOnLine;
  input Boolean inAtStartOfLine;
  input Integer inAfterNewLineIndent;
  
  output Integer outActualPositionOnLine;
  output Boolean outAtStartOfLine;
  output Integer outAfterNewLineIndent;
algorithm
  (outActualPositionOnLine, outAtStartOfLine, outAfterNewLineIndent)
   := matchcontinue (inWrapWidth, inWrapSeparator, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
    local
      String str, tokstr, sepstr;
      Integer pos, aind, wwidth;
      Boolean isstart;
      StringToken wsep;
      
    //wrap
    case (wwidth, wsep, pos, isstart, aind)
      equation
        true = (wwidth > 0) and (pos >= wwidth); //check wwidth for the invariant that should be always true here
        (pos, isstart, aind) = tokString(wsep, pos, isstart, aind);
      then 
        (pos, isstart, aind);
    
    case (_, _, pos, isstart, aind)
      then 
        (pos, isstart, aind);
    
    //should not ever happen 
    case (_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.tryWrap failed.\n");
      then 
        fail();
  end matchcontinue;
end tryWrapString;


public function booleanString
  input Boolean inBoolean;  
  output String outString;
algorithm
  outString := matchcontinue inBoolean
    case (false) then "false";
    case (true)  then "true";
  end matchcontinue;
end booleanString;


public function strTokText
  input StringToken inStringToken;
  output Text outText;
algorithm
  outText := MEM_TEXT({inStringToken},{});
end strTokText;


public function textStrTok
  input Text inText;  
  output StringToken outStringToken;
algorithm
  outStringToken := matchcontinue inText
    local
      Tokens toks, txttoks;
    
    case ( MEM_TEXT( tokens = {} ) )
      then 
        ST_STRING("");
        
    case ( MEM_TEXT(
             tokens = txttoks,
             blocksStack = {} 
           ))
      then 
        ST_BLOCK(txttoks, BT_TEXT());
    
    //should not ever happen 
    //- when compilation is correct, this is impossible (only completed texts can be accessible to write out)
    case (_ )
      equation
        Debug.fprint("failtrace", "-!!!Tpl.textStrTok failed - incomplete text was passed to be converted.\n");
      then 
        fail();
  end matchcontinue;
end textStrTok;


public function stringText
  input String inString;
  output Text outText;
algorithm
  outText := MEM_TEXT({ST_STRING(inString)},{});
end stringText;


public function strTokString
  input StringToken inStringToken;
  output String outString;
algorithm
  outString := textString( MEM_TEXT({inStringToken},{}) );
end strTokString;


public function tplString
  input Tpl_Fun inFun;
  input Type_a inArg;
  output String outString;
    
  partial function Tpl_Fun
    input Text in_txt;
    input Type_a inArgA;    
    output Text out_txt;    
    replaceable type Type_a subtypeof Any;
  end Tpl_Fun;  
  replaceable type Type_a subtypeof Any;   
protected
  Text txt;
algorithm
  txt := inFun(emptyTxt, inArg);  
  outString := textString(txt);
end tplString;

public function tplString2
  input Tpl_Fun inFun;
  input Type_a inArgA;
  input Type_b inArgB;
  output String outString;
    
  partial function Tpl_Fun
    input Text in_txt;
    input Type_a inArgA;    
    input Type_b inArgB;    
    output Text out_txt;    
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end Tpl_Fun;  
  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any; 
protected
  Text txt;
algorithm
  txt := inFun(emptyTxt, inArgA, inArgB);  
  outString := textString(txt);
end tplString2;


public function tplNoret
  input Tpl_Fun inFun;
  input Type_a inArg;
    
  partial function Tpl_Fun
    input Text in_txt;
    input Type_a inArgA;    
    output Text out_txt;    
    replaceable type Type_a subtypeof Any;
  end Tpl_Fun;  
  replaceable type Type_a subtypeof Any;   
algorithm
  _ := inFun(emptyTxt, inArg);  
end tplNoret;


public function textFile "function: textFile:
This function renders a (memory-)text to a file."
  input Text inText;
  input String inFileName;

algorithm
  outString := matchcontinue (inText, inFileName)
    local
      Text txt;
      String file, str;
      Real rtTickTxt, rtTickW;   
    case (txt, file)
      equation
        rtTickTxt = System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL);
        Print.clearBuf();
        textStringBuf(txt);
        rtTickW = System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL); 
        Print.writeBuf(file);
        Print.clearBuf();
        Debug.fprintln("perfTimes",
                "textFile " +& file 
           +& "\n    text:" +& realString(realSub(rtTickW,rtTickTxt)) 
           +& "\n   write:" +& realString(realSub(System.realtimeTock(CevalScript.RT_CLOCK_BUILD_MODEL), rtTickW))
           );
      then
        ();
    
    //TODO: let this function fail and the error message can be reported via  # ( textFile(txt,"file.cpp") ; failMsg="error" )
    case (_,_)
      equation
        Debug.fprint("failtrace", "-!!!Tpl.textFile failed - a system error ?\n");
      then 
        ();
    
    //should not ever happen 
    //case (_ )
    //  equation
    //    Debug.fprint("failtrace", "-!!!Tpl.textFile failed.\n");
    //  then 
    //    fail();
  end matchcontinue;
end textFile;



end Tpl;
