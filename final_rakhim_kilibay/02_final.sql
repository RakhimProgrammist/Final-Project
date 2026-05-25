CREATE SCHEMA IF NOT EXISTS rest_ops;

DROP VIEW IF EXISTS rest_ops.analytics_recent_quarter CASCADE;
DROP TABLE IF EXISTS rest_ops.menu_ingredients CASCADE;
DROP TABLE IF EXISTS rest_ops.ingredients CASCADE;
DROP TABLE IF EXISTS rest_ops.suppliers CASCADE;
DROP TABLE IF EXISTS rest_ops.order_items CASCADE;
DROP TABLE IF EXISTS rest_ops.orders CASCADE;
DROP TABLE IF EXISTS rest_ops.reservations CASCADE;
DROP TABLE IF EXISTS rest_ops.customers CASCADE;
DROP TABLE IF EXISTS rest_ops.tables CASCADE;
DROP TABLE IF EXISTS rest_ops.staff CASCADE;
DROP TABLE IF EXISTS rest_ops.shifts CASCADE;
DROP TABLE IF EXISTS rest_ops.menu_items CASCADE;
DROP TABLE IF EXISTS rest_ops.categories CASCADE;





CREATE TABLE rest_ops.categories (
    category_id   SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL CONSTRAINT uq_category_name UNIQUE
);


CREATE TABLE rest_ops.menu_items (
    item_id       SERIAL PRIMARY KEY,
    category_id   INT NOT NULL REFERENCES rest_ops.categories(category_id) ON DELETE RESTRICT,
    item_name     VARCHAR(100) NOT NULL CONSTRAINT uq_item_name UNIQUE,
    price         NUMERIC(10,2) NOT NULL,
    is_available  BOOLEAN NOT NULL DEFAULT TRUE
);


CREATE TABLE rest_ops.shifts (
    shift_id      SERIAL PRIMARY KEY,
    shift_name    VARCHAR(20) NOT NULL CONSTRAINT uq_shift_name UNIQUE,
    start_time    TIME NOT NULL,
    end_time      TIME NOT NULL
);


CREATE TABLE rest_ops.staff (
    staff_id      SERIAL PRIMARY KEY,
    shift_id      INT NOT NULL REFERENCES rest_ops.shifts(shift_id) ON DELETE RESTRICT,
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    full_name     VARCHAR(105) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    role_title    VARCHAR(30) NOT NULL,
    phone_number  VARCHAR(15) NOT NULL UNIQUE
);


CREATE TABLE rest_ops.tables (
    table_id      SERIAL PRIMARY KEY,
    table_number  VARCHAR(10) NOT NULL CONSTRAINT uq_table_num UNIQUE,
    capacity      INT NOT NULL
);


CREATE TABLE rest_ops.customers (
    customer_id   SERIAL PRIMARY KEY,
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    phone_number  VARCHAR(15) NOT NULL UNIQUE,
    bonus_points  INT NOT NULL DEFAULT 0
);


CREATE TABLE rest_ops.reservations (
    reservation_id   SERIAL PRIMARY KEY,
    table_id         INT NOT NULL REFERENCES rest_ops.tables(table_id) ON DELETE CASCADE,
    customer_id      INT NOT NULL REFERENCES rest_ops.customers(customer_id) ON DELETE CASCADE,
    reservation_time TIMESTAMP NOT NULL,
    status           VARCHAR(20) NOT NULL DEFAULT 'Confirmed'
);

-- 8. Заказы (Чеки)
CREATE TABLE rest_ops.orders (
    order_id      SERIAL PRIMARY KEY,
    table_id      INT NOT NULL REFERENCES rest_ops.tables(table_id) ON DELETE RESTRICT,
    staff_id      INT NOT NULL REFERENCES rest_ops.staff(staff_id) ON DELETE RESTRICT,
    order_date    TIMESTAMP NOT NULL,
    total_amount  NUMERIC(10,2) NOT NULL DEFAULT 0.00
);


CREATE TABLE rest_ops.order_items (
    order_id      INT NOT NULL REFERENCES rest_ops.orders(order_id) ON DELETE CASCADE,
    item_id       INT NOT NULL REFERENCES rest_ops.menu_items(item_id) ON DELETE RESTRICT,
    quantity      INT NOT NULL,
    subtotal      NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, item_id)
);


CREATE TABLE rest_ops.suppliers (
    supplier_id   SERIAL PRIMARY KEY,
    company_name  VARCHAR(100) NOT NULL CONSTRAINT uq_supplier_company UNIQUE,
    contact_name  VARCHAR(100) NOT NULL,
    phone_number  VARCHAR(15) NOT NULL UNIQUE
);


CREATE TABLE rest_ops.ingredients (
    ingredient_id  SERIAL PRIMARY KEY,
    supplier_id    INT NOT NULL REFERENCES rest_ops.suppliers(supplier_id) ON DELETE RESTRICT,
    ingredient_name VARCHAR(100) NOT NULL CONSTRAINT uq_ing_name UNIQUE,
    stock_quantity NUMERIC(10,2) NOT NULL,
    unit_of_measure VARCHAR(10) NOT NULL
);


CREATE TABLE rest_ops.menu_ingredients (
    item_id       INT NOT NULL REFERENCES rest_ops.menu_items(item_id) ON DELETE CASCADE,
    ingredient_id INT NOT NULL REFERENCES rest_ops.ingredients(ingredient_id) ON DELETE CASCADE,
    weight_grams  NUMERIC(8,2) NOT NULL,
    PRIMARY KEY (item_id, ingredient_id)
);





ALTER TABLE rest_ops.menu_items ADD CONSTRAINT chk_positive_price CHECK (price > 0.00);
ALTER TABLE rest_ops.tables ADD CONSTRAINT chk_table_capacity CHECK (capacity BETWEEN 1 AND 20);
ALTER TABLE rest_ops.order_items ADD CONSTRAINT chk_positive_quantity CHECK (quantity > 0);
ALTER TABLE rest_ops.orders ALTER COLUMN order_date SET DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE rest_ops.ingredients ADD CONSTRAINT chk_non_negative_stock CHECK (stock_quantity >= 0.00);





TRUNCATE TABLE 
    rest_ops.menu_ingredients, rest_ops.ingredients, rest_ops.suppliers,
    rest_ops.order_items, rest_ops.orders, rest_ops.reservations, rest_ops.customers,
    rest_ops.tables, rest_ops.staff, rest_ops.shifts, rest_ops.menu_items, rest_ops.categories 
RESTART IDENTITY CASCADE;


INSERT INTO rest_ops.categories (category_name) VALUES 
    ('Закуски'), ('Горячее'), ('Десерты'), ('Напитки'), ('Гарниры'), ('Фирменное');

INSERT INTO rest_ops.menu_items (category_id, item_name, price) VALUES
    ((SELECT category_id FROM rest_ops.categories WHERE category_name='Закуски'), 'Чесночные гренки', 1200.00),
    ((SELECT category_id FROM rest_ops.categories WHERE category_name='Горячее'), 'Стейк Рибай', 12500.00),
    ((SELECT category_id FROM rest_ops.categories WHERE category_name='Горячее'), 'Филе Лосося', 8900.00),
    ((SELECT category_id FROM rest_ops.categories WHERE category_name='Десерты'), 'Шоколадный фондан', 2100.00),
    ((SELECT category_id FROM rest_ops.categories WHERE category_name='Напитки'), 'Домашний лимонад', 1500.00),
    ((SELECT category_id FROM rest_ops.categories WHERE category_name='Гарниры'), 'Картофель фри с трюфелем', 1800.00);

INSERT INTO rest_ops.shifts (shift_name, start_time, end_time) VALUES
    ('Утренняя', '08:00:00', '14:00:00'), ('Дневная', '10:00:00', '18:00:00'),
    ('Вечерняя', '16:00:00', '00:00:00'), ('Ночная', '00:00:00', '08:00:00'),
    ('Субботняя', '12:00:00', '23:00:00'), ('Воскресная', '12:00:00', '22:00:00');

INSERT INTO rest_ops.staff (shift_id, first_name, last_name, role_title, phone_number) VALUES
    ((SELECT shift_id FROM rest_ops.shifts WHERE shift_name='Дневная'), 'Алиса', 'Смирнова', 'Старший официант', '+77011112233'),
    ((SELECT shift_id FROM rest_ops.shifts WHERE shift_name='Вечерняя'), 'Игорь', 'Иванов', 'Официант', '+77022223344'),
    ((SELECT shift_id FROM rest_ops.shifts WHERE shift_name='Вечерняя'), 'Тимур', 'Кузнецов', 'Официант', '+77033334455'),
    ((SELECT shift_id FROM rest_ops.shifts WHERE shift_name='Утренняя'), 'Диана', 'Маратова', 'Хостес', '+77044445566'),
    ((SELECT shift_id FROM rest_ops.shifts WHERE shift_name='Ночная'), 'Алексей', 'Петров', 'Ночной менеджер', '+77055556677'),
    ((SELECT shift_id FROM rest_ops.shifts WHERE shift_name='Субботняя'), 'Айдар', 'Галиев', 'Бармен', '+77066667788');

INSERT INTO rest_ops.tables (table_number, capacity) VALUES 
    ('Т1', 2), ('Т2', 4), ('Т3', 4), ('Т4', 6), ('VIP-01', 8), ('Bar-01', 1);

INSERT INTO rest_ops.customers (first_name, last_name, phone_number, bonus_points) VALUES
    ('Арман', 'Сабитов', '+77771112233', 150), ('Елена', 'Ким', '+77772223344', 500),
    ('Марат', 'Оспанов', '+77773334455', 0), ('Анна', 'Сергеева', '+77774445566', 1200),
    ('Берик', 'Ахметов', '+77775556677', 50), ('Зарина', 'Алиева', '+77776667788', 340);

INSERT INTO rest_ops.suppliers (company_name, contact_name, phone_number) VALUES
    ('Мясной Бор бор-1', 'Олег Крупнов', '+77071112233'), ('Рыбный Рай', 'Вадим Морской', '+77072223344'),
    ('Ферма Овощей', 'Алия Нурланова', '+77073334455'), ('Сладкий Мир', 'Ирина Тортикова', '+77074445566'),
    ('Эко Бакалея', 'Канат Исаев', '+77075556677'), ('Премиум Напитки', 'Дмитрий Винный', '+77076667788');


INSERT INTO rest_ops.ingredients (supplier_id, ingredient_name, stock_quantity, unit_of_measure) VALUES
    ((SELECT supplier_id FROM rest_ops.suppliers WHERE company_name='Мясной Бор бор-1'), 'Говядина Вырезка Рибай', 45.50, 'кг'),
    ((SELECT supplier_id FROM rest_ops.suppliers WHERE company_name='Рыбный Рай'), 'Охлажденный Лосось', 20.00, 'кг'),
    ((SELECT supplier_id FROM rest_ops.suppliers WHERE company_name='Ферма Овощей'), 'Картофель молодой', 150.00, 'кг'),
    ((SELECT supplier_id FROM rest_ops.suppliers WHERE company_name='Ферма Овощей'), 'Чеснок', 10.00, 'кг'),
    ((SELECT supplier_id FROM rest_ops.suppliers WHERE company_name='Сладкий Мир'), 'Бельгийский шоколад', 15.00, 'кг'),
    ((SELECT supplier_id FROM rest_ops.suppliers WHERE company_name='Эко Бакалея'), 'Трюфельное масло', 5.00, 'л');


INSERT INTO rest_ops.menu_ingredients (item_id, ingredient_id, weight_grams) VALUES
    ((SELECT item_id FROM rest_ops.menu_items WHERE item_name='Стейк Рибай'), (SELECT ingredient_id FROM rest_ops.ingredients WHERE ingredient_name='Говядина Вырезка Рибай'), 350.00),
    ((SELECT item_id FROM rest_ops.menu_items WHERE item_name='Филе Лосося'), (SELECT ingredient_id FROM rest_ops.ingredients WHERE ingredient_name='Охлажденный Лосось'), 250.00),
    ((SELECT item_id FROM rest_ops.menu_items WHERE item_name='Картофель фри с трюфелем'), (SELECT ingredient_id FROM rest_ops.ingredients WHERE ingredient_name='Картофель молодой'), 200.00),
    ((SELECT item_id FROM rest_ops.menu_items WHERE item_name='Картофель фри с трюфелем'), (SELECT ingredient_id FROM rest_ops.ingredients WHERE ingredient_name='Трюфельное масло'), 15.00),
    ((SELECT item_id FROM rest_ops.menu_items WHERE item_name='Чесночные гренки'), (SELECT ingredient_id FROM rest_ops.ingredients WHERE ingredient_name='Чеснок'), 20.00),
    ((SELECT item_id FROM rest_ops.menu_items WHERE item_name='Шоколадный фондан'), (SELECT ingredient_id FROM rest_ops.ingredients WHERE ingredient_name='Бельгийский шоколад'), 90.00);


INSERT INTO rest_ops.reservations (table_id, customer_id, reservation_time) VALUES
    ((SELECT table_id FROM rest_ops.tables WHERE table_number='Т1'), (SELECT customer_id FROM rest_ops.customers WHERE last_name='Сабитов'), '2026-05-24 12:00:00'),
    ((SELECT table_id FROM rest_ops.tables WHERE table_number='VIP-01'), (SELECT customer_id FROM rest_ops.customers WHERE last_name='Ким'), '2026-05-24 20:00:00');

INSERT INTO rest_ops.orders (table_id, staff_id, order_date, total_amount) VALUES
    ((SELECT table_id FROM rest_ops.tables WHERE table_number='Т1'), (SELECT staff_id FROM rest_ops.staff WHERE last_name='Смирнова'), '2026-05-24 12:30:00', 13700.00),
    ((SELECT table_id FROM rest_ops.tables WHERE table_number='Т2'), (SELECT staff_id FROM rest_ops.staff WHERE last_name='Иванов'), '2026-05-24 18:45:00', 25000.00),
    ((SELECT table_id FROM rest_ops.tables WHERE table_number='Т3'), (SELECT staff_id FROM rest_ops.staff WHERE last_name='Кузнецов'), '2026-05-24 19:00:00', 10700.00),
    ((SELECT table_id FROM rest_ops.tables WHERE table_number='VIP-01'), (SELECT staff_id FROM rest_ops.staff WHERE last_name='Иванов'), '2026-05-24 20:15:00', 37500.00);

INSERT INTO rest_ops.order_items (order_id, item_id, quantity, subtotal) VALUES
    (1, (SELECT item_id FROM rest_ops.menu_items WHERE item_name='Чесночные гренки'), 1, 1200.00),
    (1, (SELECT item_id FROM rest_ops.menu_items WHERE item_name='Стейк Рибай'), 1, 12500.00),
    (2, (SELECT item_id FROM rest_ops.menu_items WHERE item_name='Стейк Рибай'), 2, 25000.00),
    (3, (SELECT item_id FROM rest_ops.menu_items WHERE item_name='Филе Лосося'), 1, 8900.00),
    (3, (SELECT item_id FROM rest_ops.menu_items WHERE item_name='Картофель фри с трюфелем'), 1, 1800.00),
    (4, (SELECT item_id FROM rest_ops.menu_items WHERE item_name='Стейк Рибай'), 3, 37500.00);





UPDATE rest_ops.menu_items SET price = price + 500.00 WHERE item_name LIKE '%Стейк%';

UPDATE rest_ops.orders o
SET total_amount = total_amount * 1.15
FROM rest_ops.order_items oi
JOIN rest_ops.menu_ingredients mi ON oi.item_id = mi.item_id
JOIN rest_ops.ingredients ing ON mi.ingredient_id = ing.ingredient_id
JOIN rest_ops.suppliers sup ON ing.supplier_id = sup.supplier_id
WHERE o.order_id = oi.order_id AND sup.company_name = 'Мясной Бор бор-1';

BEGIN;
    DELETE FROM rest_ops.orders WHERE total_amount <= 0.00 
    RETURNING order_id, total_amount;
COMMIT;





CREATE OR REPLACE VIEW rest_ops.analytics_recent_quarter AS
SELECT 
    o.order_id AS "Чек №",
    s.full_name AS "Официант",
    mi.item_name AS "Проданное Блюдо",
    ing.ingredient_name AS "Израсходованное Сырье",
    (oi.quantity * m_ing.weight_grams) AS "Списано со Склада (г)",
    sup.company_name AS "Поставщик Ингредиента"
FROM rest_ops.orders o
JOIN rest_ops.staff s ON o.staff_id = s.staff_id
JOIN rest_ops.order_items oi ON o.order_id = oi.order_id
JOIN rest_ops.menu_items mi ON oi.item_id = mi.item_id
JOIN rest_ops.menu_ingredients m_ing ON mi.item_id = m_ing.item_id
JOIN rest_ops.ingredients ing ON m_ing.ingredient_id = ing.ingredient_id
JOIN rest_ops.suppliers sup ON ing.supplier_id = sup.supplier_id;




DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'manager_read_only') THEN
        REASSIGN OWNED BY manager_read_only TO CURRENT_USER;
        DROP OWNED BY manager_read_only;
        DROP ROLE manager_read_only;
    END IF;
END $$;

CREATE ROLE manager_read_only WITH LOGIN PASSWORD 'SecureRestPass2026!';
GRANT USAGE ON SCHEMA rest_ops TO manager_read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA rest_ops TO manager_read_only;