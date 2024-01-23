# Create a Channel

Mobile SDK

## Overview

To use SDK, you need a channel of type "Mobile SDK"
> Important: Available for [Enterprise plan](https://www.jivochat.com/pricing/) only

## #1: Create channel
- Log in to your Jivo account
- Navigate to channels screen: `Manage -> Channels`
- Create new channel of type "Mobile SDK"

  ![Channel Creation](channel_setup_1)

## #2: Push Notifications
Make sure you have APNs Key configured in P8 format. If not, you can create it within `Keys` section of your account page at [developer.apple.com](developer.apple.com), and then download it.

Add your key into your Jivo account for your `Mobile SDK` channel.

To do this, please navigate step-by-step:
- "Management"
- "Channels"
- "Mobile SDK" (button "Settings")
- "PUSH Settings"
- "Upload p8 key"

![Channel APNs Settings: upload the key](channel_setup_3)

Then, you need to specify:

| Parameter | Purpose
| ---       | ---
| key_id    | Key ID itself
| team_id   | Team ID of your Apple Developer Program account
| bundle_id | Bundle ID of your app

![Channel APNs Settings: specify the parameters](channel_setup_4)

## #3: Inspect configuration
- Navigate to settings of created channel, section `"Options"`
- Copy `widget_id` in the `"Jivo Mobile SDK parameters"` section for later use

  ![Channel Settings](channel_setup_2)

  > Note: You should use `widget_id` value wherever `channelID` is required
