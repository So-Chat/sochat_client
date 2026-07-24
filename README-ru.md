# SoChat Client

<div align="center">

<h2>Общайтесь на любом сервере!</h2>

<p>
    <a href="./README.md">Eng</a>
</p>

<h3>Написано на Flutter</h3>

</div>

# О чём SoChat

**SoChat позволяет пользователям создавать и управлять собственными серверами для обмена текстовыми и голосовыми сообщениями, подключаясь к ним через специальное приложение SoChat Client и получая полный контроль над своей инфраструктурой и безопасностью.**

[**Создано для SoChat Server**](https://github.com/So-Chat/SoChatServer)

Главная цель SoChat Client — сделать использование самостоятельно размещённых серверов для обмена сообщениями максимально простым.

Клиент создан для пользователей, которые хотят подключаться к собственной инфраструктуре для обмена сообщениями.

## ЭТОТ ПРОЕКТ ВСЁ ЕЩЁ В РАЗРАБОТКЕ

* SoChat находится в активной разработке. Некоторые функции могут быть недоделаны или измениться в будущем.

## Библиотеки, использованные в проекте

| Библиотека                     | Версия |
|--------------------------------|--------|
| encrypt                        | 5.0.3  |
| flutter_riverpod               | 3.2.1  |
| http                           | 1.6.0  |
| cryptography                   | 2.9.0  |
| web_socket_channel             | 3.0.3  |
| flutter_secure_storage         | 10.0.0 |
| tray_manager                   | 0.5.2  |
| flutter_local_notifications    | 21.0.0 |
|file_picker                     | 11.0.2 |
| mime                           | 2.0.0  |
|flutter_webrtc                  | 1.5.1  |
| flutter_resizable_container    | 4.2.0  | 
| flutter_miniaudio              | [из репозитория](https://github.com/So-Chat/flutter_miniaudio.git) |
| scrollable_positioned_list     | 0.3.8  |

## Сборка из исходного кода

### Требования

* Flutter SDK
* Git

### Клонирование репозитория

```bash
git clone https://github.com/So-Chat/sochat_client
cd sochat_client
```

### Сборка

```bash
flutter build <platform> --release
```

* Замените `<platform>` на платформу, для которой вы хотите собрать приложение, например `windows`, `linux` или `macos`.

### Результат

После успешной сборки скомпилированное приложение будет находиться в папке сборки, соответствующей выбранной платформе.

Например, в Windows:

```text
build/windows/x64/runner/Release/
```

## Лицензия

* **Этот проект распространяется под [лицензией MIT](https://github.com/So-Chat/sochat_client/blob/master/LICENSE)**
