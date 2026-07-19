# AETHER

AETHER is an all-in-one student productivity and life-management app built with Flutter.

Designed around a minimal dark aesthetic with subtle glassmorphism, AETHER combines study planning, habit tracking, health monitoring, routines, and academic management into a single cross-platform experience.

---

## ✨ Features

### 📊 Dashboard

- Daily overview
- Progress tracking
- Upcoming deadlines
- Schedule preview
- Quick statistics

---

### ✅ Daily Planner

- Create tasks and notes
- Organize days, weeks, and months
- Set priorities and deadlines
- Filter tasks by category

---

### ⏰ Routine Builder

Create reusable templates such as:

- Study Day
- Rest Day
- Travel Day
- Exam Day
- Custom routines

Templates can repeat on:

- Every day
- Weekdays
- Weekends
- Specific days
- Custom tags

---

### 🎓 Academics

Manage your academic life through course cards.

Each course includes:

- Lectures and classes
- Assignments
- Notes
- Timetables
- Syllabus tracking
- Projects and exams

---

### 🔥 Habits

Track habits and hobbies with:

- Streaks
- Weekly progress
- Categories
- Completion statistics

---

### ❤️ Health

- Calorie tracking
- Meal logging
- Weight trends
- Workout plans
- Water intake
- Fitness analytics

---

## 🛠 Tech Stack

### Frontend

- Flutter

### State Management

- Riverpod

### Navigation

- Go Router

### Backend

- Supabase

### Local Database

- SQLite / Drift

### Notifications

- Firebase Cloud Messaging

---

## 📦 Offline-First Architecture

```text
Device
   ↓
Local Database
   ↓
Sync Engine
   ↓
Cloud Backend
```

Changes are saved locally and synchronized automatically whenever an internet connection becomes available.

---

## 🌍 Supported Platforms

- Android
- iOS
- Windows
- Linux
- macOS
- Web

---

## 📁 Project Structure

```text
lib/
├── core/
│   ├── theme/
│   ├── utils/
│   └── constants/
│
├── features/
│   ├── dashboard/
│   ├── planner/
│   ├── academics/
│   ├── habits/
│   ├── health/
│   └── routines/
│
├── widgets/
├── services/
├── models/
└── main.dart
```

---

## 🎨 Design Philosophy

AETHER focuses on:

- Simplicity
- Speed
- Offline usability
- Cross-platform support
- Long-term planning
- Minimal distractions

Because apparently managing studies, habits, workouts, deadlines, classes, sleep, food, and life itself now requires its own operating system.

---

Built with Flutter ❤️