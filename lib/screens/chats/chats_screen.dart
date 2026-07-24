import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final nameStr = profile.name.isNotEmpty ? ', ${profile.name}' : '';
    
    final messages = [
      _ChatMessage(
        text: "Welcome to TruFit$nameStr! 💪 I'm your fitness coach. Let's start your journey together!",
        isCoach: true,
        time: '9:00 AM',
        date: 'Today',
      ),
      _ChatMessage(
        text: "Your workout for today is Day 1 - Upper Body. It includes warm-up, wall pushups, incline pushups, tricep dips, and cooldown stretches.",
        isCoach: true,
        time: '9:01 AM',
        date: 'Today',
      ),
      _ChatMessage(
        text: "Remember to follow your meal plan — Protein Breakfast, Balanced Lunch, Evening Snack, and Light Dinner. Total: 1397 Kcal 🍽️",
        isCoach: true,
        time: '9:02 AM',
        date: 'Today',
      ),
      _ChatMessage(
        text: "💡 Tip of the day: Focus on form over speed. Quality reps build better muscle and prevent injuries!",
        isCoach: true,
        time: '9:05 AM',
        date: 'Today',
      ),
      _ChatMessage(
        text: "Don't forget to log your weight and habits. Consistency is key! 🔑",
        isCoach: true,
        time: '6:00 PM',
        date: 'Today',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Coach Notes'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sports_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                // Show date header
                final showDate = index == 0 ||
                    messages[index - 1].date != msg.date;
                return Column(
                  children: [
                    if (showDate)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.lavender,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg.date,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ),
                      ),
                    _ChatBubble(message: msg),
                  ],
                );
              },
            ),
          ),
          // Input placeholder
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.lavender,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Coach-only chat for now...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isCoach;
  final String time;
  final String date;

  _ChatMessage({
    required this.text,
    required this.isCoach,
    required this.time,
    required this.date,
  });
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.isCoach)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sports_rounded,
                color: AppColors.white,
                size: 16,
              ),
            ),
          Expanded(
            child: Align(
              alignment: message.isCoach
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: message.isCoach ? AppColors.white : AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(message.isCoach ? 4 : 18),
                    bottomRight: Radius.circular(message.isCoach ? 18 : 4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: message.isCoach
                            ? AppColors.textDark
                            : AppColors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.time,
                      style: TextStyle(
                        fontSize: 11,
                        color: message.isCoach
                            ? AppColors.textLight
                            : AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
