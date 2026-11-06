script "test-force-string"

/*
Checks the pForceRootType "string" option of JSONStringify / ArrayToJSON.

Run headless:
   <engine> -ui testing/test-force-string.livecodescript
or load the stack in the IDE and run:
   testForceString
*/

local sPass = 0, sFail = 0

on startup
   local tFolder
   set the itemDelimiter to "/"
   put item 1 to -2 of the filename of me into tFolder
   start using stack (tFolder & "/../PhotonJSON.livecodescript")
   testForceString
   quit
end startup

on testForceString
   local tA, tJ, tB
   put 0 into sPass
   put 0 into sFail

   put "1999" into tA["year"]
   put "abc" into tA["text"]
   put "true" into tA["flag"]
   put JSONStringify(tA, "string") into tJ
   check "a number is written as a string", quote & "year" & quote & ": " & quote & "1999" & quote is in tJ, tJ
   check "a literal is written as a string", quote & "flag" & quote & ": " & quote & "true" & quote is in tJ, tJ
   check "a string is quoted once, not twice", quote & "text" & quote & ": " & quote & "abc" & quote is in tJ and (quote & quote & "abc") is not in tJ, tJ
   put JSONParser(tJ) into tB
   check "forced output parses back", tB["year"] is "1999" and tB["text"] is "abc" and tB["flag"] is "true", the keys of tB

   put empty into tA
   put 7 into tA[1]
   put "x" into tA[2]
   put JSONStringify(tA, "string") into tJ
   check "list elements forced to strings", tJ is ("[" & quote & "7" & quote & "," & quote & "x" & quote & "]"), tJ

   put empty into tA
   put 42 into tA["n"]
   put "s" into tA["s"]
   put JSONStringify(tA, "string", true) into tJ
   check "pretty output forced to strings", quote & "n" & quote & ": " & quote & "42" & quote is in tJ and quote & "s" & quote & ": " & quote & "s" & quote is in tJ and (quote & quote & "s") is not in tJ, tJ

   put empty into tA
   put 42 into tA["n"]
   put JSONStringify(tA) into tJ
   check "without the option numbers stay bare", tJ is ("{" & quote & "n" & quote & ": 42}"), tJ

   put "PASS " & sPass & "  FAIL " & sFail & return
end testForceString

private command check pName, pCondition, pDetail
   if pCondition is true then
      add 1 to sPass
      put "ok   " & pName & return
   else
      add 1 to sFail
      put "FAIL " & pName & "  --  got: " & pDetail & return
   end if
end check
