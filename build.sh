rm -rf build
mkdir build
#clang jtrans.c -o build/jtrans -O0 -g   ## Debug
clang jtrans.c -o build/jtrans -O2     ## Fast
