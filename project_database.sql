drop database if exists my_project;
create database my_project;
use my_project;
drop table if exists customer;
drop table if exists medication;
drop table if exists pharmacy;
drop table if exists employee;
drop table if exists inventory;
drop table if exists prescription;
drop table if exists prescription_fill;
drop table if exists inventory_order;

-- Customer table creation --
create table customer (
	ssn varchar(11) not null,
    f_name varchar(100) not null,
    l_name varchar(100) not null,
    phone varchar(20) not null,
    email varchar(255),
    address varchar(255),
    dob date not null,
    primary key (ssn)
    );
    
-- Medication table creation --
create table medication (
	med_id int not null,
    med_name varchar(100) not null,
    dosage_form varchar(50) not null,
    dosage_strength varchar(50) not null,
    manufacturer varchar(100) not null,
    unit_price numeric(10,2) not null,
    primary key (med_id)
    );

-- Pharmacy table creation --
create table pharmacy (
	pharmacy_id int not null,
    pharmacy_address varchar(255) not null,
    contact_number varchar(20) not null,
    primary key (pharmacy_id)
    );

-- employee table creation
create table employee (
	employee_id int not null,
    f_name varchar(50) not null,
    l_name varchar(50) not null,
    position varchar(50) not null,
    pharmacy_id int not null,
    contact_number varchar(20),
    e_mail varchar(100),
    primary key (employee_id),
    foreign key (pharmacy_id) references pharmacy(pharmacy_id)
    );

-- inventory table creation
create table inventory (
	pharmacy_id int not null,
    med_id int not null,
    quantity_on_hand int constraint check (quantity_on_hand>=0),
    reorder_level int,
    primary key (pharmacy_id, med_id),
    foreign key (pharmacy_id) references pharmacy(pharmacy_id),
    foreign key (med_id) references medication(med_id)
    );

-- prescription table creation --
create table prescription (
	prescription_id int not null,
    customer_ssn varchar(11) not null,
    med_id int not null,
    prescriber varchar(100) not null,
    issued_date date not null,
    expiration_date date not null,
    num_refills int constraint check(num_refills>=0) not null,
    quantity_per_fill int not null,
    directions varchar(255) not null,
    primary key (prescription_id),
    foreign key (customer_ssn) references customer(ssn),
    foreign key (med_id) references medication(med_id)
    );
    
-- prescription_fill table creation   
create table prescription_fill (
	fill_id int not null,
    prescription_id int not null,
    fill_date date,
    employee_id int not null,
    pharmacy_id int not null,
    quantity_filled int constraint check(quantity_filled>=0) not null,
    pickup_date date default null,
    primary key (fill_id),
    foreign key (prescription_id) references prescription(prescription_id),
    foreign key (employee_id) references employee(employee_id),
    foreign key (pharmacy_id) references pharmacy(pharmacy_id)
    );

-- inventory_order table creation
create table inventory_order (
	order_id int not null,
    med_id int not null,
    pharmacy_id int not null,
    order_date date not null,
    quantity_ordered int constraint check(quantity_ordered>0) not null,
    date_received date,
    primary key (order_id),
    foreign key (med_id) references medication(med_id),
    foreign key (pharmacy_id) references pharmacy(pharmacy_id)
    );
-- table triggers
delimiter //
create trigger inventory_update
after update on inventory_order
for each row
	-- make sure received_date is being switched from NULL to a valid date before updating the inventory
    if old.date_received is null and new.date_received is not null then
		update inventory
        set quantity_on_hand = quantity_on_hand + new.quantity_ordered
        where pharmacy_id = new.pharmacy_id and med_id = new.med_id;
	end if;
// delimiter ;

-- Views
create view inventory_status as
select p.pharmacy_id, p.pharmacy_address, m.med_id, m.med_name, i.quantity_on_hand, i.reorder_level
from inventory i
join medication m on i.med_id = m.med_id
join pharmacy p on i.pharmacy_id = p.pharmacy_id;

create view prescription_fill_counts as
select prescription_id, count(*) as fills_count
from prescription_fill
group by prescription_id;

create view active_prescriptions as
select p.customer_ssn, p.prescription_id, p.med_id
from prescription p
left join prescription_fill_counts pf on p.prescription_id = pf.prescription_id
where p.expiration_date >= curdate()
and ((p.num_refills+1) > ifnull(pf.fills_count, 0));
select * from active_prescriptions;

create view customer_due_for_refills as
select distinct c.ssn, c.f_name, c.l_name, m.med_id, m.med_name
from prescription p1
join customer c on p1.customer_ssn = c.ssn
join medication m on p1.med_id = m.med_id
left join active_prescriptions ap on p1.customer_ssn = ap.customer_ssn
where ap.customer_ssn is null;
select * from customer_due_for_refills;

-- Procedures
delimiter //
create procedure customer_history(in customer_ssn varchar(11))
begin
	select c.f_name, c.l_name, p.prescription_id, m.med_name, pf.fill_date, pf.quantity_filled, pf.pickup_date
    from customer c
    join prescription p on c.ssn = p.customer_ssn
    join prescription_fill pf on p.prescription_id = pf.prescription_id
    join medication m on p.med_id = m.med_id
    where c.ssn = customer_ssn and pf.pickup_date is not null
    order by pf.fill_date desc;
end //
delimiter ;

-- Populating Tables -----------------------------------------------------------------------------------------------------------------------------
-- Populate Customer table
insert into customer (ssn, f_name, l_name, phone, email, address, dob)
values
('123-45-6789', 'John', 'Doe', '952-321-1111', 'jdoe@example.com', '100 Elm St, nowhereville, somewhere, usa', '1980-01-01'),
('987-65-4321', 'Jane', 'Smith', '952-551-2222', 'jsmith@example.com', '200 Oak St, nowhereville, somewhere, usa', '1975-05-15'),
('555-55-5555', 'Bob', 'Johnson', '952-222-3333', 'bjohnson@example.com', '300 Pine St, nowhereville, somewhere, usa', '1990-07-20'),
('111-22-3333', 'Alice', 'Williams', '952-454-4444', 'awilliams@example.com', '400 Maple St, Nowhereville, Somewhere, USA', '1985-02-12'),
('222-33-4444', 'Charlie', 'Brown', '952-697-5555', 'cbrown@example.com', '500 Birch St, Nowhereville, Somewhere, USA', '1978-11-30'),
('333-44-5555', 'Diana', 'Evans', '952-789-6666', 'devans@example.com', '600 Cedar St, Nowhereville, Somewhere, USA', '1992-03-08'),
('444-55-6666', 'Edward', 'Taylor', '952-123-7777', 'etaylor@example.com', '700 Ash St, Nowhereville, Somewhere, USA', '1983-06-25'),
('555-66-7777', 'Fiona', 'Anderson', '952-456-8888', 'fanderson@example.com', '800 Poplar St, Nowhereville, Somewhere, USA', '1989-09-14');
-- Populate medication table --
insert into medication (med_id, med_name, dosage_form, dosage_strength, manufacturer, unit_price)
values
(101, 'Amoxicillin', 'Capsule', '500mg', 'PharmaCorp', 0.50),
(102, 'Levothyroxine', 'Tablet', '75mcg', 'Pfizer', 0.08),
(103, 'Lisinopril', 'Tablet', '10mg', 'CorePharma', 0.08),
(104, 'Amlodipine', 'Tablet', '10mg', 'PharmaCorp', 0.13),
(105, 'Prednisone', 'Tablet', '20mg', 'PharmaCorp', 0.29);
-- Populate Pharmacy table --
insert into pharmacy (pharmacy_id, pharmacy_address, contact_number)
values
(1, '123 main str, nowhereville, somewhere, usa', '952-555-1234'),
(2, '456 east ave, nowhereville, somewhere, usa', '952-555-5678'),
(3, '789 west blvd, nowherville, somewhere, usa', '952-555-9012'),
(4, '101 north rd, nowhereville, somewhere, usa', '952-555-3456'),
(5, '202 south st, nowhereville, somewhere, usa', '952-555-7890');
-- Populate employee table --
INSERT INTO employee (employee_id, f_name, l_name, position, pharmacy_id, contact_number, e_mail)
VALUES
(1, 'Alice', 'Brown', 'Pharmacist', 1, '952-555-4444', 'abrown@centralpharmacy.com'),
(2, 'Eve', 'Davis', 'Pharmacy Technician', 1, '952-555-5555', 'edavis@centralpharmacy.com'),
(3, 'Charlie', 'Wilson', 'Pharmacist', 2, '952-555-6666', 'cwilson@eastpharmacy.com'),
(4, 'David', 'Taylor', 'Pharmacy Technician', 2, '952-555-7777', 'dtaylor@eastpharmacy.com'),
(5, 'Fiona', 'Johnson', 'Pharmacist', 3, '952-555-8888', 'fjohnson@westpharmacy.com'),
(6, 'George', 'Smith', 'Pharmacy Technician', 3, '952-555-9999', 'gsmith@westpharmacy.com'),
(7, 'Hannah', 'Clark', 'Pharmacist', 4, '952-555-1212', 'hclark@northpharmacy.com'),
(8, 'Ian', 'Roberts', 'Pharmacy Technician', 4, '952-555-2323', 'iroberts@northpharmacy.com'),
(9, 'Jenna', 'Lewis', 'Pharmacist', 5, '952-555-3434', 'jlewis@southpharmacy.com'),
(10, 'Kevin', 'Adams', 'Pharmacy Technician', 5, '952-555-4545', 'kadams@southpharmacy.com');
-- Populate inventory table
INSERT INTO inventory (pharmacy_id, med_id, quantity_on_hand, reorder_level)
VALUES
(1, 101, 50, 20),
(1, 102, 30, 15),
(1, 103, 40, 10),
(2, 101, 20, 20),
(2, 102, 10, 15),
(3, 103, 5, 10);

-- Populate Prescription table
INSERT INTO prescription (prescription_id, customer_ssn, med_id, prescriber, issued_date, expiration_date, num_refills, quantity_per_fill, directions)
VALUES
(1001, '123-45-6789', 101, 'Dr. House', '2024-10-11', '2025-10-11', 3, 90, 'Take one capsule every 8 hours'),
(1002, '987-65-4321', 102, 'Dr. Adams', '2023-11-30', '2024-11-30', 2, 30, 'Take one tablet daily'),
(1003, '555-55-5555', 103, 'Dr. Baker', '2024-10-09', '2025-10-09', 1, 60, 'Take one tablet twice daily'),
(1004, '111-22-3333', 104, 'Dr. Carter', '2024-07-10', '2025-07-10', 4, 60, 'Take one tablet every 12 hours'),
(1005, '222-33-4444', 105, 'Dr. Evans', '2024-06-01', '2025-06-01', 0, 30, 'Take one tablet in the morning'),
(1006, '111-22-3333', 101, 'Dr. Carter', '2024-01-01', '2025-01-01', 0, 60, 'Take one capsule twice daily');

-- Populate Prescription_Fill table
INSERT INTO prescription_fill (fill_id, prescription_id, fill_date, employee_id, pharmacy_id, quantity_filled, pickup_date)
VALUES
(1, 1001, '2024-11-12', 1, 1, 30, null),
(2, 1002, '2024-11-14', 3, 2, 30, '2024-11-14'),
(3, 1003, '2024-10-10', 4, 3, 60, '2024-10-11'),
(4, 1004, '2024-07-12', 5, 3, 30, '2024-07-13'),
(5, 1005, '2024-07-14', 6, 2, 30, '2024-07-20'),
(7, 1001, '2024-10-11', 1, 1, 30, '2024-10-11'),
(8, 1006, '2024-01-01', 5, 3, 60, '2024-01-01');

-- Populate inventory_order table
INSERT INTO inventory_order (order_id, med_id, pharmacy_id, order_date, quantity_ordered, date_received)
VALUES
(5001, 102, 1, '2024-11-01', 500, '2024-11-08'),
(5002, 103, 3, '2024-11-10', 500, null),
(5003, 101, 4, '2024-11-10', 500, null),
(5004, 101, 2, '2024-11-13', 1000, null),
(5005, 105, 4, '2024-11-13', 1000, null);

-- example queries --
-- 1. List all customers who have prescriptions that are going to expire within 30 days.
select c.ssn, c.f_name, c.l_name, c.phone, c.email, p.prescription_id, m.med_name, p.expiration_date
from customer c
join prescription p on c.ssn = p.customer_ssn
join medication m on p.med_id = m.med_id
where p.expiration_date between curdate() and date_add(curdate(), interval 30 day); -- determine the current date and what the date is 30 days out

-- 2. Identify the medications that are most frequently prescribed.
select m.med_id, m.med_name, count(p.prescription_id) as times_prescribed
from prescription p
join medication m on p.med_id = m.med_id
group by m.med_id, m.med_name
order by times_prescribed desc;

-- 3. List medications in each pharmacy where the quantity on hand is less than or equal to the reorder level
select *
from inventory_status
where quantity_on_hand <= reorder_level;

-- 4. List customers that have prescriptions ready for pickup
select c.f_name, c.l_name, m.med_name, pf.fill_date, pf.quantity_filled
from customer c
join prescription p on c.ssn = p.customer_ssn
join prescription_fill pf on p.prescription_id = pf.prescription_id
join medication m on p.med_id = m.med_id
where pf.pickup_date is null;

-- 5. List the history of all picked up prescriptions for a customer
call customer_history('111-22-3333');

-- 6. List the medications on order for each pharmacy and the quantities ordered
select p.pharmacy_id, p.pharmacy_address, o.med_id, m.med_name, o.quantity_ordered, o.order_date
from pharmacy p
join inventory_order o on p.pharmacy_id = o.pharmacy_id
join medication m on m.med_id = o.med_id
where o.date_received is null
order by p.pharmacy_id asc;

-- 7. List all customers that have active prescriptions
select c.ssn, c.f_name, c.l_name, c.phone, c.email, a.prescription_id, a.med_id 
from customer c
join active_prescriptions a on a.customer_ssn = c.ssn;

-- 8. Check the inventory of all pharmacies for a specific medication
select distinct p.pharmacy_id, p.pharmacy_address, i.quantity_on_hand
from inventory i
join pharmacy p on i.pharmacy_id = p.pharmacy_id
join medication m on i.med_id = m.med_id
where m.med_name = 'Amoxicillin'
and i.quantity_on_hand > 0;

-- 9. Determine the cost of an inventory order
select o.order_id, o.pharmacy_id, p.pharmacy_address, o.med_id, m.med_name,
	o.quantity_ordered, m.unit_price, (o.quantity_ordered * m.unit_price) as total_cost,
	o.order_date, o.date_received
from inventory_order o
join medication m on o.med_id = m.med_id
join pharmacy p on o.pharmacy_id = p.pharmacy_id
order by p.pharmacy_id;

-- 10. Display a list of all pharmacists employed
select * from employee
where position = "pharmacist";