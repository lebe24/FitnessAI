### Below is a clean, structured API integration plan for how your Flutter app will use:

- ExerciseDB API (Exercise search + Exercise details)

- YouTube Data API (Video search only)

🧩 API Integration Plan for Flutter
📌 Overview

Flutter app needs to:

Fetch exercise details from ExerciseDB API

Fetch related workout videos from YouTube API

This plan explains how each API call flows inside your Flutter application.

🔵 1. ExerciseDB API Integration Plan
A. When does the app call the ExerciseDB API?

Whenever a user:

Views a specific exercise in their fitness plan

Wants details such as:

Exercise description

Primary muscles

Secondary muscles

Instructions

Equipment

GIF / image

B. Data Flow
Step 1 — Flutter app sends exercise name to API

You already have exercise names in your user’s fitness plan:

Example:

Pull-Ups
Benchpress
Squats


Flutter makes a GET request:

/api/v1/exercises/search?query=pull-ups

Step 2 — API returns matching exercises

You get a list of objects containing exercise IDs.

Fetch exercise details

Now Flutter calls:

/api/v1/exercises/{exerciseId}

The API returns full exercise details:

Name

Primary muscle

Equipment

Description / instructions

Video GIF

Body part

Step 4 — Flutter displays the exercise details

Details go into your UI widgets:

Title

Muscles targeted

Steps

Equipment needed

Video/GIF preview

2. YouTube Video Search API Integration Plan
A. When does the app call YouTube API?

Whenever a user:

Opens an exercise details page

Or taps “Watch videos”

Data Flow
Step 1 — Flutter sends a search query

Use the exercise name as the search keyword:

Call YouTube Search endpoint:

/youtube/v3/search?part=snippet&type=video&q=pull-ups workout&maxResults=5

Step 2 — API returns video IDs and details

YouTube returns:

Video ID

Title

Description

Thumbnail

Example:

{
  "items": [
    {
      "id": { "videoId": "abc123" },
      "snippet": {
        "title": "How to do Pull-Ups",
        "description": "Beginner pull-up guide...",
        "thumbnails": {...}
      }
    }
  ]
}

Step 3 — Flutter stores the YouTube results

Flutter keeps:

Video IDs

Titles

Thumbnails

Descriptions

Step 4 — Flutter shows video preview cards

You display:

Thumbnail

Title

“Watch on YouTube” button

When tapped:

Launch video using video player package