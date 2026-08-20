import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/modules/friends/friendship.dart';
import 'package:sochat_client/modules/websocket/message_packet.dart';
import 'package:sochat_client/modules/users/user.dart';
import 'package:sochat_client/modules/common/auth_service.dart';
import 'package:sochat_client/modules/keys/key_service.dart';
import 'package:sochat_client/modules/websocket/web_socket_service.dart';

//final friendsServiceProvider = StateNotifierProvider<FriendsService, FriendsState>(
//      (ref) => FriendsService(ref.read(webSocketProvider.future), ref.read(keyServiceProvider.notifier), ref.read(authServiceProvider), ref.read(currentUserProvider), ref),);

final friendsServiceProvider =
    NotifierProvider<FriendsService, FriendsState>(
  FriendsService.new,
);

final friendsListProvider = Provider<List<User>>((ref) {
  final friendships = ref.watch(friendsServiceProvider).friendships;
  final currentUser = ref.watch(authServiceProvider).currentUser;

  return friendships.values
      .where((r) => r.status == FriendshipStatus.ACCEPTED)
      .map((r) {
    if (r.user.id == currentUser?.id) {
      return r.friend;
    } else {
      return r.user;
    }
  })
      .toList();
});

final blockedListProvider = Provider<List<User>>((ref) {
  final friendships = ref.watch(friendsServiceProvider).friendships;
  final currentUser = ref.watch(authServiceProvider).currentUser;

  return friendships.values
      .where((r) => r.status == FriendshipStatus.BLOCKED)
      .map((r) => r.user.id == currentUser?.id ? r.friend : r.user)
      .toList();
});

final outgoingRequestsProvider = Provider<List<User>>((ref) {
  final friendships = ref.watch(friendsServiceProvider).friendships;
  final currentUser = ref.watch(authServiceProvider).currentUser;

  return friendships.values
      .where((f) => f.isOutgoing(currentUser!.id))
      .map((f) => f.getOtherUser(currentUser!.id))
      .toList();
});

final incomingRequestsProvider = Provider<List<User>>((ref) {
  final friendships = ref.watch(friendsServiceProvider).friendships;
  final currentUser = ref.watch(authServiceProvider).currentUser;

  return friendships.values
      .where((f) => f.isIncoming(currentUser!.id))
      .map((f) => f.getOtherUser(currentUser!.id))
      .toList();
});



class FriendsState {
  final Map<String, Friendship> friendships;

  FriendsState({
    required this.friendships,
  });

  FriendsState copyWith({
    Map<String, Friendship>? friendships,
  }) {
    return FriendsState(
      friendships: friendships ?? this.friendships,
    );
  }
}


class FriendsService extends Notifier<FriendsState>{
  late final WebSocketService _webSocket;
  late final KeyService _keyService;
  User? get currentUser => ref.read(authServiceProvider).currentUser;

  StreamSubscription? _subscription;

  Map<String, Friendship> get friendships =>
      state.friendships;

  @override
  FriendsState build() {
    _keyService = ref.read(keyServiceProvider.notifier);

    ref.watch(webSocketProvider.future).then((ws) {
      _webSocket = ws;
      startListen();
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return FriendsState(
      friendships: {},
    );
  }
  void startListen(){
    _subscription =  _webSocket.friendsMessages.listen((message) {
      switch(message.type) {
        case ("friend_request"):
          {
            receiveFriendRequest(message);
          }
        case ("friend_accept"):
          {
            receiveFriendAccept(message);
          }
        case ("friend_remove"):
        case ("friend_decline"):
          {
            receiveFriendRemove(message);
            break;
          }

        case ("blockUser"):
          {
            var userMap = jsonDecode(message.payload["user"]) as Map<String, dynamic>;
            remove(userMap["username"].toString());
            break;
          }
      }
    });
  }

  void remove(String username) {
    final newMap = {...friendships};

    final keyToRemove = newMap.keys.firstWhere(
          (key) => key == username,
      orElse: () => "",
    );

    if (keyToRemove.isNotEmpty) {
      newMap.remove(keyToRemove);
      state = state.copyWith(friendships: newMap);
    }
  }

  void addUpdate(Friendship friendship){
    final key = friendship.user.id == currentUser?.id
        ? friendship.friend.username
        : friendship.user.username;

    state = state.copyWith(
      friendships: {
        ...friendships,
        key: friendship,
      },
    );
  }

  Future<void> getRelativesList() async {
    MessagePacket message = MessagePacket(type: "relatives_list", payload: {});
    MessagePacket request = await _webSocket.sendRequest(message);
    List<dynamic> friendshipList = jsonDecode(request.payload["friendship_list"]);
    for (var f in friendshipList) {
      final user = f['user'];
      final friend = f['friend'];
      final status = f['status'];

      final friendName = friend["username"].isNotEmpty ? friend["username"] : "Null";
      final myName = user["username"].isNotEmpty ? user["username"] : "Null";

      Friendship friendship = Friendship(user: User(id: user["id"], nickname: user["nickname"], username: myName, x25519PublicKey: user["x25519PublicKey"]),
          friend: User(id: friend["id"], nickname: friend["nickname"], username: friendName, x25519PublicKey: friend["x25519PublicKey"]), status: FriendshipStatus.values.byName(status));
      addUpdate(friendship);
    }
  }

  void sendFriendRequest(String username) async {
    MessagePacket message = MessagePacket(type: "friend_request", payload: {
      "username": username,
      "fingerprint": await _keyService.generateFingerprint(),
    });
    MessagePacket request = await _webSocket.sendRequest(message);
    receiveFriendRequest(request);
  }

  void acceptFriendRequest(String username) async{
    MessagePacket message = MessagePacket(type: "friend_accept", payload: {
      "username": username,
      "fingerprint": await _keyService.generateFingerprint(),
    });
    MessagePacket request = await _webSocket.sendRequest(message);
    receiveFriendAccept(request);
  }

  void declineFriendRequest(String username) async{
    MessagePacket message = MessagePacket(type: "friend_decline", payload: {
      "username": username,
    });
    MessagePacket request = await _webSocket.sendRequest(message);
    receiveFriendRemove(request);
  }

  void removeFriend(String username) async{
    MessagePacket message = MessagePacket(type: "friend_remove", payload: {
      "username": username,
    });
    MessagePacket request = await _webSocket.sendRequest(message);
    receiveFriendRemove(request);
  }

  void blockUser(String username) async{
    MessagePacket message = MessagePacket(type: "block", payload: {
      "username": username,
    });
    MessagePacket request = await _webSocket.sendRequest(message);
    var blockedMap = jsonDecode(request.payload["blocked"]) as Map<String, dynamic>;
    remove(blockedMap["username"].toString());
  }


  void receiveFriendRequest(MessagePacket message){
    var friendshipMap = jsonDecode(message.payload["friendship"]) as Map<String, dynamic>;
    var userMap = friendshipMap["user"] as Map<String, dynamic>;
    var friendMap = friendshipMap["friend"] as Map<String, dynamic>;

    Friendship friendship = Friendship(user: User(id: userMap["id"], nickname: userMap["nickname"], username: userMap["username"], x25519PublicKey: userMap["x25519PublicKey"]),
        friend: User(id: friendMap["id"], nickname: friendMap["nickname"], username: friendMap["username"], x25519PublicKey: friendMap["x25519PublicKey"]),
        status: FriendshipStatus.PENDING);

    addUpdate(friendship);
  }

  void receiveFriendAccept(MessagePacket message){
    var friendshipMap = jsonDecode(message.payload["friendship"]) as Map<String, dynamic>;
    var userMap = friendshipMap["user"] as Map<String, dynamic>;
    var friendMap = friendshipMap["friend"] as Map<String, dynamic>;

    if (message.payload["success"] != null) {
      Friendship? friendship1 = friendships[userMap["username"].toString()];
      friendship1!.status = FriendshipStatus.ACCEPTED;
      addUpdate(friendship1);
    }
    else{
      Friendship? friendship1 = friendships[friendMap["username"].toString()];
      friendship1!.status = FriendshipStatus.ACCEPTED;
      addUpdate(friendship1);
    }
  }

  void receiveFriendRemove(MessagePacket message){
    {
      var removedMap = jsonDecode(message.payload["user"]) as Map<String, dynamic>;
      var userMap = jsonDecode(message.payload["removed"]) as Map<String, dynamic>;
      remove(removedMap["username"].toString());
      remove(userMap["username"].toString());
    }
  }

}
