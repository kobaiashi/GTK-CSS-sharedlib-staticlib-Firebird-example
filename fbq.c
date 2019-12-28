#include <stdlib.h>
#include <string.h>
#include <ibase.h>
#include <stdio.h>
#include <gtk/gtk.h>
#include <iberror.h>
#include <ib_util.h>

#include "fbq.h"
/* This macro is used to declare structures representing SQL VARCHAR types */
#define SQL_VARCHAR(len) struct {short vary_length; char vary_string[(len)+1];}
#define ERREXIT(status, rc)	{isc_print_status(status); return rc;}

#define    LASTLEN     20
#define    FIRSTLEN    15
#define    EXTLEN       4

isc_db_handle    DB = 0;                       /* database handle */
isc_tr_handle    trans = 0;                    /* transaction handle */
ISC_STATUS_ARRAY status;                       /* status vector */

/* "employee.fdb" */
int conenctdb(const char *db_name,GArray *res)
{
  /* int                num_cols, i; */
  isc_stmt_handle    stmt = NULL;
  XSQLDA             *sqlda;
  SQL_VARCHAR(LASTLEN)    last_name;
  SQL_VARCHAR(FIRSTLEN)   first_name;
  char                    phone_ext[EXTLEN + 2];
  long                    fetch_stat;
  short                   flag0 = 0, flag1 = 0, flag2 = 0;
  elemento e;
  gchar *db_path=NULL;

  char *sel_str =
        "SELECT last_name, first_name, phone_ext FROM phone_list \
        WHERE location = 'Monterey' ORDER BY last_name, first_name;";
  /* strcpy(empdb, dbname); */
  printf("conenctdb\n");

  /*
  strcpy(user_name, "guest");
  strcpy(password, "guest");
  strcpy(dbname, "employee.fdb");
  */

  db_path=g_strdup_printf("./db/%s.fdb",db_name);
/*
  if (isc_attach_database(status, 0, dbname, &DB, dpb_length, dpb))
      isc_print_status(status);
*/

  g_print("db_path:%s\n",db_path);

  if (isc_attach_database(status, 0, db_path, &DB, 0, NULL))
    {
      g_print("no connection\n");
      ERREXIT(status, 1);
    }

    /* Allocate an output SQLDA. */
    sqlda = (XSQLDA *) malloc(XSQLDA_LENGTH(3));
    sqlda->sqln = 3;
    sqlda->sqld = 3;
    sqlda->version = 1;

    if (isc_start_transaction(status, &trans, 1, &DB, 0, NULL))
    {
        ERREXIT(status, 1)
    }

    /* Allocate a statement. */
    if (isc_dsql_allocate_statement(status, &DB, &stmt))
    {
        ERREXIT(status, 1)
    }

    /* Prepare the statement. */
    if (isc_dsql_prepare(status, &trans, &stmt, 0, sel_str, 1, sqlda))
    {
        ERREXIT(status, 1)
    }

    /*
    *  Although all three selected columns are of type varchar, the
    *  third field's type is changed and printed as type TEXT.
    */

   sqlda->sqlvar[0].sqldata = (char *)&last_name;
   sqlda->sqlvar[0].sqltype = SQL_VARYING + 1;
   sqlda->sqlvar[0].sqlind  = &flag0;

   sqlda->sqlvar[1].sqldata = (char *)&first_name;
   sqlda->sqlvar[1].sqltype = SQL_VARYING + 1;
   sqlda->sqlvar[1].sqlind  = &flag1;

   sqlda->sqlvar[2].sqldata = (char *) phone_ext;
   sqlda->sqlvar[2].sqltype = SQL_TEXT + 1;
   sqlda->sqlvar[2].sqlind  = &flag2;

   printf("\n%-20s %-15s %-10s\n\n", "LAST NAME", "FIRST NAME", "EXTENSION");

   /* Execute the statement. */
   if (isc_dsql_execute(status, &trans, &stmt, 1, NULL))
       {
           ERREXIT(status, 1)
       }

       /*
        *    Fetch and print the records.
        *    Status is 100 after the last row is fetched.
        */
  while ((fetch_stat = isc_dsql_fetch(status, &stmt, 1, sqlda)) == 0)
       {
           printf("%-20.*s ", last_name.vary_length, last_name.vary_string);

           printf("%-15.*s ", first_name.vary_length, first_name.vary_string);

           phone_ext[sqlda->sqlvar[2].sqllen] = '\0';
           printf("%s\n", phone_ext);

           e.first_name=g_strdup( first_name.vary_string);
           e.last_name=g_strdup(last_name.vary_string);
           e.extension=g_strdup(phone_ext);
           g_array_append_val(res,e);

       }

   if (fetch_stat != 100L)
       {
           ERREXIT(status, 1)
       }

       /* Free statement handle. */
   if (isc_dsql_free_statement(status, &stmt, DSQL_close))
       {
           ERREXIT(status, 1)
       }


  if (isc_commit_transaction(status, &trans))
       {
           ERREXIT(status, 1)
       }

  if (isc_detach_database(status, &DB))
       {
           ERREXIT(status, 1)
       }
  g_print("isc_detach_database\n");

  free( sqlda);

  return (0);
}
