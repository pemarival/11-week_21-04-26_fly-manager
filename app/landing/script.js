const audiencePlaybooks = {
    arquitectura: {
        title: "Arquitectura / Data",
        description: "Empieza aqui para validar baseline, modelo vigente y siguiente frente sin reabrir decisiones ya cerradas.",
        focus: [
            "Canvas para ubicar capas, riesgos y continuidad.",
            "Roadmap senior para entender que ya se estabilizo.",
            "DDL maestro para confirmar el contrato fisico real."
        ],
        outcome: [
            "Diagnostico claro del baseline vigente.",
            "Decision de frente siguiente con una sola fuente de verdad.",
            "Handoff tecnico consistente para backend y frontend."
        ],
        links: [
            { label: "Abrir canvas arquitectonico", href: "../../architecture/canvas/canvas_arquitectura.html" },
            { label: "Abrir roadmap senior", href: "../../docs/planes/ROADMAP_ESTABILIZACION_DB_SENIOR.md" },
            { label: "Abrir DDL maestro", href: "../../db/ddl/modelo_postgresql.sql" }
        ],
        command: ".\\infra\\tools\\ejecutar_gate_pre_release.ps1 -SkipDocker",
        note: "Valida rapido el estado repo-local antes de abrir un nuevo frente de trabajo."
    },
    backend: {
        title: "Backend",
        description: "Usa este recorrido para aterrizar el baseline en servicios reales sin desarrollar sobre una percepcion desalineada.",
        focus: [
            "Cruzar capacidades funcionales con flujos reservation, sale, ticket e invoice.",
            "Revisar rebuild limpio y gate local antes de soportar una integracion seria.",
            "Tomar el baseline como contrato y no como referencia blanda."
        ],
        outcome: [
            "Servicios alineados al modelo fisico real.",
            "Menos retrabajo por divergencia entre codigo y baseline.",
            "Integraciones construidas sobre flujos ya validados."
        ],
        links: [
            { label: "Abrir capacidades funcionales", href: "../../reports/html/funcionalidades_sistema.html" },
            { label: "Abrir rebuild limpio", href: "../../infra/docker/recrear_instalacion_limpia.ps1" },
            { label: "Abrir gate local", href: "../../infra/tools/ejecutar_gate_pre_release.ps1" }
        ],
        command: ".\\infra\\tools\\ejecutar_gate_pre_release.ps1",
        note: "Usalo cuando necesites un corte completo antes de apoyar una integracion fuerte."
    },
    frontend: {
        title: "Frontend / Producto",
        description: "Este recorrido traduce el baseline a journeys, estados y pantallas sin inventar entidades fuera del dominio vigente.",
        focus: [
            "Entrar por el informe funcional para mapear modulos y capacidades.",
            "Cruzar cronograma y continuidad para separar estado actual y siguiente frente.",
            "Tomar reserva, check-in y boarding como flujo de experiencia base."
        ],
        outcome: [
            "Journeys consistentes con el dominio real.",
            "Backlog visual sustentado en flujos y dependencias existentes.",
            "Mejor alineacion entre producto, UI y backend."
        ],
        links: [
            { label: "Abrir informe funcional", href: "../../reports/html/funcionalidades_sistema.html" },
            { label: "Abrir cronograma", href: "../../reports/cronograma/cronograma_realizacion.html" },
            { label: "Abrir plan de continuidad", href: "../../docs/planes/PLAN_CONTINUIDAD_FASES_2026-03-19.md" }
        ],
        command: ".\\infra\\tools\\ejecutar_gate_pre_release.ps1 -SkipDocker",
        note: "Sirve para arrancar diseño y producto con una lectura vigente antes de bajar a UI."
    },
    operacion: {
        title: "QA / Operacion",
        description: "Concentra la salud del corte, la promocion remota y el unico pendiente administrativo que queda fuera del repo.",
        focus: [
            "Confirmar evidencia remota del workflow oficial en la rama aplicable.",
            "Validar el release guard repo-local antes de considerar promocion.",
            "Usar el runbook de GitHub cuando existan permisos administrativos."
        ],
        outcome: [
            "Promocion anclada a evidencia y no a intuicion.",
            "Menor riesgo de merge sin pipeline remoto en verde.",
            "Ruta clara para completar el pendiente externo."
        ],
        links: [
            { label: "Abrir evidencia pipeline CI", href: "../../docs/validacion/EVIDENCIA_PIPELINE_CI_REMOTO_2026-03-20.md" },
            { label: "Abrir release guard", href: "../../docs/validacion/POLITICA_PROMOCION_DB_RELEASE_GUARD.md" },
            { label: "Abrir runbook GitHub", href: "../../docs/validacion/RUNBOOK_BRANCH_PROTECTION_GITHUB.md" }
        ],
        command: ".\\infra\\tools\\validar_control_promocion_ci.ps1",
        note: "Es el chequeo mas directo para confirmar que el repo sigue alineado al flujo oficial."
    }
};

const journeyBlueprints = {
    reserva: {
        title: "Reserva y venta",
        description: "Es el flujo que convierte exploracion en ingreso y debe sentirse confiable, rapido y verificable desde busqueda hasta emision.",
        moment: "Cotizacion a cobro",
        persona: "Cliente comprador",
        tables: "reservation, sale, payment",
        states: [
            { name: "Busqueda", detail: "Explorar origen, destino, fecha, tarifa y disponibilidad." },
            { name: "Seleccion", detail: "Elegir vuelo, tarifa, asientos base y datos del pasajero." },
            { name: "Pago", detail: "Confirmar monto, metodo y resultado transaccional sin friccion." },
            { name: "Emision", detail: "Mostrar ticket, localizador, recibo e invoice trazable." }
        ],
        deliverables: [
            "Flujo completo de compra con estados claros y recuperables.",
            "Mensajes consistentes para validaciones, rechazo y exito.",
            "Resumen final que conecte reserva, ticket e invoice."
        ],
        backend: [
            "Persistencia ordenada entre reservation, sale, payment y ticket.",
            "Trazabilidad de transaccion y relacion con invoice.",
            "Estados idempotentes para reintento y confirmacion."
        ],
        qa: [
            "Caso feliz de compra completo con evidencia final.",
            "Fallas de cobro sin doble emision ni registros huerfanos.",
            "Chequeo de consistencia previo a promover cambios."
        ],
        links: [
            { label: "Abrir informe funcional", href: "../../reports/html/funcionalidades_sistema.html" },
            { label: "Abrir DDL maestro", href: "../../db/ddl/modelo_postgresql.sql" },
            { label: "Abrir gate local", href: "../../infra/tools/ejecutar_gate_pre_release.ps1" }
        ],
        command: ".\\infra\\tools\\ejecutar_gate_pre_release.ps1 -SkipDocker",
        note: "Usa este corte rapido antes de traducir el journey a backlog visual y tareas tecnicas."
    },
    checkin: {
        title: "Check-in y embarque",
        description: "Aqui la experiencia debe reducir ansiedad operativa: validar al pasajero, confirmar asiento y emitir un pase de abordar sin fricciones al final del viaje digital.",
        moment: "Confirmacion a abordaje",
        persona: "Pasajero en salida",
        tables: "check_in, boarding_pass, ticket_segment",
        states: [
            { name: "Validacion", detail: "Confirmar reserva activa, pasajero y ventana de check-in." },
            { name: "Asiento", detail: "Elegir o validar seat assignment con reglas visibles." },
            { name: "Equipaje", detail: "Registrar condiciones operativas y mensajes preventivos." },
            { name: "Boarding", detail: "Emitir pase y estado listo para control aeroportuario." }
        ],
        deliverables: [
            "Pantallas de estado con instrucciones claras y minima carga cognitiva.",
            "Fallbacks visibles cuando el pasajero no puede completar el flujo online.",
            "Resumen final orientado a aeropuerto: puerta, horario y pase."
        ],
        backend: [
            "Reglas consistentes entre ticket, segment y check_in.",
            "Actualizacion segura de asiento y emision de boarding_pass.",
            "Trazabilidad de eventos para soporte y operacion."
        ],
        qa: [
            "Cobertura de bloqueo por ventana cerrada o datos inconsistentes.",
            "Prueba de reasignacion de asiento sin romper boarding.",
            "Validacion del estado final antes de control operacional."
        ],
        links: [
            { label: "Abrir informe funcional", href: "../../reports/html/funcionalidades_sistema.html" },
            { label: "Abrir cronograma", href: "../../reports/cronograma/cronograma_realizacion.html" },
            { label: "Abrir evidencia admin bootstrap", href: "../../docs/validacion/EVIDENCIA_ADMIN_BOOTSTRAP_LOCAL_2026-03-20.md" }
        ],
        command: ".\\infra\\tools\\ejecutar_gate_pre_release.ps1 -SkipDocker",
        note: "Mantiene el contexto tecnico al dia antes de definir estados UI y reglas de operacion."
    },
    postventa: {
        title: "Postventa y recaudo",
        description: "Este journey concentra cambios, ajustes y devoluciones: el valor para el usuario esta en la trazabilidad y para el negocio en proteger el recaudo sin opacidad.",
        moment: "Ajuste a devolucion",
        persona: "Soporte comercial",
        tables: "payment, transaction, invoice",
        states: [
            { name: "Consulta", detail: "Ubicar venta, estado de cobro y comprobantes existentes." },
            { name: "Cambio", detail: "Aplicar reglas para ajustes, recotizacion o reemision." },
            { name: "Recaudo", detail: "Determinar saldo pendiente, aprobado o sujeto a refund." },
            { name: "Cierre", detail: "Dejar evidencia financiera y comunicacion verificable." }
        ],
        deliverables: [
            "Vista operativa que explique impacto economico antes de confirmar cambios.",
            "Mensajes claros para diferencias de tarifa, saldo y tiempos de devolucion.",
            "Historial visual para que soporte no dependa de trazas dispersas."
        ],
        backend: [
            "Relacion limpia entre transaccion, invoice y eventos de refund.",
            "Persistencia auditable de ajustes sin perder el rastro de la venta original.",
            "Reglas de recalculo consistentes antes de emitir nuevos documentos."
        ],
        qa: [
            "Escenarios de devolucion parcial y total con evidencia contable.",
            "Pruebas de cambios sin duplicar movimientos financieros.",
            "Corte documental y tecnico antes de promocionar un cambio sensible."
        ],
        links: [
            { label: "Abrir roadmap senior", href: "../../docs/planes/ROADMAP_ESTABILIZACION_DB_SENIOR.md" },
            { label: "Abrir politica de promocion", href: "../../docs/validacion/POLITICA_PROMOCION_DB_RELEASE_GUARD.md" },
            { label: "Abrir evidencia recovery", href: "../../docs/validacion/EVIDENCIA_RECUPERACION_LOCAL_2026-03-19.md" }
        ],
        command: ".\\infra\\tools\\validar_control_promocion_ci.ps1",
        note: "Usalo antes de tocar reglas sensibles de recaudo o postventa."
    },
    lealtad: {
        title: "Lealtad y cliente",
        description: "Este frente conecta perfil, categoria y beneficios. La experiencia correcta hace que el valor del programa se entienda y se use, no que quede escondido en tablas de soporte.",
        moment: "Perfil a beneficio",
        persona: "Cliente frecuente",
        tables: "customer, category, benefits",
        states: [
            { name: "Perfil", detail: "Mostrar identidad, contacto y estado de cuenta de forma confiable." },
            { name: "Categoria", detail: "Explicar nivel vigente, reglas y proyeccion del cliente." },
            { name: "Beneficios", detail: "Traducir ventajas a acciones visibles durante el journey." },
            { name: "Retencion", detail: "Usar historial y valor acumulado para fortalecer continuidad." }
        ],
        deliverables: [
            "Panel de cliente que conecte datos, categoria y beneficios sin ambiguedad.",
            "Estados visuales para beneficios disponibles, usados o pendientes.",
            "Narrativa de valor consistente entre producto, UX y programa de lealtad."
        ],
        backend: [
            "Fuente unica de verdad para customer, category y benefits.",
            "Lectura consistente del estado del cliente a lo largo de distintos modulos.",
            "Preparacion del dominio para personalizacion futura sin duplicar entidades."
        ],
        qa: [
            "Cobertura de cambios de categoria y reflejo correcto en beneficios.",
            "Validacion de consistencia entre perfil visible y datos persistidos.",
            "Chequeo de enlaces funcionales antes de abrir superficies de autoservicio."
        ],
        links: [
            { label: "Abrir capacidades funcionales", href: "../../reports/html/funcionalidades_sistema.html" },
            { label: "Abrir continuidad", href: "../../docs/planes/PLAN_CONTINUIDAD_FASES_2026-03-19.md" },
            { label: "Abrir canvas arquitectonico", href: "../../architecture/canvas/canvas_arquitectura.html" }
        ],
        command: ".\\infra\\tools\\ejecutar_gate_pre_release.ps1 -SkipDocker",
        note: "Te deja una lectura vigente antes de convertir el programa en experiencia visible."
    }
};

document.addEventListener("DOMContentLoaded", () => {
    initSmoothNavigation();
    initAudienceExperience();
    initJourneyExperience();
    initEvidenceFilters();
    initCopyButtons();
    initActiveNav();
});

function initSmoothNavigation() {
    document.querySelectorAll('a[href^="#"]').forEach((link) => {
        link.addEventListener("click", (event) => {
            const target = document.querySelector(link.getAttribute("href"));
            if (!target) {
                return;
            }

            event.preventDefault();
            const headerOffset = document.querySelector(".topbar")?.offsetHeight ?? 0;
            const top = target.getBoundingClientRect().top + window.scrollY - headerOffset - 18;
            window.scrollTo({ top, behavior: "smooth" });
        });
    });
}

function initAudienceExperience() {
    const tabs = [...document.querySelectorAll(".audience-tab")];
    const cards = [...document.querySelectorAll(".route-card[data-audience]")];
    const panel = document.getElementById("audience-brief");

    if (!tabs.length || !cards.length || !panel) {
        return;
    }

    const activate = (audience) => {
        const playbook = audiencePlaybooks[audience];
        if (!playbook) {
            return;
        }

        tabs.forEach((tab) => {
            const active = tab.dataset.audience === audience;
            tab.classList.toggle("active", active);
            tab.setAttribute("aria-selected", active ? "true" : "false");
        });

        cards.forEach((card) => {
            const active = card.dataset.audience === audience;
            card.classList.toggle("active", active);
            card.setAttribute("aria-pressed", active ? "true" : "false");
        });

        panel.innerHTML = `
            <div class="brief-head">
                <span class="brief-kicker">Recorrido activo</span>
                <h3>${playbook.title}</h3>
                <p>${playbook.description}</p>
            </div>
            <div class="brief-grid">
                <section class="brief-block">
                    <h4>Que revisar primero</h4>
                    <ul class="brief-list">${playbook.focus.map((item) => `<li>${item}</li>`).join("")}</ul>
                </section>
                <section class="brief-block">
                    <h4>Resultado esperado</h4>
                    <ul class="brief-list">${playbook.outcome.map((item) => `<li>${item}</li>`).join("")}</ul>
                </section>
            </div>
            <div class="brief-links">
                ${playbook.links.map((item) => `<a href="${item.href}">${item.label}</a>`).join("")}
            </div>
            <div class="brief-command">
                <span class="command-caption">Primer comando recomendado</span>
                <pre class="code-block"><code>${playbook.command}</code></pre>
                <div class="command-actions">
                    <button class="copy-btn" type="button" data-copy="${playbook.command}">Copiar comando</button>
                    <span class="command-note">${playbook.note}</span>
                </div>
            </div>
        `;
    };

    tabs.forEach((tab) => tab.addEventListener("click", () => activate(tab.dataset.audience)));
    cards.forEach((card) => {
        card.addEventListener("click", (event) => {
            if (event.target.closest("a")) {
                return;
            }
            activate(card.dataset.audience);
        });
        card.addEventListener("keydown", (event) => {
            if (event.key === "Enter" || event.key === " ") {
                event.preventDefault();
                activate(card.dataset.audience);
            }
        });
    });

    activate("arquitectura");
}

function initJourneyExperience() {
    const tabs = [...document.querySelectorAll(".journey-tab")];
    const panel = document.getElementById("journey-panel");

    if (!tabs.length || !panel) {
        return;
    }

    const activate = (journey) => {
        const blueprint = journeyBlueprints[journey];
        if (!blueprint) {
            return;
        }

        tabs.forEach((tab) => {
            const active = tab.dataset.journey === journey;
            tab.classList.toggle("active", active);
            tab.setAttribute("aria-selected", active ? "true" : "false");
        });

        panel.innerHTML = `
            <div class="journey-panel-head">
                <span class="journey-kicker">Journey activo</span>
                <h3>${blueprint.title}</h3>
                <p>${blueprint.description}</p>
            </div>
            <div class="journey-metrics">
                <article class="journey-stat">
                    <span>Momento critico</span>
                    <strong>${blueprint.moment}</strong>
                </article>
                <article class="journey-stat">
                    <span>Persona principal</span>
                    <strong>${blueprint.persona}</strong>
                </article>
                <article class="journey-stat">
                    <span>Tablas eje</span>
                    <strong>${blueprint.tables}</strong>
                </article>
            </div>
            <div class="journey-grid">
                <section class="journey-block">
                    <h4>Estados de experiencia</h4>
                    <div class="journey-state-grid">
                        ${blueprint.states.map((state) => `
                            <article class="state-card">
                                <strong>${state.name}</strong>
                                <p>${state.detail}</p>
                            </article>
                        `).join("")}
                    </div>
                </section>
                <section class="journey-block">
                    <h4>Que debe salir de diseno y producto</h4>
                    <ul class="journey-list">${blueprint.deliverables.map((item) => `<li>${item}</li>`).join("")}</ul>
                </section>
                <section class="journey-block">
                    <h4>Contrato backend y datos</h4>
                    <ul class="journey-list">${blueprint.backend.map((item) => `<li>${item}</li>`).join("")}</ul>
                </section>
                <section class="journey-block">
                    <h4>QA y liberacion</h4>
                    <ul class="journey-list">${blueprint.qa.map((item) => `<li>${item}</li>`).join("")}</ul>
                </section>
            </div>
            <div class="journey-footer">
                <div class="journey-links">
                    ${blueprint.links.map((item) => `<a href="${item.href}">${item.label}</a>`).join("")}
                </div>
                <div class="journey-command">
                    <span class="command-caption">Siguiente paso recomendado</span>
                    <pre class="code-block"><code>${blueprint.command}</code></pre>
                    <div class="command-actions">
                        <button class="copy-btn" type="button" data-copy="${blueprint.command}">Copiar comando</button>
                        <span class="command-note">${blueprint.note}</span>
                    </div>
                </div>
            </div>
        `;
    };

    tabs.forEach((tab) => tab.addEventListener("click", () => activate(tab.dataset.journey)));
    activate("reserva");
}

function initEvidenceFilters() {
    const chips = [...document.querySelectorAll(".filter-chip")];
    const cards = [...document.querySelectorAll(".evidence-card[data-tags]")];
    const status = document.querySelector("[data-filter-status]");

    if (!chips.length || !cards.length) {
        return;
    }

    const applyFilter = (filter) => {
        let visible = 0;

        chips.forEach((chip) => chip.classList.toggle("active", chip.dataset.filter === filter));
        cards.forEach((card) => {
            const tags = (card.dataset.tags || "").split(" ");
            const show = filter === "all" || tags.includes(filter);
            card.classList.toggle("is-hidden", !show);
            if (show) {
                visible += 1;
            }
        });

        if (status) {
            status.textContent = `Mostrando ${visible} grupos de artefactos`;
        }
    };

    chips.forEach((chip) => chip.addEventListener("click", () => applyFilter(chip.dataset.filter)));
    applyFilter("all");
}

function initCopyButtons() {
    document.addEventListener("click", async (event) => {
        const button = event.target.closest(".copy-btn");
        if (!button) {
            return;
        }

        try {
            await navigator.clipboard.writeText(button.dataset.copy || "");
            const label = button.textContent;
            button.textContent = "Copiado";
            button.classList.add("is-copied");
            window.setTimeout(() => {
                button.textContent = label;
                button.classList.remove("is-copied");
            }, 1500);
        } catch (error) {
            console.error("No se pudo copiar el comando", error);
        }
    });
}

function initActiveNav() {
    const links = [...document.querySelectorAll("[data-nav-link]")];
    const sections = links.map((link) => document.querySelector(link.getAttribute("href"))).filter(Boolean);

    if (!links.length || !sections.length || !("IntersectionObserver" in window)) {
        return;
    }

    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            if (!entry.isIntersecting) {
                return;
            }

            links.forEach((link) => link.classList.remove("active"));
            const activeLink = links.find((link) => link.getAttribute("href") === `#${entry.target.id}`);
            if (activeLink) {
                activeLink.classList.add("active");
            }
        });
    }, {
        threshold: 0.35,
        rootMargin: "-18% 0px -55% 0px"
    });

    sections.forEach((section) => observer.observe(section));
}
