
install nim:
> curl https://nim-lang.org/choosenim/init.sh -sSf | sh

run server
> cd src
> python -m SimpleHTTPServer

goto this page http://localhost:8000/

download md files from google docs
> ~/.nimble/bin/nim c -r downloader.nim

compile md files into html files
> ~/.nimble/bin/nim c -r generator.nim

upload html files to live server
> ~/.nimble/bin/nim c -r uploader.nim

do everthing at once
> ~/.nimble/bin/nim c -r sync.nim