import os, strutils, algorithm, sequtils, re, chrono, strformat, osproc, times, json
import markdown
import utils


let index = readFile(srcDir / "index.md")
let preview = readFile(srcDir / "preview.md")
let error404 = readFile(srcDir / "404.md")

var mainIndex = ""


type BlogEntry = object
  date: Timestamp
  slug: string
  file: string
  title: string
  picture: string
  md: string

proc generate*() =
  var blogs: seq[BlogEntry]
  for file in walkFiles(mdDir / "*.md"):
    #echo file
    var blog = BlogEntry()
    blog.file = file.replace("\\","/")
    blog.slug = file.lastPathPart().changeFileExt("")
    blog.md = readFile(file)
    let arrs = blog.md.findAll(re"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec).*,.*20.*")
    if arrs.len > 0:
      let dateAuthor = arrs[0].split(" by ")
      #echo dateAuthor[0]
      blog.date = parseTs("{month/n/3} {day}, {year}", dateAuthor[0])
    let arrs2 = blog.md.findAll(re"# (.*)")
    if arrs2.len > 0:
      blog.title = arrs2[0][2..^1]
    let arrs3 = blog.md.findAll(re"\!\[\]\((.*image_.*)\)")
    if arrs3.len > 0:
      blog.picture = arrs3[0][4..^2]
    if blog.picture == "":
      blog.picture = "img/not_found.png"
    blogs.add(blog)

  blogs.sort proc(a, b: BlogEntry): int = cmp(b.date, a.date)

  for blog in blogs:
    let htmlFile = htmlDir / blog.slug & ".html"

    if fileModTime(blog.file) > fileModTime(htmlFile):
      var htmlMd = markdown(blog.md)
      var html = index.replace("<!-- page content -->", htmlMd)
        .replace("<!-- title -->", blog.title)
      writeFile(htmlFile, html)

    if "draft" notin blog.title:
      var blogPreview = preview
      blogPreview = blogPreview.replace("<!-- url -->", blog.slug & ".html")
      blogPreview = blogPreview.replace("<!-- title -->", blog.title)
      blogPreview = blogPreview.replace("<!-- date -->", blog.date.format("{month/n/3} {day}, {year}"))
      blogPreview = blogPreview.replace("<!-- picture -->", blog.picture)
      mainIndex.add blogPreview

  var html = index.replace("<!-- page content -->", mainIndex)
    .replace("<!-- title -->", blogTitle)
  writeFile(htmlDir / "index.html", html)

  echo "generated ", blogs.len, " blogs"

  var html404 = index.replace("<!-- page content -->", markdown(error404))
    .replace("<!-- title -->", blogTitle)
  writeFile(htmlDir / "404.html", html404)

  copyDir(srcDir / "imgs", htmlDir / "img")
  copyDir(imgDir, htmlDir / "img")
  copyDir(imgDir, htmlDir / "font")
  copyDir(jsDir, htmlDir / "js")
  copyDir(cssDir, htmlDir / "css")

if isMainModule:
  generate()




