from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from services.ai_parser import parse_event_text
from models import ParseRequest, ParseResponse

from auth import require_api_token
from database import get_db
from models import Event, Step, EventCreate, EventResponse, StepItem

from datetime import datetime

router = APIRouter(
    prefix="/api/events",
    tags=["events"],
    dependencies=[Depends(require_api_token)],
)

@router.post("/parse",response_model=ParseResponse)
def parse_event_text_api(req: ParseRequest):
    result = parse_event_text(req.text)
    return ParseResponse(**result)

@router.post("",response_model=EventResponse)
def create_event(req:EventCreate,db: Session = Depends(get_db)):
    event = Event(
        title=req.title,
        purpose=req.purpose,
        summary=req.summary,
        status=req.status,
        quadrant=req.quadrant,
        scheduled_date=req.scheduled_date,
        time_slot= req.time_slot,
        calendar_order=req.calendar_order,
    )
    db.add(event)
    db.flush()

    for s in req.steps:
        step = Step(
            event_id=event.id,
            step_order=s.step_order,
            description=s.description,
            estimated_min=s.estimated_min
        )
        db.add(step)

    db.commit()
    db.refresh(event)
    return _to_response(event)

@router.get("", response_model=list[EventResponse])
def list_events(status: str | None = None, db: Session = Depends(get_db)):
    query = db.query(Event).filter(Event.deleted_at.is_(None))
    if status:
        query = query.filter(Event.status == status)
    query = query.order_by(Event.created_at.desc())
    return [_to_response(e) for e in query.all()]

@router.get("/{event_id}", response_model=EventResponse)
def get_event(event_id: int, db: Session = Depends(get_db)):
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    return _to_response(event)


@router.put("/{event_id}", response_model=EventResponse)
def update_event(event_id: int, req: EventCreate, db: Session = Depends(get_db)):
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")

    event.title = req.title
    event.purpose = req.purpose
    event.summary = req.summary
    event.status = req.status
    event.quadrant = req.quadrant
    event.scheduled_date = req.scheduled_date
    event.time_slot = req.time_slot
    event.calendar_order = req.calendar_order

    # 步骤的处理：先删旧的，再插新的
    db.query(Step).filter(Step.event_id == event_id).delete()

    for s in req.steps:
        step = Step(
            event_id=event.id,
            step_order=s.step_order,
            description=s.description,
            estimated_min=s.estimated_min,
        )
        db.add(step)

    db.commit()
    db.refresh(event)
    return _to_response(event)

@router.delete("/{event_id}")
def delete_event(event_id: int, db: Session = Depends(get_db)):
    event = db.query(Event).filter(Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    event.deleted_at = datetime.now().isoformat()
    db.commit()
    return {"ok": True}

def _to_response(event: Event) -> EventResponse:
    return EventResponse(
        id=event.id,
        title=event.title or "",
        summary=event.summary or "",
        purpose=event.purpose or "",
        status=event.status or "inbox",
        quadrant=event.quadrant,
        scheduled_date=event.scheduled_date,
        time_slot=event.time_slot,
        calendar_order=event.calendar_order or 0,
        steps=[
            StepItem(
                step_order=s.step_order or 1,
                description=s.description or "",
                estimated_min=s.estimated_min or 0,
            )
            for s in sorted(event.steps, key=lambda x: x.step_order)
          ],
        created_at=event.created_at or "",
        completed_at=event.completed_at,
      )
