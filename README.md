# YaConecta 🚀🇨🇴
### *La plataforma comunitaria y comercial nativa para los pueblos y el campo colombiano.*

> **"Donde las grandes aplicaciones no llegan ni entienden la vida del pueblo, YaConecta devuelve el poder del comercio, los encargos y la información directa a las manos de los vecinos."**

---

## 🌾 El Manifiesto: Modelo *GobiernoFree* para la Economía Local y Rural

Las grandes multinacionales tecnológicas (Rappi, Uber, MercadoLibre) fueron diseñadas por y para las grandes metrópolis. Exigen márgenes de comisión exorbitantes, cobros bancarios complejos y logística centralizada que resultan **inviables e inútiles para los municipios de pequeña escala, los campesinos, los pequeños comerciantes y los transportadores de nuestro campo**.

En la mayoría de los pueblos de Colombia (como Cubarral, Guamal, Lejanías o San Martín), el comercio real sucede cara a cara, a través del vos a vos, en los mototaxis, en las ferreterías de barrio, en las tiendas de remates y en las plazas de mercado.

**YaConecta nace con una filosofía clara: Modelo *GobiernoFree* y Descentralizado**
1. **Sin Comisiones ni Intermediarios Chupasangre**: El comerciante o campesino vende su producto o servicio y se queda con el 100% de su ganancia. La transacción se acuerda directamente en efectivo o Nequi/Daviplata entre vecinos.
2. **Cero Burocracia**: Sin trámites complejos ni registros corporativos extensos. Un dulcero, un mecánico, una panadería o un expreso rural se registran en 30 segundos.
3. **Autonomía Comunitaria**: La información del pueblo la regulan los mismos habitantes. Si hay un derrumbe en la vía, una emergencia de agua o un evento en la plaza, los vecinos publican la noticia y aportan pruebas fotográficas/videográficas para verificar la veracidad en tiempo real.
4. **Respeto e Impulso al Trabajo del Campo**: Permite al agricultor o comerciante local anunciar sus cosechas, encargos o productos sin depender de intermediarios que devalúen su trabajo.

---

## 🌟 Funcionalidades Principales

```
 ┌─────────────────────────────────────────────────────────────────────────┐
 │                            YACONECTA APP                                │
 ├─────────────────┬───────────────────┬──────────────────┬────────────────┤
 │   🏪 MI NEGOCIO │ 📣 ENCARGOS       │ 📰 NOTICIAS      │ 📸 SPOTS       │
 │   Dashboard     │ Encargos locales  │ Tablón verificado│ Rincones       │
 │   Estantería    │ Ofertas directas  │ Evidencia fotos  │ Turismo local  │
 │   Excel / CSV   │ Oportunidades     │ Confirmación     │ Miradores      │
 └─────────────────┴───────────────────┴──────────────────┴────────────────┘
```

### 1. 🏪 Dashboard Comercial "Mi Negocio" y Estantería Digital
Un panel de administración moderno pensado para que los comerciantes atiendan su negocio sin complicaciones:
- **Vista de Métricas en Tiempo Real**: Tarjetas rápidas con el estado del catálogo, conexión WhatsApp, tarifa de domicilio y solicitudes pendientes del pueblo.
- **Configuración Comercial Simplificada**: Foto de perfil personalizada, horario, resumen, catálogo, tarifa de envío ($) y tiempo estimado (ETA).
- **Importador Masivo de Inventarios (Excel / CSV)**: Ideal para ferreterías, tiendas de remates, misceláneas o tiendas de abarrotes. Copia y pega un archivo con cientos de productos (`Nombre, Descripción, Precio`) y la app los carga instantáneamente a la estantería del comercio.

### 2. 📣 Solicitudes Comunitarias y Encargos de Vecinos
El punto de encuentro entre la oferta y la demanda del pueblo:
- Publicación de solicitudes locales en segundos: *“Necesito una carrera a la vereda El Retiro”*, *“Busco repuesto para guadañadora”*, *“¿Quién vende tamales hoy?”*.
- **Botón "Ofrecer"**: Los comerciantes y trabajadores locales responden instantáneamente con una oferta directa, conectando por privado o WhatsApp sin cobrar comisión por la carrera o la venta.

### 3. 📰 Noticias Comunitarias y Evidencia Fotográfica / Videográfica
El periódico ciudadano y sistema de alertas del pueblo:
- Publicación de noticias viales, luto, alertas climáticas, cortes de agua/luz o eventos comunitarios.
- **Evidencia Multimedia Comunitaria**: Los vecinos no solo confirman la noticia, sino que pueden **subir fotografías o videos tomados en el lugar del evento** con notas aclaratorias para respaldar la información.
- **Sistema de Verificación Ciudadana**: Con 3 confirmaciones de los vecinos, la noticia adquiere la insignia de *“Confirmada por vecinos”*.

### 4. 📸 Spots del Pueblo (Turismo y Parches Locales)
Guía colaborativa para que visitantes y residentes descubran los tesoros del municipio:
- Miradores, charcos de río, fincas agroturísticas, panaderías tradicionales y rincones históricos.
- Categorías: 📸 *Fotos / Miradores*, ☕ *Chill / Parche*, 🏞️ *Naturaleza / Río*, 🏛️ *Historia / Rincón*.

### 5. 🔑 Autenticación Flexible (Supabase Auth)
- **Sign in with Apple**: Integrado de forma nativa (`ASAuthorizationAppleIDCredential`).
- **Google Sign-In**: Compatible con OAuth 2.0 en iOS.
- **Correo y Contraseña**: Registro tradicional para cualquier ciudadano.

---

## 🛠️ Arquitectura Técnica

La aplicación fue construida con estándares modernos de ingeniería en Swift:

- **Lenguaje**: Swift 6 + SwiftUI + Observation Framework (`@Observable`).
- **Backend & Base de Datos**: PostgreSQL en **Supabase** con políticas de seguridad a nivel de fila (**RLS - Row Level Security**).
- **Storage Buckets**:
  - `product-images` (Fotos de productos)
  - `request-attachments` (Adjuntos de encargos)
  - `spot-photos` (Fotografías de Spots turísticos)
  - `avatars` (Fotos de perfil y logos comerciales)

### Esquema de Tablas SQL

```
  ┌──────────────┐       ┌──────────────┐       ┌──────────────┐
  │    towns     │───────│  businesses  │───────│   products   │
  └──────────────┘       └──────────────┘       └──────────────┘
         │                      │                      │
         │               ┌──────────────┐       ┌──────────────┐
         └───────────────│ local_news   │───────│news_evidences│
                         └──────────────┘       └──────────────┘
```

Las migraciones SQL están estructuradas en:
- `supabase/migrations/202607220001_auth_and_local_news.sql`: Usuarios, perfiles, noticias locales y confirmaciones.
- `supabase/migrations/202608110002_businesses_products_requests.sql`: Comercios, productos, solicitudes y ofertas.
- `supabase/migrations/202608110003_storage_spots_and_ratings.sql`: Storage Buckets, Spots del pueblo y calificaciones.

---

## 🚀 Guía de Desarrollo Local

1. Requisitos: macOS con Xcode 15+ o 16.
2. Clona este repositorio:
   ```bash
   git clone https://github.com/tu-usuario/YaConecta.git
   cd YaConecta
   ```
3. Abre el proyecto en Xcode:
   ```bash
   open YaConecta.xcodeproj
   ```
4. Selecciona el esquema **PuebloApp** y ejecuta en el simulador de iOS (`Cmd + R`).
5. Para configurar las credenciales de Supabase y llaves de desarrollo, consulta [`SUPABASE_SETUP.md`](SUPABASE_SETUP.md).

---

## 🇨🇴 Construido para la Colombia Real
*YaConecta es un proyecto dedicado a la gente trabajadora de nuestros pueblos, campesinos, tenderos y emprendedores que mueven a Colombia desde las regiones.* 💛💙❤️
