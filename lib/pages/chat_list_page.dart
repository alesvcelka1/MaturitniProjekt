import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'chat_page.dart';
import '../services/unread_messages_service.dart';

/// Seznam všech chatů uživatele
/// Zobrazuje aktivní konverzace s trenéry/klienty
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Zprávy'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Nejste přihlášeni'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text('Zprávy'),
      ),
      body: _buildChatsList(),
    );
  }

  /// Vytvoří seznam chatů
  Widget _buildChatsList() {
    return StreamBuilder<QuerySnapshot>(
      // Načte všechny chaty, kde je uživatel účastníkem
      stream: _firestore
          .collection('chats')
          .where('participants', arrayContains: _currentUser!.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Chyba: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          );
        }

        final chats = snapshot.data?.docs ?? [];

        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Zatím žádné konverzace',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Začni chatovat s trenérem nebo klientem',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chatData = chats[index].data() as Map<String, dynamic>;
            final participants = chatData['participants'] as List<dynamic>;
            
            // Najdi ID druhého uživatele
            final otherUserId = participants.firstWhere(
              (id) => id != _currentUser.uid,
              orElse: () => null,
            );

            if (otherUserId == null) return const SizedBox.shrink();

            return _buildChatListItem(
              chatData: chatData,
              otherUserId: otherUserId,
              chatId: chats[index].id,
            );
          },
        );
      },
    );
  }

  /// Vytvoří položku v seznamu chatů
  Widget _buildChatListItem({
    required Map<String, dynamic> chatData,
    required String otherUserId,
    required String chatId,
  }) {
    final currentUserId = _currentUser?.uid;
    if (currentUserId == null) return const SizedBox.shrink();
    
    final lastMessage = chatData['lastMessage'] as String? ?? '';
    final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
    final lastSenderId = chatData['lastSenderId'] as String?;
    final isUnread = lastSenderId != null && lastSenderId != currentUserId;

    return FutureBuilder<DocumentSnapshot>(
      // Načte informace o druhém uživateli
      future: _firestore.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        String userName = 'Uživatel';
        String? userRole;
        String? photoUrl;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          // Použij display_name, pokud existuje, jinak email bez domény
          userName = userData['display_name'] as String? ?? 
                     userData['name'] as String? ?? 
                     (userData['email'] as String?)?.split('@')[0] ?? 
                     'Uživatel';
          userRole = userData['role'] as String?;
          photoUrl = userData['photo_url'] as String?;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Otevře chat s daným uživatelem
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    chatWithUserId: otherUserId,
                    chatWithUserName: userName,
                    chatWithUserRole: userRole,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Avatar s profilovou fotkou
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.orange.withOpacity(0.2),
                    backgroundImage: photoUrl != null && photoUrl.startsWith('data:image')
                        ? MemoryImage(_decodeBase64Image(photoUrl))
                        : null,
                    child: photoUrl == null || !photoUrl.startsWith('data:image')
                        ? Icon(
                            userRole == 'trainer'
                                ? Icons.fitness_center
                                : Icons.person,
                            color: Colors.orange,
                            size: 28,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Jméno a poslední zpráva
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (lastMessageTime != null)
                              Text(
                                _formatTimestamp(lastMessageTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUnread
                                      ? Colors.orange
                                      : Colors.grey[600],
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (lastSenderId == currentUserId)
                              Icon(
                                Icons.done_all,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            if (lastSenderId == currentUserId)
                              const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lastMessage,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: isUnread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Indikátor nepřečtené zprávy - badge s počtem
                            StreamBuilder<int>(
                              stream: UnreadMessagesService.getUnreadCountForChat(chatId, currentUserId),
                              builder: (context, unreadSnapshot) {
                                final unreadCount = unreadSnapshot.data ?? 0;
                                
                                if (unreadCount == 0) {
                                  return const SizedBox.shrink();
                                }
                                
                                return Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  child: Center(
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Dekóduje base64 obrázek
  Uint8List _decodeBase64Image(String base64String) {
    return base64Decode(base64String.split(',')[1]);
  }

  /// Formátuje timestamp pro seznam chatů
  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Teď';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Včera';
    } else if (difference.inDays < 7) {
      final days = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}.${dateTime.month}.';
    }
  }
}
