"""
seed.py — Script de uso único para desarrollo local y demo.
NO incluir en producción ni en el repo principal.

Uso:
    1. Asegúrate de tener MONGODB_URI en tu .env
    2. pip install pymongo[srv] passlib[bcrypt]
    3. python seed.py
"""

import os

from dotenv import load_dotenv
from passlib.context import CryptContext
from pymongo import MongoClient

load_dotenv()

MONGODB_URI = os.environ["MONGODB_URI"]
DATABASE_NAME = os.getenv("DATABASE_NAME", "cleanpool")

_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

SEED_USER = {
    "username": "admin",
    "password": _pwd_context.hash("cleanpool2026"),
}

client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=5_000)
db = client[DATABASE_NAME]
col = db["usuarios"]

existing = col.find_one({"username": SEED_USER["username"]})
if existing:
    print(f"[seed] Usuario '{SEED_USER['username']}' ya existe. Nada que hacer.")
else:
    result = col.insert_one(SEED_USER)
    print(f"[seed] Usuario '{SEED_USER['username']}' insertado. _id={result.inserted_id}")

client.close()
