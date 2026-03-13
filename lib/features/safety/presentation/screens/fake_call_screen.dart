import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/core/constants/app_colors.dart';
import 'package:saferide/core/constants/app_dimensions.dart';
import 'package:saferide/core/providers/service_providers.dart';
import 'package:saferide/features/safety/presentation/providers/fake_call_provider.dart';

/// Realistic incoming call UI.
///
/// Shows caller name, accept/decline buttons, and plays
/// audio when the call is accepted.
class FakeCallScreen extends ConsumerStatefulWidget {
  const FakeCallScreen({super.key});

  @override
  ConsumerState<FakeCallScreen> createState() =>
      _FakeCallScreenState();
}

class _FakeCallScreenState
    extends ConsumerState<FakeCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  late final Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _ringAnimation =
        Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: Curves.easeInOut,
      ),
    );

    // Vibrate on mount to simulate ringing
    HapticFeedback.vibrate();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fakeCallState = ref.watch(
      fakeCallNotifierProvider,
    );
    final isAnswered = fakeCallState.isAnswered;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Caller avatar with ring animation
            AnimatedBuilder(
              animation: _ringAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isAnswered
                      ? 1.0
                      : _ringAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary
                      .withValues(alpha: 0.3),
                  border: Border.all(
                    color: AppColors.primary
                        .withValues(alpha: 0.6),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(
              height: AppDimensions.paddingLG,
            ),

            // Caller name
            Text(
              fakeCallState.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: AppDimensions.paddingSM,
            ),

            // Call status text
            Text(
              isAnswered
                  ? 'Connected'
                  : 'Incoming Call...',
              style: TextStyle(
                color:
                    Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),

            const Spacer(flex: 3),

            // Call duration when answered
            if (isAnswered)
              _CallDurationTimer()
            else
              const SizedBox.shrink(),

            const Spacer(),

            // Action buttons
            if (isAnswered)
              _buildEndCallButton()
            else
              _buildIncomingCallButtons(),

            const SizedBox(
              height: AppDimensions.paddingXXL,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingCallButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingXXL,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceEvenly,
        children: [
          // Decline
          _CallActionButton(
            icon: Icons.call_end,
            color: AppColors.danger,
            label: 'Decline',
            onTap: () {
              ref
                  .read(
                    fakeCallNotifierProvider.notifier,
                  )
                  .end();
              Navigator.of(context).pop();
            },
          ),

          // Accept
          _CallActionButton(
            icon: Icons.call,
            color: AppColors.safe,
            label: 'Accept',
            onTap: _answerCall,
          ),
        ],
      ),
    );
  }

  Widget _buildEndCallButton() {
    return _CallActionButton(
      icon: Icons.call_end,
      color: AppColors.danger,
      label: 'End Call',
      onTap: () {
        final audioService = ref.read(
          audioServiceProvider,
        );
        audioService.stopPlayback();
        ref
            .read(fakeCallNotifierProvider.notifier)
            .end();
        Navigator.of(context).pop();
      },
    );
  }

  void _answerCall() {
    ref
        .read(fakeCallNotifierProvider.notifier)
        .answer();

    // Play a pre-recorded audio clip to simulate the
    // other end of the call.
    final audioService = ref.read(audioServiceProvider);
    audioService
        .playAsset('assets/audio/fake_call_voice.mp3')
        .catchError((_) {
      // Silently ignore if asset is missing
    });

    _ringController.stop();
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSM),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// Displays an incrementing call duration timer.
class _CallDurationTimer extends StatefulWidget {
  @override
  State<_CallDurationTimer> createState() =>
      _CallDurationTimerState();
}

class _CallDurationTimerState
    extends State<_CallDurationTimer> {
  int _seconds = 0;
  late final Stream<int> _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(
      const Duration(seconds: 1),
      (i) => i + 1,
    );
    _ticker.listen((s) {
      if (mounted) setState(() => _seconds = s);
    });
  }

  String _formatDuration(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(
          2,
          '0',
        );
    final s = (totalSeconds % 60).toString().padLeft(
          2,
          '0',
        );
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_seconds),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 18,
        fontFeatures: const [
          FontFeature.tabularFigures(),
        ],
      ),
    );
  }
}
