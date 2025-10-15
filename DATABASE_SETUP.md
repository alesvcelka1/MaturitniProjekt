## � CHYBA OPRÁVNĚNÍ - IHNED OPRAVTE!

### ❌ **Aktuální problém**
Aplikace zobrazuje chybu: `permission-denied: The caller does not have permission to execute the specified operation.`

### 🔧 **OKAMŽITÉ ŘEŠENÍ:**

**1. OTEVŘETE:** https://console.firebase.google.com/project/mat-app-bc99c/firestore/rules

**2. SMAŽTE VŠE A VLOŽTE:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**3. KLIKNĚTE "PUBLISH"**

**4. POČKEJTE 30 SEKUND A ZKUSTE V APLIKACI ZNOVU**

### �🚀 Propojení s databází - Pokyny

### ✅ Stav projektu
- **Firebase Core:** ✅ Nakonfigurováno
- **Firebase Auth:** ✅ Funkční přihlašování
- **Cloud Firestore:** ⚠️ Potřebuje nastavit Security Rules
- **Uživatelské role:** ✅ Trenér rozpoznán

### 🛠️ Řešení (proveďte ručně):

1. **Otevřete Firebase Console:** https://console.firebase.google.com/
2. **Vyberte projekt:** `mat-app-bc99c`
3. **Jděte na Firestore Database → Rules**
4. **Nahraďte pravidla tímto (PRO TESTOVÁNÍ):**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

5. **Klikněte "Publish"**

### 🧪 Testování databáze

Po nastavení pravidel:

1. **Restartujte aplikaci** (`flutter run`)
2. **Přihlaste se jako trenér** (ales.vcelka1@gmail.com)
3. **V profilu použijte debug tlačítka:**
   - `Test připojení` - otestuje základní připojení
   - `Seed DB` - vytvoří testovací data
   - `Clear DB` - smaže testovací data

### 📊 Databázová struktura

```
workouts/
├── {workoutId}
│   ├── workout_name: string
│   ├── description: string
│   ├── trainer_id: string
│   ├── client_ids: array<string>
│   ├── estimated_duration: number
│   ├── created_at: timestamp
│   └── exercises: array<object>
│       ├── name: string
│       ├── sets: number
│       ├── reps: number
│       ├── load: string
│       └── note: string

users/
├── {userId}
│   ├── email: string
│   ├── display_name: string
│   ├── role: "client" | "trainer"
│   ├── created_at: timestamp
│   └── ...other_fields

exercises/
├── {exerciseId}
│   ├── name: string
│   ├── category: string
│   ├── difficulty: string
│   ├── equipment: string
│   └── description: string
```

### 🎯 Funkce aplikace

**Trenér (ales.vcelka1@gmail.com):**
- ✅ Dashboard s přehledem
- ✅ QR kód pro připojení klientů
- ✅ Vytváření tréninků s více cviky
- ✅ Přiřazování tréninků klientům
- ✅ Real-time zobrazení tréninků

**Klient (ostatní uživatelé):**
- ✅ Zobrazení přiřazených tréninků
- ✅ QR scanner pro připojení k trenérovi

### 🔐 Bezpečnost

Po dokončení testování změňte pravidla na bezpečnější verzi (soubor `firestore.rules`).

### 📱 Debug funkce

Pouze pro ales.vcelka1@gmail.com jsou k dispozici debug tlačítka v profilu:
- **Test připojení** - ověří Firestore konektivitu
- **Seed DB** - vytvoří ukázková data pro testování
- **Clear DB** - vyčistí testovací data