# Readme arquitectura wordflow code

**Repositorio:** `maxbry123-commits/nct-core`  
**Rama:** `main`  
**Corte forense:** 2026-09-02  
**Documento relacionado, no fusionado:** [Readme arquitectura YAIWES](https://github.com/maxbry123-commits/agentes/blob/main/Readme%20arquitectura%20Yaiwes.md)

Este archivo contiene únicamente la arquitectura del motor Wordflow Code: recepción de tareas de programación, pipeline, motores, tools, ejecución aislada, pruebas, evidencia y cierre. El kernel de decisión YAIWES/TEAM permanece documentado por separado.

## 1. Fuentes

- [Índice raíz Wordflow Code](https://github.com/maxbry123-commits/nct-core/blob/main/Readme%20arquitectura%20ra%C3%ADz%20estructura%20wordflow%20code.md)
- [README base](https://github.com/maxbry123-commits/nct-core/blob/main/Wordflow%20Code/Readme/README.md)
- [SOURCE](https://github.com/maxbry123-commits/nct-core/blob/main/Wordflow%20Code/SOURCE.md)
- [CABLE](https://github.com/maxbry123-commits/nct-core/blob/main/Wordflow%20Code/skills/CABLE.md)
- [Método de trabajo](https://github.com/maxbry123-commits/nct-core/blob/main/Wordflow%20Code/skills/METODO-DE-TRABAJO.md)
- [ORIGIN_MAP](https://github.com/maxbry123-commits/nct-core/blob/main/code-programming-engine/ORIGIN_MAP.md)
- [Auditoría R6](https://github.com/maxbry123-commits/agentes/blob/main/AUDITORIA-RAIZ-R6-WORDFLOW-CODE-XRAY-2026-09-01.md)
- [Crazy Wall v4](https://github.com/maxbry123-commits/agentes/blob/main/FUENTE-GROK-YAIWES-CRAZY-WALL-v4.html)

## 2. Separación física y fuente real

```text
nct-core/main/
├── Wordflow Code/                  documentación, skills y cables
├── code-programming-engine/        pool mínimo y referencias
└── Core/                           vacío (.keep)

agentes/main/
├── extensions/wordflow/            runtime operativo canónico
├── extensions/wordflow/engine/
│   ├── code_path_runner.py         hot path
│   └── programming_pipeline.py
└── agente-yaiwes/
    └── code-programming-engine/
        └── code-path-execution/
            └── p01…p12             stubs pequeños
```

La raíz `nct-core/Wordflow Code` no contiene Python. El cuerpo ejecutable continúa en el repositorio `agentes`.

## 3. Huella física de NCT Core

### Wordflow Code

- 15 entradas.
- 12 archivos y 3 directorios.
- 8 Markdown.
- 0 Python y 0 tests Python.

### code-programming-engine

- 17 entradas.
- 12 archivos y 5 directorios.
- 2 Python, 9 Markdown y 0 tests.
- Los módulos Python son `instance_pool.py` y `programming_instance.py`.
- El resto son referencias SOURCE, catálogos, contratos y mapas de migración.

### Runtime canónico externo

`agentes/extensions/wordflow/` contiene 310 archivos Python y 134 tests. Esta sigue siendo la implementación real.

## 4. Arquitectura lógica de Wordflow Code

```text
extensions/
└── wordflow/
    ├── reception/
    │   ├── convert
    │   └── enchufe_gate
    ├── planner/
    │   ├── mission
    │   ├── goals
    │   └── task classification
    ├── engine/
    │   ├── code_path_runner.py
    │   ├── programming_pipeline.py
    │   ├── programming_kwargs.py
    │   ├── input_quality_bar.py
    │   ├── goal_lock.py
    │   ├── cognitive_loop.py
    │   └── checkpoint/state/recovery
    ├── motors/
    │   ├── kernel_ext
    │   └── external engines
    ├── codegen/
    ├── connectors/
    ├── contracts/
    ├── schemas/
    ├── standards/
    │   ├── forensic
    │   ├── dependency graph
    │   ├── evidence verifier
    │   └── test runner
    ├── state/
    ├── store/
    ├── policies/
    ├── accounts/
    └── tests/
```

## 5. Microflujo transversal

```text
solicitud de programación
→ reception.convert
→ input quality bar
→ goals + goal lock
→ mission
→ task classifier
→ programming pipeline
→ code_path_runner
→ motor o tool
→ cambios aislados
→ tests
→ evidence
→ auditoría forense
→ PASS o GAP
→ publish/deploy
```

## 6. Flujo de adquisición y reciclaje

```text
repositorio origen
→ licencia y commit
→ fingerprint
→ sandbox
→ localizar responsabilidad única
→ separar “decide” de “hace”
→ definir puerto
→ adaptar código ejecutor
→ tests de paridad
→ manifest origen-destino
→ registry
```

Wordflow Code ejecuta y verifica la adaptación. YAIWES decide si la pieza es capacidad, workflow o agente de pool.

## 7. Frontera con YAIWES

| Responsabilidad | Dueño |
|---|---|
| Decidir si una pieza debe usarse | YAIWES reasoning-kernel |
| Registrar capacidad/passport/ABI | YAIWES extension-kernel |
| Ejecutar modificación de código | Wordflow Code |
| Ejecutar tests y generar evidencia | Wordflow Code |
| Elegir workflow con política global | YAIWES |
| Hot path de programación | Wordflow Code |
| Aprobar cierre | Gobierno/forense YAIWES |

No se deben copiar los prompts Mythos dentro del motor de programación. Wordflow Code recibe una decisión y un contrato de tarea; no reemplaza el reasoning-kernel.

## 8. Grok Build: piezas que corresponden a Wordflow Code

Repositorio oficial:

https://github.com/xai-org/grok-build

Fuentes primarias:

- https://x.ai/news/grok-build-open-source
- https://github.com/xai-org/grok-build/blob/main/README.md
- https://github.com/xai-org/grok-build/blob/main/LICENSE
- https://github.com/xai-org/grok-build/tree/main/crates/codegen/xai-fast-worktree
- https://github.com/xai-org/grok-build/blob/main/crates/codegen/xai-grok-pager/docs/tutorial/06-worktrees.md
- https://github.com/xai-org/grok-build/blob/main/crates/codegen/xai-grok-pager/docs/user-guide/16-subagents.md

El repositorio es un workspace Rust bajo Apache-2.0. Contiene agente, tools, shell, TUI, skills, subagentes y worktrees.

### Qué extraer

| Código Grok Build | Destino Wordflow Code | Motivo |
|---|---|---|
| lectura/listado/búsqueda de archivos | tools/filesystem adapter | Capacidad determinista |
| edición y diff | codegen/edit adapter | Acción concreta |
| shell/terminal | tools/shell adapter | Ejecución aislable |
| xai-fast-worktree | engine/worktree isolation | Paralelismo sin pisar cambios |
| lifecycle de subagentes | engine pool adapter | Gestión de ejecutores |
| hooks pre/post tool | standards/gates | Evidencia y veto |
| skills loader | skill adapter | Descubrimiento de procedimientos |
| bucle de decisión Grok | No integrar | Duplicaría el kernel YAIWES |
| telemetría externa no controlada | No integrar | Superficie de fuga |

## 9. Control de seguridad obligatorio

Un incidente reportado públicamente en julio de 2026 indicó que una versión de Grok Build enviaba repositorios e historial Git a almacenamiento externo. Esto no prueba que el comportamiento siga activo hoy, pero obliga a tratar el código como no confiable hasta auditarlo.

Fuentes:

- https://thehackernews.com/2026/07/grok-build-uploads-entire-git.html
- https://www.theverge.com/ai-artificial-intelligence/965600/spacexai-grok-build-repository-upload

Gate de incorporación:

```text
sin secretos
→ filesystem temporal
→ red denegada por defecto
→ captura de egress
→ SBOM
→ secret scan
→ llamadas externas allowlist
→ tests de edición/shell
→ borrar sandbox
→ revisar evidencia
```

## 10. Poda y Ports & Adapters

Antes de copiar código:

1. Seleccionar una responsabilidad.
2. Mantener funciones que ejecutan acciones.
3. Excluir funciones que deciden el siguiente paso.
4. Definir un puerto estable de Wordflow.
5. Crear adaptador Rust→subproceso, FFI o servicio aislado.
6. No importar Grok Build directamente desde el kernel.
7. Versionar contrato, licencia, commit y SHA.
8. Añadir fallback e idempotencia.

## 11. Auditoría de lo existente

| Elemento | Estado |
|---|---|
| Wordflow Code en nct-core | Documental |
| Python bajo Wordflow Code | 0 |
| code-programming-engine nct | 2 Python; sin tests |
| runtime extensions/wordflow | Real, pero en otro repo |
| code_path_runner | Hot path real |
| p01–p11 | Existen, 108–109 bytes: stubs |
| p12 | 157 bytes: stub |
| pool de engines | Parcial |
| adapters OpenClaw/Hermes | Stubs |
| estado durable obligatorio | No demostrado |
| E2E hasta output consumed | No demostrado |
| paridad espejo NCT | No cerrada |

## 12. GAPS prioritarios

1. Elegir si NCT importará el runtime como paquete, submódulo, artefacto versionado o copia con SHA.
2. Evitar dos cuerpos editables del mismo motor.
3. Materializar p01–p12 o eliminarlos del claim operativo.
4. Añadir tests a `nct-core/code-programming-engine`.
5. Crear manifest de imports y versiones.
6. Implementar adapters reales del pool.
7. Hacer obligatorios mission_id, workspace_id, state y evidence.
8. Demostrar rollback e idempotencia.
9. Añadir pruebas de seguridad y egress para herramientas externas.
10. Probar solicitud→runner→tests→evidence→publish E2E.

## 13. Veredicto

Wordflow Code posee un runtime real y valioso, pero todavía no vive operativamente dentro de NCT Core. La raíz NCT es documental y el motor permanece distribuido. Estado: **PARCIAL / FAIL-CLOSED**.
