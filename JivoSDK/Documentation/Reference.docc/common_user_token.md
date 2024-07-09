# User Token and JWT

Required for keeping chat history alive

## Overview

For security reasons, chat history by default has a temporary nature and gets killed when providing another credentials into ``Jivo``.``Jivo/session``.``JVSessionController/startUp(channelID:userToken:)``, or by calling ``Jivo``.``Jivo/session``.``JVSessionController/shutDown()``.

It means, for example, if your client logs-out and then logs-in again, you may see him as entirely new client.  
Even in case he uses the same login credentials, and even in case you provide the same user_token for him into SDK.

To keep chat history alive between login sessions, you have to generate JWT token and use it as user_token.  
Below, we explain how to do that.

## #1: Prepare secret

First, you need to create your global `secret` which you'll use for generating JWT tokens.  
Please create it accordingly to RFC 7519, with length of 256 bit.

Then, place this secret into "JWT Settings" screen of your Mobile SDK channel options.

> Tip: You may found this resource useful to generate, sign, and check JWT tokens: [jwt.io](https://jwt.io/)

## #2: Generate token

JWT tokens you will generate for your clients, must:
- contain unique "id" field for each individual client
- be encrypted using your `secret`

Minimal JWT payload must contain "id" field which acts like a client identifier, so here is example of such JWT payload:
```
{
    "id": "egor531@example.com"
}
```

Finally, you should feed your JWT as userToken parameter into:  
``Jivo``.``Jivo/session``.``JVSessionController/startUp(channelID:userToken:)``

> Important: For security reasons, you'd better generate JWT tokens on your back-end,  
> rather than doing it directly in the mobile app (because your `secret` might be stolen)
