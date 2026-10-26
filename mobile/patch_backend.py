import sys

path = r"C:\Users\user\Desktop\ANTIGRAVTY\app\routes\customers.py"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

if "create_customer" not in content:
    # Add get_or_create_customer import if not present
    if "get_or_create_customer" not in content:
        content = content.replace(
            "list_customers_with_balance,",
            "get_or_create_customer,\n    list_customers_with_balance,",
        )

    snippet = """class CreateCustomerReq(BaseModel):
    name: str
    phone: str | None = None


@router.post("/customers")
def create_customer(req: CreateCustomerReq, owner_id: str = Depends(current_owner)):
    name = (req.name or "").strip()
    if not name:
        raise HTTPException(400, "Customer name cannot be empty.")
    customer_id = get_or_create_customer(owner_id, name)
    return {
        "success": True,
        "id": customer_id,
        "name": name,
        "phone": req.phone or "",
        "balance_paise": 0,
        "balance_display": "₹0",
    }


@router.get("/customers")"""

    if '@router.get("/customers")' not in content:
        sys.stderr.write("ERROR: Anchor '@router.get(\"/customers\")' not found in customers.py\n")
        sys.exit(1)
    content = content.replace('@router.get("/customers")', snippet)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("SUCCESS: POST /customers added to customers.py")
else:
    print("ALREADY EXISTS")
