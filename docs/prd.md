# Product Requirements Document (PRD) - Upwise

## 1. Overview

**Product Name:** Upwise
**Tagline:** Personalized AI-Powered Learning Path Generator
**Platform:** Mobile (Flutter)
**Target User:** Lifelong learners of all ages who want to learn in a structured, customized, and consistent way.

## 2. Problem Statement

Users who want to learn new skills often:

* Waste time crafting personalized learning paths manually
* Need to copy and clean learning content from ChatGPT or online sources
* Lack motivation and consistency to follow the plan
* Don’t track their progress properly

## 3. Solution

Upwise helps users generate detailed and personalized learning paths using AI, track progress daily, stay motivated via gamification (streaks, badges), and access curated recommendations for learning materials, exercises, and projects.

## 4. Core Features

### 4.1. Learning Path Generator

* Input:

  * Topic of study
  * Daily available study time 
  * Experience level
  * Learning style
  * Output goal
  * Optional: include projects, exercises, notes
* Output:

  * Table of daily learning plan
  * Each row includes:

    * Day number
    * Main topic
    * Sub-topic
    * Recommended material (URL)
    * Exercise (optional)
    * Status (default: "Not Started")
  * Project recommendations section
  * Optional section

### 4.2. Daily Tracker

* Display today’s learning topic, material, and exercise
* Actions:

  * Mark as "Complete", "Skip", or "In progress"
  * Automatically update progress and streak

### 4.3. Streak System (Gamification)

* Track consecutive active days
* Display visual streak indicator (🔥)
* Daily reminder to maintain streak

### 4.4. Analytics Page

* Total topics completed
* Total hours learned
* Current streak
* Overall progress bar

### 4.5. User Authentication

* Email/password login and register
* Session management via Supabase Auth

## 5. AI Integration

* LLM: Google Gemini (Gemma 3)
* Used to:

  * Generate the structured learning path based on user input
  * Suggest projects and exercises
* Integration via Gemini API

## 6. Tech Stack

* **Frontend:** Flutter (mobile only)
* **Backend:** Supabase (auth, database, API)
* **AI:** Google Gemini API (Gemma 3)
* **Auth:** Supabase Auth
* **Database:** Supabase

## 7. User Roles

* **Learner (default user role):**

  * Create learning paths
  * Track progress
  * View analytics
  * Maintain streaks

## 8. Success Metrics

* 75% of users completing a learning path
* 100 daily active users (DAU)
* 20 days average streak length
* Feature adoption rate (e.g., analytics viewed, learning path created)

## 9. Optional Future Features

* Sync to calendar or reminders
* Export to CSV/Notion
* Social/community feature
* Goal-based template presets
* Offline mode

## 10. Non-Functional Requirements

* Mobile-first UX
* Fast AI response time (<5s)
* Data privacy via Supabase policies
* Offline caching (future)

---