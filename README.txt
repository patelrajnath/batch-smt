CDACM-KBCS n-fold-cross-validation - 2014-11-05
----------------------------------------------

This package provides a fram-work for automatic evaluation of Statistical Machine Translation System with n-folds.

(c) 2014-2024. Centre for Development of Advanced Computing, Mumbai
Knowledge Based Computer Systems Division. All Rights Reserved. 

Original code by Raj Nath Patel.

The software is licensed under the GPL V3. Please see the file LICENSE.txt

For more information, bug reports, and fixes, contact:
    Raj Nath Patel / Prakash Pimpale
    CDAC, Rain tree marg, sector 7, CBD Belapur Navi Mumbai - 400614
    India
    rajnathp@cdac.in/prakash@cdac.in
    http://kbcs.in/

CONTACT

For questions about this distribution, please contact KBCS, CDAC Mumbai at sasi@cdac.in. We provide assistance on a best-effort basis.

PRE-REQUISIT

	- Linux operating system
	- 'GIZA++' should be installed
	- 'Moses decoder' (version 1.9 or above) should be installed
	- 'gunzip' should be installed(install using 'yum' or 'apt-get' command: #yum install zip unzip)
	- 'sed' should be installed(install using 'yum' or 'apt-get' command: #yum install sed)

DEPENDENCY INSTALLATION
	-GIZA++ installation
		-Download system(http://code.google.com/p/giza-pp/downloads/list)
		-Extract and change directory to "giza-pp"
			$cd giza-pp
		-Compile the code as instructed in README 
					or
			For basic installation run
			$make

		-Create directory "bin"
		-Copy GIZA++, snt2cooc.out and mkcl to bin directory
			$cp GIZA++-v2/GIZA++ ./bin
			$cp GIZA++-v2/snt2cooc.out ./bin
			$cp mkcls-v2/mkcls ./bin

	-MOSES installation
		-Download MOSES(https://github.com/moses-smt/mosesdecoder/tree/RELEASE-2.1.1)
		-Extract the download
		-Follow the instruction in BUILD-INSTRUCTIONS.txt 
					or			
			For basic installation run
			$./bjam -jN 4 
				//4 is number of CPUs, change acoordingly

SYSTEM INSTALLATION-

	#Change whare you want to install systems
		In my case its-
		"WORKDIR=/some path/current dir/s1"
 
	#Change bin directory where GIZA++ is installed
		In my case its-
		BIN=/home/anuvad/smt/decoder/bin
 
	#Change "MOSES_HOME" according moses installation dir w.r.t. your system
		In my case its-
		"MOSES_HOME=/home/raj/smt/decoder/mosesdecoder-RELEASE-2.1.1/"

USE

	Usage:
		$bash <SYSTEM-SCRIPT> -s <SOURCE-FILE> -t <TARGET-FILE> -r <ROOT-DIRECTORY> -f <FOLDS>
	
	SAMPLE Usage 1:
		To train 3-fold validation test
 		$bash n-fold-validation.sh -s sample-corpus/corpus.eng -t sample-corpus/corpus.hin -r s1 -f 3
 
RESULTS

	Individual system testing is done in "eval" dir of respective systems. (Eg: for system "1" it will be at "s1/1/eval"). Consolidated results will be in "s1/results"

HELP

	#To know about 'n-fold-validation.sh', run
 		$bash n-fold-validation.sh
			or
 		$bash n-fold-validation.sh -h

--------------------
CHANGES
--------------------

2014-11-26      1.0   Initial release
