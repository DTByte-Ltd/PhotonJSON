script "test-utf8-output"

/*
Checks that JSONStringify writes text outside ASCII as UTF-8 and escapes
only control characters.

Run headless:
   <engine> -ui testing/test-utf8-output.livecodescript
or load the stack in the IDE and run:
   testUtf8Output
*/

local sPass = 0, sFail = 0

on startup
   local tFolder
   set the itemDelimiter to "/"
   put item 1 to -2 of the filename of me into tFolder
   start using stack (tFolder & "/../PhotonJSON.livecodescript")
   testUtf8Output
   quit
end startup

on testUtf8Output
   local tA, tJ, tD, tB, tP, tEacute, tGreek, tTypo, tEmoji
   put 0 into sPass
   put 0 into sFail

   put numToCodepoint(201) into tEacute                                   -- É
   put numToCodepoint(913) & numToCodepoint(955) & numToCodepoint(966) into tGreek   -- Αλφ
   put numToCodepoint(8220) & "q" & numToCodepoint(8221) & numToCodepoint(8212) & numToCodepoint(8230) into tTypo   -- “q”—…
   put numToCodepoint(128512) into tEmoji                                 -- U+1F600

   put tEacute into tA["e"]
   put JSONStringify(tA) into tJ
   check "output is UTF-8 encoded data", tJ is strictly a binary string, "not binary"
   check "E acute is written as its UTF-8 bytes", hexOf(tJ) contains "c389", hexOf(tJ)
   check "E acute is not escaped", "\u00" is not in tJ, tJ
   put textDecode(tJ, "UTF-8") into tD
   check "decoded output is the expected text", tD is ("{" & quote & "e" & quote & ": " & quote & tEacute & quote & "}"), tD

   -- letters whose native (Mac Roman) codes are 128 to 159 were escaped before
   put empty into tA
   put numToCodepoint(226) & numToCodepoint(237) & numToCodepoint(252) into tA["m"]   -- âíü
   put JSONStringify(tA) into tJ
   check "a-circumflex, i-acute and u-umlaut are not escaped", "\u00" is not in tJ and hexOf(tJ) contains "c3a2c3adc3bc", hexOf(tJ)

   put empty into tA
   put tTypo into tA["t"]
   put JSONStringify(tA) into tJ
   check "typographic quotes, dash and ellipsis are not escaped", "\u20" is not in tJ and hexOf(tJ) contains "e2809c71e2809de28094e280a6", hexOf(tJ)

   put empty into tA
   put tGreek & tEmoji into tA["g"]
   put JSONStringify(tA) into tJ
   check "Greek and an emoji are written as UTF-8", hexOf(tJ) contains "ce91cebbcf86f09f9880", hexOf(tJ)

   -- control characters are still escaped, by code point
   put empty into tA
   put numToCodepoint(1) & "a" & numToCodepoint(31) & "b" & numToCodepoint(127) & "c" & numToCodepoint(133) into tA["c"]
   put JSONStringify(tA) into tJ
   check "C0 controls and DEL are escaped", quote & "\u0001a\u001fb\u007fc" is in tJ, tJ
   check "a C1 control is escaped by its code point", "\u0085" & quote is in tJ, tJ

   -- keys get the same treatment
   put empty into tA
   put 1 into tA["k" & tEacute]
   put JSONStringify(tA) into tJ
   check "non-ASCII key is written as UTF-8", hexOf(tJ) contains "6bc389", hexOf(tJ)

   -- the output parses back
   put empty into tA
   put tEacute into tA["e"]
   put tGreek & tEmoji into tA["g"]
   put tTypo into tA["t"]
   put JSONStringify(tA) into tJ
   put JSONParser(tJ) into tB
   check "round trip: E acute", tB["e"] is tEacute, codepointsOf(tB["e"])
   check "round trip: Greek and emoji", tB["g"] is (tGreek & tEmoji), codepointsOf(tB["g"])
   check "round trip: typographic characters", tB["t"] is tTypo, codepointsOf(tB["t"])
   check "validateJSON accepts the output", validateJSON(tJ) is true, "rejected"

   -- pretty output is text and keeps the characters
   put JSONStringify(tA, empty, true) into tP
   check "pretty output keeps E acute", tEacute is in tP and "\u00" is not in tP, tP
   check "pretty output keeps the emoji", tEmoji is in tP, tP

   put "PASS " & sPass & "  FAIL " & sFail & return
end testUtf8Output

private function hexOf pData
   local tHex
   get binaryDecode("H*", pData, tHex)
   return tHex
end hexOf

private function codepointsOf pText
   local tList, tCP
   repeat for each codepoint tCP in pText
      put "U+" & baseConvert(codepointToNum(tCP), 10, 16) & " " after tList
   end repeat
   return tList
end codepointsOf

private command check pName, pCondition, pDetail
   if pCondition is true then
      add 1 to sPass
      put "ok   " & pName & return
   else
      add 1 to sFail
      put "FAIL " & pName & "  --  got: " & pDetail & return
   end if
end check
