# YaConecta iOS

MVP nativo en SwiftUI para conectar comercios, vecinos, viajeros y transportadores en pueblos donde las grandes plataformas no operan.

## Requisitos

- Xcode 26 o posterior
- iOS 17 o posterior

## Ejecutar

Abre `YaConecta.xcodeproj`, selecciona el esquema **PuebloApp** y un iPhone Simulator, y pulsa Run.

La aplicación usa datos comerciales locales de demostración. La autenticación social está integrada con Supabase y la sección de noticias incluye verificación comunitaria, moderación y reportes.

Para activar Apple, Google y la base de datos, sigue [`SUPABASE_SETUP.md`](SUPABASE_SETUP.md). El esquema inicial está en `supabase/migrations/202607220001_auth_and_local_news.sql`.
