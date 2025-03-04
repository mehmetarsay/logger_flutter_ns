part of logger_flutter_ns;

class LogConsoleOnShake extends StatefulWidget {
  final Widget child;
  final bool debugOnly;
  final Key? key;

  LogConsoleOnShake({
    required this.child,
    this.debugOnly = true,
    this.key,
  }) : super(key: key);

  @override
  _LogConsoleOnShakeState createState() => _LogConsoleOnShakeState();
}

class _LogConsoleOnShakeState extends State<LogConsoleOnShake> {
  late ShakeDetector _detector;
  bool _open = false;
  OverlayEntry? _overlayEntry;
  static final Set<Key> _activeKeys = {};

  @override
  void initState() {
    super.initState();

    if (widget.debugOnly) {
      assert(() {
        _init();
        return true;
      }());
    } else {
      _init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  _init() {
    _detector = ShakeDetector(onPhoneShake: _openLogConsole);
    _detector.startListening();
  }

  _openLogConsole() {
    if (_open) return;

    if (widget.key != null && _activeKeys.contains(widget.key)) {
      return;
    }

    if (widget.key != null) {
      _activeKeys.add(widget.key!);
    }

    _open = true;

    var logConsole = LogConsole(
      showCloseButton: true,
      dark: Theme.of(context).brightness == Brightness.dark,
      onClose: _closeLogConsole,
    );

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.5),
        child: SafeArea(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: logConsole,
          ),
        ),
      ),
    );

    if (context.mounted) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  _closeLogConsole() {
    if (widget.key != null) {
      _activeKeys.remove(widget.key);
    }

    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _open = false;
  }

  @override
  void dispose() {
    _detector.stopListening();
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }

    if (widget.key != null) {
      _activeKeys.remove(widget.key);
    }

    super.dispose();
  }
}
