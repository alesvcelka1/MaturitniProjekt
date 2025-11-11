import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../services/unread_messages_service.dart';

/// Real-time chat page between client and trainer
/// Uses Firebase Firestore for instant messaging
class ChatPage extends StatefulWidget {
  final String chatWithUserId; // ID uživatele, se kterým chatujeme
  final String chatWithUserName; // Jméno uživatele
  final String? chatWithUserRole; // Role (trainer/client)

  const ChatPage({
    super.key,
    required this.chatWithUserId,
    required this.chatWithUserName,
    this.chatWithUserRole,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String? _otherUserPhotoUrl;
  String? _currentUserPhotoUrl;

  // Generuje unikátní ID chatu z obou user ID (vždy ve stejném pořadí)
  String get _chatId {
    final userId1 = _currentUser!.uid;
    final userId2 = widget.chatWithUserId;
    // Seřadíme ID alfabeticky, aby chat byl vždy stejný pro oba uživatele
    return userId1.compareTo(userId2) < 0 
        ? '${userId1}_$userId2' 
        : '${userId2}_$userId1';
  }

  @override
  void initState() {
    super.initState();
    _loadProfilePhotos();
    // Automaticky scrolluj dolů po načtení
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      // Označ zprávy jako přečtené
      _markMessagesAsRead();
    });
  }

  /// Načte profilové fotky obou uživatelů
  Future<void> _loadProfilePhotos() async {
    // Načti fotku druhého uživatele
    final otherUserDoc = await _firestore.collection('users').doc(widget.chatWithUserId).get();
    if (otherUserDoc.exists) {
      final data = otherUserDoc.data();
      setState(() {
        _otherUserPhotoUrl = data?['photo_url'] as String?;
      });
    }

    // Načti fotku aktuálního uživatele
    if (_currentUser != null) {
      final currentUserDoc = await _firestore.collection('users').doc(_currentUser.uid).get();
      if (currentUserDoc.exists) {
        final data = currentUserDoc.data();
        setState(() {
          _currentUserPhotoUrl = data?['photo_url'] as String?;
        });
      }
    }
  }

  /// Označí všechny zprávy v tomto chatu jako přečtené
  Future<void> _markMessagesAsRead() async {
    if (_currentUser != null) {
      await UnreadMessagesService.markChatAsRead(_chatId, _currentUser.uid);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolluje chat na nejnovější zprávy
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Odešle novou zprávu do Firestore
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUser == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      // Přidá zprávu do kolekce messages pod daným chatem
      await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'senderId': _currentUser.uid,
        'receiverId': widget.chatWithUserId,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false, // Pro budoucí "read receipts"
      });

      // Aktualizuje metadata chatu (poslední zpráva, čas)
      await _firestore.collection('chats').doc(_chatId).set({
        'participants': [_currentUser.uid, widget.chatWithUserId],
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': _currentUser.uid,
      }, SetOptions(merge: true));

      // Scrolluj na konec po odeslání
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      print('Chyba při odesílání zprávy: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba při odesílání: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Nejste přihlášeni'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(widget.chatWithUserId).get(),
          builder: (context, snapshot) {
            String? photoUrl;
            
            if (snapshot.hasData && snapshot.data!.exists) {
              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              photoUrl = userData?['photo_url'] as String?;
            }
            
            return Row(
              children: [
                // Avatar s profilovou fotkou
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.3),
                  backgroundImage: photoUrl != null && photoUrl.startsWith('data:image')
                      ? MemoryImage(base64Decode(photoUrl.split(',')[1]))
                      : null,
                  child: photoUrl == null || !photoUrl.startsWith('data:image')
                      ? Icon(
                          widget.chatWithUserRole == 'trainer' 
                              ? Icons.fitness_center 
                              : Icons.person,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Jméno a role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatWithUserName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.chatWithUserRole != null)
                        Text(
                          widget.chatWithUserRole == 'trainer' 
                              ? 'Trenér' 
                              : 'Klient',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Seznam zpráv (expanduje se)
          Expanded(
            child: _buildMessagesList(),
          ),
          // Input pro novou zprávu
          _buildMessageInput(),
        ],
      ),
    );
  }

  /// Vytvoří seznam zpráv s real-time updates
  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false) // Od nejstarší k nejnovější
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

        final messages = snapshot.data?.docs ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Zatím žádné zprávy',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Začni konverzaci!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Automatický scroll dolů při nových zprávách
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageData = messages[index].data() as Map<String, dynamic>;
            final isMyMessage = messageData['senderId'] == _currentUser!.uid;
            final text = messageData['text'] as String? ?? '';
            final timestamp = messageData['timestamp'] as Timestamp?;

            return _buildMessageBubble(
              text: text,
              isMyMessage: isMyMessage,
              timestamp: timestamp,
            );
          },
        );
      },
    );
  }

  /// Vytvoří bublinu pro jednu zprávu
  Widget _buildMessageBubble({
    required String text,
    required bool isMyMessage,
    Timestamp? timestamp,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Avatar pro zprávy od druhé osoby (vlevo)
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.orange.withOpacity(0.2),
              backgroundImage: _otherUserPhotoUrl != null && _otherUserPhotoUrl!.startsWith('data:image')
                  ? MemoryImage(base64Decode(_otherUserPhotoUrl!.split(',')[1]))
                  : null,
              child: _otherUserPhotoUrl == null || !_otherUserPhotoUrl!.startsWith('data:image')
                  ? Icon(
                      widget.chatWithUserRole == 'trainer'
                          ? Icons.fitness_center
                          : Icons.person,
                      size: 16,
                      color: Colors.orange,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          // Samotná zpráva
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isMyMessage
                    ? Colors.orange
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMyMessage ? 16 : 4),
                  bottomRight: Radius.circular(isMyMessage ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMyMessage ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: isMyMessage
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Avatar pro moje zprávy (vpravo)
          if (isMyMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.orange.withOpacity(0.2),
              backgroundImage: _currentUserPhotoUrl != null && _currentUserPhotoUrl!.startsWith('data:image')
                  ? MemoryImage(base64Decode(_currentUserPhotoUrl!.split(',')[1]))
                  : null,
              child: _currentUserPhotoUrl == null || !_currentUserPhotoUrl!.startsWith('data:image')
                  ? const Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.orange,
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  /// Vytvoří input pole pro psaní zpráv
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // TextField pro psaní
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Napište zprávu...',
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Tlačítko pro odeslání
            Container(
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: Colors.white),
                iconSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Formátuje timestamp na čitelný formát
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
    } else if (difference.inDays < 7) {
      final days = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
      return '${days[dateTime.weekday - 1]} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}.${dateTime.month}. ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
