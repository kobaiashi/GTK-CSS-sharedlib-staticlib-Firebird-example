-- This is a generated file
set sql dialect 3;
create database 'employee.fdb';
/*
 * The contents of this file are subject to the Interbase Public
 * License Version 1.0 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy
 * of the License at http://www.Inprise.com/IPL.html
 *
 * Software distributed under the License is distributed on an
 * "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express
 * or implied. See the License for the specific language governing
 * rights and limitations under the License.
 *
 * The Original Code was created by Inprise Corporation
 * and its predecessors. Portions created by Inprise Corporation are
 * Copyright (C) Inprise Corporation.
 *
 * All Rights Reserved.
 * Contributor(s): ______________________________________.
 */
/*create database "employee.fdb";*/
/**
 **  Create a sample employee database.
 **
 **  This database keeps track of employees, departments, projects, and sales
 **  for a small company.
 **
 **/


/*
 *   Define domains.
 */
/* set echo on;
*/

CREATE DOMAIN firstname     AS VARCHAR(15);

CREATE DOMAIN lastname      AS VARCHAR(20);

CREATE DOMAIN phonenumber   AS VARCHAR(20);

CREATE DOMAIN countryname   AS VARCHAR(15);

CREATE DOMAIN addressline   AS VARCHAR(30);


CREATE DOMAIN empno
    AS SMALLINT;

CREATE DOMAIN deptno
    AS CHAR(3)
    CHECK (VALUE = '000' OR (VALUE > '0' AND VALUE <= '999') OR VALUE IS NULL);

CREATE DOMAIN projno
    AS CHAR(5)
    CHECK (VALUE = UPPER (VALUE));

CREATE DOMAIN custno
    AS INTEGER
    CHECK (VALUE > 1000);

/* must begin with a letter */
CREATE DOMAIN jobcode
    AS VARCHAR(5)
    CHECK (VALUE > '99999');

CREATE DOMAIN jobgrade
    AS SMALLINT
    CHECK (VALUE BETWEEN 0 AND 6);

/* salary is in any currency type */
CREATE DOMAIN salary
    AS NUMERIC(10,2)
    DEFAULT 0
    CHECK (VALUE > 0);

/* budget is in US dollars */
CREATE DOMAIN budget
    AS DECIMAL(12,2)
    DEFAULT 50000
    CHECK (VALUE > 10000 AND VALUE <= 2000000);

CREATE DOMAIN prodtype
    AS VARCHAR(12)
    DEFAULT 'software' NOT NULL
    CHECK (VALUE IN ('software', 'hardware', 'other', 'N/A'));

CREATE DOMAIN PONUMBER
    AS CHAR(8)
    CHECK (VALUE STARTING WITH 'V');


/*
 *  Create generators.
 */

CREATE GENERATOR emp_no_gen;

CREATE GENERATOR cust_no_gen;
SET GENERATOR cust_no_gen to 1000;

COMMIT;

/*
 *  Create tables.
 */


/*
 *  Country name, currency type.
 */
CREATE TABLE country
(
    country         COUNTRYNAME NOT NULL PRIMARY KEY,
    currency        VARCHAR(10) NOT NULL
);


/*
 *  Job id, job title, minimum and maximum salary, job description,
 *  and required languages.
 *
 *  A job is defined by a multiple key, consisting of a job_code
 *  (a 5-letter job abbreviation), a job grade, and a country name
 *  indicating the salary currency type.
 *
 *  The salary range is expressed in the appropriate country's currency.
 *
 *  The job requirement is a text blob.
 *
 *  The job may also require some knowledge of foreign languages,
 *  stored in a character array.
 */
CREATE TABLE job
(
    job_code            JOBCODE NOT NULL,
    job_grade           JOBGRADE NOT NULL,
    job_country         COUNTRYNAME NOT NULL,
    job_title           VARCHAR(25) NOT NULL,
    min_salary          SALARY NOT NULL,
    max_salary          SALARY NOT NULL,
    job_requirement     BLOB(400,1),
    language_req        VARCHAR(15) [5],

    PRIMARY KEY (job_code, job_grade, job_country),
    FOREIGN KEY (job_country) REFERENCES country (country),

    CHECK (min_salary < max_salary)
);

CREATE ASCENDING INDEX minsalx ON job (job_country, min_salary);
CREATE DESCENDING INDEX maxsalx ON job (job_country, max_salary);


/*
 *  Department number, name, head department, manager id,
 *  budget, location, department phone number.
 *
 *  Each department is a sub-department in some department, determined
 *  by head_dept.  The head of this tree is the company.
 *  This information is used to produce a company organization chart.
 *
 *  Departments have managers; however, manager id can be null to allow
 *  for temporary situations where a manager needs to be hired.
 *
 *  Budget is allocated in U.S. dollars for all departments.
 *
 *  Foreign key mngr_no is added after the employee table is created,
 *  using 'alter table'.
 */
CREATE TABLE department
(
    dept_no         DEPTNO NOT NULL,
    department      VARCHAR(25) NOT NULL UNIQUE,
    head_dept       DEPTNO,
    mngr_no         EMPNO,
    budget          BUDGET,
    location        VARCHAR(15),
    phone_no        PHONENUMBER DEFAULT '555-1234',

    PRIMARY KEY (dept_no),
    FOREIGN KEY (head_dept) REFERENCES department (dept_no)
);

CREATE DESCENDING INDEX budgetx ON department (budget);


/*
 *  Employee id, name, phone extension, date of hire, department id,
 *  job and salary information.
 *
 *  Salary can be entered in any country's currency.
 *  Therefore, some of the salaries can appear magnitudes larger than others,
 *  depending on the currency type.  Ex. Italian lira vs. U.K. pound.
 *  The currency type is determined by the country code.
 *
 *  job_code, job_grade, and job_country reference employee's job information,
 *  illustrating two tables related by referential constraints on multiple
 *  columns.
 *
 *  The employee salary is verified to be in the correct salary range
 *  for the given job title.
 */
CREATE TABLE employee
(
    emp_no          EMPNO NOT NULL,
    first_name      FIRSTNAME NOT NULL,
    last_name       LASTNAME NOT NULL,
    phone_ext       VARCHAR(4),
    hire_date       TIMESTAMP DEFAULT 'NOW' NOT NULL,
    dept_no         DEPTNO NOT NULL,
    job_code        JOBCODE NOT NULL,
    job_grade       JOBGRADE NOT NULL,
    job_country     COUNTRYNAME NOT NULL,
    salary          SALARY NOT NULL,
    full_name       COMPUTED BY (last_name || ', ' || first_name),

    PRIMARY KEY (emp_no),
    FOREIGN KEY (dept_no) REFERENCES
            department (dept_no),
    FOREIGN KEY (job_code, job_grade, job_country) REFERENCES
            job (job_code, job_grade, job_country),

    CHECK ( salary >= (SELECT min_salary FROM job WHERE
                        job.job_code = employee.job_code AND
                        job.job_grade = employee.job_grade AND
                        job.job_country = employee.job_country) AND
            salary <= (SELECT max_salary FROM job WHERE
                        job.job_code = employee.job_code AND
                        job.job_grade = employee.job_grade AND
                        job.job_country = employee.job_country))
);

CREATE INDEX namex ON employee (last_name, first_name);

CREATE VIEW phone_list AS SELECT
    emp_no, first_name, last_name, phone_ext, location, phone_no
    FROM employee, department
    WHERE employee.dept_no = department.dept_no;

COMMIT;

SET TERM !! ;

CREATE TRIGGER set_emp_no FOR employee
BEFORE INSERT AS
BEGIN
    if (new.emp_no is null) then
    new.emp_no = gen_id(emp_no_gen, 1);
END !!

SET TERM ; !!


/*
 *  Add an additional constraint to department: check manager numbers
 *  in the employee table.
 */
ALTER TABLE department ADD FOREIGN KEY (mngr_no) REFERENCES employee (emp_no);


/*
 *  Project id, project name, description, project team leader,
 *  and product type.
 *
 *  Project description is a text blob.
 */
CREATE TABLE project
(
    proj_id         PROJNO NOT NULL,
    proj_name       VARCHAR(20) NOT NULL UNIQUE,
    proj_desc       BLOB(800,1),
    team_leader     EMPNO,
    product         PRODTYPE,

    PRIMARY KEY (proj_id),
    FOREIGN KEY (team_leader) REFERENCES employee (emp_no)
);

CREATE UNIQUE INDEX prodtypex ON project (product, proj_name);


/*
 *  Employee id, project id, employee's project duties.
 *
 *  Employee duties is a text blob.
 */
CREATE TABLE employee_project
(
    emp_no          EMPNO NOT NULL,
    proj_id         PROJNO NOT NULL,

    PRIMARY KEY (emp_no, proj_id),
    FOREIGN KEY (emp_no) REFERENCES employee (emp_no),
    FOREIGN KEY (proj_id) REFERENCES project (proj_id)
);


/*
 *  Fiscal year, project id, department id, projected head count by
 *  fiscal quarter, projected budget.
 *
 *  Tracks head count and budget planning by project by department.
 *
 *  Quarterly head count is an array of integers.
 */
CREATE TABLE proj_dept_budget
(
    fiscal_year         INTEGER NOT NULL CHECK (FISCAL_YEAR >= 1993),
    proj_id             PROJNO NOT NULL,
    dept_no             DEPTNO NOT NULL,
    quart_head_cnt      INTEGER [4],
    projected_budget    BUDGET,

    PRIMARY KEY (fiscal_year, proj_id, dept_no),
    FOREIGN KEY (dept_no) REFERENCES department (dept_no),
    FOREIGN KEY (proj_id) REFERENCES project (proj_id)
);


/*
 *  Employee number, salary change date, updater's user id, old salary,
 *  and percent change between old and new salary.
 */
CREATE TABLE salary_history
(
    emp_no              EMPNO NOT NULL,
    change_date         TIMESTAMP DEFAULT 'NOW' NOT NULL,
    updater_id          VARCHAR(20) NOT NULL,
    old_salary          SALARY NOT NULL,
    percent_change      DOUBLE PRECISION
                            DEFAULT 0
                            NOT NULL
                            CHECK (percent_change between -50 and 50),
    new_salary          COMPUTED BY
                            (old_salary + old_salary * percent_change / 100),

    PRIMARY KEY (emp_no, change_date, updater_id),
    FOREIGN KEY (emp_no) REFERENCES employee (emp_no)
);

CREATE INDEX updaterx ON salary_history (updater_id);
CREATE DESCENDING INDEX changex ON salary_history (change_date);

COMMIT;

SET TERM !! ;

CREATE TRIGGER save_salary_change FOR employee
AFTER UPDATE AS
BEGIN
    IF (old.salary <> new.salary) THEN
        INSERT INTO salary_history
            (emp_no, change_date, updater_id, old_salary, percent_change)
        VALUES (
            old.emp_no,
            'NOW',
            user,
            old.salary,
            (new.salary - old.salary) * 100 / old.salary);
END !!

SET TERM ; !!

COMMIT;


/*
 *  Customer id, customer name, contact first and last names,
 *  phone number, address lines, city, state or province, country,
 *  postal code or zip code, and customer status.
 */
CREATE TABLE customer
(
    cust_no             CUSTNO NOT NULL,
    customer            VARCHAR(25) NOT NULL,
    contact_first       FIRSTNAME,
    contact_last        LASTNAME,
    phone_no            PHONENUMBER,
    address_line1       ADDRESSLINE,
    address_line2       ADDRESSLINE,
    city                VARCHAR(25),
    state_province      VARCHAR(15),
    country             COUNTRYNAME,
    postal_code         VARCHAR(12),
    on_hold             CHAR
                            DEFAULT NULL
                            CHECK (on_hold IS NULL OR on_hold = '*'),
    PRIMARY KEY (cust_no),
    FOREIGN KEY (country) REFERENCES country (country)
);

CREATE INDEX custnamex ON customer (customer);
CREATE INDEX custregion ON customer (country, city);

SET TERM !! ;

CREATE TRIGGER set_cust_no FOR customer
BEFORE INSERT AS
BEGIN
    if (new.cust_no is null) then
    new.cust_no = gen_id(cust_no_gen, 1);
END !!

SET TERM ; !!

COMMIT;


/*
 *  Purchase order number, customer id, sales representative, order status,
 *  order date, date shipped, date need to ship by, payment received flag,
 *  quantity ordered, total order value, type of product ordered,
 *  any percent discount offered.
 *
 *  Tracks customer orders.
 *
 *  sales_rep is the ID of the employee handling the sale.
 *
 *  Number of days passed since the order date is a computed field.
 *
 *  Several checks are performed on this table, among them:
 *      - A sale order must have a status: open, shipped, waiting.
 *      - The ship date must be entered, if order status is 'shipped'.
 *      - New orders can't be shipped to customers with 'on_hold' status.
 *      - Sales rep
 */
CREATE TABLE sales
(
    po_number       PONUMBER NOT NULL,
    cust_no         CUSTNO NOT NULL,
    sales_rep       EMPNO,
    order_status    VARCHAR(7)
                        DEFAULT 'new'
                        NOT NULL
                        CHECK (order_status in
                            ('new', 'open', 'shipped', 'waiting')),
    order_date      TIMESTAMP
                        DEFAULT 'NOW' 
                        NOT NULL,
    ship_date       TIMESTAMP
                        CHECK (ship_date >= order_date OR ship_date IS NULL),
    date_needed     TIMESTAMP
                        CHECK (date_needed > order_date OR date_needed IS NULL),
    paid            CHAR
                        DEFAULT 'n'
                        CHECK (paid in ('y', 'n')),
    qty_ordered     INTEGER
                        DEFAULT 1
                        NOT NULL
                        CHECK (qty_ordered >= 1),
    total_value     DECIMAL(9,2)
                        NOT NULL
                        CHECK (total_value >= 0),
    discount        FLOAT
                        DEFAULT 0
                        NOT NULL
                        CHECK (discount >= 0 AND discount <= 1),
    item_type       PRODTYPE,
    aged            COMPUTED BY
                        (ship_date - order_date),

    PRIMARY KEY (po_number),
    FOREIGN KEY (cust_no) REFERENCES customer (cust_no),
    FOREIGN KEY (sales_rep) REFERENCES employee (emp_no),

    CHECK (NOT (order_status = 'shipped' AND ship_date IS NULL)),

    CHECK (NOT (order_status = 'shipped' AND
            EXISTS (SELECT on_hold FROM customer
                    WHERE customer.cust_no = sales.cust_no
                    AND customer.on_hold = '*')))
);

CREATE INDEX needx ON sales (date_needed);
CREATE INDEX salestatx ON sales (order_status, paid);
CREATE DESCENDING INDEX qtyx ON sales (item_type, qty_ordered);

SET TERM !! ;

CREATE TRIGGER post_new_order FOR sales
AFTER INSERT AS
BEGIN
    POST_EVENT 'new_order';
END !!

SET TERM ; !!

COMMIT;





/****************************************************************************
 *
 *	Create stored procedures.
 * 
*****************************************************************************/


SET TERM !! ;

/*
 *	Get employee's projects.
 *
 *	Parameters:
 *		employee number
 *	Returns:
 *		project id
 */

CREATE PROCEDURE get_emp_proj (emp_no SMALLINT)
RETURNS (proj_id CHAR(5)) AS
BEGIN
	FOR SELECT proj_id
		FROM employee_project
		WHERE emp_no = :emp_no
		INTO :proj_id
	DO
		SUSPEND;
END !!



/*
 *	Add an employee to a project.
 *
 *	Parameters:
 *		employee number
 *		project id
 *	Returns:
 *		--
 */

CREATE EXCEPTION unknown_emp_id 'Invalid employee number or project id.' !!

CREATE PROCEDURE add_emp_proj (emp_no SMALLINT, proj_id CHAR(5))  AS
BEGIN
	BEGIN
	INSERT INTO employee_project (emp_no, proj_id) VALUES (:emp_no, :proj_id);
	WHEN SQLCODE -530 DO
		EXCEPTION unknown_emp_id;
	END
	SUSPEND;
END !!



/*
 *	Select one row.
 *
 *	Compute total, average, smallest, and largest department budget.
 *
 *	Parameters:
 *		department id
 *	Returns:
 *		total budget
 *		average budget
 *		min budget
 *		max budget
 */

CREATE PROCEDURE sub_tot_budget (head_dept CHAR(3))
RETURNS (tot_budget DECIMAL(12, 2), avg_budget DECIMAL(12, 2),
	min_budget DECIMAL(12, 2), max_budget DECIMAL(12, 2))
AS
BEGIN
	SELECT SUM(budget), AVG(budget), MIN(budget), MAX(budget)
		FROM department
		WHERE head_dept = :head_dept
		INTO :tot_budget, :avg_budget, :min_budget, :max_budget;
	SUSPEND;
END !!



/*
 *	Delete an employee.
 *
 *	Parameters:
 *		employee number
 *	Returns:
 *		--
 */

CREATE EXCEPTION reassign_sales
		'Reassign the sales records before deleting this employee.' !!

CREATE PROCEDURE delete_employee (emp_num INTEGER)
AS
	DECLARE VARIABLE any_sales INTEGER;
BEGIN
	any_sales = 0;

	/*
	 *	If there are any sales records referencing this employee,
	 *	can't delete the employee until the sales are re-assigned
	 *	to another employee or changed to NULL.
	 */
	SELECT count(po_number)
	FROM sales
	WHERE sales_rep = :emp_num
	INTO :any_sales;

	IF (any_sales > 0) THEN
	BEGIN
		EXCEPTION reassign_sales;
		SUSPEND;
	END

	/*
	 *	If the employee is a manager, update the department.
	 */
	UPDATE department
	SET mngr_no = NULL
	WHERE mngr_no = :emp_num;

	/*
	 *	If the employee is a project leader, update project.
	 */
	UPDATE project
	SET team_leader = NULL
	WHERE team_leader = :emp_num;

	/*
	 *	Delete the employee from any projects.
	 */
	DELETE FROM employee_project
	WHERE emp_no = :emp_num;

	/*
	 *	Delete old salary records.
	 */
	DELETE FROM salary_history
	WHERE emp_no = :emp_num;

	/*
	 *	Delete the employee.
	 */
	DELETE FROM employee
	WHERE emp_no = :emp_num;

	SUSPEND;
END !!



/*
 *	Recursive procedure.
 *
 *	Compute the sum of all budgets for a department and all the
 *	departments under it.
 *
 *	Parameters:
 *		department id
 *	Returns:
 *		total budget
 */

CREATE PROCEDURE dept_budget (dno CHAR(3))
RETURNS (tot decimal(12,2)) AS
	DECLARE VARIABLE sumb DECIMAL(12, 2);
	DECLARE VARIABLE rdno CHAR(3);
	DECLARE VARIABLE cnt INTEGER;
BEGIN
	tot = 0;

	SELECT budget FROM department WHERE dept_no = :dno INTO :tot;

	SELECT count(budget) FROM department WHERE head_dept = :dno INTO :cnt;

	IF (cnt = 0) THEN
		SUSPEND;

	FOR SELECT dept_no
		FROM department
		WHERE head_dept = :dno
		INTO :rdno
	DO
		BEGIN
			EXECUTE PROCEDURE dept_budget :rdno RETURNING_VALUES :sumb;
			tot = tot + sumb;
		END

	SUSPEND;
END !!



/*
 *	Display an org-chart.
 *
 *	Parameters:
 *		--
 *	Returns:
 *		parent department
 *		department name
 *		department manager
 *		manager's job title
 *		number of employees in the department
 */

CREATE PROCEDURE org_chart
RETURNS (head_dept CHAR(25), department CHAR(25),
		mngr_name CHAR(20), title CHAR(5), emp_cnt INTEGER)
AS
	DECLARE VARIABLE mngr_no INTEGER;
	DECLARE VARIABLE dno CHAR(3);
BEGIN
	FOR SELECT h.department, d.department, d.mngr_no, d.dept_no
		FROM department d
		LEFT OUTER JOIN department h ON d.head_dept = h.dept_no
		ORDER BY d.dept_no
		INTO :head_dept, :department, :mngr_no, :dno
	DO
	BEGIN
		IF (:mngr_no IS NULL) THEN
		BEGIN
			mngr_name = '--TBH--';
			title = '';
		END

		ELSE
			SELECT full_name, job_code
			FROM employee
			WHERE emp_no = :mngr_no
			INTO :mngr_name, :title;

		SELECT COUNT(emp_no)
		FROM employee
		WHERE dept_no = :dno
		INTO :emp_cnt;

		SUSPEND;
	END
END !!



/*
 *	Generate a 6-line mailing label for a customer.
 *	Some of the lines may be blank.
 *
 *	Parameters:
 *		customer number
 *	Returns:
 *		6 address lines
 */

CREATE PROCEDURE mail_label (cust_no INTEGER)
RETURNS (line1 CHAR(40), line2 CHAR(40), line3 CHAR(40),
		line4 CHAR(40), line5 CHAR(40), line6 CHAR(40))
AS
	DECLARE VARIABLE customer	VARCHAR(25);
	DECLARE VARIABLE first_name		VARCHAR(15);
	DECLARE VARIABLE last_name		VARCHAR(20);
	DECLARE VARIABLE addr1		VARCHAR(30);
	DECLARE VARIABLE addr2		VARCHAR(30);
	DECLARE VARIABLE city		VARCHAR(25);
	DECLARE VARIABLE state		VARCHAR(15);
	DECLARE VARIABLE country	VARCHAR(15);
	DECLARE VARIABLE postcode	VARCHAR(12);
	DECLARE VARIABLE cnt		INTEGER;
BEGIN
	line1 = '';
	line2 = '';
	line3 = '';
	line4 = '';
	line5 = '';
	line6 = '';

	SELECT customer, contact_first, contact_last, address_line1,
		address_line2, city, state_province, country, postal_code
	FROM CUSTOMER
	WHERE cust_no = :cust_no
	INTO :customer, :first_name, :last_name, :addr1, :addr2,
		:city, :state, :country, :postcode;

	IF (customer IS NOT NULL) THEN
		line1 = customer;
	IF (first_name IS NOT NULL) THEN
		line2 = first_name || ' ' || last_name;
	ELSE
		line2 = last_name;
	IF (addr1 IS NOT NULL) THEN
		line3 = addr1;
	IF (addr2 IS NOT NULL) THEN
		line4 = addr2;

	IF (country = 'USA') THEN
	BEGIN
		IF (city IS NOT NULL) THEN
			line5 = city || ', ' || state || '  ' || postcode;
		ELSE
			line5 = state || '  ' || postcode;
	END
	ELSE
	BEGIN
		IF (city IS NOT NULL) THEN
			line5 = city || ', ' || state;
		ELSE
			line5 = state;
		line6 = country || '    ' || postcode;
	END

	SUSPEND;
END !!



/*
 *	Ship a sales order.
 *	First, check if the order is already shipped, if the customer
 *	is on hold, or if the customer has an overdue balance.
 *
 *	Parameters:
 *		purchase order number
 *	Returns:
 *		--
 *
 */

CREATE EXCEPTION order_already_shipped 'Order status is "shipped."' !!
CREATE EXCEPTION customer_on_hold 'This customer is on hold.' !!
CREATE EXCEPTION customer_check 'Overdue balance -- can not ship.' !!

CREATE PROCEDURE ship_order (po_num CHAR(8))
AS
	DECLARE VARIABLE ord_stat CHAR(7);
	DECLARE VARIABLE hold_stat CHAR(1);
	DECLARE VARIABLE cust_no INTEGER;
	DECLARE VARIABLE any_po CHAR(8);
BEGIN
	SELECT s.order_status, c.on_hold, c.cust_no
	FROM sales s, customer c
	WHERE po_number = :po_num
	AND s.cust_no = c.cust_no
	INTO :ord_stat, :hold_stat, :cust_no;

	/* This purchase order has been already shipped. */
	IF (ord_stat = 'shipped') THEN
	BEGIN
		EXCEPTION order_already_shipped;
		SUSPEND;
	END

	/*	Customer is on hold. */
	ELSE IF (hold_stat = '*') THEN
	BEGIN
		EXCEPTION customer_on_hold;
		SUSPEND;
	END

	/*
	 *	If there is an unpaid balance on orders shipped over 2 months ago,
	 *	put the customer on hold.
	 */
	FOR SELECT po_number
		FROM sales
		WHERE cust_no = :cust_no
		AND order_status = 'shipped'
		AND paid = 'n'
		AND ship_date < CAST('NOW' AS TIMESTAMP) - 60
		INTO :any_po
	DO
	BEGIN
		EXCEPTION customer_check;

		UPDATE customer
		SET on_hold = '*'
		WHERE cust_no = :cust_no;

		SUSPEND;
	END

	/*
	 *	Ship the order.
	 */
	UPDATE sales
	SET order_status = 'shipped', ship_date = 'NOW'
	WHERE po_number = :po_num;

	SUSPEND;
END !!


CREATE PROCEDURE show_langs (code VARCHAR(5), grade SMALLINT, cty VARCHAR(15))
  RETURNS (languages VARCHAR(15))
AS
DECLARE VARIABLE i INTEGER;
BEGIN
  i = 1;
  WHILE (i <= 5) DO
  BEGIN
    SELECT language_req[:i] FROM joB
    WHERE ((job_code = :code) AND (job_grade = :grade) AND (job_country = :cty)
           AND (language_req IS NOT NULL))
    INTO :languages;
    IF (languages = ' ') THEN  /* Prints 'NULL' instead of blanks */
       languages = 'NULL';         
    i = i +1;
    SUSPEND;
  END
END!!



CREATE PROCEDURE all_langs RETURNS 
    (code VARCHAR(5), grade VARCHAR(5), 
     country VARCHAR(15), LANG VARCHAR(15)) AS
    BEGIN
	FOR SELECT job_code, job_grade, job_country FROM job 
		INTO :code, :grade, :country

	DO
	BEGIN
	    FOR SELECT languages FROM show_langs 
 		    (:code, :grade, :country) INTO :lang DO
	        SUSPEND;
	    /* Put nice separators between rows */
	    code = '=====';
	    grade = '=====';
	    country = '===============';
	    lang = '==============';
	    SUSPEND;
	END
    END!!

SET TERM ; !!

/* Privileges */

GRANT ALL PRIVILEGES ON country TO PUBLIC WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON job TO PUBLIC WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON department TO PUBLIC WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON employee TO PUBLIC WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON phone_list TO PUBLIC WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON project TO PUBLIC WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON employee_project TO PUBLIC WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON proj_dept_budget TO PUBLIC WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON salary_history TO PUBLIC WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON customer TO PUBLIC WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON sales TO PUBLIC WITH GRANT OPTION;
GRANT EXECUTE ON PROCEDURE get_emp_proj TO PUBLIC WITH GRANT OPTION;
GRANT EXECUTE ON PROCEDURE add_emp_proj TO PUBLIC WITH GRANT OPTION;
GRANT EXECUTE ON PROCEDURE sub_tot_budget TO PUBLIC WITH GRANT OPTION;
GRANT EXECUTE ON PROCEDURE delete_employee TO PUBLIC WITH GRANT OPTION;
GRANT EXECUTE ON PROCEDURE dept_budget TO PUBLIC WITH GRANT OPTION;
GRANT EXECUTE ON PROCEDURE org_chart TO PUBLIC WITH GRANT OPTION;
GRANT EXECUTE ON PROCEDURE mail_label TO PUBLIC WITH GRANT OPTION;
GRANT EXECUTE ON PROCEDURE ship_order TO PUBLIC WITH GRANT OPTION;
GRANT EXECUTE ON PROCEDURE show_langs TO PUBLIC WITH GRANT OPTION;
GRANT EXECUTE ON PROCEDURE all_langs TO PUBLIC WITH GRANT OPTION;


/*
 * The contents of this file are subject to the Interbase Public
 * License Version 1.0 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy
 * of the License at http://www.Inprise.com/IPL.html
 *
 * Software distributed under the License is distributed on an
 * "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express
 * or implied. See the License for the specific language governing
 * rights and limitations under the License.
 *
 * The Original Code was created by Inprise Corporation
 * and its predecessors. Portions created by Inprise Corporation are
 * Copyright (C) Inprise Corporation.
 *
 * All Rights Reserved.
 * Contributor(s): ______________________________________.
 */
alter index CUSTNAMEX  inactive;
alter index CUSTREGION  inactive;
alter index BUDGETX  inactive;
alter index NAMEX  inactive;
alter index MAXSALX  inactive;
alter index MINSALX  inactive;
alter index PRODTYPEX  inactive;
alter index CHANGEX  inactive;
alter index UPDATERX  inactive;
alter index NEEDX  inactive;
alter index QTYX  inactive;
alter index SALESTATX  inactive;
ALTER TRIGGER set_emp_no INACTIVE;
ALTER TRIGGER set_cust_no INACTIVE;
ALTER TRIGGER post_new_order INACTIVE;
/*
 * The contents of this file are subject to the Interbase Public
 * License Version 1.0 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy
 * of the License at http://www.Inprise.com/IPL.html
 *
 * Software distributed under the License is distributed on an
 * "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express
 * or implied. See the License for the specific language governing
 * rights and limitations under the License.
 *
 * The Original Code was created by Inprise Corporation
 * and its predecessors. Portions created by Inprise Corporation are
 * Copyright (C) Inprise Corporation.
 *
 * All Rights Reserved.
 * Contributor(s): ______________________________________.
 */
/****************************************************************************
 *
 *  Create data.
 * 
*****************************************************************************/

/*
 *  Add countries.
 */
INSERT INTO country (country, currency) VALUES ('USA',         'Dollar');
INSERT INTO country (country, currency) VALUES ('England',     'Pound'); 
INSERT INTO country (country, currency) VALUES ('Canada',      'CdnDlr');
INSERT INTO country (country, currency) VALUES ('Switzerland', 'SFranc');
INSERT INTO country (country, currency) VALUES ('Japan',       'Yen');
INSERT INTO country (country, currency) VALUES ('Italy',       'Euro');
INSERT INTO country (country, currency) VALUES ('France',      'Euro');
INSERT INTO country (country, currency) VALUES ('Germany',     'Euro');
INSERT INTO country (country, currency) VALUES ('Australia',   'ADollar');
INSERT INTO country (country, currency) VALUES ('Hong Kong',   'HKDollar');
INSERT INTO country (country, currency) VALUES ('Netherlands', 'Euro');
INSERT INTO country (country, currency) VALUES ('Belgium',     'Euro');
INSERT INTO country (country, currency) VALUES ('Austria',     'Euro');
INSERT INTO country (country, currency) VALUES ('Fiji',        'FDollar');
INSERT INTO country (country, currency) VALUES ('Russia',      'Ruble');
INSERT INTO country (country, currency) VALUES ('Romania',     'RLeu');

COMMIT;

/*
 *  Add departments.
 *  Don't assign managers yet.
 *
 *  Department structure (4-levels):
 *
 *      Corporate Headquarters
 *          Finance
 *          Sales and Marketing
 *              Marketing
 *              Pacific Rim Headquarters (Hawaii)
 *                  Field Office: Tokyo
 *                  Field Office: Singapore
 *              European Headquarters (London)
 *                  Field Office: France
 *                  Field Office: Italy
 *                  Field Office: Switzerland
 *              Field Office: Canada
 *              Field Office: East Coast
 *          Engineering
 *              Software Products Division (California)
 *                  Software Development
 *                  Quality Assurance
 *                  Customer Support
 *              Consumer Electronics Division (Vermont)
 *                  Research and Development
 *                  Customer Services
 *
 *  Departments have parent departments.
 *  Corporate Headquarters is the top department in the company.
 *  Singapore field office is new and has 0 employees.
 *
 */
INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('000', 'Corporate Headquarters', null, 1000000, 'Monterey','(408) 555-1234');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('100', 'Sales and Marketing',  '000', 2000000, 'San Francisco',
'(415) 555-1234');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('600', 'Engineering', '000', 1100000, 'Monterey', '(408) 555-1234');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('900', 'Finance',   '000', 400000, 'Monterey', '(408) 555-1234');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('180', 'Marketing', '100', 1500000, 'San Francisco', '(415) 555-1234');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('620', 'Software Products Div.', '600', 1200000, 'Monterey', '(408) 555-1234');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('621', 'Software Development', '620', 400000, 'Monterey', '(408) 555-1234');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('622', 'Quality Assurance',    '620', 300000, 'Monterey', '(408) 555-1234');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('623', 'Customer Support', '620', 650000, 'Monterey', '(408) 555-1234');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('670', 'Consumer Electronics Div.', '600', 1150000, 'Burlington, VT',
'(802) 555-1234');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('671', 'Research and Development', '670', 460000, 'Burlington, VT',
'(802) 555-1234');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('672', 'Customer Services', '670', 850000, 'Burlington, VT', '(802) 555-1234');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('130', 'Field Office: East Coast', '100', 500000, 'Boston', '(617) 555-1234');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('140', 'Field Office: Canada',     '100', 500000, 'Toronto', '(416) 677-1000');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('110', 'Pacific Rim Headquarters', '100', 600000, 'Kuaui', '(808) 555-1234');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('115', 'Field Office: Japan',      '110', 500000, 'Tokyo', '3 5350 0901');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('116', 'Field Office: Singapore',  '110', 300000, 'Singapore', '3 55 1234');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('120', 'European Headquarters',    '100', 700000, 'London', '71 235-4400');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('121', 'Field Office: Switzerland','120', 500000, 'Zurich', '1 211 7767');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('123', 'Field Office: France',     '120', 400000, 'Cannes', '58 68 11 12');

INSERT INTO department
(dept_no, department, head_dept, budget, location, phone_no) VALUES
('125', 'Field Office: Italy',      '120', 400000, 'Milan', '2 430 39 39');


COMMIT;

/*
 *  Add jobs.
 *  Job requirements (blob) and languages (array) are not added here.
 */

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('CEO',   1, 'USA', 'Chief Executive Officer',    130000, 250000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('CFO',   1, 'USA', 'Chief Financial Officer',    85000,  140000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('VP',    2, 'USA', 'Vice President',             80000,  130000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Dir',   2, 'USA', 'Director',                   75000,  120000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Mngr',  3, 'USA', 'Manager',                    60000,  100000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Mngr',  4, 'USA', 'Manager',                    30000,  60000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Admin', 4, 'USA', 'Administrative Assistant',   35000,  55000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Admin', 5, 'USA', 'Administrative Assistant',   20000,  40000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Admin', 5, 'England', 'Administrative Assistant', 13400, 26800) /* pounds */;

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('PRel',  4, 'USA', 'Public Relations Rep.',      25000,  65000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Mktg',  3, 'USA', 'Marketing Analyst',          40000,  80000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Mktg',  4, 'USA', 'Marketing Analyst',          20000,  50000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Accnt', 4, 'USA', 'Accountant',                 28000,  55000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Finan', 3, 'USA', 'Financial Analyst',          35000,  85000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Eng',   2, 'USA', 'Engineer',                   70000,  110000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Eng',   3, 'USA', 'Engineer',                   50000,  90000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Eng',   3, 'Japan', 'Engineer',                 5400000, 9720000) /* yen */;

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Eng',   4, 'USA', 'Engineer',                   30000,  65000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Eng',   4, 'England', 'Engineer',               20100,  43550) /* Pounds */;

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Eng',   5, 'USA', 'Engineer',                   25000,  35000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Doc',   3, 'USA', 'Technical Writer',           38000,  60000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Doc',   5, 'USA', 'Technical Writer',           22000,  40000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Sales', 3, 'USA', 'Sales Co-ordinator',         40000,  70000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('Sales', 3, 'England', 'Sales Co-ordinator',     26800,  46900) /* pounds */;

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('SRep',  4, 'USA', 'Sales Representative',       20000,  100000);

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('SRep',  4, 'England', 'Sales Representative',   13400,  67000) /* pounds */;

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('SRep',  4, 'Canada', 'Sales Representative', 26400,  132000) /* CndDollar */;

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('SRep',  4, 'Switzerland', 'Sales Representative', 28000, 149000) /* SFranc */;

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('SRep',  4, 'Japan', 'Sales Representative',   2160000, 10800000) /* yen */;

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('SRep',  4, 'Italy', 'Sales Representative',   20000, 100000) /* Euro */;

INSERT INTO job
(job_code, job_grade, job_country, job_title, min_salary, max_salary) VALUES
('SRep',  4, 'France', 'Sales Representative',  20000, 100000) /* Euro */;


COMMIT;

/*
 *  Add employees.
 *
 *  The salaries initialized here are not final.  Employee salaries are
 *  updated below -- see salary_history.
 */


INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(2, 'Robert', 'Nelson', '600', 'VP', 2, 'USA', '12/28/88', 98000, '250');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(4, 'Bruce', 'Young', '621', 'Eng', 2, 'USA', '12/28/88', 90000, '233');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(5, 'Kim', 'Lambert', '130', 'Eng', 2, 'USA', '02/06/89', 95000, '22');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(8, 'Leslie', 'Johnson', '180', 'Mktg',  3, 'USA', '04/05/89', 62000, '410');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(9, 'Phil', 'Forest',   '622', 'Mngr',  3, 'USA', '04/17/89', 72000, '229');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(11, 'K. J.', 'Weston', '130', 'SRep',  4, 'USA', '01/17/90', 70000, '34');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(12, 'Terri', 'Lee', '000', 'Admin', 4, 'USA', '05/01/90', 48000, '256');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(14, 'Stewart', 'Hall', '900', 'Finan', 3, 'USA', '06/04/90', 62000, '227');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(15, 'Katherine', 'Young', '623', 'Mngr',  3, 'USA', '06/14/90', 60000, '231');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(20, 'Chris', 'Papadopoulos', '671', 'Mngr', 3, 'USA', '01/01/90', 80000,
'887');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(24, 'Pete', 'Fisher', '671', 'Eng', 3, 'USA', '09/12/90', 73000, '888');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(28, 'Ann', 'Bennet', '120', 'Admin', 5, 'England', '02/01/91', 20000, '5');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(29, 'Roger', 'De Souza', '623', 'Eng', 3, 'USA', '02/18/91', 62000, '288');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(34, 'Janet', 'Baldwin', '110', 'Sales', 3, 'USA', '03/21/91', 55000, '2');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(36, 'Roger', 'Reeves', '120', 'Sales', 3, 'England', '04/25/91', 30000, '6');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(37, 'Willie', 'Stansbury','120', 'Eng', 4, 'England', '04/25/91', 35000, '7');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(44, 'Leslie', 'Phong', '623', 'Eng', 4, 'USA', '06/03/91', 50000, '216');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(45, 'Ashok', 'Ramanathan', '621', 'Eng', 3, 'USA', '08/01/91', 72000, '209');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(46, 'Walter', 'Steadman', '900', 'CFO', 1, 'USA', '08/09/91', 120000, '210');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(52, 'Carol', 'Nordstrom', '180', 'PRel',  4, 'USA', '10/02/91', 41000, '420');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(61, 'Luke', 'Leung', '110', 'SRep',  4, 'USA', '02/18/92', 60000, '3');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(65, 'Sue Anne','O''Brien', '670', 'Admin', 5, 'USA', '03/23/92', 30000, '877');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(71, 'Jennifer M.', 'Burbank', '622', 'Eng', 3, 'USA', '04/15/92', 51000,
'289');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(72, 'Claudia', 'Sutherland', '140', 'SRep', 4, 'Canada', '04/20/92', 88000,
null);

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(83, 'Dana', 'Bishop', '621', 'Eng',  3, 'USA', '06/01/92', 60000, '290');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(85, 'Mary S.', 'MacDonald', '100', 'VP', 2, 'USA', '06/01/92', 115000, '477');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(94, 'Randy', 'Williams', '672', 'Mngr', 4, 'USA', '08/08/92', 54000, '892');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(105, 'Oliver H.', 'Bender', '000', 'CEO', 1, 'USA', '10/08/92', 220000, '255');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(107, 'Kevin', 'Cook', '670', 'Dir', 2, 'USA', '02/01/93', 115000, '894');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(109, 'Kelly', 'Brown', '600', 'Admin', 5, 'USA', '02/04/93', 27000, '202');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(110, 'Yuki', 'Ichida', '115', 'Eng', 3, 'Japan', '02/04/93',
6000000, '22');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(113, 'Mary', 'Page', '671', 'Eng', 4, 'USA', '04/12/93', 48000, '845');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(114, 'Bill', 'Parker', '623', 'Eng', 5, 'USA', '06/01/93', 35000, '247');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(118, 'Takashi', 'Yamamoto', '115', 'SRep', 4, 'Japan', '07/01/93',
6800000, '23');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(121, 'Roberto', 'Ferrari', '125', 'SRep',  4, 'Italy', '07/12/93',
30000, '1');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(127, 'Michael', 'Yanowski', '100', 'SRep', 4, 'USA', '08/09/93', 40000, '492');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(134, 'Jacques', 'Glon', '123', 'SRep',  4, 'France', '08/23/93', 35000, null);

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(136, 'Scott', 'Johnson', '623', 'Doc', 3, 'USA', '09/13/93', 60000, '265');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(138, 'T.J.', 'Green', '621', 'Eng', 4, 'USA', '11/01/93', 36000, '218');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(141, 'Pierre', 'Osborne', '121', 'SRep', 4, 'Switzerland', '01/03/94',
110000, null);

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(144, 'John', 'Montgomery', '672', 'Eng',   5, 'USA', '03/30/94', 35000, '820');

INSERT INTO employee (emp_no, first_name, last_name, dept_no, job_code,
job_grade, job_country, hire_date, salary, phone_ext) VALUES
(145, 'Mark', 'Guckenheimer', '622', 'Eng', 5, 'USA', '05/02/94', 32000, '221');


COMMIT;

SET GENERATOR emp_no_gen to 145;


/*
 *  Set department managers.
 *  A department manager can be a director, a vice president, a CFO,
 *  a sales rep, etc.  Several departments have no managers (TBH).
 */
UPDATE department SET mngr_no = 105 WHERE dept_no = '000';
UPDATE department SET mngr_no = 85 WHERE dept_no = '100';
UPDATE department SET mngr_no = 2 WHERE dept_no = '600';
UPDATE department SET mngr_no = 46 WHERE dept_no = '900';
UPDATE department SET mngr_no = 9 WHERE dept_no = '622';
UPDATE department SET mngr_no = 15 WHERE dept_no = '623';
UPDATE department SET mngr_no = 107 WHERE dept_no = '670';
UPDATE department SET mngr_no = 20 WHERE dept_no = '671';
UPDATE department SET mngr_no = 94 WHERE dept_no = '672';
UPDATE department SET mngr_no = 11 WHERE dept_no = '130';
UPDATE department SET mngr_no = 72 WHERE dept_no = '140';
UPDATE department SET mngr_no = 118 WHERE dept_no = '115';
UPDATE department SET mngr_no = 36 WHERE dept_no = '120';
UPDATE department SET mngr_no = 141 WHERE dept_no = '121';
UPDATE department SET mngr_no = 134 WHERE dept_no = '123';
UPDATE department SET mngr_no = 121 WHERE dept_no = '125';
UPDATE department SET mngr_no = 34 WHERE dept_no = '110';


COMMIT;

/*
 *  Generate some salary history records.
 */

UPDATE employee SET salary = salary + salary * 0.10 
    WHERE hire_date <= '08/01/91' AND job_grade = 5;
UPDATE employee SET salary = salary + salary * 0.05 + 3000
    WHERE hire_date <= '08/01/91' AND job_grade in (1, 2);
UPDATE employee SET salary = salary + salary * 0.075
    WHERE hire_date <= '08/01/91' AND job_grade in (3, 4) AND emp_no > 9;
UPDATE salary_history
    SET change_date = '12/15/92', updater_id = 'admin2';

UPDATE employee SET salary = salary + salary * 0.0425
    WHERE hire_date < '02/01/93' AND job_grade >= 3;
UPDATE salary_history
    SET change_date = '09/08/93', updater_id = 'elaine'
    WHERE NOT updater_id IN ('admin2');

UPDATE employee SET salary = salary - salary * 0.0325
    WHERE salary > 110000 AND job_country = 'USA';
UPDATE salary_history
    SET change_date = '12/20/93', updater_id = 'tj'
    WHERE NOT updater_id IN ('admin2', 'elaine');

UPDATE employee SET salary = salary + salary * 0.10
    WHERE job_code = 'SRep' AND hire_date < '12/20/93';
UPDATE salary_history
    SET change_date = '12/20/93', updater_id = 'elaine'
    WHERE NOT updater_id IN ('admin2', 'elaine', 'tj');

COMMIT;


/*
 *  Add projects.
 *  Some projects have no team leader.
 */

INSERT INTO project (proj_id, proj_name, team_leader, product) VALUES
('VBASE', 'Video Database', 45, 'software');

        /* proj_desc blob:
                  Design a video data base management system for
                  controlling on-demand video distribution.
        */

INSERT INTO project (proj_id, proj_name, team_leader, product) VALUES
('DGPII', 'DigiPizza', 24, 'other');

        /* proj_desc blob:
                  Develop second generation digital pizza maker
                  with flash-bake heating element and
                  digital ingredient measuring system.
        */

INSERT INTO project (proj_id, proj_name, team_leader, product) VALUES
('GUIDE', 'AutoMap', 20, 'hardware');

        /* proj_desc blob:
                  Develop a prototype for the automobile version of
                  the hand-held map browsing device.
        */

INSERT INTO project (proj_id, proj_name, team_leader, product) VALUES
('MAPDB', 'MapBrowser port', 4, 'software');

        /* proj_desc blob:
                  Port the map browsing database software to run
                  on the automobile model.
        */

INSERT INTO project (proj_id, proj_name, team_leader, product) VALUES
('HWRII', 'Translator upgrade', null, 'software');

        /* proj_desc blob:
                  Integrate the hand-writing recognition module into the
                  universal language translator.
        */

INSERT INTO project (proj_id, proj_name, team_leader, product) VALUES
('MKTPR', 'Marketing project 3', 85, 'N/A');

        /* proj_desc blob:
                  Expand marketing and sales in the Pacific Rim.
                  Set up a field office in Australia and Singapore.
        */

COMMIT;

/*
 *  Assign employees to projects.
 *  One project has no employees assigned.
 */

INSERT INTO employee_project (proj_id, emp_no) VALUES ('DGPII', 144);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('DGPII', 113);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('DGPII', 24);

INSERT INTO employee_project (proj_id, emp_no) VALUES ('VBASE', 8);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('VBASE', 136);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('VBASE', 15);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('VBASE', 71);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('VBASE', 145);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('VBASE', 44);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('VBASE', 4);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('VBASE', 83);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('VBASE', 138);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('VBASE', 45);

INSERT INTO employee_project (proj_id, emp_no) VALUES ('GUIDE', 20);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('GUIDE', 24);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('GUIDE', 113);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('GUIDE', 8);

INSERT INTO employee_project (proj_id, emp_no) VALUES ('MAPDB', 4);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('MAPDB', 71);

INSERT INTO employee_project (proj_id, emp_no) VALUES ('MKTPR', 46);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('MKTPR', 105);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('MKTPR', 12);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('MKTPR', 85);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('MKTPR', 110);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('MKTPR', 34);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('MKTPR', 8);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('MKTPR', 14);
INSERT INTO employee_project (proj_id, emp_no) VALUES ('MKTPR', 52);

COMMIT;

/*
 *  Add project budget planning by department.
 *  Head count array is not added here.
 */

INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'GUIDE', '100', 200000);
        /* head count:  1,1,1,0 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'GUIDE', '671', 450000);
        /* head count:  3,2,1,0 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1993, 'MAPDB', '621', 20000);
        /* head count:  0,0,0,1 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'MAPDB', '621', 40000);
        /* head count:  2,1,0,0 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'MAPDB', '622', 60000);
        /* head count:  1,1,0,0 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'MAPDB', '671', 11000);
        /* head count:  1,1,0,0 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'HWRII', '670', 20000);
        /* head count:  1,1,1,1 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'HWRII', '621', 400000);
        /* head count:  2,3,2,1 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'HWRII', '622', 100000);
        /* head count:  1,1,2,2 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'MKTPR', '623', 80000);
        /* head count:  1,1,1,2 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'MKTPR', '672', 100000);
        /* head count:  1,1,1,2 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'MKTPR', '100', 1000000);
        /* head count:  4,5,6,6 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'MKTPR', '110', 200000);
        /* head count:  2,2,0,3 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'MKTPR', '000', 100000);
        /* head count:  1,1,2,2 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1995, 'MKTPR', '623', 1200000);
        /* head count:  7,7,4,4 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1995, 'MKTPR', '672', 800000);
        /* head count:  2,3,3,3 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1995, 'MKTPR', '100', 2000000);
        /* head count:  4,5,6,6 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1995, 'MKTPR', '110', 1200000);
        /* head count:  1,1,1,1 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'VBASE', '621', 1900000);
        /* head count:  4,5,5,3 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1995, 'VBASE', '621', 900000);
        /* head count:  4,3,2,2 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'VBASE', '622', 400000);
        /* head count:  2,2,2,1 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1994, 'VBASE', '100', 300000);
        /* head count:  1,1,2,3 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1995, 'VBASE', '100', 1500000);
        /* head count:  3,3,1,1 */
INSERT INTO proj_dept_budget (fiscal_year, proj_id, dept_no, projected_budget) VALUES
(1996, 'VBASE', '100', 150000);
        /* head count:  1,1,0,0 */


COMMIT;
/*
 *  Add a few customer records.
 */


INSERT INTO customer
(cust_no, customer, contact_first, contact_last, phone_no, address_line1,
address_line2, city, state_province, country, postal_code, on_hold) VALUES
(1001, 'Signature Design', 'Dale J.', 'Little', '(619) 530-2710',
'15500 Pacific Heights Blvd.', null, 'San Diego', 'CA', 'USA', '92121', null);

INSERT INTO customer
(cust_no, customer, contact_first, contact_last, phone_no, address_line1,
address_line2, city, state_province, country, postal_code, on_hold) VALUES
(1002, 'Dallas Technologies', 'Glen', 'Brown', '(214) 960-2233',
'P. O. Box 47000', null, 'Dallas', 'TX', 'USA', '75205', null);

INSERT INTO customer
(cust_no, customer, contact_first, contact_last, phone_no, address_line1,
address_line2, city, state_province, country, postal_code, on_hold) VALUES
(1003, 'Buttle, Griffith and Co.', 'James', 'Buttle', '(617) 488-1864',
'2300 Newbury Street', 'Suite 101', 'Boston', 'MA', 'USA', '02115', null);

INSERT INTO customer
(cust_no, customer, contact_first, contact_last, phone_no, address_line1,
address_line2, city, state_province, country, postal_code, on_hold) VALUES
(1004, 'Central Bank', 'Elizabeth', 'Brocket', '61 211 99 88',
'66 Lloyd Street', null, 'Manchester', null, 'England', 'M2 3LA', null);

INSERT INTO customer
(cust_no, customer, contact_first, contact_last, phone_no, address_line1,
address_line2, city, state_province, country, postal_code, on_hold) VALUES
(1005, 'DT Systems, LTD.', 'Tai', 'Wu', '(852) 850 43 98',
'400 Connaught Road', null, 'Central Hong Kong', null, 'Hong Kong', null, null);

INSERT INTO customer
(cust_no, customer, contact_first, contact_last, phone_no, address_line1,
address_line2, city, state_province, country, postal_code, on_hold) VALUES
(1006, 'DataServe International', 'Tomas', 'Bright', '(613) 229 3323',
'2000 Carling Avenue', 'Suite 150', 'Ottawa', 'ON', 'Canada', 'K1V 9G1', null);

INSERT INTO customer
(cust_no, customer, contact_first, contact_last, phone_no, address_line1,
address_line2, city, state_province, country, postal_code, on_hold) VALUES
(1007, 'Mrs. Beauvais', null, 'Mrs. Beauvais', null,
'P.O. Box 22743', null, 'Pebble Beach', 'CA', 'USA', '93953', null);

INSERT INTO customer
(cust_no, customer, contact_first, contact_last, phone_no, address_line1,
address_line2, city, state_province, country, postal_code, on_hold) VALUES
(1008, 'Anini Vacation Rentals', 'Leilani', 'Briggs', '(808) 835-7605',
'3320 Lawai Road', null, 'Lihue', 'HI', 'USA', '96766', null);

INSERT INTO customer
(cust_no, customer, contact_first, contact_last, phone_no, address_line1,
address_line2, city, state_province, country, postal_code, on_hold) VALUES
(1009, 'Max', 'Max', null, '22 01 23',
'1 Emerald Cove', null, 'Turtle Island', null, 'Fiji', null, null);

INSERT INTO customer
(cust_no, customer, contact_first, contact_last, phone_no, address_line1,
address_line2, city, state_province, country, postal_code, on_hold) VALUES
(1010, 'MPM Corporation', 'Miwako', 'Miyamoto', '3 880 77 19',
'2-64-7 Sasazuka', null, 'Tokyo', null, 'Japan', '150', null);

INSERT INTO customer
(cust_no, customer, contact_first, contact_last, phone_no, address_line1,
address_line2, city, state_province, country, postal_code, on_hold) VALUES
(1011, 'Dynamic Intelligence Corp', 'Victor', 'Granges', '01 221 16 50',
'Florhofgasse 10', null, 'Zurich', null, 'Switzerland', '8005', null);

INSERT INTO customer
(cust_no, customer, contact_first, contact_last, phone_no, address_line1,
address_line2, city, state_province, country, postal_code, on_hold) VALUES
(1012, '3D-Pad Corp.', 'Michelle', 'Roche', '1 43 60 61',
'22 Place de la Concorde', null, 'Paris', null, 'France', '75008', null);

INSERT INTO customer
(cust_no, customer, contact_first, contact_last, phone_no, address_line1,
address_line2, city, state_province, country, postal_code, on_hold) VALUES
(1013, 'Lorenzi Export, Ltd.', 'Andreas', 'Lorenzi', '02 404 6284',
'Via Eugenia, 15', null, 'Milan', null, 'Italy', '20124', null);

INSERT INTO customer
(cust_no, customer, contact_first, contact_last, phone_no, address_line1,
address_line2, city, state_province, country, postal_code, on_hold) VALUES
(1014, 'Dyno Consulting', 'Greta', 'Hessels', '02 500 5940',
'Rue Royale 350', null, 'Brussels', null, 'Belgium', '1210', null);

INSERT INTO customer
(cust_no, customer, contact_first, contact_last, phone_no, address_line1,
address_line2, city, state_province, country, postal_code, on_hold) VALUES
(1015, 'GeoTech Inc.', 'K.M.', 'Neppelenbroek', '(070) 44 91 18',
'P.0.Box 702', null, 'Den Haag', null, 'Netherlands', '2514', null);

COMMIT;

SET GENERATOR cust_no_gen to 1015;



/*
 *  Add some sales records.
 */

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V91E0210', 1004, 11,  '03/04/91', '03/05/91', null,
'shipped',      'y',    10,     5000,   0.1,    'hardware');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V92E0340', 1004, 11, '10/15/92', '10/16/92', '10/17/92',
'shipped',      'y',    7,      70000,  0,      'hardware');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V92J1003', 1010, 61,  '07/26/92', '08/04/92', '09/15/92',
'shipped',      'y',    15,     2985,   0,      'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V93J2004', 1010, 118, '10/30/93', '12/02/93', '11/15/93',
'shipped',      'y',    3,      210,    0,      'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V93J3100', 1010, 118, '08/20/93', '08/20/93', null,
'shipped',      'y',    16,     18000.40,       0.10, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V92F3004', 1012, 11, '10/15/92', '01/16/93', '01/16/93',
'shipped',      'y',    3,      2000,           0, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V93F3088', 1012, 134, '08/27/93', '09/08/93', null,
'shipped',      'n',    10,     10000,          0, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V93F2030', 1012, 134, '12/12/93', null,    null,
'open',         'y',    15,     450000.49,      0, 'hardware');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V93F2051', 1012, 134, '12/18/93', null, '03/01/94',
'waiting',      'n',    1,      999.98,         0, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V93H0030', 1005, 118, '12/12/93', null, '01/01/94',
'open',         'y',    20,     5980,           0.20, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V94H0079', 1005, 61, '02/13/94', null, '04/20/94',
'open',         'n',    10,     9000,           0.05, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V9324200', 1001, 72, '08/09/93', '08/09/93', '08/17/93',
'shipped',      'y',    1000,   560000, 0.20, 'hardware');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V9324320', 1001, 127, '08/16/93', '08/16/93', '09/01/93',
'shipped',      'y',    1,              0,      1, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V9320630', 1001, 127, '12/12/93', null, '12/15/93',
'open',         'n',    3,      60000,  0.20, 'hardware');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V9420099', 1001, 127, '01/17/94', null, '06/01/94',
'open',         'n',    100, 3399.15,   0.15, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V9427029', 1001, 127, '02/07/94', '02/10/94', '02/10/94',
'shipped',      'n',    17,     422210.97,      0, 'hardware');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V9333005', 1002, 11, '02/03/93', '03/03/93', null,
'shipped',      'y',    2,      600.50,         0, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V9333006', 1002, 11, '04/27/93', '05/02/93', '05/02/93',
'shipped',      'n',    5,      20000,          0, 'other');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V9336100', 1002, 11, '12/27/93', '01/01/94', '01/01/94',
'waiting',      'n',    150,    14850,  0.05, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V9346200', 1003, 11, '12/31/93', null, '01/24/94',
'waiting',      'n',    3,      0,      1,    'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V9345200', 1003, 11, '11/11/93', '12/02/93', '12/01/93',
'shipped',      'y',    900,    27000,  0.30, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V9345139', 1003, 127, '09/09/93', '09/20/93', '10/01/93',
'shipped',      'y',    20,     12582.12,       0.10, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V93C0120', 1006, 72, '03/22/93', '05/31/93', '04/17/93',
'shipped',      'y',    1,      47.50,  0, 'other');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V93C0990', 1006, 72, '08/09/93', '09/02/93', null,
'shipped',      'y',    40,     399960.50,      0.10, 'hardware');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V9456220', 1007, 127, '01/04/94', null, '01/30/94',
'open',         'y',    1,      3999.99,        0, 'hardware');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V93S4702', 1011, 121, '10/27/93', '10/28/93', '12/15/93',
'shipped',      'y',    4,      120000,         0, 'hardware');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V94S6400', 1011, 141, '01/06/94', null, '02/15/94',
'waiting',      'y',    20,     1980.72,        0.40, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V93H3009', 1008, 61, '08/01/93', '12/02/93', '12/01/93',
'shipped',      'n',    3,      9000,           0.05, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V93H0500', 1008, 61, '12/12/93', null, '12/15/93',
'open',         'n',    3,      16000,          0.20, 'hardware');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V93F0020', 1009, 61,  '10/10/93', '11/11/93', '11/11/93',
'shipped',      'n',    1,      490.69,         0, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V93I4700', 1013, 121, '10/27/93', null, '12/15/93',
'open',         'n',    5,      2693,           0, 'hardware');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V93B1002', 1014, 134, '09/20/93', '09/21/93', '09/25/93',
'shipped',      'y',    1,      100.02,         0, 'software');

INSERT INTO sales
(po_number, cust_no, sales_rep, order_date, ship_date, date_needed,
order_status, paid, qty_ordered, total_value, discount, item_type) VALUES
('V93N5822', 1015, 134, '12/18/93', '01/14/94', null,
'shipped',      'n',    2,      1500.00,        0, 'software');


COMMIT;
/*
 *  Put some customers on-hold.
 */

UPDATE customer SET on_hold = '*' WHERE cust_no = 1002;
UPDATE customer SET on_hold = '*' WHERE cust_no = 1009;

COMMIT;
/*
 * The contents of this file are subject to the Interbase Public
 * License Version 1.0 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy
 * of the License at http://www.Inprise.com/IPL.html
 *
 * Software distributed under the License is distributed on an
 * "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express
 * or implied. See the License for the specific language governing
 * rights and limitations under the License.
 *
 * The Original Code was created by Inprise Corporation
 * and its predecessors. Portions created by Inprise Corporation are
 * Copyright (C) Inprise Corporation.
 *
 * All Rights Reserved.
 * Contributor(s): ______________________________________.
 */
alter index CUSTNAMEX  active;
alter index CUSTREGION  active;
alter index BUDGETX  active;
alter index NAMEX  active;
alter index MAXSALX  active;
alter index MINSALX  active;
alter index PRODTYPEX  active;
alter index CHANGEX  active;
alter index UPDATERX  active;
alter index NEEDX  active;
alter index QTYX  active;
alter index SALESTATX  active;
ALTER TRIGGER set_emp_no ACTIVE;
ALTER TRIGGER set_cust_no ACTIVE;
ALTER TRIGGER post_new_order ACTIVE;
UPDATE job
SET job_requirement = 'No specific requirements.'
WHERE job_code = 'CEO'
  AND job_grade = '1'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = '15+ years in finance or 5+ years as a CFO
with a proven track record.
MBA or J.D. degree.'
WHERE job_code = 'CFO'
  AND job_grade = '1'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = '5-10 years of accounting and financial experience.
Strong analytical skills.
CPA/MBA required.'
WHERE job_code = 'Finan'
  AND job_grade = '3'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = 'CPA with 3-5 years experience.
Spreadsheet, data entry, and word processing knowledge required.'
WHERE job_code = 'Accnt'
  AND job_grade = '4'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = 'CPA with 3-5 years experience.
Spreadsheet, data entry, and word processing knowledge required.'
WHERE job_code = 'Accnt'
  AND job_grade = '4'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = '5-10 years as a director in computer or electronics industries.
An advanced degree.'
WHERE job_code = 'Dir'
  AND job_grade = '2'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = 'No specific requirements.'
WHERE job_code = 'VP'
  AND job_grade = '2'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = '3-5 years experience in executive environment.
Strong organizational and communication skills required.
BA degree preferred.'
WHERE job_code = 'Admin'
  AND job_grade = '4'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = '2-4 years clerical experience.
Facility with word processing and data entry.
AA degree preferred.'
WHERE job_code = 'Admin'
  AND job_grade = '5'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = 'MBA required.
10+ years experience in high tech environment.'
WHERE job_code = 'Mktg'
  AND job_grade = '3'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = 'BA/BS required.  MBA preferred.
3-5 years experience.
Knowledgeable with spreadsheets and databases.'
WHERE job_code = 'Mktg'
  AND job_grade = '4'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = 'Distinguished engineer.
Ph.D/MS/BS or equivalent experience.'
WHERE job_code = 'Eng'
  AND job_grade = '2'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = '5+ years experience.
BA/BS required.
MS degree preferred.'
WHERE job_code = 'Eng'
  AND job_grade = '3'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = '5+ years experience.
BA/BS and/or MS degrees required.
Customer support experience desired.
Knowledge of Japanese and English.'
WHERE job_code = 'Eng'
  AND job_grade = '3'
  AND job_country = 'Japan';

UPDATE job
SET job_requirement = 'BA/BS and 3-5 years experience.'
WHERE job_code = 'Eng'
  AND job_grade = '4'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = 'BA/BS and
2-4 years experience in technical support.
Knowledge of several European languages helpful.'
WHERE job_code = 'Eng'
  AND job_grade = '4'
  AND job_country = 'England';

UPDATE job
SET job_requirement = 'BA/BS preferred.
2-4 years technical experience.'
WHERE job_code = 'Eng'
  AND job_grade = '5'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = '4+ years writing highly technical
software documentation.
A bachelor''s degree or equivalent.
Programming experience required.
Excellent language skills.'
WHERE job_code = 'Doc'
  AND job_grade = '3'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = 'BA in English/journalism or excellent language skills.
Some programming experience required.
2-4 years of technical writing.'
WHERE job_code = 'Doc'
  AND job_grade = '5'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = 'BA/BS required.
3-5 years in management,
plus 2-4 years engineering experience.'
WHERE job_code = 'Mngr'
  AND job_grade = '3'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = '5+ years office management experience.'
WHERE job_code = 'Mngr'
  AND job_grade = '4'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = 'Experience in sales and public relations
in a high tech environment.
Excellent communication skills.
BA or equivalent.'
WHERE job_code = 'Sales'
  AND job_grade = '3'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = 'Experience in sales and public relations
in a high tech environment.
Excellent communication skills.
BA or equivalent.
Knowledge of several European languages helpful.'
WHERE job_code = 'Sales'
  AND job_grade = '3'
  AND job_country = 'England';

UPDATE job
SET job_requirement = 'Computer/electronics industry sales experience.
Excellent communications, negotiation, and analytical skills.
Experience in establishing long term customer relationships.
Some knowledge of Spanish required.
Travel required.'
WHERE job_code = 'SRep'
  AND job_grade = '4'
  AND job_country = 'USA';

UPDATE job
SET job_requirement = 'Computer/electronics industry sales experience.
Excellent communications, negotiation, and analytical skills.
Experience in establishing long term customer relationships.
Knowledge of several European languages helpful.
Travel required.'
WHERE job_code = 'SRep'
  AND job_grade = '4'
  AND job_country = 'England';

UPDATE job
SET job_requirement = 'Computer/electronics industry sales experience.
Excellent communications, negotiation, and analytical skills.
Experience in establishing long term customer relationships.
Travel required.
English plus speaking knowledge of French required.'
WHERE job_code = 'SRep'
  AND job_grade = '4'
  AND job_country = 'Canada';

UPDATE job
SET job_requirement = 'Computer/electronics industry sales experience.
Excellent communications, negotiation, and analytical skills.
Experience in establishing long term customer relationships.
Knowledge of German required; one or more other European language helpful.
Travel required.'
WHERE job_code = 'SRep'
  AND job_grade = '4'
  AND job_country = 'Switzerland';

UPDATE job
SET job_requirement = 'Computer/electronics industry sales experience.
Excellent communications, negotiation, and analytical skills.
Experience in establishing long term customer relationships.
Knowledge of Japanese required.
Travel required.'
WHERE job_code = 'SRep'
  AND job_grade = '4'
  AND job_country = 'Japan';

UPDATE job
SET job_requirement = 'Computer/electronics industry sales experience.
Excellent communications, negotiation, and analytical skills.
Experience in establishing long term customer relationships.
Fluency in Italian; some knowledge of German helpful.
Travel required.'
WHERE job_code = 'SRep'
  AND job_grade = '4'
  AND job_country = 'Italy';

UPDATE job
SET job_requirement = 'Computer/electronics industry sales experience.
Excellent communications, negotiation, and analytical skills.
Experience in establishing long term customer relationships.
Fluency in French; some knowledge of German/Spanish helpful.
Travel required.'
WHERE job_code = 'SRep'
  AND job_grade = '4'
  AND job_country = 'France';

UPDATE project
SET proj_desc = 'Design a video data base management system for
controlling on-demand video distribution.'
WHERE proj_id = 'VBASE';

UPDATE project
SET proj_desc = 'Develop second generation digital pizza maker
with flash-bake heating element and
digital ingredient measuring system.'
WHERE proj_id = 'DGPII';

UPDATE project
SET proj_desc = 'Develop a prototype for the automobile version of
the hand-held map browsing device.'
WHERE proj_id = 'GUIDE';

UPDATE project
SET proj_desc = 'Port the map browsing database software to run
on the automobile model.'
WHERE proj_id = 'MAPDB';

UPDATE project
SET proj_desc = 'Integrate the hand-writing recognition module into the
universal language translator.'
WHERE proj_id = 'HWRII';

UPDATE project
SET proj_desc = 'Expand marketing and sales in the Pacific Rim.
Set up a field office in Australia and Singapore.'
WHERE proj_id = 'MKTPR';

