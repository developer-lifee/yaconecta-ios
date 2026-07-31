# Activar Supabase, Apple y Google

La app ya contiene el cliente y la interfaz de autenticación. Las credenciales públicas se configuran en `PuebloApp/Supporting/Info.plist`. Nunca pongas una clave `service_role` dentro de una app móvil.

## 1. Crear el proyecto Supabase

1. Crea un proyecto en Supabase.
2. Ejecuta `supabase/migrations/202607220001_auth_and_local_news.sql` desde el SQL Editor o con Supabase CLI.
3. En **Project Settings > API**, copia la URL y la clave **publishable** (o `anon` en proyectos antiguos).
4. Reemplaza `YOUR_PROJECT` y `YOUR_PUBLISHABLE_KEY` en `PuebloApp/Supporting/Info.plist`.

## 2. Sign in with Apple

1. Usa el Bundle ID `com.yaconecta.ios` o cambia el del proyecto antes de configurar proveedores.
2. En Apple Developer, habilita **Sign in with Apple** para ese App ID.
3. En Supabase > Authentication > Providers > Apple, activa Apple y agrega el Bundle ID como Client ID.
4. Selecciona tu equipo de desarrollo en Signing & Capabilities de Xcode.

Para una app exclusivamente nativa no hace falta crear un secreto OAuth de Apple. El proyecto incluye el entitlement y usa `ASAuthorizationAppleIDCredential`.

## 3. Sign in with Google

1. En Google Auth Platform crea un cliente OAuth de tipo **iOS** con el Bundle ID de la app.
2. Crea también un cliente OAuth de tipo **Web application** para que Supabase valide los ID tokens.
3. Activa Google en Supabase Auth. Agrega ambos Client IDs y habilita **Skip nonce check**, como indica la guía de Supabase para iOS.
4. En `Info.plist`, reemplaza:
   - `YOUR_IOS_CLIENT_ID.apps.googleusercontent.com`
   - `YOUR_WEB_CLIENT_ID.apps.googleusercontent.com`
   - `com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID`
5. En Google Auth Platform configura branding, política de privacidad y términos.

## 4. Verificación rápida

1. Ejecuta en un dispositivo o Simulator con una cuenta disponible.
2. Abre **Perfil > Continuar con Apple o Google**.
3. Comprueba en Supabase > Authentication > Users que se creó el usuario.
4. Comprueba que el trigger creó su fila en `public.profiles`.

Antes de producción hay que añadir URL públicas de política de privacidad, términos, eliminación de cuenta y un flujo de moderación para reportes.
