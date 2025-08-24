:: Debug Build  
:: NOTE: We don't use subsystem:windows,
:: because on windows terminal, when excuting the subsystem:windows exe
:: won't wait it finish, need to type start /wait yourapp, but nobody want to do that.
:: https://stackoverflow.com/questions/15952892/using-the-console-in-a-gui-app-in-windows-only-if-its-run-from-a-console
::--subsystem:windows

::
odin build src -out:build/game.exe -debug -collection:libs=./src/libs/^
    -vet-shadowing -vet-semicolon 
