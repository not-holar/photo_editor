static const double pillHeight = 50;
static const double bottomSheetPeekHeight = pillHeight;

Builder(
  builder: (context) {
    final images = Provider.of<ImageDataList>(context, listen: false);

    const initialHeight = bottomSheetPeekHeight;
    const childrenHeight = 65.0 * 1;
    const padding = const EdgeInsets.fromLTRB(0, 0, 0, 20);
    final contextHeight = MediaQuery.of(context).size.height;
    final minHeight = (initialHeight / contextHeight).clamp(0, .5);
    final maxHeight =
        ((initialHeight + childrenHeight + padding.vertical) /
                contextHeight)
            .clamp(minHeight, .9);

    return DraggableScrollableSheet(
      minChildSize: minHeight,
      initialChildSize: minHeight,
      maxChildSize: maxHeight,
      builder: (context, scrollController) {
        return Material(
          borderRadius: const BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          elevation: 10,
          child: ListView(
            shrinkWrap: false,
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              const Pill(
                height: pillHeight,
              ),
              ListTile(
                contentPadding:
                    const EdgeInsets.only(left: 20, right: 10),
                leading: const Icon(Icons.add),
                title: const Text("Add images"),
                onTap: images.addFromPicker,
              ),
            ],
          ),
        );
      },
    );
  },
);

class Pill extends StatelessWidget {
  const Pill({
    Key key,
    this.height,
  }) : super(key: key);

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: Center(
        child: FractionallySizedBox(
          widthFactor: .1,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.2),
              borderRadius: const BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}