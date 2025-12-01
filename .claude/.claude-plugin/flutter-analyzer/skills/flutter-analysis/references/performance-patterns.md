# Flutter Performance Patterns

Comprehensive guide to Flutter performance optimization, covering widget rebuilds, memory management, and async patterns.

## Widget Rebuild Optimization

### The Cost of Rebuilds

Every `setState` call triggers `build()` for the widget and all descendants. Minimize rebuild scope for smooth 60fps.

### setState Scope Reduction

**Problem**: Entire widget tree rebuilds for localized state changes.

```dart
// BAD - Rebuilds entire page for counter change
class _MyPageState extends State<MyPage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ExpensiveWidget(),        // Rebuilds unnecessarily!
          Text('Count: $_counter'),  // Only this needs update
          AnotherExpensiveWidget(), // Rebuilds unnecessarily!
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _counter++),
      ),
    );
  }
}
```

**Solution**: Extract stateful logic to smallest possible widget:

```dart
// GOOD - Only CounterDisplay rebuilds
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ExpensiveWidget(),   // Never rebuilds (const)
          CounterDisplay(),          // Only this rebuilds
          const AnotherExpensiveWidget(),
        ],
      ),
    );
  }
}

class CounterDisplay extends StatefulWidget { ... }
```

### Const Constructors

**Problem**: Widgets without `const` rebuild every time parent rebuilds.

```dart
// BAD - Creates new instance every build
Container(
  child: Text('Hello'),  // New Text every time
)

// GOOD - Compile-time constant, never rebuilds
const Container(
  child: Text('Hello'),
)
```

**Detection**:
- Look for widgets that could be `const` but aren't
- Check `Text`, `Icon`, `SizedBox`, `Padding` with literal values

### Keys for Widget Identity

**Problem**: Flutter recreates widgets unnecessarily in lists.

```dart
// BAD - No keys, Flutter may rebuild wrong widgets
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)

// GOOD - Keys help Flutter identify which widgets changed
ListView(
  children: items.map((item) => ItemWidget(key: ValueKey(item.id), item: item)).toList(),
)
```

## Build Method Anti-Patterns

### Object Creation in Build

**Problem**: Creating expensive objects during build.

```dart
// BAD - New controller every build (causes bugs too)
Widget build(BuildContext context) {
  final controller = TextEditingController();
  return TextField(controller: controller);
}

// GOOD - Initialize once
late final TextEditingController _controller;

@override
void initState() {
  super.initState();
  _controller = TextEditingController();
}

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

### Expensive Computations in Build

**Problem**: Complex calculations run on every frame.

```dart
// BAD - Recomputes every build
Widget build(BuildContext context) {
  final sortedItems = items..sort((a, b) => complexComparison(a, b));
  final filteredItems = sortedItems.where(expensiveFilter).toList();
  return ListView(children: filteredItems.map(buildItem).toList());
}

// GOOD - Memoize expensive operations
List<Item>? _cachedItems;
List<Item>? _lastInput;

List<Item> get processedItems {
  if (_lastInput != items) {
    _cachedItems = items..sort((a, b) => complexComparison(a, b));
    _cachedItems = _cachedItems!.where(expensiveFilter).toList();
    _lastInput = items;
  }
  return _cachedItems!;
}
```

### Anonymous Functions in Build

**Problem**: New function instances prevent widget reuse.

```dart
// BAD - New function every build
ElevatedButton(
  onPressed: () => handleClick(item),
  child: Text('Click'),
)

// BETTER - Method reference (still not const, but clearer)
ElevatedButton(
  onPressed: _handleClick,
  child: const Text('Click'),
)

// BEST for lists - Use builder pattern
ListView.builder(
  itemBuilder: (context, index) => ItemWidget(
    item: items[index],
    onTap: () => _handleItemTap(items[index]),
  ),
)
```

## Memory Management

### Undisposed Controllers

**Problem**: Controllers and subscriptions not cleaned up.

```dart
// MEMORY LEAK
class _MyWidgetState extends State<MyWidget> {
  final _controller = StreamController<int>();
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = someStream.listen(_handleData);
  }

  // Missing dispose!
}

// CORRECT
@override
void dispose() {
  _controller.close();
  _subscription.cancel();
  super.dispose();
}
```

**Common Resources to Dispose**:
- `TextEditingController`
- `AnimationController`
- `ScrollController`
- `FocusNode`
- `StreamController`
- `StreamSubscription`
- `Timer`

### Retained BuildContext

**Problem**: Storing BuildContext beyond widget lifecycle.

```dart
// DANGEROUS - Context may be invalid when callback runs
void _saveContext() {
  _savedContext = context;
  Future.delayed(Duration(seconds: 5), () {
    Navigator.of(_savedContext!).pop();  // May crash!
  });
}

// SAFE - Check mounted before using context
Future.delayed(Duration(seconds: 5), () {
  if (mounted) {
    Navigator.of(context).pop();
  }
});
```

### Image Memory

**Problem**: Large images consuming excessive memory.

```dart
// BAD - Full resolution image in small container
Image.network(
  'https://example.com/huge-image.jpg',
  width: 100,
  height: 100,
)

// GOOD - Resize at source or use cacheWidth/cacheHeight
Image.network(
  'https://example.com/huge-image.jpg',
  width: 100,
  height: 100,
  cacheWidth: 200,  // 2x for retina
  cacheHeight: 200,
)
```

### List View Optimization

**Problem**: Creating all list items at once.

```dart
// BAD - All 10,000 items created immediately
ListView(
  children: hugeList.map((item) => ExpensiveWidget(item)).toList(),
)

// GOOD - Only visible items created
ListView.builder(
  itemCount: hugeList.length,
  itemBuilder: (context, index) => ExpensiveWidget(hugeList[index]),
)
```

## Async Patterns

### Blocking the Main Thread

**Problem**: Expensive sync operations on UI thread.

```dart
// BAD - Blocks UI
void _processData() {
  final result = expensiveOperation(largeData);  // UI frozen!
  setState(() => _result = result);
}

// GOOD - Use compute for CPU-intensive work
void _processData() async {
  final result = await compute(expensiveOperation, largeData);
  if (mounted) {
    setState(() => _result = result);
  }
}
```

### FutureBuilder Anti-Patterns

**Problem**: Creating future in build method.

```dart
// BAD - New future every build, infinite rebuilds!
Widget build(BuildContext context) {
  return FutureBuilder(
    future: fetchData(),  // Called every build!
    builder: (context, snapshot) => ...,
  );
}

// GOOD - Create future once
late final Future<Data> _dataFuture;

@override
void initState() {
  super.initState();
  _dataFuture = fetchData();
}

Widget build(BuildContext context) {
  return FutureBuilder(
    future: _dataFuture,  // Same future reference
    builder: (context, snapshot) => ...,
  );
}
```

### Unnecessary Async

**Problem**: Making synchronous code async for no reason.

```dart
// BAD - Unnecessary async overhead
Future<String> getName() async {
  return _name;  // Just returning a value!
}

// GOOD - Sync when possible
String get name => _name;
```

## Animation Performance

### Ticker Outside Visible Widgets

**Problem**: Animations running when widget not visible.

```dart
// BAD - Animation continues off-screen
class _MyWidgetState extends State<MyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)..repeat();
  }
  // Animation runs forever, even when widget scrolled off-screen
}

// BETTER - Use VisibilityDetector or check mounted
```

### RepaintBoundary for Animations

**Problem**: Animations cause entire tree to repaint.

```dart
// Animation causes parent repaints
Stack(
  children: [
    ExpensiveBackground(),
    AnimatedWidget(),  // This animation repaints everything
  ],
)

// BETTER - Isolate animated widget
Stack(
  children: [
    ExpensiveBackground(),
    RepaintBoundary(
      child: AnimatedWidget(),  // Repaints only this subtree
    ),
  ],
)
```

## Platform-Specific Performance

### Skia vs Impeller

As of Flutter 3.16+, Impeller is the default on iOS. Check for:
- Custom shaders compatibility
- Image filter performance differences
- Path rendering behavior

### Android Specific

```dart
// Reduce overdraw
debugRepaintRainbowEnabled = true;  // Visualize repaints

// Check for saveLayer calls (expensive)
// Opacity, ClipRRect with high radius, and shadows use saveLayer
```

## Profiling Commands

Use these tools to identify issues:

```bash
# Run in profile mode
flutter run --profile

# Performance overlay
flutter run --profile --trace-systrace

# Generate timeline
flutter run --profile --trace-skia
```

In DevTools:
- **Performance tab**: CPU flame charts
- **Memory tab**: Heap snapshots, allocations
- **Widget rebuild stats**: Enable in DevTools settings

## Checklist

Performance review checklist:

- [ ] setState scoped to smallest widget
- [ ] Const constructors used where possible
- [ ] No object creation in build methods
- [ ] Expensive computations memoized
- [ ] All controllers disposed
- [ ] ListView.builder for long lists
- [ ] Images sized appropriately with cache dimensions
- [ ] CPU work offloaded with compute()
- [ ] FutureBuilder futures created in initState
- [ ] Animations paused when not visible
- [ ] RepaintBoundary for isolated animations
