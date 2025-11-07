import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/error_handler.dart';
import '../utils/error_reporter.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    final appEx = ErrorHandler.handle(error, stackTrace: stackTrace, context: 'Bloc:${bloc.runtimeType}');
    ErrorReporter.reportNow(appEx);
    super.onError(bloc, error, stackTrace);
  }
}


