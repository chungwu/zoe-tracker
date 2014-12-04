all: build build/index.html build/img build/scripts build/styles build/scripts/baby.js build/styles/baby.css

build:
	mkdir build

build/index.html: src/index.html
	sed "s/{{SPREADSHEET_KEY}}/$(SPREADSHEET_KEY)/" src/index.html > build/index.html

build/img:
	mkdir build/img
	cp -rp src/img/* build/img/

build/scripts:
	mkdir build/scripts
	cp -rp src/scripts/*.js build/scripts/

build/styles:
	mkdir build/styles
	cp -rp src/styles/*.css build/styles/

build/scripts/%.js: src/scripts/%.coffee
	coffee -c -o build/scripts/ $<

build/styles/%.css: src/styles/%.sass
	compass compile --sass-dir=./src/styles --css-dir=build/styles/ --images-dir=build/img --relative-assets $<

clean:
	rm -rf build