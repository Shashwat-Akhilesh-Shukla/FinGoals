from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import Optional
from datetime import datetime, date

from database import get_db
from schemas import Verdict, VerdictsResponse

router = APIRouter(prefix="/analytics", tags=["analytics"])


def _subtract_months(d: date, months: int) -> date:
    import calendar
    month = d.month - months
    year = d.year
    while month <= 0:
        month += 12
        year -= 1
    day = min(d.day, calendar.monthrange(year, month)[1])
    return date(year, month, day)


def _monthly_data(db: Session, month: str) -> dict:
    row = db.execute(
        text("""
            SELECT
              COALESCE(SUM(CASE WHEN t.type='income'     THEN t.amount ELSE 0 END), 0) AS income,
              COALESCE(SUM(CASE WHEN t.type='expense'    THEN t.amount ELSE 0 END), 0) AS expenses,
              COALESCE(SUM(CASE WHEN t.type='investment' THEN t.amount ELSE 0 END), 0) AS investments,
              COALESCE(SUM(CASE WHEN t.type='savings'    THEN t.amount ELSE 0 END), 0) AS savings,
              COALESCE(SUM(CASE WHEN t.type='expense' AND c.bucket='essentials'
                                THEN t.amount ELSE 0 END), 0)                          AS essentials,
              COALESCE(SUM(CASE WHEN t.type='expense' AND c.bucket='lifestyle'
                                THEN t.amount ELSE 0 END), 0)                          AS lifestyle
            FROM transactions t
            LEFT JOIN categories c ON t.category = c.name
            WHERE strftime('%Y-%m', t.timestamp) = :month
        """),
        {"month": month},
    ).fetchone()

    income      = row.income or 0
    expenses    = row.expenses or 0
    investments = row.investments or 0
    savings     = row.savings or 0
    essentials  = row.essentials or 0
    lifestyle   = row.lifestyle or 0

    sr = round((income - expenses) / income * 100, 2) if income > 0 else 0
    ir = round(investments / income * 100, 2)          if income > 0 else 0
    er = round(essentials / income * 100, 2)           if income > 0 else 0

    return {
        "income": income, "expenses": expenses,
        "investments": investments, "savings": savings,
        "essentials": essentials, "lifestyle": lifestyle,
        "net": income - expenses - investments - savings,
        "savings_rate": sr, "investment_rate": ir, "essential_ratio": er,
    }


def _verdicts(data: dict) -> VerdictsResponse:
    sr, ir, er = data["savings_rate"], data["investment_rate"], data["essential_ratio"]

    if sr < 5:
        sv = Verdict(label="FAILED",  color="red",   score=0)
    elif sr < 20:
        sv = Verdict(label="WEAK",    color="amber", score=1)
    elif sr < 40:
        sv = Verdict(label="GOOD",    color="green", score=2)
    else:
        sv = Verdict(label="STRONG",  color="green", score=3)

    iv = Verdict(
        label="NOT BUILDING WEALTH" if ir < 10 else "BUILDING WEALTH",
        color="red"   if ir < 10 else "green",
        score=0       if ir < 10 else 1,
    )
    ev = Verdict(
        label="OVERDEPENDENT" if er > 60 else "CONTROLLED",
        color="red"           if er > 60 else "green",
        score=0               if er > 60 else 1,
    )

    score = sv.score + iv.score + ev.score
    label_map = {0: "CRITICAL", 1: "POOR", 2: "POOR", 3: "AVERAGE", 4: "GOOD", 5: "EXCELLENT"}
    overall = label_map.get(score, "AVERAGE")

    return VerdictsResponse(
        savings=sv, investment=iv, expense=ev,
        overall_score=score, overall_label=overall,
    )


@router.get("/summary")
def get_summary(month: Optional[str] = None, db: Session = Depends(get_db)):
    if not month:
        month = datetime.now().strftime("%Y-%m")
    data = _monthly_data(db, month)
    return {"month": month, **data}


@router.get("/verdicts")
def get_verdicts(month: Optional[str] = None, db: Session = Depends(get_db)):
    if not month:
        month = datetime.now().strftime("%Y-%m")
    return _verdicts(_monthly_data(db, month))


@router.get("/trends")
def get_trends(
    months: int = Query(6, ge=1, le=24),
    db: Session = Depends(get_db),
):
    today = date.today().replace(day=1)
    result = []
    for i in range(months - 1, -1, -1):
        d = _subtract_months(today, i)
        m = d.strftime("%Y-%m")
        data = _monthly_data(db, m)
        result.append({
            "month": m,
            "income": data["income"],
            "expenses": data["expenses"],
            "investments": data["investments"],
            "savings": data["savings"],
            "savings_rate": data["savings_rate"],
        })
    return result


@router.get("/breakdown")
def get_breakdown(month: Optional[str] = None, db: Session = Depends(get_db)):
    if not month:
        month = datetime.now().strftime("%Y-%m")

    rows = db.execute(
        text("""
            SELECT t.category,
                   COALESCE(c.bucket, 'other') AS bucket,
                   SUM(t.amount)               AS amount
            FROM transactions t
            LEFT JOIN categories c ON t.category = c.name
            WHERE strftime('%Y-%m', t.timestamp) = :month
              AND t.type = 'expense'
            GROUP BY t.category
            ORDER BY amount DESC
        """),
        {"month": month},
    ).fetchall()

    total = sum(r.amount for r in rows) or 1
    return [
        {
            "category": r.category,
            "bucket": r.bucket,
            "amount": round(r.amount, 2),
            "pct": round(r.amount / total * 100, 1),
        }
        for r in rows
    ]
