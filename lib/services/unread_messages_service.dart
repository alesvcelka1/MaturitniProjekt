import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Služba pro správu nepřečtených zpráv
class UnreadMessagesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Získá počet nepřečtených zpráv pro aktuálního uživatele
  static Stream<int> getUnreadCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    // Načte všechny chaty, kde je uživatel účastníkem
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      int totalUnread = 0;

      for (var chatDoc in snapshot.docs) {
        final chatData = chatDoc.data();
        final lastSenderId = chatData['lastSenderId'] as String?;
        
        // Pokud poslední zprávu neposlal aktuální uživatel
        if (lastSenderId != null && lastSenderId != currentUser.uid) {
          // Spočítej nepřečtené zprávy v tomto chatu
          final unreadSnapshot = await chatDoc.reference
              .collection('messages')
              .where('receiverId', isEqualTo: currentUser.uid)
              .where('read', isEqualTo: false)
              .get();
          
          totalUnread += unreadSnapshot.docs.length;
        }
      }

      return totalUnread;
    });
  }

  /// Označí všechny zprávy v chatu jako přečtené
  static Future<void> markChatAsRead(String chatId, String currentUserId) async {
    final messagesSnapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    
    for (var doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
    print('Zprávy označeny jako přečtené v chatu: $chatId');
  }

  /// Získá počet nepřečtených zpráv pro konkrétní chat
  static Stream<int> getUnreadCountForChat(String chatId, String currentUserId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
