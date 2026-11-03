script "test-list-detection"

/*
Checks which arrays are written as JSON lists.

Run headless:
   <engine> -ui testing/test-list-detection.livecodescript
or load the stack in the IDE and run:
   testListDetection
*/

local sPass = 0, sFail = 0

on startup
   local tFolder
   set the itemDelimiter to "/"
   put item 1 to -2 of the filename of me into tFolder
   start using stack (tFolder & "/../PhotonJSON.livecodescript")
   testListDetection
   quit
end startup

on testListDetection
   local tA, tJ, tB
   put 0 into sPass
   put 0 into sFail

   put "a" into tA[1]
   put "b" into tA[2]
   put "c" into tA[3]
   check "keys 1 to n are a list", JSONStringify(tA) is ("[" & quote & "a" & quote & "," & quote & "b" & quote & "," & quote & "c" & quote & "]"), JSONStringify(tA)

   put empty into tA
   put "x" into tA[2]
   put "y" into tA[5]
   put JSONStringify(tA) into tJ
   check "sparse integer keys are an object", char 1 of tJ is "{" and quote & "2" & quote & ": " & quote & "x" & quote is in tJ and quote & "5" & quote & ": " & quote & "y" & quote is in tJ, tJ
   put JSONParser(tJ) into tB
   check "sparse keys survive a round trip", tB[2] is "x" and tB[5] is "y" and the number of elements in tB is 2, the keys of tB

   put empty into tA
   put "x" into tA[1]
   put "z" into tA[3]
   put JSONStringify(tA) into tJ
   check "a gap in the keys makes an object", char 1 of tJ is "{" and quote & "3" & quote & ": " & quote & "z" & quote is in tJ, tJ

   put empty into tA
   put "x" into tA[0]
   put "y" into tA[1]
   put JSONStringify(tA) into tJ
   check "keys starting at 0 make an object", char 1 of tJ is "{" and quote & "0" & quote & ": " & quote & "x" & quote is in tJ, tJ

   put empty into tA
   put "p" into tA[1774238712067]
   put "q" into tA[1775338084582]
   put JSONStringify(tA) into tJ
   check "large integer keys are an object", char 1 of tJ is "{" and quote & "1774238712067" & quote & ": " & quote & "p" & quote is in tJ, tJ

   put empty into tA
   put "v" into tA["list"][1]
   put "w" into tA["list"][2]
   put "s" into tA["sparse"][3]
   put JSONStringify(tA) into tJ
   check "nested list and nested sparse object", quote & "list" & quote & ": [" & quote & "v" & quote & "," & quote & "w" & quote & "]" is in tJ and quote & "sparse" & quote & ": {" & quote & "3" & quote & ": " & quote & "s" & quote & "}" is in tJ, tJ

   put "PASS " & sPass & "  FAIL " & sFail & return
end testListDetection

private command check pName, pCondition, pDetail
   if pCondition is true then
      add 1 to sPass
      put "ok   " & pName & return
   else
      add 1 to sFail
      put "FAIL " & pName & "  --  got: " & pDetail & return
   end if
end check
