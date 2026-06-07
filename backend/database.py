#每次函数需要操作数据库时，递给它一个可用连接，用完回收

from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy import text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.orm import DeclarativeBase
from config import DATABASE_URL

def ensure_database_parent():
    if not DATABASE_URL.startswith("sqlite:///"):
        return
    raw_path = DATABASE_URL.removeprefix("sqlite:///")
    if raw_path == ":memory:":
        return
    Path(raw_path).expanduser().resolve().parent.mkdir(parents=True, exist_ok=True)

ensure_database_parent()

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(
    DATABASE_URL,
    connect_args=connect_args)
SessionLocal = (sessionmaker(autocommit=False,autoflush=False,bind=engine))

class Base(DeclarativeBase):
    pass

def init_db():
    Base.metadata.create_all(bind=engine)
    ensure_schema()

def ensure_schema():
    with engine.begin() as conn:
        columns = conn.execute(text("PRAGMA table_info(events)")).fetchall()
        names = {row[1] for row in columns}
        if "calendar_order" not in names:
            conn.execute(
                text(
                    "ALTER TABLE events "
                    "ADD COLUMN calendar_order INTEGER NOT NULL DEFAULT 0"
                )
            )

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
