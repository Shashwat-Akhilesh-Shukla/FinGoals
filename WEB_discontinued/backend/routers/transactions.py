from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from sqlalchemy.orm import Session
from sqlalchemy import desc, func
from typing import Optional, List
from datetime import datetime
import csv
import io

from database import get_db
from models import Transaction, Category
from schemas import (
    TransactionCreate, TransactionUpdate, TransactionResponse,
    TransactionListResponse, CategoryCreate, CategoryResponse,
)

router = APIRouter(prefix="/transactions", tags=["transactions"])


@router.get("", response_model=TransactionListResponse)
def list_transactions(
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=200),
    type: Optional[str] = None,
    category: Optional[str] = None,
    month: Optional[str] = None,
    db: Session = Depends(get_db),
):
    q = db.query(Transaction)
    if type:
        q = q.filter(Transaction.type == type)
    if category:
        q = q.filter(Transaction.category == category)
    if month:
        q = q.filter(func.strftime("%Y-%m", Transaction.timestamp) == month)
    total = q.count()
    items = (
        q.order_by(desc(Transaction.timestamp))
        .offset((page - 1) * per_page)
        .limit(per_page)
        .all()
    )
    return TransactionListResponse(
        items=items,
        total=total,
        page=page,
        per_page=per_page,
        has_more=(page * per_page) < total,
    )


@router.post("", response_model=TransactionResponse, status_code=201)
def create_transaction(data: TransactionCreate, db: Session = Depends(get_db)):
    tx = Transaction(
        amount=abs(data.amount),
        type=data.type,
        category=data.category,
        account=data.account,
        timestamp=data.timestamp or datetime.now(),
        note=data.note,
    )
    db.add(tx)
    db.commit()
    db.refresh(tx)
    return tx


@router.put("/{tx_id}", response_model=TransactionResponse)
def update_transaction(tx_id: int, data: TransactionUpdate, db: Session = Depends(get_db)):
    tx = db.query(Transaction).filter(Transaction.id == tx_id).first()
    if not tx:
        raise HTTPException(404, "Transaction not found")
    updates = data.model_dump(exclude_none=True)
    if "amount" in updates:
        updates["amount"] = abs(updates["amount"])
    for k, v in updates.items():
        setattr(tx, k, v)
    db.commit()
    db.refresh(tx)
    return tx


@router.delete("/{tx_id}", status_code=204)
def delete_transaction(tx_id: int, db: Session = Depends(get_db)):
    tx = db.query(Transaction).filter(Transaction.id == tx_id).first()
    if not tx:
        raise HTTPException(404, "Transaction not found")
    db.delete(tx)
    db.commit()


@router.post("/import")
async def import_csv(file: UploadFile = File(...), db: Session = Depends(get_db)):
    content = await file.read()
    text_content = content.decode("utf-8-sig")
    reader = csv.DictReader(io.StringIO(text_content))
    created, errors = 0, []
    for i, row in enumerate(reader):
        try:
            tx = Transaction(
                amount=abs(float(row.get("amount", 0))),
                type=row.get("type", "expense").lower(),
                category=row.get("category", "Other Income"),
                account=row.get("account", "Bank"),
                timestamp=datetime.fromisoformat(
                    row.get("timestamp", datetime.now().isoformat())
                ),
                note=row.get("note", ""),
            )
            db.add(tx)
            created += 1
        except Exception as e:
            errors.append(f"Row {i + 2}: {e}")
    db.commit()
    return {"imported": created, "errors": errors}


# ---------- Categories ----------

@router.get("/categories", response_model=List[CategoryResponse])
def list_categories(db: Session = Depends(get_db)):
    return db.query(Category).order_by(Category.bucket, Category.name).all()


@router.post("/categories", response_model=CategoryResponse, status_code=201)
def create_category(data: CategoryCreate, db: Session = Depends(get_db)):
    cat = Category(
        name=data.name,
        bucket=data.bucket,
        transaction_type=data.transaction_type,
        is_custom=True,
    )
    db.add(cat)
    db.commit()
    db.refresh(cat)
    return cat


@router.delete("/categories/{cat_id}", status_code=204)
def delete_category(cat_id: int, db: Session = Depends(get_db)):
    cat = (
        db.query(Category)
        .filter(Category.id == cat_id, Category.is_custom == True)
        .first()
    )
    if not cat:
        raise HTTPException(404, "Custom category not found")
    db.delete(cat)
    db.commit()
