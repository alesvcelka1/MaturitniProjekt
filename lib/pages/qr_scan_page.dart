import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// 🔶 Stránka pro klienty - skenování QR kódu trenéra
/// Po naskenování QR kódu se klient automaticky propojí s trenérem
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _isProcessing = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    // Inicializace skeneru
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  /// 🔶 Zpracování naskenovaného QR kódu
  Future<void> _handleQrCode(String qrData) async {
    // Zabránění vícenásobného zpracování
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);

    try {
      // 1️⃣ Kontrola formátu QR kódu
      if (!qrData.startsWith('trainer:')) {
        _showErrorSnackBar('Neplatný QR kód! Musí být od trenéra.');
        return;
      }

      // 2️⃣ Extrakce ID trenéra z QR kódu
      final String trainerId = qrData.substring(8); // Odstraní "trainer:"
      if (trainerId.isEmpty) {
        _showErrorSnackBar('Neplatné ID trenéra v QR kódu!');
        return;
      }

      // 3️⃣ Získání aktuálního uživatele (klienta)
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('Nejsi přihlášený!');
        return;
      }

      final String clientId = currentUser.uid;

      // 4️⃣ Reference na Firestore dokumenty
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final DocumentReference clientDoc = firestore.collection('users').doc(clientId);
      final DocumentReference trainerDoc = firestore.collection('users').doc(trainerId);

      // 5️⃣ Kontrola existence trenéra a jeho role
      final DocumentSnapshot trainerSnapshot = await trainerDoc.get();
      if (!trainerSnapshot.exists) {
        _showErrorSnackBar('Trenér s tímto ID neexistuje!');
        return;
      }

      final trainerData = trainerSnapshot.data() as Map<String, dynamic>?;
      final trainerRole = trainerData?['role'] as String?;
      
      if (trainerRole != 'trainer') {
        _showErrorSnackBar('Naskenovaný QR kód nepatří platným trenérovi!');
        return;
      }

      final trainerName = trainerData?['display_name'] as String? ?? 
                         trainerData?['email'] as String? ?? 
                         'Trenér';

      // 6️⃣ Kontrola, zda už klient není propojený s jiným trenérem
      final DocumentSnapshot clientSnapshot = await clientDoc.get();
      if (clientSnapshot.exists) {
        final clientData = clientSnapshot.data() as Map<String, dynamic>?;
        final existingTrainerId = clientData?['trainer_id'] as String?;
        
        if (existingTrainerId != null && existingTrainerId != trainerId) {
          _showErrorSnackBar('Už jsi propojený s jiným trenérem!');
          return;
        }
        
        if (existingTrainerId == trainerId) {
          _showSuccessSnackBar('Už jsi propojený s tímto trenérem: $trainerName');
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pop(context, true);
          }
          return;
        }
      }

      // 7️⃣ Batch operace pro atomické aktualizace
      final WriteBatch batch = firestore.batch();

      // Aktualizace klienta - nastavení role a přiřazení trenéra
      batch.set(clientDoc, {
        'role': 'client',
        'trainer_id': trainerId,
        'trainer_name': trainerName,
        'email': currentUser.email,
        'display_name': currentUser.displayName,
        'connected_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Aktualizace trenéra - přidání klienta do seznamu (zajistí, že role je trainer)
      batch.set(trainerDoc, {
        'role': 'trainer', // Zajistí, že trenér má správnou roli
        'clients': FieldValue.arrayUnion([clientId]),
      }, SetOptions(merge: true));

      // 8️⃣ Spuštění batch operace
      await batch.commit();

      // 9️⃣ Zobrazení úspěšné zprávy
      if (mounted) {
        _showSuccessSnackBar('Úspěšně jsi se propojil s trenérem $trainerName!');
        
        // Návrat na předchozí obrazovku po krátkém čekání
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context, true); // true = úspěšné propojení
        }
      }

    } catch (e) {
      // 🔟 Zpracování chyb
      debugPrint('Chyba při propojování: $e');
      _showErrorSnackBar('Chyba při propojování: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// 🔶 Zobrazení chybové zprávy
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 🔶 Zobrazení úspěšné zprávy
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔶 Moderní oranžová AppBar
      appBar: AppBar(
        title: const Text(
          'Naskenuj QR kód trenéra',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      
      // 🔶 Tělo stránky se skenerem
      body: Stack(
        children: [
          // Scanner view
          MobileScanner(
            controller: _scannerController,
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing) {
                final String? qrData = barcodes.first.rawValue;
                if (qrData != null) {
                  _handleQrCode(qrData);
                }
              }
            },
          ),
          
          // Overlay s instrukcemi
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          
          // Scanning frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.orange,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  Positioned(
                    top: -1,
                    left: -1,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    left: -1,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Instrukce nahoře
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text(
                    'Namiř kameru na QR kód trenéra',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Automaticky se staneš klientem',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Instrukce dole
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'QR kód se automaticky naskenuje\na ty se propojíš s trenérem',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Loading overlay při zpracování
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.orange,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Propojuji s trenérem...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      
      // Tlačítko pro zapnutí/vypnutí baterky
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _scannerController?.toggleTorch();
        },
        backgroundColor: Colors.orange,
        child: const Icon(
          Icons.flashlight_on,
          color: Colors.white,
        ),
      ),
    );
  }
}