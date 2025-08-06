part of logger_flutter_ns_v1;

ListQueue<OutputEvent> _outputEventBuffer = ListQueue();

Function(OutputEvent)? _outputListener;
final logger = Logger(
  filter: _Filter(),
  printer: HybridPrinter(
    SimplerPrinter(),
    error: PrettyPrinter(printEmojis: false, printTime: true, methodCount: 4, colors: false),
  ),
  output: _ConsoleOutput(),
);

class _Filter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

class _ConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    _outputEventBuffer.add(event);
    _outputListener?.call(event);
    log(event.lines.fold('', (p, e) => '$p\n$e'));
  }
}

// Clear logs fonksiyonu
void clearLogs() {
  _outputEventBuffer.clear();
}

class LogConsole extends StatefulWidget {
  final bool dark;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const LogConsole({super.key, this.dark = false, this.showCloseButton = false, this.onClose});

  @override
  _LogConsoleState createState() => _LogConsoleState();
}

class RenderedEvent {
  final int id;
  final Level level;
  final TextSpan span;
  final String lowerCaseText;
  final bool isJsonResponse;
  final Map<String, dynamic>? jsonData;
  final String? title;

  RenderedEvent(this.id, this.level, this.span, this.lowerCaseText, {this.isJsonResponse = false, this.jsonData, this.title});
}

class _LogConsoleState extends State<LogConsole> {
  final ListQueue<RenderedEvent> _renderedBuffer = ListQueue();
  List<RenderedEvent> _filteredBuffer = [];

  final _scrollController = ScrollController();
  final _filterController = TextEditingController();

  double _logFontSize = 14;

  var _currentId = 0;
  bool _scrollListenerEnabled = true;
  bool _followBottom = true;

  @override
  void initState() {
    super.initState();
    _outputListener = (e) {
      _renderedBuffer.add(_renderEvent(e));
      _refreshFilter();
    };

    _scrollController.addListener(() {
      if (!_scrollListenerEnabled) return;
      var scrolledToBottom = _scrollController.offset >= _scrollController.position.maxScrollExtent;
      setState(() {
        _followBottom = scrolledToBottom;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _renderedBuffer.clear();
    for (var event in _outputEventBuffer) {
      _renderedBuffer.add(_renderEvent(event));
    }
    _refreshFilter();
  }

  void _refreshFilter() {
    var newFilteredBuffer = _renderedBuffer.where((it) {
      if (_filterController.text.isNotEmpty) {
        var filterText = _filterController.text.toLowerCase();
        return it.lowerCaseText.contains(filterText);
      } else {
        return true;
      }
    }).toList();
    setState(() {
      _filteredBuffer = newFilteredBuffer;
    });

    if (_followBottom) {
      Future.delayed(Duration.zero, _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTopBar(),
              Expanded(
                child: _buildLogContent(context),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
        floatingActionButton: AnimatedOpacity(
          opacity: _followBottom ? 0 : 1,
          duration: Duration(milliseconds: 150),
          child: Padding(
            padding: EdgeInsets.only(bottom: 60),
            child: FloatingActionButton(
              mini: true,
              clipBehavior: Clip.antiAlias,
              child: Icon(
                Icons.arrow_downward,
                color: widget.dark ? Colors.white : Colors.lightBlue[900],
              ),
              onPressed: _scrollToBottom,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogContent(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 1600,
        child: SelectionArea(
          child: ListView.builder(
            controller: _scrollController,
            itemBuilder: (context, index) {
              var logEntry = _filteredBuffer[index];
              if (logEntry.isJsonResponse && logEntry.jsonData != null) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _buildExpandableJsonWidget(logEntry),
                );
              } else {
                return Text.rich(
                  logEntry.span,
                  key: Key(logEntry.id.toString()),
                  style: TextStyle(fontSize: _logFontSize),
                );
              }
            },
            itemCount: _filteredBuffer.length,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableJsonWidget(RenderedEvent logEntry) {
    return _JsonExpandableWidget(
      logEntry: logEntry,
      fontSize: _logFontSize,
      dark: widget.dark,
    );
  }

  Widget _buildTopBar() {
    return LogBar(
      dark: widget.dark,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Text(
            "Log Console",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              setState(() {
                _logFontSize++;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.remove),
            onPressed: () {
              setState(() {
                _logFontSize--;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: () {
              clearLogs();
              setState(() {
                _renderedBuffer.clear();
                _filteredBuffer.clear();
              });
            },
          ),
          if (widget.showCloseButton)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                widget.onClose?.call();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return LogBar(
      dark: widget.dark,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: TextField(
              style: TextStyle(fontSize: 20),
              controller: _filterController,
              onChanged: (s) => _refreshFilter(),
              decoration: InputDecoration(
                labelText: "Filter log output",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(width: 20),
          IconButton(
            onPressed: _export,
            icon: Icon(Icons.description),
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    StringBuffer sb = StringBuffer();
    _outputEventBuffer.toList().forEach((event) {
      sb.writeln(event.lines.join('\n'));
    });
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.log';
    final file = File(filePath);

    await file.writeAsString(sb.toString());
    Share.shareFiles([filePath]);
  }

  void _scrollToBottom() async {
    _scrollListenerEnabled = false;

    setState(() {
      _followBottom = true;
    });

    var scrollPosition = _scrollController.position;
    await _scrollController.animateTo(
      scrollPosition.maxScrollExtent,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );

    _scrollListenerEnabled = true;
  }

  RenderedEvent _renderEvent(OutputEvent event) {
    var parser = AnsiParser(widget.dark);
    var text = event.lines.join('\n');
    
    // JSON response kontrolü
    bool isJsonResponse = false;
    Map<String, dynamic>? jsonData;
    String? title;
    
    try {
      // Basit JSON tespit - sadece { ile başlayan ve } ile biten
      if (text.trim().startsWith('{') && text.trim().endsWith('}')) {
        jsonData = jsonDecode(text.trim()) as Map<String, dynamic>;
        isJsonResponse = true;
        print('JSON detected in log: ${jsonData.keys.take(3).toList()}');
      } else if (text.contains('{') && text.contains('}')) {
        // İçinde JSON olan log - daha esnek tespit
        var jsonStart = text.indexOf('{');
        var jsonEnd = text.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          var jsonText = text.substring(jsonStart, jsonEnd + 1);
          // JSON formatını kontrol et - daha esnek
          if (jsonText.contains('"') && jsonText.contains(':')) {
            // JSON parse edilebilir mi kontrol et
            try {
              var testJson = jsonDecode(jsonText);
              if (testJson is Map) {
                jsonData = testJson as Map<String, dynamic>;
                isJsonResponse = true;
                print('JSON detected in log: ${jsonData.keys.take(3).toList()}');
                
                // Log başındaki açıklamayı çıkar
                if (jsonStart > 0) {
                  title = text.substring(0, jsonStart).trim();
                }
              }
            } catch (e) {
              // JSON parse edilemez, devam et
            }
          }
        }
      }
    } catch (e) {
      // JSON parse hatası, normal log olarak göster
      print('JSON parse error: $e');
    }
    
    parser.parse(text);
    
    // Debug için JSON tespit bilgisi
    if (isJsonResponse) {
      print('JSON Response detected: ${jsonData?.keys.take(3).toList()}');
    }
    
    return RenderedEvent(
      _currentId++,
      event.level,
      TextSpan(children: parser.spans),
      text.toLowerCase(),
      isJsonResponse: isJsonResponse,
      jsonData: jsonData,
      title: title,
    );
  }

  @override
  void dispose() {
    _outputListener = null;
    super.dispose();
  }
}

class _JsonExpandableWidget extends StatefulWidget {
  final RenderedEvent logEntry;
  final double fontSize;
  final bool dark;

  const _JsonExpandableWidget({
    required this.logEntry,
    required this.fontSize,
    required this.dark,
  });

  @override
  State<_JsonExpandableWidget> createState() => _JsonExpandableWidgetState();
}

class _JsonExpandableWidgetState extends State<_JsonExpandableWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Row(
            children: [
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: widget.dark ? Colors.white : Colors.black,
              ),
              SizedBox(width: 8),
              Text(
                widget.logEntry.title ?? 'JSON Response (${widget.logEntry.jsonData?.keys.length ?? 0} keys)',
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.bold,
                  color: widget.dark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        if (_isExpanded) ...[
          SizedBox(height: 8),
          _buildJsonContent(),
        ],
      ],
    );
  }

  Widget _buildJsonContent() {
    if (widget.logEntry.jsonData == null) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(left: 20),
      child: _buildJsonTree(widget.logEntry.jsonData!, 0),
    );
  }

  Widget _buildJsonTree(dynamic data, int depth) {
    if (data is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          return _buildJsonEntry(entry.key, entry.value, depth);
        }).toList(),
      );
    } else if (data is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.asMap().entries.map((entry) {
          return _buildJsonEntry('[${entry.key}]', entry.value, depth);
        }).toList(),
      );
    } else {
      return Text(
        data.toString(),
        style: TextStyle(
          fontSize: widget.fontSize - 2,
          color: widget.dark ? Colors.white70 : Colors.black87,
        ),
      );
    }
  }

  Widget _buildJsonEntry(String key, dynamic value, int depth) {
    bool isExpandable = value is Map || value is List;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isExpandable)
          _JsonExpandableEntry(
            entryKey: key,
            value: value,
            depth: depth,
            fontSize: widget.fontSize,
            dark: widget.dark,
          )
        else
          Padding(
            padding: EdgeInsets.only(left: depth * 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$key: ',
                  style: TextStyle(
                    fontSize: widget.fontSize - 2,
                    fontWeight: FontWeight.bold,
                    color: widget.dark ? Colors.blue[300] : Colors.blue[700],
                  ),
                ),
                Expanded(
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: widget.fontSize - 2,
                      color: widget.dark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _JsonExpandableEntry extends StatefulWidget {
  final String entryKey;
  final dynamic value;
  final int depth;
  final double fontSize;
  final bool dark;

  const _JsonExpandableEntry({
    required this.entryKey,
    required this.value,
    required this.depth,
    required this.fontSize,
    required this.dark,
  });

  @override
  State<_JsonExpandableEntry> createState() => _JsonExpandableEntryState();
}

class _JsonExpandableEntryState extends State<_JsonExpandableEntry> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: EdgeInsets.only(left: widget.depth * 16.0),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: widget.dark ? Colors.white70 : Colors.black54,
                ),
                SizedBox(width: 4),
                Text(
                  widget.entryKey,
                  style: TextStyle(
                    fontSize: widget.fontSize - 2,
                    fontWeight: FontWeight.bold,
                    color: widget.dark ? Colors.blue[300] : Colors.blue[700],
                  ),
                ),
                Text(
                  widget.value is Map ? ' {...}' : ' [...]',
                  style: TextStyle(
                    fontSize: widget.fontSize - 2,
                    color: widget.dark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: (widget.depth + 1) * 16.0),
            child: _buildExpandedContent(),
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedContent() {
    if (widget.value is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (widget.value as Map<String, dynamic>).entries.map((entry) {
          return _buildSimpleEntry(entry.key, entry.value);
        }).toList(),
      );
    } else if (widget.value is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (widget.value as List).asMap().entries.map((entry) {
          return _buildSimpleEntry('[${entry.key}]', entry.value);
        }).toList(),
      );
    } else {
      return Text(
        widget.value.toString(),
        style: TextStyle(
          fontSize: widget.fontSize - 2,
          color: widget.dark ? Colors.white70 : Colors.black87,
        ),
      );
    }
  }

  Widget _buildSimpleEntry(String key, dynamic value) {
    bool isExpandable = value is Map || value is List;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isExpandable)
          _JsonExpandableEntry(
            entryKey: key,
            value: value,
            depth: widget.depth + 1,
            fontSize: widget.fontSize,
            dark: widget.dark,
          )
        else
          Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$key: ',
                  style: TextStyle(
                    fontSize: widget.fontSize - 2,
                    fontWeight: FontWeight.bold,
                    color: widget.dark ? Colors.blue[300] : Colors.blue[700],
                  ),
                ),
                Expanded(
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: widget.fontSize - 2,
                      color: widget.dark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class LogBar extends StatelessWidget {
  final bool dark;
  final Widget child;

  const LogBar({super.key, required this.dark, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            if (!dark)
              BoxShadow(
                color: Colors.grey.shade400,
                blurRadius: 3,
              ),
          ],
        ),
        child: Material(
          color: dark ? Colors.blueGrey.shade900 : Colors.white,
          child: Padding(
            padding: EdgeInsets.fromLTRB(15, 8, 15, 8),
            child: child,
          ),
        ),
      ),
    );
  }
} 