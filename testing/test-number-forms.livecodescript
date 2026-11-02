script "test-number-forms"

/*
Checks which values are written as bare JSON numbers, and that numbers with
an exponent sign parse as one value.

Run headless:
   <engine> -ui testing/test-number-forms.livecodescript
or load the stack in the IDE and run:
   testNumberForms
*/

local sPass = 0, sFail = 0

on startup
   local tFolder
   set the itemDelimiter to "/"
   put item 1 to -2 of the filename of me into tFolder
   start using stack (tFolder & "/../PhotonJSON.livecodescript")
   testNumberForms
   quit
end startup

on testNumberForms
   local tA, tJ, tB, tV
   put 0 into sPass
   put 0 into sFail

   -- canonical numbers are written bare
   repeat for each item tV in "42,-7,0,-0,10,3.14,0.5,-0.25,1787070000000"
      put empty into tA
      put tV into tA["v"]
      put JSONStringify(tA) into tJ
      check tV && "is written bare", tJ is ("{" & quote & "v" & quote & ": " & tV & "}"), tJ
   end repeat

   -- text that merely evaluates as a number is written as a string
   repeat for each item tV in "007,3.10,1e5,1E5,1.,.5,+5,0x1A"
      put empty into tA
      put tV into tA["v"]
      put JSONStringify(tA) into tJ
      check tV && "is written as a string", tJ is ("{" & quote & "v" & quote & ": " & quote & tV & quote & "}"), tJ
   end repeat

   put empty into tA
   put " 42" into tA["v"]
   put JSONStringify(tA) into tJ
   check "a number with a leading space is written as a string", tJ is ("{" & quote & "v" & quote & ": " & quote & " 42" & quote & "}"), tJ

   put empty into tA
   put "3.10" into tA["v"]
   put JSONStringify(tA, empty, true) into tJ
   check "pretty print keeps 3.10 quoted", quote & "3.10" & quote is in tJ, tJ

   -- numbers with a signed exponent parse as one value
   put JSONParser("{" & quote & "a" & quote & ": 1e-5}") into tB
   check "1e-5 parses as one value", tB["a"] is "1e-5" and the number of chars in tB["a"] is 4, tB["a"]

   put JSONParser("{" & quote & "a" & quote & ": 1e+5, " & quote & "b" & quote & ": -3}") into tB
   check "1e+5 parses as one value", tB["a"] is "1e+5" and the number of chars in tB["a"] is 4, tB["a"]
   check "a following negative number is unaffected", tB["b"] is -3, tB["b"]

   put JSONParser("[1.5E-3, 2, -4]") into tB
   check "1.5E-3 in a list", tB[1] is "1.5E-3" and the number of chars in tB[1] is 6, tB[1]
   check "list positions after it are kept", tB[2] is 2 and tB[3] is -4 and the number of elements in tB is 3, the keys of tB

   put JSONParser("{" & quote & "a" & quote & ": 2e5}") into tB
   check "an unsigned exponent still parses", tB["a"] is "2e5", tB["a"]

   put JSONParser("{" & quote & "a" & quote & ": " & quote & "x1e" & quote & ", " & quote & "b" & quote & ": -5}") into tB
   check "a string ending in e followed by a negative number", tB["a"] is "x1e" and tB["b"] is -5, tB["a"] & " " & tB["b"]

   put "PASS " & sPass & "  FAIL " & sFail & return
end testNumberForms

private command check pName, pCondition, pDetail
   if pCondition is true then
      add 1 to sPass
      put "ok   " & pName & return
   else
      add 1 to sFail
      put "FAIL " & pName & "  --  got: " & pDetail & return
   end if
end check
