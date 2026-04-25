# 🔀 GITFLOW — Guía de Referencia Rápida

**Objetivo:** Mantener `main` estable y limpia. `develop` es tu área de trabajo.

---

## 📋 FASE 1: Trabajar en develop (Desarrollo diario)

Siempre que agregues código o corrijas bugs, trabaja en **develop**:

```bash
# 1. Cambiarte a develop
git checkout develop

# 2. Descargar cambios más recientes (por si otra persona o tú en otro PC trabajaste)
git pull origin develop

# ... Aquí escribes/modificas tu código ...

# 3. Preparar todos los archivos que modificaste
git add .

# 4. Guardar cambios con un mensaje descriptivo
git commit -m "Descripción: Qué agregaste/arreglaste (ej: 'Implementar PoolSettings validación')"

# 5. Subir a GitHub en develop
git push origin develop
```

**Ejemplo de mensaje de commit recomendado:**
```bash
git commit -m "Task #66: Agregar PoolSettings con Pydantic v2 ConfigDict"
git commit -m "Fix: Eliminar warning deprecated Config class en models.py"
git commit -m "Test: Crear suite de pruebas para endpoints de pools"
```

---

## 🚀 FASE 2: Pasar a main (Cuando código está estable y probado)

Una vez que verificaste que todo funciona perfecto en **develop**, mueve a **main**:

```bash
# 1. Cambiarte a main
git checkout main

# 2. Bajar cambios recientes de main (por precaución)
git pull origin main

# 3. Fusionar (merge) todo lo de develop hacia main
git merge develop

# 4. Subir la versión estable a GitHub
git push origin main
```

**⚠️ Importante:** Solo haz merge a main cuando:
- ✅ Todos los tests PASEN (pytest con código verde)
- ✅ Hayas auditado el código
- ✅ La funcionalidad esté completamente implementada
- ✅ No haya warnings críticos

---

## ↩️ FASE 3: Volver a develop (Después de actualizar main)

Siempre que termines de pushar a main, regresa a **develop** inmediatamente:

```bash
git checkout develop
```

**⚠️ ADVERTENCIA:** Si no vuelves a develop, el próximo commit que hagas podría ir directo a main sin querer.

---

## 📊 Vista General del Flujo

```
┌─────────────────────────────────────────────────────────┐
│                    REPOSITORIO GITHUB                   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  main (ESTABLE)          develop (TRABAJO DIARIO)      │
│  ├─ Only merges           ├─ Commits regulares         │
│  ├─ Always tested         ├─ Testing constant          │
│  └─ Production ready      └─ Integration branch        │
│                                                         │
│  [Merge when ready]  ← ← ← [Pull requests / Merges]   │
│                                                         │
└─────────────────────────────────────────────────────────┘

Tu flujo diario:
1. git checkout develop      (Trabaja aquí siempre)
2. git pull origin develop   (Sincroniza)
3. ... código, tests, audit ...
4. git add . && git commit
5. git push origin develop
6. [Cuando está 100% listo] → git checkout main → git merge develop → git push main
7. git checkout develop      (Regresa aquí)
```

---

## ✅ Checklist Antes de Hacer Merge a Main

```bash
# 1. ¿Todos los tests pasan?
cd backend && pytest -v

# 2. ¿No hay warnings críticos?
python -m pytest tests/ --tb=short

# 3. ¿El código está auditado?
# (Revisa manualmente o usa: git diff origin/main...develop)

# 4. ¿La documentación está actualizada?
# (README, docstrings, CHANGELOG si aplica)

# Si todo ✅, entonces:
git checkout main
git pull origin main
git merge develop
git push origin main
git checkout develop  # ← No olvides este paso
```

---

## 🐛 Si Cometes un Error

```bash
# ¿Accidentalmente hiciste commit en main en lugar de develop?
# No panic. Usa:

# Deshace el último commit (pero guarda los cambios)
git reset --soft HEAD~1

# Ahora cambia a develop
git checkout develop

# Y repite el commit aquí
git add . && git commit -m "Tu mensaje"
git push origin develop
```

---

## 📝 Ejemplo Real: Implementar Task #66 Completa

```bash
# DÍA 1: Empezar a trabajar
git checkout develop
git pull origin develop
# ... escribes código PoolSettings ...
git add .
git commit -m "Task #66: Implementar esquema PoolSettings con 8 campos"
git push origin develop

# DÍA 1 TARDE: Crear tests
# ... escribes test_pools.py ...
git add .
git commit -m "Task #66: Agregar suite de pruebas para endpoints de pools"
git push origin develop

# DÍA 2: Verificar everything works
pytest tests/test_pools.py -v  # ✅ 5/5 PASSING
git add .
git commit -m "Fix: Eliminar warning Pydantic v2 en models.py"
git push origin develop

# DÍA 2 TARDE: Auditoria completada, todo perfecto
# → Hora de llevar a main
git checkout main
git pull origin main
git merge develop
git push origin main
# ✅ HITO 2 ENTREGADO A MAIN (Versión estable)

# Importante: Volver a develop
git checkout develop
```

---

## 🏆 Beneficios del GitFlow

| Aspecto | Beneficio |
|--------|-----------|
| **main limpia** | Siempre tienes una versión que funciona perfecta para mostrar/presentar |
| **develop estable** | Integras cambios sin romper la versión production |
| **Historial claro** | Puedes ver exactamente qué cambios fueron a producción |
| **Fácil revertir** | Si algo falla en main, es fácil volver atrás |
| **Trabajo en equipo** | Otros devs pueden hacer pull de develop sin romper main |

---

**Creado:** 2026-03-26 | **Proyecto:** CleanPool v1.0 | **Versión:** Hito 2
