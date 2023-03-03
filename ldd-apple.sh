#!/bin/bash 

# Checking if file is an executable
file $1 | grep executable
IS_EXECUTABLE=$?

if [ "$IS_EXECUTABLE" == "0" ]
then

  /bin/ls -lOL $1 | grep restricted
  IS_EXECUTABLE_RESTRICTED=$?
  if [ "$IS_EXECUTABLE_RESTRICTED" == "0" ]
  then
    echo "===== The executable $1 is restricted, so no information at runtime, sorry. More info at https://apple.co/3sDkQZJ"
    exit
  fi
  echo "========== Trying to execute the binary while printing library linked:"
  DYLD_PRINT_LIBRARIES=1 \
  DYLD_PRINT_LIBRARIES_POST_LAUNCH=1 \
  DYLD_PRINT_RPATHS=$1 \
  $1
  exit 0
fi

temp_unrestricted_source=$(mktemp /tmp/unrestricted.$(uuidgen).cpp)
temp_unrestricted_out="${temp_unrestricted_source}.exec"

# Creating source file for an unrestricted binary
echo "#include <stdio.h>
int main(int argc, char **argv, char **envp) {
    printf(\"%s\n\", \"========== Showing environment variables:\");
    while (*envp) {
        printf(\"%s\n\", *envp);
        envp++;
    }
    return 0;
}" > ${temp_unrestricted_source}

ALL_ARCHS_IN_BINARY=`lipo -info $1 | awk 'BEGIN{FS=":"}{print $3}'`

for arch in `echo $ALL_ARCHS_IN_BINARY`; do
  echo "===== Found $arch architecture"
  temp_unrestricted_out="${temp_unrestricted_out}.${arch}"

  echo "========== The following will be temporatily created:"
  echo $temp_unrestricted_source
  echo $temp_unrestricted_out

  # Very hard assumption that llvm keeps the target architecture name consistent
  clang $temp_unrestricted_source -target ${arch}-apple-macos11 -o $temp_unrestricted_out

  while getopts "r" OPTION; do
    case $OPTION in   
      r) export DYLD_PRINT_RPATHS=1;;
    esac
  done
  shift $((OPTIND-1))

  echo "========== Showing runtime library dependencies:"
  DYLD_PRINT_LIBRARIES=1 \
  DYLD_PRINT_LIBRARIES_POST_LAUNCH=1 \
  DYLD_INSERT_LIBRARIES=$1 \
  $temp_unrestricted_out

  rm -f $temp_unrestricted_out
done

rm -f $temp_unrestricted_source
