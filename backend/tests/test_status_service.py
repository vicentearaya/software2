"""
test_status_service.py — Tests para el módulo status_service.py (Tarea #61)

Verifica que la función evaluar_aptitud_global() retorna correctamente
el estado de aptitud global de una piscina basándose en sus sensores.
"""

import pytest
from core.config_pool import EstadoAgua
from services.status_service import evaluar_aptitud_global


class TestAptitudApta:
    """
    Casos de prueba donde la piscina debería estar APTA
    (todos los sensores en OPTIMO o ADVERTENCIA)
    """

    def test_todos_sensores_optimo(self):
        """
        Test Case 1: Todos los sensores en estado OPTIMO.
        
        Expectativa:
        - piscina_apta = True
        - sensores_criticos = []
        - motivo contiene 'APTAS'
        """
        # Arrange
        evaluaciones = {
            "ph": {
                "valor": 7.5,
                "unidad": "pH",
                "estado": EstadoAgua.OPTIMO.value,
                "mensaje": "pH en rango óptimo."
            },
            "cloro": {
                "valor": 2.0,
                "unidad": "ppm",
                "estado": EstadoAgua.OPTIMO.value,
                "mensaje": "Cloro en nivel seguro."
            },
            "temperatura": {
                "valor": 26.0,
                "unidad": "°C",
                "estado": EstadoAgua.OPTIMO.value,
                "mensaje": "Temperatura dentro del rango confortable."
            },
            "conductividad": {
                "valor": 1500.0,
                "unidad": "µS/cm",
                "estado": EstadoAgua.OPTIMO.value,
                "mensaje": "Conductividad en nivel aceptable."
            }
        }

        # Act
        resultado = evaluar_aptitud_global(evaluaciones)

        # Assert
        assert resultado["piscina_apta"] is True, "Piscina debería estar APTA con todos sensores OPTIMO"
        assert resultado["sensores_criticos"] == [], "No debería haber sensores críticos"
        assert "APTAS" in resultado["motivo"], "Motivo debería indicar aptitud"

    def test_todos_sensores_advertencia(self):
        """
        Test Case 2: Todos los sensores en estado ADVERTENCIA.
        
        Expectativa:
        - piscina_apta = True (ADVERTENCIA no es CRITICO)
        - sensores_criticos = []
        """
        # Arrange
        evaluaciones = {
            "ph": {
                "valor": 7.0,
                "unidad": "pH",
                "estado": EstadoAgua.ADVERTENCIA.value,
                "mensaje": "pH en rango advertencia."
            },
            "cloro": {
                "valor": 0.8,
                "unidad": "ppm",
                "estado": EstadoAgua.ADVERTENCIA.value,
                "mensaje": "Cloro bajo."
            },
            "temperatura": {
                "valor": 22.0,
                "unidad": "°C",
                "estado": EstadoAgua.ADVERTENCIA.value,
                "mensaje": "Temperatura baja."
            },
            "conductividad": {
                "valor": 600.0,
                "unidad": "µS/cm",
                "estado": EstadoAgua.ADVERTENCIA.value,
                "mensaje": "Conductividad baja."
            }
        }

        # Act
        resultado = evaluar_aptitud_global(evaluaciones)

        # Assert
        assert resultado["piscina_apta"] is True, "Piscina debería estar APTA incluso con ADVERTENCIA"
        assert resultado["sensores_criticos"] == [], "ADVERTENCIA no es crítico"

    def test_mezcla_optimo_y_advertencia(self):
        """
        Test Case 3: Mezcla de sensores OPTIMO y ADVERTENCIA.
        
        Expectativa:
        - piscina_apta = True
        - sensores_criticos = []
        """
        # Arrange
        evaluaciones = {
            "ph": {
                "valor": 7.5,
                "unidad": "pH",
                "estado": EstadoAgua.OPTIMO.value,
                "mensaje": "pH óptimo."
            },
            "cloro": {
                "valor": 0.8,
                "unidad": "ppm",
                "estado": EstadoAgua.ADVERTENCIA.value,
                "mensaje": "Cloro bajo."
            },
            "temperatura": {
                "valor": 26.0,
                "unidad": "°C",
                "estado": EstadoAgua.OPTIMO.value,
                "mensaje": "Temperatura óptima."
            },
            "conductividad": {
                "valor": 1500.0,
                "unidad": "µS/cm",
                "estado": EstadoAgua.OPTIMO.value,
                "mensaje": "Conductividad óptima."
            }
        }

        # Act
        resultado = evaluar_aptitud_global(evaluaciones)

        # Assert
        assert resultado["piscina_apta"] is True, "Mezcla de OPTIMO/ADVERTENCIA debería estar APTA"
        assert resultado["sensores_criticos"] == []


class TestAptitudNoApta:
    """
    Casos de prueba donde la piscina debería estar NO APTA
    (al menos un sensor en CRITICO)
    """

    def test_cloro_critico(self):
        """
        Test Case 4: Cloro en estado CRITICO (bajo).
        
        Expectativa:
        - piscina_apta = False
        - sensores_criticos = ["cloro"]
        - motivo contiene 'NO APTA'
        """
        # Arrange
        evaluaciones = {
            "ph": {
                "valor": 7.5,
                "unidad": "pH",
                "estado": EstadoAgua.OPTIMO.value,
                "mensaje": "pH óptimo."
            },
            "cloro": {
                "valor": 0.1,
                "unidad": "ppm",
                "estado": EstadoAgua.CRITICO.value,
                "mensaje": "CLORO DEMASIADIO BAJO - PELIGRO BACTERIOLÓGICO."
            },
            "temperatura": {
                "valor": 26.0,
                "unidad": "°C",
                "estado": EstadoAgua.OPTIMO.value,
                "mensaje": "Temperatura óptima."
            },
            "conductividad": {
                "valor": 1500.0,
                "unidad": "µS/cm",
                "estado": EstadoAgua.OPTIMO.value,
                "mensaje": "Conductividad óptima."
            }
        }

        # Act
        resultado = evaluar_aptitud_global(evaluaciones)

        # Assert
        assert resultado["piscina_apta"] is False, "Piscina NO APTA si cloro es CRITICO"
        assert "cloro" in resultado["sensores_criticos"], "Cloro debe estar en sensores críticos"
        assert len(resultado["sensores_criticos"]) == 1, "Solo cloro está crítico"
        assert "NO APTA" in resultado["motivo"], "Motivo debe advertir sobre NO APTA"

    def test_multiples_sensores_criticos(self):
        """
        Test Case 5: Múltiples sensores en estado CRITICO.
        
        Expectativa:
        - piscina_apta = False
        - sensores_criticos incluye "pH" y "temperatura"
        """
        # Arrange
        evaluaciones = {
            "ph": {
                "valor": 5.0,
                "unidad": "pH",
                "estado": EstadoAgua.CRITICO.value,
                "mensaje": "pH CRITICO bajo."
            },
            "cloro": {
                "valor": 2.0,
                "unidad": "ppm",
                "estado": EstadoAgua.OPTIMO.value,
                "mensaje": "Cloro óptimo."
            },
            "temperatura": {
                "valor": 38.0,
                "unidad": "°C",
                "estado": EstadoAgua.CRITICO.value,
                "mensaje": "Temperatura CRITICO alta (riesgo bacteriano)."
            },
            "conductividad": {
                "valor": 1500.0,
                "unidad": "µS/cm",
                "estado": EstadoAgua.OPTIMO.value,
                "mensaje": "Conductividad óptima."
            }
        }

        # Act
        resultado = evaluar_aptitud_global(evaluaciones)

        # Assert
        assert resultado["piscina_apta"] is False, "NO APTA con sensores críticos"
        assert len(resultado["sensores_criticos"]) == 2, "Debería haber 2 sensores críticos"
        assert "ph" in resultado["sensores_criticos"], "pH está crítico"
        assert "temperatura" in resultado["sensores_criticos"], "Temperatura está crítica"

    def test_sensor_offline_tratado_como_critico(self):
        """
        Test Case 6: Sensor offline (valor None) se trata como CRITICO por seguridad.
        
        Expectativa:
        - piscina_apta = False
        - sensores_criticos incluye el sensor offline
        """
        # Arrange
        evaluaciones = {
            "ph": {
                "valor": 7.5,
                "unidad": "pH",
                "estado": EstadoAgua.OPTIMO.value,
                "mensaje": "pH óptimo."
            },
            "cloro": None,  # Sensor offline
            "temperatura": {
                "valor": 26.0,
                "unidad": "°C",
                "estado": EstadoAgua.OPTIMO.value,
                "mensaje": "Temperatura óptima."
            },
            "conductividad": {
                "valor": 1500.0,
                "unidad": "µS/cm",
                "estado": EstadoAgua.OPTIMO.value,
                "mensaje": "Conductividad óptima."
            }
        }

        # Act
        resultado = evaluar_aptitud_global(evaluaciones)

        # Assert
        assert resultado["piscina_apta"] is False, "NO APTA si hay sensor offline"
        assert "cloro" in resultado["sensores_criticos"], "Sensor offline tratado como crítico"
        assert "cloro" in resultado["motivo"].lower()


class TestCasosEdge:
    """Casos edge y manejo de errores"""

    def test_evaluaciones_vacio(self):
        """
        Test Case 7: Diccionario de evaluaciones vacío.
        
        Expectativa:
        - piscina_apta = False (por seguridad)
        - sensores_criticos = []
        - motivo índica falta de datos
        """
        # Arrange
        evaluaciones = {}

        # Act
        resultado = evaluar_aptitud_global(evaluaciones)

        # Assert
        assert resultado["piscina_apta"] is False, "Sin datos → NO APTA por seguridad"
        assert "No hay datos" in resultado["motivo"], "Motivo debe indicar falta de datos"

    def test_uso_enum_directo(self):
        """
        Test Case 8: Uso de Enum directamente (no string).
        
        Expectativa: Debería funcionar con EstadoAgua.CRITICO directamente
        """
        # Arrange
        evaluaciones = {
            "ph": {
                "valor": 7.5,
                "unidad": "pH",
                "estado": EstadoAgua.OPTIMO,  # Enum, no string
                "mensaje": "pH óptimo."
            },
            "cloro": {
                "valor": 0.1,
                "unidad": "ppm",
                "estado": EstadoAgua.CRITICO,  # Enum, no string
                "mensaje": "CLORO CRITICO bajo."
            },
            "temperatura": {
                "valor": 26.0,
                "unidad": "°C",
                "estado": EstadoAgua.OPTIMO,
                "mensaje": "Temperatura óptima."
            },
            "conductividad": {
                "valor": 1500.0,
                "unidad": "µS/cm",
                "estado": EstadoAgua.OPTIMO,
                "mensaje": "Conductividad óptima."
            }
        }

        # Act
        resultado = evaluar_aptitud_global(evaluaciones)

        # Assert
        assert resultado["piscina_apta"] is False, "Debe detectar CRITICO incluso con Enum"
        assert "cloro" in resultado["sensores_criticos"]
