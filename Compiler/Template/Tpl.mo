
encapsulated package Tpl
"
  file:        Tpl.mo
  package:     Tpl
  description: Susan

  $Id$
"

protected import Config;
protected import ClockIndexes;
protected import Debug;
protected import Error;
protected import Flags;
protected import List;
protected import Print;
protected import System;

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

replaceable type ArgType1 subtypeof Any;
replaceable type ArgType2 subtypeof Any;
replaceable type ArgType3 subtypeof Any;
replaceable type ArgType4 subtypeof Any;

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
    else
      writeChars(inText, System.strtokIncludingDelimiters(inStr, "\n"));
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
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.writeText failed - incomplete text was passed to be written\n");
      then
        fail();
  end matchcontinue;
end writeText;

public function writeChars
  input Text inText;
  input list<String> inChars;

  output Text outText;
algorithm
  outText := match (inText, inChars)
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
        txt = writeLineOrStr(txt, stringAppendList(c :: lschars), isline);
        //Error txt = writeLineOrStr(txt, stringCharListString( str :: lschars), isline);
      then
        writeChars(txt, chars);

    //should not ever happen
    case (_ , _)
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.writeChars failed.\n");
      then
        fail();
  end match;
end writeChars;


public function writeLineOrStr
  input Text inText;
  input String inStr;
  input Boolean inIsLine;

  output Text outText;
algorithm
  outText := match (inText, inStr, inIsLine)
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
  end match;
end writeLineOrStr;


public function takeLineOrString
  input list<String> inChars;

  output list<String> outTillNewLineChars;
  output list<String> outRestChars;
  output Boolean outIsLine;
algorithm
  (outTillNewLineChars, outRestChars, outIsLine) := match (inChars)
    local
      String  char;
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

  end match;
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
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.softNL failed. \n");
      then
        fail();

  end matchcontinue;
end softNewLine;


public function isAtStartOfLine
  input StringToken inTok;
algorithm
  _ := match (inTok)
    local
      StringToken tok;

    //a new-line at the end
    case ( ST_NEW_LINE() )
      then
        ();

    //a new-line at the end
    case ( ST_LINE() )
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

  end match;
end isAtStartOfLine;


public function newLine
  input Text inText;
  output Text outText;
algorithm
  outText := match (inText)
    local
      Tokens toks;
      list<tuple<Tokens,BlockType>> blstack;

    case (MEM_TEXT(tokens = toks,blocksStack = blstack))
      then MEM_TEXT(ST_NEW_LINE() :: toks, blstack);
  end match;
end newLine;


public function pushBlock
  input Text inText;
  input BlockType inBlockType;

  output Text outText;
algorithm
  outText := match (inText, inBlockType)
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
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.pushBlock failed \n");
      then
        fail();

  end match;
end pushBlock;


public function popBlock
  input Text inText;
  output Text outText;
algorithm
  outText := match (inText)
    local
      Tokens toks, stacktoks;
      list<tuple<Tokens,BlockType>> blstack;
      BlockType blType;

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
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.popBlock failed - probably pushBlock and popBlock are not well balanced !\n");
      then
       fail();
  end match;
end popBlock;


public function pushIter
  input Text inText;
  input IterOptions inIterOptions;

  output Text outText;
algorithm
  outText := match (inText, inIterOptions)
    local
      Tokens toks;
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
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.pushIter failed \n");
      then
        fail();
  end match;
end pushIter;


public function popIter
  input Text inText;
  output Text outText;
algorithm
  outText := match (inText)
    local
      Tokens  stacktoks, itertoks;
      list<tuple<Tokens,BlockType>> blstack;
      BlockType blType;

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
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.popIter failed - probably pushIter and popIter are not well balanced or something was written between the last nextIter and popIter ?\n");
      then
       fail();
  end match;
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
      Text txt;

    //empty iteration segment and 'empty' option is NONE(), so do nothing
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
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.nextIter failed - nextIter was called in a non-iteration context ? \n");
      then
        fail();
  end matchcontinue;
end nextIter;


public function getIteri_i0
  input Text inText;
  output Integer outI0;
algorithm
  outI0 := match (inText)
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
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.getIter_i0 failed - getIter_i0 was called in a non-iteration context ? \n");
      then
        fail();
  end match;
end getIteri_i0;


public function getIteri_i1
  input Text inText;
  output Integer outI1;
algorithm
  outI1 := match (inText)
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
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.getIter_i1 failed - getIter_i1 was called in a non-iteration context ? \n");
      then
        fail();
  end match;
end getIteri_i1;


public function textString "function: textString:
This function renders a (memory-)text to string."
  input Text inText;
  output String outString;
algorithm
  outString := match (inText)
    local
      Text txt;
      String str;
      Integer handle;
    case (txt)
      equation
        handle = Print.saveAndClearBuf();
        textStringBuf(txt);
        str = Print.getString();
        Print.restoreBuf(handle);
      then
        str;

    //should not ever happen
    case (_ )
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.textString failed.\n");
      then
        fail();
  end match;
end textString;

public function textStringBuf "function: textStringBuf:
This function renders a (memory-)text to (Print.)string buffer."
  input Text inText;
algorithm
  _ := match (inText)
    local
      Tokens toks;

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
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.textString failed - a non-comlete text was given.\n");
      then
        fail();

    //should not ever happen
    case (_ )
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.textString failed.\n");
      then
        fail();
  end match;
end textStringBuf;

public function tokensString
  input Tokens inTokens;
  input output Integer actualPositionOnLine;
  input output Boolean atStartOfLine;
  input output Integer afterNewLineIndent;
algorithm
  for tok in inTokens loop
    (actualPositionOnLine, atStartOfLine, afterNewLineIndent) := tokString(tok, actualPositionOnLine, atStartOfLine, afterNewLineIndent);
  end for;
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
   := match (inStringToken, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
    local
      Tokens toks;
      BlockType bt;
      String str;
      list<String>  strLst;
      Integer nchars,   aind, blen;
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
        //str = spaceStr(nchars) + str; //indent is actually stored in nchars when on start of the line
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
        //str = spaceStr(nchars) + str; //indent is actually stored in nchars when on start of the line
      then
        (aind, true, aind);

    case (ST_LINE(line = str), _, false, aind)
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
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.tokString failed.\n");
      then
        fail();
  end match;
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
      String str;
      list<String> strLst;
      Integer nchars, aind, blen;
      Boolean isstart, hasNL;


    case ({}, _, isstart, aind)
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
        nchars = if hasNL then aind else blen;
        (nchars, isstart, aind) = stringListString(strLst, nchars, hasNL, aind);

        //"\n" = stringGetStringChar(str, stringLength(str));
        //accstr = accstr + (spaceStr(nchars) + str); //indent is actually stored in nchars when on start of the line
        //(str, nchars, isstart, aind)
        // = stringListString(strLst, aind, true, aind, accstr);
      then
        (nchars, isstart, aind);


    //at start, no new line
    //case (str :: strLst, nchars, true, aind, accstr)
    //  equation
    //    //failure("\n" = stringGetStringChar(str, stringLength(str)));
    //    accstr = accstr + (spaceStr(nchars) + str); //indent is actually stored in nchars when on start of the line
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
        nchars = if hasNL then aind else nchars+blen;
        (nchars, isstart, aind) = stringListString(strLst, nchars, hasNL, aind);

        //"\n" = stringGetStringChar(str, stringLength(str));
        //accstr = accstr + str;
        //(str, nchars, isstart, aind)
        // = stringListString(strLst, aind, true, aind, accstr);
      then
        (nchars, isstart, aind);

    //not at start, no new line
    //case (str :: strLst, nchars, true, aind, accstr)
    //  equation
    //    //failure("\n" = stringGetStringChar(str, stringLength(str)));
    //    accstr = accstr + str;
    //    nchars = nchars + stringLength(str);
    //    (str, nchars, isstart, aind)
    //     = stringListString(strLst, nchars, false, aind, accstr);
    // then
    //    (str, nchars, isstart, aind);

    //should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.stringListString failed.\n");
      then
        fail();
  end matchcontinue;
end stringListString;

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
   := match (inBlockType, inTokens, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
    local
      Tokens toks;
      StringToken septok, tok, asep, wsep;
      Integer nchars, tsnchars,   aind, w, aoffset, anum, wwidth, blen;
      Boolean isstart;

    case (BT_TEXT(), toks, nchars, isstart, aind)
      equation
        (nchars, isstart, aind)
          = tokensString(toks, nchars, isstart, aind);
      then
        (nchars, isstart, aind);

    case (BT_INDENT(width = w), toks, nchars, true, aind)
      equation
        (tsnchars, isstart)
          = tokensString(toks, w + nchars, true, w + aind);
        nchars = if isstart then nchars else tsnchars; //pop indent when at the start of a line
      then
        (nchars, isstart, aind);

    case (BT_INDENT(width = w), toks, nchars, false, aind)
      equation
        Print.printBufSpace(w);
        (tsnchars, isstart)
          = tokensString(toks, w + nchars, false, w + aind);
        nchars = if isstart then aind else tsnchars; //pop indent when at the start of a line - there were a new line, so use the aind
      then
        (nchars, isstart, aind);

    case (BT_ABS_INDENT(width = w), toks, nchars, true, aind)
      equation
        blen = Print.getBufLength();
        (tsnchars, isstart)
          = tokensString(toks, 0, true, w); //discard an indent when at the start of a line
        blen = Print.getBufLength() - blen;
        nchars = if blen == 0 then nchars else (if isstart then aind else tsnchars); //when no chars -> pop indent; when something written -> aind for the start of a line otherwise actual position
      then
        (nchars, isstart, aind);

    case (BT_ABS_INDENT(width = w), toks, nchars, false, aind)
      equation
        (tsnchars, isstart)
          = tokensString(toks, nchars, false, w);
        nchars = if isstart then aind else tsnchars; //pop indent when at the start of a line - there were a new line, so use the aind
      then
        (nchars, isstart, aind);

    case (BT_REL_INDENT(offset = w), toks, nchars, true, aind)
      equation
        blen = Print.getBufLength();
        (tsnchars, isstart)
          = tokensString(toks, nchars, true, aind + w);
        blen = Print.getBufLength() - blen;
        nchars = if blen == 0 then nchars else (if isstart then aind else tsnchars); //when no chars -> pop indent; when something written -> aind for the start of a line otherwise actual position
      then
        (nchars, isstart, aind);

    case (BT_REL_INDENT(offset = w), toks, nchars, false, aind)
      equation
        (tsnchars, isstart)
          = tokensString(toks, nchars, false, aind + w);
        nchars = if isstart then aind else tsnchars; //pop indent when at the start of a line - there were a new line, so use the aind
      then
        (nchars, isstart, aind);

    case (BT_ANCHOR(offset = w), toks, nchars, true, aind)
      equation
        blen = Print.getBufLength();
        (tsnchars, isstart)
          = tokensString(toks, nchars, true, nchars + w);
        blen = Print.getBufLength() - blen;
        nchars = if blen == 0 then nchars else (if isstart then aind else tsnchars); //when no chars -> pop indent; when something written -> aind for the start of a line otherwise actual position
      then
        (nchars, isstart, aind);

    case (BT_ANCHOR(offset = w), toks, nchars, false, aind)
      equation
        (tsnchars, isstart)
          = tokensString(toks, nchars, false, nchars + w);
        nchars = if isstart then aind else tsnchars; //pop indent when at the start of a line - there were a new line, so use the aind
      then
        (nchars, isstart, aind);


    //iter block, no tokens ... should be impossible, but ...
    case (BT_ITER(), {}, nchars, isstart, aind)
      then
        (nchars, isstart, aind);

    //concat ... i.e. text
    case (BT_ITER(options = ITER_OPTIONS(
                              separator = NONE(),
                              alignNum = 0,
                              wrapWidth = 0)), toks, nchars, isstart, aind)
      equation
        (nchars, isstart, aind)
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
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.tokString failed.\n");
      then
        fail();
  end match;
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
  (outActualPositionOnLine, outAtStartOfLine) := match (inTokens, inSeparator, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
    local
      Tokens toks;
      StringToken tok, septok;
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
  end match;
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
protected
  Tokens toks = inTokens;
  StringToken tok;
  StringToken septok = inSeparator;
  Integer idx = inActualIndex;
  Integer anum = inAlignNum;
  StringToken asep = inAlignSeparator;
  Integer wwidth = inWrapWidth;
  StringToken wsep = inWrapSeparator;
  Integer pos = inActualPositionOnLine;
  Boolean isstart = inAtStartOfLine;
  Integer aind = inAfterNewLineIndent;
algorithm
  while (boolNot(listEmpty(toks))) loop
    tok::toks := toks;
    if((idx > 0) and (intMod(idx,anum) == 0)) then
      (pos, isstart, aind) := tokString(asep, pos, isstart, aind);
    else
      (pos, isstart, aind) := tokString(septok, pos, isstart, aind);
    end if;
    (pos, isstart, aind) := tryWrapString(wwidth, wsep, pos, isstart, aind);
    (pos, isstart, aind) := tokString(tok, pos, isstart, aind);
    idx := idx + 1;
  end while;
  (outActualPositionOnLine, outAtStartOfLine) := (pos, isstart);
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
      StringToken tok,  asep, wsep;
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
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.iterAlignWrapString failed.\n");
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

    else (inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent);
  end matchcontinue;
end tryWrapString;


public function booleanString
  input Boolean inBoolean;
  output String outString;
algorithm
  outString := match inBoolean
    case (false) then "false";
    case (true)  then "true";
  end match;
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
  outStringToken := match inText
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
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.textStrTok failed - incomplete text was passed to be converted.\n");
      then
        fail();
  end match;
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

protected function failIfTrue
  input Boolean istrue;
algorithm
  _ := match istrue
    case ( false ) then ();
    case ( _ ) then fail();
 end match;
end failIfTrue;

public function tplCallWithFailErrorNoArg
  input Tpl_Fun inFun;
  output Text txt;

  partial function Tpl_Fun
    input Text in_txt;
    output Text out_txt;
  end Tpl_Fun;
algorithm
  try
    txt := inFun(emptyTxt);
  else
    addTemplateError("A template call failed (a call with 0 parameters: " + System.dladdr(inFun) +"). One possible reason could be that a template imported function call failed (which should not happen for functions called from within template code; templates preserve pure 'match'/non-failing semantics).");
    fail();
  end try;
end tplCallWithFailErrorNoArg;

public function tplCallWithFailError
  input Tpl_Fun inFun;
  input ArgType1 inArg;
  output Text outTxt;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    output Text out_txt;
  end Tpl_Fun;
protected
  ArgType1 arg;
  Text txt;
algorithm
  outTxt := matchcontinue(inFun, inArg)
    case(_, arg)
      equation
        txt = inFun(emptyTxt, arg);
      then txt;
    else
      equation
        addTemplateError("A template call failed (a call with 1 parameter: " + System.dladdr(inFun) +"). One possible reason could be that a template imported function call failed (which should not happen for functions called from within template code; templates preserve pure 'match'/non-failing semantics).");
      then fail();
  end matchcontinue;
end tplCallWithFailError;

public function tplCallWithFailError2
  input Tpl_Fun inFun;
  input ArgType1 inArgA;
  input ArgType2 inArgB;
  output Text outTxt;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    input ArgType2 inArgB;
    output Text out_txt;
  end Tpl_Fun;
protected
  ArgType1 argA;
  ArgType2 argB;
  Text txt;
algorithm
 outTxt := matchcontinue(inFun, inArgA, inArgB)
    local
      String file,symbol;
    case(_, argA, argB)
      equation
        txt = inFun(emptyTxt, argA, argB);
      then txt;
    else
      equation
        addTemplateError("A template call failed (a call with 2 parameters: " + System.dladdr(inFun) + "). One possible reason could be that a template imported function call failed (which should not happen for functions called from within template code; templates preserve pure 'match'/non-failing semantics).");
      then fail();
  end matchcontinue;
end tplCallWithFailError2;

protected function tplCallWithFailError3
  input Tpl_Fun inFun;
  input ArgType1 inArgA;
  input ArgType2 inArgB;
  input ArgType3 inArgC;
  output Text outTxt;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    input ArgType2 inArgB;
    input ArgType3 inArgC;
    output Text out_txt;
  end Tpl_Fun;
protected
  ArgType1 argA;
  ArgType2 argB;
  ArgType3 argC;
  Text txt;
algorithm
  outTxt := matchcontinue(inFun, inArgA, inArgB, inArgC)
    case(_, argA, argB, argC)
      equation
        txt = inFun(emptyTxt, argA, argB, argC);
      then txt;
    else
      equation
        addTemplateError("A template call failed (a call with 3 parameters: " + System.dladdr(inFun) +"). One possible reason could be that a template imported function call failed (which should not happen for functions called from within template code; templates preserve pure 'match'/non-failing semantics).");
      then fail();
  end matchcontinue;
end tplCallWithFailError3;

protected function tplCallWithFailError4
  input Tpl_Fun func;
  input ArgType1 argA;
  input ArgType2 argB;
  input ArgType3 argC;
  input ArgType4 argD;
  output Text txt;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    input ArgType2 inArgB;
    input ArgType3 inArgC;
    input ArgType4 inArgD;
    output Text out_txt;
  end Tpl_Fun;
algorithm
  try
    txt := func(emptyTxt, argA, argB, argC, argD);
  else
    addTemplateError("A template call failed (a call with 4 parameters: " + System.dladdr(func) +"). One possible reason could be that a template imported function call failed (which should not happen for functions called from within template code; templates preserve pure 'match'/non-failing semantics).");
    fail();
  end try;
end tplCallWithFailError4;

public function tplString
  input Tpl_Fun inFun;
  input ArgType1 inArg;
  output String outString;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    output Text out_txt;
  end Tpl_Fun;
protected
  Text txt;
  Integer nErr;
algorithm
  nErr := Error.getNumErrorMessages();
  txt := tplCallWithFailError(inFun, inArg);
  failIfTrue(Error.getNumErrorMessages() > nErr);
  outString := textString(txt);
end tplString;

public function tplString2
  input Tpl_Fun inFun;
  input ArgType1 inArgA;
  input ArgType2 inArgB;
  output String outString;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    input ArgType2 inArgB;
    output Text out_txt;
  end Tpl_Fun;
protected
  Text txt;
  Integer nErr;
algorithm
  nErr := Error.getNumErrorMessages();
  txt := tplCallWithFailError2(inFun, inArgA, inArgB);
  failIfTrue(Error.getNumErrorMessages() > nErr);
  outString := textString(txt);
end tplString2;

public function tplString3
  input Tpl_Fun inFun;
  input ArgType1 inArgA;
  input ArgType2 inArgB;
  input ArgType3 inArgC;
  output String outString;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    input ArgType2 inArgB;
    input ArgType3 inArgC;
    output Text out_txt;
  end Tpl_Fun;
protected
  Text txt;
  Integer nErr;
algorithm
  nErr := Error.getNumErrorMessages();
  txt := tplCallWithFailError3(inFun, inArgA, inArgB, inArgC);
  failIfTrue(Error.getNumErrorMessages() > nErr);
  outString := textString(txt);
end tplString3;

public function tplPrint
  input Tpl_Fun inFun;
  input ArgType1 inArg;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    output Text out_txt;
  end Tpl_Fun;
protected
  Text txt;
  Integer nErr;
algorithm
  nErr := Error.getNumErrorMessages();
  txt := tplCallWithFailError(inFun, inArg);
  failIfTrue(Error.getNumErrorMessages() > nErr);
  textStringBuf(txt);
end tplPrint;

public function tplPrint2
  input Tpl_Fun inFun;
  input ArgType1 inArgA;
  input ArgType2 inArgB;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    input ArgType2 inArgB;
    output Text out_txt;
  end Tpl_Fun;
protected
  Text txt;
  Integer nErr;
algorithm
  nErr := Error.getNumErrorMessages();
  txt := tplCallWithFailError2(inFun, inArgA, inArgB);
  failIfTrue(Error.getNumErrorMessages() > nErr);
  textStringBuf(txt);
end tplPrint2;

public function tplPrint3
  input Tpl_Fun inFun;
  input ArgType1 inArgA;
  input ArgType2 inArgB;
  input ArgType3 inArgC;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    input ArgType2 inArgB;
    input ArgType3 inArgC;
    output Text out_txt;
  end Tpl_Fun;
protected
  Text txt;
  Integer nErr;
algorithm
  nErr := Error.getNumErrorMessages();
  txt := tplCallWithFailError3(inFun, inArgA, inArgB, inArgC);
  failIfTrue(Error.getNumErrorMessages() > nErr);
  textStringBuf(txt);
end tplPrint3;

public function tplNoret3
  input Tpl_Fun inFun;
  input ArgType1 inArg;
  input ArgType2 inArg2;
  input ArgType3 inArg3;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    input ArgType2 inArgB;
    input ArgType3 inArgC;
    output Text out_txt;
  end Tpl_Fun;
protected
  Integer nErr;
algorithm
  nErr := Error.getNumErrorMessages();
  _ := tplCallWithFailError3(inFun, inArg, inArg2, inArg3);
  failIfTrue(Error.getNumErrorMessages() > nErr);
end tplNoret3;

public function tplNoret4
  input Tpl_Fun inFun;
  input ArgType1 inArg;
  input ArgType2 inArg2;
  input ArgType3 inArg3;
  input ArgType4 inArg4;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    input ArgType2 inArgB;
    input ArgType3 inArgC;
    input ArgType4 inArgD;
    output Text out_txt;
  end Tpl_Fun;
protected
  Integer nErr;
algorithm
  nErr := Error.getNumErrorMessages();
  _ := tplCallWithFailError4(inFun, inArg, inArg2, inArg3, inArg4);
  failIfTrue(Error.getNumErrorMessages() > nErr);
end tplNoret4;

public function tplNoret2
  input Tpl_Fun inFun;
  input ArgType1 inArg;
  input ArgType2 inArg2;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    input ArgType2 inArgB;
    output Text out_txt;
  end Tpl_Fun;
protected
  Integer nErr;
algorithm
  nErr := Error.getNumErrorMessages();
  _ := tplCallWithFailError2(inFun, inArg, inArg2);
  failIfTrue(Error.getNumErrorMessages() > nErr);
end tplNoret2;

public function tplNoret
  input Tpl_Fun inFun;
  input ArgType1 inArg;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    output Text out_txt;
  end Tpl_Fun;
protected
  Integer nErr;
algorithm
  nErr := Error.getNumErrorMessages();
  _ := tplCallWithFailError(inFun, inArg);
  failIfTrue(Error.getNumErrorMessages() > nErr);
end tplNoret;


public function textFile "function: textFile:
This function renders a (memory-)text to a file."
  input Text inText;
  input String inFileName;

algorithm
  _ := matchcontinue (inText, inFileName)
    local
      Text txt;
      String file;
      Real rtTickTxt, rtTickW;
    case (txt, file)
      equation
        rtTickTxt = System.realtimeTock(ClockIndexes.RT_CLOCK_BUILD_MODEL);
        Print.clearBuf();
        textStringBuf(txt);
        rtTickW = System.realtimeTock(ClockIndexes.RT_CLOCK_BUILD_MODEL);
        Print.writeBuf(file);
        if Config.getRunningTestsuite() then
          System.appendFile(Config.getRunningTestsuiteFile(), file + "\n");
        end if;
        Print.clearBuf();
        if Flags.isSet(Flags.TPL_PERF_TIMES) then
           Debug.trace("textFile " + file
           + "\n    text:" + realString(realSub(rtTickW,rtTickTxt))
           + "\n   write:" + realString(realSub(System.realtimeTock(ClockIndexes.RT_CLOCK_BUILD_MODEL), rtTickW))
           );
        end if;
      then
        ();

    //TODO: let this function fail and the error message can be reported via  # ( textFile(txt,"file.cpp") ; failMsg="error" )
    else
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("-!!!Tpl.textFile failed - a system error ?\n");
        end if;
      then
        ();

  end matchcontinue;
end textFile;

public function textFileConvertLines "This function renders a (memory-)text to a file. If we generate modelicaLine directives, translate them to C preprocessor."
  input Text inText;
  input String inFileName;

algorithm
  _ := matchcontinue (inText, inFileName)
    local
      Text txt;
      String file;
      Real rtTickTxt, rtTickW;
    case (txt, file)
      equation
        rtTickTxt = System.realtimeTock(ClockIndexes.RT_CLOCK_BUILD_MODEL);
        Print.clearBuf();
        textStringBuf(txt);
        rtTickW = System.realtimeTock(ClockIndexes.RT_CLOCK_BUILD_MODEL);
        System.writeFile(file, "") /* To make realpath work */;
        if Config.acceptMetaModelicaGrammar() or Flags.isSet(Flags.GEN_DEBUG_SYMBOLS) then
          Print.writeBufConvertLines(System.realpath(file));
        else
          Print.writeBuf(file);
        end if;
        if Config.getRunningTestsuite() then
          System.appendFile(Config.getRunningTestsuiteFile(), file + "\n");
        end if;
        Print.clearBuf();
        if Flags.isSet(Flags.TPL_PERF_TIMES) then
           Debug.traceln("textFile " + file
           + "\n    text:" + realString(realSub(rtTickW,rtTickTxt))
           + "\n   write:" + realString(realSub(System.realtimeTock(ClockIndexes.RT_CLOCK_BUILD_MODEL), rtTickW))
           );
        end if;
      then
        ();

    //TODO: let this function fail and the error message can be reported via  # ( textFile(txt,"file.cpp") ; failMsg="error" )
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.textFile failed - a system error ?\n");
      then
        ();

  end matchcontinue;
end textFileConvertLines;

public function sourceInfo
"Magic sourceInfo() function implementation"
  input String  inFileName;
  input Integer inLineNum;
  input Integer inColumnNum;

  output SourceInfo outSourceInfo;
algorithm
  outSourceInfo  := SOURCEINFO(inFileName, false, inLineNum, inColumnNum, inLineNum, inColumnNum, 0.0);
end sourceInfo;


//we do not import Error.addSourceMessage() directly
//because of list creation in Susan is not possible (yet by design)
public function addSourceTemplateError
 "Wraps call to Error.addSourceMessage() funtion with Error.TEMPLATE_ERROR and one MessageToken."
  input String inErrMsg;
  input SourceInfo inInfo;
algorithm
  Error.addSourceMessage(Error.TEMPLATE_ERROR, {inErrMsg}, inInfo);
end addSourceTemplateError;

//for completeness
public function addTemplateError
 "Wraps call to Error.addMessage() funtion with Error.TEMPLATE_ERROR and one MessageToken."
  input String inErrMsg;
algorithm
  Error.addMessage(Error.TEMPLATE_ERROR, {inErrMsg});
end addTemplateError;

annotation(__OpenModelica_Interface="susan");
end Tpl;
