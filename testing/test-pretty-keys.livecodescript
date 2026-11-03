script "test-pretty-keys"

/*
Checks that the pretty printer always writes object keys as strings.

Run headless:
   <engine> -ui testing/test-pretty-keys.livecodescript
or load the stack in the IDE and run:
   testPrettyKeys
*/

local sPass = 0, sFail = 0

on startup
   local tFolder
   set the itemDelimiter to "/"
   put item 1 to -2 of the filename of me into tFolder
   start using stack (tFolder & "/../PhotonJSON.livecodescript")
   testPrettyKeys
   quit
end startup

on testPrettyKeys
   local tA, tJ, tB
   put 0 into sPass
   put 0 into sFail

   put 1 into tA["123"]
   put 2 into tA["true"]
   put 3 into tA["3.10"]
   put 4 into tA["plain"]
   put JSONStringify(tA, empty, true) into tJ
   check "numeric-looking key is quoted", quote & "123" & quote & ": 1" is in tJ, tJ
   check "key that reads as a boolean is quoted", quote & "true" & quote & ": 2" is in tJ, tJ
   check "decimal-looking key is quoted", quote & "3.10" & quote & ": 3" is in tJ, tJ
   check "no bare key anywhere", not matchText(tJ, "[{,]\s*[^\s" & quote & "}\]]"), tJ
   put JSONParser(tJ) into tB
   check "pretty output parses back with the same keys", tB["123"] is 1 and tB["true"] is 2 and tB["3.10"] is 3 and tB["plain"] is 4, the keys of tB

   -- nested objects and lists keep the key rule per container
   put empty into tA
   put "a" into tA["o"]["seven"]
   put "b" into tA["o"]["eight"]
   put 9 into tA["l"][1]
   put 10 into tA["l"][2]
   put JSONStringify(tA, empty, true) into tJ
   check "keys inside a nested object are quoted", quote & "seven" & quote & ": " & quote & "a" & quote is in tJ and quote & "eight" & quote & ": " & quote & "b" & quote is in tJ, tJ
   check "list elements are not quoted", "[9, 10]" is in tJ or "[9,10]" is in tJ, tJ
   put JSONParser(tJ) into tB
   check "nested pretty output parses back", tB["o"]["seven"] is "a" and tB["o"]["eight"] is "b" and tB["l"][2] is 10, the keys of tB

   -- values keep their types
   put empty into tA
   put 42 into tA["n"]
   put "text" into tA["s"]
   put JSONStringify(tA, empty, true) into tJ
   check "number value stays bare, string value stays quoted", quote & "n" & quote & ": 42" is in tJ and quote & "s" & quote & ": " & quote & "text" & quote is in tJ, tJ

   put "PASS " & sPass & "  FAIL " & sFail & return
end testPrettyKeys

private command check pName, pCondition, pDetail
   if pCondition is true then
      add 1 to sPass
      put "ok   " & pName & return
   else
      add 1 to sFail
      put "FAIL " & pName & "  --  got: " & pDetail & return
   end if
end check
