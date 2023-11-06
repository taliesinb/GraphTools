PublicFunction[MarkdownFrontMatter]

MarkdownFrontMatter[path_Str | File[path_Str]] := Scope[
  
  path //= NormalizePath;

  If[!FileExistsQ[path], ReturnFailed[]];

  str = ReadString[path];

  If[StringStartsQ[str, "{"],
    jsonStr = FirstStringCase[str, json:(StartOfString ~~ "{\n" ~~ Shortest[___] ~~ "\n}\n") :> json];
    If[StringQ[jsonStr],
      res = ReadRawJSONString @ jsonStr;
      res = res /. Null -> None;
      If[AssocQ[res], Return @ res]
    ];
  ];

  None
];

(**************************************************************************************************)

PrivateFunction[getMarkdownUnixTime]

getMarkdownUnixTime[path_Str] := Scope[
  Quiet[
    stream = OpenRead[path];
    line = PN @ ReadList[stream, "String", 2];
    Close[stream];
  ];
  If[!StringQ[line], Return[None]];
  matches = StringCases[line, "unixtime\":" ~~ d:DigitCharacter.. :> d, 1];
  If[matches === {}, Return[None]];
  FromDigits @ P1 @ matches
];

(**************************************************************************************************)

PublicFunction[NotebookFrontMatter]

NotebookFrontMatter[_] := $Failed;

NotebookFrontMatter[nb_NotebookObject] :=
  NotebookFrontMatter @ NotebookFileName @ nb;

$frontMatterMetadataCache = UAssoc[];

(* TODO: deal with notebooks that have changed in FE but haven't been saved yet! *)
NotebookFrontMatter[path_Str | File[path_Str]] := Scope[
  
  path //= NormalizePath;
  fileDate = FileDate @ path;
  
  result = Lookup[$frontMatterMetadataCache, path, None];
  If[AssocQ[result],
    cachedDate = Lookup[result, "unixtime", 0];
    If[cachedDate === UnixTime[fileDate], Goto[Done]];
  ];

  filebase = FileBaseName @ path;

  numbering = StringTrim @ FirstStringCase[filebase, DigitCharacter.. ~~ " ", ""];
  weight = If[numbering === "", 999, FromDigits @ numbering];

  {title, subTitle, taggingRules} = getNotebookData[path];
  SetNone[title, trimNumberPrefix @ filebase];
  fileDate = DatePlus[fileDate, -1]; (* to force Hugo to render the page *)
  dateString = DateString[fileDate, {"Year", "-", "Month", "-", "Day"}];

  result = Assoc[
    "unixtime" -> UnixTime @ fileDate,
    "date" -> dateString,
    "weight" -> weight,
    "title" -> title,
    "summary" -> subTitle,
    "notebookpath" -> path,
    KeySelect[taggingRules, StringQ[#] && LowerCaseQ[StringTake[#, 1]]&]
  ];

  $frontMatterMetadataCache[path] ^= result;

  Label[Done];

  result["relativepath"] = ReplaceNone[RelativePath[$notebookPath, FileNameDrop @ path], ""];

  If[$frontMatterFunction =!= None,
    result //= $frontMatterFunction;
  ];

  result
];

getNotebookData[path_Str] := Scope[
  nb = Get @ path;
  title = FirstCase[nb, Cell[title_Str, "Title"|"Chapter"|"Section", ___] :> title, None, Infinity];
  subTitle = FirstCase[nb, Cell[subtitle_Str, "Subtitle", ___] :> subtitle, None, Infinity];
  SetNone[subTitle, notebookFirstLine @ nb];
  taggingRules = LookupOption[nb, TaggingRules];
  If[RuleListQ[taggingRules], taggingRules //= Assoc];
  SetAutomatic[taggingRules, <||>];
  KeyDropFrom[taggingRules, "TryRealOnly"];
  {title, subTitle, taggingRules}
];

notebookFirstLine[nb_] :=
  FirstCase[nb,
    Cell[b_ /; FreeQ[b, _GraphicsBox], "Text", ___] :>
      With[{res = boxesFirstLine @ b}, res /; StringLength[res] > 5],
    None, Infinity
  ];

boxesFirstLine[b_] := Scope[
  str = Quiet @ CatchMessage @ textCellToMarkdown @ b;
  If[!StringQ[str], Return[None]];
  split = StringSplit[str, w:("." | "?" | "!" | "...") ~~ (EndOfString | EndOfLine | WhitespaceCharacter) :> w, 2];
  StringTrim @ StringJoin @ Take[split, UpTo[2]]
];