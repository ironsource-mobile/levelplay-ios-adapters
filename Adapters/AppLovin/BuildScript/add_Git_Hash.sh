#!/bin/bash
set -e

version=$(git rev-parse --verify HEAD --short)

cd ..

  echo 'Adding Git Hash To '${PROJECT_DIR}''  
  cd ${PROJECT_DIR}/${PROJECT_NAME}
  sed -i -e 's/GitHash.*/GitHash = @"'$version'";/g' ${PROJECT_NAME}.h
  rm -f ${PROJECT_NAME}.h-e 
  cd ../BuildScript
  






printf '\e[1;32m%-6s\e[m\n' "<----==============================BUILD PASSED==============================---->"



