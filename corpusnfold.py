#	       (c) Centre for Development of Advanced Computing, Mumbai
#	    Knowledge Based Computer Systems Division. All Rights Reserved. 

#!/usr/bin/python
#Craeted by Raj Nath Patel Nov 5, 2014
#Usage: To get N fold ref, test and training data

import array
import random                                                               
import sys
import os


fold = int(sys.argv[3])
file1, ext1 = os.path.splitext(sys.argv[1])
file2, ext2 = os.path.splitext(sys.argv[2])

fin1=open(sys.argv[1])
fin2=open(sys.argv[2])

lines1 = fin1.readlines()
lines2 = fin2.readlines()


testout1 = open("test1"+ext1 , 'w')
testout2 = open("ref1"+ext2, 'w')

trainout1 = open("train1"+ext1 , 'w')
trainout2 = open("train1"+ext2, 'w')

l = len(lines1)

#Testing size = 5% of whole data
test = l/100*5

a = array.array('I', xrange(l))  # a.itemsize indicates 4 bytes per element => about 0.5 GB
random.shuffle(a)
#line = random.choice(fin.readlines())
#print line


k=0
j=1
for i in a:
	if(j == fold + 1):
		break
	if(k == test):
		k = 0
		j += 1
		for m in range(l):
			if(lines1[m] != ""):
				trainout1.write(lines1[m])
				trainout2.write(lines2[m])
		
		fin1=open(sys.argv[1])
		fin2=open(sys.argv[2])

		lines1 = fin1.readlines()
		lines2 = fin2.readlines()
		if(j != fold + 1):
			trainout1 = open("train"+str(j)+ext1 , 'w')
			trainout2 = open("train"+str(j)+ext2, 'w')
			testout1 = open("test"+str(j)+ext1, 'w')
			testout2 = open("ref"+str(j)+ext2, 'w')
	else:
		testout1.write(lines1[i])
		testout2.write(lines2[i])
		lines1[i] = ""
		lines2[i] = ""
		k +=1
	#index = random.randrange(0, 49946) 
	#data = [ (random.random(), line) for line in fin ]
	#data.sort()
	#for _, line in data:
        #	print line,
