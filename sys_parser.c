#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <mysql.h>
#include <libgen.h>


/* The 'MAIN TYPE' of a column */
#define	DATA_VARCHAR	1	/* character varying of the
				latin1_swedish_ci charset-collation; note
				that the MySQL format for this, DATA_BINARY,
				DATA_VARMYSQL, is also affected by whether the
				'precise type' contains
				DATA_MYSQL_TRUE_VARCHAR */
#define DATA_CHAR	2	/* fixed length character of the
				latin1_swedish_ci charset-collation */
#define DATA_FIXBINARY	3	/* binary string of fixed length */
#define DATA_BINARY	4	/* binary string */
#define DATA_BLOB	5	/* binary large object, or a TEXT type;
				if prtype & DATA_BINARY_TYPE == 0, then this is
				actually a TEXT column (or a BLOB created
				with < 4.0.14; since column prefix indexes
				came only in 4.0.14, the missing flag in BLOBs
				created before that does not cause any harm) */
#define	DATA_INT	6	/* integer: can be any size 1 - 8 bytes */
#define	DATA_SYS_CHILD	7	/* address of the child page in node pointer */
#define	DATA_SYS	8	/* system column */

/* Data types >= DATA_FLOAT must be compared using the whole field, not as
binary strings */

#define DATA_FLOAT	9
#define DATA_DOUBLE	10
#define DATA_DECIMAL	11	/* decimal number stored as an ASCII string */
#define	DATA_VARMYSQL	12	/* any charset varying length char */
#define	DATA_MYSQL	13	/* any charset fixed length char */
				/* NOTE that 4.1.1 used DATA_MYSQL and
				DATA_VARMYSQL for all character sets, and the
				charset-collation for tables created with it
				can also be latin1_swedish_ci */
#define DATA_MTYPE_MAX	63	/* dtype_store_for_order_and_null_size()
				requires the values are <= 63 */

/*
enum enum_field_types { MYSQL_TYPE_DECIMAL, MYSQL_TYPE_TINY,
                        MYSQL_TYPE_SHORT,  MYSQL_TYPE_LONG,
                        MYSQL_TYPE_FLOAT,  MYSQL_TYPE_DOUBLE,
                        MYSQL_TYPE_NULL,   MYSQL_TYPE_TIMESTAMP,
                        MYSQL_TYPE_LONGLONG,MYSQL_TYPE_INT24,
                        MYSQL_TYPE_DATE,   MYSQL_TYPE_TIME,
                        MYSQL_TYPE_DATETIME, MYSQL_TYPE_YEAR,
                        MYSQL_TYPE_NEWDATE, MYSQL_TYPE_VARCHAR,
                        MYSQL_TYPE_BIT,
                        MYSQL_TYPE_NEWDECIMAL=246,
                        MYSQL_TYPE_ENUM=247,
                        MYSQL_TYPE_SET=248,
                        MYSQL_TYPE_TINY_BLOB=249,
                        MYSQL_TYPE_MEDIUM_BLOB=250,
                        MYSQL_TYPE_LONG_BLOB=251,
                        MYSQL_TYPE_BLOB=252,
                        MYSQL_TYPE_VAR_STRING=253,
                        MYSQL_TYPE_STRING=254,
                        MYSQL_TYPE_GEOMETRY=255

};
*/
/*
   - In the second least significant byte we OR flags DATA_NOT_NULL,
   DATA_UNSIGNED, DATA_BINARY_TYPE.
 */
#define DATA_NOT_NULL   256     /* this is ORed to the precise type when
                                   the column is declared as NOT NULL */
#define DATA_UNSIGNED   512     /* this id ORed to the precise type when
                                   we have an unsigned integer type */
#define DATA_BINARY_TYPE 1024   /* if the data type is a binary character
                                   string, this is ORed to the precise type:
                                   this only holds for tables created with
                                   >= MySQL-4.0.14 */
#define DATA_LONG_TRUE_VARCHAR 4096     /* this is ORed to the precise data
				type when the column is true VARCHAR where
				MySQL uses 2 bytes to store the data len;
				for shorter VARCHARs MySQL uses only 1 byte */

#define DATA_MYSQL_TYPE_MASK 255 /* AND with this mask to extract the MySQL
					type from the precise type */

int  USE_UTF8=1;

int debug=0;

char rowbuffer[1024];

char *mt2typename[] = {
        "",
        "VARCHAR",
        "CHAR",
        "FIXBINARY",
        "BINARY",
        "BLOB",
        "INT",
        "",
        "",
        "FLOAT",
        "DOUBLE",
        "DECIMAL",
        "VARCHAR", /* with collation/charset */
        "MYSQL"
};

char *mysqltype_names[] = {
        "DECIMAL",
        "TINYINT",
        "SMALLINT",
        "INT",
        "FLOAT",
        "DOUBLE",
        "NULL",
        "TIMESTAMP",
        "BIGINT",
        "MEDIUMINT",
        "DATE",
        "TIME",
        "DATETIME",
        "YEAR",
        "DATE", /* new date */
        "VARCHAR",
        "BIT",
"","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","",
        "DECIMAL",
        "ENUM",
        "SET",
        "TINY_BLOB",
        "MEDIUM_BLOB",
        "LONG_BLOB",
        "BLOB",
        "VAR_STRING",
        "TINYINT", /* ENUM */
        "GEOMETRY"
};


char *null_to_string[] = {
        "NULL",
        "NOT NULL"
};


int get_field_length(int type, int len) {
        if(type == MYSQL_TYPE_NEWDECIMAL ) {
                switch(len) {
                        case 4:
                                return 8;
                        case 5:
                                return 10;
                        case 6:
                                return 12;
                        case 7:
                                return 15;
                        case 8:
                                return 17;
                        case 9:
                                return 19;
                        case 10:
                                return 21;
                        case 11:
                                return 24;
                        case 12:
                                return 26;
                        case 13:
                                return 28;
                        case 14:
                                return 30;
                }
                return len*9/4;
        }
        if(type == MYSQL_TYPE_VARCHAR) {
                if(USE_UTF8) {
                        return len/3;
                } else {
                        return len;
                }
        } 
        return 0;
}

int fix_unsigned(int type, int is_unsign) {
        if(type == MYSQL_TYPE_TIMESTAMP || type == MYSQL_TYPE_STRING) {
                return 0;
        }
        return is_unsign;
}

void usage(char* prg){
	fprintf(stderr, "%s [-h <host>] [-P <port>] [-u <user>] [-p <passowrd>] [-d <db>] [-r 0|1 default 0 (recursive search in the schema)] databases/table\n", prg);	
}

void print_type(unsigned long mtype, unsigned long prtype){
	unsigned char type_code = prtype & DATA_MYSQL_TYPE_MASK;
	switch(mtype){
		case DATA_MYSQL:
			printf("CHAR");
			break;
		default:
			printf("%s", mysqltype_names[type_code]);
		
		}
}

int main(int argc, char** argv) {
	char host[1024];
	char user[1024];
	char passwd[1024];
	char db[1024];
	char query[1024];
	char table[1024];
	char tablePrefix[1024];
        char infoschema[1024];
	int port;
	int recursive;
	
	
	MYSQL link;
	MYSQL_RES* result, *result2;
	MYSQL_ROW row, row2;
	char ch;


	unsigned long long int table_id;
	unsigned long long int index_id[128];
	char* charset;
	char* collation;
	unsigned long maxlen;
	/* Set default values */
	strcpy(host, "localhost");
	getlogin_r(user, sizeof(user));
	strcpy(passwd, "");
	strcpy(tablePrefix,"");
	strcpy(db, "INFORMATION_SCHEMA");
        strcpy(infoschema,"INFORMATION_SCHEMA");
	port =3306;
	recursive=0;
	
	/*port = 3306;*/

	while((ch = getopt(argc, argv, "h:u:p:d:g:r:P:")) != -1){
		switch(ch){
			case 'h': strncpy(host, optarg, sizeof(host)); break;
			case 'u': strncpy(user, optarg, sizeof(user)); break;
			case 'p': strncpy(passwd, optarg, sizeof(passwd)); break;
			case 'd': strncpy(db, optarg, sizeof(db)); break;
			case 'P': port = atoi(optarg); break;
			case 'r': recursive = atoi(optarg); break;
			case 'g': debug=1; break;
			default : usage(basename(argv[0])); exit(EXIT_FAILURE);
			}
		}
	if(argv[optind] != NULL){
		strncpy(table, argv[optind], sizeof(table)); 	
		}
	else{
		usage(basename(argv[0])); exit(EXIT_FAILURE);
		}
		
	if(db != "INFORMATION_SCHEMA"){
	    strcpy(infoschema,db);
	}
	else{
	  strcpy(tablePrefix,"INNODB_");
	  //TABLE_ID
	  //INDEX_ID
	  //
	}
	//printf("CREATE TABLE `%s`(\n", strstr(table, "/")+1);
	/* Connect to MySQL*/
	mysql_init(&link);
	if(NULL == mysql_real_connect(&link, host, user, passwd, db, port, NULL, 0)){
		fprintf(stderr,"Error: %s\n", mysql_error(&link));
		exit(EXIT_FAILURE);
		}

	/* Get table_id from SYS_TABLES  
	 IF recursive is activated it will not limit the result to one table but to the whole schema
	 */
	if(recursive){
	    snprintf(query, sizeof(query), "SELECT ID, NAME FROM %s.%sSYS_TABLES WHERE `NAME` LIKE '%s%%' ",infoschema,tablePrefix,table);
	}
	else{
	    snprintf(query, sizeof(query), "SELECT ID, NAME FROM %s.%sSYS_TABLES WHERE `NAME` LIKE '%s%' LLIMIT 1 ",infoschema,tablePrefix,table);
	}
//	fprintf(stderr,"SQL: %s\n", query );
	if(0 != mysql_query(&link, query)){
		fprintf(stderr,"Error: %s\n", mysql_error(&link));
		
		exit(EXIT_FAILURE);
		}
	result = mysql_store_result(&link);
	
	int nTables = mysql_num_rows(result);
	int fields =  mysql_num_fields(result);
	//row = mysql_fetch_row(result);
	
	if(nTables == 0){
		fprintf(stderr, "Table '%s' not found in SYS_TABLES\n", table);
		exit(EXIT_FAILURE);
		}
	
	//Look for multiple tables dumping description for the whole schema
	unsigned long long int tables_id[1024];
	char tables_name[1024][1024];
	char tableNameT[1024];
	int tables_index;
	tables_index=0;
	int tbload;
	tbload=1;
	
	int tb_count;
	tb_count=0;
	
	
	while ((row = mysql_fetch_row(result)))
	{

	      tbload=1;
	      unsigned long *lengths;
	      lengths = mysql_fetch_lengths(result);
	      unsigned int i;
	      
	      snprintf(tableNameT,lengths[1]+1,row[1]);
	      
//	      printf("Table %s length %lu \n",tableNameT, lengths[1]);
//	      printf("Vut %s \n",strstr(tableNameT, "#P"));

	      if(strstr(tableNameT, "#P") != NULL){
		
	      char *token;
	      token = strtok(tableNameT,"#");
	      strcpy(tableNameT,token);
//	      printf("Table %s \n",tableNameT);
	      }
 
	      
	      for (tb_count=0;tb_count < 1024;tb_count++){
		  if(strcmp(tableNameT,tables_name[tb_count]) ==0){
		      tbload=0;
		      break;
		  }
		
	      }
	      if(tbload){
		tables_id[tables_index]=strtoull(row[0], NULL, 10);
		strcpy(tables_name[tables_index],tableNameT);
//		printf("Table ID %d Table Name %s \n",tables_id[tables_index],tableNameT);
		tables_index++;
	      }
	    
	}
	 mysql_free_result(result);
	
	
	for(tb_count=0; tb_count < tables_index ; tb_count++){
	  
	    strcpy(tableNameT,"");
	    
	    table_id = tables_id[tb_count];
	    //strcpy(tableNameT,tables_name[tb_count]);
	    strcpy(tableNameT,strstr(tables_name[tb_count], "/")+1);
	    
	    //strtoull(row[0], NULL, 10);
	    if(debug) printf("-- `%s`: table_id = %llu\n", tableNameT, table_id);
	    //mysql_free_result(result);

	    /* Get array of index_id */
	    snprintf(query, sizeof(query), "SELECT ID FROM  %s.SYS_INDEXES WHERE TABLE_ID='%llu' ORDER BY ID",infoschema, table_id);
	    if(0 != mysql_query(&link, query)){
		    fprintf(stderr,"Error: %s\n", mysql_error(&link));
		    exit(EXIT_FAILURE);
		    }
	    result = mysql_store_result(&link);
	    int n = mysql_num_rows(result);
	    if(n == 0){
		    fprintf(stderr, "Index records are not found for table '%s' in SYS_INDEXES\n", tableNameT);
		    exit(EXIT_FAILURE);
		    }
	    int i = 0;
	    for(i = 0; i < n; i++){
		    row = mysql_fetch_row(result);
		    index_id[i] = strtoull(row[0], NULL, 10);
		    if(debug) printf("-- `%s`: index_id = %llu\n", tableNameT, index_id[i]);
		    }
	    mysql_free_result(result);

	    /* Get array of fields */
	    snprintf(query, sizeof(query), "SELECT TABLE_ID, POS, NAME, MTYPE, PRTYPE, LEN, POS as PREC FROM  %s.SYS_COLUMNS WHERE TABLE_ID='%llu' ORDER BY POS",infoschema, table_id);
	    if(0 != mysql_query(&link, query)){
		    fprintf(stderr,"Error: %s\n", mysql_error(&link));
		    exit(EXIT_FAILURE);
		    }
	    result = mysql_store_result(&link);
	    n = mysql_num_rows(result);
	    if(n == 0){
		    fprintf(stderr, "Fields are not found for table '%s' in SYS_COLUMNS\n", tableNameT);
		    exit(EXIT_FAILURE);
		    }

	    printf("CREATE TABLE IF NOT EXISTS `%s`(\n", tableNameT);
	   // printf("CREATE TABLE `%s`(\n", strstr(table, "/")+1);

	    for(i = 0; i < n; i++){
		    row = mysql_fetch_row(result);
		    unsigned long mtype = strtoul(row[3], NULL, 10);
		    if(debug) printf("-- `%s`: mtype = %lu\n", row[2], mtype);
		    unsigned long prtype = strtoul(row[4], NULL, 10);
		    if(debug) printf("-- `%s`: prtype = 0x%08lX(%lu)\n", row[2], prtype, prtype);
		    unsigned char type_code = prtype & DATA_MYSQL_TYPE_MASK; 
		    if(debug) printf("-- `%s`: mysql type = %u\n", row[2], type_code);
		    int unsigned_flag = (prtype & DATA_UNSIGNED) ? 1 : 0;
		    int not_null_flag = (prtype & DATA_NOT_NULL) ? 1 : 0;
		    int binarytype_flag = (prtype & DATA_BINARY_TYPE)? 1 : 0;
		    int logn_true_varchar_flag = (prtype & DATA_LONG_TRUE_VARCHAR)? 1 : 0;
		    unsigned c_code = ((prtype >> 16) & 0xFFUL);
		    unsigned long len = strtoul(row[5], NULL, 10);
		    if(c_code != 0){
			    snprintf(query, sizeof(query), "SELECT COLLATIONS.CHARACTER_SET_NAME, COLLATIONS.COLLATION_NAME, CHARACTER_SETS.MAXLEN  FROM  information_schema.COLLATIONS LEFT JOIN information_schema.CHARACTER_SETS ON  information_schema.COLLATIONS.CHARACTER_SET_NAME = CHARACTER_SETS.CHARACTER_SET_NAME WHERE COLLATIONS.ID = '%u';", c_code);
			    
			    if(0 != mysql_query(&link, query)){
				    fprintf(stderr,"Error: %s\n", mysql_error(&link));
				    exit(EXIT_FAILURE);
				    }
			    result2 = mysql_store_result(&link);
			    if(mysql_num_rows(result2)>0){
				    row2 = mysql_fetch_row(result2);
				    charset = row2[0];
				    collation = row2[1];
				    maxlen = strtoul(row2[2], NULL, 10);
				    mysql_free_result(result2);
				    if(debug) printf("-- charset: %s , collation %s maxlen = %lu\n", charset, collation, maxlen);
				    }
			    else{
				    fprintf(stderr, "Couldn't find charset-collcation details for collation id = %u  SQL: %s\n", c_code,query);
				    exit(EXIT_FAILURE);
				    }
			    }	
		    if(debug) printf("-- `%s`: c_code = %u\n", row[2], c_code);
		    printf("\t`%s` ", row[2]);
		    print_type(mtype, prtype);
		    if(mtype == DATA_VARCHAR ||
				    mtype == DATA_CHAR ||
				    mtype == DATA_VARMYSQL || 
				    mtype == DATA_MYSQL){
			    len /= maxlen;
			    printf("(%lu)", len);
			    printf(" CHARACTER SET '%s'", charset);
			    printf(" COLLATE '%s'", collation);
			    }
		    if(mtype == DATA_FIXBINARY && type_code == MYSQL_TYPE_NEWDECIMAL){
			    printf("(%lu,0)", len * 2);
			    }
		    if(type_code == MYSQL_TYPE_TINY ||
				    type_code == MYSQL_TYPE_SHORT ||
				    type_code == MYSQL_TYPE_LONG ||
				    type_code == MYSQL_TYPE_LONGLONG ||
				    type_code == MYSQL_TYPE_INT24
				    ){
			    if(unsigned_flag) printf(" UNSIGNED");
			    }
		    if(not_null_flag) printf(" NOT NULL");
		    if(mtype == DATA_VARCHAR ||
				    mtype == DATA_CHAR ){
			    if(binarytype_flag) printf(" BINARY");
			    }
		    printf(",\n");

		    }
	    mysql_free_result(result);
	    /* Now print PRIMARY KEY */
	    snprintf(query, sizeof(query), "SELECT COL_NAME from  %s.SYS_FIELDS WHERE INDEX_ID = %llu ORDER BY POS;",infoschema, index_id[0]);
	    if(0 != mysql_query(&link, query)){
		    fprintf(stderr,"Error: %s\n", mysql_error(&link));
		    exit(EXIT_FAILURE);
		    }
	    result = mysql_store_result(&link);
	    n = mysql_num_rows(result);
	    if(n == 0){
		    fprintf(stderr, "Fields are not found for table '%s' in SYS_FIELDS\n", tableNameT);
		    exit(EXIT_FAILURE);
		    }
	    printf("\tPRIMARY KEY (", tableNameT);
	    int comma=0;
	    for(i = 0; i < n; i++){
		    row = mysql_fetch_row(result);
		    if(comma) printf(", ");
		    printf("`%s`", row[0]);
		    comma=1;
		    }
	    printf(")\n", tableNameT);
	    printf(") ENGINE=InnoDB;\n");

	    printf("\n\n", tableNameT);
	}    
	exit(EXIT_SUCCESS);
}
