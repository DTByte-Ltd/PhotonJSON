script "test-literals"

/*
Checks that empty strings, null, true and false survive a round trip.

Run headless:
   <engine> -ui testing/test-literals.livecodescript
or load the stack in the IDE and run:
   testLiterals
*/

local sPass = 0, sFail = 0

on startup
   local tFolder
   set the itemDelimiter to "/"
   put item 1 to -2 of the filename of me into tFolder
   start using stack (tFolder & "/../PhotonJSON.livecodescript")
   testLiterals
   quit
end startup

on testLiterals
   local tA, tJ, tB
   put 0 into sPass
   put 0 into sFail

   -- an empty string is a string, not null
   put "" into tA["e"]
   put JSONStringify(tA) into tJ
   check "empty string is written as an empty JSON string", tJ is ("{" & quote & "e" & quote & ": " & quote & quote & "}"), tJ
   put JSONParser(tJ) into tB
   check "empty string round trip", "e" is among the keys of tB and tB["e"] is empty and tB["e"] is not an array, tB["e"]

   put "" into tA["l"][1]
   put "x" into tA["l"][2]
   put JSONStringify(tA) into tJ
   check "empty string in a list is written as an empty JSON string", "[" & quote & quote & "," & quote & "x" & quote & "]" is in tJ, tJ

   put JSONStringify(tA, empty, true) into tJ
   check "pretty print keeps the empty string", quote & "e" & quote & ": " & quote & quote is in tJ, tJ

   -- a bare null parses to an empty value
   put JSONParser("{" & quote & "n" & quote & ": null, " & quote & "v" & quote & ": 1}") into tB
   check "bare null parses to empty", "n" is among the keys of tB and tB["n"] is empty, tB["n"]
   check "value after the null is intact", tB["v"] is 1, tB["v"]

   put JSONParser("[null, " & quote & "null" & quote & ", " & quote & quote & ", 2]") into tB
   check "null in a list parses to empty", tB[1] is empty, tB[1]
   check "quoted null in a list stays the string null", tB[2] is "null", tB[2]
   check "empty JSON string in a list parses to empty", tB[3] is empty, tB[3]
   check "list positions are kept", tB[4] is 2 and the number of elements in tB is 4, the keys of tB

   -- a quoted "null" is a string
   put JSONParser("{" & quote & "s" & quote & ": " & quote & "null" & quote & "}") into tB
   check "quoted null parses to the string null", tB["s"] is "null" and the number of chars in tB["s"] is 4, tB["s"]

   put JSONParser("{" & quote & "null" & quote & ": 1}") into tB
   check "null as a key stays a key", tB["null"] is 1, the keys of tB

   -- the string "null" still writes a JSON null (the library's idiom for null)
   put empty into tA
   put "null" into tA["n"]
   put JSONStringify(tA) into tJ
   check "the string null is still written as JSON null", tJ is ("{" & quote & "n" & quote & ": null}"), tJ

   -- booleans
   put empty into tA
   put "true" into tA["t"]
   put "false" into tA["f"]
   put JSONStringify(tA) into tJ
   check "true and false are written bare", quote & "t" & quote & ": true" is in tJ and quote & "f" & quote & ": false" is in tJ, tJ
   put JSONParser(tJ) into tB
   check "boolean round trip", tB["t"] is true and tB["f"] is false, tB["t"] & " " & tB["f"]

   put JSONParser("{" & quote & "q" & quote & ": " & quote & "true" & quote & "}") into tB
   check "quoted true parses to the string true", tB["q"] is "true", tB["q"]

   put "PASS " & sPass & "  FAIL " & sFail & return
end testLiterals

private command check pName, pCondition, pDetail
   if pCondition is true then
      add 1 to sPass
      put "ok   " & pName & return
   else
      add 1 to sFail
      put "FAIL " & pName & "  --  got: " & pDetail & return
   end if
end check
