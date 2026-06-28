from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class TransactionCreate(BaseModel):
    amount: float
    type: str
    category: str
    account: str = "Bank"
    timestamp: Optional[datetime] = None
    note: Optional[str] = None


class TransactionUpdate(BaseModel):
    amount: Optional[float] = None
    type: Optional[str] = None
    category: Optional[str] = None
    account: Optional[str] = None
    timestamp: Optional[datetime] = None
    note: Optional[str] = None


class TransactionResponse(BaseModel):
    id: int
    amount: float
    type: str
    category: str
    account: str
    timestamp: datetime
    note: Optional[str] = None
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class TransactionListResponse(BaseModel):
    items: List[TransactionResponse]
    total: int
    page: int
    per_page: int
    has_more: bool


class GoalCreate(BaseModel):
    name: str
    type: str
    target_amount: float
    current_amount: float = 0.0
    monthly_target: Optional[float] = None
    description: Optional[str] = None


class GoalUpdate(BaseModel):
    name: Optional[str] = None
    target_amount: Optional[float] = None
    current_amount: Optional[float] = None
    monthly_target: Optional[float] = None
    description: Optional[str] = None


class GoalResponse(BaseModel):
    id: int
    name: str
    type: str
    target_amount: float
    current_amount: float
    monthly_target: Optional[float] = None
    description: Optional[str] = None
    progress_pct: float
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class CategoryCreate(BaseModel):
    name: str
    bucket: str
    transaction_type: str


class CategoryResponse(BaseModel):
    id: int
    name: str
    bucket: str
    transaction_type: str
    is_custom: bool

    model_config = {"from_attributes": True}


class Verdict(BaseModel):
    label: str
    color: str
    score: int


class VerdictsResponse(BaseModel):
    savings: Verdict
    investment: Verdict
    expense: Verdict
    overall_score: int
    overall_label: str
