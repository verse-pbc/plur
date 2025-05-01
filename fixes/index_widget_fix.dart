import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/group_read_status_provider.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';

/// This class provides the necessary providers for the group feed functionality
/// It should be placed high in the widget tree, preferably at the root
class GroupProviderRoot extends StatelessWidget {
  final Widget child;
  
  const GroupProviderRoot({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Get the list provider from the context
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    
    // Create the full provider tree with proper dependencies
    return MultiProvider(
      providers: [
        // Group Read Status Provider
        ChangeNotifierProvider<GroupReadStatusProvider>(
          create: (context) {
            final provider = GroupReadStatusProvider();
            // Initialize it
            provider.init();
            return provider;
          },
        ),
        
        // Group Feed Provider that depends on both ListProvider and GroupReadStatusProvider
        Consumer<GroupReadStatusProvider>(
          builder: (context, readStatusProvider, _) {
            return ChangeNotifierProxyProvider<GroupReadStatusProvider, GroupFeedProvider>(
              create: (context) => GroupFeedProvider(listProvider, readStatusProvider),
              update: (context, readStatus, previous) {
                if (previous == null) {
                  return GroupFeedProvider(listProvider, readStatus);
                }
                return previous;
              },
              child: child,
            );
          },
        ),
      ],
    );
  }
}

/// Extension to add GroupProviders to a MaterialApp easily
extension GroupProvidersExtension on MaterialApp {
  /// Wraps the app with all necessary group providers
  MaterialApp withGroupProviders() {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: GroupProviderRoot(
        child: this,
      ),
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      title: title,
      onGenerateRoute: onGenerateRoute,
      routes: routes,
      initialRoute: initialRoute,
      navigatorObservers: navigatorObservers,
      builder: builder,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      showSemanticsDebugger: showSemanticsDebugger,
      checkerboardOffscreenLayers: checkerboardOffscreenLayers,
      checkerboardRasterCacheImages: checkerboardRasterCacheImages,
    );
  }
}