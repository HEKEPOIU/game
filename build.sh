mkdir -p build
cp -rf assets build/

odin build src -out:build/game -debug -collection:libs=./src/libs/ -collection:thrid_party=./src/thrid_party/ -vet-shadowing -vet-semicolon
