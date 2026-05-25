# Final Project: Restaurant Operations Database Management System (`rest_ops`)

**Student:** Kilibay Rakhim  
**Course:** Relational Databases & SQL  
**Grade Assignment:** Final Project Submission  

---

## 1. Domain Description

This database system, named `restaurant_db`, is designed to manage the day-to-day business and culinary operations of a high-end restaurant under the schema `rest_ops`. 
The core objective is to seamlessly track the entire cycle of restaurant hospitality and internal logistics:
* **Front-of-House:** Managing customer reservations, seating arrangements (tables), opening guest orders (bills), and detailing individual items sold within each order.
* **Back-of-House & Logistics:** Managing recipe compositions (precise weight of ingredients needed for menu dishes), tracking real-time stock quantities in the warehouse, organizing raw materials from corporate vendors, and managing staff work shifts.

---

## 2. Database & Schema Specifications

* **Database Name:** `restaurant_db`
* **Target Schema:** `rest_ops`
* **Database Platform:** PostgreSQL (v14+)
* **Script File:** `02_final.sql` (Fully re-runnable, idempotent script)

---

## 3. Design Decisions & Architecture

### 3.1 Third Normal Form (3NF) Compliance
The database consists of **12 interrelated tables** structured strictly according to 3NF parameters to eliminate data redundancy and prevent operational anomalies:
* **1NF:** Every column contains atomic values. Multi-value entries (e.g., list of ingredients or ordered items stored as text arrays/strings) are completely avoided.
* **2NF:** All tables possess defined Primary Keys. No partial dependencies exist — in bridge tables with composite primary keys (`order_items`, `menu_ingredients`), the non-key attributes (`quantity`, `weight_grams`) depend strictly on the whole primary key combination.
* **3NF:** No transitive dependencies are present. Attributes that do not belong to the primary key rely solely on the primary key. For instance, staff names do not contain repetitive shift detail fields; they reference `shift_id` directly, which isolates shift hours into a separate reference table (`shifts`).

### 3.2 Resolution of Many-to-Many (N:M) Relationships
Two complex enterprise-level many-to-many linkages were resolved using junction/bridge tables:
1. **`menu_items` ──(N:M)── `ingredients`:** Resolved via **`menu_ingredients`**. It details specific recipes, letting the kitchen track exactly how many grams of raw materials are deducted per dish.
2. **`orders` ──(N:M)── `menu_items`:** Resolved via **`order_items`**. It handles checkout detailing, mapping multiple dishes to individual bills while storing unique line sub-totals.

### 3.3 Integrity Constraints & System Evolution (ALTERs)
* **`GENERATED ALWAYS AS`:** Utilized in the `staff` table to compute the `full_name` column dynamically by combining first and last names, preventing string mismatch or data duplication.
* **Advanced CHECKs:** Applied across five strict business areas including price validation (`price > 0.00`), structural boundaries (`capacity BETWEEN 1 AND 20`), and chronological control, ensuring that reservations do not clip into past dates (`reservation_time > '2026-01-01'`).
* **Schema Evolution:** The script models realistic enterprise changes using 5 distinct `ALTER TABLE` commands (e.g., widening character inputs, dropping deprecated logistical markers, and setting safe operational column defaults dynamically).

### 3.4 Data Control Language (DCL) Post-Mortem
Two distinct application roles are isolated to respect the principle of least privilege:
* `manager_read_only`: Granted global `SELECT` authority for real-time sales audit and inventory view monitoring.
* `pos_cashier_writer`: Granted transactional insert/update commands for operational cash desks. 
* *Security Override:* Following a theoretical system post-mortem audit, a `REVOKE UPDATE` constraint was actively issued against cashiers on the main `orders` table. This protects financial logs from internal manipulation; modifications to finalized invoices must run explicitly through certified administrators.

---

## 4. Run & Execution Instructions

The script `02_final.sql` is built with safe conditional guards (`IF NOT EXISTS`, conditional wrapper blocks, and an upfront sequential cascade truncation routine) making it **100% re-runnable**. Running the script multiple times consecutively will consistently result in 0 execution errors.

### Option A: Execution via GUI (DBeaver / pgAdmin)
1. Open your database administration tool and connect to your PostgreSQL instance.
2. Create a clean database named `restaurant_db` or execute the script directly.
3. Open a new SQL Editor window and copy-paste the entire contents of `02_final.sql`.
4. Execute the entire script bottom-to-top (`Alt + X` or click "Execute SQL Script").
5. Refresh your database tree view to see the generated `rest_ops` tables, structural data views, and data controls.

### Option B: Execution via Command Line (`psql`)
Open your terminal environment and run the following execution string (adjust host/username parameters if needed):
```bash
psql -h localhost -U postgres -d restaurant_db -f 02_final.sql