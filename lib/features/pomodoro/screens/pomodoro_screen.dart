import 'dart:async';
import 'package:aether/core/database/database.dart' show PomodoroSession;
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/features/pomodoro/providers/pomodoro_providers.dart';
import 'package:aether/widgets/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  static const int workDuration = 25 * 60;
  static const int shortBreakDuration = 5 * 60;

  int _secondsRemaining = workDuration;
  bool _isRunning = false;
  bool _isBreak = false;
  Timer? _timer;
  String? _activeSessionId;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });

    if (_activeSessionId == null) {
      final service = ref.read(pomodoroServiceProvider);
      final session = await service.startSession(
        plannedMinutes: _isBreak ? shortBreakDuration ~/ 60 : workDuration ~/ 60,
      );
      _activeSessionId = session.id;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _onTimerFinished();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _onTimerFinished() async {
    _timer?.cancel();
    _isRunning = false;

    if (_activeSessionId != null) {
      await ref.read(pomodoroServiceProvider).finishSession(
            _activeSessionId!,
            completed: true,
          );
      _activeSessionId = null;
    }

    setState(() {
      _isBreak = !_isBreak;
      _secondsRemaining = _isBreak ? shortBreakDuration : workDuration;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isBreak ? 'Break time over!' : 'Work session complete!'),
          backgroundColor: context.aether.accent,
        ),
      );
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _isRunning = false;
    _activeSessionId = null;
    setState(() {
      _secondsRemaining = _isBreak ? shortBreakDuration : workDuration;
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    final sessionsAsync = ref.watch(todaySessionsProvider);

    return Scaffold(
      backgroundColor: aether.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: aether.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Focus Timer',
            style: TextStyle(
                color: aether.text, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          _buildTimerFace(aether),
          const SizedBox(height: 40),
          _buildControls(aether),
          const SizedBox(height: 60),
          Expanded(child: _buildRecentSessions(aether, sessionsAsync)),
        ],
      ),
    );
  }

  Widget _buildTimerFace(AetherTheme aether) {
    final total = _isBreak ? shortBreakDuration : workDuration;
    final progress = 1.0 - (_secondsRemaining / total);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              color: _isBreak ? context.aether.success : context.aether.accent,
              backgroundColor: aether.surfaceAlt,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isBreak ? 'BREAK' : 'FOCUS',
                style: TextStyle(
                    color: aether.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Text(
                _formatTime(_secondsRemaining),
                style: TextStyle(
                    color: aether.text,
                    fontSize: 52,
                    fontWeight: FontWeight.w300,
                    fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(AetherTheme aether) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: aether.textMuted, size: 28),
          onPressed: _resetTimer,
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: _isRunning ? _pauseTimer : _startTimer,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: aether.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: aether.accent.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: Icon(
            _isBreak ? Icons.laptop_rounded : Icons.coffee_rounded,
            color: aether.textMuted,
            size: 28,
          ),
          onPressed: () {
            if (_isRunning) return;
            setState(() {
              _isBreak = !_isBreak;
              _secondsRemaining = _isBreak ? shortBreakDuration : workDuration;
            });
          },
        ),
      ],
    );
  }

  Widget _buildRecentSessions(AetherTheme aether, AsyncValue sessionsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('Today\'s Sessions',
              style: TextStyle(
                  color: aether.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: sessionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading history')),
            data: (sessions) {
              if (sessions.isEmpty) {
                return Center(
                  child: Text('No sessions logged today',
                      style: TextStyle(color: aether.textMuted, fontSize: 13)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _SessionTile(session: sessions[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final PomodoroSession session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: aether.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.timer_rounded, color: aether.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.plannedMinutes}m Session',
                  style: TextStyle(
                      color: aether.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  DateFormat('h:mm a').format(session.startedAt),
                  style: TextStyle(color: aether.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (session.completed)
            Icon(Icons.check_circle_outline_rounded,
                color: aether.success, size: 18)
          else
            Text(
              '${session.actualMinutes ?? 0}m',
              style: TextStyle(color: aether.textMuted, fontSize: 13),
            ),
        ],
      ),
    );
  }
}
