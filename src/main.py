from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from src.database import get_db

app = FastAPI(title="NoLogic MES API", version="0.1.0")

@app.get("/")
def health_check():
    return {"status": "online", "system": "NoLogic MES"}

@app.get("/db-check")
def check_database(db: Session = Depends(get_db)):
    result = db.execute(text("SELECT version();")).fetchone()
    if result:
        return {"database_connected": True, "postgres_version": result[0]}
    else:
        return {"database_connected": False}