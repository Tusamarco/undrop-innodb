#!/bin/bash
#-x


############
# Data extraction wrapper
#
# Author Marco Tusa 
# Copyright (C) 2001-2003, 2014
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU GUNATTENDEDeneral Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# v1.1

ARGV="$@"
VERBOSE=0
DEBUG=0

SOURCEDIR="#"
DESTDIR="#"
EXECDIR="#"
LOCALPATH=`pwd`
DATABASE="test"
USER="#"
PASSWORD="#"
IP="#"
PORT="#"
SOCKET="#"
PHASE=0
RECOVERYMODE=U
FILTERBYTABLE="#"
ASKCONFIRMATION=0
UNATTENDED=0
CHUNKSIZE=200
CONFIRMDELDIR="n"
SCHEMA_RECOVERY=""
MYSQLMODE=5
#
# Use LSB init script functions for printing messages, if possible
#
log_success_msg=" [ \e[32mOK\e[39m ] \n"
#"/etc/redhat-lsb/lsb_log_message success"
log_failure_msg=" [ \e[91mERROR\e[39m ] \n"
#"/etc/redhat-lsb/lsb_log_message failure"
log_warning_msg=" [ \e[93mWARNING\e[39m ] \n"
#"/etc/redhat-lsb/lsb_log_message warning"


usage() {
printf "Valid options are \n";
printf " \t -s root_directory_for_page_files \n"
printf " \t -o destination_directory_for_data extract \n"
printf " \t -r executable_dir \n"
printf " \t -d database name to extract \n"
printf " \t -u MySQL user \n"
printf " \t -p MySQL password \n"
printf " \t -i MySQL IP \n"
printf " \t -x MySQL Port\n"
printf " \t -k socket \n"
printf " \t -v verbose mode  \n"
printf " \t -A [0|1] ask for confirmation when extracting a table  \n"
printf " \t -U [0|1] Unattended if set to 1 will run the whole process assuming YES is the answer to all questions  \n"
printf " \t -P Phase to start from:\n \t1 ibdata extract;\n \t2 compile table_def;\n \t3 run only table extraction  \n"
printf " \t -m recovery mode [U undeleted | D deleted]  \n"
printf " \t -M MySQL c_parser mode (default 5)\n \t\t -4  -- innodb_datafile is in REDUNDANT format\n \t\t -5  -- innodb_datafile is in COMPACT format\n \t\t -6  -- innodb_datafile is in MySQL 5.6 format \n"
printf " \t -F filter by <table_name>  \n"
printf "run_data_extraction.sh -v -A 1 -F salaries -d employees -u stress -p tool -i 192.168.0.35 -x 5510 -s /home/mysql/instances/my56test1_recovery_PLMC -o /home/mysql/instances/my56test1_recovery_PLMC -r /home/mysql/recoverycode"
printf "\n"
}


if [ $# -lt 6 ] ; then
	echo 'Too few arguments supplied'
	usage
	exit 1
fi


#Reading the incoming options

    echo "###################################################"
while getopts ":s:o:r:d:u:p:i:x:k:P:r:F:A:U:S:m:M:v" opt; do
  case $opt in
    v)
       VERBOSE=1
       ;;
    A)
       ASKCONFIRMATION=$OPTARG;
       if [ $VERBOSE -eq 1  ] ; then
           echo "ASKCONFIRMATION = $ASKCONFIRMATION"
       fi
       ;;
    U)
       UNATTENDED=$OPTARG;
       if [ $VERBOSE -eq 1  ] ; then
           echo "UNATTENDED active"
       fi
       ;;

    s)
       SOURCEDIR=$OPTARG 

       if [ $VERBOSE -eq 1  ] ; then
           echo "Source DIR is set to $SOURCEDIR"
       fi
       ;;
    o)
       DESTDIR=$OPTARG

       if [ $VERBOSE -eq 1  ] ; then
           echo "Destination DIR is set to $DESTDIR"
       fi
       ;;
    r)
       EXECDIR=$OPTARG
       if [ $VERBOSE -eq 1  ] ; then
           echo "Execution DIR is set to $EXECDIR"
       fi
       ;;
    d)
       DATABASE=$OPTARG
       SCHEMA_RECOVERY=$DATABASE
       if [ $VERBOSE -eq 1  ] ; then
           echo "Database to extract is set to $DATABASE"
       fi
       ;;
    u)
       USER=$OPTARG
       if [ $VERBOSE -eq 1  ] ; then
           echo "USER to extract is set to $USER"
       fi
       ;;
    p)
       PASSWORD=$OPTARG
       if [ $VERBOSE -eq 1  ] ; then
           echo "PASSWORD to extract is set to $PASSWORD"
       fi
       ;;
    i)
       IP=$OPTARG
       if [ $VERBOSE -eq 1  ] ; then
           echo "IP to extract is set to $IP"
       fi
       ;;

    x)
       PORT=$OPTARG
       if [ $VERBOSE -eq 1  ] ; then
           echo "PORT to extract is set to $PORT"
       fi
       ;;

    k)
       SOCKET=$OPTARG
       if [ $VERBOSE -eq 1  ] ; then
           echo "SOCKET to extract is set to $SOCKET"
       fi
       ;;
      
    P)
       PHASE=$OPTARG
       if [ $VERBOSE -eq 1  ] ; then
           echo "Running From phase $PHASE"
       fi
       ;;
       
    m)
       RECOVERYMODE=$OPTARG
       if [ $VERBOSE -eq 1  ] ; then
           echo "Running using recovery mode $RECOVERYMODE"
       fi
       ;;
    M)
       MYSQLMODE=$OPTARG
       if [ $VERBOSE -eq 1  ] ; then
           echo "Running using MySQL c_parser mode $MYSQLMODE"
       fi
       ;;

    F)
       FILTERBYTABLE=$OPTARG
       if [ $VERBOSE -eq 1  ] ; then
           echo "Filtering the table extraction by table name $FILTERBYTABLE"
       fi
       ;;
    S)
       CHUNKSIZE=$OPTARG
       if [ $VERBOSE -eq 1  ] ; then
           echo "Chunk size is: $CHUNKSIZE"
       fi
       ;;


    \?)
       echo "Invalid option: -$OPTARG" >&2
       usage
       exit 1
       ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

#define conncetion preferences

     CONNECTIONPAR=""
     CONNECTIONPAR_C=""
        
     if [ $SOCKET = "#" ]
     then
         CONNECTIONPAR=" --user=$USER --password=$PASSWORD --host=$IP --port=$PORT "
         CONNECTIONPAR_C=" -u $USER -p $PASSWORD -h $IP -P $PORT "
     else
	 echo "Must use TCP/IP connection to mysql"
	 exit 1
         CONNECTIONPAR=" --user=$USER --password=$PASSWORD --socket=$SOCKET"
     fi



    TIMENOW=`date`;
    echo "Local DIR is set to $LOCALPATH"
    echo "C_parser Mode is set to  $MYSQLMODE"
    
    
    echo "###################################################"
    echo "Process STARTs ${TIMENOW}"
    echo "###################################################"
    if [ ! -e $DESTDIR ]
    then
        echo "Global destination directory not present I will create it";
        `mkdir -p $DESTDIR`
        echo "---------------------------"
    
    fi
#Phase one is mainly extracting the info from ibdata
# create the files with the data in
# create the schema in the "fake" mysql that will be used for the recovery and analisys
    
    if [ $PHASE -lt 2 ]
    then
        echo "PHASE 1 ---------------------------"    
                
        while true; do
            echo "Clean destination directory from ANY content please confirm [yes] full word"
            echo -n "Destination directory to clean: $DESTDIR:  [yes/no/exit] --> "
            read CONFIRMDELDIR
        
        
            case "$CONFIRMDELDIR" in
                yes)
                    echo "You said that I am going to delete all the previous data in ${DESTDIR} give you last chance (15 sec to press ctrl-c)"
                    sleep 1;
                    echo "Deleting ... "
                    `rm -fr $DESTDIR/*`                    
                    break;
                    ;;
                no)
                    echo "NON empty directory, possible data over-write!!"
                    break
                    ;;
                exit)
                    echo "Ok goodby ... "
                    exit
                    ;;
                *)
                 echo "Invalid answer valid answers are yes/no/exit" 
            esac
        
            #if [ "x${CONFIRMDELDIR}" ==  "xyes" ] 
            #then
            #    `rm -fr $DESTDIR/*`
            #    break;
            #elsif [ "x${CONFIRMDELDIR}" ==  "xno" ] 
            #    echo "NON empty directory, possible data over-write!!"
            #    break
            #elsif [ "x${CONFIRMDELDIR}" ==  "xexit" ] 
            #    echo "NON empty directory, possible data over-write!!"
            #     exit
            #else
            #    echo "Invalid answer valid answers are yes/no/exit" 
            #fi
            ## I set the UNATTENDED only after the first queston given it may be too dangerous and can bring to data loss
            #if [ ${UNATTENDED} -eq 1 ]
            #then
            #    CONFIRMDELDIR="y"
            #fi
        done;
 
            
        echo "Processing main IBDATA file  "
      
        cd $DESTDIR;
        echo "current directory: `pwd`"
        echo "${EXECDIR}/stream_parser -f ${SOURCEDIR}/ibdata1 "
        `time ${EXECDIR}/stream_parser -f ${SOURCEDIR}/ibdata1`
        
        TOCHANGE=`ls -d page*`;
        `mv $DESTDIR/$TOCHANGE $DESTDIR/ibdata`
        TOCHANGE=""
        
        cd $EXECDIR
        if [ ! -e  "${EXECDIR}/c_parser" ]
        then
            printf "\nCompile before running \n"
            `time make c_parsers 1>&2>/dev/null`
        fi
    
        printf "\nPrecessing SYS_TABLES & SYS_INDEXES\n"
        
        cd "${DESTDIR}/ibdata";
        
        echo "Current Path `pwd`"
        
        `${EXECDIR}/c_parser -t ${EXECDIR}/dictionary/SYS_TABLES.sql  -p${DESTDIR}/ibdata -4Uf FIL_PAGE_INDEX/0000000000000001.page > ${DESTDIR}/ibdata/SYS_TABLES 2> ${DESTDIR}/ibdata/load_dictionary.sql`
        `${EXECDIR}/c_parser -t ${EXECDIR}/dictionary/SYS_INDEXES.sql -p${DESTDIR}/ibdata -4Uf FIL_PAGE_INDEX/0000000000000003.page > ${DESTDIR}/ibdata/SYS_INDEXES 2>> ${DESTDIR}/ibdata/load_dictionary.sql`
	      `${EXECDIR}/c_parser -t ${EXECDIR}/dictionary/SYS_COLUMNS.sql -p${DESTDIR}/ibdata -4Uf FIL_PAGE_INDEX/0000000000000002.page > ${DESTDIR}/ibdata/SYS_COLUMNS 2>> ${DESTDIR}/ibdata/load_dictionary.sql`
	      `${EXECDIR}/c_parser -t ${EXECDIR}/dictionary/SYS_FIELDS.sql  -p${DESTDIR}/ibdata -4Uf FIL_PAGE_INDEX/0000000000000004.page > ${DESTDIR}/ibdata/SYS_FIELDS 2>> ${DESTDIR}/ibdata/load_dictionary.sql`
        
        echo "---------------------------"        

        echo -n "Please check if the extracted structure is correct look in: $DESTDIR [y/n]  --> "
        if [ ${UNATTENDED} -eq 0 ]
	      then
	         read CONFIRMDELDIR
        else
	         CONFIRMDELDIR="y"            
	      fi

	      if [ "x${CONFIRMDELDIR}" == "xy" ]
        then
            echo "Cool continue then"
        else
            echo "Check what is the problem and run me again"
            exit 0 
        fi 
        echo "---------------------------"
        echo -n "(Re)Create the dictionary?: $DESTDIR [y/n]  --> "
        
				if [ ${UNATTENDED} -eq 0 ]
        then
            read CONFIRMDELDIR
        else
            CONFIRMDELDIR="y"
        fi
        

        if [ "x${CONFIRMDELDIR}" == "xy" ]
        then
	         echo "Loading dictionary information ...";
					`mysql $CONNECTIONPAR -D mysql -e "DROP schema if exists DRDICTIONARY"`;
					`mysql $CONNECTIONPAR -D mysql -e "create schema if not exists DRDICTIONARY"`;
					`mysql $CONNECTIONPAR -D mysql -D DRDICTIONARY < ${EXECDIR}/dictionary.sql`
					`mysql $CONNECTIONPAR -D DRDICTIONARY <  ${DESTDIR}/ibdata/load_dictionary.sql`;
				  echo "Loading dictionary information ... COMPLETED";
        else
            echo "Check what is the problem and run me again"
            exit 0 
        fi 
        echo "---------------------------"
        
    fi
    
# Creating include files
#USER="#"
#PASSWORD="#"
#IP="#"
#PORT="#"
#SOCKET="#"

#Phase 2
# here we create the SQL definition for each table
# also I process all partitioned tables and partition
# in that way it will be possible to se exactly what is going to use before using it
# Partitions def are empty and works as placeholders and a common table is used. this to allow EVENTUALLY to modify the partition definition itself


    if [ $PHASE -lt 3 ]
    then
        echo "PHASE 2 ---------------------------"
				RUNDEF=0;
				
        `rm -f $EXECDIR/include/*.defrecovery`;

        for schema in  $DATABASE ;
        do
	          SCHEMA_RECOVERY="${schema}"

            if [ ! -e $DESTDIR/${SCHEMA_RECOVERY} ]
            then
                echo "Global destination directory not present I will create it";
                `mkdir -p $DESTDIR/${SCHEMA_RECOVERY}`
                echo "---------------------------"
            fi
            if [ ! -e $DESTDIR/${SCHEMA_RECOVERY}/tablesdef ]
            then
                echo "${SCHEMA_RECOVERY} Definition file destination directory not present I will create it";
                `mkdir -p $DESTDIR/${SCHEMA_RECOVERY}/tablesdef`
                echo "---------------------------"
            fi



            echo -n "Should I recreate the structure for SCHEMA = $SCHEMA_RECOVERY ?[y/n]  --> "
	          if [ ${UNATTENDED} -eq 0 ]
       	    then
           	    read CONFIRMDELDIR
       	    else
                CONFIRMDELDIR="y"
            fi
	   
						if [ "x${CONFIRMDELDIR}" == "xy" ]
						then
							 `mysql $CONNECTIONPAR -D mysql -e "create schema if not exists ${SCHEMA_RECOVERY}"`;
							 echo "EXECUTING sys_parser.... $EXECDIR/sys_parser $CONNECTIONPAR_C -d DRDICTIONARY -r 1 $schema"
			
							if [ $VERBOSE -eq 1  ] ; then
								echo "$EXECDIR/sys_parser $CONNECTIONPAR_C -d DRDICTIONARY -r 1 $schema 1> ${DESTDIR}/${SCHEMA_RECOVERY}/${schema}_definition.sql"
								echo "mysql $CONNECTIONPAR -D $SCHEMA_RECOVERY <  ${DESTDIR}/${SCHEMA_RECOVERY}/${schema}_definition.sql "
							fi
					
							`$EXECDIR/sys_parser $CONNECTIONPAR_C -d DRDICTIONARY -r 1 $schema 1> ${DESTDIR}/${SCHEMA_RECOVERY}/${schema}_definition.sql`;
							MYERROR=0;
							`mysql $CONNECTIONPAR -D $SCHEMA_RECOVERY <  ${DESTDIR}/${SCHEMA_RECOVERY}/${schema}_definition.sql `;
					    MYERROR=$?;
							if [ $MYERROR > 0 ]
							then
								 echo "something went wrong with the definition file; I will set the auto generation of it from TABLEDEF \n Run table def creation and you should have a file named:"
								 echo "\t ${DESTDIR}/${SCHEMA_RECOVERY}/${schema}_definition2.sql"
								 echo "In the output directory"
								 RUNDEF=1
							fi	
							
							
							echo -n "Please check the status of the SCHEMA = $SCHEMA_RECOVERY and press [y] to continue or [n] to exit ?[y/n]  --> "
							if [ ${UNATTENDED} -eq 0 ]
							then
								read CONFIRMDELDIR
										else
											CONFIRMDELDIR="y"
							fi
					
							if [ "x${CONFIRMDELDIR}" == "xy" ]
							then
								 echo  "Continue......... to create table_def";		 
							else
								exit 1;
							fi
						else
							echo "Ok I assume that SCHEMA = $schema is already there";
							 
						fi 
									 
									
									
						for table in `find $SOURCEDIR/${SCHEMA_RECOVERY}/ -name *.ibd  -exec basename {} \;|awk -F '.' '{print $1}' `;
						do
								TABLEDEFINITIONNAME=""
								PARTITIONINDEX=0
								PARTITIONINDEX=`expr index "$table" \#`
								#echo "PINDEX = $PARTITIONINDEX"
								TABLENAME_SQL=""
								
								if [ $PARTITIONINDEX -gt 0 ]
								then
										
										TABLEFILTERNAME=${table:0:($PARTITIONINDEX - 1)}"#_XXX_PARTITIONED__XXX_"${table:($PARTITIONINDEX - 1)}
										TABLENAME_SQL=${table:0:($PARTITIONINDEX - 1)}
										TABLEDEFINITIONNAME=${table:0:($PARTITIONINDEX - 1)}
										
								
								else
										TABLEDEFINITIONNAME=$table
										TABLENAME_SQL=$table
								fi
								
								if [ $VERBOSE -eq 1  ] ; then
										echo "Creating definition for table ($table) : $SOURCEDIR/${SCHEMA_RECOVERY}/${TABLEDEFINITIONNAME}"
										
								fi
								
								if [ ! -e $DESTDIR/${SCHEMA_RECOVERY} ]
								then
										echo "Destination (${DESTDIR}/${SCHEMA_RECOVERY}/tablesdef/) directory not present I will create it";
										`mkdir -p ${DESTDIR}/${SCHEMA_RECOVERY}/tablesdef/`
										echo "---------------------------"
								
								fi
	
								DEFINITIONFILE="${DESTDIR}/${SCHEMA_RECOVERY}/tablesdef/table_defs.${schema}.${TABLEDEFINITIONNAME}.sql"
								
								if [ $PARTITIONINDEX -gt 0 ]
								then
										if [ $VERBOSE -eq 1  ] ; then
												echo "$EXECDIR/single_sys_parser $CONNECTIONPAR_C -d DRDICTIONARY  $SCHEMA_RECOVERY/$TABLEFILTERNAME  $DEFINITIONFILE";
										fi
										`$EXECDIR/single_sys_parser $CONNECTIONPAR_C -d DRDICTIONARY  $SCHEMA_RECOVERY/${table} | sed  -e "s/${table}/${TABLEDEFINITIONNAME}/g" > $DEFINITIONFILE`;
										`echo "" > ${DESTDIR}/${SCHEMA_RECOVERY}/tablesdef/table_defs.${schema}.${TABLEFILTERNAME}.sql`;
								else
										if [ $VERBOSE -eq 1  ] ; then
												echo "$EXECDIR/single_sys_parser $CONNECTIONPAR_C -d DRDICTIONARY  '$SCHEMA_RECOVERY/$TABLENAME_SQL'  [$DEFINITIONFILE]" ;
										fi
										`$EXECDIR/single_sys_parser $CONNECTIONPAR_C -d DRDICTIONARY  $SCHEMA_RECOVERY/$TABLENAME_SQL > $DEFINITIONFILE`;
								
								fi
						done;
				done;
				
				if [ $RUNDEF > 0  ]
				then
					for def in `ls -D ${DESTDIR}/${SCHEMA_RECOVERY}/tablesdef/*.sql`; do cat $def >> ${DESTDIR}/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_definition2.sql; done
					echo "Additional Schema definition created in ${DESTDIR}/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_definition2.sql \n"
				fi
				
				echo -n "Please check if the extracted table definition is correct look in: ${DESTDIR}/${SCHEMA_RECOVERY}/tablesdef/*.sql [y/n]  --> "
				if [ ${UNATTENDED} -eq 0 ]
				then
 					  read CONFIRMDELDIR
				else
				    CONFIRMDELDIR="y"
				fi

				if [ "x${CONFIRMDELDIR}" == "xy" ]
				then
						echo "Cool continue then"
				else
						echo "Check what is the problem and run me again"
						exit 0 
				fi
				echo "---------------------------"
						
    fi
# Starting the extraction process
#Phase 3 is where we extract from ibd and create file tab separated
# the list of extracted table definition is processed, as such is possible to copy all of them somewhere
# an move back only the table u want really process
#OR if ONE table only use the filter and run directly the wrapper from PHASE 3

    if [ $PHASE -lt 4 ]
    then
        echo "PHASE 3 ---------------------------"
        #for schematable in `find $EXECDIR/include/ -name *.defrecovery  -exec basename {} \\;`
        
        echo "use ${SCHEMA_RECOVERY} " > ${DESTDIR}/${SCHEMA_RECOVERY}/load_${SCHEMA_RECOVERY}.sql
        
        for schematable in `ls ${DESTDIR}/${SCHEMA_RECOVERY}/tablesdef/*.sql | xargs -n1 basename`
        do
    #read the table name and schema
    
						SCHEMA=`echo $schematable|awk -F '.' '{print $2}' `;
						TABLE=`echo $schematable|awk -F '.' '{print $3}' `;
						PARTITIONINDEX=`expr index "$TABLE" \#`
						ISPARTITIONED=0
		
						PARTITIONFLAG=$(expr match "$TABLE"  '.*\(XXX_PARTITIONED__XXX\)')
						
						if [ "#$PARTITIONFLAG" = "#XXX_PARTITIONED__XXX" ]
						then
								ISPARTITIONED=1
						fi
		
						if [ $ISPARTITIONED -gt 0 ]
						then
								TABLEFILTERNAME=${TABLE:0:($PARTITIONINDEX -1 )}
								schematable="table_defs.${SCHEMA}.${TABLEFILTERNAME}.sql"
								TABLE=`echo $TABLE|sed -e"s/#_XXX_PARTITIONED__XXX_//g"`
						else
								TABLEFILTERNAME=$TABLE
						fi
		
						if [ "#$FILTERBYTABLE" != "##" ]
						then
								if [ "#$FILTERBYTABLE" != "#$TABLEFILTERNAME" ]
								then
									continue;
								else
																echo "$FILTERBYTABLE   $TABLEFILTERNAME"
								fi
						
						fi
						
						if [ $VERBOSE -eq 1  ] ; then
								echo "Original Name = $schematable" ;   
								echo "Schema Name = $SCHEMA" ;
								echo "Table Name = $TABLE" ;
								echo "Table is Partitioned = $ISPARTITIONED" ;
								#LINK=`Table definition SQL `
								#echo "active definition link:${LINK}"
								echo "Active Schema/Table ${schematable}"
						fi
						echo "Compile for table = $TABLE [SCHEMA=${SCHEMA}]";
				
						if [ ${ASKCONFIRMATION} -eq 1 ]
						then
							while [ 1=1 ]
							do
								CONFIRMDELDIR="xn";
								echo -n "Process next Table ${TABLE}? [y/n]  --> "
											read CONFIRMDELDIR
								if [ "#${CONFIRMDELDIR}" == "#y" ]
								then
										echo "Cool continue then ${CONFIRMDELDIR}"
										break;
								else
										echo "Waiting ..";
								fi
							done  
						fi
			
						#Read table ID from SYS_TABLE
						ESCTABLE=${TABLE//_/.\\_};
						ESCSCHEMA=${SCHEMA//_/.\\_};
				
						TABLEID=`cat ${DESTDIR}/ibdata/SYS_TABLES|grep -e "SYS_TABLES.\"${ESCSCHEMA}/${ESCTABLE}\""|sed -e"s/\t/,/g"|awk -F ',' '{print $5}'|head -n 1`;
						INDEXID=`cat ${DESTDIR}/ibdata/SYS_INDEXES|grep -e "SYS_INDEXES.${TABLEID}"|grep PRIMARY|sed -e"s/\t/,/g"|awk -v r=${TABLEID} -F ',' '{if($4==r){print $5}else{print $4 $5}}'|head -n 1`;
						PAGEFILE=""
						printf -v PAGEFILE "%016d" $INDEXID
		#                if [ $VERBOSE -eq 1  ] ; then
		#                  echo "cat ${DESTDIR}/ibdata/SYS_TABLES|grep -e \"SYS_TABLES.\"${ESCSCHEMA}/${ESCTABLE}\"\"|sed -e\"s/\t/,/g\"|awk -F ',' '{print \$5}'"
		#		  echo "cat ${DESTDIR}/ibdata/SYS_INDEXES|grep -e \"SYS_INDEXES.${TABLEID}\"|grep PRIMARY|sed -e\"s/\t/,/g\"|awk -F ',' '{if(\$4 == "${TABLEID}"){print \$5}else{exit 1}}'";
		#                fi
						echo "Processing TableId $TABLEID with PK ID ${INDEXID} file (${PAGEFILE})";
					
						FILETOPARSE=${SOURCEDIR}/${SCHEMA_RECOVERY}/${TABLE}.ibd
						if [ ! -e $FILETOPARSE ]
						then
								printf "!!!!! WARNING !!!!\n The file $FILETOPARSE is not found please check the path and try again\n";
								continue
						fi
		
		#Parsing IBD file for the given table
		
						echo "Parsing file $FILETOPARSE";
						cd $DESTDIR/$SCHEMA_RECOVERY
						echo "Current dir:`pwd`"
						echo "Executing:   ${EXECDIR}/stream_parser -f ${SOURCEDIR}/${SCHEMA_RECOVERY}/${TABLE}.ibd"
													
						`time ${EXECDIR}/stream_parser -f ${SOURCEDIR}/${SCHEMA_RECOVERY}/${TABLE}.ibd`
						
						TOCHANGE=`ls -d page*`;
						`rm -fr $DESTDIR/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_${TABLE}`
						`mv $DESTDIR/${SCHEMA_RECOVERY}/$TOCHANGE $DESTDIR/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_${TABLE}`
					
						printf "\n -------------------------- \n"   ;
						TIMENOW=`date`;
		#extracting data
						echo "Starting data extraction ${SCHEMA_RECOVERY}_${TABLE} ${TIMENOW}";
						
						echo "${EXECDIR}/c_parser -p ${DESTDIR}/${SCHEMA_RECOVERY} -${MYSQLMODE}${RECOVERYMODE}f $DESTDIR/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_${TABLE}/FIL_PAGE_INDEX/${PAGEFILE}.page -b $DESTDIR/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_${TABLE}/FIL_PAGE_TYPE_BLOB/ -t ${DESTDIR}/${SCHEMA_RECOVERY}/tablesdef/${schematable} -o $DESTDIR/${SCHEMA_RECOVERY}/DATA_${SCHEMA_RECOVERY}_${TABLE}" 
						if [ -f $DESTDIR/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_${TABLE}/FIL_PAGE_INDEX/${PAGEFILE}.page ]
						then
								 `time ${EXECDIR}/c_parser  -p ${DESTDIR}/${SCHEMA_RECOVERY} -${MYSQLMODE}${RECOVERYMODE}f $DESTDIR/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_${TABLE}/FIL_PAGE_INDEX/${PAGEFILE}.page -b $DESTDIR/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_${TABLE}/FIL_PAGE_TYPE_BLOB/ -t ${DESTDIR}/${SCHEMA_RECOVERY}/tablesdef/${schematable} -o $DESTDIR/${SCHEMA_RECOVERY}/DATA_${SCHEMA_RECOVERY}_${TABLE}.tab 1>> ${DESTDIR}/${SCHEMA_RECOVERY}/load_${SCHEMA_RECOVERY}.sql`
						else
								 if [ -f ${DESTDIR}/${SCHEMA_RECOVERY}/tablesdef/${schematable} ]
								 then
											RECLOCALPATH=`pwd`
											cd $DESTDIR/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_${TABLE}/FIL_PAGE_INDEX/
											echo "File page $DESTDIR/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_${TABLE}/FIL_PAGE_INDEX/${PAGEFILE}.page Not found"
											echo "Will try to process existing file(s) using the given table definition ${DESTDIR}/${SCHEMA_RECOVERY}/tablesdef/${schematable}"
											#MYCHUNK=0;
											for FRECOV in `ls -D *.page`;
											do
												 echo "processing $FRECOV"
												 #MYCHUNK=$((MYCHUNK+1));
												 #`time ${EXECDIR}/c_parser  -p ${DESTDIR}/${SCHEMA_RECOVERY} -${MYSQLMODE}${RECOVERYMODE}f $DESTDIR/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_${TABLE}/FIL_PAGE_INDEX/${FRECOV} -b $DESTDIR/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_${TABLE}/FIL_PAGE_TYPE_BLOB/ -t ${DESTDIR}/${SCHEMA_RECOVERY}/tablesdef/${schematable} -o $DESTDIR/${SCHEMA_RECOVERY}/DATA_${SCHEMA_RECOVERY}_${TABLE}_C${MYCHUNK}.tab 1>> ${DESTDIR}/${SCHEMA_RECOVERY}/load_${SCHEMA_RECOVERY}.sql`
												`time ${EXECDIR}/c_parser  -p ${DESTDIR}/${SCHEMA_RECOVERY} -${MYSQLMODE}${RECOVERYMODE}f $DESTDIR/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_${TABLE}/FIL_PAGE_INDEX/${FRECOV} -b $DESTDIR/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_${TABLE}/FIL_PAGE_TYPE_BLOB/ -t ${DESTDIR}/${SCHEMA_RECOVERY}/tablesdef/${schematable} -o $DESTDIR/${SCHEMA_RECOVERY}/DATA_${SCHEMA_RECOVERY}_${TABLE}.tab 1>> ${DESTDIR}/${SCHEMA_RECOVERY}/load_${SCHEMA_RECOVERY}.sql`
												break;
										 done;
										 cd $RECLOCALPATH;
									else
										echo "[ERROR] Table definition not found I cannot process the file \n Page file $DESTDIR/${SCHEMA_RECOVERY}/${SCHEMA_RECOVERY}_${TABLE}/FIL_PAGE_INDEX/${PAGEFILE}.page "
										echo "[Error] Table definition -f ${DESTDIR}/${SCHEMA_RECOVERY}/tablesdef/${schematable}"
										exit 1;
									fi
									echo "";
						fi 
					 
						
						TIMENOW=`date`;
						echo "Data extraction ENDS ${SCHEMA_RECOVERY}_${TABLE} ${TIMENOW}";
						
						printf "\n -------------------------- \n\n" 
        done;
    fi
    echo "###################################################"
    echo "Process ENDs ${TIMENOW}"
    echo "###################################################"
    
    
    cd $LOCALPATH;
    
