  module Array


    using MetaModelica
    #= ExportAll is not good practice but it makes it so that we do not have to write export after each function :( =#
    using ExportAll
    #= Necessary to write declarations for your uniontypes until Julia adds support for mutually recursive types =#


    FuncType = Function

    FuncType = Function

    FuncType = Function

    FuncType = Function

    FuncType = Function

    FuncType = Function

    FuncType = Function

    FuncType = Function

    FoldFunc = Function

    FoldFunc = Function

    FoldFunc = Function

    FoldFunc = Function

    FoldFunc = Function

    FoldFunc = Function

    FoldFunc = Function

    FoldFunc = Function

    ReduceFunc = Function

    CompFunc = Function

    PredFunc = Function

         #= /*
         * This file is part of OpenModelica.
         *
         * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
         * c/o Linköpings universitet, Department of Computer and Information Science,
         * SE-58183 Linköping, Sweden.
         *
         * All rights reserved.
         *
         * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
         * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
         * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
         * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
         * ACCORDING TO RECIPIENTS CHOICE.
         *
         * The OpenModelica software and the Open Source Modelica
         * Consortium (OSMC) Public License (OSMC-PL) are obtained
         * from OSMC, either from the above address,
         * from the URLs: http:www.ida.liu.se/projects/OpenModelica or
         * http:www.openmodelica.org, and in the OpenModelica distribution.
         * GNU version 3 is obtained from: http:www.gnu.org/copyleft/gpl.html.
         *
         * This program is distributed WITHOUT ANY WARRANTY; without
         * even the implied warranty of  MERCHANTABILITY or FITNESS
         * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
         * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
         *
         * See the full OSMC Public License conditions for more details.
         *
         */ =#

        using MetaModelica.Dangerous: arrayGetNoBoundsChecking, arrayUpdateNoBoundsChecking, arrayCreateNoInit

         #= Takes an array and a function over the elements of the array, which is
           applied for each element.  Since it will update the array values the returned
           array must have the same type, and thus the applied function must also return
           the same type. =#
        T = Any
        function mapNoCopy(inArray::MArray, inFunc::FuncType)::MArray
              local outArray::MArray = inArray

              for i in 1:arrayLength(inArray)
                arrayUpdate(inArray, i, inFunc(arrayGetNoBoundsChecking(inArray, i)))
              end
          outArray
        end

         #= Same as arrayMapNoCopy, but with an additional arguments that's updated for
           each call. =#
        T = Any
        ArgT = Any
        function mapNoCopy_1(inArray::MArray, inFunc::FuncType, inArg::ArgT)::Tuple{ArgT, MArray}
              local outArg::ArgT = inArg
              local outArray::MArray = inArray

              local e::T

              for i in 1:arrayLength(inArray)
                (e, outArg) = inFunc((arrayGetNoBoundsChecking(inArray, i), outArg))
                arrayUpdate(inArray, i, e)
              end
          (outArg, outArray)
        end

        function downheap(inArray::MArray, n::ModelicaInteger, vIn::ModelicaInteger)::MArray


              local v::ModelicaInteger = vIn
              local w::ModelicaInteger = 2 * v + 1
              local tmp::ModelicaInteger

              while w < n
                if w + 1 < n
                  if inArray[w + 2] > inArray[w + 1]
                    w = w + 1
                  end
                end
                if inArray[v + 1] >= inArray[w + 1]
                  return inArray
                end
                tmp = inArray[v + 1]
                inArray[v + 1] = inArray[w + 1]
                inArray[w + 1] = tmp
                v = w
                w = 2 * v + 1
              end
          inArray
        end

        function heapSort(inArray::MArray)::MArray


              local n::ModelicaInteger = arrayLength(inArray)
              local tmp::ModelicaInteger

              for v in intDiv(n, 2) - 1:(-1):0
                inArray = downheap(inArray, n, v)
              end
              for v in n:(-1):2
                tmp = inArray[1]
                inArray[1] = inArray[v]
                inArray[v] = tmp
                inArray = downheap(inArray, v - 1, 0)
              end
          inArray
        end

        T = Any
        function findFirstOnTrue(inArray::MArray, inPredicate::FuncType)::Option
              local outElement::Option

              outElement = NONE()
              for e in inArray
                if inPredicate(e)
                  outElement = SOME(e)
                  break
                end
              end
          outElement
        end

        T = Any
        function findFirstOnTrueWithIdx(inArray::MArray, inPredicate::FuncType)::Tuple{ModelicaInteger, Option}
              local idxOut::ModelicaInteger = -1
              local outElement::Option

              local idx::ModelicaInteger = 1

              outElement = NONE()
              for e in inArray
                if inPredicate(e)
                  idxOut = idx
                  outElement = SOME(e)
                  break
                end
                idx = idx + 1
              end
          (idxOut, outElement)
        end

         #= Takes an array and a list of indices, and returns a new array with the
           indexed elements. Will fail if any index is out of bounds. =#
        T = Any
        function select(inArray::MArray, inIndices::IList)::MArray
              local outArray::MArray

              local i::ModelicaInteger = 1

              outArray = arrayCreateNoInit(listLength(inIndices), inArray[1])
              for e in inIndices
                arrayUpdate(outArray, i, arrayGet(inArray, e))
                i = i + 1
              end
          outArray
        end

         #= Takes an array and a function over the elements of the array, which is
           applied to each element. The updated elements will form a new array, leaving
           the original array unchanged. =#
        TI = Any
        TO = Any
        function map(inArray::MArray, inFunc::FuncType)::MArray
              local outArray::MArray

              local len::ModelicaInteger = arrayLength(inArray)
              local res::TO

               #=  If the array is empty, use list transformations to fix the types!
               =#
              if len == 0
                outArray = listArray(list())
              else
                res = inFunc(arrayGetNoBoundsChecking(inArray, 1))
                outArray = arrayCreateNoInit(len, res)
                arrayUpdateNoBoundsChecking(outArray, 1, res)
                for i in 2:len
                  arrayUpdateNoBoundsChecking(outArray, i, inFunc(arrayGetNoBoundsChecking(inArray, i)))
                end
              end
               #=  If the array isn't empty, use the first element to create the new array.
               =#
          outArray
        end

         #= Takes an array, an extra arguments, and a function over the elements of the
           array, which is applied to each element. The updated elements will form a new
           array, leaving the original array unchanged. =#
        TI = Any
        TO = Any
        ArgT = Any
        function map1(inArray::MArray, inFunc::FuncType, inArg::ArgT)::MArray
              local outArray::MArray

              local len::ModelicaInteger = arrayLength(inArray)
              local res::TO

               #=  If the array is empty, use list transformations to fix the types!
               =#
              if len == 0
                outArray = listArray(list())
              else
                res = inFunc(arrayGetNoBoundsChecking(inArray, 1), inArg)
                outArray = arrayCreateNoInit(len, res)
                arrayUpdate(outArray, 1, res)
                for i in 2:len
                  arrayUpdate(outArray, i, inFunc(arrayGetNoBoundsChecking(inArray, i), inArg))
                end
              end
               #=  If the array isn't empty, use the first element to create the new array.
               =#
          outArray
        end

         #= Applies a non-returning function to all elements in an array. =#
        T = Any
        function map0(inArray::MArray, inFunc::FuncType)
              for e in inArray
                inFunc(e)
              end
        end

         #= As map, but takes a list in and creates an array from the result. =#
        TI = Any
        TO = Any
        function mapList(inList::IList, inFunc::FuncType)::MArray
              local outArray::MArray

              local i::ModelicaInteger = 2
              local len::ModelicaInteger = listLength(inList)
              local res::TO

              if len == 0
                outArray = listArray(list())
              else
                res = inFunc(listHead(inList))
                outArray = arrayCreateNoInit(len, res)
                arrayUpdate(outArray, 1, res)
                for e in listRest(inList)
                  arrayUpdate(outArray, i, inFunc(e))
                  i = i + 1
                end
              end
          outArray
        end

         #= Takes an array, a function, and a start value. The function is applied to
           each array element, and the start value is passed to the function and
           updated. =#
        T = Any
        FoldT = Any
        function fold(inArray::MArray, inFoldFunc::FoldFunc, inStartValue::FoldT)::FoldT
              local outResult::FoldT = inStartValue

              for e in inArray
                outResult = inFoldFunc(e, outResult)
              end
          outResult
        end

         #= Takes an array, a function, and a start value. The function is applied to
           each array element, and the start value is passed to the function and
           updated. =#
        T = Any
        FoldT = Any
        ArgT = Any
        function fold1(inArray::MArray, inFoldFunc::FoldFunc, inArg::ArgT, inStartValue::FoldT)::FoldT
              local outResult::FoldT = inStartValue

              for e in inArray
                outResult = inFoldFunc(e, inArg, outResult)
              end
          outResult
        end

         #= Takes an array, a function, a constant parameter, and a start value. The
           function is applied to each array element, and the start value is passed to
           the function and updated. =#
        T = Any
        FoldT = Any
        ArgT1 = Any
        ArgT2 = Any
        function fold2(inArray::MArray, inFoldFunc::FoldFunc, inArg1::ArgT1, inArg2::ArgT2, inStartValue::FoldT)::FoldT
              local outResult::FoldT = inStartValue

              for e in inArray
                outResult = inFoldFunc(e, inArg1, inArg2, outResult)
              end
          outResult
        end

         #= Takes an array, a function, a constant parameter, and a start value. The
           function is applied to each array element, and the start value is passed to
           the function and updated. =#
        T = Any
        FoldT = Any
        ArgT1 = Any
        ArgT2 = Any
        ArgT3 = Any
        function fold3(inArray::MArray, inFoldFunc::FoldFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inStartValue::FoldT)::FoldT
              local outResult::FoldT = inStartValue

              for e in inArray
                outResult = inFoldFunc(e, inArg1, inArg2, inArg3, outResult)
              end
          outResult
        end

         #= Takes an array, a function, four constant parameters, and a start value. The
           function is applied to each array element, and the start value is passed to
           the function and updated. =#
        T = Any
        FoldT = Any
        ArgT1 = Any
        ArgT2 = Any
        ArgT3 = Any
        ArgT4 = Any
        function fold4(inArray::MArray, inFoldFunc::FoldFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inStartValue::FoldT)::FoldT
              local outResult::FoldT = inStartValue

              for e in inArray
                outResult = inFoldFunc(e, inArg1, inArg2, inArg3, inArg4, outResult)
              end
          outResult
        end

         #= Takes an array, a function, four constant parameters, and a start value. The
           function is applied to each array element, and the start value is passed to
           the function and updated. =#
        T = Any
        FoldT = Any
        ArgT1 = Any
        ArgT2 = Any
        ArgT3 = Any
        ArgT4 = Any
        ArgT5 = Any
        function fold5(inArray::MArray, inFoldFunc::FoldFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inArg5::ArgT5, inStartValue::FoldT)::FoldT
              local outResult::FoldT = inStartValue

              for e in inArray
                outResult = inFoldFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, outResult)
              end
          outResult
        end

         #= Takes an array, a function, four constant parameters, and a start value. The
           function is applied to each array element, and the start value is passed to
           the function and updated. =#
        T = Any
        FoldT = Any
        ArgT1 = Any
        ArgT2 = Any
        ArgT3 = Any
        ArgT4 = Any
        ArgT5 = Any
        ArgT6 = Any
        function fold6(inArray::MArray, inFoldFunc::FoldFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inArg5::ArgT5, inArg6::ArgT6, inStartValue::FoldT)::FoldT
              local outResult::FoldT = inStartValue

              for e in inArray
                outResult = inFoldFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, outResult)
              end
          outResult
        end

         #= Takes an array, a function, and a start value. The function is applied to
           each array element, and the start value is passed to the function and
           updated, additional the index of the passed element is also passed to the function. =#
        T = Any
        FoldT = Any
        function foldIndex(inArray::MArray, inFoldFunc::FoldFunc, inStartValue::FoldT)::FoldT
              local outResult::FoldT = inStartValue

              local e::T

              for i in 1:arrayLength(inArray)
                e = arrayGet(inArray, i)
                outResult = inFoldFunc(e, i, outResult)
              end
          outResult
        end

         #= Takes a list and a function operating on two elements of the array.
           The function performs a reduction of the array to a single value using the
           function. Example:
             reduce([1, 2, 3], intAdd) => 6 =#
        T = Any
        function reduce(inArray::MArray, inReduceFunc::ReduceFunc)::T
              local outResult::T

              local rest::IList

              outResult = arrayGet(inArray, 1)
              for i in 2:arrayLength(inArray)
                outResult = inReduceFunc(outResult, arrayGet(inArray, i))
              end
          outResult
        end

         #= Like arrayUpdate, but with the index first so it can be used with List.map. =#
        T = Any
        function updateIndexFirst(inIndex::ModelicaInteger, inValue::T, inArray::MArray)
              arrayUpdate(inArray, inIndex, inValue)
        end

         #= Like arrayGet, but with the index first so it can used with List.map. =#
        T = Any
        function getIndexFirst(inIndex::ModelicaInteger, inArray::MArray)::T
              local outElement::T = arrayGet(inArray, inIndex)
          outElement
        end

         #= Replaces the element with the given index in the second array with the value
           of the corresponding element in the first array. =#
        T = Any
        function updatewithArrayIndexFirst(inIndex::ModelicaInteger, inArraySrc::MArray, inArrayDest::MArray)
              arrayUpdate(inArrayDest, inIndex, inArraySrc[inIndex])
        end

        T = Any
        function updatewithListIndexFirst(inList::IList, inStartIndex::ModelicaInteger, inArraySrc::MArray, inArrayDest::MArray)
              for i in inStartIndex:inStartIndex + listLength(inList)
                arrayUpdate(inArrayDest, i, inArraySrc[i])
              end
        end

        T = Any
        function updateElementListAppend(inIndex::ModelicaInteger, inValue::IList, inArray::MArray)
              arrayUpdate(inArray, inIndex, listAppend(inArray[inIndex], inValue))
        end

         #= Takes
           - an element,
           - a position (1..n)
           - an array and
           - a fill value
           The function replaces the value at the given position in the array, if the
           given position is out of range, the fill value is used to padd the array up
           to that element position and then insert the value at the position.

          Example:
            replaceAtWithFill('A', 5, {'a', 'b', 'c'}, 'dummy') => {'a', 'b', 'c', 'dummy', 'A'} =#
        T = Any
        function replaceAtWithFill(inPos::ModelicaInteger, inTypeReplace::T, inTypeFill::T, inArray::MArray)::MArray
              local outArray::MArray

              outArray = expandToSize(inPos, inArray, inTypeFill)
              arrayUpdate(outArray, inPos, inTypeReplace)
          outArray
        end

         #= Expands an array to the given size, or does nothing if the array is already
           large enough. =#
        T = Any
        function expandToSize(inNewSize::ModelicaInteger, inArray::MArray, inFill::T)::MArray
              local outArray::MArray

              if inNewSize <= arrayLength(inArray)
                outArray = inArray
              else
                outArray = arrayCreate(inNewSize, inFill)
                copy(inArray, outArray)
              end
          outArray
        end

         #= Increases the number of elements of an array with inN. Each new element is
           assigned the value inFill. =#
        T = Any
        function expand(inN::ModelicaInteger, inArray::MArray, inFill::T)::MArray
              local outArray::MArray

              local len::ModelicaInteger

              if inN < 1
                outArray = inArray
              else
                len = arrayLength(inArray)
                outArray = arrayCreateNoInit(len + inN, inFill)
                copy(inArray, outArray)
                setRange(len + 1, len + inN, outArray, inFill)
              end
          outArray
        end

         #= Resizes an array with the given factor if the array is smaller than the
           requested size. =#
        T = Any
        function expandOnDemand(inNewSize::ModelicaInteger #= The number of elements that should fit in the array. =#, inArray::MArray #= The array to resize. =#, inExpansionFactor::ModelicaReal #= The factor to resize the array with. =#, inFillValue::T #= The value to fill the new part of the array. =#)::MArray
              local outArray::MArray #= The resulting array. =#

              local new_size::ModelicaInteger
              local len::ModelicaInteger = arrayLength(inArray)

              if inNewSize <= len
                outArray = inArray
              else
                new_size = realInt(intReal(len) * inExpansionFactor)
                outArray = arrayCreateNoInit(new_size, inFillValue)
                copy(inArray, outArray)
                setRange(len + 1, new_size, outArray, inFillValue)
              end
          outArray #= The resulting array. =#
        end

         #= Concatenates an element to a list element of an array. =#
        T = Any
        function consToElement(inIndex::ModelicaInteger, inElement::T, inArray::MArray)::MArray
              local outArray::MArray

              outArray = arrayUpdate(inArray, inIndex, inElement <| inArray[inIndex])
          outArray
        end

         #= Appends a list to a list element of an array. =#
        T = Any
        function appendToElement(inIndex::ModelicaInteger, inElements::IList, inArray::MArray)::MArray
              local outArray::MArray

              outArray = arrayUpdate(inArray, inIndex, listAppend(inArray[inIndex], inElements))
          outArray
        end

         #= Returns a new array with the list elements added to the end of the given array. =#
        T = Any
        function appendList(arr::MArray, lst::IList)::MArray
              local outArray::MArray

              local arr_len::ModelicaInteger = arrayLength(arr)
              local lst_len::ModelicaInteger
              local e::T
              local rest::IList

              if listEmpty(lst)
                outArray = arr
              elseif arr_len == 0
                outArray = listArray(lst)
              else
                lst_len = listLength(lst)
                outArray = arrayCreateNoInit(arr_len + lst_len, arr[1])
                copy(arr, outArray)
                rest = lst
                for i in arr_len + 1:arr_len + lst_len
                  e, rest = listHead(rest), listRest(rest)
                  arrayUpdateNoBoundsChecking(outArray, i, e)
                end
              end
          outArray
        end

         #= Copies all values from inArraySrc to inArrayDest. Fails if inArraySrc is
           larger than inArrayDest.

           NOTE: There's also a builtin arrayCopy operator that should be used if the
                 purpose is only to duplicate an array. =#
        T = Any
        function copy(inArraySrc::MArray, inArrayDest::MArray)::MArray
              local outArray::MArray = inArrayDest

              if arrayLength(inArraySrc) > arrayLength(inArrayDest)
                fail()
              end
              for i in 1:arrayLength(inArraySrc)
                arrayUpdateNoBoundsChecking(outArray, i, arrayGetNoBoundsChecking(inArraySrc, i))
              end
          outArray
        end

         #= Copies the first inN values from inArraySrc to inArrayDest. Fails if
           inN is larger than either inArraySrc or inArrayDest. =#
        T = Any
        function copyN(inArraySrc::MArray, inArrayDest::MArray, inN::ModelicaInteger)::MArray
              local outArray::MArray = inArrayDest

              if inN > arrayLength(inArrayDest) || inN > arrayLength(inArraySrc)
                fail()
              end
              for i in 1:inN
                arrayUpdateNoBoundsChecking(outArray, i, arrayGetNoBoundsChecking(inArraySrc, i))
              end
          outArray
        end

         #= Copies a range of elements from one array to another. =#
        T = Any
        function copyRange(srcArray::MArray #= The array to copy from. =#, dstArray::MArray #= The array to insert into. =#, srcFirst::ModelicaInteger #= The index of the first element to copy. =#, srcLast::ModelicaInteger #= The index of the last element to copy. =#, dstPos::ModelicaInteger #= The index to begin inserting at. =#)
              local offset::ModelicaInteger = dstPos - srcFirst

              if srcFirst > srcLast || srcLast > arrayLength(srcArray) || offset + srcLast > arrayLength(dstArray)
                fail()
              end
              for i in srcFirst:srcLast
                arrayUpdateNoBoundsChecking(dstArray, offset + i, arrayGetNoBoundsChecking(srcArray, i))
              end
        end

         #= Creates an array<Integer> of size inLen with the values set to the range of 1:inLen. =#
        function createIntRange(inLen::ModelicaInteger)::MArray
              local outArray::MArray

              outArray = arrayCreateNoInit(inLen, 0)
              for i in 1:inLen
                arrayUpdateNoBoundsChecking(outArray, i, i)
              end
          outArray
        end

         #= Sets the elements in positions inStart to inEnd to inValue. =#
        T = Any
        function setRange(inStart::ModelicaInteger, inEnd::ModelicaInteger, inArray::MArray, inValue::T)::MArray
              local outArray::MArray = inArray

              if inStart > arrayLength(inArray)
                fail()
              end
              for i in inStart:inEnd
                arrayUpdate(inArray, i, inValue)
              end
          outArray
        end

         #= Gets the elements between inStart and inEnd. =#
        T = Any
        function getRange(inStart::ModelicaInteger, inEnd::ModelicaInteger, inArray::MArray)::IList
              local outList::IList = list()

              local value::T

              if inStart > arrayLength(inArray)
                fail()
              end
              for i in inStart:inEnd
                value = arrayGet(inArray, i)
                outList = value <| outList
              end
          outList
        end

         #= Returns the index of the given element in the array, or 0 if it wasn't found. =#
        T = Any
        function position(inArray::MArray, inElement::T, inFilledSize::ModelicaInteger = arrayLength(inArray) #= The filled size of the array. =#)::ModelicaInteger
              local outIndex::ModelicaInteger

              local e::T

              for i in 1:inFilledSize
                if valueEq(inElement, inArray[i])
                  outIndex = i
                  return outIndex
                end
              end
              outIndex = 0
          outIndex
        end

         #= Takes a value and returns the first element for which the comparison
           function returns true, along with that elements position in the array. =#
        VT = Any
        ET = Any
        function getMemberOnTrue(inValue::VT, inArray::MArray, inCompFunc::CompFunc)::Tuple{ModelicaInteger, ET}
              local outIndex::ModelicaInteger
              local outElement::ET

              for i in 1:arrayLength(inArray)
                if inCompFunc(inValue, arrayGetNoBoundsChecking(inArray, i))
                  outElement = arrayGetNoBoundsChecking(inArray, i)
                  outIndex = i
                  return (outIndex, outElement)
                end
              end
              fail()
          (outIndex, outElement)
        end

         #= reverses the elements in an array =#
        T = Any
        function reverse(inArray::MArray)::MArray
              local outArray::MArray

              local size::ModelicaInteger
              local i::ModelicaInteger
              local elem1::T
              local elem2::T

              outArray = inArray
              size = arrayLength(inArray)
              for i in 1:size / 2
                elem1 = arrayGet(inArray, i)
                elem2 = arrayGet(inArray, size - i + 1)
                outArray = arrayUpdate(outArray, i, elem2)
                outArray = arrayUpdate(outArray, size - i + 1, elem1)
              end
          outArray
        end

         #= output true if all lists in the array are empty =#
        T = Any
        function arrayListsEmpty(arr::MArray)::Bool
              local isEmpty::Bool

              isEmpty = fold(arr, arrayListsEmpty1, true)
          isEmpty
        end

        T = Any
        function arrayListsEmpty1(lst::IList, isEmptyIn::Bool)::Bool
              local isEmptyOut::Bool

              isEmptyOut = listEmpty(lst) && isEmptyIn
          isEmptyOut
        end

         #= Checks if two arrays are equal. =#
        T = Any
        function isEqual(inArr1::MArray, inArr2::MArray)::Bool
              local outIsEqual::Bool = true

              local arrLength::ModelicaInteger

              arrLength = arrayLength(inArr1)
              if ! intEq(arrLength, arrayLength(inArr2))
                fail()
              end
              for i in 1:arrLength
                if ! valueEq(inArr1[i], inArr2[i])
                  outIsEqual = false
                  break
                end
              end
          outIsEqual
        end

         #= Returns true if a certain element exists in the given array as indicated by
           the given predicate function. =#
        T = Any
        function exist(arr::MArray, pred::PredFunc)::Bool
              local exists::Bool

              for e in arr
                if pred(e)
                  exists = true
                  return exists
                end
              end
              exists = false
          exists
        end

        T = Any
        function insertList(arr::MArray, lst::IList, startPos::ModelicaInteger)::MArray


              local i::ModelicaInteger = startPos

              for e in lst
                arr[i] = e
                i = i + 1
              end
          arr
        end

    #= So that we can use wildcard imports and named imports when they do occur. Not good Julia practice =#
    @exportAll()
  end