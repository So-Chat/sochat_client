# SoChat Client 

<div align="center">

<h2>Chat on any server you want!</h2>

<p>
    <a href="./README-ru.md">Rus</a>
</p>

<h3>Made with Flutter</h3>
</div>

# About SoChat
__SoChat enables users to create and manage their own messaging servers for text and voice communication through the dedicated SoChat Client application, giving them full control over customization and security.__

[**Made for SoChat Server**](https://github.com/So-Chat/SoChatServer)

The main goal of SoChat Client is to make using self-hosted messaging servers as simple as possible.

The client is designed for users who want to connect to self-hosted messaging infrastructure.

## THIS PROJECT IS STILL A WORK IN PROGRESS
- SoChat is currently under active development. Some features may be incomplete or subject to change.

## Features
- End-to-end encryption — Messages and media are encrypted before leaving the client.
- User profiles
- Friends and friend requests
- Private and group messaging
- Media sharing
- P2P voice & video calls
- Media device management
- Desktop support
### Planned features
- More encryption
- SFU-based calls
- Mobile UI
- Avatars
- Notification improvments
- Localization
- And more!

## Libraries used in project

| Library                     | Version|
|-----------------------------|--------|
| encrypt                     | 5.0.3  |
| flutter_riverpod            | 3.2.1  |
| http                        | 1.6.0  |
| cryptography                | 2.9.0  |
| web_socket_channel          | 3.0.3  |
| flutter_secure_storage      | 10.0.0 |
| tray_manager                | 0.5.2  |
| flutter_local_notifications | 21.0.0 |
|file_picker                  | 11.0.2 |
| mime                        | 2.0.0  |
|flutter_webrtc               | 1.5.1  |
| flutter_resizable_container | 4.2.0  | 
| flutter_miniaudio           | [from repository](https://github.com/So-Chat/flutter_miniaudio.git) |
| scrollable_positioned_list  | 0.3.8  |

## Build from source
### Requirements
- Flutter SDK
- Git
### Clone the repository
```bash 
git clone https://github.com/So-Chat/sochat_client
cd sochat_client
```
### Build
```bash
flutter build <platform> --release
```
- Replace `<platform>` with the platform you want to build for, for example `windows`, `linux`, or `macos`.
### Result

After a successful build, the compiled application will be located in the platform-specific build directory.

For example, on Windows:
build/windows/x64/runner/Release/

## License
- **This project is licensed under the [MIT License](https://github.com/So-Chat/sochat_client/blob/master/LICENSE)**
