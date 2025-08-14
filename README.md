# logger_flutter_ns_v1

Nullsafe version for for [logger_flutter](https://github.com/leisim/logger).<br>
Flutter extension for [logger](https://github.com/leisim/logger).<br>
Please go to there for documentation.

## Usage Example

### Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  logger_flutter_ns: ^1.0.1
```

### Basic Usage

```dart
import 'package:logger_flutter_ns/logger_flutter_ns.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LogConsoleOnShake(
        debugOnly: true, // Only works in debug mode
        showDraggableButton: true, // Shows draggable button
        child: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final logger = Logger(
    printer: SimplePrinter(),
    output: LogConsoleOutput(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logger Flutter NS Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                logger.d('Debug message');
              },
              child: Text('Debug Log'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                logger.i('Info message');
              },
              child: Text('Info Log'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                logger.w('Warning message');
              },
              child: Text('Warning Log'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                logger.e('Error message');
              },
              child: Text('Error Log'),
            ),
          ],
        ),
      ),
    );
  }
}

### Features

- **LogConsoleOnShake**: Opens log console by shaking the device
- **LogConsoleOutput**: Displays logs in Flutter console
- **SimplePrinter**: Simple log format printer
- **ANSI Parser**: Parses ANSI codes for colored log output

### LogConsoleOnShake Parameters

- **debugOnly** (bool, default: true): Only works in debug mode. Disabled in release mode.
- **showDraggableButton** (bool, default: true): Shows a draggable button on screen. You can manually open the log console using this button.
- **child** (Widget): The main widget to be displayed inside LogConsoleOnShake widget.

### Usage Examples

```dart
// Only in debug mode with draggable button
LogConsoleOnShake(
  debugOnly: true,
  showDraggableButton: true,
  child: MyApp(),
)

// Works always (debug and release)
LogConsoleOnShake(
  debugOnly: false,
  showDraggableButton: true,
  child: MyApp(),
)

// Only shake to work, don't show button
LogConsoleOnShake(
  debugOnly: true,
  showDraggableButton: false,
  child: MyApp(),
)
```

### Log Levels

- `logger.v()` - Verbose
- `logger.d()` - Debug
- `logger.i()` - Info
- `logger.w()` - Warning
- `logger.e()` - Error
- `logger.wtf()` - What a Terrible Failure
