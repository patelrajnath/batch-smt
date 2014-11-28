#	        (c) Centre for Development of Advanced Computing, Mumbai
#	    Knowledge Based Computer Systems Division. All Rights Reserved. 

#!/bin/bash
#Created By Raj Nath Patel, Nov 7, 2014
#Purpos: Automatic n-fold cross validation

CURDIR=`pwd`

SYSDIR=`dirname $0`

#Change bin directory where GIZA++ is installed
BIN=/home/anuvad/smt/decoder/bin

#Change "MOSES_HOME" according moses installation dir w.r.t. your system
MOSES_HOME=/home/raj/smt/decoder/mosesdecoder-RELEASE-2.1.1/

MOSES_BIN=$MOSES_HOME/bin
SCRIPTS=$MOSES_HOME/scripts

WORKDIR=

usage()
{
cat << EOF
usage: $0 options

This script run n-fold validation test.

OPTIONS:
   -h      Show this message
   -t      Target Corpus
   -s      Source Corpus
   -r      Directory where systems will be installed
   -f      Number of folds(Min=1,Max=20)
EOF
}

#BL='\e[0;31m'
BL='\e[0;34m'
NC='\e[0m' # No Color

if [ $# -eq 0 ]
  then
    echo -e "${BL}No arguments supplied${NC}"
	usage
	exit 1
fi

src=
tgt=
fold=

while getopts “hs:r:t:f:” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         r)
             WORKDIR=$OPTARG
             ;;
         s)
             src=$OPTARG
             ;;
         t)
             tgt=$OPTARG
             ;;
         f)
             fold=$OPTARG
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

if [ -z "$src" ] || [ -z "$tgt" ] || [ -z  "$fold" ] || [ -z "$WORKDIR" ]
then
	usage
        exit 1
fi


#Check if path is absolute or not
if [[ "$WORKDIR" = /* ]]
then
	echo "Absolute path for working directory:$WORKDIR"
else
	WORKDIR=$CURDIR/$WORKDIR
	echo "Absolute path for working directory:$WORKDIR"
fi

#If work directory already exist delete it
if [ -d "$WORKDIR" ]; then
  rm -rf $WORKDIR
fi


#CLEANING corpus
cat $src |tr -d '|' > $src.clean
cat $src.clean |tr -d '[' > $src.clean.clean
cat $src.clean.clean |tr -d ']' > $src.clean.clean.clean

cat $tgt |tr -d '|' > $tgt.clean
cat $tgt.clean |tr -d '[' > $tgt.clean.clean
cat $tgt.clean.clean |tr -d ']' > $tgt.clean.clean.clean

mv $src.clean.clean.clean $src
mv $tgt.clean.clean.clean $tgt

rm -rf $src.*
rm -rf $tgt.*

#CREATING corpus
python $SYSDIR/corpusnfold.py $src $tgt $fold
#rm -rf train test ref lm
mkdir -p $WORKDIR/train $WORKDIR/test $WORKDIR/ref $WORKDIR/lm
mv ref* $WORKDIR/ref
mv train* $WORKDIR/train
mv test* $WORKDIR/test

src=$(basename $src)
echo $src
tgt=$(basename $tgt)
echo $tgt

ext1="${src##*.}"
ext2="${tgt##*.}"
echo $ext1
echo $ext2

#CREATING Language Models
for file in $WORKDIR/train/*.$ext2
do
    if [[ -f $file ]]; then
	echo $file
	$MOSES_HOME/bin/lmplz -o 2 -S 20% -T /tmp < $file > $file.5gram.arpa
	$MOSES_HOME/bin/build_binary $file.5gram.arpa $file.5gram.binary
    fi
done

mv $WORKDIR/train/*.binary $WORKDIR/lm
mv $WORKDIR/train/*.arpa $WORKDIR/lm


#Training n-fold systems
for i in `seq 1 $fold`;
do
	echo $i
	mkdir -p $WORKDIR/$i/corpus $WORKDIR/$i/lm
	cp $WORKDIR/train/*$i.* $WORKDIR/$i/corpus
	cp $WORKDIR/lm/*$i.* $WORKDIR/$i/lm

	$SCRIPTS/training/train-model.perl \
        -external-bin-dir $BIN \
        -root-dir $WORKDIR/$i \
        -corpus $WORKDIR/$i/corpus/train$i -f $ext1 -e $ext2 \
        -reordering msd-bidirectional-fe \
        -alignment grow-diag-final-and \
        -lm 0:5:$WORKDIR/$i/lm/train$i.$ext2.5gram.binary:8 \
        >& $WORKDIR/$i/trainig.out &
done

echo -e "${BL}Training Started for all $fold folds...${NC}"

for job in `jobs -p`
do
	while kill -0 $job >/dev/null 2>&1
	do
		echo -n '.'
		sleep 3
	done
done

echo -e "\n${BL}Training Completed!!!${NC}"

#Unzip phrase table for binrization
for i in `seq 1 $fold`;
do
	echo "Unzipping phrase table for system $i ..."
	gunzip $WORKDIR/$i/model/phrase-table.gz

done

for job in `jobs -p`
do
        wait $job || let "FAIL+=1"
done

#Binarizing
echo -e "\n${BL}Binarizing phrase table...${NC}"
for i in `seq 1 $fold`;
do

	export LC_ALL=C
	
	#Binarizing Reordering model
	$MOSES_BIN/processLexicalTable -in $WORKDIR/$i/model/reordering-table.wbe-msd-bidirectional-fe.gz \
	-out $WORKDIR/$i/model/reordering-table.wbe-msd-bidirectional-fe.gz.binary 2> $WORKDIR/$i/lex.log &
	
	#Binarizing Phrase table
	cat $WORKDIR/$i/model/phrase-table | sort | $MOSES_BIN/processPhraseTable -ttable 0 0 - -nscores 5 \
	-out $WORKDIR/$i/model/phrase-table  2> $WORKDIR/$i/tm.log &
done


echo -e "\n${BL}Binarization Started for all $fold folds...${NC}"
for job in `jobs -p`
do
        while kill -0 $job >/dev/null 2>&1
        do
                echo -n '.'
                sleep 3
        done
done


#Chnaging moses.ini, after binrizing

echo -e "\n${BL}Chnaging "moses.ini" for binarized tables...${NC}"

for i in `seq 1 $fold`;
do
	/bin/sed -i 's,phrase-table.gz,phrase-table,' "$WORKDIR/$i/model/moses.ini"
	/bin/sed -i 's,reordering-table.wbe-msd-bidirectional-fe.gz,reordering-table.wbe-msd-bidirectional-fe.gz.binary,' "$WORKDIR/$i/model/moses.ini"
	/bin/sed -i 's,PhraseDictionaryMemory,PhraseDictionaryBinary,' "$WORKDIR/$i/model/moses.ini"
done

for job in `jobs -p`
do
        wait $job || let "FAIL+=1"
done


#Testing 
for i in `seq 1 $fold`;
do
	mkdir -p $WORKDIR/$i/eval/
	cp $WORKDIR/test/test$i.$ext1 $WORKDIR/$i/eval
        $MOSES_BIN/moses -f $WORKDIR/$i/model/moses.ini -threads 4 < $WORKDIR/$i/eval/test$i.$ext1 > $WORKDIR/$i/eval/test$i.$ext1.out 2> $WORKDIR/$i/eval/err.log &
done


echo -e "\n${BL}Testing Started for all $fold folds... ${NC}"
for job in `jobs -p`
do
	while kill -0 $job >/dev/null 2>&1
	do
		echo -n '.'
		sleep 3
	done
done

#Evaluation
echo -e "\n${BL}Calculating BLEU...${NC}" 

for i in `seq 1 $fold`;
do	
        $SCRIPTS/generic/multi-bleu.perl $WORKDIR/ref/ref$i.$ext2 < $WORKDIR/$i/eval/test$i.$ext1.out > $WORKDIR/$i/eval/bleu.txt &
done


for job in `jobs -p`
do
        wait $job || let "FAIL+=1"
done

#Consolidating Results
echo -e "\n${BL}Consolidating Results...${NC}" 

mkdir -p $WORKDIR/results

let total=0
let var=0
for i in `seq 1 $fold`;
do
	cat $WORKDIR/$i/eval/bleu.txt 
	cat $WORKDIR/$i/eval/bleu.txt >> $WORKDIR/results/CONSOLIDATED-BLEU.txt
	
	var=$(cat $WORKDIR/$i/eval/bleu.txt |cut -d ',' -f1 |cut -d '=' -f2 |sed "s/ //g")
	echo "Variable=$var"
	total=$(bc <<< "scale=3;$total+$var") 
done

echo "Total=$total"
average=$(bc <<< "scale=3;$total/$fold")
echo "Average=$average" 
echo "Average=$average" >> $WORKDIR/results/CONSOLIDATED-BLEU.txt

echo -e "${BL}Done...${NC}" 

