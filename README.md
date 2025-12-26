# 🎮 Gawean: Gamify Todolist

**Transform Your Daily Tasks into an Epic Adventure!**

Gawean adalah aplikasi To-Do List dengan elemen gamifikasi yang mengubah tugas sehari-hari menjadi petualangan seru. Tingkatkan produktivitas dengan sistem level, hadiah, pencapaian, dan harta karun yang menunggu untuk ditemukan!

![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)
![SQLite](https://img.shields.io/badge/SQLite-07405E?logo=sqlite)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Fitur Utama

### 🗺️ **Sistem Quest**
- Buat tugas dengan kategori dan prioritas
- Pelacakan progres real-time
- Hadiah XP dan koin untuk setiap tugas selesai
- Warna kustom untuk setiap quest

### 🏆 **Sistem Gamifikasi**
- **Leveling System**: Naik level dengan mengumpulkan XP
- **Achievement System**: 12+ pencapaian unik dengan kategori berbeda
- **Treasure Mountain**: 10 level harta karun dengan layout vertikal
- **Currency System**: Koin yang bisa dikumpulkan

### 📊 **Statistik & Analitik**
- Dashboard statistik komprehensif
- Pelacakan produktivitas harian
- Streak system untuk konsistensi
- Grafik perkembangan mingguan

### 👤 **Profil Pengguna**
- Profil avatar kustom
- Progress tracking
- Koleksi achievement
- Riwayat aktivitas

## 🗄️ Struktur Database

### **Tabel Utama**

#### `quests` - Manajemen Tugas
```sql
- id, title, description, category, priority
- date, time, progress, isCompleted
- xpReward (15), coinsReward (10)
- createdAt, completedAt, colorHex
```

#### `user_profile` - Data Pengguna
```sql
- displayName, photoPath, level (1-∞)
- currentXp, xpToNextLevel (formula: 100 * level^1.5)
- totalCoins, streakDays, tasksCompleted
- efficiencyRate, highestStreak
- achievementsEarned, treasuresUnlocked
```

#### `achievements` - Sistem Pencapaian
```sql
- title, description, icon_name, color_hex
- is_earned, earned_at, xp_reward, category
- Kategori: quest, streak, productivity, level, special, speed
```

#### `treasures` - Harta Karun Bertingkat
```sql
- 10 level dengan layout mountain vertikal
- requiredTasks (20-400 tasks)
- rewards: coins, XP, badges, avatar, theme
- positionX, positionY untuk layout visual
```

#### `daily_stats` - Statistik Harian
```sql
- date, tasksCompleted, productivityScore
- focusMinutes (menit fokus)
```

## 🚀 Instalasi & Setup

### Prasyarat
- Flutter SDK 3.0+
- Dart 3.0+
- SQLite (via sqflite package)

### Langkah Instalasi

1. **Clone Repository**
```bash
git clone https://github.com/username/gawean-todolist.git
cd gawean-todolist
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Setup Database**
```dart
// Database akan otomatis terinisialisasi
// Versi database: 6 (dengan auto-migration)
```

4. **Run Aplikasi**
```bash
flutter run
```

## 📁 Struktur Project

```
lib/
├── models/
│   ├── quest.dart          # Model Quest/Tugas
│   ├── user_profile.dart   # Model Profil Pengguna
│   ├── achievement.dart    # Model Achievement
│   └── treasure.dart       # Model Treasure Level
│
├── database/
│   └── database_helper.dart # File utama database
│
├── screens/
│   ├── quest_list.dart     # Daftar Quest
│   ├── profile_page.dart   # Halaman Profil
│   ├── achievements.dart   # Halaman Achievement
│   └── treasure_map.dart   # Peta Treasure
│
└── widgets/
    └── gamification/       # Widget Gamifikasi
```

## 🔧 Database Migration

Gawean mendukung **auto-migration** dari versi 1-6:

### **Versi 1 → 2**
- Menambahkan sistem koin
- Menambahkan streak days

### **Versi 2 → 3**
- Reset data user untuk struktur baru

### **Versi 3 → 4**
- Sistem XP baru dengan formula `100 * level^1.5`
- Statistik tambahan di user profile
- 5 level treasure awal

### **Versi 4 → 5**
- Layout vertikal mountain untuk treasure
- 10 level treasure
- Visualisasi yang lebih menarik

### **Versi 6**
- Achievement system baru
- Migrasi dari badges ke achievements
- 12 default achievements dengan kategori

## 🎯 Achievement Categories

| Kategori | Contoh Achievement | Hadiah XP |
|----------|-------------------|-----------|
| **Quest** | First Steps, Task Legend | 100-600 XP |
| **Streak** | Week Warrior, Monthly Master | 200-500 XP |
| **Productivity** | Efficient Explorer, Productivity Guru | 250-400 XP |
| **Level** | Level Up, XP Collector | 300-500 XP |
| **Special** | Early Bird, Speed Demon | 150-200 XP |

## 💎 Treasure Levels

| Level | Nama | Tasks Required | Hadiah |
|-------|------|----------------|---------|
| 1 | Novice Adventurer | 20 | 200 Coins + 50 XP |
| 2 | Task Initiate | 40 | 400 Coins + 100 XP |
| 3 | Consistent Contributor | 60 | 600 Coins + 150 XP |
| ... | ... | ... | ... |
| 10 | Legendary Hero | 400 | 4000 Coins + 1500 XP |

## 📈 Statistik yang Tersedia

### **Personal Stats**
- Total tasks completed
- Current level & XP progress
- Streak days & highest streak
- Efficiency rate
- Average productivity

### **Gamification Stats**
- Achievements earned (progress)
- Treasures unlocked (progress)
- Total coins collected
- Focus minutes accumulated

### **Weekly Analytics**
- Daily tasks completion
- Productivity score trend
- Focus time distribution

## 🔄 API Methods

### **User Profile**
```dart
Future<UserProfile?> getUserProfile()
Future<int> updateUserProfile(UserProfile user)
```

### **Quest Management**
```dart
Future<List<Quest>> getQuests()
Future<int> insertQuest(Quest quest)
Future<int> updateQuest(Quest quest)
Future<int> deleteQuest(int id)
```

### **Achievements**
```dart
Future<List<Achievement>> getAllAchievements()
Future<List<Achievement>> getEarnedAchievements()
Future<int> updateAchievement(Achievement achievement)
```

### **Treasures**
```dart
Future<List<TreasureLevel>> getAllTreasures()
Future<int> updateTreasure(TreasureLevel treasure)
```

### **Statistics**
```dart
Future<Map<String, dynamic>> getTotalStatistics()
Future<List<Map<String, dynamic>>> getWeeklyStats()
```

## 🛠️ Maintenance

### **Database Checks**
```dart
// Auto-execute saat startup
await DatabaseHelper().initializeWithChecks();

// Manual checks
checkAndUpdateXpSystem()      // Validasi XP formula
ensureTenTreasures()          // Pastikan 10 treasures
ensureVerticalLayout()        // Layout mountain vertikal
ensureAchievementsTable()     // Tabel achievements
```

### **Reset Database (Testing)**
```dart
await DatabaseHelper().resetDatabase();
// Reset semua data ke default
```

## 📱 Fitur UI yang Direkomendasikan

Berdasarkan struktur database, implementasikan:

1. **Quest List Screen**
   - Add/edit/delete quests
   - Progress tracking dengan progress bar
   - Filter by category/priority

2. **Profile Dashboard**
   - Level progress ring
   - Quick stats overview
   - Achievement showcase

3. **Treasure Mountain**
   - Interactive vertical mountain map
   - Treasure unlock animations
   - Reward claim system

4. **Achievement Gallery**
   - Category filters
   - Locked/unlocked states
   - Achievement details modal

5. **Statistics Page**
   - Weekly charts
   - Productivity insights
   - Focus time analysis

## 🎨 Theme & Customization

- **Light/Dark theme** support
- **Color schemes** untuk quest categories
- **Custom avatars** untuk level milestones
- **Theme unlocks** melalui treasure system

## 📄 License

MIT License - lihat [LICENSE](LICENSE) untuk detail.

## 🤝 Kontribusi

1. Fork repository
2. Buat feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📞 Support

Untuk masalah atau pertanyaan:

1. Cek [Issues](https://github.com/username/gawean-todolist/issues)
2. Database issues - pastikan migration berjalan
3. Performance - optimize query untuk large datasets

---

**✨ Jadikan setiap tugas sebagai petualangan dengan Gawean!**
