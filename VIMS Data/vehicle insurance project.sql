CREATE DATABASE Vims;
USE Vims;

CREATE TABLE insurance_plans(
plan_id VARCHAR(5) PRIMARY KEY,
plan_name VARCHAR(50) NOT NULL,
coverage_type VARCHAR(20) NOT NULL,
base_rate_pct DECIMAL(4,2) NOT NULL,
deductible INT DEFAULT 0
);

CREATE TABLE agents(
agent_id VARCHAR(5) PRIMARY KEY,
agent_name VARCHAR(50) NOT NULL,
phone VARCHAR(15),
city VARCHAR(30),
hire_date DATE,
commission_pct DECIMAL(4,1) NOT NULL 
);

CREATE TABLE customers(
customer_id VARCHAR(5) PRIMARY KEY,
first_name VARCHAR(30) NOT NULL,
last_name VARCHAR(30) NOT NULL,
gender VARCHAR(10),
date_of_birth DATE,
phone VARCHAR(15),
email VARCHAR(60) NULL,
city VARCHAR(30),
state VARCHAR(30),
registration_date DATE
);

CREATE TABLE vehicles(
vehicle_id VARCHAR(5) PRIMARY KEY,
customer_id VARCHAR(5) ,
vehicle_type VARCHAR(20) NOT NULL,
make VARCHAR(30) NOT NULL,
model VARCHAR(30) NOT NULL,
manufacture_year INT NOT NULL,
registration_no VARCHAR(15) UNIQUE,
fuel_type VARCHAR(15),
vehicle_value DECIMAL(12,2) NOT NULL,
FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
);

CREATE TABLE policies(
policy_id VARCHAR(8) PRIMARY KEY,
vehicle_id VARCHAR(5) ,
plan_id VARCHAR(5),
agent_id VARCHAR(5),
start_date DATE NOT NULL,
end_date DATE NOT NULL,
idv_amount DECIMAL(12,2) NOT NULL,
premium_amount DECIMAL(12,2) NOT NULL,
policy_status VARCHAR(15) NOT NULL,
FOREIGN KEY (vehicle_id) REFERENCES vehicles (vehicle_id),
FOREIGN KEY (plan_id) REFERENCES insurance_plans (plan_id),
FOREIGN KEY (agent_id) REFERENCES agents (agent_id)
);

CREATE TABLE payments(
payment_id VARCHAR(8) PRIMARY KEY,
policy_id VARCHAR(8),
payment_date DATE NOT NULL,
amount_paid DECIMAL(12,2) NOT NULL,
payment_mode VARCHAR(15) NOT NULL ,
payment_status VARCHAR(10) NOT NULL,
FOREIGN KEY (policy_id) REFERENCES policies (policy_id)
);

CREATE TABLE claims(
claim_id VARCHAR(8) PRIMARY KEY,
policy_id VARCHAR(8),
claim_date DATE NOT NULL,
incident_type VARCHAR(25) NOT NULL,
claim_amount DECIMAL(12,2) NOT NULL,
approved_amount DECIMAL(12,2) DEFAULT 0,
claim_status VARCHAR(15) NOT NULL,
settlement_date DATE NULL,
FOREIGN KEY (policy_id) REFERENCES policies (policy_id)
);
 
 
-- Q1
SELECT CONCAT(first_name, " ",last_name) AS Full_Name, city, email
FROM customers
WHERE city IN ('Pune', 'Mumbai')
AND email LIKE '%@gmail.com';

-- Q2
SELECT registration_no , make, model, vehicle_value
FROM vehicles
ORDER BY vehicle_value DESC
LIMIT 5;

-- Q3
SELECT vehicle_type,
COUNT(vehicle_id) AS total_vehicles ,
ROUND(AVG(vehicle_value),2) AS Avg_Value
FROM vehicles
GROUP BY vehicle_type;

-- Q4
SELECT policy_id, vehicle_id, plan_id,premium_amount, policy_status
FROM policies
WHERE premium_amount BETWEEN 30000 and 60000 
ORDER BY premium_amount DESC;

-- Q5
SELECT customer_id, CONCAT(first_name, " ",last_name) AS customer_name, city
FROM customers
WHERE  email IS NULL
OR TRIM(email) = '';

-- Q6
SELECT vehicle_id , make, model, manufacture_year, fuel_type
FROM vehicles
WHERE make IN ("Maruti Suzuki", "Hyundai", "Tata")
AND fuel_type = "Petrol" 
AND manufacture_year >= 2020;

-- Q7
SELECT policy_id, vehicle_id, end_date,
DATEDIFF(end_date, '2026-10-20') AS days_left
FROM policies
WHERE policy_status = 'Active'
AND end_date BETWEEN '2026-10-20'
AND DATE_ADD('2026-10-20', INTERVAL 90 DAY)
ORDER BY end_date;

-- Q8
SELECT CONCAT(first_name, " ",last_name) AS customer_name , v.registration_no, v.make, v.model
FROM vehicles v
JOIN customers c 
ON v.customer_id = c.customer_id
LIMIT 15;

-- Q9
SELECT p.policy_id, 
CONCAT(c.first_name, " ",c.last_name) AS customer_name ,
v.registration_no, i.plan_name, 
a.agent_name, p.premium_amount
FROM vehicles v
JOIN customers c 
ON c.customer_id = v.customer_id
JOIN policies p
ON p.vehicle_id = v.vehicle_id
JOIN insurance_plans i
ON p.plan_id = i.plan_id
JOIN agents a
ON p.agent_id = a.agent_id
WHERE p.policy_status = 'Active'
ORDER BY p.premium_amount DESC
LIMIT 10;

-- Q10
SELECT payment_mode, 
COUNT(payment_id) AS No_of_payments,
SUM(amount_paid) AS Total_amount_collected
FROM payments 
WHERE payment_status = 'Success'
GROUP BY payment_mode;

-- Q11
SELECT incident_type, 
COUNT(claim_id) AS total_claims, 
SUM(claim_amount) AS  total_claimed, 
SUM(approved_amount) AS total_approved
FROM claims
GROUP BY incident_type
HAVING COUNT(claim_id) >= 3;

-- Q12
SELECT c.customer_id, 
CONCAT(c.first_name, " ",c.last_name) AS customer_name ,
c.city
FROM customers c
LEFT JOIN vehicles v
ON c.customer_id = v.customer_id
WHERE registration_no IS NULL;

-- Q13
SELECT v.vehicle_id, v.registration_no, v.make, v.model,
CONCAT(c.first_name, " ",c.last_name) AS Owner_name
FROM vehicles v
LEFT JOIN customers c 
ON c.customer_id = v.customer_id
LEFT JOIN policies p
ON p.vehicle_id = v.vehicle_id
WHERE policy_id IS NULL;

-- Q14
SELECT a.agent_id, a.agent_name, a.city,
COUNT(p.policy_id) AS policies_sold,
COALESCE(SUM(p.premium_amount), 0) AS total_premium,
COALESCE(SUM(p.premium_amount * a.commission_pct / 100), 0) AS commission_earned
FROM agents a
LEFT JOIN policies p
ON a.agent_id = p.agent_id
GROUP BY a.agent_id, a.agent_name, a.city;

-- Q15
SELECT i.plan_name,
COUNT(c.claim_id) AS total_claims,
SUM(CASE WHEN c.claim_status IN ('Settled', 'Approved') THEN 1 ELSE 0 END) AS approved_claims,
SUM(CASE WHEN c.claim_status = 'Rejected' THEN 1 ELSE 0 END) AS rejected_claims,
ROUND(SUM(CASE WHEN c.claim_status IN ('Settled', 'Approved') THEN 1 ELSE 0 END) * 100.0
/ COUNT(c.claim_id), 2) AS approval_pct
FROM insurance_plans i
JOIN policies p ON i.plan_id = p.plan_id
JOIN claims c ON p.policy_id = c.policy_id
GROUP BY i.plan_id, i.plan_name;

-- Q16
SELECT c.customer_id,
CONCAT(c.first_name, " ",c.last_name) AS customer_name,
COUNT(v.vehicle_id) AS Vehicle_owned,
SUM(v.vehicle_value) AS Total_vehicle_value
FROM vehicles v
JOIN customers c 
ON c.customer_id = v.customer_id
GROUP BY c.customer_id
HAVING COUNT(v.vehicle_id) > 1
ORDER BY Vehicle_owned DESC
LIMIT 10;

-- Q17
SELECT p.policy_id, p.plan_id, p.premium_amount, 
	(
	SELECT AVG(p1.premium_amount) 
	FROM policies p1
	WHERE p1.plan_id = p.plan_id
	)AS plan_avg_premium
FROM policies p
WHERE p.premium_amount > (
    SELECT AVG(p1.premium_amount)
    FROM policies p1
    WHERE p1.plan_id = p.plan_id
)
ORDER BY p.plan_id, p.premium_amount DESC
LIMIT 12;

-- Q18
WITH agent_sales AS (
    SELECT a.city, a.agent_id, a.agent_name,
		COALESCE(SUM(
            CASE
                WHEN p.policy_status != 'Cancelled'
                THEN p.premium_amount
                ELSE 0
            END
        ), 0) AS total_premium
    FROM agents a
    LEFT JOIN policies p
        ON a.agent_id = p.agent_id
    GROUP BY a.city, a.agent_id, a.agent_name
)
SELECT city, agent_name, total_premium,
    RANK() OVER ( PARTITION BY city
        ORDER BY total_premium DESC
    ) AS city_rank
FROM agent_sales
ORDER BY city, city_rank;

-- Q19
SELECT
    DATE_FORMAT(start_date, '%Y-%m') AS policy_month,
    COUNT(policy_id) AS policies_issued,
    SUM(premium_amount) AS monthly_premium,
    SUM(SUM(premium_amount)) OVER (
        ORDER BY DATE_FORMAT(start_date, '%Y-%m')
    ) AS running_total
FROM policies
WHERE start_date >= '2025-01-01'
  AND start_date < '2026-01-01'
GROUP BY DATE_FORMAT(start_date, '%Y-%m')
ORDER BY policy_month;

-- Q20
WITH customer_premium AS (
    SELECT
        v.customer_id,
        SUM(p.premium_amount) AS total_premium
    FROM vehicles v
    JOIN policies p ON v.vehicle_id = p.vehicle_id
    GROUP BY v.customer_id
),
customer_claims AS (
    SELECT
        v.customer_id,
        SUM(c.approved_amount) AS total_approved
    FROM vehicles v
    JOIN policies p ON v.vehicle_id = p.vehicle_id
    JOIN claims c ON p.policy_id = c.policy_id
    GROUP BY v.customer_id
)
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    cp.total_premium,
    COALESCE(cc.total_approved, 0) AS total_approved,
    ROUND(
        COALESCE(cc.total_approved, 0) * 100.0 /
        NULLIF(cp.total_premium, 0), 2
    ) AS loss_ratio_pct,
    CASE
        WHEN COALESCE(cc.total_approved, 0) * 100.0 /
             NULLIF(cp.total_premium, 0) > 100
        THEN 'High Risk'
        ELSE 'Normal'
    END AS risk_flag
FROM customers c
JOIN customer_premium cp ON c.customer_id = cp.customer_id
LEFT JOIN customer_claims cc ON c.customer_id = cc.customer_id
ORDER BY loss_ratio_pct DESC
LIMIT 10;















