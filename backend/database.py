from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from typing import Generator
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATABASE_URL = f"sqlite:///{os.path.join(BASE_DIR, 'fingoals.db')}"

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False},
)

@event.listens_for(engine, "connect")
def optimize_sqlite(dbapi_connection, connection_record):
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA journal_mode=WAL")
    cursor.execute("PRAGMA synchronous=NORMAL")
    cursor.execute("PRAGMA cache_size=-32000")
    cursor.execute("PRAGMA temp_store=MEMORY")
    cursor.execute("PRAGMA mmap_size=268435456")
    cursor.close()

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

class Base(DeclarativeBase):
    pass

def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

SEED_CATEGORIES = [
    ("Rent", "essentials", "expense"),
    ("Groceries", "essentials", "expense"),
    ("Utilities", "essentials", "expense"),
    ("Transport", "essentials", "expense"),
    ("Healthcare", "essentials", "expense"),
    ("Insurance", "essentials", "expense"),
    ("EMI / Loan", "essentials", "expense"),
    ("Dining Out", "lifestyle", "expense"),
    ("Shopping", "lifestyle", "expense"),
    ("Entertainment", "lifestyle", "expense"),
    ("Subscriptions", "lifestyle", "expense"),
    ("Personal Care", "lifestyle", "expense"),
    ("Travel", "lifestyle", "expense"),
    ("Gifts & Donations", "lifestyle", "expense"),
    ("Stocks", "investments", "investment"),
    ("SIP / Mutual Funds", "investments", "investment"),
    ("Crypto", "investments", "investment"),
    ("Real Estate", "investments", "investment"),
    ("Gold", "investments", "investment"),
    ("NPS", "investments", "investment"),
    ("ELSS", "investments", "investment"),
    ("Emergency Fund", "savings", "savings"),
    ("Fixed Deposit", "savings", "savings"),
    ("PPF", "savings", "savings"),
    ("Recurring Deposit", "savings", "savings"),
    ("Other Savings", "savings", "savings"),
    ("Salary", "income", "income"),
    ("Freelance", "income", "income"),
    ("Business", "income", "income"),
    ("Dividends", "income", "income"),
    ("Investment Returns", "income", "income"),
    ("Rental Income", "income", "income"),
    ("Other Income", "income", "income"),
]
