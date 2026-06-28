from sqlalchemy import Column, Integer, Float, String, DateTime, Boolean, Text, Index
from sqlalchemy.sql import func
from database import Base


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    amount = Column(Float, nullable=False)
    type = Column(String(20), nullable=False)
    category = Column(String(100), nullable=False)
    account = Column(String(100), nullable=False, default="Bank")
    timestamp = Column(DateTime, nullable=False, default=func.now())
    note = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now())

    __table_args__ = (
        Index("idx_ts", "timestamp"),
        Index("idx_type", "type"),
        Index("idx_cat", "category"),
        Index("idx_type_ts", "type", "timestamp"),
    )


class Goal(Base):
    __tablename__ = "goals"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(200), nullable=False)
    type = Column(String(20), nullable=False)
    target_amount = Column(Float, nullable=False)
    current_amount = Column(Float, default=0.0)
    monthly_target = Column(Float, nullable=True)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now())


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), nullable=False, unique=True)
    bucket = Column(String(50), nullable=False)
    transaction_type = Column(String(20), nullable=False)
    is_custom = Column(Boolean, default=False)
