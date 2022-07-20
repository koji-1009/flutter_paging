import 'package:flutter/widgets.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:paging_view/src/data_source.dart';
import 'package:paging_view/src/function.dart';
import 'package:paging_view/src/private/entity.dart';
import 'package:sliver_tools/sliver_tools.dart';

class SliverPagingGrid<PageKey, Value> extends StatelessWidget {
  const SliverPagingGrid({
    super.key,
    required this.gridDelegate,
    required this.dataSource,
    required this.builder,
    required this.errorBuilder,
    required this.initialLoadingWidget,
    this.prependLoadingWidget,
    this.appendLoadingWidget,
    this.padding = EdgeInsets.zero,
  });

  /// region Paging
  final DataSource<PageKey, Value> dataSource;
  final TypedWidgetBuilder<Value> builder;
  final ExceptionWidgetBuilder errorBuilder;
  final Widget initialLoadingWidget;
  final Widget? prependLoadingWidget;
  final Widget? appendLoadingWidget;

  /// endregion

  /// region customize
  final EdgeInsets padding;
  final SliverGridDelegate gridDelegate;

  /// endregion

  @override
  Widget build(BuildContext context) =>
      StateNotifierBuilder<NotifierState<PageKey, Value>>(
        key: key,
        stateNotifier: dataSource.notifier,
        builder: (context, value, child) => value.when(
          (state, pages) {
            if (state == NotifierLoadingState.init) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                dataSource.update(LoadType.refresh);
              });

              return SliverToBoxAdapter(
                child: initialLoadingWidget,
              );
            } else if (state == NotifierLoadingState.initLoading) {
              return SliverToBoxAdapter(
                child: initialLoadingWidget,
              );
            }

            final showPrependLoading = prependLoadingWidget != null &&
                state == NotifierLoadingState.prependLoading;
            final showAppendLoading = appendLoadingWidget != null &&
                state == NotifierLoadingState.appendLoading;

            final items = value.items;
            final length = items.length;
            return MultiSliver(
              key: key,
              children: [
                if (showPrependLoading)
                  SliverPadding(
                    padding: padding,
                    sliver: SliverToBoxAdapter(
                      child: prependLoadingWidget,
                    ),
                  ),
                SliverPadding(
                  padding: padding,
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          // prepend
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            dataSource.update(LoadType.prepend);
                          });
                        } else if (index == length - 1) {
                          // append
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            dataSource.update(LoadType.append);
                          });
                        }

                        final element = items[index];
                        return builder(context, element, index);
                      },
                      childCount: length,
                    ),
                    gridDelegate: gridDelegate,
                  ),
                ),
                if (showAppendLoading)
                  SliverPadding(
                    padding: padding,
                    sliver: SliverToBoxAdapter(
                      child: appendLoadingWidget,
                    ),
                  ),
              ],
            );
          },
          error: (e) => errorBuilder(context, e),
        ),
      );
}
