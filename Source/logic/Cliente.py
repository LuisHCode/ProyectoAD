
from fastapi import APIRouter, Request, Response, status, Depends, HTTPException
from sqlalchemy import text
from fastapi.responses import JSONResponse
from fastapi import HTTPException
from sqlalchemy.exc import DBAPIError
from datetime import datetime
from Conexion.conexion import obtener_conexion_sqlserver
# logic/Cliente.py
from fastapi import Request, Response, HTTPException
from sqlalchemy.exc import DBAPIError
from Conexion.conexion import obtener_conexion_sqlserver

async def insertar_cliente(request: Request, response: Response):
    body = await request.json()
    for k, v in body.items():
        if isinstance(v, str) and v.strip() == "":
            body[k] = None

    db = obtener_conexion_sqlserver()
    if db is None:
        raise HTTPException(status_code=500, detail="No se pudo abrir conexión a la base de datos")
    
    nombreCliente = body.get("Nombre_Cliente")
    telefonoCliente = body.get("Telefono_Cliente")
    instagramCliente = body.get("Instagram_Cliente")
    emailCliente = body.get("Email_Cliente")
    direccion = body.get("Direccion")

    # Convertir valores vacíos a None
    def limpiar(valor):
        return None if valor is None or (isinstance(valor, str) and valor.strip() == "") else valor

    nombreCliente = limpiar(nombreCliente)
    telefonoCliente = limpiar(telefonoCliente)
    instagramCliente = limpiar(instagramCliente)
    emailCliente = limpiar(emailCliente)
    direccion = limpiar(direccion)
    
    if not nombreCliente or nombreCliente[0] == "" or nombreCliente[0] is None:
        raise HTTPException(status_code=400, detail="Faltan parámetros obligatorios")

    try:
        sql = """
            EXEC InsertarCliente
                @Nombre_Cliente = ?, 
                @Telefono_Cliente = ?, 
                @Instagram_Cliente = ?,
                @Email_Cliente = ?,
                @Direccion = ?
        """
        cursor = db.cursor()
        cursor.execute(sql, (
            nombreCliente,
            telefonoCliente,
            instagramCliente,
            emailCliente,
            direccion
        ))
        result = None
        try:
            result = cursor.fetchone()
        except Exception:
            pass
        if result and isinstance(result, dict) and "ErrorMessage" in result:
            cursor.close()
            raise HTTPException(status_code=400, detail=result["ErrorMessage"])
        db.commit()
        cursor.close()
        return {"mensaje": "Cliente insertado con éxito"}
    except DBAPIError as e:
        raise HTTPException(status_code=500, detail="DB error: " + str(e.orig))
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error inesperado: " + str(e))
    finally:
        db.close()
