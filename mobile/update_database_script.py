import os

path = r"C:\Users\user\Desktop\ANTIGRAVTY\app\database.py"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Update Customer model
old_model = """class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(String, index=True, nullable=False)
    name = Column(String, nullable=False)
    name_lower = Column(String, nullable=False, index=True)
    created_at = Column(DateTime, default=utc_now, nullable=False)"""

new_model = """class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(String, index=True, nullable=False)
    name = Column(String, nullable=False)
    name_lower = Column(String, nullable=False, index=True)
    party_type = Column(String, default="customer", server_default="customer", nullable=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)"""

assert old_model in content, "old_model not found"
content = content.replace(old_model, new_model)

# 2. Update migrate_legacy_data
old_migrate = """def migrate_legacy_data():
    \"\"\"Idempotent migration. Safe on every startup.\"\"\"
    with get_db() as db:
        _migrate_amount_column(db)
        _migrate_customers(db)"""

new_migrate = """def migrate_legacy_data():
    \"\"\"Idempotent migration. Safe on every startup.\"\"\"
    with get_db() as db:
        _migrate_amount_column(db)
        _migrate_party_type_column(db)
        _migrate_customers(db)


def _migrate_party_type_column(db):
    try:
        cols = [r[1] for r in db.execute(text("PRAGMA table_info(customers)")).fetchall()]
    except Exception:
        return
    if "party_type" not in cols:
        db.execute(text("ALTER TABLE customers ADD COLUMN party_type VARCHAR DEFAULT 'customer'"))
        db.commit()
        logger.info("Added party_type column to customers.")
    db.execute(
        text(
            "UPDATE customers SET party_type = 'customer' "
            "WHERE party_type IS NULL OR party_type = ''"
        )
    )
    db.commit()"""

assert old_migrate in content, "old_migrate not found"
content = content.replace(old_migrate, new_migrate)

# 3. Update get_or_create_customer
old_create = """def get_or_create_customer(owner_id: str, name: str) -> int:
    \"\"\"Return customer_id. Case-insensitive. Creates if missing.\"\"\"
    name = sanitize_input_text(name, max_len=100)
    if not name:
        raise ValueError("Customer name cannot be empty.")
    lower = name.lower()
    with get_db() as db:
        row = db.execute(
            text("SELECT id FROM customers WHERE owner_id=:o AND name_lower=:n"),
            {"o": owner_id, "n": lower},
        ).fetchone()
        if row:
            return row[0]
        try:
            db.execute(
                text(
                    "INSERT INTO customers (owner_id, name, name_lower, created_at) "
                    "VALUES (:o, :n, :nl, :t)"
                ),
                {"o": owner_id, "n": name, "nl": lower, "t": utc_now()},
            )
            db.commit()
        except IntegrityError:
            db.rollback()
        row = db.execute(
            text("SELECT id FROM customers WHERE owner_id=:o AND name_lower=:n"),
            {"o": owner_id, "n": lower},
        ).fetchone()
        return row[0]"""

new_create = """def get_or_create_customer(owner_id: str, name: str, party_type: str = "customer") -> int:
    \"\"\"Return customer_id. Case-insensitive. Creates if missing.\"\"\"
    name = sanitize_input_text(name, max_len=100)
    if not name:
        raise ValueError("Customer name cannot be empty.")
    party_type = (party_type or "customer").strip().lower()
    if party_type not in {"customer", "supplier", "other"}:
        party_type = "customer"
    lower = name.lower()
    with get_db() as db:
        row = db.execute(
            text("SELECT id FROM customers WHERE owner_id=:o AND name_lower=:n"),
            {"o": owner_id, "n": lower},
        ).fetchone()
        if row:
            return row[0]
        try:
            db.execute(
                text(
                    "INSERT INTO customers (owner_id, name, name_lower, party_type, created_at) "
                    "VALUES (:o, :n, :nl, :pt, :t)"
                ),
                {"o": owner_id, "n": name, "nl": lower, "pt": party_type, "t": utc_now()},
            )
            db.commit()
        except IntegrityError:
            db.rollback()
        row = db.execute(
            text("SELECT id FROM customers WHERE owner_id=:o AND name_lower=:n"),
            {"o": owner_id, "n": lower},
        ).fetchone()
        return row[0]"""

assert old_create in content, "old_create not found"
content = content.replace(old_create, new_create)

# 4. Update list_customers_with_balance
old_list = """def list_customers_with_balance(owner_id: str) -> list[dict]:
    \"\"\"Every customer with net balance (paise). Sorted by owed DESC.\"\"\"
    with get_db() as db:
        rows = db.execute(
            text(
                \"\"\"
            SELECT c.id, c.name,
              COALESCE(SUM(CASE WHEN t.transaction_type IN ('Debit','Sale')
                                THEN t.amount_paise ELSE 0 END), 0) AS owed,
              COALESCE(SUM(CASE WHEN t.transaction_type = 'Credit'
                                THEN t.amount_paise ELSE 0 END), 0) AS paid
            FROM customers c
            LEFT JOIN transactions t
              ON t.customer_id = c.id AND t.is_deleted = 0
            WHERE c.owner_id = :o
            GROUP BY c.id, c.name
            ORDER BY (owed - paid) DESC
        \"\"\"
            ),
            {"o": owner_id},
        ).fetchall()
    return [
        {"id": r[0], "name": r[1], "balance_paise": int((r[2] or 0) - (r[3] or 0))}
        for r in rows
    ]"""

new_list = """def list_customers_with_balance(owner_id: str, party_type: str | None = None) -> list[dict]:
    \"\"\"Every customer with net balance (paise). Sorted by owed DESC.\"\"\"
    query = \"\"\"
            SELECT c.id, c.name, COALESCE(c.party_type, 'customer') AS party_type,
              COALESCE(SUM(CASE WHEN t.transaction_type IN ('Debit','Sale')
                                THEN t.amount_paise ELSE 0 END), 0) AS owed,
              COALESCE(SUM(CASE WHEN t.transaction_type = 'Credit'
                                THEN t.amount_paise ELSE 0 END), 0) AS paid
            FROM customers c
            LEFT JOIN transactions t
              ON t.customer_id = c.id AND t.is_deleted = 0
            WHERE c.owner_id = :o
    \"\"\"
    params = {"o": owner_id}
    if party_type and party_type.strip().lower() != "all":
        query += " AND LOWER(COALESCE(c.party_type, 'customer')) = :pt"
        params["pt"] = party_type.strip().lower()

    query += \"\"\"
            GROUP BY c.id, c.name, c.party_type
            ORDER BY (owed - paid) DESC
    \"\"\"
    with get_db() as db:
        rows = db.execute(text(query), params).fetchall()
    return [
        {
            "id": r[0],
            "name": r[1],
            "party_type": r[2] or "customer",
            "balance_paise": int((r[3] or 0) - (r[4] or 0)),
        }
        for r in rows
    ]"""

assert old_list in content, "old_list not found"
content = content.replace(old_list, new_list)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)
print("SUCCESSFULLY UPDATED database.py")
