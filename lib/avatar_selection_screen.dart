import 'package:flutter/material.dart';

class AvatarSelectionScreen extends StatelessWidget {
  final Function(String) onAvatarSelected;

  const AvatarSelectionScreen({super.key, required this.onAvatarSelected});

  @override
  Widget build(BuildContext context) {
    final avatars = [
      'assets/avatars/avatar1.png',
      'assets/avatars/avatar2.png',
      'assets/avatars/avatar3.png',
      'assets/avatars/avatar4.png',
      'assets/avatars/avatar5.png',
      'assets/avatars/avatar6.png',
      'assets/avatars/avatar7.png',
      'assets/avatars/avatar8.png',
      'assets/avatars/avatar9.png',
      'assets/avatars/avatar10.png',
      'assets/avatars/avatar11.png',
      'assets/avatars/avatar12.png',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Avatar'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount: avatars.length,
        itemBuilder: (context, index) {
          final avatar = avatars[index];
          return GestureDetector(
            onTap: () {
              onAvatarSelected(avatar);
              Navigator.of(context).pop();
            },
            child: CircleAvatar(
              child: ClipOval(
                child: Image.asset(
                  avatar,
                  fit: BoxFit.cover,
                  width: 80,
                  height: 80,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
