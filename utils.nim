import chrono, strutils, os, times, strformat, json


let config* = parseJson(readFile("blogconfig.json"))
let
  srcDir* = config["src_dir"].getStr()
  mdDir* = srcDir / "md"
  jsonDir* = srcDir / "json"
  imgDir* = srcDir / "img"
  jsDir* = srcDir / "js"
  cssDir* = srcDir / "css"
  htmlDir* = srcDir / "html"

  bucketName* = config["bucket_name"].getStr()
  bucketFolder* = config["bucket_folder"].getStr()
  blogTitle* = config["blog_title"].getStr()


if not dirExists(htmlDir): createDir(htmlDir)
if not dirExists(srcDir): createDir(srcDir)
if not dirExists(mdDir): createDir(mdDir)
if not dirExists(jsonDir): createDir(jsonDir)
if not dirExists(imgDir): createDir(imgDir)
if not dirExists(jsDir): createDir(jsDir)
if not dirExists(cssDir): createDir(cssDir)
if not dirExists(htmlDir): createDir(htmlDir)

proc parseGoogleTs*(timeStr: string): TimeStamp =
  let timeStr = timeStr.split(".")[0]
  return parseTs("{year/4}-{month/2}-{day/2}T{hour/2}:{minute/2}:{second}", timeStr)


proc replaceAtStart*(s, a, b: string): string =
  if not s.startsWith(a):
    raise newException(Exception, &"Can't replace, string \"{s}\" does not start the match \"{a}\".")
  return b & s[a.len .. ^1]


proc fileModTime*(filePath: string): float =
  if fileExists(filePath):
    return getLastModificationTime(filePath).toUnix().float