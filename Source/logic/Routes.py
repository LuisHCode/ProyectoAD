
from fastapi import FastAPI, Request, Response
from logic import Cliente

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "API funcionando"}

@app.post("/cliente")
async def insertarCliente(request: Request, response: Response):
    return await Cliente.insertar_cliente(request, response)