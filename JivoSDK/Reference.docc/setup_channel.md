# Set up a channel

<!--Summary-->

## Overview

For the **JivoSDK** to work, you need a channel of type "Mobile SDK".
> Important: Its creation is only available in [Enterprise version of **Jivo**](https://www.jivochat.com/pricing/).

## #1: To create a channel:
- log in to your personal **Jivo** account
- go to the screen `Manage -> Channels`
- create a new channel there "Mobile SDK"
![Channel Creation](channel_setup_1)

## #2: To get a channel configuration:
- go to the settings of created channel, section `"Options"`
- find the value `widget_id` in the `"Jivo Mobile SDK parameters"` item
![Channel Settings](channel_setup_2)

> Note: `widget_id` value will be used everywhere in the **JivoSDK** wherever a `channelID` is required.
