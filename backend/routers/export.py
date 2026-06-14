from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse, FileResponse
from sqlalchemy.orm import Session
import csv
import json
import io
import shutil
import os
from datetime import datetime

from database import get_db, BASE_DIR
from models import Transaction, Goal, Category

router = APIRouter(prefix="/export", tags=["export"])


@router.get("/csv")
def export_csv(db: Session = Depends(get_db)):
    txns = db.query(Transaction).order_by(Transaction.timestamp.desc()).all()
    out = io.StringIO()
    w = csv.writer(out)
    w.writerow(["id", "amount", "type", "category", "account", "timestamp", "note"])
    for t in txns:
        w.writerow([
            t.id, t.amount, t.type, t.category, t.account,
            t.timestamp.isoformat(), t.note or "",
        ])
    out.seek(0)
    filename = f"fingoals_{datetime.now().strftime('%Y%m%d')}.csv"
    return StreamingResponse(
        io.BytesIO(out.getvalue().encode()),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@router.get("/json")
def export_json(db: Session = Depends(get_db)):
    data = {
        "exported_at": datetime.now().isoformat(),
        "transactions": [
            {
                "id": t.id, "amount": t.amount, "type": t.type,
                "category": t.category, "account": t.account,
                "timestamp": t.timestamp.isoformat(), "note": t.note,
            }
            for t in db.query(Transaction).order_by(Transaction.timestamp.desc()).all()
        ],
        "goals": [
            {
                "id": g.id, "name": g.name, "type": g.type,
                "target_amount": g.target_amount, "current_amount": g.current_amount,
                "monthly_target": g.monthly_target,
            }
            for g in db.query(Goal).all()
        ],
        "custom_categories": [
            {"name": c.name, "bucket": c.bucket, "transaction_type": c.transaction_type}
            for c in db.query(Category).filter(Category.is_custom == True).all()
        ],
    }
    body = json.dumps(data, indent=2)
    filename = f"fingoals_backup_{datetime.now().strftime('%Y%m%d')}.json"
    return StreamingResponse(
        io.BytesIO(body.encode()),
        media_type="application/json",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@router.get("/backup")
def download_backup():
    db_path = os.path.join(BASE_DIR, "fingoals.db")
    if not os.path.exists(db_path):
        return {"error": "Database not found"}
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = os.path.join(BASE_DIR, f"fingoals_backup_{ts}.db")
    shutil.copy2(db_path, backup)
    return FileResponse(
        backup,
        media_type="application/octet-stream",
        filename=os.path.basename(backup),
    )
