import
  strformat, json, tables, osproc, streams, os, times, strutils, algorithm, re, unicode,
  chrono, print, json, math, tables, times, strformat, asyncdispatch, httpclient,
  googleapi/documents, googleapi/connection, googleapi/drive

import utils

proc slugify(s: string): string =
  const a = ["à", "á", "ä", "â", "ã", "å", "ă", "æ", "ç", "è", "é", "ë", "ê", "ǵ", "ḧ", "ì", "í", "ï", "î", "ḿ", "ń", "ǹ", "ñ", "ò", "ó", "ö", "ô", "œ", "ø", "ṕ", "ŕ", "ß", "ś", "ș", "ț", "ù", "ú", "ü", "û", "ǘ", "ẃ", "ẍ", "ÿ", "ź", "·", "/", "_", ",", ":", ";"]
  const b = ["a", "a", "a", "a", "a", "a", "a", "a", "c", "e", "e", "e", "e", "g", "h", "i", "i", "i", "i", "m", "n", "n", "n", "o", "o", "o", "o", "o", "o", "p", "r", "s", "s", "s", "t", "u", "u", "u", "u", "u", "w", "x", "y", "z", "-", "-", "-", "-", "-", "-"]
  for c in s.runes:
    let cstr = c.toUTF8()
    if cstr == "&" or cstr == "+":
      if result[^1] != '-': result.add '-'
      result.add "and-"
    elif cstr == "-":
      if result[^1] != '-': result.add '-'
    elif cstr == "'" or cstr == "’":
      continue
    elif cstr.len == 1 and cstr[0] in {'A'..'Z', 'a'..'z', '0'..'9', '_', '.'}:
        result.add cstr.toLowerAscii()
    else:
      let replaceIndex = a.find(cstr)
      if replaceIndex != -1:
        result.add b[replaceIndex]
      else:
        if result[^1] != '-': result.add '-'
  if result[^1] == '-': result.setLen(result.len - 1)

assert slugify("hi there how are you?") == "hi-there-how-are-you"
assert slugify("àǹdré the gaint") == "andre-the-gaint"
assert slugify("Update: v.2.3.4 + new things!") == "update-v.2.3.4-and-new-things"
assert slugify("new - old") == "new-old"
assert slugify("don't think about it") == "dont-think-about-it"


proc docJsonToMD(filePath: string, docJson: JsonNode) {.async.} =
  var md = ""
  for section in docJson["body"]["content"]:
    if "paragraph" in section:
      let styleType = section["paragraph"]["paragraphStyle"]["namedStyleType"].getStr()
      case styleType:
        of "TITLE":
          md.add "## "
        of "HEADING_1":
          md.add "## "
        of "HEADING_2":
          md.add "### "
        of "HEADING_3":
          md.add "#### "
        of "HEADING_4":
          md.add "##### "
        of "SUBTITLE":
          md.add "###### "
        else:
          discard
      if "bullet" in section["paragraph"]:
          md.add "* "
      for element in section["paragraph"]["elements"]:
        if "textRun" in element:
          if "link" in element["textRun"]["textStyle"]:
            let url = element["textRun"]["textStyle"]["link"]["url"].getStr()
            if url.startsWith("https://www.youtube.com"):
              let youtubeUrl = url.replace("watch?v=", "embed/")
              md.add &"""<div class="video-container"><iframe width="853" height="480" src="{youtubeUrl}" frameborder="0" allowfullscreen></iframe></div>"""
            else:
              md.add "[" & element["textRun"]["content"].getStr() & "](" & url & ")"
          else:
            md.add element["textRun"]["content"].getStr()
        if "inlineObjectElement" in element:
          let inlineObjectId = element["inlineObjectElement"]["inlineObjectId"].getStr()
          let url = docJson["inlineObjects"][inlineObjectId]["inlineObjectProperties"]["embeddedObject"]["imageProperties"]["contentUri"].getStr()
          let imgName = "image_" & inlineObjectId & ".jpg"
          let localFile = imgDir / imgName
          md.add &"![](img/{imgName})"
          var client = newAsyncHttpClient()
          echo " * ", localFile
          if not existsFile(localFile):
            await client.downloadFile(url, localFile)
      md.add "\n"

  writeFile(filePath, md)


proc download*() =
  var conn = waitFor newConnection(config["service_account"].getStr())

  proc processDoc(filePath, documentId: string) {.async.} =
    var docJson = await conn.getDocument(documentId)
    var fileName = docJson["title"].getStr()

    await docJsonToMD(filePath, docJson)
    writeFile(jsonDir / fileName & ".json", pretty docJson)
    echo filePath

  var list = waitFor conn.list("", @["files(id,name,mimeType,modifiedTime)"])

  echo "looking at ", list["files"].len, " docs"

  for file in list["files"]:
    let
      name = file["name"].getStr()
      mimeType = file["mimeType"].getStr()
      documentId = file["id"].getStr()
      modifiedTime = file["modifiedTime"].getStr()
      filePath = mdDir / slugify(name) & ".md"

    let modifiedTs = parseGoogleTs(modifiedTime)
    if mimeType == "application/vnd.google-apps.document":
      if fileExists(filePath):
        # echo ""
        let timeDiff = getLastModificationTime(filePath).toUnix().float - modifiedTs.float
        if timeDiff > 100:
          continue

      waitFor processDoc(filePath, documentId)
      echo "downloaded ", filePath


when isMainModule:
  download()
