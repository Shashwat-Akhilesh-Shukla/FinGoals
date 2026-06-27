# FinGoals — Financial Command Center

> Local-first · Zero cloud · Zero AI · Zero external APIs

A precision personal finance system that enforces discipline through data, clear visualization, and brutal evaluation.

---

## Quick Start

### Prerequisites
- Python 3.10+
- Node.js 16+ (v22.4 confirmed working)
- Flutter SDK 3.12+ (for mobile application)

### Web Application

#### 1. Install Python dependencies
```bash
pip install -r requirements.txt
```

#### 2. Start the backend
```bash
python run.py
# API: http://localhost:8000
# Docs: http://localhost:8000/docs
```

#### 3. Start the frontend (new terminal)
```bash
cd frontend
npm install
npm run dev
# App: http://localhost:5173
```

#### Or use the one-click launcher (Windows)
```
start.bat
```

### Mobile Application

#### 1. Start the mobile app
```bash
cd mobile/my_app
flutter pub get
flutter run
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
├── mobile/
│   └── my_app/
│       └── lib/
│           ├── screens/     # Dashboard, Transactions, Goals, Settings screens
│           ├── widgets/     # Custom cards & labels
│           ├── api.dart     # Local storage API wrapper (CRUD)
│           ├── local_storage.dart # Local JSON file IO operations
│           └── formatters.dart # INR currency formatters & date parsing
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

## Mobile Application

The FinGoals Mobile App is a Flutter implementation designed for mobile devices. True to the project's core philosophy, it is **completely local-first, offline-ready, and has zero cloud or external API dependencies**.

### Key Features

1. **Local-First JSON Database**:
   - Stores transactions, custom categories, and goals on-device inside JSON files (`transactions.json`, `categories.json`, `goals.json`) using `path_provider` and `shared_preferences`.
   - Runs fully offline without any backend server.

2. **Dashboard & Metric Verdicts**:
   - Monthly financial snapshot showing **Net Balance**, **Income**, **Expenses**, **Investments**, and **Savings**.
   - Automatic execution of the precision **Verdict System** directly on the device, scoring performance and assigning rating labels.
   - Interactive breakdown of expenses by categories/buckets and trend history across 6 months.

3. **Transactions Manager**:
   - Complete CRUD operations to log, update, and delete transactions.
   - Quick search by category/note and filters for transactions by type.
   - Pagination (50 records per page) with manual loading for smooth, high-volume performance.
   - Supports five account types: Bank, Cash, Credit Card, UPI / Wallet, and Other.

4. **Goal Tracking**:
   - Set financial targets under three types: **Emergency Fund**, **SIP / Invest**, and **Custom**.
   - Features color-coded completion progress bars (Red for <60%, Amber for 60-99%, Green for >=100%).
   - Quick additions directly from the goals screen.
   - Supports monthly targets for SIP goals.

5. **Settings & Custom Categories**:
   - Dynamic adding and deleting of custom categories linked to standard buckets (Essentials, Lifestyle, Investments, Savings, Income).
   - Local Verdict Guide explaining the math behind saving rates and dependencies.

---

## Tech Stack

| Layer | Tech |
|---|---|
| Backend | FastAPI + Uvicorn |
| Database | SQLite (WAL mode, indexed) |
| ORM | SQLAlchemy 2.0 |
| Web Frontend | React + Vite |
| Web Styling | TailwindCSS |
| Web Charts | Custom SVG (zero deps) |
| Web State | TanStack Query + React Context |
| Web Animations | Framer Motion |
| Web Icons | Lucide React |
| PWA | Web App Manifest |
| Mobile Framework | Flutter (Dart SDK ^3.12.2) |
| Mobile Storage | path_provider + shared_preferences + local JSON |
| Mobile Formatting | intl (INR locale & compact scales) |

---

*Built to be a financial mirror. No softening. No vanity.*
