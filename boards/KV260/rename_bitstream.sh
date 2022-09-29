#!/bin/bash

pushd overlay/

sed -i 's/8014/8012/g' $(ls *pr_0*.hwh)
sed -i 's/8013/8012/g' $(ls *pr_0*.hwh)
sed -i 's/8014/8013/g' $(ls *pr_1*.hwh)
sed -i 's/8012/8013/g' $(ls *pr_1*.hwh)
sed -i 's/8012/8014/g' $(ls *pr_2*.hwh)
sed -i 's/8013/8014/g' $(ls *pr_2*.hwh)

com=$(ls composable*)

for i in ${com}
do
    mNewFName=$(echo ${i} | sed 's/inst\_0/partial/')
    mv ${i} cv_dfx_3_pr_${mNewFName}
done

cp ../default_paths.json overlay/cv_dfx_3_pr_paths.json

popd