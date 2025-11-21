


## Overview
This document outlines how the Flutter app communicates with the backend to provide context-aware AI chat based on the user’s saved fitness plan.

NOTE: WEBSCOKET URL = ws://localhost:8000/ws/chat

## Architecture
Flutter → Backend → AI Agent → Backend → Flutter

## Workflow
1. Flutter sends user message + userId to backend.
2. Backend fetches daily fitness plan from save plan in the local storage.
3. Backend constructs context and sends to AI Agent.
4. AI responds (may call tools to update the plan).
5. Backend updates local storage if needed.
6. Backend returns final answer to Flutter.
7. Flutter displays reply and updates local storage.

## Components
### Flutter
- Sends chat message
- Displays plan and agent replies
- Syncs local storage with cloud

### Backend (Python)
- Fetches saved plan
- Sends message + context to AI Agent
- Handles tool calls for plan updates