# README — Arquitectura fusionada Wordflow Code · X-Ray

**Repositorio documental/destino:** `maxbry123-commits/nct-core`  
**Rama:** `main`  
**Fecha de corte:** 2026-09-01  
**Hallazgo principal:** la raíz `Wordflow Code/` contiene documentación y contratos; el runtime canónico continúa en `maxbry123-commits/agentes/extensions/wordflow`.

## 1. Fuentes fusionadas y trazabilidad

1. [Índice raíz NCT/Wordflow Code](https://github.com/maxbry123-commits/nct-core/blob/main/Readme%20arquitectura%20ra%C3%ADz%20estructura%20wordflow%20code.md)
2. [README base de Wordflow Code](https://github.com/maxbry123-commits/nct-core/blob/main/Wordflow%20Code/Readme/README.md)
3. [SOURCE — fuente operativa](https://github.com/maxbry123-commits/nct-core/blob/main/Wordflow%20Code/SOURCE.md)
4. [ORIGIN_MAP del motor](https://github.com/maxbry123-commits/nct-core/blob/main/code-programming-engine/ORIGIN_MAP.md)
5. [README del motor](https://github.com/maxbry123-commits/nct-core/blob/main/code-programming-engine/README.md)
6. [Cable del skill](https://github.com/maxbry123-commits/nct-core/blob/main/Wordflow%20Code/skills/CABLE.md)
7. [Método de trabajo](https://github.com/maxbry123-commits/nct-core/blob/main/Wordflow%20Code/skills/METODO-DE-TRABAJO.md)
8. [Skill operativo](https://github.com/maxbry123-commits/nct-core/blob/main/Wordflow%20Code/skills/SKILL.md)
9. [Hot path canónico](https://github.com/maxbry123-commits/agentes/blob/main/extensions/wordflow/engine/code_path_runner.py)
10. [Runtime canónico](https://github.com/maxbry123-commits/agentes/tree/main/extensions/wordflow)

## 2. Leyenda X-Ray

- **REAL:** código ejecutable existente.
- **PARCIAL:** cuerpo incompleto, espejo parcial o wiring no cerrado.
- **REF:** puntero a otra ruta/repositorio.
- **DOC:** documentación/contrato, no runtime.
- **FALTANTE:** arquitectura declarada sin cuerpo ejecutable comprobado.

## 3. Árbol físico localizado en nct-core — cuatro niveles

```text
main/
├── Readme arquitectura raíz estructura wordflow code.md
├── Wordflow Code/
│   ├── Readme/
│   │   ├── README.md                                  [DOC]
│   │   └── Readme1/
│   │       ├── CABLE-DEPLOY-ROUTER.md
│   │       ├── CABLE-PASO-CONTROL.md
│   │       └── CABLE-PLUGIN-ROUTER.md
│   ├── SOURCE.md                                      [REF]
│   └── skills/
│       ├── SKILL.md
│       ├── CABLE.md
│       ├── METODO-DE-TRABAJO.md
│       └── RULES.yaml
├── code-programming-engine/
│   ├── README.md
│   ├── ORIGIN_MAP.md
│   ├── engine-modules/
│   │   └── referencias/cuerpos parciales
│   ├── code-path-execution/
│   │   └── programación modular                       [PARCIAL]
│   ├── standards-forensic/
│   ├── schema-contracts-io/
│   ├── external-motor-bridge/
│   ├── multi-account-bridge/
│   ├── inbox-normalization/
│   └── module-tests/
├── Frontend code NCT/
├── skills agente nct/
├── Documentos proyectos nct/
├── Download code NCT/
├── NCT neuronas code turbo/
├── Desplegar nct/
├── Refactoria nct/
├── PIPELINE nct/
├── Método de trabajo nct/
├── Agente motores nct/
├── contracts/
├── scripts/
├── Core/
└── .github/
    └── workflows/
```

## 4. Arquitectura lógica completa declarada

```text
extensions/
└── wordflow/
    ├── reception/
    │   └── convert / normalización / handoff
    ├── planner/
    │   └── misión / goals / task planning
    ├── engine/
    │   ├── code_path_runner.py                        [HOT PATH REAL]
    │   ├── programming_pipeline.py                    [REAL]
    │   ├── programming_kwargs.py
    │   ├── input_quality_bar.py
    │   ├── skill_native_compiler.py
    │   ├── goal_lock.py
    │   └── cognitive_loop.py
    ├── motors/
    │   └── selección/ejecución de motores
    ├── codegen/
    │   └── generación y transformación
    ├── connectors/
    │   └── adaptadores externos
    ├── contracts/
    │   └── contratos de entrada/salida
    ├── schemas/
    │   └── validación estructurada
    ├── standards/
    │   ├── forensic controls
    │   ├── gap registry
    │   └── closure
    ├── state/
    │   └── estado de ejecución
    ├── store/
    │   └── persistencia/evidencia
    ├── policies/
    │   └── reglas y permisos
    ├── accounts/
    │   └── selección multi-cuenta
    ├── tests/
    │   └── unit/integration/e2e
    ├── component_catalog.json
    ├── connect_catalog.json
    ├── ficha.v2.json
    └── manifest.yaml
```

## 5. Microflujo transversal de Wordflow Code

```text
Solicitud
→ reception.convert
→ validación de entrada
→ goals + goal_lock
→ mission/planner
→ task_classifier
→ programming_pipeline
→ code_path_runner
→ motor/adapter seleccionado
→ generación o modificación
→ tests
→ evidence
→ auditoría de cuatro pasadas
→ cierre o GAP
→ deploy/publish
```

Método operacional documentado:

```text
P02 inbox Download code/Download N
→ P03 staging + copia + SHA-256 + plugin I/O
→ P04 mapeo src/config/scripts/tests + commit/push
→ P06 code_path_runner + evidence + deploy
```

## 6. Mapa raíz lógica → cuerpo real

| Pieza lógica en nct-core | Fuente canónica actual | Estado |
|---|---|---:|
| `engine-modules/code_path_runner.py` | `agentes/extensions/wordflow/engine/code_path_runner.py` | REF a REAL |
| `engine-modules/programming_pipeline.py` | `agentes/extensions/wordflow/engine/programming_pipeline.py` | REF a REAL |
| `engine-modules/programming_kwargs.py` | `agentes/extensions/wordflow/engine/programming_kwargs.py` | REF/PARCIAL |
| `engine-modules/input_quality_bar.py` | `agentes/extensions/wordflow/engine/input_quality_bar.py` | REF a REAL |
| `engine-modules/skill_native_compiler.py` | `agentes/extensions/wordflow/engine/skill_native_compiler.py` | REF a REAL |
| `engine-modules/goal_lock.py` | `agentes/extensions/wordflow/engine/goal_lock.py` | REF a REAL |
| `engine-modules/cognitive_loop.py` | `agentes/extensions/wordflow/engine/cognitive_loop.py` | REF/PARCIAL |
| ABI | `agentes/wordflow/abi.py` | REF |
| Pool/motor espejo | `nct-core/code-programming-engine` | PARCIAL |

## 7. Qué hay y qué falta

| Dimensión | Hay | Falta |
|---|---|---|
| Arquitectura documental | README, SOURCE, skills y cables | Un único documento fusionado — resuelto por este archivo |
| Runtime en `Wordflow Code/` | No: principalmente DOC/REF | Cuerpo ejecutable completo |
| Hot path | Existe en repo `agentes` | Migración/cutover con paridad |
| Motor espejo | Estructura y algunos cuerpos | Copia completa verificable por SHA |
| Recepción→evidencia | Piezas reales dispersas | Prueba E2E única |
| Catálogos | Declarados en arquitectura | Validación contra rutas reales |
| p01–p12 | Referencias documentales | Módulos ejecutables |
| Providers/motores | Puntos de extensión | Adaptadores reales, credenciales y failover probado |
| Auditoría forense | Standards y documentos | Controlador global integrado |
| Persistencia | Piezas parciales | Estado durable y GapRegistry persistente |
| Despliegue | Cables y workflows | Cierre behavior/output-consumed |

## 8. Auditoría forense de cuatro pasadas

1. **STRUCTURE:** la arquitectura lógica está descrita; la raíz física `Wordflow Code/` no contiene todo el runtime declarado.
2. **CONNECTIVITY:** los documentos apuntan correctamente al hot path de `agentes`, pero eso es un enlace entre repositorios, no una importación ejecutable automática.
3. **BEHAVIOR:** el comportamiento real depende del runtime de `agentes/extensions/wordflow`; no puede atribuirse como capacidad autónoma de `nct-core/Wordflow Code`.
4. **CLOSURE:** **PARCIAL / FAIL-CLOSED** hasta copiar o empaquetar cuerpos con SHA, corregir imports, ejecutar tests de paridad y verificar el flujo completo.

## 9. Regla de integración

No reescribir el hot path. Para trasladarlo a NCT:

```text
inventario origen
→ blob SHA
→ copia exacta
→ mapa de imports
→ adaptador
→ tests de paridad
→ ejecución E2E
→ evidencia
→ cutover autorizado
```

Hasta entonces, `agentes/extensions/wordflow` continúa siendo la fuente operativa y `nct-core/Wordflow Code` la raíz documental/de destino.
