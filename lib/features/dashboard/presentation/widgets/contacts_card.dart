import 'package:flutter/material.dart';
import 'package:project_bihon/shared/shared.dart';

class ContactsCard extends StatelessWidget {
  final int contactCount;
  final int verifiedCount;

  const ContactsCard({
    super.key,
    this.contactCount = 5,
    this.verifiedCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                color: BihonTheme.bihonOrange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Emergency Contacts',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$contactCount contacts saved',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _AvatarDot(backgroundColor: Colors.green, letter: 'A'),
              SizedBox(width: 4),
              _AvatarDot(backgroundColor: Colors.orange, letter: 'B'),
              SizedBox(width: 4),
              _AvatarDot(backgroundColor: Colors.grey, letter: 'C'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$verifiedCount verified',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _AvatarDot extends StatelessWidget {
  final Color backgroundColor;
  final String letter;

  const _AvatarDot({required this.backgroundColor, required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(letter, style: const TextStyle(color: Colors.white)),
    );
  }
}
