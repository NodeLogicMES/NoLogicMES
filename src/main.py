from fastapi import FastAPI, Depends
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

from sqlalchemy.orm import Session
from sqlalchemy import text
from src.database import get_db
app = FastAPI(title="NoLogic MES API", version="0.1.0")

app.mount("/static", StaticFiles(directory="src/static"), name="static")


@app.get("/")
def leer_index():
    return FileResponse("src/static/index.html")

@app.get("/office")
def leer_oficina():
    return {"status": "oficina", "system": "NoLogic MES"}

@app.get("/factory")
def leer_fabrica():
    return {"status": "fabrica", "system": "NoLogic MES"}