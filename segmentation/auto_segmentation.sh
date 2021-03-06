#!/bin/bash
echo "Starting auto segmentation in folder: "$1
echo "Extra params: "$2" "$3" "$4
cd ..
CURR_PCL=0
TOT_N_PCLS=0
for P in `ls -vd $1*.ply`;
do 	 
	TOT_N_PCLS=$((TOT_N_PCLS+1))
done
for P in `ls -vd $1*.ply`;
do 	 
	CURR_PCL=$((CURR_PCL+1))
	NAME_LENGTH=`expr ${#P} - 12`
	P_NAME=`expr substr $P 22 $NAME_LENGTH`
	TYPELESS_FILEPATH_SIZE=`expr ${#P} - 4`
	PCD_TYPE='pcd'
	TYPELESS_FILEPATH=`expr substr $P 1 $TYPELESS_FILEPATH_SIZE`
	PCD_FILEPATH=$TYPELESS_FILEPATH'.pcd'
	PLY_FILEPATH=$TYPELESS_FILEPATH'.ply'
	~/pcl/release/bin/pcl_ply2pcd $PLY_FILEPATH $PCD_FILEPATH $TYPELESS_FILEPATH
	echo ~/pcl/release/bin/pcl_example_cpc_segmentation $PCD_FILEPATH -cut 1,400,0.16 -s 0.015 -v 0.0075 -clocal -cdir -smooth 10 -loop $CURR_PCL,$TOT_N_PCLS -o $TYPELESS_FILEPATH -write $2
	~/pcl/release/bin/pcl_example_cpc_segmentation $PCD_FILEPATH -cut 1,400,0.16 -s 0.015 -v 0.0075 -clocal -cdir -smooth 10 -loop $CURR_PCL,$TOT_N_PCLS -o $TYPELESS_FILEPATH -write $2	
done
echo "Done with autosegmentation in "$1

