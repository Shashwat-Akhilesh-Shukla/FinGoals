from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from models import Goal
from schemas import GoalCreate, GoalUpdate, GoalResponse

router = APIRouter(prefix="/goals", tags=["goals"])


def _to_response(g: Goal) -> GoalResponse:
    pct = (
        min(round(g.current_amount / g.target_amount * 100, 1), 100)
        if g.target_amount > 0
        else 0
    )
    return GoalResponse(
        id=g.id, name=g.name, type=g.type,
        target_amount=g.target_amount, current_amount=g.current_amount,
        monthly_target=g.monthly_target, description=g.description,
        progress_pct=pct, created_at=g.created_at,
    )


@router.get("", response_model=List[GoalResponse])
def list_goals(db: Session = Depends(get_db)):
    return [_to_response(g) for g in db.query(Goal).all()]


@router.post("", response_model=GoalResponse, status_code=201)
def create_goal(data: GoalCreate, db: Session = Depends(get_db)):
    g = Goal(**data.model_dump())
    db.add(g)
    db.commit()
    db.refresh(g)
    return _to_response(g)


@router.put("/{goal_id}", response_model=GoalResponse)
def update_goal(goal_id: int, data: GoalUpdate, db: Session = Depends(get_db)):
    g = db.query(Goal).filter(Goal.id == goal_id).first()
    if not g:
        raise HTTPException(404, "Goal not found")
    for k, v in data.model_dump(exclude_none=True).items():
        setattr(g, k, v)
    db.commit()
    db.refresh(g)
    return _to_response(g)


@router.delete("/{goal_id}", status_code=204)
def delete_goal(goal_id: int, db: Session = Depends(get_db)):
    g = db.query(Goal).filter(Goal.id == goal_id).first()
    if not g:
        raise HTTPException(404, "Goal not found")
    db.delete(g)
    db.commit()
