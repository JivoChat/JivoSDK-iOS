# API Reference

<!--Summary-->

## Overview

For native projects, **JivoSDK API** is divided into several namespaces:

| Namespace     | Purpose
| ---           | ---
| session       | Responsible for everything related to the communication session, such as connection and client data
| chattingUI    | Responsible for everything related to the visual representation of the chat on the screen
| notifications | Contains methods responsible for setting up and processing PUSH notifications
| debugging     | Helps with SDK debugging

Each of these spaces contains methods and properties under a common area of responsibility, and each of them corresponds to a static object that can be accessed from the **Jivo SDK Mobile API**, for example:

```swift
JivoSDK.[namespace].[method_or_property]
```
