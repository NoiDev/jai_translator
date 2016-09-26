
rm -rf build
mkdir build

(

    clang jtrans.c -o build/jtrans -O0 -g   2>&1    ## Debug
    #clang jtrans.c -o build/jtrans -O2     2>&1    ## Fast

) | tee "build/build.log";
