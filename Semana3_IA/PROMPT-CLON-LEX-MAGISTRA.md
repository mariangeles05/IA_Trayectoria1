# PROMPT — Construir "Lex Magistra" (plataforma web de firma de abogados) de 0 a 100

---

Eres un ingeniero full-stack senior y director de arte. Vas a construir desde cero una **plataforma web real** (no una landing estática) para una firma de abogados multidisciplinaria en Colombia llamada **Lex Magistra** ("Abogados en Colombia"). Trabaja por fases, en orden. No pases a la siguiente fase hasta que la actual cumpla su "Listo cuando" y su comando "Verificar" dé verde. Pega la salida de cada verificación como prueba.

Todo el texto visible va en **español de Colombia**, con tuteo, claro y sin jerga. No inventes abogados, reseñas, cifras ni casos de éxito: si no hay datos reales, la sección muestra un estado vacío elegante.

## 0. Reglas generales (aplican siempre)

- TypeScript estricto. Funciones chicas, nombres claros, errores manejados.
- HTML semántico, labels en todos los campos, foco visible, `aria-*` solo cuando hace falta. Contraste AA mínimo.
- Mobile-first. Cada pantalla se revisa a 390 px y a 1280 px.
- Toda escritura pasa por **Server Actions** validadas con **zod**. Toda lectura, por funciones en `lib/data.ts`.
- Seguridad en **3 capas**: middleware → verificación en servidor (layouts y Server Actions) → **RLS + triggers** en Postgres.
- Nunca pongas llaves secretas en el cliente. La `service_role` solo la usan scripts locales.
- No agregues dependencias que no estén en la lista de la Fase 1 sin justificarlo.
- Estados en todo: hover, focus, active, disabled, loading, empty y error.
- Los formularios **no pierden lo escrito** cuando hay un error (ver el hook de la Fase 6).

## 1. Stack y estructura

**Dependencias exactas (o la versión estable más reciente compatible):**

- `next@15.5` (App Router, Turbopack), `react@19.1`, `react-dom@19.1`
- `@supabase/ssr`, `@supabase/supabase-js`
- `gsap@3` (ScrollTrigger y SplitText), `lenis`
- `lucide-react`, `zod@4`, `server-only`
- Dev: `tailwindcss@4`, `@tailwindcss/postcss`, `typescript@5`, `eslint@9` y `eslint-config-next`, `tsx`, `supabase` (CLI), `@electric-sql/pglite` (para probar RLS sin servidor)

**Scripts de `package.json`:**

```json
"dev": "next dev --turbopack",
"build": "next build --turbopack",
"start": "next start",
"lint": "eslint",
"typecheck": "tsc --noEmit",
"gen:seed": "tsx scripts/gen-seed.ts",
"test:db": "tsx scripts/test-db.ts",
"make-admin": "tsx --env-file=.env.local scripts/make-admin.ts",
"db:start": "supabase start",
"db:stop": "supabase stop",
"db:reset": "supabase db reset",
"db:env": "tsx scripts/local-env.ts"
```

**Árbol de carpetas (créalo así):**

```
app/
  layout.tsx            (fuentes, metadata, script BOOT, DemoSwitcher solo en dev)
  globals.css           (tokens, @layer components)
  icon.svg  not-found.tsx  robots.ts  sitemap.ts
  auth/callback/route.ts
  (site)/               layout (Nav + Footer + WhatsAppFab), template.tsx (transición), page.tsx (home)
    abogados/(lista)/page.tsx + loading.tsx, abogados/[id]/page.tsx + not-found.tsx, error.tsx
    especialidades/(lista)/page.tsx + loading.tsx, especialidades/[slug]/page.tsx + not-found.tsx, error.tsx
    opiniones/page.tsx + loading + error
    nosotros/page.tsx   contacto/page.tsx   legal/[doc]/page.tsx
  (auth)/               layout, ingresar, registro, recuperar, restablecer
  panel/                layout (Shell), page, nueva-solicitud, solicitudes, solicitudes/[id],
                        resenas, resenas/nueva, perfil, abogados, asignadas (rol abogado), loading/error
  admin/                layout (Shell admin), page (resumen), solicitudes, solicitudes/[id], resenas,
                        mensajes, abogados, abogados/[id], firmas, especialidades, especialidades/[id],
                        usuarios, configuracion, loading/error
components/
  motion/   MotionProvider, SplitHeading, Magnetic, Cursor, LoopVideo
  landing/  Preloader, Hero, Marquee, SpecialtiesRail, Orientador, Process, Rights, FirstConsult,
            Counter, ContactForm, Sections (Intro, Team, WhyUs, ReviewsSection, Faq, ContactSection)
  site/     Nav, Footer, FooterClose, LawyerCard, Monogram, MotionToggle, NotFoundBlock, PageHeader,
            RouteStates, SpecialtyIcon, Stars, WhatsAppFab
  auth/     AuthForms, ConfigNotice
  panel/    Shell, RequestWizard, CaseTimeline, AttachmentsPanel, ProfileForm, ReviewForm, StatusBadge, ScreenStates
  admin/    LawyerForm, FirmForm, SpecialtyForm, SettingsForm, ConfirmButton, stats.ts
  ui/       Form, FormSection, Panel, States, ImageDrop, Attachments, useFormAction.ts
  dev/      DemoSwitcher
lib/
  supabase/ client.ts, server.ts, use-nav-session.ts
  actions/  public.ts, auth.ts, panel.ts, admin.ts, uploads.ts, demo.ts
  content/  specialties.ts, specialty-details.ts, legal.ts, settings.ts, credits.ts, generated-images.ts
  data.ts  types.ts  validation.ts  rate-limit.ts  safe-redirect.ts  storage-url.ts
  whatsapp.ts  attachments.ts  demo-accounts.ts
scripts/  gen-seed.ts, test-db.ts, make-admin.ts, local-env.ts
supabase/ config.toml, seed.sql, migrations/
middleware.ts  next.config.ts  .env.example  README.md
public/img/  public/video/
```

**`.env.example`:**

```
NEXT_PUBLIC_SUPABASE_URL=https://TU-PROYECTO.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=
NEXT_PUBLIC_SITE_URL=http://localhost:3000
SUPABASE_SERVICE_ROLE_KEY=        # solo scripts locales
DEMO_SWITCHER=                    # 1 = barra de cuentas de prueba (solo con Supabase local)
DEMO_PASSWORD=
```

`.gitignore` debe cubrir `.env*.local` **antes** de crear el `.env.local`.

- **Listo cuando:** el proyecto arranca y muestra una página en blanco con las fuentes cargadas.
- **Verificar:** `npm run typecheck && npm run lint && npm run build`

## 2. Dirección visual (decídela ANTES de escribir UI)

**Concepto:** "el nombre como monumento". La firma se presenta como la arquitectura de la justicia colombiana: sobria, pesada, nocturna, con titulares serif enormes y fotografía de edificios judiciales en duotono navy.

**Paleta estricta (tokens CSS en `:root`, nada de hex sueltos):**

```css
--steel:#61696c; --navy:#212b41; --carbon:#1a1b1d; --mist:#b8c2c9; --graphite:#1e2127; --white:#fff;
--ground:var(--carbon); --surface:var(--graphite); --field:var(--navy);
--ink:var(--white); --ink-soft:var(--mist);   /* 10:1 sobre carbón */
--accent:var(--mist); --muted:var(--steel);   /* steel solo decorativo o texto ≥24px */
--danger:#e8a3a3; --danger-bg:#3a2326; --wa:#25d366;  /* verde WhatsApp SOLO en su botón */
--ease-out:cubic-bezier(0.23,1,0.32,1); --ease-in-out:cubic-bezier(0.77,0,0.175,1);
--dur-fast:160ms; --dur:240ms;
--margin:clamp(16px,2.2vw,32px); --section-gap:clamp(72px,9vw,140px);
```

Exponlos a Tailwind v4 con `@theme inline` (`--color-navy`, `--color-ink-soft`, etc., más `--font-sans` y `--font-display`). Usa `color-scheme: dark`, un fondo explícito en `html` y `body`, selección mist sobre navy y `:focus-visible` con un outline mist de 2 px y 3 px de separación.

**Tipografía:** `Instrument Serif` (400) para los display y `Geist` para el texto, las dos con `next/font/google` y `display: swap`. La clase `.font-display` lleva `letter-spacing: -0.03em` y `line-height: 0.95`. El cuerpo va a 17 px con `line-height: 1.6`. **Prohibido usar Inter, Roboto o Arial.**

**Prohibido:** degradados morado→azul, tarjetas dentro de tarjetas, texto gris sobre color, rebotes, esquinas muy redondeadas (los botones son rectos, `border-radius: 0`, con `min-height: 48px` y `:active { scale(.97) }`), emojis decorativos, etiquetas pequeñas encima de cada título, filas de 3 tarjetas con ícono.

**Clases propias:** todas dentro de `@layer components`. Si no, pisan las utilidades de Tailwind (pasó: la foto del hero quedó con altura 0).

**Fotografía:** arquitectura judicial colombiana de Wikimedia Commons con licencia CC (Palacio de Justicia, Capitolio Nacional, Plaza de Bolívar, La Candelaria, columnas corintias, una escalera), más 4 fotos propias (expediente, Candelaria con lluvia, biblioteca de derecho, mano firmando). Todas llevan la clase `.duotone` en navy. Los créditos (autor, licencia y enlace) se guardan en `lib/content/credits.ts` y se muestran en el pie. Hay un video corto en bucle (`public/video/web-exp.webm` y `.mp4`) que se carga perezoso.

**Motion (reglas):** usa ease-out `cubic-bezier(0.23,1,0.32,1)` (en GSAP, `expo.out`), entre 150 y 300 ms en la UI. Las entradas animan solo opacidad y transform. Nunca animes anchos ni altos.

- Las animaciones están **activas por defecto**, pero hay un interruptor "Reducir movimiento" en el pie y en el menú móvil, que se guarda en `localStorage` (`motion = reduce | full`). Si el visitante nunca eligió, se respeta `prefers-reduced-motion`.
- Pon un **script BOOT inline** en el `<head>` que haga esto:
  1. Agregar `.js` a `<html>`.
  2. Leer la preferencia de movimiento y poner `.reduce-motion` si corresponde.
  3. Marcar `.no-intro` si ya se vio la intro en la sesión (`sessionStorage`).
  4. Si `window.__motionReady` no llega en 2,5 s, agregar `.js-fallback` para que TODO se vea aunque falle el JS.
- Los elementos `[data-split]`, `[data-reveal]` y `[data-media]` arrancan ocultos solo bajo `.js` y se muestran forzados bajo `.js-fallback`.

- **Listo cuando:** existe `globals.css` con los tokens, las clases base (`.frame`, `.btn`, `.font-display`, `.duotone`, preloader y Lenis) y una página de prueba que se ve bien en 390 y 1280 px.

## 3. Base de datos (Supabase + RLS desde el primer commit)

Crea `supabase/migrations/<fecha>_init.sql`.

**Tipos:**

- `user_role`: `client | lawyer | admin`
- `request_status`: `pendiente | en_revision | contactado | cerrado | rechazado`
- `review_status`: `pendiente | aprobada | rechazada`

**Tablas (con checks de longitud en todos los textos):**

- `profiles`: `id` (FK `auth.users`, cascade), `full_name ≤120`, `phone ≤30`, `document_id ≤30`, `city ≤80`, `role` (default `client`), `data_consent_at`, `avatar_url`, timestamps.
- `firms`: `name 2–120`, `description ≤2000`, `city`, `website`, `is_active`.
- `specialties`: `slug` único que cumple `^[a-z0-9-]{2,60}$`, `name`, `short_name`, `icon`, `summary`, `description`, `problems text[]`, `services text[]`, `faqs jsonb` (un array), `sort_order`, `is_active`.
- `lawyers`: `profile_id` (único, FK `profiles`, set null), `firm_id`, `full_name`, `title`, `photo_url`, `bio`, `experience`, `education` (cada uno ≤4000), `services text[]`, `years_experience 0–70`, `professional_card`, `availability`, `accepts_consultations`, `is_active`.
- `lawyer_specialties`: PK (`lawyer_id`, `specialty_id`).
- `consultation_requests`: `client_id`, `specialty_id` (restrict), `lawyer_id` y `firm_id` (opcionales), `subject 5–140`, `description 20–4000`, `preferred_contact` (`whatsapp | llamada | correo`), `status`, `admin_notes`, `data_consent` (con `check = true`), `data_consent_at`.
- `request_status_history`: `request_id`, `status`, `note`, `changed_by`, `created_at`.
- `reviews`: `author_id`, `lawyer_id` y `specialty_id` (opcionales), `rating 1–5`, `comment 20–1500`, `public_name 2–80`, `show_name`, `status`, `moderated_by`, `moderated_at`.
- `site_settings`: `key` que cumple `^[a-z0-9_]{2,60}$` y `value text`.
- `contact_messages`: `full_name`, `email` (regex), `phone`, `specialty_id`, `message 10–3000`, `data_consent = true`, `handled`.
- `request_attachments`: `request_id`, `uploaded_by`, `path` único que empieza por `<request_id>/`, `name ≤160`, `mime` (jpeg, png, webp o pdf), `size ≤10 MB`.
- Índices: en cada FK y en `(client_id, created_at desc)`, `status` y `(status, created_at desc)` de las reseñas.

**Funciones (todas `security definer set search_path = ''`):**

- `current_role_name()` e `is_admin()`. Evitan la recursión de RLS sobre `profiles`.
- `touch_updated_at()`: un trigger por tabla.
- `handle_new_user()`: un trigger after insert en `auth.users` que crea el `profile` con `full_name` y `data_consent_at` tomados de `raw_user_meta_data`.
- `guard_profile_role()`: solo un admin cambia el `role`.
- `guard_request_update()`: si quien edita no es admin, no puede tocar `client_id`, `admin_notes` ni `data_consent_at`. El estado lo cambia solo el **abogado asignado** (`lawyers.profile_id = auth.uid()`), o el cliente para pasar de `pendiente` a `cerrado` (cancelar). Todo cambio de estado se inserta en el historial.
- `request_initial_history()`: inserta "Solicitud registrada" al crear la solicitud.
- `guard_review_write()`: si quien escribe no es admin, en el INSERT se fuerza `status = pendiente` y se limpia la moderación, y se le prohíbe el UPDATE. Si es admin y cambia el estado, se guardan `moderated_by` y `moderated_at`.
- `limit_request_attachments()`: máximo 5 adjuntos por solicitud, con `pg_advisory_xact_lock` para que dos subidas simultáneas no pasen el límite.
- `set_own_lawyer_photo(p_url)`: el abogado vinculado cambia su propia foto. Valida la URL con un **patrón anclado** `^https?://host(:port)?/storage/v1/object/public/lawyer-photos/<lawyer_id>/<nombre>.(jpg|jpeg|png|webp)(\?v=n)?$` y sin `..`. Revoca execute a `public` y `anon`.
- `admin_stats()`: devuelve JSON con clientes, abogados activos, solicitudes totales y abiertas, reseñas pendientes, mensajes sin atender y solicitudes por especialidad. Lanza un error si no es admin. Revoca execute a `anon`.
- La vista `review_stats` (con `security_invoker`) da el total y el promedio de las reseñas aprobadas.

**RLS habilitado en TODAS las tablas:**

- Lectura pública (anon y authenticated): `firms`, `specialties`, `lawyers`, `lawyer_specialties`, `site_settings` y las reseñas **aprobadas**. Escritura en esas tablas: solo admin.
- `profiles`: cada uno ve y edita el suyo. Un abogado ve los perfiles de sus clientes asignados. El admin ve todo.
- `consultation_requests`: el cliente ve y crea las suyas, el abogado ve las asignadas y el admin ve todo. Borrar: solo admin.
- `request_status_history`: lo ve quien puede ver la solicitud.
- `contact_messages`: anon y authenticated insertan. El admin lee y marca como atendido.
- `request_attachments`: lo ve quien ve la solicitud. Solo el cliente dueño sube y borra, y solo mientras la solicitud está abierta (no `cerrado` ni `rechazado`).
- El check de `profiles.avatar_url` usa el mismo patrón anclado sobre `avatars/<id>/`.

**Storage (3 buckets):**

- `lawyer-photos`: público, 3 MB, imágenes. Escribe el admin, o el propio abogado en `lawyer-photos/<su lawyer_id>/`.
- `avatars`: público, 2 MB. Cada usuario escribe solo en `avatars/<uid>/`.
- `request-files`: **privado**, 10 MB, imágenes o PDF, en la carpeta `<request_id>/`. Las mismas reglas que la tabla. La descarga se hace con una URL firmada.

**`supabase/seed.sql`:** se genera con `scripts/gen-seed.ts` a partir de `lib/content/*`. Incluye las 6 especialidades y los `site_settings` por defecto. **No** incluye abogados ni reseñas de ejemplo.

**`scripts/test-db.ts`:** monta un Postgres en memoria con PGlite, simula `auth.uid()` y los roles `anon` y `authenticated`, aplica todas las migraciones y prueba al menos 35 reglas: un cliente no ve solicitudes ajenas, un cliente no se cambia el rol, un cliente no cambia el estado (salvo cancelar estando pendiente), el abogado asignado sí lo cambia, el no asignado no, una reseña nace siempre pendiente, anon no ve reseñas pendientes, el límite de 5 adjuntos, una URL de foto con otro dominio se rechaza, `admin_stats` falla para quien no es admin, etc.

- **Listo cuando:** la migración aplica limpia y pasan todas las pruebas.
- **Verificar:** `npm run test:db` (debe dar N/N ✓, 0 ✗)

## 4. Contenido (`lib/content/*`) — el sitio funciona SIN base de datos

`lib/data.ts` lee de Supabase y, si no hay configuración o la consulta falla, **cae a este contenido de respaldo**. El sitio público nunca se rompe.

**`specialties.ts`:** 6 áreas, cada una con slug, nombre, nombre corto, ícono lucide, resumen, descripción, problemas típicos, servicios y FAQs:

| slug | nombre | corto | ícono |
|---|---|---|---|
| derecho-de-transito | Derecho de tránsito | Tránsito | car |
| derecho-penal | Derecho penal | Penal | gavel |
| derecho-economico-y-financiero | Derecho económico y financiero | Económico y financiero | landmark |
| derecho-digital-y-tecnologico | Derecho digital y tecnológico | Digital y tecnológico | shield |
| derecho-migratorio-y-visas | Derecho migratorio y asesoría de visas | Migratorio y visas | plane |
| proteccion-del-buen-nombre | Protección del buen nombre y reputación | Buen nombre | badge-check |

`specialty-details.ts` amplía cada área para su página propia.

**`settings.ts` (valores por defecto, editables en `/admin/configuracion`):** `firm_name "Lex Magistra"`, `firm_tagline "Abogados en Colombia"`, `whatsapp_number ""`, `whatsapp_message "Hola, quisiera orientación sobre un asunto legal."`, `contact_email`, `contact_phone`, `address`, `city "Bogotá, Colombia"`, `hours "Lunes a viernes, 8:00 a. m. – 6:00 p. m."`, `instagram_url`, `facebook_url`, `linkedin_url` y `about_text`. El `about_text` dice que la firma escucha el caso completo, explica el derecho en palabras claras, arma una estrategia antes de actuar y trabaja con confidencialidad, con honorarios por escrito y sin prometer resultados.

**`legal.ts`:** 3 documentos que se ven en `/legal/[doc]`: `tratamiento-datos` (Política de tratamiento de datos personales, Ley 1581 de 2012), `privacidad` (aviso de privacidad) y `terminos` (términos y condiciones). Agrega un aviso visible para que un abogado los revise antes de publicar.

**`lib/whatsapp.ts`:** `whatsappUrl(numero, mensaje)` arma un enlace `wa.me` solo si el número tiene entre 8 y 15 dígitos. Si no, devuelve `null` y el botón flotante no aparece.

## 5. Sitio público (home y páginas)

**Home (`app/(site)/page.tsx`, `revalidate = 300`), en este orden:**

1. **Preloader**: solo con CSS. Se dibuja el monograma SVG de la firma, aparece el nombre y sube la cortina. Sale solo en la primera visita de la sesión y se retira aunque falle el JS.
2. **Hero**: el título queda **fijo** en el centro, "Defendemos tus derechos. / Construimos soluciones." (serif, `clamp(64px,8.2vw,150px)` en desktop), mientras pasan una tras otra 5 fotos (Palacio de Justicia, Capitolio, columnas corintias, La Candelaria, Plaza de Bolívar). Cada foto trae su propio fondo (carbón, navy o grafito) y su pie de foto. Mide `100 + 4×38 svh`: el scroll de la página manda y no se secuestra. Abajo va el texto "Soluciones jurídicas estratégicas, profesionales y personalizadas para proteger tus intereses y acompañarte en cada decisión.", el contador "1 / 5" y los CTA (WhatsApp si hay número configurado, si no /contacto). Intro con SplitText por líneas enmascaradas.
3. **Intro**: quiénes somos (`about_text`) y cifras con un contador animado (Counter).
4. **Marquee**: cinta infinita con los nombres de las especialidades, cada uno con su enlace.
5. **SpecialtiesRail**: en desktop (≥1024 px) la sección se fija y las 6 tarjetas cruzan en horizontal al bajar (`scrub 0.3`, altura = recorrido + viewport, parallax interno de la foto con `containerAnimation`, inclinación 3D y un foco que sigue al cursor). En móvil es una lista vertical.
6. **Orientador**: sección interactiva sobre fondo navy, "¿Qué necesitas resolver?". El visitante elige su situación, se muestra el área que la atiende con sus servicios y el siguiente paso, y el panel se anima con un stagger de 40 ms. Sin JS, son enlaces normales.
7. **Team**: abogados reales desde la BD (LawyerCard). Si no hay, un estado vacío digno.
8. **WhyUs**: por qué elegirnos (método, confidencialidad, honorarios por escrito).
9. **Rights**: "Tus derechos en situaciones comunes". Son unas 29 tarjetas con área, situación, respuesta corta y base legal real (p. ej. "Te impusieron un comparendo → pagar en 5 días hábiles con curso reduce 50 %; hasta el día 20, 25 % — Ley 769 de 2002, art. 136"; "Fotomulta → notificación en 3 días hábiles — Ley 1843 de 2017, art. 8"), filtrables por área, cada una con su enlace al área.
10. **Process**: 5 etapas: "Nos cuentas tu caso", "Revisamos y te orientamos", "Propuesta por escrito", "Estrategia y actuación" y "Seguimiento". Cada panel tiene su color (carbón, grafito, navy, steel, mist) y su foto. En desktop son paneles superpuestos que se abren deslizando con transform, sin animar anchos.
11. **ReviewsSection**: las 3 últimas reseñas aprobadas con estrellas y el promedio. Si no hay, se invita a dejar una.
12. **FirstConsult**: "Cómo llegar preparado". Un checklist por área (qué documentos traer), horario y dirección, y el video en bucle.
13. **Faq**: un acordeón accesible con `<details>`.
14. **ContactSection**: el formulario de contacto (nombre, correo, teléfono, especialidad, mensaje, consentimiento obligatorio de datos) más los datos y el WhatsApp.
15. JSON-LD `LegalService` y `FAQPage` (escapando `<`).

**Componentes de motion:**

- `MotionProvider`: inicia Lenis (lo guarda en `window.__lenis`), registra ScrollTrigger con `fastScrollEnd`, hace los reveals por lotes con `ScrollTrigger.batch` (lo que ya pasó hacia arriba se muestra sin animar), abre las máscaras de las fotos con `clip-path inset(100% 0 0 0) → 0` y marca `window.__motionReady = true`.
- `SplitHeading`: un título que entra por líneas enmascaradas con un trigger `scroll` o `load`.
- `Magnetic`: botones que siguen levemente al cursor.
- `Cursor`: cursor propio solo en dispositivos con puntero fino.
- `LoopVideo`: carga y reproduce el video solo cuando está a la vista, y nunca con movimiento reducido.

**Layout del sitio:**

- **Nav fijo** con el monograma, los enlaces (Especialidades, Abogados, Opiniones, Nosotros, Contacto) y "Ingresar" o "Mi panel" según la sesión (`use-nav-session`). En móvil, un menú de pantalla completa.
- **Footer** con un cierre grande (FooterClose), enlaces, legales, redes, créditos de las fotos y MotionToggle.
- **WhatsAppFab** flotante (verde oficial) solo si hay número.
- `template.tsx` con una transición corta entre páginas.

**Páginas:**

- `/especialidades` (lista) y `/especialidades/[slug]`: hero del área, problemas, servicios, abogados del área, FAQs y CTA "Solicitar asesoría", que lleva al wizard con el área preseleccionada.
- `/abogados` (filtro por especialidad) y `/abogados/[id]`: foto, bio, experiencia, formación, servicios, tarjeta profesional, disponibilidad y CTA con el abogado preseleccionado.
- `/opiniones`: reseñas aprobadas con filtro por área o abogado, y promedio.
- `/nosotros` y `/contacto`. `/legal/[doc]`.
- `loading.tsx`, `error.tsx` y `not-found.tsx` con el estilo de la marca en cada grupo.
- `robots.ts` y `sitemap.ts` (incluye las especialidades y los abogados). Metadata con `metadataBase`, plantilla `%s · Lex Magistra` y OpenGraph `es_CO`.

- **Listo cuando:** la home y todas las páginas públicas se ven completas sin base de datos (con el contenido de respaldo), en 390 y 1280 px, y con movimiento reducido todo queda visible y estático.

## 6. Autenticación y formularios

- **Clientes Supabase** con `@supabase/ssr`: `lib/supabase/server.ts` (cookies de `next/headers`) y `client.ts` (navegador).
- **Rutas:** `/registro` (nombre, correo, contraseña, confirmar contraseña y consentimiento de datos obligatorio, que se guarda en la metadata), `/ingresar`, `/recuperar` (correo de restablecimiento), `/restablecer` (nueva contraseña) y `/auth/callback` (intercambia el código por la sesión).
- **`safeNext()`:** el parámetro `next` solo acepta rutas internas. Bloquea `//x`, `/\x`, espacios y cualquier otro origen, valida contra una base falsa y revisa la ruta **normalizada** (caso `/.//host`).
- **`ConfigNotice`:** si faltan las variables de Supabase, las rutas privadas redirigen a `/ingresar?config=1` y se muestra un aviso claro.
- **`middleware.ts`:**
  - Corre solo en `/panel/*`, `/admin/*`, `/ingresar`, `/registro`, `/recuperar`, `/restablecer` y `/auth/*`. Las páginas públicas no pagan un `getUser()`.
  - Refresca el token.
  - Sin usuario, manda a `/ingresar?next=`.
  - En `/admin`, si el rol no es admin, manda a `/panel`.
  - Si ya hay sesión y entra a ingresar o registro, lo manda a `/panel`.
- **`lib/rate-limit.ts`:** un límite en memoria por IP o usuario en contacto, registro, ingreso y reseñas. Anota en el README que con varias instancias toca usar Redis o Upstash.
- **`lib/validation.ts`:** esquemas zod de contacto, registro, ingreso, correo, nueva contraseña, perfil, solicitud, reseña, abogado, firma y especialidad. También las constantes `AVATAR_MAX 2 MB`, `LAWYER_PHOTO_MAX 3 MB`, `ATTACHMENT_MAX 10 MB`, `ATTACHMENTS_PER_REQUEST 5` y `storagePath(folder, ext)` con `crypto.randomUUID()`.
- **Hook `useFormAction`:** el `<form action>` de React 19 **resetea los campos** después de un error. Usa `onSubmit` + `startTransition` + estado `{ok, message, fieldErrors}` para que el usuario no pierda lo que escribió. Muestra los errores accesibles por campo (`aria-invalid` y `aria-describedby`) y un resumen arriba.

- **Listo cuando:** el registro, la confirmación de correo, el ingreso, la recuperación y la salida funcionan contra Supabase, y un `next=//evil.com` termina en `/panel`.

## 7. Panel del cliente y del abogado (`/panel`)

`Shell` con una barra lateral agrupada, contadores y un menú móvil.

- **Resumen:** solicitudes recientes, su estado y accesos rápidos.
- **Nueva solicitud** (`RequestWizard`, 4 pasos con una barra de progreso):
  1. **Especialidad**
  2. **Abogado**: uno de esa especialidad, o "Que la firma asigne".
  3. **Confirmar**
  4. **Tu caso**: asunto, descripción, contacto preferido (WhatsApp, llamada o correo, cada uno con su explicación) y consentimiento.

  Acepta `?especialidad=` y `?abogado=` para entrar con el paso adelantado. Cada paso entra con una transición de 220 ms (opacidad y translateY).
- **Mis solicitudes** y el detalle `/panel/solicitudes/[id]`: `StatusBadge`, `CaseTimeline` (historial de estados), `AttachmentsPanel` (hasta 5 documentos, imágenes o PDF de máximo 10 MB, que se suben por Server Action y se descargan con una URL firmada) y "Cancelar solicitud" (solo si está pendiente).
- **Reseñas:** las mías y una nueva (estrellas, comentario, nombre público, mostrar mi nombre sí o no, abogado o área opcional). El aviso dice que queda pendiente de moderación.
- **Perfil:** nombre, teléfono, documento, ciudad y avatar con `ImageDrop` (arrastrar o elegir, vista previa, límite de tamaño y tipo).
- **Abogados:** el directorio dentro del panel.
- **Asignadas** (solo rol `lawyer`): las solicitudes asignadas a su perfil, con cambio de estado y nota. También puede cambiar **su propia foto pública** (RPC `set_own_lawyer_photo`).
- Estados vacíos, de carga y de error en cada pantalla (`ScreenStates`).

## 8. Administración (`/admin`, solo rol `admin`)

Barra lateral agrupada con contadores en vivo de `admin_stats()`:

- **Resumen:** las cifras y las solicitudes por especialidad (barras simples sin librería).
- **Operación:** Solicitudes (filtros por estado o área, detalle con asignación de abogado o firma, cambio de estado y notas internas), Reseñas (aprobar, rechazar o borrar, con `ConfirmButton`) y Mensajes de contacto (marcar atendido).
- **Directorio:** Abogados (crear o editar con `LawyerForm`: datos, especialidades, foto al bucket y **vincular a una cuenta** de usuario para darle el rol de abogado), Firmas y Especialidades (editar los textos, problemas, servicios y FAQs, una por línea con `lines()`).
- **Usuarios y roles:** cambiar el rol (`setUserRole`). El trigger de la BD lo protege igual.
- **Configuración y contenido:** todas las `site_settings` (nombre, eslogan, WhatsApp con formato `573001234567`, mensaje, contacto, dirección, horario, redes y texto de nosotros).
- Todas las acciones validan otra vez en el servidor que el usuario sea admin y llaman a `revalidatePath` en lo que afecten.

## 9. Herramientas de desarrollo local

- `supabase/config.toml` para levantar el stack local (`npm run db:start`) y `npm run db:env`, que escribe el `.env.local` con la URL y las llaves locales.
- `next.config.ts`:
  - `remotePatterns` de `next/image` derivado de `NEXT_PUBLIC_SUPABASE_URL` (permite `http` para el `127.0.0.1:54321` local), con `pathname /storage/v1/object/public/**`.
  - Formatos avif y webp.
  - `serverActions.bodySizeLimit` y `middlewareClientMaxBodySize` en `"11mb"`.
  - Cabeceras de seguridad: `X-Content-Type-Options nosniff`, `Referrer-Policy strict-origin-when-cross-origin`, `X-Frame-Options DENY` y `Permissions-Policy camera=(), microphone=(), geolocation=()`.
  - `devIndicators: false`.
- **DemoSwitcher:** una barra flotante para saltar entre 3 cuentas de prueba (`admin@example.com`, `abogado@example.com` y `cliente@example.com`), con los atajos Alt+1, Alt+2 y Alt+3, que se puede ocultar. Se activa **solo** si `DEMO_SWITCHER=1`, hay `DEMO_PASSWORD` y la URL de Supabase es `localhost` o `127.0.0.1`. Nunca aparece en producción.
- `scripts/make-admin.ts`: `npm run make-admin -- correo@x.com` da el rol admin usando la service role (solo local).

## 10. Verificación final (loop, máximo 8 vueltas)

1. `npm run typecheck` ✓, `npm run lint` ✓, `npm run build` ✓ y `npm run test:db` con todo ✓. Pega las salidas.
2. Todas las rutas públicas responden 200. Las privadas sin sesión responden 307 a `/ingresar`. Ningún enlace interno da 404 (rastrea la home).
3. Flujo E2E con la BD local: registro → confirmación → wizard → el admin asigna un abogado → el abogado cambia el estado → el cliente ve el historial → el cliente deja una reseña → el admin la aprueba → la reseña aparece en `/opiniones`.
4. Capturas a 390 y 1280 px de la home, una especialidad, el panel y el admin. Revisa el contraste, los solapes, el texto cortado y el scroll rápido (sin contenido roto ni secciones encimadas mientras el pin está activo).
5. Con "Reducir movimiento" activado no hay animaciones, todo se ve y nada queda oculto.
6. Lighthouse móvil: performance ≥ 85, accesibilidad ≥ 95. Fotos con `next/image`, `sizes` correctos, `priority` solo en la primera foto del hero, video perezoso.
7. Revisión de seguridad: ninguna llave fuera de `.env.local`, RLS en todas las tablas, la URL de foto con otro dominio se rechaza, el open redirect está bloqueado, los adjuntos son privados y se descargan con una URL firmada.

## 11. README y puesta en marcha

Escribe un `README.md` con:

1. `npm install`.
2. Crear un proyecto Supabase propio.
3. Correr las migraciones en orden y luego `seed.sql`.
4. Configurar `.env.local`.
5. En Auth → URL Configuration, poner el Site URL y el redirect `<site>/auth/callback`.
6. `npm run dev`, registrarse y luego `npm run make-admin -- correo`.
7. Configurar el WhatsApp en `/admin/configuracion`.

Agrega también la tabla de scripts, la descripción de los roles (client, lawyer, admin) y la lista "Antes de publicar": revisar con un abogado los textos legales y de especialidades, cargar los abogados reales, confirmar los créditos de las fotos y pasar el rate limit a Redis si hay varias instancias.

Entrega el proyecto completo, funcionando y con todas las verificaciones en verde.
