# YaConecta iOS 🚀

Aplicación móvil nativa en **SwiftUI** (Swift 6) diseñada para conectar comercios, vecinos, visitantes y transportadores en pueblos e intermediarios locales donde las grandes plataformas no operan.

---

## 🌟 Funcionalidades Principales

### 1. 🔑 Autenticación Flexible (Supabase Auth)
- **Sign in with Apple**: Integrado de forma nativa (`ASAuthorizationAppleIDCredential`).
- **Google Sign-In**: Compatible con OAuth 2.0 iOS y Web client IDs.
- **Correo Electrónico**: Registro e inicio de sesión tradicional por correo y contraseña.

### 2. 🏪 Gestor de Comercios "Mi Negocio" y Estantería de Productos
- Registro y personalización de perfil comercial (Nombre, Categoría, Tiempo de entrega, Costo de domicilio).
- Administración de catálogo/estantería de productos.
- **Carga Masiva de Inventarios (Excel / CSV)**: Herramienta ideal para ferreterías, remates o tiendas de abarrotes. Permite copiar y pegar listas enteras de productos (`Nombre, Descripción, Precio`) para realizar *matching* instantáneo con búsquedas de clientes.

### 3. 📣 Solicitudes Comunitarias y Encargos
- Publicación de solicitudes locales (Domicilios, Expresos, Mandados, Servicios técnicos, o "Busco algo").
- Sistema de ofertas entre vecinos y negocios locales.

### 4. 📰 Noticias Comunitarias y Verificación
- Tablón de noticias del pueblo (Alertas viales, emergencias, servicios públicos, luto).
- Confirmación comunitaria por vecinos (reputación y estado de verificación automático).

### 5. 📸 Spots del Pueblo (Turismo y Parches Locales)
- Guía colaborativa de lugares únicos recomendados por los propios habitantes.
- Categorías: 📸 *Fotos / Miradores*, ☕ *Chill / Parche*, 🏞️ *Naturaleza / Río*, 🏛️ *Historia / Rincón*.

---

## 🛠️ Arquitectura de Base de Datos (Supabase PostgreSQL)

La aplicación utiliza la arquitectura relacional de **PostgreSQL en Supabase** con políticas de seguridad a nivel de fila (**RLS - Row Level Security**):

1. **Tablas Relacionales**:
   - `towns`, `profiles`, `businesses`, `products`, `local_requests`, `request_offers`, `local_news`, `news_confirmations`, `town_spots`, `completed_deals`, `merchant_reviews`.
2. **Supabase Storage Buckets**:
   - `product-images` (Fotos de productos)
   - `request-attachments` (Imágenes adjuntas a solicitudes)
   - `spot-photos` (Fotos de Spots turísticos)
   - `avatars` (Fotos de perfil)

---

## 🚀 Guía de Configuración y Despliegue

1. Abre `YaConecta.xcodeproj` en **Xcode**.
2. Selecciona el esquema **PuebloApp** y un simulador de iPhone.
3. Para la base de datos y llaves de desarrollo, consulta la guía paso a paso en [`SUPABASE_SETUP.md`](SUPABASE_SETUP.md).

---

## 📂 Estructura de Migraciones SQL

- `supabase/migrations/202607220001_auth_and_local_news.sql`: Perfiles, pueblos, noticias comunitarias.
- `supabase/migrations/202608110002_businesses_products_requests.sql`: Comercios, productos, solicitudes y ofertas.
- `supabase/migrations/202608110003_storage_spots_and_ratings.sql`: Storage Buckets, Spots del Pueblo, tratos completados y calificaciones automáticas.
