script "test-sorted-keys"

/*
Checks that object keys are written in a stable, sorted order.

Run headless:
   <engine> -ui testing/test-sorted-keys.livecodescript
or load the stack in the IDE and run:
   testSortedKeys
*/

local sPass = 0, sFail = 0

on startup
   local tFolder
   set the itemDelimiter to "/"
   put item 1 to -2 of the filename of me into tFolder
   start using stack (tFolder & "/../PhotonJSON.livecodescript")
   testSortedKeys
   quit
end startup

on testSortedKeys
   local tA, tB, tJ1, tJ2, i
   put 0 into sPass
   put 0 into sFail

   put 1 into tA["zeta"]
   put 2 into tA["alpha"]
   put 3 into tA["Mid"]
   put 4 into tA["beta"]
   put JSONStringify(tA) into tJ1
   check "keys come out sorted", tJ1 is ("{" & quote & "alpha" & quote & ": 2," & quote & "beta" & quote & ": 4," & quote & "Mid" & quote & ": 3," & quote & "zeta" & quote & ": 1}"), tJ1

   -- the same data built in a different order gives the same text
   put 4 into tB["beta"]
   put 3 into tB["Mid"]
   put 2 into tB["alpha"]
   put 1 into tB["zeta"]
   check "insertion order does not matter", JSONStringify(tB) is tJ1, JSONStringify(tB)

   -- nested objects are sorted too, lists keep their order
   put empty into tA
   put "y" into tA["o"]["k2"]
   put "x" into tA["o"]["k1"]
   put "second" into tA["l"][2]
   put "first" into tA["l"][1]
   put JSONStringify(tA) into tJ1
   check "nested object keys sorted, list order kept", tJ1 is ("{" & quote & "l" & quote & ": [" & quote & "first" & quote & "," & quote & "second" & quote & "]," & quote & "o" & quote & ": {" & quote & "k1" & quote & ": " & quote & "x" & quote & "," & quote & "k2" & quote & ": " & quote & "y" & quote & "}}"), tJ1

   -- pretty output is stable as well
   put JSONStringify(tA, empty, true) into tJ1
   put JSONStringify(tA, empty, true) into tJ2
   check "pretty output is identical on repeat", tJ1 is tJ2, tJ1

   put "PASS " & sPass & "  FAIL " & sFail & return
end testSortedKeys

private command check pName, pCondition, pDetail
   if pCondition is true then
      add 1 to sPass
      put "ok   " & pName & return
   else
      add 1 to sFail
      put "FAIL " & pName & "  --  got: " & pDetail & return
   end if
end check
