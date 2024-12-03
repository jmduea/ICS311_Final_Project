import mysql.connector
from mysql.connector import Error
from datetime import date
import re

class Config:
    user=None

def connect():
    """Creates a connection to the database

    Returns:
        MySQLConnection: connection object used to connect to the database
    """
    try:
        connection = mysql.connector.connect(
            host="localhost",
            user="root",
            database="my_project",
            password="ics311",
            auth_plugin="mysql_native_password"
        )
        if connection.is_connected():
            return connection
    except Error as e:
        print("Error while connecting to MySQL:", e)
        return None
    
def display_report_header(report_number: int, report_title: str, customer_ssn: str=None, header_length: int=130):
    """Prints a formatted report header based on the provided arguments

    Args:
        report_number (int): Number representing which report this is
        report_title (str): Short title describing the report
        customer_ssn (str, default=None): Accepts a string to be used for displaying in the report header
        header_length (int, default=130): Accepts an int to be used for defining the number of "-" to display seperating the header from the report
    """
    customer_ssn=customer_ssn
    print(f"Name: {Config.user}\nReport {report_number}: {report_title}\nDate: {date.today()}")
    if customer_ssn is not None:
        print(f"Customer Prescription History for Customer SSN: {customer_ssn}")
    print("-"*header_length)

def report1(connection):
    """Displays a list of all employees and their information

    Args:
        connection (MySQLConnection): Connection object for accessing the database
    """
    cursor = connection.cursor()
    query = "SELECT employee_id, f_name, l_name, position FROM employee"
    try:
        cursor.execute(query)
        rows = cursor.fetchall()
        display_report_header(1, "Employee Information", header_length=80)
        print(f"{'ID':<10} {'First Name':<15} {'Last Name':<15} {'Position':<20}")
        print("-" *80)
        for row in rows:
            print(f"{row[0]:<10} {row[1]:<15} {row[2]:<15} {row[3]:<20}")
        print("-"*80)
    except Error as e:
        print(f"Error executing query: {e}")
    finally:
        cursor.close()
    
def report2(connection):
    """Displays a list of all customers with currently active prescriptions

    Args:
        connection (MySQLConnection): Connection object for accessing the database
    """
    cursor=connection.cursor()
    query = """
    SELECT c.ssn, c.f_name, c.l_name, c.phone, c.email, a.prescription_id, a.med_id
    FROM customer c
    JOIN active_prescriptions a ON a.customer_ssn = c.ssn
    """
    try:
        cursor.execute(query)
        rows = cursor.fetchall()
        display_report_header(2, "Customers with Active Prescriptions")
        print(f"{'SSN':<15} {'First Name':<15} {'Last Name':<10} \
            {'Phone':<15} {'Email':<25} {'Prescription ID':<20} {'Med ID':<10}")
        print("-"*130)
        for row in rows:
            print(f"{row[0]:<15} {row[1]:<15} {row[2]:<15} {row[3]:<15} {row[4]:<25} \
                  {row[5]:<15} {row[6]:<10}")
        print("-"*130)
    except Error as e:
        print(f"Error executing query: {e}")
    finally:
        cursor.close()
    
def report3(connection):
    """Gathers user input to display a specific customers prescription history

    Args:
        connection (MySQLConnection): Connection object for accessing the database
    """
    # For validating ssn input
    ssn_pattern = re.compile(r'^\d{3}-\d{2}-\d{4}$')
    # Loop for valid input
    while True:
        customer_ssn = input("Enter Customer SSN to retrieve prescription history for or enter 0 to abort (e.g., 123-45-6789): ").strip()
        if customer_ssn == "0":
            print("Report generation aborted.")
            return
        if ssn_pattern.match(customer_ssn):
            break
        else:
            print("Invalid SSN format. Please enter in the format XXX-XX-XXXX.")
    cursor = connection.cursor(prepared=True)
    query = """
    SELECT c.f_name, c.l_name, p.prescription_id, m.med_name, pf.fill_date, pf.quantity_filled, pf.pickup_date
    FROM customer c
    JOIN prescription p on c.ssn = p.customer_ssn
    JOIN prescription_fill pf ON p.prescription_id = pf.prescription_id
    JOIN medication m ON p.med_id = m.med_id
    WHERE c.ssn = %s AND pf.pickup_date IS NOT NULL
    ORDER BY pf.fill_date DESC;
    """
    try:
        cursor.execute(query, (customer_ssn,))
        rows = cursor.fetchall()
        if rows:
            display_report_header(3, "Customer Prescription History", customer_ssn=customer_ssn)
            print(f"{"First Name":<15} {"Last Name":<15} {"Prescription ID":<15} {"Medication Name":<25} {"Fill Date":<15} {"Quantity":<10} {"Pickup Date":<15}")
            print("-"*130)
            for row in rows:
                print(f"{row[0]:<15} {row[1]:<15} {row[2]:<15} {row[3]:<25} {row[4].strftime('%Y-%m-%d'):<15} {row[5]:<10} {row[6].strftime('%Y-%m-%d'):<15}")
            print("-"*130)
        else:
            print(f"No prescription history found for customer SSN: {customer_ssn}")
    except Error as e:
        print(f"Error executing query: {e}")
    finally:
        cursor.close()
    
def db_report_generator():
    print(f"\nWelcome to DBReportGenerator today's date is: {date.today()}")
    Config.user = str(input("Please enter your name: "))
    
    connection=connect()
    running=True
    first_loop=True
    while running:
        if first_loop:
            print(f"Hello, {Config.user}, please select what you would like to do. (Enter 1, 2, 3, or 4)")
            first_loop=False
        else:
            print("Please select what you would like to do. (Enter 1, 2, 3, or 4)")
        print("1. Report 1 (Employee Information)")
        print("2. Report 2 (Customers with Active Prescriptions)")
        print("3. Report 3 (Customer Prescription History)")
        print("4. Exit")
        selection = int(input())

        if selection == 1:
            report1(connection)
        elif selection == 2:
            report2(connection)
        elif selection == 3:
            report3(connection)
        elif selection == 4:
            print("Thank you for using DBReportGenerator, have a good day!")
            running=False
            break
        else:
            print("Invalid input please enter 1, 2, 3 or 4.")
    connection.close()


if __name__ == "__main__":
    db_report_generator()