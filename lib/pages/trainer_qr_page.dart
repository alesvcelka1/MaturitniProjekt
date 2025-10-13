import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// 🔶 Stránka pro trenéry - zobrazuje QR kód s UID trenéra
/// Klient naskenuje tento QR kód a propojí se s trenérem
class TrainerQrPage extends StatelessWidget {
  const TrainerQrPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1️⃣ Získání aktuálního Firebase uživatele (trenér)
    final User? user = FirebaseAuth.instance.currentUser;
    
    // Kontrola, zda je uživatel přihlášený
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Můj QR kód'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Nejsi přihlášený!',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    // 2️⃣ Vytvoření QR kódu s formátem "trainer:<uid>"
    final String qrData = 'trainer:${user.uid}';

    return Scaffold(
      // 3️⃣ Moderní oranžová AppBar
      appBar: AppBar(
        title: const Text(
          'Můj QR kód',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      
      // 4️⃣ Tělo stránky s QR kódem
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Informační text
                const Text(
                  'Sdílej tento QR kód se svými klienty',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                const Text(
                  'Klient ho naskenuje a automaticky se s tebou propojí',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // 5️⃣ QR kód v bílém kontejneru
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // QR kód
                      QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200.0,
                        foregroundColor: Colors.black87,
                        backgroundColor: Colors.white,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Informace o uživateli
                      Text(
                        user.displayName ?? user.email ?? 'Trenér',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        'ID: ${user.uid.substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // 6️⃣ Pomocný text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Klient si stáhne aplikaci, vytvoří účet a naskenuje tento QR kód pro propojení',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}