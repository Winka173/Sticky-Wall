/// [items] with the free ones first and the Pro ones after them, each group
/// in its own order: a chooser never opens on a locked choice.
List<T> proLast<T>(Iterable<T> items, bool Function(T item) isPro) => [
  ...items.where((i) => !isPro(i)),
  ...items.where(isPro),
];
