# AIStudio

iOS-приложение по тестовому заданию: AI-чат (Dola) и генератор видео (PixVerse) + экран подписки (Apphud). UIKit, программная вёрстка, iOS 16+.

## Стек и архитектура

- UIKit, Auto Layout кодом, без сторибордов. MVC + сервисный слой.
- Зависимость ApphudSDK — через SPM. `.xcodeproj` закоммичен (открывается напрямую); `project.yml` — спека XcodeGen для регенерации проекта (опционально, ревьюеру не нужна).
- Шрифт Inter (в `Resources/Fonts`), иконки в `Assets.xcassets`.
- Локализация интерфейса: en / es / zh-Hans / ru (`Localizable.strings`).
- История чата и видео сохраняется локально (UserDefaults + постеры в Caches).

```
App/          AppDelegate (Apphud.start), SceneDelegate, Info.plist
Models/       ChatMessage, VideoRequest, HistoryItem
Views/        переиспользуемые вью (градиенты, бабблы, карточки, paywall)
Controllers/  по экрану: Home, Chat, VideoGallery, VideoCreate, VideoResult, Paywall, History
Services/
  AppServices.swift   сборка графа сервисов
  Identity/           user_id для запросов (Apphud id + device fallback)
  Network/            Endpoint, APIError, NetworkService, Chat/Video сервисы
  Subscription/       SubscriptionService (Apphud)
Support/      AppConfig (URL/ключи), палитра, шрифты, Layout
```

Сервисы внедряются в контроллеры через инициализаторы (дефолты из `AppServices`).

## API

- Чат: `POST {chatBase}/chats/{chat_id}/messages?user_id=&app_id=`, тело `{message}` -> `{chat_id, assistant_message}`. `chat_id` генерит клиент (UUID).
- Видео: `POST {videoBase}/api/v1/text2video` (form) или `/image2video` (multipart) -> `{video_id}`; опрос `GET /api/v1/status?id=&user_id=&app_id=` -> `{status, video_url}`.
- Авторизация: заголовок `Bearer`, `user_id`+`app_id` в query, `app_id=com.test.test`.

## Apphud

`Apphud.start` в `didFinishLaunching` (до UI). Paywall грузится по id `main`, цены берутся из StoreKit-продуктов. Гейтинг: генерация видео закрыта без подписки; после покупки/restore доступ открывается без перезапуска.

## Допущения и ограничения

- Премиум закрывает генерацию видео (явной точки гейтинга в макете нет).
- В выданном проекте Apphud продукты не заведены, поэтому в `Resources/AIStudio.storekit` лежат репрезентативные id (`com.labs.fviu.premium.yearly/monthly`). Реальные id продуктов paywall `main` берутся из дашборда Apphud и подставляются в `.storekit` и в схему (Run -> Options -> StoreKit Configuration).
- Sandbox PixVerse возвращает фиктивный `video_url` (`example.com/.../sample.mp4`), поэтому реальное проигрывание/скачивание на нём не отрабатывает.
- Bearer-токен вынесен в `Secrets.swift` (в `.gitignore`, в репозиторий не коммитится) — создаётся из `Secrets.example.swift`, значение берётся из задания. Apphud-ключ в `AppConfig` — публикуемый клиентский ключ (нормально держать в клиенте). Сам ADMIN-токен — тестовый из задания; в проде токен выдавался бы per-user и хранился в Keychain.
- `ai-writing` из схемы Dola не подключён: отдельного экрана нет.
