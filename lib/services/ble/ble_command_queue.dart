import 'dart:async';
import 'package:flutter/foundation.dart';

/// Type of response expected from a command
enum CommandResponseType {
  /// No response expected (fire-and-forget)
  none,

  /// Wait for RESP_CODE_OK (0) or RESP_CODE_ERR (1)
  ack,

  /// Wait for specific response code with data
  data,
}

/// Represents a queued BLE command
class QueuedCommand<T> {
  /// The command data to send
  final Uint8List data;

  /// Command code (first byte of data)
  final int commandCode;

  /// Type of response expected
  final CommandResponseType responseType;

  /// Expected response code (for data type commands)
  final int? expectedResponseCode;

  /// Completer to signal command completion
  final Completer<T> completer;

  /// Timeout duration for this command
  final Duration timeout;

  /// Timestamp when command was enqueued
  final DateTime enqueuedAt;

  QueuedCommand({
    required this.data,
    required this.commandCode,
    required this.responseType,
    this.expectedResponseCode,
    required this.completer,
    required this.timeout,
  }) : enqueuedAt = DateTime.now();
}

/// BLE command queue with mutex lock and inter-command delays
///
/// Ensures that:
/// - Only one command executes at a time
/// - 100ms delay between all commands
/// - Commands can wait for ACK or specific responses
/// - Timeouts are enforced
class BleCommandQueue {
  // Queue of pending commands
  final List<QueuedCommand> _queue = [];

  // Mutex lock using Completer
  Completer<void> _lock = Completer<void>()..complete();

  // Whether queue is currently processing
  bool _isProcessing = false;

  // Pending responses mapped by command code
  final Map<int, QueuedCommand> _pendingResponses = {};

  // Last command execution timestamp
  DateTime? _lastCommandTime;

  // Minimum delay between commands (milliseconds)
  static const int _minDelayMs = 100;

  // Callbacks
  VoidCallback? onQueueEmpty;
  void Function(int queueSize)? onQueueSizeChanged;

  /// Enqueue a command and wait for it to complete
  ///
  /// [data] - The command data to send
  /// [commandCode] - Command code (first byte)
  /// [responseType] - Type of response expected
  /// [expectedResponseCode] - For data responses, the expected response code
  /// [timeout] - Maximum time to wait for response
  ///
  /// Returns a Future that completes when the command receives its response
  /// or throws TimeoutException if timeout expires.
  Future<T> enqueue<T>({
    required Uint8List data,
    required int commandCode,
    required CommandResponseType responseType,
    int? expectedResponseCode,
    Duration? timeout,
  }) async {
    // Determine timeout based on response type
    final cmdTimeout =
        timeout ??
        (responseType == CommandResponseType.data
            ? const Duration(seconds: 10)
            : const Duration(seconds: 5));

    // Create queued command
    final command = QueuedCommand<T>(
      data: data,
      commandCode: commandCode,
      responseType: responseType,
      expectedResponseCode: expectedResponseCode,
      completer: Completer<T>(),
      timeout: cmdTimeout,
    );

    // Add to queue
    _queue.add(command);
    onQueueSizeChanged?.call(_queue.length);

    debugPrint(
      '📋 [CommandQueue] Enqueued command 0x${commandCode.toRadixString(16).padLeft(2, '0')} (queue size: ${_queue.length})',
    );

    // Start processing if not already running
    if (!_isProcessing) {
      _processQueue();
    }

    // Wait for command to complete or timeout
    return command.completer.future.timeout(
      cmdTimeout,
      onTimeout: () {
        debugPrint(
          '⏱️ [CommandQueue] Command 0x${commandCode.toRadixString(16).padLeft(2, '0')} timed out after ${cmdTimeout.inSeconds}s',
        );
        _pendingResponses.remove(commandCode);
        throw TimeoutException(
          'Command 0x${commandCode.toRadixString(16).padLeft(2, '0')} timed out',
        );
      },
    );
  }

  /// Process the command queue
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      // Wait for lock
      await _lock.future;

      // Get next command
      final command = _queue.removeAt(0);
      onQueueSizeChanged?.call(_queue.length);

      try {
        // Enforce minimum delay between commands
        if (_lastCommandTime != null) {
          final elapsed = DateTime.now().difference(_lastCommandTime!);
          final remainingDelay = _minDelayMs - elapsed.inMilliseconds;

          if (remainingDelay > 0) {
            debugPrint(
              '⏸️ [CommandQueue] Waiting ${remainingDelay}ms before next command',
            );
            await Future.delayed(Duration(milliseconds: remainingDelay));
          }
        }

        // Create new lock for next command
        _lock = Completer<void>();

        // Register for response if needed
        if (command.responseType != CommandResponseType.none) {
          final responseKey = command.responseType == CommandResponseType.ack
              ? command.commandCode
              : (command.expectedResponseCode ?? command.commandCode);
          _pendingResponses[responseKey] = command;
        }

        // Execute command (handled by BleCommandSender)
        // The completer will be completed by completeCommand() when response arrives
        debugPrint(
          '📤 [CommandQueue] Executing command 0x${command.commandCode.toRadixString(16).padLeft(2, '0')}',
        );

        // For fire-and-forget commands, complete immediately
        if (command.responseType == CommandResponseType.none) {
          command.completer.complete(null);
        }

        // Update last command time
        _lastCommandTime = DateTime.now();

        // Release lock after minimum delay
        Future.delayed(const Duration(milliseconds: _minDelayMs), () {
          if (!_lock.isCompleted) {
            _lock.complete();
          }
        });
      } catch (e) {
        debugPrint('❌ [CommandQueue] Error processing command: $e');
        if (!command.completer.isCompleted) {
          command.completer.completeError(e);
        }
        // Release lock on error
        if (!_lock.isCompleted) {
          _lock.complete();
        }
      }
    }

    _isProcessing = false;
    onQueueEmpty?.call();
    debugPrint('✅ [CommandQueue] Queue empty');
  }

  /// Complete a pending command with response data
  ///
  /// Called by BleResponseHandler when a response is received
  void completeCommand<T>(int responseCode, T data) {
    final command = _pendingResponses.remove(responseCode);
    if (command != null) {
      debugPrint(
        '✅ [CommandQueue] Completing command 0x${command.commandCode.toRadixString(16).padLeft(2, '0')} with response 0x${responseCode.toRadixString(16).padLeft(2, '0')}',
      );
      if (!command.completer.isCompleted) {
        command.completer.complete(data);
      }
    }
  }

  /// Complete a pending command with error
  ///
  /// Called by BleResponseHandler when RESP_CODE_ERR is received
  void completeCommandWithError(
    int commandCode,
    String error, {
    int? errorCode,
  }) {
    final command = _pendingResponses.remove(commandCode);
    if (command != null) {
      debugPrint(
        '❌ [CommandQueue] Command 0x${commandCode.toRadixString(16).padLeft(2, '0')} failed: $error (code: $errorCode)',
      );
      if (!command.completer.isCompleted) {
        command.completer.completeError(
          Exception('Command failed: $error (error code: $errorCode)'),
        );
      }
    }
  }

  /// Get current queue size
  int get queueSize => _queue.length;

  /// Get number of pending responses
  int get pendingResponseCount => _pendingResponses.length;

  /// Check if queue is empty
  bool get isEmpty => _queue.isEmpty;

  /// Check if queue is processing
  bool get isProcessing => _isProcessing;

  /// Clear all pending commands (use with caution)
  void clear() {
    debugPrint(
      '🗑️ [CommandQueue] Clearing queue (${_queue.length} commands, ${_pendingResponses.length} pending responses)',
    );

    // Complete all pending commands with error
    for (final command in _pendingResponses.values) {
      if (!command.completer.isCompleted) {
        command.completer.completeError(Exception('Queue cleared'));
      }
    }

    _queue.clear();
    _pendingResponses.clear();
    onQueueSizeChanged?.call(0);
  }

  /// Dispose resources
  void dispose() {
    clear();
    if (!_lock.isCompleted) {
      _lock.complete();
    }
  }
}
