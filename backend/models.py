from database import Base
from sqlalchemy import Column, Integer, String, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from pydantic import BaseModel, Field

class Event(Base):
    __tablename__="events"

    id = Column(Integer,primary_key = True,autoincrement=True)
    title = Column(String,nullable= False,default="")
    summary = Column(String(20),nullable= False,default="")
    purpose =Column(Text,default="")
    status = Column(String,nullable= False,default="inbox")
    quadrant = Column(String,nullable=True)
    scheduled_date = Column(String(20),nullable=True)
    time_slot = Column(String)
    calendar_order = Column(Integer, nullable=False, default=0)
    created_at = Column(String(30), default=lambda: datetime.now().isoformat())
    updated_at = Column(String(30), default=lambda: datetime.now().isoformat())
    completed_at = Column(String(30),nullable=True)
    deleted_at = Column(String(30),nullable=True)

    steps = relationship("Step", back_populates="event", cascade="all, delete-orphan")
    pomodoro_sessions = relationship("PomodoroSession", back_populates="event", cascade="all, delete-orphan")

class Step(Base):
    __tablename__ = "steps"

    id = Column(Integer,primary_key = True,autoincrement=True)
    event_id = Column(Integer,ForeignKey("events.id"),nullable=False)
    step_order = Column(Integer, default=1)
    description = Column(Text,nullable=True)
    estimated_min = Column(Integer,nullable=True)

    event = relationship("Event", back_populates="steps")

class  PomodoroSession(Base):
    __tablename__ = "pomodoro_sessions"

    id = Column(Integer,primary_key = True,autoincrement=True)
    event_id = Column(Integer,ForeignKey("events.id"),nullable=False)
    start_time = Column(Text,nullable=True)
    end_time = Column(Text,nullable=True)
    status = Column(String,nullable=True,default="running") #running/paused/completed
    duration_sec = Column(Integer,nullable=True)

    interruptions = relationship("Interruption", back_populates="session", cascade="all, delete-orphan")
    ideas = relationship("Idea", back_populates="session", cascade="all, delete-orphan")
    event = relationship("Event", back_populates="pomodoro_sessions")

class Interruption(Base):
    __tablename__ = "interruptions"

    id = Column(Integer,primary_key = True,autoincrement=True)
    session_id = Column(Integer,ForeignKey("pomodoro_sessions.id"),nullable=False)
    reason = Column(Text,nullable=True)
    minute = Column(Integer,nullable=True) #第几分钟被打断
    resolved = Column(Integer,nullable=True,default=0) #0 待解决 1 已解决

    session = relationship("PomodoroSession", back_populates="interruptions")

class Idea(Base):
    __tablename__ = "ideas"

    id = Column(Integer,primary_key = True,autoincrement=True)
    session_id = Column(Integer,ForeignKey("pomodoro_sessions.id"),nullable=False)
    content = Column(Text,nullable=True)
    minute = Column(Integer,nullable=True)
    added_to_inbox = Column(Integer,nullable=True,default=0) #0 未加入 1 已加入事件箱

    session = relationship("PomodoroSession", back_populates="ideas")

#请求模型
class ParseRequest(BaseModel):
    text: str

#步骤模型
class StepItem(BaseModel):
    step_order: int = 1
    description: str = ""
    estimated_min: int = 0

    class Config:
        from_attributes = True

class EventItem(BaseModel):
    title:str = ""
    summary:str = ""
    steps:list[StepItem] = Field(default_factory=list)
    total_minutes:int = 0

#AI拆解响应模型
class ParseResponse(BaseModel):
    events:list[EventItem] = Field(default_factory=list)

#事件创建请求模型
class EventCreate(BaseModel):
    title: str = ""
    purpose: str = ""
    summary: str = ""
    status: str = "inbox"
    quadrant: str | None = None
    scheduled_date: str | None = None
    time_slot: str | None = None
    calendar_order: int = 0
    steps: list[StepItem] = Field(default_factory=list)

#事件返回模型
class EventResponse(BaseModel):
    id: int
    title: str
    summary: str = ""
    purpose: str = ""
    status: str
    quadrant: str | None = None
    scheduled_date: str | None = None
    time_slot: str | None = None
    calendar_order: int = 0
    steps: list[StepItem] = Field(default_factory=list)
    created_at: str = ""
    completed_at: str | None = None

    class Config:
        from_attributes = True
