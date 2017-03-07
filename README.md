#Why this wrapper?

I developed this wrapper to facilitate the data recovery of what I think will be the 80% of data corruption cases.
The point is that the whole process is very fragmented and manual, but it can be automatated, given that most of the tasks are repetitive.
The scope of the wrapper is to let you set only few things and run it. 
The extraction process can take few minutes to days, depending the data to recover.  
But having the wrapper to execute the dummy part, you can focus on the data validation and additional adjustments data recovery may require.


#How it works?
The wrapper is split in 3 main Phases:
 - 1) innodb data extraction and DRDICTIONARY creation
 - 2) re-generate the schema and create table definitions
 - 3) data extraction from corrupted files in to pages (binary), extract data in tab separated format

The whole process require a dummy mysql server to run. The tool will access it and will use it to generate processing informations.
It will also contains the information from the InnoDB dictionary (in the DRDICTIONARY) that can be review and eventually modified. 

Once the dictionary is recovered, the tool will generate the schema in the dummy mysql where you will be able to reload the data once done.
After that a list of table definitions will be generated in the destination directory.
The path is <dest_dir>/schema_name/tablesdef/ each definition has the following name format table_defs.${schema}.${TABLEDEFINITIONNAME}.sql
The TABLEDEFINITIONNAME is a name created by the tool, and include the real table name plus informations like if table is partitioned.

After that the generated list of tabe defintion will be used by the tool to process the InnoDB files.
If (as it advisable) you want to test the data extraction, you can either filter the process by table name using the -F option, or if you want to test on more than one
just move the table definition files in a sub-dir and keep only the definition(s) of the tables you want toprocess.

The next step the tool will generate a subdir for each table to recover and a DATA_XXX file in the schema_name/ directory.

The tool can be run once, say until PHASE 3 excluded. Then review whatever, and run again just using the -P flag with the PHASE from which you want to start.
IE you had run it up to PHASE 2 and want to run Phase 3 -P 3.
Or you had run it all and you had just change the definition files in the <dest_dir>/schema_name/tablesdef/, then again no reason to re-run the whole process, 
just run it again with -P 3.
If you want to run it from start to end just do not put any -P.

The tool asks by default few questions during the process, to allow you to check the output while processing.
If you want to suppress that, use the flag -U 1, and the process will not bother you until the end.
On the other hand if you want to check EACH tabe data extraction use -A 1 and the tool will ask you confirmation at each processed table.

One note if you re-run the tool from Phase 1, you will be ask to confirm IF you want to delete the original directory, well be careful!!.
 
Finally you can pass the standard flags to the recovery tools, so you can say if you want to recover data, or recover DELETE data and which version of InnoDB to use.
``` 
Valid options are:
-s root_directory_for_page_files 
-o destination_directory_for_data extract
-r executable_dir
-d database name to extract
-u MySQL user
-p MySQL password
-i MySQL IP
-x MySQL Port
-k socket
-v verbose mode
-A [0|1] ask for confirmation when extracting a table
-U [0|1] Unattended if set to 1 will run the whole process assuming YES is the answer to all questions
-P Phase to start from:\n \t1 ibdata extract;\n \t2 compile table_def;\n \t3 run only table extraction
-m recovery mode [U undeleted | D deleted]
-M MySQL c_parser mode (default 5)
  -4  -- innodb_datafile is in REDUNDANT format
  -5  -- innodb_datafile is in COMPACT format
  -6  -- innodb_datafile is in MySQL 5.6 format
-F filter by _table_name_ 
run_data_extraction.sh -v -A 1 -F salaries -d employees -u stress -p tool -i 192.168.0.35 -x 5510 -s /opt/dr_origin -o /opt/dr_dest -r /opt/undrop
```

Example:
Copy all data from original location to `/opt/dr_int/dr_orig/data/` while destination will be `/opt/dr_int/dr_dest/` and binaries are in `/opt/undrop-innodb/`, schema to rescue is windmills
the following will be the command line I am not using -U now.

```
run_data_extraction.sh -v -A 0 -d windmills -u stress -p test -i 192.168.0.12 -x 3306  -s /opt/dr_int/dr_orig/data/ -o /opt/dr_int/dr_dest/ -r /opt/undrop-innodb/ -M 6
```

First question:
```
PHASE 1 ---------------------------
Clean destination directory from ANY content please confirm [yes] full word
Destination directory to clean: /opt/dr_int/dr_dest/:  [yes/no/exit] --> 
```

IF I say YES:
```
Destination directory to clean: /opt/dr_int/dr_dest/:  [yes/no/exit] --> yes
You said that I am going to delete all the previous data in /opt/dr_int/dr_dest/ give you last chance (15 sec to press ctrl-c)
Deleting ... 
Processing main IBDATA file  
current directory: /opt/dr_int/dr_dest
/opt/undrop-innodb//stream_parser -f /opt/dr_int/dr_orig/data//ibdata1 
Opening file: /opt/dr_int/dr_orig/data//ibdata1
File information:

ID of device containing file:        64769
```
So ibdata will be processed.

Second question:
```
Precessing SYS_TABLES SYS_INDEXES
Current Path /opt/dr_int/dr_dest/ibdata
---------------------------
Please check if the extracted structure is correct look in: /opt/dr_int/dr_dest/ [y/n]  --> 
```
If I check in the destination directory /opt/dr_int/dr_dest/ibdata
```
drwxr-xr-x 4 root root 4096 Mar  6 19:45 ibdata
[root@mysqlt2 dr_dest]# ll ibdata/
total 80
drwxr-xr-x 2 root root  4096 Mar  6 19:45 FIL_PAGE_INDEX
drwxr-xr-x 2 root root  4096 Mar  6 19:45 FIL_PAGE_TYPE_BLOB
-rw-r--r-- 1 root root  1082 Mar  6 19:45 load_dictionary.sql
-rw-r--r-- 1 root root 33883 Mar  6 19:45 SYS_COLUMNS
-rw-r--r-- 1 root root 12081 Mar  6 19:45 SYS_FIELDS
-rw-r--r-- 1 root root  9800 Mar  6 19:45 SYS_INDEXES
-rw-r--r-- 1 root root  7401 Mar  6 19:45 SYS_TABLES
```
You can check whatever you like here and go ahead if all sounds ok.
```
Current Path /opt/dr_int/dr_dest/ibdata
---------------------------
Please check if the extracted structure is correct look in: /opt/dr_int/dr_dest/ [y/n]  --> y
Cool continue then
---------------------------
(Re)Create the dictionary?: /opt/dr_int/dr_dest/ [y/n]  --> y
Loading dictionary information ...
mysql: [Warning] Using a password on the command line interface can be insecure.
mysql: [Warning] Using a password on the command line interface can be insecure.
mysql: [Warning] Using a password on the command line interface can be insecure.
mysql: [Warning] Using a password on the command line interface can be insecure.
Loading dictionary information ... COMPLETED
---------------------------
PHASE 2 ---------------------------
Global destination directory not present I will create it
---------------------------
windmills Definition file destination directory not present I will create it
---------------------------
Should I recreate the structure for SCHEMA = windmills ?[y/n]  --> y
mysql: [Warning] Using a password on the command line interface can be insecure.
EXECUTING sys_parser.... /opt/undrop-innodb//sys_parser  -u stress -p test -h 192.168.0.12 -P 3306  -d DRDICTIONARY -r 1 windmills
/opt/undrop-innodb//sys_parser  -u stress -p <secret> -h 192.168.0.12 -P 3306  -d DRDICTIONARY -r 1 windmills 1> /opt/dr_int/dr_dest//windmills/windmills_definition.sql
mysql  --user=stress --password=test --host=192.168.0.12 --port=3306  -D windmills <  /opt/dr_int/dr_dest//windmills/windmills_definition.sql 
mysql: [Warning] Using a password on the command line interface can be insecure.
Please check the status of the SCHEMA = windmills and press [y] to continue or [n] to exit ?[y/n]  --> 
```
As you can see above we had pass to Phase 2 and once you say Yes the tool will generate the definition files 
```
[root@mysqlt2 dr_dest]# ll windmills/tablesdef/
total 36
-rw-r--r-- 1 root root 439 Mar  6 19:50 table_defs.windmills.wmillAUTOINC.sql
-rw-r--r-- 1 root root 449 Mar  6 19:50 table_defs.windmills.wmillMIDPart.sql
-rw-r--r-- 1 root root   1 Mar  6 19:50 table_defs.windmills.wmillMIDPart#_XXX_PARTITIONED__XXX_#P#asia.sql
-rw-r--r-- 1 root root   1 Mar  6 19:50 table_defs.windmills.wmillMIDPart#_XXX_PARTITIONED__XXX_#P#europe.sql
-rw-r--r-- 1 root root   1 Mar  6 19:50 table_defs.windmills.wmillMIDPart#_XXX_PARTITIONED__XXX_#P#namerica.sql
-rw-r--r-- 1 root root   1 Mar  6 19:50 table_defs.windmills.wmillMIDPart#_XXX_PARTITIONED__XXX_#P#samerica.sql
-rw-r--r-- 1 root root   1 Mar  6 19:50 table_defs.windmills.wmillMIDPart#_XXX_PARTITIONED__XXX_#P#universe.sql
-rw-r--r-- 1 root root 445 Mar  6 19:50 table_defs.windmills.wmillMID.sql
-rw-r--r-- 1 root root 451 Mar  6 19:50 table_defs.windmills.wmillMIDUUID.sql
```

Again another question:
```
Please check if the extracted table definition is correct look in: /opt/dr_int/dr_dest//windmills/tablesdef/*.sql [y/n]  --> 

Check OR remove the definition files you want. 

On Yes the tool will start data extraction and will report the process:
 -------------------------- 
Starting data extraction windmills_wmillAUTOINC Mon Mar  6 19:52:44 EST 2017
/opt/undrop-innodb//c_parser -p /opt/dr_int/dr_dest//windmills -5Uf /opt/dr_int/dr_dest//windmills/windmills_wmillAUTOINC/FIL_PAGE_INDEX/0000000000000307.page -b /opt/dr_int/dr_dest//windmills/windmills_wmillAUTOINC/FIL_PAGE_TYPE_BLOB/ -t /opt/dr_int/dr_dest//windmills/tablesdef/table_defs.windmills.wmillAUTOINC.sql -o /opt/dr_int/dr_dest//windmills/DATA_windmills_wmillAUTOINC
-- 2.80% done
-- 5.60% done
-- 8.40% done
-- 11.20% done
-- 14.01% done
```
File will be in :
```
drwxr-xr-x 4 root root      4096 Mar  6 19:52 windmills_wmillAUTOINC
[root@mysqlt2 dr_dest]# ll windmills/windmills_wmillAUTOINC/
total 8
drwxr-xr-x 2 root root 4096 Mar  6 19:52 FIL_PAGE_INDEX
drwxr-xr-x 2 root root 4096 Mar  6 19:52 FIL_PAGE_TYPE_BLOB
```
While final data in:
```
[root@mysqlt2 dr_dest]# ll windmills/
total 415252
-rw-r--r-- 1 root root 332560216 Mar  6 19:54 DATA_windmills_wmillAUTOINC.tab         <------
-rw-r--r-- 1 root root  92633715 Mar  6 19:55 DATA_windmills_wmillMIDPart#P#asia.tab  <------
-rw-r--r-- 1 root root         0 Mar  6 19:52 load_windmills.sql
drwxr-xr-x 2 root root      4096 Mar  6 19:50 tablesdef
-rw-r--r-- 1 root root      1848 Mar  6 19:49 windmills_definition.sql
drwxr-xr-x 4 root root      4096 Mar  6 19:52 windmills_wmillAUTOINC
drwxr-xr-x 4 root root      4096 Mar  6 19:54 windmills_wmillMIDPart#P#asia
```
While file to reload the dataset back to mysql is cat windmills/load_windmills.sql

Once the process is over the file will have the command to relaod all the processed tables

This is the message reported at the end:
```
-------------------------- 

###################################################
Process ENDs Mon Mar  6 23:36:21 EST 2017
###################################################
```

And this an example of load file:
```
use windmills; 
SET FOREIGN_KEY_CHECKS=0;
LOAD DATA LOCAL INFILE '/opt/dr_int/dr_dest//windmills/DATA_windmills_wmillMIDPart#P#asia.tab' REPLACE INTO TABLE `wmillMIDPart` FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '"' LINES STARTING BY 'wmillMIDPart\t' (`millid`, `id`, `uuid`, `kwatts_s`, `date`, `location`, `active`, `time`, `strrecordtype`);
SET FOREIGN_KEY_CHECKS=0;
LOAD DATA LOCAL INFILE '/opt/dr_int/dr_dest//windmills/DATA_windmills_wmillMIDPart#P#europe.tab' REPLACE INTO TABLE `wmillMIDPart` FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '"' LINES STARTING BY 'wmillMIDPart\t' (`millid`, `id`, `uuid`, `kwatts_s`, `date`, `location`, `active`, `time`, `strrecordtype`);
SET FOREIGN_KEY_CHECKS=0;
LOAD DATA LOCAL INFILE '/opt/dr_int/dr_dest//windmills/DATA_windmills_wmillMIDPart#P#namerica.tab' REPLACE INTO TABLE `wmillMIDPart` FIELDS TERMINATED BY '\t' OPTIONALLY ENCLOSED BY '"' LINES STARTING BY 'wmillMIDPart\t' (`millid`, `id`, `uuid`, `kwatts_s`, `date`, `location`, `active`, `time`, `strrecordtype`);
```
Example of output:
```
-- Page id: 336, Format: COMPACT, Records list: Valid, Expected records: (113 113)
0000000FAB7B    D00000017B04B2  wmillMIDPart    68      488023  "2524a9a0-fc86-11e6-bbe4-08002734ed50"  511     "2010-02-24"    "For sweetest things turn sourest by "  -12     "2025-07-02 13:16:34"   " de"
0000000FAB83    D80000021604EE  wmillMIDPart    68      488138  "2526f9e9-fc86-11e6-bbe4-08002734ed50"  2415    "2010-02-24"    "ORLANDO. O, but she is wise.ROSALIND"  -82     "1987-03-06 20:04:32"   "els"
0000000FABDB    B0000001BB0462  wmillMIDPart    68      493103  "25a7660e-fc86-11e6-bbe4-08002734ed50"  4495    "2010-02-24"    "To play the watchman ever for thy sa"  -21     "2023-10-17 04:31:43"   "r t"
0000000FAC24    F9000001FA0502  wmillMIDPart    68      496093  "25f9f86e-fc86-11e6-bbe4-08002734ed50"  4024    "2010-02-24"    "And summer's lease hath all too shor"  -12     "1987-03-20 05:56:36"   "ate"
0000000FAC67    BC0000022D0502  wmillMIDPart    68      499593  "265cbed0-fc86-11e6-bbe4-08002734ed50"  4729    "2010-02-24"    "DIANA. They say the French count has"  -96     "2023-05-25 10:19:17"   " mo"
_snip_
0000001182F6	A50000012E0502	wmillMIDPart	6	6490943	"fcd594d2-fc88-11e6-bbe4-08002734ed50"	2471	"1935-06-06"	"Can make you live your self in eyes "	-17	"2024-04-17 20:46:29"	"n.T"
0000001182FA	A90000023704DA	wmillMIDPart	6	6491033	"fcda36fe-fc88-11e6-bbe4-08002734ed50"	3199	"1935-06-06"	"Too base of thee to be remembered,Th"	-27	"1987-04-06 05:03:46"	"th "
00000011834E	DD0000013A04C6	wmillMIDPart	6	6495228	"fd6a6c65-fc88-11e6-bbe4-08002734ed50"	4148	"1935-06-06"	"O let me true in love but truly writ"	-27	"1993-07-12 10:00:04"	" th"
00000011838E	BD0000017104B2	wmillMIDPart	6	6498523	"fdce49a8-fc88-11e6-bbe4-08002734ed50"	267	"1935-06-06"	"Painting my age with beauty of thy d"	-31	"2034-07-27 01:39:44"	"63A"
-- Page id: 3199, Found records: 113, Lost records: NO, Leaf page: YES
```


#Note
To have it work decently, I had to modify the basic code coming from Aleksandr in some different points, and I foresee more changes, especially now given he had stop to produce the free source version.

Still credits of the original code go to Aleksandr Kuzminsky, who is the original author of the tool.












#--Former--
## TwinDB data recovery toolkit
## Supported Failures

TwinDB Data Recovery Toolkit is a set of tools that operate with MySQL files at low level and allow to recover InnoDB databases after different failure scenarios.

The toolkit is also known as **UnDrop for InnoDB**, which is more accurate name because the toolkit works with InnoDB tables.

The tool recovers data when backups are not available. It supports recovery from following failures:

- A table or database was dropped.
- InnoDB table space corruption.
- Hard disk failure.
- File system corruption.
- Records were deleted from a table.
- A table was truncated.
- InnoDB files were accidentally deleted.
- A table was dropped and created empty one.
## Installation
The source code of the toolkit is hosted on LaunchPad. The tool has been developed on Linux, it’s known to work on CentOS 4,5,6,7, Debian, Ubuntu and Amazon Linux. Only 64 bit systems are supported.

To best way to get the source code is to clone it from GitHub.
```
git clone https://github.com/twindb/undrop-for-innodb.git
```

### Prerequisites

The toolkit needs `make`, `gcc`, `flex` and `bison` to compile.

### Compilation

To build the toolkit run make in the source code root:
```
# make
```
## Usage
There is a series of blog posts that describe in great details recovery from different failures.

 * [Recover Table Structure From InnoDB Dictionary](https://twindb.com/recover-table-structure-from-innodb-dictionary/) – how to generate CREATE TABLE statement if you have ibdata1 file.
 * [Take image from corrupted hard drive](https://twindb.com/take-image-from-corrupted-hard-drive/) – what you should do if a hard disk is dying.
 * [Recover Corrupt MySQL Database](https://twindb.com/recover-corrupt-mysql-database/) – how to recover database from corrupt InnoDB tablespace. The same approach can be taken to recover from corrupt file system.
 * [Recover after DROP TABLE. Case 2](https://twindb.com/recover-after-drop-table-innodb_file_per_table-on/) – how to recover InnoDB table if it was dropped and innodb_file_per_table was ON (a separate .ibd file per table).
 * [Recover after DROP TABLE. Case 1](https://twindb.com/recover-innodb-table-after-drop-table-innodb/) – how to recover InnoDB table if it was dropped and innodb_file_per_table was OFF (all tables are in ibadat1 file).
 * [Recover InnoDB dictionary](https://twindb.com/how-to-recover-innodb-dictionary/) – how to recover and read InnoDB dictionary tables.
 * [UnDROP tool for InnoDB](https://twindb.com/undrop-tool-for-innodb/) – describes tools of the toolkit, their usage, command line options.
 * [InnoDB dictionary](https://twindb.com/innodb-dictionary/) – describes InnoDB dictionary, its tables and format.

## Commercial Support and Data Recovery Service

You can recover your database using the toolkit and detailed instructions from the blog posts. 
We can help you to do it much faster.

[Aleksandr Kuzminsky](https://www.linkedin.com/in/akuzminsky) is an author of TwinDB data recovery toolkit and its forks. 
Since 2008 he dealt with many hundreds recovery cases.

Check [MySQL Data Recovery Service](https://twindb.com/mysql-data-recovery/) to learn more about prices, prerequisites and contact details.
