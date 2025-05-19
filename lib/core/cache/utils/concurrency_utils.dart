import 'dart:async';

/// A simple lock for ensuring exclusive access to a resource
class Lock {
  Completer<void>? _completer;

  /// Acquires the lock and returns a function that releases it
  Future<void Function()> acquire() async {
    // Wait for any existing lock to be released
    while (_completer != null) {
      await _completer!.future;
    }

    // Create a new lock
    _completer = Completer<void>();

    // Return a function that releases the lock
    return () {
      final completer = _completer;
      _completer = null;
      completer?.complete();
    };
  }

  /// Executes a function with the lock acquired
  Future<T> synchronized<T>(Future<T> Function() function) async {
    final release = await acquire();
    try {
      return await function();
    } finally {
      release();
    }
  }
}

/// Manages a work queue with a limited number of concurrent jobs
class WorkQueue {
  final int _concurrency;
  final List<Future Function()> _queue = [];
  int _activeCount = 0;
  final Completer<void> _allComplete = Completer<void>();
  bool _isProcessing = false;

  /// Creates a new work queue with the specified maximum concurrency
  WorkQueue(this._concurrency);

  /// Adds a job to the queue and returns a future that completes when the job completes
  Future<T> add<T>(Future<T> Function() job) {
    final completer = Completer<T>();
    
    _queue.add(() async {
      try {
        completer.complete(await job());
      } catch (e, stackTrace) {
        completer.completeError(e, stackTrace);
      }
      return completer.future;
    });
    
    _processQueue();
    
    return completer.future;
  }

  /// Returns a future that completes when all jobs in the queue have completed
  Future<void> get onAllComplete => _allComplete.future;

  /// Processes the queue, respecting the concurrency limit
  void _processQueue() {
    if (_isProcessing) return;
    _isProcessing = true;

    // Execute this outside the current execution context
    Future.microtask(() {
      _executeNext();
    });
  }

  /// Executes the next job in the queue if concurrency limit allows
  void _executeNext() async {
    // If queue is empty and no active jobs, we're done
    if (_queue.isEmpty && _activeCount == 0 && !_allComplete.isCompleted) {
      _allComplete.complete();
      _isProcessing = false;
      return;
    }
    
    // If we've reached concurrency limit or queue is empty, wait
    if (_activeCount >= _concurrency || _queue.isEmpty) {
      _isProcessing = false;
      return;
    }

    // Take the next job from the queue
    final job = _queue.removeAt(0);
    _activeCount++;

    // Execute the job
    job().then((_) {
      _activeCount--;
      _executeNext();
    }).catchError((e) {
      _activeCount--;
      _executeNext();
    });

 // Mark processing as done - next job will start the process again
 _isProcessing = false;
 
 // If we can still process more, schedule another processing cycle
 if (_activeCount < _concurrency && _queue.isNotEmpty) {
   _processQueue();
 }
  }
}
