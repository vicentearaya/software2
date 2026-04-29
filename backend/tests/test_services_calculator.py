import pytest

from services.calculator import (
    calcular_tratamiento,
    evaluar_parametros_individuales,
    evaluarAptitud,
)


def test_evaluar_aptitud_sin_datos():
    assert evaluarAptitud(None, None, None) is None


def test_evaluar_aptitud_no_apta_si_un_parametro_falla():
    assert evaluarAptitud(7.4, 0.2, 28.0) == "NO APTA"


def test_evaluar_parametros_individuales_con_sin_datos():
    estados = evaluar_parametros_individuales(None, 1.5, 31.0)
    assert estados == {"ph": "SIN DATOS", "cloro": "NORMAL", "temperatura": "ALTO"}


def test_calcular_tratamiento_valida_volumen():
    with pytest.raises(ValueError, match="volumen"):
        calcular_tratamiento(7.0, 1.0, 0)


def test_calcular_tratamiento_normal_no_requiere_accion():
    tratamiento = calcular_tratamiento(7.4, 2.0, 50)
    assert len(tratamiento) == 1
    assert tratamiento[0]["producto"] == "Ninguno"


def test_calcular_tratamiento_combinado_ph_y_cloro_con_orden():
    tratamiento = calcular_tratamiento(6.8, 0.5, 20)

    assert len(tratamiento) == 2
    assert tratamiento[0]["producto"].lower().startswith("elevador de ph")
    assert tratamiento[1]["producto"] == "Cloro granulado"
    assert tratamiento[0]["instrucciones"].startswith("Paso 1:")
    assert tratamiento[1]["instrucciones"].startswith("Paso 2:")


def test_calcular_tratamiento_cloro_muy_alto():
    tratamiento = calcular_tratamiento(7.4, 6.0, 30)
    assert len(tratamiento) == 1
    assert "MUY alto" in tratamiento[0]["instrucciones"]
