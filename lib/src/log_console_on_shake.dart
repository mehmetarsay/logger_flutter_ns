part of logger_flutter_ns_v1;

class LogConsoleOnShake extends StatefulWidget {
  final Widget child;
  final bool debugOnly;
  final Key? key;
  final bool showDraggableButton;
  final Color buttonColor;
  final double buttonSize;
  final Offset initialButtonPosition;

  LogConsoleOnShake({
    required this.child,
    this.debugOnly = true,
    this.key,
    this.showDraggableButton = true,
    this.buttonColor = Colors.blue,
    this.buttonSize = 50.0,
    this.initialButtonPosition = const Offset(20, 100),
  }) : super(key: key);

  @override
  _LogConsoleOnShakeState createState() => _LogConsoleOnShakeState();
}

class _LogConsoleOnShakeState extends State<LogConsoleOnShake> {
  ShakeDetector? _detector;
  bool _open = false;
  OverlayEntry? _overlayEntry;
  static final Set<Key> _activeKeys = {};

  bool _showDraggableButton = false;
  Offset _buttonPosition = const Offset(20, 100);

  @override
  void initState() {
    super.initState();

    _buttonPosition = widget.initialButtonPosition;

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
    return Stack(
      children: [
        widget.child,
        if (_showDraggableButton)
          Positioned(
            left: _buttonPosition.dx,
            top: _buttonPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  final newX = _buttonPosition.dx + details.delta.dx;
                  final newY = _buttonPosition.dy + details.delta.dy;

                  final screenWidth = MediaQuery.of(context).size.width;
                  final screenHeight = MediaQuery.of(context).size.height;

                  _buttonPosition = Offset(
                    newX.clamp(0, screenWidth - widget.buttonSize),
                    newY.clamp(0, screenHeight - widget.buttonSize),
                  );
                });
              },
              onTap: _openLogConsole,
              child: Container(
                width: widget.buttonSize,
                height: widget.buttonSize,
                decoration: BoxDecoration(
                  color: widget.buttonColor.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bug_report,
                  color: Colors.white,
                  size: widget.buttonSize * 0.48,
                ),
              ),
            ),
          ),
      ],
    );
  }

  _init() {
    if (!mounted) return;

    _detector = ShakeDetector(onPhoneShake: _openLogConsole);
    _detector?.startListening();

    if (widget.showDraggableButton || !(_detector?.isListening ?? false)) {
      setState(() {
        _showDraggableButton = true;
      });
    }
  }

  _openLogConsole() {
    if (_open || !mounted) return;

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
        color: Colors.black.withOpacity(0.9),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Theme(
              data: ThemeData.dark().copyWith(
                textTheme: ThemeData.dark().textTheme.apply(
                      bodyColor: Colors.white,
                      displayColor: Colors.white,
                    ),
              ),
              child: logConsole,
            ),
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
      try {
        _overlayEntry!.remove();
      } catch (e) {}
      _overlayEntry = null;
    }
    _open = false;
  }

  @override
  void dispose() {
    if (_detector != null) {
      _detector!.stopListening();
      _detector = null;
    }

    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
      } catch (e) {}
      _overlayEntry = null;
    }

    if (widget.key != null) {
      _activeKeys.remove(widget.key);
    }

    super.dispose();
  }
}
