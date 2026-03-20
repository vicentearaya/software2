from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "CleanPool API funcionando"}

@app.get("/readings")
def get_readings():
    return {
        "ph": 7.2,
        "cloro": 1.5,
        "temperatura": 25
    }