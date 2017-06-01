#!/bin/bash
#################################################
#################################################
# create nodes
# designed to help create puppet manifests
# May 31 2017  SGT-IMOC-II
#################################################
#################################################
#
IFSORIG=$IFS
IFS="
"
C50="#################################################"
tmp1="/tmp/tmp1.txt"
tmp2="/tmp/tmp2.txt"           # temp file
tmp3="/tmp/tmp3.txt"           # usable output
FIN=""                         # file variable
FINMAX=0                       # file lines total
DF=""                          # destination file
MMAN=""
SHN=""                         # node for shownodes
#################################################
function helpme {
echo ${C50}
echo " -h help display "
echo " -f read input file "
echo ${C50}
echo " Example file contents , comma delimted: arg1 FQDN,arg2-10 puppet manifests"
echo "ssc1.ssc.jsl.nasa.gov,include jalapeno::alextest1,include testmod "
echo "ssc2.ssc.jsl.nasa.gov,include jalapeno::alextest2,include testmod "
echo "ssc3.ssc.jsl.nasa.gov,include jalapeno::alextest3,include testmod "
echo ${C50}
echo " -d [client|pluto] destination-file required with -f , -m and no args "
echo " -d has one time backup of last version   "
echo " -s [client|pluto] will display the configuration file on the screen "
echo " -m  manual mode one server ssc1.ssc.jsl.nasa.gov,include jalapeno::alextest1,include testmod "
echo " NO ARGS  Runs default of nothing in all 23 ssc clients"
echo " NO ARGS  /tmp/tmp3.txt is the output you need         "
}
#################################################
function destination {
NODE=$1
TFIL1=""
case "$1" in
       client)
          TFILE="/etc/puppet/manifests/nodes/ssc-client_node.pp"
           ;;
       pluto)
          TFILE="/etc/puppet/manifests/nodes/ssc-pluto_node.pp"
          ;;
       *)
          echo "client or pluto options destination function failed [$NODE]"
          exit 1
esac
DF=$TFILE
if [ -f ${DF} ]; then
   cp -f ${DF} ${DF}.last
   cp -f /tmp/tmp3.txt ${DF} && chmod 777 ${DF}
   echo "Update ${DF} Complete..."
else
  echo "I can not find path/file ${DF} exiting.........." && exit 1
fi 
}
#################################################
function readinfile {
if [ -f $1 ]; then
 IFS=$IFS
 FIN=($(cat $1))
else
 echo "$1 No such file found ...... " && exit 1
fi
}
#################################################
function isnasa {
ISIT=$(echo $1 |tr '[:upper:]' '[:lower:]' |  grep -c "nasa.gov")
echo $ISIT
}
#################################################
function crnode {
#echo "[CRNODE $1, $2, $3, $4, $5,]"
echo  "" > ${tmp1} && echo -n "" > ${tmp2} 
echo ${C50} >> ${tmp1}
for i in "$@"
do
 if [ $(isnasa $i) -gt 0  ]; then
    echo  "node '$1' {" >> ${tmp1}
 else
    echo  " $i" >> ${tmp2}
 fi 
done
echo "}" >> ${tmp2}
cat ${tmp1} >> ${tmp3}
cat ${tmp2} >> ${tmp3}
}
#################################################
function crnodeFIN {
IFS=$IFS
echo  "" > ${tmp1} && echo -n "" > ${tmp2} 
echo ${C50} >> ${tmp1}
for lines in ${FIN[@]}
do 
#  echo "lines=$lines"
  IFS=,
  for z in $lines
   do
      if [ $(isnasa "$z") -gt 0  ]; then
         echo  "node '$z' {" >> ${tmp1}
      else
         echo  " $z" >> ${tmp2}
      fi 
  done
echo "}" >> ${tmp2}
cat ${tmp1} >> ${tmp3}
cat ${tmp2} >> ${tmp3}
echo -n "" > ${tmp1} && echo -n "" > ${tmp2} 
echo ${C50} >> ${tmp1}
done
}
#################################################
function mannode {
INP=$1
echo  "" > ${tmp1} && echo -n "" > ${tmp2} 
echo ${C50} >> ${tmp1}
  IFS=,
  for y in $INP
   do
      if [ $(isnasa "$y") -gt 0  ]; then
         echo  "node '$y' {" >> ${tmp1}
      else
         echo  " $y" >> ${tmp2}
      fi 
  done
echo "}" >> ${tmp2}
cat ${tmp1} >> ${tmp3}
cat ${tmp2} >> ${tmp3}
echo -n "" > ${tmp1} && echo -n "" > ${tmp2} 
echo ${C50} >> ${tmp1}
}
#################################################
function chknodes {
NODE=$1
case "$1" in
       client)
          cat /etc/puppet/manifests/nodes/ssc-client_node.pp
           ;;
       pluto)
          cat /etc/puppet/manifests/nodes/ssc-pluto_node.pp
          ;;
       *)
          echo "client or pluto options  chknodes function failed [$NODE]"
          exit 1
esac
}
#################################################
#################################################
#################### MAIN #######################
#################################################
echo -n "" > ${tmp1} && echo -n "" > ${tmp2} && echo -n > ${tmp3}
while getopts ":hf:d:s:m:" FLAG; do
        case "${FLAG}" in 
             h) # help
                helpme
                exit 1
                ;;
             f) # read source  file as input 
                RIF="${OPTARG}"
                readinfile ${RIF}
                crnodeFIN 
                ;;
             d) # destination output file  
                DST="${OPTARG}"
                destination ${DST} 
               ;;
             s) # show node configuration
                SHN="${OPTARG}"
                chknodes ${SHN} # client or pluto only #
                ;;
             m) # manual mode 
                MMAN="${OPTARG}"
                mannode ${MMAN}
               ;; 
            \?) ;;
             :) ;;
        esac
done
if [ -z "${RIF}"  ] && [ -z "${MMAN}" ] ; then

#######################################################
echo "Warning...... This will write blank nodes to all 24 ssc-clients "
select yn in "Yes" "No"; do
    case $yn in
        Yes ) echo "[OK]"; break;;
        No ) exit;;
    esac
done





########################################################
for  i in {1..24} 
 do
   sname=$(echo -n "ssc${i}")
    crnode "${sname}.ssc.jsl.nasa.gov"
#   crnode "${sname}.ssc.jsl.nasa.gov" "include roles::alextest1" "include testmod" 
 done
destination client
fi # end of RIF
#crnode "ssc1.ssc.jsl.nasa.gov" "include roles::alextest1" "include testmod" "include terrymod" "include alexmod"dd
#################################################
