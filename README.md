
install nim:
```sh
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
```
run server
```sh
cd src
python -m SimpleHTTPServer
```

goto this page http://localhost:8000/

download md files from google docs
```sh
~/.nimble/bin/nim c -r downloader.nim
```

compile md files into html files
```sh
~/.nimble/bin/nim c -r generator.nim
```

upload html files to live server
```sh
~/.nimble/bin/nim c -r uploader.nim
```

do everthing at once
```sh
~/.nimble/bin/nim c -r sync.nim
```