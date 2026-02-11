#!/bin/bash -xv
cp ./cvForOfferRulesFile_default.txt ./cvForOfferRulesFile.txt
echo  >> ./cvForOfferRulesFile.txt
echo "================================================================================================" >> ./cvForOfferRulesFile.txt
echo  >> ./cvForOfferRulesFile.txt
cat ./cvForOfferRulesFile_$1.txt >> ./cvForOfferRulesFile.txt
cat ./cvForOfferRulesFile.txt | more
