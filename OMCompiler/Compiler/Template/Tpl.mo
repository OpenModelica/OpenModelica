
encapsulated package Tpl
"
  file:        Tpl.mo
  package:     Tpl
  description: Susan

  $Id$
"

protected
import Config;
import ClockIndexes;
import Debug;
import Error;
import File;
import Flags;
import List;
import Print;
import StackOverflow;
import StringUtil;
import System;

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
  record FILE_TEXT
    Option<Integer> opaqueFile;
    array<Integer> nchars, aind;
    array<Boolean> isstart;
    array<list<BlockTypeFileText>> blocksStack;
  end FILE_TEXT;
end Text;

public constant Text emptyTxt = MEM_TEXT({}, {});

public
uniontype BlockTypeFileText
  record BT_FILE_TEXT
    BlockType bt "The block type";
    Integer nchars, aind;
    Boolean isstart;
    array<Integer> tell "Usage depends on bt; stores the last file position to know if it is empty or not.";
    array<Option<StringToken>> septok;
  end BT_FILE_TEXT;
end BlockTypeFileText;

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
    array<Integer> index0;
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
  outText := match (inText, inStr)
    local
      Tokens toks;
      list<tuple<Tokens,BlockType>> blstack;
      String str;
      Text txt;
      Integer nchars;

    //empty string means nothing
    //to ensure invariant being able to check emptiness only through the tokens (list) emtiness
    case (txt, "")
      then
        txt;

    case (MEM_TEXT(
            tokens = toks,
            blocksStack = blstack
            ), str)
      guard
        -1 == System.stringFind(str, "\n")
      then
        MEM_TEXT(ST_STRING(str) :: toks, blstack);

    case (FILE_TEXT(), str)
      guard
        -1 == System.stringFind(str, "\n")
      equation
        stringFile(inText, str, line=false);
      then inText;

    // a new-line is inside
    else
      writeChars(inText, System.strtokIncludingDelimiters(inStr, "\n"));
  end match;
end writeStr;

public function writeTok
  input Text inText;
  input StringToken inToken;

  output Text outText;
algorithm
  outText := match (inText, inToken)
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

    case (FILE_TEXT(), tok)
      algorithm
        tokFileText(inText, tok);
      then inText;

  end match;
end writeTok;

public function writeText
  input Text inText;
  input Text inTextToWrite;

  output Text outText;
algorithm
  outText := match (inText, inTextToWrite)
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

    case (FILE_TEXT(),
          MEM_TEXT(
            tokens = txttoks,
            blocksStack = {}
            ))
      algorithm
        for tok in listReverse(txttoks) loop
          writeTok(inText, tok);
        end for;
      then inText;

    //should not ever happen
    //- when compilation is correct, this is impossible (only completed texts can be accessible to write out)
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.writeText failed - incomplete text was passed to be written\n");
      then
        fail();
  end match;
end writeText;

protected function writeChars
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


protected function writeLineOrStr
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

    case (FILE_TEXT(), str, _)
      algorithm
        stringFile(inText, str, line=inIsLine);
      then inText;

  end match;
end writeLineOrStr;


protected function takeLineOrString
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
  outText := match (inText)
    local
      Text txt;
      Tokens toks;
      list<tuple<Tokens,BlockType>> blstack;
      StringToken tok;

    //empty - nothing
    case (txt as MEM_TEXT(tokens = {} ))
      then
        txt;

    case (txt as MEM_TEXT(tokens = toks))
      algorithm
        //at start of line - nothing
        if not isAtStartOfLine(txt) then
          //otherwise put normal new-line
          txt.tokens := ST_NEW_LINE() :: toks;
        end if;
      then txt;

    case FILE_TEXT()
      algorithm
        //at start of line - nothing
        if not isAtStartOfLine(inText) then
          //otherwise put normal new-line
          newlineFile(inText);
        end if;
      then inText;

    //should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.softNL failed. \n");
      then
        fail();

  end match;
end softNewLine;

protected function isAtStartOfLine
  input Text text;
  output Boolean b;
algorithm
  b := match text
    local
      StringToken tok;

    case MEM_TEXT(tokens=tok::_)
      then isAtStartOfLineTok(tok);

    case FILE_TEXT()
      then arrayGet(text.isstart,1);

  end match;
end isAtStartOfLine;

protected function isAtStartOfLineTok
  input StringToken inTok;
  output Boolean b;
algorithm
  b := match (inTok)
    local
      StringToken tok;

    //a new-line at the end
    case ( ST_NEW_LINE() )
      then true;

    //a new-line at the end
    case ( ST_LINE() )
      then true;

    //a new-line at the end
    case ( ST_STRING_LIST(lastHasNewLine = true) )
      then true;

    //recursively in the last block
    case ( ST_BLOCK(
             tokens = (tok :: _) ))
      then isAtStartOfLineTok(tok);


  // otherwise fail - not at the start
    else false;

  end match;
end isAtStartOfLineTok;


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

    case FILE_TEXT()
      algorithm
        newlineFile(inText);
      then inText;
  end match;
end newLine;


public function pushBlock
  input output Text txt;
  input BlockType inBlockType;
algorithm
  txt := match txt
    local
      Tokens toks;
      list<tuple<Tokens,BlockType>> blstack;
      BlockType blType;
      Integer nchars, aind, w;
      Boolean isstart;

    case MEM_TEXT(
            tokens = toks,
            blocksStack = blstack
            )
      then
        MEM_TEXT(
          {},
          (toks, inBlockType) :: blstack
        );

    case FILE_TEXT()
      algorithm
        nchars := arrayGet(txt.nchars,1);
        aind := arrayGet(txt.aind,1);
        isstart := arrayGet(txt.isstart,1);
        arrayUpdate(txt.blocksStack, 1, BT_FILE_TEXT(inBlockType, nchars, aind, isstart, arrayCreate(1, textFileTell(txt)), arrayCreate(1, NONE()))::arrayGet(txt.blocksStack, 1));
        _ := match inBlockType
          case BT_INDENT(width = w)
          algorithm
            arrayUpdate(txt.nchars, 1, nchars+w);
            arrayUpdate(txt.aind, 1, aind+w);
          then ();
          case BT_ABS_INDENT(width = w)
          algorithm
            if isstart then
              arrayUpdate(txt.nchars, 1, 0);
            end if;
            arrayUpdate(txt.aind, 1, w);
          then ();
          case BT_REL_INDENT(offset = w)
          algorithm
            arrayUpdate(txt.aind, 1, aind + w);
          then ();
          case BT_ANCHOR(offset = w)
          algorithm
            arrayUpdate(txt.aind, 1, nchars + w);
          then ();
          else ();
        end match;
      then txt;

    //should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.pushBlock failed \n");
      then
        fail();

  end match;
end pushBlock;


public function popBlock
  input output Text txt;
algorithm
  txt := match txt
    local
      Tokens toks, stacktoks;
      list<tuple<Tokens,BlockType>> blstack;
      BlockType blType;
      list<BlockTypeFileText> rest;
      BlockTypeFileText blk;
      Boolean oldisstart;

    //when nothing was put, just pop tokens from the stack and no block output
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

    case FILE_TEXT()
      algorithm
        blk::rest := arrayGet(txt.blocksStack, 1);
        arrayUpdate(txt.blocksStack, 1, rest);
        _ := match blk.bt
          case BT_INDENT()
            algorithm
              if arrayGet(txt.isstart,1) then
                arrayUpdate(txt.nchars, 1, blk.nchars);
              end if;
              arrayUpdate(txt.aind, 1, blk.aind);
            then ();
          case _ guard match blk.bt
            // All these have the same cases
            case BT_ABS_INDENT() then true;
            case BT_REL_INDENT() then true;
            case BT_ANCHOR() then true;
            end match
            algorithm
              oldisstart := arrayGet(txt.isstart,1);
              if oldisstart then
                if textFileTell(txt)==arrayGet(blk.tell,1) then
                  // No update, restore nchars
                  arrayUpdate(txt.nchars, 1, blk.nchars);
                else
                  // Update; restore depends on if we are at start of line
                  if arrayGet(txt.isstart,1) then
                    arrayUpdate(txt.nchars, 1, blk.aind);
                  end if;
                end if;
              else
                // Was not at start of line before
                if arrayGet(txt.isstart,1) then
                  arrayUpdate(txt.nchars, 1, blk.aind);
                end if;
              end if;
              arrayUpdate(txt.aind, 1, blk.aind);
            then ();
          else ();
        end match;
      then txt;

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
  input output Text txt;
  input IterOptions inIterOptions;
algorithm
  txt := match (txt, inIterOptions)
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
          ({}, BT_ITER(iopts, arrayCreate(1,i0))) :: (toks, BT_TEXT()) :: blstack);

    case (FILE_TEXT(),
          iopts as ITER_OPTIONS(
            startIndex0 = i0))
      algorithm
        _ := match iopts
          case ITER_OPTIONS(alignNum=0, wrapWidth=0) then ();
          else
            algorithm
              Error.addInternalError("Tpl.mo FILE_TEXT does not support aligning or wrapping elements", sourceInfo());
            then fail();
        end match;
        pushBlock(txt, BT_ITER(inIterOptions, arrayCreate(1,i0)));
      then txt;

    //should not ever happen
    case (_ , _)
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.pushIter failed \n");
      then
        fail();
  end match;
end pushIter;


public function popIter
  input output Text txt;
algorithm
  txt := match txt
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

    case FILE_TEXT()
      algorithm
        arrayUpdate(txt.blocksStack, 1, listRest(arrayGet(txt.blocksStack, 1)));
      then txt;

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
  input output Text txt;
algorithm
  txt := match txt
    local
      Tokens toks, itertoks;
      StringToken tok, emptok;
      list<tuple<Tokens,BlockType>> blstack;
      IterOptions iopts;
      array<Integer> i0, tell;
      BlockType bt;
      Integer tellpos, curIndex;
      Text txt2;
      Boolean haveToken;
      array<Option<StringToken>> septok;

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
            blocksStack = (itertoks, bt as BT_ITER(
                                       options = ITER_OPTIONS(
                                                            empty = SOME(emptok)),
                                       index0 = i0)) :: blstack
            ))
      equation
        arrayUpdate(i0, 1, arrayGet(i0,1) + 1);
      then
        MEM_TEXT(
          {},
          (emptok :: itertoks, bt) :: blstack
        );


    //one token, put it as it is
    case (MEM_TEXT(
            tokens = {tok},
            blocksStack = (itertoks, bt as BT_ITER(index0 = i0)) :: blstack
            ))
      equation
        arrayUpdate(i0, 1, arrayGet(i0,1) + 1);
      then
        MEM_TEXT(
          {},
          (tok :: itertoks, bt) :: blstack
        );

    //more tokens, put them as a text block
    case (MEM_TEXT(
            tokens = toks /* as (_::_) */,
            blocksStack = (itertoks, bt as BT_ITER(index0 = i0)) :: blstack
            ))
      equation
        arrayUpdate(i0, 1, arrayGet(i0,1) + 1);
      then
        MEM_TEXT(
          {},
          (ST_BLOCK(toks,BT_TEXT()) :: itertoks, bt) :: blstack
        );

    case FILE_TEXT()
      algorithm
        _ := match listGet(arrayGet(txt.blocksStack,1),1)
        case BT_FILE_TEXT(bt=BT_ITER(options = iopts, index0=i0), tell=tell, septok=septok)
        algorithm
          // Either the iterator always increments, or the file position changed
          tellpos := textFileTell(txt);
          if arrayGet(tell,1)<>tellpos then
            // Update file position and increment i0. Else, we are at the same position and state as before.
            arrayUpdate(tell, 1, tellpos);
            txt2 := txt;
            haveToken := true;
          else
            // File position did not change, but we might have the empty specifier
            txt2 := match iopts.empty
            case NONE()
              algorithm
                haveToken := false;
              then txt;
            case SOME(emptok)
              algorithm
                arrayUpdate(i0, 1, arrayGet(i0,1) + 1);
                haveToken := true;
              then writeTok(txt, emptok);
            end match;
          end if;
          if haveToken then
            // Handle separator
            curIndex := arrayGet(i0,1);
            arrayUpdate(septok, 1, iopts.separator);
            arrayUpdate(i0, 1, curIndex + 1);
          end if;
        then ();
        end match;
      then txt2;

    //should not ever happen
    else
      equation
        Error.addInternalError("-!!!Tpl.nextIter failed - nextIter was called in a non-iteration context?", sourceInfo());
      then
        fail();
  end match;
end nextIter;


public function getIteri_i0
  input Text inText;
  output Integer outI0;
algorithm
  outI0 := match (inText)
    local
      array<Integer> i0;

    case (MEM_TEXT(
            blocksStack = (_, BT_ITER(index0 = i0)) :: _
            ))
      then
        arrayGet(i0,1);

    case FILE_TEXT()
      then match listGet(arrayGet(inText.blocksStack,1),1) case BT_FILE_TEXT(bt=BT_ITER(index0=i0)) then arrayGet(i0,1); end match;

    //should not ever happen
    case (_ )
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.getIter_i0 failed - getIter_i0 was called in a non-iteration context ? \n");
      then
        fail();
  end match;
end getIteri_i0;

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

protected function tokensString
  input Tokens inTokens;
  input output Integer actualPositionOnLine;
  input output Boolean atStartOfLine;
  input output Integer afterNewLineIndent;
algorithm
  for tok in inTokens loop
    (actualPositionOnLine, atStartOfLine, afterNewLineIndent) := tokString(tok, actualPositionOnLine, atStartOfLine, afterNewLineIndent);
  end for;
end tokensString;

protected function tokensFile
  input File.File file;
  input Tokens inTokens;
  input output Integer actualPositionOnLine;
  input output Boolean atStartOfLine;
  input output Integer afterNewLineIndent;
algorithm
  for tok in inTokens loop
    (actualPositionOnLine, atStartOfLine, afterNewLineIndent) := tokFile(file, tok, actualPositionOnLine, atStartOfLine, afterNewLineIndent);
  end for;
end tokensFile;

protected function tokString
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

protected function tokFileText
  input Text inText;
  input StringToken inStringToken;
  input Boolean doHandleTok=true;
protected
  File.File file = File.File(getTextOpaqueFile(inText));
  Integer nchars, aind;
  Boolean isstart;
algorithm
  if doHandleTok then
    handleTok(inText);
  end if;
  _ := match inText
    case FILE_TEXT()
    algorithm
      nchars := arrayGet(inText.nchars, 1);
      aind := arrayGet(inText.aind, 1);
      isstart := arrayGet(inText.isstart, 1);
      (nchars, isstart, aind) := tokFile(file, inStringToken, nchars, isstart, aind);
      arrayUpdate(inText.nchars, 1, nchars);
      arrayUpdate(inText.aind, 1, aind);
      arrayUpdate(inText.isstart, 1, isstart);
    then ();
  end match;
end tokFileText;

protected function tokFile
  input File.File file;
  input StringToken inStringToken;
  input output Integer nchars;
  input output Boolean isstart;
  input output Integer aind;
algorithm
  (nchars, isstart, aind) := match (inStringToken, nchars, isstart, aind)
    local
      Tokens toks;
      BlockType bt;
      String str;
      list<String> strLst;

    case (ST_NEW_LINE(), _, _, aind)
      equation
        File.write(file, "\n");
      then (aind, true, aind);

    case (ST_STRING(value = str), nchars, true, aind)
      equation
        File.writeSpace(file, nchars);
        File.write(file, str);
      then
        (nchars+stringLength(str), false, aind);

    case (ST_STRING(value = str), nchars, false, aind)
      equation
        File.write(file, str);
      then
        (nchars + stringLength(str), false, aind);

    case (ST_LINE(line = str), nchars, true, aind)
      equation
        File.writeSpace(file, nchars);
        File.write(file, str);
      then
        (aind, true, aind);

    case (ST_LINE(line = str), _, false, aind)
      equation
        File.write(file, str);
      then
        (aind, true, aind);

    case (ST_STRING_LIST( strList = strLst ), nchars, isstart, aind)
      equation
        (nchars, isstart, aind)
          = stringListFile(file, strLst, nchars, isstart, aind);
      then
        (nchars, isstart, aind);

    case (ST_BLOCK(
           tokens = toks,
           blockType = bt), nchars, isstart, aind)
      equation
        (nchars, isstart, aind)
          = blockFile(file, bt, listReverse(toks), nchars, isstart, aind);
      then
        (nchars, isstart, aind);
  end match;
end tokFile;

protected function stringListString
  input list<String> inStringList;
  input Integer inActualPositionOnLine;
  input Boolean inAtStartOfLine;
  input Integer inAfterNewLineIndent;

  output Integer outActualPositionOnLine;
  output Boolean outAtStartOfLine;
  output Integer outAfterNewLineIndent;
algorithm
  (outActualPositionOnLine, outAtStartOfLine, outAfterNewLineIndent)
   := match (inStringList, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
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
      then
        (nchars, isstart, aind);

    //not at start, new line or no new line
    case (str :: strLst, nchars, false, aind)
      equation
        blen = Print.getBufLength();
        Print.printBuf(str);
        blen = Print.getBufLength() - blen;
        hasNL = Print.hasBufNewLineAtEnd();
        nchars = if hasNL then aind else nchars+blen;
        (nchars, isstart, aind) = stringListString(strLst, nchars, hasNL, aind);
      then
        (nchars, isstart, aind);

    //should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.stringListString failed.\n");
      then
        fail();
  end match;
end stringListString;

protected function stringListFile
  input File.File file;
  input list<String> inStringList;
  input output Integer nchars;
  input output Boolean isstart;
  input output Integer aind;
algorithm
  (nchars, isstart, aind)
   := match (inStringList, nchars, isstart, aind)
    local
      String str;
      list<String> strLst;
      Boolean hasNL;

    case ({}, _, isstart, aind)
      then
        (aind, isstart, aind);

    //empty string ... for sure -> it can be a special case when allowed; when let for the case at start of a line, it would output an indent
    case ("" :: strLst, nchars, isstart, aind)
      equation
        (nchars, isstart, aind)
         = stringListFile(file, strLst, nchars, isstart, aind);
      then
        (nchars, isstart, aind);


    //at start, new line or no new line
    case (str :: strLst, nchars, true, aind)
      equation
        File.writeSpace(file, nchars);
        File.write(file, str);
        hasNL = StringUtil.endsWithNewline(str);
        nchars = if hasNL then aind else (nchars+stringLength(str));
        (nchars, isstart, aind) = stringListFile(file, strLst, nchars, hasNL, aind);
      then
        (nchars, isstart, aind);

    //not at start, new line or no new line
    case (str :: strLst, nchars, false, aind)
      equation
        File.write(file, str);
        hasNL = StringUtil.endsWithNewline(str);
        nchars = if hasNL then aind else (nchars+stringLength(str));
        (nchars, isstart, aind) = stringListFile(file, strLst, nchars, hasNL, aind);
      then
        (nchars, isstart, aind);

    //should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.stringListFile failed.\n");
      then
        fail();
  end match;
end stringListFile;

protected function blockString
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


protected function iterSeparatorString
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


protected function iterSeparatorAlignWrapString
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


protected function iterAlignWrapString
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
   := match (inTokens, inActualIndex, inAlignNum, inAlignSeparator, inWrapWidth, inWrapSeparator, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
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
      guard
        (idx > 0) and (intMod(idx,anum) == 0)
      equation
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
      guard
        //false = (idx > 0) and (intMod(idx,anum) == 0);
        (wwidth > 0) and (pos >= wwidth) //check wwidth for the invariant that should be always true here
      equation
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
  end match;
end iterAlignWrapString;


protected function tryWrapString
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
   := match (inWrapWidth, inWrapSeparator, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
    local
      Integer pos, aind, wwidth;
      Boolean isstart;
      StringToken wsep;

    //wrap
    case (wwidth, wsep, pos, isstart, aind)
      guard
        (wwidth > 0) and (pos >= wwidth) //check wwidth for the invariant that should be always true here
      then
        tokString(wsep, pos, isstart, aind);

    else (inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent);
  end match;
end tryWrapString;


protected function blockFile
  input File.File file;
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
          = tokensFile(file, toks, nchars, isstart, aind);
      then
        (nchars, isstart, aind);

    case (BT_INDENT(width = w), toks, nchars, true, aind)
      equation
        (tsnchars, isstart)
          = tokensFile(file, toks, w + nchars, true, w + aind);
        nchars = if isstart then nchars else tsnchars; //pop indent when at the start of a line
      then
        (nchars, isstart, aind);

    case (BT_INDENT(width = w), toks, nchars, false, aind)
      equation
        File.writeSpace(file, w);
        (tsnchars, isstart)
          = tokensFile(file, toks, w + nchars, false, w + aind);
        nchars = if isstart then aind else tsnchars; //pop indent when at the start of a line - there were a new line, so use the aind
      then
        (nchars, isstart, aind);

    case (BT_ABS_INDENT(width = w), toks, nchars, true, aind)
      equation
        blen = File.tell(file);
        (tsnchars, isstart)
          = tokensFile(file, toks, 0, true, w); //discard an indent when at the start of a line
        blen = File.tell(file) - blen;
        nchars = if blen == 0 then nchars else (if isstart then aind else tsnchars); //when no chars -> pop indent; when something written -> aind for the start of a line otherwise actual position
      then
        (nchars, isstart, aind);

    case (BT_ABS_INDENT(width = w), toks, nchars, false, aind)
      equation
        (tsnchars, isstart)
          = tokensFile(file, toks, nchars, false, w);
        nchars = if isstart then aind else tsnchars; //pop indent when at the start of a line - there were a new line, so use the aind
      then
        (nchars, isstart, aind);

    case (BT_REL_INDENT(offset = w), toks, nchars, true, aind)
      equation
        blen = File.tell(file);
        (tsnchars, isstart)
          = tokensFile(file, toks, nchars, true, aind + w);
        blen = File.tell(file) - blen;
        nchars = if blen == 0 then nchars else (if isstart then aind else tsnchars); //when no chars -> pop indent; when something written -> aind for the start of a line otherwise actual position
      then
        (nchars, isstart, aind);

    case (BT_REL_INDENT(offset = w), toks, nchars, false, aind)
      equation
        (tsnchars, isstart)
          = tokensFile(file, toks, nchars, false, aind + w);
        nchars = if isstart then aind else tsnchars; //pop indent when at the start of a line - there were a new line, so use the aind
      then
        (nchars, isstart, aind);

    case (BT_ANCHOR(offset = w), toks, nchars, true, aind)
      equation
        blen = File.tell(file);
        (tsnchars, isstart)
          = tokensFile(file, toks, nchars, true, nchars + w);
        blen = File.tell(file) - blen;
        nchars = if blen == 0 then nchars else (if isstart then aind else tsnchars); //when no chars -> pop indent; when something written -> aind for the start of a line otherwise actual position
      then
        (nchars, isstart, aind);

    case (BT_ANCHOR(offset = w), toks, nchars, false, aind)
      equation
        (tsnchars, isstart)
          = tokensFile(file, toks, nchars, false, nchars + w);
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
          = tokensFile(file,toks, nchars, isstart, aind);
      then
        (nchars, isstart, aind);


    //separator only ...
    case (BT_ITER(options = ITER_OPTIONS(
                              separator = SOME(septok),
                              alignNum = 0,
                              wrapWidth = 0)), tok :: toks, nchars, isstart, aind)
      equation
        // put the first token, all the others with separator
        (nchars, isstart, aind) = tokFile(file, tok, nchars, isstart, aind);
        (nchars, isstart)
          = iterSeparatorFile(file, toks, septok, nchars, isstart, aind);
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
        (nchars, isstart, aind) = tokFile(file, tok, nchars, isstart, aind);
        (nchars, isstart)
          = iterSeparatorAlignWrapFile(file, toks, septok, 1 + aoffset, anum, asep, wwidth, wsep, nchars, isstart, aind);
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
          = iterAlignWrapFile(file, toks, aoffset, anum, asep, wwidth, wsep, nchars, isstart, aind);
      then
        (nchars, isstart, aind);


    //should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.tokString failed.\n");
      then
        fail();
  end match;
end blockFile;

protected function iterSeparatorFile
  input File.File file;
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
        (pos, isstart, aind) = tokFile(file, septok, pos, isstart, aind);
        (pos, isstart, aind) = tokFile(file, tok, pos, isstart, aind);
        (pos, isstart)
         = iterSeparatorFile(file, toks, septok, pos, isstart, aind);
      then
        (pos, isstart);
  end match;
end iterSeparatorFile;


protected function iterSeparatorAlignWrapFile
  input File.File file;
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
      (pos, isstart, aind) := tokFile(file, asep, pos, isstart, aind);
    else
      (pos, isstart, aind) := tokFile(file, septok, pos, isstart, aind);
    end if;
    (pos, isstart, aind) := tryWrapFile(file, wwidth, wsep, pos, isstart, aind);
    (pos, isstart, aind) := tokFile(file, tok, pos, isstart, aind);
    idx := idx + 1;
  end while;
  (outActualPositionOnLine, outAtStartOfLine) := (pos, isstart);
end iterSeparatorAlignWrapFile;


protected function iterAlignWrapFile
  input File.File file;
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
   := match (inTokens, inActualIndex, inAlignNum, inAlignSeparator, inWrapWidth, inWrapSeparator, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
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
      guard
        (idx > 0) and (intMod(idx,anum) == 0)
      equation
        (pos, isstart, aind) = tokFile(file, asep, pos, isstart, aind);
        (pos, isstart, aind) = tryWrapFile(file, wwidth, wsep, pos, isstart, aind);
        (pos, isstart, aind) = tokFile(file, tok, pos, isstart, aind);
        (pos, isstart)
         = iterAlignWrapFile(file, toks, idx + 1, anum, asep, wwidth, wsep,
                pos, isstart, aind);
      then
        (pos, isstart);
    //wrap
    case (tok :: toks, idx, anum, asep, wwidth, wsep, pos, isstart, aind)
      guard
        //false = (idx > 0) and (intMod(idx,anum) == 0);
        (wwidth > 0) and (pos >= wwidth) //check wwidth for the invariant that should be always true here
      equation
        (pos, isstart, aind) = tokFile(file, wsep, pos, isstart, aind);
        (pos, isstart, aind) = tokFile(file, tok, pos, isstart, aind);
        (pos, isstart)
          = iterAlignWrapFile(file, toks, idx + 1, anum, asep, wwidth, wsep,
                pos, isstart, aind);
      then
        (pos, isstart);

    //item only
    case (tok :: toks, idx, anum, asep, wwidth, wsep, pos, isstart, aind)
      equation
        //false = (idx > 0) and (intMod(idx,anum) == 0);
        //false = (wwidth > 0) and (pos >= wwidth); //check wwidth for the invariant that should be always true here
        (pos, isstart, aind) = tokFile(file, tok, pos, isstart, aind);
        (pos, isstart)
         = iterAlignWrapFile(file, toks, idx + 1, anum, asep, wwidth, wsep,
              pos, isstart, aind);
      then
        (pos, isstart);

    //should not ever happen
    else
      equation
        true = Flags.isSet(Flags.FAILTRACE); Debug.trace("-!!!Tpl.iterAlignWrapString failed.\n");
      then
        fail();
  end match;
end iterAlignWrapFile;


protected function tryWrapFile
  input File.File file;
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
   := match (inWrapWidth, inWrapSeparator, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
    local
      Integer pos, aind, wwidth;
      Boolean isstart;
      StringToken wsep;

    //wrap
    case (wwidth, wsep, pos, isstart, aind)
      guard
        (wwidth > 0) and (pos >= wwidth) //check wwidth for the invariant that should be always true here
      then
        tokFile(file, wsep, pos, isstart, aind);

    else (inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent);
  end match;
end tryWrapFile;


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

public function failIfTrue
  input Boolean istrue;
algorithm
  if istrue then
    fail();
  end if;
end failIfTrue;

protected function tplCallHandleErrors
  input Tpl_Fun inFun;
  input output Text txt = emptyTxt;

  partial function Tpl_Fun
    input Text in_txt;
    output Text out_txt;
  end Tpl_Fun;
protected
  Integer nErr;
algorithm
  nErr := Error.getNumErrorMessages();
  try
  try
    txt := inFun(txt);
  else
    addTemplateErrorFunc(inFun);
    fail();
  end try;
  else
    if StackOverflow.hasStacktraceMessages() then
       Error.addInternalError("Stack overflow when evaluating function:\n"+ stringDelimitList(StackOverflow.readableStacktraceMessages(), "\n"), sourceInfo());
    end if;
    addTemplateErrorFunc(inFun);
    fail();
  end try annotation(__OpenModelica_stackOverflowCheckpoint=true);
end tplCallHandleErrors;

public function tplCallWithFailErrorNoArg
  input Tpl_Fun inFun;
  input output Text txt = emptyTxt;

  partial function Tpl_Fun
    input Text in_txt;
    output Text out_txt;
  end Tpl_Fun;
algorithm
  txt := tplCallHandleErrors(inFun, txt);
end tplCallWithFailErrorNoArg;

public function tplCallWithFailError
  input Tpl_Fun inFun;
  input ArgType1 inArg;
  input output Text txt = emptyTxt;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    output Text out_txt;
  end Tpl_Fun;
protected
  ArgType1 arg;
algorithm
  txt := tplCallHandleErrors(function inFun(inArgA=inArg), txt);
end tplCallWithFailError;

public function tplCallWithFailError2
  input Tpl_Fun inFun;
  input ArgType1 inArgA;
  input ArgType2 inArgB;
  input output Text txt = emptyTxt;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    input ArgType2 inArgB;
    output Text out_txt;
  end Tpl_Fun;
protected
  ArgType1 argA;
  ArgType2 argB;
algorithm
  txt := tplCallHandleErrors(function inFun(inArgA=inArgA, inArgB=inArgB), txt);
end tplCallWithFailError2;

function tplCallWithFailError3
  input Tpl_Fun inFun;
  input ArgType1 inArgA;
  input ArgType2 inArgB;
  input ArgType3 inArgC;
  input output Text txt = emptyTxt;

  partial function Tpl_Fun
    input Text in_txt;
    input ArgType1 inArgA;
    input ArgType2 inArgB;
    input ArgType3 inArgC;
    output Text out_txt;
  end Tpl_Fun;
algorithm
  txt := tplCallHandleErrors(function inFun(inArgA=inArgA, inArgB=inArgB, inArgC=inArgC), txt);
end tplCallWithFailError3;

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
protected function addTemplateErrorFunc<T>
 "Wraps call to Error.addMessage() funtion with Error.TEMPLATE_ERROR and one MessageToken."
  input T func;
algorithm
  Error.addMessage(Error.TEMPLATE_ERROR_FUNC, {System.dladdr(func)});
end addTemplateErrorFunc;

public function addTemplateError
 "Wraps call to Error.addMessage() funtion with Error.TEMPLATE_ERROR and one MessageToken."
  input String msg;
algorithm
  Error.addMessage(Error.TEMPLATE_ERROR, {msg});
end addTemplateError;

public function redirectToFile
"Magic sourceInfo() function implementation"
  input output Text text;
  input String fileName;
protected
  File.File file = File.File();
algorithm
  if Config.getRunningTestsuite() then
    System.appendFile(Config.getRunningTestsuiteFile(), fileName + "\n");
  end if;
  File.open(file, fileName, File.Mode.Write);
  text := writeText(FILE_TEXT(File.getReference(file), arrayCreate(1, 0), arrayCreate(1, 0), arrayCreate(1, true), arrayCreate(1, {})), text);
end redirectToFile;

public function closeFile
"Magic sourceInfo() function implementation"
  input output Text text;
protected
  File.File file = File.File(getTextOpaqueFile(text));
algorithm
  File.releaseReference(file);
  text := emptyTxt;
end closeFile;

public function booleanString // TODO: Remove me
  input Boolean b;
  output String s;
algorithm
  s := String(b);
end booleanString;

protected function getTextOpaqueFile
  input Text text;
  output Option<Integer> opaqueFile;
algorithm
  opaqueFile := match text
    case FILE_TEXT() then text.opaqueFile;
    else
    algorithm
      Error.addInternalError("tokFile got non-file text input", sourceInfo());
    then fail();
  end match;
end getTextOpaqueFile;

protected function stringFile "Like ST_STRING or ST_LINE"
  input Text inText;
  input String str;
  input Boolean line;
  input Boolean recurseSeparator=true;
protected
  File.File file = File.File(getTextOpaqueFile(inText));
  Integer nchars;
  IterOptions iopts;
  StringToken septok;
algorithm
  _ := match inText
  case FILE_TEXT()
  algorithm
    handleTok(inText);
    nchars := arrayGet(inText.nchars, 1);
    if not line then
      if arrayGet(inText.isstart,1) then
        File.writeSpace(file, nchars);
        File.write(file, str);
        arrayUpdate(inText.nchars, 1, nchars+stringLength(str));
        arrayUpdate(inText.isstart, 1, false);
      else
        File.write(file, str);
        arrayUpdate(inText.nchars, 1, nchars+stringLength(str));
      end if;
    else
      if arrayGet(inText.isstart,1) then
        File.writeSpace(file, nchars);
      else
        arrayUpdate(inText.isstart,1,true);
      end if;
      File.write(file, str);
      arrayUpdate(inText.nchars,1,arrayGet(inText.aind,1));
    end if;
  then ();
  end match;
end stringFile;

protected function newlineFile "Like ST_NEWLINE"
  input Text inText;
protected
  File.File file = File.File(getTextOpaqueFile(inText));
  Integer nchars;
algorithm
  _ := match inText
  case FILE_TEXT()
  algorithm
    File.write(file, "\n");
    arrayUpdate(inText.nchars, 1, arrayGet(inText.aind, 1));
    arrayUpdate(inText.isstart, 1, true);
  then ();
  end match;
end newlineFile;

protected function textFileTell
  input Text inText;
  output Integer tell;
protected
  File.File file = File.File(getTextOpaqueFile(inText));
algorithm
  tell := File.tell(file);
end textFileTell;

protected function handleTok "Handle a new token, for example separators"
  input Text txt;
protected
  StringToken septok;
  array<Option<StringToken>> aseptok;
algorithm
  _ := match txt
  case FILE_TEXT()
  algorithm
    _ := match arrayGet(txt.blocksStack, 1)
      case (BT_FILE_TEXT(bt=BT_ITER(), septok=aseptok)::_)
      algorithm
        _ := match arrayGet(aseptok,1)
        case SOME(septok)
        algorithm
          arrayUpdate(aseptok,1,NONE());
          tokFileText(txt, septok, doHandleTok=false);
        then ();
        else ();
        end match;
      then ();
      else ();
    end match;
  then ();
  end match;
end handleTok;

public function debugSusan
  output Boolean b;
algorithm
  b := Flags.isSet(Flags.SUSAN_MATCHCONTINUE_DEBUG);
end debugSusan;

public function fakeStackOverflow
algorithm
  Error.addInternalError("Stack overflow:\n" + StackOverflow.generateReadableMessage(), sourceInfo());
  StackOverflow.triggerStackOverflow();
end fakeStackOverflow;

annotation(__OpenModelica_Interface="susan");
end Tpl;
