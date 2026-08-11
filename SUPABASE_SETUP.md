# Activar Supabase, Autenticación y Storage de Imágenes

La app ya contiene el cliente y la interfaz de autenticación nativa. Las credenciales públicas se configuran en `PuebloApp/Supporting/Info.plist`. Nunca pongas una clave `service_role` dentro de una app móvil.

---

## 1. Crear el Proyecto y Ejecutar Migraciones SQL

1. Crea un proyecto en [Supabase](https://supabase.com).
2. En el **SQL Editor** de Supabase o mediante Supabase CLI, ejecuta las siguientes migraciones en orden:
   - `supabase/migrations/202607220001_auth_and_local_news.sql` (Pueblos, perfiles y noticias comunitarias).
   - `supabase/migrations/202608110002_businesses_products_requests.sql` (Comercios, estantería de productos, solicitudes locales y ofertas).
   - `supabase/migrations/202608110003_storage_spots_and_ratings.sql` (Buckets de imágenes, Spots del pueblo y métricas de tratos/calificaciones).
3. En **Project Settings > API**, copia la URL y la clave **publishable** (o `anon`).
4. Configúralos en `PuebloApp/Supporting/Info.plist`.

---

## 2. Configurar Supabase Storage (Buckets de Imágenes)

La migración 0003 crea automáticamente los 4 buckets públicos:
- `product-images` (Fotos de productos de comercios).
- `request-attachments` (Fotos adjuntas en pedidos/solicitudes).
- `spot-photos` (Fotos de spots y rincones locales).
- `avatars` (Fotos de perfil de vecinos).

En la consola de Supabase en **Storage > Buckets**, confirma que aparezcan marcados como **Public**.

---

## 3. Sign in with Apple

1. En Apple Developer, habilita **Sign in with Apple** para el App ID (`com.yaconecta.ios`).
2. En Supabase > **Authentication > Providers > Apple**, activa Apple y agrega el Bundle ID como Client ID.
3. En Xcode, en **Signing & Capabilities**, asegura que la capacidad *Sign in with Apple* esté activa.

---

## 4. Sign in with Google

1. En Google Auth Platform crea un cliente OAuth de tipo **iOS** con el Bundle ID de la app.
2. Crea un cliente OAuth de tipo **Web application** para que Supabase valide los ID tokens.
3. Activa Google en Supabase Auth. Agrega ambos Client IDs y habilita **Skip nonce check**.
4. En `Info.plist`, reemplaza los valores de `GIDClientID`, `GIDServerClientID` y el esquema URL.

---

## 5. Autenticación con Correo Electrónico

1. En Supabase > **Authentication > Providers > Email**, habilita el proveedor por correo.
2. La app ya cuenta con la interfaz integrada en `SignInSheet.swift` para registrarse e iniciar sesión con correo y contraseña de forma directa.
