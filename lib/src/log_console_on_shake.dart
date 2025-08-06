part of logger_flutter_ns_v1;

ValueNotifier<bool> _logConsoleOpen = ValueNotifier<bool>(false);

void _openLogConsole() => _logConsoleOpen.value = true;
void _hideLogConsole() => _logConsoleOpen.value = false;

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
  bool _showDraggableButton = false;
  Offset _buttonPosition = const Offset(20, 100);

  @override
  void initState() {
    super.initState();
    _buttonPosition = widget.initialButtonPosition;
    if (widget.debugOnly && !kDebugMode) return;
    _init();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.debugOnly && !kDebugMode) return widget.child;
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
        ValueListenableBuilder(
          valueListenable: _logConsoleOpen,
          builder: (context, isOpen, child) {
            return isOpen
                ? LogConsole(
                    showCloseButton: true,
                    dark: Theme.of(context).brightness == Brightness.dark,
                    onClose: _hideLogConsole,
                  )
                : SizedBox.shrink();
          },
        ),
      ],
    );
  }

  _init() {
    if (!mounted) return;
    _detector = ShakeDetector(onPhoneShake: _openLogConsole);
    _detector?.startListening();
    if (widget.showDraggableButton || !(_detector?.isListening ?? false)) {
      setState(() => _showDraggableButton = true);
    }
  }

  @override
  void dispose() {
    if (_detector != null) {
      _detector!.stopListening();
      _detector = null;
    }
    super.dispose();
  }
}
