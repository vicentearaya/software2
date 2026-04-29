import pytest

from core.config_pool import EstadoAgua, evaluar_sensor


@pytest.mark.parametrize(
    "clave,valor,estado_esperado,mensaje_fragmento",
    [
        ("ph", 7.5, EstadoAgua.OPTIMO, "óptimo"),
        ("ph", 6.9, EstadoAgua.ADVERTENCIA, "bajo"),
        ("ph", 8.5, EstadoAgua.CRITICO, "alto"),
        ("cloro", 2.0, EstadoAgua.OPTIMO, "seguro"),
        ("temperatura", 22.0, EstadoAgua.ADVERTENCIA, "baja"),
        ("conductividad", 3500.0, EstadoAgua.CRITICO, "alta"),
    ],
)
def test_evaluar_sensor_estados(clave, valor, estado_esperado, mensaje_fragmento):
    resultado = evaluar_sensor(clave, valor)

    assert resultado["valor"] == valor
    assert resultado["estado"] == estado_esperado
    assert mensaje_fragmento.lower() in resultado["mensaje"].lower()


def test_evaluar_sensor_clave_invalida():
    with pytest.raises(ValueError, match="no reconocido"):
        evaluar_sensor("oxigeno", 8.0)
