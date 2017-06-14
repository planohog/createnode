#!/bin/bash
#################################################
#################################################
# create nodes
# designed to help create puppet manifests
# June 14 2017 SGT-IMOC-II
# ver 02
#################################################
#################################################
# capturing original file seperator and loading \n
IFSORIG=$IFS
IFS="
"
C50="#################################################"
nodef1=$(mktemp)          # helps build final nodef3
nodef2=$(mktemp)          # helps build final nodef3
finalnodefile=$(mktemp)         # Final node file 
FIN=""                          # file variable
FINMAX=0                        # file lines total
DF=""                           # destination file
MMAN=""                         # manual mode variable
SHN=""                          # show nodes variable
NPATH="/etc/puppet/manifests/nodes" # path node files
#################################################
#       Function name and description           
# helpme:        Display a help menu            
# destination:   Selects client or pluto node file
# readinfile:    Used with -f switch to supply node info
# isnasa:        Used to grep for nasa.gov in node string
# crnode:        Used to create empty node file for 24 clients
# crnodeFIN:     Used to create node file with -f -d option  
# mannode:       Used to create node file with -m -d option
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
echo " example:"
echo "./createnode.sh -d client -f /tmp/newfile.txt"
echo ${C50}
echo " -d [client|pluto] destination-file required with -f , -m and no args "
echo " -d has one time backup of last version   "
echo " -s [client|pluto] will display the configuration file on the screen "
echo ${C50}
echo " -m  manual mode one server ssc1.ssc.jsl.nasa.gov,include jalapeno::alextest1,include testmod "
echo " example:"
echo " ./createnode.sh -d pluto -m \"ssc-pluto.ssc.jsl.nasa.gov\",\"include jalapeno::imsclient\" "
echo " NO ARGS prompts and  Runs default of nothing in all 23 ssc clients"
}
#################################################
function destination {
case "$1" in
       client)
          TFILE="${NPATH}/ssc-client_node.pp"
           ;;
       pluto)
          TFILE="${NPATH}/ssc-pluto_node.pp"
          ;;
       *)
          echo "client or pluto option only!  function=destination failed [$1]"
          exit 1
esac
#
if [ -f ${TFILE} ]; then
   cp -f ${TFILE} ${TFILE}.last
   cp -f ${finalnodefile} ${TFILE} && chmod 777 ${TFILE}
else
  echo "I can not find path/file ${NPATH}/${TFILE} exiting.........." && exit 1
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
echo  "" > ${nodef1} && echo -n "" > ${nodef2} 
echo ${C50} >> ${nodef1}
for i in "$@"
do
 if [ $(isnasa $i) -gt 0  ]; then
    echo  "node '$1' {" >> ${nodef1}
 else
    echo  " $i" >> ${nodef2}
 fi 
done
echo "}" >> ${nodef2}
cat ${nodef1} >> ${finalnodefile}
cat ${nodef2} >> ${finalnodefile}
}
#################################################
function crnodeFIN {
IFS=$IFS
echo  "" > ${nodef1} && echo -n "" > ${nodef2} 
echo ${C50} >> ${nodef1}
for lines in ${FIN[@]}
do 
  IFS=,
  for z in $lines
   do
      if [ $(isnasa "$z") -gt 0  ]; then
         echo  "node '$z' {" >> ${nodef1}
      else
         echo  " $z" >> ${nodef2}
      fi 
  done
echo "}" >> ${nodef2}
cat ${nodef1} >> ${finalnodefile}
cat ${nodef2} >> ${finalnodefile}
echo -n "" > ${nodef1} && echo -n "" > ${nodef2} 
echo ${C50} >> ${finalnodefile}
destination ${DST}
done
}
#################################################
function mannode {
INP=$1
[ -z ${INP} ] && echo "No Input -m manual mode , exiting ...." && exit 1
[ -z ${DST} ] && echo "No Destination -d selected , exiting ...." && exit 1
echo  "" > ${nodef1} && echo -n "" > ${nodef2} 
echo ${C50} >> ${nodef1}
IFS=,
  for y in $INP
   do
      if [ $(isnasa "$y") -gt 0  ]; then
         echo  "node '$y' {" >> ${nodef1}
      else
         echo  " $y" >> ${nodef2}
      fi 
  done
echo "}" >> ${nodef2}
cat ${nodef1} >> ${finalnodefile}
cat ${nodef2} >> ${finalnodefile}
echo -n "" > ${nodef1} && echo -n "" > ${nodef2} 
echo ${C50} >> ${finalnodefile}
destination ${DST}
}
#################################################
function chknodes {
NODE=$1
case "${NODE}" in
       client)
        if [ ! -s ${NPATH}/ssc-client_node.pp ]; then echo "${NPATH}/ssc-client_node.pp EMPTY"; else
          cat ${NPATH}/ssc-client_node.pp
        fi
           ;;
       pluto)
        if [ ! -s ${NPATH}/ssc-pluto_node.pp ]; then echo "${NPATH}/ssc-pluto_node.pp  EMPTY"; else
          cat ${NPATH}/ssc-pluto_node.pp
        fi
          ;;
       *)
          echo "client or pluto options only!!  chknodes function fail [$NODE]"
          exit 1
esac
}
#################################################
#################### MAIN #######################
#################################################
echo -n "" > ${nodef1} && echo -n "" > ${nodef2} && echo -n > ${finalnodefile}
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
            \?) echo "Un-Known Option, Thanks for Playing "; sleep 2 ; helpme; exit 1 ;;
             :)  ;;
        esac
done
if [ -z "${RIF}"  ] && [ -z "${MMAN}" ] && [ -z "${SHN}" ] ; then
#######################################################
echo "Warning...... This will write blank nodes to all 24 ssc-clients "
select yn in "Yes" "No" "Help"; do
    case $yn in
        Yes ) echo "[OK]"; break;;
        Help ) helpme ; exit ;;
        No ) exit;;
    esac
done
########################################################
for  i in {1..24} # 24 ssc clients
 do
    sname=$(echo -n "ssc${i}")
    crnode "${sname}.ssc.jsl.nasa.gov"
 done
destination client
fi # end of RIF
#######################################################
###################### END ############################
#######################################################
