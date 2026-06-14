# FinGoals — Financial Command Center

> Local-first · Zero cloud · Zero AI · Zero external APIs

A precision personal finance system that enforces discipline through data, clear visualization, and brutal evaluation.

---

## Quick Start

### Prerequisites
- Python 3.10+
- Node.js 16+ (v22.4 confirmed working)

### 1. Install Python dependencies
```bash
pip install -r requirements.txt
```

### 2. Start the backend
```bash
python run.py
# API: http://localhost:8000
# Docs: http://localhost:8000/docs
```

### 3. Start the frontend (new terminal)
```bash
cd frontend
npm install
npm run dev
# App: http://localhost:5173
```

### Or use the one-click launcher (Windows)
```
start.bat
```

---

## Architecture

```
FinGoals/
├── backend/
│   ├── main.py              # FastAPI app
│   ├── database.py          # SQLite + WAL mode
│   ├── models.py            # SQLAlchemy ORM
│   ├── schemas.py           # Pydantic schemas
│   └── routers/
│       ├── transactions.py  # CRUD + CSV import
│       ├── analytics.py     # Ratio engine + verdicts
│       ├── goals.py         # Goal tracking
│       └── export.py        # CSV/JSON/backup
├── frontend/
│   └── src/
│       ├── pages/           # Dashboard, Transactions, Goals, Settings
│       ├── components/      # Reusable components + SVG charts
│       ├── lib/             # API client + formatters
│       └── store/           # App context (month, form state)
├── requirements.txt
├── run.py
└── start.bat
```

---

## Verdict System

| Verdict | Condition |
|---|---|
| **STRONG** | Savings rate > 40% |
| **GOOD** | Savings rate 20–40% |
| **WEAK** | Savings rate 5–20% |
| **FAILED** | Savings rate < 5% |
| **NOT BUILDING WEALTH** | Investment rate < 10% |
| **OVERDEPENDENT** | Essentials > 60% of income |

---

## CSV Import Format

```csv
amount,type,category,account,timestamp,note
50000,income,Salary,Bank,2026-06-01T09:00:00,June salary
12000,expense,Rent,Bank,2026-06-02T00:00:00,
5000,investment,SIP / Mutual Funds,Bank,2026-06-03T00:00:00,HDFC Midcap
```

---

## Tech Stack

| Layer | Tech |
|---|---|
| Backend | FastAPI + Uvicorn |
| Database | SQLite (WAL mode, indexed) |
| ORM | SQLAlchemy 2.0 |
| Frontend | React + Vite |
| Styling | TailwindCSS |
| Charts | Custom SVG (zero deps) |
| State | TanStack Query + React Context |
| Animations | Framer Motion |
| Icons | Lucide React |
| PWA | Web App Manifest |

---

*Built to be a financial mirror. No softening. No vanity.*
