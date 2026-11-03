script "test-containers"

/*
Checks nesting deeper than ten levels and empty containers.

Run headless:
   <engine> -ui testing/test-containers.livecodescript
or load the stack in the IDE and run:
   testContainers
*/

local sPass = 0, sFail = 0

on startup
   local tFolder
   set the itemDelimiter to "/"
   put item 1 to -2 of the filename of me into tFolder
   start using stack (tFolder & "/../PhotonJSON.livecodescript")
   testContainers
   quit
end startup

on testContainers
   local tJ, tA, tB, i, tOpen, tClose
   put 0 into sPass
   put 0 into sFail

   -- an object nested fourteen levels deep (the array builder unrolls ten)
   put empty into tOpen
   put empty into tClose
   repeat with i = 1 to 14
      put "{" & quote & "l" & i & quote & ": " after tOpen
      put "}" after tClose
   end repeat
   put tOpen & "{" & quote & "value" & quote & ": " & quote & "deep" & quote & ", " & quote & "n" & quote & ": 5}" & tClose into tJ
   put JSONParser(tJ) into tA
   check "value fourteen levels down", tA["l1"]["l2"]["l3"]["l4"]["l5"]["l6"]["l7"]["l8"]["l9"]["l10"]["l11"]["l12"]["l13"]["l14"]["value"] is "deep", the keys of tA
   check "sibling fourteen levels down", tA["l1"]["l2"]["l3"]["l4"]["l5"]["l6"]["l7"]["l8"]["l9"]["l10"]["l11"]["l12"]["l13"]["l14"]["n"] is 5, the keys of tA["l1"]
   check "no stray keys at the top", the number of elements in tA is 1, the keys of tA

   -- exactly eleven levels, the first depth that uses the general path
   put empty into tOpen
   put empty into tClose
   repeat with i = 1 to 10
      put "{" & quote & "k" & i & quote & ": " after tOpen
      put "}" after tClose
   end repeat
   put tOpen & "{" & quote & "x" & quote & ": 1}" & tClose into tJ
   put JSONParser(tJ) into tA
   check "value eleven levels down", tA["k1"]["k2"]["k3"]["k4"]["k5"]["k6"]["k7"]["k8"]["k9"]["k10"]["x"] is 1, the keys of tA

   -- a list nested twelve levels deep
   put "[[[[[[[[[[[[7]]]]]]]]]]]]" into tJ
   put JSONParser(tJ) into tA
   check "list twelve levels down", tA[1][1][1][1][1][1][1][1][1][1][1][1] is 7, the keys of tA

   -- a deep value followed by a sibling of its ancestor
   put "{" & quote & "deep" & quote & ": " & tOpen & "{" & quote & "x" & quote & ": 1}" & tClose & ", " & quote & "after" & quote & ": 2}" into tJ
   put JSONParser(tJ) into tA
   check "deep value is intact", tA["deep"]["k1"]["k2"]["k3"]["k4"]["k5"]["k6"]["k7"]["k8"]["k9"]["k10"]["x"] is 1, the keys of tA
   check "sibling after the deep value", tA["after"] is 2, the keys of tA

   -- deep round trip
   put JSONStringify(tA) into tJ
   put JSONParser(tJ) into tB
   check "deep structure round-trips", tB is tA, tJ

   -- empty containers do not leak into each other
   put JSONParser("{" & quote & "l" & quote & ": [], " & quote & "o" & quote & ": {}, " & quote & "v" & quote & ": 1}") into tA
   check "empty object after an empty list has one key", the number of elements in tA["o"] is 1 and "" is among the keys of tA["o"], the keys of tA["o"]
   check "empty list has one element", the number of elements in tA["l"] is 1 and tA["l"][1] is empty, the keys of tA["l"]
   put JSONStringify(tA) into tJ
   check "empty list is written back as []", quote & "l" & quote & ": []" is in tJ, tJ
   check "empty object is written back as {}", quote & "o" & quote & ": {}" is in tJ, tJ

   put JSONParser("[[], {}, " & quote & quote & ", {}, []]") into tA
   put JSONStringify(tA) into tJ
   check "empty containers inside a list", tJ is ("[[],{}," & quote & quote & ",{},[]]"), tJ

   put "PASS " & sPass & "  FAIL " & sFail & return
end testContainers

private command check pName, pCondition, pDetail
   if pCondition is true then
      add 1 to sPass
      put "ok   " & pName & return
   else
      add 1 to sFail
      put "FAIL " & pName & "  --  got: " & pDetail & return
   end if
end check
