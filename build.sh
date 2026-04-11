mkdir -p build
cp -rf assets build/

odin build src -out:build/game -debug -collection:libs=./src/libs/ -collection:third_party=./src/third_party/ -vet-shadowing -vet-semicolon
