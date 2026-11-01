script "test-backslash"

/*
Round-trip checks for backslash escaping in JSONStringify and minifyJSON.

Run headless:
   <engine> -ui testing/test-backslash.livecodescript
or load the stack in the IDE and run:
   testBackslash
*/

local sPass = 0, sFail = 0

on startup
   local tFolder
   set the itemDelimiter to "/"
   put item 1 to -2 of the filename of me into tFolder
   start using stack (tFolder & "/../PhotonJSON.livecodescript")
   testBackslash
   quit
end startup

on testBackslash
   local tA, tJ, tIn, tOut
   put 0 into sPass
   put 0 into sFail

   -- JSONStringify must escape a backslash as \\ (ECMA-404, section 9)
   put "C:\Users\stam" into tA["path"]
   put JSONStringify(tA) into tJ
   check "backslash in value is escaped", quote & "C:\\Users\\stam" & quote is in tJ, tJ

   put empty into tA
   put "trail\" into tA["t"]
   put JSONStringify(tA) into tJ
   check "trailing backslash does not escape the closing quote", quote & "trail\\" & quote is in tJ, tJ

   put empty into tA
   put "a\nb" into tA["n"]
   put JSONStringify(tA) into tJ
   check "literal backslash-n is not emitted as a newline escape", quote & "a\\nb" & quote is in tJ, tJ

   put empty into tA
   put "say " & quote & "hi\" & quote into tA["q"]
   put JSONStringify(tA) into tJ
   check "backslash before a quote is escaped before the quote is", quote & "say \" & quote & "hi\\\" & quote & quote is in tJ, tJ

   put empty into tA
   put "C:\path" into tA["k\ey"]
   put JSONStringify(tA) into tJ
   check "backslash in a key is escaped", quote & "k\\ey" & quote is in tJ, tJ

   -- minifyJSON must preserve escape sequences it did not create
   put "{ " & quote & "p" & quote & " : " & quote & "C:\\Users" & quote & ", " \
         & quote & "q" & quote & ": " & quote & "a\" & quote & "b" & quote & ", " \
         & quote & "n" & quote & ": " & quote & "x\ny" & quote & " }" into tIn
   put minifyJSON(tIn) into tOut
   check "minify keeps an escaped backslash intact", quote & "C:\\Users" & quote is in tOut, tOut
   check "minify keeps an escaped quote intact", quote & "a\" & quote & "b" & quote is in tOut, tOut
   check "minify keeps an escaped newline intact", quote & "x\ny" & quote is in tOut, tOut

   put "PASS " & sPass & "  FAIL " & sFail & return
end testBackslash

private command check pName, pCondition, pDetail
   if pCondition is true then
      add 1 to sPass
      put "ok   " & pName & return
   else
      add 1 to sFail
      put "FAIL " & pName & "  --  got: " & pDetail & return
   end if
end check
