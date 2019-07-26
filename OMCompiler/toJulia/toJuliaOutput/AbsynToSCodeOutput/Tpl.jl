module Tpl

#= Automatically generated with some minor adjustments=#

using MetaModelica
#= Necessary to write declarations for your uniontypes until Julia adds support for mutually recursive types =#

Lst = MetaModelica.List

@UniontypeDecl Text
@UniontypeDecl BlockTypeFileText
@UniontypeDecl StringToken
@UniontypeDecl BlockType
@UniontypeDecl IterOptions

Tpl_Fun = Function

import Config
import ClockIndexes
import Debug
import Error
import File
import Flags
import MetaModelica.ListUtil
import Print
import StackOverflow
import StringUtil
import System
#=  indentation will be implemented through spaces
=#
#=  where tabs will be converted where 1 tab = 4 spaces ??
=#

Tokens = Lst

@Uniontype Text begin
  @Record MEM_TEXT begin

    tokens::Tokens
    #= reversed list of tokens
    =#
    blocksStack::Lst
  end

  @Record FILE_TEXT begin

    opaqueFile::Option
    nchars::Array
    aind::Array
    isstart::Array
    blocksStack::Array
  end
end

emptyTxt = MEM_TEXT(list(), list())::Text

@Uniontype BlockTypeFileText begin
  @Record BT_FILE_TEXT begin

    bt #= The block type =#::BlockType
    nchars::ModelicaInteger
    aind::ModelicaInteger
    isstart::Bool
    tell #= Usage depends on bt; stores the last file position to know if it is empty or not. =#::Array
    septok::Array
  end
end

@Uniontype StringToken begin
  @Record ST_NEW_LINE begin

  end

  @Record ST_STRING begin

    value::String
  end

  @Record ST_LINE begin

    line::String
  end

  @Record ST_STRING_LIST begin

    strList::Lst
    lastHasNewLine #= True when the last string in the list has new-line at the end. =#::Bool
  end

  @Record ST_BLOCK begin

    tokens::Tokens
    blockType::BlockType
  end
end

@Uniontype BlockType begin
  @Record BT_TEXT begin

  end

  @Record BT_INDENT begin

    width::ModelicaInteger
  end

  @Record BT_ABS_INDENT begin

    width::ModelicaInteger
  end

  @Record BT_REL_INDENT begin

    offset::ModelicaInteger
  end

  @Record BT_ANCHOR begin

    offset::ModelicaInteger
  end

  @Record BT_ITER begin

    options::IterOptions
    index0::Array
  end
end

@Uniontype IterOptions begin
  @Record ITER_OPTIONS begin

    startIndex0::ModelicaInteger
    empty::Option
    separator::Option
    alignNum #= Number of items to be aligned by. When 0, no alignment. =#::ModelicaInteger
    alignOfset::ModelicaInteger
    alignSeparator::StringToken
    wrapWidth #= Number of chars on a line, after that the wrapping can occur. When 0, no wrapping. =#::ModelicaInteger
    wrapSeparator::StringToken
  end
end

ArgType1 = Any
ArgType2 = Any
ArgType3 = Any
ArgType4 = Any
#= by default, we will parse new lines in every non-token string
=#

function writeStr(inText::Text, inStr::String)::Text
  local outText::Text

  outText = begin
    local toks::Tokens
    local blstack::Lst
    local str::String
    local txt::Text
    local nchars::ModelicaInteger
    #= empty string means nothing
    =#
    #= to ensure invariant being able to check emptiness only through the tokens (list) emtiness
    =#
    @match (inText, inStr) begin
      (txt, "")  => begin
        txt
      end

      (MEM_TEXT(tokens = toks, blocksStack = blstack), str) where (-1) == System.stringFind(str, "\n")  => begin
        MEM_TEXT(ST_STRING(str) <| toks, blstack)
      end

      (FILE_TEXT(), str) where (-1) == System.stringFind(str, "\n")  => begin
        stringFile(inText, str, line = false)
        inText
      end

      _  => begin
        writeChars(inText, System.strtokIncludingDelimiters(inStr, "\n"))
      end
    end
  end
  #=  a new-line is inside
  =#
  outText
end

function writeTok(inText::Text, inToken::StringToken)::Text
  local outText::Text

  outText = begin
    local txt::Text
    local toks::Tokens
    local blstack::Lst
    local tok::StringToken
    #= to ensure invariant being able to check emptiness only through the tokens (list) emtiness
    =#
    #= should not happen, tokens must have at least one element
    =#
    @match (inText, inToken) begin
      (txt, ST_BLOCK(tokens =  nil()))  => begin
        txt
      end

      (txt, ST_STRING(value = ""))  => begin
        txt
      end

      (MEM_TEXT(tokens = toks, blocksStack = blstack), tok)  => begin
        MEM_TEXT(tok <| toks, blstack)
      end

      (FILE_TEXT(), tok)  => begin
        #= same as above - compiler should not generate this value in any case
        =#
        tokFileText(inText, tok)
        inText
      end
    end
  end
  outText
end

function writeText(inText::Text, inTextToWrite::Text)::Text
  local outText::Text

  outText = begin
    local toks::Tokens
    local txttoks::Tokens
    local blstack::Lst
    local txt::Text
    #= to ensure invariant being able to check emptiness only through the tokens (list) emtiness
    =#
    @match (inText, inTextToWrite) begin
      (txt, MEM_TEXT(tokens =  nil()))  => begin
        txt
      end

      (MEM_TEXT(tokens = toks, blocksStack = blstack), MEM_TEXT(tokens = txttoks, blocksStack =  nil()))  => begin
        MEM_TEXT(ST_BLOCK(txttoks, BT_TEXT()) <| toks, blstack)
      end

      (FILE_TEXT(), MEM_TEXT(tokens = txttoks, blocksStack =  nil()))  => begin
        for tok in listReverse(txttoks)
          writeTok(inText, tok)
        end
        inText
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.writeText failed - incomplete text was passed to be written\n")
        fail()
      end
    end
  end
  #= should not ever happen
  =#
  #= - when compilation is correct, this is impossible (only completed texts can be accessible to write out)
  =#
  outText
end

function writeChars(inText::Text, inChars::Lst)::Text
  local outText::Text

  outText = begin
    local txt::Text
    local c::String
    local chars::Lst
    local lschars::Lst
    local isline::Bool
    @match (inText, inChars) begin
      (txt,  nil())  => begin
        txt
      end

      (txt, "\n" <| chars)  => begin
        txt = newLine(txt)
        writeChars(txt, chars)
      end

      (txt, c <| chars)  => begin
        (lschars, chars, isline) = takeLineOrString(chars)
        txt = writeLineOrStr(txt, stringAppendList(c <| lschars), isline)
        writeChars(txt, chars)
      end

      (_, _)  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.writeChars failed.\n")
        fail()
      end
    end
  end
  #= leading new-lines
  =#
  #= non-new-line at the start of the string, so a string or line only follows
  =#
  #= Error txt = writeLineOrStr(txt, stringCharListString( str :: lschars), isline);
  =#
  #= should not ever happen
  =#
  outText
end

function writeLineOrStr(inText::Text, inStr::String, inIsLine::Bool)::Text
  local outText::Text

  outText = begin
    local toks::Tokens
    local blstack::Lst
    local str::String
    local txt::Text
    #= empty string means nothing
    =#
    #= to ensure invariant being able to check emptiness only through the tokens (list) emtiness
    =#
    #= should not happen
    =#
    @match (inText, inStr, inIsLine) begin
      (txt, "", _)  => begin
        txt
      end

      (MEM_TEXT(tokens = toks, blocksStack = blstack), str, false)  => begin
        MEM_TEXT(ST_STRING(str) <| toks, blstack)
      end

      (MEM_TEXT(tokens = toks, blocksStack = blstack), str, true)  => begin
        MEM_TEXT(ST_LINE(str) <| toks, blstack)
      end

      (FILE_TEXT(), str, _)  => begin
        stringFile(inText, str, line = inIsLine)
        inText
      end
    end
  end
  outText
end

function takeLineOrString(inChars::Lst)::Tuple{Bool, List, List}
  local outIsLine::Bool
  local outRestChars::Lst
  local outTillNewLineChars::Lst

  (outTillNewLineChars, outRestChars, outIsLine) = begin
    local char::String
    local tnlchars::Lst
    local restchars::Lst
    local chars::Lst
    local isline::Bool
    @match inChars begin
      nil()  => begin
        (list(), list(), false)
      end

      "\n" <| chars  => begin
        (list("\n"), chars, true)
      end

      char <| chars  => begin
        (tnlchars, restchars, isline) = takeLineOrString(chars)
        (char <| tnlchars, restchars, isline)
      end
    end
  end
  (outIsLine, outRestChars, outTillNewLineChars)
end

function softNewLine(inText::Text)::Text
  local outText::Text

  outText = begin
    local txt::Text
    local toks::Tokens
    local blstack::Lst
    local tok::StringToken
    #= empty - nothing
    =#
    @match inText begin
      MEM_TEXT(tokens =  nil())  => begin
        txt
      end

      MEM_TEXT(tokens = toks)  => begin
        #= at start of line - nothing
        =#
        txt = MEM_TEXT(tokens = toks)
        if ! isAtStartOfLine(txt)
          txt.tokens = ST_NEW_LINE() <| toks
        end
        #= otherwise put normal new-line
        =#
        txt
      end

      FILE_TEXT()  => begin
        #= at start of line - nothing
        =#
        if ! isAtStartOfLine(inText)
          newlineFile(inText)
        end
        #= otherwise put normal new-line
        =#
        inText
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.softNL failed. \n")
        fail()
      end
    end
  end
  #= should not ever happen
  =#
  outText
end

function isAtStartOfLine(text::Text)::Bool
  local b::Bool

  b = begin
    local tok::StringToken
    @match text begin
      MEM_TEXT(tokens = tok <| _)  => begin
        isAtStartOfLineTok(tok)
      end

      FILE_TEXT()  => begin
        arrayGet(text.isstart, 1)
      end
    end
  end
  b
end

function isAtStartOfLineTok(inTok::StringToken)::Bool
  local b::Bool

  b = begin
    local tok::StringToken
    #= a new-line at the end
    =#
    @match inTok begin
      ST_NEW_LINE()  => begin
        true
      end

      ST_LINE()  => begin
        true
      end

      ST_STRING_LIST(lastHasNewLine = true)  => begin
        true
      end

      ST_BLOCK(tokens = tok <| _)  => begin
        isAtStartOfLineTok(tok)
      end

      _  => begin
        false
      end
    end
  end
  #= a new-line at the end
  =#
  #= a new-line at the end
  =#
  #= recursively in the last block
  =#
  #=  otherwise fail - not at the start
  =#
  b
end

function newLine(inText::Text)::Text
  local outText::Text

  outText = begin
    local toks::Tokens
    local blstack::Lst
    @match inText begin
      MEM_TEXT(tokens = toks, blocksStack = blstack)  => begin
        MEM_TEXT(ST_NEW_LINE() <| toks, blstack)
      end

      FILE_TEXT()  => begin
        newlineFile(inText)
        inText
      end
    end
  end
  outText
end

function pushBlock(txt::Text, inBlockType::BlockType)::Text


  txt = begin
    local toks::Tokens
    local blstack::Lst
    local blType::BlockType
    local nchars::ModelicaInteger
    local aind::ModelicaInteger
    local w::ModelicaInteger
    local isstart::Bool
    @match txt begin
      MEM_TEXT(tokens = toks, blocksStack = blstack)  => begin
        MEM_TEXT(list(), (toks, inBlockType) <| blstack)
      end

      FILE_TEXT()  => begin
        nchars = arrayGet(txt.nchars, 1)
        aind = arrayGet(txt.aind, 1)
        isstart = arrayGet(txt.isstart, 1)
        arrayUpdate(txt.blocksStack, 1, BT_FILE_TEXT(inBlockType, nchars, aind, isstart, arrayCreate(1, textFileTell(txt)), arrayCreate(1, NONE())) <| arrayGet(txt.blocksStack, 1))
        _ = begin
          @match inBlockType begin
            BT_INDENT(width = w)  => begin
              arrayUpdate(txt.nchars, 1, nchars + w)
              arrayUpdate(txt.aind, 1, aind + w)
              ()
            end

            BT_ABS_INDENT(width = w)  => begin
              if isstart
                arrayUpdate(txt.nchars, 1, 0)
              end
              arrayUpdate(txt.aind, 1, w)
              ()
            end

            BT_REL_INDENT(offset = w)  => begin
              arrayUpdate(txt.aind, 1, aind + w)
              ()
            end

            BT_ANCHOR(offset = w)  => begin
              arrayUpdate(txt.aind, 1, nchars + w)
              ()
            end

            _  => begin
              ()
            end
          end
        end
        txt
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.pushBlock failed \n")
        fail()
      end
    end
  end
  #= should not ever happen
  =#
  txt
end

function popBlock(txt::Text)::Text


  txt = begin
    local toks::Tokens
    local stacktoks::Tokens
    local blstack::Lst
    local blType::BlockType
    local rest::Lst
    local blk::BlockTypeFileText
    local oldisstart::Bool
    #= when nothing was put, just pop tokens from the stack and no block output
    =#
    @match txt begin
      MEM_TEXT(tokens =  nil(), blocksStack = (stacktoks, _) <| blstack)  => begin
        MEM_TEXT(stacktoks, blstack)
      end

      MEM_TEXT(tokens = toks, blocksStack = (stacktoks, blType) <| blstack)  => begin
        MEM_TEXT(ST_BLOCK(toks, blType) <| stacktoks, blstack)
      end

      FILE_TEXT()  => begin
        blk, rest = listHead(arrayGet(txt.blocksStack, 1)), listRest(arrayGet(txt.blocksStack, 1))
        arrayUpdate(txt.blocksStack, 1, rest)
        _ = begin
          @match blk.bt begin
            BT_INDENT()  => begin
              if arrayGet(txt.isstart, 1)
                arrayUpdate(txt.nchars, 1, blk.nchars)
              end
              arrayUpdate(txt.aind, 1, blk.aind)
              ()
            end

            _ where begin
              @match blk.bt begin
                BT_ABS_INDENT()  => begin
                  true
                end

                BT_REL_INDENT()  => begin
                  true
                end

                BT_ANCHOR()  => begin
                  true
                end
              end
            end  => begin
              #=  All these have the same cases
              =#
              oldisstart = arrayGet(txt.isstart, 1)
              if oldisstart
                if textFileTell(txt) == arrayGet(blk.tell, 1)
                  arrayUpdate(txt.nchars, 1, blk.nchars)
                else
                  if arrayGet(txt.isstart, 1)
                    arrayUpdate(txt.nchars, 1, blk.aind)
                  end
                end
              else
                if arrayGet(txt.isstart, 1)
                  arrayUpdate(txt.nchars, 1, blk.aind)
                end
              end
              #=  No update, restore nchars
              =#
              #=  Update; restore depends on if we are at start of line
              =#
              #=  Was not at start of line before
              =#
              arrayUpdate(txt.aind, 1, blk.aind)
              ()
            end

            _  => begin
              ()
            end
          end
        end
        txt
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.popBlock failed - probably pushBlock and popBlock are not well balanced !\n")
        fail()
      end
    end
  end
  #= should not ever happen
  =#
  #= - when compilation is correct, this is impossible (pushs and pops should be balanced)
  =#
  txt
end

function pushIter(txt::Text, inIterOptions::IterOptions)::Text


  txt = begin
    local toks::Tokens
    local blstack::Lst
    local iopts::IterOptions
    local i0::ModelicaInteger
    @match (txt, inIterOptions) begin
      (MEM_TEXT(tokens = toks, blocksStack = blstack), ITER_OPTIONS(startIndex0 = i0))  => begin
        iopts = ITER_OPTIONS(startIndex0 = i0)
        MEM_TEXT(list(), (list(), BT_ITER(iopts, arrayCreate(1, i0))) <| (toks, BT_TEXT()) <| blstack)
      end

      (FILE_TEXT(), ITER_OPTIONS(startIndex0 = i0))  => begin
        #= let the existing tokens on stack in the text block and start iterating
        =#
        iopts = ITER_OPTIONS(startIndex0 = i0)
        () = begin
          @match iopts begin
            ITER_OPTIONS(alignNum = 0, wrapWidth = 0)  => begin
              ()
            end
            _  => begin
              Error.addInternalError("Tpl.mo FILE_TEXT does not support aligning or wrapping elements", sourceInfo())
              fail()
            end
          end
        end
        pushBlock(txt, BT_ITER(inIterOptions, arrayCreate(1, i0)))
        txt
      end

      (_, _)  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.pushIter failed \n")
        fail()
      end
    end
  end
  #= should not ever happen
  =#
  txt
end

function popIter(txt::Text)::Text


  txt = begin
    local stacktoks::Tokens
    local itertoks::Tokens
    local blstack::Lst
    local blType::BlockType
    #= nothing was iterated, pop only the stacked tokens
    =#
    @match txt begin
      MEM_TEXT(tokens =  nil(), blocksStack = ( nil(), _) <| (stacktoks, _) <| blstack)  => begin
        MEM_TEXT(stacktoks, blstack)
      end

      MEM_TEXT(tokens =  nil(), blocksStack = (itertoks, blType) <| (stacktoks, _) <| blstack)  => begin
        MEM_TEXT(ST_BLOCK(itertoks, blType) <| stacktoks, blstack)
      end

      FILE_TEXT()  => begin
        arrayUpdate(txt.blocksStack, 1, listRest(arrayGet(txt.blocksStack, 1)))
        txt
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.popIter failed - probably pushIter and popIter are not well balanced or something was written between the last nextIter and popIter ?\n")
        fail()
      end
    end
  end
  #= should not ever happen
  =#
  #= - when compilation is correct, this is impossible (pushs and pops should be balanced)
  =#
  txt
end

function nextIter(txt::Text)::Text
  println("Fixme. Patternmatching to complicated for us to handle atm")
  txt
end

function getIteri_i0(inText::Text)::ModelicaInteger
  local outI0::ModelicaInteger

  outI0 = begin
    local i0::Array
    @match inText begin
      MEM_TEXT(blocksStack = (_, BT_ITER(index0 = i0)) <| _)  => begin
        arrayGet(i0, 1)
      end

      FILE_TEXT()  => begin
        begin
          @match listGet(arrayGet(inText.blocksStack, 1), 1) begin
            BT_FILE_TEXT(bt = BT_ITER(index0 = i0))  => begin
              arrayGet(i0, 1)
            end
          end
        end
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.getIter_i0 failed - getIter_i0 was called in a non-iteration context ? \n")
        fail()
      end
    end
  end
  #= should not ever happen
  =#
  outI0
end

#= function: textString:
This function renders a (memory-)text to string. =#
function textString(inText::Text)::String
  local outString::String

  outString = begin
    local txt::Text
    local str::String
    local handle::ModelicaInteger
    @match inText begin
      txt  => begin
        handle = Print.saveAndClearBuf()
        textStringBuf(txt)
        str = Print.getString()
        Print.restoreBuf(handle)
        str
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.textString failed.\n")
        fail()
      end
    end
  end
  #= should not ever happen
  =#
  outString
end

#= function: textStringBuf:
This function renders a (memory-)text to (Print.)string buffer. =#
function textStringBuf(inText::Text)
  () = begin
    local toks::Tokens
    @match inText begin
      MEM_TEXT(tokens = toks, blocksStack =  nil())  => begin
        (_, _) = tokensString(listReverse(toks), 0, true, 0)
        ()
      end

      MEM_TEXT(blocksStack = _ <| _)  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.textString failed - a non-comlete text was given.\n")
        fail()
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.textString failed.\n")
        fail()
      end
    end
  end
  #= should not ever happen
  =#
end

function tokensString(inTokens::Tokens, actualPositionOnLine::ModelicaInteger, atStartOfLine::Bool, afterNewLineIndent::ModelicaInteger)::Tuple{ModelicaInteger, Bool, ModelicaInteger}
  for tok in inTokens
    (actualPositionOnLine, atStartOfLine, afterNewLineIndent) = tokString(tok, actualPositionOnLine, atStartOfLine, afterNewLineIndent)
  end
  (afterNewLineIndent, atStartOfLine, actualPositionOnLine)
end

function tokensFile(file::File.FILE, inTokens::Tokens, actualPositionOnLine::ModelicaInteger, atStartOfLine::Bool, afterNewLineIndent::ModelicaInteger)::Tuple{ModelicaInteger, Bool, ModelicaInteger}
  for tok in inTokens
    (actualPositionOnLine, atStartOfLine, afterNewLineIndent) = tokFile(file, tok, actualPositionOnLine, atStartOfLine, afterNewLineIndent)
  end
  (afterNewLineIndent, atStartOfLine, actualPositionOnLine)
end

function tokString(inStringToken::StringToken, inActualPositionOnLine::ModelicaInteger, inAtStartOfLine::Bool, inAfterNewLineIndent::ModelicaInteger)::Tuple{ModelicaInteger, Bool, ModelicaInteger}
  local outAfterNewLineIndent::ModelicaInteger
  local outAtStartOfLine::Bool
  local outActualPositionOnLine::ModelicaInteger

  (outActualPositionOnLine, outAtStartOfLine, outAfterNewLineIndent) = begin
    local toks::Tokens
    local bt::BlockType
    local str::String
    local strLst::Lst
    local nchars::ModelicaInteger
    local aind::ModelicaInteger
    local blen::ModelicaInteger
    local isstart::Bool
    @match (inStringToken, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent) begin
      (ST_NEW_LINE(), _, _, aind)  => begin
        Print.printBufNewLine()
        (aind, true, aind)
      end

      (ST_STRING(value = str), nchars, true, aind)  => begin
        blen = Print.getBufLength()
        Print.printBufSpace(nchars)
        Print.printBuf(str)
        blen = Print.getBufLength() - blen
        (blen, false, aind)
      end

      (ST_STRING(value = str), nchars, false, aind)  => begin
        blen = Print.getBufLength()
        Print.printBuf(str)
        blen = Print.getBufLength() - blen
        (nchars + blen, false, aind)
      end

      (ST_LINE(line = str), nchars, true, aind)  => begin
        Print.printBufSpace(nchars)
        Print.printBuf(str)
        (aind, true, aind)
      end

      (ST_LINE(line = str), _, false, aind)  => begin
        Print.printBuf(str)
        (aind, true, aind)
      end

      (ST_STRING_LIST(strList = strLst), nchars, isstart, aind)  => begin
        (nchars, isstart, aind) = stringListString(strLst, nchars, isstart, aind)
        (nchars, isstart, aind)
      end

      (ST_BLOCK(tokens = toks, blockType = bt), nchars, isstart, aind)  => begin
        (nchars, isstart, aind) = blockString(bt, listReverse(toks), nchars, isstart, aind)
        (nchars, isstart, aind)
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.tokString failed.\n")
        fail()
      end
    end
  end
  #= str = spaceStr(nchars) + str; indent is actually stored in nchars when on start of the line
  =#
  #= str = spaceStr(nchars) + str; indent is actually stored in nchars when on start of the line
  =#
  #= should not ever happen
  =#
  (outAfterNewLineIndent, outAtStartOfLine, outActualPositionOnLine)
end

function tokFileText(inText::Text, inStringToken::StringToken, doHandleTok::Bool)
  local file::File.FILE = File.FILE(getTextOpaqueFile(inText))
  local nchars::ModelicaInteger
  local aind::ModelicaInteger
  local isstart::Bool

  if doHandleTok
    handleTok(inText)
  end
  () = begin
    @match inText begin
      FILE_TEXT()  => begin
        nchars = arrayGet(inText.nchars, 1)
        aind = arrayGet(inText.aind, 1)
        isstart = arrayGet(inText.isstart, 1)
        (nchars, isstart, aind) = tokFile(file, inStringToken, nchars, isstart, aind)
        arrayUpdate(inText.nchars, 1, nchars)
        arrayUpdate(inText.aind, 1, aind)
        arrayUpdate(inText.isstart, 1, isstart)
        ()
      end
    end
  end
end

function tokFile(file::File.FILE, inStringToken::StringToken, nchars::ModelicaInteger, isstart::Bool, aind::ModelicaInteger)::Tuple{ModelicaInteger, Bool, ModelicaInteger}
  (nchars, isstart, aind) = begin
    local toks::Tokens
    local bt::BlockType
    local str::String
    local strLst::Lst
    @match (inStringToken, nchars, isstart, aind) begin
      (ST_NEW_LINE(), _, _, aind)  => begin
        File.write(file, "\n")
        (aind, true, aind)
      end

      (ST_STRING(value = str), nchars, true, aind)  => begin
        File.writeSpace(file, nchars)
        File.write(file, str)
        (nchars + stringLength(str), false, aind)
      end

      (ST_STRING(value = str), nchars, false, aind)  => begin
        File.write(file, str)
        (nchars + stringLength(str), false, aind)
      end

      (ST_LINE(line = str), nchars, true, aind)  => begin
        File.writeSpace(file, nchars)
        File.write(file, str)
        (aind, true, aind)
      end

      (ST_LINE(line = str), _, false, aind)  => begin
        File.write(file, str)
        (aind, true, aind)
      end

      (ST_STRING_LIST(strList = strLst), nchars, isstart, aind)  => begin
        (nchars, isstart, aind) = stringListFile(file, strLst, nchars, isstart, aind)
        (nchars, isstart, aind)
      end

      (ST_BLOCK(tokens = toks, blockType = bt), nchars, isstart, aind)  => begin
        (nchars, isstart, aind) = blockFile(file, bt, listReverse(toks), nchars, isstart, aind)
        (nchars, isstart, aind)
      end
    end
  end
  (aind, isstart, nchars)
end

function stringListString(inStringList::Lst, inActualPositionOnLine::ModelicaInteger, inAtStartOfLine::Bool, inAfterNewLineIndent::ModelicaInteger)::Tuple{ModelicaInteger, Bool, ModelicaInteger}
  local outAfterNewLineIndent::ModelicaInteger
  local outAtStartOfLine::Bool
  local outActualPositionOnLine::ModelicaInteger

  (outActualPositionOnLine, outAtStartOfLine, outAfterNewLineIndent) = begin
    local str::String
    local strLst::Lst
    local nchars::ModelicaInteger
    local aind::ModelicaInteger
    local blen::ModelicaInteger
    local isstart::Bool
    local hasNL::Bool
    @match (inStringList, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent) begin
      ( nil(), _, isstart, aind)  => begin
        (aind, isstart, aind)
      end

      ("" <| strLst, nchars, isstart, aind)  => begin
        (nchars, isstart, aind) = stringListString(strLst, nchars, isstart, aind)
        (nchars, isstart, aind)
      end

      (str <| strLst, nchars, true, aind)  => begin
        blen = Print.getBufLength()
        Print.printBufSpace(nchars)
        Print.printBuf(str)
        blen = Print.getBufLength() - blen
        hasNL = Print.hasBufNewLineAtEnd()
        nchars = if hasNL
          aind
        else
          blen
        end
        (nchars, isstart, aind) = stringListString(strLst, nchars, hasNL, aind)
        (nchars, isstart, aind)
      end

      (str <| strLst, nchars, false, aind)  => begin
        blen = Print.getBufLength()
        Print.printBuf(str)
        blen = Print.getBufLength() - blen
        hasNL = Print.hasBufNewLineAtEnd()
        nchars = if hasNL
          aind
        else
          nchars + blen
        end
        (nchars, isstart, aind) = stringListString(strLst, nchars, hasNL, aind)
        (nchars, isstart, aind)
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.stringListString failed.\n")
        fail()
      end
    end
  end
  #= empty string ... for sure -> it can be a special case when allowed; when let for the case at start of a line, it would output an indent
  =#
  #= at start, new line or no new line
  =#
  #= indent is actually stored in nchars when on start of the line
  =#
  #= not at start, new line or no new line
  =#
  #= should not ever happen
  =#
  (outAfterNewLineIndent, outAtStartOfLine, outActualPositionOnLine)
end

function stringListFile(file::File.FILE, inStringList::Lst, nchars::ModelicaInteger, isstart::Bool, aind::ModelicaInteger)::Tuple{ModelicaInteger, Bool, ModelicaInteger}




  (nchars, isstart, aind) = begin
    local str::String
    local strLst::Lst
    local hasNL::Bool
    @match (inStringList, nchars, isstart, aind) begin
      ( nil(), _, isstart, aind)  => begin
        (aind, isstart, aind)
      end

      ("" <| strLst, nchars, isstart, aind)  => begin
        (nchars, isstart, aind) = stringListFile(file, strLst, nchars, isstart, aind)
        (nchars, isstart, aind)
      end

      (str <| strLst, nchars, true, aind)  => begin
        File.writeSpace(file, nchars)
        File.write(file, str)
        hasNL = StringUtil.endsWithNewline(str)
        nchars = if hasNL
          aind
        else
          nchars + stringLength(str)
        end
        (nchars, isstart, aind) = stringListFile(file, strLst, nchars, hasNL, aind)
        (nchars, isstart, aind)
      end

      (str <| strLst, nchars, false, aind)  => begin
        File.write(file, str)
        hasNL = StringUtil.endsWithNewline(str)
        nchars = if hasNL
          aind
        else
          nchars + stringLength(str)
        end
        (nchars, isstart, aind) = stringListFile(file, strLst, nchars, hasNL, aind)
        (nchars, isstart, aind)
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.stringListFile failed.\n")
        fail()
      end
    end
  end
  #= empty string ... for sure -> it can be a special case when allowed; when let for the case at start of a line, it would output an indent
  =#
  #= at start, new line or no new line
  =#
  #= not at start, new line or no new line
  =#
  #= should not ever happen
  =#
  (aind, isstart, nchars)
end

function blockString(inBlockType::BlockType, inTokens::Tokens, inActualPositionOnLine::ModelicaInteger, inAtStartOfLine::Bool, inAfterNewLineIndent::ModelicaInteger)::Tuple{ModelicaInteger, Bool, ModelicaInteger}
  local outAfterNewLineIndent::ModelicaInteger
  local outAtStartOfLine::Bool
  local outActualPositionOnLine::ModelicaInteger

  (outActualPositionOnLine, outAtStartOfLine, outAfterNewLineIndent) = begin
    local toks::Tokens
    local septok::StringToken
    local tok::StringToken
    local asep::StringToken
    local wsep::StringToken
    local nchars::ModelicaInteger
    local tsnchars::ModelicaInteger
    local aind::ModelicaInteger
    local w::ModelicaInteger
    local aoffset::ModelicaInteger
    local anum::ModelicaInteger
    local wwidth::ModelicaInteger
    local blen::ModelicaInteger
    local isstart::Bool
    @match (inBlockType, inTokens, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent) begin
      (BT_TEXT(), toks, nchars, isstart, aind)  => begin
        (nchars, isstart, aind) = tokensString(toks, nchars, isstart, aind)
        (nchars, isstart, aind)
      end

      (BT_INDENT(width = w), toks, nchars, true, aind)  => begin
        (tsnchars, isstart) = tokensString(toks, w + nchars, true, w + aind)
        nchars = if isstart
          nchars
        else
          tsnchars
        end
        (nchars, isstart, aind)
      end

      (BT_INDENT(width = w), toks, nchars, false, aind)  => begin
        Print.printBufSpace(w)
        (tsnchars, isstart) = tokensString(toks, w + nchars, false, w + aind)
        nchars = if isstart
          aind
        else
          tsnchars
        end
        (nchars, isstart, aind)
      end

      (BT_ABS_INDENT(width = w), toks, nchars, true, aind)  => begin
        blen = Print.getBufLength()
        (tsnchars, isstart) = tokensString(toks, 0, true, w)
        blen = Print.getBufLength() - blen
        nchars = if blen == 0
          nchars
        else
          if isstart
            aind
          else
            tsnchars
          end
        end
        (nchars, isstart, aind)
      end

      (BT_ABS_INDENT(width = w), toks, nchars, false, aind)  => begin
        (tsnchars, isstart) = tokensString(toks, nchars, false, w)
        nchars = if isstart
          aind
        else
          tsnchars
        end
        (nchars, isstart, aind)
      end

      (BT_REL_INDENT(offset = w), toks, nchars, true, aind)  => begin
        blen = Print.getBufLength()
        (tsnchars, isstart) = tokensString(toks, nchars, true, aind + w)
        blen = Print.getBufLength() - blen
        nchars = if blen == 0
          nchars
        else
          if isstart
            aind
          else
            tsnchars
          end
        end
        (nchars, isstart, aind)
      end

      (BT_REL_INDENT(offset = w), toks, nchars, false, aind)  => begin
        (tsnchars, isstart) = tokensString(toks, nchars, false, aind + w)
        nchars = if isstart
          aind
        else
          tsnchars
        end
        (nchars, isstart, aind)
      end

      (BT_ANCHOR(offset = w), toks, nchars, true, aind)  => begin
        blen = Print.getBufLength()
        (tsnchars, isstart) = tokensString(toks, nchars, true, nchars + w)
        blen = Print.getBufLength() - blen
        nchars = if blen == 0
          nchars
        else
          if isstart
            aind
          else
            tsnchars
          end
        end
        (nchars, isstart, aind)
      end

      (BT_ANCHOR(offset = w), toks, nchars, false, aind)  => begin
        (tsnchars, isstart) = tokensString(toks, nchars, false, nchars + w)
        nchars = if isstart
          aind
        else
          tsnchars
        end
        (nchars, isstart, aind)
      end

      (BT_ITER(),  nil(), nchars, isstart, aind)  => begin
        (nchars, isstart, aind)
      end

      (BT_ITER(options = ITER_OPTIONS(separator = NONE(), alignNum = 0, wrapWidth = 0)), toks, nchars, isstart, aind)  => begin
        (nchars, isstart, aind) = tokensString(toks, nchars, isstart, aind)
        (nchars, isstart, aind)
      end

      (BT_ITER(options = ITER_OPTIONS(separator = SOME(septok), alignNum = 0, wrapWidth = 0)), tok <| toks, nchars, isstart, aind)  => begin
        (nchars, isstart, aind) = tokString(tok, nchars, isstart, aind)
        (nchars, isstart) = iterSeparatorString(toks, septok, nchars, isstart, aind)
        (nchars, isstart, aind)
      end

      (BT_ITER(options = ITER_OPTIONS(separator = SOME(septok), alignNum = anum, alignOfset = aoffset, alignSeparator = asep, wrapWidth = wwidth, wrapSeparator = wsep)), tok <| toks, nchars, isstart, aind)  => begin
        (nchars, isstart, aind) = tokString(tok, nchars, isstart, aind)
        (nchars, isstart) = iterSeparatorAlignWrapString(toks, septok, 1 + aoffset, anum, asep, wwidth, wsep, nchars, isstart, aind)
        (nchars, isstart, aind)
      end

      (BT_ITER(options = ITER_OPTIONS(separator = NONE(), alignNum = anum, alignOfset = aoffset, alignSeparator = asep, wrapWidth = wwidth, wrapSeparator = wsep)), toks, nchars, isstart, aind)  => begin
        (nchars, isstart) = iterAlignWrapString(toks, aoffset, anum, asep, wwidth, wsep, nchars, isstart, aind)
        (nchars, isstart, aind)
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.tokString failed.\n")
        fail()
      end
    end
end
#= pop indent when at the start of a line
=#
#= pop indent when at the start of a line - there were a new line, so use the aind
=#
#= discard an indent when at the start of a line
=#
#= when no chars -> pop indent; when something written -> aind for the start of a line otherwise actual position
=#
#= pop indent when at the start of a line - there were a new line, so use the aind
=#
#= when no chars -> pop indent; when something written -> aind for the start of a line otherwise actual position
=#
#= pop indent when at the start of a line - there were a new line, so use the aind
=#
#= when no chars -> pop indent; when something written -> aind for the start of a line otherwise actual position
=#
#= pop indent when at the start of a line - there were a new line, so use the aind
=#
#= iter block, no tokens ... should be impossible, but ...
=#
#= concat ... i.e. text
=#
#= separator only ...
=#
#=  put the first token, all the others with separator
=#
#= separator and alignment and/or wrapping
=#
#=  put the first token, all the others with separator
=#
#= no separator and alignment and/or wrapping
=#
#= should not ever happen
=#
(outAfterNewLineIndent, outAtStartOfLine, outActualPositionOnLine)
end

function iterSeparatorString(inTokens::Tokens, inSeparator::StringToken, inActualPositionOnLine::ModelicaInteger, inAtStartOfLine::Bool, inAfterNewLineIndent::ModelicaInteger)::Tuple{Bool, ModelicaInteger}
  local outAtStartOfLine::Bool
  local outActualPositionOnLine::ModelicaInteger

  (outActualPositionOnLine, outAtStartOfLine) = begin
    local toks::Tokens
    local tok::StringToken
    local septok::StringToken
    local pos::ModelicaInteger
    local aind::ModelicaInteger
    local isstart::Bool
    @match (inTokens, inSeparator, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent) begin
      ( nil(), _, pos, isstart, _)  => begin
        (pos, isstart)
      end

      (tok <| toks, septok, pos, isstart, aind)  => begin
        (pos, isstart, aind) = tokString(septok, pos, isstart, aind)
        (pos, isstart, aind) = tokString(tok, pos, isstart, aind)
        (pos, isstart) = iterSeparatorString(toks, septok, pos, isstart, aind)
        (pos, isstart)
      end
    end
  end
  (outAtStartOfLine, outActualPositionOnLine)
end

function iterSeparatorAlignWrapString(inTokens::Tokens, inSeparator::StringToken, inActualIndex::ModelicaInteger, inAlignNum::ModelicaInteger, inAlignSeparator::StringToken, inWrapWidth::ModelicaInteger, inWrapSeparator::StringToken, inActualPositionOnLine::ModelicaInteger, inAtStartOfLine::Bool, inAfterNewLineIndent::ModelicaInteger)::Tuple{Bool, ModelicaInteger}
  local outAtStartOfLine::Bool
  local outActualPositionOnLine::ModelicaInteger

  local toks::Tokens = inTokens
  local tok::StringToken
  local septok::StringToken = inSeparator
  local idx::ModelicaInteger = inActualIndex
  local anum::ModelicaInteger = inAlignNum
  local asep::StringToken = inAlignSeparator
  local wwidth::ModelicaInteger = inWrapWidth
  local wsep::StringToken = inWrapSeparator
  local pos::ModelicaInteger = inActualPositionOnLine
  local isstart::Bool = inAtStartOfLine
  local aind::ModelicaInteger = inAfterNewLineIndent

  while boolNot(listEmpty(toks))
    tok, toks = listHead(toks), listRest(toks)
    if idx > 0 && intMod(idx, anum) == 0
      (pos, isstart, aind) = tokString(asep, pos, isstart, aind)
    else
      (pos, isstart, aind) = tokString(septok, pos, isstart, aind)
    end
    (pos, isstart, aind) = tryWrapString(wwidth, wsep, pos, isstart, aind)
    (pos, isstart, aind) = tokString(tok, pos, isstart, aind)
    idx = idx + 1
  end
  (outActualPositionOnLine, outAtStartOfLine) = (pos, isstart)
  (outAtStartOfLine, outActualPositionOnLine)
end

function iterAlignWrapString(inTokens::Tokens, inActualIndex::ModelicaInteger, inAlignNum::ModelicaInteger, inAlignSeparator::StringToken, inWrapWidth::ModelicaInteger, inWrapSeparator::StringToken, inActualPositionOnLine::ModelicaInteger, inAtStartOfLine::Bool, inAfterNewLineIndent::ModelicaInteger)::Tuple{Bool, ModelicaInteger}
  local outAtStartOfLine::Bool
  local outActualPositionOnLine::ModelicaInteger

  (outActualPositionOnLine, outAtStartOfLine) = begin
    local toks::Tokens
    local tok::StringToken
    local asep::StringToken
    local wsep::StringToken
    local pos::ModelicaInteger
    local aind::ModelicaInteger
    local idx::ModelicaInteger
    local anum::ModelicaInteger
    local wwidth::ModelicaInteger
    local isstart::Bool
    @match (inTokens, inActualIndex, inAlignNum, inAlignSeparator, inWrapWidth, inWrapSeparator, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent) begin
      ( nil(), _, _, _, _, _, pos, isstart, _)  => begin
        (pos, isstart)
      end

      (tok <| toks, idx, anum, asep, wwidth, wsep, pos, isstart, aind) where (idx > 0 && intMod(idx, anum)) == 0  => begin
        (pos, isstart, aind) = tokString(asep, pos, isstart, aind)
        (pos, isstart, aind) = tryWrapString(wwidth, wsep, pos, isstart, aind)
        (pos, isstart, aind) = tokString(tok, pos, isstart, aind)
        (pos, isstart) = iterAlignWrapString(toks, idx + 1, anum, asep, wwidth, wsep, pos, isstart, aind)
        (pos, isstart)
      end

      (tok <| toks, idx, anum, asep, wwidth, wsep, pos, isstart, aind) where (wwidth > 0 && pos >= wwidth)  => begin
        (pos, isstart, aind) = tokString(wsep, pos, isstart, aind)
        (pos, isstart, aind) = tokString(tok, pos, isstart, aind)
        (pos, isstart) = iterAlignWrapString(toks, idx + 1, anum, asep, wwidth, wsep, pos, isstart, aind)
        (pos, isstart)
      end

      (tok <| toks, idx, anum, asep, wwidth, wsep, pos, isstart, aind)  => begin
        (pos, isstart, aind) = tokString(tok, pos, isstart, aind)
        (pos, isstart) = iterAlignWrapString(toks, idx + 1, anum, asep, wwidth, wsep, pos, isstart, aind)
        (pos, isstart)
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.iterAlignWrapString failed.\n")
        fail()
      end
    end
  end
  #= align and try wrap
  =#
  #= wrap
  =#
  #= false = (idx > 0) and (intMod(idx,anum) == 0);
  =#
  #= check wwidth for the invariant that should be always true here
  =#
  #= item only
  =#
  #= false = (idx > 0) and (intMod(idx,anum) == 0);
  =#
  #= false = (wwidth > 0) and (pos >= wwidth); check wwidth for the invariant that should be always true here
  =#
  #= should not ever happen
  =#
  (outAtStartOfLine, outActualPositionOnLine)
end

function tryWrapString(inWrapWidth::ModelicaInteger, inWrapSeparator::StringToken, inActualPositionOnLine::ModelicaInteger, inAtStartOfLine::Bool, inAfterNewLineIndent::ModelicaInteger)::Tuple{ModelicaInteger, Bool, ModelicaInteger}
  local outAfterNewLineIndent::ModelicaInteger
  local outAtStartOfLine::Bool
  local outActualPositionOnLine::ModelicaInteger

  (outActualPositionOnLine, outAtStartOfLine, outAfterNewLineIndent) = begin
    local pos::ModelicaInteger
    local aind::ModelicaInteger
    local wwidth::ModelicaInteger
    local isstart::Bool
    local wsep::StringToken
    #= wrap
    =#
    @match (inWrapWidth, inWrapSeparator, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent) begin
      (wwidth, wsep, pos, isstart, aind) where (wwidth > 0 && pos >= wwidth)  => begin
        tokString(wsep, pos, isstart, aind)
      end

      _  => begin
        (inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
      end
    end
  end
  #= check wwidth for the invariant that should be always true here
  =#
  (outAfterNewLineIndent, outAtStartOfLine, outActualPositionOnLine)
end

function blockFile(file::File.FILE, inBlockType::BlockType, inTokens::Tokens, inActualPositionOnLine::ModelicaInteger, inAtStartOfLine::Bool, inAfterNewLineIndent::ModelicaInteger)::Tuple{ModelicaInteger, Bool, ModelicaInteger}
  local outAfterNewLineIndent::ModelicaInteger
  local outAtStartOfLine::Bool
  local outActualPositionOnLine::ModelicaInteger

  (outActualPositionOnLine, outAtStartOfLine, outAfterNewLineIndent) = begin
    local toks::Tokens
    local septok::StringToken
    local tok::StringToken
    local asep::StringToken
    local wsep::StringToken
    local nchars::ModelicaInteger
    local tsnchars::ModelicaInteger
    local aind::ModelicaInteger
    local w::ModelicaInteger
    local aoffset::ModelicaInteger
    local anum::ModelicaInteger
    local wwidth::ModelicaInteger
    local blen::ModelicaInteger
    local isstart::Bool
    @match (inBlockType, inTokens, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent) begin
      (BT_TEXT(), toks, nchars, isstart, aind)  => begin
        (nchars, isstart, aind) = tokensFile(file, toks, nchars, isstart, aind)
        (nchars, isstart, aind)
      end

      (BT_INDENT(width = w), toks, nchars, true, aind)  => begin
        (tsnchars, isstart) = tokensFile(file, toks, w + nchars, true, w + aind)
        nchars = if isstart
          nchars
        else
          tsnchars
        end
        (nchars, isstart, aind)
      end

      (BT_INDENT(width = w), toks, nchars, false, aind)  => begin
        File.writeSpace(file, w)
        (tsnchars, isstart) = tokensFile(file, toks, w + nchars, false, w + aind)
        nchars = if isstart
          aind
        else
          tsnchars
        end
        (nchars, isstart, aind)
      end

      (BT_ABS_INDENT(width = w), toks, nchars, true, aind)  => begin
        blen = File.tell(file)
        (tsnchars, isstart) = tokensFile(file, toks, 0, true, w)
        blen = File.tell(file) - blen
        nchars = if blen == 0
          nchars
        else
          if isstart
            aind
          else
            tsnchars
          end
        end
        (nchars, isstart, aind)
      end

      (BT_ABS_INDENT(width = w), toks, nchars, false, aind)  => begin
        (tsnchars, isstart) = tokensFile(file, toks, nchars, false, w)
        nchars = if isstart
          aind
        else
          tsnchars
        end
        (nchars, isstart, aind)
      end

      (BT_REL_INDENT(offset = w), toks, nchars, true, aind)  => begin
        blen = File.tell(file)
        (tsnchars, isstart) = tokensFile(file, toks, nchars, true, aind + w)
        blen = File.tell(file) - blen
        nchars = if blen == 0
          nchars
        else
          if isstart
            aind
          else
            tsnchars
          end
        end
        (nchars, isstart, aind)
      end

      (BT_REL_INDENT(offset = w), toks, nchars, false, aind)  => begin
        (tsnchars, isstart) = tokensFile(file, toks, nchars, false, aind + w)
        nchars = if isstart
          aind
        else
          tsnchars
        end
        (nchars, isstart, aind)
      end

      (BT_ANCHOR(offset = w), toks, nchars, true, aind)  => begin
        blen = File.tell(file)
        (tsnchars, isstart) = tokensFile(file, toks, nchars, true, nchars + w)
        blen = File.tell(file) - blen
        nchars = if blen == 0
          nchars
        else
          if isstart
            aind
          else
            tsnchars
          end
        end
        (nchars, isstart, aind)
      end

      (BT_ANCHOR(offset = w), toks, nchars, false, aind)  => begin
        (tsnchars, isstart) = tokensFile(file, toks, nchars, false, nchars + w)
        nchars = if isstart
          aind
        else
          tsnchars
        end
        (nchars, isstart, aind)
      end

      (BT_ITER(),  nil(), nchars, isstart, aind)  => begin
        (nchars, isstart, aind)
      end

      (BT_ITER(options = ITER_OPTIONS(separator = NONE(), alignNum = 0, wrapWidth = 0)), toks, nchars, isstart, aind)  => begin
        (nchars, isstart, aind) = tokensFile(file, toks, nchars, isstart, aind)
        (nchars, isstart, aind)
      end

      (BT_ITER(options = ITER_OPTIONS(separator = SOME(septok), alignNum = 0, wrapWidth = 0)), tok <| toks, nchars, isstart, aind)  => begin
        (nchars, isstart, aind) = tokFile(file, tok, nchars, isstart, aind)
        (nchars, isstart) = iterSeparatorFile(file, toks, septok, nchars, isstart, aind)
        (nchars, isstart, aind)
      end

      (BT_ITER(options = ITER_OPTIONS(separator = SOME(septok), alignNum = anum, alignOfset = aoffset, alignSeparator = asep, wrapWidth = wwidth, wrapSeparator = wsep)), tok <| toks, nchars, isstart, aind)  => begin
        (nchars, isstart, aind) = tokFile(file, tok, nchars, isstart, aind)
        (nchars, isstart) = iterSeparatorAlignWrapFile(file, toks, septok, 1 + aoffset, anum, asep, wwidth, wsep, nchars, isstart, aind)
        (nchars, isstart, aind)
      end

      (BT_ITER(options = ITER_OPTIONS(separator = NONE(), alignNum = anum, alignOfset = aoffset, alignSeparator = asep, wrapWidth = wwidth, wrapSeparator = wsep)), toks, nchars, isstart, aind)  => begin
        (nchars, isstart) = iterAlignWrapFile(file, toks, aoffset, anum, asep, wwidth, wsep, nchars, isstart, aind)
        (nchars, isstart, aind)
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.tokString failed.\n")
        fail()
      end
    end
end
#= pop indent when at the start of a line
=#
#= pop indent when at the start of a line - there were a new line, so use the aind
=#
#= discard an indent when at the start of a line
=#
#= when no chars -> pop indent; when something written -> aind for the start of a line otherwise actual position
=#
#= pop indent when at the start of a line - there were a new line, so use the aind
=#
#= when no chars -> pop indent; when something written -> aind for the start of a line otherwise actual position
=#
#= pop indent when at the start of a line - there were a new line, so use the aind
=#
#= when no chars -> pop indent; when something written -> aind for the start of a line otherwise actual position
=#
#= pop indent when at the start of a line - there were a new line, so use the aind
=#
#= iter block, no tokens ... should be impossible, but ...
=#
#= concat ... i.e. text
=#
#= separator only ...
=#
#=  put the first token, all the others with separator
=#
#= separator and alignment and/or wrapping
=#
#=  put the first token, all the others with separator
=#
#= no separator and alignment and/or wrapping
=#
#= should not ever happen
=#
(outAfterNewLineIndent, outAtStartOfLine, outActualPositionOnLine)
end

function iterSeparatorFile(file::File.FILE, inTokens::Tokens, inSeparator::StringToken, inActualPositionOnLine::ModelicaInteger, inAtStartOfLine::Bool, inAfterNewLineIndent::ModelicaInteger)::Tuple{Bool, ModelicaInteger}
  local outAtStartOfLine::Bool
  local outActualPositionOnLine::ModelicaInteger

  (outActualPositionOnLine, outAtStartOfLine) = begin
    local toks::Tokens
    local tok::StringToken
    local septok::StringToken
    local pos::ModelicaInteger
    local aind::ModelicaInteger
    local isstart::Bool
    @match (inTokens, inSeparator, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent) begin
      ( nil(), _, pos, isstart, _)  => begin
        (pos, isstart)
      end

      (tok <| toks, septok, pos, isstart, aind)  => begin
        (pos, isstart, aind) = tokFile(file, septok, pos, isstart, aind)
        (pos, isstart, aind) = tokFile(file, tok, pos, isstart, aind)
        (pos, isstart) = iterSeparatorFile(file, toks, septok, pos, isstart, aind)
        (pos, isstart)
      end
    end
  end
  (outAtStartOfLine, outActualPositionOnLine)
end

function iterSeparatorAlignWrapFile(file::File.FILE, inTokens::Tokens, inSeparator::StringToken, inActualIndex::ModelicaInteger, inAlignNum::ModelicaInteger, inAlignSeparator::StringToken, inWrapWidth::ModelicaInteger, inWrapSeparator::StringToken, inActualPositionOnLine::ModelicaInteger, inAtStartOfLine::Bool, inAfterNewLineIndent::ModelicaInteger)::Tuple{Bool, ModelicaInteger}
  local outAtStartOfLine::Bool
  local outActualPositionOnLine::ModelicaInteger

  local toks::Tokens = inTokens
  local tok::StringToken
  local septok::StringToken = inSeparator
  local idx::ModelicaInteger = inActualIndex
  local anum::ModelicaInteger = inAlignNum
  local asep::StringToken = inAlignSeparator
  local wwidth::ModelicaInteger = inWrapWidth
  local wsep::StringToken = inWrapSeparator
  local pos::ModelicaInteger = inActualPositionOnLine
  local isstart::Bool = inAtStartOfLine
  local aind::ModelicaInteger = inAfterNewLineIndent

  while boolNot(listEmpty(toks))
    tok, toks = listHead(toks), listRest(toks)
    if idx > 0 && intMod(idx, anum) == 0
      (pos, isstart, aind) = tokFile(file, asep, pos, isstart, aind)
    else
      (pos, isstart, aind) = tokFile(file, septok, pos, isstart, aind)
    end
    (pos, isstart, aind) = tryWrapFile(file, wwidth, wsep, pos, isstart, aind)
    (pos, isstart, aind) = tokFile(file, tok, pos, isstart, aind)
    idx = idx + 1
  end
  (outActualPositionOnLine, outAtStartOfLine) = (pos, isstart)
  (outAtStartOfLine, outActualPositionOnLine)
end

function iterAlignWrapFile(file::File.FILE, inTokens::Tokens, inActualIndex::ModelicaInteger, inAlignNum::ModelicaInteger, inAlignSeparator::StringToken, inWrapWidth::ModelicaInteger, inWrapSeparator::StringToken, inActualPositionOnLine::ModelicaInteger, inAtStartOfLine::Bool, inAfterNewLineIndent::ModelicaInteger)::Tuple{Bool, ModelicaInteger}
  local outAtStartOfLine::Bool
  local outActualPositionOnLine::ModelicaInteger

  (outActualPositionOnLine, outAtStartOfLine) = begin
    local toks::Tokens
    local tok::StringToken
    local asep::StringToken
    local wsep::StringToken
    local pos::ModelicaInteger
    local aind::ModelicaInteger
    local idx::ModelicaInteger
    local anum::ModelicaInteger
    local wwidth::ModelicaInteger
    local isstart::Bool
    @match (inTokens, inActualIndex, inAlignNum, inAlignSeparator, inWrapWidth, inWrapSeparator, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent) begin
      ( nil(), _, _, _, _, _, pos, isstart, _)  => begin
        (pos, isstart)
      end

      (tok <| toks, idx, anum, asep, wwidth, wsep, pos, isstart, aind) where (idx > 0 && intMod(idx, anum) == 0)  => begin
        (pos, isstart, aind) = tokFile(file, asep, pos, isstart, aind)
        (pos, isstart, aind) = tryWrapFile(file, wwidth, wsep, pos, isstart, aind)
        (pos, isstart, aind) = tokFile(file, tok, pos, isstart, aind)
        (pos, isstart) = iterAlignWrapFile(file, toks, idx + 1, anum, asep, wwidth, wsep, pos, isstart, aind)
        (pos, isstart)
      end

      (tok <| toks, idx, anum, asep, wwidth, wsep, pos, isstart, aind) where (wwidth > 0 && pos >= wwidth)  => begin
        (pos, isstart, aind) = tokFile(file, wsep, pos, isstart, aind)
        (pos, isstart, aind) = tokFile(file, tok, pos, isstart, aind)
        (pos, isstart) = iterAlignWrapFile(file, toks, idx + 1, anum, asep, wwidth, wsep, pos, isstart, aind)
        (pos, isstart)
      end

      (tok <| toks, idx, anum, asep, wwidth, wsep, pos, isstart, aind)  => begin
        (pos, isstart, aind) = tokFile(file, tok, pos, isstart, aind)
        (pos, isstart) = iterAlignWrapFile(file, toks, idx + 1, anum, asep, wwidth, wsep, pos, isstart, aind)
        (pos, isstart)
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.iterAlignWrapString failed.\n")
        fail()
      end
    end
  end
  #= align and try wrap
  =#
  #= wrap
  =#
  #= false = (idx > 0) and (intMod(idx,anum) == 0);
  =#
  #= check wwidth for the invariant that should be always true here
  =#
  #= item only
  =#
  #= false = (idx > 0) and (intMod(idx,anum) == 0);
  =#
  #= false = (wwidth > 0) and (pos >= wwidth); check wwidth for the invariant that should be always true here
  =#
  #= should not ever happen
  =#
  (outAtStartOfLine, outActualPositionOnLine)
end

function tryWrapFile(file::File.FILE, inWrapWidth::ModelicaInteger, inWrapSeparator::StringToken, inActualPositionOnLine::ModelicaInteger, inAtStartOfLine::Bool, inAfterNewLineIndent::ModelicaInteger)::Tuple{ModelicaInteger, Bool, ModelicaInteger}
  local outAfterNewLineIndent::ModelicaInteger
  local outAtStartOfLine::Bool
  local outActualPositionOnLine::ModelicaInteger

  (outActualPositionOnLine, outAtStartOfLine, outAfterNewLineIndent) = begin
    local pos::ModelicaInteger
    local aind::ModelicaInteger
    local wwidth::ModelicaInteger
    local isstart::Bool
    local wsep::StringToken
    #= wrap
    =#
    @match (inWrapWidth, inWrapSeparator, inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent) begin
      (wwidth, wsep, pos, isstart, aind) where (wwidth > 0 && pos >= wwidth)  => begin
        tokFile(file, wsep, pos, isstart, aind)
      end

      _  => begin
        (inActualPositionOnLine, inAtStartOfLine, inAfterNewLineIndent)
      end
    end
  end
  #= check wwidth for the invariant that should be always true here
  =#
  (outAfterNewLineIndent, outAtStartOfLine, outActualPositionOnLine)
end

function strTokText(inStringToken::StringToken)::Text
  local outText::Text

  outText = MEM_TEXT(list(inStringToken), list())
  outText
end

function textStrTok(inText::Text)::StringToken
  local outStringToken::StringToken

  outStringToken = begin
    local toks::Tokens
    local txttoks::Tokens
    @match inText begin
      MEM_TEXT(tokens =  nil())  => begin
        ST_STRING("")
      end

      MEM_TEXT(tokens = txttoks, blocksStack =  nil())  => begin
        ST_BLOCK(txttoks, BT_TEXT())
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.textStrTok failed - incomplete text was passed to be converted.\n")
        fail()
      end
    end
  end
  #= should not ever happen
  =#
  #= - when compilation is correct, this is impossible (only completed texts can be accessible to write out)
  =#
  outStringToken
end

function stringText(inString::String)::Text
  local outText::Text

  outText = MEM_TEXT(list(ST_STRING(inString)), list())
  outText
end

function strTokString(inStringToken::StringToken)::String
  local outString::String

  outString = textString(MEM_TEXT(list(inStringToken), list()))
  outString
end

function failIfTrue(istrue::Bool)
  if istrue
    fail()
  end
end

function tplCallHandleErrors(inFun::Tpl_Fun, txt::Text)::Text


  local nErr::ModelicaInteger

  nErr = Error.getNumErrorMessages()
  try
    try
      txt = inFun(txt)
    catch
      addTemplateErrorFunc(inFun)
      fail()
    end
  catch
    if StackOverflow.hasStacktraceMessages()
      Error.addInternalError("Stack overflow when evaluating function:\n" + stringDelimitList(StackOverflow.readableStacktraceMessages(), "\n"), sourceInfo())
    end
    addTemplateErrorFunc(inFun)
    fail()
  end #= annotation(
  __OpenModelica_stackOverflowCheckpoint = true) =#
  txt
end

function tplCallWithFailErrorNoArg(inFun::Tpl_Fun, txt::Text)::Text


  txt = tplCallHandleErrors(inFun, txt)
  txt
end

function tplCallWithFailError(inFun::Tpl_Fun, inArg::ArgType1, txt::Text)::Text
  txt
end

function tplCallWithFailError2(inFun::Tpl_Fun, inArgA::ArgType1, inArgB::ArgType2, txt::Text)::Text
  txt
end

function tplCallWithFailError3(inFun::Tpl_Fun, inArgA::ArgType1, inArgB::ArgType2, inArgC::ArgType3, txt::Text)::Text
  txt
end

function tplString(inFun::Tpl_Fun, inArg::ArgType1)::String
  local outString::String

  local txt::Text
  local nErr::ModelicaInteger

  nErr = Error.getNumErrorMessages()
  txt = tplCallWithFailError(inFun, inArg)
  failIfTrue(Error.getNumErrorMessages() > nErr)
  outString = textString(txt)
  outString
end

function tplString2(inFun::Tpl_Fun, inArgA::ArgType1, inArgB::ArgType2)::String
  local outString::String

  local txt::Text
  local nErr::ModelicaInteger

  nErr = Error.getNumErrorMessages()
  txt = tplCallWithFailError2(inFun, inArgA, inArgB)
  failIfTrue(Error.getNumErrorMessages() > nErr)
  outString = textString(txt)
  outString
end

function tplString3(inFun::Tpl_Fun, inArgA::ArgType1, inArgB::ArgType2, inArgC::ArgType3)::String
  local outString::String

  local txt::Text
  local nErr::ModelicaInteger

  nErr = Error.getNumErrorMessages()
  txt = tplCallWithFailError3(inFun, inArgA, inArgB, inArgC)
  failIfTrue(Error.getNumErrorMessages() > nErr)
  outString = textString(txt)
  outString
end

function tplPrint(inFun::Tpl_Fun, inArg::ArgType1)
  local txt::Text
  local nErr::ModelicaInteger

  nErr = Error.getNumErrorMessages()
  txt = tplCallWithFailError(inFun, inArg)
  failIfTrue(Error.getNumErrorMessages() > nErr)
  textStringBuf(txt)
end

function tplPrint2(inFun::Tpl_Fun, inArgA::ArgType1, inArgB::ArgType2)
  local txt::Text
  local nErr::ModelicaInteger

  nErr = Error.getNumErrorMessages()
  txt = tplCallWithFailError2(inFun, inArgA, inArgB)
  failIfTrue(Error.getNumErrorMessages() > nErr)
  textStringBuf(txt)
end

function tplPrint3(inFun::Tpl_Fun, inArgA::ArgType1, inArgB::ArgType2, inArgC::ArgType3)
  local txt::Text
  local nErr::ModelicaInteger

  nErr = Error.getNumErrorMessages()
  txt = tplCallWithFailError3(inFun, inArgA, inArgB, inArgC)
  failIfTrue(Error.getNumErrorMessages() > nErr)
  textStringBuf(txt)
end

function tplNoret3(inFun::Tpl_Fun, inArg::ArgType1, inArg2::ArgType2, inArg3::ArgType3)
  local nErr::ModelicaInteger

  nErr = Error.getNumErrorMessages()
  _ = tplCallWithFailError3(inFun, inArg, inArg2, inArg3)
  failIfTrue(Error.getNumErrorMessages() > nErr)
end

function tplNoret2(inFun::Tpl_Fun, inArg::ArgType1, inArg2::ArgType2)
  local nErr::ModelicaInteger

  nErr = Error.getNumErrorMessages()
  _ = tplCallWithFailError2(inFun, inArg, inArg2)
  failIfTrue(Error.getNumErrorMessages() > nErr)
end

function tplNoret(inFun::Tpl_Fun, inArg::ArgType1)
  local nErr::ModelicaInteger

  nErr = Error.getNumErrorMessages()
  _ = tplCallWithFailError(inFun, inArg)
  failIfTrue(Error.getNumErrorMessages() > nErr)
end

#= function: textFile:
This function renders a (memory-)text to a file. =#
function textFile(inText::Text, inFileName::String)
  _ = begin
    local txt::Text
    local file::String
    local rtTickTxt::ModelicaReal
    local rtTickW::ModelicaReal
    @matchcontinue (inText, inFileName) begin
      (txt, file)  => begin
        rtTickTxt = System.realtimeTock(ClockIndexes.RT_CLOCK_BUILD_MODEL)
        Print.clearBuf()
        textStringBuf(txt)
        rtTickW = System.realtimeTock(ClockIndexes.RT_CLOCK_BUILD_MODEL)
        Print.writeBuf(file)
        if Config.getRunningTestsuite()
          System.appendFile(Config.getRunningTestsuiteFile(), file + "\n")
        end
        Print.clearBuf()
        if Flags.isSet(Flags.TPL_PERF_TIMES)
          Debug.trace("textFile " + file + "\n    text:" + realString(realSub(rtTickW, rtTickTxt)) + "\n   write:" + realString(realSub(System.realtimeTock(ClockIndexes.RT_CLOCK_BUILD_MODEL), rtTickW)))
        end
        ()
      end

      _  => begin
        if Flags.isSet(Flags.FAILTRACE)
          Debug.trace("-!!!Tpl.textFile failed - a system error ?\n")
        end
        ()
      end
    end
  end
end

#= This function renders a (memory-)text to a file. If we generate modelicaLine directives, translate them to C preprocessor. =#
function textFileConvertLines(inText::Text, inFileName::String)
  _ = begin
    local txt::Text
    local file::String
    local rtTickTxt::ModelicaReal
    local rtTickW::ModelicaReal
    @matchcontinue (inText, inFileName) begin
      (txt, file)  => begin
        rtTickTxt = System.realtimeTock(ClockIndexes.RT_CLOCK_BUILD_MODEL)
        Print.clearBuf()
        textStringBuf(txt)
        rtTickW = System.realtimeTock(ClockIndexes.RT_CLOCK_BUILD_MODEL)
        System.writeFile(file, "")
        if Config.acceptMetaModelicaGrammar() || Flags.isSet(Flags.GEN_DEBUG_SYMBOLS)
          Print.writeBufConvertLines(System.realpath(file))
        else
          Print.writeBuf(file)
        end
        if Config.getRunningTestsuite()
          System.appendFile(Config.getRunningTestsuiteFile(), file + "\n")
        end
        Print.clearBuf()
        if Flags.isSet(Flags.TPL_PERF_TIMES)
          Debug.traceln("textFile " + file + "\n    text:" + realString(realSub(rtTickW, rtTickTxt)) + "\n   write:" + realString(realSub(System.realtimeTock(ClockIndexes.RT_CLOCK_BUILD_MODEL), rtTickW)))
        end
        ()
      end

      _  => begin
        @assert true == (Flags.isSet(Flags.FAILTRACE))
        Debug.trace("-!!!Tpl.textFile failed - a system error ?\n")
        ()
      end
    end
  end
  #= TODO: let this function fail and the error message can be reported via  # ( textFile(txt,\"file.cpp\") ; failMsg=\"error\" )
  =#
end

#= Magic sourceInfo() function implementation =#
function sourceInfo(inFileName::String, inLineNum::ModelicaInteger, inColumnNum::ModelicaInteger)::SourceInfo
  local outSourceInfo::SourceInfo

  outSourceInfo = SOURCEINFO(inFileName, false, inLineNum, inColumnNum, inLineNum, inColumnNum, 0.0)
  outSourceInfo
end

#= we do not import Error.addSourceMessage() directly
=#
#= because of list creation in Susan is not possible (yet by design)
=#

#= Wraps call to Error.addSourceMessage() funtion with Error.TEMPLATE_ERROR and one MessageToken. =#
function addSourceTemplateError(inErrMsg::String, inInfo::SourceInfo)
  Error.addSourceMessage(Error.TEMPLATE_ERROR, list(inErrMsg), inInfo)
end

#= for completeness
=#

#= Wraps call to Error.addMessage() funtion with Error.TEMPLATE_ERROR and one MessageToken. =#
T = Any
function addTemplateErrorFunc(func::T)
  Error.addMessage(Error.TEMPLATE_ERROR_FUNC, list(System.dladdr(func)))
end

#= Wraps call to Error.addMessage() funtion with Error.TEMPLATE_ERROR and one MessageToken. =#
function addTemplateError(msg::String)
  Error.addMessage(Error.TEMPLATE_ERROR, list(msg))
end

#= Magic sourceInfo() function implementation =#
function redirectToFile(text::Text, fileName::String)::Text


  local file::File.FILE = File.FILE()

  if Config.getRunningTestsuite()
    System.appendFile(Config.getRunningTestsuiteFile(), fileName + "\n")
  end
  File.open(file, fileName, File.Mode.Write)
  text = writeText(FILE_TEXT(File.getReference(file), arrayCreate(1, 0), arrayCreate(1, 0), arrayCreate(1, true), arrayCreate(1, list())), text)
  text
end

#= Magic sourceInfo() function implementation =#
function closeFile(text::Text)::Text


  local file::File.FILE = File.FILE(getTextOpaqueFile(text))

  File.releaseReference(file)
  text = emptyTxt
  text
end

function booleanString(b::Bool)::String
  local s::String

  s = String(b)
  s
end

function getTextOpaqueFile(text::Text)::Option
  local opaqueFile::Option

  opaqueFile = begin
    @match text begin
      FILE_TEXT()  => begin
        text.opaqueFile
      end

      _  => begin
        Error.addInternalError("tokFile got non-file text input", sourceInfo())
        fail()
      end
    end
  end
  opaqueFile
end

#= Like ST_STRING or ST_LINE =#
function stringFile(inText::Text, str::String, line::Bool, recurseSeparator::Bool)
  local file::File.FILE = File.FILE(getTextOpaqueFile(inText))
  local nchars::ModelicaInteger
  local iopts::IterOptions
  local septok::StringToken

  _ = begin
    @match inText begin
      FILE_TEXT()  => begin
        handleTok(inText)
        nchars = arrayGet(inText.nchars, 1)
        if ! line
          if arrayGet(inText.isstart, 1)
            File.writeSpace(file, nchars)
            File.write(file, str)
            arrayUpdate(inText.nchars, 1, nchars + stringLength(str))
            arrayUpdate(inText.isstart, 1, false)
          else
            File.write(file, str)
            arrayUpdate(inText.nchars, 1, nchars + stringLength(str))
          end
        else
          if arrayGet(inText.isstart, 1)
            File.writeSpace(file, nchars)
          else
            arrayUpdate(inText.isstart, 1, true)
          end
          File.write(file, str)
          arrayUpdate(inText.nchars, 1, arrayGet(inText.aind, 1))
        end
        ()
      end
    end
  end
end

#= Like ST_NEWLINE =#
function newlineFile(inText::Text)
  local file::File.FILE = File.FILE(getTextOpaqueFile(inText))
  local nchars::ModelicaInteger

  _ = begin
    @match inText begin
      FILE_TEXT()  => begin
        File.write(file, "\n")
        arrayUpdate(inText.nchars, 1, arrayGet(inText.aind, 1))
        arrayUpdate(inText.isstart, 1, true)
        ()
      end
    end
  end
end

function textFileTell(inText::Text)::ModelicaInteger
  local tell::ModelicaInteger

  local file::File.FILE = File.FILE(getTextOpaqueFile(inText))

  tell = File.tell(file)
  tell
end

#= Handle a new token, for example separators =#
function handleTok(txt::Text)
  local septok::StringToken
  local aseptok::Array

  _ = begin
    @match txt begin
      FILE_TEXT()  => begin
        _ = begin
          @match arrayGet(txt.blocksStack, 1) begin
            BT_FILE_TEXT(bt = BT_ITER(), septok = aseptok) <| _  => begin
              _ = begin
                @match arrayGet(aseptok, 1) begin
                  SOME(septok)  => begin
                    arrayUpdate(aseptok, 1, NONE())
                    tokFileText(txt, septok, doHandleTok = false)
                    ()
                  end

                  _  => begin
                    ()
                  end
                end
              end
              ()
            end

            _  => begin
              ()
            end
          end
        end
        ()
      end
    end
  end
end

function debugSusan()::Bool
  local b::Bool

  b = Flags.isSet(Flags.SUSAN_MATCHCONTINUE_DEBUG)
  b
end

function fakeStackOverflow()
  Error.addInternalError("Stack overflow:\n" + StackOverflow.generateReadableMessage(), sourceInfo())
  StackOverflow.triggerStackOverflow()
end

end
