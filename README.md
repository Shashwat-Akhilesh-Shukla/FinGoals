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

## Financial Health Score (v2)

A weighted score out of **100**, computed from 5 factors (each out of 20):

| Factor | Points | How it's Scored |
|---|---|---|
| **Savings** | 0–20 | Savings rate capped at 20% |
| **Investment** | 0–20 | Investment rate capped at 20% |
| **Emergency** | 0–20 | Avg. progress of emergency goals |
| **Expenses** | 0–20 | Essential ratio (80% = 0 pts, ≤50% = 20 pts) |
| **Goals** | 0–20 | Avg. progress of active non-emergency goals |

| Label | Score |
|---|---|
| **EXCELLENT** | ≥ 80 |
| **GOOD** | 60–79 |
| **AVERAGE** | 40–59 |
| **POOR** | 20–39 |
| **CRITICAL** | < 20 |

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
   - **Auto-Link to Transaction Category**: When creating a goal, link it to a savings or investment category (e.g. "Emergency Fund", "SIP / Mutual Funds"). The goal's `current_amount` is automatically derived from the **cumulative all-time sum** of all transactions in that category — no manual updates needed.
   - Linked goals show an `⚡ AUTO · linked to "[Category]"` badge instead of a manual add input.
   - Manual goals (no link) retain the quick-add input field.
   - Features color-coded completion progress bars (Red for <60%, Amber for 60–99%, Green for ≥100%).
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
