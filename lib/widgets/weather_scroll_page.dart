import 'package:flutter/material.dart';
import '../services/location_service.dart';

typedef RefreshWeatherCallback = Future<void> Function(
  CurrentLocationInfo location,
);

class WeatherScrollPage extends StatefulWidget {
  final String temperatureText;
  final String conditionText;
  final Widget content;

  // Connect this to your existing weather provider/API.
  final RefreshWeatherCallback onRefreshWeather;

  final Widget? leading;
  final List<Widget> actions;

  final Color headerColor;

  const WeatherScrollPage({
    super.key,
    required this.temperatureText,
    required this.conditionText,
    required this.content,
    required this.onRefreshWeather,
    this.leading,
    this.actions = const [],
    this.headerColor = const Color(0xFF17324D),
  });

  @override
  State<WeatherScrollPage> createState() =>
      _WeatherScrollPageState();
}

class _WeatherScrollPageState extends State<WeatherScrollPage> {
  static const double _expandedHeight = 260;
  static const double _collapseDistance =
      _expandedHeight - kToolbarHeight;

  final ScrollController _scrollController = ScrollController();

  // Changes from 0 (expanded) to 1 (fully collapsed).
  final ValueNotifier<double> _collapseProgress =
      ValueNotifier<double>(0);

  CurrentLocationInfo? _location;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScroll);

    // Load the current location and weather when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshWeatherAndLocation(showError: false);
      }
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final progress = (_scrollController.offset /
            _collapseDistance)
        .clamp(0.0, 1.0)
        .toDouble();

    // Avoid unnecessary rebuilds for tiny scroll differences.
    if ((progress - _collapseProgress.value).abs() > 0.005) {
      _collapseProgress.value = progress;
    }
  }

  Future<void> _refreshWeatherAndLocation({
    bool showError = true,
  }) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // 1. Get the latest device location.
      final newLocation =
          await LocationService.getCurrentLocation();

      if (!mounted) return;

      setState(() => _location = newLocation);

      // 2. Refresh your existing weather data using that location.
      await widget.onRefreshWeather(newLocation);
    } catch (error) {
      if (mounted && showError) {
        final message = error
            .toString()
            .replaceFirst('Exception: ', '');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _loadingIndicator(Color color) {
    if (!_isLoading) return const SizedBox.shrink();

    return SizedBox(
      width: 13,
      height: 13,
      child: CircularProgressIndicator(
        strokeWidth: 1.8,
        color: color,
      ),
    );
  }

  Widget _expandedWeatherHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: Colors.white,
              size: 17,
            ),
            const SizedBox(width: 5),

            Expanded(
              child: Text(
                _location?.placeName ?? 'Finding location...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            _loadingIndicator(Colors.white),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.temperatureText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                height: 1.0,
                fontWeight: FontWeight.w600,
                letterSpacing: -1.5,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                widget.conditionText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        const Text(
          'Swipe down to refresh',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _compactAppBarTitle(double progress, Color foreground) {
    return Opacity(
      opacity: progress,
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 16,
          ),

          const SizedBox(width: 4),

          Expanded(
            child: Text(
              _location?.placeName ?? 'Finding location...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Text(
            widget.temperatureText,
            style: TextStyle(
              color: foreground,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(width: 8),

          _loadingIndicator(foreground),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<double>(
      valueListenable: _collapseProgress,
      builder: (context, progress, _) {
        final surface = theme.colorScheme.surface;

        // Smoothly blend the expanded header into the AppBar.
        final blendedColor = Color.lerp(
          widget.headerColor,
          surface,
          progress,
        )!;

        final foreground = Color.lerp(
          Colors.white,
          theme.colorScheme.onSurface,
          progress,
        )!;

        return RefreshIndicator(
          onRefresh: _refreshWeatherAndLocation,
          color: theme.colorScheme.primary,
          backgroundColor: surface,
          strokeWidth: 2.0,
          displacement: 32,

          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: _expandedHeight,
                toolbarHeight: kToolbarHeight,
                backgroundColor: blendedColor,
                foregroundColor: foreground,
                surfaceTintColor: Colors.transparent,
                elevation: progress > 0.95 ? 1 : 0,
                leading: widget.leading,
                actions: widget.actions,

                titleSpacing: 12,

                // The compact info fades into the top AppBar.
                title: _compactAppBarTitle(
                  progress,
                  foreground,
                ),

                flexibleSpace: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.lerp(
                          widget.headerColor,
                          surface,
                          progress * 0.45,
                        )!,
                        blendedColor,
                      ],
                    ),
                  ),

                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        left: 22,
                        right: 22,
                        bottom: 26,

                        child: IgnorePointer(
                          ignoring: progress > 0.15,

                          // The larger weather info fades out as
                          // the compact AppBar info fades in.
                          child: Opacity(
                            opacity: 1 - progress,
                            child: _expandedWeatherHeader(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    18,
                    16,
                    32,
                  ),
                  child: widget.content,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();

    _collapseProgress.dispose();

    super.dispose();
  }
}