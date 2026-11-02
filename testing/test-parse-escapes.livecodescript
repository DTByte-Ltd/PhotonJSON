script "test-parse-escapes"

/*
Checks that JSONParser decodes escape sequences and UTF-8 input correctly.

Run headless:
   <engine> -ui testing/test-parse-escapes.livecodescript
or load the stack in the IDE and run:
   testParseEscapes
*/

local sPass = 0, sFail = 0

on startup
   local tFolder
   set the itemDelimiter to "/"
   put item 1 to -2 of the filename of me into tFolder
   start using stack (tFolder & "/../PhotonJSON.livecodescript")
   testParseEscapes
   quit
end startup

on testParseEscapes
   local tJ, tA, tExpected, tBytes
   put 0 into sPass
   put 0 into sFail

   -- escaped reverse solidus
   put JSONParser(obj("p", "C:\\Users\\stam")) into tA
   check "double backslash decodes to one backslash", tA["p"] is "C:\Users\stam", tA["p"]

   put JSONParser(obj("t", "trail\\")) into tA
   check "escaped backslash before the closing quote", tA["t"] is "trail\", tA["t"]

   put JSONParser(obj("m", "\\\" & quote & "x")) into tA
   check "escaped backslash then escaped quote", tA["m"] is ("\" & quote & "x"), tA["m"]

   put JSONParser(obj("a", "x\\\\y")) into tA
   check "two escaped backslashes", tA["a"] is "x\\y", tA["a"]

   -- the text produced by one escape must not start another (issue #2)
   put JSONParser(obj("e", "\\u0041")) into tA
   check "escaped backslash followed by u0041 stays literal", tA["e"] is "\u0041", tA["e"]

   put JSONParser(obj("e", "\\n")) into tA
   check "escaped backslash followed by n stays literal", tA["e"] is "\n", tA["e"]

   -- escaped quote
   put JSONParser(obj("q", "say \" & quote & "hi\" & quote)) into tA
   check "escaped quotes", tA["q"] is ("say " & quote & "hi" & quote), tA["q"]

   -- the single-character escapes
   put JSONParser(obj("c", "a\nb\tc\rd\/e\bf\fg")) into tA
   put "a" & numToChar(10) & "b" & numToChar(9) & "c" & numToChar(13) & "d/e" & numToChar(8) & "f" & numToChar(12) & "g" into tExpected
   check "control character escapes", tA["c"] is tExpected, tA["c"]

   -- unicode escapes decode by code point on every platform
   put JSONParser(obj("u", "caf\u00e9")) into tA
   put "caf" & numToCodepoint(233) into tExpected
   check "\u00e9 decodes to U+00E9", tA["u"] is tExpected, codepointsOf(tA["u"])

   put JSONParser(obj("u", "\u0391\u03bb\u03c6\u03b1")) into tA
   put numToCodepoint(913) & numToCodepoint(955) & numToCodepoint(966) & numToCodepoint(945) into tExpected
   check "Greek unicode escapes", tA["u"] is tExpected, codepointsOf(tA["u"])

   put JSONParser(obj("s", "\ud83d\ude00")) into tA
   check "surrogate pair decodes to one code point", codepointToNum(codepoint 1 of tA["s"]) is 128512 and the number of codepoints in tA["s"] is 1, codepointsOf(tA["s"])

   put JSONParser(obj("z", "\u0000")) into tA
   check "\u0000 decodes to a null character", tA["z"] is numToChar(0) and the number of chars in tA["z"] is 1, codepointsOf(tA["z"])

   -- keys are unescaped too
   put JSONParser("{" & quote & "k\\ey" & quote & ": 1}") into tA
   check "escapes in keys", tA["k\ey"] is 1, the keys of tA

   -- raw UTF-8 input as binary data
   put textEncode(obj("g", numToCodepoint(913) & numToCodepoint(955)), "UTF-8") into tBytes
   put JSONParser(tBytes) into tA
   check "binary UTF-8 input", tA["g"] is (numToCodepoint(913) & numToCodepoint(955)), codepointsOf(tA["g"])

   -- the same bytes as native text, one character per byte (url "file:")
   put JSONParser(textDecode(tBytes, "native")) into tA
   check "UTF-8 bytes held in native text", tA["g"] is (numToCodepoint(913) & numToCodepoint(955)), codepointsOf(tA["g"])

   -- plain text input
   put JSONParser(obj("g", numToCodepoint(913) & numToCodepoint(955))) into tA
   check "plain text input", tA["g"] is (numToCodepoint(913) & numToCodepoint(955)), codepointsOf(tA["g"])

   put JSONParser(obj("g", "caf" & numToCodepoint(233))) into tA
   check "plain text input in the native range", tA["g"] is ("caf" & numToCodepoint(233)), codepointsOf(tA["g"])

   -- the formatting entry points use the same pre-pass
   put minifyJSON("{ " & quote & "p" & quote & " : " & quote & "a\\b" & quote & " }") into tJ
   check "minifyJSON keeps an escaped backslash", tJ is ("{" & quote & "p" & quote & ":" & quote & "a\\b" & quote & "}"), tJ

   put beautifyJSON("{" & quote & "p" & quote & ":" & quote & "a\\b" & quote & "}") into tJ
   check "beautifyJSON keeps an escaped backslash", quote & "a\\b" & quote is in tJ, tJ

   check "validateJSON accepts an escaped backslash", validateJSON(obj("p", "a\\b")) is true, validateJSON(obj("p", "a\\b"))

   put "PASS " & sPass & "  FAIL " & sFail & return
end testParseEscapes

-- builds {"<key>": "<raw JSON string body>"}
private function obj pKey, pBody
   return "{" & quote & pKey & quote & ": " & quote & pBody & quote & "}"
end obj

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
