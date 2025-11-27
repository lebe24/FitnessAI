import 'package:fitness/app/chat/presentation/bloc/chat_bloc.dart';
import 'package:fitness/app/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:fitness/app/core/theme/app_pallet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

Future<dynamic> chatModal({
  required BuildContext context,
  required ChatBloc chatBloc,
  required String userId,
  required VoidCallback onClose,
  required Function(String) onSendMessage,
  required ScrollController scrollController,
  required TextEditingController messageController,
  required VoidCallback scrollToBottom,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => BlocProvider.value(
      value: chatBloc,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppPallete.backgroundColorBk,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPallete.whiteColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Chat header with connection status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AI-Chat Assistant',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppPallete.whiteColor,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Don't disconnect, just close the modal
                            Navigator.of(context).pop();
                            onClose();
                          },
                          icon: const Icon(
                            Icons.close,
                            color: AppPallete.whiteColor,
                          ),
                        ),
                      ],
                    ),
                    // Connection status indicator
                    BlocBuilder<ChatBloc, ChatState>(
                      bloc: chatBloc,
                      builder: (context, state) {
                        if (state is ChatConnecting) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Connecting...',
                                  style: GoogleFonts.poppins(
                                    color: Colors.orange,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (state is ChatConnected) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.circle, size: 6, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'Connected',
                                  style: GoogleFonts.poppins(
                                    color: Colors.green,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (state is ChatError) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 12, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.message,
                                    style: GoogleFonts.poppins(
                                      color: Colors.red,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              // Chat messages
              Expanded(
                child: BlocConsumer<ChatBloc, ChatState>(
                  bloc: chatBloc,
                  listener: (context, state) {
                    if (state is ChatMessageSent || state is ChatMessageReceived) {
                      scrollToBottom();
                    }
                  },
                  builder: (context, state) {
                    final messages = state.messages ?? [];

                    if (messages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: AppPallete.whiteColor.withOpacity(0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Start a conversation with your AI fitness assistant',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppPallete.whiteColor.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ask about your workout plan, nutrition, or fitness goals',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppPallete.whiteColor.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return ChatMessageBubble(message: message);
                      },
                    );
                  },
                ),
              ),
              // Chat input area
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppPallete.backgroundColorBk,
                  ),
                  child: BlocBuilder<ChatBloc, ChatState>(
                    bloc: chatBloc,
                    builder: (context, state) {
                      final isLoading = state is ChatMessageSending;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              style: GoogleFonts.inter(color: AppPallete.whiteColor),
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: GoogleFonts.inter(
                                  color: AppPallete.whiteColor.withOpacity(0.5),
                                ),
                                filled: true,
                                fillColor: AppPallete.whiteColor.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: 5,
                              minLines: 1,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => onSendMessage(userId),
                              enabled: !isLoading,
                              onTap: () {
                                // Scroll to bottom when text field is tapped
                                Future.delayed(
                                  const Duration(milliseconds: 300),
                                  () => scrollToBottom(),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: isLoading
                                  ? AppPallete.borderColor.withOpacity(0.5)
                                  : AppPallete.borderColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: isLoading ? null : () => onSendMessage(userId),
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.send, color: AppPallete.whiteColor),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    ),
  );
}