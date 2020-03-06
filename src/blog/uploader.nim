import
  strformat, json, tables, osproc, streams, os, times, strutils, algorithm,
  chrono, print, json, math, tables, times, strformat, asyncdispatch, httpclient,
  md5, base64
import googleapi/storage, googleapi/connection
import utils


proc md5base64(data: string): string =
  for d in toMD5(data):
    result.add char(d)
  return base64.encode(result)


proc upload*() =
  var conn = waitFor newConnection(config["service_account"].getStr())

  var md5s = newTable[string, string]()
  var listing = waitFor conn.list(bucketName, "")
  if "items" in listing:
    for fileMeta in listing["items"]:
      md5s[fileMeta["name"].getStr()] = fileMeta["md5Hash"].getStr()
    echo "looking at ", listing["items"].len, " files"

  for file in walkDirRec(htmlDir):
    if file.endsWith(".html") or file.endsWith(".css") or file.endsWith(".js") or file.endsWith(".jpg") or file.endsWith(".png") or file.endsWith(".txt") or file.endsWith(".woff") or file.endsWith(".woff2"):
      let filePath = file
      let uploadPath = (bucketFolder / filePath.replaceAtStart(htmlDir, "")[1 .. ^1]).replace("\\", "/")
      let data = readFile(filePath)
      if uploadPath notin md5s or md5base64(data) != md5s[uploadPath]:
        if uploadPath in md5s:
          echo "local:", md5base64(data)
          echo "cloud:", md5s[uploadPath]
        var err = waitFor conn.upload(bucketName, uploadPath, readFile(filePath))
        print "uploaded ", uploadPath

when isMainModule:
  upload()
