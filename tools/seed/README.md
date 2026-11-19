# Phrase Practice — Database Seed & Verification Tools

This folder contains automated scripts and data definitions for populating Cloud Firestore with the initial curriculum of languages, categories, and phrases.

---

## Data Contents

- **`data/languages.json`:** 3 active languages: English (`en`), Spanish (`es`), and Filipino (`fil`).
- **`data/categories.json`:** 5 core categories with trilingual titles: Greetings, Food and Dining, Directions, Travel, and Emergencies.
- **`data/phrases.json`:** 50 curated phrases (10 per category), each translated into English, Spanish, and Filipino with pronunciation respellings, example sentences, and usage notes.

---

## 1. Verifying Seed Data (Offline / No Credentials Needed)

To validate data integrity, run:
```bash
node verify.js
```
This checks that:
- Every active phrase has translations in all three languages (`en`, `es`, `fil`).
- Every phrase belongs to a valid category.
- No category is empty.
- Respellings and example sentences are populated.
- `verified` is set to `false`.

---

## 2. Generating Firebase Credentials

The seed script requires a Firebase Service Account key:

1. Open the [Firebase Console](https://console.firebase.google.com).
2. Select your project: **`phrase-practice`**.
3. Click the gear icon (**Project settings**) at the top left, then go to the **Service accounts** tab.
4. Click **Generate new private key**, then confirm by clicking **Generate key**.
5. Save the downloaded JSON file to your computer.
   *(Note: Service account keys are sensitive credentials. Never commit them to git or upload them to public servers. `.gitignore` is configured to ignore `*serviceAccount*.json` and `tools/seed/serviceAccountKey.json`).*

---

## 3. Running the Seed Script

### Step 1: Install Dependencies
```bash
cd tools/seed
npm install
```

### Step 2: Set the Credentials Environment Variable
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/downloaded-key.json"
```

### Step 3: Run the Seeder
```bash
node seed.js
```

The script will write each document with its slug as the document ID and `{ merge: true }`. It is completely safe to run multiple times without duplicating data or overwriting manual edits to other fields.
