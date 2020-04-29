import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:kitley/utils/message.dart';
import 'package:kitley/utils/user.dart';

class ChatPage extends StatefulWidget {
  final User otherUser;

  const ChatPage({Key key, @required this.otherUser}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  Future<FirebaseUser> _myUser = FirebaseAuth.instance.currentUser();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUser.name)),
      body: FutureBuilder(
        future: _myUser,
        builder: (_, AsyncSnapshot<FirebaseUser> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(child: Text('Loading....'));
            default:
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');

              User myUser = User.fromFireBaseUser(snapshot.data);
              String chatId =
                  '${myUser.uid.hashCode + widget.otherUser.uid.hashCode}';
              return Column(
                children: <Widget>[
                  chatList(chatId),
                  Divider(height: 1.0),
                  Composer(myUser: myUser, otherUser: widget.otherUser),
                ],
              );
          }
        },
      ),
    );
  }

  Widget chatList(String chatId) {
    return Flexible(
      child: StreamBuilder(
        stream: Firestore.instance
            .collection('chats')
            .document(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .snapshots(),
        builder: (_, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) return Text('Error: ${snapshot.error}');

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          } else {
            List<Message> messages = snapshot.data.documents
                .map<Message>(
                    (snapshot) => Message.fromDocumentSnapshot(snapshot))
                .toList();
            messages.map((e) => print(e.content));

            return ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) {
                return Text('${messages[index].content}');
              },
              itemCount: messages.length,
            );
          }
        },
      ),
    );
  }
}

class Composer extends StatefulWidget {
  final User myUser;
  final User otherUser;

  const Composer({Key key, @required this.myUser, @required this.otherUser})
      : super(key: key);

  @override
  _ComposerState createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  TextEditingController _textController = TextEditingController();
  bool _isComposing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: <Widget>[
          Flexible(
            child: TextField(
              controller: _textController,
              onChanged: (String text) {
                setState(() => _isComposing = text.length > 0);
              },
              onSubmitted: _handleSubmitted,
              decoration: InputDecoration.collapsed(hintText: "Send a message"),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _isComposing
                      ? () => _handleSubmitted(_textController.text)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmitted(String text) {
    Message message = Message()
      ..idFrom = widget.myUser.uid
      ..idTo = widget.otherUser.uid
      ..content = text;

    message.upload();
  }
}
